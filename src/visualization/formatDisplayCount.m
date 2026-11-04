function text = formatDisplayCount(n, lang)
%FORMATDISPLAYCOUNT Exact count in Turkish/English presentation conventions.
%   Analysis values are untouched; only display grouping changes. Undefined
%   counts are shown as an em dash, never as a measured zero or abbreviation.
arguments
    n double
    lang (1,1) string {mustBeMember(lang,["tr","en"])} = uiText("--lang")
end
if isempty(n)
    text = "—";
    return;
end
if ~isscalar(n)
    error("MOSAIC:CountShape", "Display counts must be scalar.");
end
if ~isfinite(n)
    text = "—";
    return;
end
separator = ',';
if lang == "tr"
    separator = '.';
end
text = string(regexprep(sprintf('%.0f', n), '(\d)(?=(\d{3})+$)', ['$1' separator]));
end
