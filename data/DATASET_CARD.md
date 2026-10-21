# Dataset Card — Primary Artifact

## Identity

- Dataset family: ROXANNE / Criminal Network Analysis and Visualization
- Selected artifact: `israel_lea_inp_burglary_offender_id_network.json`
- Upstream repository: https://github.com/erichoang/criminal-network-visualization
- Path: `datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json`
- Upstream Git blob SHA: `3afe9cbb4e313fb056f1b115c92a3f750f4698b9` (verified by `scripts/download_dataset.m`)
- Size: 15,551,662 bytes
- Inspection date: 2026-09-30

## Exact inspected artifact

- Nodes/offenders: **17,237** (type `offender` only)
- Links: **21,302** directed = **10,651** undirected relations (all reciprocal, equal weights)
- Unique crimes: **24,087**; flattened offender-crime rows: **34,156**
- Dates: **2010-12-01** to **2020-09-28**, day resolution; 91 rows before 2014
- X, Y: min-max scaled to [0,1]
- Edge weight: 1–37 = number of shared crimes (verified for every link)
- Edge type `relation`, `observed = true` for all links

Full detail: `docs/DATASET_SCHEMA_INSPECTION.md`.

## Source description

Upstream documentation: around 23,000 solved burglary cases in Israel (2012–2021) supplied by the
Israel National Police, "duly anonymized according to the standards of Israeli national law and
GDPR and further approved by a legal advisor of the Israel National Police". The source contained
crime ID, anonymized offender IDs, min-max-scaled site coordinates, timestamps and a free-text
embedding; the embedding is **not** part of this artifact. The exact artifact above is the
code/schema authority.

## Licence

The upstream repository is distributed under a BSD-3-Clause-style licence, "Copyright (c) 2021,
Consortium Board ROXANNE". Redistribution is permitted with the copyright notice; the project
nevertheless keeps raw data out of Git (conservative choice for a sensitive domain) and downloads
it on demand.

## Ground truth

No anomaly or other label exists in the artifact. No label is fabricated. Evaluation uses
validation checks, stability/sensitivity analysis and clearly labelled synthetic injections
(`docs/EVALUATION.md`).

## Privacy

- IDs are provider pseudonyms; coordinates are normalized.
- No re-identification, no external joins, no de-normalization of coordinates, no basemaps.
- See `docs/ETHICS_AND_LIMITATIONS.md`.

## Intended use

Analyze observable behavioural patterns in an anonymized network for a university research
project. Outputs are deviations from an analytical baseline, not determinations about criminality.

## Citation

Ahmadi, Z., Nguyen, H. H., Zhang, Z., Bozhkov, D., Kudenko, D., Jofre, M., Calderoni, F.,
Cohen, N., & Solewicz, Y. (2023). Inductive and transductive link prediction for criminal network
analysis. *Journal of Computational Science*, 72, 102063.
https://doi.org/10.1016/j.jocs.2023.102063
