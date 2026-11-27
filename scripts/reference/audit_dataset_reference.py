#!/usr/bin/env python3
"""Independent reference audit of the primary artifact (verification only).

Purpose (docs/PYTHON_POLICY.md, "verification against a reference
implementation"): reproduce every dataset fact quoted in
docs/DATASET_SCHEMA_INSPECTION.md and provide expected values for the
MATLAB real-data regression test (tests/test_real_dataset.m). It is NOT a
second analysis pipeline and none of its output is used by MATLAB code.

Usage:
    python3 scripts/reference/audit_dataset_reference.py [path/to/json]

Core section: Python standard library only.
Optional section (--graph): needs numpy + networkx; cross-checks the k-core,
clustering, component and articulation-point logic used in MATLAB.
"""
import collections
import datetime as dt
import hashlib
import json
import math
import statistics as st
import sys

DEFAULT = "data/raw/israel_lea_inp_burglary_offender_id_network.json"


def git_blob_sha(path):
    data = open(path, "rb").read()
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


def main(path, with_graph):
    print("blob_sha", git_blob_sha(path))
    d = json.load(open(path))
    nodes, links = d["nodes"], d["links"]
    ids = [n["id"] for n in nodes]
    index = {o: i for i, o in enumerate(ids)}
    print("directed", d["directed"], "multigraph", d["multigraph"])
    print("nodes", len(nodes), "unique_ids", len(set(ids)), "links", len(links))
    print("node_types", dict(collections.Counter(n["type"] for n in nodes)))
    print("list_cid_mismatch", sum(set(n["list_cid"]) != set(n["crime_details"]) for n in nodes))

    ev = []
    for i, n in enumerate(nodes):
        for c, v in n["crime_details"].items():
            ev.append((i, c, int(c.split("#")[1]), dt.date.fromisoformat(v["date"][:10]),
                       v["X"], v["Y"], v["num_of_offenders"], v["date"]))
    ev.sort(key=lambda r: (r[0], r[3], r[2]))
    print("event_rows", len(ev))
    print("non_midnight_times", sum(not r[7].endswith("00:00:00") for r in ev))
    by_crime = collections.defaultdict(list)
    for r in ev:
        by_crime[r[1]].append(r)
    print("unique_crimes", len(by_crime))
    incons = sum(len({(r[3], r[4], r[5], r[6]) for r in rs}) > 1 for rs in by_crime.values())
    print("crimes_inconsistent_across_offenders", incons)
    print("num_offenders_mismatch", sum(rs[0][6] != len(rs) for rs in by_crime.values()))
    print("date_min", min(r[3] for r in ev), "date_max", max(r[3] for r in ev))
    print("rows_per_year", sorted(collections.Counter(r[3].year for r in ev).items()))
    xs = [r[4] for r in ev]
    ys = [r[5] for r in ev]
    print("x_range", min(xs), max(xs), "y_range", min(ys), max(ys))
    per_crime = [rs[0] for rs in by_crime.values()]
    dom = collections.Counter(r[3].day for r in per_crime)
    print("day1_excess_ratio_crimes", round(dom[1] / st.mean(dom[k] for k in range(2, 29)), 3))
    dom_rows = collections.Counter(r[3].day for r in ev)
    print("day1_excess_ratio_rows", round(dom_rows[1] / st.mean(dom_rows[k] for k in range(2, 29)), 3))

    pairs = collections.Counter((l["source"], l["target"]) for l in links)
    print("reciprocal_links", sum((t, s) in pairs for (s, t) in pairs))
    shared = collections.defaultdict(int)
    for rs in by_crime.values():
        m = sorted({r[0] for r in rs})
        for a in range(len(m)):
            for b in range(a + 1, len(m)):
                shared[(m[a], m[b])] += 1
    print("relations_from_crimes", len(shared), "pair_crime_rows", sum(shared.values()))
    ok = sum(shared.get(tuple(sorted((index[l["source"]], index[l["target"]]))), 0) == l["weight"]
             for l in links)
    print("links_with_weight_equal_shared_crimes", ok)
    deg = collections.Counter()
    for a, b in shared:
        deg[a] += 1
        deg[b] += 1
    print("isolated_nodes", sum(deg[i] == 0 for i in range(len(ids))))
    cnt = collections.Counter(r[0] for r in ev)
    print("entities_with_>=2/3/5_events",
          sum(v >= 2 for v in cnt.values()), sum(v >= 3 for v in cnt.values()),
          sum(v >= 5 for v in cnt.values()))

    # sequence tokens (same definition as src/sequence/encodeEventSequences.m)
    steps, prev = [], None
    for r in ev:
        if prev and prev[0] == r[0]:
            steps.append(math.hypot(r[4] - prev[4], r[5] - prev[5]))
        prev = r
    steps.sort()
    h = (len(steps) - 1) * 0.5
    thr = steps[int(h)] + (h - int(h)) * (steps[min(int(h) + 1, len(steps) - 1)] - steps[int(h)])
    print("median_step", repr(thr), "steps", len(steps))
    members = {c: {r[0] for r in rs} for c, rs in by_crime.items()}
    seen, toks, prev = collections.defaultdict(set), collections.Counter(), None
    for r in ev:
        partners = members[r[1]] - {r[0]}
        state = "S" if not partners else ("N" if partners - seen[r[0]] else "R")
        seen[r[0]] |= partners
        if prev is None or prev[0] != r[0]:
            move = "0"
        else:
            move = "L" if math.hypot(r[4] - prev[4], r[5] - prev[5]) <= thr else "F"
        toks[state + move] += 1
        prev = r
    print("token_counts", sorted(toks.items()))

    if with_graph:
        import networkx as nx
        G = nx.Graph()
        G.add_nodes_from(range(len(ids)))
        G.add_weighted_edges_from((a, b, w) for (a, b), w in shared.items())
        core = nx.core_number(G)
        comps = sorted((len(c) for c in nx.connected_components(G)), reverse=True)
        print("components", len(comps), "largest", comps[0], "max_core", max(core.values()))
        print("articulation_points", len(list(nx.articulation_points(G))))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else DEFAULT, "--graph" in sys.argv)
