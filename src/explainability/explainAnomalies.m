function ex = explainAnomalies(res, features, cfg)
%EXPLAINANOMALIES Evidence for why entities were ranked as anomalous.
%
%   EX = EXPLAINANOMALIES(RES, FEATURES, CFG) for RES from
%   runAnomalyDetection. Explained entities = every entity flagged by
%   either detector plus the cfg.anomaly.explain_top_k highest-ranked by
%   the primary detector (Isolation Forest when available, else baseline).
%
%   Two complementary kinds of evidence (docs/EXPLAINABILITY.md):
%   1. Deviation evidence (model-independent): per-feature robust z-score
%      of the entity relative to the reference population, its raw value
%      and the reference median. For the baseline this is an exact
%      decomposition: contribution_j = z_j^2 / sum(z^2).
%   2. Occlusion attribution (Isolation Forest): the drop in the forest
%      score when feature j (or a whole feature group) is replaced by the
%      reference median (z = 0). Positive delta = the feature pushes the
%      entity towards "anomalous". A perturbation-based, model-agnostic
%      attribution in the spirit of Siddiqui et al. (2019).
%
%   EX fields:
%     summary   one row per explained entity: entity_index, entity_id,
%               iforest_score, iforest_rank, iforest_flag, baseline_score,
%               baseline_rank, baseline_flag, dominant_group, evidence_text
%     evidence  one row per (entity, feature): entity_index, feature,
%               label, group, value, reference_median, robust_z,
%               baseline_share, occlusion_delta, notable
%     groups    one row per (entity, group): baseline_share, occlusion_delta
%
%   Wording follows docs/ETHICS_AND_LIMITATIONS.md: deviations from a
%   statistical reference, never statements about guilt or danger.

arguments
    res (1,1) struct
    features table
    cfg struct = struct()
end

zThr = cfgGet(cfg, "anomaly.feature_z_threshold", 3.5);
topK = cfgGet(cfg, "anomaly.explain_top_k", 100);
prep = res.prep;
eligIdx = find(res.eligible);
hasIF = ~isempty(res.iforest.model);

primaryRank = res.baseline.rank;
if hasIF
    primaryRank = res.iforest.rank;
end
chosen = find(res.baseline.flag | res.iforest.flag | primaryRank <= topK);
[~, ord] = sort(primaryRank(chosen));
chosen = chosen(ord);
[~, rowInPrep] = ismember(chosen, eligIdx);

p = numel(prep.names);
K = numel(chosen);
Zc = prep.Z(rowInPrep, :);
contrib = res.baseline.contrib(rowInPrep, :);
groupsU = unique(prep.groups, 'stable');
G = numel(groupsU);

% --- Occlusion attribution ------------------------------------------------------
occ = NaN(K, p);
occG = NaN(K, G);
if hasIF && K > 0
    base = res.iforest.score(chosen);
    Zf = repmat(Zc, p, 1);                  % block j = all entities, feature j occluded
    for j = 1:p
        Zf((j-1)*K + (1:K), j) = 0;
    end
    [~, sf] = isanomaly(res.iforest.model, Zf);
    occ = base - reshape(sf, K, p);
    Zg = repmat(Zc, G, 1);
    for g = 1:G
        Zg((g-1)*K + (1:K), prep.groups == groupsU(g)) = 0;
    end
    [~, sg] = isanomaly(res.iforest.model, Zg);
    occG = base - reshape(sg, K, G);
end

% --- Raw values and reference medians in original units -------------------------
raw = features{chosen, cellstr(prep.names)};
refMedian = prep.center;
reg = featureRegistry();
[~, regRow] = ismember(prep.names, reg.name);
isLog = reg.transform(regRow)' == "log1p";
refMedian(isLog) = expm1(refMedian(isLog));

% --- Long evidence table ------------------------------------------------------------
eIdx = repelem(chosen, p, 1);
fIdx = repmat((1:p)', K, 1);
rawT = raw';
Zt = Zc';
Ct = contrib';
Ot = occ';
evidence = table(eIdx, prep.names(fIdx)', prep.labels(fIdx)', prep.groups(fIdx)', ...
    rawT(:), refMedian(fIdx)', Zt(:), Ct(:), Ot(:), abs(Zt(:)) >= zThr, ...
    'VariableNames', {'entity_index','feature','label','group','value', ...
    'reference_median','robust_z','baseline_share','occlusion_delta','notable'});

% --- Group table ---------------------------------------------------------------------
gShare = zeros(K, G);
for g = 1:G
    gShare(:, g) = sum(contrib(:, prep.groups == groupsU(g)), 2);
end
groupsTbl = table(repelem(chosen, G, 1), repmat(groupsU', K, 1), ...
    reshape(gShare', [], 1), reshape(occG', [], 1), 'VariableNames', ...
    {'entity_index','group','baseline_share','occlusion_delta'});

% --- Summary + text ---------------------------------------------------------------------
dominant = strings(K, 1);
text = strings(K, 1);
nElig = numel(eligIdx);
for i = 1:K
    if hasIF && all(~isnan(occG(i,:)))
        [~, gi] = max(occG(i,:));
    else
        [~, gi] = max(gShare(i,:));
    end
    if G > 0
        dominant(i) = groupsU(gi);
    end
    text(i) = composeText(i, chosen(i), res, prep, raw, refMedian, Zc, occ, ...
        hasIF, dominant(i), zThr, nElig);
end

ex.summary = table(chosen, features.entity_id(chosen), res.iforest.score(chosen), ...
    res.iforest.rank(chosen), res.iforest.flag(chosen), res.baseline.score(chosen), ...
    res.baseline.rank(chosen), res.baseline.flag(chosen), dominant, text, ...
    'VariableNames', {'entity_index','entity_id','iforest_score','iforest_rank', ...
    'iforest_flag','baseline_score','baseline_rank','baseline_flag', ...
    'dominant_group','evidence_text'});
ex.evidence = evidence;
ex.groups = groupsTbl;
ex.z_threshold = zThr;
end

function t = composeText(i, e, res, prep, raw, refMedian, Zc, occ, hasIF, dom, zThr, nElig)
parts = strings(0,1);
if hasIF
    parts(end+1) = sprintf("Isolation Forest rank %d of %d (score %.3f; review threshold %.3f).", ...
        res.iforest.rank(e), nElig, res.iforest.score(e), res.iforest.threshold);
end
parts(end+1) = sprintf("Robust baseline rank %d of %d (RMS deviation %.2f robust SD; threshold %.2f).", ...
    res.baseline.rank(e), nElig, res.baseline.score(e), res.baseline.threshold);

if hasIF && any(~isnan(occ(i,:)))
    [~, order] = sort(occ(i,:), 'descend');
else
    [~, order] = sort(abs(Zc(i,:)), 'descend');
end
order = order(1:min(3, numel(order)));
lines = strings(0,1);
for j = order
    if abs(Zc(i,j)) < 1 && ~(hasIF && occ(i,j) > 0)
        continue;
    end
    if Zc(i,j) >= 0
        dir = "higher";
    else
        dir = "lower";
    end
    note = "";
    if abs(Zc(i,j)) >= zThr
        note = " [notable]";
    end
    lines(end+1) = sprintf("%s = %s, %s than the typical %s (%+.1f robust SD)%s", ...
        prep.labels(j), fmt(raw(i,j)), dir, fmt(refMedian(j)), Zc(i,j), note); %#ok<AGROW>
end
if isempty(lines)
    parts(end+1) = "No single feature deviates strongly; the ranking reflects an unusual combination of moderate deviations.";
else
    parts(end+1) = "Main evidence: " + joinStrings(lines, "; ") + ".";
end
parts(end+1) = "Dominant feature group: " + dom + ".";
parts(end+1) = "Interpretation: a statistical deviation from the reference population of offenders with >= " + ...
    res.settings.min_events + " recorded crimes; it is not evidence of guilt, intent or dangerousness.";
t = joinStrings(parts, " ");
end

function s = fmt(v)
if isnan(v)
    s = "n/a";
elseif abs(v - round(v)) < 1e-9
    s = sprintf("%d", round(v));
else
    s = sprintf("%.3g", v);
end
end
