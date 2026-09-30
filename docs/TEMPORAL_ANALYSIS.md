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
| unusual months | `detectTemporalAnomalies`: z_t = (x_t − median(x_{t−12..t−1})) / (1.4826·MAD); causal | window 12, ≥ 6 bins, |z| ≥ 3.5 |
| level shifts | `detectChangePoints`: penalized binary segmentation of the mean | min segment 6, ≤ 5 changes, penalty 2σ² log n |

Applied to crime counts, new offenders and co-offending share.

Reference computation during the audit (Python port, not a MATLAB result): the rule flags
2016-07 and 2019-07; change points at 2015-04 and 2016-06. The July flags coincide with the
seasonal peak → see limitation below.

## Entity level

Gap statistics, burstiness, dormancy ratio and busiest-window share (docs/FEATURE_ENGINEERING.md).

## Dynamic network

Yearly windows 2014–2020 (`computeDynamicGraphStats`): active ties, new ties (first-ever shared
crime), persistent ties, edge persistence, Jaccard, components, largest component, mean degree.

## Playback

`buildPlaybackFrame(bundle, tEnd, windowMonths)` returns the crimes, active ties and new ties in
`[tEnd − window, tEnd)` plus whether the month is unusual; the app animates it month by month.

## Limitations and next steps

- No seasonal component (T-043): candidate fix = baseline from the same calendar month in previous
  years (seasonal naive) or a rolling median of de-seasonalized counts; evaluate by how many July
  flags disappear without losing injected spikes.
- Monthly counts of solved cases mix offending and police solving activity.
