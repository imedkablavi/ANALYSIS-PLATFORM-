function [relations, pairEvents] = buildRelationTable(events, entityIds)
%BUILDRELATIONTABLE Derive time-stamped undirected co-offending relations.
%
%   [RELATIONS, PAIREVENTS] = BUILDRELATIONTABLE(EVENTS, ENTITYIDS)
%
%   Verified property of the artifact (docs/DATASET_SCHEMA_INSPECTION.md):
%   every JSON link is present in both directions and its weight equals the
%   number of crimes shared by the two offenders. The offender network is
%   therefore the one-mode projection of the offender-crime bipartite graph,
%   and it can be rebuilt from EVENTS with timestamps attached. That is what
%   enables dynamic-graph analysis and temporal playback.
%
%   PAIREVENTS has one row per (offender pair, shared crime):
%     a_index, b_index (a_index < b_index), crime_id, event_time
%
%   RELATIONS has one row per undirected offender pair:
%     a_index, b_index, a_id, b_id,
%     weight        number of shared crimes (derived),
%     first_time    earliest shared crime date,
%     last_time     latest shared crime date,
%     span_days     last_time - first_time in days
%
%   Complexity: sum over crimes of k*(k-1)/2 pairs (k = offenders per crime);
%   about 15k pair rows for the verified artifact.

arguments
    events table
    entityIds (:,1) string
end

pairEvents = table(zeros(0,1), zeros(0,1), strings(0,1), NaT(0,1), ...
    'VariableNames', {'a_index','b_index','crime_id','event_time'});
emptyRel = table(zeros(0,1), zeros(0,1), strings(0,1), strings(0,1), ...
    zeros(0,1), NaT(0,1), NaT(0,1), zeros(0,1), 'VariableNames', ...
    {'a_index','b_index','a_id','b_id','weight','first_time','last_time','span_days'});

if height(events) == 0
    relations = emptyRel;
    return;
end

% Unique (crime, entity) rows only: duplicate association rows must not
% inflate the pair weight (duplicates are reported by validation).
[~, keep] = unique(findgroups(events.crime_id, events.entity_index), 'stable');
ev = events(keep, :);

[g, crimeIds] = findgroups(ev.crime_id);
groupSize = accumarray(g, 1);
[~, order] = sortrows([g ev.entity_index]);
ev = ev(order, :);
g = g(order);
firstRow = cumsum([1; groupSize(1:end-1)]);
crimeTime = ev.event_time(firstRow);

A = {}; B = {}; C = {}; T = {};
for k = 2:max(groupSize)
    gk = find(groupSize == k);
    if isempty(gk)
        continue;
    end
    % Members matrix: one row per crime of size k, sorted entity indices.
    members = ev.entity_index(firstRow(gk) + (0:k-1));
    members = reshape(members, numel(gk), k);
    combos = nchoosek(1:k, 2);
    for c = 1:size(combos,1)
        A{end+1,1} = members(:, combos(c,1)); %#ok<AGROW>
        B{end+1,1} = members(:, combos(c,2)); %#ok<AGROW>
        C{end+1,1} = crimeIds(gk);            %#ok<AGROW>
        T{end+1,1} = crimeTime(gk);           %#ok<AGROW>
    end
end

if isempty(A)
    relations = emptyRel;
    return;
end

pairEvents = table(vertcat(A{:}), vertcat(B{:}), vertcat(C{:}), vertcat(T{:}), ...
    'VariableNames', {'a_index','b_index','crime_id','event_time'});
pairEvents = sortrows(pairEvents, {'event_time','a_index','b_index'});

[gp, aIdx, bIdx] = findgroups(pairEvents.a_index, pairEvents.b_index);
weight = accumarray(gp, 1);
tNum = days(pairEvents.event_time - datetime(1970,1,1));
firstT = datetime(1970,1,1) + days(accumarray(gp, tNum, [], @min, NaN));
lastT = datetime(1970,1,1) + days(accumarray(gp, tNum, [], @max, NaN));

relations = table(aIdx, bIdx, entityIds(aIdx), entityIds(bIdx), weight, ...
    firstT, lastT, days(lastT - firstT), 'VariableNames', ...
    {'a_index','b_index','a_id','b_id','weight','first_time','last_time','span_days'});
end
