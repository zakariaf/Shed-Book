# N08-T03 — `testWithDataIntegrity`, scoped

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 3 of 7 |
| **Depends on** | N08-T02 |
| **Commit** | one commit · `test(drift): scoped data-integrity checks` |

## 1. Why this task exists

Data integrity checked on the N-1→N pair and on any step that rewrites a table — not
on every pair, because a full-data check across every historical pair costs minutes and proves nothing
new.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.6, §2.7, §3.3 | when `TableMigration` is needed and why a rewrite pulls in a data test · what a step may never write · the hand-written integrity test and the raw-SQL-types warning |
| `docs/engineering/03-data-model-and-schema.md` | §3, §4.1, §5.1, §5.2, §5.4 | the dual key and why `uid` is the identity that survives · `INTEGER` instants and `TEXT` civil dates · the exact v1 columns the fixture writes |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §3, and the line at *"the N-1→N data-integrity test is hand-written"* | the scope rule is held by review, not by a scanner — the matrix extends itself and this file does not |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | which steps rewrite a table is a schema fact |
| `shed-testing` | scoping a slow tier by what it can actually catch |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/drift/data_integrity_test.dart`
- **Test** — `'the N-1 to N step preserves every row it rewrites'`
- **Why it is red today** — nothing checks that rows survive a migration.

```bash
fvm flutter test test/drift/data_integrity_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the scoped helper and its one current case: real v1 rows written through the per-version companions, migrated to head, and read back by `uid`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 1 item 5 and Step 7 only. No production code changes; the schema is frozen.

| # | File | What changes, and why |
|---|---|---|
| 1 | `test/drift/data_integrity_test.dart` | **New.** The scope rule as a doc comment that explains itself, the hand-written v1 fixture, and the read-back-by-`uid` assertions. `@Tags(['migration'])`. |
| 2 | `test/drift/data_integrity_ambiguous_hour_test.dart` | **New.** The one time-shaped case, in its own file because it needs `TZ=Europe/London`. `@Tags(['migration', 'uk-zone'])`, with the loud `setUpAll` offset assertion `12 §2.3` requires. |
| 3 | `test/drift/generated/schema_v1.dart` | **Read only.** `DatabaseAtV1`, `SeasonsCompanion`, `EwesCompanion`, `LambingsCompanion` come from here. Generated, never hand-edited. |
| 4 | `test/drift/generated/schema.dart` | **Read only.** `GeneratedHelper` and — if you use it — `testWithDataIntegrity`. Read its real signature here before calling it. |

### 5.2 The signature

`04 §3.3`, written explicitly rather than through a generated helper whose signature you have not read:

```dart
// test/drift/data_integrity_test.dart
@Tags(['migration'])
library;

import 'generated/schema_v1.dart' as v1s;   // the per-version data classes and companions

/// THE SCOPE RULE (decision #38, 04 §3.3), and why it is not "every pair":
///
///   A data-integrity case is required for
///     (a) the N-1 -> N pair, every version, without exception; and
///     (b) EVERY step whose body contains `alterTable` — a TableMigration
///         rebuild copies rows with a generated SELECT, and that is precisely
///         the kind of migration that loses data (04 §2.6).
///
///   It is NOT required for every historical pair. The from->to SCHEMA matrix
///   (test/drift/migration_matrix_test.dart) is the high-value half and it
///   extends itself. THIS FILE DOES NOT. Adding a version means adding a case
///   here by hand, and CODE-REVIEW-CHECKLIST is what holds that — a scanner
///   cannot see whether a rewriting step has a matching case, and a RegExp in
///   a test() is a policy rule that escaped its home (12 §1.4).

test('the N-1 to N step preserves every row it rewrites', () async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final schema = await verifier.schemaAt(kSchemaVersion - 1 < 1 ? 1 : kSchemaVersion - 1);

  // RAW SQL TYPES. `schema generate` does NOT apply type converters, so
  // startDate is a String here and an Instant is an int.
  final old = v1s.DatabaseAtV1(schema.newConnection());
  await old.into(old.seasons).insert(v1s.SeasonsCompanion.insert(
        uid: '019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0',
        year: 2026,
        label: '2026 lambing',
        startDate: '2026-02-01',            // TEXT civil date — decision #29
      ));
  await old.into(old.ewes).insert(v1s.EwesCompanion.insert(
        uid: '019524f8-1d02-7c11-8e77-3ab0c4d19e21',
        tag: '412',
        tagDigits: '412',                   // required: no default (03 §5.2)
      ));
  await old.close();

  final db = AppDatabase(schema.newConnection(), seedOnCreate: false);
  addTearDown(db.close);
  await verifier.migrateAndValidate(db, kSchemaVersion);

  // The uid is the identity that must survive. Not the integer id (03 §3).
  final ewe = await (db.select(db.ewes)
        ..where((t) => t.uid.equals('019524f8-1d02-7c11-8e77-3ab0c4d19e21')))
      .getSingle();
  expect(ewe.tag, '412');
  expect(ewe.status, 'active');   // the v1 column default survived the hops
});
```

The generated `testWithDataIntegrity` helper is permitted, on one condition: **read its signature out
of `test/drift/generated/schema.dart` before you call it.** It is generated code and it tracks the
pinned `drift_dev` 2.34.5. A signature copied from `04 §3.3`, from note 03 or from a blog post will
not compile, and the ten minutes you lose to that is the cheapest part of the mistake.

### 5.3 The details that are easy to get wrong

- **`schema generate` does not apply type converters.** This is the single biggest trap in the file.
  `seasons.start_date` is a `String`, not a `LocalDate`; `lambings.occurred_at` is an `int`, not an
  `Instant`. Passing `Instant(…)` into a v1 companion does not compile, and — worse — computing the
  int with `DateTime.now().millisecondsSinceEpoch` in the fixture makes the test non-deterministic.
  Write the literal, or derive it from an explicit `DateTime.utc(...)`.
- **At v1 there is no N-1.** `kSchemaVersion - 1 == 0` and there is no v0 to start at. The case
  degenerates to *write with the v1 companions, migrate to head (a no-op hop), read back through
  `AppDatabase`*. That is not busywork: it is the only thing in the suite that proves the
  `InstantConverter` and `LocalDateConverter` can read what a raw SQL insert wrote — a converter
  that disagrees with the storage representation is decision #29 breaking silently.
- **`uid`, never `id`.** `AUTOINCREMENT` integer ids are join keys; the `uid` UUID v7 is the export
  identity and the only thing whose survival across a hop means anything (#32). Asserting on
  `id == 1` passes today and lies at v3.
- **A rebuild copies columns untouched.** `04 §2.6`: `await m.alterTable(TableMigration(schema.mediaAssets))`
  with **no** `columnTransformer` is what almost every rebuild in this project looks like. A
  `columnTransformer` is only for a column whose SQL *storage* changes; it is never a way to supply
  a value. And it is never `COALESCE(target, 'meat')` on a withdrawal column — that is what a
  §12.1 violation looks like written as a migration.
- **A migration may never write a domain value.** No withdrawal period, no lambing ease, no birth
  type, no cause of death, no `ewe_seasons.status = 'barren'` (`04 §2.7`, #51, #52, #59). This test
  is one of the two places that failure could be caught, and it only catches it if the fixture
  leaves those columns NULL. Leave them NULL on purpose, and assert they are still NULL afterwards.
- **The scope rule cannot be a scanner.** A `check_policy` rule can see the word `alterTable`; it
  cannot see whether a matching case exists in this file. `12 §1.4` and `CODE-REVIEW-CHECKLIST`
  place it with the reviewer. What this task ships is a doc comment that states the rule and a
  failing example, not a heuristic.
- **The zone-tagged file runs twice, and once under the wrong zone.** `13 §4.3`'s randomised
  `flutter test` step does not exclude `uk-zone`, so the ambiguous-hour file would also run under
  the runner's UTC, where its `setUpAll` offset assertion fails loudly by design. That is the same
  open item `12 §11.2` carries. The fix is `--exclude-tags uk-zone` on the randomised step in
  `ci.yml` (N01-T06's job), **not** deleting the `setUpAll` assertion — *"a skipped safety test is a
  broken safety test"*.

### 5.4 The test set

`test/drift/data_integrity_test.dart` — `@Tags(['migration'])`.

| Case | Asserts |
|---|---|
| `'the N-1 to N step preserves every row it rewrites'` | **anchor.** Seasons and Ewes written with the v1 companions; after `migrateAndValidate(db, kSchemaVersion)` the ewe is found by `uid` with `tag == '412'` and `status == 'active'`, and the season by `uid` with `start_date == '2026-02-01'` unchanged as a `TEXT` civil date. |
| `'a row count is preserved across every rewriting step'` | for each hop in the declared rewriting-step list, `COUNT(*)` per affected table before and after are equal. At v1 the list is empty and the case asserts the list is empty, so it cannot silently pass by iterating nothing. |
| `'a migration writes no withdrawal period, ease, birth type or cause of death'` | the fixture leaves `lambings.ease`, `lambings.declared_birth_type` and the treatment-withdrawal columns NULL; all are still NULL at head. The one §12.1 property this tier can hold. |
| `'the uid survives and the integer id is not asserted on'` | round-trips both fixture rows by `uid`; a deliberate second insert proves `AUTOINCREMENT` did not renumber the first |
| `'a rewriting step that loses a row fails this test'` | run once by hand: plant a `TableMigration` whose copy drops a row, watch the case go red, revert. The DoD line made real. |

`test/drift/data_integrity_ambiguous_hour_test.dart` — `@Tags(['migration', 'uk-zone'])`, with
`setUpAll` asserting `DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` and the reason
*"Run this file with TZ=Europe/London"*.

| Case | Asserts |
|---|---|
| `'a lambing recorded in the repeated hour keeps its instant, its local date and its provenance across a migration'` | writes a v1 `lambings` row with `occurred_at` at **01:30 on 25 October 2026** — an hour that happens twice — as an explicit epoch-millis literal, one of `DateTime.utc(2026, 10, 25, 0, 30)` (BST) or `DateTime.utc(2026, 10, 25, 1, 30)` (GMT), with `captured_at` set, `original_effective` NULL and `time_source` `'auto'`. After `migrateAndValidate` all four columns are **byte-identical** and `local_date` is still `'2026-10-25'`. A migration never rewrites a timestamp or its provenance, and it never recomputes the denormalised civil date (#53, `04 §2.7`). |
| `'the spring-forward hour is stored and read back unchanged'` | the same row shape at **01:30 on 29 March 2026**, an hour that never happens locally. The stored value is an opaque instant, so the hop must not care — and if a future step ever tries to re-derive `local_date` in SQL, this is the case that catches it. `CURRENT_TIMESTAMP` and `date('now')` are banned everywhere including migrations (#47). |

### 5.5 Verification, in order

```bash
fvm flutter test test/drift/data_integrity_test.dart
TZ=Europe/London fvm flutter test test/drift/data_integrity_ambiguous_hour_test.dart
fvm flutter test test/drift/                        # the whole migration tier together
make check
make test
```

## 6. Constraints that bind this task

- **Never a domain value** — `04 §2.7`. The fixture leaves every advice-bearing column NULL, and
  the test asserts it stays NULL. A `columnTransformer` that supplies one is a §12.1 violation.
- **Provenance travels as a unit** — `occurred_at`, `captured_at`, `original_effective` and
  `time_source` move together or not at all (#53, `CONVENTIONS` R37).
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the N-1 to N step preserves every row it rewrites'` passes, and was seen to fail first for the stated reason
- [ ] the scope rule is in the source and explains itself
- [ ] a rewriting step that loses a row fails the test
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/drift/data_integrity_test.dart
TZ=Europe/London fvm flutter test test/drift/data_integrity_ambiguous_hour_test.dart
fvm flutter test test/drift/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(drift): scoped data-integrity checks`
