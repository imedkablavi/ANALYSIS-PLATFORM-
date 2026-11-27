function E = evaluateGroundTruth(entities, truth, k)
%EVALUATEGROUNDTRUTH Detector quality against published host labels.
%
%   E = EVALUATEGROUNDTRUTH(ENTITIES, TRUTH, K) compares the unsupervised
%   scores of bundle.entities (baseline_score, iforest_score, eligible)
%   with TRUTH (networkGroundTruth). One row per (detector, setting):
%     setting "known_only"          hosts labelled malicious or benign;
%                                   unknown hosts are left out
%     setting "unknown_as_benign"   unknown hosts count as negatives
%                                   (conservative for precision: an unknown
%                                   host ranked high counts as a false
%                                   alarm; reported separately because
%                                   CTU-13 Background is NOT verified benign)
%   Columns: detector, setting, n_scored, n_malicious, n_negative,
%   roc_auc (rankAuc), average_precision, chance_ap (= positive rate),
%   precision_at_k, recall_at_k, k, malicious_not_scored (malicious hosts
%   below the eligibility threshold: they cannot be found by design).
%   K defaults to the number of malicious scored hosts (R-precision).
%
%   Labels are used here only, after scoring: the detectors never see them.

arguments
    entities table
    truth table
    k double = []
end

det = ["baseline", "iforest"];
settings = ["known_only", "unknown_as_benign"];
rows = cell(0, 12);
mal = truth.truth == "malicious";
for dname = det
    score = entities.(dname + "_score");
    for st = settings
        use = entities.eligible & ~isnan(score);
        if st == "known_only"
            use = use & truth.truth ~= "unknown";
        end
        y = mal(use);
        x = score(use);
        nPos = nnz(y);
        kk = k;
        if isempty(kk)
            kk = nPos;
        end
        if isempty(x) || nPos == 0
            auc = NaN; ap = NaN; p = NaN; r = NaN;
        else
            auc = rankAuc(x, y);
            ap = averagePrecision(x, y);
            [p, r] = precisionAtK(x, y, max(kk, 1));
        end
        notScored = nnz(mal & ~entities.eligible);
        rows(end+1, :) = {dname, st, numel(x), nPos, numel(x) - nPos, auc, ap, ...
            nPos / max(numel(x), 1), p, r, kk, notScored}; %#ok<AGROW>
    end
end
E = cell2table(rows, 'VariableNames', {'detector', 'setting', 'n_scored', ...
    'n_malicious', 'n_negative', 'roc_auc', 'average_precision', 'chance_ap', ...
    'precision_at_k', 'recall_at_k', 'k', 'malicious_not_scored'});
E.detector = string(E.detector);
E.setting = string(E.setting);
end
