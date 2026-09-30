# Explainability

## Goal

A user must be able to answer “why was this flagged?” without reading source code.

## Evidence structure

```text
Alert
 ├─ anomaly score
 ├─ threshold
 ├─ top contributing feature groups
 ├─ temporal evidence
 ├─ network evidence
 ├─ sequence evidence
 └─ supporting visualization
```

## Minimum UI wording

Use language such as:

- “behavior deviates from baseline”
- “unusually high interaction frequency”
- “newly observed connection pattern”
- “repeated sequence detected”

Avoid statements that convert statistical anomaly into a claim that a person is criminal.
