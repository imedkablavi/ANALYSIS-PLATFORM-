function [scores, summary] = scoreSUS(responses)
%SCORESUS System Usability Scale (SUS) scores and descriptive summary.
%
%   [SCORES, SUMMARY] = SCORESUS(RESPONSES) scores the 10-item SUS
%   (Brooke 1996). RESPONSES is either
%     - an N-by-10 numeric matrix (column k = item k), or
%     - a table with numeric variables q1..q10 (other variables, e.g.
%       participant_id, are ignored),
%   with integer values 1..5 (1 = strongly disagree, 5 = strongly agree)
%   and NaN for a missing answer.
%
%   Scoring (Brooke 1996):
%     odd items  (1,3,5,7,9):  contribution = response - 1
%     even items (2,4,6,8,10): contribution = 5 - response
%     SUS = 2.5 * sum(contributions)          (range 0..100)
%
%   Missing-data rule: a participant with ANY missing item gets SUS = NaN
%   and is excluded from SUMMARY. No imputation is done, because SUS is
%   only defined for the complete 10-item questionnaire and imputing one
%   item can shift the score by up to 10 points (docs/USABILITY_STUDY.md).
%
%   SCORES   N-by-1 double, SUS per participant (NaN if incomplete).
%   SUMMARY  struct: n (complete responses), n_incomplete, mean, sd
%            (sample SD, N-1), median, min, max. Statistics are NaN when
%            n == 0. Descriptive only; no benchmark is applied here.
%
%   Errors (id MOSAIC:SUSInput): wrong type, not exactly 10 item columns,
%   missing q1..q10 table variables, or values that are not integers in
%   1..5.
%
%   Reference: Brooke, J. (1996). SUS: a "quick and dirty" usability
%   scale. In Jordan, Thomas, Weerdmeester & McClelland (Eds.),
%   Usability Evaluation in Industry, Taylor & Francis, pp. 189-194.

arguments
    responses
end

R = susMatrix(responses);
known = R(~isnan(R));
if any(known < 1 | known > 5 | known ~= round(known))
    error("MOSAIC:SUSInput", ...
        "SUS responses must be integers in 1..5 (NaN for missing).");
end

contrib = zeros(size(R));
contrib(:, 1:2:9) = R(:, 1:2:9) - 1;
contrib(:, 2:2:10) = 5 - R(:, 2:2:10);
scores = 2.5 * sum(contrib, 2);          % NaN propagates: incomplete -> NaN

valid = scores(~isnan(scores));
summary = struct();
summary.n = numel(valid);
summary.n_incomplete = nnz(isnan(scores));
if summary.n == 0
    summary.mean = NaN;
    summary.sd = NaN;
    summary.median = NaN;
    summary.min = NaN;
    summary.max = NaN;
else
    summary.mean = mean(valid);
    summary.sd = std(valid);
    summary.median = median(valid);
    summary.min = min(valid);
    summary.max = max(valid);
end
end

function R = susMatrix(responses)
% Convert the accepted input forms to an N-by-10 double matrix.
if istable(responses)
    names = "q" + (1:10);
    missing = names(~ismember(names, string(responses.Properties.VariableNames)));
    if ~isempty(missing)
        error("MOSAIC:SUSInput", "SUS table is missing variable(s): %s.", ...
            strjoin(missing, ", "));
    end
    R = zeros(height(responses), 10);
    for k = 1:10
        col = responses.(names(k));
        if ~isnumeric(col) && ~islogical(col)
            error("MOSAIC:SUSInput", "SUS variable %s must be numeric.", names(k));
        end
        R(:, k) = double(col);
    end
elseif isnumeric(responses)
    if ~ismatrix(responses) || size(responses, 2) ~= 10
        error("MOSAIC:SUSInput", ...
            "SUS matrix must have exactly 10 columns (got %d).", size(responses, 2));
    end
    R = double(responses);
else
    error("MOSAIC:SUSInput", ...
        "SUS responses must be an N-by-10 numeric matrix or a table with q1..q10.");
end
end
