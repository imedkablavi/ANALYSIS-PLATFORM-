# Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Dataset is inaccessible | High | Keep one documented fallback dataset |
| Dataset lacks labels | Medium | Use unsupervised detection + clearly labeled evaluation strategy |
| Dataset schema is complex | High | Build ingestion adapter before ML |
| Model underperforms | Medium | Keep simple statistical baseline and compare models |
| App becomes too large | High | Freeze UI scope after core analytical demo |
| Runtime is slow | Medium | Sample/slice data, cache features, use vectorization, optional parallelization |
| Privacy concerns | High | Use anonymized public data and never attempt re-identification |
| Multimedia features consume time | High | Prioritize timeline/network/entity/replay; audio is optional |
