function [bundle, bundleFile] = presentationBundle(rootDir, catalog)
%PRESENTATIONBUNDLE Latest saved, valid network analysis for the public launch.
%   Returns struct([]), "" when no matching saved run can be loaded. Missing,
%   unreadable and inconsistent catalog entries are skipped. No analysis,
%   fixture generation or fallback to the historical burglary dataset runs.
%   Metadata consistency is checked here; source authentication belongs to
%   acquisition/import, not to the presentation selector.
arguments
    rootDir (1,1) string
    catalog table = table()
end
bundle = struct([]);
bundleFile = "";
if nargin < 2
    try
        catalog = listDatasets(rootDir);
    catch
        return;
    end
end
required = ["format", "dataset_id", "bundle_file", "imported"];
if ~all(ismember(required, string(catalog.Properties.VariableNames)))
    return;
end
catalog = catalog(string(catalog.format) == "network_flow", :);
catalog = sortrows(catalog, 'imported', 'descend', 'MissingPlacement', 'last');
for k = 1:height(catalog)
    file = string(catalog.bundle_file(k));
    if ~isfile(file)
        file = fullfile(rootDir, file);
    end
    if ~isfile(file)
        continue;
    end
    try
        S = load(file, "bundle");
        if ~isfield(S, 'bundle') || ~validNetworkRun(S.bundle, string(catalog.dataset_id(k)))
            continue;
        end
        bundle = S.bundle;
        bundleFile = file;
        return;
    catch
        % A stale or unreadable saved run must not replace a usable one.
    end
end
end

function ok = validNetworkRun(b, datasetId)
ok = false;
if ~isstruct(b) || ~isscalar(b)
    return;
end
format = string(cfgGet(b, "meta.dataset.format", ""));
id = string(cfgGet(b, "meta.dataset.id", ""));
sha = string(cfgGet(b, "meta.dataset_blob_sha", ""));
if ~isscalar(format) || ismissing(format) || format ~= "network_flow" || ~isscalar(id) || ...
        ismissing(id) || strlength(id) == 0 || id ~= datasetId || ~isscalar(sha) || ismissing(sha) || ...
        isempty(regexp(char(sha), '^[0-9a-fA-F]{40}([0-9a-fA-F]{24})?$', 'once'))
    return;
end
valid = cfgGet(b, "validation.is_valid", false);
if ~isscalar(valid) || ~isequal(valid, true)
    return;
end
if ~isfield(b, 'entities') || ~istable(b.entities) || height(b.entities) == 0 || ...
        ~isfield(b, 'events') || ~istable(b.events) || height(b.events) == 0
    return;
end
ok = true;
end
