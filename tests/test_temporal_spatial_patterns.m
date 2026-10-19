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

function testSeasonalBaselineIgnoresNormalSeasonalPeaks(tc)
% Every July is a normal seasonal peak (20 vs 10); July 2017 carries an
% injected spike. With >= 3 prior Julys, a normal July must score ~0 while
% the spike is flagged. July 2016 has only 2 prior Julys: it is UNSCORED
% (NaN), which is different from "scored as normal".
months = datetime(2014,1,1) + calmonths(0:59)';
x = 10 * ones(60,1);
x(month(months) == 7) = 20;
x(43) = 50;  % July 2017
r = detectTemporalAnomalies(x, 12, 6, 3.5, "seasonal_same_month", months, 5, 3);
verifyTrue(tc, isnan(r.robust_z(31)));          % July 2016: insufficient history
verifyEqual(tc, r.baseline_count(31), 2);
verifyTrue(tc, r.is_high(43));                  % July 2017 spike
verifyEqual(tc, r.baseline_median(43), 20);
verifyEqual(tc, r.baseline_count(43), 3);
verifyFalse(tc, r.is_high(55) || r.is_low(55)); % July 2018: normal peak, scored
verifyEqual(tc, r.robust_z(55), 0);
% The rolling 12-month baseline (no seasonal term) flags the normal July
% 2016 peak: its window holds 11 ordinary months and one July, so z ~ 9.6.
rr = detectTemporalAnomalies(x, 12, 6, 3.5);
verifyTrue(tc, rr.is_high(31));
end

function testPoissonScaleFloorForCounts(tc)
% Monthly counts near 260 whose three same-month references happen to be
% almost identical: the robust scale (1.4826 * MAD = 1.48) is far below
% counting noise (sqrt(260) ~ 16.1), so +15 crimes would look extreme.
months = datetime(2014,1,1) + calmonths(0:47)';
x = repmat(260, 48, 1);
x(month(months) == 3) = [259; 260; 261; 275];   % March 2014-2017
r0 = detectTemporalAnomalies(x, 12, 6, 3.5, "seasonal_same_month", months, 5, 3, false);
r1 = detectTemporalAnomalies(x, 12, 6, 3.5, "seasonal_same_month", months, 5, 3, true);
k = find(months == datetime(2017,3,1));
verifyTrue(tc, r0.is_high(k));                  % unfloored: spurious flag
verifyFalse(tc, r1.is_high(k));                 % floored: within counting noise
verifyEqual(tc, r1.baseline_scale(k), sqrt(260), 'AbsTol', 1e-12);
verifyTrue(tc, r1.poisson_floor_used(k));
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
