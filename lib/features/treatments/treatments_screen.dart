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
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/features/treatments/treatments_controller.dart';
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

    // THE PREVIOUS TREATMENT IS ALREADY IN THE LIST. The countdown excludes
    // voided rows, which is exactly the filter *repeat last* wants — so there is
    // nothing to look up beyond its stored periods.
    final List<TreatmentRow> live =
        ref.watch(treatmentsProvider(TreatmentMode.countdown)).value ?? const <TreatmentRow>[];
    final TreatmentRow? previous = live.isEmpty ? null : live.first;
    final List<StoredWithdrawal> stored = previous == null
        ? const <StoredWithdrawal>[]
        : ref.watch(storedWithdrawalsProvider(previous.id)).value ?? const <StoredWithdrawal>[];
    final QuickEntryDeck? deck = ref.watch(quickEntryDeckProvider).value;
    final List<DeckEntry> candidates = <DeckEntry>[...?deck?.penned, ...?deck?.recents];

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
            if (rows.isEmpty)
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
                    children: <Widget>[
                      // THE EMPTY STATE IS *OUTSIDE* THIS SCROLL VIEW — see the
                      // `if (rows.isEmpty)` arm above. `ShedEmptyState` is
                      // `double.infinity` in both axes, and a scroll view gives
                      // its child an UNBOUNDED height where infinity is an error
                      // rather than a maximum.
                      for (final TreatmentRow row in rows)
                        _TreatmentLine(row: row, locale: locale, l10n: l10n),
                    ],
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
                key: const Key('treatments.repeat_last'),
                label: l10n.treatmentsRepeatLast,
                semanticLabel: l10n.treatmentsRepeatLast,
                onTap: () => _openRepeat(context, ref, l10n, previous, stored, candidates),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    TreatmentRow? previous,
    List<StoredWithdrawal> stored,
    List<DeckEntry> candidates,
  ) {
    if (previous case final TreatmentRow entry) {
      unawaited(
        showRepeatSheet(
          context,
          child: _RepeatSheet(
            previous: entry,
            stored: stored,
            candidates: candidates,
            l10n: l10n,
            onPicked: (EweId ewe) {
              unawaited(
                ref.read(treatmentRepositoryProvider).repeatTreatment(entry.id, TreatEwe(ewe)),
              );
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
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
    required this.stored,
    required this.candidates,
    required this.l10n,
    required this.onPicked,
  });

  final TreatmentRow previous;
  final List<StoredWithdrawal> stored;
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
          for (final StoredWithdrawal w in stored)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      '${w.days ?? ''}',
                      key: const Key('treatment.repeat.previous_days'),
                      style: text.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: t.gapMin / 4),
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

class _TreatmentLine extends StatelessWidget {
  const _TreatmentLine({required this.row, required this.locale, required this.l10n});

  final TreatmentRow row;
  final String locale;
  final AppLocalizations l10n;

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
          if (row.voidedAt case final Instant at)
            Text(
              l10n.treatmentsVoided(date: formatShedDate(LocalDate.of(at), locale)),
              key: Key('treatments.voided.${row.id.value}'),
              style: text.bodySmall?.copyWith(color: t.statusAttention),
            )
          else
            Text(
              // THE STORED CLEAR DATE, OR THE ABSENCE SAID OUT LOUD. There is no
              // third line saying she is clear.
              row.earliestClearDate == null
                  ? l10n.treatmentsNoWithdrawal
                  : l10n.treatmentsClears(date: formatShedDate(row.earliestClearDate!, locale)),
              key: Key('treatments.clears.${row.id.value}'),
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
