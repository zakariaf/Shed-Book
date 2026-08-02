// lib/features/lambing/lambing_entry_controller.dart
//
// ONE PROVIDER TODAY, and the emptiness is deliberate.
// `lambingEntryControllerProvider` (screen state) and
// `lambingWriteControllerProvider` arrive in T02, when there is state to hold
// and a write to guard. Declaring them now would be declaring two providers
// nobody reads.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// The screen's one read.
///
/// **`.family` on a `LambingId`**, because the screen is opened for one lambing
/// and the id arrives through the route rather than through state.
///
/// **`.autoDispose`**, because unlike Quick Entry's deck this is not a hub: the
/// shepherd opens a lambing, fills it in and leaves, and a subscription that
/// outlived the screen would keep a statement live on a phone in a pocket.
final AutoDisposeStreamProviderFamily<LambingEntryData, LambingId> lambingEntryProvider =
    StreamProvider.autoDispose.family<LambingEntryData, LambingId>((ref, LambingId id) async* {
      await ref.watch(databaseProvider.future);
      yield* ref.watch(lambingRepositoryProvider).watchLambingEntry(id);
    });
