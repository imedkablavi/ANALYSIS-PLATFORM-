# Network Behavioral Analysis & Suspicious Pattern Detection

**MATLAB-first university research project for Çoklu Ortam**

## Project Overview

This repository implements the professor's assigned network/behavior analysis topic at a deeper technical level without replacing the original topic.

The system is designed around **real, documented, anonymized research data**. It builds observable behavioral profiles, analyzes changes over time, models relationships as graphs, discovers repeated/sequential patterns, detects deviations from a reference baseline, produces explainable evidence, and communicates the results through an interactive MATLAB App Designer application.

> **Important:** An anomaly score describes deviation from an analytical baseline. It is not a determination that a real person is criminal.

## Core Research Pipeline

```text
Real Dataset
    ↓
Data Ingestion & Validation
    ↓
Preprocessing
    ↓
Entity / Event Representation
    ↓
Feature Engineering
    ↓
Behavioral Profiles
    ↓
┌──────────────┬──────────────┬──────────────┐
│ Temporal     │ Graph        │ Sequence     │
│ Analysis     │ Analysis     │ Analysis     │
└──────────────┴──────────────┴──────────────┘
                    ↓
            Anomaly Detection
                    ↓
             Pattern Mining
                    ↓
              Explainability
                    ↓
         Interactive Multimedia UI
                    ↓
              Evaluation
```

## Why the project is deeper than a simple visualization

A static network graph shows structure. This project additionally asks:

- What is the reference/normal behavior?
- How does that behavior change over time?
- Which interactions or structural changes are unusual?
- Which event sequences repeat or become novel?
- Which network features contribute to the anomaly signal?
- Can the user inspect the evidence behind an alert?
- Can the same event be replayed through synchronized timeline/network views?

## Primary Technology Stack

### MATLAB — primary language and application platform

Used for:

- data processing,
- feature engineering,
- statistical analysis,
- machine learning,
- anomaly detection,
- graph/network analysis,
- visualization,
- multimedia processing where needed,
- evaluation,
- MATLAB App Designer.

### MATLAB Toolboxes

Required/conditional according to the selected dataset:

- MATLAB
- MATLAB App Designer
- Statistics and Machine Learning Toolbox
- Computer Vision Toolbox — only if justified
- Image Processing Toolbox — only if justified
- Signal Processing Toolbox — only if justified
- Audio Toolbox — only if justified
- Parallel Computing Toolbox — only if needed

### Python — secondary utility only

Python may be used for a narrowly justified dataset conversion, specialized preprocessing step, model conversion/export, or reference verification.

Python is **not** the main application stack.

## Primary Dataset Candidate

The first candidate is the public **Criminal Network Analysis and Visualization** dataset repository:

https://github.com/erichoang/criminal-network-visualization

Its documentation describes anonymized burglary-related data, including network-ready offender/crime representations and temporal/spatial information.

Dataset acquisition is documented in:

- `docs/DATASETS.md`
- `docs/DATASET_ACQUISITION.md`
- `data/DATASET_CARD.md`

**Do not commit raw data before verifying the applicable terms.**

## Multimedia Application

The final MATLAB application is expected to include:

- Dashboard
- Interactive network graph
- Timeline
- Anomaly/event highlighting
- Entity detail
- Behavioral profile
- Heatmap/spatial view when supported
- Event replay
- Pattern view
- Exportable analytical summary

The multimedia layer is an analytical interface, not decoration.

## Planned Repository Structure

```text
.
├── README.md
├── PROJECT_CONTEXT.md
├── AGENTS.md
├── CHANGELOG.md
├── LICENSE.txt
├── data/
│   ├── DATASET_CARD.md
│   ├── raw/
│   ├── processed/
│   └── samples/
├── docs/
│   ├── PROJECT_BRIEF.md
│   ├── ASSIGNMENT_SOURCE.md
│   ├── REQUIREMENTS.md
│   ├── ARCHITECTURE.md
│   ├── DATASETS.md
│   ├── DATASET_ACQUISITION.md
│   ├── DATA_DICTIONARY.md
│   ├── FEATURE_ENGINEERING.md
│   ├── BEHAVIOR_MODEL.md
│   ├── TEMPORAL_ANALYSIS.md
│   ├── SPATIAL_ANALYSIS.md
│   ├── GRAPH_ANALYSIS.md
│   ├── SEQUENCE_ANALYSIS.md
│   ├── ANOMALY_DETECTION.md
│   ├── PATTERN_MINING.md
│   ├── EXPLAINABILITY.md
│   ├── MULTIMEDIA_DESIGN.md
│   ├── MATLAB_STACK.md
│   ├── PYTHON_POLICY.md
│   ├── EXPERIMENTS.md
│   ├── EVALUATION.md
│   ├── 30_DAY_ROADMAP.md
│   ├── TASKS.md
│   ├── MILESTONES.md
│   ├── DEFINITION_OF_DONE.md
│   ├── DEMO_SCENARIO.md
│   ├── GITHUB_WORKFLOW.md
│   ├── ISSUE_TEMPLATE.md
│   ├── AGENT_EXECUTION_PROMPT.md
│   ├── RESEARCH_LOG.md
│   ├── SOURCE_INDEX.md
│   ├── RISKS.md
│   └── TURKISH_PROJECT_PROPOSAL.md
├── models/
├── outputs/
├── src/
└── app/
```

## 30-Day Delivery Strategy

### Days 1–7
Scope freeze, dataset verification, ingestion, validation, preprocessing.

### Days 8–16
Feature engineering, behavior profiles, temporal/network/sequence analysis, statistical baseline.

### Days 17–20
Isolation Forest or another justified anomaly detector, threshold protocol, ablation and explainability.

### Days 21–27
MATLAB App Designer, dashboard, graph view, timeline, replay, heatmap if supported, usability refinement.

### Days 28–30
Reproducibility run, evaluation, report, presentation, demo, repository cleanup and release.

## Project Status

Current status: **Foundation / Scope & Data Planning**

No model performance is claimed until the real dataset is inspected and experiments are executed.

## First Gate

Before implementing the analytical core:

1. Record the exact professor assignment wording in `docs/ASSIGNMENT_SOURCE.md`.
2. Acquire the primary dataset.
3. Verify its terms and version.
4. Inspect the real schema in MATLAB.
5. Complete `data/DATASET_CARD.md`.
6. Implement the first reproducible ingestion/validation pipeline.

See `docs/TASKS.md` for the task board.
