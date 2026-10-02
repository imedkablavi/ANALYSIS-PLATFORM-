function report = validateBurglaryNetwork(data, events, cfg)
%VALIDATEBURGLARYNETWORK Data-quality validation of the network and event table.
%
%   REPORT = VALIDATEBURGLARYNETWORK(DATA, EVENTS) runs every check and
%   returns a machine-readable report. Nothing is repaired: the report
%   documents problems and downstream code decides explicitly what to do.
%
%   REPORT = VALIDATEBURGLARYNETWORK(DATA, EVENTS, CFG) uses plausibility
%   bounds from projectConfig (defaults are used when CFG is omitted).
%
%   report.checks     table: check_id, category, severity, passed,
%                     affected, message
%                     severity: "error" (blocks the pipeline),
%                               "warning" (analysis continues, documented),
%                               "info" (property of the data, no judgement)
%   report.errors     messages of failed error checks
%   report.warnings   messages of failed warning checks
%   report.is_valid   true when no error check failed
%   report.summary    counts, ranges and derived facts
%
%   Use writeValidationReport to export JSON + Markdown.

arguments
    data (1,1) struct
    events table
    cfg struct = struct()
end

minDate = cfgGet(cfg, "data.min_plausible_date", datetime(2000,1,1));
maxDate = cfgGet(cfg, "data.max_plausible_date", datetime(2021,12,31));
seriesStart = cfgGet(cfg, "temporal.series_start", datetime(2014,1,1));

C = {};   % rows: {id, category, severity, passed, affected, message}
nodes = data.nodes;
links = data.links;
nodeIds = nodes.entity_id;
nN = height(nodes);
nL = height(links);
nE = height(events);

% --- Structure --------------------------------------------------------------
C = add(C, "V01", "structure", "error", nN > 0, nN == 0, "At least one node is loaded.");
C = add(C, "V02", "structure", "error", nL > 0, nL == 0, "At least one link is loaded.");
C = add(C, "V03", "structure", "error", nE > 0, nE == 0, "At least one offender-crime event is loaded.");

% --- Nodes --------------------------------------------------------------------
emptyId = nodeIds == "" | ismissing(nodeIds);
C = add(C, "V10", "nodes", "error", ~any(emptyId), sum(emptyId), ...
    "Every node has a non-empty entity ID.");
[~, firstIdx] = unique(nodeIds, 'stable');
dupNodes = nN - numel(firstIdx);
C = add(C, "V11", "nodes", "error", dupNodes == 0, dupNodes, "Entity IDs are unique.");
badType = nodes.entity_type ~= "offender";
C = add(C, "V12", "nodes", "warning", ~any(badType), sum(badType), ...
    "All nodes have type 'offender' (the only type in the verified artifact).");
cidMismatch = nodes.crime_count ~= nodes.detail_count;
C = add(C, "V13", "nodes", "warning", ~any(cidMismatch), sum(cidMismatch), ...
    "list_cid length equals the number of crime_details entries per node.");
noEvents = nodes.detail_count == 0;
C = add(C, "V14", "nodes", "info", ~any(noEvents), sum(noEvents), ...
    "Nodes without any crime_details entry.");

% --- Links --------------------------------------------------------------------
missingEnd = links.source_id == "" | links.target_id == "";
C = add(C, "V20", "links", "error", ~any(missingEnd), sum(missingEnd), ...
    "Every link has a source and a target.");
[srcOk, si] = ismember(links.source_id, nodeIds);
[tgtOk, ti] = ismember(links.target_id, nodeIds);
dangling = ~(srcOk & tgtOk) & ~missingEnd;
C = add(C, "V21", "links", "error", ~any(dangling), sum(dangling), ...
    "Every link endpoint references an existing node.");
selfLoop = links.source_id == links.target_id & ~missingEnd;
C = add(C, "V22", "links", "warning", ~any(selfLoop), sum(selfLoop), "No self-loops.");
if nL > 0
    gDir = findgroups(links.source_id, links.target_id);
    dupDirected = nL - numel(unique(gDir));
else
    dupDirected = 0;
end
C = add(C, "V23", "links", "warning", dupDirected == 0, dupDirected, ...
    "No duplicate directed links (multigraph=false).");
wMissing = isnan(links.weight);
C = add(C, "V24", "links", "error", ~any(wMissing), sum(wMissing), "Every link has a numeric weight.");
wNeg = links.weight < 0;
C = add(C, "V25", "links", "error", ~any(wNeg), sum(wNeg), "No negative weights.");
wZero = links.weight == 0;
C = add(C, "V26", "links", "warning", ~any(wZero), sum(wZero), "No zero weights.");
wFrac = ~wMissing & links.weight ~= round(links.weight);
C = add(C, "V27", "links", "warning", ~any(wFrac), sum(wFrac), ...
    "Weights are integers (they are shared-crime counts).");
otherType = links.link_type ~= "relation";
C = add(C, "V28", "links", "info", ~any(otherType), sum(otherType), ...
    "Links with a type other than 'relation'.");
notObserved = ~links.observed;
C = add(C, "V29", "links", "info", ~any(notObserved), sum(notObserved), ...
    "Links flagged observed=false.");

% Reciprocity: is the 'directed' graph actually symmetric?
valid = srcOk & tgtOk & ~selfLoop;
reciprocal = false(nL,1);
asymWeight = false(nL,1);
if any(valid)
    keyFwd = si(valid) * (nN + 1) + ti(valid);
    keyRev = ti(valid) * (nN + 1) + si(valid);
    [hasRev, revLoc] = ismember(keyRev, keyFwd);
    w = links.weight(valid);
    r = false(nnz(valid),1);
    r(hasRev) = true;
    aw = false(nnz(valid),1);
    aw(hasRev) = w(hasRev) ~= w(revLoc(hasRev));
    reciprocal(valid) = r;
    asymWeight(valid) = aw;
end
C = add(C, "V30", "links", "info", all(reciprocal(valid)), sum(valid & ~reciprocal), ...
    "Links without a reverse link (0 means the directed graph is symmetric).");
C = add(C, "V31", "links", "warning", ~any(asymWeight), sum(asymWeight), ...
    "Reciprocal links carry identical weights.");

% --- Events -------------------------------------------------------------------
notRestored = ~events.id_restored;
C = add(C, "V40", "events", "warning", ~any(notRestored), sum(notRestored), ...
    "Every crime_details key maps back to an original list_cid entry.");
emptyCrime = events.crime_id == "" | ismissing(events.crime_id);
C = add(C, "V41", "events", "error", ~any(emptyCrime), sum(emptyCrime), "Every event has a crime ID.");
if nE > 0
    gEC = findgroups(events.entity_index, events.crime_id);
    dupEvents = nE - numel(unique(gEC));
else
    dupEvents = 0;
end
C = add(C, "V42", "events", "warning", dupEvents == 0, dupEvents, ...
    "No duplicate (offender, crime) association rows.");
missingTime = ismissing(events.event_time);
C = add(C, "V43", "events", "warning", ~any(missingTime), sum(missingTime), ...
    "Every event has a parseable timestamp.");
implausible = ~missingTime & (events.event_time < minDate | events.event_time > maxDate);
C = add(C, "V44", "events", "warning", ~any(implausible), sum(implausible), ...
    sprintf("Event dates fall inside the plausibility window %s to %s.", ...
    string(minDate, 'yyyy-MM-dd'), string(maxDate, 'yyyy-MM-dd')));
early = ~missingTime & events.event_time < seriesStart;
C = add(C, "V45", "events", "info", ~any(early), sum(early), ...
    sprintf("Events before the temporal-series start %s (sparse early period).", ...
    string(seriesStart, 'yyyy-MM-dd')));
tod = ~missingTime & timeofday(events.event_time) > seconds(0);
C = add(C, "V46", "events", "info", any(tod), sum(tod), ...
    "Events with a non-midnight time of day (0 means day resolution only; hour-of-day analysis is not supported).");
xyMissing = isnan(events.x) | isnan(events.y);
C = add(C, "V47", "events", "warning", ~any(xyMissing), sum(xyMissing), "Every event has X and Y.");
xyOut = ~xyMissing & (events.x < 0 | events.x > 1 | events.y < 0 | events.y > 1);
C = add(C, "V48", "events", "error", ~any(xyOut), sum(xyOut), ...
    "Coordinates lie inside the documented normalized range [0,1].");
nBad = isnan(events.num_offenders) | events.num_offenders < 1 | ...
    events.num_offenders ~= round(events.num_offenders);
C = add(C, "V49", "events", "warning", ~any(nBad), sum(nBad), ...
    "num_of_offenders is a positive integer.");

% --- Cross-record consistency -------------------------------------------------
crimes = buildCrimeTable(events);
inconsistent = ~(crimes.time_consistent & crimes.xy_consistent & crimes.num_consistent);
C = add(C, "V50", "consistency", "warning", ~any(inconsistent), sum(inconsistent), ...
    "Each crime has identical date/X/Y/num_of_offenders for all attached offenders.");
countMismatch = crimes.num_offenders ~= crimes.n_offenders_observed & ~isnan(crimes.num_offenders);
C = add(C, "V51", "consistency", "warning", ~any(countMismatch), sum(countMismatch), ...
    "num_of_offenders equals the number of offenders in the file attached to the crime.");

relations = buildRelationTable(events, nodeIds);
fileW = NaN(height(relations),1);
linkWithoutShared = 0;
if any(valid) && height(relations) > 0
    a = min(si(valid), ti(valid));
    b = max(si(valid), ti(valid));
    lk = a * (nN + 1) + b;
    rk = relations.a_index * (nN + 1) + relations.b_index;
    [inRel, loc] = ismember(lk, rk);
    wv = links.weight(valid);
    fileW(loc(inRel)) = wv(inRel);
    linkWithoutShared = numel(unique(lk(~inRel)));
elseif any(valid)
    linkWithoutShared = numel(unique(min(si(valid), ti(valid)) * (nN+1) + max(si(valid), ti(valid))));
end
relWithoutLink = sum(isnan(fileW));
wMismatch = sum(~isnan(fileW) & fileW ~= relations.weight);
C = add(C, "V52", "consistency", "warning", linkWithoutShared == 0, linkWithoutShared, ...
    "Every linked offender pair shares at least one crime.");
C = add(C, "V53", "consistency", "warning", relWithoutLink == 0, relWithoutLink, ...
    "Every offender pair sharing a crime is linked in the file.");
C = add(C, "V54", "consistency", "warning", wMismatch == 0, wMismatch, ...
    "Link weight equals the number of crimes shared by the two offenders.");

% --- Structural observations ----------------------------------------------------
deg = zeros(nN,1);
if height(relations) > 0
    deg = accumarray([relations.a_index; relations.b_index], 1, [nN 1]);
end
isolated = deg == 0;
C = add(C, "V60", "graph", "info", ~any(isolated), sum(isolated), ...
    "Offenders without any co-offending relation (solo offenders; kept as isolated nodes).");

validT = events.event_time(~missingTime);
heapRatio = NaN;
if numel(validT) >= 28
    dom = day(validT);
    perDom = accumarray(dom(dom <= 28), 1, [28 1]);
    heapRatio = perDom(1) / mean(perDom(2:28));
end
C = add(C, "V61", "events", "info", ~(heapRatio > 1.1), round(100 * (heapRatio - 1)), ...
    "Excess (%) of events on day 1 of the month vs. days 2-28 (possible date-imputation heaping).");

% --- Assemble ------------------------------------------------------------------
C = vertcat(C{:});
if isempty(C)
    C = cell(0,6);
end
checks = cell2table(C, 'VariableNames', ...
    {'check_id','category','severity','passed','affected','message'});
checks.check_id = string(checks.check_id);
checks.category = string(checks.category);
checks.severity = string(checks.severity);
checks.message = string(checks.message);

report = struct();
report.checks = checks;
failed = ~checks.passed;
report.errors = checks.message(failed & checks.severity == "error");
report.warnings = checks.message(failed & checks.severity == "warning");
report.is_valid = isempty(report.errors);

s = struct();
s.node_count = nN;
s.link_count = nL;
s.undirected_relation_count = height(relations);
s.event_count = nE;
s.unique_crime_count = height(crimes);
s.isolated_node_count = sum(isolated);
s.symmetric_links = all(reciprocal(valid));
s.weight_equals_shared_crimes = wMismatch == 0 && relWithoutLink == 0 && linkWithoutShared == 0;
s.day_resolution_only = ~any(tod);
s.day1_excess_ratio = heapRatio;
if isempty(validT)
    s.date_min = NaT;
    s.date_max = NaT;
else
    s.date_min = min(validT);
    s.date_max = max(validT);
end
s.events_before_series_start = sum(early);
report.summary = s;

% Backward-compatible top-level fields used by earlier scripts.
report.node_count = nN;
report.link_count = nL;
report.event_count = nE;
report.unique_crime_count = height(crimes);
report.date_min = s.date_min;
report.date_max = s.date_max;
end

function C = add(C, id, category, severity, passed, affected, message)
C{end+1,1} = {char(id), char(category), char(severity), logical(passed), ...
    double(affected), char(message)};
end
