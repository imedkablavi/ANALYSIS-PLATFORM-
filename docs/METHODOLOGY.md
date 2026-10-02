# Methodology

This document is the end-to-end method in the order it runs (`src/pipeline/runAnalysisPipeline.m`).
Each section states the decision, the reason and where the detail lives. All parameters are in
`configs/projectConfig.m`.

## 1. Framing and terminology

The system measures **deviation of observable records from a reference population**. Outputs are
called *anomaly scores*, *behavioural deviations*, *unusual patterns*. They are never statements
about guilt, intent or dangerousness (docs/ETHICS_AND_LIMITATIONS.md). The unit of analysis is the
anonymized offender record (`OID#n`) and its attached solved-burglary records (`CID#n`).

## 2. Data, validation and preprocessing

- **Source**: one pinned artifact (Git blob SHA `3afe9cbb…`), verified at download
  (`verifyGitBlobSha`).
- **Ingestion** restores original crime IDs that `jsondecode` rewrites (`CID#2` → `CID_2`).
- **Validation** (37 checks, severities error / warning / info) runs before any analysis; an
  error stops the pipeline. Nothing is silently repaired. Report: `outputs/reports/validation_report.*`.
- **Canonical events**: one row per (offender, crime); duplicates are dropped *and* reported
  (V42); order = date, then numeric crime ID for same-day events (the artifact has no time of day).
- **Relations** are rebuilt from shared crimes, which reproduces every file link and weight (V52–V54)
  and adds first/last shared date to each relation.

## 3. Behavioural features

28 entity-level features in six groups (activity, temporal, spatial, co-offending, graph,
sequence), defined once in `featureRegistry.m` and documented with formulas in
docs/FEATURE_ENGINEERING.md. Undefined values (e.g. gaps of an offender with one crime) are `NaN`,
never 0.

## 4. Temporal analysis

- **System series**: monthly crimes, active offenders, new offenders, co-offending share and mean
  group size over **2014-01 to 2020-08** (end exclusive 2020-09-01). Excluded: 2010–2013 (91 rows,
  too sparse for a baseline) and September 2020 (incomplete; solved-case data are right-censored).
- **Unusual months**: the configured production rule is a causal same-calendar-month robust
  baseline: compare a month only with earlier observations of that same month, using up to five
  prior years and requiring at least three prior samples. |z| ≥ 3.5 is the evidence threshold.
  The original causal 12-month rolling rule is retained as a comparison. Neither rule uses the
  current or future month, so both are replay-safe.
- **Level shifts**: penalized binary segmentation on the monthly count (penalty 2σ²·log n,
  σ from first differences; Truong et al. 2020), minimum segment 6 months, at most 5 changes.
- **Entity rhythm**: inter-event gap statistics, burstiness B = (σ−μ)/(σ+μ) (Goh & Barabási 2008),
  dormancy ratio, busiest-30-day share.
- **Known limitation**: the rolling baseline has no seasonal term; July is the busiest month
  overall, so summer peaks may be flagged as unusual (open task T-043).

## 5. Spatial analysis

Coordinates are provider min-max scaled; the project works in that normalized space only and
never maps back to places. Entity features: radius of gyration (González et al. 2008),
consecutive-step distances, repeated-site share. System level: a 20×20 grid density and a
cell × year Poisson excess test (expected = row total × column total / N, one-sided p via
`gammainc`, Bonferroni at α = 0.001). This is a transparent fixed-grid relative of the space–time
scan statistic (Kulldorff 1997), not an implementation of it.

## 6. Graph analysis

Undirected weighted co-offending graph (the file's links are all reciprocal). Node features:
degree, strength, strongest tie, local clustering (Watts & Strogatz 1998), k-core number
(Batagelj & Zaversnik 2003), component size, unweighted betweenness (Freeman 1977), articulation
point flag. Dynamic view: yearly snapshots with active/new/persistent ties, edge persistence and
Jaccard, component structure. Interpretation limits of centrality on incomplete criminal
network data (Sparrow 1991) are stated in docs/ETHICS_AND_LIMITATIONS.md.

## 7. Sequence analysis

The artifact has no event type, so each event is encoded from two observable and causal
properties: partner state (Solo / Repeat partners only / New partner, "new" judged only against
the offender's earlier events) × spatial move (first / Local / Far, split at the global median
step). A first-order Markov model with Laplace smoothing gives the per-transition surprisal
−log₂ P(token_t | token_t−1); entity features are mean and maximum surprisal and the new-partner
rate. Contiguous n-grams (n = 3) give frequent and rare patterns with entity-level support.

## 8. Anomaly detection

1. **Population**: offenders with ≥ 3 crimes (3,260 in the artifact). Others are reported as
   *insufficient history*.
2. **Preparation**: `log1p` for heavy-tailed counts, robust scaling fit on the population
   (median, 1.4826·MAD, fallback 1.2533·mean absolute deviation, then drop as constant), `NaN`
   imputed at the median (z = 0) and recorded.
3. **Baseline**: RMS of robust z-scores (distance from the robust centre in robust-SD units).
   Transparent, deterministic, exactly decomposable.
4. **Model**: Isolation Forest (Liu et al. 2008; MATLAB `iforest`), 200 trees, 256 samples per
   tree, seed 42, `ContaminationFraction = 0`.
5. **Threshold**: an explicit review budget (top 1 % of the population per detector). Without
   labels there is no defensible "correct" threshold; the budget is reported and its effect is
   experiment E8.
6. **Comparison**: Spearman rank correlation and top-k Jaccard between detectors.

A model is **not** chosen by how many anomalies it produces. Selection criteria are sensitivity in
controlled injection (E5–E7), stability (E8) and interpretability.

## 9. Explainability

For every flagged entity and the top 100 by the primary detector: per-feature robust z, raw value
vs reference median, the exact baseline share z_j² / Σz², the Isolation Forest occlusion delta
(score drop when a feature or a whole group is reset to the reference median; cf. Siddiqui et al.
2019), a dominant feature group and generated evidence text ending with the interpretation caveat.

## 10. Evaluation

No ground truth exists and none is fabricated. The protocol (docs/EVALUATION.md) combines data
quality (E1), score behaviour (E2/E3), ranking consistency under feature ablation on real data
(E4), **synthetic** injected deviations per feature group (E5–E7; Emmott et al. 2013), sensitivity
and stability (E8), runtime (E9) and a small usability study (E10). Metric choices follow Campos
et al. (2016): ROC-AUC, average precision and precision at the number of injected rows.

## 11. Reproducibility

One configuration file, fixed seeds, pinned dataset hash, every output regenerated by a script,
run metadata written to `outputs/experiments/pipeline_run.json`. Runbook: docs/REPRODUCIBILITY.md.
