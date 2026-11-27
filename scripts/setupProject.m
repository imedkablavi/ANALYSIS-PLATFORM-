function rootDir = setupProject()
%SETUPPROJECT Add project folders to the MATLAB path and return the root.
%   Called by every script and by the test runner so no undocumented manual
%   path setup is needed.

rootDir = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(fullfile(rootDir, "src")));
addpath(fullfile(rootDir, "configs"));
addpath(fullfile(rootDir, "app"));
addpath(fullfile(rootDir, "scripts"));
addpath(fullfile(rootDir, "tests", "fixtures"));
end
