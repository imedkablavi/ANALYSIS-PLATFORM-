function info = bundleDatasetInfo(bundle)
%BUNDLEDATASETINFO Dataset descriptor of a bundle, with defaults for old bundles.
%
%   INFO = BUNDLEDATASETINFO(BUNDLE) reads BUNDLE.meta.dataset (written by
%   analyzeDataset) and fills what is missing. Bundles created before the
%   dataset-import layer have no meta.dataset: they are the primary
%   burglary dataset, which has (normalized) coordinates.
%
%   info.id, info.name, info.format, info.source_file   strings
%   info.has_coordinates   logical (absent -> true)
%   info.pseudonymized     logical (absent -> true)
%   info.event_noun / event_plural     "crime"/"crimes" for the burglary
%                                      format, otherwise "event"/"events"
%   info.entity_noun / entity_plural   "offender(s)" or "entity/entities"
%   info.network_label     "Co-offending network" or "Relation network"
%   Pure function: no graphics, unit-tested.

info.id = "primary";
info.name = "Primary dataset";
info.format = "networkx_burglary_json";
info.source_file = "";
info.has_coordinates = true;
info.pseudonymized = true;
if isstruct(bundle) && isfield(bundle, 'meta') && isstruct(bundle.meta) && ...
        isfield(bundle.meta, 'dataset') && isstruct(bundle.meta.dataset)
    d = bundle.meta.dataset;
    for f = ["id", "name", "format", "source_file"]
        if isfield(d, f) && ~isempty(d.(f)) && strlength(string(d.(f))) > 0
            info.(f) = string(d.(f));
        end
    end
    for f = ["has_coordinates", "pseudonymized"]
        if isfield(d, f) && ~isempty(d.(f))
            info.(f) = logical(d.(f)(1));
        end
    end
end
if info.format == "networkx_burglary_json"
    info.event_noun = "crime";
    info.event_plural = "crimes";
    info.entity_noun = "offender";
    info.entity_plural = "offenders";
    info.network_label = "Co-offending network";
else
    info.event_noun = "event";
    info.event_plural = "events";
    info.entity_noun = "entity";
    info.entity_plural = "entities";
    info.network_label = "Relation network";
end
end
