# 30-Day Roadmap

## Days 1–3 — Scope and dataset
- freeze assignment interpretation,
- verify dataset license/terms,
- download primary candidate,
- inspect schema,
- create dataset card.

**Gate:** data can be loaded in MATLAB.

## Days 4–7 — Data pipeline
- validation,
- cleaning,
- normalization,
- entity/event tables,
- first exploratory plots.

**Gate:** reproducible `run_pipeline` works.

## Days 8–12 — Feature engineering
- temporal features,
- network features,
- optional spatial features,
- sequence representation,
- feature quality checks.

**Gate:** versioned feature matrix generated.

## Days 13–16 — Baseline analysis
- statistical anomaly baseline,
- graph metrics,
- initial pattern mining,
- baseline visualization.

**Gate:** first measurable anomaly result.

## Days 17–20 — ML and explainability
- Isolation Forest,
- threshold evaluation,
- feature ablation,
- evidence generation.

**Gate:** reproducible experiment report.

## Days 21–25 — MATLAB App Designer
- dashboard,
- network view,
- timeline,
- entity detail,
- filtering,
- replay.

**Gate:** app can inspect at least one detected anomaly end-to-end.

## Days 26–27 — Multimedia refinement
- animation polish,
- heatmap/spatial view if supported,
- optional audio cues,
- accessibility/readability checks.

## Days 28–29 — Final validation
- clean clone test,
- performance check,
- regression test,
- screenshots,
- demo dataset package if allowed.

## Day 30 — Delivery
- final report,
- presentation,
- demo script,
- GitHub cleanup,
- release tag.

## Scope rule
If a task threatens the core pipeline, cut optional features before cutting data quality, evaluation, or explainability.
