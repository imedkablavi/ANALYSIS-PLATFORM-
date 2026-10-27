function plotScoreComparison(ax, bundle, selectedIndex)
%PLOTSCORECOMPARISON Baseline vs Isolation Forest scores of eligible entities.
%
%   PLOTSCORECOMPARISON(AX, BUNDLE) scatters every scored entity (grey)
%   and the flagged classes: both detectors (red diamond), baseline only
%   (blue square), Isolation Forest only (aqua triangle). Shape doubles
%   the colour so the classes stay separable under colour-vision
%   deficiency (appTheme). SELECTEDINDEX (optional) adds an ink ring on
%   that entity when it is scored.

if nargin < 3, selectedIndex = []; end
th = appTheme();
info = bundleDatasetInfo(bundle);
eligible = bundle.entities.eligible;
e = bundle.entities(eligible, :);
if height(e) == 0 || all(isnan(e.iforest_score))
    showAxesMessage(ax, ["Isolation Forest scores are not available for this dataset"; ...
        "(not run, or no entity has enough history)."], th);
    return;
end
cla(ax, 'reset');   % also hidden-handle objects and manual limits of a previous dataset
axis(ax, 'on');
legend(ax, 'off');
hold(ax, 'on');
scatter(ax, e.baseline_score, e.iforest_score, 10, th.semantic.scoredNeutral, 'filled', ...
    'DisplayName', "Scored " + info.entity_plural);
both = e.baseline_flag & e.iforest_flag;
onlyB = e.baseline_flag & ~e.iforest_flag;
onlyI = ~e.baseline_flag & e.iforest_flag;
A = th.mark.scatterArea;
scatter(ax, e.baseline_score(both), e.iforest_score(both), A * 1.2, ...
    th.semantic.flaggedBoth, 'd', 'filled', 'MarkerEdgeColor', th.color.surface, ...
    'LineWidth', 0.75, 'DisplayName', 'Flagged by both');
scatter(ax, e.baseline_score(onlyB), e.iforest_score(onlyB), A, ...
    th.semantic.baselineOnly, 's', 'filled', 'MarkerEdgeColor', th.color.surface, ...
    'LineWidth', 0.75, 'DisplayName', 'Baseline only');
scatter(ax, e.baseline_score(onlyI), e.iforest_score(onlyI), A, ...
    th.semantic.iforestOnly, '^', 'filled', 'MarkerEdgeColor', th.color.surface, ...
    'LineWidth', 0.75, 'DisplayName', 'Isolation Forest only');
if ~isempty(selectedIndex) && selectedIndex <= numel(eligible) && eligible(selectedIndex)
    s = bundle.entities(selectedIndex, :);
    scatter(ax, s.baseline_score, s.iforest_score, A * 4, th.semantic.selected, 'o', ...
        'LineWidth', th.mark.ring, 'DisplayName', 'Selected');
end
hold(ax, 'off');
xlabel(ax, 'Robust baseline score (RMS robust z)');
ylabel(ax, 'Isolation Forest score');
ag = bundle.anomaly.agreement;
title(ax, sprintf('Detector agreement: Spearman %.2f, top-%d Jaccard %.2f', ...
    ag.spearman, ag.k, ag.topk_jaccard));
styleAxes(ax, th);
grid(ax, 'on');
styleLegend(ax, th);
end
