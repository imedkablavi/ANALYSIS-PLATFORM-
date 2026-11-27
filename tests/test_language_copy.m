function tests = test_language_copy
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.language = uiText("--lang");
end

function teardownOnce(tc)
uiText("--lang", tc.TestData.language);
end

function testFreshSessionUsesTurkish(tc)
clear uiText
verifyEqual(tc, uiText("--lang"), "tr");
verifyEqual(tc, uiText("Network Behaviour Explorer"), "Ağ Davranışı Analizi");
verifyEqual(tc, uiText("hosts"), "cihaz");
end

function testInvalidLanguagePreservesSelection(tc)
uiText("--lang", "tr");
verifyError(tc, @() uiText("--lang", "de"), "MOSAIC:UnsupportedLanguage");
verifyEqual(tc, uiText("--lang"), "tr");
verifyError(tc, @() uiText("--lang", ["tr", "en"]), "MOSAIC:UiTextArguments");
verifyError(tc, @() uiText(["Ranking", "Language"]), "MOSAIC:UiTextArguments");
end

function testExplicitFormattingPreservesSelectedLanguage(tc)
uiText("--lang", "en");
s = uiText("--format", "tr", "%s: score %.3g; rank %g of %g eligible entities.", ...
    "Isolation Forest", 0.75, 2, 40);
verifyEqual(tc, s, "Isolation Forest: puan 0.75; değerlendirmeye uygun 40 kayıt içinde 2. sırada.");
verifyEqual(tc, uiText("--lang"), "en");
verifyEqual(tc, uiText("--format", "en", "Recorded events: %g.", 5), "Recorded events: 5.");
verifyEqual(tc, uiText("--format", "tr", "Recorded events: %g.", 5), "Kayıtlı olay sayısı: 5.");
end

function testFallbackAndLiteralPercent(tc)
uiText("--lang", "tr");
verifyEqual(tc, uiText("Diagnostic is 50% complete"), "Diagnostic is 50% complete");
verifyEqual(tc, uiText("Türkçe"), "Türkçe");
verifyEqual(tc, uiText("English"), "English");
verifyEqual(tc, uiText("--format", "en", "No translation: %d", 7), "No translation: 7");
end

function testSummaryCopyPreservesScientificMeaning(tc)
s = uiText("--format", "tr", ...
    "Not scored: %g recorded events; at least %g are required.", 2, 3);
verifyEqual(tc, s, "Puanlanmadı: 2 olay kaydı var; en az 3 gerekiyor.");
verifyEqual(tc, uiText("--format", "tr", ...
    "Scope: the complete saved analysis; playback does not recompute scores."), ...
    "Puanlar kayıtlı analizin tamamına aittir. Oynatma sırasında yeniden hesaplanmaz.");
verifyEqual(tc, uiText("--format", "tr", "%s: value %.3g; reference median %.3g; robust z %+.2f.", ...
    "Akış sayısı", 12, 4, 2.5), ...
    "Akış sayısı: değer 12; referans medyan 4; sağlam z +2.50.");
end

function testMeasuredTableHeadersAreReadableInBothLanguages(tc)
verifyEqual(tc, uiText("--format", "tr", "duration_seconds"), "Süre (sn)");
verifyEqual(tc, uiText("--format", "en", "duration_seconds"), "Duration (s)");
verifyEqual(tc, uiText("--format", "tr", "average_precision"), "Ortalama kesinlik (AP)");
verifyEqual(tc, uiText("--format", "en", "malicious_not_scored"), "Malicious hosts not scored");
end

function testVisibleTableHeadingsAndEmptyStates(tc)
verifyEqual(tc, uiText("--format", "tr", "ngram"), "Dizi örüntüsü");
verifyEqual(tc, uiText("--format", "en", "occurrences"), "Occurrences");
verifyEqual(tc, uiText("--format", "tr", "%d warnings", 3), "3 uyarı");
verifyEqual(tc, uiText("--format", "tr", "Network flows"), "Ağ akışları");
verifyEqual(tc, uiText("--format", "tr", ...
    "Strongest deviations: %d of %d measured features.", 12, 24), ...
    "En belirgin sapmalar: ölçülen 24 özelliğin 12 tanesi.");
end
