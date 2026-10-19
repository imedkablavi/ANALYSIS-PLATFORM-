function result = detectTemporalAnomalies(x, window, minBins, zThreshold, mode, binStart, seasonalLookbackYears, seasonalMinSamples, scaleFloor, trials)
%DETECTTEMPORALANOMALIES Causal rolling or seasonal robust z-scores.
%
%   RESULT = DETECTTEMPORALANOMALIES(X, WINDOW, MINBINS, ZTHRESHOLD)
%   uses a causal rolling baseline: the previous WINDOW bins.
%
%   RESULT = DETECTTEMPORALANOMALIES(..., MODE, BINSTART, ...)
%   supports:
%     "rolling"             previous WINDOW bins (default)
%     "seasonal_same_month" earlier bins with the same calendar month
%
%   For both modes, the current and future bins are never used. The robust
%   center/scale is computed by robustCenterScale (median / 1.4826*MAD with
%   explicit fallbacks). Seasonal mode is a transparent seasonal-naive
%   baseline; it requires BINSTART and enough prior same-month observations.
%
%   SCALEFLOOR (default "none") sets a minimum scale from sampling noise:
%     "poisson"   count series: scale >= sqrt(max(baseline median, 1))
%     "binomial"  proportion series: scale >= sqrt(p(1-p)/n_t), with p the
%                 baseline median and n_t = TRIALS(t), the bin's denominator
%                 (e.g. number of crimes for the co-offending share)
%   A robust scale estimated from a handful of reference values (seasonal
%   mode uses 3-5 same-month values) can fall far below ordinary sampling
%   noise; on the real monthly crime series the unfloored seasonal scale was
%   ~7 crimes for counts of ~260 (Poisson SD ~16), which turns normal
%   fluctuation into |z| > 3.5.
%
%   Seasonal mode requires monthly bins (one bin per calendar month and
%   year); weekly bins would compare a week with other weeks of the same
%   month in the SAME earlier year, which is not a seasonal baseline.
%
%   RESULT fields: value, baseline_median, baseline_scale, robust_z,
%   is_high, is_low, baseline_count, baseline_years, floor_used.

arguments
    x (:,1) double
    window (1,1) double {mustBeInteger, mustBePositive} = 12
    minBins (1,1) double {mustBeInteger, mustBePositive} = 6
    zThreshold (1,1) double = 3.5
    mode (1,1) string {mustBeMember(mode,["rolling","seasonal_same_month"])} = "rolling"
    binStart (:,1) datetime = datetime.empty(0,1)
    seasonalLookbackYears (1,1) double {mustBeInteger, mustBePositive} = 5
    seasonalMinSamples (1,1) double {mustBeInteger, mustBePositive} = 3
    scaleFloor (1,1) string {mustBeMember(scaleFloor,["none","poisson","binomial"])} = "none"
    trials (:,1) double = double.empty(0,1)
end

if numel(x) ~= numel(binStart) && mode == "seasonal_same_month"
    error("MOSAIC:TemporalLengthMismatch", ...
        "X and BINSTART must have the same number of elements for seasonal mode.");
end

x = x(:);
n = numel(x);
if mode == "seasonal_same_month" && n > 0
    ym = year(binStart(:)) * 12 + month(binStart(:));
    ym = ym(~isnan(ym));
    if numel(unique(ym)) ~= numel(ym)
        error("MOSAIC:SeasonalNeedsMonthlyBins", ...
            "Seasonal same-month mode requires one bin per calendar month (got several bins in one month).");
    end
end
if scaleFloor == "binomial" && numel(trials) ~= n
    error("MOSAIC:TemporalLengthMismatch", "TRIALS must have one value per bin for the binomial floor.");
end
med = NaN(n,1);
scale = NaN(n,1);
nRef = zeros(n,1);
refYears = strings(n,1);

if mode == "rolling"
    for t = 1:n
        ref = x(max(1, t - window):t-1);
        ref = ref(~isnan(ref));
        nRef(t) = numel(ref);
        if nRef(t) < minBins
            continue;
        end
        [med(t), scale(t)] = robustCenterScale(ref);
        refYears(t) = sprintf("previous %d bins", nRef(t));
    end
else
    binStart = binStart(:);
    yy = year(binStart);
    mm = month(binStart);
    for t = 1:n
        if isnat(binStart(t))
            continue;
        end
        refMask = ~isnan(x) & ~isnat(binStart) & ...
            mm == mm(t) & yy < yy(t) & yy >= (yy(t) - seasonalLookbackYears);
        ref = x(refMask);
        nRef(t) = numel(ref);
        if nRef(t) < seasonalMinSamples
            continue;
        end
        [med(t), scale(t)] = robustCenterScale(ref);
        refYears(t) = joinStrings(string(yy(refMask)), ",");
    end
end

floorSd = NaN(n,1);
switch scaleFloor
    case "poisson"
        floorSd = sqrt(max(med, 1));
    case "binomial"
        p = min(max(med, 0), 1);
        ok = trials(:) > 0;
        floorSd(ok) = sqrt(p(ok) .* (1 - p(ok)) ./ trials(ok));
end
floorUsed = ~isnan(scale) & ~isnan(floorSd) & scale < floorSd;
scale(floorUsed) = floorSd(floorUsed);

z = (x - med) ./ scale;
result = table(x, med, scale, z, z >= zThreshold, z <= -zThreshold, ...
    nRef, refYears, floorUsed, 'VariableNames', {'value','baseline_median', ...
    'baseline_scale','robust_z','is_high','is_low','baseline_count', ...
    'baseline_years','floor_used'});
end
