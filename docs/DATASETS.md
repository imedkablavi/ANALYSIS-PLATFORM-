# Dataset Strategy

## Primary artifact — burglary offender network

Public repository:
https://github.com/erichoang/criminal-network-visualization

The upstream preprocessing documentation describes a burglary dataset with roughly 23,000 solved burglary reports in Israel and identifies offender-network and crime-network representations.

### Exact artifact selected for implementation

`datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json`

Verified artifact facts:

- directed: true
- multigraph: false
- 17,237 offender nodes
- 21,302 relation links
- 24,087 unique crime IDs
- 34,156 offender-crime association rows
- observed dates: 2010-12-01 through 2020-09-28
- normalized X/Y values in [0,1]
- edge weights observed in [1,37]

Full schema inspection:
`docs/DATASET_SCHEMA_INSPECTION.md`

### Why selected

The artifact combines:

- anonymized entity IDs,
- timestamps,
- privacy-preserving spatial coordinates,
- co-offending relations,
- weighted network structure,
- repeated events.

This supports a genuinely non-trivial behavioral/network analysis pipeline within the one-month constraint.

### Multimedia limitation

This artifact does not contain raw video/audio. The Çoklu Ortam contribution will therefore be the interactive analytical presentation: dynamic graph, timeline, heatmap, animated state changes, event replay, synchronized views, and optional audio/narration.

### Secondary artifacts

The same upstream repository documents:

- `israel_lea_inp_burglary_v2_crime_id_network.json`
- `israel_lea_case1_speakers.json`
- `israel_lea_case2_speakers.json`
- `nist_c1.json`
- `nist_c2.json`
- `madoff.json`

These remain secondary until a schema/value-add gate is passed.

## Switching rule

Do not switch the primary dataset unless it fails a documented gate for:

1. accessibility,
2. legal/usage terms,
3. schema completeness,
4. temporal availability,
5. analytical relevance,
6. computational feasibility,
7. evaluation feasibility.

Record every change in `docs/RESEARCH_LOG.md`.
