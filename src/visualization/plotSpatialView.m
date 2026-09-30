function plotSpatialView(ax, bundle, entityIndex, t0, t1)
%PLOTSPATIALVIEW Density of crimes in NORMALIZED coordinate space.
%
%   PLOTSPATIALVIEW(AX, BUNDLE, ENTITYINDEX, T0, T1) shows the log crime
%   density on the analysis grid, the crimes inside [T0,T1) (playback) and
%   the selected entity's chronological path (numbered). Axes are the
%   provider's min-max-scaled coordinates in [0,1]: relative positions
%   only, no map, no real-world locations (docs/ETHICS_AND_LIMITATIONS.md).

if nargin < 3, entityIndex = []; end
if nargin < 4, t0 = NaT; end
if nargin < 5, t1 = NaT; end

cla(ax);
g = bundle.spatial.grid;
n = size(g, 1);
imagesc(ax, [0.5 n-0.5] / n, [0.5 n-0.5] / n, log1p(g));
set(ax, 'YDir', 'normal');
colormap(ax, flipud(gray));
hold(ax, 'on');
if ~isnat(t0) && ~isnat(t1)
    c = bundle.crimes;
    m = c.event_time >= t0 & c.event_time < t1;
    scatter(ax, c.x(m), c.y(m), 10, [0.2 0.5 0.9], 'filled', 'MarkerFaceAlpha', 0.6);
end
if ~isempty(entityIndex)
    e = bundle.events(bundle.events.entity_index == entityIndex, :);
    plot(ax, e.x, e.y, '-o', 'Color', [0.85 0.2 0.1], 'MarkerFaceColor', [0.85 0.2 0.1], ...
        'MarkerSize', 4, 'LineWidth', 1);
    for k = 1:height(e)
        text(ax, e.x(k), e.y(k), " " + k, 'FontSize', 8, 'Color', [0.6 0 0]);
    end
end
hold(ax, 'off');
axis(ax, [0 1 0 1]);
axis(ax, 'square');
xlabel(ax, 'X (normalized)');
ylabel(ax, 'Y (normalized)');
title(ax, 'Relative spatial density (log) and selected path');
end
