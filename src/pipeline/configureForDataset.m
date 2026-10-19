function [cfg, notes] = configureForDataset(cfg, ds)
%CONFIGUREFORDATASET Adapt time windows and bins to the dataset being analysed.
%
%   [CFG, NOTES] = CONFIGUREFORDATASET(CFG, DS) leaves CFG unchanged for the
%   verified primary artifact (its windows are documented decisions, see
%   docs/TEMPORAL_ANALYSIS.md). For any other dataset the hard-coded
%   2014-2020 windows would be meaningless, so they are derived from the data:
%     series_start   first day of the month of the earliest event
%     series_end     first day of the month of the latest event (EXCLUSIVE:
%                    the last, usually partial, month is left out)
%     bin            "month"; "week" when the span is < 24 months
%                    (a monthly series would be too short for baselines)
%     anomaly_method "seasonal_same_month" only with monthly bins and
%                    >= 4 calendar years (3 prior years are needed to score
%                    a month); otherwise "rolling"
%     snapshot_years calendar years covered
%     plausible dates 1900-01-01 .. end of the current year
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
t0 = dateshift(min(t), 'start', 'month');
t1 = dateshift(max(t), 'start', 'month');
spanMonths = calmonths(between(t0, t1, 'months'));
if spanMonths < 1
    t1 = t0 + calmonths(1);
    spanMonths = 1;
    notes(end+1,1) = "All events fall in one month: the series covers that (possibly partial) month.";
end

cfg.temporal.series_start = t0;
cfg.temporal.series_end = t1;
notes(end+1,1) = sprintf("Temporal series %s to %s (exclusive; last partial month left out).", ...
    string(t0, 'yyyy-MM-dd'), string(t1, 'yyyy-MM-dd'));

if spanMonths < 24
    cfg.temporal.bin = "week";
    cfg.temporal.anomaly_method = "rolling";
    notes(end+1,1) = sprintf("Span %d months < 24: weekly bins, rolling baseline of %d weeks.", ...
        spanMonths, cfg.temporal.baseline_window);
elseif year(t1) - year(t0) < 4
    cfg.temporal.bin = "month";
    cfg.temporal.anomaly_method = "rolling";
    notes(end+1,1) = "Fewer than 4 calendar years: rolling baseline (seasonal needs 3 prior years).";
else
    cfg.temporal.bin = "month";
    notes(end+1,1) = "Monthly bins; configured temporal method kept (" + cfg.temporal.anomaly_method + ").";
end

cfg.temporal.snapshot_years = year(t0):year(max(t));
cfg.data.min_plausible_date = datetime(1900,1,1);
cfg.data.max_plausible_date = dateshift(datetime('today'), 'end', 'year');
notes(end+1,1) = "Dynamic-graph windows: calendar years " + year(t0) + "-" + year(max(t)) + ".";
end
