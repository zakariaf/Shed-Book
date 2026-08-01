# N26 — Flock and Note Search

| | |
|---|---|
| **`00-README` §9 step** | 10 (1 of 4) |
| **Depends on** | N25 |
| **Size** | L |
| **Was** | E22 + E25, absorbed |
| **Branch** | `epic/n26-flock-and-note-search` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The daylight screen: find any animal, filter the flock by anything, add a ewe — and the
thirteenth route, full-text offline search across every note.

Two screens, one feature folder, one pull request. `flockListProvider` and `FlockRow` land the
one-statement read; five SQL filters land spec §7.7's *"filter the flock by anything"*; the 88 px ewe
row lands Indelible §7.4; `createEwe` gains its second call site with `EntryContext.calm`; and
`noteSearchProvider` lands the app's only FTS5 query and its only 200 ms debounce.

**Three rulings are made here and each amends a published document in the same commit.** They are not
optional and they are not deferrable — every one of them is a place where two authoritative documents
disagree about something this epic has to build:

| # | Task | The disagreement |
|---|---|---|
| **N1** | T02 | `07 §3.1`'s `under_withdrawal` predicate treats *"withdrawal not recorded"* as *"not under treatment"*, which is the one direction spec §12.1 does not permit |
| **N2** | T03 | `07 §3.1` selects `WHERE e.status = 'active'` — Indelible §7.4 keeps a struck ewe **in the list**, at the bottom, under a printed `STRUCK — 1` rule. Both cannot ship |
| **N3** | T04 | `07 §3.3` says the `duplicateActiveTag` warning *"never blocks the create"*; `03 §6`'s partial unique index makes a second **active** 412 unstorable. `00-README` §10 lists this as a **known open contradiction** and N14-T01 defers it here by name |

## Why the epic sits here

`00-README` §9 puts the calm screens at **step 10**, after reminders (step 9, N24 + N25) and before
monetization (step 11, N30). Its stated reason, not re-derived here:

> *"Off the 3am path, so they may be daylight work — but the Ewe Card summary line is the **retention
> feature**, the reason the product exists in year two. Do not treat it as filler."*

Four consequences bind this epic's scope:

- It comes **after** step 8 (N21–N23) because every assertion in it runs against
  `test/fixtures/flock_400_3seasons.json`, and that fixture does not exist until **N23-T05** writes it
  through the restore path. *"400 ewes filter to currently penned"* is not a claim you can make against
  six seeded rows, and `12 §5.2` splits the two seeding routes on exactly this line: helpers for
  *a shape*, fixtures for *shape at volume*.
- It comes **after** step 3's schema freeze (N07 + N08) because FTS5 has been sitting in the schema
  with zero real rows since **N07-T07**. `00-README` §9 step 3 puts it there deliberately — *"with FTS5
  present in v1 and zero real rows"* — so that `SchemaVerifier` meets the shadow tables in week one
  rather than at v4 with a shepherd's five seasons in the file. **N26-T05 is the first task in the
  project that puts a row in `search_docs` and reads it back.**
- It comes **after** N14, which landed `FlockRepository.createEwe` *already gated by* `FreeTierPolicy`
  (critique **S5**). This epic adds the verb's second call site and its second `EntryContext`; it does
  not add the gate, and it must not re-implement it.
- It comes **before** N27 (Ewe Card), and that ordering costs this epic something real: **there is no
  Ewe Card to navigate to.** `Routes.eweCard` does not exist until N27-T01. Tapping a flock row here
  writes the `ewe_touches` row (decision #68) and nothing else; a note-search hit whose subject is a
  ewe renders and does not navigate. Both are stated in the code, beside the call site, naming N27.

`00-README` §9's two parallel tracks are load-bearing in this epic rather than incidental: the **ARB**
gains three note-search strings and two flock empty strings, each authored in the task that renders it,
and the **accessibility** track gains the `headingLevel: 1` on both screens plus `spellOutTag` on every
node that speaks a tag. N33 only *verifies*.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/flock_test.dart
fvm flutter test test/features/note_search_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/data/flock_repository_test.dart
fvm flutter test test/data/note_repository_test.dart
make check
make test
```

- **400 ewes render and filter in one drift statement.** `restoreFixture(db, 'flock_400_3seasons.json')`,
  tap *IN THE PENS*, and the list narrows — with **one** `customSelect` behind it and an explicit
  `readsFrom:`. `combineLatest` appears nowhere; the fan-in is in SQL.
- **All five spec §7.7 filters work against the 400-ewe fixture** — barren, not yet lambed,
  triplet-bearing, currently penned, under treatment — each asserted with a count read off the fixture,
  never a literal.
- **A ewe treated with no recorded withdrawal appears under *UNDER TREATMENT*, and her row says
  `WITHDRAWAL — NOT RECORDED`, not a clear date and not silence.** That is ruling N1, and it is the one
  place in this epic where a wrong answer is a food-chain answer.
- **Type `watery` and every note that ever said it comes back, offline, in under a second** — against
  the 400-ewe fixture, `bm25()`-ordered, with a `snippet()` excerpt showing the word in context. The
  test asserts the elapsed budget with `fakeAsync`, never a wall clock (`12 §11.6`).
- **The debounce is 200 ms and it is proved to exist**: five keystrokes inside 200 ms issue **one**
  statement, counted off the database, not inspected by eye.
- **`noteSearchProvider` disposes with its last listener.** Pop the screen and the family instance is
  gone; a `ProviderContainer` listener count of zero is asserted, not assumed.
- **A ewe whose lambing contradicts its lamb count carries a `?` in the margin cell and a word** —
  never colour alone, never colour at all. `lambing_consistency` recomputes on read; there is no
  `warning_count` column and there never will be (decision #54).
- **Add a ewe from the flock bottom slab creates a row through the same `createEwe` verb Quick Entry
  uses**, with `EntryContext.calm` — and past the cap in daylight it returns
  `WriteRefused(RefusalReason.eweCap)` and **no row is inserted**. At 22:30 the same tap returns
  `Allow(overFreeCap: true)` and creates the row, permanently, and that is not a bug (`11 §7.4`).
- **`kPumpableVariants` reaches eleven entries** — the nine that were there (`quick_entry`,
  `lambing_entry`, `lamb_card`, `foster`, `pen_board`, `treatments`, `export`,
  `quick_entry.export_banner`, `reminders`) plus this epic's `flock` and `note_search` — taking the
  matrix from 162 cells to **198**. The count is still arithmetic over the variant list, never a
  remembered number (R58); it reaches 252 over fourteen variants at N33-T01, with `ewe_card` (N27),
  `season_summary` (N28) and `settings` (N29) still to come.
- **`routes.dart` gains exactly two push helpers**, `Routes.flock` and `Routes.noteSearch`, and no
  `onGenerateRoute`, no `routes:` map, no `pushNamed`.

What is deliberately **not** demonstrable yet: **tapping a flock row goes nowhere.** It writes
`ewe_touches` and stops, because `EweCardScreen` is N27-T01. The static over-cap upgrade row that
`07 §3.2` pins to the top of this screen is **N30-T05's**, not this epic's — `showCapRow` exists here
only as N14-T04's signature with its two no-op guards. And the *"navigates to Unlock"* half of
`07 §3.3` cannot land: Unlock is a **Settings section**, not one of the thirteen `RouteNames`, and
Settings is N29.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §1.1–§1.5 (the index, the one-query rule, tap counting, the state vocabulary, the §12 disclosure matrix) · §1.7 (headings) · §2.2 (the empty-state table — **the three note-search strings, verbatim**) · **§3.1–§3.4 (Screen 1 — Flock: the query, the six states, the actions, §12.4 on this screen)** · **§18 (Search — two problems, two surfaces)** · §19.1–§19.4 (the cap surfaces, and the seven screens that have none) · §20 (primary actions in the bottom third) | the two screen briefs: what renders, in what order, in which state |
| `docs/design/indelible.md` | §2.7 (status without colour — the contradiction, struck and withdrawal rows) · §3.4–§3.5 (the scale; **the fixed three-character right-aligned tag column**) · §4.1–§4.5 (spacing, geometry, the grid, **row heights**, the three reach bands) · §6.2 (the six marks — the dagger, the query mark, the strike line) · **§7.4 (the ewe row, all four states)** · §7.7 (the stamp: boxed = the animal, unboxed = the writing) · §7.12 (the text field — no placeholder, ever) · §7.13 (the word button, and the selected-filter underline) · §7.14 (the bottom sheet) · §7.16 (the page header) · **§8 Screen 1** (the filter line, the trailing state words, `+ EWE`) | every value: size, ink, rule weight, target, band, mark |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 4, 5, 6, 7, 8 · §2.9 (enums that mirror stored keys) · §2.10 (**`EntryContext { liveEntry, calm }`**) · §2.13 (`createEwe`, `setStatus`) · §2.14 · **§3.2 (`flockListProvider` and `noteSearchProvider`, their files and their dispose policy)** · §3.4 (`flockControllerProvider`, `flockWriteControllerProvider`, `noteSearchControllerProvider`) · §4.1–§4.6 · §5 · **R18, R19, R26, R27, R33, R41, R42, R53, R57, R58, R59, R60, R69** | **BINDING** on every path, type, provider, key, column and word |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes`, `tag`, `tag_digits`, the active-only partial unique index) · §5.3 (`EweSeasons` — the seven stored keys, `scanned_count`) · §5.4 (the `lambing_consistency` **view**) · §5.8 (`Treatments` + `TreatmentWithdrawals`; **no row for a target means NotRecorded**) · §5.13 (`ewe_summaries` stores **counts only**) · §5.14 (who writes what) · **§6 (tag uniqueness — settled)** · **§9.1 (`rankTagMatches`) and §9.2 (FTS5, the fan-in table, the triggers, the two spelling traps, the two week-one prototypes)** | the tables both screens read and every trap in the search index |
| `docs/engineering/02-state-di-navigation.md` | §4.1 (which shape for which job) · **§4.2 (auto-dispose: `flockListProvider` keepAlive, per-query families autoDispose)** · §4.3 (`watch`/`read`/`listen`) · §4.4 (`.select` and the collection trap) · §4.5 (reading an `AsyncValue`) · §7 (the double-tap-safe write controller) · §8.1 (`RouteNames`, the push helpers, the count) · **§10.3 rule 8 (exactly two debounces exist in `lib/`: 200 ms note search, 400 ms free text)** | the provider shapes, the rebuild scope, the dispose policy and the debounce budget |
| `docs/engineering/05-domain-correctness.md` | the `WithdrawalStatus` triple (`ClearsOn` / `NoWithdrawal` / `WithdrawalUnknown`) and `computeWithdrawalStatus` · `LocalDate.of(Instant)` · `rankTagMatches`'s contract | why *not recorded* is a third answer and not a false |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60 / `tapPrimary` 72 / `tapHero` 88 / `gapMin` 16) · §6.2 (`ShedTapTarget`) · §7 (the gesture ban — **the filter line scrolls horizontally and drag is banned**) · §12 (`ShedAnimalRow`, `ShedStatusBadge`, `ShedEmptyState`, `ShedBanner`, `ShedKeypad`) | the Flutter-side contract for every control this epic composes |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (the eight label rules) · **§3.3 (`spellOutTag` — the tag range only)** · §3.4 (Flock gets `headingLevel: 1` and **no** level 2; note search the same) · §4.4 (`FittedBox` is banned around user-facing text) · §5.2 (the redundancy table) · §8.4 (ARB conventions) · §8.5 (the terminology-placeholder rule) · §9.1–§9.2 (one formatting authority; **no all-numeric human date**) | what both screens say rather than show, and every string's home |
| `docs/engineering/12-testing.md` | §2.3 (the ambiguous hour 01:00–01:59) · §3.1–§3.3 (the drift harness, the host `sqlite3` floor, repository tests) · §5.1–§5.3 (`pumpApp`, the two seeding routes, the closed `test/support/` list) · **§6.1–§6.4 (the fourteen variants, the matrix, the failure protocol, reachability)** · §11.5 (**the two committed fixtures — do not add a third**) · §11.6 (flakiness: no `Future.delayed`, no wall clock) | the harness this epic extends and the two variants it adds |
| `docs/engineering/11-monetization-and-store.md` | §7.3–§7.4 (the two gated verbs; the 22:00–06:00 degrade, and *"do not fix it"*) · §8.1 (`over_free_cap` is not a warning) | what the cap may say on this screen, and what it may never do |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12 (drift `watch()`, no `combineLatest`) · #35 (in-memory tag ranking **and** FTS5 for notes — two problems, two mechanisms) · #47 (SQL-side time is banned) · #50 (the stored `clear_date`) · #54 (a warning cannot be persisted) · #58 (never `?? 0` on a nullable aggregate) · #68 (`ewe_touches`) · #71 (never a spinner) · #90/#91/#92 (nothing monetization-related on a shed screen; the live-entry rule; two static rows, never a modal) · #99 · #114 (superseded by R58) · §7.0 rulings **3** (en_GB, kg, 24h, ambiguous hour 01:00–01:59, AHDB), **7** (tags unique among ACTIVE animals only) and **8** (season-primary, ewe cap secondary) | Flutter **3.44.8** / Dart **3.12.2** · `flutter_riverpod` **2.6.1** exactly · `drift` **2.34.2** / `drift_dev` **2.34.5** / `sqlite3` **3.5.0** |
| `CLAUDE.md` | the 3am test floor · **P2** (there is no SnackBar) · the five safety rules, present rather than consulted · the banned words · the authority order | the floor, and the owner ruling that supersedes `CONVENTIONS §2.11` |
| `epics/00-PLAN-CRITIQUE.md` | **§3 "Too small to be worth a PR"** (E25 absorbed into E22 → N26) · **S3** (the matrix's fixture) · S5 (`createEwe` gated from its first commit) · §4 *"delete the closer task"* · §10 (the rules of the corrected plan) · §11.3 (this epic's two named anchors) · §11.4 (the skills) | why this is one pull request and why T07 is one line rather than a closer |
| `shed-book-spec.md` | **§7.7** (*"full-text offline search across every note, tag and treatment"*; *"filter the flock by anything: barren, not yet lambed, triplet-bearing, currently penned, under treatment"*) · §5 (the 3am test) · §12 (the five safety rules) | the product claim this epic exists to hold |

## Why this is one pull request

`CONVENTIONS §3.2` puts `noteSearchProvider` in `lib/features/flock/note_search_controller.dart`
— the **same feature folder**. Both screens read tables `FlockRepository` and `NoteRepository` already
own, both are reached from the same app bar, and layer rule 6 would forbid a separate `search/` feature
from importing anything the flock built. A separate pull request for one debounced route buys nothing
and costs a full pipeline wait. Critique §3, *"too small to be worth a PR"*.

## Tasks

Strictly sequential: each task depends on the one before it. The statement must exist before it can be
filtered, the filters before the row can render their trailing words, the row before a create can join
the list, and the matrix cannot pump a screen that has not been built.

| Task | Depends on | One line |
|---|---|---|
| [N26-T01](N26-T01-flocklistprovider-and-flockrow-one-statement.md) | N25-T06 | `flockListProvider` and `FlockRow` — one statement |
| [N26-T02](N26-T02-the-five-filters-and-a-filtered-empty-state-of-its-own.md) | N26-T01 | The five filters and a filtered-empty state of its own — **ruling N1** |
| [N26-T03](N26-T03-the-88-px-ewe-row-the-124-warning-badge-and-the-culled-tag-m.md) | N26-T02 | The 88 px ewe row, the §12.4 warning badge and the culled-tag marker — **ruling N2** |
| [N26-T04](N26-T04-add-a-ewe-from-the-bottom-bar-through-the-same-gated-verb.md) | N26-T03 | Add a ewe from the bottom bar, through the same gated verb — **ruling N3** |
| [N26-T05](N26-T05-notesearchprovider-fts5-with-a-200-ms-debounce.md) | N26-T04 | `noteSearchProvider` — FTS5 with a 200 ms debounce |
| [N26-T06](N26-T06-searchhit-rendering-navigation-and-the-three-distinct-empty.md) | N26-T05 | `SearchHit` rendering, navigation, and the three distinct empty strings |
| [N26-T07](N26-T07-two-matrix-variants-flock-and-note-search.md) | N26-T06 | Two matrix variants — `flock` and `note_search` |

Three ordering wrinkles, all deliberate:

- **T01 creates `flock_controller.dart` and the read verb on `FlockRepository`; T02 adds the filter
  arguments to both.** `FlockFilter` and its state live with the controller from T01 so the statement is
  written once with the filter parameters already in its signature — retrofitting a `WHERE` into a
  shipped `customSelect` is how a second statement gets born.
- **T04 lands `setStatus` and `EweStatus`**, which N14-T01 explicitly left for this epic
  (*"`setStatus` is N26's"*). The struck-row rendering that consumes it is T03's, so T03 asserts against
  a fixture ewe whose `status` is already `'culled'` and T04 makes it reachable from the UI.
- **T05 is the first FTS5 read in the project.** `03 §9.2` carries **two unverified week-one
  prototypes** — drift#3322's analyser gap and `SchemaVerifier` versus the FTS5 shadow tables. Both were
  meant to be settled at N07; if either is still open when this branch is cut, T05 records which
  fallback shipped, **here and in doc 04**, in the same commit.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N25 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n26-flock-and-note-search
```

**2 — One commit per task, seven commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Four commits in this epic carry an extra obligation, and each is an application of `00-README` §10's
amendment rule — *the decision record and every document that applies it change in the same change*:

- **T02** amends `07 §3.1`'s `under_withdrawal` predicate (ruling **N1**).
- **T03** amends either `07 §3.1`'s `WHERE e.status = 'active'` or `indelible.md` §7.4's struck state —
  whichever loses ruling **N2**.
- **T04** amends `07 §3.3` (ruling **N3**) and closes the row `00-README` §10 carries under *"known open
  contradictions"*. **That row is deleted in the same commit**; a doc set that still advertises a
  contradiction someone resolved is worse than one that never named it.
- **T01, T04, T05 and T06 each add a name `CONVENTIONS` does not yet carry** — `FlockRow`,
  `FlockFilter`, `EweStatus`, `SearchHit` — and each adds its row to `CONVENTIONS §2.9`/`§2.14` in its
  own commit. A name that two files use and the naming authority does not carry is how a second spelling
  gets born (precedent: N13-T03's `DeckEntry`).

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:
`docs/` (the three ruling amendments and the `CONVENTIONS` rows) → `lib/data/flock_repository.dart` and
`lib/data/note_repository.dart` → `lib/domain/ewe_status.dart` → `lib/l10n/app_en.arb` →
`lib/routing/routes.dart` → `lib/features/flock/` → `test/`.

`lib/l10n/app_en.arb` is **never waved through**. This branch authors the copy a shepherd reads when the
app has nothing to show them, and `07 §2.2` is explicit about why three note-search strings are three
and not one: *"a shepherd who sees the wrong one concludes the app lost their notes."*

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Two of the five land here and both answers are long:

- **§12.4** — this is the epic's headline disclosure. `07 §1.5` gives Flock a row badge and nothing
  else; T03 implements it as Indelible's `?` margin mark **plus a word**, never colour alone. State
  ruling **N3** in the body: `duplicateActiveTag` is produced by the **controller** (R53) as the tag is
  typed and is never persisted — *there is no `warnings` column* (decision #54).
- **§12.1** — the *"as entered by you"* provenance does not appear on a flock row, and `07 §1.5`'s
  matrix says so. But ruling **N1** is a §12.1 question wearing a filter's clothes: state in the body
  that a ewe with an unrecorded withdrawal is shown as **unknown**, never as clear, and name the test
  that holds it.

The other three (**§12.2** copy discipline, **§12.3** the not-a-regulatory-record footer, **§12.5** time
provenance) do not reach this epic — say so, and say why: a flock row shows a count and a state word,
never an event time; the note-search hit shows a date, which is `formatters.dart`'s `d MMM y` and
carries its `provenanceLabel` from `RecordedTime` (T06).

**5 — Wait for the pipelines.** Three jobs block this PR and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The layer rules where they are easiest to break. `layer.features` proves `lib/features/flock/` imports no `package:drift` and no `lib/core/db/` — which is what forces both statements onto repositories rather than into the controller `CONVENTIONS §3.2` names. `layer.single_writer` proves no `customStatement(` escaped `lib/core/db/`, which matters here because T05 is the first task tempted to hand-write an FTS5 `INSERT`. The gesture rows prove the horizontally scrolling filter line is a `ListView`, not a `Dismissible` or a `Draggable`. `ui.spinner` proves nothing under `lib/features/` renders a `CircularProgressIndicator` while the debounce is pending — the single most likely regression in T05. `copy.currency_literal` proves the cap row copy never printed a price |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | Mostly a **negative**, and it is the important one. N26 adds no table and no column: `drift_schemas/` must not move. A schema snapshot in this diff means somebody added a `warning_count`, an `is_under_treatment` boolean or a second FTS index to make a query easier — all three are irreversible after N07's freeze and the first two are banned outright by decision #54. The one legitimate movement is `database.g.dart`, if T05 edits `lib/core/db/search.drift`; that regeneration must be **in the commit** |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | Two widget files, two repository files, one policy file and **36** new matrix cells (2 variants × 3 devices × 3 text scales × 2 bold states). The `uk-zone` leg is load-bearing in three tasks: T02's day-boundary comparison, T03's `STRUCK 12 MAR` margin date and T06's hit date all only exercise the ambiguous **01:00–01:59** hour when tagged and run under `TZ=Europe/London`. Randomised ordering matters more than usual because T05's provider is `.autoDispose.family` with a `Timer` behind it: a test that leaks a listener makes the *next* test's statement count wrong, which reads as a debounce failure and is not one |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. **Nothing in this
epic should move it.** No native file is touched, no permission is added, no plugin is wrapped. If the
G4 merger report changes on this branch, stop and find out why before merging.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, because the
macOS runner bills at a 10× multiplier. The eight images are N33-T07.

**6 — Merge, delete the branch, and only then cut N27.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n27-ewe-card
```

N27 hangs `eweTimelineProvider`, the retention summary line and `Routes.eweCard` off exactly the
repository, the row widget and the `ewe_touches` write this epic ships — and it is the epic that makes
this one's dead row taps live. Cutting it from anything other than a green merged `main` means the Ewe
Card is rebased onto a moving flock row.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The three rulings, N1, N2 and N3.** Each deletes or rewrites a paragraph in a published document.
  `00-README` §10: *"A doc set where document 07 applies decision #29 and document 03 no longer does is
  worse than no doc set, because both look authoritative."* If a ruling cannot be made on this epic's
  authority, **carry it into the PR body as open, with both sides cited** — never silently resolve it,
  and never implement around it.
- **Every widget key spelled in T02, T03, T04 and T06.** `CONVENTIONS §4.5`: *"a key is a test
  contract, so renaming one is a breaking change to `test/features/`."* `flock.filter.currently_penned`,
  `flock.row.412`, `flock.add_ewe`, `note_search.field`, `note_search.hit.0` are read by T07's two
  variants, by all four of N33's sweeps and by the four integration journeys. Spell them once.
- **Every ARB key and message authored in T02, T03, T04 and T06.** `10 §8.4` rule 2: the `description`
  carries the rationale, *"and when a future contributor 'improves' it, the description is what tells
  them why they must not."* The three note-search strings are `07 §2.2`'s words, and the reason they are
  three is written into their descriptions.
- **The `EweStatus` member names (T04).** They are byte-identical to `ewes.status`'s CHECK
  (`active`, `sold`, `dead`, `culled`) and go straight into `setStatus`. A stored enum key is
  *"`snake_case`, ASCII, frozen forever"* (`CONVENTIONS §4.6`).
- **Whichever FTS5 fallback T05 records.** `03 §9.2` names Fallback A (hide the special INSERTs from
  drift's analyser) and Fallback B (drop `content='search_docs'`). B changes what the index **stores**.
  Record which one shipped, here and in doc 04, in the commit that makes the choice.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`,
`lib/core/db/tables/**`, `lib/core/db/migrations.dart`, `android/`, `ios/`. **If a file under any of
those shows up in this branch, stop and find out why.** Two read screens store nothing new. The single
permitted exception is `lib/core/db/search.drift` if T05 has to move a statement — and that one moves
`database.g.dart` with it, in the same commit.

**Risks specific to N26:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **A trigger-written table is invisible to drift's stream invalidation** | `search_docs` and `search_fts` are written by **SQL triggers only** (`03 §5.14`). drift's `watch()` re-emits on writes it issued through its own API; it never saw the trigger fire. So a search stream keyed on `search_fts` can sit open while a note is added and never re-emit — the whole feature, silently one keystroke stale | T05 makes it an assertion, not an assumption: *open the stream, `addNote`, expect a second emission*. If it fails, the read moves to a `customSelect` whose `readsFrom:` names the five **source** tables (`notes`, `ewes`, `lambs`, `lambings`, `treatments`), with the reason in the file |
| **`:today` is captured when the statement is built and never advances** | `07 §3.1` binds `:today` in Dart from `appNow()` because SQL-side time is banned (decision #47). A phone left on the Flock screen across midnight then filters *under treatment* against yesterday. Watching `minuteTickProvider` from `flockListProvider` is the obvious fix and is **wrong**: the provider is keepAlive (`02 §4.2`) and would pin an `autoDispose` ticker for the life of the app | Ruling **N1**'s other half. The statement emits clock-free columns — the latest `clear_date` and whether any withdrawal is unrecorded — and Dart compares them to today. `05`'s `computeWithdrawalStatus` is the comparison, `now` is a parameter (R24), and the **widget** watches `minuteTickProvider.select((t) => LocalDate.of(t))` so the ticker dies with the screen |
| **`under_withdrawal` treats *not recorded* as *not under treatment*** | `07 §3.1`'s predicate is `w.kind = 'days' AND w.clear_date >= :today`. `03 §5.8`: *"NO ROW for a target means NotRecorded."* So a ewe injected yesterday with no withdrawal typed is absent from the *under treatment* filter — the app answering a withdrawal question the user never answered, which is the exact shape §12.1 forbids | Ruling **N1**. The filter admits `ClearsOn` **and** `WithdrawalUnknown`, and the row prints which. `test/policy/` gains the property assertion, not `test/features/` (`CONVENTIONS §4.1`: a policy test states the property, not the file) |
| **`07 §3.1` erases culled ewes; Indelible §7.4 keeps them** | `WHERE e.status = 'active'` against *"She stays in the list, at the bottom, under a printed line reading `STRUCK — 1`."* And this epic's own DoD line — *a culled tag is visibly distinct from an active one with the same number* — is **unsatisfiable** if the culled row is not rendered, which is itself the strongest argument on Indelible's side | Ruling **N2**, in T03, with the losing document amended in the same commit. Whichever way it goes, `03 §6`'s partial unique index is untouched: uniqueness is on `tag` among `status = 'active'` and stays there |
| **`duplicateActiveTag` has no producer, or has one that cannot fire** | `05 §2.6` declares eleven `WarningCode` members. `07 §3.3` says the flock create raises `duplicateActiveTag` and *"never blocks the create"*; `03 §6` makes a second active 412 physically unstorable. One of the two is dead code and `00-README` §10 says out loud it is a domain question | Ruling **N3**, in T04. Whatever the ruling, `WriteFailed` must be the outcome if the index ever does fire — `shedFailureFrom` (N11-T02) unwraps the `DriftRemoteException` and maps it; a bare `on SqliteException` clause **never matches** on drift's background isolate (`04 §4.6`) |
| **A family keyed on `String` instantiates one provider per keystroke** | `CONVENTIONS §3.2` declares `noteSearchProvider` as `.autoDispose.family<List<SearchHit>, String>`. Typing `watery` is six distinct family arguments, six provider instances and six drift subscriptions. Putting the debounce *inside* the provider does not help — it debounces the SQL, not the instantiation | T05 puts the timer in `noteSearchControllerProvider` (`CONVENTIONS §3.4`), holds the raw text in a **private field** (`02 §4.4`: *"anything the user typed lives in a private field on the notifier"*) and publishes only the settled query. One family instance per settled query, and the previous one autoDisposes |
| **A note containing `OR` is an FTS5 operator** | `03 §9.2`: *"never build FTS5 syntax by string concatenation without tokenising first, because a note containing the word `OR` is an FTS5 operator and throws a syntax error at 3am."* And `"` , `*`, `NEAR` and `^` do the same | T05 tokenises, quotes each token, and prefix-matches the last one. Its test set carries a case per operator, plus the apostrophe case that a naive `replaceAll("'", "''")` gets wrong |
| **FTS5 has no fuzzy matching and `spellfix1` is not in the bundled build** | `03 §9.2`: `watry` returns **zero rows**. A shepherd with cold fingers types `watry` and concludes the app lost their notes | The mitigations in `03 §9.2`'s stated order — prefix-match the last token, porter stemming, and a bounded Dart-side pass over `search_docs.body`. **Do not add a second trigram index for typos** |
| **The filter line scrolls horizontally, and drag is banned** | `07 §3.3` puts the filter chips *"in a horizontally scrolling row"*; `CLAUDE.md` bans drag and drag handles; Indelible §8 Screen 1 makes it *"a single horizontally scrolling 64px ruled line of words with counts printed after them"*. The gate has **no row** that catches `ListView(scrollDirection: Axis.horizontal)` | T02 states it and cites both. `06 §7`'s one permitted tracked gesture is vertical scrolling, with the mitigation that *"no action is ever reachable only behind a scroll"* — so `ALL` is always visible and every filter is also reachable from the index sheet |
| **`ewe_summaries` may be stale or absent** | `03 §5.13` makes it a **cache**, rebuilt by `LambingRepository`. `07 §3.1` uses a `LEFT JOIN`, so a ewe with no summary row yields NULLs — and decision #58 bans `?? 0` on a nullable aggregate | T01 renders *"no seasons recorded"* rather than *"0 seasons"*, and the 400-ewe fixture's assertions read counts off the fixture. The rebuild-on-write is **N27-T03**, not this epic |
| **`spellOutTag` is applied to the wrong range** | `10 §3.3`: the `SpellOutStringAttribute` covers the **tag only**, never the term. On a flock row the sentence is *"gimmer 412 · 3 seasons · avg 2.0"* — an off-by-one spells out half of it and *"nobody notices without a device"* | T03 uses `attributedLabel:`, never `label:`, and its test set carries the four cases `10 §3.3` names, including a tag that is also a substring of the term |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] **rulings N1, N2 and N3 are each closed by an amendment to the losing document in the same commit, or carried into the PR body as open with both sides cited** — never silently resolved
- [ ] `00-README` §10's *"known open contradictions"* row about `07 §3.3` versus `03 §6` is **deleted** in T04's commit
- [ ] `flockListProvider` is **one** `customSelect` with an explicit `readsFrom:`; `combineLatest` appears nowhere in `lib/`
- [ ] no file under `lib/features/` imports `package:drift`, `package:sqlite3` or `lib/core/db/`
- [ ] exactly **two** debounces exist in `lib/`: 200 ms on note search, 400 ms on free-text fields (`02 §10.3` rule 8)
- [ ] `noteSearchProvider` is `.autoDispose.family` and is proved to dispose with its last listener
- [ ] `rankTagMatches` has **one** implementation, in `lib/domain/tag_match.dart` (R27); the flock search box calls it and does not reimplement it
- [ ] no FTS5 syntax is built by string concatenation without tokenising first
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `lib/core/db/migrations.dart`, `android/` or `ios/`
- [ ] no `warning_count`, no `is_under_treatment`, no persisted warning of any kind (decision #54)
- [ ] `EntryContext.deliberate` appears nowhere — the two members are `liveEntry` and `calm` (R69)
- [ ] `FlockRow`, `FlockFilter`, `EweStatus` and `SearchHit` each have a row in `CONVENTIONS` §2.9 or §2.14
- [ ] `routes.dart` gains exactly two push helpers, `Routes.flock` and `Routes.noteSearch`; no `onGenerateRoute`, no `routes:` map, no `pushNamed`
- [ ] `kPumpableVariants` gains exactly two entries — reaching eleven, 198 cells — and the count stays derived from the variant list (R58)
- [ ] the harness ledger's `ewe_card` line is corrected from N26 to **N27** (N13-T07 planted it wrong)
- [ ] every user-facing string authored in this branch is in `app_en.arb` with a `description`; no domain noun appears literally in a message (`10 §8.5`)
- [ ] every interactive element has a `semanticLabel` and a `flock.` or `note_search.` key, all `lower_snake` (R59)
- [ ] both screens carry a `headingLevel: 1` and neither carries a `headingLevel: 2` (`10 §3.4`)
- [ ] nothing in `lib/features/flock/` watches `entitlementProvider` or `purchaseServiceProvider` outside T04's single cap call site (decision #90)
- [ ] no human-facing date in this diff is all-numeric (R60)
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

400 ewes filter to *currently penned* in daylight, at 11am, in the yard — and typing `watery`
returns every note that ever said it, offline, in under a second.

## Notes

**`EntryContext.deliberate` does not exist.** `CONVENTIONS` R69 and §2.10 declare
`enum EntryContext { liveEntry, calm }`, `07 §3.3` spells the flock create `EntryContext.calm`, and
N14-T01's own test names use `calm`. The N26-T04 anchor test's name has been corrected to `calm`; the
anchor itself — the file, the reason it is red, and the `BlockedByCap` assertion — is unchanged. A test
naming a member that does not exist does not compile, so this is a correction to the assertion, not a
weakening of it.

**Note search's three empty strings are not *"query too short"*.** `07 §2.2` and `07 §18` agree on the
three, and they are: **no query yet** → *"Type to search notes."*; **no notes exist at all** → *"No
notes recorded yet."*; **query with no match** → *"No notes match 'watery'."* with a `Clear` action on
the third only. There is no length threshold on this screen — the length problem belongs to the
**keypad** path, where FTS5 is banned outright and `rankTagMatches` handles two-character queries
(`03 §9.1`, decision #35). T06 carries the corrected wording.

**This epic does not build the over-cap row.** `07 §3.2` pins a static
`Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>` row to the top of
the Flock screen, and `06 §12` makes `ShedBanner` the only monetization component that exists. Both are
**N30-T05's**. What lands here is T04's single `showCapRow(context, reason)` call site — N14-T04's
signature, with its two no-op guards intact — so that when N30-T05 gives the function a body, the flock
create is already routed through it. `<store price>` is never a literal (`copy.currency_literal`).
