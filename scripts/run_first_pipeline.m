% RUN_FIRST_PIPELINE
% End-to-end first analytical slice using the verified primary artifact.

clear; clc;

rootDir = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(rootDir,"src")));

cfg = projectConfig();
dataFile = fullfile(rootDir, cfg.data.primary_file);

fprintf("\n=== MOSAIC / FIRST PIPELINE ===\n");
fprintf("Input: %s\n\n", dataFile);

data = loadBurglaryNetwork(dataFile);
events = flattenBurglaryEvents(data);
validation = validateBurglaryNetwork(data, events);

disp("Validation report:");
disp(validation);

if ~validation.is_valid
    error("MOSAIC:ValidationFailed", ...
        "Dataset validation failed; inspect report before continuing.");
end

G = buildOffenderGraph(data);
graphFeatures = computeGraphFeatures(G);
behaviorFeatures = buildBehaviorFeatures(events, data);
features = mergeFeatureTables(behaviorFeatures, graphFeatures);

fprintf("\n=== Summary ===\n");
fprintf("Nodes: %d\n", numnodes(G));
fprintf("Links: %d\n", numedges(G));
fprintf("Events: %d\n", height(events));
fprintf("Unique crimes: %d\n", numel(unique(events.crime_id)));

fprintf("\nTop 10 entities by total graph degree:\n");
[~, idx] = maxk(features.total_degree, min(10,height(features)));
disp(features(idx, {'entity_id','total_degree','weighted_out_degree','weighted_in_degree'}));

outDir = fullfile(rootDir,"outputs","experiments");
if ~isfolder(outDir), mkdir(outDir); end

save(fullfile(outDir,"first_pipeline_snapshot.mat"), ...
    "validation","data","events","G","features","-v7.3");

writetable(features, fullfile(outDir,"behavior_graph_features.csv"));

fprintf("\nSaved outputs to %s\n", outDir);
