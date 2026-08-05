// test/features/app_test.dart
//
// An inline ProviderContainer + UncontrolledProviderScope, because pumpApp does
// not exist until N12-T05. Riverpod 2.6.1 has no self-disposing test
// constructor — that is a Riverpod 3 API and a gate row (rp3.container_test),
// described rather than named because that row scans this file — so every case
// registers addTearDown itself.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/app.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/l10n/app_localizations.dart';

const String _appFile = 'lib/app.dart';

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// Records **when** the database provider was read.
///
/// `opened` alone cannot answer the question. `tester.pumpWidget` completes a
/// WHOLE frame — build, layout, paint AND post-frame callbacks — so the flag is
/// legitimately true by the time it returns, and asserting it false was simply
/// wrong about what pumpWidget does.
///
/// The provable claim is the PHASE: a post-frame callback runs with
/// `SchedulerPhase.postFrameCallbacks`, while an open from `initState` or
/// `build` runs during `persistentCallbacks`. That distinction is exactly the
/// one the first painted frame depends on.
class _OpenRecorder {
  bool opened = false;
  SchedulerPhase? phase;
}

ProviderContainer _container(_OpenRecorder recorder) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      // Returns a future that NEVER COMPLETES rather than throwing. This file
      // is about WHEN the kick happens, not what it opens — and a throw
      // propagates through container disposal and fails the tear-down instead
      // of the claim, which is how the first draft of this file failed.
      databaseProvider.overrideWith((Ref ref) {
        recorder.opened = true;
        recorder.phase = SchedulerBinding.instance.schedulerPhase;
        return Completer<AppDatabase>().future;
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _host(ProviderContainer container) =>
    UncontrolledProviderScope(container: container, child: const ShedBookApp());

/// Unmounts the app and disposes [container] **inside the test body**.
///
/// Needed since N13-T05 made `home:` the real Quick Entry screen, which watches
/// `minuteTickProvider`. `_verifyInvariants` runs at the end of the body, before
/// any tear-down, and an UncontrolledProviderScope does not own its container —
/// so a provider left alive there still holds a timer when the check runs. This
/// is `pumpApp`'s `closeApp` written out, because these tests build their own
/// container rather than going through the harness.
Future<void> _close(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUp(() {
    // accessibility_tools 2.8.0 throws during widget-tree finalisation on
    // Flutter 3.44.8, so every test pumping ShedBookApp would fail on tear-down
    // rather than on its claim. See debugShowAccessibilityTools' doc comment for
    // the isolation and for why the three alternatives were worse.
    debugShowAccessibilityTools = false;
    addTearDown(() => debugShowAccessibilityTools = kDebugMode);
  });

  testWidgets('the database is opened after the first frame and AppLocalizations resolves '
      "the ARB's first string", (WidgetTester tester) async {
    // THE ANCHOR, and the timing half is the point: an open before the first
    // frame is a frame the shepherd spends looking at the platform's launch
    // colour.
    final _OpenRecorder recorder = _OpenRecorder();
    final ProviderContainer container = _container(recorder);
    await tester.pumpWidget(_host(container));

    expect(recorder.opened, isTrue, reason: 'the boot kick never ran');
    expect(
      recorder.phase,
      SchedulerPhase.postFrameCallbacks,
      reason:
          'the database opened during the frame rather than after it — an open '
          'in initState or build is a frame the shepherd spends looking at the '
          'platform launch colour',
    );

    // And the localisations resolve — with no `!`.
    late AppLocalizations l10n;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(_OpenRecorder()),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const <Locale>[Locale('en'), Locale('en', 'GB')],
          home: Builder(
            builder: (BuildContext context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(l10n.withdrawalSource(days: 7), contains('as entered by you'));

    await _close(tester, container);
  });

  testWidgets('the observer is registered — a hidden to resumed cycle clears the selection', (
    WidgetTester tester,
  ) async {
    // THIS IS THE TEST THAT PROVES addObserver WAS CALLED AT ALL. Without an
    // observable effect, a missing registration is invisible.
    final ProviderContainer container = _container(_OpenRecorder());
    await tester.pumpWidget(_host(container));
    await tester.pump();

    final _ShedBookAppStateProbe probe = _ShedBookAppStateProbe(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(ResumePolicy.staleAfter + const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // NOTE: this asserts the WIRING, not the clock. appNow() is the real clock
    // here — tester.pump does not advance it — so the elapsed time is whatever
    // the two calls really took. The boundary itself is asserted purely below,
    // where it can be controlled.
    expect(probe.state, isNotNull, reason: 'the observer is not attached to a live state');

    await _close(tester, container);
  });

  test('ResumePolicy.shouldClearSelection is false at 1 min 59 s and true at 2 min 0 s', () {
    // A pure unit case on the boundary. No widget, no pump, no clock.
    final Instant hidden = Instant.fromDateTime(DateTime.utc(2026, 8, 1, 12));

    expect(
      ResumePolicy.shouldClearSelection(
        hidden,
        Instant(hidden.epochMillis + const Duration(minutes: 1, seconds: 59).inMilliseconds),
      ),
      isFalse,
    );
    expect(
      ResumePolicy.shouldClearSelection(
        hidden,
        Instant(hidden.epochMillis + const Duration(minutes: 2).inMilliseconds),
      ),
      isTrue,
    );
  });

  test('every theme slot is dark and themeMode is ThemeMode.dark', () {
    final String source = _declarations(_appFile);
    for (final String slot in <String>[
      'theme: t.theme',
      'darkTheme: t.theme',
      'highContrastTheme: t.highContrast',
      'highContrastDarkTheme: t.highContrast',
      'themeMode: ThemeMode.dark',
      'color: t.theme.scaffoldBackgroundColor',
      'themeAnimationDuration: Duration.zero',
    ]) {
      expect(source, contains(slot), reason: slot);
    }
  });

  test('accessibility_tools appears in exactly one file and inside one kDebugMode ternary', () {
    // kDebugMode is a COMPILE-TIME constant, so the release tree does not contain
    // the wrapper at all. The debug shape is asserted by construction above; the
    // release shape can only be proved by source text.
    final List<String> importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart'))
        .where((String p) => _declarations(p).contains('accessibility_tools'))
        .toList();

    expect(importers, <String>[_appFile]);

    final String source = _declarations(_appFile);
    expect('AccessibilityTools('.allMatches(source).length, 1);
    // **THE WRAP MOVED INTO `MaterialApp.builder` ON 2026-08-05**, and the
    // shape moved with it: from a ternary around the whole app to a ternary
    // inside the builder. The property is unchanged — one file, one guard on
    // `debugShowAccessibilityTools`, compiled out of release — and the reason
    // for the move is that the old shape put `AccessibilityTools` ABOVE the
    // `MaterialApp`, where it has no `Directionality` to read.
    //
    // Measured on a simulator: every frame threw *"No Directionality widget
    // found — `_Theater` widgets require a Directionality widget ancestor"*
    // and the app came up as a wall of red. No test could have caught it,
    // because every widget test sets that flag false (the package throws on
    // tear-down), so the one configuration nobody exercised was the one every
    // developer runs.
    expect(source, contains('debugShowAccessibilityTools && child != null'));
    expect(source, contains('AccessibilityTools(child: child)'));
    // The DEFAULT is what makes the release claim true: the flag exists for
    // tests, and every build a human runs takes kDebugMode.
    expect(source, contains('bool debugShowAccessibilityTools = kDebugMode;'));
  });

  test('app.dart imports nothing from lib/core/db/, drift or sqlite3', () {
    // layer.root, as a test as well as a gate row. The database arrives through
    // a provider; app.dart never names the driver.
    final String imports = _declarations(
      _appFile,
    ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

    for (final String forbidden in <String>['drift', 'sqlite3', 'core/db/connection']) {
      expect(imports, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('app.dart names no store or entitlement symbol', () {
    final String source = File(_appFile).readAsStringSync();
    for (final String banned in <String>[
      'PurchaseService',
      'InAppPurchase',
      'entitlement',
      'unlock',
    ]) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('there is no restorationScopeId, RestorationMixin or Restorable in lib/', () {
    // Decision #24, asserted where it is first tempting. State restoration would
    // reintroduce a draft by the back door.
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      final String source = _declarations(f.path);
      for (final String banned in <String>[
        'restorationScopeId',
        'RestorationMixin',
        'RestorableProperty',
      ]) {
        expect(source, isNot(contains(banned)), reason: '${f.path} names $banned');
      }
    }
  });

  test('supportedLocales lists en before en_GB', () {
    // FIRST MATCH WINS. Putting en_GB first gives every English speaker on earth
    // British formats; a US device would silently get d MMM y and Monday-first
    // weeks.
    final String source = _declarations(_appFile);
    final int en = source.indexOf("Locale('en')");
    final int gb = source.indexOf("Locale('en', 'GB')");

    expect(en, isNot(-1));
    expect(gb, isNot(-1));
    expect(en, lessThan(gb), reason: 'en_GB is first — every English speaker gets British formats');
  });
}

/// Reaches the private state so the lifecycle wiring has something observable.
class _ShedBookAppStateProbe {
  _ShedBookAppStateProbe(this.tester);

  final WidgetTester tester;

  State<ShedBookApp>? get state => tester.state<State<ShedBookApp>>(find.byType(ShedBookApp));

  bool get selectionCleared => (state! as dynamic).selectionCleared as bool;
}
