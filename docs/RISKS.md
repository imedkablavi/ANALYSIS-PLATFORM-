# Risks and Mitigations

Updated 2026-09-30 after the audit. Ordered by current severity.

| # | Risk | Impact | Likelihood | Mitigation | Owner/status |
|---|---|---|---|---|---|
| R1 | **MATLAB code has never been executed** (written and statically parsed without MATLAB) | High | High that *some* runtime fixes are needed | fixture-based unit tests for every module; real-data regression test with independent expected values; run `run_tests.m` first (REPRODUCIBILITY §4) | open — first task of week 1 |
| R2 | Exact assignment wording not recorded (T-001) | High | – | transcribe the professor's sheet; re-check scope mapping | open — needs the human author |
| R3 | App behaviour/performance unverified (graph plots, timer, click selection) | High | Medium | app logic lives in tested pure functions; node cap 400; demo can fall back to report figures | open |
| R4 | Over-interpretation of scores/centrality as guilt or leadership | High | Medium | mandatory caveat in evidence text (tested); ethics doc; demo rules | mitigated |
| R5 | Seasonality produces spurious "unusual months" | Medium | High (July peak) | documented; T-043 seasonal baseline | open |
| R6 | No ground truth → weak evaluation claims | Medium | Certain | synthetic injection clearly labelled; stability; usability study; no accuracy claims | mitigated by design |
| R7 | Synthetic grid (≈1,200 forests) too slow on a laptop | Medium | Low–Medium | `QUICK` mode; reduce repeats in config | open |
| R8 | Upstream artifact changes | Medium | Low | blob-SHA check at download; version warning | mitigated |
| R9 | Graph and co-offending features are not independent | Medium | Certain | stated in ablation reading guide; not presented as corroboration | mitigated |
| R10 | Older MATLAB release lacks a function (< R2021b) | Medium | Low | requirement documented; baseline-only path without the toolbox | mitigated |
| R11 | Privacy leak via exported CSVs / screenshots | Medium | Low | outputs git-ignored; validation report ID-free (tested); no ID labels on figures | mitigated |
| R12 | Scope creep (extra models, community detection, audio narration) | Medium | Medium | decisions recorded as "considered, not added" | mitigated |
