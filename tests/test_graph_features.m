function tests = test_graph_features
tests = functiontests(localfunctions);
end

function testFeatureJoinHasOneEntityPerNode(testCase)
assumeTrue(testCase, isfile(fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json")));

addpath(genpath("src"));

data = loadBurglaryNetwork(fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json")));
G = buildOffenderGraph(data);
gf = computeGraphFeatures(G);

verifyEqual(testCase, height(gf), numnodes(G));
verifyEqual(testCase, numel(unique(gf.entity_id)), height(gf));
verifyTrue(testCase, all(gf.total_degree == gf.out_degree + gf.in_degree));
end
