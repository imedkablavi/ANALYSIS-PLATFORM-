function plotEvidenceBars(ax, bundle, entityIndex)
%PLOTEVIDENCEBARS Robust z-score profile of one entity, coloured by feature group.
%   Dashed lines mark the per-feature evidence threshold (default 3.5).

cla(ax);
ev = entityEvidence(bundle, entityIndex);
if height(ev) == 0
    text(ax, 0.5, 0.5, 'Not scored: insufficient history', 'HorizontalAlignment', 'center', ...
        'Units', 'normalized');
    axis(ax, 'off');
    return;
end
axis(ax, 'on');
groups = unique(ev.group, 'stable');
colors = lines(numel(groups));
[~, gi] = ismember(ev.group, groups);
b = barh(ax, ev.robust_z, 'FaceColor', 'flat');
b.CData = colors(gi, :);
set(ax, 'YTick', 1:height(ev), 'YTickLabel', ev.label, 'YDir', 'reverse', 'FontSize', 8);
thr = bundle.config.anomaly.feature_z_threshold;
xline(ax, [-thr thr], '--', 'Color', [0.4 0.4 0.4]);
xlabel(ax, 'Robust z (deviation from reference median, robust SD)');
title(ax, 'Why: deviation profile');
grid(ax, 'on');
end
