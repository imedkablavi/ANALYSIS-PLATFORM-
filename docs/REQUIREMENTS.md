# Requirements

## Functional requirements

### FR-01 Data ingestion

The system shall import at least one real, documented dataset from CSV, JSON, NDJSON, MATLAB, or another reproducible source format.

### FR-02 Data validation

The system shall validate required fields, data types, missingness, duplicate records, invalid timestamps, and identifier consistency.

### FR-03 Preprocessing

The system shall implement documented cleaning, normalization, aggregation, and derived-field rules.

### FR-04 Entity representation

The system shall construct a consistent entity table and an interaction/event table.

### FR-05 Behavioral profiling

The system shall derive baseline behavioral statistics for each entity or network unit supported by the dataset.

### FR-06 Temporal analysis

The system shall provide time-based aggregates and detect significant temporal deviations.

### FR-07 Network analysis

The system shall construct a graph and compute a justified set of node/edge statistics.

### FR-08 Sequence analysis

The system shall represent event or interaction sequences and identify at least one recurrent or anomalous sequence pattern.

### FR-09 Anomaly detection

The system shall implement at least one unsupervised anomaly detector and one baseline comparison.

### FR-10 Explainability

Every displayed anomaly shall have a human-readable evidence summary derived from measurable features.

### FR-11 Interactive multimedia UI

The MATLAB app shall provide synchronized views for network, timeline, charts/heatmaps, entity detail, and event replay where applicable.

### FR-12 Export

The application shall export selected analytical results to figures and a machine-readable summary.

## Non-functional requirements

- Reproducible experiments
- Clear modular code
- Robust error handling
- No hard-coded dataset-specific assumptions outside configuration
- No raw sensitive data embedded in screenshots or commits
- UI must remain responsive for the selected project-sized sample

## Acceptance criteria

The project is considered baseline-complete when a fresh clone can:

1. load the documented dataset,
2. run preprocessing,
3. produce features,
4. run the baseline detector,
5. generate evaluation artifacts,
6. open the MATLAB app,
7. select an entity/event,
8. inspect the evidence behind a detection.
