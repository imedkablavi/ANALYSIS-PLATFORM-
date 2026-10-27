function events = flattenBurglaryEvents(data, dateFormat)
%FLATTENBURGLARYEVENTS Flatten nested offender crime details into an event table.
%
%   EVENTS = FLATTENBURGLARYEVENTS(DATA) returns one row per observed
%   offender-crime association with variables:
%
%     entity_id      anonymized offender ID (e.g. "OID#1")
%     entity_index   row of DATA.nodes (stable integer key)
%     crime_id       original crime ID restored from list_cid (e.g. "CID#2")
%     crime_num      numeric part of crime_id (NaN if not parseable)
%     x, y           normalized coordinates as stored in the artifact
%     event_time     datetime (day resolution in the verified artifact)
%     num_offenders  num_of_offenders field of the crime record
%     id_restored    false when a crime_details key had no list_cid match
%
%   Crime-ID restoration: jsondecode rewrites keys such as "CID#2" into
%   valid field names ("CID_2"). The original IDs are recovered by applying
%   matlab.lang.makeValidName to the node's list_cid entries and matching.
%
%   Rows are sorted by entity_index, event_time, crime_num. The crime_num
%   tie-break gives a deterministic order for same-day events; it is an
%   arbitrary but documented ordering (the artifact has no time of day).
%
%   Timestamps are parsed without a time zone so that they can be compared
%   with configuration dates (mixing zoned/unzoned datetimes is an error).

arguments
    data (1,1) struct
    dateFormat (1,1) string = "yyyy-MM-dd HH:mm:ss"
end

rawNodes = data.rawNodes;
nNodes = numel(rawNodes);

perNode = zeros(nNodes,1);
for i = 1:nNodes
    if isfield(rawNodes{i}, "crime_details") && isstruct(rawNodes{i}.crime_details)
        perNode(i) = numel(fieldnames(rawNodes{i}.crime_details));
    end
end
rows = sum(perNode);

entityIndex = zeros(rows,1);
crimeId = strings(rows,1);
x = NaN(rows,1);
y = NaN(rows,1);
dateText = strings(rows,1);
numOffenders = NaN(rows,1);
idRestored = true(rows,1);

r = 0;
for i = 1:nNodes
    if perNode(i) == 0
        continue;
    end
    node = rawNodes{i};
    keys = fieldnames(node.crime_details);

    % Map mangled field names back to original list_cid strings.
    original = strings(0,1);
    if isfield(node, "list_cid") && ~isempty(node.list_cid)
        original = string(cellstr(node.list_cid));
        original = original(:);
    end
    mangled = string(matlab.lang.makeValidName(cellstr(original)));
    [found, loc] = ismember(string(keys), mangled);

    for j = 1:numel(keys)
        r = r + 1;
        entityIndex(r) = i;
        if found(j)
            crimeId(r) = original(loc(j));
        else
            crimeId(r) = string(keys{j});
            idRestored(r) = false;
        end
        detail = node.crime_details.(keys{j});
        x(r) = numericField(detail, "X");
        y(r) = numericField(detail, "Y");
        numOffenders(r) = numericField(detail, "num_of_offenders");
        if isfield(detail, "date") && (ischar(detail.date) || isstring(detail.date))
            dateText(r) = string(detail.date);
        end
    end
end

eventTime = NaT(rows,1);
hasDate = strlength(dateText) > 0;
if any(hasDate)
    % Unparseable strings become NaT and are reported by validation.
    try
        eventTime(hasDate) = datetime(dateText(hasDate), 'InputFormat', dateFormat);
    catch
        idx = find(hasDate);
        for k = 1:numel(idx)
            try
                eventTime(idx(k)) = datetime(dateText(idx(k)), 'InputFormat', dateFormat);
            catch
                eventTime(idx(k)) = NaT;
            end
        end
    end
end

crimeNum = double(extractAfter(crimeId, "#"));
entityId = data.nodes.entity_id(entityIndex);
if isempty(entityId)
    entityId = strings(0,1);
end

events = table(entityId, entityIndex, crimeId, crimeNum, x, y, eventTime, ...
    numOffenders, idRestored, 'VariableNames', {'entity_id','entity_index', ...
    'crime_id','crime_num','x','y','event_time','num_offenders','id_restored'});

events = sortrows(events, {'entity_index','event_time','crime_num'});
end

function v = numericField(s, name)
v = NaN;
if isfield(s, name)
    f = s.(name);
    if isnumeric(f) && isscalar(f)
        v = double(f);
    end
end
end
