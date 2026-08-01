// The toolchain pin, asserted against the file CI reads rather than against the
// SDK that happens to be installed. `13 §1.1`'s three-line workflow assert greps
// `.fvmrc` for one exact key; a file that pin does not match is a green pipeline
// that has proved nothing.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Decision-record §2 A #1. This is the only place a version string is written
/// in this file, so a bump is one edit and not four.
const String pinnedFlutterVersion = '3.44.8';

/// Every spelling that would let the pin float. `13 §1.1`: never `channel:
/// stable` unpinned, never a caret, never a range.
const List<String> floatingSpellings = <String>[
  'stable',
  'beta',
  'dev',
  'master',
  'any',
  '^',
  '>=',
];

void main() {
  final File fvmrc = File('.fvmrc');
  final File pubspec = File('pubspec.yaml');

  test('.fvmrc pins $pinnedFlutterVersion and never the string stable', () {
    expect(fvmrc.existsSync(), isTrue, reason: 'Cannot open file .fvmrc');

    final Object? parsed = jsonDecode(fvmrc.readAsStringSync());
    expect(parsed, isA<Map<String, dynamic>>(), reason: '.fvmrc must be a JSON object');

    final Map<String, dynamic> json = parsed! as Map<String, dynamic>;
    expect(json['flutter'], pinnedFlutterVersion);
  });

  test('.fvmrc names no channel and no range', () {
    final String raw = fvmrc.readAsStringSync();
    for (final String spelling in floatingSpellings) {
      expect(
        raw.contains(spelling),
        isFalse,
        reason: '.fvmrc carries "$spelling", which lets the toolchain float',
      );
    }
  });

  test("the .fvmrc key is the one 13 §1.1's CI assert greps for", () {
    // The workflow runs `grep -o '"flutter": *"[^"]*"' .fvmrc`. Recent FVM
    // releases write `flutterSdkVersion` instead, which that grep cannot read.
    final String raw = fvmrc.readAsStringSync();
    expect(
      RegExp('"flutter": *"$pinnedFlutterVersion"').hasMatch(raw),
      isTrue,
      reason: 'the CI assert in 13 §1.1 cannot read this .fvmrc',
    );
  });

  test('pubspec.yaml declares the package name CONVENTIONS §1 fixes', () {
    // Every `package:shed_book/…` import, `build.yaml`'s `databases:` key and
    // the database file name all key on this string.
    final List<String> lines = pubspec.readAsLinesSync();
    expect(lines, contains('name: shed_book'));
  });
}
