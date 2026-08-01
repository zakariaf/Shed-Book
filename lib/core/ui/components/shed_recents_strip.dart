// lib/core/ui/components/shed_recents_strip.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One entry, **already formatted**.
///
/// indelible.md §7.15: `412 · penned 2h · twin last year` — a tag in the record
/// voice and a summary in the control voice. Both arrive as strings: `2h` is a
/// `Duration` the CALLER turned into text through `formatters.dart`, because a
/// component in `lib/core/ui/` reads no clock and imports no provider (layer
/// rule 7). **If this file ever needs a `Duration`, the design is wrong.**
@immutable
final class ShedRecentsEntry {
  const ShedRecentsEntry({
    required this.tag,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
  });

  final String tag;
  final String summary;
  final String semanticLabel;
  final VoidCallback onTap;
}

/// The recents strip — one fixed height across all four states.
///
/// A strip that grows when it fills is a strip that moves the slab under a thumb
/// already in flight, which is why the height comes from `tapPrimary` and from
/// nothing else.
final class ShedRecentsStrip extends StatelessWidget {
  const ShedRecentsStrip({
    required this.entries,
    required this.emptyLabel,
    super.key,
    this.selectedTag,
    this.placeholderLabel = '',
  });

  /// **`null` is the placeholder state and `const []` is the empty state.**
  ///
  /// They are different facts and they render differently. Frame 1 has not read
  /// the database yet; an empty list means the database was read and there is
  /// nothing in it. Collapsing them is how a shepherd on day one is told the app
  /// lost their flock.
  final List<ShedRecentsEntry>? entries;

  /// `07 §2.2` — *"No recent animals."* Arrives localised.
  final String emptyLabel;

  /// Rendered while [entries] is null. Deliberately blank by default: frame 1
  /// says nothing rather than guessing.
  final String placeholderLabel;

  final String? selectedTag;

  /// Spec §7.1. Held **in the layout**, not only in an `assert` — an assert is
  /// stripped in release, which is the build where nobody is watching.
  static const int maxEntries = 6;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final List<ShedRecentsEntry>? all = entries;

    return SizedBox(
      height: t.tapPrimary,
      child: switch (all) {
        null => Align(
          alignment: Alignment.centerLeft,
          child: Text(placeholderLabel, style: Theme.of(context).textTheme.bodyMedium),
        ),
        <ShedRecentsEntry>[] => Align(
          alignment: Alignment.centerLeft,
          child: Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium),
        ),
        // ONE LINE PER ENTRY, and horizontally scrollable.
        //
        // Both follow from the fixed height. indelible.md §7.15 renders an entry
        // as one line — `412 · penned 2h · twin last year` — and stacking the
        // tag over the summary was the first attempt: two lines of body text at
        // 200% is ~112 pt, which cannot fit `tapPrimary` and overflows. Decision
        // #99 forbids clamping the text, so the LAYOUT gives way, not the type.
        //
        // Scrolling for the same reason: at 200% one entry is wider than a third
        // of the screen, and six of them cannot share 800 pt. A strip that
        // scrolls is a strip that never overflows at any scale. Scrolling is not
        // one of the banned gestures — swipe ACTIONS are (CLAUDE.md); a list
        // that cannot be scrolled is a list whose sixth entry is unreachable.
        // SingleChildScrollView + Row, NOT ListView. A ListView is lazy: it
        // builds only the children that are visible, so at 200% only three of
        // the six entries exist in the tree at all — and a target that has not
        // been built is a target the N33 sweeps cannot measure and a screen
        // reader cannot reach by scanning. The strip is bounded at six by
        // maxEntries, so building all of them costs nothing.
        _ => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final ShedRecentsEntry e in all.take(maxEntries))
                Padding(
                  // gapMin between entries, so the strip never puts two targets
                  // 4 pt apart — which reads as one wide target to a cold thumb.
                  padding: EdgeInsets.only(right: t.gapMin),
                  child: ShedTapTarget(
                    onTap: e.onTap,
                    semanticLabel: e.semanticLabel,
                    minSize: t.tapPrimary,
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          // The tag in the record voice, the summary in the
                          // control voice — one line, two voices.
                          TextSpan(
                            text: e.tag,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: e.tag == selectedTag ? t.textPrimary : t.textNumeric,
                            ),
                          ),
                          TextSpan(
                            text: ' · ${e.summary}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}
