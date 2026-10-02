# Sequence Analysis

## Representation (decision)

The artifact has no event-type field, so tokens are derived from two observable, causal
properties of each crime in an offender's history (`encodeEventSequences`):

| Component | Values | Definition |
|---|---|---|
| partner state | S / R / N | solo; co-offended only with partners already seen in the offender's **earlier** crimes; at least one new partner |
| move | 0 / L / F / U | first crime; step ≤ global median step (0.006586 normalized units); farther; missing coordinates |

Token = state + move (12-symbol fixed alphabet, `sequenceAlphabet`). Same-day crimes are ordered by
numeric crime ID (documented convention). Observed distribution in the artifact (reference audit):
S0 8,715 · N0 8,522 · SL 4,632 · SF 4,055 · RL 2,493 · NF 2,256 · RF 2,148 · NL 1,335.

## Models

- **Transition model** (`fitTransitionModel`): first-order Markov, Laplace α = 1, optional row mask
  for temporal hold-out.
- **Novelty** (`scoreSequenceNovelty`): per-transition surprisal −log₂ P; entity mean and max; share
  of new-partner crimes.
- **Patterns** (`mineSequenceNgrams`): contiguous trigrams inside each offender's history with
  occurrences and support (distinct offenders); frequent = support ≥ 5; rare = low support.

## Why this and not full sequential pattern mining

Histories are short (median 1, max 40 crimes) and the alphabet is small; contiguous n-grams and a
Markov model are transparent enough to explain in a defense, and they plug directly into anomaly
features and explanation text. PrefixSpan-style gapped patterns would add complexity without a
clear evaluation benefit here.

## Limitation

Tokens describe partner novelty and movement, not what kind of crime happened.
