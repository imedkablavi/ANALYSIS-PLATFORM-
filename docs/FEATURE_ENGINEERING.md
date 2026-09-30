# Feature Engineering

## Goal

Convert raw records into measurable indicators of observable behavior.

## Feature families

### Temporal

- activity count per time window
- inter-event time
- active-hour distribution
- burstiness
- day-of-week concentration
- recent-vs-historical activity ratio

### Network

- degree
- weighted degree
- in/out degree when directed
- neighborhood size
- edge weight statistics
- component/community membership
- centrality metrics where justified

### Spatial (only when supported)

- number of unique locations
- location entropy
- radius/dispersion
- transition frequency
- deviation from historical spatial baseline

### Sequence

- event n-grams
- transition probabilities
- repeated subsequences
- sequence novelty
- time-normalized sequence frequency

### Change features

- rolling z-score
- exponentially weighted deviation
- baseline-to-current ratio
- change-point indicator

## Leakage control

Never compute a feature using information that occurs after the prediction/detection timestamp when evaluating prospective detection.

## Scaling

Scaling must be fit on training/reference data only when the selected evaluation design requires it.

## Feature versioning

Every experiment must record the feature set version and configuration file used.
