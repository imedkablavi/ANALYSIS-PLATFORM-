function tests = test_graph_work_budget
tests = functiontests(localfunctions);
end
function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end
function testWorkBudgetSkipsDenseComponentBelowNodeLimit(tc)
G = graph([1 1 1 2 2 3], [2 3 4 3 4 4], ones(1,6), 4);
cfg.graph.max_betweenness_nodes = 100;
cfg.graph.max_betweenness_work = 23; % complete K4: 4 nodes * 6 edges = 24
[F, notes] = computeGraphFeatures(G, cfg);
verifyTrue(tc, all(isnan(F.betweenness)));
verifyTrue(tc, any(contains(notes, 'work limit')));
cfg.graph.max_betweenness_work = 24;
F = computeGraphFeatures(G, cfg);
verifyEqual(tc, F.betweenness, zeros(4,1));
end
function testBudgetUsesComponentsRatherThanGlobalProduct(tc)
G = graph([1 2 4 5], [2 3 5 6], ones(1,4), 6);
cfg.graph.max_betweenness_work = 12; % two components each 3*2, not 6*4
[F, notes] = computeGraphFeatures(G, cfg);
verifyTrue(tc, all(isfinite(F.betweenness)));
verifyEmpty(tc, notes);
end
