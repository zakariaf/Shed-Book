// lib/features/settings/widgets/settings_section.dart
//
// **ONE SECTION SHELL, ELEVEN CALL SITES.** A section that hand-rolls its own
// heading is a section that forgets the heading level — and `10 §3.4` makes the
// heading structure the only way a screen-reader user reaches a setting without
// swiping through every row above it.
//
// `indelible.md §8` screen 12: ruled rows, one setting per row, every control a
// word button or a text field. No cards, no tiles, no expansion panels.
//
// ---------------------------------------------------------------------------
// THE HEADING IS A RULED LINE, NOT A LABEL IN A GAP (rebuilt 2026-08-08)
// ---------------------------------------------------------------------------
//
// It was `Padding(vertical: gapMin)` around a `ShedSectionHeading`, then each row
// followed by a hand-drawn 2 px `SizedBox`. Two consequences, both visible in the
// running app: the heading floated in dead space rather than sitting in the
// ruling, and the rows below it were separated by the gap the padding left, so
// nothing shared an edge. `§8`'s mockup prints the section head as a ruled line
// in the control face — `UNITS`, `TERMINOLOGY`, `APPEARANCE`, `DATA` — and that
// is now literally what it is: a `ShedRuledRow` with a word in it.
//
// **THE ROWS DRAW THEIR OWN RULE NOW**, so the `SizedBox` between them is gone.
// A rule drawn by the parent AND by the child is a 4 px rule, which is what turns
// a ledger into a table.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';

final class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.rows, super.key});

  /// Uppercased here rather than in the ARB, for the reason `ShedPageHeader`
  /// states: the caps are the design system's decision, not the copy's.
  final String title;

  /// One widget per setting, each already a ruled row. **Never empty** — the
  /// screen drops a section with no rows rather than printing a heading over
  /// nothing.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // **READ-ONLY, SO IT IS NOT A TARGET.** `ShedRuledRow` deliberately does
      // not wrap a row with no `onTap` in a `ShedTapTarget`, which is what keeps
      // a 64 pt heading out of the geometric gate's separation sweep.
      ShedRuledRow(child: ShedSectionHeading(label: title.toUpperCase())),
      ...rows,
    ],
  );
}
