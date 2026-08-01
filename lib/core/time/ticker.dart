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
final AutoDisposeStreamProvider<Instant> minuteTickProvider = StreamProvider.autoDispose<Instant>((
  ref,
) async* {
  while (true) {
    final Instant now = appNow(); // the ONE wall-clock reader (R23)
    yield now;
    final int msToNextMinute = 60000 - (now.epochMillis % 60000);
    await Future<void>.delayed(Duration(milliseconds: msToNextMinute));
  }
});
