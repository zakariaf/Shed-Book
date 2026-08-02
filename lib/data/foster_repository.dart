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

  /// The lamb's CURRENT rearing dam, from the view.
  ///
  /// **A SINGLE-ROW LOOKUP, which `07 §1.2` permits beside one content
  /// statement.** The Foster screen's content statement is the deck; this is the
  /// one extra fact it needs, and it is one row.
  ///
  /// `null` means the lamb is on no ewe — which is a THIRD state and not a
  /// match: `ToBottle()` on a lamb already on a bottle does not warn, because
  /// null-by-intent is not *already on this ewe* and there is no ewe to be on.
  Stream<EweId?> watchRearingDam(LambId lamb) => _db
      .customSelect(
        'SELECT rearing_dam FROM lamb_rearing WHERE lamb_id = ?',
        variables: <Variable<Object>>[Variable<int>(lamb.value)],
        // `lamb_rearing` is a view over these two, and a customSelect cannot
        // infer that — so a foster appended elsewhere would leave this stale.
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.lambs, _db.fosterEvents},
      )
      .watchSingleOrNull()
      .map(
        (QueryRow? r) =>
            r?.readNullable<int>('rearing_dam') == null ? null : EweId(r!.read<int>('rearing_dam')),
      );

  /// Appends a **compensating event** that reverses [event] and points at it.
  ///
  /// **THERE IS NO DELETE.** `FosterEvents` is append-only, `corrects` is
  /// `ON DELETE RESTRICT`, and `07 §15.3` is explicit: neither row can be
  /// removed afterwards. The obvious implementation deletes the row and it is
  /// wrong twice over — it loses the fact that a foster happened at all, and it
  /// makes the history unreadable in April, when the shepherd is trying to work
  /// out what actually went on.
  ///
  /// **REVERSING THE VERY FIRST FOSTER MEANS WRITING `ToEwe(birthDam)`.** Once
  /// any event exists for a lamb the view's *"no event at all"* arm is
  /// unreachable — its `EXISTS(…)` is true forever — so *put her back with her
  /// mother* is an explicit event naming the birth dam as the REARING dam. That
  /// is not a birth-dam mutation and the trigger never fires: `lambs.birth_dam`
  /// is not in the statement.
  ///
  /// **`was_fostered` STAYS 1 FOREVER, AND THAT IS CORRECT.** The lamb WAS
  /// fostered; the correction says where she ended up, not that it never
  /// happened.
  ///
  /// **`time_source` IS `auto`, NEVER `edited`.** Nothing was typed, and this is
  /// a NEW event rather than an edit of an old one — the paired CHECK forces
  /// `original_effective` to NULL, which is the same statement in the schema's
  /// own words.
  Future<WriteOutcome> correctFoster(FosterEventId event) async {
    final Instant now = appNow(); // ONCE per mutation
    final RecordedTime time = RecordedTime.capture(now);

    try {
      final int id = await _db.transaction(() async {
        final FosterEvent corrected = await (_db.select(
          _db.fosterEvents,
        )..where(($FosterEventsTable t) => t.id.equals(event.value))).getSingle();

        // THE STATE IMMEDIATELY BEFORE THE CORRECTED EVENT. Ordered by
        // `(effective_at, id)` exactly as `lamb_rearing` orders, so the
        // correction restores what the view WOULD have said — not what a
        // separate rule thinks it should say.
        final List<FosterEvent> earlier =
            await (_db.select(_db.fosterEvents)
                  ..where(
                    ($FosterEventsTable t) =>
                        t.lamb.equals(corrected.lamb) & t.id.isSmallerThanValue(corrected.id),
                  )
                  ..orderBy(<OrderClauseGenerator<$FosterEventsTable>>[
                    ($FosterEventsTable t) =>
                        OrderingTerm(expression: t.effectiveAt, mode: OrderingMode.desc),
                    ($FosterEventsTable t) =>
                        OrderingTerm(expression: t.id, mode: OrderingMode.desc),
                  ])
                  ..limit(1))
                .get();

        final FosterOutcome restored;
        if (earlier.isEmpty) {
          // ARM 1 OF THE VIEW'S COALESCE, made explicit. There was no prior
          // event, so the state before this foster was the lamb with her own
          // mother — and that has to be WRITTEN, because the view's no-event arm
          // is gone the moment the first event exists.
          final Lamb lamb = await (_db.select(
            _db.lambs,
          )..where(($LambsTable t) => t.id.equals(corrected.lamb))).getSingle();
          restored = ToEwe(EweId(lamb.birthDam));
        } else {
          final FosterEvent previous = earlier.first;
          restored = switch (previous.outcome) {
            'to_ewe' => ToEwe(EweId(previous.rearingDam!)),
            'to_bottle' => const ToBottle(),
            'removed_unknown' => const RemovedUnknown(),
            // NOT a silent fallback. A fourth outcome reaching here means the
            // CHECK grew a value and this switch did not, and a correction that
            // guessed would put a lamb on the wrong ewe.
            _ => throw FormatException('Unknown foster outcome', previous.outcome),
          };
        }

        final EweId? dam = switch (restored) {
          ToEwe(:final EweId ewe) => ewe,
          ToBottle() || RemovedUnknown() => null,
        };

        return _db
            .into(_db.fosterEvents)
            .insert(
              FosterEventsCompanion.insert(
                uid: newUid(),
                lamb: corrected.lamb,
                // COPIED FROM THE CORRECTED EVENT, which already carries the
                // lamb's season — copying keeps the pair cascade-consistent.
                season: corrected.season,
                rearingDam: Value<int?>(dam?.value),
                outcome: restored.key,
                // THE SELF-FK. This is what makes the row a CORRECTION rather
                // than a second foster, and it is why the two can never be
                // deleted: `corrects` is ON DELETE RESTRICT.
                corrects: Value<int?>(corrected.id),
                // A GRAFT IS DATED BY WHEN IT TOOK EFFECT (R37), and a
                // correction took effect now.
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
