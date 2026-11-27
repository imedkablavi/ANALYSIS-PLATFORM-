function crimes = buildCrimeTable(events)
%BUILDCRIMETABLE One row per unique crime with cross-offender consistency flags.
%
%   CRIMES = BUILDCRIMETABLE(EVENTS) groups the offender-crime rows produced
%   by flattenBurglaryEvents by crime_id. Attribute values are taken from
%   the first row of each crime; the *_consistent flags record whether all
%   offenders attached to the crime carry identical values (checked, not
%   assumed; the verified artifact is fully consistent).
%
%   Variables:
%     crime_id, crime_num, event_time, x, y, num_offenders,
%     n_offenders_observed   number of offender rows attached in the file,
%     time_consistent, xy_consistent, num_consistent

if height(events) == 0
    crimes = table(strings(0,1), zeros(0,1), NaT(0,1), zeros(0,1), zeros(0,1), ...
        zeros(0,1), zeros(0,1), false(0,1), false(0,1), false(0,1), ...
        'VariableNames', {'crime_id','crime_num','event_time','x','y', ...
        'num_offenders','n_offenders_observed','time_consistent', ...
        'xy_consistent','num_consistent'});
    return;
end

[g, crimeId] = findgroups(events.crime_id);
[~, first] = unique(g, 'first');

nObs = accumarray(g, 1);
tNum = days(events.event_time - datetime(1970,1,1));   % NaN for NaT

crimes = table(crimeId, events.crime_num(first), events.event_time(first), ...
    events.x(first), events.y(first), events.num_offenders(first), nObs, ...
    groupConstant(g, tNum), ...
    groupConstant(g, events.x) & groupConstant(g, events.y), ...
    groupConstant(g, events.num_offenders), ...
    'VariableNames', {'crime_id','crime_num','event_time','x','y', ...
    'num_offenders','n_offenders_observed','time_consistent', ...
    'xy_consistent','num_consistent'});
crimes = sortrows(crimes, {'event_time','crime_num'});
end

function tf = groupConstant(g, v)
% True when every value in the group is identical (all-NaN counts as constant).
lo = accumarray(g, v, [], @min, NaN);
hi = accumarray(g, v, [], @max, NaN);
nanCount = accumarray(g, double(isnan(v)));
groupSize = accumarray(g, 1);
tf = (lo == hi & nanCount == 0) | nanCount == groupSize;
end
