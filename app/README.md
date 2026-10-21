# MATLAB App — Network Behaviour Explorer

`NetworkBehaviorExplorer.m` — launch with `run scripts/launch_app.m` after `run scripts/run_pipeline.m`.

Built programmatically from App Designer components (uifigure family) so the source is reviewable
text; callbacks only call `src/visualization` and `src/` functions, which are unit-tested without a
GUI. Views, interactions and design rationale: docs/MULTIMEDIA_DESIGN.md. Walkthrough:
docs/DEMO_SCENARIO.md.

Status: implemented, not yet launched (no MATLAB in the development environment).
