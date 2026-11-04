# Remaining delivery roadmap — recalculated 2026-10-31

The original October 1–30 calendar is historical, not a completed schedule. The
remaining work below is ordered by dependencies, without inventing a new submission
date. Exact assignment and deadline confirmation remain external inputs.

Historical evidence: CHANGELOG records 114/114 MATLAB Online tests on 2026-10-27.
Current fixes/new tests have not run in MATLAB. Official complete CTU-13 scenario 7
is already local and independently audited; downloading network data is no longer
the main blocker. See `docs/TASKS.md` for per-task evidence/status.

## Stage 1 — Current execution gate

- Obtain an available MATLAB runtime and required toolbox; run `scripts/run_tests.m`.
- Run `scripts/run_network_demo.m` on pinned scenario 7, inspect canonical counts,
  validation warnings, label attribution, flow features and graph cost guards.
- Run current experiments, generate figures and `scripts/verify_delivery.m`; retain
  errors, source/configuration fingerprints, elapsed time and verification manifest.
- Gate: current tests pass and current real-data outputs are traceable. Python
  reference results or historical tests alone do not satisfy this gate.

## Stage 2 — Results and interface verification

- Interpret generated E1–E9/ground-truth metrics; separate synthetic injections,
  observed published labels and unknown-background assumptions.
- Document that scenario 7 contains only one labelled malicious host: no broad
  detector-generalization or precision claims from that small positive population.
- Review actual top-ranked explanations and launch the revised app; verify linked
  graph, minute timeline, traffic details, chronological replay and privacy.
- Adapt demo instructions/E10 answer key to a short computer-network capture;
  spatial/yearly burglary tasks cannot be reused unchanged.
- Gate: repeatable current demo walkthrough and actual outputs ready for reporting.

## Stage 3 — Human inputs and E10

- Acquire the professor's exact wording, course/author details and submission constraints.
- Confirm report language and presentation format; decide how to resolve the
  unsupported “better than tables” comparison claim (comparison study or narrower question).
- Confirm institutional requirements for volunteer sessions; review Turkish SUS wording.
- If E10 is retained: pilot then 5–8 actual volunteer sessions, private anonymous
  responses, scoring and explicit study limitations. Templates are not results.
- Gate: authentic study evidence or an explicit documented scope exclusion.

## Stage 4 — Delivery artifacts

- Extend the written factual report with detector/experiment results only from generated current artifacts; add confirmed academic metadata.
- Build final slides and demo backup; synchronize report, figures, README and task board.
- Reproduce from a clean checkout on the delivery machine, verify manifests, then release.
- Gate: complete report, presentation, demonstrable application and traceable evidence.

## Scope rule

Optional audio and visual polish can be deferred. Additional CIC/UNSW/LANL
real-capture evaluations and future-time holdout experiments remain extensions;
implemented profiles are not proof of real-data validation. Preserve validation,
unknown-label handling, eligibility, explanation/privacy rules and truthful limits.
