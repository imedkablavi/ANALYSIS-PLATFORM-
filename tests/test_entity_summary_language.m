function tests = test_entity_summary_language
%TEST_ENTITY_SUMMARY_LANGUAGE Measured summaries translate without changing data.
tests = functiontests(localfunctions);
end

function setup(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.lang = uiText("--lang");
end

function teardown(tc)
uiText("--lang", tc.TestData.lang);
end

function b = measuredBundle()
% Deliberately small saved-table fixture, not an experiment performance claim.
b.entities = table(12, true, 0.75, 1, 3.2, 1, ...
    'VariableNames', {'event_count','eligible','iforest_score','iforest_rank', ...
    'baseline_score','baseline_rank'});
b.anomaly.settings.min_events = 3;
b.explanations.evidence = table(ones(4,1), ...
    ["event_count";"degree";"strength";"same_day_fraction"], ...
    ["old crime label";"old offender label";"old label";"old label"], ...
    [12;8;17;0.25], [4;2;5;0.1], [2;5;-4;1], ...
    'VariableNames', {'entity_index','feature','label','value','reference_median','robust_z'});
end

function testEnglishUsesMeasuredValuesAndThreeStrongestFeatures(tc)
uiText("--lang", "en");
b = measuredBundle();
original = b;
text = renderEntitySummary(b, 1);
verifyEqual(tc, size(text,2), 1);
verifyTrue(tc, any(contains(text, "score 0.75; rank 1 of 1 eligible entities")));
verifyTrue(tc, any(contains(text, "number of peers: value 8; reference median 2; robust z +5.00")));
verifyTrue(tc, any(contains(text, "total shared events with peers: value 17; reference median 5; robust z -4.00")));
verifyEqual(tc, nnz(contains(text, "reference median")), 3);
verifyFalse(tc, any(contains(text, ["old crime label", "old offender label", "confidence", "probability"])));
verifyTrue(tc, any(contains(text, "playback does not recompute scores")));
verifyEqual(tc, b, original);
end

function testTurkishUsesSameMeasurements(tc)
b = measuredBundle();
uiText("--lang", "en");
en = renderEntitySummary(b, 1);
uiText("--lang", "tr");
tr = renderEntitySummary(b, 1);
verifyNotEqual(tc, tr, en);
verifyTrue(tc, any(contains(tr, "0.75")));
verifyTrue(tc, any(contains(tr, "+5.00")));
verifyTrue(tc, any(contains(tr, "-4.00")));
verifyFalse(tc, any(contains(tr, ["Scope:", "Recorded events:", "reference median", "score unavailable"])));
end

function testInsufficientHistoryDoesNotPresentScores(tc)
b = measuredBundle();
b.entities.eligible = false;
b.entities.event_count = 1;
for lang = ["en", "tr"]
    uiText("--lang", lang);
    text = renderEntitySummary(b, 1);
    expected = uiText("Not scored: %g recorded events; at least %g are required.", 1, 3);
    verifyTrue(tc, any(text == expected));
    verifyFalse(tc, any(contains(text, ["0.75", "3.2", "+5.00"])));
end
end

function testOlderBundleMissingEvidenceAndScores(tc)
b.entities = table(4, true, 'VariableNames', {'event_count','eligible'});
for lang = ["en", "tr"]
    uiText("--lang", lang);
    text = renderEntitySummary(b, 1);
    verifyTrue(tc, any(text == uiText("%s: score unavailable.", uiText("Isolation Forest"))));
    verifyTrue(tc, any(text == uiText("Measured feature deviations are unavailable in this saved analysis.")));
    verifyFalse(tc, any(contains(text, "score 0")));
end
end

function testTextExportPreservesMeasurementsWithNumericSourceIdentifier(tc)
% The TXT export uses this renderer directly. A source ID such as "1" must
% never be globally replaced inside unrelated counts, ranks or feature values.
b = measuredBundle();
b.entities.entity_id = "1";
b.explanations.summary = table("private note for raw identifier 1", ...
    'VariableNames', {'evidence_text'});
folder = string(tempname);
mkdir(folder);
tc.addTeardown(@() rmdir(folder, 's'));
for lang = ["en", "tr"]
    uiText("--lang", lang);
    summary = renderEntitySummary(b, 1);
    file = fullfile(folder, "summary_" + lang + ".txt");
    writeTextFile(file, joinStrings(summary, newline));
    saved = string(fileread(file));
    verifyTrue(tc, contains(saved, uiText("Recorded events: %g.", 12)));
    verifyTrue(tc, contains(saved, uiText("%s: score %.3g; rank %g of %g eligible entities.", ...
        uiText("Isolation Forest"), 0.75, 1, 1)));
    verifyTrue(tc, contains(saved, uiText("%s: value %.3g; reference median %.3g; robust z %+.2f.", ...
        uiText("total shared events with peers"), 17, 5, -4)));
    verifyFalse(tc, contains(saved, "ENTITY-"));
    verifyFalse(tc, contains(saved, "private note"));
end
end
