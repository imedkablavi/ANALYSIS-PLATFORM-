# Pattern Mining

| Pattern | Definition | Support measure | Function |
|---|---|---|---|
| Recurring pair | offender pair with ≥ 2 shared crimes | shared crimes; first/last date; span | `mineCooffendingPatterns` → `pairs` |
| Recurring group | the same exact set of ≥ 3 offenders in ≥ 2 crimes | number of crimes; first/last date | `mineCooffendingPatterns` → `groups` |
| Frequent / rare sequence | contiguous token trigram inside offender histories | occurrences; support = distinct offenders | `mineSequenceNgrams` |
| Emerging ties | ties whose first shared crime falls in a window | count per window | `computeDynamicGraphStats` (`new_edges`) |
| Space–time concentration | cell-year with Poisson excess | p-value, observed/expected | `computeSpatialHotspots` |
| Structural change | level shift in monthly activity | cost gain vs penalty | `detectChangePoints` |

Each pattern report states: definition, support/novelty measure, affected entities (indices, not
raw IDs, in shared reports), time interval, visualization (Patterns tab, timeline, map, network).

## Link to explainability

Sequence surprisal and new-partner rate are anomaly features, so an entity whose history contains
rare transitions shows them in its evidence; recurring pairs appear in the Partners tab with their
first/last dates.
