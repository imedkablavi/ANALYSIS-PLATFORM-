function ngrams = mineSequenceNgrams(tokens, n, minSupport)
%MINESEQUENCENGRAMS Frequent and rare contiguous token n-grams.
%
%   NGRAMS = MINESEQUENCENGRAMS(TOKENS, N, MINSUPPORT) enumerates every
%   contiguous n-gram inside each entity's sequence (never across entities).
%   Returns a table sorted by support:
%     ngram, occurrences, support   (support = number of distinct entities)
%     is_frequent                   support >= MINSUPPORT
%   Rare n-grams are the rows with small support; they are candidates for
%   "unusual sequence" evidence, not proof of anything.

arguments
    tokens table
    n (1,1) double {mustBeInteger, mustBePositive} = 3
    minSupport (1,1) double = 5
end

E = height(tokens);
if E < n
    ngrams = table(strings(0,1), zeros(0,1), zeros(0,1), false(0,1), ...
        'VariableNames', {'ngram','occurrences','support','is_frequent'});
    return;
end
starts = (1:E-n+1)';
ok = tokens.entity_index(starts) == tokens.entity_index(starts + n - 1);
starts = starts(ok);
gram = tokens.token(starts);
for k = 1:n-1
    gram = gram + ">" + tokens.token(starts + k);
end
ent = tokens.entity_index(starts);
[g, key] = findgroups(gram);
occ = accumarray(g, 1);
[~, firstPerEntity] = unique([g ent], 'rows');
support = accumarray(g(firstPerEntity), 1, [numel(key) 1]);
ngrams = table(key, occ, support, support >= minSupport, ...
    'VariableNames', {'ngram','occurrences','support','is_frequent'});
ngrams = sortrows(ngrams, {'support','occurrences'}, {'descend','descend'});
end
