function cfg = projectConfig()
%PROJECTCONFIG Central project configuration (single source of truth).
%
%   Every threshold, window and model setting used by the pipeline and the
%   experiments is defined here so that results are reproducible from this
%   file plus the dataset blob SHA. Rationale for each choice is documented
%   in docs/METHODOLOGY.md (section references in comments).

cfg.project.name = "Network Behavioral Analysis Platform";
cfg.project.version = "0.2.0";
cfg.project.feature_version = "F2";   % bump when feature definitions change

% --- Data ---------------------------------------------------------------
cfg.data.primary_file = fullfile("data","raw", ...
    "israel_lea_inp_burglary_offender_id_network.json");
cfg.data.source_url = "https://raw.githubusercontent.com/erichoang/" + ...
    "criminal-network-visualization/main/datasets/preprocessed/" + ...
    "israel_lea_inp_burglary_offender_id_network.json";
% Git blob SHA of the verified artifact (docs/DATASET_SCHEMA_INSPECTION.md).
cfg.data.expected_blob_sha = "3afe9cbb4e313fb056f1b115c92a3f750f4698b9";
cfg.data.date_format = "yyyy-MM-dd HH:mm:ss";
% Plausibility bounds for event dates (validation only, never used to drop).
cfg.data.min_plausible_date = datetime(2000,1,1);
cfg.data.max_plausible_date = datetime(2021,12,31);

% --- Temporal (docs/METHODOLOGY.md §4) -----------------------------------
% Before 2014 the artifact contains only 91 offender-crime rows, so
% system-level temporal baselines start in 2014-01. Entity features still
% use every event.
% series_end is EXCLUSIVE. September 2020 is incomplete (data end
% 2020-09-28, 148 rows vs ~280/month) and the data are *solved* cases, so
% the most recent months are right-censored by solving delay.
cfg.temporal.series_start = datetime(2014,1,1);
cfg.temporal.series_end = datetime(2020,9,1);
cfg.temporal.bin = "month";
cfg.temporal.baseline_window = 12;     % causal rolling window (bins)
cfg.temporal.min_baseline_bins = 6;    % bins required before scoring
cfg.temporal.robust_z_threshold = 3.5; % Iglewicz & Hoaglin (1993)
cfg.temporal.burst_window_days = 30;
cfg.temporal.changepoint_min_segment = 6;
cfg.temporal.changepoint_max_changes = 5;
cfg.temporal.snapshot_years = 2014:2020;

% --- Spatial (normalized coordinates only; never de-normalized) ---------
cfg.spatial.grid_size = 20;            % 20x20 cells over [0,1]^2
cfg.spatial.hotspot_alpha = 0.001;     % Poisson upper-tail, Bonferroni-adjusted
cfg.spatial.local_move_quantile = 0.5; % move is "local" if <= global median step

% --- Sequence ------------------------------------------------------------
cfg.sequence.laplace_alpha = 1;
cfg.sequence.ngram_n = 3;
cfg.sequence.min_ngram_support = 5;

% --- Anomaly (docs/ANOMALY_DETECTION.md) ---------------------------------
cfg.analysis.random_seed = 42;
cfg.anomaly.min_events = 3;            % eligibility: >= 2 inter-event gaps
cfg.anomaly.feature_groups = ["activity","temporal","spatial", ...
    "cooffending","graph","sequence"];
cfg.anomaly.method = "isolation_forest";
cfg.anomaly.iforest.num_learners = 200;
cfg.anomaly.iforest.num_observations_per_learner = 256; % Liu et al. (2008)
cfg.anomaly.review_budget_fraction = 0.01;  % top 1% of eligible entities
cfg.anomaly.feature_z_threshold = 3.5;      % per-feature evidence flag
cfg.anomaly.explain_top_k = 100;            % entities receiving occlusion attribution

% --- Evaluation (docs/EVALUATION.md) -------------------------------------
cfg.evaluation.synthetic_fraction = 0.01;
cfg.evaluation.synthetic_shift = [3 5];     % robust-SD shifts for injection
cfg.evaluation.synthetic_repeats = 10;
cfg.evaluation.stability_seeds = 1:10;
cfg.evaluation.sensitivity.num_learners = [50 100 200 400];
cfg.evaluation.sensitivity.num_obs = [64 128 256 512];
cfg.evaluation.sensitivity.min_events = [2 3 5];
cfg.evaluation.sensitivity.budget = [0.005 0.01 0.02 0.05];

% --- Output ---------------------------------------------------------------
cfg.output.bundle_file = fullfile("outputs","model","analysis_bundle.mat");
cfg.output.report_dir = fullfile("outputs","reports");
cfg.output.experiment_dir = fullfile("outputs","experiments");
cfg.output.figure_dir = fullfile("outputs","figures");

% --- Application -----------------------------------------------------------
cfg.app.max_graph_nodes = 400;   % cap for interactive rendering
cfg.app.audio_cues = false;      % optional; analysis never depends on audio

% --- Privacy ---------------------------------------------------------------
cfg.privacy.anonymized_data_only = true;
cfg.privacy.reidentification = false;
cfg.privacy.denormalize_coordinates = false;
end
