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
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
// `AppSetting` arrives through `lib/data/models.dart` — `layer.features` forbids
// a feature importing `lib/core/db/`, and the re-export is the seam that exists
// so a screen never has to know a database does.
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/features/flock/widgets/add_ewe_sheet.dart';
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

    // **REGISTERED UNCONDITIONALLY, AT THE TOP OF `build`** (`02 §4.3`).
    // `ref.listen` inside an `if` is a listener that exists on some frames and
    // not others, so the outcome of a write started on one frame lands on a
    // frame that is not listening.
    ref.listen<WriteState>(flockWriteControllerProvider, (WriteState? _, WriteState next) {
      if (next case WriteDone(outcome: final WriteOutcome outcome)) {
        // NO `default:`. `WriteOutcome` is sealed with three variants
        // (`CONVENTIONS §2.4`); the day a fourth appears this must fail to
        // compile rather than swallow it.
        switch (outcome) {
          case WriteCommitted():
            // **P2: THE CONFIRMATION IS THE COMMITTED ROW.** The new ewe appears
            // in the list because `watchFlockList` declares `ewes` in
            // `readsFrom` — there is nothing to announce and nothing to dismiss.
            break;
          case WriteFailed(failure: final ShedFailure failure):
            showFailure(context, failure.userMessage);
          case WriteRefused(reason: final RefusalReason reason):
            // **A ROW, NEVER A DIALOG, AND NEVER A NAVIGATION** (#92,
            // `07 §19.2`). `07 §3.3` also says the over-cap create *"navigates
            // to Unlock"* — that half cannot land here: Unlock is a **Settings
            // section**, not one of the thirteen `RouteNames`, and Settings is
            // N29. `showCapRow` has its two guards today and its pixels at
            // N30-T05.
            //
            // `onShedScreen: false` because Flock is not one of the five. It is
            // stated rather than assumed: the guard lives in `showCapRow` so
            // that the thirteenth call site cannot forget it.
            showCapRow(context, reason, onShedScreen: false);
        }
      }
    });

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        // **THE SLAB IS A FIXED LAYER, NOT A LIST CHILD.** `indelible.md §7.1`
        // puts it in the corner and §4.5 puts it in the thumb band, 0–320 px
        // from the bottom — an affordance that scrolls away is an affordance
        // that is not in the thumb band on most frames.
        child: Stack(
          children: <Widget>[
            Column(
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
            // **MIRRORED BY `app_settings.left_handed`, WHICH IS READ AND NEVER
            // RE-DERIVED** (R40). Exactly three things move — the slab, `INDEX`
            // and the keypad's bottom row — and the spine, the margin cell and
            // the record column do not.
            Positioned(
              bottom: t.gapMin,
              right: _leftHanded(ref) ? null : t.gapMin,
              left: _leftHanded(ref) ? t.gapMin : null,
              child: _addSlab(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// `app_settings.left_handed`. **Absent settings are right-handed**, which is
  /// the column's own `withDefault(false)` rather than a guess made here.
  bool _leftHanded(WidgetRef ref) => switch (ref.watch(settingsProvider)) {
    AsyncData<AppSetting>(value: final AppSetting s) => s.leftHanded,
    _ => false,
  };

  /// `+ EWE` — `indelible.md §7.1`'s corner slab, the largest target in the app.
  ///
  /// It opens the one overlay this app has. It does **not** write: the sheet's
  /// confirm bar does, through the same `createEwe` verb Quick Entry calls, with
  /// `EntryContext.calm` — the one context in which the cap may honestly refuse,
  /// because this is daylight work and nobody is holding a lamb.
  Widget _addSlab(BuildContext context, AppLocalizations l10n) {
    return ShedCornerSlab(
      key: const Key('flock.add_slab'),
      label: l10n.flockAddSlab(term: l10n.termEweSingular.toUpperCase()),
      semanticLabel: l10n.flockAddSlab(term: l10n.termEweSingular.toUpperCase()),
      onTap: () => showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.flockAddClose,
        dismissSemanticLabel: l10n.flockAddCloseHint,
        barrierLabel: l10n.flockAddHeading(term: l10n.termEweSingular),
        fillsViewport: true,
        child: AddEweSheet(
          // N27 pushes the ewe card from here. There is no route helper for a
          // screen that does not exist yet (critique S2), and a `TODO` in a
          // callback is a screen nobody wires.
          onOpenExisting: (EweId _) => Navigator.of(context).pop(),
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
          // **ONE EXTRA ITEM FOR THE DIVIDER**, and only when there is something
          // below it to divide. `indelible.md §7.4`: the removed ewes sit *"at
          // the bottom, under a printed line reading `STRUCK — 1`."*
          itemCount: list.length + (list.any((FlockRow r) => r.removedFromFlock) ? 1 : 0),
          itemBuilder: (BuildContext context, int i) {
            final int firstRemoved = list.indexWhere((FlockRow r) => r.removedFromFlock);
            if (firstRemoved >= 0 && i == firstRemoved) {
              return _struckDivider(context, l10n, list.length - firstRemoved);
            }
            return _row(context, l10n, list[firstRemoved >= 0 && i > firstRemoved ? i - 1 : i]);
          },
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

  /// `STRUCK — n`, the printed line the removed ewes sit under (`§7.4`).
  ///
  /// **A DOUBLED RULE, WHICH IS THE MARK FOR EXACTLY THIS.** `--rule-double-gap`
  /// means *a total, a boundary, a threshold crossed*, and this is a boundary —
  /// between the flock and the animals who have left it. It is readable in
  /// peripheral vision from across the shed, which is the property the doubled
  /// rule exists for; a single rule would read as one more row boundary among
  /// four hundred.
  ///
  /// **NOT A TARGET AND NOT A HEADER.** Nothing collapses, nothing filters,
  /// nothing hides behind it — it is a printed line, so it carries no
  /// `ShedTapTarget` and cannot fail a tap-target gate for being under 60 pt.
  Widget _struckDivider(BuildContext context, AppLocalizations l10n, int count) {
    final ShedTokens t = context.tokens;
    return Padding(
      key: const Key('flock.struck_divider'),
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Two 2px rules with a gap between them. Rules never scale with text —
          // a rule is a mark, not type (`§3.6`).
          _rule(t),
          SizedBox(height: t.outlineWidth),
          _rule(t),
          SizedBox(height: t.gapMin),
          Text(
            l10n.flockStruckDivider(count: count),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _rule(ShedTokens t) => SizedBox(
    height: t.outlineWidth,
    child: ColoredBox(color: t.outline),
  );

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
    // §7.4's Warning state: the doubled rule is the channel that survives
    // grayscale, the `QUERIED` stamp is the word. Two channels, neither colour.
    warning: r.hasWarning && !r.removedFromFlock,
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
