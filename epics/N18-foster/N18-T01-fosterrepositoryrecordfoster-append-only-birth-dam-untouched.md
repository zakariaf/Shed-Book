# N18-T01 — `FosterRepository.recordFoster` — append-only, birth dam untouched

| | |
|---|---|
| **Epic** | [N18 — Foster](epic.md) · `00-README` §9 step 6 (4 of 5) |
| **Task** | 1 of 5 |
| **Depends on** | N17-T05 |
| **Commit** | one commit · `feat(data): recordFoster — append-only, birth dam immutable` |

## 1. Why this task exists

`FosterOutcome`: to a ewe, to a bottle, or removed unknown. The event is **appended**;
`birth_dam` is immutable by trigger (N07-T04). Both dams stay on the page forever, because *who bore
her* and *who reared her* are different questions and next season's decisions need both.

This is the twelfth and last repository in the closed set (`03` §5.14, R19) and the smallest: one
table, one verb, one transaction. Its whole difficulty is what it must **not** do — not update
`lambs`, not update `ewe_touches` or `ewe_summaries` (other repositories own those), not import
`lib/domain/validation/`, not read `app_settings.current_season`, and not accept a nullable ewe id.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 | Foster |
| `shed-book-spec.md` | §7.3 | birth dam and rearing dam as separate fields, reassignment in two taps or fewer |
| `docs/engineering/03-data-model-and-schema.md` | §5 | `foster_events`, the trigger and the `lamb_rearing` view |
| `docs/engineering/03-data-model-and-schema.md` | §7 | the full `FosterEvents` declaration, its five indexes, its six CHECKs, the view's three-armed `COALESCE`, the born-vs-reared invariant and the conservation test |
| `docs/engineering/03-data-model-and-schema.md` | §5.14, §2.1, §3 | one repository owns each table; `mixin Identified`; `uid` is a UUID v7 and `id` never leaves the device |
| `docs/engineering/CONVENTIONS.md` | §2.4, §2.9, §2.13, §3.1, §4.1, R15, R18, R19, R23, R32, R53, R64 | `WriteOutcome`, `FosterOutcome`, the verb signature, `fosterRepositoryProvider`, `newUid()`, `appNow()` |
| `docs/engineering/05-domain-correctness.md` | §4.2, §6.8–§6.10 | the provenance quad on `FosterEvents`; a fostered lamb is counted **once**, in the birth dam's litter, never the receiving ewe's |
| `docs/engineering/12-testing.md` | §3.1, §3.3, §2.4 | `testDatabase()`, real SQLite over mocks, and where a zone-pinned data test lives |
| `docs/engineering/01-architecture.md` | §4 | event verbs, one `transaction()` per mutation, nothing side-effecting inside it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the event verb and the append-only rule |
| `shed-drift-schema` | the trigger and the `lamb_rearing` view are what make this safe |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/foster_repository_test.dart`
- **Test** — `'recordFoster leaves birth_dam unchanged and appends a FosterEvent'`
- **Assertion, spelled out** — capture `birthDamBefore` from the lamb row **before** the write; call
  `recordFoster(lamb, ToEwe(other))`; then assert three things in this order: the returned value is a
  `WriteCommitted`; `db.select(db.fosterEvents)` has exactly one row whose `outcome` is `'to_ewe'` and
  whose `rearingDam` is `other.value`; and `readLamb(db, lamb).birthDam == birthDamBefore`. Never
  compare against `EweId(412)` — 412 is a **tag**, an `EweId` is a row id, and under the active-only
  uniqueness ruling a tag is not unique across time.
- **Why it is red today** — nothing records a foster, and the obvious implementation updates the lamb's dam column.

```bash
fvm flutter test test/data/foster_repository_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the verb, one transaction, the appended event, and a read-back proving the birth dam did
not move.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 and 4 only, plus step 7's data tier. **Step 1 is skipped and the commit
message says so**: `foster_events`, the `lamb_birth_dam_is_immutable` trigger and the `lamb_rearing`
view were written in N07-T04 and snapshotted in N07-T08. Reaching the schema here is not a shortcut,
it is a migration on somebody else's phone. Step 2 is skipped because `FosterOutcome` already exists
(N06-T01, R64) — reference it, never re-declare it. Steps 5 and 6 are T02's.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/data/foster_repository.dart` | **New.** `final class FosterRepository` and the one verb. The last of the twelve repositories (R19) |
| 2 | `lib/data/providers.dart` | Edit: add `fosterRepositoryProvider`, `FutureProvider<FosterRepository>`, keepAlive, derived from `databaseProvider`. It takes no gateway and no clock |
| 3 | `lib/data/failure_mapping.dart` | Edit **only if** a foreign-key violation on `rearing_dam` maps to a `ShedFailure` shape `shedFailureFrom` does not already cover. Read it first; the likely answer is no change, and no change is the better outcome |
| 4 | `lib/data/models.dart` | **No change.** `FosterEvent` is already re-exported (N07-T04). Confirm, do not re-add |
| 5 | `test/data/foster_repository_test.dart` | **New.** The anchor plus the cases in §5.4 |
| 6 | `test/data/fostering_conservation_test.dart` | **Extend.** N07-T04 landed the database-level halves; add the 200-random-move property test through the repository |
| 7 | `test/data/foster_ambiguous_hour_test.dart` | **New**, `@Tags(['uk-zone'])`. The data tier of `12 §2.4`, applied to `effective_at` |

### 5.2 The signatures

```dart
// lib/data/foster_repository.dart — CONVENTIONS §2.13 (R18, R19, R64).
final class FosterRepository {
  FosterRepository(this._db);
  final AppDatabase _db;                 // no Clock parameter, ever (R19)

  /// The event verb. `setRearingDam(LambId, EweId?)` is a BANNED signature
  /// (07 §8.4 rule 1): it merges to_bottle (null by intent) with
  /// removed_unknown (null by omission), and the rearing-credit numbers differ.
  Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome);
}
```

The body, in the shape `00-README` §8 step 10 fixes — `appNow()` **once**, `RecordedTime.capture`,
`newUid()`, everything in one `_db.transaction()`:

```dart
Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome) async {
  final now = appNow();                          // ONCE per mutation (R23)
  final time = RecordedTime.capture(now);
  // The CHECK ((outcome = 'to_ewe') = (rearing_dam IS NOT NULL)) is why these
  // two are derived together from one switch and never from two arguments.
  final EweId? dam = switch (outcome) { ToEwe(:final ewe) => ewe, _ => null };

  try {
    final id = await _db.transaction(() async {
      final season = await _seasonOfLamb(lamb);  // the LAMB's season — §5.3.1
      return _db.into(_db.fosterEvents).insert(
        FosterEventsCompanion.insert(
          uid: newUid(),                         // UUID v7, the export identity
          lamb: lamb.value,
          season: season,
          rearingDam: Value(dam?.value),
          outcome: outcome.key,                  // R64: the key lives on the type
          effectiveAt: time.effective,
          capturedAt: time.capturedAt,
          timeSource: Value(TimeSource.autoCaptured.key),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
    return WriteCommitted(insertedId: id);
  } catch (e) {
    return WriteFailed(shedFailureFrom(e));      // never rethrow: R32
  }
}
```

`insertedId` is a raw `int?` on `WriteCommitted` and is wrapped by the one call site that reads it —
there is no `WriteOutcome<T>` and no `WriteCommitted{id}` (R3, R8). `recordFoster` is **not** one of
the two verbs that return an id and throw: `beginLambing` and `addLamb` are the only two (R32).

### 5.3 The details that are easy to get wrong

1. **The season is the lamb's, never `app_settings.current_season`.** Read it inside the transaction:
   `SELECT lambings.season FROM lambs JOIN lambings ON lambings.id = lambs.lambing WHERE lambs.id = ?`.
   The argument is not tidiness — `foster_events.season` is `ON DELETE CASCADE`, so an event filed
   under the wrong season is **deleted with that season**, and `lamb_rearing` then silently reverts
   the rearing dam with no row left to explain it. 03 §5.1: *"Season scopes the events."*
2. **`SettingsRepository` owns `app_settings`, `FlockRepository` owns `ewe_touches`, and
   `LambingRepository` owns `ewe_summaries`** (03 §5.14). This file writes `foster_events` and nothing
   else. In particular, **the receiving ewe does not appear in the recents strip because of a foster**
   — if that is wanted it is a `FlockRepository` verb called by the write controller, and it is not in
   this epic's scope.
3. **Never `UPDATE lambs` from here, for any reason.** The trigger aborts with
   `birth_dam is immutable; record a foster instead`, and the mapped failure is a message a shepherd
   cannot act on. The correct design is that the repository has no reason to touch `lambs` at all:
   `recordFoster` takes a `LambId` and reads it.
4. **`time_source` is `'auto'` and `original_effective` stays NULL.** The paired
   `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))` makes any other combination
   unstorable. And note the corollary in `05` §4.2: **a table without the quad has no edit verb** —
   `FosterEvents` has the quad, but 07 §15.1 gives fostering **no** `correctOccurredAt`. Do not add
   one here because the columns would allow it.
5. **`effective_at`, not `occurred_at`.** It is one of exactly three documented exceptions to the
   event-time column name (R37), because *a graft is dated by when it took effect*. Grep for
   `occurredAt` in this file before committing; drift will happily let you name a local variable that
   way and the next reader will look for a column that does not exist.
6. **Pass `time_source` explicitly even though the column has `withDefault(const Constant('auto'))`.**
   A write whose provenance depends on a schema default is a write whose provenance changes when the
   schema does — and provenance is a §12.5 mechanism, not a convenience.
7. **The outcome key comes off the sealed type** (`outcome.key`), never from a local `switch` that
   re-types the three strings. `FosterOutcome` carries them precisely so a fourth call site cannot
   spell `'toEwe'` and pass the CHECK by accident — it would not.
8. **`method` is not written in v1 and the column is not removed.** `foster_events.method` is a
   nullable `RESTRICT` foreign key onto the five `fm_*` `vocab_terms` keys. There is no method chooser
   on the screen (07 §8 offers none) because it costs a tap on the one flow spec §7.3 says dies at
   five. When it is ever written, it must be a `foster_method` key —
   `test/data/vocab_list_scope_test.dart` asserts that per column.
9. **`rearing_dam` is `ON DELETE RESTRICT`.** A ewe who has ever reared a fostered lamb is referenced
   by a record someone may show a vet, so she cannot be deleted out from under it. Nothing in this
   task deletes a ewe; the point is not to "fix" the restrict later by relaxing it.
10. **The repository may not import `lib/domain/validation/`** (R53, `layer.data`). `fosterToSelf` is
    computed by the **controller** in T04 against the freshly-watched row and passed to `confirmSaved`.
    A repository that could produce a warning could persist one, and there is no `warnings` column.
11. **One `transaction()`, and nothing side-effecting inside it** — no notification call, no file
    write, no share sheet, and no `await` that waits on a human (03 §5.14, 01 §4.3).
12. **Two identical fosters in the same millisecond are two rows, and that is fine.** The view breaks
    the tie with `ORDER BY effective_at DESC, id DESC`, so the second one wins. Do **not** add a
    uniqueness constraint, a dedupe or a `sleep` in a test to separate them: the double-tap defence is
    `WriteController.guard()` in T02, and it belongs at the controller, not in the log.
13. **`uid` is generated here and `id` never leaves the device.** `newUid()` is the one
    `package:uuid` call site (R15); the export identity is the `uid`, and
    `test/policy/export_carries_no_row_ids_test.dart` already asserts no integer id reaches a file.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/data/foster_repository_test.dart` | **anchor:** `'recordFoster leaves birth_dam unchanged and appends a FosterEvent'` · `'ToBottle stores outcome to_bottle with rearing_dam NULL'` · `'RemovedUnknown stores outcome removed_unknown with rearing_dam NULL, distinguishable from to_bottle by read-back'` · `'the event carries the provenance quad: effective_at equals captured_at, time_source is auto, original_effective is NULL'` · `'the event season is the lamb lambing season, not app_settings.current_season'` — seed a lamb in season 2025 while `current_season` is 2026 · `'a second foster appends a second row and updates neither the first row nor the lamb'` · `'lamb_rearing returns the newest rearing dam after each write'` · `'a foster onto a ewe id that does not exist returns WriteFailed and inserts nothing'` — the FK, mapped, never thrown · `'recordFoster returns WriteCommitted and never an id'` — the R32 shape, held by the compile and by the assertion · `'two fosters written in the same millisecond both persist and the later id wins in lamb_rearing'` |
| `test/data/fostering_conservation_test.dart` | **extends** N07-T04's file · `'total lambs is invariant under any sequence of fosters'` — `randomFosterSequence(seed: 42, moves: 200)` through the repository, asserting `countLambs()` and the sum of `bornCountsByDam()` both unchanged · `'reared counts exclude bottle lambs, which belong to no ewe'` · `'the birth dam cannot be updated'` — the trigger, re-asserted at this layer because this is the file a future contributor edits |
| `test/data/foster_ambiguous_hour_test.dart` `@Tags(['uk-zone'])` | `'a foster recorded AT 01:30 in the repeated hour reads back as 01:30 after a reopen'` — write through `atFixed(DateTime(2026, 10, 25, 1, 30), …)` against a real file, close, reopen with `seedOnCreate: false`, assert `effectiveAt.local.hour == 1` and `timeSource == TimeSource.autoCaptured` · `'two fosters an hour apart inside the repeated hour resolve in the order they happened'` — 01:30 BST then 01:30 GMT differ by exactly 3 600 000 ms and `lamb_rearing` returns the **second** dam; a civil-time implementation ties here and returns the first · `'a foster at 01:30 on 29 March — the hour that does not exist — stores an instant whose local rendering round-trips and raises no warning'`, because `appNow()` cannot produce a nonexistent local time and nothing was typed |

The `uk_zone`-tagged files carry the `setUpAll` offset assertion from `05` §2.9 and **fail loudly**
rather than skip when the zone is wrong. A skipped safety test is a broken safety test.

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The schema is frozen.** N07-T08 committed `drift_schema_v1.json`. This task adds no column, no index and no trigger; if it appears to need one, that is a ruling for the owner, not an edit.
- **§12.4 and §12.5** — the warning is not this layer's (R53) and the provenance quad is written on every row. Both are structural here, not documented.

## 7. Definition of Done

- [ ] `'recordFoster leaves birth_dam unchanged and appends a FosterEvent'` passes, and was seen to fail first for the stated reason
- [ ] `birth_dam` is unchanged, proved by read-back
- [ ] the event carries the provenance quad
- [ ] all three outcomes are representable
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the event's `season` is read from the lamb's lambing, proved by a lamb seeded in an earlier season
- [ ] `lib/data/foster_repository.dart` writes exactly one table, and `setRearingDam` appears nowhere

## 8. Verification

```bash
fvm flutter test test/data/foster_repository_test.dart
fvm flutter test test/data/fostering_conservation_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "domain/validation" lib/data/foster_repository.dart
grep -rn "UPDATE lambs\|setRearingDam\|current_season" lib/data/foster_repository.dart
make check
make test
```

Both greps must print nothing: the first is R53 (`lib/data/` may not import `lib/domain/validation/`),
the second is the three writes this file is forbidden to make. `make check` is what proves
`layer.data` and `layer.single_writer` still hold; `make test` runs the whole suite in randomised
order, which is what catches a repository that leaked state between tests.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): recordFoster — append-only, birth dam immutable`
