// lib/data/providers.dart — the DI root (02 §4.6, §5.1).
//
// CONVENTIONS §3.1 catalogues thirty providers for this file. THIS LEDGER SAYS
// WHICH OF THEM EXIST, so that nobody stubs one.
//
// DECLARED TODAY (N12):
//   databaseProvider            N12-T01  FutureProvider<AppDatabase>  keepAlive
//   freeTierPolicyProvider      N12-T01  Provider<FreeTierPolicy>     keepAlive
//
// NOT YET DECLARED — the epic that writes the class adds its provider in the
// same commit, and deletes its line from this list:
//   settingsRepositoryProvider · settingsProvider · themeProvider ·
//     unitsProvider · terminologyProvider                            N12-T02
//   flockRepositoryProvider · tagIndexProvider                       N13
//   lambingRepositoryProvider                                        N16
//   noteRepositoryProvider · mediaStoreProvider ·
//     cameraServiceProvider · voiceRecorderProvider                  N15
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
import 'package:shed_book/domain/free_tier.dart';

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
