# Shed Book — Research Notes 02: State Management, DI, and Navigation

**Researched:** 2026-07-27
**Toolchain verified against:** Flutter 3.44.6 stable (revision `ee80f08bbf`, 2026-07-08) · Dart 3.12.2 · DevTools 2.57.0 · macOS arm64 · Android SDK build-tools 36.0.0
**Method:** every package version below was read from the pub.dev API (`https://pub.dev/api/packages/<name>`), not from memory. Every dependency-resolution claim was reproduced locally with `flutter pub get`. Every Dart snippet in this document was compiled with `flutter analyze` against the exact versions named.

---

## Bottom line

| Question | Decision | Confidence |
|---|---|---|
| State management package | **`flutter_riverpod` 2.6.1**, pinned. Not 3.x. | High |
| Why not Riverpod 3.x | 3.x declares `test` as a **runtime** dependency (WONTFIX per maintainer). On *this app's actual stack* it makes `flutter pub get` fail outright, where every alternative resolves. | High — reproduced locally |
| Does the `test` dep create a network path? | **No.** Release APK has no `INTERNET` permission; zero shelf/websocket symbols survive AOT tree-shaking. The premise is half-true — the cost is *resolution*, not *runtime*. | High — verified on a built APK |
| Codegen (`riverpod_generator` / `build_runner`) | **No.** Latest `riverpod_generator` 4.0.6 and `riverpod_lint` 3.1.6 are **unresolvable — broken on publish**. Write providers by hand. | High — reproduced locally |
| `riverpod_lint` | **Skip.** Currently unresolvable at 3.1.6. Revisit later. | High |
| DI | **Riverpod providers as the composition root.** `ProviderScope(overrides: [...])` in `main()`. No `get_it`, no global singletons. | High |
| Navigation | **Imperative `Navigator` 2.0 via `MaterialApp` + named-free typed helpers.** `go_router` is *not* earning its keep here. | Medium-High |
| State restoration | `restorationScopeId` + `RestorationMixin` for the **keypad query string and scroll offsets only**. Everything else is already in SQLite. | High |
| Immutable state | Hand-written `@immutable` classes with a stored (not computed) derived field. No `freezed`. | High |
| Quick-entry list | `ListView.builder` + `itemExtent` + `const` rows + precomputed match list + `.select`. | High |

**The one-line version:** use the *boring, stable* Riverpod 2.6.1 with hand-written providers and the plain `Navigator`. The exciting options (Riverpod 3.x, codegen, go_router) each cost this specific app more than they return.

---

## 1. The Riverpod 3.x `test`-dependency question — settled with evidence

This was the assignment's critical question. The answer has two halves, and they point in opposite directions. I got the second half wrong in my first pass and had to correct it.

### 1.1 The dependency is real, current, and deliberate

Read verbatim from the pub.dev API on 2026-07-27:

**`riverpod` 3.4.1**, published `2026-07-26T17:31:54Z`, publisher `dash-overflow.net`. Runtime `dependencies:`

```yaml
async: ^2.12.0
clock: ^1.1.1
collection: ^1.18.0
listen: ^1.0.0-beta.3
meta: ^1.15.0
stack_trace: ^1.12.1
state_notifier: ">=0.7.2 <2.0.0"
test: ^1.0.0          # <-- runtime dependency
uuid: ^4.5.1
```

**`flutter_riverpod` 3.4.1**, published `2026-07-26T17:32:12Z`. Runtime `dependencies:`

```yaml
collection: ^1.15.0
flutter: {sdk: flutter}
flutter_test: {sdk: flutter}     # <-- runtime dependency
meta: ^1.15.0
riverpod: 3.4.1
state_notifier: ">=0.7.2 <2.0.0"
```

`hooks_riverpod` 3.4.1 carries `flutter_test` too.

Source: [pub.dev/packages/riverpod](https://pub.dev/packages/riverpod) · [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod)

**When it appeared, and whether it was ever fixed.** I walked every published `riverpod` version:

| Version | Published | `test` in `dependencies:` |
|---|---|---|
| 2.6.1 (last 2.x) | 2024-10-22 | **no** |
| 3.0.0-dev.12 | 2025-04-30 | `^1.0.0` |
| 3.0.0 | 2025-09-10 | `^1.0.0` |
| 3.2.1 | 2026-02-03 | `^1.0.0` |
| 3.3.2 | 2026-06-10 | `^1.0.0` |
| **3.4.1 (latest)** | **2026-07-26** | **`^1.0.0`** |

**It has never been fixed and there is no entry in the changelog proposing to fix it.**

**Root cause**, from the package source (`riverpod-3.4.1/lib/src/core/provider_container.dart:959`):

```dart
/// This constructor works only inside tests, by relying on `package:test`'s
/// `addTearDown`.
@visibleForTesting
factory ProviderContainer.test({ ... }) {
  final container = ProviderContainer(...);
  test.addTearDown(container.dispose);
  return container;
}
```

`lib/src/framework.dart:15` does `import 'package:test/test.dart' as test;`, and `framework.dart` is re-exported through `lib/src/_internals.dart` → `lib/riverpod.dart`. So `package:test` sits on the import graph reachable from the public entry point of every app that uses Riverpod 3.x.

### 1.2 The maintainer's position: WONTFIX, by design

[flutter/riverpod issue #4791, "test declared as direct dependency causes pub get conflicts"](https://github.com/rrousselGit/riverpod/issues/4791) — opened 2026-06-22, **closed 2026-06-23 as `completed`** (i.e. closed as answered, not as fixed). Quoting `rrousselGit` verbatim:

> "`ProviderContainer.test` is visible to downstream consumers. It is a public API. A test API, yes, but public still. It is meant to be used by all Riverpod users. As such `dev_dependencies` is not appropriate here."

and, closing the thread:

> "For now, I still lean towards thinking that the benefits are better than the downsides.
> - All projects should depend on `test` somehow, so any conflict with `test` is likely bound to happen regardless of Riverpod
> - On the flip side, `ProviderContainer.test` is way too small to warrant a package. Nobody would use it. This would be a big loss for the community IMO."

Related, also closed: [#4364](https://github.com/rrousselGit/riverpod/issues/4364) ("Riverpod 3.0.3's test dependency requires analyzer <8.0.0, while some other dependencies require analyzer >= 8.0.0" — the reporter's blocked `dev_dependencies` included **`drift_dev`**, which this app will use) and [#4308](https://github.com/rrousselGit/riverpod/issues/4308).

**Conclusion: this will not be fixed in the 3.x line. Plan around it, not for it.**

### 1.3 Does it introduce a network path? **No.** I was wrong to assume it did.

The brief framed the `test` dependency as potentially "disqualifying for an app whose core claim is that it has no network path." I built the app and checked. **It is not.** Three independent checks:

**(a) `package:test` and its transitive network packages ship no native code.** The `test` 1.31.2 archive contains only `bin/ doc/ lib/ test/ tool/` — no `android/`, no `AndroidManifest.xml`, no `.java`/`.kt`/`.gradle`. Nothing can be merged into the app manifest, because there is nothing to merge.

**(b) The built release APK declares no `INTERNET` permission.** I created a Flutter app with `flutter_riverpod: ^3.4.1` and ran `flutter build apk --release` (Flutter 3.44.6). Reading the *generated* merged manifests and the packaged binary:

```
$ aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
package: com.shedbook.rp3
permission: com.shedbook.rp3.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='com.shedbook.rp3.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
```

That is the only permission. No `android.permission.INTERNET`. Every generated `*/release/*/AndroidManifest.xml` contains exactly one `uses-permission`, the auto-generated dynamic-receiver one.

> **Separate but important:** Flutter's own `android/app/src/debug/AndroidManifest.xml` and `src/profile/AndroidManifest.xml` **do** declare `android.permission.INTERNET` (for the Dart VM service / hot reload). That is Flutter, not Riverpod, and it is stripped from release builds. The spec's "Android build that declares NO INTERNET permission at all" is achievable by default — just never add it to `src/main/AndroidManifest.xml`. Verify per release with the `aapt2 dump permissions` command above; make it a release-checklist item.

**(c) None of the code survives tree-shaking into the binary.** Scanning the release `arm64-v8a/libapp.so` (4.46 MB) for symbols:

| Symbol searched | Occurrences in release `libapp.so` |
|---|---|
| `web_socket_channel` | 0 |
| `WebSocketChannel` | 0 |
| `package:shelf` | 0 |
| `package:test` | 0 |
| `addTearDown` | 0 |
| `HttpServer` | 0 |
| `webkit_inspection` | 0 |

Dart's AOT compiler removes all of it. `ProviderContainer.test` is never called from app code, so the whole subgraph is unreachable and dropped.

**So: the "no network path" claim survives Riverpod 3.x intact.** Do not reject Riverpod 3.x on that basis. That would be cargo-culting a scary-looking dependency list.

### 1.4 What the dependency *actually* costs — and why it is still disqualifying here

The real cost is at **resolution time**, which happens before any build and cannot be tree-shaken away. This is precisely the distinction the issue reporter drew and the maintainer initially disputed.

**Minimal comparison.** Same pubspec, only the Riverpod version changed, Flutter 3.44.6:

| Dependency set | Packages in `pubspec.lock` |
|---|---|
| `flutter_riverpod: ^2.6.1` + `go_router` | **32** |
| `flutter_riverpod: ^3.4.1` + `go_router` | **68** |

The 36 extra packages include `test`, `test_core`, `test_api`, `shelf`, `shelf_web_socket`, `shelf_static`, `shelf_packages_handler`, `web_socket_channel`, `http_multi_server`, `webkit_inspection_protocol`, `coverage`, `node_preamble`, `frontend_server_client`, `analyzer`, `vm_service`.

**The decisive test: this app's real stack.** I built the pubspec Shed Book will actually have — Drift + `sqlite3_flutter_libs` + `path_provider` + `flutter_local_notifications` + `share_plus` + `go_router`, with `build_runner` + `drift_dev` in `dev_dependencies` — and swapped only the state-management line. Flutter 3.44.6 / Dart 3.12.2:

| State-management dependency | `flutter pub get` result |
|---|---|
| *(none at all)* | resolves — 112 packages |
| `get_it: ^9.2.1` | resolves — 113 packages |
| `provider: ^6.1.5+1` | resolves — 114 packages |
| `flutter_bloc: ^9.1.1` | resolves — 116 packages |
| `flutter_riverpod: ^2.6.1` | resolves — 117 packages |
| `signals: ^7.1.0` | resolves — 118 packages |
| **`flutter_riverpod: ^3.4.1`** | **FAILS — "version solving failed"** |

The failure message is entirely about `test`:

```
Because test >=1.24.3 <1.25.13 depends on matcher >=0.12.16 <0.12.17 and
test >=1.31.2 depends on test_api 0.7.13, test >=1.24.3 <1.25.13-∞ or >=1.31.2
requires matcher >=0.12.16 <0.12.17 or test_api 0.7.13.
Because test >=1.16.6 <1.17.10 depends on analyzer ^1.0.0 and
test >=1.17.10 <1.20.0 depends on analyzer >=1.0.0 <3.0.0, ...
So, because full depends on both build_runner ^2.4.0 and drift_dev ^2.34.5,
version solving failed.
```

`flutter_riverpod` 3.4.1 is **the only state-management option tested that breaks `pub get` on this app's stack**, and it breaks it because of `test`. The maintainer's argument — "any conflict with `test` is likely bound to happen regardless of Riverpod" — is falsified for this specific, entirely mainstream, Flutter-3.44.6-stable configuration: with no state package at all, resolution succeeds.

**Workarounds exist, and both have a running cost.** In fairness, Riverpod 3.4.1 *can* be made to work:

1. **Loosen the codegen constraints to `any`:** `build_runner: any` + `drift_dev: any` resolves (128 packages). But inspect what pub picked: `drift_dev 2.34.0` — **not** the current 2.34.5. Riverpod's `test` dependency silently held your database toolchain back two patch releases, and `any` constraints mean it will keep doing so invisibly.
2. **`dependency_overrides: {test: ^1.31.0, analyzer: ^13.0.0}`** — also resolves (125 packages). `dependency_overrides` disables pub's compatibility checking for those packages; it is a documented escape hatch, not a design.
3. **Drop `drift_dev`/`build_runner` entirely** — resolves (111 packages), but you lose Drift's codegen, which is the main reason to use Drift.

Each of these is a small, permanent tax on a solo developer maintaining one app for five-plus seasons. None of them buys anything the app needs.

### 1.5 Decision: `flutter_riverpod` 2.6.1, pinned

```yaml
dependencies:
  flutter_riverpod: 2.6.1   # exact pin, not ^2.6.1 — see below
```

**Why 2.6.1 wins for *this* app:**

- It resolves cleanly against the real stack with no `any` constraints and no `dependency_overrides`.
- Its dependency graph is `collection`, `meta`, `stack_trace`, `state_notifier` — four packages, all first-party, all pure Dart. When the app's core marketing claim is "nothing leaves the device", a dependency list an auditor can read in ten seconds has genuine value even though I proved the 3.x one is harmless at runtime. You should not have to explain `webkit_inspection_protocol` to anyone.
- The API surface this app needs — `Notifier`, `AsyncNotifier`, `NotifierProvider`, `family`, `autoDispose`, `.select`, `ref.listen`, `ProviderScope` overrides — is **entirely present in 2.6.1**. Nothing in section 4 of these notes requires 3.x.
- It is *frozen*. Last published 2024-10-22. For an app with no server, no API to track, and a five-year horizon, a frozen dependency is a feature.

**The honest counter-argument, stated fully:**

- 2.6.1 is 21 months old and receives **no bug fixes**. Real fixes have landed only in 3.x — including a Notifier state-loss regression fix (3.2.0), a `ConsumerState.dispose` listener leak (3.4.0), and several `markNeedsBuild` scheduling bugs. If you hit one of those in 2.6.1, you are on your own.
- 3.x has genuinely nice things: `Ref.mounted`, sealed `AsyncValue` for exhaustive `switch`, and automatic pausing of providers behind an invisible `TickerMode` (which would be pleasant for the pen-board hour timers).
- Riverpod's author explicitly warns in the 3.0.0 changelog: *"This major version is a transition version, to unblock the development of the project. It is quite possible that a 4.0.0 will be released relatively soon in the future, so keep that in mind when migrating."* Migrating to 3.x now plausibly buys you a **second** migration shortly. That argues for either staying on 2.6.1 or waiting for 4.0.0 — not for adopting 3.4.1 today.

**Pin exactly (`2.6.1`, no caret).** There is no 2.7.x and never will be; a caret only invites a surprise. Add a comment in `pubspec.yaml` pointing at this document so the reason survives.

**Revisit trigger:** re-evaluate when Riverpod 4.0.0 ships, or if a 2.6.1 bug blocks you. If you must move to 3.x before then, use option 1 above (`build_runner: any`, `drift_dev: any`) and add a CI check that `pubspec.lock` still contains the drift_dev version you expect.

**Migration cost if you later move 2.6.1 → 3.x/4.x** is modest and mostly mechanical, because the patterns recommended below are the ones 3.x kept: `Notifier`/`AsyncNotifier` classes, `ProviderScope` overrides, `.select`. The 3.0.0 breaking changes that would touch this app are: `StateProvider`/`StateNotifierProvider` moved to `legacy.dart` (we use neither), `AsyncValue.valueOrNull` → `.value` (grep-able), and `Provider.autoDispose.family(...)` gaining the equivalent `Provider.family(..., isAutoDispose: true)` spelling (the old spelling still works). Avoiding `StateProvider` and `valueOrNull` from day one — see §9 — makes this a near-no-op.

---

## 2. Riverpod vs Bloc vs signals vs ChangeNotifier/Provider

### 2.1 What Flutter itself says

Flutter's official architecture guidance is more specific than people assume, and it does **not** name Riverpod.

From [docs.flutter.dev/app-architecture/recommendations](https://docs.flutter.dev/app-architecture/recommendations):

| Topic | Flutter's rating | Flutter's recommendation |
|---|---|---|
| State management | **Conditional** | "Use `ChangeNotifiers` and `Listenables` to handle widget updates." "There are many options… ultimately the decision comes down to personal preference." |
| Dependency injection | **Strongly recommend** | "We recommend you use the **provider** package to handle dependency injection." |
| ViewModels (MVVM) | **Strongly recommend** | "Use ViewModels and Views in the UI layer." |
| Immutable data models | **Strongly recommend** | "Use immutable data models." |
| `freezed`/`built_value` | Recommend | "…can add significant build time to your applications if you have a lot of models." |
| Navigation | **Recommend** | "Use `go_router`… the preferred way to write 90% of Flutter applications." |
| Command pattern | Recommend | "Use `Commands` to handle events from user interaction." |

From [docs.flutter.dev/app-architecture/case-study/dependency-injection](https://docs.flutter.dev/app-architecture/case-study/dependency-injection):

> "In the Compass app, *dependency injection* is handled using `package:provider`. Based on their experience building Flutter apps, teams at Google recommend using `package:provider` to implement dependency injection."

And [docs.flutter.dev/data-and-backend/state-mgmt/options](https://docs.flutter.dev/data-and-backend/state-mgmt/options) refuses to crown a winner: *"The best choice for your app often depends on the app's complexity, your team's preferences, and the specific problems you need to solve."*

So the officially-blessed stack is **MVVM + `ChangeNotifier` + `package:provider` + `go_router`**. This document diverges from it on two of four points, and says why below.

### 2.2 The candidates, with verified numbers

All figures read from the pub.dev API on 2026-07-27.

| Package | Version | Published | Publisher | Likes | Pub points | 30-day downloads |
|---|---|---|---|---|---|---|
| `flutter_riverpod` | 3.4.1 | 2026-07-26 | dash-overflow.net ✓ | 2,895 | 140/160 | 2,522,057 |
| `flutter_riverpod` (2.x) | 2.6.1 | 2024-10-22 | dash-overflow.net ✓ | — | — | — |
| `provider` | 6.1.5+1 | 2025-08-19 | dash-overflow.net ✓ | 10,992 | 150/160 | 1,120,736 |
| `flutter_bloc` | 9.1.1 | 2025-05-02 | bloclibrary.dev ✓ | 8,055 | 160/160 | 1,765,063 |
| `signals` | 7.1.0 | 2026-05-29 | rodydavis.com ✓ | 688 | 160/160 | 19,174 |
| `get_it` | 9.2.1 | 2026-02-20 | (see pub.dev) | 4,711 | 150/160 | 1,887,232 |
| `go_router` | 17.3.0 | 2026-06-02 | **flutter.dev** ✓ | 5,757 | 150/160 | 3,526,050 |

Note `provider` and `riverpod` share a maintainer (Remi Rousselet / dash-overflow.net).

### 2.3 The evidence-based comparison for a solo dev, 12 screens, offline

**First, the framing that matters most and that most comparisons miss.**

This app's source of truth is SQLite. Drift exposes `Stream`s via `.watch()`. Almost every screen is *"run a query, render the rows"*. There is no server, no cache-invalidation problem, no optimistic update, no request de-duplication, no auth token refresh — none of the problems that make state management genuinely hard and that Riverpod's more advanced machinery exists to solve.

**The actual state-management surface of Shed Book is small:**

1. Inject four collaborators (database, clock, notification gateway, share gateway).
2. Hold a handful of ephemeral, screen-local values — most importantly the quick-entry keypad's query string.
3. Bridge Drift streams into widgets.
4. Keep derived values (filtered flock list, pen hour counts, season stats) off the widget-build path.

That is a small job, and it should be judged on *ceremony per screen*, not on peak capability.

**`ChangeNotifier` + `provider`** — Flutter's own answer.
*For:* zero new concepts; `ChangeNotifier` is in the SDK; officially recommended; smallest dependency (`provider` adds only `nested`); resolves cleanly.
*Against:* `ChangeNotifier` is mutable and notifies imperatively, which fights the "immutable data models" recommendation sitting three rows above it in Flutter's own table. `provider`'s DI is `BuildContext`-scoped, so anything that needs a dependency needs a `context` — awkward in a notification-scheduling helper or an export routine. Overriding for tests means rebuilding a widget tree. It is a genuinely reasonable choice and the honest runner-up.

**`flutter_bloc`** — the most disciplined option.
*For:* 160/160 pub points, huge adoption, excellent testing story, explicit and traceable event→state transitions, very stable API.
*Against:* the ceremony is the point of Bloc, and here the ceremony is the cost. An event class, a state class, and a bloc per screen across 12 screens is a lot of files to express "the user typed a digit; filter the list." Bloc's discipline pays off on teams and on complex async flows; this is one developer and a local database. Also note `flutter_bloc` depends on `provider` anyway.

**`signals`** — the most elegant option.
*For:* 160/160 pub points, genuinely fine-grained reactivity, minimal boilerplate, active maintainer.
*Against:* 688 likes and **19,174 monthly downloads** against Riverpod's 2.5M and Bloc's 1.8M. For a solo developer maintaining an app for five seasons with no colleagues to ask, ecosystem depth *is* a risk-management feature — Stack Overflow answers, worked examples, and the odds the package still exists in 2031. This is the "popular answer beats the elegant answer" case, and I think popularity is genuinely right here.

**`riverpod` (2.6.1)** — the recommendation.
*For:*
- **Compile-safe DI that does not need `BuildContext`.** This is the single biggest win. The export routine, the notification scheduler and the season-stats calculator all need the database and the clock; none of them should need a widget.
- **`ProviderScope(overrides:)` is a first-class test seam** — swap in an in-memory database and a fake clock with two lines and no widget tree. For an app with non-negotiable correctness rules (§12 of the spec: withdrawal periods, honest timestamps), being able to test the domain logic headlessly matters.
- **`.select` and `autoDispose`** are exactly the tools the quick-entry screen and the per-ewe screens need (§7).
- Immutable state by default, matching Flutter's own "strongly recommend".
- Largest ecosystem of the reactive options.

*Against:* it is a third-party package with a history of major-version churn (2.0 → 3.0 → a promised 4.0), and the author's own changelog calls 3.0 "a transition version". Pinning 2.6.1 is the mitigation.

**Verdict:** Riverpod 2.6.1. If you find Riverpod's concepts genuinely getting in the way during the first week, `provider` + `ChangeNotifier` is a legitimate fallback and Flutter officially recommends it — but you will hand-roll the non-widget DI that Riverpod gives you free.

**Do not use `hooks_riverpod`.** It adds `flutter_hooks` and a second mental model (hook rules, ordering constraints) for no benefit here, and it carries the same `flutter_test` runtime dependency at 3.x.

---

## 3. Codegen: no. And the reason is stronger than "build times"

### 3.1 What the tooling actually does today

Verified 2026-07-27 by attempting resolution with Flutter 3.44.6:

| Attempted | Result |
|---|---|
| `riverpod_generator: ^4.0.6` (latest) | **UNRESOLVABLE** |
| `riverpod_lint: ^3.1.6` (latest) | **UNRESOLVABLE** |
| both together | **UNRESOLVABLE** |

```
Because riverpod_analyzer_utils >=1.0.0-dev.10 depends on analyzer ^12.0.0
and riverpod_generator >=4.0.6 depends on analyzer ^13.0.0,
riverpod_analyzer_utils >=1.0.0-dev.10 is incompatible with riverpod_generator >=4.0.6.
So, because cg depends on riverpod_generator ^4.0.6 which depends on
riverpod_analyzer_utils 1.0.0-dev.10, version solving failed.
```

Both packages are **internally self-contradictory**: they declare `analyzer: ^13.0.0` directly while pinning `riverpod_analyzer_utils: 1.0.0-dev.10`, which requires `analyzer: ^12.0.0`. They cannot be installed in *any* project.

This is not an edge case in my setup — it is arithmetic on the published constraints. Both were published **2026-07-26**, the same day as `riverpod` 3.4.1 (whose changelog notes "Upgraded `analyzer` to `<15.0.0`"): the bump shipped without a matching `riverpod_analyzer_utils` release.

The compatibility history shows how tightly coupled this chain is:

| `riverpod_generator` | Published | `analyzer` | `riverpod_analyzer_utils` |
|---|---|---|---|
| 4.0.3 | 2026-02-03 | `^9.0.0` | `1.0.0-dev.9` |
| 4.0.4 | 2026-06-10 | `^12.0.0` | `1.0.0-dev.10` |
| **4.0.6** | **2026-07-26** | **`^13.0.0`** | **`1.0.0-dev.10`** ← mismatch |

Falling back to the last coherent generation (`riverpod_generator 4.0.4`) forces `riverpod_annotation 4.0.3`, which forces `riverpod 3.3.2`, which conflicts with `build_runner >=2.15.2`. A working set exists — `riverpod 3.3.2` + `riverpod_annotation 4.0.3` + `riverpod_generator 4.0.4` + `riverpod_lint 3.1.4` + `build_runner <2.15.2` — but that is **five pinned packages, all held one release generation behind**, on top of the `test` problem in §1.

### 3.2 Build time is *not* the argument (be honest about this)

I measured it. Trivial file, two providers, `build_runner` with the new AOT snapshot path:

```
COLD:  Built with build_runner/aot in 14s; wrote 2 outputs.   (16.5s wall)
WARM:  Built with build_runner/aot in 0s; wrote 0 outputs.    (0.7s wall)
```

`build_runner` in 2026 is far faster than its reputation. **Do not reject codegen on build-time grounds — that argument is out of date.** Reject it on toolchain fragility, which is measurable and current.

Note also that this app will run `build_runner` anyway for **Drift**. The question is not "codegen or no codegen" — it is "one generator or two". Adding `riverpod_generator` means one more package in the analyzer version-lock chain that already broke twice this year.

### 3.3 What codegen would have bought

Genuine benefits, stated fairly: `@riverpod` infers the provider type and generic parameters, generates `family` argument classes with proper equality, makes `autoDispose` the default, and removes a class of "wrong generic parameter" errors. On a 40-provider app with complex families it is a real ergonomic win.

Shed Book will have roughly 12–18 providers. Hand-writing them costs about one extra line each.

### 3.4 Decision

**No `riverpod_generator`. No `riverpod_annotation`. No `riverpod_lint`.** Write providers by hand as shown in §4. Keep `build_runner` for Drift only.

Revisit if and when `riverpod_analyzer_utils` gets a release matching `analyzer ^13`, *and* the `test` runtime dependency is resolved, *and* 4.0.0 has settled.

**Footnote worth knowing:** `riverpod_lint` 3.1.0 (2025-12-26) migrated off `custom_lint` to Dart's native `analysis_server_plugin` — *"`riverpod_lint` is no-longer implemented using `custom_lint`, but instead `analysis_server_plugin`"*. That is a real improvement (no more `custom_lint` server flakiness) and makes `riverpod_lint` worth re-evaluating once it resolves. It also means you do **not** need `custom_lint` in this project — which is fortunate, since `custom_lint` 0.8.1 still requires `analyzer ^8.0.0` and would conflict with everything.

---

## 4. The patterns to actually use

> Every snippet below was compiled with `flutter analyze` (Flutter 3.44.6 / Dart 3.12.2) against `flutter_riverpod` and `go_router`, and reports **"No issues found!"**. The API shapes were additionally cross-checked against the `riverpod` package source (`lib/src/builder.dart`, `lib/src/providers/notifier/orphan.dart`).
>
> **API note:** these snippets are written in the shared 2.x/3.x subset and compile on both. Where 3.x adds a spelling (e.g. `isAutoDispose:`), the 2.x spelling (`.autoDispose`) is shown as the primary and the 3.x one is noted.

### 4.1 Composition root and DI — "no global singletons"

The rule: **nothing is reachable statically.** No `AppDatabase.instance`, no `GetIt.I`, no top-level mutable. Every collaborator is a provider, and the real implementations are injected exactly once, in `main()`.

```dart
// lib/di.dart
//
// Leaf providers. Each one throws by default so that forgetting to override it
// is a loud crash at startup, not a silent null at 3am.

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Wraps flutter_local_notifications. The app layer never imports the plugin.
abstract class NotificationGateway {
  Future<void> schedule({required int id, required DateTime at, required String body});
  Future<void> cancel(int id);
}

/// Wraps share_plus. The app layer never imports the plugin.
abstract class ShareGateway {
  Future<void> shareFiles(List<String> paths, {String? subject});
}

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden in main()'),
);

/// Injected, never called as DateTime.now() directly. This is what makes the
/// spec's "timestamps are honest" rule testable: a fake clock lets a test prove
/// that an auto-captured time is stored verbatim and flagged as auto-captured.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => throw UnimplementedError('notificationGatewayProvider must be overridden'),
);

final shareGatewayProvider = Provider<ShareGateway>(
  (ref) => throw UnimplementedError('shareGatewayProvider must be overridden'),
);
```

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the DB and warm the notification plugin BEFORE runApp so the first
  // frame can already render real data — see the 3am note in §4.7.
  final db = await openShedBookDatabase();
  final notifications = await LocalNotificationGateway.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationGatewayProvider.overrideWithValue(notifications),
        shareGatewayProvider.overrideWithValue(const SystemShareGateway()),
        // clockProvider intentionally NOT overridden: its default is correct.
      ],
      child: const ShedBookApp(),
    ),
  );
}
```

**Why `throw` rather than a default instance:** a default would let a screen silently open a *second*, empty database if a `ProviderScope` were ever misconfigured. Throwing turns that into a crash on the first frame, in development, instead of a lost lambing record in a shed.

**Why gateway interfaces rather than the plugins directly:** it keeps `share_plus` and `flutter_local_notifications` out of the domain layer, so unit tests need no platform channels, and it puts one auditable place between the app and anything that touches the OS.

### 4.2 One ViewModel per screen — sync `Notifier`

Matches Flutter's "Views and view models should have a one-to-one relationship."

```dart
@immutable
class QuickEntryState {
  /// `matches` is a STORED FIELD, computed once in the factory.
  /// It must NOT be a getter — see the pitfall in §8.1.
  const QuickEntryState._({
    required this.query,
    required this.all,
    required this.recents,
    required this.matches,
  });

  factory QuickEntryState({
    String query = '',
    List<Ewe> all = const [],
    List<Ewe> recents = const [],
  }) {
    return QuickEntryState._(
      query: query,
      all: all,
      recents: recents,
      matches: query.isEmpty
          ? all
          : all.where((e) => e.tag.contains(query)).toList(growable: false),
    );
  }

  final String query;
  final List<Ewe> all;
  final List<Ewe> recents;

  /// Precomputed once per state transition, never per widget build.
  final List<Ewe> matches;

  QuickEntryState copyWith({String? query, List<Ewe>? all, List<Ewe>? recents}) =>
      QuickEntryState(
        query: query ?? this.query,
        all: all ?? this.all,
        recents: recents ?? this.recents,
      );
}

class QuickEntryVm extends Notifier<QuickEntryState> {
  @override
  QuickEntryState build() => QuickEntryState();

  void appendDigit(String d) => state = state.copyWith(query: state.query + d);

  void backspace() {
    final q = state.query;
    if (q.isEmpty) return;
    state = state.copyWith(query: q.substring(0, q.length - 1));
  }

  /// Commits immediately — there is no draft state (spec §5).
  Future<void> commitLambing(int eweId, int birthType) async {
    final db = ref.read(databaseProvider);
    final clock = ref.read(clockProvider);
    await db.insertLambing(
      LambingDraft(eweId: eweId, at: clock.now(), birthType: birthType),
    );
  }
}

final quickEntryVmProvider =
    NotifierProvider<QuickEntryVm, QuickEntryState>(QuickEntryVm.new);
```

**Notifier lifecycle, precisely.** The `riverpod` source documents it (`lib/src/providers/notifier/orphan.dart`):

> "If a dependency of this `Notifier` (when using `Ref.watch`) changes, then `build` will be re-executed. On the other hand, the `Notifier` will **not** be recreated. Its instance will be preserved between executions of `build`."

Be careful reading the 3.0.0 changelog here: `3.0.0-dev.12` listed *"**Breaking**: `Notifier` and variants are now recreated whenever the provider rebuilds"*, but `3.0.0-dev.16` **reverted it** — *"Revert Notifier life-cycle change. They are once again preserved across rebuilds."* The final behaviour in both 2.6.1 and 3.4.1 is: **instance preserved, `build()` re-run.** Do not put one-time setup in the constructor expecting it to re-run.

### 4.3 `AsyncNotifier` and Drift streams

For anything read straight from the database, prefer a `StreamProvider` over an `AsyncNotifier` — Drift already gives you the reactivity, and re-wrapping it adds nothing.

```dart
/// Preferred for pure reads: Drift's .watch() is already the reactive source.
final flockStreamProvider = StreamProvider<List<Ewe>>(
  (ref) => ref.watch(databaseProvider).watchAllEwes(),
);

/// Use AsyncNotifier only where a screen owns commands as well as data.
class SeasonSummaryVm extends AsyncNotifier<SeasonStats> {
  @override
  Future<SeasonStats> build() async {
    final db = ref.watch(databaseProvider);
    return computeSeasonStats(await db.lambingsForCurrentSeason());
  }

  Future<void> recompute() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      return computeSeasonStats(await db.lambingsForCurrentSeason());
    });
  }
}

final seasonSummaryVmProvider =
    AsyncNotifierProvider<SeasonSummaryVm, SeasonStats>(SeasonSummaryVm.new);
```

Render with exhaustive pattern matching:

```dart
final stats = ref.watch(seasonSummaryVmProvider);
return switch (stats) {
  AsyncData(:final value) => SeasonChart(stats: value),
  AsyncError(:final error) => ErrorPanel(error: error),
  _ => const SizedBox.shrink(),   // see §8.6 on loading spinners
};
```

### 4.4 `family` + `autoDispose` for per-animal screens

This is exactly what the ewe card and lamb card need: one provider instance per animal, disposed when you navigate away, so a season of browsing does not accumulate 400 live view models.

```dart
class EweCardVm extends AsyncNotifier<EweCard> {
  EweCardVm(this.eweId);
  final int eweId;

  @override
  Future<EweCard> build() async {
    final db = ref.watch(databaseProvider);
    return db.eweCard(eweId);
  }
}

// 2.6.1 spelling (also valid in 3.x):
final eweCardVmProvider =
    AsyncNotifierProvider.autoDispose.family<EweCardVm, EweCard, int>(
  EweCardVm.new,
);

// 3.x additionally allows the flatter spelling:
//   AsyncNotifierProvider.family<EweCardVm, EweCard, int>(
//     EweCardVm.new, isAutoDispose: true);
```

Verified against `riverpod-3.4.1/lib/src/builder.dart`, whose family builder signature is
`call<NotifierT extends Notifier<StateT>, StateT, ArgT>(NotifierT Function(ArgT arg) create, {..., bool isAutoDispose = false})` — i.e. **the family argument arrives through the notifier's constructor**, not as a `build(arg)` parameter.

Usage: `ref.watch(eweCardVmProvider(412))`.

**`family` argument equality matters.** The argument is the cache key and is compared with `==`. Use `int` ids (as above) or `String` tags. Never pass a record, list, or custom class without a correct `==`/`hashCode`, or you will create a new provider instance on every rebuild and leak them.

**Keep `autoDispose` off the flock list.** The flock list is re-entered constantly during a night; disposing and re-querying it on every navigation is exactly the wrong trade at 3am. `autoDispose` belongs on per-animal detail screens, not on the hub.

### 4.5 `watch` / `read` / `listen` discipline

The three-line rule, which prevents most Riverpod bugs:

| Method | Where | Purpose |
|---|---|---|
| `ref.watch` | **only** in `build()` / `Notifier.build()` | declare a dependency; rebuild on change |
| `ref.read` | **only** inside callbacks and event handlers | one-shot access; never creates a subscription |
| `ref.listen` | in `build()`, for side effects | react to a change with navigation, a snackbar, haptics |

```dart
class QuickEntryScreen extends ConsumerWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch + select: rebuild only when the digits change.
    final query = ref.watch(quickEntryVmProvider.select((s) => s.query));

    // listen: side effects, never in the returned widget tree.
    ref.listen(quickEntryVmProvider.select((s) => s.query), (prev, next) {
      if (prev != next) HapticFeedback.selectionClick();
    });

    return Scaffold(
      body: Column(
        children: [
          _QueryDisplay(query: query),
          const Expanded(child: _MatchList()),
          _Keypad(
            // read inside a callback — never watch here.
            onDigit: (d) => ref.read(quickEntryVmProvider.notifier).appendDigit(d),
            onBackspace: () => ref.read(quickEntryVmProvider.notifier).backspace(),
          ),
        ],
      ),
    );
  }
}
```

**Never `ref.watch` in a callback** — it creates a subscription per tap and is the classic Riverpod memory leak.
**Never `ref.read` in `build()`** — the widget will not update when the value changes, which at 3am shows a stale ewe.

### 4.6 Testing: overriding providers

The whole point of provider DI. No widget tree required:

```dart
test('lambing is timestamped from the injected clock, not DateTime.now()', () async {
  final fakeClock = FixedClock(DateTime.utc(2026, 3, 14, 3, 20));
  final db = await openInMemoryDatabase();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(fakeClock),
    ],
  );
  addTearDown(container.dispose);   // 2.6.1: do this yourself

  await container.read(quickEntryVmProvider.notifier).commitLambing(412, 2);

  final saved = await db.lastLambing();
  expect(saved.at, DateTime.utc(2026, 3, 14, 3, 20));
  expect(saved.timeSource, TimeSource.autoCaptured);   // spec §12.5
});
```

> In Riverpod 3.x this becomes `ProviderContainer.test(overrides: [...])`, which registers the teardown for you — that convenience is the entire reason for the `test` runtime dependency discussed in §1. On 2.6.1, `addTearDown(container.dispose)` is one extra line and costs nothing. Write a tiny local helper if you use it a lot.

Widget tests wrap in a scope:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: QuickEntryScreen()),
  ),
);
```

### 4.7 How this serves the 3am test and offline-only

- **Under 15 seconds.** The database is opened *before* `runApp`, so the first frame of the quick-entry screen already has the flock and the recents strip — no spinner, no empty state, no second tap. See §8.6.
- **Every write commits immediately.** `commitLambing` writes through to SQLite on the tap; the ViewModel holds no draft. If the phone dies mid-entry, nothing is lost because nothing was pending.
- **No network path.** Every dependency in §4.1 is local. The gateway interfaces make it structurally obvious in code review that nothing calls out.
- **Testable safety rules.** The injected `Clock` is what makes spec §12.5 ("timestamps are honest") provable rather than aspirational. Same pattern for withdrawal periods: the ViewModel must have no default value to inject.

---

## 5. Navigation: `go_router` is not earning its keep here

This is the recommendation most likely to raise eyebrows, since Flutter officially says go_router is *"the preferred way to write 90% of Flutter applications."* Shed Book is in the other 10%, and here is the argument.

### 5.1 What go_router is for

`go_router` 17.3.0, published 2026-06-02 by **flutter.dev** (first-party, `flutter/packages` monorepo), 3.5M monthly downloads. It is an excellent package. Its value proposition is **URL-based routing**: declarative route tables, deep links, web URL synchronisation, and a router that can reconstruct an arbitrary navigation stack from a string.

Now check that list against the spec:

| go_router's core value | Shed Book |
|---|---|
| Deep links (`shedbook://ewe/412`) | **Not in spec.** Nothing links into this app. |
| Web URL sync | **No web target.** iOS + Android only. |
| Browser back/forward | N/A |
| Reconstruct arbitrary stack from a URL | Only relevant for deep links / restoration — see §5.3 |
| Declarative route table | Nice-to-have |
| Nested/shell navigation for a persistent bottom bar | Genuinely useful **if** you use a bottom bar |

The first four are worth exactly nothing here. That is most of the package's reason to exist.

### 5.2 What it costs

**Real breaking-change churn.** From the go_router changelog: **15.0.0** made URLs case-sensitive (*"URLs are now case sensitive"*), **16.0.0** was a `GoRouteData` break requiring `go_router_builder >= 3.0.0`, **17.0.0** changed shell-route observer notification (*"ShellRoute's navigating changes notify GoRouter's observers by default"*). Three majors in roughly a year, all driven by URL/web semantics this app does not have. That is maintenance you pay for features you do not use.

**Loss of type safety without a second generator.** Plain `go_router` routes take `String` paths and `Map<String, String>` path parameters:

```dart
context.go('/ewe/${ewe.id}');                          // stringly-typed
final id = int.parse(state.pathParameters['id']!);     // parse + bang
```

Getting compile-time safety back means adding `go_router_builder`, i.e. another `build_runner` generator in the analyzer version-lock chain that already broke twice this year (§3).

Compare the imperative version, which is type-safe with no codegen:

```dart
Future<void> openEweCard(BuildContext context, int eweId) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EweCardScreen(eweId: eweId)),
  );
}
```

**The Android back button works identically.** This is the most common reason people reach for go_router, and it is a misconception. `Navigator.pop` is what the system back gesture drives in both cases; `WidgetsApp` wires the platform back button to the navigator regardless of which router you use. Predictive back is handled by `PopScope` (§5.4), which is framework-level and router-agnostic.

### 5.3 State restoration: go_router is actively *worse* here

This is the decisive point, and it cuts against the popular choice.

`go_router` documents state restoration ([go_router State restoration topic](https://pub.dev/documentation/go_router/latest/topics/State%20restoration-topic.html)): set `restorationScopeId` on `GoRouter` *and* `MaterialApp.router`, and supply a `pageBuilder` returning a page with a `restorationId` for every route. But two long-lived open bugs say it does not fully work:

- [flutter/flutter#117683 — "[go_router] Fail to restore widget states after 'restart and restore'"](https://github.com/flutter/flutter/issues/117683). **Open since 2022-12-27** — over three and a half years. A `ListView` scroll position restores correctly with plain `MaterialApp` and is **lost** with `go_router`, with identical restoration IDs. The issue notes the official go_router restoration example *"does not restore the state of the Pages, only the state of the GoRouter (e.g. the location)."*
- [flutter/flutter#174935 — "go_router: `RestorationScope` doesn't work inside a `ShellRoute`"](https://github.com/flutter/flutter/issues/174935). Open, filed 2025-09-04, labelled P2, reproducible on Flutter 3.35/3.36: restoration data is serialized but never deserialized; the page restarts from scratch.

The plain `Navigator` has first-class, framework-maintained restoration via `restorablePush`. Given that §6 is a real requirement for this app, adopting a router with a three-year-old open restoration bug to get deep-link features the app does not want is a bad trade.

### 5.4 Recommendation

**Use `MaterialApp` + the imperative `Navigator`,** with typed helper functions instead of string routes.

```dart
class ShedBookApp extends StatelessWidget {
  const ShedBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'shedbook',      // enables restoration — §6
      themeMode: ThemeMode.dark,           // dark is the default, not an option
      darkTheme: shedBookDarkTheme,
      theme: shedBookDarkTheme,            // never a light flash, even mid-boot
      home: const QuickEntryScreen(),      // the 3am screen IS the home screen
    );
  }
}
```

Typed navigation helpers, one per destination, in `lib/navigation.dart`:

```dart
Future<void> pushEweCard(BuildContext context, int eweId) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => EweCardScreen(eweId: eweId)));

Future<void> pushLambingEntry(BuildContext context, int eweId) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => LambingEntryScreen(eweId: eweId)));

/// Pen board -> ewe card -> lambing entry, then straight back to the board.
void popToPenBoard(BuildContext context) =>
    Navigator.of(context).popUntil((r) => r.isFirst);
```

This gives compile-time checked arguments, no codegen, no string paths, and no version churn.

**The pen board → ewe card → lambing entry stack** is a plain three-deep push stack. `Navigator.push` handles it; back unwinds it correctly; `popUntil` returns to the board after a save. There is nothing here a route table improves.

**Android predictive back.** Use `PopScope`, never the removed `WillPopScope`. Per [docs.flutter.dev/release/breaking-changes/android-predictive-back](https://docs.flutter.dev/release/breaking-changes/android-predictive-back), `canPop` must be decided *ahead of time*, because the back animation starts before the gesture is committed. Add `android:enableOnBackInvokedCallback="true"` to `AndroidManifest.xml`.

For Shed Book this is mostly a non-issue and that is by design: because **every write commits immediately**, there is no "discard unsaved changes?" dialog anywhere in the app. `canPop` is `true` everywhere. Back is always safe, always instant, never asks a question — which is exactly right for cold hands at 3am. The only candidate for `canPop: false` is the destructive "delete everything" flow in Settings.

**When to revisit:** if v2 adds a persistent bottom navigation bar with independent per-tab stacks, `StatefulShellRoute` becomes genuinely valuable and go_router earns its keep. Note the spec's 12 screens do not describe a bottom bar, and a bottom bar is questionable against the 60×60pt rule anyway.

**Dissenting note, recorded honestly:** Flutter's official recommendation is go_router, and a developer already fluent in it would not be wrong to use it — the ceremony is modest and the package is first-party and well maintained. The argument above is specifically that *for this app* it is unpaid overhead plus a restoration regression. If you adopt it anyway, set `restorationScopeId` on both `GoRouter` and `MaterialApp.router`, give every route an explicit `pageBuilder` with a `restorationId`, and **avoid `ShellRoute` entirely** until #174935 is fixed.

---

## 6. State restoration and process death

### 6.1 The scenario that matters

3:20am, ewe 412 lambs. The shepherd records it, pockets the phone, and deals with the lamb. 3:55am, ewe 128 starts. Between the two, Android may have killed the app to reclaim memory (very likely on a mid-range phone in a cold pocket with the camera having been used), or iOS may have suspended and terminated it.

The spec's requirement is **under 15 seconds from unlock to a saved lambing event**. A cold start that lands on the right screen with the flock loaded meets it. A cold start that shows a splash, then an empty list, then a spinner, does not.

### 6.2 What Flutter restores for free, and what it does not

Per [docs.flutter.dev/platform-integration/android/restore-state-android](https://docs.flutter.dev/platform-integration/android/restore-state-android):

> "Providing a `restorationScopeId` to `MaterialApp`, `CupertinoApp`, or `WidgetsApp` automatically enables state restoration by injecting a `RootRestorationScope`."

**Free once `restorationScopeId` is set** — provided each widget also gets a `restorationId`:
- `Scrollable` / `ListView` scroll offsets (`restorationId` on the scroll view)
- `TextField` text and selection (`restorationId` on the field)
- `TabBar` index, `PageView` page, expansion state of `ExpansionTile`
- The `Navigator` stack — **but only for routes pushed with `restorablePush`**

**Never restored, no matter what:**
- **All Riverpod provider state.** Providers are in-memory objects; a killed process takes them with it. There is no Riverpod feature that changes this. (Riverpod 3.x has an *experimental* offline-persistence feature, but the changelog is explicit: *"Anything imported with `package:riverpod/experimental/....dart` are not stable features. They may be modified in breaking ways without a major version."* It is aimed at caching network responses. **Do not use it** — this app's source of truth is SQLite, which is already durable.)
- Anything in a plain `State` field.
- Routes pushed with ordinary `Navigator.push`.

### 6.3 The insight that makes this cheap

**Because every write commits immediately to SQLite, there is almost nothing to restore.**

The spec's "assume the phone dies" rule (§5) is not just a durability guarantee — it is what collapses the restoration problem. Contrast with an app that keeps a half-filled lambing form in memory: that app must serialize a complex draft object through `RestorableProperty`, handle schema evolution of the restoration payload, and get it right or lose data.

Shed Book has no draft. After process death, everything the shepherd has actually recorded is on disk. What is genuinely worth restoring is a very short list:

| State | Restore? | Mechanism |
|---|---|---|
| Saved lambings, ewes, treatments | Already durable | SQLite |
| **Quick-entry keypad query** ("41" typed, not yet selected) | **Yes** | `RestorableString` |
| Flock list scroll offset | Yes | `restorationId` on the `ListView` |
| Current screen (deep in a stack) | **No — deliberately** | see below |
| Provider/ViewModel state | No | rebuilt from SQLite |

**Do not restore the navigation stack. Always cold-start to the quick-entry screen.** This is a deliberate product decision, not a shortcut. At 3am, after the phone was killed in a pocket, landing on the fastest path to a new record is *better* than landing wherever the user happened to be forty minutes ago — which is very likely a screen they were finished with. Restoring to a stale ewe card actively costs seconds and risks recording against the wrong animal. **Make the quick-entry screen the `home:` of `MaterialApp`** and the cold-start path is both the shortest and the correct one.

This also sidesteps `restorablePush` entirely, which is fortunate: per [api.flutter.dev — `Navigator.restorablePush`](https://api.flutter.dev/flutter/widgets/Navigator/restorablePush.html), the route builder must be a *static or top-level* function annotated `@pragma('vm:entry-point')`, and arguments must be serializable via `StandardMessageCodec`. That is a real constraint on how you write screens, and this app does not need to pay it.

### 6.4 Setup

**Dart:**

```dart
MaterialApp(
  restorationScopeId: 'shedbook',
  home: const QuickEntryScreen(),
  // ...
)
```

```dart
class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen>
    with RestorationMixin {
  final RestorableString _query = RestorableString('');

  @override
  String? get restorationId => 'quick_entry';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_query, 'query');
    // Push the restored value back into the ViewModel.
    if (_query.value.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(quickEntryVmProvider.notifier).setQuery(_query.value);
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();      // required — RestorableProperty is disposable
    super.dispose();
  }
}
```

Mirror ViewModel changes back into `_query.value` so the restoration payload stays current.

**iOS** requires a step that is easy to miss, from [api.flutter.dev — `RestorationManager`](https://api.flutter.dev/flutter/services/RestorationManager-class.html):

> "a restoration identifier has to be assigned to the `FlutterViewController`"

Open `ios/Runner.xcodeproj` → `Main.storyboard` → select the Flutter View Controller → Identity Inspector → enter a **Restoration ID**. Without this, iOS restoration silently does nothing.

**Android** needs no `MainActivity` changes.

### 6.5 Testing it — put this in the release checklist

Restoration bugs are invisible in normal development because the OS rarely kills a debug app.

- **Android:** enable Developer options → **"Don't keep activities"**, then background and return to the app. *Remember to turn it off afterwards.*
- **iOS:** run in **profile or release** mode (debug cannot relaunch from the home screen on iOS 14+), background the app, press **Stop** in Xcode, then reopen from the home screen — not from Xcode.

Test at minimum: type `41` on the keypad → background → kill → reopen → the digits are still there and the list is still filtered.

---

## 7. Rebuild cost on the quick-entry screen

The scenario: a giant numeric keypad filtering a 400-row flock list, one digit at a time, on a cold mid-range phone. Every keystroke must feel instant. Frame budget is 16ms at 60Hz, 8ms at 120Hz ([docs.flutter.dev/perf/best-practices](https://docs.flutter.dev/perf/best-practices)).

### 7.1 The rules that matter here

**1. Filter in the ViewModel, once per keystroke — never in `build()`.**
400 rows × a `where` + `toList` per rebuild is cheap in isolation but is pure waste, and it is the thing that will be executing during the frame you cannot afford. `QuickEntryState.matches` in §4.2 is computed exactly once per state transition.

**2. Split the widget tree so the keypad never rebuilds.**
> "Avoid overly large single widgets with a large `build()` function. Split them into different widgets based on encapsulation and how they change."

The keypad is 12 large buttons and is **completely static**. It must be a `const` widget outside the rebuild path. If the keypad rebuilds on every digit, you are rebuilding the most expensive part of the screen for no reason.

**3. `const` everywhere it is legal.**
> "Use `const` constructors on widgets as much as possible, since they allow Flutter to short-circuit most of the rebuild work."

**4. `.select` to narrow subscriptions.** The query display watches only `query`; the list watches only `matches`. Neither rebuilds when the other changes.

**5. `ListView.builder`, never `ListView(children: [...])`.**
> "When building a large grid or list, use the lazy builder methods, with callbacks. That ensures that only the visible portion of the screen is built at startup time."

**6. `itemExtent` on the list — this one is doubly worth it here.**
The 3am test mandates ≥60×60pt targets, so every row is a fixed, generous height anyway. Declaring it lets Flutter skip layout measurement per child and jump straight to a scroll offset. Flutter's docs warn specifically about the *intrinsic pass*:
> "For some widgets, particularly grids and lists, the layout process can be expensive… sometimes, a second pass (called an *intrinsic pass*) is needed, and that can slow performance."
Mitigation: *"set cells to a fixed size up front."* The design already does.

**7. Stable keys on rows.** `ValueKey(ewe.id)` so element and state are reused as the filter narrows, rather than rebuilt.

**8. Do not put `Opacity` or `saveLayer`-triggering widgets in list rows.** `Opacity`, `ShaderMask` and `ColorFilter` allocate an offscreen buffer:
> "Calling `saveLayer()` allocates an offscreen buffer and drawing content into the offscreen buffer might trigger a render target switch… On mobile GPUs this is particularly disruptive to rendering throughput."
For a dimmed/disabled row, draw with a semi-transparent colour instead.

**9. Do not override `operator ==` on widgets.** Flutter's docs are explicit that it causes O(N²) behaviour. Value equality belongs on the *state* classes, not the widgets.

### 7.2 The resulting structure

```dart
class QuickEntryScreen extends ConsumerWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Column(
        children: [
          _QueryDisplay(),   // watches .query only
          _RecentsStrip(),   // watches .recents only
          Expanded(child: _MatchList()),  // watches .matches only
          _Keypad(),         // const — watches NOTHING, never rebuilds
        ],
      ),
    );
  }
}

class _MatchList extends ConsumerWidget {
  const _MatchList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(quickEntryVmProvider.select((s) => s.matches));
    return ListView.builder(
      itemCount: matches.length,
      itemExtent: 72,                        // fixed height: skips intrinsic pass
      itemBuilder: (context, i) => _EweRow(
        key: ValueKey(matches[i].id),
        ewe: matches[i],
      ),
    );
  }
}
```

`_Keypad` takes no parameters and reaches the notifier through its own `Consumer`/`ref.read` internally, so it can stay `const` and is structurally incapable of rebuilding on keystrokes.

### 7.3 Sanity check on scale

400 ewes is small. A naive implementation would very likely hit 60fps anyway. The rules above are worth following not because 400 rows are slow, but because:
- the target hardware is a cheap phone, cold, possibly in a bag, possibly with the screen wet;
- `ListView.builder` + `itemExtent` + `const` cost nothing to write correctly the first time and are annoying to retrofit;
- the *perceived* latency budget for a keypad is far tighter than for a normal list, because the user is watching a specific number appear.

**Profile before optimising further.** Use DevTools 2.57.0 with a **profile-mode** build on a real low-end device — never the simulator, never debug mode. If it is fast there with a full 400-ewe database, stop.

---

## 8. Pitfalls

### 8.1 `.select` returning a fresh collection — silently defeats itself

**The bug.** Riverpod compares the selected value with `==`. Dart's `List` does **not** override `==`; it is identity comparison. I verified this with `dart run`:

```
List == is identity?              false
same instance compares equal?     true
two equal-content lists == ?      false
```

So this looks like an optimisation and is the opposite of one:

```dart
// BAD — `matches` is a getter that builds a new List every call.
class QuickEntryState {
  List<Ewe> get matches => all.where((e) => e.tag.contains(query)).toList();
}
ref.watch(quickEntryVmProvider.select((s) => s.matches));  // rebuilds ALWAYS
```

Every notifier change produces a new `List` instance, `==` is false, the widget rebuilds — plus you now run the filter on every comparison as well as every build. Strictly worse than not using `.select`.

**Mitigation.** Make derived collections **stored fields**, computed once in the constructor/factory (as in §4.2), so `.select` compares the same instance. Alternatively select a scalar proxy (`s.matches.length` plus `s.query`). Note this bites harder on Riverpod 3.x, where *"All providers now use `==` to compare previous/new values and filter updates."*

I made this exact mistake while drafting §4 and only caught it by testing the equality semantics. Assume it will happen again.

### 8.2 `ref.watch` inside a callback

Creates a new subscription on every tap; the provider is never released. Symptom: the app gets slower the longer the night goes on — the worst possible failure mode here. **Mitigation:** `ref.read` in callbacks, `ref.watch` only in `build`. Grep for `ref.watch` inside `onPressed`/`onTap` in review.

### 8.3 `family` arguments without value equality

`ref.watch(eweCardVmProvider(SomeArgsObject(...)))` where the argument type lacks `==`/`hashCode` creates a **new provider per rebuild** and leaks all of them. **Mitigation:** family arguments must be `int`, `String`, or a type with verified value equality. Prefer the primary key.

### 8.4 Forgetting a `ProviderScope` override

`databaseProvider` throws by default (§4.1). If a test or a secondary entry point forgets the override, it crashes. That is intended — but make the message say what to override, as shown.

### 8.5 Riverpod state assumed to survive process death

Nothing in a provider survives an Android low-memory kill. **Mitigation:** the "commit every write immediately" rule already covers this; treat any provider state that would hurt to lose as a bug in the write path, not a restoration problem.

### 8.6 A loading spinner on the 3am screen

A `FutureProvider`/`AsyncNotifier` on the quick-entry screen means the first frame is `AsyncLoading`, and the shepherd sees a spinner instead of the flock. That is a direct hit on the 15-second requirement and on "no white flash on launch."

**Mitigations, in order of preference:**
1. Open the database *before* `runApp` and inject the ready instance (§4.1). The first frame has data.
2. Where async is unavoidable, render the *previous* data during refresh rather than a spinner. In `AsyncValue`, prefer `switch` with `AsyncData` first and fall through to `SizedBox.shrink()` rather than `CircularProgressIndicator` — an empty region reads better in a head torch than a spinning white ring.
3. Never full-screen-spinner a screen that already has data.

### 8.7 The launch white flash

Not strictly a state-management issue, but it interacts with the app's entry point: the native launch screen must be dark on **both** platforms (`android/app/src/main/res/values/styles.xml` **and** `values-night/`, plus `LaunchScreen.storyboard` on iOS). Also set `MaterialApp.theme` (not only `darkTheme`) to the dark theme so a device in light mode never flashes white between the native splash and the first Flutter frame. Verify on a physical device with `themeMode: ThemeMode.dark` *and* the system in light mode.

### 8.8 `dependency_overrides` creeping in

If a future change forces `dependency_overrides` into `pubspec.yaml`, treat it as a defect to be paid down, not a solution. Record the reason inline. It silences pub's compatibility checking for that package permanently and across all future upgrades.

### 8.9 Using `StateProvider` or `StateNotifierProvider`

Both are legacy and were moved to `legacy.dart` in Riverpod 3.0.0. Even on 2.6.1, **do not use them** — you would be writing 2026 code against an API already retired in the next major, and creating migration work for no benefit. Use `Notifier`/`NotifierProvider` exclusively. Likewise avoid `AsyncValue.valueOrNull` (removed in 3.x in favour of `.value`).

### 8.10 `flutter pub upgrade` breaking the build silently

Given §1 and §3, an unconstrained upgrade can pull in an unresolvable or subtly downgraded toolchain. **Mitigation:** commit `pubspec.lock`, pin `flutter_riverpod` exactly, and run `flutter pub outdated` deliberately rather than `flutter pub upgrade` reflexively. Re-read this document before any dependency bump.

---

## 9. Rejected alternatives

| Rejected | Why it lost |
|---|---|
| **`flutter_riverpod` 3.4.1** | Only state option tested that makes `flutter pub get` **fail** on this app's real stack (Drift + drift_dev + build_runner). Cause is the `test` runtime dependency, which the maintainer has declined to change ([#4791](https://github.com/rrousselGit/riverpod/issues/4791), closed 2026-06-23). Workarounds (`any` constraints, `dependency_overrides`) impose a permanent tax and silently held `drift_dev` back to 2.34.0. Author signals 4.0.0 "relatively soon". **Note it was *not* rejected for introducing a network path — verified it does not.** |
| **`riverpod_generator` + `riverpod_annotation`** | Latest (4.0.6, 2026-07-26) is **unresolvable in any project** — declares `analyzer ^13.0.0` while pinning `riverpod_analyzer_utils 1.0.0-dev.10` which needs `analyzer ^12.0.0`. Fallback requires pinning five packages a generation behind. Saves ~1 line per provider on ~15 providers. Build time was *not* the reason (measured: 16.5s cold / 0.7s warm). |
| **`riverpod_lint`** | Same self-contradictory constraints at 3.1.6. Revisit once resolvable; its 3.1.0 move off `custom_lint` to `analysis_server_plugin` is a genuine improvement. |
| **`custom_lint`** | 0.8.1 (2025-09-09) still requires `analyzer ^8.0.0`; conflicts with the whole current toolchain. Not needed now that `riverpod_lint` dropped it. |
| **`hooks_riverpod`** | Adds `flutter_hooks` plus a second mental model (hook ordering rules) for no benefit on 12 simple screens. Carries the same `flutter_test` runtime dep at 3.x. |
| **`flutter_bloc`** | Excellent, 160/160 pub points, resolves cleanly. Lost on ceremony-per-screen: event + state + bloc classes × 12 screens to express "user typed a digit" against a local database. Bloc's discipline pays off on teams and complex async; this is one developer and SQLite. Legitimate second choice if you want maximum structure. |
| **`signals`** | Technically the most elegant, 160/160 pub points. Lost on ecosystem depth: **19k monthly downloads vs Riverpod's 2.5M**. For a solo dev with a 5-year horizon and no colleagues to ask, ecosystem size is risk management. |
| **`provider` + `ChangeNotifier`** | Flutter's *official* recommendation, and the honest runner-up — smallest dependency, zero new concepts. Lost because DI is `BuildContext`-scoped (awkward for export/notification/stats code that has no widget), `ChangeNotifier` is mutable (fighting Flutter's own "use immutable data models"), and test overrides need a widget tree. Choose it if Riverpod's concepts prove to be friction in week one. |
| **`get_it`** | Resolves cleanly and is widely used, but it is a **global service locator** — precisely the "globally accessible objects" that Flutter's own DI guidance says to avoid ("Dependency injection prevents your app from having globally accessible objects, which makes your code less error prone"). Riverpod already provides DI; adding `get_it` means two DI systems. |
| **`go_router`** | First-party, excellent, officially recommended — but its core value is URL routing, deep links and web, all of which this app explicitly does not have. Costs: three breaking majors in ~a year driven by URL semantics; stringly-typed args without a second generator; and **[flutter/flutter#117683](https://github.com/flutter/flutter/issues/117683) open since 2022** — restores router location but not page state, which directly undermines §6. |
| **`go_router_builder`** | Only exists to fix go_router's stringly-typed arguments; adds another generator to the analyzer version-lock chain. Moot once go_router is rejected. |
| **`freezed`** | Flutter recommends it but warns it "can add significant build time… if you have a lot of models." This app has ~8 entities and a handful of view states; hand-written `@immutable` classes with `copyWith` are ~15 lines each and add zero toolchain risk. Reconsider only if the model count grows a lot. |
| **`Navigator.restorablePush`** | Requires static/top-level `@pragma('vm:entry-point')` route builders and `StandardMessageCodec`-serializable arguments. Unnecessary once the app deliberately cold-starts to quick entry (§6.3). |
| **Riverpod 3.x experimental offline persistence** | Changelog explicitly warns experimental APIs "may be modified in breaking ways without a major version." Aimed at caching network responses. SQLite is already the durable source of truth. |
| **`StateProvider` / `StateNotifierProvider`** | Legacy; moved to `legacy.dart` in 3.0.0. Would create migration work immediately. |
| **`ProviderObserver` for analytics** | No analytics in this app, by design. Useful only as a debug-mode logger; keep it out of release builds. |

---

## 10. Concrete `pubspec.yaml` for this area

```yaml
environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter

  # State management + DI.
  # PINNED EXACTLY to 2.6.1 — do NOT bump to 3.x without re-reading
  # docs/research/raw/02-state-and-navigation.md §1.
  # 3.x declares `test` as a RUNTIME dependency, which makes `flutter pub get`
  # fail against this project's drift_dev + build_runner toolchain.
  flutter_riverpod: 2.6.1

  # NO go_router — see §5. Navigation is the imperative Navigator.

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  # build_runner is present for Drift only — no riverpod_generator (§3).
```

Verified: this resolves cleanly on Flutter 3.44.6 alongside `drift ^2.34.2`, `drift_dev ^2.34.5`, `sqlite3_flutter_libs`, `path_provider`, `flutter_local_notifications ^22.2.0` and `share_plus ^13.3.0` — 117 packages, no `test`, no `coverage`, no `webkit_inspection_protocol`, no `dependency_overrides`.

> `web_socket_channel` and `shelf` *do* still appear in the lock file in that configuration — but via `build_runner`, which is a `dev_dependency` of **this** app and therefore never ships. That is a categorically different thing from a package pulling them into `dependencies:`, and it is the same for every Flutter app that uses any code generator.

**Release checklist item:** after `flutter build apk --release`, confirm
`aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk`
prints no `android.permission.INTERNET`.

---

## 11. Open questions

1. **Bottom navigation bar or not?** The spec's 12 screens do not describe one. If v2 adds one with independent per-tab stacks, revisit `go_router`'s `StatefulShellRoute` (§5.4) — though a bottom bar is in tension with the 60×60pt rule.
2. **Does the restored keypad query actually help?** §6.3 assumes restoring partially-typed digits is worth it. Worth checking in the shed observation (spec §17.1): the shepherd may simply retype two digits without noticing. If so, drop `RestorationMixin` entirely and rely on cold-starting to quick entry.
3. **Riverpod 4.0.0 timing.** The author flagged it as coming "relatively soon" in the 3.0.0 changelog (2025-04-30). If it lands during development *and* resolves the `test` dependency, re-evaluate — a 2.6.1 → 4.x jump may be cheaper than 2.6.1 → 3.x → 4.x.
4. **Free-tier cap enforcement location.** The ~15-ewe cap must not degrade the 3am path (spec §14). It should be enforced in the write path (the ViewModel command), never as a gate on the quick-entry screen render. Needs a decision alongside the purchase-flow research.
5. **`sqlite3_flutter_libs` 0.6.0+eol** carries an `+eol` build tag on pub.dev. Out of scope here, but flag it to whoever owns the persistence research.

---

## 12. Sources

Every URL below was actually fetched on 2026-07-27.

**pub.dev package pages and API**
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/riverpod
- https://pub.dev/packages/flutter_riverpod/changelog
- https://pub.dev/packages/riverpod_lint/changelog
- https://pub.dev/packages/go_router/changelog
- https://pub.dev/packages/signals
- https://pub.dev/documentation/go_router/latest/topics/State%20restoration-topic.html
- `https://pub.dev/api/packages/{riverpod, flutter_riverpod, hooks_riverpod, riverpod_annotation, riverpod_generator, riverpod_lint, riverpod_analyzer_utils, provider, go_router, get_it, bloc, flutter_bloc, signals, signals_flutter, freezed, state_notifier, custom_lint, build_runner, test, test_core, listen, drift, drift_dev, sqlite3_flutter_libs, flutter_local_notifications, share_plus}` — authoritative pubspec/version/publisher data
- `https://pub.dev/api/packages/{...}/score` — likes, pub points, download counts
- `https://pub.dev/api/archives/riverpod-3.4.1.tar.gz`, `test-1.31.2.tar.gz` — package sources inspected directly

**Riverpod repository**
- https://github.com/rrousselGit/riverpod/issues/4791 (+ GitHub API for full comment thread — maintainer's verbatim position)
- https://github.com/rrousselGit/riverpod/issues/4639
- https://github.com/rrousselGit/riverpod/issues/4364
- https://github.com/rrousselGit/riverpod/issues/4308
- https://riverpod.dev/docs/whats_new
- https://riverpod.dev/docs/migration/from_state_notifier

**Flutter official documentation**
- https://docs.flutter.dev/app-architecture/guide
- https://docs.flutter.dev/app-architecture/recommendations
- https://docs.flutter.dev/app-architecture/case-study/dependency-injection
- https://docs.flutter.dev/data-and-backend/state-mgmt/options
- https://docs.flutter.dev/perf/best-practices
- https://docs.flutter.dev/platform-integration/android/restore-state-android
- https://docs.flutter.dev/platform-integration/ios/restore-state-ios
- https://docs.flutter.dev/release/breaking-changes/android-predictive-back
- https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html
- https://api.flutter.dev/flutter/services/RestorationManager-class.html
- https://api.flutter.dev/flutter/widgets/Navigator/restorablePush.html

**Flutter / go_router issue tracker**
- https://github.com/flutter/flutter/issues/117683
- https://github.com/flutter/flutter/issues/174935

**Locally reproduced evidence (Flutter 3.44.6 / Dart 3.12.2, macOS arm64)**
- `flutter pub get` resolution matrices across riverpod 2.6.1 / 3.4.1 and every alternative package, on both a minimal pubspec and this app's real stack
- `flutter build apk --release` + `aapt2 dump permissions` on a riverpod-3.4.1 app — manifest permission audit
- `strings libapp.so` symbol scan of the release arm64 binary — tree-shaking verification
- `flutter analyze` on every Dart snippet in §4 — "No issues found!"
- `dart run build_runner build` cold/warm timing
- `dart` program confirming `List` `==` identity semantics behind the `.select` pitfall
