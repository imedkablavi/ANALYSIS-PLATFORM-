# Project Context

## Objective

Build a one-month university project that implements the professor's network/behavior analysis topic at a substantially deeper level while remaining realistic to finish.

## Interpretation

The project focuses on detecting and explaining **observable suspicious/anomalous behavioral patterns** inside a network of interactions, events, communications, locations, or related entities. The exact wording of the assignment must remain the authoritative scope reference.

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

## Working hypothesis

A multi-view representation that combines temporal, relational/network, and event-sequence information should provide richer anomaly evidence than a single static network metric, while an interactive visualization should improve the user's ability to inspect and understand detected patterns.

## Delivery constraint

Timebox: 30 calendar days.

Priority order:

1. Reproducible data pipeline
2. Working analytical baseline
3. Validated anomaly detector
4. Explainable evidence
5. Multimedia UI
6. Advanced optional features
