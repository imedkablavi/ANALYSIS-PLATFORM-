function base = scoreRobustBaseline(Z)
%SCOREROBUSTBASELINE Transparent multivariate robust-deviation score.
%
%   BASE = SCOREROBUSTBASELINE(Z) for a matrix of robust z-scores
%   (prepareFeatureMatrix):
%     base.score       sqrt(mean(z.^2)) per row: root-mean-square robust
%                      deviation = Euclidean distance from the reference
%                      median in robust-SD units, divided by sqrt(p)
%     base.max_abs_z   largest single-feature deviation
%     base.contrib     z_j^2 / sum(z.^2): exact additive share of each
%                      feature in the squared score (explanations)
%   No fitting beyond the median/scale, no randomness: this is the
%   interpretable reference against which Isolation Forest is compared.

n = size(Z, 1);
if size(Z, 2) == 0
    % No usable feature (e.g. all constant): nothing can be scored.
    base.score = NaN(n, 1);
    base.max_abs_z = NaN(n, 1);
    base.contrib = zeros(n, 0);
    return;
end
sq = Z.^2;
total = sum(sq, 2);
base.score = sqrt(mean(sq, 2));
base.max_abs_z = max(abs(Z), [], 2);
base.contrib = sq ./ total;
base.contrib(total == 0, :) = 0;
end
