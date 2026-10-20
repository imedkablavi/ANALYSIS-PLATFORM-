# Final Demo Scenario (≈ 8 minutes)

## Main demo: CTU-13 botnet capture (network traffic)

Preparation: download one CTU-13 scenario (`.binetflow`) into `data/external/`, run
`b = analyzeDataset("data/external/<file>.binetflow")` and `scripts/run_experiments.m` with
`DATASET = "latest"` once, then `run scripts/launch_app.m` and pick the dataset in the header list.

1. **Header and KPI tiles** — dataset name and format badge (`network_flow`), hosts, flows, scored
   hosts, flagged hosts, unusual periods, data quality. Say: "every flow is an event between two
   pseudonymized hosts; no IP address is shown or stored."
2. **Data quality tab** — validation result; import notes (time format, how many flows, label
   counts, Background = unknown).
3. **Ranking** — "Flagged (either detector)"; eligibility (≥ 3 flows) and the 1 % review budget.
4. **Select the top host** — network (who it talks to), timeline (its flows over the capture,
   minute/hour bins) update together.
5. **Why flagged / Deviation profile** — point at the network-traffic group: e.g. very high
   fan-out, many tiny flows, or `beacon_cv_min` close to 0 (clock-like repeated connections).
   Read the caveat: a deviation, not a verdict.
6. **Status line** — only now show the host's *published label* (e.g. botnet) — the detectors
   never saw it.
7. **Ground truth tab** — ROC-AUC and AP vs chance for both detectors; known-only vs
   unknown-as-benign; how many malicious hosts were too quiet to be scored.
8. **Replay** — Reset, Play: the communication network grows over the capture; unusual periods
   are labelled (optional audio cue).
9. **Detectors tab** — baseline vs Isolation Forest agreement.
10. **Export** — PNGs (no host labels) and the evidence text.

Fallback if the app cannot run on the day: the exported PNGs and `experiments_summary.md`
(E11 table) of the same run.

## Case study (optional, 2 minutes): burglary co-offending artifact

Preparation: `run scripts/run_pipeline.m` (once), then `run scripts/launch_app.m`.

1. **Dashboard** — dataset size, date range, validation status; say: "all links are reciprocal and
   equal the shared-crime count, so the network is rebuilt from the records with timestamps."
2. **Data quality tab** — show the info observations (day resolution, pre-2014 sparsity, day-1
   heaping) and why the temporal series starts in 2014.
3. **Ranking** — "Flagged (either detector)"; explain the eligibility rule (≥ 3 crimes) and the
   1 % review budget.
4. **Select the top entity** — network, timeline and map update together (linked views).
5. **Why flagged** — read the evidence text; open **Deviation profile**; point to the dominant
   group and to the interpretation caveat.
6. **Events tab** — tokens (partner state + move) and the rare transition with high surprisal.
7. **Partners tab** — click a partner: every view follows (brushing & linking).
8. **Replay** — Reset, then Play: ties appear at their first shared crime, the map shows the current
   12-month window, unusual months are labelled (optional audio cue).
9. **Detectors tab** — baseline vs Isolation Forest agreement; mention E8 stability.
10. **Timeline** — an unusual month and a change point; mention the seasonality limitation.
11. **Export** — PNGs and evidence text written to `outputs/`.

## Defense message

The system is a reproducible analytical pipeline, not a static picture: results follow from the
data, the configuration and documented methods, and every score comes with its evidence and its
limits. A deviation is not an accusation, and a published benchmark label is used to measure the
ranking, not to judge a host.
