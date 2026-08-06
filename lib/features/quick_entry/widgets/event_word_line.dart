// lib/features/quick_entry/widgets/event_word_line.dart
//
// **FIVE WORDS. THE SCREEN SHIPPED WITH ONE.**
//
// `indelible.md §8` Screen 3: *"The event buttons — `LAMBING · TREATMENT · NOTE ·
// DEATH · MOVE PEN` — are five in-stream word buttons on a single 64px ruled line
// directly above the live row, at the top of the thumb band. Lambing is
// pre-selected on tonight's page because that is what tonight is."*
//
// What existed was a lone `Lambing` label sharing a row with `INDEX`, so four of
// the five things that can happen in a shed at 03:20 had no affordance on the
// screen the shepherd is standing on. They were all reachable — through `INDEX`,
// two taps deeper, on a screen with a different shape.
//
// **THE LINE IS ONE 64 px RULED ROW AND IT WRAPS RATHER THAN SCROLLS.** Five
// words do not fit across 393 px at any text scale, and a horizontally scrolling
// strip needs a swipe — banned outright (§9). The Flock screen's filter line has
// the same shape and `§8` Screen 1 gives the same reason: *"they wrap onto ruled
// lines rather than scrolling sideways."* So the row is a minimum height, not a
// fixed one, and it grows downward when the words need a second line.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One event word and what pressing it does.
typedef ShedEventWord = ({String id, String label, bool selected, VoidCallback onTap});

/// `§8`'s event line: five words on one ruled row above the live row.
final class EventWordLine extends StatelessWidget {
  const EventWordLine({required this.words, required this.semanticLabel, super.key});

  final List<ShedEventWord> words;

  /// The group's own label. `lib/core/ui/` may not resolve copy and neither may
  /// this widget invent any — the screen that knows the locale supplies it.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return DecoratedBox(
      key: const Key('quick_entry.event_line'),
      // Rows share edges: a 2 px bottom rule and no gap (`§7.3`).
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: t.outline, width: t.outlineWidth),
        ),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: ConstrainedBox(
          // **A MINIMUM, NOT A HEIGHT.** At 200% the five words need two lines,
          // and a fixed 64 would clip the second one — `§3.6`: rows grow, the
          // grid does not move.
          constraints: BoxConstraints(minHeight: t.tapIndelible),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin / 2),
            child: Wrap(
              // **`gapMin`, NEVER `spaceBetween`.** `spaceBetween` distributes
              // whatever is left over, which on a 375 pt device at textScaler
              // 2.0 came out at 4.0, 6.0 and 10.97 pt between adjacent targets —
              // and `test/design/tap_target_test.dart` is right to redden on
              // that. P9 is the OPEN question of whether Indelible's own 8–12 pt
              // geometry may relax the 16 pt floor, and it is the owner's; this
              // is not that question. `indelible-page-and-screens §9`: *"use
              // `gapMin` for every new gap you are free to choose"* — and this
              // one is free.
              spacing: t.gapMin,
              // Zero vertically, which is the ledger idiom and the gate's other
              // permitted separation: the two runs of words are two ruled lines
              // sharing an edge, exactly as §7.3 draws every other row.
              runSpacing: 0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final ShedEventWord w in words)
                  ShedWordButton(
                    key: Key('quick_entry.event.${w.id}'),
                    label: w.label,
                    selected: w.selected,
                    onTap: w.onTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
