function ev = canonicalEvents(events)
%CANONICALEVENTS Deduplicated, deterministically ordered event table.
%
%   EV = CANONICALEVENTS(EVENTS) keeps the first row of every
%   (entity_index, crime_id) pair (duplicates are reported by validation
%   check V42, never silently merged without trace), sorts by
%   entity_index, event_time, crime_num and adds:
%     seq_pos   1-based position of the event within its entity's history
%
%   Same-day events are ordered by the numeric crime ID. The artifact has
%   day-resolution timestamps only, so this order is a documented
%   convention, not an observed order (docs/SEQUENCE_ANALYSIS.md).

if height(events) == 0
    ev = events;
    ev.seq_pos = zeros(0,1);
    return;
end
[~, keep] = unique(findgroups(events.entity_index, events.crime_id), 'stable');
ev = sortrows(events(keep,:), {'entity_index','event_time','crime_num'});
newEntity = [true; diff(ev.entity_index) ~= 0];
startRow = find(newEntity);
groupId = cumsum(newEntity);
ev.seq_pos = (1:height(ev))' - startRow(groupId) + 1;
end
