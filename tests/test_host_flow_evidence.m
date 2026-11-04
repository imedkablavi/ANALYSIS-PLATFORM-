function tests = test_host_flow_evidence
tests = functiontests(localfunctions);
end
function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end
function testChronologyDirectionAndBound(tc)
f = table([1;2;1;3], [2;1;1;4], ...
    datetime(2020,1,1) + seconds([3;1;2;4]), ...
    categorical(["tcp";"udp";"tcp";"udp"]), ...
    [10;20;30;40], [80;53;80;53], ones(4,1), [50;60;70;80], [1;2;3;4], ...
    'VariableNames', {'src_index','dst_index','time','proto','sport','dport', ...
    'duration_s','bytes','packets'});
[T,n] = hostFlowEvidence(struct('flows', f), 1, 2);
verifyEqual(tc, n, 3);
verifyEqual(tc, height(T), 2);
verifyEqual(tc, T.direction, ["incoming";"self"]);
verifyEqual(tc, T.peer, ["HOST-2";"HOST-1"]);
verifyEqual(tc, T.bytes, [60;70]);
verifyFalse(tc, any(contains(string(T.Properties.VariableNames), 'label')));
end
function testOlderBundleAndAbsentHost(tc)
[T,n] = hostFlowEvidence(struct(), 1);
verifyEqual(tc, n, 0);
verifyEqual(tc, height(T), 0);
end
