#!/usr/bin/env python3
"""Package the current worktree and pinned flow captures, without linked .git paths."""
import argparse
import hashlib
import json
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PREFIX = "NetworkBehaviourExplorer"
CAPTURES = {
    "data/external/ctu13-scenario7.binetflow":
        "df0b5338190b967bd340a0d6c1bb3c34d1bbfb4b7ffa764c2dd26f77f1a26680",
    "data/external/ctu13-scenario11.binetflow":
        "cee542d4b5efe4fa1cd59b87ece5aaea9a13d8f0abe56cd07cee31590736428c",
}


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def build(output):
    paths = set(git("ls-files", "--cached", "--others", "--exclude-standard", "-z")
                .decode("utf-8").rstrip("\0").split("\0"))
    paths.update(CAPTURES)
    for name, expected in CAPTURES.items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != expected:
            raise ValueError(f"Capture fingerprint differs: {name}")
    # Reference receipts contain aggregate source counts, never detector results.
    for name in ("ctu13-scenario7.json", "ctu13-scenario11.json"):
        receipt = ROOT / "outputs" / "reference" / name
        if receipt.is_file():
            paths.add(receipt.relative_to(ROOT).as_posix())
    stamp = datetime.now(timezone.utc)
    state = {
        "created_utc": stamp.isoformat(),
        "branch": git("branch", "--show-current").decode().strip(),
        "base_commit": git("rev-parse", "HEAD").decode().strip(),
        "main_commit": git("rev-parse", "main").decode().strip(),
        "status": git("status", "--short").decode(),
        "history": git("log", "--graph", "--oneline", "--all", "-20").decode(),
        "runtime_verification": "PENDING: run MATLAB tests and GUI on target Windows installation",
        "snapshot": "Current file contents, including uncommitted and untracked source files",
        "files_sha256": {},
    }
    output.mkdir(parents=True, exist_ok=True)
    dest = output / f"NetworkBehaviourExplorer-Windows-{stamp:%Y%m%dT%H%M%SZ}.zip"
    used = set()
    with zipfile.ZipFile(dest, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(paths):
            path = ROOT / name
            if not path.exists():  # Tracked deletions are absent from the snapshot.
                continue
            if path.is_symlink() or not path.is_file():
                raise ValueError(f"Unsupported source entry: {name}")
            parts = Path(name).parts
            if any(part in ("..", ".git") or ":" in part or "\\" in part
                   or part.endswith((".", " ")) for part in parts):
                raise ValueError(f"Nonportable path: {name}")
            if name.casefold() in used:
                raise ValueError(f"Case collision on Windows: {name}")
            used.add(name.casefold())
            data = path.read_bytes()
            state["files_sha256"][name] = hashlib.sha256(data).hexdigest()
            archive.writestr(f"{PREFIX}/{name}", data)
        archive.writestr(f"{PREFIX}/TRANSFER_STATE.json",
                         json.dumps(state, ensure_ascii=False, indent=2) + "\n")
        archive.writestr(f"{PREFIX}/TRANSFER_GIT_DIFF.patch", git("diff", "HEAD", "--binary"))
    # Re-read every packaged member, rather than trusting only the write operation.
    with zipfile.ZipFile(dest) as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP CRC verification failed")
        for name, expected in state["files_sha256"].items():
            if hashlib.sha256(archive.read(f"{PREFIX}/{name}")).hexdigest() != expected:
                raise ValueError(f"Packaged content differs: {name}")
    checksum = hashlib.sha256(dest.read_bytes()).hexdigest()
    dest.with_suffix(".zip.sha256").write_text(f"{checksum}  {dest.name}\n", encoding="ascii")
    print(json.dumps({"archive": str(dest), "bytes": dest.stat().st_size,
                      "source_and_data_files": len(state["files_sha256"]),
                      "sha256": checksum, "verified": True}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT.parent / "deliveries")
    build(parser.parse_args().output.resolve())
