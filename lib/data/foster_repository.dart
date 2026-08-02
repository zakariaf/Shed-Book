// lib/data/foster_repository.dart
//
// A FOSTER MOVES THE REARING DAM AND NEVER THE BIRTH DAM.
//
// `foster_events` is APPEND-ONLY. `lamb_rearing` projects the latest event onto
// the lamb, so the current rearing dam is a DERIVED value that no verb writes —
// which is what keeps a foster from looking like a rewrite of history. In year
// two the shepherd must be able to read that 412 threw this lamb and 077 reared
// it, and both must be true.
//
// The schema is N07-T04's and was snapshotted at N07-T08: `foster_events`, the
// `lamb_birth_dam_is_immutable` trigger and the `lamb_rearing` view all exist.
// Reaching for the schema here is not a shortcut, it is a migration on somebody
// else's phone.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class FosterRepository {
  /// No clock parameter, ever (R19). `appNow()` is the one seam, and a
  /// repository that took a clock would be a repository two tests could
  /// configure differently.
  // ignore_for_file: prefer_initializing_formals
  FosterRepository(AppDatabase db) : _db = db;

  final AppDatabase _db;

  /// Records one foster.
  ///
  /// **`setRearingDam(LambId, EweId?)` IS A BANNED SIGNATURE** (`07 §8.4` rule
  /// 1). It merges `to_bottle` — null BY INTENT, the shepherd put the lamb on a
  /// bottle — with `removed_unknown` — null BY OMISSION, the lamb came off a ewe
  /// and where it went was not recorded. The rearing-credit numbers differ
  /// between those two, so merging them silently changes a season's figures.
  ///
  /// `FosterOutcome` being sealed is what makes that merge UNCONSTRUCTIBLE
  /// rather than merely discouraged, and the `CHECK
  /// ((outcome = 'to_ewe') = (rearing_dam IS NOT NULL))` is why the outcome and
  /// the dam are derived together from one switch rather than taken as two
  /// arguments that can disagree.
  Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome) async {
    final Instant now = appNow(); // ONCE per mutation (R23)
    final RecordedTime time = RecordedTime.capture(now); // §12.5 provenance

    final EweId? dam = switch (outcome) {
      ToEwe(:final EweId ewe) => ewe,
      // EXHAUSTIVE, NO `default:`. A fourth outcome must fail to compile here
      // rather than quietly writing a NULL dam.
      ToBottle() || RemovedUnknown() => null,
    };

    try {
      final int id = await _db.transaction(() async {
        // THE LAMB'S SEASON, WALKED TO INSIDE THE TRANSACTION. Reading it from
        // a screen's copy is one frame stale, and getting it wrong scopes the
        // foster into the wrong season's rearing figures forever.
        final SeasonId season = await _seasonOfLamb(lamb);

        return _db
            .into(_db.fosterEvents)
            .insert(
              FosterEventsCompanion.insert(
                uid: newUid(), // UUID v7 — the export identity (#32)
                lamb: lamb.value,
                season: season.value,
                rearingDam: Value<int?>(dam?.value),
                // R64: the stored key lives on the type, so there is one
                // spelling of each outcome and it cannot drift from the CHECK.
                outcome: outcome.key,
                effectiveAt: time.effective,
                capturedAt: time.capturedAt,
                timeSource: Value<String>(time.source.key),
                createdAt: now,
                updatedAt: now,
              ),
            );
      });
      return WriteCommitted(insertedId: id);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  Future<SeasonId> _seasonOfLamb(LambId lamb) async {
    final Lamb row = await (_db.select(
      _db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    final Lambing parent = await (_db.select(
      _db.lambings,
    )..where(($LambingsTable t) => t.id.equals(row.lambing))).getSingle();
    return SeasonId(parent.season);
  }
}
