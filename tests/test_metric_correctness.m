function tests = test_metric_correctness
%TEST_METRIC_CORRECTNESS Regression coverage for tied metrics and empty runs.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testAveragePrecisionGroupsTies(tc)
verifyEqual(tc, averagePrecision(ones(4,1), [1;1;0;0]), 0.5);
verifyEqual(tc, averagePrecision(ones(4,1), [0;0;1;1]), 0.5);
s = [3;2;2;1];
y = [1;1;0;1];
expected = (1 + 2/3 + 3/4) / 3;
verifyEqual(tc, averagePrecision(s, y), expected, 'AbsTol', 1e-12);
order = [4;3;1;2];
verifyEqual(tc, averagePrecision(s(order), y(order)), expected, 'AbsTol', 1e-12);
verifyTrue(tc, isnan(averagePrecision([1;NaN], [0;1])));
end

function testConstantProportionHasSamplingScale(tc)
x = [repmat(0.3,6,1);0.9];
r = detectTemporalAnomalies(x, 6, 6, 3.5, "rolling", ...
    datetime.empty(0,1), 5, 3, "binomial", repmat(250,7,1));
verifyEqual(tc, r.baseline_scale(7), sqrt(0.3*0.7/250), 'AbsTol', 1e-12);
verifyTrue(tc, r.is_high(7));
verifyTrue(tc, r.floor_used(7));
end

function testConstantBoundarySharesStayFinite(tc)
for p = [0 1]
    x = [repmat(p,6,1);1-p];
    r = detectTemporalAnomalies(x, 6, 6, 3.5, "rolling", ...
        datetime.empty(0,1), 5, 3, "binomial", repmat(250,7,1));
    verifyTrue(tc, isfinite(r.robust_z(7)));
    verifyGreaterThan(tc, r.baseline_scale(7), 0);
    verifyTrue(tc, r.is_high(7) || r.is_low(7));
end
end

function testExperimentWithNoEligibleEntities(tc)
cfg = projectConfig();
f = makeSyntheticNetworkJson(tc.TestData.dir);
b = runAnalysisPipeline(cfg, tc.TestData.dir, ...
    struct('data_file', f, 'save', false, 'use_iforest', false));
cfg.anomaly.min_events = 100;
b.anomaly = runAnomalyDetection(b.entities, b.registry, cfg, ...
    cfg.anomaly.feature_groups, struct('use_iforest', false));
b.entities.eligible(:) = false;
b.entities.baseline_score(:) = NaN;
b.entities.iforest_score(:) = NaN;
b.explanations.summary = b.explanations.summary([],:);
out = fullfile(tc.TestData.dir, "empty_experiments");
r = runExperiments(b, cfg, out, struct('quick', true, 'include_synthetic', true));
verifyEqual(tc, height(r.synthetic), 0);
verifyEqual(tc, width(r.synthetic), 8);
noComparison = ismember(r.sensitivity.parameter, ["budget", "min_events"]);
verifyTrue(tc, all(isnan(r.sensitivity.topk_jaccard(noComparison))));
verifyTrue(tc, isfile(fullfile(out, "research_synthetic", "synthetic_E5_E7_injection_raw.csv")));
verifyTrue(tc, isfile(fullfile(out, "experiments_summary.md")));
end

function testDefaultExperimentsDoNotGenerateSyntheticResults(tc)
cfg = projectConfig();
f = makeSyntheticNetworkJson(tc.TestData.dir);
b = runAnalysisPipeline(cfg, tc.TestData.dir, ...
    struct('data_file', f, 'save', false, 'use_iforest', false));
% Older bundles without the opt-in field must also stay on the real-data path.
cfg.evaluation = rmfield(cfg.evaluation, 'include_synthetic');
out = fullfile(tc.TestData.dir, "real_only_experiments");
r = runExperiments(b, cfg, out, struct('quick', true));
verifyEqual(tc, r.synthetic_status, "UNAVAILABLE_NOT_REQUESTED");
budgets = r.sensitivity.parameter == "budget";
verifyTrue(tc, any(budgets));
verifyTrue(tc, all(isnan(r.sensitivity.topk_jaccard(budgets))));
verifyEmpty(tc, r.synthetic);
verifyFalse(tc, isfolder(fullfile(out, "research_synthetic")));
verifyEmpty(tc, dir(fullfile(out, "**", "synthetic_*.csv")));
verifyTrue(tc, isfile(fullfile(out, "E4_ablation_real_ranking_consistency.csv")));
summary = string(fileread(fullfile(out, "experiments_summary.md")));
verifyFalse(tc, contains(summary, "## E5-E7 SYNTHETIC"));
verifyTrue(tc, contains(summary, "unavailable (not requested)"));
% An explicit real-only option overrides an opted-in saved configuration.
cfg.evaluation.include_synthetic = true;
outOverride = fullfile(tc.TestData.dir, "real_only_override");
r = runExperiments(b, cfg, outOverride, struct('quick', true, 'include_synthetic', false));
verifyEqual(tc, r.synthetic_status, "UNAVAILABLE_NOT_REQUESTED");
verifyFalse(tc, isfolder(fullfile(outOverride, "research_synthetic")));
end

function testBaselineOnlyDoesNotReuseSavedForestResults(tc)
assumeFalse(tc, isempty(which('iforest')), "Statistics toolbox is unavailable.");
cfg = projectConfig();
cfg.anomaly.iforest.num_learners = 10;
f = makeSyntheticNetworkJson(tc.TestData.dir);
b = runAnalysisPipeline(cfg, tc.TestData.dir, ...
    struct('data_file', f, 'save', false, 'use_iforest', true));
verifyTrue(tc, any(isfinite(b.entities.iforest_score)));
originalScores = b.entities.iforest_score;
originalModel = b.anomaly.iforest.model;
out = fullfile(tc.TestData.dir, "disable_saved_forest");
r = runExperiments(b, cfg, out, struct('quick', true, 'use_iforest', false));
verifyTrue(tc, all(isnan(r.score_quantiles.iforest_score)));
verifyTrue(tc, all(isnan(r.ablation.iforest_topk_jaccard_vs_full)));
verifyTrue(tc, all(isnan(r.ablation.iforest_spearman_vs_full)));
verifyTrue(tc, all(isnan(r.sensitivity.topk_jaccard(r.sensitivity.parameter == "budget"))));
verifyFalse(tc, any(ismember(r.sensitivity.parameter, ["seed","num_learners","num_obs"])));
verifyEqual(tc, b.entities.iforest_score, originalScores);
verifyEqual(tc, b.anomaly.iforest.model, originalModel);
end
