import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/ancillary.dart';
import 'package:shed_book/core/db/tables/common.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/seasons.dart';

@TableIndex(name: 'idx_lambing_season_time', columns: <Symbol>{#season, #occurredAt})
@TableIndex(name: 'idx_lambing_ewe_time', columns: <Symbol>{#ewe, #occurredAt})
@TableIndex(name: 'idx_lambing_localdate', columns: <Symbol>{#season, #localDate})
@TableIndex(name: 'idx_lambing_presentation', columns: <Symbol>{#presentation})
class Lambings extends Table with Identified, Struckable {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  /// `restrict`: a ewe with lambings is a record someone may show a vet, so she
  /// cannot be deleted out from under it — and she never needs to be, because a
  /// ewe leaves the flock by `status = 'culled'`, not by DELETE.
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  // --- The §12.5 provenance quad. See RecordedTime in 05. ---
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// Denormalised local civil date of [occurredAt], written in the **same
  /// statement**.
  ///
  /// The grouping key for the lambing-spread histogram: SQLite cannot bucket by
  /// the shepherd's civil day without a timezone database, and Dart can. An edit
  /// to the time that leaves this stale moves a lambing to the wrong bar for
  /// ever — which is what `WarningCode.localDateDisagrees` surfaces and nothing
  /// repairs.
  late final localDate = text().map(const LocalDateConverter())();

  /// EXACTLY what the shepherd tapped. 1 = single … 4 = quad, 5 = *"more"*.
  /// **The number of Lamb rows is NOT forced to agree** (spec §12.4).
  ///
  /// **NULLABLE, and this is load-bearing (R6):** the lambing row is written on
  /// the FIRST tap, before any birth type exists, and the record must survive
  /// being interrupted at any point. NULL means *"not yet tapped"*, which is a
  /// different fact from any of 1..5 and is **never defaulted to `single`**.
  late final declaredBirthType = integer().nullable()();

  /// 1..5. **NO DEFAULT and nullable**: a blank score means *"not scored"*,
  /// which is a different fact from *"unassisted"* (decision #59).
  late final ease = integer().nullable()();

  late final assistedBy = text().nullable()();

  late final presentation = text().nullable().references(
    VocabTerms,
    #key,
    onDelete: KeyAction.restrict,
  )();

  late final presentationNote = text().nullable()();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    "CHECK (local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (declared_birth_type IS NULL OR declared_birth_type BETWEEN 1 AND 5)',
    'CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// **A lamb that died before tagging is counted, fully.** Lamb identity is the
/// row, never the tag; `tag` is nullable at every layer. Anything else loses
/// exactly the losses that matter most.
@TableIndex(name: 'idx_lamb_lambing', columns: <Symbol>{#lambing})
@TableIndex(name: 'idx_lamb_birthdam', columns: <Symbol>{#birthDam})
@TableIndex(name: 'idx_lamb_tagdigits', columns: <Symbol>{#tagDigits})
@TableIndex(name: 'idx_lamb_deathcause', columns: <Symbol>{#deathCause})
// Ruled 2026-08-01 (§7.0 row 13). SQLite creates no child-key index
// automatically (#31), and the ewe card reads this the other way round — "which
// lamb was she?" — on every retained ewe.
@TableIndex(name: 'idx_lamb_became_ewe', columns: <Symbol>{#becameEwe})
@TableIndex.sql(
  // `struck = 0` per R79 §f, for the same reason as the ewe index.
  "CREATE UNIQUE INDEX idx_lamb_tag_alive ON lambs (tag) "
  "WHERE tag IS NOT NULL AND status = 'alive' AND struck = 0",
)
class Lambs extends Table with Identified, Struckable {
  late final lambing = integer().references(Lambings, #id, onDelete: KeyAction.cascade)();

  /// Immutable, denormalised from `lambings.ewe` at insert. **Enforced by a
  /// BEFORE UPDATE trigger, not by Dart** (03 §7) — a Dart guard is one
  /// repository method away from being bypassed, and a fostered lamb whose birth
  /// dam moved has lost the fact the two-dam model exists to keep.
  late final birthDam = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  late final tag = text().nullable()();
  late final tagDigits = text().nullable()();

  /// NULL = not recorded. `'unknown'` = the shepherd looked and could not tell.
  /// The Dart side models NULL as `Sex?`, **never as `Sex.unknown`** (R45).
  late final sex = text().nullable()();

  late final birthWeightG = integer().nullable()();
  late final status = text().withDefault(const Constant('alive'))();

  /// Civil date: the shepherd knows the day, not the minute. Forcing a time
  /// would invent precision the mortality buckets then over-claim.
  late final deathDate = text().map(const LocalDateConverter()).nullable()();

  late final deathCause = text().nullable().references(
    VocabTerms,
    #key,
    onDelete: KeyAction.restrict,
  )();

  late final petLamb = boolean().withDefault(const Constant(false))();
  late final bottleFeeds = integer().withDefault(const Constant(0))();
  late final notes = text().nullable()();

  /// The retained lamb, promoted to the breeding flock (§7.0 row 13). NULL for
  /// every lamb that was not kept, which is nearly all of them.
  ///
  /// `setNull` and not `cascade`: deleting the ewe row must not delete the lamb
  /// she was, because the lamb is a record of a birth that happened.
  late final becameEwe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.setNull)();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (sex IS NULL OR sex IN ('f','m','unknown'))",
    "CHECK (status IN ('alive','dead','stillborn','sold'))",
    // A death date implies a death. A death does NOT imply a date — "died, date
    // not recorded" is a real state and lands in unknownAge.
    "CHECK (death_date IS NULL OR status IN ('dead','stillborn'))",
    "CHECK (death_cause IS NULL OR status IN ('dead','stillborn'))",
    "CHECK (death_date IS NULL OR death_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    // A UNIT-SLIP guard (5 g versus 5 kg), NOT a husbandry opinion. Never narrow
    // it to a range a vet would recognise — spec §12.2. The plausibility band a
    // shepherd actually sees is kPlausibleBirthWeight, and it warns.
    'CHECK (birth_weight_g IS NULL OR birth_weight_g BETWEEN 200 AND 20000)',
    'CHECK (bottle_feeds >= 0)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}
