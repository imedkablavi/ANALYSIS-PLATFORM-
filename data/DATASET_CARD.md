# Dataset Card — Primary Artifact

## Identity

- Dataset family: ROXANNE / Criminal Network Analysis and Visualization
- Selected artifact: `israel_lea_inp_burglary_offender_id_network.json`
- Upstream repository: https://github.com/erichoang/criminal-network-visualization
- Upstream blob SHA: `3afe9cbb4e313fb056f1b115c92a3f750f4698b9`
- Inspection date: 2026-09-30

## Exact inspected artifact

- Nodes/offenders: **17,237**
- Links: **21,302**
- Unique crimes: **24,087**
- Flattened offender-crime rows: **34,156**
- Earliest observed date: **2010-12-01**
- Latest observed date: **2020-09-28**
- X range: **0–1**
- Y range: **0–1**
- Edge weight range: **1–37**
- Edge type observed: `relation`
- Observed flag: true for inspected links

## Source description

The upstream documentation describes an anonymized burglary dataset from the Israel National Police with roughly 23,000 solved cases and network representations. The exact artifact above is the code/schema authority for this project.

## Ground truth

Do not assume that an anomaly label exists in this artifact.

The project will distinguish:

- source facts,
- derived behavioral features,
- anomaly scores,
- any externally documented ground truth.

No label will be fabricated.

## Privacy

- IDs are anonymized in the selected artifact.
- Coordinates are normalized.
- The project will not attempt re-identification or coordinate reversal.
- Raw data will remain local unless redistribution terms are explicitly confirmed.

## Intended use

Analyze observable behavioral patterns in an anonymized network. Model outputs are deviations from an analytical baseline, not determinations about criminality.

## Citation

Use the upstream project's required citation in the final report.
