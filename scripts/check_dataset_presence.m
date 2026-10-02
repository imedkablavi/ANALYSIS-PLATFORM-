% CHECK_DATASET_PRESENCE
% Verify that the approved primary dataset is installed locally and is the
% exact verified version (Git blob SHA).

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
dataFile = fullfile(rootDir, cfg.data.primary_file);
fprintf("Expected dataset: %s\n", dataFile);

if ~isfile(dataFile)
    error("MOSAIC:DatasetMissing", ...
        ["Primary dataset is not installed locally.\n" ...
         "Run scripts/download_dataset.m or follow docs/DATASET_ACQUISITION.md; target:\n%s"], ...
         dataFile);
end
info = dir(dataFile);
fprintf("Dataset found. Size: %.2f MB\n", info.bytes / 1024^2);
[ok, sha] = verifyGitBlobSha(dataFile, cfg.data.expected_blob_sha);
fprintf("Blob SHA %s (%s)\n", sha, string(ok));
if ~ok
    warning("MOSAIC:DatasetVersion", "Local file is not the verified artifact version.");
end
fprintf("Next step: run scripts/run_pipeline.m\n");
