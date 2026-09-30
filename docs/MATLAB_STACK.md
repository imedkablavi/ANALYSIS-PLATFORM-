# MATLAB Stack

| Component | Status | Used for |
|---|---|---|
| MATLAB R2021b+ (base) | required | tables, datetime, `graph` (`centrality`, `conncomp`, `biconncomp`, `distances`, `subgraph`), sparse algebra, `gammainc`, App Designer components, `timer`, `sound`, `exportgraphics`, `jsondecode/jsonencode`, `matlab.unittest` |
| Statistics and Machine Learning Toolbox | required for Isolation Forest | `iforest`, `isanomaly` only; everything else (quantiles, ranks, AUC, AP, Spearman) is base MATLAB so tests run without it |
| Signal Processing Toolbox | not used | change points are implemented transparently (`detectChangePoints`) instead of `findchangepts` |
| Image Processing / Computer Vision | not used | no image data |
| Audio Toolbox | not used | the optional cue uses base `sound` |
| Parallel Computing Toolbox | not used | largest workload (~1,200 small forests in E5–E7) is minutes, not hours |

The minimum release is inferred from the functions used; no specific release has been executed
yet (docs/REPRODUCIBILITY.md §4).

Sources: MATLAB documentation for App Designer, `iforest`, anomaly detection overview, `jsondecode`
(field-name conversion with `matlab.lang.makeValidName`).
