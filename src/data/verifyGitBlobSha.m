function [ok, sha] = verifyGitBlobSha(filePath, expectedSha)
%VERIFYGITBLOBSHA Check a downloaded file against a Git blob SHA-1.
%
%   [OK, SHA] = VERIFYGITBLOBSHA(FILEPATH, EXPECTEDSHA) computes
%   sha1("blob <bytes>\0" + content), the identifier GitHub shows for the
%   file, so the local dataset can be tied to the exact upstream version
%   documented in docs/DATASET_SCHEMA_INSPECTION.md. Uses the JVM's
%   MessageDigest (available in desktop MATLAB).

arguments
    filePath (1,1) string
    expectedSha (1,1) string = ""
end

fid = fopen(filePath, 'r');
if fid < 0
    error("MOSAIC:DataFileNotFound", "Cannot open %s", filePath);
end
bytes = fread(fid, Inf, '*uint8');
fclose(fid);
header = uint8(sprintf('blob %d', numel(bytes)));
payload = [header(:); uint8(0); bytes(:)];
md = java.security.MessageDigest.getInstance('SHA-1');
md.update(typecast(payload, 'int8'));
digest = typecast(md.digest(), 'uint8');
sha = lower(string(reshape(dec2hex(digest, 2)', 1, [])));
ok = strlength(expectedSha) == 0 || sha == lower(expectedSha);
end
