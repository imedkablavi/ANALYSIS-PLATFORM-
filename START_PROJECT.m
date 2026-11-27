% START_PROJECT
% One-command entry point for the Network Behaviour Explorer.
%
% Run from the project root in MATLAB:
%   run('START_PROJECT.m')
%
% This launcher opens the latest valid saved network analysis from the local
% dataset catalog. It does NOT re-import CTU-13, re-run the detector, overwrite
% analysis outputs, clear the workspace, or modify source data. If no valid
% saved network analysis exists, it opens the empty application so a dataset
% can be explicitly selected with "Open dataset...".
%
% Safety: the existing project files and analysis bundle are left untouched.

projectRoot = fileparts(mfilename("fullpath"));
if strlength(string(projectRoot)) == 0
    projectRoot = pwd;
end
addpath(fullfile(projectRoot, "scripts"));
rootDir = setupProject();

[bundle, bundleFile] = presentationBundle(rootDir);
if ~isempty(bundle) && strlength(string(bundleFile)) > 0 && isfile(bundleFile)
    app = NetworkBehaviorExplorer(bundleFile);
    fprintf("Network Behaviour Explorer opened from saved analysis:\n  %s\n", bundleFile);
else
    app = NetworkBehaviorExplorer(struct([]));
    fprintf("No valid saved network analysis was found. Use Open dataset... in the app.\n");
end

if ~isempty(app.Figure) && isvalid(app.Figure)
    app.Figure.Visible = "on";
    drawnow;
end
