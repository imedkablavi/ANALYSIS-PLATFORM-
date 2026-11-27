# Explainability

Goal: a user can answer "why was this offender record ranked as unusual?" without reading code.

## Evidence structure (`explainAnomalies`, `entityEvidence`, `getEntityContext`)

```text
Alert (entity)
 ├─ Isolation Forest score, rank of N, review threshold
 ├─ Baseline score, rank of N, review threshold
 ├─ Per-feature evidence: value, reference median, robust z, notable (|z| ≥ 3.5)
 ├─ Baseline share   z_j² / Σ z²                       (exact additive decomposition)
 ├─ IF occlusion Δ   score − score(feature j reset to median)   (per feature and per group)
 ├─ Dominant feature group
 ├─ Context: events + tokens + surprisal, partners with shared crimes, component
 └─ Evidence text + interpretation caveat
```

Occlusion is a perturbation-based, model-agnostic attribution (cf. Siddiqui et al. 2019 on
feature-based explanations of anomalies). It is computed for every flagged entity and the top
100 by the primary detector in one batched `isanomaly` call per level.

## Example of generated text (format)

> Isolation Forest rank 3 of 3260 (score 0.712; review threshold 0.655). Robust baseline rank 5 of
> 3260 (RMS deviation 2.41 robust SD; threshold 2.10). Main evidence: longest dormancy / median gap
> = 45, higher than the typical 3.1 (+6.3 robust SD) [notable]; … Dominant feature group: temporal.
> Interpretation: a statistical deviation from the reference population of offenders with >= 3
> recorded crimes; it is not evidence of guilt, intent or dangerousness.

(The numbers above illustrate the format only; they are not results.)

## Entities that are not explained

- Ineligible: "Not scored: k recorded crime(s), below the minimum of 3 … not a statement that the
  behaviour is normal."
- Eligible but outside the budget: ranks are shown with the full deviation profile.

## Wording rules

Use "deviates from the reference", "unusually high/low", "newly observed partner", "rare
transition". Never convert a score into a statement about a person (docs/ETHICS_AND_LIMITATIONS.md).
