# Experiments

## Experiment matrix

### E1 — Data quality

Measure missingness, duplicates, invalid timestamps, graph connectivity, and class/label availability.

### E2 — Baseline statistical detector

Evaluate a transparent baseline.

### E3 — Isolation Forest

Evaluate anomaly scores against the same evaluation split/reference period.

### E4 — Feature ablation

Compare:

- temporal only,
- network only,
- temporal + network,
- temporal + network + sequence,
- spatial only when justified.

### E5 — Visualization usability

Run a small user test with representative tasks such as “find the most anomalous event” and “explain why it was flagged.”

## Reproducibility

Every experiment must store:

- dataset version,
- feature version,
- random seed,
- model settings,
- threshold strategy,
- output artifact names.
