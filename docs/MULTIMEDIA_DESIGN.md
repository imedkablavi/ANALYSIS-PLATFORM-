# Multimedia Design

The dataset has no audio or video, so the multimedia contribution is the **synchronized,
time-based, interactive presentation** of analytical evidence: linked views, animation along the
time axis (replay), and an optional audio cue. Every visual element maps to an analytical output.

## Implementation decision

`app/NetworkBehaviorExplorer.m` is built programmatically from App Designer's component family
(`uifigure`, `uigridlayout`, `uipanel`, `uiaxes`, `uitable`, `uislider`, `uitabgroup`,
`uiprogressdlg`, `uialert`, `timer`). Reasons: a binary `.mlapp` is not diffable or reviewable in
Git and cannot be authored without MATLAB; the programmatic class uses the same components and can
be ported into App Designer later. Callbacks only call functions in `src/visualization/` and
`src/`, which are tested without a GUI (`tests/test_visualization_theme.m`,
`tests/test_pipeline_fixture.m`). Properties added in recent releases (`BorderColor`,
`Placeholder`, `RowStriping`, `WordWrap`) are set only when present, so the app degrades to default
styling on older releases instead of failing.

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Network Behaviour Explorer   <dataset name> [format badge]   Dataset [▼ catalog] [Open dataset…] [Export] │  header
├───────────────────────┬──────────────────────────────────────────────────────────────────┤
│ OVERVIEW              │ ┌ Network ─────────────────────┐ ┌ Relative space ─────────────┐ │
│ ┌Entities┐┌Events──┐  │ │ ego network, score colour,   │ │ log density (grey), window  │ │
│ │  1,284 ││ 12.3K  │  │ │ ink ring = selected          │ │ events (blue), ink path     │ │
│ ├Scored──┤├Flagged─┤  │ └──────────────────────────────┘ └─────────────────────────────┘ │
│ │   431  ││   12   │  │ ┌ Timeline ────────────────────┐ ┌ Details ────────────────────┐ │
│ ├Unusual─┤├Quality─┤  │ │ monthly counts, baseline,    │ │ Why flagged | Deviation     │ │
│ │    7   ││● ✓Valid│  │ │ ▲▼ unusual months, change    │ │ profile | Events | Partners │ │
│ └────────┘└────────┘  │ │ points, ink cursor + ticks   │ │ | Patterns | Detectors |    │ │
│ RANKING               │ │                              │ │ Data quality                │ │
│ [Search entity ID   ] │ └──────────────────────────────┘ └─────────────────────────────┘ │
│ [Flagged (either) ▼]  │                                                                  │
│ 12 shown              │                                                                  │
│ ┌ ranking table ────┐ │                                                                  │
│ └───────────────────┘ │                                                                  │
├───────────────────────┴──────────────────────────────────────────────────────────────────┤
│ REPLAY [Reset] [Step] [Play] ═══════○═══════════  Window (months) [12] ☐ Audio cue  <time label> │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│ <status message>             Selected: <id> (<status>)    Scores are statistical deviations, not evidence of wrongdoing │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Header**: title, current dataset name and a format badge (`networkx_burglary_json`,
  `event_csv`, `edge_csv`), the dataset dropdown (catalog), "Open dataset…" (accent button) and
  "Export".
- **Sidebar**: six KPI tiles from `kpiSummary(bundle)` (label · value · detail; values compacted by
  `formatCount`: 1,284 / 12.3K / 1.5M), then search (entity-ID substring, case-insensitive, live),
  filter dropdown and the ranking table from `filterRanking`. The selected entity's row is tinted,
  whichever view selected it.
- **Main area**: 2×2 titled panels. The detail panel keeps every tab of the previous version.
- **Replay bar** and **status bar** (messages, current selection, the permanent disclaimer).
- **Empty state**: with no bundle at all the app opens with "—" tiles and panels that invite
  "Open dataset…" instead of raising an error. A wrong explicit `.mat` path gives an alert, not a
  crash.

## Visual design system (`src/visualization/appTheme.m`)

One design system serves the app and the report figures: every plot function reads its colours and
fonts from `appTheme()`; `styleAxes` and `styleLegend` apply the shared chrome. The method follows
the data-visualization procedure "form first, colour by job, validate, then mark specs":

1. **Colour is assigned by the job it does** — categorical (identity), sequential (magnitude),
   diverging (above/below a baseline), status (state). Never a rainbow.
2. **Every categorical set was validated, not eyeballed**, with the palette validator (OKLab ×100
   ΔE under Machado–Oliveira–Fernandes 2009 protan/deutan simulation; target ≥ 8, 6–8 legal only with
   secondary encoding, normal-vision floor 15; contrast vs the surface).
3. **Text never wears a data colour**; identity comes from the mark beside it. Every chart with
   two or more series has a legend, always above the plot, horizontal, without a box.
4. **Marks**: 1.5 pt lines, ≥ 8 px markers with a thin surface-coloured ring, bars at 60 % of the
   band, solid hairline gridlines one step off the surface, no box, no bold titles.

| Role | Colour | Job / check |
|---|---|---|
| Surface / page | `#fcfcfb` / `#f3f2ef` | panels on a slightly darker page plane; borders `#e1e0d9` |
| Text primary / secondary / muted | `#0b0b0b` 19.2:1 · `#52514e` 7.7:1 · `#898781` 3.5:1 | muted only for axis-scale text |
| Accent (buttons, Play) | `#256abf` | 5.3:1 on surface; white on accent 5.4:1 |
| Feature groups activity · temporal · spatial · cooffending · graph · sequence | `#2a78d6` `#eb6834` `#1baf7a` `#eda100` `#e87ba4` `#008300` | categorical, fixed order; adjacent CVD ΔE 9.1, normal 19.6 (PASS). Aqua/yellow/magenta < 3:1 → relief: legend + feature labels |
| Flagged both · baseline only · IF only | `#e34948` ◆ · `#2a78d6` ■ · `#1baf7a` ▲ | scatter = all pairs: CVD ΔE 6.9 (floor band) → shapes are the required secondary encoding |
| Scored, not flagged / not scored | `#c3c2b7` | neutral; unscored grey is not on the score ramp |
| Unusually high · low month | `#e34948` ▲ · `#2a78d6` ▼ | diverging warm/cool poles + triangle direction |
| Change point | `#008300` dashed rule | red/blue/green all pairs CVD ΔE 7.2 → line form is the secondary encoding |
| Count line · baseline | `#52514e` solid · `#898781` dotted | neutral so the anomaly hues own the colour channel |
| Selected entity | `#0b0b0b` ink | ring (network, detector scatter), path (relative space), ticks (timeline); keeps the node's score colour visible |
| Replay cursor | `#0b0b0b` ink rule labelled with its month | |
| Anomaly score | blue ramp `#9ec5f4` → `#0d366b` (11 steps) | sequential, one hue, monotone lightness (validator: monotone PASS, hue spread 4°) |
| Density | grey ramp `#fcfcfb` → `#898781` | recedes behind data marks |
| Data quality good · warning · critical | `#0ca30c` · `#fab219` · `#d03b3b` | reserved status scale, always with ✓ / ! / ✕ and a text label |

Rejected alternatives (validator FAIL): violet change points next to blue low months (normal-vision
ΔE 10.5); orange as "selected" next to red flags (ΔE 7.1); the previous `parula` node colours (a
multi-hue ramp) and `lines()` group colours (colour depended on the order of groups present, so a
group could change colour between entities).

Typography: one sans family (`Helvetica`, MATLAB's UI default) at 10 / 12 / 16 pt, KPI values 20 pt
bold. Light theme only; dark mode is not implemented (it would need its own validated steps, not
an automatic inversion).

## Views (all linked)

| View | Content | Analytical source |
|---|---|---|
| KPI tiles | entities, events, scored (≥ min events), flagged (either detector), unusual months, data quality | `kpiSummary` |
| Ranking table | flagged / top-200 IF / top-200 baseline / all eligible, + ID search; ranks, scores, events, main group | `filterRanking` |
| Network | 2-hop ego network; colour = score, size = events, width = shared events; ring = selected; click to select | `graph`, `plotEgoNetwork` |
| Timeline | monthly counts, causal/seasonal baseline, unusual months, change points, selected entity's events, playback cursor | `temporal`, `plotActivityTimeline` |
| Relative space | normalized density, current-window events, selected entity's numbered path; a message when the dataset has no coordinates | `spatial`, `plotSpatialView` |
| Why flagged | evidence text | `getEntityContext` |
| Deviation profile | robust-z bars by feature group with ±threshold rules and a group legend | `plotEvidenceBars` |
| Events | ordered events with token and surprisal (coordinates only if the dataset has them) | `events` |
| Partners | partners, shared events, first/last date, their score; click to navigate | `relations` |
| Patterns | frequent/rare trigrams | `patterns.ngrams` |
| Detectors | baseline vs Isolation Forest scatter with the selected entity ringed | `plotScoreComparison` |
| Data quality | validation checks | `validation` |

Wording adapts to the dataset (`bundleDatasetInfo`): the primary burglary format says
crimes/offenders/co-offending network, imported generic formats say events/entities/relation
network. No UI text calls a scored entity criminal, guilty or a suspect.

## Datasets: open, analyse, switch

`Open dataset…` → `uigetfile` (`*.json;*.csv;*.txt;*.tsv`) → `inspectDatasetFile(path)`:

- `format == "unknown"` → `uialert` with the inspector's message; nothing else happens.
- Otherwise a small modal dialog (`uifigure` + `uiwait`/`uiresume`) asks for an optional dataset
  name and, when `needs_mapping` is true, which column holds each field — entity/event/time/x/y
  for `event_csv`, source/target/time/weight for `edge_csv`, prefilled from `info.mapping`; required
  fields are starred and checked before the dialog closes.
- `analyzeDataset(path, opts)` runs with `opts.progress` wired to a `uiprogressdlg` (not
  cancelable); `opts.root_dir` is the project root. Errors are shown with `uialert`, the current
  dataset stays loaded.
- On success `loadBundle(app, bundle)` repopulates every view and the dataset dropdown is
  refreshed from `listDatasets(root)` (plus "primary" when `outputs/model/analysis_bundle.mat`
  exists). Choosing a dropdown entry loads that bundle with `load(file, "bundle")`.

`loadBundle` is public and is also what the constructor uses, so
`NetworkBehaviorExplorer()`, `NetworkBehaviorExplorer(bundle)` and
`NetworkBehaviorExplorer("x.mat")` all go through the same path.

## Interaction model

- **Brushing and linking** (Becker & Cleveland 1987): one selection (table row, network node or
  partner row) drives network, timeline, relative space, detector scatter, all tabs and the
  ranking-row highlight.
- **Overview → zoom/filter → details on demand** (Shneiderman 1996): KPI tiles and ranking (with
  search) → ego network and time window → evidence and events.
- **Replay**: slider, Play/Pause, Step, Reset, window length (months). Each step recomputes the
  window with `buildPlaybackFrame`: ties appear at their first shared event (hidden only while
  replaying the past; at the last month the full network is shown so the graph agrees with the
  Partners tab), the density view shows the window's events, the timeline cursor moves, unusual
  months are labelled in the replay bar. The timer callback is wrapped in try/catch and always
  stops cleanly (`stopTimer`) on error, on dataset change and on close. Replay controls are
  disabled for datasets without dated events.
- **Robustness**: each view is drawn through `safePlot`; a view that cannot be drawn for an imported
  dataset shows a message in its own panel instead of breaking the others.

## Animation and audio principles

- Animation is used only for what actually changes over time (ties appearing, activity moving)
  and is user-controlled (pause/step/reset). Tversky, Morrison & Bétrancourt (2002) found little
  evidence that animation beats static graphics unless it is interactive and congruent with the
  content, so replay is an interactive tool, not an automatic effect.
- No decorative motion; one month per step at 0.8 s.
- Optional audio cue (short 880 Hz tone) when the replay enters an unusual month; off by default
  (`cfg.app.audio_cues`); every audio event also has a visual label, so nothing depends on sound.

## Export

"Export" writes PNGs of the network, timeline and relative-space views and the entity's evidence
text to `outputs/` (file names carry the dataset id and a timestamp; graph nodes carry no labels,
so no identifiers appear in the figures). Report figures are regenerated by
`scripts/generate_report_figures.m` with the same themed plotting functions.

## Verification

- `tests/test_visualization_theme.m`: theme fields and RGB ranges, WCAG contrast of text tokens,
  palette order and name-based group colours, score ramp (anchor values, monotone luminance,
  single hue), `formatCount`, `filterRanking` (filters, stable ordering, search, IF-less fallback),
  `kpiSummary` (values, quality status, partial bundles), `bundleDatasetInfo` (old bundles,
  datasets without coordinates), and a headless smoke test drawing every plot function on the
  synthetic fixture.
- GUI: the walkthrough in docs/DEMO_SCENARIO.md and the usability protocol (E10).

## Status

Implemented, **not yet executed** (no MATLAB in the development environment; MISS_HIT lint clean).
The dataset UI codes against the `inspectDatasetFile` / `analyzeDataset` / `listDatasets`
contract; when those functions are not on the path, "Open dataset…" explains that import is
unavailable and the catalog shows only the primary bundle.

## Layout revision 2026-10-27 (after the first real screenshot)

Feedback: the dashboard look (KPI tiles, filled accent buttons, bordered cards) read as
generic and the network view was unreadable on a 178,501-host capture. The layout is now plain:
one header row (title, dataset, format; dataset list, Open, Export), one summary line in text
(hosts · flows · scored · flagged · unusual periods · data quality) instead of six tiles, the
ranking on the left, network and detail tabs side by side, and the timeline across the full width
with its replay controls directly underneath. The relative-space view moved into a "Space" tab
(most network datasets have no coordinates). White page, no panel borders, neutral buttons.
Hubs show their 60 strongest ties; node size is log-scaled and bounded.

