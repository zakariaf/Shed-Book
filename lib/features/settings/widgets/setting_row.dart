// lib/features/settings/widgets/setting_row.dart
//
// **THE SHAPE EVERY SETTING IS, AND UNTIL 2026-08-08 THERE WAS NO SHAPE AT ALL.**
//
// Measured against the running app: each section rendered a `Padding` with 8 pt
// of vertical space around a word button, and nothing else. No rule, no label
// above the control, no shared edge — twelve headings floating over loose words
// on black. `indelible.md §8` screen 12 asks for the opposite in one sentence:
// *"Ruled rows, one setting per row, every control a word button or a text
// field."*
//
// So there are exactly two shapes on this screen and both are `ShedRuledRow`:
//
//   * [SettingRow]  — a control. Label above in the control voice, the control
//                     sitting on the rule. `§7.12`'s geometry, applied to a
//                     word button rather than to a text field.
//   * [SettingLine] — a printed line. No target, no control, record voice. The
//                     offline statement, a refusal, a count, a term.
//
// ---------------------------------------------------------------------------
// THE ONE ADJACENCY THAT IS ILLEGAL, AND IT IS ARITHMETIC RATHER THAN TASTE
// ---------------------------------------------------------------------------
//
// R86: two targets are 0 apart (sharing an edge) or >= 16 apart, never between.
// A [SettingRow]'s control is inset `gapMin / 2` from the row's own edges, so
// two stacked control rows put 8 + 2 + 8 = 18 between their targets, and a
// labelled one puts far more. Both clear the floor.
//
// A **whole-row** target does not: a `ShedRuledRow(onTap:)` fills its row, so a
// control row directly beneath one measures 0 + 2 + 8 = 10 — the middle of the
// forbidden band. Put a heading, a [SettingLine] or another whole-row target
// between them; never a bare [SettingRow].
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One setting, on one ruled line.
final class SettingRow extends StatelessWidget {
  const SettingRow({required this.control, super.key, this.label});

  /// A word button, or a `Wrap` of them.
  ///
  /// **NEVER A TOGGLE AND NEVER A TRACK-AND-THUMB CONTROL.** Both are drag
  /// targets with a tap fallback, and drag is banned outright (`06 §7`) — a
  /// control whose primary gesture the app does not support teaches the wrong
  /// thing. Two `check_policy` rows hold it, and they scan every line including
  /// this one, which is why neither widget is named here.
  final Widget control;

  /// The line above the control, in the control voice.
  ///
  /// **`null` where the section heading already says it**, which is the whole of
  /// sections 7 and 8: a heading reading `KEEP SCREEN ON` over a row labelled
  /// `KEEP SCREEN ON` is the same word twice, and the heading row is already
  /// welded to this one by a shared edge.
  ///
  /// Uppercased **here** rather than in the ARB, for the reason
  /// `ShedPageHeader` states: the caps are a typographic decision owned by the
  /// design system, and storing them in the copy catalogue loses that the first
  /// time somebody edits the string.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return ShedRuledRow(
      // `§4.4`'s tall row. A 19 pt label over a 64 pt target is 88 before any
      // text scaling, which is exactly what the second row height is for.
      height: kRuledRowTall,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.gapMin / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (label case final String l) ...<Widget>[
              Text(
                l.toUpperCase(),
                // `§7.12`: the label is caps, control voice, `--ink-mid`. It is
                // never the value and must not read as one.
                style: text.labelMedium?.copyWith(color: t.textSecondary),
              ),
              SizedBox(height: t.gapMin / 4),
            ],
            control,
          ],
        ),
      ),
    );
  }
}

/// A line the page prints rather than a thing the shepherd presses.
///
/// **IT IS A ROW, NOT A PARAGRAPH IN A GAP.** The three About paragraphs, the
/// cap refusal, the diagnostics verdict and the terminology terms were all loose
/// `Text`s between two `SizedBox`es; ruled, they read as part of the same
/// document as everything above them.
final class SettingLine extends StatelessWidget {
  const SettingLine({required this.text, super.key, this.label, this.textKey, this.muted = false});

  final String text;

  /// Same contract as [SettingRow.label] — uppercased here.
  final String? label;

  /// Goes on the `Text` itself, because two tests read
  /// `tester.widget<Text>(…).data` off the About paragraphs and a key on the row
  /// would find a `ShedRuledRow` instead.
  final Key? textKey;

  /// `--ink-mid` rather than full ink, for a line that **qualifies** something
  /// above it — a refusal, a count under a verdict. Never for a line that is the
  /// only statement of its fact.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme style = Theme.of(context).textTheme;

    return ShedRuledRow(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.gapMin / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (label case final String l) ...<Widget>[
              Text(l.toUpperCase(), style: style.labelMedium?.copyWith(color: t.textSecondary)),
              SizedBox(height: t.gapMin / 4),
            ],
            Text(
              text,
              key: textKey,
              // The record voice — sentence case, `w500`. A printed line is a
              // statement of fact, and `§1.2` rule 2 says facts are not set in
              // the voice of things you can press.
              style: muted ? style.bodyMedium?.copyWith(color: t.textSecondary) : style.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
