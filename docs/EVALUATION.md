# Evaluation Plan

## Ground truth

**None exists** in the artifact, and none is fabricated. Consequently, no precision/recall/ROC
claims about real offenders are possible.

## What is evaluated instead

| Question | Method | Metrics |
|---|---|---|
| Is the data fit for analysis? | validation (E1) | failed checks by severity |
| Are detectors sensitive to known deviations? | **synthetic** injection per feature group (E5–E7), in the spirit of controlled benchmark construction (Emmott et al. 2013) | ROC-AUC, average precision (chance = injected fraction), precision at m (m = injected rows) — Campos et al. (2016) |
| Which information matters? | ablation: real-data ranking consistency (E4) + injection detection per feature set (E5–E7) | top-k Jaccard, Spearman; AUC/AP |
| Are results stable? | seeds, forest size, sample size, eligibility, budget (E8) | pairwise top-k Jaccard, Spearman |
| Do the two detectors agree? | E3 | Spearman, top-k Jaccard |
| Is temporal detection sensible? | causal rule on real months + change points; seasonality check (T-043) | flagged months vs calendar month |
| Is it fast enough? | E9 | seconds per stage, MB |

### Synthetic injection protocol

1. Take the prepared robust-z matrix of the real eligible population.
2. Choose 1 % of rows at random (seeded).
3. For one feature group, move each feature 3 or 5 robust SD further from the median in the
   direction it already deviates (random sign when z = 0).
4. Re-fit/score each detector on the contaminated matrix (as in real use) for every feature set.
5. Repeat 10 times; report mean and SD.

Limits: injected deviations are axis-aligned and group-coherent; real unusual behaviour need not
look like that. Results measure **sensitivity**, not real-world accuracy, and are always labelled
SYNTHETIC (file prefix `synthetic_`).

## Application evaluation (E10, human)

5–8 participants (classmates), think-aloud, after a 3-minute introduction:

| Task | Measure |
|---|---|
| T1 Find the highest-ranked offender record and state the dominant feature group | time, correctness |
| T2 Explain in one sentence why it was flagged, using the evidence tab | rubric (mentions ≥ 2 concrete deviations, no guilt language) |
| T3 Find when this offender's first co-offending tie appeared (replay) | time, correctness |
| T4 Identify an unusual month and say whether it could be seasonal | correctness |
| T5 Find a record that is *not* scored and explain why | correctness |

Plus SUS questionnaire (10 items) and one open question. Report model performance and usability
separately.

## Reporting principle

Separate: data quality, detector behaviour, synthetic sensitivity, stability, usability. State
the absence of ground truth in every results section.
