function [profile, cols, message] = matchNetworkProfile(path, names, profileId, mapping)
%MATCHNETWORKPROFILE Match a delimited file against the known network-traffic layouts.
%
%   [PROFILE, COLS, MESSAGE] = MATCHNETWORKPROFILE(PATH, NAMES) tries every
%   networkFlowProfiles() entry. NAMES are the variable names reported by
%   textImportOptions (VarN for headerless files).
%   - Headered profile: every signature name must be present after
%     normalization (lower case, punctuation and spaces removed).
%   - Headerless profile: the column count must equal the profile's
%     positional list AND every content check must pass on the first rows
%     (>= 90% of non-empty values), so a file with the right width but
%     different content is not mislabelled.
%   PROFILEID (optional) forces one profile; a failed check then raises
%   MOSAIC:ProfileMismatch with the reason instead of returning empty.
%
%   PROFILE is the matched profile ([] when none matches). COLS maps each
%   role of PROFILE.map to the actual variable name(s) of the read table
%   ("" when the role is absent from the file). MESSAGE explains the
%   decision (shown in the app and stored in the import notes).

arguments
    path (1,1) string
    names (1,:) string
    profileId (1,1) string = ""
    mapping (1,1) struct = struct()
end

P = networkFlowProfiles();
if profileId == "generic_network_flow"
    [profile, cols, message] = genericProfile(P, names, mapping, true);
    return;
end
if profileId ~= ""
    P = P([P.id] == profileId);
    if isempty(P)
        error("MOSAIC:UnknownProfile", "Unknown network profile: %s", profileId);
    end
end
profile = [];
cols = struct();
message = "No known network-traffic layout matched.";
headerless = ~isempty(names) && all(startsWith(names, "Var"));
norm = normalizeName(names);
reasons = strings(0,1);

for k = 1:numel(P)
    p = P(k);
    if p.id == "generic_network_flow"
        continue;
    end
    if ~isempty(p.signature)
        if headerless
            continue;
        end
        missing = p.signature(~ismember(p.signature, norm));
        if ~isempty(missing)
            reasons(end+1,1) = p.id + ": missing " + joinStrings(missing, ", "); %#ok<AGROW>
            continue;
        end
        actual = @(c) resolveHeadered(c, names, norm);
    else
        if ~headerless || numel(names) ~= numel(p.positional)
            reasons(end+1,1) = sprintf("%s: needs %d headerless columns (file: %d%s)", ...
                p.id, numel(p.positional), numel(names), ternary(headerless, "", ", has a header")); %#ok<AGROW>
            continue;
        end
        [ok, why] = contentChecks(path, names, p);
        if ~ok
            reasons(end+1,1) = p.id + ": " + why; %#ok<AGROW>
            continue;
        end
        actual = @(c) resolvePositional(c, names, p.positional);
    end
    profile = p;
    roleNames = string(fieldnames(p.map))';
    for r = roleNames
        cols.(r) = actual(string(p.map.(r)));
    end
    message = p.name + ". Layout check: " + p.verified;
    return;
end

if profileId == ""
    [generic, genericCols, genericMessage] = genericProfile(P, names, mapping, false);
    if ~isempty(generic)
        profile = generic; cols = genericCols; message = genericMessage;
        return;
    end
end

if ~isempty(reasons)
    message = message + " (" + joinStrings(reasons, "; ") + ")";
end
if profileId ~= ""
    error("MOSAIC:ProfileMismatch", "%s", message);
end
end

function n = normalizeName(s)
n = lower(regexprep(string(s), "[^A-Za-z0-9]", ""));
end

function out = resolveHeadered(c, names, norm)
% Column names of the profile -> the file's own spelling ("" if absent).
out = strings(size(c));
for k = 1:numel(c)
    if c(k) == ""
        continue;
    end
    j = find(norm == normalizeName(c(k)), 1);
    if ~isempty(j)
        out(k) = names(j);
    end
end
% A multi-column role is a total (for example forward + backward bytes).
% One missing component makes that total unobserved, rather than equal to
% the available direction alone. numberOf treats an absent role as NaN.
if numel(c) > 1 && any(out == "" & c ~= "")
    out = "";
    return;
end
out = out(out ~= "" | c == "");
if isempty(out)
    out = "";
end
end

function out = resolvePositional(c, names, positional)
out = strings(size(c));
for k = 1:numel(c)
    j = find(positional == c(k), 1);
    if ~isempty(j)
        out(k) = names(j);
    end
end
end

function [ok, why] = contentChecks(path, names, p)
ok = true;
why = "";
o = textImportOptions(path, names);           % every column as text
first = o.DataLines(1);
o.DataLines = [first, first + 199];
try
    T = readtable(path, o);
catch ME
    ok = false;
    why = "could not read the first rows (" + ME.message + ")";
    return;
end
for c = p.content_checks
    j = find(p.positional == c.column, 1);
    v = strtrim(string(T{:, j}));
    v = v(~ismissing(v) & v ~= "");
    if isempty(v)
        ok = false;
        why = c.column + " is empty";
        return;
    end
    switch c.kind
        case "ipv4"
            hit = matches(v, regexpPattern("\d{1,3}(\.\d{1,3}){3}"));
        case "integer"
            x = str2double(v);
            hit = isfinite(x) & x == round(x);
        case "number"
            hit = isfinite(str2double(v));
        case "binary"
            hit = ismember(v, ["0", "1"]);
        case "success_fail"
            hit = ismember(lower(v), ["success", "fail"]);
        otherwise
            error("MOSAIC:ProfileCheck", "Unknown content check: %s", c.kind);
    end
    if mean(hit) < 0.9
        ok = false;
        why = sprintf("column %s does not look like %s (%.0f%% of the first rows)", ...
            c.column, c.kind, 100 * mean(hit));
        return;
    end
end
end

function v = ternary(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end

function [p, cols, message] = genericProfile(P, names, mapping, explicit)
p = [];
cols = struct();
message = "";
normalized = lower(regexprep(names, "[^A-Za-z0-9]", ""));
roles = ["src","dst","time","duration","bytes","packets","sport","dport","proto", ...
    "state","outcome","label","label_detail"];
aliases = { ["srcip","sourceip","srcaddr","sourceaddress"], ...
    ["dstip","destinationip","destip","dstaddr","destinationaddress"], ...
    ["timestamp","starttime","flowstart","flowstarttime","eventtime","time"], ...
    ["duration","durationseconds","durations","dur"], ...
    ["bytes","totalbytes","totbytes"], ["packets","totalpackets","totpkts"], ...
    ["sport","srcport","sourceport"], ["dport","dstport","destinationport"], ...
    ["proto","protocol"], strings(1,0), strings(1,0), strings(1,0), strings(1,0) };
if isfield(mapping, "source") && ~isfield(mapping, "src")
    mapping.src = mapping.source;
end
if isfield(mapping, "target") && ~isfield(mapping, "dst")
    mapping.dst = mapping.target;
end
recognized = false(1,3);
for j = 1:numel(roles)
    role = roles(j);
    hits = find(ismember(normalized, aliases{j}));
    col = "";
    if j <= 3
        recognized(j) = ~isempty(hits);
    end
    if numel(hits) == 1
        col = names(hits);
    end
    if isfield(mapping, role)
        requested = string(mapping.(role));
        if ~isscalar(requested) || ismissing(requested) || (requested ~= "" && ~ismember(requested, names))
            error("MOSAIC:MappingMissing", "Column for %s is not found or is not scalar.", role);
        end
        col = requested;
    end
    cols.(role) = col;
end
% IP-specific endpoint names are the evidence for auto classification.
% Missing/ambiguous required fields are exposed for a mapping dialog.
if ~explicit && ~all(recognized(1:2))
    return;
end
required = [cols.src, cols.dst, cols.time];
if explicit && (any(required == "") || numel(unique(required)) ~= 3)
    error("MOSAIC:MappingMissing", "Custom flows require three distinct source, destination and time columns.");
end
p = P([P.id] == "generic_network_flow");
message = "Custom network flows; map source, destination and time. Labels are unknown.";
end
