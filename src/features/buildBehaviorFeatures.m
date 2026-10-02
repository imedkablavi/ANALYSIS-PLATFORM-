function features = buildBehaviorFeatures(events, entityIds, relations, cfg)
%BUILDBEHAVIORFEATURES Entity-level activity, temporal, spatial and co-offending features.
%
%   FEATURES = BUILDBEHAVIORFEATURES(EVENTS, ENTITYIDS, RELATIONS, CFG)
%
%   EVENTS     table from flattenBurglaryEvents (needs entity_index,
%              crime_id, crime_num, x, y, event_time, num_offenders)
%   ENTITYIDS  string column of all entity IDs (defines row order)
%   RELATIONS  table from buildRelationTable (a_index, b_index, weight)
%   CFG        projectConfig() or struct() for defaults
%
%   Returns one row per entity (including entities with few events). A
%   feature that is undefined for an entity (e.g. inter-event statistics
%   with fewer than 3 events) is NaN, never 0: "insufficient history" must
%   not be confused with "normal behaviour". Definitions: featureRegistry
%   and docs/FEATURE_ENGINEERING.md. These features describe observable
%   records only; they are not risk or criminality scores.
%
%   Complexity: O(E log E + N). Events are sorted once and each entity's
%   rows are addressed by a contiguous range (the previous implementation
%   compared every event ID against every entity ID, O(N*E)).

arguments
    events table
    entityIds (:,1) string
    relations table
    cfg struct = struct()
end

burstWindow = cfgGet(cfg, "temporal.burst_window_days", 30);
n = numel(entityIds);

% Deduplicated, deterministically ordered events (see canonicalEvents).
ev = canonicalEvents(events);

idx = ev.entity_index;
tDays = days(ev.event_time - datetime(1970,1,1));   % NaN for NaT
x = ev.x;
y = ev.y;
grp = ev.num_offenders;

counts = accumarray(idx, 1, [n 1]);
rowEnd = cumsum(counts);
rowStart = rowEnd - counts + 1;

F = NaN(n, 16);
% Column map (kept local; names assigned at the end)
C_COUNT = 1; C_SPAN = 2; C_DAYS = 3; C_IETMED = 4; C_IETCV = 5; C_BURST = 6;
C_MAXGAP = 7; C_PEAK = 8; C_SAMEDAY = 9; C_RG = 10; C_STEPMEAN = 11;
C_STEPMAX = 12; C_REPEATLOC = 13; C_GMEAN = 14; C_SOLO = 15; C_GMAX = 16;

for i = 1:n
    k = counts(i);
    F(i, C_COUNT) = k;
    if k == 0
        continue;
    end
    r = rowStart(i):rowEnd(i);

    % --- activity / temporal ---
    t = tDays(r);
    t = t(~isnan(t));
    if ~isempty(t)
        F(i, C_SPAN) = t(end) - t(1);
        ud = unique(floor(t));
        F(i, C_DAYS) = numel(ud);
        if k >= 2
            F(i, C_SAMEDAY) = 1 - numel(ud) / numel(t);
        end
        if numel(t) >= 3
            gaps = diff(t);
            mu = mean(gaps);
            sd = std(gaps);
            medGap = median(gaps);
            F(i, C_IETMED) = medGap;
            if mu > 0
                F(i, C_IETCV) = sd / mu;
            end
            if (sd + mu) > 0
                F(i, C_BURST) = (sd - mu) / (sd + mu);
            end
            F(i, C_MAXGAP) = max(gaps) / max(medGap, 1);
            % busiest window [t_j, t_j + W); O(k^2) but k <= 40 in the artifact
            upper = arrayfun(@(tj) find(t < tj + burstWindow, 1, 'last'), t);
            F(i, C_PEAK) = max(upper - (1:numel(t))' + 1) / numel(t);
        end
    end

    % --- spatial (normalized coordinates) ---
    xy = [x(r) y(r)];
    xy = xy(all(isfinite(xy), 2), :);
    if size(xy,1) >= 2
        centroid = mean(xy, 1);
        F(i, C_RG) = sqrt(mean(sum((xy - centroid).^2, 2)));
        steps = sqrt(sum(diff(xy, 1, 1).^2, 2));
        F(i, C_STEPMEAN) = mean(steps);
        F(i, C_STEPMAX) = max(steps);
        F(i, C_REPEATLOC) = 1 - size(unique(xy, 'rows'), 1) / size(xy, 1);
    end

    % --- co-offending ---
    gs = grp(r);
    gs = gs(isfinite(gs));
    if ~isempty(gs)
        F(i, C_GMEAN) = mean(gs);
        F(i, C_SOLO) = mean(gs == 1);
        F(i, C_GMAX) = max(gs);
    end
end

% Repeat-partner fraction from the relation table (vectorized).
repeatFrac = zeros(n,1);
if height(relations) > 0
    ends = [relations.a_index; relations.b_index];
    w = [relations.weight; relations.weight];
    partners = accumarray(ends, 1, [n 1]);
    repeats = accumarray(ends, double(w >= 2), [n 1]);
    has = partners > 0;
    repeatFrac(has) = repeats(has) ./ partners(has);
end
repeatFrac(counts == 0) = NaN;

features = table(entityIds, F(:,C_COUNT), F(:,C_SPAN), F(:,C_DAYS), ...
    F(:,C_IETMED), F(:,C_IETCV), F(:,C_BURST), F(:,C_MAXGAP), F(:,C_PEAK), ...
    F(:,C_SAMEDAY), F(:,C_RG), F(:,C_STEPMEAN), F(:,C_STEPMAX), ...
    F(:,C_REPEATLOC), F(:,C_GMEAN), F(:,C_SOLO), F(:,C_GMAX), repeatFrac, ...
    'VariableNames', {'entity_id','event_count','active_span_days', ...
    'active_day_count','iet_median_days','iet_cv','burstiness', ...
    'max_gap_ratio','peak_window_share','same_day_fraction', ...
    'radius_of_gyration','mean_step_distance','max_step_distance', ...
    'location_repeat_fraction','mean_group_size','solo_fraction', ...
    'max_group_size','repeat_partner_fraction'});
end
