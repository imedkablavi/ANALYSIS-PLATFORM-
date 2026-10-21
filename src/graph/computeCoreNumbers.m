function core = computeCoreNumbers(A)
%COMPUTECORENUMBERS k-core number of every node of an undirected graph.
%
%   CORE = COMPUTECORENUMBERS(A) for a symmetric (sparse) adjacency matrix A
%   without self-loops. Batch peeling (Batagelj & Zaversnik, 2003): at
%   level k, repeatedly remove all nodes with remaining degree <= k and
%   assign them core number k. Each peeling round is vectorized; the number
%   of rounds is small for sparse co-offending graphs.

A = spones(A);
A = A - diag(diag(A));
n = size(A, 1);
core = zeros(n, 1);
alive = true(n, 1);
deg = full(sum(A, 2));
while any(alive)
    k = min(deg(alive));
    while true
        peel = alive & deg <= k;
        if ~any(peel)
            break;
        end
        core(peel) = k;
        alive(peel) = false;
        deg = deg - full(sum(A(:, peel), 2));
    end
end
end
