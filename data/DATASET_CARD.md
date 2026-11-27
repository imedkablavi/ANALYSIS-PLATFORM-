# Dataset Card — CTU-13 scenario 7

## Source and identity

The full bidirectional-flow file for CTU-13 scenario 7 is published by
Stratosphere Laboratory, Czech Technical University. The official description
identifies a controlled botnet capture mixed with normal/background traffic.

- [Dataset description](https://www.stratosphereips.org/datasets-ctu13/).
- [Authoritative scenario directory](https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/).
- Original file: `capture20110816-2.binetflow`.
- Local file: `data/external/ctu13-scenario7.binetflow` (excluded from Git).
- Acquired and independently audited: 2026-10-31.
- Bytes: 15,630,512.
- Git blob: `33065bb8bc1df911fae818e3475ee0cf96d0e0a9`.
- SHA256: `df0b5338190b967bd340a0d6c1bb3c34d1bbfb4b7ffa764c2dd26f77f1a26680`.
- Selection: complete file, without local relabelling or row sampling.

## Observed data

114,077 flows and 38,204 hosts. Source timestamps span
2011-08-16 13:51:24.049047 through 14:12:41.499668; their timezone is not
inferred. The independent audit found no missing endpoints or invalid/missing
timestamps. Available flow fields include source/destination, start time,
protocol, ports, duration, packets, bytes and label. There are no geographic
coordinates or packet contents in the imported flow table.

## Labels and population

The CTU rule maps Botnet to malicious, Normal to benign and Background to
unknown. To-labels apply to the destination endpoint. A host is malicious
if any applicable record is malicious, benign if it has benign evidence and
no malicious evidence, and otherwise unknown. Labels are joined after scoring.

| Population | Malicious | Benign | Unknown | Total |
|---|---:|---:|---:|---:|
| Flows | 63 | 1,677 | 112,337 | 114,077 |
| Hosts | 1 | 6 | 38,197 | 38,204 |
| Hosts with at least 3 incident flows | 1 | 6 | 2,449 | 2,456 |

These are source/reference counts, not detector metrics. One labelled malicious
host does not support broad accuracy conclusions or deployment claims.

## Processing and privacy

Identifiers are pseudonymized by default. Each flow becomes one event with
its two endpoints; self-flows have one participant. Units and timestamp rules
are defined in [NETWORK_DATASETS.md](../docs/NETWORK_DATASETS.md). Raw input and
local generated reports are excluded from Git. Exported investigation records
use local host pseudonyms and never reconstruct source identities.

## Use and citation

The authoritative scenario README permits use with reference to the project
and authors. Cite Garcia, S., Grill, M., Stiborek, J., and Zunino, A. (2014),
An empirical comparison of botnet detection methods, Computers & Security 45,
100–123, https://doi.org/10.1016/j.cose.2014.05.011. Source terms remain attached
to the source; no broader redistribution permission is inferred here.

## Reproduction and validation

Run `python3 scripts/data/acquire_ctu13_scenario7.py` to acquire and verify
source content. Independent receipt: `outputs/reference/ctu13-scenario7.json`.
Run `scripts/run_network_demo.m` in MATLAB for the actual analysis and
`verify_delivery` for test/experiment receipts. Current runtime acceptance
status is tracked in [TASKS.md](../docs/TASKS.md).

The earlier independent case study has its own
[BURGLARY_DATASET_CARD.md](BURGLARY_DATASET_CARD.md).
