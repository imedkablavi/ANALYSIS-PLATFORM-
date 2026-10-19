# Reproducibility Runbook

## 1. Requirements

| Item | Needed for | Notes |
|---|---|---|
| MATLAB **R2021b or newer** (R2023b+ recommended) | everything | R2021b is the oldest release providing every function used (`iforest`/`isanomaly`; `arguments` blocks, `mustBeInRange`, `exportgraphics`, `xline` with vectors are older). Not yet verified on a specific release. |
| Statistics and Machine Learning Toolbox | Isolation Forest only | Without it the pipeline runs baseline-only (`bundle.meta.iforest_used = false`); tests that need `iforest` are skipped. |
| Java-enabled MATLAB desktop | dataset hash check | `verifyGitBlobSha` uses `java.security.MessageDigest`. |
| ~1 GB free RAM | pipeline | decoded JSON is dropped after flattening. |
| Python 3 (optional) | reference audit only | stdlib; `--graph` needs `numpy`, `networkx`. Not used by the MATLAB pipeline. |

No other toolbox is required. Signal Processing, Image Processing, Computer Vision and Parallel
Computing toolboxes are deliberately not used (docs/MATLAB_STACK.md).

## 2. Workflow

Run from MATLAB with the repository root as the current folder (every script also works from any
folder because it resolves paths from its own location).

```matlab
run scripts/download_dataset.m        % 1. acquire + verify blob SHA 3afe9cbb…
run scripts/check_dataset_presence.m  % 2. optional re-check
run scripts/run_tests.m               % 3. unit tests (fixtures; real-data tests if data present)
run scripts/run_pipeline.m            % 4. validate -> features -> analysis -> anomaly -> explain
run scripts/run_experiments.m         % 5. E1–E9 tables + experiments_summary.md
run scripts/generate_report_figures.m % 6. report figures (same plotting code as the app)
run scripts/launch_app.m              % 7. interactive multimedia application
```

The configured production temporal anomaly rule is stored in
`cfg.temporal.anomaly_method`. The default is `seasonal_same_month`, a causal same-calendar-month
baseline using up to five prior years and at least three prior observations. The original
12-month rolling rule remains available for comparison.

Without MATLAB, the dataset facts can be reproduced with:

```bash
curl -L -o data/raw/israel_lea_inp_burglary_offender_id_network.json \
  https://raw.githubusercontent.com/erichoang/criminal-network-visualization/main/datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json
git hash-object data/raw/israel_lea_inp_burglary_offender_id_network.json   # expect 3afe9cbb4e313fb056f1b115c92a3f750f4698b9
python3 scripts/reference/audit_dataset_reference.py --graph
```

## 3. Outputs

| Path | Produced by | Content |
|---|---|---|
| `outputs/reports/validation_report.{json,md}`, `validation_checks.csv` | pipeline | E1 data quality (aggregates only, no IDs) |
| `outputs/model/analysis_bundle.mat` | pipeline | shared analytical model used by app and experiments |
| `outputs/experiments/entity_features_scores.csv` | pipeline | one row per offender: features, scores, ranks, flags |
| `outputs/experiments/anomaly_explanations.csv`, `anomaly_evidence_long.csv` | pipeline | explanations |
| `outputs/experiments/monthly_activity_series.csv`, `dynamic_graph_yearly.csv`, `spacetime_hotspots.csv`, `sequence_ngrams.csv` | pipeline | analysis tables |
| `outputs/experiments/pipeline_run.json` | pipeline | versions, seed, timings, feature count, agreement |
| `outputs/experiments/E*.csv`, `synthetic_*.csv`, `experiments_summary.md` | experiments | results; synthetic files are prefixed `synthetic_` |
| `outputs/figures/fig_*.png` | figure script | report figures |

`outputs/experiments`, `outputs/reports` and `outputs/model` are git-ignored: results are
regenerated, not committed. The CSVs contain the dataset's pseudonymous `OID#` identifiers; do not
publish them outside the course context.

## 4. Pending execution-based verification (to do on a MATLAB machine)

These have **not** been run yet (the development environment had no MATLAB). Record the outcome in
docs/RESEARCH_LOG.md and in the relevant GitHub issue.

1. `run scripts/run_tests.m` → expected: all fixture tests pass; `test_real_dataset` passes when
   the dataset is installed (its expected values come from the independent Python audit).
2. `run scripts/run_pipeline.m` → expected: validation `is_valid = true`; warnings none;
   info observations V14/V45/V46/V60/V61 as in docs/DATASET_SCHEMA_INSPECTION.md; 3,260 eligible.
3. `run scripts/run_experiments.m` (first with `QUICK = true`) → check runtime; the full synthetic
   grid fits about 1,200 small forests.
4. `run scripts/launch_app.m` → walk through docs/DEMO_SCENARIO.md.

## 5. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Undefined function 'projectConfig'` | paths not set | run scripts via `run scripts/...`; they call `setupProject` |
| `MOSAIC:DatasetMissing` / `MOSAIC:DataFileNotFound` | dataset absent | `run scripts/download_dataset.m` |
| warning `MOSAIC:DatasetVersion` | upstream file changed | re-run the reference audit and schema inspection before trusting results |
| `MOSAIC:ValidationFailed` | an error-level check failed | read `outputs/reports/validation_report.md`; do not bypass with `allow_invalid` without documenting why |
| `MOSAIC:ToolboxMissing` | no Statistics and ML Toolbox | pipeline continues baseline-only; install the toolbox for E3/E5–E8 IF rows |
| app shows "Analysis bundle not found" | pipeline not run | `run scripts/run_pipeline.m` |
| slow app rendering | very large ego network | lower `cfg.app.max_graph_nodes` |
| `verifyGitBlobSha` Java error | MATLAB started with `-nojvm` | start normally, or check with `git hash-object` |

## 6. Continuous integration

`.github/workflows/ci.yml` runs on every push (any branch), on pull requests and on manual
dispatch (`workflow_dispatch`).

| Job | What it does | Needs MATLAB |
|---|---|---|
| `lint` | `pip install miss_hit`, then `mh_lint .`; any MISS_HIT finding fails the job. | no |
| `reference-audit` | Downloads the dataset with `curl` into `data/raw/` (cached with `actions/cache`, keyed by the blob SHA), fails unless `git hash-object` equals `cfg.data.expected_blob_sha`, runs `scripts/reference/audit_dataset_reference.py --graph` (NumPy + NetworkX) and asserts the exact printed lines `relations_from_crimes 10651 pair_crime_rows 15422`, `isolated_nodes 7597`, `components 10468 largest 518 max_core 12`, `articulation_points 1156`. | no |
| `license-check` | Reports only whether the secret `MLM_LICENSE_TOKEN` exists (secrets cannot be used in a job-level `if`). | no |
| `matlab-tests` | Only when the secret exists: restores and verifies the dataset, installs MATLAB R2023b + Statistics and Machine Learning Toolbox (`matlab-actions/setup-matlab@v3`), runs the `tests/` suite with `matlab-actions/run-tests@v3` (same tests as `scripts/run_tests.m`, including `test_real_dataset`), and uploads JUnit XML (`test-results/results.xml`) as the `matlab-test-results` artifact. | yes |

**Enabling MATLAB tests.** This repository is private, so MathWorks' actions do not license
MATLAB automatically. The owner must request a MATLAB batch licensing token (see the
"Use MATLAB Batch Licensing Token" section of https://github.com/matlab-actions/setup-matlab
and https://github.com/matlab-actions/run-tests) and add it as a repository secret named
`MLM_LICENSE_TOKEN` (Settings → Secrets and variables → Actions). The release is pinned to R2023b
(not `latest`) so CI results do not change silently when MathWorks ships a new release.

**When the token is absent** the `matlab-tests` job is skipped, the workflow still passes, and
the run shows a notice and job-summary entry "MATLAB tests were SKIPPED … No MATLAB results were
produced by this run." A green CI run without that job having executed is **not** evidence
that the MATLAB code works; section 4 remains pending until MATLAB tests actually run. CI never
commits the dataset or uploads pipeline outputs (which contain pseudonymous `OID#` identifiers).
