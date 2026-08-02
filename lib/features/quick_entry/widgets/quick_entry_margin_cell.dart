// lib/features/quick_entry/widgets/quick_entry_margin_cell.dart
//
// The 68 x 64 margin cell: the auto-captured time, the AUTO stamp, and space for
// the dagger and query marks a later epic adds.
//
// IT IS A LEGAL TAP TARGET (indelible.md §4.3) — 68 x 64 clears the 60 floor on
// both axes. That matters because the margin is where a time is CORRECTED, and a
// margin you cannot press is a margin that sends the shepherd hunting for an
// edit affordance somewhere else on the page.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

class QuickEntryMarginCell extends StatelessWidget {
  const QuickEntryMarginCell({
    required this.time,
    required this.stampAuto,
    required this.width,
    required this.height,
    super.key,
  });

  /// Pre-formatted, 24-hour, from `formatShedTime`.
  final String time;

  /// `AUTO` — four characters, all-caps, and it sits beside a time that is
  /// obviously the current time, so it is never the sole carrier of its meaning.
  /// That is what keeps indelible §3.4's stamp exemption valid here, and safety
  /// rule §12.5 is what makes the stamp mandatory.
  final String stampAuto;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    // A MINIMUM, NOT A FIXED HEIGHT, AND TEXT SCALE IS WHY. MEASURED: two lines
    // at the record and stamp roles come to ~50 pt at scale 1.0 and overflow the
    // 64 pt cell by 2 at scale 1.3. indelible §4.3's 68 x 64 is the FLOOR that
    // makes the margin a legal tap target — a cell that clipped its own stamp to
    // hold that number would be trading §12.5's provenance label for a geometry
    // the same section only ever stated as a minimum.
    return ConstrainedBox(
      key: const Key('quick_entry.margin_cell'),
      constraints: BoxConstraints(minWidth: width, minHeight: height),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(time, style: Theme.of(context).textTheme.bodySmall, maxLines: 1),
            Text(stampAuto, style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
