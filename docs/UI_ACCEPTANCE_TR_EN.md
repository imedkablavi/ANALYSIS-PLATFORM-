# Interface acceptance — Turkish and English

Run on the target MATLAB installation. These checks describe required
observations; they are not a record that the GUI has passed.

1. With no saved language preference, launch the app: Turkish title, controls,
   table headers, empty states, plot labels and analytical summary are readable.
2. Inspect at 1366×768 and 1920×1080. Header/toolbars and replay controls must
   remain accessible; selected-host details and ranking values must not overlap.
3. Import the official scenario-7 binetflow. Confirm the file filter exposes
   `.binetflow`, numbers correspond to the current bundle and source hashes match.
4. Select a host, search/filter the ranking, choose a replay interval/window,
   and enable sound. Switch to English. The same in-memory analysis, selection,
   search/filter, time/window and sound setting must remain. Playback stays stopped.
5. Compare summary measurements in both languages. Scores and evidence values
   must be unchanged, unavailable values remain unavailable, and technical IDs
   and diagnostics must not be translated as prose.
6. Switch back to Turkish. Read the generated host summary, flow-table headers,
   provenance fields, plot legends and export dialogs; no stored English paragraph
   should appear in place of the current-language summary.
7. Export the selected host. PNG/TXT/JSON/CSV refer to the same frozen cursor;
   the manifest distinguishes full-run scores from interval observations.
8. Open an older bundle without source flows and an unscored host. The interface
   explains missing records/history without inventing a zero score or normal label.

Record the MATLAB version, source fingerprints, display resolution, results
and real screenshots with the run's verification artifacts. Layout contracts
and static parsing do not substitute for these checks.

## Readability and empty-result checks

- Turkish source counts use exact grouping (114.077); English uses 114,077.
  Unknown counts remain unavailable and are not presented as zero.
- Search for an absent identifier, clear the search, and choose a filter with no
  matching rows. Each state gives an appropriate next action without implying
  that an unscored host is normal.
- Direction, detector and evaluation-scope cells use the active language;
  numeric measurements and raw file diagnostics remain unchanged.
- With more than twelve measured deviations, the plot shows the strongest
  twelve by absolute z and labels its shown/total count. Negative deviations
  keep their sign; the exported evidence table remains complete.
- Verify the dataset-type badge uses readable words, not internal schema keys.
