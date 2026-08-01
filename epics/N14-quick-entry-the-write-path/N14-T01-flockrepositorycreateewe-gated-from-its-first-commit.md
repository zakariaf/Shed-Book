# N14-T01 — `FlockRepository.createEwe` — gated from its first commit

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 1 of 7 |
| **Depends on** | N13-T07 · N06-T10 · N07-T03 |
| **Commit** | one commit · `feat(data): createEwe, gated by FreeTierPolicy from its first commit` |

## 1. Why this task exists

`createEwe({required String tag, required EntryContext context})` — the `EntryContext`
parameter is **structural**, not a later addition: decision #91 makes `EntryContext.liveEntry`
incapable of returning `BlockedByCap`, so create-on-the-fly can never block an entry at 3am. The policy
it consults already exists (N06-T10). Plus the `ewe_touches` write that feeds the recents strip.
Critique defect S5.

A parameter that changes a function's *reachable return set* cannot be retrofitted. The old plan added
it in E27, sixteen epics later, which would have re-opened the product's most-reviewed repository to
change the shape of its most-used verb.

This is also the first repository in the project. Everything it does — the transaction boundary, the
single `appNow()`, the `newUid()`, the `WriteOutcome` return — is the template the other eleven copy.
Get the shape right here and the rest is transcription.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/11-monetization-and-store.md` | §7.1, §7.2, §7.3, §7.4, §8.1 | what is capped and what never is; `FreeTierPolicy.decide`'s complete body; **the post-write count contract**; the two consequences stated rather than discovered; `over_free_cap` is bookkeeping and never a warning |
| `docs/engineering/01-architecture.md` | §4.1, §4.2, §4.3, §4.4 | repositories are concrete `final class`es taking `AppDatabase`, never a `Clock`; event verbs; one `appNow()` and one `db.transaction` per mutation; `.distinct()` in the repository, never in the widget |
| `docs/engineering/CONVENTIONS.md` | §2.13 (the signature) · §2.4 (`WriteOutcome`) · §2.10 (`CapDecision`) · §1.1 layer rules 3, 4, 8 · §4.6 · §5.1–§5.3 · R18, R19, R33, R53, R69 | **BINDING**: the exact signature, the flat `lib/data/`, ids across boundaries, and the validation ban |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes` and the active-only partial unique index) · §5.13 (`Entitlements`) · §5.14 (`FlockRepository` owns `ewes` and `ewe_touches`) · §9.2 (the `ewes` FTS5 source trigger and the `COALESCE` rule) | every column and every trigger this verb fires |
| `docs/engineering/12-testing.md` | §3.1, §3.3, §3.6 | `NativeDatabase.memory()`, never a mock; what a repository test asserts |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | event verbs, `appNow()` once per mutation, the provenance quad, one transaction |
| `shed-monetization` | the cap's only two gated verbs and why this one cannot refuse on the live path |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/flock_repository_test.dart`
- **Test** — `'createEwe with EntryContext.liveEntry never returns BlockedByCap and marks the row over_free_cap'`
- **Why it is red today** — nothing creates a ewe, and the old plan added the cap parameter sixteen epics later, which would have re-opened the product's most-reviewed repository.

```bash
fvm flutter test test/data/flock_repository_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion with the values, not the shape. Seed 15 active ewes into the current season and
leave `entitlements.unlocked = 0`; call `createEwe(tag: '412', context: EntryContext.liveEntry)`;
assert the outcome `isA<WriteCommitted>()` with a non-null `insertedId`, assert
`(await db.select(db.ewes).getSingle()).overFreeCap` is `true`, and assert the same holds at 0, 15, 16
and 400 ewes and at 1, 2 and 5 seasons. A test that only asserts "did not throw" passes against a verb
that silently swallowed the decision.

**Green.** The minimum code that passes, and nothing beyond it — the verb, the policy call, the `ewe_touches` write, all in one transaction.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** Every column this verb writes was frozen at
N07-T08: `ewes.tag`, `ewes.tag_digits`, `ewes.status`, `ewes.over_free_cap`, the `Identified` mixin's
four, and `ewe_touches.ewe` / `.touched_at`. **No domain step either** — `EntryContext`, `CapDecision`,
`RefusalReason` and `FreeTierPolicy` are N06-T10's and are complete.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **New.** `final class FlockRepository`, taking `AppDatabase` and `FreeTierPolicy`. Holds `createEwe` and nothing else this epic needs — `setStatus` is N26's and the flock read queries are N26-T01's |
| 2 | `lib/data/providers.dart` | **Edit.** Add `flockRepositoryProvider` (`FutureProvider<FlockRepository>`, keepAlive), derived from `databaseProvider` and `freeTierPolicyProvider`. `CONVENTIONS §3.1` already names both |
| 3 | `test/data/flock_repository_test.dart` | **New.** The anchor, the boundary cases, the trigger case and the DST group |

`lib/data/models.dart` is **not** touched: it already re-exports all 23 row classes (R20), `Ewe` and
`EweTouch` among them, and `@DataClassName('EweTouch')` was declared at the table (R7).
`test/support/seeds.dart` is **not** touched either: `seedEwe(db, tag: '412')` exists from N12-T05, and
`setEntitlement` / `setEwesInCurrentSeason` are T07's, per `12 §5.3`'s closed list.

### 5.2 The signature

`CONVENTIONS §2.13` fixes this line. Type it exactly — a named `tag`, a named required `context`, and
a `Future<WriteOutcome>`:

```dart
// lib/data/flock_repository.dart
final class FlockRepository {
  FlockRepository({required AppDatabase db, required FreeTierPolicy policy})
      : _db = db,
        _policy = policy;

  final AppDatabase _db;
  final FreeTierPolicy _policy;

  /// The one create verb the cap can refuse (11 §7.3). On the live-entry path
  /// it is structurally incapable of refusing: FreeTierPolicy.decide cannot
  /// reach a BlockedByCap on that arm (decision #91).
  Future<WriteOutcome> createEwe({
    required String tag,
    required EntryContext context,
  }) =>
      _db.transaction(() async {
        final now = appNow();                              // ONE instant per mutation
        final decision = _policy.decide(
          context: context,
          now: now,
          unlocked: await _readUnlocked(),
          ewesInCurrentSeason: await _countEwesInCurrentSeason() + 1,  // post-write
          seasonCount: await _countSeasons(),                          // unchanged
        );
        return switch (decision) {
          BlockedByCap(:final reason) => WriteRefused(reason),
          Allow(:final overFreeCap) => WriteCommitted(
              insertedId: await _insertEwe(tag: tag, now: now, overFreeCap: overFreeCap),
            ),
        };
      });
}
```

Four things in that body are fixed elsewhere and are not local choices:

- **`WriteCommitted` is non-generic and its id field is `insertedId`** (R3). There is no
  `WriteOutcome<EweId>` and no `WriteCommitted{id}`.
- **`warnings` is left at its default empty list** (R53). `lib/data/` may not import
  `lib/domain/validation/`, so this class is *structurally incapable* of producing a `Warning`. The
  controller populates the list.
- **The switch has no `default:`** — `CapDecision` is sealed with two variants, and the day a third
  appears every switch must fail to compile rather than swallow it.
- **`_insertEwe` returns a raw `int`**, which is one of only two places R33 permits one, because
  `WriteCommitted.insertedId` is an `int?` and the single reading call site wraps it in `EweId`.

The private helpers, so nothing is left to invent:

```dart
Future<bool> _readUnlocked() async =>
    (await _db.select(_db.entitlements).getSingle()).unlocked;

Future<int> _countEwesInCurrentSeason();   // ewe_seasons joined to app_settings.current_season
Future<int> _countSeasons();               // SELECT COUNT(*) FROM seasons

Future<int> _insertEwe({
  required String tag,
  required Instant now,
  required bool overFreeCap,
}) async {
  final id = await _db.into(_db.ewes).insert(
        EwesCompanion.insert(
          uid: newUid(),                                   // R15 — core/db/uid.dart
          createdAt: now,
          updatedAt: now,
          tag: tag,                                        // EXACTLY as typed
          tagDigits: tag.replaceAll(RegExp(r'\D'), ''),    // projection, same statement
          overFreeCap: Value(overFreeCap),
        ),
      );
  // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
  await _db.into(_db.eweTouches).insertOnConflictUpdate(
        EweTouchesCompanion.insert(ewe: id, touchedAt: now),
      );
  return id;
}
```

### 5.3 The details that are easy to get wrong

- **The counts are post-write, and getting that wrong is an off-by-one that ships.** `11 §7.2`'s doc
  comment is explicit: *"`ewesInCurrentSeason` and `seasonCount` are the counts **as they would be
  after the write**"*. So `_countEwesInCurrentSeason() + 1`, and `_countSeasons()` unchanged because
  this verb creates no season. Backwards, you either refuse ewe #15 or let #16 through — and the free
  tier's boundary is the one number a paying user notices.
- **`unlocked` is read *inside* the transaction, and so are both counts.** `11 §7.3`: *"the decision
  and the insert are in one transaction, so the count cannot move between them."* Reading a count
  outside and inserting inside is a race with the restore path and with a second create.
- **Reading `entitlements` here does not violate "nothing on the 3am path reads it."** `11 §4.4` bans
  a **screen** from watching `entitlementProvider`; the failure mode it prevents is a paywall flash at
  3am. A repository reading one row inside its own transaction is exactly what `11 §7.3` prints. Quick
  Entry watches nothing; it calls a verb that decides.
- **`EntitlementRepository` does not exist yet, and you must not create it.** It is N30-T02, together
  with `entitlementRepositoryProvider` and `entitlementProvider`. The `entitlements` row exists from
  the first millisecond because `seedFirstRun` seeds it in `onCreate` as `const EntitlementsCompanion()`
  (N07-T07, `11 §4.1`), so `_readUnlocked()` is a one-row select that can never find nothing. N30-T04
  replaces that private read with the repository collaborator and **changes no signature** — that is
  what critique defect S5 means by *"E27 then only supplies the entitlement source."*
- **`getSingle()` on `entitlements` is the right spelling**, because the table has `CHECK (id = 1)` and
  a seeded row. `getSingleOrNull()` would invite a null branch for a state that cannot exist, and that
  branch would have to guess an entitlement.
- **The tag is stored exactly as typed and is never normalised** (spec §12.4, decision #55).
  `tag_digits` is a *projection* written in the same statement, not a correction: `'0412'` stores
  `tag = '0412'` and `tag_digits = '0412'`, with the typed value preserved verbatim beside it.
  Uniqueness is on `tag`, never on `tag_digits` (`03 §6`) — making the projection unique would refuse
  `0412` because `412` exists, which is the app deciding two tags are the same animal.
- **The `ewes` FTS5 source trigger fires on this insert.** `search_docs.title` and `body` are
  `NOT NULL` while `ewes.notes` is nullable, so the trigger's `COALESCE(new.notes, '')` is
  load-bearing: miss it and *"creating a ewe with no notes aborts the insert with a `NOT NULL` failure
  — at 03:20, on the create-on-the-fly path, from a trigger nobody was looking at"* (`03 §9.2`). This
  task is the first code in the project that fires it. Assert it rather than discover it.
- **`ewe_touches` is an upsert, not an insert.** Its primary key is `ewe`, one row per animal
  (decision #68), which is what makes `ORDER BY touched_at DESC LIMIT 6` in `quickEntryDeckQuery`
  really return the last six *distinct* animals with no `GROUP BY` and no `DISTINCT`. A plain
  `insert()` on a second touch throws a `UNIQUE` failure; `insertOnConflictUpdate` is the spelling.
- **A created ewe must appear at the head of the recents strip in the same frame.** That is the third
  confirmation channel (`07 §5.5`) and the only one still true five seconds later. It works because
  `quickEntryDeckProvider` (N13-T03) declares `readsFrom: {penOccupancies, eweTouches, ewes, pens}` —
  drop the `ewe_touches` upsert and the ewe is created, nothing visibly happens, and the shepherd taps
  again.
- **`ewes` carries no provenance quad, and that is correct.** R37 adds the quad to `PenOccupancies`,
  `FosterEvents`, `Notes` and `EweObservations`; `Ewes` is not on the list. So `createEwe` writes
  `created_at` and `updated_at` from the mixin and **no** `captured_at` / `original_effective` /
  `time_source`, and the standing rule holds unchanged: *a table without the quad has no edit verb*.
  Do not add one, and do not call `RecordedTime.capture` here — there is no column to put it in.
  `RecordedTime` lands in T02, on `lambings`, which does carry the quad.
- **`overFreeCap` uses `Value(overFreeCap)`, never `const Value.absent()`.** The column has
  `withDefault(const Constant(false))`, so omitting it is legal Dart and wrong behaviour: an over-cap
  row would be indistinguishable from a normal one, and `11 §8.1`'s unlock transaction would have
  nothing to clear.
- **`over_free_cap` is not a warning.** No `WarningCode`, no badge, no colour, never in the receipt
  (`11 §8.1`). If it renders anywhere on this branch, T07 should fail — and if T07 passes anyway, T07
  is wrong.
- **A calm refusal at 22:30 is `Allow`, permanently, and is not a bug.** `isQuietHours` returns
  `Allow(overFreeCap: over)` and rule 1 means the app never revokes, so a user who creates ewe #16 from
  the Flock screen at 22:30 keeps it for nothing. `11 §7.4` says out loud: *"do not 'fix' it"* by
  deferring the refusal to the morning. Pin the behaviour with a test so nobody tries.
- **A second *active* 412 is unstorable, and this task does not rule on that.** `03 §6`'s partial
  unique index is `ON ewes (tag) WHERE status = 'active'`, while `07 §3.3` says the
  `duplicateActiveTag` warning *"never blocks the create"*. `00-README` §10 lists this as a known open
  contradiction and calls it a domain question, not a naming one. On the live path it is unreachable —
  `tagIndexProvider` reads active animals only, so the confirm key offers "Create 412" only when no
  active 412 exists — but the repository must still map the constraint failure through
  `shedFailureFrom` (N11-T02) into `WriteFailed` rather than let a `SqliteException` escape. The ruling
  belongs to N26-T04's calm path.
- **No `Clock`, ever.** `FlockRepository` takes `AppDatabase` and `FreeTierPolicy` and nothing else
  (`01 §4.1`). Tests install time with `withClock`; two clock seams are worse than none, because a test
  that fakes one does not fake the other.

### 5.4 The full test set

`test/data/flock_repository_test.dart`, against `NativeDatabase.memory()` through `testDatabase()`
(`12 §3.1`). Never a mock — a mock cannot express a `CHECK`, a trigger or a partial index, and this
task's three sharpest failures are each one of those.

| Case | What it asserts |
|---|---|
| `'createEwe with EntryContext.liveEntry never returns BlockedByCap and marks the row over_free_cap'` | **The anchor.** Locked, 15 ewes already in the season: `WriteCommitted`, non-null `insertedId`, `over_free_cap = 1` — and the same at 0, 15, 16 and 400 ewes and at 1, 2 and 5 seasons |
| `'createEwe on the calm path returns WriteRefused(eweCap) past the cap in daylight'` | The other arm. `EntryContext.calm`, `withClock` at 11:00, 16 ewes → `WriteRefused(RefusalReason.eweCap)` and **no row inserted** |
| `'season-primary: over both limits, the reason is secondSeason'` | `11 §7.2`'s ordering. Two seasons and 16 ewes on the calm path → `secondSeason`, never `eweCap` |
| `'a calm refusal inside the quiet window commits instead, and is never revoked'` | `withClock` at 22:30 and at 05:59: `WriteCommitted` with `over_free_cap = 1`, and re-reading the row later never flips it back |
| `'unlocked never marks a row over the free cap'` | `entitlements.unlocked = 1` at 400 ewes → `Allow(overFreeCap: false)` and `over_free_cap = 0` |
| `'the counts are post-write'` | With exactly `kFreeEweCap` ewes in the season, the **next** create is the one that is over. Pins the `+ 1` |
| `'the tag is stored exactly as typed and tag_digits is a projection'` | `'0412'` → `tag = '0412'`, `tag_digits = '0412'`; `'412A'` → `tag_digits = '412'`. Nothing is normalised |
| `'creating a ewe with every optional column null does not abort'` | The `COALESCE` in the `ewes` FTS5 source trigger: `notes`, `eid`, `breed`, `date_of_birth` and `source` all null, the insert returns, and `search_docs` has one row |
| `'the created ewe is the head of ewe_touches'` | One `ewe_touches` row whose `touched_at` **equals** the `created_at` written on the same call — one `appNow()` per mutation, proved by equality rather than by reading the code |
| `'a second createEwe for the same ewe upserts ewe_touches rather than failing'` | The primary key is `ewe`. Two touches, one row, the later `touched_at` |
| `'a second ACTIVE ewe on the same tag returns WriteFailed, not an exception'` | The partial unique index, mapped by `shedFailureFrom`; nothing escapes the verb |
| `'a culled 412 releases the tag'` | §7.0 ruling 7. Set the first to `status = 'culled'` and create again: `WriteCommitted`, two rows, two uids, two histories |
| `'the uid is a v7 UUID and is unique across two creates'` | `newUid()` is the export identity (decision #32); a duplicated uid breaks N22's backup round trip |
| `'no row is written when the decision refuses'` | The transaction rolls back whole — a refusal leaves no partial `ewe_touches` row either |
| `'createEwe returns WriteCommitted with warnings empty'` | R53. A repository cannot produce a `Warning`; the field is the default `const []` |

**The `uk-zone` group.** `createEwe` is time-shaped through one parameter — the `now` it hands the
policy — and `isQuietHours` reads `now.local.hour`. Put this in a `group('DST', …, tags: 'uk-zone')`
that asserts the ambient zone **first and loudly**, so it can never pass under the runner's own zone.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: a calm create at 01:30 on the clocks-back night is allowed under both readings of the hour'` | The ambiguous 01:00–01:59 hour sits inside 22:00–06:00 under **both** readings (`11 §7.2`), so the one hour where a local time is genuinely ambiguous is an hour where the ambiguity cannot change the answer. Both instants → `Allow` |
| `'DST: a live-entry create at 01:30 is allowed for the structural reason, not the quiet-hours reason'` | Same instant, `EntryContext.liveEntry`, `unlocked: true` so the quiet-hours arm is unreachable — still `Allow`. Proves the two arms are independent |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Safety rule §12.4 — never silently correct.** The tag is stored as typed and `tag_digits` sits
  beside it. `lib/data/` may not import `lib/domain/validation/` (R53, `layer.data_no_validation`),
  which is what makes a repository structurally incapable of producing or persisting a warning.
- **The free tier never gates safety.** `11 §7.1`: withdrawal periods, clear dates, the medicine book
  and export are never capped in any state. Nothing in this file may become a precedent for that.

## 7. Definition of Done

- [ ] `'createEwe with EntryContext.liveEntry never returns BlockedByCap and marks the row over_free_cap'` passes, and was seen to fail first for the stated reason
- [ ] the signature matches `CONVENTIONS §2.13` exactly
- [ ] `liveEntry` never returns `BlockedByCap`
- [ ] a row created over the cap is marked, not refused
- [ ] `appNow()` is called once per mutation and `RecordedTime.capture` carries the provenance
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the decision and the insert are in **one** `_db.transaction`, and both counts are read inside it
- [ ] the counts passed to `decide` are post-write — `+ 1` on the ewes, unchanged on the seasons
- [ ] **`ewes` gains no provenance quad and this verb writes no `captured_at`.** R37's standing rule holds — *a table without the quad has no edit verb* — so `RecordedTime.capture` lands in T02, on `lambings`, where there is a column for it. The provenance line above is satisfied by the single `appNow()`, whose instant is written to `created_at`, `updated_at` and `touched_at` alike
- [ ] `EntitlementRepository` is **not** created here; `_readUnlocked()` is a private select that N30-T04 replaces without changing a signature
- [ ] `ewe_touches` is written with `insertOnConflictUpdate`, and a create reaches the head of the recents strip in the same frame
- [ ] a create with every optional column null does not abort — the `ewes` FTS5 source trigger's `COALESCE` is exercised by a test
- [ ] a `SqliteException` never escapes the verb; the partial unique index surfaces as `WriteFailed`
- [ ] the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers 01:00–01:59
- [ ] `drift_schemas/` and `lib/core/db/tables/` are untouched by this diff

## 8. Verification

```bash
fvm flutter test test/data/flock_repository_test.dart
TZ=Europe/London fvm flutter test test/data/flock_repository_test.dart --tags uk-zone
make check
make test
```

```bash
# the layer rules this file is the first to exercise
grep -rn "package:drift" lib/features/ --include='*.dart'          # expect zero
grep -rn "domain/validation" lib/data/ --include='*.dart'          # expect zero
grep -rn "clock.now(\|DateTime.now(" lib/data/ --include='*.dart'  # expect zero — appNow() only
grep -rn "save\|commit(\|submit(\|isDirty" lib/data/ --include='*.dart'   # expect zero
git diff --stat -- drift_schemas/ lib/core/db/tables/              # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): createEwe, gated by FreeTierPolicy from its first commit`
