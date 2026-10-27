# Technical Report — DRAFT

> **Status of this draft.** Structure, background, data, methodology, system design, discussion
> framework, ethics and appendices are written. **Every result is a placeholder** marked
> `[PENDING MATLAB RUN — do not fill by hand]`; the MATLAB pipeline and experiments have not been
> executed yet (docs/REPRODUCIBILITY.md §4). Human fields are marked `[TO FILL]`. Task T-063.
>
> **Scope update 2026-10-20.** The project owner confirmed that the assigned topic concerns
> **computer-network traffic**. The report is therefore organised around labelled network-security
> datasets (primary: CTU-13; secondary: CIC-IDS2017, UNSW-NB15, LANL) [NET]. The burglary
> co-offending artifact analysed first is kept as a *first case study* (§3.6 and the burglary
> rows of §4) until the owner decides whether it stays in the final report (TASKS_FOR_ADMIN 11b).
> Network-dataset facts are `[PENDING DOWNLOAD + MATLAB RUN]`: the files could not be downloaded in
> the development environment.

---

## Title page

| Field | Value |
|---|---|
| Title (TR) | **Ağ Tabanlı Şüpheli Davranış Örüntülerinin Analizi ve Multimedya Destekli Görselleştirilmesi** |
| Title (EN) | **Network-Based Suspicious Behaviour Pattern Analysis and Multimedia-Supported Visualization** |
| Course | Çoklu Ortam (Multimedia) — course code `[TO FILL]` |
| Institution | Fırat University — faculty / department `[TO FILL]` |
| Author(s) | `[TO FILL]` (name, student number) |
| Instructor | `[TO FILL]` |
| Date | `[TO FILL]` |
| Repository version | commit `[TO FILL]`; project version 0.2.0, feature version F3 [CFG] |
| Primary dataset | CTU-13 scenario `[TO FILL: scenario number and .binetflow file name]`, Git blob SHA `[TO FILL]` [NET] |
| Case-study dataset | burglary artifact, Git blob SHA `3afe9cbb4e313fb056f1b115c92a3f750f4698b9` [DSI] |

### Source keys used in brackets

Every number in this report is followed by a bracket naming the document or file it is copied
from. Keys:

| Key | File |
|---|---|
| [PC] | PROJECT_CONTEXT.md |
| [README] | README.md |
| [MET] | docs/METHODOLOGY.md |
| [AUD] | docs/AUDIT_2026-09-30.md |
| [DSI] | docs/DATASET_SCHEMA_INSPECTION.md |
| [CARD] | data/DATASET_CARD.md |
| [DD] | docs/DATA_DICTIONARY.md |
| [FE] | docs/FEATURE_ENGINEERING.md |
| [REG] | src/features/featureRegistry.m |
| [TMP] | docs/TEMPORAL_ANALYSIS.md |
| [SPA] | docs/SPATIAL_ANALYSIS.md |
| [GRA] | docs/GRAPH_ANALYSIS.md |
| [SEQ] | docs/SEQUENCE_ANALYSIS.md |
| [ANO] | docs/ANOMALY_DETECTION.md |
| [PAT] | docs/PATTERN_MINING.md |
| [XAI] | docs/EXPLAINABILITY.md |
| [MM] | docs/MULTIMEDIA_DESIGN.md |
| [EXP] | docs/EXPERIMENTS.md |
| [EVA] | docs/EVALUATION.md |
| [ETH] | docs/ETHICS_AND_LIMITATIONS.md |
| [SI] | docs/SOURCE_INDEX.md |
| [RL] | docs/RESEARCH_LOG.md |
| [USE] | docs/USABILITY_STUDY.md |
| [REP] | docs/REPRODUCIBILITY.md |
| [CFG] | configs/projectConfig.m |
| [VAL] | src/data/validateBurglaryNetwork.m |
| [PIPE] | src/pipeline/runAnalysisPipeline.m |
| [RUNEXP] | src/evaluation/runExperiments.m |
| [FIG] | scripts/generate_report_figures.m |
| [NET] | docs/NETWORK_DATASETS.md |
| [NETREF] | scripts/reference/network_flow_reference.py |

### Terminology used throughout

In the network datasets the scored unit is a **host** — an IP address or computer name, replaced
by a pseudonym `ENT…` on import — described by the flows (connections) or authentication events it
takes part in [NET]. In the burglary case study it is the **anonymized offender record** (`OID#n`).
Outputs are called *anomaly scores*, *behavioural deviations* or *unusual traffic / record
patterns*. A high score is never a statement that a host is compromised or that a person is
guilty; scored entities are never called "attacker", "criminal" or "suspect" [MET §1; ETH §1].
The word "suspicious" in the assigned title is read as "statistically unusual relative to a
reference population". Published dataset labels (botnet, attack, red team) are used only to
*evaluate* the detectors after scoring (§4.10).

---

## Abstract

This project builds a MATLAB analytical system that ranks unusual behaviour of hosts in computer-
network traffic and presents the evidence in a linked, replayable multimedia application. The
primary data are the labelled botnet captures of CTU-13; CIC-IDS2017, UNSW-NB15 and the LANL
authentication events are supported as secondary datasets. Each file is recognised by a documented
layout profile, validated, pseudonymized (no IP address leaves the import) and converted into a
time-stamped host-interaction network. Twelve traffic features (fan-out and fan-in, destination-
port diversity and entropy, tiny-flow share, failed attempts, flow size and duration, and a
beaconing measure — the regularity of repeated connections typical of command-and-control
traffic) complement graph, activity, timing and sequence features. A transparent robust baseline
and Isolation Forest score the same prepared matrix under an explicit review budget; every
ranking is explained by an exact baseline decomposition, an occlusion attribution and generated
evidence text. Because the network datasets carry published labels, detection quality is measured
against them — after scoring and never as features — with ROC-AUC, average precision against its
chance level and precision at k, separately for hosts with verified labels and with unlabelled
background hosts counted as negatives. Synthetic injection, sensitivity analysis, runtime
measurement and a usability study complete the evaluation. The system was first developed on an
anonymized co-offending network, which is retained as a case study.

**Results:** `[PENDING MATLAB RUN]`

**Keywords:** network anomaly detection, botnet traffic, CTU-13, Isolation Forest, explainability,
temporal analysis, linked views, multimedia visualization, MATLAB.

## Özet

Bu proje, bilgisayar ağı trafiğinde host'ların (IP adresleri / bilgisayarlar) olağandışı
davranışlarını sıralayan ve bulguları bağlantılı, yeniden oynatılabilir bir multimedya
uygulamasıyla sunan MATLAB tabanlı bir analiz sistemi geliştirmektedir. Birincil veri, etiketli
botnet trafiği içeren CTU-13 veri setidir; CIC-IDS2017, UNSW-NB15 ve LANL kimlik doğrulama olayları
ikincil veri setleri olarak desteklenir. Her dosya belgelenmiş bir biçim profiliyle tanınır,
doğrulanır, takma adlandırılır (hiçbir IP adresi içe aktarmanın dışına çıkmaz) ve zaman damgalı bir
host etkileşim ağına dönüştürülür. On iki trafik özelliği (bağlantı yayılımı, hedef port çeşitliliği
ve entropisi, küçük akış oranı, başarısız denemeler, akış boyutu ve süresi ile komuta-kontrol
trafiğine özgü düzenli tekrar eden bağlantıları ölçen "beaconing" ölçüsü) çizge, etkinlik, zaman ve
dizi özelliklerini tamamlar. Şeffaf bir dayanıklı taban model ve Isolation Forest aynı hazırlanmış
matrisi açık bir inceleme bütçesi altında puanlar; her sıralama, taban modelin tam ayrışımı, bir
örtme (occlusion) katkı analizi ve otomatik kanıt metniyle açıklanır. Ağ veri setleri yayımlanmış
etiketler içerdiğinden tespit başarısı bu etiketlere göre — puanlamadan sonra ve asla özellik
olarak kullanılmadan — ROC-AUC, şans düzeyine göre ortalama kesinlik ve ilk k'deki kesinlik ile
ölçülür. Sentetik enjeksiyon, duyarlılık analizi, çalışma süresi ölçümü ve kullanılabilirlik
çalışması değerlendirmeyi tamamlar. Sistem önce anonimleştirilmiş bir birlikte suç işleme ağı
üzerinde geliştirilmiş, bu çalışma örnek vaka olarak korunmuştur.

**Sonuçlar:** `[PENDING MATLAB RUN]`

**Anahtar kelimeler:** ağ anomali tespiti, botnet trafiği, CTU-13, Isolation Forest,
açıklanabilirlik, zamansal analiz, bağlantılı görünümler, multimedya görselleştirme, MATLAB.

---

## 1 Introduction

### 1.1 Problem

Hosts in a computer network leave records of *when*, *with whom*, *on which ports* and *how
regularly* they communicate. Most hosts follow common patterns; a few deviate — for example a host
that suddenly contacts hundreds of destinations, probes many ports with tiny flows, fails repeated
logins, or calls the same server at clock-like intervals, as bots do when they poll a command-and-
control server [NET]. An analyst who wants to inspect such deviations needs (a) a reproducible way
to rank them, (b) evidence that explains each ranking in measurable terms, (c) a presentation that
makes the temporal and relational context visible and (d) where labels exist, an honest
measurement of how well the ranking finds the known malicious hosts. A single alert score without
context invites over-interpretation; unrelated charts do not support reasoning about one host
across time and network.

### 1.2 Motivation

The assigned topic asks for the analysis of suspicious behaviour patterns in a network and their
multimedia-supported visualization. The project interprets "suspicious" strictly as *statistically
unusual with respect to a documented reference population* [PC; MET §1], and "network" as
computer-network traffic (owner decision 2026-10-20) [PC; NET]. Multimedia is the synchronized,
time-based, interactive presentation of analytical evidence, because the datasets contain no audio
or video streams [MM]. The exact assignment wording is not yet
transcribed into the repository (task T-001) `[TO FILL: assignment wording, once available]`.

### 1.3 Research questions

The research questions are taken verbatim from PROJECT_CONTEXT.md [PC]:

1. **RQ1** Which behavioral features best separate baseline behavior from anomalous behavior?
2. **RQ2** Does temporal context improve anomaly detection over static network features?
3. **RQ3** Does combining node-level and edge-level features improve detection?
4. **RQ4** Can repeated/sequential patterns explain why a data point was flagged?
5. **RQ5** Can the same analytical result be communicated more effectively through interactive
   multimedia visualization than through tables alone?

Section 7 states which experiment addresses each question and what outcome would support or
weaken it.

### 1.4 Contributions

1. **Direct support for four labelled network-security datasets** (CTU-13, CIC-IDS2017,
   UNSW-NB15, LANL) through documented layout profiles with content checks, pseudonymization of
   addresses, per-flow attributes without addresses, and a host-level ground truth derived from
   the published labels; and an evaluation that separates verified labels from unlabelled
   background traffic [NET].
1. **Host traffic features** including a beaconing measure for command-and-control regularity
   [FE; NET].
1. **A verified, pinned data foundation** (case study): the artifact is identified by its Git blob SHA,
   validated by 37 checks before analysis, and its structure is characterised; notably, the
   offender network is shown to be exactly the one-mode projection of the offender–crime records
   [AUD §3].
2. **Time-stamped relations**: rebuilding ties from shared crimes gives every tie a first and last
   shared date, which enables a dynamic network and replay that the file itself does not provide
   [AUD §3; GRA].
3. **A registered feature set**: 28 features in six groups, defined once in a registry that drives
   scaling, ablation, explanation text and documentation [MET §3; REG].
4. **Two comparable detectors** (robust baseline and Isolation Forest) on one prepared matrix,
   with an explicit review budget instead of an unjustifiable "risk threshold" [ANO].
5. **Per-entity explanations**: exact baseline shares, Isolation Forest occlusion deltas, a
   dominant feature group and generated text with a mandatory interpretation caveat [XAI].
6. **An evaluation protocol** with real labels where they exist (E11) and for the no-ground-truth setting (E1–E10), including synthetic
   injection with clean-reference novelty training for Isolation Forest [EXP; EVA].
7. **A linked multimedia application** with brushing and linking, overview-to-detail navigation,
   time-cursor replay and an optional audio cue [MM].

### 1.5 Scope and non-goals

In scope: host-level traffic profiles, system-level temporal/network/sequence analysis,
unsupervised ranking, evaluation against published labels, explanation and interactive
presentation of public network-security datasets; the burglary artifact as a first case study.

Non-goals [PC; ETH §1]:

- no intrusion-prevention, blocking or attribution of attacks to people;
- no supervised classifier trained on the labels (the question is what an unsupervised, explained
  ranking finds);
- no prediction of criminality from demographic or protected attributes (none are present);
- no identification of real people, no re-identification attempts, no external joins;
- no production law-enforcement or risk-assessment system;
- no web/mobile stack added for appearance;
- no fabricated results used as evidence.

**Anomaly ≠ compromise.** In the network datasets a high score means that a host's traffic is
unusual among the hosts of the same capture; servers, scanners run by administrators and busy
gateways are unusual without being malicious. Published labels show how often unusual coincides
with malicious in these benchmark captures; they do not turn a score into a verdict.

**Anomaly ≠ guilt (case study).** Every record in the burglary artifact is already a solved case. An anomaly
score therefore says nothing about whether an offence happened; it says only that the recorded
pattern of an offender record is unusual relative to other recorded offender records with at least
three cases. Unusual can reflect data-collection artefacts (date heaping, batch solving, recording
practice) as much as behaviour [ETH §2].

---

## 2 Related work

Only works listed in docs/SOURCE_INDEX.md are cited [SI]. Entries marked (m) in the source index
are standard references cited from memory and must be verified before submission (see
References).

### 2.0 Network intrusion datasets and botnet behaviour

García et al. (2014) published CTU-13, thirteen captures of real botnet traffic mixed with normal
and background traffic in a university network, with every bidirectional flow labelled, and used it
to compare botnet detection methods. Sharafaldin et al. (2018) generated CIC-IDS2017 from profiled
benign behaviour and scripted attacks (DoS, DDoS, port scan, brute force, web attacks, botnet,
infiltration); later analyses report labelling and feature-extraction errors in its flow files
(Engelen et al., 2021; SciTePress 2022 study), which this project treats as known limitations
rather than ground truth beyond doubt. Moustafa and Slay (2015) built UNSW-NB15 with nine attack
families. Kent (2015) released two months of authentication, process, DNS and flow events from the
Los Alamos National Laboratory enterprise network together with red-team activity. Periodic
contact with a command-and-control server ("beaconing") and wide, shallow fan-out (scanning,
spam) are recurring botnet traffic characteristics described for CTU-13 (García et al., 2014); the
traffic features of §4.3 operationalise these as measurable host properties.

### 2.1 Anomaly detection and its evaluation

Isolation Forest (Liu et al., 2008) isolates observations by random axis-parallel splits; points
that are isolated after few splits receive high anomaly scores. It runs in time linear in the
number of trees and sub-sample size and makes few distributional assumptions, and its default
sub-sample of 256 is adopted here. For a transparent reference, the modified z-score of Iglewicz
and Hoaglin (1993), based on the median and the scaled median absolute deviation (1.4826·MAD) with
a 3.5 cut-off, provides a robust per-feature deviation measure. Evaluating unsupervised detectors
is difficult without labels: Campos et al. (2016) compare measures such as ROC-AUC, average
precision and precision at n, and Emmott et al. (2013) argue for constructing benchmarks with
controlled anomalies derived from real data — the basis of the synthetic injection used here.
Akoglu et al. (2015) survey graph-based anomaly detection; their taxonomy motivated using
node-level structural features within a feature-based detector rather than community-based graph
detectors.

### 2.2 Network analysis of criminal networks

Sparrow (1991) assessed the prospects of applying network analysis to criminal intelligence and
emphasised three problems that remain central: incompleteness (missing nodes and ties), fuzzy
boundaries and dynamics. These limit the interpretation of centrality, which is why this report
never reads centrality as "leadership" or "importance" (Section 8). The dataset used here was
published with work on inductive and transductive link prediction for criminal network analysis
(Ahmadi et al., 2023), which is cited as the dataset source rather than as a method used here.
The structural measures follow standard definitions: local clustering (Watts & Strogatz, 1998),
k-core decomposition (Batagelj & Zaversnik, 2003) and betweenness centrality (Freeman, 1977).

### 2.3 Temporal and spatial measures

Goh and Barabási (2008) define the burstiness coefficient B = (σ − μ)/(σ + μ) of inter-event
times, which distinguishes periodic, Poisson-like and bursty activity. Truong et al. (2020) review
offline change-point detection; the project uses penalized binary segmentation following that
review. Radius of gyration, a standard measure of individual spatial spread in human mobility
research (González et al., 2008), summarises how widely an offender record's events are spread in
normalized space. The spatial scan statistic (Kulldorff, 1997) is the reference point for the
project's simpler fixed-grid space–time Poisson excess test, which is explicitly *not* a scan
implementation. Sample quantiles follow the type-7 definition discussed by Hyndman and Fan (1996).

### 2.4 Explainability

Siddiqui et al. (2019) study feature-based explanations of anomalies, i.e. which features an
analyst must inspect to confirm that a point is anomalous. The project adopts the feature-level
view: an exact additive decomposition for the robust baseline and a perturbation (occlusion)
attribution for Isolation Forest.

### 2.5 Visualization and multimedia

Shneiderman (1996) proposed the "overview first, zoom and filter, then details on demand"
information-seeking mantra. Becker and Cleveland (1987) introduced brushing of linked
scatterplots, the origin of the linked-selection principle used across all views. Tversky et al.
(2002) found little evidence that animation outperforms static graphics unless it is interactive
and congruent with the content; this motivates a user-controlled replay rather than automatic
animation. Brooke (1996) introduced the System Usability Scale used in the planned usability
study.

---

## 3 Data

### 3.1 Network-traffic datasets

| Dataset | Role | File used | Hosts / events | Labels | Source |
|---|---|---|---|---|---|
| CTU-13 | **primary** | one scenario's `.binetflow` (bidirectional Argus flows) | IP addresses; one flow = one event | Botnet → malicious; Normal → benign; Background → **unknown** | García et al. (2014); CC BY [NET] |
| CIC-IDS2017 | secondary | one day of `GeneratedLabelledFlows` | IP addresses | BENIGN / attack name | Sharafaldin et al. (2018) [NET] |
| UNSW-NB15 | secondary | `UNSW-NB15_1.csv` (49 columns, no header) | IP addresses | `Label` 0/1, `attack_cat` | Moustafa & Slay (2015) [NET] |
| LANL | secondary | `auth.txt` subset (`max_rows`) + `redteam.txt` | computers; one authentication = one event | red-team events → malicious | Kent (2015) [NET] |

Selected files and their versions: `[TO FILL after download: scenario/day/part, file name, size,
Git blob SHA]`.

### 3.2 Import, validation and privacy (network)

Layouts are recognised by `matchNetworkProfile`: headered files by their column names
(normalised for case and spaces), headerless files by column count **and** content checks on the
first 200 rows (IPv4 addresses, integer times, 0/1 labels, Success/Fail), so a file is never
silently read with the wrong layout [NET]. `importNetworkFlows` turns each record into an event
between its source and destination hosts and keeps a flow table with time, duration (s), bytes,
packets, ports, protocol and authentication outcome — **indices only, no addresses**. Hosts are
pseudonymized `ENT…` in order of first appearance; the address map is not stored unless requested
and then only outside the bundle (git-ignored) [NET; DATASET_IMPORT]. Timestamps are parsed with
each dataset's documented formats (CTU microseconds, CIC mixed day/month layouts, UNSW POSIX
seconds, LANL relative seconds), never by automatic guessing. The validation checks of §3.6.4 run
on every dataset; link-file checks are "not applicable" because relations are derived from shared
flows.

### 3.3 Dataset facts (to be filled from the run)

| Fact | Value |
|---|---|
| Flows read / hosts / hosts with ≥ 3 flows | `[PENDING DOWNLOAD + MATLAB RUN]` |
| Capture span and chosen time bin | `[PENDING]` (`configureForDataset`: minute bins below 24 h, hour bins up to 30 days) |
| Labelled flows malicious / benign / unknown | `[PENDING]` |
| Hosts malicious / benign / unknown | `[PENDING]` |
| Validation result | `[PENDING]` |

Reference check before MATLAB: the independent Python reference [NETREF] was run on a real
published capture in the CTU-13 layout (Stratosphere's public test capture, 6,751 flows, 497 hosts,
unlabelled): the infected host initiated 99.7 % of its 6,751 flows to 495 distinct destinations
over 10 destination ports, with a most regular destination at gap CV 0.099 — the kind of profile
the traffic features are designed to expose. This sanity check is not a result of this project.

### 3.4 Labels and ground truth

`labelNetworkFlows` maps each published label to malicious / benign / unknown and to the endpoint it
describes (CTU-13 `To-…` labels describe the destination). A host is malicious when at least one
labelled record about it is malicious, benign when it has only benign labelled records, unknown
otherwise (`networkGroundTruth`) [NET]. CTU-13 Background traffic is explicitly *not* benign.

### 3.5 Known dataset limitations

CIC-IDS2017: label and feature errors and 12-hour timestamps without AM/PM in some files;
CTU-13: most traffic is unlabelled background; UNSW-NB15: synthetic testbed traffic; LANL: red-team
labels cover successful authentications only and times are relative [NET; §2.0].

### 3.6 First case study: burglary co-offending artifact

#### 3.6.1 Source, licence and citation

| Item | Value |
|---|---|
| Artifact | `israel_lea_inp_burglary_offender_id_network.json` [CARD] |
| Upstream | https://github.com/erichoang/criminal-network-visualization, path `datasets/preprocessed/` [CARD] |
| Identity | Git blob SHA `3afe9cbb4e313fb056f1b115c92a3f750f4698b9`, verified at download by `verifyGitBlobSha` [CARD; MET §2] |
| Size | 15,551,662 bytes [CARD] |
| Inspection date | 2026-09-30 [DSI] |
| Provider description | around 23,000 solved burglary cases in Israel (2012–2021) supplied by the Israel National Police, "duly anonymized according to the standards of Israeli national law and GDPR and further approved by a legal advisor of the Israel National Police" [CARD] |
| Licence | BSD-3-Clause-style, "Copyright (c) 2021, Consortium Board ROXANNE" [CARD] |
| Required citation | Ahmadi et al. (2023), *Journal of Computational Science* 72, 102063 [CARD; SI] |
| Storage | raw data are downloaded on demand and not committed (conservative choice) [CARD] |

The provider's description (around 23,000 cases, 2012–2021) and the exact artifact (24,087 crime
IDs, dates 2010-12-01 to 2020-09-28) describe different layers; the artifact is the authority for
schema and statistics [DSI].

#### 3.6.2 Schema

NetworkX JSON with `directed = true`, `multigraph = false`, `graph`, `nodes`, `links` [DSI].
Nodes are of type `offender` and carry `list_cid` and a nested `crime_details` mapping with
`X`, `Y`, `date`, `num_of_offenders`. Links carry `weight`, `type`, `observed`, `source`, `target`
[DSI; DD].

#### 3.6.3 Verified facts

All values below were verified on the artifact by the independent reference audit
(`scripts/reference/audit_dataset_reference.py`) and are checked by the MATLAB regression test
`tests/test_real_dataset.m` (pending execution) [DSI; AUD §3].

| Fact | Value | Source |
|---|---|---|
| Offender nodes | 17,237 | [DSI] |
| Links (directed) | 21,302 | [DSI] |
| Undirected relations | 10,651 | [DSI] |
| Unique crime IDs | 24,087 | [DSI] |
| Offender–crime association rows | 34,156 | [DSI] |
| Pair–crime rows (time-stamped relations) | 15,422 | [DSI] |
| Date range | 2010-12-01 to 2020-09-28 | [DSI] |
| X, Y range | 0–1 (min-max scaled) | [DSI] |
| `num_of_offenders` range; mean (rows / crimes); median | 1–13; ≈ 1.903 / ≈ 1.418; 1 | [DSI] |
| Link weight range; mean; median | 1–37; ≈ 1.448; 1 | [DSI] |
| Link `type` / `observed` | `relation` / true for all links | [DSI] |
| Crimes per offender | min 1, median 1, mean 1.98, max 40 | [DSI] |
| Offenders with one crime | 11,446 (66 %) | [DSI; AUD §3] |
| Offenders with ≥ 2 / ≥ 3 / ≥ 5 crimes | 5,791 / 3,260 / 1,395 | [DSI] |
| Offenders per crime | 1: 17,402 · 2: 4,512 · 3: 1,390 · 4: 523 · 5: 170 · 6: 53 · 7: 19 · 8: 5 · 9: 9 · 10: 1 · 11: 1 · 12: 1 · 13: 1 | [DSI] |
| Isolated offenders (no co-offender) | 7,597 (44 %) | [DSI; AUD §3] |
| Connected components; largest | 10,468; 518 offenders | [DSI] |
| Maximum k-core; articulation points | 12; 1,156 | [DSI] |
| Distinct (X, Y) among crimes | 19,509 of 24,087 | [DSI] |
| Median consecutive step (same offender) | 0.006586 normalized units (16,919 steps) | [DSI] |
| Busiest calendar month (all years) | July, 2,374 crimes | [DSI] |

*Note:* the mean of `num_of_offenders` is ≈ 1.903 over the 34,156 offender–crime rows and
≈ 1.418 (= 34,156 / 24,087) per unique crime (resolved 2026-10-19 against the reference audit;
the offenders-per-crime distribution above was also corrected to include sizes 10–12).

#### 3.6.4 Validation design

Validation runs before any analysis; nothing is silently repaired; an error-level failure stops
the pipeline [MET §2]. The 37 checks are implemented in `validateBurglaryNetwork` and exported as
JSON, CSV and Markdown by `writeValidationReport` [VAL; AUD §2]. Counts by category and severity
are taken from the check definitions in [VAL]:

| Category | Check IDs | Count | What is checked |
|---|---|---|---|
| structure | V01–V03 | 3 | nodes, links and events are present |
| nodes | V10–V14 | 5 | non-empty, unique IDs; node type; `list_cid` vs `crime_details`; nodes without crimes |
| links | V20–V31 | 12 | endpoints present and valid; self-loops; duplicates; weight missing/negative/zero/non-integer; type; observed; reciprocity; symmetric weights |
| events | V40–V49, V61 | 11 | crime-ID restoration; missing crime ID; duplicate rows; parseable and plausible dates; pre-series events; time of day; X/Y present and in [0,1]; `num_of_offenders` valid; day-1 heaping |
| consistency | V50–V54 | 5 | per-crime consistency across offenders; `num_of_offenders` vs attached offenders; links vs shared crimes; weight = shared crimes |
| graph | V60 | 1 | isolated offenders |
| **Total** | | **37** | |

Severities [VAL]: 11 *error* checks (block the pipeline), 18 *warning* checks (documented,
analysis continues), 8 *info* checks (record a property of the data, no judgement). Date
plausibility bounds are 2000-01-01 to 2021-12-31 and are used for validation only, never to drop
rows [CFG].

#### 3.6.5 Key structural findings

1. **Reciprocal links.** All 21,302 links occur in reciprocal pairs with equal weights, i.e.
   10,651 undirected relations; `directed = true` is a serialization property, not a semantic one
   [AUD §3.1; DSI]. The graph is therefore modelled as undirected.
2. **Weight = shared crimes.** Every link weight equals the number of crimes shared by its two
   offenders, and every pair that shares a crime is linked. The offender network is exactly the
   one-mode projection of the offender–crime bipartite graph [AUD §3.2]. Consequences: graph and
   co-offending features are not independent evidence; every tie can be time-stamped (15,422
   pair–crime rows) [DSI].
3. **`num_of_offenders` is redundant**: it equals the number of attached offenders for all 24,087
   crimes [AUD §3.3]. Cross-offender consistency of a crime's date, X, Y and `num_of_offenders`
   shows 0 inconsistencies [DSI].
4. **Crime-ID restoration.** `list_cid` and `crime_details` keys are identical sets for all nodes,
   so IDs that MATLAB's `jsondecode` rewrites (`CID#2` → `CID_2`) can be restored [DSI; AUD §2H].
5. **Day resolution only.** 0 of 34,156 rows have a non-midnight time; hour-of-day analysis is
   impossible and same-day order is a convention (numeric crime ID) [DSI; AUD §3.4].
6. **Uneven coverage and censoring.** Rows per year: 2010: 1, 2011: 2, 2012: 5, 2013: 83,
   2014: 5,639, 2015: 4,812, 2016: 4,820, 2017: 5,149, 2018: 5,071, 2019: 5,189, 2020: 3,385
   [DSI]. The 91 rows before 2014 are too sparse for a baseline; the data are solved cases, so the
   most recent months are right-censored by solving delay, and September 2020 is incomplete
   [AUD §3.5; CFG].
7. **Date heaping.** Day 1 of the month has +17.7 % rows (+16 % crimes) relative to days 2–28;
   possibly imputed dates (validation V61) [DSI].
8. **Sparsity.** 66 % of offenders have one crime, 7,597 have no co-offender and 3,260 have at
   least three crimes and form the anomaly population; the largest connected component has 518
   offenders [AUD §3.7].
9. **Repeated sites.** 24,087 crimes occupy 19,509 distinct normalized (X, Y) points [DSI].
10. **Unsupported analyses.** No hour-of-day analysis, no crime-type analysis (the upstream
    free-text embedding is not in this artifact), no real-world distances or maps [DSI].

#### 3.6.6 Privacy

Identifiers are the provider's pseudonyms (`OID#n`, `CID#n`); coordinates are provider min-max
scaled "to prevent precise retrieval of the localization of the site" [ETH §5; SPA]. The project
never attempts re-identification, never joins external data, never de-normalizes coordinates
(`cfg.privacy.denormalize_coordinates = false`) and draws no basemap [CFG; ETH §5]. Reports,
validation files and figures contain aggregates or pseudonymous IDs only; the validation Markdown
is tested to contain no `OID#`; this report refers to entities by rank or `entity_index` only.
Output CSVs contain pseudonymous identifiers and are not published outside the course context
[REP §3].

---

## 4 Methodology

### 4.1 Pipeline architecture

`runAnalysisPipeline` executes the stages in a fixed order, times each one and writes one shared
analytical model, the **analysis bundle** (`outputs/model/analysis_bundle.mat`) [PIPE; MET]:

```text
load → flatten (crime-ID restoration) → validate (37 checks)
 → crimes · relations (time-stamped) → graph features → behaviour features
 → sequences (tokens, Markov model, n-grams) → feature merge
 → temporal series, anomalies, change points → spatial grid & space–time excess
 → dynamic graph → pattern mining → anomaly detection → explanations → save
```

The bundle connects every layer through one integer key, `entity_index`, so that linking views is
an index lookup rather than a string join. Its fields are `meta`, `config`, `validation`,
`entities`, `events`, `crimes`, `relations`, `pairEvents`, `graph`, `registry`, `sequence`,
`temporal`, `spatial`, `dynamicGraph`, `patterns`, `anomaly`, `explanations` [PIPE; see
docs/ARCHITECTURE.md]. All analysis lives in `src/`; the application only lays out views and calls
the same functions, and report figures use the same plotting functions as the application
[MM; FIG]. Every parameter is in `configs/projectConfig.m` (Appendix B).

### 4.2 Preprocessing

- **Ingestion** decodes the JSON, restores original crime IDs from `list_cid` and flags each row
  with `id_restored` (check V40) [MET §2; DD].
- **Canonical events**: one row per (offender, crime); duplicates are dropped *and* reported
  (V42); order within an offender is date, then numeric crime ID for same-day events [MET §2].
- **Crime table**: one row per crime with cross-offender consistency flags [DD].
- **Relation table**: ties are rebuilt from shared crimes; this reproduces every file link and
  weight (V52–V54) and adds `first_time`, `last_time`, `span_days` to each tie; `pairEvents` holds
  one row per shared crime [MET §2; DD].
- **Undefined values are `NaN`, never 0** (e.g. gap statistics of an offender with one crime)
  [MET §3; FE].
- The decoded JSON is dropped immediately after flattening to limit memory [AUD §2H].

### 4.3 Behavioural features

Twenty-eight features in six groups are defined once in `featureRegistry.m` (feature version F2)
[REG; FE; CFG]. Notation: an offender record with k crimes at dates t₁ ≤ … ≤ t_k, gaps
g_i = t_{i+1} − t_i, sites p_i = (x_i, y_i) in normalized units, group sizes
n_i = `num_of_offenders`. "min" is the minimum number of crimes for the feature to be defined
[FE].

| # | Feature | Group | min | Transform | Formula |
|---|---|---|---|---|---|
| 1 | `event_count` | activity | 1 | log1p | k |
| 2 | `active_span_days` | activity | 1 | – | t_k − t₁ |
| 3 | `active_day_count` | activity | 1 | log1p | number of distinct dates |
| 4 | `iet_median_days` | temporal | 3 | log1p | median(g) |
| 5 | `iet_cv` | temporal | 3 | – | std(g)/mean(g) (NaN if mean = 0) |
| 6 | `burstiness` | temporal | 3 | – | B = (σ_g − μ_g)/(σ_g + μ_g) ∈ [−1, 1] (Goh & Barabási, 2008) |
| 7 | `max_gap_ratio` | temporal | 3 | log1p | max(g)/max(median(g), 1 day) |
| 8 | `peak_window_share` | temporal | 3 | – | max_j #{i : t_j ≤ t_i < t_j + 30 d} / k |
| 9 | `same_day_fraction` | temporal | 2 | – | 1 − distinct dates / k |
| 10 | `radius_of_gyration` | spatial | 2 | – | sqrt(mean‖p_i − p̄‖²) (González et al., 2008) |
| 11 | `mean_step_distance` | spatial | 2 | – | mean ‖p_{i+1} − p_i‖ in date order |
| 12 | `max_step_distance` | spatial | 2 | – | max ‖p_{i+1} − p_i‖ |
| 13 | `location_repeat_fraction` | spatial | 2 | – | 1 − distinct sites / k |
| 14 | `mean_group_size` | co-offending | 1 | – | mean(n_i) |
| 15 | `solo_fraction` | co-offending | 1 | – | share of n_i = 1 |
| 16 | `max_group_size` | co-offending | 1 | – | max(n_i) |
| 17 | `repeat_partner_fraction` | co-offending | 1 | – | partners with ≥ 2 shared crimes / partners (0 without partners) |
| 18 | `degree` | graph | 1 | log1p | number of distinct co-offenders |
| 19 | `strength` | graph | 1 | log1p | Σ shared crimes over partners |
| 20 | `max_tie_weight` | graph | 1 | log1p | max shared crimes with one partner |
| 21 | `clustering_coef` | graph | 1 | – | triangles / (d(d−1)/2), 0 if d < 2 (Watts & Strogatz, 1998) |
| 22 | `core_number` | graph | 1 | log1p | k-core index (Batagelj & Zaversnik, 2003) |
| 23 | `component_size` | graph | 1 | log1p | offenders in the connected component |
| 24 | `betweenness` | graph | 1 | log1p | unweighted shortest-path betweenness (Freeman, 1977) |
| 25 | `is_cut_vertex` | graph | 1 | – | 1 if an articulation point |
| 26 | `seq_surprisal_mean` | sequence | 2 | – | mean −log₂ P(token_t \| token_{t−1}) |
| 27 | `seq_surprisal_max` | sequence | 2 | – | max of the same |
| 28 | `new_partner_rate` | sequence | 1 | – | share of crimes with ≥ 1 previously unseen partner |

Group sizes: activity 3, temporal 6, spatial 4, co-offending 4, graph 8, sequence 3 [REG].
`component_id` is stored for navigation but is not a model feature [FE].

**Network-traffic features (group `network`, feature version F3).** For network datasets twelve
host features are added (`computeNetworkFeatures`) [FE; NET]; *outgoing* = flows the host
initiated:

| # | Feature | min | Transform | Definition |
|---|---|---|---|---|
| 29–30 | `out_flows`, `in_flows` | 1 | log1p | flows initiated / received |
| 31 | `out_share` | 1 | – | out / (out + in) |
| 32–33 | `distinct_dst`, `distinct_src_in` | 1 | log1p | fan-out / fan-in (distinct peers) |
| 34 | `distinct_dport` | 1 | log1p | distinct destination ports |
| 35 | `dport_entropy` | 2 | – | −Σ p log₂ p over destination ports |
| 36–37 | `median_bytes_out`, `median_duration_out` | 1 | log1p | medians of outgoing flows |
| 38 | `small_flow_fraction` | 1 | – | outgoing flows with ≤ 2 packets / outgoing |
| 39 | `failed_fraction` | 1 | – | failed / outgoing authentications (LANL) |
| 40 | `beacon_cv_min` | 4 | – | min over destinations with ≥ 4 flows of std/mean of the gaps between flow starts (≈ 0 = clock-like) |

In the network datasets every event has exactly two participants, so the co-offending group sizes
are constant and dropped automatically; spatial features are undefined (no coordinates) and
dropped; graph features describe the host-interaction network; the feature definitions were
cross-checked against the Python reference on a hand-built CTU-13 fixture [NETREF;
`tests/test_network_datasets.m`]. **No feature reads the label columns.**

Design decisions [FE]: gap features need at least three crimes (two crimes give one gap and no
dispersion); radius of gyration replaces mean pairwise distance (same concept, O(k) instead of
O(k²)); in/out degree is removed because every link is reciprocal; `log1p` keeps a handful of
extreme counts from dominating the robust scale (Isolation Forest is invariant to such monotone
transforms). Group-size and graph features overlap by construction because `num_of_offenders`
equals the attached offenders; ablation results must be read with that in mind.

**Leakage control.** The setting is unsupervised and transductive (no labels), so supervised
leakage does not arise. Temporal look-ahead is prevented: `group_state` uses only earlier events,
system-level temporal z-scores use only earlier months, and `fitTransitionModel` accepts a row mask
for temporal hold-out experiments [FE].

### 4.4 Temporal analysis

**Time resolution (network datasets).** `configureForDataset` chooses the coarsest bin that still
gives a usable series: month (≥ 24 months), week (≥ 26 weeks), day (≥ 30 days), hour (≥ 24 h),
otherwise minute; for day/hour/minute bins the causal rolling baseline is used (the seasonal rule
needs years of monthly data) and dynamic-graph windows are about eight equal windows [NET; CFG].
A CTU-13 scenario (hours) is analysed in minute or hour bins. The rest of this subsection
describes the case study's monthly series.

**System series (case study).** Monthly crimes, active offenders, new offenders (first-ever crime),
co-offending share and mean group size over 2014-01 to 2020-08 (exclusive end 2020-09-01), i.e. 80
monthly bins [MET §4; CFG]. 2010–2013 (91 rows) are excluded as too sparse, and September 2020 as
incomplete and right-censored [MET §4; CFG].

**Unusual months — production rule.** The configured method is a causal **same-calendar-month
robust baseline** (`cfg.temporal.anomaly_method = "seasonal_same_month"`): each month is compared
only with earlier observations of the same calendar month, using up to five prior years and
requiring at least three prior samples; |z| ≥ 3.5 marks a month as unusual [MET §4; CFG]. Because
2014 is the first baseline year, seasonal scoring starts in 2017 and 44 of the 80 months are
scored; unscored months are `NaN` ("insufficient history"), never "normal" [MET §4; TMP]. This
rule was adopted because July is the busiest calendar month overall (2,374 crimes over all years
[DSI]), and a non-seasonal baseline treats an established July peak as anomalous [RL 2026-10-01].

**Comparison rule.** The original causal 12-month rolling robust baseline (at least 6 prior bins)
is computed alongside and stored in `temporal_anomaly_method_comparison.csv` [CFG; PIPE]. In the
reference computation (Python port, not a MATLAB result) it flagged 2016-07 and 2019-07 [TMP;
RL 2026-09-30]. Neither rule uses the current or a future month, so both are replay-safe [MET §4].

**Sampling-noise floors.** A robust scale estimated from only 3–5 same-month values can fall far
below counting noise. For count series (crimes, new offenders) the scale is therefore floored at
the Poisson standard deviation √(baseline median); for the co-offending share the binomial
analogue √(p(1−p)/n_crimes) is used, with n_crimes the crimes in the bin
(`cfg.temporal.sampling_noise_floor = true`) [MET §4; CFG; PIPE]. Rationale: in the reference
computation on the real series the seasonal MAD scale was ≈ 7.4 crimes for monthly counts of
≈ 255–295, below the Poisson SD of ≈ 16, and three months (2018-09, 2019-05, 2019-12) reached
|z| ≥ 3.5 on ordinary fluctuation; with the floor, none were flagged [RL 2026-10-19; TMP]. These
are reference values to be confirmed by the MATLAB run. The floor assumes Poisson-or-wider monthly
variation, which overdispersed crime counts satisfy [RL 2026-10-19].

**Level shifts.** Penalized binary segmentation of the monthly crime count: segment cost = sum of
squared deviations from the segment mean; a split is accepted when its cost reduction exceeds
β = 2σ²·log n, with σ = 1.4826·MAD(diff(x))/√2 estimated from first differences so that a level
shift does not inflate it; minimum segment 6 months; at most 5 changes (Truong et al., 2020)
[MET §4; CFG; `src/temporal/detectChangePoints.m`].

**Entity rhythm.** Inter-event gap statistics, burstiness, dormancy ratio and busiest-30-day share
(features 4–9) [TMP; FE].

**Dynamic network.** Yearly windows 2014–2020 [CFG]; ties are active in a window when a shared
crime falls in it, new ties are first-ever shared crimes, persistence is the share of the previous
window's ties that are active again; the last window is cut at the series end and marked
`partial` [GRA; PIPE].

### 4.5 Spatial analysis

Coordinates are used only as relative positions in [0,1]² and are never converted to real-world
units [SPA; CFG]. Entity features are radius of gyration, mean/max step distance and repeated-site
share (features 10–13). At system level, crimes are counted on a 20 × 20 grid [CFG], and a
cell × year Poisson excess test compares observed counts with expected_{c,y} = N_c·N_y/N; the
one-sided p-value P(X ≥ observed) is computed with `gammainc`, and a cell-year is a hotspot when
p < 0.001 / (number of tested cell-years) (Bonferroni) [SPA; MET §5; CFG]. This highlights cells
whose activity in a year exceeds what their overall share predicts; it is a fixed-grid relative of
the space–time scan statistic (Kulldorff, 1997), without variable windows or Monte-Carlo inference
[SPA]. Location entropy and route similarity were not used because a median of one crime per
offender makes such estimates unstable [SPA].

### 4.6 Graph analysis

**Model: undirected, weighted.** Because all links are reciprocal with equal weights and the
weight equals the number of shared crimes, a directed graph would double-count ties and duplicate
features [GRA]. Ties are rebuilt from events; the 7,597 isolated offenders remain as degree-0 nodes
[GRA; DSI]. Node features: degree, strength, strongest tie, local clustering (sparse (A·A)∘A),
k-core number (batch peeling; verified against NetworkX on all 17,237 nodes in a Python port),
component size, unweighted betweenness (Brandes, bounded by component sizes of at most 518) and
articulation-point flag [GRA; AUD §5].

Not computed [GRA]: closeness (ill-defined across 10,468 components), PageRank (on an undirected
graph close to proportional to strength) and community detection (no built-in MATLAB routine;
components, k-core and cut vertices answer the structural questions for components of at most 518
nodes).

### 4.7 Sequence analysis

The artifact has no event type, so each event is encoded from two observable, causal properties
[SEQ]:

| Component | Values | Definition |
|---|---|---|
| partner state | S / R / N | solo; only partners already seen in the offender's **earlier** crimes; at least one new partner |
| move | 0 / L / F / U | first crime; step ≤ global median step (0.006586 normalized units); farther; missing coordinates |

Token = state + move, a fixed 12-symbol alphabet [SEQ]. Observed token counts in the reference
audit: S0 8,715 · N0 8,522 · SL 4,632 · SF 4,055 · RL 2,493 · NF 2,256 · RF 2,148 · NL 1,335 [SEQ].
A first-order Markov model with Laplace smoothing (α = 1) gives per-transition surprisal
−log₂ P(token_t | token_{t−1}); entity features are mean and maximum surprisal and the new-partner
rate [SEQ; CFG]. Contiguous trigrams (n = 3) within each offender's history are mined with
occurrences and support (distinct offenders); a trigram is frequent when support ≥ 5 [SEQ; CFG].
Full sequential pattern mining (e.g. gapped patterns) was not used because histories are short
(median 1, maximum 40 crimes) and the alphabet is small [SEQ]. Tokens describe partner novelty and
movement, not the kind of crime.

**Pattern mining** additionally reports recurring pairs (≥ 2 shared crimes), recurring exact
groups (the same set of ≥ 3 offenders in ≥ 2 crimes), emerging ties per window, space–time
concentrations and structural change points [PAT].

### 4.8 Anomaly detection protocol

| Step | Decision | Source |
|---|---|---|
| Eligibility | offender records with ≥ 3 crimes (`cfg.anomaly.min_events = 3`): 3,260 in the artifact; others are reported as *insufficient history* | [ANO; CFG; DSI] |
| Features | all six groups from the registry; ablation unit = group | [ANO; CFG] |
| Transform | `log1p` for heavy-tailed counts | [ANO; FE] |
| Scaling | median and 1.4826·MAD fit on the eligible population; MAD = 0 → 1.2533·mean absolute deviation; still 0 → drop the feature as constant | [ANO; MET §8] |
| Missing values | imputed at the reference median (z = 0) and recorded in `prep.imputed` | [ANO; FE] |
| Baseline | score = sqrt(mean(z²)), the RMS distance from the robust centre in robust-SD units; deterministic and exactly decomposable | [ANO] |
| Model | Isolation Forest (`iforest`), 200 trees, 256 observations per tree, `rng(42, "twister")`, `ContaminationFraction = 0`; scores in [0, 1], higher = easier to isolate | [ANO; CFG] |
| Threshold | review budget: top 1 % of the eligible population per detector, k = max(1, ceil(0.01·n)), i.e. 33 of 3,260 | [ANO; CFG; `applyReviewBudget.m`] |
| Comparison | Spearman rank correlation and top-k Jaccard between detectors (agreement = robustness evidence, not accuracy) | [ANO] |

Both detectors score the **same prepared matrix**. Scores are relative to this population and this
dataset. Without labels there is no statistically "correct" threshold, so the review budget is an
explicit, reported choice whose effect is studied in E8 [ANO]. A model is not selected by how many
anomalies it produces; the preference order is (1) sensitivity to injected deviations of every
feature group (E5–E7), (2) stability (E8), (3) interpretability [ANO]. LOF, One-Class SVM and Robust
Random Cut Forest were considered and not added because there is no evaluation signal that would
justify a third model [ANO; AUD §4].

### 4.9 Explainability

For every flagged entity and the top 100 by the primary detector (`cfg.anomaly.explain_top_k`)
[CFG; XAI]:

- per-feature robust z, raw value vs reference median, and a *notable* flag at |z| ≥ 3.5;
- the exact baseline share z_j² / Σz² (additive decomposition of the baseline score);
- the Isolation Forest occlusion delta: score − score(feature j reset to the reference median),
  per feature and per group, computed in one batched `isanomaly` call per level (cf. Siddiqui et
  al., 2019);
- a dominant feature group (largest group occlusion delta, or largest baseline group share when
  Isolation Forest is unavailable) [`explainAnomalies.m`];
- generated evidence text ending with the interpretation caveat: *"a statistical deviation from
  the reference population …; it is not evidence of guilt, intent or dangerousness."* [ETH §1].

Ineligible entities receive "Not scored: … below the minimum of 3 … not a statement that the
behaviour is normal" [XAI].

### 4.10 Evaluation protocol

**With published labels (network datasets).** The detectors are unsupervised and never see the
labels. After scoring, `evaluateGroundTruth` measures for each detector ROC-AUC, average precision
(AP) with its chance level (the positive rate), and precision and recall at k = number of
malicious scored hosts, in two settings: *known_only* (hosts with verified labels) and
*unknown_as_benign* (unlabelled hosts counted as negatives, conservative for precision). Malicious
hosts below the eligibility threshold are counted as `malicious_not_scored`, not hidden. E11
repeats this for every feature-group set of the ablation, which answers RQ1–RQ3 with real labels
instead of synthetic injections only [RUNEXP; NET].

**Without labels (case study).** No ground truth exists in the burglary artifact and none is
fabricated; therefore no precision, recall or ROC claims about real offender records are made
[EVA; CARD]. The experiments are [EXP]:

| ID | Question | Design |
|---|---|---|
| E1 | Does the raw artifact pass validation? | 37 checks with severities |
| E2 | How does the transparent baseline behave? | score quantiles, flagged count, dominant groups |
| E3 | How does Isolation Forest behave, and does it agree with the baseline? | same matrix, same budget; Spearman, top-k Jaccard |
| E4 | Which feature groups drive the ranking on real data? | 10 feature sets (each group alone, cumulative sets, full); ranking consistency with the full model |
| E5 | Is unusual temporal behaviour detected? | **SYNTHETIC** injection into the temporal group |
| E6 | Does network information improve detection? | **SYNTHETIC** injection into the graph group |
| E7 | Does sequence information improve detection? | **SYNTHETIC** injection into the sequence group |
| E8 | How sensitive are results? | seeds 1–10; NumLearners 50–400; NumObservationsPerLearner 64–512; min_events 2/3/5; budget 0.5–5 % |
| E9 | Runtime and memory | per-stage timings; bundle size |
| E10 | Can users interpret the system? | task-based usability study with 5–8 participants and SUS |
| E11 | How well does the ranking find the labelled malicious hosts, and which feature groups matter? | published labels joined after scoring; every ablation set × detector × setting; ROC-AUC, AP vs chance, precision@k |

Activity, spatial and co-offending injections run in the same synthetic grid and are reported
without separate numbers [EXP].

**Synthetic injection (E5–E7), clearly labelled SYNTHETIC.** From the prepared robust-z matrix of
the real eligible population, 1 % of rows are chosen at random (seeded); every feature of one
target group is moved 3 or 5 robust SD further from the median in the direction it already
deviates (random sign when z = 0); this is repeated 10 times with seeds 42 + repeat
[EVA; CFG; RUNEXP]. The baseline score is computed in the original clean robust frame. **Isolation
Forest is used in novelty-detection mode**: it is fitted on the clean real reference matrix and
scores the separately contaminated copy, so injected rows never contaminate training; this matches
MathWorks' guidance that `isanomaly` novelty detection uses uncontaminated training data
[EXP; ANO; RL 2026-10-01]. Metrics follow Campos et al. (2016): ROC-AUC, average precision (chance
level = injected fraction) and precision at m (m = number of injected rows) [EVA]. Limitations:
injected deviations are axis-aligned and group-coherent; results measure **sensitivity**, not
real-world accuracy; output files carry the prefix `synthetic_` [EVA].

**Reading ablations.** Graph and co-offending features both derive from shared-crime counts; a
graph-only model detecting a co-offending injection is expected and is not independent
confirmation [EXP].

**Usability (E10).** 5–8 participants (classmates), think-aloud, 3-minute introduction; tasks
T1–T5 (find the top-ranked record and its dominant group; explain it in one sentence without guilt
language; find the first co-offending tie by replay; judge whether an unusual month could be
seasonal; find an unscored record and explain why); SUS (10 items) plus one open question; model
performance and usability are reported separately [EVA]. The session script, assist ladder,
scoring rules (`scoreSUS`, `summarizeUsabilityLog`) and limitations (convenience sample, fixed task
order, English interface for Turkish-speaking participants, unvalidated Turkish SUS wording) are in
docs/USABILITY_STUDY.md [USE].

---

## 5 Multimedia system

### 5.1 Concept and implementation

The dataset has no audio or video, so the multimedia contribution is the **synchronized,
time-based, interactive presentation** of analytical evidence: linked views, animation along the
time axis (replay) and an optional audio cue; every visual element maps to an analytical output
[MM]. The application `app/NetworkBehaviorExplorer.m` is built programmatically from App
Designer's component family (`uifigure`, `uigridlayout`, `uiaxes`, `uitable`, `uislider`,
`uitabgroup`, `timer`) because a binary `.mlapp` is not diffable or reviewable in Git; callbacks
only call tested functions in `src/` [MM].

### 5.2 Views

| View | Content | Analytical source |
|---|---|---|
| Dashboard | counts, dates, validation status, eligible/flagged, agreement, unusual months, hotspots, patterns | bundle summary |
| Ranking table | flagged / top-200 IF / top-200 baseline / all eligible; ranks, scores, main group | `entities`, `explanations` |
| Network | 2-hop ego network (≤ 400 nodes); colour = score, size = crimes, width = shared crimes | `graph`, `plotEgoNetwork` |
| Timeline | monthly crimes, causal baseline, unusual months, change points, selected record's crimes, playback cursor | `temporal`, `plotActivityTimeline` |
| Spatial | normalized density, current-window crimes, selected record's numbered path (no basemap) | `spatial`, `plotSpatialView` |
| Why flagged | evidence text | `getEntityContext` |
| Deviation profile | robust-z bars by feature group with ±3.5 lines | `plotEvidenceBars` |
| Events | ordered crimes with token and surprisal | `events` |
| Partners | co-offenders, shared crimes, first/last date, their score | `relations` |
| Patterns | frequent/rare trigrams | `patterns.ngrams` |
| Detectors | baseline vs Isolation Forest scatter | `plotScoreComparison` |
| Data quality | validation checks | `validation` |

Source: [MM; GRA; CFG (`cfg.app.max_graph_nodes = 400`)].

### 5.3 Linked interaction

One selection — a ranking-table row, a network node or a partner row — drives the network,
timeline, map and every detail tab (brushing and linking; Becker & Cleveland, 1987). Navigation
follows overview → zoom/filter → details on demand (Shneiderman, 1996): dashboard and ranking,
then ego network and time window, then evidence and events [MM].

### 5.4 Replay

A slider with Play/Pause, Step, Reset and a window length in months; each step calls
`buildPlaybackFrame(bundle, tEnd, windowMonths)`, which returns the crimes, active ties and new
ties in [tEnd − window, tEnd) and whether the month is unusual. Ties appear at their first shared
crime, the map shows the window's crimes, the timeline cursor moves and unusual months are
labelled; one month per step at 0.8 s [MM; TMP]. Replay is possible only because relations were
time-stamped from shared crimes (Section 3.5).

### 5.5 Audio cue

An optional short 880 Hz tone sounds when the replay enters an unusual month. It is off by default
(`cfg.app.audio_cues = false`) and every audio event also has a visual label, so no information
depends on sound [MM; CFG]. Audio narration was considered and rejected as low in analytical value
[AUD §4].

### 5.6 Design rationale

- **Linked views** (Becker & Cleveland, 1987) let a user examine one offender record across time,
  space and network without re-selecting it.
- **Overview first, details on demand** (Shneiderman, 1996) structures the path from ranking to
  evidence.
- **Animation only where it is interactive and congruent** (Tversky et al., 2002): replay animates
  only what actually changes over time (ties appearing, activity moving) and is fully
  user-controlled; there is no decorative motion.
- **Evidence beside every score**: the "Why flagged" and deviation-profile tabs accompany every
  ranking, in line with the responsible-demo rules [ETH §7].

### 5.7 Export

"Export" writes PNGs of the network, timeline and map views and the entity's evidence text to
`outputs/`; report figures are regenerated by `scripts/generate_report_figures.m` with the same
plotting functions [MM; FIG].

**Status:** implemented, not yet executed; verification is the walkthrough in
docs/DEMO_SCENARIO.md and E10 [MM]. Screenshots: `[PENDING MATLAB RUN — do not fill by hand]`.

---

## 6 Results

> **No result in this section may be written by hand.** Every value comes from the files named in
> each subsection after `run scripts/run_pipeline.m`, `run scripts/run_experiments.m` and
> `run scripts/generate_report_figures.m` on a MATLAB machine (Appendix A). Record the MATLAB
> version, commit and date of the run here: `[PENDING MATLAB RUN — do not fill by hand]`.
> No ground truth exists; every results subsection must restate this. Refer to entities by rank or
> `entity_index`, never by `entity_id`.

Run metadata (seed, MATLAB version, feature version, `iforest_used`, number of eligible entities,
number of features, dropped features, agreement, timings) is written to
`outputs/experiments/pipeline_run.json` [PIPE]. The experiments write
`outputs/experiments/experiments_summary.md` [RUNEXP].

### 6.1 E1 — Data quality

**Reported:** overall validity, failed error/warning checks, observed info checks, summary facts.
**Produced by:** `outputs/reports/validation_report.md`, `outputs/reports/validation_report.json`,
`outputs/reports/validation_checks.csv` (pipeline, `writeValidationReport`) and
`outputs/experiments/E1_validation_checks.csv` (`runExperiments`) [PIPE; RUNEXP].

Table 6.1a — check results (`E1_validation_checks.csv`; one row per check, 37 rows).

| check_id | category | severity | passed | affected | message |
|---|---|---|---|---|---|
| … | … | … | … | … | … |

`[PENDING MATLAB RUN — do not fill by hand]`

Table 6.1b — validation summary (`validation_report.json` → `summary`). The right-hand column
holds the values verified by the **reference audit (Python), to be confirmed by MATLAB**
[DSI; AUD; REP §4]; the MATLAB column must be filled from the file.

| Summary field | MATLAB value | Reference audit (Python), to be confirmed by MATLAB |
|---|---|---|
| `node_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 17,237 |
| `link_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 21,302 |
| `undirected_relation_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 10,651 |
| `event_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 34,156 |
| `unique_crime_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 24,087 |
| `isolated_node_count` | `[PENDING MATLAB RUN — do not fill by hand]` | 7,597 |
| `symmetric_links` | `[PENDING MATLAB RUN — do not fill by hand]` | true (all links reciprocal) |
| `weight_equals_shared_crimes` | `[PENDING MATLAB RUN — do not fill by hand]` | true |
| `day_resolution_only` | `[PENDING MATLAB RUN — do not fill by hand]` | true (0 of 34,156 non-midnight) |
| `day1_excess_ratio` | `[PENDING MATLAB RUN — do not fill by hand]` | +17.7 % rows on day 1 vs days 2–28 |
| `date_min` / `date_max` | `[PENDING MATLAB RUN — do not fill by hand]` | 2010-12-01 / 2020-09-28 |
| `events_before_series_start` | `[PENDING MATLAB RUN — do not fill by hand]` | 91 |

Expected outcome stated in the runbook (an expectation, not a result): `is_valid = true`, no
warnings, info observations as in docs/DATASET_SCHEMA_INSPECTION.md [REP §4].

### 6.2 E2 — Robust baseline behaviour

**Reported:** baseline score distribution over the eligible population, number flagged under the
budget, baseline threshold, dominant feature groups among flagged entities.
**Produced by:** `outputs/experiments/E2_E3_score_quantiles.csv`,
`outputs/experiments/E2_E3_dominant_groups.csv`, section "E2/E3" of `experiments_summary.md`,
`outputs/experiments/entity_features_scores.csv` [RUNEXP; PIPE].

Table 6.2a — score quantiles (`E2_E3_score_quantiles.csv`; quantiles 0, 0.25, 0.5, 0.75, 0.9, 0.99,
1 as defined in [RUNEXP]).

| quantile | baseline_score | iforest_score |
|---|---|---|
| 0 | `[PENDING]` | `[PENDING]` |
| 0.25 | `[PENDING]` | `[PENDING]` |
| 0.5 | `[PENDING]` | `[PENDING]` |
| 0.75 | `[PENDING]` | `[PENDING]` |
| 0.9 | `[PENDING]` | `[PENDING]` |
| 0.99 | `[PENDING]` | `[PENDING]` |
| 1 | `[PENDING]` | `[PENDING]` |

`[PENDING MATLAB RUN — do not fill by hand]`

Table 6.2b — summary line values (`experiments_summary.md`, section E2/E3).

| Quantity | Value |
|---|---|
| Eligible entities (of 17,237) | `[PENDING MATLAB RUN — do not fill by hand]` (reference audit (Python), to be confirmed by MATLAB: 3,260 offenders with ≥ 3 crimes [DSI]) |
| Features used / dropped as constant | `[PENDING MATLAB RUN — do not fill by hand]` |
| Entities per detector under the 1 % budget | `[PENDING MATLAB RUN — do not fill by hand]` |
| Baseline threshold | `[PENDING MATLAB RUN — do not fill by hand]` |

Figure: `outputs/figures/fig_top_entity_evidence.png` (deviation profile of the top-ranked entity)
[FIG] — `[PENDING MATLAB RUN — do not fill by hand]`.

### 6.3 E3 — Isolation Forest behaviour and agreement

**Reported:** Isolation Forest score distribution and threshold; agreement with the baseline
(Spearman ρ and top-k Jaccard at the budget k); dominant groups among entities flagged by either
detector.
**Produced by:** same files as E2; `agreement` in `pipeline_run.json`;
`outputs/experiments/anomaly_explanations.csv`, `outputs/experiments/anomaly_evidence_long.csv`
[RUNEXP; PIPE].

Table 6.3a — agreement.

| Quantity | Value |
|---|---|
| Isolation Forest threshold | `[PENDING MATLAB RUN — do not fill by hand]` |
| Spearman ρ (baseline vs IF, eligible population) | `[PENDING MATLAB RUN — do not fill by hand]` |
| Top-k Jaccard (k = budget) | `[PENDING MATLAB RUN — do not fill by hand]` |

Table 6.3b — dominant feature group among entities flagged by either detector
(`E2_E3_dominant_groups.csv`).

| dominant_group | flagged_entities |
|---|---|
| … | … |

`[PENDING MATLAB RUN — do not fill by hand]`

Figures: `outputs/figures/fig_detector_agreement.png` (baseline vs IF scatter),
`outputs/figures/fig_top_entity_network.png` (2-hop ego network of the top-ranked entity, no
identifier labels) [FIG] — `[PENDING MATLAB RUN — do not fill by hand]`.

### 6.4 E4 — Feature-group ablation on real data (ranking consistency)

**Reported:** for each of 10 feature sets, the number of features used and the consistency of its
ranking with the full model, for both detectors. This is consistency, not accuracy.
**Produced by:** `outputs/experiments/E4_ablation_real_ranking_consistency.csv` [RUNEXP].

Table 6.4 — feature sets as defined in `ablationSets()` [RUNEXP].

| feature_set | n_features | baseline_topk_jaccard_vs_full | baseline_spearman_vs_full | iforest_topk_jaccard_vs_full | iforest_spearman_vs_full |
|---|---|---|---|---|---|
| activity | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| spatial | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| cooffending | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| activity+temporal | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| activity+temporal+graph | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| activity+temporal+graph+sequence | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| activity+temporal+spatial+cooffending+graph+sequence | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |

`[PENDING MATLAB RUN — do not fill by hand]`

Reading note: graph and co-offending features share their source (Section 3.5), so their
individual consistency values are not independent [EXP].

### 6.5 E5 — SYNTHETIC temporal injection

**Reported (SYNTHETIC — sensitivity, not real-world accuracy):** mean ± SD ROC-AUC, mean average
precision and mean precision at m over 10 repeats, for temporal injections of 3 and 5 robust SD,
for each feature set and detector. Chance AP equals the injected fraction (0.01 [CFG]).
**Produced by:** `outputs/experiments/synthetic_E5_E7_injection_summary.csv` (aggregated) and
`outputs/experiments/synthetic_E5_E7_injection_raw.csv` (per repeat; columns `injected_group,
shift_sd, repeat, feature_set, detector, roc_auc, average_precision, precision_at_m`) [RUNEXP].

Table 6.5 — rows with `injected_group = temporal` (all 10 feature sets × 2 shifts × 2 detectors in
the file; the minimum to report is the injected group alone and the full set).

| injected_group | shift_sd | feature_set | detector | roc_auc_mean | roc_auc_sd | ap_mean | precision_at_m_mean |
|---|---|---|---|---|---|---|---|
| temporal | 3 | temporal | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 3 | temporal | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 3 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 3 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 5 | temporal | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 5 | temporal | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 5 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | 5 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| temporal | … | graph / cooffending (static sets) | … | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |

"full set" = `activity+temporal+spatial+cooffending+graph+sequence`.
`[PENDING MATLAB RUN — do not fill by hand]`

### 6.6 E6 — SYNTHETIC graph injection

Same design, files and columns as E5 with `injected_group = graph`; Isolation Forest is fitted on
the clean reference rows and scores the injected sample [EXP; RUNEXP].

| injected_group | shift_sd | feature_set | detector | roc_auc_mean | roc_auc_sd | ap_mean | precision_at_m_mean |
|---|---|---|---|---|---|---|---|
| graph | 3 | graph | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 3 | graph | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 3 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 3 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 5 | graph | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 5 | graph | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 5 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| graph | 5 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |

`[PENDING MATLAB RUN — do not fill by hand]`

### 6.7 E7 — SYNTHETIC sequence injection

Same design, files and columns as E5 with `injected_group = sequence` [EXP; RUNEXP].

| injected_group | shift_sd | feature_set | detector | roc_auc_mean | roc_auc_sd | ap_mean | precision_at_m_mean |
|---|---|---|---|---|---|---|---|
| sequence | 3 | sequence | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 3 | sequence | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 3 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 3 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 5 | sequence | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 5 | sequence | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 5 | full set | baseline | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |
| sequence | 5 | full set | iforest | `[PENDING]` | `[PENDING]` | `[PENDING]` | `[PENDING]` |

`[PENDING MATLAB RUN — do not fill by hand]`

Activity, spatial and co-offending injections are in the same summary file and may be reported in
an appendix table: `[PENDING MATLAB RUN — do not fill by hand]`.

### 6.8 E8 — Sensitivity and stability

**Reported:** stability of the Isolation Forest top-k across seeds; overlap and rank correlation
with the default run when NumLearners, NumObservationsPerLearner and min_events change;
baseline-vs-IF overlap at each review budget.
**Produced by:** `outputs/experiments/E8_sensitivity.csv`; interpretation of each column is given
in the E8 section of `experiments_summary.md` [RUNEXP].

| parameter | value | topk_jaccard | min_jaccard | spearman |
|---|---|---|---|---|
| seed | pairwise over seeds (1–10) | `[PENDING]` | `[PENDING]` | – |
| num_learners | 50 | `[PENDING]` | – | `[PENDING]` |
| num_learners | 100 | `[PENDING]` | – | `[PENDING]` |
| num_learners | 200 | `[PENDING]` | – | `[PENDING]` |
| num_learners | 400 | `[PENDING]` | – | `[PENDING]` |
| num_obs | 64 | `[PENDING]` | – | `[PENDING]` |
| num_obs | 128 | `[PENDING]` | – | `[PENDING]` |
| num_obs | 256 | `[PENDING]` | – | `[PENDING]` |
| num_obs | 512 | `[PENDING]` | – | `[PENDING]` |
| min_events | 2 (eligible `[PENDING]`) | `[PENDING]` | – | `[PENDING]` |
| min_events | 3 (eligible `[PENDING]`) | `[PENDING]` | – | `[PENDING]` |
| min_events | 5 (eligible `[PENDING]`) | `[PENDING]` | – | `[PENDING]` |
| budget | 0.005 (thresholds `[PENDING]`) | `[PENDING]` | – | – |
| budget | 0.01 (thresholds `[PENDING]`) | `[PENDING]` | – | – |
| budget | 0.02 (thresholds `[PENDING]`) | `[PENDING]` | – | – |
| budget | 0.05 (thresholds `[PENDING]`) | `[PENDING]` | – | – |

"–" marks cells the code writes as `NaN` by design [RUNEXP]. Reference audit (Python), to be
confirmed by MATLAB: offenders with ≥ 2 / ≥ 3 / ≥ 5 crimes = 5,791 / 3,260 / 1,395 [DSI], which
are the expected eligible counts for min_events 2 / 3 / 5.
`[PENDING MATLAB RUN — do not fill by hand]`

### 6.9 E9 — Runtime and memory

**Reported:** seconds per pipeline stage and bundle memory.
**Produced by:** `outputs/experiments/E9_performance.csv` (from `bundle.meta.timings`) and
`timings` in `pipeline_run.json` [RUNEXP; PIPE].

| stage | seconds |
|---|---|
| load | `[PENDING]` |
| flatten | `[PENDING]` |
| validate | `[PENDING]` |
| relations | `[PENDING]` |
| graph | `[PENDING]` |
| behavior | `[PENDING]` |
| sequence | `[PENDING]` |
| temporal | `[PENDING]` |
| spatial | `[PENDING]` |
| dynamic_graph | `[PENDING]` |
| patterns | `[PENDING]` |
| anomaly | `[PENDING]` |
| explain | `[PENDING]` |
| bundle_memory_MB | `[PENDING]` (MB, not seconds) |

Machine specification (CPU, RAM, OS, MATLAB release): `[TO FILL]`. Total experiment runtime (printed
by `run_experiments.m`): `[PENDING MATLAB RUN — do not fill by hand]`.

### 6.10 E10 — Usability study

**Reported:** per-task n, success rate, median time, mean assists and mean errors for T1–T5; the T2
rubric outcome (explanations with ≥ 2 deviations; explanations with guilt language); per-participant
SUS scores and their summary; usability issues by severity; open-question themes. Reported
separately from model results; state n, the convenience sample, the absence of significance tests
and the translation caveat [EVA; USE §10, §13].
**Produced by:** `outputs/usability/observation_log.csv` → `summarizeUsabilityLog`, and
`outputs/usability/sus_responses.csv` → `scoreSUS` (both git-ignored; the pilot `P00` is excluded);
protocol and forms in docs/USABILITY_STUDY.md and docs/usability/ [USE].

Sessions run: `[TO FILL]` · participants analysed: n = `[TO FILL]` · pilot excluded: `[TO FILL]` ·
app commit: `[TO FILL]`

| Task | n | Success rate | Median time (s) | Mean assists | Mean errors |
|---|---|---|---|---|---|
| T1 | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |
| T2 | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |
| T3 | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |
| T4 | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |
| T5 | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |

| SUS | n | Mean | SD | Median | Min | Max | Incomplete |
|---|---|---|---|---|---|---|---|
| All participants | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` | `[PENDING STUDY]` |

| Issue | Participants affected | Severity | Proposed fix |
|---|---|---|---|
| `[PENDING STUDY]` | | | |

T2 rubric: explanations with ≥ 2 concrete deviations `[PENDING STUDY]`; explanations with guilt
language `[PENDING STUDY]`. Per-participant SUS strip plot: `[PENDING STUDY]`.
`[PENDING STUDY — do not fill by hand]`

### 6.10b E11 — Detection against published labels (network datasets)

**Produced by** `runExperiments` → `E11_ground_truth_by_feature_set.csv`; the full-model rows also
in `outputs/datasets/<id>/tables/ground_truth_evaluation.csv` and in the app's "Ground truth" tab
[RUNEXP; PIPE].

| Dataset | Feature set | Detector | Setting | n scored | n malicious | ROC-AUC | AP | chance AP | P@k | malicious not scored |
|---|---|---|---|---|---|---|---|---|---|---|
| CTU-13 `[scenario]` | full | baseline | known_only | `[PENDING DOWNLOAD + MATLAB RUN — do not fill by hand]` | | | | | | |
| CTU-13 `[scenario]` | full | Isolation Forest | known_only | `[PENDING]` | | | | | | |
| CTU-13 `[scenario]` | network | both | known_only | `[PENDING]` | | | | | | |
| CTU-13 `[scenario]` | full | both | unknown_as_benign | `[PENDING]` | | | | | | |
| CIC-IDS2017 / UNSW-NB15 (optional) | full | both | known_only | `[PENDING]` | | | | | | |

Interpretation rule: an AP clearly above its chance level means the unsupervised ranking places
labelled malicious hosts near the top; a CTU-13 scenario usually contains only one or a few
infected hosts, so precision at k is coarse and AP/ROC-AUC with their counts must be reported
together.

### 6.11 Supporting real-data analyses (not numbered experiments)

**Produced by** the pipeline [PIPE; RUNEXP; FIG]:

| Analysis | File | Columns |
|---|---|---|
| Monthly series | `outputs/experiments/monthly_activity_series.csv` | `bin_start, crimes, active_offenders, new_offenders, cooffending_share, mean_group_size` |
| Rolling vs seasonal flags | `outputs/experiments/temporal_anomaly_method_comparison.csv` | `bin_start, rolling_flag, seasonal_flag` |
| Unusual months and change points | `experiments_summary.md`, section "Real temporal findings" | text |
| Space–time hotspots | `outputs/experiments/spacetime_hotspots.csv` | `cell_row, cell_col, year, crimes, expected, ratio, p_value, is_hotspot` |
| Dynamic network | `outputs/experiments/dynamic_graph_yearly.csv` | `window_start, window_end, window_days, partial, active_offenders, edges, new_edges, persistent_edges, edge_persistence, edge_jaccard, components, largest_component, mean_degree` |
| Sequence trigrams | `outputs/experiments/sequence_ngrams.csv` | `ngram, occurrences, support, is_frequent` |

Figures: `fig_temporal_activity.png`, `fig_spatial_density.png`, `fig_dynamic_graph.png`,
`fig_degree_distribution.png` in `outputs/figures/` [FIG].

Unusual months (seasonal production rule): `[PENDING MATLAB RUN — do not fill by hand]`.
Unusual months (rolling comparison rule): `[PENDING MATLAB RUN — do not fill by hand]`.
Change points: `[PENDING MATLAB RUN — do not fill by hand]`.
Space–time hotspots: `[PENDING MATLAB RUN — do not fill by hand]`.
Dynamic network by year: `[PENDING MATLAB RUN — do not fill by hand]`.
Frequent and rare trigrams: `[PENDING MATLAB RUN — do not fill by hand]`.

---

## 7 Discussion

All statements in this section are conditional: they define what a result would mean, not what the
result is. They are to be rewritten once Section 6 is filled. For the network datasets each RQ is
answered first with E11 (real labels) and then with E4–E8; synthetic results support but never
replace labelled evidence.

### 7.1 RQ1 — Which features separate baseline from anomalous behaviour?

*Evidence (network):* E11 — AP and ROC-AUC of each single-group set (e.g. `network` alone vs
`graph` alone) against the labels. *Evidence (all):* E2/E3 dominant groups, E4 ranking
consistency, E5–E7 per-group sensitivity.
*Supporting pattern:* one or few groups appear as dominant among flagged entities **and** a
ranking built from those groups alone is highly consistent with the full model (E4). *Weakening
pattern:* dominant groups are spread evenly and no single-group set reproduces the full ranking,
which would indicate that unusualness is a combination of groups. *Caveat:* graph and co-offending
groups share their source, so their joint prominence counts as one signal, not two. Without labels
"separates" means "drives the ranking", not "correctly identifies".

### 7.2 RQ2 — Does temporal context improve detection over static network features?

*Evidence (network):* E11 rows with and without the temporal group; `beacon_cv_min` is a
temporal-regularity feature inside the network group and is reported separately in the evidence
tables. *Evidence (all):* E5 (synthetic temporal injection) across feature sets; E4 rows `activity+temporal` and
`activity+temporal+graph` vs `graph`/`cooffending`.
*Supporting pattern:* sets containing the temporal group detect temporal injections clearly above
chance AP (0.01), while static-only sets (graph, co-offending) stay near chance; on real data,
adding the temporal group changes the full-model ranking materially (lower consistency of the
graph-only set). *Weakening pattern:* static-only sets already rank temporal injections well,
which would mean the temporal deviations are reflected in static counts. *Caveat:* a set that
contains the injected group is expected to detect it; the informative comparison is how much
detection degrades without it, and whether the full set dilutes the signal.

### 7.3 RQ3 — Does combining node-level and edge-level features improve detection?

*Evidence (network):* E11 `network+graph` vs `network` vs `graph`. *Evidence (all):* E4 and E6. In this design, edge-level information enters as node-level aggregates of
tie attributes (`strength`, `max_tie_weight`, `repeat_partner_fraction`, `new_partner_rate`) and
as relation-level outputs (recurring pairs, tie first/last dates, dynamic ties); there is no
separate edge-level detector. *Supporting pattern:* the full set detects graph injections at least
as well as the graph set alone and adds sensitivity to other groups. *Weakening pattern:* adding
groups dilutes graph-injection detection. The question can therefore only be answered partially;
an edge-level anomaly model is future work.

### 7.4 RQ4 — Can repeated or sequential patterns explain a flag?

*Evidence:* E7 (sensitivity to sequence injections), evidence tables (`anomaly_evidence_long.csv`)
where sequence features are notable, the Events and Patterns tabs, and E10 task T2.
*Supporting pattern:* among flagged entities, sequence features (surprisal, new-partner rate) are
notable for a non-trivial share, and participants cite concrete transitions or recurring partners
when explaining a flag. *Weakening pattern:* sequence features are rarely notable or the occlusion
deltas of the sequence group are small. *Caveat:* tokens describe partner novelty and movement,
not crime type.

### 7.5 RQ5 — Is interactive multimedia more effective than tables alone?

*Evidence:* E10. *Supporting pattern:* participants complete T1–T5 correctly within reasonable
times and the SUS score is acceptable; T3 (replay) and T4 (seasonality) are the tasks where tables
alone would be weakest. *Limitation of the design:* the E10 protocol as documented has no
tables-only control condition, so it can show that the application is usable and interpretable but
cannot by itself establish that it is *more* effective than tables `[TO DECIDE: add a tables-only
condition or restate RQ5]`.

### 7.6 Cross-cutting interpretation rules

- Detector agreement (E3, E8) is robustness evidence, not accuracy; entities flagged by only one
  detector deserve extra caution [ETH §3].
- The review budget guarantees that some entities are flagged even if nothing is truly unusual
  [ETH §3].
- Temporal peaks in solved-case data can reflect case-solving and reporting processes [TMP].

---

## 8 Ethics and limitations

### 8.1 Nature of the system

An analysis and visualization system for statistical deviations in an anonymized research dataset;
not a law-enforcement decision engine, not a risk-assessment instrument and not a predictor of
offending [ETH §1]. Allowed wording: anomaly, behavioural deviation, unusual pattern, "deviates by
x robust SD from the reference median", "insufficient history". Not allowed: "criminal", "guilty",
"dangerous", "proves", "identifies the perpetrator", or treating unscored entities as "normal"
[ETH §1]. A test guards that generated evidence text ends with the interpretation caveat
[ETH §1].

### 8.2 Anomaly ≠ wrongdoing; false positives

Every record is a solved case; scores describe recorded patterns relative to other recorded
offender records with at least three cases, and can reflect data artefacts [ETH §2]. Real
false-positive rates are unknown; synthetic results measure sensitivity only; flags are prompts
for inspection, not findings [ETH §3].

### 8.3 Network-centrality caveats

Criminal-network data are incomplete, have fuzzy boundaries and change over time (Sparrow, 1991).
Here the graph contains only co-offending recorded in solved cases: high degree or betweenness can
reflect police attention and solving rates; a missing edge may be an unsolved joint offence;
articulation points and betweenness are sensitive to single missing edges in small components
(largest: 518 offenders [DSI]); graph and co-offending features are not independent corroboration.
Centrality is never described as "leadership" or "importance" [ETH §4].

### 8.4 Privacy

Network datasets: IP addresses and computer names are pseudonymized on import and never stored in
the flow table, bundle, reports or figures; the address map is written only on request, outside
the bundle and git-ignored [NET]. Case study: pseudonymous identifiers only; no re-identification, no external joins, no de-normalized
coordinates, no basemap; spatial views labelled "normalized"; reports contain aggregates or
pseudonyms only; raw data not committed; report figures produced by the figure script without
identifier labels [ETH §5].

### 8.5 Methodological limitations

| Limitation | Consequence | Mitigation / status |
|---|---|---|
| Day-resolution dates | no time-of-day analysis; same-day order is a convention | order = numeric crime ID |
| Solved cases, right-censored at the end | recent declines are artefacts | series ends 2020-08 |
| Sparse pre-2014 data | no reliable baseline before 2014 | excluded from system series (V45) |
| 66 % of offenders have one case | most cannot be profiled | eligibility ≥ 3 crimes, "insufficient history" |
| Seasonality | a non-seasonal baseline flags July peaks | seasonal same-month baseline in production; rolling kept for comparison; 2014–2016 unscored |
| Small seasonal reference sets | unstable robust scale | Poisson/binomial noise floor |
| Normalized coordinates of unknown extent | distances are relative, not metres | never interpreted as distances |
| Derived event alphabet | sequences describe partner novelty and movement, not crime type | stated wherever shown |
| Transductive scoring | scores are relative to this dataset | temporal hold-out is future work |
| No labels | no accuracy claims | synthetic injection + stability, labelled |
| Network: benchmark captures, partly synthetic (UNSW-NB15, CIC-IDS2017) | results do not transfer to other networks | stated with every number |
| Network: most CTU-13 traffic unlabelled | precision can only be bounded | known_only and unknown_as_benign reported |
| Network: label errors (CIC-IDS2017) | evaluation noise | CTU-13 primary; CIC secondary |
| Network: layouts of CIC/UNSW/LANL verified from documentation only | first import may need fixes | content checks; profile `verified` notes |
| Not yet executed in MATLAB | no result is verified | Appendix A gate |

Sources: [ETH §6; TMP; MET §4; README].

### 8.6 Responsible demonstration

Say "unusual traffic pattern of host ENT…", not "attacker" or "infected"; say "the published
label of this host is …" only after showing the score and evidence; say "unusual record pattern", not "suspect"; show the evidence tab whenever showing a score;
mention the eligibility rule and the review budget; no raw identifiers on slides [ETH §7].

---

## 9 Conclusion and future work

### 9.1 Conclusion (conditional)

The project delivers a reproducible MATLAB pipeline from a pinned, validated artifact to ranked,
explained and interactively presented record patterns, together with an evaluation protocol that
does not depend on labels. Whether the detectors are sensitive to every feature group, stable
across settings and interpretable to users is determined by E1–E10:
`[PENDING MATLAB RUN — summarise only after Section 6 is filled]`.

If E5–E7 show sensitivity well above chance for every group and E8 shows stable top-k sets, the
combination of transparent baseline and Isolation Forest is a defensible ranking tool for this
dataset. If sensitivity is uneven or rankings are unstable, the conclusion is that the evidence
layer (per-feature deviations) is more trustworthy than any single ranking, and the review budget
must be presented as an inspection aid only.

### 9.2 Future work

- Temporal hold-out (fit on earlier years, score later years) using the existing row mask in
  `fitTransitionModel` [FE; ETH §6].
- An edge-level or dynamic-graph anomaly model (RQ3).
- A tables-only control condition in the usability study (RQ5).
- Additional detectors only if E5–E8 reveal systematic blind spots [ANO].
- Exact assignment transcription (T-001) and alignment of the report with it.
- Turkish version of the final report.
- All thirteen CTU-13 scenarios and a cross-dataset comparison (train-free, so directly
  comparable); a temporal hold-out within a capture.
- Dataset-specific features where documented (e.g. CIC-IDS2017 flow statistics) — only after E11
  shows which generic features fail.

---

## References

Entries are copied from docs/SOURCE_INDEX.md. Entries marked **(m — to verify)** are standard
references cited from memory and must be checked before final submission [SI].

**Network datasets** (m — to verify bibliographic details before submission)

- García, S., Grill, M., Stiborek, J., & Zunino, A. (2014). An empirical comparison of botnet
  detection methods. *Computers & Security*, 45, 100–123. Dataset: https://stratosphereips.org/datasets-ctu13
- Sharafaldin, I., Habibi Lashkari, A., & Ghorbani, A. A. (2018). Toward generating a new intrusion
  detection dataset and intrusion traffic characterization. *Proc. ICISSP 2018*, 108–116.
  Dataset: https://www.unb.ca/cic/datasets/ids-2017.html
- Moustafa, N., & Slay, J. (2015). UNSW-NB15: a comprehensive data set for network intrusion
  detection systems. *Proc. MilCIS 2015*. Dataset: https://research.unsw.edu.au/projects/unsw-nb15-dataset
- Kent, A. D. (2015). *Comprehensive, Multi-Source Cyber-Security Events*. Los Alamos National
  Laboratory. https://csr.lanl.gov/data/cyber1/
- Engelen, G., Rimmer, V., & Joosen, W. (2021). Troubleshooting an intrusion detection dataset: the
  CICIDS2017 case study. *IEEE Security and Privacy Workshops (SPW)*.
- CICIDS2017 flow-error study (2022), SciTePress, https://www.scitepress.org/Papers/2022/107740/107740.pdf
  (authors and title to be copied from the paper).

**Case-study dataset**

- Ahmadi, Z., Nguyen, H. H., Zhang, Z., Bozhkov, D., Kudenko, D., Jofre, M., Calderoni, F.,
  Cohen, N., & Solewicz, Y. (2023). Inductive and transductive link prediction for criminal
  network analysis. *Journal of Computational Science*, 72, 102063.
  https://doi.org/10.1016/j.jocs.2023.102063
- Criminal Network Analysis and Visualization (GitHub, ROXANNE).
  https://github.com/erichoang/criminal-network-visualization
- Dataset documentation.
  https://github.com/erichoang/criminal-network-visualization/blob/main/datasets/preprocessed/README.md

**Software documentation**

- MathWorks. App Designer. https://www.mathworks.com/help/matlab/ref/appdesigner.html
- MathWorks. `iforest` / `isanomaly`. https://www.mathworks.com/help/stats/iforest.html
- MathWorks. `jsondecode`. https://www.mathworks.com/help/matlab/ref/jsondecode.html

**Literature**

- Akoglu, L., Tong, H., & Koutra, D. (2015). Graph based anomaly detection and description: a
  survey. *Data Mining and Knowledge Discovery*, 29(3), 626–688.
  https://doi.org/10.1007/s10618-014-0365-y
- Batagelj, V., & Zaversnik, M. (2003). An O(m) algorithm for cores decomposition of networks.
  arXiv:cs/0310049. **(m — to verify)**
- Becker, R. A., & Cleveland, W. S. (1987). Brushing scatterplots. *Technometrics*, 29(2),
  127–142. **(m — to verify)**
- Brooke, J. (1996). SUS: a "quick and dirty" usability scale. In *Usability Evaluation in
  Industry*, 189–194. **(m — to verify)**
- Campos, G. O., Zimek, A., Sander, J., et al. (2016). On the evaluation of unsupervised outlier
  detection: measures, datasets, and an empirical study. *Data Mining and Knowledge Discovery*,
  30(4), 891–927. https://doi.org/10.1007/s10618-015-0444-8
- Emmott, A. F., Das, S., Dietterich, T., Fern, A., & Wong, W.-K. (2013). Systematic construction
  of anomaly detection benchmarks from real data. *ODD '13 (KDD workshop)*.
  https://doi.org/10.1145/2500853.2500858
- Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*,
  40(1), 35–41. **(m — to verify)**
- Goh, K.-I., & Barabási, A.-L. (2008). Burstiness and memory in complex systems. *EPL*, 81(4),
  48002. https://doi.org/10.1209/0295-5075/81/48002
- González, M. C., Hidalgo, C. A., & Barabási, A.-L. (2008). Understanding individual human
  mobility patterns. *Nature*, 453, 779–782. https://doi.org/10.1038/nature06958
  **(m — to verify)**
- Hyndman, R. J., & Fan, Y. (1996). Sample quantiles in statistical packages. *The American
  Statistician*, 50(4), 361–365. **(m — to verify)**
- Iglewicz, B., & Hoaglin, D. C. (1993). *How to Detect and Handle Outliers*. ASQC Basic
  References in Quality Control, Vol. 16.
- Kulldorff, M. (1997). A spatial scan statistic. *Communications in Statistics – Theory and
  Methods*, 26(6), 1481–1496. **(m — to verify)**
- Liu, F. T., Ting, K. M., & Zhou, Z.-H. (2008). Isolation Forest. *ICDM 2008*, 413–422.
  https://doi.org/10.1109/ICDM.2008.17
- Shneiderman, B. (1996). The eyes have it: a task by data type taxonomy for information
  visualizations. *IEEE Symposium on Visual Languages*, 336–343. **(m — to verify)**
- Siddiqui, M. A., Fern, A., Dietterich, T. G., & Wong, W.-K. (2019). Sequential feature
  explanations for anomaly detection. *ACM TKDD*, 13(1), 1–22. https://doi.org/10.1145/3230666
- Sparrow, M. K. (1991). The application of network analysis to criminal intelligence: an
  assessment of the prospects. *Social Networks*, 13(3), 251–274.
- Truong, C., Oudre, L., & Vayatis, N. (2020). Selective review of offline change point detection
  methods. *Signal Processing*, 167, 107299. https://doi.org/10.1016/j.sigpro.2019.107299
- Tversky, B., Morrison, J. B., & Bétrancourt, M. (2002). Animation: can it facilitate?
  *International Journal of Human-Computer Studies*, 57(4), 247–262.
  https://doi.org/10.1006/ijhc.2002.1017
- Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks.
  *Nature*, 393, 440–442. **(m — to verify)**

---

## Appendix A — Reproducibility commands

Requirements: MATLAB R2021b or newer (R2023b+ recommended; not yet verified on a specific release),
Statistics and Machine Learning Toolbox (Isolation Forest only; without it the pipeline runs
baseline-only), Java-enabled desktop for the hash check, about 1 GB free RAM; Python 3 only for the
optional reference audit [REP §1].

From MATLAB, with the repository root as the current folder [REP §2]:

```matlab
run scripts/download_dataset.m        % 1. acquire + verify blob SHA 3afe9cbb…
run scripts/check_dataset_presence.m  % 2. optional re-check
run scripts/run_tests.m               % 3. unit tests (fixtures; real-data tests if data present)
run scripts/run_pipeline.m            % 4. validate -> features -> analysis -> anomaly -> explain
run scripts/run_experiments.m         % 5. E1–E9 tables + experiments_summary.md (QUICK = true first)
run scripts/generate_report_figures.m % 6. report figures
run scripts/launch_app.m              % 7. interactive multimedia application
```

Dataset facts without MATLAB [REP §2]:

```bash
curl -L -o data/raw/israel_lea_inp_burglary_offender_id_network.json \
  https://raw.githubusercontent.com/erichoang/criminal-network-visualization/main/datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json
git hash-object data/raw/israel_lea_inp_burglary_offender_id_network.json   # expect 3afe9cbb4e313fb056f1b115c92a3f750f4698b9
python3 scripts/reference/audit_dataset_reference.py --graph
```

**Filling Section 6.** After step 6, copy values only from the files named in each subsection,
record MATLAB version, commit and date at the top of Section 6, and log the run in
docs/RESEARCH_LOG.md [REP §4]. The full synthetic grid is about 6 groups × 2 shifts × 10 repeats ×
10 sets [EXP].

## Appendix B — Configuration

Key parameters from `configs/projectConfig.m` [CFG].

| Parameter | Value | Purpose |
|---|---|---|
| `project.version` / `project.feature_version` | 0.2.0 / F2 | versioning |
| `data.expected_blob_sha` | `3afe9cbb4e313fb056f1b115c92a3f750f4698b9` | dataset identity |
| `data.min_plausible_date` / `max_plausible_date` | 2000-01-01 / 2021-12-31 | validation only (V44) |
| `temporal.series_start` / `series_end` (exclusive) | 2014-01-01 / 2020-09-01 | system series window |
| `temporal.bin` | month | series resolution |
| `temporal.anomaly_method` | `seasonal_same_month` | production unusual-month rule |
| `temporal.baseline_window` / `min_baseline_bins` | 12 / 6 | rolling comparison rule |
| `temporal.seasonal_lookback_years` / `seasonal_min_samples` | 5 / 3 | seasonal rule |
| `temporal.sampling_noise_floor` | true | Poisson / binomial scale floor |
| `temporal.robust_z_threshold` | 3.5 | unusual month (Iglewicz & Hoaglin, 1993) |
| `temporal.burst_window_days` | 30 | `peak_window_share` |
| `temporal.changepoint_min_segment` / `changepoint_max_changes` | 6 / 5 | change points |
| `temporal.snapshot_years` | 2014–2020 | dynamic graph windows |
| `spatial.grid_size` | 20 | 20 × 20 grid over [0,1]² |
| `spatial.hotspot_alpha` | 0.001 | Bonferroni-adjusted Poisson upper tail |
| `spatial.local_move_quantile` | 0.5 | local/far split at the median step |
| `sequence.laplace_alpha` | 1 | Markov smoothing |
| `sequence.ngram_n` / `min_ngram_support` | 3 / 5 | trigrams; frequent if support ≥ 5 |
| `analysis.random_seed` | 42 | all seeded steps |
| `anomaly.min_events` | 3 | eligibility |
| `anomaly.feature_groups` | activity, temporal, spatial, cooffending, graph, sequence | full feature set |
| `anomaly.iforest.num_learners` | 200 | trees |
| `anomaly.iforest.num_observations_per_learner` | 256 | sub-sample (Liu et al., 2008) |
| `anomaly.review_budget_fraction` | 0.01 | top 1 % per detector |
| `anomaly.feature_z_threshold` | 3.5 | notable feature evidence |
| `anomaly.explain_top_k` | 100 | entities with occlusion attribution |
| `evaluation.synthetic_fraction` | 0.01 | injected share |
| `evaluation.synthetic_shift` | [3 5] | robust-SD shifts |
| `evaluation.synthetic_repeats` | 10 | repeats |
| `evaluation.stability_seeds` | 1:10 | E8 seeds |
| `evaluation.sensitivity.num_learners` | [50 100 200 400] | E8 |
| `evaluation.sensitivity.num_obs` | [64 128 256 512] | E8 |
| `evaluation.sensitivity.min_events` | [2 3 5] | E8 |
| `evaluation.sensitivity.budget` | [0.005 0.01 0.02 0.05] | E8 |
| `app.max_graph_nodes` | 400 | ego-network rendering cap |
| `app.audio_cues` | false | optional audio cue |
| `privacy.anonymized_data_only` / `reidentification` / `denormalize_coordinates` | true / false / false | privacy guards |
