# N29-T06 — The only two honest deletes in the app

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 6 of 8 |
| **Depends on** | N29-T05 |
| **Commit** | one commit · `feat(settings): the two honest deletes` |

## 1. Why this task exists

Delete a season and delete everything — the only `canPop: false` flow in the product, and
the only two places anything is genuinely destroyed. Each **names what it will destroy, with counts,
before** the destructive step, and each takes two steps.

`indelible.md` §9 is the sentence this task is the exception to: *"**There is no delete.** Not banned —
absent. Striking is a visible word button that draws a line. The concept of erasure does not exist in
the product."* Screen 12 is where it does: *"the two destructive actions — and they are the only place
in the product where the word *delete* is used honestly: `DELETE SEASON 2026` and `DELETE EVERYTHING`,
each requiring the season year or the word `EVERYTHING` typed into a field, each printed above the
sentence `THIS IS THE ONLY DELETE IN SHED BOOK. IT IS NOT A STRIKE. THE ROWS DO NOT STAY.`"*

`07 §15.1`'s undo table has one word in the last two rows: **none**. Not a compensating event, not a
soft-void, not an `original_effective`. `ON DELETE CASCADE` has already run.

`/shed-code-review` is doubly required here because these are the only two verbs in the product that
destroy a shepherd's records, and because **a count that under-describes what is about to be destroyed
is the worst defect this epic can ship** — no gate catches it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§14.3 row 11** (the Data section: Restore · Delete a season · Delete everything) · **§14.4** (4 taps each; **typed confirmation**; *"the only `canPop: false` flow"*; *"Export first" offered as a 72 pt action above it — **offered, never required***; the two `showDialog` files) · **§15.1** (both deletes: undo **none**) · §15.2–§15.4 (the undo window, and that undo never survives process death) | the flows and their friction |
| `docs/design/indelible.md` | **§8 screen 12** (the double rule, the two labels, the typed field, and the three-sentence warning verbatim) · §9 (*"there is no delete"* — the rule this is the exception to) · **§7.13** (word button, `Destructive`: label and underline in `--madder-ink`, *"**never a filled red button** — a filled red button is a thing you press by accident"*) · §7.12 (text field: no placeholder) · §7.14 (the bottom sheet is the only overlay) | the composition |
| `docs/engineering/03-data-model-and-schema.md` | **§9.2** (`sweepSearchDocs` + `rebuildSearchIndex` run by `SeasonRepository` **inside the season-delete transaction**, and why the `recursive_triggers` pragma is not relied on) · §5.1 (`Seasons` and its cascades) · §5.14 (the season-delete search sweep is `SeasonRepository`'s; *"no other Dart code may write either table"*) · §5.8 (`ON DELETE` asymmetry: a ewe with a treatment is `RESTRICT`; a season containing a treated lamb cascades) | the blast radius |
| `docs/engineering/04-migrations-media-backup-restore.md` | **§7.2–§7.6** (the atomic replace-everything path: staging, validate before destruction, the two renames, the completion paragraph) · §5 (the media root and the relative-path rule) · §8 (`VACUUM INTO` is a snapshot, not a backup) | how a destructive swap is done safely |
| `docs/engineering/06-design-system.md` | §12 (`ShedDestructiveButton`: *"**never within `gapDestructive` of a frequent action; two-step**"*) · §9.3 (`gapDestructive` = **32**, `tapPrimary` = 72, `tapHero` = 88) | the geometry |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`SeasonRepository` owns the season-delete search sweep; `RestoreService` is the only file that renames the live database) · §3.4 (there is **no** delete controller — the verbs go on `settingsWriteControllerProvider`) · §4.5 + R59 · §4.7 (`ui.show_dialog`, `db.destructive_ddl`) · §5.1 (*restore*, never *import* or *merge*) | **BINDING** on the verbs, the keys and the words |
| `docs/engineering/12-testing.md` | §3.1 (`testDatabase()`) · §3.5 (durability as a testable property) · §5.1 (`pumpApp`) · §10 (the product's own promises as tests) | the tier and the harness |
| `docs/research/00-tech-decisions.md` | **#73** (a destructive confirmation is typed **or** two-step) · #69 (no generic `undo(id)`) · #22 (the double-tap defence) · #106 (colour is never the only channel) · #108 (never an all-numeric date) | the decisions applied |
| `epics/N23-restore-the-sweeps-and-the-seed/N23-T02-…md` | §5.1 (the `showDialog` ruling, already made) · §5.3 (the five statements, in `04 §7.3`'s order) · §5.4 (the two-step control geometry) | the pattern this task copies, and the one it must not |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the confirmation, the friction and the wording |
| `shed-safety-rules` | a delete that under-describes what it removes is the worst defect in this class |

The atomic-swap mechanics are `04 §7.2`'s and `RestoreService`'s, cited in Sources and spelled out in
§5.1 and §5.3; the skill budget is two auto-firing and the two above are the ones that decide whether
the **flow** is right rather than whether the file rename is tidy.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'delete everything names what it will destroy and requires two steps'`
- **Why it is red today** — nothing deletes, and the first implementation would be a one-tap destructive action.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen it so it cannot pass on a confidently wrong screen. Seed the live database to counts that are
**all different from each other and all different from any constant in the code** — 1 season, 38 ewes,
41 lambs, 6 treatments, 452 media assets — then assert:

1. Every one of those five numbers is rendered **before** the destructive control is enabled, each
   read from a `COUNT(*)` the test takes itself. Not "a count is shown": *these* counts.
2. The destructive control is **disabled** until the typed confirmation matches, and the typed word is
   compared exactly (`EVERYTHING` for the whole-database delete, the season's own **year** for the
   season delete).
3. `tester.tap(); tester.tap();` on the destructive control performs **one** destruction. `guard()` is
   the mechanism (`if (state is WriteRunning) return;`) and the assertion is that the service was
   called once (decision #22).
4. Cancel before the destructive step leaves every row count **unchanged** and leaves no staging file
   behind.

**Green.** The minimum code that passes, and nothing beyond it — both flows, counts read from the database, two steps each, `canPop: false` while in
progress.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The ruling this task must make first

**No document defines what *"delete everything"* does mechanically.** `07 §14.3` row 11 names the row;
`07 §14.4` prices it at four taps; `indelible.md` §8 gives its label and its warning sentence. Nothing
says whether it is a `DELETE FROM` loop or a file replacement.

**Rule it in writing, in this commit.** The recommendation, with its reason: **route it through the
same atomic replace `RestoreService` uses** — create a fresh database beside the live one, run
`seedFirstRun` into it, validate it, swap, reopen, and sweep the media root — because a `DELETE FROM`
loop leaves four things behind that make the label a lie:

| Left behind by a `DELETE FROM` loop | Why it matters |
|---|---|
| The **media root** — every photo and voice note | `04 §5`: media is on the filesystem with relative paths in the database. "Delete everything" that leaves 452 photos on the phone is the app saying something untrue |
| The **FTS5 shadow tables** | `search_fts` is an external-content index; `03 §9.2` already has to sweep and rebuild for the *season* delete. A whole-database delete would have to do it again, correctly, by hand |
| `sqlite_sequence` and the WAL | Ids continue where they left off, which is harmless and confusing, and the WAL keeps the old pages until a checkpoint |
| The **pre-migration snapshot** in `pre_migration/` | Written by `configureConnection` (R13). It is a copy of the records the user just asked to destroy |

`RestoreService` is *"the ONLY file that renames the live database"* (`CONVENTIONS` §2.13, N23-T01).
So the verb belongs beside it and reuses its half-two, with an **empty seeded database** where the
imported one would be. If the ruling goes the other way, the losing document is amended in the same
commit (`00-README` §10) and the `DELETE FROM` path must carry its own media sweep, FTS rebuild and
`VACUUM` — say so explicitly rather than discovering it.

**The `showDialog` question is already ruled and must not be re-opened.** N23-T02 made it:
`indelible.md` §7.14 says the bottom sheet is *"the only overlay in the app"*; `07 §14.4` says restore
and delete are *"the only two flows permitted to use `showDialog`"*; N23-T02 ruled it and amended the
loser. Read that ruling, follow it, and **check the path `ui.show_dialog` already names** before
creating a file:

```bash
grep -n "ui.show_dialog" tool/check_policy.dart
```

Move the **file** to match the rule if they disagree — never the rule to match the file (`CLAUDE.md`).

### 5.2 The files, in `00-README` §8 order

**Steps 3 (write path), 5 (controller), 6 (UI), 7 (ARB) and 8 (tests).** No schema — the cascades were
declared at N07 and `db.destructive_ddl` bans a `DROP` anywhere. No domain. **Say both out loud in the
commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/season_repository.dart` | **Edit.** `deleteSeason(SeasonId)` — one transaction containing the delete, then `sweepSearchDocs`, then `rebuildSearchIndex`, **in that order** (`03 §9.2`). Plus `watchSeasonDeletionCounts(SeasonId)`, a season-scoped count read |
| 2 | `lib/data/restore_service.dart` | **Edit.** `deleteEverything()` — half two's swap with a freshly seeded database instead of an imported one (§5.1's ruling). It reuses the staging, validation and rename steps rather than re-implementing them |
| 3 | `lib/data/media_sweeper.dart` | **Edit, if needed.** The whole-root sweep the delete-everything path calls after the swap. N23-T03 built the both-directions sweeper; check whether it already exposes what is needed before adding a method |
| 4 | `lib/features/settings/widgets/delete_confirmation.dart` | **New.** Both flows, one widget, two configurations. **The second file `ui.show_dialog` allowlists** — or not, per §5.1's inherited ruling |
| 5 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `deleteSeason(SeasonId)` and `deleteEverything()`, both `guard()`ed. `CONVENTIONS` §3.4 declares no delete controller and this task does not invent one |
| 6 | `lib/features/settings/settings_screen.dart` | **Edit.** The two rows in the Data section, below a double rule, below the Restore row N23-T02 already put there |
| 7 | `lib/l10n/app_en.arb` | **Edit.** Every string below, each with a `description` carrying **why it is worded that way** |
| 8 | `test/features/settings_test.dart` | **Edit.** The anchor and the widget cases |
| 9 | `test/data/season_repository_test.dart` | **Edit.** The cascade, the sweep and the rebuild, at the tier that runs first |

### 5.3 The signatures, the counts and the wording

```dart
// lib/data/season_repository.dart
//
// 03 §9.2: the season-delete path does NOT rely on `PRAGMA recursive_triggers`.
// In the same transaction as the delete, AFTER it, it runs the orphan sweep and
// then the rebuild, "so the index is correct whichever way the pragma question
// resolves". Both queries live in lib/core/db/queries.drift and nothing else in
// Dart may write search_docs or search_fts (03 §5.14).
Future<WriteOutcome> deleteSeason(SeasonId season) => _db.transaction(() async {
      await (_db.delete(_db.seasons)..where((s) => s.id.equals(season.value))).go();
      await _db.sweepSearchDocs().go();
      await _db.rebuildSearchIndex().go();
      return const WriteCommitted();
    });

/// Season-scoped counts, read from the database at the moment the confirmation
/// opens. NOT ExportRepository's whole-database counts — layer rule 6 forbids
/// lib/features/settings/ importing lib/features/export/, and more importantly
/// a whole-database count on a season delete would be a confident, symmetrical,
/// WRONG pair of numbers (N23-T02's own warning, applied one screen over).
Stream<SeasonDeletionCounts> watchSeasonDeletionCounts(SeasonId season);

final class SeasonDeletionCounts {
  const SeasonDeletionCounts({
    required this.ewesRecorded, required this.lambings, required this.lambs,
    required this.treatments, required this.notes, required this.mediaAssets,
  });
  final int ewesRecorded, lambings, lambs, treatments, notes, mediaAssets;
}
```

```dart
// lib/data/restore_service.dart — §5.1's ruling, implemented as reuse.
//
// The SAME one-way door as restore(), minus the file that would have replaced
// the records: staging -> seedFirstRun -> validate -> rename -> reopen -> sweep
// the media root. RestoreService is "the ONLY file that renames the live
// database" (CONVENTIONS §2.13), which is why the verb lives here and not on a
// repository.
Future<WriteOutcome> deleteEverything();
```

The five statements the whole-database confirmation prints, in `04 §7.3`'s order — what you are about
to lose, what that means, what it does not include, and only then the controls:

```
1  What is on this phone now   "1 season, 38 ewes, 41 lambs, 6 treatments,
                                452 photos and voice notes."
2  The destruction sentence    "Deleting will remove everything now on this phone.
                                This cannot be undone from inside the app."
3  The only-delete sentence     indelible.md §8 screen 12, verbatim:
                                "THIS IS THE ONLY DELETE IN SHED BOOK.
                                 IT IS NOT A STRIKE. THE ROWS DO NOT STAY."
4  Export first                 a 72 pt action ABOVE the destructive one.
                                07 §14.4: "offered, never required."
5  The two controls             step one: type EVERYTHING into a field
                                step two: 72 pt "Delete everything" — disabled
                                          until step one matches, on the OPPOSITE
                                          side of the screen from Cancel, at least
                                          gapDestructive (32) from its neighbour
```

The season confirmation is the same five with a season-scoped statement 1 and the season's **year** as
the typed word.

Widget keys, R59 spelling, read by T08 and by N33's four sweeps:

```
settings.data.delete_season          settings.data.delete_everything
settings.delete.counts               settings.delete.destruction
settings.delete.only_delete          settings.delete.export_first
settings.delete.typed_word           settings.delete.confirm
settings.delete.cancel
```

### 5.4 The details that are easy to get wrong

- **The counts are counted, not described.** `07 §14.4`: the flow *"states plainly what will be
  destroyed."* N23-T02's own warning, one screen over: *"wiring both to the header is the single most
  likely bug on this screen and it renders as a confident, symmetrical, **wrong** pair of numbers."*
  Here the equivalent bug is showing the **whole-database** counts on a **season** delete. Read
  season-scoped counts for the season delete and whole-database counts for the other, and never share
  the query.
- **The season delete uses a typed confirmation; the restore does not — and the wrong pattern is one
  screen away.** N23-T02 chose two taps in different places and said why: *"a word to type is a
  keyboard, and this is the app that exists because keyboards are hard with wet hands."* `07 §14.4` and
  `indelible.md` §8 screen 12 both give the **deletes** a typed confirmation anyway, because they are
  daylight work with two hands and because they are irreversible. Decision #73 permits either. Do not
  "harmonise" the two flows: the difference is the argument.
- **Two steps, separated by `gapDestructive`.** `06 §12`: `ShedDestructiveButton` is *"never within
  `gapDestructive` of a frequent action; two-step."* The token is **32** and it is read from
  `context.tokens.gapDestructive` — a literal `32` is a build-breaking defect. The confirm control sits
  on the **opposite side** from Cancel.
- **Never a filled red button** (`indelible.md` §7.13). The destructive state is a **label and
  underline in `--madder-ink`** (5.59:1), because *"a filled red button is a thing you press by
  accident."* Colour is never the only channel (decision #106): the word `Delete everything` carries
  the meaning and the ink reinforces it.
- **`canPop: false` from the destructive step onward, and use `onPopInvokedWithResult`.**
  `onPopInvoked` is deprecated, and `--fatal-infos` turns a deprecation into a CI failure. Before the
  destructive step Cancel is real and costs nothing.
- **`07 §14.4` says the season delete is *"the only `canPop: false` flow in the app"*; N23-T02 already
  amended that to two.** This commit makes it four. Edit the sentence again or, better, change it to
  name the class of flow rather than counting — a doc set that has to be re-counted every epic will
  eventually not be.
- **There is no undo, no compensating event and no soft-void** (`07 §15.1`, `#69`). Do not offer one,
  do not imply one, do not use the word, and do not set `SaveReceipt.undoLabel`. `15.4`: *"no undo
  affordance is ever reconstructed from storage."*
- **There is no SnackBar** (P2). Not for the confirmation, not for the outcome, not for the refusal.
  N23-T02 said it for restore and the reason is the same here: *"the outcome of a restore is a whole
  screen, because it is the one write in the app with no row to point at."* A delete has even less to
  point at.
- **The search index must be swept and rebuilt inside the season-delete transaction** (`03 §9.2`).
  `search_docs` is an external-content FTS5 index; rows removed by `ON DELETE CASCADE` *"do not reliably
  fire the child table's `AFTER DELETE` trigger unless `PRAGMA recursive_triggers` is on."* The pragma
  is set (R13) **and** the sweep runs anyway, in that order, so the index is correct whichever way the
  open verification question resolves. Skipping the sweep because the pragma is on is the shape that
  leaves `search_fts` returning rows whose content is gone.
- **A ewe survives a season delete; a season containing a treated lamb does not survive its own.**
  `03 §5.2`/`§5.8`: *"`ON DELETE CASCADE` from `Seasons` is right: deleting a season removes that
  season's participation records and **must not remove the ewes**."* The confirmation must therefore
  say what stays as well as what goes, or a shepherd will believe deleting 2025 deleted her flock.
- **`ON DELETE SET NULL` on `app_settings.current_season` means the delete can leave no current
  season** — and `export_prompt_dismissed_for_season` too. Handle the null; do not write a defensive
  replacement id, because picking a season on the user's behalf is a silent correction.
- **"Export first" is offered, never required** (`07 §14.4`). A required export turns a delete into a
  share sheet the user did not ask for, and the share sheet is a different process. It is a 72 pt
  action **above** the destructive one, and tapping it pushes Export and **starts no work** (the same
  rule the end-of-day banner follows, `07 §16.3`).
- **`guard()` is the double-tap defence, not a debounce** (decision #22, `02 §7.1`).
  `if (state is WriteRunning) return;` — a second tap during the flow does nothing at all. The test is
  literally `tester.tap(); tester.tap();` and the assertion is one destruction.
- **Every banned gesture, on the one screen where a designer would reach for one.** No `Dismissible` to
  cancel, no drag-to-confirm, no hold-to-delete, no slider. All are `check_policy` rows, and
  hold-to-repeat is banned as long-press's cousin (`CLAUDE.md`).
- **Layer rule 6.** `lib/features/settings/` may not import `lib/features/export/`, so
  `exportCountsProvider` is out of reach. That is why the whole-database count lives on
  `ExportRepository` (N23-T02 put it there) and the season-scoped one on `SeasonRepository`.
- **`d MMM y`, never `14/07/2026`** (decision #108, R60). This screen is read once, by someone about to
  destroy their records; an ambiguous `07/13` here is a §12.5-class failure. The widget test greps the
  rendered text for `/` and expects none.
- **Banned copy on this screen:** *"a lost phone is lost data"* unqualified, *"should"*, *"compliance
  record"*, and any hedge on the destruction sentence — no *may*, no *might*. `ContentPolicy` scans ARB
  messages, so a soft word here is a red build, not a review note.
- **This is one of the two screens permitted to look frightening** (`04 §7.3`, applied). That is a
  licence for plain sentences, not for red fills, alarm icons or a countdown.

### 5.5 The full test set

Two files.

`test/features/settings_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'delete everything names what it will destroy and requires two steps'` | **The anchor.** All five counts rendered from the test's own `COUNT(*)`; step two disabled until the typed word matches |
| `'delete a season names that season's counts and not the whole database's'` | Seed two seasons with different totals; the confirmation shows the target season's, and neither number appears twice |
| `'the typed word is compared exactly'` | `everything`, `EVERYTHING ` and `EVERYTHIN` all leave the control disabled; `EVERYTHING` enables it. The season flow takes the year |
| `'the destruction sentence is present and unhedged'` | No *may*, no *might*, no *should*; the string comes from the ARB |
| `'the only-delete sentence is indelible §8's, verbatim'` | String equality against the three-sentence block |
| `'Export first is offered above the destructive control and starts no work'` | Its `Rect.top` is above; tapping it pushes Export and no artifact is built |
| `'a double tap on the destructive control destroys once'` | `tester.tap(); tester.tap();` → the service is called once (decision #22) |
| `'the flow cannot be popped once the destruction has begun'` | `canPop: false`; a system back does nothing; `onPopInvokedWithResult` is the API used |
| `'Cancel before the destructive step leaves every row count unchanged'` | Counts identical; no staging file; no sentinel |
| `'both controls are at least 60 x 60 and separated by gapDestructive read from tokens'` | `tester.getRect` against `context.tokens.gapDestructive`; no literal `32` in the widget file |
| `'the destructive control is not a filled button'` | Its background is the page surface; the ink is `--madder-ink` on the label and the underline |
| `'no rendered date contains a slash'` | Walk every `Text` (R60) |
| `'no undo is offered, implied or worded'` | `undo` appears in no ARB message reachable from this flow; `SaveReceipt` is not constructed |
| `'no SnackBar is shown at any point in either flow'` | P2 |
| `'no banned gesture is bound in the confirmation'` | Source text: `Dismissible`, `Draggable`, `Slider`, `onLongPress:` — all zero |
| `'the confirmation renders without overflow at the smallest device and textScaler 2.0, bold'` | More prose than any other section; the cell most likely to break |
| `'every string in the flow is an ARB message with a description'` | Source text over `app_en.arb` and the widget file |

`test/data/season_repository_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'deleting a season cascades its events and leaves the ewes'` | `ewe_seasons`, `lambings`, `lambs`, `care_events`, `ewe_observations`, `foster_events`, `pen_occupancies`, `treatments`, `reminders` all gone for that season; `ewes` unchanged. Both halves in one test — `03`'s DoD makes the same point about the `ON DELETE` asymmetry |
| `'deleting a season sweeps search_docs and rebuilds the index in the same transaction'` | Insert a note, delete its season, assert `search_docs` is empty and `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw |
| `'the sweep runs whether or not recursive_triggers fired'` | Once with the pragma on, once with it off (`03 §9.2`'s five-minute verification, made permanent) |
| `'deleting the current season leaves app_settings.current_season NULL and the row intact'` | `ON DELETE SET NULL`; `COUNT(*) FROM app_settings` is still 1 |
| `'delete everything leaves one seeded database and an empty media root'` | Row counts equal a fresh `seedFirstRun`; the media root has no files; `pre_migration/` is empty |
| `'delete everything is atomic — an interrupted swap leaves the live database readable'` | Kill between the two renames; `completeInterruptedRestore` resolves it; `RestoreOutcome` is never `notStarted` |
| `'no DROP statement appears anywhere in the diff'` | Source text. `db.destructive_ddl` proves it in CI; this proves it in the tier that runs first |

## 6. Constraints that bind this task

- **§12.4, held at *caught by a test*: these are the only two genuine destructions in the product and neither of them is silent.** Each names what it will destroy, **with counts, before** the destructive step, and each takes two steps with `canPop: false` in between. A flow that reports a count it did not actually query, or that completes on one tap, breaks §12.4 as surely as an auto-correction would — the user was not told what changed.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The safety rule this task holds is §12.4**, at the level *"caught by a test on the source text"* for
  the wording and *"unrepresentable"* for the mechanism: there is no `undo(id)` to call (decision #69),
  so there is nothing to reconstruct and nothing to imply. The rule it must not weaken is the honesty of
  the counts, and that one has **no mechanism above a test** — which is why the test seeds five
  different numbers.
- **§12.3 does not reach the deletes, but the word *record* does.** Never *"delete your compliance
  record"*, never *"official record"*. Records, in project vocabulary, and nothing else.

## 7. Definition of Done

- [ ] `'delete everything names what it will destroy and requires two steps'` passes, and was seen to fail first for the stated reason
- [ ] counts are read, not described in the abstract
- [ ] two steps, separated by `gapDestructive`
- [ ] the flow cannot be dismissed by a back gesture mid-way
- [ ] a double-tap test exists for both
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **the delete-everything mechanism is ruled in writing in this commit** (§5.1), and if it is not the atomic swap, the media sweep, the FTS rebuild and the `VACUUM` are each named and implemented
- [ ] the `ui.show_dialog` ruling is **inherited from N23-T02, not re-opened**, and the file sits at the path the rule already names
- [ ] the season delete reads season-scoped counts and the whole-database delete reads whole-database counts; the two queries are not shared
- [ ] `deleteSeason` runs the delete, then `sweepSearchDocs`, then `rebuildSearchIndex`, in one transaction and in that order
- [ ] the confirmation states what **stays** — the ewes survive a season delete — as well as what goes
- [ ] the destructive control is a label and an underline in `--madder-ink`, never a filled button, and never within `gapDestructive` of a frequent action
- [ ] `onPopInvokedWithResult` is the API used; `onPopInvoked` appears nowhere
- [ ] the word *undo* appears in no message reachable from either flow
- [ ] `07 §14.4`'s *"the only `canPop: false` flow"* sentence is amended in this commit
- [ ] `find.byType(SnackBar)` is `findsNothing` through every state of both flows

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/data/season_repository_test.dart
fvm flutter test test/data/restore_service_test.dart     # N23-T01's file, still green
make check
make test
```

```bash
grep -n "ui.show_dialog" tool/check_policy.dart                    # read the path BEFORE creating a file
grep -rn "showDialog(" lib/features/                               # exactly the two allowlisted files
grep -rn "DROP TABLE\|DROP COLUMN" lib/                            # expect zero (db.destructive_ddl)
grep -rn "onPopInvoked\b" lib/                                     # expect zero — WithResult only
grep -rni "undo" lib/features/settings/widgets/delete_confirmation.dart lib/l10n/app_en.arb | grep -i delete
grep -rn "32\b" lib/features/settings/widgets/delete_confirmation.dart   # expect zero — tokens only
grep -rn "Dismissible\|Draggable\|Slider(\|onLongPress" lib/features/settings/   # expect zero
grep -rn "SnackBar(\|showSnackBar(" lib/features/settings/         # expect zero (P2)
git diff --stat -- drift_schemas/ lib/core/db/tables/              # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): the two honest deletes`
