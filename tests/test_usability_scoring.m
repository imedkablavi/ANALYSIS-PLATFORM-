function tests = test_usability_scoring
%TEST_USABILITY_SCORING SUS scoring and usability-log summary (experiment E10).
%   Expected values are hand-computed (arithmetic in the comments) and were
%   cross-checked with an independent calculation. No participant data.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function testAllThreesIsFifty(tc)
% odd: 5 x (3-1) = 10; even: 5 x (5-3) = 10; (10+10) x 2.5 = 50
verifyEqual(tc, scoreSUS(3 * ones(1, 10)), 50);
end

function testBestResponsesIsHundred(tc)
% odd = 5 -> 4 each, even = 1 -> 4 each; 40 x 2.5 = 100
verifyEqual(tc, scoreSUS(repmat([5 1], 1, 5)), 100);
end

function testWorstResponsesIsZero(tc)
% odd = 1 -> 0 each, even = 5 -> 0 each; 0 x 2.5 = 0
verifyEqual(tc, scoreSUS(repmat([1 5], 1, 5)), 0);
end

function testMixedCases(tc)
% Row A = [4 2 4 1 3 2 5 2 4 3]
%   odd  items 4,4,3,5,4 -> 3+3+2+4+3 = 15
%   even items 2,1,2,2,3 -> 3+4+3+3+2 = 15
%   (15+15) x 2.5 = 75
% Row B = [2 4 3 3 2 4 3 4 2 5]
%   odd  items 2,3,2,3,2 -> 1+2+1+2+1 = 7
%   even items 4,3,4,4,5 -> 1+2+1+1+0 = 5
%   (7+5) x 2.5 = 30
R = [4 2 4 1 3 2 5 2 4 3; 2 4 3 3 2 4 3 4 2 5];
verifyEqual(tc, scoreSUS(R), [75; 30]);
end

function testMissingItemGivesNaNAndIsExcluded(tc)
% Scores: 50, 100, 0, 75, 30, NaN (row 6 = row A with item 3 missing).
% Summary over the 5 complete rows:
%   mean   = (50+100+0+75+30)/5 = 255/5 = 51
%   devs   = -1, 49, -51, 24, -21; squares 1+2401+2601+576+441 = 6020
%   sd     = sqrt(6020/4) = sqrt(1505) = 38.7943...
%   median = 50; min = 0; max = 100
R = [3 * ones(1, 10); repmat([5 1], 1, 5); repmat([1 5], 1, 5); ...
    4 2 4 1 3 2 5 2 4 3; 2 4 3 3 2 4 3 4 2 5; 4 2 NaN 1 3 2 5 2 4 3];
[s, summary] = scoreSUS(R);
verifyEqual(tc, s(1:5), [50; 100; 0; 75; 30]);
verifyTrue(tc, isnan(s(6)));
verifyEqual(tc, summary.n, 5);
verifyEqual(tc, summary.n_incomplete, 1);
verifyEqual(tc, summary.mean, 51, 'AbsTol', 1e-12);
verifyEqual(tc, summary.sd, sqrt(1505), 'AbsTol', 1e-12);
verifyEqual(tc, summary.median, 50);
verifyEqual(tc, summary.min, 0);
verifyEqual(tc, summary.max, 100);
end

function testAllMissingGivesNaNSummary(tc)
[s, summary] = scoreSUS(NaN(2, 10));
verifyTrue(tc, all(isnan(s)));
verifyEqual(tc, summary.n, 0);
verifyTrue(tc, isnan(summary.mean));
end

function testInvalidValueErrors(tc)
R = 3 * ones(1, 10);
R(4) = 6;
verifyError(tc, @() scoreSUS(R), "MOSAIC:SUSInput");
R(4) = 0;
verifyError(tc, @() scoreSUS(R), "MOSAIC:SUSInput");
R(4) = 2.5;
verifyError(tc, @() scoreSUS(R), "MOSAIC:SUSInput");
end

function testWrongWidthErrors(tc)
verifyError(tc, @() scoreSUS(3 * ones(2, 9)), "MOSAIC:SUSInput");
verifyError(tc, @() scoreSUS(table((1:2)', 'VariableNames', {'q1'})), "MOSAIC:SUSInput");
end

function testTableEqualsMatrix(tc)
R = [4 2 4 1 3 2 5 2 4 3; 2 4 3 3 2 4 3 4 2 5; 4 2 NaN 1 3 2 5 2 4 3];
T = array2table(R, 'VariableNames', cellstr("q" + (1:10)));
T = addvars(T, ["P01"; "P02"; "P03"], 'Before', 1, 'NewVariableNames', 'participant_id');
[sM, sumM] = scoreSUS(R);
[sT, sumT] = scoreSUS(T);
verifyEqual(tc, sT, sM);
verifyEqual(tc, sumT, sumM);
end

function testSummarizeUsabilityLog(tc)
% T1: durations 60-0=60, 100-10=90, 45-0=45 -> median 60
%     success (1 + 0.5 + 1)/3 = 0.8333; assists (0+1+0)/3 = 1/3
% T2: durations 220-100=120, 180-120=60 -> median (60+120)/2 = 90
%     success (0 + 1)/2 = 0.5; assists (2+0)/2 = 1
L = table(["P01"; "P02"; "P03"; "P01"; "P02"], ["T1"; "T1"; "T1"; "T2"; "T2"], ...
    [0; 10; 0; 100; 120], [60; 100; 45; 220; 180], [1; 0.5; 1; 0; 1], ...
    [0; 1; 0; 2; 0], [0; 1; 0; 1; 0], repmat("", 5, 1), 'VariableNames', ...
    {'participant_id','task_id','start_s','end_s','success','assists','errors','notes'});
S = summarizeUsabilityLog(L);
verifyEqual(tc, S.task_id, ["T1"; "T2"]);
verifyEqual(tc, S.n, [3; 2]);
verifyEqual(tc, S.success_rate, [2.5 / 3; 0.5], 'AbsTol', 1e-12);
verifyEqual(tc, S.median_time_s, [60; 90]);
verifyEqual(tc, S.mean_assists, [1 / 3; 1], 'AbsTol', 1e-12);
verifyEqual(tc, S.mean_errors, [1 / 3; 0.5], 'AbsTol', 1e-12);
end

function testSummarizeUsabilityLogRejectsBadSuccess(tc)
L = table("T1", 0, 10, 0.7, 0, 'VariableNames', ...
    {'task_id','start_s','end_s','success','assists'});
verifyError(tc, @() summarizeUsabilityLog(L), "MOSAIC:UsabilityLogInput");
end
