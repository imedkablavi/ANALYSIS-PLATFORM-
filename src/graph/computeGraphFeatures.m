function graphFeatures = computeGraphFeatures(G)
%COMPUTEGRAPHFEATURES Compute first-version node-level network features.

n = numnodes(G);
graphFeatures = table(string(G.Nodes.Name), ...
    outdegree(G), indegree(G), ...
    zeros(n,1), zeros(n,1), zeros(n,1), ...
    'VariableNames', {'entity_id','out_degree','in_degree', ...
    'total_degree','weighted_out_degree','weighted_in_degree'});

graphFeatures.total_degree = graphFeatures.out_degree + graphFeatures.in_degree;

sourceNames = string(G.Edges.EndNodes(:,1));
targetNames = string(G.Edges.EndNodes(:,2));
for i = 1:n
    id = string(G.Nodes.Name(i));
    graphFeatures.weighted_out_degree(i) = sum(G.Edges.Weight(sourceNames == id));
    graphFeatures.weighted_in_degree(i) = sum(G.Edges.Weight(targetNames == id));
end
end
