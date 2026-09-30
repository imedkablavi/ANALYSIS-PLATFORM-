function tests = test_anomaly_and_metrics
%TEST_ANOMALY_AND_METRICS Feature preparation, detectors, budget, explanation, metrics.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
% Synthetic feature table: 300 entities, registry columns ~ N(0,1),
% entity 17 is an extreme outlier in the temporal group only.
reg = featureRegistry();
rng(7, "twister");
n = 300;
X = randn(n, height(reg));
X(:, reg.transform == "log1p") = abs(X(:, reg.transform == "log1p"));
T = array2table(X, 'VariableNames', cellstr(reg.name));
T.event_count = 3 + floor(abs(randn(n, 1)) * 3);
T.event_count(1:10) = 1;                          % ineligible
T.iet_cv(17) = 40;
T.burstiness(17) = -30;
T.peak_window_share(17) = 35;
T.is_cut_vertex = zeros(n, 1);                    % constant -> dropped
T.iet_median_days(20) = NaN;                      % undefined -> imputed
T = addvars(T, "E" + (1:n)', 'Before', 1, 'NewVariableNames', 'entity_id');
tc.TestData.T = T;
tc.TestData.reg = reg;
end

function testPrepareDropsConstantAndImputes(tc)
T = tc.TestData.T;
prep = prepareFeatureMatrix(T, tc.TestData.reg, ["temporal","graph"], true(height(T), 1));
verifyTrue(tc, ismember("is_cut_vertex", prep.dropped));
verifyFalse(tc, ismember("is_cut_vertex", prep.names));
j = find(prep.names == "iet_median_days");
verifyTrue(tc, prep.imputed(20, j));
verifyEqual(tc, prep.Z(20, j), 0);
verifyTrue(tc, all(ismember(prep.groups, ["temporal","graph"])));
verifyEqual(tc, median(prep.Z(:, 1)), 0, 'AbsTol', 1e-12);
end

function testBaselineFindsOutlierAndExplainsIt(tc)
T = tc.TestData.T;
cfg = struct();
cfg.anomaly.min_events = 3;
cfg.anomaly.review_budget_fraction = 0.01;
cfg.anomaly.explain_top_k = 5;
res = runAnomalyDetection(T, tc.TestData.reg, cfg, ["temporal","graph","activity"], ...
    struct('use_iforest', false));
verifyEqual(tc, nnz(res.eligible), nnz(T.event_count >= 3));
verifyTrue(tc, all(isnan(res.baseline.score(~res.eligible))));
verifyEqual(tc, res.baseline.rank(17), 1);
verifyTrue(tc, res.baseline.flag(17));
verifyEqual(tc, nnz(res.baseline.flag), ceil(0.01 * nnz(res.eligible)));
ex = explainAnomalies(res, T, cfg);
verifyEqual(tc, ex.summary.entity_index(1), 17);
verifyEqual(tc, ex.summary.dominant_group(1), "temporal");
verifyTrue(tc, contains(ex.summary.evidence_text(1), "not evidence of guilt"));
e17 = ex.evidence(ex.evidence.entity_index == 17, :);
verifyEqual(tc, sum(e17.baseline_share), 1, 'AbsTol', 1e-12);
verifyTrue(tc, all(e17.notable(ismember(e17.feature, ["iet_cv","burstiness","peak_window_share"]))));
end

function testIsolationForestIfAvailable(tc)
assumeFalse(tc, isempty(which('iforest')), "Statistics and Machine Learning Toolbox iforest not available.");
T = tc.TestData.T;
cfg = struct();
cfg.anomaly.review_budget_fraction = 0.02;
cfg.anomaly.iforest.num_learners = 100;
res1 = runAnomalyDetection(T, tc.TestData.reg, cfg, ["temporal","graph"], struct('seed', 1));
res2 = runAnomalyDetection(T, tc.TestData.reg, cfg, ["temporal","graph"], struct('seed', 1));
verifyEqual(tc, res1.iforest.score, res2.iforest.score);          % reproducible
verifyLessThanOrEqual(tc, res1.iforest.rank(17), 3);
s = res1.iforest.score(res1.eligible);
verifyTrue(tc, all(s >= 0 & s <= 1));
ex = explainAnomalies(res1, T, struct('anomaly', struct('explain_top_k', 3)));
verifyFalse(tc, all(isnan(ex.evidence.occlusion_delta)));
end

function testReviewBudget(tc)
[f, thr, r] = applyReviewBudget([0.1 NaN 0.9 0.5 0.7]', 0.5);
verifyEqual(tc, f', [false false true false true]);
verifyEqual(tc, thr, 0.7);
verifyEqual(tc, r', [4 NaN 1 3 2]);
end

function testMetrics(tc)
verifyEqual(tc, tiedRanks([10 20 20 30])', [1 2.5 2.5 4]);
verifyEqual(tc, rankAuc([0.9 0.8 0.1 0.2], [1 1 0 0]), 1);
verifyEqual(tc, rankAuc([0.1 0.2 0.9 0.8], [1 1 0 0]), 0);
verifyEqual(tc, rankAuc([1 1 1 1], [1 0 1 0]), 0.5);
verifyEqual(tc, averagePrecision([0.9 0.8 0.7 0.6], [1 0 1 0]), (1 + 2/3) / 2, 'AbsTol', 1e-12);
[p, r] = precisionAtK([0.9 0.8 0.7 0.6], [1 0 1 0], 2);
verifyEqual(tc, [p r], [0.5 0.5]);
verifyEqual(tc, topKJaccard([4 3 2 1], [4 3 1 2], 2), 1);
verifyEqual(tc, topKJaccard([4 3 2 1], [1 2 3 4], 2), 0);
verifyEqual(tc, spearmanRho([1 2 3 4], [10 20 30 40]), 1, 'AbsTol', 1e-12);
verifyEqual(tc, spearmanRho([1 2 3 4], [4 3 2 1]), -1, 'AbsTol', 1e-12);
verifyEqual(tc, empiricalQuantile([1 2 3 4 NaN], [0 0.5 1]), [1 2.5 4]);
end

function testSyntheticInjection(tc)
Z = zeros(200, 4);
Z(:, 1) = 1;
groups = ["temporal","temporal","graph","graph"];
[Zi, lab, rows] = injectSyntheticAnomalies(Z, groups, "temporal", 0.05, 5, 3);
verifyEqual(tc, nnz(lab), 10);
verifyEqual(tc, find(lab), rows);
verifyEqual(tc, Zi(rows, 1), 6 * ones(10, 1));        % pushed along its sign
verifyEqual(tc, abs(Zi(rows, 2)), 5 * ones(10, 1));   % zero -> random sign
verifyEqual(tc, Zi(:, 3:4), Z(:, 3:4));                % other groups untouched
verifyEqual(tc, Zi(~lab, :), Z(~lab, :));
[Zi2, lab2] = injectSyntheticAnomalies(Z, groups, "temporal", 0.05, 5, 3);
verifyEqual(tc, Zi2, Zi);
verifyEqual(tc, lab2, lab);
end
