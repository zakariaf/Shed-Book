// The complete shape of one event verb. Copy the SHAPE, not the file — the real
// file is lib/data/foster_repository.dart and CONVENTIONS.md §2.13 owns the
// signature. Every line below exists to demonstrate a rule; nothing is filler.

import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/db/uid.dart'; // newUid() — the one package:uuid call site (R15)
import '../core/log/local_log.dart'; // local file sink. Never a network sink.
import '../core/time/app_clock.dart'; // appNow() — the one wall-clock reader (R23)
import '../core/write_outcome.dart';
import '../domain/foster_outcome.dart'; // sealed: ToEwe / ToBottle / RemovedUnknown (R64)
import '../domain/ids.dart';
import '../domain/time/recorded_time.dart';
import 'failure_mapping.dart';

// NO import of '../domain/validation/…'. lib/data/ may never import
// lib/domain/validation/ (rule layer.data_no_validation, R53). It is the
// structural mechanism behind spec §12.4: a repository that cannot see a
// Warning cannot invent one. The controller produces warnings, not this file.

/// Concrete `final class`, no interface, flat in `lib/data/`, takes an
/// `AppDatabase` and (where relevant) gateways — never a `Clock` (R18, R19).
final class FosterRepository {
  FosterRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Records one graft as a complete, committed fact. Append-only: nothing is
  /// ever deleted from `foster_events`, and a correction is a compensating
  /// event whose `corrects` FK names the one it reverses — those semantics
  /// belong to shed-screens-and-routing, not here.
  ///
  /// The outcome is carried by a sealed type, never a nullable ewe id:
  /// "bottle" (null by intent) and "not recorded" (null by omission) are
  /// different facts and the rearing-credit numbers differ.
  Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome) {
    // 1. ONE instant for the whole mutation. Two rows must not disagree by a
    //    millisecond. Never `clock.now()`, never `DateTime.now()`.
    final now = appNow();

    // 2. The §12.5 provenance quad, captured once. `effective`, `capturedAt`,
    //    `originalEffective`, `source` travel together onto four columns.
    final when = RecordedTime.capture(now);

    // 3. Media, if any, is written BEFORE this call and outside the
    //    transaction: an orphaned file is garbage a sweep collects, an
    //    orphaned row is a broken record.

    return _write(() async {
      // 4. All SQL, and only SQL, inside the one transaction. Every statement
      //    is awaited — un-awaited work escapes the transaction and silently
      //    loses data.
      final season = await _currentSeason();

      // The CHECK is `(outcome = 'to_ewe') = (rearing_dam IS NOT NULL)`, so the
      // rearing dam is derived from the outcome, never passed alongside it.
      // Value(null) is an explicit NULL; Value.absent() omits the column and
      // lets the default apply. They are not the same thing on an UPDATE.
      final rearingDam = switch (outcome) {
        ToEwe(:final ewe) => Value(ewe.value), // field name per foster_outcome.dart
        ToBottle() || RemovedUnknown() => const Value<int?>(null),
      };

      await _db.into(_db.fosterEvents).insert(
            FosterEventsCompanion.insert(
              uid: newUid(), // export identity — UUID v7, #32, R15
              createdAt: now,
              updatedAt: now,
              lamb: lamb.value, // ids cross the boundary, not bare ints (R33)
              season: season.value,
              outcome: outcome.key, // frozen wire key, never localised
              rearingDam: rearingDam,
              effectiveAt: when.effective, // foster's event-time column (R37)
              capturedAt: when.capturedAt,
              timeSource: Value(when.source.key),
              // originalEffective stays absent: nothing has been edited yet.
              // `corrects` stays absent: this is an original, not a correction.
            ),
          );
    });
    // 5. Gateways run AFTER the transaction returns, debounced 500 ms, off the
    //    paint frame. Never a platform channel inside a transaction — it
    //    round-trips through another isolate while holding the write lock.
  }

  Future<SeasonId> _currentSeason() async {
    /* one statement against app_settings — decision #42 */
    throw UnimplementedError();
  }

  /// One private helper per repository, and the only place error mapping
  /// appears. Note `const WriteCommitted()` — ALWAYS the default empty
  /// `warnings`, because this layer structurally cannot produce a Warning
  /// (R53). A create verb the cap can refuse returns
  /// `WriteCommitted(insertedId: id)` from its own body instead.
  Future<WriteOutcome> _write(Future<void> Function() body) async {
    try {
      await _db.transaction(body);
      return const WriteCommitted();
    } on Object catch (e, s) {
      // A programmer error is loud in debug and logged in release. Without this
      // line the catch-all turns every bad-state bug into a polite message and
      // you never see it. The assert throws out of the catch block.
      assert(e is! Error, 'programmer error inside a write: $e\n$s');
      LocalLog.instance.write('write failed', e, s);
      return WriteFailed(shedFailureFrom(e));
    }
  }
}

// Deliberately absent, and it must stay that way:
//   save(aggregate) · commit() · submit() · FosterDraft · isDirty ·
//   a Clock parameter · a return of WriteCommitted(warnings: [...]) ·
//   ref.invalidate after the write · an undo() method.
// The two verbs that break the WriteOutcome pattern are beginLambing and
// addLamb, which return an id and throw (R32). There is no third.
