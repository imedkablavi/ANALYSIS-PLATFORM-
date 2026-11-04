function tests = test_display_counts
tests = functiontests(localfunctions);
end
function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts')); setupProject();
tc.TestData.lang = uiText("--lang");
end
function teardownOnce(tc)
uiText("--lang", tc.TestData.lang);
end
function testLocaleKeepsExactDatasetCounts(tc)
verifyEqual(tc, formatDisplayCount(114077,"tr"), "114.077");
verifyEqual(tc, formatDisplayCount(114077,"en"), "114,077");
verifyEqual(tc, formatDisplayCount(38204,"tr"), "38.204");
verifyEqual(tc, formatDisplayCount(0,"tr"), "0");
verifyEqual(tc, formatDisplayCount(1000000,"tr"), "1.000.000");
end
function testMissingCountsDifferFromZero(tc)
for v = [NaN Inf -Inf]
    verifyEqual(tc, formatDisplayCount(v,"tr"), "—");
end
verifyEqual(tc, formatDisplayCount([],"en"), "—");
verifyError(tc, @() formatDisplayCount([1;2],"tr"), "MOSAIC:CountShape");
end
function testDefaultLanguageAndMetadataFormatting(tc)
uiText("--lang","tr");
verifyEqual(tc, formatDisplayCount(38204), "38.204");
verifyEqual(tc, datasetFormatLabel("network_flow"), uiText("Network flows"));
verifyFalse(tc, contains(datasetFormatLabel("network_flow"), "network_flow"));
uiText("--lang","en");
verifyEqual(tc, formatDisplayCount(38204), "38,204");
verifyEqual(tc, datasetFormatLabel("unsupported_internal_key"), "Imported dataset");
end
