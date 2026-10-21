function data = loadBurglaryNetwork(filePath)
%LOADBURGLARYNETWORK Load the primary burglary offender network (NetworkX JSON).
%
%   DATA = LOADBURGLARYNETWORK(FILEPATH) reads the artifact documented in
%   docs/DATASET_SCHEMA_INSPECTION.md and returns:
%
%     data.sourceFile   input path
%     data.directed     top-level "directed" flag (true in the artifact)
%     data.multigraph   top-level "multigraph" flag
%     data.graph        graph metadata struct
%     data.nodes        table: entity_id, entity_type, crime_count,
%                       detail_count (one row per JSON node, file order)
%     data.links        table: source_id, target_id, weight, link_type,
%                       observed (one row per JSON link, file order)
%     data.rawNodes     1xN cell of node structs (input to flattenBurglaryEvents)
%     data.metadata     counts and flags
%
%   Schema problems in required top-level fields raise errors. Record-level
%   problems (null weights, empty IDs, list_cid/crime_details mismatch) are
%   NOT repaired here; they are preserved as NaN/"" and reported by
%   validateBurglaryNetwork.
%
%   Note: jsondecode converts object keys that are not valid MATLAB
%   identifiers with matlab.lang.makeValidName ("CID#2" -> "CID_2").
%   Crime IDs are therefore restored from list_cid in flattenBurglaryEvents.

arguments
    filePath (1,1) string
end

if ~isfile(filePath)
    error("MOSAIC:DataFileNotFound", ...
        "Dataset file was not found: %s", filePath);
end

rawText = fileread(filePath);
try
    raw = jsondecode(rawText);
catch ME
    error("MOSAIC:InvalidJSON", ...
        "Unable to decode JSON file %s: %s", filePath, ME.message);
end
clear rawText

if ~isstruct(raw) || ~isscalar(raw)
    error("MOSAIC:SchemaMismatch", "Top-level JSON value must be an object.");
end
requiredTop = ["directed","multigraph","graph","nodes","links"];
missingTop = requiredTop(~isfield(raw, cellstr(requiredTop)));
if ~isempty(missingTop)
    error("MOSAIC:SchemaMismatch", ...
        "Missing top-level fields: %s", strjoin(missingTop, ", "));
end

data.sourceFile = filePath;
data.directed = logical(raw.directed);
data.multigraph = logical(raw.multigraph);
data.graph = raw.graph;

% jsondecode returns a struct array when all objects share the same keys
% and a cell array otherwise; normalize to a cell of scalar structs.
rawNodes = toCellOfStructs(raw.nodes);
rawLinks = toCellOfStructs(raw.links);

% --- Nodes ----------------------------------------------------------------
n = numel(rawNodes);
nodeId = strings(n,1);
nodeType = strings(n,1);
crimeCount = zeros(n,1);
detailCount = zeros(n,1);
for i = 1:n
    node = rawNodes{i};
    nodeId(i) = scalarString(node, "id");
    nodeType(i) = scalarString(node, "type");
    if isfield(node, "list_cid") && ~isempty(node.list_cid)
        crimeCount(i) = numel(cellstr(node.list_cid));
    end
    if isfield(node, "crime_details") && isstruct(node.crime_details)
        detailCount(i) = numel(fieldnames(node.crime_details));
    end
end
data.nodes = table(nodeId, nodeType, crimeCount, detailCount, ...
    'VariableNames', {'entity_id','entity_type','crime_count','detail_count'});

% --- Links ----------------------------------------------------------------
m = numel(rawLinks);
sourceId = strings(m,1);
targetId = strings(m,1);
weight = NaN(m,1);
linkType = strings(m,1);
observed = false(m,1);
for i = 1:m
    link = rawLinks{i};
    sourceId(i) = scalarString(link, "source");
    targetId(i) = scalarString(link, "target");
    if isfield(link, "weight") && isnumeric(link.weight) && isscalar(link.weight)
        weight(i) = double(link.weight);
    end
    linkType(i) = scalarString(link, "type");
    if isfield(link, "observed") && isscalar(link.observed)
        observed(i) = logical(link.observed);
    end
end
data.links = table(sourceId, targetId, weight, linkType, observed, ...
    'VariableNames', {'source_id','target_id','weight','link_type','observed'});

data.rawNodes = rawNodes;

data.metadata.node_count = height(data.nodes);
data.metadata.link_count = height(data.links);
data.metadata.directed = data.directed;
data.metadata.multigraph = data.multigraph;
end

function c = toCellOfStructs(v)
if isempty(v)
    c = {};
elseif isstruct(v)
    c = num2cell(v(:))';
elseif iscell(v)
    c = v(:)';
else
    error("MOSAIC:SchemaMismatch", "Expected a JSON array of objects.");
end
end

function s = scalarString(st, name)
% Return field NAME as a scalar string, or "" when absent/null/non-scalar.
s = "";
if isstruct(st) && isfield(st, name)
    v = st.(name);
    if ischar(v) || (isstring(v) && isscalar(v))
        s = string(v);
    elseif isnumeric(v) && isscalar(v)
        s = string(v);
    end
end
end
