// test/data/treatment_repository_test.dart
//
// SAFETY RULE §12.1: never default a medicine withdrawal period. This file is
// where that stops being a sentence.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  late AppDatabase db;
  late TreatmentRepository repo;

  setUp(() async {
    db = testDatabase();
    repo = TreatmentRepository(db);
    await seedSeason(db);
  });

  test('recordTreatment writes no withdrawal row when the user entered none', () async {
    // THE ANCHOR, AND THE LAST ASSERTION IS THE ONE THAT MATTERS.
    //
    // Counting rows says the app did not write one. Reading the period back says
    // ABSENCE IS THE STATE — which is the claim §12.1 actually makes, and the
    // one a caller depends on. A nullable `withdrawal_days` column could not
    // carry it: `0` is a real label value, so "the label says zero days" and
    // "nobody wrote a number down" would be the same value.
    //
    // Called with an EMPTY LIST — not with a `WithdrawalNotRecorded` in it and
    // not with a null. Not recorded is the absence of an entry.
    final EweId ewe = await seedEwe(db, tag: '412');

    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: const <WithdrawalPeriod>[],
    );

    expect(outcome, isA<WriteCommitted>());
    final int id = (outcome as WriteCommitted).insertedId!;

    expect(await db.select(db.treatments).get(), hasLength(1));
    expect(
      await db.select(db.treatmentWithdrawals).get(),
      isEmpty,
      reason: 'no row, because nobody typed a number off a bottle',
    );

    expect(
      await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.meat),
      isA<WithdrawalNotRecorded>(),
      reason: 'absence IS the state — a caller cannot read a zero that is not there',
    );
    expect(
      await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.milk),
      isA<WithdrawalNotRecorded>(),
    );
  });

  test('a WithdrawalNotRecorded in the list writes nothing', () async {
    // THE DEFENSIVE BRANCH, AND IT NEEDED ITS OWN CASE. The anchor passes an
    // EMPTY list, so the `continue` that skips a not-recorded entry was never
    // executed — drilled, and turning that skip into a zero-day insert passed
    // every other case in this file.
    //
    // The branch exists because a caller assembling the list from two optional
    // fields should not have to filter, and the skip is the same statement the
    // absence of a row makes. It must stay a skip.
    final EweId ewe = await seedEwe(db, tag: '412');

    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: const <WithdrawalPeriod>[
        WithdrawalNotRecorded(),
        WithdrawalNotApplicable(WithdrawalTarget.milk),
      ],
    );
    final int id = (outcome as WriteCommitted).insertedId!;

    expect(
      await db.select(db.treatmentWithdrawals).get(),
      hasLength(1),
      reason: 'the not-applicable one, and nothing for the not-recorded one',
    );
    expect(
      await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.meat),
      isA<WithdrawalNotRecorded>(),
    );
  });

  test('zero days is a recorded period and not the same as none', () async {
    // "THE LABEL SAYS ZERO DAYS" AND "NOBODY WROTE A NUMBER DOWN" ARE DIFFERENT
    // FACTS. This is the case a nullable int cannot pass, and the reason the
    // child table exists at all.
    final EweId ewe = await seedEwe(db, tag: '412');

    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 0, target: WithdrawalTarget.meat),
      ],
    );
    final int id = (outcome as WriteCommitted).insertedId!;

    final WithdrawalPeriod meat = await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.meat);
    expect(meat, isA<WithdrawalDays>());
    expect((meat as WithdrawalDays).days, 0);

    // AND THE OTHER TARGET IS STILL NOT RECORDED. One entered period does not
    // imply anything about the other.
    expect(
      await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.milk),
      isA<WithdrawalNotRecorded>(),
    );
  });

  test('not applicable is a recorded fact, stored with a null days', () async {
    // THE LABEL SAYS NONE APPLIES — which is something the shepherd read and
    // recorded, not something nobody said. It stores a row, and the CHECK
    // permits a null `days` only for this kind.
    final EweId ewe = await seedEwe(db, tag: '412');

    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.milk)],
    );
    final int id = (outcome as WriteCommitted).insertedId!;

    final TreatmentWithdrawal row = await db.select(db.treatmentWithdrawals).getSingle();
    expect(row.kind, 'not_applicable');
    expect(row.days, isNull);
    expect(row.clearDate, isNull, reason: 'nothing to clear');

    expect(
      await repo.withdrawalFor(TreatmentId(id), WithdrawalTarget.milk),
      isA<WithdrawalNotApplicable>(),
    );
  });

  test('the clear date is stored, not recomputed on read', () async {
    // IT IS WHAT THE SHEPHERD WAS TOLD ON THE DAY. Recomputing it later against
    // a changed clock or a changed device zone would silently move a date they
    // may have written in a book and handed to a vet.
    final EweId ewe = await seedEwe(db, tag: '412');

    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );
    final int id = (outcome as WriteCommitted).insertedId!;

    final TreatmentWithdrawal row = await db.select(db.treatmentWithdrawals).getSingle();
    expect(row.days, 28);
    expect(row.clearDate, isNotNull, reason: 'computed once, at the moment it was recorded');

    final Treatment treatment = await (db.select(
      db.treatments,
    )..where(($TreatmentsTable t) => t.id.equals(id))).getSingle();
    expect(
      row.clearDate!.compareTo(LocalDate.of(treatment.administeredAt)),
      greaterThan(0),
      reason: '28 days after, not the day of',
    );
  });

  test('a treatment names exactly one animal', () async {
    // `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)`, and `TreatmentSubject`
    // is sealed for the same reason `CareSubject` is: two nullable ids make both
    // unstorable combinations constructible, and the CHECK then fires at 03:20
    // instead of at compile time.
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await repo.recordTreatment(TreatEwe(ewe), productName: 'Alamycin');
    await repo.recordTreatment(TreatLamb(lamb), productName: 'Spectam');

    final List<Treatment> rows = await db.select(db.treatments).get();
    final Treatment forEwe = rows.firstWhere((Treatment t) => t.productName == 'Alamycin');
    final Treatment forLamb = rows.firstWhere((Treatment t) => t.productName == 'Spectam');

    expect(forEwe.ewe, ewe.value);
    expect(forEwe.lamb, isNull);
    expect(forLamb.lamb, lamb.value);
    expect(forLamb.ewe, isNull);
  });

  test('the clear date is read exactly as stored, never recomputed', () async {
    // N20-T03'S ANCHOR, AND THE ASSERTION IS NOT "THE DATE IS RIGHT" — IT IS
    // "THE DATE IS THE STORED ONE". Those differ in precisely the case that
    // matters.
    //
    // `TZ` cannot be changed inside a running Dart process, so the CONSEQUENCE
    // is seeded instead: a stored `clear_date` that does NOT match what today's
    // arithmetic would produce is exactly the row a device that moved zone
    // leaves behind. A screen that recomputes on build renders the other date,
    // and a shepherd who wrote the first one in a book is now holding a
    // different answer from the app.
    final EweId ewe = await seedEwe(db, tag: '412');
    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );
    final TreatmentId treatment = TreatmentId((outcome as WriteCommitted).insertedId!);

    final TreatmentWithdrawal computed = await db.select(db.treatmentWithdrawals).getSingle();
    final LocalDate asComputed = computed.clearDate!;
    final LocalDate asStored = asComputed.plusDays(-1);

    await (db.update(db.treatmentWithdrawals)
          ..where(($TreatmentWithdrawalsTable t) => t.id.equals(computed.id)))
        .write(TreatmentWithdrawalsCompanion(clearDate: Value<LocalDate?>(asStored)));

    final List<StoredWithdrawal> read = await repo.watchWithdrawals(treatment).first;

    expect(read, hasLength(1));
    expect(read.single.clearDate, asStored, reason: 'the stored one');
    expect(
      read.single.clearDate,
      isNot(asComputed),
      reason: 'and NOT what recomputing would produce',
    );
    expect(read.single.days, 28, reason: 'the shepherd\'s own number, unchanged');
  });

  test('a not-applicable withdrawal has no days and no clear date', () async {
    // NULL DAYS IS NOT ZERO DAYS, and null clear date is not "clears today".
    // Nothing applies, so there is nothing to count and nothing to clear.
    final EweId ewe = await seedEwe(db, tag: '412');
    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.milk)],
    );

    final List<StoredWithdrawal> read = await repo
        .watchWithdrawals(TreatmentId((outcome as WriteCommitted).insertedId!))
        .first;

    expect(read.single.target, WithdrawalTarget.milk);
    expect(read.single.days, isNull);
    expect(read.single.clearDate, isNull);
  });

  test('repeating a treatment copies the product but never the withdrawal days', () async {
    // THE WHOLE TASK IS THE SECOND HALF OF THAT SENTENCE, and it is tempting to
    // get wrong: the shepherd is holding the same bottle, so surely the same
    // number applies.
    //
    // Copying it would make the APP the source of a clinical figure for a
    // treatment nobody read a label for — §12.1's exact prohibition — and the
    // copy would be indistinguishable, on disk and on screen, from a number they
    // typed. The previous entry is SHOWN so they can read it and decide; it is
    // not written for them.
    final EweId first = await seedEwe(db, tag: '412');
    final EweId second = await seedEwe(db, tag: '128');

    await repo.recordTreatment(
      TreatEwe(first),
      productName: 'Alamycin LA',
      doseText: '3 ml',
      batchNo: 'B7734',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );

    final TreatmentRow? previous = await repo.lastTreatment();
    expect(previous, isNotNull);

    final WriteOutcome outcome = await repo.repeatTreatment(previous!.id, TreatEwe(second));
    expect(outcome, isA<WriteCommitted>());
    final TreatmentId repeated = TreatmentId((outcome as WriteCommitted).insertedId!);

    // THE PRODUCT, THE DOSE AND THE BATCH COME ACROSS. Those are facts about the
    // bottle in their hand, not clinical decisions.
    final Treatment row = await (db.select(
      db.treatments,
    )..where(($TreatmentsTable t) => t.id.equals(repeated.value))).getSingle();
    expect(row.productName, 'Alamycin LA');
    expect(row.doseText, '3 ml');
    expect(row.batchNo, 'B7734');
    expect(row.ewe, second.value);

    // AND THE WITHDRAWAL DOES NOT. Still one row in the whole table — the
    // original's.
    expect(
      await db.select(db.treatmentWithdrawals).get(),
      hasLength(1),
      reason: 'the repeat wrote none',
    );
    expect(
      await repo.withdrawalFor(repeated, WithdrawalTarget.meat),
      isA<WithdrawalNotRecorded>(),
      reason: 'not recorded until the shepherd says otherwise',
    );
  });

  test('lastTreatment skips voided rows', () async {
    // A VOIDED TREATMENT IS NOT WHAT THEY DID LAST. The row stays — it may
    // already have been printed into a medicine book — but offering it as the
    // one to repeat would be offering to repeat a mistake.
    final EweId ewe = await seedEwe(db, tag: '412');

    await repo.recordTreatment(TreatEwe(ewe), productName: 'Alamycin');
    await repo.recordTreatment(TreatEwe(ewe), productName: 'Spectam');

    final TreatmentRow latest = (await repo.lastTreatment())!;
    expect(latest.productName, 'Spectam');

    await (db.update(db.treatments)..where(($TreatmentsTable t) => t.id.equals(latest.id.value)))
        .write(TreatmentsCompanion(voidedAt: Value<Instant?>(appNow())));

    expect((await repo.lastTreatment())!.productName, 'Alamycin');
  });

  test('a voided treatment keeps its row and its withdrawal untouched', () async {
    // THE OBVIOUS IMPLEMENTATION DELETES, and it is wrong for a reason that has
    // nothing to do with tidiness: the treatment may ALREADY HAVE BEEN PRINTED
    // INTO A MEDICINE BOOK and handed to a vet, and a book that disagrees with
    // the app is worse than either alone.
    //
    // The withdrawal row is not touched either — not deleted, not blanked, not
    // recalculated. Its days are what the shepherd typed and its clear date is
    // what they were told; a void says the treatment should not have been
    // RECORDED, not that those numbers were never read.
    final EweId ewe = await seedEwe(db, tag: '412');
    final WriteOutcome outcome = await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );
    final TreatmentId id = TreatmentId((outcome as WriteCommitted).insertedId!);

    final TreatmentWithdrawal before = await db.select(db.treatmentWithdrawals).getSingle();

    expect(await repo.voidTreatment(id), isA<WriteCommitted>());

    final Treatment treatment = await (db.select(
      db.treatments,
    )..where(($TreatmentsTable t) => t.id.equals(id.value))).getSingle();
    expect(treatment.voidedAt, isNotNull, reason: 'marked, not removed');

    final TreatmentWithdrawal after = await db.select(db.treatmentWithdrawals).getSingle();
    expect(after.days, before.days, reason: 'what they typed');
    expect(after.clearDate, before.clearDate, reason: 'what they were told');
    expect(after.kind, before.kind);

    // AND THE PERIOD STILL READS BACK. A void does not un-record a number.
    expect(await repo.withdrawalFor(id, WithdrawalTarget.meat), isA<WithdrawalDays>());
  });
}
