function [scores, forest] = scoreIsolationForest(Ztrain, Zscore, numLearners, numObs, seed)
%SCOREISOLATIONFOREST Fit an isolation forest and score observations.
%
%   [SCORES, FOREST] = SCOREISOLATIONFOREST(ZTRAIN, ZSCORE, NUMLEARNERS,
%   NUMOBS, SEED) fits MATLAB's iforest (Statistics and Machine Learning
%   Toolbox, R2021b+) on ZTRAIN and returns anomaly scores in [0,1] for
%   ZSCORE (higher = easier to isolate = more anomalous; Liu et al. 2008).
%
%   - The random stream is reset with rng(SEED, "twister") for reproducibility.
%   - ContaminationFraction = 0: iforest's own threshold is not used; the
%     project applies an explicit review budget (applyReviewBudget).
%   - NumObservationsPerLearner is capped at the training size.
%   - Isolation trees split on single features, so the model is invariant
%     to monotone per-feature transforms; scaling matters only through
%     imputation. The same matrix as the baseline is used for comparability.

arguments
    Ztrain double
    Zscore double
    numLearners (1,1) double {mustBeInteger, mustBePositive} = 200
    numObs (1,1) double {mustBeInteger, mustBePositive} = 256
    seed (1,1) double = 42
end

if isempty(which('iforest'))
    error("MOSAIC:ToolboxMissing", ...
        "iforest requires the Statistics and Machine Learning Toolbox (R2021b or newer).");
end
if size(Ztrain, 1) < 3
    error("MOSAIC:TooFewObservations", "Isolation forest needs at least 3 training rows.");
end
rng(seed, "twister");
forest = iforest(Ztrain, 'NumLearners', numLearners, ...
    'NumObservationsPerLearner', min(numObs, size(Ztrain, 1)), ...
    'ContaminationFraction', 0);
[~, scores] = isanomaly(forest, Zscore);
end
