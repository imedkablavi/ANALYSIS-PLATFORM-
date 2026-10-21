function G = buildOffenderGraph(relations, entityIds)
%BUILDOFFENDERGRAPH Undirected weighted co-offending graph.
%
%   G = BUILDOFFENDERGRAPH(RELATIONS, ENTITYIDS) returns a MATLAB graph with
%   one node per entity (node k = ENTITYIDS(k), isolated offenders
%   included) and one edge per offender pair in RELATIONS (weight = shared
%   crimes, plus FirstTime/LastTime edge attributes).
%
%   Why undirected: the artifact declares directed=true, but validation
%   (check V30) shows every link has a reverse link with the same weight,
%   and the weight equals the shared-crime count (V54). Co-offending is a
%   symmetric relation, so a digraph would only double-count edges and
%   make in-degree identical to out-degree. See docs/GRAPH_ANALYSIS.md.

arguments
    relations table
    entityIds (:,1) string
end

n = numel(entityIds);
if height(relations) == 0
    G = graph(sparse(n, n));
else
    edges = table([relations.a_index relations.b_index], double(relations.weight), ...
        relations.first_time, relations.last_time, ...
        'VariableNames', {'EndNodes','Weight','FirstTime','LastTime'});
    G = graph(edges, table((1:n)', 'VariableNames', {'EntityIndex'}));
end
if ~ismember('EntityIndex', G.Nodes.Properties.VariableNames)
    G.Nodes.EntityIndex = (1:n)';
end
G.Nodes.Name = cellstr(entityIds);
end
