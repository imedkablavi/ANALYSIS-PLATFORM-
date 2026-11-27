#!/usr/bin/env python3
"""Independent reference for the network-flow import and host features (verification only).

Purpose (docs/PYTHON_POLICY.md, "verification against a reference
implementation"): recompute, without MATLAB, what importNetworkFlows,
labelNetworkFlows, networkGroundTruth and computeNetworkFeatures produce for
a CTU-13 style .binetflow file, to derive the expected values of
tests/test_network_datasets.m and to sanity-check the definitions on real
published traffic. It is NOT a second pipeline; MATLAB never reads its output.

Usage:
    python3 scripts/reference/network_flow_reference.py FILE.binetflow [--hosts N]

Standard library only. Host identifiers are printed as pseudonyms
(H0001...) in order of first appearance, exactly like the MATLAB import
(sources of all rows first, then destinations), never as IP addresses.
"""
import collections
import csv
import datetime as dt
import math
import re
import statistics as st
import sys


def read_binetflow(path):
    with open(path, newline="") as fh:
        first = fh.readline()
        delim = "\t" if "\t" in first else ","
        fh.seek(0)
        rows = list(csv.DictReader(fh, delimiter=delim))
    return [{k.strip(): (v or "").strip() for k, v in r.items()} for r in rows]


def label_ctu13(label):
    low = label.lower()
    cls = "unknown"
    if "normal" in low:
        cls = "benign"
    if "botnet" in low:
        cls = "malicious"
    role = "dst" if re.match(r"^(flow=)?to-", low) else "src"
    return cls, role


def num(v):
    try:
        return float(v)
    except ValueError:
        return math.nan   # e.g. hexadecimal ICMP "ports"


def main(path, show):
    rows = read_binetflow(path)
    t0 = None
    flows = []
    for r in rows:
        t = dt.datetime.strptime(r["StartTime"], "%Y/%m/%d %H:%M:%S.%f")
        cls, role = label_ctu13(r.get("Label", ""))
        flows.append(dict(src=r["SrcAddr"], dst=r["DstAddr"], t=t,
                          dur=num(r["Dur"]), bytes=num(r["TotBytes"]),
                          pkts=num(r["TotPkts"]), dport=num(r["Dport"]),
                          cls=cls, role=role))
    order = {}
    for f in flows:
        order.setdefault(f["src"], len(order))
    for f in flows:
        if f["dst"] != f["src"]:
            order.setdefault(f["dst"], len(order))
    pid = {ip: "H%04d" % (i + 1) for ip, i in order.items()}

    out = collections.defaultdict(list)
    inc = collections.Counter()
    src_in = collections.defaultdict(set)
    events = collections.Counter()
    for f in flows:
        out[f["src"]].append(f)
        events[f["src"]] += 1
        if f["dst"] != f["src"]:
            inc[f["dst"]] += 1
            src_in[f["dst"]].add(f["src"])
            events[f["dst"]] += 1

    mal = collections.Counter()
    ben = collections.Counter()
    for f in flows:
        host = f["dst"] if f["role"] == "dst" else f["src"]
        if f["cls"] == "malicious":
            mal[host] += 1
        elif f["cls"] == "benign":
            ben[host] += 1

    tmin = min(f["t"] for f in flows)

    def feats(h):
        o = out[h]
        n_out, n_in = len(o), inc[h]
        res = dict(out_flows=n_out, in_flows=n_in,
                   out_share=n_out / (n_out + n_in) if n_out + n_in else math.nan,
                   distinct_dst=len({f["dst"] for f in o}) if o else math.nan,
                   distinct_src_in=len(src_in[h]))
        ports = [f["dport"] for f in o if not math.isnan(f["dport"])]
        if ports:
            c = collections.Counter(ports)
            res["distinct_dport"] = len(c)
            res["dport_entropy"] = (-sum(v / len(ports) * math.log2(v / len(ports))
                                         for v in c.values())
                                    if len(ports) >= 2 else math.nan)
        else:
            res["distinct_dport"] = math.nan
            res["dport_entropy"] = math.nan
        b = [f["bytes"] for f in o if not math.isnan(f["bytes"])]
        d = [f["dur"] for f in o if not math.isnan(f["dur"])]
        p = [f["pkts"] for f in o if not math.isnan(f["pkts"])]
        res["median_bytes_out"] = st.median(b) if b else math.nan
        res["median_duration_out"] = st.median(d) if d else math.nan
        res["small_flow_fraction"] = (sum(x <= 2 for x in p) / len(p)) if p else math.nan
        best = math.nan
        by_dst = collections.defaultdict(list)
        for f in o:
            if f["dst"] != h:
                by_dst[f["dst"]].append((f["t"] - tmin).total_seconds())
        for ts in by_dst.values():
            if len(ts) < 4:
                continue
            ts.sort()
            g = [b2 - a2 for a2, b2 in zip(ts, ts[1:])]
            mu = sum(g) / len(g)
            if mu <= 0:
                continue
            sd = math.sqrt(max(sum(x * x for x in g) / len(g) - mu * mu, 0))
            cv = sd / mu
            best = cv if math.isnan(best) else min(best, cv)
        res["beacon_cv_min"] = best
        return res

    truth = {h: ("malicious" if mal[h] else "benign" if ben[h] else "unknown") for h in order}
    labels = collections.Counter(f["cls"] for f in flows)
    print(f"file: {path}")
    print(f"flows: {len(flows)}  hosts: {len(order)}  "
          f"span: {min(f['t'] for f in flows)} .. {max(f['t'] for f in flows)}")
    print(f"flow labels: {dict(labels)}")
    print(f"host truth: {dict(collections.Counter(truth.values()))}")
    print(f"eligible hosts (>= 3 flows): {sum(v >= 3 for v in events.values())}")
    hosts = sorted(order, key=order.get)[:show]
    for h in hosts:
        f = feats(h)
        print(pid[h], truth[h], "events=%d" % events[h],
              " ".join(f"{k}={v:.6g}" if isinstance(v, float) else f"{k}={v}"
                       for k, v in f.items()))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    n = 12
    if "--hosts" in sys.argv:
        n = int(sys.argv[sys.argv.index("--hosts") + 1])
    main(sys.argv[1], n)
