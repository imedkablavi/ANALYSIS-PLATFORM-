function tests = test_primary_loader
%TEST_PRIMARY_LOADER Basic MATLAB function-based tests.

tests = functiontests(localfunctions);
end

function testMissingFile(testCase)
verifyError(testCase, ...
    @() loadBurglaryNetwork("does-not-exist.json"), ...
    "MOSAIC:DataFileNotFound");
end

function testRequiredSchemaFields(testCase)
assumeTrue(testCase, isfile(fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json")));

data = loadBurglaryNetwork(fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json"));

verifyTrue(testCase, isfield(data.raw,"nodes"));
verifyTrue(testCase, isfield(data.raw,"links"));
verifyGreaterThan(testCase, height(data.nodes), 0);
verifyGreaterThan(testCase, height(data.links), 0);
end
