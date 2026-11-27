function text = renderEntitySummary(bundle, entityIndex)
%RENDERENTITYSUMMARY Localized measured evidence for the saved full analysis.
%   Rendering never changes scores or infers attack type, intent or certainty.
%   Old bundles with missing scores/evidence retain explicit unavailable states.
arguments
    bundle (1,1) struct
    entityIndex (1,1) double {mustBeInteger, mustBePositive}
end
ent = bundle.entities;
if entityIndex > height(ent)
    error("MOSAIC:EntityIndex", "Entity index is outside the saved entity table.");
end
text = uiText("Scope: the complete saved analysis; playback does not recompute scores.");
count = scalarValue(ent, 'event_count', entityIndex);
if isfinite(count)
    text(end+1,1) = uiText("Recorded events: %g.", count);
end
hasEligibility = ismember('eligible', ent.Properties.VariableNames);
if hasEligibility && ~ent.eligible(entityIndex)
    minimum = NaN;
    if isfield(bundle, 'anomaly') && isfield(bundle.anomaly, 'settings')
        minimum = cfgGet(bundle.anomaly.settings, "min_events", NaN);
    end
    if isfinite(count) && isfinite(minimum)
        text(end+1,1) = uiText("Not scored: %g recorded events; at least %g are required.", count, minimum);
    else
        text(end+1,1) = uiText("This record was not scored in the saved analysis.");
    end
    text(end+1,1) = uiText("These values describe statistical deviations, not intent or a verdict.");
    return;
end
if ~hasEligibility
    text(end+1,1) = uiText("Scoring status is unavailable in this saved analysis.");
end
nEligible = NaN;
if hasEligibility
    nEligible = nnz(ent.eligible);
end
for detector = ["iforest", "baseline"]
    label = "Isolation Forest";
    if detector == "baseline"
        label = "Robust baseline";
    end
    score = scalarValue(ent, detector + "_score", entityIndex);
    rank = scalarValue(ent, detector + "_rank", entityIndex);
    if ~isfinite(score)
        text(end+1,1) = uiText("%s: score unavailable.", uiText(label));
    elseif isfinite(rank) && isfinite(nEligible)
        text(end+1,1) = uiText("%s: score %.3g; rank %g of %g eligible entities.", ...
            uiText(label), score, rank, nEligible);
    else
        text(end+1,1) = uiText("%s: score %.3g; rank unavailable.", uiText(label), score);
    end
end

ev = table();
try
    ev = entityEvidence(bundle, entityIndex);
catch
    % Earlier saved bundles may lack the prepared matrix or attribution table.
    if isfield(bundle, 'explanations') && isfield(bundle.explanations, 'evidence')
        saved = bundle.explanations.evidence;
        if istable(saved) && ismember('entity_index', saved.Properties.VariableNames)
            ev = saved(saved.entity_index == entityIndex, :);
        end
    end
end
needed = {'feature','label','value','reference_median','robust_z'};
if istable(ev) && all(ismember(needed, ev.Properties.VariableNames))
    usable = isfinite(ev.value) & isfinite(ev.reference_median) & isfinite(ev.robust_z);
    ev = ev(usable, :);
else
    ev = table();
end
if isempty(ev)
    text(end+1,1) = uiText("Measured feature deviations are unavailable in this saved analysis.");
else
    [~, order] = sort(abs(ev.robust_z), 'descend');
    registry = featureRegistry();
    for k = reshape(order(1:min(3, numel(order))), 1, [])
        label = string(ev.label(k));
        r = find(registry.name == string(ev.feature(k)), 1);
        if ~isempty(r)
            label = registry.label(r); % current neutral vocabulary for older bundles
        end
        text(end+1,1) = uiText("%s: value %.3g; reference median %.3g; robust z %+.2f.", ...
            uiText(label), ev.value(k), ev.reference_median(k), ev.robust_z(k));
    end
end
text(end+1,1) = uiText("These values describe statistical deviations, not intent or a verdict.");
end

function value = scalarValue(t, name, row)
value = NaN;
if ismember(name, string(t.Properties.VariableNames))
    candidate = t.(name)(row,:);
    if isnumeric(candidate) && isscalar(candidate)
        value = candidate;
    end
end
end
