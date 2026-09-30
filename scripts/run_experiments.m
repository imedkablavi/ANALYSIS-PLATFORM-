% RUN_EXPERIMENTS
% Experiments E1-E9 on the saved analysis bundle (docs/EXPERIMENTS.md).
% Set QUICK = true for a smoke run (1 repeat, fewer seeds).

QUICK = false;
addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
bundleFile = fullfile(rootDir, cfg.output.bundle_file);
if ~isfile(bundleFile)
    error("MOSAIC:BundleMissing", "Run scripts/run_pipeline.m first (%s missing).", bundleFile);
end
S = load(bundleFile, "bundle");
outDir = fullfile(rootDir, cfg.output.experiment_dir);
clk = tic;
results = runExperiments(S.bundle, cfg, outDir, struct('quick', QUICK));
fprintf("Experiments finished in %.1f s. Summary: %s\n", toc(clk), ...
    fullfile(outDir, "experiments_summary.md"));
