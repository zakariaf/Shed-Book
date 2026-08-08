// lib/features/quick_entry/widgets/tag_sheet.dart
//
// **THE SHEET HAS FOUR PARTS AND THE APP SHIPPED WITH ONE.**
//
// `indelible.md §8`: *"Tap the TAG cell. The sheet rises 160ms into the bottom
// half. The six recents print as full-width 64px ruled lines — `412 · penned 2h ·
// twin last year`, `128 · lambed yesterday · twins` … — with the keypad's twelve
// keys beneath them. One press of a recent line is the whole selection. That is
// the common case and it costs one tap."*
//
// What existed was the keypad, permanently open on the page, with no header, no
// match list and no way to close it. So the common case — press the ewe you can
// already see — did not exist, and every selection went through typing digits.
//
// **THE MATCHES ARE RULED LINES, NOT A DROPDOWN** (`§8`): *"they are the same
// 64px row as everything else, in the same place, so there is nothing new to
// learn under stress."*
//
// **THE CREATE LINE IS ALWAYS PRESENT, EVEN WHEN THERE ARE MATCHES** — `§8` is
// explicit and gives the reason: *"at 3am the ewe you are holding might genuinely
// be a tag you have never entered and the app must never stop to make you go and
// set something up first."* It is the last printed line, never a modal, never a
// confirm.
//
// **THE MATCH LIST IS WHAT GIVES.** `06 §8.2`: the pad grows and *"the match list
// above it gives up rows"*. That is why the list is the `Expanded` here and the
// display line, the create line and the keypad are not.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One selectable animal in the list.
typedef ShedTagMatch = ({
  String id,
  String tag,
  String summary,
  String semanticLabel,
  VoidCallback onTap,
});

/// `§8`'s tag sheet.
final class TagSheet extends StatelessWidget {
  const TagSheet({
    required this.heading,
    required this.query,
    required this.matches,
    required this.createLabel,
    required this.onCreate,
    required this.onDigit,
    required this.onBackspace,
    required this.onNewTag,
    required this.padLabel,
    required this.backspaceLabel,
    required this.backspaceHint,
    required this.newTagLabel,
    required this.rowHeight,
    required this.marginWidth,
    super.key,
    this.emptyNote,
  });

  /// `TAG · 3 MATCHES · IN THE PENS FIRST`, already composed by the screen.
  final String heading;

  /// The digits typed so far. Empty prints nothing rather than a placeholder —
  /// §7.12's rule, and in the dark a grey placeholder is indistinguishable from
  /// an entered value.
  final String query;

  final List<ShedTagMatch> matches;

  /// `no such tag — write 12 into the book`.
  final String createLabel;
  final VoidCallback onCreate;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onNewTag;
  final String padLabel;
  final String backspaceLabel;
  final String backspaceHint;
  final String newTagLabel;

  final double rowHeight;
  final double marginWidth;

  /// One line where the list would be, or `null` when there is a list.
  ///
  /// **TWO DIFFERENT STRINGS, NEVER ONE.** *Not read yet* and *read and empty*
  /// are different facts, and a shared "nothing here" tells a shepherd on their
  /// first night that the app lost their flock. The caller picks; this only
  /// places it.
  final String? emptyNote;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      key: const Key('quick_entry.tag_sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The heading and the typed digits, on one ruled block. The digits are
        // the record face at display size, because they are what the shepherd
        // matches against the tag in the row above.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                heading,
                key: const Key('quick_entry.tag_sheet.heading'),
                style: text.labelMedium?.copyWith(color: t.textSecondary),
              ),
              SizedBox(
                height: t.tapIndelible,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    query,
                    key: const Key('quick_entry.tag_sheet.query'),
                    style: text.displayMedium?.copyWith(color: t.textPrimary),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // **THE ROWS ARE THE PAGE'S ROWS.** Same height, same margin cell, same
        // right-aligned tag column — so nothing new has to be learned here.
        if (emptyNote case final String note)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  note,
                  key: const Key('quick_entry.tag_sheet.empty'),
                  style: text.labelMedium?.copyWith(color: t.textSecondary),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              key: const Key('quick_entry.tag_sheet.matches'),
              itemCount: matches.length,
              itemBuilder: (BuildContext context, int i) {
                final ShedTagMatch m = matches[i];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                    ),
                  ),
                  child: ShedTapTarget(
                    key: Key('quick_entry.tag_sheet.match.${m.id}'),
                    semanticLabel: m.semanticLabel,
                    minSize: rowHeight,
                    onTap: m.onTap,
                    child: ExcludeSemantics(
                      child: Row(
                        children: <Widget>[
                          // **RIGHT-ALIGNED IN A FIXED COLUMN, AND THAT IS THE
                          // WHOLE REASON THE LIST SCANS** (`§8`): *"the tags are
                          // right-aligned on a tabular grid, so `12` sits under the
                          // `12` of `412` and `128` and the match is visible as a
                          // shape before you have read a single digit."*
                          SizedBox(
                            width: marginWidth,
                            child: Text(
                              m.tag,
                              textAlign: TextAlign.right,
                              style: text.headlineSmall?.copyWith(color: t.textPrimary),
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: t.gapMin / 2),
                          Expanded(
                            child: Text(
                              m.summary,
                              style: text.bodyMedium?.copyWith(color: t.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // **THE LAST PRINTED LINE. ALWAYS.**
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: t.outline, width: t.outlineWidth),
              bottom: BorderSide(color: t.outline, width: t.outlineWidth),
            ),
          ),
          child: ShedTapTarget(
            key: const Key('quick_entry.tag_sheet.create'),
            semanticLabel: createLabel,
            minSize: rowHeight,
            onTap: onCreate,
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    createLabel,
                    style: text.bodyLarge?.copyWith(color: t.textPrimary),
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        ShedKeypad(
          onDigit: onDigit,
          onBackspace: onBackspace,
          thirdKey: ShedKeypadThirdKey.newTag,
          onThirdKey: onNewTag,
          padLabel: padLabel,
          backspaceLabel: backspaceLabel,
          backspaceHint: backspaceHint,
          thirdKeyLabel: newTagLabel,
        ),
      ],
    );
  }
}
