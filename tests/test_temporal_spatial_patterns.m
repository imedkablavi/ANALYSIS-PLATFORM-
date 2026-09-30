function tests = test_temporal_spatial_patterns
%TEST_TEMPORAL_SPATIAL_PATTERNS Temporal baselines, change points, hotspots, patterns.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
tc.TestData.events = flattenBurglaryEvents(data);
tc.TestData.crimes = buildCrimeTable(tc.TestData.events);
tc.TestData.rel = buildRelationTable(tc.TestData.events, data.nodes.entity_id);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testRobustScaleFallbacks(tc)
[c, s, m] = robustCenterScale([1 2 3 4 5]);
verifyEqual(tc, [c s], [3 1.4826]);
verifyEqual(tc, m, "MAD");
[~, s, m] = robustCenterScale([5 5 5 9]);
verifyEqual(tc, s, 1.2533);
verifyEqual(tc, m, "meanAD");
[~, s, m] = robustCenterScale([5 5 5 5]);
verifyEqual(tc, s, 1);
verifyEqual(tc, m, "constant");
end

function testCausalSpikeDetection(tc)
x = [10 10 11 9 10 10 10 11 9 10 40 10]';
r = detectTemporalAnomalies(x, 12, 6, 3.5);
verifyTrue(tc, all(isnan(r.robust_z(1:6))));
verifyTrue(tc, r.is_high(11));
verifyEqual(tc, nnz(r.is_high | r.is_low), 1);
% causal: the spike does not change the baseline of its own bin
verifyEqual(tc, r.baseline_median(11), 10);
end

function testChangePoint(tc)
noise = repmat([0 1 -1]', 8, 1);
x = [10 * ones(12,1); 30 * ones(12,1)] + noise;
cp = detectChangePoints(x, 4, 3);
verifyEqual(tc, height(cp), 1);
verifyEqual(tc, cp.index, 13);
verifyEqual(tc, cp.mean_before, mean(x(1:12)), 'AbsTol', 1e-12);
verifyEmpty(tc, detectChangePoints(10 + noise, 4, 3));
end

function testActivitySeries(tc)
s = buildActivitySeries(tc.TestData.events, tc.TestData.crimes, ...
    datetime(2015,1,1), datetime(2015,4,1), "month");
verifyEqual(tc, height(s), 3);
verifyEqual(tc, s.crimes', [3 2 1]);
verifyEqual(tc, s.new_offenders', [5 0 0]);
verifyEqual(tc, s.active_offenders', [5 4 1]);
verifyEqual(tc, s.cooffending_share(3), 0);
end

function testHotspotsNormalizedGrid(tc)
hs = computeSpatialHotspots(tc.TestData.crimes, 10, (2015:2017)', 0.05);
verifyEqual(tc, sum(hs.grid, 'all'), 10);
verifyEqual(tc, height(hs.cells), 100);
verifyTrue(tc, all(hs.spaceTime.p_value >= 0 & hs.spaceTime.p_value <= 1));
verifyEqual(tc, sum(hs.spaceTime.crimes), 10);
% P(X >= k) for Poisson via gammainc: k = 1 -> 1 - exp(-lambda)
verifyEqual(tc, gammainc(0.5, 1), 1 - exp(-0.5), 'AbsTol', 1e-12);
end

function testCooffendingPatterns(tc)
p = mineCooffendingPatterns(tc.TestData.events, tc.TestData.rel, 2);
verifyEqual(tc, height(p.pairs), 4);             % all ties except 1-3
verifyEqual(tc, height(p.groups), 1);            % {3,4,5} twice
verifyEqual(tc, p.groups.group_key, "3-4-5");
verifyEqual(tc, p.groups.crimes, 2);
verifyEqual(tc, p.groups.first_time, datetime(2015,1,5));
end
