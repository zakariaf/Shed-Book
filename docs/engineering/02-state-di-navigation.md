# 02 — State, DI and navigation

This document governs every line of Riverpod, every provider declaration, every screen controller, every `Navigator` call and the app's lifecycle/resume behaviour. You need it before you write the second screen, and you need §2 before you copy a single line of Riverpod from anything published after 2025 — every such tutorial shows the Riverpod-3 API, which does not compile here and cannot be installed here. Read `01-architecture.md` first for the layer rules and `main()`; this document assumes both.

> **Decisions applied:** #17 (state management + DI: `flutter_riverpod` 2.6.1 exact pin), #18 (banned Riverpod-3 APIs), #19 (Riverpod 2.6.1 spellings), #20 (provider shapes: `FutureProvider<AppDatabase>`), #21 (bootstrap: `main()` awaits nothing), #22 (double-tap protection), #23 (Navigator 1.0 + typed route helpers), #24 (no state restoration), #3 (`build_runner` range), #11 (write path: no draft state), #12 (read path: drift `watch()` streams, no `combineLatest`), #13 (`WriteOutcome`), #16 (no codegen but drift), #35 (in-memory tag filter, no keypad debounce), #46 (one clock: `package:clock`), #53 (`RecordedTime` provenance survives resume), #54 (warnings are flagged, never fixed), #63 (`reconcile()`, four call sites), #66 (one 60 s ticker), #67 (the "in the pens" list shares the pen-board query), #69 (undo does not survive process death), #79 (wakelock released on any non-resumed state), #90 (first frame is entitlement-agnostic), #91/#92 (`WriteRefused` renders as the calm static row, never a modal), #103 (commit-then-confirm), #111 (`NativeDatabase.memory()` in tests), #112 (hand-written fakes for the six gateways), #113 (`Clock.fixed` freezes time), #123 (`LocalLog`, no analytics), #126 (performance is measured by hand, not in CI).
>
> **Owner's rulings honoured** (decision-record §7.0): tags are unique among **active** animals only — §10.2; UK/Ireland first, so every time in this document is 24-hour `en_GB` — §9.2; OCR and voice tag entry are cut from v1, so no route, provider or controller here exists for either; the free tier is season-primary and nothing on the 3am path watches `entitlementProvider` — §5.1, §10.3.

---

## 1. Why `flutter_riverpod: 2.6.1`, exactly

`riverpod` 3.4.1 declares `test: ^1.0.0` in its **runtime** `dependencies`, and `flutter_riverpod` 3.4.1 declares `flutter_test`. `package:test` caps `analyzer <13.0.0`; `drift_dev` ≥2.34.1 requires `analyzer ^13.0.0`. On this app's real stack `flutter pub get` therefore fails outright — reproduced independently by two reviewers. This is the solver output from the c2 probe pubspec (`shed_probe`, `flutter_riverpod: ^3.4.1` + `drift` + `drift_dev` + `build_runner`), quoted verbatim:

```
Because flutter_riverpod >=3.4.1 depends on riverpod 3.4.1 which depends on test ^1.0.0,
one of flutter_test from sdk or build_runner >=2.0.0 or drift_dev >=2.34.1+1 or
flutter_riverpod >=3.4.1 must be false.
So, because shed_probe depends on both build_runner ^2.4.0 and drift_dev ^2.34.5,
version solving failed.
```

Shed Book's own `build_runner` constraint is tighter — `">=2.15.0 <2.15.2"` (decision #3) — and fails identically, for the same reason and in the same sentence of solver output: the conflict is `test` → `analyzer <13` vs `drift_dev` → `analyzer ^13`, and no `build_runner` range escapes it.

The maintainer has declined to change it (riverpod#4791, closed WONTFIX 2026-06-23). The `any`-constraint workaround resolves but silently pins `drift_dev` back to 2.34.0 and `analyzer` to 12.1.0 — it trades your database toolchain for a state-management convenience. Riverpod 3 was **not** rejected for adding a network path; it does not add one. It was rejected on dependency resolution alone. See `../research/00-tech-decisions.md` §2 row 17 and §5.3.

**Consequences you live with, and must not try to fix:**

1. `pubspec.yaml` says `flutter_riverpod: 2.6.1` — **no caret**. `^2.6.1` is a defect; CI asserts the exact string in `pubspec.yaml` and the exact resolved version in `pubspec.lock`.
2. 2.6.1 is frozen upstream. There will be no bug fixes. Accepted: the surface used here is `Provider`, `FutureProvider`, `StreamProvider`, `NotifierProvider`, `.family`, `.autoDispose`, `.select`, `ProviderScope` and `ProviderContainer`, all of which have been stable since 2.0.
3. Always `import 'package:flutter_riverpod/flutter_riverpod.dart';`. **Never** `package:riverpod/riverpod.dart` — `riverpod` is a transitive dependency, not a declared one, and gate G2 scans direct dependencies (`13-build-ci-release.md`).
4. If Riverpod is ever abandoned, the documented fallback is `provider` 6.1.5+1, at a cost of ~150–200 lines of `StreamSubscription` lifecycle across 12 screens. Do not pre-emptively abstract for it.
5. **Open, and it is not yours to close on a whim:** the Riverpod 3.0.0 changelog (2025-04-30) says *"This major version is a transition version… It is quite possible that a 4.0.0 will be released relatively soon in the future."* That is a maintainer's signal, **not a schedule** — treat any date attached to it as unverified. If 4.0.0 lands during development *and* drops the `test` runtime dependency, re-evaluate: a 2.6.1 → 4.x jump may be cheaper than 2.6.1 → 3.x → 4.x. The ban list in §2 is what makes that jump cheap; every banned API is one you would have to unwrite.

`lib/domain/` is pure Dart and imports **no** Riverpod at all. Providers exist in `lib/data/`, `lib/core/` and `lib/features/` only.

---

## 2. The Riverpod-3 ban list

This is the single most likely way this codebase breaks. Every entry below appears in current tutorials, blog posts and LLM output. **Eight of them fail the analyzer**, which is the good case: CI runs `flutter analyze --fatal-infos`, so they never reach a device. The rest compile clean and are still banned — those are the ones that need the greps in §2.4.

### 2.1 Does not compile on 2.6.1 — the analyzer catches these

| Riverpod-3 API you will be shown | Error on 2.6.1 | Write this instead |
|---|---|---|
| `ProviderScope(retry: (_, __) => null, …)` | `The named parameter 'retry' isn't defined` | Nothing. 2.6.1 has **no** provider auto-retry, so there is nothing to disable. Delete the line; do not port the pitfall it defends against. |
| `class X extends Notifier<S>` used with `NotifierProvider.autoDispose<X, S>` | `'X' doesn't conform to the bound 'AutoDisposeNotifier<S>'` | `class X extends AutoDisposeNotifier<S>` |
| `class X extends AsyncNotifier<S>` used with `.autoDispose` | same, with `AutoDisposeAsyncNotifier<S>` | `class X extends AutoDisposeAsyncNotifier<S>` |
| Family args delivered through the constructor: `class C extends AsyncNotifier<T> { C(this.id); }` + `AsyncNotifierProvider.autoDispose.family<C, T, int>(C.new)` | `'C' doesn't conform to the bound 'AutoDisposeFamilyAsyncNotifier<T, int>'` **and** `The argument type 'C Function(int)' can't be assigned to the parameter type 'C Function()'` | `class C extends AutoDisposeFamilyAsyncNotifier<T, int>` with `Future<T> build(int arg)`, a **zero-argument** constructor tear-off, and `this.arg` inside the class. |
| `AsyncNotifierProvider.family<C, T, int>(C.new, isAutoDispose: true)` | `The named parameter 'isAutoDispose' isn't defined` | `AsyncNotifierProvider.autoDispose.family<C, T, int>(C.new)` |
| `if (!ref.mounted) return;` after an `await` | `The getter 'mounted' isn't defined for the type 'Ref'` | 2.6.1 has **no** `Ref.mounted`. Track disposal yourself: a `bool _disposed` field set from `ref.onDispose`. That is exactly why `WriteController` carries one (§7) — it is not a stylistic choice. |
| A bare `Ref ref` parameter — the 3.x unified `Ref` | `strict-raw-types` failure, or `deprecated_member_use` on the type argument | 2.6.1's `Ref` is `Ref<State>` and its type parameter is already marked `@Deprecated('Will be removed in 3.0')`. **Never name `Ref` in this codebase.** Let the create callback's parameter type be inferred (`Provider<T>((ref) => …)`), and inside a `Notifier` use the inherited `ref`. |
| A `ProviderObserver` written against 3.x: `void didUpdateProvider(ProviderObserverContext context, Object? previous, Object? next)` | `ProviderObserverContext` is undefined, and the override does not match the supertype | 2.6.1's signature is `didUpdateProvider(ProviderBase<Object?> provider, Object? previousValue, Object? newValue, ProviderContainer container)`. 2.6.1's `ProviderObserver` is an `abstract class`; 3.x's is `abstract base class` and adds `didCreateProviderContainer` / `didUnmountProvider`, which do not exist here. |

Every row above was checked against `~/.pub-cache/hosted/pub.dev/riverpod-2.6.1/lib/src/` and the 3.4.1 source beside it, not from memory: `Ref.mounted` is `riverpod-3.4.1/lib/src/core/ref.dart:112` and has no counterpart on 2.6.1's `Ref`; `ProviderObserver` is `riverpod-2.6.1/lib/src/framework/container.dart:714` versus `riverpod-3.4.1/lib/src/core/provider_container.dart:1407`. If you doubt a row, read those two files — they are on your disk.

The analyzer is the real gate here, and CI already runs `flutter analyze --fatal-infos`. The greps in §2.4 exist anyway, because the analyzer never sees a wrong snippet pasted into a comment, a doc or a `//` TODO — and that is where the next wrong copy comes from.

### 2.2 Compiles on 2.6.1, banned anyway

| API | Why it is banned | Write this instead |
|---|---|---|
| `AsyncValue.valueOrNull` | Removed in 3.x in favour of `.value`. Banning it now makes a future 4.0 migration near-free (§5.1 of the decision record). | Exhaustive `switch` over `AsyncData` / `AsyncError` / `AsyncLoading` — see §4.5. |
| `AsyncValue.value`, `.requireValue`, `.hasValue`, `.asData` | Same forward-compatibility rule, and every one of them is a place to accidentally render a stale or null value at 3am. | The same exhaustive `switch`. **No `AsyncValue` accessor is used anywhere in this codebase.** |
| `StateProvider` | Legacy; moved to `legacy.dart` in 3.0.0. | `NotifierProvider` + a `Notifier`. |
| `StateNotifierProvider` / `StateNotifier` | Same. | `NotifierProvider` + a `Notifier`. |
| `ChangeNotifierProvider` | Legacy, and mutable state fights Flutter's own immutable-model guidance. | `NotifierProvider` over an `@immutable` state class. |

### 2.3 Not in this project at all

| Thing | Why |
|---|---|
| `ProviderContainer.test(...)` | 3.x only. It is the entire reason for the `test` runtime dependency that makes 3.x uninstallable here. Use `ProviderContainer(overrides: […])` + `addTearDown(container.dispose)`. |
| `WidgetTester.container` | 3.x only. Build your own container and pass it via `UncontrolledProviderScope` (§5.4). |
| Mutations (`Mutation`, `ref.mutate`) | 3.x, and *experimental* there. The double-tap gate is `WriteController.guard()` (§7). |
| Riverpod 3 experimental offline persistence (`package:riverpod/experimental/…`) | Explicitly unstable, and aimed at caching network responses. SQLite is already the durable source of truth. |
| `riverpod_generator` / `riverpod_annotation` / `@riverpod` | `riverpod_generator` 4.0.6 is unresolvable in *any* project (declares `analyzer ^13.0.0` while pinning `riverpod_analyzer_utils 1.0.0-dev.10`, which needs `analyzer ^12.0.0`). Providers are hand-written; each is one line. Decision #16: drift is the only generator. |
| `riverpod_lint` | Same self-contradiction at 3.1.6, and no verified publisher tag. Its rules live in `tool/check_policy.dart` instead. |
| `hooks_riverpod` / `flutter_hooks` | A second mental model for 12 simple screens, plus the same 3.x runtime dependency. |
| `ProviderObserver` | Permitted as a **debug-only** logger behind `kDebugMode`, written against the 2.6.1 four-argument signature (§2.1, last row); never wired to anything that persists or transmits. There is no analytics in this app (decision #123). |
| `Ref.mounted`, `ProviderContainer.retry`, `ProviderScope.retry` | 3.x only. No auto-retry exists on 2.6.1 and there is nothing to disable; disposal is tracked by hand (§7). |

### 2.4 The CI rules

These are rows in the single `tool/check_policy.dart` rule table (decision #10), not separate scripts. Scope is `lib/**` and `test/**` unless stated; `*.g.dart` is skipped.

| Pattern | Scope | Message |
|---|---|---|
| `retry:` | lib, test | Riverpod-3 only. 2.6.1 has no auto-retry. This app has no retries of any kind, so the bare token is safe to ban. |
| `ProviderContainer.test` | lib, test | Use `ProviderContainer(...)` + `addTearDown(container.dispose)`. |
| `tester.container` | test | Use `UncontrolledProviderScope` with your own container. |
| `isAutoDispose` | lib, test | Use the `.autoDispose` builder. |
| `Mutation` / `ref.mutate(` | lib, test | Use `WriteController.guard()`. |
| `valueOrNull` / `.requireValue` / `.hasValue` / `.asData` | lib, test | Switch on the `AsyncValue` instead. |
| `ref.mounted` / `\bRef\b` as a written type name | lib, test | 2.6.1 has no `Ref.mounted`; `Ref<State>`'s type parameter is deprecated. Use a `_disposed` field and let the create-callback parameter type infer. |
| `ProviderObserverContext` / `didUnmountProvider` / `didCreateProviderContainer` | lib, test | The 3.x `ProviderObserver` signature. Use 2.6.1's four-argument form. |
| `StateProvider` / `StateNotifier` / `ChangeNotifierProvider` | lib, test | Legacy. Use `NotifierProvider`. |
| `@riverpod` / `riverpod_annotation` / `riverpod_generator` / `riverpod_lint` | lib, test, pubspec | Unresolvable on this stack. |
| `hooks_riverpod` / `flutter_hooks` / `useProvider` | lib, test, pubspec | Not in this project. |
| `package:riverpod/` | lib, test | Import `package:flutter_riverpod/flutter_riverpod.dart`. |
| `overrideWith` / `overrideWithValue` | **lib only** | Production has zero overrides (§5.2). Overrides are a test-only mechanism. |
| `go_router` / `GoRoute` / `context.go(` / `context.push(` | lib, test, pubspec | Navigator 1.0 (§8). |
| `RestorationMixin` / `restorationScopeId` / `Restorable` / `restorablePush` | lib, test | No state restoration (§9). |
| `WillPopScope` | lib | Removed from the framework. Use `PopScope`. |
| `pushNamed(` / `onGenerateRoute` | lib | Routes are typed helpers, not strings (§8.1). |
| `.select(` on the same line as `.where(` / `.map(` / `.toList()` | lib | Heuristic for the fresh-collection `.select` bug (§4.4). Line-scoped, low false-positive rate; if it fires wrongly, restructure rather than allowlist. |

**What CI cannot catch, and therefore belongs in `CODE-REVIEW-CHECKLIST.md`:**

1. `ref.watch` inside a callback.
2. `ref.read` inside `build()`.
3. A derived collection exposed as a getter rather than a stored field.
4. **`AsyncValue.value`.** The other four accessors are distinctive enough to grep; bare `.value` is not — it collides with `MapEntry.value`, `ValueNotifier.value`, `DropdownMenuItem.value` and every drift companion field. §2.2 bans it and the Definition of Done asserts it, but **only a reviewer can see it**. If you want a mechanical proof, the exhaustive-`switch` rule gives you one for free: a `switch` over `AsyncValue` with no `default` fails to compile the day a new case appears, and there is no `.value` in the codebase to begin with.

All four are reviewer-only. None of them is a soft preference.

---

## 3. The 2.6.1 spelling reference card

Keep this open. It is the whole API surface this app uses.

| Job | 2.6.1 declaration | Notifier base class |
|---|---|---|
| Injected value, no state | `Provider<T>((ref) => …)` | — |
| One-shot async value | `FutureProvider<T>((ref) async => …)` | — |
| Live query from drift | `StreamProvider<T>((ref) => repo.watchX())` | — |
| Screen state, kept alive | `NotifierProvider<C, S>(C.new)` | `Notifier<S>` |
| Screen state, disposed on pop | `NotifierProvider.autoDispose<C, S>(C.new)` | `AutoDisposeNotifier<S>` |
| Per-animal live query | `StreamProvider.autoDispose.family<T, EweId>((ref, id) => …)` | — |
| Per-animal screen state | `NotifierProvider.autoDispose.family<C, S, EweId>(C.new)` | `AutoDisposeFamilyNotifier<S, EweId>` with `S build(EweId arg)` |
| Per-animal async + commands | `AsyncNotifierProvider.autoDispose.family<C, S, EweId>(C.new)` | `AutoDisposeFamilyAsyncNotifier<S, EweId>` with `Future<S> build(EweId arg)` |

In every family case the create argument is a **zero-argument** tear-off (`C.new`), and the family argument arrives as the `build` parameter and as the inherited `arg` getter. Constructor delivery is Riverpod 3.

```dart
// The corrected 2.6.1 family shape. This is the snippet the research notes got
// wrong; do not reintroduce the version they printed.
final class EweCardController
    extends AutoDisposeFamilyAsyncNotifier<EweCardData, EweId> {
  @override
  Future<EweCardData> build(EweId arg) async {
    final repo = await ref.watch(flockRepositoryProvider.future);
    return repo.eweCard(arg);            // `this.arg` is also available
  }
}

final eweCardControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EweCardController, EweCardData, EweId>(EweCardController.new);

// Usage: ref.watch(eweCardControllerProvider(eweId))
```

**Notifier lifecycle, precisely.** When a dependency watched inside `build()` changes, `build()` re-runs but the **notifier instance is preserved**. This is true in both 2.6.1 and 3.x (3.0.0-dev.12 changed it; 3.0.0-dev.16 reverted). Two consequences you must design around:

- Do not put one-time setup in the constructor expecting it to re-run.
- Anything the user typed must live in a **private field on the notifier**, not only in `state` — otherwise `build()` re-running (because the flock changed) silently wipes it. See §10.2; this is a real 3am bug, not a theoretical one.

---

## 4. Provider shapes and the rules for using them

### 4.1 Which shape for which job

| Need | Shape | Example |
|---|---|---|
| Live data from SQLite | `StreamProvider` over one drift `watch()` (decision #12) | `penBoardProvider`, `quickEntryDeckProvider` (in `lib/data/providers.dart` from N18-T02 — **R83**), `tagIndexProvider` |
| Screen-local state (query, filter, expanded section) | `Notifier` over an `@immutable` state class | `quickEntryControllerProvider` |
| Per-animal anything | the same, `.autoDispose.family` | `eweCardControllerProvider` |
| Any mutation | `WriteController` (§7) | `lambingWriteControllerProvider` |
| An injected collaborator | `Provider` (sync) or `FutureProvider` (async construction) | `shareServiceProvider`, `databaseProvider` |

**Never** combine two drift streams in Dart. drift#3338 is open and its maintainer calls the torn-emission behaviour working as intended: two streams updated in one transaction can emit at different times, so a `combineLatest` of them shows a state that never existed in the database. One screen, one SQL statement. If two things must be shown together, they are one query or one view.

**Never** `ref.invalidate` a **drift-backed** read provider — after a write or at any other time. drift's `watch()` already re-emits. A manual invalidate means either the write did not go through drift or the query is missing a table in `readsFrom:`. The rule is scoped to drift-backed providers because there are exactly **two** legitimate invalidates in the app and neither is one: `ref.invalidate(minuteTickProvider)` on resume (§9.1), which restarts a wall-clock ticker that has no database behind it, and `ref.invalidate(databaseProvider)` at restore step 14 ([`04-data-and-migrations.md`](04-data-and-migrations.md) §7), where the live database file has been *replaced* and re-opening it is the point. Those two call sites are the whole allowance; a third is a defect.

> **Amended 2026-08-02 (N12).** This paragraph said *"exactly one"* and named only the ticker, while `04 §7` step 14 had been printing the second call site all along. The gate row `stream.invalidate` now carries a negative lookahead for both arguments and fires on every other one, which closes `CODE-REVIEW-CHECKLIST §1.5`. The `[exempt]` allowlist is untouched and still has four lines (R56).

### 4.2 Auto-dispose policy

| Provider class | Policy | Why |
|---|---|---|
| `databaseProvider`, repositories, gateways, settings | **keepAlive** (never `.autoDispose`) | Reopening SQLite at 03:41 because the last screen popped is absurd. |
| Hub reads: `tagIndexProvider`, `quickEntryDeckProvider`, `penBoardProvider`, `flockListProvider` | **keepAlive** | Re-entered constantly through a night. Disposing and re-querying on every pop is exactly the wrong trade at 3am. Quick Entry's two strips are **one** provider, not two (R28): `quickEntryDeckProvider` is a single `StreamProvider<QuickEntryDeck>` — `({List<DeckEntry> penned, List<DeckEntry> recents})` — whose `penned` half is a `select` over the **same** `PenOccupancies WHERE exited_at IS NULL` projection the pen board watches, ordered by `entered_at` ascending, ewes only (decision #67). Not a second table, and not a second stream to combine. `recentEwesProvider` and `inPensProvider` are banned spellings. |
| Per-animal reads and per-animal controllers | **`.autoDispose.family`** | A season of browsing must not accumulate 400 live controllers and 400 live drift subscriptions. |
| Write controllers | **`.autoDispose`** | One per screen; it holds only in-flight state. |
| `minuteTickProvider` | **`.autoDispose`** | Only the pen board, the withdrawal countdown and the Reminders day boundaries watch it; nothing should tick when nothing displays elapsed time. It yields `Instant`, never a raw `DateTime` (R25). |

`ref.keepAlive()` is used nowhere. If you reach for it, you have put `.autoDispose` on a hub provider — remove the `.autoDispose` instead.

**Family argument rule.** The argument is the cache key and is compared with `==`. Use the `int`-backed extension-type ids from `lib/domain/ids.dart` (`EweId`, `LambId`, `LambingId`) — an extension type erases to its representation, so `==` and `hashCode` are the underlying `int`'s and are correct. Dart records also have structural equality and would work, but there is no reason to use one. **Never** a `List`, and never a hand-written class without verified `==`/`hashCode`: you would create a new provider instance on every rebuild and leak every one of them.

### 4.3 `watch` / `read` / `listen`

| Method | Where it is legal | Purpose |
|---|---|---|
| `ref.watch` | **only** in `Widget.build()` and `Notifier.build()` | Declare a dependency; rebuild on change. |
| `ref.read` | **only** inside callbacks, event handlers and controller methods | One-shot access; creates no subscription. |
| `ref.listen` | **only** in `build()`, called unconditionally | Side effects: haptics, SnackBar, navigation, announcements. |

`ref.watch` in a callback creates a subscription per tap and never releases it — the app gets slower the longer the night goes on, which is the worst possible failure mode here. `ref.read` in `build()` means the widget does not update, which at 3am shows a stale ewe. Both are reviewer-caught, not CI-caught.

`ref.listen` never appears inside an `if`. It is registered once per build, at the top of `build()`, before the returned tree.

### 4.4 `.select` to narrow rebuilds

```dart
final query = ref.watch(quickEntryControllerProvider.select((s) => s.query));
```

`.select` compares the selected value with `==`. That makes it a trap for collections:

```dart
// BANNED. `matches` is a getter that allocates a new List every call, and List's
// `==` is identity. This rebuilds on EVERY notifier change and runs the filter
// once per comparison as well as once per build — strictly worse than no .select.
List<TagIndexEntry> get matches =>
    index.where((e) => e.tag.contains(query)).toList();
```

**Rule: anything reachable through `.select` is a stored field, computed once in the state class's factory.** Never a getter that builds a collection. The CI heuristic in §2.4 catches the common spelling; the general case is a review item.

**And be honest about what that buys.** A stored `List` field still has identity `==`, so `.select((s) => s.matches)` deduplicates **nothing** — every new state instance carries a new list. What the stored field removes is the recomputation: the filter runs once per state transition instead of once per equality check *and* once per build. That is the expensive half, and it is the half that runs during the frame.

So there are two selector shapes and they do different jobs:

| You want | Select | Effect |
|---|---|---|
| To not rebuild unless a value changed | a scalar: `s.query`, `s.selected`, `s.matches.length` | true deduplication — `==` is meaningful |
| To not recompute a collection | a stored collection field | no deduplication; the widget rebuilds whenever the notifier emits, which for `_MatchList` is once per keystroke and is exactly right |

Never reach for a deep-equality helper to close the gap. `listEquals` over 400 rows on every notifier emission costs more than the rebuild it prevents.

### 4.5 Reading an `AsyncValue`

The only permitted form is an exhaustive switch. No accessors (§2.2).

```dart
final deck = ref.watch(quickEntryDeckProvider);
return SizedBox(
  height: 96,                              // reserved whether or not data arrived
  child: switch (deck) {
    AsyncData(:final value) => RecentsStrip(ewes: value.recents),
    AsyncError(:final error) => RecordsUnavailableRow(error: error),
    AsyncLoading() => const SizedBox.shrink(),   // NOT a spinner
  },
);
```

Three rules that follow from the 3am test and are not negotiable:

1. **Loading is never a spinner.** It is a fixed-height placeholder in the same dark colour, so nothing shifts when data lands. A spinning white ring under a head torch is a flashbang; see `06-design-system.md`.
2. **Error is never silent.** If `databaseProvider` fails to open, every downstream provider is `AsyncError`. The keypad stays interactive, but the event buttons are replaced by an honest failure row — a tap must never look like it recorded something when it did not. `07-screens.md` owns the copy.
3. **Never `?? 0`** on a nullable aggregate. Decision #58: an unknown statistic is `notComputableReason`, not zero.

### 4.6 Where providers are declared

| Kind | File |
|---|---|
| Database, repositories, gateways, settings | `lib/data/providers.dart` |
| The 60 s ticker | `lib/core/time/ticker.dart` |
| The `WriteController` base class | `lib/core/write_action.dart` |
| A screen's controller and its provider | `lib/features/<feature>/<feature>_controller.dart` |

`lib/core/write_action.dart` is the **one file this document adds** to the `lib/core/` tree printed in `01-architecture.md` §2.2; R72 puts it in the canonical tree (`CONVENTIONS.md` §1), so there is no longer a difference to diff. The file name stays `write_action.dart` even though the class is `WriteController`.

Providers are top-level `final` globals. That is not a contradiction of "no global singletons": the *declaration* is global, the *state* lives in the `ProviderContainer` and is replaced wholesale by a test's overrides. No repository, database, gateway or controller is reachable through a static field — there is no `AppDatabase.instance` and no service locator.

**The one deliberate static, named so nobody "fixes" it:** `LocalLog.instance` (`01-architecture.md` §5.5). The three error handlers are installed synchronously in `main()`, **before** `runApp` and therefore before any `ProviderScope` exists, and they must still work when the container has been torn down by the very failure being logged. A provider cannot satisfy that. It is a singleton because the alternative is a log that goes silent exactly when it matters. Nothing else in the app gets that argument.

---

## 5. The DI graph

### 5.1 The graph

```
main()  — awaits nothing (decision #21, see 01-architecture.md §6.1)
  └── runApp(const ProviderScope(child: ShedBookApp()))      NO overrides in production
        │
        ├── lib/data/providers.dart ───────────────────────────────────────────────┐
        │                                                                          │
        │   databaseProvider : FutureProvider<AppDatabase>                          │
        │     • opened from the first post-frame callback, application support dir  │
        │     • keepAlive; never overridden with a value                            │
        │        │                                                                 │
        │        ├── flockRepositoryProvider      : FutureProvider<FlockRepository> │
        │        ├── lambingRepositoryProvider    : FutureProvider<…>               │
        │        ├── fosterRepositoryProvider     : FutureProvider<…>               │
        │        ├── penRepositoryProvider        : FutureProvider<…>               │
        │        ├── treatmentRepositoryProvider  : FutureProvider<…>               │
        │        ├── reminderRepositoryProvider   : FutureProvider<…>               │
        │        ├── noteRepositoryProvider       : FutureProvider<…>               │
        │        ├── seasonRepositoryProvider     : FutureProvider<…>               │
        │        ├── settingsRepositoryProvider   : FutureProvider<SettingsRepo…>   │
        │        │     └── settingsProvider       : StreamProvider<AppSetting>      │
        │        │           ├── themeProvider       : Provider<ShedThemeSet>       │
        │        │           ├── unitsProvider       : Provider<WeightUnit>         │
        │        │           └── terminologyProvider : Provider<Terminology>        │
        │        ├── entitlementRepositoryProvider: FutureProvider<…>               │
        │        ├── entitlementProvider          : StreamProvider<Entitlement>     │
        │        │     ▲ NOTHING on the 3am path may watch this (decision #90)      │
        │        ├── exportRepositoryProvider     : FutureProvider<…>               │
        │        ├── restoreServiceProvider       : FutureProvider<RestoreService>  │
        │        ├── mediaSweeperProvider         : FutureProvider<MediaSweeper>    │
        │        └── reminderReconcilerProvider   : FutureProvider<ReminderRecon…>  │
        │              ▲ needs the DB *and* the notification seam (decision #63)    │
        │                                                                          │
        │   freeTierPolicyProvider : Provider<FreeTierPolicy>                       │
        │                                                                          │
        │   Gateways — the only code that touches a plugin. Collective noun from    │
        │   decision #112; the class names and files are CONVENTIONS.md §2.12's:    │
        │     notificationSchedulerProvider : FutureProvider<NotificationScheduler> │
        │     shareServiceProvider          : Provider<ShareService>                │
        │     mediaStoreProvider            : Provider<MediaStore>                  │
        │     cameraServiceProvider         : Provider<CameraService>               │
        │     voiceRecorderProvider         : Provider<VoiceRecorder>               │
        │     wakelockProvider              : Provider<WakelockController>          │
        │     purchaseServiceProvider       : Provider<PurchaseService>             │
        │       ^ the store seam, not a platform one — CONVENTIONS.md R74, owned by │
        │         11-monetization-and-store.md §5. Nothing on a shed screen reads it│
        └──────────────────────────────────────────────────────────────────────────┘
        │
        ├── lib/core/time/ticker.dart
        │     minuteTickProvider : StreamProvider.autoDispose<Instant>
        │
        └── lib/features/<f>/<f>_controller.dart
              read providers   : StreamProvider  (one drift statement each)
              screen state     : Notifier / AutoDisposeFamilyNotifier
              write controllers: NotifierProvider.autoDispose<…, WriteState>

NOT in the graph:
  • the clock — it is ambient (`package:clock`), not a provider. See §5.3.
  • LocalLog — a deliberate singleton, installed before any container. See §4.6.
  • AppDatabase as a value — decision #20 forbids `Provider<AppDatabase>.overrideWithValue`.
```

Each gateway wraps exactly one plugin and nothing else wraps it: `NotificationScheduler` → `flutter_local_notifications` **and `package:timezone`** (R48 — the only tz call site in the app), `ShareService` → `share_plus`, `MediaStore` → `path_provider` + `flutter_image_compress`, `CameraService` → `image_picker`, `VoiceRecorder` → `record`, `WakelockController` → `wakelock_plus`. If a plugin import appears outside its gateway, the fake in `test/` is no longer testing the real path.

**Names.** All six class names and file names are `CONVENTIONS.md` §2.12's, and they are settled: `NotificationScheduler` (`lib/data/notification_scheduler.dart`), `ShareService` (`share_service.dart`), `MediaStore` (`media_store.dart`), `CameraService` (`camera_service.dart`), `VoiceRecorder` (`voice_recorder.dart`), `WakelockController` (`wakelock_controller.dart`). Use those spellings and no others. `08-platform-integration.md` owns the implementations of the last three and **adopts these exact names** (R9) — it does not get to rename them. What this document fixes is the *shape*: each is a hand-written class behind a plain `Provider`, injected nowhere except through the container, and replaced by a hand-written fake in tests (decision #112). Capture is split by R47: `CameraService` owns `image_picker` (`pickImage`, `retrieveLostData`), `VoiceRecorder` owns `record`, and `MediaStore` owns the media root, `newRelativePath`, `resolve`, `writeAtomically` and the `flutter_image_compress` downscale.

Asynchrony is contagious upwards. Decision #20 makes `databaseProvider` a `FutureProvider`; its "repositories are `Provider`s" clause does not survive that, because a `Provider<FlockRepository>` could only reach the database through an `AsyncValue` accessor, and §2.2 bans every one of them. `01-architecture.md` §4.1 already resolves this the same way: repository providers are `FutureProvider`s that `await ref.watch(databaseProvider.future)`. Every read provider then folds the await in:

```dart
// lib/data/providers.dart
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();      // lib/core/db/connection.dart (R2, R12)
  ref.onDispose(db.close);
  return db;
});

final penRepositoryProvider = FutureProvider<PenRepository>((ref) async {
  return PenRepository(await ref.watch(databaseProvider.future));
});

// One SQL statement, one screen. `async*` + `yield*` folds the open away.
final penBoardProvider = StreamProvider<List<PenTile>>((ref) async* {
  final repo = await ref.watch(penRepositoryProvider.future);
  yield* repo.watchBoard();
});
```

During boot every one of these is `AsyncLoading`, which is exactly what the first-frame design wants: a dark shell with a fully interactive keypad and fixed-height placeholders where data will land.

### 5.2 Production has no overrides

`main()` runs `runApp(const ProviderScope(child: ShedBookApp()))`. There is nothing to override, because nothing is constructed before `runApp`. `overrideWith` and `overrideWithValue` are **banned in `lib/`** by CI (§2.4); they appear only in `test/` and in `tool/seed.dart`.

### 5.3 The clock is not a provider

Decision #46: there is **one** clock, `package:clock`'s ambient `clock`, and it is read through exactly one function — `Instant appNow()` in `lib/core/time/app_clock.dart` (R23). Every repository, controller, seed and sweep calls `appNow()`; `clock.now()` at any other call site is a defect. Do not write a `Clock` interface, a `SystemClock` class or a `clockProvider` — the research note that proposed them was overruled, because two clock seams are worse than none: a test that fakes one does not fake the other.

- `DateTime.now(` and `clock.now()` appear in exactly one allowlisted file, `lib/core/time/app_clock.dart`, which is where `appNow()` wraps them (`app_clock.dart :: time.dart_clock` is one of the four `[exempt]` lines). Everywhere else either is a CI failure. `*.g.dart` is skipped.
- Tests fake time with `withClock(...)`, not with an override.
- In **widget** tests you fake nothing. `AutomatedTestWidgetsFlutterBinding` already installs an *advancing* fake clock, so `tester.pump(const Duration(hours: 25))` really does move `appNow()`. `Clock.fixed` **freezes** `now()` and is only for single-instant assertions — wrap a pen-board test in it and every "hours since penned" readout silently measures 0 h (decision #113). For an elapsed-time widget test, offset the seed data; never pin `now`. See `12-testing.md`.

### 5.4 Overriding in tests

**Rule: override leaves, never controllers.** Override `databaseProvider` and the seven gateways — the six platform seams and `purchaseServiceProvider` (R74). Never override a repository provider or a screen controller — a fake controller tests the fake. A real in-memory SQLite database is a better fake than anything you could hand-write and cannot diverge from production (decision #15).

```dart
// test/support/harness.dart
ProviderContainer shedContainer(AppDatabase db, {FakeShareService? share}) {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWith((ref) async => db),
      shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
      notificationSchedulerProvider
          .overrideWith((ref) async => FakeNotificationScheduler()),
    ],
  );
  addTearDown(container.dispose);   // 2.6.1: you register this yourself
  return container;
}
```

Widget tests hand the same container to the tree. `closeStreamsSynchronously: true` on the connection is mandatory or every stream-touching widget test fails with a pending-timer error (decision #111):

```dart
final db = AppDatabase(DatabaseConnection(
  NativeDatabase.memory(),
  closeStreamsSynchronously: true,
));
addTearDown(db.close);

final container = shedContainer(db);
await tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: QuickEntryScreen()),
  ),
);
```

Hand-written fakes for all seven gateways — the six platform seams `NotificationScheduler`, `ShareService`, `MediaStore`, `CameraService`, `VoiceRecorder`, `WakelockController`, plus the store seam `PurchaseService` (`CONVENTIONS.md` §2.12, R74; the fakes are `12-testing.md` §4.2's). All seven are providers and are overridden as above. Decision #112's own list of six counts the *clock* and omits the wakelock; that wording is superseded, because the clock is **not** a gateway and **not** a provider — tests install theirs with `withClock(...)` (§5.3), never with an override. `mocktail` is kept only for interaction-ordering and non-invocation assertions.

**Anti-pattern:** a `ProviderScope` with no override for `databaseProvider` in a test that touches data. It will open a real database on the test machine. `openAppDatabase()` asserts it is not running under `flutter_test` and throws with the name of the override to add.

---

## 6. Controller conventions

1. **One controller per screen**, named `<Screen>Controller`, in `lib/features/<feature>/<feature>_controller.dart`, with its provider named `<screen>ControllerProvider` in the same file.
2. **A controller holds screen state, never data.** The keypad query, the selected filter, the expanded season, the in-flight write. Data comes from `StreamProvider`s over drift. Do not mirror rows into controller state — you will get two sources of truth and the wrong one will win at 3am.
3. **State classes are hand-written and `@immutable`** (from `package:flutter/foundation.dart`; there is no `freezed` — it is unresolvable on this stack). Derived collections are stored fields computed in a factory, never getters (§4.4).
4. **Controllers never import drift** and never see an `AppDatabase`. Layer rule 5 (`lib/features/**` may not import `core/db/` or `package:drift/`) is enforced by `tool/check_policy.dart`.
5. **Controllers have no `BuildContext`.** They never show a SnackBar, never navigate, never call `HapticFeedback`. The screen does that from `ref.listen`.
6. **Controllers hold no draft.** There is no `save()`, no `isDirty`, no `commit()`. The row is created on screen entry and every field is its own committed write (decision #11). If you find yourself accumulating fields to write later, you have reintroduced the thing spec §5 forbids.
7. **Mutations go through a `WriteController`**, always (§7). A controller that both holds screen state and writes is two objects.
8. **Anything the user typed lives in a private field on the notifier, not only in `state`.** `build()` re-runs whenever a watched dependency changes and the notifier instance survives it (§3), so state-only input is wiped by an unrelated flock change. Seed `state` from the private field at the end of `build()`. This is rule 8 because it is the rule that produces a silent 3am data loss rather than a crash — see §10.2 for the worked example.
9. **A controller never formats for display.** No `DateFormat`, no unit conversion, no terminology lookup. Canonical values in, canonical values out; the presentation edge converts (decisions #56, #61). A controller that knows `en_GB` is a controller that cannot be unit-tested without a locale.

---

## 7. The double-tap-safe write controller

A cold, gloved thumb on capacitive glass through a freezer bag double-fires. Without a gate, the second fire is a second lambing record — a data-integrity bug produced by hardware. This is a UX safety feature disguised as architecture.

```dart
// lib/core/write_action.dart — CONVENTIONS.md §1, §2.4 (R72). See §4.6.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'failure.dart';         // sealed ShedFailure    — 01-architecture.md §5.3
import 'write_outcome.dart';   // sealed WriteOutcome   — 01-architecture.md §5.2

sealed class WriteState {
  const WriteState();
}

final class WriteIdle extends WriteState {
  const WriteIdle();
}

final class WriteRunning extends WriteState {
  const WriteRunning();
}

/// Deliberately has NO `==`. Two identical outcomes in a row must still fire
/// `ref.listen`, because each completed write owes the user its own haptic,
/// its own SnackBar and its own uniquely-labelled live region (decision #103).
final class WriteDone extends WriteState {
  const WriteDone(this.outcome);
  final WriteOutcome outcome;
}

/// `base` because Dart requires every subtype of a `base` class to be
/// `base`, `final` or `sealed` — subclasses below are `final class`.
abstract base class WriteController extends AutoDisposeNotifier<WriteState> {
  bool _disposed = false;

  /// Must not `ref.watch` anything. A write controller has no data
  /// dependencies, so `build()` runs exactly once per mount.
  @override
  WriteState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const WriteIdle();
  }

  @protected
  Future<void> guard(Future<WriteOutcome> Function() action) async {
    // The double-tap gate. This assignment MUST happen synchronously, before
    // the first await, or the second tap of a double-fire slips through.
    if (state is WriteRunning) return;
    state = const WriteRunning();

    WriteOutcome outcome;
    try {
      outcome = await action();
    } on Object catch (e, s) {
      // Repositories map their own expected failures and return WriteFailed
      // (01-architecture.md §5.4), so anything that reaches here is a bug —
      // a bad cast, a null id, a closure that throws before the transaction.
      // It must still surface as a failure. It must never surface as silence.
      outcome = WriteFailed(UnexpectedFailure(e, s));
    }

    // The screen may have been popped while the transaction ran. The write
    // itself completed — drift does not care that the provider is gone — but
    // assigning `state` after disposal throws. 2.6.1 has no `ref.mounted`
    // (§2.1), which is why `_disposed` exists at all.
    if (_disposed) return;
    state = WriteDone(outcome);
  }
}
```

`UnexpectedFailure` is `lib/core/failure.dart`'s bug variant, and `01-architecture.md` §5.4 already names it as where a programmer error lands in release. Its constructor is settled: **`UnexpectedFailure(Object error, StackTrace stack)`** (R8), and it is constructed at exactly two sites — inside `shedFailureFrom` and inside this catch-all.

`guard()` must **not** import `lib/data/failure_mapping.dart`. Translating a `SqliteException` into a `ShedFailure` is the repository's job, through the top-level **`ShedFailure shedFailureFrom(Object error)`** in `lib/data/failure_mapping.dart` (`01-architecture.md` §5.3, R4). There is **no** `ShedFailure.from(e, s)` and no other constructor that touches SQLite: putting the mapping on `ShedFailure` would drag `package:sqlite3` into `lib/core/`, which layer rule 8 forbids. `lib/core/` does not reach into `lib/data/`, and a second mapping site is a second set of user-facing strings to keep honest at 3am.

Per screen:

```dart
// lib/features/pens/pen_board_controller.dart
final class PenWriteController extends WriteController {
  // `turnOut` is the UI verb and lives HERE; the repository verb is `exitPen`,
  // because the occupancy row — not the pen — is what closes (R63).
  Future<void> turnOut(PenOccupancyId occupancy) => guard(() async {
        final repo = await ref.read(penRepositoryProvider.future);
        return repo.exitPen(occupancy, reason: PenExitReason.turnedOut);
      });
}

final penWriteControllerProvider =
    NotifierProvider.autoDispose<PenWriteController, WriteState>(
  PenWriteController.new,
);
```

And on the screen — the only place feedback happens:

```dart
ref.listen(penWriteControllerProvider, (previous, next) {
  if (next case WriteDone(:final outcome)) {
    // WriteOutcome is sealed and has THREE variants (01-architecture.md §5.2).
    // No `default:` — the day a fourth appears, every switch must fail to
    // compile rather than silently swallow it.
    switch (outcome) {
      case WriteCommitted(:final warnings):
        // `receipt` is the SaveReceipt this screen built for the verb it just
        // ran — 06-design-system.md owns the type and the three functions.
        confirmSaved(context, receipt, warnings);  // haptic + SnackBar + live region
      case WriteFailed(:final failure):
        showFailure(context, failure);         // failure.userMessage, never a code
      case WriteRefused(:final reason):
        showCapRow(context, reason);           // calm, static, never a modal
    }
  }
});
```

Three things about that switch are load-bearing:

- **`warnings`, not `flags`.** `WriteCommitted.warnings` is `List<Warning>` from `lib/domain/validation/warning.dart` (decision #54; R17 — `lib/domain/consistency.dart` does not exist and is a banned import path). The write *succeeded* **and** something looks contradictory — three lambs on a lambing declared twin. **The controller populates that list, never a repository** (R53): `lib/data/**` may not import `lib/domain/validation/**`, so a repository is structurally incapable of producing a `Warning`. Repositories return `WriteCommitted(insertedId: …)` with the default empty `warnings`; this controller runs the domain validators against the freshly-watched row and the two travel together through `WriteDone` to `ref.listen`. `confirmSaved` shows the saved confirmation **and** a non-blocking badge. It never corrects the record, never offers to, and never blocks the save: spec §12.4 is "flag it; do not fix it", and the type enforces that by holding no writer. `06-design-system.md` owns the badge and `07-screens.md` owns the copy.
- **`WriteRefused` is not a failure.** It is the free-tier policy declining a calm-UI action (decision #91), reachable from exactly the two callers that decision names — adding ewe #16 from the Flock screen, and starting a second season — and **structurally unreachable from `EntryContext.liveEntry`**. `enum EntryContext { liveEntry, calm }` and `enum RefusalReason { secondSeason, eweCap }` live in `lib/domain/free_tier.dart`; `11-monetization-and-store.md` adopts those names (R69). Rendering it through `showFailure` would tell a shepherd their record did not save when nothing was ever attempted, and would poison the Diagnostics log with a non-error. It renders as the same static upgrade row that is always on the Flock screen (decision #92): no modal, ever, and nothing between 22:00 and 06:00.
- **`confirmSaved` / `showFailure` / `showCapRow` are `06-design-system.md`'s.** They are named here to show *where* feedback happens — in `ref.listen`, on the screen, holding a `BuildContext`. The names and signatures are settled (R10, R30) and 06 adopts them verbatim in `lib/core/ui/feedback.dart`: `void confirmSaved(BuildContext, SaveReceipt, List<Warning>)`, `void showFailure(BuildContext, ShedFailure)`, `void showCapRow(BuildContext, RefusalReason)`. `confirmSaved` takes **no** `WidgetRef` — a feedback function holds a `BuildContext` and nothing else. `showShedReceipt` and `showShedFailure` are banned spellings.

### 7.1 The four rules

1. **`guard()` prevents concurrency, not repetition.** Once the first write returns, a second tap is a second write — and for "add lamb" that is correct. Where an action must not repeat *after* completion, the repository makes it idempotent: `exitPen` is a no-op when the occupancy row already has `exited_at`, enforced by the partial unique index (decision #34). A UI cooldown is **not** the mechanism; it would drop a legitimate second lamb.
2. **No optimistic UI.** The UI must not show success before the transaction returns (decision #103). `WriteRunning` disables nothing visually beyond what the gate already guarantees — a greyed-out button at 3am reads as a broken app.
3. **Taps are never debounced.** The debounce ceiling in this codebase is **400 ms and it applies only to free-text fields** — notes and tag entry, which cannot round-trip to SQLite per keystroke without churning every watching stream. Those fields additionally commit on focus loss, on route pop (`PopScope`), and on `AppLifecycleState.inactive`. Worst-case loss is 400 ms of typing. That number is in `CODE-REVIEW-CHECKLIST.md` precisely so it cannot silently grow.
4. **Every destructive action gets a double-tap test.** No pump between the taps — `WidgetTester.tap` dispatches the pointer sequence without pumping a frame, so the second `onTap` runs while `state` is still `WriteRunning` and the first transaction is still in flight. **Do not add `await tester.pump()` between the two taps.** With a pump, the first write completes, `state` becomes `WriteDone`, and the second tap legitimately produces a second row — the test fails, and rule 1 says it is right to. A double-tap test with a pump in the middle is testing nothing and will be "fixed" by someone adding the cooldown rule 1 forbids.

```dart
testWidgets('two taps on Turn out produce one pen exit', (tester) async {
  // …seed one open occupancy in pen 3, pump the board…
  await tester.tap(find.byKey(const Key('pen_board.turn_out.3')));
  await tester.tap(find.byKey(const Key('pen_board.turn_out.3')));
  await tester.pumpAndSettle();

  final closed = await db.closedOccupanciesForPen(const PenId(3));
  expect(closed, hasLength(1));
});
```

**Anti-pattern:** `Future<void> onTap() async { if (_busy) return; _busy = true; … }` in a `State`. It dies with the widget, is untestable through the provider, and is re-implemented slightly differently on every screen. There is one gate and it is `WriteController.guard()`.

---

## 8. Navigation

`Navigator` 1.0 with a static typed route-helper file. `go_router` was rejected because its entire value proposition is URLs — there is no web target, no deep links and no URL bar — while it costs three breaking majors in ~24 months and carries open restoration bugs (flutter#117683, open since 2022-12-27; flutter#174935).

### 8.1 The route helper

This is the **one** file in the app that imports every feature. That is not a layer violation — `lib/routing/` is not a feature, so rule 6 (no sibling-feature imports) does not apply to it, and rule 5 explicitly allows `lib/features/` → `lib/routing/`. It is the trade the helper file buys: one file knows all twelve destinations so that no screen has to know a second one.

```dart
// lib/routing/routes.dart
import 'package:flutter/material.dart';

import '../domain/ids.dart';
import '../features/flock/ewe_card_screen.dart';
import '../features/lambing/lambing_entry_screen.dart';
import '../features/pens/pen_board_screen.dart';
// …one import per screen. This file is the only place that has them all.

/// Every route name that can appear in the diagnostics log. Route name is one of
/// the few fields decision #124 permits to be logged, so every route sets one.
abstract final class RouteNames {
  static const quickEntry = 'quick_entry';
  static const flock = 'flock';
  static const eweCard = 'ewe_card';
  static const lambingEntry = 'lambing_entry';
  static const lambCard = 'lamb_card';
  static const foster = 'foster';
  static const penBoard = 'pen_board';
  static const treatments = 'treatments';
  static const reminders = 'reminders';
  static const seasonSummary = 'season_summary';
  static const export = 'export';
  static const settings = 'settings';
  static const noteSearch = 'note_search';
}

abstract final class Routes {
  /// The one navigator, so notification taps and the resume policy can navigate
  /// without a BuildContext.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> eweCard(BuildContext context, EweId id) =>
      Navigator.of(context).push(_route(
        RouteNames.eweCard,
        (_) => EweCardScreen(eweId: id),
      ));

  static Future<void> lambingEntry(BuildContext context, LambingId id) =>
      Navigator.of(context).push(_route(
        RouteNames.lambingEntry,
        (_) => LambingEntryScreen(lambingId: id),
      ));

  static Future<void> penBoard(BuildContext context) =>
      Navigator.of(context)
          .push(_route(RouteNames.penBoard, (_) => const PenBoardScreen()));

  // …one method per PUSHED screen, 12 in total. See the count below.

  /// Back to the screen that started the flow.
  static void popTo(BuildContext context, String routeName) =>
      Navigator.of(context).popUntil(ModalRoute.withName(routeName));

  /// Back to Quick Entry — the "next ewe" action, and the resume policy.
  static void popToQuickEntry(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);

  static void popToQuickEntryGlobal() =>
      navigatorKey.currentState?.popUntil((r) => r.isFirst);

  static MaterialPageRoute<void> _route(
    String name,
    WidgetBuilder builder,
  ) =>
      MaterialPageRoute<void>(
        builder: builder,
        settings: RouteSettings(name: name),
      );
}
```

**The count, because it looks off by one and is not.** `RouteNames` has **thirteen** entries: spec §9's twelve screens plus `noteSearch`, which decision #35 puts on its own screen (full-text note search is a different problem from tag matching and does not belong on the keypad path). `Routes` has **twelve** push helpers, because Quick Entry is `MaterialApp.home` and is never pushed — it is route 0 and `isFirst` is how you get back to it. Thirteen names, twelve helpers, and the arithmetic is checkable: `RouteNames` constants minus one must equal `Routes` push methods.

Typed, greppable, testable, zero dependencies, no codegen, no string paths at the call site. `RouteSettings(name:)` exists for two reasons only — the diagnostics log and `ModalRoute.withName` — and **never** for `pushNamed`. There is no `routes:` table and no `onGenerateRoute`.

`MaterialApp` sets `home: const QuickEntryScreen()` and `navigatorKey: Routes.navigatorKey`. It sets **no** `restorationScopeId` (§9).

### 8.2 The stack

```
[ QuickEntry ]  ← home:, route 0, isFirst
      └─push→ [ PenBoard ]
                   └─push→ [ EweCard(412) ]
                                └─push→ [ LambingEntry(#1183) ]
```

Three pushes deep is the deepest stack in the app. Rules:

- **After a write, `pop()` back to where the flow started.** From lambing entry that is the ewe card; the shepherd is still holding that ewe. `Routes.popTo(context, RouteNames.penBoard)` is used only by the pen-board flow's explicit "back to the board" action.
- **`Routes.popToQuickEntry` is the "next ewe" action**, not the default. Do not silently dump the user at the root after a save — they lose the context they were about to use.
- The lambing-entry row exists from screen entry (decision #11), so backing out of any of these screens loses nothing and never asks a question.

### 8.3 Android back

Use `PopScope`; `WillPopScope` was removed from the framework. Per Flutter's predictive-back guidance `canPop` must be decided **ahead of time**, because the back animation starts before the gesture is committed. Add `android:enableOnBackInvokedCallback="true"` to `AndroidManifest.xml`.

Because every write commits immediately, there is **no "discard unsaved changes?" dialog anywhere in this app**. `canPop` is `true` on every screen. Back is always safe, always instant, and never asks a question — which is exactly right for cold hands.

`PopScope` still appears on the screens that own a free-text field, and this is where the two rules meet without contradicting each other. `canPop` stays `true` — the pop is never *blocked* — and the 400 ms debounce is flushed on the way out:

```dart
PopScope(
  canPop: true,                       // back is never blocked. Never.
  onPopInvokedWithResult: (didPop, _) {
    // The screen controller that owns the field — here the ewe card, which is
    // where a note is typed. CONVENTIONS.md §3.4 is the closed list of names.
    if (didPop) ref.read(eweCardControllerProvider(eweId).notifier).flushPending();
  },
  child: …,
)
```

Use `onPopInvokedWithResult`. `onPopInvoked` is deprecated and `flutter analyze --fatal-infos` fails on it. Flushing is idempotent: it also runs on focus loss and on `AppLifecycleState.inactive` (§7.1 rule 3), and running it three times writes the same text once.

The single exception to `canPop: true` is the season-deletion / delete-everything flow in Settings, which has no undo (decision #69). That is the only `PopScope` with `canPop: false` in the codebase, and CI counts it: more than one occurrence in `lib/` fails the policy check.

Flutter 3.38 made `PredictiveBackPageTransitionBuilder` the default Android page transition. Do not fight it; do honour reduce-motion through the single resolver in `10-accessibility-and-i18n.md`.

### 8.4 Anti-patterns

| Banned | Why |
|---|---|
| `go_router`, `GoRoute`, `context.go(...)` | Decision #23. CI greps `lib/`, `test/` and `pubspec.yaml`. |
| `Navigator.pushNamed` / `onGenerateRoute` / a `routes:` map | Stringly-typed arguments are the exact thing the helper file removes. |
| `Navigator.restorablePush` | Requires top-level `@pragma('vm:entry-point')` builders and `StandardMessageCodec`-serializable arguments — a real constraint on how you write screens, paid for a feature §9 deletes. |
| Navigating from a `Notifier` | Controllers have no `BuildContext`. Navigate from `ref.listen` in the screen, or through `Routes.navigatorKey` for the two context-free cases (notification tap, resume policy). |
| A bottom navigation bar | Not in spec §9, and in tension with the 60×60 pt rule. If v2 adds one with independent per-tab stacks, `go_router`'s `StatefulShellRoute` becomes worth re-evaluating — and only then. |

> **Still open, and it lands here.** The ziplock-bag capacitance test (`../research/00-tech-decisions.md` §7.1 item 2) is unresolved. If the target hardware does not register taps through a freezer bag, the interaction model moves to volume-button shortcuts, and every entry point in §8.1 gains a second, context-free caller through `Routes.navigatorKey`. Do not design for that now; do keep the route helper the only place a `MaterialPageRoute` is constructed, so the change is one file.

---

## 9. Why there is no state restoration

**Decision #24: none.** No `RestorationMixin`, no `restorationScopeId`, no `Restorable*` properties, no iOS `FlutterViewController` Restoration ID step in `Main.storyboard`. CI greps for all of them.

The reason is correctness, not effort. Restoring a stale selected ewe at 3am is a data-integrity bug: at 03:20 the shepherd selects 412 and is interrupted; at 03:41 they reopen the app, see "412" still selected, tap "Twin", and ewe 128's lambing is filed against 412. That is precisely the class of error the product exists to eliminate (spec §2), and spec §12.4's "never silently correct a user's entry" has a corollary — never silently attribute an entry to the wrong animal.

Restoration is also unnecessary, because **the database is the restored state**. Every write commits immediately (spec §5), so there is no draft to serialise. An app that keeps a half-filled lambing form in memory must serialise a complex draft through `RestorableProperty`, version the restoration payload, and get it right or lose data. This app has no draft to lose, so adopting restoration would mean *reintroducing* one.

### 9.1 The 3am reality, concretely

Opened at 03:20, used for 15 seconds, pocketed, reopened at 03:41.

**Case A — the process survived** (iOS suspended, Android cached). The Dart heap, the drift isolate, the open SQLite file descriptor and every provider are intact. Resume costs nothing. The lifecycle observer applies the resume policy:

```dart
// lib/app.dart — the same State that holds the post-frame boot kick
//                (01-architecture.md §6.3). There is no separate lifecycle file.

/// Pure, no Riverpod, no BuildContext — so it is a unit test, not a widget test.
/// The parameters are `Instant`, not `DateTime`, because the only wall-clock
/// reader in the app is `appNow()` and it returns an `Instant` (R23).
class ResumePolicy {
  /// Beyond this, the previously selected animal is untrustworthy.
  static const staleAfter = Duration(minutes: 2);

  static bool shouldClearSelection(Instant hiddenAt, Instant resumedAt) =>
      resumedAt.difference(hiddenAt) >= staleAfter;
}

class _ShedBookAppState extends ConsumerState<ShedBookApp>
    with WidgetsBindingObserver {
  Instant? _hiddenAt;

  @override
  void initState() {
    super.initState();
    // WITHOUT THIS LINE the whole block below is dead code and nothing warns
    // you. The mixin compiles, the overrides look right, and no lifecycle
    // callback ever fires. Widget-test it: drive `hidden` then `resumed` and
    // assert the selection cleared.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(databaseProvider.future).ignore();   // 01-architecture.md §6.3
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Decision #79: the wakelock is released on ANY non-resumed state, not just
    // `hidden`. A phone that goes `inactive` behind a banner and never reaches
    // `hidden` must not hold the screen on for the rest of the night.
    if (state != AppLifecycleState.resumed) {
      ref.read(wakelockProvider).release();
    }

    switch (state) {
      case AppLifecycleState.hidden:
        // `hidden` is the last state you are guaranteed to observe on both
        // platforms — it is synthesised, so it is the only safe place to
        // record "we paused cleanly".
        _hiddenAt = appNow();                 // lib/core/time/app_clock.dart (R23)
        LocalLog.instance.markCleanPause();   // clears session.lock, decision #123

      case AppLifecycleState.resumed:
        final hiddenAt = _hiddenAt;
        if (hiddenAt != null &&
            ResumePolicy.shouldClearSelection(hiddenAt, appNow())) {
          ref.read(quickEntryControllerProvider.notifier).clearSelection();
          Routes.popToQuickEntryGlobal();
        }
        _hiddenAt = null;
        ref.invalidate(minuteTickProvider);   // elapsed times are 20 min stale
        unawaited(                             // dart:async — deliberate, not a slip
          ref.read(reminderReconcilerProvider.future).then((r) => r.reconcile()),
        );

      case _:
        break;
    }
  }
}
```

Five details in that block are not stylistic:

- **`addObserver(this)` in `initState`, `removeObserver(this)` in `dispose`.** `with WidgetsBindingObserver` alone does nothing: the mixin compiles, `didChangeAppLifecycleState` looks like a valid override, and it is never called. This is the failure mode where the resume policy, the wakelock release and the clean-pause marker all silently stop existing and no test, lint or analyzer notices.
- **`reconcile()`, not `schedule()`.** Decision #63 names exactly one idempotent method and exactly four call sites: app start after the DB opens, `AppLifecycleState.resumed`, after any write touching `Reminder`/`Lambing`/`Treatment`/interval settings, and after a notification tap. It is debounced to once per 500 ms and runs off the paint frame. Anything named `schedule` on the write path is the architecture decision #63 rejects. `08-platform-integration.md` owns the implementation.
- **`reminderReconcilerProvider` is a `FutureProvider`** — it needs the database — so the resume path reaches it through `.future`, not `ref.read(p)`. The `.then` is deliberately not awaited: `didChangeAppLifecycleState` is `void` and the reconcile must not sit on the frame.
- **`LocalLog.instance`, not a provider.** See §4.6. The log outlives the container by design.
- **`session.lock` and `LocalLog.markCleanPause()` are `13-build-ci-release.md`'s** (decision #123), under those exact names (R11). Named here only to fix *where* the clean-pause marker is written, which is this switch and nowhere else.

The policy itself:

- **Under 2 minutes:** stay where you are, keep the selection. You put the phone down to grab a towel.
- **2 minutes or more:** land on Quick Entry with nothing selected.

**Case B — the process was killed** (very plausible on a 3 GB phone after the camera, a torch app and a browser). Full cold start: `main()` awaits nothing, the dark Quick Entry shell paints with a fully interactive keypad, the database opens on the first post-frame callback, and the recents strip fills in. Nothing else is restored, and nothing else needs to be.

**Both cases land in the same place, which is the point.** There is one resume path to design, one to test and one to reason about at 3am.

### 9.2 What the app owes the user on resume

Not the previous screen. The previous **fact**, read from disk:

- The in-flight lambing row already exists, because it is created on screen entry (decision #11), carrying a `RecordedTime` whose `source` is `TimeSource.autoCaptured` and whose `provenanceLabel` is *"recorded automatically"* (decision #53, `05-domain-correctness.md`). Resume does not touch it and must never re-stamp it: the honest time is 03:20, not 03:41. Spec §12.5 is a property of the row, not of the session.
- It therefore appears as the first chip in the recents strip, labelled *"412 · lambing 03:20 — continue"*. Times in this app are 24-hour `en_GB` throughout (owner ruling, decision-record §7.0 #3); there is no 12-hour path to get wrong.
- Resuming is one tap, and the resumed state comes from durable storage rather than from volatile UI state.

Clearing the selection destroys nothing. That is only true because of the commit-on-first-tap rule, so the two decisions must be read together: if you ever weaken "every write commits immediately", the aggressive resume-clear becomes data loss.

### 9.3 What is genuinely lost, stated honestly

| Lost on process death | Consequence | Accepted because |
|---|---|---|
| Partially typed keypad digits ("41") | Retype two digits | Restoring them requires the whole restoration apparatus, and a shepherd retypes two digits without noticing. Worth a question in the shed observation (`../research/00-tech-decisions.md` §7.1 item 1). |
| Scroll offset in the flock list | The list starts at the top | The keypad is faster than scrolling anyway. |
| An undo window | Undo does not survive process death, and the UI must not imply it does | Decision #69: the window is until the SnackBar is dismissed or the route pops. |
| Every provider's state | Rebuilt from SQLite on the next frame | Providers are in-memory objects; no Riverpod feature changes this, and the 3.x experimental persistence feature is explicitly unstable and aimed at caching network responses. |

**Anti-pattern:** treating any provider state that would hurt to lose as a restoration problem. It is a bug in the write path. Fix the write, not the restore.

---

## 10. Keeping Quick Entry cheap

The screen: a giant numeric keypad filtering ~400 ewes, one digit at a time, on a cold mid-range phone. Frame budget is 16 ms at 60 Hz, 8 ms at 120 Hz. 400 rows is small, and a naive implementation would plausibly still hit 60 fps — **that is an estimate, not a measurement**, and decision #126 says the only numbers that count come from profile mode on two real devices with the 400-ewe fixture. The rules below are not performance tuning against a measured deficit; they are structural choices that cost nothing to make and are expensive to retrofit. The perceived latency budget for a keypad is far tighter than for a list anyway, because the user is watching a specific number appear.

### 10.1 What rebuilds when a digit is typed

| Widget | Rebuilds? | Watches |
|---|---|---|
| `_QueryDisplay` | **yes** | `.select((s) => s.query)` — a `String`, so `==` is meaningful and a no-op keystroke rebuilds nothing |
| `_MatchList` | **yes** | `.select((s) => s.matches)` — a stored field, so the filter is not re-run per comparison. It rebuilds on every controller emission (§4.4) and that is correct: every emission on this screen changes the list |
| `_Keypad` | **never** | nothing. `const`, no parameters, reaches the controller through `ref.read` in its own callbacks |
| `_RecentsStrip` | never | `quickEntryDeckProvider.select((d) => d.recents)` only |
| `_InPensStrip` | never | `quickEntryDeckProvider.select((d) => d.penned)` only |
| `_EventButtonRow` | never | nothing. `const` |
| `Scaffold` / theme | never | — |

The keypad is the most expensive part of the screen and it is completely static. If it rebuilds on every digit, you are rebuilding twelve large buttons for no reason.

```dart
// A StatelessWidget, NOT a ConsumerWidget. It watches nothing, so it cannot be
// rebuilt by anything — which is the strongest available proof that a digit
// cannot reach the keypad. The moment someone makes it a ConsumerWidget to
// "just watch one thing here", every child below loses its const-ness.
class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          _RecentsStrip(),
          _QueryDisplay(),
          Expanded(child: _MatchList()),
          _Keypad(),            // const — structurally incapable of rebuilding
          _EventButtonRow(),
        ],
      ),
    );
  }
}

class _MatchList extends ConsumerWidget {
  const _MatchList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches =
        ref.watch(quickEntryControllerProvider.select((s) => s.matches));
    return ListView.builder(
      itemCount: matches.length,
      itemExtent: 72,                       // fixed height: skips the intrinsic pass
      itemBuilder: (context, i) => _EweRow(
        key: ValueKey(matches[i].eweId),
        entry: matches[i],
      ),
    );
  }
}
```

### 10.2 The controller

Two things make this correct rather than merely fast: the filter runs **once per keystroke in the controller**, and the query lives in a **private field** so that a `build()` re-run cannot wipe it.

```dart
// lib/features/quick_entry/quick_entry_controller.dart
@immutable
final class QuickEntryState {
  const QuickEntryState._({
    required this.query,
    required this.index,
    required this.matches,
    required this.selected,
  });

  factory QuickEntryState({
    String query = '',
    List<TagIndexEntry> index = const [],
    EweId? selected,
  }) =>
      QuickEntryState._(
        query: query,
        index: index,
        selected: selected,
        // Stored, not a getter. Computed once per state transition.
        matches: rankTagMatches(index, query),   // pure, lib/domain/tag_match.dart
      );

  final String query;
  final List<TagIndexEntry> index;
  final List<TagIndexEntry> matches;
  final EweId? selected;
}

final class QuickEntryController extends Notifier<QuickEntryState> {
  // NOT in `state`. The notifier instance is preserved across `build()` re-runs;
  // `state` is not. Without this field, a flock change while the shepherd is
  // mid-tag wipes the digits they just typed.
  String _query = '';
  EweId? _selected;

  @override
  QuickEntryState build() {
    final index = switch (ref.watch(tagIndexProvider)) {
      AsyncData(:final value) => value,
      _ => const <TagIndexEntry>[],
    };
    return QuickEntryState(query: _query, index: index, selected: _selected);
  }

  void appendDigit(String digit) {
    _query += digit;
    state = QuickEntryState(
        query: _query, index: state.index, selected: _selected);
  }

  void backspace() {
    if (_query.isEmpty) return;
    _query = _query.substring(0, _query.length - 1);
    state = QuickEntryState(
        query: _query, index: state.index, selected: _selected);
  }

  void clearSelection() {
    _query = '';
    _selected = null;
    state = QuickEntryState(index: state.index);
  }
}

final quickEntryControllerProvider =
    NotifierProvider<QuickEntryController, QuickEntryState>(
  QuickEntryController.new,     // keepAlive: this is the hub screen
);
```

`rankTagMatches` is the pure in-memory ranked filter from decision #35 — exact, then prefix, then suffix, then infix, then most-recently-touched — living in `lib/domain/tag_match.dart`. It is not FTS5 and not a SQL query: FTS5's trigram tokenizer cannot match the spec's own two-character `12` example, `LIKE '%12%'` cannot use an index, and a round-trip through drift's background isolate lands one or two frames late. A substring scan over 400 short strings is **sub-millisecond** — that is the claim decision #35 rests on, and it is the claim to hold. Sharper figures circulate (~40 µs, a quarter of a percent of a frame); they are estimates from a desktop, **not measured on a target device**, and nothing in this document depends on them. What matters and is structural: the filter runs in Dart on the UI isolate, so the digits and the list update in the **same** frame, where a drift round-trip through the background isolate lands one or two frames late.

**`tagIndexProvider` carries ACTIVE animals only.** That is the owner's ruling on tag uniqueness (decision-record §7.0 #7): tags are unique among active animals, not globally, so a culled 412 releases the tag and a new 412 is a different row with its own history. The consequences land here:

1. The keypad's index and the create-on-the-fly match are the **same** active-only set, so typing `412` can never surface two live candidates and never needs a disambiguation dialog at 03:20 (spec §7.1 forbids one on the entry path).
2. A culled 412 is therefore **absent** from the keypad. That is correct and it is not silent: the ewe card for the new 412 shows "there was an earlier 412", and the history screen finds it. `03-data-model-and-schema.md` owns the partial unique index and `07-screens.md` owns the earlier-animal line.
3. The index is rebuilt by drift's `watch()` when an animal is culled or created. Nothing in this controller invalidates it.

### 10.3 The rules, and what is banned

1. **Filter in the controller, never in `build()`.** A `where` + `toList` per rebuild is the thing executing during the frame you cannot afford.
2. **`.select` only on stored fields** (§4.4).
3. **`const` everywhere it is legal**, so Flutter can short-circuit the rebuild.
4. **`ListView.builder` with `itemExtent`.** Rows are a fixed 72 pt because the 60×60 pt rule makes them so anyway; declaring it lets Flutter skip the intrinsic pass and jump straight to a scroll offset.
5. **`ValueKey(eweId)` on rows**, so elements and their state are reused as the filter narrows.
6. **No `Opacity`, `ShaderMask` or `ColorFilter` in a row.** They trigger `saveLayer`, which allocates an offscreen buffer and forces a render-target switch — Flutter's docs call this particularly disruptive on mobile GPUs. For a dimmed row, draw with a semi-transparent colour token instead.
7. **Never override `operator ==` on a widget.** It is O(N²) by Flutter's own documentation. Value equality belongs on the state class.
8. **No debounce on the keypad.** Debouncing a sub-millisecond operation is cargo cult, and it puts a visible lag between the thumb and the digit. The 200 ms debounce belongs to full-text note search on its own screen (decision #35), and the 400 ms ceiling belongs to free-text fields (§7.1). Those are the only two debounces in the app; a third is a defect.
9. **Nothing monetization-related renders here**, and nothing on this screen watches `entitlementProvider` (decision #90). The failure mode is a paywall flash at 3am.

**Profile before optimising further.** DevTools, profile mode, a real low-end device with a 400-ewe database — never the simulator, never debug mode. If it is fast there, stop.

---

## Definition of done

Tick every line before calling this area finished.

- [ ] `pubspec.yaml` contains `flutter_riverpod: 2.6.1` with no caret; `pubspec.lock` is committed and CI asserts the resolved version.
- [ ] `tool/check_policy.dart` contains every row in §2.4, and each row has a test in `test/policy/` proving it fires on a planted violation.
- [ ] `flutter analyze --fatal-infos` is clean, which independently proves no Riverpod-3-only class or parameter is in the tree.
- [ ] No `AsyncValue` accessor (`value`, `valueOrNull`, `requireValue`, `hasValue`, `asData`) appears anywhere; every read site is an exhaustive `switch`. Four are grepped; bare `.value` is a reviewer item (§2.4).
- [ ] `ref.mounted` appears nowhere; the type name `Ref` appears nowhere; no `ProviderObserver` mentions `ProviderObserverContext`.
- [ ] `lib/` contains zero occurrences of `overrideWith` / `overrideWithValue`.
- [ ] Every provider is declared in the file listed in §4.6, is named `<name>Provider`, and follows the auto-dispose policy in §4.2.
- [ ] `databaseProvider` is a `FutureProvider<AppDatabase>`; there is no `Provider<AppDatabase>` anywhere.
- [ ] No `clockProvider`, no `Clock` interface, no `SystemClock`. `DateTime.now(` and `clock.now()` appear only in `lib/core/time/app_clock.dart`; every other site calls `appNow()`.
- [ ] Every screen has exactly one controller, and no controller imports `package:drift/` or `lib/core/db/`.
- [ ] Every mutation in the app goes through a `WriteController.guard()`; `guard()` sets `WriteRunning` before its first `await`.
- [ ] Every `switch` over `WriteOutcome` handles all three variants — `WriteCommitted`, `WriteFailed`, `WriteRefused` — with no `default:`. `WriteRefused` never renders as a failure.
- [ ] `WriteCommitted.warnings` is rendered as a non-blocking badge alongside the saved confirmation. No code path corrects, blocks, or discards a write because of a warning (spec §12.4).
- [ ] `WriteState` subclasses do not implement `==`.
- [ ] The only static-field singleton in `lib/` is `LocalLog.instance`. Grep `\.instance\b`; every other hit is a defect.
- [ ] Provider and class names match `CONVENTIONS.md` §2.12 and §3 exactly: `NotificationScheduler`, `ShareService`, `MediaStore`, `CameraService`, `VoiceRecorder`, `WakelockController`, `settingsProvider`, `quickEntryDeckProvider`. No file contains a second spelling; `recentEwesProvider`, `inPensProvider` and `appSettingsProvider` appear nowhere.
- [ ] Every destructive action has a `tester.tap(); tester.tap();` test with no pump between the taps, and each one asserts exactly one row.
- [ ] Every screen has a `RouteNames` constant, and every `MaterialPageRoute` carries `settings: RouteSettings(name: …)`.
- [ ] `lib/routing/routes.dart` has one push method per pushed screen; `RouteNames` constants minus one equals `Routes` push methods (§8.1). No `MaterialPageRoute` is constructed anywhere else.
- [ ] Exactly one `PopScope(canPop: false)` exists in `lib/`, in the delete-everything flow. Every other `PopScope` is `canPop: true` and uses `onPopInvokedWithResult`; the deprecated `onPopInvoked` appears nowhere.
- [ ] Exactly two debounces exist in `lib/`: 200 ms on note search, 400 ms on free-text fields. Grep every `Duration(milliseconds:` near a `Timer`.
- [ ] `MaterialApp` sets no `restorationScopeId`; there is no `RestorationMixin`, no `Restorable*`, no `restorablePush`, and no iOS storyboard Restoration ID.
- [ ] `ResumePolicy.staleAfter` is 2 minutes, has a unit test at 1 min 59 s and 2 min 0 s, and takes its instants from `appNow()`.
- [ ] `WidgetsBinding.instance.addObserver(this)` runs in `initState` and `removeObserver(this)` in `dispose`. A widget test drives `hidden` → `resumed` and asserts the selection cleared — proving the observer is actually registered.
- [ ] The wakelock is released on **every** non-resumed lifecycle state, not only `hidden` (decision #79). Proved by a widget test that drives `inactive` and asserts release.
- [ ] The resume path calls `reconcile()` (decision #63). The token `schedule(` appears nowhere on a reminder object.
- [ ] Backgrounding for 3 minutes and returning lands on Quick Entry with nothing selected, the in-flight lambing is the first recents chip, and its displayed time is still the original auto-captured 03:20 — not the resume time. Verified by hand on a device, once per release.
- [ ] A widget test asserts `_Keypad` does not rebuild when a digit is typed (a build counter, or a golden of the rebuild set).
- [ ] `QuickEntryScreen` is a `StatelessWidget` and watches nothing.
- [ ] `QuickEntryState.matches` is a stored field; no derived collection in the codebase is a getter.
- [ ] `tagIndexProvider` returns active animals only, and a test proves a culled tag leaves the keypad index and is re-usable by a new animal (decision-record §7.0 #7).
- [ ] The overflow matrix (`12-testing.md`) passes for Quick Entry, Ewe Card, Lambing Entry, Pen Board and Foster.

---

## References

**Decision record and siblings**
- `../research/00-tech-decisions.md` — §1 (the five pre-commit decisions), §2 rows 11–24, 35, 46, 63, 66, 90, 103, 111, 112, §5.1/§5.3 (versions), §6 (corrections), §7.0 (owner's rulings).
- `../research/raw/02-state-and-navigation.md`, `../research/critique/c2-api-correctness.md` §1–3, §9, §11, `../research/critique/c3-consistency.md` A1, A5, C1, C3.
- `01-architecture.md` (layers, `main()`, `WriteOutcome`, `ShedFailure`), `05-domain-correctness.md` (`Instant`, `Warning`, `rankTagMatches` inputs), `06-design-system.md` (placeholders, tokens, ticker display), `07-screens.md` (per-screen states and undo), `12-testing.md` (harness, time in tests, overflow matrix), `13-build-ci-release.md` (`tool/check_policy.dart`, gates G1–G5), `CODE-REVIEW-CHECKLIST.md`.

**Riverpod**
- https://pub.dev/documentation/riverpod/2.6.1/riverpod/FamilyAsyncNotifier-class.html — the 2.6.1 family bound and `build(Arg)` signature.
- https://pub.dev/documentation/riverpod/2.6.1/riverpod/AutoDisposeFamilyNotifier-class.html — `build(Arg arg)` plus the `arg` getter (verified 2026-07-27).
- https://pub.dev/documentation/riverpod/2.6.1/riverpod/Provider-class.html — `overrideWithValue(State)` (verified 2026-07-27).
- https://pub.dev/documentation/riverpod/2.6.1/riverpod/FutureProvider-class.html — `overrideWith` and the `future` property (verified 2026-07-27).
- https://pub.dev/documentation/flutter_riverpod/2.6.1/flutter_riverpod/UncontrolledProviderScope-class.html — `{required ProviderContainer container, required Widget child}` (verified 2026-07-27); the 2.6.1 replacement for `WidgetTester.container`.
- https://pub.dev/documentation/flutter_riverpod/2.6.1/flutter_riverpod/ProviderScope-class.html — the 2.6.1 constructor; there is no `retry` parameter.
- https://pub.dev/api/packages/riverpod — `test: ^1.0.0` in runtime dependencies at 3.4.1.
- https://github.com/rrousselGit/riverpod/issues/4791 — maintainer's WONTFIX position.
- https://riverpod.dev/docs/whats_new — "notifiers now accept arguments through constructors" (a Riverpod-3 change); provider auto-retry with exponential backoff (3.x only).
- Riverpod 3.0.0 changelog (2025-04-30) — *"This major version is a transition version… It is quite possible that a 4.0.0 will be released relatively soon in the future."* A signal, **not a release date**; no date for 4.0.0 has been published and none should be written down here.

**Read from the package sources on disk, not from documentation** (verified 2026-07-27 against `~/.pub-cache/hosted/pub.dev/`). These are the rows in §2.1 that a reader is most likely to doubt, so the file and line are given:

| Claim | 2.6.1 | 3.4.1 |
|---|---|---|
| `Ref` shape | `riverpod-2.6.1/lib/src/framework/ref.dart:13` — `abstract class Ref<@Deprecated('Will be removed in 3.0') State extends Object?>` | `riverpod-3.4.1/lib/src/core/ref.dart:43` — `sealed class Ref implements BaseRef, MutationTarget` |
| `Ref.mounted` | absent (2.6.1's `mounted` is on `ProviderElementBase`, `framework/element.dart:106` — not reachable from `Ref`) | `riverpod-3.4.1/lib/src/core/ref.dart:112` |
| `ProviderObserver` | `riverpod-2.6.1/lib/src/framework/container.dart:714` — `abstract class`, `didUpdateProvider(ProviderBase, prev, next, container)` | `riverpod-3.4.1/lib/src/core/provider_container.dart:1407` — `abstract base class`, `ProviderObserverContext` |
| `ProviderContainer.test` | absent | `riverpod-3.4.1/lib/src/core/provider_container.dart:962` |
| `ProviderScope.retry` | absent from `flutter_riverpod-2.6.1/lib/src/framework.dart` | present |
| Family bound | `riverpod-2.6.1/lib/src/async_notifier/auto_dispose_family.dart:6` — `AutoDisposeFamilyAsyncNotifier<State, Arg>` with `late final Arg arg` and `FutureOr<State> build(Arg arg)` | constructor-delivered |
| `UncontrolledProviderScope` | `flutter_riverpod-2.6.1/lib/src/framework.dart:277` — `{super.key, required this.container, required super.child}` | same shape |

**Flutter**
- https://docs.flutter.dev/app-architecture/guide and https://docs.flutter.dev/app-architecture/case-study/dependency-injection — MVVM shape, one view model per view, DI without global objects.
- https://docs.flutter.dev/app-architecture/design-patterns/command — "ensures that it can't be launched again until it finishes", the basis of §7.
- https://docs.flutter.dev/perf/best-practices — split large builds, `const`, lazy builders, `saveLayer` cost, do not override `==` on widgets.
- https://docs.flutter.dev/release/breaking-changes/android-predictive-back — `canPop` decided ahead of time; `enableOnBackInvokedCallback`.
- https://api.flutter.dev/flutter/widgets/runApp.html — `runApp` initialises the binding itself.
- https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html — `hidden` is synthesised on both platforms and is the last guaranteed state.
- https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html and https://api.flutter.dev/flutter/widgets/Navigator/restorablePush.html — what restoration would have cost.
- https://api.flutter.dev/flutter/services/RestorationManager-class.html — the iOS `FlutterViewController` restoration-ID requirement this app does not pay.
- https://github.com/flutter/flutter/issues/117683 (open since 2022-12-27) and https://github.com/flutter/flutter/issues/174935 — go_router restoration defects.

**Platform**
- https://developer.apple.com/documentation/uikit/about-the-app-launch-sequence — suspended apps stay in memory; termination under memory pressure.
- https://developer.android.com/guide/components/activities/process-lifecycle — cached processes are killed freely; `onDestroy()` is not guaranteed.

**drift**
- https://github.com/simolus3/drift/issues/3338 — two streams updated in one transaction can emit at different times; the reason `combineLatest` is banned.
