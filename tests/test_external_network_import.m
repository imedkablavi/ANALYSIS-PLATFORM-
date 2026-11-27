function tests = test_external_network_import
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

function testIpAliasesAndUnknownLabels(tc)
p = fullfile(tc.TestData.dir, "custom.csv");
writeTextFile(p, joinStrings([ ...
    "src_ip,dst_ip,timestamp,bytes,packets,destination_port,protocol,label"; ...
    "123456789012345678,A,1700000000,120,2,443,tcp,Botnet"; ...
    "123456789012345679,B,1700000060,350,4,80,tcp,BENIGN"], newline) + newline);
info = inspectDatasetFile(p);
verifyEqual(tc, info.profile, "generic_network_flow");
verifyFalse(tc, info.needs_mapping);
ds = importDataset(p, struct('time_unit', "posix_s"));
verifyEqual(tc, ds.meta.n_entities, 4);
verifyEqual(tc, ds.flows.bytes, [120; 350]);
verifyEqual(tc, ds.flows.dport, [443; 80]);
verifyEqual(tc, string(ds.flows.label_class), ["unknown"; "unknown"]);
verifyFalse(tc, ds.meta.has_labels);
verifyEqual(tc, ds.flows.time(2) - ds.flows.time(1), seconds(60));
end

function testExplicitDifferentOrderAndOptionalColumns(tc)
p = fullfile(tc.TestData.dir, "second.tsv");
writeTextFile(p, "when" + char(9) + "receiver" + char(9) + "sender" + newline + ...
    "1700000000000" + char(9) + "B" + char(9) + "A" + newline + ...
    "1700000001500" + char(9) + "C" + char(9) + "A" + newline);
opts = struct('format', "network_flow", 'profile', "generic_network_flow", ...
    'time_unit', "posix_ms", 'mapping', struct('source', "sender", 'target', "receiver", 'time', "when"));
ds = importDataset(p, opts);
verifyEqual(tc, ds.flows.time(2) - ds.flows.time(1), seconds(1.5));
verifyTrue(tc, all(isnan(ds.flows.bytes)));
verifyTrue(tc, all(isnan(ds.flows.packets)));
verifyTrue(tc, all(isnan(ds.flows.duration_s)));
verifyEqual(tc, ds.meta.n_events, 2);
end

function testAmbiguousAliasNeedsMapping(tc)
p = fullfile(tc.TestData.dir, "ambiguous.csv");
writeTextFile(p, "src_ip,source_ip,dst_ip,timestamp" + newline + "A,B,C,1700000000" + newline);
info = inspectDatasetFile(p);
verifyEqual(tc, info.profile, "generic_network_flow");
verifyTrue(tc, info.needs_mapping);
verifyError(tc, @() importDataset(p), "MOSAIC:MappingMissing");
ds = importDataset(p, struct('mapping', struct('src', "src_ip"), 'time_unit', "posix_s"));
verifyEqual(tc, ds.meta.n_flows, 1);
end

function testPlainEdgesStayEdgesAndUnsupportedFilesStayUnknown(tc)
p = fullfile(tc.TestData.dir, "edges.csv");
writeTextFile(p, "src,dst,time" + newline + "A,B,1700000000" + newline);
info = inspectDatasetFile(p);
verifyEqual(tc, info.format, "edge_csv");
q = fullfile(tc.TestData.dir, "not_text.xlsx");
writeTextFile(q, "src_ip,dst_ip,timestamp" + newline + "A,B,1700000000" + newline);
info = inspectDatasetFile(q);
verifyEqual(tc, info.format, "unknown");
verifyError(tc, @() textImportOptions(q), "MOSAIC:UnsupportedFormat");
end

function testInvalidMappingAndRowBounds(tc)
p = fullfile(tc.TestData.dir, "bounds.csv");
writeTextFile(p, "src_ip,dst_ip,timestamp" + newline + "A,B,1700000000" + newline);
verifyError(tc, @() importDataset(p, struct('mapping', struct('src', "absent"))), "MOSAIC:MappingMissing");
for first = [0, -1, 1.5, Inf, NaN]
    verifyError(tc, @() importDataset(p, struct('first_row', first)), "MOSAIC:InvalidImportOptions");
end
for limit = [0, -1, 1.5, NaN]
    verifyError(tc, @() importDataset(p, struct('max_rows', limit)), "MOSAIC:InvalidImportOptions");
end
end

function testKnownProfileWins(tc)
p = fullfile(tc.TestData.dir, "known.csv");
writeTextFile(p, "StartTime,Dur,Proto,SrcAddr,Sport,Dir,DstAddr,Dport,State,TotPkts,TotBytes,Label" + newline + ...
    "2011/08/16 10:00:00.000000,1,tcp,A,1,->,B,80,S,2,120,flow=From-Botnet" + newline);
info = inspectDatasetFile(p);
verifyEqual(tc, info.profile, "ctu13_binetflow");
ds = importDataset(p);
verifyEqual(tc, string(ds.flows.label_class), "malicious");
end

function testInvalidTrafficMeasurements(tc)
p = fullfile(tc.TestData.dir, "measurements.csv");
for row = ["A,B,1700000000,-1,80"; "A,B,1700000000,Inf,80"; ...
        "A,B,1700000000,10,65536"; "A,B,1700000000,10,1.5"]'
    writeTextFile(p, "src_ip,dst_ip,timestamp,bytes,destination_port" + newline + row + newline);
    verifyError(tc, @() importDataset(p), "MOSAIC:InvalidFlowValues");
end
end

function testExplicitTextTimeAndPartialEndpoints(tc)
p = fullfile(tc.TestData.dir, "dates.csv");
writeTextFile(p, "source_ip,destination_ip,start_time,bytes" + newline + ...
    "A,B,31.10.2026 08:00,20" + newline + ...
    "ONLY_DROPPED,,31.10.2026 08:01,40" + newline);
opts = struct('time_formats', "dd.MM.yyyy HH:mm");
ds = importDataset(p, opts);
verifyEqual(tc, ds.flows.time, datetime(2026,10,31,8,0,0));
verifyEqual(tc, ds.meta.n_entities, 2);
verifyEqual(tc, height(ds.events), 2);
verifyEqual(tc, ds.meta.n_flows, 1);
end

function testGenericLabelColumnDoesNotImplyCicGroundTruth(tc)
p = fullfile(tc.TestData.dir,"unfamiliar_labels.csv");
writeTextFile(p,"Source IP,Destination IP,Timestamp,Label" + newline + ...
    "A,B,1700000000,review" + newline);
info = inspectDatasetFile(p);
verifyEqual(tc,info.profile,"generic_network_flow");
ds = importDataset(p,struct('time_unit',"posix_s"));
verifyFalse(tc,ds.meta.has_labels);
verifyEqual(tc,string(ds.flows.label_class),"unknown");
end

function testEventRowLimitIsNotSilentlyIgnored(tc)
p = fullfile(tc.TestData.dir,"event_selection.csv");
writeTextFile(p,"entity,time" + newline + "A,1700000000" + newline);
verifyError(tc,@() importDataset(p,struct('max_rows',1)),"MOSAIC:UnsupportedSelection");
end
