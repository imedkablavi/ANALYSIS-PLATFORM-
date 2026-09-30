% LAUNCH_APP
% Open the Network Behaviour Explorer on the saved analysis bundle.

addpath(fullfile(fileparts(mfilename("fullpath"))));
setupProject();
app = NetworkBehaviorExplorer();
