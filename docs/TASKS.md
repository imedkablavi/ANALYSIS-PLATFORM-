# Task Board

## Milestone M0 — Scope Freeze

### T-001 Exact assignment transcription
**Priority:** P0

Capture the professor's exact wording from the source sheet and store it in `docs/ASSIGNMENT_SOURCE.md`.

**Definition of done:** original wording, date, and source image reference are recorded.

### T-002 Confirm interpretation
**Priority:** P0

Map each phrase of the assignment to a project requirement.

**Definition of done:** no requirement is based only on an assumption.

---

## Milestone M1 — Dataset

### T-010 Acquire primary dataset
**Priority:** P0

Download the selected public research dataset and record source/license/version.

### T-011 Dataset card
**Priority:** P0

Create `data/DATASET_CARD.md` with schema, size, coverage, labels, identifiers, and privacy notes.

### T-012 MATLAB ingestion
**Priority:** P0

Implement a loader that returns normalized tables/graph structures.

### T-013 Data validation
**Priority:** P0

Create checks for missing, duplicate, malformed, and inconsistent records.

---

## Milestone M2 — Analytical Core

### T-020 Entity/event model
**Priority:** P0

Define stable internal representations for nodes, edges, and events.

### T-021 Temporal feature extraction
**Priority:** P0

Implement windowed activity, inter-event time, burstiness, and change features.

### T-022 Network feature extraction
**Priority:** P0

Implement degree/weight/centrality features justified by the dataset.

### T-023 Spatial features
**Priority:** P1

Implement only if location fields are meaningful.

### T-024 Sequence features
**Priority:** P1

Implement transparent n-gram/transition features.

---

## Milestone M3 — Detection

### T-030 Statistical baseline
**Priority:** P0

Implement a transparent anomaly score baseline.

### T-031 Isolation Forest
**Priority:** P0

Train and score with documented settings.

### T-032 Threshold strategy
**Priority:** P0

Define threshold selection using validation data or a documented reference procedure.

### T-033 Feature ablation
**Priority:** P1

Compare feature families.

### T-034 Explainability evidence
**Priority:** P0

Generate human-readable reason summaries linked to measurable deviations.

---

## Milestone M4 — Pattern Mining

### T-040 Frequent pattern analysis
**Priority:** P1

### T-041 Sequential pattern analysis
**Priority:** P1

### T-042 Dynamic graph change analysis
**Priority:** P1

---

## Milestone M5 — Multimedia Application

### T-050 App shell
**Priority:** P0

Create MATLAB App Designer application structure.

### T-051 Dashboard
**Priority:** P0

### T-052 Interactive graph
**Priority:** P0

### T-053 Timeline
**Priority:** P0

### T-054 Entity detail
**Priority:** P0

### T-055 Event replay
**Priority:** P1

### T-056 Heatmap
**Priority:** P1

### T-057 Optional audio cues
**Priority:** P2

---

## Milestone M6 — Evaluation & Delivery

### T-060 Evaluation scripts
**Priority:** P0

### T-061 Reproducibility run
**Priority:** P0

### T-062 Demo scenario
**Priority:** P0

### T-063 Technical report
**Priority:** P0

### T-064 Final presentation
**Priority:** P0

### T-065 Repository cleanup and release
**Priority:** P0
