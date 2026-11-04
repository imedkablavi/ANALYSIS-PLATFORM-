function opts = importDialogOptions(info, form)
%IMPORTDIALOGOPTIONS Validate an editable import form into pipeline options.
%   No data is imported here. Required mappings must name actual inspected
%   columns; numeric controls are validated without rounding. Zero maximum
%   means all records and is omitted from the pipeline's positive limit.
arguments
    info (1,1) struct
    form (1,1) struct
end
layout = string(cfgGet(form, "layout", ""));
columns = string(cfgGet(info, "columns", strings(0,1)));
opts = struct();
switch layout
    case "event_csv"
        fields = ["entity","event","time","x","y"];
        required = ["entity","time"];
    case "edge_csv"
        fields = ["source","target","time","weight"];
        required = ["source","target","time"];
    case "generic_network_flow"
        fields = ["src","dst","time","duration","bytes","packets","sport","dport","proto"];
        required = ["src","dst","time"];
        opts.profile = "generic_network_flow";
    case "network_flow"
        if string(cfgGet(info,"format","")) ~= "network_flow" || ...
                strlength(string(cfgGet(info,"profile",""))) == 0
            error("MOSAIC:ImportLayout", "%s", uiText("Choose a data layout."));
        end
        fields = strings(1,0);
        required = strings(1,0);
        opts.profile = string(info.profile);
    case "networkx_burglary_json"
        if string(cfgGet(info,"format","")) ~= layout
            error("MOSAIC:ImportLayout", "%s", uiText("Choose a data layout."));
        end
        fields = strings(1,0);
        required = strings(1,0);
    otherwise
        error("MOSAIC:ImportLayout", "%s", uiText("Choose a data layout."));
end
if ~isempty(fields) && isempty(columns)
    error("MOSAIC:ImportLayout", "%s", uiText("Column mapping requires a readable delimited text file."));
end
mapping = cfgGet(form, "mapping", struct());
if layout == "generic_network_flow"
    mapping.src = cfgGet(mapping,"src",cfgGet(mapping,"source",""));
    mapping.dst = cfgGet(mapping,"dst",cfgGet(mapping,"target",""));
end
opts.mapping = struct();
for field = fields
    value = string(cfgGet(mapping,field,""));
    if ~isscalar(value) || ismissing(value) || ...
            (strlength(value) > 0 && ~any(columns == value)) || ...
            (ismember(field,required) && strlength(value) == 0)
        error("MOSAIC:ImportMapping", "%s", uiText("Choose an existing column for each required field."));
    end
    opts.mapping.(field) = value;
end
if layout == "generic_network_flow"
    if numel(unique([opts.mapping.src,opts.mapping.dst,opts.mapping.time])) ~= 3
        error("MOSAIC:ImportMapping", "%s", uiText("Choose different columns for source, destination and time."));
    end
    opts.format = "network_flow";
else
    opts.format = layout;
end
name = string(cfgGet(form,"name",""));
if isscalar(name) && ~ismissing(name) && strlength(strtrim(name)) > 0
    opts.name = strtrim(name);
end
if layout ~= "networkx_burglary_json"
    unit = string(cfgGet(form,"time_unit","auto"));
    if ~isscalar(unit) || ~ismember(unit,["auto","posix_s","posix_ms","excel","datenum","yyyymmdd"])
        error("MOSAIC:ImportTimeUnit", "%s", uiText("Choose a supported timestamp unit."));
    end
    if unit ~= "auto"
        opts.time_unit = unit;
    end
    timeFormat = string(cfgGet(form,"time_format",""));
    if ~isscalar(timeFormat) || ismissing(timeFormat)
        error("MOSAIC:ImportTimeFormat", "%s", uiText("Enter one timestamp format or leave it blank."));
    end
    if strlength(strtrim(timeFormat)) > 0
        opts.time_formats = strtrim(timeFormat);
    end
end
if ismember(layout,["network_flow","generic_network_flow"])
    first = cfgGet(form,"first_row",1);
    maximum = cfgGet(form,"max_rows",0);
    if ~isnumeric(first) || ~isscalar(first) || ~isreal(first) || ~isfinite(first) || first < 1 || first ~= fix(first) || ...
            ~isnumeric(maximum) || ~isscalar(maximum) || ~isreal(maximum) || ~isfinite(maximum) || maximum < 0 || maximum ~= fix(maximum)
        error("MOSAIC:ImportRange", "%s", uiText("First record must be a positive integer; maximum records must be zero or a positive integer."));
    end
    opts.first_row = first;
    if maximum > 0
        opts.max_rows = maximum;
    end
end
end
