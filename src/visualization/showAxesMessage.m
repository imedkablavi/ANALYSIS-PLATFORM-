function showAxesMessage(ax, msg, theme)
%SHOWAXESMESSAGE Replace a plot by a centred explanatory message.
%
%   SHOWAXESMESSAGE(AX, MSG, THEME) clears AX and writes MSG (string or
%   string array, one line each) in secondary ink. Used for empty states
%   ("Select an entity ..."), datasets without coordinates and views that
%   could not be drawn, so a panel is never left blank or stale.

if nargin < 3 || isempty(theme)
    theme = appTheme();
end
cla(ax, 'reset');   % also hidden-handle objects and manual limits of a previous dataset
legend(ax, 'off');
colorbar(ax, 'off');
title(ax, '');
text(ax, 0.5, 0.5, string(msg), 'Units', 'normalized', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'Color', theme.color.textSecondary, 'FontName', theme.font.family, ...
    'FontSize', theme.font.base, 'Interpreter', 'none');
axis(ax, 'off');
ax.Color = theme.color.surface;
end
