function [t, note] = parseTimeColumn(v, unit)
%PARSETIMECOLUMN Convert an imported time column to an unzoned datetime column.
%
%   [T, NOTE] = PARSETIMECOLUMN(V, UNIT) accepts what readtable returns for
%   a time column:
%     datetime         time zone is removed (all project dates are unzoned)
%     numeric          UNIT "auto" (default): values > 1e11 are POSIX
%                      milliseconds, otherwise POSIX seconds (the SNAP
%                      temporal-network convention); or explicitly
%                      "posix_s", "posix_ms", "excel", "datenum"
%     text             parsed with datetime's format inference; if that
%                      fails, a list of common formats is tried
%   Unparseable values become NaT; they are never dropped here, so the
%   validation report (check V43) counts them. NOTE describes the
%   interpretation for the import record.

arguments
    v
    unit (1,1) string {mustBeMember(unit, ["auto","posix_s","posix_ms","excel","datenum"])} = "auto"
end

if isdatetime(v)
    t = v(:);
    t.TimeZone = '';
    note = "time column read as datetime";
    return;
end

if isnumeric(v) || islogical(v)
    x = double(v(:));
    if unit == "auto"
        if max(abs(x(isfinite(x))), [], 'omitnan') > 1e11
            unit = "posix_ms";
        else
            unit = "posix_s";
        end
    end
    switch unit
        case "posix_s"
            t = datetime(x, 'ConvertFrom', 'posixtime');
        case "posix_ms"
            t = datetime(x / 1000, 'ConvertFrom', 'posixtime');
        case "excel"
            t = datetime(x, 'ConvertFrom', 'excel');
        case "datenum"
            t = datetime(x, 'ConvertFrom', 'datenum');
    end
    t.TimeZone = '';
    note = "numeric time interpreted as " + unit;
    return;
end

s = string(v(:));
s(ismissing(s)) = "";
t = NaT(numel(s), 1);
has = strlength(strtrim(s)) > 0;
if ~any(has)
    note = "time column is empty";
    return;
end
note = "";
try
    t(has) = datetime(s(has));
    note = "text time parsed with inferred format";
catch
    formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd", ...
        "dd.MM.yyyy HH:mm", "dd.MM.yyyy", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy/MM/dd"];
    best = 0;
    for f = formats
        cand = NaT(numel(s), 1);
        try
            cand(has) = datetime(s(has), 'InputFormat', f);
        catch
            continue;
        end
        ok = nnz(~isnat(cand));
        if ok > best
            best = ok;
            t = cand;
            note = "text time parsed with format " + f;
        end
    end
    if best == 0
        note = "time column could not be parsed (all NaT)";
    end
end
t.TimeZone = '';
end
