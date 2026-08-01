# N08-T01 — `migrations.dart` — the `stepByStep` scaffold

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 1 of 7 |
| **Depends on** | N07-T08 |
| **Commit** | one commit · `feat(db): the stepByStep migration scaffold and its five rules` |

## 1. Why this task exists

The migration strategy with the five migration rules carried on it as a doc comment
where the next person will actually read them: forward-only, additive, never destructive, no
`DROP COLUMN`, no changing a column's meaning in place.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.1, §2.3, §2.5, §2.7, §2.10 | the five rules verbatim · the `MigrationStrategy` object · what `migrations.dart` is, and that it is the only hand-edited file in that package · what a step may and may not write · the gates that catch the rest |
| `docs/engineering/CONVENTIONS.md` | §1, §2.8, §4.7, R14, R16 | `lib/core/db/migrations.dart` is in the tree · `AppDatabase`'s two named parameters · the rule id is `db.destructive_ddl`, not 04's `no_destructive_ddl` |
| `docs/engineering/12-testing.md` | §1.4, §3.4, §11.2 | a source scan belongs in the gate and never inside a `test()` · the migration tier · the `migration` tag and its `allow_test_randomization: false` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the strategy object and its registration |
| `shed-migrations` | runbook, invoked by name — it owns the five rules quoted here |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/drift/migrations_test.dart`
- **Test** — `'stepByStep is the only migration strategy and no step runs a destructive statement'`
- **Why it is red today** — there is no migration file; a v2 would have nowhere to land.

```bash
fvm flutter test test/drift/migrations_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the scaffold, the doc comment, and an assertion that proves the property structurally: every table present at `from`, and every column of it read off `PRAGMA table_info`, is still present at `to`, for every pair the version count yields.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

This task is entirely §8 **Step 1 (schema)** and **Step 7 (tests)**. It reaches no domain, no data,
no wiring, no controller, no UI and no ARB layer — say so in the commit body, per §8's instruction to
name a skipped layer out loud.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/migrations.dart` | **New.** `04 §2.5` marks this the one file in `lib/core/db/` whose *Hand-edited?* column says **Yes**. It holds the five rules as a doc comment and the `from<N>To<N+1>` bodies. At v1 there are no bodies — there is no hop — so what lands is the comment, the imports and the registry the strategy calls. |
| 2 | `lib/core/db/database.dart` | **Edit.** `MigrationStrategy get migration` gains its real `onUpgrade`, wired to (1) instead of the commented-out `from1To2` stub `04 §2.3` ships. `onCreate` and `beforeOpen` came in with N07-T02 and are not touched. |
| 3 | `test/drift/migrations_test.dart` | **New.** The anchor plus the four cases in §5.4. Carries `@Tags(['migration'])`. |

Nothing under `drift_schemas/`, `lib/core/db/schema_versions.dart` or `test/drift/generated/`
changes. Those were frozen by N07-T08 and this task adds no schema version.

### 5.2 The signature

The target shape, assembled in `database.dart` exactly as `04 §2.3` has it, with the bodies next door:

```dart
// lib/core/db/database.dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        if (seedOnCreate) await seedFirstRun(this);   // decision #42
      },
      onUpgrade: shedStepByStep(),                    // lib/core/db/migrations.dart
      beforeOpen: (details) async {
        if (kDebugMode) {
          await validateDatabaseSchema();             // #39 — awaited, never inside an assert
        }
      },
    );
```

```dart
// lib/core/db/migrations.dart — the ONE hand-written file in this package (04 §2.5).
//
// THE FIVE RULES (04 §2.1). They are here, not only in a document, because this
// is the file the next person opens at 22:00 with a column to add.
//
// 1. Forward-only. kSchemaVersion goes up by EXACTLY one. Never down, never by
//    two: stepByStep has no callback for a skipped hop. A downgrade fails
//    loudly and never runs — the guarantee is ours, asserted by
//    test/drift/downgrade_test.dart, not quoted from a drift version number.
// 2. Additive by default. m.createTable, m.addColumn, m.createIndex. That is
//    the whole vocabulary of a normal migration.
// 3. Never destructive on user data. No DROP COLUMN, no DROP TABLE, ever, on a
//    table that has held a shepherd's records. A column that must die stops
//    being written and stays. A table that must die is renamed
//    <name>_deprecated_v<N> and dropped no earlier than two major versions
//    later, with a line in tool/policy_allowlist.txt naming the table, the
//    version that deprecated it and the version that drops it. No line, no drop.
// 4. Never change a column's meaning in place. New meaning => new column =>
//    new name. "kg x 10" becoming "grams" is silent corruption no test catches
//    and no user notices until the season summary is wrong.
// 5. Bump, generate and test in ONE commit. kSchemaVersion, the new step, the
//    regenerated snapshot and the regenerated helpers land together or not at
//    all. The codegen job (N08-T06) is what enforces it.
//
// A step may write STRUCTURAL values only (04 §2.7): 0, NULL, '', a value
// copied from another column, newUid(), appNow(). It may NEVER write a
// withdrawal period, a lambing ease, a birth type, a cause of death, or
// ewe_seasons.status = 'barren'. CI cannot see that one. The reviewer can.

/// The project's single migration entry point. Every callback takes the
/// HISTORICAL `schema`, never `db` and never a table class from today's
/// `database.dart` — that is the whole mechanism that stops a v1-to-v2 step
/// breaking on the day a column is added in v9 (gate rule `db.migration_today_schema`).
OnUpgrade shedStepByStep() => stepByStep(
      // from1To2: (m, schema) async {
      //   await m.addColumn(schema.ewes, schema.ewes.eid);
      // },
    );
```

**Read `lib/core/db/schema_versions.dart` before you type that call.** It is generated, N07-T08
committed it, and it tracks the pinned `drift_dev` 2.34.5. `04 §3.3` states the rule for the
generated helpers and it applies identically here: never copy a generated signature out of a
document. If `drift_dev schema steps` emitted no `stepByStep` at v1 because there is no step to
compose, that is a finding and not a blocker — record it in `04 §2.3`, leave `onUpgrade` as the
generated file allows, and land the doc comment and the tests anyway. The rules and the
never-destructive assertion are the deliverable; the callback registry is what they protect.

### 5.3 The details that are easy to get wrong

- **A `RegExp` inside a `test()` is a policy rule that escaped its home.** `12 §1.4`:
  *"if the assertion can be made by reading source text, it belongs in `tool/check_policy.dart`, not
  in `test/policy/`."* Grepping `migrations.dart` for `DROP` is precisely that. The scan already
  exists as gate rule `db.destructive_ddl` (N03), and this task's job is to **prove the gate fires**
  by running `tool/check_policy.dart` over a planted fixture — not to re-implement it. A second
  scanner acquires its own allowlist, drifts out of sync with the real one, and is eventually
  weakened by whoever is unlucky enough to hit its first false positive.
- **The rule id is `db.destructive_ddl`.** `04 §2.10` still spells it `no_destructive_ddl`;
  `CONVENTIONS §4.7` renamed every one of 04's ids to dotted `namespace.name` under R54, and
  CONVENTIONS outranks 04 on any name. Typing 04's spelling gets a rule id no table row matches.
- **At v1 the derived pair list is empty.** `for (var from = 1; from < kSchemaVersion; from++)`
  runs zero times when `kSchemaVersion == 1`. A file whose only `test()` calls are generated inside
  that loop registers **no tests at all** and reports success having run nothing. The anchor is
  therefore one `test()` that always runs and iterates the pairs *inside its body* — so the file is
  never vacuous — and it asserts the pair list is the derived one rather than a typed one.
- **`m.createAll()` in `onUpgrade` is the classic wrong fix.** It is what a developer reaches for
  when a migration fails on a fresh install. It silently recreates the world and the shepherd's rows
  are gone. `createAll` belongs in `onCreate` and nowhere else.
- **`beforeOpen` is not this task's, and its hazard is a gate rule.**
  `assert(() { validateDatabaseSchema(); return true; }())` starts a `Future`, returns `true`
  immediately, and surfaces a schema mismatch as an unhandled async error long after `beforeOpen`
  completed. Decision #39 bans it; `db.async_in_assert` catches it; no test here duplicates that.
- **`kDebugMode` is what tree-shakes `drift_dev` out of release.** `database.dart` is the one file
  in `lib/` that imports a dev dependency (`package:drift_dev/api/migrations_native.dart`). It is
  allowlisted, and the deprecated `api/migrations.dart` is banned outright (#39). Do not add a
  second import of it in `migrations.dart` "for symmetry".
- **Nothing in this task is time-shaped.** No instant, no civil date, no `appNow()` call, no stored
  timestamp — so there is no ambiguous-hour case to write here. The DST cases land in N08-T03 (a
  provenance quad crossing a hop) and N08-T07 (the snapshot filename's stamp).

### 5.4 The test set

`test/drift/migrations_test.dart` — `@Tags(['migration'])` at library level, so `dart_test.yaml`'s
`allow_test_randomization: false` and `timeout: 2x` apply (`12 §11.2`). The tag must already be
declared in `dart_test.yaml` by N01-T04, or a `--tags` filter matches nothing and the run is green
because it ran nothing.

| Case | Asserts |
|---|---|
| `'stepByStep is the only migration strategy and no step runs a destructive statement'` | **anchor.** `AppDatabase(connection).migration.onUpgrade` is the generated composition and never a hand-written `(m, from, to)` that calls `createAll`; and for every derived `from`→`to` pair, every table name in `sqlite_schema` at `from` is still present at `to`, and every column of each of those tables, read off `PRAGMA table_info`, is still present at `to`. At v1 the pair list is empty and the assertion runs against v1 alone. |
| `'the pair list is derived from kSchemaVersion and never typed'` | the enumeration holds exactly `kSchemaVersion * (kSchemaVersion - 1) ~/ 2` entries — the closed form, so adding v2 cannot leave a hand-typed list behind |
| `'onCreate creates every table and seeds only when seedOnCreate is true'` | two opens against `NativeDatabase.memory()`, `seedOnCreate: true` then `false`; the second has the full schema and **no** season row. The restore path depends on this (`04 §7`), and a phantom "2026 lambing" nobody created is the failure it prevents. |
| `'check_policy exits 1 on a planted DROP COLUMN under lib/core/db/'` | runs `dart tool/check_policy.dart` as a process over a temp tree carrying one planted violation; asserts a non-zero exit and `db.destructive_ddl` in the output; deletes the fixture. Watch it fail once by hand before automating it. |
| `'migrations.dart carries all five rules'` | the file exists and its doc comment names each of the five. This is the one place a text assertion is correct, because the property *is* the prose. |

### 5.5 Verification, in order

```bash
fvm flutter test test/drift/migrations_test.dart   # the anchor and its four companions
dart tool/check_policy.dart                    # db.destructive_ddl still exits 0 on the real tree
make check                                         # gate, format, analyze --fatal-infos
make test                                          # whole suite, randomised, plus the UK-zone run
```

## 6. Constraints that bind this task

- **Never destructive** — `04 §2.1` rule 3. `DROP COLUMN` and `DROP TABLE` appear nowhere in this
  diff, including in a commented-out example. The gate does not read intent.
- **One writer, one package** — `customStatement(` is legal only inside `lib/core/db/` (layer rule
  8). Nothing in this task needs it.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'stepByStep is the only migration strategy and no step runs a destructive statement'` passes, and was seen to fail first for the stated reason
- [ ] `stepByStep` is the only strategy
- [ ] the five rules are in the source, not only in a document
- [ ] a planted `DROP COLUMN` fails the test
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/drift/migrations_test.dart
dart tool/check_policy.dart
make check
make test
git status --short          # nothing generated moved: this task adds no schema version
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): the stepByStep migration scaffold and its five rules`
