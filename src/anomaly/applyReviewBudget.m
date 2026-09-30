function [flag, threshold, rnk] = applyReviewBudget(scores, fraction)
%APPLYREVIEWBUDGET Flag the top FRACTION of scores for analyst review.
%
%   [FLAG, THRESHOLD, RANK] = APPLYREVIEWBUDGET(SCORES, FRACTION)
%   Without ground truth there is no statistically "correct" anomaly
%   threshold. The project therefore uses an explicit, reported review
%   budget: k = max(1, ceil(FRACTION * n)) highest-scoring rows are
%   flagged. THRESHOLD is the k-th highest score. RANK is 1 for the
%   highest score (ties broken by row order, deterministic). NaN scores
%   (ineligible rows) get RANK NaN and are never flagged.
%   Sensitivity of results to FRACTION is experiment E8.

arguments
    scores (:,1) double
    fraction (1,1) double {mustBeInRange(fraction, 0, 1)}
end

n = numel(scores);
flag = false(n, 1);
rnk = NaN(n, 1);
threshold = NaN;
valid = find(~isnan(scores));
if isempty(valid)
    return;
end
[~, order] = sort(scores(valid), 'descend');
rnk(valid(order)) = 1:numel(valid);
k = max(1, ceil(fraction * numel(valid)));
flag(valid(order(1:k))) = true;
threshold = scores(valid(order(k)));
end
