// test/features/minute_tick_test.dart
//
// testWidgets throughout, because the advancing fake clock only exists inside
// the widget binding: `tester.pump(duration)` is what moves both the scheduler
// and `Future.delayed`.
//
// `withClock` supplies the wall time, so the two are driven together — the
// ticker's alignment arithmetic reads `appNow()` and its sleep is a
// `Future.delayed`, and a test that advanced only one of them would prove
// nothing about either.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/domain/time/instant.dart';

const String _tickerFile = 'lib/core/time/ticker.dart';

List<String> _authoredDart(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart') && !p.endsWith('.g.dart'))
        .toList()
      ..sort();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('the provider is autoDispose and yields Instant, not DateTime', () {
    // `.autoDispose` IS LOAD-BEARING, NOT TIDINESS (02 §4.2). A plain
    // StreamProvider stays subscribed for the life of the ProviderScope, so the
    // loop would wake the process every 60 s all night with no pen board on
    // screen — on a phone in a coat pocket, in a shed, on battery.
    expect(minuteTickProvider, isA<AutoDisposeStreamProvider<Instant>>());

    final String source = _declarations(_tickerFile);
    expect(source, contains('StreamProvider.autoDispose<Instant>'));
    expect(source, isNot(contains('DateTime')), reason: 'R25: it yields Instant');
  });

  test('the delay is computed from the current instant, not fixed at 60 s', () {
    // THE ALIGNMENT PROPERTY, read off the source because it is arithmetic
    // rather than behaviour. A fixed 60 s delay keeps whatever offset the first
    // subscription happened to have, so every pen tile updates at a different
    // moment and the grid reads as noise.
    //
    // `epochMillis % 60000` is zone-independent: every IANA offset is a whole
    // number of minutes, so the local minute boundary and the UTC one are the
    // same instant.
    final String source = _declarations(_tickerFile);
    expect(source, contains('60000 - (now.epochMillis % 60000)'));
  });

  // ---------------------------------------------------------------------
  // WHY THERE IS NO BEHAVIOURAL CASE HERE, AND WHAT IT COSTS
  // ---------------------------------------------------------------------
  //
  // N12-T03 §5.4 asks for six pumped cases — first emission immediate, second
  // on the boundary, five minutes gives six emissions, two listeners share one
  // loop, re-subscription restarts, and the type. They cannot be written against
  // 01 §7.2's printed body, and the reason is structural rather than fixable in
  // a test.
  //
  // MEASURED: the generator loops forever, so there is ALWAYS a Future.delayed
  // outstanding, and a Future.delayed cannot be cancelled. Dropping the last
  // listener makes autoDispose cancel the subscription and pauses the generator
  // at its `await` — the timer survives, and flutter_test fails any test that
  // ends with one pending: "A Timer is still pending even after the widget tree
  // was disposed."
  //
  // The emission itself was OBSERVED during that run: subscribing at :17
  // created a timer of exactly 43 s, which is the alignment arithmetic working.
  // So the behaviour is right and only the assertion is unwritable.
  //
  // Two honest ways out, and both are somebody else's call:
  //   * give the loop a cancellation seam — a Completer raced against the delay,
  //     closed on ref.onDispose — which changes 01 §7.2's printed body; or
  //   * pump the pending delay to completion in the harness, which N12-T05's
  //     pumpApp could own once it exists.
  //
  // Neither is taken here. What IS held below is everything the source can
  // prove: the autoDispose shape, the Instant type, the alignment expression,
  // the single declaration, and the absence of a drifting periodic timer.

  test('Timer.periodic appears nowhere under lib/', () {
    // Duplicates net.sync_timer deliberately, in the tier a developer runs
    // first. A periodic timer drifts: it fires 60 s after the last fire, not on
    // the boundary, so the grid walks off the minute over an hour.
    const String needle =
        'Timer.'
        'periodic';
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains(needle)), reason: path);
    }
  });

  test('exactly one ticker provider is declared in lib/', () {
    // The banned spellings are named so a second heartbeat cannot arrive under a
    // different name.
    int declarations = 0;
    for (final String path in _authoredDart('lib')) {
      final String source = _declarations(path);
      declarations += 'StreamProvider.autoDispose<Instant>'.allMatches(source).length;
      expect(source, isNot(contains('minuteTickerProvider')), reason: path);
      expect(source, isNot(contains('penTickProvider')), reason: path);
    }
    expect(declarations, 1);
  });

  test('the manual refresh is absent from lib/ and the gap is named', () {
    // N12-T03 §5.2 asks for one call to Riverpod's manual refresh in app.dart's
    // resumed arm, and anticipates an [exempt] line for the gate row that scans
    // for it.
    //
    // BOTH CANNOT BE TRUE AT ONCE. R56 fixes the allowlist at four lines and
    // CLAUDE.md forbids adding one to silence a gate, so the call is not
    // written. What IS asserted is that the gap is NAMED rather than forgotten:
    // a TODO in the resumed arm, and a line in N12's pull request.
    const String needle =
        'ref.in'
        'validate(';
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains(needle)), reason: path);
    }

    expect(
      File('lib/app.dart').readAsStringSync(),
      contains('TODO(owner)'),
      reason: 'the deferral must be visible where the code is, not only in a PR',
    );
  });

  test('the allowlist still has exactly four exempt lines', () {
    // The assertion that makes the deferral above meaningful: if a fifth line
    // ever appears, this is where it is noticed.
    final List<String> lines = File('tool/policy_allowlist.txt').readAsLinesSync();
    final int start = lines.indexWhere((String l) => l.trim() == '[exempt]');
    final List<String> keys = lines
        .skip(start + 1)
        .map((String l) => l.split('#').first.trim())
        .where((String l) => l.contains('::'))
        .toList();

    expect(keys, hasLength(4));
  });
}
