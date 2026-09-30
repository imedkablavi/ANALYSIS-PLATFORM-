function graphFeatures = computeGraphFeatures(G)
%COMPUTEGRAPHFEATURES Node-level structural features of the co-offending graph.
%
%   GF = COMPUTEGRAPHFEATURES(G) for the undirected weighted graph from
%   buildOffenderGraph. Columns: entity_id, degree, strength, max_tie_weight,
%   clustering_coef, core_number, component_id, component_size,
%   betweenness, is_cut_vertex.
%
%   Cost (n nodes, m edges): degree/strength/ties O(m); clustering via
%   sparse (A*A).*A, O(sum of squared degrees); k-core O(m * rounds);
%   components and articulation points O(n+m); betweenness is Brandes'
%   algorithm, O(n*m) worst case, but BFS never leaves a component, so on
%   this highly fragmented graph the real cost is sum_c n_c*m_c.
%   Betweenness is unweighted (hop count) on purpose: weights are tie
%   strengths, not distances. Interpretation caveats (missing data,
%   boundary effects; Sparrow 1991) are in docs/ETHICS_AND_LIMITATIONS.md.

n = numnodes(G);
if isempty(G.Nodes) || ~ismember('Name', G.Nodes.Properties.VariableNames)
    names = string((1:n)');
else
    names = string(G.Nodes.Name);
end

deg = degree(G);
strength = zeros(n,1);
maxTie = zeros(n,1);
if numedges(G) > 0
    [s, t] = findedge(G);
    w = G.Edges.Weight;
    strength = accumarray([s; t], [w; w], [n 1]);
    maxTie = accumarray([s; t], [w; w], [n 1], @max, 0);
end

A = adjacency(G);
A = spones(A);
twiceTriangles = full(sum((A * A) .* A, 2));
clustering = zeros(n,1);
ok = deg >= 2;
clustering(ok) = twiceTriangles(ok) ./ (deg(ok) .* (deg(ok) - 1));

core = computeCoreNumbers(A);

bins = conncomp(G);
bins = bins(:);
compSize = accumarray(bins, 1);
componentSize = compSize(bins);

if numedges(G) > 0
    btw = centrality(G, 'betweenness');
    [~, cutIdx] = biconncomp(G);
else
    btw = zeros(n,1);
    cutIdx = [];
end
isCut = zeros(n,1);
isCut(cutIdx) = 1;

graphFeatures = table(names, deg, strength, maxTie, clustering, core, ...
    bins, componentSize, btw, isCut, 'VariableNames', {'entity_id', ...
    'degree','strength','max_tie_weight','clustering_coef','core_number', ...
    'component_id','component_size','betweenness','is_cut_vertex'});
end
