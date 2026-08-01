/// The sixteen entity ids, and nothing else (R5).
///
/// R33: a bare `int` never crosses a repository, controller, route-helper or
/// provider-family boundary. The way that rule gets broken is a repository
/// written against an id type nobody created, so all sixteen exist here even
/// though sixteen tables do not exist until N07 — which makes the violation a
/// compile error rather than a habit.
///
/// **They erase at run time**, and the boundary is not quite where 05 §2.3's
/// summary puts it. Measured on Dart 3.12.2 while `test/domain/ids_test.dart`
/// was written:
///
///   - The compiler **does** refuse to widen one to `Object`, because these
///     declare no `implements`. `Map<Object, String>{EweId(3): …}` is a compile
///     error, so the most obvious form of *"key one Map with two id types"*
///     cannot be written at all.
///   - Everything reached through `dynamic` sees a bare `int`. `runtimeType` is
///     `int`, `EweId(3) == LambId(3)` is `true`, `d is EweId` is `true` for a
///     plain `3`, and a `Map<dynamic, …>` keyed by an `EweId` is hit by a
///     `LambId` and by `3`.
///
/// So: never `is`-check an id, never serialise one expecting the type to
/// survive, and treat any `dynamic` boundary as the point the type stops
/// existing. The separation is real at compile time, which is the whole benefit.
///
/// **No `implements Comparable`.** `extension type EweId(int value) implements
/// Comparable<EweId>` fails with `extension_type_implements_not_supertype`,
/// because `int` implements `Comparable<num>`. If ids need sorting, sort on
/// `.value`. 05 §2.3 documents the same wall for `Instant`.
///
/// **No `package:uuid` here.** `String newUid()` is `lib/core/db/uid.dart`'s, and
/// `lib/domain/` may not import that package (R15, layer rule 1). Anything you
/// are tempted to put beside these — a uid generator, a `parseId`, a `toJson` —
/// belongs elsewhere.
library;

// The empty braces are required: a trailing `;` in place of the body does not
// compile. The representation getter is always `.value` (R5).
extension type const EweId(int value) {}

extension type const EweSeasonId(int value) {}

extension type const LambingId(int value) {}

extension type const LambId(int value) {}

extension type const FosterEventId(int value) {}

extension type const CareEventId(int value) {}

extension type const EweObservationId(int value) {}

extension type const PenId(int value) {}

extension type const PenOccupancyId(int value) {}

extension type const TreatmentId(int value) {}

extension type const TreatmentWithdrawalId(int value) {}

extension type const ReminderId(int value) {}

extension type const NoteId(int value) {}

extension type const MediaAssetId(int value) {}

extension type const SeasonId(int value) {}

extension type const VocabTermId(int value) {}
