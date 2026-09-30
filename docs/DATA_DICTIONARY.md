# Data Dictionary

Source fields are from the verified artifact (docs/DATASET_SCHEMA_INSPECTION.md). Derived tables
are produced by the functions named in each heading. Missingness refers to the verified artifact.

## Source fields

| JSON path | Type | Meaning | Missing | Used as |
|---|---|---|---|---|
| `directed`, `multigraph` | bool | graph flags (true, false) | 0 | validation only; graph modelled undirected (all links reciprocal) |
| `graph.name/description/version/id` | text | metadata | 0 | recorded in bundle meta |
| `nodes[].id` | text `OID#n` | anonymized offender pseudonym | 0 | `entity_id` |
| `nodes[].type` | text | always `offender` | 0 | `entity_type` |
| `nodes[].list_cid` | text[] | crime IDs of the offender | 0 | crime-ID restoration, V13 |
| `nodes[].crime_details.<CID>.date` | text `yyyy-MM-dd HH:mm:ss` | crime date (time always 00:00:00) | 0 | `event_time` |
| `...crime_details.<CID>.X`, `.Y` | double in [0,1] | min-max-scaled site coordinates | 0 | `x`, `y` (normalized only) |
| `...crime_details.<CID>.num_of_offenders` | int 1–13 | offenders in the crime (equals attached offenders) | 0 | `num_offenders` |
| `links[].source`, `.target` | text `OID#n` | endpoints (every link has its reverse) | 0 | validation; relations are rebuilt from events |
| `links[].weight` | double 1–37 | number of shared crimes | 0 | validation V52–V54 |
| `links[].type`, `.observed` | text / bool | always `relation` / true | 0 | validation V28/V29 |

## `events` (`flattenBurglaryEvents`, `canonicalEvents`, `encodeEventSequences`)

One row per (offender, crime); 34,156 rows.

| Column | Type | Definition |
|---|---|---|
| `entity_id`, `entity_index` | string, int | offender pseudonym and its row in the node table |
| `crime_id`, `crime_num` | string, double | restored original ID (`CID#n`) and n |
| `x`, `y` | double | normalized coordinates |
| `event_time` | datetime (unzoned, day) | parsed `date` |
| `num_offenders` | double | `num_of_offenders` |
| `id_restored` | logical | crime-details key matched to `list_cid` |
| `seq_pos` | double | 1-based position in the offender's history (date, then crime number) |
| `group_state` | "S"/"R"/"N" | solo / repeat partners only / at least one new partner (causal) |
| `step_distance` | double | distance to the offender's previous crime site (NaN for first) |
| `move` | "0"/"L"/"F"/"U" | first / local (≤ median step) / far / unknown |
| `token` | string | `group_state + move` |
| `surprisal_bits` | double | −log₂ P(token | previous token) |

## `crimes` (`buildCrimeTable`) — one row per crime (24,087)

`crime_id, crime_num, event_time, x, y, num_offenders, n_offenders_observed,
time_consistent, xy_consistent, num_consistent`.

## `relations` (`buildRelationTable`) — one row per offender pair (10,651)

| Column | Definition |
|---|---|
| `a_index < b_index`, `a_id`, `b_id` | endpoints |
| `weight` | number of shared crimes (equals file weight) |
| `first_time`, `last_time`, `span_days` | first / last shared crime date and their distance |

`pairEvents` (15,422 rows): `a_index, b_index, crime_id, event_time` — one row per shared crime.

## `entities` (bundle) — one row per offender (17,237)

All features in docs/FEATURE_ENGINEERING.md plus `component_id`, `entity_index`, `entity_type`,
`eligible` (≥ `min_events` crimes), `baseline_score/rank/flag`, `iforest_score/rank/flag`.
Scores are `NaN` for ineligible offenders.

## Temporal, spatial, dynamic and pattern tables

| Table | Columns |
|---|---|
| `temporal.series` | `bin_start, crimes, active_offenders, new_offenders, cooffending_share, mean_group_size` |
| `temporal.*_anomalies` | `value, baseline_median, baseline_scale, robust_z, is_high, is_low` |
| `temporal.change_points` | `index, mean_before, mean_after, cost_gain, bin_start` |
| `spatial.cells` | `cell_row, cell_col, x_center, y_center, crimes` |
| `spatial.spaceTime` | `cell_row, cell_col, year, crimes, expected, ratio, p_value, is_hotspot` |
| `dynamicGraph` | `window_start, window_end, active_offenders, edges, new_edges, persistent_edges, edge_persistence, edge_jaccard, components, largest_component, mean_degree` |
| `patterns.pairs` | relations with weight ≥ 2 |
| `patterns.groups` | `group_key` (sorted entity indices), `group_size, crimes, first_time, last_time` |
| `patterns.ngrams` | `ngram, occurrences, support, is_frequent` |
| `explanations.summary` | `entity_index, entity_id, iforest_*, baseline_*, dominant_group, evidence_text` |
| `explanations.evidence` | `entity_index, feature, label, group, value, reference_median, robust_z, baseline_share, occlusion_delta, notable` |

## Rules

- Every feature maps to source fields (registry column `source`).
- Derived fields have formulas in docs/FEATURE_ENGINEERING.md.
- Coordinates are never converted to real-world units.
