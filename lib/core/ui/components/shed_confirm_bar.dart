// lib/core/ui/components/shed_confirm_bar.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The full-width confirm bar.
///
/// **Its label is the OUTCOME, never the act.** `Create 412`, `Use 412`,
/// `7 days — as entered by you`. indelible.md §11 test 7 and 06 §8.2 both ban
/// `OK`, `Done`, `Confirm`, `Submit` and `Save`: at 03:20 a shepherd reading
/// `OK` has to reconstruct what they are agreeing to from memory, and the whole
/// point of the bar is that they do not have to.
///
/// That ban is enforced in the constructor rather than left to review — see
/// [bannedLabels].
final class ShedConfirmBar extends StatelessWidget {
  ShedConfirmBar({
    required this.outcomeLabel,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  }) : assert(
         !bannedLabels.contains(outcomeLabel.trim().toUpperCase()),
         'A confirm bar says the OUTCOME, never the act: '
         '"$outcomeLabel" is one of $bannedLabels',
       );

  /// The words a confirm bar may never be.
  ///
  /// Compared upper-cased and trimmed, so `ok`, ` OK ` and `Ok` are all caught.
  /// **An `assert` is stripped in release**, so a test asserts the same set over
  /// the constructor — the list is the shared source for both.
  static const Set<String> bannedLabels = <String>{
    'OK',
    'DONE',
    'CONFIRM',
    'SUBMIT',
    'SAVE',
    'CANCEL',
    'YES',
    'NO',
  };

  final String outcomeLabel;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return SizedBox(
      width: double.infinity,
      height: t.tapHero,
      child: ShedTapTarget(
        onTap: onTap,
        semanticLabel: semanticLabel,
        minSize: t.tapHero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceFill,
            border: Border.all(color: t.outline, width: t.outlineWidth),
            borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Center(
              // VERBATIM: no ellipsis, no maxLines, and nothing that scales the
              // glyphs down to fit (the widget that does is a gate row,
              // type.fitted_box, described rather than named because that row
              // scans this file). The outcome is the one string on screen that
              // must survive 200% text intact — a truncated outcome is a
              // shepherd agreeing to something they cannot read.
              child: Text(outcomeLabel, style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ),
      ),
    );
  }
}
