function T = readDelimitedTable(path)
%READDELIMITEDTABLE Read a CSV/TSV/TXT table with original column names.
%
%   T = READDELIMITEDTABLE(PATH) uses detectImportOptions (delimiter and
%   header detection), keeps column names exactly as written
%   (VariableNamingRule "preserve"), reads text as string and ignores lines
%   starting with "#" (the SNAP edge-list convention). Headerless files get
%   Var1, Var2, ... as names.

arguments
    path (1,1) string
end

if ~isfile(path)
    error("MOSAIC:DataFileNotFound", "Dataset file was not found: %s", path);
end
opts = detectImportOptions(path, 'FileType', 'text', 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'CommentStyle', '#');
T = readtable(path, opts);
end
