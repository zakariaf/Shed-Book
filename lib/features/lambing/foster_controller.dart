// lib/features/lambing/foster_controller.dart
//
// SCREEN STATE ONLY — the typed digits and nothing else. No `BuildContext`, no
// drift, no navigation. The match list is computed from the deck the screen
// already watches; a controller that held it would be a second source of truth
// about what is on the page.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
