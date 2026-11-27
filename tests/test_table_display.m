function tests = test_table_display
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function testPresentationCopyPreservesData(tc)
source = table(["baseline"; "iforest"], ["known_only"; "unknown_as_benign"], ...
    [NaN; 0.75], [true; false], ["Raw diagnostic 10%"; "HOST-0002"], ...
    'VariableNames', {'detector','setting','roc_auc','passed','message'});
before = source;
shown = localizeTableDisplay(source, "tr");
verifyEqual(tc, source, before);
verifyEqual(tc, shown.Properties.VariableNames, source.Properties.VariableNames);
verifyEqual(tc, shown.detector, ["Sağlam referans modeli"; "Isolation Forest"]);
verifyEqual(tc, shown.setting, ["Yalnızca bilinen etiketler"; "Bilinmeyen etiketler normal kabul edildi"]);
verifyEqual(tc, shown.roc_auc, source.roc_auc);
verifyTrue(tc, isnan(shown.roc_auc(1)));
verifyEqual(tc, shown.passed, source.passed);
verifyEqual(tc, shown.message, source.message);
end

function testUnknownAndMissingEnumsStayVisible(tc)
source = table(["outgoing"; "self"; "unrecognized"; missing], ...
    categorical(["warning"; "info"; "error"; "custom"]), ...
    'VariableNames', {'direction','severity'});
shown = localizeTableDisplay(source, "tr");
verifyEqual(tc, shown.direction(1:3), ["Giden"; "Kendiyle bağlantı"; "unrecognized"]);
verifyTrue(tc, ismissing(shown.direction(4)));
verifyEqual(tc, shown.severity, ["Uyarı"; "Bilgi"; "Hata"; "custom"]);
english = localizeTableDisplay(source, "en");
verifyEqual(tc, english.direction(1), "Outgoing");
end

function testHeadersAndLanguageState(tc)
previous = uiText("--lang");
tc.addTeardown(@() uiText("--lang", previous));
uiText("--lang", "en");
localizeTableDisplay(table(), "tr");
verifyEqual(tc, uiText("--lang"), "en");
verifyEqual(tc, uiText("--format", "tr", "support"), "Farklı varlık sayısı");
verifyEqual(tc, uiText("--format", "en", "ngram"), "Sequence pattern");
verifyError(tc, @() localizeTableDisplay(table(), "xx"), "MOSAIC:UnsupportedLanguage");
end
