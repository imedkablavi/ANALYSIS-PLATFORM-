function tests = test_playback_correctness
%TEST_PLAYBACK_CORRECTNESS Exclusive replay endpoints at each time scale.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

function testMinuteBins(tc)
checkBins(tc, datetime(2020,1,1) + minutes((0:3)'));
end

function testHourBins(tc)
checkBins(tc, datetime(2020,1,1) + hours((0:3)'));
end

function testCalendarMonthBins(tc)
checkBins(tc, datetime(2020,1,1) + calmonths((0:3)'));
end

function checkBins(tc, bins)
b = playbackFixture(bins);
% At the second bin's exclusive end, its unusual flag must be used,
% rather than the next bin's normal flag or an earlier day's flag.
fr = buildPlaybackFrame(b, bins(3), bins(2) - bins(1));
verifyEqual(tc, fr.bin, 2);
verifyTrue(tc, fr.bin_is_anomalous);
verifyEqual(tc, fr.crime_rows, 2);
% The following normal bin must clear the flag.
fr = buildPlaybackFrame(b, bins(4), bins(3) - bins(2));
verifyEqual(tc, fr.bin, 3);
verifyFalse(tc, fr.bin_is_anomalous);
% Nothing precedes the first bin start.
fr = buildPlaybackFrame(b, bins(1), bins(2) - bins(1));
verifyEmpty(tc, fr.bin);
verifyFalse(tc, fr.bin_is_anomalous);
end

function b = playbackFixture(bins)
b.crimes = table(bins, 'VariableNames', {'event_time'});
b.pairEvents = table(zeros(0,1), zeros(0,1), NaT(0,1), ...
    'VariableNames', {'a_index','b_index','event_time'});
b.relations = table(zeros(0,1), zeros(0,1), zeros(0,1), NaT(0,1), ...
    'VariableNames', {'a_index','b_index','weight','first_time'});
b.temporal.series = table(bins, 'VariableNames', {'bin_start'});
b.temporal.crime_anomalies = table(logical([0;1;0;0]), false(4,1), ...
    'VariableNames', {'is_high','is_low'});
end
