function ctx = getEntityContext(bundle, entityIndex)
%GETENTITYCONTEXT Everything the entity-detail view shows for one entity.
%
%   CTX = GETENTITYCONTEXT(BUNDLE, ENTITYINDEX) links the shared analytical
%   model: Entity -> Events -> Behaviour -> Relations -> Sequence ->
%   Anomaly -> Explanation. Pure function (no graphics) so it is unit
%   testable and reused by the app and by reports.
%
%   ctx.profile      one-row entity table (features, scores, flags)
%   ctx.events       the entity's events in canonical order (with tokens)
%   ctx.partners     partner_index, partner_id, shared_crimes, first_time,
%                    last_time, partner_iforest_score
%   ctx.evidence     entityEvidence table (empty if ineligible)
%   ctx.explanation  evidence text, or the reason no explanation exists
%   ctx.status       "flagged" | "ranked" | "insufficient history"

ent = bundle.entities;
ctx.profile = ent(entityIndex, :);
ctx.events = bundle.events(bundle.events.entity_index == entityIndex, :);

R = bundle.relations;
m = R.a_index == entityIndex | R.b_index == entityIndex;
r = R(m, :);
partner = r.a_index;
partner(r.a_index == entityIndex) = r.b_index(r.a_index == entityIndex);
ctx.partners = table(partner, ent.entity_id(partner), r.weight, r.first_time, ...
    r.last_time, ent.iforest_score(partner), 'VariableNames', {'partner_index', ...
    'partner_id','shared_crimes','first_time','last_time','partner_iforest_score'});
ctx.partners = sortrows(ctx.partners, 'shared_crimes', 'descend');

ctx.evidence = entityEvidence(bundle, entityIndex);

S = bundle.explanations.summary;
k = find(S.entity_index == entityIndex, 1);
if ~ent.eligible(entityIndex)
    ctx.status = "insufficient history";
    ctx.explanation = sprintf(['Not scored: %d recorded crime(s), below the minimum of %d ' ...
        'needed for temporal and sequence features. This is not a statement that ' ...
        'the behaviour is normal.'], ent.event_count(entityIndex), ...
        bundle.anomaly.settings.min_events);
elseif ~isempty(k)
    if ent.iforest_flag(entityIndex) || ent.baseline_flag(entityIndex)
        ctx.status = "flagged";
    else
        ctx.status = "ranked";
    end
    ctx.explanation = S.evidence_text(k);
else
    ctx.status = "ranked";
    ctx.explanation = sprintf(['Scored but outside the review budget (Isolation Forest rank %g, ' ...
        'baseline rank %g of %d eligible). See the deviation profile for details.'], ...
        ent.iforest_rank(entityIndex), ent.baseline_rank(entityIndex), nnz(ent.eligible));
end
ctx.explanation = string(ctx.explanation);
end
