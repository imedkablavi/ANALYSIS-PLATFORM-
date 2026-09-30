function features = mergeFeatureTables(behaviorFeatures, graphFeatures)
%MERGEFEATURETABLES Join entity-level feature tables on entity_id.

features = outerjoin(behaviorFeatures, graphFeatures, ...
    'Keys',"entity_id", 'MergeKeys',true, 'Type','left');

features = sortrows(features, "entity_id");
end
