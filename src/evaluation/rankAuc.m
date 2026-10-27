function auc = rankAuc(scores, labels)
%RANKAUC ROC-AUC via the Mann-Whitney U statistic (ties count 1/2).
%   AUC = RANKAUC(SCORES, LABELS): probability that a random positive
%   (LABELS true) scores higher than a random negative. NaN if a class is
%   empty. Used only with synthetic labels (docs/EVALUATION.md).

scores = scores(:);
labels = logical(labels(:));
ok = ~isnan(scores);
scores = scores(ok);
labels = labels(ok);
nPos = sum(labels);
nNeg = sum(~labels);
if nPos == 0 || nNeg == 0
    auc = NaN;
    return;
end
r = tiedRanks(scores);
auc = (sum(r(labels)) - nPos * (nPos + 1) / 2) / (nPos * nNeg);
end
