function files = writeValidationReport(report, outDir)
%WRITEVALIDATIONREPORT Export a validation report as JSON, CSV and Markdown.
%
%   FILES = WRITEVALIDATIONREPORT(REPORT, OUTDIR) writes
%     validation_report.json   machine-readable (checks + summary)
%     validation_checks.csv    check table
%     validation_report.md     human-readable
%   The report contains aggregate counts only; no entity or crime IDs.

arguments
    report (1,1) struct
    outDir (1,1) string
end

if ~isfolder(outDir)
    mkdir(outDir);
end

summary = report.summary;
fn = fieldnames(summary);
for k = 1:numel(fn)
    if isdatetime(summary.(fn{k}))
        summary.(fn{k}) = char(summary.(fn{k}), 'yyyy-MM-dd');
    end
end

payload = struct();
payload.generated = char(datetime('now'), 'yyyy-MM-dd''T''HH:mm:ss');
payload.is_valid = report.is_valid;
payload.summary = summary;
payload.checks = table2struct(report.checks);

files.json = fullfile(outDir, "validation_report.json");
files.csv = fullfile(outDir, "validation_checks.csv");
files.md = fullfile(outDir, "validation_report.md");

writeTextFile(files.json, jsonencode(payload));
writetable(report.checks, files.csv);

lines = strings(0,1);
lines(end+1) = "# Dataset Validation Report";
lines(end+1) = "";
lines(end+1) = "Generated: " + string(payload.generated);
lines(end+1) = "";
if report.is_valid
    verdict = "PASSED (no error-level check failed)";
else
    verdict = "FAILED (" + numel(report.errors) + " error-level checks failed)";
end
lines(end+1) = "**Overall:** " + verdict;
lines(end+1) = "";
lines(end+1) = "## Summary";
lines(end+1) = "";
for k = 1:numel(fn)
    lines(end+1) = "- " + string(fn{k}) + ": " + valueText(summary.(fn{k})); %#ok<AGROW>
end
lines(end+1) = "";
lines(end+1) = "## Checks";
lines(end+1) = "";
lines(end+1) = "| ID | Category | Severity | Status | Affected | Check |";
lines(end+1) = "|---|---|---|---|---|---|";
for k = 1:height(report.checks)
    c = report.checks(k,:);
    if c.passed
        status = "pass";
    elseif c.severity == "info"
        status = "observed";
    else
        status = "FAIL";
    end
    lines(end+1) = sprintf("| %s | %s | %s | %s | %s | %s |", c.check_id, ...
        c.category, c.severity, status, valueText(c.affected), c.message); %#ok<AGROW>
end
lines(end+1) = "";
lines(end+1) = "Severity semantics: error blocks the pipeline; warning is documented and analysis continues; info records a data property.";
writeTextFile(files.md, joinStrings(lines, newline));
end

function t = valueText(v)
if islogical(v)
    t = string(mat2str(v));
elseif isnumeric(v)
    if isempty(v) || all(isnan(v))
        t = "n/a";
    else
        t = string(num2str(v, 6));
    end
else
    t = string(v);
end
end
