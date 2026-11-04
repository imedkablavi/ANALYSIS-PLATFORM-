# Network Behaviour Explorer — Technical Report

Date: 2026-10-31. Implementation: MATLAB. Application domain: offline
computer-network traffic analysis.

## Purpose

The system supports investigation of unusual host behaviour by linking
measurable host features, reference deviations, network context and source
flow observations. It compares a transparent statistical score with Isolation
Forest and evaluates the rankings against independently supplied labels.
The research question is whether combined traffic, temporal and network
features provide useful rankings and inspectable explanations for the chosen
capture. A ranking is not a calibrated probability of compromise.

## Source data

The primary case study is the complete CTU-13 scenario 7 bidirectional-flow
file, published by Stratosphere Laboratory at the Czech Technical University.
The official project describes captured botnet traffic mixed with normal and
background traffic. This is a historical controlled-capture benchmark, not a
claim of deployment in a current production network.

- [Official dataset description](https://www.stratosphereips.org/datasets-ctu13/).
- [Authoritative scenario directory](https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/).
- File: `capture20110816-2.binetflow`.
- Size: 15,630,512 bytes; full file, no row subsampling.
- Git blob: `33065bb8bc1df911fae818e3475ee0cf96d0e0a9`.
- SHA-256: `df0b5338190b967bd340a0d6c1bb3c34d1bbfb4b7ffa764c2dd26f77f1a26680`.
- Source-clock interval: 2011-08-16 13:51:24.049047–14:12:41.499668.

The independent streaming audit produced the following source facts:

| Population | Malicious | Benign | Unknown | Total |
|---|---:|---:|---:|---:|
| Flows | 63 | 1,677 | 112,337 | 114,077 |
| Hosts | 1 | 6 | 38,197 | 38,204 |
| Hosts with at least three incident flows | 1 | 6 | 2,449 | 2,456 |

No rows have missing endpoints or unparseable/missing timestamps. The audit
checks source structure and mapping; it does not execute a detector. The
receipt, acquisition commands and sample limitations are documented in
[REAL_CAPTURE_EVIDENCE.md](../REAL_CAPTURE_EVIDENCE.md).

## Data representation

Each flow is an event involving its source and destination; a self-flow has
one participant. Imported host identifiers are pseudonymized by default.
The source observation table retains time, duration, protocol, ports, packets
and bytes, with integer endpoint indices rather than raw addresses. A separate
label table determines host truth: a malicious-labelled record overrides
benign-labelled records; otherwise a host with benign evidence is benign;
without either it remains unknown. Direction-specific CTU labels identify
the endpoint to which the label applies.

CTU-13, CIC-IDS2017, UNSW-NB15 and LANL have explicit import profiles. Generic
event CSV and temporal edge-list layouts share the canonical entity/event
contract. Accepting a tabular layout does not establish that the chosen
features have scientific meaning for every possible domain.

## Analytical method

1. Inspect the format, map columns and normalize source records.
2. Validate identifiers, dates, participant consistency and numeric ranges.
3. Construct event tables and weighted host relationships.
4. Derive activity, timing, topology, partner recurrence and traffic features.
   Features unavailable or constant in the reference population are excluded
   and reported; unavailable data are not presented as measured zero.
5. For eligible hosts, transform skewed count features and fit robust reference
   centres/scales without reading attack labels.
6. Compute baseline RMS deviation and a seeded Isolation Forest ranking on
   the same retained feature matrix.
7. Allocate a documented review budget rather than presenting a guessed risk
   probability. Explain measured deviations and, when computed, feature
   occlusion effects.
8. Join published labels after scoring and generate evaluation artifacts.

Configuration is stored with the analysis bundle. The import fingerprint
includes source content, selection options, mappings and label-file content.
Source and experiment fingerprints are retained by the delivery verifier.

Time bins adapt to capture duration. Descriptive full-run host scores remain
separate from replay-window observations. The methodology is transductive
ranking of the analysed population; it does not establish prospective attack
detection. Derived sequence states are conventions, not source protocol labels.

## Computational bounds

Graph calculations report skipped features explicitly. Clustering is bounded
by the squared-degree work estimate. Betweenness has both a largest-component
node limit and a component node-edge work limit. The actual case study has a
largest component of 37,977 nodes and a work proxy of 1,582,160,303, exceeding
the default 200,000,000 betweenness budget. This is an estimated traversal
budget, not an experimentally measured MATLAB runtime.

## Investigation interface

The application links host ranking, network neighbourhood, timeline, measured
feature evidence, label evaluation and data quality. Provenance presents the
source fingerprint, selected records and run parameters. Host observations
show real imported flow metadata with explicit row limits and totals.

Export retains figures, feature evidence CSV, flow CSV and a JSON investigation
manifest. It distinguishes full-run scores from the half-open replay interval
and uses bundle-local host pseudonyms. A displayed flow supports inspection;
it is not asserted to have caused an aggregate host score.

## Evaluation protocol

E11 compares feature sets and both detectors using ROC-AUC, average precision,
chance AP and precision/recall at the documented review size. Equal-score
observations are grouped at score thresholds for AP. Unknown-labelled hosts
are excluded in known-only evaluation; counting unknowns as negatives is a
separate explicitly named sensitivity setting. Malicious hosts excluded by
eligibility must be reported.

Synthetic feature perturbations test score sensitivity and are labelled
synthetic; they do not replace real-label evaluation or establish that event
extraction detects an attack. Stability, ablation and configuration sensitivity
are reported separately from interface usability.

Only seven eligible hosts have known labels in this scenario. Multiple complete
scenarios and a predeclared selection procedure are necessary for stronger
conclusions. Label-based selection or tuning must be disclosed.

## Verification evidence and scope

The local streaming audit and its automated regression tests have executed.
MISS_HIT checks MATLAB parsing; it does not execute MATLAB functions or app
callbacks. An earlier MATLAB Online run is recorded in CHANGELOG, but cannot
validate subsequent changes. Current MATLAB detector metrics and GUI acceptance
have not been established in this environment, so this report makes no claim
about detector accuracy or completed deployment.

`verify_delivery` writes actual test outcomes, configuration, artifact hashes
and failures. A quick run or skipped tests receives a partial status. Full
model evaluation requires both known classes among eligible hosts and a fitted
Isolation Forest model with finite scores. Interactive checks include loading,
selection, language/dataset switching, replay and export.

## Conclusion

The repository contains an implemented offline analysis and investigation
workflow with documented authentic input data and reproducible evidence
collection. The source audit supports the data facts above. Model-performance
and user-interface claims require execution evidence from the target MATLAB
installation and are not inferred from code presence or static checks.

## References

- Garcia, S., Grill, M., Stiborek, J., and Zunino, A. (2014). An empirical
  comparison of botnet detection methods. Computers & Security 45, 100–123.
  https://doi.org/10.1016/j.cose.2014.05.011
- [Dataset protocol and units](../NETWORK_DATASETS.md).
- [Feature definitions](../FEATURE_ENGINEERING.md).
- [Related mature systems and scope](../RELATED_SYSTEMS_AND_DELIVERY.md).
- [Experiments](../EXPERIMENTS.md) and [evaluation](../EVALUATION.md).
