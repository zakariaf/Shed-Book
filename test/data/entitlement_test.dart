// test/data/entitlement_test.dart
library;

import 'package:drift/drift.dart' show QueryRow, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/entitlement_repository.dart';
import 'package:shed_book/data/purchase_service.dart';
import 'package:shed_book/domain/ids.dart';

import '../support/fake_purchase_service.dart';
import '../support/harness.dart';
import '../support/seeds.dart';

Future<Entitlement> _row(AppDatabase db) => db.select(db.entitlements).getSingle();

void main() {
  test('an entitlement survives a restore and is never cleared by StoreUnreachable', () async {
    // **THE ANCHOR, AND IT IS TWO HALVES THAT MUST NOT PASS FOR EACH OTHER'S
    // REASON.**
    //
    // HALF ONE — the row is never downgraded. A shed has no signal most of the
    // time the store is asked, so *"the store did not confirm"* is the NORMAL
    // case; an app that acted on it would take the unlock away from a shepherd
    // standing in a barn at 03:20, for a network they never had.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService(unreachable: true);
    final EntitlementRepository repo = EntitlementRepository(db, store);
    repo.attach();

    await repo.markUnlocked(restored: false);
    expect((await _row(db)).unlocked, isTrue);

    // The store cannot report what it could not reach — so `StoreUnreachable`
    // never becomes a signal. What CAN arrive is `failed`, and it must not
    // touch `unlocked` either.
    await expectLater(store.queryUnlockPrice(), throwsA(isA<StoreUnreachable>()));
    store.emit(PurchaseSignal.failed);
    await pumpEventQueue();

    expect(
      (await _row(db)).unlocked,
      isTrue,
      reason: 'a failed attempt by somebody who already paid revoked their unlock',
    );

    await repo.detach();
    await store.dispose();
    await db.close();
  });

  test('unlocking clears every over_free_cap marker, in the same transaction', () async {
    // Decision #91, and the shape is the point: **no `where`**. Every marker in
    // the file clears. A paid notebook carrying a mark that part of it was over
    // a line is the cap applied retroactively, which `07 §19.4` rule 1 forbids —
    // *"rows over the cap are real rows."*
    final AppDatabase db = testDatabase();
    final SeasonId season = await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(ewe.value))).write(
      const EwesCompanion(overFreeCap: Value<bool>(true)),
    );
    await (db.update(db.seasons)..where(($SeasonsTable t) => t.id.equals(season.value))).write(
      const SeasonsCompanion(overFreeCap: Value<bool>(true)),
    );

    final FakePurchaseService store = FakePurchaseService();
    await EntitlementRepository(db, store).markUnlocked(restored: false);

    expect((await db.select(db.ewes).get()).every((Ewe e) => !e.overFreeCap), isTrue);
    expect((await db.select(db.seasons).get()).every((Season s) => !s.overFreeCap), isTrue);
    expect((await _row(db)).unlockedAt, isNotNull);

    await store.dispose();
    await db.close();
  });

  test('a restored purchase and a bought one are the same row and a different log line', () async {
    // The row records **that** the app is unlocked and nothing about how. `11
    // §4.1` lists what is deliberately absent — `product_id`, `store`,
    // `acquired_via`, `purchase_id` — because none of them changes what the
    // shepherd may do, and each is a fact about somebody's payment method
    // sitting in a file they will hand to a vet.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository repo = EntitlementRepository(db, store);

    await repo.markUnlocked(restored: true);
    final Entitlement afterRestore = await _row(db);

    await repo.markUnlocked(restored: false);
    final Entitlement afterPurchase = await _row(db);

    expect(afterRestore.unlocked, isTrue);
    expect(afterPurchase.unlocked, isTrue);

    // The columns that would distinguish them do not exist. Asserted against the
    // live schema, so adding one is caught here rather than at review.
    final List<String> columns =
        (await db.customSelect("SELECT name FROM pragma_table_info('entitlements')").get())
            .map((QueryRow r) => r.read<String>('name'))
            .toList();
    expect(columns, isNot(contains('product_id')));
    expect(columns, isNot(contains('store')));
    expect(columns, isNot(contains('acquired_via')));
    expect(columns, isNot(contains('purchase_id')));

    await store.dispose();
    await db.close();
  });

  test('cancelling clears the in-flight stamp and leaves an existing unlock alone', () async {
    // **A CANCELLED PURCHASE IS NOT A REVOCATION.** Somebody who already owns
    // the unlock and taps Buy by mistake must still own it afterwards — and the
    // stamp must clear, or the screen shows a purchase in flight for ever.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository repo = EntitlementRepository(db, store);
    repo.attach();

    await repo.markUnlocked(restored: false);
    await repo.beginPurchase();
    expect((await _row(db)).purchaseInFlightAt, isNotNull);

    store.emit(PurchaseSignal.cancelled);
    await pumpEventQueue();

    expect((await _row(db)).purchaseInFlightAt, isNull);
    expect((await _row(db)).unlocked, isTrue, reason: 'a cancellation revoked an unlock');

    await repo.detach();
    await store.dispose();
    await db.close();
  });

  test('awaitingPayment keeps the stamp, because that is the state it records', () async {
    // The store has taken the request and not settled it — a real state on
    // Android, where a purchase can wait on a parent's approval or a cash
    // payment for days. Clearing the stamp here would make the screen say
    // nothing is happening while something is.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository repo = EntitlementRepository(db, store);
    repo.attach();

    await repo.beginPurchase();
    store.emit(PurchaseSignal.awaitingPayment);
    await pumpEventQueue();

    expect((await _row(db)).purchaseInFlightAt, isNotNull);
    expect((await _row(db)).unlocked, isFalse, reason: 'an unsettled purchase unlocked the app');

    await repo.detach();
    await store.dispose();
    await db.close();
  });

  test('attach is idempotent and detach leaves the store reusable', () async {
    // `purchaseServiceProvider` is keepAlive and `detach()` deliberately does not
    // close the fan-out — a `close()` there is a *"Cannot add new events after
    // calling close"* on the next Settings visit.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository repo = EntitlementRepository(db, store);

    repo.attach();
    repo.attach();
    expect(store.calls.where((String c) => c == 'attach'), hasLength(1));

    await repo.detach();
    repo.attach();
    store.emit(PurchaseSignal.purchased);
    await pumpEventQueue();
    expect((await _row(db)).unlocked, isTrue, reason: 'the store was not reusable after detach');

    await repo.detach();
    await store.dispose();
    await db.close();
  });
}
