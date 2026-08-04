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
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/features/flock/widgets/flock_filter_line.dart';
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
        child: Column(
          children: <Widget>[
            // **THE LINE PRINTS ITS COUNTS OR RESERVES ITS HEIGHT.** Never a
            // count of 0 for a filter whose statement has not returned — that is
            // #58 in the one place a shepherd would act on it, by not tapping a
            // filter that looks empty and is not.
            switch (ref.watch(flockFilterCountsProvider)) {
              final FlockFilterCounts counts => FlockFilterLine(
                filters: filters,
                counts: counts,
                total: switch (rows) {
                  AsyncData<List<FlockRow>>(value: final List<FlockRow> l) => l.length,
                  _ => null,
                },
                onToggle: (FlockFilter f) => ref.read(flockFilterProvider.notifier).toggle(f),
                onClear: () => ref.read(flockFilterProvider.notifier).clear(),
              ),
              // The grid does not move while it waits (`indelible.md §3.6`).
              null => SizedBox(height: t.tapMin),
            },
            Expanded(child: _body(context, l10n, filters, rows)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    FlockFilters filters,
    AsyncValue<List<FlockRow>> rows,
  ) {
    return SizedBox.expand(
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
    );
  }

  /// The row's trailing mark, or nothing.
  ///
  /// **REMOVED-FROM-FLOCK WINS OVER THE WARNING**, and only one prints. She left
  /// the flock; a contradiction in the records of an animal who is gone is a
  /// smaller fact than her being gone, and two stamps in an 88 px row is the
  /// clutter `indelible.md §6.3`'s six-mark budget exists to refuse.
  Widget? _mark(BuildContext context, AppLocalizations l10n, FlockRow r) {
    if (r.removedFromFlock) {
      return ShedStatusBadge(stamp: ShedStamp.culled, label: l10n.flockStampCulled);
    }
    if (r.hasWarning) {
      return ShedStatusBadge(stamp: ShedStamp.queried, label: l10n.flockStampQueried);
    }
    return null;
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
    // **§12.4's BADGE IS A WORD, AND `07 §3.4` SAYS "icon + count".** There is no
    // icon set in this system — *"every action is a word"* (`indelible.md §1.3`),
    // and `ShedStatusBadge` is *"a stamp set in words, not an icon-plus-word"*
    // (`06 §12`). CLAUDE.md's authority order puts the design above the thirteen
    // engineering documents, so the word wins and `07 §3.4` is amended in this
    // commit. Ruling **N3**.
    //
    // Two non-colour channels, as every state must have (`§1.2` rule 3): the
    // WORD, and the FORM — `QUERIED` is unboxed because it is a note about the
    // writing, `CULLED` is boxed because it is a state of the sheep. Turn on the
    // grayscale filter and both still read.
    //
    // **PERSISTENT, WHICH IS THE WHOLE POINT** — *"a contradiction found at 3am
    // is still findable at 9am."* It is not a transient, not a toast, and
    // nothing dismisses it.
    trailing: _mark(context, l10n, r),
    semanticLabel: l10n.flockRowLabel(tag: r.tag),
    onTap: () {},
  );
}
