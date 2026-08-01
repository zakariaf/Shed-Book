// test/design/tokens_test.dart — tier 2.
//
// Two kinds of case in one file, deliberately. The behavioural ones pump a
// widget and read through `context.tokens`; the structural ones read
// tokens.dart as TEXT. The second kind exists because the design of this file is
// mostly ABSENCE — no TextStyle, no third value out of lerp, exactly two named
// parameters on copyWith — and an absence has no runtime behaviour to assert.
//
// Nothing here is time-shaped. `motion` is a Duration but no wall clock is read,
// so there is no uk-zone case; T06's formatters.dart is the first in this epic
// with one.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/tokens.dart';

const String _tokensFile = 'lib/core/ui/tokens.dart';
const String _frozenSchema = 'drift_schemas/drift_schema_v1.json';

/// Every field of [ShedTokens], by name. Kept beside [_valuesOf] and asserted
/// against the source below, so a field added to the class and forgotten here
/// fails rather than silently escaping the lerp sweep.
const List<String> _fieldNames = <String>[
  'id', 'highContrast', //
  'surfaceBase', 'surfaceRaised', 'surfacePressed', 'surfaceFill',
  'outline',
  'textNumeric', 'textPrimary', 'textSecondary', 'textChrome',
  'statusReady', 'statusAttention', 'statusLoss', 'onStatus',
  'tapMin', 'tapPrimary', 'tapHero', 'gapMin', 'gapDestructive',
  'outlineWidth', 'radiusControl', 'bodySize', 'numeralSize',
  'motion', 'photoTint',
];

/// The same fields, in the same order, as values.
List<Object?> _valuesOf(ShedTokens t) => <Object?>[
  t.id, t.highContrast, //
  t.surfaceBase, t.surfaceRaised, t.surfacePressed, t.surfaceFill,
  t.outline,
  t.textNumeric, t.textPrimary, t.textSecondary, t.textChrome,
  t.statusReady, t.statusAttention, t.statusLoss, t.onStatus,
  t.tapMin, t.tapPrimary, t.tapHero, t.gapMin, t.gapDestructive,
  t.outlineWidth, t.radiusControl, t.bodySize, t.numeralSize,
  t.motion, t.photoTint,
];

/// A token set whose every field differs from every other set's, so a lerp that
/// returns the wrong operand for one field cannot hide behind a shared value.
/// The colours are arbitrary — this file tests the STRUCTURE. The authored
/// values and their measured ratios are T03's, and contrast_test.dart's.
ShedTokens _tokensAt(int seed, {ShedPaletteId id = ShedPaletteId.night, bool hc = false}) {
  Color c(int n) => Color(0xFF000000 | (seed * 0x010101 + n * 0x000133));
  double d(int n) => seed * 100.0 + n;
  return ShedTokens(
    id: id,
    highContrast: hc,
    surfaceBase: c(1),
    surfaceRaised: c(2),
    surfacePressed: c(3),
    surfaceFill: c(4),
    outline: c(6),
    textNumeric: c(7),
    textPrimary: c(8),
    textSecondary: c(9),
    textChrome: c(10),
    statusReady: c(11),
    statusAttention: c(12),
    statusLoss: c(13),
    onStatus: c(14),
    tapMin: d(1),
    tapPrimary: d(2),
    tapHero: d(3),
    gapMin: d(4),
    gapDestructive: d(5),
    outlineWidth: d(6),
    radiusControl: d(7),
    bodySize: d(8),
    numeralSize: d(9),
    motion: Duration(milliseconds: seed * 10),
    photoTint: seed.isEven ? null : const ColorFilter.mode(Color(0x11223344), BlendMode.multiply),
  );
}

/// tokens.dart with whole-line comments removed.
String _declarations() => File(
  _tokensFile,
).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  testWidgets('context.tokens resolves every token and lerp snaps rather than '
      'interpolating a colour', (WidgetTester tester) async {
    final ShedTokens a = _tokensAt(1);
    final ShedTokens b = _tokensAt(7, id: ShedPaletteId.deepRed, hc: true);

    // Half one: the accessor reaches every field through a real Theme.
    List<Object?>? seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[a]),
        home: Builder(
          builder: (BuildContext context) {
            seen = _valuesOf(context.tokens);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, isNotNull, reason: 'the builder never ran');
    expect(seen, _valuesOf(a));

    // Half two: no third value, at any t. This is Indelible rule 4 applied one
    // level harder than 06 §3.3 printed it — a colour produced by interpolation
    // is a colour nobody measured for contrast, and the two-tier structure
    // exists so that every colour on screen is one somebody did.
    for (final double t in <double>[0.0, 0.25, 0.49, 0.50, 0.75, 1.0]) {
      final List<Object?> got = _valuesOf(a.lerp(b, t));
      final List<Object?> fromA = _valuesOf(a);
      final List<Object?> fromB = _valuesOf(b);

      for (int i = 0; i < got.length; i++) {
        expect(
          got[i] == fromA[i] || got[i] == fromB[i],
          isTrue,
          reason:
              '${_fieldNames[i]} at t=$t is ${got[i]}, which is neither '
              'operand. An intermediate colour is one nobody measured',
        );
      }
    }
  });

  test('lerp returns this when other is null', () {
    // The framework calls it that way during theme teardown.
    final ShedTokens a = _tokensAt(3);
    expect(identical(a.lerp(null, 0.5), a), isTrue);
  });

  test('lerp switches at exactly t = 0.5', () {
    // The boundary, named, so nobody "fixes" it to > later. 0.49 is a
    // field-for-field, 0.50 is b field-for-field.
    final ShedTokens a = _tokensAt(2);
    final ShedTokens b = _tokensAt(9, id: ShedPaletteId.amber);

    expect(_valuesOf(a.lerp(b, 0.49)), _valuesOf(a));
    expect(_valuesOf(a.lerp(b, 0.50)), _valuesOf(b));
  });

  test('no lerp result contains a value present in neither operand', () {
    // Pairwise over synthetic sets. The six-palette sweep this case eventually
    // wants cannot run here: palettes.dart is T03 and shedPalettes does not
    // exist yet. Writing it now against an empty list is exactly the S7 defect
    // the epic closes — a gate that iterates nothing and passes forever. T03
    // extends this over the real six.
    final List<ShedTokens> sets = <ShedTokens>[
      _tokensAt(1),
      _tokensAt(4, id: ShedPaletteId.amber),
      _tokensAt(8, id: ShedPaletteId.deepRed, hc: true),
    ];

    for (final ShedTokens a in sets) {
      for (final ShedTokens b in sets) {
        for (final double t in <double>[0.0, 0.1, 0.49, 0.5, 0.9, 1.0]) {
          final List<Object?> got = _valuesOf(a.lerp(b, t));
          final List<Object?> fromA = _valuesOf(a);
          final List<Object?> fromB = _valuesOf(b);
          for (int i = 0; i < got.length; i++) {
            expect(
              got[i] == fromA[i] || got[i] == fromB[i],
              isTrue,
              reason: '${_fieldNames[i]} at t=$t',
            );
          }
        }
      }
    }
  });

  test('the metric fields never take an intermediate value', () {
    // 06 §3.3's own sentence: a tap target that is 63.4 pt for 150 ms breaks the
    // 60 pt contract for 150 ms. Asserted separately from the colour sweep
    // because this is the half 06 already agreed with, and it must not be lost
    // if the colour narrowing is ever revisited.
    final ShedTokens a = _tokensAt(1);
    final ShedTokens b = _tokensAt(6);

    for (final double t in <double>[0.1, 0.3, 0.49, 0.5, 0.7, 0.99]) {
      final ShedTokens got = a.lerp(b, t);
      for (final double Function(ShedTokens) metric in <double Function(ShedTokens)>[
        (ShedTokens x) => x.tapMin,
        (ShedTokens x) => x.tapPrimary,
        (ShedTokens x) => x.tapHero,
        (ShedTokens x) => x.gapMin,
        (ShedTokens x) => x.gapDestructive,
        (ShedTokens x) => x.outlineWidth,
        (ShedTokens x) => x.radiusControl,
        (ShedTokens x) => x.bodySize,
        (ShedTokens x) => x.numeralSize,
      ]) {
        expect(<double>[metric(a), metric(b)], contains(metric(got)), reason: 't=$t');
      }
    }
  });

  test('copyWith declares exactly two named parameters', () {
    // A source-text assertion, because the narrowness IS the design and a
    // widened copyWith has no failing behaviour — it just quietly lets a widget
    // build a one-off token set that no contrast test ever sees.
    final RegExp signature = RegExp(r'ShedTokens copyWith\(\{([^}]*)\}\)');
    final RegExpMatch? m = signature.firstMatch(_declarations());
    expect(m, isNotNull, reason: 'no copyWith found in $_tokensFile');

    final List<String> params = m!
        .group(1)!
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    expect(params, <String>['Duration? motion', 'bool? highContrast']);
  });

  test('copyWith(motion:) leaves every other field identical', () {
    final ShedTokens a = _tokensAt(5);
    final ShedTokens got = a.copyWith(motion: const Duration(milliseconds: 999));

    expect(got.motion, const Duration(milliseconds: 999));

    final List<Object?> before = _valuesOf(a);
    final List<Object?> after = _valuesOf(got);
    for (int i = 0; i < before.length; i++) {
      if (_fieldNames[i] == 'motion') {
        continue;
      }
      expect(after[i], before[i], reason: '${_fieldNames[i]} was dropped in copyWith');
    }
  });

  test('ShedPaletteId keys are night, amber and red', () {
    // Read from the FROZEN SCHEMA rather than retyped, and rather than read from
    // the schema document. drift_schemas/drift_schema_v1.json is the artefact a
    // phone actually carries; if the enum and that file disagree, writing a
    // palette fails the CHECK at runtime, which is a failure nothing in the type
    // system catches.
    final String frozen = File(_frozenSchema).readAsStringSync();
    final RegExpMatch? check = RegExp(r"palette IN \(([^)]*)\)").firstMatch(frozen);
    expect(check, isNotNull, reason: 'no palette CHECK in the frozen schema');

    final List<String> allowed = check!
        .group(1)!
        .split(',')
        .map((String s) => s.trim().replaceAll("'", ''))
        .toList();

    expect(ShedPaletteId.values.map((ShedPaletteId p) => p.key).toList(), allowed);
    expect(
      ShedPaletteId.deepRed.key,
      'red',
      reason: 'R35: the one member whose key is not its name',
    );
  });

  test('no ShedTokens field is named after a colour or a screen', () {
    // 06 §3.4's two hard rules. Both survive a palette change; a colour name
    // does not — `amberWarning` is wrong in the night palette the moment it is
    // written.
    for (final String field in _fieldNames) {
      final String lower = field.toLowerCase();
      for (final String banned in <String>[
        'amber',
        'green',
        'salmon',
        'madder',
        'keypad',
        'ewe',
        'lamb',
        'tile',
      ]) {
        expect(
          lower.contains(banned),
          isFalse,
          reason: '$field is named after a colour or a screen',
        );
      }
    }
  });

  test('ShedTokens holds no TextStyle and no TextTheme', () {
    // The one place a font size comes from is buildShedTextTheme. A TextStyle on
    // the extension would be a second, and token.literal_font_size exists
    // precisely because there must be one.
    final String source = _declarations();
    expect(source, isNot(contains('TextStyle')));
    expect(source, isNot(contains('TextTheme')));
  });

  test('tokens.dart imports neither primitives.dart nor lib/data/', () {
    // Layer rule 7, and the tier boundary. This file declares FIELDS; if a hex
    // is wanted here, the field being added belongs in T03's palette literals.
    final String source = _declarations();
    expect(source, isNot(contains('primitives.dart')));
    expect(source, isNot(contains('data/')));
  });

  test('every field declared in tokens.dart is covered by this file', () {
    // The maintenance guard for _fieldNames. Without it, a field added to
    // ShedTokens and forgotten above escapes the lerp sweep entirely — and the
    // sweep is the only thing standing between a palette change and a colour
    // nobody measured.
    final RegExp declared = RegExp(
      r'^\s*final\s+[\w<>?]+\s+(\w+(?:\s*,\s*\w+)*)\s*;',
      multiLine: true,
    );
    final Set<String> fromSource = <String>{};
    for (final RegExpMatch m in declared.allMatches(_declarations())) {
      for (final String name in m.group(1)!.split(',')) {
        fromSource.add(name.trim());
      }
    }
    // ShedPalette's own fields live in the same file and are not ShedTokens'.
    fromSource.removeAll(<String>['name', 'colorScheme', 'tokens', 'key']);

    expect(fromSource, _fieldNames.toSet());
    expect(_valuesOf(_tokensAt(1)), hasLength(_fieldNames.length));
  });

  test('every Indelible token in §2.2 and §2.3 maps to exactly one ShedTokens field', () {
    // The mapping table lives in tokens.dart's doc comment because every
    // reviewer from N10 onward wants it, and a table nobody can check is a table
    // that rots. Parsed here so it cannot.
    final String source = File(_tokensFile).readAsStringSync();
    final RegExp row = RegExp(r'///\s*\|\s*`(--[a-z-]+)`\s*\|\s*`(\w+)`');

    final Map<String, String> mapping = <String, String>{};
    for (final RegExpMatch m in row.allMatches(source)) {
      mapping[m.group(1)!] = m.group(2)!;
    }

    const List<String> indelibleTokens = <String>[
      '--page', '--row-pressed', '--sheet', '--slab', '--slab-pressed', //
      '--ink-full', '--ink-mid', '--ink-low', '--rule', '--madder-rule', '--madder-ink',
    ];

    // Every one of the eleven is ACCOUNTED FOR — which is not the same as
    // mapped. `--slab-pressed` deliberately maps to *(none)*: 06 §4's ramp has
    // four surface steps and publishes no fifth hex, and decision #95 makes 06's
    // ramp the one that ships (P6). A token with no home has to be VISIBLE in
    // this table rather than absent from it, because absent reads as forgotten.
    for (final String token in indelibleTokens) {
      expect(mapping.keys, contains(token), reason: '$token is not accounted for in the table');
    }

    for (final MapEntry<String, String> e in mapping.entries) {
      if (e.value == 'none') {
        continue;
      }
      expect(_fieldNames, contains(e.value), reason: '${e.value} is not a ShedTokens field');
    }

    expect(
      mapping['--slab-pressed'],
      'none',
      reason:
          'if a fifth surface is ever authored, 06 §4 supplies the hex — a field '
          'with nothing behind it is what two tiers exist to prevent',
    );
  });
}
