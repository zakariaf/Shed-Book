// lib/core/ui/components/shed_animal_row.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
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
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
    super.key,
    this.trailing,
    this.height = ShedAnimalRowHeight.tall,
    this.selected = false,
  });

  /// `displaySmall`, tabular, **right-aligned in its own fixed-width column** so
  /// that `412`, `128`, `77` and `9` all line up on their units digit
  /// (indelible.md §7.4). That alignment is the whole claim of the flock list —
  /// a shepherd scanning for 128 finds it by shape, not by reading.
  final String tag;

  /// **One line.** `07 §4.2`: *"3 seasons · avg 2.0 · assisted twice"*. Composed
  /// by the screen from its own query, never assembled here.
  final String summary;

  /// The right-hand cell: a status word, a figure, or nothing. A `Widget` rather
  /// than a `String` because it is usually a `ShedStatusBadge`.
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

    return ShedTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      minSize: rowHeight,
      child: DecoratedBox(
        // ONE RULE, AT THE BOTTOM. Two rules per row is indelible.md §7.4's
        // warning state and must never be the default — a list where every row
        // is boxed reads as a list where every row needs attention.
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: t.outline, width: t.outlineWidth),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Row(
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
              SizedBox(width: t.gapMin),
              Expanded(
                child: Text(
                  summary,
                  style: text.bodyMedium?.copyWith(
                    // The non-colour channel for selection: the summary carries
                    // an underline when the row is selected, so the state
                    // survives a reader who cannot tell the inks apart.
                    decoration: selected ? TextDecoration.underline : TextDecoration.none,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                  maxLines: 1,
                ),
              ),
              if (trailing != null) ...<Widget>[SizedBox(width: t.gapMin), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
