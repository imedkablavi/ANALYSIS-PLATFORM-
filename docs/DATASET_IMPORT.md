# Importing External Datasets

The platform is not tied to the primary burglary artifact. Any dataset that records **who
took part in which event and when** can be analysed with the full pipeline (validation,
behavioural features, graph, temporal/spatial/sequence analysis, anomaly detection,
explanations, multimedia app).

> Status: implemented and unit-tested on fixtures; **not yet executed in MATLAB** (same gate
> as the rest of the code, docs/REPRODUCIBILITY.md §4).

## How to use

| Way | Steps |
|---|---|
| App | "Open dataset…" → choose the file → confirm/choose columns → progress dialog → the dataset opens and is added to the dataset list |
| Script | set `FILE` (and `MAPPING` if needed) in `scripts/analyze_dataset.m`, run it |
| Code | `bundle = analyzeDataset(path, struct('mapping', m, 'name', "My data"))` |

Results go to `outputs/datasets/<dataset_id>/` (bundle, validation report, tables), and
`outputs/datasets/catalog.json` lists every analysed dataset (`listDatasets`). Both are
git-ignored. `dataset_id` = name slug + first 8 hex digits of the file's Git blob SHA, so
re-analysing the same file replaces its entry instead of duplicating it.

## Supported formats (`inspectDatasetFile` detects them)

| Format | Layout | Required | Optional | Typical sources |
|---|---|---|---|---|
| `event_csv` | one row per (entity, event) participation | entity, time | event id (missing → one event per row), x/lon, y/lat | incident/case logs, co-authorship, check-ins |
| `edge_csv` | one row per interaction between two entities | source, target, time | weight (ignored, see below) | SNAP temporal networks (`src dst unixtime`), message/e-mail logs |
| `networkx_burglary_json` | the primary artifact's schema | — | — | primary dataset |

Delimiters are detected automatically (comma, semicolon, tab, space); lines starting with `#`
are ignored; headerless files with ≥ 3 columns are read as source, target, time. Column names
are matched case-insensitively against common names (e.g. `person/user/actor`,
`event_id/case_id/incident_id`, `timestamp/date/time`, `lat/latitude`, `lon/longitude`); when
a required column is not detected the app asks for it (or pass `opts.mapping`).

Time columns may be datetimes, text dates (format inferred, then common formats tried) or
numbers (POSIX seconds; > 1e11 → milliseconds; `time_unit` can force `posix_s`, `posix_ms`,
`excel`, `datenum`). Unparseable times become NaT and are counted by validation (V43).

## What happens on import (all recorded in `bundle.meta.dataset.import_notes`)

| Step | Rule | Why |
|---|---|---|
| Pseudonymization | entity and event IDs → `ENT000001…`, `EV0000001…` in order of first appearance (default on; `pseudonymize=false` to keep) | external data may contain real identifiers; AGENTS.md rule 5 |
| ID map | not stored unless `keep_id_map=true`; then only in `outputs/datasets/<id>/entity_id_map.csv` (git-ignored), never in the bundle or reports | re-identification stays a deliberate local action |
| Coordinates | min-max scaled to [0,1] over the dataset | same privacy-preserving representation as the primary artifact; distances become relative |
| Rows without entity | dropped and counted | cannot be attributed |
| Edge lists | each row = one event with two participants; self-interactions keep one participant; a weight column is ignored | tie strength = number of shared events, exactly as in the primary network |
| Group size | `num_offenders` = distinct entities sharing the event | consistent with the primary artifact (verified there) |
| Relations | derived from shared events (`buildRelationTable`) | link-related validation checks are reported "not applicable" |

## Automatic configuration (`configureForDataset`)

The primary artifact keeps its documented configuration. For other datasets the windows are
derived from the data: monthly series from the first to the last month (last, partial month
excluded); **weekly** bins when the span is < 24 months; the seasonal same-month baseline only
with ≥ 4 calendar years (it needs 3 prior years), otherwise the rolling baseline; yearly
dynamic-graph windows over the covered years; plausible-date bounds 1900 → end of this year.
Every adaptation is listed in `bundle.meta.config_notes`. Feature, anomaly and evaluation
settings are unchanged, so results stay comparable.

## Datasets without coordinates

Spatial features become undefined (`NaN`) and are dropped as constant by
`prepareFeatureMatrix`; spatial validation checks are "not applicable"; the app shows a
message instead of the map. The other analyses are unaffected.

## Candidate public datasets to try (verify licence/terms before use)

| Dataset | Format | Note |
|---|---|---|
| SNAP `CollegeMsg` (temporal network) | `edge_csv` headerless `src dst unixtime` | ~193 days → weekly bins |
| SNAP `email-Eu-core-temporal` | `edge_csv` headerless | ~800 days |
| Upstream `israel_lea_inp_burglary_v2_crime_id_network.json` | not supported as is | crime-crime projection; needs an adapter |

## Limits

- Only the three layouts above; other JSON graph formats must be exported to CSV first.
- Each edge-list row is treated as a separate event; repeated identical rows are separate
  interactions.
- Very large files (≫ 1 M rows) are read into memory in one piece.
- The interpretation rules of docs/ETHICS_AND_LIMITATIONS.md apply to every dataset: scores are
  deviations within that dataset, never statements about people.
