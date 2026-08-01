// lib/core/write_action.dart — CONVENTIONS §1, §2.4 (R72). See 02 §4.6 and §7.
//
// THE FILE NAME STAYS `write_action.dart` THOUGH THE CLASS IS `WriteController`.
// R72 fixes the path; CONVENTIONS §3.4 fixes the class name. Renaming either to
// match the other is a rename in twelve write controllers.
//
// The imports are `package:` rather than the relative ones 02 §7 prints:
// `always_use_package_imports` is on in analysis_options.yaml, so the printed
// form is an analyzer error here. Nothing else about the class is changed.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/failure.dart'; // sealed ShedFailure  — N11-T01
import 'package:shed_book/core/write_outcome.dart'; // sealed WriteOutcome — N11-T01

sealed class WriteState {
  const WriteState();
}

final class WriteIdle extends WriteState {
  const WriteIdle();
}

/// **Disables nothing visually** (decision #103, `02 §7.1` rule 2). A greyed-out
/// button at 3am reads as a broken app. This file exposes the state; what a
/// screen does with it is the screen's decision, and for the five shed screens
/// the answer is *nothing*.
final class WriteRunning extends WriteState {
  const WriteRunning();
}

/// Deliberately has NO `==`. Two identical outcomes in a row must still fire
/// `ref.listen`, because each completed write owes the user its own haptic, its
/// own confirmation and its own uniquely-labelled live region (decision #103).
final class WriteDone extends WriteState {
  const WriteDone(this.outcome);
  final WriteOutcome outcome;
}

/// The base every write controller in the app extends. **Every write the
/// shepherd makes goes through [guard]**, which refuses to run concurrently —
/// the double-tap defence, and a UX safety feature wearing architecture's
/// clothes: a cold thumb on capacitive glass through a bag double-fires, and
/// without this the second fire is a second lambing record.
///
/// THE SHAPE EVERY SCREEN EPIC COPIES, so N14 onward copies rather than invents:
///
/// ```dart
/// final class QuickEntryWriteController extends WriteController {
///   Future<void> beginLambing(EweId ewe) =>
///       guard(() => ref.read(lambingRepositoryProvider).beginLambing(ewe));
/// }
///
/// final quickEntryWriteControllerProvider =
///     NotifierProvider.autoDispose<QuickEntryWriteController, WriteState>(
///       QuickEntryWriteController.new,
///     );
/// ```
///
/// Four things about that shape are load-bearing. The subclass is a
/// `final class`. The verb is an **event verb** returning `Future<void>` — the
/// outcome arrives as state, never as a return value. The provider is always
/// `.autoDispose` (`02 §4.2`, `CONVENTIONS §3.4`). And **all** awaited work sits
/// inside the closure handed to [guard], never ahead of the call.
///
/// There is no `commit()`, no `submit()`, no `save()`, no `isDirty` and no draft
/// object here or anywhere downstream (`CONVENTIONS §5.3`). The row is created on
/// screen entry and every field after it is its own committed write.
///
/// `base` because Dart requires every subtype of a `base` class to be `base`,
/// `final` or `sealed` — every subclass in this project is a `final class`.
/// Writing `abstract class` instead would compile today and let a screen epic
/// write `implements WriteController`, giving it a [guard] that guards nothing.
abstract base class WriteController extends AutoDisposeNotifier<WriteState> {
  bool _disposed = false;

  /// Must not `ref.watch` anything. A write controller has no data
  /// dependencies, so `build()` runs exactly once per mount.
  ///
  /// If it watched something it would re-run when that thing changed — and
  /// 2.6.1 preserves the notifier instance across a re-run (`02 §3`), so
  /// `_disposed = false` would execute mid-flight while `state` reset to
  /// [WriteIdle]. The in-flight write would then land in a controller that
  /// thinks it is idle, and the next tap would start a second one.
  @override
  WriteState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const WriteIdle();
  }

  /// Runs [action] unless a write is already running.
  ///
  /// **Prevents concurrency, not repetition** (`02 §7.1` rule 1). Once the first
  /// write returns, a second tap is a second write — and for "add lamb" that is
  /// correct. Where an action must not repeat *after* completion, the repository
  /// makes it idempotent; a cooldown here would drop a legitimate second lamb.
  ///
  /// **The refusal is a return**, not a throw and not a queue: the second call
  /// completes its `Future<void>` immediately having done nothing. It is never a
  /// `WriteRefused` — that variant means the free-tier policy declined a calm-UI
  /// action (decision #91) and it comes from a repository. Rendering a double tap
  /// as a refusal would tell a shepherd their record did not save when it did.
  @protected
  Future<void> guard(Future<WriteOutcome> Function() action) async {
    // The double-tap gate. This assignment MUST happen synchronously, before
    // the first await, or the second tap of a double-fire slips through.
    if (state is WriteRunning) return;
    state = const WriteRunning();

    WriteOutcome outcome;
    try {
      outcome = await action();
    } on Object catch (e, s) {
      // Repositories map their own expected failures and return WriteFailed
      // (01 §5.4), so anything reaching here is a bug — a bad cast, a null id,
      // a closure that throws before the transaction. It must still surface as
      // a failure. It must never surface as silence.
      //
      // `on Object`, because an Error is precisely the case `on Exception` would
      // let through. One of R8's two construction sites; the other is
      // shedFailureFrom, one layer out, which is where a SqliteException is
      // translated — lib/core/ cannot reach lib/data/ to do it here.
      outcome = WriteFailed(UnexpectedFailure(e, s));
    }

    // The screen may have been popped while the transaction ran. The write
    // itself completed — drift does not care that the provider is gone — but a
    // disposed controller must not go on mutating its own state. 2.6.1 has no
    // `Ref.mounted` (02 §2.1), which is why `_disposed` exists at all.
    //
    // ONE CORRECTION TO 02 §7's PRINTED COMMENT, MEASURED ON THIS PIN: assigning
    // `state` after disposal does NOT throw on flutter_riverpod 2.6.1 — the
    // element swallows it. So the guard is not crash protection here; what it
    // buys is that the stale notifier stops at WriteRunning instead of reporting
    // a Done nobody is listening for, and that the day the pin moves to a
    // version which does throw, this file is already correct. The test asserts
    // both halves through the notifier's own `state`, because the container is
    // gone by then and reading through it would just build a fresh controller.
    if (_disposed) return;
    state = WriteDone(outcome);
  }
}
