// lib/features/treatments/treatments_screen.dart
//
// TWO SEGMENTS OVER ONE STATEMENT. The countdown is what is still running — the
// question at the gate, *can she go?* — and the book is what they open in the
// office. `indelible.md §8` screen 8: the medicine book is not a separate view,
// it is the book filtered to treatments.
//
// **NOTHING ON THIS SCREEN SAYS AN ANIMAL IS CLEAR.** Leaving the countdown is
// not the same as claiming a negative, and only the shepherd and their vet can
// say the second. That absence is asserted, not assumed.
//
// ---------------------------------------------------------------------------
// IT IS `ShedPage` NOW, AND THAT IS THE WHOLE OF THIS REWRITE (R87)
// ---------------------------------------------------------------------------
//
// Measured against the running app on 2026-08-06: this screen was a `Column` of
// `Text` on a dark background — no spine, no margin gutter, no sticky header, no
// ruled rows and no thumb anchors. `indelible.md §8`'s first claim is that there
// is ONE scrolling ruled document and twelve screens are that document under a
// different filter; six screens were a different document each time, because the
// parts lived in `lib/features/quick_entry/widgets/` where `layer.sibling` made
// them unreachable.
//
// **Not one number, not one query and not one write changed.** The countdown,
// the day tally, `CLEARS <date>`, the three withdrawal states and the soft void
// are exactly what they were; they are now laid on `ShedRuledRow`s that share
// edges, over a spine, under a 44 pt header, with `+ DOSE` and `INDEX` in the
// thumb band. The safety-critical arithmetic is untouched by construction: this
// file still computes nothing about a withdrawal except `daysUntil`, which it
// already used to decide whether a period is still running.
//
// **The one addition is a sentence, and it is the most important thing here.**
// `indelible.md §8` and §9 both print `DAYS NOT COPIED — READ THE BOTTLE` beside
// `REPEAT LAST` and it had never been built. It is welded above the band with
// the control it qualifies, so it cannot scroll away from it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_bottom_band.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_countdown.dart';
import 'package:shed_book/core/ui/components/shed_page.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/features/treatments/treatments_controller.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/features/treatments/widgets/new_treatment_sheet.dart';
import 'package:shed_book/features/treatments/widgets/treatment_disclosures.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The band's geometry, from `indelible.md §4.3–§4.4` at the 393 × 852 viewport.
///
/// Named rather than typed inline for the reason `token.magic_size` exists — and
/// the slab's two figures are **read off the component**, never copied, because
/// `indelible.md §7.1`'s 160 × 140 written in two files is a contract that will
/// disagree with itself the first time one of them moves.
class _Band {
  static const double height = 152;
  static const double indexWidth = 96;
  static const double indexHeight = 64;
  static const double slabWidth = ShedCornerSlab.width;
  static const double slabHeight = ShedCornerSlab.height;
}

class TreatmentsScreen extends ConsumerWidget {
  const TreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // `context.localeName`, THE EXTENSION `formatters.dart` SHIPS — which had
    // zero uses and six bypasses, mine among them. The two spellings are not
    // equal (`en-GB` vs `en_GB`), so the single point of truth its doc comment
    // claims did not exist until the call sites moved.
    final String locale = context.localeName;
    final TreatmentMode mode = ref.watch(treatmentModeProvider);
    final List<TreatmentRow> rows =
        ref.watch(treatmentsProvider(mode)).value ?? const <TreatmentRow>[];

    // THE TICK, WATCHED HERE AND NOT INSIDE A PROVIDER. A countdown's remaining
    // days is a function of `now`, so nothing stores it; and a keepAlive
    // listener on the `.autoDispose` ticker is a listener that never goes away,
    // waking the process every sixty seconds all night with no screen up
    // (`02 §4.2`, decision #66). The pen board watches it the same way and for
    // the same reason.
    final Instant now = ref.watch(minuteTickProvider).value ?? appNow();
    final LocalDate today = LocalDate.of(now);

    // **THE PREVIOUS TREATMENT IS ASKED FOR AT TAP TIME, NOT COMPUTED HERE.**
    // `build` used to filter the book stream for the most recent non-voided row
    // and watch its withdrawals — a second implementation of
    // `TreatmentRepository.lastTreatment`, whose doc comment says in as many
    // words that it is *what repeat last offers*. Two answers to one question is
    // one that eventually disagrees, and the rule they both have to hold is that
    // a voided treatment is never the one repeated.
    //
    // It also stopped `build` doing the work for a sheet that is usually not
    // opened, and took two `ref.watch`es off a screen that re-renders on every
    // minute tick.
    final QuickEntryDeck? deck = ref.watch(quickEntryDeckProvider).value;
    final List<DeckEntry> candidates = <DeckEntry>[...?deck?.penned, ...?deck?.recents];

    // BUILT BEFORE THE TREE, so *"is there anything to show"* is asked of what
    // actually renders. In the countdown a treatment can be in `rows` and yet
    // contribute no line — every one of its periods has cleared — and asking
    // `rows.isEmpty` there would paint a page with an empty stream instead of
    // saying so.
    final List<Widget> lines = mode == TreatmentMode.countdown
        ? _countdownLines(rows, now: now, today: today, locale: locale, l10n: l10n)
        : <Widget>[
            for (final TreatmentRow row in rows)
              _BookLine(
                row: row,
                locale: locale,
                l10n: l10n,
                onVoid: () => ref.read(treatmentRepositoryProvider).voidTreatment(row.id).ignore(),
              ),
          ];

    return ShedPage(
      // `TREATMENTS`, and the medicine book is the SECTION below. The mockup
      // prints `Medicine book · 2026` at the top of one page because it draws
      // one page; this screen is two filters over one statement, and a sticky
      // header that named only one of them would be wrong on the other half of
      // the time.
      header: l10n.treatmentsTitle,
      scrollKey: const Key('treatments.record_column'),
      // **WELDED ABOVE THE BAND, AND THE SENTENCE IS WHY.** `ShedPage`'s
      // `fixedAboveBand` is the slot for a row that must not scroll away, and
      // two rows need it.
      //
      // **THE §12.3 FOOTER HAS MOVED TWICE FOR THE SAME REASON.** At N20 it sat
      // inside the list's own `Column`, so an EMPTY book rendered no disclosure
      // at all — the one view somebody might print or hand to a vet was the one
      // that could lose it. The R87 rebuild put it in `ShedPage.children`, which
      // is the scrolling stream, so on a book longer than a screen it went below
      // the fold: a disclosure a reader has to scroll to find is a disclosure
      // conditional on their scrolling. Here it is on the first painted frame of
      // book mode at every list length, including zero.
      // `REPEAT LAST` is only safe while `DAYS NOT COPIED — READ THE BOTTLE` is
      // beside it: the two together are safety rule §12.1 at the one place the
      // app carries a figure forward, and a stream position would let a thumb
      // scroll the qualifier off the top of the control it qualifies.
      // **TWO ROWS SHARE THE SLOT, AND BOTH EARNED IT.** `mainAxisSize.min` so
      // the pair takes exactly its own height and the stream keeps the rest.
      fixedAboveBand: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (mode == TreatmentMode.book) const TreatmentBookFooter(),
          _RepeatRow(l10n: l10n, onRepeat: () => _openRepeat(context, ref, l10n, candidates)),
        ],
      ),
      band: ShedBottomBand(
        // **`INDEX` IS THE ONLY NAVIGATION AFFORDANCE IN THE APP** (P3, decision
        // record §7.0a): there is no back chevron anywhere, and until this
        // commit this screen had no exit affordance at all — only the hardware
        // key, which iOS does not have. It pops rather than pushing: Quick Entry
        // is `MaterialApp.home` and route 0, so *back to the book* and *the
        // index* are the same act from here.
        indexLabel: l10n.quickEntryIndex,
        onIndex: () => Routes.popToQuickEntry(context),
        // `+ DOSE`, the corner slab — the largest target in the system and the
        // one the shepherd aims at without looking. The key stays
        // `treatments.new` because that is what `CONVENTIONS §4.5` asks for and
        // what the fresh-notebook journey pins; it was a `ShedPrimaryButton` in
        // a `Column` before, which is the same act in the wrong place.
        slabKey: const Key('treatments.new'),
        slabLabel: l10n.treatmentsSlab,
        onSlab: () => _openNew(context, ref, l10n, candidates),
        bandHeight: _Band.height,
        indexWidth: _Band.indexWidth,
        indexHeight: _Band.indexHeight,
        slabWidth: _Band.slabWidth,
        slabHeight: _Band.slabHeight,
      ),
      children: <Widget>[
        _ModeRow(mode: mode, l10n: l10n),
        // THE RULED SECTION LINE, WHICH NAMES THE FILTER AND COUNTS IT.
        // `indelible.md §8` screen 8: `MEDICINE BOOK · 2026` and
        // `ACTIVE WITHDRAWALS · 2`.
        ShedRuledRow(
          key: const Key('treatments.section'),
          child: ShedSectionHeading(
            label: mode == TreatmentMode.countdown
                ? l10n.treatmentsSectionRunning(count: formatShedCount(lines.length, locale))
                : l10n.treatmentsSectionBook,
          ),
        ),
        if (lines.isEmpty)
          // **A LINE ABOUT THE PAGE, IN THE PIXELS A ROW WOULD OCCUPY** — not
          // `ShedEmptyState`, which is `double.infinity` in both axes and
          // therefore unusable inside a scrolling stream. It was legal on the
          // old `Column` because the old screen had no chrome for it to push
          // around; on a page with a header, a spine and two thumb anchors, an
          // empty state that takes the viewport would move all three.
          //
          // Decision #71's *"one line of copy and one action"* still holds: the
          // action is `+ DOSE`, and it is now permanently in the thumb band
          // rather than only on the empty screen.
          ShedRuledRow(
            height: kRuledRowTall,
            child: _RecordColumn(
              children: <Widget>[
                Text(
                  l10n.treatmentsEmpty,
                  key: const Key('treatments.empty'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: context.tokens.textSecondary),
                ),
              ],
            ),
          )
        else
          ...lines,
      ],
    );
  }

  /// The book's section line.
  ///
  /// **IT DOES NOT NAME A SEASON, AND THAT IS A CORRECTION MADE BEFORE IT
  /// SHIPPED.** The screen 8 mockup prints `MEDICINE BOOK · 2026` and the first
  /// build of this line followed it, reading the current season out of
  /// `settingsProvider` and `seasonsProvider`.
  ///
  /// `TreatmentRepository.watchTreatments` applies **no season filter**. So the
  /// line named a scope the list beneath it does not have: every treatment ever
  /// recorded, under a heading claiming one season. On the one screen in this app
  /// that gets handed to a vet, a heading that misstates which records these are
  /// is worse than a heading that says less.
  ///
  /// Restoring the season means filtering the statement — a data change, and one
  /// with its own question underneath it (`_currentSeason` versus the season the
  /// animal belongs to is already an open ruling in that file).

  /// **THE ENTRY N20 NEVER BUILT.** `recordTreatment` landed at N20-T01 and had
  /// no caller anywhere in `lib/`; `WithdrawalControl` — safety rule §12.1's
  /// control — landed at N20-T02 and was never built into a screen. The only
  /// reachable write was `repeatTreatment`, and on an empty book there is
  /// nothing to repeat. `07 §10.4` specifies this row and nobody wrote it.
  void _openNew(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<DeckEntry> candidates,
  ) {
    final List<VocabEntry> vocab = ref.read(vocabProvider).value ?? const <VocabEntry>[];
    unawaited(
      showRepeatSheet(
        context,
        // **THE BARRIER SAID `REPEAT LAST` OVER THE NEW-TREATMENT SHEET.** One
        // opener serves both sheets and it hard-coded one of the two labels, so
        // a VoiceOver user opening `+ DOSE` was told the modal behind them was
        // the repeat flow. `10 §3.2`: a label that does not match what is on
        // screen is worse than no label, because it is believed.
        barrierLabel: l10n.treatmentNewTitle,
        child: NewTreatmentSheet(
          candidates: candidates,
          routes: treatmentRoutes(vocab, l10n),
          l10n: l10n,
          onCommit: (NewTreatment entry) {
            unawaited(
              ref
                  .read(treatmentRepositoryProvider)
                  .recordTreatment(
                    TreatEwe(entry.ewe),
                    productName: entry.productName,
                    doseText: entry.doseText,
                    routeKey: entry.routeKey,
                    batchNo: entry.batchNo,
                    withdrawals: entry.withdrawals,
                  ),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// **ONE LINE PER TARGET** (`07 §10.1`) — *"a meat clear date and a milk clear
  /// date are two different countdowns and are listed as two rows, each labelled
  /// with its target"*. The statement fans out, the repository folds it by
  /// treatment, and this is the one place the fan-out is wanted back.
  ///
  /// **CLEARED PERIODS LEAVE THE RUNNING LIST**, at the tick that crosses
  /// midnight rather than at the next query. `07 §10.1` bounds this in SQL with
  /// `clear_date >= :today`; binding a date into the statement would re-key the
  /// provider family every day and re-subscribe, for a filter the screen already
  /// holds `now` to apply. **Nothing is deleted** — the treatment stays in the
  /// book for ever, which is where `indelible.md §7.6`'s *cleared* state lives.
  ///
  /// Deliberately NOT a filter on `days == null`: a `not_applicable` row has no
  /// clear date and so cannot appear here, and a `days` row always has one under
  /// `CHECK ((kind = 'days') = (clear_date IS NOT NULL))`. Filtering on the date
  /// is filtering on the thing being counted down.
  static List<Widget> _countdownLines(
    List<TreatmentRow> rows, {
    required Instant now,
    required LocalDate today,
    required String locale,
    required AppLocalizations l10n,
  }) => <Widget>[
    for (final TreatmentRow row in rows)
      for (final StoredWithdrawal w in row.withdrawals)
        if (w.clearDate case final LocalDate d when today.daysUntil(d) > 0)
          _CountdownLine(
            row: row,
            withdrawal: w,
            clearDate: d,
            now: now,
            locale: locale,
            l10n: l10n,
          ),
  ];

  /// Tap one of two: this opens the sheet, and a tag in it commits.
  ///
  /// **THE PREVIOUS ENTRY IS SHOWN WITH ITS PROVENANCE AND ITS DAYS ARE NOT
  /// CARRIED ACROSS.** The shepherd reads what they entered last time and
  /// decides; copying it would make the app the source of a clinical figure for
  /// a treatment nobody read a label for (§12.1).
  ///
  /// An earlier draft named a `repeatOfferProvider` here that was deleted in the
  /// rewrite; the comment outlived it and pointed at nothing.
  void _openRepeat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<DeckEntry> candidates,
  ) {
    unawaited(() async {
      final TreatmentRepository treatments = ref.read(treatmentRepositoryProvider);

      // **ASKED AT TAP TIME, AND ASKED OF THE REPOSITORY.** `build` used to
      // compute *the previous treatment* itself by filtering the book stream —
      // a second implementation of `lastTreatment`, whose doc comment says in as
      // many words that it is *what repeat last offers*. Two answers to one
      // question is one that eventually disagrees, and the rule they both have
      // to hold is that **a voided treatment is never the one repeated**.
      final TreatmentRow? previous = await treatments.lastTreatment();
      if (previous == null || !context.mounted) {
        return;
      }

      // **BOTH TARGETS, ALWAYS — AND THIS IS §12.1 BECOMING READABLE.**
      // The sheet rendered whatever withdrawal ROWS existed, so a target nobody
      // recorded a period for was **invisible**: one line about meat and nothing
      // at all about milk, which reads as *there is nothing to say* rather than
      // *nobody looked*. Those are the two facts §12.1 exists to keep apart.
      //
      // `withdrawalFor` returns `WithdrawalNotRecorded` for the absent one,
      // because absence IS the state — and asking per target is what makes it
      // print. A caller cannot get a `0` back from a treatment nobody entered a
      // period for, because there is nothing to read a zero from.
      final List<({WithdrawalTarget target, WithdrawalPeriod period})> periods =
          <({WithdrawalTarget target, WithdrawalPeriod period})>[
            for (final WithdrawalTarget target in WithdrawalTarget.values)
              (target: target, period: await treatments.withdrawalFor(previous.id, target)),
          ];

      if (!context.mounted) {
        return;
      }
      await showRepeatSheet(
        context,
        child: _RepeatSheet(
          previous: previous,
          periods: periods,
          candidates: candidates,
          l10n: l10n,
          onPicked: (EweId ewe) {
            unawaited(treatments.repeatTreatment(previous.id, TreatEwe(ewe)));
            Navigator.of(context).pop();
          },
        ),
      );
    }());
  }
}

/// The repeat sheet's opener — `showShedBottomSheet`, the sanctioned wrapper.
///
/// **IT WAS CALLED `showDialogFreeSheet` AND THE GATE REFUSED IT**, which was
/// exactly right and slightly funny: `one_overlay_test.dart` scans for the modal
/// function's NAME, and a helper named to disclaim that function contains it.
/// The sixth prohibition this session to match itself, and the first to do so in
/// an identifier rather than a comment. The name says what it opens instead.
///
/// [barrierLabel] defaults to the repeat flow's own word because that is the
/// sheet this opener was written for; `+ DOSE` passes its own. **The default is
/// not a shrug** — a barrier with no label is a modal a screen reader cannot
/// name at all, and this function has exactly two callers, both in this file.
Future<void> showRepeatSheet(BuildContext context, {required Widget child, String? barrierLabel}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showShedBottomSheet<void>(
    context,
    dismissLabel: l10n.colostrumSheetClose,
    dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
    barrierLabel: barrierLabel ?? l10n.treatmentsRepeatLast,
    fillsViewport: true,
    child: child,
  );
}

/// `§4.3`'s record column — everything from x=76, and its own vertical padding.
///
/// **`ShedRuledRow` STRETCHES ITS CHILD AND DOES NOT PAD IT**, deliberately — the
/// row is a rule and the space above it, and how that space is spent belongs to
/// the row's content. Every record row on this screen spends it the same way, so
/// it is written once: without it a two-line record sits flush against its own
/// rule and against the rule of the row above, and the ledger reads as one block
/// of text rather than as ruled lines.
///
/// The half-gap is also what keeps two rows' word buttons apart. R86 allows a
/// separation of 0 or ≥ 16 and nothing between, and 8 pt above and 8 pt below
/// puts the `VOID THIS` of one book row 16 pt clear of the next one's before the
/// intervening record line is counted at all.
class _RecordColumn extends StatelessWidget {
  const _RecordColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.tokens.gapMin / 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

/// The two segments, on one ruled line.
///
/// Word buttons, not a segmented control — `indelible.md §7.9`: there is no
/// segmented control, because there is no radius and no container in this system.
class _ModeRow extends ConsumerWidget {
  const _ModeRow({required this.mode, required this.l10n});

  final TreatmentMode mode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;

    return ShedRuledRow(
      key: const Key('treatments.modes'),
      child: Row(
        children: <Widget>[
          for (final ({TreatmentMode value, String word}) segment
              in <({TreatmentMode value, String word})>[
                (value: TreatmentMode.countdown, word: l10n.treatmentsModeCountdown),
                (value: TreatmentMode.book, word: l10n.treatmentsModeBook),
              ])
            // FLEXIBLE, AND MEASURED. Two words plus their gaps came to 124 px
            // over on a 375 pt phone at 200% text — the segments are the widest
            // fixed thing on the screen, and they are the one part that can give
            // without losing a fact.
            //
            // The `gapMin` between them is R86's floor exactly: two independent
            // targets are 0 apart or at least 16, and nothing in between.
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: t.gapMin),
                child: _Segment(
                  id: 'treatments.mode.${segment.value.key}',
                  word: segment.word,
                  selected: mode == segment.value,
                  onTap: () => ref.read(treatmentModeProvider.notifier).show(segment.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `REPEAT LAST`, and the sentence that makes it safe.
///
/// **THE SENTENCE IS NOT DECORATION AND IT IS NOT A TIP.** `indelible.md §8`
/// screen 8 and §9's safety table both print `DAYS NOT COPIED — READ THE BOTTLE`
/// where the copied value would be, and the reason is the NADIS finding behind
/// decision #51: a withdrawal period can **change for the same medicine** and
/// **differ between products with the same active ingredient**. So last time's
/// figure is not evidence about this bottle, and a repeat that carried it would
/// be the app originating a clinical number for a treatment nobody read a label
/// for.
///
/// It is printed in full ink beside the control, permanently — never behind a
/// tap, never in a tooltip (there are none), and never in the scroll where a
/// thumb could separate it from what it qualifies.
class _RepeatRow extends StatelessWidget {
  const _RepeatRow({required this.l10n, required this.onRepeat});

  final AppLocalizations l10n;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return ShedRuledRow(
      height: kRuledRowTall,
      child: _RecordColumn(
        children: <Widget>[
          // `indelible.md:973` names this control: "REPEAT LAST TREATMENT is a
          // prominent word button", and §7.13 puts a primary at `--t-ctl-lg`
          // 22px.
          //
          // `IntrinsicWidth` for the reason `ShedWordButton` carries in its own
          // header: `ShedTapTarget` wraps its child in a `Center`, which expands
          // to every pixel it is offered, so an unconstrained primary here is a
          // full-width slab with a small word in the middle of it — the shape
          // the owner described looking at the running app.
          IntrinsicWidth(
            child: ShedPrimaryButton(
              key: const Key('treatments.repeat_last'),
              label: l10n.treatmentsRepeatLast,
              semanticLabel: l10n.treatmentsRepeatLast,
              onTap: onRepeat,
            ),
          ),
          SizedBox(height: t.gapMin / 2),
          Text(
            l10n.treatmentsDaysNotCopied,
            key: const Key('treatments.days_not_copied'),
            // FULL INK, which is the mockup's own emphasis on this line and the
            // only place on the screen a printed sentence takes it. A §12.1
            // sentence set at `textSecondary` reads as chrome, and chrome is
            // what a shepherd's eye is trained to skip at 03:20.
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RepeatSheet extends StatelessWidget {
  const _RepeatSheet({
    required this.previous,
    required this.periods,
    required this.candidates,
    required this.l10n,
    required this.onPicked,
  });

  final TreatmentRow previous;

  /// **ONE ENTRY PER TARGET, NOT ONE PER STORED ROW.** A target with no row
  /// arrives as `WithdrawalNotRecorded` and prints, which is the whole point:
  /// *nobody looked* has to be visible, and a missing line says the opposite.
  final List<({WithdrawalTarget target, WithdrawalPeriod period})> periods;
  final List<DeckEntry> candidates;
  final AppLocalizations l10n;
  final ValueChanged<EweId> onPicked;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(previous.productName, style: text.titleMedium),
          ),
          // **THE SENTENCE IS IN THE SHEET TOO, AND IT IS THE SAME SENTENCE.**
          // The row that opens this sheet carries it and so does the sheet: the
          // committing tap happens in here, and §12.1's whole gate is that the
          // shepherd reads what is and is not being carried forward *before*
          // that tap rather than before the one that got them here.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(
              l10n.treatmentsDaysNotCopied,
              key: const Key('treatment.repeat.days_not_copied'),
              style: text.bodyMedium?.copyWith(color: t.textPrimary),
            ),
          ),
          // WHAT THEY ENTERED LAST TIME, WITH ITS PROVENANCE BESIDE IT — shown
          // so they can read it, never written for them.
          for (final ({WithdrawalTarget target, WithdrawalPeriod period}) w in periods)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      // **THE THREE STATES ARE THREE DIFFERENT SENTENCES**, and
                      // the middle one is the one that used to be a blank line.
                      switch (w.period) {
                        WithdrawalDays(days: final int d) => '${w.target.key} $d',
                        WithdrawalNotApplicable() =>
                          '${w.target.key} ${l10n.treatmentsNotApplicable}',
                        WithdrawalNotRecorded() => '${w.target.key} ${l10n.treatmentsNoWithdrawal}',
                      },
                      key: Key('treatment.repeat.previous_days.${w.target.key}'),
                      style: text.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: t.gapMin / 4),
                  // **THE PROVENANCE TRAVELS WITH THE FIGURE, NEVER WITHOUT
                  // IT** — and only where there IS one. The stamp beside *not
                  // recorded* would be claiming an entry nobody made.
                  //
                  // Its words are not written here, and could not be:
                  // `disclaimer_is_referenced_test` scans this feature for the
                  // constant's VALUE and caught the first draft of this comment
                  // for quoting it. The seventeenth prohibition this project has
                  // caught matching itself.
                  if (w.period is WithdrawalDays)
                    const Flexible(child: WithdrawalProvenanceStamp()),
                ],
              ),
            ),
          SizedBox(height: t.gapMin),
          for (final DeckEntry e in candidates)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
              child: ShedTapTarget(
                key: Key('treatment.repeat.animal.${e.tag}'),
                semanticLabel: l10n.treatmentsRepeatOnto(tag: e.tag),
                minSize: t.tapPrimary,
                // THE SECOND AND LAST TAP. No confirmation step.
                onTap: () => onPicked(e.eweId),
                child: ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.treatmentsRepeatOnto(tag: e.tag), style: text.bodyMedium),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One running withdrawal, as `indelible.md §7.6` draws it.
///
/// ```
///  77   ALAMYCIN LA · CLEARS 12 AUG 2026        │ │ │ │ │ │ │ │ │      9d
/// ```
///
/// **THE COUNTDOWN IS `ShedCountdown` AND ITS ARGUMENT IS A `ClearsOn`.** That
/// is `10 §5.2`'s one place where the compiler is the gate: the component takes
/// the sealed *outcome* and never a `WithdrawalStatus`, so a countdown for a
/// period nobody recorded is unconstructible rather than merely forbidden.
/// `NOT APPLICABLE` and `NOT RECORDED` are painted by [_BookLine], in words,
/// with no countdown widget anywhere in the tree.
///
/// **THE ROW IS `kRuledRowTall` AND READ-ONLY.** §7.6 gives the countdown an
/// 88 px row; `07 §10.4` gives *open the animal* one tap and there is no route
/// from here to the ewe card yet, so the row carries no `onTap` rather than a
/// handler that does nothing. A read-only row is not wrapped in a target at all,
/// which is what keeps the 60 pt gate measuring only things a thumb can press.
class _CountdownLine extends StatelessWidget {
  const _CountdownLine({
    required this.row,
    required this.withdrawal,
    required this.clearDate,
    required this.now,
    required this.locale,
    required this.l10n,
  });

  final TreatmentRow row;
  final StoredWithdrawal withdrawal;

  /// **THE STORED DATE, PASSED IN.** Never recomputed here — that is decision
  /// #50's whole point, and a recomputation would answer differently after the
  /// device moved timezone, on the one number that matters.
  final LocalDate clearDate;

  final Instant now;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final String tag = row.animalTag ?? l10n.treatmentsUntagged;
    final String target = switch (withdrawal.target) {
      WithdrawalTarget.meat => l10n.withdrawalTargetMeat,
      WithdrawalTarget.milk => l10n.withdrawalTargetMilk,
    };
    final String date = formatShedDate(clearDate, locale);

    return ShedRuledRow(
      height: kRuledRowTall,
      child: _RecordColumn(
        children: <Widget>[
          // WHO, AND WHICH TARGET. The target is spelled on every countdown
          // because one product routinely prints two figures, and a number with
          // no target named is a number that can be applied to the wrong one.
          Text(
            l10n.treatmentsCountdown(tag: tag, target: target),
            key: Key('treatments.countdown.${row.id.value}.${withdrawal.target.key}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ShedCountdown(
            key: Key('treatments.clears.${row.id.value}.${withdrawal.target.key}'),
            // `elapsesAt` IS DERIVED FROM THE STORED INPUTS, NOT FROM THE STORED
            // DATE. `clearDateFor` is the one place that arithmetic lives
            // (`05 §3.5`), and calling it here for its instant while keeping the
            // stored `date` is the honest split: the date is what the shepherd
            // was told, the instant is what it was computed from, and both came
            // off the same two columns that live beside each other for ever.
            clearsOn: ClearsOn(
              clearDate,
              clearDateFor(administeredAt: row.administeredAt, days: withdrawal.days!).elapsesAt,
              withdrawal.target,
            ),
            now: now,
            productName: row.productName,
            clearsOnLabel: l10n.treatmentsClears(date: date),
            semanticLabel: l10n.treatmentsCountdownSemantics(
              tag: tag,
              target: target,
              product: row.productName,
              date: date,
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the medicine book — **and the only place the three withdrawal
/// states are told apart in words.**
///
/// The line under the row used to read `earliestClearDate == null ? NO
/// WITHDRAWAL RECORDED : CLEARS (the date)`, which printed one sentence for two
/// different facts. A shepherd who read the bottle and chose NONE APPLIES saw
/// the words for a gap nobody had filled. `10 §5.2` splits them and names both
/// words, and the split is exactly §12.1's: *nothing applies* is something
/// somebody read, *not recorded* is nobody having looked.
///
/// **THE MARGIN CELL IS EMPTY AND THAT IS A FINDING, NOT A CHOICE.** `§4.3` puts
/// the time and its provenance stamp in the 68 pt gutter and `07 §10.1`'s
/// printed statement selects `captured_at`, `original_effective` and
/// `time_source` for exactly that; the statement that shipped selects neither,
/// and `TreatmentRow` carries no provenance. A time printed with no stamp is a
/// §12.5 claim nobody can check, and stamping `AUTO` on a source this row does
/// not know would be inventing one. So the gutter stays empty until the
/// statement carries the quad.
class _BookLine extends StatelessWidget {
  const _BookLine({
    required this.row,
    required this.locale,
    required this.l10n,
    required this.onVoid,
  });

  final TreatmentRow row;
  final String locale;
  final AppLocalizations l10n;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool voided = row.voidedAt != null;

    return ShedRuledRow(
      height: kRuledRowTall,
      // DIMS THE ROW'S RULE AND NOTHING ELSE. The strike itself is the line
      // through the text below — a struck row keeps its position, its
      // legibility and its place in the order; this only stops its boundary
      // shouting louder than its content.
      struck: voided,
      child: _RecordColumn(
        children: <Widget>[
          Text(
            <String>[
              row.animalTag ?? l10n.treatmentsUntagged,
              row.productName,
              formatShedDate(LocalDate.of(row.administeredAt), locale),
            ].join(' · '),
            key: Key('treatments.row.${row.id.value}'),
            style: text.bodyLarge?.copyWith(
              // STRUCK, NOT REMOVED. The row stays in the book because it may
              // already be printed in one somebody is holding.
              decoration: voided ? TextDecoration.lineThrough : null,
              decorationThickness: voided ? 2 : null,
              color: voided ? t.textSecondary : t.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // **THE VOID, WHICH `voidTreatment` HAD NO CALLER FOR.** `07 §10.4`
          // gives it two taps and the repository landed it at N20-T05 with its
          // own tests; the book could show a void and could not make one, so a
          // treatment recorded against the wrong ewe stayed in the medicine
          // book with its withdrawal running.
          //
          // **A SOFT VOID, AND THE ROW STAYS.** Nothing is removed from this
          // book — the row may already be printed in one somebody is holding —
          // so the word is `void` and never `delete`. The only two honest
          // deletes in the product are in Settings.
          if (!voided)
            Align(
              alignment: Alignment.centerLeft,
              child: ShedWordButton(
                key: Key('treatments.void.${row.id.value}'),
                label: l10n.treatmentsVoid,
                semanticLabel: l10n.treatmentsVoid,
                selected: false,
                onTap: onVoid,
              ),
            ),
          if (row.voidedAt case final Instant at)
            Text(
              l10n.treatmentsVoided(date: formatShedDate(LocalDate.of(at), locale)),
              key: Key('treatments.voided.${row.id.value}'),
              style: text.bodySmall?.copyWith(color: t.statusAttention),
            )
          // NO ROW AT ALL IS THE `WithdrawalUnknown` CASE, and it says so. There
          // is no third line anywhere saying she is clear: leaving a countdown
          // is not the same as claiming a negative.
          else if (row.withdrawals.isEmpty)
            Text(
              l10n.treatmentsNoWithdrawal,
              key: Key('treatments.clears.${row.id.value}'),
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            )
          else
            for (final StoredWithdrawal w in row.withdrawals)
              Text(
                // `days == null` IS `not_applicable` UNDER THE SCHEMA'S OWN
                // CHECK — `CHECK ((kind = 'days') = (days IS NOT NULL))` — so no
                // fourth field is needed to tell the two apart, and there is no
                // way to construct a `StoredWithdrawal` that means both.
                w.clearDate == null
                    ? l10n.treatmentsNotApplicable
                    : l10n.treatmentsClears(date: formatShedDate(w.clearDate!, locale)),
                key: Key('treatments.clears.${row.id.value}.${w.target.key}'),
                style: text.bodySmall?.copyWith(color: t.textSecondary),
              ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.id,
    required this.word,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String word;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: word,
        minSize: t.tapIndelible,
        onTap: onTap,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? t.textPrimary : t.outline,
                  width: selected ? t.outlineWidth * 2 : t.outlineWidth,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Center(
                child: Text(
                  word,
                  style: selected ? text.titleMedium : text.bodyMedium,
                  maxLines: 1,
                  // ELLIPSISED, NEVER SHRUNK. A shrink-to-fit widget is banned
                  // (10 §4.4).
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
