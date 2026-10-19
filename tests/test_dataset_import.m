function tests = test_dataset_import
%TEST_DATASET_IMPORT Importing external datasets (event CSV, temporal edge list).
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);

% Event participation CSV: 4 people, 5 events, real-looking coordinates.
% Event E3 has three participants; row 7 has no person (must be dropped).
T = table(["alice";"bob";"alice";"carol";"bob";"dave";"";"carol";"alice";"bob"], ...
    ["E1";"E1";"E2";"E3";"E3";"E3";"E4";"E4";"E5";"E5"], ...
    datetime(2015, [1;1;3;5;5;5;7;7;9;9], 1), ...
    [41.0;41.0;41.2;41.4;41.4;41.4;40.0;41.6;41.8;41.8], ...
    [29.0;29.0;29.2;29.4;29.4;29.4;28.0;29.6;29.8;29.8], ...
    'VariableNames', {'person','incident_id','date','lat','lon'});
tc.TestData.eventCsv = fullfile(tc.TestData.dir, "incidents.csv");
writetable(T, tc.TestData.eventCsv);

% Headerless SNAP-style temporal edge list with a comment line.
edges = "# comment line" + newline + ...
    "1 2 1420070400" + newline + ...   % 2015-01-01
    "2 3 1422748800" + newline + ...   % 2015-02-01
    "1 2 1425168000" + newline + ...   % 2015-03-01
    "3 3 1427846400" + newline;        % 2015-04-01 self-interaction
tc.TestData.edgeTxt = fullfile(tc.TestData.dir, "edges.txt");
writeTextFile(tc.TestData.edgeTxt, edges);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testInspectEventCsv(tc)
info = inspectDatasetFile(tc.TestData.eventCsv);
verifyEqual(tc, info.format, "event_csv");
verifyFalse(tc, info.needs_mapping);
verifyEqual(tc, [info.mapping.entity info.mapping.event info.mapping.time ...
    info.mapping.x info.mapping.y], ["person","incident_id","date","lon","lat"]);
end

function testInspectHeaderlessEdgeList(tc)
info = inspectDatasetFile(tc.TestData.edgeTxt);
verifyEqual(tc, info.format, "edge_csv");
verifyFalse(tc, info.needs_mapping);
verifyEqual(tc, [info.mapping.source info.mapping.target info.mapping.time], ...
    info.columns(1:3));
end

function testInspectUnsupportedJson(tc)
f = fullfile(tc.TestData.dir, "other.json");
writeTextFile(f, "{""a"": 1}");
info = inspectDatasetFile(f);
verifyEqual(tc, info.format, "unknown");
verifyTrue(tc, contains(info.message, "Unsupported JSON"));
end

function testImportEventCsvIsPseudonymizedAndScaled(tc)
ds = importDataset(tc.TestData.eventCsv, struct('name', "Test incidents"));
verifyEqual(tc, ds.meta.format, "event_csv");
verifyEqual(tc, ds.meta.n_entities, 4);            % alice, bob, carol, dave
verifyEqual(tc, ds.meta.n_events, 5);
verifyEqual(tc, height(ds.events), 9);              % 10 rows - 1 without person
verifyTrue(tc, all(startsWith(ds.events.entity_id, "ENT")));
verifyFalse(tc, any(contains(ds.events.entity_id, ["alice","bob","carol","dave"])));
verifyTrue(tc, any(contains(ds.meta.import_notes, "dropped")));
% coordinates scaled over the kept rows: lon 29.0..29.8, lat 41.0..41.8
verifyEqual(tc, [min(ds.events.x) max(ds.events.x) min(ds.events.y) max(ds.events.y)], ...
    [0 1 0 1], 'AbsTol', 1e-12);
% E3 has three participants
e3 = ds.events(ds.events.crime_num == 3, :);
verifyEqual(tc, e3.num_offenders, [3; 3; 3]);
verifyTrue(tc, ds.meta.has_coordinates);
verifyFalse(tc, ds.meta.links_provided);
verifyTrue(tc, startsWith(ds.meta.id, "test-incidents-"));
end

function testValidationMarksLinkChecksNotApplicable(tc)
ds = importDataset(tc.TestData.eventCsv);
r = validateBurglaryNetwork(ds, ds.events, struct());
verifyTrue(tc, r.is_valid);
v02 = r.checks(r.checks.check_id == "V02", :);
verifyEqual(tc, v02.severity, "info");
verifyTrue(tc, startsWith(v02.message, "Not applicable"));
v12 = r.checks(r.checks.check_id == "V12", :);
verifyTrue(tc, v12.passed);                         % expected type "entity"
end

function testImportEdgeList(tc)
ds = importDataset(tc.TestData.edgeTxt);
verifyEqual(tc, ds.meta.format, "edge_csv");
verifyEqual(tc, ds.meta.n_events, 4);
verifyEqual(tc, ds.meta.n_entities, 3);
verifyFalse(tc, ds.meta.has_coordinates);
verifyTrue(tc, any(contains(ds.meta.import_notes, "self-interactions")));
verifyEqual(tc, ds.meta.n_rows, 4);                 % source rows, not participations
verifyEqual(tc, height(ds.events), 7);              % 3 two-party rows + 1 self-interaction
verifyEqual(tc, max(ds.events.num_offenders), 2);
verifyEqual(tc, ds.events.event_time(1), datetime(2015,1,1));
[rel, ~] = buildRelationTable(ds.events, ds.nodes.entity_id);
% ties: 1-2 (two shared events), 2-3 (one)
verifyEqual(tc, sortrows([rel.a_index rel.b_index rel.weight]), [1 2 2; 2 3 1]);
r = validateBurglaryNetwork(ds, ds.events, struct());
verifyTrue(tc, r.is_valid);
v47 = r.checks(r.checks.check_id == "V47", :);
verifyTrue(tc, startsWith(v47.message, "Not applicable"));
end

function testExplicitMappingAndMissingColumnError(tc)
bad = struct('entity', "nope", 'time', "date");
verifyError(tc, @() importDataset(tc.TestData.eventCsv, struct('mapping', bad)), ...
    "MOSAIC:MappingMissing");
ds = importDataset(tc.TestData.eventCsv, struct('mapping', struct('event', ""), ...
    'pseudonymize', false));
verifyEqual(tc, ds.meta.n_events, 9);               % no event column: one event per row
verifyEqual(tc, ds.meta.n_rows, 10);
verifyTrue(tc, all(ds.events.num_offenders == 1));
verifyTrue(tc, any(ds.events.entity_id == "alice"));
end

function testConfigureForShortAndLongSpans(tc)
cfg = projectConfig();
ds = importDataset(tc.TestData.eventCsv);           % Jan-Sep 2015
[c1, notes] = configureForDataset(cfg, ds);
verifyEqual(tc, c1.temporal.bin, "week");
verifyEqual(tc, c1.temporal.anomaly_method, "rolling");
verifyEqual(tc, c1.temporal.series_start, datetime(2015,1,1));
verifyEqual(tc, c1.temporal.series_end, datetime(2015,9,1));
verifyEqual(tc, c1.temporal.snapshot_years, 2015);
verifyNotEmpty(tc, notes);
ds.events.event_time(end) = datetime(2020,6,15);    % now spans 2015-2020
c2 = configureForDataset(cfg, ds);
verifyEqual(tc, c2.temporal.bin, "month");
verifyEqual(tc, c2.temporal.anomaly_method, cfg.temporal.anomaly_method);
verifyEqual(tc, c2.temporal.snapshot_years, 2015:2020);
end

function testPrimaryConfigurationUnchanged(tc)
cfg = projectConfig();
ds.meta.sha = cfg.data.expected_blob_sha;
c = configureForDataset(cfg, ds);
verifyEqual(tc, c, cfg);
end

function testAnalyzeDatasetEndToEndAndCatalog(tc)
root = fullfile(tc.TestData.dir, "root");
mkdir(root);
f = fullfile(tc.TestData.dir, "busy.csv");
% 6 people, 36 monthly events (2015-2017): everyone gets >= 3 events
people = ["p1","p2","p3","p4","p5","p6"];
rows = {};
for k = 1:36
    a = people(mod(k - 1, 6) + 1);
    b = people(mod(k, 6) + 1);
    d = datetime(2015, k, 3);
    rows(end+1, :) = {a, "ev" + k, d, 41 + k / 100, 29 + mod(k, 5) / 10}; %#ok<AGROW>
    rows(end+1, :) = {b, "ev" + k, d, 41 + k / 100, 29 + mod(k, 5) / 10}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'person','event_id','timestamp','lat','lon'});
writetable(T, f);
calls = 0;
    function onProgress(~, ~)
        calls = calls + 1;
    end
b = analyzeDataset(f, struct('root_dir', root, 'name', "Busy", 'use_iforest', false, ...
    'progress', @onProgress));
verifyEqual(tc, b.meta.dataset.format, "event_csv");
verifyEqual(tc, height(b.entities), 6);
verifyEqual(tc, nnz(b.entities.eligible), 6);
verifyGreaterThan(tc, calls, 5);
verifyTrue(tc, isfile(fullfile(root, "outputs", "datasets", b.meta.dataset.id, "analysis_bundle.mat")));
cat1 = listDatasets(root);
verifyEqual(tc, height(cat1), 1);
verifyEqual(tc, cat1.name, "Busy");
analyzeDataset(f, struct('root_dir', root, 'name', "Busy", 'use_iforest', false));
verifyEqual(tc, height(listDatasets(root)), 1);     % same file + name: replaced, not duplicated
S = b.explanations.summary;
if height(S) > 0
    verifyTrue(tc, contains(S.evidence_text(1), "entities with >= 3 recorded events"));
end
end
