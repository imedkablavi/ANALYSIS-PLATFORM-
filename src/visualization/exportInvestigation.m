function [files, investigation] = exportInvestigation(bundle, entityIndex, outDir, t0, t1, limit)
%EXPORTINVESTIGATION Save reviewable evidence, provenance and source records.
%   Scores and feature evidence always describe the saved full run. Source
%   flows are restricted to [T0,T1) when both endpoints are dated, then capped
%   chronologically. Records support review, not causal score attribution.
%   No entity IDs, source paths, free-text notes or confidence are exported.
%   FILES identifies a JSON manifest and separate evidence/flow CSV tables.
arguments
    bundle struct
    entityIndex (1,1) double {mustBeInteger, mustBePositive}
    outDir (1,1) string
    t0 (1,1) datetime = NaT
    t1 (1,1) datetime = NaT
    limit (1,1) double {mustBeInteger, mustBePositive} = 2000
end
if ~isfield(bundle, 'entities') || entityIndex > height(bundle.entities)
    error("MOSAIC:UnknownEntity", "Selected entity is outside the saved bundle.");
end
if xor(isnat(t0), isnat(t1))
    error("MOSAIC:InvalidInterval", "Replay interval requires both endpoints or neither.");
end
hasInterval = ~isnat(t0) && ~isnat(t1);
if hasInterval && t1 <= t0
    error("MOSAIC:InvalidInterval", "Replay interval must have increasing endpoints.");
end
host = "HOST-" + string(entityIndex);
p = bundle.entities(entityIndex,:);
scores = struct('scope', "full_run");
for name = ["eligible", "baseline_score", "baseline_rank", "baseline_flag", ...
        "iforest_score", "iforest_rank", "iforest_flag"]
    if ismember(name, string(p.Properties.VariableNames))
        scores.(name) = p.(name)(1);
    end
end
evidence = entityEvidence(bundle, entityIndex);
% Missing flow storage in an older bundle is distinct from an observed
% empty result. Keep a CSV header in either case for downstream readers.
flowFields = {'src_index','dst_index','time','proto','sport','dport','duration_s','bytes','packets'};
flowsAvailable = isfield(bundle, 'flows') && istable(bundle.flows) && ...
    all(ismember(flowFields, bundle.flows.Properties.VariableNames));
totalHost = NaN;
observations = emptyObservations();
total = NaN;
observationScope = "full_run";
if hasInterval
    observationScope = "replay_interval";
end
if flowsAvailable
    F = bundle.flows;
    total = 0;
    selected = F.src_index == entityIndex | F.dst_index == entityIndex;
    totalHost = nnz(selected);
    if hasInterval
        selected = selected & F.time >= t0 & F.time < t1;
    end
    flowBundle = struct('flows', F(selected,:));
    if any(selected)
        [observations, total] = hostFlowEvidence(flowBundle, entityIndex, limit);
    end
end
provenance = struct();
sha = string(cfgGet(bundle, "meta.dataset_blob_sha", ""));
if ~isscalar(sha) || isempty(regexp(char(sha), '^[0-9a-fA-F]{40}([0-9a-fA-F]{24})?$', 'once'))
    sha = "";
end
provenance.source_blob_sha = sha;
provenance.random_seed = cfgGet(bundle, "meta.random_seed", NaN);
provenance.matlab_version = string(cfgGet(bundle, "meta.matlab_version", ""));
provenance.feature_version = string(cfgGet(bundle, "meta.feature_version", ""));
provenance.project_version = string(cfgGet(bundle, "meta.version", ""));
investigation = struct('schema_version', 1, 'host', host, ...
    'identity_scope', "bundle_local_pseudonym", 'provenance', provenance, ...
    'scores', scores, 'feature_evidence', table2struct(evidence), ...
    'replay_interval', struct('available', hasInterval, 'start_inclusive', timeText(t0), ...
        'end_exclusive', timeText(t1)), ...
    'observations', struct('scope', observationScope, 'source_available', flowsAvailable, ...
        'total_host_flows_full_run', totalHost, 'total_matching_flows', total, ...
        'shown', height(observations), 'limit', limit, 'truncated', total > height(observations), ...
        'attribution', "Supporting observations; no attribution of a host score to a particular flow.", ...
        'records', table2struct(observations)));
if ~isfolder(outDir)
    mkdir(outDir);
end
stamp = host + "_" + string(datetime('now'), 'yyyyMMdd_HHmmss_SSS');
files = struct('json', fullfile(outDir, "investigation_" + stamp + ".json"), ...
    'evidence_csv', fullfile(outDir, "evidence_" + stamp + ".csv"), ...
    'flows_csv', fullfile(outDir, "flows_" + stamp + ".csv"));
% jsonencode represents unavailable numeric values as null. No derived
% confidence or fabricated replacement score is added.
writeTextFile(files.json, string(jsonencode(investigation)));
writetable(evidence, files.evidence_csv);
writetable(observations, files.flows_csv);
end

function s = timeText(t)
s = "";
if ~isnat(t)
    s = string(t, 'yyyy-MM-dd HH:mm:ss.SSS');
end
end

function T = emptyObservations()
T = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
    zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    'VariableNames', {'time','direction','peer','protocol','source_port', ...
    'destination_port','duration_seconds','bytes','packets'});
end
