function tests = test_relations_and_graph
%TEST_RELATIONS_AND_GRAPH Relation derivation, graph construction and graph features.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
tc.TestData.data = data;
tc.TestData.events = flattenBurglaryEvents(data);
[tc.TestData.rel, tc.TestData.pe] = buildRelationTable(tc.TestData.events, data.nodes.entity_id);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testRelationsMatchSharedCrimes(tc)
rel = tc.TestData.rel;
verifyEqual(tc, height(rel), 5);
verifyEqual(tc, height(tc.TestData.pe), 9);   % 1+1+1+3+3 pair-crime rows
verifyTrue(tc, all(rel.a_index < rel.b_index));
key = rel.a_index * 10 + rel.b_index;
[~, o] = sort(key);
verifyEqual(tc, [rel.a_index(o) rel.b_index(o) rel.weight(o)], ...
    [1 2 2; 1 3 1; 3 4 2; 3 5 2; 4 5 2]);
r12 = rel(rel.a_index == 1 & rel.b_index == 2, :);
verifyEqual(tc, r12.first_time, datetime(2015,1,1));
verifyEqual(tc, r12.last_time, datetime(2015,1,11));
verifyEqual(tc, r12.span_days, 10);
end

function testDerivedWeightsEqualFileWeights(tc)
data = tc.TestData.data;
rel = tc.TestData.rel;
[~, s] = ismember(data.links.source_id, data.nodes.entity_id);
[~, t] = ismember(data.links.target_id, data.nodes.entity_id);
k = min(s,t) * 10 + max(s,t);
[~, loc] = ismember(k, rel.a_index * 10 + rel.b_index);
verifyEqual(tc, rel.weight(loc), data.links.weight);
end

function testCrimeTable(tc)
c = buildCrimeTable(tc.TestData.events);
verifyEqual(tc, height(c), 10);
verifyTrue(tc, all(c.time_consistent & c.xy_consistent & c.num_consistent));
verifyEqual(tc, c.n_offenders_observed, c.num_offenders);
end

function testUndirectedGraphAndFeatures(tc)
ids = tc.TestData.data.nodes.entity_id;
G = buildOffenderGraph(tc.TestData.rel, ids);
verifyClass(tc, G, 'graph');
verifyEqual(tc, numnodes(G), 7);
verifyEqual(tc, numedges(G), 5);
gf = computeGraphFeatures(G);
verifyEqual(tc, gf.entity_id, ids);
verifyEqual(tc, gf.degree', [2 1 3 2 2 0 0]);
verifyEqual(tc, gf.strength', [3 2 5 4 4 0 0]);
verifyEqual(tc, gf.max_tie_weight', [2 2 2 2 2 0 0]);
verifyEqual(tc, gf.clustering_coef', [0 0 1/3 1 1 0 0], 'AbsTol', 1e-12);
verifyEqual(tc, gf.core_number', [1 1 2 2 2 0 0]);
verifyEqual(tc, gf.component_size', [5 5 5 5 5 1 1]);
verifyEqual(tc, gf.is_cut_vertex', [1 0 1 0 0 0 0]);
b = gf.betweenness;
verifyGreaterThan(tc, b(3), b(1));
verifyGreaterThan(tc, b(1), 0);
verifyEqual(tc, b([2 4 5 6 7])', zeros(1,5));
end

function testCoreNumbersOnKnownGraph(tc)
% 4-clique {1,2,3,4} plus a pendant 5 attached to 1
A = sparse([1 1 1 2 2 3 1], [2 3 4 3 4 4 5], 1, 5, 5);
A = A + A';
verifyEqual(tc, computeCoreNumbers(A)', [3 3 3 3 1]);
end

function testSnapshotAndDynamics(tc)
pe = tc.TestData.pe;
snap = buildGraphSnapshot(pe, datetime(2015,1,1), datetime(2015,2,1));
% January: crimes 1, 2 (pair 1-2) and 5 (pairs 3-4, 3-5, 4-5)
verifyEqual(tc, height(snap), 4);
verifyEqual(tc, snap.weight(snap.a_index == 1 & snap.b_index == 2), 2);
starts = datetime(2015, [1 2 3 4], 1)';
st = computeDynamicGraphStats(pe, tc.TestData.events, starts);
verifyEqual(tc, st.edges', [4 4 0]);         % Feb: 1-3, 3-4, 3-5, 4-5
verifyEqual(tc, st.new_edges', [4 1 0]);
verifyEqual(tc, st.persistent_edges', [0 3 0]);
verifyEqual(tc, st.edge_persistence(2), 3/4);
verifyEqual(tc, st.largest_component', [3 4 0]);
end
