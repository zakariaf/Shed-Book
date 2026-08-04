// lib/features/flock/widgets/season_heading.dart
//
// **A PRINTED SUB-HEAD AND A DOUBLED RULE** (`indelible.md §8` screen 2). The
// doubled rule means *a total, a boundary, a threshold crossed*, and a season
// boundary is exactly that — readable in peripheral vision from across the shed,
// which is the property the doubled rule exists for. A single rule would read as
// one more row boundary among eighty.
//
// **AND IT IS A `headingLevel: 2` STOP.** `10 §3.4` states the stake: *"For a
// sighted user that is a glance. For a VoiceOver user the only equivalent is the
// rotor set to Headings and one flick."* Without these, that user swipes through
// every field on the card.
//
// **NOT A TARGET.** Nothing collapses, nothing filters, nothing hides behind it
// — it is a printed line, so it carries no `ShedTapTarget` and cannot fail a
// tap-target gate for being under 60 pt.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

final class SeasonHeading extends StatelessWidget {
  const SeasonHeading({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return Semantics(
      headingLevel: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Two 2 px rules with a gap between them. Rules never scale with
            // text — a rule is a physical mark, not type (`§3.6`).
            _rule(t),
            SizedBox(height: t.outlineWidth),
            _rule(t),
            SizedBox(height: t.gapMin / 2),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _rule(ShedTokens t) => SizedBox(
    height: t.outlineWidth,
    child: ColoredBox(color: t.outline),
  );
}
