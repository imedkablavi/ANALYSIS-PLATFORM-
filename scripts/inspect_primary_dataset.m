% INSPECT_PRIMARY_DATASET
% Quick look at the real artifact: validation summary and the largest
% connected co-offending component (plotting all 17k nodes with a force
% layout is slow and unreadable, so only the largest component is drawn).

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
dataFile = fullfile(rootDir, cfg.data.primary_file);
fprintf("Loading: %s\n", dataFile);

data = loadBurglaryNetwork(dataFile);
events = flattenBurglaryEvents(data, cfg.data.date_format);
report = validateBurglaryNetwork(data, events, cfg);
disp(report.checks);
disp(report.summary);

[relations, ~] = buildRelationTable(events, data.nodes.entity_id);
G = buildOffenderGraph(relations, data.nodes.entity_id);
bins = conncomp(G);
[~, big] = max(accumarray(bins(:), 1));
H = subgraph(G, find(bins == big));
figure("Name", "Largest co-offending component");
plot(H, "Layout", "force", "NodeLabel", {}, "MarkerSize", 2);
title(sprintf("Largest component: %d of %d offenders, %d ties", numnodes(H), numnodes(G), numedges(H)));
