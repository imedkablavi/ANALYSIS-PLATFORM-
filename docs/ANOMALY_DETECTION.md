# Anomaly Detection

Implemented in `src/anomaly/`; orchestrated by `runAnomalyDetection`.

## Protocol

| Step | Decision | Reason |
|---|---|---|
| Population | offenders with ≥ 3 crimes (`cfg.anomaly.min_events`), 3,260 | temporal and sequence features need ≥ 2 gaps; others are "insufficient history" |
| Features | 6 groups from `featureRegistry` (ablation unit = group) | coherent, documented, explainable |
| Transform | `log1p` for heavy-tailed counts | robust scale not dominated by a few extremes |
| Scaling | median / 1.4826·MAD fit on the population; MAD = 0 → 1.2533·mean abs. dev.; still 0 → drop feature | many graph features are 0 for > 50 % of offenders |
| Missing | impute z = 0 (reference median), recorded | never silently |
| Baseline | score = sqrt(mean(z²)) | transparent, deterministic, exactly decomposable |
| Model | Isolation Forest, `iforest`, 200 trees, 256 samples/tree, `rng(42,"twister")`, `ContaminationFraction = 0` | linear-time, few assumptions, native MATLAB (Liu et al. 2008) |
| Threshold | review budget: top 1 % per detector (33 of 3,260) | no labels → no statistically "correct" cut-off; budget is explicit and varied in E8 |
| Comparison | Spearman ρ and top-k Jaccard between detectors | agreement = robustness evidence, not accuracy |

Scores in [0,1] for Isolation Forest (higher = easier to isolate); baseline scores are in
robust-SD units. Both are relative to this population and this dataset.

## Why these two methods

- The **baseline** is what a reviewer can recompute by hand; every flag decomposes into feature
  shares.
- **Isolation Forest** captures unusual *combinations* that no single z-score shows, scales
  linearly and is available in MATLAB (`iforest`/`isanomaly`). For synthetic evaluation it is
  used in novelty-detection mode: the forest is fitted on uncontaminated reference rows and scores
  the injected observations.
- **Not added**: LOF (density-based, sensitive to `k` and to many tied values in count features),
  One-Class SVM (kernel and ν selection impossible without labels), Robust Random Cut Forest
  (streaming focus not needed). Adding models without an evaluation signal would only add
  quantity. The decision can be revisited if E5–E8 show systematic blind spots.

## Model selection criterion

Not the number of anomalies. Preference order: (1) sensitivity to injected deviations of every
feature group (E5–E7), (2) stability across seeds and settings (E8), (3) interpretability.

## Reproducibility

Seed, NumLearners, NumObservationsPerLearner, population size, feature count, dropped features and
agreement are written to `outputs/experiments/pipeline_run.json`.

Sources: Liu, Ting & Zhou (2008); Iglewicz & Hoaglin (1993); MATLAB `iforest` documentation.


## Evaluation interpretation

There are two distinct uses in this project:

1. **Real-data descriptive outlier ranking:** the forest and robust baseline score the eligible
   reference population itself because no external labels or uncontaminated "normal" set exist.
2. **Controlled synthetic sensitivity testing:** the forest is trained on clean reference data and
   scores a separately injected sample. This avoids contaminating the forest with the synthetic
   anomalies.

MathWorks documents this distinction explicitly: uncontaminated training data should be used for
Isolation Forest novelty detection with `isanomaly`. See the official documentation:
https://www.mathworks.com/help/stats/iforest.html
