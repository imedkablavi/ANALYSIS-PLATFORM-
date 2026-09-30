function [tokens, stepThreshold] = encodeEventSequences(events, pairEvents, cfg)
%ENCODEEVENTSEQUENCES Encode each offender's history as a token sequence.
%
%   [TOKENS, STEPTHRESHOLD] = ENCODEEVENTSEQUENCES(EVENTS, PAIREVENTS, CFG)
%
%   The artifact has no event-type field, so the alphabet is derived from
%   two observable, causal properties of each event (sequenceAlphabet):
%     - partner state: solo / repeat partners only / new partner, where
%       "new" means not co-offended with in any EARLIER event of the same
%       offender (uses past information only; no look-ahead);
%     - spatial move relative to the offender's previous crime site, split
%       at a global quantile of all consecutive steps (cfg.spatial.
%       local_move_quantile, default median).
%
%   TOKENS: canonicalEvents(EVENTS) plus columns
%     group_state, step_distance, move, token
%   STEPTHRESHOLD: the step length separating L from F moves.

arguments
    events table
    pairEvents table
    cfg struct = struct()
end

q = cfgGet(cfg, "spatial.local_move_quantile", 0.5);
ev = canonicalEvents(events);
E = height(ev);

% --- spatial move -----------------------------------------------------------
sameEntity = [false; diff(ev.entity_index) == 0];
step = NaN(E,1);
if E > 1
    d = sqrt(diff(ev.x).^2 + diff(ev.y).^2);
    step([false; sameEntity(2:end)]) = d(sameEntity(2:end));
end
stepThreshold = empiricalQuantile(step, q);
move = repmat("U", E, 1);
move(~sameEntity) = "0";
move(sameEntity & step <= stepThreshold) = "L";
move(sameEntity & step > stepThreshold) = "F";

% --- partner state ----------------------------------------------------------
state = repmat("S", E, 1);
if height(pairEvents) > 0 && E > 0
    [crimeList, ~, evCrime] = unique(ev.crime_id);
    [~, peCrime] = ismember(pairEvents.crime_id, crimeList);
    ego = [pairEvents.a_index; pairEvents.b_index];
    alter = [pairEvents.b_index; pairEvents.a_index];
    crimeG = [peCrime; peCrime];
    K = numel(crimeList) + 1;
    [found, evRow] = ismember(ego * K + crimeG, ev.entity_index * K + evCrime);
    ego = ego(found); alter = alter(found); evRow = evRow(found);
    pos = ev.seq_pos(evRow);
    gPair = findgroups(ego, alter);
    firstPos = accumarray(gPair, pos, [], @min);
    isNew = pos == firstPos(gPair);
    hasPartner = accumarray(evRow, 1, [E 1]) > 0;
    hasNew = accumarray(evRow, double(isNew), [E 1]) > 0;
    state(hasPartner) = "R";
    state(hasNew) = "N";
end

tokens = ev;
tokens.group_state = state;
tokens.step_distance = step;
tokens.move = move;
tokens.token = state + move;
end
