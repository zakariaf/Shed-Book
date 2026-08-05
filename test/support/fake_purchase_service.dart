// test/support/fake_purchase_service.dart — the seventh and last fake.
//
// **`implements`, NEVER `extends`** (`12 §4.1`). A signature change on
// `PurchaseService` must be a compile error here rather than a silent
// divergence — a fake that inherits the real method keeps passing while the
// thing it stands for has moved.
library;

import 'dart:async';

import 'package:shed_book/data/purchase_service.dart';

/// The store, as the tests see it.
///
/// **IT COUNTS ITS CALLS, AND THAT IS THE POINT OF IT.** Decision #90's promise
/// — *nothing monetization-related renders on a shed screen at any entitlement
/// state* — is not provable by looking at pixels: a screen that quietly asked
/// the store a question and rendered nothing would pass every visual assertion.
/// The tripwire is that [attach], [isAvailable], [queryUnlockPrice], [buyUnlock]
/// and [restore] each record themselves, and the shed-screen tests assert the
/// list is **empty**.
final class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.price = '£24.99', this.available = true, this.unreachable = false});

  /// Every call, in order, by name. Asserted empty on every shed screen.
  final List<String> calls = <String>[];

  /// What [queryUnlockPrice] answers. **A `String`, like the real one** — the
  /// price crosses the seam pre-formatted by the store, because the store knows
  /// the currency and the locale of the account and this app knows neither.
  final String? price;

  final bool available;

  /// When true, [queryUnlockPrice] throws exactly as a ten-second timeout does.
  /// The default is a store that answers, because a fake whose default is
  /// failure makes every unrelated test assert the failure path.
  final bool unreachable;

  final StreamController<PurchaseSignal> _signals = StreamController<PurchaseSignal>.broadcast();

  /// Drives a signal as though the store had sent one, so a test can exercise
  /// the listener without a store.
  void emit(PurchaseSignal signal) => _signals.add(signal);

  @override
  Stream<PurchaseSignal> get updates => _signals.stream;

  @override
  void attach() => calls.add('attach');

  @override
  Future<void> detach() async => calls.add('detach');

  @override
  Future<bool> isAvailable() async {
    calls.add('isAvailable');
    return available;
  }

  @override
  Future<String?> queryUnlockPrice() async {
    calls.add('queryUnlockPrice');
    if (unreachable) {
      throw const StoreUnreachable();
    }
    return price;
  }

  @override
  Future<bool> buyUnlock() async {
    calls.add('buyUnlock');
    return true;
  }

  @override
  Future<void> restore() async => calls.add('restore');

  /// Closes the fan-out. **The real service deliberately does not** — its
  /// provider is keepAlive and a later `attach()` must work — but a fake lives
  /// one test, and a controller left open is a pending timer at teardown.
  Future<void> dispose() => _signals.close();
}
