# N07-T05 — The pen and treatment clusters

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 5 of 8 |
| **Depends on** | N07-T04 |
| **Commit** | one commit · `feat(db): the pen and treatment clusters, with no default on withdrawal days` |

## 1. Why this task exists

`pens`, `pen_occupancies`, `pen_occupancy_lambs` with the partial unique index
`WHERE exited_at IS NULL` — the database itself refuses two ewes in pen 3 — and `treatments` /
`treatment_withdrawals`, a child table where **no row means not recorded** and where `days` has **no
`DEFAULT`**, because a default here is §12.1 in a column definition.

This is the highest-stakes commit in the epic. Spec §7.5: *"A wrong withdrawal number puts meat or
milk into the food chain."* The mechanism that prevents it is not a code review and not a validator —
it is the absence of two words in a column definition, and the presence of a child table whose absent
row **is** the fact *"I didn't look."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.9 | `Pens`, `PenOccupancies`, `PenOccupancyLambs` — the partial index, the quad, the exit CHECKs |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 | `Treatments` and `TreatmentWithdrawals` — the polymorphic subject, the `ON DELETE` asymmetry and its full reasoning, the soft void, and **the two gates that prove §12.1 and only these two** |
| `docs/engineering/03-data-model-and-schema.md` | §4.1 rule 5, §8 | why no `CHECK` can compare a clear date to an instant, and why hours-since-penned is never stored |
| `docs/engineering/05-domain-correctness.md` | §3 | `clearDateFor()` — the one function that may write `clear_date` |
| `docs/engineering/CONVENTIONS.md` | §2.7, §4.6, R7, R37, R63 | `WithdrawalPeriod` and its stored shape, `@DataClassName('PenOccupancy')`, `entered_at`/`administered_at`, `exitPen`'s required reason |
| `docs/engineering/00-README.md` | §2.3 | §12.1 held at *unconstructible + unpersistable*, and what "unpersistable" means in SQL |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the child-table idiom and the partial index |
| `shed-safety-rules` | the absent `DEFAULT` on `days` is §12.1's unpersistable half |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/schema_refuses_test.dart`
- **Test** — `'inserting a treatment_withdrawals row without days is rejected, and no row means NotRecorded'`
- **Assertion, spelled out** — an insert with `kind = 'days'` and `days` omitted throws
  `SqliteException` (the paired `CHECK ((kind = 'days') = (days IS NOT NULL))`); a treatment with **no**
  child row at all inserts cleanly and `SELECT … FROM treatment_withdrawals WHERE treatment = ?`
  returns zero rows — which is the storage form of `WithdrawalNotRecorded`. Both halves in one test.
- **Why it is red today** — nothing stops two open occupancies for one pen, and nothing stops a `DEFAULT 0` on `days`.

```bash
fvm flutter test test/data/schema_refuses_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — five tables, both partial indexes, no defaults on any column that could encode
veterinary advice — then `build_runner` only.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/tables/pens.dart` | **New.** `Pens`, `PenOccupancies` (with `@DataClassName('PenOccupancy')`), `PenOccupancyLambs`. |
| 2 | `lib/core/db/tables/treatments.dart` | **New.** `Treatments`, `TreatmentWithdrawals`. |
| 3 | `lib/core/db/database.dart` | Register the five tables. |
| 4 | `lib/data/models.dart` | Add `Pen`, `PenOccupancy`, `PenOccupancyLamb`, `Treatment`, `TreatmentWithdrawal`. |
| 5 | `test/data/schema_refuses_test.dart` | **New.** The anchor plus the pen half — the file is named for the **property** (things the database refuses), not for a source file, per `CONVENTIONS` §4.1. |
| 6 | `test/domain/uk_zone/schema_pen_dst_test.dart` | **New.** The elapsed-time and clear-date cases in 5.4. |

Then `dart run build_runner build --delete-conflicting-outputs`.

### 5.2 The signatures

```dart
class Pens                extends Table with Identified { … }   // uniqueKeys [{label}]
@DataClassName('PenOccupancy')
class PenOccupancies      extends Table with Identified { … }   // idx_penocc_pen_time, idx_penocc_ewe,
                                                                // idx_penocc_season,
                                                                // idx_penocc_one_open (partial, .sql)
class PenOccupancyLambs   extends Table { … }                   // primaryKey {occupancy, lamb};
                                                                // idx_penocclamb_lamb; NO Identified
class Treatments          extends Table with Identified { … }   // idx_treatment_ewe_time,
                                                                // idx_treatment_lamb_time,
                                                                // idx_treatment_season_time,
                                                                // idx_treatment_route
class TreatmentWithdrawals extends Table with Identified { … }  // idx_withdrawal_clear;
                                                                // uniqueKeys [{treatment, target}]
```

The two partial unique indexes in this epic are both `@TableIndex.sql`:

```dart
@TableIndex.sql(
  'CREATE UNIQUE INDEX idx_penocc_one_open '
  'ON pen_occupancies (pen) WHERE exited_at IS NULL',
)
```

The columns that carry a rule:

| Column | Declaration | Why it is exactly this |
|---|---|---|
| `treatment_withdrawals.days` | `integer().nullable()()` — **no `DEFAULT`, no `clientDefault`** | Spec §12.1 enforced by the schema, not by a code review. The app is physically unable to write this row without a number the user typed off the bottle. |
| `treatment_withdrawals.kind` | `text()()`, `CHECK (kind IN ('days','not_applicable'))` | *"The label says 0 days"* and *"I didn't look"* are different facts. `0` is a real label value, so a nullable `int?` on `treatments` would conflate them — which is why the child table exists at all. |
| `treatment_withdrawals.target` | `text()()`, `CHECK (target IN ('meat','milk'))` | **Both targets ship in the v1 schema**, per N00-T04's ruling on `00-README` §5.2 item 10. One product routinely prints different figures. Shipping the second key now is free; retrofitting is a migration. |
| `treatment_withdrawals.clear_date` | `text().map(const LocalDateConverter()).nullable()()` | The **one** stored derived value (decision #50), computed exactly once at write time by `clearDateFor()`. It is a record of what the app **told** the user and printed into the medicine-book PDF — not a cache, and never recomputed on read. |
| `treatments.voided_at` | `integer().map(const InstantConverter()).nullable()()` | Decision #69: undo for a treatment is a **soft void**, because the row may already have been printed into a medicine book handed to a vet. The medicine book shows the void; it never loses the row. |
| `treatments.ewe` / `treatments.lamb` | two nullable FKs + `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)` | A `(type, id)` pair cannot be a foreign key, so SQLite could not enforce that the animal exists, could not cascade, and could not stop an orphan. In a record that may be shown to a vet, an orphan is worse than useless. |
| `pen_occupancies.exit_reason` | `text().nullable()()` + `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))` | This CHECK is what makes `exitPen(occupancy, {required PenExitReason reason})` storable (R63). Four stored keys: `turned_out`, `moved`, `died`, `other`. |
| `pens.is_active` | `boolean().withDefault(const Constant(true))()` | `ON DELETE RESTRICT` on `pen` means a pen with history cannot be deleted — the pen board is a **record**, not a whiteboard. Deactivate instead. |

### 5.3 The details that are easy to get wrong

1. **The `ON DELETE` asymmetry on `treatments` is deliberate and both halves are load-bearing.**
   `RESTRICT` on `ewe`: a ewe with treatments is a record someone may show a vet, so she cannot be
   deleted out from under it — and she never needs to be, because a ewe leaves the flock by
   `status = 'culled'`, not by `DELETE`. `CASCADE` on `lamb`: deleting a season cascades
   seasons → lambings → lambs, and a `RESTRICT` here would abort that delete from a child table the
   user never sees. Season deletion is the one destructive flow, it has no undo, and decision #69
   already guards it with the app's only `canPop: false`. **Test both in one test** — each assertion
   alone passes the wrong schema (03 §11).
2. **There is no `withdrawal_days` column on `treatments`, and no medicines lookup table anywhere in
   this app.** A lookup table is a shipped default wearing a data model's clothes.
3. **The two gates that prove §12.1 are exactly two, and this task ships neither of them.** They are
   the schema-JSON assertion in **T08** and a widget test in **N20** that the Treatment entry screen
   renders no pre-filled number. What this task ships is the *condition* they assert on.
4. **Do not add a source heuristic banning numeric literals near "withdrawal".** It fires on these very
   `CHECK` constraints and on every test fixture in 5.4, and a gate that fires on correct code gets
   weakened until it fires on nothing.
5. **The schema cannot express `CHECK (clear_date >= date(administered_at))` and must not try.** That
   needs a SQL date function, and `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME`, `date('now')`
   and `datetime('now')` are all banned (decision #47). The invariant is enforced by `clearDateFor()`
   at write time and surfaced afterwards as `WarningCode.clearDateDisagrees` — **shown, never applied.**
   State this in the table's doc comment so nobody hunts for the missing CHECK.
6. **`uniqueKeys [{treatment, target}]` indexes `treatment` and does nothing for `target`.** Leading
   column only — the same rule that put `idx_penocclamb_lamb` beside `PenOccupancyLambs`'s composite
   primary key. `target` needs no index of its own (two values, one row each per treatment);
   `idx_withdrawal_clear` exists for the countdown query.
7. **`idx_penocc_one_open` is what "the whiteboard gets wiped" is solved with.** The database
   physically refuses two ewes in pen 3 at once. **Never re-express it as a Dart check in
   `PenRepository`** — 12 §3.3 asserts the `WriteFailed` comes from the index, and a repository-level
   guard would pass on a schema with no index at all.
8. **There is no `pens.occupant_ewe` and no `lambs.rearing_dam`, and adding either is the defect**
   (03 §1.5, decisions #33/#34). A boolean or id `current_*` column beside a history table is a dual
   write a future code path gets wrong, and then the list screen and the history disagree.
9. **Hours since penned is never stored and never computed in SQL** (03 §8, 01 §7.2). Store
   `entered_at`; compute at render from the instant `minuteTickProvider` yields.
   `timeSincePenned(enteredAt, now)` takes `now` as a parameter; `sincePenned` is a banned name.
   Nothing in this task stores an elapsed anything.
10. **`treatments.route` is still a forward reference.** `.references(VocabTerms, #key, onDelete:
    KeyAction.restrict)` lands in T06 with the `treatment_route` list. `idx_treatment_route` goes in now.
11. **`exited_at >= entered_at` is an integer comparison and is correct across DST** precisely because
    both are absolute epoch millis. It would be wrong on a civil-date column, and that difference is the
    entire reason 03 §4.1 separates the two kinds.
12. **`pen_occupancies.ewe` is nullable and `RESTRICT`.** A pen can hold lambs with no ewe (an orphan
    pen), which is why `inThePens` filters `o.ewe IS NOT NULL` in T07 and the pen board does not.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/schema_refuses_test.dart` | `'inserting a treatment_withdrawals row without days is rejected, and no row means NotRecorded'` | The anchor, both halves. |
| | `'a treatment_withdrawals row with kind = not_applicable and days NULL is accepted'` | *Not applicable* is a recorded answer, not an absence. The third state the sealed type carries. |
| | `'a treatment_withdrawals row with kind = days and clear_date NULL is rejected'` | The second paired CHECK — a days figure the app never turned into a date is a half-written record. |
| | `'days = 0 is storable'` | `0` is a real label value. A schema that rejects it has quietly become an opinion. |
| | `'two withdrawals for one treatment with targets meat and milk both insert; a second meat row is refused'` | `uniqueKeys [{treatment, target}]`, both directions. Also proves the `milk` key exists. |
| | `'a second open occupancy for the same pen is refused, and one is permitted after the first exits'` | `idx_penocc_one_open`, both directions. |
| | `'pen_occupancies rejects exited_at without exit_reason, and exit_reason without exited_at'` | The paired CHECK, both directions. |
| | `'pen_occupancies rejects exited_at earlier than entered_at'` | The ordering CHECK. |
| | `'deleting a pen with a closed occupancy is REFUSED'` | `RESTRICT` — the board is a record. |
| | `'deleting a ewe who has a treatment is REFUSED, and deleting a season containing a treated lamb SUCCEEDS'` | **One test, both assertions** (03 §11). Each half alone passes the wrong schema. |
| | `'treatments rejects a row with both ewe and lamb, and one with neither'` | The polymorphic-subject CHECK, both directions. |
| | `'a voided treatment is still selectable and still carries its withdrawals'` | Soft void: the row never leaves. |
| | `'every pen and treatment table is STRICT'` | Insert `'seven'` into `treatment_withdrawals.days`; expect `SqliteException`. |
| `test/domain/uk_zone/schema_pen_dst_test.dart` | `'an occupancy entered 22:00 on 28 March 2026 and exited 08:00 on 29 March spans 9 hours of stored millis'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The wall clock advanced 10 h; nine is correct, and it errs toward turning out later. Asserted on `exited_at - entered_at`, in the file, not on a formatted string. |
| | `'entered_at inside the ambiguous hour on 25 October 2026 round-trips and passes the sanity band'` | The hour that happens twice; both candidate instants are inside the band. |
| | `'a clear_date produced by clearDateFor across spring-forward stores as a civil date and passes the GLOB'` | Decision #3: ceil-to-next-local-midnight of `administeredAt + N × 24 h`, in **absolute** time. Civil-day arithmetic yields 167 h across UK spring-forward — one hour short, in late March, which is peak lambing. The schema's job is only to store what `clearDateFor()` produced; the case is here so a future refactor that recomputes on read is caught in this file. |

### 5.5 Verification that §12.1 is actually unpersistable

Read the generated `CREATE TABLE treatment_withdrawals` in `database.g.dart` and confirm the `days`
column is `INTEGER` with **no** `DEFAULT` clause, then confirm `TreatmentWithdrawalsCompanion.insert`
requires `kind` and does **not** provide `days`. T08 makes the same assertion against the committed
schema JSON, which is the version that survives; this one is what tells you now, cheaply.

## 6. Constraints that bind this task

- **The five safety rules** — §12.1 held at *unpersistable*: no `DEFAULT`, no `clientDefault`, and an
  absent child row is the *not recorded* fact. §12.5 held by the quad on `PenOccupancies` and
  `Treatments`. §12.2: the `volume_ml` and `birth_weight_g`-style bands elsewhere are unit-slip guards,
  never dose or husbandry opinions — nothing in this task narrows one.
- **Never present as a regulatory record** — the medicine book is a view over these rows; the schema
  carries no "compliant", "official" or "signed-off" column and never will.
- **Irreversibility** — a `DEFAULT` added here and frozen in T08 is a migration on somebody's phone to
  remove, and in the meantime the app has answered a veterinary question on the user's behalf.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'inserting a treatment_withdrawals row without days is rejected, and no row means NotRecorded'` passes, and was seen to fail first for the stated reason
- [ ] a second open occupancy for the same pen is refused by the index
- [ ] `treatment_withdrawals.days` is `NOT NULL` with no `DEFAULT`
- [ ] the absent child row is the *not recorded* fact and the test proves it
- [ ] milk and meat targets both exist, per N00-T04's ruling
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Read the third DoD line against 03 §5.8.** `days` is declared `integer().nullable()()` — it is
> `NULL` exactly when `kind = 'not_applicable'`, and the paired
> `CHECK ((kind = 'days') = (days IS NOT NULL))` is what makes it unwritable-without-a-number in the
> only case that matters. The load-bearing half of the line is **no `DEFAULT` and no `clientDefault`**;
> a literal `NOT NULL` would make *"not applicable"* unstorable and break the sealed type.

## 8. Verification

```bash
# 1. Red first.
fvm flutter test test/data/schema_refuses_test.dart

# 2. build_runner ONLY.
dart run build_runner build --delete-conflicting-outputs

# 3. The refusals, then the London-zone set.
fvm flutter test test/data/schema_refuses_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. Five more tables under the FK-index guard.
fvm flutter test test/data/every_fk_is_indexed_test.dart

# 5. The one grep that proves §12.1 at this stage.
grep -n "days" lib/core/db/tables/treatments.dart   # expect: no DEFAULT, no clientDefault

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): the pen and treatment clusters, with no default on withdrawal days`
