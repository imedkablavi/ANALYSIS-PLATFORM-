function results = runExperiments(bundle, cfg, outDir, opts)
%RUNEXPERIMENTS Reproducible experiment suite E1-E9 (docs/EXPERIMENTS.md).
%
%   RESULTS = RUNEXPERIMENTS(BUNDLE, CFG, OUTDIR) uses the analysis bundle
%   from runAnalysisPipeline and writes CSV tables plus
%   experiments_summary.md to OUTDIR. OPTS.quick = true reduces repeats
%   (smoke test). OPTS.use_iforest = false runs baseline-only experiments.
%
%   E1  data quality                    (validation report)
%   E2  statistical baseline behaviour  (score distribution, flags)
%   E3  Isolation Forest behaviour      (score distribution, agreement)
%   E4  feature-group ablation on real data (ranking consistency)
%   E5-E7 SYNTHETIC injection per feature group x ablation set
%        (temporal = E5, graph = E6, sequence = E7; others reported too)
%   E8  sensitivity: seeds, NumLearners, NumObservationsPerLearner,
%        min_events, review budget
%   E9  runtime per pipeline stage and bundle memory
%   E10 (usability) is a human study: protocol in docs/EVALUATION.md.
%
%   No experiment uses real labels (none exist). Synthetic results are
%   written to files whose names start with "synthetic_".

arguments
    bundle (1,1) struct
    cfg struct
    outDir (1,1) string
    opts struct = struct()
end

quick = isfield(opts, "quick") && opts.quick;
useIF = bundle.meta.iforest_used && ~(isfield(opts, "use_iforest") && ~opts.use_iforest);
if ~isfolder(outDir)
    mkdir(outDir);
end
registry = bundle.registry;
feat = bundle.entities;
res0 = bundle.anomaly;
seed = cfg.analysis.random_seed;
nl = cfg.anomaly.iforest.num_learners;
no = cfg.anomaly.iforest.num_observations_per_learner;
budget = cfg.anomaly.review_budget_fraction;
md = "# Experiment Results";
md(end+1,1) = "";
md(end+1,1) = "Generated: " + string(datetime('now'), 'yyyy-MM-dd HH:mm') + ...
    " | MATLAB " + string(version) + " | seed " + seed + ...
    " | feature version " + cfg.project.feature_version;
md(end+1,1) = "";
md(end+1,1) = "All numbers below are produced by `scripts/run_experiments.m`. Synthetic-injection results measure sensitivity to controlled deviations and are NOT real-world detection accuracy.";

% ---------------- E1 ----------------------------------------------------------------
v = bundle.validation;
writetable(v.checks, fullfile(outDir, "E1_validation_checks.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E1 Data quality";
md(end+1,1) = sprintf("Valid: %s. Failed error checks: %d. Failed warning checks: %d.", ...
    string(v.is_valid), numel(v.errors), numel(v.warnings));
failed = v.checks(~v.checks.passed, :);
for k = 1:height(failed)
    md(end+1,1) = sprintf("- %s (%s, %s): %s -> %g", failed.check_id(k), ...
        failed.severity(k), failed.category(k), failed.message(k), failed.affected(k)); %#ok<AGROW>
end

% ---------------- E2 / E3 -------------------------------------------------------------
q = [0 0.25 0.5 0.75 0.9 0.99 1];
el = feat.eligible;
dist = table(q', empiricalQuantile(feat.baseline_score(el), q)', ...
    empiricalQuantile(feat.iforest_score(el), q)', 'VariableNames', ...
    {'quantile','baseline_score','iforest_score'});
writetable(dist, fullfile(outDir, "E2_E3_score_quantiles.csv"));
dom = bundle.explanations.summary;
flaggedAny = dom.baseline_flag | dom.iforest_flag;
[gd, gname] = findgroups(dom.dominant_group(flaggedAny));
domTbl = table(gname, accumarray(gd, 1), 'VariableNames', {'dominant_group','flagged_entities'});
writetable(domTbl, fullfile(outDir, "E2_E3_dominant_groups.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E2/E3 Baseline and Isolation Forest";
md(end+1,1) = sprintf("Eligible entities: %d of %d (min_events = %d). Features used: %d (dropped as constant: %s).", ...
    nnz(el), height(feat), res0.settings.min_events, numel(res0.prep.names), ...
    droppedText(res0.prep.dropped));
md(end+1,1) = sprintf("Review budget %.3g -> %d entities per detector. Baseline threshold %.3f; IF threshold %.3f.", ...
    budget, res0.agreement.k, res0.baseline.threshold, res0.iforest.threshold);
md(end+1,1) = sprintf("Agreement: Spearman %.3f, top-k Jaccard %.3f.", ...
    res0.agreement.spearman, res0.agreement.topk_jaccard);

% ---------------- E4 ablation on real data ----------------------------------------------
sets = ablationSets();
abl = table('Size', [numel(sets) 6], 'VariableTypes', ["string","double","double","double","double","double"], ...
    'VariableNames', {'feature_set','n_features','baseline_topk_jaccard_vs_full', ...
    'baseline_spearman_vs_full','iforest_topk_jaccard_vs_full','iforest_spearman_vs_full'});
k = res0.agreement.k;
for s = 1:numel(sets)
    r = runAnomalyDetection(feat, registry, cfg, sets{s}, struct('use_iforest', useIF));
    abl.feature_set(s) = strjoin(sets{s}, "+");
    abl.n_features(s) = numel(r.prep.names);
    abl.baseline_topk_jaccard_vs_full(s) = topKJaccard(r.baseline.score, res0.baseline.score, k);
    abl.baseline_spearman_vs_full(s) = spearmanRho(r.baseline.score, res0.baseline.score);
    abl.iforest_topk_jaccard_vs_full(s) = topKJaccard(r.iforest.score, res0.iforest.score, k);
    abl.iforest_spearman_vs_full(s) = spearmanRho(r.iforest.score, res0.iforest.score);
end
writetable(abl, fullfile(outDir, "E4_ablation_real_ranking_consistency.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E4 Feature-group ablation (real data, ranking consistency with the full model)";
md = [md; tableToMarkdown(abl)];

% ---------------- E5-E7 synthetic injection -----------------------------------------------
Z = res0.prep.Z;
colGroups = res0.prep.groups;
targets = ["activity","temporal","spatial","cooffending","graph","sequence"];
targets = targets(ismember(targets, colGroups));
shifts = cfg.evaluation.synthetic_shift;
reps = cfg.evaluation.synthetic_repeats;
if quick
    reps = 1;
    shifts = shifts(end);
end
rows = {};
for tg = targets
    for sh = shifts
        for rep = 1:reps
            [Zi, lab] = injectSyntheticAnomalies(Z, colGroups, tg, ...
                cfg.evaluation.synthetic_fraction, sh, seed + rep);
            m = nnz(lab);
            for s = 1:numel(sets)
                cols = ismember(colGroups, sets{s});
                if ~any(cols)
                    continue;
                end
                bs = sqrt(mean(Zi(:, cols).^2, 2));
                rows(end+1, :) = {tg, sh, rep, strjoin(sets{s}, "+"), "baseline", ...
                    rankAuc(bs, lab), averagePrecision(bs, lab), precisionAtK(bs, lab, m)}; %#ok<AGROW>
                if useIF
                    % Novelty-detection evaluation: fit on the clean reference
                    % population and score the contaminated synthetic sample.
                    % This prevents injected anomalies from contaminating training.
                    is = scoreIsolationForest(Z(:, cols), Zi(:, cols), nl, no, seed + rep);
                    rows(end+1, :) = {tg, sh, rep, strjoin(sets{s}, "+"), "iforest", ...
                        rankAuc(is, lab), averagePrecision(is, lab), precisionAtK(is, lab, m)}; %#ok<AGROW>
                end
            end
        end
    end
end
syn = cell2table(rows, 'VariableNames', {'injected_group','shift_sd','repeat', ...
    'feature_set','detector','roc_auc','average_precision','precision_at_m'});
syn.injected_group = string(syn.injected_group);
syn.feature_set = string(syn.feature_set);
syn.detector = string(syn.detector);
writetable(syn, fullfile(outDir, "synthetic_E5_E7_injection_raw.csv"));
[gg, a1, a2, a3, a4] = findgroups(syn.injected_group, syn.shift_sd, syn.feature_set, syn.detector);
agg = table(a1, a2, a3, a4, splitapply(@mean, syn.roc_auc, gg), splitapply(@std, syn.roc_auc, gg), ...
    splitapply(@mean, syn.average_precision, gg), splitapply(@mean, syn.precision_at_m, gg), ...
    'VariableNames', {'injected_group','shift_sd','feature_set','detector', ...
    'roc_auc_mean','roc_auc_sd','ap_mean','precision_at_m_mean'});
writetable(agg, fullfile(outDir, "synthetic_E5_E7_injection_summary.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E5-E7 SYNTHETIC injection (sensitivity, not real accuracy)";
md(end+1,1) = sprintf("Injected fraction %.3g, repeats %d, shifts %s robust SD. Chance AP = injected fraction.", ...
    cfg.evaluation.synthetic_fraction, reps, mat2str(shifts));
fullSet = strjoin(cfg.anomaly.feature_groups, "+");
viewTbl = agg(agg.shift_sd == max(shifts) & ...
    (agg.feature_set == fullSet | agg.feature_set == agg.injected_group), :);
md = [md; tableToMarkdown(viewTbl)];

% ---------------- E8 sensitivity ---------------------------------------------------------------
sens = {};
if useIF
    Zf = res0.prep.Z;
    base = res0.iforest.score(el);
    seeds = cfg.evaluation.stability_seeds;
    if quick
        seeds = seeds(1:min(3, end));
    end
    S = zeros(nnz(el), numel(seeds));
    for i = 1:numel(seeds)
        S(:, i) = scoreIsolationForest(Zf, Zf, nl, no, seeds(i));
    end
    jac = [];
    for i = 1:numel(seeds)
        for j = i+1:numel(seeds)
            jac(end+1) = topKJaccard(S(:,i), S(:,j), k); %#ok<AGROW>
        end
    end
    sens(end+1, :) = {"seed", "pairwise over seeds", mean(jac), min(jac), NaN};
    for v1 = cfg.evaluation.sensitivity.num_learners
        s1 = scoreIsolationForest(Zf, Zf, v1, no, seed);
        sens(end+1, :) = {"num_learners", string(v1), topKJaccard(s1, base, k), NaN, spearmanRho(s1, base)}; %#ok<AGROW>
    end
    for v2 = cfg.evaluation.sensitivity.num_obs
        s2 = scoreIsolationForest(Zf, Zf, nl, v2, seed);
        sens(end+1, :) = {"num_obs", string(v2), topKJaccard(s2, base, k), NaN, spearmanRho(s2, base)}; %#ok<AGROW>
    end
end
for me = cfg.evaluation.sensitivity.min_events
    r = runAnomalyDetection(feat, registry, cfg, cfg.anomaly.feature_groups, ...
        struct('min_events', me, 'use_iforest', useIF));
    common = r.eligible & res0.eligible;
    a = r.baseline.flag & common;
    b = res0.baseline.flag & common;
    sens(end+1, :) = {"min_events", string(me) + " (eligible " + nnz(r.eligible) + ")", ...
        nnz(a & b) / max(nnz(a | b), 1), NaN, spearmanRho(r.baseline.score(common), res0.baseline.score(common))}; %#ok<AGROW>
end
for bf = cfg.evaluation.sensitivity.budget
    [fb, thrB] = applyReviewBudget(res0.baseline.score, bf);
    [fi, thrI] = applyReviewBudget(res0.iforest.score, bf);
    sens(end+1, :) = {"budget", string(bf) + " (thr base " + sprintf("%.3f", thrB) + ...
        ", IF " + sprintf("%.3f", thrI) + ")", nnz(fb & fi) / max(nnz(fb | fi), 1), NaN, NaN}; %#ok<AGROW>
end
sensT = cell2table(sens, 'VariableNames', {'parameter','value','topk_jaccard', ...
    'min_jaccard','spearman'});
sensT.parameter = string(sensT.parameter);
sensT.value = string(sensT.value);
writetable(sensT, fullfile(outDir, "E8_sensitivity.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E8 Sensitivity and stability";
md(end+1,1) = "topk_jaccard: overlap with the default run (seed row: mean pairwise over seeds; min_events rows: baseline flags among commonly eligible entities; budget rows: baseline-vs-IF overlap at that budget).";
md = [md; tableToMarkdown(sensT)];

% ---------------- E9 performance ---------------------------------------------------------
t = bundle.meta.timings;
fn = fieldnames(t);
perf = table(string(fn), cellfun(@(f) t.(f), fn), 'VariableNames', {'stage','seconds'});
info = whos('bundle');
perf(end+1, :) = {"bundle_memory_MB", info.bytes / 1024^2};
writetable(perf, fullfile(outDir, "E9_performance.csv"));
md(end+1,1) = "";
md(end+1,1) = "## E9 Runtime (seconds) and memory";
md = [md; tableToMarkdown(perf)];

% ---------------- temporal findings (supports E5 on real data) ----------------------------
ta = bundle.temporal;
flaggedMonths = ta.series.bin_start(ta.crime_anomalies.is_high | ta.crime_anomalies.is_low);
md(end+1,1) = "";
md(end+1,1) = "## Real temporal findings (system level)";
md(end+1,1) = sprintf("Months with |robust z| >= %.1f vs the causal 12-month baseline: %s", ...
    cfg.temporal.robust_z_threshold, joinStrings(string(flaggedMonths, 'yyyy-MM'), ", "));
if height(ta.change_points) > 0
    md(end+1,1) = "Change points (first month of new level): " + joinStrings(compose("%s (%.0f -> %.0f crimes/month)", ...
        string(ta.change_points.bin_start, 'yyyy-MM'), ta.change_points.mean_before, ...
        ta.change_points.mean_after), ", ");
else
    md(end+1,1) = "No change point exceeded the BIC-type penalty.";
end

writeTextFile(fullfile(outDir, "experiments_summary.md"), joinStrings(md, newline));
results = struct('ablation', abl, 'synthetic', agg, 'sensitivity', sensT, ...
    'performance', perf, 'score_quantiles', dist);
end

function t = droppedText(d)
if isempty(d)
    t = "none";
else
    t = joinStrings(d, ", ");
end
end

function sets = ablationSets()
sets = {["activity"], ["temporal"], ["spatial"], ["cooffending"], ["graph"], ...
    ["sequence"], ["activity","temporal"], ["activity","temporal","graph"], ...
    ["activity","temporal","graph","sequence"], ...
    ["activity","temporal","spatial","cooffending","graph","sequence"]}; %#ok<NBRAK2>
end

function lines = tableToMarkdown(T)
names = string(T.Properties.VariableNames);
lines = ["| " + strjoin(names, " | ") + " |"; "|" + strjoin(repmat("---", 1, numel(names)), "|") + "|"];
for r = 1:height(T)
    cells = strings(1, numel(names));
    for c = 1:numel(names)
        val = T{r, c};
        if isnumeric(val)
            cells(c) = sprintf("%.3g", val);
        else
            cells(c) = string(val);
        end
    end
    lines(end+1, 1) = "| " + strjoin(cells, " | ") + " |"; %#ok<AGROW>
end
end
