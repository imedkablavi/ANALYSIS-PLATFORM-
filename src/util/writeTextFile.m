function writeTextFile(path, txt)
%WRITETEXTFILE Write text to a UTF-8 file (compatible with R2020b+).

arguments
    path (1,1) string
    txt (1,1) string
end

folder = fileparts(path);
if strlength(folder) > 0 && ~isfolder(folder)
    mkdir(folder);
end
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid < 0
    error("MOSAIC:WriteFailed", "Cannot write %s", path);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, '%s', txt);
end
