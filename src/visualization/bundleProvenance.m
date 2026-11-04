function T = bundleProvenance(bundle)
%BUNDLEPROVENANCE Privacy-safe provenance and coverage of one saved run.
%   Two string columns, field/value, translated with uiText. Only allowlisted
%   metadata and aggregate counts are shown; paths, entity IDs and arbitrary
%   import notes are never copied into the presentation.

missing = uiText("Unavailable");
labels = ["Dataset name"; "Dataset ID"; "Source blob SHA"; "Source rows read"; ...
    "Record selection"; "MATLAB version"; "Feature version"; "Random seed"; ...
    "Total entities"; "Eligible entities"; "Baseline scored entities"; ...
    "Isolation Forest scored entities"; "Unscored by either detector"; ...
    "Known published labels"; "Unknown or unavailable labels"];
values = repmat(missing, numel(labels), 1);
values(1) = safeMetadata(cfgGet(bundle, "meta.dataset.name", missing));
values(2) = safeMetadata(cfgGet(bundle, "meta.dataset.id", missing));
sha = string(cfgGet(bundle, "meta.dataset_blob_sha", ""));
if isscalar(sha) && ~isempty(regexp(char(sha), '^[0-9a-fA-F]{40}([0-9a-fA-F]{24})?$', 'once'))
    values(3) = sha;
end
values(4) = scalarNumber(cfgGet(bundle, "meta.dataset.n_rows", NaN), missing);
% Recognize only the importer's numeric sample-selection note. Other notes
% can contain filenames or identifiers, so do not display them verbatim.
notes = string(cfgGet(bundle, "meta.dataset.import_notes", strings(0,1)));
for k = 1:numel(notes)
    tok = regexp(char(notes(k)), ...
        '^Only records ([0-9]+) to ([0-9]+|Inf) were read \(first_row/max_rows\)\.$', 'tokens', 'once');
    if ~isempty(tok)
        values(5) = uiText("Records %s to %s (contiguous selection)", tok{1}, tok{2});
        break;
    end
end
values(6) = safeMetadata(cfgGet(bundle, "meta.matlab_version", missing));
values(7) = safeMetadata(cfgGet(bundle, "meta.feature_version", missing));
values(8) = scalarNumber(cfgGet(bundle, "meta.random_seed", NaN), missing);
if isstruct(bundle) && isfield(bundle, 'entities') && istable(bundle.entities)
    e = bundle.entities;
    n = height(e);
    values(9) = string(n);
    eligible = true(n,1);
    hasEligible = ismember('eligible', e.Properties.VariableNames);
    if hasEligible
        eligible = e.eligible == 1;
        values(10) = string(nnz(eligible));
    end
    scored = false(n,2);
    hasScore = false(1,2);
    names = ["baseline_score", "iforest_score"];
    for k = 1:2
        hasScore(k) = ismember(names(k), string(e.Properties.VariableNames));
        if hasScore(k)
            scored(:,k) = isfinite(e.(names(k))) & eligible;
            values(10+k) = string(nnz(scored(:,k)));
        end
    end
    if all(hasScore) && hasEligible
        values(13) = string(nnz(~any(scored,2)));
    end
    known = false(n,1);
    if ismember('truth', e.Properties.VariableNames)
        known = ismember(string(e.truth), ["malicious", "benign"]);
    end
    values(14) = string(nnz(known));
    values(15) = string(n - nnz(known));
end
for k = 1:numel(labels)
    labels(k) = uiText(labels(k));
end
T = table(labels, values, 'VariableNames', {'field','value'});
end

function s = scalarNumber(v, missing)
s = missing;
if isnumeric(v) && isscalar(v) && isfinite(v)
    s = string(v);
end
end

function s = safeMetadata(v)
s = string(v);
if ~isscalar(s) || ismissing(s) || strlength(s) == 0
    s = uiText("Unavailable");
    return;
end
% Metadata descriptors may originate in a filename. Suppress descriptors
% containing paths, URL schemes or address-shaped identifiers altogether.
if contains(s, ["/", "\", ":", "@"]) || ...
        ~isempty(regexp(char(s), '(^|[^0-9])[0-9]{1,3}(\.[0-9]{1,3}){3}([^0-9]|$)', 'once'))
    s = uiText("Withheld for privacy");
end
end
