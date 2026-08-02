// lib/features/lambing/lamb_card_controller.dart
//
// ONE READ. `07 §7.1` fixes the Lamb Card's dependency set at a single
// statement, and this file is where that is spent — no drift import, no SQL, no
// BuildContext.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// **`.family` on a `LambId`** — the card is opened for one lamb and the id
/// arrives through the route rather than through state.
///
/// **`.autoDispose`**, for the same reason as Lambing Entry: the shepherd opens
/// a lamb, reads it and leaves. A subscription that outlived the screen would
/// keep a statement live on a phone in a pocket.
final AutoDisposeStreamProviderFamily<LambCardData, LambId> lambCardProvider = StreamProvider
    .autoDispose
    .family<LambCardData, LambId>((ref, LambId id) async* {
      // Awaited FIRST so `lambingRepositoryProvider`'s read is safe: the first
      // frame paints before the database opens.
      await ref.watch(databaseProvider.future);
      yield* ref.watch(lambingRepositoryProvider).watchLambCard(id);
    });
