function tests = test_loader_and_events
%TEST_LOADER_AND_EVENTS JSON loading, ID restoration and event flattening.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testMissingFile(tc)
verifyError(tc, @() loadBurglaryNetwork("does-not-exist.json"), "MOSAIC:DataFileNotFound");
end

function testInvalidJson(tc)
f = fullfile(tc.TestData.dir, "broken.json");
writeTextFile(f, "{""nodes"": [");
verifyError(tc, @() loadBurglaryNetwork(f), "MOSAIC:InvalidJSON");
end

function testSchemaMismatch(tc)
f = fullfile(tc.TestData.dir, "noLinks.json");
writeTextFile(f, "{""directed"": true, ""multigraph"": false, ""graph"": {}, ""nodes"": []}");
verifyError(tc, @() loadBurglaryNetwork(f), "MOSAIC:SchemaMismatch");
end

function testFixtureCounts(tc)
f = makeSyntheticNetworkJson(tc.TestData.dir);
data = loadBurglaryNetwork(f);
verifyEqual(tc, height(data.nodes), 7);
verifyEqual(tc, height(data.links), 10);
verifyEqual(tc, data.nodes.crime_count', [4 2 3 2 2 3 1]);
verifyEqual(tc, data.nodes.detail_count, data.nodes.crime_count);
verifyTrue(tc, data.directed);
end

function testCrimeIdsRestoredFromListCid(tc)
% jsondecode turns "CID#2" into the field name "CID_2"; the original ID
% must be restored, otherwise crime IDs disagree with list_cid.
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
events = flattenBurglaryEvents(data);
verifyEqual(tc, height(events), 17);
verifyTrue(tc, all(startsWith(events.crime_id, "CID#")));
verifyTrue(tc, all(events.id_restored));
verifyEqual(tc, numel(unique(events.crime_id)), 10);
verifyEqual(tc, sort(unique(events.crime_num))', 1:10);
end

function testEventValuesAndOrder(tc)
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
events = flattenBurglaryEvents(data);
e1 = events(events.entity_id == "OID#1", :);
verifyEqual(tc, e1.crime_id', ["CID#1","CID#2","CID#3","CID#4"]);
verifyEqual(tc, e1.event_time', datetime([2015 2015 2015 2015], [1 1 2 3], [1 11 10 12]));
verifyEqual(tc, e1.num_offenders', [2 2 2 1]);
verifyEqual(tc, e1.x(4), 0.9, 'AbsTol', 1e-12);
% same-day events are ordered by numeric crime ID
e6 = events(events.entity_id == "OID#6", :);
verifyEqual(tc, e6.crime_id', ["CID#7","CID#8","CID#9"]);
end

function testSingleCrimeNode(tc)
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
events = flattenBurglaryEvents(data);
verifyEqual(tc, events.crime_id(events.entity_id == "OID#7"), "CID#10");
end

function testMalformedDateBecomesNaT(tc)
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir, "bad_date"));
events = flattenBurglaryEvents(data);
verifyEqual(tc, nnz(isnat(events.event_time)), 1);
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir, "missing_date"));
events = flattenBurglaryEvents(data);
verifyEqual(tc, nnz(isnat(events.event_time)), 1);
end

function testRealArtifactIfPresent(tc)
root = fileparts(fileparts(mfilename('fullpath')));
f = fullfile(root, "data", "raw", "israel_lea_inp_burglary_offender_id_network.json");
assumeTrue(tc, isfile(f), "Real dataset not installed; skipped.");
data = loadBurglaryNetwork(f);
events = flattenBurglaryEvents(data);
% Values verified in docs/DATASET_SCHEMA_INSPECTION.md
verifyEqual(tc, height(data.nodes), 17237);
verifyEqual(tc, height(data.links), 21302);
verifyEqual(tc, height(events), 34156);
verifyEqual(tc, numel(unique(events.crime_id)), 24087);
verifyTrue(tc, all(events.id_restored));
end
