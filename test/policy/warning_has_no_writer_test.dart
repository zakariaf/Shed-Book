// test/policy/warning_has_no_writer_test.dart — safety rule §12.4 at the
// UNREPRESENTABLE level, which is the highest level this rule reaches anywhere
// in the product.
//
// The mechanism is an ABSENCE, so this file exists to hold absences down. A
// helpful future contributor adding `Reviewed.cleaned` is a two-line diff that
// deletes safety rule §12.4, and nothing else in the build would notice.
//
// Every scan below reads DECLARATIONS — comment lines dropped — and that is not
// a convenience. warning.dart's own doc comment says "No fix(), no `corrected`
// field, no apply()", because naming the absence is how the next reader learns
// it is deliberate. A scan over raw file text would fire on that sentence, and
// the fix would be to delete the sentence, which is the wrong direction. The
// same distinction is why one_clock_test.dart's "no second clock abstraction"
// case reads declarations too.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _warningFile = 'lib/domain/validation/warning.dart';

/// Every file under [root], as repository-relative paths.
List<String> _filesUnder(String root, {String suffix = '.dart'}) {
  final Directory dir = Directory(root);
  if (!dir.existsSync()) {
    return const <String>[];
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((File f) => f.path.replaceAll(r'\', '/'))
      .where((String p) => p.endsWith(suffix))
      .toList()
    ..sort();
}

/// [path]'s source with comment lines removed. `///` and `//` both start with
/// `//` once the indent is trimmed, so one test catches both.
String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('Warning has no fix(), no writer and no persistence path', () {
    final String declarations = _declarations(_warningFile);

    // Clause 1: no member that repairs.
    expect(
      declarations,
      isNot(matches(RegExp(r'\b(fix|repair|correct|apply)\s*\('))),
      reason: 'a Warning that can fix something is not a warning',
    );

    // Clause 2: nothing that hands back a changed value. A test that stops at
    // clause 1 passes for a type that is mutable everywhere else.
    expect(declarations, isNot(contains('corrected')));

    // Clause 3: R53 — the code that WRITES cannot reach the code that JUDGES.
    // This is the half that makes the absence structural rather than polite: a
    // repository is incapable of producing or applying a warning, so
    // WriteCommitted.warnings is always empty from the data layer and the
    // controller is the only thing that can run a validator.
    final List<String> dataImportingValidation = _filesUnder(
      'lib/data',
    ).where((String p) => File(p).readAsStringSync().contains('domain/validation/')).toList();

    expect(
      dataImportingValidation,
      isEmpty,
      reason: 'R53: the code that writes cannot reach the code that judges',
    );
  });

  test('Reviewed<T> exposes no cleaned or corrected accessor', () {
    final String declarations = _declarations(_warningFile);

    for (final String forbidden in <String>['cleaned', 'sanitised', 'sanitized', 'normalised']) {
      expect(declarations, isNot(contains(forbidden)), reason: forbidden);
    }

    // And it is not Either/Result/Validated: there is no error arm, because a
    // warning is never a failure. The write is never blocked, so there is
    // nothing to branch on. 05 §9 row 16 bans
    // Either<Corrected, List<Warning>> by name.
    expect(declarations, isNot(contains('Either')));
    expect(declarations, isNot(matches(RegExp(r'\bValidated\b'))));
  });

  test('no file under lib/ declares a warnings column', () {
    // Guarantee 2 of 05 §7.5: warnings are recomputed on read and there is no
    // column to store them in. This is the half N07 must not break — it runs now
    // so that the freeze cannot quietly add one.
    //
    // It looks for a COLUMN, not for the word. `final List<Warning> warnings` on
    // Reviewed and on WriteCommitted are the correct spellings of the field and
    // must not fire.
    final RegExp driftColumn = RegExp(r'\w*Column(<[^>]*>)?\s+get\s+warnings\b');
    for (final String path in _filesUnder('lib')) {
      expect(_declarations(path), isNot(matches(driftColumn)), reason: path);
    }

    // The raw-SQL spelling, for .drift files and for CREATE TABLE strings.
    final RegExp sqlColumn = RegExp(
      r'\bwarnings\s+(TEXT|INTEGER|REAL|BLOB|ANY)\b',
      caseSensitive: false,
    );
    for (final String path in <String>[
      ..._filesUnder('lib'),
      ..._filesUnder('lib', suffix: '.drift'),
    ]) {
      expect(File(path).readAsStringSync(), isNot(matches(sqlColumn)), reason: path);
    }
  });

  // R71 — the word is `warnings`, never the other one — is NOT held here, and
  // the omission is deliberate rather than forgotten.
  //
  // tool/check_policy.dart's copy.banned_word row already owns it, at exactly
  // the right scope: word-anchored, the plural only, lib/ only, declarations
  // only. A cross-check was written here first and immediately fired on
  // test_config_test.dart's "`flutter test` has no -P / --preset flag" and on
  // withdrawal_period.dart's "do not gate it behind a flag" — a command-line
  // flag and an English idiom, neither of which is the concept R71 renames. The
  // gate's narrower row is the correct one, and defining the same rule twice at
  // two widths is how the wider copy gets weakened and then deleted.
}
