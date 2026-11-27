function r = contrastRatio(rgbA, rgbB)
%CONTRASTRATIO WCAG 2.x contrast ratio of two sRGB colours in [0,1].
%
%   R = CONTRASTRATIO(RGBA, RGBB) returns (L1 + 0.05) / (L2 + 0.05) with
%   L the relative luminance of the lighter (L1) and darker (L2) colour.
%   Range 1 (identical) to 21 (black on white). Used to verify the theme
%   (tests/test_visualization_theme.m): body text needs >= 4.5.

la = relativeLuminance(rgbA);
lb = relativeLuminance(rgbB);
r = (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
end

function L = relativeLuminance(rgb)
c = double(rgb(:)');
lin = c / 12.92;
hi = c > 0.04045;
lin(hi) = ((c(hi) + 0.055) / 1.055) .^ 2.4;
L = 0.2126 * lin(1) + 0.7152 * lin(2) + 0.0722 * lin(3);
end
