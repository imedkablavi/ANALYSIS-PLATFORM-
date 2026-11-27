function reg = featureRegistry()
%FEATUREREGISTRY Single definition of every entity-level anomaly feature.
%
%   REG = FEATUREREGISTRY() returns a table with one row per feature:
%     name        column name in the entity feature table
%     group       activity | temporal | spatial | cooffending | graph | sequence
%                 | network (network-traffic datasets only: computeNetworkFeatures;
%                 absent columns are skipped by prepareFeatureMatrix)
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
"event_count",            "activity",    "log1p", 1, "number of events",                     "count of distinct events attached to the entity",                         "crime_details"
"active_span_days",       "activity",    "none",  1, "active period (days)",                 "last event date - first event date",                                        "date"
"active_day_count",       "activity",    "log1p", 1, "distinct active days",                 "number of distinct calendar days with an event",                            "date"
"iet_median_days",        "temporal",    "log1p", 3, "median gap between events (days)",     "median of consecutive inter-event gaps",                                    "date"
"iet_cv",                 "temporal",    "none",  3, "gap irregularity (CV)",                "std(gaps)/mean(gaps)",                                                      "date"
"burstiness",             "temporal",    "none",  3, "burstiness B",                         "(std-mean)/(std+mean) of gaps; Goh & Barabasi (2008), in [-1,1]",           "date"
"max_gap_ratio",          "temporal",    "log1p", 3, "longest dormancy / median gap",        "max gap / max(median gap, 1 day)",                                          "date"
"peak_window_share",      "temporal",    "none",  3, "share of events in busiest configured window",   "max events in a window of cfg.temporal.burst_window_days / event_count",                             "date"
"same_day_fraction",      "temporal",    "none",  2, "share of same-day events",             "1 - active_day_count/event_count",                                          "date"
"radius_of_gyration",     "spatial",     "none",  2, "spatial spread (normalized units)",    "sqrt(mean squared distance to the entity's centroid); Gonzalez et al. (2008)", "X, Y"
"mean_step_distance",     "spatial",     "none",  2, "mean move between events",             "mean distance between chronologically consecutive event sites",             "X, Y, date"
"max_step_distance",      "spatial",     "none",  2, "largest move between events",          "max distance between chronologically consecutive event sites",              "X, Y, date"
"location_repeat_fraction","spatial",    "none",  2, "share of repeated sites",              "1 - distinct (X,Y) pairs / event_count",                                    "X, Y"
"mean_group_size",        "cooffending", "none",  1, "mean entities per event",             "mean number of entities participating in each event",                          "num_of_offenders"
"solo_fraction",          "cooffending", "none",  1, "share of single-entity events",                 "fraction of events involving one entity",                             "num_of_offenders"
"max_group_size",         "cooffending", "none",  1, "largest group",                        "maximum number of entities participating in an event",                           "num_of_offenders"
"repeat_partner_fraction","cooffending", "none",  1, "share of repeat peers",             "peers with >= 2 shared events / peers (0 if no peer)",             "crime_details (shared crimes)"
"degree",                 "graph",       "log1p", 1, "number of peers",               "undirected degree in the shared-event projection",                          "links / shared crimes"
"strength",               "graph",       "log1p", 1, "total shared events with peers",    "sum of tie weights (shared-event counts)",                                  "links weight"
"max_tie_weight",         "graph",       "log1p", 1, "strongest tie (shared events)",        "max tie weight",                                                            "links weight"
"clustering_coef",        "graph",       "none",  1, "local clustering",                     "triangles / (k(k-1)/2); 0 when degree < 2; Watts & Strogatz (1998)",        "links"
"core_number",            "graph",       "log1p", 1, "k-core number",                        "largest k such that the node is in the k-core; Batagelj & Zaversnik (2003)", "links"
"component_size",         "graph",       "log1p", 1, "size of connected group",              "number of entities in the node's connected component",                     "links"
"betweenness",            "graph",       "log1p", 1, "brokerage (betweenness)",              "unweighted shortest-path betweenness; Freeman (1977)",                      "links"
"is_cut_vertex",          "graph",       "none",  1, "bridge-like position",                 "1 if removing the node disconnects its component (articulation point)",     "links"
"seq_surprisal_mean",     "sequence",    "none",  2, "mean sequence surprise (bits)",        "mean -log2 P(token_t | token_t-1) under the global Markov model",            "derived tokens"
"seq_surprisal_max",      "sequence",    "none",  2, "rarest transition (bits)",             "max -log2 P(token_t | token_t-1)",                                          "derived tokens"
"new_partner_rate",       "sequence",    "none",  1, "share of events with a new peer",   "fraction of the entity's events involving a previously unseen peer",   "crime_details (order)"
"out_flows",              "network",     "log1p", 1, "outgoing flows",                       "flows the host initiated (source)",                                         "flows"
"in_flows",               "network",     "log1p", 1, "incoming flows",                       "flows the host received (destination), self-flows excluded",                "flows"
"out_share",              "network",     "none",  1, "share of flows it initiated",          "out_flows / (out_flows + in_flows)",                                        "flows"
"distinct_dst",           "network",     "log1p", 1, "distinct destinations (fan-out)",      "number of distinct destination hosts of outgoing flows",                    "flows"
"distinct_src_in",        "network",     "log1p", 1, "distinct sources (fan-in)",            "number of distinct source hosts of incoming flows",                         "flows"
"distinct_dport",         "network",     "log1p", 1, "distinct destination ports",           "number of distinct destination ports of outgoing flows",                    "flows dport"
"dport_entropy",          "network",     "none",  2, "destination-port entropy (bits)",      "Shannon entropy of the destination-port distribution of outgoing flows",    "flows dport"
"median_bytes_out",       "network",     "log1p", 1, "median bytes per outgoing flow",       "median bytes of outgoing flows",                                            "flows bytes"
"median_duration_out",    "network",     "log1p", 1, "median outgoing duration (s)",         "median duration of outgoing flows",                                         "flows duration"
"small_flow_fraction",    "network",     "none",  1, "share of tiny outgoing flows",         "outgoing flows with <= 2 packets / outgoing flows (scans, unanswered attempts)", "flows packets"
"failed_fraction",        "network",     "none",  1, "share of failed attempts",             "failed / outgoing authentication attempts",                                 "auth outcome"
"beacon_cv_min",          "network",     "none",  4, "most regular repeated connection (gap CV)", "min over destinations meeting cfg.network.beacon_min_flows of std(gaps)/mean(gaps); ~0 = clock-like (beaconing)", "flows time"
};

reg = cell2table(rows, 'VariableNames', ...
    {'name','group','transform','min_events','label','definition','source'});
for v = ["name","group","transform","label","definition","source"]
    reg.(v) = string(reg.(v));
end
reg.min_events = double(reg.min_events);
end
