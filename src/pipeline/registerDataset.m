function catalog = registerDataset(rootDir, entry)
%REGISTERDATASET Add or replace a dataset entry in outputs/datasets/catalog.json.
%
%   CATALOG = REGISTERDATASET(ROOTDIR, ENTRY) with ENTRY fields dataset_id,
%   name, format, n_entities, n_events, imported (datetime), bundle_file,
%   source_file. An entry with the same dataset_id (same name and file
%   content) is replaced, so re-analysing a dataset does not duplicate it.

arguments
    rootDir (1,1) string
    entry (1,1) struct
end

catalog = listDatasets(rootDir);
catalog(catalog.dataset_id == string(entry.dataset_id), :) = [];
row = {string(entry.dataset_id), string(entry.name), string(entry.format), ...
    double(entry.n_entities), double(entry.n_events), entry.imported, ...
    string(entry.bundle_file), string(entry.source_file)};
catalog = [catalog; cell2table(row, 'VariableNames', catalog.Properties.VariableNames)];

items = table2struct(catalog);
for k = 1:numel(items)
    items(k).imported = char(items(k).imported, 'yyyy-MM-dd''T''HH:mm:ss');
end
file = fullfile(rootDir, "outputs", "datasets", "catalog.json");
writeTextFile(file, jsonencode(items));
catalog = listDatasets(rootDir);
end
