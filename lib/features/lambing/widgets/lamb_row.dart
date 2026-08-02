// lib/features/lambing/widgets/lamb_row.dart
//
// `LAMB 1 · EWE LAMB · ALIVE · 4.1 kg` — one 64 px sub-row per lamb, indented
// under the tally it belongs to.
//
// NOT `ShedAnimalRow` (N10-T04). That row is ewe-shaped: full bleed, a summary
// line under the tag, and a tap target that opens an animal. A lamb sub-row is
// narrower, carries no summary line, and belongs to the lambing above it rather
// than to a list of its own. Reusing the ewe row here would put a lamb at the
// same visual rank as its dam.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

/// The words for one lamb, resolved by the SCREEN and handed down.
///
/// **A record of strings rather than an `AppLocalizations` lookup**, for the
/// same reason [ShedTapTarget] takes `semanticLabel`: `lib/features/` may import
/// `lib/l10n/` (R80), but a widget that resolves its own copy cannot be pumped
/// without a localisations ancestor, and every rendering case then pays for a
/// `MaterialApp`. The screen knows the locale; this row knows the geometry.
typedef LambRowLabels = ({
  /// `LAMB 1` — the ordinal is already interpolated, because the animal noun is
  /// the shepherd's own word and only the screen has read it.
  String ordinal,
  String sex,
  String status,
  String weight,
  String tag,

  /// The whole row as one sentence, for the screen reader. Assembled by the
  /// screen so the separator is a comma to a voice and a middot to an eye.
  String semanticLabel,
});

/// Renders one lamb. Struck lambs are drawn by the caller's strike affordance,
/// not here — this row has no opinion about deletion.
class LambRow extends StatelessWidget {
  const LambRow({required this.labels, super.key, this.onTap});

  final LambRowLabels labels;

  /// Null on the read-only paths. **Null does not disable anything visible**:
  /// there is no button here, so there is no dead key — the row simply is not
  /// interactive, which a cold thumb learns by nothing happening rather than by
  /// a greyed affordance (`indelible.md §7.2`).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return ShedTapTarget(
      semanticLabel: labels.semanticLabel,
      // 64, NOT THE 60 pt FLOOR, and the test asserts the same. A case written
      // against 60 passes against a row that has forgotten it is a row, because
      // ShedTapTarget falls back to tapMin when minSize goes away — the same
      // trap the keypad case documents.
      minSize: t.tapIndelible,
      onTap: onTap,
      child: Padding(
        // INDENTED FROM THE LEFT. The indent is what says "this belongs to the
        // lambing above".
        //
        // ONE gapMin either side, plus a leading gap inside the row.
        // indelible.md's four-based scale has a 32 pt step that would indent
        // more decisively, but `ShedTokens` exposes `gapMin` and
        // `gapDestructive` and nothing between — and `gapDestructive` means
        // "clearance from a destructive control", which a lamb row is not.
        // Doubling `gapMin` here would be a literal wearing arithmetic as a
        // disguise (06 §1). If 16 does not read as a sub-row on a real device,
        // the fix is a token, not a multiplier.
        padding: EdgeInsets.symmetric(horizontal: t.gapMin),
        child: ExcludeSemantics(
          // ONE Text, NOT A ROW OF CELLS, AND THE OVERFLOW MATRIX RULED IT.
          //
          // It was five Flexible cells with four middot separators between them.
          // Flex lays out the NON-FLEXIBLE children first and shares what is
          // left, so at textScaler 2.0 the four separators alone claimed more
          // than the row had — 92 px over at Device.small, measured across six
          // matrix cells. Making the separators flexible too would let a middot
          // ellipsise into nothing, which is worse than either.
          //
          // One line, one ellipsis, at the end where it belongs: the ordinal and
          // the sex survive on the narrowest phone at the largest text, and the
          // tag is what gives way — which is the right order, because the tag is
          // the one thing a lamb does not have yet at 03:20.
          //
          // The separator's spaces are in the string for the same reason as
          // before: the gap either side of a middot is typographic.
          child: Text(
            <String>[
              labels.ordinal,
              labels.sex,
              labels.status,
              labels.weight,
              if (labels.tag.isNotEmpty) labels.tag,
            ].join(' · '),
            style: text.bodyMedium,
            maxLines: 1,
            // ELLIPSISED, NEVER SHRUNK. A shrink-to-fit widget is banned (10
            // §4.4): shrinking this line is how an 18 pt floor becomes 9 pt on
            // the one device whose owner turned the text up.
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Turns one lamb's four facts into the strings the row draws.
///
/// **Absent is not unknown, in both directions** (R45). A null [sex] renders the
/// *not recorded* label; `Sex.unknown` renders the shepherd's word for unknown.
/// A null [weight] and a null [tag] are likewise blanks the shepherd has not
/// filled, never zeroes and never guesses — §12.4 is what makes that structural,
/// and this function is where it would be lost.
LambRowLabels lambRowLabels({
  required int ordinal,
  required Sex? sex,
  required LambStatus status,
  required Grams? weight,
  required String? tag,
  required WeightUnit units,
  required String localeName,
  required String Function(int) ordinalLabel,
  required String Function(Sex) sexLabel,
  required String Function(LambStatus) statusLabel,
  required String notRecorded,
  required String Function(List<String>) sentence,
}) {
  final String sexWord = sex == null ? notRecorded : sexLabel(sex);
  final String statusWord = statusLabel(status);
  final String weightWord = weight == null
      ? notRecorded
      : formatShedWeight(weight, units, localeName);
  final String tagWord = tag ?? '';

  return (
    ordinal: ordinalLabel(ordinal),
    sex: sexWord,
    status: statusWord,
    weight: weightWord,
    tag: tagWord,
    semanticLabel: sentence(<String>[
      ordinalLabel(ordinal),
      sexWord,
      statusWord,
      weightWord,
      if (tagWord.isNotEmpty) tagWord,
    ]),
  );
}
