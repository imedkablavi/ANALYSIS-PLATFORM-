# Anomaly Detection

## Baselines

Implement a simple statistical baseline first. Examples:

- robust z-score,
- distance from behavioral centroid,
- percentile threshold.

## Primary ML candidate

**Isolation Forest** is a good MATLAB-first candidate because current MATLAB Statistics and Machine Learning Toolbox documentation provides `iforest` for fitting and `isanomaly` for scoring new observations. Scores close to 1 indicate more anomalous observations.

Source:
- https://www.mathworks.com/help/stats/iforest.html
- https://www.mathworks.com/help/stats/anomaly-detection.html

## Alternatives

Only add alternatives if time allows:

- Local Outlier Factor
- One-Class SVM
- Robust Random Cut Forest

MATLAB documents all of these under its unsupervised anomaly detection capabilities.

## Thresholding

Do not arbitrarily call a score “high risk”. Define thresholds using a documented validation procedure and report them as anomaly thresholds, not criminality thresholds.
