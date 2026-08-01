// test/policy/withdrawal_has_no_default_test.dart — safety rule §12.1, *never
// default a medicine withdrawal period*, held as claims about the artefact
// rather than about a value.
//
// **This file is not finished, and it is not meant to look finished.** §12.1 is
// held in three halves, in three different tasks, and they accumulate here:
//
//   1. N05-T01 (this one) — the UNCONSTRUCTIBLE half. WithdrawalDays has one
//      generative constructor, it is private, and the only public entry point is
//      named for where the number came from.
//   2. N05-T04 — the TYPE-AND-SOURCE half. No expression anywhere under lib/
//      routes around the type: no `?? 0` near a period, no nullable int field
//      standing in for one, no lookup table of products.
//   3. N07-T08 — the UNPERSISTABLE half, against
//      drift_schemas/drift_schema_v1.json: `days` carries no DEFAULT and no
//      clientDefault, and NO ROW means not recorded.
//
// If you are here because you added a half, add it to the list. If you are here
// because two of the three are missing, they have not been written yet.
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
}
