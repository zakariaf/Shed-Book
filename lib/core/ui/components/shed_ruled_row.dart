// lib/core/ui/components/shed_ruled_row.dart
//
// **`indelible.md §7.3`'s ROW, AND SIX SCREENS HAND-ROLLED IT OR SKIPPED IT.**
//
// §7.3: *"Full width, 64px, 2px `--rule` bottom border only (rows share edges;
// there is no top border and no gap — the ruling is continuous, like a ledger)."*
// Measured against the running app on 2026-08-06: the flock listed tags with
// vertical gaps between them, the pen board stacked three lines per pen with a
// gap after each, and Settings put loose space between every control. None of
// them drew a rule and none of them shared an edge.
//
// **THE GAPS ARE WHY IT READS AS SPARSE.** A ledger's ruling is what makes a
// column of numbers scannable — the eye runs down a continuous edge rather than
// hopping between islands. Take the rules away and what is left is a list of
// words floating on black, which is exactly the *"small word with just one line
// behind it"* the owner described.
//
// **NOT A CARD, NOT A LIST TILE.** No radius, no fill, no shadow, no elevation,
// no leading icon slot (`§1.3`: there is no icon set). A row is a rule and the
// space above it.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// `§4.4`'s two row heights. The 44 pt chart row is the only sub-64 row in the
/// system and it is read-only, so it is not built from this.
const double kRuledRowHeight = 64;

/// `§4.4`: the ewe row and the pen row. 32 pt tag over an 18 pt summary needs it.
const double kRuledRowTall = 88;

/// `§4.3`: margin cell 0–68, spine at 68, record column from 76.
const double kRuledMarginWidth = 68;

/// One ruled line in the document.
///
/// The whole row is the target when [onTap] is given, which is `§4.3`'s own
/// arrangement — the margin cell is 68 × 64 and legal on its own, and folding it
/// in makes the row a bigger target rather than leaving a dead strip beside one.
final class ShedRuledRow extends StatelessWidget {
  const ShedRuledRow({
    required this.child,
    super.key,
    this.margin,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.height = kRuledRowHeight,
    this.selected,
    this.struck = false,
  });

  /// The record column's content, from x=76.
  final Widget child;

  /// The 68 pt margin cell: a time, a stamp, a dagger, a query mark. `null`
  /// leaves the gutter empty — which is correct for a row that is not a record.
  final Widget? margin;

  /// The tally, an hours figure, a stamp. Sized to its content.
  final Widget? trailing;

  /// `null` makes the row read-only. **It does not make it look disabled** —
  /// there is no disabled rendering in this system.
  final VoidCallback? onTap;

  final String? semanticLabel;

  /// [kRuledRowHeight] or [kRuledRowTall]. **A minimum, not a fixed height**
  /// (`§3.6`: rows grow, the grid does not move).
  final double height;

  /// Announced on the node, never spelled into the label (`10 §3.2` rule 2).
  final bool? selected;

  /// Dims the row's rule to `--ink-low` and nothing else. **The strike itself is
  /// a painted 3 px madder rule through the record column** and belongs to the
  /// caller — this only stops a struck row's boundary shouting louder than its
  /// content.
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    final Widget row = Padding(
      padding: EdgeInsets.only(right: t.gapMin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(width: kRuledMarginWidth, child: margin),
          // The 8 pt gutter between the spine at x=68 and the record column at
          // x=76. It is not a gap between targets — the spine is painted behind
          // the whole page — so it is not R86's business.
          SizedBox(width: t.gapMin / 2),
          Expanded(child: child),
          if (trailing case final Widget w) w,
        ],
      ),
    );

    return DecoratedBox(
      // **BOTTOM ONLY. ROWS SHARE EDGES.** A top border would double every
      // interior rule to 4 pt and turn the ledger into a table.
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: struck ? t.textSecondary : t.outline,
            // `--rule-w` never scales with text: a rule is a physical mark, not
            // type (`§3.6`).
            width: t.outlineWidth,
          ),
        ),
      ),
      child: onTap == null
          // **NOT WRAPPED IN A TARGET WHEN IT IS NOT ONE.** A `GestureDetector`
          // with a null handler still contributes a semantics node the geometric
          // gate then measures, and a read-only row measured as a target is how a
          // 60 pt floor gets a false negative.
          ? ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: row,
            )
          : ShedTapTarget(
              semanticLabel: semanticLabel ?? '',
              selected: selected,
              minSize: height,
              onTap: onTap,
              child: ExcludeSemantics(child: row),
            ),
    );
  }
}
