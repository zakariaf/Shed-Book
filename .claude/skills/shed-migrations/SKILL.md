---
name: shed-migrations
description: >-
  Writes a Shed Book schema migration — the hand-written forward-only additive from-to step,
  drift_dev schema steps, the regenerated snapshot and test helpers that land in the same commit,
  and the extension of the from-to verifier matrix. This creates a schema snapshot that is
  irreversible once committed, so it runs only when the developer asks for it by name.
disable-model-invocation: true
---

# Writing a Shed Book schema migration

A runbook, invoked by name only: it writes `drift_schemas/drift_schema_v<N>.json`, and a committed
snapshot plus a released step are on someone's phone forever — no server, no backfill, no cloud copy.
`docs/engineering/04-migrations-media-backup-restore.md` §2–§3 is the authority and carries the
reasoning; read the section you touch. The step body is the **one hand-written file** under
`lib/core/db/`: `migrations.dart` (`CONVENTIONS.md` §1). Choosing the column, and running `make gen`,
belong to **`shed-drift-schema`** — `make gen` is not banned here, it is owned there. Run it.

## The five rules (04 §2.1) — none is negotiable

1. **Forward-only.** `kSchemaVersion` in `lib/core/db/database.dart` rises by **exactly one**; never
   down, never by two — `stepByStep` has no callback for a skipped hop.
2. **Additive.** `m.createTable`, `m.addColumn`, `m.createIndex` is the whole vocabulary.
3. **Never destructive on user data.** No `DROP COLUMN`, no `DROP TABLE`, ever, on a table that held
   records. A dead column is one you stop writing; a dead table is renamed `<name>_deprecated_v<N>`
   and dropped no earlier than two major versions later — legal only with a `tool/policy_allowlist.txt`
   line naming the table, the version that deprecated it and the version that drops it.
4. **Never change a column's meaning in place.** New meaning ⇒ new column ⇒ new name. "kg × 10" that
   becomes "grams" is corruption no test catches until a season summary is wrong.
5. **Bump, generate and test in ONE commit** (00-README §7.1, §7.4). CI re-runs the generators and
   fails on any diff.

## The ritual (04 §2.4)

```bash
# 0. git status empty.  1. edit lib/core/db/tables/*.dart  (shed-drift-schema)
# 2. bump kSchemaVersion by one.  3. add from<N>To<N+1> to stepByStep() in migrations.dart.
make gen                                      # 4. build_runner + drift_dev make-migrations
flutter test test/drift/                      # 5. a red matrix is ship-blocking
git add lib/core/db drift_schemas/ test/drift/ && git commit -m "schema v<N+1>: add <thing>"
```

`make-migrations` wraps `schema dump` / `schema steps` / `schema generate` (04 §2.4 if you need one
alone). **Nothing under `drift_schemas/` or `test/drift/generated/` is ever hand-edited** — it is
generated evidence, so `SchemaVerifier` can still build a v1 database in 2029.

## What a step may and may not write (04 §2.7)

**May:** structural values only — `0`, `NULL`, `''`, a value copied from another column, `newUid()`,
`appNow()`. **May never:** a domain value the user did not enter. CI cannot catch this; review does.

- No withdrawal period and no withdrawal target — no default, no inference, no `COALESCE(target,
  'meat')`. No row reads as `WithdrawalNotRecorded`, which is the **correct** answer (§12.1, #51/#52).
- No inferred lambing ease, birth type, cause of death or `barren` outcome (§12.4, R42).
- No "repairing" a contradiction: three lambs against a declared `twin` stays that way; the badge is
  computed on read (#54).
- Moving an instant copies `effective`, `captured_at`, `original_effective` and `time_source` as one
  unit (#53, R37). No SQL-side time — `CURRENT_TIMESTAMP`, `date('now')`, `datetime('now')` (#47).

## When `ALTER TABLE` is not enough (04 §2.6)

A `CHECK` change, type tightening, new `NOT NULL` or FK change needs SQLite's 12-step rebuild.
**Do not hand-roll it** — the naive rename/create/copy/drop order corrupts references in triggers,
views and FK constraints. Use `await m.alterTable(TableMigration(schema.mediaAssets));`, almost always
with **no `columnTransformer`**: that is only for a column whose SQL *storage* changes, never a way to
supply a value, and #29 froze the temporal representations at v1 so none is planned.

## Extending the matrix (04 §3.1–§3.6)

`test/drift/migration_matrix_test.dart` loops **every** from→to pair, not just N-1→N (#38): for each,
`verifier.startAt(from)` → the real `AppDatabase(connection, seedOnCreate: false)` →
`migrateAndValidate(db, to)` → `PRAGMA foreign_key_check` **returns zero rows** → `PRAGMA quick_check`
is `'ok'`. The loop bounds are `kSchemaVersion`, so a new version adds no code — but these follow it:

- A data-integrity test for **N-1→N**, and for **any** step containing `alterTable` (#38).
- `test/drift/downgrade_test.dart` is skipped only while `kSchemaVersion == 1`; the commit that
  introduces v2 makes it unskippable.
- A test asserting `drift_schemas/` holds exactly `kSchemaVersion` files — this catches a bump by two.
- The CI codegen no-diff step (§3.6) proves the committed snapshot describes the committed schema.
  Every other migration test rests on it.

## Gotchas — these compile, then fail

- **A step reads `schema.ewes`, never `db.ewes` and never today's table class.** The historical schema
  handed to the callback is the entire mechanism stopping a v1→v2 step breaking the day v9 adds a
  column. `check_policy` rule `db.migration_today_schema` (R54).
- **`PRAGMA foreign_keys` is a no-op inside a transaction, and drift wraps migrations in one.** For
  deferred FK behaviour use `PRAGMA defer_foreign_keys = ON` inside it and close the step with
  `PRAGMA foreign_key_check`.
- **`migrateAndValidate` validates the terminus, not the path** — it diffs `sqlite_schema` against the
  expected schema at `to`. That is exactly why every *pair* runs, not every edge.
- **FTS5 shadow tables are UNVERIFIED (04 §3.4).** `search_fts_data/_idx/_docsize/_config` appear in
  `sqlite_schema` and nobody has checked whether `SchemaVerifier` tolerates them. Write the matrix with
  FTS5 present in schema v1, in week one, with zero real rows; if it rejects them, decide then and
  record the outcome in §3.4. **Never** disable the assertion.
- **Import `package:drift_dev/api/migrations_native.dart`**; the deprecated `api/migrations.dart` is
  banned (#39). `drift` and `drift_dev` are pinned in decision-record §5 — the only source of a
  version number in this project, and **shed-dependencies-and-toolchain**'s to change.
- **`startAt` does not call `onCreate`**, so pass `seedOnCreate: false` explicitly.
- **`drift_dev schema generate` does not apply type converters**: in a v1 data-integrity test a civil
  date is a `String` and an instant is an `int`. Read a generated helper's signature out of
  `test/drift/generated/schema.dart` before calling it; never copy one from a doc.
- **The pre-migration `VACUUM INTO` snapshot (04 §2.8) must already exist before your step ships** —
  in `configureConnection` in `lib/core/db/connection.dart` (R12/R13), once per upgrade, bounded at
  250 MB, outside any transaction, refusing to overwrite a non-empty file, never rethrowing. It is a
  diagnostics artefact for `tool/snapshot_to_backup.dart`, **not** a second restore path (#84, #73).

## When you get it wrong (04 §2.9)

Stop the staged rollout first, then reproduce from a snapshot in a test before touching code. **Never
edit the committed step or the committed snapshot** — phones that ran it will not run it again, so an
edit splits the fleet into two schemas carrying the same version number, the worst state this system
can reach. Ship the repair as a **new step at N+1** that may re-derive a structural value and may not
invent a domain one. If data was lost, say so on the affected records: §12.4 forbids silent correction
and equally forbids silent loss. The regression test is permanent.

## Do NOT use for

- **The table, column, CHECK, index, converter or storage kind — and `make gen`** → `shed-drift-schema`.
  That skill decides what a column *is*; this one writes the hop between two versions.
- A column or type **spelling** → `shed-conventions`. Cite R37/R38; never retype a name.

## Definition of done

- [ ] `kSchemaVersion` rose by exactly one; exactly one new `from<N>To<N+1>` in
      `lib/core/db/migrations.dart`; no committed step or snapshot was edited.
- [ ] The body touches `schema.*` only — no `db.`, no today's table class, no `DROP`, no SQL-side
      time, and no value the shepherd did not enter.
- [ ] `make gen` ran; `drift_schemas/` holds exactly `kSchemaVersion` files; nothing generated was
      hand-edited.
- [ ] Every from→to pair validates with `foreign_key_check` empty and `quick_check` `'ok'`; N-1→N and
      every `alterTable` hop have a data-integrity test; the downgrade test is unskipped from v2 on.
- [ ] `flutter test test/drift/` green, and re-running the generators leaves
      `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` clean — all in ONE commit.

**Read `examples/migration_step.dart` when writing the step body** — a complete forward-only additive
`from<N>To<N+1>` with this project's exact imports and the historical-schema trap marked inline. It is
an excerpt to adapt, never a file to copy: `lib/core/db/migrations.dart` is the real file and is
authoritative the moment it exists.
