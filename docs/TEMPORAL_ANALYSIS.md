# Temporal Analysis

Implemented in `src/temporal/` and `src/graph/computeDynamicGraphStats.m`.

## Data constraints

- Day resolution only (no time of day).
- 91 rows before 2014; series therefore start 2014-01.
- Solved cases: the last months are right-censored; the series ends 2020-08 (exclusive end 2020-09-01).
- July is the busiest calendar month overall.

## System level

| Output | Method | Parameters |
|---|---|---|
| monthly series | `buildActivitySeries`: crimes, active offenders, new offenders (first-ever crime), co-offending share, mean group size | `cfg.temporal.bin = "month"` |
| unusual months | configurable `detectTemporalAnomalies`: causal rolling or causal same-calendar-month robust baseline | rolling: 12 bins/≥6; seasonal: 5 prior years/≥3 same-month samples; |z| ≥ 3.5 |
| level shifts | `detectChangePoints`: penalized binary segmentation of the mean | min segment 6, ≤ 5 changes, penalty 2σ² log n |

Applied to crime counts, new offenders and co-offending share.

Reference computation during the audit (Python port, not a MATLAB result): the original rolling
rule flags 2016-07 and 2019-07; change points at 2015-04 and 2016-06. The configured production
method is now the causal same-calendar-month baseline, which avoids treating an established July
peak as anomalous. Both rules remain available and are compared in the pipeline output.

## Entity level

Gap statistics, burstiness, dormancy ratio and busiest-window share (docs/FEATURE_ENGINEERING.md).

## Dynamic network

Yearly windows 2014–2020 (`computeDynamicGraphStats`): active ties, new ties (first-ever shared
crime), persistent ties, edge persistence, Jaccard, components, largest component, mean degree.

## Playback

`buildPlaybackFrame(bundle, tEnd, windowMonths)` returns the crimes, active ties and new ties in
`[tEnd − window, tEnd)` plus whether the month is unusual; the app animates it month by month.

## Limitations and next steps

- The seasonal baseline needs at least three prior observations of the same calendar month before
  it can score a bin; early years therefore have NaN temporal anomaly scores.
- The data are solved cases, so temporal peaks can still reflect case-solving and reporting
  processes rather than the underlying event process.
- Monthly counts of solved cases mix offending and police solving activity.
