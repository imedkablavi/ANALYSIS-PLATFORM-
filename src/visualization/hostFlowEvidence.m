function [T, total] = hostFlowEvidence(bundle, entityIndex, limit)
%HOSTFLOWEVIDENCE Bounded source observations for one host, without raw IDs.
%   Rows are chronological; total reports truncation. The detector scores
%   describe a whole host, not a causal attribution to any displayed flow.
%   HOST-n peers are bundle-local indices, never source IPs or names.
arguments
    bundle struct
    entityIndex (1,1) double {mustBeInteger, mustBePositive}
    limit (1,1) double {mustBeInteger, mustBePositive} = 2000
end
T = table();
total = 0;
if ~isfield(bundle, 'flows') || isempty(bundle.flows)
    return;
end
F = bundle.flows;
rows = find(F.src_index == entityIndex | F.dst_index == entityIndex);
total = numel(rows);
[~, order] = sort(F.time(rows));
rows = rows(order(1:min(limit, total)));
f = F(rows,:);
direction = repmat("incoming", height(f), 1);
out = f.src_index == entityIndex;
direction(out) = "outgoing";
peer = f.src_index;
peer(out) = f.dst_index(out);
direction(f.src_index == f.dst_index) = "self";
T = table(string(f.time, 'yyyy-MM-dd HH:mm:ss.SSS'), direction, "HOST-" + string(peer), ...
    string(f.proto), f.sport, f.dport, f.duration_s, f.bytes, f.packets, ...
    'VariableNames', {'time','direction','peer','protocol','source_port', ...
    'destination_port','duration_seconds','bytes','packets'});
end
