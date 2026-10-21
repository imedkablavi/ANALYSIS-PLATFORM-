function snap = buildGraphSnapshot(pairEvents, t0, t1)
%BUILDGRAPHSNAPSHOT Co-offending edges active in the half-open window [t0, t1).
%
%   SNAP = BUILDGRAPHSNAPSHOT(PAIREVENTS, T0, T1) aggregates the
%   (pair, shared crime) rows from buildRelationTable that fall inside the
%   window. SNAP is a table: a_index, b_index, weight (shared crimes inside
%   the window), first_time, last_time. Used for dynamic-graph statistics
%   and for temporal playback in the application.

arguments
    pairEvents table
    t0 (1,1) datetime
    t1 (1,1) datetime
end

in = pairEvents.event_time >= t0 & pairEvents.event_time < t1;
pe = pairEvents(in, :);
if height(pe) == 0
    snap = table(zeros(0,1), zeros(0,1), zeros(0,1), NaT(0,1), NaT(0,1), ...
        'VariableNames', {'a_index','b_index','weight','first_time','last_time'});
    return;
end
[g, a, b] = findgroups(pe.a_index, pe.b_index);
tNum = days(pe.event_time - datetime(1970,1,1));
snap = table(a, b, accumarray(g, 1), ...
    datetime(1970,1,1) + days(accumarray(g, tNum, [], @min)), ...
    datetime(1970,1,1) + days(accumarray(g, tNum, [], @max)), ...
    'VariableNames', {'a_index','b_index','weight','first_time','last_time'});
end
