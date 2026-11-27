# Network Behaviour Analysis

Open a supported connection file to inspect host activity, model rankings and
the measurements behind them. Selecting a host links its neighbourhood,
activity timeline, feature evidence and supporting flow records.

## Open data

Choose **Open dataset…**. CTU-13 uses `.binetflow`; supported tabular layouts
use CSV, TSV or TXT. Generic event tables need an entity and timestamp.
Connection tables need source, destination and timestamp. If column names are
not recognised, select their roles in the import dialog.

The importer leaves the source file unchanged. Saved analyses appear in the
dataset selector. If you analyse a slice of a large capture, retain its record
range with the run information.

## Inspect a host

Select a row in the ranking. The network shows its neighbours and the timeline
shows activity. Details include measured model scores and the strongest
feature deviations from the reference population. Supporting flows contain
time, direction, protocol, ports, duration, packets and bytes when available.
The view reports both the displayed count and total when it limits rows.

A high score means the host differs from the reference population; it is not
a probability of an attack. Published labels, when available, are evaluated
separately after scoring. Hosts with insufficient history are distinguished
from scored hosts.

## Replay and export

Use the time slider, window length and playback controls to inspect an
interval. Saved model scores describe the full analysis. Changing the replay
window does not retrain the model.

Check source fingerprints, record selection and software versions in the
provenance tab. **Export** saves views and the selected host's investigation:
CSV files contain measured evidence and supporting flows, and JSON records
the score scope and replay interval. Host names in exported observations are
local identifiers within that analysis.

## Language

Choose **Türkçe** or **English** in the header. The data and computed results
stay the same. Playback stops, and the selected host and time window remain
available for inspection.
