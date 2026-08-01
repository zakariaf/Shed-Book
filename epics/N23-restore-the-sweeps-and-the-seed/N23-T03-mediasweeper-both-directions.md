# N23-T03 — `MediaSweeper` — both directions

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 3 of 7 |
| **Depends on** | N23-T02 |
| **Commit** | one commit · `feat(media): MediaSweeper in both directions` |

## 1. Why this task exists

Files with no row and rows with no file. The first wastes a shepherd's storage in March;
the second is a broken image on the Ewe Card and is recorded as `missing_since` rather than crashing.
The sweep's schedule is stated, not implicit.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | **§5.1** (files with no row — the walk, `.part`, `.trash/<date>/<rel>`, printed in full) · **§5.2** (rows with no file — `missing_since`, and the un-flag when the file returns) · **§5.3** (when the sweeps run: never before the first frame, once per launch, once after a restore, chunked to ~8 ms, on the **one** `AppDatabase` instance) · **§5.4** (the five gates) · §4.2 (the media layout, the shards, `.trash/`) · §4.3 (relative paths only; the three `CHECK`s; `MediaStore.resolve`) · §4.8 (media is never deleted synchronously and never deleted at all by a sweep) · §4.9 (the anti-pattern table) · §7.2 step 15 · §7.6 (media after restore) | the two directions, their code and their schedule |
| `docs/engineering/CONVENTIONS.md` | **§2.8** (`MediaSweeper` · `SweepReport`, `lib/data/media_sweeper.dart`) · §2.12 (`MediaStore` owns the root, `newRelativePath`, `resolve`, `writeAtomically`) · §2.13 (`NoteRepository` owns writes to `notes` and `media_assets`) · §3.1 (`mediaSweeperProvider`) · §1.1 layer rules 3, 4, 8 · **R23** (`appNow()` is the only wall-clock reader) · **R47**, **R62** · §5 | **BINDING** on the class, the file and the report |
| `docs/engineering/05-domain-correctness.md` | §1.3 (`appNow()`) · §2.4 (`LocalDate.of(Instant).iso` — the `YYYY-MM-DD` the trash folder is named by) | how the trash date is produced |
| `docs/engineering/12-testing.md` | §3.1 (`testDatabase()`) · §3.3 (real SQL, never a mock) · **§2.3** (the ambiguous hour, 01:00–01:59) · §11.6 (no `Future.delayed`) | how the anchor is written |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #40 (filesystem, relative paths only) · #46 (one clock) · #29 (`missing_since` is an `INTEGER` instant, not a `dateTime()`) · #123 (diagnostics) · #125 (off-isolate work — and why a sweep is *not* it) | the decisions this task applies |
| `CLAUDE.md` | §12.4 applied to bytes — the app does not silently destroy the user's things · the vocabulary table | why nothing is deleted |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the file system side of the sweep |
| `shed-export-and-restore` | the sweep runs after a restore and its rules are the format's |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/media_sweeper_test.dart`
- **Test** — `'a row with no file is marked missing_since and a file with no row is removed'`
- **Why it is red today** — nothing reconciles the media folder with the database, and a restore leaves both inconsistent.

```bash
fvm flutter test test/data/media_sweeper_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so the word *removed* cannot be implemented as `delete()`:

1. Assert the orphan file is **at `<root>/.trash/<yyyy-MM-dd>/<its original relative path>`** — not
   that it is absent from where it was. `04 §4.8`: media is moved, never deleted.
2. Assert the flagged row **still exists** and only `missing_since` changed. Deleting the row is the
   named anti-pattern in `04 §4.9`: *"makes the app lie by omission."*
3. Assert `SweepReport` carries both counts, so the Diagnostics line is real rather than decorative.

**Green.** The minimum code that passes, and nothing beyond it — both directions, the schedule, and the `missing_since` write.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step.** `media_assets.missing_since` already exists — N07 landed it, in the spelling
`04 §4.3` fixes: `integer().map(const InstantConverter()).nullable()()`, converter first, `nullable()`
second. If it is not there, that is a migration and it is N08's harness, not this task.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/db/queries.drift` | **Edit.** Three named queries, because `lib/data/` may not say `customStatement(` (layer rule 8): `allMediaRelativePaths` (one `SELECT`, projected to a `Set<String>`), `mediaAssetsNotYetMissing` (`WHERE missing_since IS NULL`) and `flagMediaMissing` / `unflagMediaMissing`. Regenerates `database.g.dart` — the regeneration is **in this commit** |
| 2 | `lib/data/media_sweeper.dart` | **New.** `MediaSweeper` and `SweepReport`. Takes the one `AppDatabase` and the one `MediaStore`; opens no second connection and constructs no `Directory` of its own |
| 3 | `lib/data/providers.dart` | **Edit.** `mediaSweeperProvider` (`FutureProvider<MediaSweeper>`, keepAlive — `CONVENTIONS` §3.1), derived from `databaseProvider` and `mediaStoreProvider` |
| 4 | `lib/data/restore_service.dart` | **Edit.** Step 15's call site: after the first frame of the restored app, `sweepMissingFiles()` then `sweepOrphanFiles()`. The `reconcile()` beside them stays a `// TODO(N24)` with its reason |
| 5 | `lib/app.dart` | **Edit.** The once-per-launch call, from the existing post-frame boot kick. **Never** before the first frame (#21) and never on resume — *"a 20-minute pocket gap does not create orphans"* |
| 6 | `lib/features/settings/settings_screen.dart` | **Edit.** The Diagnostics line that shows the counts. Reported, not announced: a sweep that trashes three files interrupts nobody |
| 7 | `test/data/media_sweeper_test.dart` | **New.** The anchor and its neighbours (§5.4) |

### 5.2 The signatures

`04 §5.1` and `§5.2` print both methods in full. Copy them; the two things worth restating are the
report and the un-flag, because both are easy to leave out.

```dart
// lib/data/media_sweeper.dart
final class SweepReport {
  const SweepReport({
    this.orphanFilesTrashed = 0,
    this.rowsFlaggedMissing = 0,
    this.rowsUnflagged      = 0,   // a file that came back — 04 §5.2
    this.partFilesDeleted   = 0,   // the ONE thing a sweep may delete
  });
  final int orphanFilesTrashed, rowsFlaggedMissing, rowsUnflagged, partFilesDeleted;
}

final class MediaSweeper {
  MediaSweeper(this._db, this._store);

  /// Direction 1 — files with no row. Walks the media root, skips `.trash/`,
  /// deletes `.part` (a killed write nothing ever referenced), and RENAMES every
  /// unreferenced file to `.trash/<yyyy-MM-dd>/<its original relative path>`.
  Future<SweepReport> sweepOrphanFiles();

  /// Direction 2 — rows with no file. Flags `missing_since` for a row whose file
  /// is gone, and clears it again for a row whose file has come back, because
  /// "it is here now" is also true (04 §5.2). One transaction.
  Future<SweepReport> sweepMissingFiles();
}
```

The trash date is `LocalDate.of(appNow()).iso` — `'YYYY-MM-DD'`, `05 §2.4`. `appNow()` is the app's
single wall-clock reader (R23, #46); there is no `DateTime.now()` in this file and no second clock.

### 5.3 The details that are easy to get wrong

- **Nothing is deleted.** The word in the anchor's name is *removed*, and it means **moved to
  `.trash/<yyyy-MM-dd>/<rel>`**. `04 §4.8` is spec §12.4 applied to bytes: *"the app does not silently
  destroy the user's things."* Settings shows *"Recoverable files: 12 (deleted 3 days ago)"*, and the
  purge is 30 days or 100 MB, oldest first — which is a bound this task honours, not a sweep it runs.
- **`.part` is the single exception**, and it is safe for a stated reason: a `.part` file is a killed
  atomic write (`MediaStore.writeAtomically` writes `<target>.part` then renames), so nothing ever
  referenced it and no row can point at it. Delete it, count it, move on.
- **Never delete the row.** `04 §4.9`: deleting a `media_assets` row because the file is gone *"makes
  the app lie by omission"*. *"Photo taken 14 March 03:22 — file no longer on this phone"* is a true
  and useful sentence. The sweep test asserts the row survives.
- **Un-flag when the file returns.** Set `missing_since` back to `NULL`. A user who restored their
  container, or an iOS device restore that brought the media back, must not be left with a permanent
  scar. This is the half of direction 2 that is easiest to skip and it has its own gate row.
- **Skip `.trash/` in the walk, or the sweep eats its own tail.** Every trashed file is by definition
  unreferenced, so a walk that does not skip the folder re-trashes everything on every launch, one
  nested directory deeper each time.
- **Relative paths are POSIX-joined, always.** `p.posix.joinAll(p.split(p.relative(...)))` — on a
  Windows dev machine `p.relative` returns backslashes and every `known.contains(rel)` misses, so the
  sweep trashes the user's entire media folder on its first run. `04 §4.3`'s three `CHECK`s make such a
  path unstorable, which is exactly why the *comparison* must normalise.
- **`missing_since` is an `INTEGER` instant, not a `dateTime()`.** Decision #29 and #30: there are no
  `dateTime()` columns in this project at all, and `check_policy` rule `db.drift_datetime` fires on
  one. Write `appNow()` through the `InstantConverter`.
- **One connection, one instance.** The sweeper is handed the same `AppDatabase` every repository
  already uses, so its statements queue behind writes on the same connection. It never opens a second
  connection — a second connection to a WAL database mid-write is how you get `SQLITE_BUSY` on the one
  night the app matters.
- **Never before the first frame** (#21). Both sweeps run from a post-frame callback *after* the first
  real screen has rendered, and the file walk is chunked so no single microtask exceeds ~8 ms. The
  startup-trace gate asserts neither appears before `timeToFirstFrameMicros` in
  `build/start_up_info.json`.
- **Once per launch, and once after a restore. Not on resume.** `04 §5.3` states the schedule; state
  it in the code as a comment beside each call site, or it becomes implicit again the first time
  somebody adds a lifecycle hook.
- **`lib/features/**` may not construct a `File`** (`check_policy` rule `layer.features`). The
  Diagnostics line renders numbers off `SweepReport`; it does not look at the filesystem.
- **`getApplicationSupportDirectory()` stays in its two files.** The sweeper reaches the media root
  through `MediaStore.root()` and nowhere else — two roots means two answers.
- **`resolve()` still guards containment.** `MediaStore.resolve` throws on a path that leaves the media
  root. The sweep resolves every row's path through it rather than joining strings, because a row that
  somehow holds `../` must fail loudly rather than have the sweeper walk out of the container.
- **The counts are reported, never announced.** No SnackBar (P2), no banner, no modal. Settings ▸
  Diagnostics. A sweep that trashes three files interrupts nobody.
- **Run direction 2 before direction 1 after a restore** — `04 §7.2` step 15 lists
  `sweepMissingFiles()` first. After a records-only restore *every* media row is missing, and flagging
  them first means the orphan walk (which is the slow one) runs against a database that already knows
  the truth.

### 5.4 The full test set

`test/data/media_sweeper_test.dart`, against `NativeDatabase.memory()` and a real temp media root.

| Case | What it asserts |
|---|---|
| `'a row with no file is marked missing_since and a file with no row is removed'` | **The anchor.** The orphan is **at `.trash/<yyyy-MM-dd>/<rel>`**; the flagged row still exists and only `missing_since` changed; `SweepReport` carries both counts |
| `'a trashed file keeps its original relative path under the date folder'` | `2026/03/<uid>.jpg` → `.trash/2026-07-27/2026/03/<uid>.jpg` |
| `'a .part file is deleted and no row is touched'` | The one legal deletion; `partFilesDeleted` is 1 |
| `'a file that reappears clears missing_since'` | Flag, restore the file, sweep again, `missing_since` is `NULL` and `rowsUnflagged` is 1 |
| `'the sweep never deletes a media file'` | Count files under the root before and after: the total (including `.trash/`) is unchanged except for the `.part` |
| `'the sweep skips .trash and does not re-trash its own output'` | Run it three times; the `.trash` tree does not nest and `orphanFilesTrashed` is 0 on runs two and three |
| `'a Windows-shaped relative path does not cause a mass trashing'` | Feed the walk a path with backslashes and assert the POSIX normalisation makes it match the row |
| `'a media row whose relative path escapes the root fails loudly'` | `MediaStore.resolve` throws; the sweep does not walk out of the container |
| `'after a records-only restore every media row is flagged and no file is touched'` | The `04 §7.6` case: `rowsFlaggedMissing == media_assets` count; `media/` is byte-identical before and after |
| `'the sweep opens no second connection'` | It is constructed from the one `AppDatabase`; a second `NativeDatabase` in the diff is a review stop |
| `'neither sweep runs before the first frame'` | The startup-trace gate of `04 §5.4`; asserted here as "the boot kick calls it from a post-frame callback", and in the trace at N33 |
| `'the report reaches Diagnostics and nothing else'` | No SnackBar, no banner, no modal, anywhere in the diff (P2) |
| `'a sweep in the ambiguous hour files the trash under the right civil date'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 on 25 October 2026** — the hour that happens twice. The folder is `.trash/2026-10-25/`, both times through the hour, and never `2026-10-24`. `LocalDate.of(appNow())` is the only thing that can get this wrong, and a folder name a day out makes the 30-day purge fire a day early |

### 5.5 What this task does **not** build

The 30-day / 100 MB `.trash` purge is a bound this task's output lives inside, not a sweep this task
runs — it belongs with the storage figures in Settings ▸ Diagnostics. `reconcile()` is N24's. The
`ShedPhoto` "not on this phone" rendering is N15's; this task only writes the column it reads.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **§12.4 applied to bytes.** Nothing this task writes may destroy something the user made. The only
  `delete()` in the diff is the `.part` branch, and it carries the comment that says why it is safe.
- **One clock** (#46, R23). `appNow()` and nothing else. `DateTime.now()` in path construction is a
  named anti-pattern with its own `check_policy` row.
- **Never before the first frame** (#21). Nothing in the startup sequence may sit between the
  shepherd's thumb and a saved lambing event.

## 7. Definition of Done

- [ ] `'a row with no file is marked missing_since and a file with no row is removed'` passes, and was seen to fail first for the stated reason
- [ ] both directions covered
- [ ] a missing file is a rendered state, never a crash
- [ ] the sweep runs after a restore and on the schedule stated in the source
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] no media file is deleted; the `.part` branch is the only `delete()` and it carries its reason
- [ ] no `media_assets` row is deleted because its file is gone
- [ ] a file that reappears clears `missing_since`
- [ ] the walk skips `.trash/` and does not nest its own output
- [ ] the sweeper takes the one `AppDatabase` and the one `MediaStore`; no second connection, no `Directory` constructed in `lib/data/media_sweeper.dart`
- [ ] both sweeps run post-frame, once per launch and once after a restore, never on resume
- [ ] the counts reach Settings ▸ Diagnostics and nothing else
- [ ] `drift_schemas/` is unchanged, and `database.g.dart`'s regeneration is in this commit

## 8. Verification

```bash
fvm flutter test test/data/media_sweeper_test.dart
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/restore_test.dart      # step 15 still passes after the change
```

```bash
grep -n  "delete(" lib/data/media_sweeper.dart          # expect exactly one, in the .part branch
grep -rn "dateTime()" lib/                              # expect zero (#29, #30)
grep -rn "DateTime.now(" lib/ | grep -v app_clock.dart  # expect zero (#46)
grep -rn "getApplicationSupportDirectory" lib/          # expect exactly two files
grep -rn "customStatement(" lib/data/                   # expect zero (layer rule 8)
grep -rn "NativeDatabase\|driftDatabase(" lib/data/media_sweeper.dart   # expect zero
grep -rn "File(" lib/features/                          # expect zero (layer.features)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(media): MediaSweeper in both directions`
