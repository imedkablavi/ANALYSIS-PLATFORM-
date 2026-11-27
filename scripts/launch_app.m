% LAUNCH_APP
% Open the Network Behaviour Explorer.
%
% Loads the latest saved network-traffic analysis with consistent source
% metadata from the local dataset catalog. Without a valid saved network run,
% opens an empty state. Open dataset remains available for explicit imports.
% This entry point never synthesizes data or opens the historical burglary
% dataset as an implicit fallback.
% Design and interaction: docs/MULTIMEDIA_DESIGN.md.

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
[bundle, bundleFile] = presentationBundle(rootDir);
app = NetworkBehaviorExplorer(struct([]));
if ~isempty(bundle)
    app.loadBundle(bundle, bundleFile);
end
