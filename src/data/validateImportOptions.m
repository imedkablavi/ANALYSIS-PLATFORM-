function opts = validateImportOptions(opts)
%VALIDATEIMPORTOPTIONS Normalize and validate supported dataset import options.
% Shared by orchestration and direct import callers; does not read the dataset.
arguments
    opts (1,1) struct
end
for key = ["format","profile","name","root_dir","labels_file","date_format","time_unit"]
    if isfield(opts, key)
        value = opts.(key);
        if ~(ischar(value) && (isrow(value) || isempty(value))) && ...
                ~(isstring(value) && isscalar(value) && ~ismissing(value))
            error("MOSAIC:InvalidImportOptions", "%s must be a text scalar.", key);
        end
        opts.(key) = string(value);
    end
end
if isfield(opts, 'format') && ~ismember(opts.format, ...
        ["networkx_burglary_json","event_csv","edge_csv","network_flow"])
    error("MOSAIC:InvalidImportOptions", "Unsupported explicit import format.");
end
if isfield(opts, 'time_unit') && ~ismember(opts.time_unit, ...
        ["auto","posix_s","posix_ms","excel","datenum","yyyymmdd"])
    error("MOSAIC:InvalidImportOptions", "Unsupported numeric time unit.");
end
if isfield(opts, 'time_formats')
    value = opts.time_formats;
    if ~(ischar(value) || isstring(value) || iscellstr(value))
        error("MOSAIC:InvalidImportOptions", "time_formats must contain text formats.");
    end
    value = reshape(string(value), 1, []);
    if isempty(value) || any(ismissing(value) | strlength(value) == 0)
        error("MOSAIC:InvalidImportOptions", "time_formats must contain nonempty formats.");
    end
    opts.time_formats = value;
end
for key = ["first_row","max_rows"]
    if ~isfield(opts, key)
        continue;
    end
    value = opts.(key);
    valid = isnumeric(value) && isscalar(value) && isreal(value) && ...
        ~isnan(value) && value >= 1 && (isinf(value) || value == fix(value));
    if ~valid || (key == "first_row" && ~isfinite(value))
        error("MOSAIC:InvalidImportOptions", "%s must be a positive integer (max_rows also accepts Inf).", key);
    end
end
for key = ["pseudonymize","keep_id_map","use_iforest","allow_invalid"]
    if isfield(opts, key) && ~(islogical(opts.(key)) && isscalar(opts.(key)))
        error("MOSAIC:InvalidImportOptions", "%s must be a logical scalar.", key);
    end
end
if isfield(opts, 'progress') && ~isempty(opts.progress) && ~isa(opts.progress, 'function_handle')
    error("MOSAIC:InvalidImportOptions", "progress must be a function handle or empty.");
end
if isfield(opts, 'mapping')
    if ~isstruct(opts.mapping) || ~isscalar(opts.mapping)
        error("MOSAIC:InvalidImportOptions", "mapping must be a scalar struct of column names.");
    end
    fields = fieldnames(opts.mapping);
    for k = 1:numel(fields)
        value = opts.mapping.(fields{k});
        if ~(ischar(value) && (isrow(value) || isempty(value))) && ...
                ~(isstring(value) && isscalar(value) && ~ismissing(value))
            error("MOSAIC:InvalidImportOptions", "Mapped columns must be text scalars.");
        end
        opts.mapping.(fields{k}) = string(value);
    end
end
if isfield(opts, 'info') && (~isstruct(opts.info) || ~isscalar(opts.info))
    error("MOSAIC:InvalidImportOptions", "info must be a scalar inspection struct.");
end
end
