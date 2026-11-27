function tests = test_import_dialog_options
%TEST_IMPORT_DIALOG_OPTIONS Structured UI-to-pipeline mapping and validation.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'scripts'));
setupProject();
end

function [info, form] = formFixture()
info = struct('format',"edge_csv",'profile',"", ...
    'columns',["HostA","HostB","When","Session","Volume","Transport"], ...
    'mapping',struct('source',"HostA",'target',"HostB",'time',"When"));
form = struct('layout',"generic_network_flow",'name',"My capture", ...
    'mapping',struct('source',"HostA",'target',"HostB",'time',"When", ...
        'bytes',"Volume",'proto',"Transport"), ...
    'time_unit',"auto",'time_format',"dd/MM/yyyy HH:mm:ss", ...
    'first_row',7,'max_rows',10);
end

function testMappedNetworkOptionsPreserveActualColumnsAndSlice(tc)
[info,form] = formFixture();
opts = importDialogOptions(info,form);
verifyEqual(tc,opts.format,"network_flow");
verifyEqual(tc,opts.profile,"generic_network_flow");
verifyEqual(tc,opts.mapping.src,"HostA");
verifyEqual(tc,opts.mapping.dst,"HostB");
verifyEqual(tc,opts.mapping.proto,"Transport");
verifyEqual(tc,opts.mapping.duration,"");
verifyEqual(tc,opts.first_row,7);
verifyEqual(tc,opts.max_rows,10);
verifyEqual(tc,opts.time_formats,"dd/MM/yyyy HH:mm:ss");
verifyFalse(tc,isfield(opts,'time_unit')); % Auto preserves the profile default.
form.max_rows = 0;
opts = importDialogOptions(info,form);
verifyFalse(tc,isfield(opts,'max_rows'));
end

function testDetectedLayoutCanBeCorrectedAndOptionalMappingCleared(tc)
[info,form] = formFixture();
form.layout = "event_csv";
form.mapping.entity = "HostA";
form.mapping.event = "";
opts = importDialogOptions(info,form);
verifyEqual(tc,opts.format,"event_csv");
verifyEqual(tc,opts.mapping.entity,"HostA");
verifyEqual(tc,opts.mapping.event,"");
verifyFalse(tc,isfield(opts,'profile'));
verifyFalse(tc,isfield(opts,'first_row'));
end

function testUnknownTextCanBeMappedButNoColumnsCannot(tc)
[info,form] = formFixture();
info.format = "unknown";
opts = importDialogOptions(info,form);
verifyEqual(tc,opts.profile,"generic_network_flow");
info.columns = strings(0,1);
verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportLayout');
end

function testRequiredColumnMustExist(tc)
[info,form] = formFixture();
form.mapping.time = "not-a-column";
verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportMapping');
form.mapping.time = "";
verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportMapping');
form.mapping.time = "When";
form.mapping.target = "HostA";
verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportMapping');
end

function testRecordLimitsAreNotSilentlyRounded(tc)
[info,form] = formFixture();
for bad = [-1, 0, 1.5, Inf, NaN]
    form.first_row = bad;
    verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportRange');
end
form.first_row = 1;
for bad = [-1, 1.5, Inf, NaN]
    form.max_rows = bad;
    verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportRange');
end
end

function testTimestampUnitAndKnownProfile(tc)
[info,form] = formFixture();
form.time_unit = "posix_ms";
opts = importDialogOptions(info,form);
verifyEqual(tc,opts.time_unit,"posix_ms");
form.time_unit = "unsupported";
verifyError(tc,@() importDialogOptions(info,form),'MOSAIC:ImportTimeUnit');
info.format = "network_flow"; info.profile = "ctu13";
form.layout = "network_flow"; form.time_unit = "auto";
opts = importDialogOptions(info,form);
verifyEqual(tc,opts.profile,"ctu13");
verifyEmpty(tc,fieldnames(opts.mapping));
end
