function [shown, total] = strongestEvidence(evidence, limit)
%STRONGESTEVIDENCE Finite measured deviations ranked by magnitude for display.
%   The full table is unchanged and remains available to investigation export.
%   Equal magnitudes retain registry order. TOTAL counts measurable deviations.
arguments
    evidence table
    limit (1,1) double {mustBeInteger, mustBePositive} = 12
end
required = ["robust_z", "value", "reference_median"];
if ~all(ismember(required, string(evidence.Properties.VariableNames)))
    error("MOSAIC:EvidenceColumns", "Measured evidence requires value, reference median and z.");
end
% Missing inputs may have imputed z=0 in the model matrix. They are not
% measurements and must not be shown as a measured zero deviation.
measured = isfinite(evidence.robust_z) & isfinite(evidence.value) & ...
    isfinite(evidence.reference_median);
shown = evidence(measured, :);
total = height(shown);
[~, order] = sort(abs(shown.robust_z), 'descend');
shown = shown(order(1:min(total, limit)), :);
end
