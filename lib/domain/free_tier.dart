import 'package:shed_book/domain/time/instant.dart';

/// The free tier's two limits.
///
/// **Constants, not constructor parameters.** An injectable cap lets a test
/// lower it to 3 and hide an off-by-one that production would then ship. The
/// at-cap fixture (`test/fixtures/flock_15_at_cap.json`) is how tests reach the
/// boundary.
const int kFreeEweCap = 15;

const int kFreeSeasonCount = 1;

/// Where the write is coming from.
///
/// [liveEntry] is the shed. Decision #91 makes it **structurally incapable** of
/// returning [BlockedByCap] — a parameter shape, not a later addition, which is
/// why this file exists eleven epics before it is wired.
enum EntryContext { liveEntry, calm }

enum RefusalReason { secondSeason, eweCap }

sealed class CapDecision {
  const CapDecision();
}

final class Allow extends CapDecision {
  const Allow({required this.overFreeCap});

  /// The row is real; the flag rides on it and clears on unlock. Nothing is
  /// withheld and nothing is deleted — the cap constrains the next write, never
  /// the existing records.
  final bool overFreeCap;
}

final class BlockedByCap extends CapDecision {
  const BlockedByCap(this.reason);

  final RefusalReason reason;
}

/// 22:00–06:00 local wall time.
///
/// **ONE predicate**, so the policy and the upgrade row cannot disagree about
/// when the app goes quiet.
bool isQuietHours(Instant now) {
  final int h = now.local.hour;
  return h >= 22 || h < 6;
}

/// Whether this write may proceed, and whether it is over the free tier.
///
/// **Nothing in this file knows what a purchase is.** [unlocked] is a `bool`
/// parameter — no `PurchaseService`, no `EntitlementRepository`, no
/// `ProductDetails`, no price. `layer.in_app_purchase` fires on any of those
/// tokens outside `lib/data/purchase_service.dart`, and the `net.*` rules fire
/// on anything that would reach a store.
///
/// **The cap is not a schema `CHECK`.** A `CHECK` would fire on a paying user
/// mid-lambing, and there would be no way to tell it apart from corruption.
///
/// **It is not a UI check either.** A UI check is one refactor away from being
/// bypassed and cannot be tested without pumping a widget. `createEwe` and
/// `startSeason` are the only two gated verbs; `beginLambing` and `addLamb` are
/// never gated, at any entitlement state.
///
/// **Export is never gated and nothing safety-related is ever gated** (11 §7.1).
/// Export is the only backup mechanism in an app with no cloud, and a withdrawal
/// period is §12.1 machinery. A `decide` call near either is a defect.
final class FreeTierPolicy {
  const FreeTierPolicy();

  /// [ewesInCurrentSeason] and [seasonCount] are the counts **as they would be
  /// after the write**. That is the contract, and getting it wrong is an
  /// off-by-one that either refuses ewe #15 or lets #16 through.
  ///
  /// [now] is a parameter because `package:clock` is banned in `lib/domain/`
  /// (D3, R24). The repository calls `appNow()` in `lib/data/` and passes the
  /// result in **inside the same transaction as the insert**, so the count
  /// cannot move between the decision and the write.
  ///
  /// **The five statements are in a fixed order and the order IS the policy.**
  CapDecision decide({
    required EntryContext context,
    required Instant now,
    required bool unlocked,
    required int ewesInCurrentSeason,
    required int seasonCount,
  }) {
    final bool overSeason = seasonCount > kFreeSeasonCount;
    final bool overEwes = ewesInCurrentSeason > kFreeEweCap;
    final bool over = !unlocked && (overSeason || overEwes);

    if (unlocked) {
      return const Allow(overFreeCap: false);
    }

    // The 3am floor, structural rather than promised: nothing monetization-
    // related can refuse a write in the shed, at any entitlement state, at any
    // hour, at any count.
    if (context == EntryContext.liveEntry) {
      return Allow(overFreeCap: over);
    }

    // And the app does not solicit at night, even in a calm context.
    if (isQuietHours(now)) {
      return Allow(overFreeCap: over);
    }

    // SEASON-PRIMARY: if both are over, the reason is secondSeason. The order of
    // these two `if`s is the ruling. A restored three-season backup therefore
    // refuses createEwe(context: calm) with secondSeason, which is the honest
    // shape of "the cap is never applied retroactively" — it constrains the next
    // write, never the existing records.
    if (overSeason) {
      return const BlockedByCap(RefusalReason.secondSeason);
    }
    if (overEwes) {
      return const BlockedByCap(RefusalReason.eweCap);
    }
    return const Allow(overFreeCap: false);
  }
}
