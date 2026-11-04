# Interface language and copy

The interface starts in Turkish (`tr`); English (`en`) is available through the
language selector. The choices are named **Türkçe** and **English** in either
language. Saved preferences may select English on later launches.

The Turkish application title is **Ağ Davranışı Analizi**. Use everyday technical
language: *cihaz*, *akış*, *kayıt*, *referans model*, *puan* and *sıra*. Keep
established algorithm names such as Isolation Forest and scientific quantities
such as medyan, entropi and sağlam z. Generic entity keys remain available because
the same application can open non-network case studies.

Write messages around the user's next action or the observed state. “Dosya
okunamadı” is enough for a failed read; append the actual diagnostic when available.
Avoid promotional claims, filler introductions, literal translations and claims of
accuracy or certainty that the analysis does not establish. Missing scores, labels
and measurements stay explicitly unavailable. An unscored record is not evidence
of normal behavior. Playback uses saved full-analysis scores; it does not compute
a separate score for each displayed flow.

The editing approach follows the project's humanizer guidance and uses
[Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
as a descriptive checklist for unnecessary emphasis, stock phrasing and repetitive
structure. These are editorial cues, not a reliable method of identifying authorship
or a promise to evade detection. Scientific meaning and observed facts take priority.

## Translation API

English text remains the lookup key in `src/visualization/uiText.m`, preserving
existing callers. Unknown keys fall back to that text so diagnostics remain visible.
A literal percent sign is left untouched when no format arguments are supplied.
When arguments exist, use sprintf placeholders and preserve each argument's type;
Turkish may use positional placeholders to change the word order.

```matlab
uiText("--lang", "tr");
uiText("Recorded events: %g.", 5)
uiText("--format", "en", "Recorded events: %g.", 5)
```

`--format` chooses a language for one call without changing the selected language.
Use it for deterministic evidence rendering. Only `tr` and `en` are accepted;
invalid language codes and nonscalar/missing keys raise explicit errors. Text
already stored in analysis bundles remains source evidence; translate it with a
renderer rather than mutating scores or recomputing an explanation.

Regression coverage is in `tests/test_language_copy.m`. Fresh MATLAB execution is
still needed; static parsing does not verify fonts, layout or native formatting.

## Tables

Keep MATLAB `VariableNames` as the data contract. `uiText` maps those schema keys
to short headings in each language; do not rename source columns for display.
Sequence-pattern support means the number of distinct entities containing the
pattern, not the number of occurrences. The two headings deliberately differ.

`localizeTableDisplay` returns a presentation copy. It translates only enumerated
values in `detector`, `setting`, `severity`, `category` and `direction`. Unknown
values and raw diagnostics stay visible, and host identifiers are never translated.
Numbers (including NaN), dates and logical flags retain their types and values.
Do not export this display copy as scientific evidence: export the original table.
A language switch must rebuild the display from the original table so translated
values are never treated as source data.

The “unknown as benign” evaluation setting is shown as an assumption in both
languages. Background traffic is not thereby relabelled as verified benign.
Tests for this boundary are in `tests/test_table_display.m`.
