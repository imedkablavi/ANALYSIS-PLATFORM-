% LAUNCH_APP
% Open the Network Behaviour Explorer.
%
% Loads the primary analysis bundle (outputs/model/analysis_bundle.mat,
% written by scripts/run_pipeline.m) when it exists. Without any bundle the
% app opens an empty state: use "Open dataset..." in the header to import a
% JSON/CSV dataset, or pick an earlier import from the Dataset dropdown.
% Design and interaction: docs/MULTIMEDIA_DESIGN.md.

addpath(fullfile(fileparts(mfilename("fullpath"))));
setupProject();
app = NetworkBehaviorExplorer();
