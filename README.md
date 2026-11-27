# Network Behaviour Explorer

A MATLAB application for investigating unusual host behaviour in network-flow
records. It combines network and temporal features, a statistical baseline,
Isolation Forest, linked visualizations and exportable evidence. Published
attack labels are used for evaluation after scoring, never as model inputs.

[Türkçe kullanım kılavuzu](docs/KULLANIM_KILAVUZU.md) · [English user guide](docs/USER_GUIDE_EN.md) · [شرح الكود والملفات](docs/CODE_GUIDE_AR.md)

[نقل النسخة الحالية إلى Windows وأوامر MATLAB](docs/WINDOWS_TRANSFER_AR.md)

[Öğretim üyesi için proje durumu ve çalıştırma](docs/PROJE_DURUMU_TR.md)

## Run the network case study

Requirements: MATLAB R2021b or later with Statistics and Machine Learning
Toolbox. Current changes require execution on the target MATLAB installation;
static analysis alone does not establish runtime compatibility.

Download the complete official CTU-13 scenario 7 flow file:

```sh
python3 scripts/data/acquire_ctu13_scenario7.py
```

Then, from the repository root in MATLAB:

```matlab
run scripts/run_network_demo.m
```

The command checks the source fingerprint, analyses the capture and opens the
application on the resulting bundle. No model scores are supplied in advance.

## Import a dataset

Use **Open dataset…** in the application or call:

```matlab
addpath scripts
setupProject()
b = analyzeDataset("data/external/capture.binetflow");
app = NetworkBehaviorExplorer(b);
```

Supported network layouts: CTU-13 binetflow, CIC-IDS2017 GeneratedLabelledFlows,
UNSW-NB15 with host/time columns, and LANL authentication/flow records.
Custom network-flow tables can use editable source/destination/time mappings, optional traffic fields and explicit timestamp units/formats. [Import a new dataset](docs/YENI_VERI_SETI.md).
Generic delimited event tables require an entity and timestamp; temporal edge
lists require source, destination and timestamp. Column mapping is available
when names are not detected. Arbitrary JSON, spreadsheets and packet captures
are not general import formats. See [dataset import](docs/DATASET_IMPORT.md).

## Investigate and export

Select a host to inspect its measured deviations, reference population,
network neighbourhood and supporting flow records. The provenance tab shows
data fingerprints and run context. Replay changes the observation window;
saved host scores describe the full analysed capture. Export includes figures,
measured feature evidence, bounded flow tables and a JSON investigation record.
A statistical deviation is not a probability of maliciousness.

## Data and evaluation

The official case study contains 114,077 flows and 38,204 hosts. Under the
recorded host-label mapping, one malicious and six benign hosts are eligible;
2,449 additional eligible hosts have unknown labels. These are independently
audited source counts, not MATLAB detector results. This small labelled
population limits conclusions from a single scenario.

[Source, hashes and audit](docs/REAL_CAPTURE_EVIDENCE.md) ·
[Technical report](docs/report/TECHNICAL_REPORT.md) ·
[Architecture](docs/ARCHITECTURE.md)

## Reproduce checks

```sh
python3 -m unittest discover -s tests/reference -p 'test_*.py' -v
mh_lint .
```

In MATLAB:

```matlab
addpath scripts
verify_delivery("data/external/ctu13-scenario7.binetflow")
```

Verification retains test results, source/configuration fingerprints and
experiment artifacts under `outputs/verification/`. It records failures and
incomplete runs explicitly. Interactive GUI acceptance is a separate check.
Current implementation and verification status: [task board](docs/TASKS.md).

Raw data, local identifiers and generated analytical outputs stay out of Git.
The earlier burglary-network case study remains available through
`scripts/run_pipeline.m`; it is separate from the computer-network case study.

## Presentation and test data

The presentation directory contains the complete official CTU-13 capture.
Upstream software-test samples were removed. The public launcher selects a
saved network analysis or opens an empty interface. It never generates data
when an analysis is missing. Default experiments and delivery verification
use observed data; explicitly requested research perturbations are isolated
under `research_synthetic/`. Unit-test fixtures remain in `tests/` and are not
a fallback data source for the application.
