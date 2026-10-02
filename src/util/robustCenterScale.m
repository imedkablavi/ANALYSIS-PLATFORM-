function [center, scale, method] = robustCenterScale(v)
%ROBUSTCENTERSCALE Median and robust scale with explicit fallbacks.
%
%   [CENTER, SCALE, METHOD] = ROBUSTCENTERSCALE(V) ignores NaN.
%     SCALE = 1.4826 * MAD                 (consistent for the normal SD)
%     if MAD == 0: 1.2533 * mean |v - median|   (METHOD "meanAD")
%     if that is 0 too: 1                  (METHOD "constant"; feature
%                                            carries no information)
%   The MAD fallback matters here: many count features (e.g. betweenness)
%   are zero for more than half of the offenders, which makes MAD = 0.

v = v(~isnan(v));
if isempty(v)
    center = NaN;
    scale = NaN;
    method = "empty";
    return;
end
center = median(v);
dev = abs(v - center);
scale = 1.4826 * median(dev);
method = "MAD";
if scale == 0
    scale = 1.2533 * mean(dev);
    method = "meanAD";
end
if scale == 0
    scale = 1;
    method = "constant";
end
end
