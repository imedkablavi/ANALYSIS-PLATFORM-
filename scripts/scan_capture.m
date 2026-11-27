% SCAN_CAPTURE
% Fast pre-scan of a large network capture: label counts per block of
% records (reads only the time and label columns). Use the table to pick
% first_row / max_rows for analyzeDataset (docs/NETWORK_DATASETS.md).

FILE = "data/external/capture20110810.binetflow";
BLOCK = 250000;

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
path = FILE;
if ~isfile(path)
    path = fullfile(rootDir, FILE);
end
S = scanNetworkCapture(path, BLOCK);
disp(S);
fprintf("Total: %d records, %d malicious, %d benign.\n", S.last_row(end), ...
    sum(S.malicious), sum(S.benign));
