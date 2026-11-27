function tests = test_bundle_provenance
%TEST_BUNDLE_PROVENANCE Run coverage, metadata absence and privacy boundaries.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.lang = uiText("--lang");
uiText("--lang", "en");
end

function teardownOnce(tc)
uiText("--lang", tc.TestData.lang);
end

function b = fixture()
b.meta = struct('dataset_blob_sha', repmat('a',1,40), ...
    'matlab_version', '24.2', 'feature_version', '1.3', 'random_seed', 42);
b.meta.dataset = struct('name', "CTU-13 sample", 'id', "ctu13", 'n_rows', 100, ...
    'source_file', '/private/capture.csv', 'import_notes', ...
    ["Only records 500001 to 500100 were read (first_row/max_rows)."; ...
    "Private host 192.0.2.14 at /private/input.csv"]);
b.entities = table(["192.0.2.14"; "secret-host"; "secret-host2"; "secret-host3"], ...
    logical([1;1;0;1]), [0.8;0.2;NaN;NaN], [NaN;0.7;NaN;NaN], ...
    ["malicious";"benign";"malicious";"unknown"], ...
    'VariableNames', {'entity_id','eligible','baseline_score','iforest_score','truth'});
end

function testCountsAndSampling(tc)
T = bundleProvenance(fixture());
verifyEqual(tc, size(T,2), 2);
verifyEqual(tc, value(T,"Source blob SHA"), string(repmat('a',1,40)));
verifyEqual(tc, value(T,"Source rows read"), "100");
verifyEqual(tc, value(T,"Record selection"), "Records 500001 to 500100 (contiguous selection)");
verifyEqual(tc, value(T,"Random seed"), "42");
verifyEqual(tc, value(T,"Total entities"), "4");
verifyEqual(tc, value(T,"Eligible entities"), "3");
verifyEqual(tc, value(T,"Baseline scored entities"), "2");
verifyEqual(tc, value(T,"Isolation Forest scored entities"), "1");
verifyEqual(tc, value(T,"Unscored by either detector"), "2");
verifyEqual(tc, value(T,"Known published labels"), "3");
verifyEqual(tc, value(T,"Unknown or unavailable labels"), "1");
end

function testDoesNotCopyPathsIdentifiersOrFreeText(tc)
b = fixture();
T = bundleProvenance(b);
verifyFalse(tc, any(contains(T.value, ["/private", "192.0.2.14", "secret-host"])));
b.meta.dataset.name = "/private/capture.csv";
b.meta.dataset.id = "192.0.2.14";
T = bundleProvenance(b);
verifyEqual(tc, value(T,"Dataset name"), "Withheld for privacy");
verifyEqual(tc, value(T,"Dataset ID"), "Withheld for privacy");
end

function testMissingMetadataDoesNotInventProvenance(tc)
T = bundleProvenance(struct());
verifyTrue(tc, all(T.value == "Unavailable"));
b.entities = table(["a";"b"], 'VariableNames', {'entity_id'});
T = bundleProvenance(b);
verifyEqual(tc, value(T,"Known published labels"), "0");
verifyEqual(tc, value(T,"Unknown or unavailable labels"), "2");
verifyEqual(tc, value(T,"Eligible entities"), "Unavailable");
verifyEqual(tc, value(T,"Unscored by either detector"), "Unavailable");
end

function testTurkishLabels(tc)
uiText("--lang", "tr");
tc.addTeardown(@() uiText("--lang", "en"));
T = bundleProvenance(fixture());
verifyEqual(tc, T.field(1), "Veri seti adı");
verifyEqual(tc, T.value(5), "500001–500100 kayıtları (ardışık seçim)");
verifyEqual(tc, uiText("Provenance"), "Veri ve çalışma kaydı");
end

function v = value(T, field)
v = T.value(T.field == field);
end
