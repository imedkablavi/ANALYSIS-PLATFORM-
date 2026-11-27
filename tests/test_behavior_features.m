function tests = test_behavior_features
%TEST_BEHAVIOR_FEATURES Hand-computed feature values on the synthetic fixture.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
events = flattenBurglaryEvents(data);
rel = buildRelationTable(events, data.nodes.entity_id);
tc.TestData.f = buildBehaviorFeatures(events, data.nodes.entity_id, rel, struct());
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testOneRowPerEntity(tc)
f = tc.TestData.f;
verifyEqual(tc, height(f), 7);
verifyEqual(tc, f.event_count', [4 2 3 2 2 3 1]);
end

function testTemporalFeaturesEntity1(tc)
f = tc.TestData.f(1, :);             % gaps 10, 30, 30 days
verifyEqual(tc, f.active_span_days, 70);
verifyEqual(tc, f.active_day_count, 4);
verifyEqual(tc, f.iet_median_days, 30);
verifyEqual(tc, f.iet_cv, 0.4948716593053935, 'AbsTol', 1e-12);
verifyEqual(tc, f.burstiness, -0.3379074969749037, 'AbsTol', 1e-12);
verifyEqual(tc, f.max_gap_ratio, 1);
verifyEqual(tc, f.peak_window_share, 0.5);
verifyEqual(tc, f.same_day_fraction, 0);
end

function testTemporalFeaturesEntity6(tc)
f = tc.TestData.f(6, :);             % gaps 0 (same day), 30
verifyEqual(tc, f.same_day_fraction, 1/3, 'AbsTol', 1e-12);
verifyEqual(tc, f.burstiness, 0.17157287525380993, 'AbsTol', 1e-12);
verifyEqual(tc, f.max_gap_ratio, 2);
verifyEqual(tc, f.peak_window_share, 2/3, 'AbsTol', 1e-12);   % [06-01, 07-01) holds 2 of 3
verifyEqual(tc, f.location_repeat_fraction, 1/3, 'AbsTol', 1e-12);
end

function testUndefinedFeaturesAreNaN(tc)
f = tc.TestData.f;
% entity 7 has one crime; entities 2, 4, 5 have two (only one gap)
verifyTrue(tc, all(isnan([f.iet_median_days([2 4 5 7]); f.burstiness([2 4 5 7])])));
verifyTrue(tc, isnan(f.radius_of_gyration(7)));
verifyEqual(tc, f.active_span_days(7), 0);
end

function testSpatialFeaturesEntity1(tc)
f = tc.TestData.f(1, :);
verifyEqual(tc, f.radius_of_gyration, 0.4659130820228168, 'AbsTol', 1e-12);
verifyEqual(tc, f.mean_step_distance, 0.3791366646381957, 'AbsTol', 1e-12);
verifyEqual(tc, f.max_step_distance, 0.565685424949238, 'AbsTol', 1e-12);
verifyEqual(tc, f.location_repeat_fraction, 0);
end

function testCooffendingFeatures(tc)
f = tc.TestData.f;
verifyEqual(tc, f.mean_group_size(1), 1.75);
verifyEqual(tc, f.solo_fraction(1), 0.25);
verifyEqual(tc, f.max_group_size(1), 2);
verifyEqual(tc, f.repeat_partner_fraction(1), 0.5);   % partner 2 (w2), partner 3 (w1)
verifyEqual(tc, f.repeat_partner_fraction(6), 0);     % no partners
verifyEqual(tc, f.solo_fraction(6), 1);
end

function testRegistryCoversFeatureColumns(tc)
reg = featureRegistry();
f = tc.TestData.f;
behaviourCols = setdiff(string(f.Properties.VariableNames), "entity_id");
verifyTrue(tc, all(ismember(behaviourCols, reg.name)));
verifyEqual(tc, numel(unique(reg.name)), height(reg));
verifyTrue(tc, all(ismember(reg.transform, ["none","log1p"])));
end

function testMergeRejectsMisalignment(tc)
f = tc.TestData.f;
bad = table((1:3)', 'VariableNames', {'z'});
verifyError(tc, @() mergeFeatureTables(f, bad), "MOSAIC:MergeAlignment");
dup = table(f.entity_id, f.event_count, 'VariableNames', {'entity_id','event_count'});
verifyError(tc, @() mergeFeatureTables(f, dup), "MOSAIC:MergeClash");
end
