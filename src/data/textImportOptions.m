function opts = textImportOptions(path, textColumns)
%TEXTIMPORTOPTIONS Import options for delimited text with safe comment and ID handling.
%
%   OPTS = TEXTIMPORTOPTIONS(PATH) detects delimiter and header. Only the
%   LEADING lines that start with "#" (SNAP-style comment header) are
%   skipped. 'CommentStyle' is deliberately not used: it would cut every
%   value at its first "#", which breaks IDs such as "OID#12" or "Apt #4".
%
%   OPTS = TEXTIMPORTOPTIONS(PATH, TEXTCOLUMNS) additionally forces the
%   named columns to string, so identifier columns are never parsed as
%   double (18-digit IDs exceed 2^53 and would merge silently).

arguments
    path (1,1) string
    textColumns (1,:) string = strings(1,0)
end

nSkip = 0;
fid = fopen(path, 'r');
if fid < 0
    error("MOSAIC:DataFileNotFound", "Dataset file was not found: %s", path);
end
cleaner = onCleanup(@() fclose(fid));
while true
    line = fgetl(fid);
    if ~ischar(line) || ~startsWith(strtrim(string(line)), "#")
        break;
    end
    nSkip = nSkip + 1;
end
clear cleaner

args = {'FileType', 'text', 'TextType', 'string', 'VariableNamingRule', 'preserve'};
if nSkip > 0
    args = [args, {'NumHeaderLines', nSkip}];
end
opts = detectImportOptions(path, args{:});
cols = textColumns(textColumns ~= "" & ismember(textColumns, string(opts.VariableNames)));
if ~isempty(cols)
    opts = setvartype(opts, cellstr(cols), 'string');
end
end
