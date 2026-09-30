function graphFeatures = computeGraphFeatures(G)
%COMPUTEGRAPHFEATURES Compute node-level network features in O(E) time.

n = numnodes(G);
nodeNames = string(G.Nodes.Name);

outDeg = outdegree(G);
inDeg = indegree(G);

edgeNames = string(G.Edges.EndNodes);
% EndNodes is an Mx2 array; reshape preserves source/target columns.
edgeNames = reshape(edgeNames, [], 2);

sourceIdx = findnode(G, edgeNames(:,1));
targetIdx = findnode(G, edgeNames(:,2));

weightedOut = accumarray(sourceIdx, G.Edges.Weight, [n 1], @sum, 0);
weightedIn = accumarray(targetIdx, G.Edges.Weight, [n 1], @sum, 0);

graphFeatures = table( ...
    nodeNames, outDeg, inDeg, outDeg + inDeg, weightedOut, weightedIn, ...
    'VariableNames', {'entity_id','out_degree','in_degree', ...
    'total_degree','weighted_out_degree','weighted_in_degree'});
end
