# Spatial Analysis

The provider min-max scaled the coordinates "to prevent precise retrieval of the localization of
the site". The project uses them **only as relative positions in [0,1]²** and never reverses the
scaling (`cfg.privacy.denormalize_coordinates = false`).

## Entity features

radius of gyration, mean/max step distance between consecutive crimes, repeated-site share
(formulas in docs/FEATURE_ENGINEERING.md). Distances are in normalized units, not metres.

## System level (`computeSpatialHotspots`)

- 20 × 20 grid density (`hs.grid`, log-scaled in the app).
- Cell × year Poisson excess: expected_{c,y} = N_c·N_y/N; p = P(X ≥ observed) =
  `gammainc(expected, observed)`; hotspot if p < 0.001 / (number of tested cell-years).
- This highlights cells whose activity in a given year exceeds what their overall share predicts;
  it is a simple fixed-grid relative of the space–time scan statistic (Kulldorff 1997), not a
  full scan implementation (no variable windows, no Monte-Carlo inference).

## Visual outputs

Relative density map with the selected offender's numbered path and the crimes of the current
playback window (`plotSpatialView`). No basemap is drawn.

## Why not more

Route similarity and location entropy were considered. With a median of 1 crime per offender and
unknown scaling extents, entropy estimates would be unstable; steps and radius already capture
spread and movement.
