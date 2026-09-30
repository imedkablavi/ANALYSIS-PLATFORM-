function report = validateBurglaryNetwork(data, events)
%VALIDATEBURGLARYNETWORK Validate the primary dataset and flattened events.

report = struct();
report.errors = strings(0,1);
report.warnings = strings(0,1);

if height(data.nodes) == 0
    report.errors(end+1) = "No nodes were loaded.";
end
if height(data.links) == 0
    report.errors(end+1) = "No links were loaded.";
end

if any(data.nodes.entity_id == "")
    report.errors(end+1) = "At least one node has an empty entity ID.";
end
if numel(unique(data.nodes.entity_id)) ~= height(data.nodes)
    report.errors(end+1) = "Node IDs are not unique.";
end

nodeSet = string(data.nodes.entity_id);
badSource = ~ismember(data.links.source_id, nodeSet);
badTarget = ~ismember(data.links.target_id, nodeSet);
if any(badSource) || any(badTarget)
    report.errors(end+1) = "At least one link references a missing node.";
end

if any(data.links.weight < 0, 'omitnan')
    report.errors(end+1) = "Negative edge weights detected.";
end

if any(ismissing(events.event_time))
    report.warnings(end+1) = "Some event timestamps are missing.";
end

if any(events.x < 0 | events.x > 1, 'omitnan') || ...
        any(events.y < 0 | events.y > 1, 'omitnan')
    report.errors(end+1) = "Spatial values fall outside the documented normalized [0,1] range.";
end

report.node_count = height(data.nodes);
report.link_count = height(data.links);
report.event_count = height(events);
report.unique_crime_count = numel(unique(events.crime_id));

validDates = events.event_time(~ismissing(events.event_time));
if ~isempty(validDates)
    report.date_min = min(validDates);
    report.date_max = max(validDates);
else
    report.date_min = NaT;
    report.date_max = NaT;
end

report.is_valid = isempty(report.errors);
end
