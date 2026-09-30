function cfg = projectConfig()
%PROJECTCONFIG Central project configuration.

cfg.project.name = "Network Behavioral Analysis Platform";
cfg.project.version = "0.1.0";

cfg.data.primary_file = fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json");

cfg.analysis.temporal_unit = "day";
cfg.analysis.random_seed = 42;

cfg.anomaly.method = "isolation_forest";
cfg.anomaly.threshold_policy = "to_be_defined_after_validation";

cfg.privacy.anonymized_data_only = true;
cfg.privacy.reidentification = false;
end
