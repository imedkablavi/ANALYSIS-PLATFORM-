function label = datasetFormatLabel(format)
%DATASETFORMATLABEL Readable UI type without exposing internal schema keys.
arguments
    format (1,1) string
end
switch format
    case "network_flow"
        label = uiText("Network flows");
    case "event_csv"
        label = uiText("Event records");
    case "edge_csv"
        label = uiText("Timestamped connections");
    case "networkx_burglary_json"
        label = uiText("Shared-event network");
    otherwise
        label = uiText("Imported dataset");
end
end
