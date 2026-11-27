function v = cfgGet(cfg, path, default)
%CFGGET Read a nested configuration value with a default.
%
%   V = CFGGET(CFG, "temporal.series_start", DEFAULT) returns
%   CFG.temporal.series_start when it exists and DEFAULT otherwise. This
%   lets every analytical function run with an empty struct (unit tests)
%   while the pipeline passes the full projectConfig().

arguments
    cfg
    path (1,1) string
    default
end

v = default;
cur = cfg;
parts = split(path, ".");
for k = 1:numel(parts)
    name = char(parts(k));
    if isstruct(cur) && isscalar(cur) && isfield(cur, name)
        cur = cur.(name);
    else
        return;
    end
end
v = cur;
end
