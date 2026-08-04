// lib/features/flock/ewe_card_screen.dart — `indelible.md §8` screen 2.
//
// **T01 IS DELIBERATELY MINIMAL: ONE LINE PER TIMELINE ROW.** The statement is
// the task, and this screen exists to prove it reaches a widget. T02 builds the
// summary line, T04 turns each line into a real ruled record row with its
// provenance label, and T07 lands the heading hierarchy and the empty state.
//
// A screen that arrived whole here would be a screen nobody reviewed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/features/flock/widgets/earlier_animal_note.dart';
import 'package:shed_book/features/flock/widgets/ewe_card_actions.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/features/flock/widgets/ewe_summary_line.dart';
import 'package:shed_book/features/flock/widgets/season_heading.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/features/flock/widgets/timeline_record_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class EweCardScreen extends ConsumerWidget {
  const EweCardScreen({required this.eweId, required this.tag, super.key});

  final EweId eweId;

  /// **PASSED IN, NOT LOOKED UP.** The tag is what the shepherd tapped to get
  /// here, so it is already known — a second statement to re-read it would put a
  /// frame between opening the card and knowing whose it is.
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **REGISTERED UNCONDITIONALLY, AT THE TOP OF `build`** (`02 §4.3`).
    // Navigation is the screen's job, never the controller's (`§4.4` rule 3).
    ref.listen<WriteState>(flockWriteControllerProvider, (WriteState? _, WriteState next) {
      if (next case WriteDone(outcome: final WriteOutcome outcome)) {
        // Sealed, three variants, no `default:` — the day a fourth appears this
        // must fail to compile rather than swallow it.
        switch (outcome) {
          case WriteCommitted(insertedId: final int? id):
            // **AN ID MEANS A SCREEN IS ABOUT TO BE PUSHED, AND ONLY
            // `beginLambing` CARRIES ONE.** `WriteCommitted.insertedId` is R33's
            // single permitted place for a bare `int`, and the other three verbs
            // on this card deliberately return none — so the listener can tell
            // them apart without screen state to disambiguate them.
            //
            // The lambing row already exists, committed before this listener
            // ran, so pushing is the only thing left to do. Every other verb
            // confirms by its row appearing on the timeline behind — P2: the
            // confirmation IS the committed row, and there is no SnackBar.
            if (id != null) {
              Routes.lambingEntry(context, LambingId(id)).ignore();
            }
          case WriteFailed(failure: final ShedFailure failure):
            showFailure(context, failure.userMessage);
          case WriteRefused(reason: final RefusalReason reason):
            // Not reachable from this card — nothing here is a gated verb — and
            // stated rather than assumed, because `showCapRow` carries the guard
            // that would matter if one ever were.
            showCapRow(context, reason, onShedScreen: false);
        }
      }
    });

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        // **ONE SCROLLING DOCUMENT, AND A FIXED BAND UNDER IT.** The disclosure,
        // the summary line and the timeline are one scroll — which is what
        // `indelible.md §8` means by *the same document under a different
        // filter* — and the actions are a fixed layer above it, in the thumb
        // band, where they cannot scroll away from the thumb.
        //
        // **THE FIRST DRAFT MADE THE SUMMARY A FIXED HEADER AND IT OVERFLOWED BY
        // 120 PX AT 200 %** on a 375 x 667 device: a three-line summary and four
        // wrapped word buttons both demanded their full height and the timeline
        // had nothing left to give. Reading gives way to scrolling; the thumb
        // band never does.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _page(context, ref, t, l10n)),
            // **THE ACTIONS SIT IN THE THUMB BAND** (`indelible.md §4.5`):
            // nothing required to record an event is more than 320 px from the
            // bottom, and reading happens above it.
            EweCardActions(eweId: eweId),
          ],
        ),
      ),
    );
  }

  /// The page: the disclosure, the summary line, then her history — in that
  /// order, because each one qualifies the next.
  ///
  /// **SPEC §7.7's *"visible before anything else"* IS A WIDGET-ORDER FACT**, not
  /// a comment: the summary line is the first thing under the disclosure, and
  /// the disclosure is above it because it qualifies *who this card is about*. A
  /// reader who meets the timeline first has already begun attributing it to one
  /// animal.
  Widget _page(BuildContext context, WidgetRef ref, ShedTokens t, AppLocalizations l10n) =>
      CustomScrollView(
        key: const Key('ewe_card.page'),
        // **NOTHING HERE DECLARES A READING ORDER, AND THE GATE AGREES.**
        // `a11y.sort_key` bans the semantics-ordering key outright — *reading
        // order is the tree* (`10 §10`) — and the first draft of this page reached
        // for one anyway, because a raw walk of the semantics tree returns this
        // `CustomScrollView`'s slivers in an order that does not follow the page.
        //
        // The walk order is not the traversal order. Flutter derives that from
        // geometry when it serialises to the platform, and on a vertical page
        // geometry already IS the reading order. What the keys did buy was a
        // regression: an ancestor `Semantics` merges the labels beneath it, so
        // the title and the summary line became one node — undoing the *one node
        // per region* property `10 §3.4` asks for. The test asserts heading order
        // by position instead, which is what a reader actually gets.
        //
        // (The banned identifier is described rather than spelled: that gate row
        // scans source text, comments included.)
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: EarlierAnimalNote(
              eweId: eweId,
              tag: tag,
              // **THE EARLIER CARD DOES NOT DISCLOSE BACK.** The relationship
              // is directional: she is finished, and telling a reader of a
              // closed record that a different animal has her number later is
              // noise at the moment they are trying to read one history. That
              // falls out of the statement rather than out of this call — it
              // returns only animals whose status is not active.
              onOpen: (EweId earlier, String earlierTag) =>
                  Routes.eweCard(context, earlier, tag: earlierTag),
            ),
          ),
          SliverToBoxAdapter(
            child: EweSummaryLine(eweId: eweId, tag: tag),
          ),
          // **`SliverFill` SO THE EMPTY STATE STILL OWNS THE REST OF THE PAGE.**
          // It is what keeps `07 §2.2`'s promise that the empty state *"occupies
          // the same box the populated content will"* — nothing jumps when the
          // first record lands.
          SliverFillRemaining(hasScrollBody: true, child: _timeline(context, ref, t, l10n)),
        ],
      );

  Widget _timeline(BuildContext context, WidgetRef ref, ShedTokens t, AppLocalizations l10n) =>
      SizedBox.expand(
        // **EVERY ARM WRITTEN OUT** (`02 §4.5`), and read as an exhaustive
        // switch rather than through the accessors that flatten the three states
        // into two. The trailing `_` is loading and Dart's exhaustiveness
        // requirement in one — `AsyncValue`'s hierarchy is not closed over the
        // refreshing combinations.
        child: switch (ref.watch(eweTimelineProvider(eweId))) {
          AsyncData<List<TimelineRow>>(value: final List<TimelineRow> rows) when rows.isEmpty =>
            ShedEmptyState(key: const Key('ewe_card.empty'), copy: l10n.eweCardEmpty),
          AsyncData<List<TimelineRow>>(value: final List<TimelineRow> rows) => ListView(
            key: const Key('ewe_card.timeline'),
            padding: EdgeInsets.zero,
            children: <Widget>[
              // **GROUPED BY THE SEASON EACH ROW WAS FILED UNDER**, so a screen
              // reader can jump season to season instead of swiping through
              // eighty rows (`10 §3.4`). The groups are already in the
              // statement's order — newest first — so nothing is re-sorted here.
              for (final ({int? year, List<TimelineRow> rows}) group in groupBySeason(
                rows,
              )) ...<Widget>[
                SeasonHeading(
                  key: Key('ewe_card.season.${group.year ?? 'none'}'),
                  label: group.year == null
                      ? l10n.eweCardNoSeasonHeading
                      : l10n.eweCardSeasonHeading(
                          year: formatShedYear(
                            group.year!,
                            Localizations.localeOf(context).toLanguageTag(),
                          ),
                        ),
                ),
                // **KEYED ON THE PAIR, NEVER ON `ref` ALONE.** Lambing 7 and
                // note 7 are both `ref: 7`, so a key built from the id alone
                // collides and Flutter reuses the wrong element.
                for (final TimelineRow r in group.rows)
                  TimelineRecordRow(key: Key('ewe_card.row.${r.kind.key}.${r.ref}'), row: r),
              ],
            ],
          ),
          AsyncError<List<TimelineRow>>() => ShedEmptyState(
            key: const Key('ewe_card.error'),
            copy: l10n.eweCardUnavailable,
          ),
          // **NEVER A SPINNER** (#71). `07 §4.2`'s frame 1 is a fixed-height
          // placeholder at the summary line's exact height — T02 builds it, and
          // until the summary line exists there is no height to reserve, so the
          // page colour is the honest first frame rather than a lie about
          // progress.
          _ => const SizedBox.expand(),
        },
      );
}
