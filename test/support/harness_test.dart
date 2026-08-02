// test/support/harness_test.dart
//
// The harness testing itself, which is legitimate here precisely because
// everything else in the project depends on it being right. Roughly 250 widget
// tests enter through pumpApp, including all 252 overflow-matrix cells and all
// eight goldens.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

import 'harness.dart';
import 'seeds.dart';

/// Renders the palette key it finds in the one settings row.
///
/// It can only print `night` if the in-memory database was opened, migrated to
/// `kSchemaVersion` and seeded by `seedFirstRun` — so the string on screen is
/// the whole first half of the anchor.
class _PaletteProbe extends ConsumerWidget {
  const _PaletteProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSetting> settings = ref.watch(settingsProvider);
    return switch (settings) {
      AsyncData<AppSetting>(:final AppSetting value) => Text(value.palette),
      AsyncError<AppSetting>() => const Text('error'),
      _ => const Text('waiting'),
    };
  }
}

void main() {
  testWidgets(
    'pumpApp builds a widget against NativeDatabase.memory() with no production override',
    (WidgetTester tester) async {
      // THE ANCHOR, and both halves fail differently.
      //
      // FIRST HALF — "builds a widget against NativeDatabase.memory()". A harness
      // that silently failed to override would reach openAppDatabase()'s
      // under-test assertion instead of a seeded row.
      final AppDatabase db = testDatabase();
      await tester.pumpApp(const _PaletteProbe(), db: db);

      expect(tester.takeException(), isNull);
      expect(find.text('night'), findsOneWidget);

      // SECOND HALF — "with no production override". The asymmetry is the point:
      // it is what rp3.overrides' lib/-only scope buys, and N03-T06 planted the
      // case that proves the scope.
      const String needle =
          'override'
          'With';
      expect(File('test/support/harness.dart').readAsStringSync(), contains(needle));

      for (final File f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>().where((File f) => f.path.endsWith('.dart'))) {
        expect(f.readAsStringSync(), isNot(contains(needle)), reason: f.path);
      }
    },
  );

  test('testDatabase migrates to kSchemaVersion and seeds the first-run rows', () async {
    // 03's own onCreate contract. The season count is ZERO and that is the one
    // number N12-T05 §5.4 gets wrong: seedFirstRun writes settings,
    // entitlements, the vocabulary and the reminder rules, and a season is the
    // shepherd's first act rather than the installer's. MEASURED against the
    // real seed rather than copied from the task, and seeds.dart's `_season`
    // exists precisely because of it.
    final AppDatabase db = testDatabase();

    expect(db.schemaVersion, kSchemaVersion);
    expect((await db.select(db.appSettings).get()).length, 1);
    expect((await db.select(db.entitlements).get()).length, 1);
    expect((await db.select(db.seasons).get()), isEmpty);
    expect((await db.select(db.pens).get()), isEmpty);
    expect((await db.select(db.vocabTerms).get()).length, greaterThan(0));
  });

  test('testDatabase(seedOnCreate: false) leaves the tables empty', () async {
    // The other arm, needed by the reopen tests in T02 and by every migration
    // test.
    final AppDatabase db = testDatabase(seedOnCreate: false);

    expect(await db.select(db.appSettings).get(), isEmpty);
    expect(await db.select(db.entitlements).get(), isEmpty);
    expect(await db.select(db.vocabTerms).get(), isEmpty);
  });

  testWidgets('a stream-touching widget test settles with no pending timer', (
    WidgetTester tester,
  ) async {
    // The closeStreamsSynchronously property (decision #111), expressed as the
    // failure it prevents. Without it, unsubscribing from a drift query stream
    // keeps it alive for one event-loop iteration and the binding reports a
    // leaked timer — in whichever test happens to run next, naming nothing
    // useful, and it gets diagnosed as a bug in the screen.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const _PaletteProbe(), db: db);

    expect(find.text('night'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a caller override wins over the harness default for the same provider', () async {
    // The spread-last ordering, as behaviour. 12 §4.4 swaps one gateway for a
    // double by passing an override rather than rebuilding the container, and
    // that works only because the caller's entry comes after the default.
    final AppDatabase harnessDb = testDatabase();
    final AppDatabase callersDb = testDatabase();

    final ProviderContainer container = shedContainer(
      harnessDb,
      overrides: <Override>[databaseProvider.overrideWith((_) async => callersDb)],
    );

    expect(await container.read(databaseProvider.future), same(callersDb));
  });

  group('the harness registers its own tear-downs', () {
    // BOTH ASSERTIONS LIVE IN A GROUP tearDown, and the reason is mechanical
    // AND MEASURED. Two orderings are in play:
    //
    //   * addTearDown callbacks run LIFO, so one registered inside the test body
    //     runs BEFORE shedContainer's own dispose and reads 0 every time;
    //   * a group tearDown runs AFTER every addTearDown callback — probed, not
    //     assumed.
    //
    // The obvious shape, a second test asserting what the first one left
    // behind, is WRONG HERE AND CI CAUGHT IT: `make test` and the `test` job
    // both pass --test-randomize-ordering-seed random, so "the previous test"
    // is not a thing a case may depend on. A group tearDown is the only hook
    // that is both after the tear-downs and independent of order.
    int disposals = 0;
    String? supportDirPath;

    tearDown(() {
      expect(disposals, 1, reason: 'shedContainer must register addTearDown(container.dispose)');
      expect(
        Directory(supportDirPath!).existsSync(),
        isFalse,
        reason: 'freshSupportDir must delete its directory',
      );
    });

    test('shedContainer disposes its container and freshSupportDir deletes its directory', () {
      // 250 call sites will not each remember, and a leaked container holds a
      // leaked database, which is a leaked isolate.
      final AppDatabase db = testDatabase();
      final ProviderContainer container = shedContainer(db);
      container.listen<int>(
        Provider.autoDispose<int>((Ref ref) {
          ref.onDispose(() => disposals += 1);
          return 1;
        }),
        (int? previous, int next) {},
      );

      final Directory dir = freshSupportDir();
      expect(dir.existsSync(), isTrue);

      supportDirPath = dir.path;
      expect(disposals, 0);
    });
  });

  test('Device.all is three entries, smallest first', () {
    // The matrix's arithmetic depends on the count, and "smallest first" is a
    // 3am statement rather than a tidy one: most bugs live on the small device.
    expect(Device.all, hasLength(3));
    expect(Device.all.map((Device d) => d.name).toList(), <String>['small', 'typical', 'large']);

    expect(Device.small.size, const Size(375, 667));
    expect(Device.small.dpr, 2.0);
    expect(Device.typical.size, const Size(390, 844));
    expect(Device.typical.dpr, 3.0);
    expect(Device.large.size, const Size(430, 932));
    expect(Device.large.dpr, 3.0);

    for (int i = 1; i < Device.all.length; i++) {
      expect(
        Device.all[i].size.width,
        greaterThan(Device.all[i - 1].size.width),
        reason: 'smallest first',
      );
    }
  });

  testWidgets('pumpApp applies textScale, boldText and the notch padding', (
    WidgetTester tester,
  ) async {
    // Catches the MediaQuery-inside-MaterialApp inversion. Inverted, all three
    // are rebuilt from the view and the overflow matrix passes 252 cells at
    // scale 1.0 while claiming to have tested 2.0.
    final AppDatabase db = testDatabase();
    late MediaQueryData seen;

    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) {
          seen = MediaQuery.of(context);
          return const SizedBox.shrink();
        },
      ),
      db: db,
      textScale: 2.0,
      boldText: true,
    );

    expect(seen.textScaler.scale(10), 20);
    expect(seen.boldText, isTrue);
    expect(seen.padding, const EdgeInsets.only(top: 47, bottom: 34));
  });

  testWidgets('pumpApp renders in en_GB', (WidgetTester tester) async {
    // A harness that inherits the runner's locale renders 3/28/2026 on a US CI
    // runner and passes.
    final AppDatabase db = testDatabase();
    late Locale seen;

    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) {
          seen = Localizations.localeOf(context);
          return const SizedBox.shrink();
        },
      ),
      db: db,
    );

    expect(seen, const Locale('en', 'GB'));
  });

  for (final ShedPaletteId palette in ShedPaletteId.values) {
    for (final bool highContrast in <bool>[false, true]) {
      testWidgets('pumpApp cannot produce a light theme — ${palette.name} hc=$highContrast', (
        WidgetTester tester,
      ) async {
        final AppDatabase db = testDatabase();
        late Brightness seen;

        await tester.pumpApp(
          Builder(
            builder: (BuildContext context) {
              seen = Theme.of(context).brightness;
              return const SizedBox.shrink();
            },
          ),
          db: db,
          palette: palette,
          highContrast: highContrast,
        );

        expect(seen, Brightness.dark);
      });
    }
  }

  test('seedEwe, seedLambing and seedTreatment produce readable rows', () async {
    final AppDatabase db = testDatabase();

    final EweId ewe = await seedEwe(db, tag: '412');
    final Ewe eweRow = await (db.select(
      db.ewes,
    )..where(($EwesTable t) => t.id.equals(ewe.value))).getSingle();
    expect(eweRow.tag, '412'); // exactly as typed
    expect(eweRow.tagDigits, '412');
    expect(eweRow.uid, isNotEmpty);

    final LambingId lambing = await seedLambing(db, ewe);
    final Lambing lambingRow = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(lambingRow.ewe, ewe.value);
    expect(lambingRow.uid, isNotEmpty);
    // The provenance quad, coherent: a row the app could have produced.
    expect(lambingRow.timeSource, 'auto');
    expect(lambingRow.originalEffective, isNull);
    expect(lambingRow.capturedAt, lambingRow.occurredAt);

    final TreatmentId treatment = await seedTreatment(db, product: 'Alamycin', withdrawalDays: 28);
    final Treatment treatmentRow = await (db.select(
      db.treatments,
    )..where(($TreatmentsTable t) => t.id.equals(treatment.value))).getSingle();
    expect(treatmentRow.productName, 'Alamycin');
    expect(treatmentRow.uid, isNotEmpty);

    // §12.1: the withdrawal lives in a CHILD ROW, because no row means
    // NotRecorded and 0 is a real label value a nullable int could not carry.
    final List<TreatmentWithdrawal> withdrawals = await (db.select(
      db.treatmentWithdrawals,
    )..where(($TreatmentWithdrawalsTable t) => t.treatment.equals(treatment.value))).get();
    expect(withdrawals, hasLength(1));
    expect(withdrawals.single.days, 28);
    expect(withdrawals.single.clearDate, isNotNull);
  });

  test('seedLambing fails loudly on an unseeded ewe', () async {
    // foreign_keys = ON is doing its job (decision #28), and the helper does not
    // paper over it. A seed that silently wrote an orphan would make every later
    // join test pass against data the app could never hold.
    final AppDatabase db = testDatabase();
    await expectLater(seedLambing(db, const EweId(9999)), throwsA(anything));
  });

  test('seedTreatment has no default withdrawalDays', () {
    // Safety rule §12.1 at the test tier. Source text, because the absence of a
    // default is not observable from a call that supplies one.
    final String source = File('test/support/seeds.dart').readAsStringSync();
    expect(source, contains('required int withdrawalDays'));
    expect(source, isNot(contains('int withdrawalDays =')));
  });

  test('test/support/ holds exactly the files this task lands', () {
    // Fails the day somebody adds a fake early, which is the whole of critique
    // defect S1.
    //
    // THE LIST GROWS ONE FILE PER TASK THAT NEEDS ONE, and every addition is a
    // deliberate act rather than a drift. decision_record.dart landed in N00-T04,
    // before N12-T05 wrote "exactly four"; reads.dart is 12 §5.3's third support
    // file and lands at N14-T02, the first test that needed a read helper rather
    // than an inline select.
    //
    // 12 §5.3 closes the folder at twelve. This case is what makes reaching
    // thirteen a conversation.
    final List<String> files = Directory('test/support').listSync().whereType<File>().map((File f) {
      final List<String> parts = f.path.split(Platform.pathSeparator);
      return parts.last;
    }).toList()..sort();

    expect(files, <String>[
      'decision_record.dart',
      'harness.dart',
      'harness_dst_test.dart',
      'harness_test.dart',
      'reads.dart', // N14-T02
      'seeds.dart',
    ]);
  });

  test('the pumpable-variant map exists with exactly one entry', () {
    // FLIPPED AT N13-T07, which is the task that created it. The case used to
    // assert the map was ABSENT and that the header named N13 as its author —
    // and N13 is now here, so the assertion inverts rather than being deleted:
    // what it guards is that the table grows one screen at a time, in the commit
    // that adds the screen.
    //
    // The literal is still split, because this file is scanned by the same case
    // it is asserting and a whole needle would match itself.
    const String needle =
        'kPumpable'
        'Variants';
    final String source = File('test/support/harness.dart').readAsStringSync();

    expect(source, contains(needle));
    expect(kPumpableVariants, hasLength(1));
    expect(
      kPumpableVariants.keys.single,
      'quick_entry',
      reason: 'one screen exists; each screen epic adds its own row',
    );
    expect(
      source,
      contains('N33-T01'),
      reason: "the header must name where 12 §6.2's length assertion becomes true",
    );
  });

  test('no Fake class is declared under test/support/', () {
    // The seven fakes have named homes and this is the tripwire. Matched on the
    // DECLARATION, not the word, so the header ledger that names all seven does
    // not fire the rule that keeps them out — and split across two literals,
    // because this file lives in the directory it is scanning. The
    // twenty-second self-match in this project.
    for (final File f in Directory('test/support').listSync().whereType<File>()) {
      final String declarations = f
          .readAsLinesSync()
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      const String declaration =
          'class '
          'Fake';
      expect(declarations, isNot(contains(declaration)), reason: f.path);
    }
  });
}
