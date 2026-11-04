function tests = test_import_ui_contract
%TEST_IMPORT_UI_CONTRACT Localization preserves filenames and diagnostics.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.lang = uiText("--lang");
end

function teardown(tc)
uiText("--lang", tc.TestData.lang);
end

function testTranslatedImportPreservesFilenameAndFormat(tc)
uiText("--lang", "tr");
file = "capture%20-part03.binetflow";
s = uiText("%s (%s). Columns were detected automatically.", file, "network_flow");
verifyTrue(tc, contains(s, file));
verifyTrue(tc, contains(s, "network_flow"));
verifyTrue(tc, contains(s, "otomatik"));
verifyEqual(tc, uiText("(not used)"), "(kullanılmıyor)");
end

function testNumericDiagnosticIsNotReformatted(tc)
uiText("--lang", "tr");
diagnostic = "Protocol tcp: 17 records, 192.0.2.5:443, 20% invalid";
s = uiText("Import failed: %s", diagnostic);
verifyTrue(tc, endsWith(s, diagnostic));
% Unknown diagnostic messages pass through without inventing translations.
verifyEqual(tc, uiText(diagnostic), diagnostic);
end

function testSupportedExtensionsRemainVisibleInBothLanguages(tc)
key = "Supported datasets (*.json, *.csv, *.txt, *.tsv, *.binetflow)";
for lang = ["en", "tr"]
    uiText("--lang", lang);
    s = uiText(key);
    for extension = ["*.json", "*.csv", "*.txt", "*.tsv", "*.binetflow"]
        verifyTrue(tc, contains(s, extension));
    end
end
end
