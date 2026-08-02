// test/features/minute_tick_test.dart
//
// testWidgets for every behavioural case, because the advancing fake clock only
// exists inside the widget binding: AutomatedTestWidgetsFlutterBinding runs the
// body inside a FakeAsync zone and installs that zone's clock as
// package:clock's ambient clock, so `tester.pump(duration)` moves BOTH the
// scheduler and `appNow()`. The ticker's alignment arithmetic reads `appNow()`
// and its sleep is a `Future.delayed`; a test that advanced only one of them
// would prove nothing about either.
//
// NO `atFixed` ANYWHERE IN THIS FILE, and that is 12 §2.2's rule rather than a
// preference: every case here measures ELAPSED TIME, and `Clock.fixed` freezes
// `now()`. Pin the clock and each one silently measures nothing and passes.
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

/// Listens to the ticker and appends every emitted [Instant] to [into].
///
/// `fireImmediately: true`, because the first emission is a property under test
/// rather than a detail: a pen tile that is blank until the next boundary is a
/// blank tile for up to a minute.
ProviderSubscription<AsyncValue<Instant>> _subscribe(ProviderContainer c, List<Instant> into) =>
    c.listen<AsyncValue<Instant>>(minuteTickProvider, (
      AsyncValue<Instant>? previous,
      AsyncValue<Instant> next,
    ) {
      if (next is AsyncData<Instant>) {
        into.add(next.value);
      }
    }, fireImmediately: true);

/// How long until the next minute boundary after [from] — the ticker's own
/// arithmetic, recomputed here so a case never assumes the binding's fake clock
/// started on a boundary. It does not.
Duration _toBoundary(Instant from) => Duration(milliseconds: 60000 - (from.epochMillis % 60000));

/// Runs the outstanding `Future.delayed` out.
///
/// **07 §9.2 ACCEPTS THIS TAIL** — "up to 60 s ... one wake-up, once, and it is
/// cheaper than the StreamController plumbing that would avoid it" — so a test
/// that ended without draining it would fail on a pending timer while asserting
/// something the shape never promised. 61 s covers the longest possible gap.
Future<void> _drainTail(WidgetTester tester) => tester.pump(const Duration(seconds: 61));

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
  // THE BEHAVIOURAL CASES, AND WHAT MADE THEM WRITABLE
  // ---------------------------------------------------------------------
  //
  // N12 first landed WITHOUT these six, on the reading that the loop always has
  // an outstanding Future.delayed and flutter_test fails any test ending with a
  // pending timer. That reading was half right and the missing half is in
  // 07 §9.2, which ACCEPTS the tail: "after the last listener goes the pending
  // Future.delayed still completes — up to 60 s of tail. That is one wake-up,
  // once, and it is cheaper than the StreamController plumbing that would avoid
  // it."
  //
  // So the fix was never a cancellation seam — the doc set declines that
  // plumbing by name — it is to PUMP THE TAIL TO COMPLETION before the test
  // ends. [_drainTail] does exactly that, and the test tier owes the loop that
  // courtesy rather than the loop owing the test tier a seam.
  //
  // MEASURED: the binding seeds its FakeAsync clock at an arbitrary offset
  // (48003 ms past the minute in the run that proved this), so none of these
  // cases may assume it starts on a boundary. Every one computes the gap from
  // the instant it actually saw.

  testWidgets('the ticker fires on the minute boundary, once, and disposes with its '
      'last listener', (WidgetTester tester) async {
    // THE ANCHOR — all three properties in one case, because they are one
    // behaviour: a pen board that opens mid-minute, updates on the minute with
    // every other tile, and stops costing anything when it closes.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> seen = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, seen);

    await tester.pump();
    expect(seen, hasLength(1), reason: 'immediate');

    await tester.pump(_toBoundary(seen.first));
    expect(seen, hasLength(2));
    expect(seen[1].epochMillis % 60000, 0, reason: 'on the boundary');

    sub.close();
    container.dispose();
    await _drainTail(tester);
    expect(seen, hasLength(2), reason: 'nothing arrives after the last listener goes');
  });

  testWidgets('the first emission is immediate', (WidgetTester tester) async {
    // A tile must not be blank for up to 60 s after the board opens. At 03:20
    // that reads as a broken app, and the shepherd taps it.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> seen = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, seen);

    await tester.pump();
    expect(seen, hasLength(1));

    sub.close();
    container.dispose();
    await _drainTail(tester);
  });

  testWidgets('the second emission lands on the boundary when the first did not', (
    WidgetTester tester,
  ) async {
    // THE ALIGNMENT PROPERTY, ISOLATED, and pumped one millisecond short first
    // so the case cannot pass on a fixed 60 s delay: a fixed delay would still
    // be waiting at the boundary, and would fire 1 ms late — off the boundary.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> seen = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, seen);

    await tester.pump();
    final Duration gap = _toBoundary(seen.first);
    expect(gap.inMilliseconds, lessThanOrEqualTo(60000));

    await tester.pump(gap - const Duration(milliseconds: 1));
    expect(seen, hasLength(1), reason: 'not yet — the boundary is 1 ms away');

    await tester.pump(const Duration(milliseconds: 1));
    expect(seen, hasLength(2));
    expect(seen[1].epochMillis % 60000, 0);

    sub.close();
    container.dispose();
    await _drainTail(tester);
  });

  testWidgets('five simulated minutes produce six emissions', (WidgetTester tester) async {
    // THE RATE, ISOLATED. Not ten, not three hundred. Six because the immediate
    // one is followed by five boundaries, whatever offset the subscription
    // happened to start at — the first gap is short and every later one is 60 s,
    // so the count does not depend on where the clock was.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> seen = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, seen);

    await tester.pump();
    await tester.pump(const Duration(minutes: 5));

    expect(seen, hasLength(6));
    for (final Instant i in seen.skip(1)) {
      expect(i.epochMillis % 60000, 0);
    }

    sub.close();
    container.dispose();
    await _drainTail(tester);
  });

  testWidgets('two listeners share one loop', (WidgetTester tester) async {
    // Each sees six, rather than twelve between them. Riverpod gives both
    // listeners the SAME stream, so a pen board with forty tiles is one wake-up
    // a minute and not forty — which is the difference between a battery that
    // lasts the night and one that does not.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> first = <Instant>[];
    final List<Instant> second = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> a = _subscribe(container, first);
    final ProviderSubscription<AsyncValue<Instant>> b = _subscribe(container, second);

    await tester.pump();
    await tester.pump(const Duration(minutes: 5));

    expect(first, hasLength(6));
    expect(second, hasLength(6));
    expect(first.map((Instant i) => i.epochMillis), second.map((Instant i) => i.epochMillis));

    a.close();
    b.close();
    container.dispose();
    await _drainTail(tester);
  });

  testWidgets('a re-subscription after the last listener leaves starts a new loop with an '
      'immediate emission', (WidgetTester tester) async {
    // The .autoDispose property, expressed the way the async* shape allows
    // (07 §9.2): prove the SUBSCRIPTION is gone and that a new one starts a new
    // loop — not that no timer is outstanding, which would be asserting
    // something the shape deliberately does not promise.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> firstLife = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, firstLife);

    await tester.pump();
    expect(firstLife, hasLength(1));

    sub.close();
    await _drainTail(tester);
    expect(firstLife, hasLength(1), reason: 'the old loop is not still feeding the old listener');

    final List<Instant> secondLife = <Instant>[];
    _subscribe(container, secondLife);
    await tester.pump();
    expect(secondLife, hasLength(1), reason: 'a new loop emits immediately, as at first open');

    container.dispose();
    await _drainTail(tester);
  });

  testWidgets('the provider yields Instant, not DateTime', (WidgetTester tester) async {
    // R25, as a runtime assertion beside the source-text one above. Cheap, and
    // the two fail differently: a changed declaration and a changed emission.
    final ProviderContainer container = ProviderContainer();
    final List<Instant> seen = <Instant>[];
    final ProviderSubscription<AsyncValue<Instant>> sub = _subscribe(container, seen);

    await tester.pump();
    expect(seen.single, isA<Instant>());

    sub.close();
    container.dispose();
    await _drainTail(tester);
  });

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

  test('the resume refresh is written exactly once, in app.dart, on the ticker', () {
    // CLOSED ON 2026-08-02, and the shape of the close is the point. N12-T03
    // §5.2 offered two moves: a fifth `[exempt]` line, or narrowing the rule.
    // The `[exempt]` line was the wrong one — it deletes stream.invalidate for
    // lib/app.dart forever and silently, and it would not have reached the
    // SECOND architected call site at all (databaseProvider, 04 §7 step 14).
    //
    // The rule now carries a negative lookahead for the two architected
    // arguments and still fires on every other one. The allowlist is untouched.
    const String needle =
        'ref.in'
        'validate(';

    final Map<String, int> byFile = <String, int>{};
    for (final String path in _authoredDart('lib')) {
      final int n = needle.allMatches(_declarations(path)).length;
      if (n > 0) {
        byFile[path] = n;
      }
    }

    expect(byFile, <String, int>{'lib/app.dart': 1});
    expect(
      _declarations('lib/app.dart'),
      contains('${needle}minuteTickProvider)'),
      reason: '02 §4.1: the ticker is the argument, and a second one is a defect',
    );
  });

  test('the allowlist still has exactly four exempt lines', () {
    // R56, and it is what makes the case above meaningful: the refresh landed
    // WITHOUT buying a fifth line. If one ever appears, this is where it is
    // noticed.
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
