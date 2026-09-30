# Research Log

One entry per meaningful research decision. Template at the end.

### 2026-09-30 — Is the offender network independent of the crime records?
- **Sources**: artifact (blob `3afe9cbb…`), `scripts/reference/audit_dataset_reference.py`.
- **Finding**: all 21,302 links are reciprocal with equal weights; weight = shared crimes for every
  link; every co-offending pair is linked; `num_of_offenders` = attached offenders for every crime.
- **Decision impact**: undirected graph; relations rebuilt from events with timestamps (dynamic
  graph, replay); in/out-degree features removed; graph and co-offending features documented as
  non-independent in ablations.
- **Confidence**: verified exhaustively on the artifact; MATLAB regression test pending.

### 2026-09-30 — Why do crime IDs differ from `list_cid` in MATLAB?
- **Sources**: MATLAB `jsondecode` documentation (makeValidName conversion).
- **Finding**: keys like `CID#2` become struct fields `CID_2`.
- **Decision impact**: IDs restored via `makeValidName(list_cid)`; `id_restored` flag and check V40.
- **Confidence**: documented behaviour; fixture test written; not executed (no MATLAB).

### 2026-09-30 — Which period supports temporal baselines?
- **Finding**: 91 rows before 2014; 2020-09 half a normal month; solved cases → right-censoring.
- **Decision impact**: system series 2014-01 … 2020-08.
- **Confidence**: high for coverage; the size of the censoring effect is unknown.

### 2026-09-30 — Is a 12-month causal median adequate?
- **Finding** (Python port, reference only): flags 2016-07 and 2019-07; July is the busiest month.
- **Decision impact**: limitation documented; seasonal baseline opened as T-043.
- **Confidence**: medium; needs the MATLAB run and a seasonal comparison.

### 2026-09-30 — How to threshold without labels?
- **Sources**: Iglewicz & Hoaglin (1993); Campos et al. (2016).
- **Decision**: per-feature evidence at |z| ≥ 3.5; entity flags by an explicit review budget (1 %),
  varied in E8. No "risk" wording.

### 2026-09-30 — How to evaluate without ground truth?
- **Sources**: Emmott et al. (2013); Campos et al. (2016).
- **Decision**: synthetic injection per feature group (labelled SYNTHETIC), ablation, stability;
  human usability study for the app.

### 2026-09-30 — Which second anomaly model?
- **Decision**: none beyond the robust baseline + Isolation Forest. LOF/OCSVM/RRCF have no
  evaluation signal to justify them here (docs/ANOMALY_DETECTION.md).

### 2026-09-30 — Sequence alphabet without event types
- **Decision**: partner state (S/R/N, causal) × move (0/L/F/U, median-step split); observed token
  distribution recorded in docs/SEQUENCE_ANALYSIS.md.

---

## Template

### YYYY-MM-DD — Question
- **Sources**:
- **Finding**:
- **Decision impact**:
- **Confidence / limitation**:
