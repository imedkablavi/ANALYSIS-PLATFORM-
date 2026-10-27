function plotEvidenceBars(ax, bundle, entityIndex)
%PLOTEVIDENCEBARS Robust z-score profile of one entity, coloured by feature group.
%
%   PLOTEVIDENCEBARS(AX, BUNDLE, ENTITYINDEX). Bar colour = feature group
%   (appTheme categorical palette, fixed per group name so a colour never
%   changes meaning between entities); a legend names the groups present.
%   Dashed rules mark the per-feature evidence threshold (default 3.5).

th = appTheme();
ev = entityEvidence(bundle, entityIndex);
if height(ev) == 0
    showAxesMessage(ax, ["Not scored: insufficient history."; ...
        "This is not a statement that the behaviour is normal."], th);
    return;
end
cla(ax, 'reset');   % also hidden-handle objects and manual limits of a previous dataset
axis(ax, 'on');
legend(ax, 'off');
hold(ax, 'on');
b = barh(ax, ev.robust_z, 0.6, 'FaceColor', 'flat', 'EdgeColor', 'none');
b.CData = th.groupColor(ev.group);
b.HandleVisibility = 'off';
% One legend key per group present, in the fixed palette order.
present = th.groups.names(ismember(th.groups.names, lower(string(ev.group))));
keys = gobjects(0);
for k = 1:numel(present)
    label = th.groups.labels(th.groups.names == present(k));
    keys(end+1) = patch(ax, NaN, NaN, th.groupColor(present(k)), ... %#ok<AGROW>
        'EdgeColor', 'none', 'DisplayName', label);
end
thr = bundle.config.anomaly.feature_z_threshold;
xline(ax, 0, '-', 'Color', th.color.axis, 'LineWidth', th.mark.thinLine, ...
    'HandleVisibility', 'off');
xline(ax, [-thr thr], '--', 'Color', th.semantic.threshold, ...
    'LineWidth', th.mark.thinLine, 'HandleVisibility', 'off');
hold(ax, 'off');
set(ax, 'YTick', 1:height(ev), 'YTickLabel', ev.label, 'YDir', 'reverse');
ylim(ax, [0.4, height(ev) + 0.6]);
xlabel(ax, sprintf('Robust z (deviation from reference median; dashed = ±%.1f)', thr));
title(ax, 'Deviation profile');
styleAxes(ax, th);
ax.FontSize = th.font.small;
ax.YGrid = 'off';
ax.XGrid = 'on';
ax.TickLength = [0 0];
if ~isempty(keys)
    styleLegend(ax, th, keys);
end
end
