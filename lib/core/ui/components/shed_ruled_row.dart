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
//
// ---------------------------------------------------------------------------
// THE FIRST DRAFT OF THIS FILE CRASHED EVERY SCREEN THAT ADOPTED IT
// ---------------------------------------------------------------------------
//
// It used `CrossAxisAlignment.stretch` with no height bound. Inside `ShedPage`'s
// scrolling stream the incoming max height is **infinite**, and `stretch` hands
// that straight down as a tight constraint: *"BoxConstraints forces an infinite
// height"*, then a cascade of `hasSize` assertions, then a page that painted
// nothing at all.
//
// **Four independent rebuilds found it and four proposed the same fix**, which is
// as close to a specification as this project gets: keep the stretch — it is what
// makes the 68 pt margin cell the full height of its row, which is `§4.3`'s
// 68 × 64 target — and bound it with `IntrinsicHeight` so there is a finite
// number to stretch to. It costs one extra layout pass on a handful of rows per
// screen. Dropping to `center` was the other candidate and it is worse: the
// margin cell stops being a full-height cell and `§4.3`'s target goes with it.
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
    this.onTapHint,
    this.height = kRuledRowHeight,
    this.selected,
    this.struck = false,
    this.doubled = false,
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

  /// What the tap DOES, for a screen reader, where the label alone is a noun.
  final String? onTapHint;

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

  /// `§5`'s **doubled rule**: a total, a boundary, a threshold crossed.
  ///
  /// Two 2 px lines **3 px apart**, and the 3 px is the spec's own figure rather
  /// than a rounding of it — the gap is what makes the pair read as one heavier
  /// mark in peripheral vision from across the shed, which is the whole job.
  ///
  /// **Painted as a `Positioned` layer, never as a second child in a column**, so
  /// `§4.4`'s row heights cannot move: a threshold row must sit on exactly the
  /// same grid as the rows around it or the board stops scanning.
  final bool doubled;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    final Widget row = Padding(
      padding: EdgeInsets.only(right: t.gapMin),
      // See this file's header: `stretch` without a bound is an infinite-height
      // crash inside a scroll view, and dropping the stretch costs `§4.3`'s
      // full-height margin cell.
      child: IntrinsicHeight(
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
      ),
    );

    // **THE RULE, AS A DECORATION AROUND THE ROW.**
    Widget ruled(Widget inner) => DecoratedBox(
      // **KEYED, BECAUSE A RULE IS A CHANNEL AND A CHANNEL MUST BE ASSERTABLE.**
      // `10 §5.2`'s redundancy table asserts that every pen row carries a rule
      // beneath it — *"the channel that survives when the word is truncated and
      // the glyph is absent"*. That used to be `pen_tile.rule`, a painter inside
      // the tile; the tile is a `ShedRuledRow` now and the rule is this one, so
      // the assertion moves here rather than lapsing.
      key: const Key('shed_ruled_row.rule'),
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
      child: doubled
          ? Stack(
              children: <Widget>[
                inner,
                Positioned(
                  left: 0,
                  right: 0,
                  // 2 px rule + a 3 px gap, measured up from the row's own rule.
                  bottom: t.outlineWidth + kDoubledRuleGap,
                  child: SizedBox(
                    // **KEYED, BECAUSE THE MARK IS WHAT THE GATE ASSERTS.** The
                    // pen board's non-colour-channel test finds this line to
                    // prove an over-threshold row carries a second channel; a
                    // painted rule with no key can only be checked by a golden,
                    // which is a PNG rather than a statement about the design.
                    key: const Key('shed_ruled_row.doubled'),
                    height: t.outlineWidth,
                    child: ColoredBox(color: t.outline),
                  ),
                ),
              ],
            )
          : inner,
    );

    if (onTap == null) {
      // **NOT WRAPPED IN A TARGET WHEN IT IS NOT ONE.** A `GestureDetector` with
      // a null handler still contributes a semantics node the geometric gate
      // then measures, and a read-only row measured as a target is how a 60 pt
      // floor gets a false negative.
      return ruled(
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: row,
        ),
      );
    }

    // **THE TARGET IS THE OUTERMOST WIDGET, AND THAT IS A MEASURED FIX.**
    //
    // With the `DecoratedBox` outside, `ShedRuledRow`'s element resolved to a
    // `RenderDecoratedBox` — which owns no semantics — so
    // `tester.getSemantics(find.byKey(...))` walked PAST this row to whatever
    // node enclosed it and came back with an empty label. Five assertions across
    // the care lines and the provenance header failed on it, and every one of
    // them was asserting something true.
    //
    // The first fix tried was to move the `DecoratedBox` inside `ShedTapTarget`.
    // That put the row's rule inside the target's `Center`, so on every tappable
    // row the ruling stopped at the content instead of running the width of the
    // page — the ledger came apart exactly where it is most used.
    //
    // Both hold this way round: the keyed element owns the semantics node, and
    // the explicit infinite width defeats the `Center` so the rule still spans
    // the page.
    return ShedTapTarget(
      semanticLabel: semanticLabel ?? '',
      onTapHint: onTapHint,
      selected: selected,
      minSize: height,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SizedBox(width: double.infinity, child: ruled(row)),
      ),
    );
  }
}

/// `--rule-double-gap`: 3 px between the two lines of a doubled rule (`§5`).
const double kDoubledRuleGap = 3;
