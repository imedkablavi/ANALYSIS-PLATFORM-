# Experiments

Run: `run scripts/run_experiments.m` after `run scripts/run_pipeline.m`. Implementation:
`src/evaluation/runExperiments.m`. Output: `outputs/experiments/` (`E*_*.csv`,
`synthetic_*.csv`, `experiments_summary.md`). Every run records seed, MATLAB version, feature
version and settings. **No results are reported here until a MATLAB run produces them.**

| ID | Question | Design | Output |
|---|---|---|---|
| E1 | Does the raw artifact pass validation? | 37 checks with severities | `E1_validation_checks.csv`, `outputs/reports/validation_report.*` |
| E2 | How does the transparent baseline behave? | score quantiles, flagged count, dominant groups | `E2_E3_score_quantiles.csv`, `E2_E3_dominant_groups.csv` |
| E3 | How does Isolation Forest behave, and does it agree with the baseline? | same matrix, same budget; Spearman, top-k Jaccard | same files + summary |
| E4 | Which feature groups drive the ranking on real data? | 10 feature sets (each group alone, cumulative sets, full); ranking consistency with the full model | `E4_ablation_real_ranking_consistency.csv` |
| E5 | Is unusual temporal behaviour detected? | SYNTHETIC: shift temporal features of 1 % of the clean real reference population by 3 / 5 robust SD; 10 repeats; every feature set | `synthetic_E5_E7_injection_*.csv` |
| E6 | Does network information improve detection? | same, graph group injected; Isolation Forest is fit on clean reference rows and scores the injected sample | same |
| E7 | Does sequence information improve detection? | same, sequence group injected; Isolation Forest uses clean training and injected scoring data | same |
| E8 | How sensitive are results? | seeds 1–10 (pairwise top-k Jaccard); NumLearners 50–400; NumObservationsPerLearner 64–512; min_events 2/3/5; budget 0.5–5 % | `E8_sensitivity.csv` |
| E9 | Runtime and memory | per-stage timings; bundle size | `E9_performance.csv` |
| E10 | Can users interpret the system? | task-based study (docs/EVALUATION.md) | study sheet (manual) |

Spatial, activity and co-offending injections run in the same grid (reported, not separately
numbered).

## Reading the ablation correctly

Graph and co-offending features both derive from shared-crime counts (verified). A graph-only
model detecting a co-offending injection is therefore expected and not independent confirmation.

## Reproducibility record

Each experiment stores dataset version (blob SHA), feature version (`F2`), random seed(s), model
settings, threshold strategy (review budget) and artifact names.

## Synthetic evaluation protocol

The baseline keeps the original clean robust reference frame. For Isolation Forest, each synthetic run
fits on the clean real reference matrix and scores a separately contaminated copy. This is a
novelty-detection setup and avoids training on the injected anomalies, matching the intended use of
an Isolation Forest with uncontaminated training data. Synthetic metrics remain sensitivity tests,
not real-world accuracy.

## Runtime expectation

The synthetic grid fits ≈ 6 groups × 2 shifts × 10 repeats × 10 sets ≈ 1,200 small Isolation Forest
runs. Use `QUICK = true` first.
