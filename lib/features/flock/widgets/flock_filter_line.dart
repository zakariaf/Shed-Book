// lib/features/flock/widgets/flock_filter_line.dart
//
// `indelible.md §8` Screen 1: printed words with their counts after them — never
// chips, because *"a chip is a container with a radius, and this system has
// neither"*. Words, never icons — there is no icon set and every action is a
// word (§1.3).
//
// **IT WRAPS ONTO RULED LINES; IT DOES NOT SCROLL SIDEWAYS.** §8's own caption
// gives the reason in one sentence: *"a horizontally scrolling strip needs a
// swipe and swipe is banned at 3am."* The line shipped as a horizontal
// `ListView` and clipped mid-word — seen on a simulator on 2026-08-07 reading
// `IN TH…` — so two of the five filters were behind a gesture this app does not
// have. `mockups/indelible.html` builds it as one ruled row whose record column
// holds a wrapping word line, and that is what this is now.
//
// **R86: EXACTLY 0 OR AT LEAST 16.** `spacing: gapMin` between words on a run,
// `runSpacing: 0` between runs, so the words either touch or clear a thumb —
// there is nothing in between, which is the whole of the ruling.
//
// **SELECTED IS AN UNDERLINE, NOT A COLOUR** (`indelible.md §7.13`): a 2px
// `--ink-full` rule under the chosen word while its siblings sit at `--ink-mid`.
// Rule 3 — meaning is carried by form first, hue never alone — so this reads
// fully desaturated, which is the monochrome acceptance test.
//
// **THE LINE IS IN THE REACH BAND AND NOTHING IN IT IS REQUIRED** (`§4.5`).
// Filtering is a daylight act; the shed path never needs it.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
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

    // **A RULED ROW WITH AN EMPTY MARGIN CELL.** The filters are not a record,
    // so nothing prints in the gutter — but the gutter is still reserved, which
    // is what keeps the spine straight past this row instead of the page opening
    // with a jog in it.
    return ShedRuledRow(
      child: Wrap(
        spacing: t.gapMin,
        // **0, NOT A GAP** (`§7.3`, R86). Two runs of words share an edge exactly
        // as two rows do; a 4 pt or 8 pt run gap is the one separation the tap
        // ruling forbids, because a 9 mm contact patch centred on it resolves to
        // neither word.
        runSpacing: 0,
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
  }) =>
      // **NO PADDING AROUND THE TARGET.** The `Wrap` owns the separation now, and
      // a padded target inside a spaced `Wrap` is 16 + 16 between two words on
      // one run and 16 between the runs — two different gaps for one rule.
      //
      // **`IntrinsicWidth`, AND WITHOUT IT THE LINE IS NOT A LINE.** Measured:
      // six full-width stacked rows, 360 pt tall, filling the page — because
      // `ShedTapTarget` wraps its child in `Center` and `Center` expands to the
      // maximum width offered, so each word claimed a whole run of the `Wrap`.
      // The identical bug was fixed in `ShedWordButton` at P16 and this is the
      // one target in the app that does not go through it.
      IntrinsicWidth(
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
