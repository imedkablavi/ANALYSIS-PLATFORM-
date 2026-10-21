function bundle = runAnalysisPipeline(cfg, rootDir, opts)
%RUNANALYSISPIPELINE End-to-end analysis producing the shared analysis bundle.
%
%   BUNDLE = RUNANALYSISPIPELINE(CFG, ROOTDIR) runs every stage on the
%   dataset at fullfile(ROOTDIR, cfg.data.primary_file), writes reports and
%   tables under ROOTDIR/outputs and saves the bundle to
%   cfg.output.bundle_file. OPTS (struct, optional):
%     allow_invalid  continue although error-level validation checks fail
%                    (default false)
%     use_iforest    default: true when iforest is available
%     save           default true
%     data_file      override the input path (tests use a small fixture)
%     dataset        an already imported dataset (importDataset); takes
%                    precedence over data_file. Used by analyzeDataset for
%                    any external dataset (docs/DATASET_IMPORT.md)
%     progress       function handle @(fraction, message) called at every
%                    stage (fraction in [0,1]); used by the app's progress
%                    dialog
%
%   Stage order mirrors the architecture (docs/ARCHITECTURE.md):
%   load -> flatten -> validate -> crimes/relations -> graph -> behaviour
%   -> sequence -> merge -> temporal -> spatial -> dynamic graph ->
%   patterns -> anomaly -> explanation -> save.
%   Every stage is timed (bundle.meta.timings, experiment E9).

arguments
    cfg struct
    rootDir (1,1) string
    opts struct = struct()
end

allowInvalid = isfield(opts, "allow_invalid") && opts.allow_invalid;
useIF = ~isempty(which('iforest'));
if isfield(opts, "use_iforest")
    useIF = opts.use_iforest && useIF;
end
doSave = ~isfield(opts, "save") || opts.save;
dataFile = fullfile(rootDir, cfg.data.primary_file);
if isfield(opts, "data_file")
    dataFile = opts.data_file;
end

progressFcn = [];
if isfield(opts, "progress") && ~isempty(opts.progress)
    progressFcn = opts.progress;
end
stageNo = 0;

timings = struct();
clk = tic;
stageNo = logStage(stageNo, progressFcn, "import");
if isfield(opts, "dataset")
    data = opts.dataset;
else
    data = importDataset(dataFile, struct('format', "networkx_burglary_json", ...
        'date_format', cfgGet(cfg, "data.date_format", "yyyy-MM-dd HH:mm:ss")));
end
events = data.events;
timings.import = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "validate");
validation = validateBurglaryNetwork(data, events, cfg);
reportDir = fullfile(rootDir, cfg.output.report_dir);
if doSave
    writeValidationReport(validation, reportDir);
end
timings.validate = toc(clk);
if ~validation.is_valid && ~allowInvalid
    error("MOSAIC:ValidationFailed", ...
        "Validation failed (%s). See %s.", joinStrings(validation.errors, " | "), reportDir);
end

entityIds = data.nodes.entity_id;
nEnt = numel(entityIds);
entityTypes = data.nodes.entity_type;
graphMeta = data.graph;
datasetMeta = struct();
if isfield(data, "meta")
    datasetMeta = data.meta;
end
flows = table();
if isfield(data, "flows")
    flows = data.flows;   % network traffic (importNetworkFlows)
end
clear data   % drop the imported dataset as early as possible

clk = tic;
stageNo = logStage(stageNo, progressFcn, "crimes and relations");
crimes = buildCrimeTable(events);
[relations, pairEvents] = buildRelationTable(events, entityIds);
timings.relations = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "graph features");
G = buildOffenderGraph(relations, entityIds);
[graphFeatures, graphNotes] = computeGraphFeatures(G, cfg);
timings.graph = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "behaviour features");
behavior = buildBehaviorFeatures(events, entityIds, relations, cfg);
timings.behavior = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "sequences");
[tokens, stepThreshold] = encodeEventSequences(events, pairEvents, cfg);
seqModel = fitTransitionModel(tokens, cfgGet(cfg, "sequence.laplace_alpha", 1));
[seqFeatures, tokens] = scoreSequenceNovelty(tokens, seqModel, nEnt);
ngrams = mineSequenceNgrams(tokens, cfgGet(cfg, "sequence.ngram_n", 3), ...
    cfgGet(cfg, "sequence.min_ngram_support", 5));
timings.sequence = toc(clk);

if height(flows) > 0
    clk = tic;
    stageNo = logStage(stageNo, progressFcn, "network traffic features");
    networkFeatures = computeNetworkFeatures(flows, nEnt, cfg);
    features = mergeFeatureTables(behavior, graphFeatures, seqFeatures, networkFeatures);
    timings.network = toc(clk);
else
    features = mergeFeatureTables(behavior, graphFeatures, seqFeatures);
end

clk = tic;
stageNo = logStage(stageNo, progressFcn, "temporal analysis");
t0 = cfg.temporal.series_start;
t1 = cfg.temporal.series_end;
series = buildActivitySeries(events, crimes, t0, t1, cfg.temporal.bin);
temporal.series = series;
temporal.anomaly_method = cfg.temporal.anomaly_method;
% Sampling-noise floors: Poisson for counts, binomial for the co-offending
% share (denominator = crimes in the bin). See detectTemporalAnomalies.
floorOn = cfgGet(cfg, "temporal.sampling_noise_floor", true);
cntFloor = "none"; shareFloor = "none";
if floorOn
    cntFloor = "poisson"; shareFloor = "binomial";
end
% The seasonal comparison needs monthly bins; with other bins only the
% rolling rule is computed (and selecting seasonal is a configuration error).
modes = "rolling";
if cfg.temporal.bin == "month"
    modes(end+1) = "seasonal_same_month";
elseif cfg.temporal.anomaly_method == "seasonal_same_month"
    error("MOSAIC:TemporalAnomalyMethod", ...
        "anomaly_method ""seasonal_same_month"" requires cfg.temporal.bin = ""month"" (got ""%s"").", ...
        cfg.temporal.bin);
end
for m = modes
    sfx = "_" + extractBefore(m + "_", "_");      % "_rolling" / "_seasonal"
    temporal.("crime_anomalies" + sfx) = scoreSeries(series.crimes, m, series.bin_start, cfg, cntFloor, []);
    temporal.("new_offender_anomalies" + sfx) = scoreSeries(series.new_offenders, m, series.bin_start, cfg, cntFloor, []);
    temporal.("cooffending_anomalies" + sfx) = scoreSeries(series.cooffending_share, m, series.bin_start, cfg, shareFloor, series.crimes);
end

switch cfg.temporal.anomaly_method
    case "rolling"
        temporal.crime_anomalies = temporal.crime_anomalies_rolling;
        temporal.new_offender_anomalies = temporal.new_offender_anomalies_rolling;
        temporal.cooffending_anomalies = temporal.cooffending_anomalies_rolling;
    case "seasonal_same_month"
        temporal.crime_anomalies = temporal.crime_anomalies_seasonal;
        temporal.new_offender_anomalies = temporal.new_offender_anomalies_seasonal;
        temporal.cooffending_anomalies = temporal.cooffending_anomalies_seasonal;
    otherwise
        error("MOSAIC:TemporalAnomalyMethod", ...
            "Unsupported temporal anomaly method: %s", cfg.temporal.anomaly_method);
end

if isfield(temporal, "crime_anomalies_seasonal")
    temporal.anomaly_comparison = table(series.bin_start, ...
        temporal.crime_anomalies_rolling.is_high | temporal.crime_anomalies_rolling.is_low, ...
        temporal.crime_anomalies_seasonal.is_high | temporal.crime_anomalies_seasonal.is_low, ...
        'VariableNames', {'bin_start','rolling_flag','seasonal_flag'});
else
    temporal.anomaly_comparison = table(series.bin_start, ...
        temporal.crime_anomalies_rolling.is_high | temporal.crime_anomalies_rolling.is_low, ...
        'VariableNames', {'bin_start','rolling_flag'});
end
temporal.change_points = detectChangePoints(series.crimes, ...
    cfg.temporal.changepoint_min_segment, cfg.temporal.changepoint_max_changes);
if height(temporal.change_points) > 0
    temporal.change_points.bin_start = series.bin_start(temporal.change_points.index);
end
timings.temporal = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "spatial analysis");
years = cfg.temporal.snapshot_years(:);
spatial = computeSpatialHotspots(crimes, cfg.spatial.grid_size, years, cfg.spatial.hotspot_alpha);
spatial.step_threshold = stepThreshold;
timings.spatial = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "dynamic graph");
% Yearly windows, but the last one is cut at series_end: data after it are
% incomplete and right-censored (solved cases). Shortened windows are
% flagged as partial in the output. Short captures (hour/minute bins) use
% the equal windows set by configureForDataset instead.
if ~isempty(cfgGet(cfg, "temporal.snapshot_starts", datetime.empty(0, 1)))
    windowStarts = cfg.temporal.snapshot_starts(:);
else
    windowStarts = datetime([years; years(end)+1], 1, 1);
    windowStarts(end) = min(windowStarts(end), cfg.temporal.series_end);
end
dynamicGraph = computeDynamicGraphStats(pairEvents, events, windowStarts);
timings.dynamic_graph = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "pattern mining");
patterns = mineCooffendingPatterns(events, relations, 2);
patterns.ngrams = ngrams;
timings.patterns = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "anomaly detection");
registry = featureRegistry();
anomaly = runAnomalyDetection(features, registry, cfg, ...
    cfg.anomaly.feature_groups, struct('use_iforest', useIF));
timings.anomaly = toc(clk);

clk = tic;
stageNo = logStage(stageNo, progressFcn, "explanations");
explanations = explainAnomalies(anomaly, features, cfg);
timings.explain = toc(clk);

% --- Assemble entity table (one row per entity) ---------------------------------
entities = features;
entities.entity_index = (1:nEnt)';
entities.entity_type = entityTypes;
entities.eligible = anomaly.eligible;
entities.baseline_score = anomaly.baseline.score;
entities.baseline_rank = anomaly.baseline.rank;
entities.baseline_flag = anomaly.baseline.flag;
entities.iforest_score = anomaly.iforest.score;
entities.iforest_rank = anomaly.iforest.rank;
entities.iforest_flag = anomaly.iforest.flag;

% Published labels (network datasets): evaluation only, after scoring.
groundTruth = struct();
if height(flows) > 0 && cfgGet(datasetMeta, "has_labels", false)
    truth = networkGroundTruth(flows, nEnt);
    groundTruth.entities = truth;
    groundTruth.evaluation = evaluateGroundTruth(entities, truth);
    groundTruth.note = "Published dataset labels, used only to evaluate the " + ...
        "unsupervised detectors; never used as features.";
    entities.truth = truth.truth;
end

datasetSha = cfg.data.expected_blob_sha;
if isfield(datasetMeta, "sha")
    datasetSha = datasetMeta.sha;
end
if isfield(datasetMeta, "source_file")
    dataFile = datasetMeta.source_file;
end
if ~isfield(datasetMeta, "has_coordinates")
    datasetMeta.has_coordinates = true;
end
configNotes = strings(0,1);
if isfield(opts, "config_notes")
    configNotes = reshape(string(opts.config_notes), [], 1);
end
configNotes = [configNotes; graphNotes];   % scale guards that skipped a feature
bundle = struct();
bundle.meta = struct( ...
    'project', cfg.project.name, 'version', cfg.project.version, ...
    'feature_version', cfg.project.feature_version, ...
    'dataset_file', dataFile, 'dataset_blob_sha', datasetSha, ...
    'graph', graphMeta, 'created', datetime('now'), ...
    'matlab_version', version, 'iforest_used', useIF, ...
    'random_seed', cfg.analysis.random_seed, 'timings', timings);
% Dataset provenance (import format, mapping, notes, adapted configuration)
bundle.meta.dataset = datasetMeta;
bundle.meta.config_notes = configNotes;
bundle.config = cfg;
bundle.validation = validation;
bundle.entities = entities;
bundle.events = tokens;          % events + seq_pos + tokens + surprisal
bundle.crimes = crimes;
bundle.relations = relations;
bundle.pairEvents = pairEvents;
bundle.graph = G;
bundle.registry = registry;
bundle.sequence = struct('model', seqModel, 'step_threshold', stepThreshold);
bundle.temporal = temporal;
bundle.spatial = spatial;
bundle.dynamicGraph = dynamicGraph;
bundle.patterns = patterns;
bundle.anomaly = anomaly;
bundle.explanations = explanations;
bundle.ground_truth = groundTruth;

if doSave
    clk = tic;
    stageNo = logStage(stageNo, progressFcn, "save");
    bundleFile = fullfile(rootDir, cfg.output.bundle_file);
    if ~isfolder(fileparts(bundleFile))
        mkdir(fileparts(bundleFile));
    end
    save(bundleFile, "bundle", "-v7.3");
    expDir = fullfile(rootDir, cfg.output.experiment_dir);
    if ~isfolder(expDir)
        mkdir(expDir);
    end
    writetable(entities, fullfile(expDir, "entity_features_scores.csv"));
    writetable(explanations.summary, fullfile(expDir, "anomaly_explanations.csv"));
    writetable(explanations.evidence, fullfile(expDir, "anomaly_evidence_long.csv"));
    writetable(temporal.series, fullfile(expDir, "monthly_activity_series.csv"));
    writetable(dynamicGraph, fullfile(expDir, "dynamic_graph_yearly.csv"));
    writetable(spatial.spaceTime(spatial.spaceTime.is_hotspot, :), ...
        fullfile(expDir, "spacetime_hotspots.csv"));
    writetable(patterns.ngrams, fullfile(expDir, "sequence_ngrams.csv"));
    writetable(temporal.anomaly_comparison, ...
        fullfile(expDir, "temporal_anomaly_method_comparison.csv"));
    if isfield(groundTruth, "evaluation")
        writetable(groundTruth.evaluation, fullfile(expDir, "ground_truth_evaluation.csv"));
    end
    bundle.meta.timings.save = toc(clk);
    writeTextFile(fullfile(expDir, "pipeline_run.json"), jsonencode(struct( ...
        'meta', rmfield(bundle.meta, {'graph','created','dataset'}), ...
        'dataset', datasetSummary(datasetMeta), ...
        'created', char(bundle.meta.created, 'yyyy-MM-dd''T''HH:mm:ss'), ...
        'n_entities', nEnt, 'n_eligible', nnz(anomaly.eligible), ...
        'n_features', numel(anomaly.prep.names), ...
        'dropped_features', {cellstr(anomaly.prep.dropped)}, ...
        'agreement', anomaly.agreement)));
end
end

function out = datasetSummary(m)
% JSON-safe dataset provenance for pipeline_run.json (no datetimes, no IDs).
out = struct();
for f = ["id","name","format","profile","sha","n_rows","n_entities","n_events", ...
        "n_flows","has_coordinates","has_labels","pseudonymized","links_provided"]
    if isfield(m, char(f))
        out.(char(f)) = m.(char(f));
    end
end
if isfield(m, "import_notes")
    out.import_notes = cellstr(reshape(string(m.import_notes), 1, []));
end
end

function stageNo = logStage(stageNo, progressFcn, name)
% Console log + optional progress callback (fraction of the 14 stages).
stageNo = stageNo + 1;
fprintf("[pipeline] %s ...\n", name);
if ~isempty(progressFcn)
    progressFcn(min(stageNo / 14, 1), name);
end
end

function r = scoreSeries(x, mode, binStart, cfg, floorKind, trials)
% One temporal-anomaly call with every parameter taken from the configuration.
t = cfg.temporal;
if isempty(trials)
    trials = double.empty(0,1);
end
r = detectTemporalAnomalies(x, t.baseline_window, t.min_baseline_bins, ...
    t.robust_z_threshold, mode, binStart, t.seasonal_lookback_years, ...
    t.seasonal_min_samples, floorKind, trials);
end

