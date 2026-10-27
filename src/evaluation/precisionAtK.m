function [p, r] = precisionAtK(scores, labels, k)
%PRECISIONATK Precision and recall among the K highest scores.

scores = scores(:);
labels = logical(labels(:));
ok = ~isnan(scores);
scores = scores(ok);
labels = labels(ok);
k = min(k, numel(scores));
[~, order] = sort(scores, 'descend');
top = labels(order(1:k));
p = sum(top) / max(k, 1);
r = sum(top) / max(sum(labels), 1);
end
