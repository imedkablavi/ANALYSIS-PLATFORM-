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

## Analytical implications

This artifact supports:

- offender-level behavioral profiles,
- temporal aggregation,
- spatial dispersion in privacy-preserving normalized coordinate space,
- weighted offender-network analysis,
- co-offender intensity features,
- repeated crime/event patterns,
- dynamic network snapshots by time window.

The artifact does **not** itself provide video/audio streams. Multimedia requirements must therefore be satisfied through interactive visualization, animation, timeline replay, graph exploration, heatmaps, charts, and optional audio guidance.
