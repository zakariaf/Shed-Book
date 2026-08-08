// lib/core/ui/components/shed_animal_row.dart
//
// **§7.4's EWE ROW, NOW BUILT FROM §7.3's RULED ROW.**
//
// It drew its own bottom rule, its own padding and its own left edge at 16 px,
// so it was a row that looked like the ledger's without being one: no margin
// cell, no gutter, and the spine — painted at x=68 behind the page — ran
// straight through the middle of the tag column. Measured against the running
// app on 2026-08-07: the flock list was the only place in the product where the
// spine crossed a numeral.
//
// The second half of the same defect: the summary sat BESIDE the tag, on one
// line. `§7.4` puts it *"beneath"*, and `mockups/indelible.html` builds the row
// as `mg | rec( line(tag, trail) , summary )` — the trailing state on the tag's
// line, the summary spanning the whole record column under it. That is what
// makes an 88 px row worth 88 px.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// indelible.md §4.4's two ruled heights, **expressed as tokens rather than as
/// 64 and 88**.
///
/// The document prints pixel numbers; this enum names the two rows so the
/// numbers stay in `ShedTokens` — where a palette can shift them and where the
/// 60 pt contract is asserted — rather than being retyped into a widget.
enum ShedAnimalRowHeight { standard, tall }

/// One ruled row: tag, summary, and an optional right-hand cell.
///
/// **The row reads no clock.** The trailing cell renders a *string* — `31h`,
/// `9d`, `12 Mar` — that the caller formatted through `formatters.dart` from a
/// `Duration` it computed with `now` passed in (R24). If this file ever imports
/// `lib/core/time/`, layer rule 7 has been broken.
final class ShedAnimalRow extends StatelessWidget {
  const ShedAnimalRow({
    required this.tag,
    this.warning = false,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
    super.key,
    this.margin,
    this.trailing,
    this.height = ShedAnimalRowHeight.tall,
    this.selected = false,
  });

  /// `displaySmall`, tabular, **right-aligned in its own fixed-width column** so
  /// that `412`, `128`, `77` and `9` all line up on their units digit
  /// (indelible.md §7.4). That alignment is the whole claim of the flock list —
  /// a shepherd scanning for 128 finds it by shape, not by reading.
  final String tag;

  /// `indelible.md §7.4`'s **Warning** state — over threshold, last withdrawal
  /// day, or a §12.4 contradiction. This draws the **doubled rule**, one of the
  /// state's four channels (the margin `†` is [margin]'s).
  ///
  /// **THE GAP IS THE MARK, AND A THICK RULE IS NOT A DOUBLED ONE.** A first
  /// draft drew a single 6 px border and called it doubled in a comment; a
  /// second restructured the row into a `Column` and broke four tests by moving
  /// every scroll offset on the page. This is a `Stack`, which takes its size
  /// from the unpositioned child — so the 88 px in `§4.4`'s table cannot move,
  /// which is what both earlier attempts got wrong.
  final bool warning;

  /// The 68 pt margin cell (`§4.3`): a `†`, a query mark, a struck stamp. `null`
  /// leaves the gutter **reserved and empty**, which is what keeps the tag column
  /// on the same x on every row whether or not the animal is marked — the
  /// alignment §7.4 exists for.
  final Widget? margin;

  /// **One line.** `07 §4.2`: *"3 seasons · avg 2.0 · assisted twice"*. Composed
  /// by the screen from its own query, never assembled here.
  final String summary;

  /// The right-hand cell: a status word, a figure, or nothing. A `Widget` rather
  /// than a `String` because it is usually a `ShedStatusBadge`.
  ///
  /// **It sits on the TAG's line, not beside the whole row**, so the summary
  /// beneath gets the full record column rather than being squeezed by a word it
  /// is not next to (`mockups/indelible.html`, screen 1).
  final Widget? trailing;

  final String semanticLabel;
  final VoidCallback onTap;
  final ShedAnimalRowHeight height;

  /// Selection is carried by a **mark and a weight**, never by colour alone
  /// (decision #106, WCAG 1.4.1 Level A).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    final double rowHeight = switch (height) {
      ShedAnimalRowHeight.standard => t.tapPrimary,
      ShedAnimalRowHeight.tall => t.tapHero,
    };

    // The tag column's width comes from the SCALED numeral, exactly as 10 §3.5
    // does it for the pen board. indelible.md §4.3 prints "76px fixed (3 tabular
    // digits at 32px)" — 76 is that measurement at scale 1.0, and hard-coding it
    // makes a four-digit tag at 200% overflow. Measuring three digits in the
    // real style keeps the column honest at every scale.
    final TextPainter probe = TextPainter(
      text: TextSpan(text: '000', style: text.headlineLarge),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double tagColumn = probe.width;

    final Widget row = ShedRuledRow(
      height: rowHeight,
      onTap: onTap,
      semanticLabel: semanticLabel,
      // CENTRED, NOT STRETCHED. `ShedRuledRow` stretches its cells to the row
      // height so a margin rule can run the full 88 px; a `†` and a boxed stamp
      // are marks, and a stamp stretched to 88 px is a box around nothing.
      margin: margin == null ? null : Center(child: margin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: tagColumn,
                child: Text(
                  tag,
                  // RIGHT-aligned: the units digit is what aligns, not the
                  // first digit.
                  textAlign: TextAlign.right,
                  style: text.headlineLarge,
                  maxLines: 1,
                ),
              ),
              // **A `Spacer`, WHICH IS `Expanded` AND THEREFORE TIGHT.** A
              // `Flexible` here would take its share of the free space and give
              // the rest back, leaving the trailing cell floating short of the
              // right edge — the one place on this row where "nearly right"
              // reads as a bug.
              const Spacer(),
              if (trailing case final Widget w) w,
            ],
          ),
          Text(
            summary,
            // §7.4: 18 px `--ink-mid` (7.80:1). The tag is the identifier and
            // carries full ink; the summary is what she did, one step back.
            style: text.bodyMedium?.copyWith(
              color: t.textSecondary,
              // The non-colour channel for selection: the summary carries
              // an underline when the row is selected, so the state
              // survives a reader who cannot tell the inks apart.
              decoration: selected ? TextDecoration.underline : TextDecoration.none,
              fontWeight: selected ? FontWeight.w700 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!warning) {
      return row;
    }

    return Stack(
      children: <Widget>[
        row,
        // The INNER rule of the pair, floated above the content. The outer
        // one is the row's own bottom border; the gap between them is
        // `--rule-double-gap`, and it is the thing that reads as *a
        // boundary, a threshold crossed* from across the shed.
        Positioned(
          left: 0,
          right: 0,
          bottom: t.outlineWidth * 2,
          child: SizedBox(
            height: t.outlineWidth,
            child: ColoredBox(color: t.outline),
          ),
        ),
      ],
    );
  }
}
