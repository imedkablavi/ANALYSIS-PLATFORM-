function alphabet = sequenceAlphabet()
%SEQUENCEALPHABET Fixed token alphabet for event sequences.
%
%   Token = <partner state><move>:
%     partner state  S = solo crime
%                    R = co-offended only with previously seen partners
%                    N = involves at least one partner never seen before
%     move           0 = first event of the entity (no previous site)
%                    L = local move (step <= global median step)
%                    F = far move (step > global median step)
%                    U = unknown (missing coordinates)
%   A fixed alphabet keeps transition matrices comparable across runs.

states = ["S","R","N"];
moves = ["0","L","F","U"];
[m, s] = meshgrid(moves, states);
alphabet = reshape(s + m, [], 1);
end
