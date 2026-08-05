// lib/features/quick_entry/widgets/index_sheet.dart
//
// **`INDEX` WAS `onIndex: () {}` AND NOTHING IN THE APP WAS REACHABLE.**
//
// Run on a simulator on 2026-08-05: from Quick Entry a shepherd could reach
// Flock, the pen board, the medicine book, Export and Settings — not one of
// them. Every screen had a `RouteNames` constant, a built widget, a matrix
// variant and a full test file, and three of them did not even have a push
// helper. The only route out of the first screen was the export banner, which
// shows on about one day in thirty.
//
// It is the same defect as the thirty-seven repository verbs with no caller,
// one level up, and the reachability sweep never looked at routes. **A screen
// nothing pushes is a screen nobody sees**, and every test pumps it directly.
//
// `indelible.md §7.17`: the index is ruled lines in the sheet, each 64 px, each
// a word and a summary. The summaries are `v1.1.0`'s — they need counts from
// screens that do not exist — so the lines carry their words alone for now,
// which is what §7.17's own last line already does for `SETTINGS`.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One destination.
typedef IndexLine = ({String id, String label, VoidCallback? onTap});

/// `§7.17`'s ruled lines. **Rows share edges — no gaps** (R86, `§7.3`): the
/// ruling is continuous, like a ledger.
class IndexSheet extends StatelessWidget {
  const IndexSheet({required this.lines, super.key});

  final List<IndexLine> lines;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final IndexLine line in lines)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                ),
              ),
              child: ShedTapTarget(
                key: Key('quick_entry.index.${line.id}'),
                semanticLabel: line.label,
                minSize: t.tapIndelible,
                // **NEVER `null`, EVEN FOR TONIGHT.** A dead row reads as a
                // missed tap at 03:20; the line the shepherd is already on
                // closes the sheet, which is the honest answer to pressing it.
                onTap: line.onTap ?? () => Navigator.of(context).pop(),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(line.label, style: text.labelLarge),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
