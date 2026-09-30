# Dataset Acquisition Guide

## Recommended first download

Start with the public GitHub repository:

https://github.com/erichoang/criminal-network-visualization

Open:

`datasets/preprocessed/README.md`

The documented primary burglary dataset is available as a preprocessed offender network JSON and a crime network JSON. The documentation also lists temporal subgraphs and communication datasets.

## What to download first

For the first prototype, obtain:

1. `israel_lea_inp_burglary_offender_id_network.json`
2. `israel_lea_inp_burglary_v2_crime_id_network.json`

Do not commit the downloaded dataset into the repository until its license/redistribution terms have been checked. Put local copies under `data/raw/` and add them to `.gitignore` if redistribution is not allowed.

## Second download if needed

Use the documented telephone traffic example:

- `israel_lea_case1_speakers.json`
- or the Case 2 equivalent listed in the same README.

## Data acquisition record

Create `data/DATASET_CARD.md` containing:

- Dataset name
- Source organization
- URL
- Download date
- Version/commit/tag if available
- File names
- File sizes
- License/usage conditions
- Personal/sensitive data assessment
- Schema summary
- Target/ground truth definition
- Preprocessing notes
- Citation

## Never do this

- Do not scrape private social media accounts.
- Do not collect personal phone numbers or real identities.
- Do not publish raw personal data.
- Do not infer criminal propensity from protected characteristics.
