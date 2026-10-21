% ANALYZE_DATASET
% Analyse any supported dataset (e.g. downloaded from the internet) with the
% full pipeline, without touching the primary artifact's results.
% Supported: event CSV (entity, event, time[, x, y]), temporal edge list
% (source, target, time; SNAP "src dst unixtime" works headerless), and the
% primary NetworkX JSON. See docs/DATASET_IMPORT.md.
% Network traffic (the project's target domain): CTU-13 .binetflow,
% CIC-IDS2017 GeneratedLabelledFlows CSV, UNSW-NB15 CSV, LANL auth/flows -
% detected automatically, see docs/NETWORK_DATASETS.md.
%
% Edit FILE (and MAPPING only if the columns are not detected), then run.
% Results: outputs/datasets/<dataset_id>/ ; the dataset then appears in the
% app's dataset list (scripts/launch_app.m).

FILE = "data/external/my_dataset.csv";
NAME = "";                 % display name ("" = file name)
MAPPING = struct();        % e.g. struct('entity',"user",'event',"",'time',"ts")
MAX_ROWS = 0;              % network data: read only the first N records (0 = all)
LABELS_FILE = "";          % LANL auth.txt: redteam.txt (default: same folder)
PROFILE = "";              % force a network profile, e.g. "unsw_nb15_raw" ("" = detect)

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
path = FILE;
if ~isfile(path)
    path = fullfile(rootDir, FILE);
end
info = inspectDatasetFile(path);
fprintf("Detected format: %s\n%s\n", info.format, info.message);
disp(info.mapping);

opts = struct('progress', @(f, msg) fprintf("  %3.0f%%  %s\n", 100 * f, msg));
if strlength(NAME) > 0
    opts.name = NAME;
end
if ~isempty(fieldnames(MAPPING))
    opts.mapping = MAPPING;
end
if MAX_ROWS > 0
    opts.max_rows = MAX_ROWS;
end
if strlength(LABELS_FILE) > 0
    opts.labels_file = LABELS_FILE;
end
if strlength(PROFILE) > 0
    opts.profile = PROFILE;
end
bundle = analyzeDataset(path, opts);

d = bundle.meta.dataset;
fprintf("\nDataset %s (%s): %d entities, %d events, coordinates: %s, pseudonymized: %s\n", ...
    d.name, d.format, d.n_entities, d.n_events, string(d.has_coordinates), string(d.pseudonymized));
fprintf("Configuration adapted:\n");
fprintf("  - %s\n", bundle.meta.config_notes);
fprintf("Import notes:\n");
fprintf("  - %s\n", d.import_notes);
fprintf("Validation valid: %s | scored entities: %d\n", string(bundle.validation.is_valid), ...
    nnz(bundle.entities.eligible));
fprintf("Open it in the app: run scripts/launch_app.m and choose it in the dataset list.\n");
if isfield(bundle, "ground_truth") && isfield(bundle.ground_truth, "evaluation")
    fprintf("\nEvaluation against the published labels (after scoring; not used as features):\n");
    disp(bundle.ground_truth.evaluation);
end
