# Primary Dataset — Schema Inspection (Verified Artifact)

Inspection date: **2026-09-30**

Source artifact:

`israel_lea_inp_burglary_offender_id_network.json`

Upstream repository:
https://github.com/erichoang/criminal-network-visualization

Upstream blob SHA:
`3afe9cbb4e313fb056f1b115c92a3f750f4698b9`

## Top-level schema

The inspected JSON contains:

- `directed`: true
- `multigraph`: false
- `graph`
- `nodes`
- `links`

## Node schema

All inspected nodes have:

- `type`
- `list_cid`
- `crime_details`
- `id`

Observed node type:

- `offender`

Observed node count:

**17,237**

Each offender node contains a list of related crime IDs and a nested `crime_details` mapping.

## Crime detail schema

Observed fields:

- `X`
- `Y`
- `date`
- `num_of_offenders`

Observed aggregate facts:

- unique crime IDs: **24,087**
- offender-crime association rows after flattening: **34,156**
- X range: **0–1**
- Y range: **0–1**
- num_of_offenders range: **1–13**
- mean num_of_offenders: approximately **1.903**
- median num_of_offenders: **1**

The X/Y values are normalized coordinates. Do not interpret them as precise real-world map coordinates.

## Link schema

Observed fields:

- `weight`
- `type`
- `observed`
- `source`
- `target`

Observed link facts:

- link count: **21,302**
- `type`: `relation` for inspected links
- `observed`: true for inspected links
- weight range: **1–37**
- mean weight: approximately **1.448**
- median weight: **1**

The edge list is directed according to the file's `directed=true` flag.

## Date range observed in artifact

Earliest observed crime-detail date:

**2010-12-01 00:00:00**

Latest observed crime-detail date:

**2020-09-28 00:00:00**

## Important source-vs-artifact distinction

The upstream preprocessing README describes the burglary source dataset as containing around 23,000 solved burglary reports in Israel between 2012 and 2021.

The specific preprocessed offender-network artifact inspected here contains 24,087 unique crime IDs and observed dates from 2010-12-01 through 2020-09-28.

Both statements are retained because they describe different layers:

1. the upstream dataset description, and
2. the exact artifact currently selected for implementation.

The exact artifact remains the authority for code schema and observed statistics.

## Structural and quality findings (audit 2026-09-30)

Reproduce with `python3 scripts/reference/audit_dataset_reference.py <json> --graph`; the MATLAB
regression test `tests/test_real_dataset.m` checks the same values.

| Finding | Value | Consequence |
|---|---|---|
| Reciprocal links | 21,302 of 21,302 (equal weights) | graph is symmetric: **10,651 undirected relations**; modelled as undirected |
| Link weight vs shared crimes | equal for all links; every co-offending pair is linked | network = one-mode projection of offender–crime data; relations can be time-stamped (15,422 pair–crime rows) |
| `num_of_offenders` vs attached offenders | equal for all 24,087 crimes | not independent information |
| Cross-offender consistency of a crime's date/X/Y/`num_of_offenders` | 0 inconsistencies | crime table is well defined |
| `list_cid` vs `crime_details` keys | identical sets for all nodes | IDs can be restored after `jsondecode` mangling (`CID#2` → `CID_2`) |
| Time of day | 0 of 34,156 non-midnight | day resolution only |
| Rows per year | 2010: 1, 2011: 2, 2012: 5, 2013: 83, 2014: 5,639, 2015: 4,812, 2016: 4,820, 2017: 5,149, 2018: 5,071, 2019: 5,189, 2020: 3,385 | temporal baselines start 2014-01; 2020-09 incomplete |
| Day-1 heaping | +17.7 % rows (+16 % crimes) on day 1 vs days 2–28 | possible date imputation; validation V61 |
| Busiest calendar month | July (2,374 crimes over all years) | seasonality; rolling baseline limitation |
| Crimes per offender | min 1, median 1, mean 1.98, max 40; 11,446 with one crime | eligibility rule for anomaly scoring |
| Offenders with ≥ 2 / ≥ 3 / ≥ 5 crimes | 5,791 / 3,260 / 1,395 | anomaly population = 3,260 |
| Offenders per crime | 1: 17,402 · 2: 4,512 · 3: 1,390 · 4: 523 · 5: 170 · 6: 53 · 7: 19 · 8: 5 · 9: 9 · 13: 1 | |
| Isolated offenders (no co-offender) | 7,597 | kept as isolated nodes |
| Connected components / largest | 10,468 / 518 offenders | betweenness is cheap (fragmented graph) |
| Maximum k-core; articulation points | 12; 1,156 | |
| Distinct (X, Y) among crimes | 19,509 of 24,087 | repeated sites exist |
| Median consecutive step (same offender) | 0.006586 normalized units (16,919 steps) | local/far split of the sequence alphabet |

## Analytical implications

This artifact supports:

- offender-level behavioral profiles,
- temporal aggregation,
- spatial dispersion in privacy-preserving normalized coordinate space,
- weighted offender-network analysis,
- co-offender intensity features,
- repeated crime/event patterns,
- dynamic network snapshots by time window (via time-stamped relations reconstructed from shared crimes).

It does **not** support: hour-of-day analysis, crime-type analysis (no type field; the free-text
embedding mentioned upstream is not in this artifact), real-world distances or maps.

The artifact does **not** itself provide video/audio streams. Multimedia requirements must therefore be satisfied through interactive visualization, animation, timeline replay, graph exploration, heatmaps, charts, and optional audio guidance.
