function ap = averagePrecision(scores, labels)
%AVERAGEPRECISION Area under the precision-recall curve (step-wise AP).
%   AP = AVERAGEPRECISION(SCORES, LABELS) = mean over positives of the
%   precision at that positive's rank (rows sorted by descending score,
%   ties broken by row order). Chance level equals the positive rate.

scores = scores(:);
labels = logical(labels(:));
ok = ~isnan(scores);
scores = scores(ok);
labels = labels(ok);
nPos = sum(labels);
if nPos == 0
    ap = NaN;
    return;
end
[~, order] = sort(scores, 'descend');
hits = labels(order);
precisionAtHit = cumsum(hits) ./ (1:numel(hits))';
ap = sum(precisionAtHit(hits)) / nPos;
end
