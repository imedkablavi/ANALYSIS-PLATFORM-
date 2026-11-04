function tests = test_domain_wording
%TEST_DOMAIN_WORDING Shared features and network evidence use neutral nouns.
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

function testRegistryUsesEventEntityPeerLabels(tc)
r = featureRegistry();
verifyFalse(tc, any(contains(lower(r.label), ["crime", "offender", "co-offend"])));
verifyEqual(tc, r.label(r.name == "degree"), "number of peers");
verifyEqual(tc, r.label(r.name == "strength"), "total shared events with peers");
verifyFalse(tc, contains(r.label(r.name == "peak_window_share"), "30"));
verifyTrue(tc, contains(r.definition(r.name == "peak_window_share"), "cfg.temporal.burst_window_days"));
% Stable column and group keys preserve mathematical/model compatibility.
verifyEqual(tc, r.group(r.name == "mean_group_size"), "cooffending");
end

function testNetworkPipelineEvidenceUsesNeutralLabels(tc)
lines = ["StartTime,Dur,Proto,SrcAddr,Sport,Dir,DstAddr,Dport,State,sTos,dTos,TotPkts,TotBytes,SrcBytes,Label"; ...
    "2011/08/10 09:46:00.000000,1,tcp,10.0.0.1,1000,->,10.0.0.3,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP"; ...
    "2011/08/10 09:47:00.000000,1,tcp,10.0.0.1,1001,->,10.0.0.3,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP"; ...
    "2011/08/10 09:48:00.000000,1,tcp,10.0.0.1,1002,->,10.0.0.3,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP"; ...
    "2011/08/10 09:46:30.000000,2,tcp,10.0.0.2,2000,->,10.0.0.3,443,FSPA,0,0,20,3000,1800,flow=From-Normal-V42"; ...
    "2011/08/10 09:49:00.000000,2,tcp,10.0.0.2,2001,->,10.0.0.3,443,FSPA,0,0,20,3000,1800,flow=From-Normal-V42"; ...
    "2011/08/10 09:52:00.000000,2,tcp,10.0.0.2,2002,->,10.0.0.3,443,FSPA,0,0,20,3000,1800,flow=From-Normal-V42"; ...
    "2011/08/10 09:53:00.000000,2,tcp,10.0.0.4,2003,->,10.0.0.3,443,FSPA,0,0,20,3000,1800,flow=Background-TCP"];
p = fullfile(tc.TestData.dir, 'wording.binetflow');
writeTextFile(p, joinStrings(lines, newline) + newline);
ds = importDataset(p);
cfg = projectConfig();
[cfg, ~] = configureForDataset(cfg, ds);
cfg.labels.entities = "hosts";
cfg.labels.events = "flows";
cfg.temporal.burst_window_days = 7;
b = runAnalysisPipeline(cfg, tc.TestData.dir, ...
    struct('dataset', ds, 'save', false, 'use_iforest', false));
verifyNotEmpty(tc, b.explanations.summary);
text = b.explanations.summary.evidence_text;
verifyFalse(tc, any(contains(lower(text), ["crime", "offender", "cooffending", "30 days"])));
verifyTrue(tc, all(contains(text, "recorded flows")));
verifyFalse(tc, any(contains(lower(b.explanations.evidence.label), ["crime", "offender"])));
k = find(~b.entities.eligible, 1);
verifyNotEmpty(tc, k);
ctx = getEntityContext(b, k);
verifyTrue(tc, contains(ctx.explanation, "recorded flows"));
% The same renderer falls back to generic nouns without domain config.
b.config = rmfield(b.config, 'labels');
ctx = getEntityContext(b, k);
verifyTrue(tc, contains(ctx.explanation, "recorded events"));
end
