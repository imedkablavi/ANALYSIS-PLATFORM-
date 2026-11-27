# Scripts

Every script resolves paths from its own location and calls `setupProject` (no manual path setup).

| Script | Purpose |
|---|---|
| `download_dataset.m` | download the artifact to `data/raw/` and verify its Git blob SHA |
| `check_dataset_presence.m` | check presence and version of the local dataset |
| `inspect_primary_dataset.m` | validation summary + plot of the largest co-offending component |
| `run_tests.m` | run all MATLAB unit tests |
| `run_pipeline.m` | full analysis → `outputs/model/analysis_bundle.mat` + tables/reports |
| `run_experiments.m` | experiments E1–E9 (`QUICK = true` for a smoke run) |
| `generate_report_figures.m` | regenerate every report figure |
| `launch_app.m` | open the multimedia application |
| `setupProject.m` | add project folders to the path |
| `reference/audit_dataset_reference.py` | independent Python audit of the dataset facts (verification only) |
