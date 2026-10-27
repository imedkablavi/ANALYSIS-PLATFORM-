# Roadmap (recalculated 2026-09-30)

The analytical core, experiments and application are implemented but **unexecuted**. The remaining
plan front-loads execution risk, then evaluation, then presentation.

## Week 1 (Oct 1–7) — Execution gate
- Transcribe the assignment wording (T-001) and confirm scope (T-002).
- `run_tests.m`: fix every runtime failure until all fixture tests pass.
- Download dataset; `test_real_dataset` must reproduce the reference audit values.
- `run_pipeline.m` on real data; read the validation report; record timings.
- **Gate:** tests green, bundle produced, validation report committed as evidence in RESEARCH_LOG.

## Week 2 (Oct 8–14) — Evaluation
- `run_experiments.m` (QUICK, then full); record E1–E9 numbers in RESEARCH_LOG.
- T-043 seasonal baseline; compare July flags before/after.
- Review top-ranked explanations manually for wording and plausibility (no identity claims).
- Regenerate figures.
- **Gate:** experiments_summary.md produced and interpreted; limitations updated.

## Week 3 (Oct 15–21) — Application and demo
- Launch the app; walk through DEMO_SCENARIO; fix interaction/performance issues.
- Usability study E10 (5–8 participants).
- **Gate:** demo runs end-to-end twice without intervention.

## Week 4 (Oct 22–30) — Delivery
- Technical report (structure: introduction, data & validation, methodology, experiments,
  results, multimedia system, evaluation, ethics & limitations, conclusion).
- Presentation + recorded demo backup.
- Clean-clone test on a second machine; README/CHANGELOG; release tag.

## Scope rule
If time runs short, cut in this order: audio cue → pattern tab polish → E8 grid size → synthetic
repeats. Never cut validation, the eligibility rule, explanations or the ethics statements.
