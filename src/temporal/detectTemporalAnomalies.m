function result = detectTemporalAnomalies(x, window, minBins, zThreshold)
%DETECTTEMPORALANOMALIES Causal rolling robust z-scores for a count series.
%
%   RESULT = DETECTTEMPORALANOMALIES(X, WINDOW, MINBINS, ZTHRESHOLD)
%   For each bin t, the baseline is the median of the previous WINDOW bins
%   (X(t-WINDOW) .. X(t-1)); bin t itself and the future are never used,
%   so the score is available in real time (no look-ahead leakage).
%       z_t = (x_t - median) / (1.4826 * MAD)
%   (modified z-score, Iglewicz & Hoaglin 1993). When MAD = 0 the scale
%   falls back to 1.2533 * mean absolute deviation, then to 1.
%   Bins with fewer than MINBINS baseline bins get NaN.
%
%   RESULT table: value, baseline_median, baseline_scale, robust_z,
%   is_high (z >= threshold), is_low (z <= -threshold).

arguments
    x (:,1) double
    window (1,1) double {mustBeInteger, mustBePositive} = 12
    minBins (1,1) double {mustBeInteger, mustBePositive} = 6
    zThreshold (1,1) double = 3.5
end

n = numel(x);
med = NaN(n,1);
scale = NaN(n,1);
for t = 1:n
    ref = x(max(1, t - window):t-1);
    ref = ref(~isnan(ref));
    if numel(ref) < minBins
        continue;
    end
    [med(t), scale(t)] = robustCenterScale(ref);
end
z = (x - med) ./ scale;
result = table(x, med, scale, z, z >= zThreshold, z <= -zThreshold, ...
    'VariableNames', {'value','baseline_median','baseline_scale', ...
    'robust_z','is_high','is_low'});
end
