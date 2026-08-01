# N20-T01 — `TreatmentRepository.recordTreatment` and its withdrawal child rows

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 1 of 7 |
| **Depends on** | N19-T07 · N05-T02 · N07-T05 |
| **Commit** | one commit · `feat(data): recordTreatment with withdrawal child rows` |

## 1. Why this task exists

The treatment write and its `treatment_withdrawals` child rows — **meat and milk
separately**, per N00-T04's ruling. No child row means *not recorded*; that is the whole mechanism, and
a repository that writes a zero-day row *to be safe* has defeated §12.1 in one line.

This is the eleventh of the twelve repositories (`03` §5.14, R19) and the only one whose correctness
is measured by a row it does **not** write. Everything difficult about it is a refusal: it does not
default, it does not coerce, it does not consult the free tier, it does not compute a warning, and it
does not touch a table another repository owns. The one thing it computes — the clear date — it
computes exactly once and stores, because that value is *what the app told the user on the day* and it
gets printed into a medicine book somebody may hand to a vet.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.8** | the two tables in full: `Treatments`' four indexes, the `(ewe IS NOT NULL) + (lamb IS NOT NULL) = 1` CHECK, the RESTRICT/CASCADE asymmetry and why; `TreatmentWithdrawals`' six CHECKs, `uniqueKeys {treatment, target}`, and *"NO DEFAULT. NO clientDefault."* on `days` |
| `docs/engineering/03-data-model-and-schema.md` | §2, §3, §5.12, §5.14 | `mixin Identified`, `uid` as UUID v7 and `id` never leaving the device, the `rt_*` route vocabulary as a RESTRICT foreign key onto `vocab_terms.key`, and the closed writer list |
| `docs/engineering/05-domain-correctness.md` | **§3.3** (the domain-state → row mapping: *"no row means not recorded"*), **§3.5** (`clearDateFor`, and the zero-day case), **§3.8** (computed once, inside the same `db.transaction`, and never rewritten by anything but a user edit), §3.9 (the two gates), §3.10 path 3 (a voided treatment's stored date is never recomputed) | the arithmetic call site and the storage rule |
| `docs/engineering/05-domain-correctness.md` | §4.1–§4.2 | `RecordedTime.capture(now)` and the four provenance columns, with `administered_at` as one of the three documented event-time exceptions (R37) |
| `docs/engineering/CONVENTIONS.md` | §2.4 (`WriteOutcome` and its three variants), **§2.7** (`WithdrawalPeriod`, `WithdrawalTarget`, `clearDateFor`), §2.13 (`TreatmentRepository`, `recordTreatment`, `voidTreatment`), §3.1 (`treatmentRepositoryProvider`), §4.1, §4.6, R3, R8, R15, R18, R19, R23, R32, R33, R37, R53 | every name and signature in this file |
| `docs/engineering/01-architecture.md` | §4 | event verbs, one `transaction()` per mutation, nothing side-effecting inside it, and why there is no `save(aggregate)` |
| `docs/engineering/12-testing.md` | §3.1, §3.3 (`testDatabase()`, real SQLite over mocks), §2.4 (where a zone-pinned data test lives), **§10.3** (the published policy file: *"no row implies NotRecorded, and NotApplicable is an explicit marker"*) | the test tier and one published test this task must make compile |
| `docs/engineering/11-monetization-and-store.md` | §8, §9 | *"It never blocks a treatment, a withdrawal period, a clear date or the medicine book"* — this verb takes no `EntryContext` |
| `shed-book-spec.md` | §7.5, §12.1 | product, dose, route, batch, date and withdrawal in days; never default one |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 (N07-T05's schema-refusal anchor), S10 (N24-T04 writes the reminder row **inside this transaction**) | why the transaction is one function and stays one |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the verb, the child rows and the clear date are its subject |
| `shed-write-path` | one transaction, one `appNow()`, the provenance quad |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/treatment_repository_test.dart`
- **Test** — `'recordTreatment writes no withdrawal row when the user entered none'`
- **Assertion, spelled out** — call `recordTreatment` with `withdrawals: const []` — **not** with a
  `WithdrawalNotRecorded()` in the list, and not with a null; then assert three things in order: the
  returned value is a `WriteCommitted` whose `insertedId` is the new treatment's id; the treatment row
  exists; and `await db.select(db.treatmentWithdrawals).get()` is **empty**. Finish with
  `expect(await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.meat), isA<WithdrawalNotRecorded>())`,
  because absence *is* the state and a test that only counts rows does not say so.
- **Why it is red today** — nothing records a treatment, and the obvious implementation writes a row with `days = 0`.

```bash
fvm flutter test test/data/treatment_repository_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the verb, one transaction, child rows only when the user entered a period.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 and 4 only, plus step 7's data tier. **Steps 1, 2, 5 and 6 are skipped and the
commit message says so.** Step 1 (schema): `treatments` and `treatment_withdrawals` were written in
N07-T05 and snapshotted in N07-T08 — reaching the schema here is not a shortcut, it is a migration on
somebody else's phone. Step 2 (domain): `WithdrawalPeriod`, `WithdrawalTarget` and `clearDateFor` are
N05's — reference them, never re-declare them. Steps 5 and 6 are T02's.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/data/treatment_repository.dart` | **new** | `final class TreatmentRepository`, `recordTreatment` and `withdrawalFor`. Eleventh of the twelve (R19). `voidTreatment` is T05's, the two reads are T04's and T06's |
| 2 | `lib/data/providers.dart` | edit | `treatmentRepositoryProvider`, `FutureProvider<TreatmentRepository>`, keepAlive, derived from `databaseProvider`. It takes no gateway and no clock (R19) |
| 3 | `lib/data/models.dart` | **no change** | `Treatment` and `TreatmentWithdrawal` are already re-exported (R20, N07-T05). Confirm; do not re-add |
| 4 | `lib/data/failure_mapping.dart` | edit **only if** | the `UNIQUE (treatment, target)` violation and the `rt_*` RESTRICT violation must map to a `ShedFailure` a shepherd can act on. Read `shedFailureFrom` first — the likely answer is that `DatabaseUnreadable`'s extended result code already covers both, and no change is the better outcome |
| 5 | `test/data/treatment_repository_test.dart` | **new** | the anchor plus the twelve cases in §5.4 |
| 6 | `test/data/treatment_ambiguous_hour_test.dart` | **new**, `@Tags(['uk-zone'])` | the write half of the DST cases: the repeated hour, and the 168-hour clear date across spring forward |
| 7 | `test/policy/withdrawal_has_no_default_test.dart` | edit | add `12 §10.3`'s second published test — the repository half of gate 2. The schema half landed in N07-T08; the widget half is T02's |
| 8 | `test/support/seeds.dart` | edit | `seedTreatment(db, product:, withdrawalDays:)` — `12 §10.1` and `12 §5.1` already call it by that name and it does not exist yet |

### 5.2 The signatures

`CONVENTIONS` §2.13 writes `Future<WriteOutcome> recordTreatment(...)` with no parameter list. This
task declares it. Everything below follows a published shape rather than inventing one.

```dart
// lib/data/treatment_repository.dart — CONVENTIONS §2.13 (R18, R19, R32), 03 §5.8.
final class TreatmentRepository {
  TreatmentRepository(this._db);
  final AppDatabase _db;                       // no Clock parameter, ever (R19)

  /// The event verb. One transaction, one appNow(), 0..2 child rows.
  ///
  /// `withdrawals` is a LIST of periods, never `int? meatDays` and never a
  /// nullable pair: an absent entry for a target IS `WithdrawalNotRecorded`
  /// (03 §5.8), so there is no argument whose default could mean zero days.
  /// An empty list is the ordinary case, not an error.
  ///
  /// The subject is a ewe XOR a lamb, mirroring `enterPen`'s published shape
  /// (CONVENTIONS §2.13). The XOR is held by
  /// `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)` — see §5.3 item 2.
  Future<WriteOutcome> recordTreatment({
    EweId? ewe,
    LambId? lamb,
    required String productName,
    String? doseText,
    String? route,                             // a vocab_terms key: 'rt_*'
    String? batchNo,
    String? note,
    List<WithdrawalPeriod> withdrawals = const [],
  });

  /// T05's verb. Declared here so the class is whole; implemented there.
  Future<WriteOutcome> voidTreatment(TreatmentId id);

  /// `12 §10.3` calls this with one argument. It needs two: a treatment has
  /// 0..2 withdrawals and one period cannot answer for both targets. Returns
  /// `WithdrawalNotRecorded` when there is no row — never null, never zero.
  Future<WithdrawalPeriod> withdrawalFor(TreatmentId id, WithdrawalTarget target);

  // Two more reads land later and are listed so the class reads whole:
  //   Future<TreatmentRow?> lastTreatment();                  // T04
  //   Stream<List<TreatmentRow>> watchTreatments(TreatmentMode mode);   // T06
  // Neither is written here. `TreatmentRow` is T06's type and
  // `TreatmentWithdrawalRow` is T03's, so declaring them now would put two
  // unused shapes in `lib/data/` and invite a third spelling.
}
```

The body, in the shape `00-README` §8 step 10 fixes — `appNow()` **once**, `RecordedTime.capture`,
`newUid()`, everything inside one `_db.transaction()`:

```dart
Future<WriteOutcome> recordTreatment({ /* … */ }) async {
  final now = appNow();                                    // ONCE per mutation (R23)
  final time = RecordedTime.capture(now);

  try {
    final id = await _db.transaction(() async {
      final season = await _seasonFor(ewe: ewe, lamb: lamb);          // §5.3 item 3
      final treatmentId = await _db.into(_db.treatments).insert(
        TreatmentsCompanion.insert(
          uid: newUid(),                                   // UUID v7, the export identity
          season: season,
          ewe: Value(ewe?.value),
          lamb: Value(lamb?.value),
          productName: productName,
          doseText: Value(doseText),                       // stored VERBATIM, never parsed
          route: Value(route),
          batchNo: Value(batchNo),
          note: Value(note),
          administeredAt: time.effective,
          capturedAt: time.capturedAt,
          timeSource: Value(TimeSource.autoCaptured.key),  // explicit — §5.3 item 5
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final period in withdrawals) {
        // Three arms, and one of them writes NOTHING. That is the whole
        // §12.1 mechanism, expressed as an exhaustive switch (05 §3.3).
        switch (period) {
          case WithdrawalDays(:final days, :final target):
            final clear = clearDateFor(administeredAt: time.effective, days: days);
            await _db.into(_db.treatmentWithdrawals).insert(
              TreatmentWithdrawalsCompanion.insert(
                uid: newUid(),
                treatment: treatmentId,
                target: target.key,
                kind: 'days',
                days: Value(days),                         // 0 is a real value
                clearDate: Value(clear.date),              // computed ONCE, here
                createdAt: now,
                updatedAt: now,
              ),
            );
          case WithdrawalNotApplicable(:final target):
            await _db.into(_db.treatmentWithdrawals).insert(
              TreatmentWithdrawalsCompanion.insert(
                uid: newUid(),
                treatment: treatmentId,
                target: target.key,
                kind: 'not_applicable',                    // days and clear_date stay NULL
                createdAt: now,
                updatedAt: now,
              ),
            );
          case WithdrawalNotRecorded():
            break;                                         // no row. That IS the state.
        }
      }
      return treatmentId;
    });
    return WriteCommitted(insertedId: id);
  } catch (e) {
    return WriteFailed(shedFailureFrom(e));                // never rethrow (R32)
  }
}
```

`insertedId` is a raw `int?` on `WriteCommitted` and is wrapped by the one call site that reads it —
there is no `WriteOutcome<T>` and no `WriteCommitted{id}` (R3, R8). `recordTreatment` is **not** one
of the two verbs that return an id and throw: `beginLambing` and `addLamb` are the only two (R32).

### 5.3 The details that are easy to get wrong

1. **`WithdrawalNotRecorded` in the list writes nothing, and passing it is legal.** The screen builds
   the list from what the shepherd chose per target, and *not recorded* is one of the three choices
   (07 §10.2). The switch arm is `break`, never an `insert` with `days: null` — a `kind` of
   `'not_recorded'` does not exist and the `CHECK (kind IN ('days','not_applicable'))` would refuse
   it. Absence is the state; there is no third `kind`.
2. **The subject is a ewe XOR a lamb, and the database is the gate.** Two nullable named parameters
   mirror `enterPen(PenId, {EweId?, List<LambId>})`, the published shape for a polymorphic subject
   (`CONVENTIONS` §2.13). Add a debug `assert((ewe == null) != (lamb == null))` so the mistake is
   loud in a test, and let `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)` be the real refusal in
   release. A sealed `TreatmentSubject` would make it unrepresentable and is the better type — but it
   is a new file in `lib/domain/`, and `CONVENTIONS` §1 is the authority on which files exist, so it
   is a numbered ruling in §6 and not a repository author's decision. Route it to the owner if the
   assert ever fires in real use.
3. **`treatments.season` — no document says which season a treatment is filed under, so this task
   records the rule in `03` §5.8 in the same commit.** A **ewe's** treatment takes
   `app_settings.current_season`; a **lamb's** takes the lamb's lambing season. The reason is
   `ON DELETE CASCADE`: a lamb cascades from its lambing, which cascades from its season, so a lamb
   treatment filed under a *different* season would be deleted when that other season is deleted,
   while the lamb it belongs to lives on — a medicine record vanishing from an animal that still
   exists. Read the season inside the transaction; `SettingsRepository` owns *writes* to
   `app_settings`, and reading it here is not a writer conflict.
4. **`recordTreatment` takes no `EntryContext` and never calls `FreeTierPolicy`.** Treatments are
   never capped (07 §10.3's over-cap row is the word *Nothing*; 11 §9: *"It never blocks a treatment,
   a withdrawal period, a clear date or the medicine book"*). `createEwe` takes one and this does not;
   copying `createEwe`'s shape is the mistake. There is no `over_free_cap` column on `treatments`.
5. **Pass `time_source` explicitly even though the column carries `withDefault(const Constant('auto'))`.**
   A write whose provenance depends on a schema default is a write whose provenance changes when the
   schema does, and provenance is a §12.5 mechanism rather than a convenience. `original_effective`
   stays NULL; the paired `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))` makes
   any other combination unstorable.
6. **`administered_at`, not `occurred_at`.** One of exactly three documented exceptions to the
   event-time column name (R37), because a treatment is dated by when it was given. Grep this file for
   `occurredAt` before committing — drift will happily let you name a local variable that way and the
   next reader will look for a column that does not exist.
7. **`clearDateFor` is called inside the transaction, once per `WithdrawalDays` row, and its result is
   stored.** Not `computeWithdrawalStatus` — that function maps a period to a *status* and is the
   display's vocabulary, not the writer's. And not once per treatment: two targets with different day
   counts produce two different clear dates, which is exactly why `clear_date` sits on the child row
   and not on `Treatment` (05 §3.3).
8. **`days: 0` is a real write.** `WithdrawalDays.asEnteredByUser(days: 0, target: meat)` is valid,
   stores `days = 0`, and its clear date is **tomorrow** — the period elapses at the moment of
   administration, which is almost never local midnight, so today is a partial day (05 §3.5). Any code
   that special-cases zero, skips the row, or writes `clear_date` as today has re-introduced the exact
   confusion the sealed type removed.
9. **The dose is text and stays text.** `dose_text` is stored verbatim: never parsed, never
   normalised, never split into a number and a unit (09 §3.3 column 8). The app has no opinion about a
   dose (§12.2). The same applies to `batch_no` and `note`.
10. **`route` is a `vocab_terms.key`, and the foreign key is RESTRICT.** Only `rt_*` keys belong here;
    `test/data/vocab_list_scope_test.dart` asserts the list scope per column. A key from another list
    (`dc_*`, `mp_*`) satisfies the foreign key and is still wrong, which is why the scope test exists.
11. **Reject, do not sanitise.** `CHECK (length(trim(product_name)) > 0)` and
    `withLength(min: 1, max: 120)` are refusals. This repository does not trim-and-accept, does not
    truncate at 120, and does not substitute a placeholder product name (05 §8.4). The control stops
    an empty product name; the database stops everything else.
12. **The repository may not import `lib/domain/validation/`** (R53, `layer.data_no_validation`).
    `checkClearDate` is the **controller's** to call, in T06, against the freshly-watched row. A
    repository that could produce a `Warning` could persist one, and there is no `warnings` column.
13. **One `transaction()`, and nothing side-effecting inside it** — no notification call, no file
    write, no share sheet. Keep the whole body in a single `_db.transaction(() async { … })` because
    **N24-T04 adds the withdrawal-end reminder row to this exact transaction** (decision #63, critique
    S10). A body split across two transactions makes that impossible without a rewrite.
14. **Both tables carry `mixin Identified`, so both carry P1's `struck` / `struck_at`** (N00-T05). The
    inserts above set neither: a new row is not struck, and `struck` has
    `withDefault(const Constant(false))`, which is legal precisely because it is not a column that
    could encode veterinary advice (03 §2 point 5). Read the R75-or-later ruling in `CONVENTIONS` §6
    before writing the companions — it decides whether treatments' void is the strike or sits beside
    it, and T05 depends on the answer.
15. **`newUid()` per row, parent and each child.** It is the one `package:uuid` call site (R15), the
    export identity, and `treatment_withdrawals` rows are exported and restored in their own right
    (09 §7). `id` never leaves the device.

### 5.4 The full test set

**`test/data/treatment_repository_test.dart`** — new.

| Case | What it pins |
|---|---|
| `'recordTreatment writes no withdrawal row when the user entered none'` | **the anchor.** Empty list → zero child rows → `withdrawalFor` answers `WithdrawalNotRecorded` |
| `'a WithdrawalNotRecorded in the list writes no row and is not an error'` | the third switch arm, reached the way the screen will reach it |
| `'meat and milk are two rows, each with its own days and its own clear date'` | one bottle, two figures; `UNIQUE (treatment, target)` satisfied, not violated |
| `'a second row for the same target is refused and the whole transaction rolls back'` | the unique key; assert **zero** treatments afterwards, not one orphan |
| `'WithdrawalNotApplicable stores kind not_applicable with days and clear_date NULL'` | the paired CHECKs, and the state that is *not* the same as not recorded |
| `'a zero-day withdrawal stores days = 0 and a clear date of tomorrow'` | 05 §3.5. The case that proves `0` flows through real code |
| `'the clear date is computed once at write time and equals clearDateFor for the stored inputs'` | recompute in the test from `administered_at` and `days`, assert equality **once** — this is the last moment the two are allowed to agree by construction |
| `'the treatment carries the provenance quad: administered_at equals captured_at, time_source auto, original_effective NULL'` | §12.5 at the write |
| `'passing both a ewe and a lamb, or neither, returns WriteFailed and inserts nothing'` | the XOR CHECK, and that the failure is mapped rather than thrown |
| `'a lamb treatment is filed under the lamb lambing season, not app_settings.current_season'` | seed a lamb in season 2025 while `current_season` is 2026 |
| `'a route key from another vocabulary list is refused by the RESTRICT foreign key'` | pass `dc_starvation` where an `rt_*` key belongs |
| `'recordTreatment commits at the ewe cap and never returns WriteRefused'` | seed `flock_15_at_cap`-shaped data through `seeds.dart`; treatments are never capped |
| `'recordTreatment returns WriteCommitted and never an id, and never throws'` | the R32 shape, held by the compiler and by the assertion |
| `'dose_text, batch_no and note round-trip verbatim, including a comma and a newline'` | nothing is parsed or normalised |

**`test/data/treatment_ambiguous_hour_test.dart`** `@Tags(['uk-zone'])` — new.

| Case | What it pins |
|---|---|
| `'a treatment recorded AT 01:30 in the repeated hour reads back as 01:30 after a reopen'` | write through `atFixed(DateTime(2026, 10, 25, 1, 30), …)` against a real file, close, reopen with `seedOnCreate: false`, assert `administeredAt.local.hour == 1` and `timeSource == TimeSource.autoCaptured` |
| `'two treatments an hour apart inside the repeated hour order by the instant, not the wall clock'` | 01:30 BST then 01:30 GMT differ by exactly 3 600 000 ms; `ORDER BY administered_at` must separate them. A civil-time implementation ties here |
| `'a 7-day withdrawal administered 20:00 on 26 March 2026 stores clear_date 2026-04-03'` | DST-5. The period is 168 h absolute and elapses at **21:00 on 2 April**; civil-day arithmetic gives 167 h and the wrong date, in the week UK lambing peaks |
| `'a zero-day withdrawal administered at 01:30 in the repeated hour clears the next day, not that day'` | the ceil, in the hour where a naive local-midnight comparison is ambiguous |

**`test/policy/withdrawal_has_no_default_test.dart`** — extended with `12 §10.3`'s second test:
`'no row implies NotRecorded, and NotApplicable is an explicit marker'`. Note the published snippet
calls `repo.withdrawalFor(TreatmentId(1))` with one argument; it needs the target (§5.2), and the
schema half of the file is N07-T08's and is not touched here.

The `uk-zone`-tagged file carries the `setUpAll` offset assertion from `05` §2.9 and **fails loudly**
rather than skipping when the zone is wrong. A skipped safety test is a broken safety test.

## 6. Constraints that bind this task

- **§12.1, held at *unpersistable*.** No child row means *not recorded* — that is the whole mechanism. A `treatment_withdrawals` row written with zero days *to be safe* has defeated the rule in one line, and the column has neither a `DEFAULT` nor a `clientDefault` to make it look accidental. §12.5 rides with it: the clear date is computed exactly once and stored with the provenance quad, because that number is what the app told the shepherd on the day and it gets printed into a book somebody may hand to a vet.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The schema is frozen.** N07-T08 committed `drift_schema_v1.json`. This task adds no column, no index and no CHECK; if it appears to need one, that is a ruling for the owner, not an edit.
- **§12.1 is held at *unpersistable* here** — by the absence of a row and by a column with no default. Anything that moves it to *documented* has deleted it, whatever the comment says.

## 7. Definition of Done

- [ ] `'recordTreatment writes no withdrawal row when the user entered none'` passes, and was seen to fail first for the stated reason
- [ ] no child row is written when nothing was entered
- [ ] meat and milk are separate rows
- [ ] the clear date is computed once, here, and stored
- [ ] the reminder row for the withdrawal end lands in this same transaction in N24-T04
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `lib/data/treatment_repository.dart` writes exactly two tables, takes no `EntryContext`, and imports no `lib/domain/validation/`
- [ ] the `treatments.season` rule for a ewe subject and a lamb subject is recorded in `03-data-model-and-schema.md` §5.8 in this commit
- [ ] `seedTreatment` exists in `test/support/seeds.dart` with the signature `12 §10.1` already calls

## 8. Verification

```bash
fvm flutter test test/data/treatment_repository_test.dart
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "domain/validation" lib/data/treatment_repository.dart
grep -rn "?? 0\|days ?? \|int? days\|withDefault" lib/data/treatment_repository.dart
grep -rn "EntryContext\|FreeTierPolicy\|occurredAt" lib/data/treatment_repository.dart
git status --porcelain drift_schemas/ lib/core/db/
make check
make test
```

The three greps must print nothing. The first is R53. The second is the §12.1 coercion set — `?? 0`
anywhere within reach of a withdrawal is the named anti-pattern (05 §3.9). The third is the free tier
this verb must not consult and the column name that does not exist on this table. `git status` must
show a clean `drift_schemas/` and `lib/core/db/`: a diff there is a schema change in the wrong epic,
and `codegen` will fail the PR for the same reason a day later.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): recordTreatment with withdrawal child rows`
