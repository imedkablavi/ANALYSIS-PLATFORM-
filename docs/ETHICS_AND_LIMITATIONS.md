# Ethics, Privacy and Limitations

## 1. What the system is — and is not

It is an **analysis and visualization system** for statistical deviations in an anonymized research
dataset. It is not a law-enforcement decision engine, not a risk-assessment instrument and not a
predictor of offending.

| Allowed wording | Not allowed |
|---|---|
| anomaly, behavioural deviation, unusual pattern | "criminal", "guilty", "dangerous" |
| "deviates by +5.2 robust SD from the reference median" | "proves", "identifies the perpetrator" |
| "insufficient history" | treating unscored entities as "normal" |

The generated evidence text always ends with: *"a statistical deviation from the reference
population …; it is not evidence of guilt, intent or dangerousness."* A test
(`test_pipeline_fixture/testNoRawIdsInExplanationText`) guards this.

## 2. Anomaly ≠ wrongdoing

Every record in the dataset is already a solved burglary case. An anomaly score therefore says
nothing about whether an offence happened; it only says that an offender's **recorded pattern**
(timing, spatial spread, co-offending structure, event order) is unusual *relative to the other
recorded offenders with ≥ 3 cases*. Unusual can reflect data-collection artefacts (e.g. date
heaping, cases solved in batches, recording practices) as much as behaviour.

## 3. False positives and uncertainty

- There is no ground truth, so real false-positive rates are **unknown**. Synthetic-injection
  results (E5–E7) measure sensitivity to constructed deviations only.
- The review budget (top 1 %) guarantees that *some* entities are flagged even if nothing is truly
  unusual. Flags are prompts for inspection, not findings.
- Detector disagreement (E3, E8) is reported, not hidden; entities flagged by only one detector
  deserve extra caution.

## 4. Network-centrality caveats

Criminal-network data are incomplete, have fuzzy boundaries and change over time (Sparrow 1991).
Here, in addition, the graph contains only co-offending **recorded in solved cases**:

- high degree or betweenness can mean "appears in many solved cases with others", which depends
  on police attention and solving rates, not on a structural role;
- a missing edge may be an unsolved joint offence;
- articulation points and betweenness are highly sensitive to single missing edges in small
  components (largest component: 518 offenders);
- graph and co-offending features are both derived from the same shared-crime counts (the link
  weight equals the number of shared crimes), so they are not independent corroboration.

Centrality must never be described as "leadership" or "importance" in the report or the demo.

## 5. Privacy and anonymization

- Identifiers are the provider's pseudonyms (`OID#n`, `CID#n`); coordinates are provider min-max
  scaled "to prevent precise retrieval of the localization of the site" (upstream documentation).
- The project **never** attempts re-identification, never joins external data, never de-normalizes
  coordinates (`cfg.privacy.denormalize_coordinates = false`) and draws no basemap.
- The spatial view is labelled "normalized"; relative positions only.
- Reports, validation files and evidence text contain aggregates or pseudonymous IDs only; the
  validation Markdown is tested to contain no `OID#`.
- Raw data are not committed (`.gitignore`), although the upstream BSD-3-style licence would
  permit redistribution; this is the conservative choice for sensitive-domain data.
- Screenshots for the report should use the figure scripts (no identifier labels on the graph).

## 6. Methodological limitations

| Limitation | Consequence | Mitigation / status |
|---|---|---|
| Day-resolution dates | no time-of-day analysis; same-day order is a convention | documented; order = numeric crime ID |
| Solved cases only, right-censored at the end | recent declines are artefacts | series ends 2020-08 |
| Sparse pre-2014 data | no reliable baseline before 2014 | excluded from system series (V45) |
| 66 % of offenders have one case | most offenders cannot be profiled | eligibility ≥ 3 crimes, explicit "insufficient history" |
| No seasonal term in the rolling baseline | July peaks may be flagged | open task T-043 (seasonal baseline) |
| Normalized coordinates of unknown extent | distances are relative, not metres | never interpreted as distances |
| Derived event alphabet | sequences describe partner novelty and movement, not crime type | stated wherever sequences are shown |
| Transductive scoring (fit and score on the same population) | scores are relative to this dataset | stated; temporal hold-out is future work |
| No labels | no accuracy claims possible | synthetic injection + stability, clearly labelled |

## 7. Responsible demo rules

1. Say "unusual record pattern", not "suspect".
2. Show the evidence tab whenever showing a score.
3. Mention the eligibility rule and the review budget.
4. Do not show raw identifiers on slides; the app shows pseudonyms only for navigation.
