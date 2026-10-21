function info = inspectDatasetFile(path)
%INSPECTDATASETFILE Detect the format of a dataset file and propose a column mapping.
%
%   INFO = INSPECTDATASETFILE(PATH) returns
%     format        "networkx_burglary_json" | "network_flow" | "event_csv" |
%                   "edge_csv" | "unknown"
%     profile       network_flow only: networkFlowProfiles id (else "")
%     columns       string row of column names (empty for JSON)
%     mapping       struct with string fields entity, event, time, x, y,
%                   source, target, weight ("" = not detected)
%     needs_mapping true when a required column could not be detected
%     message       human-readable explanation
%
%   Supported layouts (docs/DATASET_IMPORT.md):
%   - networkx_burglary_json: the primary artifact's schema
%   - event_csv: one row per (entity, event) participation; columns
%     entity + time required, event id optional (missing = one event per row),
%     x/y optional
%   - network_flow: a known network-traffic layout (CTU-13, CIC-IDS2017,
%     UNSW-NB15, LANL; networkFlowProfiles / matchNetworkProfile). Checked
%     first, so a known layout is never read as a generic edge list.
%   - edge_csv: one row per interaction between two entities with a time
%     (temporal edge list, e.g. SNAP "src dst unixtime"); headerless files
%     with >= 3 columns are read positionally as source, target, time.

arguments
    path (1,1) string
end

info = struct('format', "unknown", 'profile', "", 'columns', strings(1,0), ...
    'mapping', emptyMapping(), 'needs_mapping', true, 'message', "");
if ~isfile(path)
    info.message = "File not found: " + path;
    return;
end
[~, ~, ext] = fileparts(path);
ext = lower(string(ext));

if ext == ".json"
    txt = fileread(path);
    if contains(txt, '"crime_details"') && contains(txt, '"nodes"') && contains(txt, '"links"')
        info.format = "networkx_burglary_json";
        info.needs_mapping = false;
        info.message = "NetworkX offender network with crime_details (primary schema).";
    else
        info.message = "Unsupported JSON layout. Export the data as an event CSV " + ...
            "(entity, event, time[, x, y]) or a temporal edge list (source, target, time).";
    end
    return;
end

try
    opts = textImportOptions(path);
catch ME
    info.message = "Could not read the file as delimited text: " + ME.message;
    return;
end
names = reshape(string(opts.VariableNames), 1, []);
info.columns = names;
low = lower(strtrim(names));
m = emptyMapping();

[p, ~, profileMsg] = matchNetworkProfile(path, names);
if ~isempty(p)
    info.format = "network_flow";
    info.profile = p.id;
    info.needs_mapping = false;
    info.message = profileMsg;
    return;
end

headerless = ~isempty(names) && all(startsWith(names, "Var"));
if headerless
    if numel(names) >= 2
        m.source = names(1);
        m.target = names(2);
    end
    if numel(names) >= 3
        m.time = names(3);
    end
    if numel(names) >= 4
        m.weight = names(4);
    end
    info.format = "edge_csv";
    info.message = "No header: read positionally as source, target, time[, weight].";
else
    m.source = pick(names, low, ["source","src","from","sender","u","source_id","from_id"]);
    m.target = pick(names, low, ["target","dst","to","receiver","v","target_id","to_id","recipient"]);
    m.entity = pick(names, low, ["entity_id","entity","offender_id","offender","person_id", ...
        "person","user_id","user","actor","participant","node","account"]);
    m.event = pick(names, low, ["event_id","event","crime_id","case_id","incident_id", ...
        "incident","case","transaction_id","session_id"]);
    m.time = pick(names, low, ["event_time","timestamp","time","date","datetime", ...
        "date_time","occurred","created_at","unixtime","ts"]);
    m.x = pick(names, low, ["x","lon","longitude","lng","long"]);
    m.y = pick(names, low, ["y","lat","latitude"]);
    m.weight = pick(names, low, ["weight","count","w"]);
    if m.source ~= "" && m.target ~= ""
        info.format = "edge_csv";
        info.message = "Temporal edge list (source, target, time).";
    else
        info.format = "event_csv";
        info.message = "Event participation list (entity, event, time).";
    end
end
info.mapping = m;
if info.format == "edge_csv"
    info.needs_mapping = m.source == "" || m.target == "" || m.time == "";
else
    info.needs_mapping = m.entity == "" || m.time == "";
end
if info.needs_mapping
    info.message = info.message + " Some required columns were not detected; choose them.";
end
end

function m = emptyMapping()
m = struct('entity', "", 'event', "", 'time', "", 'x', "", 'y', "", ...
    'source', "", 'target', "", 'weight', "");
end

function name = pick(names, low, candidates)
name = "";
for c = candidates
    k = find(low == c, 1);
    if ~isempty(k)
        name = names(k);
        return;
    end
end
end
