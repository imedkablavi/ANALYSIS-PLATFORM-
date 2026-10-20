function frame = buildPlaybackFrame(bundle, tEnd, windowLength)
%BUILDPLAYBACKFRAME State of the system for temporal playback at time tEnd.
%
%   FRAME = BUILDPLAYBACKFRAME(BUNDLE, TEND, WINDOWLENGTH) describes the
%   sliding window [TEND - WINDOWLENGTH, TEND). WINDOWLENGTH is a number
%   of months (numeric, as before) or a duration / calendarDuration (e.g.
%   12 * binStep("minute") for a short network capture):
%     frame.t0, frame.t1
%     frame.crime_rows     rows of bundle.crimes inside the window
%     frame.edges          buildGraphSnapshot table for the window
%     frame.bin            index of the temporal-series bin containing TEND-1 day
%     frame.bin_is_anomalous  robust-z flag of that bin (crime counts)
%     frame.new_edges      edges whose first-ever shared crime is in the window
%   Pure function: the app animates by calling it for successive TEND.

frame.t1 = tEnd;
if isnumeric(windowLength)
    windowLength = calmonths(windowLength);
end
frame.t0 = tEnd - windowLength;
c = bundle.crimes.event_time;
frame.crime_rows = find(c >= frame.t0 & c < frame.t1);
frame.edges = buildGraphSnapshot(bundle.pairEvents, frame.t0, frame.t1);
R = bundle.relations;
frame.new_edges = R(R.first_time >= frame.t0 & R.first_time < frame.t1, ...
    {'a_index','b_index','weight','first_time'});
bins = bundle.temporal.series.bin_start;
frame.bin = find(bins <= tEnd - days(1), 1, 'last');
frame.bin_is_anomalous = false;
if ~isempty(frame.bin)
    a = bundle.temporal.crime_anomalies;
    frame.bin_is_anomalous = a.is_high(frame.bin) || a.is_low(frame.bin);
end
end
