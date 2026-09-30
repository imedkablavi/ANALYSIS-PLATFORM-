# Task Board

Status legend: ✅ done · 🔶 implemented, awaiting MATLAB execution · ⏳ open · ⛔ blocked on human input.
GitHub issue numbers in brackets (imedkablavi/ANALYSIS-PLATFORM-).

## M0 — Scope freeze
| Task | Status | Notes |
|---|---|---|
| T-001 Exact assignment transcription [#1] | ⛔ | needs the professor's sheet |
| T-002 Confirm interpretation | ⏳ | after T-001; map each phrase to REQUIREMENTS |

## M1 — Dataset
| Task | Status | Notes |
|---|---|---|
| T-010 Acquire/verify primary dataset [#2] | ✅ | blob SHA pinned; licence + citation recorded; download script |
| T-011 Dataset card | ✅ | data/DATASET_CARD.md |
| T-012 MATLAB ingestion [#3] | 🔶 | crime-ID restoration fix; fixture tests |
| T-013 Data validation [#3] | 🔶 | 37 checks, JSON/CSV/MD report |

## M2 — Analytical core
| Task | Status | Notes |
|---|---|---|
| T-020 Entity/event model [#4] | ✅ | bundle contract in docs/ARCHITECTURE.md; data dictionary |
| T-021 Temporal features [#5] | 🔶 | gaps, burstiness, dormancy, busiest window; system series |
| T-022 Network features [#5] | 🔶 | undirected graph; 8 structural features |
| T-023 Spatial features [#5] | 🔶 | radius of gyration, steps, repeats; grid hotspots |
| T-024 Sequence features [#5] | 🔶 | derived alphabet, Markov surprisal |

## M3 — Detection
| Task | Status | Notes |
|---|---|---|
| T-030 Statistical baseline [#6] | 🔶 | RMS robust z |
| T-031 Isolation Forest [#7] | 🔶 | seeded; agreement with baseline |
| T-032 Threshold strategy | 🔶 | review budget + |z| ≥ 3.5 evidence; E8 |
| T-033 Feature ablation | 🔶 | E4 (real) + E5–E7 (synthetic) |
| T-034 Explainability evidence [#8] | 🔶 | decomposition + occlusion + text |

## M4 — Pattern mining
| Task | Status | Notes |
|---|---|---|
| T-040 Frequent pattern analysis [#9] | 🔶 | recurring pairs / exact groups |
| T-041 Sequential pattern analysis [#9] | 🔶 | trigrams with support |
| T-042 Dynamic graph change analysis [#9] | 🔶 | yearly persistence, new ties, components |
| T-043 Seasonality-aware temporal baseline [#14] | 🔶 | causal same-month baseline implemented + regression test; comparison retained; MATLAB execution pending |
| T-044 Synthetic Isolation Forest evaluation [#15] | 🔶 | clean-reference training + injected scoring; MATLAB execution pending |

## M5 — Multimedia application
| Task | Status | Notes |
|---|---|---|
| T-050 App shell [#10] | 🔶 | programmatic uifigure app |
| T-051 Dashboard | 🔶 | |
| T-052 Interactive graph | 🔶 | ego network, click-to-select |
| T-053 Timeline | 🔶 | anomalies, change points, cursor |
| T-054 Entity detail | 🔶 | why / profile / events / partners |
| T-055 Event replay | 🔶 | slider, play/step/reset, window |
| T-056 Heatmap | 🔶 | normalized density + path |
| T-057 Optional audio cues | 🔶 | off by default |

## M6 — Evaluation & delivery
| Task | Status | Notes |
|---|---|---|
| T-060 Evaluation scripts [#11] | 🔶 | E1–E9 implemented; synthetic IF evaluation uses clean-train novelty scoring |
| T-061 Reproducibility run [#11] | ⏳ | first MATLAB execution remains the main gate |
| T-062 Demo scenario [#12] | 🔶 | docs/DEMO_SCENARIO.md updated |
| T-063 Technical report [#12] | ⏳ | METHODOLOGY + AUDIT provide the skeleton |
| T-064 Final presentation [#12] | ⏳ | |
| T-065 Repository cleanup and release [#12] | ⏳ | |
| T-066 Usability study (E10) | ⏳ | 5–8 participants, protocol in EVALUATION |
