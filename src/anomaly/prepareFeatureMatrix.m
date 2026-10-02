function prep = prepareFeatureMatrix(features, registry, groups, referenceRows)
%PREPAREFEATUREMATRIX Transform, robust-scale and impute selected feature groups.
%
%   PREP = PREPAREFEATUREMATRIX(FEATURES, REGISTRY, GROUPS, REFERENCEROWS)
%
%   FEATURES       entity feature table (rows = entities to score)
%   REGISTRY       featureRegistry()
%   GROUPS         string array of feature groups to use (ablation unit)
%   REFERENCEROWS  logical mask of FEATURES rows used to FIT the scaler
%
%   Steps (docs/ANOMALY_DETECTION.md):
%   1. transform: log1p for registry transform "log1p" (heavy-tailed counts)
%   2. robust scaling fit on the reference rows only:
%        z = (x - median_ref) / scale_ref   (robustCenterScale)
%   3. features whose reference scale is degenerate ("constant"/"empty")
%      are dropped and listed in prep.dropped
%   4. remaining NaN (feature undefined for the entity) are imputed with
%      z = 0, i.e. the reference median; prep.imputed records where
%
%   PREP fields: names, groups, labels, center, scale, scale_method,
%   X (transformed values), Z (scaled + imputed), imputed, dropped.

arguments
    features table
    registry table
    groups (1,:) string
    referenceRows (:,1) logical
end

sel = ismember(registry.group, groups) & ...
    ismember(registry.name, string(features.Properties.VariableNames));
reg = registry(sel, :);
X = features{:, cellstr(reg.name)};
isLog = reg.transform == "log1p";
X(:, isLog) = sign(X(:, isLog)) .* log1p(abs(X(:, isLog)));

p = size(X, 2);
center = NaN(1, p);
scale = NaN(1, p);
method = strings(1, p);
for j = 1:p
    [center(j), scale(j), method(j)] = robustCenterScale(X(referenceRows, j));
end
keep = ~ismember(method, ["constant","empty"]);

prep.names = reg.name(keep)';
prep.groups = reg.group(keep)';
prep.labels = reg.label(keep)';
prep.center = center(keep);
prep.scale = scale(keep);
prep.scale_method = method(keep);
prep.X = X(:, keep);
Z = (prep.X - prep.center) ./ prep.scale;
prep.imputed = isnan(Z);
Z(prep.imputed) = 0;
prep.Z = Z;
prep.dropped = reg.name(~keep)';
end
