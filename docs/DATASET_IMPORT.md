# Importing External Datasets

The application imports supported network-flow layouts, event-participation
CSV/TSV/TXT tables, temporal edge lists and the documented secondary NetworkX
schema. Event records require an entity and timestamp; edge records require
source, destination and timestamp. Unknown columns can be mapped manually.
A compatible layout does not guarantee that every feature is meaningful for
the source domain. Arbitrary JSON and spreadsheet/packet formats are not
supported by this importer.

Verification status for the current source is recorded in [TASKS.md](TASKS.md).

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
| `network_flow` | a known network-traffic layout: CTU-13, CIC-IDS2017, UNSW-NB15, LANL | detected automatically | `labels_file`, `max_rows`, `profile` | **see docs/NETWORK_DATASETS.md** |
| `networkx_burglary_json` | the primary artifact's schema | — | — | primary dataset |

Delimiters are detected automatically (comma, semicolon, tab, space); leading lines starting
with `#` (SNAP comment header) are skipped, while a `#` inside a value (e.g. `OID#12`) is kept;
identifier columns are always read as text, so long numeric IDs never lose precision; headerless files with ≥ 3 columns are read as source, target, time. Column names
are matched case-insensitively against common names (e.g. `person/user/actor`,
`event_id/case_id/incident_id`, `timestamp/date/time`, `lat/latitude`, `lon/longitude`); when
a required column is not detected the app asks for it (or pass `opts.mapping`).

Time columns may be datetimes, text dates (format inferred, then common formats tried) or
numbers: integers 19000101–21001231 → `yyyymmdd`; ≥ 1e6 → POSIX seconds; > 1e11 → POSIX
milliseconds; smaller values are ambiguous and raise `MOSAIC:AmbiguousTimeUnit` unless
`time_unit` is set (`posix_s`, `posix_ms`, `excel`, `datenum`, `yyyymmdd`). Unparseable times become NaT and are counted by validation (V43).

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

Bins: month (span ≥ 24 months), week (≥ 26 weeks), day (≥ 30 days), hour (≥ 24 h), otherwise
minute. The paragraph below describes the month/week case.

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

## Custom network-flow tables

Use `format="network_flow"`, `profile="generic_network_flow"` and map `src`,
`dst`, `time` (aliases `source`/`target` are accepted). Optional fields are
`duration` in seconds, `bytes`, `packets`, `sport`, `dport`, `proto`. Custom
labels remain unknown; a column name alone does not establish attack semantics.
Known profiles keep their unit/label rules. Explicit timestamp units and
`time_formats` are forwarded through the pipeline. `first_row`/`max_rows` apply
to flow records only; event/edge imports reject effective slicing rather than
silently ignoring it. Unsupported binary/compressed formats require conversion.

The app's import dialog permits changing the detected layout and column
mapping. [Turkish instructions](YENI_VERI_SETI.md). New contracts are covered
by `test_external_network_import`, `test_dataset_reuse_pipeline` and
`test_import_dialog_options`; current MATLAB execution remains pending.
