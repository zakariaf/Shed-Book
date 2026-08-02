// lib/features/lambing/foster_controller.dart
//
// SCREEN STATE ONLY — the typed digits and nothing else. No `BuildContext`, no
// drift, no navigation. The match list is computed from the deck the screen
// already watches; a controller that held it would be a second source of truth
// about what is on the page.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// What the shepherd has typed so far.
final class FosterState {
  const FosterState({this.query = ''});

  /// Digits only. **Never a tag** — a tag is what a ewe wears and this is a
  /// prefix being matched against several.
  final String query;
}

/// **`.family` on the LAMB**, because the screen is opened for one lamb and the
/// id arrives through the route. **`.autoDispose`**, because the shepherd
/// fosters and leaves — the typed digits must not survive into the next lamb.
final class FosterController extends AutoDisposeFamilyNotifier<FosterState, LambId> {
  @override
  FosterState build(LambId arg) => const FosterState();

  void digit(String d) => state = FosterState(query: state.query + d);

  void backspace() => state = FosterState(
    query: state.query.isEmpty ? '' : state.query.substring(0, state.query.length - 1),
  );
}

final AutoDisposeNotifierProviderFamily<FosterController, FosterState, LambId>
fosterControllerProvider = NotifierProvider.autoDispose
    .family<FosterController, FosterState, LambId>(FosterController.new);

/// The lamb's current rearing dam, watched.
///
/// **A SINGLE-ROW LOOKUP beside the deck** (`07 §1.2`). The screen needs it for
/// exactly one thing: `fosterToSelf` compares the TARGET against the CURRENT
/// rearing dam, never against the birth dam — and on an un-fostered lamb those
/// two are the same ewe by arm 1 of `lamb_rearing`, which is the common case at
/// 3am and the reason the comparison has to be written the right way round.
final AutoDisposeStreamProviderFamily<EweId?, LambId> lambRearingDamProvider = StreamProvider
    .autoDispose
    .family<EweId?, LambId>((ref, LambId lamb) async* {
      await ref.watch(databaseProvider.future);
      yield* ref.watch(fosterRepositoryProvider).watchRearingDam(lamb);
    });
