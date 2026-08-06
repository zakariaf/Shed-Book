# 01 — Architecture

This document governs the shape of the codebase: which layers exist, which may import which, who is allowed to write to the database, what a write returns, what happens when one fails, and what `main()` does. It is the file every other document in this set links to instead of re-printing bootstrap or write-path code. Read it before you create `lib/`. Everything here is enforced by one script, `tool/check_policy.dart`, which runs on every push.

> **Decisions applied:** #6 MVVM two-layer with domain as plain functions · #7 Flutter's offline-first design pattern is rejected outright · #8 feature-first UI with shared `data/` + `domain/` · #9 eight dependency rules enforced by a dependency-free Dart script · #10 one source-scanning gate, not five · #11 event-verb write path, draft state unrepresentable · #12 drift `watch()` streams, one statement per screen, no `combineLatest` · #13 reads throw, writes return `WriteOutcome` · #14 global error net with a dark `ErrorWidget.builder`, no `runZonedGuarded`, no crash reporter · #15 concrete `final class` repositories, no abstract interfaces · #16 drift is the only code generator · #17/#19 `flutter_riverpod` 2.6.1 pinned exactly · #20 `databaseProvider` is a `FutureProvider` · #21 `main()` awaits nothing · #27 database in application support · #46 one ambient clock · #50 `clear_date` is the one stored derived value · #58 `StatResult`, never a bare nullable out of a view · #60 `customSelect` with explicit `readsFrom:` for aggregates · #63 reminder rows in the transaction, OS projection after it · #66 one app-level 60 s ticker · #91 the free-tier policy takes an `EntryContext` · #123 diagnostics are a local file, never a network sink.

**Names, paths and signatures are governed by [`CONVENTIONS.md`](CONVENTIONS.md)**, which outranks this document on any question of a name, a path, a type shape, a signature or a word — and which this document has been conformed to. It does not outrank this document on reasoning; §§1–8 below own the folder tree, the layer rules, `tool/check_policy.dart`, the error types and `main()`. Ruling numbers cited inline (`R12`, `R23`, …) are its §6.

Sibling documents: [`00-README.md`](00-README.md) (toolchain), [`02-state-di-navigation.md`](02-state-di-navigation.md) (providers, controllers, routing), [`03-data-model-and-schema.md`](03-data-model-and-schema.md) (tables), [`05-domain-correctness.md`](05-domain-correctness.md) (`Instant`, withdrawal, statistics), [`06-design-system.md`](06-design-system.md) (`lib/core/ui/`, the three feedback functions), [`08-platform-integration.md`](08-platform-integration.md) (the six gateways), [`12-testing.md`](12-testing.md), [`13-build-ci-release.md`](13-build-ci-release.md) (CI wiring, offline gates G0–G5).

---

## 1. The layer model for an app with no remote data source

### 1.1 What you are building

Two layers, exactly as Flutter's own guidance prescribes for a CRUD app, plus a domain **folder** that sits beside them rather than between them:

```
View            widgets, zero logic
  │   reads:  ref.watch(penBoardProvider)   → AsyncValue<List<PenTile>>
  │   writes: ref.read(penWriteControllerProvider.notifier).turnOut(...)
  ▼
Controller      presentation shaping only. No SQL, no drift types, no BuildContext in the write path.
  ▼
Repository      the only writer. Owns transactions. Concrete final class.
  │   ├─→ AppDatabase (drift)        ← the source of truth
  │   ├─→ NotificationScheduler      ← gateway
  │   ├─→ MediaStore                 ← gateway
  │   ├─→ ShareService               ← gateway
  │   └─→ CameraService · VoiceRecorder · WakelockController   ← gateways
  ▼
domain/         pure top-level functions and value types. Imported by repositories AND by controllers.
```

Flutter's guide pre-authorises skipping the logic layer: *"The logic layer is optional, and only needs to be implemented if your application has complex business logic… Many apps are only concerned with presenting data to a user and allowing the user to change that data."* Shed Book has real computation — withdrawal dates, lambing percentages, hours since penned — but all of it is stateless arithmetic with no injected dependencies. So it is **top-level functions in `lib/domain/`, never `class GetSeasonSummaryUseCase`** (decision #6).

### 1.2 What is dead, and why

Walk Flutter's official responsibilities and mark each one. This is the part most architectures get wrong by carrying over reflexes from networked apps.

| Official responsibility | Fate here | Why |
|---|---|---|
| Repository **caching** | Dead | SQLite *is* the cache. A second in-memory cache is a second source of truth and a guaranteed divergence bug. |
| Repository **retry** | Dead, and harmful | Disk-full, corrupt-file and permission-denied do not heal on retry. Retrying hides the failure past the spec's entire 15-second budget. |
| Repository **refresh / polling** | Dead | Nothing upstream changes. This app is the only writer of this file, ever. |
| A **`Service`** layer for data | Dead | Flutter defines a service as an API-endpoint wrapper. `AppDatabase` is already the data-source wrapper, and it is generated. A hand-rolled `DatabaseService` over drift is a layer that only forwards. |
| Separate **API models** and **domain models** | Dead | Flutter marks this "Conditional"; the condition is a wire format you do not control. You own the schema. |
| **Loading states** on reads | Nearly dead | An indexed local query over ≤400 ewes returns in single-digit milliseconds. A spinner for a local read is a 3am-test failure. The one real loading state is "the database is not open yet", which is the first frame (§6). |
| **`Result<T>` on every method** | Dead | ~100% of reads succeed and every failure has the same response. See §5.1. |
| **Abstract repository interfaces** | Dead (deliberate divergence from Flutter's "strongly recommend") | A real `NativeDatabase.memory()` is a better fake than a hand-written fake and cannot diverge from production. Twelve abstract classes with one implementation each, forever, is ceremony that also breaks "go to definition". Decision #15. |

### 1.3 What survives, and matters more

| Responsibility | Why it survives |
|---|---|
| Single source of truth | Eight entities with cross-cutting reads — Export touches all of them. One owner per table is what stops the season summary disagreeing with the ewe card. |
| Unidirectional data flow | **Strengthened**: with drift streams, UDF is enforced by the database rather than by convention. A write goes down; a table-change notification comes back up. There is no path that skips the file. |
| Repository as the only writer | Spec §5's "every write is committed immediately" is only checkable if there is exactly one place that writes. |
| Controllers keep logic out of widgets | Still true, still cheap. |
| Commands / write guards | Survive for a non-obvious reason: **double-tap protection**, not spinners. Cold wet fingers on capacitive glass double-fire, and a duplicated lambing insert is a record nobody notices until March. Owned by [`02-state-di-navigation.md`](02-state-di-navigation.md). |
| Immutable models | Free — drift generates immutable row classes with `==`, `hashCode`, `copyWith`. |
| DI | Survives as graph wiring, not as swappability. `ProviderScope` is the whole DI root. |

Six **gateways** remain — one hand-written class per platform seam, each wrapping exactly one plugin, each replaced by a hand-written fake in tests. "Gateway" is the collective noun for all six; "platform service" is a banned synonym (CONVENTIONS R71). They are `NotificationScheduler` (wraps `flutter_local_notifications` and `package:timezone`), `MediaStore` (writes photos and voice notes under the media root, returns relative paths), `ShareService` (hands a file to the system share sheet), `CameraService` (`image_picker`), `VoiceRecorder` (`record`) and `WakelockController` (`wakelock_plus`) — the last three named and homed by CONVENTIONS R9 and documented by [`08-platform-integration.md`](08-platform-integration.md). All six are side-effecting and non-transactional, which is exactly why they live behind repositories and never inside a `db.transaction` (§4.3).

### 1.4 What you are NOT doing: Flutter's `offline-first` design pattern

This is the single most important anti-regression note in the document. Keep it. A future contributor — or you, in month five — will search "flutter offline" and land on [Design patterns → Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first). It is titled as if it were written for this app. **It is not.**

That page's `UserProfileRepository` composes an `ApiClientService` (HTTP) with a `DatabaseService` (SQL). Every mechanism on it exists to reconcile the two:

- reading strategies: "local fallback", "stream-based" (yield local, then yield remote), "local-only with a manual `sync()`";
- writing strategies: "online-only (safest)" vs "offline-first (more permissive)";
- a `synchronized` boolean flag on the model;
- `Timer.periodic(const Duration(minutes: 5), (timer) => sync())`;
- recommended packages: `workmanager`, `connectivity_plus`, `battery_plus`, Firebase Cloud Messaging;
- caveats about battery drain, data conflicts, and sync frequency.

Every one of those is either a no-op or a violation here. There is no remote source, so there is nothing to reconcile: no sync flag, no sync timer, no connectivity check, and no reason whatsoever to link a package that can open a socket.

> **In Flutter's vocabulary, "offline-first" means "a networked app that degrades gracefully". Shed Book is *offline-only*, which is a different and much simpler architecture. Wherever a blog post or the docs say "offline-first", mentally substitute "sync engine", then delete it.**

This is not pedantry. An engineer following that page in good faith adds `connectivity_plus`, which merges `ACCESS_NETWORK_STATE` into the Android manifest and puts a platform channel in the app whose only job is to ask about a network the app must never use. That trips gate G1 in [`13-build-ci-release.md`](13-build-ci-release.md) and breaks the only claim the product makes about itself.

**Banned, and how CI catches it.** `connectivity_plus`, `workmanager`, `battery_plus`, `firebase_*`, `package:http`, `package:dio`, any `*_web_socket*`, `google_fonts`, `printing`, a `synchronized` column, and `Timer.periodic` used for anything resembling sync. In `tool/check_policy.dart` (§3.2) the `_bannedEverywhere` import set fails the build on the import and the `net.*` text rules fail it on the API call — including the three that arrive on no package import at all, `HttpClient`, `Socket.connect` and `Image.network`; the dependency allowlist fails it on the lockfile entry; the AAB permission assertion fails it on the merged manifest. Three independent gates, because this is the property the product is sold on. A `synchronized` column is not greppable and is a schema review item in [`03-data-model-and-schema.md`](03-data-model-and-schema.md).

---

## 2. The folder tree

### 2.1 Nine features for twelve screens

A feature is a functional requirement, not a screen. Twelve screens (spec §9) collapse to nine folders:

| Feature folder | Screens it owns |
|---|---|
| `quick_entry/` | 3. Quick Entry |
| `flock/` | 1. Flock · 2. Ewe Card |
| `lambing/` | 4. Lambing Entry · 5. Lamb Card · 6. Foster |
| `pens/` | 7. Pen Board |
| `treatments/` | 8. Treatments |
| `reminders/` | 9. Reminders |
| `season/` | 10. Season Summary |
| `export/` | 11. Export |
| `settings/` | 12. Settings |

Lamb Card and Foster live with Lambing because they share the birth-dam/rearing-dam invariant; splitting them puts that invariant in two places.

The layout is **feature-first UI over a shared `data/` and `domain/`** — Flutter's own Compass App hybrid (decision #8). The reason is specific: nobody owns `Ewe`. Quick Entry reads it, Lambing writes to it, the Pen Board joins it, Treatments references it, Export dumps all eight entities. Under pure feature-first, `features/export/` would import from eight sibling features, which is precisely the violation rule 6 exists to forbid.

### 2.2 The tree

```
shed_book/
├── pubspec.yaml                      # versions come only from 00-tech-decisions §5
├── pubspec.lock                      # COMMITTED — decision #5's evidence that this set resolves
├── analysis_options.yaml             # flutter_lints 6.0.0 + the explicit strict-* language block
├── build.yaml                        # NOT build.yml. databases: shed_book: lib/core/db/database.dart
│                                     # + override_hash_and_equals_in_result_sets: true (§4.4)
├── l10n.yaml                         # gen-l10n; ships en only
├── Makefile                          # gen · check · test · goldens
├── drift_schemas/                    # committed schema snapshots (generated, never hand-edited) — 04
│   └── drift_schema_v<N>.json
├── assets/
│   ├── fonts/                        # AtkinsonHyperlegibleNext[wght].ttf + OFL.txt
│   └── content/                      # authored prose too long to be a UI string + one
│                                     # provenance line per vocabulary list.  NOT the 40
│                                     # vocabulary labels — those are ARB messages (R66).
├── tool/
│   ├── check_policy.dart             # THE gate. §3.2. Zero dependencies. Not scanned by itself.
│   ├── policy_allowlist.txt          # [dependencies] [dev_dependencies] [transitive] [exempt]
│   ├── seed.dart                     # deterministic demo DB, written THROUGH the restore path
│   └── snapshot_to_backup.dart       # developer-run: pre-migration .sqlite → JSON backup
│
├── lib/
│   ├── main.dart                     # ~20 lines. §6. Awaits nothing. No overrides.
│   ├── app.dart                      # ShedBookApp: ConsumerStatefulWidget. Theme +
│   │                                 # post-frame boot kick + WidgetsBindingObserver.
│   │
│   ├── l10n/                         # (R67)
│   │   └── app_en.arb                # every user-facing string except ShedFailure.userMessage
│   │                                 # and Disclaimers.*; includes all 40 vocabulary labels
│   │
│   ├── domain/                       # L0 — PURE DART. No flutter, drift, riverpod, intl, CLOCK.
│   │   ├── ids.dart                  # the extension-type ids ONLY (R5). No package:uuid here.
│   │   ├── birth_type.dart           # enum BirthType + int code 1..5 + expectedLambCount()
│   │   ├── lambing_ease.dart         # extension type LambingEase(int) 1..5. NO descriptions (R44).
│   │   ├── sex.dart                  # enum Sex { female('f'), male('m'), unknown('unknown') }
│   │   ├── foster_outcome.dart       # sealed FosterOutcome (R64)
│   │   ├── penning.dart              # timeSincePenned(entered, now), isReadyToTurnOut(...)  (R24)
│   │   ├── tag_match.dart            # TagIndexEntry + rankTagMatches()  (R27)
│   │   ├── free_tier.dart            # EntryContext · CapDecision · RefusalReason (R69)
│   │   ├── reminder_budget.dart      # ReminderBudget.forPlatform() (R50)
│   │   ├── time/
│   │   │   ├── instant.dart          # extension type Instant(int epochMillis)
│   │   │   ├── local_date.dart       # extension type LocalDate._(String iso)
│   │   │   ├── partial_date.dart     # extension type PartialDate._(String iso)
│   │   │   ├── recorded_time.dart    # RecordedTime + enum TimeSource
│   │   │   └── wall_time.dart        # checkLocalWallTimeExists()
│   │   ├── units/
│   │   │   ├── grams.dart            # extension type Grams(int value)          (R17)
│   │   │   ├── milli_celsius.dart    # extension type MilliCelsius(int value)   (R17)
│   │   │   ├── weight_unit.dart      # enum WeightUnit { kg, lb }               (R68)
│   │   │   └── parse_number.dart     # parseUserNumber()
│   │   ├── withdrawal/               # SAFETY, spec §12.1
│   │   │   ├── withdrawal_period.dart  # sealed WithdrawalPeriod + enum WithdrawalTarget
│   │   │   ├── withdrawal_status.dart  # sealed WithdrawalStatus
│   │   │   └── clear_date.dart         # clearDateFor() · computeWithdrawalStatus()
│   │   ├── stats/
│   │   │   ├── definitions.dart      # StatResult · LambCount · FlockDenominator ·
│   │   │   │                         # LambingPercentageChoice · EweSeasonOutcome
│   │   │   ├── season_counts.dart    # SeasonCounts · DayBirths · LambOutcome · LambStatus
│   │   │   ├── lambing_percentage.dart · litter_size.dart · barren_rate.dart
│   │   │   ├── assisted_rate.dart · losses.dart · lambing_spread.dart
│   │   ├── validation/               # lib/data/ may NEVER import this folder (R53)
│   │   │   ├── warning.dart          # Warning · WarningCode · Reviewed<T>. No fix(). Spec §12.4.
│   │   │   ├── lambing_checks.dart   # + kPlausibleBirthWeight
│   │   │   ├── foster_checks.dart · treatment_checks.dart
│   │   ├── terminology/
│   │   │   ├── animal_class.dart     # enum AnimalClass — closed, stable keys
│   │   │   ├── term_label.dart       # TermLabel
│   │   │   └── terminology.dart      # Terminology
│   │   └── policy/
│   │       ├── disclaimers.dart      # abstract final class Disclaimers
│   │       ├── export_envelope.dart  # ExportEnvelope (R65)
│   │       └── content_policy.dart   # ContentPolicy
│   │
│   ├── core/                         # L1 — cross-cutting, knows no feature
│   │   ├── failure.dart              # sealed ShedFailure + its six variants
│   │   ├── write_outcome.dart        # sealed WriteOutcome + its three variants
│   │   ├── write_action.dart         # sealed WriteState + abstract base WriteController (R72)
│   │   ├── db/                       # (R1) — the ONLY layer that may say customStatement(
│   │   │   ├── database.dart         # kSchemaVersion + @DriftDatabase + class AppDatabase
│   │   │   ├── database.g.dart       # generated
│   │   │   ├── schema_versions.dart  # generated by `drift_dev schema steps`
│   │   │   ├── migrations.dart       # the from<N>To<N+1> bodies (the one hand-written file here)
│   │   │   ├── connection.dart       # openAppDatabase() · openConnection() ·
│   │   │   │                         # configureConnection() · _snapshotBeforeMigration()  (R12)
│   │   │   ├── converters.dart       # InstantConverter · LocalDateConverter ·
│   │   │   │                         # PartialDateConverter  — ONE FILE, not a folder (R21)
│   │   │   ├── uid.dart              # String newUid() — the only package:uuid call site (R15)
│   │   │   ├── diagnostics_snapshot.dart  # VACUUM INTO
│   │   │   ├── views.drift           # CREATE VIEW + the non-search table triggers   (R22)
│   │   │   ├── search.drift          # search_docs · search_fts · the FTS5 triggers  (R22)
│   │   │   ├── queries.drift         # named queries: penBoard, inThePens, sweepSearchDocs, …
│   │   │   ├── tables/               # one file per cluster; common.dart holds mixin Identified
│   │   │   └── seed/
│   │   │       └── first_run.dart    # seedFirstRun(AppDatabase)
│   │   ├── time/
│   │   │   ├── app_clock.dart        # Instant appNow(). The ONE allowlisted DateTime.now( site.
│   │   │   └── ticker.dart           # minuteTickProvider (R25)
│   │   ├── log/
│   │   │   ├── local_log.dart        # LocalLog.instance — the one static singleton in lib/
│   │   │   └── redaction.dart        # the allowed / forbidden field lists — see 13
│   │   └── ui/
│   │       ├── primitives.dart       # raw hexes + raw scales. Imported ONLY inside lib/core/ui/.
│   │       ├── tokens.dart           # ShedTokens · ShedPalette · ShedPaletteId · context.tokens
│   │       ├── palettes.dart         # the six authored (ColorScheme, ShedTokens) pairs
│   │       ├── theme.dart            # ShedThemeSet · buildShedTheme · buildShedTextTheme
│   │       ├── motion.dart           # prefersReducedMotion
│   │       ├── formatters.dart       # the ONLY package:intl call site in lib/ outside lib/data/
│   │       ├── feedback.dart         # confirmSaved · showFailure · showCapRow  (R30)
│   │       ├── night_error_panel.dart# ErrorWidget.builder. Hard-coded hexes, own Directionality.
│   │       └── components/           # ShedTapTarget, ShedKeypad, ShedPenTile, ShedReceiptBar,
│   │                                 # ShedBanner, ShedEmptyState, ShedPhoto, ShedCountdown, …
│   │
│   ├── data/                         # L2 — the ONLY code that writes. FLAT: no subfolders (R18).
│   │   ├── models.dart               # re-exports the drift ROW types only (§2.3)
│   │   ├── providers.dart            # the DI graph: database, repositories, gateways
│   │   ├── failure_mapping.dart      # shedFailureFrom(Object) — SqliteException → ShedFailure
│   │   ├── import_defaults.dart      # const importDefaults
│   │   ├── media_limits.dart         # kVoiceNoteMaxSeconds and the other media caps
│   │   ├── flock_repository.dart · lambing_repository.dart · foster_repository.dart
│   │   ├── pen_repository.dart · treatment_repository.dart · reminder_repository.dart
│   │   ├── season_repository.dart · settings_repository.dart · note_repository.dart
│   │   ├── entitlement_repository.dart · export_repository.dart
│   │   ├── restore_service.dart · media_sweeper.dart
│   │   ├── notification_scheduler.dart   # the ONLY package:timezone call site (R48)
│   │   ├── reminder_reconciler.dart      # ReminderReconciler.reconcile()
│   │   ├── media_store.dart · share_service.dart
│   │   ├── camera_service.dart · voice_recorder.dart · wakelock_controller.dart   (R9)
│   │
│   ├── features/                     # L3 — UI, feature-first. Siblings never import siblings.
│   │   ├── quick_entry/  {quick_entry_screen.dart, quick_entry_controller.dart,
│   │   │                  quick_entry_write_controller.dart, widgets/}
│   │   ├── flock/        {flock_*, ewe_card_*, note_search_*, widgets/}
│   │   ├── lambing/      {lambing_entry_*, lamb_card_*, foster_*, widgets/}
│   │   ├── pens/ · treatments/ · reminders/ · season/ · export/ · settings/
│   │   └── (each: <name>_screen.dart, <name>_controller.dart,
│   │              <name>_write_controller.dart, widgets/)
│   │
│   └── routing/
│       └── routes.dart               # RouteNames (13) + Routes (12 push helpers)
│
├── test/
│   ├── domain/                       # pure unit tests — the thickest tier
│   │   └── uk_zone/                  # @Tags(['uk-zone']) — DST-1 … DST-5
│   ├── data/                         # repositories against NativeDatabase.memory()
│   ├── drift/                        # migration tests
│   │   └── generated/                # GENERATED helpers — never hand-edited
│   ├── design/                       # wcag.dart · contrast_test.dart · tap_target_test.dart
│   │                                 # · semantics_gate_test.dart · reduce_motion_test.dart
│   ├── features/                     # widget tests: the 252-cell overflow matrix (R58),
│   │                                 # tap budgets, monetization
│   ├── policy/                       # spec §12 as executable assertions
│   ├── support/                      # harness.dart + the seven hand-written fakes + seeds.dart
│   │                                 # · reads.dart · flock_generator.dart
│   │                                 # · tolerant_comparator.dart   (12 §5.3)
│   └── fixtures/                     # flock_400_3seasons.json · flock_15_at_cap.json
└── integration_test/                 # four journeys, nightly, non-blocking  (R57)
```

The shared components under `lib/core/ui/components/` are [`06-design-system.md`](06-design-system.md)'s inventory, not this document's: `ShedKeypad` in particular is shared rather than a Quick Entry widget, because Lambing Entry, Treatments and Settings all need the same pad and rule 6 forbids a sibling import (R70). There is no `features/quick_entry/widgets/big_keypad.dart`.

Create it:

```bash
mkdir -p lib/l10n \
         lib/domain/{time,units,withdrawal,stats,validation,terminology,policy} \
         lib/core/{db/{tables,seed},time,log,ui/components} \
         lib/data lib/routing \
         lib/features/{quick_entry,flock,lambing,pens,treatments,reminders,season,export,settings}/widgets \
         tool drift_schemas assets/{fonts,content} \
         test/{domain/uk_zone,data,drift/generated,design,features,policy,support,fixtures} \
         integration_test
```

### 2.3 `lib/data/models.dart` — the one file that makes rule 5 greppable

drift generates row classes *inside* `lib/core/db/database.dart`. If `features/` imported that file it would also get `AppDatabase`, `Value`, every companion and the whole query builder. One re-export file fixes that:

```dart
// lib/data/models.dart
//
// The UI sees ROWS. It never sees AppDatabase, Value, companions or the query
// builder. This file is the reason `lib/features/** may not import core/db/`
// is a rule you can grep for rather than a rule you have to trust.
export 'package:shed_book/core/db/database.dart'
    show Season, Ewe, EweSeason, Lambing, Lamb, FosterEvent, CareEvent, EweObservation,
         Pen, PenOccupancy, PenOccupancyLamb, Treatment, TreatmentWithdrawal,
         Reminder, ReminderRule, Note, MediaAsset, VocabTerm, TerminologyOverride,
         AppSetting, Entitlement, EweTouch, EweSummary;
```

It exports **every** row class and only row classes — all 23 (R20). A partial list is worse than none: `Note`, `MediaAsset`, `TreatmentWithdrawal`, `AppSetting`, `VocabTerm`, `EweSeason` and `EweSummary` are all rendered by screens, and `lib/features/` cannot import `lib/core/db/` to reach them.

**Three of those names only exist if you ask for them.** drift derives a row class name by dropping one trailing `s` from the table class, so `PenOccupancies` generates `PenOccupancie`, `EweTouches` generates `EweTouche` and `EweSummaries` generates `EweSummarie`. Four tables therefore carry an explicit annotation in [`03-data-model-and-schema.md`](03-data-model-and-schema.md) — the three broken ones plus `AppSettings`, annotated for explicitness because `settingsProvider` is typed on the row class — and this export list will not compile without them (R7 + R20):

```dart
@DataClassName('PenOccupancy')
class PenOccupancies extends Table with Identified { … }

@DataClassName('EweTouch')
class EweTouches extends Table { … }

@DataClassName('EweSummary')
class EweSummaries extends Table { … }

@DataClassName('AppSetting')
class AppSettings extends Table { … }
```

Every other table in the schema de-pluralises correctly (`Lambings` → `Lambing`, `Ewes` → `Ewe`, `CareEvents` → `CareEvent`). Check the generated name whenever a new table ends in anything other than a plain `s`.

### 2.4 Two structural rules with no exceptions

- **No `lib/src/`.** It is a package-authoring convention whose only real payoff — `implementation_imports` blocking other packages — is irrelevant to an application binary. Adopt it only if §8 ever fires.
- **One package.** No pub workspace, no melos, no separate pure-Dart domain package for v1. §8 states the exact test for when that changes and why it has not fired.

**Anti-patterns.** A `shared/` or `common/` folder under `features/` (that is layer-first wearing a costume — the shared thing belongs in `data/` or `domain/`). A `utils.dart`. A `constants.dart` holding colours (tokens live in `core/ui/`, decision #97). A `models/` folder duplicating drift rows. `lib/features/<f>/data/` — there is no per-feature data layer; if you are tempted, the query belongs on a repository. CI catches the sibling import and the `core/db` import; it cannot catch a badly named folder, so that is a review item.

---

## 3. The eight dependency rules and the one gate

### 3.1 The rules

| # | From | May import | May never import | Failure it prevents | Rule id |
|---|---|---|---|---|---|
| 1 | `lib/domain/` | `lib/domain/`, `dart:*`, `meta`, `collection` | `package:flutter/*`, `package:drift/*`, `package:*riverpod/*`, `package:sqlite3*`, `package:intl/*`, **`package:clock/*`** (R24), every other layer | Safety-critical arithmetic (withdrawal, statistics) acquiring a `BuildContext`, a locale, a row type **or a clock** — and becoming untestable, locale-dependent or time-dependent. A domain function that needs the current instant takes it as a parameter: `timeSincePenned(enteredAt, now)` | `layer.domain` |
| 2 | `lib/core/db/` | `lib/core/db/`, **`lib/core/`** (R16), `lib/domain/`, `package:drift/*`, `package:sqlite3*`, **`package:uuid`** (R15), `package:clock`, `package:flutter/foundation.dart` | `lib/data/`, `lib/features/`, `lib/core/ui/`, `package:flutter/material.dart` | The schema depending on a repository or a widget, which makes migrations un-reviewable in isolation. `lib/core/` is allowed because `seed/first_run.dart` must call `appNow()` and `connection.dart` must reach `LocalLog`; `lib/core/ui/` matches first in `_layers` and stays banned | `layer.core_db` |
| 3 | `lib/data/` | `lib/data/`, `lib/core/*`, `lib/domain/` **except `lib/domain/validation/`** (R53), `package:drift/*`, `package:sqlite3*` (exception types only), `package:clock`, `package:collection`, `package:intl`, `package:timezone` | `lib/features/`, `lib/domain/validation/` | A repository reaching up into a screen — the cycle that makes "who writes this row" unanswerable. `package:uuid` is gone: `newUid()` lives in `lib/core/db/uid.dart` and is the app's one call site (R15) | `layer.data` |
| 4 | `lib/data/` | — | `package:flutter/material.dart`, `package:flutter/cupertino.dart` | A repository learning about `Color`, `TimeOfDay` or `BuildContext`, and a formatting decision leaking into a stored value | `layer.data_no_material` |
| 5 | `lib/features/` | own feature, `lib/data/`, `lib/domain/`, `lib/core/`, `lib/core/ui/`, `lib/routing/` | `lib/core/db/`, `package:drift/*`, `package:sqlite3*` | A widget opening a transaction, and the UI coupling to companions and the query builder | `layer.features` |
| 6 | `lib/features/<a>/` | — | `lib/features/<b>/` | The one rule that rots first. Foster needs Ewe and Lambing; the easy move is `import '../flock/…'`, and that is how a feature-first tree becomes a ball of mud in one season | `layer.sibling` |
| 7 | `lib/core/ui/` | `lib/core/ui/`, `lib/domain/`, `package:flutter/*`, `package:intl` (in `formatters.dart` only) | `lib/data/`, `lib/core/db/`, `package:drift/*` | A shared widget acquiring a repository, so it can no longer be rendered in a golden test or an error panel | `layer.core_ui` |
| 8 | anything outside `lib/data/` | — | any mutating drift API; `customStatement(` outside `lib/core/db/`; `package:sqlite3` outside `lib/data/` + `lib/core/db/` | Two writers. Also: a raw statement bypasses drift's stream tracking, so the UI silently stops updating — drift's docs are explicit that *"other uses of the database… will not trigger stream query updates"* | `layer.single_writer` |

Plus the root: **`lib/main.dart` and `lib/app.dart` may not import `lib/core/db/`, `package:drift/*` or `package:sqlite3*`.** The database is opened by a provider in `lib/data/providers.dart`, not by the entry point (rule id `layer.root`).

And one **path-pair** ban that is not a layer ban, because `lib/data/` may import the rest of `lib/domain/` freely: **`lib/data/** may never import `lib/domain/validation/**`** (rule id `layer.data_no_validation`, R53). It is the structural mechanism behind spec §12.4 — a repository that cannot see a `Warning` cannot invent one, so warnings are the controller's job and only the controller's. It is checked by its own row in §3.2's driver, not by `_mayImport`.

**`lib/routing/` and `lib/features/` import each other, deliberately.** Routing needs each screen's class; every screen needs `Routes.eweCard(context, id)`. That two-way edge does not defeat rule 6, because rule 6 only fires when the *importing* file is under `lib/features/` — a feature still cannot name a sibling, and routing is the one file allowed to name all nine. Keep `routes.dart` free of anything but `Navigator` calls and screen constructors; the moment it holds logic it becomes a tenth feature that every feature depends on.

Why a script and not an analyzer plugin: a package boundary expresses rule 1 and nothing else; the other seven are intra-package. And every analyzer-based tool that could express them is unavailable on this stack — `import_lint` 2.0.0 declares `analyzer ^12.1.0` against `drift_dev`'s `^13.0.0` and is unresolvable, `custom_lint`'s upstream repository was archived 2026-03-24, `dart_code_metrics` is discontinued and relicensed commercially. A gate that stops running is worse than no gate, because you stop looking.

### 3.2 `tool/check_policy.dart` — one script, one allowlist, one exit code

It subsumes four gates that the research notes proposed separately: layer rules, banned text, design tokens, and the dependency allowlist (decision #10). Every other document in this set **adds rows to its rule tables**; no document adds a second script.

**Two walkers, not one — amended at N31-T02 and N33-T05.** As first published, `main()` skipped
every file not ending `.dart`, so `10-accessibility-and-i18n.md` §10's `copy.arb_domain_noun` and
`05-domain-correctness.md` §7.3's `ContentPolicy` ARB half had **nothing to run against** — both
claimed to cover `lib/l10n/*.arb` and both scanned zero bytes. The gate now carries a second reader
that decodes `lib/l10n/*.arb` and yields each non-`@`-prefixed message value.

It is deliberately a *separate* reader. JSON has no adjacent-string-literal problem, so 05's
join-before-matching rule belongs to the Dart half alone; copying it onto the ARB half would
concatenate unrelated messages and match across the join. And the generated
`lib/l10n/app_localizations*.dart` is in the skip list beside `*.g.dart` and `*.drift.dart` — it is
generated, it is committed, its name matches neither existing pattern, and every rule that fires on
it is firing on the ARB a second time.

**Rule tables.** These are the file's first hundred lines and they are the file's documentation. Adding a rule is adding a row; nothing else in the file changes:

```dart
// tool/check_policy.dart
//
// The single source-and-dependency gate for Shed Book.
//   dart tool/check_policy.dart
// Exit codes: 0 clean · 1 violations · 2 the gate could not run (still a failure).
//
// Dependency-free by decision (00-tech-decisions #9, #10): every analyzer plugin
// that could express these rules is discontinued, archived, or unresolvable
// against drift_dev's analyzer ^13.0.0.

import 'dart:io';

const _package = 'shed_book';

/// Most specific prefix first — _layerOf returns the first match.
const _layers = <String>[
  'lib/core/db/', 'lib/core/ui/', 'lib/core/', 'lib/domain/',
  'lib/data/', 'lib/features/', 'lib/routing/', 'lib/',
];

const _mayImport = <String, Set<String>>{
  'lib/domain/':   {'lib/domain/'},
  'lib/core/db/':  {'lib/core/db/', 'lib/core/', 'lib/domain/'},   // R16
  'lib/core/ui/':  {'lib/core/ui/', 'lib/domain/'},
  'lib/core/':     {'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
  'lib/data/':     {'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
  'lib/features/': {'lib/features/', 'lib/data/', 'lib/domain/', 'lib/core/',
                    'lib/core/ui/', 'lib/routing/'},
  'lib/routing/':  {'lib/routing/', 'lib/features/', 'lib/data/', 'lib/core/', 'lib/domain/'},
  'lib/':          {'lib/', 'lib/core/', 'lib/core/ui/', 'lib/data/', 'lib/domain/',
                    'lib/features/', 'lib/routing/'},
};

const _bannedPackages = <String, Set<String>>{
  // R24: package:clock is banned in the domain. A pure function that needs the
  // current instant takes it as a parameter.
  'lib/domain/':   {'package:flutter/', 'package:drift/', 'package:sqlite3',
                    'package:flutter_riverpod/', 'package:riverpod/', 'package:intl/',
                    'package:clock/'},
  'lib/data/':     {'package:flutter/material.dart', 'package:flutter/cupertino.dart'},
  'lib/core/ui/':  {'package:drift/', 'package:sqlite3'},
  'lib/features/': {'package:drift/', 'package:sqlite3'},
  'lib/routing/':  {'package:drift/', 'package:sqlite3'},
  'lib/':          {'package:drift/', 'package:sqlite3'},
};

/// Path-pair bans: (id, importing prefix, imported prefix). Not expressible in
/// _mayImport, because lib/data/ may import the rest of lib/domain/ freely.
const _bannedPathPairs = <(String, String, String)>[
  ('layer.data_no_validation', 'lib/data/', 'lib/domain/validation/'),
];

/// G3 of the offline contract. Applies to every scanned file.
const _bannedEverywhere = <String>{
  'package:http/', 'package:dio/', 'package:connectivity_plus/', 'package:workmanager/',
  'package:battery_plus/', 'package:web_socket_channel/', 'package:firebase_',
  'package:google_fonts/', 'package:printing/', 'package:speech_to_text/',
  'package:google_mlkit_', 'package:permission_handler/',
};

/// (id, literal text, path prefix it applies under, why)
///
/// The network rows are not redundant with _bannedEverywhere. That set matches
/// `package:` URIs, and the three highest-risk socket APIs in this app do not
/// arrive on one: HttpClient and Socket come from dart:io, which every file may
/// legitimately import, and Image.network is in the Flutter SDK. G3 claims our
/// own source cannot reach a network API; without these rows it is not proved.
const _bannedText = <(String, String, String, String)>[
  ('net.http_client',   'HttpClient(',         'lib/',  'dart:io socket — G3'),
  ('net.socket',        'Socket.connect(',     'lib/',  'dart:io socket — G3'),
  ('net.image_network', 'Image.network(',      'lib/',  'no remote assets — G3'),
  ('net.pdf_fonts',     'PdfGoogleFonts',      'lib/',  'fetches fonts over HTTP — G3, #83'),
  ('net.sync_timer',    'Timer.periodic(',     'lib/',
                        'per-row timers and sync loops are both banned; the one ticker uses '
                        'Future.delayed so this rule needs no exemption — #66, #7'),
  ('time.dart_clock',   'DateTime.now(',       'lib/',  'use appNow() — #46, R23'),
  ('time.sql_now_1',    "date('now')",         'lib/',  'no SQL-side time — #47'),
  ('time.sql_now_2',    "datetime('now')",     'lib/',  'no SQL-side time — #47'),
  ('time.sql_now_3',    'CURRENT_TIMESTAMP',   'lib/',  'no SQL-side time — #47'),
  ('time.sql_now_4',    'CURRENT_DATE',        'lib/',  'no SQL-side time — #47'),
  ('time.sql_now_5',    'CURRENT_TIME',        'lib/',  'no SQL-side time — #47'),
  ('rp3.retry',         'retry:',              'lib/',  'Riverpod-3 API; will not compile on 2.6.1 — #18'),
  ('rp3.container_test','ProviderContainer.test(', 'lib/', 'Riverpod-3 API — #18'),
  ('rp3.tester_container', 'tester.container',  'test/', 'Riverpod-3 API — #18'),
  ('rp3.mutation',      'Mutation<',           'lib/',  'Riverpod-3 experimental API — #18'),
  ('rp3.value_or_null', '.valueOrNull',        'lib/',  'Riverpod-3 API — #18'),
  ('rp3.state_provider','StateProvider',       'lib/',  'legacy/3.x provider — #18'),
  ('rp3.state_notifier','StateNotifierProvider','lib/', 'legacy/3.x provider — #18'),
  ('stream.combine',    'combineLatest',       'lib/',  'torn state across drift streams — #12'),
  // NARROWED 2026-08-02 (N12). A substring row fired on the two invalidates the
  // architecture MANDATES, so it lives in the pattern family now. See §4.4.
  ('stream.invalidate', RegExp(r'ref\.invalidate\((?!minuteTickProvider\)|databaseProvider\))'),
                                               'lib/',  'drift tracks tables; manual invalidation is a stale read — #12'),
  ('db.raw_statement',  'customStatement(',    'lib/data/', 'bypasses stream tracking — rule 8'),
  ('stat.zero_default', '?? 0',                'lib/features/season/', 'unknown is not zero — #58'),
  ('stat.zero_default2','?? 0',                'lib/features/flock/',  'unknown is not zero — #58'),
  ('a11y.scale_factor', 'textScaleFactor',     'lib/',  'deprecated; never clamp — #99'),
  ('a11y.header_bool',  'header: true',        'lib/',  'no-op since 3.44 — use headingLevel — #104'),
  ('gesture.dismissible','Dismissible(',       'lib/',  'gesture ban — #101'),
  ('gesture.draggable', 'Draggable(',          'lib/',  'gesture ban — #101'),
  ('gesture.tooltip',   'Tooltip(',            'lib/',  'gesture ban — #101'),
  // R55: scoped to lib/, not lib/features/ — lib/core/ui/components/ is exactly
  // where a shared widget would hide a raw hex. The two [exempt] lines are the
  // only escape.
  ('token.raw_color',   'Color(0x',            'lib/',  'read ShedTokens — #97'),
  ('token.material_color','Colors.',           'lib/',  'read ShedTokens — #97'),
  ('main.no_await',     'await ',              'lib/main.dart', 'main() awaits nothing — #21'),
];
```

**Scanned roots: `lib/` and `test/`.** Two rules in the table above (`rp3.tester_container`, and any future Riverpod-3 spelling that only ever appears in a test) are scoped to `test/` and are dead weight unless the driver walks it — decision #18 requires CI to grep for every banned Riverpod-3 API, and `WidgetTester.container` appears nowhere else. Layer *direction* rules apply only under `lib/`; test files get banned text and banned packages. **`tool/` is deliberately not scanned**: this file's own rule tables contain every banned literal, so scanning it would fail the build on itself.

**The driver.** Walk the roots, skip generated files, apply the rules, then check the lockfile:

```dart
const _roots = <String>['lib', 'test'];

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Null for anything outside lib/ — layer direction does not apply there.
String? _layerOf(String path) {
  for (final layer in _layers) {
    if (path.startsWith(layer)) return layer;
  }
  return null;
}

/// 'lib/features/flock/flock_screen.dart' + '../../data/models.dart'
///   → 'lib/data/models.dart'
String _resolveRelative(String from, String uri) {
  final parts = from.split('/')..removeLast();
  for (final seg in uri.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

void main(List<String> args) {
  final v = <String>[];
  final allow = _readAllowlist();             // exits 2 if the file is missing
  final exempt = allow['exempt'] ?? const <String>{};

  for (final root in _roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final from = e.path.replaceAll(r'\', '/');
      if (from.endsWith('.g.dart') || from.endsWith('.drift.dart')) continue;
      final src = e.readAsStringSync();
      final layer = _layerOf(from);           // null under test/

      for (final (id, text, under, why) in _bannedText) {
        if (!from.startsWith(under) || !src.contains(text)) continue;
        if (exempt.contains('$from :: $id')) continue;
        v.add('[$id] $from contains "$text" — $why');
      }

      for (final m in _directive.allMatches(src)) {
        var uri = m.group(1)!;

        for (final b in {..._bannedEverywhere, ...?_bannedPackages[layer]}) {
          if (uri.startsWith(b) && !exempt.contains('$from :: import:$uri')) {
            v.add('[layer.import] $from (${layer ?? 'test'}) may not import $uri');
          }
        }
        if (layer == null) continue;          // no layer direction outside lib/

        if (uri.startsWith('package:$_package/')) {
          uri = 'lib/${uri.substring('package:$_package/'.length)}';
        } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
          continue;
        } else {
          uri = _resolveRelative(from, uri);
        }

        for (final (id, fromPrefix, toPrefix) in _bannedPathPairs) {
          if (from.startsWith(fromPrefix) && uri.startsWith(toPrefix)) {
            v.add('[$id] $from may not import $uri');
          }
        }

        final to = _layerOf(uri);
        if (to == null) continue;
        if (!_mayImport[layer]!.contains(to)) {
          v.add('[layer.direction] $from ($layer) may not import $to  [$uri]');
        }
        if (layer == 'lib/features/' && to == 'lib/features/') {
          final a = from.split('/')[2], b = uri.split('/')[2];
          if (a != b) {
            v.add('[layer.sibling] $from: feature "$a" may not import feature "$b" — '
                  'move the shared piece into lib/data/ or lib/domain/');
          }
        }
      }
    }
  }

  v.addAll(_checkLockfile(allow));            // dependencies and dev_dependencies, separately

  if (v.isEmpty) {
    stdout.writeln('policy ok');
    return;
  }
  for (final line in v..sort()) {
    stderr.writeln('POLICY  $line');
  }
  exit(1);
}
```

**The allowlist reader** returns every section, because the lockfile check needs three of them and the per-file waivers need a fourth. There is one file and one parser:

```dart
/// tool/policy_allowlist.txt — `[section]` headers, one entry per line,
/// `#` starts a comment. Missing file is exit 2: a gate that cannot read its
/// own configuration has not passed, it has failed to run.
Map<String, Set<String>> _readAllowlist() {
  final f = File('tool/policy_allowlist.txt');
  if (!f.existsSync()) {
    stderr.writeln('POLICY  tool/policy_allowlist.txt is missing');
    exit(2);
  }
  final out = <String, Set<String>>{};
  var section = '';
  for (var line in f.readAsLinesSync()) {
    line = line.split('#').first.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      section = line.substring(1, line.length - 1);
      out[section] = <String>{};
      continue;
    }
    out[section]?.add(line);
  }
  return out;
}
```

`_checkLockfile` parses `pubspec.lock` itself — no YAML package, because the gate has no dependencies. The lockfile's shape makes this trivial: a two-space-indented package name, then `dependency: "direct main"` / `"direct dev"` / `transitive`. **The three kinds are checked against three separate allowlist sections**, because `build_runner` legitimately drags `shelf` and `web_socket_channel` into the graph as dev-only, and an undifferentiated allowlist fails on day one.

```dart
const _sectionFor = <String, String>{
  'direct main': 'dependencies',
  'direct dev': 'dev_dependencies',
  'transitive': 'transitive',
};

List<String> _checkLockfile(Map<String, Set<String>> allow) {
  final lock = File('pubspec.lock');
  if (!lock.existsSync()) {
    stderr.writeln('POLICY  no pubspec.lock — run flutter pub get');
    exit(2);
  }
  final kinds = <String, String>{};
  String? current;
  for (final line in lock.readAsLinesSync()) {
    final pkg = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
    if (pkg != null) { current = pkg.group(1); continue; }
    final dep = RegExp(r'^    dependency: "?([a-z ]+)"?$').firstMatch(line);
    if (dep != null && current != null) kinds[current] = dep.group(1)!;
  }
  return [
    for (final MapEntry(key: name, value: kind) in kinds.entries)
      if (!(allow[_sectionFor[kind] ?? ''] ?? const <String>{}).contains(name))
        '[dep.${kind.replaceAll(' ', '_')}] $name is not on the allowlist — '
        'read its pubspec, confirm it opens no socket and merges no permission, '
        'then add it to tool/policy_allowlist.txt',
  ];
}
```

The `^  ([a-z0-9_]+):$` anchor is why the `sdks:` block at the foot of the lockfile is skipped for free: its entries carry a value on the same line, so they never match.

**`tool/policy_allowlist.txt`** is the one allowlist, sectioned, comments with `#`:

```
[dependencies]        # direct main — every line was reviewed against 00-tech-decisions §5.1
drift
drift_flutter
sqlite3
flutter_riverpod
...

[dev_dependencies]    # direct dev — never shipped
drift_dev
build_runner
...

[transitive]          # documented, with the reason
http                  # via timezone and via package_info_plus. Unavoidable. See §3.4 of the decisions.
sqlite3_flutter_libs  # no-op EOL shim dragged in by drift_flutter. Expected. Not discontinued on pub.dev.
...

[exempt]              # per-file rule waivers. Each line needs a reason in the commit message.
lib/core/time/app_clock.dart       :: time.dart_clock
lib/core/ui/night_error_panel.dart :: token.raw_color
lib/core/ui/primitives.dart        :: token.raw_color
lib/core/ui/palettes.dart          :: token.primitives_import
```

Exactly four exemptions exist on day one and all four are principled (R56): `app_clock.dart` is the single allowlisted home of `DateTime.now(` (decision #46); `night_error_panel.dart` hard-codes `#0B0D0E` because it must render outside any `Theme` (§5.5); `primitives.dart` is by definition the file that holds the raw hexes; and `palettes.dart` is the one file allowed to import it. The last two arrive with [`06-design-system.md`](06-design-system.md), which owns `lib/core/ui/`. A fifth is a review conversation.

### 3.3 How it runs

```bash
dart tool/check_policy.dart          # ~2.5 s, no Flutter needed, no network

# NOT `dart run`. Measured 2026-08-01 (N03-T01): the `run` subcommand performs
# an implicit `pub get` and executes the package's build hooks, so on a cold
# hook cache with the network away it fails at a pub.dev advisories fetch —
# which is precisely the failure decision #9/#10 exist to prevent. Without
# `run` it exits 0 on the same tree. The ~2.5 s is JIT startup; the walk itself
# is milliseconds.
```

It is run from the repository root — `Directory('lib')`, `Directory('test')` and `File('pubspec.lock')` are all relative — and it must run **before** `flutter pub get` has been forgotten, because a missing lockfile is exit 2.

- **CI**, every push and PR, on `ubuntu-latest`, as its own step before the test job, so a layer violation fails in seconds rather than after the suite. It runs after `flutter pub get` (it reads `pubspec.lock`) and before `dart format` and `flutter analyze`, so the cheapest failure reports first. See [`13-build-ci-release.md`](13-build-ci-release.md).
- **Pre-push hook**, `.git/hooks/pre-push`, one line. Optional locally; not optional in CI.
- **`make check`** runs this first, then the two document validators, then `dart format --set-exit-if-changed`, then `flutter analyze --fatal-infos`. Cheapest failure first: the gate is ~2.5 s (~~sub-second~~ — struck 2026-08-01, measured), `analyze` is tens of seconds.

**Anti-patterns.** Spelling the invocation `dart run` — see the comment above; it reintroduces the dependency the script does not have. Adding a second scanning script (decision #10 — put the row in this table instead). Weakening a rule because it produced a false positive (add a line to `[exempt]` with a reason; an exemption is reviewable, a deleted rule is invisible). Banning bare `strftime` or `datetime` — they false-positive on legitimate SQL and get weakened, which is why decision #47 excludes them. Making the gate depend on a package: the moment it needs `pub get` it can fail for reasons that are not violations.

---

## 4. The single write path

### 4.1 Repositories

`lib/data/` is the only layer that writes. No widget, controller, or `domain/` function may open a transaction. Repositories are **concrete `final class`es** with no interface (decision #15); they are constructed once, in `lib/data/providers.dart`; they take an `AppDatabase` and, where relevant, gateways. The set is **twelve and closed** (R19), flat in `lib/data/` with no subfolders (R18): `Season`, `Flock`, `Lambing`, `Foster`, `Pen`, `Treatment`, `Reminder`, `Note`, `Settings`, `Entitlement` and `Export` repositories plus `RestoreService`. There is no `SeasonStatsRepository` — the season-summary reads belong to `SeasonRepository`, because a repository that only reads is a query object wearing a repository's name. A thirteenth is a schema-review conversation, not an edit.

They do **not** take a `Clock`. There is exactly one clock — the ambient `clock` from `package:clock` — and tests install theirs with `withClock` (decision #46). Two clock seams is worse than none, because a test that fakes one does not fake the other.

Because the database open is inherently asynchronous (application support directory → `path_provider` → `Future`; decisions #20, #27), the database provider is a `FutureProvider` and repository providers derive from it. `AsyncLoading` is then *precisely* the "first frame, no data yet" state the design already requires (§6, decision #71):

```dart
// lib/data/providers.dart
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();          // core/db/connection.dart — R2, R12
  ref.onDispose(db.close);
  return db;
});

final lambingRepositoryProvider = FutureProvider<LambingRepository>((ref) async => LambingRepository(
      db: await ref.watch(databaseProvider.future),
      reminders: ref.watch(notificationSchedulerProvider),
      media: ref.watch(mediaStoreProvider),
    ));
```

The full provider graph, the `.autoDispose` policy, families and the `WriteController` guard belong to [`02-state-di-navigation.md`](02-state-di-navigation.md). Riverpod 2.6.1 only: no `retry:`, no bare `Notifier` with `.autoDispose`, no constructor-delivered family arguments.

### 4.2 Event verbs, never `save(aggregate)`

This is the load-bearing decision for spec §5's *"every write is committed immediately. There is no draft state to lose."*

```dart
// lib/data/lambing_repository.dart — shape, not the whole file
import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/db/uid.dart';          // newUid() — the one package:uuid call site (R15)
import '../core/time/app_clock.dart';  // appNow() — the one wall-clock reader (R23)
import '../core/write_outcome.dart';
import '../domain/birth_type.dart';
import '../domain/ids.dart';
import '../domain/lambing_ease.dart';
import '../domain/sex.dart';
import '../domain/time/instant.dart';
import '../domain/time/local_date.dart';
import '../domain/time/recorded_time.dart';
import 'failure_mapping.dart';
import 'media_store.dart';
import 'notification_scheduler.dart';

final class LambingRepository {
  LambingRepository({
    required AppDatabase db,
    required NotificationScheduler reminders,
    required MediaStore media,
  })  : _db = db,
        _reminders = reminders,
        _media = media;

  final AppDatabase _db;
  final NotificationScheduler _reminders;
  final MediaStore _media;

  // ── WRITES — every one of these is a complete, committed fact ──────────────

  /// Called by the Quick Entry "Lambing" tap, BEFORE Lambing Entry is pushed.
  /// The row exists from this moment; there is no draft and nothing to lose if
  /// the phone dies. Column names are `Lambings` in 03; if they diverge, 03 wins.
  Future<LambingId> beginLambing(EweId ewe) {
    final now = appNow();                              // ONE instant per mutation
    final when = RecordedTime.capture(now);            // spec §12.5 provenance
    return _db.transaction(() async {
      final season = await _currentSeason();           // app_settings — decision #42
      final id = await _db.into(_db.lambings).insert(
            LambingsCompanion.insert(
              uid: newUid(),                           // export identity — #32, R15
              createdAt: now,
              updatedAt: now,
              ewe: ewe.value,
              season: season.value,
              occurredAt: when.effective,
              capturedAt: when.capturedAt,
              timeSource: Value(when.source.key),      // frozen wire key, never localised
              localDate: LocalDate.of(when.effective), // same statement — 05 §5
              declaredBirthType: const Value.absent(), // absent ≠ Value(null)
            ),
          );
      // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
      await _db.into(_db.eweTouches).insertOnConflictUpdate(
            EweTouchesCompanion.insert(ewe: ewe.value, touchedAt: now),
          );
      return LambingId(id);
    });
  }

  Future<WriteOutcome> setBirthType(LambingId id, BirthType type) =>
      _write(() async {
        await (_db.update(_db.lambings)..where((t) => t.id.equals(id.value)))
            .write(LambingsCompanion(declaredBirthType: Value(type.code)));  // 1..5
      });

  Future<WriteOutcome> setEase(LambingId id, LambingEase ease) =>
      _write(() async { /* … */ });

  /// Adds one lamb AND writes its colostrum/navel reminder rows in the SAME
  /// transaction. There is no code path that creates a lamb without them.
  /// Returns the id and throws, for the same reason beginLambing does.
  Future<LambId> addLamb(LambingId lambing, {required Sex sex}) async { /* … */ }

  /// Spec §12.5: an edited time is labelled as edited, forever, and keeps what
  /// it was edited FROM.
  Future<WriteOutcome> correctOccurredAt(LambingId id, Instant when) =>
      _write(() async { /* writes effective + originalEffective + timeSource */ });
}
```

> **Why `declaredBirthType` is nullable, settled.** `Lambings.declaredBirthType` is **nullable** (CONVENTIONS R6), which is what makes the `Value.absent()` above a legal insert. This document and [`07-screens.md`](07-screens.md) both require the row to exist before a birth type is tapped ("Never empty — the row exists before the screen does"), and a non-nullable column makes that first insert impossible. The alternatives were a draft object (banned, decision #11) or a defaulted birth type (a §12.4 violation: the app asserting a litter size the shepherd never tapped). The column shape is [`03-data-model-and-schema.md`](03-data-model-and-schema.md)'s to declare; it must land **before the first schema snapshot**, because afterwards it is a migration.

Observe what is **absent**: no `LambingDraft`, no `saveLambing(Lambing whole)`, no `commit()`, no `isDirty`. **Draft state is unrepresentable** — you cannot defer a write because there is no object to defer. A team convention "always commit immediately" survives until 11pm on a Tuesday; a write API with no aggregate parameter survives forever.

One narrow exception to "writes return `WriteOutcome`": a verb whose whole purpose is to mint a row the caller must immediately navigate to — `beginLambing`, `addLamb` — returns the new id and **throws** on failure. There is no id to hand back on failure and the screen cannot open, so the global net (§5.5) is the right handler. Neither verb is ever gated by the free tier, which is what makes this safe.

`createEwe` is **not** in that set, because it is the one create verb the cap policy can refuse (decision #91). It takes an `EntryContext`, returns `WriteOutcome`, and the committed variant carries the new row id. Two shapes in the whole codebase; no third.

### 4.3 One `db.transaction` per mutation, and what goes inside it

Every mutation is exactly one `_db.transaction`, including single-statement ones. Uniformity is the point: the next edit that adds a second statement is already inside the boundary.

The ordering inside a verb is fixed:

1. **Read the clock once.** `final now = appNow();` at the top — `appNow()` from `lib/core/time/app_clock.dart` is the app's single wall-clock reader (R23); a repository never calls `clock.now()` itself. Two rows written in one mutation must not disagree by a millisecond.
2. **Write media first, outside the transaction.** `MediaStore` writes the photo or voice note and returns a *relative* path (decision #40). If that fails, no row is written and you have nothing. If the row were written first, a failed file write would leave a record pointing at a file that never existed. An orphaned *file* is garbage the sweep in [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) collects; an orphaned *row* is a broken record.
3. **All SQL, and only SQL, inside `_db.transaction`.** Every statement is `await`ed — drift's docs are explicit that *"all queries inside the transaction must be `await`-ed"*, and un-awaited work escapes the transaction and can silently lose data. Treat any drift runtime warning about this as a P0.
4. **Gateways after the transaction returns.** `ReminderReconciler.reconcile()` is called once the write is committed, debounced to 500 ms, off the paint frame (decision #63, R51 — `reconcile()` lives on `ReminderReconciler` in `lib/data/reminder_reconciler.dart`, never on the notification gateway, and `schedule(` on a reminder object is a banned spelling). **Never call a platform channel inside a drift transaction** — it round-trips through another isolate while holding the write lock.

The reminder architecture depends on this split: the reminder *row* is written in the same transaction as the lambing, so it is a durable fact; the OS projection is a rebuildable cache reconciled afterwards. See [`08-platform-integration.md`](08-platform-integration.md).

Two more transaction rules:

- **Bulk writes are one transaction.** A JSON restore inserting 5,000 rows one at a time notifies every stream 5,000 times. The maintainer's own answer to this is to wrap the inserts in a single `transaction`. Applies to restore, to seeding, and to "repeat last treatment for a batch".
- **Streams created outside a transaction only see updates after it commits.** That is exactly the isolation you want, and it is what makes §4.4 true.

### 4.4 Persist before republish

There is one path from a tap to a pixel and it runs through the file:

```
tap → controller.guard() → repository verb → db.transaction → COMMIT
                                                              │
                    drift invalidates every stream on the touched tables
                                                              ▼
                          the screen's single watch() re-runs → widget rebuilds
```

Consequences you must not work around:

- **No optimistic UI.** The controller does not show success before the transaction returns. The three confirmation channels — haptic, persistent SnackBar with Undo, list mutation — all fire on `WriteCommitted` (decision #103). They are `confirmSaved` / `showFailure` / `showCapRow` in `lib/core/ui/feedback.dart`, owned and defined by [`06-design-system.md`](06-design-system.md) (R10, R30); this document does not re-declare them.
- **No manual invalidation.** drift already tracks which tables each stream reads. `ref.invalidate` after a write is the classic stale-read bug and it is discipline, not structure. It is on the banned-text list.
- **One SQL statement per screen.** Never `combineLatest` two drift streams: two `watch()` streams updated inside one transaction can emit at different times, and the maintainer's position on drift#3338 (still open) is that this *"generally is working as intended"*. A Pen Board built from `combineLatest(pens, ewes)` renders a pen whose ewe has already moved. Build the screen's entire payload as one joined statement and watch that.
- **De-duplicate in the repository.** drift re-runs a stream on *any* write to a tracked table, even when the result is byte-identical (drift#3295, open). Set `override_hash_and_equals_in_result_sets: true` in `build.yaml`, and append `.distinct()` in the repository — never in the widget. `List` equality is identity, so list results need a comparator:

```dart
Stream<List<PenTile>> watchBoard() {
  final q = /* one joined select over pens + open pen_occupancies + ewes */;
  return q
      .watch()
      .map(_toTiles)
      .distinct((a, b) => const ListEquality<PenTile>().equals(a, b));
}
```

  Without this the pen grid visibly re-lays-out while the shepherd is reading it in a head torch. drift invalidates by *table written*, not by row changed: penning one ewe writes `pen_occupancies` and re-runs the whole board statement, and every screen whose payload joins `ewes` re-runs on any `ewes` update anywhere in the app.

- **Aggregates use `customSelect` with an explicit `readsFrom:`.** Do not rely on `groupBy` inside a Dart-defined drift `View` — drift documents exactly one shape for those and says nothing about `groupBy` or `where` inside `as()`. Without `readsFrom:` drift cannot track the statement and the stream stops updating.

### 4.5 There is no Save button

The row is created on **screen entry**, not on exit. `LambingEntryScreen`'s controller calls `beginLambing()` on its first build; from that instant the record exists, attributed to the right ewe, with an honest auto-captured timestamp. Every subsequent tap is an `UPDATE`.

What that means in practice:

| Consequence | Rule |
|---|---|
| An abandoned entry leaves a real row | Correct. Spec §7.2: "a valid record can be one tap." A lambing with only a timestamp is a true statement — *something happened to this ewe at 03:20*. Provide an explicit delete on the ewe card. **Never garbage-collect**: silent deletion is a §12.4 violation in the other direction. |
| The app bar button says "Done", never "Save" | It pops the route. It commits nothing, because there is nothing left to commit. |
| Free-text fields are the only exception | They cannot round-trip per keystroke without churning every watching stream. Bound the exposure: debounce **400 ms**, commit on focus loss, commit on route pop (`PopScope`), commit on `AppLifecycleState.inactive`. Worst-case loss is 400 ms of typing, and that number is written down in `CODE-REVIEW-CHECKLIST.md` so it cannot silently grow. |
| Undo is per verb, not generic | `beginLambing` → hard delete while zero child rows; `addLamb` → hard delete; `foster` → a compensating `FosterEvent` labelled "corrected"; `treatment` → soft-void (`voided_at`), so the medicine book shows the void rather than losing the row; **season deletion → no undo at all**, guarded by the only `canPop: false` flow in the app. There is no `repo.undo(id)`. The window is until the SnackBar is dismissed or the route pops. **Undo does not survive process death and the UI must not imply it does** (decision #69). |
| The free-tier cap never blocks an entry | The policy object takes an `EntryContext`; `EntryContext.liveEntry` is structurally incapable of returning a block — it returns `Allow(overFreeCap: true)` and the row is written and marked as over the free cap. The tier is **season-primary with the ewe cap secondary** (owner ruling 8), so exactly two calm-UI actions are gated: starting a second season, and adding ewe #16 from the Flock screen. Neither may surface mid-entry, and neither may surface at all between 22:00 and 06:00 (decision #91, [`11-monetization-and-store.md`](11-monetization-and-store.md)). |

**Proved by test, per entry screen**, because this is the property most likely to erode:

```dart
testWidgets('the lambing row exists before any Done tap', (tester) async {
  final db = AppDatabase(DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,   // mandatory in widget tests
  ));
  addTearDown(db.close);
  // … pump the screen with databaseProvider overridden …
  // AMENDED 2026-08-02 (N16-T02a), ruling P8: the sixth tap is the first tally
  // stroke. Birth type is derived and labelled (COUNTED) — §7.0b.
  await tester.tap(find.byKey(const Key('lambing_entry.tally.stroke')));
  await tester.pump();

  final rows = await db.select(db.lambings).get();      // no Done, no Save, no pop
  expect(rows, hasLength(1));
  expect(rows.single.declaredBirthType, BirthType.twin.code);
});
```

**Anti-patterns.** A `save()` / `commit()` / `submit()` method on any repository. A `Draft` or `Pending` model. `isDirty`. A `TextEditingController` whose value is only read when a button is pressed. A write issued from a widget's `onPressed` straight to `AppDatabase`. `ref.invalidate` after a write. `combineLatest` over drift streams. CI catches the last three by text; it cannot catch a badly-shaped repository method, so the write-API review question is in `CODE-REVIEW-CHECKLIST.md`: *does any repository method take a whole aggregate?*

---

## 5. Errors

### 5.1 The complete failure set, and what it earns

An app with no network has a small, knowable failure set. Design to it exactly, not to a generic one.

| Failure | Signal | Frequency | Can the user act? |
|---|---|---|---|
| Disk full | `SQLITE_FULL` (13) | Rare but real — photos and voice notes fill a phone | **Yes** — delete photos, export, free space |
| Storage write failed, cause unknown | `SQLITE_IOERR` (10) | Rare | Partly — the message must not name a cause the app cannot see |
| Corrupt database | `SQLITE_CORRUPT` (11), `SQLITE_NOTADB` (26) | Very rare, catastrophic | Only if told immediately, loudly, with the save-a-copy path |
| Read-only / permission | `SQLITE_READONLY` (8), `SQLITE_PERM` (3), `SQLITE_CANTOPEN` (14) | Very rare | Barely — the message must not blame them |
| Migration failure | thrown during open | Rare, catastrophic | Only via the recovery screen (§5.6) |
| Constraint violation | `SQLITE_CONSTRAINT` (19) | Programmer error | **No** — it is a bug and must be loud in debug |
| Media file IO | `FileSystemException` | Occasional | Yes |

From that table: **reads throw, writes return a sealed `WriteOutcome`** (decision #13). `Result<T>` on every method would wrap ~60 methods and force ~200 `switch` blocks handling a case that never fires; roughly 100% of reads succeed, and when one does not there is exactly one sensible response and it is the same at every call site — stop, say so loudly, offer export and recovery. So reads propagate to the global net (§5.5).

Writes are different, and not because of errors: a write can be **committed but inconsistent** (spec §12.4 — "twin" with three lambs attached) or **refused by the free-tier policy** (decision #91). Neither an exception nor a bool can carry those.

### 5.2 `WriteOutcome`

```dart
// lib/core/write_outcome.dart
import '../domain/validation/warning.dart';   // Warning  (R17 — consistency.dart does not exist)
import '../domain/free_tier.dart';            // RefusalReason
import 'failure.dart';

/// Deliberately NOT named Ok/Error: `Error` shadows dart:core's `Error`, which
/// produces confusing analyzer messages the first time you write
/// `catch (e) { if (e is Error) … }`.
sealed class WriteOutcome {
  const WriteOutcome();
}

/// The fact is on disk. `warnings` may be non-empty: the write succeeded AND
/// something looks inconsistent. Spec §12.4 — warn, never fix.
///
/// `warnings` is populated by the CONTROLLER, never by a repository (R53):
/// `lib/data/` may not import `lib/domain/validation/` (rule
/// layer.data_no_validation), so a repository structurally cannot produce a
/// `Warning`. The field lives here so the outcome and its warnings travel
/// together through `WriteDone` and `ref.listen` to `confirmSaved`.
/// `insertedId` is set only by create verbs that cannot return an id directly
/// because the cap policy may refuse them (see §4.2). It is a raw `int` rather
/// than an `EweId` so that a second such verb does not turn this field into a
/// union; the caller wraps it at the one call site that reads it.
final class WriteCommitted extends WriteOutcome {
  const WriteCommitted({this.insertedId, this.warnings = const []});
  final int? insertedId;
  final List<Warning> warnings;
}

/// Nothing was written; the transaction rolled back.
final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.failure);
  final ShedFailure failure;
}

/// Nothing was written, and nothing went wrong. The free-tier policy declined a
/// calm-UI action. Unreachable from EntryContext.liveEntry, by construction.
final class WriteRefused extends WriteOutcome {
  const WriteRefused(this.reason);
  final RefusalReason reason;
}
```

> Decision #13 names two variants and writes the success payload as `WriteCommitted{flags}`. Two deliberate departures, both recorded here so neither reads as drift. **The field is `warnings`, not `flags`**, because its type is `List<Warning>` from decision #54 and a field whose name disagrees with its type is a bug waiting to be written. **The third variant exists** because decision #91 requires the repository to consult the cap policy and return something the UI can tell apart from a failure — a cap gate is not an error, and logging it as one would poison the Diagnostics screen. The free-tier type names are settled: `EntryContext`, `CapDecision` (`Allow` / `BlockedByCap`) and `RefusalReason { secondSeason, eweCap }` in `lib/domain/free_tier.dart`, and [`11-monetization-and-store.md`](11-monetization-and-store.md) **adopts** them rather than renaming them (R69). The repository maps `BlockedByCap(reason)` → `WriteRefused(reason)`. `WriteOutcome` is **not** generic: there is no `WriteOutcome<T>`, and a repository that wants to hand back an id uses the throwing shape in §4.2.

### 5.3 `ShedFailure`

```dart
// lib/core/failure.dart
sealed class ShedFailure {
  const ShedFailure();

  /// Plain, non-technical, actionable. No stack traces, no SQLite codes, no
  /// blame. This is read at 3am by someone holding a lamb.
  String get userMessage;
}

final class DiskFull extends ShedFailure {
  const DiskFull();
  @override
  String get userMessage =>
      'Your phone is out of space. Nothing was saved. Free some space and try again.';
}

final class DatabaseUnreadable extends ShedFailure {
  const DatabaseUnreadable(this.resultCode, this.extendedResultCode);
  final int resultCode;          // logged, never shown
  final int extendedResultCode;  // logged, never shown
  @override
  String get userMessage =>
      'Shed Book cannot read its records file. Do not delete the app. '
      'Open Settings › Diagnostics to save a copy of what is there.';
}

/// SQLITE_IOERR. The app knows the write did not land and does NOT know why.
/// Saying "you are out of space" here would be the app asserting something it
/// cannot see — the same class of error safety rule 4 exists to prevent, aimed
/// at the user instead of at the record.
final class StorageWriteFailed extends ShedFailure {
  const StorageWriteFailed();
  @override
  String get userMessage =>
      'Shed Book could not write to your phone. Nothing was saved. '
      'Check you have free space, then try again.';
}

final class StorageReadOnly extends ShedFailure { /* … */ }
final class MediaWriteFailed extends ShedFailure { /* … */ }

/// Bugs. Separated because the message differs and because these must be loud
/// in debug and silent-but-logged in release. It is the one variant that is not
/// `const`-constructible from nothing: it carries the error and the stack so the
/// diagnostics log has something to write (R8). Constructed at exactly two
/// sites — inside `shedFailureFrom` and inside `WriteController.guard`'s
/// catch-all. Neither the error nor the stack is ever shown to the user.
final class UnexpectedFailure extends ShedFailure {
  const UnexpectedFailure(this.error, this.stack);
  final Object error;
  final StackTrace stack;
  @override
  String get userMessage =>
      'Something went wrong and nothing was saved. Try again. '
      'If it keeps happening, open Settings › Diagnostics and save a copy.';
}
```

The six `userMessage` strings are the only user-facing text outside the ARB in v1. [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) may move them; the type does not change.

Mapping lives in `lib/data/`, not `lib/core/`, because it names SQLite types:

```dart
// lib/data/failure_mapping.dart
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../core/failure.dart';

ShedFailure shedFailureFrom(Object error) {
  // drift_flutter runs SQLite on a background isolate, so the original error
  // arrives wrapped. Unwrap once, then classify.
  final e = error is DriftRemoteException ? error.remoteCause : error;
  final s = StackTrace.current;   // the signature takes no stack — R4 fixes it at one arg
  return switch (e) {
    SqliteException(:final resultCode, :final extendedResultCode) => switch (resultCode) {
        13 => const DiskFull(),                                        // SQLITE_FULL
        10 => const StorageWriteFailed(),                              // SQLITE_IOERR
        11 || 26 => DatabaseUnreadable(resultCode, extendedResultCode), // CORRUPT / NOTADB
        8 || 3 || 14 => const StorageReadOnly(),                        // READONLY / PERM / CANTOPEN
        _ => UnexpectedFailure(e, s),
      },
    _ => UnexpectedFailure(e, s),
  };
}
```

There is **no** `ShedFailure.from(e, s)` and no other constructor that touches SQLite (R4). Putting the mapping on `ShedFailure` would drag `package:sqlite3` into `lib/core/`, which rule 8 forbids: the top-level function in `lib/data/` is the only shape that keeps the failure type free of the engine.

**Never put the exception's `message` into `userMessage` or into the log.** SQLite exception messages echo the failing SQL and sometimes bound values — ewe tags, note text, batch numbers. Log `resultCode` and `extendedResultCode` plus a statement identifier you control (decision #124). `DriftRemoteException`'s exact wrapper shape is asserted by a test in [`12-testing.md`](12-testing.md); if drift 2.34.2 wraps differently, fix this function, not its call sites.

One private helper per repository is the only place any of this appears:

```dart
Future<WriteOutcome> _write(Future<void> Function() body) async {
  try {
    await _db.transaction(body);
    // Always the default empty `warnings` — a repository cannot see
    // lib/domain/validation/ and so cannot produce a Warning (R53). A create
    // verb returns WriteCommitted(insertedId: id) from its own body instead.
    return const WriteCommitted();
  } on Object catch (e, s) {
    // §5.4: a programmer error is loud in debug and logged in release. Without
    // this line the catch-all turns every bad-state bug into a polite SnackBar
    // and you never see it. The assert throws out of the catch block.
    assert(e is! Error, 'programmer error inside a write: $e\n$s');
    LocalLog.instance.write('write failed', e, s);   // local file. Never a network sink.
    return WriteFailed(shedFailureFrom(e));
  }
}
```

### 5.4 What is returned versus thrown

| Situation | Mechanism |
|---|---|
| A read fails | **Throws.** Propagates to the global net; the screen shows the dark failure panel. |
| A write fails | **Returns** `WriteFailed`. The controller shows `failure.userMessage` in the persistent SnackBar. |
| A write succeeds but the record looks contradictory | **Returns** `WriteCommitted(warnings: […])`. Non-blocking badge. Never corrected. |
| A calm-UI action hits the free tier | **Returns** `WriteRefused`. Never on the 3am path. |
| Programmer error (constraint violation, bad state) | **Throws** in debug via `assert`; in release it lands as `UnexpectedFailure` and is logged. Never swallowed. |
| A gateway fails (notification, share) | Returns its own small result to the repository; **never** rolls back the SQL, which is already committed and is the fact that matters. |

### 5.5 The global error net

All three hooks are installed in `main()`, synchronously, before `runApp()`:

1. `FlutterError.onError` — framework errors (build, layout, paint).
2. `PlatformDispatcher.instance.onError` — errors outside the Flutter call stack (async, platform channels). Return `true`: you have handled it.
3. `ErrorWidget.builder` — what a broken subtree renders as.

Three deliberate divergences from the standard advice:

- **No Crashlytics, no Sentry, no Bugsnag, no analytics.** Every tutorial's `onError` sends to a backend. That is a network path, and the fact that a specific device crashed at 03:41 is itself telemetry the user never consented to. `LocalLog` writes a redacted, size-capped (256 KB, one rotation) plain-text file in application support — never the cache directory. Settings ▸ Diagnostics shows the last 20 events and offers a **user-initiated** share. Decision #123.
- **No `runZonedGuarded`.** `PlatformDispatcher.instance.onError` supersedes it, and mixing a custom zone with binding initialisation has a long tail of confusing failures (flutter#94123 — the framework does not warn when `ensureInitialized` runs in a different zone than `runApp`). One fewer thing to get wrong.
- **No `exit(1)` in release.** The docs offer it. Killing the app at 3am mid-lambing — when the data is already committed and the failure may be one mis-laid-out widget — is worse than a broken screen. Log it, show the panel.

`ErrorWidget.builder` is replaced because **the default is a red-on-yellow block**, which under a head torch in a dark shed is both blinding and terrifying. `NightErrorPanel` lives in `lib/core/ui/night_error_panel.dart` and has three hard constraints, because it renders in the one context where nothing is guaranteed:

- it supplies its own `Directionality` (there may be no `MaterialApp` above it);
- it reads no `Theme`, no `MediaQuery` and no provider — it hard-codes the base surface `#0B0D0E` and near-white text, and is the one file exempted from the raw-colour rule;
- it offers exactly one action: *"Save a copy of my records"*, which routes to the same share path Export uses.

`LocalLog` has one subtlety worth stating, because it is easy to get wrong: **the error handlers are installed synchronously in `main()`, but the log's directory is not known until `path_provider` resolves after the first frame.** So `LocalLog` starts in memory-only mode with a bounded ring buffer of the most recent records, and flushes to disk when `attachTo(directory)` is called during post-frame boot. Crash-path writes are `writeAsStringSync(..., flush: true)` and bypass the stream sink entirely — an async write may never flush if the process is about to be killed.

Its whole surface is `write(String, Object, StackTrace)`, `flutterError(FlutterErrorDetails)`, `record(String event)` (structured, no row contents), `attachTo(Directory)` and `markCleanPause()` (R52). `markCleanPause()` and the `session.lock` file it pairs with belong to [`13-build-ci-release.md`](13-build-ci-release.md) (R11); this document does not define them. There is exactly one diagnostics sink — `_diagnostics` is a banned identifier, and `LocalLog.instance` is the only non-framework `.instance` in `lib/` (`WidgetsBinding.instance` and `PlatformDispatcher.instance` are the SDK's, in `main.dart` and `app.dart`).

### 5.6 The one failure a screen cannot handle

A database that will not open — corruption, a failed migration — cannot be handled by a normal screen, because every normal screen needs the database. `databaseProvider` failing puts the app into a dedicated `RecoveryScreen` inside the same widget tree: dark, three 60 pt buttons — *"Save a copy of the file"* (`VACUUM INTO` a snapshot, then the share sheet), *"Restore from a JSON backup"*, *"Start a new records file"*. **Never auto-delete and never auto-repair.** Spec §7.9 already says a lost phone is lost data unless the user exports; the corresponding honesty here is that a damaged file is never silently discarded. See [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md).

**Anti-patterns.** `catch (_) {}`. Rethrowing a `SqliteException` past the repository boundary. Putting a SQLite message in a SnackBar. A `Result<T>` on a read. Naming the failure case `Error`. Any error path that touches a socket. CI catches the network imports; the rest is a review item.

---

## 6. `main()`

### 6.1 The file

```dart
// lib/main.dart
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/log/local_log.dart';
import 'core/ui/night_error_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Framework errors: build, layout, paint.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);     // keeps the console output in debug
    LocalLog.instance.flutterError(details);
  };

  // 2. Everything outside the Flutter call stack: async gaps, platform channels.
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalLog.instance.write('uncaught', error, stack);
    return true;                            // handled — do not kill the app
  };

  // 3. What a broken subtree renders as. The default is red-on-yellow.
  ErrorWidget.builder = (details) => const NightErrorPanel();

  runApp(const ProviderScope(child: ShedBookApp()));
}
```

Twenty lines of body, no `async`, no `await`, no `overrides`.

### 6.2 Line by line

| Line | Why |
|---|---|
| `WidgetsFlutterBinding.ensureInitialized()` | `runApp()` calls it internally anyway, so this moves binding init by microseconds. It is explicit so that the two handlers below are guaranteed to be installed against a live binding, and so nobody adds an `await` above it later "because the binding needed it". |
| `FlutterError.onError` | Installed **before** anything can throw. `presentError` is kept so debug console behaviour is unchanged. |
| `PlatformDispatcher.instance.onError` returning `true` | Returning `false` forwards to the default handler, which on some platforms terminates. At 3am the committed data matters more than the process. |
| `ErrorWidget.builder` | Set once here, never reassigned inside a `build()` — reassigning a global during layout is a race with whatever is currently rendering. |
| `const ProviderScope(child: …)` | No `overrides`. The database is not constructed here and is never injected with `overrideWithValue` (decision #20). Tests override `databaseProvider` in their own scope. **No `retry:`** — it does not exist on Riverpod 2.6.1 and there is no auto-retry to disable. |
| No `await`, anywhere | Enforced by rule `main.no_await`. |

### 6.3 What happens after the first frame

The first frame is a static dark Quick Entry shell: **no data and every target on it live** — tonight's records, the five event words, the TAG cell, `INDEX` and the slab (**P16** struck the *fully interactive keypad*: the keypad is in the tag sheet, which is closed on frame 1). Because every theme is dark, a wrong first frame is a dark first frame, which is why the palette can be resolved after `runApp()` at no cost. Tonight's page renders fixed-height dark rows at frame 1 — the same boxes the content will occupy, so nothing shifts. (The recents and the "in the pens" list moved into the tag sheet at **P16**.)

`app.dart` holds the boot kick:

```dart
// lib/app.dart (excerpt) — ShedBookApp is a ConsumerStatefulWidget, so `ref`
// is available in initState. It is the only stateful widget above the router.
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Starts the DB open, migration, settings read and reminder reconcile.
    // Nothing awaits it: the providers that need it rebuild when it lands.
    // `.ignore()` (dart:async) marks the future as intentionally unawaited;
    // a failure still surfaces through databaseProvider's AsyncError (§5.6).
    ref.read(databaseProvider.future).ignore();
  });
}
```

Whichever comes first — a data widget watching a derived provider during frame 1, or this callback — the open is asynchronous and the frame paints without it. The callback exists so the open still starts on a screen that watches nothing.

| Work | Where it happens | Owner |
|---|---|---|
| `path_provider` → application support directory | inside `openAppDatabase()` (`lib/core/db/connection.dart`) | [`03`](03-data-model-and-schema.md) |
| DB open, pragmas, migration, first-run season seed | `databaseProvider` | [`03`](03-data-model-and-schema.md), [`04`](04-migrations-media-backup-restore.md) |
| `LocalLog.attachTo(dir)` and buffer flush | post-frame, right after the directory resolves | §5.5 |
| Settings + palette read | `settingsProvider`, derived from `databaseProvider` | [`06`](06-design-system.md) |
| Timezone DB init, `tz.setLocalLocation` | the notification seam only | [`08`](08-platform-integration.md) |
| Notification plugin init + first `reconcile()` | after DB open; again on `AppLifecycleState.resumed` | [`08`](08-platform-integration.md) |
| Purchase stream subscription | **only** if `purchase_in_flight_at` is set and `unlocked = 0` | [`11`](11-monetization-and-store.md) |
| Entitlement read | never on the 3am path; the first frame is entitlement-agnostic | [`11`](11-monetization-and-store.md) |

**Anti-patterns in `main()`, all of them previously written down by somebody and all of them wrong here.** `await openDatabase()`. `await SettingsStore.open()` to resolve the palette. `await notifications.initialize()`. `overrides: [databaseProvider.overrideWithValue(db)]`. `retry: (_, __) => null` (Riverpod 3 API — compile error on 2.6.1). `runZonedGuarded`. `deferFirstFrame()` — rejected outright by decision #21, because it converts the fixed cost of a dark first frame into a variable wait on the DB open, which is the one thing §6.3 exists to prevent. `flutter_native_splash.preserve`. Reading the entitlement. Any `if (kReleaseMode) exit(1)`.

The no-white-flash requirement is finished off outside Dart: the Android `LaunchTheme` `windowBackground` and the iOS `LaunchScreen` background are both set to the app's base surface, and the Android 12+ splash exit fade is disabled. Those are config changes and they are the actual fix — see [`06-design-system.md`](06-design-system.md).

---

## 7. Derived state: what is computed, what is stored

### 7.1 The rule

> **Store what was observed or typed. Compute what is inferred. The one exception is a value the app *told* the user, which is itself an observation.**

Recomputation is the correctness-preserving default here because the cost is zero and the failure mode of the alternative is silent. Upper bound from the spec: 400 ewes × ~2 lambs × ~10 seasons ≈ 8,000 lamb rows. A full scan with `GROUP BY` over that is sub-millisecond on a 2018 phone. There is no performance cost to trade against — but a stored aggregate goes stale the first time a lamb's status is corrected from alive to dead through a path that forgot to recompute, and **a wrong number in an app looks authoritative in a way that a wrong number on paper does not.** This is the number a shepherd culls on.

### 7.2 Bucket A — time-relative values: never stored

"Hours since penned", "ready to turn out", "days until clear", "overdue". These change **with no write**, so any stored copy is wrong within a minute. Store `entered_at`; compute the rest at render from the instant the ticker yields — the domain functions take `now` as a parameter (`timeSincePenned(enteredAt, now)`) and never read a clock themselves (R24).

One app-level ticker, boundary-aligned, at 60 seconds (decision #66) — never a `Timer.periodic` per row, which on a 30-pen board is 30 timers, 30 rebuild schedules, staggered repaints that read as noise under a head torch, and measurable overnight battery:

```dart
// lib/core/time/ticker.dart
/// A single heartbeat for every time-relative display in the app. Aligned to
/// the wall-clock minute so every pen tile updates in the same frame.
/// `.autoDispose` is load-bearing: with no time-relative screen mounted the
/// stream must stop, or it is an overnight battery cost for nothing (R25).
final minuteTickProvider = StreamProvider.autoDispose<Instant>((ref) async* {
  while (true) {
    final now = appNow();                    // the one wall-clock reader — R23
    yield now;
    final msToNextMinute = 60000 - (now.epochMillis % 60000);
    await Future<void>.delayed(Duration(milliseconds: msToNextMinute));
  }
});
```

It yields `Instant`, never a raw `DateTime`, and it is the only ticker in the app: the pen board, the withdrawal countdown and the Reminders day boundaries all read it. `minuteTickerProvider` and `penTickProvider` are banned spellings (R25).

Display granularity is hours, so 30 s buys nothing. In widget tests, `AutomatedTestWidgetsFlutterBinding` already provides an *advancing* fake clock, so `tester.pump(Duration(hours: 25))` really does advance what `appNow()` returns; `Clock.fixed` **freezes** it and will make an elapsed-time test silently measure 0 h (decision #113).

### 7.3 Bucket B — aggregates: computed on read

Season summary, the ewe-card summary line, losses by cause, the lambing-spread histogram.

- **Row-shaped projections** (current rearing dam, open pen occupancies, the contradiction badge) are SQL **views**, written as `CREATE VIEW` in `lib/core/db/views.drift` and registered with `@DriftDatabase(tables: […], include: {'search.drift', 'views.drift', 'queries.drift'})`. Three `.drift` files sit directly in `lib/core/db/`; there is no `views/` subdirectory (R22). The `views:` parameter is for Dart-defined views and this project has none — the two mechanisms are not interchangeable and mixing them is the commonest way to get a view that generates nothing. Views are read-only in SQLite, which is a feature: the type system will not let anyone write a derived value.
- **Anything with `GROUP BY` or date bucketing** is a `customSelect` with an explicit `readsFrom:` (decision #60). Do not use `groupBy` inside a Dart-defined view — drift documents exactly one shape for those and says nothing about `groupBy` or `where` inside `as()`.
- **The view produces raw counts; a pure Dart function assembles a `StatResult`** carrying `value` (`double?`), `definition`, `numerator`, `denominator`, `caveats` and `notComputableReason` (decision #58). A SQL view cannot carry a caveat, and the same season yields 120% / 100% / 80% / 200% under four legitimate definitions of "lambing percentage" — so the definition travels with the number.
- **`?? 0` is banned** in `lib/features/season/` and `lib/features/flock/`, by CI. Every aggregate column arrives nullable — SQL `AVG` over zero rows is `NULL`, and drift documents that view expression getters are *always* nullable. A ewe with no lambings has **no** average litter size, and rendering `0.0` is the app asserting something the shepherd never said (spec §12.4). Model absence as absence all the way to the widget and render an em dash.

### 7.4 Bucket C — the one stored derived value: `clear_date`

The withdrawal clear date is stored (decision #50), and the reasoning matters because it looks like a violation of §7.1:

- The user typed `withdrawal_days` off the bottle; the app **displayed a specific date** and printed it into a medicine-book PDF handed to a vet or an abattoir.
- Recomputing on read could produce a *different* date later — after a DST transition, a device timezone change, or a settings change. Silently changing a date the shepherd wrote on a pen card is a §12.4 and §12.5 violation.
- So it is not derived: it is **a record of what the app told the user**, which is an observation.

Four rules attach to it, all enforced in [`05-domain-correctness.md`](05-domain-correctness.md): computed exactly once at write time by the single `clearDateFor()` function; never silently recomputed; its inputs stored alongside it forever; and a consistency check that recomputes and, on mismatch, emits `ClearDateDisagrees` — **shown, never applied**. Rejected: a SQLite `STORED` generated column, which cannot be added by `ALTER TABLE` and would duplicate a safety-critical rule into a second language.

### 7.5 Bucket D — observations that look derived

The recents strip is **not** derivable from event tables, because "touched" includes *looking at* a ewe card without writing anything. So it is an observation and gets a real table, `ewe_touches(ewe, touched_at)`, written by the repository whenever any feature touches a ewe (decision #68). The same logic makes `EweObservations` a table rather than an inference: the app records what the shepherd observed and **never** infers "poor mothering" from a lamb death (decision #44, spec §12.2).

**Anti-patterns.** A denormalised `rearing_dam` column (it is a dual write a future code path will get wrong — use the append-only `FosterEvents` + view). A mutable `occupant_ewe` on `Pens` (the partial unique index makes two ewes in pen 3 physically impossible). A stored `lambing_percentage`. A `warnings` column (decision #54: a warning cannot be persisted because there is nowhere to persist it, and cannot mutate because it holds no writer). CI catches `?? 0` in the two statistics folders; the rest is a schema review item in [`03-data-model-and-schema.md`](03-data-model-and-schema.md).

---

## 8. When this app earns a second package

### 8.1 The compile-wall test

A second package is worth it when — and only when — this is true:

> **A rule that is currently rotting would become a compile error instead of a CI error, for code that has a second consumer.**

Both halves are required. The first half alone is not enough: a package boundary can express exactly **one** of the eight rules in §3.1 — "domain must not import flutter or drift". The other seven are intra-package and no `pubspec.yaml` can state them. A ~200-line dependency-free script expresses all eight, runs in under a second, and cannot break on an SDK upgrade. (Decision #9 estimates 60 lines; that was the layer checker alone. The shipped file also carries the banned-text table, the offline import scan and the lockfile parser, which is decision #10 — one gate, not five — being paid for.)

### 8.2 The honest answer: not yet

There is no second consumer. Candidates, none of which exists:

- a companion CLI that regenerates a season PDF from a JSON backup;
- a watchOS / Wear target;
- a v2 that publishes the domain as a public package.

`tool/seed.dart` is **not** a second consumer: it writes through the same restore path as the user-facing JSON import, inside the app package, deliberately, so that the seed script is a continuous test of the one code path where a bug loses five seasons (decision #74).

Absent a second consumer, a package is a boundary with nothing on the other side, and it costs a second `pubspec.yaml`, a `workspace:` declaration, `resolution: workspace` markers in every member, an extra `dart pub get` surface, and a noisier IDE.

Two arguments you may **not** use in this decision:

- *"Extracting a package breaks hot reload."* It does not. Flutter's documented hot-reload limitations are enum↔class changes, generic type parameter changes, native code, static-field and global-variable initializers, `main()`, `initState()`, `CupertinoTabView.builder`, and app-killed states. Package boundaries are not on the list. This is folklore.
- *"Melos."* Melos 8 delegates to pub workspaces anyway, and its remaining value is running commands across many packages and versioning/publishing them. This project has one package and publishes nothing. A four-target `Makefile` does the same job with zero dependencies.

### 8.3 If it ever fires

Structure the code today so extraction is a `git mv` plus two pubspecs — which the tree in §2.2 already is, because `lib/domain/` imports nothing but `dart:*`, `meta`, `collection` and `clock`.

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

```yaml
# every member
environment:
  sdk: ^3.12.0
resolution: workspace
```

Pub workspaces are stable since Dart 3.6.0, so the toolchain pin in §5 of the decision record clears them comfortably. Use explicit member paths as above; whether glob patterns in the `workspace:` list are supported on this SDK was **not verified by the c1 audit** — check dart.dev before relying on one. One sharp edge: `build_runner --workspace` is documented as experimental, so keep codegen in the app package only — which is free, because the domain package would have no builders. Do not extract and add a second generator in the same change.

---

## Definition of done

Tick all of these before calling the architecture finished. Each one is either mechanically checkable or a five-minute inspection.

- [ ] `flutter pub get` succeeds against the §5 dependency table on Flutter 3.44.8 / Dart 3.12.2, and `pubspec.lock` is committed.
- [ ] The tree in §2.2 exists, including empty `test/policy/` and `drift_schemas/`.
- [ ] `lib/data/models.dart` re-exports all 23 row types and only row types — no `AppDatabase`, no `Value`, no companions.
- [ ] `lib/data/models.dart` compiles, which means `PenOccupancies`, `EweTouches`, `EweSummaries` and `AppSettings` all carry `@DataClassName` in 03. Grep the generated `database.g.dart` for `class PenOccupancie`, `class EweTouche` and `class EweSummarie` — zero hits.
- [ ] `dart tool/check_policy.dart` exits 0 on a clean tree and **exits 1 on a deliberately planted violation of each of the eight rules** (write those eight throwaway files once, confirm eight failures, delete them).
- [ ] The gate exits **2**, not 0, when `pubspec.lock` or `tool/policy_allowlist.txt` is missing.
- [ ] The gate scans `test/` as well as `lib/`: plant `tester.container` in a throwaway test file and confirm `rp3.tester_container` fires. It does not scan `tool/`.
- [ ] Planting `HttpClient(`, `Socket.connect(` and `Image.network(` in a `lib/` file each fails the build — G3 is not satisfied by the package-import scan alone.
- [ ] `tool/policy_allowlist.txt` has three dependency sections and every `[transitive]` line carries a one-line reason.
- [ ] The allowlist's `[exempt]` section has exactly four entries: `app_clock.dart`, `night_error_panel.dart`, `primitives.dart` and `palettes.dart` (R56).
- [ ] `check_policy` runs in CI before the test job, and in `.git/hooks/pre-push`.
- [ ] `lib/main.dart` matches §6.1: no `async`, no `await`, no `overrides`, no `retry:`, three handlers installed before `runApp()`.
- [ ] `NightErrorPanel` renders correctly with **no** `MaterialApp`, `Theme`, `Directionality` or `MediaQuery` ancestor — proved by a widget test that pumps it bare.
- [ ] `LocalLog` accepts records before its directory is known, and flushes them once `attachTo()` runs — proved by a unit test.
- [ ] `LocalLog` never writes an exception `message`; only type, result codes, and a statement identifier.
- [ ] Every repository is a `final class` with no interface, takes `AppDatabase` in its constructor, and takes **no** `Clock`.
- [ ] No repository method takes an aggregate. Grep every `Future<WriteOutcome>` signature and confirm each is an event verb.
- [ ] Every mutation is exactly one `db.transaction`, reads the clock exactly once, and calls no platform channel inside the transaction.
- [ ] Every repository stream ends in `.distinct(…)`, and `override_hash_and_equals_in_result_sets: true` is set in `build.yaml`.
- [ ] Every screen is fed by **one** SQL statement. Zero occurrences of `combineLatest` in `lib/`.
- [ ] One "the row exists before any Done tap" widget test per entry screen (Lambing Entry, Lamb Card, Treatments).
- [ ] `WriteOutcome` and `ShedFailure` are `sealed`; `WriteOutcome` is not generic; no variant is named `Error`; every `switch` over them is exhaustive with no `default`.
- [ ] `shedFailureFrom` is covered by tests for `SQLITE_FULL`, `SQLITE_IOERR`, `SQLITE_CORRUPT` and a `DriftRemoteException` wrapper. **No `userMessage` names a cause the result code does not prove** — `SQLITE_IOERR` must not say "out of space".
- [ ] `_write` re-throws `Error` in debug: a test that makes a repository body throw `StateError` fails with that error, not with a `WriteFailed`.
- [ ] The `RecoveryScreen` is reachable by forcing `databaseProvider` to throw, and offers save-a-copy / restore / start-new — and never auto-repairs.
- [ ] `?? 0` appears nowhere under `lib/features/season/` or `lib/features/flock/`.
- [ ] One ticker exists in the whole app; `Timer.periodic` appears zero times anywhere in `lib/`, enforced by rule `net.sync_timer` rather than by review. The ticker itself uses `Future.delayed`, so the rule carries no exemption.
- [ ] `DateTime.now(` appears in exactly one file, and it is on the exempt list. `clock.now(` appears in the same one file: every other site in `lib/` calls `appNow()` (R23).
- [ ] `package:uuid` appears in exactly one file, `lib/core/db/uid.dart`, behind `String newUid()` (R15).
- [ ] Planting an import of `lib/domain/validation/warning.dart` in a `lib/data/` file fails with `layer.data_no_validation`, and no repository returns a non-empty `warnings` list (R53).

---

## References

Fetched 2026-07-27 unless noted. Version numbers used anywhere in this document come from §5 of the decision record, never from these pages.

**Project documents**
- [`docs/research/00-tech-decisions.md`](../research/00-tech-decisions.md) — the canonical decision record; §2 rows #6–#21, #27, #46–#50, #58–#60, #63, #66, #68, #91, #123–#124; §7.0 the owner's rulings.
- [`shed-book-spec.md`](../../shed-book-spec.md) — §4 offline, §5 the 3am test, §7 features, §9 screens, §12 safety rules.
- [`docs/research/raw/01-architecture.md`](../research/raw/01-architecture.md) — §1.4 the offline-first analysis, §11 the layer rules.
- [`docs/research/critique/c3-consistency.md`](../research/critique/c3-consistency.md) — A5 the four incompatible bootstraps, D7 the free-tier placement, §E the five-gates-into-one ruling.
- [`docs/research/critique/c1-packages.md`](../research/critique/c1-packages.md) — HIGH-4, why no analyzer plugin can be the gate.

**Flutter architecture**
- https://docs.flutter.dev/app-architecture/concepts — the two mandatory layers, the optional logic layer.
- https://docs.flutter.dev/app-architecture/guide — View / ViewModel / Repository / Service definitions.
- https://docs.flutter.dev/app-architecture/recommendations — the strongly-recommend list, including abstract repositories (deliberately diverged from).
- https://docs.flutter.dev/app-architecture/case-study — the Compass App hybrid folder layout.
- https://docs.flutter.dev/app-architecture/design-patterns/offline-first — **the page this app must not follow** (§1.4).
- https://docs.flutter.dev/app-architecture/design-patterns/result — the `Result` pattern and why it is scoped to writes here.
- https://docs.flutter.dev/app-architecture/design-patterns/command — the "can't be launched again until it finishes" guarantee behind the write guard.

**Flutter framework**
- https://docs.flutter.dev/testing/errors — the three error hooks; the `exit(1)` option we decline.
- https://docs.flutter.dev/tools/hot-reload — the documented limitation list (package boundaries are absent).
- https://github.com/flutter/flutter/issues/94123 — zone/binding mismatch; why no `runZonedGuarded`.
- https://github.com/flutter/flutter/issues/32736 and https://github.com/flutter/flutter/issues/39494 — binding init tears the native splash down early.

**Drift and SQLite**
- https://drift.simonbinder.eu/dart_api/streams/ — stream queries, table tracking, `readsFrom:`.
- https://drift.simonbinder.eu/dart_api/transactions/ — all statements must be awaited; streams see updates only after commit.
- https://drift.simonbinder.eu/docs/dart-api/views/ — view registration; view expression getters are always nullable.
- https://drift.simonbinder.eu/generation_options/ — `override_hash_and_equals_in_result_sets`.
- https://drift.simonbinder.eu/docs/dart-api/tables/ — `@DataClassName`; drift's row-class name is the table class with one trailing `s` removed, which is why `PenOccupancies` and `EweTouches` must be annotated (§2.3).
- https://github.com/simolus3/drift/issues/3338 — torn state across two streams updated in one transaction (open).
- https://github.com/simolus3/drift/issues/3295 — streams re-run on any write to a tracked table (open).
- https://github.com/simolus3/drift/issues/3531 — wrap bulk inserts in one transaction.
- https://www.sqlite.org/rescode.html — primary result codes used in `shedFailureFrom`.
- https://www.sqlite.org/lang_createview.html — views are read-only.
- https://www.sqlite.org/gencol.html — restriction 7: a `STORED` column cannot be added by `ALTER TABLE`.

**Dart tooling**
- https://dart.dev/tools/pub/workspaces — stable since 3.6.0; glob patterns need 3.11+.
- https://github.com/dart-lang/build/issues/3555 — build_runner's O(N²)-ish incremental model; one generator is the budget.

**Riverpod**
- https://pub.dev/documentation/riverpod/2.6.1/ — the 2.6.1 API surface this codebase is written against.
