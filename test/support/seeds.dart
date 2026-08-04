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
//   seedOpenOccupancy            N19   (pen board — seedPenOccupancy below is
//                                       the deck's narrower ancestor, not it)
//   seedAutoLambing              N16   (lambing entry)
//   seedEditedLambing            N16   (the provenance quad)
//   seedContradictoryLambing     N06/N16 (the warning path, 12 §10.4)
//   armExportBanner              N21
//   restoreFixture               N23
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
/// The current season, created on first call and **made current**.
///
/// **PUBLIC FROM N19-T01.** It was private, and four test files had each
/// hand-rolled their own `_seedSeason` — four copies of one fact, which is four
/// places for it to drift. The pen tests needed it because a pen has no season
/// of its own and nothing else in their setup creates one.
Future<SeasonId> seedSeason(AppDatabase db) => _season(db);

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

  // AND IT IS MADE CURRENT, which it was not until N19-T01. A seeded season that
  // `app_settings.current_season` does not point at is a season NO REPOSITORY
  // CAN FIND — every write verb reads the current season from settings, so the
  // seed was producing a database the app cannot write to. Found by
  // `PenRepository.enterPen`, which was the first verb to be tested against a
  // database seeded only through this path.
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(id)),
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
  EweId? ewe,
  Instant? administeredAt,
}) async {
  final Instant at = administeredAt ?? appNow();
  final SeasonId season = await _season(db);
  // **[ewe] IS OPTIONAL AND THE FALLBACK STILL SEEDS ONE.** N20 wrote this
  // helper for the treatments screen, where the animal is incidental; N27's
  // timeline needs a treatment on a NAMED ewe, and a second helper for that
  // would be two rows of one fact. The fallback tag is derived from the instant
  // so two calls in one test do not collide on `idx_ewe_tag_active`.
  final EweId subject = ewe ?? await seedEwe(db, tag: 'T${at.epochMillis % 100000}');

  final int id = await db
      .into(db.treatments)
      .insert(
        TreatmentsCompanion.insert(
          season: season.value,
          ewe: Value<int?>(subject.value),
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

/// One pen. `label` is what the deck's penned strip prints.
Future<PenId> seedPen(AppDatabase db, {required String label}) async {
  final Instant now = appNow();
  final int id = await db
      .into(db.pens)
      .insert(PensCompanion.insert(label: label, uid: newUid(), createdAt: now, updatedAt: now));
  return PenId(id);
}

/// [ewe] into [pen], still in it.
///
/// `exited_at` stays null, which is what the deck's `penned` CTE filters on. The
/// provenance quad is the honest one for a row written as it happened.
Future<PenOccupancyId> seedPenOccupancy(
  AppDatabase db,
  PenId pen,
  EweId ewe, {
  Instant? enteredAt,
}) async {
  final Instant at = enteredAt ?? appNow();
  final SeasonId season = await _season(db);

  final int id = await db
      .into(db.penOccupancies)
      .insert(
        PenOccupanciesCompanion.insert(
          pen: pen.value,
          season: season.value,
          ewe: Value<int?>(ewe.value),
          enteredAt: at,
          capturedAt: at,
          uid: newUid(),
          createdAt: at,
          updatedAt: at,
        ),
      );
  return PenOccupancyId(id);
}

/// A touch — the row the recents strip is built from.
///
/// `ewe_touches` has `ewe` as its PRIMARY KEY, so there is exactly one row per
/// ewe and a second touch REPLACES rather than appends. It carries no identity
/// and no provenance: it is a cache, rebuildable, excluded from the backup.
Future<void> seedTouch(AppDatabase db, EweId ewe, {Instant? touchedAt}) => db
    .into(db.eweTouches)
    .insertOnConflictUpdate(
      EweTouchesCompanion.insert(ewe: Value<int>(ewe.value), touchedAt: touchedAt ?? appNow()),
    );

/// Sets the one entitlement row.
///
/// `12 §5.3`'s helper, landing at N14-T07 — the first task that needs it. The
/// row exists from the first millisecond, because `seedFirstRun` seeds it in
/// `onCreate`, so this is an update and never an insert.
Future<void> setEntitlement(AppDatabase db, {required bool unlocked}) =>
    (db.update(db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).write(
      EntitlementsCompanion(unlocked: Value<bool>(unlocked)),
    );

/// Tops the current season up to [n] ewes.
///
/// **`ewe_seasons`, not `ewes`, and the distinction is the whole reason the
/// table exists**: a barren ewe has no lambing row, so participation has to be
/// recorded explicitly or she vanishes from every count that matters.
Future<void> setEwesInCurrentSeason(AppDatabase db, int n) async {
  final SeasonId season = await _season(db);
  final Instant now = appNow();

  final int existing = (await (db.select(
    db.eweSeasons,
  )..where(($EweSeasonsTable t) => t.season.equals(season.value))).get()).length;

  for (int i = existing; i < n; i++) {
    final EweId ewe = await seedEwe(db, tag: 'CAP$i');
    await db
        .into(db.eweSeasons)
        .insert(
          EweSeasonsCompanion.insert(
            season: season.value,
            ewe: ewe.value,
            // NO DEFAULT on status, deliberately (03 §5): defaulting to
            // 'to_ram' would silently assert a ewe was put to the ram, which is
            // the denominator of a commercially sensitive number.
            status: 'to_ram',
            uid: newUid(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}

/// One lamb on [lambing], born to [birthDam].
///
/// `sex` and `birth_weight_g` stay ABSENT rather than null-by-default: not
/// recorded and recorded-as-unknown are different facts (R45), and a seed that
/// filled them in would make every read-back case assert against data the app
/// would never have produced on the five-tap path.
Future<LambId> seedLamb(
  AppDatabase db,
  LambingId lambing,
  EweId birthDam, {
  String status = 'alive',
  String? sex,
  int? birthWeightG,
  String? tag,
}) async {
  final Instant now = appNow();
  final int id = await db
      .into(db.lambs)
      .insert(
        LambsCompanion.insert(
          lambing: lambing.value,
          birthDam: birthDam.value,
          status: Value<String>(status),
          // ABSENT BY DEFAULT, ALL THREE. A seed that filled these in would
          // make every rendering test agree that a lamb has a sex, a weight and
          // a tag — which is the state a lamb is in for about ten seconds of its
          // life. `null` is what the shed produces (R45), so `null` is what the
          // helper produces unless a case says otherwise.
          sex: Value<String?>(sex),
          birthWeightG: Value<int?>(birthWeightG),
          tag: Value<String?>(tag),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return LambId(id);
}

/// One care event, against a LAMB or against the LAMBING.
///
/// `care_events`' CHECK is exactly one of the two, and the distinction is real:
/// a care action taken before the first lamb is attached belongs to the lambing.
/// Passing both, or neither, is a schema failure rather than a Dart one.
Future<CareEventId> seedCareEvent(
  AppDatabase db, {
  required String kind,
  LambingId? lambing,
  LambId? lamb,
  int? volumeMl,
}) async {
  final Instant now = appNow();
  final SeasonId season = await _season(db);
  final int id = await db
      .into(db.careEvents)
      .insert(
        CareEventsCompanion.insert(
          season: season.value,
          lambing: Value<int?>(lambing?.value),
          lamb: Value<int?>(lamb?.value),
          kind: kind,
          occurredAt: now,
          capturedAt: now,
          volumeMl: Value<int?>(volumeMl),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return CareEventId(id);
}

/// Sets `app_settings` so all six of `07 §16.2`'s conditions hold.
///
/// **HERE AND NOT IN `harness.dart`** (`12 §5.3`): it writes rows, and every
/// writer lives in this file. A seed in the harness is a seed that gets called
/// from `pumpApp` by somebody who did not mean to.
///
/// It does **not** set the hour — condition 6 is a wall-clock fact and the
/// caller pins it with `withClock`, because R23 makes `appNow()` the only clock
/// reader and a seed that moved time would be a second one.
Future<void> armExportBanner(AppDatabase db, {Instant? lastExportedAt}) async {
  final SeasonId season = await _season(db);
  final EweId ewe = await seedEwe(db, tag: '412');
  // SOMETHING TO EXPORT. Condition 2 counts records written since the last
  // export, so a seed that only sets the columns arms nothing.
  await seedLambing(db, ewe);

  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(
      currentSeason: Value<int?>(season.value),
      lastExportedAt: Value<Instant?>(lastExportedAt),
      // NOT PROMPTED TODAY, and not dismissed for this season.
      lastExportPromptedAt: const Value<Instant?>(null),
      exportPromptDismissedForSeason: const Value<int?>(null),
    ),
  );
}

/// One ewe in the current season with an explicit [status].
///
/// **`status` IS REQUIRED AND HAS NO DEFAULT** (`03 §5.3`), and that is the
/// point: defaulting to `to_ram` would silently assert a ewe was put to the ram,
/// which is the denominator of a commercially sensitive number (#59). A seeder
/// that let the caller omit it would reintroduce the default the schema refuses.
///
/// One of `to_ram`, `scanned`, `lambed`, `barren`, `aborted`, `died`, `sold` —
/// the seven stored keys, and the schema's own CHECK refuses an eighth.
Future<EweId> seedEweInSeason(AppDatabase db, {required String tag, required String status}) async {
  final SeasonId season = await _season(db);
  final Instant now = appNow();
  final EweId ewe = await seedEwe(db, tag: tag);
  await db
      .into(db.eweSeasons)
      .insert(
        EweSeasonsCompanion.insert(
          season: season.value,
          ewe: ewe.value,
          status: status,
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return ewe;
}

/// One observation on [ewe] — `03 §5.7`, `07 §4.1`.
///
/// **`kind` IS A `vocab_terms` KEY, NOT A DOMAIN ENUM** (R17, `07 §4.1`): death
/// causes, malpresentations, routes and observations are rows, user-extensible,
/// and `lib/domain/observation_kind.dart` does not exist. The column has a
/// `RESTRICT` foreign key onto `vocab_terms`, so an invented key fails the
/// insert rather than landing an unrenderable row.
///
/// **`barren` is not one of them** (R42). A barren season is
/// `ewe_seasons.status`, and `seedEweInSeason` is the helper for it — the app
/// records what the shepherd observed and never infers it (§12.2).
Future<EweObservationId> seedEweObservation(
  AppDatabase db,
  EweId ewe, {
  required String kind,
  Instant? occurredAt,
}) async {
  final Instant now = appNow();
  final Instant at = occurredAt ?? now;
  final SeasonId season = await _season(db);
  final int id = await db
      .into(db.eweObservations)
      .insert(
        EweObservationsCompanion.insert(
          ewe: ewe.value,
          season: season.value,
          kind: kind,
          // The honest quad for a row written as it happened: `captured_at`
          // equals `occurred_at`, `time_source` is `auto`, and there is no
          // original effective time because nothing has been edited.
          occurredAt: at,
          capturedAt: at,
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return EweObservationId(id);
}

/// One note.
///
/// **`occurred_at` AND `captured_at` ARE SEPARATE PARAMETERS BECAUSE THAT
/// DISTINCTION IS WHY THE COLUMN EXISTS** (R37, `07 §4.1`). A note typed at
/// 07:00 about something at 03:20 has `occurred_at` 03:20 and `captured_at`
/// 07:00 — and the timeline sorts on the first, which is the assertion this
/// helper exists to make writable.
///
/// **`season` IS THE ONE NULLABLE ONE** (`03 §5.12`), so it is a parameter and
/// not a call to `_season`: a helper that always attached a season could never
/// seed the row the timeline's null-season case is about.
Future<NoteId> seedNote(
  AppDatabase db, {
  required String body,
  EweId? ewe,
  LambId? lamb,
  SeasonId? season,
  Instant? occurredAt,
  Instant? capturedAt,
}) async {
  final Instant now = appNow();
  final Instant at = occurredAt ?? now;
  final int id = await db
      .into(db.notes)
      .insert(
        NotesCompanion.insert(
          ewe: Value<int?>(ewe?.value),
          lamb: Value<int?>(lamb?.value),
          season: Value<int?>(season?.value),
          body: body,
          occurredAt: at,
          // **NOT `?? at` BY ACCIDENT.** Defaulting `captured_at` to the event
          // time is the honest quad for a row written as it happened; a caller
          // who wants the deferred-entry shape passes both and gets it.
          capturedAt: capturedAt ?? at,
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return NoteId(id);
}

/// One foster event on [lamb] — `03 §7`, append-only.
///
/// **ONE `rearing_dam` PLUS AN OUTCOME, AND THERE IS NO `from_ewe`.** That is
/// the whole reason the timeline's foster arm needs a window function: *"she
/// lost a lamb to a foster"* is the **previous** rearing dam, which is the `LAG`
/// of this column over the lamb's own event order. A helper that took a
/// `fromEwe` would be inventing a column and would make the arm untestable.
///
/// `rearingDam` is nullable because a lamb can leave a rearing dam without
/// gaining one — `to_bottle` and `removed_unknown` are both real outcomes.
Future<FosterEventId> seedFosterEvent(
  AppDatabase db,
  LambId lamb, {
  required String outcome,
  EweId? rearingDam,
  Instant? effectiveAt,
}) async {
  final Instant now = appNow();
  final Instant at = effectiveAt ?? now;
  final SeasonId season = await _season(db);
  final int id = await db
      .into(db.fosterEvents)
      .insert(
        FosterEventsCompanion.insert(
          lamb: lamb.value,
          season: season.value,
          rearingDam: Value<int?>(rearingDam?.value),
          outcome: outcome,
          effectiveAt: at,
          capturedAt: at,
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return FosterEventId(id);
}

/// One `ewe_summaries` row — the counts the card's summary line is assembled
/// from.
///
/// **COUNTS ONLY. THERE IS NOWHERE TO PUT A RENDERED LINE AND THAT IS THE
/// POINT** (`03 §5.13`): a stored string freezes the terminology, the locale and
/// the units at write time and is wrong the moment a record is corrected.
///
/// It is a **cache** — rebuildable, excluded from the backup, and normally
/// written by the repositories inside the transactions that invalidate it
/// (N27-T03). This helper exists so the wording can be tested at every count
/// combination without driving nine writes to reach each one.
Future<void> seedEweSummary(
  AppDatabase db,
  EweId ewe, {
  required int seasons,
  required int lambings,
  required int lambsBorn,
  required int assisted,
  required int scored,
  int? lambsBornAlive,
  SeasonId? lastObservationSeason,
}) async {
  await db
      .into(db.eweSummaries)
      .insertOnConflictUpdate(
        EweSummariesCompanion.insert(
          ewe: Value<int>(ewe.value),
          seasonsRecorded: seasons,
          lambingsRecorded: lambings,
          lambsBorn: lambsBorn,
          // **DEFAULTS TO `lambsBorn`, NOT TO ZERO.** A seeder whose born-alive
          // count silently trailed its born count would make every card in the
          // suite look like a disaster, and `?? 0` near a count is the shape
          // decision #58 exists to refuse.
          lambsBornAlive: lambsBornAlive ?? lambsBorn,
          assistedLambings: assisted,
          scoredLambings: scored,
          lastObservationSeason: Value<int?>(lastObservationSeason?.value),
          rebuiltAt: appNow(),
        ),
      );
}
