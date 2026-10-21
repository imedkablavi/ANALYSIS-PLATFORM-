# Graph / Network Analysis

## Graph model (decision)

**Undirected, weighted.** The artifact declares `directed = true`, but all 21,302 links are
reciprocal with equal weights (validation V30/V31), i.e. 10,651 relations, and the weight equals
the number of shared crimes (V54). A digraph would double-count ties and duplicate features.
Relations are rebuilt from the events (`buildRelationTable`), which also gives each tie its first
and last shared date. Isolated offenders (7,597) stay in the graph as nodes of degree 0.

## Metrics (`computeGraphFeatures`)

| Metric | Why | Cost |
|---|---|---|
| degree, strength, strongest tie | co-offending breadth/intensity | O(m) |
| local clustering | closed triads = cohesive groups | sparse (A·A)∘A |
| k-core number | embeddedness in dense cores (max 12) | batch peeling, verified vs NetworkX |
| component size | group isolation vs membership in large structures (largest 518) | O(n+m) |
| betweenness (unweighted) | brokerage between otherwise separate offenders | Brandes, bounded by component sizes |
| articulation point | bridge-like position (1,156 nodes) | O(n+m) |

Not computed: closeness (ill-defined across 10,468 components), PageRank (on an undirected graph its
stationary distribution is proportional to strength without damping and close to it with damping,
so it adds little beyond `strength`), community detection (no
built-in MATLAB routine; components + k-core + cut vertices answer the structural questions for
components of ≤ 518 nodes).

## Dynamic graph

`computeDynamicGraphStats` (yearly) and `buildGraphSnapshot` (any window). Ties are active in a
window when a shared crime falls in it; new ties are first-ever shared crimes; persistence is the
share of last window's ties that are active again.

## Visualization

Ego network within 2 hops of the selected offender (capped at 400 nodes), node colour = anomaly
score, size = crimes, edge width = shared crimes; ties appear as the playback cursor passes their
first shared crime. Clicking a node selects that offender in every view.

## Interpretation

See docs/ETHICS_AND_LIMITATIONS.md §4: centrality reflects co-offending **recorded in solved
cases** and is sensitive to missing data (Sparrow 1991). Never describe it as leadership.
