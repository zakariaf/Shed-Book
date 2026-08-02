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

class _Card extends StatelessWidget {
  const _Card({required this.data, required this.units});

  final LambCardData data;
  final WeightUnit units;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();

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
