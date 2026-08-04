// lib/features/settings/widgets/unlock_section.dart
//
// Section 9 of `07 §14.3` — upgrade row 2, and the only place in the app where
// money is discussed at all.
//
// **RESTORE SITS ABOVE UNLOCK** (`11 §6.4`). Apple requires it, and a shepherd
// who reinstalled must be able to get back what they already own without paying
// twice — so the route to it must not be below the thing that charges them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/settings/unlock_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class UnlockSection extends ConsumerStatefulWidget {
  const UnlockSection({super.key});

  @override
  ConsumerState<UnlockSection> createState() => _UnlockSectionState();
}

class _UnlockSectionState extends ConsumerState<UnlockSection> {
  @override
  void initState() {
    super.initState();
    // **THE STORE IS FIRST TOUCHED HERE AND NOWHERE EARLIER.** `openSection()`
    // calls `attach()`, which initialises the Android billing client — so the
    // whole of #90 comes down to this line being in this file. No shed screen
    // mounts this widget, and `FakePurchaseService`'s call list proves it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(unlockControllerProvider.notifier).openSection().ignore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    final bool unlocked = switch (ref.watch(entitlementProvider)) {
      AsyncData<Entitlement>(value: final Entitlement e) => e.unlocked,
      _ => false,
    };

    if (unlocked) {
      // **ONE WORD, AND NOTHING ELSE.** No date, no receipt, no product name —
      // the row records THAT the app is unlocked and nothing about how
      // (`11 §4.1`), because none of it changes what the shepherd may do and
      // each is a fact about their payment method in a file they may hand to a
      // vet.
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.unlockUnlocked,
            key: const Key('settings.unlock.unlocked'),
            style: text.labelMedium,
          ),
        ),
      );
    }

    final UnlockState state = ref.watch(unlockControllerProvider);
    final UnlockController controller = ref.read(unlockControllerProvider.notifier);

    return Padding(
      key: const Key('settings.upgrade_row'),
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // **RESTORE FIRST.** See the file header.
          ShedWordButton(
            key: const Key('settings.unlock.restore'),
            label: l10n.unlockRestore,
            selected: false,
            onTap: () => controller.restore().ignore(),
          ),
          SizedBox(height: t.gapMin / 2),
          ShedWordButton(
            key: const Key('settings.unlock.buy'),
            // **THE LABEL CHANGES; NO SPINNER IS ADDED.** The indeterminate
            // progress widget is refused under `lib/features/` outright, and it
            // would be a promise about a duration nobody measured — the call is
            // bounded at ten seconds by the seam.
            //
            // **THE PRICE IS THE STORE'S OWN STRING.** It arrives localised and
            // currency-formatted from the account's own store; this app knows
            // neither, and building one would be inventing a number.
            label: switch (state) {
              UnlockContactingStore() => l10n.unlockContactingStore,
              UnlockOffered(price: final String p) => p,
              _ => l10n.upgradeRowUnlock,
            },
            selected: false,
            onTap: () => controller.unlock().ignore(),
          ),
          if (_message(l10n, state) case final String line)
            Padding(
              padding: EdgeInsets.only(top: t.gapMin / 2),
              child: Text(line, key: const Key('settings.unlock.state'), style: text.bodyMedium),
            ),
        ],
      ),
    );
  }

  /// The line under the buttons, or nothing.
  ///
  /// **EXHAUSTIVE OVER A SEALED SET, NO `default:`** — the day a fifth
  /// `UnlockState` lands this must fail to compile rather than render silence.
  String? _message(AppLocalizations l10n, UnlockState state) => switch (state) {
    UnlockOffered() || UnlockContactingStore() => null,
    UnlockAwaitingPayment() => l10n.unlockAwaitingPayment,
    UnlockUnavailable(reason: final UnlockUnavailableReason r) => switch (r) {
      UnlockUnavailableReason.storeUnreachable => l10n.unlockStoreUnreachable,
      UnlockUnavailableReason.productNotFound => l10n.unlockProductNotFound,
      UnlockUnavailableReason.userCancelled => l10n.unlockUserCancelled,
      UnlockUnavailableReason.storeError => l10n.unlockStoreError,
    },
  };
}
