# Changelog

## Unreleased — post-audit hardening

- App redesign: shared theme (`appTheme`, WCAG-checked text contrast, single-hue score ramp), KPI tiles, ranking filters/search, themed plots, empty-state messages, datasets without coordinates.
- App dataset UI: "Open dataset…" (format detection, column-mapping dialog, progress dialog) and a dataset list fed by `listDatasets`; new tests in `tests/test_visualization_theme.m`.
- Replay, timeline legend and KPI tile follow the dataset's temporal bin (weekly bins for short imported datasets advanced the replay cursor by a month before).
- Dataset import hardening: identifier columns read as text, `#` kept inside values, explicit numeric time units, self-interactions as single-participant events.
- Fixed synthetic Isolation Forest evaluation to train on clean reference data and score contaminated synthetic observations as novelty detection.
- Added configurable causal temporal anomaly baselines: rolling 12-month and same-calendar-month seasonal reference.
- Production temporal mode now defaults to the seasonal same-month baseline; the rolling rule remains available for comparison.
- Added seasonality regression coverage and made the configured baseline label visible in the timeline.
- Stabilized ego-network anomaly color scaling globally so colors remain comparable across entity selections.
- Added a Poisson scale floor (scale ≥ √baseline) for count series: the seasonal baseline's 3–5
  reference values under-estimated counting noise and flagged three ordinary months on the real data.
- Seasonal regression test now separates "unscored" from "scored as normal"; new floor test.
- Code review (2026-10-19) fixes: timeline title built with `char + char` (numeric addition → crash
  of the timeline, app and report figures); rolling-baseline label now reflects the configured
  window; seasonal mode rejects non-monthly bins; binomial noise floor for the co-offending share;
  dynamic-graph windows end at the censored series end and carry a `partial` flag; activity series
  clipped to [t0, t1); app network shows all ties outside replay; E5–E7 reuse one forest per
  (feature set, repeat) instead of refitting it for every group and shift (~12× fewer fits).
- Usability study kit for E10 (T-066): protocol docs/USABILITY_STUDY.md, bilingual consent form,
  task sheet and SUS questionnaire (docs/usability/), CSV templates, `scoreSUS` and
  `summarizeUsabilityLog` with hand-computed tests (tests/test_usability_scoring.m);
  `outputs/usability/` git-ignored for raw participant data. No sessions run, no results.
- Second code review (xhigh, runtime semantics): `sequenceAlphabet` used `meshgrid` on strings
  (unsupported → pipeline would stop at the sequence stage); `error`/`warning` messages in the data
  scripts were 1x2 string arrays; seasonal scoring no longer runs for non-monthly bins; replay hides
  future ties instead of removing them (stable layout) with an exclusive cutoff; app timer survives
  plot errors; empty-event guard in sequence encoding; single-seed E8 no longer crashes; E4 reuses
  the stored full model; E8 min_events rows skip unused forests; one shared reference-median helper.
- Technical report draft (T-063) in docs/report/ with results as explicit placeholders.
- Documentation consistency: offenders-per-crime distribution corrected (sizes 10–12 had been
  truncated), mean group size basis stated, clean-reference novelty training described everywhere.
- External dataset import (T-067): `inspectDatasetFile`, `importDataset` (event CSV, temporal
  edge list incl. headerless SNAP files, primary JSON), `buildCanonicalDataset` (pseudonymized IDs,
  min-max scaled coordinates, documented import notes), `configureForDataset` (time windows/bins
  derived from the data), `analyzeDataset` + dataset catalog (`registerDataset`, `listDatasets`),
  `scripts/analyze_dataset.m`; validation marks link/coordinate checks "not applicable" for such
  data; evidence wording uses entity/event nouns. `outputs/datasets/` and `data/external/` git-ignored.
- TASKS_FOR_ADMIN.md: every item that needs the owner's data, permissions or decisions.
- MATLAB execution remains the final verification gate; no real runtime metrics are claimed yet.

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
