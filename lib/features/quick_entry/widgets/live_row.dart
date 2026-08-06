// lib/features/quick_entry/widgets/live_row.dart
//
// **THE PERSISTENT LOADED SUBJECT — THE ONE DESIGN IDEA THE DOCS CALL
// LOAD-BEARING, AND IT WAS NOT BUILT.**
//
// `docs/design/00-comparison.md §4.1` singles this out as the graft worth
// keeping: *the animal being written about is the largest object on the phone
// and survives a cold launch.* `indelible.md §8` draws it as the row welded
// 152 px above the bottom edge, directly under the last committed row, *"which
// is fully legible one line above it."*
//
// What shipped was a 128 px `SizedBox` holding a blank margin cell and, when a
// write had just landed, the strike affordance. The tag never printed. So the
// screen could not answer the question the shepherd asks every time they take
// the phone out of a pocket mid-lambing: **whose row is open?**
//
// **IT IS A QUERY, NOT RESTORED UI STATE.** The row commits at the first
// keystroke, so the strokes come from `tonightProvider` — the committed rows —
// rather than from a counter held in a widget. `RestorationMixin` and every
// `Restorable*` stay banned (decision #24); what survives a cold launch survives
// because it is in SQLite.
//
// **THE TAG CELL IS THE TARGET THAT OPENS THE SHEET** (`§8`: *"Tap the TAG
// cell. The sheet rises 160ms into the bottom half."*). Before P16 there was no
// such target, because the sheet was already open and covering this row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/core/ui/components/shed_margin_cell.dart';
import 'package:shed_book/features/quick_entry/widgets/tonight_rows.dart';

/// `indelible.md §4.4`: the live row is two lines, 128 px.
const double kLiveRowHeight = 128;

/// The open row: margin, tag, derived type, strokes.
///
/// **IT READS ITS OWN PROVIDERS**, exactly as `TonightRows` and `ExportBanner`
/// do, and that is structural rather than stylistic. `quick_entry_test.dart`
/// asserts the shell watches nothing — *"a StatelessWidget that watches nothing
/// cannot be rebuilt by a keystroke or by an emission"* (`02 §10.1`) — and that
/// is what makes every box on the screen immovable under a thumb.
///
/// The first draft had the page watch the controller and hand this widget a tag.
/// That assertion caught it on the first run, which is the assertion doing its
/// job: a `ref.watch` in the page is a channel through which a selection could
/// move the slab under a finger already travelling towards it.
final class LiveRow extends ConsumerWidget {
  const LiveRow({
    required this.time,
    required this.provenance,
    required this.tagPrompt,
    required this.tagCellSemanticLabel,
    required this.onTagCell,
    required this.derivedType,
    required this.derivedStamp,
    required this.marginWidth,
    super.key,
    this.trailing,
  });

  /// The auto-captured time, already formatted. **A widget never reads a clock**
  /// — the screen calls `appNow()` and hands the string down (R23, #46).
  final String time;

  /// §12.5's provenance label. The sole carrier of its claim on its line, so it
  /// renders at the 18 px floor and never as an exempt stamp.
  final String provenance;

  /// What the cell reads before a tag lands. `§8`: the slab reads `TAG FIRST`,
  /// and this cell is the thing that fixes that.
  final String tagPrompt;

  final String tagCellSemanticLabel;
  final VoidCallback onTagCell;

  /// `SINGLE` / `TWIN` / `TRIPLET` from a stroke count.
  ///
  /// **DERIVED, AND THERE IS NO CHOOSER** (P8). The type is a count of things
  /// that happened, labelled as counted — which is what turns safety rule §12.4
  /// from a validation routine into the structure of the interaction. The words
  /// come from the caller because `lib/features/` composes copy and this widget
  /// only places it.
  final String? Function(int strokes) derivedType;

  /// The word `COUNTED`, supplied rather than typed here.
  final String derivedStamp;

  final double marginWidth;

  /// The strike affordance, when a write has just landed.
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final QuickEntryState state = ref.watch(quickEntryControllerProvider);

    final String? tag = state.selected == null
        ? null
        : state.index
              .where((TagIndexEntry e) => e.eweId == state.selected)
              .map((TagIndexEntry e) => e.tag)
              .firstOrNull;

    // **THE STROKES COME OFF THE COMMITTED ROWS.** Not a counter in a widget and
    // not a field on the controller: the row IS the record, and anything else
    // would be a draft of it wearing a different name.
    final int strokes = state.openLambing == null
        ? 0
        : (ref.watch(tonightProvider).value ?? const <TonightRow>[])
                  .where((TonightRow r) => r.lambing == state.openLambing)
                  .firstOrNull
                  ?.lambCount ??
              0;

    return SizedBox(
      key: const Key('quick_entry.live_row'),
      height: kLiveRowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // **THE LIVE ROW'S BOTTOM RULE IS `--ink-full`, NOT `--rule`**
          // (`§7.3`'s state table). It is the one row on the page that is being
          // written into, and the heavier rule is how you find it without
          // reading anything.
          border: Border(
            bottom: BorderSide(color: t.textPrimary, width: t.outlineWidth),
          ),
        ),
        // **THE WHOLE ROW IS ONE TARGET, MARGIN INCLUDED** — the same shape
        // `TonightRows` already uses, and the reason is measured rather than
        // tidy. With the margin outside the target, the tag cell began at the
        // margin's right edge; `§3.6` grows that gutter with the text scale
        // (68 → 96 and beyond), so at textScaler 2.0 it reached x=118 while the
        // band's `INDEX` still ended at x=112. Six points of diagonal no-man's
        // land between two targets, under a thumb aiming at either — the
        // geometric gate's "too close" case, and it was right.
        //
        // Folding the margin in also makes the row a bigger target than the 128
        // it already was, which is the correct direction for the one control the
        // shepherd presses to say *which animal*.
        child: ShedTapTarget(
          key: const Key('quick_entry.live_row.tag_cell'),
          semanticLabel: tagCellSemanticLabel,
          minSize: t.tapIndelible,
          onTap: onTagCell,
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ShedMarginCell(
                  time: time,
                  stampAuto: provenance,
                  width: marginWidth,
                  height: kRecordRowHeight,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: t.gapMin / 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // **THE TAG AT `--t-tag-xl` 44 px, IN THE RECORD FACE.**
                        // It is the largest object on the phone by design: read
                        // at arm's length, through a head torch, one-handed.
                        Text(
                          tag ?? tagPrompt,
                          style: (tag == null ? text.headlineSmall : text.displayMedium)?.copyWith(
                            color: tag == null ? t.textSecondary : t.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (derivedType(strokes) case final String type)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  type,
                                  style: text.bodyLarge?.copyWith(color: t.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: t.gapMin / 2),
                              // Unboxed: a note about the RECORD, not a state of
                              // the animal (`§6`).
                              ShedStatusBadge(stamp: ShedStamp.counted, label: derivedStamp),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (strokes > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: t.gapMin),
                    child: ShedTally(count: strokes, semanticLabel: ''),
                  ),
                // **`Flexible`, BECAUSE A PLAIN Row CHILD IS UNBOUNDED.** The
                // strike affordance has an `Expanded` inside it — the summary
                // line that gives way to the strike word — and a non-flex child
                // of a `Row` is laid out with infinite width, which is the one
                // constraint an `Expanded` cannot satisfy. It threw on layout,
                // on the frame after the first committed write.
                if (trailing case final Widget w) Flexible(child: w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
