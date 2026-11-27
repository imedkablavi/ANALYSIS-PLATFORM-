# Milestones — evidence audit 2026-10-31

| Milestone | Acceptance evidence | Current status |
| --- | --- | --- |
| M0 Scope frozen | Exact original assignment plus requirements mapping | PARTIAL/BLOCKED: computer-network scope confirmed, source wording still missing in `docs/ASSIGNMENT_SOURCE.md`. |
| M1 Data ready | Pinned real capture, canonical MATLAB import and validation | PARTIAL: official scenario 7 acquired and independently audited (`docs/REAL_CAPTURE_EVIDENCE.md`, `audit_network_capture.py`); current MATLAB import/validation pending. |
| M2 Behavioral engine ready | Current feature, temporal, graph and sequence tests plus real outputs | IMPLEMENTED: `src/features/`, `src/temporal/`, `src/graph/`, `src/sequence/`; fresh runtime execution absent. Spatial code is retained but not applicable to this capture. |
| M3 Detection validated | Current baseline/IF, E1–E9 and ground-truth outputs with limitations | IMPLEMENTED/PARTIAL: evaluation code exists; independent label counts are not detector results. Generated metrics and review missing. |
| M4 Multimedia app ready | Current linked views/replay walkthrough on real capture, E10 if required | IMPLEMENTED/PARTIAL: programmatic application exists and historical screenshot work is documented; current launch, walkthrough and participant sessions absent. |
| M5 Final delivery | Report results, slides, demo backup, clean-machine verification, release | PARTIAL/MISSING: report draft and demo instructions exist; final results, slide deck, backup and release not complete. |

CHANGELOG records MATLAB Online **114/114 tests on 2026-10-27**. This historical
run does not validate the revised 2026-10-31 implementation/new tests. Current
independent Python audits verify source/label facts only. Record fresh MATLAB
execution and delivery verification before promoting runtime-dependent milestones
to VERIFIED; see `docs/REPRODUCIBILITY.md` and `scripts/verify_delivery.m`.
