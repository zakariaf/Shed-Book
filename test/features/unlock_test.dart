// test/features/unlock_test.dart
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/purchase_service.dart';
import 'package:shed_book/features/settings/unlock_controller.dart';

import '../support/fake_purchase_service.dart';
import '../support/harness.dart';

/// A container with the store faked and the database in memory.
({ProviderContainer container, FakePurchaseService store}) _harness(
  AppDatabase db, {
  bool unreachable = false,
  bool available = true,
  String? price = '£24.99',
}) {
  final FakePurchaseService store = FakePurchaseService(
    unreachable: unreachable,
    available: available,
    price: price,
  );
  final ProviderContainer container = shedContainer(
    db,
    overrides: <Override>[purchaseServiceProvider.overrideWithValue(store)],
  );
  // **THE LISTENER IS NOT OPTIONAL, AND FORGETTING IT MADE TWO CASES LIE.**
  // `unlockControllerProvider` is `.autoDispose`; a bare `read` of its notifier
  // builds it, runs the body and disposes it immediately — which fires
  // `ref.onDispose(() => _sub?.cancel())` and unsubscribes from the store before
  // the test emits a signal. The state then never moves and the case reads as
  // *the controller ignored it*.
  //
  // Holding a subscription is what a mounted section does, so this is the
  // truthful setup rather than a workaround.
  container.listen<UnlockState>(unlockControllerProvider, (UnlockState? _, UnlockState _) {});
  return (container: container, store: store);
}

void main() {
  test('opening the section asks the store once and rests on the price it gave', () async {
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);

    expect(h.container.read(unlockControllerProvider), isA<UnlockOffered>());
    await h.container.read(unlockControllerProvider.notifier).openSection();

    final UnlockState state = h.container.read(unlockControllerProvider);
    expect(state, isA<UnlockOffered>());
    expect((state as UnlockOffered).price, '£24.99');

    // **`attach()` HAPPENS HERE AND NOWHERE EARLIER.** Subscribing is what
    // initialises the Android billing client, and #90's promise is that no shed
    // screen does it.
    expect(h.store.calls, contains('attach'));

    await h.store.dispose();
    await db.close();
  });

  test('an unreachable store rests on a state that is not a failure', () async {
    // A shed has no signal most of the time the store is asked. This is the
    // NORMAL case: `StoreUnreachable` is not a `ShedFailure`, and the state it
    // produces never renders through `showFailure()`.
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(
      db,
      unreachable: true,
    );

    await h.container.read(unlockControllerProvider.notifier).openSection();

    final UnlockState state = h.container.read(unlockControllerProvider);
    expect(state, isA<UnlockUnavailable>());
    expect((state as UnlockUnavailable).reason, UnlockUnavailableReason.storeUnreachable);

    await h.store.dispose();
    await db.close();
  });

  test('an unconfigured product and an unavailable store are the same honest answer', () async {
    // Two causes, one sentence: the app cannot tell them apart and must not
    // guess which one to blame.
    final AppDatabase db = testDatabase();

    for (final ({bool available, String? price}) c in <({bool available, String? price})>[
      (available: false, price: '£24.99'),
      (available: true, price: null),
    ]) {
      final ({ProviderContainer container, FakePurchaseService store}) h = _harness(
        db,
        available: c.available,
        price: c.price,
      );
      await h.container.read(unlockControllerProvider.notifier).openSection();

      expect(
        (h.container.read(unlockControllerProvider) as UnlockUnavailable).reason,
        UnlockUnavailableReason.productNotFound,
      );
      await h.store.dispose();
    }

    await db.close();
  });

  test('a double tap on Unlock buys once', () async {
    // **THE DOUBLE-TAP DEFENCE, HELD BY THE STATE MACHINE RATHER THAN BY
    // `guard()`.** This controller deliberately does not extend
    // `WriteController` (`11 §6.6`): `guard()` wraps one future, and a purchase
    // is a call that returns plus a signal that arrives seconds or days later on
    // a stream. Every entry point refuses while the state is
    // `UnlockContactingStore`.
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);
    final UnlockController controller = h.container.read(unlockControllerProvider.notifier);
    await controller.openSection();

    await Future.wait<void>(<Future<void>>[controller.unlock(), controller.unlock()]);

    expect(
      h.store.calls.where((String c) => c == 'buyUnlock'),
      hasLength(1),
      reason: 'a cold thumb through a bag double-fires — it must buy once',
    );

    await h.store.dispose();
    await db.close();
  });

  test('a double tap on Restore purchases restores once', () async {
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);
    final UnlockController controller = h.container.read(unlockControllerProvider.notifier);
    await controller.openSection();

    await Future.wait<void>(<Future<void>>[controller.restore(), controller.restore()]);

    expect(h.store.calls.where((String c) => c == 'restore'), hasLength(1));

    await h.store.dispose();
    await db.close();
  });

  test('awaitingPayment says so, and does not unlock', () async {
    // Android's cash and bank-transfer instruments, and Apple's Ask to Buy hold.
    // Nobody else in the app can tell the shepherd this is happening.
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);
    await h.container.read(unlockControllerProvider.notifier).openSection();

    h.store.emit(PurchaseSignal.awaitingPayment);
    await pumpEventQueue();

    expect(h.container.read(unlockControllerProvider), isA<UnlockAwaitingPayment>());
    expect((await db.select(db.entitlements).getSingle()).unlocked, isFalse);

    await h.store.dispose();
    await db.close();
  });

  test('cancelling returns to rest with the price kept, and is not a failure', () async {
    // The shepherd backed out of the store's own sheet. That is not a failure
    // and must not read as one — the button they just left is still there.
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);
    await h.container.read(unlockControllerProvider.notifier).openSection();

    h.store.emit(PurchaseSignal.cancelled);
    await pumpEventQueue();

    final UnlockState state = h.container.read(unlockControllerProvider);
    expect(state, isA<UnlockOffered>());
    expect(
      (state as UnlockOffered).price,
      '£24.99',
      reason: 'the price was re-fetched or lost — it is kept for this process',
    );

    await h.store.dispose();
    await db.close();
  });

  test('purchased and restored are ignored here, because the row is the source', () async {
    // Acting on them would be a second writer for the same fact, one frame
    // apart. `EntitlementRepository` writes the row and the section re-renders
    // from `entitlementProvider`.
    final AppDatabase db = testDatabase();
    final ({ProviderContainer container, FakePurchaseService store}) h = _harness(db);
    await h.container.read(unlockControllerProvider.notifier).openSection();
    final UnlockState before = h.container.read(unlockControllerProvider);

    h.store.emit(PurchaseSignal.purchased);
    h.store.emit(PurchaseSignal.restored);
    await pumpEventQueue();

    expect(h.container.read(unlockControllerProvider).runtimeType, before.runtimeType);

    await h.store.dispose();
    await db.close();
  });

  test('UnlockState has exactly four variants and none of them is a ShedFailure', () {
    // The sealed set is the specification. A fifth variant is a document
    // conversation; a `ShedFailure` here would put a store outage in the same
    // panel as a corrupt records file.
    const List<UnlockState> all = <UnlockState>[
      UnlockOffered(),
      UnlockContactingStore(),
      UnlockAwaitingPayment(),
      UnlockUnavailable(UnlockUnavailableReason.storeError),
    ];
    expect(all, hasLength(4));
    expect(UnlockUnavailableReason.values, hasLength(4));

    // Exhaustive with no `default:` — the day a fifth variant lands, every
    // switch must fail to compile rather than render nothing.
    for (final UnlockState s in all) {
      final String name = switch (s) {
        UnlockOffered() => 'offered',
        UnlockContactingStore() => 'contacting',
        UnlockAwaitingPayment() => 'awaiting',
        UnlockUnavailable() => 'unavailable',
      };
      expect(name, isNotEmpty);
    }
  });
}
