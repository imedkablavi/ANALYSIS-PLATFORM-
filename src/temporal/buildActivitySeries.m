function series = buildActivitySeries(events, crimes, t0, t1, binUnit)
%BUILDACTIVITYSERIES System-level activity time series.
%
%   SERIES = BUILDACTIVITYSERIES(EVENTS, CRIMES, T0, T1, BINUNIT) with
%   BINUNIT "month", "week", "day", "hour" or "minute" (binStep); only data in [T0, T1) are counted (T1 exclusive);
%   bins are calendar bins, so the first/last bin is partial if T0/T1 is mid-bin.
%   One row per bin:
%     bin_start
%     crimes              unique crimes in the bin
%     active_offenders    distinct offenders with a crime in the bin
%     new_offenders       offenders whose first-ever crime is in the bin
%     cooffending_share   share of crimes with num_of_offenders >= 2
%     mean_group_size     mean num_of_offenders of the bin's crimes

arguments
    events table
    crimes table
    t0 (1,1) datetime
    t1 (1,1) datetime
    binUnit (1,1) string {mustBeMember(binUnit, ["month","week","day","hour","minute"])} = "month"
end

step = binStep(binUnit);
edges = (dateshift(t0, 'start', binUnit):step:t1)';
if edges(end) < t1
    edges(end+1) = edges(end) + step;
end
nB = numel(edges) - 1;

% Bins are calendar bins, but only data inside [t0, t1) are counted: when t0
% or t1 is not on a bin boundary the first/last bin is partial rather than
% silently extended (discretize also closes the last bin on the right).
cb = discretize(crimes.event_time, edges);
cb(crimes.event_time < t0 | crimes.event_time >= t1) = NaN;
okC = ~isnan(cb);
nCrimes = accumarray(cb(okC), 1, [nB 1]);
multi = accumarray(cb(okC), double(crimes.num_offenders(okC) >= 2), [nB 1]);
gsum = accumarray(cb(okC), crimes.num_offenders(okC), [nB 1]);

eb = discretize(events.event_time, edges);
eb(events.event_time < t0 | events.event_time >= t1) = NaN;
okE = ~isnan(eb);
pairKey = unique([eb(okE) events.entity_index(okE)], 'rows');
active = accumarray(pairKey(:,1), 1, [nB 1]);

% first appearance uses the full history, including events before t0
valid = ~ismissing(events.event_time);
firstT = accumarray(events.entity_index(valid), ...
    days(events.event_time(valid) - datetime(1970,1,1)), [], @min, NaN);
firstT = firstT(~isnan(firstT));
firstDate = datetime(1970,1,1) + days(firstT);
fb = discretize(firstDate, edges);
fb(firstDate < t0 | firstDate >= t1) = NaN;
newOff = accumarray(fb(~isnan(fb)), 1, [nB 1]);

share = multi ./ nCrimes;
meanG = gsum ./ nCrimes;
share(nCrimes == 0) = NaN;
meanG(nCrimes == 0) = NaN;

series = table(edges(1:nB), nCrimes, active, newOff, share, meanG, ...
    'VariableNames', {'bin_start','crimes','active_offenders', ...
    'new_offenders','cooffending_share','mean_group_size'});
end
