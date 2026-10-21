% RUN_PIPELINE
% Full reproducible analysis: validation -> features -> temporal/spatial/
% graph/sequence analysis -> anomaly detection -> explanations -> bundle.
% Outputs:
%   outputs/reports/validation_report.{json,md}, validation_checks.csv
%   outputs/experiments/*.csv, pipeline_run.json
%   outputs/model/analysis_bundle.mat  (input of the app and experiments)

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
fprintf("\n=== %s %s — analysis pipeline ===\n", cfg.project.name, cfg.project.version);
bundle = runAnalysisPipeline(cfg, rootDir);

e = bundle.entities;
fprintf("\nEntities: %d | eligible: %d | flagged IF: %d | flagged baseline: %d\n", ...
    height(e), nnz(e.eligible), nnz(e.iforest_flag), nnz(e.baseline_flag));
fprintf("Detector agreement: Spearman %.3f, top-k Jaccard %.3f\n", ...
    bundle.anomaly.agreement.spearman, bundle.anomaly.agreement.topk_jaccard);
disp(struct2table(bundle.meta.timings));
fprintf("Bundle: %s\nNext: scripts/run_experiments.m, scripts/generate_report_figures.m, scripts/launch_app.m\n", ...
    fullfile(rootDir, cfg.output.bundle_file));
