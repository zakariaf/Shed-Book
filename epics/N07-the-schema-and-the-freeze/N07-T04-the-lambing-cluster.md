# N07-T04 — The lambing cluster

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 4 of 8 |
| **Depends on** | N07-T03 |
| **Commit** | one commit · `feat(db): the lambing cluster, the birth-dam trigger and the two views` |

## 1. Why this task exists

`lambings`, `lambs`, `foster_events`, `care_events`, the **birth-dam immutability
trigger**, and the `lamb_rearing` and `lambing_consistency` views. `declared_birth_type` is nullable
and — after P8 — is written only when a shepherd deliberately declares one against the strokes; the
counted type is derived. Care events are `EXISTS` rows, never booleans, so *not recorded* and *no*
stay distinguishable.

Two sentences carry the whole cluster. **Birth is a fact; rearing is a history** — so `lambs.birth_dam`
is immutable in SQL and there is no `rearing_dam` column at all. And **a lamb that died before tagging
is counted, fully** — lamb identity is the row, never the tag, so `lambs.tag` is nullable at every
layer. Anything else loses exactly the losses that matter most.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.4 | `Lambings`, its four indexes, the seven CHECKs, and the `lambing_consistency` view with both guard clauses |
| `docs/engineering/03-data-model-and-schema.md` | §5.5 | `Lambs`, the alive-only partial unique index, the sex/death/weight CHECKs |
| `docs/engineering/03-data-model-and-schema.md` | §5.6 | `CareEvents` — `EXISTS` rows, the closed `kind` CHECK, the volume guard |
| `docs/engineering/03-data-model-and-schema.md` | §7 | fostering: the immutability trigger, `FosterEvents`, the `lamb_rearing` view, the born-vs-reared invariant and its conservation test |
| `docs/engineering/03-data-model-and-schema.md` | §4.2 | the quad, and the three documented event-time column names |
| `docs/engineering/CONVENTIONS.md` | R6, R22, R37, R44, R45, R46, R64 | nullable `declared_birth_type`, `views.drift`'s contents, the quad, `LambingEase`, `Sex`, `BirthType`, `FosterOutcome` |
| `docs/skills/02-build-manifest.md` | §4.2 (P8) | birth type is **derived from the tally strokes**; any birth-type chooser is wrong |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | tables, triggers and views |
| `shed-safety-rules` | the birth-dam trigger and the nullable declared type are §12.4 mechanisms |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/schema_lambing_test.dart`
- **Test** — `'the birth-dam trigger refuses an update to lambs.birth_dam'`
- **Assertion, spelled out** —
  `db.customStatement('UPDATE lambs SET birth_dam = ? WHERE id = ?', [otherEwe, lambId])` throws
  `SqliteException`, and the raised message contains `birth_dam is immutable`. Then assert the same
  `UPDATE` setting `birth_dam` to its **existing** value does **not** throw — the trigger is guarded by
  `WHEN old.birth_dam IS NOT new.birth_dam`, and a trigger that fires on a no-op update breaks every
  later bulk write.
- **Why it is red today** — nothing stores a lambing, and nothing prevents a foster rewriting the birth dam.

```bash
fvm flutter test test/data/schema_lambing_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — four tables, the trigger, the two views — then `build_runner` only.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/tables/lambing.dart` | **New.** `Lambings`, `Lambs`, `CareEvents`, `FosterEvents`. The one cluster file name `CONVENTIONS` §4.1 spells verbatim. |
| 2 | `lib/core/db/tables/flock.dart` | Edit: complete `ewe_observations.lambing` with `.references(Lambings, #id, onDelete: KeyAction.setNull)`, deferred from T03. |
| 3 | `lib/core/db/views.drift` | **New.** `CREATE TRIGGER lamb_birth_dam_is_immutable`, `CREATE VIEW lamb_rearing`, `CREATE VIEW lambing_consistency`. R22: `views.drift` holds `CREATE VIEW` **and** the non-search table triggers. |
| 4 | `lib/core/db/database.dart` | Register the four tables; add `include: {'views.drift'}` to `@DriftDatabase`. `search.drift` and `queries.drift` join the set in T07 — the include is a set and may be built up. |
| 5 | `lib/data/models.dart` | Add `Lambing`, `Lamb`, `CareEvent`, `FosterEvent`. |
| 6 | `test/data/schema_lambing_test.dart` | **New.** The anchor plus the cases in 5.4. |
| 7 | `test/data/fostering_conservation_test.dart` | **New**, database-level half only — see gotcha 8. |
| 8 | `test/domain/uk_zone/schema_lambing_dst_test.dart` | **New.** The `local_date` cases in 5.4 — the highest-value tests in this task. |

Then `dart run build_runner build --delete-conflicting-outputs`.

### 5.2 The signatures

```dart
class Lambings    extends Table with Identified { … }  // idx_lambing_season_time, idx_lambing_ewe_time,
                                                       // idx_lambing_localdate, idx_lambing_presentation
class Lambs       extends Table with Identified { … }  // idx_lamb_lambing, idx_lamb_birthdam,
                                                       // idx_lamb_tagdigits, idx_lamb_deathcause,
                                                       // idx_lamb_tag_alive (partial, .sql)
class CareEvents  extends Table with Identified { … }  // idx_care_lambing_kind, idx_care_lamb_kind,
                                                       // idx_care_season
class FosterEvents extends Table with Identified { … } // idx_foster_lamb_time, idx_foster_rearingdam,
                                                       // idx_foster_season, idx_foster_corrects,
                                                       // idx_foster_method
```

The columns that carry a rule:

| Column | Declaration | Why it is exactly this |
|---|---|---|
| `lambings.declared_birth_type` | `integer().nullable()()`, `CHECK (… IS NULL OR … BETWEEN 1 AND 5)` | **R6, load-bearing.** The lambing row is written on the **first** tap, before any birth type exists. `NULL` = *"not yet tapped"*, a different fact from any of 1..5, never defaulted to `single`. `5` means *"more than four, count not declared."* |
| `lambings.ease` | `integer().nullable()()`, `CHECK (… BETWEEN 1 AND 5)` | No default, nullable: *"not scored"* ≠ *"unassisted"* (decision #59). An **ordinal with a CHECK**, deliberately not a vocabulary FK — widening the scale must be a migration someone has to think about (R44). |
| `lambings.local_date` | `text().map(const LocalDateConverter())()` | Denormalised civil date of `occurred_at`, written in the **same statement**. The grouping key for the lambing-spread histogram: SQLite cannot bucket by the shepherd's civil day without a tz database; Dart can. |
| `lambings.ewe` | `references(Ewes, #id, onDelete: KeyAction.restrict)` | A ewe with lambings is a record someone may show a vet. |
| `lambs.birth_dam` | `references(Ewes, #id, onDelete: KeyAction.restrict)` | Immutable, denormalised from `lambings.ewe` at insert, enforced by the trigger — **not by Dart**. |
| `lambs.sex` | `text().nullable()()`, `CHECK (… IN ('f','m','unknown'))` | `NULL` = not recorded. `'unknown'` = the shepherd looked and could not tell. Dart side is `Sex?`, never `Sex.unknown` for null (R45). **Never collapse them.** |
| `lambs.birth_weight_g` | `integer().nullable()()`, `CHECK (… BETWEEN 200 AND 20000)` | A **unit-slip guard** (5 g vs 5 kg), not a husbandry opinion. Never narrow it to a range a vet would recognise — spec §12.2. |
| `care_events.kind` | `text()()`, `CHECK (kind IN ('colostrum','navel_dip','stomach_tube','warmed'))` | A **closed** CHECK, not a vocabulary FK: each value is wired to a notification channel id frozen at release (decision #65). A fifth kind is a migration *and* a channel decision — the correct amount of friction. |
| `foster_events.outcome` | `text()()`, three keys | `to_ewe` / `to_bottle` / `removed_unknown` (R64). Bottle (null by intent) and unknown (null by omission) are different facts and the rearing-credit numbers differ. This is why `setRearingDam(lambId, eweId?)` is a banned signature. |
| `foster_events.corrects` | self-FK, `ON DELETE RESTRICT`, nullable | Decision #69: undo for a foster is a **compensating event** pointing at the one it reverses, visible in history. The log is append-only; nothing is ever deleted from it. |
| `foster_events.effective_at` | quad event time | The third documented exception to the `occurred_at` rule (R37): a graft is dated by when it took effect. |

The trigger and the two views, in `views.drift`:

```sql
CREATE TRIGGER lamb_birth_dam_is_immutable
BEFORE UPDATE OF birth_dam ON lambs
WHEN old.birth_dam IS NOT new.birth_dam
BEGIN
  SELECT RAISE(ABORT, 'birth_dam is immutable; record a foster instead');
END;
```

`lamb_rearing` projects the current rearing dam from the log; `lambing_consistency` surfaces the
spec §12.4 contradiction as a **view**, never a trigger and never a correction. Copy both from
03 §5.4 and §7 exactly — the guard clauses are the point, not decoration.

### 5.3 The details that are easy to get wrong

1. **`WHEN old.birth_dam IS NOT new.birth_dam`, not `<>` or `!=`.** `IS NOT` is SQLite's NULL-safe
   inequality. With `<>` a no-op `UPDATE lambs SET …` that happens to touch `birth_dam` fires the
   trigger on unchanged values, and every later bulk write aborts on a row it did not modify.
2. **`BEFORE UPDATE OF birth_dam`, not `BEFORE UPDATE`.** The column list is what keeps the trigger off
   every other write to a table the app updates constantly (`status`, `notes`, `bottle_feeds`).
3. **There is no `rearing_dam` column, and adding one is the defect** (decision #33). A denormalised
   current-rearing-dam column is a dual write a future code path will get wrong, producing a lamb whose
   history says *"fostered to 128"* while the list screen says *"412"*. Spec §7.3's "birth dam and
   rearing dam as separate fields" is satisfied at the **domain** level by `LambDams(birthDamId, rearingDamId)`,
   whose rearing side is projected from `lamb_rearing`.
4. **`lamb_rearing`'s `COALESCE` has three arms, not two, and the third is the subtle one.**
   No foster event at all → she is rearing what she bore (a fact at birth, not a guess). A foster event
   whose latest row has `rearing_dam IS NULL` → **NULL**, because the lamb is on a bottle or was removed.
   Collapsing those two produces a bottle lamb credited to its birth dam, which is the number the whole
   born-vs-reared distinction exists to protect.
5. **`lambing_consistency` needs both guards or it is wrong in two different ways.**
   `declared_birth_type = 5` means *"more than four"*, so five or more attached lambs is **not** a
   mismatch — get it wrong and a false badge appears on every large litter. And
   `declared_birth_type IS NULL` must be guarded explicitly, because `COUNT(…) <> NULL` is `NULL`,
   which makes `is_mismatched` three-valued for every in-progress lambing.
6. **The number of `lambs` rows is never forced to agree with `declared_birth_type`.** Both numbers are
   preserved verbatim. **There is no `warnings` column anywhere in this schema and no `fix()` anywhere
   in the codebase** — a warning cannot be persisted because there is nowhere to persist it, and cannot
   mutate because it holds no writer (decision #54).
7. **`declared_birth_type` has a writer, and it is not a chooser.** P8 (`02-build-manifest.md` §4.2):
   birth type is **derived from the tally strokes** and labelled `(COUNTED)`. The column is written only
   when the shepherd deliberately declares one **against** the strokes. `07-screens.md` §6.4's
   "five big buttons" and `12-testing.md` §10.1's sixth tap are superseded artefacts. Nothing in this
   task ships a chooser, and N16 carries the canary test that keeps one from appearing.
8. **The 03 §7 conservation test as printed calls `FosterRepository` and `randomFosterSequence`, both of
   which are N18's.** Land the database-level halves here: insert lambs and foster events directly,
   assert `SELECT COUNT(*) FROM lambs` is invariant, and assert
   `SUM(born) GROUP BY birth_dam == COUNT(*)`. N18 adds the 200-random-move property test on top.
9. **Three vocabulary foreign keys are still forward references.** `VocabTerms` lands in T06:

   | Column | Vocabulary list | `.references(VocabTerms, #key, onDelete: KeyAction.restrict)` lands in |
   |---|---|---|
   | `lambings.presentation` | `malpresentation` | T06 |
   | `lambs.death_cause` | `death_cause` | T06 |
   | `foster_events.method` | `foster_method` | T06 |

   The indexes go in now. Nothing is frozen until T08, so completing them in T06 costs a regeneration.
10. **`care_events` is `EXISTS(…)`, never a boolean column.** That is what keeps *"colostrum given at
    03:22"* recoverable, and it is what gives the colostrum reminder something to be completed *from* —
    completing the reminder writes the `CareEvent`; it is the same tap. A `lambings.colostrum_given`
    boolean would delete both facts.
11. **`CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)` — exactly one, not at-least-one.** SQLite
    evaluates a boolean as 0/1, so the sum is the idiom. A care event belongs to a lambing **or** a lamb.
12. **`lambs` has its own partial unique index and its predicate is longer:**
    `WHERE tag IS NOT NULL AND status = 'alive'`. `tag` is nullable on lambs (it is not on ewes), and
    without the `IS NOT NULL` clause SQLite treats every untagged lamb as distinct anyway — but the
    predicate states the intent and survives someone making `tag` non-nullable in 2029.
13. **A death date implies a death; a death does not imply a date.** `CHECK (death_date IS NULL OR
    status IN ('dead','stillborn'))` — and *"died, date not recorded"* is a real state that lands in the
    `unknownAge` bucket. Do not add the converse CHECK.
14. **`stillborn` is its own status, never folded into day-0 deaths** (`CONVENTIONS` §5.1).
15. **Fostering onto a ewe who has not lambed is not blocked, only warned** — a real practice with a ewe
    who lost her own lambs, and spec §7.1 forbids making the user go and record her lambing first. Same
    for more lambs than teats. Neither is a `CHECK`.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/schema_lambing_test.dart` | `'the birth-dam trigger refuses an update to lambs.birth_dam'` | The anchor, both arms (changed value throws, unchanged value does not). |
| | `'a lambing inserts with declared_birth_type NULL and ease NULL'` | R6 in the only form that matters: the first-tap row. |
| | `'lambing_consistency reports no mismatch when declared is NULL'` | The three-valued trap. |
| | `'lambing_consistency reports no mismatch when declared is 5 and six lambs are attached'` | The large-litter false badge. |
| | `'lambing_consistency reports a mismatch when declared is 2 and three lambs are attached'` | The case the view exists for; both numbers still readable afterwards. |
| | `'lamb_rearing returns the birth dam when no foster event exists'` | Arm 1 of the `COALESCE`. |
| | `'lamb_rearing returns NULL after a to_bottle foster event'` | Arm 3 — the one that is wrong by default. |
| | `'lamb_rearing returns the newest rearing dam after two fosters on the same day'` | `ORDER BY effective_at DESC, id DESC` — the `id` tiebreak, exercised with two identical instants. |
| | `'foster_events rejects outcome to_ewe with rearing_dam NULL, and to_bottle with a rearing dam'` | The paired CHECK, both directions. |
| | `'care_events rejects a row with both lambing and lamb set, and one with neither'` | The `= 1` CHECK, both directions. |
| | `'care_events rejects kind = warmed_up'` | The closed CHECK. A near-miss, not a nonsense value. |
| | `'lambs.sex NULL and lambs.sex unknown are both storable and are different rows'` | The distinction §12.4 turns on. |
| | `'lambs.birth_weight_g rejects 5 and 50000 and accepts 200 and 20000'` | The unit-slip band at both edges. |
| | `'a lamb with tag NULL is storable, and two of them coexist'` | *A lamb that died before tagging is counted, fully.* |
| | `'idx_lamb_tag_alive refuses a second ALIVE lamb on tag 12 and permits a dead one'` | Both directions. |
| | `'deleting a lambing cascades its lambs and its care events'` | `ON DELETE CASCADE` from the parent. |
| | `'deleting a ewe with a lamb whose birth_dam is her is REFUSED'` | `RESTRICT`. Pairs with T05's season-delete case. |
| `test/data/fostering_conservation_test.dart` | `'total lambs is invariant under a hand-written sequence of foster events'` | The database half of 03 §7's property test. |
| | `'born counts by birth_dam never change when a lamb is fostered'` | The industry model: a grafted lamb keeps its **birth type** and gains a new **rear type**. |
| `test/domain/uk_zone/schema_lambing_dst_test.dart` | `'a lambing at 00:30 BST on 29 March 2026 stores local_date 2026-03-29, not 2026-03-28'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The instant is 23:30 UTC on the **28th**; `local_date` is computed in Dart from the shepherd's civil day and must not be derived from the UTC date. This is the single case the histogram gets wrong if `local_date` is ever computed in SQL. |
| | `'a lambing at 01:30 on 25 October 2026 stores local_date 2026-10-25 for both candidate instants'` | The ambiguous hour happens twice. Both resolutions must land on the same civil day. |
| | `'a lambing recorded in the ambiguous hour keeps time_source = auto'` | Nothing was silently corrected from the shepherd's point of view, so no warning and no `original_effective`. |

### 5.5 Verification that the view compiles against real SQL

`views.drift` is parsed by drift's analyser at build time **and** executed by SQLite at
`createAll()`. Both must pass, and they fail differently: an analyser failure is a `build_runner`
error naming the file; a runtime failure is a `SqliteException` at the first `testDatabase()` call.
Run `build_runner` and the anchor test before you touch anything else.

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 held at *unrepresentable* (no `rearing_dam` column to dual-write,
  no `warnings` column to persist, the contradiction is a **view**) and *unpersistable* (the birth-dam
  trigger). §12.5 held by the quad on `Lambings`, `CareEvents` and `FosterEvents`. A rule that drops to
  merely *documented* has been deleted, whatever the prose says.
- **No birth-type chooser** (P8) — nothing in this task, and nothing that depends on it, offers one.
- **Irreversibility** — R6 (nullable `declared_birth_type`) and R37 (the quad on `FosterEvents`) are two
  of the three items 03 §11 requires asserted against the **committed schema JSON** in T08. Each one is
  a full table rebuild if it is found afterwards.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the birth-dam trigger refuses an update to lambs.birth_dam'` passes, and was seen to fail first for the stated reason
- [ ] `lambs.birth_dam` cannot be updated, by trigger
- [ ] `declared_birth_type` is nullable and has no default
- [ ] care events are rows, and their absence is *not recorded*
- [ ] `foster_events` is append-only and carries the provenance quad
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first.
fvm flutter test test/data/schema_lambing_test.dart

# 2. build_runner ONLY — it also type-checks views.drift.
dart run build_runner build --delete-conflicting-outputs

# 3. The cluster's tests, then the London-zone set — local_date is the one that matters.
fvm flutter test test/data/schema_lambing_test.dart test/data/fostering_conservation_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. The FK-index guard picked up four new tables.
fvm flutter test test/data/every_fk_is_indexed_test.dart

# 5. Nothing under drift_schemas/ moved.
git status --short drift_schemas/ test/drift/

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): the lambing cluster, the birth-dam trigger and the two views`
