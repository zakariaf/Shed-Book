# 00 — The Shed Book skill catalogue

**Status:** design, not yet authored. This file specifies **what** to build; the four research notes in
[`research/`](research/) specify **how** to write each one. Nothing here overrides
[`../engineering/CONVENTIONS.md`](../engineering/CONVENTIONS.md) (names),
[`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) (decisions) or
[`../design/indelible.md`](../design/indelible.md) (the selected design system).

**Where they live:** `.claude/skills/<name>/SKILL.md`, committed to the repo. Project scope, not personal —
personal skills do not reach cloud sessions and are not in the repo's history alongside the code they
describe (research 03 §3.2).

---

## 1. The shape of the catalogue

**30 skills: 19 engineering, 11 design.** Two front doors, three manual-only runbooks, 27 auto-triggered.

The count is set by two forces pulling opposite ways.

**Pulling up — the owner's organising principle for the design half.** *There is exactly one way to draw
each thing in this app.* That only works if each thing has exactly one authority with a name. A single
`indelible` skill cannot be the authority on the corner slab **and** on tabular figures **and** on the
strike line, because an agent that loads it for one gets the other two as noise, and — worse — an agent
that *doesn't* load it gets nothing. Eleven design skills is the number of genuinely distinct
"things you can draw" in [`indelible.md`](../design/indelible.md) once the seventeen components in its §7
are grouped by *what triggers the work*, not by what section they sit in.

**Pulling down — the listing budget.** Claude Code loads every skill's name and description into context
at ~1% of the window, and *"when the listing overflows, Claude Code drops descriptions starting with the
skills you invoke least"* (research 01, 03 §2.4). The failure is silent: a skill stops firing and its file
is unchanged. Twenty-five is the number at which this starts to bite.

**How both are satisfied:** the three runbooks carry `disable-model-invocation: true`, which *"removes the
skill from Claude's context entirely"* (research 02 §7.4). They cost zero listing budget. So the catalogue
is **30 skills at the cost of 27**, and 27 is inside the safe band. If `/doctor` still reports truncation
after authoring, the lever is `skillListingBudgetFraction: 0.02` in `.claude/settings.json`, not deleting
skills.

**What the count is *not* padded with.** Six skills that a naive reading of the doc set would produce were
deliberately merged or refused; §7 lists them with the reason.

### House frontmatter rules

| Rule | Reason |
|---|---|
| `name` + `description` only. `name` equals the directory name. | The two spec-required fields; everything else is a Claude-Code-only extension that other agents silently ignore (research 02 §8.1, 04 §1.1). |
| No `version`, no `tools`, no `display-name`. | Not in either schema; Anthropic's own `quick_validate.py` **rejects** unknown keys (research 04 rule 17). |
| The three runbooks add `disable-model-invocation: true`. Nothing else. | Side-effecting procedures must never auto-fire, and the flag also buys back listing budget. |
| **No `paths:` on any skill.** | `paths` limits auto-activation to *files already in play*. Every skill here must fire **before** the file exists — the design skills exist to be read before the first line is written. `paths` would make the most important ones silent at exactly the moment they matter. |
| No colon inside a description. | `description: Use when: x` is invalid YAML and Claude Code then loads the skill with **empty metadata** — `/name` still works, so you will not notice, and it never auto-triggers again (research 03 §10.1). Every description below is written with em-dashes instead. |
| Descriptions are third person, state **what** and **when**, are pushy about triggers, and end with a **Do NOT** naming the actual competing skill. | Research 02 §1.2, §1.5. Four of Anthropic's five document skills carry a negative trigger; it is how overlap is stopped. |
| Bodies stay under 250 lines. Anything longer moves to `references/` **with a load condition**. | Anthropic's median shipped skill is ~130 lines; 500 is a ceiling, not a target (research 02 §2.2). "See references/" is the documented anti-pattern; "read X **if** Y" is the pattern. |

---

## 2. The catalogue

Size: **S** ≤ 100 lines · **M** 100–200 · **L** 200–250 + references.
Extras: `ref` = `references/`, `ex` = `examples/`, `scr` = `scripts/`, `tpl` = `templates/`.

### 2.1 Engineering — 19

| # | Skill | Kind | Size | Rich | Scope in one line | Sources | Extras |
|---|---|---|---|---|---|---|---|
| E1 | `shed-engineering` | workflow | M | ref | **Front door.** The four non-negotiables, the pinned stack, the gate commands, and the routing table to every other engineering skill | 00-README, decisions §1–§3 | `ref` feature-pipeline, build-order |
| E2 | `shed-conventions` | engineering | L | ref | The tree, the eight layer rules, the type and provider catalogues, every naming rule, and the one-word-per-concept vocabulary | CONVENTIONS (all), 01 §2–§3 | `ref` type-catalogue, provider-catalogue, layer-rules, vocabulary |
| E3 | `shed-bootstrap-and-errors` | engineering | S | ex | `main()` awaits nothing, the first frame, the global error net, `WriteOutcome`/`ShedFailure`, the local log | 01 §5–§6, 13 §8 | `ex` main.dart, failure_mapping.dart |
| E4 | `shed-riverpod-providers` | engineering | L | ref tpl | Riverpod 2.6.1 exactly — the 3.x ban list, the spelling card, provider shapes, controllers, `WriteController.guard` | 02 §1–§7 | `ref` riverpod3-ban-list, spelling-card · `tpl` provider.dart |
| E5 | `shed-write-path` | engineering | M | tpl ex | Repository methods are event verbs; one transaction; `appNow()` once; no draft, no `save()`; undo per verb | 01 §4, 07 §15, CONVENTIONS §2.13 | `tpl` repository_verb.dart · `ex` foster_verb.dart |
| E6 | `shed-drift-schema` | engineering | L | ref tpl | Table, column, key, index and CHECK conventions; time and unit storage; the freeze point | 03 (all) | `ref` column-conventions, table-catalogue · `tpl` table.dart |
| E7 | `shed-domain` | engineering | L | ref | Pure Dart only; the time model; units; every statistic and its edge cases and verbatim definition | 05 §1–§2, §4–§6, §8 | `ref` time-model, units, statistics |
| E8 | `shed-withdrawal` | engineering | M | ex | Never defaulted; the sealed type; the ceil-to-next-local-midnight clear date; the DST cases | 05 §3, decisions #3 | `ex` clear_date.dart, clear_date_dst_test.dart |
| E9 | `shed-safety-rules` | engineering | M | — | The five §12 rules as structural mechanisms, each with the level of the hierarchy that holds it | 05 §7, CODE-REVIEW §2 | *(single file)* |
| E10 | `shed-screens-and-routing` | engineering | L | ref tpl | What a screen contains, the one query that feeds it, its states and tap budget, and how it is routed to | 07 (all), 02 §8 | `ref` screen-briefs · `tpl` screen_scaffold |
| E11 | `shed-accessibility-and-copy` | engineering | M | ref tpl | Semantics, headings, text scaling, motor, the ship gate — and every user-facing string through ARB | 10 (all), CONVENTIONS §5.4 | `ref` semantics, en-gb-formats · `tpl` arb_entry |
| E12 | `shed-platform-gateways` | engineering | L | ref tpl | The seven seams, `reconcile()`, capture, share, import, wakelock, and the per-plugin permission policy | 08 (all) | `ref` notifications, capture-share-import, permissions · `tpl` gateway.dart |
| E13 | `shed-export-and-restore` | engineering | L | ref ex | CSV, PDF, the JSON envelope, the disclaimer footers, media layout, orphan sweeps, atomic restore | 09 (all), 04 §4–§7 | `ref` csv-shapes, pdf, backup-envelope, media-layout · `ex` lambs.csv |
| E14 | `shed-monetization` | engineering | M | ref | The one unlock, the entitlement row, `FreeTierPolicy`, the four constraints on the upgrade row | 11 (all) | `ref` free-tier-policy, store-declarations |
| E15 | `shed-testing` | engineering | L | ref tpl ex | The five tiers, fixed time, the drift harness, fakes, `pumpApp`, the 252-cell matrix, the a11y gates | 12 (all) | `ref` harness, overflow-matrix · `tpl` widget_test.dart · `ex` repository_test.dart |
| E16 | `shed-code-review` | workflow | M | — | Read by irreversibility, skip what CI proves, spend the review on the five §12 questions | CODE-REVIEW (all) | *(single file)* |
| E17 | `shed-codegen-and-migrations` | **runbook** | M | ref tpl | `make gen`, `make-migrations`, the hand-written step, the snapshot, the from→to matrix | 04 §2–§3, 00-README §7.3 | `ref` migration-matrix · `tpl` migration_step.dart |
| E18 | `shed-release` | **runbook** | M | ref | G0–G5 against a real AAB, the eight-entry permission set, signing, budgets, the seasonal freeze | 13 (all) | `ref` gates, permission-set, pre-release-checklist |
| E19 | `shed-goldens-rebaseline` | **runbook** | S | — | Re-baseline the eight images as their own commit, with real fonts and the tolerant comparator | 12 §8 | *(single file)* |

### 2.2 Design — 11, all from `indelible.md`

| # | Skill | Kind | Size | Rich | Scope in one line | Sources | Extras |
|---|---|---|---|---|---|---|---|
| D1 | `indelible-design-system` | design | M | scr ref | **Front door.** The four rules, the two-voice law, what the system does not have, motion and haptics, and the routing table | indelible §1, §5, §11 | `scr` indelible_audit.sh · `ref` acceptance-tests |
| D2 | `indelible-color-and-contrast` | design | M | scr ref | Five surfaces, three inks, one hue with three jobs, red-shift, and the measured floors | indelible §2, §10 · 06 §2–§4 | `scr` contrast.py · `ref` palette |
| D3 | `indelible-typography` | design | M | scr ref ex | Two faces, the scale, weights, tracking, tabular figures, no italic, behaviour at 200% | indelible §3 · 06 §5 | `scr` check_type.sh · `ref` type-scale · `ex` text_theme.dart |
| D4 | `indelible-page-grid-and-rows` | design | M | ex ref | The spine, the margin cell, the record column, the spacing scale, and the ruled row that fills them | indelible §4.1–§4.4, §7.3–§7.4, §7.15–§7.16 | `ex` ruled_row.dart · `ref` measurements |
| D5 | `indelible-targets-and-gestures` | design | S | scr | The 64 floor, the reach bands, the 560px rule, the complete gesture ban, the left-hand mirror | indelible §4.5, §9 · 06 §6–§7 | `scr` check_gestures.sh |
| D6 | `indelible-marks-and-status` | design | M | ref ex | Rules, strikes, doubled and dotted lines, the six marks, the stamp vocabulary, and the no-colour-alone table | indelible §2.7, §4.2, §6, §7.7 | `ref` status-encoding · `ex` dashed_rule_painter.dart |
| D7 | `indelible-buttons` | design | S | ex | The corner slab and the word button — the only two button forms that exist | indelible §7.1, §7.13, §7.17 | `ex` buttons.dart |
| D8 | `indelible-input-and-sheet` | design | M | scr ex | The keypad, the one overlay, the ruled text field, the stepper, the ease group, the check control | indelible §7.2, §7.8–§7.10, §7.12, §7.14–§7.15 | `scr` check_no_placeholder.sh · `ex` shed_keypad.dart |
| D9 | `indelible-strike-and-query` | design | M | scr | Rule 1 — nothing is removed, only struck. Strikes, queries, edited times, and the only two honest deletes | indelible §1.2, §7.3, screens 3 and 12 | `scr` check_no_erasure.sh |
| D10 | `indelible-tallies-and-blocks` | design | M | ex | Every quantity is blocks of ink — the lamb tally, counted birth types, day tallies, the spread chart | indelible §6.2, §7.6, §7.11 | `ex` tally_marks.dart, spread_chart.dart |
| D11 | `indelible-screen-composition` | design | M | ref | One document under twelve filters, plus the two screens with their own geometry | indelible §8 | `ref` per-screen |

**Rich vs simple.** Three ship as a single file (E9, E16, E19) because their whole content is a set of
judgement questions with nothing mechanical underneath. The rest earn their extras against one test each:
a `scripts/` entry exists only where a rule is greppable (five of them — contrast, type, gestures,
placeholders, erasure), `templates/` only where there is a real file to scaffold, `examples/` only where a
complete correct artefact resolves a judgement prose cannot (the `main()` ordering, a ruled row's
sub-grid, the five-bar tally), and `references/` only where the content would push the body past 250 lines
**and** has a one-line load condition. No skill ships an empty directory.

---

## 3. The frontmatter descriptions

These are the load-bearing strings. Each is third person, states what and when, is pushy about triggers,
names its nearest competitor in a `Do NOT` clause, and contains no colon. All are between 400 and 800
characters — inside the 1024 hard cap with room for the listing to degrade gracefully, key use case first.

### 3.1 Engineering

```yaml
name: shed-engineering
description: >-
  Routes any Shed Book engineering task to the one skill that owns it, and carries the four
  non-negotiables — the offline-purity contract and its only permitted wording, the 3am test, the five
  safety rules, and the rule that every write commits immediately with no draft state. Also carries the
  pinned stack, the make gen and make check and make test gates, and the rule that a red gate is never
  turned green by editing the gate or its allowlist. Use at the start of any work on this Flutter app —
  a feature, a screen, a table, a provider, a test, an export, a dependency, a build — and whenever it is
  unclear which rule or which document governs. Do NOT use for visual work, which has its own front door
  in indelible-design-system.
```

```yaml
name: shed-conventions
description: >-
  The naming and structure authority for Shed Book — the canonical lib tree, the eight layer rules and
  the two path-pair bans, the complete type and provider catalogues, and the naming of files, classes,
  providers, controllers, widget keys, policy rule ids and database columns, plus the one-word-per-concept
  vocabulary and the absolutely banned words including draft, save, commit, submit, sync and flags. Use
  before creating any file or folder, before naming anything at all, when deciding whether one folder may
  import another, and when choosing the word for a concept in code, in copy or in a commit message. Do NOT
  use for how a widget is drawn or for what a screen contains.
```

```yaml
name: shed-bootstrap-and-errors
description: >-
  Governs how Shed Book starts and how it fails — main awaits nothing, error handlers are installed before
  runApp, the database opens after the first frame, the first painted frame is a dark interactive shell
  with no data, plus the global error net, the dark error panel that bypasses Theme, the mapping from
  SqliteException to ShedFailure, and the local redacted rolling log that is never a crash reporter. Use
  when editing main.dart or app.dart, adding anything to startup, catching or mapping an exception, wiring
  logging or diagnostics, or investigating a white flash, a slow cold start or an unhandled error. Do NOT
  use for repository write semantics or for the wording a screen shows after a failure.
```

```yaml
name: shed-riverpod-providers
description: >-
  The state and dependency-injection rules for flutter_riverpod 2.6.1 pinned exactly — the Riverpod 3 ban
  list, the 2.6.1 spelling card, provider shapes and disposal, the DI graph rooted at databaseProvider, one
  drift statement per screen with fan-in done in SQL, screen controllers that hold state and never data,
  and the double-tap-safe WriteController guard. Use when adding or changing any provider, notifier or
  controller, when wiring a screen to data, and whenever ref.watch, ref.read, AsyncValue, autoDispose,
  family or select appears — especially when copying Riverpod code or documentation published after 2025,
  all of which shows APIs that do not compile here. Do NOT use for repository methods, drift queries or
  navigation.
```

```yaml
name: shed-write-path
description: >-
  The single write path in Shed Book — repository methods are event verbs, there is no save of an
  aggregate anywhere, the row is created on screen entry rather than on exit, appNow is called once per
  mutation, everything runs inside one transaction, and the method returns a WriteOutcome. Also covers undo
  defined per verb and living only until the receipt is dismissed, and why the data layer may never import
  the validation folder. Use when adding or changing anything that stores a fact — a mutation, an undo, a
  strike, a foster, a pen move, a treatment, a care check — and whenever a Save button, a draft, a dirty
  flag, a submit or optimistic UI is being considered. Do NOT use for table and column definitions or for
  the controller that calls the verb.
```

```yaml
name: shed-drift-schema
description: >-
  The drift and SQLite schema rules for Shed Book — STRICT tables, a real foreign key with an explicit ON
  DELETE and a hand-written index for every one, CHECK conventions, the dual-key id strategy, instants
  stored as INTEGER UTC epoch millis and civil dates as TEXT, the provenance quad that any editable row
  must carry, the active-only partial unique index on tag, and the rule that no column may carry a DEFAULT
  which could encode veterinary advice. Use when adding or changing a table, column, index, view or named
  query, when deciding how a value is stored, and when reviewing anything under the db folder. Do NOT use
  to run codegen or write a migration step, which is the manual shed-codegen-and-migrations runbook.
```

```yaml
name: shed-domain
description: >-
  The pure-Dart domain rules for Shed Book — the domain folder imports no Flutter, no drift, no Riverpod,
  no intl and no clock, now is always a parameter and never a read, and the value types are Instant,
  LocalDate, PartialDate, Grams and MilliCelsius. Covers the time model and the UK ambiguous hour between
  01.00 and 01.59, RecordedTime provenance, unit canonicalisation and rounding, and every statistic with
  its edge cases and its verbatim definition string. Use when writing or changing any calculation,
  conversion, comparison, average, percentage, count or date arithmetic, and whenever a number shown to the
  shepherd is derived rather than typed. Do NOT use for withdrawal periods and clear dates, which have
  their own skill.
```

```yaml
name: shed-withdrawal
description: >-
  The highest-stakes arithmetic in Shed Book — a withdrawal period is never defaulted, never suggested,
  never pre-filled and never copied by repeat-last-treatment. The sealed WithdrawalPeriod type has one
  entry point taking the days as entered by the user, an absent row means not recorded rather than zero,
  and the clear date is the ceiling to the next local midnight of the administration instant plus N times
  24 hours, computed in absolute time and stored exactly once at write time because civil-day arithmetic
  loses an hour across British spring-forward. Use for anything touching medicines, doses, treatments,
  batch numbers, withdrawal days, clear dates, meat or milk safety, or the countdown that displays them.
  Do NOT use for general date arithmetic or for how the treatment screen is drawn.
```

```yaml
name: shed-safety-rules
description: >-
  The five Shed Book safety rules as structural mechanisms rather than reminders — never default a
  withdrawal period, never give veterinary advice, never present the app as a compliance record, never
  silently correct an entry, and keep timestamps honest by keeping both the effective and the captured
  time. Each rule names the mechanism that holds it and the level it sits at, from unrepresentable through
  unconstructible and unpersistable down to a test over the source text, and a rule that has dropped to
  merely documented has been deleted whatever the prose says. Use when writing copy or an ARB string,
  adding a disclaimer, adding any default value, adding validation, changing a stored value, or judging
  whether a change weakens one of the five. Do NOT use for the withdrawal clear-date algorithm itself.
```

```yaml
name: shed-screens-and-routing
description: >-
  What a Shed Book screen is made of and how it is reached — the one drift statement that feeds it, every
  state it must handle including empty, over-cap and not recorded, the tap budget it must meet, undo per
  verb, the end-of-day export prompt, plus the RouteNames entry and typed push helper, Navigator 1.0 with
  no go_router, no named-route strings and no state restoration. Use when adding, changing or navigating to
  any of the twelve screens, when wiring a route, a back behaviour or a sheet destination, and when
  deciding what belongs on a screen and what it costs the shepherd in taps. Do NOT use for how a screen is
  drawn, which the Indelible design skills own.
```

```yaml
name: shed-accessibility-and-copy
description: >-
  Everything a Shed Book widget says rather than shows — semantic labels, heading levels, the pen board and
  keypad and chart semantics, live regions, text scaling to 200 per cent, motor accessibility, and Apple's
  Accessibility Nutrition Labels as a ship gate — together with the ARB and gen-l10n setup in which every
  user-facing string lives with a description and every domain noun is a placeholder fed by the terminology
  provider. Also the en_GB date, number and unit formats and the rule that a human-facing date is never
  all-numeric. Use whenever adding or changing user-facing text, a label, a heading, a date or number
  format, or any interactive element. Do NOT use for colour contrast ratios, which the Indelible colour
  skill owns.
```

```yaml
name: shed-platform-gateways
description: >-
  The seven seams between Shed Book and the operating system — the gateway pattern and its hand-written
  fakes, notification reconcile with its channels, exact alarms, reboot and DST handling and its windowed
  projection, photo capture and downscaling, voice-note recording, the share sheet, file import, the
  wakelock, the store seam, and the per-plugin permission policy that keeps the Android manifest at exactly
  eight entries. Use when adding or changing a plugin, touching AndroidManifest.xml or Info.plist,
  scheduling or cancelling a reminder, capturing or picking media, sharing a file, or requesting any
  permission. Do NOT use for the contents of an exported file or for the release-time permission gate.
```

```yaml
name: shed-export-and-restore
description: >-
  Every route by which records leave or re-enter the phone — the hand-rolled RFC 4180 CSV writer and its
  three shapes, the PDF build with an embedded TTF in an isolate, the JSON backup envelope and its
  forward-compatibility rules, the safety-rule footers that every export carries, the media filesystem
  layout and its relative-path rule, orphan sweeps, and the atomic replace-everything restore that is never
  a merge. Use when writing or changing an export, a backup, an import, a restore, a round trip, or the way
  a photo or voice note is stored on disk. Do NOT use for the share-sheet plugin seam or for schema
  migrations.
```

```yaml
name: shed-monetization
description: >-
  The one non-consumable unlock and everything it touches — the entitlement row and its three rules, the
  purchase service seam, the purchase and restore flows, the free-tier policy object with a full season as
  the primary allowance and the ewe cap as a calm secondary gate, the four hard constraints on the upgrade
  affordance, and both stores' privacy declarations for an app that collects nothing. Use for any line that
  touches price, purchase, restore, entitlement, the cap, the upgrade row, or a store listing artefact. Do
  NOT use for the five shed screens, which render nothing monetization-related at any entitlement state and
  at any hour.
```

```yaml
name: shed-testing
description: >-
  How Shed Book is tested — the five tiers and why it is not a pyramid, fixed time in tests and the UK
  ambiguous hour, the in-memory drift harness, hand-written fakes rather than mocks for the seven gateways,
  the pumpApp harness, the 252-cell overflow matrix over fourteen pumpable variants, accessibility and tap
  targets and contrast as executable gates, the tap-budget and policy tests, tags and randomised ordering,
  fixtures, and what earns one of the eight goldens. Use when writing or changing any test, when adding a
  screen or variant the matrix must cover, when a test is flaky or time-dependent, and when deciding which
  tier a new assertion belongs in. Do NOT use to regenerate golden images, which is the manual
  shed-goldens-rebaseline runbook.
```

```yaml
name: shed-code-review
description: >-
  Reviews a Shed Book change the way the checklist prescribes — read the diff in order of irreversibility
  rather than in the order it prints, say nothing about anything CI already proves, and spend the whole
  review on what no gate can catch, starting with the five safety rules asked as questions and the one
  question about Quick Entry, which is whether the shepherd now has to do anything new before the record
  exists. Names the files that are never waved through however small. Use when reviewing a diff, a pull
  request or a proposed change, when asked whether something is ready to merge, and before claiming a piece
  of work is complete. Do NOT use as the authority on any individual rule — it routes to the owning skill
  rather than restating it.
```

```yaml
name: shed-codegen-and-migrations
description: >-
  Runs the Shed Book codegen and schema-migration ritual — make gen, drift_dev make-migrations and schema
  steps, the hand-written forward-only additive migration step, the regenerated snapshot and test helpers
  that must land in the same commit, and the extension of the from-to verifier matrix. This procedure
  rewrites generated files and creates a schema snapshot that is irreversible once committed, so it runs
  only when the developer asks for it by name.
disable-model-invocation: true
```

```yaml
name: shed-release
description: >-
  Cuts a Shed Book release — the offline gates G0 to G5 run against a real release bundle, the exact
  eight-entry permission set, signing and the off-machine symbols archive, size and startup budgets
  measured on two real devices, version name and build number rules, the closed test track, and the release
  freeze between 1 February and 30 April. This procedure builds, signs and tags, so it runs only when the
  developer asks for it by name.
disable-model-invocation: true
```

```yaml
name: shed-goldens-rebaseline
description: >-
  Re-baselines Shed Book's eight golden images — loads the real bundled fonts so nothing renders in Ahem,
  runs the tolerant comparator, regenerates with make goldens-update, inspects every changed image by eye,
  and lands the new PNGs as their own commit rather than bundled with the change that moved them. This
  overwrites committed reference images, so it runs only when the developer asks for it by name.
disable-model-invocation: true
```

### 3.2 Design

```yaml
name: indelible-design-system
description: >-
  The front door to Indelible, the one design system Shed Book has — the four rules that settle any visual
  disagreement, the law that serif means it happened and sans means it is a thing you can press, the list
  of what this system does not have including cards, corner radius in the record, shadows, elevation,
  icons, modals, tabs, spinners and empty-state illustrations, the motion and haptic vocabularies and the
  list of what must never animate, and a routing table naming the skill that owns each thing. Use before
  drawing or changing any pixel of this app — a screen, a widget, a colour, a size, a spacing, an
  animation, a haptic — and whenever a request would add a component, a state, a mark or a motion the
  system does not already have. Do NOT use for what data a screen shows or how it is wired.
```

```yaml
name: indelible-color-and-contrast
description: >-
  The entire Indelible palette — five surfaces and no sixth, three ink densities, one hue with three jobs
  and two densities, the red-shift variant, the two placement rules that fell out of measurement, and the
  requirement that every text pair reaches 4.5 to 1 and every rule and mark 3 to 1, recomputed against the
  shipped token block rather than eyeballed. Also the mapping from these values onto the token member names
  a widget is allowed to say, because a raw colour literal outside the primitives file is a build-breaking
  defect. Use when choosing or changing any colour, adding a token, checking a contrast ratio, working on
  the red-shift or high-contrast theme, or whenever a hex value is about to be typed. Do NOT use for which
  non-colour channels carry a status, which the marks and status skill owns.
```

```yaml
name: indelible-typography
description: >-
  The two voices and the whole type scale — a serif for the record and a sans for controls, both bundled
  rather than requested from the system, with the single documented exception that keypad digits are set in
  the record face so the shape you press is the shape that prints. Covers every size and line height from
  the season figure down to the stamp, the dark-mode weight policy that sets everything one step lighter,
  per-token tracking, tabular lining figures on every numeral in both faces, the right-aligned three-digit
  tag column, the absolute ban on italic and small caps, and behaviour at 200 per cent text scale. Use when
  setting or changing any text style, size, weight, tracking, casing or alignment, and when deciding
  whether an element is record or control. Do NOT use for the words themselves or their semantic labels.
```

```yaml
name: indelible-page-grid-and-rows
description: >-
  The page geometry of Indelible and the ruled row that fills it — the margin cell that is itself a tap
  target, the continuous madder spine that never breaks for a header or a sheet and never mirrors, the
  record column, the gutters, the ten-step spacing scale with no half steps, the standard 64px row and the
  88px tall row, the row sub-grid of tag and body and tally and trailing status, the sticky header band and
  the bottom band, and how every one of them grows at 200 per cent without the grid moving. Use when laying
  out any screen, list or row, when placing or sizing anything, when adding a row type, and whenever a
  padding, margin, gap, width or height number is about to be chosen. Do NOT use for a row's struck or
  queried state.
```

```yaml
name: indelible-targets-and-gestures
description: >-
  Every interactive element in this app is at least 64 by 64 with 8 to 12px of separation, the thumb band
  holds everything required to record an event, nothing more than 560px above the bottom edge is ever
  required to complete one, and the left-handed mirror moves the slab and the index button but never the
  spine. Also the complete gesture ban — no swipe action, no drag, no drag handle, no long-press binding,
  no pinch, no force touch, no hold-to-repeat and no slider anywhere — and the rule that a target never
  shrinks under a thumb. Use when adding anything tappable, deciding where a control sits, or when a
  gesture, swipe, drag, slider, long-press or hover behaviour is proposed. Do NOT use for how the target is
  painted.
```

```yaml
name: indelible-marks-and-status
description: >-
  How this app carries meaning without leaning on colour — the 2px rule that is never a hairline, the 3px
  strike weight, the doubled rule, the dotted rule that means a value was never entered, the six marks and
  their exact geometry and stroke rules, the boxed and unboxed stamp vocabulary that tells you whether a
  label is about the sheep or about the writing, and the table giving every state at least two non-colour
  channels so the screen reads identically in monochrome and under a red torch. Use when showing a status,
  warning, threshold, unset value, derived value or emphasis of any kind, and when drawing or adding any
  rule, mark, badge, dagger or stamp. Do NOT use for the strike workflow itself or for colour values.
```

```yaml
name: indelible-buttons
description: >-
  There are exactly two button forms in this app and this skill is the authority on both — the corner slab,
  the largest target in the product, with its per-page verb, its armed and pressed and disabled states and
  the rule that it never refuses a press, and the word button in its filled, in-stream, selected and
  destructive forms, plus the pinned index button that is the app's only navigation control. Use whenever
  an action, button, primary action, call to action, destructive action, floating action or tappable word
  is being added or changed, even when the request never uses the word button. Do NOT use for keys, rows,
  fields, steppers or choosers, and never introduce a third button form.
```

```yaml
name: indelible-input-and-sheet
description: >-
  Every way the shepherd puts a value into Shed Book — the keypad key and its record-face digits, the
  bottom sheet that is the only overlay in the entire app and has exactly three possible contents, the
  recents lines, the text field that is a ruled line rather than a box and never renders placeholder text
  inside itself, the number stepper that replaces every slider and never repeats on hold, the five-button
  ease group, and the check control that stamps the time you pressed it rather than storing a tick. Use
  when adding or changing any input, field, form, picker, chooser, keypad, sheet, toggle, checkbox or
  selection. Do NOT use for buttons that perform an action rather than capture a value.
```

```yaml
name: indelible-strike-and-query
description: >-
  Rule 1 of Indelible — nothing is ever removed from this app, only struck. Covers the strike line and the
  one animation in the product that has a direction, the struck stamp and its time, struck rows staying
  exactly where they were at full legibility in every list and every export forever, the query mark for a
  record that contradicts itself and its two-option chooser in which the app never picks, edited timestamps
  that print both the entered time and the corrected one, and the only two honest deletes in the product.
  Use whenever a delete, remove, undo, hide, clear, dismiss, archive, mute, correct or edit behaviour is
  being designed or implemented. Do NOT use for the geometry of the marks themselves.
```

```yaml
name: indelible-tallies-and-blocks
description: >-
  Every quantity in this app is drawn as blocks of ink rather than as a bar, ring, gauge, arc, pie or chart
  library — the lamb tally with its true five-bar gate, the birth type derived from the strokes and printed
  as counted so that nobody ever chooses triplet from a list, the struck stroke, the day tally on a
  withdrawal countdown, and the lambing spread as fourteen ruled rows at one block per birth with no axis,
  no gridline, no legend, no tooltip, no colour and no animation. Use when showing a count, a progress, a
  remaining time, a distribution, a chart or a graph, and when implementing the lamb counter or the birth
  type. Do NOT use for numeric typography or for the strike workflow.
```

```yaml
name: indelible-screen-composition
description: >-
  How the twelve Shed Book screens are composed — one scrolling ruled document under twelve different
  filters, with one spine, one header, one slab and one index button, so a new screen is a filter rather
  than a new layout. Includes the two screens with geometry of their own, tonight's page with its live row
  already drawn and welded above the bottom band before the shepherd touches anything, and the pen board as
  twelve ruled rows whose pen number, occupant and hours each form a straight vertical read. Use when
  building, restyling or reviewing a whole screen, when deciding what the page header says, and whenever a
  request proposes a grid of cards, tiles, chips, tabs, a rail or a navigation bar. Do NOT use for what
  data a screen shows.
```

---

## 4. The routing map

### 4.1 The two front doors

Both front doors carry the same three things: **the non-negotiables of their half**, **a routing table**,
and **the definition of done**. Neither is an authority on any single rule — each one names the skill that
is, which is the `internal-comms` dispatcher pattern (research 04 §2.3).

```
                    ┌──────────────────────┐        ┌────────────────────────────┐
   any code task ──▶│   shed-engineering   │        │  indelible-design-system   │◀── any pixel task
                    │  4 non-negotiables   │        │  4 rules · 2 voices        │
                    │  stack pins · gates  │        │  what we do not have       │
                    │  routing table       │        │  motion · haptics · route  │
                    └──────────┬───────────┘        └─────────────┬──────────────┘
                               │                                  │
        ┌──────────────────────┼───────────────┐     ┌────────────┼──────────────────┐
        │ structure            │ correctness   │     │ system     │ components        │
        │  shed-conventions    │  shed-domain  │     │  color     │  buttons          │
        │  shed-bootstrap...   │  shed-withdr. │     │  typography│  input-and-sheet  │
        │  shed-riverpod...    │  shed-safety  │     │  grid-rows │  marks-and-status │
        │  shed-write-path     │               │     │  targets   │  strike-and-query │
        │  shed-drift-schema   │               │     │            │  tallies-and-...  │
        ├──────────────────────┼───────────────┤     ├────────────┴──────────────────┤
        │ surface              │ workflow      │     │ composition                   │
        │  shed-screens-...    │  shed-testing │     │  indelible-screen-composition │
        │  shed-a11y-and-copy  │  shed-code-.. │     └───────────────────────────────┘
        │  shed-platform-...   │               │
        │  shed-export-...     │  runbooks ▸ codegen-and-migrations · release · goldens-rebaseline
        │  shed-monetization   │              (manual only — never auto-fire)
        └──────────────────────┴───────────────┘
```

**The one sentence that separates the halves, and it goes in both front doors verbatim:**

> If the change would be visible in a screenshot, the Indelible skills decide it. If it would be visible
> in a diff of a query, a row, a verb or a test, the engineering skills decide it. A new screen is both,
> and loading both is correct.

### 4.2 Intent → skill

The left column is what the developer actually types. This table is the acceptance test for the
descriptions in §3 — every row must resolve to exactly one skill, or to a stated pair.

| The developer says… | Skill |
|---|---|
| "add a feature", "where do I start", "what are the rules here" | `shed-engineering` |
| "where does this file go", "what do I call this", "can this import that", "what word do we use" | `shed-conventions` |
| "the app is slow to start", "there's a white flash", "handle this exception", "add logging" | `shed-bootstrap-and-errors` |
| "add a provider", "this widget needs data", "ref.watch", "the state resets when I navigate back" | `shed-riverpod-providers` |
| "save this", "add a Save button", "store the weight", "add undo", "make it a draft" | `shed-write-path` |
| "add a column", "new table", "how do I store a date", "add an index" | `shed-drift-schema` |
| "calculate the average", "convert kg to lb", "how many hours since", "the percentage is wrong" | `shed-domain` |
| "add a treatment", "withdrawal", "clear date", "read from the bottle", "repeat last dose" | `shed-withdrawal` |
| "add a default", "suggest a value", "warn the user", "add a disclaimer", "fix their entry" | `shed-safety-rules` |
| "add a screen", "navigate to", "what's on the ewe card", "add a back button" | `shed-screens-and-routing` **+** `indelible-screen-composition` |
| "add a label", "this string", "translate", "format the date", "screen reader" | `shed-accessibility-and-copy` |
| "add a plugin", "schedule a reminder", "take a photo", "share this", "ask for permission" | `shed-platform-gateways` |
| "export to CSV", "make a PDF", "back up", "restore", "where do photos live" | `shed-export-and-restore` |
| "the paywall", "unlock", "restore purchases", "free tier", "the cap" | `shed-monetization` |
| "write a test", "this test is flaky", "add to the matrix", "check accessibility" | `shed-testing` |
| "review this", "is this ready to merge", "check my diff" | `shed-code-review` |
| "run codegen", "make gen", "add a migration", "bump the schema version" | `shed-codegen-and-migrations` *(manual)* |
| "cut a release", "build the AAB", "sign", "check the permissions" | `shed-release` *(manual)* |
| "update the goldens", "the golden test fails after a Flutter bump" | `shed-goldens-rebaseline` *(manual)* |
| "make this look better", "restyle", "add an animation", "add a haptic", "add a component" | `indelible-design-system` |
| "what colour", "add a hex", "contrast", "dark mode", "red-shift", "night vision" | `indelible-color-and-contrast` |
| "font size", "make it bold", "which typeface", "the numbers don't line up", "200% text" | `indelible-typography` |
| "layout this screen", "padding", "spacing", "how tall is a row", "the list" | `indelible-page-grid-and-rows` |
| "make it tappable", "swipe to delete", "drag this", "long press", "a slider", "how big" | `indelible-targets-and-gestures` |
| "show a warning", "a badge", "a status", "an icon", "the value is empty", "highlight it" | `indelible-marks-and-status` |
| "add a button", "a CTA", "the primary action", "a FAB", "a destructive action" | `indelible-buttons` |
| "a text field", "a form", "a picker", "a checkbox", "a modal", "the keypad" | `indelible-input-and-sheet` |
| "delete this", "remove the row", "hide it", "mute", "let them fix a typo" | `indelible-strike-and-query` |
| "a chart", "a graph", "a progress bar", "count the lambs", "the birth type" | `indelible-tallies-and-blocks` |
| "build the pen board", "tonight's page", "a grid of cards", "a tab bar", "the header" | `indelible-screen-composition` |

---

## 5. The overlap audit

Fourteen pairs could plausibly both fire. For each, the distinguishing sentence below appears — from both
sides — in the two descriptions. Three pairs are *designed* to co-fire and are marked as such.

| # | Pair | What separates them |
|---|---|---|
| 1 | `shed-engineering` ↔ `indelible-design-system` | Screenshot or diff. Visible in a screenshot is design; visible in a diff of a query, row, verb or test is engineering. Each front door names the other by skill name. |
| 2 | `shed-screens-and-routing` ↔ `indelible-screen-composition` | **Co-fire by design.** One owns *what is on the screen and what it costs in taps* — the query, the states, the route entry. The other owns *how the page is composed* — spine, header, bands, filters. They never state a rule about the same object; adding a screen needs both and they do not conflict. |
| 3 | `indelible-buttons` ↔ `indelible-input-and-sheet` | Does it perform an action or capture a value. A slab and a word button act; a key, field, stepper, ease group and check control capture. The keypad key is an input even though it is pressed. |
| 4 | `indelible-buttons` ↔ `indelible-targets-and-gestures` | Rendering versus reach. Buttons owns fill, border, label, states. Targets owns minimum size, separation, which band it may live in, and which gestures may bind to it. Both fire when a button is added; neither contradicts the other. **Co-fire by design.** |
| 5 | `indelible-marks-and-status` ↔ `indelible-strike-and-query` | Geometry versus law. Marks owns *how a strike line, dagger or query mark is drawn* and the stamp vocabulary. Strike owns *when a row is struck or queried, what must persist, and what may never be erased*. The word STRUCK appears in both — marks gives its type and box, strike gives its placement and permanence. This is the highest-risk pair in the catalogue and both descriptions carry the reciprocal negative. |
| 6 | `indelible-marks-and-status` ↔ `indelible-color-and-contrast` | Channel versus value. Which channels carry a status, and how many are required, is marks. What the madder hex is and what it measures against a surface is colour. |
| 7 | `indelible-marks-and-status` ↔ `indelible-tallies-and-blocks` | The tally stroke is listed in the marks inventory and **specified** in tallies. Marks points at tallies for anything that counts; tallies never restates stroke weight or cap rules. |
| 8 | `indelible-page-grid-and-rows` ↔ `indelible-screen-composition` | One row versus the whole page. Grid-and-rows owns the row and the coordinates it sits on; composition owns which rows appear under which filter and the two screens with their own geometry. |
| 9 | `shed-conventions` ↔ `shed-engineering` | Names and imports versus the pipeline and the non-negotiables. The front door never states a name; conventions never states a workflow. |
| 10 | `shed-drift-schema` ↔ `shed-write-path` | Columns versus verbs. If it is a `CREATE TABLE` concern it is schema; if it is a method that mutates a row it is the write path. |
| 11 | `shed-drift-schema` ↔ `shed-codegen-and-migrations` | Define versus regenerate. Writing the table is the schema skill and auto-fires; running `make gen` and writing the migration step is the runbook and can only be invoked by name. |
| 12 | `shed-riverpod-providers` ↔ `shed-write-path` | Controller versus repository. The controller guards, validates and reports; the repository is the only thing that writes. The one rule they share — warnings are the controller's job and a repository cannot see them — is stated in both because it is a structural safety mechanism, and both statements are identical. |
| 13 | `shed-domain` ↔ `shed-withdrawal` | General arithmetic versus the one algorithm with a food-chain consequence. Domain's description explicitly excludes withdrawal; withdrawal's explicitly excludes general date arithmetic. |
| 14 | `shed-testing` ↔ `shed-goldens-rebaseline` | Writing an assertion versus overwriting a committed PNG. The runbook cannot auto-fire, so this pair cannot mis-resolve — the failure mode it prevents is an agent running `--update-goldens` to make a red test green. |
| 15 | `shed-accessibility-and-copy` ↔ `indelible-typography` | Words versus letterforms. The string, its ARB key, its semantic label and its format is copy. Its face, size, weight and tracking is typography. |
| 16 | `shed-safety-rules` ↔ `indelible-input-and-sheet` | The withdrawal-days field appears in both. Safety owns *why there is no default, no placeholder and no copy-forward*; input owns *how a field with no placeholder is drawn*. The field is the single clearest case in the product where a design rule and a safety rule are the same rule, and both skills say so and cross-name. |

**Two tests to run before committing the descriptions** (research 02 §1.7): for each pair above, write
three near-miss prompts that sit between them and confirm in a fresh session that the intended skill fires;
and disable each skill in turn via `skillOverrides` to confirm the work is measurably worse without it.
Near-misses, not obvious irrelevancies, are the whole game.

---

## 6. Build order

Authoring order is set by three facts. **A skill can only be distilled from a doc that is settled** — and
seven cross-document conflicts are not (§6.1). **The front doors must exist before the deep dives**, because
every deep dive ends by pointing back at one. And **descriptions are written last**, tuned against the
intent table in §4.2, because they are the only part that can be measured.

### 6.1 Phase 0 — settle these first, or the skills will encode a guess

Seven conflicts surfaced while sizing the catalogue. A skill that resolves any of them on its own authority
is worse than no skill, because it will look authoritative. Each needs a ruling in
[`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) or a numbered ruling in
`CONVENTIONS.md` §6 before the affected skill is written.

| # | Conflict | Blocks | Severity |
|---|---|---|---|
| P1 | **`struck` / `struck_at` on every table.** Indelible's Rule 1 means no row is ever deleted, every query decides whether struck rows count, and both CSV and PDF carry the columns. `03-data-model-and-schema.md` has no such columns. This is a **schema change and is irreversible after the first snapshot** | D9, E6, E13, E15 | **Blocking — must land before schema freeze** |
| P2 | **The 14px stamp versus the 18pt floor.** `indelible.md` §3.4 argues the exemption; `00-comparison.md` §2.2 shows three load-bearing stamps fail its own third test, and `06-design-system.md` §1 fixes the 18pt floor as something a direction may not change | D3, D6 | High — a safety rule is carried at 14px |
| P3 | **Token names.** `06` §1 fixes token *names* and lets a direction change *values*; Indelible ships a different naming scheme (`--page`, `--ink-full`, `--madder-rule`). One of the two must be restated in the other's vocabulary | D2, D6, all design | High |
| P4 | **The palette set.** `06` §4 and `CONVENTIONS` R35 define three palettes plus a high-contrast switch with stored keys; Indelible defines dark plus red-shift | D2, E14 (settings row) | High |
| P5 | **The typeface.** `06` §5 and the golden font loader in `12` §8.3 hard-code one family; Indelible requires two bundled families and its entire disambiguation rests on the pair | D3, E15, E18 (payload budget) | High |
| P6 | **Component class names.** `06` §12's inventory names components Indelible does not have (`ShedPenTile`, `ShedStatusBadge`) and lacks the ones it does (slab, word button, ruled row, spine, stamp, tally). New names need a `CONVENTIONS` ruling | D4, D6, D7, D8, D10 | Medium |
| P7 | **The two grafts** in `00-comparison.md` §4.1 — the live row pinned above the band rather than scrolling with the stream, and the 6px hours bar on pen rows. Adopted or not | D11, D10 | Medium |

Also carry forward, unresolved but already documented: the tap floor is 60 in `06` and 64 in Indelible —
compatible, since Indelible raises it, but the `tapMin` / `tapPrimary` / `tapHero` scale does not match
Indelible's 64 / 117×84 / 160×140 and one of the two must be restated.

### 6.2 Phases 1–7

| Phase | Build | Why here |
|---|---|---|
| **1** | `shed-engineering`, `indelible-design-system`, `shed-conventions` | Everything else ends with a link back to one of these. Writing them first also forces the routing table to exist before the skills it routes to, which is what stops overlap. |
| **2** | `shed-drift-schema`, `shed-domain`, `shed-withdrawal`, `shed-safety-rules` | The irreversible and the invisible-when-wrong, in the same order the app itself is built (`00-README` §9 steps 2–3). P1 must be settled before `shed-drift-schema` is written. |
| **3** | `indelible-color-and-contrast`, `indelible-typography`, `indelible-page-grid-and-rows`, `indelible-targets-and-gestures`, `indelible-marks-and-status` | The system layer. Every component skill quotes these, so they must be stable first. P2–P5 gate this phase. |
| **4** | `indelible-buttons`, `indelible-input-and-sheet`, `indelible-strike-and-query`, `indelible-tallies-and-blocks`, `indelible-screen-composition` | The components. Each is a thin skill over phase 3 plus one component's states table — cheap once phase 3 is right, and impossible before it. |
| **5** | `shed-bootstrap-and-errors`, `shed-riverpod-providers`, `shed-write-path`, `shed-screens-and-routing` | The machinery Quick Entry needs. Written in the order the app builds them so each can be tested against real code as it lands. |
| **6** | `shed-testing`, `shed-accessibility-and-copy`, `shed-code-review` | The three that only pay off once there is code to test, label and review. Accessibility and copy are authoring rules that run in parallel from day one, so this is the latest they can be written, not the earliest. |
| **7** | `shed-platform-gateways`, `shed-export-and-restore`, `shed-monetization`, then the three runbooks | Last because they are last in the build order, and because the runbooks encode procedures whose exact commands only exist once the `Makefile` and CI do. |

**Then, across the whole set, in this order:** rewrite every `description` against §4.2 · run the near-miss
trigger tests · run the baseline comparison for the five skills with the most to prove (`shed-withdrawal`,
`shed-write-path`, `indelible-strike-and-query`, `indelible-buttons`, `shed-drift-schema`) · wire
`tool/lint_skills.py` and the `.claude/.claude-plugin/plugin.json` lint shim from research 03 §5.4–§5.5 into
a pre-commit hook · run `/doctor` and read the Skills row in `/context`.

**Ongoing, forever:** *"when an agent makes a mistake you have to correct, add the correction to the gotchas
section."* The gotchas sections are the only part of this catalogue that should keep growing.

---

## 7. What is deliberately not a skill

### 7.1 Belongs in `CLAUDE.md`

| Content | Why not a skill |
|---|---|
| The pinned versions — Flutter 3.44.8, Dart 3.12.2, `flutter_riverpod` 2.6.1 exact, drift 2.34.2, the `build_runner` range | Facts needed in *every* session and in *every* answer, including one-line ones. A skill is consulted; `CLAUDE.md` is present. And research 02 §1.1 is explicit that simple one-step requests may never trigger a skill however good the description — a version fact must not depend on triggering. Keep under 200 lines. |
| The one-line product identity, the repo layout at top level, and the three commands (`make gen`, `make check`, `make test`) | Same reason. The front door repeats the commands as a definition of done; `CLAUDE.md` is what makes them available when no skill fires. |
| The absolutely banned words list | Short, universal, and needed on every string the agent writes. It is also a gate row, so it is enforced twice and remembered once. |

### 7.2 Belongs in a hook

| Content | Why not a skill |
|---|---|
| Running `dart format` and `dart run tool/check_policy.dart` after edits | *"Executes deterministically without Claude deciding"* (research 01). A rule that must fire on every edit must not depend on a model choosing to load a skill. The skills tell the agent what the gate proves; the hook makes it run. |
| Blocking a commit that edits `tool/policy_allowlist.txt` without a reason in the message | Mechanical, and exactly the kind of thing an agent rationalises past. |
| Linting the skills themselves (`tool/lint_skills.py --strict`) | Infrastructure, not knowledge. `claude plugin validate` alone does not check name/directory match, charset, length limits or dangling references (research 03 §5.1). |

### 7.3 Stays a document

| Content | Why not a skill |
|---|---|
| `00-tech-decisions.md` — the reasoning, the rejected alternatives, the corrections | Skills carry operative rules; the decision record carries *why*, and it is what you read when a skill surprises you. Distilling it would create a second authority that drifts. |
| The thirteen open questions and the four owner rulings | They change. A skill that names an open question goes stale silently; a doc that names it is read by a human who can see the date. |
| The twelve screen briefs verbatim, and every §-numbered rationale in `01`–`13` | Each skill links back to its source section. Copying the prose would double the maintenance and halve the trust, and research 04 P9 measured that skills teaching what the model can already infer crowd out the rules that matter. |
| `the-register.md` and `strip-bay.md` | Not selected. No skill may cite, mention or borrow from them — the point of a single design system is that the alternatives are not reachable. Their one adopted contribution is the two grafts in P7, which enter the catalogue through Indelible or not at all. |
| The four skill-authoring research notes | They govern how these thirty are written, not how the app is built. An agent building the app should never load them. |

### 7.4 Refused merges and splits — and why

| Considered | Verdict |
|---|---|
| A separate `shed-layers` skill for the eight dependency rules | **Refused.** "Where does this file go", "what is it called" and "may it import that" are one question family, and two skills would have fought over all three. `CONVENTIONS.md` §1.1 already owns the layer rules as amended, so `shed-conventions` owns them too. |
| Splitting `shed-testing` into unit / widget / golden | **Refused.** Research 02 §7.3 names this exact split as the wrong one — "write a test for this" hits all three and they share the harness. Golden *policy* lives in `shed-testing`; only the side-effecting *re-baseline* is separate, and only because it is destructive. |
| A separate `indelible-motion` skill | **Merged into the design front door.** "Ink appears, it does not travel", "numbers never animate" and the haptic vocabulary are laws of the system, not a component's properties — and a front door is where non-negotiables belong. It also means a request to add an animation cannot miss them. |
| Separate `indelible-chart` and `indelible-countdown` skills | **Merged into `indelible-tallies-and-blocks`.** In this system the chart bar, the day tally and the lamb tally are literally the same filled block; three skills would have described one thing three times and invited a fourth. |
| Separate `indelible-tonight-page` and `indelible-pen-board` skills | **Merged into `indelible-screen-composition`.** The system's central claim is that every screen is the same page under a filter; two screen skills would have implied otherwise, and the two exceptions fit in one body with a reference file. |
| A skill per component from `indelible.md` §7 — seventeen of them | **Refused.** Seventeen listings for one design system would have consumed the budget on its own, and several §7 entries (recents line, index sheet, page header) have no trigger vocabulary of their own — nobody types "add a recents line" without already being in the sheet. Grouped by *what the developer says*, seventeen components become five component skills. |

---

## 8. Status

| | |
|---|---|
| **Catalogue version** | 1.0 — 2026-07-27 |
| **Skills specified** | 30 — 19 engineering, 11 design. 27 auto-triggered, 3 manual-only runbooks |
| **Skills authored** | 0 |
| **Authored against** | `research/01`–`04` (2026-07-27), Claude Code v2.1.220, Agent Skills spec as of 2026-07-27 |
| **Design system** | `../design/indelible.md` v1.0 — the selected direction, and the only one any skill may cite |
| **Blocking before authoring** | P1 (`struck` columns — schema-irreversible). P2–P5 before any design skill in phase 3 |
| **Amendment rule** | Changing a skill's scope changes this catalogue in the same commit, including the routing table in §4.2 and the overlap audit in §5. A skill whose description no longer matches its row here is worse than a missing skill |
