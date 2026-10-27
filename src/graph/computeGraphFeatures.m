function [graphFeatures, notes] = computeGraphFeatures(G, cfg)
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
%
%   Scale guards (CFG, optional; NOTES lists what was skipped). Network
%   traffic graphs are the opposite of the fragmented co-offending graph:
%   one giant component held together by gateways/DNS servers with
%   hundreds of thousands of neighbours. Then
%   - clustering needs (A*A).*A, whose work and memory grow with
%     sum(degree.^2) (one hub of degree d alone creates d^2 entries); above
%     cfg.graph.max_clustering_work (default 2e8) clustering is NaN;
%   - Brandes betweenness costs ~ n*m inside the giant component; above
%     cfg.graph.max_betweenness_nodes nodes in the largest component
%     (default 50,000) betweenness is NaN.
%   NaN features are dropped by prepareFeatureMatrix and reported there;
%   the skip is never silent. The burglary graph (largest component 518,
%   sum(deg^2) in the thousands) is far below both limits.

if nargin < 2
    cfg = struct();
end
maxWork = cfgGet(cfg, "graph.max_clustering_work", 2e8);
maxBtwNodes = cfgGet(cfg, "graph.max_betweenness_nodes", 5e4);
notes = strings(0, 1);
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
work = sum(deg .^ 2);
if work <= maxWork
    twiceTriangles = full(sum((A * A) .* A, 2));
    clustering = zeros(n,1);
    ok = deg >= 2;
    clustering(ok) = twiceTriangles(ok) ./ (deg(ok) .* (deg(ok) - 1));
else
    clustering = NaN(n, 1);
    notes(end+1, 1) = sprintf("clustering_coef not computed: sum(degree^2) = %.3g exceeds " + ...
        "graph.max_clustering_work = %.3g (hub nodes; memory).", work, maxWork);
end

core = computeCoreNumbers(A);

bins = conncomp(G);
bins = bins(:);
compSize = accumarray(bins, 1);
componentSize = compSize(bins);

if numedges(G) > 0
    if max(compSize) <= maxBtwNodes
        btw = centrality(G, 'betweenness');
    else
        btw = NaN(n, 1);
        notes(end+1, 1) = sprintf("betweenness not computed: largest component has %d nodes " + ...
            "(> graph.max_betweenness_nodes = %d; Brandes cost ~ n*m).", max(compSize), maxBtwNodes);
    end
    [~, cutIdx] = biconncomp(G);
else
    btw = zeros(n,1);
    cutIdx = [];
end
isCut = zeros(n,1);
if iscell(cutIdx) || isstring(cutIdx)
    % biconncomp returns node NAMES for graphs with named nodes (observed
    % in R2026b); convert to indices.
    cutIdx = findnode(G, cutIdx);
end
isCut(cutIdx) = 1;

graphFeatures = table(names, deg, strength, maxTie, clustering, core, ...
    bins, componentSize, btw, isCut, 'VariableNames', {'entity_id', ...
    'degree','strength','max_tie_weight','clustering_coef','core_number', ...
    'component_id','component_size','betweenness','is_cut_vertex'});
end
