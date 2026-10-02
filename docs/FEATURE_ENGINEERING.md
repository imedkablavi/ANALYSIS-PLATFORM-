# Feature Engineering

**Single source of truth:** `src/features/featureRegistry.m` (name, group, transform, minimum
events, label, formula, source fields). This table mirrors it; feature version `F2`
(`cfg.project.feature_version`).

Notation: an offender with k crimes at dates t₁ ≤ … ≤ t_k (days), gaps g_i = t_{i+1} − t_i,
sites p_i = (x_i, y_i) in normalized units, group sizes n_i = `num_of_offenders`.
"min" = minimum number of crimes for the feature to be defined; otherwise `NaN`.

| Feature | Group | min | Transform | Formula |
|---|---|---|---|---|
| `event_count` | activity | 1 | log1p | k |
| `active_span_days` | activity | 1 | – | t_k − t₁ |
| `active_day_count` | activity | 1 | log1p | number of distinct dates |
| `iet_median_days` | temporal | 3 | log1p | median(g) |
| `iet_cv` | temporal | 3 | – | std(g)/mean(g) (NaN if mean = 0) |
| `burstiness` | temporal | 3 | – | B = (σ_g − μ_g)/(σ_g + μ_g) ∈ [−1, 1] (Goh & Barabási 2008); −1 periodic, 0 Poisson-like, → 1 bursty |
| `max_gap_ratio` | temporal | 3 | log1p | max(g)/max(median(g), 1 day) — long dormancy then reactivation |
| `peak_window_share` | temporal | 3 | – | max_j #{i : t_j ≤ t_i < t_j + 30 d} / k |
| `same_day_fraction` | temporal | 2 | – | 1 − distinct dates / k |
| `radius_of_gyration` | spatial | 2 | – | sqrt(mean‖p_i − p̄‖²) (González et al. 2008) |
| `mean_step_distance` | spatial | 2 | – | mean ‖p_{i+1} − p_i‖ in date order |
| `max_step_distance` | spatial | 2 | – | max ‖p_{i+1} − p_i‖ |
| `location_repeat_fraction` | spatial | 2 | – | 1 − distinct sites / k |
| `mean_group_size` | co-offending | 1 | – | mean(n_i) |
| `solo_fraction` | co-offending | 1 | – | share of n_i = 1 |
| `max_group_size` | co-offending | 1 | – | max(n_i) |
| `repeat_partner_fraction` | co-offending | 1 | – | partners with ≥ 2 shared crimes / partners (0 without partners) |
| `degree` | graph | 1 | log1p | number of distinct co-offenders |
| `strength` | graph | 1 | log1p | Σ shared crimes over partners |
| `max_tie_weight` | graph | 1 | log1p | max shared crimes with one partner |
| `clustering_coef` | graph | 1 | – | triangles / (d(d−1)/2), 0 if d < 2 (Watts & Strogatz 1998) |
| `core_number` | graph | 1 | log1p | k-core index (Batagelj & Zaversnik 2003) |
| `component_size` | graph | 1 | log1p | offenders in the connected component |
| `betweenness` | graph | 1 | log1p | unweighted shortest-path betweenness (Freeman 1977) |
| `is_cut_vertex` | graph | 1 | – | 1 if an articulation point |
| `seq_surprisal_mean` | sequence | 2 | – | mean −log₂ P(token_t | token_{t−1}) |
| `seq_surprisal_max` | sequence | 2 | – | max of the same |
| `new_partner_rate` | sequence | 1 | – | share of crimes with ≥ 1 previously unseen partner |

`component_id` is stored for navigation but is not a model feature.

## Decisions

- **`NaN`, not 0, for undefined features.** "One crime" is insufficient history, not zero
  variability. The anomaly population (≥ 3 crimes) has all temporal features defined; residual
  `NaN` is imputed at the reference median and recorded in `prep.imputed`.
- **Why gaps need ≥ 3 crimes.** With 2 crimes there is one gap: no dispersion, no burstiness.
- **Radius of gyration replaces mean pairwise distance** (the previous `spatial_dispersion`): same
  concept, O(k) instead of O(k²), standard in mobility research.
- **In/out degree removed.** Every link is reciprocal, so in = out and total = 2 × partners.
- **`num_of_offenders` is redundant** with attached offenders (verified), so group-size features
  and graph features overlap by construction; ablation results must be read with that in mind.
- **Heavy-tailed counts** (`log1p`) keep a handful of extreme counts from dominating the robust
  scale; Isolation Forest is invariant to such monotone transforms.

## Leakage control

The anomaly setting is unsupervised and transductive (no labels, no prediction target), so
supervised leakage does not arise. Temporal leakage is prevented where time matters:
`group_state` uses only earlier events, system-level temporal z-scores use only earlier months,
and `fitTransitionModel` accepts a row mask for temporal hold-out experiments.

## Scaling

Robust scaling (median, 1.4826·MAD; fallback 1.2533·mean absolute deviation; constant features
dropped) is fit on the eligible population in `prepareFeatureMatrix`. The same prepared matrix is
used by both detectors.
