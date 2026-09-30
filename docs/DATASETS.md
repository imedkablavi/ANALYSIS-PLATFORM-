# Dataset Strategy

## Primary candidate — ROXANNE-linked burglary network data

The public `erichoang/criminal-network-visualization` repository documents a primary burglary dataset containing about 23,000 solved burglary reports in Israel from 2012–2021. The repository says the records were provided by the Israel National Police, anonymized, and include crime identifiers, anonymized offender identifiers, min-max-scaled site coordinates, timestamps, and parameterized free-text case-description embeddings. It also provides offender-network and crime-network JSON/NDJSON representations.

Source:
- https://github.com/erichoang/criminal-network-visualization
- Dataset documentation: https://github.com/erichoang/criminal-network-visualization/blob/main/datasets/preprocessed/README.md

### Why this is the strongest primary candidate

- directly related to the professor's topic,
- real case-derived data,
- temporal information,
- spatial information in privacy-preserving form,
- entity relationships,
- network-ready representations,
- suitable for graph analysis and pattern mining.

### Important limitation

It is not a raw multimedia corpus. The “multimedia” component therefore comes primarily from interactive visualization, animation, maps/heatmaps, timeline replay, charts, and optional audio guidance. Do not claim the dataset itself contains surveillance video unless the downloaded data actually does.

## Secondary candidate — Enron email communication network

Stanford SNAP provides an Enron email communication network derived from publicly released records. The network has 36,692 nodes and 183,831 edges and is useful for temporal/communication network methodology and pipeline testing.

Source:
- https://snap.stanford.edu/data/email-Enron.html

Use this as a methodology/fallback dataset, not as direct evidence of criminal behavior.

## Secondary candidate — ROXANNE telephone communication examples

The same criminal-network visualization repository documents anonymized telephone communication datasets. Case 1 contains 33 phone calls; Case 2 covers communications among 124 individuals and identifies whether links are calls or SMS in the preprocessed network representation.

Source:
- https://github.com/erichoang/criminal-network-visualization/blob/main/datasets/preprocessed/README.md

These are useful for demonstrating temporal communication-network analysis but should not be mislabeled as a complete criminal ground-truth dataset.

## Secondary candidate — Madoff fraud network

The repository also documents a 61-node, 61-link network representing financial flows in the Madoff case.

Source:
- https://github.com/erichoang/criminal-network-visualization/blob/main/datasets/preprocessed/README.md

Useful for a small end-to-end demo and graph visualization.

## Repository of alternatives

Network Repository provides thousands of real-world graph datasets, including social, dynamic, spatial, and time-series network data.

Source:
- https://networkrepository.com/network-data.php

## Dataset selection gate

Before implementation, the team must record:

1. source URL,
2. license/terms,
3. exact download artifact,
4. schema,
5. ground-truth availability,
6. temporal coverage,
7. identifier semantics,
8. missingness,
9. privacy constraints,
10. why the dataset matches the assignment.

Do not download multiple large datasets and start coding blindly. Select one primary dataset first.
