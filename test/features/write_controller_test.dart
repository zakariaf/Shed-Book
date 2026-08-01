// test/features/write_controller_test.dart
//
// Pure ProviderContainer tests plus source-text sweeps. There is no widget test
// here AND THAT ABSENCE IS DELIBERATE: there is no screen until N13, so the
// per-screen double-tap tests — `tester.tap(); tester.tap();` with NO PUMP
// BETWEEN THE TAPS, which is what makes them a real double tap rather than two
// separate ones — arrive one per screen epic from N14 onward (12 §10.1).
//
// NOTHING HERE IS TIME-SHAPED. guard() reads no clock, stores no instant and
// takes no Duration, so the only asynchrony below is a Completer this file
// resolves by hand (12 §11.6 bans Future.delayed in a test body outright). There
// is therefore no uk-zone case — and the moment somebody adds a timeout or a
// cooldown to guard(), this task acquires one.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';

const String _file = 'lib/core/write_action.dart';

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// A write controller whose action the TEST completes, so concurrency is a fact
/// the test controls rather than a race it hopes for.
///
/// It also proves the base class is subclassable OUTSIDE `lib/core/` — the shape
/// N14's `quickEntryWriteControllerProvider` copies.
final class _SlowWriteController extends WriteController {
  int invocations = 0;
  Completer<WriteOutcome> completer = Completer<WriteOutcome>();

  Future<void> go() => guard(() {
    invocations += 1;
    return completer.future;
  });

  /// `state` is `@protected` on the notifier, so a test outside the class needs
  /// a reader. Used only by the disposal case, where the container is gone and
  /// reading through it would build a fresh controller.
  WriteState peek() => state;
}

/// A controller whose action throws before it ever returns an outcome — a bad
/// cast, a null id, a closure that dies before the transaction opens.
final class _ThrowingWriteController extends WriteController {
  Future<void> go() => guard(() async => throw StateError('a bug, not a failure'));
}

/// A controller that returns whatever outcome the test hands it.
final class _FixedWriteController extends WriteController {
  WriteOutcome outcome = const WriteCommitted();

  Future<void> go() => guard(() async => outcome);
}

final AutoDisposeNotifierProvider<_SlowWriteController, WriteState> _slowProvider =
    NotifierProvider.autoDispose<_SlowWriteController, WriteState>(_SlowWriteController.new);

final AutoDisposeNotifierProvider<_ThrowingWriteController, WriteState> _throwingProvider =
    NotifierProvider.autoDispose<_ThrowingWriteController, WriteState>(
      _ThrowingWriteController.new,
    );

final AutoDisposeNotifierProvider<_FixedWriteController, WriteState> _fixedProvider =
    NotifierProvider.autoDispose<_FixedWriteController, WriteState>(_FixedWriteController.new);

/// Holds the three providers alive for the life of [container].
///
/// **MEASURED, AND NOT OPTIONAL.** These providers are `.autoDispose`, and
/// `container.read` opens a subscription and closes it again — so a notifier
/// obtained that way is disposed before the test's completer ever fires,
/// `_disposed` is true, the assignment is skipped and the state reads back as
/// `WriteIdle`. That is the production behaviour working exactly as N14 needs it
/// to; it is the TEST that has to hold a listener, the way a mounted screen does.
void _keepAlive(ProviderContainer c) {
  for (final AutoDisposeNotifierProvider<WriteController, WriteState> p
      in <AutoDisposeNotifierProvider<WriteController, WriteState>>[
        _slowProvider,
        _throwingProvider,
        _fixedProvider,
      ]) {
    c.listen<WriteState>(p, (WriteState? previous, WriteState next) {});
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    _keepAlive(container);
  });
  tearDown(() => container.dispose());

  test('guard() refuses a second invocation while the first is running', () async {
    // THE ANCHOR. A cold thumb on capacitive glass through a bag double-fires —
    // it is hardware, not user error — and without this gate the second fire is
    // a second lambing record.
    //
    // `invocations, 1` is the assertion that matters: it proves the closure was
    // never ENTERED, which is a stronger statement than "the state did not
    // change twice".
    final _SlowWriteController notifier = container.read(_slowProvider.notifier);

    unawaited(notifier.go()); // deliberately not awaited
    unawaited(notifier.go()); // the second tap, in the same microtask turn

    expect(notifier.invocations, 1);
    expect(container.read(_slowProvider), isA<WriteRunning>());

    notifier.completer.complete(const WriteCommitted());
    await pumpEventQueue();

    expect(container.read(_slowProvider), isA<WriteDone>());
  });

  test('the refused call completes normally and throws nothing', () async {
    // The refusal is a RETURN. The second call finishes its Future<void>
    // immediately having done nothing — it does not throw, it does not queue,
    // and it does not become a WriteRefused (decision #91: that variant means
    // the free-tier policy declined, and it comes from a repository).
    final _SlowWriteController notifier = container.read(_slowProvider.notifier);

    unawaited(notifier.go());
    final Future<void> refused = notifier.go();

    await expectLater(refused, completes);
    expect(notifier.invocations, 1);

    notifier.completer.complete(const WriteCommitted());
    await pumpEventQueue();
  });

  test('state moves Idle to Running to Done and never skips', () async {
    final List<WriteState> seen = <WriteState>[];
    seen.add(container.read(_slowProvider)); // the build() value
    container.listen<WriteState>(_slowProvider, (WriteState? _, WriteState next) => seen.add(next));

    final _SlowWriteController notifier = container.read(_slowProvider.notifier);
    unawaited(notifier.go());
    notifier.completer.complete(const WriteCommitted());
    await pumpEventQueue();

    expect(seen.map((WriteState s) => s.runtimeType).toList(), <Type>[
      WriteIdle,
      WriteRunning,
      WriteDone,
    ]);
  });

  test('WriteRunning is set before the first await', () async {
    // THE ONE ASSERTION THAT CATCHES THE MISORDERING. Write
    // `final repo = await ref.read(...)` ahead of the assignment and the second
    // tap arrives while state is still WriteIdle, both calls pass the check, and
    // the whole defence is decoration.
    //
    // Read synchronously — no await between the call and the expect — because an
    // await here would let a microtask run and hide exactly that bug.
    final _SlowWriteController notifier = container.read(_slowProvider.notifier);

    final Future<void> running = notifier.go();
    expect(container.read(_slowProvider), isA<WriteRunning>());

    notifier.completer.complete(const WriteCommitted());
    await running;
  });

  test('a second call after the first completes runs the action again', () async {
    // 02 §7.1 rule 1: guard() prevents CONCURRENCY, NOT REPETITION. Stated as a
    // test so nobody adds a cooldown to make the anchor "safer" — a cooldown
    // drops a legitimate second lamb. Where an action must not repeat after
    // completion, the REPOSITORY makes it idempotent.
    final _SlowWriteController notifier = container.read(_slowProvider.notifier);

    unawaited(notifier.go());
    notifier.completer.complete(const WriteCommitted());
    await pumpEventQueue();

    notifier.completer = Completer<WriteOutcome>();
    unawaited(notifier.go());

    expect(notifier.invocations, 2);
    notifier.completer.complete(const WriteCommitted());
    await pumpEventQueue();
  });

  test(
    'a throwing action becomes WriteFailed(UnexpectedFailure), not a thrown exception',
    () async {
      // A swallowed exception is a silent correction of the worst kind: the record
      // did not land and the app said nothing (§12.4). `on Object catch`, because
      // an Error — a bad cast, a null check — is precisely the case `on Exception`
      // would let through.
      final _ThrowingWriteController notifier = container.read(_throwingProvider.notifier);

      await expectLater(notifier.go(), completes);

      final WriteState state = container.read(_throwingProvider);
      expect(state, isA<WriteDone>());

      final WriteOutcome outcome = (state as WriteDone).outcome;
      expect(outcome, isA<WriteFailed>());
      expect((outcome as WriteFailed).failure, isA<UnexpectedFailure>());
      expect((outcome.failure as UnexpectedFailure).error, isA<StateError>());
    },
  );

  test('an action returning WriteFailed passes it through unchanged', () async {
    // The repository's own mapped failure is not re-wrapped. Re-wrapping would
    // turn a known DiskFull — which has a sentence a shepherd can act on — into
    // an UnexpectedFailure, which has none.
    const WriteFailed mapped = WriteFailed(DiskFull());
    final _FixedWriteController notifier = container.read(_fixedProvider.notifier)
      ..outcome = mapped;

    await notifier.go();

    expect((container.read(_fixedProvider) as WriteDone).outcome, same(mapped));
  });

  test('an action returning WriteRefused passes it through unchanged', () async {
    // The gate never MANUFACTURES a refusal and never SWALLOWS one.
    const WriteRefused refused = WriteRefused(RefusalReason.eweCap);
    final _FixedWriteController notifier = container.read(_fixedProvider.notifier)
      ..outcome = refused;

    await notifier.go();

    expect((container.read(_fixedProvider) as WriteDone).outcome, same(refused));
  });

  test('disposal mid-flight does not throw and does not assign state', () async {
    // The screen may be popped while the transaction runs. The write itself
    // completed — drift does not care that the provider is gone — and 2.6.1 has
    // no `Ref.mounted` (02 §2.1), which is why `_disposed` exists at all.
    //
    // ASSERTED THROUGH THE NOTIFIER'S OWN `state`, not through the container:
    // the container is disposed by then, so reading the provider through it
    // would build a FRESH controller and prove nothing about this one.
    //
    // MEASURED, and it corrects 02 §7's printed comment: the assignment does not
    // throw on this pin — the disposed element swallows it. Drilled by deleting
    // `if (_disposed) return;`, and with that line gone the second expect below
    // reads WriteDone. So `completes` alone would be a vacuous case; the state
    // assertion is the one holding the mechanism.
    final ProviderContainer own = ProviderContainer();
    _keepAlive(own);
    final _SlowWriteController notifier = own.read(_slowProvider.notifier);

    final Future<void> inFlight = notifier.go();
    own.dispose();
    notifier.completer.complete(const WriteCommitted());

    await expectLater(inFlight, completes);
    expect(notifier.peek(), isA<WriteRunning>());
  });

  test('two identical outcomes produce two distinct WriteDone notifications', () async {
    // The no-`==` property, as BEHAVIOUR rather than as source text. Each
    // completed write owes the user its own haptic, its own confirmation and its
    // own uniquely-labelled live region (decision #103) — collapse the two and
    // the second saved lamb gets nothing and the shepherd taps again.
    int notifications = 0;
    container.listen<WriteState>(_fixedProvider, (WriteState? _, WriteState next) {
      if (next is WriteDone) {
        notifications += 1;
      }
    });

    final _FixedWriteController notifier = container.read(_fixedProvider.notifier);
    await notifier.go();
    await notifier.go();

    expect(notifications, 2);
  });

  test('no WriteState subclass declares operator ==', () {
    // Source text, because the behavioural case above only covers the subclass
    // it exercises. Adding an `==` — or reaching for a value-equality package, or
    // making the state a record — breaks every one of them at once.
    const String needle =
        'operator '
        '==';
    expect(_declarations(_file), isNot(contains(needle)));
    expect(_declarations(_file), isNot(contains('hashCode')));
  });

  test('build() watches nothing', () {
    // If build() watched something it would re-run when that thing changed — and
    // 2.6.1 PRESERVES THE NOTIFIER INSTANCE across a build() re-run (02 §3), so
    // `_disposed = false` would execute mid-flight while state was reset to
    // WriteIdle. The in-flight write then completes into a controller that
    // thinks it is idle, and the next tap starts a second one.
    expect(_declarations(_file), isNot(contains('ref.watch')));
    // SPLIT ACROSS TWO LITERALS. `rp3.ref_mounted` is a gate row matching this
    // exact text, and this file is scanned — a needle written whole fires the
    // rule it exists to check for. The twenty-first time in this project.
    const String refMounted =
        'ref'
        '.mounted';
    expect(_declarations(_file), isNot(contains(refMounted)));
  });

  test('write_action.dart imports nothing under lib/data/', () {
    // The layer rule, and specifically the failure_mapping.dart temptation:
    // translating a SqliteException into a ShedFailure is the repository's job
    // through the one top-level shedFailureFrom (R4), and putting that mapping
    // here would drag package:sqlite3 into lib/core/.
    final String imports = _declarations(
      _file,
    ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

    for (final String forbidden in <String>['data/', 'drift', 'sqlite3']) {
      expect(imports, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('no Timer, Duration or cooldown field exists in write_action.dart', () {
    // Rule 1 as a mechanical assertion. A UI cooldown is not the mechanism for
    // "must not repeat" and it would drop a legitimate second lamb.
    final String source = _declarations(_file);
    for (final String banned in <String>[
      'Timer',
      'Duration',
      'lastTapAt',
      'debounce',
      'cooldown',
    ]) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('UnexpectedFailure is constructed at exactly two sites in lib/', () {
    // R8, asserted per FILE rather than per line, which is the honest reading:
    // shedFailureFrom reaches its fallback from two arms of a nested switch, so
    // it constructs on two lines and is still one site. A THIRD FILE is a second
    // opinion about what "unexpected" means, and that is what this catches.
    // The generative constructor in failure.dart is a DECLARATION, not a
    // construction site, and it is the one line excluded here — matched on
    // `this.`, which no call site can contain.
    final List<String> sites =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .map((File f) => f.path.replaceAll(r'\', '/'))
            .where((String p) => p.endsWith('.dart') && !p.endsWith('.g.dart'))
            .where(
              (String p) => _declarations(p)
                  .split('\n')
                  .where((String l) => !l.contains('UnexpectedFailure(this.'))
                  .any((String l) => l.contains('UnexpectedFailure(')),
            )
            .toList()
          ..sort();

    expect(sites, <String>['lib/core/write_action.dart', 'lib/data/failure_mapping.dart']);
  });
}
