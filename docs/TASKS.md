# Task Board — audited 2026-10-31

Statuses describe evidence, not optimism: **IMPLEMENTED** = code exists, current MATLAB
execution absent; **VERIFIED** = the named check actually ran; **PARTIAL** = deliverable has
unfinished parts; **MISSING** = required artifact/results absent; **BLOCKED** = external input
or runtime access is required. Historical issue numbers are retained for traceability.

CHANGELOG records **114/114 MATLAB Online tests on 2026-10-27**. That is historical
coverage, not a result for the revised 2026-10-31 code or newly added tests. Current
Python/reference checks and static lint do not replace MATLAB execution.

| Task | Status | Existing evidence and remaining work |
| --- | --- | --- |
| T-001 Exact assignment transcription [#1] | BLOCKED | `docs/ASSIGNMENT_SOURCE.md` records that source wording is unavailable; obtain the actual professor's wording. |
| T-002 Confirm interpretation | PARTIAL | Computer-network scope confirmed in `PROJECT_CONTEXT.md`; phrase-by-phrase requirements mapping still depends on T-001. |
| T-010 Acquire/verify primary dataset [#2] | VERIFIED | Official complete CTU-13 scenario 7 downloaded; `scripts/data/acquire_ctu13_scenario7.py` pins SHA256. `outputs/reference/ctu13-scenario7.json` records independent source audit; `docs/REAL_CAPTURE_EVIDENCE.md` documents provenance. |
| T-011 Dataset card | VERIFIED | `data/DATASET_CARD.md` records audited CTU-13 source/schema/label counts, fingerprints and limits; secondary burglary card is separate. No detector metric is inferred. |
| T-012 MATLAB ingestion [#3] | IMPLEMENTED | `src/data/importDataset.m`, `importNetworkFlows.m`, canonical builder and import regression tests; current runtime verification pending. |
| T-013 Data validation [#3] | IMPLEMENTED | `validateBurglaryNetwork.m`, report writer, delivery verifier; fresh MATLAB validation reports for scenario 7 pending. |
| T-020 Entity/event model [#4] | IMPLEMENTED | `buildCanonicalDataset.m`, `docs/ARCHITECTURE.md`, data dictionary; contract tests require fresh execution. |
| T-021 Temporal features [#5] | IMPLEMENTED | `buildBehaviorFeatures.m`, `src/temporal/`, configurable minute/hour/day bins; validate new capture time-series results. |
| T-022 Network features [#5] | IMPLEMENTED | `computeNetworkFeatures.m`, `src/graph/`; traffic and structural features, graph cost guards; current MATLAB timing/results missing. |
| T-023 Spatial features [#5] | IMPLEMENTED | Behavior spatial measures and `computeSpatialHotspots.m`; unsupported for CTU-13 without coordinates, retained for burglary case study. |
| T-024 Sequence features [#5] | IMPLEMENTED | `src/sequence/` alphabet, transition model, novelty and n-grams; execute regression checks. |
| T-030 Statistical baseline [#6] | IMPLEMENTED | `scoreRobustBaseline.m`; current capture detector results absent. |
| T-031 Isolation Forest [#7] | IMPLEMENTED | `scoreIsolationForest.m`; runtime requires Statistics and Machine Learning Toolbox. |
| T-032 Threshold strategy | IMPLEMENTED | `applyReviewBudget.m`, feature evidence thresholds, E8; generated calibration results absent. |
| T-033 Feature ablation | IMPLEMENTED | `runExperiments.m` E4–E7; current execution and interpretation pending. |
| T-034 Explainability [#8] | IMPLEMENTED | `explainAnomalies.m`, entity evidence and profile views; review actual generated explanations. |
| T-040 Frequent patterns [#9] | IMPLEMENTED | `mineCooffendingPatterns.m`; shared-event patterns also apply to communication peers. |
| T-041 Sequential patterns [#9] | IMPLEMENTED | `mineSequenceNgrams.m`; execute and inspect supports. |
| T-042 Dynamic graphs [#9] | IMPLEMENTED | `computeDynamicGraphStats.m`, adaptive snapshot windows. |
| T-043 Seasonal baseline [#14] | IMPLEMENTED | `detectTemporalAnomalies.m` and temporal regression tests; short captures use rolling bins rather than an annual-seasonality claim. |
| T-044 Synthetic IF evaluation [#15] | IMPLEMENTED | Clean-reference novelty evaluation in `runExperiments.m`; synthetic outputs must stay distinct from published labels. |
| T-050 App shell [#10] | IMPLEMENTED | `app/NetworkBehaviorExplorer.m`; historical screenshot/layout work exists, revised application needs a fresh launch. |
| T-051 Dashboard | IMPLEMENTED | App KPI/ranking views and `kpiSummary.m`; current interactions unverified. |
| T-052 Interactive graph | IMPLEMENTED | `plotEgoNetwork.m`, app linked entity selection; walkthrough pending. |
| T-053 Timeline | IMPLEMENTED | `plotActivityTimeline.m`, cursor/change-point views; capture-bin walkthrough pending. |
| T-054 Entity detail | IMPLEMENTED | `entityEvidence.m`, `getEntityContext.m`, app detail views. |
| T-055 Replay | IMPLEMENTED | `buildPlaybackFrame.m` and app controls; new flow chronology/direction tests await MATLAB. |
| T-056 Heatmap | IMPLEMENTED | `plotSpatialView.m`; not applicable to coordinate-free scenario 7. |
| T-057 Optional audio | IMPLEMENTED | App audio controls; optional, defaults off; current playback unverified. |
| T-060 Evaluation scripts [#11] | IMPLEMENTED | E1–E9 in `runExperiments.m`; `networkGroundTruth.m`/`evaluateGroundTruth.m` for published traffic labels. Actual current metrics missing. |
| T-061 Reproducibility run [#11] | BLOCKED | Fresh MATLAB run, tests, experiment outputs, timing and `verify_delivery.m` manifest needed. This is a rerun gate, not the project's first-ever MATLAB run. |
| T-062 Demo scenario [#12] | PARTIAL | `docs/DEMO_SCENARIO.md`, `scripts/run_network_demo.m`; two successful current-version walkthroughs and a backup recording absent. |
| T-063 Technical report [#12] | PARTIAL | `docs/report/TECHNICAL_REPORT.md` is written with factual limits; generated detector/experiment metrics and their interpretation remain unavailable. The former draft is a compatibility link. |
| T-064 Final presentation [#12] | MISSING | No completed slide deck or backup demo artifact; presentation constraints still needed. |
| T-065 Cleanup/release [#12] | PARTIAL | Source, tests and verification entrypoints exist; clean-machine runtime, synchronized deliverables and final release remain. |
| T-066 Usability E10 | PARTIAL | Protocol/forms and `scoreSUS.m`/`summarizeUsabilityLog.m` exist. Actual pilot, participant sessions, responses and resulting analysis are missing; network-specific tasks/answer key need review. |
| T-067 External event/edge import | IMPLEMENTED | `analyzeDataset.m`, dataset catalog, app open action, `docs/DATASET_IMPORT.md`; current regression execution pending. |
| T-068 Network datasets | PARTIAL | CTU/CIC/UNSW/LANL profiles implemented. Official scenario 7 independently audited: 114,077 flows, 38,204 hosts, 63 malicious-labelled flows. MATLAB detector execution absent; real CIC/UNSW/LANL imports remain unverified. |

## Highest-priority unfinished work

1. Run current MATLAB tests and complete scenario-7 pipeline/experiments; retain validation,
   timings, configuration/source hashes and delivery verification. Report failures honestly.
2. Add report detector/experiment results only from generated evidence. With only one labelled
   malicious host in scenario 7, qualify any host-level evaluation accordingly.
3. Exercise current GUI and prepare a network-specific demo, slides and backup artifact.
4. Obtain exact assignment/cover/presentation details and finish actual E10 sessions if retained.
5. Verify a clean checkout on the delivery machine; synchronize final documents and release.
