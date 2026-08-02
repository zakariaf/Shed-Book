// lib/data/lambing_repository.dart
//
// beginLambing and nothing else. addLamb, setEase, addCare, removeCare and
// correctOccurredAt are N16's and N17's.
//
// `setBirthType` IS IN CONVENTIONS §2.13 AND IS NOT BUILT HERE. P8 abolished the
// birth-type chooser: birth type is DERIVED from the tally strokes and labelled
// (COUNTED). The column still has a writer — the deferred CHANGE TYPE path in
// N16 — but nothing on the five-tap path ever declares one.
import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class LambingRepository {
  /// `db:` is the name `CONVENTIONS §2.13` prints. The initializing-formal lint
  /// is suppressed rather than obeyed for the same reason as in
  /// `FlockRepository`: `this._db` would make the PUBLIC parameter name `_db`,
  /// so every caller would be writing a private name.
  // ignore_for_file: prefer_initializing_formals
  LambingRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Called by the Quick Entry "Lambing" tap, **before Lambing Entry is
  /// pushed**. The row exists from this moment; there is no draft and nothing to
  /// lose if the phone dies.
  ///
  /// **Returns the id and THROWS** (R32 — this and `addLamb` are the only two
  /// verbs in the app that do). There is no id to hand back on failure and the
  /// screen cannot open, so the global error net (`01 §5.5`) is the right
  /// handler. Never gated by the free tier, at any entitlement state.
  Future<LambingId> beginLambing(EweId ewe) {
    final Instant now = appNow(); // ONE instant per mutation
    final RecordedTime when = RecordedTime.capture(now); // spec §12.5 provenance

    return _db.transaction(() async {
      final SeasonId season = await _currentSeason();

      final int id = await _db
          .into(_db.lambings)
          .insert(
            LambingsCompanion.insert(
              uid: newUid(), // export identity — #32, R15
              createdAt: now,
              updatedAt: now,
              ewe: ewe.value,
              season: season.value,
              // THREE TIME COLUMNS, THREE MEANINGS, ONE `now`. occurred_at is
              // when the thing happened; captured_at is when we wrote it down;
              // local_date is the shepherd's civil day, derived in DART because
              // SQLite cannot bucket by a local civil day without a tz database.
              // A local_date read from a second clock is how the lambing-spread
              // histogram acquires a one-row-off bug nobody sees until the
              // season summary.
              occurredAt: when.effective,
              capturedAt: when.capturedAt,
              // The FROZEN WIRE KEY, never the enum's `name` and never
              // localised: the CHECK is time_source IN ('auto','entered','edited').
              timeSource: Value<String>(when.source.key),
              localDate: LocalDate.of(when.effective),
              // `absent`, NOT `Value(null)`, and the difference is the whole
              // reason R6 exists: absent omits the column so SQLite applies its
              // own rules, while Value(null) writes an explicit NULL. Both land
              // on NULL here — but with Value(null) the next reviewer cannot
              // tell whether the column is nullable by design or by accident.
              declaredBirthType: const Value<int?>.absent(),
            ),
          );

      // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
      await _db
          .into(_db.eweTouches)
          .insertOnConflictUpdate(
            EweTouchesCompanion.insert(ewe: Value<int>(ewe.value), touchedAt: now),
          );

      // N24-T04 writes the colostrum and navel reminder ROWS here, inside this
      // same transaction (decision #63). The OS projection is reconciled AFTER
      // the transaction returns, never inside it — a platform channel round
      // trips through another isolate while holding the write lock.

      return LambingId(id);
    });
  }

  /// **Never creates a season.** A verb that invented one would give the
  /// shepherd a season they did not start, on the 3am path, silently — and the
  /// season is the unit the whole free tier is priced on.
  Future<SeasonId> _currentSeason() async {
    final AppSetting settings = await _db.select(_db.appSettings).getSingle();
    final int? current = settings.currentSeason;
    if (current == null) {
      throw StateError('no current season — Quick Entry must not offer a lambing without one');
    }
    return SeasonId(current);
  }
}
