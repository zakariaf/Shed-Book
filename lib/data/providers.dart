// lib/data/providers.dart — the DI root (02 §4.6, §5.1).
//
// CONVENTIONS §3.1 catalogues thirty providers for this file. THIS LEDGER SAYS
// WHICH OF THEM EXIST, so that nobody stubs one.
//
// DECLARED TODAY (N12):
//   databaseProvider            N12-T01  FutureProvider<AppDatabase>  keepAlive
//   freeTierPolicyProvider      N12-T01  Provider<FreeTierPolicy>     keepAlive
//   settingsRepositoryProvider  N12-T02  Provider<SettingsRepository>
//   settingsProvider            N12-T02  StreamProvider<AppSetting>
//   themeProvider               N12-T02  Provider<ShedThemeSet>       synchronous
//   unitsProvider               N12-T02  Provider<WeightUnit>
//   terminologyProvider         N12-T02  Provider<Terminology>
//   flockRepositoryProvider     N13-T02  Provider<FlockRepository>
//   tagIndexProvider            N13-T02  StreamProvider<List<TagIndexEntry>>  keepAlive
//   lambingRepositoryProvider   N14-T02  Provider<LambingRepository>
//   mediaStoreProvider          N15-T01  Provider<MediaStore>                 keepAlive
//   cameraServiceProvider       N15-T02  Provider<CameraService>              keepAlive
//
// NOT YET DECLARED — the epic that writes the class adds its provider in the
// same commit, and deletes its line from this list:
//   noteRepositoryProvider · voiceRecorderProvider                   N15
//   fosterRepositoryProvider                                         N18
//   penRepositoryProvider                                            N19
//   treatmentRepositoryProvider                                      N20
//   exportRepositoryProvider · shareServiceProvider                  N21
//   restoreServiceProvider · mediaSweeperProvider                    N23
//   reminderRepositoryProvider · reminderReconcilerProvider ·
//     notificationSchedulerProvider                                  N24
//   seasonRepositoryProvider                                         N28
//   wakelockProvider                                                 N29
//   entitlementRepositoryProvider · entitlementProvider ·
//     purchaseServiceProvider                                        N30
//
// A PROVIDER WHOSE BODY THROWS UnimplementedError IS NOT A PLACEHOLDER; IT IS A
// LIE THAT COMPILES. If you need one to make something else build, the thing you
// are building belongs in the later epic too.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/camera_service.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/terminology/terminology.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

/// Opened from the first post-frame callback in `lib/app.dart` (#21, `01 §6.3`).
///
/// **keepAlive, which has no positive spelling** — it is the absence of
/// `.autoDispose`, so the absence is the assertion. Reopening SQLite at 03:41
/// because the last screen popped is absurd (`02 §4.2`).
///
/// **Never `Provider<AppDatabase>`** (#20): a synchronous provider would have to
/// be overridden with an already-open database, which means somebody awaited it
/// before the first frame — the exact thing `main()` refuses to do.
///
/// Tests supply their own database through a container override that returns a
/// FUTURE, never one that supplies an already-built value (`02 §5.4`,
/// `12 §5.1`) — described rather than spelled, because `rp3.overrides` scans
/// this file for exactly those two method names and production has zero of
/// them. Reading it under `flutter_test`
/// without an override throws, and that is a TRIPWIRE rather than a defect:
/// `openAppDatabase()` asserts it is not running under a test binding, so the
/// mistake fails loudly at the first read instead of quietly opening a real file
/// in somebody's home directory.
// The callback parameter is deliberately UNTYPED. Riverpod 2.6.1 deprecates
// `FutureProviderRef` in favour of `Ref` — and `Ref` is exactly the token
// N12-T01's test bans from this file, because it is the Riverpod 3 spelling and
// this project is pinned to 2.6.1 exactly. Naming neither satisfies both: the
// type is inferred, no deprecated member is used, and no Riverpod 3 idiom
// appears.
final FutureProvider<AppDatabase> databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final AppDatabase db = await openAppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Pure policy: **no database, no clock** — `decide()` takes `now` as a
/// parameter (`CONVENTIONS §2.10`, R69).
///
/// Declared now rather than at N30 because `lib/domain/free_tier.dart` has
/// existed since N06 and N14's `createEwe` consults it from its first commit
/// (critique defect S5). **Nothing on a shed screen reads it** — decision #90
/// keeps every entitlement question off the five 3am screens at any state.
final Provider<FreeTierPolicy> freeTierPolicyProvider = Provider<FreeTierPolicy>(
  (ref) => const FreeTierPolicy(),
);

/// The only writer of `app_settings`. Depends on the database, so it is only
/// readable once the boot kick has resolved.
final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider).requireValue),
);

/// **A plain `Provider`, not a `FutureProvider`, even though `root()` is
/// async.** The gateway itself is cheap to construct and resolves its directory
/// per call; making the PROVIDER async would put an `AsyncValue` in front of
/// every caller for a value that is never awaited at construction.
final Provider<CameraService> cameraServiceProvider = Provider<CameraService>(
  (ref) => CameraService(),
);

final Provider<MediaStore> mediaStoreProvider = Provider<MediaStore>((ref) => MediaStore());

final Provider<LambingRepository> lambingRepositoryProvider = Provider<LambingRepository>(
  (ref) => LambingRepository(db: ref.watch(databaseProvider).requireValue),
);

final Provider<FlockRepository> flockRepositoryProvider = Provider<FlockRepository>(
  (ref) => FlockRepository(
    db: ref.watch(databaseProvider).requireValue,
    // The policy is pure — no database, no clock — so it is a plain collaborator
    // rather than something the repository reaches for. `decide()` takes `now`.
    policy: ref.watch(freeTierPolicyProvider),
  ),
);

/// The whole active flock's tags, ranked in Dart by the keypad.
///
/// **`tagIndexProvider`, and `flockTagCacheProvider` is a banned spelling**
/// (R26): `07` used the latter in two places and lost — *"'cache' names the
/// implementation while 'index' names the value."* It is also one of the five
/// documented exceptions to the `<typeNameLowerCamel>Provider` rule
/// (`CONVENTIONS §4.3`), so it is not `tagIndexEntriesProvider` either.
///
/// **`keepAlive`, not `autoDispose`, and the reason is 3am** (`02 §4.2`): hub
/// reads are re-entered constantly through a night, and disposing and
/// re-querying on every pop is exactly the wrong trade. An autoDispose index
/// means the `412 →` window re-opens every time the shepherd pops back.
///
/// Nothing invalidates it. drift's `watch()` rebuilds it when an animal is
/// culled or created, and a manual invalidate on a drift-backed provider is a
/// defect (`02 §4.1`).
final StreamProvider<List<TagIndexEntry>> tagIndexProvider = StreamProvider<List<TagIndexEntry>>((
  ref,
) async* {
  // Awaited FIRST so `flockRepositoryProvider`'s `requireValue` is safe: the
  // first frame paints before the database opens, and reading the repository
  // ahead of that would throw rather than wait.
  await ref.watch(databaseProvider.future);
  yield* ref.watch(flockRepositoryProvider).watchTagIndex();
});

/// The one settings row, watched. **Carries the ROW class**, not a hand-rolled
/// view model: a second shape is a second place a column can be forgotten.
final StreamProvider<AppSetting> settingsProvider = StreamProvider<AppSetting>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// **SYNCHRONOUS, and that is the point** (`06 §2.1`, R29).
///
/// The first frame paints BEFORE the database opens, so this provider cannot
/// await anything. Its not-yet-loaded arm is the `const` night pair — which is
/// why N09 had to build that pair as a `const` before `app.dart` could name it.
///
/// Reduce-motion is applied at the WIDGET, not here: `prefersReducedMotion`
/// needs a `BuildContext` and this provider has none.
final Provider<ShedThemeSet> themeProvider = Provider<ShedThemeSet>((ref) {
  // SWITCHED ON THE AsyncValue, never read through a nullable accessor
  // (gate row rp3.value_or_null, #18). The pattern makes the not-yet-loaded arm
  // a branch somebody had to write rather than a `?.` somebody could forget —
  // and that arm is the const night pair, which is the whole reason N09 built it
  // as a const.
  final ShedPaletteId id = switch (ref.watch(settingsProvider)) {
    AsyncData<AppSetting>(value: final AppSetting s) => switch (s.palette) {
      'amber' => ShedPaletteId.amber,
      'red' => ShedPaletteId.deepRed,
      // An unrecognised key lands on night too. A restore from a newer schema
      // can carry a palette this build has never heard of, and the first frame
      // is not the place to find out.
      _ => ShedPaletteId.night,
    },
    _ => ShedPaletteId.night,
  };
  return buildShedThemeSet(id);
});

/// `Provider<WeightUnit>` (R68). **Never inferred from the locale**: a UK
/// smallholder may genuinely want lb, and a wrong inference silently mislabels
/// every weight ever recorded.
final Provider<WeightUnit> unitsProvider = Provider<WeightUnit>((ref) {
  switch (ref.watch(settingsProvider)) {
    case AsyncData<AppSetting>(value: final AppSetting s):
      try {
        return WeightUnit.fromKey(s.weightUnit);
      } on FormatException {
        // Same reasoning as the palette: an unknown key is a restore from a
        // newer build, not a reason to fail a read.
        return WeightUnit.kg;
      }
    case _:
      // The default is kg — settled, not open (§7.0 ruling 3, UK and Ireland
      // first) — and it is never inferred from the locale.
      return WeightUnit.kg;
  }
});

/// The shepherd's words for their own animals.
///
/// `Terminology` takes DEFAULTS and OVERRIDES as two separate maps, and keeping
/// them separate is what makes a half-filled override fall back instead of
/// rendering a blank button at 3am.
///
/// **Both maps are empty here, and that is a seam rather than a gap.**
///
/// The defaults come from the ARB (`05 §8.1`) and reading the ARB needs a
/// `BuildContext` this provider has none of. The overrides come from a table
/// `SettingsRepository.watchTerminologyOverrides()` already exposes and this
/// task already tests — but wiring them needs a SECOND provider, and CONVENTIONS
/// §3.1's catalogue does not name one. Inventing `terminologyOverridesProvider`
/// was the first attempt and the subset assertion caught it, which is precisely
/// what that assertion is for: the catalogue is the authority on names, and a
/// provider it does not name is a name nobody agreed to.
///
/// So N29 — which edits the overrides and has the context to read the ARB —
/// assembles the real pair, and adds its provider to §3.1 in the same commit.
/// N12 only reads (`CONVENTIONS §2.13`), and empty-over-empty is the honest
/// identity: every lookup falls through to the caller's own word.
final Provider<Terminology> terminologyProvider = Provider<Terminology>(
  (ref) => const Terminology(<AnimalClass, TermLabel>{}, <AnimalClass, TermLabel>{}),
);
