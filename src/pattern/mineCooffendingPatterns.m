function patterns = mineCooffendingPatterns(events, relations, minRepeat)
%MINECOOFFENDINGPATTERNS Recurring co-offending pairs and exact groups.
%
%   PATTERNS = MINECOOFFENDINGPATTERNS(EVENTS, RELATIONS, MINREPEAT)
%
%   patterns.pairs   relations with weight >= MINREPEAT (recurring pairs),
%                    sorted by weight; includes first/last shared date and
%                    span, i.e. how long the collaboration persisted.
%   patterns.groups  exact offender sets of size >= 3 that appear together
%                    in >= MINREPEAT crimes: group_key (sorted entity
%                    indices), group_size, crimes, first_time, last_time.
%   patterns.summary counts for reporting.
%
%   Support is the number of crimes; entity indices (not raw IDs) are used
%   in keys so reports can be shared without listing identifiers.

arguments
    events table
    relations table
    minRepeat (1,1) double = 2
end

pairs = relations(relations.weight >= minRepeat, :);
pairs = sortrows(pairs, {'weight','span_days'}, {'descend','descend'});

ev = canonicalEvents(events);
groups = table(strings(0,1), zeros(0,1), zeros(0,1), NaT(0,1), NaT(0,1), ...
    'VariableNames', {'group_key','group_size','crimes','first_time','last_time'});
if height(ev) > 0
    g = findgroups(ev.crime_id);
    sz = accumarray(g, 1);
    big = sz(g) >= 3;
    if any(big)
        sub = ev(big, :);
        gs = g(big);
        [gs, order] = sortrows([gs sub.entity_index]);
        sub = sub(order, :);
        gc = findgroups(gs(:,1));
        keyPerCrime = splitapply(@(v) strjoin(string(v'), "-"), gs(:,2), gc);
        timePerCrime = splitapply(@(t) t(1), sub.event_time, gc);
        sizePerCrime = splitapply(@numel, gs(:,2), gc);
        [gk, keys] = findgroups(keyPerCrime);
        cnt = accumarray(gk, 1);
        tNum = days(timePerCrime - datetime(1970,1,1));
        firstT = datetime(1970,1,1) + days(accumarray(gk, tNum, [], @min));
        lastT = datetime(1970,1,1) + days(accumarray(gk, tNum, [], @max));
        gsize = accumarray(gk, sizePerCrime, [], @max);
        allGroups = table(keys, gsize, cnt, firstT, lastT, 'VariableNames', ...
            {'group_key','group_size','crimes','first_time','last_time'});
        groups = sortrows(allGroups(allGroups.crimes >= minRepeat, :), ...
            {'crimes','group_size'}, {'descend','descend'});
    end
end

patterns.pairs = pairs;
patterns.groups = groups;
patterns.summary = struct( ...
    'relations', height(relations), ...
    'recurring_pairs', height(pairs), ...
    'recurring_pair_share', height(pairs) / max(height(relations), 1), ...
    'recurring_groups', height(groups), ...
    'min_repeat', minRepeat);
end
