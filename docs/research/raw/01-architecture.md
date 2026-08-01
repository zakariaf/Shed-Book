# 01 — App Architecture & Layering (Shed Book)

> Research notes, single-developer greenfield offline-only Flutter app.
> Target toolchain: **Flutter 3.44.6 stable, Dart 3.12.2**, Xcode 26.6, Android SDK, macOS arm64.
> Researched **2026-07-27**. Every package version below was read off its live pub.dev page on that date.
> Judged against `shed-book-spec.md` (12 screens §9, 8 entities §10, the 3am test §5, safety rules §12).

---

## Bottom line

| # | Decision | Call | Confidence |
|---|---|---|---|
| 1 | Overall shape | Flutter's official **MVVM two-layer** (UI + Data), with the **domain layer as plain functions, not use-case classes** | High |
| 2 | Flutter's `offline-first` design pattern page | **Do not follow it.** It is a cache-over-network pattern; every mechanism it prescribes (sync flags, `Timer.periodic`, `workmanager`, `connectivity_plus`, FCM) is dead weight or a banned network path here | High |
| 3 | Folder layout | **Feature-first UI, shared data + domain** — i.e. the Compass App layout Flutter itself ships. Not pure feature-first | High |
| 4 | Separate pure-Dart domain package | **No, not for v1.** Single package. A 60-line `tool/check_layers.dart` enforces 8 rules; a package boundary enforces 1 | Medium-high |
| 5 | Pub workspace / melos | **Never for this app.** Melos 8 delegates to pub workspaces anyway; with 1 package there is nothing to orchestrate | High |
| 6 | Source of truth | The **SQLite file**. One `AppDatabase`, one repository per aggregate, repositories are the only writers | High |
| 7 | Read path | **drift `watch()` streams. One query per screen.** Never `combineLatest` two drift streams (torn state — maintainer-confirmed) | High |
| 8 | Write path | Repository methods are **event verbs, not `save(aggregate)`**. Draft state is made *unrepresentable*, not merely discouraged | High |
| 9 | State mgmt / DI | **Riverpod 3.4.1** for DI + stream binding, with `retry: (_, __) => null` on the root scope (non-negotiable). Diverges from Flutter's `provider` recommendation — argued below | Medium |
| 10 | Codegen | **drift only.** No `freezed`, no `riverpod_generator`, no `json_serializable` for entities | High |
| 11 | Routing | **Navigator 1.0** + a static route-helper file. Not `go_router` — no URLs, no deep links, and 3 major versions in 24 months | Medium |
| 12 | Error handling | **Exceptions on reads, a sealed `WriteOutcome` on writes.** `Result<T>` everywhere is disproportionate here | Medium-high |
| 13 | Global error net | `FlutterError.onError` + `PlatformDispatcher.instance.onError` + a dark `ErrorWidget.builder`, all writing to a **local ring-buffer file**. **No Crashlytics, no Sentry** — that is a network path | High |
| 14 | Derived state | **Store what was observed or typed; compute what is inferred.** Aggregates → SQL views. Time-relative values → computed at render from `clock.now()`. One exception: withdrawal `clear_date` is stored because it is *what the user was told* | High |
| 15 | Dependency enforcement | A **dependency-free Dart script in `tool/`** run in CI + pre-push. Not an analyzer plugin (`dart_code_metrics` is discontinued/commercial; `custom_lint` is at 0.8.1/60 points) | High |
| 16 | Offline enforcement | **Allowlist `pubspec.lock` in CI** + assert the merged release `AndroidManifest.xml` contains no `INTERNET` | High |
| 17 | Testing | **Real in-memory SQLite (`NativeDatabase.memory()`), not mocks.** Therefore **no abstract repository interfaces** — contradicting Flutter's "strongly recommend" | Medium-high |
| 18 | Bootstrap | **Do not `await` anything in `main()`.** `ensureInitialized()` before `runApp()` tears the native splash down early → the flash the spec forbids | Medium |

---

## 0. Scope note

This document is about *shape*: which classes exist, which may import which, who owns writes, where computation lives, and what CI can prove. It deliberately does not settle DB schema details, theming, notification scheduling internals, or export formats — those are separate topics. Where a decision here constrains those topics, it is flagged.

---

## 1. What Flutter officially prescribes in 2026

I read the whole guide rather than trusting memory. Here is what it actually says.

### 1.1 The layers

[Common architecture concepts](https://docs.flutter.dev/app-architecture/concepts) defines two mandatory layers and one optional one:

- **UI layer** — displays data, handles interaction.
- **Logic/Domain layer** — *optional*.
- **Data layer** — manages data sources.

And the constraint: *"Each layer can only communicate with the layers directly below or above it. The UI layer shouldn't know that the data layer exists, and vice versa."*

Crucially, the same page pre-authorises skipping the domain layer:

> "The logic layer is optional, and only needs to be implemented if your application has complex business logic that happens on the client. Many apps are only concerned with presenting data to a user and allowing the user to change that data (colloquially known as CRUD apps). These apps might not need this optional layer."

### 1.2 The four component types

From the [Guide to app architecture](https://docs.flutter.dev/app-architecture/guide):

| Component | Official definition | Applies to Shed Book? |
|---|---|---|
| **View** | *"the widget classes of your application… shouldn't contain any business logic"* — 1:1 with a ViewModel | Yes |
| **ViewModel** | Holds most business logic; retrieves from repositories, transforms for presentation, keeps state, exposes **Commands** | Yes, thinner than usual |
| **Repository** | *"the source of truth for your model data"*; caching, error handling, retry, refreshing, polling. **"Repositories should never be aware of each other."** | Yes — but caching/retry/refresh/polling all evaporate |
| **Service** | *"They wrap API endpoints and expose asynchronous response objects"*; *"one service class per data source"*; hold no state | **Mostly collapses** — see §2 |

Dependency direction: `View → ViewModel → (optional use-case) → Repository → Service`.

### 1.3 The recommendations table

[Recommendations](https://docs.flutter.dev/app-architecture/recommendations), verbatim priorities:

- **Strongly recommend**: clearly defined data + UI layers; repository pattern; ViewModels and Views (MVVM); no logic in widgets; unidirectional data flow; immutable data models; dependency injection; **abstract repository classes**; test components separately and together; make fakes.
- **Recommend**: `Commands` for user-interaction events; `freezed`/`built_value`; `go_router`; standardised naming.
- **Conditional**: `ChangeNotifier`/`Listenable`; a domain layer; separate API and domain models.

I dispute exactly two of these for this app — **abstract repository classes** (§10.2) and **`freezed`** (§10.1) — and one "Recommend" (`go_router`, §7.3). Everything else stands.

### 1.4 The offline-first page is not about this app

This is the single most important finding in this section.

[Design patterns → Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) is titled as if it were written for Shed Book. It is not. Its `UserProfileRepository` composes an `ApiClientService` (HTTP) with a `DatabaseService` (SQL). Every mechanism on the page exists to reconcile the two:

- Reading strategies: "local fallback", "stream-based" (`yield` local, then `yield` remote), "local-only with manual `sync()`".
- Writing strategies: "online-only (safest)" vs "offline-first (more permissive)".
- A `synchronized` boolean flag on the model.
- `Timer.periodic(const Duration(minutes: 5), (timer) => sync())`.
- Recommended packages: [`workmanager`](https://pub.dev/packages/workmanager), [`connectivity_plus`](https://pub.dev/packages/connectivity_plus), [`battery_plus`](https://pub.dev/packages/battery_plus), Firebase Cloud Messaging.
- Caveats about battery drain, data conflicts, and sync frequency.

**Every one of those is either a no-op or a violation here.** Shed Book has no remote source, so there is no divergence to reconcile, no `synchronized` flag, no sync timer, no connectivity check, and — decisively — no reason to link a package that can open a socket. Spec §4 and §13 make this a product property, not a preference.

The correct reading of that page for this project is: **"offline-first" in Flutter's vocabulary means "networked app that degrades gracefully". Shed Book is *offline-only*, which is a different and much simpler architecture.** Where a Flutter blog post or the docs say "offline-first", mentally substitute "sync engine" and then delete it.

> **3am / offline-only note.** This is not pedantry. An engineer following that page in good faith would add `connectivity_plus` to `pubspec.yaml`, which merges `ACCESS_NETWORK_STATE` into the Android manifest and puts a platform channel in the app that exists solely to ask about a network the app must never use. The CI gate in §12.2 exists to catch exactly this.

---

## 2. How MVVM degenerates when there is no remote data source

Walk the official responsibilities and mark each one dead or alive.

### 2.1 What dies

| Official responsibility | Fate here | Why |
|---|---|---|
| Repository **caching** | Dead | SQLite *is* the cache. A second in-memory cache is a second source of truth and therefore a bug factory. |
| Repository **retry logic** | Dead, and actively harmful | Disk-full and corrupt-DB do not heal on retry. See the Riverpod auto-retry footgun, §8.3. |
| Repository **refreshing / polling** | Dead | Nothing upstream changes. The only writer is this app. |
| **Service** layer for data | Almost entirely dead | Flutter defines a service as an API-endpoint wrapper. `AppDatabase` (drift) already *is* the data source wrapper, and it is generated. Writing a hand-rolled `DatabaseService` on top of drift adds a layer that only forwards. |
| **API models** separate from **domain models** | Dead | Flutter marks this "Conditional"; the condition is a wire format you do not control. You own the schema. |
| **Loading states** on reads | Nearly dead | A local indexed query over ≤400 ewes returns in single-digit milliseconds. A `CircularProgressIndicator` for a local read is a 3am-test failure, not a nicety. |
| Repository **error handling** as a first-class concern per call | Demoted | ~100% of calls succeed. See §9. |
| `Result<T>` on **every** method | Dead | Disproportionate. See §9.1. |

### 2.2 What survives, and gets *more* important

| Responsibility | Why it survives |
|---|---|
| **Single source of truth** | Still the whole game. With 8 entities and cross-cutting reads (Export touches all 8), one owner per table is what stops the season summary disagreeing with the ewe card. |
| **Unidirectional data flow** | Survives *strengthened*: with drift streams, UDF is enforced by the database rather than by convention. A write goes down; a table-change notification comes back up. There is no path that skips the DB. |
| **Repository as the only writer** | The spec's "every write commits immediately" (§5) is only checkable if there is exactly one place that writes. |
| **ViewModel exists to keep logic out of widgets** | Still true, and cheap. |
| **Commands** | Survive for a *non-obvious* reason: not loading spinners, but **double-tap protection**. Cold fingers on a wet capacitive screen double-fire. A double-fired lambing insert is a duplicate record nobody notices until March. See §8.5. |
| **Immutable models** | Free — drift generates immutable row classes with `==`, `hashCode`, `copyWith` ([drift: generated rows](https://drift.simonbinder.eu/dart_api/rows/)). |
| **DI** | Survives, but as graph wiring, not as swappability. |

### 2.3 Services do not vanish entirely

Three real services remain, and they are all *platform* services, not data services — which is consistent with Flutter's own definition ("the underlying platform (iOS and Android APIs)… local files"):

1. `NotificationScheduler` — wraps `flutter_local_notifications`.
2. `MediaStore` — writes photos/voice notes to the app's media folder, returns relative paths.
3. `ShareService` — hands a file to the system share sheet (the only export route, spec §7.9).

All three are *side-effecting* and *non-transactional*, which is why they belong behind repositories rather than being called from ViewModels: scheduling a "colostrum window" reminder must happen in the same repository call that inserts the lambing, so there is never a lambing without its reminder.

### 2.4 The resulting shape

```
View  (widgets, zero logic)
  │  reads: ref.watch(<screen>Provider)  →  AsyncValue<ScreenModel>
  │  writes: ref.read(<screen>WriteProvider.notifier).penEwe(...)
  ▼
ViewModel / Controller  (Riverpod Notifier or StreamProvider)
  │  presentation shaping only; no SQL, no drift types
  ▼
Repository  (the only writer; owns transactions)
  │  ├─→ AppDatabase (drift)   ← the source of truth
  │  ├─→ NotificationScheduler (platform service)
  │  └─→ MediaStore            (platform service)
  ▼
domain/  (pure functions — imported by repositories AND by view models)
```

Note the domain sits *beside* rather than *between*. That is Flutter's own "plated dinner, not lasagna" framing from the guide: *"Use-cases are just utility classes that have well-defined inputs and outputs."* Here they are literally top-level functions, not classes — see §5.

---

## 3. Folder layout: feature-first vs layer-first

### 3.1 The debate, honestly

The community's best-argued position is [Andrea Bizzotto's "Flutter Project Structure: Feature-first or Layer-first?"](https://codewithandrea.com/articles/flutter-project-structure/) (published 2022-03-23 — a *lead*, not evidence). Its two claims survive scrutiny:

1. **Layer-first scatters a feature.** Editing "foster a lamb" means touching `presentation/foster/`, `application/foster/`, `domain/`, `data/`. Constant jumping; deleting a feature leaves orphans.
2. **Feature-first fails when "feature" is read as "screen".** You get a bloated presentation layer and a `shared/` dumping ground underneath.

Flutter's own [Compass App case study](https://docs.flutter.dev/app-architecture/case-study) resolves this with a hybrid, and states the rationale explicitly:

> "The `data` folder organizes code by type, because repositories and services can be used across different features and by multiple view models. The `ui` folder organizes the code by feature, because each feature has exactly one view and exactly one view model."

### 3.2 The call for Shed Book: feature-first UI, shared data + domain

Defence, specific to this app:

- **Nobody owns `Ewe`.** Under pure feature-first you must decide whether `Ewe` lives in `features/flock/data/`. Quick Entry reads it, Lambing writes to it, Pen Board joins it, Treatments references it, Export dumps it. Any answer is arbitrary, and the wrong answer produces cross-feature imports — the exact dependency-direction violation §11 exists to forbid.
- **Export is the proof.** `features/export/` must read all 8 entities. Under pure feature-first it would import from 8 sibling features. Under the hybrid it imports 8 repositories, which is fine and expected.
- **8 entities vs 9 features is a near-1:1 ratio.** Feature-siloing the data layer at this ratio produces one repository per folder plus a `shared/` folder for the six repositories that are actually shared. That is layer-first wearing a costume.
- **A single developer never has merge conflicts.** The strongest argument for pure feature-first — parallel work by many developers on disjoint folders — does not apply. Spec framing: one person, greenfield.

### 3.3 Feature ≠ screen

Following Andrea's correction, features are **functional requirements**, so the 12 screens (spec §9) collapse into 9 features:

| Feature folder | Screens it owns (spec §9) |
|---|---|
| `quick_entry` | 3. Quick Entry |
| `flock` | 1. Flock, 2. Ewe Card |
| `lambing` | 4. Lambing Entry, 5. Lamb Card, 6. Foster |
| `pens` | 7. Pen Board |
| `treatments` | 8. Treatments |
| `reminders` | 9. Reminders |
| `season` | 10. Season Summary |
| `export` | 11. Export |
| `settings` | 12. Settings |

Lamb Card and Foster live with Lambing because they share the birth-dam/rearing-dam invariant. Splitting them would put that invariant in two places.

### 3.4 The concrete tree

```
shed_book/
├── pubspec.yaml
├── analysis_options.yaml            # include: package:flutter_lints/flutter.yaml
├── build.yaml                       # drift options (see §6.4, §14.2)
├── drift_schemas/                   # exported schema snapshots (generated)
├── tool/
│   ├── check_layers.dart            # §11.3 — dependency direction gate
│   └── check_offline.dart           # §12.2 — dependency allowlist gate
├── lib/
│   ├── main.dart                    # ~15 lines. See §13.
│   ├── app.dart                     # MaterialApp, dark-by-default theme
│   │
│   ├── domain/                      # L0 — PURE DART. No flutter, no drift.
│   │   ├── ids.dart                 # extension types over int: EweId, LambingId…
│   │   ├── birth_type.dart          # enum single/twin/triplet/quad/more (+ expectedLambs)
│   │   ├── lambing_ease.dart        # enum 1..5 + the 5 authored descriptions (spec §11)
│   │   ├── death_cause.dart         # the editable short list (spec §7.3)
│   │   ├── withdrawal.dart          # clearDate(), daysRemaining(), isClear()
│   │   ├── penning.dart             # timeSincePenned(), isReadyToTurnOut()
│   │   ├── season_stats.dart        # lambingPercentage(), litterStats(), lossBreakdown()
│   │   ├── consistency.dart         # spec §12.4 flags — never auto-corrections
│   │   └── terminology.dart         # ewe/gimmer/shearling/theave/hogget mapping
│   │
│   ├── core/                        # L1 — cross-cutting, knows no feature
│   │   ├── db/
│   │   │   ├── database.dart        # @DriftDatabase(tables: [...], views: [...])
│   │   │   ├── database.g.dart      # generated
│   │   │   ├── database.steps.dart  # generated step-by-step migrations
│   │   │   ├── tables/              # 8 files, one per entity (spec §10)
│   │   │   ├── views/               # v_ewe_season.dart, v_season_totals.dart …
│   │   │   └── converters/          # TypeConverters (enums, Instant)
│   │   ├── time/app_clock.dart      # re-exports package:clock; see §10.5
│   │   ├── log/local_log.dart       # capped on-device ring buffer. NEVER a network sink.
│   │   ├── failure.dart             # sealed ShedFailure
│   │   ├── write_outcome.dart       # sealed WriteOutcome (§9.2)
│   │   └── ui/                      # theme, night/red-shift, BigButton, TapTarget, formatters
│   │
│   ├── data/                        # L2 — the ONLY code that writes
│   │   ├── models.dart              # export 'package:shed_book/core/db/database.dart' show Ewe, Lamb…
│   │   ├── flock_repository.dart
│   │   ├── lambing_repository.dart
│   │   ├── pen_repository.dart
│   │   ├── treatment_repository.dart
│   │   ├── reminder_repository.dart
│   │   ├── season_repository.dart
│   │   ├── settings_repository.dart
│   │   ├── export_repository.dart
│   │   ├── notification_scheduler.dart   # service
│   │   ├── media_store.dart              # service
│   │   └── providers.dart                # the DI graph: db, repos, services
│   │
│   ├── features/                    # L3 — UI, feature-first, siblings never import siblings
│   │   ├── quick_entry/
│   │   │   ├── quick_entry_screen.dart
│   │   │   ├── quick_entry_controller.dart
│   │   │   └── widgets/{big_keypad.dart, recents_strip.dart, in_pens_strip.dart}
│   │   ├── flock/
│   │   │   ├── flock_screen.dart · flock_controller.dart
│   │   │   ├── ewe_card_screen.dart · ewe_card_controller.dart
│   │   │   └── widgets/{ewe_summary_line.dart, flock_filter_bar.dart}
│   │   ├── lambing/
│   │   │   ├── lambing_entry_screen.dart · lambing_entry_controller.dart
│   │   │   ├── lamb_card_screen.dart · lamb_card_controller.dart
│   │   │   ├── foster_screen.dart · foster_controller.dart
│   │   │   └── widgets/{ease_row.dart, birth_type_row.dart, care_checks.dart}
│   │   ├── pens/ · treatments/ · reminders/ · season/ · export/ · settings/
│   │   │
│   │   └── (each: <name>_screen.dart, <name>_controller.dart, widgets/)
│   │
│   └── routing/
│       └── routes.dart              # static push helpers (§7.3)
│
├── test/
│   ├── domain/                      # pure unit tests, fastest tier
│   ├── data/                        # against NativeDatabase.memory()
│   ├── drift/                       # GENERATED migration tests
│   └── features/                    # widget tests, incl. the commit-on-first-tap tests (§8.4)
└── integration_test/
```

Two structural details worth defending:

- **`data/models.dart` re-export.** drift generates the row classes inside `core/db/database.dart`. Letting `features/` import that file would expose `AppDatabase`, `Value`, companions, and the whole query builder to the UI. Instead, one file re-exports only the row types:
  ```dart
  // lib/data/models.dart
  export 'package:shed_book/core/db/database.dart'
      show Ewe, Lambing, Lamb, Pen, Treatment, Reminder, Note, Season;
  ```
  Now the enforceable rule is trivially greppable: **`lib/features/**` may not import `core/db/` or `package:drift/`.**
- **No `lib/src/`.** It is a package-authoring convention whose only real payoff (`implementation_imports` blocking other packages) is irrelevant to an application binary. Skipping it shortens every path. Adopt it only if you later extract packages (§4).

> **3am note.** Feature-first pays off in the one situation that matters for this app: you are about to redesign the Quick Entry screen for the fifth time because the freezer-bag test failed. Everything you need is in one folder and nothing outside it changes.

---

## 4. Is a separate pure-Dart domain package worth it?

The candidates for extraction are exactly the things in `lib/domain/`: season statistics, lambing percentage, withdrawal-date math, "hours since penned", consistency flags. Perhaps 400–700 lines total.

### 4.1 The real arguments for extracting

1. **Analyzer-time enforcement.** A package that does not declare `flutter` or `drift` in its `pubspec.yaml` *cannot compile* if someone imports them. That is stronger feedback than CI: it is red squiggles while typing. Given spec §12.1 (never default a withdrawal period) and §12.2 (never give veterinary advice), the withdrawal math is safety-relevant code and keeping it pure has real value.
2. **Test tier speed.** A pure-Dart package's tests run under `dart test` on the VM instead of `flutter test`, which does not need to construct a Flutter binding.
3. **Codegen isolation.** The domain package has no builders, so its sources are never dragged through drift's build graph. This matters more than it sounds: [dart-lang/build#3555](https://github.com/dart-lang/build/issues/3555), opened by build maintainer Jake MacKenzie, says of build_runner's incremental model: *"basically any time a builder runs on a file it establishes a dependency on all files transitively imported by that file, which is O(N), and there is probably a fairly high constant multiplier as well. So you end up with O(N^2) complexity."*

### 4.2 The argument I checked and had to discard

I assumed hot reload degrades across package boundaries. **It does not, as far as Flutter documents.** The [hot reload limitations list](https://docs.flutter.dev/tools/hot-reload) enumerates: enum↔class changes, generic type parameter changes, native (Kotlin/Java/Swift/ObjC) code, static-field and global-variable *initializers*, `main()`, `initState()`, `CupertinoTabView.builder`, and app-killed states. **Package boundaries are not on the list.** So "extracting a package breaks hot reload" is folklore, not documentation. Do not use it as an argument in either direction.

### 4.3 The argument against, and the call

**A package boundary can express exactly one rule: "domain must not import flutter or drift."** This app needs at least eight rules, and the other seven are *intra-package* and therefore inexpressible as package dependencies:

1. `domain/` imports nothing but dart:core + meta + collection + clock.
2. `core/db/` may import `domain/`, never `data/` or `features/`.
3. `data/` may import `core/` and `domain/`, never `features/`.
4. `data/` may not import `package:flutter/material.dart` (repositories must not know about `Color`, `TimeOfDay`, `BuildContext`).
5. `features/` may not import `core/db/` or `package:drift/`.
6. **No feature may import a sibling feature.** ← the rule that actually rots first
7. `core/ui/` may not import `data/`.
8. Nothing outside `data/` may call a mutating drift API.

A ~60-line script (§11.3) enforces all eight, has zero dependencies, cannot break on an SDK upgrade, and runs in well under a second. A package split enforces rule 1 only, and costs a second `pubspec.yaml`, a workspace declaration, `resolution: workspace` markers, an extra `dart pub get` surface, and a slightly noisier IDE.

**Call: single package for v1.** Structure it so extraction is a `git mv` plus two pubspecs.

**The trigger to extract — be specific:** the day there is a *second consumer* of the domain code. Realistic candidates: a companion CLI that re-generates a season PDF from a JSON backup; a watchOS/Wear target; a v2 that ships the domain as a public package. Absent a second consumer, a package is a boundary with nothing on the other side.

### 4.4 If you do extract: what 2026 actually gives you

[Pub workspaces](https://dart.dev/tools/pub/workspaces) shipped in **Dart 3.6.0** and are stable. Root:

```yaml
# pubspec.yaml (workspace root)
name: _
publish_to: none
environment:
  sdk: ^3.12.0
workspace:
  - app
  - packages/shed_domain
```

Each member:

```yaml
environment:
  sdk: ^3.12.0
resolution: workspace
```

Benefits per the docs: one `pubspec.lock`, one shared `.dart_tool/package_config.json`, one analysis context (*"reduces the amount of memory required for analysis, hence improving performance"*), one `dart pub get`. Glob patterns (`packages/*`) require Dart 3.11+. Documented limitation: *"Using a single shared dependency resolution for all your packages increases the risks of dependency conflicts, because Dart doesn't allow multiple versions of the same package."*

One sharp edge if you go multi-package **and** the second package needs codegen: build_runner's workspace support is explicitly experimental. [build_runner 2.15.2](https://pub.dev/packages/build_runner) README: *"You can build or watch more than one package together by putting them in a workspace and passing the `--workspace` flag. This is still experimental and subject to change based on feedback."* For Shed Book this would not bite — the domain package would have no builders, so you keep running `dart run build_runner build` in the app package only.

### 4.5 Melos: never, for this app

[melos 8.2.2](https://pub.dev/packages/melos) (invertase.io, published ~2026-07-14) README: *"Since the pub workspaces feature has been released, Melos has been updated to rely on that, instead of creating `pubspec_overrides.yaml` files."*

Melos's remaining value is **running commands across many packages** and **versioning/publishing** them. Shed Book has 1 (or at most 2) packages and publishes nothing. A `Makefile` with four targets does the same job with zero dependencies. Melos is a correct tool for a 20-package plugin federation; it is overhead here.

---

## 5. Domain layer: functions, not use-case classes

Flutter's guide lists three conditions for adding use-cases: logic that *"requires merging data from multiple repositories"*, is *"exceedingly complex"*, or *"will be reused by different view models"*. And it lists the costs: *"Increases complexity… Testing requires additional mocks… Adds additional boilerplate."*

Shed Book has real computation but it is **stateless and dependency-free**. Season statistics are arithmetic over rows; withdrawal math is date arithmetic; "hours since penned" is a subtraction. None of it needs a repository injected.

**So: top-level pure functions in `lib/domain/`, not `class GetSeasonSummaryUseCase`.** They are trivially testable with no mocks, importable from both a repository and a view model, and tree-shakeable.

```dart
// lib/domain/withdrawal.dart
//
// SAFETY (spec §12.1): this file contains NO default withdrawal periods and NO
// product database. `days` always comes from what the user read off the bottle.
// If you are ever tempted to add a lookup table here, re-read spec §12.

import 'package:meta/meta.dart';

/// The date on which meat/milk from the treated animal is clear.
///
/// Day-granularity, computed in the user's local calendar because that is how
/// the bottle label and the vet both express it. `treatedOn` must already be a
/// local calendar date (year/month/day), not an instant.
@visibleForTesting
DateTime clearDateFor({required DateTime treatedOn, required int days}) {
  assert(days >= 0, 'withdrawal days cannot be negative');
  final d = DateTime(treatedOn.year, treatedOn.month, treatedOn.day);
  return DateTime(d.year, d.month, d.day + days); // DateTime normalises overflow
}

/// Whole days remaining, floor 0. `now` is injected so this is testable and so
/// no clock is read inside domain code.
int daysUntilClear({required DateTime clearDate, required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final diff = clearDate.difference(today).inDays;
  return diff < 0 ? 0 : diff;
}
```

```dart
// lib/domain/season_stats.dart

/// Spec §7.8: the definition is user-configurable, so it is a parameter, never
/// a hard-coded formula.
enum PercentageBasis { perEwePutToRam, perEweLambed }
enum PercentageNumerator { lambsBorn, lambsReared }

/// Returns null rather than 0 when the denominator is zero. A season with no
/// ewes recorded has *no* lambing percentage; showing "0%" would be the app
/// asserting something the shepherd never said (spec §12.4).
double? lambingPercentage({
  required int lambsBorn,
  required int lambsReared,
  required int ewesPutToRam,
  required int ewesLambed,
  required PercentageBasis basis,
  required PercentageNumerator numerator,
}) {
  final n = switch (numerator) {
    .lambsBorn => lambsBorn,
    .lambsReared => lambsReared,
  };
  final d = switch (basis) {
    .perEwePutToRam => ewesPutToRam,
    .perEweLambed => ewesLambed,
  };
  if (d <= 0) return null;
  return n / d * 100;
}
```

> Note the `.lambsBorn` / `.perEwePutToRam` **dot shorthands** — a Dart language feature that requires language version ≥ **3.10** ([Dart language evolution](https://dart.dev/resources/language/evolution); [Dot shorthands](https://dart.dev/language/dot-shorthands)). With Dart 3.12.2 you have them. They are worth using in exhaustive switches, which this codebase will have many of.

```dart
// lib/domain/consistency.dart
//
// Spec §12.4: "Never silently correct a user's entry. If a birth type of 'twin'
// has three lambs attached, flag it; do not fix it."

sealed class ConsistencyFlag {
  const ConsistencyFlag();
  String get message;
}

final class LambCountMismatch extends ConsistencyFlag {
  const LambCountMismatch({required this.declared, required this.actual});
  final int declared;
  final int actual;
  @override
  String get message =>
      'You recorded $declared, and $actual ${actual == 1 ? "lamb is" : "lambs are"} attached.';
}

final class ClearDateDisagrees extends ConsistencyFlag {
  const ClearDateDisagrees({required this.stored, required this.recomputed});
  final DateTime stored;
  final DateTime recomputed;
  @override
  String get message => 'The clear date saved with this treatment no longer '
      'matches the dates and days entered.';
}

/// Pure. Returns what is inconsistent; never returns a corrected value.
List<ConsistencyFlag> flagsForLambing({
  required int declaredLambs,
  required int attachedLambs,
}) => [
      if (declaredLambs != attachedLambs)
        LambCountMismatch(declared: declaredLambs, actual: attachedLambs),
    ];
```

Note the return type: `List<ConsistencyFlag>`, not `Either<Corrected, Flags>`. The type system itself refuses to express "fix it". That is spec §12.4 as an architectural property.

---

## 6. The repository / single-write-path pattern

### 6.1 Who owns writes

**Exactly one layer: `lib/data/`.** No widget, controller, view model, or `domain/` function may open a write transaction. Enforced mechanically by §11.

Repositories take a drift `AppDatabase` and, where relevant, the two platform services. They are constructed once, at app start, in `data/providers.dart`.

```dart
// lib/data/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import 'lambing_repository.dart';
import 'media_store.dart';
import 'notification_scheduler.dart';

/// Overridden in main() with the real instance, and in tests with an
/// in-memory one. This is the whole of the app's DI root.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('override databaseProvider in main()'),
);

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) => NotificationScheduler());

final mediaStoreProvider = Provider<MediaStore>((ref) => MediaStore());

final lambingRepositoryProvider = Provider<LambingRepository>(
  (ref) => LambingRepository(
    db: ref.watch(databaseProvider),
    reminders: ref.watch(notificationSchedulerProvider),
    media: ref.watch(mediaStoreProvider),
  ),
);
```

`Provider<AppDatabase>` throwing by default is deliberate: it makes it impossible to accidentally run against an unconfigured database — the app fails at wiring time, not at 3am.

### 6.2 Write API shape: verbs, not `save(aggregate)`

This is the load-bearing decision for "every write commits immediately" (spec §5).

```dart
// lib/data/lambing_repository.dart  — shape, not the full file
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/write_outcome.dart';
import '../domain/birth_type.dart';
import '../domain/ids.dart';
import 'notification_scheduler.dart';
import 'media_store.dart';

final class LambingRepository {
  LambingRepository({
    required AppDatabase db,               // Dart 3.12 private named params:
    required NotificationScheduler reminders,
    required MediaStore media,
  })  : _db = db,
        _reminders = reminders,
        _media = media;

  final AppDatabase _db;
  final NotificationScheduler _reminders;
  final MediaStore _media;

  // ── READS ────────────────────────────────────────────────────────────────
  // One query per screen. See §6.3.
  Stream<LambingEntryModel> watchEntry(LambingId id) => /* one joined query */;

  // ── WRITES — every one of these is a complete, committed fact ────────────

  /// Called on the FIRST tap of the Lambing Entry screen. The row exists from
  /// this moment; there is no draft.
  Future<LambingId> beginLambing({
    required EweId ewe,
    required SeasonId season,
  }) async {
    final now = clock.now().toUtc();
    return _db.transaction(() async {
      final id = await _db.into(_db.lambings).insert(
            LambingsCompanion.insert(
              ewe: ewe.value,
              season: season.value,
              recordedAt: now,
              occurredAt: now,
              occurredAtSource: TimeSource.autoCaptured, // spec §12.5
              birthType: const Value.absent(),
            ),
          );
      await _db.into(_db.eweTouches).insert(
            EweTouchesCompanion.insert(ewe: ewe.value, touchedAt: now),
          );
      return LambingId(id);
    });
  }

  Future<WriteOutcome> setBirthType(LambingId id, BirthType type) =>
      _write(() => (_db.update(_db.lambings)..where((t) => t.id.equals(id.value)))
          .write(LambingsCompanion(birthType: Value(type))));

  Future<WriteOutcome> setEase(LambingId id, int ease) => /* … */;

  /// Adds one lamb AND schedules its colostrum/navel reminders in the SAME
  /// transaction boundary. There is no code path that creates a lamb without
  /// its reminders.
  Future<WriteOutcome> addLamb(LambingId id, {required Sex sex}) async { /* … */ }

  /// Spec §12.5: an edited time is labelled as edited, forever.
  Future<WriteOutcome> correctOccurredAt(LambingId id, DateTime when) =>
      _write(() => (_db.update(_db.lambings)..where((t) => t.id.equals(id.value)))
          .write(LambingsCompanion(
            occurredAt: Value(when.toUtc()),
            occurredAtSource: const Value(TimeSource.editedByUser),
            occurredAtEditedAt: Value(clock.now().toUtc()),
          )));
}
```

Observe what is **absent**: there is no `LambingDraft` class, no `saveLambing(Lambing whole)`, no `commit()`, no `isDirty`. **Draft state is unrepresentable.** You cannot defer a write because there is no object to defer.

This is the difference between a discipline and a structural property. A team convention "always commit immediately" survives until 11pm on a Tuesday. A write API with no aggregate parameter survives forever.

### 6.3 Read path: drift streams, one query per screen

drift's reactive queries are the correct mechanism, and manual invalidation is the wrong one. Facts, verified:

- Any `Selectable<T>` has `watch()` / `watchSingle()` / `watchSingleOrNull()` alongside `get()`; *"the stream will automatically emit new items whenever the underlying data changes"* ([Selects](https://drift.simonbinder.eu/docs/dart-api/select/), [Stream queries](https://drift.simonbinder.eu/dart_api/streams/)).
- drift *"tracks which tables it's listening on"* per stream, and reschedules queries when an insert/update/delete goes through drift APIs.
- **Streams created outside a transaction only see updates after the transaction commits** ([Transactions](https://drift.simonbinder.eu/dart_api/transactions/)). This is exactly the isolation you want.
- All drift streams emit a current snapshot on subscribe, so you never need to combine `get()` + `watch()`.

Three hard rules follow, each backed by a specific issue:

**Rule A — one query per screen. Never `combineLatest` two drift streams.**

[drift#3338](https://github.com/simolus3/drift/issues/3338) reports that two `watch()` streams updated inside one transaction can emit at different times, tearing a `combineLatest2`. Maintainer simolus3, 2024-11-13:

> "When a transaction completes, drift invalidates all queries on any table affected by the transaction. When there are lots of pending queries, they might take a while to complete and since they're running on a background isolate, it's perfectly valid for them to complete at different times. I know that this can violate some correctness assumptions, but generally is working as intended… The problem is that drift makes it really hard to get this right (as is evident by the docs showing a broken example)."

The issue is still **open** as of 2026-07-27. So: **build each screen's entire payload as one SQL statement** (joins / correlated subqueries / a view) and watch that one statement. For Shed Book this is not a hardship; it is better:

```dart
// The Pen Board (spec §7.4) is ONE query, not a stream per pen.
Stream<List<PenBoardRow>> watchBoard() {
  final ewe = alias(_db.ewes, 'e');
  final q = _db.select(_db.pens).join([
    leftOuterJoin(ewe, ewe.id.equalsExp(_db.pens.occupantEwe)),
  ])
    ..where(_db.pens.turnedOutAt.isNull())
    ..orderBy([OrderingTerm.asc(_db.pens.enteredAt)]);

  return q.watch().map((rows) => rows
      .map((r) => PenBoardRow(
            pen: r.readTable(_db.pens),
            ewe: r.readTableOrNull(ewe),
          ))
      .toList(growable: false));
}
```

**Rule B — de-duplicate emissions.** drift re-runs a stream on *any* write to a tracked table, even if the result is byte-identical. The docs say so: stream queries *"generally update more often than they have to"* since row-level filtering isn't available. [drift#3295 "Use .distinct() by default for streams"](https://github.com/simolus3/drift/issues/3295) is open. Mitigations, both cheap:

1. Enable `override_hash_and_equals_in_result_sets: true` in `build.yaml` so generated result-set classes implement `==`/`hashCode` ([generation options](https://drift.simonbinder.eu/generation_options/)). Generated *row* classes already do ([generated rows](https://drift.simonbinder.eu/dart_api/rows/)).
2. Append `.distinct()` (or a `ListEquality`-based `.distinct(...)` for `List<T>` results, since `List` `==` is identity) in the repository, never in the widget.

> **3am note.** This is not a micro-optimisation. On the Pen Board every treatment log, every reminder tick, and every `ewe_touch` write re-runs the pens query. Without de-duplication you get a grid that visibly re-lays-out while the shepherd is reading it in a head torch.

**Rule C — bulk writes go in one transaction.** [drift#3531](https://github.com/simolus3/drift/issues/3531), simolus3, 2025-04-15:

> "There's no way to turn them off entirely, but you can wrap the large amount of inserts in a single `transaction` which ensures that streams are only notified once if that helps?"

This matters for JSON restore (spec §7.9) and for "repeat-last-treatment for a batch" (spec §7.5).

**Corollary — never write to the DB outside drift.** The docs are explicit: *"Other uses of the database, e.g. a native SQLite client, will not trigger stream query updates."* If you ever must (you should not), `notifyUpdates()` is the escape hatch. Ban the raw handle in `tool/check_layers.dart` by disallowing `package:sqlite3/` outside `core/db/`.

### 6.4 Transactions and the "commits immediately" guarantee

drift's `transaction()` rolls back on any thrown exception, supports nesting since drift 2.0, and — per the [changelog](https://pub.dev/packages/drift/changelog) — since **2.34.0** uses `BEGIN IMMEDIATE`, which takes the write lock up front rather than upgrading mid-transaction. That removes a whole class of `SQLITE_BUSY`-on-upgrade failures.

The one hard requirement, from the docs: *"All queries inside the transaction must be `await`-ed. The transaction will complete when the inner method completes."* Un-awaited work escapes the transaction and can silently lose data. drift ships runtime checks for this; treat any such runtime warning as a P0.

Database placement: drift recommends `NativeDatabase.createInBackground(...)` so SQLite's synchronous IO does not run on the UI isolate ([drift on the VM](https://drift.simonbinder.eu/platforms/vm/)):

> "the usage of the database doesn't change at all, only the setup code needs to be adapted."

```dart
// lib/core/db/database.dart (open)
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor _open() => driftDatabase(name: 'shed_book');
// drift_flutter stores $name.sqlite under getApplicationDocumentsDirectory().
```

`readPool:` (multiple read isolates + WAL) is documented but **not** justified here — Shed Book has one user, one screen, and tiny tables. Extra isolates cost memory and startup time. Skip.

---

## 7. State management, DI, and routing

### 7.1 The honest trade-off

Flutter's official answer is `provider` + `ChangeNotifier` ViewModels + `Command` + `Result`, wired in `go_router` route builders. The [DI case study](https://docs.flutter.dev/app-architecture/case-study/dependency-injection) says:

> "Based on their experience building Flutter apps, teams at Google recommend using `package:provider` to implement dependency injection."

The docs do not mention Riverpod, get_it, or bloc there. Separately, [state management options](https://docs.flutter.dev/data-and-backend/state-mgmt/options) declines to endorse any package: *"The best choice for your app often depends on the app's complexity, your team's preferences, and the specific problems you need to solve."*

Now count the code for one screen, since that is what actually decides this.

**Official MVVM:**
```dart
class PenBoardViewModel extends ChangeNotifier {
  PenBoardViewModel({required PenRepository repository}) : _repository = repository {
    _sub = _repository.watchBoard().listen(
      (rows) { _rows = rows; notifyListeners(); },
      onError: (Object e, StackTrace s) { _error = e; notifyListeners(); },
    );
  }
  final PenRepository _repository;
  late final StreamSubscription<List<PenBoardRow>> _sub;
  List<PenBoardRow> _rows = const [];
  List<PenBoardRow> get rows => _rows;
  Object? _error;
  Object? get error => _error;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}
```
…plus a `ChangeNotifierProvider` in the route builder to own disposal.

**Riverpod:**
```dart
final penBoardProvider = StreamProvider.autoDispose<List<PenBoardRow>>(
  (ref) => ref.watch(penRepositoryProvider).watchBoard(),
);
```

That is ~16 lines of hand-written subscription lifecycle per screen versus 3. Across 12 screens it is roughly 150–200 lines of plumbing whose only job is to not leak a `StreamSubscription`. For a solo developer, every one of those lines is a place to forget `_sub.cancel()`.

### 7.2 The call: Riverpod 3, with one mandatory configuration

**Adopt [`flutter_riverpod` 3.4.1](https://pub.dev/packages/flutter_riverpod)** (dash-overflow.net, published ~2026-07-26; 3.0.0 stable landed **2025-09-10** per the [changelog](https://pub.dev/packages/flutter_riverpod/changelog) — ~10 months of stable field time). Keep Flutter's *layering vocabulary* (View / ViewModel / Repository); replace only the `ChangeNotifier` + `provider` mechanism.

Reasons specific to this app:

1. The entire read path is `Stream<T>` from drift. Riverpod's provider graph is literally a cache-and-dispose layer over async sources; `provider` is not.
2. `family` maps exactly onto per-entity screens: `eweCardProvider(eweId)`, `lambingEntryProvider(lambingId)`.
3. DI comes free — no `MultiProvider` tree to maintain as 8 repositories accumulate.
4. Testing overrides (`ProviderScope(overrides: [databaseProvider.overrideWithValue(memoryDb)])`) are one line.

**Mandatory configuration — do not ship without it:**

```dart
// lib/main.dart
runApp(
  ProviderScope(
    // Riverpod 3 retries failing providers by default with exponential
    // backoff. For a LOCAL database that is exactly wrong: disk-full,
    // corrupt-file and permission-denied do not heal, and the backoff hides
    // the failure for >12 seconds — longer than the spec's entire
    // unlock-to-saved budget (§5).
    retry: (retryCount, error) => null,
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const ShedBookApp(),
  ),
);
```

### 7.3 Routing: Navigator 1.0, not go_router

Flutter "Recommends" [`go_router` 17.3.0](https://pub.dev/packages/go_router) (flutter.dev, published ~2026-06-03, Flutter Favorite). It is a good package. It is not the right one here.

- **The value proposition is URLs.** go_router exists to give you *"a convenient, url-based API"* — deep links, browser history, web. Shed Book has no web target, no deep links, and no URL bar. Spec §13 rules out sharing and multi-user, which is where deep links usually enter.
- **Churn cost.** Per [go_router versions](https://pub.dev/packages/go_router/versions): 15.x ≈ 15 months ago, 16.x ≈ 13 months ago, 17.x ≈ 8 months ago — **three majors in 24 months**. A solo developer maintaining a one-time-purchase app for five seasons should minimise the number of dependencies that force migration work with no user-visible benefit.
- **The one feature that would justify it** — `ShellRoute` for a persistent bottom nav — is probably not wanted. The 3am hub is a screen of very large buttons, not a 5-tab bar with 44pt targets.

```dart
// lib/routing/routes.dart
abstract final class Routes {
  static Future<void> eweCard(BuildContext context, EweId id) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EweCardScreen(eweId: id)));

  static Future<void> lambingEntry(BuildContext context, LambingId id) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LambingEntryScreen(lambingId: id)),
      );
  // …12 screens, one method each.
}
```

Typed, greppable, testable, and zero dependencies. **Revisit if** you later add App Shortcuts / Quick Actions that need to open a specific ewe, or a widget/complication.

---

## 8. Making "every write commits immediately" structural

Spec §5: *"Assume the phone dies. Every write is committed immediately. There is no draft state to lose."* Five mechanisms, in order of strength.

### 8.1 Make the draft unrepresentable (§6.2)
No aggregate-shaped write method exists. Strongest mechanism; costs nothing.

### 8.2 Create the row on screen entry, not on exit
`LambingEntryScreen` calls `beginLambing()` in its controller's constructor. From that instant the record exists and is attributed to the right ewe with an honest auto-captured timestamp. Every subsequent tap is an `UPDATE`.

Consequence to design around: **an abandoned entry leaves a real row.** That is correct — spec §7.2 says "a valid record can be one tap". A lambing with only a timestamp is a true statement ("something happened to this ewe at 03:20"). Provide an explicit, deliberate delete on the ewe card; do not garbage-collect, because silent deletion is a §12.4 violation in the other direction.

### 8.3 Text fields are the only exception, and are bounded
Free-text notes and tag numbers cannot round-trip to SQLite per keystroke without churning every watching stream (§6.3 Rule B). Bound the exposure:

- debounce ~400 ms;
- commit on focus loss;
- commit on route pop (`PopScope`);
- commit on `AppLifecycleState.inactive` (fires before backgrounding on both platforms).

Worst-case loss: 400 ms of typing. State that number in the code review checklist so it cannot silently grow.

### 8.4 Prove it with a widget test, per entry screen
This is the part most teams skip and it is the part that makes the property durable:

```dart
testWidgets('Lambing entry row exists before any Done tap', (tester) async {
  final db = AppDatabase(DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true, // required in widget tests — see §14.1
  ));
  addTearDown(db.close);

  await tester.pumpWidget(ProviderScope(
    retry: (_, __) => null,
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: LambingEntryScreen.forNewEwe(tag: '412')),
  ));
  await tester.pump();

  await tester.tap(find.byKey(const Key('birthType.twin')));
  await tester.pump();

  // No "Done", no "Save", no navigation. The fact is already on disk.
  final rows = await db.select(db.lambings).get();
  expect(rows, hasLength(1));
  expect(rows.single.birthType, BirthType.twin);
});
```

### 8.5 Guard against the double tap
Cold, wet fingers on capacitive glass double-fire. Flutter's [Command pattern](https://docs.flutter.dev/app-architecture/design-patterns/command) exists partly for this — its doc comment says a Command *"ensures that it can't be launched again until it finishes"*, and `_execute` starts with `if (_running) return;`.

Riverpod 3 ships experimental "Mutations" for the same job, but experimental is the wrong risk profile for a safety-adjacent write path. Hand-roll ~30 lines:

```dart
// lib/core/write_action.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'write_outcome.dart';

sealed class WriteState {
  const WriteState();
}
final class WriteIdle extends WriteState { const WriteIdle(); }
final class WriteRunning extends WriteState { const WriteRunning(); }
final class WriteDone extends WriteState { const WriteDone(this.outcome); final WriteOutcome outcome; }

/// A Notifier that refuses to run concurrently. Extend it for each screen's
/// write surface. Riverpod 3: `Notifier`, no `AutoDispose` prefix.
abstract base class WriteController extends Notifier<WriteState> {
  @override
  WriteState build() => const WriteIdle();

  Future<void> guard(Future<WriteOutcome> Function() action) async {
    if (state is WriteRunning) return;      // the double-tap gate
    state = const WriteRunning();
    try {
      state = WriteDone(await action());
    } on Object catch (e, s) {
      state = WriteDone(WriteFailed(ShedFailure.from(e, s)));
    }
  }
}
```

Use `NotifierProvider.autoDispose<PenWriteController, WriteState>(PenWriteController.new)` per screen ([Riverpod: automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose)).

> **3am note.** This is a UX safety feature disguised as architecture. Every one-tap action in this app — foster, turn out, mark dead, repeat treatment — is destructive-ish and idempotency is not free at the DB level. The gate is the cheapest possible defence.

---

## 9. Error handling, proportionate to the real failure set

The complete failure set for an app with no network:

| Failure | SQLite / platform signal | Frequency | Can the user act? |
|---|---|---|---|
| Disk full | `SQLITE_FULL` | Rare, real (photos, spec §7.2) | Yes — delete photos, export, free space |
| Corrupt DB | `SQLITE_CORRUPT` / `SQLITE_NOTADB` | Very rare, catastrophic | Only if told immediately |
| Read-only / permission | `SQLITE_READONLY`, iOS data protection | Very rare | Barely |
| Migration failure | thrown during open | Rare, catastrophic | Only with an escape hatch |
| Constraint violation | `SQLITE_CONSTRAINT` | Programmer error | No — it is a bug |
| Media file IO | `FileSystemException` | Occasional | Yes |

### 9.1 Why `Result<T>` on every method is disproportionate here

[Error handling with Result objects](https://docs.flutter.dev/app-architecture/design-patterns/result) gives the canonical sealed implementation (`sealed class Result<T>` with `final class Ok<T>` / `final class Error<T>`, Dart 3 exhaustive switches) and notes packages like [`result_dart`](https://pub.dev/packages/result_dart) exist.

It is a good pattern **for network calls**, where failure is routine, per-call-site recovery is meaningful, and forgetting to handle it is the default failure mode. Here:

- Roughly 100% of read calls succeed.
- When one fails, there is exactly one sensible response and it is the same for every call site: **stop, tell the user loudly, offer export/recovery.** There is no per-call-site recovery to write.
- Wrapping ~60 repository methods forces ~200 `switch (result)` blocks in ViewModels to handle a case that never fires, and each unhandled-but-compiled `case Error()` branch is a place to write `// TODO`.

**Reads therefore throw.** Exceptions propagate to the global net (§9.3), which shows the one correct screen.

### 9.2 Writes get a sealed outcome — for a different reason

The reason is not error handling; it is **spec §12.4**. A write can be *rejected on domain grounds* ("this twin has three lambs") and the app must surface that without correcting it. That is a third state that neither an exception nor a bool can carry.

```dart
// lib/core/write_outcome.dart
import '../domain/consistency.dart';
import 'failure.dart';

/// Deliberately NOT named Ok/Error: `Error` shadows dart:core's `Error`, which
/// Flutter's own sample does and which produces confusing analyzer messages
/// the first time you `catch (e) { if (e is Error) … }`.
sealed class WriteOutcome {
  const WriteOutcome();
}

/// The fact is on disk. `flags` may be non-empty: the write succeeded AND
/// something looks inconsistent. Spec §12.4 — flag, do not fix.
final class WriteCommitted extends WriteOutcome {
  const WriteCommitted({this.flags = const []});
  final List<ConsistencyFlag> flags;
}

/// Nothing was written; the transaction rolled back.
final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.failure);
  final ShedFailure failure;
}
```

```dart
// lib/core/failure.dart
sealed class ShedFailure {
  const ShedFailure();
  /// Plain, non-technical, actionable. No stack traces in the UI at 3am.
  String get userMessage;
}

final class DiskFull extends ShedFailure {
  const DiskFull();
  @override
  String get userMessage =>
      'Your phone is out of space. Nothing was saved. Free some space, then try again.';
}

final class DatabaseUnreadable extends ShedFailure {
  const DatabaseUnreadable(this.detail);
  final String detail;
  @override
  String get userMessage =>
      'Shed Book cannot read its records file. Do not delete the app. '
      'Open Settings › Diagnostics to save a copy of what is there.';
}

final class StorageReadOnly extends ShedFailure { /* … */ }
final class MediaWriteFailed extends ShedFailure { /* … */ }

/// Bugs. Distinguished from the above because the user message differs and
/// because these should be loud in debug.
final class UnexpectedFailure extends ShedFailure { /* … */ }

extension ShedFailureFrom on ShedFailure {
  static ShedFailure from(Object e, StackTrace s) => switch (e) {
        // Map sqlite3 extended result codes here; see the persistence notes.
        _ => const UnexpectedFailure(),
      };
}
```

Repository writes wrap in one private helper so the mapping lives in exactly one place:

```dart
Future<WriteOutcome> _write(Future<void> Function() body) async {
  try {
    await _db.transaction(body);
    return const WriteCommitted();
  } on Object catch (e, s) {
    LocalLog.instance.error('write failed', e, s);   // local file, never network
    return WriteFailed(ShedFailureFrom.from(e, s));
  }
}
```

### 9.3 Where the global error net lives — and why the standard advice is wrong here

[Handling errors in Flutter](https://docs.flutter.dev/testing/errors) prescribes three hooks. All three belong in `main.dart`:

```dart
void main() {
  // 1. Framework errors (build / layout / paint).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);            // keep console output in debug
    LocalLog.instance.flutterError(details);       // on-device only
  };

  // 2. Errors outside the Flutter callstack (async, platform channels).
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalLog.instance.error('uncaught', error, stack);
    return true;
  };

  runApp(/* … */);
}
```

Plus a **dark** error widget, installed inside `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) {
    ErrorWidget.builder = (details) => const _NightErrorPanel();
    return child ?? const SizedBox.shrink();
  },
  // …
)
```

`_NightErrorPanel` is near-black with large white text and one button ("Save a copy of my records"). **The default `ErrorWidget` is a red-on-yellow block.** In a dark shed under a head torch that is both blinding and terrifying. This is a 3am-test requirement, not polish.

**Three deliberate divergences from the standard advice:**

1. **No Crashlytics, no Sentry, no Bugsnag.** Every tutorial's `FlutterError.onError` sends to a backend. That is a network path and it exfiltrates data the spec explicitly calls commercially sensitive (§4.5). `LocalLog` writes a size-capped ring-buffer file under the app support directory; Settings › Diagnostics shows it and offers **user-initiated** share-sheet export. That is the offline-legal equivalent, and it reuses the export mechanism you are already building (§7.9).
2. **No `runZonedGuarded`.** `PlatformDispatcher.instance.onError` supersedes it for async errors, and mixing custom zones with binding initialisation has a long tail of confusing failures ([flutter#94123](https://github.com/flutter/flutter/issues/94123): the framework does not warn when `ensureInitialized` is called in a different zone than `runApp`). One fewer thing to get wrong.
3. **`exit(1)` in release on framework errors — no.** The docs show `if (kReleaseMode) exit(1);` as an option. Killing the app at 3am mid-lambing, when the data is already committed and the failure may be a single mis-laid-out widget, is worse than a broken screen. Log and show the panel.

---

## 10. Where derived state lives

### 10.1 The rule

> **Store what was observed or typed. Compute what is inferred. The one exception is a value the app *told* the user, which is itself an observation.**

### 10.2 Bucket A — time-relative values: never stored

"Hours since penned" (§7.4), "ready to turn out" (§7.4), "days until clear" (§7.5), "overdue" (§7.6).

These change **with no write**. Any stored copy is wrong within a minute. Store `entered_at`; compute the rest from `clock.now()` at render.

Implementation detail that matters: **one app-level ticker, not a `Timer.periodic` per row.** A 30-pen board with a timer each is 30 timers, 30 rebuild schedules, and measurable battery cost overnight.

```dart
// lib/core/time/ticker.dart
/// A single 30-second heartbeat for every time-relative display in the app.
/// Emits at the boundary rather than on an arbitrary phase so all pens tick
/// together — a grid where cells update at different moments reads as noise
/// under a head torch.
final minuteTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield clock.now();
  while (true) {
    final now = clock.now();
    final msToNextHalfMinute = 30000 - (now.millisecondsSinceEpoch % 30000);
    await Future<void>.delayed(Duration(milliseconds: msToNextHalfMinute));
    yield clock.now();
  }
});
```

Caveat to verify on device: Riverpod 3 **pauses providers whose listeners are not visible** (see §15, pitfall 6). For the ticker that is desirable (no ticking in the background) but you must confirm it *resumes and re-emits* on return rather than showing a stale minute count. Riverpod 3.2.1 and 3.3.2 both shipped pause/resume bug fixes, which is a signal to test this rather than assume it.

### 10.3 Bucket B — aggregates: SQL views, computed on read

Season summary (§7.8), ewe-card one-line summary (§7.7), losses by cause, lambing spread histogram.

**Compute on read, expressed as drift views.** Two independent arguments:

*Correctness.* A stored `lambing_percentage` column drifts the first time a lamb's status is corrected from "alive" to "dead" through a path that forgot to recompute. Spec §8 says the app's advantage over paper is that these are "computed, not tallied by hand" — a stale computed number is strictly worse than paper, because paper is visibly out of date and a wrong number in an app looks authoritative. This is the number a shepherd culls on.

*Cost.* Upper bound from the spec: 400 ewes × ~2 lambs × ~10 seasons ≈ 8,000 lamb rows. A full scan with `GROUP BY` on that is sub-millisecond on a 2018 phone. There is no cost to trade against.

[SQLite views](https://www.sqlite.org/lang_createview.html) are computed on read and read-only — *"You cannot DELETE, INSERT, or UPDATE a view. Views are read-only in SQLite."* That read-only property is a feature: the type system will not let anyone accidentally write a derived value. drift models them as `abstract class … extends View` registered on `@DriftDatabase(views: [...])` ([drift views](https://drift.simonbinder.eu/docs/dart-api/views/)):

```dart
// lib/core/db/views/v_ewe_season.dart
abstract class EweSeasonSummary extends View {
  Ewes get ewes;
  Lambings get lambings;
  Lambs get lambs;

  Expression<int> get lambingCount => lambings.id.count();
  Expression<double> get avgLitter => lambs.id.count().cast<double>() /
      lambings.id.count(distinct: true).cast<double>();

  @override
  Query as() => select([ewes.id, ewes.tag, lambingCount, avgLitter])
      .from(ewes)
      .join([
        leftOuterJoin(lambings, lambings.ewe.equalsExp(ewes.id)),
        leftOuterJoin(lambs, lambs.lambing.equalsExp(lambings.id)),
      ])
      ..groupBy([ewes.id]);
}
```

Documented gotcha: *"For Dart-defined views, expressions defined as an `Expression` getter are **always** nullable."* So `avgLitter` arrives as `double?`. Do not paper over it with `?? 0` — a ewe with no lambings has *no* average, and printing `0.0` is the app asserting something false (§12.4).

**Views are watchable**, which is the real payoff: `select(eweSeasonSummary).watch()` gives the Season Summary screen a live, single-query, always-consistent feed with zero invalidation code.

Where a view is awkward (the lambing-spread histogram wants date bucketing), use a named `customSelect` with an explicit `readsFrom: {lambings}` so drift can still track it — the docs warn that drift *"can't reliably update stream queries that don't have a `readsFrom` set."*

### 10.4 Bucket C — the one stored derived value: `clear_date`

Spec §10 already stores `clear_date` on `Treatment`. That is correct, and the reasoning is worth writing down because it looks like a violation of the rule:

- The user typed `withdrawal_days` off the bottle and the app **displayed a specific calendar date** and printed it into the medicine book PDF (§7.5).
- Recomputing on read could produce a *different* date later — after a DST transition, a device timezone change, or a locale/calendar-settings change. Silently changing a date the shepherd wrote on a pen card and told the abattoir is a §12.4 and §12.5 violation.
- So `clear_date` is not really derived; it is **a record of what the app told the user**, which is an observation.

Rules attached to it:
1. Computed **exactly once**, at write time, by `clearDateFor()` in `domain/withdrawal.dart`. No other code computes a clear date.
2. Never silently recomputed.
3. A consistency check recomputes and, on mismatch, emits `ClearDateDisagrees` — **shown, never applied** (§5's `consistency.dart`).
4. Store the *inputs* alongside it forever (`treated_on`, `withdrawal_days`), so the discrepancy is always explainable.

**Rejected: making it a SQLite generated column.** [Generated columns](https://www.sqlite.org/gencol.html) (SQLite 3.31.0+, and drift exposes `generatedAs(...)` with `stored:`) would work in principle: `date(treated_on, '+' || withdrawal_days || ' days')` references only same-row columns. But: (a) restriction 7 — *"It is not possible to ALTER TABLE ADD COLUMN a STORED column"*, so schema evolution becomes a table rebuild; (b) you would then have the withdrawal rule in **two** places, SQL and Dart, and spec §12.1 makes that rule safety-critical; (c) SQLite's date arithmetic and Dart's `DateTime` overflow normalisation must agree exactly, forever, across SQLite version bumps. Reject. One rule, one function, one language.

### 10.5 Bucket D — observed UI events that look derived

The "recents strip" (last 6 animals touched, §7.1) is *not* derivable from records: "touched" includes looking at a ewe card without writing anything. So it is an observation and gets a real table, `ewe_touches(ewe, touched_at)`, written by the repository whenever any feature touches a ewe. Consistent with the rule; worth calling out because it is the one place where a UI concern legitimately reaches the schema.

### 10.6 Time is an injected dependency

Every timestamp comes from [`package:clock` 1.1.2](https://pub.dev/packages/clock) (tools.dart.dev), never `DateTime.now()`.

```dart
import 'package:clock/clock.dart';
final now = clock.now();                 // production
withClock(Clock.fixed(DateTime.utc(2026, 3, 14, 3, 20)), () { /* test */ });
```

And the corresponding SQL rule: **never use SQLite's `CURRENT_TIMESTAMP`, `date('now')`, or `datetime('now')`.** Reasons: (a) they bypass `package:clock`, making withdrawal countdowns and pen timers untestable; (b) spec §12.5 requires distinguishing auto-captured from edited times, which needs a Dart-side decision; (c) you lose control of UTC-vs-local. Always pass an explicit instant from Dart. Add `date('now')` and `CURRENT_TIMESTAMP` to the CI grep.

If a future feature genuinely needs SQL-side time, [`sqlite3_test` 0.2.0](https://pub.dev/packages/sqlite3_test) (simonbinder.eu) provides `TestSqliteFileSystem`, a VFS that makes `CURRENT_TIME`/`CURRENT_DATE`/`CURRENT_TIMESTAMP` read from `package:clock`. Note its adoption is tiny (1 like, 289 downloads) — it works, but you would be an early user.

**Store instants as UTC** (`clock.now().toUtc()`); convert to local only at the presentation edge. A shepherd who lambs across the March DST change — which is exactly when UK/Ireland lambing happens — will otherwise get a one-hour discontinuity in "hours since penned".

---

## 11. Dependency direction that a tool enforces

### 11.1 The rules, as data

| From | May import | May never import |
|---|---|---|
| `lib/domain/` | `lib/domain/`, `dart:*`, `package:meta`, `package:collection` | `package:flutter/*`, `package:drift/*`, `package:flutter_riverpod/*`, any other app layer |
| `lib/core/db/` | `lib/core/db/`, `lib/domain/`, `package:drift/*` | `lib/data/`, `lib/features/` |
| `lib/core/ui/` | `lib/core/ui/`, `lib/domain/`, `package:flutter/*` | `lib/data/`, `lib/core/db/`, `package:drift/*` |
| `lib/core/` (other) | `lib/core/*`, `lib/domain/` | `lib/data/`, `lib/features/` |
| `lib/data/` | `lib/data/`, `lib/core/*`, `lib/domain/`, `package:drift/*` | `lib/features/`, `package:flutter/material.dart`, `package:flutter/cupertino.dart` |
| `lib/features/<f>/` | own feature, `lib/data/`, `lib/domain/`, `lib/core/ui/`, `lib/routing/` | **any other feature**, `lib/core/db/`, `package:drift/*`, `package:sqlite3/*` |
| `lib/routing/` | `lib/routing/`, `lib/features/`, `lib/domain/` | `lib/core/db/` |

### 11.2 Why not an analyzer plugin

I checked the three candidates:

- **[`dart_code_metrics` 5.7.6](https://pub.dev/packages/dart_code_metrics)** — **discontinued**, last published 3 years ago. The pub page says: *"This package has been discontinued and is no longer maintained. To continue using Dart Code Metrics, visit our website to purchase a license."* This is the cautionary tale: a whole generation of Flutter codebases had their architecture rules enforced by a package that went commercial.
- **[`custom_lint` 0.8.1](https://pub.dev/packages/custom_lint)** (invertase.io) — last published ~10 months ago, **60 pub points** and SDK constraint `>=3.0.0 <4.0.0`. Downloads are high (692k) because Riverpod ships lints on it, but the low score and staleness reflect the fundamental problem: analyzer-plugin packages are pinned to analyzer versions and break on SDK upgrades.
- **[`import_lint` 2.0.0](https://pub.dev/packages/import_lint)** (kawa.dev, ~3 months old) — does exactly the right thing (`target` / `from` / `except` glob rules in `analysis_options.yaml`, `severity: error` gives exit code 1). But 28 likes / 3.77k downloads, requires Dart 3.10+, and *"Analyzer plugin must be restarted after configuration changes."*

For a five-season, one-time-purchase app maintained by one person, betting the architecture gate on any of these is an unforced dependency risk.

### 11.3 The script

Zero dependencies. Runs in well under a second. Cannot break on an SDK upgrade. Encodes all eight rules including the intra-package ones no package boundary can express.

```dart
// tool/check_layers.dart
//
// Enforces Shed Book's dependency direction. Run in CI and from a pre-push
// hook:  dart run tool/check_layers.dart
//
// Deliberately dependency-free: an analyzer plugin would couple this gate to
// analyzer versions, which is how dart_code_metrics-based setups died.
import 'dart:io';

const _package = 'shed_book';

/// Most specific prefix first — _layerOf returns the first match.
const _layers = <String>[
  'lib/core/db/',
  'lib/core/ui/',
  'lib/core/',
  'lib/domain/',
  'lib/data/',
  'lib/features/',
  'lib/routing/',
];

const _allowed = <String, Set<String>>{
  'lib/domain/':   {'lib/domain/'},
  'lib/core/db/':  {'lib/core/db/', 'lib/domain/'},
  'lib/core/ui/':  {'lib/core/ui/', 'lib/domain/'},
  'lib/core/':     {'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
  'lib/data/':     {'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
  'lib/features/': {'lib/features/', 'lib/data/', 'lib/domain/', 'lib/core/ui/', 'lib/core/', 'lib/routing/'},
  'lib/routing/':  {'lib/routing/', 'lib/features/', 'lib/data/', 'lib/core/', 'lib/domain/'},
};

const _bannedPackageImports = <String, Set<String>>{
  'lib/domain/':   {'package:flutter/', 'package:drift/', 'package:flutter_riverpod/', 'package:riverpod/', 'package:sqlite3'},
  'lib/data/':     {'package:flutter/material.dart', 'package:flutter/cupertino.dart'},
  'lib/core/ui/':  {'package:drift/', 'package:sqlite3'},
  'lib/features/': {'package:drift/', 'package:sqlite3'},
};

/// Textual bans applied to whole layers (see §10.6 — SQL-side clocks).
const _bannedText = <String, Set<String>>{
  'lib/': {"date('now')", 'CURRENT_TIMESTAMP', 'DateTime.now('},
};

final _directive = RegExp("""^\\s*(?:import|export)\\s+['"]([^'"]+)['"]""", multiLine: true);

String? _layerOf(String path) {
  for (final layer in _layers) {
    if (path.startsWith(layer)) return layer;
  }
  return null;
}

String _resolveRelative(String from, String relative) {
  final segments = from.split('/')..removeLast();
  for (final part in relative.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(part);
  }
  return segments.join('/');
}

void main() {
  final violations = <String>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final from = entity.path.replaceAll(r'\', '/');
    if (from.endsWith('.g.dart') || from.endsWith('.drift.dart')) continue;

    final fromLayer = _layerOf(from);
    if (fromLayer == null) continue;
    final source = entity.readAsStringSync();

    for (final banned in _bannedText['lib/'] ?? const <String>{}) {
      if (source.contains(banned)) {
        violations.add('$from uses "$banned" — use package:clock / an explicit instant');
      }
    }

    for (final match in _directive.allMatches(source)) {
      var uri = match.group(1)!;

      for (final banned in _bannedPackageImports[fromLayer] ?? const <String>{}) {
        if (uri.startsWith(banned)) {
          violations.add('$from  ($fromLayer)  may not import  $uri');
        }
      }

      // Normalise self-referential package: imports to lib/ paths.
      if (uri.startsWith('package:$_package/')) {
        uri = 'lib/${uri.substring('package:$_package/'.length)}';
      } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
        continue;
      } else {
        uri = _resolveRelative(from, uri);
      }

      final toLayer = _layerOf(uri);
      if (toLayer == null) continue;

      if (!(_allowed[fromLayer] ?? const <String>{}).contains(toLayer)) {
        violations.add('$from  ($fromLayer)  may not import  $toLayer  [$uri]');
      }

      if (fromLayer == 'lib/features/' && toLayer == 'lib/features/') {
        final a = from.split('/')[2];
        final b = uri.split('/')[2];
        if (a != b) {
          violations.add('$from  feature "$a" may not import feature "$b" — '
              'move the shared piece into lib/data/ or lib/domain/');
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('layers ok');
    return;
  }
  for (final v in violations..sort()) {
    stderr.writeln('LAYER VIOLATION  $v');
  }
  exit(1);
}
```

Wire it into `.git/hooks/pre-push` and CI. The `DateTime.now(` ban will fire on `lib/core/time/app_clock.dart` if you re-export there — carve that one file out explicitly rather than weakening the rule.

---

## 12. Offline-only as a structural property

Architecture here means: **the network layer is absent by construction, and CI proves it.**

### 12.1 Android: no `INTERNET` permission in release

Verified behaviour: Flutter's template does **not** put `INTERNET` in the main manifest. [Build and release an Android app](https://docs.flutter.dev/deployment/android):

> "Add the `android.permission.INTERNET` permission value to the `android:name` attribute if your app needs Internet access. The standard template doesn't include this tag but allows Internet access during development to enable communication between Flutter tools and a running app."

The development permission lives in `android/app/src/debug/AndroidManifest.xml` (and the profile variant), which the manifest merger only applies to those build types. Confirmed independently in [flutter#20789](https://github.com/flutter/flutter/issues/20789), where a contributor notes *"`android.permission.INTERNET` is not automatically added to AndroidManifest.xml in release mode."*

So a stock Flutter release build already has no `INTERNET` — **unless a plugin merges one in.** Belt and braces in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
  <!-- Shed Book never opens a socket. If a dependency tries to merge these in,
       strip them and then go find out why that dependency is here. -->
  <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
  <!-- … the app's own real permissions (notifications, camera, mic) below … -->
</manifest>
```

And a CI assertion on the *merged* output:

```bash
flutter build apk --release
if grep -rl 'android.permission.INTERNET' build/app/intermediates/ | grep -q AndroidManifest; then
  echo "FAIL: INTERNET permission reached the merged release manifest"; exit 1
fi
```

### 12.2 A dependency allowlist, not a denylist

A denylist misses the transitive `http` that arrives inside some new plugin. Allowlist every resolved package instead:

```dart
// tool/check_offline.dart
import 'dart:io';

/// Every package permitted in the resolved graph. Adding a line here is a
/// deliberate act: read its pubspec and confirm it opens no socket and merges
/// no network permission.
const _allow = <String>{
  'shed_book',
  'flutter', 'flutter_test', 'flutter_localizations', 'sky_engine', 'flutter_lints', 'lints',
  'drift', 'drift_flutter', 'drift_dev', 'sqlite3', 'sqlite3_flutter_libs',
  'flutter_riverpod', 'riverpod', 'state_notifier',
  'path_provider', 'path_provider_android', 'path_provider_foundation',
  'path_provider_platform_interface', 'path', 'file', 'platform',
  'flutter_local_notifications', 'flutter_local_notifications_linux',
  'flutter_local_notifications_platform_interface', 'timezone',
  'clock', 'collection', 'meta', 'async', 'characters', 'material_color_utilities',
  'vector_math', 'stack_trace', 'source_span', 'string_scanner', 'term_glyph',
  'build_runner', 'build', 'analyzer', /* … dev-only, still reviewed … */
};

void main() {
  final lock = File('pubspec.lock');
  if (!lock.existsSync()) { stderr.writeln('no pubspec.lock'); exit(1); }

  final name = RegExp(r'^  ([a-z0-9_]+):$');
  final found = <String>{
    for (final line in lock.readAsLinesSync())
      if (name.firstMatch(line) case final m?) m.group(1)!,
  };

  final unreviewed = (found.difference(_allow)).toList()..sort();
  if (unreviewed.isEmpty) {
    stdout.writeln('dependency allowlist ok (${found.length} packages)');
    return;
  }
  stderr.writeln('UNREVIEWED DEPENDENCIES — each may open a socket or merge a permission:');
  for (final p in unreviewed) stderr.writeln('  $p');
  exit(1);
}
```

Refresh the list against a real `pubspec.lock` once the project exists; the names above are illustrative.

### 12.3 iOS

There is no "remove networking" entitlement for an iOS app, so enforcement is (a) the allowlist above, (b) no `NSAppTransportSecurity` key in `Info.plist`, (c) an App Privacy nutrition label of "Data Not Collected", and (d) an optional manual check with Charles/`nettop` during release testing. Say so honestly in the notes rather than implying parity with Android.

### 12.4 The permission the notification plugin does bring

[`flutter_local_notifications` 22.2.0](https://pub.dev/packages/flutter_local_notifications) (dexterx.dev, published ~2026-07-25, minimum Flutter 3.38.1) merges `POST_NOTIFICATIONS` and `VIBRATE`, and you will add `RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` for scheduled reminders. **None of these is a network permission** — good — but they are exactly the kind of silent manifest merge the CI check exists to make visible. Detailed handling belongs to the notifications research topic.

---

## 13. Bootstrap: architecture of the first 300 ms

Spec §5: *"No white flash on launch."* This is partly a theming problem and partly an architecture problem — specifically, **what `main()` awaits**.

Verified mechanism: calling `WidgetsFlutterBinding.ensureInitialized()` before `runApp()` **tears the native splash down early**, leaving a blank frame until Flutter paints. [flutter#32736](https://github.com/flutter/flutter/issues/32736): *"causes the launch image to disappear and a blank (typically black) screen to be displayed momentarily."* [flutter#39494](https://github.com/flutter/flutter/issues/39494) (45 comments, labelled `c: regression`, `customer: crowd`) documents the same for iOS. Both are closed, but the mechanism is inherent: the splash comes down when the binding is up, not when your first frame is ready.

### 13.1 The call: `main()` awaits nothing

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/log/local_log.dart';
import 'data/providers.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LocalLog.instance.flutterError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalLog.instance.error('uncaught', error, stack);
    return true;
  };

  // Constructing AppDatabase does NOT do IO — drift opens lazily on the first
  // query, by which time runApp() has initialised the binding. Nothing is
  // awaited here, so the native splash comes down at the normal moment and the
  // first Flutter frame is the app's own near-black background.
  final db = AppDatabase(_open());

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,        // §7.2 — non-negotiable
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const ShedBookApp(),
    ),
  );
}
```

Three supporting pieces:

1. **Launch theme background = app background.** Android: `android:windowBackground` in `LaunchTheme` (or `android:windowSplashScreenBackground` for the Android 12+ `SplashScreen` API); iOS: the `LaunchScreen` storyboard's background colour. Both set to the app's near-black. Then *any* gap is invisible rather than white. This is a config change, not code, and it is the actual fix. ([Adding a splash screen to your Android app](https://docs.flutter.dev/platform-integration/android/splash-screen))
2. **Kill the Android 12+ splash exit fade**, which the same page calls out: *"Disable the Android splash screen fade out animation to avoid a flicker before the similar frame is drawn in Flutter."*
3. **`deferFirstFrame()` only if measurement shows you need it.** `WidgetsBinding.deferFirstFrame` / `allowFirstFrame` is the documented tool — *"Call this to perform asynchronous initialization work before the first frame is rendered (which takes down the splash screen)"* ([api.flutter.dev](https://api.flutter.dev/flutter/widgets/WidgetsBinding/deferFirstFrame.html)). It is the right escape hatch, and the wrong default: it converts a fixed cost into a variable one, and the spec's budget is 15 seconds *total*.

### 13.2 The one thing that must be handled before the first screen

A database that fails to open (corruption, failed migration) cannot be handled by a normal screen. Catch it at the first query, and route to a dedicated `RecoveryScreen` inside the same widget tree — dark, three buttons: *"Save a copy of the file"* (share sheet), *"Restore from a JSON backup"*, *"Start a new records file"*. Never auto-delete and never auto-repair. Spec §7.9 already says a lost phone is lost data unless exported; the corresponding honesty here is that a corrupt file is not silently discarded.

---

## 14. Testing shape (architecture-relevant parts only)

### 14.1 Test against a real in-memory database, not mocks

drift's own [testing guide](https://drift.simonbinder.eu/testing/) says to use `NativeDatabase.memory()` rather than mocking, and flags the widget-test requirement:

> "By default, unsubscribing from a query stream created by drift will keep the stream open for one event loop iteration… In Flutter widget tests however, it's illegal to keep these timers open after a test concludes."

So: `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` in widget tests. Forget this and every widget test that touches a stream fails with a pending-timer error, which is a miserable half-day.

### 14.2 Migration tests are not optional

The **only** backup is a user-initiated export (spec §7.9). A migration bug therefore destroys records with no recovery path. drift's [migration tooling](https://drift.simonbinder.eu/Migrations/) generates both the step-by-step migration and the tests:

```yaml
# build.yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          databases:
            app_database: lib/core/db/database.dart
          test_dir: test/drift/
          schema_dir: drift_schemas/
          override_hash_and_equals_in_result_sets: true   # §6.3 Rule B
```

```bash
dart run drift_dev make-migrations   # after every schemaVersion bump
```

Treat a red migration test as ship-blocking.

### 14.3 Three tiers

| Tier | Runner | What |
|---|---|---|
| `test/domain/` | `flutter test` (or `dart test` if extracted) | Pure functions. `withClock(Clock.fixed(...))`. Fastest; where withdrawal and percentage math is proven. |
| `test/data/` | `flutter test` | Repositories against `NativeDatabase.memory()`. Where "one write path" and "one transaction" are proven. |
| `test/features/` | `flutter test` | Widget tests, including the commit-on-first-tap tests (§8.4) and a double-tap test per destructive action. |

Plus `test/drift/` (generated) for migrations.

### 14.4 The consequence for abstract repositories

Flutter **strongly recommends** abstract repository classes, so that ViewModels can be tested against fakes. That recommendation assumes the alternative is a live network. Here the alternative is an in-memory SQLite database that is *faster to construct than a hand-written fake and cannot diverge from production behaviour*. An `abstract class LambingRepository` with exactly one implementation, forever, is 8 files of pure ceremony that also breaks IDE "go to definition".

**Call: concrete `final class` repositories.** Revisit only if a second implementation ever appears (it will not — spec §13 rules out sync).

---

## 15. Rejected alternatives

| # | Rejected | Why it lost |
|---|---|---|
| 1 | **Flutter's offline-first design pattern** (sync flags, `sync()`, `Timer.periodic`, `workmanager`, `connectivity_plus`, `battery_plus`, FCM) | It is a cache-over-network pattern. There is no network. Following it adds packages that merge network permissions — a direct spec §4 violation. |
| 2 | **Full Clean Architecture** (entities / use-cases / repositories / data-sources + mappers) | 8 entities × 4 layers + mapping ≈ 2,000 lines guarding a boundary that can never move. Flutter's own docs pre-authorise skipping the logic layer for CRUD apps. |
| 3 | **Use-case / interactor classes** | Flutter's conditions (merge multiple repositories, exceedingly complex, reused across view models) are not met. Domain logic here is stateless arithmetic → top-level functions. The docs' own cost list (more classes, more mocks, more boilerplate) applies fully. |
| 4 | **Separate API models + domain models** | Marked "Conditional" by Flutter; the condition is a wire format you do not control. You own the schema. |
| 5 | **Abstract repository interfaces** | See §14.4. Real in-memory SQLite is a better fake than a fake. |
| 6 | **`freezed` for entities** | drift already generates immutable rows with `==`, `hashCode`, `copyWith`, `fromJson`. Dart 3 `sealed`/`final class` covers unions natively. Adding [freezed 3.2.5](https://pub.dev/packages/freezed) means a second code generator in the loop for zero new capability — and build_runner is O(N²)-ish ([build#3555](https://github.com/dart-lang/build/issues/3555)). |
| 7 | **`riverpod_generator`** | [4.0.6](https://pub.dev/packages/riverpod_generator) is fine, but a manual `final xProvider = StreamProvider(...)` is one line and hot-reloads instantly; codegen makes every provider edit a build_runner round-trip. One generator (drift) is the budget. |
| 8 | **BLoC / flutter_bloc** | Event + state class explosion for what is CRUD: ~4 extra classes × 12 screens. Its strengths (traceable event logs, complex async orchestration) address problems this app does not have. |
| 9 | **`get_it`** ([9.2.1](https://pub.dev/packages/get_it)) | Service locator gives DI but no reactive caching, and hides the dependency graph behind global lookups. Riverpod does both jobs; two tools would be worse than one. |
| 10 | **`provider` + `ChangeNotifier` ViewModels** (Flutter's official pick) | Genuinely close, and the "no magic" argument is real. Lost on ~150–200 lines of hand-written `StreamSubscription` lifecycle across 12 screens, each a leak site. If you prefer the official path, the *only* thing you must port from §7.2 is: do not add retry logic. |
| 11 | **`go_router`** | See §7.3. No URLs, no deep links, no web; 3 majors in 24 months. |
| 12 | **Manual cache invalidation** (`ref.invalidate` after every write) | drift already tracks table dependencies. Hand invalidation is the classic stale-read bug and it is discipline, not structure. |
| 13 | **Stored aggregate columns** (denormalised lambing %, litter counts) | Recomputation cost is ~0 at N ≈ 8,000 rows; drift-out-of-sync cost is a wrong number a shepherd culls on. |
| 14 | **SQLite generated columns for `clear_date`** | Legal but duplicates a safety-critical rule (spec §12.1) into SQL; `STORED` columns cannot be added by `ALTER TABLE` ([gencol restriction 7](https://www.sqlite.org/gencol.html)). |
| 15 | **`Result<T>` on every repository method** | Disproportionate: ~100% success rate, one uniform response to failure, ~200 dead `switch` branches. Kept only on the write path, where a third state (rejected-on-domain-grounds) genuinely exists. |
| 16 | **Naming the failure case `Error`** (as Flutter's sample does) | Shadows `dart:core`'s `Error`. Use `WriteCommitted` / `WriteFailed`. |
| 17 | **`runZonedGuarded`** | Superseded by `PlatformDispatcher.instance.onError`; zone/binding mismatches are a documented footgun ([flutter#94123](https://github.com/flutter/flutter/issues/94123)). |
| 18 | **Crashlytics / Sentry in `FlutterError.onError`** | Network path + exfiltration of commercially sensitive data (spec §4.5). Replaced by a local ring-buffer log surfaced through the share sheet. |
| 19 | **Melos** | 1–2 packages, nothing published. Melos 8 delegates to pub workspaces anyway. |
| 20 | **Pub workspace / separate domain package for v1** | Enforces 1 of 8 rules; a 60-line script enforces all 8. Extract when a second consumer exists. |
| 21 | **`readPool:` / multi-isolate drift** | One user, one screen, tiny tables. Costs memory and startup for no measurable gain. |
| 22 | **`await`ing DB open in `main()`** | Documented cause of the splash-teardown flash the spec forbids (§13). |
| 23 | **`lib/src/`** | Package-authoring convention; its only real payoff is irrelevant to an app binary. Adopt only alongside extraction. |

---

## 16. Pitfalls

| # | Pitfall | Severity | Mitigation |
|---|---|---|---|
| 1 | **Torn screen state from combining drift streams.** Two `watch()` streams updated in one transaction can emit at different times ([drift#3338](https://github.com/simolus3/drift/issues/3338), open; maintainer: *"generally is working as intended"*, and *"the docs [show] a broken example"*). A Pen Board built from `combineLatest(pens, ewes)` will render a pen whose ewe has already moved. | **Blocker** | One SQL statement per screen. Ban `combineLatest`/`Rx.combineLatest*` over drift streams in the review checklist and in `check_layers.dart`'s text bans. |
| 2 | **Stream churn.** drift re-runs every stream watching a table on *any* write to it, even when the result is identical ([drift#3295](https://github.com/simolus3/drift/issues/3295), open). Writing `ewe_touches` on every screen visit re-runs the flock query, the pen board, and the reminders list. | High | `override_hash_and_equals_in_result_sets: true` + `.distinct()` in the repository (with a `ListEquality` comparator for `List<T>` results — `List.==` is identity). |
| 3 | **Notification storm on bulk writes.** A JSON restore inserting 5,000 rows one by one notifies streams 5,000 times. Maintainer's answer ([drift#3531](https://github.com/simolus3/drift/issues/3531)): *"wrap the large amount of inserts in a single `transaction`."* | High | One transaction per import / per batch treatment. |
| 4 | **Riverpod 3 auto-retry masks disk failures.** Retry is **on by default** and *"starts with a 200ms delay that doubles after each retry up to 6.4 seconds"* ([What's new in Riverpod 3.0](https://riverpod.dev/docs/whats_new), [3.0 migration](https://riverpod.dev/docs/3.0_migration)). 200 + 400 + 800 + 1600 + 3200 ms is already >6 s of silence before the sixth attempt, and disk-full never heals. | **Blocker** | `ProviderScope(retry: (retryCount, error) => null)`. Put it in the first commit and add a grep for it in CI. |
| 5 | **`ProviderException` wrapping.** Riverpod 3 rethrows all provider failures wrapped: *"all provider failures are rethrown as ProviderExceptions."* `on DiskFull catch` silently stops matching. | High | Unwrap once, in the global net: `if (e is ProviderException) e = e.exception;` before mapping to `ShedFailure`. |
| 6 | **Paused providers.** Riverpod 3 pauses listeners whose widgets are not visible; 3.2.1 fixed a *"paused provider resumption bug"* and 3.3.2 fixed *"assertion errors with provider unpause"* ([changelog](https://pub.dev/packages/flutter_riverpod/changelog)). A paused minute-ticker plus a Pen Board reached via a back-navigation is a plausible stale-timer bug. | High | Explicit test: pen a ewe, background the app for 5 minutes with a fake clock, foreground, assert the elapsed reading. Use `TickerMode` to control pausing if needed. |
| 7 | **`ensureInitialized()` before `runApp()` → splash flash** ([flutter#32736](https://github.com/flutter/flutter/issues/32736), [#39494](https://github.com/flutter/flutter/issues/39494)). Directly violates spec §5. | High | `main()` awaits nothing (§13). Launch background = app background on both platforms. |
| 8 | **Non-drift writes are invisible to streams.** *"Other uses of the database, e.g. a native SQLite client, will not trigger stream query updates."* One `customStatement` that mutates and the UI silently stops updating. | High | Ban `package:sqlite3` outside `core/db/`. If a raw statement is unavoidable, `notifyUpdates()` in the same method. |
| 9 | **Analyzer-plugin rot.** `dart_code_metrics` is discontinued and now commercial; `custom_lint` sits at 0.8.1 / 60 pub points. A gate that stops running is worse than no gate, because you stop looking. | Medium | Dependency-free script (§11.3). |
| 10 | **Migration without tests → unrecoverable data loss.** There is no cloud backup by design. | **Blocker** | `dart run drift_dev make-migrations` + generated schema tests, wired into CI as ship-blocking (§14.2). |
| 11 | **Draft state creeping back in.** The first `TextEditingController` held until a Save button is the moment "commits immediately" quietly becomes false. | High | No aggregate write method exists (§6.2); one widget test per entry screen asserting the row exists before any Done tap (§8.4). |
| 12 | **Double-tap duplicates.** Wet gloves double-fire. Two lambings for ewe 412 at 03:20. | High | `WriteController.guard` (§8.5); a `tester.tap(); tester.tap();` test per destructive action. |
| 13 | **A timer per row.** 30 pens × `Timer.periodic` = battery drain and staggered repaints. | Medium | One app-level ticker (§10.2). |
| 14 | **`Value.absent()` vs `Value(null)`.** In drift companions, `absent()` means "don't touch this column" and `Value(null)` means "write NULL". Confusing them makes "clear the birthweight" silently do nothing. | Medium | Repository-level named helpers (`clearBirthWeight()`), never raw companions above `data/`; test the clear path explicitly. |
| 15 | **Local `DateTime` in the DB.** UK/Ireland lambing spans the March DST change; local timestamps produce a one-hour discontinuity in every pen timer. | Medium | Store UTC instants (`clock.now().toUtc()`); convert at the presentation edge only. |
| 16 | **`DateTime.now()` / `CURRENT_TIMESTAMP` sneaking in.** Makes withdrawal countdowns untestable and defeats spec §12.5. | Medium | `package:clock` everywhere; text ban in `check_layers.dart` (§11.3). |
| 17 | **Transitive network dependency.** A future plugin pulls `http` or `connectivity_plus` and the app is no longer offline-only. | High | `tool/check_offline.dart` allowlist + merged-manifest grep (§12). |
| 18 | **Feature-to-feature imports.** Foster needs Ewe and Lambing; the easy move is `import '../flock/…'`. That is how a feature-first tree becomes a ball of mud in one season. | Medium | The sibling-import rule in `check_layers.dart` (§11.3); the shared piece goes to `data/` or `domain/`. |
| 19 | **Nullable view columns papered over with `?? 0`.** drift: *"expressions defined as an `Expression` getter are always nullable."* `?? 0` turns "no data" into "zero lambs", which is the app asserting something the user never said (§12.4). | Medium | Model absence as absence all the way to the widget; render "—". Lint the codebase for `?? 0` in `season/` and `flock/`. |
| 20 | **iOS background writes when the device is locked.** With `NSFileProtectionComplete`, SQLite writes fail (`disk I/O error`) and the app can be terminated with `0xdead10cc` for holding a file lock in the background — widely reported ([ccgus/fmdb#262](https://github.com/ccgus/fmdb/issues/262), [sqlcipher#255](https://github.com/sqlcipher/sqlcipher/issues/255)). | Medium (low probability, high impact) | Shed Book writes in the foreground only. **Never write to the DB from a notification-response handler or any background callback.** If that requirement ever appears, verify the data-protection class first. |
| 21 | **build_runner slowdown.** O(N²)-ish incremental behaviour ([build#3555](https://github.com/dart-lang/build/issues/3555)). Three generators on one package makes the edit loop painful. | Low-medium | One generator (drift). Keep `.g.dart` output confined to `core/db/`. |
| 22 | **Blocking the UI isolate on SQLite.** SQLite is synchronous; a large export on the UI isolate drops frames. | Medium | `NativeDatabase.createInBackground` (drift's own recommendation). |
| 23 | **`Provider<AppDatabase>` left unoverridden** in a test or a new entry point → a confusing null/late error. | Low | The provider throws `UnimplementedError` by default (§6.1) — fails loudly at wiring time. |

---

## 17. How this architecture serves the two hard constraints

**The 3am test (spec §5)**

- *Under 15 seconds, unlock → saved event.* Nothing is awaited in `main()`; the DB opens lazily; the first frame is the app's dark shell; a local indexed query returns in single-digit ms. There is no login, no sync, no spinner, and — critically — **no retry backoff** (Riverpod's default would have added up to double-digit seconds of silence on a disk error).
- *Assume the phone dies.* Draft state is unrepresentable, not merely discouraged. The row exists from the first tap. Worst-case loss is 400 ms of typing in a free-text field, and that number is written down.
- *Gloves and cold fingers.* The `WriteController.guard` double-tap gate is an architectural response to a physical problem. Big tap targets are UI; not creating two lambing records is architecture.
- *Head torch / darkness.* `ErrorWidget.builder` is replaced with a dark panel, because the framework default is a red-on-yellow flashbang. Launch background = app background, so there is no white frame anywhere in the boot path.
- *Zero interruptions.* No update prompts, no rating prompts, no notification-permission nags — structurally guaranteed by having no SDK that wants them.

**Offline-only (spec §4, §13)**

- Flutter's own "offline-first" guidance is explicitly rejected (§1.4) because it is a networking pattern. This is the most likely place for a well-intentioned engineer to reintroduce a socket.
- No crash reporter, no analytics, no remote config, no feature flags. The local ring-buffer log gives you the same diagnostic value through the export mechanism the app already has.
- The absence of a network is *checked*, not assumed: a `pubspec.lock` allowlist and a merged-manifest assertion, both in CI.
- One consequence to accept honestly: with no telemetry you will never know why a shepherd stopped using the app. The compensating mechanism is the diagnostics export plus direct contact with the forums named in spec §3.

---

## 18. Open questions

1. **Riverpod vs the official `provider` path** is the one decision here that a reasonable senior engineer could reverse. It hinges on how much hand-written `StreamSubscription` lifecycle you are willing to own. Decide it in week one; it is expensive to change in month three.
2. **Does the Riverpod 3 pause/resume behaviour keep the minute-ticker honest** across a 5-minute background? Needs a device test, not a reading of the docs (3.2.1 and 3.3.2 both shipped fixes in this area).
3. **Does `AppDatabase` construction really do zero IO** before the first query, given `drift_flutter`'s `path_provider` call? If not, `main()` needs `deferFirstFrame()` after all. Measure on a cold start on the oldest supported device.
4. **Freezer-bag capacitance** (spec §17.4) may force volume-button shortcuts. That would add a platform-channel service under `data/` and a global hardware-key route — worth confirming before the Quick Entry controller is written.
5. **Season boundary semantics.** "Delete a season" (§7.10) versus permanent birth-dam links (§7.3) is a referential-integrity decision that belongs to the schema topic but constrains `season_repository`.
6. **Free-tier cap enforcement** (15 ewes / one season, §14) — where does it live? Recommendation: a `data/`-layer guard on `FlockRepository.createEwe` returning a `WriteOutcome`, never a UI check. It must not degrade the 3am path, so it can never block an *existing* ewe's event entry.

---

## Sources

Fetched 2026-07-27. Versions and dates are as displayed on those pages on that date.

**Flutter official architecture**
- https://docs.flutter.dev/app-architecture
- https://docs.flutter.dev/app-architecture/concepts
- https://docs.flutter.dev/app-architecture/guide
- https://docs.flutter.dev/app-architecture/recommendations
- https://docs.flutter.dev/app-architecture/case-study
- https://docs.flutter.dev/app-architecture/case-study/dependency-injection
- https://docs.flutter.dev/app-architecture/design-patterns
- https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- https://docs.flutter.dev/app-architecture/design-patterns/sql
- https://docs.flutter.dev/app-architecture/design-patterns/result
- https://docs.flutter.dev/app-architecture/design-patterns/command

**Flutter framework / tooling**
- https://docs.flutter.dev/testing/errors
- https://docs.flutter.dev/tools/hot-reload
- https://docs.flutter.dev/deployment/android
- https://docs.flutter.dev/platform-integration/android/splash-screen
- https://docs.flutter.dev/data-and-backend/state-mgmt/options
- https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- https://api.flutter.dev/flutter/widgets/WidgetsBinding/deferFirstFrame.html
- https://github.com/flutter/flutter/issues/20789
- https://github.com/flutter/flutter/issues/31968
- https://github.com/flutter/flutter/issues/32736
- https://github.com/flutter/flutter/issues/39494

**Dart language / tooling**
- https://dart.dev/resources/language/evolution
- https://dart.dev/language/constructors
- https://dart.dev/language/dot-shorthands
- https://dart.dev/tools/pub/workspaces
- https://github.com/dart-lang/build/issues/3555

**Drift**
- https://drift.simonbinder.eu/docs/dart-api/select/
- https://drift.simonbinder.eu/dart_api/streams/
- https://drift.simonbinder.eu/dart_api/transactions/
- https://drift.simonbinder.eu/dart_api/rows/
- https://drift.simonbinder.eu/docs/dart-api/views/
- https://drift.simonbinder.eu/platforms/vm/
- https://drift.simonbinder.eu/generation_options/
- https://drift.simonbinder.eu/testing/
- https://drift.simonbinder.eu/Migrations/
- https://github.com/simolus3/drift/issues/574
- https://github.com/simolus3/drift/issues/3295
- https://github.com/simolus3/drift/issues/3338
- https://github.com/simolus3/drift/issues/3531

**Riverpod**
- https://riverpod.dev/docs/whats_new
- https://riverpod.dev/docs/3.0_migration
- https://riverpod.dev/docs/concepts2/auto_dispose

**SQLite**
- https://www.sqlite.org/lang_createview.html
- https://www.sqlite.org/gencol.html

**pub.dev package pages (versions read live on 2026-07-27)**
- https://pub.dev/packages/drift — 2.34.2, simonbinder.eu, ~12 days ago, Flutter Favorite, 2.44k likes / 160 pts / 1.03M downloads
- https://pub.dev/packages/drift/versions
- https://pub.dev/packages/drift/changelog
- https://pub.dev/packages/drift_flutter — 0.3.1, simonbinder.eu, ~16 days ago
- https://pub.dev/packages/sqflite — 2.4.3, tekartik.com, ~54 days ago (comparison only)
- https://pub.dev/packages/flutter_riverpod — 3.4.1, dash-overflow.net, ~2026-07-26
- https://pub.dev/packages/flutter_riverpod/changelog — 3.0.0 stable 2025-09-10
- https://pub.dev/packages/riverpod — 3.4.1
- https://pub.dev/packages/riverpod_generator — 4.0.6, 40 pub points
- https://pub.dev/packages/provider — 6.1.5+1, ~11 months ago, 11k likes
- https://pub.dev/packages/get_it — 9.2.1, ~5 months ago
- https://pub.dev/packages/go_router — 17.3.0, flutter.dev, ~54 days ago
- https://pub.dev/packages/go_router/versions
- https://pub.dev/packages/freezed — 3.2.5, ~5 months ago (4.0.0-dev.3 prerelease exists)
- https://pub.dev/packages/build_runner — 2.15.2, tools.dart.dev, ~14 days ago
- https://pub.dev/packages/melos — 8.2.2, invertase.io, ~13 days ago
- https://pub.dev/packages/flutter_lints — 6.0.0, flutter.dev, ~14 months ago
- https://pub.dev/packages/custom_lint — 0.8.1, invertase.io, ~10 months ago, 60 pub points
- https://pub.dev/packages/import_lint — 2.0.0, kawa.dev, ~3 months ago, 28 likes
- https://pub.dev/packages/dart_code_metrics — 5.7.6, **DISCONTINUED**
- https://pub.dev/packages/clock — 1.1.2, tools.dart.dev, ~21 months ago
- https://pub.dev/packages/sqlite3_test — 0.2.0, simonbinder.eu, ~8 months ago, 289 downloads
- https://pub.dev/packages/flutter_local_notifications — 22.2.0, dexterx.dev, ~2 days ago

**Leads verified against primary sources, not used as evidence on their own**
- https://codewithandrea.com/articles/flutter-project-structure/ (2022-03-23) — feature-first vs layer-first argument
- https://github.com/ccgus/fmdb/issues/262 and https://github.com/sqlcipher/sqlcipher/issues/255 — iOS data-protection / `0xdead10cc` reports
