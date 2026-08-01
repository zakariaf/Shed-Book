# N30-T02 — `EntitlementRepository` and the entitlement row

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 2 of 8 |
| **Depends on** | N30-T01 |
| **Commit** | one commit · `feat(data): EntitlementRepository and its three rules` |

## 1. Why this task exists

The entitlement as a **row**, with its three rules: it is set by a store signal only, it is
never cleared by a failure to reach the store, and it survives a restore. A shepherd who bought the app
in February and restores onto a new phone in April still owns it.

`11 §1.2` is the sentence the whole repository implements: *"the store is the source of a one-time
fact, not a runtime dependency."* The app answers *"am I unlocked?"* by reading one row of its own
SQLite file. That is the entire mechanism, and it is what makes an unlock survive a phone that never
sees a network again.

This task also carries **the one documented exception to `CONVENTIONS §2.13`'s table-ownership rule**
in the whole codebase. Read §5.3 before you write `markUnlocked`.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§4.1** (the four columns, the `onCreate` seed, and what is deliberately **not** on the row) · **§4.2** (the three rules: write-once and never revoked; excluded from the backup; never in `shared_preferences`) · **§4.3** (`EntitlementRepository`'s six members and `markUnlocked` printed in full, including the ownership-exception note and the `LocalLog` line outside the transaction) · **§4.4** (nothing on the 3am path reads it) · §4.5 (the new-device, no-signal table) · §5.1 (the 14-day drain bound) · §5.2 (why the row is written *after* the acknowledgement) · §6.3 (which two signals write and which three are ignored) · **§12.1** (`db.entitlement_revoke`) · §12.2 (what `entitlement_repository_test.dart` and `entitlement_is_never_revoked_test.dart` assert) | the repository, its rules and its gate row |
| `docs/engineering/03-data-model-and-schema.md` | **§5.13** (`Entitlements` — `id` with `CHECK (id = 1)`, `unlocked`, `unlocked_at`, `purchase_in_flight_at`, both instants through `InstantConverter`) · §5.1 / §5.2 (`Seasons.over_free_cap`, `Ewes.over_free_cap`) · §5.14 (`EntitlementRepository` owns `entitlements`) · §11 (`seedFirstRun` inserts `const EntitlementsCompanion()` in `onCreate`) | every column, and the fact that the row always exists |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/entitlement_repository.dart`) · §1.1 layer rules **3, 4, 8** (`lib/data/` is the only writer; no `material.dart`) · **§2.13** (the repository set is twelve and closed; the table-ownership rule this task breaks once, on purpose) · §3.1 (`entitlementRepositoryProvider` — `FutureProvider`, keepAlive; `entitlementProvider` — `StreamProvider<Entitlement>`, keepAlive, **nothing on a shed screen may watch it**) · §4.6 (SQL vs Dart column spellings) · §5.3 (banned words) · **R20** (`models.dart` re-exports every row class) · **R23** (`appNow()` is the only wall-clock reader) · **R37** (the provenance quad, and the standing rule that follows from its absence) · **R52** (`LocalLog.instance` is the one diagnostics sink) | the path, the provider shapes and the exception |
| `docs/engineering/04-migrations-media-backup-restore.md` | **§7.2 step 6** (*"Entitlement rows are skipped and logged"*, and staging is a **new** file) · **§7.5 item 9** (after any restore, *"an entitlement that came out of a backup file"* may not exist) · **§7.7** (*"Never unlocks. The entitlement is never imported"*) · §7.8 (the refusal fixture: a backup carrying `unlocked: 1` imports to `unlocked = 0`) · §7.4 (the eleven-to-thirteen swap steps) | the restore boundary, and the question §5.3 makes you answer |
| `docs/engineering/09-export-formats.md` | §7 (`entitlements` never exported, ignored on import) · §8 item 9 (excluded tables are excluded **symmetrically**) | the export half of rule 2 |
| `docs/engineering/01-architecture.md` | §4.1–§4.3 (repositories are concrete `final class`es taking `AppDatabase` and gateways, never a `Clock`; event verbs; one `appNow()` and one `db.transaction` per mutation; `.distinct()` in the repository, never in the widget) · §5.1 (`ShedFailure`'s six variants) · §6.3 (*"Reading the entitlement"* is a named banned line in `main()`) | the write-path template |
| `docs/engineering/12-testing.md` | §3.1, §3.3, §3.6 (`NativeDatabase.memory()`, never a mock; what a repository test asserts) · §4.2 (`FakePurchaseService` drives the scripted `updates` stream) · §5.3 (`setEntitlement` in `seeds.dart`) · §2.1 (installing time with `withClock`) | the tier and its harness |
| `docs/research/00-tech-decisions.md` | §2 **#88** (the row, written once, never revoked, excluded from the backup, never in prefs; Restore above Unlock) · **#89** (`purchase_in_flight_at` and the three-day window) · #90 · #91 (the `over_free_cap` columns) · #124 (the redaction list) · §5.1 for versions | the decisions this file implements |
| `shed-book-spec.md` | §14 | one-time unlock, no subscription, a cap that must not degrade 3am |
| `CLAUDE.md` | rule 4 (every write commits immediately) · the banned words · P2 | the write shape |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the entitlement's three rules are its subject |
| `shed-write-path` | the row, its transaction and its provenance |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/entitlement_test.dart`
- **Test** — `'an entitlement survives a restore and is never cleared by StoreUnreachable'`
- **Why it is red today** — nothing records the purchase, so an unlock would be lost the moment the store became unreachable — which, in a shed, is most of the time it is asked.

```bash
fvm flutter test test/data/entitlement_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion into the two halves it actually names, so neither can pass for the other's
reason. **Half one:** unlock, then feed `FakePurchaseService` a `StoreUnreachable` and then
`PurchaseSignal.failed`, and assert `unlocked` is still `1` — the row is never downgraded.
**Half two:** unlock, run a restore of a backup file that carries **no** entitlement row, and assert
the device is still unlocked afterwards *and* that a backup carrying `unlocked: 1` from another phone
does **not** unlock this one. Those two are a single test only because they are a single promise; if
they read better as two `test()` calls with the anchor name on the first, split them and keep the name.

**Green.** The minimum code that passes, and nothing beyond it — the repository, the three rules, and the restore round trip.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**The schema step is a check, not an edit.** `Entitlements` was frozen at **N07-T08** with exactly four
columns and seeded in `onCreate`. If `lib/core/db/tables/`, `lib/core/db/database.dart` or
`drift_schemas/` appears in this diff, stop — you have reached for a column that does not exist, and
`11 §4.1` lists what is deliberately absent (`product_id`, `store`, `acquired_via`, `purchase_id`,
`recorded_at_was_edited`).

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/entitlement_repository.dart` | **New.** `final class EntitlementRepository`, taking `AppDatabase` and `PurchaseService` (`11 §4.3`). Six members plus `attach`/`detach`. The only place in `lib/` that ever writes `entitlements.unlocked` |
| 2 | `lib/data/models.dart` | **Check, probably no edit.** R20: every drift row class is re-exported here, and `Entitlement` should already be present from N07-T02. If it is not, add it — a repository whose row type is not exported forces `lib/features/` to import `lib/core/db/`, which layer rule 5 forbids |
| 3 | `lib/data/providers.dart` | **Edit.** `entitlementRepositoryProvider` (`FutureProvider<EntitlementRepository>`, keepAlive, derived from `databaseProvider` + `purchaseServiceProvider`) and `entitlementProvider` (`StreamProvider<Entitlement>`, keepAlive). `ref.onDispose` wires `detach()` |
| 4 | `tool/check_policy.dart` | **Edit.** One row: `db.entitlement_revoke` |
| 5 | `test/policy/gate_rules_test.dart` | **Edit.** The planted-violation case. N03-T07's inventory assertion fails the build without it |
| 6 | `test/support/seeds.dart` | **Edit or check.** `setEntitlement(db, {required bool unlocked})` — `12 §5.3` names it and N14-T07 has been calling it since step 5. It writes the column **directly**, never through `markUnlocked`: a helper that goes through the verb under test cannot set up the *"already unlocked"* precondition without exercising it |
| 7 | `test/data/entitlement_test.dart` | **New.** The anchor and the cases in §5.4 |
| 8 | `test/policy/entitlement_is_never_revoked_test.dart` | **New.** `11 §12.2`'s file, named for the property rather than the file it tests (`CONVENTIONS §4.1`) |

### 5.2 The signatures

```dart
// lib/data/entitlement_repository.dart
final class EntitlementRepository {
  EntitlementRepository(this._db, this._purchases);

  Stream<Entitlement> watch();                    // one row, .distinct() HERE, never in the widget
  Future<Entitlement> read();                     // the boot check and the policy call sites (T04)
  Future<void> beginPurchase();                   // sets purchase_in_flight_at = appNow()
  Future<void> markUnlocked({required bool restored});
  Future<void> abandonPurchase();                 // clears purchase_in_flight_at
  void attach();                                  // PurchaseService.attach() + listen(updates)
  Future<void> detach();                          // cancels both; wired to ref.onDispose
}
```

`markUnlocked` is printed in full by `11 §4.3` and the shape is the point — three updates in **one**
`db.transaction`, and one line deliberately outside it:

```dart
Future<void> markUnlocked({required bool restored}) async {
  await _db.transaction(() async {
    final now = appNow();                       // R23: once per mutation, never per statement
    await (_db.update(_db.entitlements)..where((t) => t.id.equals(1))).write(
      EntitlementsCompanion(
        unlocked: const Value(true),
        unlockedAt: Value(now),
        purchaseInFlightAt: const Value(null),
      ),
    );
    // decision #91: on unlock the over-cap markers clear in one transaction.
    // No `where`: every marker in the file clears, which is the whole point.
    await _db.update(_db.ewes).write(const EwesCompanion(overFreeCap: Value(false)));
    await _db.update(_db.seasons).write(const SeasonsCompanion(overFreeCap: Value(false)));
  });
  // OUTSIDE the transaction, deliberately. LocalLog writes a file, a file write
  // can fail, and a failed diagnostics line must never roll back an unlock the
  // user has already paid for.
  LocalLog.instance.record(restored ? 'unlock.restored' : 'unlock.purchased');
}
```

```dart
// lib/data/providers.dart
final entitlementRepositoryProvider = FutureProvider<EntitlementRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final repo = EntitlementRepository(db, ref.watch(purchaseServiceProvider));
  ref.onDispose(repo.detach);
  return repo;
});                                              // keepAlive

final entitlementProvider = StreamProvider<Entitlement>((ref) async* {
  final repo = await ref.watch(entitlementRepositoryProvider.future);
  yield* repo.watch();
});   // keepAlive. Nothing on a shed screen may watch this (decision #90).
```

The gate row:

| Rule id | Fails on | Scope |
|---|---|---|
| `db.entitlement_revoke` | `markLocked`, `revokeEntitlement`, or `unlocked:` assigned `false` / `Constant(false)` outside `lib/core/db/tables/` | `lib/` |

The scope excludes `lib/core/db/tables/` for one reason: the column's own
`boolean().withDefault(const Constant(false))()` declaration lives there and is legitimate. Scoping the
rule to all of `lib/` without that carve-out fails the build on the schema.

### 5.3 The details that are easy to get wrong

- 🚩 **`markUnlocked` writes two tables it does not own, and that is the only such write in the app.**
  `ewes.over_free_cap` belongs to `FlockRepository` and `seasons.over_free_cap` to `SeasonRepository`
  (`CONVENTIONS §2.13`). Decision #91 requires the clear to be **atomic with the unlock**, and three
  repositories mean three transactions. `11 §4.3` states the exception and requires it to be repeated
  **in the method's doc comment**, with the reason: those two columns are monetization bookkeeping that
  happens to live on two record tables — written by their owners on insert, cleared here on unlock, and
  read by nothing else. Write that comment. A reviewer meeting a cross-repository write with no comment
  is right to stop.
- **The clear has no `where`, and that is not a bug.** Every marker in the file clears, including
  markers on rows from a restored backup that predate this device. `11 §8.1`: *"nothing reads
  `over_free_cap` when `unlocked = 1`"*, which is what makes stale markers harmless — the app does not
  rewrite the user's rows to tidy up its own bookkeeping.
- **`LocalLog.instance.record` takes an event string and nothing else.** Never the `purchaseID`, never
  the price, never a store error message. Decision #124's allowed list contains none of them, and the
  Diagnostics screen's honesty line — *"this file contains no animal records… you can open it and read
  it before you send it"* — is enforced by the redaction list, not by a reviewer remembering.
- **Rule 1 is never revoked, and the reason is a business one.** Both stores can revoke after a refund,
  but detecting that means polling the store on the launch path, which is the one thing this app
  refuses to do. Re-locking a shepherd on night nine because a refund propagated is unacceptable against
  €12 of revenue. That is deliberate, documented, and held by `db.entitlement_revoke` plus a policy
  test — not by discipline.
- **Only two signals write.** `purchased` → `markUnlocked(restored: false)`; `restored` →
  `markUnlocked(restored: true)`. `awaitingPayment`, `cancelled` and `failed` write **nothing**: a store
  failure never touches the row. The two writing arms are handled by the same code, which is what makes
  the `in_app_purchase_storekit` 0.4.3 regression (StoreKit 2 purchases reported as `restored`)
  incapable of costing an unlock even if a future resolution slips below the 0.4.8 floor.
- **`attach()` subscribes to `PurchaseService.updates`, which carries no plugin type.** If this file
  ever names `List<PurchaseDetails>` in a callback it imports the plugin, and `layer.in_app_purchase`
  becomes a comment. The seam is what makes the rule enforceable, not tidiness.
- **The row always exists.** `seedFirstRun` inserts `const EntitlementsCompanion()` in `onCreate`, so
  *"no entitlement row"* is not a state any code path handles. Do not write a `?? Entitlement.empty()`,
  a `getOrCreate`, or an `insertOnConflictUpdate`. If `read()` finds nothing, the database is corrupt
  and that is a `ShedFailure`, not a default.
- **`.distinct()` goes in the repository.** `watch()` on a one-row table re-emits on every unrelated
  write to that table; a `.distinct()` in the widget is a rebuild storm one refactor from returning.
- **`unlocked_at` and `purchase_in_flight_at` are machine facts, not event times.** No provenance quad,
  and **rendered nowhere in v1**: the unlocked Settings section reads one word, *"Unlocked."* — no date,
  no price, no receipt. R37's standing rule is what makes that safe: a table without the quad has no
  edit verb, and nothing displays an unprovenanced time. Rendering an unlock date later means adding
  the quad to the table first, which is a migration.
- **The 14-day drain bound is absolute, not civil.** `11 §5.1`: if `purchase_in_flight_at` is older
  than 14 days and `unlocked` is still `0`, call `abandonPurchase()` and do **not** attach. Fourteen
  days is 336 hours of elapsed time on `Instant` epoch millis. Computing it by subtracting `LocalDate`s
  is off by an hour twice a year, and this is the one place in the file where that arithmetic is
  tempting. Google's acknowledgement window is three days; a shepherd can be off-network for a week;
  after fourteen days the transaction has either been acknowledged or auto-refunded and continuing to
  initialise a billing client on every launch forever buys nothing.
- **`shared_preferences` is not an option.** Rule 3. Prefs are a second source of truth that disagrees
  with the database after a restore, they are trivially editable, `shared_preferences` is not in
  decision-record §5.1, and its absence is what lets T07 leave
  `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`) out of the privacy manifest.

🚩 **The restore question, which this task must rule and record.** The anchor test says the entitlement
*survives a restore*, and the documents say two things that do not obviously fit together:

- `#88` and `11 §4.2` rule 2: the row is **excluded from the backup and ignored on import** —
  *"restoring your neighbour's file must not unlock your app."*
- `04 §7.2`: restore imports into a **new** SQLite file beside the live one and then swaps. A fresh
  drift file runs `onCreate`, so its `entitlements` row is `seedFirstRun`'s default — `unlocked = 0`.

Read together with no further ruling, a shepherd who restores **their own** backup onto **their own**
phone loses a purchase they made, and `db.entitlement_revoke` does not see it because no code wrote
`false`. The reading that satisfies both halves is the one to implement and to write down: **the row is
never imported from the file, and the device's own row is carried across the swap.** That is a
one-sentence amendment to `04 §7` (add it to §7.5's list of things that must be true after any restore)
and to `11 §4.2` rule 2, and `00-README §10`'s amendment rule says it lands **in this commit**. If the
owner should decide instead, say so in the commit message and leave the test asserting the honest
alternative — a locked app whose remedy is the Restore purchases button (`11 §4.5`) — rather than
leaving the question open in code.

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/data/entitlement_test.dart` | **anchor** — `'an entitlement survives a restore and is never cleared by StoreUnreachable'` | Both halves of §4 |
| | `'markUnlocked clears both over_free_cap columns in the same transaction'` | Seed two flagged ewes and two flagged seasons; one call clears all four |
| | `'a mid-transaction failure leaves unlocked = 0 and both markers intact'` | Force the second update to throw; assert the rollback is total |
| | `'awaitingPayment, cancelled and failed write nothing'` | Three signals through `FakePurchaseService`, one assertion each |
| | `'an error or cancelled update leaves an existing unlocked = 1 untouched'` | Rule 1 from the other side |
| | `'markUnlocked is idempotent'` | Twice in a row; `unlocked_at` may move, `unlocked` may not flicker |
| | `'beginPurchase writes purchase_in_flight_at and abandonPurchase clears it'` | Decision #89's flag, both directions |
| | `'read() on a fresh database returns the seeded row rather than throwing'` | `seedFirstRun`'s guarantee, asserted once so nobody adds a null path |
| | `'watch() emits once for an unrelated write to the same table'` | `.distinct()` is in the repository |
| | `'a backup carrying unlocked: 1 imports to unlocked = 0'` | Rule 2, through `RestoreService` and `04 §7.8`'s refusal fixture |
| | **`@Tags(['uk-zone'])`** — `'the 14-day drain bound is 336 absolute hours across the clocks-back night'` | Set `purchase_in_flight_at` at `2026-10-24T23:30` local, evaluate at `2026-11-07T23:30` local — 337 h absolute because the night has 25 hours — and assert the bound fired. Civil-day arithmetic gives 14 and gets it wrong. Carry the `setUpAll` offset guard so the file fails loudly under the wrong `TZ` rather than skipping |
| `test/policy/entitlement_is_never_revoked_test.dart` | `'no code path in lib/ writes unlocked = false after onCreate'` | Source-text over `lib/`, with `lib/core/db/tables/` excluded **by name**, never by pattern |
| `test/policy/gate_rules_test.dart` | `'db.entitlement_revoke exits 1 on a planted markLocked in lib/data/'` | The proving case |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **How `guard()` applies here, precisely.** `WriteController.guard()` is the double-tap defence for
> **UI-initiated mutations**, and it lives in `lib/features/`. Nothing on this screen calls
> `markUnlocked` directly: the row is written by `attach()`'s stream listener, minutes after the tap
> that caused it, which is why `11 §6.6` records a *"stated, narrow departure"* from `CONVENTIONS §4.4`
> rule 2. The double-tap refusal that protects the user is `UnlockController`'s, in **T03**, in the same
> shape. What binds here is the rest of the write path: one `appNow()`, one `db.transaction`, no draft,
> no `save()`, no optimistic UI.

## 7. Definition of Done

- [ ] `'an entitlement survives a restore and is never cleared by StoreUnreachable'` passes, and was seen to fail first for the stated reason
- [ ] never cleared by an unreachable store
- [ ] survives a restore, asserted through `RestoreService`
- [ ] the row is in the backup's restorable set
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Reading line four.** *"The backup's restorable set"* is the set of state that survives a restore,
> **not** the set of tables written into the backup JSON. `entitlements` is absent from the file in both
> directions — the export writer skips it, the importer skips and logs it, and `09 §7` and `04 §7.7`
> both say so — because a backup that carried it would be a licence key. What survives is the
> **device's own row**, carried across the swap per §5.3's ruling. Both halves have to be true at once,
> and this line is the second one.

## 8. Verification

```bash
fvm flutter test test/data/entitlement_test.dart
fvm flutter test test/policy/entitlement_is_never_revoked_test.dart
fvm flutter test test/policy/gate_rules_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone         # the 14-day bound case must appear in the count
dart run tool/check_policy.dart
grep -rn "unlocked" lib/ | grep -v "lib/core/db/tables/" # no false, no Constant(false)
git diff --stat -- drift_schemas/ lib/core/db/           # nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): EntitlementRepository and its three rules`
