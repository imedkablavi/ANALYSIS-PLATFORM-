# Architecture

## Layers

```text
DATA SOURCES
   ↓
INGESTION
   ↓
VALIDATION
   ↓
PREPROCESSING
   ↓
FEATURE ENGINEERING
   ↓
BEHAVIOR / EVENT MODEL
   ↓
┌──────────────┬───────────────┬──────────────┐
│ Temporal     │ Graph/Network │ Sequence     │
│ Analysis     │ Analysis      │ Analysis     │
└──────────────┴───────────────┴──────────────┘
                 ↓
          ANOMALY DETECTION
                 ↓
         PATTERN DISCOVERY
                 ↓
           EXPLAINABILITY
                 ↓
       MULTIMEDIA PRESENTATION
                 ↓
        MATLAB APP DESIGNER
```

## Data contracts

### Entity table

Minimum conceptual fields:

- `entity_id`
- `entity_type`
- optional dataset-specific attributes approved for use

### Event/interaction table

Minimum conceptual fields:

- `timestamp`
- `source_id`
- `target_id` or `location_id`
- `event_type`
- optional numeric value/weight

The actual schema is determined only after inspecting the selected dataset.

## Separation of concerns

- `src/data`: ingestion and data contracts
- `src/preprocessing`: validation and cleaning
- `src/features`: feature generation
- `src/behavior`: baseline profiles
- `src/temporal`: time-based analysis
- `src/spatial`: spatial analysis when data supports it
- `src/graph`: graph construction/metrics
- `src/sequence`: sequential pattern handling
- `src/anomaly`: anomaly models
- `src/pattern`: pattern mining
- `src/explainability`: evidence generation
- `src/evaluation`: metrics and experiment reports
- `app`: App Designer only

## Design principle

Analytical functions must be callable independently of the GUI so they can be tested and benchmarked without launching the app.
