// lib/features/settings/widgets/settings_section.dart
//
// **ONE SECTION SHELL, ELEVEN CALL SITES.** A section that hand-rolls its own
// heading is a section that forgets the heading level — and `10 §3.4` makes the
// heading structure the only way a screen-reader user reaches a setting without
// swiping through every row above it.
//
// `indelible.md §8` screen 12: ruled rows, one setting per row, every control a
// word button or a text field. No cards, no tiles, no expansion panels.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';
import 'package:shed_book/core/ui/tokens.dart';

final class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.rows, super.key});

  final String title;

  /// One widget per setting. The section draws the rule between them, so a row
  /// never has to know whether it is last.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
          child: ShedSectionHeading(label: title),
        ),
        for (final Widget row in rows) ...<Widget>[
          row,
          // A 2 px rule and nothing else — rows share edges, which is the ledger
          // ruling `indelible.md §4.4` describes. Rules never scale with text.
          SizedBox(
            height: t.outlineWidth,
            child: ColoredBox(color: t.outline),
          ),
        ],
      ],
    );
  }
}
