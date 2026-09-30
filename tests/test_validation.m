function tests = test_validation
%TEST_VALIDATION Every validation failure mode is detected with the right severity.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'));
setupProject();
tc.TestData.dir = string(tempname);
mkdir(tc.TestData.dir);
end

function teardownOnce(tc)
rmdir(tc.TestData.dir, 's');
end

function r = validateFixture(tc, mutation)
data = loadBurglaryNetwork(makeSyntheticNetworkJson(tc.TestData.dir, mutation));
events = flattenBurglaryEvents(data);
r = validateBurglaryNetwork(data, events);
end

function verifyCheck(tc, r, id, passed)
row = r.checks(r.checks.check_id == id, :);
verifyEqual(tc, height(row), 1, "missing check " + id);
verifyEqual(tc, row.passed, passed, "check " + id);
end

function testCleanFixtureIsValid(tc)
r = validateFixture(tc, "none");
verifyTrue(tc, r.is_valid);
verifyEmpty(tc, r.warnings);
verifyTrue(tc, r.summary.symmetric_links);
verifyTrue(tc, r.summary.weight_equals_shared_crimes);
verifyTrue(tc, r.summary.day_resolution_only);
verifyEqual(tc, r.summary.undirected_relation_count, 5);
verifyEqual(tc, r.summary.isolated_node_count, 2);
verifyEqual(tc, r.summary.unique_crime_count, 10);
end

function testNegativeWeightIsError(tc)
r = validateFixture(tc, "negative_weight");
verifyFalse(tc, r.is_valid);
verifyCheck(tc, r, "V25", false);
end

function testDanglingLinkIsError(tc)
r = validateFixture(tc, "dangling_link");
verifyFalse(tc, r.is_valid);
verifyCheck(tc, r, "V21", false);
end

function testCoordinateOutOfRangeIsError(tc)
r = validateFixture(tc, "bad_coordinate");
verifyFalse(tc, r.is_valid);
verifyCheck(tc, r, "V48", false);
end

function testInconsistentCrimeAttributes(tc)
r = validateFixture(tc, "inconsistent_date");
verifyTrue(tc, r.is_valid);                 % warning, not error
verifyCheck(tc, r, "V50", false);
end

function testMissingAndMalformedDates(tc)
verifyCheck(tc, validateFixture(tc, "missing_date"), "V43", false);
verifyCheck(tc, validateFixture(tc, "bad_date"), "V43", false);
end

function testAsymmetricReciprocalWeights(tc)
r = validateFixture(tc, "asymmetric_weight");
verifyCheck(tc, r, "V31", false);
end

function testWeightNotEqualSharedCrimes(tc)
r = validateFixture(tc, "weight_mismatch");
verifyCheck(tc, r, "V54", false);
verifyFalse(tc, r.summary.weight_equals_shared_crimes);
end

function testDuplicateAndEmptyIds(tc)
verifyCheck(tc, validateFixture(tc, "duplicate_node"), "V11", false);
verifyCheck(tc, validateFixture(tc, "empty_id"), "V10", false);
end

function testReportExport(tc)
r = validateFixture(tc, "none");
files = writeValidationReport(r, fullfile(tc.TestData.dir, "report"));
verifyTrue(tc, isfile(files.json) && isfile(files.md) && isfile(files.csv));
decoded = jsondecode(fileread(files.json));
verifyTrue(tc, decoded.is_valid);
txt = fileread(files.md);
verifyFalse(tc, contains(txt, "OID#"));   % no identifiers in reports
end
