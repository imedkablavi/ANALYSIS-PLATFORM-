function hs = computeSpatialHotspots(crimes, gridSize, years, alpha)
%COMPUTESPATIALHOTSPOTS Grid density and space-time excess in normalized space.
%
%   HS = COMPUTESPATIALHOTSPOTS(CRIMES, GRIDSIZE, YEARS, ALPHA)
%
%   Coordinates are min-max scaled by the data provider and are used ONLY
%   in that normalized space; nothing here maps cells back to real places.
%
%   hs.cells     GRIDSIZE^2 rows: cell_row, cell_col, x_center, y_center,
%                crimes (all years)
%   hs.spaceTime one row per (cell, year) with crimes > 0:
%                cell_row, cell_col, year, crimes, expected, ratio,
%                p_value, is_hotspot
%     expected_{c,y} = N_c * N_y / N  (independence of place and year)
%     p = P(X >= crimes | Poisson(expected)) = gammainc(expected, crimes)
%     is_hotspot: p < ALPHA / (number of tested cell-years)  (Bonferroni)
%   This is a fixed-grid Poisson excess test: a simple, transparent
%   relative of the space-time scan statistic (Kulldorff 1997), not an
%   implementation of it.
%   hs.grid      GRIDSIZE x GRIDSIZE count matrix (row = y cell, col = x cell)

arguments
    crimes table
    gridSize (1,1) double {mustBeInteger, mustBePositive} = 20
    years (:,1) double = (2014:2020)'
    alpha (1,1) double = 0.001
end

ok = isfinite(crimes.x) & isfinite(crimes.y);
cx = min(floor(crimes.x(ok) * gridSize) + 1, gridSize);
cy = min(floor(crimes.y(ok) * gridSize) + 1, gridSize);
cx = max(cx, 1);
cy = max(cy, 1);
grid = accumarray([cy cx], 1, [gridSize gridSize]);

[cc, rr] = meshgrid(1:gridSize, 1:gridSize);
centers = ((1:gridSize) - 0.5) / gridSize;
hs.cells = table(rr(:), cc(:), centers(cc(:))', centers(rr(:))', grid(:), ...
    'VariableNames', {'cell_row','cell_col','x_center','y_center','crimes'});
hs.grid = grid;

yr = year(crimes.event_time(ok));
inY = ismember(yr, years);
cellIdx = sub2ind([gridSize gridSize], cy(inY), cx(inY));
[~, yIdx] = ismember(yr(inY), years);
nCY = accumarray([cellIdx yIdx], 1, [gridSize^2 numel(years)]);
N = sum(nCY, 'all');
expected = sum(nCY, 2) * sum(nCY, 1) / max(N, 1);

[ci, yi] = find(nCY > 0);
lin = sub2ind(size(nCY), ci, yi);
obs = nCY(lin);
ex = expected(lin);
p = gammainc(ex, obs);          % P(X >= obs), obs >= 1
nTests = numel(lin);
[r, c] = ind2sub([gridSize gridSize], ci);
hs.spaceTime = table(r, c, years(yi), obs, ex, obs ./ ex, p, ...
    p < alpha / max(nTests, 1), 'VariableNames', {'cell_row','cell_col', ...
    'year','crimes','expected','ratio','p_value','is_hotspot'});
hs.spaceTime = sortrows(hs.spaceTime, 'p_value');
hs.alpha = alpha;
hs.n_tests = nTests;
end
