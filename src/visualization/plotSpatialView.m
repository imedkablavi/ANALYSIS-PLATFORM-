function plotSpatialView(ax, bundle, entityIndex, t0, t1)
%PLOTSPATIALVIEW Density of events in NORMALIZED coordinate space.
%
%   PLOTSPATIALVIEW(AX, BUNDLE, ENTITYINDEX, T0, T1) shows the log event
%   density on the analysis grid (neutral grey ramp), the events inside
%   [T0,T1) (playback, blue dots) and the selected entity's chronological
%   path (ink, numbered). Axes are the provider's min-max-scaled
%   coordinates in [0,1]: relative positions only, no map, no real-world
%   locations (docs/ETHICS_AND_LIMITATIONS.md).
%   Datasets without coordinates (bundle.meta.dataset.has_coordinates ==
%   false) get an explanatory message instead of an empty plot.

if nargin < 3, entityIndex = []; end
if nargin < 4, t0 = NaT; end
if nargin < 5, t1 = NaT; end

th = appTheme();
info = bundleDatasetInfo(bundle);
if ~info.has_coordinates || ~isfield(bundle, 'spatial') || ~isfield(bundle.spatial, 'grid') ...
        || isempty(bundle.spatial.grid)
    showAxesMessage(ax, ["No coordinates in this dataset."; ...
        "The relative-space view needs x/y columns."], th);
    return;
end

cla(ax);
axis(ax, 'on');
legend(ax, 'off');
g = bundle.spatial.grid;
n = size(g, 1);
imagesc(ax, [0.5 n-0.5] / n, [0.5 n-0.5] / n, log1p(g), 'HandleVisibility', 'off');
set(ax, 'YDir', 'normal');
colormap(ax, th.densityColormap(256));
hold(ax, 'on');
shown = false;
if ~isnat(t0) && ~isnat(t1)
    c = bundle.crimes;
    m = c.event_time >= t0 & c.event_time < t1;
    scatter(ax, c.x(m), c.y(m), 24, th.semantic.windowEvents, 'filled', ...
        'MarkerEdgeColor', th.color.surface, 'LineWidth', 0.5, 'MarkerFaceAlpha', 0.75, ...
        'DisplayName', "Events in replay window");
    shown = true;
end
if ~isempty(entityIndex)
    e = bundle.events(bundle.events.entity_index == entityIndex, :);
    plot(ax, e.x, e.y, '-o', 'Color', th.semantic.selected, ...
        'MarkerFaceColor', th.semantic.selected, 'MarkerEdgeColor', th.color.surface, ...
        'MarkerSize', th.mark.marker - 1, 'LineWidth', th.mark.thinLine, ...
        'DisplayName', "Selected " + info.entity_noun + "'s path");
    for k = 1:height(e)
        text(ax, e.x(k), e.y(k), " " + k, 'FontSize', th.font.small, ...
            'Color', th.color.textSecondary, 'FontName', th.font.family, ...
            'HandleVisibility', 'off');
    end
    shown = true;
end
hold(ax, 'off');
axis(ax, [0 1 0 1]);
axis(ax, 'square');
xlabel(ax, 'X (normalized)');
ylabel(ax, 'Y (normalized)');
title(ax, 'Relative density (log) and selected path');
styleAxes(ax, th);
ax.Layer = 'top';
if shown
    styleLegend(ax, th);
end
end
