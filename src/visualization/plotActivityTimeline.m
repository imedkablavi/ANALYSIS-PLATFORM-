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
    showAxesMessage(ax, ["No dated " + info.event_plural + " in this dataset."; ...
        "The timeline needs a time column."], th);
    return;
end
a = bundle.temporal.crime_anomalies;
nounTitle = upper(extractBefore(info.event_plural, 2)) + extractAfter(info.event_plural, 1);

cla(ax);
axis(ax, 'on');
hold(ax, 'on');
plot(ax, s.bin_start, s.crimes, '-', 'Color', th.semantic.series, ...
    'LineWidth', th.mark.line, 'DisplayName', nounTitle + " per " + info.bin);
% Labels are strings ("..."): adding char vectors with + would sum their
% character codes numerically instead of concatenating text.
if isfield(bundle.temporal, 'anomaly_method') && bundle.temporal.anomaly_method == "seasonal_same_month"
    baselineLabel = "Seasonal baseline (same calendar month, prior years)";
else
    t = bundle.config.temporal;
    baselineLabel = sprintf("Causal baseline (previous %d %ss)", t.baseline_window, t.bin);
end
plot(ax, s.bin_start, a.baseline_median, ':', 'Color', th.semantic.baseline, ...
    'LineWidth', th.mark.line, 'DisplayName', baselineLabel);
hi = a.is_high;
lo = a.is_low;
if any(hi)
    plot(ax, s.bin_start(hi), s.crimes(hi), '^', 'LineStyle', 'none', ...
        'MarkerFaceColor', th.semantic.unusualHigh, 'MarkerEdgeColor', th.color.surface, ...
        'MarkerSize', th.mark.marker + 1, 'DisplayName', "Unusually high " + info.bin);
end
if any(lo)
    plot(ax, s.bin_start(lo), s.crimes(lo), 'v', 'LineStyle', 'none', ...
        'MarkerFaceColor', th.semantic.unusualLow, 'MarkerEdgeColor', th.color.surface, ...
        'MarkerSize', th.mark.marker + 1, 'DisplayName', "Unusually low " + info.bin);
end
cp = bundle.temporal.change_points;
for k = 1:height(cp)
    xl = xline(ax, s.bin_start(cp.index(k)), '--', 'Color', th.semantic.changePoint, ...
        'LineWidth', th.mark.thinLine, 'HandleVisibility', 'off');
    if k == 1
        xl.HandleVisibility = 'on';
        xl.DisplayName = 'Change point';
    end
end
yTop = max(s.crimes) * 1.08;
if ~isempty(entityIndex)
    t = bundle.events.event_time(bundle.events.entity_index == entityIndex);
    plot(ax, t, repmat(yTop, size(t)), '|', 'Color', th.semantic.selected, ...
        'MarkerSize', 10, 'LineWidth', th.mark.line, ...
        'DisplayName', "Selected " + info.entity_noun + "'s " + info.event_plural);
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
    note = "Solved cases only; the last months are right-censored.";
else
    note = "The last " + info.bin + "s may be incomplete.";
end
title(ax, ["Activity over time"; note]);
styleAxes(ax, th);
ax.XGrid = 'off';
ax.YGrid = 'on';
styleLegend(ax, th);
end
