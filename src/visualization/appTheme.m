function t = appTheme()
%APPTHEME The single design system of the app and the report figures.
%
%   T = APPTHEME() returns a struct of fonts, chrome colours, semantic
%   colours, the categorical palette of the six feature groups and two
%   colormap generators. Every colour is a 1x3 RGB triple in [0,1]; every
%   plot function and the app read colours from here, never inline.
%
%   Method (docs/MULTIMEDIA_DESIGN.md, "Visual design system"): colour is
%   assigned by the job it does, and every categorical set was checked
%   with the dataviz palette validator (OKLab x100 Delta E, Machado 2009
%   protan/deutan simulation) instead of being eyeballed.
%
%   Chrome (light theme). WCAG contrast on the surface #fcfcfb:
%     text primary   #0b0b0b  19.2:1     text secondary #52514e  7.7:1
%     text muted     #898781   3.5:1 (axis ticks / large text only)
%     accent         #256abf   5.3:1 (white text on accent: 5.4:1)
%     gridlines #e1e0d9 and borders are one step off the surface, solid.
%
%   Categorical: feature groups (bars, adjacent pairs). Slots 1-7 of the
%     reference palette in fixed order activity, temporal, spatial,
%     cooffending, graph, sequence, network (violet #6250d6, slot 7;
%     re-validated with all 7). Worst adjacent CVD dE 9.1 (target 8),
%     normal-vision dE 19.6 (floor 15). Aqua, yellow and magenta are below
%     3:1 on the surface, so the evidence chart always carries a legend
%     and feature labels (relief rule). Colour follows the group name,
%     never its position in a filtered list.
%
%   Detector classes (scatter, all pairs): flagged by both = red,
%     baseline only = blue, Isolation Forest only = aqua. Worst all-pairs
%     CVD dE 6.9 (floor band) -> legal only with secondary encoding, so
%     each class also has its own marker shape (diamond/square/triangle).
%
%   Timeline: unusually high / low months are the diverging pair
%     red / blue (warm vs cool poles) with up/down triangles; change points
%     are green dashed rules (red-blue-green all-pairs CVD dE 7.2 ->
%     secondary encoding = line form vs triangle markers). The count line
%     is secondary ink so the anomaly hues own the colour channel.
%
%   Selection and cursor are ink, not a data hue: the selected entity
%   keeps its score colour and gets a 2 pt ink ring (network, detector
%   scatter), an ink path (relative space) or ink ticks (timeline). The
%   replay cursor is an ink rule labelled with its month.
%
%   Sequential: anomaly score = one hue (blue) light -> dark, steps 200-700
%     of the reference ramp, lightness monotone, hue spread 4 degrees.
%     Unscored (insufficient history) is the neutral grey #c3c2b7, which
%     is not on the ramp. Density uses a neutral grey ramp so data marks
%     placed on top stay readable.
%
%   Status (data quality) is reserved: good / warning / critical, always
%   shown with an icon and a text label, never colour alone.

t.name = "Analysis light";

% Typography: one sans family everywhere (no display or serif faces).
t.font.family = "Helvetica";
t.font.base = 12;
t.font.small = 10;
t.font.axis = 10;
t.font.title = 12;
t.font.header = 16;
t.font.kpi = 20;

% Chrome.
t.color.page = hex("#f3f2ef");
t.color.surface = hex("#fcfcfb");
t.color.header = hex("#fcfcfb");
t.color.border = hex("#e1e0d9");
t.color.grid = hex("#e1e0d9");
t.color.axis = hex("#c3c2b7");
t.color.text = hex("#0b0b0b");
t.color.textSecondary = hex("#52514e");
t.color.textMuted = hex("#898781");
t.color.accent = hex("#256abf");
t.color.accentText = hex("#ffffff");
t.color.badge = hex("#cde2fb");          % format badge fill, ink text 14.9:1
t.color.selectedRow = hex("#cde2fb");    % ranking row of the selected entity
t.color.stripe = hex("#f6f5f2");         % alternate table rows

% Semantic colours (data jobs).
t.semantic.flaggedBoth = hex("#e34948");
t.semantic.baselineOnly = hex("#2a78d6");
t.semantic.iforestOnly = hex("#1baf7a");
t.semantic.scoredNeutral = hex("#c3c2b7");
t.semantic.unscored = hex("#c3c2b7");
t.semantic.selected = hex("#0b0b0b");
t.semantic.unusualHigh = hex("#e34948");
t.semantic.unusualLow = hex("#2a78d6");
t.semantic.changePoint = hex("#008300");
t.semantic.cursor = hex("#0b0b0b");
t.semantic.series = hex("#52514e");
t.semantic.baseline = hex("#898781");
t.semantic.windowEvents = hex("#2a78d6");
t.semantic.edge = hex("#898781");
t.semantic.threshold = hex("#898781");

% Status palette: fixed, reserved, always paired with icon + label.
t.status.good = hex("#0ca30c");
t.status.warning = hex("#fab219");
t.status.critical = hex("#d03b3b");
t.status.icon = struct('good', "✓", 'warning', "!", 'critical', "✕");

% Categorical palette of the six feature groups (fixed order).
t.groups.names = ["activity", "temporal", "spatial", "cooffending", "graph", ...
    "sequence", "network"];
t.groups.labels = ["Activity", "Temporal", "Spatial", "Co-offending", "Graph", ...
    "Sequence", "Network traffic"];
t.groups.colors = [hex("#2a78d6"); hex("#eb6834"); hex("#1baf7a"); ...
    hex("#eda100"); hex("#e87ba4"); hex("#008300"); hex("#6250d6")];
names = t.groups.names;
colors = t.groups.colors;
other = hex("#898781");
t.groupColor = @(g) lookupGroupColor(g, names, colors, other);

% Mark specs (points): thin lines, >= 8 px markers, hairline grid.
t.mark.line = 1.5;
t.mark.thinLine = 1;
t.mark.hairline = 0.5;
t.mark.marker = 6;
t.mark.scatterArea = 36;
t.mark.ring = 1.5;

% Colormap generators: N-by-3 matrices.
t.scoreColormap = @scoreColormap;
t.densityColormap = @densityColormap;
end

function rgb = hex(h)
h = char(h);
rgb = [hex2dec(h(2:3)), hex2dec(h(4:5)), hex2dec(h(6:7))] / 255;
end

function c = lookupGroupColor(g, names, colors, other)
g = string(g);
c = repmat(other, numel(g), 1);
[has, loc] = ismember(lower(g(:)), names);
c(has, :) = colors(loc(has), :);
end

function cmap = scoreColormap(n)
%SCORECOLORMAP Single-hue blue ramp (steps 200..700), light = low score.
if nargin < 1
    n = 256;
end
anchors = ["#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5", "#2a78d6", ...
    "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b"];
cmap = rampFromAnchors(anchors, n);
end

function cmap = densityColormap(n)
%DENSITYCOLORMAP Neutral grey ramp from the surface to muted ink.
if nargin < 1
    n = 256;
end
cmap = rampFromAnchors(["#fcfcfb", "#e1e0d9", "#c3c2b7", "#898781"], n);
end

function cmap = rampFromAnchors(anchors, n)
A = zeros(numel(anchors), 3);
for k = 1:numel(anchors)
    A(k, :) = hex(anchors(k));
end
if n == 1
    cmap = A(1, :);
    return;
end
x = linspace(0, 1, numel(anchors));
cmap = interp1(x, A, linspace(0, 1, n));
cmap = min(max(cmap, 0), 1);
end
