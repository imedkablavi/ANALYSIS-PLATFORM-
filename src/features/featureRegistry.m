function reg = featureRegistry()
%FEATUREREGISTRY Single definition of every entity-level anomaly feature.
%
%   REG = FEATUREREGISTRY() returns a table with one row per feature:
%     name        column name in the entity feature table
%     group       activity | temporal | spatial | cooffending | graph | sequence
%     transform   "log1p" for heavy-tailed non-negative counts, "none" otherwise
%     min_events  minimum events for the feature to be defined
%     label       short human-readable label (used in explanations and UI)
%     definition  formula (mirrors docs/FEATURE_ENGINEERING.md)
%     source      artifact fields the feature is computed from
%
%   The registry drives feature selection for ablation (by group), the
%   transform/scaling step, the explanation text and the documentation, so
%   they cannot drift apart. Feature version: projectConfig().project.feature_version.

rows = {
% name                     group          transform min label                                   definition                                                                 source
"event_count",            "activity",    "log1p", 1, "number of crimes",                     "count of distinct crimes attached to the offender",                         "crime_details"
"active_span_days",       "activity",    "none",  1, "active period (days)",                 "last event date - first event date",                                        "date"
"active_day_count",       "activity",    "log1p", 1, "distinct active days",                 "number of distinct calendar days with an event",                            "date"
"iet_median_days",        "temporal",    "log1p", 3, "median gap between crimes (days)",     "median of consecutive inter-event gaps",                                    "date"
"iet_cv",                 "temporal",    "none",  3, "gap irregularity (CV)",                "std(gaps)/mean(gaps)",                                                      "date"
"burstiness",             "temporal",    "none",  3, "burstiness B",                         "(std-mean)/(std+mean) of gaps; Goh & Barabasi (2008), in [-1,1]",           "date"
"max_gap_ratio",          "temporal",    "log1p", 3, "longest dormancy / median gap",        "max gap / max(median gap, 1 day)",                                          "date"
"peak_window_share",      "temporal",    "none",  3, "share of crimes in busiest 30 days",   "max events in any 30-day window / event_count",                             "date"
"same_day_fraction",      "temporal",    "none",  2, "share of same-day crimes",             "1 - active_day_count/event_count",                                          "date"
"radius_of_gyration",     "spatial",     "none",  2, "spatial spread (normalized units)",    "sqrt(mean squared distance to the offender's centroid); Gonzalez et al. (2008)", "X, Y"
"mean_step_distance",     "spatial",     "none",  2, "mean move between crimes",             "mean distance between chronologically consecutive crime sites",             "X, Y, date"
"max_step_distance",      "spatial",     "none",  2, "largest move between crimes",          "max distance between chronologically consecutive crime sites",              "X, Y, date"
"location_repeat_fraction","spatial",    "none",  2, "share of repeated sites",              "1 - distinct (X,Y) pairs / event_count",                                    "X, Y"
"mean_group_size",        "cooffending", "none",  1, "mean offenders per crime",             "mean num_of_offenders over the offender's crimes",                          "num_of_offenders"
"solo_fraction",          "cooffending", "none",  1, "share of solo crimes",                 "fraction of crimes with num_of_offenders == 1",                             "num_of_offenders"
"max_group_size",         "cooffending", "none",  1, "largest group",                        "max num_of_offenders over the offender's crimes",                           "num_of_offenders"
"repeat_partner_fraction","cooffending", "none",  1, "share of repeat partners",             "partners with >= 2 shared crimes / partners (0 if no partner)",             "crime_details (shared crimes)"
"degree",                 "graph",       "log1p", 1, "number of co-offenders",               "undirected degree in the co-offending projection",                          "links / shared crimes"
"strength",               "graph",       "log1p", 1, "total shared crimes with partners",    "sum of tie weights (shared-crime counts)",                                  "links weight"
"max_tie_weight",         "graph",       "log1p", 1, "strongest tie (shared crimes)",        "max tie weight",                                                            "links weight"
"clustering_coef",        "graph",       "none",  1, "local clustering",                     "triangles / (k(k-1)/2); 0 when degree < 2; Watts & Strogatz (1998)",        "links"
"core_number",            "graph",       "log1p", 1, "k-core number",                        "largest k such that the node is in the k-core; Batagelj & Zaversnik (2003)", "links"
"component_size",         "graph",       "log1p", 1, "size of connected group",              "number of offenders in the node's connected component",                     "links"
"betweenness",            "graph",       "log1p", 1, "brokerage (betweenness)",              "unweighted shortest-path betweenness; Freeman (1977)",                      "links"
"is_cut_vertex",          "graph",       "none",  1, "bridge-like position",                 "1 if removing the node disconnects its component (articulation point)",     "links"
"seq_surprisal_mean",     "sequence",    "none",  2, "mean sequence surprise (bits)",        "mean -log2 P(token_t | token_t-1) under the global Markov model",            "derived tokens"
"seq_surprisal_max",      "sequence",    "none",  2, "rarest transition (bits)",             "max -log2 P(token_t | token_t-1)",                                          "derived tokens"
"new_partner_rate",       "sequence",    "none",  1, "share of crimes with a new partner",   "fraction of the offender's crimes involving a previously unseen partner",   "crime_details (order)"
};

reg = cell2table(rows, 'VariableNames', ...
    {'name','group','transform','min_events','label','definition','source'});
for v = ["name","group","transform","label","definition","source"]
    reg.(v) = string(reg.(v));
end
reg.min_events = double(reg.min_events);
end
