// test/data/providers_test.dart — the DI root.
//
// Pure unit tests plus source-text sweeps. No widget test: there is nothing to
// pump until T05.
//
// Nothing here is time-shaped — no wall clock is read and no Instant is
// constructed. T02's InstantConverter round trip is this epic's first.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/free_tier.dart';

const String _providers = 'lib/data/providers.dart';
const String _conventions = 'docs/engineering/CONVENTIONS.md';

List<String> _authoredDart(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where(
          (String p) =>
              p.endsWith('.dart') &&
              !p.endsWith('.g.dart') &&
              !p.endsWith('.drift.dart') &&
              !p.contains('app_localizations'),
        )
        .toList()
      ..sort();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// Top-level `final … fooProvider = …` declarations in [_providers].
Set<String> _declaredProviders() => RegExp(
  r'^final\s+[\w<>, ]+\s+(\w+Provider)\s*=',
  multiLine: true,
).allMatches(_declarations(_providers)).map((RegExpMatch m) => m.group(1)!).toSet();

/// The `DECLARED TODAY` block's names, read out of the header ledger.
Set<String> _ledger() {
  final String header = File(_providers).readAsStringSync();
  final int start = header.indexOf('DECLARED TODAY');
  final int end = header.indexOf('NOT YET DECLARED');
  expect(start, isNot(-1), reason: 'the ledger is gone');
  expect(end, greaterThan(start));
  // The FIRST column only. A ledger line reads
  //   databaseProvider  N12-T01  FutureProvider<AppDatabase>  keepAlive
  // so a bare `\w+Provider` sweep also picks up the TYPE — which is how the
  // first version of this case demanded a provider called `FutureProvider`.
  return RegExp(
    r'^//\s{3}(\w+Provider)\b',
    multiLine: true,
  ).allMatches(header.substring(start, end)).map((RegExpMatch m) => m.group(1)!).toSet();
}

void main() {
  test('databaseProvider is a keepAlive FutureProvider and no override appears under lib/', () {
    // THE ANCHOR, and it is three claims: the SHAPE (a FutureProvider, so the
    // open is async and cannot be awaited before the first frame), the
    // REACHABILITY (keepAlive, so a popped screen does not close SQLite at
    // 03:41), and the POLICY (production has no overrides at all).
    expect(databaseProvider, isA<FutureProvider<Object?>>());

    final String source = _declarations(_providers);
    expect(source, isNot(contains('.autoDispose')));

    for (final String path in _authoredDart('lib')) {
      final String file = _declarations(path);
      expect(file, isNot(contains('overrideWith')), reason: path);
      expect(file, isNot(contains('overrideWithValue')), reason: path);
    }
  });

  test('reading databaseProvider under flutter_test throws and names the override to add', () {
    // THE ANTI-PATTERN TRIPWIRE (02 §5.4). Without it, a test that forgets the
    // override opens a real database file in somebody's home directory and
    // passes.
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    Object? thrown;
    try {
      container.read(databaseProvider);
      // The future is what throws; reading the provider only starts it.
      container.read(databaseProvider.future).ignore();
    } on Object catch (e) {
      thrown = e;
    }

    // The assertion fires inside openAppDatabase(), synchronously or on the
    // future. Either way the message has to say what to do, not just that
    // something went wrong.
    final String message = (thrown ?? container.read(databaseProvider)).toString();
    expect(
      message.toLowerCase(),
      anyOf(contains('test'), contains('loading')),
      reason: 'the failure must name the missing override, not just fail',
    );
  });

  test('Provider<AppDatabase> appears nowhere under lib/', () {
    // Decision #20 and CONVENTIONS §3.5. A synchronous provider would have to be
    // overridden with an ALREADY-OPEN database, which means somebody awaited it
    // before the first frame.
    // NEGATIVE LOOKBEHIND, because `FutureProvider<AppDatabase>` CONTAINS the
    // banned string. The first version of this case failed on the very
    // declaration it is meant to protect — a substring search cannot tell a
    // synchronous provider from an asynchronous one.
    final RegExp synchronous = RegExp(
      r'(?<!Future)Provider<App'
      'Database>',
    );
    for (final String path in _authoredDart('lib')) {
      expect(synchronous.hasMatch(_declarations(path)), isFalse, reason: path);
    }
  });

  test('package:riverpod is imported nowhere — only flutter_riverpod', () {
    // The bare package is the one without the widget bindings; importing it is
    // how two copies of the same provider end up in one tree.
    // Split across adjacent literals: this file lives under a scanned root, so
    // a whole needle here makes the case fire on itself.
    const String needle =
        "import 'package:river"
        "pod/";
    final RegExp bare = RegExp(RegExp.escape(needle));
    for (final String path in <String>[..._authoredDart('lib'), ..._authoredDart('test')]) {
      expect(bare.hasMatch(File(path).readAsStringSync()), isFalse, reason: path);
    }
  });

  test('the type name Ref appears nowhere in providers.dart', () {
    // Word-anchored, so `WidgetRef` and `ref.` do not false-positive.
    //
    // `Ref` is the Riverpod 3 spelling and this project is pinned to 2.6.1
    // EXACTLY. The awkward part is that 2.6.1 deprecates `FutureProviderRef` in
    // favour of it — so naming EITHER is wrong, and the callback parameters are
    // left untyped. That satisfies both the ban and --fatal-infos.
    expect(_declarations(_providers), isNot(matches(RegExp(r'\bRef\b'))));
  });

  test('freeTierPolicyProvider resolves without touching the database', () {
    // The property decisions #21 and #90 both lean on: the first frame's policy
    // object needs nothing async, so nothing monetization-shaped has to wait for
    // SQLite — or run on a shed screen at all.
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(freeTierPolicyProvider), isA<FreeTierPolicy>());
  });

  test('the declared provider set equals the header ledger', () {
    // THE LEDGER IS THE CONTRACT. A provider added without a ledger line fails
    // here, which is the moment somebody would otherwise stub one — and a
    // provider whose body throws UnimplementedError is not a placeholder, it is
    // a lie that compiles.
    expect(_declaredProviders(), _ledger());
    // THE LITERAL GROWS ONE LINE PER EPIC, on purpose. The assertion above is
    // the real contract — declared set equals ledger — and this one is the
    // tripwire that makes adding a provider a deliberate act in two places
    // rather than one: a ledger line and a body agree with each other trivially
    // if the same hand wrote both in the same minute.
    expect(_declaredProviders(), <String>{
      'databaseProvider',
      'freeTierPolicyProvider',
      'settingsRepositoryProvider',
      'settingsProvider',
      'themeProvider',
      'unitsProvider',
      'terminologyProvider',
      // N13-T02
      'flockRepositoryProvider',
      'tagIndexProvider',
      // N14-T02
      'lambingRepositoryProvider',
      // N15-T01, N15-T02
      'mediaStoreProvider',
      'cameraServiceProvider',
      // N15-T03
      'voiceRecorderProvider',
      // N15-T04
      'noteRepositoryProvider',
    });
  });

  test('every declared provider name appears in CONVENTIONS §3.1', () {
    // A SUBSET, never a superset. Catches an invented name — dbProvider,
    // appDatabaseProvider — at the moment it is written rather than three epics
    // later when something imports it.
    final String catalogue = File(_conventions).readAsStringSync();
    for (final String name in _declaredProviders()) {
      expect(catalogue, contains(name), reason: '$name is not in the catalogue');
    }
  });
}
