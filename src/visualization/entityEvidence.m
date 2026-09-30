function ev = entityEvidence(bundle, entityIndex)
%ENTITYEVIDENCE Per-feature deviation profile of one entity.
%
%   EV = ENTITYEVIDENCE(BUNDLE, ENTITYINDEX) returns a table (feature,
%   label, group, value, reference_median, robust_z, occlusion_delta) for
%   an eligible entity, or an empty table when the entity is not in the
%   reference population (insufficient history). Occlusion deltas are
%   filled when the entity is among the explained entities.

prep = bundle.anomaly.prep;
elig = find(bundle.anomaly.eligible);
row = find(elig == entityIndex, 1);
ev = table(strings(0,1), strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), ...
    zeros(0,1), zeros(0,1), 'VariableNames', {'feature','label','group', ...
    'value','reference_median','robust_z','occlusion_delta'});
if isempty(row)
    return;
end
reg = bundle.registry;
[~, regRow] = ismember(prep.names, reg.name);
ref = prep.center;
isLog = reg.transform(regRow)' == "log1p";
ref(isLog) = expm1(ref(isLog));
values = bundle.entities{entityIndex, cellstr(prep.names)};
occ = NaN(1, numel(prep.names));
E = bundle.explanations.evidence;
m = E.entity_index == entityIndex;
if any(m)
    [~, loc] = ismember(prep.names, E.feature(m));
    od = E.occlusion_delta(m);
    occ(loc > 0) = od(loc(loc > 0));
end
ev = table(prep.names', prep.labels', prep.groups', values', ref', ...
    prep.Z(row, :)', occ', 'VariableNames', {'feature','label','group', ...
    'value','reference_median','robust_z','occlusion_delta'});
end
