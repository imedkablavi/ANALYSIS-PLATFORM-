function tests = test_sequence
%TEST_SEQUENCE Token encoding, Markov transition model, novelty and n-grams.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir));
events = flattenBurglaryEvents(data);
[~, pe] = buildRelationTable(events, data.nodes.entity_id);
[tc.TestData.tokens, tc.TestData.thr] = encodeEventSequences(events, pe, struct());
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function tok = tokensOf(tc, e)
t = tc.TestData.tokens;
tok = t.token(t.entity_index == e)';
end

function testTokens(tc)
verifyEqual(tc, tokensOf(tc, 1), ["N0","RL","NF","SF"]);
verifyEqual(tc, tokensOf(tc, 2), ["N0","RL"]);
verifyEqual(tc, tokensOf(tc, 3), ["N0","RL","NF"]);
verifyEqual(tc, tokensOf(tc, 6), ["S0","SL","SL"]);
verifyEqual(tc, tokensOf(tc, 7), "S0");
verifyEqual(tc, tc.TestData.thr, 0.02, 'AbsTol', 1e-9);
end

function testPartnerNoveltyIsCausal(tc)
% entity 1 meets partner 2 in crimes 1 and 2: new, then repeat
t = tc.TestData.tokens;
s = t.group_state(t.entity_index == 1)';
verifyEqual(tc, s, ["N","R","N","S"]);
end

function testTransitionModelAndSurprisal(tc)
t = tc.TestData.tokens;
m = fitTransitionModel(t, 1);
verifyEqual(tc, m.n_transitions, 10);
a = m.alphabet;
verifyEqual(tc, m.counts(a == "N0", a == "RL"), 5);
verifyEqual(tc, m.P(a == "N0", a == "RL"), 6/17, 'AbsTol', 1e-12);
verifyEqual(tc, sum(m.P, 2), ones(numel(a), 1), 'AbsTol', 1e-12);
[es, t2] = scoreSequenceNovelty(t, m, 7);
expected = mean([-log2(6/17), -log2(3/14), -log2(2/13)]);
verifyEqual(tc, es.seq_surprisal_mean(1), expected, 'AbsTol', 1e-12);
verifyEqual(tc, es.seq_surprisal_max(1), -log2(2/13), 'AbsTol', 1e-12);
verifyTrue(tc, isnan(es.seq_surprisal_mean(7)));
verifyEqual(tc, es.new_partner_rate([1 6 7])', [0.5 0 0]);
verifyTrue(tc, all(isnan(t2.surprisal_bits(t2.seq_pos == 1))));
end

function testTrainingMaskExcludesRows(tc)
t = tc.TestData.tokens;
m = fitTransitionModel(t, 1, t.entity_index ~= 1);
verifyEqual(tc, m.n_transitions, 7);
end

function testNgrams(tc)
ng = mineSequenceNgrams(tc.TestData.tokens, 2, 2);
row = ng(ng.ngram == "N0>RL", :);
verifyEqual(tc, row.occurrences, 5);
verifyEqual(tc, row.support, 5);
verifyTrue(tc, row.is_frequent);
verifyEqual(tc, ng.ngram(1), "N0>RL");
verifyFalse(tc, any(ng.ngram == "SF>N0" | ng.ngram == "SL>S0"));   % never across entities
end
