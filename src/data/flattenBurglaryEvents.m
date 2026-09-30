function events = flattenBurglaryEvents(data)
%FLATTENBURGLARYEVENTS Flatten nested offender crime details into events.
%
% EVENTS contains one row per observed offender-crime association.
% It is the core event table for temporal/spatial/behavioral analysis.

rawNodes = data.raw.nodes;
rows = sum(arrayfun(@(n) numel(fieldnames(n.crime_details)), rawNodes));

entityId = strings(rows,1);
crimeId = strings(rows,1);
x = NaN(rows,1);
y = NaN(rows,1);
eventDate = NaT(rows,1);
numOffenders = NaN(rows,1);

r = 0;
for i = 1:numel(rawNodes)
    node = rawNodes(i);
    if ~isfield(node, "crime_details") || isempty(node.crime_details)
        continue;
    end

    cids = fieldnames(node.crime_details);
    for j = 1:numel(cids)
        r = r + 1;
        cid = cids{j};
        detail = node.crime_details.(cid);

        entityId(r) = string(node.id);
        crimeId(r) = string(cid);

        if isfield(detail, "X"), x(r) = double(detail.X); end
        if isfield(detail, "Y"), y(r) = double(detail.Y); end
        if isfield(detail, "date")
            eventDate(r) = datetime(detail.date, ...
                'InputFormat','yyyy-MM-dd HH:mm:ss', ...
                'TimeZone','UTC');
        end
        if isfield(detail, "num_of_offenders")
            numOffenders(r) = double(detail.num_of_offenders);
        end
    end
end

events = table(entityId, crimeId, x, y, eventDate, numOffenders, ...
    'VariableNames', {'entity_id','crime_id','x','y','event_time','num_offenders'});

events = sortrows(events, {'entity_id','event_time','crime_id'});
end
