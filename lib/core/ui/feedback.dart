// lib/core/ui/feedback.dart
//
// P2: THERE IS NO FLOATING CONFIRMATION IN THIS APP, INCLUDING IN THIS FILE.
// The confirmation IS the committed row, in ink, one line above the one being
// written. `showShedReceipt` and `showShedFailure` are banned spellings (R30).
//
// CONVENTIONS §2.11 called this "the one file permitted to call the framework's
// transient-message API", and 06 §10.3 printed a body that did. Both are
// superseded and both are amended in this commit. (The API is described rather
// than named: `gesture.raw_snackbar` scans this file, which is the point.) P2 forbids the FALLBACK as well as the mechanism:
// 06 §10.3's "a house bar in an overlay" is out too, because a floating overlay
// is a toast with a different class name.
//
// A feedback function holds a BuildContext and nothing else (R30) — no
// WidgetRef, no provider read, no navigation. That constraint is what forces
// ShedReceiptScope to be an InheritedNotifier: `of(context)` is the only lookup
// this signature permits.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/motion.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/validation/warning.dart';

/// How long the strike affordance stays in the margin.
///
/// **THE NUMBER IS NOT RULED BY ANY DOCUMENT.** `07 §15.2` defined the window as
/// a widget lifetime and P2 abolished that definition without supplying a
/// replacement figure. 20 s is a proposal: long enough to notice a mis-pressed
/// slab with gloves on, short enough that it is gone before the next lamb. It is
/// carried into N14's pull request as a ruling, because it is a number a
/// shepherd READS ON SCREEN rather than an implementation detail.
///
/// **Measured in absolute time, never civil time.** It is a `Duration` compared
/// against instants, so a window opened at 01:59 on the clocks-back night lasts
/// 20 s and not 3600 — the same reasoning decision #3 applies to the withdrawal
/// clear date.
///
/// The copy and the timer must never disagree: the ARB message takes
/// `kStrikeWindow.inSeconds` as a placeholder, and the number is never typed
/// into copy.
const Duration kStrikeWindow = Duration(seconds: 20);

/// What a receipt says.
///
/// `at` is pre-formatted `HH:mm`, 24-hour, en_GB, by
/// `lib/core/ui/formatters.dart` — **never here**. One formatting authority,
/// not two.
///
/// `undoLabel` exists because the label is not always *UNDO*: it is
/// "Correct this" on a foster and "Void" on a treatment, and a receipt that
/// said UNDO for a voided treatment would promise a reversal the schema does
/// not do.
@immutable
final class SaveReceipt {
  const SaveReceipt({
    required this.term,
    required this.tag,
    required this.summary,
    required this.at,
    this.expiresAt,
    this.undo,
    this.undoLabel = 'UNDO',
  });

  final String term;
  final String tag;
  final String summary;
  final String at;

  /// When the strike affordance stops being offered — `now + kStrikeWindow`,
  /// stamped by the publisher.
  ///
  /// **THE WINDOW IS A FACT ABOUT THE RECEIPT, NOT ABOUT A WIDGET'S LIFETIME,
  /// AND THAT IS A CORRECTION.** Holding it as widget state meant the affordance
  /// re-armed whenever its `State` was recreated — MEASURED: the timer fired,
  /// the word disappeared, and a rebuild brought it straight back, so a window
  /// "stated in seconds" silently lasted as long as the shepherd kept the screen
  /// open. An absolute deadline recomputes to the same answer however many times
  /// the widget is rebuilt.
  ///
  /// `07 §15.2` still holds: no timer outlives the screen. The widget's timer
  /// only schedules a rebuild; it does not decide anything.
  final Instant? expiresAt;

  final VoidCallback? undo;
  final String undoLabel;

  /// Whether the strike word is still offered at [now].
  bool isOpenAt(Instant now) =>
      undo != null && expiresAt != null && now.epochMillis < expiresAt!.epochMillis;

  /// **The live-region label must differ every time or it does not
  /// re-announce.** A live region only speaks when its label CHANGES, so two
  /// identical saves in a row would announce once — and the second lamb would
  /// get silence. The time is what makes it differ, which is one more reason
  /// `at` is on the receipt rather than looked up at render.
  String get liveLabel => '$term $tag, $summary, $at';
}

/// The channel a receipt travels on now that there is no overlay.
///
/// An `InheritedNotifier` over a `ValueNotifier<SaveReceipt?>`, installed once
/// by the screen above its ledger. [confirmSaved] publishes; the receipt row
/// reads it to know which committed row is the live region and which row
/// currently carries the strike affordance (T05).
///
/// **It is an InheritedNotifier and not a provider on purpose**: a feedback
/// function has a `BuildContext` and no `WidgetRef` (R30).
final class ShedReceiptScope extends InheritedNotifier<ValueNotifier<SaveReceipt?>> {
  const ShedReceiptScope({required super.notifier, required super.child, super.key});

  static ValueNotifier<SaveReceipt?> of(BuildContext context) {
    final ShedReceiptScope? scope = context.dependOnInheritedWidgetOfExactType<ShedReceiptScope>();
    assert(scope != null, 'no ShedReceiptScope above this context');
    return scope!.notifier!;
  }

  /// Null when there is no scope — for the two feedback functions, which must
  /// never throw on a screen that has not installed one.
  static ValueNotifier<SaveReceipt?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShedReceiptScope>()?.notifier;
}

/// Three channels, and the row is the one still true five seconds later.
///
/// **The haptic fires on the transaction RETURNING, never on the tap**
/// (`06 §10.1`) — which is why this is called from `ref.listen` on `WriteDone`
/// and not from `onPressed`. A false receipt is worse than no receipt.
void confirmSaved(BuildContext context, SaveReceipt receipt, List<Warning> warnings) {
  hapticForWrite(
    warnings.isEmpty ? ShedWriteSignal.committed : ShedWriteSignal.committedWithWarnings,
  );
  ShedReceiptScope.maybeOf(context)?.value = receipt;
}

/// A failure is never silence: the record did not land and the app must say so.
///
/// It prints the message as a ruled line in the same column — never a dialog,
/// never a toast.
///
/// **IT TAKES THE MESSAGE, NOT THE `ShedFailure`, AND THE LAYER TABLE IS WHY.**
/// R30 and N14-T04 §5.2 both print `showFailure(BuildContext, ShedFailure)`,
/// but `ShedFailure` lives in `lib/core/` and `_mayImport['lib/core/ui/']` is
/// `{lib/core/ui/, lib/domain/}` — so this file cannot name the type. The gate
/// is right and the printed signature is not: a shared-tier renderer should
/// take the words it is handed rather than interpret a failure type, which is
/// the same correction `ShedKeypad`'s four label parameters made at N13-T04.
///
/// The caller reads `.userMessage` — the six strings live on the failure types
/// and are the only user-facing text outside the ARB in v1 (`CONVENTIONS §1`).
/// The alternative was a second R80-style amendment admitting `lib/core/` to
/// `lib/core/ui/`, which would open the whole tier to reach for anything.
void showFailure(BuildContext context, String userMessage) {
  // `ShedWriteSignal.refused` is the enum member for a returned WriteFailed —
  // N09's naming, and it reads oddly here because "refused" in the vocabulary
  // means the free-tier decline (WriteRefused). The signal enum predates that
  // distinction; renaming it is a CONVENTIONS §6 ruling, not an edit, so it is
  // used as spelled and flagged rather than quietly changed.
  hapticForWrite(ShedWriteSignal.refused);
  ShedReceiptScope.maybeOf(context)?.value = SaveReceipt(
    term: '',
    tag: '',
    summary: userMessage,
    at: '',
    undoLabel: '',
  );
}

/// **No haptic, deliberately** (`06 §10.1`). A refusal is not a failure
/// (decision #91) and buzzing at somebody for hitting a commercial boundary is
/// the app taking a side.
///
/// **THE REFUSAL RENDERS IN PLACE AND THE APP NEVER NAVIGATES ON ITS OWN.**
/// `11 §8` constraint 4 allows one self-navigation — to Settings ▸ Unlock, after
/// a user-initiated calm tap — rate-limited to once a civil day by
/// `app_settings.last_unlock_prompted_at`. **That column does not exist**:
/// `11 §2` flagged it as needing to land before the first schema snapshot, no
/// task in N00–N29 added it, and N07-T08 froze `v1` without it.
///
/// **Ruled at N30-T05 (decision-record §7.0e): ship without the
/// self-navigation.** The refusal is a row where the shepherd already is. A
/// migration is the one change this project cannot undo on somebody else's
/// phone, and the thing it would buy is the closest thing in the whole design to
/// an interruption — #92 bans the modal, the interstitial, the self-appearing
/// sheet and the timed prompt, and a screen that moves under you on a refusal is
/// the same family. The rest of constraint 4 is unaffected: a **user-initiated**
/// tap on an upgrade row was never rate-limited, and the rule cannot fire in the
/// quiet window because nothing is refused there.
///
/// **No haptic** (`06 §10.1`), no dialog, no snackbar (P2), no navigation.
/// **`copyFor` IS A PARAMETER BECAUSE `lib/core/ui/` MAY NOT RESOLVE COPY**
/// (layer rule 7: it cannot import `lib/l10n/` or `lib/data/`). It is the same
/// shape `ShedKeypad` and `ShedTapTarget` already use — a component in the
/// shared tier renders what it is handed, and the screen that knows the locale
/// and the shepherd's own noun for their animals is the screen that supplies the
/// words. R30 fixes the first three parameters; this is the fourth, and it is
/// the only way the function can render a `RefusalReason` at all.
/// **`now` IS A PARAMETER FOR THE SAME REASON `copyFor` IS.** `lib/core/ui/` may
/// not import `lib/core/` (layer rule 7), so it cannot call `appNow()` — and
/// `ShedBanner` already takes its instant the same way, which is what makes the
/// quiet-hours rule testable at 21:59 and 22:00 without waiting for either.
void showCapRow(
  BuildContext context,
  RefusalReason reason, {
  required bool onShedScreen,
  required Instant now,
  required String Function(RefusalReason) copyFor,
}) {
  // NEVER ON A SHED SCREEN, at any entitlement state (decision #90), and NEVER
  // between 22:00 and 06:00 (§7.0 ruling 8). Both guards are here rather than at
  // the call sites, because a guard at a call site is a guard somebody forgets
  // at the thirteenth call site.
  if (onShedScreen || isQuietHours(now)) {
    return;
  }

  // **THE SAME CHANNEL A COMMITTED ROW USES, AND THAT IS THE POINT.** P2: the
  // confirmation is the committed row, in ink, one line above the one being
  // written — so a refusal is a line in the same place, in the same ink. It is
  // not an overlay, it cannot scroll away from what caused it, and there is
  // nothing to dismiss.
  //
  // **THE CAP IS A PLACEHOLDER, NEVER A TYPED NUMBER.** `kFreeEweCap` is the
  // source; a literal here goes stale the day it moves, in the one sentence a
  // paying user reads most carefully.
  ShedReceiptScope.maybeOf(context)?.value = SaveReceipt(
    term: '',
    tag: '',
    summary: copyFor(reason),
    at: '',
    undoLabel: '',
  );
}
