function summary = summarizeUsabilityLog(logTable)
%SUMMARIZEUSABILITYLOG Per-task descriptives of a usability observation log.
%
%   SUMMARY = SUMMARIZEUSABILITYLOG(LOGTABLE) aggregates the observation
%   log of experiment E10 (docs/USABILITY_STUDY.md). LOGTABLE has the
%   columns of docs/usability/observation_log_template.csv:
%     participant_id, task_id, start_s, end_s, success, assists, errors,
%     notes
%   (participant_id, errors and notes are optional for the summary).
%   success is 0, 0.5 or 1; start_s / end_s are seconds from session start.
%
%   SUMMARY is a table with one row per task_id (sorted):
%     task_id, n             attempts logged for the task
%     success_rate           mean(success)                      (0..1)
%     median_time_s          median(end_s - start_s), NaNs omitted
%     mean_assists           mean(assists), NaNs omitted
%     mean_errors            mean(errors), NaNs omitted (NaN if no column)
%
%   Descriptive only: with 5-8 participants no significance tests are run.
%   Errors (id MOSAIC:UsabilityLogInput): missing columns, success outside
%   {0, 0.5, 1}, or end_s < start_s.

arguments
    logTable table
end

vars = string(logTable.Properties.VariableNames);
need = ["task_id", "start_s", "end_s", "success", "assists"];
missing = need(~ismember(need, vars));
if ~isempty(missing)
    error("MOSAIC:UsabilityLogInput", "Usability log is missing column(s): %s.", ...
        strjoin(missing, ", "));
end

task = string(logTable.task_id);
success = double(logTable.success);
duration = double(logTable.end_s) - double(logTable.start_s);
assists = double(logTable.assists);
if ismember("errors", vars)
    errs = double(logTable.errors);
else
    errs = NaN(height(logTable), 1);
end

if any(~ismember(success, [0 0.5 1]))
    error("MOSAIC:UsabilityLogInput", "success must be 0, 0.5 or 1 for every row.");
end
if any(duration < 0)
    error("MOSAIC:UsabilityLogInput", "end_s must not be earlier than start_s.");
end

tasks = unique(task);
k = numel(tasks);
n = zeros(k, 1);
rate = NaN(k, 1);
medTime = NaN(k, 1);
meanAssists = NaN(k, 1);
meanErrors = NaN(k, 1);
for i = 1:k
    m = task == tasks(i);
    n(i) = nnz(m);
    rate(i) = mean(success(m));
    medTime(i) = median(duration(m), 'omitnan');
    meanAssists(i) = mean(assists(m), 'omitnan');
    meanErrors(i) = mean(errs(m), 'omitnan');
end

summary = table(tasks, n, rate, medTime, meanAssists, meanErrors, ...
    'VariableNames', {'task_id', 'n', 'success_rate', 'median_time_s', ...
    'mean_assists', 'mean_errors'});
end
