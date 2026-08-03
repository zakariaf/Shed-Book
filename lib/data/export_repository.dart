// lib/data/export_repository.dart
//
// THE ONE REPOSITORY THAT WRITES NOTHING (`CONVENTIONS §2.13`). It reads, it
// assembles artefacts, and it owns no table — which is why it has no event verbs
// and no `WriteOutcome` anywhere in it.
//
// **THE THREE HEADER ROWS ARE THE CONTRACT AND THEY ARE FROZEN.** Appending a
// column to the end of a list is allowed; renaming or reordering one is a
// breaking change to every spreadsheet a shepherd has built on top of the file —
// and that file landed on somebody else's laptop the day after the first tap.
// You cannot recall it.
//
// **NO EXPORT STATEMENT MAY FILTER A STRUCK ROW OUT.** `indelible.md` screen 11:
// *"every CSV carries a `struck` and a `struck_at` column and every struck row
// is included and marked, because an export that quietly drops the strikes would
// undo the one thing this app is for."*
//
// A predicate that excludes struck rows is a defect, and `csv_shapes_test.dart`
// scans this file's source text for four spellings of one. **The spellings are
// not quoted in this comment** — the scan reads the whole file, so a comment
// naming the thing it forbids fails the case that forbids it. It caught the
// first draft of this one.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';

final class ExportRepository {
  ExportRepository(this._db);

  final AppDatabase _db;

  /// 37 fields. `09 §3.1`.
  ///
  /// Every `*_key` column is the stable ASCII vocabulary key that never changes;
  /// every `*_label` is the resolved human wording the user may have edited.
  /// Both ship, because the key is what a machine joins on and the label is what
  /// a human reads, and neither substitutes for the other.
  static const List<String> lambsHeader = <String>[
    'lamb_uid',
    'season_year',
    'season_label',
    'lamb_tag',
    'sex',
    'birth_dam_tag',
    'birth_dam_uid',
    'rearing_dam_tag',
    'rearing_dam_uid',
    'was_fostered',
    'lambing_uid',
    'born_at_utc',
    'born_at_local',
    'born_local_date',
    'local_date_disagrees',
    'time_source',
    'time_provenance',
    'time_captured_at_utc',
    'time_original_effective_utc',
    'declared_birth_type',
    'lambs_recorded_for_lambing',
    'birth_type_mismatch',
    'lambing_ease',
    'assisted_by',
    'presentation_key',
    'presentation_label',
    'birth_weight_g',
    'birth_weight_kg',
    'status',
    'death_date',
    'death_cause_key',
    'death_cause_label',
    'pet_lamb',
    'bottle_feeds',
    'notes',
    'struck',
    'struck_at',
  ];

  /// 28 fields. `09 §3.2`.
  ///
  /// `over_free_cap` is deliberately absent: a monetization marker is not a fact
  /// about a sheep. It is in the JSON backup, because **the backup is the record
  /// and the CSV is a report** — and that distinction settles every "does this
  /// column belong?" argument. `tag_digits` is absent for the same reason in the
  /// other direction: it is a projection for the keypad's ranking, and the tag
  /// ships exactly as typed.
  static const List<String> ewesHeader = <String>[
    'ewe_uid',
    'tag',
    'eid',
    'breed',
    'date_of_birth',
    'source',
    'status',
    'season_year',
    'season_label',
    'season_status',
    'scanned_count',
    'lambings_recorded',
    'lambings_scored',
    'lambings_scored_assisted',
    'lambs_born',
    'lambs_born_alive',
    'lambs_stillborn',
    'lambs_reared',
    'first_lambing_at_utc',
    'first_lambing_local_date',
    'last_lambing_at_utc',
    'observations',
    'treatments_recorded',
    'latest_meat_clear_date',
    'latest_milk_clear_date',
    'notes',
    'struck',
    'struck_at',
  ];

  /// 31 fields. `09 §3.3`.
  ///
  /// A treatment has 0..2 withdrawal children and they are **pivoted into
  /// columns**, not unpivoted into rows: the spec says one row per treatment,
  /// and the shepherd reading the file wants one line per bottle.
  static const List<String> treatmentsHeader = <String>[
    'treatment_uid',
    'season_year',
    'season_label',
    'animal_kind',
    'animal_tag',
    'animal_uid',
    'product_name',
    'dose_text',
    'route_key',
    'route_label',
    'batch_no',
    'administered_at_utc',
    'administered_at_local',
    'time_source',
    'time_provenance',
    'time_captured_at_utc',
    'time_original_effective_utc',
    'meat_withdrawal_state',
    'meat_withdrawal_days',
    'meat_clear_date',
    'meat_withdrawal_source',
    'milk_withdrawal_state',
    'milk_withdrawal_days',
    'milk_clear_date',
    'milk_withdrawal_source',
    'clear_date_disagrees',
    'is_voided',
    'voided_at_utc',
    'note',
    'struck',
    'struck_at',
  ];

  /// One row per lamb, including dead, stillborn and untagged ones.
  ///
  /// [vocabLabels] is resolved by the Export **screen** — the only object in the
  /// app with a `BuildContext` — and handed down opaque (`09 §3.4`). Nothing at
  /// or below `lib/data/` may reach `AppLocalizations`, and neither may a
  /// controller, which holds no context by `CONVENTIONS §4.4` rule 3.
  Future<Uint8List> writeLambsCsv({
    required SeasonId season,
    required CsvWriter writer,
    required Map<String, String> vocabLabels,
  }) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          _lambsSql,
          variables: <Variable<Object>>[Variable<int>(season.value)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.lambs,
            _db.lambings,
            _db.ewes,
            _db.seasons,
            _db.fosterEvents,
          },
        )
        .get();

    return writer.encode(lambsHeader, rows.map((QueryRow r) => _lambRow(r, vocabLabels)));
  }

  List<Object?> _lambRow(QueryRow r, Map<String, String> labels) {
    final Instant bornAt = Instant(r.read<int>('born_at'));
    final LocalDate storedDate = LocalDate.parse(r.read<String>('born_local_date'));
    final int? weightG = r.readNullable<int>('birth_weight_g');

    return <Object?>[
      r.read<String>('lamb_uid'),
      r.read<int>('season_year'),
      r.read<String>('season_label'),
      r.readNullable<String>('lamb_tag'),
      // BLANK IS NOT `unknown` (R45): blank is *not recorded*, `unknown` is
      // *looked and could not tell*. Passing the nullable straight through is
      // what keeps them apart — there is no `?? 'unknown'` anywhere here.
      r.readNullable<String>('sex'),
      r.readNullable<String>('birth_dam_tag'),
      r.read<String>('birth_dam_uid'),
      r.readNullable<String>('rearing_dam_tag'),
      r.readNullable<String>('rearing_dam_uid'),
      r.read<int>('was_fostered'),
      r.read<String>('lambing_uid'),
      _iso(bornAt),
      _localDdMmYyyyHhMm(bornAt),
      storedDate.iso,
      // §12.4: BOTH VALUES ARE PRINTED AND NEITHER IS CORRECTED. The stored
      // civil date is the day as it was lived; re-deriving it in the
      // export-time zone can disagree after the device moved, and the file says
      // so in a column rather than quietly picking one.
      _bit(storedDate.iso != LocalDate.of(bornAt).iso),
      r.read<String>('time_source'),
      TimeSource.fromKey(r.read<String>('time_source')).label,
      _iso(Instant(r.read<int>('captured_at'))),
      // BLANK IFF `time_source` IS NOT `edited` — the paired CHECK travels into
      // the file rather than being re-derived by whoever reads it.
      _isoOrNull(r.readNullable<int>('original_effective')),
      r.readNullable<int>('declared_birth_type'),
      r.read<int>('lambs_recorded_for_lambing'),
      r.read<int>('birth_type_mismatch'),
      // BLANK IS *NOT SCORED*, WHICH IS NOT *UNASSISTED*. `05 §6.7` excludes
      // unscored lambings from both sides of the assisted rate for this reason.
      r.readNullable<int>('lambing_ease'),
      r.readNullable<String>('assisted_by'),
      r.readNullable<String>('presentation_key'),
      _label(r.readNullable<String>('presentation_key'), labels),
      weightG,
      // Canonical grams in, two decimals out, `.` separator, hand-formatted.
      weightG == null ? null : _kg(Grams(weightG)),
      r.read<String>('status'),
      r.readNullable<String>('death_date'),
      r.readNullable<String>('death_cause_key'),
      // A blank cause is **unattributed**, never `unknown` — `dc_unknown` is a
      // cause the shepherd picked, and merging the two loses the difference
      // between "nobody said" and "nobody could tell".
      _label(r.readNullable<String>('death_cause_key'), labels),
      r.read<int>('pet_lamb'),
      r.read<int>('bottle_feeds'),
      r.readNullable<String>('notes'),
      r.read<int>('struck'),
      _isoOrNull(r.readNullable<int>('struck_at')),
    ];
  }

  /// One row per ewe: every participation row for the season, **union** every
  /// active ewe with none.
  ///
  /// An export that silently omits an animal the shepherd can see in her flock
  /// list is the failure this format exists to prevent. A blank `season_status`
  /// is honest; an absent row is not.
  Future<Uint8List> writeEwesCsv({
    required SeasonId season,
    required CsvWriter writer,
    required Map<String, String> vocabLabels,
  }) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          _ewesSql,
          variables: <Variable<Object>>[
            for (int i = 0; i < _ewesSeasonPlaceholders; i++) Variable<int>(season.value),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.ewes,
            _db.eweSeasons,
            _db.seasons,
            _db.lambings,
            _db.lambs,
            _db.fosterEvents,
            _db.eweObservations,
            _db.treatments,
            _db.treatmentWithdrawals,
          },
        )
        .get();

    return writer.encode(ewesHeader, rows.map((QueryRow r) => _eweRow(r, vocabLabels)));
  }

  List<Object?> _eweRow(QueryRow r, Map<String, String> labels) => <Object?>[
    r.read<String>('ewe_uid'),
    // EXACTLY AS TYPED, never normalised (`03 §5.2`).
    r.read<String>('tag'),
    r.readNullable<String>('eid'),
    r.readNullable<String>('breed'),
    // A `PartialDate` as stored — `2023`, `2023-04` or `2023-04-11`. Never
    // padded to 1 January: partial precision is a real state.
    r.readNullable<String>('date_of_birth'),
    r.readNullable<String>('source'),
    r.read<String>('status'),
    r.read<int>('season_year'),
    r.read<String>('season_label'),
    // ONE OF THE SEVEN STORED KEYS, or blank. **Never the four-way
    // `EweSeasonOutcome` bucketing** (R43) — that is a derived view for
    // statistics and it does not round-trip.
    r.readNullable<String>('season_status'),
    r.readNullable<int>('scanned_count'),
    r.read<int>('lambings_recorded'),
    r.read<int>('lambings_scored'),
    // Paired with the column before it so an assisted rate can exclude unscored
    // lambings from **both** sides.
    r.read<int>('lambings_scored_assisted'),
    r.read<int>('lambs_born'),
    r.read<int>('lambs_born_alive'),
    // ITS OWN BUCKET, never folded into day-0 deaths.
    r.read<int>('lambs_stillborn'),
    // AGGREGATED BY REARING DAM, never mixed with the three born counts above,
    // which are by birth dam. `lamb_rearing` is the view that keeps them apart.
    r.read<int>('lambs_reared'),
    _isoOrNull(r.readNullable<int>('first_lambing_at')),
    r.readNullable<String>('first_lambing_local_date'),
    _isoOrNull(r.readNullable<int>('last_lambing_at')),
    _observations(r.readNullable<String>('observation_keys'), labels),
    r.read<int>('treatments_recorded'),
    // THE STORED VALUE (#50) — never recomputed here.
    r.readNullable<String>('latest_meat_clear_date'),
    r.readNullable<String>('latest_milk_clear_date'),
    r.readNullable<String>('notes'),
    r.read<int>('struck'),
    _isoOrNull(r.readNullable<int>('struck_at')),
  ];

  /// How many times `_ewesSql` binds the season.
  ///
  /// **COUNTED FROM THE STATEMENT AT RUNTIME**, not written down. SQLite has no
  /// named parameters through `customSelect`, so every correlated subquery needs
  /// its own `?` — and a hand-maintained count is one edit away from
  /// `Expected 15 parameters, got 9`, which is what it gave on the first run.
  static final int _ewesSeasonPlaceholders = '?'.allMatches(_ewesSql).length;

  /// One row per treatment, **including voided ones**.
  ///
  /// Decision #69: undo for a treatment is a soft void, because the row may
  /// already have been printed into a medicine book handed to a vet. The
  /// medicine book shows the void and never loses the row — and neither does
  /// this file.
  Future<Uint8List> writeTreatmentsCsv({
    required SeasonId season,
    required CsvWriter writer,
    required Map<String, String> vocabLabels,
  }) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          _treatmentsSql,
          variables: <Variable<Object>>[Variable<int>(season.value)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.treatments,
            _db.treatmentWithdrawals,
            _db.ewes,
            _db.lambs,
            _db.seasons,
          },
        )
        .get();

    return writer.encode(treatmentsHeader, rows.map((QueryRow r) => _treatmentRow(r, vocabLabels)));
  }

  List<Object?> _treatmentRow(QueryRow r, Map<String, String> labels) {
    final Instant administeredAt = Instant(r.read<int>('administered_at'));
    final int? voidedAt = r.readNullable<int>('voided_at');

    final _Withdrawal meat = _withdrawalOf(r, 'meat', administeredAt);
    final _Withdrawal milk = _withdrawalOf(r, 'milk', administeredAt);

    return <Object?>[
      r.read<String>('treatment_uid'),
      r.read<int>('season_year'),
      r.read<String>('season_label'),
      r.read<String>('animal_kind'),
      r.readNullable<String>('animal_tag'),
      r.read<String>('animal_uid'),
      r.read<String>('product_name'),
      // NEVER PARSED, NEVER NORMALISED, never split into a number and a unit.
      // The app has no opinion about a dose (§12.2).
      r.readNullable<String>('dose_text'),
      r.readNullable<String>('route_key'),
      _label(r.readNullable<String>('route_key'), labels),
      r.readNullable<String>('batch_no'),
      _iso(administeredAt),
      _localDdMmYyyyHhMm(administeredAt),
      r.read<String>('time_source'),
      TimeSource.fromKey(r.read<String>('time_source')).label,
      _iso(Instant(r.read<int>('captured_at'))),
      _isoOrNull(r.readNullable<int>('original_effective')),
      meat.state,
      meat.days,
      meat.clearDate,
      meat.source,
      milk.state,
      milk.days,
      milk.clearDate,
      milk.source,
      // SHOWN, NEVER APPLIED (#50, #54). The stored date stays; the column says
      // that today's arithmetic gives a different one.
      _bit(meat.disagrees || milk.disagrees),
      _bit(voidedAt != null),
      _isoOrNull(voidedAt),
      r.readNullable<String>('note'),
      // R79 §d: `treatments` carries no `struck` column, because a treatment is
      // *voided* rather than struck — the row may already be in a book somebody
      // is holding. The export contract is uniform across all three shapes, so
      // the pair is DERIVED here, once, and sits beside `is_voided`.
      _bit(voidedAt != null),
      _isoOrNull(voidedAt),
    ];
  }

  /// The three withdrawal states, kept apart at the file's edge.
  ///
  /// **`not_recorded` IS THE ABSENCE OF A CHILD ROW**, `not_applicable` is a row
  /// the shepherd wrote, and `days` is a number off a bottle. A nullable integer
  /// merges the first two, and `0` is a real label value — which is the whole
  /// reason `treatment_withdrawals` is a child table (§12.1).
  _Withdrawal _withdrawalOf(QueryRow r, String target, Instant administeredAt) {
    final String? kind = r.readNullable<String>('${target}_kind');
    if (kind == null) {
      return const _Withdrawal(state: 'not_recorded');
    }
    if (kind != 'days') {
      return const _Withdrawal(state: 'not_applicable');
    }

    final int days = r.read<int>('${target}_days');
    final String stored = r.read<String>('${target}_clear_date');
    final LocalDate recomputed = clearDateFor(administeredAt: administeredAt, days: days).date;

    return _Withdrawal(
      state: 'days',
      days: days,
      clearDate: stored,
      // The one place the file claims a provenance, and it is referenced rather
      // than re-typed.
      source: Disclaimers.withdrawalProvenance,
      disagrees: stored != recomputed.iso,
    );
  }

  // -- formatting, all of it by hand -----------------------------------------
  //
  // `09 §2.5`: CSV is an interchange format, not a display format, and a
  // locale-aware formatter is banned from the writer for a measured reason — on
  // a device set to French it emits a comma decimal, which is then quoted or not
  // depending on the predicate, and every column after the weight shifts.

  /// ISO-8601, UTC, milliseconds, `Z`. Never a local ISO string, never an epoch
  /// integer, never `DateTime.toString()`.
  static String _iso(Instant i) =>
      DateTime.fromMillisecondsSinceEpoch(i.epochMillis, isUtc: true).toIso8601String();

  static String? _isoOrNull(int? epochMillis) =>
      epochMillis == null ? null : _iso(Instant(epochMillis));

  /// `dd/MM/yyyy HH:mm`, 24-hour, device zone at export, zero-padded by hand.
  ///
  /// The leading zero is the thing hand-rolling gets wrong — `1:5` instead of
  /// `01:05` — and it is asserted in `test/domain/uk_zone/`.
  static String _localDdMmYyyyHhMm(Instant i) {
    final DateTime d = i.local;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Two decimals, `.` separator, e.g. `4.10`.
  static String _kg(Grams g) => (g.value / 1000).toStringAsFixed(2);

  /// `0` / `1`, never `true`/`false` and never `Y`/`N`.
  static int _bit(bool v) => v ? 1 : 0;

  /// `label ?? default` (#61) — and the default here is the key itself rather
  /// than a guess, because a key with no resolved label is a vocabulary gap and
  /// printing the key says so.
  static String? _label(String? key, Map<String, String> labels) =>
      key == null ? null : (labels[key] ?? key);

  /// `; `-joined, which the `;` quoting rule then wraps: `prolapse; mastitis`.
  static String? _observations(String? keys, Map<String, String> labels) {
    if (keys == null || keys.isEmpty) {
      return null;
    }
    return keys.split('').map((String k) => labels[k] ?? k).join('; ');
  }
}

/// One target's withdrawal, as four cells and a warning.
final class _Withdrawal {
  const _Withdrawal({
    required this.state,
    this.days,
    this.clearDate,
    this.source,
    this.disagrees = false,
  });

  final String state;

  /// **Blank is never `0`.** `0` is a real label value.
  final int? days;
  final String? clearDate;
  final String? source;
  final bool disagrees;
}

// ---------------------------------------------------------------------------
// The statements.
//
// NOT ONE OF THEM CARRIES A `struck` PREDICATE, and that is asserted by a scan
// of this file's source text rather than left to review.
// ---------------------------------------------------------------------------

const String _lambsSql = '''
SELECT lb.uid AS lamb_uid, lb.tag AS lamb_tag, lb.sex, lb.birth_weight_g,
       lb.status, lb.death_date, lb.death_cause AS death_cause_key,
       lb.pet_lamb, lb.bottle_feeds, lb.notes, lb.struck, lb.struck_at,
       s.year AS season_year, s.label AS season_label,
       bd.tag AS birth_dam_tag, bd.uid AS birth_dam_uid,
       rd.tag AS rearing_dam_tag, rd.uid AS rearing_dam_uid,
       lr.was_fostered,
       l.uid AS lambing_uid, l.occurred_at AS born_at, l.local_date AS born_local_date,
       l.time_source, l.captured_at, l.original_effective,
       l.declared_birth_type, l.ease AS lambing_ease, l.assisted_by,
       l.presentation AS presentation_key,
       lc.recorded AS lambs_recorded_for_lambing,
       lc.is_mismatched AS birth_type_mismatch
  FROM lambs lb
  JOIN lambings l ON l.id = lb.lambing
  JOIN seasons  s ON s.id = l.season
  JOIN ewes    bd ON bd.id = lb.birth_dam
  JOIN lamb_rearing lr ON lr.lamb_id = lb.id
  LEFT JOIN ewes rd ON rd.id = lr.rearing_dam
  JOIN lambing_consistency lc ON lc.lambing_id = l.id
 WHERE l.season = ?
 ORDER BY l.occurred_at, lb.uid
''';

/// The union rule, and the reason the season id is bound nine times: SQLite has
/// no named parameters through `customSelect`, and every correlated subquery
/// here needs the same season.
const String _ewesSql = '''
SELECT e.uid AS ewe_uid, e.tag, e.eid, e.breed, e.date_of_birth, e.source,
       e.status, e.notes, e.struck, e.struck_at,
       s.year AS season_year, s.label AS season_label,
       es.status AS season_status, es.scanned_count,
       (SELECT COUNT(*) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ?) AS lambings_recorded,
       (SELECT COUNT(*) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ? AND l.ease IS NOT NULL) AS lambings_scored,
       (SELECT COUNT(*) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ? AND l.ease >= 2) AS lambings_scored_assisted,
       (SELECT COUNT(*) FROM lambs lb JOIN lambings l ON l.id = lb.lambing
         WHERE lb.birth_dam = e.id AND l.season = ?) AS lambs_born,
       (SELECT COUNT(*) FROM lambs lb JOIN lambings l ON l.id = lb.lambing
         WHERE lb.birth_dam = e.id AND l.season = ?
           AND lb.status <> 'stillborn') AS lambs_born_alive,
       (SELECT COUNT(*) FROM lambs lb JOIN lambings l ON l.id = lb.lambing
         WHERE lb.birth_dam = e.id AND l.season = ?
           AND lb.status = 'stillborn') AS lambs_stillborn,
       (SELECT COUNT(*) FROM lamb_rearing lr
          JOIN lambs lb ON lb.id = lr.lamb_id
          JOIN lambings l ON l.id = lb.lambing
         WHERE lr.rearing_dam = e.id AND l.season = ?
           AND lb.status = 'alive') AS lambs_reared,
       (SELECT MIN(l.occurred_at) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ?) AS first_lambing_at,
       (SELECT MIN(l.local_date) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ?) AS first_lambing_local_date,
       (SELECT MAX(l.occurred_at) FROM lambings l
         WHERE l.ewe = e.id AND l.season = ?) AS last_lambing_at,
       (SELECT group_concat(o.kind, char(1)) FROM ewe_observations o
         WHERE o.ewe = e.id AND o.season = ?) AS observation_keys,
       (SELECT COUNT(*) FROM treatments t
         WHERE t.ewe = e.id AND t.season = ? AND t.voided_at IS NULL) AS treatments_recorded,
       (SELECT MAX(tw.clear_date) FROM treatment_withdrawals tw
          JOIN treatments t ON t.id = tw.treatment
         WHERE t.ewe = e.id AND t.season = ?
           AND tw.target = 'meat') AS latest_meat_clear_date,
       (SELECT MAX(tw.clear_date) FROM treatment_withdrawals tw
          JOIN treatments t ON t.id = tw.treatment
         WHERE t.ewe = e.id AND t.season = ?
           AND tw.target = 'milk') AS latest_milk_clear_date
  FROM ewes e
  CROSS JOIN seasons s
  LEFT JOIN ewe_seasons es ON es.ewe = e.id AND es.season = s.id
 WHERE s.id = ?
   AND (es.id IS NOT NULL OR e.status = 'active')
 ORDER BY e.tag_digits, e.tag, e.uid
''';

const String _treatmentsSql = '''
SELECT t.uid AS treatment_uid, t.product_name, t.dose_text, t.route AS route_key,
       t.batch_no, t.administered_at, t.captured_at, t.original_effective,
       t.time_source, t.voided_at, t.note,
       s.year AS season_year, s.label AS season_label,
       CASE WHEN t.ewe IS NOT NULL THEN 'ewe' ELSE 'lamb' END AS animal_kind,
       COALESCE(e.tag, l.tag) AS animal_tag,
       COALESCE(e.uid, l.uid) AS animal_uid,
       meat.kind AS meat_kind, meat.days AS meat_days, meat.clear_date AS meat_clear_date,
       milk.kind AS milk_kind, milk.days AS milk_days, milk.clear_date AS milk_clear_date
  FROM treatments t
  JOIN seasons s ON s.id = t.season
  LEFT JOIN ewes  e ON e.id = t.ewe
  LEFT JOIN lambs l ON l.id = t.lamb
  LEFT JOIN treatment_withdrawals meat
         ON meat.treatment = t.id AND meat.target = 'meat'
  LEFT JOIN treatment_withdrawals milk
         ON milk.treatment = t.id AND milk.target = 'milk'
 WHERE t.season = ?
 ORDER BY t.administered_at, t.uid
''';
