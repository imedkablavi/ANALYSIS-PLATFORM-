# Network-Traffic Datasets (computer networks)

Scope decision (2026-10-20, project owner): "ağ tabanlı" in the assignment title means
**computer-network traffic**, not a social/crime network. The platform therefore reads the
standard labelled network-security datasets directly. The burglary artifact stays supported
as an earlier case study, but it is not the project's target domain.

> Status: implemented and unit-tested on hand-written fixtures in the published layouts
> (`tests/test_network_datasets.m`); **not yet executed in MATLAB** (same gate as the rest of
> the code), and **no real file of these datasets has been analysed yet**: the download
> sites cannot be reached from the development environment. See "Verification status".

## Supported datasets

| Profile id | Dataset | File(s) to use | Hosts / events | Labels | Licence / terms |
|---|---|---|---|---|---|
| `ctu13_binetflow` | CTU-13 (Stratosphere Lab, CTU Prague): 13 scenarios of real botnet traffic mixed with normal and background traffic | `*.binetflow` (bidirectional Argus flows) of a scenario | IP addresses; one flow = one event | `flow=From-Botnet-…` malicious, `…Normal…` benign, `Background…` **unknown** | CC BY ([page](https://stratosphereips.org/datasets-ctu13)) |
| `cicids2017_flows` | CIC-IDS2017 (UNB CIC): 5 days of enterprise traffic with DoS, DDoS, PortScan, brute force, web attacks, botnet, infiltration | `GeneratedLabelledFlows/*.csv` (the `MachineLearningCSV` files have no IP/time columns and cannot form a network) | IP addresses | `BENIGN` benign, attack name malicious | academic use, cite the paper ([page](https://www.unb.ca/cic/datasets/ids-2017.html)) |
| `unsw_nb15` / `unsw_nb15_raw` | UNSW-NB15 (UNSW Canberra): 2.54 M records, 9 attack families | `UNSW-NB15_1.csv` … `_4.csv` (no header, 49 columns) or a copy with the feature names as header. The training/testing split files have no IPs | IP addresses | `Label` 1/0, `attack_cat` detail | academic use ([page](https://research.unsw.edu.au/projects/unsw-nb15-dataset)) |
| `lanl_auth` | LANL Comprehensive Multi-Source Cyber-Security Events: 58 days of an enterprise network, 1.05 B authentication events | `auth.txt` (+ `redteam.txt` as `labels_file`) | computers; one authentication = one event | red-team events malicious, all other events of the file benign | see [LANL page](https://csr.lanl.gov/data/cyber1/) |
| `lanl_flows` | same release | `flows.txt` | computers | none | same |

Format detection is automatic (`inspectDatasetFile` → `matchNetworkProfile`). A headered file
matches when all signature columns are present (case, spaces and punctuation ignored, because
published copies differ, e.g. `" Source IP"`). A headerless file matches only when its column
count is right **and** content checks pass on the first 200 rows (IPv4 addresses, integer
times, 0/1 labels, `Success`/`Fail`); otherwise it is not silently mislabelled. A profile can be
forced: `analyzeDataset(f, struct('profile', "unsw_nb15_raw"))`, which raises
`MOSAIC:ProfileMismatch` with the reason if the checks fail.

## How to use

1. Download from the official page (links above) and put the file in `data/external/`
   (git-ignored). Check the licence and cite the dataset in the report.
2. App: "Open dataset…" → choose the file → the profile is detected → progress dialog.
   Script/code:
   ```matlab
   b = analyzeDataset("data/external/capture20110810.binetflow");          % CTU-13 scenario 1
   b = analyzeDataset("data/external/auth.txt", struct( ...
       'labels_file', "data/external/redteam.txt", 'max_rows', 5e6));      % LANL subset
   ```
3. Results: `outputs/datasets/<id>/` incl. `tables/ground_truth_evaluation.csv`; the app's
   "Ground truth" tab shows the same table, the status line shows the selected host's
   published label.

Size guidance (not yet measured in MATLAB): start with one CTU-13 scenario (scenarios differ
from ~0.1 M to a few M flows), one CIC-IDS2017 day, one UNSW-NB15 part, and LANL with
`max_rows` (≤ a few million). Every record becomes one event with two participants, so memory
grows with 2 × rows.

## What the import does (`importNetworkFlows`, notes in `bundle.meta.dataset.import_notes`)

| Step | Rule | Why |
|---|---|---|
| Entities | hosts = source and destination addresses / computer names, pseudonymized `ENT…` in order of first appearance (all sources, then destinations) | IP addresses are personal data in many jurisdictions (AGENTS.md rule 5) |
| Events | one record = one event between its two hosts (self-traffic: one participant) | reuses the event/relation/graph pipeline; tie strength = number of shared flows |
| Flow table | `ds.flows`: host indices, time, duration (s), bytes, packets, ports, protocol, failed (auth), label columns. **No addresses** | per-flow attributes for the network features |
| Time | CTU `yyyy/MM/dd HH:mm:ss.SSSSSS`; CIC `dd/MM/yyyy HH:mm:ss`, `d/M/yyyy H:mm[:ss]` (mixed in one file are all read); UNSW POSIX seconds; LANL seconds from an undisclosed origin (shown as 1970 offsets) | timestamps are read as text and parsed with the profile's formats, never with automatic guessing |
| Units | CIC `Flow Duration` µs → s; bytes/packets = forward + backward where the dataset splits them | comparable features across datasets |
| Ports | non-numeric ports (CTU ICMP `0x0008`, LANL `N1136`) → NaN | they are not port numbers |
| Labels | `labelNetworkFlows` (see below) | evaluation only |
| `max_rows` | read only the first N records | LANL files are far larger than memory |

### Labels → host ground truth

`labelNetworkFlows` turns the published label of each record into malicious / benign / unknown
and says which endpoint it describes (`label_role`): CTU-13 `To-…` labels describe the
destination, all others the source (attacking / infected host). `networkGroundTruth`: a host
is **malicious** if at least one labelled record about it is malicious, **benign** if it has
benign records and no malicious one, **unknown** otherwise.

Important: CTU-13 *Background* traffic was not labelled by the authors; it is "unknown", never
"benign". `evaluateGroundTruth` therefore reports two settings: `known_only` (unknown hosts
left out) and `unknown_as_benign` (conservative for precision).

**Labels never enter the features or the detectors.** They are joined after scoring, only to
measure ROC-AUC, average precision (with its chance level) and precision/recall at k = number
of malicious hosts. Malicious hosts with too little traffic to be scored are counted
(`malicious_not_scored`), not hidden. A host flagged by the platform is a host whose traffic
deviates; even with labels, the wording stays "deviation", not "compromised".

## Network features (group `network`, `computeNetworkFeatures`)

| Feature | Definition | Typical suspicious pattern |
|---|---|---|
| `out_flows`, `in_flows`, `out_share` | flows initiated / received, share initiated | infected host initiates almost everything |
| `distinct_dst` (fan-out), `distinct_src_in` (fan-in) | distinct peers | scanning, spam, worm propagation; DDoS victims |
| `distinct_dport`, `dport_entropy` | destination-port diversity (bits) | port scans (high), single-service C&C (low) |
| `median_bytes_out`, `median_duration_out` | typical size and length of outgoing flows | exfiltration, keep-alive sessions |
| `small_flow_fraction` | outgoing flows with ≤ 2 packets | probes, unanswered attempts |
| `failed_fraction` | failed authentications (LANL) | password guessing, lateral-movement attempts |
| `beacon_cv_min` | smallest coefficient of variation of the gaps between flows to one destination (≥ 4 flows) | clock-like command-and-control "beaconing" (≈ 0) |

The existing groups still apply: graph position (degree, k-core, betweenness, …), activity and
timing, partner novelty. Spatial features are undefined (no coordinates) and dropped.

## Time resolution

`configureForDataset` picks the coarsest bin that still gives a usable series: month
(≥ 24 months), week (≥ 26 weeks), day (≥ 30 days), hour (≥ 24 h), otherwise minute. A CTU-13
scenario (hours) gets minute or hour bins, LANL (58 days) daily bins. Dynamic-graph windows
are ~8 equal windows for day/hour/minute bins; the app's replay window is measured in the same
bins ("Window (periods)").

## Verification status

| Item | How it was checked |
|---|---|
| CTU-13 header and value formats | on Stratosphere's published binetflow samples (`StratosphereLinuxIPS/dataset`, comma and tab variants) |
| Host feature definitions | independent Python reference `scripts/reference/network_flow_reference.py`; run on the fixture (expected values of the MATLAB test) and on a real published capture (6,751 flows, 497 hosts: the infected host initiates 99.7% of its flows to 495 destinations, `beacon_cv_min` 0.099) |
| CIC-IDS2017, UNSW-NB15, LANL layouts | **from the dataset documentation only** (download sites unreachable here). Profiles carry this in `verified`; content checks guard headerless files. First real import must be checked (TASKS_FOR_ADMIN) |
| Known dataset problems | CIC-IDS2017: label errors, duplicated/miscomputed features, 12-hour timestamps without AM/PM in some files (Lanvin et al. 2022, SciTePress). CTU-13: Background ≠ benign. LANL: red team covers successful authentications only |
