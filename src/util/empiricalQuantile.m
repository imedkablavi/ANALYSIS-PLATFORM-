function q = empiricalQuantile(v, p)
%EMPIRICALQUANTILE Linear-interpolation quantile (Hyndman & Fan type 7).
%
%   Q = EMPIRICALQUANTILE(V, P) ignores NaN values. Implemented here so the
%   analytical core does not depend on a toolbox for a basic statistic.

v = sort(v(~isnan(v)));
q = NaN(size(p));
m = numel(v);
if m == 0
    return;
end
if m == 1
    q(:) = v;
    return;
end
h = (m - 1) * p(:) + 1;
lo = floor(h);
hi = min(lo + 1, m);
q(:) = v(lo) + (h - lo) .* (v(hi) - v(lo));
end
