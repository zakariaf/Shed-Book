# N12-T01 — `providers.dart` — the DI graph as far as it can honestly reach

| | |
|---|---|
| **Epic** | [N12 — The DI root, settings, the ticker and the harness](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 1 of 5 |
| **Depends on** | N11-T09 |
| **Commit** | one commit · `feat(data): providers.dart and the DI graph` |

## 1. Why this task exists

`databaseProvider` as a `FutureProvider`, keepAlive, and the repository providers derived
from it — for the repositories that exist today. Never `Provider<AppDatabase>`, never
`overrideWithValue` in `lib/`.

The count of repositories that exist today is **zero**. `CONVENTIONS` §3.1 tabulates thirty providers
for this file; twenty-eight of them name a class no file in the project declares. This task lands the
two that are real, plus a header ledger saying where each of the others comes from — so the next person
to open `providers.dart` learns the graph's true extent from the file rather than from the catalogue.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4–§5 | the provider graph, the override rules and the harness |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3 | `SettingsRepository`'s ownership of `app_settings`, and every provider name |
| `docs/engineering/12-testing.md` | §4, §6.2 | the seven fakes and the variant table — and what may exist yet |
| `docs/engineering/02-state-di-navigation.md` | §1 · §2.1–§2.4 · §3 · §4.2 · §4.6 · §5.1–§5.2 | why 2.6.1 exactly; the ban list and the thirteen `rp3.*` rows; the spelling card; the auto-dispose policy; **which file each provider is declared in**; the graph; production has zero overrides |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rules 3, 4 and `layer.root` · §2.8 · §2.10 · §3.1 · §3.5 · §4.3 | `lib/data/` may not import material; `openAppDatabase()`'s shape; `FreeTierPolicy`; the provider catalogue; what is *not* in the graph; the five documented naming exceptions |
| `docs/engineering/01-architecture.md` | §4.1 · §6.3 | repository providers `await ref.watch(databaseProvider.future)`; the post-frame boot kick that already reads this provider |
| `docs/research/00-tech-decisions.md` | §5.1 · #17–#21 | `flutter_riverpod` **2.6.1**, no caret; `databaseProvider` is a `FutureProvider`; `main()` awaits nothing |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | every provider, its scope and its rebuild behaviour — and the 2.6.1 import path, because `package:riverpod/` is a G2 failure |
| `shed-conventions` | §3 names every provider in the project and this file must match it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/providers_test.dart`
- **Test** — `'databaseProvider is a keepAlive FutureProvider and no override appears under lib/'`
- **Why it is red today** — nothing wires the database to a widget tree.

```bash
fvm flutter test test/data/providers_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it proves three separable things rather than one vague one:

1. **Shape.** `expect(databaseProvider, isA<FutureProvider<AppDatabase>>())`, and the source text of
   `lib/data/providers.dart` carries no `.autoDispose` on that declaration. On 2.6.1 keepAlive is the
   *absence* of `.autoDispose` — there is nothing positive to assert, so assert the absence.
2. **Reachability.** Build a bare `ProviderContainer()` with **no** overrides, read
   `databaseProvider.future`, and expect it to throw — because `openAppDatabase()` asserts it is not
   running under `flutter_test` and throws with the name of the override to add (`CONVENTIONS` §2.8,
   R12). Assert the message names `databaseProvider`. That one assertion proves the provider is wired
   to the real opener rather than to a stub, and it is the tripwire `02 §5.4`'s anti-pattern relies on.
3. **Policy.** Scan every `.dart` file under `lib/` (skipping `*.g.dart` and `*.drift.dart`) for
   `overrideWith` and `overrideWithValue`; expect zero hits.

**Green.** The minimum code that passes, and nothing beyond it — the graph, with a policy assertion that no `overrideWithValue` exists under `lib/`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 4 (wiring) and step 7 (tests) only.** No schema — this task stores nothing, and §8's rule is
that skipping the schema step is said out loud, so say it in the commit message. No domain, no data
verb, no controller, no UI, no ARB string.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/providers.dart` | **New.** The DI root. Two provider declarations and the header ledger. Imports `package:flutter_riverpod/flutter_riverpod.dart`, `../core/db/connection.dart`, `../core/db/database.dart` and `../domain/free_tier.dart` — and nothing else |
| 2 | `test/data/providers_test.dart` | **New.** The anchor, plus the shape, reachability, policy and ledger cases in §5.4 |

That is the whole diff. `lib/app.dart` is **not** touched: N11-T05 already wrote
`ref.read(databaseProvider.future).ignore()` in the post-frame callback against a provider that did not
exist yet, and this task is what makes that line resolve. If you find yourself needing to edit
`app.dart`, read it first — the edit you want is probably N11's and was missed.

### 5.2 The signatures

```dart
// lib/data/providers.dart
//
// The DI root (02 §4.6, §5.1). CONVENTIONS §3.1 catalogues thirty providers for
// this file. This ledger says which of them exist, so that nobody stubs one.
//
// DECLARED TODAY (N12):
//   databaseProvider            N12-T01  FutureProvider<AppDatabase>  keepAlive
//   freeTierPolicyProvider      N12-T01  Provider<FreeTierPolicy>     keepAlive
//   settingsRepositoryProvider  N12-T02
//   settingsProvider · themeProvider · unitsProvider · terminologyProvider
//                               N12-T02
//
// NOT YET DECLARED — the epic that writes the class adds its provider in the
// same commit, and deletes its line from this list:
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
// A provider whose body throws UnimplementedError is not a placeholder; it is a
// lie that compiles. If you need one to make something else build, the thing
// you are building belongs in the later epic too.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/connection.dart';
import '../core/db/database.dart';
import '../domain/free_tier.dart';

/// Opened from the first post-frame callback in `lib/app.dart` (decision #21,
/// 01 §6.3). keepAlive — reopening SQLite at 03:41 because the last screen
/// popped is absurd (02 §4.2). Never `Provider<AppDatabase>`, and never
/// overridden with a value: tests use `overrideWith((ref) async => db)`
/// (02 §5.4, 12 §5.1).
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();        // lib/core/db/connection.dart (R12)
  ref.onDispose(db.close);
  return db;
});

/// Pure policy: no database, no clock — `decide()` takes `now` as a parameter
/// (CONVENTIONS §2.10, R69). Declared now because `lib/domain/free_tier.dart`
/// has existed since N06-T10 and because N14's `createEwe` consults it from its
/// first commit (critique defect S5). Nothing on a shed screen reads it.
final freeTierPolicyProvider = Provider<FreeTierPolicy>((ref) => FreeTierPolicy());
```

The shape every later repository provider takes is `01 §4.1`'s and `02 §5.1`'s. Put it in the ledger
comment so N13 copies it rather than inventing it:

```dart
// The shape, for the epics that add one. Asynchrony is contagious upwards:
// decision #20 makes databaseProvider a FutureProvider, so a
// `Provider<FlockRepository>` could only reach it through an AsyncValue
// accessor — and 02 §2.2 bans every one of them.
//
// final flockRepositoryProvider = FutureProvider<FlockRepository>((ref) async {
//   return FlockRepository(await ref.watch(databaseProvider.future));
// });
```

### 5.3 The details that are easy to get wrong

- **Never write the type name `Ref`.** 2.6.1's `Ref` is `Ref<State>` and its type parameter is already
  `@Deprecated('Will be removed in 3.0')`, so naming it is either a `strict-raw-types` failure or a
  `deprecated_member_use` info — and `--fatal-infos` turns both into a red build. Let the create
  callback's parameter type be **inferred**: `FutureProvider<AppDatabase>((ref) async { … })`, never
  `((Ref ref) async { … })`. There is a gate row for the written type name (`02 §2.4`) and this file is
  the likeliest place in the project to trip it.
- **`ref.mounted` does not exist on 2.6.1.** If you reach for it after the `await`, you have found the
  reason `WriteController` carries a `_disposed` field (T04). `databaseProvider` needs no such field:
  `ref.onDispose(db.close)` is registered after the `await`, which is correct, because there is nothing
  to close until `openAppDatabase()` returns.
- **`ref.onDispose(db.close)` is a tear-off, and its position matters.** After the `await`, before the
  `return`. Registering it first would close a database that does not exist; omitting it leaks a drift
  isolate for the life of the process.
- **keepAlive is spelled by not writing `.autoDispose`.** `ref.keepAlive()` is used **nowhere** in this
  codebase (`02 §4.2`). If you reach for it you have put `.autoDispose` on a hub provider — remove the
  `.autoDispose` instead.
- **`import 'package:flutter_riverpod/flutter_riverpod.dart';`, never `package:riverpod/riverpod.dart`.**
  `riverpod` is a *transitive* dependency, not a declared one, and gate G2 scans direct dependencies
  against `tool/policy_allowlist.txt`. The wrong import compiles locally and fails CI.
- **`lib/data/` may not import `package:flutter/material.dart`** (layer rule 4,
  `layer.data_no_material`). `flutter_riverpod` drags material in transitively and that is fine — the
  gate scans import *statements*. Do not add a material import "for `@immutable`"; that lives in
  `package:flutter/foundation.dart`.
- **`lib/main.dart` and `lib/app.dart` may not import `lib/core/db/`** (`layer.root`). `app.dart`
  reaches the database through `ref.read(databaseProvider.future)`, whose static type is
  `Future<AppDatabase>` by **inference**. The moment somebody writes
  `final AppDatabase db = await ref.read(databaseProvider.future);` in `app.dart`, the import appears
  and `layer.root` fires. Keep the boot kick as `.ignore()` with no named type.
- **Do not declare `entitlementProvider` here, even though the catalogue lists it.** Decision #90:
  nothing on the 3am path may watch it, and the widget test that holds that property is N13's.
  Declaring it early gives five screens something to accidentally watch before the test exists.
- **`freeTierPolicyProvider` is a plain `Provider`, not a `FutureProvider`.** `FreeTierPolicy` takes no
  database and no clock; `decide()` takes `now` as an argument. If you find yourself awaiting anything
  to construct it, you are about to give the policy a data dependency its signature deliberately
  refuses.
- **The five documented naming exceptions are exceptions, not a pattern** (`CONVENTIONS` §4.3):
  `databaseProvider`, `settingsProvider`, `wakelockProvider`, `minuteTickProvider`, `tagIndexProvider`.
  Everything else is `<typeNameLowerCamel>Provider`. `appDatabaseProvider` and `dbProvider` are not
  alternative spellings of the first one; they are defects.
- **`AppDatabase` is not reachable through a static field.** There is no `AppDatabase.instance`. The
  only `\.instance\b` in `lib/` is `LocalLog.instance` (N11-T09), and `02 §4.6` says why: the error
  handlers are installed before any `ProviderScope` exists. Nothing else gets that argument.
- **Do not add a `clockProvider`, a `Clock` interface or a `SystemClock`** (`CONVENTIONS` §3.5,
  decision #46). The clock is ambient and is read only through `appNow()`. Two clock seams are worse
  than none: a test that fakes one does not fake the other.

### 5.4 The full test set

`test/data/providers_test.dart` — pure unit tests plus source-text sweeps. No widget test: there is
nothing to pump until T05.

| Case | What it asserts |
|---|---|
| `'databaseProvider is a keepAlive FutureProvider and no override appears under lib/'` | **The anchor.** The three parts in §4: shape, reachability, policy |
| `'reading databaseProvider under flutter_test throws and names the override to add'` | A bare `ProviderContainer()`, `addTearDown(container.dispose)`, and the thrown message contains `databaseProvider`. The anti-pattern tripwire from `02 §5.4` |
| `'databaseProvider carries no .autoDispose'` | Source text over `lib/data/providers.dart`. keepAlive has no positive spelling, so the absence is the assertion |
| `'Provider<AppDatabase> appears nowhere under lib/'` | Source text. Decision #20 and `CONVENTIONS` §3.5 |
| `'overrideWith and overrideWithValue appear nowhere under lib/'` | Source text over every `.dart` under `lib/`, skipping generated files. Duplicates the `rp3.overrides` gate row deliberately: the gate proves it in CI, this proves it in the tier a developer runs first |
| `'package:riverpod/ is imported nowhere'` | Source text over `lib/` and `test/` |
| `'the type name Ref appears nowhere in providers.dart'` | Source text, word-anchored so `WidgetRef` and `ref.` do not false-positive |
| `'freeTierPolicyProvider resolves without touching the database'` | Read it from a bare container; expect a `FreeTierPolicy`. Proves the first frame's policy object needs nothing async — the property decisions #21 and #90 both lean on |
| `'the declared provider set equals the header ledger'` | Parse the top-level `final …Provider =` declarations out of `providers.dart` and compare with the `DECLARED TODAY` block. The ledger is the contract; a provider added without a ledger line fails here |
| `'every declared provider name appears in CONVENTIONS §3.1'` | The declared set is a **subset** of the catalogue, never a superset. Catches an invented name (`dbProvider`, `appDatabaseProvider`) at the moment it is written |

**Nothing here is time-shaped.** No wall clock is read and no `Instant` is constructed, so there is no
`uk-zone` case in this task. The first one in this epic is T02's `InstantConverter` round trip.

## 6. Constraints that bind this task

- **Offline purity** — this file constructs the database and, later, every gateway. Nothing in its
  import list may reach a network package; G2 asserts the direct-dependency allowlist over
  `pubspec.lock` on every push.
- **Honest reach** — a provider is declared when its subject exists, and not before. This is critique
  defect S1's rule applied one layer below the harness.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'databaseProvider is a keepAlive FutureProvider and no override appears under lib/'` passes, and was seen to fail first for the stated reason
- [ ] `databaseProvider` is a `FutureProvider`, keepAlive
- [ ] no `Provider<AppDatabase>` anywhere
- [ ] no override under `lib/` — overrides are a test concern
- [ ] every Riverpod-3-only API is still absent, per N03-T06
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `lib/data/providers.dart` declares exactly **two** providers, and the header ledger names the epic that adds each of the other twenty-eight
- [ ] the type name `Ref` appears nowhere; the create callback's parameter type is inferred
- [ ] `ref.onDispose(db.close)` is registered after the `await` and before the `return`
- [ ] `ref.keepAlive()` and `UnimplementedError` appear nowhere in the file
- [ ] the commit message says the schema step was skipped, and why — this task stores nothing

## 8. Verification

```bash
fvm flutter test test/data/providers_test.dart
make check
make test
```

```bash
grep -n "autoDispose\|keepAlive()" lib/data/providers.dart     # expect zero
grep -rn "overrideWith" lib/                                    # expect zero
grep -rn "package:riverpod/" lib/ test/                         # expect zero
grep -rn "Provider<AppDatabase>" lib/                           # expect zero
grep -n "UnimplementedError" lib/data/providers.dart            # expect zero
grep -c "^final .*Provider = " lib/data/providers.dart          # expect 2
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): providers.dart and the DI graph`
