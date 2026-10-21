function [cls, role, detail, note] = labelNetworkFlows(rule, label, labelDetail)
%LABELNETWORKFLOWS Published flow labels -> malicious / benign / unknown.
%
%   [CLS, ROLE, DETAIL, NOTE] = LABELNETWORKFLOWS(RULE, LABEL, LABELDETAIL)
%   RULE (networkFlowProfiles label_rule):
%     "ctu13"        CTU-13 labels such as "flow=From-Botnet-V42-TCP-..." :
%                    contains "Botnet" -> malicious, "Normal" -> benign,
%                    anything else (Background, empty) -> unknown. The
%                    dataset labels Background traffic as not analysed, so
%                    it is NEVER counted as benign. A leading "To-" (after an optional "flow=") means the
%                    label describes the DESTINATION host (role "dst"),
%                    otherwise the source host (role "src").
%     "benign_word"  CIC-IDS2017: "BENIGN" -> benign, empty -> unknown,
%                    any other text -> malicious (the text is the attack
%                    name, kept as DETAIL); role "src" (attacking host).
%     "binary"       UNSW-NB15: 1 -> malicious, 0 -> benign, other ->
%                    unknown; DETAIL = attack category; role "src".
%     "none"         every record unknown.
%   NOTE records the rule and the resulting counts (import notes).
%
%   These labels describe the PUBLISHED ground truth of the dataset. They
%   are used to evaluate the detectors (evaluateGroundTruth), never as
%   features, and a host with a malicious label is still a host whose
%   traffic matched an attack scenario, not a verdict about a person.

arguments
    rule (1,1) string
    label (:,1) string
    labelDetail (:,1) string
end

n = numel(label);
cls = repmat("unknown", n, 1);
role = repmat("src", n, 1);
detail = labelDetail;
low = lower(label);
switch rule
    case "ctu13"
        cls(contains(low, "normal")) = "benign";
        cls(contains(low, "botnet")) = "malicious";
        role(contains(low, regexpPattern("^(flow=)?to-"))) = "dst";
        detail = strings(n, 1);
        detail(cls == "malicious") = "botnet";
        detail(cls == "benign") = "normal";
        detail(cls == "unknown" & contains(low, "background")) = "background";
    case "benign_word"
        has = strlength(label) > 0;
        cls(has) = "malicious";
        cls(low == "benign") = "benign";
        detail = label;
        detail(cls ~= "malicious") = "";
    case "binary"
        cls(label == "1") = "malicious";
        cls(label == "0") = "benign";
    case "none"
        % all unknown
    otherwise
        error("MOSAIC:LabelRule", "Unknown label rule: %s", rule);
end
note = sprintf("Labels (%s rule): %d malicious, %d benign, %d unknown records; " + ...
    "used for evaluation only, never as features.", rule, nnz(cls == "malicious"), ...
    nnz(cls == "benign"), nnz(cls == "unknown"));
end
