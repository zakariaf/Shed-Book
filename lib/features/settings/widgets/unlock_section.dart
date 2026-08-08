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
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/settings/unlock_controller.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context);

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
      return SettingLine(text: l10n.unlockUnlocked, textKey: const Key('settings.unlock.unlocked'));
    }

    final UnlockState state = ref.watch(unlockControllerProvider);
    final UnlockController controller = ref.read(unlockControllerProvider.notifier);

    return Column(
      // The key stays on the wrapper it was on: `11 §12.1`'s *"upgrade row 2"*
      // is the whole group, not one of its buttons.
      key: const Key('settings.upgrade_row'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **RESTORE FIRST.** See the file header.
        SettingRow(
          control: ShedWordButton(
            key: const Key('settings.unlock.restore'),
            label: l10n.unlockRestore,
            selected: false,
            onTap: () => controller.restore().ignore(),
          ),
        ),
        SettingRow(
          control: ShedWordButton(
            key: const Key('settings.unlock.buy'),
            // **THE LABEL CHANGES; NO SPINNER IS ADDED.** The indeterminate
            // progress widget is refused under `lib/features/` outright, and it
            // would be a promise about a duration nobody measured — the call is
            // bounded at ten seconds by the seam.
            //
            // **THE PRICE IS THE STORE'S OWN STRING.** It arrives localised and
            // currency-formatted from the account's own store; this app knows
            // neither, and building one would be inventing a number.
            // **TWO MESSAGES, NEVER ONE WITH AN EMPTY PLACEHOLDER.**
            // `UNLOCK — ` with a trailing dash is a rendering of a missing
            // value, and a dash where a price should be reads as free. The
            // unpriced form stays tappable, because the store may answer on the
            // next tap.
            label: switch (state) {
              UnlockContactingStore() => l10n.unlockContactingStore,
              UnlockOffered(price: final String p) => l10n.unlockBuyPriced(price: p),
              _ => l10n.unlockBuyUnpriced,
            },
            selected: false,
            onTap: () => controller.unlock().ignore(),
          ),
        ),
        if (_message(l10n, state) case final String line)
          SettingLine(text: line, textKey: const Key('settings.unlock.state')),
      ],
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
