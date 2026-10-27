function tests = test_network_datasets
%TEST_NETWORK_DATASETS Network-traffic profiles, labels, host features, ground truth.
%
%   Fixtures are written by hand in the published layouts
%   (docs/NETWORK_DATASETS.md). Expected feature values for the CTU-13
%   fixture come from the independent reference
%   scripts/reference/network_flow_reference.py (same fixture text):
%     H0001 (bot)    out 8, in 0, distinct_dst 2, distinct_dport 2,
%                    dport_entropy 0.591673, median_bytes_out 300,
%                    small_flow_fraction 0.25, beacon_cv_min 0
%     H0002 (normal) out 3, in 1, out_share 0.75, dport_entropy 0
%     H0005          in 7, distinct_dst NaN (no outgoing flow)
%   Host order = first appearance (all sources, then destinations).
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
d = string(tempname);
mkdir(d);
tc.TestData.dir = d;

ctu = [ ...
    "StartTime,Dur,Proto,SrcAddr,Sport,Dir,DstAddr,Dport,State,sTos,dTos,TotPkts,TotBytes,SrcBytes,Label"
    "2011/08/10 09:46:00.000000,1.5,tcp,10.0.0.5,1025,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:47:00.000000,1.5,tcp,10.0.0.5,1026,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:48:00.000000,1.5,tcp,10.0.0.5,1027,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:49:00.000000,1.5,tcp,10.0.0.5,1028,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:50:00.000000,1.5,tcp,10.0.0.5,1029,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:51:00.000000,1.5,tcp,10.0.0.5,1030,   ->,1.2.3.4,80,S_RA,0,0,3,300,180,flow=From-Botnet-V42-TCP-CC1-HTTP"
    "2011/08/10 09:46:30.500000,0.02,udp,10.0.0.5,1031,  <->,8.8.8.8,53,CON,0,0,2,150,70,flow=From-Botnet-V42-UDP-DNS"
    "2011/08/10 09:47:10.000000,30.0,tcp,10.0.0.9,2001,   ->,5.6.7.8,443,FSPA_FSPA,0,0,20,15000,2000,flow=From-Normal-V42-Stribrek"
    "2011/08/10 09:49:00.000000,25.0,tcp,10.0.0.9,2002,   ->,5.6.7.8,443,FSPA_FSPA,0,0,20,15000,2000,flow=From-Normal-V42-Stribrek"
    "2011/08/10 09:52:30.000000,20.0,tcp,10.0.0.9,2003,   ->,5.6.7.8,443,FSPA_FSPA,0,0,20,15000,2000,flow=From-Normal-V42-Stribrek"
    "2011/08/10 09:50:00.000000,0.0,tcp,9.9.9.9,4444,   ->,10.0.0.9,22,S_,0,0,1,60,60,flow=To-Normal-V42-Grill"
    "2011/08/10 09:51:00.000000,5.0,tcp,7.7.7.7,3333,   ->,5.6.7.8,443,FSPA_FSPA,0,0,10,5000,1000,flow=Background-TCP-Established"
    "2011/08/10 09:52:00.000000,0.0,icmp,10.0.0.5,0x0008,   ->,1.2.3.4,0x0000,ECO,0,0,1,98,98,flow=From-Botnet-V42-ICMP"];
tc.TestData.ctu = fullfile(d, "capture.binetflow");
writeTextFile(tc.TestData.ctu, joinStrings(ctu, newline) + newline);

% UNSW-NB15_1.csv style: 49 columns, no header.
unsw = strings(4, 1);
recs = { ...
    "59.166.0.0", "1390", "149.171.126.6", "53", "udp", "CON", "0.001", "132", "164", "1421927414", "", "0"
    "175.45.176.1", "31000", "149.171.126.10", "80", "tcp", "FIN", "0.5", "1000", "200", "1421927420", "Exploits", "1"
    "175.45.176.1", "31001", "149.171.126.11", "445", "tcp", "FIN", "0.4", "800", "100", "1421927430", "Exploits", "1"
    "59.166.0.1", "1391", "149.171.126.6", "80", "tcp", "FIN", "0.2", "500", "5000", "1421927440", "", "0"};
for r = 1:4
    v = repmat("0", 1, 49);
    v(1:9) = string(recs(r, 1:9));
    v(17) = "4";                 % Spkts
    v(18) = "2";                 % Dpkts
    v(29) = recs{r, 10};         % Stime
    v(30) = recs{r, 10};         % Ltime
    v(48) = recs{r, 11};         % attack_cat
    v(49) = recs{r, 12};         % Label
    unsw(r) = joinStrings(v, ",");
end
tc.TestData.unsw = fullfile(d, "UNSW-NB15_1.csv");
writeTextFile(tc.TestData.unsw, joinStrings(unsw, newline) + newline);
bad = unsw;
bad(:) = replace(bad, ["59.166.0.0", "175.45.176.1", "59.166.0.1"], ["hostA", "hostB", "hostC"]);
tc.TestData.unswBad = fullfile(d, "not_unsw.csv");
writeTextFile(tc.TestData.unswBad, joinStrings(bad, newline) + newline);

% LANL auth.txt + redteam.txt (no headers, relative seconds).
auth = [ ...
    "1,C625$@DOM1,U147@DOM1,C625,C625,Negotiate,Batch,LogOn,Success"
    "2,U22@DOM1,U22@DOM1,C17,C586,NTLM,Network,LogOn,Fail"
    "3,U22@DOM1,U22@DOM1,C17,C586,NTLM,Network,LogOn,Fail"
    "4,U22@DOM1,U22@DOM1,C17,C586,NTLM,Network,LogOn,Success"
    "150885,U620@DOM1,U620@DOM1,C17693,C1003,?,Network,LogOn,Success"
    "151036,U748@DOM1,U748@DOM1,C17693,C305,?,Network,LogOn,Success"];
tc.TestData.auth = fullfile(d, "auth.txt");
writeTextFile(tc.TestData.auth, joinStrings(auth, newline) + newline);
tc.TestData.redteam = fullfile(d, "redteam.txt");
writeTextFile(tc.TestData.redteam, joinStrings([ ...
    "150885,U620@DOM1,C17693,C1003"
    "151036,U748@DOM1,C17693,C305"
    "200000,U1@DOM1,C1,C2"], newline) + newline);
lflows = [ ...
    "1,0,C1065,389,C3799,N10451,6,10,5323"
    "1,0,C1423,N1136,C1707,N1,6,5,847"
    "2,1,C1423,N1137,C1707,N1,6,5,847"];
tc.TestData.lflows = fullfile(d, "flows.txt");
writeTextFile(tc.TestData.lflows, joinStrings(lflows, newline) + newline);

% CIC-IDS2017 GeneratedLabelledFlows style (leading spaces in names,
% two timestamp layouts in one file, Flow Duration in microseconds).
cic = [ ...
    "Flow ID, Source IP, Source Port, Destination IP, Destination Port, Protocol, Timestamp, Flow Duration, Total Fwd Packets, Total Backward Packets,Total Length of Fwd Packets, Total Length of Bwd Packets, Label"
    "192.168.10.5-104.16.207.165-54865-443-6,192.168.10.5,54865,104.16.207.165,443,6,03/07/2017 08:55:58,3000000,4,2,500,1000,BENIGN"
    "172.16.0.1-192.168.10.50-40000-80-6,172.16.0.1,40000,192.168.10.50,80,6,7/7/2017 3:30,1000,1,1,0,0,DDoS"
    "172.16.0.1-192.168.10.50-40001-80-6,172.16.0.1,40001,192.168.10.50,80,6,7/7/2017 3:31,2000,2,0,10,0,DDoS"];
tc.TestData.cic = fullfile(d, "Friday-WorkingHours.pcap_ISCX.csv");
writeTextFile(tc.TestData.cic, joinStrings(cic, newline) + newline);
end

function teardownOnce(tc)
if isfolder(tc.TestData.dir)
    rmdir(tc.TestData.dir, 's');
end
end

%% Detection
function testProfilesAreDetected(tc)
expect = {tc.TestData.ctu, "ctu13_binetflow"; tc.TestData.unsw, "unsw_nb15_raw"; ...
    tc.TestData.auth, "lanl_auth"; tc.TestData.lflows, "lanl_flows"; ...
    tc.TestData.cic, "cicids2017_flows"};
for k = 1:size(expect, 1)
    info = inspectDatasetFile(expect{k, 1});
    verifyEqual(tc, info.format, "network_flow", expect{k, 2});
    verifyEqual(tc, info.profile, expect{k, 2});
    verifyFalse(tc, info.needs_mapping);
end
end

function testWrongContentIsNotMislabelled(tc)
% 49 columns but no IP addresses: the UNSW profile must NOT match.
info = inspectDatasetFile(tc.TestData.unswBad);
verifyNotEqual(tc, info.format, "network_flow");
verifyError(tc, @() importDataset(tc.TestData.unswBad, struct('format', "network_flow", ...
    'profile', "unsw_nb15_raw")), "MOSAIC:ProfileMismatch");
end

%% CTU-13
function testCtuImportLabelsAndPrivacy(tc)
ds = importDataset(tc.TestData.ctu);
verifyEqual(tc, ds.meta.format, "network_flow");
verifyEqual(tc, ds.meta.profile, "ctu13_binetflow");
verifyEqual(tc, ds.meta.n_flows, 13);
verifyEqual(tc, ds.meta.n_entities, 7);
verifyEqual(tc, ds.meta.label_counts, struct('malicious', 8, 'benign', 4, 'unknown', 1));
verifyTrue(tc, ds.meta.has_labels);
% Pseudonymized: no IP address anywhere in the dataset tables.
verifyEqual(tc, ds.nodes.entity_id(1:2), ["ENT000001"; "ENT000002"]);
verifyFalse(tc, any(contains(ds.events.entity_id, ".")));
verifyFalse(tc, any(contains(string(ds.flows.Properties.VariableNames), "addr")));
% Microsecond timestamps and the ICMP hexadecimal "ports".
verifyEqual(tc, min(ds.flows.time), datetime(2011,8,10,9,46,0));
verifyEqual(tc, ds.flows.time(7), datetime(2011,8,10,9,46,30.5), 'AbsTol', seconds(1e-6));
verifyTrue(tc, isnan(ds.flows.dport(13)));
% Self-check of the label role: "To-Normal" is about the destination.
verifyEqual(tc, string(ds.flows.label_role(11)), "dst");
truth = networkGroundTruth(ds.flows, ds.meta.n_entities);
verifyEqual(tc, truth.truth, ["malicious"; "benign"; "unknown"; "unknown"; ...
    "unknown"; "unknown"; "unknown"]);
verifyEqual(tc, truth.malicious_flows(1), 8);
verifyEqual(tc, truth.benign_flows(2), 4);         % 3 From-Normal + 1 To-Normal
end

function testCtuNetworkFeatures(tc)
ds = importDataset(tc.TestData.ctu);
F = computeNetworkFeatures(ds.flows, ds.meta.n_entities, struct());
verifyEqual(tc, height(F), 7);
verifyEqual(tc, F.out_flows', [8 3 1 1 0 0 0]);
verifyEqual(tc, F.in_flows', [0 1 0 0 7 1 4]);
verifyEqual(tc, F.out_share(2), 0.75);
verifyEqual(tc, F.distinct_dst(1), 2);
verifyTrue(tc, isnan(F.distinct_dst(5)));            % no outgoing flow
verifyEqual(tc, F.distinct_src_in(7), 2);
verifyEqual(tc, F.distinct_dport(1), 2);             % 80 and 53; ICMP has no port
verifyEqual(tc, F.dport_entropy(1), 0.591673, 'AbsTol', 1e-6);
verifyEqual(tc, F.dport_entropy(2), 0, 'AbsTol', 1e-12);
verifyTrue(tc, isnan(F.dport_entropy(3)));            % < 2 flows with a port
verifyEqual(tc, F.median_bytes_out(1), 300);
verifyEqual(tc, F.median_duration_out(2), 25);
verifyEqual(tc, F.small_flow_fraction(1), 0.25);
verifyEqual(tc, F.beacon_cv_min(1), 0, 'AbsTol', 1e-9);  % one flow per minute
verifyTrue(tc, isnan(F.beacon_cv_min(2)));           % only 3 flows to one host
verifyTrue(tc, all(isnan(F.failed_fraction)));       % CTU has no auth outcome
reg = featureRegistry();
verifyTrue(tc, all(ismember(string(F.Properties.VariableNames), reg.name(reg.group == "network"))));
end

function testShortCaptureUsesMinuteBins(tc)
ds = importDataset(tc.TestData.ctu);
[c, notes] = configureForDataset(projectConfig(), ds);
verifyEqual(tc, c.temporal.bin, "minute");
verifyEqual(tc, c.temporal.anomaly_method, "rolling");
verifyEqual(tc, c.temporal.series_start, datetime(2011,8,10,9,46,0));
verifyEqual(tc, c.temporal.series_end, datetime(2011,8,10,9,52,0));
verifyEqual(tc, numel(c.temporal.snapshot_starts), 7);     % 6 one-minute windows
verifyTrue(tc, any(contains(notes, "minute")));
s = buildActivitySeries(ds.events, buildCrimeTable(ds.events), ...
    c.temporal.series_start, c.temporal.series_end, "minute");
verifyEqual(tc, height(s), 6);
verifyEqual(tc, s.crimes(1), 2);     % 09:46:00 and 09:46:30.5
end

function testGroundTruthEvaluation(tc)
truth = table((1:6)', ["malicious"; "benign"; "unknown"; "benign"; "malicious"; "unknown"], ...
    'VariableNames', {'entity_index', 'truth'});
ent = table(true(6, 1), [6; 1; 5; 2; 4; 3], [NaN; NaN; NaN; NaN; NaN; NaN], ...
    'VariableNames', {'eligible', 'baseline_score', 'iforest_score'});
ent.eligible(5) = false;            % a malicious host below the history threshold
E = evaluateGroundTruth(ent, truth);
b = E(E.detector == "baseline" & E.setting == "known_only", :);
% scored known hosts: 1 (mal, 6), 2 (ben, 1), 4 (ben, 2) -> perfect ranking
verifyEqual(tc, [b.n_scored b.n_malicious b.n_negative], [3 1 2]);
verifyEqual(tc, b.roc_auc, 1);
verifyEqual(tc, b.precision_at_k, 1);
verifyEqual(tc, b.malicious_not_scored, 1);
u = E(E.detector == "baseline" & E.setting == "unknown_as_benign", :);
% + unknown hosts 3 (5) and 6 (3) as negatives: mal score 6 still highest
verifyEqual(tc, u.n_negative, 4);
verifyEqual(tc, u.roc_auc, 1);
i = E(E.detector == "iforest", :);
verifyTrue(tc, all(isnan(i.roc_auc)));   % Isolation Forest not run
end

%% UNSW-NB15, LANL, CIC-IDS2017
function testUnswImport(tc)
ds = importDataset(tc.TestData.unsw);
verifyEqual(tc, ds.meta.profile, "unsw_nb15_raw");
verifyEqual(tc, ds.meta.label_counts, struct('malicious', 2, 'benign', 2, 'unknown', 0));
verifyEqual(tc, ds.flows.bytes', [296 1200 900 5500]);   % sbytes + dbytes
verifyEqual(tc, ds.flows.packets', [6 6 6 6]);           % Spkts + Dpkts
verifyEqual(tc, ds.flows.time(1), datetime(1421927414, 'ConvertFrom', 'posixtime'));
verifyEqual(tc, string(ds.flows.label_detail(2)), "Exploits");
truth = networkGroundTruth(ds.flows, ds.meta.n_entities);
% host order: 59.166.0.0, 175.45.176.1, 59.166.0.1, then destinations
verifyEqual(tc, truth.truth(1:3), ["benign"; "malicious"; "benign"]);
end

function testLanlAuthWithRedTeam(tc)
ds = importDataset(tc.TestData.auth, struct('labels_file', tc.TestData.redteam));
verifyEqual(tc, ds.meta.profile, "lanl_auth");
verifyEqual(tc, ds.meta.label_counts.malicious, 2);
verifyEqual(tc, ds.meta.label_counts.benign, 4);
verifyTrue(tc, any(contains(ds.meta.import_notes, "2 of 3 red-team events")));
verifyEqual(tc, ds.flows.time(2) - ds.flows.time(1), seconds(1));
% host order (sources first): C625, C17, C17693, then C586, C1003, C305
F = computeNetworkFeatures(ds.flows, ds.meta.n_entities, struct());
verifyEqual(tc, F.failed_fraction(2), 2 / 3, 'AbsTol', 1e-12);
verifyEqual(tc, F.failed_fraction(3), 0);
truth = networkGroundTruth(ds.flows, ds.meta.n_entities);
verifyEqual(tc, truth.truth(1:3), ["benign"; "benign"; "malicious"]);
noLabels = importDataset(tc.TestData.auth);
verifyFalse(tc, noLabels.meta.has_labels);
end

function testLanlFlowsAndMaxRows(tc)
ds = importDataset(tc.TestData.lflows, struct('max_rows', 2));
verifyEqual(tc, ds.meta.profile, "lanl_flows");
verifyEqual(tc, ds.meta.n_flows, 2);
verifyTrue(tc, any(contains(ds.meta.import_notes, "records 1 to 2")));
later = importDataset(tc.TestData.lflows, struct('first_row', 2, 'max_rows', 2));
verifyEqual(tc, later.flows.bytes', [847 847]);
verifyEqual(tc, ds.flows.bytes', [5323 847]);
verifyTrue(tc, isnan(ds.flows.dport(2)));                % "N1" is not a number
end

function testCicImportMixedTimestamps(tc)
ds = importDataset(tc.TestData.cic);
verifyEqual(tc, ds.meta.profile, "cicids2017_flows");
verifyEqual(tc, ds.flows.time, [datetime(2017,7,3,8,55,58); ...
    datetime(2017,7,7,3,30,0); datetime(2017,7,7,3,31,0)]);
verifyEqual(tc, ds.flows.duration_s(1), 3);              % 3,000,000 microseconds
verifyEqual(tc, ds.flows.bytes(1), 1500);
verifyEqual(tc, string(ds.flows.label_class)', ["benign" "malicious" "malicious"]);
verifyEqual(tc, string(ds.flows.label_detail(2)), "DDoS");
end

%% End to end
function testAnalyzeNetworkDatasetEndToEnd(tc)
root = fullfile(tc.TestData.dir, "root");
mkdir(root);
b = analyzeDataset(tc.TestData.ctu, struct('root_dir', root, 'use_iforest', false));
verifyEqual(tc, b.meta.dataset.format, "network_flow");
verifyEqual(tc, b.config.temporal.bin, "minute");
verifyTrue(tc, ismember("beacon_cv_min", b.anomaly.prep.names) || ...
    ismember("beacon_cv_min", b.anomaly.prep.dropped));
verifyEqual(tc, b.entities.truth(1), "malicious");
verifyEqual(tc, height(b.ground_truth.evaluation), 4);
verifyEqual(tc, bundleDatasetInfo(b).entity_plural, "hosts");
expDir = fullfile(root, b.config.output.experiment_dir);
verifyTrue(tc, isfile(fullfile(expDir, "ground_truth_evaluation.csv")));
end

function testLanlRedTeamFoundNextToAuthFile(tc)
% analyzeDataset uses redteam.txt from the folder of auth.txt by default.
root = fullfile(tc.TestData.dir, "root_lanl");
mkdir(root);
b = analyzeDataset(tc.TestData.auth, struct('root_dir', root, 'use_iforest', false));
verifyEqual(tc, b.meta.dataset.profile, "lanl_auth");
verifyTrue(tc, b.meta.dataset.has_labels);
verifyEqual(tc, b.meta.dataset.label_counts.malicious, 2);
verifyEqual(tc, b.config.temporal.bin, "hour");     % 1 s .. 151036 s = 41.9 h
end

function testGraphScaleGuards(tc)
% A star (hub with 6 leaves) plus one triangle; tiny limits force the guards.
s = [1 1 1 1 1 1 2];
t = [2 3 4 5 6 7 3];
G = graph(s, t, ones(1, 7), string(1:7));
full = computeGraphFeatures(G);
verifyEqual(tc, full.clustering_coef(2), 1);          % leaf 2: neighbours 1,3 linked
cfg.graph = struct('max_clustering_work', 10, 'max_betweenness_nodes', 3);
[gf, notes] = computeGraphFeatures(G, cfg);
verifyTrue(tc, all(isnan(gf.clustering_coef)));
verifyTrue(tc, all(isnan(gf.betweenness)));
verifyEqual(tc, gf.degree, full.degree);              % cheap features unaffected
verifyEqual(tc, gf.is_cut_vertex, full.is_cut_vertex);
verifyEqual(tc, numel(notes), 2);
verifyTrue(tc, contains(notes(1), "clustering_coef"));
end

function testPeakWindowShareWithManyEvents(tc)
% 2,000 events of one entity: the O(k log k) busiest-window count must give
% the same value as the definition (events in [t_j, t_j + 30 d)).
n = 2000;
t = datetime(2020,1,1) + days(sort(mod((1:n)' * 7.3, 400)));
ev = table(ones(n,1), "C" + (1:n)', (1:n)', NaN(n,1), NaN(n,1), t, ones(n,1), ...
    true(n,1), repmat("E1", n, 1), 'VariableNames', {'entity_index','crime_id', ...
    'crime_num','x','y','event_time','num_offenders','id_restored','entity_id'});
rel = table(zeros(0,1), zeros(0,1), zeros(0,1), 'VariableNames', {'a_index','b_index','weight'});
f = buildBehaviorFeatures(ev, "E1", rel, struct());
d = days(t - datetime(1970,1,1));
best = 0;
for j = 1:n
    best = max(best, nnz(d >= d(j) & d < d(j) + 30));
end
verifyEqual(tc, f.peak_window_share, best / n, 'AbsTol', 1e-12);
end
