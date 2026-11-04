function tests = test_delivery_evidence
%TEST_DELIVERY_EVIDENCE Manifest serialization, fingerprints and delivery gates.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function testNestedDatetimeConfiguration(tc)
cfg = projectConfig();
cfg.extra = {struct('when', datetime(2026,10,31,12,34,56)), caldays(2)};
safe = deliveryEvidence("json_safe", cfg);
decoded = jsondecode(jsonencode(safe));
verifyEqual(tc, string(decoded.temporal.series_start), "2014-01-01T00:00:00.000");
verifyEqual(tc, string(decoded.extra{1}.when), "2026-10-31T12:34:56.000");
verifyTrue(tc, isstring(safe.extra{2}));
end

function testFingerprintsTrackChangedArtifacts(tc)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's')); %#ok<NASGU>
writeTextFile(fullfile(folder, 'metrics.csv'), "score" + newline + "0.5");
a = deliveryEvidence("fingerprints", folder);
verifyEqual(tc, a.file, "metrics.csv");
verifyEqual(tc, strlength(a.git_blob_sha1), 40);
verifyEqual(tc, fieldnames(a), {'file';'bytes';'git_blob_sha1'});
verifyEqual(tc, a, deliveryEvidence("fingerprints", folder));
writeTextFile(fullfile(folder, 'metrics.csv'), "score" + newline + "0.6");
b = deliveryEvidence("fingerprints", folder);
verifyNotEqual(tc, a.git_blob_sha1, b.git_blob_sha1);
end

function testEmptyFingerprints(tc)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's')); %#ok<NASGU>
verifyEmpty(tc, deliveryEvidence("fingerprints", folder));
end

function testMetaFlagCannotSubstituteForForest(tc)
b = struct('meta', struct('iforest_used', true), ...
    'anomaly', struct('iforest', struct('model', struct('fake', true))));
verifyError(tc, @() deliveryEvidence("require_iforest", b), "MOSAIC:ActualForestRequired");
b.anomaly.iforest.model = [];
verifyError(tc, @() deliveryEvidence("require_iforest", b), "MOSAIC:ActualForestRequired");
end

function testSmokeAndSkippedTestsCannotPassDelivery(tc)
e = struct('quick', false, 'tests_skipped', 0);
verifyEqual(tc, deliveryEvidence("completion_status", e), "AUTOMATED_CHECKS_PASSED");
e.quick = true;
verifyEqual(tc, deliveryEvidence("completion_status", e), "PARTIAL");
e.quick = false;
e.tests_skipped = 1;
verifyEqual(tc, deliveryEvidence("completion_status", e), "PARTIAL");
end

function testFittedForestIsRequiredAndAcceptedWhenAvailable(tc)
assumeFalse(tc, isempty(which('iforest')), "Statistics toolbox is unavailable.");
Z = [-2;-1;0;1;2];
[score, model] = scoreIsolationForest(Z, Z, 10, 5, 42);
b = struct('anomaly', struct('eligible', true(5,1), ...
    'iforest', struct('model', model, 'score', score)));
verifyTrue(tc, deliveryEvidence("require_iforest", b));
b.anomaly.iforest.score(1) = NaN;
verifyError(tc, @() deliveryEvidence("require_iforest", b), "MOSAIC:ForestScoresRequired");
end

function testSourceFingerprintsExcludeGeneratedCaches(tc)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's')); %#ok<NASGU>
mkdir(fullfile(folder, '__pycache__'));
writeTextFile(fullfile(folder, 'analysis.m'), "function analysis; end");
writeTextFile(fullfile(folder, '__pycache__', 'audit.pyc'), "cache");
writeTextFile(fullfile(folder, 'analysis.asv'), "autosave");
r = deliveryEvidence("source_fingerprints", folder);
verifyEqual(tc, numel(r), 1);
verifyEqual(tc, r.file, "analysis.m");
end
