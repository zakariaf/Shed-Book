// lib/features/flock/flock_screen.dart — `indelible.md §8` Screen 1.
//
// **THE SAME DOCUMENT UNDER A DIFFERENT FILTER.** One spine, one header, 88 px
// ewe rows. There is no second structure here and there is nothing to invent:
// what changes between this screen and Quick Entry is what the filter lets
// through.
//
// T01 lands the list and its states. The five filter controls are T02, the row's
// badges and culled-tag mark are T03, and `+ EWE` is T04 — each in its own
// commit, because a screen that arrives whole is a screen nobody reviewed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class FlockScreen extends ConsumerWidget {
  const FlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FlockFilters filters = ref.watch(flockFilterProvider);
    final AsyncValue<List<FlockRow>> rows = ref.watch(flockListProvider(filters));

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        // **EVERY ARM `02 §4.5` NAMES IS WRITTEN OUT**, in the order the screen
        // meets them. The trailing `_` is loading and Dart's exhaustiveness
        // requirement in one — `AsyncValue`'s sealed hierarchy is not closed over
        // the refreshing/reloading combinations, so the analyser rejects the
        // switch without it. `in_pens_strip.dart` reads the same way for the same
        // reason; it is not a catch-all for states nobody considered.
        child: switch (rows) {
          AsyncData<List<FlockRow>>(value: final List<FlockRow> list) when list.isEmpty =>
            ShedEmptyState(
              key: const Key('flock.empty'),
              // FILTERED-EMPTY IS ITS OWN STATE (`07 §3.2`). "No animals yet"
              // shown to somebody with 400 ewes and a filter on is the app
              // telling them their flock is gone.
              copy: filters.isEmpty ? l10n.flockEmpty : l10n.flockFilteredEmpty,
            ),
          AsyncData<List<FlockRow>>(value: final List<FlockRow> list) => ListView.builder(
            key: const Key('flock.list'),
            padding: EdgeInsets.zero,
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) => _row(context, l10n, list[i]),
          ),
          AsyncError<List<FlockRow>>() => ShedEmptyState(
            key: const Key('flock.error'),
            copy: l10n.flockUnavailable,
          ),
          // **NEVER A SPINNER** (decision #71, `02 §4.5`). `07 §3.2`'s frame 1 is
          // six fixed-height dark placeholders, which is what a ruled page looks
          // like before the ink lands — T03 draws them; until then the page
          // colour is the honest first frame and not a lie about progress.
          _ => const SizedBox.expand(),
        },
      ),
    );
  }

  /// Empty unless BOTH counts are real.
  String _summary(AppLocalizations l10n, FlockRow r) {
    final int? seasons = r.seasonsRecorded;
    final int? lambings = r.lambingsRecorded;
    if (seasons == null || lambings == null) {
      return '';
    }
    return l10n.flockRowSummary(seasons: seasons, lambings: lambings);
  }

  Widget _row(BuildContext context, AppLocalizations l10n, FlockRow r) => ShedAnimalRow(
    // KEYED ON THE EWE ID, never the tag and never the index: a tag is "exactly
    // as typed" and may carry letters or leading zeros, which breaks the
    // all-lower_snake key format (R59), and an index reorders under a filter.
    key: Key('flock.row.${r.id.value}'),
    tag: r.tag,
    // **ASSEMBLED IN DART FROM COUNTS** (`03 §5.13`), and only from the ones the
    // statement actually returned.
    //
    // **A NULL COUNT IS *NOT COMPUTED*, NEVER ZERO** (decision #58).
    // `ewe_summaries` is a LEFT JOIN, so a ewe whose history has not been rolled
    // up yet returns NULL — and `0 seasons` printed against a six-year-old ewe is
    // the app inventing a fact about her.
    //
    // The first draft of this line coalesced the second count with the very
    // operator the paragraph above forbids, and `stat.zero_default2` failed the
    // build on it. Sixteenth time this project has caught a prohibition inside
    // the comment that states it. Both counts are now required together, because
    // a summary built from one real number and one invented one is worse than no
    // summary.
    summary: _summary(l10n, r),
    height: ShedAnimalRowHeight.tall,
    semanticLabel: l10n.flockRowLabel(tag: r.tag),
    onTap: () {},
  );
}
