// lib/features/flock/widgets/flock_filter_line.dart
//
// `indelible.md §8` Screen 1: *"a single horizontally scrolling 64px ruled line
// of words with counts printed after them"*. Words, never icons — this system
// has no icon set and every action is a word (§1.3).
//
// **SELECTED IS AN UNDERLINE, NOT A COLOUR** (`indelible.md §7.13`): a 2px
// `--ink-full` rule under the chosen word while its siblings sit at `--ink-mid`.
// Rule 3 — meaning is carried by form first, hue never alone — so this reads
// fully desaturated, which is the monochrome acceptance test.
//
// **THE LINE IS IN THE REACH BAND AND NOTHING IN IT IS REQUIRED** (`§4.5`).
// Filtering is a daylight act; the shed path never needs it, and a horizontal
// scroll is legal here only because no action hides behind it — every filter is
// also reachable by scrolling, and none of them is the only way to do anything.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class FlockFilterLine extends StatelessWidget {
  const FlockFilterLine({
    required this.filters,
    required this.counts,
    required this.total,
    required this.onToggle,
    required this.onClear,
    super.key,
  });

  final FlockFilters filters;

  /// How many ewes each filter would leave. **Printed after the word**, because
  /// a filter that turns out to be empty is worth knowing before the tap rather
  /// than after it.
  ///
  /// **A RECORD, NOT A MAP, AND THE GATE IS WHY.** A map lookup is nullable, so
  /// the call site reached for a zero coalesce — and `stat.zero_default2` failed
  /// the build on it, correctly: a missing count is *not computed*, never *no
  /// ewes match* (#58). A record has all five fields or does not compile.
  final FlockFilterCounts counts;

  /// Null while the list is still loading. **Not zero** — `ALL 0` printed against
  /// a 400-ewe flock is a lie that lasts one frame and is the one frame a
  /// shepherd sees on a cold open.
  final int? total;
  final ValueChanged<FlockFilter> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SizedBox(
      height: t.tapMin,
      child: ListView(
        // **THE ONE PERMITTED TRACKED GESTURE IS SCROLLING** (`06 §7`), and this
        // is the horizontal case Indelible explicitly allows for this line. No
        // action is reachable ONLY behind it: `ALL` sits first and clearing is
        // always one tap on a word that is always on screen.
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: t.gapMin),
        children: <Widget>[
          _word(
            context,
            l10n,
            t,
            label: total == null ? l10n.flockFilterAllUnknown : l10n.flockFilterAll(count: total!),
            selected: filters.isEmpty,
            widgetKey: const Key('flock.filter.all'),
            onTap: onClear,
          ),
          for (final FlockFilter f in FlockFilter.values)
            _word(
              context,
              l10n,
              t,
              label: _labelFor(l10n, f, counts),
              selected: filters.has(f),
              widgetKey: Key('flock.filter.${f.key}'),
              onTap: () => onToggle(f),
            ),
        ],
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, FlockFilter f, FlockFilterCounts c) => switch (f) {
    FlockFilter.notYetLambed => l10n.flockFilterNotYetLambed(count: c.notYetLambed),
    FlockFilter.currentlyPenned => l10n.flockFilterCurrentlyPenned(count: c.currentlyPenned),
    FlockFilter.underTreatment => l10n.flockFilterUnderTreatment(count: c.underTreatment),
    FlockFilter.tripletBearing => l10n.flockFilterTripletBearing(count: c.tripletBearing),
    FlockFilter.barren => l10n.flockFilterBarren(count: c.barren),
  };

  Widget _word(
    BuildContext context,
    AppLocalizations l10n,
    ShedTokens t, {
    required String label,
    required bool selected,
    required Key widgetKey,
    required VoidCallback onTap,
  }) => Padding(
    padding: EdgeInsets.only(right: t.gapMin),
    child: ShedTapTarget(
      key: widgetKey,
      // **STATE GOES IN `selected:`, NEVER IN THE LABEL** (`10 §3.2` rule 2).
      // "Barren, selected" spoken as one string is a label that no longer
      // matches the visible text, which is rule 3 of the same section.
      semanticLabel: label,
      selected: selected,
      minSize: t.tapMin,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          decoration: BoxDecoration(
            // **ABSENT, NOT TRANSPARENT.** The first draft painted a transparent
            // Material rule under every unselected word, and
            // `token.material_color` failed the build — rightly: every colour in
            // this app comes from `ShedTokens`, and there is no transparent token
            // because a rule that is not there is not a colour at all. The 2px
            // rule never scales either; it is a mark, not type (`§3.6`).
            border: selected
                ? Border(
                    bottom: BorderSide(color: t.textPrimary, width: t.outlineWidth),
                  )
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: selected ? t.textPrimary : t.textSecondary),
            maxLines: 1,
          ),
        ),
      ),
    ),
  );
}
