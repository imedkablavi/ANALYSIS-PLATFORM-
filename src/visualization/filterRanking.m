function [rows, shown] = filterRanking(entities, explanationsSummary, filterName, searchText)
%FILTERRANKING Rows and display table of the app's entity ranking.
%
%   [ROWS, SHOWN] = FILTERRANKING(ENTITIES, SUMMARY, FILTERNAME, SEARCHTEXT)
%   ENTITIES is bundle.entities (entity_id, eligible, iforest_rank,
%   iforest_score, baseline_rank, baseline_score, iforest_flag,
%   baseline_flag, event_count); SUMMARY is bundle.explanations.summary
%   (entity_index, dominant_group). FILTERNAME is one of
%     "Flagged (either detector)"     key = best rank of the two detectors
%     "Top 200 by Isolation Forest"   key = iforest_rank
%     "Top 200 by baseline"           key = baseline_rank
%     "All eligible" (and anything else)  key = iforest_rank, or the
%                                     baseline rank when IF was not run
%   Rows are sorted by the key ascending (stable: ties keep entity order,
%   NaN last). SEARCHTEXT (optional) keeps entities whose entity_id
%   contains it, case-insensitive; empty/blank = no search filter.
%   ROWS is a column of indices into ENTITIES; SHOWN is the table shown
%   in the app (entity, IF_rank, IF_score, base_rank, base_score, events,
%   main_group). Pure function, unit-tested.

if nargin < 4 || isempty(searchText)
    searchText = "";
end
e = entities;
switch string(filterName)
    case "Flagged (either detector)"
        idx = find(e.iforest_flag | e.baseline_flag);
        key = min(e.iforest_rank(idx), e.baseline_rank(idx));
    case "Top 200 by Isolation Forest"
        idx = find(e.iforest_rank <= 200);
        key = e.iforest_rank(idx);
    case "Top 200 by baseline"
        idx = find(e.baseline_rank <= 200);
        key = e.baseline_rank(idx);
    otherwise
        idx = find(e.eligible);
        key = e.iforest_rank(idx);
        if all(isnan(key))
            key = e.baseline_rank(idx);
        end
end
idx = idx(:);
[~, o] = sort(key(:));
rows = idx(o);

q = strtrim(string(searchText));
if strlength(q) > 0
    keep = contains(string(e.entity_id(rows)), q, 'IgnoreCase', true);
    rows = rows(keep);
end
rows = reshape(rows, [], 1);

S = explanationsSummary;
dom = repmat("", numel(rows), 1);
if ~isempty(S) && height(S) > 0
    [has, loc] = ismember(rows, S.entity_index);
    dom(has) = string(S.dominant_group(loc(has)));
end
shown = table(string(e.entity_id(rows)), e.iforest_rank(rows), ...
    round(e.iforest_score(rows), 3), e.baseline_rank(rows), ...
    round(e.baseline_score(rows), 2), e.event_count(rows), dom, ...
    'VariableNames', {'entity', 'IF_rank', 'IF_score', 'base_rank', ...
    'base_score', 'events', 'main_group'});
end
