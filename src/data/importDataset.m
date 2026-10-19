function ds = importDataset(path, opts)
%IMPORTDATASET Import any supported dataset into the pipeline's dataset contract.
%
%   DS = IMPORTDATASET(PATH) detects the format (inspectDatasetFile) and
%   returns a struct the pipeline can analyse (see buildCanonicalDataset):
%   nodes, links, events, graph, meta. OPTS (struct, optional):
%     format        override the detected format
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
%     date_format   primary JSON date format (default from projectConfig)
%
%   ds.meta always contains: id (name slug + first 8 hex of the Git blob
%   SHA, so re-importing the same file gives the same id), name, format,
%   source_file, sha, imported, mapping, n_rows, n_entities, n_events,
%   has_coordinates, pseudonymized, links_provided, expected_entity_type,
%   import_notes.

arguments
    path (1,1) string
    opts struct = struct()
end

info = inspectDatasetFile(path);
fmt = optOr(opts, "format", info.format);
mapping = mergeMapping(info.mapping, optOr(opts, "mapping", struct()));
[~, stem] = fileparts(path);
name = string(optOr(opts, "name", stem));
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
meta.id = slug(name) + "-" + extractBefore(sha + "00000000", 9);
meta.import_notes = strings(0,1);

switch fmt
    case "networkx_burglary_json"
        data = loadBurglaryNetwork(path);
        events = flattenBurglaryEvents(data, string(optOr(opts, "date_format", "yyyy-MM-dd HH:mm:ss")));
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
        T = readDelimitedTable(path);
        canon = struct('pseudonymize', optOr(opts, "pseudonymize", true), ...
            'keep_id_map', optOr(opts, "keep_id_map", false));
        timeUnit = string(optOr(opts, "time_unit", "auto"));
        useEdges = mapping.source ~= "" && mapping.target ~= "";
        if useEdges
            requireColumns(T, [mapping.source, mapping.target, mapping.time], ["source","target","time"]);
            h = height(T);
            src = string(T.(mapping.source));
            dst = string(T.(mapping.target));
            [t, tNote] = parseTimeColumn(T.(mapping.time), timeUnit);
            evId = "e" + string((1:h)');
            meta.format = "edge_csv";
            meta.import_notes(end+1,1) = "Each row is one interaction event with two participants; " + tNote + ".";
            selfLoops = nnz(src == dst);
            if selfLoops > 0
                meta.import_notes(end+1,1) = sprintf("%d self-interactions (source = target) have a single participant.", selfLoops);
            end
            if mapping.weight ~= ""
                meta.import_notes(end+1,1) = "Weight column '" + mapping.weight + ...
                    "' ignored: tie strength is derived from the number of shared events.";
            end
            ds = buildCanonicalDataset([src; dst], [evId; evId], [t; t], [], [], meta, canon);
        else
            requireColumns(T, [mapping.entity, mapping.time], ["entity","time"]);
            ent = string(T.(mapping.entity));
            if mapping.event ~= ""
                requireColumns(T, mapping.event, "event");
                ev = string(T.(mapping.event));
            else
                ev = strings(height(T), 1);
            end
            [t, tNote] = parseTimeColumn(T.(mapping.time), timeUnit);
            x = numericColumn(T, mapping.x);
            y = numericColumn(T, mapping.y);
            meta.format = "event_csv";
            meta.import_notes(end+1,1) = "Event participation rows; " + tNote + ".";
            ds = buildCanonicalDataset(ent, ev, t, x, y, meta, canon);
        end

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

function v = optOr(opts, name, default)
if isfield(opts, name)
    v = opts.(name);
else
    v = default;
end
end
