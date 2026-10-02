# Source Tree

All analysis is MATLAB and independent of the GUI. Entry point: `pipeline/runAnalysisPipeline.m`.

| Folder | Responsibility | Main functions |
|---|---|---|
| `data/` | ingestion, validation, reports, dataset hash | `loadBurglaryNetwork`, `flattenBurglaryEvents`, `validateBurglaryNetwork`, `writeValidationReport`, `verifyGitBlobSha` |
| `preprocessing/` | canonical events, crimes, relations | `canonicalEvents`, `buildCrimeTable`, `buildRelationTable` |
| `features/` | feature definitions and entity features | `featureRegistry`, `buildBehaviorFeatures`, `mergeFeatureTables` |
| `graph/` | structural and dynamic network analysis | `buildOffenderGraph`, `computeGraphFeatures`, `computeCoreNumbers`, `buildGraphSnapshot`, `computeDynamicGraphStats` |
| `temporal/` | system-level time series | `buildActivitySeries`, `detectTemporalAnomalies`, `detectChangePoints` |
| `spatial/` | normalized-space density and space–time excess | `computeSpatialHotspots` |
| `sequence/` | event tokens and sequence novelty | `sequenceAlphabet`, `encodeEventSequences`, `fitTransitionModel`, `scoreSequenceNovelty`, `mineSequenceNgrams` |
| `pattern/` | recurring co-offending structures | `mineCooffendingPatterns` |
| `anomaly/` | detectors and thresholds | `prepareFeatureMatrix`, `scoreRobustBaseline`, `scoreIsolationForest`, `applyReviewBudget`, `runAnomalyDetection` |
| `explainability/` | evidence and attribution | `explainAnomalies` |
| `evaluation/` | metrics and experiments | `rankAuc`, `averagePrecision`, `precisionAtK`, `topKJaccard`, `spearmanRho`, `tiedRanks`, `injectSyntheticAnomalies`, `runExperiments` |
| `visualization/` | app/report support (pure + plotting) | `getEntityContext`, `entityEvidence`, `buildPlaybackFrame`, `plotActivityTimeline`, `plotEgoNetwork`, `plotSpatialView`, `plotEvidenceBars`, `plotScoreComparison` |
| `pipeline/` | orchestration | `runAnalysisPipeline` |
| `util/` | small shared helpers | `cfgGet`, `robustCenterScale`, `empiricalQuantile`, `joinStrings`, `writeTextFile` |

`behavior/` and `explainability/` naming follows docs/ARCHITECTURE.md; behavioural profiles are the
feature table (docs/BEHAVIOR_MODEL.md).
