# Behaviour Model

## Profile

Each offender's profile is one row of `bundle.entities`:

```text
Entity (OID#n)
 ├─ Activity      event_count, active span, active days
 ├─ Temporal      gap median/CV, burstiness, dormancy ratio, busiest-30-day share, same-day share
 ├─ Spatial       radius of gyration, step distances, repeated sites   (normalized space)
 ├─ Co-offending  group size, solo share, repeat-partner share
 ├─ Network       degree, strength, strongest tie, clustering, k-core, component, betweenness, cut vertex
 └─ Sequence      mean/max transition surprisal, new-partner rate
```

## Baseline design (decision)

| Option | Decision | Reason |
|---|---|---|
| Static population baseline | **used** for entity anomaly scores | most offenders have 1–5 crimes; a per-entity baseline cannot be estimated for them |
| Per-entity rolling baseline | not used for scoring | ≥ 10 events would be needed; only a few hundred offenders qualify |
| Causal rolling baseline | **used** for system-level months | 80 monthly bins give enough history |
| Drift within an entity | captured indirectly | `max_gap_ratio` (dormancy → reactivation), `new_partner_rate`, sequence surprisal |

The reference population for the static baseline is every offender with ≥ 3 crimes (3,260).

## Output

Machine-readable profile table (`entity_features_scores.csv`), deviation profile per entity
(`entityEvidence`), and the "Deviation profile" tab / `fig_top_entity_evidence.png`.
