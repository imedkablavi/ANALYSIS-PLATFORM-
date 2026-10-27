function ref = referenceMedians(prep, registry)
%REFERENCEMEDIANS Reference medians of the prepared features in original units.
%
%   REF = REFERENCEMEDIANS(PREP, REGISTRY) undoes the feature transform of
%   prepareFeatureMatrix on PREP.center (e.g. expm1 for "log1p"), so evidence
%   can say "value 18 vs typical 4" in the units the user sees. Shared by
%   explainAnomalies (exported evidence) and entityEvidence (app), which must
%   always agree.

[found, regRow] = ismember(prep.names, registry.name);
if ~all(found)
    error("MOSAIC:UnknownFeature", "Features missing from the registry: %s", ...
        strjoin(prep.names(~found), ", "));
end
ref = prep.center;
isLog = registry.transform(regRow)' == "log1p";
ref(isLog) = expm1(ref(isLog));
end
