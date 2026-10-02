function plotScoreComparison(ax, bundle)
%PLOTSCORECOMPARISON Baseline vs Isolation Forest scores of eligible entities.

cla(ax);
e = bundle.entities(bundle.entities.eligible, :);
hold(ax, 'on');
scatter(ax, e.baseline_score, e.iforest_score, 8, [0.6 0.6 0.6], 'filled', ...
    'DisplayName', 'Eligible offenders');
both = e.baseline_flag & e.iforest_flag;
onlyB = e.baseline_flag & ~e.iforest_flag;
onlyI = ~e.baseline_flag & e.iforest_flag;
scatter(ax, e.baseline_score(both), e.iforest_score(both), 18, [0.85 0.1 0.1], 'filled', ...
    'DisplayName', 'Flagged by both');
scatter(ax, e.baseline_score(onlyB), e.iforest_score(onlyB), 18, [0.1 0.4 0.8], 'filled', ...
    'DisplayName', 'Baseline only');
scatter(ax, e.baseline_score(onlyI), e.iforest_score(onlyI), 18, [0.9 0.6 0.1], 'filled', ...
    'DisplayName', 'Isolation Forest only');
hold(ax, 'off');
xlabel(ax, 'Robust baseline score (RMS robust z)');
ylabel(ax, 'Isolation Forest score');
ag = bundle.anomaly.agreement;
title(ax, sprintf('Detector agreement: Spearman %.2f, top-%d Jaccard %.2f', ...
    ag.spearman, ag.k, ag.topk_jaccard));
legend(ax, 'Location', 'southeast', 'Box', 'off');
grid(ax, 'on');
end
