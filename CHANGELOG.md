# Changelog

## 0.2.0 — Audit and analytical core (2026-09-30)

Audit: docs/AUDIT_2026-09-30.md. MATLAB code statically parsed; **not executed** (no MATLAB in the
development environment).

### Fixed
- Crime IDs corrupted by `jsondecode` key conversion (`CID#2` → `CID_2`); restored via `list_cid`.
- `validateBurglaryNetwork` used an invalid `any(...,'omitnan')` call.
- Scripts did not add `configs/` to the path (`projectConfig` undefined).
- `tests/test_graph_features.m` had a syntax error and could never run.
- Partner counts doubled by summing in- and out-degree of a symmetric digraph.
- O(N·E) feature computation replaced by O(E log E + N).
- Zoned (`UTC`) datetimes that could not be compared with configuration dates.

### Added
- Data: 37-check validation with severities and JSON/CSV/Markdown reports; dataset download with
  Git-blob-SHA verification; canonical events; crime table; time-stamped relation table.
- Analysis: undirected co-offending graph with structural features (clustering, k-core,
  components, betweenness, articulation points); dynamic yearly graph statistics and window
  snapshots; temporal series with causal robust z-scores and change points; normalized-grid
  space–time Poisson excess; derived sequence alphabet with Markov surprisal and n-grams;
  recurring pairs and exact groups.
- Anomaly: feature registry (28 features, 6 groups), robust preparation, transparent baseline,
  Isolation Forest, review budget, detector agreement.
- Explainability: deviation profiles, exact baseline shares, occlusion attribution, evidence text.
- Evaluation: metrics (AUC, AP, precision@k, Jaccard, Spearman), synthetic injection, experiment
  suite E1–E9, E10 usability protocol.
- Application: `NetworkBehaviorExplorer` with linked ranking, network, timeline, spatial and detail
  views, replay (play/step/reset/window), optional audio cue, export.
- Tests: 9 MATLAB test files (67 tests) with synthetic fixtures and a real-data regression test.
- Verification: `scripts/reference/audit_dataset_reference.py` (independent reference audit).
- Docs: METHODOLOGY, REPRODUCIBILITY, ETHICS_AND_LIMITATIONS, AUDIT; all topic documents rewritten
  with decisions and sources.

### Changed
- Graph modelled as undirected (all links reciprocal).
- `run_first_pipeline.m` replaced by `run_pipeline.m` + `runAnalysisPipeline`.
- System-level temporal series limited to 2014-01 … 2020-08.

## 0.1.0 — Foundation

- Created repository structure, project context and scope rules, research and dataset planning
  documents, MATLAB-first architecture, 30-day roadmap, task board, definition of done,
  privacy/ethics requirements.
