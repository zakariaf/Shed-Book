# N19-T01 — `PenRepository.enterPen` / `exitPen(PenExitReason)`

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 1 of 7 |
| **Depends on** | N18-T05 · N07-T05 |
| **Commit** | one commit · `feat(data): enterPen and exitPen, refused by the index not by Dart` |

## 1. Why this task exists

The database itself refuses two ewes in pen 3 — the partial unique index
`WHERE exited_at IS NULL` from N07-T05, not a check in Dart, because the Dart check is the one that gets
skipped by the second code path.

Everything the rest of this epic renders comes out of these two verbs, and both of them are the kind
of write that is invisible when it is wrong: an occupancy with no exit reason, an entry time with no
provenance, or a ewe silently in two pens at once are all states a board would print without
complaint. The index, the paired CHECKs and the quad are what make those states unstorable rather
than merely unlikely.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (the whiteboard replacement — occupant and entry time per pen), §5 (*"assume the phone dies; every write is committed immediately"*), §12.5 | what these two verbs are for, and why there is no draft between them |
| `docs/engineering/03-data-model-and-schema.md` | §5.9 (the three tables, `idx_penocc_one_open`, the seven `customConstraints`), §8 (turning out is one transaction; hours are never stored), §5.14 (`PenRepository` owns `pens`, `pen_occupancies`, `pen_occupancy_lambs`; one `db.transaction` per mutation) | the storage shape, and every constraint this verb must satisfy |
| `docs/engineering/CONVENTIONS.md` | §2.13 (the canonical signatures), §4.1 (`pen_repository.dart`), §4.6 (`entered_at` is one of the three documented exceptions to `occurred_at`), **R63** (`enterPen` and `exitPen` on the repository, `turnOut` on the controller), R32 (only two verbs return an id and throw), R37 (the quad and its column names), R53 (`lib/data/` may not import `lib/domain/validation/`), R15 (`newUid()`) | **BINDING** on the signatures, the file and the column names |
| `docs/engineering/01-architecture.md` | §4.2 (event verbs; the row is created on screen entry), §4.3 (nothing side-effecting inside a transaction), §5.2 (`WriteOutcome`'s three variants), §5.3 (`shedFailureFrom`, and never logging an exception message), §5.4 (returned versus thrown) | the shape of every write in this app |
| `docs/engineering/12-testing.md` | §3.1–§3.3 (`NativeDatabase.memory()`, never a mock; **the two published `PenRepository` tests**), §2.3–§2.5 (the ambiguous hour and the three commands), §5.4 (`seeds.dart` owns `seedOpenOccupancy`) | the anchor, its siblings and where the seed helper lives |
| `docs/engineering/05-domain-correctness.md` | §2.2 (`Instant` is epoch millis), §4.2 (`RecordedTime.capture`), §2.9 (DST-1: nine hours, not ten) | the time types the verbs write |
| `docs/engineering/07-screens.md` | §9.5 (the actions these verbs serve), §15.1 (undo per verb: `enterPen` is a hard delete; `exitPen` clears both columns and only when no later occupancy exists) | what the caller will ask of them next |
| `docs/engineering/02-state-di-navigation.md` | §5.1 (`penRepositoryProvider`), §7.1 rule 1 (`exitPen` is idempotent after completion; a UI cooldown is not the mechanism) | the provider and the double-tap contract |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the two event verbs and their transactions |
| `shed-drift-schema` | the partial index is the mechanism and this write must respect it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/pen_repository_test.dart`
- **Test** — `'the partial unique index refuses a second open occupancy for pen 3'`
- **Why it is red today** — nothing records pen occupancy: the tables landed in N07-T05 but no verb writes them, so the partial unique index has never been exercised by anything.

```bash
fvm flutter test test/data/pen_repository_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion until it can only pass against a schema that carries the index. Seed one pen and
two ewes. The first `enterPen(const PenId(3), ewe: const EweId(1))` returns `isA<WriteCommitted>()`.
The second, with `EweId(2)`, returns `isA<WriteFailed>()` **and** the raised `SqliteException` carries
`extendedResultCode == 2067` with a message naming `idx_penocc_one_open`. Then close the first
occupancy and assert a third `enterPen` on the same pen commits: the index refuses a second **open**
row, never a second row. A test that only asserts `WriteFailed` passes against a Dart guard, which is
the implementation this task exists to forbid.

**Green.** The minimum code that passes, and nothing beyond it — both verbs, one transaction each, the exit reason as a closed enum.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (the write path), step 4 (one provider line) and step 7 (tests).** No schema — the three
tables were frozen in N07-T05 and snapshotted in N07-T08; say so in the commit message. No domain
(`timeSincePenned`, `isReadyToTurnOut` and `enum PenExitReason` all landed in N06-T07), no UI, no ARB
string.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/pen_repository.dart` | **New.** `final class PenRepository` taking `AppDatabase` and nothing else — no `Clock`, no gateway, no interface (R18, decision #15). `enterPen`, `exitPen`, the read helper `openOccupancyFor`, and one private `_write` wrapper |
| 2 | `lib/data/providers.dart` | **Edit, one entry.** `penRepositoryProvider` — `FutureProvider<PenRepository>`, keepAlive, `PenRepository(await ref.watch(databaseProvider.future))`. CONVENTIONS §3.1 already carries the row; this is the line that fills it |
| 3 | `test/support/seeds.dart` | **Edit.** `seedPen` and `seedOpenOccupancy` — 12 §5.4 names the second one and T04's widget tests call it verbatim. Both write through drift, never through the repository: a seed that goes through the code under test cannot fail independently of it |
| 4 | `test/support/reads.dart` | **Edit.** `closedOccupanciesForPen(db, PenId)` — 02 §7.1's double-tap test calls it, and an assertion with a `select` inline is the thing this file exists to prevent |
| 5 | `test/data/pen_repository_test.dart` | **New.** The anchor plus §5.4's cases |
| 6 | `test/data/pen_repository_dst_test.dart` | **New.** `@Tags(['uk-zone'])`, with the `setUpAll` offset guard N04-T08 established |

### 5.2 The signatures

R63 fixes both verbs and they do not change. The occupancy row — not the pen — is what closes, and
the reason is not optional, because `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))` makes the
half-written form unstorable.

```dart
// lib/data/pen_repository.dart
//
// Owns writes to `pens`, `pen_occupancies` and `pen_occupancy_lambs` (03 §5.14).
// Nothing else may insert or update them; `RestoreService` is the one exception
// and it writes into a NEW file (04 §7).

final class PenRepository {
  PenRepository(this._db);
  final AppDatabase _db;

  /// Opens an occupancy. `ewe` is nullable because a pen may hold lambs with no
  /// ewe — an orphan pen — and 03 §5.9 declares the column that way.
  Future<WriteOutcome> enterPen(PenId pen, {EweId? ewe, List<LambId> lambs = const []});

  /// Closes it. Idempotent once closed (02 §7.1 rule 1): a second call on a row
  /// that already carries `exited_at` writes nothing and returns
  /// WriteCommitted. That is the double-tap defence at the layer that can hold
  /// it — `guard()` prevents concurrency, not repetition.
  Future<WriteOutcome> exitPen(PenOccupancyId occupancy, {required PenExitReason reason});

  /// The open occupancy for a pen, or null. 12 §3.3 calls it by this name.
  Future<PenOccupancy?> openOccupancyFor(PenId pen);
}
```

The body of `enterPen`, because four things have to happen in one transaction and in this order:

```dart
Future<WriteOutcome> enterPen(PenId pen, {EweId? ewe, List<LambId> lambs = const []}) =>
    _write(() async {
      final Instant now = appNow();                     // ONCE per mutation (00-README §8 step 10)
      final RecordedTime t = RecordedTime.capture(now); // §12.5 provenance, auto
      final int season = await _currentSeason();        // read inside the transaction; see §5.3
      final int id = await _db.into(_db.penOccupancies).insert(
            PenOccupanciesCompanion.insert(
              uid: newUid(),                            // the export identity (R15)
              pen: pen.value,
              season: season,
              ewe: Value(ewe?.value),
              enteredAt: t.effective,
              capturedAt: t.capturedAt,
              timeSource: Value(t.source.key),          // 'auto'
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (final lamb in lambs) {
        await _db.into(_db.penOccupancyLambs).insert(
              PenOccupancyLambsCompanion.insert(occupancy: id, lamb: lamb.value),
            );
      }
      return id;                                        // carried out as WriteCommitted(insertedId:)
    });
```

`exitPen` is 03 §8's statement and nothing else — both columns in one `UPDATE`, guarded by the
`exited_at IS NULL` predicate that makes the second call a no-op:

```sql
UPDATE pen_occupancies
   SET exited_at = ?, exit_reason = ?, updated_at = ?
 WHERE id = ? AND exited_at IS NULL;
```

### 5.3 The details that are easy to get wrong

1. **The refusal must come from the index, and a Dart pre-check would hide that.** Do not write
   `if (await openOccupancyFor(pen) != null) return WriteFailed(...)`. 12 §3.3's reason line is
   explicit — *"the partial unique index `WHERE exited_at IS NULL` is the guard, not a Dart check the
   next code path can forget"* — and a repository-level guard makes the anchor pass against a schema
   with no index at all, which is the regression it exists to catch. `openOccupancyFor` exists for the
   UI and for tests, never as a gate in front of `enterPen`.
2. **The exception is a UNIQUE violation and `shedFailureFrom` has no arm for it.** SQLite raises
   `SQLITE_CONSTRAINT_UNIQUE` — `extendedResultCode` 2067, primary code 19 — and 01 §5.3's `switch`
   maps 13, 10, 11, 26, 8, 3 and 14 only, so 19 falls through to `UnexpectedFailure` and the shepherd
   would read *"Something went wrong and nothing was saved."* **Do not add a seventh `ShedFailure`
   variant here**: that is a `lib/core/` type change plus a doc amendment, and it is not what this
   task is for. The case is unreachable from the UI by construction — T06's move sheet lists only
   *empty* pens (Indelible §8 screen 7) — so what ships is the honest mapping plus a test that names
   the constraint. If the field night shows a shepherd meeting that message in anger, the amendment
   rule applies and the ruling is the owner's.
3. **The message names the *index*, not a column.** For a partial unique index SQLite reports
   `UNIQUE constraint failed: index 'idx_penocc_one_open'`, not `pen_occupancies.pen`. A test that
   greps for the column name passes today and fails the first time somebody adds a table-level
   constraint, which is exactly backwards.
4. **`assert(e is! Error, …)` in `_write` does not fire on a constraint violation** — `SqliteException`
   is an `Exception`, not an `Error` — so the failure is returned in debug as well as in release, and
   the anchor can assert on the returned value rather than on a thrown one.
5. **`pen_occupancies.season` is `NOT NULL` and `enterPen` has no season parameter.** Read
   `app_settings.current_season` **inside** the same transaction. It is nullable
   (`ON DELETE SET NULL`, 03 §5.13), so after a season delete it is genuinely absent — let the
   `NOT NULL` constraint refuse the insert and return `WriteFailed`. **Never invent a season** and
   never create one here: `SeasonRepository` owns `seasons` and `app_settings.current_season`
   (03 §5.14), and an occupancy filed under a season nobody chose is a row that vanishes when that
   season is deleted.
6. **`appNow()` is called exactly once per mutation.** Two calls give an `entered_at` and a
   `captured_at` that differ by a millisecond, which reads as *"the app captured this a moment after
   it happened"* — a small lie in the one column pair §12.5 exists to keep honest.
7. **`time_source` is `'auto'` and `original_effective` stays `NULL`.** The paired
   `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))` refuses every other
   combination. Write `'auto'` explicitly even though it is the column default, so the row does not
   depend on a default nobody can see at the call site.
8. **`PenOccupancyLambs` has no `mixin Identified`.** Its primary key is `{occupancy, lamb}` and it
   carries no `id`, no `uid` and no `created_at`. A companion that tries to set them will not compile;
   the reflex to give every table a uid is wrong for exactly this one.
9. **The lamb rows go in the same transaction as the occupancy.** A ewe penned now with her lambs
   filed a moment later is *mark as a group* half-done, and T06's group action depends on this being
   atomic.
10. **`exitPen` writes `exited_at` and `exit_reason` in one `UPDATE`.** Writing one and then the other
    is two statements against a CHECK that refuses the intermediate state, so the first one throws —
    which is the constraint working, and is still a bug.
11. **Nothing elapsed is computed, stored or returned here.** 01 §7.2 bucket A: *"hours since penned"*
    changes with no write, so any stored copy is wrong within a minute. This file contains no
    `Duration`, no `difference` and no `hours`.
12. **`lib/data/` may not import `lib/domain/validation/`** (R53, `layer.data_no_validation`). There is
    no warning this repository could produce and nowhere to put one; `WriteCommitted.warnings` is the
    controller's to fill.
13. **`enterPen` returns `WriteOutcome`, not a `PenOccupancyId`.** R32 closes the throwing list at two
    verbs — `beginLambing` and `addLamb` — and nothing in this epic joins it. The new id travels in
    `WriteCommitted.insertedId`, a raw `int` by design (01 §5.2); the one call site that needs it
    wraps it.
14. **`ON DELETE RESTRICT` on `pen` and on `ewe` means neither can be deleted once penned.** That is
    correct — the board is a record, not a whiteboard (03 §5.9) — and it is why a pen is
    *deactivated* (`is_active = 0`) rather than removed.
15. **The vocabulary is *turn out*, two words, and the stored key is `turn_out`** (CONVENTIONS §5.1,
    R49). `turnout` as one word is banned everywhere, including in the commit message.
    `PenExitReason.turnedOut` maps to `'turned_out'`; the enum is N06-T07's and this task does not
    redeclare it.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/pen_repository_test.dart` | `'the partial unique index refuses a second open occupancy for pen 3'` | **The anchor.** Both directions, and the constraint named |
| | `'exitPen closes the occupancy and preserves entered_at forever'` | 12 §3.3's published case, verbatim: `entered_at` unchanged, `exited_at` set, `exit_reason == 'turned_out'` |
| | `'enterPen writes the provenance quad with time_source auto and a null original_effective'` | §12.5 at the level that survives a reopen |
| | `'enterPen calls the clock once: entered_at equals captured_at'` | The one-`appNow()` rule, asserted on the row rather than on the source text |
| | `'enterPen with three lambs writes three pen_occupancy_lambs rows in the same transaction'` | The group verb's storage half |
| | `'enterPen with a null ewe and two lambs commits — an orphan pen is a real state'` | The nullable FK. T02's board must render it and the deck must not |
| | `'a second exitPen on a closed occupancy changes nothing and returns WriteCommitted'` | Idempotency (02 §7.1 rule 1) |
| | `'exit_reason cannot be written without exited_at, and exited_at cannot be written without a reason'` | The paired CHECK, both directions, by direct insert — the constraint behind `required reason` |
| | `'enterPen returns WriteFailed when app_settings.current_season is NULL'` | The post-season-delete state, refused by `NOT NULL` rather than by an invented season |
| | `'enterPen against a pen id that does not exist returns WriteFailed'` | The foreign key, not a Dart existence check |
| | `'openOccupancyFor returns null for a pen whose only occupancy is closed'` | The read helper's own edge, which the board reads as *empty* |
| | `'a pen with a closed occupancy cannot be deleted'` | `ON DELETE RESTRICT` — the board is a record |
| `test/data/pen_repository_dst_test.dart` `@Tags(['uk-zone'])` | `'an occupancy entered 22:00 on 28 March 2026 and exited 08:00 on 29 March spans nine hours of stored millis'` | DST-1 at the storage layer. The wall clock advanced ten hours; nine is correct and it errs toward turning out later. Asserted on `exited_at - entered_at`, never on a formatted string |
| | `'an occupancy entered at 01:30 on 25 October 2026 round-trips through a reopen with the same epoch millis'` | The **ambiguous hour**, which happens twice. `InstantConverter` must never re-derive an instant from a local rendering |
| | `'entering at 01:30 in the repeated hour and exiting at 01:30 the second time is one hour, not zero'` | The pair a wall-clock subtraction reports as zero — the case that makes *elapsed physical time* mean something |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **The five safety rules** — §12.5 is held here at *unrepresentable*: the quad and its two paired
  CHECKs, written in the same statement as the event time. §12.4 is held structurally by R53 — this
  file cannot see `lib/domain/validation/` and therefore cannot produce, apply or persist a
  correction.
- **Irreversibility** — none in this task, and that is worth saying: no schema, no snapshot, no native
  file. The rows it writes are permanent; the code that writes them is not.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the partial unique index refuses a second open occupancy for pen 3'` passes, and was seen to fail first for the stated reason
- [ ] the refusal comes from the index, proved by the raised constraint name
- [ ] `exitPen` requires a reason and has no default
- [ ] both verbs carry the provenance quad
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `enterPen` and `exitPen` each run exactly one `_db.transaction`, and `appNow()` is called once inside it
- [ ] `PenRepository` contains no `Duration`, no elapsed arithmetic and no statement that computes time
- [ ] a second `exitPen` on a closed occupancy is a no-op that returns `WriteCommitted`
- [ ] `lib/data/pen_repository.dart` imports nothing from `lib/domain/validation/` and nothing from `lib/features/`
- [ ] `test/data/pen_repository_dst_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is picked up by `TZ=Europe/London fvm flutter test --tags uk-zone`

> **Read the second DoD line honestly.** The constraint name comes off the raised `SqliteException`
> **in the test**, never out of `userMessage` and never into `LocalLog`: 01 §5.3 forbids putting an
> exception message anywhere near the user or the diagnostics file, because SQLite echoes the failing
> statement and its bound values — ewe tags among them. The test may read it; the app may not.

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/data/pen_repository_test.dart

# 2. Green, then the zone leg.
fvm flutter test test/data/pen_repository_test.dart test/data/pen_repository_dst_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Both gates.
make check
make test
```

```bash
grep -n "openOccupancyFor" lib/data/pen_repository.dart   # declared, and never called by enterPen
grep -n "appNow()" lib/data/pen_repository.dart           # once per verb, inside the transaction
grep -rn "domain/validation" lib/data/                    # expect nothing (R53)
grep -rn "turnout" lib/ test/                             # expect nothing — it is two words (R49)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): enterPen and exitPen, refused by the index not by Dart`
