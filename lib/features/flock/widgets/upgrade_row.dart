// lib/features/flock/widgets/upgrade_row.dart
//
// **UPGRADE ROW 1 — AND THE WHOLE POINT OF IT IS THAT IT DOES NOT CHANGE.**
// Decision #92: two static rows, *"always present, in the same pixels, at 3 ewes
// or at 15."* A row that appeared when a shepherd neared the cap would teach
// them that its appearance means they are being watched, and every subsequent
// glance at it is an interruption. This one is furniture.
//
// **IT STATES FACTS AND ASKS FOR NOTHING.** `07 §19.2`: what this version is,
// what it covers, and two counts. No modal, no interstitial, no self-appearing
// sheet, no timed prompt, no badge, no colour change to red.
//
// **NEVER ON A SHED SCREEN, AND NEVER 22:00–06:00** — on any screen, at any ewe
// count. Both guards live in the widget rather than at the call sites, because a
// guard at a call site is a guard somebody forgets at the thirteenth one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/ui/components/shed_banner.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class UpgradeRow extends ConsumerWidget {
  const UpgradeRow({required this.eweCount, required this.onUnlock, super.key});

  /// Ewes in the current season. **The count is passed in rather than read
  /// here** — the Flock screen already has the list, and a second statement for
  /// a number it is holding would be a second answer one frame apart.
  final int eweCount;

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Instant now = appNow();

    // **THE QUIET WINDOW, AND IT IS NOT A PREFERENCE.** `11 §7.4`: the app does
    // not solicit between 22:00 and 06:00 — on any screen, at any ewe count, at
    // any entitlement state. One predicate, shared with the policy, so the row
    // and the refusal cannot disagree about when the app goes quiet.
    if (isQuietHours(now)) {
      return const SizedBox.shrink();
    }

    // **AN UNLOCKED NOTEBOOK RENDERS NOTHING**, and it renders nothing while the
    // entitlement is still being read — a row that flashed for one frame before
    // the row arrived is the paywall flash #90 exists to prevent.
    final Entitlement? entitlement = switch (ref.watch(entitlementProvider)) {
      AsyncData<Entitlement>(value: final Entitlement e) => e,
      _ => null,
    };
    if (entitlement == null || entitlement.unlocked) {
      return const SizedBox.shrink();
    }

    final TermLabel term =
        ref.watch(terminologyProvider).overrideFor(AnimalClass.ewe) ??
        TermLabel(l10n.termEweSingular, l10n.termEwePlural);

    return ShedBanner(
      key: const Key('flock.upgrade_row'),
      now: now,
      message: l10n.upgradeRowFree(ewes: eweCount, cap: kFreeEweCap, term: term.plural),
      // **NO PRICE ON THIS ROW, AND THAT IS A DECISION RATHER THAN AN
      // OMISSION.** The price would have to come from `unlockControllerProvider`
      // — a sibling feature, which `layer.sibling` forbids — and reaching it
      // another way would mean this screen asking the store, which is the one
      // thing #90 is about even though Flock is not a shed screen.
      //
      // So the row states facts about the free tier and the ACTION carries the
      // shepherd to where the price is. That is also the honest shape: a number
      // you cannot act on beside a word you can is an advertisement.
      //
      // **ONE ACTION AND NO DISMISS.** There is nothing to dismiss: the row is
      // not an event, so it has no lifetime — and a dismiss control would make
      // it one, which is how a static row becomes a prompt.
      primary: (
        label: l10n.upgradeRowUnlock,
        semanticLabel: l10n.upgradeRowUnlockSemantics,
        onTap: onUnlock,
      ),
    );
  }
}
