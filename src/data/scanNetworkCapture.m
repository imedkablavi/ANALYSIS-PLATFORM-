function S = scanNetworkCapture(path, blockRows)
%SCANNETWORKCAPTURE Label counts per block of a large network capture (fast pre-scan).
%
%   S = SCANNETWORKCAPTURE(PATH, BLOCKROWS) reads ONLY the time and label
%   columns of a headered network file (CTU-13, CIC-IDS2017, UNSW-NB15 with
%   header) in blocks of BLOCKROWS records (default 250,000) and returns one
%   row per block: block, first_row, last_row, t_start, t_end, malicious,
%   benign, unknown. Use it to choose first_row/max_rows for analyzeDataset
%   when the whole capture does not fit in memory or time: the attack in a
%   capture can start late (CTU-13 scenario 1 has no botnet flow in its first
%   500,000 records).
%
%   Choosing the slice by its label counts is a selection of the EVALUATION
%   window only; the detectors still never see labels. Report the slice
%   (first_row, max_rows) with every result.

arguments
    path (1,1) string
    blockRows (1,1) double {mustBePositive} = 250000
end

base = textImportOptions(path);
names = reshape(string(base.VariableNames), 1, []);
[p, cols, msg] = matchNetworkProfile(path, names);
if isempty(p) || isempty(p.signature)
    error("MOSAIC:ScanUnsupported", "Pre-scan needs a headered network file. %s", msg);
end
timeCol = cols.time;
labelCol = cols.label;
ds = tabularTextDatastore(path, 'TextType', 'string', 'VariableNamingRule', 'preserve', ...
    'ReadSize', blockRows);
ds.SelectedVariableNames = cellstr([timeCol, labelCol]);
ds.SelectedFormats = repmat({'%q'}, 1, 2);
rows = {};
first = 1;
k = 0;
runLog("scanning %s in blocks of %d records ...", path, blockRows);
while hasdata(ds)
    T = read(ds);
    k = k + 1;
    n = height(T);
    [t, ~] = parseTimeColumn(T.(timeCol), p.time_unit, p.time_formats);
    cls = labelNetworkFlows(p.label_rule, strtrim(string(T.(labelCol))), strings(n, 1));
    rows(end+1, :) = {k, first, first + n - 1, min(t), max(t), nnz(cls == "malicious"), ...
        nnz(cls == "benign"), nnz(cls == "unknown")}; %#ok<AGROW>
    runLog("block %d: rows %d-%d, malicious %d, benign %d", k, first, first + n - 1, ...
        rows{end, 6}, rows{end, 7});
    first = first + n;
end
S = cell2table(rows, 'VariableNames', {'block', 'first_row', 'last_row', 't_start', ...
    't_end', 'malicious', 'benign', 'unknown'});
end
