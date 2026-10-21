function s = formatCount(n)
%FORMATCOUNT Compact count for stat tiles: 1,284 / 12.3K / 1.5M.
%
%   S = FORMATCOUNT(N) returns a string. Below 10,000 the exact integer
%   with thousands separators; below one million thousands with one
%   decimal ("K"); otherwise millions with one decimal ("M"). NaN or
%   empty gives an em dash. Negative values keep their sign.

if isempty(n) || isnan(n)
    s = "—";
    return;
end
sgn = "";
if n < 0
    sgn = "-";
    n = -n;
end
n = round(n);
if n < 10000
    s = sgn + string(regexprep(sprintf('%d', n), '(\d)(?=(\d{3})+$)', '$1,'));
elseif round(n / 1e3, 1) < 1000
    s = sgn + string(sprintf('%.1fK', n / 1e3));
else
    s = sgn + string(sprintf('%.1fM', n / 1e6));
end
end
