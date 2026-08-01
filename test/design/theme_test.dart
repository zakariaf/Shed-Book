// test/design/theme_test.dart — dark-only, as an absence rather than a default.
//
// Theme construction is pure, so most cases need no pump.
//
// Nothing here is time-shaped. T06's formatters.dart is the first in this epic
// with a uk-zone case.
library;

import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// Every authored file under [root], generated output skipped.
List<String> _dartFilesUnder(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where(
          (String p) => p.endsWith('.dart') && !p.endsWith('.g.dart') && !p.endsWith('.drift.dart'),
        )
        .toList()
      ..sort();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('no code path in buildShedTheme can produce Brightness.light', () {
    // THE ANCHOR, and it is two claims rather than one.
    //
    // Half one: every theme this app can build is dark. Half two: there is no
    // spelling anywhere under lib/ that could select a light one. A theme object
    // that is dark while a themeMode can still follow the system is not
    // dark-only — it is one framework upgrade, one system setting or one
    // helpful contributor away from a white screen at 03:20, which costs a
    // shepherd ten minutes of night vision.
    for (final ShedPalette p in shedPalettes) {
      final ThemeData theme = buildShedTheme(p);
      expect(theme.brightness, Brightness.dark, reason: '${p.name}: ThemeData.brightness');
      expect(
        theme.colorScheme.brightness,
        Brightness.dark,
        reason: '${p.name}: ColorScheme.brightness',
      );
    }

    // The six banned spellings. Scoped to DECLARATIONS so that a comment
    // explaining the ban does not read as the ban being broken — the same
    // prohibition-versus-claim problem this project has hit eight times.
    const List<String> banned = <String>[
      'Brightness.light',
      'ThemeMode.system',
      'ThemeMode.light',
      'ColorScheme.light',
      'ThemeData.light',
      'platformBrightnessOf',
    ];

    for (final String path in _dartFilesUnder('lib')) {
      final String source = _declarations(path);
      for (final String spelling in banned) {
        expect(source, isNot(contains(spelling)), reason: '$path contains $spelling');
      }
    }
  });

  test('every palette installs exactly one ThemeExtension and it is ShedTokens', () {
    // Two entries — or a second extension added later "just for typography" —
    // reintroduces the five-object shape 06 §3.3 rejected, and
    // Theme.of(context).extension<T>() becomes a lookup that can miss.
    for (final ShedPalette p in shedPalettes) {
      final ThemeData theme = buildShedTheme(p);
      expect(theme.extensions, hasLength(1), reason: p.name);
      expect(theme.extension<ShedTokens>(), isNotNull, reason: p.name);
      expect(theme.extension<ShedTokens>(), same(p.tokens), reason: p.name);
    }
  });

  test('theme and highContrast are never the same object', () {
    // Decision #95. 06 §4.5 calls the alternative "dead plumbing while claiming
    // to honour the flag" — and because highContrast only ever fires on iOS, a
    // set that returned one object would be undetectable on Android forever.
    for (final ShedPaletteId id in ShedPaletteId.values) {
      final ShedThemeSet set = buildShedThemeSet(id);
      expect(identical(set.theme, set.highContrast), isFalse, reason: '$id');
      expect(
        set.theme.extension<ShedTokens>()!.highContrast,
        isFalse,
        reason: '$id: the standard slot holds the standard palette',
      );
      expect(
        set.highContrast.extension<ShedTokens>()!.highContrast,
        isTrue,
        reason: '$id: the high-contrast slot holds the high-contrast palette',
      );
    }
  });

  test('scaffoldBackgroundColor, canvasColor and colorScheme.surface are the same token', () {
    // Three routes to the first painted frame, one value. A mismatch is a
    // one-frame flash of the wrong surface — invisible in a screenshot, obvious
    // in a dark shed.
    for (final ShedPalette p in shedPalettes) {
      final ThemeData theme = buildShedTheme(p);
      expect(theme.scaffoldBackgroundColor, p.tokens.surfaceBase, reason: p.name);
      expect(theme.canvasColor, p.tokens.surfaceBase, reason: p.name);
      expect(theme.colorScheme.surface, p.tokens.surfaceBase, reason: p.name);
    }
  });

  test('materialTapTargetSize is padded and visualDensity is standard', () {
    // The two silent shrink vectors.
    //
    // padded is 48, which is NOT our floor — the 60 pt contract comes from
    // ShedTapTarget (T07) and the 64 x 64 build box from indelible.md §4.5. It
    // is pinned as a floor under our floor, and must not be read as "handled".
    //
    // adaptivePlatformDensity is NEGATIVE on some platforms and silently
    // subtracts up to 4 px per axis from every Material control. On a 60 pt
    // floor with 4 pt of headroom that is the entire margin.
    for (final ShedPalette p in shedPalettes) {
      final ThemeData theme = buildShedTheme(p);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded, reason: p.name);
      expect(theme.visualDensity, VisualDensity.standard, reason: p.name);
    }
  });

  test('the Android page transition carries a fallbackColor equal to surfaceBase', () {
    // Predictive back is the DEFAULT Android page transition on this SDK and
    // paints a gutter behind the outgoing page. Without fallbackColor that
    // gutter is the platform default — light. It is a white flash that appears
    // only on a real Android device, mid-navigation, and no other test in this
    // project catches it.
    for (final ShedPalette p in shedPalettes) {
      final ThemeData theme = buildShedTheme(p);
      final PageTransitionsBuilder? android =
          theme.pageTransitionsTheme.builders[TargetPlatform.android];

      expect(android, isA<PredictiveBackPageTransitionsBuilder>(), reason: p.name);
      expect(
        (android! as PredictiveBackPageTransitionsBuilder).fallbackColor,
        p.tokens.surfaceBase,
        reason: '${p.name}: the predictive-back gutter',
      );
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
        reason: p.name,
      );
    }
  });

  test('buildShedTextTheme returns all fifteen roles and none is below 18', () {
    // Structure only — T05 asserts the face and the weight axis.
    //
    // This case exists because a stub passes everything else. A `TextTheme()`
    // that compiles returns the M3 defaults, and M3's bodyLarge is 16.0 —
    // below the 18 pt floor — while nothing else in this epic would notice: the
    // overflow matrix and the pixel-sampling contrast run are both N33.
    for (final ShedPalette p in shedPalettes) {
      final TextTheme tt = buildShedTextTheme(p.tokens);
      final Map<String, TextStyle?> roles = <String, TextStyle?>{
        'displayLarge': tt.displayLarge,
        'displayMedium': tt.displayMedium,
        'displaySmall': tt.displaySmall,
        'headlineLarge': tt.headlineLarge,
        'headlineMedium': tt.headlineMedium,
        'headlineSmall': tt.headlineSmall,
        'titleLarge': tt.titleLarge,
        'titleMedium': tt.titleMedium,
        'titleSmall': tt.titleSmall,
        'bodyLarge': tt.bodyLarge,
        'bodyMedium': tt.bodyMedium,
        'bodySmall': tt.bodySmall,
        'labelLarge': tt.labelLarge,
        'labelMedium': tt.labelMedium,
        'labelSmall': tt.labelSmall,
      };

      expect(roles, hasLength(15));
      for (final MapEntry<String, TextStyle?> e in roles.entries) {
        expect(e.value, isNotNull, reason: '${p.name}: ${e.key} is unset');
        expect(
          e.value!.fontSize,
          greaterThanOrEqualTo(18.0),
          reason: '${p.name}: ${e.key} is below the 18 pt floor',
        );
        expect(e.value!.color, p.tokens.textPrimary, reason: '${p.name}: ${e.key} colour');
      }

      // bodySmall and labelSmall are COLLAPSED into the floor rather than kept
      // at M3's 12 and 11. If a piece of text is not worth 18 pt at 3am, it is
      // not worth showing.
      expect(tt.bodySmall!.fontSize, tt.bodyMedium!.fontSize, reason: p.name);
      expect(tt.labelSmall!.fontSize, tt.labelMedium!.fontSize, reason: p.name);
    }
  });

  test('every tabular role carries FontFeature.tabularFigures', () {
    // 06 §5.4: constructing a fresh TextStyle instead of copying one drops
    // fontFeatures, and the pen board starts jittering as 412 and 108 take
    // different widths. Silent, and only visible in motion.
    for (final ShedPalette p in shedPalettes) {
      final TextTheme tt = buildShedTextTheme(p.tokens);
      final Map<String, TextStyle?> tabular = <String, TextStyle?>{
        'displayLarge': tt.displayLarge,
        'displayMedium': tt.displayMedium,
        'displaySmall': tt.displaySmall,
        'headlineLarge': tt.headlineLarge,
      };

      for (final MapEntry<String, TextStyle?> e in tabular.entries) {
        expect(
          e.value!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: '${p.name}: ${e.key} is a numeral role and must not jitter',
        );
      }

      // And the non-tabular roles do not carry it, so the marking means
      // something rather than being applied everywhere.
      expect(tt.bodyMedium!.fontFeatures ?? const <FontFeature>[], isEmpty, reason: p.name);
    }
  });

  test('the night-shift palettes build a theme with bodySize 20 and numeralSize 44', () {
    // The size-not-weight compensation survives theme construction. Bumping
    // weight instead walks into flutter#139712.
    for (final ShedPalette p in shedPalettes.where(
      (ShedPalette p) => p.id != ShedPaletteId.night,
    )) {
      final TextTheme tt = buildShedTextTheme(p.tokens);
      expect(tt.bodyMedium!.fontSize, 20.0, reason: p.name);
      expect(tt.displaySmall!.fontSize, 44.0, reason: p.name);
    }
  });

  test('no snackBarTheme is configured', () {
    // P2, made executable. 06 §2.2 prints a snackBarTheme block that sets
    // actionOverflowThreshold so SnackBarAction clears the 60 pt floor; the
    // owner ruling supersedes it — there is no SnackBar, and showSnackBar( is
    // banned everywhere including feedback.dart.
    //
    // Theming a widget that cannot be constructed is dead configuration that
    // reads as permission.
    final String source = _declarations('lib/core/ui/theme.dart');
    expect(source, isNot(contains('snackBar')));
    expect(source, isNot(contains('SnackBar')));

    for (final ShedPalette p in shedPalettes) {
      // The framework's own default object, not one we authored.
      expect(
        buildShedTheme(p).snackBarTheme,
        const SnackBarThemeData(),
        reason: '${p.name}: something configured a widget this app does not have',
      );
    }
  });

  test('theme.dart imports no riverpod, no drift and nothing under lib/data/', () {
    // Layer rule 7. lib/core/ui/ may import lib/core/ui/, lib/domain/,
    // package:flutter/* and package:intl — and themeProvider therefore could not
    // live here even if it were wanted, which is why it is N12's.
    final String source = _declarations('lib/core/ui/theme.dart');
    for (final String forbidden in <String>['riverpod', 'drift', 'data/']) {
      expect(source, isNot(contains(forbidden)));
    }
  });

  test('press is a fill change with no ripple', () {
    // indelible.md §5.1: no scale, no lift, no ripple — "a target that shrinks
    // under a cold thumb is a target you miss". 06 §2.2 printed
    // InkSparkle.splashFactory; 06 §1 gives the direction "the visual form of a
    // target", so indelible.md has the stronger claim. See the commit message.
    for (final ShedPalette p in shedPalettes) {
      expect(buildShedTheme(p).splashFactory, NoSplash.splashFactory, reason: p.name);
    }
    expect(_declarations('lib/core/ui/theme.dart'), isNot(contains('InkSparkle')));
  });
}
