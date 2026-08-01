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
//     FakeShareService                                            N21
//     FakeNotificationScheduler                                   N24
//     FakeWakelockController                                      N29
//     FakePurchaseService (the store seam, R74)                   N30
//
//   the pumpable-variant map (12 §6.2) — a Map<String, Widget Function()> over
//     RouteNames. N13 creates it with ONE entry (quick_entry) and every screen
//     epic adds one row. Four files iterate it, and none of them exist yet:
//     the 252-cell overflow matrix, semantics_gate_test, the geometric half of
//     tap_target_test, and the pixel-sampling group in contrast_test (N33).
//
//   restoreFixture / flock_400_3seasons.json (12 §5.2, critique defect S3) —
//     fixtures go through RestoreService, which is N23, and tool/seed.dart
//     writes them through the restore path in the same epic. Until then every
//     test seeds with the targeted helpers in seeds.dart. The switch is one
//     task, N23-T06, and it is the task that proves the fixture is loadable.
//
//   the four fixture id constants (12 §5.3) — they index into the fixture and
//     are meaningless without it: N23.
//
// An optional `share:` parameter that overrides nothing is WORSE than no
// parameter, because it silently accepts a fake and the test passes for the
// wrong reason. Add each one with its provider, never before.
library;

import 'dart:io';

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
import 'package:shed_book/l10n/app_localizations.dart';

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
ProviderContainer shedContainer(AppDatabase db, {List<Override> overrides = const <Override>[]}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      // `overrideWith`, never the value form: databaseProvider is a
      // FutureProvider<AppDatabase>, and the value form takes an AsyncValue
      // rather than an AppDatabase — with an error message that does not say so.
      databaseProvider.overrideWith((_) async => db),
      ...overrides,
    ],
  );
  addTearDown(container.dispose); // 2.6.1: you register this yourself
  return container;
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
    EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  }) async {
    final ProviderContainer container = shedContainer(db, overrides: overrides);

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
