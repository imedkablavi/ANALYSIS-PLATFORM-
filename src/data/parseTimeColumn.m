function [t, note] = parseTimeColumn(v, unit)
%PARSETIMECOLUMN Convert an imported time column to an unzoned datetime column.
%
%   [T, NOTE] = PARSETIMECOLUMN(V, UNIT) accepts what readtable returns for
%   a time column:
%     datetime         time zone is removed (all project dates are unzoned)
%     numeric          UNIT "auto" (default):
%                        all integers in 19000101..21001231 -> yyyyMMdd dates
%                        max > 1e11 -> POSIX milliseconds
%                        max >= 1e6 -> POSIX seconds (SNAP convention;
%                                      relative offsets then start in 1970,
%                                      only relative timing is meaningful)
%                        otherwise  -> error: Excel serials, datenums and
%                                      small offsets are indistinguishable,
%                                      so UNIT must be given explicitly
%                      or explicitly "posix_s", "posix_ms", "excel",
%                      "datenum", "yyyymmdd"
%     text             parsed with datetime's format inference; if that
%                      fails, a list of common formats is tried
%   Unparseable values become NaT; they are never dropped here, so the
%   validation report (check V43) counts them. NOTE describes the
%   interpretation for the import record.

arguments
    v
    unit (1,1) string {mustBeMember(unit, ["auto","posix_s","posix_ms","excel","datenum","yyyymmdd"])} = "auto"
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
        f = x(isfinite(x));
        if isempty(f)
            unit = "posix_s";
        elseif all(f == round(f) & f >= 19000101 & f <= 21001231)
            unit = "yyyymmdd";
        elseif max(abs(f)) > 1e11
            unit = "posix_ms";
        elseif max(abs(f)) >= 1e6
            unit = "posix_s";
        else
            error("MOSAIC:AmbiguousTimeUnit", ...
                "Numeric times below 1e6 are ambiguous (Excel serial, datenum or small offsets). " + ...
                "Set time_unit to ""excel"", ""datenum"" or ""posix_s"".");
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
        case "yyyymmdd"
            t = datetime(x, 'ConvertFrom', 'yyyymmdd');
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
