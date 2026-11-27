#!/usr/bin/env python3
"""Acquire a pinned official CTU-13 flow capture; no executable content."""
import argparse
import hashlib
import os
import tempfile
from pathlib import Path
import urllib.request

CAPTURES = {
    "7": (
        "https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/"
        "detailed-bidirectional-flow-labels/capture20110816-2.binetflow",
        "df0b5338190b967bd340a0d6c1bb3c34d1bbfb4b7ffa764c2dd26f77f1a26680"),
    "11": (
        "https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-52/"
        "detailed-bidirectional-flow-labels/capture20110818-2.binetflow",
        "cee542d4b5efe4fa1cd59b87ece5aaea9a13d8f0abe56cd07cee31590736428c"),
}

def acquire(scenario):
    url, expected = CAPTURES[str(scenario)]
    dest = Path(__file__).resolve().parents[2] / f'data/external/ctu13-scenario{scenario}.binetflow'
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        with dest.open('rb') as source:
            actual = hashlib.file_digest(source, 'sha256').hexdigest()
        if actual != expected:
            raise ValueError('Existing file differs; preserve and inspect it before downloading.')
        print('Existing official scenario verified:', dest.name)
        return
    fd, pending_name = tempfile.mkstemp(prefix=dest.name + '.', suffix='.download', dir=dest.parent)
    pending = Path(pending_name)
    digest = hashlib.sha256()
    total = 0
    try:
        with os.fdopen(fd, 'wb') as target, urllib.request.urlopen(url, timeout=45) as response:
            while chunk := response.read(1024 * 1024):
                total += len(chunk)
                if total > 20_000_000:
                    raise ValueError('Unexpected file size')
                digest.update(chunk)
                target.write(chunk)
        if digest.hexdigest() != expected:
            raise ValueError('Official content changed; do not use without a fresh audit.')
        # Publish without replacing a file created by a concurrent acquisition.
        os.link(pending, dest)
        pending.unlink()
    except Exception as exc:
        # This uniquely named partial belongs to this run; preserve it for inspection.
        raise RuntimeError(f'Acquisition failed; partial retained at {pending.name}') from exc
    print('Verified official scenario:', dest.name, total, 'bytes', expected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scenario', choices=sorted(CAPTURES), default='7')
    acquire(parser.parse_args().scenario)


if __name__ == '__main__':
    main()
