% GENERATE_REPORT_FIGURES
% Regenerate every report figure from the saved bundle (no manual edits).
% Uses the same plotting functions as the application.
% Set DATASET before running: "latest" (default), a catalog dataset_id,
% or "primary" / "" for the original primary bundle. Imported datasets
% write figures to the directory configured in their saved bundle.

if ~exist('DATASET', 'var')
    DATASET = "latest";
end
DATASET = string(DATASET);

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
if DATASET == "" || DATASET == "primary"
    bundleFile = fullfile(rootDir, cfg.output.bundle_file);
else
    catalog = listDatasets(rootDir);
    if height(catalog) == 0
        error("MOSAIC:NoDatasets", ...
            'No analysed datasets yet. Import one, or set DATASET = "primary".');
    end
    if DATASET == "latest"
        [~, k] = max(catalog.imported);
    else
        k = find(string(catalog.dataset_id) == DATASET, 1);
        if isempty(k)
            error("MOSAIC:UnknownDataset", "Dataset %s is not in the catalog.", DATASET);
        end
    end
    bundleFile = string(catalog.bundle_file(k));
    if ~isfile(bundleFile) && isfile(fullfile(rootDir, bundleFile))
        bundleFile = fullfile(rootDir, bundleFile);
    end
end
if ~isfile(bundleFile)
    error("MOSAIC:BundleMissing", "Analysis bundle missing: %s", bundleFile);
end
S = load(bundleFile, "bundle");
b = S.bundle;
cfg = b.config;
ds = bundleDatasetInfo(b);
outDir = fullfile(rootDir, cfg.output.figure_dir);
if ~isfolder(outDir)
    mkdir(outDir);
end

f = figure('Visible', 'off', 'Position', [100 100 1100 420]);
plotActivityTimeline(gca, b);
exportgraphics(f, fullfile(outDir, "fig_temporal_activity.png"), 'Resolution', 200);

clf(f); f.Position = [100 100 600 560];
plotSpatialView(gca, b);
exportgraphics(f, fullfile(outDir, "fig_spatial_density.png"), 'Resolution', 200);

clf(f); f.Position = [100 100 700 560];
plotScoreComparison(gca, b);
exportgraphics(f, fullfile(outDir, "fig_detector_agreement.png"), 'Resolution', 200);

dg = b.dynamicGraph;
clf(f); f.Position = [100 100 900 420];
yyaxis left
bar(dg.window_start, [dg.edges dg.new_edges]);
ylabel('Interaction ties');
yyaxis right
plot(dg.window_start, dg.edge_persistence, '-o', 'LineWidth', 1.5);
ylabel('Edge persistence vs previous window');
xlabel('Window start');
xtickformat(char(ds.time_format));
legend({'active ties','new ties','persistence'}, 'Location', 'northwest');
ttl = "Dynamic " + lower(ds.network_label) + " over analysis windows";
if any(dg.partial)
    ttl = ttl + " (partial windows: " + ...
        joinStrings(string(dg.window_start(dg.partial), ds.time_format), ", ") + ")";
end
title(ttl);
exportgraphics(f, fullfile(outDir, "fig_dynamic_graph.png"), 'Resolution', 200);

deg = b.entities.degree;
clf(f); f.Position = [100 100 600 450];
[c, ~, ic] = unique(deg);
cnt = accumarray(ic, 1);
loglog(c(c > 0), cnt(c > 0), 'o');
xlabel('Degree (interaction partners)'); ylabel(char(ds.entity_plural));
title(sprintf('Degree distribution (%d isolated %s not shown)', ...
    nnz(deg == 0), ds.entity_plural));
exportgraphics(f, fullfile(outDir, "fig_degree_distribution.png"), 'Resolution', 200);

S2 = b.explanations.summary;
if height(S2) > 0
    top = S2.entity_index(1);
    clf(f); f.Position = [100 100 800 620];
    plotEvidenceBars(gca, b, top);
    title(sprintf('Deviation profile of an explained %s', ds.entity_noun));
    exportgraphics(f, fullfile(outDir, "fig_top_entity_evidence.png"), 'Resolution', 200);
    clf(f); f.Position = [100 100 800 700];
    plotEgoNetwork(gca, b, top, 2, cfgGet(cfg, "app.max_graph_nodes", 400));
    exportgraphics(f, fullfile(outDir, "fig_top_entity_network.png"), 'Resolution', 200);
end
close(f);
fprintf("Figures written to %s\n", outDir);
