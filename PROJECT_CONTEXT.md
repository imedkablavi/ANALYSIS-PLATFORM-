# Project Context

## Scope

Network Behaviour Explorer is an offline MATLAB application for computer-network
traffic analysis, host anomaly ranking and linked evidence investigation.
The recorded owner decision of 2026-10-20 defines the domain as computer
networks. The original professor assignment has not been supplied; its exact
wording remains the scope reference once recorded in docs/ASSIGNMENT_SOURCE.md.

## Primary network case study

Complete official CTU-13 scenario 7, acquired and independently audited on
2026-10-31. Local path: `data/external/ctu13-scenario7.binetflow`.
Git blob: `33065bb8bc1df911fae818e3475ee0cf96d0e0a9`.
114,077 flows; 38,204 hosts. Of 2,456 hosts with at least three incident
flows, one has malicious labels, six benign and 2,449 unknown. These are source
facts and eligibility counts, not measured detector performance.
Source and reproduction: docs/REAL_CAPTURE_EVIDENCE.md.

The earlier burglary-network artifact remains a separate secondary case study,
with schema/reference facts in docs/DATASET_SCHEMA_INSPECTION.md. It must not
determine the wording or claimed semantics of network-traffic features.

## Implementation and verification

Implemented: import profiles and generic tabular contracts; validation;
features and graphs; temporal/sequence analyses; baseline and Isolation Forest;
explanations; experiments including published-label E11; interactive app;
provenance and bounded supporting-flow views; investigation export; delivery
receipts and source/artifact fingerprints.

Historical MATLAB Online execution is recorded in CHANGELOG. Subsequent local
changes are parsed statically but have not been executed in MATLAB. The source
capture audit and Python reference regression tests execute locally. The task
board distinguishes implementation from verified execution; no detection
accuracy or GUI-readiness claim follows from file presence.

## Commands

- `python3 scripts/data/acquire_ctu13_scenario7.py`: acquire and fingerprint.
- `run scripts/run_network_demo.m`: verify input, analyse, open app in MATLAB.
- `verify_delivery("data/external/ctu13-scenario7.binetflow")`: retain tests,
  experiments, settings and source/artifact fingerprints.

## Boundaries

Scores are descriptive statistical deviations, not calibrated compromise
probabilities. Labels are evaluation-only. Replayed observations have their own
time scope; full-run scores are not retroactive real-time detections. External
imports require supported layouts and meaningful fields. Do not invent labels,
metrics, identities, coordinates, assignment wording or execution evidence.
