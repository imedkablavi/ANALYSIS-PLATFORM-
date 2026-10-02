function res = runAnomalyDetection(features, registry, cfg, groups, opts)
%RUNANOMALYDETECTION Baseline + Isolation Forest on one feature-group set.
%
%   RES = RUNANOMALYDETECTION(FEATURES, REGISTRY, CFG) uses
%   cfg.anomaly.feature_groups; RES = RUNANOMALYDETECTION(..., GROUPS)
%   overrides the groups (ablation). OPTS (struct, optional):
%     use_iforest   default true (false = baseline only, e.g. no toolbox)
%     seed          default cfg.analysis.random_seed
%     num_learners, num_obs, min_events, budget   override cfg values
%
%   Protocol (docs/ANOMALY_DETECTION.md):
%   1. Eligibility: event_count >= min_events (default 3). Entities below
%      it have too little history for temporal/sequence features and are
%      reported as "insufficient history", never as "normal".
%   2. The reference population for scaling = all eligible entities
%      (unsupervised, transductive setting: no labels exist).
%   3. Baseline score (scoreRobustBaseline) and Isolation Forest score are
%      computed on the SAME prepared matrix.
%   4. Both are thresholded with the same review budget (top fraction).
%   5. Agreement between the two rankings is reported (Spearman, top-k
%      Jaccard): agreement is evidence of robustness, disagreement is a
%      finding to inspect, neither is "accuracy".
%
%   RES fields: groups, eligible (N x 1), prep, baseline (struct with
%   full-length score/rank/flag/threshold/contrib), iforest (same + model),
%   agreement, settings.

arguments
    features table
    registry table
    cfg struct
    groups (1,:) string = cfgGet(cfg, "anomaly.feature_groups", ...
        ["activity","temporal","spatial","cooffending","graph","sequence"])
    opts struct = struct()
end

seed = optOr(opts, "seed", cfgGet(cfg, "analysis.random_seed", 42));
numLearners = optOr(opts, "num_learners", cfgGet(cfg, "anomaly.iforest.num_learners", 200));
numObs = optOr(opts, "num_obs", cfgGet(cfg, "anomaly.iforest.num_observations_per_learner", 256));
minEvents = optOr(opts, "min_events", cfgGet(cfg, "anomaly.min_events", 3));
budget = optOr(opts, "budget", cfgGet(cfg, "anomaly.review_budget_fraction", 0.01));
useIF = optOr(opts, "use_iforest", true);

N = height(features);
eligible = features.event_count >= minEvents;
prep = prepareFeatureMatrix(features(eligible, :), registry, groups, true(nnz(eligible), 1));

res.groups = groups;
res.eligible = eligible;
res.prep = prep;
res.settings = struct('seed', seed, 'num_learners', numLearners, 'num_obs', numObs, ...
    'min_events', minEvents, 'budget', budget, 'n_eligible', nnz(eligible), ...
    'n_features', numel(prep.names));

% --- Baseline -----------------------------------------------------------------
b = scoreRobustBaseline(prep.Z);
res.baseline = expand(b.score, eligible, N, budget);
res.baseline.max_abs_z = NaN(N, 1);
res.baseline.max_abs_z(eligible) = b.max_abs_z;
res.baseline.contrib = b.contrib;          % eligible rows only, prep.names order

% --- Isolation Forest -----------------------------------------------------------
res.iforest = struct('score', NaN(N,1), 'rank', NaN(N,1), 'flag', false(N,1), ...
    'threshold', NaN, 'model', []);
if useIF && nnz(eligible) >= 3 && ~isempty(prep.Z)
    [s, forest] = scoreIsolationForest(prep.Z, prep.Z, numLearners, numObs, seed);
    res.iforest = expand(s, eligible, N, budget);
    res.iforest.model = forest;
end

% --- Agreement ----------------------------------------------------------------
k = max(1, ceil(budget * nnz(eligible)));
res.agreement = struct( ...
    'spearman', spearmanRho(res.baseline.score, res.iforest.score), ...
    'topk_jaccard', topKJaccard(res.baseline.score, res.iforest.score, k), ...
    'k', k);
end

function out = expand(scoreEligible, eligible, N, budget)
out.score = NaN(N, 1);
out.score(eligible) = scoreEligible;
[out.flag, out.threshold, out.rank] = applyReviewBudget(out.score, budget);
end

function v = optOr(opts, name, default)
if isfield(opts, name)
    v = opts.(name);
else
    v = default;
end
end
