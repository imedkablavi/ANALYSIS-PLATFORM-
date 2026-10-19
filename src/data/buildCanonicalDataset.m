function ds = buildCanonicalDataset(entityRaw, eventRaw, t, x, y, meta, opts)
%BUILDCANONICALDATASET Participation records -> the pipeline's dataset contract.
%
%   DS = BUILDCANONICALDATASET(ENTITYRAW, EVENTRAW, T, X, Y, META, OPTS)
%   takes one row per (entity, event) participation from ANY source and
%   returns the same structure the primary burglary importer produces, so
%   the whole pipeline (validation, features, graph, anomaly, app) runs on
%   it unchanged:
%     ds.nodes   entity_id, entity_type, crime_count, detail_count
%     ds.links   empty: relations are derived from shared events
%     ds.events  entity_id, entity_index, crime_id, crime_num, x, y,
%                event_time, num_offenders, id_restored
%     ds.graph, ds.directed, ds.multigraph, ds.sourceFile, ds.meta
%   ("crime_*" column names are kept for compatibility; for an imported
%   dataset they mean "event".)
%
%   ENTITYRAW, EVENTRAW  string columns (event "" -> one event per row)
%   T                    datetime column (unzoned)
%   X, Y                 numeric columns or [] when the source has no location
%   META                 struct; fields copied into ds.meta (name, format, ...)
%   OPTS.pseudonymize    default true: entity and event IDs are replaced by
%                        ENT000001... / EV0000001... in order of first
%                        appearance. The original IDs never enter the bundle.
%   OPTS.keep_id_map     default false: if true, ds.private.entity_map holds
%                        the mapping (saved separately, never in reports)
%
%   Documented transformations (recorded in ds.meta.import_notes, never
%   silent):
%   - rows without an entity are dropped (they cannot be attributed);
%   - coordinates are min-max scaled to [0,1] over the whole dataset, the
%     same privacy-preserving representation as the primary artifact;
%   - num_offenders = number of distinct entities sharing the event.

arguments
    entityRaw (:,1) string
    eventRaw (:,1) string
    t (:,1) datetime
    x (:,1) double
    y (:,1) double
    meta (1,1) struct
    opts struct = struct()
end

pseudo = ~isfield(opts, "pseudonymize") || opts.pseudonymize;
keepMap = isfield(opts, "keep_id_map") && opts.keep_id_map;
n = numel(entityRaw);
notes = strings(0,1);
if isempty(x)
    x = NaN(n,1);
end
if isempty(y)
    y = NaN(n,1);
end

entityRaw(ismissing(entityRaw)) = "";
eventRaw(ismissing(eventRaw)) = "";
entityRaw = strtrim(entityRaw);
eventRaw = strtrim(eventRaw);
drop = entityRaw == "";
if any(drop)
    notes(end+1,1) = sprintf("%d rows without an entity id were dropped.", nnz(drop));
    entityRaw = entityRaw(~drop); eventRaw = eventRaw(~drop);
    t = t(~drop); x = x(~drop); y = y(~drop);
end
noEvent = eventRaw == "";
if any(noEvent)
    notes(end+1,1) = sprintf("%d rows without an event id were treated as single-participant events.", nnz(noEvent));
end

% --- Identifiers ----------------------------------------------------------------
[uEnt, ~, entIdx] = unique(entityRaw, 'stable');
% Rows without an event id get their own events in a separate index range,
% so they can never merge with a real event id (no synthetic text ids).
evIdx = zeros(numel(eventRaw), 1);
[uEv, ~, evIdx(~noEvent)] = unique(eventRaw(~noEvent), 'stable');
uEv = uEv(:);
k = nnz(noEvent);
evIdx(noEvent) = numel(uEv) + (1:k)';
uEv = [uEv; "(no event id, row " + string(find(noEvent)) + ")"];
if pseudo
    entityIds = "ENT" + compose("%06d", (1:numel(uEnt))');
    eventIds = "EV" + compose("%07d", (1:numel(uEv))');
    notes(end+1,1) = "Entity and event identifiers were pseudonymized (order of first appearance).";
else
    entityIds = uEnt;
    eventIds = uEv;
end
if numel(uEnt) == 0
    entityIds = strings(0,1);
    eventIds = strings(0,1);
end

% --- Coordinates -------------------------------------------------------------------
hasXY = isfinite(x) & isfinite(y);
hasCoordinates = any(hasXY);
xs = NaN(size(x));
ys = NaN(size(y));
if hasCoordinates
    xs(hasXY) = minMax(x(hasXY));
    ys(hasXY) = minMax(y(hasXY));
    notes(end+1,1) = "Coordinates were min-max scaled to [0,1] (relative positions only).";
end

% --- Participants per event ----------------------------------------------------------
pairKey = unique([evIdx entIdx], 'rows');
participants = accumarray(pairKey(:,1), 1, [numel(uEv) 1]);

events = table(entityIds(entIdx), entIdx, eventIds(evIdx), evIdx, xs, ys, t, ...
    participants(evIdx), true(numel(entIdx),1), 'VariableNames', ...
    {'entity_id','entity_index','crime_id','crime_num','x','y','event_time', ...
    'num_offenders','id_restored'});
events = sortrows(events, {'entity_index','event_time','crime_num'});

perEntity = accumarray(pairKey(:,2), 1, [numel(uEnt) 1]);
nodes = table(entityIds, repmat("entity", numel(uEnt), 1), perEntity, perEntity, ...
    'VariableNames', {'entity_id','entity_type','crime_count','detail_count'});

ds = struct();
ds.sourceFile = string(cfgGet(meta, "source_file", ""));
ds.directed = false;
ds.multigraph = false;
ds.graph = struct('name', string(cfgGet(meta, "name", "imported dataset")));
ds.nodes = nodes;
ds.links = table(strings(0,1), strings(0,1), zeros(0,1), strings(0,1), false(0,1), ...
    'VariableNames', {'source_id','target_id','weight','link_type','observed'});
ds.events = events;

m = meta;
if ~isfield(m, "n_rows")
    m.n_rows = n;          % source rows (edge lists: set by the importer)
end
m.n_entities = numel(uEnt);
m.n_events = numel(uEv);
m.has_coordinates = hasCoordinates;
m.pseudonymized = pseudo;
m.links_provided = false;
m.expected_entity_type = "entity";
m.import_notes = [reshape(string(cfgGet(meta, "import_notes", strings(0,1))), [], 1); notes];
ds.meta = m;
if keepMap && pseudo
    ds.private.entity_map = table(entityIds, uEnt, 'VariableNames', {'entity_id','original_id'});
end
end

function v = minMax(v)
lo = min(v);
hi = max(v);
if hi > lo
    v = (v - lo) / (hi - lo);
else
    v(:) = 0.5;
end
end
