function runLog(varargin)
%RUNLOG Timestamped progress log on screen and in a file.
%
%   RUNLOG("open", FILE) starts logging to FILE (appended; folder created).
%   RUNLOG("close") stops writing to the file.
%   RUNLOG(FMT, ARGS...) prints one line
%       [2026-10-27 18:01:02 | +12.4 s] message
%   to the Command Window and appends it to the open file immediately (the
%   file is closed after every line), so the file shows the last completed
%   step even when a session is cut off (MATLAB Online time-outs).
%   "+x s" is the time since the previous line.

persistent file last
if nargin == 0
    return;
end
first = string(varargin{1});
if first == "open"
    file = string(varargin{2});
    folder = fileparts(file);
    if strlength(folder) > 0 && ~isfolder(folder)
        mkdir(folder);
    end
    last = tic;
    msg = "log started: " + file;
elseif first == "close"
    file = "";
    return;
else
    msg = string(sprintf(varargin{:}));
end
if isempty(last)
    last = tic;
end
line = sprintf("[%s | +%.1f s] %s", string(datetime('now'), 'yyyy-MM-dd HH:mm:ss'), toc(last), msg);
last = tic;
fprintf("%s\n", line);
if ~isempty(file) && strlength(file) > 0
    fid = fopen(file, 'a');
    if fid >= 0
        fprintf(fid, "%s\n", line);
        fclose(fid);
    end
end
drawnow limitrate;   % keeps MATLAB Online's Command Window updating
end
