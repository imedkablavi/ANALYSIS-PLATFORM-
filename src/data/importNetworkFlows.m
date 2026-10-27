function ds = importNetworkFlows(path, profileId, meta, opts)
%IMPORTNETWORKFLOWS Read a network-traffic file (flows / auth events) into the dataset contract.
%
%   DS = IMPORTNETWORKFLOWS(PATH, PROFILEID, META, OPTS) reads PATH with the
%   networkFlowProfiles() layout PROFILEID and returns the same contract as
%   buildCanonicalDataset (nodes, links, events, graph, meta) plus
%     ds.flows   one row per flow / authentication event:
%                src_index, dst_index, event_index, time, duration_s,
%                bytes, packets, sport, dport, proto, failed,
%                label_class ("malicious" | "benign" | "unknown"),
%                label_role ("src" | "dst": which endpoint the label is
%                about), label_detail (attack category when published)
%   Hosts are the entities; every flow is one event with its two endpoints
%   as participants (a host talking to itself has one). Host identifiers
%   (IP addresses, computer names) are pseudonymized by default and never
%   stored in ds.flows (indices only).
%
%   OPTS fields (all optional):
%     max_rows      read only MAX_ROWS records (LANL files have hundreds
%                   of millions of rows; documented in the notes)
%     first_row     first record to read (default 1), with max_rows a
%                   contiguous slice of the capture
%     labels_file   LANL redteam.txt (time,user@domain,src computer,dst
%                   computer) for lanl_auth; matching events are malicious,
%                   all other events of the file benign
%     pseudonymize, keep_id_map   see buildCanonicalDataset
%
%   Labels are kept for EVALUATION ONLY: no feature reads them
%   (computeNetworkFeatures has no access to label columns).

arguments
    path (1,1) string
    profileId (1,1) string
    meta (1,1) struct
    opts struct = struct()
end

base = textImportOptions(path);
names = reshape(string(base.VariableNames), 1, []);
[p, cols, profileMsg] = matchNetworkProfile(path, names, profileId);

textRoles = ["src", "dst", "sport", "dport", "proto", "state", "outcome", "label", "label_detail"];
textCols = strings(1,0);
for r = textRoles
    textCols = [textCols, cols.(r)]; %#ok<AGROW>
end
if p.id == "lanl_auth"
    textCols = [textCols, names(p.positional == "src_user")];
end
if ~isempty(p.time_formats)
    % Text timestamps are parsed with the profile's formats, not with the
    % reader's automatic datetime detection (it would guess one format for
    % the whole column and silently misread day/month or microseconds).
    textCols = [textCols, cols.time];
end
o = textImportOptions(path, textCols(textCols ~= ""));
maxRows = cfgGet(opts, "max_rows", Inf);
firstRow = cfgGet(opts, "first_row", 1);
notes = strings(0,1);
if isfinite(maxRows) || firstRow > 1
    % first_row/max_rows select a contiguous block of records (a time
    % slice of the capture). The first records of a capture may contain no
    % attack at all (CTU-13 scenario 1: none in the first 500,000 flows).
    first = o.DataLines(1) + firstRow - 1;
    o.DataLines = [first, first + maxRows - 1];
    notes(end+1,1) = sprintf("Only records %d to %s were read (first_row/max_rows).", ...
        firstRow, string(firstRow + maxRows - 1));
end
T = readtable(path, o);
h = height(T);
if h == 0
    error("MOSAIC:EmptyDataset", "No records were read from %s.", path);
end

src = textOf(T, cols.src);
dst = textOf(T, cols.dst);
[t, tNote] = parseTimeColumn(T.(cols.time), p.time_unit, p.time_formats);
notes(end+1,1) = "Time: " + tNote + ".";
if p.id == "lanl_auth" || p.id == "lanl_flows"
    notes(end+1,1) = "LANL times are seconds from an undisclosed origin; " + ...
        "dates shown as 1970 offsets, only relative timing is meaningful.";
end

duration = numberOf(T, cols.duration) * p.duration_scale;
bytes = numberOf(T, cols.bytes);
packets = numberOf(T, cols.packets);
sport = numberOf(T, cols.sport);
dport = numberOf(T, cols.dport);
proto = categorical(textOf(T, cols.proto));
failed = NaN(h, 1);
if cols.outcome ~= ""
    out = lower(textOf(T, cols.outcome));
    failed(out == "fail") = 1;
    failed(out == "success") = 0;
end

[labelClass, labelRole, labelDetail, labelNote] = labelNetworkFlows(p.label_rule, ...
    textOf(T, cols.label), textOf(T, cols.label_detail));
if p.id == "lanl_auth" && isfield(opts, "labels_file") && strlength(string(opts.labels_file)) > 0
    [labelClass, labelNote] = lanlRedTeamLabels(string(opts.labels_file), T, ...
        names(p.positional == "time"), names(p.positional == "src_user"), src, dst);
    labelRole = repmat("src", h, 1);
end
notes(end+1,1) = labelNote;

% --- Canonical dataset: hosts = entities, one event per flow -----------------------
self = src == dst;
evId = "f" + string((1:h)');
canon = struct('pseudonymize', cfgGet(opts, "pseudonymize", true), ...
    'keep_id_map', cfgGet(opts, "keep_id_map", false));
meta.format = "network_flow";
meta.profile = p.id;
meta.profile_name = p.name;
meta.profile_check = profileMsg;
meta.n_rows = h;
meta.import_notes = [reshape(string(cfgGet(meta, "import_notes", strings(0,1))), [], 1); ...
    "Each record is one event between its source and destination host; " + ...
    "tie strength = number of shared flows."; notes];
if any(self)
    meta.import_notes(end+1,1) = sprintf("%d records have source = destination (one participant).", nnz(self));
end
[ds, rowEnt, rowEv] = buildCanonicalDataset([src; dst(~self)], [evId; evId(~self)], ...
    [t; t(~self)], [], [], meta, canon);

srcIdx = rowEnt(1:h);
dstIdx = srcIdx;
dstIdx(~self) = rowEnt(h+1:end);
keep = ~isnan(srcIdx) & ~isnan(dstIdx);
flows = table(srcIdx, dstIdx, rowEv(1:h), t, duration, bytes, packets, sport, dport, ...
    proto, failed, categorical(labelClass), categorical(labelRole), categorical(labelDetail), ...
    'VariableNames', {'src_index','dst_index','event_index','time','duration_s','bytes', ...
    'packets','sport','dport','proto','failed','label_class','label_role','label_detail'});
flows = flows(keep, :);
if any(~keep)
    ds.meta.import_notes(end+1,1) = sprintf("%d records without a source or destination host were dropped.", nnz(~keep));
end
ds.flows = flows;
ds.meta.n_flows = height(flows);
ds.meta.label_counts = struct('malicious', nnz(flows.label_class == "malicious"), ...
    'benign', nnz(flows.label_class == "benign"), ...
    'unknown', nnz(flows.label_class == "unknown"));
ds.meta.has_labels = ds.meta.label_counts.malicious + ds.meta.label_counts.benign > 0;
ds.meta.expected_entity_type = "entity";
end

function v = textOf(T, col)
% Text column (string), or "" for every row when the role is absent.
if isscalar(col) && col == ""
    v = strings(height(T), 1);
    return;
end
v = strtrim(string(T.(col(1))));
v(ismissing(v)) = "";
end

function v = numberOf(T, col)
% Numeric column; several columns are summed; NaN when the role is absent.
v = NaN(height(T), 1);
if isscalar(col) && col == ""
    return;
end
v = zeros(height(T), 1);
for c = col
    x = T.(c);
    if ~isnumeric(x)
        s = strtrim(string(x));
        x = str2double(s);
        % Recent MATLAB releases parse "0x0008" as hexadecimal 8. In CTU-13
        % such values are ICMP type/code fields, not ports: keep them NaN.
        x(startsWith(s, ["0x", "0X"])) = NaN;
    end
    v = v + double(x);
end
end

function [cls, note] = lanlRedTeamLabels(file, T, timeCol, userCol, src, dst)
% redteam.txt lines (time,user@domain,source computer,destination computer)
% mark the matching authentication events as malicious.
o = textImportOptions(file);
o = setvartype(o, o.VariableNames, 'string');
R = readtable(file, o);
if width(R) < 4
    error("MOSAIC:LabelsFile", "%s: expected 4 columns (time,user,src,dst).", file);
end
rk = strtrim(string(R{:,1})) + "|" + strtrim(string(R{:,2})) + "|" + ...
    strtrim(string(R{:,3})) + "|" + strtrim(string(R{:,4}));
tt = T.(timeCol);
if isnumeric(tt)
    tt = string(tt);
end
ek = strtrim(string(tt)) + "|" + strtrim(string(T.(userCol))) + "|" + src + "|" + dst;
hit = ismember(ek, rk);
cls = repmat("benign", height(T), 1);
cls(hit) = "malicious";
note = sprintf("Labels: %d of %d red-team events of %s matched the records read " + ...
    "(red team = authorised attack simulation; other events treated as benign).", ...
    nnz(ismember(rk, ek)), numel(rk), file);
end
