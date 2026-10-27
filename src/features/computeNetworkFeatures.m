function F = computeNetworkFeatures(flows, nEnt, cfg)
%COMPUTENETWORKFEATURES Host-level traffic-behaviour features (group "network").
%
%   F = COMPUTENETWORKFEATURES(FLOWS, NENT, CFG) returns one row per host
%   (index-aligned with the entity table, no entity_id column) for the
%   "network" rows of featureRegistry. FLOWS is ds.flows of
%   importNetworkFlows; only src_index, dst_index, time, duration_s, bytes,
%   packets, dport and failed are read. Label columns are deliberately not
%   used: features must not see the ground truth they are evaluated on.
%
%   Outgoing = flows the host initiated (source); incoming = flows it
%   received (destination; self-flows are not counted twice).
%     out_flows, in_flows      counts
%     out_share                out / (out + in)
%     distinct_dst             fan-out: distinct destination hosts
%     distinct_src_in          fan-in: distinct source hosts
%     distinct_dport           distinct destination ports of outgoing flows
%     dport_entropy            Shannon entropy (bits) of those ports
%                              (NaN with < 2 outgoing flows with a port)
%     median_bytes_out         median bytes per outgoing flow
%     median_duration_out      median outgoing duration (s)
%     small_flow_fraction      outgoing flows with <= 2 packets / outgoing
%                              (scans and unanswered attempts are tiny)
%     failed_fraction          failed attempts / outgoing (auth outcome)
%     beacon_cv_min            over destination pairs with >= MINPAIR
%                              (cfg network.beacon_min_flows, default 4)
%                              outgoing flows: the smallest coefficient of
%                              variation of the gaps between flow starts.
%                              Near 0 = clock-like repetition, a classic
%                              command-and-control pattern (NaN otherwise).
%   A feature is NaN when it is undefined (e.g. no outgoing flow, column
%   absent from the dataset) - never 0 - as everywhere in the project.

arguments
    flows table
    nEnt (1,1) double
    cfg struct = struct()
end

minPair = cfgGet(cfg, "network.beacon_min_flows", 4);
s = flows.src_index;
d = flows.dst_index;
selfFlow = s == d;

outF = accumarray(s, 1, [nEnt 1]);
inF = accumarray(d(~selfFlow), 1, [nEnt 1]);
total = outF + inF;
outShare = outF ./ total;
outShare(total == 0) = NaN;

pairs = unique([s d], 'rows');
distinctDst = accumarray(pairs(:,1), 1, [nEnt 1]);
pin = pairs(pairs(:,1) ~= pairs(:,2), :);
distinctSrc = accumarray(pin(:,2), 1, [nEnt 1]);

% Destination ports of outgoing flows.
hasPort = ~isnan(flows.dport);
distinctPort = NaN(nEnt, 1);
entropy = NaN(nEnt, 1);
if any(hasPort)
    sp = [s(hasPort) flows.dport(hasPort)];
    [up, ~, j] = unique(sp, 'rows');
    cnt = accumarray(j, 1);
    distinctPort = accumarray(up(:,1), 1, [nEnt 1]);
    nPort = accumarray(up(:,1), cnt, [nEnt 1]);
    prob = cnt ./ nPort(up(:,1));
    entropy = accumarray(up(:,1), -prob .* log2(prob), [nEnt 1]);
    entropy(nPort < 2) = NaN;
    distinctPort(nPort == 0) = NaN;
end

medBytes = groupMedian(s, flows.bytes, nEnt);
medDur = groupMedian(s, flows.duration_s, nEnt);
small = groupMean(s, double(flows.packets <= 2), ~isnan(flows.packets), nEnt);
failed = groupMean(s, flows.failed, ~isnan(flows.failed), nEnt);
beacon = beaconCv(s, d, flows.time, nEnt, minPair);

noOut = outF == 0;
distinctDst(noOut) = NaN;
distinctPort(noOut) = NaN;

F = table(outF, inF, outShare, distinctDst, distinctSrc, distinctPort, entropy, ...
    medBytes, medDur, small, failed, beacon, 'VariableNames', {'out_flows', 'in_flows', ...
    'out_share', 'distinct_dst', 'distinct_src_in', 'distinct_dport', 'dport_entropy', ...
    'median_bytes_out', 'median_duration_out', 'small_flow_fraction', ...
    'failed_fraction', 'beacon_cv_min'});
end

function m = groupMedian(g, x, n)
m = NaN(n, 1);
ok = ~isnan(x);
if any(ok)
    m = accumarray(g(ok), x(ok), [n 1], @median, NaN);
end
end

function m = groupMean(g, x, ok, n)
m = NaN(n, 1);
if any(ok)
    sums = accumarray(g(ok), x(ok), [n 1]);
    cnt = accumarray(g(ok), 1, [n 1]);
    m = sums ./ cnt;
    m(cnt == 0) = NaN;
end
end

function b = beaconCv(s, d, t, n, minPair)
% Smallest gap CV over (source, destination) pairs with >= minPair flows.
b = NaN(n, 1);
ok = ~isnat(t) & s ~= d;
if ~any(ok)
    return;
end
sec = seconds(t(ok) - min(t(ok)));
M = sortrows([s(ok) d(ok) sec]);
[~, ~, pairId] = unique(M(:, 1:2), 'rows');
gap = diff(M(:,3));
samePair = diff(pairId) == 0;
gap = gap(samePair);
gp = pairId([false; samePair]);
if isempty(gap)
    return;
end
nGap = accumarray(gp, 1);
mu = accumarray(gp, gap) ./ nGap;
sd = sqrt(max(accumarray(gp, gap .^ 2) ./ nGap - mu .^ 2, 0));
cv = sd ./ mu;
valid = nGap + 1 >= minPair & mu > 0;
[~, firstRow] = unique(pairId, 'first');
pairSrc = M(firstRow, 1);
nPairs = numel(nGap);
pairSrc = pairSrc(1:nPairs);
if any(valid)
    b = accumarray(pairSrc(valid), cv(valid), [n 1], @min, NaN);
end
end
