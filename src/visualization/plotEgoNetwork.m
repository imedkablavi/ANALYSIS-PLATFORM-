function info = plotEgoNetwork(ax, bundle, entityIndex, hops, maxNodes, cutoffTime)
%PLOTEGONETWORK Local co-offending network around an entity.
%
%   INFO = PLOTEGONETWORK(AX, BUNDLE, ENTITYINDEX, HOPS, MAXNODES, CUTOFFTIME)
%   draws the entities within HOPS co-offending steps (unweighted BFS),
%   capped at MAXNODES (closest first). Node colour = Isolation Forest
%   score (grey = not scored), size = number of crimes, edge width = shared
%   crimes, selected entity outlined in red. With CUTOFFTIME, edges whose
%   first shared crime is later are hidden (temporal playback).
%   INFO.nodes maps plotted node k to entity index INFO.nodes(k);
%   INFO.plot is the GraphPlot handle (for click selection).

if nargin < 4 || isempty(hops), hops = 2; end
if nargin < 5 || isempty(maxNodes), maxNodes = 400; end
if nargin < 6, cutoffTime = NaT; end

G = bundle.graph;
d = distances(G, entityIndex, 'Method', 'unweighted');
cand = find(isfinite(d) & d <= hops);
[~, order] = sort(d(cand));
cand = cand(order);
cand = cand(1:min(maxNodes, numel(cand)));
% Ascending order makes node k of H correspond to cand(k) regardless of
% whether subgraph keeps or sorts the requested order.
cand = sort(cand(:));
H = subgraph(G, cand);
if ~isnat(cutoffTime) && numedges(H) > 0
    H = rmedge(H, find(H.Edges.FirstTime > cutoffTime));
end

cla(ax);
if numedges(H) > 0
    lw = 0.5 + 1.5 * log1p(H.Edges.Weight) / log1p(max(H.Edges.Weight));
else
    lw = 1;
end
p = plot(ax, H, 'Layout', 'force', 'NodeLabel', {}, 'EdgeAlpha', 0.5, ...
    'LineWidth', lw, 'EdgeColor', [0.5 0.5 0.5]);
score = bundle.entities.iforest_score(cand);
if all(isnan(score))
    score = bundle.entities.baseline_score(cand);
end
% Explicit RGB colours: colormap position for scored nodes, grey for
% unscored (insufficient history), red for the selected entity.
cmap = parula(256);
% Use a stable global scale so node colors remain comparable when the
% selected ego network changes. Local rescaling would make the same color
% represent different anomaly scores from one selection to another.
allScore = bundle.entities.iforest_score;
if all(isnan(allScore))
    allScore = bundle.entities.baseline_score;
end
allScore = allScore(~isnan(allScore));
if isempty(allScore)
    lo = 0;
    hi = 1;
else
    lo = min(allScore);
    hi = max(allScore);
    if hi <= lo
        lo = lo - 0.5;
        hi = hi + 0.5;
    end
end
pos = round((score - lo) / (hi - lo) * 255) + 1;
colors = repmat([0.75 0.75 0.75], numel(cand), 1);
ok = ~isnan(pos);
colors(ok, :) = cmap(min(max(pos(ok), 1), 256), :);
sizes = 3 + 2 * sqrt(bundle.entities.event_count(cand));
self = find(cand == entityIndex, 1);
if ~isempty(self)
    colors(self, :) = [0.85 0.1 0.1];
    sizes(self) = max(sizes(self), 9);
end
p.NodeColor = colors;
p.MarkerSize = sizes;
colormap(ax, cmap);
ax.CLim = [lo hi];
cb = colorbar(ax);
cb.Label.String = 'Anomaly score (grey = not scored, red = selected)';
axis(ax, 'off');
title(ax, sprintf('Co-offending network within %d hops (%d offenders, %d ties)', ...
    hops, numnodes(H), numedges(H)));
info.nodes = cand;
info.plot = p;
end
