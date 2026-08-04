// lib/features/flock/widgets/ewe_summary_line.dart
//
// **THE RETENTION FEATURE, IN ONE LINE.** *"3 seasons · avg 2.0 · assisted twice
// · prolapsed 2025."* Spec §7.7 says it must be visible before anything else,
// and `00-README` §9 calls it the reason the product exists in year two.
//
// **ASSEMBLED IN DART FROM COUNTS, NEVER READ AS A STORED STRING.** `03 §5.13`
// forbids the obvious performance fix — `UPDATE ewe_summaries SET line` at write
// time — because a frozen string is wrong the moment the terminology changes,
// the units change, the locale changes, or a record is corrected. There is no
// column to store one in, and `EweSummaryCounts` has nowhere to put one either.
//
// It is also the one place in the app where four clauses of arithmetic sit one
// character away from becoming veterinary advice: §12.2's origination line binds
// every word. Four counts in, four clauses out, no judgement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart' show VocabEntry;
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class EweSummaryLine extends ConsumerWidget {
  const EweSummaryLine({required this.eweId, required this.tag, super.key});

  final EweId eweId;

  /// Exactly as typed (§12.4). The heading prints it beside the shepherd's own
  /// noun for the animal.
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **`terminologyProvider` IS A `Provider`, NOT A `StreamProvider`** (R68) —
    // it derives from `settingsProvider`, and watching that directly here would
    // put a second `AsyncValue` on the screen for no gain. `07 §1.2` permits the
    // singletons precisely so the screen does not have to.
    //
    // **`overrideFor`, NOT `labelFor`, AND THE DIFFERENCE IS A CRASH.** The
    // provider is `const Terminology({}, {})` until N29 wires the defaults in
    // from the ARB, so `labelFor` ends in `_defaults[c]!` and throws — which is
    // exactly what the first draft of this widget did, rendering the card's
    // heading as an error box while the timeline below it worked perfectly.
    // `lambing_entry_screen.dart` records the same trap.
    //
    // So the default is read here, from the `term*Singular` / `term*Plural`
    // messages that ARE the sanctioned source (`10 §8.6`), and the overlay is
    // consulted only for a rename. One grep — this call — when N29 lands.
    final TermLabel term =
        ref.watch(terminologyProvider).overrideFor(AnimalClass.ewe) ??
        TermLabel(l10n.termEweSingular, l10n.termEwePlural);

    final EweSummaryFacts facts = eweSummaryFacts(switch (ref.watch(eweSummaryProvider(eweId))) {
      AsyncData<EweSummaryCounts?>(value: final EweSummaryCounts? c) => c,
      _ => null,
    }, newestObservation: _newestObservation(ref));

    final List<String> clauses = _clauses(context, ref, l10n, facts);

    return Padding(
      key: const Key('ewe_card.summary'),
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            headingLevel: 1,
            child: Text(
              l10n.eweCardTitle(singularTerm: term.singular, tag: tag),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          SizedBox(height: t.gapMin / 2),
          // **ONE `Text` AND ONE SEMANTICS NODE, NOT FOUR SIBLINGS.** Four nodes
          // is four rotor stops in front of the one line the whole screen exists
          // to deliver (`10 §3.4`). The middle dot separates it visually and a
          // screen reader swallows it, so the spoken form joins on a full stop.
          //
          // **IT WRAPS; IT DOES NOT TRUNCATE.** `10 §5`: a user's own words are
          // never ellipsised, and the whole line is the payload. No `maxLines`,
          // no overflow, nothing that scales the glyphs down to fit.
          Semantics(
            label: l10n.eweCardSummarySemantics(clauses: clauses.join('. ')),
            child: ExcludeSemantics(
              child: Text(clauses.join(' · '), style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  /// The clauses that are **true**, in order. An absent clause is absent — never
  /// a blank, never a zero.
  List<String> _clauses(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    EweSummaryFacts facts,
  ) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final List<String> out = <String>[l10n.eweCardSummarySeasons(count: facts.seasonsRecorded)];

    // **DROPPED, NOT ZEROED** (`05 §6.5`). A ewe with one lambing and no lambs
    // recorded yet is a common transient state — the row is created on screen
    // entry (#11) — and `avg 0.0` would be the app asserting something false
    // about a live animal.
    if (facts.averageLitterSize case final double avg) {
      out.add(l10n.eweCardSummaryAverage(average: formatShedAverage(avg, locale)));
    }

    // **ABSENT WHEN NOTHING IS SCORED, AND `notComputable` IS NOT `0`**
    // (`05 §6.7`). When some lambings are scored and some are not, the coverage
    // is APPENDED rather than the clause omitted: a blank ease read as
    // *unassisted* deflates the number, which is the silent inference §12.4
    // forbids.
    if (facts.assistedIsComputable) {
      final String assisted = l10n.eweCardSummaryAssisted(count: facts.assistedLambings);
      out.add(
        facts.assistedCoverageIsPartial
            ? '$assisted ${l10n.eweCardSummaryAssistedCoverage(scored: facts.scoredLambings)}'
            : assisted,
      );
    }

    // **WHAT WAS OBSERVED, NEVER A CONSEQUENCE.** *"prolapsed 2025"* is a
    // record; *"prolapse risk"* is a diagnosis. The label is the shepherd's —
    // `vocab_terms.label` when they have renamed it, the shipped ARB default
    // when `NULL` (R66) — and it is resolved here, at the presentation edge,
    // because `lib/domain/` and `lib/data/` may not reach `AppLocalizations`.
    final String? kind = facts.lastObservationKind;
    final int? year = facts.lastObservationYear;
    if (kind != null && year != null) {
      out.add(
        l10n.eweCardSummaryObservation(
          observation: _observationLabel(ref, l10n, kind),
          year: formatShedCount(year, locale),
        ),
      );
    }

    return out;
  }

  /// The newest `observed` row on the timeline this screen is **already
  /// watching**.
  ///
  /// `ewe_summaries` stores `last_observation_season` — a season foreign key,
  /// not a kind — so this clause has no column behind it and adding one would be
  /// a migration. No second statement, no new column, no violation of the
  /// one-query rule.
  ({String kind, int year})? _newestObservation(WidgetRef ref) {
    final List<TimelineRow> rows = switch (ref.watch(eweTimelineProvider(eweId))) {
      AsyncData<List<TimelineRow>>(value: final List<TimelineRow> r) => r,
      _ => const <TimelineRow>[],
    };
    // The timeline is already ordered most recent first, so the first match is
    // the newest — no second sort, and no assumption that one is needed.
    for (final TimelineRow r in rows) {
      if (r.kind == TimelineKind.observed) {
        // **THE YEAR OF THE SEASON, NOT THE YEAR OF THE INSTANT.** A season is a
        // stored foreign key; an observation recorded at 01:30 on the
        // clocks-back night belongs to the season it was filed under, whatever
        // the wall clock did that night.
        // **BOTH OR NEITHER.** The clause names *what* and *when*, and half of
        // it is not a shorter clause — it is a different, vaguer claim. An
        // observation whose season or kind did not come back is skipped rather
        // than printed with a gap.
        final String? kind = r.detail;
        final int? year = r.seasonYear;
        if (kind == null || year == null) {
          continue;
        }
        return (kind: kind, year: year);
      }
    }
    return null;
  }

  String _observationLabel(WidgetRef ref, AppLocalizations l10n, String key) {
    // `.value ?? const []` and not the accessor that throws: the vocabulary
    // arrives one frame after the first paint, and an empty list renders the
    // shipped defaults — which is exactly right. A rename the shepherd has not
    // loaded yet is not a reason to show nothing.
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
    // **THE SHIPPED DEFAULT IS LOOKED UP BY KEY, NOT ASSUMED.** Six seeded
    // observation keys exist and the shepherd may add more; a `switch` that fell
    // through to one of them would print *"Prolapse"* against a term somebody
    // typed themselves.
    return vocabLabel(userLabel, _shippedObservation(l10n, key) ?? key);
  }

  /// The six seeded `ewe_observation` defaults. A key with no row here is a term
  /// the shepherd added, and its own label is the only thing that could render
  /// it — which is why the caller falls back to the key rather than to a word
  /// this app chose.
  String? _shippedObservation(AppLocalizations l10n, String key) => switch (key) {
    'obs_prolapse' => l10n.vocabObsProlapse,
    'obs_mastitis' => l10n.vocabObsMastitis,
    'obs_poor_mothering' => l10n.vocabObsPoorMothering,
    'obs_good_mothering' => l10n.vocabObsGoodMothering,
    'obs_no_milk' => l10n.vocabObsNoMilk,
    'obs_other' => l10n.vocabObsOther,
    _ => null,
  };
}
