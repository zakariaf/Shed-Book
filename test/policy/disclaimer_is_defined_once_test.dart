// test/policy/disclaimer_is_defined_once_test.dart — safety rule §12.3 at the
// unconstructible level, cross-checked from the test side.
//
// tool/check_policy.dart's copy.disclaimer_retyped row is the gate half and is
// what fails a build. This file holds the two properties the gate's tuple cannot
// express: that the OTHER two disclaimer strings are also single-site, and that
// a phrase wrapped across adjacent literals is still found — which is exactly
// how a re-typed disclaimer gets formatted.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';

const String _home = 'lib/domain/policy/disclaimers.dart';

List<String> _dartFilesUnderLib() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart'))
        .where((String p) => !p.contains('/app_localizations'))
        .toList()
      ..sort();

/// Every Dart string literal in [source], adjacent literals joined, comment
/// lines dropped first.
///
/// The joining is the point. Dart wraps long text across adjacent literals, so
/// the export footer contains *"statutory medicine"* nowhere contiguously in the
/// source — a scan that matched literals one at a time would miss every re-typed
/// copy in the codebase.
String joinedStringLiterals(String source) {
  final String code = source
      .split('\n')
      .where((String l) => !l.trimLeft().startsWith('//'))
      .join('\n');
  final StringBuffer out = StringBuffer();
  int i = 0;
  bool previousWasLiteral = false;
  while (i < code.length) {
    final String c = code[i];
    if (c != "'" && c != '"') {
      if (previousWasLiteral && c.trim().isNotEmpty) {
        out.write('\n');
        previousWasLiteral = false;
      }
      i++;
      continue;
    }
    final String quote = c;
    i++;
    while (i < code.length && code[i] != quote) {
      if (code[i] == r'\' && i + 1 < code.length) {
        i += 2;
        continue;
      }
      if (code[i] == '\n') {
        break;
      }
      out.write(code[i]);
      i++;
    }
    i++;
    previousWasLiteral = true;
  }
  return out.toString();
}

List<String> _filesContaining(Pattern needle) => _dartFilesUnderLib()
    .where((String p) => joinedStringLiterals(File(p).readAsStringSync()).contains(needle))
    .toList();

void main() {
  test('Disclaimers.exportFooter appears as a literal in exactly one file', () {
    expect(_filesContaining(RegExp(r'statutory\s+medicine|holding\s+register')), <String>[_home]);
  });

  test('a phrase split across adjacent string literals is still found', () {
    // The regression for the gotcha itself, against a fixture rather than the
    // tree — a test that wrote a scratch file under lib/ would leave the tree
    // dirty when it failed, and make check's formatter would then fail for a
    // reason unrelated to the assertion.
    const String wrapped =
        "const String f = 'It is not a statutory '\n"
        "    'medicine record, holding '\n"
        "    'register, or movement record.';";

    expect(joinedStringLiterals(wrapped), contains('statutory medicine record'));
    expect(joinedStringLiterals(wrapped), contains('holding register'));
    // …and the naive form misses both, which is why the joiner exists.
    expect(wrapped.contains('statutory medicine'), isFalse);
  });

  test('withdrawalCaveat and withdrawalProvenance are also single-site', () {
    expect(_filesContaining('Shed Book does not know any product'), <String>[_home]);
    // withdrawalProvenance is a short phrase and is deliberately checked by a
    // longer distinctive neighbour: 'as entered by you' legitimately appears in
    // the ARB's withdrawalSource message, which is 10 §8.4's provenance string
    // and the one place it is allowed to.
    expect(Disclaimers.withdrawalProvenance, 'as entered by you');
    expect(_filesContaining('as entered by you'), <String>[_home]);
  });

  test('the three constants are the ones the file declares', () {
    // Read by reference, never re-typed here: this file would otherwise become
    // the second site it exists to forbid.
    expect(Disclaimers.exportFooter, contains('statutory medicine'));
    expect(Disclaimers.exportFooter, contains('holding register'));
    expect(Disclaimers.withdrawalCaveat, contains('Check the label.'));
  });
}
