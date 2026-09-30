function stats = computeDynamicGraphStats(pairEvents, events, windowStarts)
%COMPUTEDYNAMICGRAPHSTATS Evolution of the co-offending network across time windows.
%
%   STATS = COMPUTEDYNAMICGRAPHSTATS(PAIREVENTS, EVENTS, WINDOWSTARTS)
%   WINDOWSTARTS is a sorted datetime vector; window w is
%   [WINDOWSTARTS(w), WINDOWSTARTS(w+1)) and the last start only closes the
%   previous window (e.g. yearly: datetime(2014:2021,1,1)).
%
%   One row per window:
%     window_start, window_end
%     active_offenders    offenders with >= 1 crime in the window
%     edges               co-offending pairs active in the window
%     new_edges           pairs whose first-ever shared crime is in the window
%     persistent_edges    pairs active in this and the previous window
%     edge_persistence    persistent_edges / edges of previous window
%     edge_jaccard        |E_w & E_w-1| / |E_w | E_w-1|
%     components          connected components among offenders with edges
%     largest_component   offenders in the largest component
%     mean_degree         2*edges / offenders with edges

arguments
    pairEvents table
    events table
    windowStarts (:,1) datetime
end

nW = numel(windowStarts) - 1;
key = pairEvents.a_index * 1e6 + pairEvents.b_index;   % entity indices < 1e6
[uKey, firstRow] = unique(key, 'first');   % pairEvents is sorted by time
firstSeen = pairEvents.event_time(firstRow);

vars = zeros(nW, 9);
prevKeys = zeros(0,1);
for w = 1:nW
    t0 = windowStarts(w);
    t1 = windowStarts(w+1);
    inW = pairEvents.event_time >= t0 & pairEvents.event_time < t1;
    keys = unique(key(inW));
    evIn = events.event_time >= t0 & events.event_time < t1;
    activeOff = numel(unique(events.entity_index(evIn)));

    newEdges = sum(ismember(keys, uKey(firstSeen >= t0 & firstSeen < t1)));
    persistentE = sum(ismember(keys, prevKeys));
    if isempty(prevKeys)
        persistence = NaN;
        jac = NaN;
    else
        persistence = persistentE / numel(prevKeys);
        jac = persistentE / numel(union(keys, prevKeys));
    end

    comps = 0; largest = 0; meanDeg = 0;
    if ~isempty(keys)
        a = floor(keys / 1e6);
        b = keys - a * 1e6;
        [nodesW, ~, loc] = unique([a; b]);
        m = numel(keys);
        Gw = graph(loc(1:m), loc(m+1:end), 1, numel(nodesW));
        bins = conncomp(Gw);
        sizes = accumarray(bins(:), 1);
        comps = numel(sizes);
        largest = max(sizes);
        meanDeg = 2 * m / numel(nodesW);
    end
    vars(w,:) = [activeOff, numel(keys), newEdges, persistentE, persistence, ...
        jac, comps, largest, meanDeg];
    prevKeys = keys;
end

stats = array2table(vars, 'VariableNames', {'active_offenders','edges', ...
    'new_edges','persistent_edges','edge_persistence','edge_jaccard', ...
    'components','largest_component','mean_degree'});
stats = addvars(stats, windowStarts(1:nW), windowStarts(2:nW+1), ...
    'Before', 1, 'NewVariableNames', {'window_start','window_end'});
end
