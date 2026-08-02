// test/policy/no_snackbar_test.dart
//
// P2, as a test in the tier a developer runs before CI.
//
// "There is no SnackBar" is the ruling; this file is what makes it true of the
// tree rather than of the prose. It duplicates the `gesture.raw_snackbar` gate
// row deliberately — a rule that only exists in the gate is a rule a developer
// meets after a red build rather than before one.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

void main() {
  test('showSnackBar( appears nowhere in lib/, including feedback.dart', () {
    // THE ANCHOR, AND IT SURVIVES A RENAME because it scans the whole family
    // rather than one spelling. The framework's obvious answer to "confirm a
    // save" is a SnackBar, and the whole point of P2 is that the obvious answer
    // is wrong here: undo-until-the-snackbar-is-dismissed is unimplementable
    // when Indelible §9 bans toasts outright, so the confirmation IS the
    // committed row, in ink, one line above the one being written.
    //
    // The needles are split across adjacent literals: this file lives under a
    // scanned root and a whole one would match itself. The twenty-ninth
    // prohibition-versus-claim self-match in this project.
    const List<String> banned = <String>[
      'showSnack'
          'Bar(',
      'Snack'
          'Bar(',
      'Snack'
          'BarAction(',
      'ScaffoldMessenger'
          '.of(',
      'showMaterial'
          'Banner(',
    ];

    for (final String path in _authoredDart('lib')) {
      final String source = File(path).readAsStringSync();
      for (final String needle in banned) {
        expect(source, isNot(contains(needle)), reason: '$path contains $needle');
      }
    }
  });

  test('gesture.raw_snackbar has no exempt line, and never may', () {
    // A RULE WITH AN ESCAPE HATCH IS A RULE THAT WILL BE ESCAPED at 23:00 on a
    // Tuesday. R56 fixes the [exempt] section at four lines; none of them is
    // this, and adding a fifth to keep this rule quiet is the named
    // anti-pattern.
    final List<String> lines = File('tool/policy_allowlist.txt').readAsLinesSync();
    final int start = lines.indexWhere((String l) => l.trim() == '[exempt]');
    final List<String> keys = lines
        .skip(start + 1)
        .map((String l) => l.split('#').first.trim())
        .where((String l) => l.contains('::'))
        .toList();

    expect(keys, hasLength(4));
    for (final String key in keys) {
      expect(key, isNot(contains('raw_snackbar')));
    }
  });

  test('there is no floating overlay either — P2 forbids the fallback', () {
    // 06 §10.3 offers "replace SnackBar with a house ShedReceiptBar in an
    // OverlayEntry", and P2 says "no floating overlay". BOTH ARE OUT. If you
    // find yourself reaching for the overlay lookup, you have re-invented the
    // toast with a different class name.
    const String needle =
        'Overlay'
        '.of(';
    const String entry =
        'Overlay'
        'Entry(';

    for (final String path in _authoredDart('lib')) {
      final String source = File(path).readAsStringSync();
      expect(source, isNot(contains(needle)), reason: path);
      expect(source, isNot(contains(entry)), reason: path);
    }
  });
}
