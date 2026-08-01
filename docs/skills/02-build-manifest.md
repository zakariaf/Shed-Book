# 02 — The Shed Book skill build manifest

**Status: BUILD-READY. This file supersedes [`00-catalogue.md`](00-catalogue.md) and closes
[`01-catalogue-critique.md`](01-catalogue-critique.md).** Builders follow it literally. Where it
differs from `00-catalogue.md`, the critique's correction or this file's arithmetic is the reason and
the difference is deliberate.

Nothing here overrides [`../engineering/CONVENTIONS.md`](../engineering/CONVENTIONS.md) (names),
[`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) (decisions, §5 versions) or
[`../design/indelible.md`](../design/indelible.md) (the selected design system).

**Where they live:** `.claude/skills/<name>/SKILL.md`, project scope, committed.

| | |
|---|---|
| **Skills** | **24** — 19 engineering, 5 design |
| **Listed** (auto-triggering, costs listing budget) | **20** |
| **Manual-only** (`disable-model-invocation: true`, costs zero budget) | **4** |
| **Listing total** | **6,357 characters against an 8,000 budget — 20.5% headroom** |
| **Mean SKILL.md length** | ~131 lines (Anthropic's shipped median is 132) |

---

## 1. The budget arithmetic

This is the calculation that killed the first catalogue and it is done here before anything else.

### 1.1 The budget

`skillListingBudgetFraction` defaults to **0.01** — 1% of the model's context window
(research 01, 02 §1.4). The sessions that must be survived are 200k-context ones:

```
200,000 tokens × 0.01 = 2,000 tokens ≈ 8,000 characters
```

**B = 8,000 characters.** The listing holds every listed skill's **name plus description**, and
`disable-model-invocation: true` *"removes the skill from Claude's context entirely"* — so the four
manual skills cost **zero**.

**Required headroom ≥ 20% → ceiling T ≤ 6,400 characters.**

The ceiling is computed against the **default** fraction on purpose. A set that only fits because
`.claude/settings.json` says `0.02` breaks silently in a fresh clone, a cloud session, or any
environment where that file is not honoured. `0.02` is still set (§6.2) — but as a second margin,
never as the thing that makes the arithmetic work.

### 1.2 The sum

Two cost models are computed. Both must clear 6,400.

- **Exact** — measured name length + 10 characters of listing scaffold per row.
- **Conservative** — the critique §1.1's flat 40 characters per skill for name + overhead.

| | Engineering (15 listed) | Design (5 listed) | Total (20) |
|---|---:|---:|---:|
| Description characters | 4,002 | 1,555 | **5,557** |
| Name characters | 295 | 123 | 418 |
| Scaffold @ 10/row | 150 | 50 | 200 |
| **Exact model total** | | | **6,175** |
| **Conservative model total** (5,557 + 20 × 40) | | | **6,357** |

```
Budget                      8,000
Ceiling (20% headroom)      6,400
Actual (conservative)       6,357   ✅ UNDER by 43
Actual (exact)              6,175   ✅ UNDER by 225
Headroom, conservative      (8,000 − 6,357) / 8,000 = 20.54%
Headroom, exact             (8,000 − 6,175) / 8,000 = 22.81%
Headroom at 0.02 (16,000)   60.3%
```

Description lengths: **mean 278, min 238, max 356**, every one inside research 02 §1.4's
200–600 band and far inside the 1,024 hard cap. The original catalogue's mean was 698.

### 1.3 Where the 20,750 characters went

The original overflowed by 2.6×. It is not fixed by trimming adjectives.

| Lever | Saving | Authority |
|---|---:|---|
| **Delete the contents inventory from every description.** The originals were ~70% "here is what I contain", which research 04 rule 4 names outright — *"do not summarise the workflow inside the description"*. Descriptions now carry identity, trigger vocabulary and the negative, nothing else. | ~9,400 | critique §1.1 |
| **Seven merges and one cut** (§2). Every one closes a trigger collision the critique or the original overlap audit already documented. | ~4,300 | critique C1, C2, §4, audit pairs 5/7/8 |
| **`shed-code-review` becomes manual-only.** Zero listing cost; its trigger is an explicit user intent, and it stops losing a name-space contest to Claude Code's bundled `/code-review`. | ~310 | critique §3 |
| **Four non-negotiables, the routing table, the vocabulary and the pinned versions move to `CLAUDE.md`** (§6.1). Content that must be *present* rather than *consulted* is not a description. | ~700 | critique §3, §10.3 |

### 1.4 The rule this locks in

> **A description is identity + triggers + one negative. If a clause describes contents, delete it —
> the body is where contents live, and the body is free.**

Every description below is ≤ 356 characters, contains no colon (a colon in the value is invalid YAML
and Claude Code then loads the skill with **empty metadata**, so `/name` still works and auto-trigger
is silently dead), and ends with a `Do NOT` naming a real sibling skill by name.

---

## 2. What changed from the critique's 31, and why

The critique's structural fixes are all applied. Its **count** is not, because its count was sized
against `skillListingBudgetFraction: 0.02` and this manifest is sized against the default.

**31 → 24 skills · 28 listed → 20 listed.**

| # | Change | Justification |
|---|---|---|
| 1 | `indelible-buttons` + `indelible-input-and-sheet` → **`indelible-controls`** | Critique **C1**. *"There are six pressable forms in Indelible, not two, and the buttons skill's opening sentence is false on its face."* The acts-versus-captures boundary is exactly the kind a model coin-flips on. One authority for every pressable thing removes the collision instead of papering it with reciprocal negatives. |
| 2 | `indelible-marks-and-status` + `indelible-tallies-and-blocks` + `indelible-strike-and-query` → **`indelible-marks-and-strikes`** | Overlap-audit pair 5 is *"the highest-risk pair in the catalogue"* and pair 7 is a pointer (*"marks points at tallies for anything that counts"*). Both are seams that drift. The tally stroke and the strike line are marks **4 and 5 of the same six** in `indelible.md` §6.2 — they were never three bodies of knowledge. Rule 1's reciprocity with `shed-safety-rules` (critique **C6**) survives intact on the merged description. |
| 3 | `indelible-geometry-and-targets` + `indelible-screen-composition` → **`indelible-page-and-screens`** | Critique **C2** — *"add a screen" loaded six skills*. Overlap-audit pair 8 split "one row" from "the whole page", which contradicts the system's own central claim that **every screen is the same page under a filter**. Post-merge, "add a screen" resolves to exactly two skills, satisfying C2's own proposed rule. |
| 4 | `indelible-color-and-contrast` and `indelible-typography` fold into **`indelible-design-system`** | The palette is a closed list of eleven tokens and two placement rules; Indelible **Rule 4 *is* the contrast floor**, and Rule 2 *is* the two-voice typography law. Separating a rule from its numbers is what produces drift. The front door is the highest-traffic design skill and is the last thing truncation would ever reach, so the measured floors and the corrected 18px floor live where they are always in context. |
| 5 | **`shed-engineering` is cut.** | The critique's own §3 finding — *"a use-always description with no distinctive vocabulary … it loses every contest with a specific skill"* and *"when it does not fire the non-negotiables are absent"*. Once the four non-negotiables move to `CLAUDE.md`, what is left is a routing table (which must be *present*, so it goes to `CLAUDE.md` too) and a cross-layer pipeline that is 00-README §8 restated — forbidden by the critique's §7 house rule. `shed-screens-and-routing` already owns the add-a-screen ordered file list per C2. |
| 6 | **`shed-code-review` → manual-only** (`disable-model-invocation: true`) | Critique §3 notes it *"collides in name-space with Claude Code's bundled `/code-review`, which the model may prefer"*. Manual-only removes the contest and the listing cost. `CLAUDE.md` carries the one line *"before claiming work is complete, run `/shed-code-review`"*, so the instruction is present even though the body is not. |
| 7 | `shed-codegen-and-migrations` → **`shed-migrations`**, `make gen` moves into `shed-drift-schema` | Critique **R1** — unchanged, applied verbatim. |
| 8 | **`shed-dependencies-and-toolchain`** added | Critique **G1** — *"the largest hole"*. Nothing fired on `pub add`. |
| 9 | **`indelible-states-and-feedback`** added | Critique **G2–G6** — the save receipt, the upgrade row, empty/error states, media UI and note search had no design owner. |

**Everything the critique cut stays cut:** the five design scanning scripts (`indelible_audit.sh`,
`check_type.sh`, `check_gestures.sh`, `check_no_placeholder.sh`, `check_no_erasure.sh` — decisions
#9/#10 give this project **one** gate), the `templates/` directory convention (the six survivors are
`examples/`), the seven design examples that duplicate real `lib/` files, `tpl arb_entry`,
`tpl screen_scaffold`, and every `references/` that transcribes a doc-set section.

**Extras across the whole set: 1 script · 6 examples · 9 references.**

---

## 3. The full table

Size: **S** ≤ 100 lines · **M** 100–200. Extras: `ref` = `references/` · `ex` = `examples/` ·
`scr` = `scripts/`. **Chars** is the frontmatter `description` length.

### 3.1 Engineering — 19 (15 listed, 4 manual)

| # | Skill | Kind | Lines | Extras | Chars |
|---|---|---|---:|---|---:|
| E1 | `shed-conventions` | engineering | 90 | — | 262 |
| E2 | `shed-dependencies-and-toolchain` | engineering | 150 | ref | 272 |
| E3 | `shed-bootstrap-and-errors` | engineering | 110 | ex | 259 |
| E4 | `shed-riverpod-providers` | engineering | 170 | ref | 301 |
| E5 | `shed-write-path` | engineering | 130 | ex | 261 |
| E6 | `shed-drift-schema` | engineering | 175 | ref | 272 |
| E7 | `shed-domain` | engineering | 150 | ref | 238 |
| E8 | `shed-withdrawal` | engineering | 110 | ex ×2 | 263 |
| E9 | `shed-safety-rules` | engineering | 120 | — | 268 |
| E10 | `shed-screens-and-routing` | engineering | 180 | — | 262 |
| E11 | `shed-accessibility-and-copy` | engineering | 140 | ref | 250 |
| E12 | `shed-platform-gateways` | engineering | 165 | ref | 288 |
| E13 | `shed-export-and-restore` | engineering | 170 | ref ex | 260 |
| E14 | `shed-monetization` | engineering | 90 | — | 274 |
| E15 | `shed-testing` | engineering | 180 | ref | 272 |
| E16 | `shed-migrations` | **runbook** | 70 | ex | *manual* |
| E17 | `shed-release` | **runbook** | 150 | ref | *manual* |
| E18 | `shed-goldens-rebaseline` | **runbook** | 50 | — | *manual* |
| E19 | `shed-code-review` | **workflow, manual** | 90 | — | *manual* |

### 3.2 Design — 5, all listed, all from `indelible.md`

| # | Skill | Kind | Lines | Extras | Chars |
|---|---|---|---:|---|---:|
| D1 | `indelible-design-system` | design | 195 | scr | 352 |
| D2 | `indelible-page-and-screens` | design | 180 | — | 312 |
| D3 | `indelible-controls` | design | 175 | — | 303 |
| D4 | `indelible-marks-and-strikes` | design | 180 | — | 296 |
| D5 | `indelible-states-and-feedback` | design | 150 | — | 292 |

### 3.3 House frontmatter rules

| Rule | Reason |
|---|---|
| `name` + `description` only; the four runbooks add `disable-model-invocation: true`. | The two spec-required fields. Anthropic's `quick_validate.py` **rejects** unknown keys (research 04 rule 17). No `version`, no `tools`, no `display-name`, no `when_to_use`. |
| `name` equals the directory name. | Spec requirement; the command comes from the directory. |
| **No `paths:` on any skill.** | `paths` limits activation to files already in play. Every skill here must fire **before** the file exists. |
| **No colon anywhere in a description.** | Invalid YAML → the skill loads with empty metadata, `/name` still works, and auto-trigger is silently dead forever (research 03 §10.1). Use em-dashes and parentheses. |
| Every description ends with `Do NOT use for … (<real sibling skill name>)`. | Research 02 §1.2, §1.5. Four of Anthropic's five document skills carry a negative trigger; it is how overlap is stopped. |
| Bodies front-load. | Only the **first 5,000 tokens** of a skill survive auto-compaction (research 02 §2.4). Non-negotiables go at the top. |
| Every `references/` link carries a **load condition**, not a "see also". | *"Read X **if** Y"* is the pattern; `"see references/"` is the documented anti-pattern. |
| **No skill restates a name, a signature, a column spelling, a stored key, a version number or a verbatim user-facing string.** It states the rule, cites the owning document and ruling number, and names the file where the value lives. | Critique §7. A skill that goes stale when a doc changes is written wrong. `tool/lint_skills.py` asserts every repo path named in a body exists. |

---

## 4. Owner rulings encoded in this manifest

These are settled. Any skill that contradicts one is wrong.

### 4.1 P2 — there is no SnackBar, and the receipt is the committed row

`CONVENTIONS §2.11` made `feedback.dart` *"the one file permitted to call `showSnackBar(`"*;
`07 §15` defined the undo window as *"until the SnackBar is dismissed"*; Indelible §9 bans snackbars
outright — which made undo unimplementable as specified. **Indelible wins.**

- **The confirmation is that the row is there, in ink, one line above the one being written.** No
  floating overlay. `feedback.dart` becomes the printed-receipt channel.
- **`showSnackBar(` is banned everywhere, including in `feedback.dart`.** It becomes a
  `check_policy` row with no allowlist entry.
- **Undo becomes a time-boxed strike affordance in the row's own margin** — Indelible-native, because
  you strike, you never erase. **The window is stated in seconds, never in terms of a widget's
  lifetime.**

Owners: `indelible-states-and-feedback` (what the shepherd sees) · `shed-screens-and-routing` (the
per-verb window and semantics) · `indelible-marks-and-strikes` (the strike itself).

### 4.2 P8 — birth type has no segmented control

`06 §12` documents `ShedChoiceRow` for birth type; Indelible §7.9 says *"there is no segmented
control, because there is no choice."* **Indelible wins.**

- **Birth type is derived from the tally strokes and labelled as derived.** That is what makes safety
  rule §12.4 structural rather than procedural.
- **`ShedChoiceRow` survives only where a genuine choice exists with no derivable answer — lambing
  ease 1–5 is the case that keeps it.**
- Any skill implying a birth-type selector is wrong. `indelible-controls` states this in its body
  next to the ease group, where the mistake would be made.

### 4.3 Design system of record — Indelible only

`the-register.md` and `strip-bay.md` were **not** selected. No element of either may appear in any
skill; the point of one design system is that the alternatives are unreachable.

**The single exception, recorded in `../design/00-comparison.md` §4.1: the *persistent loaded
subject*** — the animal being written about is the largest object on the phone and survives a cold
launch. **That idea is Indelible's now. Do not attribute it and do not import anything else with it**
— in particular the 6px hours bar is *not* adopted.

### 4.4 Two known defects in the Indelible artefacts

Skills encode the **corrected** rule and name the artefact as wrong.

| # | Defect | The rule a skill states | Owner |
|---|---|---|---|
| 1 | `indelible.html:1138` puts the live row inside the scrolling `.stream`, so the open row can scroll off screen — losing track of whose row is open. | **The live row is a fixed layer above the bottom band and cannot scroll away.** The band is already `position: absolute`; the live row becomes a second fixed layer above it. | `indelible-page-and-screens` |
| 2 | `--t-stamp: 14px` (49 uses) and `--t-head: 16px` (13 uses) sit under the 18px floor. §3.4's exemption test requires that *"no stamp is ever the sole carrier of its meaning"* — and it fails on **`DEAD`**, on **`AUTO-CAPTURED`** (the sole §12.5 provenance label) and on **`DERIVED FROM 3 STROKES`** (the sole statement of the §12.4 claim). | **Those three are not exempt stamps and must meet the 18px floor.** Every other stamp keeps the exemption. | `indelible-design-system` (the scale and the corrected exemption test) · `indelible-marks-and-strikes` (`DERIVED`, `DEAD`) · `indelible-states-and-feedback` (`AUTO-CAPTURED`) |

### 4.5 The remaining blocking conflicts, and who resolves them

**P1 is ruled.** `struck` / `struck_at` landed on 2026-08-01 as `CONVENTIONS` **R79**, in N00-T05,
seven epics before the schema freeze: a second mixin, `Struckable`, over **twelve** record-bearing
tables rather than the pair on `mixin Identified` and sixteen. Four `Identified` tables are named as
deliberately not struckable with a reason each — `Treatments` (it has `voided_at`, #69),
`TreatmentWithdrawals`, `VocabTerms` and `MediaAssets`. The default for every reader is stated once:
**struck rows are excluded from every count and included in every history and every export.** Both
skills it gated — `shed-drift-schema` and `shed-export-and-restore` — carry the ruled rule in their
bodies. It is recorded here in the same shape §4.1 and §4.2 use for P2 and P8. P3 (navigation model), P7
(typeface and the `FontVariation` weight axis), P9 (tap separation, 16pt vs 8–12px — an executable
gate asserts one of them), P10 (four haptics vs five) and P14 (`#0B0D0E` vs `#0A0A0B`) are recorded in
the owning skill's body as **open, with the conflict named and both sides cited** — never silently
resolved on a skill's own authority.

---

## 5. Per-skill build brief

Each brief gives the exact `description`, the exact sources to distil from, what the skill owns, what
it explicitly does not own, and the extras with their load conditions.

---

### E1 · `shed-conventions` — engineering · S, 90 lines · no extras

```yaml
name: shed-conventions
description: >-
  The naming and layering authority — the tree, the eight layer rules, the banned words. Use before
  naming any file, class, provider, key or column, and before deciding whether one folder may import
  another. Do NOT use for what a column stores (shed-drift-schema).
```

**Sources.** `CONVENTIONS.md` §1 (the tree), §1.1 (the eight layer rules as amended, plus the
`layer.data_no_validation` and `layer.sibling` path-pair bans), §4.1 (files), §4.2 (classes and
types, banned suffixes), §4.3 (providers and the five documented exceptions), §4.4 (controllers),
§4.5 (widget keys), §4.6 (database names), §4.7 (policy rule ids); `01-architecture.md` §2.2, §3.1,
§3.2.

**Owns.** The `mkdir` tree · the eight layer rules and two path-pair bans **as one table** · the
naming *shapes* for file, class, repository, gateway, screen, controller, provider, widget key and
column · policy rule id format · the banned-suffix list.
**Does not own.** `CONVENTIONS §2`'s type catalogue or `§3`'s provider catalogue — it cites them by
ruling number and never re-types a signature. Not what a column *stores*. Not copy or the
one-word-per-concept vocabulary, which is in `CLAUDE.md` (critique **C8**).

---

### E2 · `shed-dependencies-and-toolchain` — engineering · M, 150 lines · `references/gate-failures.md`

```yaml
name: shed-dependencies-and-toolchain
description: >-
  The authority on what may enter this app's pubspec and toolchain. Use before pub add, before
  proposing any package, plugin or library, when editing pubspec.yaml, analysis_options.yaml or the
  Makefile, and whenever a gate is red. Do NOT use to cut a release (shed-release).
```

**Sources.** `../research/00-tech-decisions.md` §5.1 (runtime), §5.2 (dev), §5.3 (the ~40 rejected
with reason and alternative), §3.2 (gates G0–G5), §3.4 (the honest exceptions);
`13-build-ci-release.md` §1 (what is pinned and how), §2 (the offline gates), §5 (lints and the
strict analyzer block); `00-README.md` §3.1–§3.4, §4 (decision #5 — commit `pubspec.lock` first),
§7.1; `CONVENTIONS.md` §4.7, R55, R56.

**Owns.** `pubspec.yaml`, `analysis_options.yaml`, the `Makefile` targets · exact pins and the
`build_runner` range that does **not** resolve at `^2.15.2` · `package:test` is never a direct
dependency · `flutter_timezone` is unaudited and banned from any pubspec · G2 (allowlist over
`pubspec.lock`) and G3 (import scan) · the anti-pattern that a *"no `http` in `pubspec.lock`"* rule is
**unsatisfiable** · **the gate-integrity rule**, stated verbatim as research 04 §5 layer 5 prescribes —
*never edit `tool/check_policy.dart`, its rule table or its exit code to make a build pass; never add
a line to `tool/policy_allowlist.txt` or `android/expected_permissions.txt` to silence a gate; if a
gate is genuinely wrong, say so and stop. User instructions outrank this skill; your own convenience
does not.*
**Does not own.** The release gates G0/G1/G4/G5 against a real AAB, signing, budgets — `shed-release`.
Codegen — `shed-drift-schema`.

**Extra.** `references/gate-failures.md` — what each `check_policy` rule id and each of G1–G5 means
when it fires, and the forbidden fix for each. **Load when a gate is red.** It carries no copy of
decision-record §5.3; the skill cites §5.3 and names only the packages an agent actually proposes
(`fl_chart`, `csv`, `go_router`, `freezed`, `get_it`, `permission_handler`, `printing`, `http`).

---

### E3 · `shed-bootstrap-and-errors` — engineering · S, 110 lines · `examples/main.dart`

```yaml
name: shed-bootstrap-and-errors
description: >-
  How Shed Book starts, resumes and fails. Use when editing main.dart or app.dart, mapping an
  exception to ShedFailure, wiring the local log, handling lifecycle or resume, or chasing a white
  flash or slow start. Do NOT use for write semantics (shed-write-path).
```

**Sources.** `01-architecture.md` §5.1–§5.6 (the failure set, `WriteOutcome`, `ShedFailure`, returned
vs thrown, the global error net), §6.1–§6.3 (`main()`, line by line, what happens after the first
frame); `02-state-di-navigation.md` §9.1–§9.3 (the 3am resume reality, what the app owes on resume,
what is honestly lost); `13-build-ci-release.md` §7 (the clean-pause mechanism), §8 (diagnostics
without a network); `06-design-system.md` §9 (no white flash, four layers); `CONVENTIONS.md` §2.5,
§2.14 (`ResumePolicy`, `LocalLog`, `ShedBookApp`), R11, R34, R52.

**Owns.** `main()` awaits nothing and the install order · `app.dart` and `ShedBookApp` as a
`ConsumerStatefulWidget` · the first painted frame · the global error net ·
`shedFailureFrom(Object)` and where `UnexpectedFailure` may be constructed · `LocalLog.instance`,
redaction, `markCleanPause()` · app lifecycle, resume, `ResumePolicy.staleAfter`, the `session.lock`
clean pause, and a dirty resume — **which `13 §7` previously had no owner for at all** (critique G7).
**Does not own.** Repository write semantics. The wording or pixels of the error panel —
`indelible-states-and-feedback`. Provider shapes — `shed-riverpod-providers`.

**Extra.** `examples/main.dart` — the complete ~20-line `main()` with the install order and a comment
on every line that may **not** be awaited. **Load before editing startup.** It resolves an ordering
judgement prose cannot.

---

### E4 · `shed-riverpod-providers` — engineering · M, 170 lines · `references/riverpod3-symptoms.md`

```yaml
name: shed-riverpod-providers
description: >-
  flutter_riverpod 2.6.1 pinned exactly, every Riverpod 3 API banned. Use for any provider, notifier,
  controller, ref.watch, ref.read, AsyncValue, autoDispose, family, select, rebuild scope or jank,
  and whenever copying Riverpod published after 2025. Do NOT use for repository methods
  (shed-write-path).
```

**Sources.** `02-state-di-navigation.md` §1 (why 2.6.1 exactly), §2.1–§2.4 (the Riverpod-3 ban list
and its CI rules), §3 (the 2.6.1 spelling card), §4.1–§4.6 (shapes, auto-dispose policy,
watch/read/listen, `.select`, reading an `AsyncValue`, where providers are declared), §5.1–§5.4 (the
DI graph, no production overrides, the clock is not a provider), §6 (controller conventions), §7 +
§7.1 (the double-tap-safe `WriteController`), §10.1–§10.3 (keeping Quick Entry cheap);
`01-architecture.md` §7.1–§7.5 (**never store a time-relative value**); `07-screens.md` §1.2 (one
query per screen, the SQL fan-in ban); `CONVENTIONS.md` §3.1–§3.5, R25 (the one ticker), R28, R29,
R53.

**Owns.** The 2.6.1 pin and every banned 3.x API · provider shapes and disposal · the DI graph rooted
at `databaseProvider` · **one drift statement per screen; `combineLatest` over drift streams is a
build-breaking defect** · `.select` and rebuild scope · the single `minuteTickProvider` and the one
legitimate `ref.invalidate` · `WriteController.guard()` · **`WriteCommitted.warnings` is populated by
the controller, never by a repository (R53)** — stated **here only**; `shed-write-path` points at it
rather than repeating it (critique §7).
**Does not own.** Repository methods, drift queries, navigation, `main()`.

**Extra.** `references/riverpod3-symptoms.md` — a **symptom → fix** index: the compile error or silent
behaviour an agent will actually hit, mapped to the 2.6.1 spelling, citing `02 §3` as the canonical
card. **Load when a Riverpod snippet does not compile or was copied from anywhere.** It is a
diagnostic index, not a transcription of the card.

---

### E5 · `shed-write-path` — engineering · M, 130 lines · `examples/foster_verb.dart`

```yaml
name: shed-write-path
description: >-
  The single write path — event verbs, the row commits on screen entry not exit, one transaction, no
  aggregate save. Use when storing any fact, and whenever a Save button, draft, dirty flag or
  optimistic UI appears. Do NOT use for undo (shed-screens-and-routing).
```

**Sources.** `01-architecture.md` §4.1 (repositories), §4.2 (**event verbs, never `save(aggregate)`**),
§4.3 (one `db.transaction` per mutation), §4.4 (persist before republish), §4.5 (there is no Save
button), §5.2 (`WriteOutcome`); `CONVENTIONS.md` §2.4, §2.13 (the twelve repositories and the
canonical verb signatures), R32 (`beginLambing` and `addLamb` return an id and **throw** — the only
two), R53; `00-README.md` §2.4, §8 step 3.

**Owns.** Event verbs, with **`beginLambing` and `addLamb` named first** — they are the product, and
the critique's **C3** found them missing from the original trigger list · the row is created on
**screen entry, not exit** · `appNow()` called once per mutation · `RecordedTime.capture(now)` ·
`newUid()` · one transaction · `WriteOutcome` and its three variants · **`lib/data/` may not import
`lib/domain/validation/`**, which is a §12.4 structural mechanism.
**Does not own.** Undo and delete semantics — `shed-screens-and-routing` (critique **C4** makes it
sole owner). Table definitions — `shed-drift-schema`. Warning population — `shed-riverpod-providers`.

**Extra.** `examples/foster_verb.dart` — one complete event verb showing the full transaction shape.
**Load before writing a new repository verb.**

---

### E6 · `shed-drift-schema` — engineering · M, 175 lines · `references/storage-decisions.md`

```yaml
name: shed-drift-schema
description: >-
  How a fact is stored — tables, keys, indexes, CHECKs, time and unit encoding, the provenance quad.
  Ends by running make gen. Use for any table, column, index, view or named query. Do NOT use for a
  column's spelling (shed-conventions) or a migration step (shed-migrations).
```

**Sources.** `03-data-model-and-schema.md` §1.2 (`build.yaml`), §1.3 (connection and pragmas), §1.5
(anti-patterns), §2 + §2.1 (conventions every table obeys, `mixin Identified`), §3 (dual-key ids),
§4.1–§4.3 (time and unit storage and the two schema-level guards), §5.1–§5.14 (the tables), §6 (tag
uniqueness — **active animals only**, a partial unique index), §7 (fostering), §8 (pen occupancy),
§9.1–§9.2 (the two search problems, FTS5 over one fan-in table), §10 (first run);
`04-migrations-media-backup-restore.md` §2.4 (the ritual — **the `make gen` half only**), §3.6 (the CI
no-diff check); `01-architecture.md` §7.2 (**time-relative values are never stored**);
`CONVENTIONS.md` §2.8, §4.6, R13, R21, R22, R37, R38, R62.

**Owns.** `STRICT` · a real FK with an explicit `ON DELETE` and a hand-written index for each ·
`CHECK` conventions · the dual-key id strategy · instants as `INTEGER` UTC millis and civil dates as
`TEXT` (decision #2, **irreversible after the first snapshot**) · the §12.5 provenance quad · the
active-only partial unique index on `tag` · FTS5, `search.drift` and the two search problems ·
`seedFirstRun` and the `onCreate` season insert · **no `DEFAULT` on any column that could encode
veterinary advice** · **never a stored time-relative value** · **and `make gen`, ending with the
regenerated files landing in the same commit** (critique **R1**).
**Does not own.** A column's *spelling* — `shed-conventions` cites `R37`/`R38` (`occurred_at`,
`captured_at`, `original_effective` — never `original_effective_at`); this skill cites the ruling
numbers and never re-types a spelling. The hand-written `from<N>To<N+1>` step — `shed-migrations`.

**Extra.** `references/storage-decisions.md` — how a new value is stored (instant vs civil date vs
unit vs derived), and the four things irreversible after the first snapshot. **Load when deciding how
to store a value that has no precedent in the schema.**

**P1 is ruled and this skill carries it.** `CONVENTIONS` **R79**, 2026-08-01: a second mixin,
`Struckable`, over **twelve** record-bearing tables — not the pair on `mixin Identified` and sixteen.
Four `Identified` tables are named as deliberately not struckable with a reason each. The skill's
body states the mixin, the twelve tables, the four exclusions, the paired CHECKs, the count-versus-
history default and the `AND struck = 0` in the active-tag index predicate.

---

### E7 · `shed-domain` — engineering · M, 150 lines · `references/statistics.md`

```yaml
name: shed-domain
description: >-
  The pure-Dart domain — no Flutter, drift, Riverpod, intl or clock, and now is always a parameter.
  Use for any calculation, conversion, average, percentage, count, statistic or date arithmetic. Do
  NOT use for clear dates (shed-withdrawal).
```

**Sources.** `05-domain-correctness.md` §1 (where the domain lives and what it may not touch), §2
(the time model and the **01:00–01:59** UK ambiguous hour), §4 (`RecordedTime` — provenance is part
of the value), §5 (units), §6 (the statistics and every edge case), §8 (terminology);
`CONVENTIONS.md` §2.1 (ids), §2.2 (time), §2.3 (units), §2.6 (warnings and statistics), §2.9,
R17, R23, R24 (**`package:clock` is banned in `lib/domain/`**), R61; `00-README.md` §5.1 (UK/Ireland,
`en_GB`, kg, °C, 24h, `dd/MM/yyyy`, Monday, AHDB percentage convention).

**Owns.** Pure Dart and the import ban · `now` is a parameter, never a read · `Instant`,
`LocalDate`, `PartialDate`, `Grams`, `MilliCelsius` and `parseUserNumber` · `RecordedTime` and
`TimeSource` · canonicalisation and rounding · every statistic's edge cases and `notComputableReason`
· `Warning` has no `fix()` and there is no `warnings` column.
**Does not own.** Withdrawal clear dates — `shed-withdrawal`. **The statistic `definition` strings**:
per `R61` they are printed into CSVs and PDFs that outlive the app, so the skill names
`lib/domain/stats/definitions.dart` as the **only** source and copies none of them.

**Extra.** `references/statistics.md` — per-statistic edge cases, denominators and not-computable
reasons, with a standing instruction that the `definition` string is read from
`lib/domain/stats/definitions.dart` and never quoted. **Load when adding or changing a statistic.**

---

### E8 · `shed-withdrawal` — engineering · M, 110 lines · `examples/clear_date.dart`, `examples/clear_date_dst_test.dart`

```yaml
name: shed-withdrawal
description: >-
  Withdrawal periods and clear dates — never defaulted, suggested, pre-filled or copied by
  repeat-last-treatment. Use for medicines, doses, treatments, batch numbers, withdrawal days, clear
  dates and countdowns. Do NOT use for general date arithmetic (shed-domain).
```

**Sources.** `05-domain-correctness.md` §3 (the whole section — the highest-stakes code in the app),
§7 (rule §12.1 as a mechanism); `../research/00-tech-decisions.md` §1 decision 3 (**ceil to the next
local midnight of administration + N × 24 h, in absolute time, stored once at write time; civil-day
arithmetic yields 167 h across UK spring-forward**); `CONVENTIONS.md` §2.7 (`sealed WithdrawalPeriod`,
the private generative constructor, `WithdrawalDays.asEnteredByUser`, `WithdrawalStatus`,
`clearDateFor`); `07-screens.md` §10 (Treatments — where it renders); `03` §5.8 (the child table where
**no row implies `NotRecorded`**).

**Owns.** Never defaulted, suggested, pre-filled or copied · the sealed type and its one entry point ·
absent row means *not recorded*, never zero · the ceil-to-next-local-midnight algorithm and the DST
cases · `REPEAT LAST TREATMENT` copies product, dose, route and batch and **explicitly leaves the days
blank**, printing `DAYS NOT COPIED — READ THE BOTTLE`.
**Does not own.** General date arithmetic — `shed-domain`. How the treatment screen is drawn —
`indelible-controls` (the field) and `indelible-marks-and-strikes` (the day tally).

**Extras.** `examples/clear_date.dart` and `examples/clear_date_dst_test.dart` — the algorithm and the
five DST cases including the ambiguous hour. **Load before touching clear-date arithmetic or writing
a `uk-zone` test.**

---

### E9 · `shed-safety-rules` — engineering · M, 120 lines · single file

```yaml
name: shed-safety-rules
description: >-
  The five safety rules as structural mechanisms, not reminders. Use before adding any default,
  pre-fill, suggestion, autofill, placeholder, validation, disclaimer or automatic correction, and
  before changing a stored value. Do NOT use for clear dates (shed-withdrawal).
```

**Sources.** `05-domain-correctness.md` §7 (all five as structural mechanisms);
`CODE-REVIEW-CHECKLIST.md` §2 (the five as review questions); `CONVENTIONS.md` §2.6 (`Warning`,
`Reviewed<T>` — no writer, no `fix()`), §2.14 (`Disclaimers` as `abstract final class` of `const`
strings, referenced and never re-typed; `ContentPolicy`), §1.1 rule `layer.data_no_validation`;
`00-README.md` §2.3.

**Owns.** The five rules **as mechanisms and their level** in the hierarchy — unrepresentable →
unconstructible → unpersistable → a test over the source text → documented — and the standing rule
that **a rule which has dropped to merely documented has been deleted, whatever the prose says**. The
origination line for §12.2 (*the app may arithmetic-transform a number the user supplied; it may never
originate a number that is a clinical decision*). `ExportEnvelope` has no disclaimer parameter. **A
table without the provenance quad has no edit verb.**
**Does not own.** The clear-date algorithm — `shed-withdrawal`. What the shepherd *sees* when a record
is struck or queried — `indelible-marks-and-strikes`, which states in its body that §12.4's
*mechanism* is this skill's and must not be restated (critique **C6**). Copy and ARB —
`shed-accessibility-and-copy`; the banned-words list is in `CLAUDE.md`.

The description leads with the triggers, per critique §3 — the original buried them behind 60% of
mechanism prose.

---

### E10 · `shed-screens-and-routing` — engineering · M, 180 lines · single file

```yaml
name: shed-screens-and-routing
description: >-
  What a screen is made of, how it is reached, and what it costs in taps — including undo and delete
  per verb and the ordered file list for a new screen. Use when adding, changing or routing to a
  screen. Do NOT use for how it is drawn (indelible-page-and-screens).
```

**Sources.** `07-screens.md` §1 (how to read a brief — the one query, the states, the tap budget),
§2 (first run), §3–§14 (the twelve briefs — **cited per screen, never copied**), **§15 (undo and
delete semantics, per verb — the table, the process-death rule, "Cancel is not a verb")**, §16 (the
end-of-day export prompt), §17 (the reminder reconciliation rule), §18 (search), §19 (free-tier cap
surfaces), §20 (cross-screen rules), §21 (what CI proves about screens);
`02-state-di-navigation.md` §8.1–§8.4 (the route helper, the stack, Android back, anti-patterns);
`CONVENTIONS.md` §2.14 (`RouteNames` 13, `Routes` 12 push helpers, `Routes.navigatorKey`), §4.5
(widget keys); `00-README.md` §8 steps 4–7.

**Owns.** The one drift statement that feeds a screen · every state including empty, over-cap and
not-recorded · the tap budget · **undo and delete semantics per verb — sole owner** (critique **C4**),
with the window **stated in seconds** and never as "until a widget is dismissed" (§4.1) · the export
prompt's timing and once-a-day rule · `RouteNames` / `Routes` / Navigator 1.0 / no `go_router` / no
named-route strings / no state restoration · **the ordered add-a-screen pipeline**, nine files in
build order — route entry + push helper → controller → write controller → screen → ARB strings →
widget test → matrix variant + 1 → empty-state row → §12 disclosure row — **ending by naming
`indelible-page-and-screens` as the next skill to load** (critique **C2**: at most two auto-firing
skills per intent).
**Does not own.** How a screen is drawn. The twelve briefs' prose — it cites `07 §3`–`§14` by screen.

**Carries P3 as an open conflict**, named and both sides cited: `02` ships a `Navigator` stack, 12
typed push helpers, a back behaviour and a 2-minute resume reset; Indelible §7.17 says *"there is no
tab bar, no rail, no stack, and no back button."*

---

### E11 · `shed-accessibility-and-copy` — engineering · M, 140 lines · `references/semantics-recipes.md`

```yaml
name: shed-accessibility-and-copy
description: >-
  What a widget says rather than shows — semantics, headings, text scaling, and every string through
  ARB in en_GB formats. Use when adding or changing any label, string, heading, date or number
  format. Do NOT use for contrast (indelible-design-system).
```

**Sources.** `10-accessibility-and-i18n.md` §2 (the platform flag truth table), §3 (semantics), §4
(text scaling), §5 (colour is never the only channel), §6 (motor accessibility), §7 (**Apple's
Accessibility Nutrition Labels as the ship gate**), §8 (the gen-l10n / ARB setup and the
terminology-placeholder rule), §9 (en_GB dates, numbers and units), §10 (the gate rows this document
adds); `CONVENTIONS.md` §5.4 (copy conventions), R60 (**no human-facing date is all-numeric**), R66,
R67, R68; `07-screens.md` §1.4.

**Owns.** Semantic labels, heading levels, live regions · 200% text scaling behaviour · motor
accessibility · the ship gate · every user-facing string in `app_en.arb` with a `description`, and
every domain noun as a placeholder fed by `terminologyProvider` · en_GB date, number and unit formats
· `d MMM y` for human-facing dates, `HH:mm` 24-hour, and **every displayed event time carries its
provenance label**.
**Does not own.** Contrast ratios or letterforms — `indelible-design-system`. **The assertion** —
`shed-testing` owns the executable semantics gate (critique **C7**: *the design skills own the value,
`shed-testing` owns the assertion*). The one-word-per-concept table and banned words — `CLAUDE.md`.

**Extra.** `references/semantics-recipes.md` — the pen board, keypad, tally and chart semantics trees.
**Load when adding a custom-painted or composite widget.**

---

### E12 · `shed-platform-gateways` — engineering · M, 165 lines · `references/notifications.md`

```yaml
name: shed-platform-gateways
description: >-
  The seven platform seams, their fakes and the eight-entry permission set. Use when adding a plugin,
  editing AndroidManifest.xml or Info.plist, scheduling a reminder, capturing media, sharing a file
  or asking for a permission. Do NOT use for an export's contents (shed-export-and-restore).
```

**Sources.** `08-platform-integration.md` §1 (the service boundary), §2 (notifications —
`reconcile()`, channels, exact alarms, reboot and DST, the windowed projection), §3 (photo capture),
§4 (audio — the voice note), §5 (the share sheet), §6 (file import), §7 (wakelock), §8 (the
permission policy), §10 (**the record that tag OCR and voice tag entry are v2, with the reason**);
`13-build-ci-release.md` §3 (the complete eight-entry permission set); `CONVENTIONS.md` §2.12,
R9, R47, R48 (`package:timezone` lives only in `notification_scheduler.dart`), R49, R50, R51
(**`reconcile()`, and `schedule` is banned on a reminder object**), R74.

**Owns.** The gateway pattern and its seven hand-written fakes · `NotificationScheduler`,
`ShareService`, `MediaStore`, `CameraService`, `VoiceRecorder`, `WakelockController` and
`PurchaseService` as the store seam · the per-plugin permission policy holding the Android manifest at
exactly eight entries · **editing `android/expected_permissions.txt` is named in `13 §2.3` as "the
single worst thing you can do to this project"**.
**Does not own.** What is inside an exported file — `shed-export-and-restore`. The release-time
permission gate G1 — `shed-release`. Entitlement rules — `shed-monetization`.

**Extra.** `references/notifications.md` — `reconcile()`, the channels, exact alarms, reboot and DST,
the windowed projection and `ReminderBudget`. **Load when touching a reminder or a notification.**

---

### E13 · `shed-export-and-restore` — engineering · M, 170 lines · `references/restore-and-sweeps.md`, `examples/lambs.csv`

```yaml
name: shed-export-and-restore
description: >-
  Every route records leave or re-enter the phone by — CSV, PDF, the JSON backup, the struck columns
  and safety footers, media on disk, and the atomic restore. Use for any export, backup, import or
  restore. Do NOT use for the share seam (shed-platform-gateways).
```

**Sources.** `09-export-formats.md` §2 (the hand-rolled RFC 4180 CSV writer), §3 (the three shapes),
§4 (the PDF build — embedded TTF, isolate, splitting, memory), §5 (the JSON backup envelope and
forward compatibility), §6 (**the §12.1 and §12.3 disclaimer footers**), §7 (the export → import →
export round trip), §8 (delivery); `04-migrations-media-backup-restore.md` §4.1–§4.9 (media on the
filesystem, the layout, **the relative-path rule**, capture, write ordering, disk full at 3am), §5
(orphan sweeps, both directions), §6 (the backup format), §7 (**the atomic replace-everything restore
— restore is never a merge**), §8 (`VACUUM INTO` as a diagnostics snapshot); `CONVENTIONS.md` R62,
R65 (`BackupHeader` ≠ `ExportEnvelope`); `00-README.md` §9 step 8 (`tool/seed.dart` writes the demo DB
**through the restore path**).

**Owns.** The three CSV shapes, the PDF, the JSON envelope · **every CSV and PDF carries `struck` and
`struck_at`, and every struck row is included and marked** (Indelible screen 11 — *"an export that
quietly drops the strikes would undo the one thing this app is for"*) · the safety footers,
referenced from `Disclaimers` and never re-typed · media layout and relative paths · orphan sweeps ·
atomic restore · `tool/seed.dart`, the precondition for 400-ewe profiling, the overflow matrix, the
goldens and the at-cap tests (critique **G8**).
**Does not own.** The share-sheet seam — `shed-platform-gateways`. Schema migrations —
`shed-migrations`.

**Extras.** `examples/lambs.csv` — the golden output artefact resolving RFC 4180 quoting, the
`struck`/`struck_at` columns and the disclaimer trailer; prose cannot settle it. **Load before writing
or changing a CSV shape.** `references/restore-and-sweeps.md` — the atomic restore sequence, what a
partial restore must never leave behind, and the two sweep directions. **Load when touching restore,
import or media on disk.**

---

### E14 · `shed-monetization` — engineering · S, 90 lines · single file

```yaml
name: shed-monetization
description: >-
  The one non-consumable unlock — the entitlement row, the PurchaseService seam, the free-tier policy
  and the four upgrade-affordance constraints. Use for price, purchase, restore, entitlement, unlock
  or the cap. Do NOT use for how it is drawn (indelible-states-and-feedback).
```

**Sources.** `11-monetization-and-store.md` §1 (the model), §4 (the entitlement row and its three
rules), §5 (the `PurchaseService` seam), §6 (purchase and restore flows), §7 (the `FreeTierPolicy`
object and `EntryContext`), §8 (**the four hard constraints on the upgrade affordance**), §9 (both
stores' privacy declarations for an app that collects nothing), §12 (the gates);
`CONVENTIONS.md` §2.10, R69, R74; `00-README.md` §5.1 (**season-primary, ewe cap secondary; neither
surfaces mid-entry and neither surfaces between 22:00 and 06:00**); `07-screens.md` §19.

**Owns.** The one non-consumable unlock · the entitlement row and its three rules ·
`PurchaseService`, `kUnlockProductId`, `PurchaseSignal`, `StoreUnreachable` · `FreeTierPolicy.decide`
and why `EntryContext.liveEntry` is **structurally incapable** of returning `BlockedByCap` · the four
constraints · store declarations · **the price is never a literal — `ProductDetails.price`, always**.
**Does not own.** How the upgrade row is drawn — `indelible-states-and-feedback`. Where it may render
— `shed-screens-and-routing`; **nothing monetization-related renders on the five shed screens at any
entitlement state**, held by a widget test.

The critique's §3 note is applied: the original `Do NOT` named no competing skill, only a rule.

---

### E15 · `shed-testing` — engineering · M, 180 lines · `references/harness.md`

```yaml
name: shed-testing
description: >-
  How Shed Book is tested and every gate asserted — tiers, fixed time, the drift harness, fakes,
  pumpApp. Use for any test, flaky test, or failing tap-target, semantics or contrast gate, and never
  run --update-goldens. Do NOT use to choose a value (indelible-design-system).
```

**Sources.** `12-testing.md` §1 (the five tiers, and why it is not a pyramid), §2 (time in tests and
the UK ambiguous hour), §3 (the in-memory drift harness), §4 (fakes over mocks — seven hand-written),
§5 (the `pumpApp` harness), §6 (**the overflow matrix — 252 cells over 14 variants**), §7
(accessibility as an executable gate), §8 (goldens — **policy only**), §10 (the product's own promises
as tests), §11 (organisation, tags, ordering, fixtures); `CONVENTIONS.md` R57 (the test tree), R58;
`00-README.md` §8 steps 23–29, §9 step 8.

**Owns.** The five tiers · fixed time and the `uk-zone` tag · the drift harness against
`NativeDatabase.memory()` · the seven fakes · `pumpApp` · **the matrix count is derived from the
variant list in the test, never a typed constant — adding a screen makes it 270, not a lint error**
(00-README step 25) · tap budgets · `test/policy/` named for the property, not the file · fixtures and
`tool/seed.dart` · **every executable gate — contrast, tap target, semantics, reduce-motion** ·
golden *policy* · **the `--update-goldens` prohibition, as a `grounded-copy` integrity rule** (critique
**R2**): *never run `flutter test --update-goldens`. A red golden is a failing test until a human has
looked at the image. Re-baselining is `/shed-goldens-rebaseline`, invoked by the developer, landed as
its own commit.* A `PreToolUse` hook blocks the flag outright (§6.2).
**Does not own.** Choosing a colour, a size or a target dimension — the Indelible skills own the value,
this skill owns the assertion (critique **C7**). Re-baselining — `shed-goldens-rebaseline`.

**Extra.** `references/harness.md` — the drift harness, the seven fakes and `pumpApp` with its exact
override list. **Load when writing a widget or repository test.**

---

### E16 · `shed-migrations` — runbook, **manual only** · S, 70 lines · `examples/migration_step.dart`

```yaml
name: shed-migrations
description: >-
  Writes a Shed Book schema migration — the hand-written forward-only additive from-to step,
  drift_dev schema steps, the regenerated snapshot and test helpers that land in the same commit, and
  the extension of the from-to verifier matrix. This creates a schema snapshot that is irreversible
  once committed, so it runs only when the developer asks for it by name.
disable-model-invocation: true
```

**Sources.** `04-migrations-media-backup-restore.md` §2.4 (the ritual, verbatim), §2.6 (when
`ALTER TABLE` is not enough), §2.7 (what a migration may and may not write), §2.8 (the pre-migration
snapshot), §2.9 (when you get it wrong), §3.1–§3.6 (**the from→to matrix, every pair, and the CI
no-diff check**), §3.4 (**FTS5 shadow tables — unverified, check on day one**); `00-README.md` §7.1,
§7.4 (a schema change lands as one commit).

**Owns.** The hand-written `from<N>To<N+1>` body — forward-only, additive, never destructive · `drift_dev
schema steps` · the committed snapshot · extending the from→to `SchemaVerifier` matrix so every pair
runs `migrateAndValidate` and `PRAGMA foreign_key_check` returns zero rows.
**Does not own.** `make gen` — that is `shed-drift-schema`'s (critique **R1**), and the reason is that
a runbook cannot auto-fire, so an agent adding a column was previously told by the skill it correctly
loaded **not** to run the one command that makes the change valid.

**Extra.** `examples/migration_step.dart` — one complete forward-only additive step. **Load when
writing a step.**

---

### E17 · `shed-release` — runbook, **manual only** · M, 150 lines · `references/pre-release-checklist.md`

```yaml
name: shed-release
description: >-
  Cuts a Shed Book release — the offline gates G0 to G5 against a real release bundle, the exact
  eight-entry permission set, signing and the off-machine symbols archive, size and startup budgets on
  two real devices, version and build number rules, the closed test track, and the release freeze
  between 1 February and 30 April. This builds, signs and tags, so it runs only when the developer
  asks for it by name.
disable-model-invocation: true
```

**Sources.** `13-build-ci-release.md` §2 (the offline contract and its gates, **G0 has not been run —
until it is, G1 is unwritten**), §3 (the complete permission set), §4 (the CI job matrix and its macOS
budget), §6 (size and startup budgets), §9 (versioning and signing), §10 (test tracks and the 12-tester
requirement), §11 (the seasonal freeze), §12 (the manual pre-release checklist);
`../research/00-tech-decisions.md` §3.2, §3.3.

**Extra.** `references/pre-release-checklist.md`. **Load when cutting a tag.**

---

### E18 · `shed-goldens-rebaseline` — runbook, **manual only** · S, 50 lines · single file

```yaml
name: shed-goldens-rebaseline
description: >-
  Re-baselines Shed Book's eight golden images — loads the real bundled fonts so nothing renders in
  Ahem, runs the tolerant comparator, regenerates with make goldens-update, inspects every changed
  image by eye, and lands the new PNGs as their own commit rather than bundled with the change that
  moved them. This overwrites committed reference images, so it runs only when the developer asks for
  it by name.
disable-model-invocation: true
```

**Sources.** `12-testing.md` §8 (goldens, including §8.3's font loader), §5.3 (the tolerant
comparator); `00-README.md` §7.4 (a golden re-baseline is its own commit, never bundled).

The *protective* half of this runbook — the `--update-goldens` prohibition — lives in `shed-testing`,
because a runbook the agent cannot load cannot prevent anything (critique **R2**).

---

### E19 · `shed-code-review` — workflow, **manual only** · S, 90 lines · single file

```yaml
name: shed-code-review
description: >-
  Reviews a Shed Book change the way this project's checklist prescribes rather than the way a general
  review does — read the diff in order of irreversibility, say nothing about anything CI already
  proves, and spend the whole review on the five safety rules asked as questions and the one Quick
  Entry question. Invoked by the developer by name, so it never competes with the bundled review.
disable-model-invocation: true
```

**Sources.** `CODE-REVIEW-CHECKLIST.md` §1 (everything a machine already proves), §2 (what no gate can
catch — the five §12 rules as questions), §3 (the review ritual and read order); `00-README.md` §8 step
10, §2.2 (**the one Quick Entry question — does the shepherd have to do anything new before the record
exists?**).

**Owns.** The read order by irreversibility · the never-waved-through list (`lib/domain/withdrawal/**`,
`drift_schemas/**`, the `[exempt]` allowlist, `disclaimers.dart`, `main.dart`, any new export format,
any table gaining an edit verb).
**Does not own.** Being the authority on any individual rule — it routes, and its body opens by
saying it is the project review, not Claude Code's bundled one.

**Why manual.** Critique §3 — the name-space contest with the bundled `/code-review` is unwinnable in a
listing, and manual invocation is how a review is actually requested. `CLAUDE.md` carries the standing
line *"before claiming work is complete, run `/shed-code-review`"*, so the instruction is present even
though the body is not.

---

### D1 · `indelible-design-system` — design · M, 195 lines · `scripts/contrast.py`

```yaml
name: indelible-design-system
description: >-
  The front door to Indelible — the four rules, serif means it happened and sans means you press it,
  the palette and type scale with measured floors, what the system lacks, the gesture ban, motion and
  haptics. Use before any pixel, colour, hex, token, size, weight or spacing is chosen. Do NOT use for
  what data a screen shows (shed-screens-and-routing).
```

**Sources.** `../design/indelible.md` §1.1 (the thesis), §1.2 (**the four rules that resolve any
disagreement**), §1.3 (what this system is not), §2.1 (the WCAG method), §2.2 (five surfaces),
§2.3 (three inks and one hue), §2.4 (**what measurement overruled** — two values did not survive rule
4), §2.5 (the contrast table), §2.6 (red-shift), §3.1 (two voices), §3.2 (the stacks and the 1/7 and
6/8 test), §3.3 (**weight policy — 390 / 420 / 520 / 600**), §3.4 (the scale **and the corrected
exemption test**), §3.5 (tabular numerals), §3.6 (200% behaviour), §5.1–§5.4 (motion, what must never
animate, reduce-motion, haptics), §6.1 and §6.3 (there is no icon set; stroke and size rules), §9 (the
3am compliance table), §11 (the ten acceptance tests);
`06-design-system.md` §1 (what a visual direction may **not** change), §2 (dark theme slots), §3
(two-tier tokens via one `ThemeExtension`), §5 (typography and the golden font loader), §7 (the gesture
ban as `check_policy` rows), §10 (feedback and the haptic vocabulary);
`../design/00-comparison.md` §2.2; `CONVENTIONS.md` §2.11, R35, R55.

**Owns.** The four rules · the two-voice law and the one documented exception (keypad digits are set
in the record face) · **the whole palette and the measured floors — 4.5:1 text, 3:1 rules and marks —
plus the two placement rules** (`--ink-low` and `--rule` are never drawn on `--slab-pressed`;
`--madder-rule` is never set as text) · red-shift as a six-value override · the type scale, weights,
tracking, tabular figures, no italic, no small caps, 200% behaviour · **the complete gesture ban** —
no swipe action, drag, drag handle, long-press binding, pinch, force touch, hold-to-repeat or slider ·
motion and the haptic vocabulary · **the list of what this system does not have** · the ten acceptance
tests · **a routing table naming the other four design skills**.
**Does not own.** Any component's states table. Where anything sits on the page —
`indelible-page-and-screens`. What data a screen shows.

**Corrected rules it must state.**
1. **`DEAD`, `AUTO-CAPTURED` and `DERIVED FROM 3 STROKES` meet the 18px floor.** They fail §3.4's own
   third exemption test — each is the sole carrier of its meaning on its line — so they are not
   exempt stamps. `--t-stamp: 14px` and `--t-head: 16px` in the mockup are defects, not the spec.
2. **The 390 / 420 / 520 / 600 weights need `FontVariation` on a variable axis**, because Flutter's
   `FontWeight` is w100–w900 in hundreds. `06 §5.2` records the Atkinson axis as covering **500–700**,
   which excludes 390 and 420 — **P7 is open and the skill says so rather than picking**.
3. **P10 is open**: `06`'s definition of done says the haptic vocabulary has exactly **four** entries;
   Indelible §5.4 lists **five** with distinct rhythms. `HapticFeedback.successNotification()` is
   carried as **unverified** in `00-README §10`.

**Extra.** `scripts/contrast.py` — **narrowed to the one job `test/design/contrast_test.dart` cannot
do**: take two proposed hex values, print the WCAG ratio and pass/fail against 4.5 and 3.0.
**Execute it; do not read it. Run it before proposing any colour.** The shipped values are proved by
`dart test test/design/contrast_test.dart`, and a second implementation of the WCAG formula that could
disagree with the Dart one would be a liability — so this script never re-checks a shipped token.

---

### D2 · `indelible-page-and-screens` — design · M, 180 lines · single file

```yaml
name: indelible-page-and-screens
description: >-
  The page every screen is — one ruled document under twelve filters and note search, the madder
  spine, the margin cell that is a target, the spacing scale and row heights. Use when composing a
  screen or choosing any padding, gap, width, height or target. Do NOT use for a struck row
  (indelible-marks-and-strikes).
```

**Sources.** `../design/indelible.md` §4.1 (the ten-step spacing scale, no half-steps), §4.2 (radii,
**all rules are 2px never 1px**, no shadows), §4.3 (the layout grid — the 68px margin cell, the
continuous madder spine, the 76–377 record column, **the row sub-grid**), §4.4 (row heights), §4.5
(**the three reach bands, the 560px binding rule, the minimum-target audit, the left-handed mirror
that moves the slab and never the spine**), §3.6 (rows grow, the grid does not move), §7.3 (the ruled
record row and its states), §7.4 (the ewe row), §7.5 (the pen tile that is not a tile — twelve ruled
rows), §7.16 (the page header), §7.17 (the index sheet), §8 (**all twelve screens — cited by screen
number, never copied**); `06-design-system.md` §6 (tap targets, hit slop and separation), §11
(pen-board glanceability); `../design/00-comparison.md` §4.1 (the persistent loaded subject).

**Owns.** The spine, the margin cell (68 × 64 and **itself a legal target**), the record column and
gutters · the ten-step scale · the 64px record row, the 88px ewe and pen rows, the 44px chart row and
44px header, the 152px bottom band · the header and bottom bands · **the 64 × 64 target floor and the
minimum-target audit** · the three reach bands and the 560px rule · the left-handed mirror · 200%
growth without the grid moving · **the twelve screens as filters of one document, plus the thirteenth
route, note search**, which `indelible.md` §8 does not cover (critique **G6**).
**Does not own.** A row's struck or queried state — `indelible-marks-and-strikes`. How a target is
painted — `indelible-controls`. What data a screen shows — `shed-screens-and-routing`.

**Corrected rule it must state.** **The live row is a fixed layer above the bottom band and cannot
scroll away.** `indelible.html:1138` has it as the last child of the scrolling `.stream`, which means
the open row can scroll off screen and the shepherd loses track of whose row is open — the design's
one genuine safety gap. This is where the persistent-loaded-subject graft lands (§4.3): the animal
being written about is the largest object on the phone and survives a cold launch.

**Carries P9 as an open conflict**: `00-README` step 19 requires ≥ 16 pt separation; Indelible §4.5
says 8–12px. One of the two is asserted by `test/design/tap_target_test.dart`.

---

### D3 · `indelible-controls` — design · M, 175 lines · single file

```yaml
name: indelible-controls
description: >-
  Every pressable thing — the corner slab, word button, INDEX, keypad, ease group, the stepper that
  replaces sliders, the placeholder-free field and the one sheet. Use for any button, input, field,
  form, picker, chooser, keypad, sheet or toggle. Do NOT use for rows or marks
  (indelible-marks-and-strikes).
```

**Sources.** `../design/indelible.md` §7.1 (the corner slab, its per-page verb table and five states,
**including that it never refuses a press**), §7.2 (the keypad key — **no key is ever disabled**),
§7.8 (the number stepper — **never a slider, no repeat-on-hold**), §7.9 (segmented choice — **ease
1–5 only**), §7.10 (the check control — a stamp with a time on it), §7.12 (the text field — **there is
never placeholder text inside a field**, and the `YOUR ENTRY` withdrawal case), §7.13 (the word button
and its five states), §7.14 (the bottom sheet — the only overlay, no drag handle), §7.15 (the recents
line), §7.17 (`INDEX`), §5.1 (`--motion-press`, fill only), §5.4 (haptics per press);
`06-design-system.md` §8 (the custom numeric keypad), §12 (component inventory);
`08-platform-integration.md` §3 (photo capture) and §4 (audio recording) for what a capture surface
actually returns; `CONVENTIONS.md` §2.11 (`ShedTapTarget`, `ShedKeypad`, `ShedPhoto`), R70.

**Owns.** All six pressable forms plus the sheet — **which is why this skill exists**: critique
**C1** found the old `indelible-buttons` opening with *"there are exactly two button forms in this
app"*, which is false on its face. The two *action* forms (corner slab, word button) and the pinned
`INDEX` · every control that captures a value (keypad key, ease group, stepper, ruled field, check
control) · the bottom sheet and its exactly three contents · the recents lines · **the photo and
voice-note capture surfaces**, which `indelible.md` §7 has no component for at all (critique **G5**,
conflict **P12**) — the rule being that a captured photo is a ruled cell with a `ColorFiltered`
`ShedPhoto`, never a card and never a thumbnail grid.
**Does not own.** Rows, marks, tallies, strikes. The page grid and target *sizes* —
`indelible-page-and-screens` owns the floor; this skill owns how the target is painted.

**Corrected rule it must state (P8).** **There is no birth-type chooser anywhere in the product.**
`ShedChoiceRow` survives only for lambing ease 1–5, which is a genuine choice with no derivable
answer. Birth type is derived from the tally strokes and labelled `(COUNTED)`; a declared type that
contradicts the strokes prints a `?` in the margin and adjusts nothing. This sentence sits directly
beside the ease group in the body, where the mistake would be made.

---

### D4 · `indelible-marks-and-strikes` — design · M, 180 lines · single file

```yaml
name: indelible-marks-and-strikes
description: >-
  Every mark in this app and Rule 1 behind them — nothing is removed, only struck. Use for any status,
  warning, threshold, unset or derived value, the tally, the birth type, any count or chart, and
  whenever a delete, hide, mute or edit is designed. Do NOT use for its mechanism (shed-safety-rules).
```

**Sources.** `../design/indelible.md` §1.1 (**there is no delete; nobody ever chooses "triplet"**),
§1.2 Rule 1 and Rule 3, §2.7 (**the table giving every state at least two non-colour channels**),
§4.2 (`--rule-w` 2px, `--rule-strike-w` 3px, `--rule-double-gap`, `--rule-dot`), §6.2 (**the six
marks** — dagger, double dagger, query mark, tally stroke with the five-bar gate, strike line, delete
key), §6.3 (stroke and size rules; **no new mark may be added without deleting one**), §7.6 (the
withdrawal countdown's day tally), §7.7 (**the stamp — boxed means a state of the animal, unboxed
means a note about the record**), §7.11 (the chart as small multiples of the ruled row — no axis,
gridline, legend, tooltip, colour or animation), §5.1 (`--motion-strike`, the only animation with a
direction), §8 screen 3 (striking, the contradiction case and its two-option chooser), screen 9
(`MUTE` is a strike), screen 12 (**the only two honest deletes**), §9 safety table;
`06-design-system.md` §11, §12 (`ShedStatusBadge`, `ShedPenTile` — superseded by P8);
`10-accessibility-and-i18n.md` §5 (colour is never the only channel).

**Owns.** The six marks and their exact geometry · the 2px rule, the 3px strike, the doubled rule, the
dotted rule that means *never entered* · boxed and unboxed stamps · the two-non-colour-channel table ·
the strike line, its 180ms left-to-right draw, the `STRUCK hh:mm` margin stamp, and **struck rows
staying exactly where they were at full legibility in every list and every export forever** · the
query mark, its two-option chooser and the rule that **the app never picks** · edited timestamps
printing both times · the only two honest deletes · **the lamb tally, the true five-bar gate, the
struck stroke, the day tally and the lambing spread**, with the ban on every chart library.
**Does not own.** §12.4's *mechanism* — `shed-safety-rules`; the body says so explicitly and does not
restate it (critique **C6**). Undo semantics and its window — `shed-screens-and-routing` (critique
**C4**). Numeric typography — `indelible-design-system`. Colour values — `indelible-design-system`.

**Corrected rules it must state.**
1. **`DERIVED FROM 3 STROKES` meets the 18px floor** — it is the sole statement of the §12.4 claim
   and therefore not an exempt stamp. So does **`DEAD`**.
2. **Undo is a time-boxed strike affordance in the row's own margin** (§4.1), the window stated in
   seconds. You strike; you never erase; there is no floating overlay to dismiss.

The five-bar gate's crossing stroke is ten lines of SVG and lives **inline in the body**, not in a
reference — research 02 §3.6: *you cannot progressive-disclose a surprise*.

---

### D5 · `indelible-states-and-feedback` — design · M, 150 lines · single file

```yaml
name: indelible-states-and-feedback
description: >-
  What a page shows when there is no record, a write returns, or the app must speak about itself. Use
  whenever an empty state, first frame, error, confirmation, receipt, banner, prompt, spinner, toast,
  snackbar or modal is proposed. Do NOT use for whether the write succeeded (shed-write-path).
```

**Sources.** `../design/indelible.md` §1.3 (**no spinner, no skeleton, no empty-state illustration, no
modal dialogs**), §5.2 (**the first painted frame is `--page` with tonight's page already on it — no
splash, no logo, no white flash, on either platform**), §7.3 (the unset cell — a dotted rule and a
visible gap, never a hidden field), §7.11 (the zero day and the empty season), §8 screen 3 (**the live
row is already drawn with the time already inked — this is the receipt**), screen 11 (the export
prompt as a printed line at the foot of tonight's page, once a day, dismissible for the season; and
the printed footer), §9 (**zero interruptions — no toast, no snackbar, no modal dialog anywhere**);
`07-screens.md` §1.4 (frame 1), §2.2 (empty, filtered-empty, the dark error panel with "Try again" and
"Diagnostics", and note search's three distinct empty strings), §16 (the end-of-day export prompt);
`06-design-system.md` §9 (`NightErrorPanel` bypasses `Theme` and hard-codes `#0B0D0E`), §10 (feedback
channels), §12 (`ShedBanner`, `ShedEmptyState`, `ShedReceiptBar`);
`11-monetization-and-store.md` §8 (the four constraints on the upgrade affordance);
`CONVENTIONS.md` §2.11, R30, R31.

**Owns.** Frame 1 before data lands · empty and filtered-empty · the error panel · **the save
confirmation** · the once-a-day export prompt line · the two static upgrade rows · the unset-cell
gap. These are `06 §12`'s `ShedReceiptBar`, `ShedBanner` and `ShedEmptyState`, which had **no design
owner at all** before the critique created this skill (**G2, G3, G4, G6**).
**Does not own.** Whether a write succeeded — `shed-write-path`. Entitlement rules —
`shed-monetization`. Undo's per-verb window — `shed-screens-and-routing`. The strike itself —
`indelible-marks-and-strikes`.

**Corrected rules it must state (P2).**
1. **There is no SnackBar. `showSnackBar(` is banned everywhere, including in `feedback.dart`** — a
   `check_policy` row with no allowlist entry. `CONVENTIONS §2.11`'s *"the one file permitted to call
   `showSnackBar(`"* is superseded.
2. **The receipt is the committed row itself**, in ink, one line above the one being written.
   `feedback.dart` is the printed-receipt channel, not a snackbar wrapper; `confirmSaved`,
   `showFailure` and `showCapRow` keep their names and signatures (R30) and change what they render.
3. **`SaveReceipt.undo` becomes a time-boxed strike affordance in the row's margin**, with the window
   in seconds.
4. **`AUTO-CAPTURED` meets the 18px floor** — the sole §12.5 provenance label carries meaning nothing
   else on its line carries.

**Carries P14 as an open conflict**: `NightErrorPanel` hard-codes `#0B0D0E`, Indelible's `--page` is
`#0A0A0B`, and `06`'s definition of done says *"no frame is brighter than `#0B0D0E`"*. A one-hex
disagreement on the **first painted frame**, measured at 240 fps.

---

## 6. What is deliberately not a skill

### 6.1 `CLAUDE.md` — present, not consulted

Under 200 lines. Everything here is needed in *every* session including one-line ones, and research
02 §1.1 is explicit that a simple one-step request may trigger no skill however good the description.

| Content | Why |
|---|---|
| **The four non-negotiables** — the offline-purity wording **verbatim** (decision-record §3.1) and the rule that *"your data never leaves your phone"* is never written; the 3am question; the five safety rules as one-line headlines; *"every write commits immediately, no draft state"*. | Critique §3, §10.3. They were only in `shed-engineering`, which under-fires — so when it did not fire they were **absent**. |
| **The routing table** — developer intent → the one skill that owns it. | Critique §5 cut `shed-engineering`; a router that loses every contest with a specific skill belongs where it is always present. |
| The pinned versions (Flutter 3.44.8, Dart 3.12.2, `flutter_riverpod` **2.6.1 exact**, drift 2.34.2, `build_runner ">=2.15.0 <2.15.2"`), the one-line product identity, the top-level repo layout, and the three commands `make gen` · `make check` · `make test`. | A version fact must not depend on a skill triggering. |
| **The banned-words list and the one-word-per-concept table** (`CONVENTIONS §5.1`–§5.3). | Critique **C8** — three skills claimed copy; this makes it two. Also a gate row, so it is enforced twice and remembered once. |
| The standing line *"before claiming work is complete, run `/shed-code-review`"*. | The instruction is present even though the manual skill's body is not. |
| The owner rulings of §4.1 and §4.2 in one line each. | They contradict a **BINDING** document (`CONVENTIONS §2.11`) and a written one (`06 §12`), so they must be visible without a skill firing. |

### 6.2 Hooks and settings — mechanical, not remembered

| Mechanism | What it does |
|---|---|
| `PostToolUse` | `dart format` and `dart run tool/check_policy.dart` after edits. A rule that must fire on every edit must not depend on a model loading a skill. |
| `PreToolUse` | **Blocks `flutter test --update-goldens` outright** (critique **R2**; `12 §11.4` already argues this about the `Makefile` target name). |
| `PreToolUse` | Blocks an edit to `android/expected_permissions.txt` — named in `13 §2.3` as *"the single worst thing you can do to this project"*. |
| `PreToolUse` | Blocks a commit that edits `tool/policy_allowlist.txt` without a reason in the message. |
| pre-commit | `pubspec.yaml` changed without a `pubspec.lock` diff, or the reverse (`00-README §7.1` calls it *"a review stop"* — it is mechanical). |
| pre-commit | `tool/lint_skills.py --strict`, extended to **assert that every repo path named in a skill body exists** (critique §7 — recovers the staleness signal lost by refusing `paths:`). |
| `.claude/settings.json` | `skillListingBudgetFraction: 0.02`. **A second margin, not the thing that makes §1 fit.** |

### 6.3 Stays a document

`00-tech-decisions.md` (the reasoning and the rejected alternatives — distilling it creates a second
authority that drifts) · the thirteen open questions and the owner rulings (they change; a doc is read
by a human who can see the date) · the twelve screen briefs verbatim and every §-numbered rationale in
`01`–`13` · **`the-register.md` and `strip-bay.md`, which no skill may cite, mention or borrow from**
except through §4.3's single graft · the four skill-authoring research notes, which govern how these
24 are written and not how the app is built.

---

## 7. Build order and the acceptance test

### 7.1 Before a single `SKILL.md` is written

1. **Rule P1** — `struck` / `struck_at`. Schema-irreversible; blocks E6 and E13.
2. **P2 and P8 are ruled** (§4.1, §4.2). P3, P7, P9, P10, P14 are recorded as open **inside the owning
   skill**, with both sides cited and neither picked.
3. **Write `CLAUDE.md`** (§6.1) and wire the six hooks (§6.2). Both reduce what the skills must carry,
   and the size targets in §3 assume they exist.

### 7.2 Phases

| Phase | Build | Why here |
|---|---|---|
| **1** | `indelible-design-system`, `shed-conventions`, `shed-dependencies-and-toolchain` | The design front door carries the routing table for its four dependants. Conventions and toolchain govern the first `mkdir` and the first `pubspec.yaml`. |
| **2** | `shed-drift-schema`, `shed-domain`, `shed-withdrawal`, `shed-safety-rules` | The irreversible and the invisible-when-wrong, in the order the app is built. P1 gates the first. |
| **3** | `indelible-page-and-screens`, `indelible-marks-and-strikes`, `indelible-controls`, `indelible-states-and-feedback` | The design half, after its front door is stable. P2 and P8 gate the last two. |
| **4** | `shed-bootstrap-and-errors`, `shed-riverpod-providers`, `shed-write-path`, `shed-screens-and-routing` | The machinery Quick Entry needs, in build order, so each is testable against real code as it lands. |
| **5** | `shed-testing`, `shed-accessibility-and-copy` | They pay off once there is code to test and label. |
| **6** | `shed-platform-gateways`, `shed-export-and-restore`, `shed-monetization` | Last in the app's build order. |
| **7** | `shed-migrations`, `shed-release`, `shed-goldens-rebaseline`, `shed-code-review` | The runbooks encode procedures whose exact commands exist only once the `Makefile` and CI do. |

### 7.3 The acceptance test the first catalogue named and did not run

**For each collision below, three near-miss prompts in a fresh session, confirming exactly one skill —
or the stated pair — fires.** Near-misses, not obvious irrelevancies, are the whole game (research 02
§1.7).

| Developer intent | Must resolve to | Was |
|---|---|---|
| "add a button" / "add the ease buttons" / "a segmented control" | `indelible-controls` | **C1** — two skills with a false opening sentence |
| "add a screen" | `shed-screens-and-routing` → then `indelible-page-and-screens` | **C2** — six skills |
| "record a lambing" / "the tally" | `indelible-marks-and-strikes` (+ `shed-write-path` for the verb) | C2 + C3 |
| "add undo" | `shed-screens-and-routing` | **C4** — three skills, two identical claims |
| "add a column" / "name this column" | `shed-drift-schema` (store) vs `shed-conventions` (spelling) | C5 |
| "never silently correct that" / "let them fix a typo" | `shed-safety-rules` (mechanism) vs `indelible-marks-and-strikes` (what is seen) | **C6** — the highest contradiction risk |
| "fix the contrast" / "the contrast test fails" | `indelible-design-system` (the value) vs `shed-testing` (the assertion) | C7 |
| "add a label" / "rename this string" | `shed-accessibility-and-copy` | **C8** — three skills |
| "add a package" / "let's use fl_chart" / "pub add" | `shed-dependencies-and-toolchain` | **G1** — nothing fired |
| "make it faster" / "janky at 400 ewes" | `shed-riverpod-providers` | **G7** — nothing fired |
| "show a confirmation" / "add a snackbar" | `indelible-states-and-feedback` | **G2** — nothing owned it |
| "the empty state" / "a spinner" | `indelible-states-and-feedback` | **G4** — nothing owned it |
| "run codegen" / "make gen" | `shed-drift-schema` | **R1** — stranded behind a manual runbook |
| "the golden is red" | `shed-testing` (refuses `--update-goldens`) | **R2** — the prohibition was unloadable |
| "the birth type" | `indelible-marks-and-strikes` — *derived, never chosen* | **P8** — the doc set documented a chooser |

Then: `/doctor`, and read the **Skills** row in `/context` against §1.2's arithmetic rather than
against a feeling. If the measured listing exceeds 6,400 characters, the fix is to shorten a
description, not to raise the fraction.

**Ongoing, forever:** *"when an agent makes a mistake you have to correct, add the correction to the
gotchas section."* The gotchas sections are the only part of this manifest that should keep growing.

---

## 8. Status

| | |
|---|---|
| **Manifest version** | 1.0 — 2026-07-27 |
| **Supersedes** | `00-catalogue.md` v1.0 (30 skills) and closes `01-catalogue-critique.md` v1.0 (31 skills) |
| **Skills specified** | **24** — 19 engineering, 5 design. **20 listed**, 4 manual-only |
| **Listing budget** | 6,357 / 8,000 characters — **20.5% headroom** at the default `skillListingBudgetFraction`, 60.3% at 0.02 |
| **Skills authored** | 0 |
| **Design system** | `../design/indelible.md` v1.0 — the only direction any skill may cite, plus the one graft in §4.3 |
| **Extras** | 1 script · 6 examples · 9 references |
| **Blocking before authoring** | **P1** (schema-irreversible). P2 and P8 are ruled in §4.1–§4.2. P3, P7, P9, P10, P14 are carried as open, inside their owning skill |
| **Amendment rule** | Changing a skill's scope changes this manifest in the same commit, including §1's arithmetic, §3's table and §7.3's acceptance test. A skill whose description no longer matches its row here is worse than a missing skill — and any description edit re-runs §1.2's sum. |
