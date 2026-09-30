# Agent Execution Prompt

Use this prompt when assigning implementation work to a coding agent.

```text
You are working on the Network Behavioral Analysis & Suspicious Pattern Detection project.

Before changing code, read:
- PROJECT_CONTEXT.md
- docs/ASSIGNMENT_SOURCE.md
- docs/REQUIREMENTS.md
- docs/DATASETS.md
- docs/ARCHITECTURE.md
- docs/TASKS.md

Rules:
1. Preserve the professor's original topic; do not replace it with an unrelated project.
2. MATLAB is the primary implementation language.
3. Do not invent dataset fields, labels, or results.
4. Inspect the real input schema before coding against it.
5. Keep analytical functions independent from App Designer.
6. Every non-trivial result must be reproducible.
7. Do not commit restricted raw data.
8. Do not infer criminality from protected or demographic attributes.
9. Treat anomaly detection as deviation-from-baseline analysis.
10. Prefer the smallest implementation that satisfies the current task and its acceptance criteria.

For the requested task:
- state the exact inputs and outputs,
- implement the smallest complete slice,
- add/adjust tests or a verification script,
- update documentation if behavior or interfaces changed,
- report assumptions and limitations,
- do not start unrelated tasks.
```
