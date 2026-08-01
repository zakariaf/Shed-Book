# N23-T06 — `restoreInto` and `freshSupportDir()` in the harness

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 6 of 7 |
| **Depends on** | N23-T05 |
| **Commit** | one commit · `test(support): restoreInto and freshSupportDir` |

## 1. Why this task exists

The harness gains the two members `09 §7.3` calls and `12` declares: `restoreInto` and
`freshSupportDir()`, a temp directory torn down with the test. Without them every restore test writes
into the developer's real application support directory, which is a fine way to lose your own demo
data.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§7.3** (the printed test, and the comment that fixes both names: *"`restoreInto` is the harness wrapper around 04 §7.2's flow — staging file, validate, swap, reopen — and it returns the reopened `AppDatabase`. 04 owns that entry point's name and signature; 09 does not get to invent one, and `RestoreOutcome` is 04's enum, not a value with a database on it"*) · §7.1–§7.2 | the two signatures, and who owns them |
| `docs/engineering/12-testing.md` | **§5.3** (the twelve support files, closed; `freshSupportDir()` declared inside `harness.dart` — *"a temp directory torn down with the test, which is what `restoreInto` restores into — `09 §7.3` calls it and 12 declares it"*) · §5.1 (`testDatabase()`, `shedContainer()`, `atFixed()`, `pumpApp`) · §3.1 (`closeStreamsSynchronously: true`, `addTearDown(db.close)` inside the helper) · §3.2 (the host sqlite3 floor) · §11.6 (flakiness discipline) | where both members live and what they must tear down |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7.2 (the flow `restoreInto` wraps) · §7.5 (the resume routine a test may need to drive) · §4.2 (what a support directory contains: `shed_book.sqlite`, its two sidecars, `media/`, `pre_migration/`, `restore_staging/`, `restore_rollback/`, `diagnostics/`) | what a "support directory" has to look like for the flow to run |
| `docs/engineering/CONVENTIONS.md` | **§2.8** (`openAppDatabase()` *"asserts it is not running under `flutter_test` and throws with the name of the override to add"* — R12) · §3.1 (`databaseProvider` is a `FutureProvider`, never `Provider<AppDatabase>`) · §1.1 layer rule 3 · **R12, R57** | why a test may not reach the real opener |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #111 (`NativeDatabase.memory()`, never a mock; `closeStreamsSynchronously`) · #27 (application support is where the real database lives) · #121 (randomised ordering) | the decisions this task applies |
| `epics/N23-restore-the-sweeps-and-the-seed/N23-T01-restoreservice-a-new-file-beside-the-live-one.md` | §5.2 (the injected `Directory`, and the two halves) | why `restoreInto` is four lines rather than a reimplementation |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the harness, its teardown and its isolation guarantees |
| `shed-export-and-restore` | `restoreInto` is the restore path under test |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/support/harness_test.dart`
- **Test** — `'freshSupportDir is torn down with the test and restoreInto never touches the real support directory'`
- **Why it is red today** — restore tests have nowhere isolated to write.

```bash
fvm flutter test test/support/harness_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it proves both halves:

1. Capture the path `freshSupportDir()` returns, run a `restoreInto` into it, and assert after the test
   completes that the directory **no longer exists**. A teardown asserted from inside the same test
   proves nothing — register the check in a second `addTearDown` so it runs after the helper's own.
2. Assert `restoreInto` produced files **under that path and nowhere else**: `shed_book.sqlite` is
   there, and no file was created under the platform's real application-support path.
3. Assert `getApplicationSupportDirectory()` was never called — the strongest form is that a test
   process has no platform channel for it, so a call **throws**; the assertion is that the flow
   completed, which it could not have done if anything reached for it.

**Green.** The minimum code that passes, and nothing beyond it — both members and a teardown assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Nothing under `lib/` changes.** The whole diff is `test/support/` plus one new test file. Say so in
the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Edit.** `freshSupportDir()` and `restoreInto(...)`, declared here because `12 §5.3` puts them here by name and because `test/support/` is twelve files and the list is closed. No thirteenth file |
| 2 | `test/support/seeds.dart` | **Edit, only if needed.** `restoreFixture` (T05) and `restoreInto` are two entry points into the **same** service — half one and the whole flow. If T05's implementation duplicated any of the parse, fold it into one private helper here now, in the refactor step |
| 3 | `test/support/harness_test.dart` | **New.** The anchor and its neighbours (§5.4). This is a test *of* the harness, which `12 §5.3` permits: *"anything else is either a test or a fake"* |

### 5.2 The signatures

```dart
// test/support/harness.dart

/// A support directory of this test's own, torn down with the test.
/// SYNCHRONOUS, because 09 §7.3 calls it inline as an argument:
///   restoreInto(freshSupportDir(), File(first.path))
/// It creates the directory eagerly so `restoreInto` can assume it exists, and
/// registers its own teardown — like testDatabase() does with db.close (12 §3.1).
Directory freshSupportDir() {
  final dir = Directory.systemTemp.createTempSync('shed_support_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}

/// The harness wrapper around 04 §7.2's flow — staging file, validate, swap,
/// reopen — returning the REOPENED AppDatabase. 04 owns the entry point's name
/// and signature; this wrapper adds nothing but the plumbing a test needs.
///
/// It is the ONLY restore entry point tests use for the whole flow.
/// `restoreFixture` (N23-T05) is the other half: it loads a committed backup
/// into an already-open in-memory database and never renames a file.
Future<AppDatabase> restoreInto(Directory support, File backup) async {
  final header  = BackupHeader.parse(await backup.readAsString());  // N22-T01
  final service = RestoreService(support, FakeNotificationScheduler());
  final outcome = await service.restore(incoming: backup, header: header);
  expect(outcome, isA<WriteCommitted>(),
      reason: 'restoreInto is for the happy path; assert refusals against '
              'RestoreService directly so the failure names the step');

  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase(File(p.join(support.path, 'shed_book.sqlite')),
          setup: configureConnection),
      closeStreamsSynchronously: true,             // #111
    ),
    seedOnCreate: false,                           // the rows came from the file
  );
  addTearDown(db.close);
  return db;
}
```

### 5.3 The details that are easy to get wrong

- **`freshSupportDir()` is synchronous.** `09 §7.3` calls it as an inline argument —
  `restoreInto(freshSupportDir(), File(first.path))` — so an `async` version does not compile at the
  one call site the doc set actually prints. Use `createTempSync`.
- **`addTearDown` only works inside a test body.** It is `flutter_test`'s, registered against the
  currently-running test. Calling `freshSupportDir()` from `setUpAll` registers the teardown against
  the *group*, which is legal but means one directory shared by every test in the file — and then
  randomised ordering (#121) turns a leaked staging directory into a failure in a different test. Call
  it inside the test body, once per test.
- **Register the teardown inside the helper, not at the call site.** `12 §3.1` makes the same point
  about `testDatabase()`: *"`addTearDown(db.close)` inside the helper, not at each call site. A leaked
  database is a leaked isolate."* A leaked temp directory is smaller but it accumulates across a
  hundred runs.
- **Teardown order is LIFO.** The database is opened after the directory, so its `addTearDown(db.close)`
  registers later and runs **first** — which is what you want: closing the database before deleting the
  directory under it. If you reverse the two registrations, Windows and some Linux filesystems refuse
  the delete and the failure reads as a permissions error.
- **`restoreInto` must never reach `openAppDatabase()`.** R12: it *"asserts it is not running under
  `flutter_test` and throws with the name of the override to add"*. That assertion is a feature, not an
  obstacle — the wrapper opens `NativeDatabase(File(...))` directly, with the same public top-level
  `configureConnection` as production (R13), so the reopened database carries the same seven pragmas in
  the same order.
- **`getApplicationSupportDirectory()` is unreachable in a test process** — no platform channel, so
  `path_provider` throws or returns nothing. That is exactly why `RestoreService` takes an injected
  `Directory` (T01 §5.2). If you find yourself wanting a `path_provider` mock here, the production
  design is wrong, not the test.
- **`closeStreamsSynchronously: true` is mandatory** (#111). Without it, unsubscribing from a drift
  query stream keeps it alive for one event-loop iteration and the widget-test binding reports it as a
  leaked timer, with a message that names nothing useful.
- **`seedOnCreate: false` on the reopened database.** The rows came from the file. It is opening an
  existing file so `onCreate` will not run anyway, but stating it documents that the first-run season
  is not part of what is under test — the same reason `04 §3.2` keeps the flag explicit in the
  migration matrix.
- **`restoreInto` is the happy path, and its `expect` says so.** Refusals — a newer `schema`, a
  truncated file, a ZIP, a `.sqlite` — are asserted against `RestoreService` directly, in
  `test/features/restore_test.dart`, so the failure message names the step that refused. A wrapper that
  silently swallows a refusal turns six refusal fixtures into six green tests.
- **Two entry points, one service.** `restoreFixture` calls half one (`importInto`); `restoreInto` calls
  the whole flow. Neither is a loader. If a third appears, the epic's *"there is exactly one restore
  code path"* Definition-of-Done line has already failed.
- **The temp directory must look like a support directory.** `04 §4.2`: the flow creates
  `restore_staging/` and `restore_rollback/` beside the live file and expects `media/` to be reachable
  through `MediaStore`. `freshSupportDir()` creates the root; the service creates the rest. Do not
  pre-create `restore_staging/` — a stale staging directory is what step 5 deletes, and pre-creating it
  hides the deletion.
- **`test/support/` is twelve files and the list is closed** (`12 §5.3`). Both members go into
  `harness.dart`. A new `restore_support.dart` is a thirteenth support file acquired by accident.
- **Do not hoist a screen-driving helper in here.** `12 §5.3`: helpers that encode a screen's tap
  sequence are private top-level functions in the single file that uses them. `restoreInto` is not one
  — it drives a service, not a screen — which is exactly why it belongs in the harness and
  `openNewTreatment(tester)` does not.

### 5.4 The full test set

`test/support/harness_test.dart`.

| Case | What it asserts |
|---|---|
| `'freshSupportDir is torn down with the test and restoreInto never touches the real support directory'` | **The anchor.** The directory exists during the test and is gone after it; every file the flow produced is under that path; nothing appeared under the platform's real application-support path |
| `'freshSupportDir returns a different directory for every test'` | Two tests in the same file get two paths — the property randomised ordering depends on |
| `'restoreInto returns a reopened database holding the backup rows'` | Row counts match the file's `counts` |
| `'restoreInto opens the database with configureConnection'` | `PRAGMA journal_mode` is `wal` and `PRAGMA foreign_keys` is on — the same seven pragmas as production (R13) |
| `'restoreInto never calls openAppDatabase'` | Source-text case over `test/support/harness.dart`; the R12 assertion would have thrown anyway, and asserting the absence documents why |
| `'restoreInto leaves no restore_staging or restore.pending behind'` | Two of `04 §7.5`'s nine invariants, in the harness rather than in the flow test |
| `'the database is closed before its directory is deleted'` | Teardown order: register a probe teardown and assert the ordering, because the failure mode is platform-specific and silent on macOS |
| `'a failed restore through restoreInto fails the test rather than returning a broken database'` | Hand it a truncated file: the `expect` inside the wrapper fires, and the message names the wrapper |
| `'restoreFixture and restoreInto call the same service'` | Source-text case: both reach `RestoreService`; there is no third path |
| `'two restoreInto calls in one test do not collide'` | Two `freshSupportDir()` calls, two databases, two teardowns, no `FileSystemException` |
| `'the harness still exposes exactly the members 12 §5.3 lists'` | Source-text case over `harness.dart`: `Device`, `kPumpableVariants`, `testDatabase`, `shedContainer`, `atFixed`, `pumpApp`, `freshSupportDir`, the four fixture id constants — and now `restoreInto`. No thirteenth support file exists |
| `'a restore driven through the harness inside the ambiguous hour is stable'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 on 25 October 2026**. The temp directory name, the restored rows and the reopened database are identical to a run outside the repeated hour. Any harness helper that stamps a time into a path — a dated temp directory, a log line — flakes exactly once a year without this case |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Nothing under `lib/` changes.** If a production file appears in this diff, the harness is being
  used to paper over a design problem in `RestoreService` — stop and fix the service instead.
- **`test/support/` is twelve files and the list is closed** (`12 §5.3`). Both members land in
  `harness.dart`.
- **No `Future.delayed`, no wall-clock assertion, no reliance on ambient `TZ`** outside the tagged
  case (`12 §11.6`). A directory-teardown test is exactly where someone reaches for a sleep.

## 7. Definition of Done

- [ ] `'freshSupportDir is torn down with the test and restoreInto never touches the real support directory'` passes, and was seen to fail first for the stated reason
- [ ] the directory is removed after each test
- [ ] no test writes to the real application support directory
- [ ] `restoreInto` is the only restore entry point tests use
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `freshSupportDir()` is synchronous and registers its own teardown
- [ ] the database is closed before its directory is deleted, and a test asserts the ordering
- [ ] `restoreInto` opens with `configureConnection` and `closeStreamsSynchronously: true`, and never through `openAppDatabase()`
- [ ] `restoreFixture` and `restoreInto` reach the same `RestoreService`; there is no third path
- [ ] both members live in `test/support/harness.dart`; `test/support/` still holds twelve files
- [ ] nothing under `lib/` appears in this diff

## 8. Verification

```bash
fvm flutter test test/support/harness_test.dart
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

# Isolation, proved by ordering rather than by inspection (#121).
fvm flutter test test/support/harness_test.dart --test-randomize-ordering-seed 1
fvm flutter test test/support/harness_test.dart --test-randomize-ordering-seed 2

# Nothing was left behind by the whole suite.
fvm flutter test && ls "$TMPDIR" | grep shed_support   # expect nothing
```

```bash
ls test/support/ | wc -l                                  # expect twelve (12 §5.3)
grep -n  "freshSupportDir\|restoreInto" test/support/harness.dart
grep -rn "openAppDatabase(" test/                         # expect zero
grep -rn "getApplicationSupportDirectory" test/           # expect zero
grep -rn "Future.delayed" test/support/                   # expect zero (12 §11.6)
git diff --stat -- lib/                                   # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(support): restoreInto and freshSupportDir`
