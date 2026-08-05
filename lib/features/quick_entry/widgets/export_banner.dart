// lib/features/quick_entry/widgets/export_banner.dart
//
// THE ONE SAFETY PROMPT THIS PRODUCT HAS, and it is a banner rather than a
// notification for a structural reason (#72, `07 §16.1`): a notification needs
// `POST_NOTIFICATIONS`, which is deferred to the moment the user asks for
// lock-screen alerts — so a shepherd who never creates a reminder would never
// receive the prompt spec §7.9 calls a safety feature.
//
// **`ShedBanner` IS ALSO THE UPGRADE ROW'S COMPONENT, AND THAT IS ON PURPOSE.**
// `ui.monetization_surface` allows it in `lib/features/quick_entry/`
// deliberately, and `11 §12.1` says why in a sentence worth keeping: *"the same
// component carries the end-of-day export prompt, which is not a monetization
// surface and predates this document. Scoping the component ban to two folders
// would have failed the build on a banner the spec calls a safety feature."*
//
// Two banners, two keys, one component — which is why
// `no_monetization_test.dart` asserts on the **upgrade row's own key** and not
// on `find.byType(ShedBanner)`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_banner.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/quick_entry/export_prompt.dart';
import 'package:shed_book/l10n/app_localizations.dart';
import 'package:shed_book/routing/routes.dart';

/// **IT DECIDES FOR ITSELF**, exactly as `InPensStrip` and `RecentsStrip` do,
/// and that is not a style choice: `quick_entry_test.dart` asserts the shell
/// watches nothing, *"because a StatelessWidget that watches nothing cannot be
/// rebuilt by a keystroke or by an emission"* (`02 §10.1`). Reading the prompt
/// state in the screen's own `build` would have moved every box on the screen
/// into the reach of an emission, which is the property the shell exists to
/// hold. Caught by that test on the first run.
///
/// **AND IT DOES NOT WATCH ON THE FIRST FRAME**, which is the second thing this
/// widget had to learn. `exportPromptProvider` needs the database, and watching
/// it from `build` opens the database DURING the frame — `app_test.dart` pins
/// the open to `postFrameCallbacks` and caught this immediately, with the right
/// message: *"an open in initState or build is a frame the shepherd spends
/// looking at the platform launch colour."*
///
/// So the watch is armed in a post-frame callback. The banner is a daylight
/// prompt on a screen whose first frame is the product's headline promise; it
/// can afford to arrive one frame late, and the first frame cannot afford it.
class ExportBanner extends ConsumerStatefulWidget {
  const ExportBanner({super.key});

  @override
  ConsumerState<ExportBanner> createState() => _ExportBannerState();
}

class _ExportBannerState extends ConsumerState<ExportBanner> {
  bool _armed = false;

  /// **THE ONCE-A-DAY RULE NEVER FIRED, BECAUSE NOTHING WROTE THE COLUMN.**
  /// `shouldPrompt`'s rule 3 reads `last_export_prompted_at` and returns false
  /// when it is today — and `SettingsRepository.recordExportPrompted`, the only
  /// writer, had no caller anywhere in `lib/`. So the column stayed null
  /// forever and a shepherd who ignored the banner got it again on the next
  /// cold launch, and the next, all day.
  ///
  /// **STAMPED WHEN IT IS SHOWN, NOT WHEN IT IS ACTED ON.** The rule is *have I
  /// asked today*, and asking is what this widget does; dismissing has its own
  /// column, and exporting has a third. Three different facts.
  bool _stamped = false;

  /// **ONCE SHOWN, IT STAYS UNTIL IT IS ANSWERED**, and the latch is not
  /// cosmetic: `recordExportPrompted` writes the column that `shouldPrompt`'s
  /// rule 3 reads, so stamping at show-time made the banner remove itself on the
  /// very next emission. Measured — the banner stopped rendering at all, and
  /// three other tests went red with it.
  ///
  /// The rule is *have I asked today*, and the answer becomes yes the moment it
  /// is on screen. What must not follow is the question vanishing while the
  /// shepherd is reading it. Dismissing and exporting have their own columns.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _armed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_armed) {
      return const SizedBox.shrink();
    }
    final ExportPromptState? p = ref.watch(exportPromptProvider).value;
    if (p != null && p.show) {
      _shown = true;
    }
    if (p == null || !(p.show || _shown)) {
      // NOT AN EMPTY BOX WITH A HEIGHT. The slot takes no space at all when the
      // banner is not shown, so the record column below it is the same size on
      // the days nothing is prompted — which is most of them.
      return const SizedBox.shrink();
    }

    // Once per mount, after the decision to show is made. `unawaited` because
    // nothing here waits on it: the banner is already on screen and the stamp
    // only changes what happens on the next launch.
    if (!_stamped) {
      _stamped = true;
      unawaited(ref.read(settingsRepositoryProvider).recordExportPrompted(p.now));
    }

    final Instant? lastExportedAt = p.lastExportedAt;
    final int recordsSinceExport = p.recordsSinceExport;
    final SeasonId? currentSeason = p.currentSeason;

    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = context.localeName;

    return ShedBanner(
      key: const Key('quick_entry.export_banner'),
      now: p.now,
      message:
          '${lastExportedAt == null ? l10n.exportBannerNeverHeadline : l10n.exportBannerHeadline(date: formatShedDate(LocalDate.of(lastExportedAt!), locale))} '
          '${l10n.exportBannerCount(count: recordsSinceExport)}',
      primary: (
        label: l10n.exportBannerAct,
        semanticLabel: l10n.exportBannerAct,
        // **IT PUSHES AND STARTS NOTHING.** A banner action that begins a share
        // is a banner that has decided for the shepherd which artefacts they
        // wanted — and on a 400-ewe flock it is also several seconds of work
        // they did not ask for.
        onTap: () => unawaited(Routes.export(context)),
      ),
      secondary: (
        label: l10n.exportBannerDismiss,
        semanticLabel: l10n.exportBannerDismiss,
        // **THERE IS NO THIRD ACTION AND NO CLOSE X**, and `ShedBanner` makes a
        // third unrepresentable rather than merely discouraged. Not answering is
        // already free; a *later* button would be a third decision at the one
        // moment the app promised not to ask for any.
        onTap: () {
          if (currentSeason case final SeasonId season) {
            unawaited(ref.read(settingsRepositoryProvider).dismissExportPromptForSeason(season));
          }
        },
      ),
    );
  }
}
