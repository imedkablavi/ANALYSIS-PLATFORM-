function features = buildBehaviorFeatures(events, data)
%BUILDBEHAVIORFEATURES Build first-version offender behavioral features.
%
% These features describe observable behavior in the supplied dataset.
% They are not criminality scores and must not be interpreted as such.

entities = data.nodes.entity_id;
n = numel(entities);

features = table(entities, ...
    zeros(n,1), zeros(n,1), zeros(n,1), zeros(n,1), ...
    NaN(n,1), NaN(n,1), zeros(n,1), ...
    'VariableNames', { ...
    'entity_id','event_count','unique_crime_count', ...
    'unique_partner_count','mean_cooffender_count', ...
    'spatial_dispersion','mean_inter_event_days','active_day_count'});

% Partner set from the observed offender graph.
for i = 1:n
    id = entities(i);
    mask = events.entity_id == id;
    e = events(mask,:);

    features.event_count(i) = height(e);
    features.unique_crime_count(i) = numel(unique(e.crime_id));
    features.active_day_count(i) = numel(unique(dateshift(e.event_time,'start','day')));

    if height(e) > 1
        dt = days(diff(sort(e.event_time)));
        features.mean_inter_event_days(i) = mean(dt, 'omitnan');
    end

    xy = [e.x e.y];
    xy = xy(all(isfinite(xy),2),:);
    if size(xy,1) > 1
        features.spatial_dispersion(i) = mean(pdist(xy,'euclidean'));
    end
end

% Network degree features.
G = digraph(data.links.source_id, data.links.target_id, ...
    data.links.weight, data.nodes.entity_id);

dOut = outdegree(G);
dIn = indegree(G);
features.unique_partner_count = double(dOut + dIn);

coCounts = events.num_offenders(events.entity_id == entities(1));
for i = 1:n
    vals = events.num_offenders(events.entity_id == entities(i));
    vals = vals(isfinite(vals));
    if ~isempty(vals)
        features.mean_cooffender_count(i) = mean(vals);
    end
end
end
