// lib/data/recorded_time_columns.dart
//
// THE READ PATH'S MISSING HALF. `RecordedTime` has a private generative
// constructor and three public entry points — capture, entered, editedTo — and
// no way back from storage. Every write path in the app can produce one; until
// this file, no read path could.
//
// IT LIVES IN lib/data/ AND NOT ON THE DOMAIN TYPE, deliberately. A
// `RecordedTime.fromColumns(effective, capturedAt, originalEffective, sourceKey)`
// would be a FOURTH entry point taking four loose values, and it would accept
// combinations the schema makes unstorable — `'auto'` beside a non-null
// original_effective, or `'edited'` with a null one. The paired CHECK
//
//     CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))
//
// is what keeps those unrepresentable in the database, and a permissive factory
// would let them back in through Dart. Reconstructing through the SAME public
// factories the write path used means the type can only be rebuilt into a state
// it could have reached.
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

/// Rebuilds the §12.5 quad from the four columns that store it.
///
/// **Exact, and it uses only public factories:**
///
///   * `'auto'`    — `capture(effective)`. `captured_at` equals `effective` by
///     construction on this arm, which is what "auto" means.
///   * `'entered'` — `entered(effective:, now: capturedAt)`. The user typed a
///     time at creation; it was never wrong, which is why this is a different
///     fact from an edit and the two must not be merged.
///   * `'edited'`  — the ORIGINAL is replayed first and then edited to the
///     current value, so `originalEffective` lands through `editedTo`'s own
///     `??` rather than being assigned. That is the one path that preserves
///     *what it was edited from* across an unbounded chain.
///
/// Throws on a combination the schema forbids, rather than repairing it: a row
/// that says `'edited'` with no original is a row that lost its history, and
/// silently substituting one would be the app inventing provenance.
RecordedTime recordedTimeFromColumns({
  required Instant effective,
  required Instant capturedAt,
  required Instant? originalEffective,
  required String sourceKey,
}) {
  final TimeSource source = TimeSource.fromKey(sourceKey);

  return switch (source) {
    TimeSource.autoCaptured => RecordedTime.capture(effective),
    TimeSource.userEntered => RecordedTime.entered(effective: effective, now: capturedAt),
    TimeSource.userEdited => () {
      if (originalEffective == null) {
        throw const FormatException(
          "a row marked 'edited' with no original_effective has lost its history",
        );
      }
      return RecordedTime.entered(
        effective: originalEffective,
        now: capturedAt,
      ).editedTo(effective);
    }(),
  };
}
