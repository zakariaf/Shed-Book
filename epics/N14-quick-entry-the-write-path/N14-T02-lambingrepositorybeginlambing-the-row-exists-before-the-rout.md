# N14-T02 — `LambingRepository.beginLambing` — the row exists before the route is pushed

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 2 of 7 |
| **Depends on** | N14-T01 · N07-T04 |
| **Commit** | one commit · `feat(data): beginLambing — the row exists before the route is pushed` |

## 1. Why this task exists

One of only **two** verbs in the app that return an id and throw. The row is committed
**before** Lambing Entry is pushed, per `00-README` §2.4 — which is what makes *every write commits
immediately* structurally true rather than aspirational, and what makes the five-tap budget honest.

It is also the write that carries the §12.5 provenance quad for the first time. Every later
timestamp in the product — the pen tile, the medicine book, the ewe card timeline, the CSV — is a
variation on the four columns this verb writes in one statement.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/01-architecture.md` | §4.2 (**the `beginLambing` body, printed in full**) · §4.3 (one `appNow()`, media before the transaction, gateways after it) · §4.5 (there is no Save button; the abandoned entry is a true statement) · §5.4, §5.5 (what throws, and the global net that catches it) | this verb's body, line for line |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`Lambings`: the quad, `local_date`, nullable `declared_birth_type`, every CHECK) · §5.14 (`LambingRepository` owns `lambings`, `lambs`, `care_events`, `ewe_observations`, `ewe_summaries`) · §9.2 (the `lambings` FTS5 source trigger and its three-column `COALESCE`) | every column and constraint the insert must satisfy |
| `docs/engineering/05-domain-correctness.md` | §2 (instants are `INTEGER` UTC millis, civil dates are `TEXT`) · §4 (`RecordedTime`, `TimeSource`, `provenanceLabel`) | why `occurred_at`, `captured_at` and `local_date` are three different things |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`Future<LambingId> beginLambing(EweId ewe)`) · §2.1 (ids) · §2.2 (`RecordedTime`, `appNow`) · §4.6 (column naming, the three `occurred_at` exceptions) · R6, R15, R23, R32, R33, R37 | **BINDING**: the signature, the id types, the column spellings |
| `docs/engineering/12-testing.md` | §3.3 (repository tests) · **§3.5 (the durability test, printed)** · §2.3 (the ambiguous hour) | the test set, including the one that reopens the file |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the verb, the transaction, and the row-before-the-route rule |
| `shed-drift-schema` | the lambing cluster's constraints are what this write must satisfy |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/lambing_repository_test.dart`
- **Test** — `'beginLambing commits a row and throws on failure, returning a LambingId'`
- **Why it is red today** — nothing writes a lambing; the screen would otherwise collect fields and save on exit — the draft state the product forbids.

```bash
fvm flutter test test/data/lambing_repository_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it pins both halves of the contract. On success: the return type is
`LambingId` (not `WriteOutcome`), exactly one `lambings` row exists, its `declared_birth_type` is
`null`, its `ease` is `null`, `time_source == 'auto'`, `original_effective == null`, and
`occurred_at == captured_at`. On failure: `expect(() => repo.beginLambing(const EweId(999999)),
throwsA(isA<SqliteException>()))` with `foreign_keys = ON` — the verb throws rather than returning a
`WriteFailed`, and **no** `lambings` row and **no** `ewe_touches` row survive the rollback.

**Green.** The minimum code that passes, and nothing beyond it — the verb, one transaction, one `appNow()`, `newUid()`, and the reminder rows that N24
will add **inside** this same transaction.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `Lambings` was frozen at N07-T08 with the quad,
the nullable `declared_birth_type` (R6) and every CHECK. **No domain step** — `Instant`, `LocalDate`,
`RecordedTime`, `TimeSource` and `LambingId` are N04's and N06-T01's.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **New.** `final class LambingRepository` with `beginLambing` and nothing else. `addLamb`, `setEase`, `addCare`, `removeCare` and `correctOccurredAt` are N16's and N17's; `setBirthType` is P8's casualty and is discussed below |
| 2 | `lib/data/providers.dart` | **Edit.** Add `lambingRepositoryProvider` (`FutureProvider<LambingRepository>`, keepAlive) |
| 3 | `test/support/seeds.dart` | **Edit.** Add `seedSeason(db)` if `seedFirstRun` is not already giving the in-memory harness a current season — see the gotcha below. Nothing else |
| 4 | `test/support/reads.dart` | **Edit.** `readLambing`, `readLambingByUid` and `countLambings` are `12 §5.3`'s and land here, because this is the first test that needs a read helper rather than an inline `select` |
| 5 | `test/data/lambing_repository_test.dart` | **New.** The anchor, the provenance cases, the trigger case and the DST group |
| 6 | `test/data/durability_test.dart` | **New.** `12 §3.5`'s reopen-the-file test, which is the closest the suite gets to *assume the phone dies* |

### 5.2 The signature

`CONVENTIONS §2.13`, R32: `beginLambing` and `addLamb` are the **only** two verbs in the app that
return an id and throw. Everything else returns `WriteOutcome`.

```dart
// lib/data/lambing_repository.dart
final class LambingRepository {
  LambingRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Called by the Quick Entry "Lambing" tap, BEFORE Lambing Entry is pushed.
  /// The row exists from this moment; there is no draft and nothing to lose if
  /// the phone dies. Returns the id and THROWS: there is no id to hand back on
  /// failure and the screen cannot open, so the global error net (01 §5.5) is
  /// the right handler. Never gated by the free tier, at any entitlement state.
  Future<LambingId> beginLambing(EweId ewe) {
    final now = appNow();                          // ONE instant per mutation
    final when = RecordedTime.capture(now);        // spec §12.5 provenance
    return _db.transaction(() async {
      final season = await _currentSeason();       // app_settings — decision #42
      final id = await _db.into(_db.lambings).insert(
            LambingsCompanion.insert(
              uid: newUid(),                           // export identity — #32, R15
              createdAt: now,
              updatedAt: now,
              ewe: ewe.value,
              season: season.value,
              occurredAt: when.effective,
              capturedAt: when.capturedAt,
              timeSource: Value(when.source.key),      // frozen wire key, never localised
              localDate: LocalDate.of(when.effective), // same statement — 05 §5
              declaredBirthType: const Value.absent(), // absent != Value(null)
            ),
          );
      // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
      await _db.into(_db.eweTouches).insertOnConflictUpdate(
            EweTouchesCompanion.insert(ewe: ewe.value, touchedAt: now),
          );
      // N24-T04 writes the colostrum and navel reminder ROWS here, inside this
      // same transaction (decision #63). The OS projection is reconciled AFTER
      // the transaction returns, never inside it — a platform channel round
      // trips through another isolate while holding the write lock.
      return LambingId(id);
    });
  }
}
```

`_currentSeason()` reads `app_settings.current_season` and returns a `SeasonId`:

```dart
Future<SeasonId> _currentSeason();   // never creates one — see §5.3
```

### 5.3 The details that are easy to get wrong

- **`const Value.absent()` is not `Value(null)`, and the difference is the whole reason R6 exists.**
  `absent` omits the column from the `INSERT` so SQLite applies its own rules; `Value(null)` writes an
  explicit `NULL`. Both land on `NULL` here because `declared_birth_type` is nullable — but write
  `Value(null)` and the next reviewer cannot tell whether the column is nullable by design or by
  accident. `01 §4.2`'s printed body writes `absent`; match it.
- **`declaredBirthType` must be nullable in the shipped schema, and it is (R6).** If it is not, this
  verb throws `SQLITE_CONSTRAINT_NOTNULL` on its first call, on a fresh install, on the 3am path. If
  you find it non-nullable, **stop** — that is a migration after the freeze, not an edit, and it is an
  owner conversation.
- **`setBirthType` exists in `CONVENTIONS §2.13` and this task does not build it.** P8 abolished the
  birth-type chooser: birth type is derived from the tally strokes and labelled `(COUNTED)`. The
  column still has a writer — the deferred `CHANGE TYPE` path in N16 — but nothing on the five-tap
  path ever declares one, and no key named `birth_type` may appear anywhere in the tree (N16-T02's
  canary).
- **Three time columns, three different meanings.** `occurred_at` is when the thing happened,
  `captured_at` is when we wrote it down, and `local_date` is the shepherd's civil day derived in
  **Dart** from `occurred_at`, because SQLite cannot bucket by a local civil day without a tz
  database. All three come from the same `now`, in the same statement. Writing `local_date` from a
  second clock read is how the lambing-spread histogram acquires a one-row-off bug that nobody sees
  until the season summary.
- **`time_source` takes `when.source.key`, the frozen wire key, never the enum's `name`.**
  `TimeSource.autoCaptured` has key `'auto'`; the CHECK is `time_source IN ('auto','entered','edited')`
  and the paired CHECK is `(time_source = 'edited') = (original_effective IS NOT NULL)`. Both hold this
  insert honest for free — but only if the key is what is written.
- **`LambingRepository` takes `db` and nothing else *today*.** `01 §4.1` prints the finished
  constructor as `LambingRepository({required AppDatabase db, required NotificationScheduler reminders,
  required MediaStore media})`. Neither collaborator exists yet: `MediaStore` is N15-T01 and
  `NotificationScheduler` is N24-T02. Declaring a parameter for a class that does not exist does not
  compile, and stubbing one is worse. The constructor grows in N15 and again in N24, in the epic that
  introduces each gateway — which is the same rule critique defect S1 applies to the seven test fakes.
- **The `lambings` FTS5 source trigger fires on this insert, and its body is three nullable columns.**
  `search_docs.body` for a lambing is `COALESCE(note,'') || ' ' || COALESCE(presentation_note,'') || ' '
  || COALESCE(assisted_by,'')` — every one of which is null at `beginLambing`. `search_docs.title` and
  `body` are `NOT NULL` (`03 §9.2`). Miss a `COALESCE` and the very first lambing of the season aborts.
- **Never call a gateway inside the transaction** (`01 §4.3` rule 4). N24's `reconcile()` runs *after*
  the transaction returns, debounced 500 ms, off the paint frame. The reminder **rows** go inside; the
  OS projection does not. Put the comment in now, where N24 will read it.
- **Every statement inside `_db.transaction` is `await`ed.** drift's own documentation is explicit, and
  un-awaited work escapes the transaction and can silently lose data. Treat any drift runtime warning
  about this as a P0.
- **`_currentSeason()` never creates a season.** `seedFirstRun` seeds one in `onCreate` (decision #42,
  N07-T07), so a current season exists from the first millisecond of a real install. A verb that
  quietly created one would make `_countSeasons()` in T01 disagree with itself and would hand the free
  tier a second season nobody asked for. **In tests this is the trap:** `testDatabase()` must build
  `AppDatabase` with `seedOnCreate` left at its default `true` (R14), or `_currentSeason()` finds
  nothing on an in-memory database and the anchor fails for a reason that has nothing to do with the
  verb.
- **`foreign_keys = ON` means a bare `EweId(1)` is an FK violation, not a durability test.** `12 §3.5`
  says so directly. Seed a real ewe with `seedEwe(db, tag: '412')` first — and note that `lambings.ewe`
  references `Ewes` with `onDelete: restrict`, so a ewe with a lambing cannot be deleted out from under
  it.
- **This verb is never gated by the free tier, at any entitlement state.** `11 §7.3`: *"`beginLambing`
  and `addLamb` throw and return ids; they are never gated."* That is what makes the throwing shape
  safe — there is no refusal to represent.
- **An abandoned lambing is a true statement, not garbage.** *"A lambing began for 412 at 03:24 and
  nothing else was recorded."* `01 §4.5`: never garbage-collect it — silent deletion is a §12.4
  violation in the other direction. It is removed by the strike affordance (T05) or explicitly from the
  ewe card, and never by a background sweep.
- **`ewe_touches` again.** The lambing tap must move the ewe to the head of the recents strip, for the
  same reason as T01: it is the confirmation channel that is still true five seconds later.

### 5.4 The full test set

`test/data/lambing_repository_test.dart` against `NativeDatabase.memory()`, plus one file that uses a
real file on disk.

| Case | What it asserts |
|---|---|
| `'beginLambing commits a row and throws on failure, returning a LambingId'` | **The anchor.** Return type, one row, and the throw on a non-existent ewe with nothing left behind |
| `'the returned id is a LambingId and never a bare int'` | R33, at the type level: the test would not compile against an `int` |
| `'occurred_at equals captured_at, time_source is auto and original_effective is null'` | The §12.5 quad at capture time, and the paired CHECK that keeps it honest |
| `'local_date is the civil day of occurred_at, written in the same statement'` | The denormalised grouping key. Compare against `LocalDate.of(instant)`, never against a re-read clock |
| `'declared_birth_type is null and is never defaulted to single'` | R6 and §12.4. `NULL` means *not yet tapped* and is a different fact from `1` |
| `'ease is null on a fresh lambing'` | Decision #59: not scored is a different fact from unassisted |
| `'the uid is a v7 UUID and two lambings never share one'` | The export identity |
| `'created_at, updated_at, occurred_at, captured_at and touched_at are all the same instant'` | One `appNow()` per mutation, proved by equality across five columns and two tables |
| `'a lambing with every optional column null does not abort'` | The three-column `COALESCE` in the `lambings` FTS5 source trigger |
| `'the ewe is at the head of ewe_touches after beginLambing'` | The recents strip moves; the third confirmation channel is real |
| `'a second beginLambing for the same ewe creates a second row'` | There is no idempotence here and there must not be: two lambings in a season is normal. Serialisation is `guard()`'s job (T03), not the repository's |
| `'beginLambing does not create a season'` | Count `seasons` before and after |
| `'beginLambing is never refused, unlocked or not, at 400 ewes'` | `11 §7.3`. The free tier has no opinion about this verb |
| `'nothing is written when the transaction throws'` | Neither `lambings` nor `ewe_touches` nor `search_docs` retains a row |

`test/data/durability_test.dart` — `12 §3.5`, verbatim in shape:

| Case | What it asserts |
|---|---|
| `'a lambing row is durable before the write returns'` | Write to a real file with `NativeDatabase(file)`, `await db.close()` with no explicit flush, reopen cold with `seedOnCreate: false`, and find the row. `synchronous = FULL`, WAL, decision #28 |

**The `uk-zone` group.** `local_date` is the one value in this verb that a time zone can make wrong,
and the clocks-back night is the only place it can happen. Put it in a
`group('DST', …, tags: 'uk-zone')` that asserts the ambient zone **first and loudly**.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: two lambings one hour apart inside the ambiguous 01:00–01:59 hour store two distinct occurred_at values and one local_date'` | The repeated hour. Two different instants, one civil day — which is exactly why the record keeps the absolute instant and derives the date, and never the other way round |
| `'DST: local_date satisfies the GLOB CHECK on the clocks-back night'` | `local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'`. A formatter that emitted an offset suffix would fail the constraint, not the eye |
| `'DST: a lambing on the clocks-forward night writes the civil date of the instant that exists'` | The spring-forward gap: 01:30 does not exist locally, and this verb never invents one because it derives from a real captured instant |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Safety rule §12.5 — timestamps carry provenance.** The quad is written in one statement, from one
  `appNow()`, and `time_source` is a frozen wire key. Nothing displays a time from this row without
  `RecordedTime.provenanceLabel`.
- **Safety rule §12.4 — never silently correct.** `declared_birth_type` stays `NULL` until a human acts,
  and the number of `lambs` rows is never forced to agree with it.
- **P8** — no birth-type chooser. This verb writes no birth type and no widget key on this branch
  contains `birth_type`.

## 7. Definition of Done

- [ ] `'beginLambing commits a row and throws on failure, returning a LambingId'` passes, and was seen to fail first for the stated reason
- [ ] returns a `LambingId` and throws — it does not return `WriteOutcome`
- [ ] the row is committed before any navigation
- [ ] no `save`, no `commit()`, no draft anywhere in the call path
- [ ] the transaction boundary is one and is named in a comment for N24
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `occurred_at`, `captured_at`, `time_source` and `local_date` are written in one statement from one `appNow()`, and `original_effective` is `NULL`
- [ ] `declaredBirthType` is `const Value.absent()` and the column is nullable in the shipped schema
- [ ] `LambingRepository`'s constructor takes `db` only; `MediaStore` is added in N15 and `NotificationScheduler` in N24
- [ ] `_currentSeason()` creates nothing, and the in-memory harness seeds one through `seedOnCreate`
- [ ] `test/data/durability_test.dart` reopens a real file cold and finds the row
- [ ] the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers 01:00–01:59 in both directions
- [ ] `drift_schemas/` and `lib/core/db/tables/` are untouched by this diff

## 8. Verification

```bash
fvm flutter test test/data/lambing_repository_test.dart
fvm flutter test test/data/durability_test.dart
TZ=Europe/London fvm flutter test test/data/lambing_repository_test.dart --tags uk-zone
make check
make test
```

```bash
grep -rn "Value(null)" lib/data/ --include='*.dart'                # expect zero on this branch
grep -rn "birth_type" lib/ test/ --include='*.dart'                # expect zero — P8
grep -rn "reconcile(\|schedule(" lib/data/lambing_repository.dart  # expect zero inside the transaction
git diff --stat -- drift_schemas/ lib/core/db/tables/              # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): beginLambing — the row exists before the route is pushed`
