# Python Policy

Python is optional and secondary.

## Allowed uses

- one-off dataset conversion,
- specialized preprocessing,
- model conversion/export,
- verification against a reference implementation.

## Current use (only one)

`scripts/reference/audit_dataset_reference.py` — **verification only**. It independently
re-computes the dataset facts in docs/DATASET_SCHEMA_INSPECTION.md and the expected values of
`tests/test_real_dataset.m`, including a cross-check of the k-core, clustering, component and
articulation-point logic against NetworkX.

- Dependencies: standard library; `--graph` needs `numpy` and `networkx` (justification: an
  independent, widely used graph implementation to compare against).
- Fallback: without Python, the same values are checked by the MATLAB regression test once MATLAB
  is available.
- It produces no analysis results and nothing in MATLAB reads its output.

## Not allowed without explicit decision

- replacing MATLAB as the application core,
- building a separate web backend,
- building a second GUI stack,
- duplicating the entire analytical pipeline in two languages.
