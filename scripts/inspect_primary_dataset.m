% INSPECT_PRIMARY_DATASET
% First real-data gate for the Network Behavior Analysis project.
%
% Update DATA_FILE to the local downloaded artifact before running.

clear; clc;

DATA_FILE = fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json");

fprintf("Loading: %s\n", DATA_FILE);

data = loadBurglaryNetwork(DATA_FILE);
events = flattenBurglaryEvents(data);
report = validateBurglaryNetwork(data, events);

disp("=== Dataset Metadata ===");
disp(data.metadata);

disp("=== Validation ===");
disp(report);

fprintf("Nodes: %d\n", height(data.nodes));
fprintf("Links: %d\n", height(data.links));
fprintf("Offender-crime event rows: %d\n", height(events));
fprintf("Unique crimes: %d\n", numel(unique(events.crime_id)));

validDates = events.event_time(~ismissing(events.event_time));
if ~isempty(validDates)
    fprintf("Date range: %s -> %s\n", string(min(validDates)), string(max(validDates)));
end

fprintf("\nGenerating a first network plot...\n");
G = digraph(data.links.source_id, data.links.target_id, ...
    data.links.weight, data.nodes.entity_id);

figure("Name","MOSAIC-VAD / Primary Offender Network");
p = plot(G, "Layout","force", "NodeLabel",{});
p.MarkerSize = 2;
title(sprintf("Primary Offender Network — %d nodes / %d links", ...
    numnodes(G), numedges(G)));
