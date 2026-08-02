// lib/features/lambing/lamb_card_screen.dart
//
// THE SCREEN THE PRODUCT EXISTS FOR. Entry is fifteen seconds at 03:20; this is
// the other half — *"what did 412 do last year?"* takes one second instead of an
// evening with a shoebox. Everything here is READ; the four action buttons are
// this epic's later tasks.
//
// It watches ONE provider. `lib/features/` may not import the persistence
// package or the database directory at all (layer rule 5) — described rather
// than spelled, because `lamb_card_test.dart` scans this file for those very
// strings and a quoted prohibition matches itself. That layer rule is why
// `LambCardData` is declared in `lib/data/` and assembled there.
library;

import 'dart:async';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/features/lambing/widgets/lamb_sex_row.dart';
import 'package:shed_book/features/lambing/widgets/lamb_weight_cell.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/validation/lambing_checks.dart';
import 'package:shed_book/features/lambing/widgets/death_date_cell.dart';
import 'package:shed_book/features/lambing/widgets/lamb_status_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/features/lambing/lamb_card_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class LambCardScreen extends ConsumerWidget {
  const LambCardScreen({required this.lambId, super.key});

  final LambId lambId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<LambCardData> data = ref.watch(lambCardProvider(lambId));

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Semantics(
                headingLevel: 1,
                child: Text(
                  switch (data) {
                    // THE TAG IS THE HEADING WHEN THERE IS ONE. A lamb without a
                    // tag is not a lamb without an identity — it is a lamb whose
                    // ear is still bare, which is most lambs for most of their
                    // first week.
                    AsyncData<LambCardData>(value: final LambCardData d) =>
                      d.tag ?? l10n.lambCardUntagged,
                    _ => l10n.lambCardUntagged,
                  },
                  key: const Key('lamb_card.title'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: switch (data) {
                AsyncData<LambCardData>(value: final LambCardData d) => _Card(
                  data: d,
                  units: ref.watch(unitsProvider),
                ),
                // NO SPINNER (`07 §1.4`). The shepherd reached this card by
                // tapping a row that already existed; a spinner would say the
                // lamb might not.
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.data, required this.units});

  final LambCardData data;
  final WeightUnit units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final LambingWriteController write = ref.read(lambingWriteControllerProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // THE SUMMARY — sex, status, weight — on one ellipsised line, for the
          // same reason the lamb sub-row is one line: five cells with separators
          // between them cannot share a 375 pt row at 200% text.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(
              <String>[
                if (data.sex case final Sex s) _sexWord(s, l10n) else l10n.careNotRecorded,
                _statusWord(data.status, l10n),
                if (data.birthWeight case final Grams g)
                  formatShedWeight(g, units, locale)
                else
                  l10n.careNotRecorded,
              ].join(' · '),
              key: const Key('lamb_card.summary'),
              style: text.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // THE TWO PARENTAGE ROWS, ALWAYS BOTH. On an unfostered lamb they name
          // the same ewe, and that is correct rather than redundant: the view's
          // COALESCE says the rearing dam IS the birth dam until something says
          // otherwise, and collapsing the rows would hide which fact is which.
          _Row(
            id: 'lamb_card.birth_dam',
            label: l10n.lambCardBirthDam(tag: data.rearing.birthDamTag),
          ),
          _Row(id: 'lamb_card.rearing_dam', label: _rearingLine(l10n)),
          SizedBox(height: t.gapMin),
          // SEX AND BIRTHWEIGHT (T02). Both skippable, both committing on their
          // own tap, neither ever defaulted.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(l10n.lambCardSexLabel, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: LambSexRow(
              key: const Key('lamb_card.sex'),
              sex: data.sex,
              words: (
                female: l10n.termEweLambSingular.toUpperCase(),
                male: l10n.termRamLambSingular.toUpperCase(),
                // NOT the plain animal noun here, unlike the lamb sub-row: on a
                // card that also offers *nothing recorded*, "LAMB" beside "EWE
                // LAMB" and "RAM LAMB" reads as a fourth animal rather than as a
                // third answer. The words say what the shepherd did.
                unknown: l10n.lambCardSexUnknown,
              ),
              onSelected: (Sex? s) => write.setLambSex(data.lambId, s),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(l10n.lambCardWeightLabel, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: ShedTapTarget(
              key: const Key('lamb_card.weight'),
              semanticLabel: l10n.lambCardWeightLabel,
              minSize: t.tapIndelible,
              onTap: () => _openWeightSheet(context, write, l10n),
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.birthWeight == null
                        ? l10n.lambCardWeightUnset
                        : formatShedWeight(data.birthWeight!, units, locale),
                    style: data.birthWeight == null
                        ? text.bodySmall?.copyWith(color: t.textSecondary)
                        : text.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          // STATUS AND, WHEN IT IS NOT ALIVE, THE DEATH DETAIL (T03).
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(l10n.lambCardStatusLabel, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: LambStatusRow(
              key: const Key('lamb_card.status'),
              status: data.status,
              words: (
                alive: l10n.lambStatusAlive,
                dead: l10n.lambStatusDead,
                stillborn: l10n.lambStatusStillborn,
              ),
              onSelected: (LambStatus s) {
                if (s == LambStatus.alive) {
                  // BACK TO ALIVE CLEARS THE DATE AND THE CAUSE WITH IT. A lamb
                  // that is alive is not a lamb that is alive and died on
                  // Tuesday, and the CHECK refuses that row anyway.
                  write.clearDeath(data.lambId);
                } else {
                  write.recordDeath(
                    data.lambId,
                    status: s,
                    // THE DATE IS NOT INVENTED. Choosing *dead* records the
                    // status and leaves the date unrecorded until the shepherd
                    // says which day — defaulting it to today would be the app
                    // answering a question they have not been asked yet.
                    deathDate: data.deathDate,
                    bornOn: data.bornLocalDate,
                    causeKey: data.deathCauseKey,
                  );
                }
              },
            ),
          ),
          // THE DEATH DETAIL APPEARS ONLY WHEN THERE IS A DEATH. It is not
          // hidden-when-alive as a tidiness measure: a date field on a living
          // lamb is a field that can be filled in, and the CHECK would then
          // refuse the write at 03:20.
          if (data.status != LambStatus.alive) ...<Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
              child: Text(l10n.lambCardDeathDateLabel, style: text.labelMedium),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: DeathDateCell(
                key: const Key('lamb_card.death_date'),
                today: LocalDate.of(appNow()),
                selected: data.deathDate,
                labels: (
                  today: l10n.lambCardDeathDateToday,
                  yesterday: l10n.lambCardDeathDateYesterday,
                  twoDaysAgo: l10n.lambCardDeathDateTwoDaysAgo,
                  formatted: (LocalDate d) => formatShedDate(d, locale),
                ),
                onPicked: (LocalDate picked) => write.recordDeath(
                  data.lambId,
                  status: data.status,
                  deathDate: picked,
                  bornOn: data.bornLocalDate,
                  causeKey: data.deathCauseKey,
                ),
              ),
            ),
            // THE WARNING RENDERS BENEATH THE FIELD THAT OWNS IT, and it never
            // gates anything: the date above is already committed.
            if (data.deathDate != null &&
                checkLambDeath(deathDate: data.deathDate, bornOn: data.bornLocalDate).isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
                child: Text(
                  l10n.warningDeathBeforeBirth,
                  key: const Key('lamb_card.warning.death_before_birth'),
                  style: text.bodySmall?.copyWith(color: t.statusAttention),
                ),
              ),
          ],
          // ON THE BOTTLE, AND THE FEEDS (T04).
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(l10n.lambCardPetLambLabel, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Row(
              children: <Widget>[
                // FLEXIBLE, AND MEASURED — the toggle, the count and the `+`
                // came to 32 px over on a 375 pt phone. The toggle's own word is
                // the one that can give: the section label above it already says
                // what this row is, so an ellipsis here costs nothing that is
                // not already on screen.
                Flexible(
                  child: Semantics(
                    selected: data.petLamb,
                    child: ShedTapTarget(
                      key: const Key('lamb_card.pet_lamb'),
                      semanticLabel: l10n.lambCardPetLambLabel,
                      minSize: t.tapIndelible,
                      onTap: () => write.setPetLamb(data.lambId, petLamb: !data.petLamb),
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: data.petLamb ? t.textPrimary : t.outline,
                                width: data.petLamb ? t.outlineWidth * 2 : t.outlineWidth,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                            child: Center(
                              child: Text(
                                l10n.lambCardPetLambLabel,
                                style: data.petLamb ? text.titleMedium : text.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.gapMin),
                // THE COUNT IS ONLY MEANINGFUL ONCE SHE IS ON THE BOTTLE.
                // `bottle_feeds` has DEFAULT 0, and that 0 means *no feeds
                // recorded* — `pet_lamb` is what says whether the number means
                // anything. A confident `0` on a lamb nobody bottle-fed would be
                // the app originating a number the shepherd never pressed.
                Flexible(
                  child: Text(
                    data.petLamb ? '${data.bottleFeeds}' : l10n.lambCardFeedsUnset,
                    key: const Key('lamb_card.feeds'),
                    style: data.petLamb
                        ? text.bodyMedium
                        : text.bodySmall?.copyWith(color: t.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data.petLamb) ...<Widget>[
                  SizedBox(width: t.gapMin),
                  ShedTapTarget(
                    key: const Key('lamb_card.feeds.add'),
                    semanticLabel: l10n.lambCardFeedsAddSemantics,
                    minSize: t.tapIndelible,
                    // NO MINUS. A feed that happened cannot un-happen, and a
                    // decrement would be an undo for an event rather than a
                    // correction of a value.
                    onTap: () => write.addBottleFeed(data.lambId),
                    child: ExcludeSemantics(
                      child: Center(child: Text(l10n.lambCardFeedsAdd, style: text.displaySmall)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: t.gapMin),
          // THE HISTORY. Never empty — the `born` arm always yields one row —
          // so the "nothing else" line is about everything AFTER the birth.
          for (final LambHistoryRow row in data.history)
            _Row(
              id: 'lamb_card.history.${row.kind}.${row.ref}',
              label: '${_kindWord(row.kind, l10n)} ${formatShedTime(row.at, locale)}',
              // THE PROVENANCE TRAVELS WITH EVERY ROW. It is why the §12.5
              // triple is on every arm of the union: a history list showing four
              // kinds of event and a bare time for each would be the one screen
              // where the claim quietly stops being true.
              trailing: row.time.provenanceLabel,
            ),
          if (data.history.length == 1)
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Text(
                l10n.lambCardNothingElseRecorded,
                key: const Key('lamb_card.nothing_else'),
                style: text.bodySmall?.copyWith(color: t.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  /// The keypad sheet. The conversion to grams happens inside it, at the widget
  /// boundary, because `WeightUnit` is a display choice (R68) and the column is
  /// canonical grams (#42).
  void _openWeightSheet(BuildContext context, LambingWriteController write, AppLocalizations l10n) {
    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.colostrumSheetClose,
        dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
        barrierLabel: l10n.lambCardWeightLabel,
        fillsViewport: true,
        child: LambWeightSheet(
          units: units,
          labels: (
            heading: l10n.lambCardWeightLabel,
            unitSuffix: switch (units) {
              WeightUnit.kg => l10n.lambCardWeightUnitKg,
              WeightUnit.lb => l10n.lambCardWeightUnitLb,
            },
            confirmLabel: l10n.colostrumRecord,
            confirmSemanticLabel: l10n.lambCardWeightLabel,
            padLabel: l10n.lambCardWeightLabel,
            backspaceLabel: l10n.keypadBackspace,
            backspaceHint: l10n.hintDeleteLastDigit,
          ),
          onRecord: (Grams g) {
            write.setBirthWeight(data.lambId, g);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// **THE TWO REASONS A REARING DAM CAN BE ABSENT ARE NEVER ONE STRING**
  /// (`07 §7.2`). A lamb on the bottle and a lamb whose rearing dam was not
  /// recorded are different facts, and merging them would have the app claim a
  /// bottle feed nobody wrote down.
  String _rearingLine(AppLocalizations l10n) {
    if (data.rearing.rearingDamTag case final String tag) {
      return l10n.lambCardRearingDam(tag: tag);
    }
    return switch (data.rearing.latestOutcome) {
      'to_bottle' => l10n.lambCardNoEweBottle,
      _ => l10n.lambCardNoEweNotRecorded,
    };
  }

  String _sexWord(Sex s, AppLocalizations l10n) => switch (s) {
    Sex.female => l10n.termEweLambSingular.toUpperCase(),
    Sex.male => l10n.termRamLambSingular.toUpperCase(),
    Sex.unknown => l10n.termLambSingular.toUpperCase(),
  };

  String _statusWord(LambStatus s, AppLocalizations l10n) => switch (s) {
    LambStatus.alive => l10n.lambStatusAlive,
    LambStatus.dead => l10n.lambStatusDead,
    LambStatus.stillborn => l10n.lambStatusStillborn,
    LambStatus.sold => l10n.lambStatusSold,
  };

  String _kindWord(String kind, AppLocalizations l10n) => switch (kind) {
    'born' => l10n.lambCardHistoryBorn,
    'foster' => l10n.lambCardHistoryFoster,
    'care' => l10n.lambCardHistoryCare,
    'treatment' => l10n.lambCardHistoryTreatment,
    // NOT a fallback to the raw key: a fifth arm added to the union without a
    // word here must be visible in a test, not rendered as `foster_v2`.
    _ => throw ArgumentError.value(kind, 'kind', 'not a history union arm'),
  };
}

/// A 64 px ruled line. Read-only — nothing on this card is a target yet, and the
/// four action buttons arrive with the tasks that give them verbs.
class _Row extends StatelessWidget {
  const _Row({required this.id, required this.label, this.trailing});

  final String id;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
      child: SizedBox(
        height: t.tapIndelible,
        child: Row(
          key: Key(id),
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                style: text.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing case final String tail) ...<Widget>[
              Text(' · ', style: text.bodySmall),
              Flexible(
                child: Text(
                  tail,
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
