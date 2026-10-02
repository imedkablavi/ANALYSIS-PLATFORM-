% DOWNLOAD_DATASET
% Download the primary artifact into data/raw/ and verify its Git blob SHA.
% Raw data stays out of Git (.gitignore); see docs/DATASET_ACQUISITION.md.
%
% Equivalent shell command (no MATLAB needed):
%   curl -L -o data/raw/israel_lea_inp_burglary_offender_id_network.json \
%     https://raw.githubusercontent.com/erichoang/criminal-network-visualization/main/datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json
%   git hash-object data/raw/israel_lea_inp_burglary_offender_id_network.json

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
target = fullfile(rootDir, cfg.data.primary_file);
if ~isfolder(fileparts(target))
    mkdir(fileparts(target));
end
if ~isfile(target)
    fprintf("Downloading %s\n", cfg.data.source_url);
    websave(target, cfg.data.source_url, weboptions('Timeout', 120));
end
[ok, sha] = verifyGitBlobSha(target, cfg.data.expected_blob_sha);
fprintf("Blob SHA: %s\n", sha);
if ~ok
    warning("MOSAIC:DatasetVersion", ...
        ["Downloaded file differs from the verified artifact (%s). The upstream file " ...
         "may have changed: re-run the schema inspection before trusting results."], ...
        cfg.data.expected_blob_sha);
else
    fprintf("Dataset matches the verified artifact.\n");
end
