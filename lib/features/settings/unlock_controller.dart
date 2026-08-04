// lib/features/settings/unlock_controller.dart
//
// **THE ONE PLACE A STORE FAILURE IS RENDERED, AND IT IS NOT A `ShedFailure`.**
// A shed has no signal most of the time the store is asked, so an unreachable
// store is the normal case rather than a fault: the app is fully usable, every
// record is written, and the only thing that cannot happen is a purchase.
// Routing it through `showFailure()` would put it in the same panel as a corrupt
// records file and tell a shepherd something is wrong when nothing is.
//
// **NO SPINNER, NO DIALOG, NO SNACKBAR, NO HAPTIC, NO RED, NO RETRY LOOP, NO
// BLOCKED SCREEN** (`11 §6.5`). The button's label changes and the section keeps
// working. Everything here is bounded at ten seconds by the seam.
//
// **THIS CONTROLLER DOES NOT EXTEND `WriteController`, AND THE DEPARTURE IS
// STATED RATHER THAN QUIET** (`11 §6.6`, `CONVENTIONS §4.4` rule 2). `guard()`
// wraps one `Future<WriteOutcome>` and reports through `WriteState` — but a
// purchase is not one future: it is a call that returns, and then a signal that
// arrives from the store seconds or days later, on a stream. The double-tap
// defence `guard()` exists for is kept, by the state machine itself: every entry
// point refuses while `UnlockContactingStore` is the state.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/entitlement_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/purchase_service.dart';

sealed class UnlockState {
  const UnlockState();
}

/// The resting state.
///
/// **`price` IS NON-NULL ONLY IF THE STORE ANSWERED IN *THIS* PROCESS, AND IT IS
/// NEVER PERSISTED.** A stored price goes stale — currencies move, tiers change,
/// a shepherd travels — and a stale price in front of a user is the same class
/// of dishonesty as a stale clear date shown as current.
final class UnlockOffered extends UnlockState {
  const UnlockOffered({this.price});

  /// The store's own localised, currency-formatted string. **Never built here**:
  /// this app does not know the currency of the account or the tier the store
  /// resolved, and formatting one would be inventing a number (`copy.currency_literal`).
  final String? price;
}

/// A bounded store call is in flight.
///
/// **NO SPINNER** — `ui.spinner` refuses the indeterminate progress widget
/// anywhere under `lib/features/`, and that row scans comments too, so it is
/// described here rather than named. The Unlock button's label swaps and the button stops
/// accepting taps, which is also this controller's double-tap defence.
final class UnlockContactingStore extends UnlockState {
  const UnlockContactingStore();
}

/// Android's slow payment instruments — cash, bank transfer — and Apple's Ask to
/// Buy family-approval hold.
///
/// **DO NOT UNLOCK, DO NOT COMPLETE, KEEP THE IN-FLIGHT STAMP.** A purchase in
/// this state can settle days later, and nobody else in the app can tell the
/// shepherd it is happening.
final class UnlockAwaitingPayment extends UnlockState {
  const UnlockAwaitingPayment();
}

/// The store could not be reached, or refused, or the shepherd backed out.
///
/// **NOT A `ShedFailure`, AND IT NEVER RENDERS THROUGH `showFailure()`.**
final class UnlockUnavailable extends UnlockState {
  const UnlockUnavailable(this.reason);

  final UnlockUnavailableReason reason;
}

enum UnlockUnavailableReason { storeUnreachable, productNotFound, userCancelled, storeError }

final class UnlockController extends AutoDisposeNotifier<UnlockState> {
  StreamSubscription<PurchaseSignal>? _sub;

  /// The last price the store gave us **in this process**, so a cancellation can
  /// return to rest without asking again. Not persisted, for the reason on
  /// [UnlockOffered.price].
  String? _price;

  @override
  UnlockState build() {
    ref.onDispose(() => _sub?.cancel());
    return const UnlockOffered();
  }

  /// Settings ▸ Unlock became visible.
  ///
  /// **THIS IS WHERE THE STORE IS FIRST TOUCHED, AND THAT IS THE WHOLE OF #90.**
  /// `attach()` initialises the Android billing client; nothing on a shed screen
  /// calls it, and `FakePurchaseService`'s call list proves it.
  Future<void> openSection() async {
    if (state is UnlockContactingStore) {
      return;
    }
    state = const UnlockContactingStore();

    final PurchaseService store = ref.read(purchaseServiceProvider);
    store.attach();
    _sub ??= store.updates.listen(_onSignal);

    if (!await store.isAvailable()) {
      state = const UnlockUnavailable(UnlockUnavailableReason.productNotFound);
      return;
    }

    try {
      final String? price = await store.queryUnlockPrice();
      if (price == null) {
        // The id is not configured in the store yet — a real state during setup,
        // and a different fact from *the store did not answer*.
        state = const UnlockUnavailable(UnlockUnavailableReason.productNotFound);
        return;
      }
      _price = price;
      state = UnlockOffered(price: price);
    } on StoreUnreachable {
      state = const UnlockUnavailable(UnlockUnavailableReason.storeUnreachable);
    }
  }

  /// The Unlock tap.
  ///
  /// **THE IN-FLIGHT STAMP IS WRITTEN BEFORE THE STORE IS ASKED**, so a process
  /// death between the two leaves a record that something was started — which is
  /// what the boot check reads.
  Future<void> unlock() async {
    if (state is UnlockContactingStore) {
      return; // the double-tap defence, held by the state machine
    }
    state = const UnlockContactingStore();

    final EntitlementRepository entitlements = await ref.read(entitlementRepositoryProvider.future);
    await entitlements.beginPurchase();

    if (!await ref.read(purchaseServiceProvider).buyUnlock()) {
      // No `ProductDetails` was resolved in this process — the same fact
      // `openSection` reports, reached a different way.
      await entitlements.abandonPurchase();
      state = const UnlockUnavailable(UnlockUnavailableReason.productNotFound);
    }
  }

  /// **RESTORE IS MANDATORY AND SITS ABOVE UNLOCK** (`11 §6.4`). Apple requires
  /// it; a shepherd who reinstalled must be able to get back what they own
  /// without paying twice, and the route to it must not be below the thing that
  /// charges them.
  Future<void> restore() async {
    if (state is UnlockContactingStore) {
      return;
    }
    state = const UnlockContactingStore();
    await ref.read(purchaseServiceProvider).restore();
  }

  /// **THREE OF THE FIVE SIGNALS, AND THE OTHER TWO ARE IGNORED ON PURPOSE.**
  /// `purchased` and `restored` write the row through `EntitlementRepository`,
  /// and the section re-renders from `entitlementProvider` — so acting on them
  /// here would be a second writer for the same fact, one frame apart.
  Future<void> _onSignal(PurchaseSignal signal) async {
    switch (signal) {
      case PurchaseSignal.awaitingPayment:
        state = const UnlockAwaitingPayment();
      case PurchaseSignal.cancelled:
        // Back to rest, price kept — the shepherd backed out of a sheet, which
        // is not a failure and must not read as one.
        state = UnlockOffered(price: _price);
      case PurchaseSignal.failed:
        // **THE ROW IS UNTOUCHED.** A failed attempt by somebody who already
        // owns the unlock leaves them owning it.
        state = const UnlockUnavailable(UnlockUnavailableReason.storeError);
      case PurchaseSignal.purchased:
      case PurchaseSignal.restored:
        break;
    }
  }
}

final AutoDisposeNotifierProvider<UnlockController, UnlockState> unlockControllerProvider =
    NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new);
