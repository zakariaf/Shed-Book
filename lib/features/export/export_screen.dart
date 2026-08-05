// lib/features/export/export_screen.dart
//
// THE ONLY BACKUP THIS PRODUCT HAS. Spec §7.9: *"Because there is no cloud, this
// is a safety feature, not a convenience."*
//
// **THE SCREEN WITH NO OVER-CAP STATE AT ALL.** `07 §13.2`'s over-cap row for
// this screen reads, in full, *"nothing"* — export is never gated by the free
// tier, in any state (#86). Paywalling the only backup mechanism in an app with
// no cloud is a data-hostage pattern, and `no_monetization_test.dart` holds it.
//
// **FRAME 1 PAINTS THE ROWS WITH THEIR LABELS AND BLANK COUNTS.** The labels are
// static and never wait. Nothing shifts when the counts land, and there is no
// spinner — `ui.spinner` refuses the widget by name under `lib/features/`, and
// refused this comment too when it spelled the name out. The building state is
// the tapped row's own word, and every other row stays live: the screen never
// blocks and never covers itself with a modal.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/export/export_controller.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/features/export/export_write_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = context.localeName;
    final ExportCounts? counts = ref.watch(exportCountsProvider).value;
    final String? building = ref.watch(exportControllerProvider);

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(t.gapMin),
                child: ShedSectionHeading(
                  key: const Key('export.title'),
                  label: l10n.exportTitle,
                  level: 1,
                ),
              ),
              // WHAT AN EXPORT IS AND IS NOT, above the buttons and on the first
              // painted frame — never behind an affordance. Two lines, and they
              // do different jobs: the first is plain English the shepherd
              // reads, the second is `Disclaimers.exportFooter` itself,
              // REFERENCED and never re-typed, so the file's footer and the
              // screen's cannot drift apart.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  l10n.exportWhatThisIs,
                  key: const Key('export.what_this_is'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(height: t.gapMin / 2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  Disclaimers.exportFooter,
                  key: const Key('export.disclaimer'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ),
              SizedBox(height: t.gapMin),
              // THE HONEST STATUS LINE. It states a fact rather than nagging,
              // and the date it prints is the one the SHARE SHEET reported — a
              // file assembled and then dismissed did not leave the phone.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  counts?.lastExportedAt == null
                      ? l10n.exportNeverExported
                      : l10n.exportLastExported(
                          date: formatShedDate(LocalDate.of(counts!.lastExportedAt!), locale),
                        ),
                  key: const Key('export.status'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ),
              // WHAT THE CHECK DOES, AND WHAT IT DOES NOT. It is one line and it
              // is on the first painted frame, because a shepherd who reads the
              // word *check* and fills in *secure* for themselves has been told
              // something nobody said. `offline_wording_test.dart` refuses six
              // words in this file for exactly that reason.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  l10n.backupIntegrityLine,
                  key: const Key('export.integrity'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ),
              SizedBox(height: t.gapMin),
              for (final ({String id, String label, int? count}) row
                  in <({String id, String label, int? count})>[
                    // THE NOUN IS A PLACEHOLDER IN BOTH ROWS, upper-cased here
                    // rather than in the ARB: `10 §8.5` keeps domain nouns out of
                    // message values, and casing a placeholder inside a message
                    // is not something a translator can do.
                    (
                      id: 'export.lambs_csv',
                      label: l10n.exportCsvRow(term: l10n.termLambSingular.toUpperCase()),
                      count: counts?.lambs,
                    ),
                    (
                      id: 'export.ewes_csv',
                      label: l10n.exportCsvRow(term: l10n.termEweSingular.toUpperCase()),
                      count: counts?.ewes,
                    ),
                    (
                      id: 'export.treatments_csv',
                      label: l10n.exportCsvTreatments,
                      count: counts?.treatments,
                    ),
                  ])
                _ArtefactRow(
                  id: row.id,
                  label: row.label,
                  count: row.count,
                  // THE BUILDING WORD IS ON THE TAPPED ROW AND NOWHERE ELSE.
                  building: building == row.id,
                  l10n: l10n,
                ),
              Padding(
                padding: EdgeInsets.all(t.gapMin),
                child: ShedPrimaryButton(
                  key: const Key('export.all_csv'),
                  label: l10n.exportCsvAll,
                  semanticLabel: l10n.exportCsvAll,
                  onTap: () => unawaited(_share(context, ref, counts)),
                ),
              ),
              // **THE BACKUP, WHICH THIS SCREEN DID NOT OFFER.** Three CSVs and
              // no way to make the one file a restore reads: `writeBackup`
              // landed at N22, was tested at its own tier, and had no caller
              // anywhere in `lib/`. So the restore path wired the same week had
              // nothing to restore from.
              Padding(
                padding: EdgeInsets.all(t.gapMin),
                child: ShedPrimaryButton(
                  key: const Key('export.backup'),
                  label: l10n.exportBackup,
                  semanticLabel: l10n.exportBackup,
                  onTap: () => unawaited(_shareBackup(context, ref)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Text(
                  l10n.exportBackupWhat,
                  key: const Key('export.backup_what'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ),
              SizedBox(height: t.gapMin),

              if (counts != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                  child: Text(
                    // THE NOUNS ARE PLACEHOLDERS, NEVER LITERALS IN THE MESSAGE
                    // (`10 §8.5`) — a literal noun in a message value is what
                    // `l10n_bootstrap_test` refuses, and it caught the first
                    // draft of this line.
                    //
                    // They are fed from the ARB's own `term*Plural` messages
                    // rather than from `Terminology`, and that is a **deliberate
                    // shortfall recorded here rather than hidden**: `Terminology`
                    // holds no default text and cannot fetch any, so its
                    // defaults arrive from `terminology_bootstrap.dart` — which
                    // is N29's and does not exist. Calling `labelFor` today
                    // throws on `_defaults[c]!`, which is correct behaviour for a
                    // programming error and a crash on this screen. Measured.
                    //
                    // So a shepherd who renames *ewe* to *gimmer* will not see
                    // gimmers HERE until N29 lands. The message shape is already
                    // right, so that epic changes two arguments and no ARB.
                    l10n.exportCounts(
                      eweCount: counts.ewes,
                      ewePlural: l10n.termEwePlural,
                      lambCount: counts.lambs,
                      lambPlural: l10n.termLambPlural,
                      treatments: counts.treatments,
                    ),
                    key: const Key('export.counts'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ),
              SizedBox(height: t.gapMin),
            ],
          ),
        ),
      ),
    );
  }

  /// **THE ORIGIN IS THE TAPPED WIDGET'S RECTANGLE**, computed from its
  /// `RenderBox` at the moment of the tap. `share_plus` needs it on iPad, where
  /// the sheet is a popover that has to point at something — and a zero rect
  /// puts it in the top-left corner over the heading.
  /// The backup. **No `counts` guard**, and that is the difference from
  /// [_share]: the CSVs are per-season and cannot be built before a season
  /// exists, but a backup of an empty notebook is a valid backup of an empty
  /// notebook — and a shepherd who has just set the app up and wants to know the
  /// backup works should be able to find out then rather than in March.
  Future<void> _shareBackup(BuildContext context, WidgetRef ref) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect origin = box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;

    ref.read(exportControllerProvider.notifier).building('export.backup');
    try {
      await ref
          .read(exportWriteControllerProvider.notifier)
          .shareBackup(origin: origin, appVersion: kAppVersion);
    } finally {
      ref.read(exportControllerProvider.notifier).idle();
    }

    if (!context.mounted) {
      return;
    }
    if (ref.read(exportWriteControllerProvider) case WriteDone(
      outcome: WriteFailed(failure: final ShedFailure failure),
    )) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      showFailure(
        context,
        '${l10n.exportFailed(artefact: l10n.exportBackup)} ${failure.userMessage}',
      );
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref, ExportCounts? counts) async {
    if (counts == null) {
      return;
    }
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect origin = box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;

    final SeasonId season = await ref.read(currentSeasonProvider.future);

    // **THE VOCABULARY LABELS ARE RESOLVED HERE**, in the one object with a
    // `BuildContext`, and handed down opaque. `lib/data/` cannot reach
    // `AppLocalizations` (layer rule 4) and neither can a controller
    // (`CONVENTIONS §4.4` rule 3) — so this is the only place the `label ??
    // <the ARB default>` rule (#61) can be applied without a layer violation.
    final Map<String, String> vocabLabels = <String, String>{
      for (final VocabEntry v in ref.read(vocabProvider).value ?? const <VocabEntry>[])
        v.key: v.label ?? v.key,
    };

    ref.read(exportControllerProvider.notifier).building('export.all_csv');
    try {
      await ref
          .read(exportWriteControllerProvider.notifier)
          .shareCsvs(
            season: season,
            seasonYear: counts.seasonYear,
            vocabLabels: vocabLabels,
            origin: origin,
            localZoneLabel: _zoneLabel(),
            appVersion: kAppVersion,
          );
    } finally {
      ref.read(exportControllerProvider.notifier).idle();
    }

    // **A FAILED EXPORT SAID NOTHING, ON THE ONE SCREEN WHOSE JOB IS GETTING
    // RECORDS OFF THE PHONE.** This screen had no outcome handling at all — no
    // `ref.listen`, no `WriteFailed` arm — so a disk-full or a read-only volume
    // ran the spinner, cleared it, and left the shepherd looking at a button
    // they had just pressed with no idea whether anything had gone.
    //
    // Found by N33-T05's ARB orphan sweep: `exportFailed` was written and never
    // rendered.
    //
    // **THE ARTEFACT IS NAMED, WHICH IS WHY THE MESSAGE TAKES A PLACEHOLDER.**
    // *Something could not be built* sends a shepherd nowhere; *the treatments
    // CSV could not be built* tells them the rest of the export is fine and
    // which one to try again.
    if (!context.mounted) {
      return;
    }
    if (ref.read(exportWriteControllerProvider) case WriteDone(
      outcome: WriteFailed(failure: final ShedFailure failure),
    )) {
      showFailure(
        context,
        '${AppLocalizations.of(context).exportFailed(artefact: AppLocalizations.of(context).exportCsvAll)} '
        '${failure.userMessage}',
      );
    }
  }

  /// `UTC+01:00` — built from the **export instant's** own offset.
  ///
  /// **NOT `DateTime.timeZoneName`.** `09 §10` item 6: it returns an
  /// abbreviation on some platforms and a full name on others, so the format
  /// would differ between a shepherd's phone and the developer's. The offset is
  /// the part that is the same everywhere and the part that matters.
  ///
  /// **AND NOT A DIRECT CLOCK READ.** R23 makes `appNow()` the only wall-clock
  /// reader in the app, and `time.dart_clock` refuses the alternative — which is
  /// what caught the first draft. Reading the offset off the export instant is
  /// also more correct than reading it off *now*: an export of a winter season
  /// run in July should say what was in force at export, and `withClock` can
  /// then pin it in a test.
  static String _zoneLabel() {
    final Duration offset = appNow().local.timeZoneOffset;
    final String sign = offset.isNegative ? '-' : '+';
    final Duration abs = offset.abs();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'UTC$sign${two(abs.inHours)}:${two(abs.inMinutes % 60)}';
  }
}

/// The version stated in every trailer.
///
/// A `const` rather than a `package_info_plus` read, because `13 §9.1` makes the
/// **tag** the build name and the pubspec a local default with no authority over
/// a store artefact — and adding a plugin to read a string that the release
/// workflow already knows would be a seam for nothing.
const String kAppVersion = '1.0.0';

class _ArtefactRow extends StatelessWidget {
  const _ArtefactRow({
    required this.id,
    required this.label,
    required this.count,
    required this.building,
    required this.l10n,
  });

  final String id;
  final String label;

  /// `null` on frame 1. The row paints at full height with a blank count, so
  /// **nothing shifts** when the number lands.
  final int? count;

  final bool building;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      // **`gapMin / 2` PER SIDE, WHICH IS `gapMin` BETWEEN TWO ROWS — R86.**
      // It was `gapMin / 4`, so two adjacent CSV choices sat **8 pt** apart:
      // the exact middle of the band the separation rule forbids, on a screen
      // where the wrong tap shares the wrong file.
      //
      // Found by N33-T03's geometric sweep only after N33-T07 loaded the real
      // font into the test engine — under Ahem the rows were far enough apart
      // that the pair was never compared. Which is the argument for the font
      // loader in one line: a gate measuring tofu is measuring the wrong
      // layout.
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: l10n.exportSemantics(label: label, count: count ?? 0),
        minSize: t.tapPrimary,
        // THE ROW IS A STATEMENT, NOT A SECOND SHARE. All three CSVs go together
        // through the one button below: three separate share sheets is three
        // chances to send the wrong one.
        onTap: () {},
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  building ? l10n.exportBuilding : (count == null ? '' : '$count'),
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
