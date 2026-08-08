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
//
// ---------------------------------------------------------------------------
// R87 — IT WAS NEVER THE DOCUMENT (2026-08-07)
// ---------------------------------------------------------------------------
//
// Everything above was true of the DATA and false of the page. Measured against
// the running app: a bare `Stack` over a `Column`, no spine, no page header, no
// margin gutter, no thumb band. `§8`'s first claim is that twelve screens are one
// scrolling ruled document, and this screen was a second document that happened
// to contain ewes. `ShedPage` is the document; this file is now the filter.
//
// Four things changed shape and each has its reason at the call site: the page
// header (there was none), the filter line (it scrolled sideways and clipped
// mid-word, behind a gesture this app does not have), the row (the spine ran
// through the tag column and the summary sat beside the tag instead of beneath
// it), and the band (`INDEX` was missing and the slab floated over the last
// record row).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/components/shed_page.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/core/ui/formatters.dart';
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
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/features/flock/widgets/add_ewe_sheet.dart';
import 'package:shed_book/features/flock/widgets/flock_band.dart';
import 'package:shed_book/features/flock/widgets/flock_filter_line.dart';
import 'package:shed_book/features/flock/widgets/upgrade_row.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The band's geometry, from `indelible.md §4.4` at the 393 × 852 viewport.
///
/// **Named rather than typed inline**, exactly as `_Grid` does on Quick Entry:
/// `token.magic_size` is right to fire on a bare number, and these are layout
/// constants the screen owns rather than palette values, so they are not on
/// `ShedTokens`. The slab's two figures are **read off the component** — 160 × 140
/// written in two files is a contract that disagrees with itself the first time
/// one of them moves.
class _Band {
  static const double height = 152;
  static const double indexWidth = 96;
  static const double indexHeight = 64;
}

class FlockScreen extends ConsumerWidget {
  const FlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FlockFilters filters = ref.watch(flockFilterProvider);
    final AsyncValue<List<FlockRow>> rows = ref.watch(flockListProvider(filters));

    // The rows, or `null` when there are none to lay out lazily — loading,
    // error, and the two empty states, each of which is a single fixed box
    // rather than a stream.
    final List<FlockRow>? loaded = switch (rows) {
      AsyncData<List<FlockRow>>(value: final List<FlockRow> l) when l.isNotEmpty => l,
      _ => null,
    };

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
            showCapRow(
              context,
              reason,
              onShedScreen: false,
              now: appNow(),
              copyFor: (RefusalReason r) => capRefusalCopy(context, ref, r),
            );
        }
      }
    });

    return ShedPage(
      // **THE PAGE SAYS WHAT IT IS FILTERED TO, AND IT SAID NOTHING.** `§8`'s
      // header for this screen is `Flock · 8 ewes · 27 July 2026` — the count is
      // the one number a shepherd checks before believing the list.
      header: _header(context, l10n, rows),
      // **UPGRADE ROW 1, PINNED TO THE TOP** (`07 §19.2`), above the stream and
      // outside the scroll — a row that scrolled away would be present only
      // sometimes, and #92's whole point is that it is present always, in the
      // same pixels, at 3 ewes or at 15. It sits above the filter line now
      // rather than below it, which is what *"pinned top of Flock"* says.
      //
      // **THE FLOCK SCREEN IS NOT ONE OF THE FIVE SHED SCREENS**, which is why
      // the row is legal here at all. The widget carries its own quiet-hours and
      // entitlement guards regardless.
      fixedBelowHeader: UpgradeRow(
        eweCount: switch (rows) {
          AsyncData<List<FlockRow>>(value: final List<FlockRow> l) => l.length,
          _ => 0,
        },
        onUnlock: () => Routes.settings(context).ignore(),
      ),
      band: FlockBand(
        // **THE SAME WORD AS EVERY OTHER BAND.** `INDEX` is the only navigation
        // affordance in the app (P3, §7.0a) and there is no back chevron
        // anywhere, so one message serves all of them rather than a per-screen
        // copy that would drift.
        indexLabel: l10n.quickEntryIndex,
        slabLabel: l10n.flockAddSlab(term: l10n.termEweSingular.toUpperCase()),
        // **IT RETURNS TO TONIGHT, WHICH IS WHERE THE INDEX SHEET LIVES.**
        // `§7.17`'s six-destination sheet is `IndexSheet`, in
        // `lib/features/quick_entry/widgets/`, and `layer.sibling` makes it
        // unreachable from this feature — so the honest options were a second
        // copy of the destination list or one tap back to the page that owns it.
        // A duplicated navigation list stops agreeing the first time a screen is
        // added; this does not. The fix is an R87-style move of `IndexSheet`
        // into `lib/core/ui/components/`, which is not this task's to make
        // because every screen's band wants it at once.
        onIndex: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        onSlab: () => _openAddSheet(context, l10n),
        bandHeight: _Band.height,
        indexWidth: _Band.indexWidth,
        indexHeight: _Band.indexHeight,
        // **MIRRORED BY `app_settings.left_handed`, WHICH IS READ AND NEVER
        // RE-DERIVED** (R40). Exactly three things move — the slab, `INDEX`
        // and the keypad's bottom row — and the spine, the margin cell and
        // the record column do not.
        leftHanded: _leftHanded(ref),
      ),
      // **THE STREAM IS LAZY, AND 400 IS WHY** (`ShedPage.itemBuilder`). The
      // product is sized for *20–400 ewes*; a page that builds every row before
      // the first paint is 400 rows and 400 tabular-column measurements on a
      // screen the shepherd opens to answer one question about one animal. This
      // is the `ListView.builder` the screen has had since N26-T01, unchanged
      // except that the page now owns the scroll.
      itemCount: loaded == null
          ? null
          // **ONE EXTRA ITEM FOR THE DIVIDER**, and only when there is something
          // below it to divide. `indelible.md §7.4`: the removed ewes sit *"at
          // the bottom, under a printed line reading `STRUCK — 1`."* Plus one
          // for the filter line, which is the stream's first ruled row.
          : loaded.length + 1 + (loaded.any((FlockRow r) => r.removedFromFlock) ? 1 : 0),
      itemBuilder: loaded == null
          ? null
          : (BuildContext context, int i) {
              if (i == 0) {
                return _filterLine(context, ref, filters, rows);
              }
              final int at = i - 1;
              final int firstRemoved = loaded.indexWhere((FlockRow r) => r.removedFromFlock);
              if (firstRemoved >= 0 && at == firstRemoved) {
                return _struckDivider(context, l10n, loaded.length - firstRemoved);
              }
              return _row(
                context,
                l10n,
                loaded[firstRemoved >= 0 && at > firstRemoved ? at - 1 : at],
              );
            },
      scrollKey: const Key('flock.list'),
      // **EVERY ARM `02 §4.5` NAMES IS WRITTEN OUT**, in the order the screen
      // meets them. The trailing `_` is loading and Dart's exhaustiveness
      // requirement in one — `AsyncValue`'s sealed hierarchy is not closed over
      // the refreshing/reloading combinations, so the analyser rejects the
      // switch without it. `in_pens_strip.dart` reads the same way for the same
      // reason; it is not a catch-all for states nobody considered.
      //
      // **THE FOUR NON-LIST ARMS ARE ONE BOX EACH, AND THE BOX IS THE SAME BOX**
      // (`ShedPage.fill`, decision #71). The filter line sits at the top of the
      // slot in every one of them and the state below it takes the remainder, so
      // the header, the filter row and the band do not move a pixel between
      // loading, empty, filtered-empty, error and four hundred rows.
      fill: loaded != null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _filterLine(context, ref, filters, rows),
                Expanded(
                  child: switch (rows) {
                    AsyncData<List<FlockRow>>() => ShedEmptyState(
                      key: const Key('flock.empty'),
                      // FILTERED-EMPTY IS ITS OWN STATE (`07 §3.2`). "No animals
                      // yet" shown to somebody with 400 ewes and a filter on is
                      // the app telling them their flock is gone.
                      copy: filters.isEmpty ? l10n.flockEmpty : l10n.flockFilteredEmpty,
                    ),
                    AsyncError<List<FlockRow>>() => ShedEmptyState(
                      key: const Key('flock.error'),
                      copy: l10n.flockUnavailable,
                    ),
                    // **NEVER A SPINNER** (decision #71, `02 §4.5`). `07 §3.2`'s
                    // frame 1 is the ruled page with no ink in it — the header,
                    // the filter line and the band are all live and none of them
                    // is waiting on the statement, which is a better answer to
                    // *"is it working?"* than a spinner and does not move a
                    // single box when the rows land.
                    _ => const SizedBox.expand(),
                  },
                ),
              ],
            ),
    );
  }

  /// `Flock · 400 ewes · 8 August 2026`, or the same line without a count.
  ///
  /// **THE COUNT IS OMITTED WHILE IT IS UNKNOWN, NEVER PRINTED AS 0** (#58).
  /// `Flock · 0 ewes` on the frame before the statement returns is the app
  /// telling a shepherd with four hundred animals that they have none, and it is
  /// the frame they see on every cold open.
  ///
  /// The date is `formatShedDate`'s, so it is never all-numeric (R60) and there
  /// is one formatting authority rather than two.
  String _header(BuildContext context, AppLocalizations l10n, AsyncValue<List<FlockRow>> rows) {
    final String date = formatShedDate(LocalDate.of(appNow()), context.localeName);
    return switch (rows) {
      AsyncData<List<FlockRow>>(value: final List<FlockRow> list) => l10n.flockPageHeader(
        count: list.length,
        // The shepherd's own noun, as a placeholder and never a literal
        // (`10 §8.5`). The overlay itself lands with N29's terminology editing;
        // until then the shipped default is the sanctioned source and the slab
        // one line below reads it the same way.
        term: l10n.termEwePlural,
        date: date,
      ),
      _ => l10n.flockPageHeaderCounting(date: date),
    };
  }

  Widget _filterLine(
    BuildContext context,
    WidgetRef ref,
    FlockFilters filters,
    AsyncValue<List<FlockRow>> rows,
  ) =>
      // **THE LINE PRINTS ITS COUNTS OR RESERVES ITS RULED ROW.** Never a count
      // of 0 for a filter whose statement has not returned — that is #58 in the
      // one place a shepherd would act on it, by not tapping a filter that looks
      // empty and is not.
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
        // The grid does not move while it waits (`indelible.md §3.6`): the ruled
        // row is there, empty, at the height it will be when the words land.
        null => SizedBox(height: context.tokens.tapIndelible),
      };

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
  void _openAddSheet(BuildContext context, AppLocalizations l10n) {
    showShedBottomSheet<void>(
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
    ).ignore();
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

  /// The row's trailing stamp, or nothing.
  ///
  /// **ONE STAMP, AND THE ORDER IS THE ARGUMENT.** `indelible.md §6.3` budgets
  /// six marks a page and `§7.4` gives this row one trailing cell, so the list is
  /// a priority rather than a set:
  ///
  ///   * **REMOVED-FROM-FLOCK WINS OVER EVERYTHING.** She left the flock; a
  ///     contradiction in the records of an animal who is gone is a smaller fact
  ///     than her being gone.
  ///   * **A CONTRADICTION OUTRANKS A STATE**, because a state the shepherd can
  ///     see from the pen is cheaper to recover than one the app disagrees with
  ///     itself about — *"a contradiction found at 3am is still findable at 9am."*
  ///   * then the four states, most urgent first: a withdrawal is a food-chain
  ///     fact, barren and not-yet-lambed are season outcomes, penned is location.
  ///
  /// **BOXED IS THE ANIMAL, UNBOXED IS THE WRITING** (`§7.7`, ruling N3), and
  /// that is a real second channel rather than a naming convention: turn on the
  /// grayscale filter and `CULLED` still reads as a fact about the sheep while
  /// `QUERIED` reads as a note about the row.
  ///
  /// **`Pen 4 · 31h` IS NOT HERE AND CANNOT BE.** `§8` prints the pen label and
  /// the hours penned in this cell; `FlockRow` carries `isPenned` — a boolean —
  /// and neither the label nor `entered_at`, so the word is all this screen can
  /// say honestly. Inventing either would need a new column in the list
  /// statement, which is not a re-layout.
  Widget? _stamp(AppLocalizations l10n, FlockRow r) {
    if (r.removedFromFlock) {
      return ShedStatusBadge(stamp: ShedStamp.culled, label: l10n.flockStampCulled);
    }
    if (r.hasWarning) {
      return ShedStatusBadge(stamp: ShedStamp.queried, label: l10n.flockStampQueried);
    }
    // **RULING N1 — THE COMPARISON HAPPENS AGAINST `appNow()`, NOT IN SQL.** A
    // phone left on this page across midnight re-answers correctly on the next
    // rebuild, which a date bound into a long-lived `watch()` statement cannot
    // do. A withdrawal nobody typed counts as running (§12.1): unknown is never
    // clear, and the stamp says so with the same word either way.
    if (r.isUnderTreatment(appNow())) {
      return ShedStatusBadge(stamp: ShedStamp.withdrawal, label: l10n.flockStampWithdrawal);
    }
    if (r.barren) {
      return ShedStatusBadge(stamp: ShedStamp.barren, label: l10n.flockStampBarren);
    }
    if (r.notYetLambed) {
      return ShedStatusBadge(stamp: ShedStamp.toLamb, label: l10n.flockStampNotYetLambed);
    }
    if (r.isPenned) {
      return ShedStatusBadge(stamp: ShedStamp.penned, label: l10n.flockStampPenned);
    }
    return null;
  }

  /// `§7.4`'s summary line: *"3 seasons · avg 2.0 · assisted twice"*.
  ///
  /// **THREE CLAUSES, NOT FOUR, AND THAT IS THE COLUMN SET RATHER THAN A CUT.**
  /// `ewe_card_controller.dart` states the split in as many words: the card has
  /// the timeline so it renders *"prolapsed 2025"* as well; `ewe_summaries`
  /// stores `last_observation_season` — a season foreign key, not a kind — so the
  /// flock row has no way to name the observation and honestly renders three.
  ///
  /// **EVERY CLAUSE IS DROPPED RATHER THAN ZEROED** (#58, `05 §6.5`). A `null`
  /// count is *not computed*, never *none*: `ewe_summaries` is a `LEFT JOIN`, so
  /// a ewe created ten seconds ago has no row, and `0 seasons` printed against a
  /// six-year-old ewe is the app inventing a fact about her. An earlier draft
  /// coalesced one of these counts with the very operator that paragraph forbids
  /// and `stat.zero_default2` failed the build on it.
  ///
  /// **THE CARD'S OWN MESSAGES, NOT A SECOND SET.** The same fact wears the same
  /// clothes wherever it appears; two catalogues of *"3 seasons"* is two that
  /// stop agreeing the first time one is edited.
  String _summary(BuildContext context, AppLocalizations l10n, FlockRow r) {
    final String locale = context.localeName;
    final List<String> clauses = <String>[];

    if (r.seasonsRecorded case final int seasons) {
      clauses.add(l10n.eweCardSummarySeasons(count: seasons));
    }

    // **DIVIDED BY LAMBINGS, NOT BY SEASONS** (`05 §6.5`: litter size is
    // `lambsBorn ÷ ewesLambed`). A ewe with three recorded seasons and two
    // lambings has an average over 2; dividing by seasons deflates it, and
    // nothing on the row would say so. Both counts must be real and the divisor
    // non-zero, or the clause is absent.
    final int? lambings = r.lambingsRecorded;
    final int? born = r.lambsBorn;
    if (lambings != null && born != null && lambings > 0) {
      clauses.add(l10n.eweCardSummaryAverage(average: formatShedAverage(born / lambings, locale)));
    }

    // **PRINTED ONLY WHEN IT IS A POSITIVE COUNT, AND WITHOUT ITS COVERAGE.**
    // `05 §6.7` appends *"of n scored"* whenever some lambings have no ease —
    // that needs `scored_lambings`, which the card's statement returns and the
    // flock list's does not. A bare `0` here could mean *never assisted* or
    // *nothing scored*, and those are different facts (§12.4), so zero drops the
    // clause instead of asserting the first one.
    if (r.assistedLambings case final int assisted when assisted > 0) {
      clauses.add(l10n.eweCardSummaryAssisted(count: assisted));
    }

    return clauses.join(' · ');
  }

  Widget _row(BuildContext context, AppLocalizations l10n, FlockRow r) {
    // The warning's four channels (`§7.4`): the `†` in the margin, the doubled
    // rule beneath, the `QUERIED` word in the trailing cell, and the row staying
    // exactly where it is. None of them is colour, which is `§1.2` rule 3.
    final bool warned = r.hasWarning && !r.removedFromFlock;
    return ShedAnimalRow(
      // KEYED ON THE EWE ID, never the tag and never the index: a tag is "exactly
      // as typed" and may carry letters or leading zeros, which breaks the
      // all-lower_snake key format (R59), and an index reorders under a filter.
      key: Key('flock.row.${r.id.value}'),
      tag: r.tag,
      summary: _summary(context, l10n, r),
      height: ShedAnimalRowHeight.tall,
      warning: warned,
      // **`†` — `§6.2`'s mark, in `§4.3`'s cell.** It is a printer's mark rather
      // than an icon (`§1.3` bans the icon set, not the marks), it never carries
      // the meaning alone, and it is the reason the margin gutter is reserved on
      // every row whether or not it has one: a tag column that moved 68 px when a
      // ewe was queried would undo the alignment the whole screen is built on.
      margin: warned
          ? Text(
              l10n.flockRowWarningMark,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            )
          : null,
      trailing: _stamp(l10n, r),
      semanticLabel: l10n.flockRowLabel(tag: r.tag),
      onTap: () {},
    );
  }
}
