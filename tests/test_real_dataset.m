function tests = test_real_dataset
%TEST_REAL_DATASET Regression test of the MATLAB pipeline against independent values.
%
%   Expected values come from scripts/reference/audit_dataset_reference.py
%   (Python stdlib + NetworkX), an independent implementation run during the
%   2026-09-30 audit on the artifact with blob SHA
%   3afe9cbb4e313fb056f1b115c92a3f750f4698b9. Skipped when the dataset is
%   not installed in data/raw/.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
f = fullfile(root, "data", "raw", "israel_lea_inp_burglary_offender_id_network.json");
assumeTrue(tc, isfile(f), "Real dataset not installed; skipped.");
data = loadBurglaryNetwork(f);
tc.TestData.data = data;
tc.TestData.events = flattenBurglaryEvents(data);
[tc.TestData.rel, tc.TestData.pe] = buildRelationTable(tc.TestData.events, data.nodes.entity_id);
end

function testValidationFacts(tc)
r = validateBurglaryNetwork(tc.TestData.data, tc.TestData.events, projectConfig());
verifyTrue(tc, r.is_valid);
s = r.summary;
verifyEqual(tc, [s.node_count s.link_count s.event_count s.unique_crime_count], ...
    [17237 21302 34156 24087]);
verifyEqual(tc, s.undirected_relation_count, 10651);
verifyEqual(tc, s.isolated_node_count, 7597);
verifyTrue(tc, s.symmetric_links);
verifyTrue(tc, s.weight_equals_shared_crimes);
verifyTrue(tc, s.day_resolution_only);
verifyEqual(tc, s.date_min, datetime(2010,12,1));
verifyEqual(tc, s.date_max, datetime(2020,9,28));
verifyEqual(tc, s.events_before_series_start, 91);
verifyEqual(tc, s.day1_excess_ratio, 1.177, 'AbsTol', 5e-4);
end

function testRelationsAndGraph(tc)
verifyEqual(tc, height(tc.TestData.rel), 10651);
verifyEqual(tc, height(tc.TestData.pe), 15422);
G = buildOffenderGraph(tc.TestData.rel, tc.TestData.data.nodes.entity_id);
gf = computeGraphFeatures(G);
verifyEqual(tc, numel(unique(gf.component_id)), 10468);
verifyEqual(tc, max(gf.component_size), 518);
verifyEqual(tc, max(gf.core_number), 12);
verifyEqual(tc, nnz(gf.is_cut_vertex), 1156);
end

function testEligibilityAndTokens(tc)
ids = tc.TestData.data.nodes.entity_id;
f = buildBehaviorFeatures(tc.TestData.events, ids, tc.TestData.rel, projectConfig());
verifyEqual(tc, [nnz(f.event_count >= 2) nnz(f.event_count >= 3) nnz(f.event_count >= 5)], ...
    [5791 3260 1395]);
[tok, thr] = encodeEventSequences(tc.TestData.events, tc.TestData.pe, projectConfig());
verifyEqual(tc, thr, 0.006585711419618685, 'AbsTol', 1e-12);
expected = ["N0" "NF" "NL" "RF" "RL" "S0" "SF" "SL"; ...
            "8522" "2256" "1335" "2148" "2493" "8715" "4055" "4632"];
for k = 1:size(expected, 2)
    verifyEqual(tc, nnz(tok.token == expected(1,k)), double(expected(2,k)), ...
        "token " + expected(1,k));
end
end
