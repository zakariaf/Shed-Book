import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/common.dart';
import 'package:shed_book/core/db/tables/seasons.dart';

@TableIndex(name: 'idx_ewe_status', columns: <Symbol>{#status})
@TableIndex(name: 'idx_ewe_tagdigits', columns: <Symbol>{#tagDigits})
@TableIndex.sql(
  // §7.0 ruling 7: unique among ACTIVE animals only. A culled 412 releases the
  // tag; a new 412 is a new row with its own uid and its own history.
  //
  // `struck = 0` is R79 §f, decided WITH the strike rather than after it: a
  // predicate that says nothing about struck means a shepherd who strikes a
  // mistyped 412 cannot immediately re-enter 412 — which is the whole point of
  // striking a typo at 03:20.
  "CREATE UNIQUE INDEX idx_ewe_tag_active ON ewes (tag) "
  "WHERE status = 'active' AND struck = 0",
)
class Ewes extends Table with Identified, Struckable {
  /// Exactly as typed. **Never normalised on write** (spec §12.4).
  late final tag = text().withLength(min: 1, max: 32)();

  /// A digits-only **projection** of [tag], written in the same statement.
  ///
  /// A projection, not a correction: the typed value is preserved verbatim
  /// beside it, so the `normalize*` ban does not apply (decision #55).
  /// `min: 0`, because a tag can be all letters.
  ///
  /// **Uniqueness is on [tag], never on this.** Making the projection unique
  /// would refuse `0412` because `412` exists — the app deciding two tags are
  /// the same animal. It ranks matches; it never decides identity.
  late final tagDigits = text().withLength(min: 0, max: 32)();

  late final eid = text().withLength(min: 0, max: 32).nullable()();
  late final breed = text().nullable()();

  /// Partial precision is a real state. **Do not pad a year to 1 January.**
  late final dateOfBirth = text().map(const PartialDateConverter()).nullable()();

  late final source = text().nullable()();

  /// A default here is fine: it encodes nothing veterinary.
  late final status = text().withDefault(const Constant('active'))();

  late final notes = text().nullable()();
  late final overFreeCap = boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (status IN ('active','sold','dead','culled'))",
    'CHECK (length(trim(tag)) > 0)',
    "CHECK (date_of_birth IS NULL"
        " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]'"
        " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'"
        " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
  ];

  @override
  bool get isStrict => true;
}

/// What the spec's `seasons[]` hides.
///
/// Barren rate is not computable from lambings, because a barren ewe **has no
/// lambing row**. You need an explicit participation record.
@TableIndex(name: 'idx_eweseason_season', columns: <Symbol>{#season})
@TableIndex(name: 'idx_eweseason_ewe', columns: <Symbol>{#ewe})
class EweSeasons extends Table with Identified, Struckable {
  // ON DELETE is CHOSEN, never defaulted — KeyAction.noAction by laziness is
  // the defect. Both directions are cascade and each has its own reason: a
  // participation record has no meaning without its season, and none without
  // its ewe either.
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();

  /// **NO DEFAULT.** Defaulting to `'to_ram'` would silently assert a ewe was
  /// put to the ram, which is the denominator of a commercially sensitive
  /// number (decision #59). Every writer knows which status it is asserting.
  late final status = text()();

  late final scannedCount = integer().nullable()();
  late final notes = text().nullable()();

  /// A composite key indexes its **leading** column only, so this gives
  /// `season` an index and does nothing for `ewe` — which is why
  /// `idx_eweseason_ewe` exists as well.
  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{season, ewe},
  ];

  @override
  List<String> get customConstraints => <String>[
    "CHECK (status IN ('to_ram','scanned','lambed','barren','aborted','died','sold'))",
    'CHECK (scanned_count IS NULL OR scanned_count BETWEEN 0 AND 6)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
  ];

  @override
  bool get isStrict => true;
}

/// A **cache**: rebuildable, excluded from the backup, carrying no identity.
/// No [Identified], no [Struckable].
@DataClassName('EweTouch')
class EweTouches extends Table {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final touchedAt = integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{ewe};

  @override
  bool get isStrict => true;
}

/// *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* is not computable
/// from free text, and *"filter the flock by anything"* cannot include a
/// free-text field. Mothering, prolapse and mastitis are not derivable from
/// anything else in the schema, so they get a table.
///
/// **The §12.2 boundary:** the app records *what the shepherd observed*. It
/// never infers `poor_mothering` from a lamb death, never infers `no_milk` from
/// a bottle-fed lamb, and **never writes a row on the user's behalf**.
@TableIndex(name: 'idx_eweobs_ewe_time', columns: <Symbol>{#ewe, #occurredAt})
@TableIndex(name: 'idx_eweobs_season_kind', columns: <Symbol>{#season, #kind})
@TableIndex(name: 'idx_eweobs_kind', columns: <Symbol>{#kind})
@TableIndex(name: 'idx_eweobs_lambing', columns: <Symbol>{#lambing})
class EweObservations extends Table with Identified, Struckable {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  /// **Forward reference, deferred to N07-T04.** `Lambings` does not exist yet.
  /// The column and its index land now — an index needs no parent table — and
  /// `.references(Lambings, #id, onDelete: KeyAction.setNull)` is added when the
  /// parent exists. Nothing is frozen until T08, so editing this in T04 is free.
  late final lambing = integer().nullable()();

  /// **Forward reference, deferred to N07-T06.** A user-editable vocabulary is a
  /// foreign key, never a `CHECK` (convention 6), and `VocabTerms` lands in T06:
  /// `.references(VocabTerms, #key, onDelete: KeyAction.restrict)`.
  late final kind = text()();

  // The §12.5 provenance quad (R37). An observation is as deferrable as a
  // lambing — "she prolapsed about midnight" is entered at 06:00 — so the quad
  // is not optional, and it MUST land before the first snapshot.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
  ];

  @override
  bool get isStrict => true;
}
