# Behavior Modeling

## Behavioral profile

For each supported entity, create a profile from historical/reference observations.

Conceptual profile:

```text
Entity
 ├─ Temporal baseline
 ├─ Interaction baseline
 ├─ Network baseline
 ├─ Spatial baseline (optional)
 └─ Sequence baseline
```

## Baseline design

At least two approaches should be considered:

### Static baseline

Aggregate the whole reference period.

### Rolling baseline

Update the baseline over time to capture behavioral drift.

The final choice must be justified from data properties and the evaluation protocol.

## Output

The behavior layer should produce a machine-readable profile table plus diagnostic plots.
