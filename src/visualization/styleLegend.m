function lgd = styleLegend(ax, theme, varargin)
%STYLELEGEND Legend with the single placement rule of the design system.
%
%   LGD = STYLELEGEND(AX, THEME) creates the legend of AX above the plot
%   area, horizontal, without a box, text in secondary ink (text never
%   wears the series colour). Extra arguments are passed to LEGEND first
%   (e.g. a vector of handles). Every chart with >= 2 series uses this.

if nargin < 2 || isempty(theme)
    theme = appTheme();
end
lgd = legend(ax, varargin{:});
lgd.Location = 'northoutside';
lgd.Orientation = 'horizontal';
lgd.Box = 'off';
lgd.TextColor = theme.color.textSecondary;
lgd.FontName = theme.font.family;
lgd.FontSize = theme.font.small;
lgd.AutoUpdate = 'off';
end
