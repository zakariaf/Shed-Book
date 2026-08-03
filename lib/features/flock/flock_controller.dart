// lib/features/flock/flock_controller.dart
//
// ONE STATEMENT PRODUCES THE LIST (`07 §1.2`), and the filters narrow it in SQL
// rather than in Dart. A `.where` over the streamed rows would look identical on
// a six-ewe test database and read all four hundred rows off the disk on a real
// one — which is the difference the fixture exists to expose.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';

export 'package:shed_book/data/flock_repository.dart' show FlockFilters, FlockRow;

/// Which of `spec §7.7`'s five filters are on. **Screen state**, not persisted:
/// a filter a shepherd left on last night is a filter that hides animals from
/// them tonight without saying why.
final class FlockFilterController extends AutoDisposeNotifier<FlockFilters> {
  @override
  FlockFilters build() => const FlockFilters();

  void set(FlockFilters filters) => state = filters;

  void clear() => state = const FlockFilters();
}

final AutoDisposeNotifierProvider<FlockFilterController, FlockFilters> flockFilterProvider =
    NotifierProvider.autoDispose<FlockFilterController, FlockFilters>(FlockFilterController.new);

/// The list.
///
/// **`keepAlive`, per `CONVENTIONS §3.2`** — Flock is a hub read (`02 §4.2`), so
/// it survives a push to a ewe card and back rather than re-running its
/// statement over four hundred rows every time a shepherd looks at one animal.
///
/// **`.family` on the filters** rather than reading `flockFilterProvider` inside:
/// ticking a filter becomes a new subscription with its own statement, instead of
/// a re-run of one that was watching the previous set.
final StreamProviderFamily<List<FlockRow>, FlockFilters> flockListProvider =
    StreamProvider.family<List<FlockRow>, FlockFilters>((ref, FlockFilters filters) async* {
      // **ONE STREAM. NO `rxdart`, AND NOTHING THAT MERGES TWO OF THEM**
      // (decision #12, `02 §4.1`). Two streams updated in one transaction can
      // emit at different times, so a merged view shows a state that never
      // existed in the database — drift#3338, which its maintainer calls working
      // as intended.
      //
      // The banned operator is deliberately not spelled here: `stream.combine`
      // scans source text, COMMENTS INCLUDED, and failed the build on the draft
      // of this paragraph that named it. The draft after that cited
      // `media_sweeper_test.dart`'s split clock literal by name and tripped
      // `time.dart_clock` the same way. Two rules, two comments, both of them
      // mine — the gate does not read intent, and that is the point of it.
      yield* watchFlockList(await ref.watch(databaseProvider.future), filters);
    });
