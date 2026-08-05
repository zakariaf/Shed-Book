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
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_countdown.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
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
import 'package:shed_book/l10n/app_localizations.dart';

class TreatmentsScreen extends ConsumerWidget {
  const TreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
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
    // `rows.isEmpty` there would paint a scroll view with nothing in it instead
    // of the empty state.
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

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: ShedSectionHeading(
                key: const Key('treatments.title'),
                label: l10n.treatmentsTitle,
                level: 1,
              ),
            ),
            // THE TWO SEGMENTS. Word buttons, not a segmented control —
            // `indelible.md §7.9`: there is no segmented control, because there
            // is no radius and no container in this system.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Row(
                children: <Widget>[
                  for (final ({TreatmentMode value, String word}) segment
                      in <({TreatmentMode value, String word})>[
                        (value: TreatmentMode.countdown, word: l10n.treatmentsModeCountdown),
                        (value: TreatmentMode.book, word: l10n.treatmentsModeBook),
                      ])
                    // FLEXIBLE, AND MEASURED. Two words plus their gaps came to
                    // 124 px over on a 375 pt phone at 200% text — the segments
                    // are the widest fixed thing on the screen, and they are the
                    // one part that can give without losing a fact.
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
            ),
            // AN EMPTY LIST HAS NOTHING TO SCROLL, so the empty state replaces
            // the scroll view rather than sitting in it — which is also the only
            // place `ShedEmptyState`'s infinite sizing is valid. Measured:
            // inside, every treatments case threw `BoxConstraints forces an
            // infinite height`.
            if (lines.isEmpty)
              Flexible(
                child: ShedEmptyState(
                  key: const Key('treatments.empty'),
                  copy: l10n.treatmentsEmpty,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // THE EMPTY STATE IS *OUTSIDE* THIS SCROLL VIEW — see the
                    // `if (lines.isEmpty)` arm above. `ShedEmptyState` is
                    // `double.infinity` in both axes, and a scroll view gives
                    // its child an UNBOUNDED height where infinity is an error
                    // rather than a maximum.
                    children: lines,
                  ),
                ),
              ),
            // THE FOOTER BELONGS TO THE MODE, NOT TO THE LIST — which is what
            // moving the empty state out of the scroll view exposed: it had been
            // sitting inside the list's Column, so an EMPTY book rendered no
            // disclosure at all. The one view somebody might print or hand to a
            // vet was the one that could lose its §12.3 footer.
            //
            // Still on the first painted frame of book mode, never behind an
            // affordance.
            if (mode == TreatmentMode.book) const TreatmentBookFooter(),
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              // `indelible.md:973` names this control: "REPEAT LAST TREATMENT
              // is a prominent word button", and §7.13 puts a primary at
              // `--t-ctl-lg` 22px. The hand-rolled version used `titleMedium`,
              // which is not that role.
              child: ShedPrimaryButton(
                key: const Key('treatments.new'),
                label: l10n.treatmentNewTitle,
                semanticLabel: l10n.treatmentNewTitle,
                onTap: () => _openNew(context, ref, l10n, candidates),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
              child: ShedPrimaryButton(
                key: const Key('treatments.repeat_last'),
                label: l10n.treatmentsRepeatLast,
                semanticLabel: l10n.treatmentsRepeatLast,
                onTap: () => _openRepeat(context, ref, l10n, candidates),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  /// Everything it renders is ALREADY LOADED, by the `ref.watch`es in `build`
  /// above — `treatmentsProvider` for the previous treatment and
  /// `storedWithdrawalsProvider` for its periods. The handler opens a sheet and
  /// nothing else.
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
Future<void> showRepeatSheet(BuildContext context, {required Widget child}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showShedBottomSheet<void>(
    context,
    dismissLabel: l10n.colostrumSheetClose,
    dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
    barrierLabel: l10n.treatmentsRepeatLast,
    fillsViewport: true,
    child: child,
  );
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            <String>[
              row.animalTag ?? l10n.treatmentsUntagged,
              row.productName,
              formatShedDate(LocalDate.of(row.administeredAt), locale),
            ].join(' · '),
            key: Key('treatments.row.${row.id.value}'),
            style: text.bodyMedium?.copyWith(
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
