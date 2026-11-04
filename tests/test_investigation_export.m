function tests = test_investigation_export
%TEST_INVESTIGATION_EXPORT Review artifacts preserve measured evidence/scope.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function b = fixture()
b.meta = struct('dataset_blob_sha', repmat('a',1,40), ...
    'dataset_file', '/private/capture.csv', 'random_seed', 42, ...
    'matlab_version', '24.2', 'feature_version', 'F3', 'version', '0.2.0');
b.meta.dataset = struct('pseudonymized', false, 'name', "private dataset");
b.entities = table(["192.0.2.14";"internal-secret";"198.51.100.42";"another-secret"], ...
    logical([1;0;1;1]), [12;1;4;5], [2;NaN;0.2;0.3], NaN(4,1), ...
    'VariableNames', {'entity_id','eligible','event_count','baseline_score','iforest_score'});
b.registry = featureRegistry();
b.anomaly.eligible = b.entities.eligible;
b.anomaly.prep = struct('names', "event_count", 'labels', "Event count", ...
    'groups', "activity", 'center', log1p(4), 'Z', [2;0;0]);
b.explanations.evidence = table(1, "event_count", 0.1, ...
    'VariableNames', {'entity_index','feature','occlusion_delta'});
b.flows = table([1;2;1;1;3], [2;1;1;2;4], ...
    datetime(2020,1,1) + seconds([3;1;2;4;5]), ...
    categorical(["tcp";"udp";"tcp";"tcp";"udp"]), ...
    [10;20;30;40;50], [80;53;80;80;53], ones(5,1), [30;10;20;40;50], ones(5,1), ...
    'VariableNames', {'src_index','dst_index','time','proto','sport','dport', ...
    'duration_s','bytes','packets'});
end

function dir = outputDir(tc)
dir = string(tempname);
mkdir(dir);
tc.addTeardown(@() rmdir(dir, 's'));
end

function testExportRoundTripAndBoundedReplayWindow(tc)
b = fixture();
t = datetime(2020,1,1);
[files, payload] = exportInvestigation(b, 1, outputDir(tc), t+seconds(1), t+seconds(4), 2);
verifyTrue(tc, isfile(files.json));
verifyTrue(tc, isfile(files.evidence_csv));
verifyTrue(tc, isfile(files.flows_csv));
r = jsondecode(fileread(files.json));
verifyEqual(tc, string(r.host), "HOST-1");
verifyEqual(tc, string(r.scores.scope), "full_run");
verifyEqual(tc, r.scores.baseline_score, 2);
verifyEqual(tc, r.provenance.random_seed, 42);
verifyEqual(tc, string(r.provenance.feature_version), "F3");
verifyEqual(tc, string(r.provenance.source_blob_sha), string(repmat('a',1,40)));
verifyTrue(tc, r.replay_interval.available);
verifyEqual(tc, string(r.replay_interval.end_exclusive), "2020-01-01 00:00:04.000");
verifyEqual(tc, string(r.observations.scope), "replay_interval");
verifyEqual(tc, r.observations.total_host_flows_full_run, 4);
verifyEqual(tc, r.observations.total_matching_flows, 3);
verifyEqual(tc, r.observations.shown, 2);
verifyTrue(tc, r.observations.truncated);
ev = readtable(files.evidence_csv);
verifyEqual(tc, ev.value, 12);
verifyEqual(tc, ev.reference_median, 4, 'AbsTol', 1e-12);
verifyEqual(tc, ev.robust_z, 2);
verifyEqual(tc, ev.occlusion_delta, 0.1, 'AbsTol', 1e-12);
flows = readtable(files.flows_csv);
verifyEqual(tc, flows.bytes, [10;20]);
verifyEqual(tc, string(flows.peer), ["HOST-2";"HOST-1"]);
verifyEqual(tc, payload.observations.total_matching_flows, 3);
end

function testExportDoesNotCopySensitiveIdentifiersOrPaths(tc)
b = fixture();
[files, ~] = exportInvestigation(b, 1, outputDir(tc));
for name = ["json", "evidence_csv", "flows_csv"]
    txt = string(fileread(files.(name)));
    verifyFalse(tc, any(contains(txt, b.entities.entity_id)));
    verifyFalse(tc, contains(txt, '/private/capture.csv'));
    verifyFalse(tc, contains(txt, 'private dataset'));
end
r = jsondecode(fileread(files.json));
verifyFalse(tc, isfield(r, 'confidence'));
verifyFalse(tc, isfield(r.observations, 'confidence'));
end

function testOldBundleMissingFlowsIsExplicit(tc)
b = rmfield(fixture(), 'flows');
[files, r] = exportInvestigation(b, 1, outputDir(tc));
verifyFalse(tc, r.observations.source_available);
verifyFalse(tc, r.replay_interval.available);
verifyTrue(tc, isnan(r.observations.total_matching_flows));
verifyTrue(tc, isnan(r.observations.total_host_flows_full_run));
verifyFalse(tc, r.observations.truncated);
verifyTrue(tc, contains(string(fileread(files.flows_csv)), 'duration_seconds'));
end

function testIneligibleEntityHasNoInventedFeatureEvidence(tc)
[files, r] = exportInvestigation(fixture(), 2, outputDir(tc));
verifyFalse(tc, r.scores.eligible);
verifyEmpty(tc, r.feature_evidence);
verifyTrue(tc, contains(string(fileread(files.evidence_csv)), 'reference_median'));
end

function testInvalidIntervalIsRejected(tc)
t = datetime(2020,1,1);
verifyError(tc, @() exportInvestigation(fixture(),1,outputDir(tc),t,t), ...
    'MOSAIC:InvalidInterval');
verifyError(tc, @() exportInvestigation(fixture(),1,outputDir(tc),t,NaT), ...
    'MOSAIC:InvalidInterval');
verifyError(tc, @() exportInvestigation(fixture(),1,outputDir(tc),NaT,t), ...
    'MOSAIC:InvalidInterval');
end
