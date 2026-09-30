function model = fitTransitionModel(tokens, alpha, useRow)
%FITTRANSITIONMODEL First-order Markov model over event tokens.
%
%   MODEL = FITTRANSITIONMODEL(TOKENS, ALPHA, USEROW) counts transitions
%   token(t-1) -> token(t) inside each entity's sequence, using only rows
%   where USEROW is true (both ends must be usable; e.g. a training period
%   for temporal hold-out). Laplace smoothing with ALPHA:
%       P(j | i) = (C(i,j) + ALPHA) / (sum_j C(i,j) + ALPHA * K)
%
%   MODEL fields: alphabet (Kx1 string), counts (KxK), P (KxK), alpha,
%   n_transitions.

arguments
    tokens table
    alpha (1,1) double {mustBeNonnegative} = 1
    useRow (:,1) logical = true(height(tokens),1)
end

alphabet = sequenceAlphabet();
K = numel(alphabet);
[~, code] = ismember(tokens.token, alphabet);
prevOk = [false; diff(tokens.entity_index) == 0];
valid = prevOk & useRow & [false; useRow(1:end-1)] & code > 0 & [0; code(1:end-1)] > 0;
from = [0; code(1:end-1)];
counts = accumarray([from(valid) code(valid)], 1, [K K]);
P = (counts + alpha) ./ (sum(counts, 2) + alpha * K);

model.alphabet = alphabet;
model.counts = counts;
model.P = P;
model.alpha = alpha;
model.n_transitions = sum(valid);
end
