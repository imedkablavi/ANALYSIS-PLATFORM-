% RUN_NETWORK_DEMO Analyse the pinned official CTU-13 scenario and open its app.
% Acquire first: python3 scripts/data/acquire_ctu13_scenario7.py
% Verifies and analyses the source capture before opening its saved results.
addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
file = fullfile(rootDir, "data", "external", "ctu13-scenario7.binetflow");
if ~isfile(file)
    error("MOSAIC:DatasetMissing", ...
        "Acquire the official capture with python3 scripts/data/acquire_ctu13_scenario7.py.");
end
[ok, actual] = verifyGitBlobSha(file, "33065bb8bc1df911fae818e3475ee0cf96d0e0a9");
if ~ok
    error("MOSAIC:DatasetVersion", "Capture differs from documented source: %s", actual);
end
if isempty(which('iforest'))
    error("MOSAIC:ToolboxRequired", "The network demo requires Statistics and Machine Learning Toolbox.");
end
bundle = analyzeDataset(file, struct('name', "CTU-13 scenario 7", 'use_iforest', true));
fprintf("\nPublished labels used only AFTER scoring. Actual evaluation:\n");
disp(bundle.ground_truth.evaluation);
app = NetworkBehaviorExplorer(bundle);
