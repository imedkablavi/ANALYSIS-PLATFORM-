# Architecture

## Pipeline (implemented)

```text
data/raw/*.json ──verifyGitBlobSha
   │
   ▼  src/data            loadBurglaryNetwork → flattenBurglaryEvents → validateBurglaryNetwork → writeValidationReport
   ▼  src/preprocessing   canonicalEvents · buildCrimeTable · buildRelationTable (time-stamped ties)
   ▼  src/graph           buildOffenderGraph (undirected) · computeGraphFeatures · computeCoreNumbers
   │                      buildGraphSnapshot · computeDynamicGraphStats
   ▼  src/features        featureRegistry · buildBehaviorFeatures · mergeFeatureTables
   ▼  src/sequence        encodeEventSequences · fitTransitionModel · scoreSequenceNovelty · mineSequenceNgrams
   ▼  src/temporal        buildActivitySeries · detectTemporalAnomalies · detectChangePoints
   ▼  src/spatial         computeSpatialHotspots
   ▼  src/pattern         mineCooffendingPatterns
   ▼  src/anomaly         prepareFeatureMatrix · scoreRobustBaseline · scoreIsolationForest · applyReviewBudget · runAnomalyDetection
   ▼  src/explainability  explainAnomalies
   ▼  src/pipeline        runAnalysisPipeline  ──►  outputs/model/analysis_bundle.mat
   │
   ├─► src/evaluation     runExperiments (E1–E9) · metrics · injectSyntheticAnomalies
   └─► src/visualization  getEntityContext · entityEvidence · buildPlaybackFrame · plot*  ──►  app/NetworkBehaviorExplorer.m
```

## Shared analytical model (the bundle)

One struct connects every layer: **Entity → Events → Behaviour → Relationships → Time → Patterns →
Anomaly → Explanation → Visualization**.

| Field | Grain | Keys |
|---|---|---|
| `entities` | offender | `entity_index` (row = node order), `entity_id` |
| `events` | offender × crime | `entity_index`, `crime_id`, `seq_pos` |
| `crimes` | crime | `crime_id` |
| `relations`, `pairEvents` | offender pair (× crime) | `a_index < b_index` |
| `graph` | MATLAB `graph`, node k = entity k | |
| `temporal`, `spatial`, `dynamicGraph`, `patterns`, `sequence` | system level | time bins, grid cells, windows |
| `anomaly` | eligible offenders | same `entity_index` |
| `explanations` | explained offenders | `entity_index` |
| `registry`, `config`, `validation`, `meta` | run | |

`entity_index` is the integer key everywhere, so linking views is an index lookup, never a string
join.

## Separation of concerns

- `src/` contains all analysis; no function depends on the GUI.
- `src/visualization/` contains pure context functions (tested) and axes-parameterized plotting
  functions shared by the app and report figures.
- `app/` contains only layout and callbacks.
- `scripts/` are thin entry points; `configs/projectConfig.m` holds every parameter.
- `tests/` use synthetic fixtures; `tests/test_real_dataset.m` checks the real artifact against the
  independent reference audit.

## Performance decisions

| Step | Complexity | Note |
|---|---|---|
| JSON decode | O(file) | decoded JSON dropped immediately after flattening |
| date parsing | one vectorized `datetime` call | previously 34k calls |
| entity features | O(E log E + N) via contiguous row ranges | previously O(N·E) string scans |
| relations | Σ k(k−1)/2 over crimes ≈ 15k rows | vectorized per group size |
| clustering | sparse (A·A)∘A | |
| k-core | batch peeling, few rounds | verified vs NetworkX |
| betweenness | Brandes, bounded by component sizes (≤ 518) | |
| Isolation Forest | O(trees · samples · log samples) | 3,260 × ≤ 28 matrix |
| occlusion | one batched `isanomaly` call per level | K × p rows |

Parallel Computing Toolbox is not needed at this size.
