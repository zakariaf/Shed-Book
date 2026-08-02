// lib/features/lambing/lambing_entry_screen.dart
//
// The shell. The header, the lambs region and the care region are empty regions
// today; T02 onward fills them. It exists now because the anchor test has to
// pump something, and because the route helper needs a destination.
//
// It watches ONE provider. lib/features/ may not import package:drift or
// lib/core/db/ at all (layer rule 5), which is why LambingEntryData is declared
// in lib/data/ and assembled there.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/features/lambing/widgets/ease_row.dart';
import 'package:shed_book/features/lambing/widgets/lamb_row.dart';
import 'package:shed_book/features/lambing/widgets/lamb_tally_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class LambingEntryScreen extends ConsumerWidget {
  const LambingEntryScreen({required this.lambingId, super.key});

  final LambingId lambingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<LambingEntryData> data = ref.watch(lambingEntryProvider(lambingId));

    // THE ONE LISTEN. The switch is exhaustive with no `default:` — WriteOutcome
    // is sealed with three variants, and the day a fourth lands this must fail
    // to compile rather than swallow it.
    ref.listen<WriteState>(lambingWriteControllerProvider, (WriteState? previous, WriteState next) {
      if (next case WriteDone(:final WriteOutcome outcome)) {
        switch (outcome) {
          case WriteCommitted():
            // The confirmation IS the stroke: the stream re-emits and the mark
            // appears. There is nothing else to say and no SnackBar to say it
            // in (P2).
            break;
          case WriteFailed():
            // T06's warning strip. A failure is never silence.
            break;
          case WriteRefused():
            // Unreachable: no write on this screen is gated by the cap.
            break;
        }
      }
    });

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
                  l10n.lambingEntryTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: switch (data) {
                AsyncData<LambingEntryData>(value: final LambingEntryData d) => _Regions(
                  data: d,
                  lambsLabel: l10n.lambingEntryLambs,
                  careLabel: l10n.lambingEntryCare,
                  units: ref.watch(unitsProvider),
                ),
                // NO SPINNER (07 §1.4): loading is a fixed-height placeholder or
                // it is nothing. A spinner on a screen the shepherd reached by
                // committing a row says the row might not be there.
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Regions extends StatelessWidget {
  const _Regions({
    required this.data,
    required this.lambsLabel,
    required this.careLabel,
    required this.units,
  });

  final LambingEntryData data;
  final String lambsLabel;
  final String careLabel;

  /// **Never inferred from the locale** (R68). A UK smallholder may genuinely
  /// want lb, and a wrong inference silently mislabels every weight ever
  /// recorded.
  final WeightUnit units;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ShedTokens t = context.tokens;

    // SCROLLABLE FROM T04, AND VERTICAL SCROLLING IS THE ONE TRACKED GESTURE
    // (06 §7 — the gate's own words, and every swipe ACTION stays banned).
    //
    // It was a plain Column until the ease group landed, and the ease group is
    // what made it overflow: five 72 pt buttons with their descriptions do not
    // fit under the tally on a small phone, and at 150% text scale they re-lay
    // as 3 + 2 and take another row. The measured overflow was 148 px.
    //
    // A ListView would be the reflex and it is wrong here: the regions are a
    // fixed handful, not a list, and a ListView would add lazy building and a
    // scroll controller for nothing. The trailing Expanded filler goes with the
    // change — nothing may be Expanded inside an unbounded scrollable.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(
              // The provenance travels with the time, always — it is the only
              // place §12.5's claim reaches the shepherd.
              data.lambing.time.provenanceLabel,
              key: const Key('lambing_entry.provenance'),
              style: text.bodySmall,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(
              '$lambsLabel ${data.lambs.length}',
              key: const Key('lambing_entry.lambs'),
              style: text.bodyMedium,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: LambTallyRow(lambingId: data.lambing.id, lambs: data.lambs),
          ),
          // ONE ROW PER LAMB, IN `l.id ASC` — STROKE ORDER, which is the order the
          // repository already returns and the order the tally beside it counts
          // in. 10 §5.2 groups by status on the lists that are ABOUT lambs; here
          // the ordinal must agree with the marks, and re-sorting the dead to the
          // bottom would print LAMB 3 second. If that is disputed it is a screens
          // question for N17/N27, not a local choice.
          //
          // A Column and not a ListView: a lambing is single, twins or triplets
          // in almost every case, and quintPlus is the tail. A scrollable here
          // would add a scroll gesture to a screen whose whole point is that a
          // cold thumb hits big fixed things.
          for (int i = 0; i < data.lambs.length; i++)
            LambRow(
              key: Key('lambing_entry.lamb.${data.lambs[i].id.value}'),
              labels: _labelsFor(context, data.lambs[i], i + 1),
            ),
          // UNDER THE LAMBS, ABOVE CARE. Ease is about the lambing rather than
          // about any one lamb, so it sits below the list it describes.
          EaseRow(lambingId: data.lambing.id, ease: data.lambing.ease),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(
              '$careLabel ${data.lambs.fold<int>(0, (int n, LambEntryRow l) => n + l.care.length) + data.lambingCare.length}',
              key: const Key('lambing_entry.care'),
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// The screen resolves the copy; [LambRow] renders it. See `LambRowLabels`.
  ///
  /// **THE NOUNS COME FROM THE ARB'S `term*Singular` MESSAGES, NOT FROM A
  /// LITERAL AND NOT YET FROM `terminologyProvider`.** Three things forced this,
  /// and the middle one is a gate:
  ///
  /// 1. `10 §8.5` — a domain noun varies by county, so it is never typed into a
  ///    sentence. `l10n_bootstrap_test.dart` scans every ARB value for one and
  ///    caught `"EWE {animal}"` on the first run of this task.
  /// 2. The `term<Class>Singular` / `term<Class>Plural` pair IS the sanctioned
  ///    source — the fourteen messages the placeholder is fed FROM — and reading
  ///    them here is what `05 §8`'s bootstrap will do when it lands.
  /// 3. `terminologyProvider` is `const Terminology({}, {})` until N29, and
  ///    `labelFor` ends in `_defaults[c]!`. **Routing through it today would
  ///    throw**, which is why `LambTallyRow` types `'lamb'` instead. This is the
  ///    better half of that trade: no literal, no crash, and one grep — the
  ///    `term…Singular` reads below — when N29 wires the overrides through.
  ///
  /// The SEX CELL IS THE ANIMAL CLASS. `AnimalClass.eweLamb`, `ramLamb` and
  /// `lamb` are exactly the three states a lamb's sex can be in, and the last
  /// one's own doc comment reads *"sex unknown, or not yet sexed"* — so a
  /// recorded `Sex.unknown` renders as the plain animal noun while an ABSENT sex
  /// renders as *not recorded* (R45). The two stay different words.
  LambRowLabels _labelsFor(BuildContext context, LambEntryRow lamb, int ordinal) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return lambRowLabels(
      ordinal: ordinal,
      sex: lamb.sex,
      status: lamb.status,
      weight: lamb.birthWeight,
      tag: lamb.tag,
      units: units,
      localeName: Localizations.localeOf(context).toLanguageTag(),
      ordinalLabel: (int n) =>
          l10n.lambingLambOrdinal(animal: l10n.termLambSingular, n: n).toUpperCase(),
      sexLabel: (Sex s) => switch (s) {
        // EXHAUSTIVE, NO `default:`. The day a fourth member lands on Sex this
        // must fail to compile rather than render one of the three.
        Sex.female => l10n.termEweLambSingular.toUpperCase(),
        Sex.male => l10n.termRamLambSingular.toUpperCase(),
        Sex.unknown => l10n.termLambSingular.toUpperCase(),
      },
      statusLabel: (LambStatus s) => switch (s) {
        LambStatus.alive => l10n.lambStatusAlive,
        LambStatus.dead => l10n.lambStatusDead,
        LambStatus.stillborn => l10n.lambStatusStillborn,
        LambStatus.sold => l10n.lambStatusSold,
      },
      notRecorded: l10n.lambingTypeNotRecorded,
      // A COMMA AND A SPACE, not the middot the eye gets: at least one screen
      // reader says "middle dot" and another says nothing at all, and neither
      // is what the row means.
      sentence: (List<String> parts) => l10n.lambRowSemantics(parts: parts.join(', ')),
    );
  }
}
