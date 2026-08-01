// test/domain/validation/warning_test.dart — mirrors
// lib/domain/validation/warning.dart.
//
// The value-type behaviour. The absences — no fix(), no corrected, no warnings
// column, no lib/data/ import — are claims about the artefact and live in
// test/policy/warning_has_no_writer_test.dart.
//
// No uk-zone case. Nothing here carries a time. `timeDoesNotExistLocally` is
// named in the enum but is raised by N04-T08's checkLocalWallTimeExists, whose
// DST-3 case already runs in the 01:00–01:59 hour under TZ=Europe/London.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/validation/warning.dart';

void main() {
  test("WarningCode has exactly eleven members, in CONVENTIONS §2.6's order", () {
    // Frozen literally rather than counted. The CSV's `warnings` column joins
    // these NAMES — 05 §7.5's "codes, not localised messages" — so renaming one
    // after N21 breaks every export ever written, and a twelfth is a
    // CONVENTIONS §2.6 edit rather than a local decision.
    expect(WarningCode.values.map((WarningCode c) => c.name).toList(), <String>[
      'birthTypeLambCountMismatch',
      'lambingBeforeSeasonStart',
      'lambingInFuture',
      'lambingLongBeforeCapture',
      'implausibleBirthWeight',
      'timeDoesNotExistLocally',
      'fosterToSelf',
      'deathBeforeBirth',
      'duplicateActiveTag',
      'clearDateDisagrees',
      'localDateDisagrees',
    ]);
  });

  test('WarningCode has no stored key and no fromKey, unlike every other enum here', () {
    // On purpose. A stored key exists so a value can be written to SQLite, and a
    // warning is never written anywhere. The one place a code becomes a string
    // is the CSV column, which joins the enum names, and that is
    // 09-export-formats.md's call site rather than this file's.
    expect(WarningCode.clearDateDisagrees.name, 'clearDateDisagrees');
  });

  test('Reviewed.hasWarnings is false for an empty list and true otherwise', () {
    const Reviewed<int> clean = Reviewed<int>(3, <Warning>[]);
    const Reviewed<int> questionable = Reviewed<int>(3, <Warning>[
      Warning(WarningCode.implausibleBirthWeight, 'observed'),
    ]);

    expect(clean.hasWarnings, isFalse);
    expect(questionable.hasWarnings, isTrue);
    expect(questionable.value, 3, reason: 'the value is unchanged either way');
  });

  test('Reviewed holds the value byte-identically', () {
    // The whole point of the type: it carries the UNCHANGED value together with
    // what is questionable about it, so a screen cannot render the value without
    // seeing the warning. Leading and trailing whitespace and a comma are the
    // three things a "helpful" normaliser would take out.
    const String asTyped = '  412, twin  ';
    const Reviewed<String> reviewed = Reviewed<String>(asTyped, <Warning>[
      Warning(WarningCode.duplicateActiveTag, 'observed', fieldPath: 'tag'),
    ]);

    expect(reviewed.value, asTyped);
    expect(reviewed.value.length, asTyped.length);
  });

  test('a Warning constructed without fieldPath has a null fieldPath', () {
    const Warning w = Warning(WarningCode.fosterToSelf, 'observed');

    expect(w.fieldPath, isNull);
    expect(w.code, WarningCode.fosterToSelf);
    expect(w.message, 'observed');
  });
}
