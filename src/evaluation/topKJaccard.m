function j = topKJaccard(a, b, k)
%TOPKJACCARD Jaccard overlap of the top-K rows of two score vectors.
%   Rows with NaN in either vector are ignored. Used for stability and
%   ranking-consistency analysis (no labels needed).

a = a(:);
b = b(:);
ok = ~isnan(a) & ~isnan(b);
idx = find(ok);
k = min(k, numel(idx));
if k == 0
    j = NaN;
    return;
end
[~, oa] = sort(a(ok), 'descend');
[~, ob] = sort(b(ok), 'descend');
ta = idx(oa(1:k));
tb = idx(ob(1:k));
j = numel(intersect(ta, tb)) / numel(union(ta, tb));
end
