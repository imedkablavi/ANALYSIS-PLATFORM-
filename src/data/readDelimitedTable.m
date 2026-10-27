function T = readDelimitedTable(path, textColumns)
%READDELIMITEDTABLE Read a CSV/TSV/TXT table with original column names.
%
%   T = READDELIMITEDTABLE(PATH, TEXTCOLUMNS) reads with textImportOptions:
%   delimiter/header detection, column names kept as written, leading "#"
%   comment lines skipped, and TEXTCOLUMNS (identifier columns) read as
%   string. Headerless files get Var1, Var2, ... as names.

arguments
    path (1,1) string
    textColumns (1,:) string = strings(1,0)
end

if ~isfile(path)
    error("MOSAIC:DataFileNotFound", "Dataset file was not found: %s", path);
end
T = readtable(path, textImportOptions(path, textColumns));
end
