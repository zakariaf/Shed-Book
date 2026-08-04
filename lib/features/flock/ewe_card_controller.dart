// lib/features/flock/ewe_card_controller.dart
//
// **THE RETENTION FEATURE.** In year two, *"what did 412 do last year?"* takes
// one second instead of an evening with a shoebox — and `00-README` §9 says out
// loud that this is the one calm screen that is not filler.
//
// `CONVENTIONS §3.2` types `eweTimelineProvider` on `List<TimelineRow>` and no
// document declares that class's fields; `07 §4.1` fixes the seven **columns**.
// This file is the Dart shape, and every later task in the epic renders whatever
// is decided here.
//
// **THE STATEMENT IS NOT HERE AND CANNOT BE.** Layer rule 5 bans
// `package:drift/*` and `lib/core/db/` from `lib/features/` outright, and
// `customSelect` is a drift API — so the SQL lives in `FlockRepository` and the
// provider lives here. Same split `02 §5.1` prints for the pen board.
//
// **`02 §3.1`'s `EweCardController` / `EweCardData` snippet is not this screen's
// architecture.** It exists to print the corrected 2.6.1 family shape after the
// research notes got it wrong, and it calls `repo.eweCard(arg)` — a method
// `CONVENTIONS §2.13` does not declare. Copying it would put DATA in a screen
// controller, which `§4.4` rule 1 forbids outright.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// **THE TWO TYPES LIVE IN THE REPOSITORY, RE-EXPORTED HERE.** `CONVENTIONS §3.2`
/// puts `eweTimelineProvider` in this file and the task text drafts the classes
/// beside it — but `layer.data` forbids `lib/data/` from naming a screen, so a
/// repository method returning a type declared under `lib/features/` does not
/// build. `FlockRow` already sits on the other side of that seam for the same
/// reason, and the export is what makes the split invisible to a screen.
export 'package:shed_book/data/flock_repository.dart' show TimelineKind, TimelineRow;

/// Her whole history, one statement, most recent first.
///
/// **`.autoDispose.family`, both of them** (`CONVENTIONS §3.2`, §3.4), and the
/// reason is arithmetic: a `keepAlive` family holds one live stream per ewe
/// opened — four hundred of them by the end of a night. `EweId` is an extension
/// type over `int` with real `==`, so the family key does not mint a new
/// provider per rebuild (R33).
final AutoDisposeStreamProviderFamily<List<TimelineRow>, EweId> eweTimelineProvider = StreamProvider
    .autoDispose
    .family<List<TimelineRow>, EweId>((ref, EweId eweId) async* {
      // **THE DATABASE IS AWAITED FIRST, AND IT IS NOT CEREMONY.**
      // `flockRepositoryProvider` reads `requireValue` on `databaseProvider`, so
      // reading it before the database has opened throws — and on a
      // `StreamProvider` a throw is an `AsyncError`, which renders the error
      // panel on the first frame of a card that is about to work perfectly well.
      // Awaiting the future is what makes the loading arm mean *loading*.
      await ref.watch(databaseProvider.future);
      yield* ref.read(flockRepositoryProvider).watchEweTimeline(eweId);
    });
