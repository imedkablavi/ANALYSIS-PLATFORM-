# Temporal Analysis

## Objectives

- measure activity rhythm,
- identify bursts and gaps,
- detect abrupt changes,
- support event replay in the multimedia UI.

## Candidate methods

- time-window aggregation,
- inter-event time distributions,
- rolling mean/median,
- robust z-scores,
- EWMA-style deviations,
- change-point detection if justified.

## Visual outputs

- activity timeline,
- event density chart,
- rolling anomaly score,
- before/after comparison around a detected change.

## Evaluation

If ground truth event intervals exist, evaluate temporal localization. Otherwise report detection consistency and false-alert behavior using a documented reference strategy.
