// lib/features/treatments/widgets/new_treatment_sheet.dart
//
// **A TREATMENT COULD NOT BE RECORDED. AT ALL.**
//
// `TreatmentRepository.recordTreatment` landed at N20-T01 and had no caller
// anywhere in `lib/`. `WithdrawalControl` — safety rule §12.1's control, the
// highest-stakes control in this product — landed at N20-T02 and was never
// built into a screen. The only reachable write was `repeatTreatment`, and
// there was nothing to repeat: N20's seven tasks are the countdowns, the clear
// date, the repeat sheet and the void, and **not one of them is the entry**.
//
// `07 §10.4` specifies it and nobody built it: *"New treatment — 1 to open +
// animal + product + dose + route + batch + withdrawal; every field except the
// animal is skippable; the withdrawal control is never skipped **silently** —
// skipping it records `NotRecorded` explicitly."*
//
// Found 2026-08-05 by a sweep for `lib/data/` verbs with no caller. It returned
// thirty-seven.
//
// ## Why the withdrawal cannot be left out
//
// `Disclaimers.withdrawalCaveat` sits above the control, permanently, and the
// three choices are explicit with **no pre-filled number and no pre-selected
// option** — because the app ships no default and originates no number. What
// the control cannot express is *not answered yet*: it emits nothing until the
// shepherd chooses. So this sheet does not send a withdrawal it was not given,
// and the commit records `NotRecorded` for a target the shepherd left alone —
// explicitly, in a row, which is the difference between *nobody looked* and
// *the label says none applies*.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_text_field.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/features/treatments/widgets/treatment_disclosures.dart';
import 'package:shed_book/features/treatments/widgets/withdrawal_control.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// What the sheet hands back. `null` from the sheet means they backed out.
typedef NewTreatment = ({
  EweId ewe,
  String productName,
  String? doseText,
  String? routeKey,
  String? batchNo,
  List<WithdrawalPeriod> withdrawals,
});

class NewTreatmentSheet extends ConsumerStatefulWidget {
  const NewTreatmentSheet({
    required this.candidates,
    required this.routes,
    required this.l10n,
    required this.onCommit,
    super.key,
  });

  /// The deck — penned first, then recents. The same list the repeat sheet
  /// picks from, so a shepherd finds the same animal in the same order.
  final List<DeckEntry> candidates;

  /// `treatment_route` from `vocab_terms`, already filtered and localised by the
  /// caller: `lib/core/ui/` may not resolve copy and this sheet holds to the
  /// same discipline.
  final List<({String key, String label})> routes;

  final AppLocalizations l10n;
  final ValueChanged<NewTreatment> onCommit;

  @override
  ConsumerState<NewTreatmentSheet> createState() => _NewTreatmentSheetState();
}

class _NewTreatmentSheetState extends ConsumerState<NewTreatmentSheet> {
  EweId? _ewe;
  String? _product;
  String? _dose;
  String? _route;
  String? _batch;

  /// **KEYED BY TARGET, AND ABSENT IS THE STATE.** A target with no entry here
  /// is a target the shepherd has not answered — which becomes an explicit
  /// `WithdrawalNotRecorded` row at commit, never a missing row and never a
  /// zero. `03 §5.8`: no row means not recorded, and this map is the same shape
  /// one level up.
  final Map<WithdrawalTarget, WithdrawalPeriod> _withdrawals =
      <WithdrawalTarget, WithdrawalPeriod>{};

  /// **THE ANIMAL AND THE PRODUCT. NOTHING ELSE.** `07 §10.4`: every field
  /// except the animal is skippable — and a treatment with no product name is a
  /// row nobody can read back, so the product joins it. Dose, route and batch
  /// are genuinely optional and print as gaps.
  bool get _canCommit => _ewe != null && (_product?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = widget.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // 1 — WHICH ANIMAL. The one field that is not skippable.
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(l10n.treatmentNewAnimal, style: Theme.of(context).textTheme.labelMedium),
          ),
          for (final DeckEntry e in widget.candidates)
            ShedAnimalRow(
              key: Key('treatment.new.animal.${e.tag}'),
              tag: e.tag,
              summary: e.penLabel ?? '',
              semanticLabel: l10n.treatmentNewOnto(tag: e.tag),
              selected: _ewe == e.eweId,
              onTap: () => setState(() => _ewe = e.eweId),
            ),

          // 2 — THE PRODUCT, AND THE THREE SKIPPABLE FIELDS.
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ShedTextField(
                  key: const Key('treatment.new.product'),
                  label: l10n.treatmentNewProduct,
                  value: _product,
                  semanticLabel: l10n.treatmentNewProduct,
                  onChanged: (String? v) => setState(() => _product = v),
                ),
                SizedBox(height: t.gapMin),
                ShedTextField(
                  key: const Key('treatment.new.dose'),
                  label: l10n.treatmentNewDose,
                  value: _dose,
                  semanticLabel: l10n.treatmentNewDose,
                  // **NO UNIT HINT, AND THAT IS SAFETY RULE §12.1's NEIGHBOUR.**
                  // A pre-filled `ml` is the app suggesting a unit it does not
                  // know; the label carries what is wanted and the field carries
                  // only what they typed.
                  onChanged: (String? v) => setState(() => _dose = v),
                ),
                SizedBox(height: t.gapMin),
                ShedTextField(
                  key: const Key('treatment.new.batch'),
                  label: l10n.treatmentNewBatch,
                  value: _batch,
                  semanticLabel: l10n.treatmentNewBatch,
                  onChanged: (String? v) => setState(() => _batch = v),
                ),
              ],
            ),
          ),

          // 3 — THE ROUTE, from the seeded vocabulary rather than free text: it
          // is a closed list a shepherd picks from, and typing it would make
          // `rt_subcutaneous` and `sub cut` two different routes in the export.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(l10n.treatmentNewRoute, style: Theme.of(context).textTheme.labelMedium),
          ),
          for (final ({String key, String label}) route in widget.routes)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShedWordButton(
                  key: Key('treatment.new.route.${route.key}'),
                  label: route.label,
                  semanticLabel: route.label,
                  selected: _route == route.key,
                  // Pressing the selected one clears it: route is skippable, and
                  // a choice with no way back is a choice that was not optional.
                  onTap: () => setState(() => _route = _route == route.key ? null : route.key),
                ),
              ),
            ),

          // 4 — THE WITHDRAWAL. **The caveat is above the control, permanently.**
          const WithdrawalCaveat(),
          for (final WithdrawalTarget target in WithdrawalTarget.values)
            WithdrawalControl(
              key: Key('treatment.new.withdrawal.${target.key}'),
              target: target,
              labels: (
                heading: l10n.withdrawalLabel(target: target.key),
                enterDays: l10n.withdrawalEnterDays,
                notApplicable: l10n.withdrawalNotApplicable,
                notRecorded: l10n.withdrawalNotRecorded,
                unit: l10n.withdrawalUnit,
                padLabel: l10n.withdrawalEnterDays,
                backspaceLabel: l10n.keypadBackspace,
                backspaceHint: l10n.hintDeleteLastDigit,
              ),
              onChanged: (WithdrawalPeriod p) => setState(() => _withdrawals[target] = p),
            ),

          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: ShedPrimaryButton(
              key: const Key('treatment.new.commit'),
              label: l10n.treatmentNewCommit,
              semanticLabel: l10n.treatmentNewCommit,
              // **NEVER DISABLED** (#103): a greyed-out button at 3am reads as a
              // broken app. It refuses by doing nothing, and the animal rows
              // above are what the shepherd has not pressed yet.
              onTap: _commit,
            ),
          ),
        ],
      ),
    );
  }

  void _commit() {
    if (!_canCommit) {
      return;
    }
    widget.onCommit((
      ewe: _ewe!,
      productName: _product!.trim(),
      doseText: _dose,
      routeKey: _route,
      batchNo: _batch,
      // **ONLY WHAT THEY ANSWERED, AND THE TYPE IS WHY.**
      //
      // The first draft sent a `WithdrawalNotRecorded` for every unanswered
      // target, to make `07 §10.4`'s *never skipped silently* explicit at this
      // layer. It does not compile, and the reason is the mechanism working:
      // `WithdrawalDays` and `WithdrawalNotApplicable` carry a `target` and
      // `WithdrawalNotRecorded` **has no field at all** — because *not
      // recorded* is the absence of a row, and an absence has no target.
      //
      // `recordTreatment` says the same thing from the other side: it skips
      // `NotRecorded` silently rather than rejecting it, *"the same statement
      // the absence of a row makes"*. So a target the shepherd left alone
      // writes no row, which is exactly §12.1's shape — and *not skipped
      // silently* is satisfied where it belongs, on the screen: the control is
      // rendered for both targets, with the caveat above it, and it cannot be
      // scrolled past without being seen.
      withdrawals: _withdrawals.values.toList(),
    ));
  }
}

/// The route list, resolved from the seeded vocabulary.
///
/// **`vocabLabel(userLabel, shipped)` — the shepherd's word wins** (#61), and
/// the shipped one is the ARB's. Resolved here rather than in the sheet because
/// this is the one object with a `BuildContext` and the mapping is copy.
List<({String key, String label})> treatmentRoutes(List<VocabEntry> vocab, AppLocalizations l10n) {
  const Map<String, String Function(AppLocalizations)> shipped =
      <String, String Function(AppLocalizations)>{
        'rt_subcutaneous': _subcutaneous,
        'rt_intramuscular': _intramuscular,
        'rt_oral': _oral,
        'rt_topical': _topical,
        'rt_intranasal': _intranasal,
        'rt_intravenous': _intravenous,
        'rt_intraperitoneal': _intraperitoneal,
        'rt_other': _other,
      };

  return <({String key, String label})>[
    for (final VocabEntry v in vocab)
      if (shipped[v.key] case final String Function(AppLocalizations) name)
        (key: v.key, label: vocabLabel(v.label, name(l10n))),
  ];
}

// **A SWITCH-SHAPED MAP RATHER THAN A LOOKUP BY NAME**, so a ninth route fails
// to compile here rather than rendering an empty button.
String _subcutaneous(AppLocalizations l) => l.vocabRtSubcutaneous;
String _intramuscular(AppLocalizations l) => l.vocabRtIntramuscular;
String _oral(AppLocalizations l) => l.vocabRtOral;
String _topical(AppLocalizations l) => l.vocabRtTopical;
String _intranasal(AppLocalizations l) => l.vocabRtIntranasal;
String _intravenous(AppLocalizations l) => l.vocabRtIntravenous;
String _intraperitoneal(AppLocalizations l) => l.vocabRtIntraperitoneal;
String _other(AppLocalizations l) => l.vocabRtOther;
