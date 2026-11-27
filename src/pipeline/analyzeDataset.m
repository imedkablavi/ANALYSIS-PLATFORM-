function bundle = analyzeDataset(path, opts)
%ANALYZEDATASET Import, analyse and register any supported dataset in one call.
%
%   BUNDLE = ANALYZEDATASET(PATH) runs the complete project pipeline on a
%   new dataset (e.g. one downloaded from the internet) instead of the
%   fixed primary artifact:
%     inspectDatasetFile -> importDataset -> configureForDataset ->
%     runAnalysisPipeline -> registerDataset
%   Results go to outputs/datasets/<dataset_id>/ (bundle, reports, tables)
%   and the dataset appears in the app's dataset list.
%
%   OPTS (struct, optional):
%     mapping      column mapping (see inspectDatasetFile); needed when the
%                  columns cannot be detected automatically
%     name         display name (default: file name)
%     root_dir     project root (default: this repository)
%     progress     @(fraction, message) callback (app progress dialog)
%     use_iforest  default true when the toolbox is available
%     format, time_unit, time_formats, date_format, pseudonymize, keep_id_map
%                  passed to importDataset; explicit schemas override detection
%     profile, max_rows, labels_file         network traffic (importNetworkFlows,
%                                            docs/NETWORK_DATASETS.md)
%     allow_invalid  continue despite error-level validation findings
%
%   Imported datasets are pseudonymized and their coordinates min-max
%   scaled by default (docs/DATASET_IMPORT.md, docs/ETHICS_AND_LIMITATIONS.md).

arguments
    path (1,1) string
    opts struct = struct()
end

opts = validateImportOptions(opts);
assertTextDataset(path);
rootDir = string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if isfield(opts, "root_dir")
    rootDir = string(opts.root_dir);
end
progress = [];
if isfield(opts, "progress")
    progress = opts.progress;
end
logFile = fullfile(rootDir, "outputs", "logs", "analyze_" + ...
    string(datetime('now'), 'yyyyMMdd_HHmmss_SSS') + ".log");
runLog("open", logFile);
logCleanup = onCleanup(@() runLog("close")); %#ok<NASGU>
runLog("analyzeDataset %s", path);
report(progress, 0.01, "inspecting file");

info = inspectDatasetFile(path);
hasOverride = isfield(opts, 'format') || isfield(opts, 'mapping');
if info.format == "unknown" && ~hasOverride
    error("MOSAIC:UnsupportedFormat", "%s", info.message);
end
if info.needs_mapping && ~isfield(opts, "mapping") && ~isfield(opts, "format")
    error("MOSAIC:MappingMissing", "%s Pass opts.mapping.", info.message);
end

% LANL authentication events: use redteam.txt from the same folder as the
% labels file when none is given (recorded in the import notes).
if string(cfgGet(opts, "format", info.format)) == "network_flow" && ...
        string(cfgGet(opts, "profile", cfgGet(info, "profile", ""))) == "lanl_auth" && ~isfield(opts, "labels_file")
    candidate = fullfile(fileparts(path), "redteam.txt");
    if isfile(candidate)
        opts.labels_file = string(candidate);
    end
end

% importDataset merges opts.mapping over the detected mapping and reuses
% this inspection instead of reading the file again.
importOpts = struct('info', info);
if info.format == "unknown" && ~isfield(opts, 'format') && isfield(opts, 'mapping')
    m = opts.mapping;
    if isfield(m, 'source') && isfield(m, 'target')
        importOpts.format = "edge_csv";
    elseif isfield(m, 'entity')
        importOpts.format = "event_csv";
    end
end
for f = ["format","mapping","name","time_unit","time_formats","date_format", ...
        "pseudonymize","keep_id_map","profile","max_rows","first_row","labels_file"]
    if isfield(opts, char(f))
        importOpts.(char(f)) = opts.(char(f));
    end
end
report(progress, 0.03, "importing");
ds = importDataset(path, importOpts);

cfg = projectConfig();
[cfg, notes] = configureForDataset(cfg, ds);
if ds.meta.format == "network_flow"
    cfg.labels.entities = "hosts";      % wording of evidence texts
    cfg.labels.events = "flows";
elseif ds.meta.format ~= "networkx_burglary_json"
    cfg.labels.entities = "entities";
    cfg.labels.events = "events";
end
id = ds.meta.id;
outRel = fullfile("outputs", "datasets", id);
cfg.output.bundle_file = fullfile(outRel, "analysis_bundle.mat");
cfg.output.report_dir = fullfile(outRel, "reports");
cfg.output.experiment_dir = fullfile(outRel, "tables");
cfg.output.figure_dir = fullfile(outRel, "figures");

if ~isfolder(fullfile(rootDir, outRel))
    mkdir(fullfile(rootDir, outRel));
end
if isfield(ds, "private")
    % Original identifiers stay out of the bundle; saved separately (git-ignored).
    writetable(ds.private.entity_map, fullfile(rootDir, outRel, "entity_id_map.csv"));
    ds = rmfield(ds, "private");
end

pipeOpts = struct('dataset', ds, 'config_notes', notes);
if ~isempty(progress)
    pipeOpts.progress = @(f, msg) report(progress, 0.05 + 0.9 * f, msg);
end
for f = ["use_iforest","allow_invalid"]
    if isfield(opts, char(f))
        pipeOpts.(char(f)) = opts.(char(f));
    end
end
bundle = runAnalysisPipeline(cfg, rootDir, pipeOpts);

entry = struct('dataset_id', id, 'name', ds.meta.name, 'format', ds.meta.format, ...
    'n_entities', ds.meta.n_entities, 'n_events', ds.meta.n_events, ...
    'imported', datetime('now'), 'bundle_file', fullfile(rootDir, cfg.output.bundle_file), ...
    'source_file', path);
registerDataset(rootDir, entry);
runLog("done: %s (bundle %s)", id, fullfile(rootDir, cfg.output.bundle_file));
runLog("close");
report(progress, 1, "done");
end

function report(progress, fraction, message)
if ~isempty(progress)
    try
        progress(fraction, message);
    catch
        % A closed UI/progress dialog must not invalidate scientific output.
        runLog("Progress display callback unavailable; analysis continues.");
    end
end
end

function assertTextDataset(path)
% A manual schema can override detection, never turn a binary into a CSV.
fid = fopen(path, 'rb');
if fid < 0
    error("MOSAIC:DataFileNotFound", "Dataset file cannot be opened.");
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
prefix = fread(fid, 8192, '*uint8');
control = prefix < 32 & ~ismember(prefix, uint8([9 10 13]));
if any(control)
    error("MOSAIC:UnsupportedFormat", "Binary dataset files are unsupported; provide delimited text or supported JSON.");
end
end
