# Related systems and evidence-driven delivery

Research date: 2026-10-31. These are references for design and methodology,
not dependencies, copied implementations, or claims of equivalent capability.

## Positioning

A MATLAB investigation workspace for offline network-flow anomaly analysis:
source capture → validated records → host features → descriptive anomaly
ranking → measurable reasons → supporting observations → benchmark evaluation.
A flow being displayed next to an unusual host does not establish that this
specific flow caused its score. Published labels remain evaluation-only.

## Comparison with primary sources

| Reference | Verified relevant capability | Adaptation here | Boundary |
|---|---|---|---|
| [Slips, Stratosphere](https://github.com/stratosphereips/StratosphereLinuxIPS) | Behavioral network analysis with evidence and alerts | Quantitative feature reasons and supporting host observations | Our MATLAB app is an offline research system; no live blocking/IPS claim |
| [Malcolm analytics](https://malcolm.fyi/docs/analytics.html) | Linked network analytics and investigation views | Shared dataset provenance and explicit temporal scope | No Elasticsearch/OpenSearch or new web stack needed |
| [Arkime](https://arkime.com/index) | Session investigation, temporal exploration and packet drill-down | Chronological host-flow table: protocol, ports, duration, packets, bytes | Imported NetFlow summaries cannot show packet payloads or prove a packet-level attack |
| [Zeek connection logs](https://docs.zeek.org/en/master/reference/logs/conn.html) | Defined connection fields and documented units | Explicit observed fields and units; unavailable stays unavailable | Zeek import is future work, not currently implemented |
| [CTU-13](https://www.stratosphereips.org/datasets-ctu13/) | Thirteen botnet captures with normal/background traffic and flow labels | Primary benchmark with known-only evaluation and separately reported unknowns | Real captured malware activity is not the same as arbitrary operational deployment; historical benchmark generalization is limited |
| [CIC-IDS2017](https://www.unb.ca/cic/datasets/ids-2017.html) | Labelled flows from a generated traffic/attack scenario | Secondary external evaluation after CTU-13 | Do not describe generated benchmark traffic as naturally occurring enterprise production traffic |

## Changes implemented from this comparison

- Preserve the imported privacy-safe flow table in newly generated bundles;
  show chronological, bounded supporting observations for the selected host.
- Expose dataset/run provenance separately from detection results, including
  the data fingerprint, configuration/version context and label coverage.
- Keep full-run scores distinct from replayed observations; showing a time
  cursor does not mean the host model was retrained at that cursor.
- Retain verification logs, test results, configuration and E11 outputs via
  `scripts/verify_delivery.m`. Earlier recorded MATLAB test results do not
  validate later code changes.

New flow records need a regenerated bundle. Old bundles retain their event
view. The retained table increases saved bundle size; use documented slices
for large captures and report the exact slice. Views are capped; counts must
make truncation visible. No GUI screenshot has been generated in this
review because MATLAB is unavailable locally.

## What the professor should be able to verify

1. Open the official source and identify the exact capture/scenario. Record
   the immutable source revision, file hash, terms, original vs sampled size,
   selected row range, time interval and published label mapping.
2. Run the pipeline from the checked-out source and retain the MATLAB
   version, configuration, random seed, test outcomes and generated artifacts.
3. Select a host; see actual observed feature values next to the reference
   median/scale and both model scores. Missing results must say unavailable.
4. Inspect supporting flows with time, direction, protocol, ports and units;
   no fabricated locations or invented packet contents for flow-only data.
5. Compare the ranking with published labels after scoring. Show malicious,
   benign, unknown and ineligible counts, AP, ROC-AUC and chance AP together.
   No positive class means no valid detection-performance experiment.
6. Compare baseline vs Isolation Forest and network-only vs combined feature
   groups on the SAME capture/protocol. Use E11 outputs, never typed metrics.
7. Replay the chosen time interval, export evidence, and explain limitations
   without calling an anomaly score a probability of maliciousness.

## Visual acceptance

Use the current MATLAB component stack. Improve hierarchy through one clear
investigation path: dataset → host ranking → reason → observed records.
Keep the primary network/timeline visible, use tables for exact evidence,
label all units, show unknown/insufficient-history as distinct states, and
avoid decorating the screen with unsupported threat maps or confidence KPIs.
Verify real screenshots at the presentation resolution, legible text,
selection consistency, empty states and export readability in MATLAB.

## Scientific boundary

The present detector is transductive descriptive ranking. A prospective
claim needs a chronological reference/evaluation split and features available
at each decision time. Feature-space injection only measures score sensitivity;
event-level scenario injection is needed to test extraction end to end.
Do not tune on a label-selected slice and present that same slice as untouched
external validation. Report host counts and scenario selection, not only a
large number of flows that share the same few infected hosts.
