// lib/features/pens/widgets/pen_sheet.dart
//
// **THE PEN BOARD COULD READ AND NOT WRITE.**
//
// `pen_board_screen.dart` carried `onTap: () {}` on every tile, with the
// comment *"T07 OPENS THE ROW; the verbs inside it are the sheet's"*. There was
// no sheet. `enterPen`, `exitPen`, `movePen` and `correctEnteredAt` all landed
// at N19 with their own tests and none of them had a caller in `lib/` — so a
// shepherd could add a pen and could not put an animal in it, take one out, or
// move one.
//
// Found 2026-08-05 by the uncalled-verb sweep.
//
// **`TURN OUT` IS ONE OF THE FIVE WORDS THE DESIGN NAMES** (`indelible.md §6`:
// every action is a word, there is no icon set). It is the daily act on this
// screen and it was the one thing the board could not do.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// What the shepherd chose. **A sealed outcome rather than four callbacks**, so
/// the screen handles one shape and a fifth verb cannot be added without the
/// switch failing to compile.
sealed class PenAction {
  const PenAction();
}

final class PenAnimal extends PenAction {
  const PenAnimal(this.ewe);
  final EweId ewe;
}

final class TurnOut extends PenAction {
  const TurnOut();
}

final class MoveTo extends PenAction {
  const MoveTo(this.pen);
  final PenId pen;
}

/// The §12.5 edit path. **`correctEnteredAt` had no caller** — it landed at
/// N19-T06 with tests, and the board could MARK a corrected penning time
/// (`TimeSource.edited` is one of the tile's states) without being able to make
/// one.
final class CorrectEnteredAt extends PenAction {
  const CorrectEnteredAt(this.hour, this.minute);
  final int hour;
  final int minute;
}

/// One pen's verbs, opened by pressing its tile.
class PenSheet extends StatelessWidget {
  const PenSheet({
    required this.occupied,
    required this.candidates,
    required this.otherPens,
    required this.l10n,
    required this.onAction,
    required this.onCorrectTime,
    super.key,
  });

  /// `false` is an empty pen, and its only verb is putting an animal in it.
  final bool occupied;

  /// The deck — penned first, then recents, the same order every other picker
  /// in the app uses.
  final List<DeckEntry> candidates;

  /// Every pen but this one.
  final List<({PenId id, String label})> otherPens;

  final AppLocalizations l10n;
  final ValueChanged<PenAction> onAction;

  /// Opens the time editor. **A separate callback rather than a `PenAction`**,
  /// because it is the only verb here that asks a question before it writes —
  /// the other three commit on the tap.
  final VoidCallback onCorrectTime;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!occupied) ...<Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Text(
                l10n.penSheetPenAnimal,
                key: const Key('pen_sheet.heading'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            // **A HEADING OVER NOTHING IS THE DEFECT THIS WHOLE FILE EXISTS TO
            // UNDO, ONE SCALE SMALLER.** An empty deck happens on a fresh
            // notebook — no ewe has been touched yet — and the sheet said
            // *WHICH ANIMAL* over a blank space. Say what is true instead.
            if (candidates.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  l10n.penSheetEmpty,
                  key: const Key('pen_sheet.empty'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final DeckEntry e in candidates)
              ShedAnimalRow(
                key: Key('pen_sheet.animal.${e.tag}'),
                tag: e.tag,
                summary: e.penLabel ?? '',
                semanticLabel: e.tag,
                // ONE TAP IS THE WRITE. There is no confirm on this screen —
                // penning is a daylight act with an obvious undo, which is
                // turning her back out.
                onTap: () => onAction(PenAnimal(e.eweId)),
              ),
          ] else ...<Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShedWordButton(
                  key: const Key('pen_sheet.turn_out'),
                  label: l10n.penSheetTurnOut,
                  semanticLabel: l10n.penSheetTurnOut,
                  selected: false,
                  onTap: () => onAction(const TurnOut()),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Text(
                l10n.penSheetMove,
                key: const Key('pen_sheet.move_heading'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShedWordButton(
                  key: const Key('pen_sheet.correct_time'),
                  label: l10n.penSheetCorrectTime,
                  semanticLabel: l10n.penSheetCorrectTime,
                  selected: false,
                  onTap: onCorrectTime,
                ),
              ),
            ),
            for (final ({PenId id, String label}) pen in otherPens)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShedWordButton(
                    key: Key('pen_sheet.move_to.${pen.label}'),
                    label: l10n.penSheetMoveTo(label: pen.label),
                    semanticLabel: l10n.penSheetMoveTo(label: pen.label),
                    selected: false,
                    onTap: () => onAction(MoveTo(pen.id)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
