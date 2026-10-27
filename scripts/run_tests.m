% RUN_TESTS
% Run the MATLAB unit tests. Tests use small synthetic fixtures and run
% without the real dataset; dataset-dependent tests are skipped (assumeTrue)
% when data/raw is empty.

addpath(fullfile(fileparts(mfilename("fullpath"))));
rootDir = setupProject();
results = runtests(fullfile(rootDir, "tests"));
disp(table(results));
fprintf("Passed %d / %d, failed %d, incomplete (skipped) %d\n", ...
    nnz([results.Passed]), numel(results), nnz([results.Failed]), nnz([results.Incomplete]));
if any([results.Failed])
    error("MOSAIC:TestsFailed", "%d test(s) failed.", nnz([results.Failed]));
end
