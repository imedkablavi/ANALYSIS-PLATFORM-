function G = buildOffenderGraph(data)
%BUILDOffenderGraph Build a weighted directed MATLAB graph from link data.

required = ["source_id","target_id","weight"];
missing = required(~ismember(required, string(data.links.Properties.VariableNames)));
if ~isempty(missing)
    error("MOSAIC:GraphSchema", "Missing link columns: %s", strjoin(missing, ", "));
end

G = digraph(string(data.links.source_id), ...
    string(data.links.target_id), ...
    double(data.links.weight), ...
    string(data.nodes.entity_id));

G.Nodes.EntityType = string(data.nodes.entity_type);
G.Nodes.EventCount = double(data.nodes.crime_count);
end
