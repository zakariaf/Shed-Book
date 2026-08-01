// test/design/contrast_test.dart — the epic's honest demo.
//
// Every ratio is RECOMPUTED from the authored constants with
// Color.computeLuminance(), not read from a table and not taken from a design
// tool's report. Change one hex by one digit and this suite names the failing
// palette and the failing pair.
//
// Nothing here is time-shaped: no uk-zone case, no atFixed, no clock.
//
// THE PIXEL-SAMPLING GROUP BELONGS IN THIS FILE, NOT A SECOND ONE. 12 §7.6's
// `textContrastGuideline` run — 14 variants × 3 standard-contrast palettes on
// Device.small at textScaler 1.0, 42 runs, tagged `slow` — lands at N33 as a
// second group here. It cannot exist yet: it iterates kPumpableVariants, which
// is declared in test/support/harness.dart at N12-T05 and is not complete until
// N33. Writing it now against an empty list is critique defect S7 — a gate that
// iterates nothing and passes forever.
//
// What THIS file proves is arithmetic over authored constants. It does not prove
// rendering: a widget can still paint textChrome on surfaceFill and no assertion
// here would notice. That is what the pixel-sampling group is for.
library;

import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/tokens.dart';

import 'wcag.dart';

void main() {
  test('every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1', () {
    // The anchor. Deliberately a single case over everything, so that one run
    // answers the epic's headline claim — and every failure NAMES the palette
    // and the pair, because a bare "Expected: a value greater than or equal to
    // <4.5>" over six palettes and forty pairs tells you nothing at 9am.
    for (final ShedPalette p in shedPalettes) {
      final ShedTokens t = p.tokens;

      for (final (String name, Color colour) in <(String, Color)>[
        ('textNumeric', t.textNumeric),
        ('textPrimary', t.textPrimary),
        ('textSecondary', t.textSecondary),
        ('textChrome', t.textChrome),
      ]) {
        expect(
          contrastRatio(colour, t.surfaceBase),
          greaterThanOrEqualTo(4.5),
          reason: '${p.name}: $name on surfaceBase',
        );
      }

      expect(
        contrastRatio(t.outline, t.surfaceBase),
        greaterThanOrEqualTo(3.0),
        reason: '${p.name}: outline on surfaceBase',
      );

      for (final (String name, Color fill) in <(String, Color)>[
        ('statusReady', t.statusReady),
        ('statusAttention', t.statusAttention),
        ('statusLoss', t.statusLoss),
      ]) {
        expect(
          contrastRatio(t.onStatus, fill),
          greaterThanOrEqualTo(4.5),
          reason: '${p.name}: onStatus on $name',
        );
      }
    }
  });

  test('shedPalettes has six entries and every (id, highContrast) pair appears exactly once', () {
    // The one place the count is asserted. resolvePalette's switch over
    // (enum, bool) is exhaustive and a missing arm is a compile error;
    // shedPalettes is a plain list and is not — so without this, a seventh
    // palette added in season two gets its ratios published in 06 §4 and never
    // tested.
    expect(shedPalettes, hasLength(6));

    final Set<(ShedPaletteId, bool)> pairs = shedPalettes
        .map((ShedPalette p) => (p.id, p.highContrast))
        .toSet();
    expect(pairs, hasLength(6), reason: 'a duplicate (id, highContrast) pair');

    for (final ShedPaletteId id in ShedPaletteId.values) {
      for (final bool hc in <bool>[false, true]) {
        expect(pairs, contains((id, hc)), reason: '($id, hc: $hc) is missing');
        // And the registry agrees with the list.
        final ShedPalette resolved = resolvePalette(id, highContrast: hc);
        expect(resolved.id, id);
        expect(resolved.highContrast, hc);
      }
    }

    // The name is what every group below prints, so a duplicate makes two
    // different palettes indistinguishable in a failure message.
    expect(shedPalettes.map((ShedPalette p) => p.name).toSet(), hasLength(6));
  });

  for (final ShedPalette p in shedPalettes) {
    group(p.name, () {
      final ShedTokens t = p.tokens;

      // THE AA EXCEPTION, written beside the assertion and applying to exactly
      // one palette (06 §4.4). No spectrally clean long-wavelength palette
      // reaches AAA and stays spectrally clean — #FF0000 on black is 5.25:1 —
      // and pushing deep red toward orange buys contrast by adding green energy,
      // which bleaches rhodopsin faster and defeats the palette's only purpose.
      //
      // The suite is NOT relaxed globally to hide this.
      final double bodyFloor = p.id == ShedPaletteId.deepRed && !p.highContrast ? 4.5 : 7.0;

      test('numerals clear the floor on base, raised and fill', () {
        for (final (String surface, Color colour) in <(String, Color)>[
          ('surfaceBase', t.surfaceBase),
          ('surfaceRaised', t.surfaceRaised),
          ('surfaceFill', t.surfaceFill),
        ]) {
          expect(
            contrastRatio(t.textNumeric, colour),
            greaterThanOrEqualTo(bodyFloor),
            reason: '${p.name}: textNumeric on $surface (floor $bodyFloor)',
          );
        }
      });

      test('primary and secondary text clear the palette floor', () {
        expect(
          contrastRatio(t.textPrimary, t.surfaceBase),
          greaterThanOrEqualTo(bodyFloor),
          reason: '${p.name}: textPrimary on surfaceBase (floor $bodyFloor)',
        );
        expect(
          contrastRatio(t.textSecondary, t.surfaceBase),
          greaterThanOrEqualTo(4.5),
          reason: '${p.name}: textSecondary on surfaceBase',
        );
      });

      test('chrome text clears AA and is never used for data', () {
        // The NAME is the contract: 06 §4.2 defines chrome as "never a value the
        // shepherd must read". AA is the floor because it is decoration.
        expect(
          contrastRatio(t.textChrome, t.surfaceBase),
          greaterThanOrEqualTo(4.5),
          reason: '${p.name}: textChrome on surfaceBase',
        );
      });

      test('outline clears the 3:1 non-text requirement', () {
        // Including deep red's #CC2200 at 3.80:1, which is outline-only and
        // never carries a glyph.
        expect(
          contrastRatio(t.outline, t.surfaceBase),
          greaterThanOrEqualTo(3.0),
          reason: '${p.name}: outline on surfaceBase',
        );
      });

      test('status fills are legible with onStatus text', () {
        for (final (String name, Color fill) in <(String, Color)>[
          ('statusReady', t.statusReady),
          ('statusAttention', t.statusAttention),
          ('statusLoss', t.statusLoss),
        ]) {
          expect(
            contrastRatio(t.onStatus, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${p.name}: onStatus on $name',
          );
        }
      });

      test('the tap floor is never below spec §5 and bodySize never below 18', () {
        // The 3am floor, asserted where the values live rather than where they
        // are used. A palette that could ship a 58 pt target is a palette the
        // tap-target sweep has to catch on fourteen screens instead.
        expect(t.tapMin, greaterThanOrEqualTo(60.0), reason: p.name);
        expect(t.bodySize, greaterThanOrEqualTo(18.0), reason: p.name);
        expect(t.tapPrimary, greaterThanOrEqualTo(t.tapMin), reason: p.name);
        expect(t.tapHero, greaterThanOrEqualTo(t.tapPrimary), reason: p.name);
      });

      test('the ramp is a hint and never reaches 3:1', () {
        // 06 §4.2, inverted into an assertion. 1.07:1 and 1.18:1 between surface
        // steps are far BELOW what WCAG asks of a non-text boundary, and that is
        // deliberate: a bright card edge is a light source you stare at for four
        // hours. Any boundary that must be findable under a head torch carries
        // an outline AS WELL AS a ramp step.
        //
        // Written as an upper bound so that "fixing" the ramp to 3:1 — which
        // looks like an accessibility improvement — fails loudly.
        for (final (String name, Color surface) in <(String, Color)>[
          ('surfaceRaised', t.surfaceRaised),
          ('surfacePressed', t.surfacePressed),
          ('surfaceFill', t.surfaceFill),
        ]) {
          expect(
            contrastRatio(surface, t.surfaceBase),
            lessThan(3.0),
            reason:
                '${p.name}: $name against surfaceBase is a HINT, not a '
                'separator — the outline does the work under a torch',
          );
        }
      });
    });
  }

  test('no palette is brighter than the native launch colour', () {
    // 06 §9. launchSurface is a duplicate of the native launch colour, so
    // editing nSurface04 without editing
    // android/app/src/main/res/values/colors.xml fails here.
    //
    // Worded as "no palette's surfaceBase is brighter than the native launch
    // colour" rather than "equals", so it still means something whichever way
    // N11-T04 rules P14.
    for (final ShedPalette p in shedPalettes) {
      expect(
        relativeLuminance(p.tokens.surfaceBase),
        lessThanOrEqualTo(relativeLuminance(launchSurface)),
        reason: '${p.name}: surfaceBase is brighter than the first painted frame',
      );
    }
  });

  test('the night-shift palettes drop luminance, not just hue', () {
    // The naval/aviation finding: at low instrument-lighting levels the
    // red-vs-white advantage largely disappears — INTENSITY matters more than
    // colour — so a night mode that is merely red and just as bright is close to
    // useless.
    //
    // Measured over body text only. See wcag.dart's peakLuminance for why, and
    // note the 0.70 factor is NOT relaxed: relaxing it is the
    // edit-the-gate-to-make-it-green anti-pattern 13 names by name.
    final double peakNight = peakLuminance(nightPalette);

    for (final ShedPalette p in <ShedPalette>[amberPalette, deepRedPalette]) {
      expect(
        peakLuminance(p),
        lessThan(0.70 * peakNight),
        reason: '${p.name}: body text is as bright as night, so it is only red',
      );
    }
  });

  test('the status exception is bounded, not waived', () {
    // 06 §4.3 rule 1 deliberately spends the luminance channel on urgency, so a
    // status mark may exceed the body-text ceiling. It may not exceed night's
    // peak: at that point the night-shift palette is emitting more light than
    // the palette it exists to be dimmer than.
    final double peakNight = peakLuminance(nightPalette);

    for (final ShedPalette p in <ShedPalette>[amberPalette, deepRedPalette]) {
      expect(
        peakStatusLuminance(p),
        lessThan(peakNight),
        reason: '${p.name}: a status mark is brighter than night body text',
      );
    }
  });

  test('the AA exception applies to standard-contrast deepRed and to nothing else', () {
    // A globally relaxed suite is the failure this case exists to catch. Written
    // positively: the other five ARE at AAA on textPrimary, so relaxing the
    // floor everywhere would not make this pass.
    for (final ShedPalette p in shedPalettes) {
      final bool isTheException = p.id == ShedPaletteId.deepRed && !p.highContrast;
      final double ratio = contrastRatio(p.tokens.textPrimary, p.tokens.surfaceBase);

      if (isTheException) {
        expect(
          ratio,
          lessThan(7.0),
          reason: 'if deep red reached AAA the exception would be dead code',
        );
        expect(ratio, greaterThanOrEqualTo(4.5), reason: p.name);
      } else {
        expect(ratio, greaterThanOrEqualTo(7.0), reason: '${p.name} must reach AAA');
      }
    }
  });

  test('every ratio printed in 06 §4.2 to §4.5 is reproduced', () {
    // 06 §3.5: if a number in that document and the test disagree, the test is
    // right and the document is stale. These are the published figures, and this
    // case is what makes it safe to print sixty ratios in prose.
    //
    // THE TOLERANCE IS 0.005 BECAUSE THE DOCUMENT PRINTS TWO DECIMAL PLACES, and
    // that bounds what this case can detect. MEASURED: changing nInk40 from
    // #8A9199 to #8A9198 — one unit of blue — moves its ratio by about 0.001 and
    // does not fail here. So the epic's "change one hex by one digit and the
    // suite names the failing pair" is true only of changes large enough to
    // cross a floor or to shift a printed figure.
    //
    // The single-digit case is caught one tier down instead:
    // test/policy/primitives_are_private_test.dart pins every hex 06 §4
    // publishes, exactly, and the same plant fails there with "06 §4 publishes
    // #8A9199 and this file lost it". Arithmetic here, identity there — and
    // tightening this tolerance to chase it would only make the suite disagree
    // with the document's own precision.
    void published(double got, double want, String what) {
      expect(got, closeTo(want, 0.005), reason: what);
    }

    final ShedTokens n = nightPalette.tokens;
    published(contrastRatio(n.textNumeric, n.surfaceBase), 19.79, 'night textNumeric');
    published(contrastRatio(n.textPrimary, n.surfaceBase), 16.42, 'night textPrimary');
    published(contrastRatio(n.textSecondary, n.surfaceBase), 10.45, 'night textSecondary');
    published(contrastRatio(n.textChrome, n.surfaceBase), 6.21, 'night textChrome');
    published(contrastRatio(n.statusReady, n.surfaceBase), 11.02, 'night statusReady');
    published(contrastRatio(n.statusAttention, n.surfaceBase), 14.02, 'night statusAttention');
    published(contrastRatio(n.statusLoss, n.surfaceBase), 11.66, 'night statusLoss');

    // §4.2's "also measured on the raised surface, because half the app's text
    // sits there".
    published(contrastRatio(n.textPrimary, n.surfaceRaised), 15.08, 'night textPrimary on raised');
    published(
      contrastRatio(n.textSecondary, n.surfaceRaised),
      9.60,
      'night textSecondary on raised',
    );
    published(contrastRatio(n.textChrome, n.surfaceRaised), 5.70, 'night textChrome on raised');

    final ShedTokens a = amberPalette.tokens;
    published(contrastRatio(a.textNumeric, a.surfaceBase), 13.36, 'amber textNumeric');
    published(contrastRatio(a.textPrimary, a.surfaceBase), 11.46, 'amber textPrimary');
    published(contrastRatio(a.textSecondary, a.surfaceBase), 7.79, 'amber textSecondary');
    published(contrastRatio(a.textChrome, a.surfaceBase), 6.78, 'amber textChrome');
    published(contrastRatio(a.outline, a.surfaceBase), 4.85, 'amber outline');
    published(contrastRatio(a.statusLoss, a.surfaceBase), 16.44, 'amber statusLoss');

    final ShedTokens r = deepRedPalette.tokens;
    published(contrastRatio(r.textNumeric, r.surfaceBase), 7.45, 'deepRed textNumeric');
    published(contrastRatio(r.textPrimary, r.surfaceBase), 6.08, 'deepRed textPrimary');
    published(contrastRatio(r.textSecondary, r.surfaceBase), 4.59, 'deepRed textSecondary');
    published(contrastRatio(r.outline, r.surfaceBase), 3.80, 'deepRed outline');
    published(contrastRatio(r.statusLoss, r.surfaceBase), 10.45, 'deepRed statusLoss');

    // §4.5's high-contrast table.
    final ShedTokens nh = nightHcPalette.tokens;
    published(contrastRatio(nh.textPrimary, nh.surfaceBase), 21.00, 'night-hc textPrimary');
    published(contrastRatio(nh.outline, nh.surfaceBase), 4.89, 'night-hc outline');
    published(contrastRatio(nh.statusReady, nh.surfaceBase), 15.94, 'night-hc statusReady');
    published(contrastRatio(nh.statusAttention, nh.surfaceBase), 16.28, 'night-hc statusAttention');
    published(contrastRatio(nh.statusLoss, nh.surfaceBase), 14.16, 'night-hc statusLoss');

    final ShedTokens ah = amberHcPalette.tokens;
    published(contrastRatio(ah.textPrimary, ah.surfaceBase), 13.36, 'amber-hc textPrimary');

    final ShedTokens rh = deepRedHcPalette.tokens;
    published(contrastRatio(rh.textPrimary, rh.surfaceBase), 7.45, 'deepRed-hc textPrimary');
  });

  test('deepRed textSecondary and textChrome are deliberately the same value', () {
    // 06 §4.4. Nothing dimmer clears AA, and inventing a fourth ink step here
    // would mean shipping unreadable text. Asserted so that a future reviewer
    // reads it as a decision rather than a copy-paste slip and "fixes" it.
    expect(deepRedPalette.tokens.textSecondary, deepRedPalette.tokens.textChrome);
  });

  test('the high-contrast variants separate by border, not by tint', () {
    // 06 §4.5: surfaceRaised == surfaceBase, because a few percent of luminance
    // disappears under a head torch. The outline is what becomes load-bearing,
    // so it is asserted in the same breath.
    for (final ShedPalette p in shedPalettes.where((ShedPalette p) => p.highContrast)) {
      expect(
        p.tokens.surfaceRaised,
        p.tokens.surfaceBase,
        reason: '${p.name}: a HC card separated by tint is separated by nothing under a torch',
      );
      expect(
        contrastRatio(p.tokens.outline, p.tokens.surfaceBase),
        greaterThanOrEqualTo(3.0),
        reason: '${p.name}: the outline is the only separator left',
      );
    }
  });

  test('both night-shift palettes take the larger type, not just deep red', () {
    // 06 §4.4. Compensation is bought with SIZE, never weight — bumping weight
    // walks into flutter#139712 — and BOTH night-shift palettes take it so that
    // switching between the honest pair never reflows the screen.
    for (final ShedPalette p in shedPalettes.where(
      (ShedPalette p) => p.id != ShedPaletteId.night,
    )) {
      expect(p.tokens.bodySize, 20.0, reason: p.name);
      expect(p.tokens.numeralSize, 44.0, reason: p.name);
    }
    for (final ShedPalette p in shedPalettes.where(
      (ShedPalette p) => p.id == ShedPaletteId.night,
    )) {
      expect(p.tokens.bodySize, 18.0, reason: p.name);
      expect(p.tokens.numeralSize, 40.0, reason: p.name);
    }
  });

  test('every ColorScheme error role is legible in its own right', () {
    // A NOTE ON WHAT THIS DOES NOT ASSERT, because the first version of this
    // case asserted it and was wrong.
    //
    // "error never doubles as statusLoss" is a real rule — conflating them
    // paints a recorded death in the same pixels as a failed write, a spec
    // §12.2 problem wearing a palette's clothes, and indelible.md §2.7 is
    // blunter still: for a dead lamb, colour is "none, ever". But it is a rule
    // about PROVENANCE, not about pixels: 06 §4.2 gives night statusLoss
    // #FFB4AB and §3.5's own worked nightScheme sets error: nSalmon80 — the same
    // hex, in the same document, deliberately. The palette simply does not have
    // a second pale warm tone.
    //
    // So value identity proves nothing here, and a test that asserted it could
    // only be made to pass by excluding the palettes where it fired — which is
    // what the first draft did. The rule is held instead by the two literals
    // being authored separately from separately named primitives, which is a
    // property of the source and is covered by primitives_are_private_test.dart's
    // naming case, and by review.
    //
    // What IS assertable is that Material's role works as a role: its own text
    // is legible on it, so an AlertDialog action is readable at 03:20.
    for (final ShedPalette p in shedPalettes) {
      expect(
        contrastRatio(p.colorScheme.onError, p.colorScheme.error),
        greaterThanOrEqualTo(4.5),
        reason: '${p.name}: onError on error',
      );
      expect(
        contrastRatio(p.colorScheme.error, p.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${p.name}: error on surface',
      );
    }
  });

  test('no ColorScheme sets background, onBackground or surfaceVariant', () {
    // Source text over palettes.dart, so the failure names the deprecated ROLE
    // rather than arriving as one of eighteen analyzer infos. `gate` runs
    // analyze --fatal-infos, so this is belt and braces — but the braces name
    // the thing.
    final String source = File(
      'lib/core/ui/palettes.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    for (final String role in <String>['background:', 'onBackground:', 'surfaceVariant:']) {
      expect(source, isNot(contains(role)), reason: '$role is deprecated on this SDK');
    }
    // And the generated-scheme ban, which is a gate row as well (#94): Flutter
    // 3.41 changed four on*Container roles for every generated scheme, and you
    // cannot ask a seed for >= 12:1 on the base surface. Here legibility is a
    // safety property, not a brand property.
    expect(source, isNot(contains('fromSeed')));
  });
}
