# Source Tree

The implementation is MATLAB-first and intentionally separated from the GUI.

## Modules

- `data/`: JSON ingestion, flattening and validation.
- `preprocessing/`: cleaning and normalization (next stage).
- `features/`: entity-level behavioral features.
- `behavior/`: baseline profile construction (next stage).
- `temporal/`: time-aware behavioral analysis.
- `spatial/`: normalized-coordinate analysis when supported.
- `graph/`: graph construction and network features.
- `sequence/`: event/interaction sequence analysis.
- `anomaly/`: anomaly detectors.
- `pattern/`: pattern discovery.
- `explainability/`: evidence generation.
- `evaluation/`: metrics and experiment runners.

## Current implementation

The first slice currently implements:

```text
JSON
 ↓
loadBurglaryNetwork
 ↓
flattenBurglaryEvents
 ↓
validateBurglaryNetwork
 ↓
buildOffenderGraph
 ↓
computeGraphFeatures
 ↓
buildBehaviorFeatures
 ↓
mergeFeatureTables
 ↓
outputs/experiments/
```
