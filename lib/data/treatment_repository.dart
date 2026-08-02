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
        final SeasonId season = await _seasonOf(subject);

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

  /// The most recent treatment for the current season, or `null`.
  ///
  /// What *repeat last* offers. It carries the product, the dose, the route and
  /// the batch — **and never the withdrawal period**, which is `withdrawalFor`'s
  /// to answer separately and deliberately.
  Future<Treatment?> lastTreatment() =>
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
  Future<WriteOutcome> repeatTreatment(Treatment previous, TreatmentSubject onto) =>
      recordTreatment(
        onto,
        productName: previous.productName,
        doseText: previous.doseText,
        routeKey: previous.route,
        batchNo: previous.batchNo,
        // EMPTY, EXPLICITLY. Not `previous`'s periods, and not a default.
        withdrawals: const <WithdrawalPeriod>[],
      );

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
        (List<TreatmentWithdrawal> rows) => <StoredWithdrawal>[
          for (final TreatmentWithdrawal r in rows)
            StoredWithdrawal(
              target: WithdrawalTarget.values.firstWhere((WithdrawalTarget t) => t.key == r.target),
              days: r.days,
              // READ, NEVER DERIVED. The whole point of the column.
              clearDate: r.clearDate,
            ),
        ],
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

  Future<SeasonId> _seasonOf(TreatmentSubject subject) async {
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
