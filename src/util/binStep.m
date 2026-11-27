function step = binStep(unit)
%BINSTEP Calendar step of a temporal bin unit.
%
%   STEP = BINSTEP(UNIT) for UNIT "month" | "week" | "day" | "hour" |
%   "minute" returns calmonths(1), calweeks(1), caldays(1), hours(1) or
%   minutes(1). Bins start at dateshift(t, 'start', UNIT), so bin edges are
%   calendar-aligned for every unit.

arguments
    unit (1,1) string {mustBeMember(unit, ["month","week","day","hour","minute"])}
end

switch unit
    case "month"
        step = calmonths(1);
    case "week"
        step = calweeks(1);
    case "day"
        step = caldays(1);
    case "hour"
        step = hours(1);
    case "minute"
        step = minutes(1);
end
end
