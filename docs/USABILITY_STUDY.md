# Usability Study Protocol (E10, task T-066)

Status: **kit ready, sessions not yet run.** This document contains no participant data and no
results. All result tables below are empty templates.

Related: docs/EVALUATION.md (E10 definition), docs/MULTIMEDIA_DESIGN.md (views),
docs/DEMO_SCENARIO.md, docs/ETHICS_AND_LIMITATIONS.md (wording rules).

## 1. Purpose

Check whether people who did not build the application can use **Network Behaviour Explorer**
(`app/NetworkBehaviorExplorer.m`) to (a) find and read the evidence behind a ranked record,
(b) use the time replay, (c) interpret an unusual month, and (d) recognise records that are not
scored. The study evaluates the **interface**, not the participants and not the anomaly models.
Usability results are reported separately from model results (docs/EVALUATION.md).

Questions the study answers (descriptively):

1. Which of the tasks T1–T5 can participants complete unaided, and how long do they take?
2. Do participants explain a flag with concrete deviations and without guilt language (T2)?
3. How do participants rate overall usability (SUS, Brooke 1996)?
4. Which interface problems (from think-aloud notes) should be fixed first?

## 2. Participants

- **5–8 classmates** (volunteers), plus **one pilot session** (ID `P00`) that is used only to test
  the procedure and is **excluded** from the analysis.
- Inclusion: can use a desktop application; no prior use of this app; not a project member.
- No compensation, no grading consequence; participation is voluntary and anonymous.
- Recruitment message (oral or chat): "We are testing the usability of a course-project
  application for about 25 minutes. Participation is voluntary and anonymous."
- Participants receive IDs `P01`, `P02`, … in session order. **No names, student numbers, e-mail
  addresses or other personal data** are written in any study file.

## 3. Materials and setup

| Item | File |
|---|---|
| Consent form (TR/EN) | docs/usability/consent_form.md |
| Participant task sheet (TR/EN) | docs/usability/task_sheet.md |
| SUS questionnaire (TR/EN) | docs/usability/sus_questionnaire.md |
| Observation log template | docs/usability/observation_log_template.csv |
| SUS response template | docs/usability/sus_responses_template.csv |
| Scoring functions | src/evaluation/scoreSUS.m, src/evaluation/summarizeUsabilityLog.m |
| Tests | tests/test_usability_scoring.m |

Setup before **every** session:

1. Same computer, same screen resolution, same analysis bundle for all participants. Record once,
   in the facilitator's private notes: git commit hash, bundle file date, MATLAB release.
2. `run scripts/run_pipeline.m` (only once, before the pilot), then for each participant
   restart the application: `run scripts/launch_app.m`.
3. Leave the defaults: ranking filter "Flagged (either detector)", window 12 months, **Audio off**,
   cursor at the end of the series (the state the app opens in).
4. Close other windows; have a stopwatch (or a clock showing seconds) and a printed log sheet.
5. **No audio, video or screen recording.** The facilitator takes handwritten/typed notes only.

### Answer key (prepared once, before the pilot)

The facilitator prepares the expected answers from the running application and keeps them in a
private sheet (paper or `outputs/usability/`, which is git-ignored). The answer key must not be
committed because it contains pseudonymous record IDs (docs/ETHICS_AND_LIMITATIONS.md §7.4).

| Key | How to obtain it |
|---|---|
| K1 top record + dominant group | top row of the ranking table in its default filter; `main_group` column and the largest bar group in "Deviation profile" (either detector's rank-1 record is accepted) |
| K2 deviations of the top record | the features named in "Why flagged" and the notable bars in "Deviation profile" |
| K3 first co-offending tie of the top record | earliest `first` date in the "Partners" tab (month resolution) |
| K4 unusual months + baseline type | triangle markers on the timeline; baseline type from the timeline title / legend ("Seasonal baseline (same calendar month, prior years)" or "Causal baseline (previous N months)") |
| K5 at least one unscored record reachable from the top record | a partner whose `partner_score` is empty (NaN); after selecting it, "Why flagged" says "Not scored: … below the minimum of 3 …" and the status reads "insufficient history" |

## 4. Session plan (~25 minutes)

| Time (min) | Step | Who |
|---|---|---|
| 0–3 | Welcome, consent form, explain think-aloud | facilitator |
| 3–6 | Standard 3-minute introduction (script §5.2), participant may ask questions | facilitator |
| 6–7 | Think-aloud warm-up (one sentence about the dashboard) | participant |
| 7–19 | Tasks T1–T5 in fixed order, max 4 min per task (timebox) | participant |
| 19–22 | SUS questionnaire (paper) | participant |
| 22–24 | Open question + short debrief | both |
| 24–25 | Facilitator completes the log; reset the app | facilitator |

Task order is fixed because T2, T3 and T5 build on the record found in T1 (see §11).

## 5. Facilitator script

### 5.1 Welcome (read aloud)

> TR: "Katıldığınız için teşekkürler. Bugün sizi değil, uygulamayı test ediyoruz; yanlış cevap
> diye bir şey yok. Lütfen yaparken aklınızdan geçenleri sesli söyleyin. İsminiz veya kişisel
> bilginiz kaydedilmeyecek; istediğiniz an bırakabilirsiniz."
>
> EN: "Thank you for taking part. We are testing the application, not you; there are no wrong
> answers. Please think aloud while you work. Your name and personal data are not recorded, and
> you may stop at any time."

### 5.2 Standard introduction (same for everyone, ~3 min)

Say only the following, pointing at each area once; do **not** demonstrate any task:

1. "The data are anonymized research records of solved burglary cases; people appear only as
   pseudonymous codes."
2. "The application ranks records whose recorded pattern differs statistically from the others.
   A high rank is a statistical deviation, **not** an accusation and not evidence of guilt."
3. "On the left: summary and ranking table. In the middle: network (top) and timeline (bottom).
   On the right: map (top) and detail tabs (bottom). At the top: replay controls."
4. "Selecting something in one view updates the other views."

### 5.3 Neutral think-aloud prompts (allowed at any time; do not count as assists)

- "What are you thinking now?" / "Şu an ne düşünüyorsunuz?"
- "What are you looking for?" / "Ne arıyorsunuz?"
- "What do you expect to happen?" / "Ne olmasını bekliyorsunuz?"
- "Please keep talking." / "Lütfen sesli düşünmeye devam edin."

If asked "Is this right?": "What would you conclude?" / "Siz ne sonuca varırdınız?"
Never say whether an answer is correct during the session.

### 5.4 Assists (count each one)

An **assist** is any task-relevant help: naming a view, tab, control or column, pointing at the
screen, or rephrasing the task in a way that reveals the route. Use assists only after ~60 s
without progress or when the participant asks for help, in this order:

1. re-read the task sentence;
2. name the area of the screen ("the tabs on the right");
3. name the exact tab/control.

After the third assist, or at the 4-minute timebox, end the task (success = 0) and, if the next
task depends on it, put the app into the required state yourself (e.g. select the top record)
and note this.

### 5.5 Closing (after SUS)

Open question (also on the SUS sheet): "What would you change first in this application, and
why?" Then thank the participant. Debrief sentence: "Again, the scores show statistical
deviations in anonymized records; they say nothing about any real person's guilt."

## 6. Tasks (exact wording)

The participant reads the task sheet (docs/usability/task_sheet.md); the facilitator reads each
task aloud in Turkish and starts timing when the reading ends.

| ID | Wording (EN; Turkish on the task sheet) |
|---|---|
| T1 | "Find the record that the application ranks highest. Which feature group contributes most to its deviation?" |
| T2 | "In one sentence, explain why this record was flagged, using the explanation the application provides." |
| T3 | "Use the time replay to find when this record's first co-offending tie appears. Give the month and year." |
| T4 | "Find a month that the application marks as unusual. Could this be a normal seasonal effect? Explain briefly." |
| T5 | "Find a record that has no anomaly score, and explain why it is not scored." |

## 7. Measures and scoring rubric

Per task and participant (one row in the observation log):

| Column | Definition |
|---|---|
| `participant_id` | `P01`, `P02`, … (`P00` = pilot, excluded) |
| `task_id` | `T1` … `T5` |
| `start_s`, `end_s` | seconds from session start: end of task reading → participant states the final answer (or timebox/abandon) |
| `success` | 0, 0.5 or 1 according to the rubric below (CSV header is `success`; allowed values 0/0.5/1) |
| `assists` | number of assists (§5.4) |
| `errors` | number of wrong paths: an action the participant must undo to reach the goal (wrong tab, wrong record, wrong control), or a wrong answer stated and then corrected |
| `notes` | short observations / think-aloud quotes **without record IDs or personal data** (write "top record", not the code) |

General rule: **1** = correct and complete with no assist; **0.5** = partially correct, or
correct only after one or two assists; **0** = incorrect, abandoned, three assists, or timebox
(4 min) reached.

| Task | 1 (success) | 0.5 (partial) | 0 (fail) |
|---|---|---|---|
| T1 | selects a rank-1 record (K1) **and** names its dominant feature group | correct record but wrong/no group, or correct after assists | wrong record |
| T2 | sentence mentions **≥ 2 concrete deviations** that appear in K2 (e.g. a named feature and its direction) **and uses no guilt language** | exactly one concrete deviation, no guilt language; or ≥ 2 after assists | no concrete deviation, **or any guilt language** ("criminal", "guilty", "suspect", "dangerous", "proves", "suçlu", "şüpheli", "tehlikeli", "kanıtlıyor") — guilt language always scores 0 for T2 |
| T3 | month and year match K3, found with the replay (Play/Step/slider) | correct month only via another route (e.g. reading the Partners tab), or off by one month, or after assists | wrong or no month |
| T4 | names a month marked unusual (K4) **and** gives a reason about seasonality consistent with the baseline type shown (seasonal baseline: unusual compared with the same month in earlier years, so plain seasonality is less likely but not excluded; rolling baseline: seasonality cannot be ruled out) | correct month but no or inconsistent reasoning | month not marked unusual / no answer |
| T5 | selects an unscored record (K5) **and** explains the minimum-history rule (fewer than 3 recorded crimes) | finds an unscored record but the reason is missing or wrong, or describes it as "normal" | no unscored record found |

T2 guilt-language check is done on the participant's sentence as written down verbatim by the
facilitator. Describing an unscored record as "normal" (T5) is a known misreading
(docs/ETHICS_AND_LIMITATIONS.md §1) and is noted in `notes`.

## 8. SUS administration and scoring

- Administered on paper **after** the tasks and **before** any discussion, using
  docs/usability/sus_questionnaire.md. Participants answer every item quickly; if an item is left
  blank, the facilitator does not fill it in.
- Responses are typed into a copy of `sus_responses_template.csv` (columns
  `participant_id,q1,…,q10`, values 1–5, empty cell = missing).
- Scoring (Brooke 1996), implemented in `src/evaluation/scoreSUS.m`:
  odd items contribute *(response − 1)*, even items *(5 − response)*;
  SUS = 2.5 × sum of contributions (0–100).
- **Missing-data rule:** a participant with any missing item gets SUS = NaN and is excluded from
  the summary (`summary.n_incomplete` counts them). No imputation.
- SUS is a single overall score; individual items are not interpreted as separate scales.
- The Turkish wording is a **project translation**, not a validated Turkish SUS (see the note in
  the questionnaire); this is reported as a limitation.

Context only, not a pass/fail threshold: Bangor, Kortum & Miller (2008) report a mean SUS of
about 70 (70.14, SD 21.71) over the surveys in their data set; an average of about 68 is also
widely quoted in practitioner literature. With 5–8 participants our mean is imprecise, so it
is reported next to these values, never "tested" against them.

## 9. Data handling and privacy

- Working copies of the filled CSVs live in **`outputs/usability/`**, which is git-ignored
  (`.gitignore`: `outputs/usability/*`), or outside the repository. Raw logs are **never
  committed**.
- File names: `outputs/usability/observation_log.csv`, `outputs/usability/sus_responses.csv`.
- Only `P`-IDs are stored. There is no list linking IDs to names. Paper consent forms carry no
  name (tick boxes + date) and stay with the facilitator; they are not scanned or uploaded.
- Notes must not contain record pseudonyms (`OID#…`), personal data or quotes that could
  identify a participant.
- No recordings and no screenshots during sessions.
- Only aggregate tables (and per-participant SUS scores labelled by `P`-ID) appear in the report.
- Raw files are deleted after the course grade is final, unless the supervisor asks otherwise.
- Before running sessions, ask the supervisor whether the university requires an ethics
  committee application for an anonymous classroom usability test; record the answer in
  docs/RESEARCH_LOG.md. This protocol does not assume either answer.

## 10. Analysis plan (descriptive only)

n is small (5–8), so **no significance tests, no confidence claims about a population**.

```matlab
setupProject();
L = readtable("outputs/usability/observation_log.csv", "TextType", "string");
L = L(L.participant_id ~= "P00", :);                 % drop the pilot
taskSummary = summarizeUsabilityLog(L);              % n, success_rate, median_time_s, mean_assists, mean_errors
R = readtable("outputs/usability/sus_responses.csv", "TextType", "string");
R = R(R.participant_id ~= "P00", :);
[sus, susSummary] = scoreSUS(R);                     % per participant + n, mean, sd, median, min, max
```

Report:

1. Per task: n, success rate, median time (s), mean assists, mean errors (table below).
2. Per participant SUS scores (dot/strip plot) and n, mean, SD, median, min–max.
3. T2: number of explanations with ≥ 2 deviations and number with guilt language.
4. Usability issues from notes: one line each, with the number of participants who hit it and a
   severity (minor = slowed down, major = needed an assist, critical = task failed); ordered by
   severity then frequency.
5. Open-question answers, grouped by theme.

Verification of the scoring code: `runtests("tests/test_usability_scoring.m")` (hand-computed
cases: all 3s → 50, best → 100, worst → 0, two mixed rows → 75 and 30, NaN handling, invalid
input errors, table = matrix, two-task log summary).

## 11. Limitations

- Small convenience sample of classmates: not representative of analysts; results describe this
  group only.
- Fixed task order (T2, T3, T5 depend on T1): learning effects are not counterbalanced.
- The facilitator is a project member (possible bias in prompts and scoring); mitigated by the
  fixed script, assist ladder and written rubric.
- The interface is in English while participants are Turkish speakers; language may affect times.
- Think-aloud slows task completion; times are relative, not benchmarks.
- Turkish SUS wording is an unvalidated project translation.
- Lab-like session with an answer key known to the facilitator; no real analysis workload.

## 12. Results templates (fill in after the sessions; currently empty)

Sessions run: ____ (dates) · participants analysed: n = ____ · pilot excluded: ____ ·
app commit: ____

| Task | n | Success rate | Median time (s) | Mean assists | Mean errors |
|---|---|---|---|---|---|
| T1 | | | | | |
| T2 | | | | | |
| T3 | | | | | |
| T4 | | | | | |
| T5 | | | | | |

| SUS | n | Mean | SD | Median | Min | Max | Incomplete |
|---|---|---|---|---|---|---|---|
| All participants | | | | | | | |

| Issue | Participants affected | Severity | Proposed fix |
|---|---|---|---|
| | | | |

## 13. How results enter the report

- A separate "Application evaluation (E10)" subsection, after the model evaluation, with the
  three tables above, the SUS strip plot and the issue list; model performance and usability are
  not mixed (docs/EVALUATION.md, "Reporting principle").
- State n, the convenience sample, the absence of significance tests and the translation caveat
  in the same subsection.
- Fixed issues are listed in CHANGELOG.md with the participant-observed problem they address.
- Update docs/TASKS.md (T-066) to ✅ only when sessions are run and the tables are filled.

## References

- Brooke, J. (1996). SUS: A "quick and dirty" usability scale. In P. W. Jordan, B. Thomas,
  B. A. Weerdmeester & I. L. McClelland (Eds.), *Usability Evaluation in Industry*
  (pp. 189–194). Taylor & Francis.
- Bangor, A., Kortum, P. T., & Miller, J. T. (2008). An empirical evaluation of the System
  Usability Scale. *International Journal of Human–Computer Interaction, 24*(6), 574–594.
  https://doi.org/10.1080/10447310802205776
