% GENERATE_REPORT_FIGURES
% Regenerate every report figure from the saved bundle (no manual edits).
% Uses the same plotting functions as the application.

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
cfg = projectConfig();
S = load(fullfile(rootDir, cfg.output.bundle_file), "bundle");
b = S.bundle;
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
bar(year(dg.window_start), [dg.edges dg.new_edges]);
ylabel('Co-offending ties');
yyaxis right
plot(year(dg.window_start), dg.edge_persistence, '-o', 'LineWidth', 1.5);
ylabel('Edge persistence vs previous year');
legend({'active ties','new ties','persistence'}, 'Location', 'northwest');
title('Dynamic co-offending network by year');
exportgraphics(f, fullfile(outDir, "fig_dynamic_graph.png"), 'Resolution', 200);

deg = b.entities.degree;
clf(f); f.Position = [100 100 600 450];
[c, ~, ic] = unique(deg);
cnt = accumarray(ic, 1);
loglog(c(c > 0), cnt(c > 0), 'o');
xlabel('Degree (co-offenders)'); ylabel('Offenders');
title(sprintf('Degree distribution (%d isolated offenders not shown)', nnz(deg == 0)));
exportgraphics(f, fullfile(outDir, "fig_degree_distribution.png"), 'Resolution', 200);

S2 = b.explanations.summary;
if height(S2) > 0
    top = S2.entity_index(1);
    clf(f); f.Position = [100 100 800 620];
    plotEvidenceBars(gca, b, top);
    title(sprintf('Deviation profile of the top-ranked entity (rank %g)', S2.iforest_rank(1)));
    exportgraphics(f, fullfile(outDir, "fig_top_entity_evidence.png"), 'Resolution', 200);
    clf(f); f.Position = [100 100 800 700];
    plotEgoNetwork(gca, b, top, 2, cfg.app.max_graph_nodes);
    exportgraphics(f, fullfile(outDir, "fig_top_entity_network.png"), 'Resolution', 200);
end
close(f);
fprintf("Figures written to %s\n", outDir);
