# Real network capture evidence

## Complete labelled CTU-13 scenario acquired from the authoritative server

Acquisition succeeded on 2026-10-31 from the authoritative
[scenario 7 directory](https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/),
linked by the [official CTU-13 page](https://www.stratosphereips.org/datasets-ctu13/).
Earlier upstream software-test samples were removed from the presentation data
directory. The source below is the complete official scenario.

- Original flow text: [capture20110816-2.binetflow](https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/detailed-bidirectional-flow-labels/capture20110816-2.binetflow).
- Local gitignored file: `data/external/ctu13-scenario7.binetflow`.
- Full file, no row sampling, no locally rewritten labels or timestamps.
- Bytes: 15,630,512.
- Git blob: `33065bb8bc1df911fae818e3475ee0cf96d0e0a9`.
- SHA-256: `df0b5338190b967bd340a0d6c1bb3c34d1bbfb4b7ffa764c2dd26f77f1a26680`.
- Time interval: 2011-08-16 13:51:24.049047 through 14:12:41.499668 (source clock; no timezone assumption).
- Independent Python reference: **114,077 flows, 38,204 hosts**.
- Flow classes under the documented mapping: **63 malicious, 1,677 benign, 112,337 unknown**.
- Host truth: **1 malicious, 6 benign, 38,197 unknown**.
- Eligible (at least 3 incident flows): **2,456 hosts**, of which **1 malicious, 6 benign, 2,449 unknown**.

Only seven eligible hosts have known labels. This is a valid small labelled
case study, not sufficient evidence of general detection performance. Report
counts beside AP/AUC, use additional complete scenarios for robustness, and keep
unknown-as-benign separate. All numbers above describe the source and reference
mapping; **no MATLAB model has been run and no detector metric is claimed**.
The authoritative README permits use with project/author reference; cite Garcia
et al. (2014), DOI 10.1016/j.cose.2014.05.011 as required by the dataset page.

Reproduce:

```sh
python3 scripts/data/acquire_ctu13_scenario7.py
python3 scripts/reference/network_flow_reference.py data/external/ctu13-scenario7.binetflow --hosts 0
```

Then in MATLAB, from the repository root:

```matlab
addpath scripts
verify_delivery("data/external/ctu13-scenario7.binetflow")
```

## Streaming audit receipt

`python3 scripts/reference/audit_network_capture.py` now creates a machine-readable,
privacy-safe audit receipt. Its regression suite covers empty/malformed input,
missing endpoints/timestamps, direction-specific labels and self-flow counting.
The locally generated receipt is `outputs/reference/ctu13-scenario7.json` and
explicitly records that no detector was executed. CI runs the offline reference
tests independently of MATLAB licensing.

## Graph workload checked against this capture

An independent traversal of the source/destination graph found a largest
component of 37,977 hosts. The sum of component node-count × edge-count is
1,582,160,303. The previous node-only betweenness guard would allow this
computation; the new configurable `graph.max_betweenness_work = 2e8` proxy
skips it, leaves the feature unavailable and records the reason. This is a
work estimate, not a measured MATLAB timing. Existing degree/strength and
traffic features remain usable; skipped features must be reported in results.

## Second independent official input — CTU-13 scenario 11

Acquired unchanged on 2026-11-01 from the authoritative
[scenario directory](https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-52/detailed-bidirectional-flow-labels/).
Source: `capture20110818-2.binetflow`; local file:
`data/external/ctu13-scenario11.binetflow` (gitignored).

- Bytes: 14,596,615; complete file without local row sampling.
- SHA256: `cee542d4b5efe4fa1cd59b87ece5aaea9a13d8f0abe56cd07cee31590736428c`.
- Git blob: `939116f18a8ccfd9c4694dd58c7fa558d49e67ae`.
- Source-clock interval: 2011-08-18 15:39:35.087798–15:55:46.379941.
- Independent audit: 107,251 flows, 41,931 hosts; no missing endpoints or invalid/missing timestamps.
- Flow classes: 8,164 malicious, 2,718 benign, 96,369 unknown.
- Host truth: 3 malicious, 8 benign, 41,920 unknown.
- Eligible hosts (at least 3 incident flows): 2,242; 3 malicious, 8 benign, 2,231 unknown.

These are source/reference facts, not model-performance results. The small
known-labelled population still limits inference. Receipt:
`outputs/reference/ctu13-scenario11.json`. Acquisition:
`python3 scripts/data/acquire_ctu13_capture.py --scenario 11`.
The same import entry point accepts either complete capture. MATLAB runs on
both and custom-column datasets remain separate runtime verification work.
