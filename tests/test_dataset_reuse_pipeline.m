function tests = test_dataset_reuse_pipeline
%TEST_DATASET_REUSE_PIPELINE New imports adapt and isolate saved analysis state.
tests = functiontests(localfunctions);
end

function setup(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
end

function teardown(tc)
runLog("close");
rmdir(tc.TestData.dir, 's');
end

function testNewNetworkFilesAreIndependentAndRepeatable(tc)
a = fullfile(tc.TestData.dir, 'capture_a.csv');
b = fullfile(tc.TestData.dir, 'capture_b.csv');
writeTextFile(a, joinStrings(["origin,peer,moment"; ...
    "10.0.0.1,10.0.0.2,01|11|2025 10:00:00"; ...
    "10.0.0.1,10.0.0.2,01|11|2025 10:01:00"; ...
    "10.0.0.1,10.0.0.2,01|11|2025 10:02:00"; ...
    "10.0.0.1,10.0.0.2,01|11|2025 10:03:00"], newline));
writeTextFile(b, joinStrings(["origin,peer,moment"; ...
    "10.1.0.1,10.1.0.2,02|02|2024 09:00:00"; ...
    "10.1.0.1,10.1.0.3,02|02|2024 09:01:00"; ...
    "10.1.0.2,10.1.0.3,02|02|2024 09:02:00"], newline));
o = struct('root_dir', tc.TestData.dir, 'format', "network_flow", ...
    'profile', "generic_network_flow", 'mapping', struct('src', "origin", ...
    'dst', "peer", 'time', "moment"), 'time_formats', "dd|MM|yyyy HH:mm:ss", ...
    'use_iforest', false, 'progress', @failingProgress);
first = analyzeDataset(a, o);
second = analyzeDataset(b, o);
repeat = analyzeDataset(a, o);
verifyNotEqual(tc, first.meta.dataset.id, second.meta.dataset.id);
verifyEqual(tc, repeat.meta.dataset.id, first.meta.dataset.id);
verifyEqual(tc, first.config.temporal.series_start, datetime(2025,11,1,10,0,0));
verifyEqual(tc, second.config.temporal.series_start, datetime(2024,2,2,9,0,0));
verifyEqual(tc, first.config.temporal.bin, "minute");
verifyEqual(tc, first.entities, repeat.entities);
verifyEqual(tc, height(first.entities), 2);
verifyEqual(tc, height(second.entities), 3);
verifyFalse(tc, first.meta.dataset.has_labels);
verifyFalse(tc, isfield(first.ground_truth, 'evaluation'));
verifyFalse(tc, ismember('truth', first.entities.Properties.VariableNames));
verifyTrue(tc, isfile(fullfile(tc.TestData.dir, first.config.output.bundle_file)));
verifyTrue(tc, isfile(fullfile(tc.TestData.dir, second.config.output.bundle_file)));
catalog = listDatasets(tc.TestData.dir);
verifyEqual(tc, height(catalog), 2);
verifyEqual(tc, numel(unique(catalog.dataset_id)), 2);
end

function testExplicitEventAndEdgeMappingsAndNumericTimes(tc)
eventFile = fullfile(tc.TestData.dir, 'custom_events.csv');
edgeFile = fullfile(tc.TestData.dir, 'custom_edges.csv');
writeTextFile(eventFile, "who,when" + newline + "alpha,1700000000" + newline + ...
    "alpha,1700000060" + newline + "alpha,1700000120");
writeTextFile(edgeFile, "left,right,when" + newline + "a,b,1600000000" + newline + ...
    "a,c,1600000060" + newline + "b,c,1600000120");
o = struct('root_dir', tc.TestData.dir, 'format', "event_csv", ...
    'mapping', struct('entity', "who", 'time', "when"), ...
    'time_unit', "posix_s", 'use_iforest', false);
events = analyzeDataset(eventFile, o);
o.format = "edge_csv";
o.mapping = struct('source', "left", 'target', "right", 'time', "when");
edges = analyzeDataset(edgeFile, o);
verifyEqual(tc, events.meta.dataset.format, "event_csv");
verifyEqual(tc, edges.meta.dataset.format, "edge_csv");
verifyEqual(tc, numel(unique(events.events.crime_id)), 3);
verifyEqual(tc, numel(unique(edges.events.crime_id)), 3);
verifyEqual(tc, height(events.entities), 1);
verifyEqual(tc, height(edges.entities), 3);
verifyFalse(tc, any(isnat(events.events.event_time)));
verifyFalse(tc, isfield(events.ground_truth, 'evaluation'));
verifyEqual(tc, height(listDatasets(tc.TestData.dir)), 2);
end

function testInvalidOptionsAndBinaryDoNotBypassValidation(tc)
verifyError(tc, @() validateImportOptions(struct('first_row', 0)), "MOSAIC:InvalidImportOptions");
verifyError(tc, @() validateImportOptions(struct('max_rows', NaN)), "MOSAIC:InvalidImportOptions");
verifyError(tc, @() validateImportOptions(struct('time_formats', ["a", missing])), "MOSAIC:InvalidImportOptions");
file = fullfile(tc.TestData.dir, 'binary.csv');
fid = fopen(file, 'wb');
fwrite(fid, uint8([80 75 3 4 0 0 8]));
fclose(fid);
verifyError(tc, @() analyzeDataset(file, struct('root_dir', tc.TestData.dir, ...
    'format', "edge_csv", 'mapping', struct('source', "a", 'target', "b", 'time', "t"))), ...
    "MOSAIC:UnsupportedFormat");
end

function testFailedAnalysisClosesLog(tc)
file = fullfile(tc.TestData.dir, 'unmapped.csv');
writeTextFile(file, "foo,bar" + newline + "a,b");
verifyError(tc, @() analyzeDataset(file, struct('root_dir', tc.TestData.dir)), "MOSAIC:MappingMissing");
logs = dir(fullfile(tc.TestData.dir, 'outputs', 'logs', '*.log'));
verifyEqual(tc, numel(logs), 1);
p = fullfile(string(logs(1).folder), string(logs(1).name));
before = fileread(p);
runLog("after failure: must not append to previous run");
verifyEqual(tc, fileread(p), before);
end

function testAdaptedYearWindowsHaveNoDuplicateClosingEdge(tc)
ds.events = table([datetime(2022,1,1);datetime(2025,1,15)], 'VariableNames', {'event_time'});
[cfg, ~] = configureForDataset(projectConfig(), ds);
verifyEqual(tc, cfg.temporal.series_end, datetime(2025,1,1));
verifyTrue(tc, all(diff(cfg.temporal.snapshot_starts) > seconds(0)));
verifyEqual(tc, cfg.temporal.snapshot_starts(end), cfg.temporal.series_end);
end

function failingProgress(~, ~)
error("MOSAIC:ClosedProgressDialog", "Test callback is intentionally unavailable.");
end
