% CHECK_DATASET_PRESENCE
% Verify that the approved primary dataset is available locally.

clear; clc;

rootDir = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(rootDir,"src")));

cfg = projectConfig();
dataFile = fullfile(rootDir, cfg.data.primary_file);

fprintf("Expected dataset: %s\n", dataFile);

if ~isfile(dataFile)
    error("MOSAIC:DatasetMissing", ...
        ["Primary dataset is not installed locally.\n" ...
         "Download it according to docs/DATASET_ACQUISITION.md and place it at:\n%s"], ...
         dataFile);
end

info = dir(dataFile);
fprintf("Dataset found. Size: %.2f MB\n", info.bytes / 1024^2);
fprintf("Next step: run scripts/run_first_pipeline.m\n");
