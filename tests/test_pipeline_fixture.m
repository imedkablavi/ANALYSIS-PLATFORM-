function tests = test_pipeline_fixture
%TEST_PIPELINE_FIXTURE End-to-end pipeline, app-support functions and experiment smoke run.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
cfg = projectConfig();
cfg.anomaly.min_events = 3;
f = makeSyntheticNetworkJson(tc.TestData.dir);
tc.TestData.cfg = cfg;
tc.TestData.bundle = runAnalysisPipeline(cfg, tc.TestData.dir, ...
    struct('data_file', f, 'save', false, 'use_iforest', false));
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function testBundleStructure(tc)
b = tc.TestData.bundle;
for f = ["meta","validation","entities","events","crimes","relations","pairEvents", ...
        "graph","registry","sequence","temporal","spatial","dynamicGraph", ...
        "patterns","anomaly","explanations"]
    verifyTrue(tc, isfield(b, f), "missing bundle field " + f);
end
verifyEqual(tc, height(b.entities), 7);
verifyEqual(tc, b.entities.eligible', logical([1 0 1 0 0 1 0]));
verifyTrue(tc, b.validation.is_valid);
verifyFalse(tc, b.meta.iforest_used);
verifyTrue(tc, all(ismember(["degree","burstiness","seq_surprisal_mean"], ...
    string(b.entities.Properties.VariableNames))));
end

function testEntityContextLinksAllLayers(tc)
b = tc.TestData.bundle;
ctx = getEntityContext(b, 1);
verifyEqual(tc, height(ctx.events), 4);
verifyEqual(tc, sort(ctx.partners.partner_index)', [2 3]);
verifyTrue(tc, ismember(ctx.status, ["flagged","ranked"]));
verifyGreaterThan(tc, height(ctx.evidence), 0);
verifyGreaterThan(tc, strlength(ctx.explanation), 0);
ctx7 = getEntityContext(b, 7);
verifyEqual(tc, ctx7.status, "insufficient history");
verifyTrue(tc, contains(ctx7.explanation, "not a statement that the behaviour is normal"));
verifyEqual(tc, height(ctx7.evidence), 0);
end

function testPlaybackFrame(tc)
b = tc.TestData.bundle;
fr = buildPlaybackFrame(b, datetime(2015,2,1), 1);
verifyEqual(tc, numel(fr.crime_rows), 3);          % January 2015
verifyEqual(tc, height(fr.edges), 4);
verifyEqual(tc, height(fr.new_edges), 4);
verifyNotEmpty(tc, fr.bin);
end

function testNoRawIdsInExplanationText(tc)
% Evidence text describes deviations; it must not contain partner IDs or
% guilt language.
S = tc.TestData.bundle.explanations.summary;
for k = 1:height(S)
    verifyFalse(tc, contains(S.evidence_text(k), ["criminal","guilty","dangerous"], 'IgnoreCase', true) ...
        && ~contains(S.evidence_text(k), "not evidence of guilt"));
    verifyFalse(tc, contains(S.evidence_text(k), "OID#"));
end
end

function testExperimentSmokeRun(tc)
out = fullfile(tc.TestData.dir, "experiments");
r = runExperiments(tc.TestData.bundle, tc.TestData.cfg, out, struct('quick', true));
verifyTrue(tc, isfile(fullfile(out, "experiments_summary.md")));
verifyTrue(tc, isfile(fullfile(out, "synthetic_E5_E7_injection_summary.csv")));
verifyGreaterThan(tc, height(r.ablation), 5);
txt = fileread(fullfile(out, "experiments_summary.md"));
verifyTrue(tc, contains(txt, "SYNTHETIC"));
end
