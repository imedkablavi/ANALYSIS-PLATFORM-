# Changelog

## Unreleased — 2026-11-04 professor review

- Consolidate source, observed-data examples, Turkish review notes and an email draft.
- Correct numeric text export, incomplete bidirectional traffic totals and
  unavailable/baseline-only detector comparisons; add regression coverage.
- MATLAB execution and GUI acceptance remain pending; do not merge based only
  on static checks or an overall green CI run with skipped MATLAB tests.

## Unreleased — 2026-11-02 Windows transfer

- Add an Arabic Windows/MATLAB transfer guide with extraction, tests, analysis,
  official data download commands and explicit current runtime limits.
- Package the current worktree (including uncommitted source), both fingerprinted
  official captures and per-file hashes without the Linux-linked `.git` file.
- Retain Git state and tracked-file patch in the transfer archive; verify ZIP
  contents and emit an archive SHA-256. No new MATLAB execution is claimed.

## Unreleased — 2026-10-31 correctness verification

- Correct tied-score AP, subdaily playback, proportion baselines and empty experiments.
- Stream file hashing, separate import identities and consistently filter malformed flows.
- Add regression tests and a delivery verification entry point retaining real run evidence.
- Report figures select a saved dataset and use its time windows and labels.
- MATLAB runtime validation of these changes is pending; no new metrics are claimed.


## Unreleased — post-audit hardening

- Progress log (`runLog`): timestamped steps on screen and in `outputs/logs/`; capture pre-scan `scripts/scan_capture.m` (label counts per block) and `first_row` slices for large captures.
- **First MATLAB execution (2026-10-27, MATLAB Online R2026b with Statistics and Machine Learning Toolbox): 114 / 114 tests passed** after three fixes from the first run (99 / 114): `biconncomp` cut-vertex names, hexadecimal ICMP "ports", row input in `empiricalQuantile`.
- Scope: computer-network traffic (owner decision 2026-10-20). New `network_flow` format with profiles for CTU-13 (binetflow), CIC-IDS2017 (GeneratedLabelledFlows), UNSW-NB15 (headered and the headerless 49-column files) and LANL (auth + redteam, flows); detection with content checks; `max_rows`; host pseudonymization; flow table without addresses (docs/NETWORK_DATASETS.md).
- Published labels → host ground truth (`labelNetworkFlows`, `networkGroundTruth`) and detector evaluation (`evaluateGroundTruth`: ROC-AUC, AP vs chance, precision/recall@k, known-only and unknown-as-benign); labels never reach features. App "Ground truth" tab.
- Feature version F3: 12 host traffic features (group `network`, incl. port entropy, fan-out/in, tiny-flow share, failed attempts, beaconing CV); palette slot 7 (validated).
- Temporal bins day/hour/minute (`binStep`), automatic choice by span; equal dynamic-graph windows for short captures; playback window in bins; mixed timestamp formats parsed completely; pair keys no longer limited to 1e6 entities.
- Python reference `scripts/reference/network_flow_reference.py`; tests `tests/test_network_datasets.m`.
- Scale guards for traffic graphs: clustering/betweenness skipped (with a recorded note) above configurable limits; busiest-window feature O(k log k) instead of O(k²) (equivalence checked on 2,000 random cases and in a MATLAB test).
- Network import usability: "Max records" field in the app import dialog; LANL `redteam.txt` next to `auth.txt` is used automatically; `scripts/analyze_dataset.m` takes MAX_ROWS / LABELS_FILE / PROFILE and prints the ground-truth evaluation.
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

### Evidence-oriented investigation (2026-10-31)
- Compared Slips, Malcolm, Arkime and Zeek using primary project documentation.
- Newly generated network bundles retain privacy-safe source flow records for bounded host investigation; labels remain separate from the observations table.
- Added regression coverage for flow chronology, direction, truncation and peer pseudonyms. MATLAB runtime/UI validation remains pending.

### Reproducible network delivery (2026-10-31)
- Added an offline streaming capture audit and three passing Python regression tests; CI runs them without a MATLAB license.
- Added `run_network_demo.m` to verify and analyse the complete pinned official CTU-13 scenario 7 and open that same bundle.
- Added a component node-edge workload budget for betweenness after checking the real capture's 1.58e9 work proxy; unavailable graph features remain explicit.
- Hardened verification manifests and retained source/experiment fingerprints. MATLAB execution remains pending.

### Product wording and documentation consistency (2026-10-31)
- Replaced shared crime/offender feature labels with event/entity/peer terminology and labelled configurable windows accurately.
- Added .binetflow selection and translated import, status and dialog copy; kept scientific limits and missing-value states explicit.
- Replaced the old report template with a factual technical report, updated primary CTU-13 dataset card and retained a separate secondary case-study card.
- Audited task/milestone/admin/roadmap documents against implementation evidence; unexecuted runtime and human deliverables remain distinguished from implemented code.

### Turkish/English investigation interface (2026-10-31)
- Turkish is the first-session default; Türkçe/English remains visible by name.
- Reworked header, readable type scale, ranking columns and narrow-window view arrangement.
- Language changes retain the in-memory investigation and stop playback instead of reloading the source file.
- Host explanations render measured scores and deviations in the selected language; stored numerical analysis remains unchanged.
- Localized table headings and added independent Turkish/English user guides and a GUI acceptance procedure.
- Editorial guidance uses Wikipedia's descriptive writing examples for clear, factual copy; no authorship-detection guarantee is claimed. Current GUI rendering still requires MATLAB acceptance.

### Interface readability — 2026-11-01
- Added exact locale-aware display counts and readable dataset-type labels; canonical metadata and counts remain unchanged.
- Added presentation-only localization for known table enums while retaining numeric values and original diagnostics.
- Deviation plots show the strongest twelve finite measurements with an explicit shown/total title; investigation exports retain full measured evidence.
- Added regression tests for count formatting, evidence selection and translated table values; current MATLAB execution remains pending.

### Presentation data and code explanation — 2026-11-01
- Removed the three upstream software-test captures from the local presentation directory and removed their acquisition helper; retained the complete official CTU-13 scenario 7.
- Public launch selects a saved validated network analysis or an empty interface, without fixture/historical-dataset fallback.
- Default experiments and delivery verification disable synthetic injection; explicit research outputs remain isolated and labelled.
- Added the Arabic code guide with per-file explanations and a source inventory. Unit-test fixtures remain isolated from application data.
- MATLAB execution and interactive acceptance remain required; static checks are not reported as detector results.

### Reusable external dataset imports — 2026-11-01
- Added generic flow schemas, editable mappings, timestamp-unit/format overrides and validated record ranges while preserving known profile priority.
- Custom labels remain unknown; tightened CIC auto-detection to avoid interpreting unrelated label columns as attack ground truth.
- Import pipeline rejects unsupported binary input, closes logging on errors and isolates each dataset's outputs/configuration.
- Added regressions for multiple independent files, profile compatibility, invalid fields and the import dialog's structural options.
- Acquired and independently audited official CTU-13 scenario 11 as a second real input; no MATLAB detector result is claimed.
