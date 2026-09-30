# Data Dictionary Template

This file is intentionally a template until the primary dataset is inspected.

## Entity fields

| Field | Type | Meaning | Source | Missingness | Allowed use |
|---|---|---|---|---|---|
| entity_id | string | Anonymized entity identifier | dataset | TBD | yes |
| entity_type | categorical | Entity category | derived/source | TBD | yes |

## Event/relationship fields

| Field | Type | Meaning | Source | Missingness | Derived? |
|---|---|---|---|---|---|
| timestamp | datetime | Event time | dataset | TBD | no |
| source_id | string | Source entity | dataset | TBD | no |
| target_id | string | Target entity | dataset | TBD | no |
| weight | numeric | Interaction/edge weight | source/derived | TBD | TBD |

## Rules

- Do not finalize this table by guessing.
- Every production feature must map to one or more source fields.
- Any derived field must have a formula documented in `FEATURE_ENGINEERING.md`.
