// lib/features/lambing/widgets/query_mark.dart
//
// TWO DOCUMENTS DESCRIBED TWO DIFFERENT MARKS AND THE AUTHORITY ORDER SETTLED
// IT. `07 §6.3` and `05 §7.5` both call for *"a persistent, tappable 60 pt amber
// strip under the field"*; `indelible.md §2.2` and `§6.2` call for a QUERY MARK
// IN THE MARGIN plus a 2 px madder underline under the offending cell, and
// Indelible has NO STATUS PALETTE AT ALL — *"a colour-coded death reads wrong at
// 4am through a wet freezer bag."*
//
// `CLAUDE.md`'s authority order puts `docs/design/indelible.md` above the
// thirteen engineering documents, so the mark is the query mark. Both engineering
// documents are amended in the same commit, per the amendment rule.
//
// Everything else in `07 §6.3`'s row survives verbatim: never a dialog, never
// blocking, never twice for one field. And `05 §7.5` guarantee 3 is absolute —
// WARNINGS NEVER GATE THE WRITE. A blocked write produces a lost record, which
// is worse than a queried one, and on this screen there is nothing to block
// anyway: every field committed the moment it was tapped.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The margin `?`.
///
/// **IT ADJUSTS NOTHING.** Tapping it opens the sheet that says what was found;
/// it does not focus a field, does not open the keypad and does not pre-fill
/// anything. `Warning.fieldPath` is for scroll-to-field, not for editing —
/// `Warning` has no `fix()`, no `corrected` and no callback, so the API surface
/// for mutation does not exist and no amount of call-site carelessness produces
/// one.
class QueryMark extends StatelessWidget {
  const QueryMark({required this.semanticLabel, required this.onTap, super.key});

  final String semanticLabel;

  /// **Never null.** A mark that cannot be tapped is a mark that cannot be
  /// explained, and an unexplained `?` at 03:20 is worse than no mark.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return ShedTapTarget(
      semanticLabel: semanticLabel,
      // THE WHOLE MARGIN CELL IS THE TARGET (`indelible.md §6.2`): 68 × 64, so
      // the mark is reachable by a thumb rather than by a fingernail. The width
      // is the cell's, not the glyph's.
      minSize: t.tapIndelible,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Center(
          child: Text(
            '?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              // MADDER, WHICH IS THE SYSTEM'S ONE MARGIN INK — not an amber
              // status colour, because there is no status palette. And colour is
              // never the only channel (decisions #14 and #106): the glyph
              // itself carries the meaning, and the underline below the cell
              // carries it a third time.
              color: t.statusAttention,
            ),
          ),
        ),
      ),
    );
  }
}

/// The 2 px madder underline under a queried cell.
///
/// The second channel. A reader who cannot separate the inks still sees a rule
/// that is not there on the cells beside it.
class QueriedUnderline extends StatelessWidget {
  const QueriedUnderline({required this.child, required this.queried, super.key});

  final Widget child;
  final bool queried;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    // `BorderSide.none` RATHER THAN A TRANSPARENT COLOUR, and the gate ruled it
    // twice. `token.material_color` scans this file for the Material palette
    // prefix — so the first version failed for using it, and the SECOND version
    // failed for naming it in this comment while explaining the first. It is
    // described rather than quoted here for that reason.
    //
    // The rule is right on its merits: a transparent Material colour is a
    // palette value that did not come from ShedTokens, and the day somebody
    // changes it to a visible one nothing notices. An absent border is absent.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: queried
              ? BorderSide(color: t.statusAttention, width: t.outlineWidth)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
