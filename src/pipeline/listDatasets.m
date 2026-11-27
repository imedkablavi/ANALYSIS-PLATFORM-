function catalog = listDatasets(rootDir)
%LISTDATASETS Datasets analysed so far (outputs/datasets/catalog.json).
%
%   CATALOG = LISTDATASETS(ROOTDIR) returns a table with one row per
%   registered dataset: dataset_id, name, format, n_entities, n_events,
%   imported (datetime), bundle_file, source_file. Zero rows when nothing
%   has been imported yet. The catalog lives under outputs/ (git-ignored):
%   it records local analyses, it is not part of the repository.

arguments
    rootDir (1,1) string
end

catalog = table(strings(0,1), strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), ...
    NaT(0,1), strings(0,1), strings(0,1), 'VariableNames', {'dataset_id','name', ...
    'format','n_entities','n_events','imported','bundle_file','source_file'});
file = catalogFile(rootDir);
if ~isfile(file)
    return;
end
raw = jsondecode(fileread(file));
if isempty(raw)
    return;
end
if iscell(raw)
    raw = [raw{:}];
end
catalog = table(string({raw.dataset_id})', string({raw.name})', string({raw.format})', ...
    [raw.n_entities]', [raw.n_events]', ...
    datetime(string({raw.imported})', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss'), ...
    string({raw.bundle_file})', string({raw.source_file})', 'VariableNames', ...
    {'dataset_id','name','format','n_entities','n_events','imported','bundle_file','source_file'});
catalog = sortrows(catalog, 'imported', 'descend');
end

function f = catalogFile(rootDir)
f = fullfile(rootDir, "outputs", "datasets", "catalog.json");
end
