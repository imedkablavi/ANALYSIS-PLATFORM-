% RUN_EXPERIMENTS
% Experiments E1-E9 (+ E11 for datasets with published labels) on a saved
% analysis bundle (docs/EXPERIMENTS.md).
% Set QUICK = true for a smoke run (1 repeat, fewer seeds).
% DATASET selects the bundle:
%   ""        the primary bundle (scripts/run_pipeline.m)
%   "latest"  the most recently analysed dataset (analyzeDataset, e.g. CTU-13)
%   "<id>"    a dataset_id from listDatasets / outputs/datasets/catalog.json
% Imported datasets use the configuration stored in their bundle (time
% bins etc. adapted by configureForDataset) and write to
% outputs/datasets/<id>/experiments/.

QUICK = false;
DATASET = "";

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
if DATASET == ""
    bundleFile = fullfile(rootDir, cfg.output.bundle_file);
    outDir = fullfile(rootDir, cfg.output.experiment_dir);
else
    catalog = listDatasets(rootDir);
    if height(catalog) == 0
        error("MOSAIC:NoDatasets", "No analysed datasets yet: run analyzeDataset first.");
    end
    if DATASET == "latest"
        [~, k] = max(catalog.imported);
    else
        k = find(string(catalog.dataset_id) == DATASET, 1);
        if isempty(k)
            error("MOSAIC:UnknownDataset", "Dataset %s is not in the catalog.", DATASET);
        end
    end
    bundleFile = string(catalog.bundle_file(k));
    outDir = fullfile(fileparts(bundleFile), "experiments");
end
if ~isfile(bundleFile)
    error("MOSAIC:BundleMissing", "Analysis bundle missing: %s", bundleFile);
end
S = load(bundleFile, "bundle");
if DATASET ~= ""
    cfg = S.bundle.config;   % the dataset's adapted configuration
end
fprintf("Experiments on %s\n", bundleFile);
clk = tic;
results = runExperiments(S.bundle, cfg, outDir, struct('quick', QUICK));
fprintf("Experiments finished in %.1f s. Summary: %s\n", toc(clk), ...
    fullfile(outDir, "experiments_summary.md"));
