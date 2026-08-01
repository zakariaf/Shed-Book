---
name: shed-drift-schema
description: >-
  How a fact is stored, and the only skill that runs codegen — including how time and units are
  encoded. Use for any table, column, index, view or named query, and whenever make gen,
  build_runner or a regenerated .g.dart or .drift.dart file is involved. Do NOT use for a column's
  spelling (shed-conventions) or a migration step (shed-migrations).
---

# Storing a fact in Shed Book

## The strike is part of the schema (`CONVENTIONS` R79)

Indelible Rule 1 — *nothing is ever removed, only struck* — is held in the tables, not in the UI.
A **second** mixin sits beside `Identified`:

```dart
mixin Struckable on Table {
  late final struck   = boolean().withDefault(const Constant(false))();
  late final struckAt = integer().map(const InstantConverter()).nullable()();
}
// on every table that carries it:
//   CHECK (struck IN (0,1))
//   CHECK ((struck = 1) = (struck_at IS NOT NULL))
```

**Twelve tables carry it:** `Seasons` · `Ewes` · `EweSeasons` · `Lambings` · `Lambs` ·
`FosterEvents` · `CareEvents` · `EweObservations` · `Pens` · `PenOccupancies` · `Reminders` ·
`Notes`.

**Four `Identified` tables deliberately do not**, because the act already has a home: `Treatments`
has `voided_at` (#69 — a treatment is *voided*, not struck, because it may already have been printed
into a medicine book handed to a vet); `TreatmentWithdrawals` is voided by voiding its treatment;
`VocabTerms` labels are *edited*; `MediaAssets` removal is `04 §4.8`'s `.trash/` path.

**The default every query follows: struck rows are excluded from every count and included in every
history and every export.** A struck lambing must leave **both** the numerator and the denominator of
every statistic — striking one mistyped record must not change a number the shepherd compares
against last year. The Pen Board's open-occupancy projection, the "in the pens" list, the recents
strip and `ewe_summaries` exclude; FTS5 note search **includes**, its triggers are unchanged, and the
screen decides how a struck hit renders.

`struck_at` is an `Instant` — UTC epoch millis behind `InstantConverter`, never drift's
`dateTime()` — so a strike recorded at 01:30 on the clocks-back night is unambiguous. Its round trip
belongs in the `uk-zone` tier against 01:00–01:59.

The active-tag partial unique index carries `AND struck = 0` (R79 §f), so striking a mistyped `412`
releases the tag immediately.

**A table without the provenance quad has no edit verb**, and that is unchanged by any of this.

---

`docs/engineering/03-data-model-and-schema.md` is the catalogue — every table, index and CHECK with
its reasoning; read the section you are touching. This skill carries the rules that apply to *every*
edit and the traps that fail at runtime rather than at codegen. Schema files live in `lib/core/db/`:
`tables/*.dart` (one per cluster), `converters.dart` (one file, not a folder — R21), `uid.dart`,
`database.dart`, `connection.dart`, `seed/first_run.dart`, and three `.drift` files at the package
root — `views.drift`, `search.drift`, `queries.drift` (R22), no `views/` subdirectory.
`customStatement(` is permitted only inside `lib/core/db/`.

## Irreversible after the first schema snapshot — get these right now

Doc 04 §1 lists what cannot be undone. Four are yours:

1. **Storage kind.** Instants are `INTEGER` UTC epoch **millis**; civil dates are `TEXT 'YYYY-MM-DD'`
   (decisions #29/#30). `store_date_time_values_as_text` is never set in `build.yaml` and drift's
   `dateTime()` builder appears nowhere — both are global flags forcing one representation onto two
   different kinds.
2. **The §12.5 provenance quad** on all seven quad-carrying tables (03 §4.2, R37) — adding a
   `NOT NULL` column later is a full table rebuild on tables pointing at the user's records.
3. **`lambings.declared_birth_type` is nullable** (R6): the lambing row is written on the first tap
   and NULL means "no strokes tallied yet", which no default may erase. Birth type is *derived from
   the tally strokes and labelled as derived* — there is no birth-type chooser in the product, so no
   column stores a chosen one.
4. **`media_assets.relative_path` carries all three CHECKs** (R62) — a CHECK cannot be added by
   `ALTER TABLE`.

Decide these before `make gen` runs the first time. For a value with no precedent in the schema, read
`references/storage-decisions.md`.

## Every table obeys these

- **`bool get isStrict => true;`** on every table. Without STRICT, SQLite stores `'twin'` in an
  INTEGER column and pretends — spec §12.4 at the storage layer.
- **Every relationship is a real FK with an explicit `onDelete:`.** `cascade` = this row has no meaning
  without its parent; `restrict` = the parent is referenced by a record someone may show a vet. Never
  `KeyAction.noAction` by laziness. Asymmetry is load-bearing: `treatments` is `restrict` on `ewe` and
  `cascade` on `lamb` (03 §5.8), because a `restrict` on `lamb` would abort season deletion from a
  child table the user never sees.
- **Every FK is hand-indexed.** SQLite creates no child-key index. A composite PK or `uniqueKeys` entry
  indexes **only its leading column**: `{occupancy, lamb}` does nothing for `lamb`. The nullable
  `vocab_terms(key)` references are the forgotten ones, and they are exactly what a RESTRICT scans when
  a user hides a term. One exemption, allowlisted by table name: `app_settings` (one row).
- **No `DEFAULT` and no `clientDefault` on any column that could encode veterinary advice** —
  withdrawal days, `lambings.ease`, `ewe_seasons.status`, `seasons.ewes_to_ram`. A default is the app
  answering on the user's behalf (spec §12.1, §12.2).
- **Closed vocabulary → `CHECK (x IN (…))`. User-editable vocabulary → FK to `vocab_terms(key)`.** That
  discriminator decides every enum-shaped column. An FK constrains the *key*, never the *list*;
  per-column list membership is asserted by `test/data/vocab_list_scope_test.dart`. Do not add a
  trigger for it — it would fire on restore.
- **History tables, never a mutable "current" field.** No `lambs.rearing_dam`, no `pens.occupant_ewe`:
  both are dual writes a future code path gets wrong. Append-only log plus a view (decisions #33, #34).
- **`NULL` and an explicit `'unknown'` are different facts.** `lambs.sex IS NULL` = not recorded;
  `'unknown'` = the shepherd looked and could not tell. Never collapse them.
- **`customConstraints` uses SQL column names** (`declared_birth_type`, not `declaredBirthType`) as
  literal strings — drift_dev reads them from source and its constant-folding of a helper is unverified.
- **`@DataClassName` on any table that does not singularise by dropping one `s`** — drift literally
  strips it, so `PenOccupancies`→`PenOccupancie`. Which tables need it and what row-class name each
  takes is R20 plus `lib/data/models.dart`'s export list, which must agree; read both rather than
  carrying a remembered set. Renaming a row class after the first snapshot is a whole-codebase edit
  for no behaviour change.
- **A range CHECK is a unit-slip guard, never a husbandry opinion.** `birth_weight_g BETWEEN 200 AND
  20000`, `volume_ml BETWEEN 1 AND 2000` and the instant band `946684800000..4102444800000` catch
  grams-vs-kg and seconds-vs-millis. Never narrow one to a range a vet would recognise (spec §12.2).

## The dual key

`id INTEGER PRIMARY KEY AUTOINCREMENT` for joins, FKs, drift companions and FTS5 `content_rowid`;
`uid TEXT UNIQUE` holding UUID v7 for identity across export and re-import. Both come from `mixin
Identified` (`lib/core/db/tables/common.dart`, which also carries `createdAt`/`updatedAt`), carried by
every table whose rows cross the export boundary and by no cache (`ewe_touches`, `ewe_summaries`,
`search_docs`), singleton (`app_settings`, `entitlements`) or pure join table. `newUid()` in
`lib/core/db/uid.dart` is the only `package:uuid` call site (R15). An integer id never appears in a
backup file; import is an upsert on `uid`, never on `tag`.

## Time, units, and what is never stored

- **A moment that happened → instant** (`integer().map(const InstantConverter())`, plus the sanity
  band CHECK). **A square on a calendar → civil date** (`text().map(const LocalDateConverter())`, plus
  a `GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'` CHECK). `ORDER BY` and `>=` on a civil-date
  column are correct *because* the format is GLOB-enforced — that is the payoff of TEXT dates.
  `ewes.date_of_birth` is the only `PartialDateConverter` column; never widen `'2026'` to
  `'2026-01-01'`, because partial precision is the fact.
- **No SQL-side time**: `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME`, `date('now')`,
  `datetime('now')` are banned (decision #47) — all time arithmetic is Dart behind `appNow()` (R23).
  So the schema cannot express `CHECK (clear_date >= date(administered_at))`; that invariant is a
  write-time function plus a shown-never-applied warning.
- **Canonical mass is integer grams, temperature integer milli-°C, and no measurement has a `unit`
  column.** Storing mass at 0.1 kg silently rewrites 132 of 241 lb entries. Convert at the display edge.
- **Never store a time-relative value** (01 §7.2) — "hours since penned", "days until clear",
  "overdue", "ready to turn out" change with no write, so a stored copy is wrong within a minute. Store
  `entered_at`; compute at render from the ticker's instant.
- **Never store an aggregate, a percentage or a formatted string.** `ewe_summaries` holds counts only.
  The schema's one stored derived value is `treatment_withdrawals.clear_date` — a record of what the
  app *told* the user and printed into a medicine book, not a cache.

## The provenance quad

Four columns on every table whose rows the user can date, added together or not at all, plus **both**
paired CHECKs — the pair is what makes an inconsistent quad unstorable rather than merely discouraged.

**Every spelling in the quad is `CONVENTIONS` R37/R38** — the event-time column's name and its three
documented exceptions, and the fact that the original-effective column is *not* suffixed `_at`. Open
those two rulings; this skill deliberately spells none of the four, because R37/R38 were written to
close a stale-claim sweep and a second copy reopens it. **Which tables carry the quad, and the two
CHECK expressions verbatim, are `03 §4.2`** — read the section, never a remembered count.

**Standing rule until the quad is on a table: that table has no edit verb.** A note's event time is a
different column from the `Identified` mixin's creation stamp — a note typed at 06:00 about an 03:20
lambing has two instants, and every timeline sorts on the event time.

## Tag uniqueness, search, first run

- **Tags are unique among ACTIVE animals only** (owner ruling): two partial unique indexes —
  `ewes (tag) WHERE status = 'active'`, `lambs (tag) WHERE tag IS NOT NULL AND status = 'alive'`.
  Uniqueness is on `tag` as typed, never on `tag_digits`: unique digits would refuse `0412` because
  `412` exists, which is the app deciding two tags are one animal. Culling drops the row out of the
  index in the same statement, so a tag is reusable with no dialog on the 03:20 path.
- **Partial tag matching is not a search problem.** It is an in-memory synchronous rank in
  `lib/domain/tag_match.dart` over ~400 active tags, so every keypad tap re-filters inside the same
  frame. FTS5, the trigram tokenizer, `LIKE` and any debounce are banned on the keypad path.
- **Note search is FTS5 over one fan-in table**, `search_docs` + `search_fts`, kept in sync by SQL
  triggers on the source tables — never repository code, because a bulk restore is exactly where a
  Dart-side "also index this" call gets skipped. No Dart writes either table; the one exception is
  `SeasonRepository` running `sweepSearchDocs` then `rebuildSearchIndex` inside the season-delete
  transaction. `search_docs` is excluded from the backup and repopulates itself.
- **First run seeds inside `onCreate`, in the same transaction as `createAll()`** — one season, one
  `app_settings` row, one `entitlements` row, the 40 vocabulary keys with `label = NULL`, the reminder
  rules, **zero pens**; never in UI code, a provider or first paint. Every event table has `season NOT
  NULL`, so without the season insert the first keypad tap cannot write a lambing. `seedOnCreate:
  false` on exactly two paths — the restore staging database and `tool/seed.dart`.

## Gotchas — these pass codegen and fail at 3am

- **The file is `build.yaml`, not `build.yml`.** With the wrong name FTS5 silently stays disabled and
  nothing complains until a MATCH throws on a device.
- **`COALESCE` in every fan-in trigger.** `search_docs.title`/`.body` are `NOT NULL` and every source
  column is nullable, so a trigger writing `new.notes` straight through aborts *creating a ewe with no
  notes* — on the create-on-the-fly path, at 03:20, from a trigger nobody was watching. Multi-column
  bodies are `COALESCE(a,'') || ' ' || COALESCE(b,'')`.
- **Once an FTS5 table is aliased, only the alias is in scope.** `FROM search_fts f` with
  `WHERE search_fts MATCH …`, `snippet(search_fts, …)` or `bm25(search_fts, …)` fails at runtime with
  *no such column*: use `f` in all three places or the table name in all three, never mixed. And `rank`
  is FTS5's own generated column, so alias the score `rank_score`; `bm25()` is negative-smaller-better,
  so ascending `ORDER BY` is correct.
- **`PRAGMA foreign_keys` and `PRAGMA recursive_triggers` are per-connection, not in the file header.**
  Without the first, every `ON DELETE` you wrote is decorative; without the second, `ON DELETE CASCADE`
  does not reliably fire child `AFTER DELETE` triggers and `search_docs` keeps rows for notes that no
  longer exist. Both are set in the one `configureConnection`, whose pragma list is a fixed-order union
  of two documents' lists — dropping any one is a regression (R13, 03 §1.3). Exactly one
  `driftDatabase(` call site is what makes that provable.
- **`validateDatabaseSchema()` is an async extension member.** Wrapping it in a sync `assert()` starts
  the check, returns `true` immediately, and surfaces a mismatch as an unhandled async error much
  later. `await` it inside `beforeOpen` under `kDebugMode`.
- **`withClock()` does not cross an isolate boundary**, so it never reaches a migration opened through
  `driftDatabase()`. Migration and seed tests use `NativeDatabase.memory()`.
- **A contradiction is a view, never a trigger and never a correction.** `lambing_consistency` reports
  declared-vs-recorded; there is no `warnings` column and no `fix()` anywhere (decision #54).
  `declared = 5` means "more than four" and `declared IS NULL` means "no strokes tallied yet" — miss
  either guard and every large or in-progress litter shows a false badge.
- **`lambs.birth_dam` is immutable, enforced by a `BEFORE UPDATE` trigger in `views.drift`**, not by
  Dart. Fostering appends a `FosterEvents` row and never touches `declared_birth_type`; a plausible
  "move a lamb" implementation that recomputes the litter is the bug that trigger exists to catch.

## Finish the change: `make gen`, one commit

Regeneration is part of the edit, not a separate errand. After editing anything under `lib/core/db/`:

```bash
make gen          # build_runner build --delete-conflicting-outputs && drift_dev make-migrations
flutter test test/drift/
```

`make gen` is the **only** way `*.g.dart`, `*.drift.dart`, `drift_schemas/*.json`,
`lib/core/db/schema_versions.dart` and `test/drift/generated/**` change — never hand-edit one, never
commit a schema edit without them. The `codegen` CI job re-runs both and fails on a non-empty
`git diff` over `lib/`, `drift_schemas/` and `test/drift/generated/` (04 §3.6); a stale generated file
is invisible locally and lethal on a fresh clone. Schema edit, version bump, migration step and every
regenerated artefact land in **one commit, together or not at all**.

## Not this skill

- **A column's or type's spelling, path or provider name** → `shed-conventions`. Cite R37/R38 by
  number; never retype a spelling.
- **`kSchemaVersion`, the `from<N>To<N+1>` body, the committed snapshot, the from→to matrix** →
  `shed-migrations`. Run `make gen` here; hand the step over there.
- **Which repository writes the row, the event verb, the transaction, `WriteOutcome`** →
  `shed-write-path`. This skill decides what the column *is*, not who writes it.

## Blocked — do not improvise around it

**P1: `struck` / `struck_at` are not in the schema and are not yours to add.** Indelible's Rule 1
(nothing is removed, only struck) implies the columns on every table, every query deciding whether
struck rows count, and both CSV and PDF carrying them — schema-irreversible, and the owner has not
ruled it. Do not add them, nor a boolean `deleted`, a `DELETE` path or an "active rows" view as a
stand-in. If a task needs a strike or an undo, stop and say P1 blocks it.

## Definition of done

- [ ] Every new table declares `isStrict => true`; every FK has an explicit `onDelete:` plus an index
      whose **leading** column is the child key.
- [ ] No `DEFAULT`/`clientDefault` on an advice-bearing column; no `dateTime()` column; no
      `store_date_time_values_as_text`; no SQL-side time function.
- [ ] Every civil-date column has its GLOB CHECK, every instant column the sanity band, and any table
      the user can date the full quad with both paired CHECKs.
- [ ] Any table that does not singularise cleanly has `@DataClassName`, and the name is in
      `lib/data/models.dart`'s export list.
- [ ] `make gen` ran and its artefacts are staged **in the same commit** as the schema edit;
      `flutter test test/drift/` is green.
- [ ] A ewe, a lamb and a lambing insert with **every optional text field blank** — the `COALESCE`
      trap on the 3am path.
- [ ] Any query added to `queries.drift` was executed once against a real database, not just compiled
      — the FTS5 alias trap passes codegen.

**Read `references/storage-decisions.md` when deciding how to store a value with no precedent in the
schema** — instant vs civil date vs unit vs derived, and what is irreversible after the first snapshot.
