// lib/features/flock/widgets/timeline_record_row.dart — `indelible.md §7.3`.
//
// **EVERY ROW CARRIES A PROVENANCE LABEL, AND THIS IS THE TASK WHERE §12.5
// EITHER STAYS AT *unrepresentable* OR DROPS TO *documented*.** R37 put the quad
// on all seven of these tables precisely so this screen could be honest, and
// `07 §1.5` makes the label mandatory on **every** timeline row, not on the
// interesting ones. A row that renders `03:21` with nothing beside it is a
// review failure.
//
// **THE LABEL COMES FROM `RecordedTime.provenanceLabel` AND FROM NOWHERE ELSE.**
// It is an exhaustive switch that can never be empty (`05 §4.1`). A second
// switch over `time_source` in a widget is a §12.5 mechanism reimplemented in
// the layer least likely to be reviewed, and it will disagree with the CSV
// within one release.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart' show VocabEntry;
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/features/flock/widgets/withdrawal_note.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class TimelineRecordRow extends ConsumerWidget {
  const TimelineRecordRow({required this.row, super.key});

  final TimelineRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();

    final RecordedTime recorded = row.recorded;
    final String time = formatShedTime(row.at, locale);
    final String body = _body(ref, l10n);

    // **STRUCK TEXT DIMS, IT DOES NOT VANISH.** `indelible.md §7.3`: all text
    // drops from full to low ink — 4.94:1, *"still fully legible, permanently"*.
    // The row **stays in position**: it does not move, collapse or fade, and
    // nothing sorts it to the bottom or hides it behind a toggle.
    final Color ink = row.struck ? t.textSecondary : t.textPrimary;

    return Semantics(
      // **ONE NODE PER ROW, AND ITS LABEL IS A COMPLETE SENTENCE** in the order
      // a shepherd would say it (`10 §3.2` rule 3, the Voice Control criterion).
      // Seven `Text` widgets is seven rotor stops per row and about eighty rows
      // on a five-season card.
      label: l10n.eweCardRowSemantics(time: time, body: body, provenance: recorded.provenanceLabel),
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: _marginWidth, child: _margin(context, t, l10n, time, locale, ink)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(body, style: text.bodyMedium?.copyWith(color: ink)),
                    // **`null` MEANS THE FIELD DOES NOT APPLY**, which is not the
                    // same as *not recorded*. A lambing has no withdrawal at all;
                    // a treatment always has one of three answers, and one of
                    // them is *nobody looked*.
                    if (row.withdrawal case final WithdrawalPeriod w) WithdrawalNote(period: w),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `indelible.md §4.3`'s margin cell: the time, and the provenance stamp
  /// beneath it.
  ///
  /// **THE PROVENANCE STAMP IS NOT AN EXEMPT STAMP.** `indelible.md §3.4` allows
  /// 14 px only when a stamp is never the sole carrier of its meaning, and this
  /// one is the sole statement of the §12.5 claim — so it renders at the 18 px
  /// floor, in the `labelMedium` role rather than the stamp role. Shortening the
  /// label to make it fit is not the fix: the three strings are `05 §4.1`'s and
  /// they are what the export legend and the CSV `time_source` column are read
  /// against.
  Widget _margin(
    BuildContext context,
    ShedTokens t,
    AppLocalizations l10n,
    String time,
    String locale,
    Color ink,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final RecordedTime recorded = row.recorded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(time, style: text.labelMedium?.copyWith(color: ink)),
        Text(recorded.provenanceLabel, style: text.labelMedium?.copyWith(color: t.textSecondary)),
        // **AN EDITED ROW SHOWS BOTH TIMES, NEVER A MARKER ALONE** (`05 §4.3`).
        // The paired SQL `CHECK` exists precisely so the pre-edit value is always
        // there to show; omitting it makes the §12.5 label true and
        // uninformative — it says the time was edited and loses what it was
        // edited from.
        if (recorded.originalEffective case final Instant was)
          Text(
            l10n.eweCardRowEditedFrom(time: formatShedTime(was, locale)),
            style: text.labelMedium?.copyWith(color: t.textSecondary),
          ),
        // **`STRUCK 03:41`, AND THE ROW STAYS.** Three channels, none of them
        // colour alone: the stamp, the dimmed ink, and the rule the list draws.
        if (row.struckAt case final Instant at)
          Text(
            l10n.eweCardRowStruck(time: formatShedTime(at, locale)),
            style: text.labelMedium?.copyWith(color: t.textSecondary),
          ),
      ],
    );
  }

  /// The record column's sentence, per arm.
  ///
  /// **EXHAUSTIVE OVER `TimelineKind`, NO `default:`.** An arm added to the
  /// statement must fail to compile here rather than render as a blank row.
  String _body(WidgetRef ref, AppLocalizations l10n) {
    final String detail = row.detail ?? '';
    return switch (row.kind) {
      TimelineKind.lambing => l10n.eweCardRowLambing,
      TimelineKind.treatment => l10n.eweCardRowTreatment(product: detail),
      TimelineKind.care => l10n.eweCardRowCare(kind: detail),
      TimelineKind.foster => l10n.eweCardRowFoster,
      // The shepherd's own word for it when they have renamed the term (R66).
      TimelineKind.observed => l10n.eweCardRowObserved(observation: _vocab(ref, detail, l10n)),
      TimelineKind.penned => l10n.eweCardRowPenned(pen: detail),
      TimelineKind.note => l10n.eweCardRowNote(body: detail),
    };
  }

  String _vocab(WidgetRef ref, String key, AppLocalizations l10n) {
    final List<VocabEntry> vocab = switch (ref.watch(vocabProvider)) {
      AsyncData<List<VocabEntry>>(value: final List<VocabEntry> v) => v,
      _ => const <VocabEntry>[],
    };
    String? userLabel;
    for (final VocabEntry term in vocab) {
      if (term.key == key) {
        userLabel = term.label;
        break;
      }
    }
    // The key itself is the last resort, never a word this app chose: a term the
    // shepherd added has no shipped default, and printing somebody else's noun
    // against it would be the app renaming their vocabulary.
    return vocabLabel(userLabel, key);
  }

  /// `indelible.md §4.3`: the margin cell is 0–68 px, and 68 × 64 is itself a
  /// legal tap target. Named here rather than typed inline because the gate is
  /// right to fire on a bare number.
  static const double _marginWidth = 68;
}
