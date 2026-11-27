function tests = test_import_correctness
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

function testGitBlobHash(tc)
p = fullfile(tc.TestData.dir, "hash.txt");
writeTextFile(p, "hello" + newline);
[ok, sha] = verifyGitBlobSha(p, "ce013625030ba8dba906f756967f9e9ca394464a");
verifyTrue(tc, ok);
verifyEqual(tc, sha, "ce013625030ba8dba906f756967f9e9ca394464a");
% Cross the streaming chunk boundary and compare with an independent digest.
fid = fopen(p, 'wb');
payload = repmat(uint8(0:255), 1, 5000);
fwrite(fid, payload, 'uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-1');
md.update(typecast([uint8(sprintf('blob %d', numel(payload))), uint8(0), payload], 'int8'));
expected = lower(string(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2)', 1, [])));
[~, actual] = verifyGitBlobSha(p);
verifyEqual(tc, actual, expected);
end

function testImportIdentity(tc)
p = flowFixture(tc);
a = importDataset(p, struct('max_rows', 1));
b = importDataset(p, struct('first_row', 3, 'max_rows', 1));
c = importDataset(p, struct('max_rows', 1));
verifyNotEqual(tc, a.meta.id, b.meta.id);
verifyEqual(tc, a.meta.id, c.meta.id);
verifyEqual(tc, a.meta.sha, b.meta.sha);
end

function testLabelContentChangesIdentity(tc)
p = fullfile(tc.TestData.dir, "auth.txt");
r = fullfile(tc.TestData.dir, "redteam.txt");
writeTextFile(p, "1,U1@D,U1@D,C1,C2,NTLM,Network,LogOn,Success" + newline);
writeTextFile(r, "1,U1@D,C1,C2" + newline);
a = importDataset(p, struct('labels_file', r));
writeTextFile(r, "2,U1@D,C1,C2" + newline);
b = importDataset(p, struct('labels_file', r));
verifyEqual(tc, a.meta.sha, b.meta.sha);
verifyNotEqual(tc, a.meta.id, b.meta.id);
verifyEqual(tc, a.meta.label_counts.malicious, 1);
verifyEqual(tc, b.meta.label_counts.malicious, 0);
end

function testDroppedEndpointsCannotContributeEvents(tc)
p = flowFixture(tc);
ds = importDataset(p);
verifyEqual(tc, ds.meta.n_rows, 3);
verifyEqual(tc, ds.meta.n_flows, 2);
verifyEqual(tc, ds.meta.n_events, 2);
verifyEqual(tc, ds.meta.n_entities, 3);
verifyEqual(tc, height(ds.events), 4);
verifyEqual(tc, sum(ds.nodes.crime_count), 4);
verifyEqual(tc, ds.flows.bytes, [100; 300]);
verifyTrue(tc, all(ds.events.num_offenders == 2));
end

function testInvalidFirstTimestampDoesNotPoisonColumn(tc)
[t, ~] = parseTimeColumn(["not-a-date"; "2011/08/10 09:46:00.000000"], ...
    "auto", "yyyy/MM/dd HH:mm:ss.SSSSSS");
verifyTrue(tc, isnat(t(1)));
verifyEqual(tc, t(2), datetime(2011,8,10,9,46,0));
end

function p = flowFixture(tc)
p = fullfile(tc.TestData.dir, "capture.binetflow");
lines = ["StartTime,Dur,Proto,SrcAddr,Sport,Dir,DstAddr,Dport,State,TotPkts,TotBytes,Label"; ...
    "2011/08/10 09:46:00.000000,1,tcp,A,1,->,B,80,S,2,100,flow=From-Normal"; ...
    "2011/08/10 09:47:00.000000,2,tcp,INVALID_ONLY,2,->,,80,S,3,200,flow=From-Botnet"; ...
    "2011/08/10 09:48:00.000000,3,tcp,A,3,->,C,443,S,4,300,flow=From-Normal"];
writeTextFile(p, joinStrings(lines, newline) + newline);
end

function testMissingDirectionalComponentDoesNotBecomeTotal(tc)
p = fullfile(tc.TestData.dir, "partial_cic.csv");
header = "Source IP,Destination IP,Timestamp,Label,Total Length of Fwd Packets,Total Fwd Packets";
row = "A,B,03/07/2017 08:55:58,BENIGN,100,1";
writeTextFile(p, header + newline + row + newline);
partial = importDataset(p);
verifyEqual(tc, partial.meta.profile, "cicids2017_flows");
verifyTrue(tc, isnan(partial.flows.bytes));
verifyTrue(tc, isnan(partial.flows.packets));
f = computeNetworkFeatures(partial.flows, partial.meta.n_entities);
verifyTrue(tc, all(isnan(f.small_flow_fraction)));
verifyTrue(tc, all(isnan(f.median_bytes_out)));
% The exact same forward observations become totals only once both
% directional components are present, including observed zeros.
writeTextFile(p, header + ",Total Length of Bwd Packets,Total Backward Packets" + ...
    newline + row + ",0,2" + newline);
complete = importDataset(p);
verifyEqual(tc, complete.flows.bytes, 100);
verifyEqual(tc, complete.flows.packets, 3);
f = computeNetworkFeatures(complete.flows, complete.meta.n_entities);
verifyEqual(tc, f.small_flow_fraction(1), 0);
end
