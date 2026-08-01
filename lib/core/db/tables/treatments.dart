import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/ancillary.dart';
import 'package:shed_book/core/db/tables/common.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/lambing.dart';
import 'package:shed_book/core/db/tables/seasons.dart';

/// **No `Struckable`** (R79): a treatment is *voided*, not struck, because the
/// row may already have been printed into a medicine book handed to a vet. The
/// medicine book shows the void; it never loses the row.
@TableIndex(name: 'idx_treatment_ewe_time', columns: <Symbol>{#ewe, #administeredAt})
@TableIndex(name: 'idx_treatment_lamb_time', columns: <Symbol>{#lamb, #administeredAt})
@TableIndex(name: 'idx_treatment_season_time', columns: <Symbol>{#season, #administeredAt})
@TableIndex(name: 'idx_treatment_route', columns: <Symbol>{#route})
class Treatments extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  // Polymorphic subject as two nullable FKs + a CHECK. A (type, id) pair cannot
  // be a foreign key, so SQLite could not enforce that the animal exists, could
  // not cascade, and could not stop an orphan — and in a record that may be
  // shown to a vet, an orphan is worse than useless.
  //
  // RESTRICT on `ewe`, CASCADE on `lamb`, and the asymmetry is deliberate. A ewe
  // with treatments is a record someone may show a vet, so she cannot be deleted
  // out from under it — and she never needs to be, because a ewe leaves the
  // flock by status = 'culled', not by DELETE. A lamb cannot be RESTRICT:
  // deleting a season cascades seasons → lambings → lambs, and a RESTRICT here
  // would abort that delete from a child table the user never sees.
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();

  late final productName = text().withLength(min: 1, max: 120)();
  late final doseText = text().nullable()();

  late final route = text().nullable().references(VocabTerms, #key, onDelete: KeyAction.restrict)();

  late final batchNo = text().nullable()();

  /// One of the three documented exceptions to the `occurred_at` column-name
  /// rule, alongside `pen_occupancies.entered_at` and
  /// `foster_events.effective_at` (R37).
  late final administeredAt = integer().map(const InstantConverter())();

  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// Decision #69: undo for a treatment is a **soft void**.
  late final voidedAt = integer().map(const InstantConverter()).nullable()();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    // Exactly one subject. `+` on two booleans is SQLite's idiom for "exactly
    // one of these is set", and it is a CHECK rather than a Dart guard because
    // an orphaned treatment is the failure that matters.
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)',
    'CHECK (length(trim(product_name)) > 0)',
    'CHECK (administered_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// **There is no `withdrawal_days` column on `treatments` and no medicines
/// lookup table anywhere.**
///
/// A nullable `int?` conflates *"the label says 0 days"* with *"I did not
/// look"*, and `0` is a real label value. Withdrawals are a child table, 0..n
/// rows per treatment, and **NO ROW for a target means NotRecorded** — there is
/// no column whose default could quietly mean zero, because there is no row.
///
/// This is safety rule §12.1 at the **unpersistable** level.
@TableIndex(name: 'idx_withdrawal_clear', columns: <Symbol>{#clearDate})
class TreatmentWithdrawals extends Table with Identified {
  late final treatment = integer().references(Treatments, #id, onDelete: KeyAction.cascade)();

  /// `'meat'` | `'milk'`. One product routinely prints different figures.
  late final target = text()();

  /// `'days'` | `'not_applicable'`.
  late final kind = text()();

  /// **NO DEFAULT. NO clientDefault.** The app physically cannot write this row
  /// without the user having typed a number off the bottle. Spec §12.1 enforced
  /// by the schema, not by a code review — and N07-T08's snapshot assertion is
  /// what keeps it that way.
  late final days = integer().nullable()();

  /// The **one** stored derived value (decision #50). Computed exactly once at
  /// write time by `clearDateFor()`; its inputs live alongside it for ever.
  ///
  /// A record of what the app TOLD the user and printed into the medicine-book
  /// PDF — **not a cache**. When it disagrees with a fresh computation, that is
  /// `clearDateDisagrees`: shown, never applied.
  late final clearDate = text().map(const LocalDateConverter()).nullable()();

  /// Also the hand-written index decision #31 requires on the `treatment`
  /// foreign key — SQLite creates no child-key index by itself, and a
  /// leading-column index serves the FK. **Do not add a second one.**
  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{treatment, target},
  ];

  @override
  List<String> get customConstraints => <String>[
    "CHECK (target IN ('meat','milk'))",
    "CHECK (kind IN ('days','not_applicable'))",
    "CHECK ((kind = 'days') = (days IS NOT NULL))",
    "CHECK ((kind = 'days') = (clear_date IS NOT NULL))",
    'CHECK (days IS NULL OR days >= 0)',
    "CHECK (clear_date IS NULL OR clear_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}
