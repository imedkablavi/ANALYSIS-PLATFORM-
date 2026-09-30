# Project Context

## Objective

Build a one-month university project that implements the professor's assigned network/behavior analysis topic at a substantially deeper level while remaining realistic to finish.

## Interpretation

The project focuses on detecting and explaining **observable suspicious/anomalous behavioral patterns** inside a network of interactions, events, communications, locations, or related entities. The exact wording of the assignment must remain the authoritative scope reference.

## Current verified primary artifact

The selected upstream artifact is:

`israel_lea_inp_burglary_offender_id_network.json`

Verified on 2026-09-30 from upstream blob SHA:

`3afe9cbb4e313fb056f1b115c92a3f750f4698b9`

Observed schema:

- NetworkX JSON
- directed=true
- multigraph=false
- 17,237 offender nodes
- 21,302 relation links
- 24,087 unique crime IDs
- 34,156 offender-crime association rows
- crime-detail fields: X, Y, date, num_of_offenders
- link fields: weight, type, observed, source, target
- observed crime-detail dates: 2010-12-01 through 2020-09-28

Full inspection:
`docs/DATASET_SCHEMA_INSPECTION.md`

## Current implementation status

Foundation: complete.

First data/feature implementation slice: complete in repository.

Local execution status: **blocked only by local dataset availability and MATLAB execution**; no performance claims have been made.

## Non-goals

- Do not claim to predict criminality from demographic or protected attributes.
- Do not identify real people.
- Do not build a production law-enforcement system.
- Do not add web/mobile stacks merely for visual appearance.
- Do not use fabricated results as experimental evidence.

## Research questions

1. Which behavioral features best separate baseline behavior from anomalous behavior?
2. Does temporal context improve anomaly detection over static network features?
3. Does combining node-level and edge-level features improve detection?
4. Can repeated/sequential patterns explain why a data point was flagged?
5. Can the same analytical result be communicated more effectively through interactive multimedia visualization than through tables alone?

## Delivery constraint

Timebox: 30 calendar days.

Priority order:

1. Reproducible data pipeline
2. Working analytical baseline
3. Validated anomaly detector
4. Explainable evidence
5. Multimedia UI
6. Advanced optional features
