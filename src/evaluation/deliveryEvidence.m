function out = deliveryEvidence(action, value)
%DELIVERYEVIDENCE JSON-safe evidence, source fingerprints and delivery gates.
%   fingerprints records relative file names, bytes and Git-blob SHA-1;
%   contents, entity IDs and environment variables are never included.
arguments
    action (1,1) string
    value
end
switch action
    case "json_safe"
        out = jsonSafe(value);
    case "fingerprints"
        out = fingerprints(string(value), false);
    case "source_fingerprints"
        out = fingerprints(string(value), true);
    case "completion_status"
        if value.quick || value.tests_skipped > 0
            out = "PARTIAL";
        else
            out = "AUTOMATED_CHECKS_PASSED";
        end
    case "require_iforest"
        b = value;
        if ~isfield(b, 'anomaly') || ~isfield(b.anomaly, 'iforest') || ...
                ~isfield(b.anomaly.iforest, 'model') || ...
                ~isa(b.anomaly.iforest.model, 'IsolationForest')
            error("MOSAIC:ActualForestRequired", ...
                "Delivery requires a fitted MATLAB IsolationForest model.");
        end
        score = b.anomaly.iforest.score;
        eligible = b.anomaly.eligible;
        if ~any(eligible) || numel(score) ~= numel(eligible) || ...
                any(~isfinite(score(eligible)))
            error("MOSAIC:ForestScoresRequired", ...
                "Delivery requires finite Isolation Forest scores for eligible hosts.");
        end
        out = true;
    otherwise
        error("MOSAIC:EvidenceAction", "Unknown evidence action.");
end
end

function out = jsonSafe(value)
if isdatetime(value)
    value.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSS';
    out = string(value);
elseif isduration(value) || iscalendarduration(value)
    out = string(value);
elseif isstruct(value)
    out = value;
    names = fieldnames(value);
    for k = 1:numel(value)
        for j = 1:numel(names)
            out(k).(names{j}) = jsonSafe(value(k).(names{j}));
        end
    end
elseif iscell(value)
    out = cellfun(@jsonSafe, value, 'UniformOutput', false);
elseif istable(value)
    out = jsonSafe(table2struct(value));
elseif isnumeric(value) || islogical(value) || ischar(value) || isstring(value)
    out = value;
else
    error("MOSAIC:EvidenceType", "Unsupported evidence value type: %s", class(value));
end
end

function records = fingerprints(root, sourceOnly)
files = dir(fullfile(root, '**', '*'));
files = files(~[files.isdir]);
if sourceOnly
    keep = false(numel(files), 1);
    for j = 1:numel(files)
        [~, ~, extension] = fileparts(files(j).name);
        keep(j) = ismember(lower(string(extension)), ...
            [".m", ".py", ".json", ".yml", ".yaml", ".md"]) && ...
            ~contains(string(files(j).folder), "__pycache__");
    end
    files = files(keep);
end
records = repmat(struct('file', "", 'bytes', 0, 'git_blob_sha1', ""), numel(files), 1);
for k = 1:numel(files)
    path = fullfile(string(files(k).folder), string(files(k).name));
    [~, sha] = verifyGitBlobSha(path);
    records(k).file = extractAfter(path, strlength(root) + 1);
    records(k).bytes = files(k).bytes;
    records(k).git_blob_sha1 = sha;
end
if ~isempty(records)
    [~, order] = sort([records.file]);
    records = records(order);
end
end
