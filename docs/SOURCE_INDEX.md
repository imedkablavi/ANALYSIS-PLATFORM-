# Source Index

Only sources that justify a concrete decision are listed. "Used for" names the decision.
Bibliographic details of entries 7–25 were verified online on 2026-09-30 unless marked (m) =
standard reference cited from memory, to be double-checked before final submission.

## Dataset

1. Criminal Network Analysis and Visualization (GitHub, ROXANNE): https://github.com/erichoang/criminal-network-visualization — artifact, licence (BSD-3-style), preprocessing description.
2. Dataset documentation: https://github.com/erichoang/criminal-network-visualization/blob/main/datasets/preprocessed/README.md — anonymization and min-max scaling statement.
3. Ahmadi, Z., Nguyen, H. H., Zhang, Z., Bozhkov, D., Kudenko, D., Jofre, M., Calderoni, F., Cohen, N., & Solewicz, Y. (2023). Inductive and transductive link prediction for criminal network analysis. *Journal of Computational Science*, 72, 102063. https://doi.org/10.1016/j.jocs.2023.102063 — required dataset citation.

## MATLAB documentation

4. App Designer: https://www.mathworks.com/help/matlab/ref/appdesigner.html — UI component family.
5. `iforest` / `isanomaly`: https://www.mathworks.com/help/stats/iforest.html — Isolation Forest API, NaN handling, `ContaminationFraction`.
6. `jsondecode`: https://www.mathworks.com/help/matlab/ref/jsondecode.html — non-identifier keys converted with `matlab.lang.makeValidName` (root cause of the crime-ID bug).

## Anomaly detection and evaluation

7. Liu, F. T., Ting, K. M., & Zhou, Z.-H. (2008). Isolation Forest. *ICDM 2008*, 413–422. https://doi.org/10.1109/ICDM.2008.17 — primary model; 256-sample default.
8. Iglewicz, B., & Hoaglin, D. C. (1993). *How to Detect and Handle Outliers*. ASQC Basic References in Quality Control, Vol. 16 — modified z-score, 1.4826·MAD, 3.5 cut-off.
9. Campos, G. O., Zimek, A., Sander, J., et al. (2016). On the evaluation of unsupervised outlier detection: measures, datasets, and an empirical study. *Data Mining and Knowledge Discovery*, 30(4), 891–927. https://doi.org/10.1007/s10618-015-0444-8 — ROC-AUC, AP, precision@n.
10. Emmott, A. F., Das, S., Dietterich, T., Fern, A., & Wong, W.-K. (2013). Systematic construction of anomaly detection benchmarks from real data. *ODD '13 (KDD workshop)*. https://doi.org/10.1145/2500853.2500858 — controlled anomalies on real data (synthetic injection design).
11. Siddiqui, M. A., Fern, A., Dietterich, T. G., & Wong, W.-K. (2019). Sequential feature explanations for anomaly detection. *ACM TKDD*, 13(1), 1–22. https://doi.org/10.1145/3230666 — feature-level anomaly explanations.
12. Akoglu, L., Tong, H., & Koutra, D. (2015). Graph based anomaly detection and description: a survey. *Data Mining and Knowledge Discovery*, 29(3), 626–688. https://doi.org/10.1007/s10618-014-0365-y — landscape of graph-based anomaly features; justified choosing node-level structural features over community-based detectors.

## Temporal, spatial and network measures

13. Goh, K.-I., & Barabási, A.-L. (2008). Burstiness and memory in complex systems. *EPL*, 81(4), 48002. https://doi.org/10.1209/0295-5075/81/48002 — burstiness B.
14. Truong, C., Oudre, L., & Vayatis, N. (2020). Selective review of offline change point detection methods. *Signal Processing*, 167, 107299. https://doi.org/10.1016/j.sigpro.2019.107299 — binary segmentation, penalty choice.
15. González, M. C., Hidalgo, C. A., & Barabási, A.-L. (2008). Understanding individual human mobility patterns. *Nature*, 453, 779–782. https://doi.org/10.1038/nature06958 (m) — radius of gyration.
16. Kulldorff, M. (1997). A spatial scan statistic. *Communications in Statistics – Theory and Methods*, 26(6), 1481–1496 (m) — context for the Poisson excess test (not implemented as a scan).
17. Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, 393, 440–442 (m) — local clustering.
18. Batagelj, V., & Zaversnik, M. (2003). An O(m) algorithm for cores decomposition of networks. arXiv:cs/0310049 (m) — k-core.
19. Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, 40(1), 35–41 (m) — betweenness.
20. Sparrow, M. K. (1991). The application of network analysis to criminal intelligence: an assessment of the prospects. *Social Networks*, 13(3), 251–274 — incompleteness, fuzzy boundaries, dynamics: limits of centrality interpretation.
21. Hyndman, R. J., & Fan, Y. (1996). Sample quantiles in statistical packages. *The American Statistician*, 50(4), 361–365 (m) — type-7 quantile in `empiricalQuantile`.

## Visualization and multimedia

22. Shneiderman, B. (1996). The eyes have it: a task by data type taxonomy for information visualizations. *IEEE Symposium on Visual Languages*, 336–343 (m) — overview → filter → details on demand.
23. Becker, R. A., & Cleveland, W. S. (1987). Brushing scatterplots. *Technometrics*, 29(2), 127–142 (m) — linked selection across views.
24. Tversky, B., Morrison, J. B., & Bétrancourt, M. (2002). Animation: can it facilitate? *International Journal of Human-Computer Studies*, 57(4), 247–262. https://doi.org/10.1006/ijhc.2002.1017 — animation only when interactive and congruent.
25. Brooke, J. (1996). SUS: a "quick and dirty" usability scale. In *Usability Evaluation in Industry*, 189–194 (m) — E10 questionnaire.

## Considered, not used as a basis

- Stanford SNAP / Network Repository (alternative datasets; primary artifact passed all gates).
