function info = plotEgoNetwork(ax, bundle, entityIndex, hops, maxNodes, cutoffTime)
%PLOTEGONETWORK Local relation (co-offending) network around an entity.
%
%   INFO = PLOTEGONETWORK(AX, BUNDLE, ENTITYINDEX, HOPS, MAXNODES, CUTOFFTIME)
%   draws the entities within HOPS steps (unweighted BFS), capped at
%   MAXNODES (closest first). Node colour = anomaly score on a single-hue
%   ramp (appTheme.scoreColormap; grey = not scored), size = number of
%   events, edge width = shared events; the selected entity keeps its
%   score colour and is marked by an ink ring. With CUTOFFTIME (exclusive
%   window end, as in buildPlaybackFrame), ties whose first shared event
%   is on or after it are hidden (temporal playback). They are hidden, not
%   removed, so the layout is computed on the same graph in every frame
%   and nodes do not jump during replay. No node labels (no identifiers
%   in exported figures).
%   INFO.nodes maps plotted node k to entity index INFO.nodes(k);
%   INFO.plot is the GraphPlot handle (for click selection).

if nargin < 4 || isempty(hops), hops = 2; end
if nargin < 5 || isempty(maxNodes), maxNodes = 400; end
if nargin < 6, cutoffTime = NaT; end

th = appTheme();
ds = bundleDatasetInfo(bundle);
G = bundle.graph;
hubLimit = 60;                 % neighbours shown around a hub
deg = degree(G, entityIndex);
hubMode = deg > hubLimit;
if hubMode
    % A hub (gateway, server, scanner) has thousands of neighbours: a
    % 2-hop view is an unreadable hairball. Show its strongest ties only.
    [eid, nid] = outedges(G, entityIndex);
    [~, order] = sort(G.Edges.Weight(eid), 'descend');
    keep = order(1:min(hubLimit, numel(order)));
    cand = [entityIndex; nid(keep)];
    hops = 1;
else
    d = distances(G, entityIndex, 'Method', 'unweighted');
    cand = find(isfinite(d) & d <= hops);
    [~, order] = sort(d(cand));
    cand = cand(order);
    cand = cand(1:min(maxNodes, numel(cand)));
end
% Ascending order makes node k of H correspond to cand(k) regardless of
% whether subgraph keeps or sorts the requested order.
cand = sort(cand(:));
H = subgraph(G, cand);
future = false(numedges(H), 1);
if ~isnat(cutoffTime) && numedges(H) > 0
    future = H.Edges.FirstTime >= cutoffTime;
end

cla(ax, 'reset');   % also hidden-handle objects and manual limits of a previous dataset
legend(ax, 'off');
if numedges(H) > 0
    lw = 0.5 + 1.5 * log1p(H.Edges.Weight) / log1p(max(H.Edges.Weight));
else
    lw = 1;
end
p = plot(ax, H, 'Layout', 'force', 'NodeLabel', {}, 'EdgeAlpha', 0.45, ...
    'LineWidth', lw, 'EdgeColor', th.semantic.edge);
if any(future)
    [fs, ft] = findedge(H, find(future));
    highlight(p, fs, ft, 'LineStyle', 'none');
end
score = bundle.entities.iforest_score(cand);
scoreName = uiText("Isolation Forest score");
if all(isnan(score))
    score = bundle.entities.baseline_score(cand);
    scoreName = uiText("Baseline score");
end
cmap = th.scoreColormap(256);
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
colors = repmat(th.semantic.unscored, numel(cand), 1);
ok = ~isnan(pos);
colors(ok, :) = cmap(min(max(pos(ok), 1), 256), :);
% Size grows with log(event count) and stays between 4 and 14 points: a
% sqrt scale made a host with 186,952 flows a marker covering the axes.
cnt = log1p(bundle.entities.event_count(cand));
sizes = 4 + 10 * cnt / max(max(cnt), eps);
self = find(cand == entityIndex, 1);
if ~isempty(self)
    sizes(self) = max(sizes(self), 9);
end
p.NodeColor = colors;
p.MarkerSize = sizes;
if ~isempty(self)
    % Ink ring around the selected node; it ignores clicks so node
    % selection on the GraphPlot underneath keeps working.
    hold(ax, 'on');
    plot(ax, p.XData(self), p.YData(self), 'o', 'MarkerSize', sizes(self) + 6, ...
        'MarkerEdgeColor', th.semantic.selected, 'LineWidth', 2, ...
        'HitTest', 'off', 'PickableParts', 'none', 'HandleVisibility', 'off');
    hold(ax, 'off');
end
colormap(ax, cmap);
ax.CLim = [lo hi];
cb = colorbar(ax);
cb.Label.String = uiText("%s (grey = not scored; ring = selected)", scoreName);
cb.Label.Color = th.color.textSecondary;
cb.Color = th.color.textSecondary;
cb.FontSize = th.font.small;
cb.Box = 'off';
cb.TickDirection = 'out';
styleAxes(ax, th);
axis(ax, 'off');
if hubMode
    ttl = uiText("%s: %d strongest of %d ties", uiText(ds.network_label), numnodes(H) - 1, deg);
else
    ttl = uiText("%s within %d hops (%d %s, %d ties)", uiText(ds.network_label), ...
        hops, numnodes(H), uiText(ds.entity_plural), nnz(~future));
end
if ~isnat(cutoffTime)
    ttl = uiText("%s — ties formed before %s", ttl, string(cutoffTime, ds.time_format));
end
title(ax, ttl, 'Color', th.color.text, 'FontWeight', 'normal');
info.nodes = cand;
info.plot = p;
end
