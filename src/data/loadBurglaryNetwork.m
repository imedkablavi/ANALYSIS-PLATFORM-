function data = loadBurglaryNetwork(filePath)
%LOADBURGLARYNETWORK Load the primary burglary offender network.
%
%   DATA = LOADBURGLARYNETWORK(FILEPATH) reads the NetworkX JSON file
%   documented in docs/DATASETS.md and returns a normalized MATLAB struct.
%
%   Expected source schema:
%       directed, multigraph, graph, nodes, links
%
%   Node fields:
%       type, list_cid, crime_details, id
%
%   Crime detail fields:
%       X, Y, date, num_of_offenders
%
%   Link fields:
%       weight, type, observed, source, target
%
%   The function performs schema checks but does not silently repair data.

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
data.raw = raw;

% Normalize nodes into a MATLAB table.
n = numel(raw.nodes);
nodeId = strings(n,1);
nodeType = strings(n,1);
crimeCount = zeros(n,1);
for i = 1:n
    nodeId(i) = string(raw.nodes(i).id);
    nodeType(i) = string(raw.nodes(i).type);
    if isfield(raw.nodes(i), "list_cid") && ~isempty(raw.nodes(i).list_cid)
        crimeCount(i) = numel(raw.nodes(i).list_cid);
    else
        crimeCount(i) = 0;
    end
end
data.nodes = table(nodeId, nodeType, crimeCount, ...
    'VariableNames', {'entity_id','entity_type','crime_count'});

% Normalize links into a table.
m = numel(raw.links);
sourceId = strings(m,1);
targetId = strings(m,1);
weight = NaN(m,1);
linkType = strings(m,1);
observed = false(m,1);
for i = 1:m
    sourceId(i) = string(raw.links(i).source);
    targetId(i) = string(raw.links(i).target);
    if isfield(raw.links(i), "weight"),   weight(i) = double(raw.links(i).weight); end
    if isfield(raw.links(i), "type"),     linkType(i) = string(raw.links(i).type); end
    if isfield(raw.links(i), "observed"), observed(i) = logical(raw.links(i).observed); end
end
data.links = table(sourceId, targetId, weight, linkType, observed, ...
    'VariableNames', {'source_id','target_id','weight','link_type','observed'});

data.metadata.node_count = height(data.nodes);
data.metadata.link_count = height(data.links);
data.metadata.directed = data.directed;
data.metadata.multigraph = data.multigraph;
end
