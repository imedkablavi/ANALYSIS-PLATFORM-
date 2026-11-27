function evidence = verify_delivery(datasetPath, opts)
%VERIFY_DELIVERY Run tests and a real labelled network experiment, retaining evidence.
%   addpath scripts; verify_delivery("data/external/capture.binetflow")
%   Requires MATLAB + Statistics and Machine Learning Toolbox. Never creates
%   labels or metrics by hand. opts.quick=true is a smoke run, not delivery.
arguments
    datasetPath (1,1) string
    opts struct = struct()
end
root = setupProject();
out = fullfile(root, "outputs", "verification", ...
    string(datetime('now'), 'yyyyMMdd_HHmmss_SSS'));
mkdir(out);
diary(fullfile(out, "matlab_run.log"));
cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
evidence = struct('status', "RUNNING", 'matlab_version', version, ...
    'started', string(datetime('now')), 'quick', cfgGet(opts, "quick", false));
manifest = fullfile(out, "verification.json");
% Persist before preflight so a missing toolbox still leaves a run record.
writeTextFile(manifest, jsonencode(deliveryEvidence("json_safe", evidence)));
try
    source = struct();
    for folder = ["src", "scripts", "configs", "app", "tests"]
        source.(folder) = deliveryEvidence("source_fingerprints", fullfile(root, folder));
    end
    evidence.source_fingerprints = source;
    writeTextFile(manifest, jsonencode(deliveryEvidence("json_safe", evidence)));
    if isempty(which('iforest'))
        error("MOSAIC:ToolboxRequired", "Delivery verification requires Isolation Forest.");
    end
    results = runtests(fullfile(root, "tests"));
    save(fullfile(out, "test_results.mat"), "results");
    evidence.tests_passed = nnz([results.Passed]);
    evidence.tests_failed = nnz([results.Failed]);
    evidence.tests_skipped = nnz([results.Incomplete]);
    if isempty(results) || any([results.Failed])
        error("MOSAIC:TestsFailed", "Tests failed; see retained test_results.mat.");
    end
    importOpts = opts;
    importOpts.use_iforest = true;
    b = analyzeDataset(datasetPath, importOpts);
    if ~b.meta.iforest_used || ~isfield(b.ground_truth, 'evaluation')
        error("MOSAIC:EvaluationRequired", "A labelled network dataset and both detectors are required.");
    end
    deliveryEvidence("require_iforest", b);
    E = b.ground_truth.evaluation;
    known = E.setting == "known_only";
    if ~any(known) || any(~isfinite(E.roc_auc(known)))
        error("MOSAIC:ClassesRequired", "Known eligible hosts must contain both malicious and benign classes.");
    end
    evidence.dataset_sha = b.meta.dataset_blob_sha;
    evidence.dataset_id = b.meta.dataset.id;
    if isfield(b.meta.dataset, 'import_sha')
        evidence.import_sha = b.meta.dataset.import_sha;
    end
    evidence.include_synthetic = false; % delivery evidence is always observed-data only
    evidence.config = b.config;
    evidence.config_notes = b.meta.config_notes;
    evidence.bundle_file = fullfile(root, b.config.output.bundle_file);
    runExperiments(b, b.config, fullfile(out, "experiments"), struct('quick', evidence.quick, 'include_synthetic', false));
    evidence.experiment_fingerprints = deliveryEvidence("fingerprints", fullfile(out, "experiments"));
    if isempty(evidence.experiment_fingerprints)
        error("MOSAIC:ExperimentsRequired", "No experiment artifacts were retained.");
    end
    evidence.status = deliveryEvidence("completion_status", evidence);
    evidence.manual_app_check = "PENDING: open, select host, change language/dataset, replay, export";
catch ME
    % A failed experiment may already have written useful partial artifacts.
    if isfolder(fullfile(out, "experiments"))
        try
            evidence.experiment_fingerprints = deliveryEvidence("fingerprints", fullfile(out, "experiments"));
        catch fingerprintError
            evidence.fingerprint_error_identifier = string(fingerprintError.identifier);
        end
    end
    evidence.status = "FAILED";
    evidence.error_identifier = string(ME.identifier);
    evidence.error_message = "Verification did not complete; inspect the retained MATLAB log.";
    evidence.finished = string(datetime('now'));
    writeTextFile(manifest, jsonencode(deliveryEvidence("json_safe", evidence)));
    rethrow(ME);
end
evidence.finished = string(datetime('now'));
writeTextFile(manifest, jsonencode(deliveryEvidence("json_safe", evidence)));
fprintf("Evidence: %s | status: %s | GUI verification remains manual.\n", out, evidence.status);
end
