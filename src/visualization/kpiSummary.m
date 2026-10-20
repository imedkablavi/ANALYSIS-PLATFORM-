function kpi = kpiSummary(bundle)
%KPISUMMARY Values, labels and status of the app's KPI tiles.
%
%   KPI = KPISUMMARY(BUNDLE) returns a struct with numeric fields
%     entities         height(bundle.entities)
%     events           height(bundle.crimes) (bundle.events when absent)
%     scored           nnz(entities.eligible)
%     flagged          nnz(iforest_flag | baseline_flag)
%     unusual_months   nnz(is_high | is_low) of temporal.crime_anomalies
%     warnings         numel(validation.warnings)
%   plus quality_status ("good" | "warning" | "critical": invalid ->
%   critical, valid with warnings -> warning, otherwise good) and
%   kpi.tiles, a 1x6 struct array (key, label, value, value_text, detail,
%   status) in display order. Missing bundle parts give NaN / "—" rather
%   than an error, so a partial bundle still renders. Pure function.

e = table();
if isfield(bundle, 'entities')
    e = bundle.entities;
end
kpi.entities = height(e);
if isfield(bundle, 'crimes')
    kpi.events = height(bundle.crimes);
elseif isfield(bundle, 'events')
    kpi.events = height(bundle.events);
else
    kpi.events = NaN;
end
kpi.scored = countIf(e, 'eligible');
if hasVar(e, 'iforest_flag') && hasVar(e, 'baseline_flag')
    kpi.flagged = nnz(e.iforest_flag | e.baseline_flag);
else
    kpi.flagged = NaN;
end
kpi.unusual_months = NaN;
nMonths = NaN;
if isfield(bundle, 'temporal') && isfield(bundle.temporal, 'crime_anomalies')
    a = bundle.temporal.crime_anomalies;
    kpi.unusual_months = nnz(a.is_high | a.is_low);
    nMonths = numel(a.is_high);
end
kpi.warnings = NaN;
kpi.quality_status = "warning";
qualityText = "Not validated";
if isfield(bundle, 'validation')
    v = bundle.validation;
    kpi.warnings = numel(v.warnings);
    if ~v.is_valid
        kpi.quality_status = "critical";
        qualityText = "Invalid";
    elseif kpi.warnings > 0
        kpi.quality_status = "warning";
        qualityText = sprintf("%d warning", kpi.warnings);
        if kpi.warnings > 1
            qualityText = qualityText + "s";
        end
    else
        kpi.quality_status = "good";
        qualityText = "Valid";
    end
end

minEvents = NaN;
if isfield(bundle, 'anomaly') && isfield(bundle.anomaly, 'settings') && ...
        isfield(bundle.anomaly.settings, 'min_events')
    minEvents = bundle.anomaly.settings.min_events;
end
scoredDetail = "";
if ~isnan(minEvents)
    scoredDetail = sprintf("≥ %d events", minEvents);
end
monthsDetail = "";
if ~isnan(nMonths)
    monthsDetail = sprintf("of %d months", nMonths);
end

keys = ["entities", "events", "scored", "flagged", "unusual_months", "quality"];
labels = ["Entities", "Events", "Scored", "Flagged", "Unusual months", "Data quality"];
values = [kpi.entities, kpi.events, kpi.scored, kpi.flagged, kpi.unusual_months, kpi.warnings];
details = ["", "", scoredDetail, "either detector", monthsDetail, "validation checks"];
tiles = struct('key', {}, 'label', {}, 'value', {}, 'value_text', {}, ...
    'detail', {}, 'status', {});
for k = 1:numel(keys)
    tiles(k).key = keys(k);
    tiles(k).label = labels(k);
    tiles(k).value = values(k);
    tiles(k).value_text = formatCount(values(k));
    tiles(k).detail = details(k);
    tiles(k).status = "";
end
tiles(6).value_text = qualityText;
tiles(6).status = kpi.quality_status;
kpi.tiles = tiles;
end

function tf = hasVar(t, name)
tf = istable(t) && ismember(name, t.Properties.VariableNames);
end

function n = countIf(t, name)
if hasVar(t, name)
    n = nnz(t.(name));
else
    n = NaN;
end
end
