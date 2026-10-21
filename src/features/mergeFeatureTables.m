function features = mergeFeatureTables(varargin)
%MERGEFEATURETABLES Column-wise merge of entity-level feature tables.
%
%   FEATURES = MERGEFEATURETABLES(T1, T2, ...) where T1 has an entity_id
%   column that defines row order. Each further table must either carry an
%   entity_id column (it is matched by ID, missing entities get NaN) or have
%   exactly height(T1) rows in the same entity order (index-aligned tables
%   such as the sequence features). Duplicate column names raise an error
%   instead of being silently suffixed.

features = varargin{1};
ids = features.entity_id;
for k = 2:nargin
    T = varargin{k};
    if ismember('entity_id', T.Properties.VariableNames)
        [found, loc] = ismember(ids, T.entity_id);
        T = removevars(T, 'entity_id');
        aligned = array2table(NaN(numel(ids), width(T)), ...
            'VariableNames', T.Properties.VariableNames);
        for v = 1:width(T)
            col = T{:, v};
            if isnumeric(col) || islogical(col)
                aligned{found, v} = double(col(loc(found)));
            else
                error("MOSAIC:MergeType", "Non-numeric feature column %s.", ...
                    T.Properties.VariableNames{v});
            end
        end
        T = aligned;
    elseif height(T) ~= numel(ids)
        error("MOSAIC:MergeAlignment", ...
            "Table %d has no entity_id and %d rows (expected %d).", k, height(T), numel(ids));
    end
    clash = intersect(features.Properties.VariableNames, T.Properties.VariableNames);
    if ~isempty(clash)
        error("MOSAIC:MergeClash", "Duplicate feature columns: %s", strjoin(clash, ", "));
    end
    features = [features T]; %#ok<AGROW>
end
end
