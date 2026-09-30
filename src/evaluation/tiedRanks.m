function r = tiedRanks(v)
%TIEDRANKS Ascending ranks with ties receiving their average rank.
%   Base-MATLAB replacement for tiedrank (keeps metrics toolbox-free and
%   unit-testable).

v = v(:);
n = numel(v);
[s, order] = sort(v);
r = zeros(n, 1);
i = 1;
while i <= n
    j = i;
    while j < n && s(j+1) == s(i)
        j = j + 1;
    end
    r(order(i:j)) = (i + j) / 2;
    i = j + 1;
end
end
