function [Zinj, labels, rows] = injectSyntheticAnomalies(Z, colGroups, targetGroup, fraction, shift, seed)
%INJECTSYNTHETICANOMALIES Controlled, clearly SYNTHETIC anomalies in feature space.
%
%   [ZINJ, LABELS, ROWS] = INJECTSYNTHETICANOMALIES(Z, COLGROUPS,
%   TARGETGROUP, FRACTION, SHIFT, SEED)
%
%   Z           robust-scaled feature matrix of REAL eligible entities
%   COLGROUPS   1 x p string: feature group of each column
%   TARGETGROUP group whose features are perturbed ("all" = every column)
%   FRACTION    share of rows to perturb (at least one)
%   SHIFT       magnitude in robust-SD units
%
%   For each selected row, every column of the target group is moved SHIFT
%   robust SD further from the reference median in the direction it already
%   deviates (zeros get a random sign). Everything else is untouched.
%
%   Purpose and limits (docs/EVALUATION.md): this measures whether a
%   detector/feature set is SENSITIVE to a known deviation of a given type.
%   It is not ground truth about real offenders and its scores must never
%   be reported as real-world detection accuracy (Emmott et al. 2013
%   discuss constructing benchmarks with controlled anomalies).

arguments
    Z double
    colGroups (1,:) string
    targetGroup (1,1) string
    fraction (1,1) double
    shift (1,1) double
    seed (1,1) double
end

rng(seed, "twister");
n = size(Z, 1);
m = max(1, round(fraction * n));
rows = sort(randperm(n, m))';
if targetGroup == "all"
    cols = true(1, size(Z, 2));
else
    cols = colGroups == targetGroup;
end
Zinj = Z;
block = Z(rows, cols);
s = sign(block);
zeroMask = s == 0;
rnd = 2 * (rand(size(block)) > 0.5) - 1;
s(zeroMask) = rnd(zeroMask);
Zinj(rows, cols) = block + s * shift;
labels = false(n, 1);
labels(rows) = true;
end
