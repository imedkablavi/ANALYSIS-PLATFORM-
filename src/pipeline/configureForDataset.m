function [cfg, notes] = configureForDataset(cfg, ds)
%CONFIGUREFORDATASET Adapt time windows and bins to the dataset being analysed.
%
%   [CFG, NOTES] = CONFIGUREFORDATASET(CFG, DS) leaves CFG unchanged for the
%   verified primary artifact (its windows are documented decisions, see
%   docs/TEMPORAL_ANALYSIS.md). For any other dataset the hard-coded
%   2014-2020 windows would be meaningless, so they are derived from the data:
%     bin            the coarsest unit that still gives a usable series:
%                    month (span >= 24 months), week (>= 26 weeks), day
%                    (>= 30 days), hour (>= 24 hours), otherwise minute.
%                    Network captures last hours (CTU-13) or weeks (LANL),
%                    burglary-like records years.
%     series_start   start of the bin containing the earliest event
%                    (month start for week bins)
%     series_end     start of the bin containing the latest event (month
%                    start for week bins). EXCLUSIVE: the last, usually
%                    partial, bin is left out
%     anomaly_method "seasonal_same_month" only with monthly bins and
%                    >= 4 calendar years (3 prior years are needed to score
%                    a month); otherwise "rolling"
%     snapshot_years calendar years covered
%     snapshot_starts dynamic-graph window edges: calendar years for month
%                    and week bins, otherwise ~8 equal windows aligned to
%                    the bin (a yearly window would hold the whole capture)
%     plausible dates 1900-01-01 .. end of the current year (LANL relative
%                    times start in 1970)
%   Every change is listed in NOTES (stored in bundle.meta.config_notes).
%   Feature, anomaly and evaluation settings are not changed.

arguments
    cfg struct
    ds (1,1) struct
end

notes = strings(0,1);
isPrimary = isfield(ds, "meta") && isfield(ds.meta, "sha") && ...
    ds.meta.sha == cfgGet(cfg, "data.expected_blob_sha", "");
if isPrimary
    notes(end+1,1) = "Verified primary artifact: documented configuration used unchanged.";
    return;
end

t = ds.events.event_time(~isnat(ds.events.event_time));
if isempty(t)
    error("MOSAIC:NoValidTimes", "The dataset has no parseable event times; temporal analysis is impossible.");
end
tMin = min(t);
tMax = max(t);
minimum = struct('month', 24, 'week', 26, 'day', 30, 'hour', 24, 'minute', 0);
for unit = ["month", "week", "day", "hour", "minute"]
    % Weekly series keep month-aligned limits (as before day/hour/minute
    % bins existed); finer units are aligned to their own unit.
    align = unit;
    if unit == "week"
        align = "month";
    end
    t0 = dateshift(tMin, 'start', align);
    t1 = dateshift(tMax, 'start', align);
    nBins = binCount(t0, t1, unit);
    if nBins >= minimum.(unit)
        break;
    end
end
if nBins < 1
    t1 = t0 + binStep(unit);
    nBins = 1;
    notes(end+1,1) = "All events fall in one " + unit + ": the series covers that (possibly partial) " + unit + ".";
end

cfg.temporal.series_start = t0;
cfg.temporal.series_end = t1;
cfg.temporal.bin = unit;
fmt = 'yyyy-MM-dd';
if ismember(unit, ["hour", "minute"])
    fmt = 'yyyy-MM-dd HH:mm';
end
notes(end+1,1) = sprintf("Temporal series %s to %s in %d %s bins (exclusive end; last partial %s left out).", ...
    string(t0, fmt), string(t1, fmt), nBins, unit, unit);

if unit ~= "month"
    cfg.temporal.anomaly_method = "rolling";
    notes(end+1,1) = sprintf("%s bins: rolling baseline of the previous %d bins.", ...
        upper(extractBefore(unit, 2)) + extractAfter(unit, 1), cfg.temporal.baseline_window);
elseif year(t1) - year(t0) < 4
    cfg.temporal.anomaly_method = "rolling";
    notes(end+1,1) = "Fewer than 4 calendar years: rolling baseline (seasonal needs 3 prior years).";
else
    notes(end+1,1) = "Monthly bins; configured temporal method kept (" + cfg.temporal.anomaly_method + ").";
end

cfg.temporal.snapshot_years = year(t0):year(tMax);
if ismember(unit, ["month", "week"])
    cfg.temporal.snapshot_starts = datetime.empty(0, 1);   % yearly windows
    notes(end+1,1) = "Dynamic-graph windows: calendar years " + year(t0) + "-" + year(tMax) + ".";
else
    k = min(8, nBins);
    edges = unique(round(linspace(0, nBins, k + 1)));
    cfg.temporal.snapshot_starts = reshape(t0 + edges * binStep(unit), [], 1);
    notes(end+1,1) = sprintf("Dynamic-graph windows: %d equal windows of about %d %ss.", ...
        numel(edges) - 1, round(nBins / max(numel(edges) - 1, 1)), unit);
end
cfg.data.min_plausible_date = datetime(1900,1,1);
cfg.data.max_plausible_date = dateshift(datetime('today'), 'end', 'year');
end

function n = binCount(t0, t1, unit)
% Number of whole bins in [t0, t1).
switch unit
    case "month"
        n = calmonths(between(t0, t1, 'months'));
    case "week"
        n = floor(days(t1 - t0) / 7);
    case "day"
        n = round(days(t1 - t0));
    case "hour"
        n = round(hours(t1 - t0));
    case "minute"
        n = round(minutes(t1 - t0));
end
end
