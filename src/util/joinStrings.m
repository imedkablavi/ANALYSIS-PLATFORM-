function s = joinStrings(parts, delimiter)
%JOINSTRINGS strjoin for any-orientation text vectors; empty input gives "".
%   strjoin is documented for 1-by-N inputs; this normalizes orientation.

if nargin < 2
    delimiter = " ";
end
parts = reshape(string(parts), 1, []);
if isempty(parts)
    s = "";
else
    s = strjoin(parts, delimiter);
end
end
