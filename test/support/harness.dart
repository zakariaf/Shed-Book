// test/support/harness.dart — the shared test seams (12 §2.1, §3.1, §5.1).
//
// The one way a test gets a database, a container and a pumped tree.
// 02 §5.4 owns the override RULES; 12 §5 owns this harness.
//
// It grows, it does not fork. N07-T02 wrapped [testConnection] in
// `testDatabase({bool seedOnCreate = true})` once AppDatabase existed; a second
// harness entry point is how two tests end up disagreeing about what "a fresh
// database" means. N12-T05 added [Device], [shedContainer], [freshSupportDir]
// and [PumpApp] beside them.
//
// THIS IS THE MOST-COPIED FILE IN THE PROJECT. Roughly 250 widget tests enter
// through pumpApp, including all 252 overflow-matrix cells and all eight
// goldens, so every comment here is read more often than any comment in lib/.
//
// ---------------------------------------------------------------------------
// WHAT IS DELIBERATELY ABSENT, AND WHERE IT LANDS (critique defect S1)
// ---------------------------------------------------------------------------
//
//   the seven gateway fakes (12 §4.2) — each lands in the epic that writes its
//   gateway, and extends shedContainer's override list in the SAME commit:
//     FakeMediaStore · FakeCameraService · FakeVoiceRecorder      N15
//     FakeShareService                                            N21 — DONE, T06
//     FakeNotificationScheduler                                   N24
//     FakeWakelockController                                      N29
//     FakePurchaseService (the store seam, R74)                   N30
//

//   restoreFixture / flock_400_3seasons.json (12 §5.2, critique defect S3) —
//     fixtures go through RestoreService, which is N23, and tool/seed.dart
//     writes them through the restore path in the same epic. Until then every
//     test seeds with the targeted helpers in seeds.dart. The switch is
//     N23-T05, "the two committed fixtures and the matrix switch". (N13-T07's
//     own text says N23-T06; that is `restoreInto` and `freshSupportDir`, which
//     is a different task. Corrected here.)
//
//   the four fixture id constants (12 §5.3) — they index into the fixture and
//     are meaningless without it: N23.
//
// An optional `share:` parameter that overrides nothing is WORSE than no
// parameter, because it silently accepts a fake and the test passes for the
// wrong reason. Add each one with its provider, never before.
library;

import 'dart:io';
import 'package:shed_book/data/restore_service.dart';
import 'package:shed_book/data/backup_format.dart';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/l10n/app_localizations.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/features/treatments/treatments_screen.dart';
import 'package:shed_book/features/export/export_screen.dart';
import 'package:shed_book/features/pens/pen_board_screen.dart';
import 'package:shed_book/features/lambing/foster_screen.dart';
import 'package:shed_book/features/lambing/lamb_card_screen.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/data/media_store.dart';
import 'fake_share_service.dart';
import 'seeds.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/routing/routes.dart';

/// Runs [body] with the ambient clock pinned to [instant].
///
/// 12 §2.1: pin `now` and offset the SEED DATA to the instant you want, rather
/// than asserting on a moving clock. A test that reads the real time is a test
/// that fails at midnight, in March, once.
///
/// **SINGLE-INSTANT ASSERTIONS ONLY.** `Clock.fixed` FREEZES `now()`, so nothing
/// that measures elapsed duration may run inside this callback. Wrap a pen-board
/// test in it and every "hours since penned" readout silently measures 0 h and
/// passes (decision #113). 12 §2.2's rule, verbatim:
///
/// > **In a widget test, either pin `now` or measure elapsed time. Never both.**
/// >
/// > - *"Does the tile read `9h`?"* — a single-instant assertion. Pin `now` with
/// >   `atFixed` and offset the **seed data** to the instant you want to be 9 h
/// >   earlier.
/// > - *"Does the tile flip from `23h` to `24h`?"* — an elapsed-time assertion.
/// >   Pin nothing. Seed `entered_at` at
/// >   `appNow().plus(const Duration(hours: -23, minutes: -59))` and call
/// >   `tester.pump(const Duration(minutes: 1))`.
///
/// The convention that keeps that readable: **every `atFixed` call in the widget
/// tier carries a comment saying why it is a single-instant assertion.**
///
/// In a widget test you install no clock at all unless you want the freeze — the
/// binding already runs the body inside a `FakeAsync` zone whose clock is
/// `package:clock`'s ambient clock, so `tester.pump(const Duration(hours: 25))`
/// really moves `appNow()`. `package:fake_async` is not a declared dependency.
T atFixed<T>(DateTime instant, T Function() body) => withClock(Clock.fixed(instant), body);

/// Every screen the overflow matrix, the semantics gate, the geometric half of
/// the tap-target gate and the contrast sampler pump (`12 §6.2`).
///
/// **THE TABLE LIVES HERE BECAUSE FOUR FILES ITERATE IT.** A table copied four
/// times is four tables that stop agreeing the first time a screen is added.
///
/// **One entry today, and the membership is DERIVED rather than asserted.**
/// N13-T07 lands `quick_entry` because that is the only screen that exists; each
/// screen epic adds its own row in the commit that adds the screen:
///
///   flock · ewe_card                                      N26, N27
///   lambing_entry                                         N16
///   lamb_card                                             N17
///   foster                                                N18
///   pen_board                                             N19
///   treatments                                            N20
///   reminders                                             N24
///   season_summary                                        N28
///   export                                                N21
///   settings                                              N29
///   note_search                                           N25
///
/// At fourteen the matrix is 252 cells (`12 §6.1`) and `12 §6.2`'s
/// `expect(kPumpableVariants.length, 14)` becomes true — **in N33-T01, not
/// here.** Writing that assertion today would be asserting a future.
///
/// The builders take no arguments and seed nothing: a cell pumps the screen and
/// looks for overflow, and the data it needs comes from `seeds.dart` until
/// **N23-T05** switches the matrix to the committed fixtures.
///
/// **THE ENTRY GAINED A SEEDER AT N16-T09, AND THAT IS A CHANGE TO THE TABLE'S
/// SHAPE.** Quick Entry pumps against an empty database and proves something;
/// Lambing Entry pumped against an empty database would render its loading arm
/// at every one of eighteen cells and prove nothing at all. So a variant is now
/// a builder AND a seeder, the seeder returns the arguments the builder needs,
/// and the table stays the single declaration four files read (`12 §6.2`).
const Map<String, PumpableVariant> kPumpableVariants = <String, PumpableVariant>{
  RouteNames.quickEntry: (seed: _seedNothing, build: _quickEntry),
  RouteNames.lambingEntry: (seed: _seedHardLambing, build: _lambingEntry),
  RouteNames.lambCard: (seed: _seedHardLamb, build: _lambCard),
  RouteNames.foster: (seed: _seedHardFoster, build: _foster),
  RouteNames.penBoard: (seed: _seedHardPenBoard, build: _penBoard),
  RouteNames.treatments: (seed: _seedHardTreatments, build: _treatments),
  RouteNames.export: (seed: _seedHardTreatments, build: _export),
  // **QUICK ENTRY WITH THE BANNER SHOWN** — a state, not a screen, and the one
  // in which the reachability assertion is most likely to fail. Keyed on the
  // banner's widget key rather than on a route name because it is not a route:
  // `12 §6.4` names the variant and `overflow_matrix_test.dart`'s membership
  // case allows it by shape.
  'quick_entry.export_banner': (seed: _seedArmedBanner, build: _quickEntry),
};

/// A matrix cell: what to put in the database, then what to pump.
///
/// `seed` returns the ids `build` needs. A record rather than two parallel maps,
/// because two maps are two things that stop agreeing the first time a screen is
/// added — which is the same argument that put this table in one file.
typedef PumpableVariant = ({
  Future<Map<String, int>> Function(AppDatabase db) seed,
  Widget Function(Map<String, int> ids) build,
});

Future<Map<String, int>> _seedNothing(AppDatabase db) async => <String, int>{};

Widget _quickEntry(Map<String, int> _) => const QuickEntryScreen();

/// **THE HARD STATE, NOT THE EASY ONE**, and N16-T09 is explicit about why: a
/// lambing with FIVE lambs exercises the five-bar tally gate, five lamb
/// sub-rows, the ease description printed beside a selected button, a query mark
/// in the margin and a two-line provenance header — all at once. An empty
/// lambing passes eighteen cells while proving almost nothing.
Future<Map<String, int>> _seedHardLambing(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
  final int season = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(season)),
  );

  final EweId ewe = await seedEwe(db, tag: '412');
  final LambingId lambing = await seedLambing(db, ewe);

  // A DECLARED TRIPLET WITH FIVE LAMBS — so the query mark renders too, and the
  // longest ease description sits beside a selected button. Every wide thing on
  // the screen is wide at once, which is the only arrangement that can overflow.
  await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
    LambingsCompanion(
      declaredBirthType: const Value<int?>(3),
      ease: const Value<int?>(4),
      presentation: const Value<String?>('mp_twins_together'),
      assistedBy: const Value<String?>('the vet and my daughter'),
      presentationNote: const Value<String?>('ropes, plenty of lubricant, vet out at 04:10'),
      note: const Value<String?>('big single-looking triplet, watched her all night'),
      originalEffective: Value<Instant?>(now),
      timeSource: const Value<String>('edited'),
    ),
  );
  for (int i = 0; i < 5; i++) {
    await seedLamb(
      db,
      lambing,
      ewe,
      sex: i.isEven ? 'f' : 'm',
      birthWeightG: 4100 + i,
      tag: 'A1$i',
    );
  }

  return <String, int>{'lambing': lambing.value};
}

Widget _lambingEntry(Map<String, int> ids) =>
    LambingEntryScreen(lambingId: LambingId(ids['lambing']!));

/// **THE HARD LAMB.** Every cell on the card populated at once: a tag, a sex, a
/// weight, a death with a date and a cause, pet-lamb status with a long feed
/// count, a foster onto a second ewe, and care and treatment rows in the
/// history. That is the arrangement where the summary line, the two parentage
/// rows, the status wrap and the feed row are all as wide as they can be — and
/// it is the only arrangement that can overflow.
///
/// A freshly-born lamb passes eighteen cells and proves almost nothing.
Future<Map<String, int>> _seedHardLamb(AppDatabase db) async {
  final Map<String, int> ids = await _seedHardLambing(db);
  final LambingId lambing = LambingId(ids['lambing']!);

  final Lamb lamb = (await (db.select(
    db.lambs,
  )..where(($LambsTable t) => t.lambing.equals(lambing.value))).get()).first;
  final EweId fosterDam = await seedEwe(db, tag: '1077');
  final Instant when = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5));

  await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.id))).write(
    LambsCompanion(
      tag: const Value<String?>('A12345'),
      status: const Value<String>('dead'),
      deathDate: Value<LocalDate?>(LocalDate(2026, 3, 20)),
      deathCause: const Value<String?>('dc_hypothermia'),
      petLamb: const Value<bool>(true),
      bottleFeeds: const Value<int>(128),
    ),
  );

  final Lambing parent = await (db.select(
    db.lambings,
  )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

  await db
      .into(db.fosterEvents)
      .insert(
        FosterEventsCompanion.insert(
          uid: newUid(),
          createdAt: when,
          updatedAt: when,
          lamb: lamb.id,
          season: parent.season,
          rearingDam: Value<int?>(fosterDam.value),
          outcome: 'to_ewe',
          effectiveAt: when,
          capturedAt: when,
        ),
      );
  await seedCareEvent(db, kind: 'warmed', lamb: LambId(lamb.id));

  return <String, int>{'lamb': lamb.id};
}

Widget _lambCard(Map<String, int> ids) => LambCardScreen(lambId: LambId(ids['lamb']!));

/// **THE HARD FOSTER.** The Foster screen's width comes from its match list, so
/// the seed puts SIX ewes in pens with tags that all share a prefix — every one
/// of them renders at once when a single digit is typed, and the longest of them
/// is a five-digit tag beside the longest label on the screen.
///
/// A lamb with an empty deck passes eighteen cells and proves nothing: the list
/// would be the no-match line, which is one short string.
Future<Map<String, int>> _seedHardFoster(AppDatabase db) async {
  final Map<String, int> ids = await _seedHardLamb(db);

  for (final String tag in <String>['40001', '40002', '40003', '40004', '40005', '40006']) {
    final EweId ewe = await seedEwe(db, tag: tag);
    final PenId pen = await seedPen(db, label: 'PEN $tag');
    // ONE EWE PER PEN — `pen_occupancies` has a UNIQUE on the pen, which is the
    // schema saying what a lambing pen is.
    await seedPenOccupancy(db, pen, ewe);
  }

  return ids;
}

Widget _foster(Map<String, int> ids) => FosterScreen(lambId: LambId(ids['lamb']!));

/// **THE HARD BOARD.** Twelve pens, because twelve is the width the grid has to
/// reflow at — and they are not all the same: one is empty, one holds an orphan
/// litter, one has a five-digit tag, and the rest hold ewes at different entry
/// times so the hours readouts differ.
///
/// A board of three identical tiles passes eighteen cells and proves nothing
/// about the wrap, which is the only thing on this screen that can overflow.
Future<Map<String, int>> _seedHardPenBoard(AppDatabase db) async {
  await seedSeason(db);
  final PenRepository repo = PenRepository(db);

  for (int i = 0; i < 12; i++) {
    await repo.addPen();
  }
  final List<Pen> pens = await db.select(db.pens).get();

  for (int i = 0; i < 10; i++) {
    final EweId ewe = await seedEwe(db, tag: i == 0 ? '40001' : '${400 + i}');
    await repo.enterPen(PenId(pens[i].id), ewe: ewe);
  }

  // AN ORPHAN LITTER in the eleventh — lambs with no ewe, which is a different
  // tile from the empty twelfth.
  final EweId dam = await seedEwe(db, tag: '900');
  final LambingId lambing = await seedLambing(db, dam);
  await repo.enterPen(
    PenId(pens[10].id),
    lambs: <LambId>[
      await seedLamb(db, lambing, dam),
      await seedLamb(db, lambing, dam),
      await seedLamb(db, lambing, dam),
    ],
  );

  return <String, int>{};
}

Widget _penBoard(Map<String, int> _) => const PenBoardScreen();

/// **THE HARD TREATMENTS LIST.** Eleven rows, and they are not all the same: one
/// is voided (struck, with its own stamp), one has a five-digit tag, one is on an
/// untagged lamb, one has no withdrawal at all, one says NONE APPLIES and the
/// rest carry clear dates. The widest combination is the only thing that can
/// overflow — a list of eleven identical rows proves nothing about it.
///
/// **EVERY WIDE ROW CARRIES A RUNNING PERIOD, AND THAT IS NOT DECORATION.** The
/// matrix pumps the screen's DEFAULT segment, which is the countdown, and
/// `07 §10.1`'s countdown arm holds only `kind = 'days'` rows. The long tag and
/// the untagged lamb had no period, so when the countdown started filtering they
/// silently left all eighteen cells — the widest two rows in the seed, covered by
/// nothing, with the matrix still green. They are given periods here so the cells
/// pump what the comment above claims they pump.
///
/// **What is still uncovered, and it is worth saying plainly:** the voided stamp
/// and the two absence words are BOOK rows, and the matrix has no way to pump a
/// screen in its non-default mode — `PumpableVariant.build` returns a widget and
/// the segment lives in a provider. Widening the record to carry overrides is the
/// fix; it is a harness change rather than a screen change, so it is recorded
/// here rather than done in passing.
Future<Map<String, int>> _seedHardTreatments(AppDatabase db) async {
  await seedSeason(db);
  final TreatmentRepository repo = TreatmentRepository(db);

  final EweId longTag = await seedEwe(db, tag: '40001');
  final LambingId lambing = await seedLambing(db, longTag);
  final LambId untagged = await seedLamb(db, lambing, longTag);

  final WriteOutcome voided = await repo.recordTreatment(
    TreatEwe(longTag),
    productName: 'Alamycin LA 300 mg/ml',
    doseText: '3 ml',
    batchNo: 'B7734-2026',
    withdrawals: <WithdrawalPeriod>[
      WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
    ],
  );
  await repo.voidTreatment(TreatmentId((voided as WriteCommitted).insertedId!));

  // THE FIVE-DIGIT TAG, RUNNING — the widest tag in the seed, on the widest
  // product name, counting down.
  await repo.recordTreatment(
    TreatEwe(longTag),
    productName: 'Alamycin LA 300 mg/ml',
    doseText: '3 ml',
    batchNo: 'B7734-2026',
    withdrawals: <WithdrawalPeriod>[
      WithdrawalDays.asEnteredByUser(days: 40, target: WithdrawalTarget.meat),
      // BOTH TARGETS, so the fan-out renders as two countdown rows and the
      // per-target line is exercised at every scale.
      WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.milk),
    ],
  );

  // THE UNTAGGED LAMB, RUNNING — its tag cell falls back to a word rather than a
  // number, which is a different width at every scale.
  await repo.recordTreatment(
    TreatLamb(untagged),
    productName: 'Spectam Scour Halt',
    withdrawals: <WithdrawalPeriod>[
      WithdrawalDays.asEnteredByUser(days: 35, target: WithdrawalTarget.meat),
    ],
  );

  // ONE WITH NO WITHDRAWAL AT ALL — the row that prints the absence out loud —
  // and one that says NONE APPLIES. Both are book rows; see the note above.
  await repo.recordTreatment(TreatLamb(untagged), productName: 'Spectam Scour Halt');
  await repo.recordTreatment(
    TreatEwe(longTag),
    productName: 'Footbath',
    withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.meat)],
  );

  for (int i = 0; i < 8; i++) {
    final EweId ewe = await seedEwe(db, tag: '${500 + i}');
    await repo.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin LA 300 mg/ml',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28 + i, target: WithdrawalTarget.meat),
      ],
    );
  }

  return <String, int>{};
}

Widget _treatments(Map<String, int> _) => const TreatmentsScreen();

/// **THE SAME SEED AS TREATMENTS, DELIBERATELY.** The Export screen renders
/// counts, and the counts that can overflow a row are the large ones — the
/// treatments seed is the only one in this file that produces double figures in
/// every column at once. A screen whose numbers are all `1` proves nothing about
/// a row at 200% text.
Widget _export(Map<String, int> _) => const ExportScreen();

/// The banner armed, and the hour NOT set — condition 6 is a wall-clock fact and
/// the matrix runs at whatever hour the machine is at.
///
/// That is deliberate rather than sloppy: the cells that matter here are the
/// LAYOUT ones, and a banner that does not render because the suite ran at 02:00
/// would make eighteen cells pass having pumped nothing. So the matrix pins the
/// hour through `withClock` in its own body — see the variant's note there.
Future<Map<String, int>> _seedArmedBanner(AppDatabase db) async {
  await armExportBanner(db);
  return <String, int>{};
}

/// The text scales every variant is pumped at. 1.0, the Android 14+ default
/// ceiling most users reach, and the 200% the platform allows.
const List<double> kTextScales = <double>[1.0, 1.3, 2.0];

/// Bold Text off and on. It is a separate axis from scale because
/// flutter#139712 makes w800/w900 render LIGHTER when it is on — the one
/// combination a scale-only matrix would never reach.
const List<bool> kBoldStates = <bool>[false, true];

/// The devices we promise to work on. **Smallest first — most bugs live there.**
final class Device {
  const Device(this.name, this.size, this.dpr);

  final String name;

  /// Logical, not physical. [PumpApp.pumpApp] multiplies by [dpr] for the view.
  final Size size;

  final double dpr;

  static const Device small = Device('small', Size(375, 667), 2.0); // iPhone SE
  static const Device typical = Device('typical', Size(390, 844), 3.0); // iPhone 15/16
  static const Device large = Device('large', Size(430, 932), 3.0); // Pro Max

  /// The matrix's arithmetic depends on this count.
  static const List<Device> all = <Device>[small, typical, large];
}

/// ONE override today: the database.
///
/// 2.6.1 spelling throughout. Riverpod 3's container-for-tests factory and its
/// `WidgetTester` container getter do not exist here (decision #18), and both
/// are gate rows — `rp3.container_test` under lib/ and `rp3.tester_container`
/// under test/, the second existing purely because THIS is the file somebody
/// would write it in. Neither is spelled out above: the rows match the text
/// itself, so naming them here would fire the rule that keeps them out. It is
/// the twenty-third self-match in this project, and this one is load-bearing —
/// the row that guards the harness is the row the harness cannot quote.
///
/// `...overrides` is spread **LAST** so a caller's override wins over the
/// harness default for the same provider. 12 §4.4 swaps one gateway for a
/// `mocktail` double by passing an override rather than rebuilding the
/// container, and that works only because the caller's entry comes after. Do not
/// sort this list, do not deduplicate it, and do not move the spread.
///
/// **Override leaves, never controllers** (02 §5.4): `databaseProvider` and —
/// later — the seven gateways. Never a repository provider and never a screen
/// controller, because a fake controller tests the fake. A real in-memory SQLite
/// database is a better fake than anything hand-written and cannot diverge from
/// production.
ProviderContainer shedContainer(
  AppDatabase db, {
  List<Override> overrides = const <Override>[],
  FakeShareService? share,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      // `overrideWith`, never the value form: databaseProvider is a
      // FutureProvider<AppDatabase>, and the value form takes an AsyncValue
      // rather than an AppDatabase — with an error message that does not say so.
      databaseProvider.overrideWith((_) async => db),
      // N21-T06. **Always overridden, even when the test passes nothing**: the
      // real gateway reaches `SharePlus.instance`, which fails on a missing
      // platform channel in a widget test — and that reads as a flaky test
      // rather than as an unmocked seam. §17's warning applies in reverse here:
      // a parameter that overrides nothing is worse than no parameter.
      shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
      // N21-T07. **A REAL `MediaStore` WITH INJECTED RESOLVERS**, not a fake —
      // `12 §4.1`'s *a fake is a real implementation* taken literally, and the
      // shape `media_store_test.dart` already uses. The `path_provider` method
      // channel does not answer under `flutter_test`, so without this every
      // export tap silently does nothing: the future rejects inside `guard()`
      // and the test sees an empty share list rather than an error. Measured.
      //
      // `FakeMediaStore` is still N15's to write; this override is the seam it
      // will replace, not a substitute for it.
      mediaStoreProvider.overrideWithValue(_memoryMediaStore()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose); // 2.6.1: you register this yourself
  return container;
}

/// A [MediaStore] rooted in one temp directory for the life of the test.
///
/// **ONE directory, resolved once.** `freshSupportDir()` creates a new one per
/// call, and `MediaStore` resolves its root per operation — so passing the
/// function directly would give a different root to the write and to the read,
/// which is a bug that only shows up in the tests that do both.
MediaStore _memoryMediaStore() {
  final Directory dir = freshSupportDir();
  Future<Directory> resolve() async => dir;
  return MediaStore(supportDirectory: resolve, temporaryDirectory: resolve);
}

/// The harness wrapper around `04 §7.2`'s flow — staging file, validate, swap,
/// reopen — returning the **reopened** database.
///
/// **THE ONLY RESTORE ENTRY POINT TESTS USE FOR THE WHOLE FLOW.**
/// `restoreFixture` (N23-T05) is the other half: it loads a committed backup into
/// an already-open in-memory database and never renames a file. Two entry points
/// because they exercise two different halves, and mixing them is how a test
/// that renames nothing claims to have proved the swap.
///
/// **`FakeNotificationScheduler` IS NOT A PARAMETER, AND THAT IS P15.** `09 §7.3`
/// gives `RestoreService` a scheduler so a restore can cancel what the old
/// database had scheduled. Reminders ship in `v1.1.0`, so there is nothing to
/// cancel and no scheduler to fake — N24 adds both, here and in the service, in
/// the commit that creates them.
Future<AppDatabase> restoreInto(Directory support, File backup) async {
  final Map<String, Object?> decoded =
      jsonDecode(await backup.readAsString()) as Map<String, Object?>;

  final BackupHeaderOutcome outcome = readBackupHeader(decoded);
  expect(
    outcome,
    isA<BackupHeaderAccepted>(),
    reason: 'the fixture is not readable by this build — check `schema` and `formatVersion`',
  );

  final Map<String, List<Map<String, Object?>>> tables = <String, List<Map<String, Object?>>>{
    for (final MapEntry<String, Object?> e in (decoded['tables']! as Map<String, Object?>).entries)
      e.key: <Map<String, Object?>>[
        for (final Object? row in e.value! as List<Object?>) row! as Map<String, Object?>,
      ],
  };

  final WriteOutcome result = await RestoreService(support).restore(
    header: (outcome as BackupHeaderAccepted).header,
    tables: tables,
    openStaging: (File file) async {
      file.parent.createSync(recursive: true);
      return AppDatabase(NativeDatabase(file), seedOnCreate: false);
    },
  );
  expect(
    result,
    isA<WriteCommitted>(),
    reason: 'the restore aborted — the live database is untouched, which is the point',
  );

  // THE REOPENED DATABASE, from where the swap actually put it. Reopening the
  // staging path instead would test a file the app will never read.
  final AppDatabase reopened = AppDatabase(
    NativeDatabase(File('${support.path}/$kLiveDatabaseName')),
    seedOnCreate: false,
  );
  addTearDown(reopened.close);
  return reopened;
}

/// A temp directory torn down with the test — what `restoreInto` restores into
/// (09 §7.3).
///
/// Nothing calls it until N23; it lands here because 12 §5.3 closes the file
/// list and this is harness.dart's member.
Directory freshSupportDir() {
  final Directory dir = Directory.systemTemp.createTempSync('shed_book_support');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir;
}

/// The container [PumpApp.pumpApp] built, so [PumpApp.closeApp] can dispose it
/// inside the test body.
///
/// A top-level field rather than a member because an extension cannot hold
/// state. One test pumps one app, so one slot is enough — and `closeApp` clears
/// it, so a second `pumpApp` in the same body starts clean.
ProviderContainer? _container;

extension PumpApp on WidgetTester {
  /// Pumps [screen] inside the app's real theme, locale and container.
  ///
  /// The default [padding] is NOT zero. Real phones have a notch and a home
  /// indicator, and a zero-padding harness hides the entire class of bug where a
  /// bottom-anchored 60 pt target sits under the home bar — which is every
  /// primary action in this app.
  Future<void> pumpApp(
    Widget screen, {
    required AppDatabase db,
    Device device = Device.typical,
    double textScale = 1.0,
    bool boldText = false,
    ShedPaletteId palette = ShedPaletteId.night,
    bool highContrast = false,
    List<Override> overrides = const <Override>[],
    FakeShareService? share,
    EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  }) async {
    final ProviderContainer container = shedContainer(db, overrides: overrides, share: share);
    _container = container;

    view.physicalSize = device.size * device.dpr;
    view.devicePixelRatio = device.dpr;
    // Forget the reset and the next test in the same file inherits a Pro Max
    // viewport — which is exactly the size at which the overflow bugs do not
    // reproduce.
    addTearDown(view.reset);

    // THE HARNESS PINS THE THEME; IT DOES NOT READ themeProvider. Reading it
    // would make every widget test depend on whatever settingsProvider emitted
    // from the in-memory row, and a palette-specific golden could not be written
    // at all.
    final ThemeData theme = buildShedTheme(resolvePalette(palette, highContrast: highContrast));

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // MediaQuery WRAPS MaterialApp, not the other way round. Inside-out and
        // the app rebuilds the MediaQueryData from the view, discarding the
        // textScaler, the boldText flag and the padding — and the overflow
        // matrix then passes 252 cells at scale 1.0 while claiming 2.0.
        child: MediaQuery(
          data: MediaQueryData(
            size: device.size,
            devicePixelRatio: device.dpr,
            // `textScaler`, never the deprecated factor (decision #99).
            textScaler: TextScaler.linear(textScale),
            boldText: boldText,
            padding: padding,
          ),
          child: MaterialApp(
            // A harness that inherits the runner's locale renders `3/28/2026` on
            // a US CI runner and passes. `d MMM y`, 24-hour, kg.
            locale: const Locale('en', 'GB'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const <Locale>[Locale('en'), Locale('en', 'GB'), Locale('en', 'IE')],

            // All four slots, so no platform event can select light.
            theme: theme,
            darkTheme: theme,
            highContrastTheme: theme,
            highContrastDarkTheme: theme,
            themeMode: ThemeMode.dark,
            themeAnimationDuration: Duration.zero,

            home: screen,
          ),
        ),
      ),
    );

    // No timeout, and that is safe ONLY because indefinite animations are banned
    // on every screen. If one ever ships, this call hangs for ten minutes and
    // fails opaquely — which is worth knowing if you are reading this file
    // because a test hung.
    await pumpAndSettle();

    // ONE MILLISECOND, AND IT IS NOT A ROUNDING NICETY — IT IS RIVERPOD'S
    // DISPOSAL QUEUE. MEASURED by reading the binding's own pending-timer
    // dump: dropping a listener makes `ProviderScheduler.scheduleProviderDispose`
    // post a ZERO-DURATION timer to do the autoDispose cleanup, and
    // `_verifyInvariants` fails the test if one is still queued. A bare `pump()`
    // elapses nothing and does not fire it; elapsing a millisecond does.
    //
    // WHAT THIS COST TO FIND IS WORTH RECORDING: the failure reads "A Timer is
    // still pending even after the widget tree was disposed", which points at
    // the widget tree, and the only screen carrying a timer was the one watching
    // minuteTickProvider — so the ticker looked guilty and was not. The timer
    // belongs to Riverpod, not to us, and no amount of draining the ticker's
    // tail would ever have cleared it. The binding prints the creation stack via
    // debugPrint; reading it took a minute and three turns of guessing did not.
    await pump(const Duration(milliseconds: 1));
  }

  /// Unmounts the app, disposes its container, and lets every provider dispose —
  /// **inside the test body**, which is the whole point.
  ///
  /// **A TEST THAT PUMPS A SCREEN WATCHING `minuteTickProvider` MUST END WITH
  /// THIS**, and the reason is a property of `flutter_test` rather than a defect
  /// in the ticker: `_verifyInvariants` runs at the END OF THE TEST BODY, before
  /// any tear-down, and a mounted screen carrying a live ticker inherently has a
  /// live timer at that moment. No tear-down can help, because none has run yet.
  ///
  /// MEASURED, by reading the binding's own pending-timer dump rather than
  /// guessing — which cost three rounds of guessing first. Two distinct timers
  /// are involved and they need different things:
  ///
  ///   * the TICKER's `Timer`, cancelled by `ref.onDispose` once the provider is
  ///     disposed — which needs the last listener gone, i.e. the unmount below;
  ///   * RIVERPOD's own zero-duration disposal timer, posted by
  ///     `ProviderScheduler.scheduleProviderDispose` when a listener drops. A
  ///     bare `pump()` elapses nothing and does not fire it; elapsing a
  ///     millisecond does.
  ///
  /// The failure message says *"even after the widget tree was disposed"*, which
  /// points at the widget tree and at whatever screen is on it. It is not the
  /// screen's fault, and the ticker only looked guilty because it was the one
  /// thing on screen holding a timer.
  Future<void> closeApp() async {
    await pumpWidget(const SizedBox.shrink());

    // DISPOSING HERE, NOT LEAVING IT TO THE TEAR-DOWN, IS THE FIX — INSTRUMENTED
    // AND CONFIRMED. Unmounting alone is not enough: an UncontrolledProviderScope
    // does not own its container, so the provider survives the tree and
    // `onDispose` does not run until `shedContainer`'s tear-down — which is
    // AFTER `_verifyInvariants`. Printing from inside the generator showed the
    // order plainly: one iteration, then the failure, then onDispose.
    //
    // shedContainer still registers its own dispose; Riverpod's is idempotent,
    // so the tear-down finds nothing left to do when a test has called this.
    _container?.dispose();
    _container = null;

    await pump(const Duration(milliseconds: 1));
  }
}

/// An in-memory connection with the seven pragmas applied.
///
/// `NativeDatabase.memory(setup: configureConnection)` — the same function the
/// app passes, not a copy of it, so a pragma that stops being applied in
/// production stops being applied here too.
///
/// **`closeStreamsSynchronously: true`** is the trap this helper exists to
/// close: without it a stream still open at the end of a test is torn down
/// asynchronously, after the test has finished, and the failure surfaces in
/// whichever test happens to run next under
/// `--test-randomize-ordering-seed random`.
DatabaseConnection testConnection() => DatabaseConnection(
  NativeDatabase.memory(setup: configureConnection),
  closeStreamsSynchronously: true,
);

/// A fresh in-memory [AppDatabase], closed when the test ends.
///
/// **The one harness entry point**, grown rather than forked: N07-T01 landed
/// [testConnection] because AppDatabase did not exist yet, and this wraps it.
/// Two entry points is how two tests end up disagreeing about what "a fresh
/// database" means.
///
/// `addTearDown(db.close)` is inside the helper rather than at each call site,
/// because the call site that forgets it leaks a database into the next test and
/// the failure lands somewhere else entirely.
AppDatabase testDatabase({bool seedOnCreate = true}) {
  final AppDatabase db = AppDatabase(testConnection(), seedOnCreate: seedOnCreate);
  addTearDown(db.close);
  return db;
}
