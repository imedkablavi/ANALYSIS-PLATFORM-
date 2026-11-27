function displayTable = localizeTableDisplay(sourceTable, language)
%LOCALIZETABLEDISPLAY Translate known enum values in a presentation copy only.
% Schema names, numbers, logical flags, dates, identifiers and diagnostics
% remain intact. Headers are separately rendered with uiText(schemaName).
arguments
    sourceTable table
    language (1,1) string = uiText("--lang")
end
% Validate even an empty table without changing the selected UI language.
uiText("--format", language, "");
displayTable = sourceTable;
columns = ["detector", "setting", "severity", "category", "direction"];
known = { ["baseline", "iforest"], ["known_only", "unknown_as_benign"], ...
    ["error", "warning", "info"], ...
    ["structure", "nodes", "links", "events", "consistency", "graph"], ...
    ["incoming", "outgoing", "self"] };
for j = 1:numel(columns)
    column = columns(j);
    if ~ismember(column, string(sourceTable.Properties.VariableNames))
        continue;
    end
    original = sourceTable.(column);
    if ~(isstring(original) || iscategorical(original) || iscellstr(original))
        continue;
    end
    values = string(original);
    for key = known{j}
        hit = ~ismissing(values) & values == key;
        values(hit) = uiText("--format", language, "table." + column + "." + key);
    end
    displayTable.(column) = values;
end
end
