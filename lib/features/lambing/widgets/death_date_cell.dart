// lib/features/lambing/widgets/death_date_cell.dart
//
// THREE QUICK ANSWERS AND A STEPPER — NO PICKER AND NO FREE TEXT.
// `showDatePicker` is a `showDialog` call site and the gate bans those outside
// two allowlisted destructive files; it is also a grid of sub-floor targets that
// a cold thumb cannot hit. `07 §7.3` puts the three quick answers first because
// a death recorded at the shed is almost always today's, and the usual case
// should be one tap.
//
// THE LIST STOPS AT TWO DAYS AGO. "THREE DAYS AGO" and "FOUR DAYS AGO" are
// guesses dressed as buttons; beyond two days the stepper is the honest control.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/time/local_date.dart';

typedef DeathDateLabels = ({
  String today,
  String yesterday,
  String twoDaysAgo,
  String Function(LocalDate) formatted,
});

class DeathDateCell extends StatelessWidget {
  const DeathDateCell({
    required this.today,
    required this.selected,
    required this.labels,
    required this.onPicked,
    super.key,
  });

  /// **Passed in, never read from the clock here.** A widget that reached for
  /// the platform clock directly would be untestable across the day boundary and
  /// would disagree with the row above it at midnight — and `time.dart_clock`
  /// bans the call outright in favour of `appNow()` (#46, R23).
  ///
  /// That rule is described rather than spelled here because it is a text scan
  /// over this file, and the first version of this comment failed the gate by
  /// naming the very call it was explaining.
  final LocalDate today;

  final LocalDate? selected;
  final DeathDateLabels labels;
  final ValueChanged<LocalDate> onPicked;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: t.gapMin,
          runSpacing: t.gapMin,
          children: <Widget>[
            for (final ({int back, String label}) c in <({int back, String label})>[
              (back: 0, label: labels.today),
              (back: 1, label: labels.yesterday),
              (back: 2, label: labels.twoDaysAgo),
            ])
              ShedWordButton(
                key: Key('lamb_card.death_date.minus_${c.back}'),
                label: c.label,
                selected: selected == _daysBack(c.back),
                onTap: () => onPicked(_daysBack(c.back)),
              ),
          ],
        ),
        // **`gapMin`, AND IT WAS 4 pt.** Four is not on `§4.1`'s scale, and it
        // put two adjacent 64 pt targets 4 pt apart — a mis-tap between *died
        // today* and *step the date back one day*, which is a wrong date on a
        // dead lamb.
        //
        // The geometric gate was blind to it while `ShedWordButton` expanded to
        // full width: the three date words each took their own run, so the rect
        // above the gap was `TWO DAYS AGO`, sitting wide of the `−` arrow. Giving
        // the button its authored width put `TODAY` over the arrow and the gate
        // reddened immediately. The gap was always wrong; only the geometry that
        // exposed it is new.
        SizedBox(height: t.gapMin),
        // THE STEPPER. Two arrows, each its own target, and the value between
        // them — never a slider and never a drag (both banned outright).
        Row(
          children: <Widget>[
            _Arrow(id: 'lamb_card.death_date.back', glyph: '−', onTap: () => onPicked(_shift(-1))),
            SizedBox(width: t.gapMin),
            // FLEXIBLE, AND MEASURED. `d MMM y` between two 64 pt arrows plus
            // two gaps came to 2.8 px over on a 375 pt phone — the value is the
            // one part that can give, and it ellipsises rather than shrinking,
            // because a shrink-to-fit widget is banned (10 §4.4).
            Flexible(
              child: Text(
                selected == null ? '—' : labels.formatted(selected!),
                key: const Key('lamb_card.death_date.value'),
                style: text.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: t.gapMin),
            _Arrow(
              id: 'lamb_card.death_date.forward',
              glyph: '+',
              onTap: () => onPicked(_shift(1)),
            ),
          ],
        ),
      ],
    );
  }

  LocalDate _daysBack(int days) => today.plusDays(-days);

  /// Steps from the selected date, or from today when nothing is selected —
  /// **never from an invented starting point**.
  LocalDate _shift(int days) {
    final LocalDate from = selected ?? today;
    return from.plusDays(days);
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.id, required this.glyph, required this.onTap});

  final String id;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return ShedTapTarget(
      key: Key(id),
      semanticLabel: glyph,
      minSize: t.tapIndelible,
      // NO HOLD-TO-REPEAT. It is a banned gesture, and a cold thumb resting on
      // an arrow must move one day rather than a fortnight.
      onTap: onTap,
      child: ExcludeSemantics(
        child: Center(child: Text(glyph, style: Theme.of(context).textTheme.displaySmall)),
      ),
    );
  }
}
