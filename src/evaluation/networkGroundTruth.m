function truth = networkGroundTruth(flows, nEnt)
%NETWORKGROUNDTRUTH Host-level ground truth from the published flow labels.
%
%   TRUTH = NETWORKGROUNDTRUTH(FLOWS, NENT) returns one row per host:
%     entity_index
%     truth            "malicious" | "benign" | "unknown"
%     malicious_flows  flows whose label is about this host and malicious
%     benign_flows     same, benign
%   The host a flow label is about is its source (label_role "src") or
%   destination ("dst"); see labelNetworkFlows. A host is malicious when at
%   least one labelled flow about it is malicious, benign when it has
%   benign labelled flows and no malicious one, unknown otherwise (e.g.
%   CTU-13 Background traffic, which the dataset authors did not label).

arguments
    flows table
    nEnt (1,1) double
end

host = flows.src_index;
isDst = flows.label_role == "dst";
host(isDst) = flows.dst_index(isDst);
mal = flows.label_class == "malicious";
ben = flows.label_class == "benign";
malN = accumarray(host, double(mal), [nEnt 1]);
benN = accumarray(host, double(ben), [nEnt 1]);
t = repmat("unknown", nEnt, 1);
t(benN > 0) = "benign";
t(malN > 0) = "malicious";
truth = table((1:nEnt)', t, malN, benN, 'VariableNames', ...
    {'entity_index', 'truth', 'malicious_flows', 'benign_flows'});
end
