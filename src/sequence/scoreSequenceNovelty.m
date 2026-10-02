function [entitySeq, tokens] = scoreSequenceNovelty(tokens, model, nEntities)
%SCORESEQUENCENOVELTY Per-transition surprisal and per-entity sequence features.
%
%   [ENTITYSEQ, TOKENS] = SCORESEQUENCENOVELTY(TOKENS, MODEL, NENTITIES)
%   adds TOKENS.surprisal_bits = -log2 P(token_t | token_t-1) (NaN for the
%   first event of each entity) and returns ENTITYSEQ with one row per
%   entity index 1..NENTITIES:
%     seq_surprisal_mean, seq_surprisal_max   (NaN with < 2 events)
%     new_partner_rate                        (NaN with 0 events)

arguments
    tokens table
    model (1,1) struct
    nEntities (1,1) double
end

[~, code] = ismember(tokens.token, model.alphabet);
prevOk = [false; diff(tokens.entity_index) == 0];
from = [0; code(1:end-1)];
valid = prevOk & code > 0 & from > 0;
s = NaN(height(tokens), 1);
lin = sub2ind(size(model.P), from(valid), code(valid));
s(valid) = -log2(model.P(lin));
tokens.surprisal_bits = s;

idx = tokens.entity_index;
nValid = accumarray(idx(valid), 1, [nEntities 1]);
sumS = accumarray(idx(valid), s(valid), [nEntities 1]);
maxS = accumarray(idx(valid), s(valid), [nEntities 1], @max, NaN);
meanS = sumS ./ nValid;
meanS(nValid == 0) = NaN;

nEv = accumarray(idx, 1, [nEntities 1]);
nNew = accumarray(idx, double(tokens.group_state == "N"), [nEntities 1]);
newRate = nNew ./ nEv;
newRate(nEv == 0) = NaN;

entitySeq = table(meanS, maxS, newRate, 'VariableNames', ...
    {'seq_surprisal_mean','seq_surprisal_max','new_partner_rate'});
end
