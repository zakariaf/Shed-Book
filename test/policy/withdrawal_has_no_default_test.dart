// test/policy/withdrawal_has_no_default_test.dart — safety rule §12.1, *never
// default a medicine withdrawal period*, held as claims about the artefact
// rather than about a value.
//
// **This file is not finished, and it is not meant to look finished.** §12.1 is
// held in three halves, in three different tasks, and they accumulate here:
//
//   1. N05-T01 — the UNCONSTRUCTIBLE half. WithdrawalDays has one generative
//      constructor, it is private, and the only public entry point is named for
//      where the number came from.                                    [present]
//   2. N05-T04 — the SOURCE half. No literal withdrawal day count appears
//      anywhere under lib/ — not in a constant, not in an example, not in a
//      placeholder, and not in a comment a future contributor will copy.
//                                                                     [present]
//   3. N07-T08 — the UNPERSISTABLE half, against
//      drift_schemas/drift_schema_v1.json: treatment_withdrawals.days carries a
//      null defaultValue and a null clientDefault, and NO ROW means not
//      recorded.                                                      [MISSING]
//
// The fourth proof is a widget test on the entry control, in N20-T02.
//
// If you are here because you added a half, add it to the list. If you are here
// because one is still marked MISSING, it has not been written yet.
//
// Why all of it is in ONE file: 12 §1.4 sends source-text assertions to
// tool/check_policy.dart, and the rule immediately above it is decision #52's
// TWO GATES AND NO MORE. Splitting §12.1's proof across two files would leave a
// reader of this one believing they had seen the whole rule. 03 §5.8, 05 §3.9
// and 12 §10.3 all name this path.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _path = 'lib/domain/withdrawal/withdrawal_period.dart';

/// The file with comment lines dropped, so a doc comment naming the thing we
/// ban cannot be mistaken for the thing itself.
String _declarations() =>
    File(_path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// The interior of `final class <name>`, from its opening brace to the matching
/// close. Comment lines are already gone.
String _classBody(String name) {
  final String source = _declarations();
  final int declaration = source.indexOf('final class $name');
  if (declaration < 0) {
    throw StateError('$_path declares no `final class $name`');
  }
  final int open = source.indexOf('{', declaration);
  int depth = 0;
  for (int i = open; i < source.length; i++) {
    if (source[i] == '{') {
      depth++;
    } else if (source[i] == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(open + 1, i);
      }
    }
  }
  throw StateError('unbalanced braces in $_path');
}

final RegExp _constructor = RegExp(r'(factory\s+|const\s+)?WithdrawalDays(\.\w+)?\s*\(');

/// Constructor declarations of `WithdrawalDays`, as `(isFactory, name)` — where
/// the name is `''` for an unnamed one.
///
/// Two filters, and both are load-bearing, because the one correct call site —
/// `return WithdrawalDays._(days, target);` inside the factory — matches the
/// same regex as the declaration it is calling. A bare `contains` would read it
/// as a second entry point.
///
///   - **Brace depth 0** drops invocations inside a braced constructor body.
///   - **The character before the match** drops the ones depth cannot see. An
///     arrow-bodied factory has no braces at all, so `=> WithdrawalDays._(…)`
///     sits at depth 0 and is otherwise indistinguishable from a declaration.
///     A declaration follows `;`, `{`, `}` or the start of the class body;
///     an invocation follows `=>`, `return`, `=` or a comma.
///
/// This was found by planting a second factory and reading *why* the anchor went
/// red: it reported two generative constructors where the plant added none.
List<(bool, String)> _constructorsOfWithdrawalDays() {
  final String body = _classBody('WithdrawalDays');
  final List<int> depthAt = List<int>.filled(body.length, 0);
  int depth = 0;
  for (int i = 0; i < body.length; i++) {
    depthAt[i] = depth;
    if (body[i] == '{') {
      depth++;
    } else if (body[i] == '}') {
      depth--;
    }
  }

  bool isDeclaration(int start) {
    if (depthAt[start] != 0) {
      return false;
    }
    final String before = body.substring(0, start).trimRight();
    return before.isEmpty || <String>[';', '{', '}'].contains(before[before.length - 1]);
  }

  return <(bool, String)>[
    for (final RegExpMatch m in _constructor.allMatches(body))
      if (isDeclaration(m.start))
        ((m.group(1) ?? '').trimRight() == 'factory', (m.group(2) ?? '').replaceFirst('.', '')),
  ];
}

// ---------------------------------------------------------------------------
// The source half (N05-T04): the scanner, and the scope it runs over.
// ---------------------------------------------------------------------------

/// Where the private constructor is allowed to be called.
const String _periodFile = 'lib/domain/withdrawal/withdrawal_period.dart';

/// A hit. Empty means clean.
typedef Hit = ({String path, int line, String why});

/// Source with every run of whitespace collapsed to one space, and a map from
/// each character back to the line it came from.
///
/// The collapse is the fix for a trap found while the research was written, not
/// theorised: Dart wraps long text across a line break, so a naive
/// `text.contains(…)` misses the moment somebody splits `const
/// kDefaultWithdrawalDays` over two lines. The line map is what keeps the
/// failure message useful after the collapse.
({String text, List<int> lineOf}) _flatten(String raw) {
  final StringBuffer out = StringBuffer();
  final List<int> lineOf = <int>[];
  int line = 1;
  bool lastWasSpace = false;
  for (int i = 0; i < raw.length; i++) {
    final String c = raw[i];
    final bool isSpace = c == ' ' || c == '\n' || c == '\t' || c == '\r';
    if (!isSpace || !lastWasSpace) {
      out.write(isSpace ? ' ' : c);
      lineOf.add(line);
    }
    lastWasSpace = isSpace;
    if (c == '\n') {
      line++;
    }
  }
  return (text: out.toString(), lineOf: lineOf);
}

/// A `const` / `final` / `static const` declaration initialised to an integer
/// literal. The identifier is checked afterwards, not in the pattern, so the
/// reason string can quote it.
final RegExp _intConstant = RegExp(
  r'\b(?:static\s+)?(?:const|final)\s+(?:int\s+)?(\w+)\s*=\s*-?\d+',
);

/// Every literal withdrawal day count in one file's text.
///
/// **This is not the heuristic decision #52 rejects, and the difference has to
/// be visible here.** What #52 rejects, by name in three documents, is *"a
/// source heuristic banning a numeric literal near the word withdrawal"* — that
/// one fires on `CHECK (days IS NULL OR days >= 0)`, on `CHECK (target IN
/// ('meat','milk'))`, on every fixture and on the doc set's own examples. *"A
/// gate with a standing false positive gets an allowlist, then gets weakened,
/// then gets deleted — and it is guarding the one rule whose regression is a
/// food-safety incident."*
///
/// So there is no proximity match anywhere below. Each of the three shapes is a
/// **construction or declaration site**:
///
///   1. a call to `asEnteredByUser(` whose `days:` argument is an integer
///      literal — the only entry point, handed a number nobody typed;
///   2. a `const`/`final` declaration whose identifier carries both a withdrawal
///      token and a day token, initialised to an integer literal — that is
///      `const kDefaultWithdrawalDays = 7` in every spelling of it;
///   3. `WithdrawalDays._(` outside its own file — the private constructor
///      reached through a `part`, the one hole `sealed` does not close.
///
/// The negative self-test below is what keeps this honest, and it is not
/// optional. If it ever cannot be kept green without an allowlist line, the
/// scan is the wrong scan and must be deleted rather than exempted.
///
/// Comments are IN SCOPE on purpose: a commented-out default is the most copied
/// line in any codebase.
List<Hit> literalWithdrawalDays(String path, String rawText) {
  if (path.endsWith('.g.dart') || path.endsWith('.drift.dart')) {
    // Regenerated by `make gen` and always waved through in review. A scan that
    // reads them is a scan that goes red on a drift_dev bump.
    return const <Hit>[];
  }

  final ({String text, List<int> lineOf}) flat = _flatten(rawText);
  final String text = flat.text;
  final List<Hit> hits = <Hit>[];
  int lineAt(int index) => flat.lineOf[index];

  // Shape 1. The argument list is walked to its matching close paren rather than
  // matched with a regex, so a nested call in an earlier argument cannot end the
  // scan early or run it past the end.
  const String entryPoint = 'asEnteredByUser(';
  for (int i = text.indexOf(entryPoint); i >= 0; i = text.indexOf(entryPoint, i + 1)) {
    final int open = i + entryPoint.length - 1;
    int depth = 0;
    int close = open;
    for (; close < text.length; close++) {
      if (text[close] == '(') {
        depth++;
      } else if (text[close] == ')') {
        depth--;
        if (depth == 0) {
          break;
        }
      }
    }
    final String arguments = text.substring(open, close.clamp(open, text.length));
    if (RegExp(r'days:\s*-?\d').hasMatch(arguments)) {
      hits.add((
        path: path,
        line: lineAt(i),
        why: 'asEnteredByUser called with an integer literal for days:',
      ));
    }
  }

  // Shape 2.
  for (final RegExpMatch m in _intConstant.allMatches(text)) {
    final String identifier = m.group(1)!;
    final String lower = identifier.toLowerCase();
    if (lower.contains('withdraw') && lower.contains('day')) {
      hits.add((
        path: path,
        line: lineAt(m.start),
        why: 'declaration initialised to an integer literal ($identifier)',
      ));
    }
  }

  // Shape 3.
  if (path != _periodFile) {
    const String privateConstructor = 'WithdrawalDays._(';
    for (
      int i = text.indexOf(privateConstructor);
      i >= 0;
      i = text.indexOf(privateConstructor, i + 1)
    ) {
      hits.add((
        path: path,
        line: lineAt(i),
        why: 'the private constructor called outside $_periodFile',
      ));
    }
  }

  return hits;
}

/// Every non-generated Dart file under `lib/`. **Never `test/`** — this file
/// carries all three shapes as fixtures and would match itself, and so would
/// every future seed. Scoping to `lib/` is the second reason the false-positive
/// set is empty.
List<String> _libSources() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart'))
        .toList()
      ..sort();

String _render(List<Hit> hits) => hits.map((Hit h) => '${h.path}:${h.line} — ${h.why}').join('\n');

void main() {
  test('WithdrawalPeriod has no public generative constructor', () {
    // The name is broader than the assertion, deliberately. Two of the three
    // subclasses DO have public generative constructors — the two marker states
    // — and so does the sealed base. That is correct: `sealed` already stops the
    // base being extended outside its library, and neither marker carries a
    // number anybody could be wrong about. Only WithdrawalDays is locked,
    // because it is the only one holding a figure read off a bottle. Widen this
    // to "no subclass has a public constructor" and the very next task weakens
    // it again.
    final List<(bool, String)> generative = _constructorsOfWithdrawalDays()
        .where(((bool, String) c) => !c.$1)
        .toList();

    expect(
      generative,
      <(bool, String)>[(false, '_')],
      reason:
          'the one generative constructor is private, so no expression '
          'outside this library can produce a withdrawal period the user did '
          'not type',
    );
  });

  test('withdrawal_period.dart declares no part and is named by no part of', () {
    // `_` is library-private, not class-private: anything else in this library
    // could call WithdrawalDays._. So the library is this one file, and this is
    // the only hole left in the mechanism.
    final String declarations = _declarations();
    expect(declarations, isNot(matches(RegExp(r'^\s*part\s+', multiLine: true))));
    expect(declarations, isNot(matches(RegExp(r'^\s*part\s+of\s+', multiLine: true))));

    final List<String> partsNamingThisFile = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart'))
        .where((String p) => File(p).readAsStringSync().contains('withdrawal_period.dart'))
        .where((String p) => File(p).readAsStringSync().contains('part of'))
        .toList();
    expect(partsNamingThisFile, isEmpty);
  });

  test('WithdrawalDays.asEnteredByUser is the only factory on WithdrawalDays', () {
    // A second factory is a second entry point whatever it is called, and the
    // names it would be called — `unknown`, `none`, `standard` — are the whole
    // problem.
    final List<String> factories = _constructorsOfWithdrawalDays()
        .where(((bool, String) c) => c.$1)
        .map(((bool, String) c) => c.$2)
        .toList();

    expect(factories, <String>['asEnteredByUser']);
  });

  test('no literal withdrawal day count appears anywhere under lib/', () {
    // The type from N05-T01 stops a VALUE. It cannot stop somebody writing
    // `const kDefaultWithdrawalDays = 7` and handing it to the factory, because
    // the factory cannot tell a typed 7 from a hard-coded one. This is that gap,
    // and it is the last one that is cheap to close before twelve screens exist.
    final List<Hit> hits = <Hit>[
      for (final String path in _libSources())
        ...literalWithdrawalDays(path, File(path).readAsStringSync()),
    ];

    expect(hits, isEmpty, reason: 'a withdrawal day count nobody typed:\n${_render(hits)}');
  });

  test('the scan names the file and the line of a planted default', () {
    // A bare `expect(hits, isEmpty)` at 3am tells a developer nothing. Path,
    // line and reason are the deliverable.
    final List<Hit> hits = literalWithdrawalDays(
      'lib/features/treatments/entry.dart',
      'class Entry {\n'
          '  void build() {}\n'
          '  static const int kDefaultWithdrawalDays = 7;\n'
          '}\n',
    );

    expect(hits.single.path, 'lib/features/treatments/entry.dart');
    expect(hits.single.line, 3);
    expect(hits.single.why, contains('kDefaultWithdrawalDays'));
  });

  test('the scan fires on a literal handed to asEnteredByUser', () {
    final List<Hit> hits = literalWithdrawalDays(
      'lib/features/treatments/repeat.dart',
      'final p = WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat);\n',
    );

    expect(hits, hasLength(1));
    expect(hits.single.why, contains('integer literal for days:'));
  });

  test('the scan fires on the private constructor called outside its own file', () {
    // Shape 3: the one hole `sealed` does not close, because `_` is
    // library-private and a `part` of withdrawal_period.dart would be inside it.
    final String planted = 'const p = WithdrawalDays._(7, WithdrawalTarget.meat);\n';

    expect(literalWithdrawalDays('lib/data/treatments_repository.dart', planted), hasLength(1));
    expect(
      literalWithdrawalDays(_periodFile, planted),
      isEmpty,
      reason: 'its own file is where the one call site lives',
    );
  });

  test('the scan is silent on the schema CHECK constraints and on the implausibility guard', () {
    // THE test that keeps this assertion honest against decision #52. Every line
    // below contains the word and a number, and a proximity heuristic fires on
    // all of them. None of them is a default.
    const String innocent =
        "  CHECK (days IS NULL OR days >= 0),\n"
        "  CHECK (kind IN ('days','not_applicable')),\n"
        "  CHECK (target IN ('meat','milk')),\n"
        '  if (days < 0) throw ArgumentError.value(days, "days", "must be >= 0");\n'
        '  if (days > 1000) throw ArgumentError.value(days, "days", "implausible");\n'
        '  /// A 7-day withdrawal administered at 20:00 clears 8 days later.\n'
        '  final int withdrawalRowCount = 2;\n'
        '  const int kDayMillis = 86400000;\n';

    expect(literalWithdrawalDays('lib/data/schema.dart', innocent), isEmpty);
  });

  test('the scan is silent on a day count read from a row or a parameter', () {
    const String fromData =
        'WithdrawalDays.asEnteredByUser(days: typed, target: t);\n'
        'WithdrawalDays.asEnteredByUser(days: row.days!, target: t);\n'
        'WithdrawalDays.asEnteredByUser(days: int.parse(text), target: t);\n';

    expect(literalWithdrawalDays('lib/data/treatments_repository.dart', fromData), isEmpty);
  });

  test('the scan reads comments, because a commented-out default is one a contributor '
      'will copy', () {
    final List<Hit> hits = literalWithdrawalDays(
      'lib/features/treatments/entry.dart',
      '// TODO: bring this back\n'
          '// const kDefaultWithdrawalDays = 7;\n',
    );

    expect(hits, hasLength(1));
    expect(hits.single.line, 2);
  });

  test('the scan skips generated files', () {
    const String planted = 'const kDefaultWithdrawalDays = 7;\n';

    expect(literalWithdrawalDays('lib/data/db/database.g.dart', planted), isEmpty);
    expect(literalWithdrawalDays('lib/data/db/tables.drift.dart', planted), isEmpty);
    expect(
      literalWithdrawalDays('lib/data/db/database.dart', planted),
      hasLength(1),
      reason: 'and only because they are generated — the same text is a defect anywhere else',
    );
  });

  test('the scan sees a declaration split across a line break', () {
    // The long-string trap, as it bites shape 2. Dart wraps a long declaration
    // over two lines and a naive `contains` misses it, which is why the scanner
    // collapses whitespace before matching — and why the line map exists, so the
    // failure message still names the line the declaration starts on.
    final List<Hit> hits = literalWithdrawalDays(
      'lib/features/treatments/entry.dart',
      'class Entry {\n'
          '  static const int kDefaultWithdrawalDaysForMeat =\n'
          '      7;\n'
          '}\n',
    );

    expect(hits, hasLength(1));
    expect(hits.single.line, 2);
  });
}
