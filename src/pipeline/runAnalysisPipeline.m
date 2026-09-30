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

timings = struct();
clk = tic;
logStage("load");
data = loadBurglaryNetwork(dataFile);
timings.load = toc(clk);

clk = tic;
logStage("flatten");
events = flattenBurglaryEvents(data, cfgGet(cfg, "data.date_format", "yyyy-MM-dd HH:mm:ss"));
timings.flatten = toc(clk);

clk = tic;
logStage("validate");
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
clear data   % drop decoded JSON (largest object) as early as possible

clk = tic;
logStage("crimes and relations");
crimes = buildCrimeTable(events);
[relations, pairEvents] = buildRelationTable(events, entityIds);
timings.relations = toc(clk);

clk = tic;
logStage("graph features");
G = buildOffenderGraph(relations, entityIds);
graphFeatures = computeGraphFeatures(G);
timings.graph = toc(clk);

clk = tic;
logStage("behaviour features");
behavior = buildBehaviorFeatures(events, entityIds, relations, cfg);
timings.behavior = toc(clk);

clk = tic;
logStage("sequences");
[tokens, stepThreshold] = encodeEventSequences(events, pairEvents, cfg);
seqModel = fitTransitionModel(tokens, cfgGet(cfg, "sequence.laplace_alpha", 1));
[seqFeatures, tokens] = scoreSequenceNovelty(tokens, seqModel, nEnt);
ngrams = mineSequenceNgrams(tokens, cfgGet(cfg, "sequence.ngram_n", 3), ...
    cfgGet(cfg, "sequence.min_ngram_support", 5));
timings.sequence = toc(clk);

features = mergeFeatureTables(behavior, graphFeatures, seqFeatures);

clk = tic;
logStage("temporal analysis");
t0 = cfg.temporal.series_start;
t1 = cfg.temporal.series_end;
series = buildActivitySeries(events, crimes, t0, t1, cfg.temporal.bin);
temporal.series = series;
temporal.crime_anomalies = detectTemporalAnomalies(series.crimes, ...
    cfg.temporal.baseline_window, cfg.temporal.min_baseline_bins, cfg.temporal.robust_z_threshold);
temporal.new_offender_anomalies = detectTemporalAnomalies(series.new_offenders, ...
    cfg.temporal.baseline_window, cfg.temporal.min_baseline_bins, cfg.temporal.robust_z_threshold);
temporal.cooffending_anomalies = detectTemporalAnomalies(series.cooffending_share, ...
    cfg.temporal.baseline_window, cfg.temporal.min_baseline_bins, cfg.temporal.robust_z_threshold);
temporal.change_points = detectChangePoints(series.crimes, ...
    cfg.temporal.changepoint_min_segment, cfg.temporal.changepoint_max_changes);
if height(temporal.change_points) > 0
    temporal.change_points.bin_start = series.bin_start(temporal.change_points.index);
end
timings.temporal = toc(clk);

clk = tic;
logStage("spatial analysis");
years = cfg.temporal.snapshot_years(:);
spatial = computeSpatialHotspots(crimes, cfg.spatial.grid_size, years, cfg.spatial.hotspot_alpha);
spatial.step_threshold = stepThreshold;
timings.spatial = toc(clk);

clk = tic;
logStage("dynamic graph");
windowStarts = datetime([years; years(end)+1], 1, 1);
dynamicGraph = computeDynamicGraphStats(pairEvents, events, windowStarts);
timings.dynamic_graph = toc(clk);

clk = tic;
logStage("pattern mining");
patterns = mineCooffendingPatterns(events, relations, 2);
patterns.ngrams = ngrams;
timings.patterns = toc(clk);

clk = tic;
logStage("anomaly detection");
registry = featureRegistry();
anomaly = runAnomalyDetection(features, registry, cfg, ...
    cfg.anomaly.feature_groups, struct('use_iforest', useIF));
timings.anomaly = toc(clk);

clk = tic;
logStage("explanations");
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

bundle = struct();
bundle.meta = struct( ...
    'project', cfg.project.name, 'version', cfg.project.version, ...
    'feature_version', cfg.project.feature_version, ...
    'dataset_file', dataFile, 'dataset_blob_sha', cfg.data.expected_blob_sha, ...
    'graph', graphMeta, 'created', datetime('now'), ...
    'matlab_version', version, 'iforest_used', useIF, ...
    'random_seed', cfg.analysis.random_seed, 'timings', timings);
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

if doSave
    clk = tic;
    logStage("save");
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
    bundle.meta.timings.save = toc(clk);
    writeTextFile(fullfile(expDir, "pipeline_run.json"), jsonencode(struct( ...
        'meta', rmfield(bundle.meta, {'graph','created'}), ...
        'created', char(bundle.meta.created, 'yyyy-MM-dd''T''HH:mm:ss'), ...
        'n_entities', nEnt, 'n_eligible', nnz(anomaly.eligible), ...
        'n_features', numel(anomaly.prep.names), ...
        'dropped_features', {cellstr(anomaly.prep.dropped)}, ...
        'agreement', anomaly.agreement)));
end
end

function logStage(name)
fprintf("[pipeline] %s ...\n", name);
end
