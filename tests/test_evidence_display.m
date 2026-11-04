function tests = test_evidence_display
tests = functiontests(localfunctions);
end
function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'scripts'));setupProject();
end
function testStrongestMeasuredRowsKeepSignAndOriginal(tc)
e = table(["a";"b";"c";"d";"e"], [1;-5;5;NaN;2], ...
    'VariableNames',{'feature','robust_z'});
e.value = [1;2;3;4;5];
e.reference_median = zeros(5,1);
original = e;
[s,total] = strongestEvidence(e,2);
verifyEqual(tc,total,4);
verifyEqual(tc,s.feature,["b";"c"]);
verifyEqual(tc,s.robust_z,[-5;5]);
verifyEqual(tc,e,original);
end
function testNoMeasuredDeviations(tc)
e = table([NaN;Inf], 'VariableNames',{'robust_z'});
e.value = ones(height(e),1);
e.reference_median = zeros(height(e),1);
[s,total] = strongestEvidence(e,12);
verifyEqual(tc,total,0);
verifyEqual(tc,height(s),0);
end
function testCountBelowDisplayLimit(tc)
e = table([0;-2], 'VariableNames',{'robust_z'});
e.value = ones(height(e),1);
e.reference_median = zeros(height(e),1);
[s,total] = strongestEvidence(e,12);
verifyEqual(tc,total,2);
verifyEqual(tc,s.robust_z,[-2;0]);
end

function testImputedZeroDoesNotRepresentMeasurement(tc)
e = table(["missing";"observed"], [0;0], [NaN;5], [2;5], ...
    'VariableNames', {'feature','robust_z','value','reference_median'});
[s,total] = strongestEvidence(e,12);
verifyEqual(tc,total,1);
verifyEqual(tc,s.feature,"observed");
verifyEqual(tc,s.robust_z,0);
end
