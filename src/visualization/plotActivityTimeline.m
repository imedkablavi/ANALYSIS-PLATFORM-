function plotActivityTimeline(ax, bundle, entityIndex, cursorTime)
%PLOTACTIVITYTIMELINE Monthly crime counts with temporal anomalies and change points.
%
%   PLOTACTIVITYTIMELINE(AX, BUNDLE) draws the system series;
%   ENTITYINDEX (optional, [] for none) overlays the selected entity's
%   crimes as ticks; CURSORTIME (optional) draws the playback cursor.
%   Markers: triangles = months whose count deviates >= threshold robust SD
%   from the causal 12-month baseline; dashed lines = change points.

if nargin < 3, entityIndex = []; end
if nargin < 4, cursorTime = NaT; end

cla(ax);
hold(ax, 'on');
s = bundle.temporal.series;
a = bundle.temporal.crime_anomalies;
plot(ax, s.bin_start, s.crimes, '-', 'Color', [0.25 0.45 0.75], 'LineWidth', 1.2, ...
    'DisplayName', 'Crimes per month');
if isfield(bundle.temporal, 'anomaly_method') && bundle.temporal.anomaly_method == "seasonal_same_month"
    baselineLabel = 'Seasonal baseline (same calendar month)';
else
    baselineLabel = 'Causal baseline (previous 12 months)';
end
plot(ax, s.bin_start, a.baseline_median, ':', 'Color', [0.4 0.4 0.4], ...
    'DisplayName', baselineLabel);
hi = a.is_high;
lo = a.is_low;
if any(hi)
    plot(ax, s.bin_start(hi), s.crimes(hi), '^', 'MarkerFaceColor', [0.85 0.33 0.1], ...
        'MarkerEdgeColor', 'none', 'DisplayName', 'Unusually high month');
end
if any(lo)
    plot(ax, s.bin_start(lo), s.crimes(lo), 'v', 'MarkerFaceColor', [0.5 0.2 0.6], ...
        'MarkerEdgeColor', 'none', 'DisplayName', 'Unusually low month');
end
cp = bundle.temporal.change_points;
for k = 1:height(cp)
    xline(ax, s.bin_start(cp.index(k)), '--', 'Color', [0.3 0.3 0.3], ...
        'HandleVisibility', 'off');
end
if ~isempty(entityIndex)
    t = bundle.events.event_time(bundle.events.entity_index == entityIndex);
    yl = max(s.crimes) * 1.05;
    plot(ax, t, repmat(yl, size(t)), '|', 'Color', [0.8 0.1 0.1], ...
        'MarkerSize', 12, 'LineWidth', 1.5, 'DisplayName', 'Selected offender''s crimes');
end
if ~isnat(cursorTime)
    xline(ax, cursorTime, '-', 'Color', [0 0 0], 'LineWidth', 1.5, 'HandleVisibility', 'off');
end
hold(ax, 'off');
ylabel(ax, 'Crimes');
methodLabel = baselineLabel;
title(ax, 'Activity over time — ' + methodLabel + ' (solved cases; last months right-censored)');
legend(ax, 'Location', 'northwest', 'Box', 'off');
grid(ax, 'on');
end
