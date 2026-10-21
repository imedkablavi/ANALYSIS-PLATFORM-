function styleAxes(ax, theme)
%STYLEAXES Apply the design system to an axes or uiaxes.
%
%   STYLEAXES(AX) / STYLEAXES(AX, THEME): surface background, secondary-ink
%   tick labels, solid hairline gridlines one step off the surface, no
%   box, sans font, non-bold primary-ink title. Works for axes created by
%   scripts (gca) and for uiaxes in the app.

if nargin < 2 || isempty(theme)
    theme = appTheme();
end
ax.Color = theme.color.surface;
ax.FontName = theme.font.family;
ax.FontSize = theme.font.axis;
ax.XColor = theme.color.textSecondary;
ax.YColor = theme.color.textSecondary;
ax.GridColor = theme.color.grid;
ax.GridAlpha = 1;
ax.GridLineStyle = '-';
ax.MinorGridColor = theme.color.grid;
ax.LineWidth = theme.mark.hairline;
ax.Box = 'off';
ax.TickDir = 'out';
ax.TitleFontWeight = 'normal';
ax.TitleFontSizeMultiplier = theme.font.title / theme.font.axis;
ax.Title.Color = theme.color.text;
end
