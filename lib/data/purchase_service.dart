// lib/data/purchase_service.dart
//
// **THE ONLY FILE IN THE APP PERMITTED TO IMPORT `package:in_app_purchase`.**
// Rule id: `layer.in_app_purchase`.
//
// **THE SEAM IS PLUGIN-FREE ON THE WAY *OUT*, AND THAT IS THE LOAD-BEARING
// HALF.** An import ban is trivially satisfied by a public signature that
// returns a plugin type — and then the *caller* imports the plugin to name it,
// legitimately, and the rule holds on paper while the architecture is gone. That
// is why the gate row carries a second clause banning five token names, why
// [updates] is a `Stream<PurchaseSignal>`, and why the price crosses as a bare
// `String`.
//
// The plugin surface used is **exactly seven members**: `instance`,
// `purchaseStream`, `isAvailable`, `queryProductDetails`, `buyNonConsumable`,
// `restorePurchases`, `completePurchase`. There is no `getPlatformAddition`, no
// `enableStoreKit1()` and no `buyConsumable`. Reaching for an eighth is a
// document conversation, not an implementation detail.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// **FROZEN AT THE FIRST SALE.** Byte-identical in App Store Connect and in Play
/// Console. Changing it strands every purchase ever made — there is no server to
/// migrate them with.
const String kUnlockProductId = 'shed_book_unlock';

/// The store did not answer inside the bound.
///
/// **DELIBERATELY NOT A `ShedFailure`** (`11 §6.2`). A shed with no signal is the
/// normal case, not a fault: the app is fully usable, every record is written,
/// and the only thing that cannot happen is a purchase. Making this a failure
/// type would put it in the same bucket as a corrupt database, and the panel
/// that renders those would tell a shepherd something is wrong when nothing is.
final class StoreUnreachable implements Exception {
  const StoreUnreachable();
}

/// Everything the rest of the app is allowed to learn from a store update about
/// **our** product. No plugin type crosses this line.
enum PurchaseSignal { awaitingPayment, purchased, restored, cancelled, failed }

/// **`interface class`, NOT `final class`, AND THE TWO DOCUMENTS DISAGREED.**
/// `11 §5` prints `final class PurchaseService`; `12 §4.1` requires every fake
/// to `implements` its gateway rather than `extends` it, so that a signature
/// change is a compile error instead of a silent divergence. Dart makes those
/// mutually exclusive: a `final` class cannot be implemented outside its own
/// library.
///
/// The other six gateways in this project already resolve it the same way —
/// `ShareService` is an `interface class` for exactly this reason — so the
/// testing rule wins and `11 §5` is amended in this commit. What `final` was
/// protecting is protected better by the gate: `layer.in_app_purchase` bans the
/// plugin and its five type names everywhere else, so there is nothing to gain
/// by subclassing this and nowhere to put it.
interface class PurchaseService {
  PurchaseService([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  /// Ten seconds. Long enough for a slow store on a bad connection, short enough
  /// that a shepherd standing in a shed with no signal is not left holding a
  /// screen that never resolves.
  static const Duration _bound = Duration(seconds: 10);

  /// **A BROADCAST FAN-OUT WE OWN**, so two readers can subscribe without either
  /// having to know whether the plugin's own stream is broadcast — which is a
  /// plugin implementation detail and has changed between majors.
  final StreamController<PurchaseSignal> _signals = StreamController<PurchaseSignal>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// The resolved product, if a query succeeded in this process. `null` before
  /// one has, which is why [buyUnlock] returns `false` rather than throwing.
  ProductDetails? _product;

  Stream<PurchaseSignal> get updates => _signals.stream;

  /// **SUBSCRIBING IS WHAT INITIALISES BILLING ON ANDROID**, which is why this
  /// is a method and not the constructor: `purchaseServiceProvider` can be a
  /// plain `Provider` on the Quick Entry path without a shed screen ever
  /// starting a billing client. Nothing on a shed screen calls this, and
  /// `FakePurchaseService`'s tripwire is what proves it.
  ///
  /// Idempotent: a second call while attached does nothing.
  void attach() {
    if (_subscription != null) {
      return;
    }
    _subscription = _iap.purchaseStream.listen(
      _onBatch,
      // The stream's own errors are store errors, not app errors — the same
      // reason [StoreUnreachable] is not a `ShedFailure`.
      onError: (Object _) => _signals.add(PurchaseSignal.failed),
    );
  }

  /// **CANCELS THE PLUGIN SUBSCRIPTION AND DOES *NOT* CLOSE THE FAN-OUT.** The
  /// provider is keepAlive and a later [attach] must work; closing `_signals`
  /// here is a *"Cannot add new events after calling close"* on the next
  /// Settings visit.
  Future<void> detach() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Bounded, and **times out to `false`** — an unanswered store is an
  /// unavailable one for the purposes of showing a price.
  Future<bool> isAvailable() async {
    try {
      return await _iap.isAvailable().timeout(_bound);
    } on Object {
      return false;
    }
  }

  /// The localised price, or `null` if the id is not configured yet.
  ///
  /// **TIMES OUT BY THROWING, WHICH IS THE OPPOSITE OF [isAvailable] AND IS
  /// DELIBERATE.** They answer two different questions. *Is there a store?* has
  /// a useful `false`. *What does it cost?* has no useful `null` — rendering a
  /// blank price is how a screen ends up saying the unlock is free.
  Future<String?> queryUnlockPrice() async {
    final ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails(<String>{kUnlockProductId}).timeout(_bound);
    } on Object {
      throw const StoreUnreachable();
    }
    if (response.productDetails.isEmpty) {
      // The id is not configured in the store yet. A real state during setup,
      // and not an error — the section renders without a price.
      return null;
    }
    _product = response.productDetails.first;
    return _product!.price;
  }

  /// **`false` WHEN NO PRODUCT WAS RESOLVED IN THIS PROCESS**, rather than
  /// querying inside the tap. A buy that silently performs a network round trip
  /// first is a buy that can take ten seconds after the thumb has left the glass.
  Future<bool> buyUnlock() async {
    final ProductDetails? product = _product;
    if (product == null) {
      return false;
    }
    // **`buyNonConsumable`, NEVER `buyConsumable`.** One non-consumable unlock,
    // bought once (spec §14). A consumable would let the same shepherd buy it
    // twice and would not restore.
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// **NO `applicationUserName`.** There is no account in this app to name, and
  /// passing a device id would be inventing one. The results replay through
  /// [updates] like any other batch.
  Future<void> restore() => _iap.restorePurchases();

  /// One batch from the store.
  ///
  /// **THE ORDER OF THE TWO ACTS IN HERE IS THE WHOLE METHOD.** Google
  /// auto-refunds and revokes a purchase that is not acknowledged within **three
  /// days**, and on Android `completePurchase` *is* `acknowledgePurchase()`.
  ///
  ///   * acknowledge-then-write leaves a window one process-death wide in which
  ///     the purchase is acknowledged and the row unwritten — repaired by the
  ///     Restore button Apple already requires;
  ///   * write-then-acknowledge produces an auto-refund three days later, and
  ///     **nothing repairs that**.
  ///
  /// So the signal is emitted only after the completion is issued, and the
  /// listener that writes the row is downstream of the emit.
  Future<void> _onBatch(List<PurchaseDetails> batch) async {
    for (final PurchaseDetails purchase in batch) {
      // **COMPLETION RUNS FOR EVERY SETTLED UPDATE, REGARDLESS OF PRODUCT
      // ID.** An unrecognised id left uncompleted is redelivered forever. The id
      // check below gates the SIGNAL, not the completion — and the two sit one
      // apart, which is exactly how they get swapped.
      //
      // **NEVER COMPLETE A PURCHASE THE STORE IS STILL WAITING ON.** Google's
      // own wording: *"don't acknowledge it while a purchase is in PENDING
      // state."* On Android `completePurchase` IS `acknowledgePurchase()`.
      if (purchase.status != PurchaseStatus.pending && purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      if (purchase.productID != kUnlockProductId) {
        continue;
      }

      // **EXHAUSTIVE, NO `default:` AND NO `_ =>`.** Five members, five arms. A
      // catch-all turns a sixth member in a future plugin major from a compile
      // error into a silently-ignored purchase.
      _signals.add(switch (purchase.status) {
        PurchaseStatus.pending => PurchaseSignal.awaitingPayment,
        PurchaseStatus.purchased => PurchaseSignal.purchased,
        PurchaseStatus.restored => PurchaseSignal.restored,
        PurchaseStatus.canceled => PurchaseSignal.cancelled,
        PurchaseStatus.error => PurchaseSignal.failed,
      });
    }
  }
}
