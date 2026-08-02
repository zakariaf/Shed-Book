// lib/features/lambing/foster_screen.dart
//
// ONE TAP FROM HERE TO A COMMITTED REASSIGNMENT. `07 §8.2` fixes that budget and
// `test/features/tap_budget_test.dart` holds it at exactly 1 — not *at most* 1,
// because a screen that got cheaper would mean a target moved.
//
// Spec §7.3 names this as the flow most likely to be abandoned if it takes five
// taps, and an abandoned foster is a lamb whose rearing nobody can account for in
// April. So there is NO CONFIRM, no chooser and no review line: the tap is the
// write, and the committed row is the confirmation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/foster_controller.dart';
import 'package:shed_book/features/lambing/foster_write_controller.dart';
import 'package:shed_book/features/lambing/widgets/foster_no_ewe_targets.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class FosterScreen extends ConsumerWidget {
  const FosterScreen({required this.lambId, super.key});

  final LambId lambId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FosterState state = ref.watch(fosterControllerProvider(lambId));
    final FosterController input = ref.read(fosterControllerProvider(lambId).notifier);
    // READ INSIDE EACH CALLBACK, NEVER CAPTURED AT BUILD TIME — and this is a
    // MEASURED bug rather than a style preference. The write controller is
    // `.autoDispose` (`CONVENTIONS §3.4`), and `ref.read` does not subscribe, so
    // nothing keeps it alive between builds. A notifier captured in a closure
    // during one build is a notifier that may already have been disposed by the
    // time the second tap runs — and on 2.6.1 assigning state to a disposed
    // notifier does NOT throw, so the tap does nothing at all, silently.
    //
    // Found by the two-outcomes case: the first tap wrote a row and the second
    // wrote nothing, with no error anywhere.
    FosterWriteController write() => ref.read(fosterWriteControllerProvider.notifier);

    // THE DECK, READ FROM `lib/data/` (R83). The pen strip is where a ewe with a
    // spare teat is found, and before N18-T02 this provider lived inside Quick
    // Entry where no other feature could reach it.
    final List<DeckEntry> penned = ref.watch(
      quickEntryDeckProvider.select(
        (AsyncValue<QuickEntryDeck> d) => d.value?.penned ?? const <DeckEntry>[],
      ),
    );

    // MATCHED ON A PREFIX OF THE DIGITS, in Dart, over rows already in hand.
    // A second statement per keystroke would be a second dependency list and
    // `07 §1.2` allows one.
    final List<DeckEntry> matches = state.query.isEmpty
        ? const <DeckEntry>[]
        : penned.where((DeckEntry e) => e.digits.startsWith(state.query)).toList(growable: false);

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
                  l10n.fosterTitle,
                  key: const Key('foster.title'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // THE MATCHES. Each is a TARGET THAT COMMITS — the key
                    // carries the ewe's tag, so `foster.target.128` is the tap
                    // the budget test counts.
                    if (matches.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(t.gapMin),
                        child: Text(
                          l10n.fosterNoMatch,
                          key: const Key('foster.no_match'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                        ),
                      )
                    else
                      for (final DeckEntry e in matches)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: t.gapMin,
                            vertical: t.gapMin / 4,
                          ),
                          child: ShedTapTarget(
                            key: Key('foster.target.${e.tag}'),
                            semanticLabel: l10n.fosterOnto(tag: e.tag),
                            minSize: t.tapPrimary,
                            // ONE TAP, AND IT IS THE WRITE. No confirm.
                            onTap: () => write().recordFoster(lambId, ToEwe(e.eweId)),
                            child: ExcludeSemantics(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.fosterOnto(tag: e.tag),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                    SizedBox(height: t.gapMin),
                    FosterNoEweTargets(
                      onToBottle: () => write().recordFoster(lambId, const ToBottle()),
                      onRemoved: () => write().recordFoster(lambId, const RemovedUnknown()),
                      bottleLabel: l10n.fosterToBottle,
                      removedLabel: l10n.fosterRemovedUnknown(
                        animal: l10n.termEweSingular.toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // THE PAD AT THE BOTTOM, where the thumb is. Decision #57: it is the
            // only numeric route in the app.
            ShedKeypad(
              onDigit: input.digit,
              onBackspace: input.backspace,
              thirdKey: ShedKeypadThirdKey.decimal,
              // A TAG HAS NO DECIMAL, so this key appends nothing. It stays LIVE
              // because a dead key under a cold thumb is indistinguishable from
              // a missed tap (`indelible.md §7.2`).
              onThirdKey: () {},
              padLabel: l10n.fosterTitle,
              backspaceLabel: l10n.keypadBackspace,
              backspaceHint: l10n.hintDeleteLastDigit,
              thirdKeyLabel: '.',
            ),
          ],
        ),
      ),
    );
  }
}
