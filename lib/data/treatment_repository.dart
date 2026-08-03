// lib/data/treatment_repository.dart
//
// SAFETY RULE §12.1 LIVES HERE: **never default a medicine withdrawal period.**
//
// The mechanism is a CHILD TABLE WHERE NO ROW MEANS *NOT RECORDED*. A nullable
// `withdrawal_days` column on `treatments` could not carry that state, because
// `0` is a real label value — "the label says zero days" and "nobody wrote a
// number down" are different facts, and a nullable int merges them. So absence
// is the absence of a row, which nothing can accidentally write.
//
// The obvious implementation writes a row with `days = 0`. Everything in this
// file exists so that it cannot.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

/// Who was treated — **exactly one of a ewe or a lamb**.
///
/// `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)`, and this type is the
/// same move `CareSubject` makes for the same reason: two nullable ids make the
/// unstorable combinations constructible, and the CHECK then fires at 03:20
/// instead of at compile time.
sealed class TreatmentSubject {
  const TreatmentSubject();
}

final class TreatEwe extends TreatmentSubject {
  const TreatEwe(this.ewe);

  final EweId ewe;
}

final class TreatLamb extends TreatmentSubject {
  const TreatLamb(this.lamb);

  final LambId lamb;
}

final class TreatmentRepository {
  // ignore_for_file: prefer_initializing_formals
  TreatmentRepository(AppDatabase db) : _db = db;

  final AppDatabase _db;

  /// Records one treatment and **only the withdrawal periods the user entered**.
  ///
  /// **`withdrawals` IS A LIST, AND AN EMPTY LIST IS THE COMMON CASE.** It does
  /// NOT contain `WithdrawalNotRecorded` entries — *not recorded* is the absence
  /// of an entry, which is the whole point of the child table. Passing one in
  /// would be asking this verb to write a row that means "no row".
  ///
  /// `WithdrawalDays` can only be built through `asEnteredByUser`, whose name is
  /// the §12.1 claim in the type system: every stored period came off a bottle
  /// the shepherd was holding.
  Future<WriteOutcome> recordTreatment(
    TreatmentSubject subject, {
    required String productName,
    String? doseText,
    String? routeKey,
    String? batchNo,
    List<WithdrawalPeriod> withdrawals = const <WithdrawalPeriod>[],
  }) async {
    final Instant now = appNow(); // ONE instant per mutation
    final RecordedTime time = RecordedTime.capture(now); // §12.5 provenance

    try {
      final int id = await _db.transaction(() async {
        final SeasonId season = await _currentSeason();

        final int treatment = await _db
            .into(_db.treatments)
            .insert(
              TreatmentsCompanion.insert(
                uid: newUid(),
                createdAt: now,
                updatedAt: now,
                season: season.value,
                ewe: Value<int?>(switch (subject) {
                  TreatEwe(:final EweId ewe) => ewe.value,
                  TreatLamb() => null,
                }),
                lamb: Value<int?>(switch (subject) {
                  TreatLamb(:final LambId lamb) => lamb.value,
                  TreatEwe() => null,
                }),
                productName: productName,
                doseText: Value<String?>(doseText),
                route: Value<String?>(routeKey),
                batchNo: Value<String?>(batchNo),
                administeredAt: time.effective,
                capturedAt: time.capturedAt,
                timeSource: Value<String>(time.source.key),
              ),
            );

        for (final WithdrawalPeriod period in withdrawals) {
          switch (period) {
            // NOT RECORDED WRITES NOTHING, and it is silently skipped rather
            // than rejected: a caller assembling a list from two optional fields
            // should not have to filter, and the skip is the same statement the
            // absence of a row makes.
            case WithdrawalNotRecorded():
              continue;

            // NOT APPLICABLE IS A RECORDED FACT — the label says none applies —
            // and it is NOT the same as nobody writing a number. It stores a row
            // with a null `days`, which the CHECK permits only for this kind.
            case WithdrawalNotApplicable(:final WithdrawalTarget target):
              await _db
                  .into(_db.treatmentWithdrawals)
                  .insert(
                    TreatmentWithdrawalsCompanion.insert(
                      uid: newUid(),
                      createdAt: now,
                      updatedAt: now,
                      treatment: treatment,
                      target: target.key,
                      kind: 'not_applicable',
                    ),
                  );

            case WithdrawalDays(:final int days, :final WithdrawalTarget target):
              // THE CLEAR DATE IS STORED, NOT RECOMPUTED ON READ. It is what the
              // shepherd was told on the day, and recomputing it later against a
              // changed clock or a changed zone would silently move a date they
              // may have written in a book.
              final WithdrawalStatus status = computeWithdrawalStatus(
                administeredAt: time.effective,
                period: period,
              );
              await _db
                  .into(_db.treatmentWithdrawals)
                  .insert(
                    TreatmentWithdrawalsCompanion.insert(
                      uid: newUid(),
                      createdAt: now,
                      updatedAt: now,
                      treatment: treatment,
                      target: target.key,
                      kind: 'days',
                      days: Value<int?>(days),
                      clearDate: Value<LocalDate?>(switch (status) {
                        ClearsOn(:final LocalDate date) => date,
                        // Unreachable: `WithdrawalDays` always clears on a date.
                        // Named rather than defaulted, so a fourth status is a
                        // compile error instead of a null date.
                        WithdrawalUnknown() || NoWithdrawal() => null,
                      }),
                    ),
                  );
          }
        }

        return treatment;
      });
      return WriteCommitted(insertedId: id);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// The treatments list, in one statement, **for one mode**.
  ///
  /// **TWO MODES, NOT THREE.** The plan counted the log and the medicine book
  /// separately; `07 §10` says two segments and `indelible.md §8` screen 8 says
  /// *"the medicine book is not a separate view — it is the book filtered to
  /// treatments"*. A third member would need a third arm in the bound
  /// statement, which `§1.2`'s one-query rule forbids.
  ///
  /// **THE BOOK SHOWS VOIDED ROWS; THE COUNTDOWN DOES NOT.** That is the whole
  /// difference, and it is the §12.3 shape: a voided treatment may already be
  /// printed in a book handed to a vet, so the book keeps it and marks it —
  /// while the countdown is about what is still running, and a voided treatment
  /// is not.
  ///
  /// Leaving the countdown is NOT the same as claiming the animal is clear, and
  /// nothing here says the second.
  Stream<List<TreatmentRow>> watchTreatments(TreatmentMode mode) => _db
      .customSelect(
        _treatmentsSql,
        // BOUND THREE TIMES, ONCE PER `?`. The statement is still one statement
        // with the mode bound rather than branched; SQLite has no named
        // parameters through `customSelect`, so the same value is supplied for
        // each occurrence.
        variables: <Variable<Object>>[
          Variable<String>(mode.key),
          Variable<String>(mode.key),
          Variable<String>(mode.key),
        ],
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.treatments,
          _db.treatmentWithdrawals,
          _db.ewes,
          _db.lambs,
        },
      )
      .watch()
      .map(_foldByTreatment);

  /// The fan-out, folded — **in first-seen order, never re-sorted**.
  ///
  /// A `LinkedHashMap` and not a `groupBy` into a fresh list: the statement has
  /// already ordered the rows (by clear date in the countdown, by time in the
  /// book) and re-sorting in Dart would be a second ordering to keep in step
  /// with the first.
  static List<TreatmentRow> _foldByTreatment(List<QueryRow> rows) {
    final Map<int, QueryRow> firstSeen = <int, QueryRow>{};
    final Map<int, List<StoredWithdrawal>> periods = <int, List<StoredWithdrawal>>{};

    for (final QueryRow r in rows) {
      final int id = r.read<int>('id');
      firstSeen[id] ??= r;
      final List<StoredWithdrawal> list = periods[id] ??= <StoredWithdrawal>[];

      // A LEFT JOIN, so a treatment with no withdrawal at all still arrives —
      // with a null target. **That is `WithdrawalNotRecorded` and it is a fact**,
      // so the row is kept and its list stays empty. Skipping it here is how the
      // book would lose the one treatment an inspector is looking for.
      if (r.readNullable<String>('withdrawal_target') case final String target) {
        list.add(
          StoredWithdrawal(
            target: WithdrawalTarget.fromKey(target),
            days: r.readNullable<int>('withdrawal_days'),
            // READ, NEVER DERIVED — the whole point of the column. A
            // recomputation here would answer differently after the device
            // moved timezone, silently, on the one number that matters.
            clearDate: r.readNullable<String>('clear_date') == null
                ? null
                : LocalDate.parse(r.read<String>('clear_date')),
          ),
        );
      }
    }

    return <TreatmentRow>[
      for (final MapEntry<int, QueryRow> e in firstSeen.entries)
        TreatmentRow(
          id: TreatmentId(e.key),
          productName: e.value.read<String>('product_name'),
          doseText: e.value.readNullable<String>('dose_text'),
          batchNo: e.value.readNullable<String>('batch_no'),
          animalTag: e.value.readNullable<String>('animal_tag'),
          administeredAt: Instant(e.value.read<int>('administered_at')),
          voidedAt: e.value.readNullable<int>('voided_at') == null
              ? null
              : Instant(e.value.read<int>('voided_at')),
          // UNMODIFIABLE, because the fold is the only writer and a caller who
          // could append to it would be adding a withdrawal to a treatment
          // without going through the repository — the one path §12.1's
          // mechanisms all sit on.
          withdrawals: List<StoredWithdrawal>.unmodifiable(periods[e.key]!),
        ),
    ];
  }

  /// Voids a treatment. **A SOFT VOID: the row stays, and so does its
  /// withdrawal.**
  ///
  /// The obvious implementation deletes. It is wrong for a reason that has
  /// nothing to do with tidiness: the treatment may ALREADY HAVE BEEN PRINTED
  /// INTO A MEDICINE BOOK and handed to a vet, and a book that disagrees with
  /// the app is worse than either alone. `09 §3.2` exports voided rows marked
  /// as voided for exactly that.
  ///
  /// **THE WITHDRAWAL ROW IS NOT TOUCHED — not deleted, not blanked, not
  /// recalculated.** Its `days` are what the shepherd typed and its `clear_date`
  /// is what they were told; a void says the treatment should not have been
  /// recorded, not that those numbers were never read.
  ///
  /// Every *"is she clear?"* query filters `voided_at IS NULL` UPSTREAM, which is
  /// where the exclusion belongs: leaving the countdown is not the same as
  /// claiming the animal is clear, and no screen may say the second.
  Future<WriteOutcome> voidTreatment(TreatmentId treatment) async {
    try {
      final Instant now = appNow();
      final int rows =
          await (_db.update(
            _db.treatments,
          )..where(($TreatmentsTable t) => t.id.equals(treatment.value))).write(
            TreatmentsCompanion(voidedAt: Value<Instant?>(now), updatedAt: Value<Instant>(now)),
          );
      return WriteCommitted(insertedId: rows > 0 ? treatment.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// The most recent treatment for the current season, or `null`.
  ///
  /// What *repeat last* offers. It carries the product, the dose, the route and
  /// the batch — **and never the withdrawal period**, which is `withdrawalFor`'s
  /// to answer separately and deliberately.
  /// **RETURNS `TreatmentRow`, NOT THE DRIFT CLASS.** `lib/features/` may not
  /// import the database directory at all, so a verb handing back a generated
  /// row type is a verb no screen can call — the same layer rule that put
  /// `LambCardData` and `VocabEntry` in this layer.
  Future<TreatmentRow?> lastTreatment() async {
    final Treatment? row = await _lastTreatmentRow();
    if (row == null) {
      return null;
    }
    return TreatmentRow(
      id: TreatmentId(row.id),
      productName: row.productName,
      doseText: row.doseText,
      batchNo: row.batchNo,
      // NOT JOINED HERE. The repeat sheet shows the PRODUCT and the previous
      // period; which animal it was on last time is not what the shepherd is
      // choosing, and joining for it would be a second read for a fact nobody
      // reads.
      animalTag: null,
      administeredAt: row.administeredAt,
      voidedAt: row.voidedAt,
      // **READ, NOT LEFT EMPTY**, and that is not a convenience. An empty list
      // is `WithdrawalNotRecorded` on this type — it is the whole reason the
      // field is a list — so a constructor that passed `const []` because it had
      // not looked would be stating a §12.1 fact it never checked. The verb
      // costs one indexed select on the foreign key.
      //
      // Reading them is not copying them: *repeat last* still writes no period,
      // which is `withdrawalFor`'s to answer separately and deliberately.
      withdrawals: await _withdrawalsOf(TreatmentId(row.id)),
    );
  }

  /// The stored withdrawals for one treatment, mapped once.
  ///
  /// The map lives here rather than being spelled twice: [watchWithdrawals]
  /// streams it and [lastTreatment] awaits it, and two copies of the
  /// `not_applicable`-means-`days == null` reading is two places to get §12.1
  /// wrong.
  Future<List<StoredWithdrawal>> _withdrawalsOf(TreatmentId treatment) async =>
      _mapWithdrawals(
        await (_db.select(_db.treatmentWithdrawals)
              ..where(($TreatmentWithdrawalsTable t) => t.treatment.equals(treatment.value)))
            .get(),
      );

  static List<StoredWithdrawal> _mapWithdrawals(List<TreatmentWithdrawal> rows) =>
      <StoredWithdrawal>[
        for (final TreatmentWithdrawal r in rows)
          StoredWithdrawal(
            target: WithdrawalTarget.fromKey(r.target),
            days: r.days,
            // READ, NEVER DERIVED. The whole point of the column.
            clearDate: r.clearDate,
          ),
      ];

  Future<Treatment?> _lastTreatmentRow() =>
      (_db.select(_db.treatments)
            ..where(($TreatmentsTable t) => t.voidedAt.isNull())
            ..orderBy(<OrderClauseGenerator<$TreatmentsTable>>[
              ($TreatmentsTable t) =>
                  OrderingTerm(expression: t.administeredAt, mode: OrderingMode.desc),
              ($TreatmentsTable t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// Repeats [previous] onto another animal.
  ///
  /// **THE WITHDRAWAL PERIOD IS NOT COPIED, AND THAT IS THE WHOLE TASK.** It is
  /// tempting: the shepherd is holding the same bottle, so the same number
  /// applies. But copying it would make the app the SOURCE of a clinical figure
  /// for a treatment nobody read a label for — §12.1's exact prohibition — and
  /// the copy would be indistinguishable, on disk and on screen, from a number
  /// they typed.
  ///
  /// So the new treatment carries the product, the dose, the route and the
  /// batch, and its withdrawal is **not recorded** until the shepherd says
  /// otherwise. The previous entry is SHOWN with `Disclaimers.withdrawalProvenance`
  /// beside it, so they can read what they entered last time and decide.
  Future<WriteOutcome> repeatTreatment(TreatmentId previous, TreatmentSubject onto) async {
    final Treatment row = await (_db.select(
      _db.treatments,
    )..where(($TreatmentsTable t) => t.id.equals(previous.value))).getSingle();

    return recordTreatment(
      onto,
      productName: row.productName,
      doseText: row.doseText,
      routeKey: row.route,
      batchNo: row.batchNo,
      // EMPTY, EXPLICITLY. Not the previous treatment's periods, and not a
      // default.
      withdrawals: const <WithdrawalPeriod>[],
    );
  }

  /// Every withdrawal on a treatment, **with the clear date exactly as stored**.
  ///
  /// **NOTHING RECOMPUTES IT.** The stored date is what the shepherd was told on
  /// the day; a screen that recalculated on build would silently move a date
  /// they may have written in a book and handed to a vet — and it would move it
  /// for the one reason nobody would think to look for, a device that changed
  /// timezone between the write and the read.
  ///
  /// `05 §6.9` says the same thing about `local_date` and for the same reason:
  /// a stored civil date is a record of the day as it was lived.
  Stream<List<StoredWithdrawal>> watchWithdrawals(TreatmentId treatment) =>
      (_db.select(
        _db.treatmentWithdrawals,
      )..where(($TreatmentWithdrawalsTable t) => t.treatment.equals(treatment.value))).watch().map(
        _mapWithdrawals,
      );

  /// The period recorded for one target, or [WithdrawalNotRecorded].
  ///
  /// **NO ROW IS THE ANSWER, NOT A MISSING ANSWER.** This is where §12.1 becomes
  /// readable: the caller cannot get a `0` back from a treatment nobody entered a
  /// period for, because there is nothing to read a zero from.
  Future<WithdrawalPeriod> withdrawalFor(TreatmentId treatment, WithdrawalTarget target) async {
    final TreatmentWithdrawal? row =
        await (_db.select(_db.treatmentWithdrawals)..where(
              ($TreatmentWithdrawalsTable t) =>
                  t.treatment.equals(treatment.value) & t.target.equals(target.key),
            ))
            .getSingleOrNull();

    if (row == null) {
      //  CARRIES NO TARGET, and that is the type being
      // precise: nothing was recorded, so there is nothing target-shaped to
      // record it against. The caller already knows which target it asked about.
      return const WithdrawalNotRecorded();
    }
    return switch (row.kind) {
      'not_applicable' => WithdrawalNotApplicable(target),
      'days' => WithdrawalDays.asEnteredByUser(days: row.days!, target: target),
      _ => throw FormatException('Unknown withdrawal kind', row.kind),
    };
  }

  /// **NAMED `_currentSeason`, NOT `_seasonOf(subject)`.** It was the second,
  /// and the signature was a lie: the body never read the subject. It returns
  /// the CURRENT season, not the season the animal belongs to — and a name that
  /// promised derivation is how that divergence would have stayed invisible.
  /// `lambing_repository` and `foster_repository` answer the OTHER question
  /// (`_seasonOfLamb`), and which one a treatment should use is an open ruling.
  Future<SeasonId> _currentSeason() async {
    final AppSetting settings = await (_db.select(
      _db.appSettings,
    )..where(($AppSettingsTable t) => t.id.equals(1))).getSingle();
    final int? current = settings.currentSeason;
    if (current == null) {
      throw StateError('no current season');
    }
    return SeasonId(current);
  }
}

/// One stored withdrawal, as the screen renders it.
///
/// **[clearDate] IS READ, NEVER DERIVED.** It is the date the shepherd was told
/// on the day the medicine went in, and the reason it is a column rather than a
/// computation is that a computation would answer differently after a device
/// moved timezone — silently, and for a row nobody would think to re-check.
final class StoredWithdrawal {
  const StoredWithdrawal({required this.target, required this.days, required this.clearDate});

  final WithdrawalTarget target;

  /// `null` on a `not_applicable` row. It is not zero: nothing applies is not
  /// the same as zero days.
  final int? days;

  /// `null` on a `not_applicable` row — there is nothing to clear.
  final LocalDate? clearDate;
}

/// The two segments `07 §10.1`'s statement binds into `:mode`.
enum TreatmentMode {
  countdown('countdown'),
  book('book');

  const TreatmentMode(this.key);

  /// Bound into the statement. **Frozen, never localised.**
  final String key;
}

/// One row of the treatments list.
final class TreatmentRow {
  const TreatmentRow({
    required this.id,
    required this.productName,
    required this.doseText,
    required this.batchNo,
    required this.animalTag,
    required this.administeredAt,
    required this.voidedAt,
    required this.withdrawals,
  });

  final TreatmentId id;
  final String productName;
  final String? doseText;
  final String? batchNo;

  /// The ewe's or the lamb's tag. `null` on an untagged lamb, which is most
  /// lambs for most of their first week.
  final String? animalTag;

  final Instant administeredAt;

  /// Non-null on a voided row. **The book renders these struck and keeps them**;
  /// the countdown never sees them at all.
  final Instant? voidedAt;

  /// This treatment's stored withdrawals, **one entry per row that exists**.
  ///
  /// **EMPTY IS `WithdrawalNotRecorded`, AND THAT IS WHY THIS IS A LIST RATHER
  /// THAN A DATE.** It replaced a `LocalDate? earliestClearDate`, whose own doc
  /// comment admitted the defect — *"`null` when nothing was recorded or nothing
  /// applies"* — and the screen then printed one sentence for both. A shepherd
  /// who read the bottle and chose NONE APPLIES saw the words for a gap nobody
  /// had filled. That is precisely the merge §12.1 exists to prevent, arriving
  /// one layer above the schema that prevents it: `treatment_withdrawals` keeps
  /// the three states apart with `kind` and a missing row, and the read path
  /// collapsed them again.
  ///
  /// [StoredWithdrawal] already carries the distinction the schema does — a
  /// `not_applicable` row has `days == null` under
  /// `CHECK ((kind = 'days') = (days IS NOT NULL))` — so no fourth field is
  /// needed to tell the three apart.
  final List<StoredWithdrawal> withdrawals;
}

/// `07 §10.1`'s statement, with the mode bound rather than branched.
///
/// **ONE STATEMENT AND ONE DEPENDENCY LIST.** Two statements — one per mode —
/// would be two lists that can disagree about when the screen is stale, and a
/// screen that went stale in one mode only is the hardest kind of bug to
/// believe.
/// **IT FANS OUT AND THE REPOSITORY FOLDS IT**, which `07 §10.1` says in as many
/// words. One product routinely prints a meat figure and a milk figure, so a
/// treatment with both targets returns two rows and the join is the only way to
/// see them. The previous statement used `MIN(clear_date)` in a scalar subquery,
/// which is a fold done in SQL — and a fold that throws away the two facts the
/// screen has to tell apart.
///
/// The fold is in Dart, over one stream. That is not stream combination, so the
/// one-query rule (`§1.2`) still holds.
///
/// **`w.kind = 'days'` IS THE COUNTDOWN'S WHOLE FILTER.** A treatment nobody
/// recorded a period for has no number to count down, so it is not in the
/// running list; it appears in the book saying so, which is where an inspector
/// would look for it.
const String _treatmentsSql = '''
SELECT t.id, t.product_name, t.dose_text, t.batch_no,
       t.administered_at, t.voided_at,
       COALESCE(e.tag, l.tag) AS animal_tag,
       w.target AS withdrawal_target, w.days AS withdrawal_days,
       w.clear_date AS clear_date
  FROM treatments t
  LEFT JOIN treatment_withdrawals w ON w.treatment = t.id
  LEFT JOIN ewes  e ON e.id = t.ewe
  LEFT JOIN lambs l ON l.id = t.lamb
 WHERE (? = 'book')
    OR (t.voided_at IS NULL AND w.kind = 'days')
 ORDER BY CASE WHEN ? = 'book'      THEN t.administered_at END DESC,
          CASE WHEN ? = 'countdown' THEN w.clear_date      END ASC,
          t.id, w.target
''';
