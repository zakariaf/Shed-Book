# 01 — Adversarial critique of the skill catalogue

**Reviewing:** [`00-catalogue.md`](00-catalogue.md) v1.0 (2026-07-27) against
[`research/01`–`04`](research/), [`../engineering/CONVENTIONS.md`](../engineering/CONVENTIONS.md),
[`../engineering/00-README.md`](../engineering/00-README.md),
[`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) and
[`../design/indelible.md`](../design/indelible.md).

**Verdict: the shape is right, the sizing is wrong, and it is not safe to author yet.**

The two-front-door structure, the negative-trigger discipline, the runbook/`disable-model-invocation`
split and the refused-merges section are all correct and better than any published Flutter skill set.
Three things must change before a single `SKILL.md` is written:

1. **The listing budget arithmetic is wrong, and it fails silently.** 27 descriptions at the stated
   lengths total **~20,800 characters**. The budget is 1% of the context window — **~8,000 characters
   on a 200k model**. It is 2.6× over, and the overflow drops the *least-invoked* skills' descriptions
   first, which is the design half. §1.1.
2. **Five of the six proposed `scripts/` violate decision #9/#10** — *"One `tool/check_policy.dart`
   with a rule table, one allowlist file, one exit code."* The design half proposes five new
   source-scanning gates. §6.
3. **The blocking-conflict list is missing six conflicts, three of them worse than any of P1–P7** —
   including one that makes `undo` unimplementable as specified. §9.

Also structural: **eleven skills restate content the doc set owns**, which is the failure mode §7.3 of
the catalogue itself names and then commits (§7).

Corrected catalogue in §10: **31 skills, 28 listed** — 20 engineering, 11 design, 3 manual runbooks.

---

## 1. The three defects that are not opinions

### 1.1 The listing budget overflows at the stated description lengths

Measured, unfolding every `>-` block scalar in §3 of the catalogue:

| | chars |
|---|---:|
| 30 descriptions, total | 20,966 |
| 27 auto-triggered (excl. the 3 runbooks) | 19,670 |
| + ~40 ch/skill name and listing overhead | **~20,750** |

Against the documented budget (research 01, 03 §2.4 — 1% of the model's context window):

| Model context | 1% budget | 2% budget | Fits at 1%? |
|---|---:|---:|---|
| 200k | ~8,000 ch | ~16,000 ch | **No — 2.6× over** |
| 1M | ~40,000 ch | — | Yes |

The catalogue's claim — *"27 is inside the safe band"* — is true only on a 1M-context model and is
asserted without arithmetic. On the model most sessions actually run, the listing truncates, and
research 03 §2.4 is explicit that *"Claude Code drops descriptions starting with the skills you invoke
least."* The engineering skills fire constantly; the design skills fire per visual task. **The design
half loses its descriptions first — the half whose entire purpose is "there is exactly one way to draw
each thing".** The failure is silent and the files are unchanged.

Two levers, and both are needed, not one:

- **Cut the mean description from 698 to ~400 characters.** Research 02 §1.4's actual recommendation is
  *"aim for 200–600 characters"*; the catalogue set its own floor at 400 and then wrote 698. 28 × 420 ≈
  11,800 ch.
- **Set `skillListingBudgetFraction: 0.02`** in `.claude/settings.json` from day one, not as a
  contingency after `/doctor` complains. 11,800 < 16,000, with headroom for a 29th skill.

**Where the 300 characters per description go.** Every description in §3 is roughly 70% inventory of
contents and 30% trigger. `shed-testing` lists thirteen things it contains; `shed-domain` lists nine.
That is the `flutter-modern` keyword-dump anti-pattern named in research 04 §3.4, and research 04 rule
4 states it directly: **"Do not summarise the workflow inside the description."** P5 records an agent
following a description's summary instead of reading the body. Cut the inventory; keep the trigger
vocabulary and the negative.

### 1.2 Five design `scripts/` are five new gates, and the project has exactly one

`00-README.md` §3.1, decisions #9 and #10:

> **Enforcement** — **One** `tool/check_policy.dart` with a rule table, one allowlist file, one exit
> code — 8 layer rules, banned text, design tokens and the dependency allowlist

`06-design-system.md` §3.5 restates it: *"Every design rule in §3.5 is a row in
`tool/check_policy.dart`'s `_bannedText` or `_bannedPattern` … **there is no second script** and no
inline comment escape hatch."*

The catalogue proposes `indelible_audit.sh`, `check_type.sh`, `check_gestures.sh`,
`check_no_placeholder.sh`, `check_no_erasure.sh`. Every one is a source scan. Every one is a second
gate with its own exit code and no allowlist, and every one duplicates a rule that must already be a
`check_policy` row. **Cut all five.** The rules become rows; the skills say *"run `make check`; a red
gate is never turned green by editing the gate or its allowlist."*

The one script that survives is `contrast.py`, and only in a narrowed form — see §6.

### 1.3 The overlap audit was not run

§5 is titled *"Fourteen pairs could plausibly both fire"* and contains **sixteen** rows. It says
*"Three pairs are designed to co-fire"* and marks **two**. A section whose stated job is to be *"the
acceptance test for the descriptions"* has not itself been checked. §2 below runs it properly and finds
seven collisions it does not contain, three of which are contradictions rather than ambiguities.

---

## 2. Trigger collisions

Read as the model reads: every description, scored against the intent, no knowledge of the routing
table. `»` = fires.

| Developer intent | What actually fires | Verdict |
|---|---|---|
| "add a button" | `indelible-buttons` » `indelible-targets-and-gestures` » `indelible-design-system` » (`shed-write-path` if the word is *Save*) | OK — 4 but they agree, and the Save catch is the point |
| "add the ease buttons" / "a segmented control" | `indelible-buttons` » `indelible-input-and-sheet` | **Collision C1** |
| "add a screen" | `shed-screens-and-routing` » `indelible-screen-composition` » `indelible-page-grid-and-rows` » `shed-engineering` » `indelible-design-system` » `shed-testing` | **Collision C2 — six** |
| "record a lambing" / "the tally" | `indelible-tallies-and-blocks` » `shed-screens-and-routing` » `shed-riverpod-providers` » `indelible-screen-composition` » `shed-write-path` (weakly) | **C2 + C3** |
| "add undo" | `shed-write-path` » `shed-screens-and-routing` » `indelible-strike-and-query` | **Collision C4 — three, two identical claims** |
| "add a column" / "name this column" | `shed-drift-schema` » `shed-conventions` | **Collision C5** |
| "never silently correct that" / "let them fix a typo" | `shed-safety-rules` » `indelible-strike-and-query` | **Collision C6 — same rule, two authorities** |
| "fix the contrast" / "the contrast test fails" | `indelible-color-and-contrast` » `shed-testing` | **Collision C7** |
| "add a label" / "rename this string" | `shed-accessibility-and-copy` » `shed-conventions` » `shed-safety-rules` | **Collision C8 — three** |
| "add a package" / "let's use fl_chart" / "pub add" | **nothing reliable** | **Gap G1 — see §5** |
| "make it faster" / "janky at 400 ewes" | **nothing** | **Gap G7** |
| "change the schema" | `shed-drift-schema` — and its Do-NOT actively pushes `make gen` away to a runbook that cannot auto-fire | **Routing defect R1** |
| "the golden is red" | `shed-testing` — whose Do-NOT sends the agent to a runbook it cannot load | **Routing defect R2** |

### C1 — `indelible-buttons` ↔ `indelible-input-and-sheet`

`indelible-buttons` opens *"There are exactly two button forms in this app"* and closes *"even when the
request never uses the word button"*. `indelible-input-and-sheet` claims *"the five-button ease group"*
and the keypad key and the stepper's `±`. There are six pressable forms in Indelible, not two, and the
buttons skill's opening sentence is false on its face. An agent asked for a segmented control and
holding only `indelible-buttons` will build it from word buttons.

**Fix — both descriptions, reciprocally.** Buttons says *two action forms*, and its Do-NOT names the
ease group by name. Input says *controls that capture a value, including the ones that look like
buttons*.

### C2 — "add a screen" loads six skills

Research 02 §7.1: *"Skills scoped too narrowly force multiple skills to load for a single task, risking
overhead and **conflicting instructions**."* Research 04 P19 repeats it. Six bodies, each persisting for
the session, is the documented failure — and three of them (`page-grid-and-rows`,
`screen-composition`, `design-system`) will each state a version of the same geometry.

**Fix — sequencing, not co-firing.** The catalogue has no rule bounding concurrent loads. Add one:

> **Every intent in the routing table resolves to at most two auto-firing skills.** Where a task
> genuinely spans more, the owning skill carries the ordered pipeline and names the next skill to load,
> one at a time. A skill that expects three others to be loaded with it is mis-scoped.

`shed-screens-and-routing` becomes the owner of the add-a-screen pipeline (nine files, in order:
route entry + push helper → controller → write controller → screen → ARB strings → widget test →
matrix variant +1 → empty-state row → §12 disclosure row) and ends by naming
`indelible-screen-composition`. The design half is loaded *after* the wiring exists, not alongside it.

### C3 — `shed-write-path` does not list the app's most common write

Its trigger list is *"a mutation, an undo, a strike, a foster, a pen move, a treatment, a care check"*.
**"a lambing" and "a lamb" are absent** — the two verbs (`beginLambing`, `addLamb`) that are the
product, the only two that return an id and throw (CONVENTIONS R32), and the ones an agent will write
first. Add them, first.

### C4 — three skills claim `undo`

- `shed-write-path`: *"undo defined per verb and living only until the receipt is dismissed"*
- `shed-screens-and-routing`: *"undo per verb"*
- `indelible-strike-and-query`: *"Use whenever a delete, remove, **undo**, hide … behaviour is being
  designed or implemented"*

Two of the three state the same rule in the same words, which is how drift starts. `07-screens.md` §15
owns *"Undo and delete semantics, per verb"* — the table, the window, the process-death rule, the
"Cancel is not a verb" rule. `01-architecture.md` §4.2 owns event verbs and nothing about undo.

**Fix.** `shed-screens-and-routing` is the sole owner of undo. `shed-write-path` deletes the clause and
says *"a verb's undo is `shed-screens-and-routing`'s"*. `indelible-strike-and-query` owns the *strike*
— the visual and permanence law — and its Do-NOT names undo as screens-and-routing's.

### C5 — `shed-drift-schema` ↔ `shed-conventions` on column naming

Drift-schema claims *"the dual-key id strategy … the provenance quad … CHECK conventions"*; conventions
claims *"the naming of … database columns"*. CONVENTIONS §4.6 is **BINDING** and R37/R38 fix the exact
spellings (`occurred_at`, `captured_at`, `original_effective` — *never* `original_effective_at`). A
schema skill that restates them can only be right or stale; it can never outrank CONVENTIONS.

**Fix.** Drift-schema owns *what a column is* (type, constraint, index, storage encoding); conventions
owns *what it is called*, and drift-schema's Do-NOT says so and cites the ruling numbers rather than
the spellings.

### C6 — `shed-safety-rules` ↔ `indelible-strike-and-query`

Safety rule §12.4 is *"never silently correct a user's entry"*. Indelible Rule 1 is *"nothing is ever
removed, only struck"*, and its §9 safety table restates §12.4 in its own words. **These are the same
rule with two authorities and two vocabularies** — one says `Warning`/`Reviewed<T>`/no `fix()`/`lib/data`
may not import `lib/domain/validation/`; the other says strike line, query mark, both times printed,
the app never picks. This is the highest contradiction risk in the catalogue and **the audit does not
contain the pair.**

**Fix.** Safety owns the *mechanism and its level* (unrepresentable → unconstructible → unpersistable →
source test). Strike-and-query owns *what the shepherd sees and what must persist*. Both descriptions
carry the reciprocal negative, and `indelible-strike-and-query` states in its body that §12.4's
mechanism is `shed-safety-rules`' and must not be restated.

### C7 — `indelible-color-and-contrast` ↔ `shed-testing`

Colour claims *"checking a contrast ratio … recomputed against the shipped token block"*; testing claims
*"accessibility and tap targets and contrast as executable gates"*. `test/design/contrast_test.dart`
already recomputes every published ratio (06 Definition of done).

**Fix.** Choosing or proposing a value is colour; making the assertion pass is testing. Colour's Do-NOT
names `shed-testing`. Same boundary applies to tap targets (`indelible-geometry-and-targets` vs
`shed-testing`'s two gates) and semantics (`shed-accessibility-and-copy` vs the semantics gate). State
it once as a rule: **the design skills own the value; `shed-testing` owns the assertion.**

### C8 — three skills claim copy

`shed-accessibility-and-copy` (ARB, description, placeholder), `shed-conventions` (one word per
concept, banned words), `shed-safety-rules` (ContentPolicy, no veterinary advice, disclaimers
referenced never re-typed). All three fire on "rename this label". They do not contradict, but three
bodies for a one-line change is the bloat research 02 §7.2 warns about.

**Fix — cheapest available.** The banned-words list is already going into `CLAUDE.md` (catalogue §7.1),
where it is *present* rather than *consulted*. Move the one-word-per-concept table there too and drop
the clause *"or in copy"* from `shed-conventions`' description. Two skills, not three.

### R1 — `make gen` is stranded behind a manual runbook

`shed-drift-schema`'s Do-NOT: *"Do NOT use to run codegen … which is the manual
shed-codegen-and-migrations runbook."* That runbook carries `disable-model-invocation: true` and its
description *is not in context at all* (research 01, invocation matrix). So the agent that adds a column
is told, by the skill it correctly loaded, **not** to run the one command that makes the change valid —
and the `codegen` CI job fails on `git diff --exit-code`, or worse, the agent hand-edits a `.g.dart`.

`make gen` is idempotent regeneration. It is not destructive. Research 02 §7.4's criterion for
`disable-model-invocation` is *"workflows with side effects (deploy, delete) that should never
auto-trigger"*.

**Fix.** Split the runbook. `make gen` and *"the regenerated files land in the same commit"* move into
`shed-drift-schema`'s body (and the command is already in `CLAUDE.md`). The manual runbook keeps only
the irreversible half — the hand-written `from<N>To<N+1>` step, `drift_dev schema steps`, the committed
snapshot, the from→to verifier matrix — and is renamed **`shed-migrations`**.

### R2 — the golden prohibition is in the file the agent cannot load

`shed-testing`'s Do-NOT sends golden work to `shed-goldens-rebaseline`, which cannot auto-fire. The
failure this is meant to prevent — *an agent running `--update-goldens` to make a red test green* — is
committed by an agent holding `shed-testing` and nothing else.

**Fix.** The *prohibition* lives in `shed-testing`, as a `grounded-copy`-style integrity rule (research
04 §5 layer 5): *"Never run `flutter test --update-goldens`. A red golden is a failing test until a
human has looked at the image. Re-baselining is `/shed-goldens-rebaseline`, invoked by the developer,
landed as its own commit."* The runbook keeps the procedure. Add a hook (§8) that blocks the flag
outright — `12-testing.md` §11.4 already argues exactly this about the `Makefile` target name.

---

## 3. Descriptions that will not fire

| Skill | Problem | Fix |
|---|---|---|
| `shed-engineering` | *"Use at the start of any work on this Flutter app"* is a use-always description with no distinctive vocabulary. It loses every contest with a specific skill, and research 02 §1.1 / 04 P4 say simple one-step requests trigger nothing at all. **The four non-negotiables are only in here, so when it does not fire they are absent.** | Move the four non-negotiables — the offline wording verbatim, the 3am question, the five safety rules as headlines, "every write commits immediately" — into `CLAUDE.md`, where they are *present* not *consulted*. The skill becomes a router plus the add-a-feature pipeline, triggered on multi-layer work. |
| `indelible-design-system` | Same shape, but survives — *"before drawing or changing any pixel … a colour, a size, a spacing, an animation, a haptic"* has real vocabulary. | Keep. Add the gesture ban (§4). |
| `shed-monetization` | Its Do-NOT names no competing skill: *"Do NOT use for the five shed screens, which render nothing monetization-related."* That is a rule, not a boundary. Research 02 §1.2 / §1.5: the negative must name the actual competitor. | Do-NOT names `indelible-states-and-feedback` (how the upgrade row is drawn) and `shed-screens-and-routing` (where it may render). |
| `shed-code-review` | Same — *"Do NOT use as the authority on any individual rule"*. Also collides in name-space with Claude Code's bundled `/code-review`, which the model may prefer. | Do-NOT names `shed-safety-rules`. Body opens by stating it is the project review, not the bundled one. |
| `shed-safety-rules` | Its first 60% is the mechanism hierarchy — content, not trigger. The trigger clause is good and buried. | Lead with the triggers: *default, pre-fill, suggest, autofill, disclaimer, validation, correct, fix, edit a stored value*. |
| all 27 | Missing vocabulary a developer actually types: `pubspec`, `package`, `dependency`, `analyze`, `lint`, `format`, `build`, `widget`, `SQL`, `query`, `stream`, `rebuild`, `profile`, `isolate`, `frame`. Several appear nowhere in any description. | See §5 G1 and the rewrites in §11. |

---

## 4. Wrong granularity

**Eight engineering skills at L (200–250 lines + references) is too many.** Anthropic's shipped median
is 129 lines; two-thirds are under 250 (research 02 §2.2, 04 §2). More decisively, the length is
*caused* by a mistake: the L skills are large because they plan to copy the doc set into
`references/`. Once §7's no-restatement rule applies, they shrink on their own.

| Skill | Catalogue | Corrected | Why |
|---|---|---|---|
| `shed-conventions` | L + 4 refs (type catalogue, provider catalogue, layer rules, vocabulary) | **S, no refs** | CONVENTIONS §2 and §3 are ~400 lines of exact signatures, **BINDING**, and outrank any skill. A copy can only be right or wrong; it can never win. The skill carries the tree, the eight layer rules as one table, the banned words, and the naming table — and cites ruling numbers. |
| `shed-screens-and-routing` | L + `ref screen-briefs` | **M, no refs** | The catalogue's own §7.3 says *"The twelve screen briefs verbatim … stays a document"*, then §2.1 gives the skill `references/screen-briefs`. Direct self-contradiction. |
| `shed-domain` | L + `ref statistics` | **M + 1 ref** | R61: *"Statistic `definition` strings are 05's, verbatim"* — and those strings are **printed into CSVs and PDFs that outlive the app**. A second copy in a skill reference is a correctness hazard, not a convenience. The skill names `lib/domain/stats/definitions.dart` as the only source. |
| `shed-drift-schema`, `shed-riverpod-providers`, `shed-export-and-restore`, `shed-platform-gateways`, `shed-testing` | L | **M** | Same cause. Each keeps the references that are genuinely *subset-loaded* (the Riverpod-3 ban list, the CSV shapes, notifications-vs-capture, the overflow matrix) and drops the ones that are transcriptions. |
| `indelible-targets-and-gestures` | S, standalone | **merged** | See below. |
| `shed-goldens-rebaseline` | S runbook | **keep, shrink** | Zero listing cost; the procedure is real. But its protective half moves to `shed-testing` (R2). |

**One merge.** `indelible-targets-and-gestures` and `indelible-page-grid-and-rows` are one body of
knowledge: page geometry. Grid already owns *"the margin cell that is itself a tap target"*, the
ten-step spacing scale, row heights and 200%-scale behaviour; targets owns the 64 floor, separation,
the reach bands, the 560px rule and the left-handed mirror. Every number in both comes from
`indelible.md` §4. Merge into **`indelible-geometry-and-targets`**.

The gesture ban is the odd half of that skill, and it does not need its own home: *"swipe to delete"*
already lands on `indelible-strike-and-query` (which gives the correct answer — there is no delete) and
*"add a slider"* lands on `indelible-input-and-sheet` (the stepper replaces every slider). The complete
ban list goes to `indelible-design-system`, which already carries *"the list of what this system does
not have"*.

---

## 5. Gaps

### G1 — Adding a dependency has no authority. This is the largest hole.

The single most dangerous routine act in this repo is `flutter pub add X`. It can void the product's
central public claim (the offline contract), break the analyzer ceiling (decision #2), or re-admit a
package rejected with a reason (decision-record §5.3 lists ~40).

What fires on *"let's use fl_chart for the spread chart"* or *"add the csv package"*:

- `shed-platform-gateways` — only if the word "plugin" appears. `csv`, `fl_chart`, `freezed`, `get_it`,
  `go_router` are not plugins.
- `shed-engineering` — the word "dependency" appears once, mid-list, in an em-dash enumeration.
- `shed-release` — owns G0–G5 and the permission set, and **carries `disable-model-invocation`, so its
  description is not in context at all.**

Nothing reliable fires. Meanwhile the doc set has a great deal to say: the pinned exact versions, the
`build_runner` range that does not resolve at `^2.15.2`, `package:test` never being a direct
dependency, `flutter_timezone` unaudited and banned from any pubspec, the G2 allowlist over
`pubspec.lock`, the G3 import scan, and the anti-pattern of a *"no `http` in `pubspec.lock`"* rule that
is unsatisfiable.

**New skill: `shed-dependencies-and-toolchain`** (auto-firing). Owns `pubspec.yaml`,
`analysis_options.yaml`, the `Makefile` targets, the pinned table, the rejected list with its
alternatives, G2/G3, and — most importantly — the `grounded-copy` integrity rules on the gate
(research 04 §5 layer 5):

> Never edit `tool/check_policy.dart`, its rule table, or its exit code to make a build pass. Never add
> a line to `tool/policy_allowlist.txt` or `android/expected_permissions.txt` to silence a gate. If a
> gate is genuinely wrong, say so and stop. **User instructions outrank this skill; your own
> convenience does not.**

That last clause is the one device research 04 §3.2 measured as reliably stopping invention, and the
catalogue currently has it nowhere.

### G2–G6 — UI elements with no design authority

Walking Indelible §7's seventeen components against `06-design-system.md` §12's twenty-one:

| # | Element | Engineering says | Indelible says | Design owner |
|---|---|---|---|---|
| G2 | **The save confirmation / receipt** | `ShedReceiptBar`, `confirmSaved`, `feedback.dart` is *"the one file permitted to call `showSnackBar(`"* (CONVENTIONS §2.11, R30, R31) | §9: *"no toast, **no snackbar**, no modal dialog anywhere in the app"* | **none** |
| G3 | **The upgrade row** | `ShedBanner`, renders on Flock and Settings, *"the only monetization component that exists"* (06 §12) | no banner; screens 1 and 12 describe no upgrade row | **none** |
| G4 | **Frame 1, Empty, Filtered-empty, Error** | 07 §1.4 + §2.2: a fixed-height placeholder, one line of copy + one action per screen, a dark error panel with "Try again" and "Diagnostics" | §1.3: no spinner, no skeleton, no empty-state illustration — and nothing about what *is* drawn | **none** |
| G5 | **Photo and voice note** | `ShedPhoto` (the only `ColorFiltered`), `CameraService`, `VoiceRecorder`, `media_assets` | **no image or audio component anywhere in §7** | **none** |
| G6 | **Note search (the 13th route)** | `Routes.noteSearch`, the 14th overflow-matrix variant, three distinct empty strings (07 §2.2) | §8 covers twelve screens | **none** |

**New skill: `indelible-states-and-feedback`.** Owns G2, G3, G4 and G6 — everything the page shows when
there is no record, when the write returns, or when the app has something to say about itself. Coherent
trigger family: *"the empty state"*, *"show a confirmation"*, *"the loading state"*, *"an error"*,
*"the upgrade row"*, *"the export prompt"*.

G5 folds into `indelible-input-and-sheet` at zero cost — its scope is already stated as *"every way the
shepherd puts a value into Shed Book"*, and a photo and a voice note are values. Its description adds
*"a photo, a voice note"*.

**On "is a second button style impossible?"** — after C1's fix, yes for *actions*. But note that the
answer depends entirely on P8 being settled (§9): while `06-design-system.md` §12 still names
`ShedChoiceRow` for birth type and Indelible says *"there is no segmented control, because there is no
choice"*, a second form is not merely possible, it is documented.

### G7 — Performance and rebuild scope

*"The pen board rebuilds every second"*, *"scrolling is janky at 400 ewes"*, *"should this be an
isolate"*, *"profile this"* — nothing fires. The knowledge exists and is scattered:
`01-architecture.md` §7 (what is computed vs stored, and the rule that time-relative values are
**never** stored), the one-query rule and the SQL fan-in ban (07 §1.2), the single 60 s ticker
(R25), the PDF isolate (09), the startup budget (13 §6.2, inside a manual runbook).

Cheapest correct fix, no new skill: `shed-riverpod-providers` absorbs rebuild scope, `select`, the
ticker and *"never store a time-relative value"*, and its description gains `rebuild`, `janky`,
`profile`, `select`. The startup budget stays with `shed-bootstrap-and-errors`, whose description gains
*app lifecycle, resume, the clean-pause `session.lock`, and a dirty resume* — currently 13 §7 has no
owner at all.

### G8 — Smaller, worth one line each in an existing skill

- `tool/seed.dart` — writes the demo DB **through the restore path**, and is the precondition for
  400-ewe profiling, the overflow matrix, the goldens and the at-cap tests. No skill mentions it.
  → `shed-testing` + `shed-export-and-restore`.
- FTS5 / `search.drift` / the two search problems → `shed-drift-schema`.
- `seedFirstRun` and the `onCreate` season insert → `shed-drift-schema`.
- The analyzer strict-language block and `--fatal-infos` → new `shed-dependencies-and-toolchain`.

---

## 6. Richness that is padding

| Extra | Verdict |
|---|---|
| `D1 scr indelible_audit.sh`, `D3 scr check_type.sh`, `D5 scr check_gestures.sh`, `D8 scr check_no_placeholder.sh`, `D9 scr check_no_erasure.sh` | **Cut all five.** §1.2 — they are five new source-scanning gates and the project has one by decision. Every rule they would check is already required to be a `check_policy` row by 06 §3.5. |
| `D2 scr contrast.py` | **Keep, narrowed.** `test/design/contrast_test.dart` already recomputes every *shipped* ratio; a Python re-implementation of the WCAG formula that can disagree with the Dart one is a liability. Narrow it to the one job the Dart test cannot do: **take two proposed hexes, print the ratio and the pass/fail against 4.5 and 3.0.** State in the body: *run it before proposing a colour; the shipped values are proved by `dart test test/design/contrast_test.dart`.* |
| `tpl arb_entry` | **Cut.** Four lines of JSON. |
| `tpl screen_scaffold` | **Cut as a template.** A screen is nine files across five skills; one file cannot scaffold it and nothing generates from it. It becomes the ordered checklist in `shed-screens-and-routing`'s body (C2). |
| `tpl provider.dart`, `repository_verb.dart`, `table.dart`, `gateway.dart`, `widget_test.dart`, `migration_step.dart` | **Keep, renamed `examples/`.** Nothing consumes them as templates — there is no scaffolding script — so they are complete correct artefacts, which research 02 §5.2 calls an example. Two directory conventions for one purpose is noise. Each must be a file that actually compiles with this project's exact imports, or it is decoration. |
| `D3 ex text_theme.dart`, `D4 ex ruled_row.dart`, `D6 ex dashed_rule_painter.dart`, `D7 ex buttons.dart`, `D8 ex shed_keypad.dart`, `D10 ex tally_marks.dart` + `spread_chart.dart` | **Cut all seven.** These *are* the real files — they will exist at `lib/core/ui/components/`. Shipping a copy inside a skill creates the second authority the catalogue's own §7.3 forbids, and it goes stale the first time the widget changes. Replace each with a named path: *"the reference implementation is `lib/core/ui/components/shed_tally.dart`; read it before drawing a second one."* Geometry that is genuinely fiddly (the five-bar gate's crossing stroke) is ten lines of SVG and belongs inline in the body, where research 02 §3.6 says a gotcha must live — **you cannot progressive-disclose a surprise.** |
| `E13 ex lambs.csv` | **Keep.** A golden output artefact resolving RFC 4180 quoting, the `struck`/`struck_at` columns and the disclaimer trailer — exactly the "expected output format" pattern, and prose cannot settle it. |
| `E3 ex main.dart`, `E5 ex foster_verb.dart`, `E8 ex clear_date.dart` + `clear_date_dst_test.dart` | **Keep.** Each resolves an ordering or edge-case judgement prose cannot: what `main()` may not await, an event verb's full transaction shape, and the spring-forward case. |
| Every `references/` that transcribes a doc-set section | **Cut.** §4 and §7. |

Net: **6 scripts → 1 · 8 templates → 6, as examples · 11 examples → 4 · references roughly halved.**

---

## 7. Contradiction risk — the rule the catalogue needs and does not have

The catalogue's §7.3 states the principle perfectly and then violates it in §2.1:

> *"Skills carry operative rules; the decision record carries why … Distilling it would create a second
> authority that drifts."*

Eleven skills as specified restate content that a **BINDING** document owns. The worst four:

| Skill | Restates | Why it can only lose |
|---|---|---|
| `shed-conventions` | CONVENTIONS §2 type catalogue, §3 provider catalogue | CONVENTIONS *outranks every document on any name, path, type shape, signature or word*. A restatement cannot outrank it, so its only possible states are "identical" and "wrong". |
| `shed-domain` | Every statistic's verbatim `definition` string | R61 — those strings are printed into exports that outlive the app. Two copies is a correctness defect, not a maintenance one. |
| `shed-drift-schema` | Column spellings, the provenance quad names | R37/R38 fixed these against an explicit stale-claim sweep. A skill re-typing `original_effective` is one edit from re-introducing `original_effective_at`. |
| `shed-riverpod-providers` **and** `shed-write-path` | The catalogue **deliberately** duplicates the warnings rule: *"stated in both … and both statements are identical."* | Two identical sentences in two files is the definition of drift risk. R53 assigns the rule to the controller. One owner states it; the other points. |

**Adopt this as a house rule, in §1 of the catalogue:**

> **No skill restates a name, a signature, a column spelling, a stored key, a version number or a
> verbatim user-facing string.** It states the *rule*, cites the owning document and ruling number
> (`CONVENTIONS R37`, `05 §3`, `decision #25`) and names the file path where the value actually lives.
> A skill that would go stale when a doc changes is written wrong.

This is also what makes the size reductions in §4 possible: the skills get short because the doc set is
in the repo and readable.

**One more contradiction the catalogue creates for itself:** it forbids `paths:` on every skill,
correctly (the design skills must fire *before* the file exists). But it then loses the staleness signal
research 03 §8.2 recommends. Recover it without the activation cost: **extend `tool/lint_skills.py` to
assert that every repo path named in a skill body exists.** A skill that names `lib/features/foo/` after
a rename fails the pre-commit hook.

---

## 8. Missing runbooks and missing mechanical checks

### Should be a hook, is currently prose

| Rule | Where it is now | Should be |
|---|---|---|
| `flutter test --update-goldens` is never run | prose in a manual-only runbook the agent cannot load (R2) | **`PreToolUse` hook blocking the flag.** 12 §11.4 already argues this about the `Makefile` target name. |
| `pubspec.yaml` changed without a `pubspec.lock` diff, or vice versa | prose in 00-README §7.1 (*"a review stop"*) | **hook.** It is mechanical and it is exactly what an agent rationalises past. |
| `android/expected_permissions.txt` edited | named as *"the single worst thing you can do to this project"* in 13 §2.3 | **hook**, alongside the `policy_allowlist.txt` hook the catalogue already plans. |
| Every repo path named in a skill body exists | nothing | **`tool/lint_skills.py` extension** (§7). |

### Should be a script, is currently prose

| Rule | Fix |
|---|---|
| The 252-cell matrix arithmetic | 00-README step 25 already says *"the arithmetic follows the variant list, never a remembered number"* — so the constant is computed in the test, and `shed-testing` must say **the number is derived, never typed**. Adding a screen makes it 270, not a lint error. |
| Indelible acceptance tests 1, 7, 8 (grep `DELETE`/`remove`/`splice`/`hidden`; grep `Save`; grep `placeholder`) | `check_policy` rows, not three shell scripts (§1.2). |
| A proposed colour's contrast ratio | `contrast.py`, narrowed (§6). |

### Missing runbook

**None, except by renaming.** `shed-codegen-and-migrations` → `shed-migrations` (R1). The pipeline that
*looks* like a missing runbook — "add a screen" — must not be one: a runbook cannot auto-fire, and the
add-a-screen pipeline must fire. It belongs in `shed-screens-and-routing`'s body.

---

## 9. The corrected blocking-conflict list

The catalogue's P1–P7 are all real. **Six more, three of them worse than any of them**, and one
re-scoped. Nothing in the design half may be authored until P1–P4 and P8–P9 are ruled; §6 already says
this about P2–P5 and does not know about the rest.

| # | Conflict | Blocks | Severity |
|---|---|---|---|
| **P1** | `struck` / `struck_at` on every table. Indelible Rule 1 means no row is deleted, every query decides whether struck rows count, and both CSV and PDF carry the columns. `03` has no such columns. **Schema-irreversible.** *(unchanged)* | D8, E7, E14, E16 | **Blocking — before schema freeze** |
| **P2** | **NEW — the receipt.** `CONVENTIONS` §2.11: `feedback.dart` is *"the one file permitted to call `showSnackBar(`"*; `SaveReceipt` carries the `undo` callback; 00-README §2.4 and 07 §15.2 define the undo window as *"until the SnackBar is dismissed"*. Indelible §9: *"no toast, **no snackbar**, no modal dialog anywhere in the app."* **Undo as specified is unimplementable under Indelible.** | E6, E11, D11, CONVENTIONS R30/R31 | **Blocking — a named type and a safety-adjacent window depend on it** |
| **P3** | **NEW — the navigation model.** `02` ships `Navigator` 1.0, `RouteNames` (13), `Routes` (12 typed push helpers), a back behaviour and a 2-minute resume reset. Indelible §7.17: *"There is no tab bar, no rail, **no stack**, and **no back button** — pressing `INDEX` and choosing another filter is always one press deeper, never one press back."* | E11, D10, D6 | **Blocking — 12 push helpers and every screen's back behaviour** |
| **P4** | The 14px stamp versus the 18pt floor. *(was P2)* | D3, D5 | High — a safety rule is carried at 14px |
| **P5** | Token names — `06` §1 fixes names and lets values change; Indelible ships `--page` / `--ink-full` / `--madder-rule`. *(was P3)* | D2, D5, all design | High |
| **P6** | The palette set — `06` §4 + R35 define three palettes plus a high-contrast switch with stored keys; Indelible defines dark plus red-shift. *(was P4)* | D2, E15 | High |
| **P7** | The typeface — `06` §5 and the golden font loader hard-code one family (`AtkinsonHyperlegibleNext[wght].ttf`); Indelible requires two bundled families and its whole disambiguation rests on the pair. **Newly noted:** Indelible's weights are `390/420/520/600`; Flutter's `FontWeight` is w100–w900 in hundreds, so these need `FontVariation` on a variable axis — and `06` §5.2 records the Atkinson axis as covering **500–700**, which excludes 390 and 420. *(was P5, enlarged)* | D3, E16, E19 | High |
| **P8** | **RE-SCOPED — the status and component vocabulary, not just class names.** `06` §12 and §11 ship `ShedStatusBadge` (*"Icon **and** word, always"*), `ShedPenTile` as a reflowing grid with a *circle-slash badge*, a *filled corner triangle* and a *diagonal hatch fill*, `ShedRecentsStrip` as *"6 chips"*, and `ShedChoiceRow` for **birth type**. Indelible has no icon set, no badge (*"there is a stamp"*), no chips (*"chips are containers with a radius, and this system has neither"*), a pen board of twelve ruled rows, a hard six-mark budget (*"no new mark may be added without deleting one"*), and — the signature of the direction — **no segmented control for birth type, "because there is no choice."** | D4, D5, D6, D7, D9, D10, E11, E16 | **Blocking — this is the "second button style" question, and today the doc set documents the second style** |
| **P9** | **NEW — the tap scale and separation.** `06` §6.1 sets the floor at 60 with `tapMin`/`tapPrimary`/`tapHero`; Indelible sets 64 / 117×84 / 160×140. Compatible on the floor. **Not compatible on separation: 00-README step 19 says ≥ 16 pt; Indelible says 8–12px.** One of the two gates in `test/design/tap_target_test.dart` asserts a number. | D4, E16 | **Blocking — an executable gate asserts one of them** |
| **P10** | **NEW — the haptic vocabulary.** `06` Definition of done: *"The haptic vocabulary has exactly **four** entries and the success haptic fires after the transaction returns."* Indelible §5.4 lists **five** events with distinct rhythms (10 ms tick, two ticks 60 ms apart on commit, two ticks 120 ms apart on strike). Compounded by `HapticFeedback.successNotification()` being carried as **unverified** in 00-README §10. | D1, E4 | Medium |
| **P11** | **NEW — the upgrade row and the export prompt.** `06` §12: `ShedBanner` is *"the only monetization component"*, renders on Flock and Settings, covers both the export prompt and the upgrade row. Indelible has no banner, specifies the export prompt as *"a printed line at the foot of tonight's page"*, and describes no upgrade row on either screen. | D11, E15 | Medium |
| **P12** | **NEW — media has no visual specification.** `ShedPhoto` is the only `ColorFiltered` in the app (`06` §4.7); photos and voice notes ship in v1. Indelible's component inventory contains **no image and no audio element**. | D7, E13 | Medium |
| **P13** | The two grafts in `00-comparison.md` §4.1 — the live row pinned above the band, and the 6px hours bar on pen rows. *(was P7)* | D10, D9 | Medium |
| **P14** | **NEW — the error panel's colour.** `NightErrorPanel` hard-codes `#0B0D0E` and bypasses `Theme`; Indelible's `--page` is `#0A0A0B`. `06`'s DoD says *"no frame is brighter than `#0B0D0E`"*. A one-hex conflict, but it is the **first painted frame** and the no-white-flash claim is measured at 240 fps. | D2, D11, E4 | Low, cheap to close |

---

## 10. The corrected catalogue

**31 skills — 20 engineering, 11 design. 28 auto-triggered, 3 manual-only runbooks.**
Size: **S** ≤ 100 lines · **M** 100–200 · **L** 200–250. Extras: `ref` · `ex` · `scr`.
Descriptions target **350–450 characters**; `skillListingBudgetFraction: 0.02` is set from day one.

### 10.1 Engineering — 20

| # | Skill | Kind | Size | Extras | Owns | Never |
|---|---|---|---|---|---|---|
| E1 | `shed-engineering` | workflow | S | — | **Front door.** The routing table; the add-a-feature pipeline in build order | Any rule of its own. The four non-negotiables move to `CLAUDE.md` |
| E2 | `shed-conventions` | engineering | S | — | The tree; the eight layer rules + two path-pair bans as one table; naming shapes; banned words | The type and provider catalogues — cite `CONVENTIONS` §2/§3 by ruling number |
| E3 | **`shed-dependencies-and-toolchain`** ★new | engineering | M | ref | `pubspec.yaml`, the pinned table, the rejected list, G2/G3, the analyzer block, the `Makefile`, **the gate integrity rules** | The release gates G0/G1/G4/G5 (E19) |
| E4 | `shed-bootstrap-and-errors` | engineering | S | ex | `main()`/`app.dart`, first frame, lifecycle + resume, `session.lock` + clean pause, the error net, `ShedFailure` mapping, `LocalLog` | Write semantics; screen copy after a failure |
| E5 | `shed-riverpod-providers` | engineering | M | ref | Riverpod 2.6.1 exactly, the 3.x ban list, provider shapes, the DI graph, one statement per screen, `select` and rebuild scope, the one ticker, `WriteController.guard`, **warnings are the controller's (R53)** | Repository methods; drift queries; navigation |
| E6 | `shed-write-path` | engineering | M | ex | Event verbs — **`beginLambing`, `addLamb`** first; row on entry; one transaction; `appNow()` once; `WriteOutcome`; the validation-import ban | **Undo** (E11); table definitions (E7) |
| E7 | `shed-drift-schema` | engineering | M | ref | STRICT/FK/index/CHECK, dual keys, time and unit storage, the provenance quad, the tag partial index, no advice-encoding `DEFAULT`, **never a stored time-relative value**, FTS5, the first-run seed, **and `make gen`** | Column *spelling* (E2); the migration step (E18) |
| E8 | `shed-domain` | engineering | M | ref | Pure Dart; the time model and the 01:00–01:59 hour; `RecordedTime`; units; every statistic's edge cases | The `definition` strings — name `lib/domain/stats/definitions.dart` |
| E9 | `shed-withdrawal` | engineering | M | ex | Never defaulted; the sealed type; ceil-to-next-local-midnight; the DST cases | General date arithmetic (E8) |
| E10 | `shed-safety-rules` | engineering | M | — | The five rules **as mechanisms and levels** | What the shepherd sees — the strike, the query mark (D8) |
| E11 | `shed-screens-and-routing` | engineering | M | — | The one query; every state; the tap budget; **undo and delete per verb, sole owner**; the export prompt; `RouteNames`/`Routes`; **the add-a-screen pipeline** | How a screen is drawn (D10) |
| E12 | `shed-accessibility-and-copy` | engineering | M | ref | Semantics, headings, 200% scaling, motor, the Nutrition Labels gate; ARB + gen-l10n; en_GB formats | Contrast (D2); the assertion (E16) |
| E13 | `shed-platform-gateways` | engineering | M | ref | Seven seams; `reconcile()`, channels, exact alarms, reboot/DST; capture, share, import, wakelock; the per-plugin permission policy | Export contents (E14); the release permission gate (E19) |
| E14 | `shed-export-and-restore` | engineering | M | ref ex | CSV/PDF/JSON envelope, the safety footers, media layout + relative paths, orphan sweeps, atomic restore, `tool/seed.dart` | The share-sheet seam (E13); migrations (E18) |
| E15 | `shed-monetization` | engineering | S | — | The one unlock, the entitlement row and its three rules, `PurchaseService`, `FreeTierPolicy`, the four constraints, store declarations | How the upgrade row is drawn (D11); where it renders (E11) |
| E16 | `shed-testing` | engineering | M | ref | Five tiers, fixed time, the drift harness, seven fakes, `pumpApp`, the matrix (**count derived, never typed**), **every executable gate — contrast, tap target, semantics**, tap budgets, policy tests, fixtures, golden *policy*, **the `--update-goldens` prohibition** | Re-baselining (E20) |
| E17 | `shed-code-review` | workflow | S | — | Read by irreversibility; skip what CI proves; the five §12 questions; the Quick Entry question; the never-waved-through list | Being the authority on a rule — it routes |
| E18 | **`shed-migrations`** ↻renamed | **runbook** | S | ref | The hand-written `from<N>To<N+1>` step, `schema steps`, the committed snapshot, the from→to verifier matrix | `make gen` — that is E7 |
| E19 | `shed-release` | **runbook** | M | ref | G0–G5 on a real AAB, the eight-entry permission set, signing, the symbols archive, budgets on two devices, versioning, the closed track, the 1 Feb–30 Apr freeze | — |
| E20 | `shed-goldens-rebaseline` | **runbook** | S | — | Real fonts, tolerant comparator, `make goldens-update`, inspect by eye, its own commit | — |

### 10.2 Design — 11

| # | Skill | Kind | Size | Extras | Owns | Never |
|---|---|---|---|---|---|---|
| D1 | `indelible-design-system` | design | M | — | **Front door.** The four rules; the two-voice law; what the system does not have; **the complete gesture ban**; motion and haptics; the routing table | Any component's specification |
| D2 | `indelible-color-and-contrast` | design | S | scr | Five surfaces, three inks, one hue with three jobs, red-shift, the two placement rules, the token member names, `contrast.py` for **proposed** values | Which non-colour channels carry status (D5); the shipped-ratio assertion (E16) |
| D3 | `indelible-typography` | design | M | — | Two faces, the full scale, dark-mode weights, tracking, tabular figures, the three-digit tag column, no italic, 200% behaviour | The words themselves (E12) |
| D4 | **`indelible-geometry-and-targets`** ↻merged | design | M | — | Spine, margin cell, record column, the ten-step scale, row heights and the row sub-grid, the header band and bottom band, the 64 floor and separation, the three reach bands, the 560px rule, the left-handed mirror, 200% growth | A row's struck or queried state (D8); how a target is painted (D6) |
| D5 | `indelible-marks-and-status` | design | M | — | The 2px rule, the 3px strike weight, doubled and dotted rules, the six marks and their geometry, boxed vs unboxed stamps, the two-non-colour-channel table | The strike workflow (D8); colour values (D2); anything that counts (D9) |
| D6 | `indelible-buttons` | design | S | — | **The two *action* forms** — the corner slab and the word button — plus the pinned index button | Keys, ease groups, steppers, check controls, choosers — all D7 |
| D7 | `indelible-input-and-sheet` | design | M | — | Every control that **captures a value**: the keypad key, the ease group, the stepper, the text field, the check control, the bottom sheet and its three contents, the recents lines, **and the photo and voice-note surfaces** | Controls that perform an action (D6) |
| D8 | `indelible-strike-and-query` | design | M | — | Rule 1 — the strike line and its animation, the struck stamp, permanence in every list and export, the query mark and its two-option chooser, both printed times, the only two honest deletes | The mark geometry (D5); §12.4's *mechanism* (E10); undo semantics (E11) |
| D9 | `indelible-tallies-and-blocks` | design | S | — | The lamb tally and the five-bar gate, the counted birth type, the struck stroke, the day tally, the lambing spread — and the ban on every chart library | Numeric typography (D3); the strike workflow (D8) |
| D10 | `indelible-screen-composition` | design | M | ref | One document under twelve filters **plus note search**; the page header's content; tonight's page; the pen board | What data a screen shows (E11) |
| D11 | **`indelible-states-and-feedback`** ★new | design | M | — | Frame 1, empty, filtered-empty, error; **the save confirmation** (whatever P2 rules); the export prompt line; the upgrade row | Whether a write succeeded (E6); the entitlement rules (E15) |

### 10.3 What moves out of the catalogue entirely

Added to `CLAUDE.md` (catalogue §7.1), because they must be *present*, not *consulted*:

- **The four non-negotiables** — the offline-purity wording verbatim, the 3am question, the five safety
  rules as one-line headlines, "every write commits immediately, no draft state". Currently only in
  `shed-engineering`, which under-fires.
- **The one-word-per-concept table** (C8), alongside the banned-words list already planned.

Added to hooks (catalogue §7.2): the `--update-goldens` block, the `pubspec.yaml`/`pubspec.lock` pairing
check, the `expected_permissions.txt` guard, and the `lint_skills.py` path-existence rule.

---

## 11. Rewritten descriptions for every skill named in §2 and §3

Target 350–450 characters. Third person, what + when + a `Do NOT` naming a real competing skill, no
colon outside the YAML key, no workflow summary.

```yaml
name: shed-engineering
description: >-
  Routes any Shed Book engineering task to the one skill that owns it, and carries the ordered
  pipeline for adding a feature or a screen — schema, domain, write path, wiring, controller, UI,
  tests, gates. Use at the start of multi-layer work, when a task spans more than one folder, and
  whenever it is unclear which skill or which document governs. Do NOT use for visual work, whose
  front door is indelible-design-system, and do NOT restate a rule it routes to.
```

```yaml
name: shed-conventions
description: >-
  The naming and structure authority for Shed Book — the canonical lib tree, the eight layer rules,
  the two path-pair bans, and the banned words draft, save, commit, submit, sync and flags. Cites
  CONVENTIONS.md by ruling number rather than restating a signature. Use before creating any file or
  folder, before naming any file, class, provider, controller, widget key or database column, and
  when deciding whether one folder may import another. Do NOT use for what a column stores, which is
  shed-drift-schema.
```

```yaml
name: shed-dependencies-and-toolchain
description: >-
  The authority on what may enter this app's pubspec and toolchain — every version pinned exactly,
  the forty rejected packages and their approved alternatives, the analyzer strict block, the make
  gen and make check and make test targets, and the offline dependency and import gates. Use before
  pub add, before proposing any package, library, plugin or chart or CSV or routing dependency, when
  editing pubspec.yaml or analysis_options.yaml or the Makefile, and whenever a gate is red. A red
  gate is never turned green by editing the gate or its allowlist. Do NOT use for cutting a release,
  which is shed-release.
```

```yaml
name: shed-drift-schema
description: >-
  How Shed Book stores a fact — STRICT tables, a real foreign key with an explicit ON DELETE and a
  hand-written index for each, CHECK conventions, dual keys, instants as INTEGER UTC millis and civil
  dates as TEXT, the provenance quad, the active-only partial index on tag, no DEFAULT that could
  encode veterinary advice, and never a stored time-relative value. Ends by running make gen and
  landing the regenerated files in the same commit. Use when adding or changing a table, column,
  index, view or named query. Do NOT use for a column's spelling, which is shed-conventions, or for a
  migration step, which is shed-migrations.
```

```yaml
name: shed-write-path
description: >-
  The single write path in Shed Book — repository methods are event verbs, beginLambing and addLamb
  first, the row is created on screen entry rather than exit, appNow is called once per mutation,
  everything runs in one transaction, and there is no save of an aggregate anywhere. Use when adding
  or changing anything that stores a fact — a lambing, a lamb, a strike, a foster, a pen move, a
  treatment, a care check, a note — and whenever a Save button, a draft, a dirty flag, a submit or
  optimistic UI is proposed. Do NOT use for undo, which is shed-screens-and-routing, or for table
  definitions.
```

```yaml
name: shed-screens-and-routing
description: >-
  What a Shed Book screen is made of, how it is reached, and what it costs the shepherd — the one
  drift statement that feeds it, every state including empty and over-cap and not recorded, the tap
  budget, undo and delete semantics per verb and their window, the end-of-day export prompt, and
  Navigator 1.0 with typed push helpers and no go_router. Carries the ordered file list for adding a
  screen. Use when adding, changing or navigating to any screen, or wiring a route or a back
  behaviour. Do NOT use for how a screen is drawn, which is indelible-screen-composition.
```

```yaml
name: shed-safety-rules
description: >-
  Use before adding any default, pre-fill, suggestion, autofill, placeholder, validation, disclaimer
  or automatic correction, and before changing a value the shepherd already stored. Carries the five
  Shed Book safety rules as structural mechanisms rather than reminders, each naming the level that
  holds it from unrepresentable through unconstructible and unpersistable down to a test over the
  source text — a rule that has dropped to merely documented has been deleted. Do NOT use for the
  withdrawal clear-date algorithm, which is shed-withdrawal, or for what a struck row looks like,
  which is indelible-strike-and-query.
```

```yaml
name: shed-testing
description: >-
  How Shed Book is tested and how every gate is asserted — the five tiers, fixed time and the UK
  ambiguous hour, the in-memory drift harness, seven hand-written fakes, pumpApp, the overflow matrix
  whose cell count is derived and never typed, and the executable accessibility, tap-target and
  contrast gates. Use when writing or changing any test, when a test is flaky or time-dependent, when
  a gate assertion fails, and when adding a screen or variant the matrix must cover. Never run
  --update-goldens. Do NOT use to choose a colour or a size, which the Indelible skills own.
```

```yaml
name: shed-monetization
description: >-
  The one non-consumable unlock and everything it touches — the entitlement row and its three rules,
  the purchase service seam, purchase and restore, the free-tier policy with a full season primary
  and the ewe cap secondary, the four hard constraints on the upgrade affordance, and both stores'
  privacy declarations for an app that collects nothing. Use for any line touching price, purchase,
  restore, entitlement, the cap or a store artefact. Do NOT use for how the upgrade row is drawn,
  which is indelible-states-and-feedback, or where it may render, which is shed-screens-and-routing.
```

```yaml
name: shed-code-review
description: >-
  Reviews a Shed Book change the way this project's checklist prescribes, not the way a general code
  review does — read the diff in order of irreversibility, say nothing about anything CI already
  proves, and spend the whole review on the five safety rules asked as questions and the one Quick
  Entry question, which is whether the shepherd now has to do anything new before the record exists.
  Use when reviewing a diff or a pull request, when asked whether something can merge, and before
  claiming work is complete. Do NOT use as the authority on a rule — for that load shed-safety-rules.
```

```yaml
name: indelible-design-system
description: >-
  The front door to Indelible, the one design system Shed Book has — the four rules that settle any
  visual disagreement, the law that serif means it happened and sans means it is a thing you can
  press, the list of what this system does not have including cards, radius, shadows, icons, modals,
  tabs and spinners, the complete gesture ban covering swipe, drag, long-press, pinch and sliders,
  the motion and haptic vocabularies, and a routing table naming the skill that owns each thing. Use
  before drawing or changing any pixel, and whenever a request would add a component, a state, a mark
  or a motion the system does not have. Do NOT use for what data a screen shows.
```

```yaml
name: indelible-color-and-contrast
description: >-
  The entire Indelible palette — five surfaces and no sixth, three ink densities, one hue with three
  jobs, the red-shift variant, the two placement rules that fell out of measurement, and the floors
  of 4.5 to 1 for text and 3 to 1 for rules and marks. Also the token member names a widget may say,
  because a raw colour literal outside the primitives file is a build-breaking defect. Use when
  choosing, proposing or changing any colour, adding a token, or whenever a hex value is about to be
  typed. Do NOT use for which non-colour channels carry a status, which is indelible-marks-and-status,
  or for making a failing contrast assertion pass, which is shed-testing.
```

```yaml
name: indelible-geometry-and-targets
description: >-
  The page geometry of Indelible and everything measured on it — the margin cell that is itself a tap
  target, the continuous madder spine that never breaks and never mirrors, the record column and
  gutters, the ten-step spacing scale with no half steps, the 64px and 88px rows and the row
  sub-grid, the header and bottom bands, the 64 by 64 minimum target and its separation, the three
  reach bands and the rule that nothing above 560px from the bottom is required, and how all of it
  grows at 200 per cent without the grid moving. Use whenever a padding, margin, gap, width, height
  or target size is about to be chosen. Do NOT use for how a target is painted, which is
  indelible-buttons, or for a row's struck state.
```

```yaml
name: indelible-buttons
description: >-
  The two forms in this app that perform an action, and the authority on both — the corner slab, the
  largest target in the product, with its per-page verb and its armed and pressed and disabled states
  and the rule that it never refuses a press, and the word button in its filled, in-stream, selected
  and destructive forms, plus the pinned index button that is the app's only navigation control. Use
  whenever an action, primary action, call to action, destructive action or tappable word is added or
  changed, even when the request never says button, and never introduce a third action form. Do NOT
  use for controls that capture a value — the keypad key, the ease group, the stepper, the check
  control and the choosers are all indelible-input-and-sheet.
```

```yaml
name: indelible-input-and-sheet
description: >-
  Every way the shepherd puts a value into Shed Book, including the ones that look like buttons — the
  keypad key in the record face, the five-button ease group, the number stepper that replaces every
  slider and never repeats on hold, the ruled text field that never renders placeholder text inside
  itself, the check control that stamps the time you pressed it, the photo and voice-note surfaces,
  the recents lines, and the bottom sheet that is the only overlay in the app. Use when adding or
  changing any input, field, form, picker, chooser, keypad, sheet, toggle, checkbox, segmented
  control or capture surface. Do NOT use for buttons that perform an action, which is
  indelible-buttons.
```

```yaml
name: indelible-strike-and-query
description: >-
  Rule 1 of Indelible — nothing is ever removed from this app, only struck. Covers the strike line
  and the one animation in the product with a direction, the struck stamp and its time, struck rows
  staying exactly where they were at full legibility in every list and every export forever, the
  query mark for a record that contradicts itself and its two-option chooser in which the app never
  picks, edited timestamps that print both times, and the only two honest deletes. Use whenever a
  delete, remove, hide, clear, dismiss, archive, mute, correct or edit behaviour is designed. Do NOT
  use for the mark geometry, for undo semantics which are shed-screens-and-routing, or for safety
  rule four's mechanism which is shed-safety-rules.
```

```yaml
name: indelible-states-and-feedback
description: >-
  What an Indelible page shows when there is nothing to show, when something went wrong, or when the
  app has something to say about itself — the first painted frame before data lands, empty and
  filtered-empty, the error panel, the confirmation the shepherd sees after a write, the once-a-day
  export prompt line, and the two static upgrade rows. Use when adding or changing an empty state, a
  loading or first-frame placeholder, an error surface, a confirmation, a receipt, a banner, a prompt
  or the upgrade row, and whenever a spinner, skeleton, toast, snackbar or modal is proposed. Do NOT
  use for whether the write succeeded, which is shed-write-path, or for entitlement rules, which is
  shed-monetization.
```

Remaining descriptions — `shed-bootstrap-and-errors`, `shed-riverpod-providers`, `shed-domain`,
`shed-withdrawal`, `shed-accessibility-and-copy`, `shed-platform-gateways`, `shed-export-and-restore`,
`indelible-typography`, `indelible-marks-and-status`, `indelible-tallies-and-blocks`,
`indelible-screen-composition`, and the three runbooks — keep their existing trigger clauses and
`Do NOT` clauses, and are cut to ~400 characters by deleting the contents inventory in the middle. The
runbook descriptions are already at the right length and need no change beyond the `shed-migrations`
rename.

---

## 12. Order of work

1. **Rule P2, P3, P8 and P9.** They change named types (`SaveReceipt`, `Routes`, `ShedChoiceRow`,
   `ShedStatusBadge`, `tapMin`), an executable gate, and the meaning of "there is exactly one way to
   draw each thing". No design skill and no skill touching undo or routing may be authored first.
2. **Rule P1** before the schema freeze — unchanged, still the only schema-irreversible one.
3. Write `CLAUDE.md` (the four non-negotiables, the pinned versions, the vocabulary, the three
   commands) and the four hooks. Both reduce what the skills have to carry.
4. Set `skillListingBudgetFraction: 0.02` and wire `tool/lint_skills.py` with the path-existence rule.
5. Then the build order in catalogue §6.2, amended: E3 `shed-dependencies-and-toolchain` joins phase 1
   (it governs the first `pubspec.yaml`), and D11 `indelible-states-and-feedback` joins phase 4.
6. Run the acceptance test the catalogue names and did not run: for each of C1–C8 and each pair in the
   corrected audit, three near-miss prompts in a fresh session. Then `/doctor`, and read the Skills row
   in `/context` against §1.1's arithmetic rather than against a feeling.

---

| | |
|---|---|
| **Critique version** | 1.0 — 2026-07-27 |
| **Catalogue reviewed** | `00-catalogue.md` v1.0, 30 skills |
| **Corrected count** | **31 skills** — 20 engineering, 11 design; 28 listed, 3 manual runbooks |
| **Net changes** | +2 skills (`shed-dependencies-and-toolchain`, `indelible-states-and-feedback`) · 1 merge (`targets-and-gestures` → `geometry-and-targets`) · 1 rename (`codegen-and-migrations` → `shed-migrations`) · 8 skills down a size band · 5 scripts, 2 templates and 7 examples cut · 7 blocking conflicts added |
| **Blocking before authoring** | P1, P2, P3, P8, P9 |
