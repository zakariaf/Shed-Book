// lib/core/time/ticker.dart
//
// A single heartbeat for every time-relative display in the app (#66,
// CONVENTIONS §3.3, R25). Aligned to the wall-clock minute so every pen tile
// updates in the SAME frame — a grid whose cells change at different moments
// reads as noise under a head torch.
//
// It yields `Instant`, never a raw `DateTime` (R25). `minuteTickerProvider` and
// `penTickProvider` are banned spellings.
//
// Consumers: the pen board (07 §9), the withdrawal countdown (07 §10) and the
// Reminders day boundaries (07 §11.1). All three take `now` as a PARAMETER and
// none of them reads a clock (R24).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/instant.dart';

/// The one ticker.
///
/// **`.autoDispose` is load-bearing, not tidiness** (`02 §4.2`, `07 §9.2`): a
/// plain `StreamProvider` stays subscribed for the life of the `ProviderScope`,
/// so this loop would wake the process every 60 s all night with no pen board on
/// screen — on a phone in a coat pocket, in a shed, on battery.
///
/// **The first emission is immediate.** A tile that stayed blank for up to 60 s
/// after the board opened would be a tile nobody trusts.
///
/// The delay is computed from the CURRENT instant rather than fixed at 60 s, so
/// a subscription at :17 lands the second emission on the boundary and every one
/// after it stays aligned. `epochMillis % 60000` is zone-independent: every IANA
/// offset is a whole number of minutes, so the local minute boundary and the UTC
/// one are the same instant.
/// ---------------------------------------------------------------------------
/// THE CANCELLATION SEAM — AMENDED 2026-08-02, AND A MEASUREMENT FORCED IT
/// ---------------------------------------------------------------------------
///
/// `01 §7.2` prints this loop with a bare `await Future<void>.delayed(...)`, and
/// `07 §9.2` ACCEPTS the tail that leaves: *"after the last listener goes the
/// pending `Future.delayed` still completes — up to 60 s of tail. That is one
/// wake-up, once, and it is cheaper than the `StreamController` plumbing that
/// would avoid it."*
///
/// **That ruling priced the runtime cost and not the test cost, and the test
/// cost is total.** A `Future.delayed` cannot be cancelled, so any screen
/// watching this provider leaves a timer outstanding and `flutter_test` fails
/// the test on it — with a message that names the binding rather than the
/// screen. (The message is described rather than quoted: `copy.banned_word`
/// scans this file and the word the framework uses is one of the nine.)
/// MEASURED at N13-T06,
/// where it made the Quick Entry screen untestable through `pumpApp`; from N19
/// onward that is most screens in the app.
///
/// Four ways of draining it in the harness were tried and none works: pumping
/// inline (the loop re-arms on every yield), unmounting first
/// (`UncontrolledProviderScope` does not own the container, so an autoDispose
/// provider is not disposed while the container lives), repeated long pumps, and
/// registering the drain so LIFO runs it after `container.dispose`.
///
/// **A one-shot `Timer` cancelled in `ref.onDispose` is the smallest fix that
/// works.** It is materially less than the `StreamController` plumbing §9.2
/// rejected — four lines, no controller, no subscription bookkeeping — and it is
/// what `Future.delayed` is built on anyway, with the handle kept instead of
/// thrown away. `Timer.periodic` remains banned (`net.sync_timer`) and unused:
/// this is a fresh one-shot per iteration, so the boundary alignment is
/// recomputed every time and a late wake-up self-corrects rather than
/// accumulating drift.
///
/// When disposal happens mid-wait the completer is never completed and the
/// generator simply stays suspended with no timer behind it, which is exactly
/// the state the test binding is asking for.
final AutoDisposeStreamProvider<Instant> minuteTickProvider = StreamProvider.autoDispose<Instant>((
  ref,
) async* {
  Timer? wake;
  ref.onDispose(() => wake?.cancel());

  while (true) {
    final Instant now = appNow(); // the ONE wall-clock reader (R23)
    yield now;
    final int msToNextMinute = 60000 - (now.epochMillis % 60000);

    final Completer<void> boundary = Completer<void>();
    wake = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!boundary.isCompleted) {
        boundary.complete();
      }
    });
    await boundary.future;
  }
});
