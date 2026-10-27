function cp = detectChangePoints(x, minSegment, maxChanges)
%DETECTCHANGEPOINTS Mean-shift change points by penalized binary segmentation.
%
%   CP = DETECTCHANGEPOINTS(X, MINSEGMENT, MAXCHANGES) returns a table of
%   accepted change points (index = first bin of the new segment), ordered
%   by position, with the segment means before/after and the cost gain.
%
%   Cost of a segment = sum of squared deviations from its mean. A split is
%   accepted when its cost reduction exceeds the BIC-type penalty
%       beta = 2 * sigma^2 * log(n),
%   where sigma is estimated robustly from first differences
%   (1.4826 * MAD(diff(x)) / sqrt(2)), so a level shift does not inflate
%   it. Binary segmentation and penalty choice follow the review of
%   Truong, Oudre & Vayatis (2020). Implemented directly (base MATLAB) so
%   the rule is transparent and does not require the Signal Processing
%   Toolbox (findchangepts).

arguments
    x (:,1) double
    minSegment (1,1) double {mustBeInteger, mustBePositive} = 6
    maxChanges (1,1) double {mustBeInteger, mustBeNonnegative} = 5
end

cp = table(zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), 'VariableNames', ...
    {'index','mean_before','mean_after','cost_gain'});
x = x(:);
n = numel(x);
if n < 2 * minSegment || any(isnan(x))
    return;
end
d = diff(x);
sigma = 1.4826 * median(abs(d - median(d))) / sqrt(2);
if sigma == 0
    sigma = std(d) / sqrt(2);
end
if sigma == 0
    return;
end
beta = 2 * sigma^2 * log(n);

segments = [1 n];
found = zeros(0, 2);   % [index gain]
for iter = 1:maxChanges
    bestGain = -Inf; bestSeg = 0; bestIdx = 0;
    for s = 1:size(segments, 1)
        [gain, idx] = bestSplit(x(segments(s,1):segments(s,2)), minSegment);
        if gain > bestGain
            bestGain = gain;
            bestSeg = s;
            bestIdx = segments(s,1) + idx - 1;
        end
    end
    if bestSeg == 0 || bestGain <= beta
        break;
    end
    seg = segments(bestSeg, :);
    segments(bestSeg, :) = [];
    segments = [segments; seg(1) bestIdx-1; bestIdx seg(2)]; %#ok<AGROW>
    found(end+1, :) = [bestIdx bestGain]; %#ok<AGROW>
end
if isempty(found)
    return;
end
found = sortrows(found, 1);
bounds = [1; found(:,1); n+1];
means = arrayfun(@(k) mean(x(bounds(k):bounds(k+1)-1)), (1:numel(bounds)-1)');
cp = table(found(:,1), means(1:end-1), means(2:end), found(:,2), 'VariableNames', ...
    {'index','mean_before','mean_after','cost_gain'});
end

function [gain, idx] = bestSplit(v, minSegment)
% Best single split of v; idx = first element of the right part.
m = numel(v);
gain = -Inf;
idx = 0;
if m < 2 * minSegment
    return;
end
c1 = cumsum(v);
c2 = cumsum(v.^2);
total = c2(m) - c1(m)^2 / m;
k = (minSegment:m-minSegment)';          % size of the left part
left = c2(k) - c1(k).^2 ./ k;
right = (c2(m) - c2(k)) - (c1(m) - c1(k)).^2 ./ (m - k);
[bestCost, j] = min(left + right);
gain = total - bestCost;
idx = k(j) + 1;
end
