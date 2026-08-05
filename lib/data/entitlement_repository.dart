// lib/data/entitlement_repository.dart
//
// **THE ONLY PLACE IN `lib/` THAT EVER WRITES `entitlements.unlocked`.** One
// row, one writer, and a gate row — `db.entitlement_revoke` — that refuses the
// write nobody should ever make.
//
// ---------------------------------------------------------------------------
// THE THREE RULES, AND EACH IS A DIFFERENT WAY OF LOSING SOMEBODY'S MONEY.
// ---------------------------------------------------------------------------
//
// 1. **AN ENTITLEMENT IS NEVER REVOKED.** There is no verb here that sets
//    `unlocked` to false, and the gate refuses one. A shed has no signal most of
//    the time the store is asked, so *"the store did not confirm"* is the normal
//    case — and an app that downgraded on it would take the unlock away from a
//    shepherd standing in a barn at 03:20, for a network they never had.
//
// 2. **`StoreUnreachable` CHANGES NOTHING.** It is not a `ShedFailure` and it is
//    not a signal: the listener below never sees one, because the store cannot
//    report what it could not reach.
//
// 3. **UNLOCK CLEARS EVERY `over_free_cap` MARKER, IN THE SAME TRANSACTION**
//    (#91). Not a `where`, not a subset — every marker in the file. The cap
//    constrains the next write and never the existing records, so a paid-for
//    notebook must not carry a mark saying part of it was over a line.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/log/local_log.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/data/purchase_service.dart';
import 'package:shed_book/domain/time/instant.dart';

final class EntitlementRepository {
  EntitlementRepository(this._db, this._purchases);

  final AppDatabase _db;
  final PurchaseService _purchases;

  StreamSubscription<PurchaseSignal>? _signals;

  /// The one row, watched.
  ///
  /// **`.distinct()` HERE, NEVER IN THE WIDGET** (`01 §4.4`). drift re-runs a
  /// watched query on any write to a tracked table, and `entitlements` is
  /// written by three verbs — without this, every `beginPurchase` would rebuild
  /// every screen watching the entitlement.
  ///
  /// `watchSingle`, not `watchSingleOrNull`: the table has `CHECK (id = 1)` and
  /// `seedFirstRun` seeds the row in `onCreate`, so it can never find nothing.
  /// A null branch would have to guess an entitlement, and the safe guess and
  /// the honest one are different.
  Stream<Entitlement> watch() => (_db.select(
    _db.entitlements,
  )..where(($EntitlementsTable t) => t.id.equals(1))).watchSingle().distinct();

  /// The boot check and the two gated verbs' call site (T04).
  Future<Entitlement> read() =>
      (_db.select(_db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).getSingle();

  /// A purchase has been started and the store has not answered.
  ///
  /// **IT IS A TIMESTAMP AND NOT A STATE ENUM**, deliberately: the question the
  /// screen asks is *"how long has this been in flight?"*, and a boolean cannot
  /// answer it. `pending` as a model state is a banned word in this project for
  /// the same reason.
  Future<void> beginPurchase() async {
    final Instant now = appNow(); // R23: once per mutation
    await (_db.update(_db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).write(
      EntitlementsCompanion(purchaseInFlightAt: Value<Instant?>(now)),
    );
  }

  /// The purchase landed.
  ///
  /// `11 §4.3` prints this in full and the shape is the point: three updates in
  /// **one** transaction, and one line deliberately outside it.
  Future<void> markUnlocked({required bool restored}) async {
    await _db.transaction(() async {
      final Instant now = appNow(); // R23: once per mutation, never per statement
      await (_db.update(_db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).write(
        EntitlementsCompanion(
          unlocked: const Value<bool>(true),
          unlockedAt: Value<Instant?>(now),
          purchaseInFlightAt: const Value<Instant?>(null),
        ),
      );
      // Decision #91: on unlock the over-cap markers clear in one transaction.
      // **NO `where`** — every marker in the file clears, which is the whole
      // point. A paid notebook carrying a mark that part of it was over a line
      // is the cap applied retroactively, which §19.4 rule 1 forbids.
      await _db.update(_db.ewes).write(const EwesCompanion(overFreeCap: Value<bool>(false)));
      await _db.update(_db.seasons).write(const SeasonsCompanion(overFreeCap: Value<bool>(false)));
    });
    // **OUTSIDE THE TRANSACTION, DELIBERATELY.** `LocalLog` writes a file, a file
    // write can fail, and a failed diagnostics line must never roll back an
    // unlock the shepherd has already paid for.
    LocalLog.instance.record(restored ? 'unlock.restored' : 'unlock.purchased');
  }

  /// The shepherd cancelled, or the store said no.
  ///
  /// **IT CLEARS THE IN-FLIGHT STAMP AND TOUCHES `unlocked` NEITHER WAY.** A
  /// cancelled purchase is not a revocation — somebody who already owns the
  /// unlock and taps Buy by mistake must still own it afterwards.
  Future<void> abandonPurchase() async {
    await (_db.update(_db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).write(
      const EntitlementsCompanion(purchaseInFlightAt: Value<Instant?>(null)),
    );
  }

  /// Starts the store and listens for what it says about our product.
  ///
  /// **NOTHING ON A SHED SCREEN CALLS THIS** (#90). Subscribing is what
  /// initialises the Android billing client, and `FakePurchaseService`'s call
  /// list is the tripwire that proves no shed screen does.
  void attach() {
    if (_signals != null) {
      return;
    }
    _purchases.attach();
    _signals = _purchases.updates.listen(_onSignal);
  }

  Future<void> detach() async {
    await _signals?.cancel();
    _signals = null;
    await _purchases.detach();
  }

  /// **EXHAUSTIVE, NO `default:`.** Five signals, five arms — and three of them
  /// deliberately do nothing to `unlocked`.
  Future<void> _onSignal(PurchaseSignal signal) async {
    switch (signal) {
      case PurchaseSignal.purchased:
        await markUnlocked(restored: false);
      case PurchaseSignal.restored:
        await markUnlocked(restored: true);
      // **CANCELLED AND FAILED CLEAR THE STAMP AND NOTHING ELSE.** Neither is
      // evidence about what the shepherd owns; a failed *attempt* by somebody
      // who already paid must leave them exactly as they were.
      case PurchaseSignal.cancelled:
      case PurchaseSignal.failed:
        await abandonPurchase();
      // The store has taken the payment request and not settled it. The stamp
      // stays, because that is the state it records.
      case PurchaseSignal.awaitingPayment:
        break;
    }
  }
}
