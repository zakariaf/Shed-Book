// test/design/typography_test.dart — the face, read off the committed bytes.
//
// theme_test.dart asserts the STRUCTURE of the scale. This file asserts the
// FACE: that the font this app declares is the font this app ships, that every
// weight it asks for exists on that font's axis, and that the two mechanisms
// which would silently break the Bold Text accessibility setting are absent.
//
// It parses the TTF itself rather than shelling out to fc-query or ttx, because
// neither is available on the CI runner and a test that skips when a tool is
// missing is a test that never runs.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';

const String _family = 'AtkinsonNext';
const String _fontFile = 'assets/fonts/AtkinsonHyperlegibleNext[wght].ttf';
const String _licence = 'assets/fonts/OFL.txt';
const String _measurements = 'docs/perf/measurements.md';

/// The byte count recorded in [_measurements] on 2026-08-01. Duplicated here on
/// purpose: a silent font swap changes the file and not the document, and this
/// is the constant that makes that fail.
const int _recordedBytes = 114552;

/// A minimal big-endian TTF table reader. Enough for `fvar` and `GSUB`.
class _Ttf {
  _Ttf(this.bytes) : _d = ByteData.sublistView(bytes) {
    final int numTables = _d.getUint16(4);
    for (int i = 0; i < numTables; i++) {
      final int off = 12 + 16 * i;
      final String tag = String.fromCharCodes(bytes.sublist(off, off + 4));
      tables[tag] = (_d.getUint32(off + 8), _d.getUint32(off + 12));
    }
  }

  final Uint8List bytes;
  final ByteData _d;
  final Map<String, (int, int)> tables = <String, (int, int)>{};

  /// `wght`'s (min, default, max), in design units.
  (double, double, double) wghtAxis() {
    final (int off, _) = tables['fvar']!;
    final int axesOff = _d.getUint16(off + 4);
    final int axisCount = _d.getUint16(off + 8);
    final int axisSize = _d.getUint16(off + 10);

    for (int i = 0; i < axisCount; i++) {
      final int a = off + axesOff + i * axisSize;
      final String tag = String.fromCharCodes(bytes.sublist(a, a + 4));
      if (tag == 'wght') {
        // Fixed 16.16.
        return (
          _d.getInt32(a + 4) / 65536.0,
          _d.getInt32(a + 8) / 65536.0,
          _d.getInt32(a + 12) / 65536.0,
        );
      }
    }
    fail('the committed font has no wght axis');
  }

  Set<String> featureTags(String table) {
    final (int off, _) = tables[table]!;
    final int featOff = _d.getUint16(off + 6);
    final int f = off + featOff;
    final int count = _d.getUint16(f);
    return <String>{
      for (int i = 0; i < count; i++)
        String.fromCharCodes(bytes.sublist(f + 2 + 6 * i, f + 6 + 6 * i)),
    };
  }
}

_Ttf _font() => _Ttf(File(_fontFile).readAsBytesSync());

List<String> _authoredDart(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path.replaceAll(r'\', '/'))
    .where(
      (String p) => p.endsWith('.dart') && !p.endsWith('.g.dart') && !p.endsWith('.drift.dart'),
    )
    .toList();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// Every weight `buildShedTextTheme` emits, across every palette.
Set<FontWeight> _weightsUsed() => <FontWeight>{
  for (final ShedPalette p in shedPalettes)
    ...<TextStyle?>[
      buildShedTextTheme(p.tokens).displayLarge,
      buildShedTextTheme(p.tokens).displayMedium,
      buildShedTextTheme(p.tokens).displaySmall,
      buildShedTextTheme(p.tokens).headlineLarge,
      buildShedTextTheme(p.tokens).headlineMedium,
      buildShedTextTheme(p.tokens).headlineSmall,
      buildShedTextTheme(p.tokens).titleLarge,
      buildShedTextTheme(p.tokens).titleMedium,
      buildShedTextTheme(p.tokens).titleSmall,
      buildShedTextTheme(p.tokens).bodyLarge,
      buildShedTextTheme(p.tokens).bodyMedium,
      buildShedTextTheme(p.tokens).bodySmall,
      buildShedTextTheme(p.tokens).labelLarge,
      buildShedTextTheme(p.tokens).labelMedium,
      buildShedTextTheme(p.tokens).labelSmall,
    ].map((TextStyle? s) => s!.fontWeight!),
};

void main() {
  test('every weight the app uses exists on the shipped variable font axis', () {
    // THE ANCHOR. Read off the committed bytes, not off a document — 06 §5.2
    // asked for the range and recorded 500–700 without ever having downloaded
    // the file.
    final (double min, double def, double max) = _font().wghtAxis();

    expect(min, 200.0, reason: 'the measured axis minimum');
    expect(max, 800.0, reason: 'the measured axis maximum');
    expect(def, 400.0);

    final Set<FontWeight> used = _weightsUsed();
    expect(used, isNotEmpty);

    for (final FontWeight w in used) {
      expect(
        w.value,
        inInclusiveRange(min, max),
        reason: 'w${w.value} is outside the shipped axis $min–$max',
      );
    }

    // And the range the house style actually occupies, so a widened scale is
    // visible rather than merely legal.
    expect(used, <FontWeight>{FontWeight.w500, FontWeight.w600, FontWeight.w700});
  });

  test('the committed font matches the recorded measurement', () {
    // A silent font swap changes the file and not the document. This is the
    // assertion that makes the two disagree loudly.
    expect(
      File(_fontFile).lengthSync(),
      _recordedBytes,
      reason: 'the font on disk is not the one $_measurements records',
    );
    expect(File(_measurements).readAsStringSync(), contains('114 552'));
  });

  test('the font ships tnum, which the tabular roles depend on', () {
    // Decision #98 claims it. 06 §5.4's failure mode is silent: a role that
    // asks for tabularFigures on a face without tnum simply renders
    // proportional, and the pen board jitters as 412 and 108 take different
    // widths.
    expect(_font().featureTags('GSUB'), contains('tnum'));
  });

  test('the font ships no slashed zero, and that is recorded rather than assumed', () {
    // 06 §5.2 flagged this as unverified. It is now verified NEGATIVE: there is
    // no `zero` feature and no ss01/cv variant, so 0 and O separate by counter
    // shape and width alone. The on-device check under a head torch has NOT
    // been run and measurements.md says so; the documented fallback is Inter
    // with FontFeature.slashedZero().
    //
    // Asserted so that a future font swap which DOES ship `zero` forces
    // measurements.md to be re-read rather than quietly inheriting this note.
    expect(_font().featureTags('GSUB'), isNot(contains('zero')));
    expect(File(_measurements).readAsStringSync(), contains('slashed zero'));
  });

  test('no text style exceeds w700', () {
    // Decision #98 and 06 §5.3. flutter#139712: with the Bold Text
    // accessibility setting on, w800/w900 styles render LIGHTER, at w700 — so a
    // weight bump walks straight into the bug, on button labels and pen-tile
    // numerals, in exactly the accessibility mode the bug affects.
    for (final FontWeight w in _weightsUsed()) {
      expect(w.value, lessThanOrEqualTo(700), reason: 'w${w.value} exceeds the cap');
    }
    for (final String path in _authoredDart('lib')) {
      final String source = _declarations(path);
      expect(source, isNot(contains('FontWeight.w800')), reason: path);
      expect(source, isNot(contains('FontWeight.w900')), reason: path);
      expect(source, isNot(contains('weightBump')), reason: path);
    }
  });

  test('FontVariation appears nowhere under lib/', () {
    // THE P7 RULING, made executable.
    //
    // The axis measures 200–800, so indelible.md §3.3's 390 / 420 / 520 / 600
    // are all REACHABLE — the axis was never the obstacle. What rules them out
    // is the mechanism: Text.build merges FontWeight.bold for the Bold Text
    // accessibility setting and does not touch fontVariations, so a weight set
    // through FontVariation silently ignores that setting. Invisible on a
    // developer's device, and it lands on exactly the users who turned the
    // setting on.
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains('FontVariation')), reason: path);
    }
  });

  test('google_fonts is absent from the pubspec and from lib/', () {
    // 8.2.0 depends on http and fetches at runtime by default, which is
    // categorically wrong in an app that ships with no INTERNET permission.
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('google_fonts')));
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains('google_fonts')), reason: path);
    }
  });

  test('each declared family has an OFL.txt beside it', () {
    expect(File(_licence).existsSync(), isTrue);
    expect(File(_licence).readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
  });

  test('the family the theme names is the family the pubspec declares', () {
    // A mismatch here renders every glyph in the platform fallback — which
    // looks fine on a developer's machine and loses tnum, the weight axis and
    // the whole legibility argument at once.
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: $_family'));
    expect(pubspec, contains(_fontFile));

    for (final ShedPalette p in shedPalettes) {
      final TextTheme tt = buildShedTextTheme(p.tokens);
      for (final TextStyle? style in <TextStyle?>[
        tt.displayLarge,
        tt.bodyMedium,
        tt.labelSmall,
        tt.headlineLarge,
      ]) {
        expect(style!.fontFamily, _family, reason: p.name);
      }
    }
  });

  test('exactly one family is declared, and the two voices ride the weight ladder', () {
    // P7 IS CLOSED — 2026-08-02 — AND ONE FAMILY WON.
    //
    // indelible.md §3.2 asked for two bundled faces, "two families, four
    // instances, whole payload under 700 kB", because its Rule 2 was
    // serif = record, sans = control. Decision #98 — rank 1 in the authority
    // order, and not struck — bundles Atkinson Hyperlegible Next, which is a
    // SANS. So a second face for controls would have been sans against sans:
    // the letterform-shape distinction collapses either way, and the 700 kB
    // buys nothing it was chosen for.
    //
    // The two voices survive on CASE AND WEIGHT, which indelible.md §3.1 now
    // states. This case holds the WEIGHT half mechanically; the case half is a
    // review question, because a TextTheme cannot know whether a label was
    // written in capitals.
    final int declared = 'family:'.allMatches(File('pubspec.yaml').readAsStringSync()).length;
    expect(
      declared,
      1,
      reason:
          'P7 is closed at one family. A second one re-opens it: amend the '
          'decision record, indelible.md §3.1 and 06 §5.2 in the same change, '
          'and it must beat case-and-weight on the two-voice test',
    );
  });

  test('records are lighter than controls at the same size', () {
    // THE WEIGHT LADDER IS THE TWO-VOICE MECHANISM NOW, so it is asserted rather
    // than assumed. body* is the record voice, label* is the control voice, and
    // at every shared size the control is heavier — which is what a shepherd
    // reads at a glance when the letterforms can no longer tell them apart.
    // Over EVERY palette, because the night-shift palettes buy stroke with size
    // (#98) and a future direction that bought it with weight instead would
    // flatten the ladder in exactly one palette and nowhere else.
    for (final ShedPalette p in shedPalettes) {
      final TextTheme t = buildShedTextTheme(p.tokens);

      expect(t.bodyMedium!.fontWeight, FontWeight.w500, reason: p.id.name);
      expect(t.bodyLarge!.fontWeight, FontWeight.w500, reason: p.id.name);
      expect(t.bodySmall!.fontWeight, FontWeight.w500, reason: p.id.name);

      for (final TextStyle? control in <TextStyle?>[t.labelLarge, t.labelMedium, t.labelSmall]) {
        expect(
          control!.fontWeight!.value,
          greaterThan(t.bodyMedium!.fontWeight!.value),
          reason: 'control must read heavier than record — ${p.id.name}',
        );
      }
    }
  });
}
