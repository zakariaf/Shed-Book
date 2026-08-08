// lib/features/export/export_write_controller.dart
//
// EVERY ARTEFACT TAP GOES THROUGH `guard()`, which refuses to run concurrently.
// That is the double-tap defence, and on this screen it matters more than on the
// shed screens: assembling a 400-ewe CSV twice writes the same file twice and
// opens two share sheets, the second one over a sheet the shepherd is already
// reading.
//
// **THE ONE PLACE `last_exported_at` IS STAMPED**, and it is a `SettingsRepository`
// write rather than an `ExportRepository` one — `CONVENTIONS §2.13` says that
// repository owns *nothing*, which is why `SettingsRepository` came forward nine
// epics to N12-T02 (critique defect S6).
//
// `09 §8.3` fixes exactly when: on `completed` **and** on `unknown`, never on
// `dismissed`, and never before the sheet opens. Android frequently cannot tell
// us, and the honest reading of *unavailable* is *it probably happened* —
// stamping is the safer error, because the alternative nags somebody who has
// just exported.
library;

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/share_service.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

final class ExportWriteController extends WriteController {
  /// Assemble the three CSVs and hand them to the share sheet.
  ///
  /// [vocabLabels] arrives from the **screen**, already resolved, and is passed
  /// straight through. `lib/data/` cannot reach `AppLocalizations` (layer rule 4
  /// keeps Flutter's widget layer out and there is no `BuildContext` down
  /// there), and neither can a controller — `CONVENTIONS §4.4` rule 3 gives a
  /// controller no context. A controller that reached for a localisation would
  /// be a layer violation **and** a lie about where terminology lives.
  Future<void> shareCsvs({
    required SeasonId season,
    required int seasonYear,
    required Map<String, String> vocabLabels,
    required Rect origin,
    required String localZoneLabel,
    required String appVersion,
  }) => guard(() async {
    final Instant now = appNow(); // ONE instant, and it dates the envelope

    // THE SCRATCH DIRECTORY COMES FROM `MediaStore`, not from here. `08 §1.2`
    // confines `package:path_provider` to two files and a controller is neither
    // — see `MediaStore.exportScratch()` for the ruling.
    final Directory dir = await ref.read(mediaStoreProvider).exportScratch();
    final ExportRepository repo = await ref.read(exportRepositoryProvider.future);

    final List<ExportArtifact> artifacts = await repo.writeCsvArtifacts(
      season: season,
      seasonYear: seasonYear,
      // THE ENVELOPE IS BUILT HERE AND THE DISCLAIMER IS NOT A PARAMETER OF IT
      // (§12.3, `05 §7.4`). There is nothing to pass and nothing to forget.
      writer: CsvWriter(
        ExportEnvelope.standard(now: now, appVersion: appVersion),
        localZoneLabel: localZoneLabel,
      ),
      vocabLabels: vocabLabels,
      outputDir: dir,
    );

    final ShareOutcome outcome = await ref
        .read(shareServiceProvider)
        .shareFiles(
          paths: <String>[for (final ExportArtifact a in artifacts) a.path],
          fileNames: <String>[for (final ExportArtifact a in artifacts) a.shareName],
          origin: origin,
        );

    // STAMPED AFTER THE SHEET, AND ONLY ON TWO OF THE THREE OUTCOMES.
    // `dismissed` means nothing left the phone, so stamping it would silence the
    // end-of-day prompt for somebody who has not exported — which is the one
    // failure mode that turns a safety feature into a liability.
    if (outcome != ShareOutcome.dismissed) {
      await ref.read(settingsRepositoryProvider).recordExported(now);
    }

    return WriteCommitted(insertedId: artifacts.length);
  });

  /// The JSON backup — **the only file a restore can read.**
  ///
  /// **IT HAD NO CALLER ANYWHERE IN `lib/`.** `ExportRepository.writeBackup`
  /// landed at N22 and was tested at its own tier; the export screen offered
  /// three CSVs and no backup. So a shepherd could get their records *out* in a
  /// form a spreadsheet reads and never in the form this app reads back — and
  /// N23's whole restore path, wired on 2026-08-05, had nothing to restore
  /// from. Found by the uncalled-verb sweep on the same day.
  ///
  /// **A CSV IS NOT A BACKUP AND THE TWO ARE NOT INTERCHANGEABLE.** The CSVs are
  /// three flattened views for somebody else's software; the backup is all 21
  /// tables including the empty ones (P15), with the provenance quad, the
  /// withdrawal child rows and the strikes. Restoring from a CSV would lose
  /// every one of those silently, which is why there is no such path.
  Future<void> shareBackup({required Rect origin, required String appVersion}) => guard(() async {
    final Instant now = appNow(); // ONE instant, and it dates the envelope
    final Directory dir = await ref.read(mediaStoreProvider).exportScratch();
    final ExportRepository repo = await ref.read(exportRepositoryProvider.future);

    final ExportArtifact artefact = await repo.writeBackup(
      envelope: ExportEnvelope.standard(now: now, appVersion: appVersion),
      outputDir: dir,
    );

    final ShareOutcome outcome = await ref
        .read(shareServiceProvider)
        .shareFiles(
          paths: <String>[artefact.path],
          fileNames: <String>[artefact.shareName],
          origin: origin,
        );

    // **STAMPED, AND ON THE SAME TWO OUTCOMES AS THE CSVs.** A backup that left
    // the phone is the strongest form of *exported* there is, so the end-of-day
    // prompt goes quiet for exactly the right reason. `dismissed` means nothing
    // left, and stamping it would silence the prompt for somebody who has
    // backed up nothing.
    if (outcome != ShareOutcome.dismissed) {
      await ref.read(settingsRepositoryProvider).recordExported(now);
    }

    return WriteCommitted(insertedId: artefact.byteSize);
  });
}

/// **Always `.autoDispose`** for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<ExportWriteController, WriteState> exportWriteControllerProvider =
    NotifierProvider.autoDispose<ExportWriteController, WriteState>(ExportWriteController.new);
