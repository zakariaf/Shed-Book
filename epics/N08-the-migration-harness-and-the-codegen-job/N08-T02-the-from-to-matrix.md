# N08-T02 — The from→to matrix

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 2 of 7 |
| **Depends on** | N08-T01 |
| **Commit** | one commit · `test(drift): the from-to migration matrix` |

## 1. Why this task exists

`SchemaVerifier.migrateAndValidate` on **every** from→to pair, with
`PRAGMA foreign_key_check` returning zero rows afterwards. At v1 the matrix is one cell; the point is
that it exists and iterates a generated list, so v2 costs nothing to cover.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §3.1, §3.2, §3.7 | why every pair and not just the last hop · the test verbatim, on the pinned drift · the gate table |
| `docs/engineering/12-testing.md` | §3.2, §3.4, §11.2, §11.3 | the host sqlite3 floor · the matrix and the snapshot-count test · the `migration` tag and the unverified `-P` question · why randomisation is excluded here |
| `docs/research/00-tech-decisions.md` | §5.1, §5.2, #37, #38 | `drift` 2.34.2 · `drift_dev` 2.34.5 and `api/migrations_native.dart` · a red migration test is ship-blocking |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the verifier and the generated helpers |
| `shed-testing` | the migration tier runs unrandomised and is ship-blocking when red |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/drift/migration_matrix_test.dart`
- **Test** — `'every from-to pair passes migrateAndValidate and foreign_key_check returns zero rows'`
- **Why it is red today** — no matrix exists: nothing iterates the version pairs, so a broken migration step would be found by a shepherd in April rather than by CI in week one.

```bash
fvm flutter test test/drift/migration_matrix_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — iterate the versions from `schema_versions.dart` rather than a typed list, so the count
follows the generated file, and assert `foreign_key_check` empty and `quick_check` `'ok'` after each hop.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 1 item 5 (*"extend the from→to matrix"*) and Step 7. No production code moves; the schema is
frozen and this task must not touch it.

| # | File | What changes, and why |
|---|---|---|
| 1 | `test/drift/migration_matrix_test.dart` | **New.** The matrix, the derived pair enumeration, the two pragma assertions per hop and the snapshot-count test `12 §3.4` puts in this same file. Carries `@Tags(['migration'])`. |
| 2 | `test/drift/generated/schema.dart` | **Read only.** `GeneratedHelper` comes from here. It was written by N07-T08 and is never hand-edited (`00-README` §7.3). Read it to take the real signatures before you write a call. |
| 3 | `drift_schemas/drift_schema_v1.json` | **Read only.** It is what `startAt` builds from and what `migrateAndValidate` compares against. Never hand-edited; losing it is unrecoverable (`00-README` §7.1). |

### 5.2 The signature

`04 §3.2`, on the pinned `drift` 2.34.2 / `drift_dev` 2.34.5 (decision-record §5 is the only source
of a version number in this project):

```dart
// test/drift/migration_matrix_test.dart
@Tags(['migration'])
library;

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';   // NOT api/migrations.dart — banned (#39)
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  // Every from -> to pair, not just N-1 -> N. Decision #38.
  for (var from = 1; from < kSchemaVersion; from++) {
    for (var to = from + 1; to <= kSchemaVersion; to++) {
      test('migrates v$from -> v$to', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase(connection, seedOnCreate: false);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, to);

        final violations = await db.customSelect('PRAGMA foreign_key_check;').get();
        expect(violations, isEmpty, reason: 'FK violations after v$from -> v$to');

        final quick = await db.customSelect('PRAGMA quick_check;').getSingle();
        expect(quick.data.values.first, 'ok');
      });
    }
  }
}
```

The three names that matter and where they come from: `SchemaVerifier` and `migrateAndValidate` from
`package:drift_dev/api/migrations_native.dart`; `GeneratedHelper` from
`test/drift/generated/schema.dart`; `kSchemaVersion` and `AppDatabase` from
`lib/core/db/database.dart` (`CONVENTIONS §2.8`). `verifier.startAt(from)` returns a
`DatabaseConnection` already at that schema version, and you hand it to the **real** database class
so the **real** `MigrationStrategy` runs — a hand-rolled `Migrator` in the test proves nothing.

### 5.3 The details that are easy to get wrong

- **At v1 that nested loop registers zero tests.** `from = 1; from < 1` is false, so the file
  declares no `test()` at all and the runner reports success having run nothing. The anchor named in
  §4 is therefore written as **one `test()` that always runs and iterates the pairs inside its
  body**, driving the same per-hop helper the generated cases use. The generated
  `'migrates v$from -> v$to'` cases stay — they are what gives a v4 failure a readable name — but
  they are additional to the anchor, not a replacement for it. A test file that can silently run
  nothing is worse than no test file, because it is green.
- **The epic's "one cell" is the intent, not the arithmetic.** At `kSchemaVersion == 1` there are
  `1 × 0 ÷ 2 = 0` ordered pairs. What runs at v1 is the anchor, the snapshot-count test and the
  degenerate `startAt(1)` open. That is the correct amount of work and it is worth writing down, so
  nobody "fixes" the loop bounds to manufacture a cell.
- **`migrateAndValidate` validates the terminus, not the path** (`04 §3.1`). It reads every `CREATE`
  out of `sqlite_schema` and compares it semantically against the expected schema at `to`. That is
  exactly why the matrix runs the real composition instead of trusting that `stepByStep` composes
  edges correctly.
- **`PRAGMA foreign_keys` is a no-op inside a transaction, and drift wraps migrations in one**
  (`04 §2.6`). So a step that needs deferred behaviour uses `PRAGMA defer_foreign_keys = ON` inside
  the transaction, and the check that catches the damage is `PRAGMA foreign_key_check` *after* the
  hop — which is what this test runs, on every path, because no generator gives you that.
- **`seedOnCreate: false` is not decoration.** `startAt` does not call `onCreate`, so the flag
  changes nothing at runtime; it is there to document that the first-run season seed is not part of
  what the matrix validates. Leave it in.
- **The `migration` tag's ordering guarantee is `allow_test_randomization: false`, not a seed.** The
  Definition of Done says `test_randomize_ordering_seed: 0`; the mechanism that delivers it is the
  `migration` tag block in `dart_test.yaml` (`12 §11.2`), declared by N01-T04, and the equivalent
  one-off local spelling is `--test-randomize-ordering-seed 0` on the command line. **`12 §11.2`
  carries this as unverified on Flutter 3.44.8**: `flutter test` honours less of `dart_test.yaml`
  than `dart test` does, and whether the tag's `allow_test_randomization: false` actually takes
  effect has not been confirmed. Confirm it in this task — run the file under
  `--test-randomize-ordering-seed random` twice and compare the emitted order — and record the
  answer in `12 §11.2`. If it does not take effect, the named fallback is `--exclude-tags migration`
  in the randomised job plus a separate non-randomised invocation, not removing randomisation.
- **The same check answers the `-P ci-fast` question.** `12 §11.2` and `13 §1.3`/`§4.3` currently
  disagree: 13 invokes `flutter test -P ci-fast`, 12 says `flutter test` has no `-P` flag at all and
  declines to declare presets. Both spellings appear in the backlog. Run the check once here, and
  fix whichever of the two documents is wrong — one of them changes, and both saying different
  things is the only unacceptable outcome.
- **CI needs `libsqlite3-dev` and the host sqlite3 floor is 3.41.0.** `flutter test` runs on the
  **host**, so `sqlite3_flutter_libs` is never applied (`12 §3.2`). The `test` job installs it
  already (N01-T06); `test/data/host_sqlite_version_test.dart` is what turns a runner below the
  floor into a named assertion instead of a mystery. If it fails, the fix is the runner image,
  never the assertion.
- **Do not reach for `testWithDataIntegrity` here.** Data integrity is scoped, not universal
  (#38), and it is N08-T03's task. Quadratic data-integrity tests at v1 are busywork.

### 5.4 The test set

`test/drift/migration_matrix_test.dart` — `@Tags(['migration'])`.

| Case | Asserts |
|---|---|
| `'every from-to pair passes migrateAndValidate and foreign_key_check returns zero rows'` | **anchor.** Always runs. Builds the pair list from `kSchemaVersion`, then for each pair: `startAt(from)` → `AppDatabase(connection, seedOnCreate: false)` → `migrateAndValidate(db, to)` → `PRAGMA foreign_key_check` empty → `PRAGMA quick_check` is `'ok'`. |
| `'migrates v$from -> v$to'` (generated, one per pair) | the same per-hop helper, named so a v4 failure reads as a version pair in the CI log rather than as one long anchor. Zero cases at v1, twenty-eight at v8. |
| `'the pair list holds exactly kSchemaVersion * (kSchemaVersion - 1) / 2 entries'` | the enumeration is derived from the generated version count and never from a typed literal — the DoD's *"derived, never typed"* made executable |
| `'drift_schemas holds exactly kSchemaVersion snapshot files'` | `12 §3.4` puts this in this file. It is what catches a `kSchemaVersion` bumped without a `make gen`, and a bump **by two** (`04 §2.10`), which `stepByStep` has no callback for. Failure message names the fix: run `dart run drift_dev make-migrations`. |
| `'startAt(kSchemaVersion) opens with the FTS5 virtual table present'` | edge case: the v1 schema already carries `search_fts` and its four shadow tables. This is the case that hands N08-T05 its starting point; keep it here as a smoke assertion and let T05 own the verdict. |

**Nothing in this task is time-shaped** — no instant, no civil date, no `appNow()` — so there is no
ambiguous-hour case here. The hop that carries a timestamp across a migration is N08-T03's, and its
DST case is written there.

### 5.5 Verification, in order

```bash
fvm flutter test test/drift/migration_matrix_test.dart --test-randomize-ordering-seed random
fvm flutter test test/drift/migration_matrix_test.dart --test-randomize-ordering-seed random
# the two runs must report the same order; if they do not, the migration tag is
# not taking effect and 12 §11.2's fallback applies. Record the answer there.
fvm flutter test test/data/host_sqlite_version_test.dart
make check
make test
```

## 6. Constraints that bind this task

- **The schema is frozen.** N07-T08 committed `drift_schemas/drift_schema_v1.json` once. This task
  reads it and never regenerates it; `git status --short` at the end must show only the new test file.
- **A red migration test is ship-blocking** (#37). It is not skipped, not `@Skip`-annotated and not
  moved behind a tag that CI excludes.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every from-to pair passes migrateAndValidate and foreign_key_check returns zero rows'` passes, and was seen to fail first for the stated reason
- [ ] the pair list is derived, never typed
- [ ] `foreign_key_check` returns zero rows for every pair
- [ ] the tier runs with `test_randomize_ordering_seed: 0`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/drift/migration_matrix_test.dart
fvm flutter test test/drift/ --test-randomize-ordering-seed random
make check
make test
git status --short          # only the new test file; drift_schemas/ must be untouched
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(drift): the from-to migration matrix`
