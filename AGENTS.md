# Agent Instructions

## Project rules

1. Read `PROJECT_CONTEXT.md`, `docs/REQUIREMENTS.md`, `docs/DATASETS.md`, and `docs/ARCHITECTURE.md` before making architecture decisions.
2. Keep MATLAB as the primary implementation language.
3. Do not introduce new frameworks without documenting the reason, cost, and fallback.
4. Do not invent dataset columns, labels, ground truth, or performance metrics. Inspect the actual data first.
5. Never leak raw sensitive identifiers into logs, screenshots, reports, or exported figures.
6. Every model result must be reproducible from a documented script and configuration.
7. Keep research code separate from App Designer presentation code.
8. Prefer small, testable functions over large scripts.
9. Use deterministic random seeds for experiments.
10. Document all non-obvious preprocessing decisions.

## Completion standard

A feature is not complete until it has:

- implementation,
- a minimal test or verification procedure,
- documentation,
- and an example/output that can be reproduced.

## Agent workflow

Before coding:

- inspect relevant files,
- identify assumptions,
- define inputs/outputs,
- confirm whether the change belongs to data, analysis, or UI layers.

After coding:

- run the smallest relevant test,
- inspect produced figures/tables,
- update `CHANGELOG.md` and task status where appropriate.
