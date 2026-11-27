function plotActivityTimeline(ax, bundle, entityIndex, cursorTime)
%PLOTACTIVITYTIMELINE Monthly event counts with temporal anomalies and change points.
%
%   PLOTACTIVITYTIMELINE(AX, BUNDLE) draws the system series;
%   ENTITYINDEX (optional, [] for none) overlays the selected entity's
%   events as ink ticks; CURSORTIME (optional) draws the playback cursor
%   (an ink rule labelled with the month it closes).
%   Markers: red up-triangles / blue down-triangles = months whose count
%   deviates >= threshold robust SD above / below the configured causal
%   baseline (bundle.temporal.anomaly_method: seasonal same-month or
%   rolling); green dashed rules = change points. Colours: appTheme.

if nargin < 3, entityIndex = []; end
if nargin < 4, cursorTime = NaT; end

th = appTheme();
info = bundleDatasetInfo(bundle);
s = bundle.temporal.series;
if height(s) == 0
    showAxesMessage(ax, [uiText("No dated %s in this dataset.", uiText(info.event_plural)); ...
        uiText("The timeline needs a time column.")], th);
    return;
end
a = bundle.temporal.crime_anomalies;
noun = uiText(info.event_plural);
nounTitle = upper(extractBefore(noun, 2)) + extractAfter(noun, 1);
binWord = uiText(info.bin);

cla(ax, 'reset');   % also hidden-handle objects and manual limits of a previous dataset
axis(ax, 'on');
hold(ax, 'on');
plot(ax, s.bin_start, s.crimes, '-', 'Color', th.semantic.series, ...
    'LineWidth', th.mark.line, 'DisplayName', uiText("%s per %s", nounTitle, binWord));
% Labels are strings ("..."): adding char vectors with + would sum their
% character codes numerically instead of concatenating text.
if isfield(bundle.temporal, 'anomaly_method') && bundle.temporal.anomaly_method == "seasonal_same_month"
    baselineLabel = uiText("Seasonal baseline (same calendar month, prior years)");
else
    t = bundle.config.temporal;
    baselineLabel = uiText("Causal baseline (previous %d %ss)", t.baseline_window, binWord);
end
plot(ax, s.bin_start, a.baseline_median, ':', 'Color', th.semantic.baseline, ...
    'LineWidth', th.mark.line, 'DisplayName', baselineLabel);
hi = a.is_high;
lo = a.is_low;
if any(hi)
    plot(ax, s.bin_start(hi), s.crimes(hi), '^', 'LineStyle', 'none', ...
        'MarkerFaceColor', th.semantic.unusualHigh, 'MarkerEdgeColor', th.color.surface, ...
        'MarkerSize', th.mark.marker + 1, 'DisplayName', uiText("Unusually high %s", binWord));
end
if any(lo)
    plot(ax, s.bin_start(lo), s.crimes(lo), 'v', 'LineStyle', 'none', ...
        'MarkerFaceColor', th.semantic.unusualLow, 'MarkerEdgeColor', th.color.surface, ...
        'MarkerSize', th.mark.marker + 1, 'DisplayName', uiText("Unusually low %s", binWord));
end
cp = bundle.temporal.change_points;
for k = 1:height(cp)
    xl = xline(ax, s.bin_start(cp.index(k)), '--', 'Color', th.semantic.changePoint, ...
        'LineWidth', th.mark.thinLine, 'HandleVisibility', 'off');
    if k == 1
        xl.HandleVisibility = 'on';
        xl.DisplayName = uiText("Change point");
    end
end
yTop = max(s.crimes) * 1.08;
if ~isempty(entityIndex)
    % The selected entity's events per bin, as an ink step line on the same
    % axis (one tick mark per event does not scale to hosts with 10^5 flows).
    t = bundle.events.event_time(bundle.events.entity_index == entityIndex);
    edges = [s.bin_start; s.bin_start(end) + info.bin_step];
    own = histcounts(t, edges)';
    stairs(ax, s.bin_start, own, '-', 'Color', th.semantic.selected, ...
        'LineWidth', th.mark.line, ...
        'DisplayName', uiText("Selected %s's %s", uiText(info.entity_noun), noun));
end
if ~isnat(cursorTime)
    xline(ax, cursorTime, '-', string(cursorTime - seconds(1), info.time_format), ...
        'Color', th.semantic.cursor, 'LineWidth', th.mark.line, ...
        'LabelVerticalAlignment', 'bottom', 'LabelOrientation', 'horizontal', ...
        'FontSize', th.font.small, 'HandleVisibility', 'off');
end
hold(ax, 'off');
ylim(ax, [0, max(1, yTop * 1.04)]);
ylabel(ax, nounTitle);
if info.format == "networkx_burglary_json"
    note = uiText("Solved cases only; the last months are right-censored.");
else
    note = uiText("The last %ss may be incomplete.", binWord);
end
title(ax, [uiText("Activity over time"); note]);
styleAxes(ax, th);
ax.XGrid = 'off';
ax.YGrid = 'on';
styleLegend(ax, th);
end
