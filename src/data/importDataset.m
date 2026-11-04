function ds = importDataset(path, opts)
%IMPORTDATASET Import any supported dataset into the pipeline's dataset contract.
%
%   DS = IMPORTDATASET(PATH) detects the format (inspectDatasetFile) and
%   returns a struct the pipeline can analyse (see buildCanonicalDataset):
%   nodes, links, events, graph, meta. OPTS (struct, optional):
%     format        override the detected format (skips detection for the
%                   primary JSON, which avoids reading the large file twice)
%     info          a result of inspectDatasetFile already computed by the
%                   caller (skips a second inspection)
%     mapping       column mapping struct (fields entity, event, time, x, y,
%                   source, target, weight); missing fields fall back to
%                   the detected mapping
%     name          dataset display name (default: file name)
%     time_unit     for numeric time columns: "auto" | "posix_s" |
%                   "posix_ms" | "excel" | "datenum" (default "auto")
%     pseudonymize  default true for external datasets (see
%                   buildCanonicalDataset); the primary artifact is already
%                   pseudonymized by its provider
%     keep_id_map   default false
%     profile       network_flow: force a networkFlowProfiles id
%     max_rows, labels_file   network_flow options (importNetworkFlows)
%     date_format   primary JSON date format (default from projectConfig)
%
%   ds.meta always contains: id (name slug + import identity hash, including
%   slice, mapping and label content), source sha, import_sha, name, format,
%   source_file, sha, imported, mapping, n_rows, n_entities, n_events,
%   has_coordinates, pseudonymized, links_provided, expected_entity_type,
%   import_notes.

arguments
    path (1,1) string
    opts struct = struct()
end

opts = validateImportOptions(opts);

if isfield(opts, "info")
    info = opts.info;
elseif isfield(opts, "format") && string(opts.format) == "networkx_burglary_json"
    info = struct('format', "networkx_burglary_json", 'mapping', struct(), 'message', "");
else
    info = inspectDatasetFile(path);
end
fmt = string(cfgGet(opts, "format", info.format));
if fmt ~= "network_flow" && (cfgGet(opts, "first_row", 1) ~= 1 || ...
        isfinite(cfgGet(opts, "max_rows", Inf)))
    error("MOSAIC:UnsupportedSelection", ...
        "Record slicing is supported for network-flow imports only.");
end
mapping = mergeMapping(info.mapping, cfgGet(opts, "mapping", struct()));
if isfield(opts, "mapping")
    % Explicit dialog aliases override auto-detected role names.
    if isfield(opts.mapping, "source")
        mapping.src = string(opts.mapping.source);
    end
    if isfield(opts.mapping, "target")
        mapping.dst = string(opts.mapping.target);
    end
end
[~, stem] = fileparts(path);
name = string(cfgGet(opts, "name", stem));
if strlength(name) == 0
    name = string(stem);
end
[~, sha] = verifyGitBlobSha(path);

meta = struct();
meta.name = name;
meta.format = string(fmt);
meta.source_file = path;
meta.sha = sha;
meta.imported = datetime('now');
meta.mapping = mapping;
identity = struct('source_sha', sha, 'format', fmt, 'mapping', mapping, ...
    'profile', string(cfgGet(opts, "profile", cfgGet(info, "profile", ""))), ...
    'first_row', cfgGet(opts, "first_row", 1), 'max_rows', cfgGet(opts, "max_rows", Inf), ...
    'time_unit', string(cfgGet(opts, "time_unit", "auto")), ...
    'time_formats', string(cfgGet(opts, "time_formats", strings(1,0))), ...
    'date_format', string(cfgGet(opts, "date_format", "yyyy-MM-dd HH:mm:ss")), ...
    'pseudonymize', cfgGet(opts, "pseudonymize", true), ...
    'keep_id_map', cfgGet(opts, "keep_id_map", false), 'labels_sha', "");
labelsFile = string(cfgGet(opts, "labels_file", ""));
if strlength(labelsFile) > 0
    [~, identity.labels_sha] = verifyGitBlobSha(labelsFile);
end
meta.import_sha = identitySha(identity);
meta.id = slug(name) + "-" + extractBefore(meta.import_sha, 17);
meta.import_notes = strings(0,1);

switch fmt
    case "networkx_burglary_json"
        data = loadBurglaryNetwork(path);
        events = flattenBurglaryEvents(data, string(cfgGet(opts, "date_format", "yyyy-MM-dd HH:mm:ss")));
        ds = rmfield(data, "rawNodes");
        ds.events = events;
        meta.n_rows = height(events);
        meta.n_entities = height(data.nodes);
        meta.n_events = numel(unique(events.crime_id));
        meta.has_coordinates = any(isfinite(events.x) & isfinite(events.y));
        meta.pseudonymized = false;   % provider pseudonyms (OID#/CID#) are kept
        meta.links_provided = true;
        meta.expected_entity_type = "offender";
        meta.import_notes = "Provider-anonymized identifiers and min-max scaled coordinates kept as published.";
        ds.meta = meta;

    case {"event_csv", "edge_csv"}
        % Identifier columns are read as text (never as double).
        timeText = strings(1,0);
        if isfield(opts, "time_formats") || isfield(opts, "date_format")
            timeText = mapping.time;
        end
        T = readDelimitedTable(path, [mapping.entity, mapping.event, mapping.source, mapping.target, timeText]);
        canon = struct('pseudonymize', cfgGet(opts, "pseudonymize", true), ...
            'keep_id_map', cfgGet(opts, "keep_id_map", false));
        timeUnit = string(cfgGet(opts, "time_unit", "auto"));
        timeFormats = string(cfgGet(opts, "time_formats", cfgGet(opts, "date_format", strings(1,0))));
        % An explicitly requested format wins over column detection.
        useEdges = fmt == "edge_csv" || (~isfield(opts, "format") && ...
            mapping.source ~= "" && mapping.target ~= "");
        meta.n_rows = height(T);
        if useEdges
            requireColumns(T, [mapping.source, mapping.target, mapping.time], ["source","target","time"]);
            h = height(T);
            src = string(T.(mapping.source));
            dst = string(T.(mapping.target));
            [t, tNote] = parseTimeColumn(T.(mapping.time), timeUnit, timeFormats);
            evId = "e" + string((1:h)');
            self = src == dst;            % self-interaction: one participant
            meta.format = "edge_csv";
            meta.import_notes(end+1,1) = "Each row is one interaction event with two participants; " + tNote + ".";
            selfLoops = nnz(self);
            if selfLoops > 0
                meta.import_notes(end+1,1) = sprintf("%d self-interactions (source = target) have a single participant.", selfLoops);
            end
            if mapping.weight ~= ""
                meta.import_notes(end+1,1) = "Weight column '" + mapping.weight + ...
                    "' ignored: tie strength is derived from the number of shared events.";
            end
            ds = buildCanonicalDataset([src; dst(~self)], [evId; evId(~self)], ...
                [t; t(~self)], [], [], meta, canon);
        else
            requireColumns(T, [mapping.entity, mapping.time], ["entity","time"]);
            ent = string(T.(mapping.entity));
            if mapping.event ~= ""
                requireColumns(T, mapping.event, "event");
                ev = string(T.(mapping.event));
            else
                ev = strings(height(T), 1);
            end
            [t, tNote] = parseTimeColumn(T.(mapping.time), timeUnit, timeFormats);
            x = numericColumn(T, mapping.x);
            y = numericColumn(T, mapping.y);
            meta.format = "event_csv";
            meta.import_notes(end+1,1) = "Event participation rows; " + tNote + ".";
            ds = buildCanonicalDataset(ent, ev, t, x, y, meta, canon);
        end

    case "network_flow"
        profileId = string(cfgGet(opts, "profile", cfgGet(info, "profile", "")));
        if profileId == ""
            error("MOSAIC:UnknownProfile", "network_flow needs a profile (see networkFlowProfiles).");
        end
        opts.mapping = mapping;
        ds = importNetworkFlows(path, profileId, meta, opts);

    otherwise
        error("MOSAIC:UnsupportedFormat", "Unsupported dataset format: %s. %s", fmt, info.message);
end
end

function requireColumns(T, cols, roles)
names = string(T.Properties.VariableNames);
for k = 1:numel(cols)
    if cols(k) == "" || ~ismember(cols(k), names)
        error("MOSAIC:MappingMissing", ...
            "Column for '%s' is not set or not found (available: %s).", roles(k), strjoin(names, ", "));
    end
end
end

function v = numericColumn(T, col)
v = [];
if col == ""
    return;
end
c = T.(col);
if isnumeric(c)
    v = double(c);
else
    v = str2double(string(c));
end
end

function m = mergeMapping(detected, given)
m = detected;
fn = fieldnames(given);
for k = 1:numel(fn)
    m.(fn{k}) = string(given.(fn{k}));
end
end

function s = slug(name)
s = lower(regexprep(char(name), '[^A-Za-z0-9]+', '-'));
s = regexprep(s, '^-+|-+$', '');
if isempty(s)
    s = 'dataset';
end
s = string(s(1:min(end, 40)));
end

function sha = identitySha(value)
% Sorted nested fields make mapping insertion order irrelevant.
value.mapping = orderfields(value.mapping);
value = orderfields(value);
bytes = unicode2native(jsonencode(value), 'UTF-8');
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(uint8(bytes), 'int8'));
digest = typecast(md.digest(), 'uint8');
sha = lower(string(reshape(dec2hex(digest, 2)', 1, [])));
end
