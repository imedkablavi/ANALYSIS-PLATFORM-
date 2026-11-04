function ap = averagePrecision(scores, labels)
%AVERAGEPRECISION Area under the precision-recall curve (step-wise AP).
%   AP = sum over distinct score thresholds of precision * recall gain.
%   Equal scores enter the retrieved set together, making AP invariant to
%   row order. A constant-score predictor has AP equal to the positive rate.

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
[sorted, order] = sort(scores, 'descend');
hits = cumsum(labels(order));
ends = find([diff(sorted) ~= 0; true]);
precision = hits(ends) ./ ends;
positiveGain = diff([0; hits(ends)]);
ap = sum(precision .* positiveGain) / nPos;
end
