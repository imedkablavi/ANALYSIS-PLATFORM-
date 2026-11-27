# MATLAB application

`NetworkBehaviorExplorer` provides linked host ranking, neighbourhood,
timeline, measured feature evidence, supporting flows, provenance and export.

From the project root, run `run('START_PROJECT.m')` in MATLAB to open the
latest valid saved network analysis and all explorer views without re-running
the analysis. If no saved network result exists, the app opens in an empty
state and lets you select a dataset.

Run `scripts/run_network_demo.m` only when you intentionally want to verify
and analyse the full official CTU-13 capture again. `scripts/launch_app.m`
remains an alternative entry point. Analytical functions remain in `src/`;
callbacks connect selections and views.

The current implementation requires GUI acceptance in the target MATLAB
installation. Historical screenshots/runs do not validate later changes.
Use [the walkthrough](../docs/DEMO_SCENARIO.md) and record evidence through
`scripts/verify_delivery.m` for the corresponding automated checks.

The interface starts in Turkish unless an English preference was saved.
Use the Türkçe / English selector to change language. The current investigation
is retained while playback stops.

[ Türkçe kullanım kılavuzu](../docs/KULLANIM_KILAVUZU.md) ·
[English user guide](../docs/USER_GUIDE_EN.md) ·
[GUI acceptance](../docs/UI_ACCEPTANCE_TR_EN.md)
