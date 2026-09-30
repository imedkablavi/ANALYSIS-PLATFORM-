# Evaluation Plan

## If ground truth exists

Use appropriate classification/detection metrics:

- Precision
- Recall
- F1
- ROC-AUC
- PR-AUC / Average Precision
- false positive rate

For time-localized events, also report temporal overlap or interval-based localization metrics where labels support them.

## If ground truth is incomplete or absent

Do not invent labels.

Use:

- expert-defined reference rules,
- synthetic perturbation tests clearly labeled as synthetic,
- stability analysis,
- manual qualitative review with a documented protocol.

## Application evaluation

Measure task completion for the multimedia UI:

- time to locate a flagged event,
- time to explain the alert,
- successful interaction rate,
- qualitative clarity feedback.

## Reporting principle

Always separate model performance from visual/interaction usability.
