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

## Traceability (2026-09-30)

| Requirement | Implementation | Verification |
|---|---|---|
| FR-01 | `loadBurglaryNetwork`, `flattenBurglaryEvents`, `download_dataset.m` | `test_loader_and_events`, `test_real_dataset` |
| FR-02 | `validateBurglaryNetwork`, `writeValidationReport` | `test_validation` (every failure mode) |
| FR-03 | `canonicalEvents`, `buildCrimeTable`, `buildRelationTable`, `prepareFeatureMatrix` | `test_relations_and_graph`, `test_anomaly_and_metrics` |
| FR-04 | analysis bundle (docs/ARCHITECTURE.md), docs/DATA_DICTIONARY.md | `test_pipeline_fixture` |
| FR-05 | `featureRegistry`, `buildBehaviorFeatures` | `test_behavior_features` (hand-computed values) |
| FR-06 | `buildActivitySeries`, `detectTemporalAnomalies`, `detectChangePoints`, `computeDynamicGraphStats` | `test_temporal_spatial_patterns`, `test_relations_and_graph` |
| FR-07 | `buildOffenderGraph`, `computeGraphFeatures`, `computeCoreNumbers` | `test_relations_and_graph`, NetworkX cross-check |
| FR-08 | `encodeEventSequences`, `fitTransitionModel`, `scoreSequenceNovelty`, `mineSequenceNgrams` | `test_sequence` |
| FR-09 | `scoreRobustBaseline`, `scoreIsolationForest`, `runAnomalyDetection` | `test_anomaly_and_metrics` |
| FR-10 | `explainAnomalies`, `getEntityContext` | `test_anomaly_and_metrics`, `test_pipeline_fixture` |
| FR-11 | `app/NetworkBehaviorExplorer.m`, `src/visualization/*` | pure functions tested; app needs manual run |
| FR-12 | pipeline CSV/JSON outputs, app Export, `generate_report_figures.m` | manual |

All verification entries are **pending MATLAB execution** except the Python cross-check.
