# Final Demo Scenario (≈ 8 minutes)

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
limits. A deviation is not an accusation.
