# C4 — Completeness critique

**Lens:** what would a developer still not know on day one?
**Reviewed:** all ten notes in `docs/research/raw/` (≈14,000 lines) against `shed-book-spec.md`.
**Date:** 2026-07-27

---

## Summary of coverage

What the ten notes cover very well, so the writing phase does not re-litigate it:

- Persistence (16 tables, FKs, triggers, FTS5, migrations, media, WAL/`synchronous`, `VACUUM INTO`) — 03 is the strongest document in the set.
- The five §12 safety rules as type-level mechanisms — 09 discharges all five.
- Offline provability (manifest gates, dependency allowlist, tree-shake audit) — 01 §12, 06 §11, 07 §1, 08 §7.
- The 3am interaction physics: 60pt targets, dark-first theming, red-shift, no-white-flash, typography, keypad layout — 05.
- Monetization + store compliance + the free-tier cap policy — 07.
- Accessibility and i18n groundwork — 10.
- Statistics maths with four legitimate lambing-percentage definitions — 09 Part 4.
- Diagnostics/crash logging without a network — 08 §7. **Field debugging in a barn is answered** (Diagnostics screen + shareable redacted log); do not list it as a gap.

The gaps below are the things a developer hits in week one and cannot resolve from these notes.

---

## Findings

### 1. BLOCKER — three mutually contradictory `main()` implementations

`main.dart` is the first file you write and the notes give three incompatible versions:

| Note | `main()` body |
|---|---|
| 01 §13.1 | `void main()` with **no** `WidgetsFlutterBinding.ensureInitialized()`; constructs `AppDatabase` synchronously; `ProviderScope(retry:…, overrides:[databaseProvider.overrideWithValue(db)])` |
| 02 §4.1 | `Future<void> main() async`; `ensureInitialized()`; **`await openShedBookDatabase()`** and **`await LocalNotificationGateway.initialize()`** before `runApp`; four overrides |
| 08 §1.3 | `ensureInitialized()`; `Diagnostics.installSync(binding)`; `runApp(const ProviderScope(child: ShedBookApp()))` — **no overrides at all**, DB opened later from a post-frame `FutureProvider` |

08 §1.3's "Forbidden in `main()`" list explicitly bans exactly what 02 §4.1 does. And 08's `ref.read(databaseProvider.future)` implies `databaseProvider` is a `FutureProvider`, while 01 and 02 both make it a `Provider<AppDatabase>` overridden with a value — a third, incompatible DI shape that changes every repository's construction site.

01's premise is also shaky: it argues against calling `ensureInitialized()` because doing so "tears the native splash down early", but `runApp()` calls `WidgetsFlutterBinding.ensureInitialized()` internally regardless — verified at <https://api.flutter.dev/flutter/widgets/runApp.html> ("Initializes the binding using WidgetsFlutterBinding if necessary"). Omitting the explicit call moves binding init by microseconds, it does not avoid it.

**Sketch of the answer.** Adopt 08's shape, which is the only one that satisfies both "no white flash" and "no error-less black screen": `ensureInitialized()` → install sync error handlers → `runApp` with a `ProviderScope` whose `databaseProvider` is a `FutureProvider` opened on the first post-frame callback → the Quick Entry shell paints at frame 1 with a fixed-height placeholder where recents will land. Keep 01's `retry: (_, __) => null` (it is right, and 08 omits it). Delete 02 §4.1's awaiting variant and its `openShedBookDatabase()` snippet. Write the resulting ~20 lines once, in the architecture doc, and have every other doc link to it rather than re-print a variant.

---

### 2. BLOCKER — first-run bootstrap is undefined: no Season and no Pens exist

Every event table in 03 has `season INTEGER NOT NULL REFERENCES seasons(id)` — `Lambings`, `EweSeasons`, `Treatments`, `Reminders`, `PenOccupancies`, `FosterEvents`, `Notes`. `AppSettings.currentSeason` is **nullable**. So on the very first launch there is no season, and the first tap on the keypad path cannot insert a lambing. No note says who creates the first `Season` row, when, with what `year` / `label` / `startDate`, or what Quick Entry renders while `currentSeason IS NULL`. Spec §5 forbids an onboarding wizard, so "ask the user to set up a season first" is not available either — and §7.1 says "never block an entry to make the user go and set something up first."

The same hole exists for `Pens`. Screen 7 is a grid of pens; `Pens(label, sortOrder, isActive)` is entirely user-authored; nothing in ten documents describes pen creation, a default pen count, labelling, or what the Pen Board shows on a device with zero pens. The Pen Board is the feature spec §7.4 calls "a feature paper genuinely cannot match".

**Sketch of the answer.** On first open of the database (in the migration's `onCreate`, not in UI code), insert one `Season` derived from the device clock — `year = now.year`, `label = "<year> lambing"`, `startDate = today` — and set `AppSettings.currentSeason` to it in the same transaction. It is renameable in Settings and re-datable; nothing is asked of the user. Pens are created lazily and implicitly: the first time a ewe is penned from the Ewe Card, the app offers pens `1…n` and creates the row on tap, so the board fills as the shed fills. The zero-pen board shows a single 72pt "Add a pen" tile rather than an empty grid, and the Settings screen gets a "Pens" sub-screen for bulk labelling in daylight. Write this as a §"First run" section owned by the persistence or architecture doc; it is a schema decision, not a UI decision.

---

### 3. BLOCKER — four of the twelve screens have no design at all

Coverage is very uneven across spec §9:

| Screen | State of guidance |
|---|---|
| 3 Quick Entry | Excellent (05 §9, §11; 08 §1.4; 02 §7) |
| 7 Pen Board | Good (05 §12; 10 §3.4; 03 §4.7) — but see finding 2 |
| 4 Lambing Entry | Good on writes/consistency (01 §8, 09) — but see finding 4 |
| 1 Flock, 2 Ewe Card | Adequate (08 §4.3, 09 §8) |
| 5 Lamb Card, 6 Foster | Data model excellent (03 §4.6); UI thin |
| 8 Treatments | Data + safety excellent (03 §4.8, 09 §1.1); UI thin |
| **9 Reminders** | **Two incidental sentences in 12,000 lines** |
| **10 Season Summary** | Maths (09) + chart semantics (10) but no rendering decision — see finding 16 |
| **11 Export** | Formats decided (06 §6) but no screen |
| **12 Settings** | **Effectively nothing** |

Reminders is the worst. Spec §9.9 asks for "due today, overdue, upcoming"; nothing describes the grouping, how a reminder is completed or muted (`Reminders.completedAt`, `muted` exist in 03 but no interaction does), or — most importantly — how the in-app list reconciles with the OS. 06 §1.4 caps iOS at 56 scheduled notifications out of a possible 312, so the OS list and the app list *deliberately disagree*, and the only guidance is one line of suggested copy. That reconciliation (which 56? re-scheduled when? on which lifecycle event?) is a screen's worth of design.

Settings owns six spec-mandated groups (§7.10: units, terminology, reminder intervals, season start/switching, theme, delete season / delete everything) plus Diagnostics (08 §7.7) plus the unlock row (07 §3.3) plus pens (finding 2) plus restore-from-backup (06 §7) — roughly ten sections, zero design.

**Sketch of the answer.** Give each of the four a short screen brief in the design doc: purpose, the one query that feeds it (per 01 §6.3 Rule A), the list of states including empty, the actions and their tap costs, and which §12 disclosures appear. For Reminders specifically, settle the OS-reconciliation rule first: keep the DB as the truth, re-project the next N to the OS on every `AppLifecycleState.resumed` and after every write that creates or completes a reminder, and show the honest "showing the next 56 on your lock screen; all 312 are in the app" line 06 already drafted.

---

### 4. HIGH — spec §7.2's "care checkboxes" are absent from the data model

Spec §7.2 requires: *"Care checkboxes: colostrum given (with volume/method), navel dipped, stomach tubed, warmed."* 03 defines sixteen tables and none of them stores this. Searching all ten notes, "colostrum" appears only as (a) a value in `Reminders.kind`, (b) a notification channel id in 06 §1.6, and (c) an example in 09 §1.2 of a phrase that would be advice. "Stomach tubed" and "warmed" appear only in prose. There is no column, no table, and no decision on the per-lamb vs per-lambing question (colostrum volume and "warmed" are per-lamb facts; the spec lists them under the Lambing Entry screen).

The knock-on is real: the colostrum reminder (§7.6) has nothing to be marked complete *from*, so the reminder and the fact can never be linked; and 08 §2.3's "continue this in-flight lambing" resume path has no care state to resume.

**Sketch of the answer.** Add a `CareEvents` table keyed to `lamb` (nullable) and `lambing` (nullable) with the same `CHECK ((a IS NOT NULL) + (b IS NOT NULL) = 1)` idiom 03 already uses for `Treatments`: `kind TEXT CHECK (kind IN ('colostrum','navel_dip','stomach_tube','warmed'))`, `occurredAt`/`capturedAt`/`timeSource` (the §12.5 triple, since a care event is exactly as deferrable as a lambing), `volumeMl INTEGER NULL`, `method TEXT NULL` ('teat','tube','bottle'), `note`. Checkbox state on the Lambing Entry screen is then `EXISTS(...)`, not a boolean column — which keeps 01 §14's "store what was observed" rule and makes "colostrum given at 03:22" recoverable. Completing the colostrum reminder writes the `CareEvent`; it is the same tap.

---

### 5. HIGH — spec §7.7's ewe traits have nowhere to live: mothering ability, prolapse, mastitis

Spec §7.7 requires the Ewe Card to show *"litter size, ease score, losses, mothering ability, prolapse, mastitis, and any note ever written about her"*, and the one-line summary example is *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025."* 09 §8 tells you to **precompute that summary line** into an `ewe_summary` row. But nothing in any note says where "prolapsed 2025" comes from. `Ewes` has only `notes TEXT`; `EweSeasons` has `status` (to_ram/scanned/lambed/barren/aborted/died/sold) and `notes`. Litter size, ease and losses are derivable; mothering, prolapse and mastitis are not derivable from anything that exists.

This is a fork with consequences: if they are free text, the summary line is not computable and the §7.7 filters ("filter the flock by anything") cannot include them; if they are structured, at least one table is missing and the Lambing Entry screen needs the taps to record them.

**Sketch of the answer.** Reuse the `CareEvents` shape from finding 4 or add a sibling `EweObservations(ewe, season, kind, occurredAt, note)` with an editable vocabulary — `prolapse`, `mastitis`, `poor_mothering`, `good_mothering`, `no_milk`, `other` — seeded from the §11 authored list and user-extensible, exactly like death causes. Structured, because the retention feature (§1: "what did 412 do last year?") is the product's whole reason to exist and a free-text-only answer means grep, not recall. Feed `ewe_summary` from it. Note the §12.2 boundary explicitly in the table's doc comment: the app records *what the shepherd observed*, and must never infer "poor mothering" from a lamb death.

---

### 6. HIGH — the ~40 authored terms (spec §11) were never written, and the one sourced list conflicts with the spec

Spec §11 says the only shipped data is *"roughly 40 authored terms — lambing ease scale descriptions, common death causes, common malpresentations, common treatment routes — all generic husbandry vocabulary **written from scratch**"*, under a heading that reads **"None that is licensed."**

Actual state across the corpus: 5 lambing-ease descriptions (09 §1.2), 8 death causes (copied from the spec itself), **0 malpresentations**, and **0 treatment routes** — 03 §4.8 shows only a trailing-ellipsis code comment, `// 'sc','im','oral','topical','intranasal',…`. That is ~13 of ~40, and the two lists that would need actual husbandry authorship are the two that do not exist. 10 §11.2 correctly routes them into ARB but has nothing to route.

Worse, 09 §1.2 says of the ease scale: *"Adopt them verbatim"* from SRUC TN747. Verbatim adoption of a levy-body technical note is the opposite of "written from scratch" and puts pressure on "None that is licensed." I fetched the cited PDF (<https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf>) — it resolves and is a real SRUC document, but it is image-based and the fetch returned no extractable body text, so **I could not verify the quoted 1–5 scale or any licence terms on it.** Treat the quotation as unverified.

**Sketch of the answer.** Make the 40 terms a named deliverable with an owner, in one file (`assets/content/terms.md` → ARB), and write them rather than copy them. Paraphrase the ease scale in the app's own words at the same semantic granularity (the *concept* of a 1–5 assistance scale is not ownable; the sentences are). Author the missing lists: malpresentations (head back, leg back, one leg back, both legs back, breech, backwards, twins together, ringwomb, other) and routes (subcutaneous, intramuscular, oral/drench, topical/pour-on, intranasal, intravenous, intraperitoneal, other) — both plainly descriptive vocabulary with no dose, no indication, no advice. Add a provenance line per list stating it was authored, and add the "no verbatim third-party copy in `assets/content/`" check to the §12.2 content-policy CI script 09 §1.2 already builds.

---

### 7. MEDIUM — no git hygiene: nothing says what is committed vs ignored

Not one document states the repository conventions, and this is unusually load-bearing here because several gates depend on committed generated artifacts:

- `pubspec.lock` — 01 §16 and 06 §11.6 gate CI on its contents, and 02 §8.10 warns `flutter pub upgrade` can break the build silently. It must be committed; nobody says so.
- `drift_schemas/*.json` — 04 §3.5 calls migration tests "the highest-value tests in the project" and they cannot run without the committed snapshots.
- `*.g.dart` / `database.steps.dart` — commit or regenerate? (Affects CI time and whether `build_runner` runs on every clone.)
- `lib/l10n/` generated output — 10 line 790 is the **only** VCS statement in 14,000 lines ("commit it").
- Golden PNGs — 04 §7.4 says goldens are OS- and version-sensitive. Which runner is canonical, are they committed, and how does a developer on macOS regenerate without a spurious diff?
- `docs/perf/measurements.md` — 08 decision #14 requires hand-measured numbers be committed per release.

Also absent: branch model, commit conventions, whether a CHANGELOG exists, and what the release tag looks like against 07 §6.1's version/build scheme.

**Sketch of the answer.** One short section: start from Flutter's default `.gitignore`, then explicitly **commit** `pubspec.lock`, `drift_schemas/`, `lib/l10n/`, all `*.g.dart`, `test/goldens/`, `analysis_options.yaml`, `dart_test.yaml`, `docs/`; **ignore** `build/`, `.dart_tool/`, `*.iml`, `ios/Pods/`, `coverage/`, `*.jks` and any signing material (07 §6.3). Name Linux-CI as the golden-canonical runner with `flutter test --update-goldens` run there only, and add a `tool/` script that fails a PR touching goldens without a matching runner tag. Trunk-based with short branches; tag `v<version>+<build>`.

---

### 8. MEDIUM — no naming conventions and no end-to-end "how a feature gets added"

01 §3.4 gives a folder tree with sample filenames but never states the rules. Unanswered on day one: file naming; the `_screen`/`_controller` suffix contract (and whether it is `_controller` per 01 or `Vm`/`_vm_provider` per 02 §4.2 — the two documents use different names for the same object); provider naming; test-file naming; and widget `Key` naming, where the corpus already disagrees with itself — 01 §8.4 uses `Key('birthType.twin')` while 04 §10.1 uses `Key('birth_type.twin')` for the same widget. Keys are load-bearing here because 04's whole tap-budget gate finds widgets by key.

Nor does anything describe the *sequence* to add a feature. With eight enforced layer rules (01 §11), a design-token gate (05 §3.3), an offline gate (06 §11.6), an l10n gate (10 §12.1), schema snapshots (04 §3.5) and a golden set, the order is not guessable.

**Sketch of the answer.** A one-page "Adding a feature" recipe: table + `CHECK`s → bump `schemaVersion` → `drift_dev schema dump` + `generate` (the exact three commands 04 §3.5 lists) → migration test → repository verb method returning `WriteOutcome` → provider in `data/providers.dart` → controller → screen → `Routes.` helper → ARB strings with descriptions → widget test with keyed finders → golden if it is one of the ~8 → run `check_layers`, `check_tokens`, `check_offline`. Plus a conventions table: `snake_case.dart` files, `<feature>_screen.dart` / `<feature>_controller.dart`, providers `<name>Provider`, keys `dotted.lower_snake` (pick one and fix 01 §8.4), tests mirroring `lib/` under `test/`.

---

### 9. MEDIUM — no consolidated code review checklist, which spec §12 explicitly asks for

Spec §12 opens: *"These are non-negotiable and should be visible in the code review checklist."* No file produces that checklist. Items are scattered and would have to be assembled by reading all ten documents: the 400 ms debounce ceiling (01 §8.3 — which says "state that number in the code review checklist"), ban `combineLatest` over drift streams (01 pitfall 1), ban `FittedBox` around user-facing text (10 §14 — "ban in code review"), ban `Tooltip` and `Dismissible`/`Draggable` (05 §3.3), no raw colour literals (05 §3.1), no `DateTime.now()` outside the injected clock (01 §16), the ten caveats at 10 §3.7, and the §12 rules themselves.

**Sketch of the answer.** One `docs/code-review-checklist.md` (and a PR template pointing at it) with two sections: **"CI already proves this"** (layer rules, tokens, offline gate, tap targets, l10n) so reviewers do not waste attention, and **"a human must check this"** — the five §12 rules restated as questions, plus the bans above. Cross-link each item to the note section that argued it, so the checklist stays short and the reasoning stays findable.

---

### 10. MEDIUM — no seed/demo data strategy, despite four topics depending on one

08 §4.3 requires profiling "with a full 400-ewe database" on a physical device in profile mode; 04 §5.3's overflow matrix, §7.5's golden set and §10's policy tests all need populated state; 07 §3 needs a flock sitting exactly at the 15-ewe cap; and the §7.7 recall feature needs a *multi-season* history, which by definition does not exist yet for anyone. Nothing says how any of that data comes into being, where the generator lives, how it is kept out of release builds, or whether there is a shareable JSON backup fixture (06 §6.3 defines the backup format — that is the obvious vehicle).

**Sketch of the answer.** A `tool/seed.dart` that writes a deterministic database from a committed JSON backup fixture, invoked as `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42`, plus two committed fixtures: `test/fixtures/flock_400_3seasons.json` and `flock_15_at_cap.json`. Deterministic (fixed seed, fixed clock via `package:clock`) so goldens and stats tests are reproducible. Route it through the *same* restore path as 06 §6.3's user-facing JSON import — that way the seed script doubles as a continuous test of restore, which is the one code path where a bug loses five seasons. Guard it with `assert()` + a `--dart-define` so it cannot run in release.

---

### 11. MEDIUM — empty states are undefined for every screen

The only empty-adjacent guidance in the corpus is 08 §1.4's fixed-height dark placeholder — and that is about the *loading* frame, not about a shepherd who genuinely has no ewes, no pens, no treatments and no reminders. Every one of the 12 screens has a zero-data rendering and none is specified. It interacts directly with spec §5's "no onboarding after first run": the empty states *are* the onboarding, and they are the only place the app is allowed to teach anything.

**Sketch of the answer.** A table in the design doc: one row per screen, the empty copy, and the single action it offers. Rules: never a spinner, never an illustration, never a multi-step tour; the empty state occupies the same box the content will occupy so nothing shifts; the action is the same 60pt control the populated screen uses. Quick Entry is the exception that proves the rule — it is never empty, because the keypad is usable at frame 1 with no data.

---

### 12. MEDIUM — undo is asserted as a core affordance but never specified

05 §10.3 makes a persistent SnackBar with `UNDO` the *replacement* for the banned swipe-to-delete, and 05 line 1452 leans on it to satisfy §12.4. The code is `onPressed: () => repo.undo(id)`. `undo(` appears exactly once in 14,000 lines — that call site. No repository in 01 or 03 defines it, and it cannot be generic:

- Undoing `beginLambing` is a `DELETE` — but 01 §8.2 says an abandoned entry is a *true statement* that must not be garbage-collected. Which is it?
- Undoing a foster cannot be a delete: 03 makes `FosterEvents` an append-only log and `birth_dam` immutable by trigger, so undo must write a compensating event — and a compensating event is visible history, which is right, but then "undo" is a misleading label.
- Undoing a treatment affects a record that may already have been printed into a medicine book (§7.5).
- Undoing a delete of a season is impossible after `ON DELETE CASCADE`.

Nor is it said how long undo remains available, whether it survives a route pop or a backgrounding, or whether it survives process death (it cannot — 02 §6.2 — so the SnackBar is lying if the app is killed).

**Sketch of the answer.** Do not build a generic `undo`. Define it per verb, in the repository, with an explicit list: `beginLambing` → hard delete, allowed only while zero child rows and only within the SnackBar's lifetime; `addLamb` → hard delete; `foster` → compensating `FosterEvent` labelled "corrected", visible in history; `treatment` → soft-void with a `voided_at` column so the medicine book can show the void rather than lose the row; season deletion → no undo, guarded by the only `canPop: false` flow in the app (02 §5.4). State the window (until the SnackBar is dismissed or the route pops, whichever is first) and state plainly that undo does not survive process death.

---

### 13. MEDIUM — the end-of-day export prompt's mechanics are split across three files and incomplete

Spec §7.9: *"A gentle end-of-day prompt to export, at most once per day, dismissible for the season."* Three notes each own a fragment: 03 §4.11 stores `exportPromptDismissedForSeason`; 06 §1.5 defaults an "end-of-day export nudge" to a 20:00 local **notification**; 08 §5.4 says the prompt "opens the screen; it does not start work." Nobody joins them, and the unanswered questions are the ones that decide whether it works:

- Notification or in-app banner or both? If it is a notification, it needs `POST_NOTIFICATIONS` — which 06 §9 deliberately defers to "the first time the user creates a reminder." A user who never creates a reminder therefore never gets the backup nudge, which is the one prompt the spec calls a *safety* feature.
- Is it suppressed when nothing was written that day? (Prompting after a quiet day is the definition of a nag, and §5 bans nags.)
- Is it suppressed if the user already exported today?
- What is "once per day" keyed on — there is no `lastExportPromptedAt` column anywhere in 03 §4.11, only the season-level dismissal flag.
- Which timezone's calendar day, given 09 §3 stores instants in UTC and derives civil dates separately?

**Sketch of the answer.** Make it an in-app banner on next launch, not a notification — it then needs no permission, cannot fire while the shepherd is in the shed, and honours §5. Add `lastExportedAt` and `lastExportPromptedAt` (both instants) to `AppSettings`. Show the banner at the top of Quick Entry on the first launch of a *local civil day* (09's denormalised `local_date` rule) when: writes occurred since `lastExportedAt`, `lastExportPromptedAt` is not today, and `exportPromptDismissedForSeason != currentSeason`. Two 60pt actions: "Export now" (pushes screen 11) and "Not this season" (writes the dismissal). It never appears mid-entry and never blocks.

---

### 14. MEDIUM — two of the four §15 success criteria have no proposed measurement

Criterion 2 (median unlock→save under 15 s) is well handled: 04 §10.1 decomposes it into a blocking tap budget plus a nightly device trace, and 08 §10.4 adds a local rolling median in Diagnostics. Criterion 3 ("more than half of entries within five minutes of the event") is handled by 09 §1.5 — the `capturedAt`/`occurredAt` pair makes it locally computable, and 09 says so explicitly.

Criteria **1** ("a shepherd uses it on night two, and night eleven") and **4** ("at least one user opens a ewe's previous-season history during their second season") have no proposed measurement anywhere. Unlike 2 and 3, these are cross-user retention facts and a local, never-transmitted Diagnostics screen structurally cannot produce them. No note connects them to 07 §6.4's twelve-tester recruitment, which is the only human-contact mechanism the project has.

**Sketch of the answer.** Say out loud that 1 and 4 are **not instrumentable** under §4.5 and §5, and are therefore qualitative acceptance criteria, not metrics. Bind them to the beta cohort: 07 §6.4 already requires 12 testers for 14 days for Play's closed-testing rule, and 07 notes that recruitment doubles as the §17.1 field research. Add a third job: a two-question post-season note to those testers ("which nights did you use it?", "did you look up a ewe's last year?"). Also add a *local, opt-in* line to the Diagnostics screen — "You have recorded on 9 nights this season" and "You have opened 14 previous-season histories" — which costs nothing, transmits nothing, and gives a tester something concrete to paste into a forum reply.

---

### 15. LOW — the free-tier cap's enforcement location is answered four times, three different ways

01 §18 says a `data/`-layer guard on `FlockRepository.createEwe`. 02 §11.4 says the write path, "the ViewModel command". 03 open question 4 says **"UI only"**, and explicitly argues against the data layer. 07 §3.2 says "not in widgets — one policy object consulted by the repository", with an `EntryContext` enum and a sealed `CapDecision`. 07 is by far the deepest treatment and is right, but a developer reading 01→03 in order implements the wrong thing twice before reaching it.

**Sketch of the answer.** Promote 07 §3.2 to the single answer, and edit the other three to defer to it. Note the reconciliation explicitly, because 03's objection is good and 07 already answers it: the cap is *not* a schema `CHECK` (03's real concern — a `CHECK` would fire on a paying user mid-lambing), it is a policy object the repository consults, with the calling context as an explicit parameter so that `EntryContext.liveEntry` can never be blocked.

---

### 16. LOW — the season-summary chart has no rendering decision

Spec §7.8 requires "a simple bar chart of births per day". 09 Part 4 supplies the bucketing and maths; 10 §3.6 supplies per-bar semantics for a class it calls `SpreadChartPainter`; 08 mentions "one bar chart" in passing. No note evaluates a charting package against hand-rolled `CustomPainter`. `fl_chart`, `syncfusion_flutter_charts` and `graphic` appear **zero** times in 14,000 lines — so this was never considered, not considered and rejected. That matters because 06 §10's dependency allowlist and offline gate would have to rule on any chart package's transitive graph, and because 10's semantics design silently pre-commits the decision to `CustomPainter` without saying so.

**Sketch of the answer.** Decide for hand-rolled `CustomPainter` and *say why*: one chart, no interaction, no animation, fixed dark palette, an existing accessibility design in 10 §3.6 that assumes `semanticsBuilder`, plus a hard requirement that nothing enters `pubspec.yaml` without passing the offline allowlist. Roughly 120 lines. Add a line to the rejected-alternatives table in 06 or 08 naming `fl_chart` so the next reader sees it was weighed. Golden-test the chart at three data shapes (one day, a tight 18-day spread, a 60-day straggle).

---

### 17. LOW — the "in the pens" list in Quick Entry has one line of coverage

Spec §7.1 lists three parallel affordances on the hardest screen in the app: the keypad, the recents strip, and *"'In the pens' list — animals currently in individual pens, shown first."* The keypad gets ~120 lines (05 §9) and the recents strip gets a real schema decision (01 §10.5: `ewe_touches` is an observation, not derivable). "In the pens" gets one substantive sentence in the whole corpus — 09 line 1871, *"Recents and 'in the pens' are the same in-memory list, sorted differently."* That is a claim, not a design: it does not say the ordering (entry time? pen label? hours-since descending?), whether penned lambs appear alongside their dam, how it relates to the Pen Board's own single-statement query (01 §6.3), or how it degrades at frame 1 before the DB is open (08 §1.4 says only two of the three affordances need the database, without saying which).

**Sketch of the answer.** Define it as the same `PenOccupancies WHERE turnedOutAt IS NULL` projection the Pen Board already watches, ordered by `enteredAt` ascending (the ewe penned longest is the one most likely to need turning out and is the one you are most likely to be standing next to), ewes only — lambs are reachable from the dam in one tap. It shares the Pen Board's query, so it costs one extra `select`, not one extra table. At frame 1 it renders the same fixed-height dark placeholder as the recents strip.

---

## Also worth the writing phase's attention

- **Screens 5 (Lamb Card), 6 (Foster) and 8 (Treatments)** have excellent data models and safety analysis but almost no interaction design. §7.3 calls the foster flow "the flow most likely to be abandoned if it takes five taps" and §7.5 requires a repeat-last-treatment shortcut for batches — both are tap-budget claims, and neither has the tap-budget test that 04 §10.1 built for the lambing path. Extending that test to `foster` and `repeat treatment` is cheap and would turn two prose claims into gates.
- **Restore is under-designed relative to its stakes.** 06 §7 picks `file_selector`, 03 §10.6 covers media-after-restore, 03 §1676 decides JSON is records-only — but no note describes the restore *screen*, what happens to existing data (merge? replace? refuse?), or the confirmation. It is the single most destructive operation in the app and the only recovery path that exists.
