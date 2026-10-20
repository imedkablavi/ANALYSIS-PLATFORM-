function tests = test_visualization_theme
%TEST_VISUALIZATION_THEME Design system and the app's pure helper functions.
%   appTheme (fields, ranges, contrast, palette order, colormaps),
%   contrastRatio, formatCount, filterRanking, kpiSummary and
%   bundleDatasetInfo. No GUI is created. Expected values are computed by
%   hand in the comments next to each assertion.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
end

%% appTheme
function testThemeHasEveryField(tc)
t = appTheme();
for f = ["font", "color", "semantic", "status", "groups", "mark", ...
        "groupColor", "scoreColormap", "densityColormap"]
    verifyTrue(tc, isfield(t, f), "missing theme field " + f);
end
for f = ["family", "base", "small", "axis", "title", "header", "kpi"]
    verifyTrue(tc, isfield(t.font, f), "missing font field " + f);
end
for f = ["page", "surface", "border", "grid", "text", "textSecondary", "textMuted", ...
        "accent", "accentText"]
    verifyTrue(tc, isfield(t.color, f), "missing color field " + f);
end
for f = ["flaggedBoth", "baselineOnly", "iforestOnly", "unscored", "selected", ...
        "unusualHigh", "unusualLow", "changePoint", "cursor"]
    verifyTrue(tc, isfield(t.semantic, f), "missing semantic field " + f);
end
verifyGreaterThanOrEqual(tc, t.font.base, 10);
verifyGreaterThan(tc, t.font.kpi, t.font.base);
end

function testThemeColorsAreRgbTriples(tc)
t = appTheme();
for group = ["color", "semantic"]
    S = t.(group);
    names = fieldnames(S);
    for k = 1:numel(names)
        c = S.(names{k});
        verifySize(tc, c, [1 3], group + "." + names{k});
        verifyGreaterThanOrEqual(tc, c, 0);
        verifyLessThanOrEqual(tc, c, 1);
    end
end
for s = ["good", "warning", "critical"]
    verifySize(tc, t.status.(s), [1 3]);
end
% #0b0b0b = [11 11 11]/255; #2a78d6 = [42 120 214]/255.
verifyEqual(tc, t.color.text, [11 11 11] / 255, 'AbsTol', 1e-12);
verifyEqual(tc, t.semantic.baselineOnly, [42 120 214] / 255, 'AbsTol', 1e-12);
end

function testTextContrast(tc)
t = appTheme();
% WCAG body text needs >= 4.5:1 (published values: 19.2, 7.7 and 5.4).
verifyGreaterThanOrEqual(tc, contrastRatio(t.color.text, t.color.surface), 4.5);
verifyGreaterThanOrEqual(tc, contrastRatio(t.color.textSecondary, t.color.surface), 4.5);
verifyGreaterThanOrEqual(tc, contrastRatio(t.color.accentText, t.color.accent), 4.5);
% Black on white is the maximum 21:1; identical colours give 1:1.
verifyEqual(tc, contrastRatio([0 0 0], [1 1 1]), 21, 'AbsTol', 1e-12);
verifyEqual(tc, contrastRatio(t.color.accent, t.color.accent), 1, 'AbsTol', 1e-12);
end

function testFeatureGroupPalette(tc)
t = appTheme();
verifyEqual(tc, t.groups.names, ...
    ["activity", "temporal", "spatial", "cooffending", "graph", "sequence"]);
verifySize(tc, t.groups.colors, [6 3]);
verifyEqual(tc, size(unique(t.groups.colors, 'rows'), 1), 6);   % six distinct hues
% Colour follows the group name, not its position in the query.
c = t.groupColor(["graph"; "activity"; "unknown"; "Temporal"]);
verifyEqual(tc, c(1, :), t.groups.colors(5, :));
verifyEqual(tc, c(2, :), t.groups.colors(1, :));
verifyEqual(tc, c(3, :), [137 135 129] / 255, 'AbsTol', 1e-12);   % #898781 fallback
verifyEqual(tc, c(4, :), t.groups.colors(2, :));                 % case-insensitive
end

function testScoreColormapIsOneHueLightToDark(tc)
t = appTheme();
cm = t.scoreColormap(11);   % 11 rows = exactly the 11 anchor steps
verifySize(tc, cm, [11 3]);
verifyEqual(tc, cm(1, :), [158 197 244] / 255, 'AbsTol', 1e-12);    % #9ec5f4
verifyEqual(tc, cm(6, :), [42 120 214] / 255, 'AbsTol', 1e-12);     % #2a78d6
verifyEqual(tc, cm(11, :), [13 54 107] / 255, 'AbsTol', 1e-12);     % #0d366b
big = t.scoreColormap(256);
verifySize(tc, big, [256 3]);
lum = big * [0.2126; 0.7152; 0.0722];
verifyTrue(tc, all(diff(lum) < 0), 'score colormap must darken monotonically');
verifyTrue(tc, all(big(:, 3) >= big(:, 1)), 'blue channel dominates (single hue)');
verifyFalse(tc, ismember(t.semantic.unscored, big, 'rows'), 'unscored grey is off the ramp');
d = t.densityColormap(4);
verifyEqual(tc, d(1, :), t.color.surface, 'AbsTol', 1e-12);
end

%% formatCount
function testFormatCount(tc)
verifyEqual(tc, formatCount(0), "0");
verifyEqual(tc, formatCount(999), "999");
verifyEqual(tc, formatCount(1284), "1,284");
verifyEqual(tc, formatCount(9999), "9,999");
verifyEqual(tc, formatCount(12345), "12.3K");        % 12.345 -> 12.3
verifyEqual(tc, formatCount(999999), "1.0M");        % 1000.0K would be misleading
verifyEqual(tc, formatCount(1500000), "1.5M");
verifyEqual(tc, formatCount(-1284), "-1,284");
verifyEqual(tc, formatCount(NaN), "—");
end

%% filterRanking
function [E, S] = rankingFixture()
% Five entities; entity 4 is not eligible (insufficient history).
E = table(["E01"; "E02"; "E03"; "E10"; "X05"], logical([1; 1; 1; 0; 1]), ...
    [2; 1; 4; NaN; 3], [0.6; 0.7; 0.4; NaN; 0.5], ...
    [1; 3; 2; NaN; 4], [5; 3; 4; NaN; 2], ...
    logical([0; 1; 0; 0; 0]), logical([1; 0; 0; 0; 0]), [5; 4; 3; 1; 6], ...
    'VariableNames', {'entity_id', 'eligible', 'iforest_rank', 'iforest_score', ...
    'baseline_rank', 'baseline_score', 'iforest_flag', 'baseline_flag', 'event_count'});
S = table([1; 2], ["temporal"; "graph"], 'VariableNames', {'entity_index', 'dominant_group'});
end

function testFilterFlagged(tc)
[E, S] = rankingFixture();
% Flagged = entities 1 (baseline) and 2 (IF). Keys min(2,1)=1 and
% min(1,3)=1 tie -> stable order 1, 2.
[rows, shown] = filterRanking(E, S, "Flagged (either detector)", "");
verifyEqual(tc, rows, [1; 2]);
verifyEqual(tc, shown.entity, ["E01"; "E02"]);
verifyEqual(tc, shown.main_group, ["temporal"; "graph"]);
verifyEqual(tc, string(shown.Properties.VariableNames), ...
    ["entity", "IF_rank", "IF_score", "base_rank", "base_score", "events", "main_group"]);
end

function testFilterTopRanks(tc)
[E, S] = rankingFixture();
% IF ranks of eligible entities 1,2,3,5 are 2,1,4,3 -> order 2,1,5,3.
verifyEqual(tc, filterRanking(E, S, "Top 200 by Isolation Forest", ""), [2; 1; 5; 3]);
% Baseline ranks 1,3,2,4 -> order 1,3,2,5.
verifyEqual(tc, filterRanking(E, S, "Top 200 by baseline", ""), [1; 3; 2; 5]);
% All eligible is keyed by the IF rank -> same as the IF order; entity 4
% (not eligible) never appears.
[rows, shown] = filterRanking(E, S, "All eligible", "");
verifyEqual(tc, rows, [2; 1; 5; 3]);
verifyEqual(tc, shown.main_group, ["graph"; "temporal"; ""; ""]);
verifyEqual(tc, shown.events, [4; 5; 6; 3]);
end

function testFilterSearch(tc)
[E, S] = rankingFixture();
% "e0" matches E01, E02, E03 (case-insensitive), not X05; IF order 2,1,3.
verifyEqual(tc, filterRanking(E, S, "All eligible", "e0"), [2; 1; 3]);
verifyEqual(tc, filterRanking(E, S, "All eligible", "  x "), 5);   % trimmed
[rows, shown] = filterRanking(E, S, "All eligible", "zzz");
verifySize(tc, rows, [0 1]);
verifyEqual(tc, height(shown), 0);
% No search text at all behaves like "".
verifyEqual(tc, filterRanking(E, S, "Top 200 by baseline"), [1; 3; 2; 5]);
end

function testFilterFallsBackToBaselineWithoutIForest(tc)
[E, S] = rankingFixture();
E.iforest_rank(:) = NaN;
% Without IF ranks, All eligible uses the baseline ranks 1,3,2,4.
verifyEqual(tc, filterRanking(E, S, "All eligible", ""), [1; 3; 2; 5]);
end

%% kpiSummary
function b = kpiFixture()
b.entities = table(logical([1; 1; 0]), logical([1; 0; 0]), logical([1; 1; 0]), ...
    'VariableNames', {'eligible', 'iforest_flag', 'baseline_flag'});
b.crimes = table(zeros(1284, 1), 'VariableNames', {'crime_index'});
b.temporal.crime_anomalies = table(logical([1; 0; 0; 1]), logical([0; 1; 0; 1]), ...
    'VariableNames', {'is_high', 'is_low'});
b.validation.is_valid = true;
b.validation.warnings = ["w1"; "w2"];
b.anomaly.settings.min_events = 3;
end

function testKpiValues(tc)
k = kpiSummary(kpiFixture());
verifyEqual(tc, k.entities, 3);
verifyEqual(tc, k.events, 1284);
verifyEqual(tc, k.scored, 2);            % eligible 1,2
verifyEqual(tc, k.flagged, 2);           % (1|1), (0|1), (0|0)
verifyEqual(tc, k.unusual_months, 3);    % months 1, 2 and 4
verifyEqual(tc, k.warnings, 2);
verifyEqual(tc, k.quality_status, "warning");
verifyEqual(tc, [k.tiles.key], ["entities", "events", "scored", "flagged", ...
    "unusual_months", "quality"]);
verifyEqual(tc, [k.tiles.value_text], ["3", "1,284", "2", "2", "3", "2 warnings"]);
verifyEqual(tc, k.tiles(3).detail, "≥ 3 events");
verifyEqual(tc, k.tiles(5).detail, "of 4 months");
verifyEqual(tc, k.tiles(6).status, "warning");
end

function testKpiQualityStatus(tc)
b = kpiFixture();
b.validation.warnings = strings(0, 1);
k = kpiSummary(b);
verifyEqual(tc, k.quality_status, "good");
verifyEqual(tc, k.tiles(6).value_text, "Valid");
b.validation.warnings = "only one";
k = kpiSummary(b);
verifyEqual(tc, k.tiles(6).value_text, "1 warning");
b.validation.is_valid = false;
k = kpiSummary(b);
verifyEqual(tc, k.quality_status, "critical");
verifyEqual(tc, k.tiles(6).value_text, "Invalid");
end

function testKpiToleratesPartialBundle(tc)
b.entities = table(logical([1; 0]), 'VariableNames', {'eligible'});
k = kpiSummary(b);
verifyEqual(tc, k.entities, 2);
verifyEqual(tc, k.scored, 1);
verifyTrue(tc, isnan(k.flagged));
verifyTrue(tc, isnan(k.events));
verifyEqual(tc, k.tiles(2).value_text, "—");
verifyEqual(tc, k.tiles(6).value_text, "Not validated");
end

%% bundleDatasetInfo
function testDatasetInfoDefaultsForOldBundles(tc)
info = bundleDatasetInfo(struct('meta', struct('created', 1)));
verifyTrue(tc, info.has_coordinates);
verifyEqual(tc, info.format, "networkx_burglary_json");
verifyEqual(tc, info.event_plural, "crimes");
end

function testDatasetInfoWithoutCoordinates(tc)
d = struct('id', "ds1", 'name', "Edges", 'format', "edge_csv", ...
    'has_coordinates', false, 'pseudonymized', true);
info = bundleDatasetInfo(struct('meta', struct('dataset', d)));
verifyFalse(tc, info.has_coordinates);
verifyEqual(tc, info.name, "Edges");
verifyEqual(tc, info.event_plural, "events");
verifyEqual(tc, info.entity_plural, "entities");
verifyEqual(tc, info.bin, "month");                   % no config -> month
end

function testDatasetInfoWeeklyBins(tc)
b = struct('config', struct('temporal', struct('bin', "week")));
info = bundleDatasetInfo(b);
verifyEqual(tc, info.bin, "week");
verifyEqual(tc, datetime(2020,1,1) + info.bin_step, datetime(2020,1,8));
end

%% Themed plot functions (headless smoke test on the synthetic fixture)
function testPlotFunctionsDrawThemed(tc)
dir = string(tempname);
mkdir(dir);
tc.addTeardown(@() rmdir(dir, 's'));
cfg = projectConfig();
cfg.anomaly.min_events = 3;
f = makeSyntheticNetworkJson(dir);
b = runAnalysisPipeline(cfg, dir, struct('data_file', f, 'save', false, 'use_iforest', false));
fig = figure('Visible', 'off');
tc.addTeardown(@() close(fig));
ax = axes(fig);
th = appTheme();

plotActivityTimeline(ax, b, 1, datetime(2015, 2, 1));
verifyEqual(tc, ax.Color, th.color.surface, 'AbsTol', 1e-12);
verifyEqual(tc, ax.GridColor, th.color.grid, 'AbsTol', 1e-12);
verifyNotEmpty(tc, ax.Legend);
verifyEqual(tc, char(ax.Legend.Location), 'northoutside');

info = plotEgoNetwork(ax, b, 1, 2, 50);
verifyTrue(tc, issorted(info.nodes));            % node k <-> entity info.nodes(k)
verifyTrue(tc, ismember(1, info.nodes));
verifyEqual(tc, size(info.plot.NodeColor), [numel(info.nodes) 3]);

plotSpatialView(ax, b, 1, datetime(2015, 1, 1), datetime(2015, 2, 1));
plotEvidenceBars(ax, b, 1);
plotEvidenceBars(ax, b, 7);            % not eligible -> message, no error
plotScoreComparison(ax, b);
% IF was not run in this fixture: the detector view explains why.
verifyNotEmpty(tc, findobj(ax, 'Type', 'text'));

% A dataset without coordinates shows a message instead of a plot.
b.meta.dataset = struct('id', "nocoord", 'name', "No coordinates", ...
    'format', "edge_csv", 'has_coordinates', false);
plotSpatialView(ax, b, 1);
txt = findobj(ax, 'Type', 'text');
verifyNumElements(tc, txt, 1);
verifyTrue(tc, any(contains(string(txt.String), "No coordinates")));
end
