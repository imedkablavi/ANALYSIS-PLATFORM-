function [filePath, spec] = makeSyntheticNetworkJson(folder, mutation)
%MAKESYNTHETICNETWORKJSON Write a small artifact-shaped JSON test fixture.
%
%   [FILEPATH, SPEC] = MAKESYNTHETICNETWORKJSON(FOLDER, MUTATION)
%
%   The fixture reproduces the verified artifact's structure (NetworkX JSON,
%   "OID#n"/"CID#n" identifiers that jsondecode mangles, reciprocal links
%   whose weight = shared crimes, day-resolution dates) with values chosen
%   so features can be computed by hand (expected values in the tests).
%   It is synthetic TEST data only; it is never used as analytical evidence.
%
%   Offenders 1..7. Crimes (id: date, X, Y, offenders):
%     1: 2015-01-01 .10 .10 {1,2}     6: 2015-02-05 .30 .32 {3,4,5}
%     2: 2015-01-11 .12 .10 {1,2}     7: 2016-06-01 .70 .20 {6}
%     3: 2015-02-10 .50 .50 {1,3}     8: 2016-06-01 .71 .21 {6}
%     4: 2015-03-12 .90 .90 {1}       9: 2016-07-01 .70 .20 {6}
%     5: 2015-01-05 .30 .30 {3,4,5}  10: 2017-01-01 .40 .60 {7}
%   Co-offending graph: 1-2 (w2), 1-3 (w1), 3-4 (w2), 3-5 (w2), 4-5 (w2);
%   offenders 6 and 7 are isolated.
%
%   MUTATION (optional): "none" | "negative_weight" | "dangling_link" |
%   "bad_coordinate" | "inconsistent_date" | "missing_date" | "bad_date" |
%   "asymmetric_weight" | "weight_mismatch" | "duplicate_node" | "empty_id"

arguments
    folder (1,1) string = string(tempdir)
    mutation (1,1) string = "none"
end

crimes = struct( ...
    'date', {"2015-01-01","2015-01-11","2015-02-10","2015-03-12","2015-01-05", ...
             "2015-02-05","2016-06-01","2016-06-01","2016-07-01","2017-01-01"}, ...
    'x', {0.10, 0.12, 0.50, 0.90, 0.30, 0.30, 0.70, 0.71, 0.70, 0.40}, ...
    'y', {0.10, 0.10, 0.50, 0.90, 0.30, 0.32, 0.20, 0.21, 0.20, 0.60}, ...
    'members', {[1 2], [1 2], [1 3], 1, [3 4 5], [3 4 5], 6, 6, 6, 7});
nOff = 7;
edges = [1 2 2; 1 3 1; 3 4 2; 3 5 2; 4 5 2];   % a b weight

nodeIds = "OID#" + (1:nOff);
if mutation == "duplicate_node"
    nodeIds(7) = "OID#6";
elseif mutation == "empty_id"
    nodeIds(7) = "";
end

% Per-(offender, crime) overrides for mutations
dateOverride = containers.Map('KeyType', 'char', 'ValueType', 'any');
if mutation == "inconsistent_date"
    dateOverride('4_5') = "2015-01-06";        % offender 4 disagrees on crime 5
elseif mutation == "missing_date"
    dateOverride('1_1') = [];
elseif mutation == "bad_date"
    dateOverride('1_1') = "2015-13-45";
end
if mutation == "bad_coordinate"
    crimes(4).x = 1.5;
end

nodeText = strings(nOff, 1);
for o = 1:nOff
    mine = find(arrayfun(@(c) any(c.members == o), crimes));
    cidList = "CID#" + mine;
    details = strings(numel(mine), 1);
    for k = 1:numel(mine)
        c = crimes(mine(k));
        key = sprintf('%d_%d', o, mine(k));
        dateText = """" + c.date + " 00:00:00""";
        if isKey(dateOverride, key)
            v = dateOverride(key);
            if isempty(v)
                dateText = "null";
            else
                dateText = """" + v + " 00:00:00""";
            end
        end
        details(k) = sprintf('"%s": {"X": %.17g, "Y": %.17g, "date": %s, "num_of_offenders": %d}', ...
            cidList(k), c.x, c.y, dateText, numel(c.members));
    end
    nodeText(o) = sprintf(['{"type": "offender", "list_cid": [%s], ' ...
        '"crime_details": {%s}, "id": "%s"}'], ...
        joinStrings("""" + cidList + """", ", "), joinStrings(details, ", "), nodeIds(o));
end

linkRows = strings(0, 1);
for e = 1:size(edges, 1)
    a = edges(e, 1); b = edges(e, 2); w = edges(e, 3);
    wab = w; wba = w;
    if mutation == "negative_weight" && e == 1
        wab = -1; wba = -1;
    elseif mutation == "asymmetric_weight" && e == 1
        wba = w + 1;
    elseif mutation == "weight_mismatch" && e == 2
        wab = 5; wba = 5;
    end
    linkRows(end+1, 1) = linkText(wab, "OID#" + a, "OID#" + b); %#ok<AGROW>
    linkRows(end+1, 1) = linkText(wba, "OID#" + b, "OID#" + a); %#ok<AGROW>
end
if mutation == "dangling_link"
    linkRows(end+1, 1) = linkText(1, "OID#1", "OID#99");
end

json = sprintf(['{"directed": true, "multigraph": false, "graph": {"name": "fixture"}, ' ...
    '"nodes": [%s], "links": [%s]}'], joinStrings(nodeText, ", "), joinStrings(linkRows, ", "));

if ~isfolder(folder)
    mkdir(folder);
end
filePath = fullfile(folder, "fixture_" + mutation + ".json");
fid = fopen(filePath, 'w', 'n', 'UTF-8');
fprintf(fid, '%s', json);
fclose(fid);

spec.crimes = crimes;
spec.edges = edges;
spec.n_offenders = nOff;
end

function t = linkText(w, s, d)
t = sprintf('{"weight": %.1f, "type": "relation", "observed": true, "source": "%s", "target": "%s"}', ...
    w, s, d);
end
