function tests = test_presentation_bundle
%TEST_PRESENTATION_BUNDLE Selection of saved runs, never generated demo data.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function testLatestNetworkRunWinsOverHistoricalDataset(tc)
dir = folder(tc);
saveRun(dir, "old.mat", "old", "network_flow", true);
saveRun(dir, "new.mat", "new", "network_flow", true);
saveRun(dir, "historical.mat", "historical", "networkx_burglary_json", true);
c = catalog(["old";"historical";"new"], ...
    ["network_flow";"networkx_burglary_json";"network_flow"], ...
    ["old.mat";"historical.mat";"new.mat"], [1;3;2]);
[b, file] = presentationBundle(dir,c);
verifyEqual(tc, string(b.meta.dataset.id), "new");
verifyEqual(tc, file, fullfile(dir,"new.mat"));
end

function testSkipsMissingCorruptAndInvalidNewerRuns(tc)
dir = folder(tc);
saveRun(dir, "valid.mat", "valid", "network_flow", true);
saveRun(dir, "invalid.mat", "invalid", "network_flow", false);
writeTextFile(fullfile(dir,"corrupt.mat"), "not a MAT file");
c = catalog(["valid";"missing";"invalid";"corrupt"], repmat("network_flow",4,1), ...
    ["valid.mat";"missing.mat";"invalid.mat";"corrupt.mat"], [1;4;3;2]);
[b, ~] = presentationBundle(dir,c);
verifyEqual(tc, string(b.meta.dataset.id), "valid");
end

function testMismatchedMetadataDoesNotLaunch(tc)
dir = folder(tc);
saveRun(dir,"run.mat","actual","network_flow",true);
c = catalog("wrong-id","network_flow","run.mat",1);
[b,file] = presentationBundle(dir,c);
verifyEmpty(tc,b);
verifyEqual(tc,file,"");
saveRun(dir,"run.mat","actual","networkx_burglary_json",true);
c.dataset_id = "actual";
[b,~] = presentationBundle(dir,c);
verifyEmpty(tc,b);
end

function testMissingShaAndNoCatalogRemainEmpty(tc)
dir = folder(tc);
bundle = runMetadata("run","network_flow",true);
bundle.meta.dataset_blob_sha = "";
save(fullfile(dir,"run.mat"), 'bundle');
c = catalog("run","network_flow","run.mat",1);
[b,~] = presentationBundle(dir,c);
verifyEmpty(tc,b);
[b,file] = presentationBundle(dir,table());
verifyEmpty(tc,b);
verifyEqual(tc,file,"");
verifyEqual(tc, numel(dirFiles(dir)), 1); % selector created no replacement run
end

function c = catalog(ids, formats, files, day)
c = table(ids,formats,files,datetime(2020,1,1)+days(day), ...
    'VariableNames', {'dataset_id','format','bundle_file','imported'});
end

function dir = folder(tc)
dir = string(tempname);
mkdir(dir);
tc.addTeardown(@() rmdir(dir,'s'));
end

function saveRun(dir,file,id,format,valid)
bundle = runMetadata(id,format,valid);
save(fullfile(dir,file), 'bundle');
end

function b = runMetadata(id,format,valid)
% Metadata-only fixture for selector tests; never displayed by the app.
b.meta.dataset = struct('id',id,'format',format);
b.meta.dataset_blob_sha = repmat('a',1,40);
b.validation.is_valid = valid;
b.entities = table(1,'VariableNames',{'entity_index'});
b.events = table(1,'VariableNames',{'entity_index'});
end

function entries = dirFiles(folder)
entries = dir(fullfile(folder,'*.mat'));
end
