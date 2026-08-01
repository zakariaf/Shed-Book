// test/support/seeds.dart
//
// Targeted seed helpers (12 §5.2): small, explicit, and the test reads as the
// scenario. These write rows DIRECTLY through drift, not through a repository —
// deliberately, because at N12 only SettingsRepository exists, and because a
// fixture is not a record. The other route is restoreFixture, which goes through
// RestoreService (N23).
//
// 12 §5.3 closes this file at ten writers. Three land here; each of the others
// lands with the epic that first needs it:
//   seedOpenOccupancy            N19   (pen board)
//   seedAutoLambing              N16   (lambing entry)
//   seedEditedLambing            N16   (the provenance quad)
//   seedContradictoryLambing     N06/N16 (the warning path, 12 §10.4)
//   armExportBanner              N21
//   setEntitlement · setEwesInCurrentSeason · restoreFixture   N23/N30
//
// EVERY ROW HERE IS A ROW THE APP COULD HAVE PRODUCED. These helpers satisfy the
// schema by hand — `foreign_keys = ON` (decision #28), every table `STRICT`,
// `uid` from `newUid()`, and the §12.5 provenance quad coherent: `time_source`
// stays `'auto'` and `original_effective` stays null, because a row that says
// 'auto' while carrying an original effective time is a row no screen could have
// written. `seedEditedLambing` is the helper that sets the other combination,
// and it lands in N16 with the screen that produces it.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

/// The season every seeded row hangs off, created once per database.
///
/// `seedFirstRun` writes settings, entitlements, the vocabulary and the reminder
/// rules — **it does not write a season**, because a season is the shepherd's
/// first act, not the installer's. Lambings and treatments both have a non-null
/// season foreign key, so the helpers below need one to exist; this creates it
/// on demand rather than making every caller pass an id it does not care about.
Future<SeasonId> _season(AppDatabase db) async {
  final List<Season> existing = await db.select(db.seasons).get();
  if (existing.isNotEmpty) {
    return SeasonId(existing.first.id);
  }

  final Instant now = appNow();
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: now.local.year,
          label: '${now.local.year}',
          startDate: LocalDate(now.local.year, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return SeasonId(id);
}

/// One ewe, with [tag] stored **exactly as typed** (spec §12.4).
///
/// `tagDigits` is the digits-only projection written in the same statement — a
/// projection beside the typed value, never a correction of it.
Future<EweId> seedEwe(AppDatabase db, {required String tag}) async {
  final Instant now = appNow();
  final int id = await db
      .into(db.ewes)
      .insert(
        EwesCompanion.insert(
          tag: tag,
          tagDigits: tag.replaceAll(RegExp('[^0-9]'), ''),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return EweId(id);
}

/// One lambing for [ewe], at [occurredAt] or now.
///
/// The provenance quad is the honest one for a row written as it happened:
/// `captured_at == occurred_at`, `time_source` `'auto'`, no original effective
/// time. `local_date` is derived from the instant in the local zone, which is
/// what makes a 01:30 lambing on the clocks-back night land on the right day.
Future<LambingId> seedLambing(AppDatabase db, EweId ewe, {Instant? occurredAt}) async {
  final Instant at = occurredAt ?? appNow();
  final SeasonId season = await _season(db);

  final int id = await db
      .into(db.lambings)
      .insert(
        LambingsCompanion.insert(
          season: season.value,
          ewe: ewe.value,
          occurredAt: at,
          capturedAt: at,
          localDate: LocalDate.of(at),
          uid: newUid(),
          createdAt: at,
          updatedAt: at,
        ),
      );
  return LambingId(id);
}

/// One treatment on its own freshly-seeded ewe, with one **meat** withdrawal
/// period of [withdrawalDays] days.
///
/// **[withdrawalDays] IS REQUIRED AND HAS NO DEFAULT VALUE.** Safety rule §12.1:
/// no code path in this project defaults a withdrawal period, and that includes
/// a test helper — a default here is a default that gets copied into a screen.
/// `0` is a real recorded value, which is why the child row exists at all: no
/// row means `NotRecorded`, and a nullable int could not carry both.
Future<TreatmentId> seedTreatment(
  AppDatabase db, {
  required String product,
  required int withdrawalDays,
}) async {
  final Instant at = appNow();
  final SeasonId season = await _season(db);
  final EweId ewe = await seedEwe(db, tag: 'T${at.epochMillis % 100000}');

  final int id = await db
      .into(db.treatments)
      .insert(
        TreatmentsCompanion.insert(
          season: season.value,
          ewe: Value<int?>(ewe.value),
          productName: product,
          administeredAt: at,
          capturedAt: at,
          uid: newUid(),
          createdAt: at,
          updatedAt: at,
        ),
      );

  await db
      .into(db.treatmentWithdrawals)
      .insert(
        TreatmentWithdrawalsCompanion.insert(
          treatment: id,
          target: 'meat',
          kind: 'days',
          days: Value<int?>(withdrawalDays),
          clearDate: Value<LocalDate?>(LocalDate.of(at).plusDays(withdrawalDays)),
          uid: newUid(),
          createdAt: at,
          updatedAt: at,
        ),
      );

  return TreatmentId(id);
}
