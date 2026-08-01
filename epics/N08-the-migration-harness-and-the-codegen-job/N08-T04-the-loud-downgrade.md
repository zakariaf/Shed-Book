# N08-T04 — The loud downgrade

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 4 of 7 |
| **Depends on** | N08-T03 |
| **Commit** | one commit · `feat(db): refuse a database written by a newer schema, loudly` |

## 1. Why this task exists

A database file written by a **newer** schema on an older build must fail loudly and
never open. Silently opening it is how a shepherd loses a season: the newer columns are invisible, the
next write drops them, and the backup that would have saved it was never made.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.1 rule 1, §2.3, §2.8, §3.5, §3.7 | forward-only and *"the guarantee is ours"* · `schemaVersionOverride` · what `configureConnection` already runs · the downgrade test and its skip · the gate table |
| `docs/engineering/01-architecture.md` | §5 | the six `ShedFailure` variants, their `userMessage` strings, `shedFailureFrom` and the `DriftRemoteException` unwrap |
| `docs/engineering/CONVENTIONS.md` | §2.5, §2.8, §5.3, R13, R14 | the failure catalogue · `configureConnection`'s fixed pragma order · `schemaVersionOverride` is `@visibleForTesting` and final · `Error` is a banned failure-type name |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the version check and where it belongs in the open path |
| `shed-bootstrap-and-errors` | the failure has to surface as a `ShedFailure`, not a raw exception |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/drift/downgrade_test.dart`
- **Test** — `'a database written by a newer schema fails loudly and never opens'`
- **Why it is red today** — nothing checks the direction of the version difference.

```bash
fvm flutter test test/drift/downgrade_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the check in the open path and a readable failure a shepherd could act on: `user_version` and the file length unchanged, and a message that says update the app.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 1 (schema, the open path), Step 3 (the failure mapping, which lives in `lib/data/`) and Step 7.
No domain, no controller, no UI, no ARB — the six `userMessage` strings are the only user-facing text
outside the ARB in v1 (`01 §5`), so this task adds no ARB key. Say so in the commit body.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/connection.dart` | **Edit.** `configureConnection(CommonDatabase db)` gains one guard: if `db.userVersion > kSchemaVersion`, throw. It runs after `_assertEngineCapabilities(db)` and **before** `_snapshotBeforeMigration(db)` — this is the last point on the open path before drift's migration begins, and it is outside any transaction. |
| 2 | `lib/core/failure.dart` | **Edit, and only after the ruling in §5.3.** A variant whose `userMessage` says *update the app*. Six variants exist and none of them says that. |
| 3 | `lib/data/failure_mapping.dart` | **Edit.** `shedFailureFrom` classifies the refusal. It already unwraps `DriftRemoteException` once before the `switch`; the new case sits alongside the `SqliteException` arm, not inside it — a downgrade is not a SQLite result code. |
| 4 | `test/drift/downgrade_test.dart` | **New.** `@Tags(['migration'])`, the anchor, the self-cancelling skip and the mapping cases. |

### 5.2 The signature

```dart
// lib/core/db/connection.dart — inside configureConnection, after the seven
// pragmas and _assertEngineCapabilities, before _snapshotBeforeMigration.
//
// Forward-only, rule 1 (04 §2.1). `stepByStep` is UNDERSTOOD to throw on a
// downgrade, but the drift version that introduced that behaviour is not in
// decision-record §5 and is not quoted here from memory. The guarantee is
// OURS: this line, plus test/drift/downgrade_test.dart, on the pinned
// drift 2.34.2 / drift_dev 2.34.5.
void _refuseNewerSchema(CommonDatabase db) {
  final onDisk = db.userVersion;
  if (onDisk <= kSchemaVersion) return;
  // Two integers we own. NEVER the SQLite exception message — those echo the
  // failing SQL and sometimes bound values: ewe tags, batch numbers (#124).
  throw SchemaTooNew(fileVersion: onDisk, appVersion: kSchemaVersion);
}
```

```dart
// test/drift/downgrade_test.dart — 04 §3.5.
// AppDatabase exposes `schemaVersionOverride` ONLY in this file's eyes: it is a
// @visibleForTesting final field defaulting to kSchemaVersion, with
// `int get schemaVersion => schemaVersionOverride`. There is no setter and no
// path from the UI (R14). Do not add one.
test('a database written by a newer schema fails loudly and never opens', () async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final connection = await verifier.startAt(kSchemaVersion);      // the newer file

  final old = AppDatabase(connection,
      seedOnCreate: false, schemaVersionOverride: kSchemaVersion - 1);
  addTearDown(old.close);

  await expectLater(
    old.customSelect('SELECT 1;').getSingle(),                    // forces the open
    throwsA(isA<SchemaTooNew>()),
  );
}, skip: kSchemaVersion == 1
    ? 'no lower version to pretend to be until v2 exists — 04 §3.5'
    : false);
```

### 5.3 The details that are easy to get wrong

- **`ShedFailure` has six variants and none of them says "update the app".** `DatabaseUnreadable`'s
  message is *"Shed Book cannot read its records file. Do not delete the app. Open Settings ›
  Diagnostics to save a copy of what is there."* — which is wrong here twice over: the file is
  perfectly readable, and saving a copy is not the action. `UnexpectedFailure`'s message cannot say
  it either. **A seventh variant is a `CONVENTIONS §2.5` change and therefore a ruling** (R8 plus the
  amendment rule): a numbered ruling in `CONVENTIONS §6`, §2.5 updated, `01 §5` updated, and the
  count corrected wherever "six variants, six `userMessage` strings" appears — all in this commit.
  Route it to the owner before you write the mapping. Name it `SchemaTooNew`: `Error` as a
  failure-type name is banned outright (`CONVENTIONS §5.3`).
- **The guard changes a list `CONVENTIONS` R13 fixes.** R13 rules that `configureConnection` runs
  seven pragmas, then `_assertEngineCapabilities`, then `_snapshotBeforeMigration`, *"in the order
  above"*, and that dropping any is a regression. Inserting a line means R13's list, `03 §1.3` and
  `04 §2.8` all say something different from the code unless they are edited in the same commit.
  Edit them.
- **Do the test first, and let it tell you whether the guard is even load-bearing.** On the pinned
  drift, `stepByStep` may already throw. The guard is added regardless, for two reasons: the
  library's throw carries no message a shepherd can act on, and a future drift bump must not be able
  to silently remove the behaviour. What the test result changes is the commit body, not the diff.
- **`throwsA(anything)` is too weak, and `04 §3.5`'s own example uses it.** Sharpen it: assert the
  thrown type, then assert nothing moved — `PRAGMA user_version` is the same integer afterwards, the
  file length is unchanged, and the `sqlite_schema` row set is identical before and after the
  refused open. That is the DoD's *"no data is written to the file before the check"* made
  executable, and it is the half a bare `throwsA` cannot see.
- **`schemaVersionOverride: 0` is not "one version behind".** At v1, `kSchemaVersion - 1 == 0`, and
  SQLite treats `user_version == 0` as a brand-new file, so a build claiming schema version 0 would
  run `onCreate` and `createAll` over the top of real tables. That is why `04 §3.5` skips the test
  at v1 rather than lowering the bound.
- **Make the skip cancel itself.** A skipped safety test that nobody notices at v2 is worse than no
  test. Ship a second case that always runs and fails the moment v2 lands, naming the file and the
  line to change. `04 §3.5`: *"make it unskippable in the same commit that introduces v2."*
- **The production throw arrives wrapped; the test's does not.** `drift_flutter` runs SQLite on a
  background isolate, so `shedFailureFrom` unwraps `DriftRemoteException.remoteCause` **once**
  before classifying (`01 §5`). `verifier.startAt()` builds an in-process connection with no
  isolate, so the test sees the raw throw. A mapping that only handles the raw shape passes here and
  fails on a phone. Write a case that feeds `shedFailureFrom` the wrapped form explicitly.
- **The screen is not this task's.** The failure surfaces through the global error net (#14) as the
  dark `lib/core/ui/night_error_panel.dart`, which owns its own hexes and its own `Directionality`.
  This task supplies the failure and its message; N11 owns the panel.
- **Nothing here is time-shaped.** `user_version` is an integer, not an instant. There is no
  ambiguous-hour case in this task.

### 5.4 The test set

`test/drift/downgrade_test.dart` — `@Tags(['migration'])`.

| Case | Asserts |
|---|---|
| `'a database written by a newer schema fails loudly and never opens'` | **anchor.** `startAt(kSchemaVersion)`, opened by a build with `schemaVersionOverride: kSchemaVersion - 1`, throws on the first statement. Skipped while `kSchemaVersion == 1`, with the reason in the skip string. |
| `'the downgrade test stops being skipped at v2'` | always runs. Fails the moment `kSchemaVersion > 1` while the skip is still unconditional, naming `test/drift/downgrade_test.dart` and the skip expression to delete. |
| `'the refused open leaves user_version, the file length and sqlite_schema unchanged'` | opens a real temp-file database (not `:memory:`), records the three, provokes the refusal, re-reads all three. Nothing moved. |
| `'shedFailureFrom maps the refusal to a failure whose message tells the shepherd to update the app'` | the mapped `ShedFailure`'s `userMessage` contains the instruction and contains no result code, no SQL and no exception text |
| `'shedFailureFrom unwraps a DriftRemoteException before classifying the refusal'` | the same throw wrapped once maps to the same variant — the production shape, which the anchor cannot reach |
| `'the two version numbers are logged and the exception message is not'` | `LocalLog` receives `fileVersion` and `appVersion`; it receives no substring of the SQLite message (#124) |
| `'an equal version and an older file both open normally'` | the guard's boundary: `userVersion == kSchemaVersion` opens, `userVersion < kSchemaVersion` migrates. A `>=` typo here refuses every launch, which is the worst possible way to be safe. |

### 5.5 Verification, in order

```bash
fvm flutter test test/drift/downgrade_test.dart     # skipped at v1 except the self-cancelling case
fvm flutter test test/drift/                        # the tier together
fvm flutter test test/data/                         # failure_mapping's own tier
make check
make test
```

At v1 the end-to-end rehearsal — build a v(N) file, open it with a v(N-1) build — cannot be
performed, and pretending otherwise is how the skip gets forgotten. It becomes a
`CODE-REVIEW-CHECKLIST` item on the commit that introduces v2.

## 6. Constraints that bind this task

- **Forward-only** — `04 §2.1` rule 1. The refusal is not a repair, not a rollback and not a
  "migrate backwards"; nothing in this diff writes to a newer file.
- **Never leak SQLite text** — decision #124. Two integers we own, into the diagnostics log; nothing
  from the exception, ever, into the log or into `userMessage`.
- **The failure catalogue is `CONVENTIONS §2.5`'s** — a seventh variant is a ruling, not a
  refactor, and `Error` is a banned failure-type name.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a database written by a newer schema fails loudly and never opens'` passes, and was seen to fail first for the stated reason
- [ ] the newer file never opens
- [ ] the message says what happened and what to do
- [ ] no data is written to the file before the check
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/drift/downgrade_test.dart
fvm flutter test test/drift/
fvm flutter test test/data/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): refuse a database written by a newer schema, loudly`
