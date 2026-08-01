# CONVENTIONS — the naming authority for the Shed Book doc set

**Status:** BINDING. This file outranks every other document in `docs/engineering/` on any question of a
**name, a path, a type shape, a signature, or a word**. It does not outrank them on reasoning, on
rationale, or on any decision that is not a name.

**Authority order used to produce it:** `shed-book-spec.md` → `docs/research/00-tech-decisions.md` →
the owner's eleven rulings (§6, R1–R11) → the owning document for the concept → majority usage →
Dart / Flutter / drift convention.

**Ownership map, used to break ties.** When two documents spell one thing two ways and no decision
record settles it, the owner wins:

| Concept | Owner |
|---|---|
| The folder tree, layer rules, `tool/check_policy.dart`, the error types, `main()` | `01-architecture.md` |
| Providers, controllers, the DI graph, auto-dispose policy, routing | `02-state-di-navigation.md` |
| The schema: tables, columns, indexes, constraints, vocabularies, stored keys | `03-data-model-and-schema.md` |
| Migrations, media, backup, restore, the diagnostics snapshot | `04-migrations-media-backup-restore.md` |
| `lib/domain/**` and `lib/core/time/`: value types, time, units, withdrawal, statistics, warnings | `05-domain-correctness.md` |
| `lib/core/ui/**`: tokens, palettes, type, tap targets, shared components, feedback | `06-design-system.md` |
| Screens: per-screen states, copy, tap costs, undo-per-verb, cap surfaces | `07-screens.md` |

**How to use it.** Every ruling in §6 has a number. A fixer cites the number
(`per CONVENTIONS R27`) and applies it mechanically. §1–§5 are the ruling log's output, restated as
one thing you can read top-to-bottom. If §1–§5 and §6 ever disagree, §6 is the record of the decision
and §1–§5 is stale.

**Seven documents were unwritten when this file was compiled** — 08, 09, 10, 11, 12, 13 and
`CODE-REVIEW-CHECKLIST.md`. **All seven are now written**, and they adopted every name below. They did
not get to rename anything in §2 or §3; where a ruling says "08 adopts", that was not an invitation to
counter-propose, and it is not one now. They raised exactly one **addition** — not a rename — and it is
folded in as **R74**: `PurchaseService` / `purchaseServiceProvider`, the store seam (§2.12, §3.1, §1).

---

## §1 The canonical folder tree

This is the tree a developer runs `mkdir` from. It is `01-architecture.md` §2.2 with all of §6
applied. Every path any of the seven documents names is either in this tree or is banned by a
numbered ruling.

```
shed_book/
├── pubspec.yaml                      # versions only from 00-tech-decisions §5
├── pubspec.lock                      # COMMITTED — decision #5's evidence
├── analysis_options.yaml             # flutter_lints 6.0.0 + the explicit strict-* language block
├── build.yaml                        # NOT build.yml. databases: shed_book: lib/core/db/database.dart
├── l10n.yaml                         # gen-l10n; ships en only
├── Makefile                          # gen · check · test · goldens
├── drift_schemas/                    # committed schema snapshots (generated, never hand-edited)
│   └── drift_schema_v<N>.json
├── assets/
│   ├── fonts/                        # AtkinsonHyperlegibleNext[wght].ttf + OFL.txt
│   └── content/                      # authored prose too long to be a UI string + one
│                                     # provenance line per vocabulary list.  NOT the 40
│                                     # vocabulary labels — those are ARB messages (R66).
├── tool/
│   ├── check_policy.dart             # THE gate. Zero dependencies. Not scanned by itself.
│   ├── policy_allowlist.txt          # [dependencies] [dev_dependencies] [transitive] [exempt]
│   ├── seed.dart                     # deterministic demo DB, written THROUGH the restore path
│   └── snapshot_to_backup.dart       # developer-run: pre-migration .sqlite → JSON backup
│
├── lib/
│   ├── main.dart                     # ~20 lines. Awaits nothing. No overrides.
│   ├── app.dart                      # ShedBookApp: ConsumerStatefulWidget (R34). Theme +
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
│   │   ├── withdrawal/
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
│   │   │   ├── warning.dart          # Warning · WarningCode · Reviewed<T>
│   │   │   ├── lambing_checks.dart   # + kPlausibleBirthWeight
│   │   │   ├── foster_checks.dart · treatment_checks.dart
│   │   ├── terminology/
│   │   │   ├── animal_class.dart     # enum AnimalClass
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
│   │   │   └── redaction.dart        # the allowed / forbidden field lists
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
│   │   ├── models.dart               # re-exports the drift ROW types only (see §2.8)
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
│   │   ├── purchase_service.dart         # the store seam — the ONLY package:in_app_purchase
│   │   │                                 # call site (R74)
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
│   ├── features/                     # widget tests: overflow matrix, tap budgets, monetization
│   ├── policy/                       # spec §12 as executable assertions
│   ├── support/                      # harness.dart + the seven hand-written fakes + seeds.dart
│   │                                 # · reads.dart · flock_generator.dart
│   │                                 # · tolerant_comparator.dart   (12 §5.3)
│   │                                 # · decision_record.dart — §7's parser, shared by the
│   │                                 #   dependency and schema ruling anchors (N00-T04)
│   └── fixtures/                     # flock_400_3seasons.json · flock_15_at_cap.json
└── integration_test/                 # four journeys, nightly, non-blocking  (R57)
```

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

### 1.1 The eight layer rules, as amended

Two amendments to `01-architecture.md` §3.1 are forced by rulings elsewhere. Everything else stands.

| # | From | May import | May never import | Rule id |
|---|---|---|---|---|
| 1 | `lib/domain/` | `lib/domain/`, `dart:*`, `meta`, `collection` | `package:flutter/*`, `package:drift/*`, `package:*riverpod/*`, `package:sqlite3*`, `package:intl/*`, **`package:clock/*`** (R24), every other layer | `layer.domain` |
| 2 | `lib/core/db/` | `lib/core/db/`, **`lib/core/`** (R16), `lib/domain/`, `package:drift/*`, `package:sqlite3*`, **`package:uuid`** (R15), `package:clock`, `package:flutter/foundation.dart` | `lib/data/`, `lib/features/`, `lib/core/ui/`, `package:flutter/material.dart` | `layer.core_db` |
| 3 | `lib/data/` | `lib/data/`, `lib/core/*`, `lib/domain/` **except `lib/domain/validation/`** (R53), `package:drift/*`, `package:sqlite3*`, `package:clock`, `package:collection`, `package:intl`, `package:timezone` | `lib/features/`, `lib/domain/validation/` | `layer.data` |
| 4 | `lib/data/` | — | `package:flutter/material.dart`, `package:flutter/cupertino.dart` | `layer.data_no_material` |
| 5 | `lib/features/` | own feature, `lib/data/`, `lib/domain/`, `lib/core/`, `lib/core/ui/`, `lib/routing/` | `lib/core/db/`, `package:drift/*`, `package:sqlite3*` | `layer.features` |
| 6 | `lib/features/<a>/` | — | `lib/features/<b>/` | `layer.sibling` |
| 7 | `lib/core/ui/` | `lib/core/ui/`, `lib/domain/`, `package:flutter/*`, `package:intl` (in `formatters.dart` only) | `lib/data/`, `lib/core/db/`, `package:drift/*` | `layer.core_ui` |
| 8 | anything outside `lib/data/` | — | any mutating drift API; `customStatement(` outside `lib/core/db/`; `package:sqlite3` outside `lib/data/` + `lib/core/db/` | `layer.single_writer` |

Plus the root: `lib/main.dart` and `lib/app.dart` may not import `lib/core/db/`, `package:drift/*` or
`package:sqlite3*` (`layer.root`).

The corresponding `_mayImport` entries:

```dart
'lib/domain/':   {'lib/domain/'},
'lib/core/db/':  {'lib/core/db/', 'lib/core/', 'lib/domain/'},   // R16
'lib/core/ui/':  {'lib/core/ui/', 'lib/domain/'},
'lib/core/':     {'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
'lib/data/':     {'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
'lib/features/': {'lib/features/', 'lib/data/', 'lib/domain/', 'lib/core/', 'lib/core/ui/', 'lib/routing/'},
'lib/routing/':  {'lib/routing/', 'lib/features/', 'lib/data/', 'lib/core/', 'lib/domain/'},
'lib/':          {'lib/', 'lib/core/', 'lib/core/ui/', 'lib/data/', 'lib/domain/', 'lib/features/', 'lib/routing/'},
```

`lib/data/** → lib/domain/validation/**` is a *path-pair* ban, not a layer ban; it is its own rule row
`layer.data_no_validation`.

---

## §2 The canonical type catalogue

Every type that appears in more than one document. **Name · file · shape · owner.** A document that
spells one of these differently is wrong and must be edited.

### 2.1 Ids

`lib/domain/ids.dart` — owner **05** (types), **03** (which ids exist). Ruling R5.

```dart
extension type const EweId(int value) {}
extension type const EweSeasonId(int value) {}
extension type const LambingId(int value) {}
extension type const LambId(int value) {}
extension type const FosterEventId(int value) {}
extension type const CareEventId(int value) {}
extension type const EweObservationId(int value) {}
extension type const PenId(int value) {}
extension type const PenOccupancyId(int value) {}
extension type const TreatmentId(int value) {}
extension type const TreatmentWithdrawalId(int value) {}
extension type const ReminderId(int value) {}
extension type const NoteId(int value) {}
extension type const MediaAssetId(int value) {}
extension type const SeasonId(int value) {}
extension type const VocabTermId(int value) {}
```

- The representation getter is always `.value`. `id.id` and `id.raw` are banned.
- The uid generator is **not** here: `String newUid()` lives in `lib/core/db/uid.dart` (R15), because
  `lib/domain/` may not import `package:uuid`.
- A bare `int` never crosses a repository, controller, route-helper or provider-family boundary (R33).

### 2.2 Time

| Name | File | Shape | Owner |
|---|---|---|---|
| `Instant` | `lib/domain/time/instant.dart` | `extension type const Instant(int epochMillis)`; `Instant.fromDateTime(DateTime)`; `.utc`, `.local`, `.plus(Duration)`, `.difference(Instant)`, `.isBefore/.isAfter/.compareTo`, `Instant.ascending/descending` | 05 |
| `LocalDate` | `lib/domain/time/local_date.dart` | `extension type const LocalDate._(String iso)`; `LocalDate(y,m,d)`, `LocalDate.parse(String)` (strict, throws), `LocalDate.of(Instant)`; `.year/.month/.day/.iso`, `.plusDays`, `.daysUntil`, `.startOfDayLocal()`, `.compareTo` | 05 |
| `PartialDate` | `lib/domain/time/partial_date.dart` | `extension type const PartialDate._(String iso)`; `PartialDate.parse`; `int get year`, `int? get month`, `LocalDate? get exactDate`. Never widened to a full date. | 05 |
| `RecordedTime` | `lib/domain/time/recorded_time.dart` | `final class`; fields `effective`, `capturedAt`, `originalEffective?`, `source`; factories `RecordedTime.capture(Instant)`, `RecordedTime.entered({effective, now})`; `editedTo(Instant)`; `isEdited`, `provenanceLabel`, `entryLag` | 05 |
| `TimeSource` | same file | `enum TimeSource { autoCaptured('auto'), userEntered('entered'), userEdited('edited') }` + `fromKey` | 05 |
| `appNow()` | `lib/core/time/app_clock.dart` | `Instant appNow() => Instant(clock.now().millisecondsSinceEpoch);` — **the only wall-clock reader in the app** (R23) | 05 |
| `checkLocalWallTimeExists` | `lib/domain/time/wall_time.dart` | `List<Warning> checkLocalWallTimeExists(int y,int mo,int d,int h,int mi)` | 05 |

Banned spellings: `Instant.now()`, `Instant.fromUtc()`, `RecordedTime.captured()`, `clock.now()`
anywhere outside `app_clock.dart`, `DateTime.now(` anywhere outside `app_clock.dart`, any second clock
abstraction (`abstract class Clock`, `SystemClock`, `clockProvider`).

### 2.3 Units

| Name | File | Shape | Owner |
|---|---|---|---|
| `Grams` | `lib/domain/units/grams.dart` | `extension type const Grams(int value)`; `.fromKilograms/.fromPounds/.fromPoundsOunces`; `.inKilograms/.inPounds/.wholePounds/.remainderOunces` | 05 |
| `MilliCelsius` | `lib/domain/units/milli_celsius.dart` | `extension type const MilliCelsius(int value)`; `.fromCelsius/.fromFahrenheit`; `.inCelsius/.inFahrenheit` | 05 |
| `WeightUnit` | `lib/domain/units/weight_unit.dart` | `enum WeightUnit { kg('kg'), lb('lb') }` + `fromKey` — matches `app_settings.weight_unit`'s CHECK (R68) | 05 |
| `parseUserNumber` | `lib/domain/units/parse_number.dart` | `double? parseUserNumber(String raw)` — returns null on ambiguity | 05 |
| `kPlausibleBirthWeight` | `lib/domain/validation/lambing_checks.dart` | `const ({Grams min, Grams max}) kPlausibleBirthWeight = (min: Grams(1000), max: Grams(10000));` | 05 |

No extension type ever exists for a *display* unit. `Pounds` and `Fahrenheit` are banned type names.

### 2.4 The write path

`lib/core/write_outcome.dart` — owner **01**. Rulings R3, R8, R32, R53.

```dart
sealed class WriteOutcome { const WriteOutcome(); }

/// NOT generic. There is no WriteOutcome<T>.
final class WriteCommitted extends WriteOutcome {
  const WriteCommitted({this.insertedId, this.warnings = const []});
  final int? insertedId;          // raw int, wrapped by the one call site that reads it
  final List<Warning> warnings;   // populated by the CONTROLLER, never by a repository (R53)
}

final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.failure);
  final ShedFailure failure;
}

final class WriteRefused extends WriteOutcome {
  const WriteRefused(this.reason);
  final RefusalReason reason;
}
```

Banned: `WriteOutcome<T>`, `WriteCommitted{flags}`, `WriteCommitted{id}`, `Ok`, `Error`, a fourth
variant added without editing every `switch`.

`lib/core/write_action.dart` — owner **02**:

```dart
sealed class WriteState { const WriteState(); }
final class WriteIdle    extends WriteState { const WriteIdle(); }
final class WriteRunning extends WriteState { const WriteRunning(); }
final class WriteDone    extends WriteState { const WriteDone(this.outcome); final WriteOutcome outcome; }
// WriteState subclasses deliberately have NO ==.

abstract base class WriteController extends AutoDisposeNotifier<WriteState> {
  bool _disposed = false;
  @override WriteState build();
  @protected Future<void> guard(Future<WriteOutcome> Function() action);
}
```

### 2.5 Errors

`lib/core/failure.dart` — owner **01**. Ruling R8.

```dart
sealed class ShedFailure {
  const ShedFailure();
  String get userMessage;   // plain, actionable, no codes, no blame
}

final class DiskFull            extends ShedFailure { const DiskFull(); }
final class DatabaseUnreadable  extends ShedFailure { const DatabaseUnreadable(this.resultCode, this.extendedResultCode);
                                                     final int resultCode; final int extendedResultCode; }
final class StorageWriteFailed  extends ShedFailure { const StorageWriteFailed(); }
final class StorageReadOnly     extends ShedFailure { const StorageReadOnly(); }
final class MediaWriteFailed    extends ShedFailure { const MediaWriteFailed(); }
final class UnexpectedFailure   extends ShedFailure { const UnexpectedFailure(this.error, this.stack);
                                                     final Object error; final StackTrace stack; }   // R8
```

Six variants; six `userMessage` strings; they are the only user-facing text outside the ARB in v1.

`lib/data/failure_mapping.dart` — owner **01**. Ruling R4:

```dart
ShedFailure shedFailureFrom(Object error);
```

There is **no** `ShedFailure.from(e, s)` and no other constructor that touches SQLite. Putting the
mapping on `ShedFailure` would drag `package:sqlite3` into `lib/core/`, which layer rule 8 forbids.
`UnexpectedFailure` is constructed at exactly two sites: inside `shedFailureFrom` (with the unwrapped
error and its stack) and inside `WriteController.guard`'s catch-all.

### 2.6 Warnings and statistics

| Name | File | Shape | Owner |
|---|---|---|---|
| `Warning` | `lib/domain/validation/warning.dart` | `final class Warning { const Warning(this.code, this.message, {this.fieldPath}); }` — no `fix()`, no `corrected`, no callback | 05 |
| `WarningCode` | same file | 11 members: `birthTypeLambCountMismatch`, `lambingBeforeSeasonStart`, `lambingInFuture`, `lambingLongBeforeCapture`, `implausibleBirthWeight`, `timeDoesNotExistLocally`, `fosterToSelf`, `deathBeforeBirth`, `duplicateActiveTag`, `clearDateDisagrees`, `localDateDisagrees` | 05 |
| `Reviewed<T>` | same file | `final class Reviewed<T> { final T value; final List<Warning> warnings; bool get hasWarnings; }` — no `cleaned` getter | 05 |
| `StatResult` | `lib/domain/stats/definitions.dart` | `value` (`double?`), `definition` (required), `numerator`, `denominator`, `notComputableReason`, `caveats`; plus `StatResult.notComputable({definition, reason, …})` | 05 |
| `LambCount` | same | `enum LambCount { born('born'), bornAlive('born_alive'), reared('reared') }` | 05 |
| `FlockDenominator` | same | `enum FlockDenominator { ewesPutToRam('ewes_to_ram'), ewesLambed('ewes_lambed') }` | 05 |
| `LambingPercentageChoice` | same | four members, keys identical to `app_settings.percentage_definition`'s CHECK; `definition` strings pinned literally (R61) | 05 |
| `EweSeasonOutcome` | same | `enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }` — a **derived bucketing** over `ewe_seasons.status`'s seven stored keys, never a replacement for them (R43) | 05 |
| `SeasonCounts` | `lib/domain/stats/season_counts.dart` | 13 int fields, hand-written `==`/`hashCode` | 05 |
| `DayBirths`, `LambOutcome`, `LambStatus`, `AgeBucket` | same | as in 05 §6.8–§6.9 | 05 |

`lib/domain/season_stats.dart` and `lib/domain/consistency.dart` do not exist (R17). Any import of
either is a defect.

### 2.7 Withdrawal — the safety type

`lib/domain/withdrawal/` — owner **05**.

```dart
enum WithdrawalTarget { meat('meat'), milk('milk') }          // + fromKey

sealed class WithdrawalPeriod { const WithdrawalPeriod(); }
final class WithdrawalDays extends WithdrawalPeriod {
  const WithdrawalDays._(this.days, this.target);             // PRIVATE generative ctor
  factory WithdrawalDays.asEnteredByUser({required int days, required WithdrawalTarget target});
  final int days; final WithdrawalTarget target;
}
final class WithdrawalNotApplicable extends WithdrawalPeriod { const WithdrawalNotApplicable(this.target);
                                                              final WithdrawalTarget target; }
final class WithdrawalNotRecorded   extends WithdrawalPeriod { const WithdrawalNotRecorded(); }

sealed class WithdrawalStatus { const WithdrawalStatus(); }
final class ClearsOn extends WithdrawalStatus { const ClearsOn(this.date, this.elapsesAt, this.target); }
final class NoWithdrawal      extends WithdrawalStatus { const NoWithdrawal(); }
final class WithdrawalUnknown extends WithdrawalStatus { const WithdrawalUnknown(); }

({LocalDate date, Instant elapsesAt}) clearDateFor({required Instant administeredAt, required int days});
WithdrawalStatus computeWithdrawalStatus({required Instant administeredAt, required WithdrawalPeriod period});
```

`WithdrawalMilkings` does not exist in v1 and nothing converts milkings to days. The countdown widget
takes a `ClearsOn`, never a `WithdrawalStatus`.

### 2.8 Database and persistence

| Name | File | Shape | Owner |
|---|---|---|---|
| `AppDatabase` | `lib/core/db/database.dart` | `class AppDatabase extends _$AppDatabase { AppDatabase(super.e, {this.seedOnCreate = true, this.schemaVersionOverride = kSchemaVersion}); }` (R2, R14) | 03 + 04 |
| `kSchemaVersion` | same | `const int kSchemaVersion` — top-level, captures nothing | 04 |
| `openAppDatabase()` | `lib/core/db/connection.dart` | `Future<AppDatabase> openAppDatabase()` — asserts it is not running under `flutter_test` and throws with the name of the override to add (R12) | 01 |
| `openConnection()` | same | `QueryExecutor openConnection()` — the ONLY `driftDatabase(` call site (R12) | 03 |
| `configureConnection` | same | `void configureConnection(CommonDatabase db)` — top-level, captures nothing, public (R12, R13) | 03 + 04 |
| `newUid()` | `lib/core/db/uid.dart` | `String newUid()` → UUID v7 (R15) | 03 |
| `mixin Identified` | `lib/core/db/tables/common.dart` | `id`, `uid`, `createdAt`, `updatedAt` | 03 |
| `InstantConverter`, `LocalDateConverter`, `PartialDateConverter` | `lib/core/db/converters.dart` | `const` `TypeConverter`s (R21) | 03 |
| `seedFirstRun` | `lib/core/db/seed/first_run.dart` | `Future<void> seedFirstRun(AppDatabase db)` | 03 |
| `RestoreService` | `lib/data/restore_service.dart` | + `RestoreOutcome`, `completeInterruptedRestore(Directory)` | 04 |
| `MediaSweeper` | `lib/data/media_sweeper.dart` | + `SweepReport` | 04 |
| `BackupHeader` | `lib/data/` (09 places the file) | the JSON envelope's `format`/`formatVersion`/`schema`/`counts`/`checksum` block. **Not** `ExportEnvelope` (R65) | 04 → 09 |
| `ExportEnvelope` | `lib/domain/policy/export_envelope.dart` | the disclaimer-bearing value every writer takes; `ExportEnvelope.standard({now, appVersion})` is its only constructor (R65) | 05 |

`configureConnection` runs, in this order (R13 — the union of 03's and 04's lists):

```
journal_mode = WAL · synchronous = FULL · foreign_keys = ON · busy_timeout = 5000
journal_size_limit = 4194304 · temp_store = MEMORY · recursive_triggers = ON
_assertEngineCapabilities(db)        // FTS5, fails loudly
_snapshotBeforeMigration(db)         // VACUUM INTO pre_migration/, bounded, never rethrows
```

`lib/data/models.dart` re-exports **every row class**, and only row classes (R20):

```dart
export 'package:shed_book/core/db/database.dart'
    show Season, Ewe, EweSeason, Lambing, Lamb, FosterEvent, CareEvent, EweObservation,
         Pen, PenOccupancy, PenOccupancyLamb, Treatment, TreatmentWithdrawal,
         Reminder, ReminderRule, Note, MediaAsset, VocabTerm, TerminologyOverride,
         AppSetting, Entitlement, EweTouch, EweSummary;
```

Four tables carry `@DataClassName`: `PenOccupancies`→`PenOccupancy`, `EweTouches`→`EweTouch`,
`EweSummaries`→`EweSummary`, `AppSettings`→`AppSetting` (R7 + R20).

### 2.9 Domain enums that mirror stored keys

The Dart member and the stored key must be readable off each other. Owner: **03** for the key, **05**
for the type.

| Type | File | Members → stored key |
|---|---|---|
| `BirthType` | `lib/domain/birth_type.dart` | `single`→1, `twin`→2, `triplet`→3, `quad`→4, `quintPlus`→5, on `int code`. `int? expectedLambCount(BirthType)` lives in this file and returns **null** for `quintPlus` (R46). |
| `LambingEase` | `lib/domain/lambing_ease.dart` | `extension type const LambingEase(int code)` 1..5, validated. **No descriptions in the domain** — the five labels are `vocab_terms` keys `ease_1`…`ease_5` with ARB defaults (R44). |
| `Sex` | `lib/domain/sex.dart` | `female('f')`, `male('m')`, `unknown('unknown')` (R45). `NULL` ≠ `unknown`. |
| `LambStatus` | `lib/domain/stats/season_counts.dart` | `alive`, `dead`, `stillborn`, `sold` |
| `FosterOutcome` | `lib/domain/foster_outcome.dart` | sealed: `ToEwe(EweId)`→`'to_ewe'`, `ToBottle()`→`'to_bottle'`, `RemovedUnknown()`→`'removed_unknown'` (R64) |
| `AnimalClass` | `lib/domain/terminology/animal_class.dart` | `ewe`, `maidenFemale`, `eweLamb`, `ram`, `ramLamb`, `wether`, `lamb` |
| `WithdrawalTarget` | see §2.7 | `meat`, `milk` |
| `TimeSource` | see §2.2 | `auto`, `entered`, `edited` |
| `ShedPaletteId` | `lib/core/ui/tokens.dart` | `night`→`'night'`, `amber`→`'amber'`, `deepRed`→`'red'` (R35) |
| `WeightUnit` | see §2.3 | `kg`, `lb` |

Death causes, malpresentations, treatment routes, ewe observations and foster methods are **not**
domain enums: they are `vocab_terms` rows with the keys 03 §10.1 seeds (`dc_*`, `mp_*`, `rt_*`,
`obs_*`, `fm_*`). `lib/domain/death_cause.dart` does not exist (R17).

### 2.10 Free tier

`lib/domain/free_tier.dart` — owner **01** (file), **11** (members). Ruling R69.

```dart
enum EntryContext { liveEntry, calm }

sealed class CapDecision { const CapDecision(); }
final class Allow        extends CapDecision { const Allow({required this.overFreeCap}); final bool overFreeCap; }
final class BlockedByCap extends CapDecision { const BlockedByCap(this.reason); final RefusalReason reason; }

enum RefusalReason { secondSeason, eweCap }

final class FreeTierPolicy {
  CapDecision decide({
    required EntryContext context,
    required Instant now,          // R69: the 22:00–06:00 quiet window needs it
    required bool unlocked,
    required int ewesInCurrentSeason,
    required int seasonCount,
  });
}
```

`EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap`. The repository maps
`BlockedByCap(reason)` → `WriteRefused(reason)`.

### 2.11 Design system

`lib/core/ui/` — owner **06**.

| Name | File | Shape |
|---|---|---|
| `ShedTokens` | `tokens.dart` | `final class ShedTokens extends ThemeExtension<ShedTokens>`; flat; `copyWith({Duration? motion, bool? highContrast})`; `lerp` snaps every non-`Color` field at `t < 0.5` |
| `ShedPalette` | `tokens.dart` | `{id, highContrast, name, colorScheme, tokens}` |
| `ShedPaletteId` | `tokens.dart` | `{night, amber, deepRed}` with `key` (R35) |
| `ShedThemeSet` | `theme.dart` | `typedef ShedThemeSet = ({ThemeData theme, ThemeData highContrast});` |
| `context.tokens` | `tokens.dart` | `extension ShedTokensX on BuildContext` — the only way a widget gets a colour or a metric |
| `SaveReceipt` | `feedback.dart` | `final class SaveReceipt { final String term, tag, summary, at; final VoidCallback? undo; final String undoLabel; }` (R31) |
| `confirmSaved` | `feedback.dart` | `void confirmSaved(BuildContext context, SaveReceipt receipt, List<Warning> warnings)` (R10, R30) |
| `showFailure` | `feedback.dart` | `void showFailure(BuildContext context, ShedFailure failure)` (R10, R30) |
| `showCapRow` | `feedback.dart` | `void showCapRow(BuildContext context, RefusalReason reason)` — calm, static, never a modal (R10, R30) |
| `ShedTapTarget` | `components/shed_tap_target.dart` | required `semanticLabel`; `Semantics(onTap:)` set |
| `ShedKeypad` | `components/shed_keypad.dart` | the only tag- and number-entry route (R70) |
| `ShedReceiptBar` | `components/shed_receipt.dart` | the widget only; the *functions* are in `feedback.dart` |
| `NightErrorPanel` | `night_error_panel.dart` | hard-coded `#0B0D0E`, own `Directionality`, no `Theme`/`MediaQuery` |

`showShedReceipt` and `showShedFailure` are banned spellings (R30). `feedback.dart` is the one file
permitted to call `showSnackBar(`.

### 2.12 Gateways — six platform seams and one store seam

All seven are hand-written classes in `lib/data/`, each wrapping exactly one plugin, each replaced by a
hand-written fake in tests. Ruling R9 fixes the three unhomed names; R47 fixes who owns capture; R74
adds the store seam.

| Class | File | Wraps | Owner |
|---|---|---|---|
| `NotificationScheduler` | `lib/data/notification_scheduler.dart` | `flutter_local_notifications` **and `package:timezone`** — the only tz call site in the app (R48) | 01 → 08 |
| `ShareService` | `lib/data/share_service.dart` | `share_plus` | 01 → 08 |
| `MediaStore` | `lib/data/media_store.dart` | `path_provider` + `flutter_image_compress`; owns the media root, `newRelativePath`, `resolve`, `writeAtomically` | 01 + 04 |
| `CameraService` | `lib/data/camera_service.dart` | `image_picker` — owns `pickImage`, `retrieveLostData` (R9, R47) | 08 |
| `VoiceRecorder` | `lib/data/voice_recorder.dart` | `record` (`AudioRecorder`) (R9, R47) | 08 |
| `WakelockController` | `lib/data/wakelock_controller.dart` | `wakelock_plus`; `acquire()` / `release()` (R9) | 08 |
| `PurchaseService` | `lib/data/purchase_service.dart` | `in_app_purchase`; the **store** seam, not a platform one. Also holds `kUnlockProductId`, `PurchaseSignal` and `StoreUnreachable`; no plugin type crosses it (R74) | 11 |

The first six are the **platform** seams and are `08-platform-integration.md`'s; `PurchaseService` is
the **store** seam and is `11-monetization-and-store.md`'s. 08 documents six, 11 documents the seventh,
and `test/support/` holds seven fakes (12 §4.2).

Non-plugin services in the same layer: `ReminderReconciler` (`lib/data/reminder_reconciler.dart`,
one method `Future<void> reconcile()`, R51), `RestoreService`, `MediaSweeper`.

`lib/features/reminders/notification_gateway.dart` does not exist (R48).

### 2.13 Repositories

Concrete `final class`es, no interfaces, flat in `lib/data/`, each taking `AppDatabase` and (where
relevant) gateways, none taking a `Clock`. Ruling R18, R19.

| Repository | File | Owns writes to |
|---|---|---|
| `SeasonRepository` | `season_repository.dart` | `seasons`, `ewe_seasons`, `app_settings.current_season`, the season-delete search sweep. Also owns the season-summary **reads** (R18: there is no `SeasonStatsRepository`). |
| `FlockRepository` | `flock_repository.dart` | `ewes`, `ewe_touches` |
| `LambingRepository` | `lambing_repository.dart` | `lambings`, `lambs`, `care_events`, `ewe_observations`, `ewe_summaries` |
| `FosterRepository` | `foster_repository.dart` | `foster_events` |
| `PenRepository` | `pen_repository.dart` | `pens`, `pen_occupancies`, `pen_occupancy_lambs` |
| `TreatmentRepository` | `treatment_repository.dart` | `treatments`, `treatment_withdrawals` |
| `ReminderRepository` | `reminder_repository.dart` | `reminders`, `reminder_rules` |
| `NoteRepository` | `note_repository.dart` | `notes`, `media_assets` |
| `SettingsRepository` | `settings_repository.dart` | `app_settings`, `vocab_terms`, `terminology_overrides` |
| `EntitlementRepository` | `entitlement_repository.dart` | `entitlements` |
| `ExportRepository` | `export_repository.dart` | nothing — read + artifact assembly only |
| `RestoreService` | `restore_service.dart` | all tables, once, into a **new** file |

Canonical verb signatures where more than one document names them (R32, R63, R64):

```dart
// LambingRepository — the two throwing verbs, and the only two.
Future<LambingId> beginLambing(EweId ewe);                      // returns an id, THROWS on failure
Future<LambId>    addLamb(LambingId lambing, {required Sex sex});
Future<WriteOutcome> setBirthType(LambingId id, BirthType type);
Future<WriteOutcome> setEase(LambingId id, LambingEase ease);
Future<WriteOutcome> correctOccurredAt(LambingId id, Instant when);
Future<WriteOutcome> addCare(...);       Future<WriteOutcome> removeCare(CareEventId id);

// FlockRepository — the one create verb the cap can refuse.
Future<WriteOutcome> createEwe({required String tag, required EntryContext context});
Future<WriteOutcome> setStatus(EweId id, EweStatus status);

// PenRepository — the UI verb is `turnOut`; the repository verb is `exitPen` (R63).
Future<WriteOutcome> enterPen(PenId pen, {EweId? ewe, List<LambId> lambs});
Future<WriteOutcome> exitPen(PenOccupancyId occupancy, {required PenExitReason reason});

// FosterRepository
Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome);

// TreatmentRepository
Future<WriteOutcome> recordTreatment(...);
Future<WriteOutcome> voidTreatment(TreatmentId id);
```

`beginLambing` and `addLamb` are the **only** verbs that return an id and throw. Every other write
returns `WriteOutcome`. `07-screens.md` §6.1's `switch (outcome) { case WriteCommitted(:final id) … }`
is wrong twice over and must be rewritten as a `try`/`catch` around a `Future<LambingId>` (R32).

### 2.14 Miscellaneous shared types

| Name | File | Shape | Owner |
|---|---|---|---|
| `TagIndexEntry` | `lib/domain/tag_match.dart` | `{EweId eweId, String tag, String digits, Instant? lastTouched}` (R26) | 05 |
| `rankTagMatches` | same | `List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query)` — pure, synchronous (R27) | 05 |
| `timeSincePenned` | `lib/domain/penning.dart` | `Duration timeSincePenned(Instant enteredAt, Instant now)` — takes `now`, never reads a clock (R24) | 05 |
| `ReminderBudget` | `lib/domain/reminder_budget.dart` | `abstract final class ReminderBudget { static int forPlatform(); }` → 56 iOS / 200 Android (R50) | 05 → 08 |
| `Disclaimers` | `lib/domain/policy/disclaimers.dart` | `abstract final class`; `exportFooter`, `withdrawalProvenance`, `withdrawalCaveat` — referenced, never re-typed | 05 |
| `ContentPolicy` | `lib/domain/policy/content_policy.dart` | `bannedInUserFacingText`, `allowlist` keyed by `Disclaimers.*` | 05 |
| `Terminology`, `TermLabel` | `lib/domain/terminology/` | as in 05 §8.1 | 05 |
| `ResumePolicy` | `lib/app.dart` | `static const staleAfter = Duration(minutes: 2); static bool shouldClearSelection(DateTime, DateTime)` | 02 |
| `LocalLog` | `lib/core/log/local_log.dart` | singleton `LocalLog.instance`; `write(String, Object, StackTrace)`, `flutterError(FlutterErrorDetails)`, `record(String event)`, `attachTo(Directory)`, `markCleanPause()` (R11, R52) | 01 + 13 |
| `ShedBookApp` | `lib/app.dart` | `class ShedBookApp extends ConsumerStatefulWidget` (R34) | 01 |
| `RouteNames`, `Routes` | `lib/routing/routes.dart` | 13 names, 12 push helpers, `Routes.navigatorKey` | 02 |

---

## §3 The canonical provider catalogue

Every provider in the app. **Name · type · file · scope · auto-dispose.** `flutter_riverpod` 2.6.1
spellings only. Production has zero overrides.

### 3.1 `lib/data/providers.dart` — the DI root

| Provider | Type | Auto-dispose | Notes |
|---|---|---|---|
| `databaseProvider` | `FutureProvider<AppDatabase>` | keepAlive | opens via `openAppDatabase()` on the first post-frame callback; `ref.onDispose(db.close)`. Never `Provider<AppDatabase>`, never `overrideWithValue` in `lib/`. |
| `seasonRepositoryProvider` | `FutureProvider<SeasonRepository>` | keepAlive | |
| `flockRepositoryProvider` | `FutureProvider<FlockRepository>` | keepAlive | |
| `lambingRepositoryProvider` | `FutureProvider<LambingRepository>` | keepAlive | takes `NotificationScheduler` + `MediaStore` |
| `fosterRepositoryProvider` | `FutureProvider<FosterRepository>` | keepAlive | |
| `penRepositoryProvider` | `FutureProvider<PenRepository>` | keepAlive | |
| `treatmentRepositoryProvider` | `FutureProvider<TreatmentRepository>` | keepAlive | |
| `reminderRepositoryProvider` | `FutureProvider<ReminderRepository>` | keepAlive | |
| `noteRepositoryProvider` | `FutureProvider<NoteRepository>` | keepAlive | |
| `settingsRepositoryProvider` | `FutureProvider<SettingsRepository>` | keepAlive | |
| `entitlementRepositoryProvider` | `FutureProvider<EntitlementRepository>` | keepAlive | |
| `exportRepositoryProvider` | `FutureProvider<ExportRepository>` | keepAlive | |
| `restoreServiceProvider` | `FutureProvider<RestoreService>` | keepAlive | |
| `mediaSweeperProvider` | `FutureProvider<MediaSweeper>` | keepAlive | |
| `reminderReconcilerProvider` | `FutureProvider<ReminderReconciler>` | keepAlive | needs the DB **and** the notification seam |
| `notificationSchedulerProvider` | `FutureProvider<NotificationScheduler>` | keepAlive | async: plugin `initialize()` |
| `shareServiceProvider` | `Provider<ShareService>` | keepAlive | |
| `mediaStoreProvider` | `Provider<MediaStore>` | keepAlive | |
| `cameraServiceProvider` | `Provider<CameraService>` | keepAlive | R9 |
| `voiceRecorderProvider` | `Provider<VoiceRecorder>` | keepAlive | R9 |
| `wakelockProvider` | `Provider<WakelockController>` | keepAlive | name is `wakelockProvider`, not `wakelockControllerProvider` (documented exception, §4.3) |
| `purchaseServiceProvider` | `Provider<PurchaseService>` | keepAlive | R74. Same shape as `shareServiceProvider`. **Nothing on a shed screen may watch it**, and `lib/main.dart` / `lib/app.dart` may not reference it (`launch.store_call`) |
| `settingsProvider` | `StreamProvider<AppSetting>` | keepAlive | **row class `AppSetting`, not the table class `AppSettings`** (R29). `appSettingsProvider` is banned. |
| `themeProvider` | `Provider<ShedThemeSet>` | keepAlive | synchronous; exhaustive `switch` over `settingsProvider`, with the `night` pair as the not-yet-loaded arm (R29) |
| `unitsProvider` | `Provider<WeightUnit>` | keepAlive | derived from `settingsProvider` (R68) |
| `terminologyProvider` | `Provider<Terminology>` | keepAlive | derived from `settingsProvider` + the seeded defaults |
| `entitlementProvider` | `StreamProvider<Entitlement>` | keepAlive | **nothing on a shed screen may watch this** (decision #90) |
| `freeTierPolicyProvider` | `Provider<FreeTierPolicy>` | keepAlive | R69 |

### 3.2 Read providers (one drift statement each)

| Provider | Type | File | Auto-dispose |
|---|---|---|---|
| `tagIndexProvider` | `StreamProvider<List<TagIndexEntry>>` | `lib/data/providers.dart` | keepAlive — active animals only (R26) |
| `quickEntryDeckProvider` | `StreamProvider<QuickEntryDeck>` | `lib/features/quick_entry/quick_entry_controller.dart` | keepAlive — **one** statement, two buckets; the strips read it with `.select` (R28) |
| `penBoardProvider` | `StreamProvider<List<PenTile>>` | `lib/features/pens/pen_board_controller.dart` | keepAlive |
| `flockListProvider` | `StreamProvider<List<FlockRow>>` | `lib/features/flock/flock_controller.dart` | keepAlive |
| `eweTimelineProvider` | `StreamProvider.autoDispose.family<List<TimelineRow>, EweId>` | `lib/features/flock/ewe_card_controller.dart` | autoDispose |
| `lambingEntryProvider` | `StreamProvider.autoDispose.family<LambingEntryData, LambingId>` | `lib/features/lambing/lambing_entry_controller.dart` | autoDispose |
| `lambCardProvider` | `StreamProvider.autoDispose.family<LambCardData, LambId>` | `lib/features/lambing/lamb_card_controller.dart` | autoDispose |
| `treatmentsProvider` | `StreamProvider.autoDispose.family<List<TreatmentRow>, TreatmentMode>` | `lib/features/treatments/treatments_controller.dart` | autoDispose |
| `remindersProvider` | `StreamProvider<RemindersView>` | `lib/features/reminders/reminders_controller.dart` | keepAlive |
| `seasonFactsProvider` | `StreamProvider.autoDispose.family<SeasonCounts, SeasonId>` | `lib/features/season/season_controller.dart` | autoDispose |
| `exportCountsProvider` | `StreamProvider<ExportCounts>` | `lib/features/export/export_controller.dart` | autoDispose |
| `noteSearchProvider` | `StreamProvider.autoDispose.family<List<SearchHit>, String>` | `lib/features/flock/note_search_controller.dart` | autoDispose — 200 ms debounce |

`recentEwesProvider` and `inPensProvider` are banned (R28): both strips are `.select`s over
`quickEntryDeckProvider`. `flockTagCacheProvider` is banned (R26).

### 3.3 The ticker

| Provider | Type | File | Auto-dispose |
|---|---|---|---|
| `minuteTickProvider` | `StreamProvider.autoDispose<Instant>` | `lib/core/time/ticker.dart` | autoDispose (R25) |

Boundary-aligned to the wall-clock minute, implemented with `Future.delayed` (never `Timer.periodic`).
It yields `Instant`, not `DateTime`. It is the **only** ticker in the app: the pen board, the
withdrawal countdown and the Reminders day boundaries all read it.
`minuteTickerProvider` and `penTickProvider` are banned spellings.
`ref.invalidate(minuteTickProvider)` on `AppLifecycleState.resumed` is the one legitimate
`ref.invalidate` in the codebase.

### 3.4 Screen controllers and write controllers

Two objects per screen, never one (R30 note, §4.4):

| Kind | Name | Type | Auto-dispose |
|---|---|---|---|
| Screen state | `<screen>ControllerProvider` | `NotifierProvider<…>` or `NotifierProvider.autoDispose.family<…>` | keepAlive for hub screens (Quick Entry, Flock, Pen Board); `.autoDispose.family` for per-animal |
| Writes | `<feature>WriteControllerProvider` | `NotifierProvider.autoDispose<C, WriteState>` | **always** `.autoDispose`. "Mutation" is a banned synonym (§5.2) |

Declared: `quickEntryControllerProvider`, `quickEntryWriteControllerProvider`,
`flockControllerProvider`, `flockWriteControllerProvider`, `eweCardControllerProvider`,
`lambingEntryControllerProvider`, `lambingWriteControllerProvider`, `lambCardControllerProvider`,
`fosterControllerProvider`, `fosterWriteControllerProvider`, `penBoardControllerProvider`,
`penWriteControllerProvider`, `treatmentsControllerProvider`, `treatmentWriteControllerProvider`,
`remindersControllerProvider`, `reminderWriteControllerProvider`, `seasonControllerProvider`,
`exportControllerProvider`, `exportWriteControllerProvider`, `settingsControllerProvider`,
`settingsWriteControllerProvider`, `noteSearchControllerProvider`.

`lambingControllerProvider` is a banned spelling (07 §6.1) — it is either
`lambingEntryControllerProvider` or `lambingWriteControllerProvider`, and the write goes through the
latter.

### 3.5 Not in the graph

- **The clock.** Ambient `package:clock`, read only through `appNow()`. There is no `clockProvider`.
- **`LocalLog`.** A deliberate static singleton, installed in `main()` before any `ProviderScope`
  exists. It is the only `\.instance\b` in `lib/`.
- **`AppDatabase` as a value.** `Provider<AppDatabase>` and `.overrideWithValue(db)` are banned in
  `lib/`.

Family arguments are always extension-type ids from `lib/domain/ids.dart` — never a bare `int`, never
a `List`, never a hand-written class without verified `==` (R33).

---

## §4 Naming conventions

### 4.1 Files

| Thing | Rule | Example |
|---|---|---|
| Every Dart file | `lower_snake_case.dart` | `lambing_entry_screen.dart` |
| Screen | `<screen>_screen.dart` | `pen_board_screen.dart` |
| Screen controller | `<screen>_controller.dart` | `pen_board_controller.dart` |
| Write controller | `<feature>_write_controller.dart`, or in the screen controller's file if it is one small class | `pen_board_controller.dart` |
| Repository | `<area>_repository.dart` | `treatment_repository.dart` |
| Gateway / service | `<name>.dart` matching the class in `lower_snake` | `notification_scheduler.dart` |
| Table cluster | `lib/core/db/tables/<cluster>.dart` | `tables/lambing.dart` |
| Shared component | `lib/core/ui/components/shed_<thing>.dart` | `components/shed_pen_tile.dart` |
| Test | mirrors the file under test, `_test.dart` suffix | `test/domain/withdrawal/clear_date_test.dart` |
| Policy test | states the *property*, not the file | `test/policy/withdrawal_has_no_default_test.dart` |
| Generated | `*.g.dart`, `*.drift.dart` — never hand-edited, always skipped by the gate | `database.g.dart` |

There is no `lib/src/`, no `utils.dart`, no `constants.dart`, no `models/` folder, no `shared/` or
`common/` under `features/`, and no per-feature `data/` folder.

### 4.2 Classes and types

| Role | Suffix / shape | Layer it reveals |
|---|---|---|
| drift table | plural `PascalCase` (`Lambings`) | `lib/core/db/tables/` |
| drift row class | singular `PascalCase` (`Lambing`) | re-exported by `lib/data/models.dart` |
| Repository | `<Area>Repository` | `lib/data/` — **may write** |
| Service / gateway | `<Name>Service`, `<Name>Store`, `<Name>Scheduler`, `<Name>Recorder`, `<Name>Controller` (platform) | `lib/data/` — touches one plugin |
| Screen widget | `<Screen>Screen` | `lib/features/<f>/` |
| Screen controller | `<Screen>Controller` extending `Notifier`/`AutoDisposeFamilyAsyncNotifier` | `lib/features/<f>/` — no `BuildContext`, no drift |
| Write controller | `<Feature>WriteController` extending `WriteController` | `lib/features/<f>/` — the only mutation path |
| Immutable screen state | `<Screen>State` | `lib/features/<f>/` |
| Value type | no suffix (`Instant`, `Grams`, `RecordedTime`) | `lib/domain/` — pure |
| Sealed result | no suffix; variants are nouns (`WriteCommitted`, `ClearsOn`) | — |
| Design token set | `Shed*` (`ShedTokens`, `ShedTapTarget`, `ShedKeypad`) | `lib/core/ui/` |

`Manager`, `Helper`, `Util`, `Handler`, `Impl` and `Abstract*` are banned suffixes. `DatabaseService`
is banned outright — `AppDatabase` is already the data-source wrapper.

### 4.3 Providers

`<typeNameLowerCamel>Provider`, declared as a top-level `final` global in the file listed in §3.

Five documented exceptions, because two documents already agree on them and renaming buys nothing:
`databaseProvider`, `settingsProvider`, `wakelockProvider`, `minuteTickProvider`, `tagIndexProvider`.

- Read providers are named after **what they read** (`penBoardProvider`), never after the screen.
- Controller providers are named after **the screen** (`penBoardControllerProvider`).
- A family provider's name is singular: `eweCardControllerProvider(eweId)`.

### 4.4 Controllers

1. One screen controller per screen, holding **screen state, never data**.
2. One write controller per feature; **every** mutation goes through `WriteController.guard()`.
3. Controllers hold no `BuildContext`, never navigate, never show a SnackBar, never format for
   display, never import drift, and never hold a draft.
4. Anything the user typed lives in a **private field** on the notifier, not only in `state`.
5. Derived collections are stored fields computed in a factory, never getters.
6. `WriteCommitted.warnings` is populated **here**, by calling `lib/domain/validation/`, never by a
   repository (R53).

### 4.5 Widget keys

`<screen>.<element>[.<qualifier>]` — every segment `lower_snake`, segments joined by `.`:

```
quick_entry.keypad.digit_4
quick_entry.confirm
lambing_entry.birth_type.twin
pen_board.turn_out.3
treatment.withdrawal.enter_days
```

`Key('birthType.twin')` is a defect (R59). Keys are stable: a key is a test contract, so renaming one
is a breaking change to `test/features/`.

### 4.6 Database names

| Thing | Convention |
|---|---|
| Table (Dart) | plural `PascalCase` — `TreatmentWithdrawals` |
| Table (SQL) | plural `snake_case` — `treatment_withdrawals` |
| Column (Dart) | `lowerCamel` — `declaredBirthType` |
| Column (SQL) | `snake_case` — `declared_birth_type`; `customConstraints` always use the SQL name |
| Foreign key column | the parent's singular noun, no `_id` suffix — `ewe`, `lambing`, `season` |
| Index | `idx_<table-abbrev>_<columns>` — `idx_lambing_season_time` |
| Named `.drift` query | `lowerCamel` — `penBoard`, `inThePens`, `sweepSearchDocs` |
| View | `snake_case` noun — `lamb_rearing`, `lambing_consistency` |
| Stored enum key | `snake_case`, ASCII, frozen forever — `born_alive_per_ewe_to_ram` |
| Vocabulary key | `<list-prefix>_<term>` — `dc_starvation`, `mp_breech`, `rt_oral`, `obs_prolapse`, `fm_skin`, `ease_1` |
| Event-time column | `occurred_at`, with exactly three documented exceptions: `treatments.administered_at`, `pen_occupancies.entered_at`, `foster_events.effective_at` (R37) |
| Provenance columns | always `captured_at`, `original_effective`, `time_source` — never `original_effective_at` (R38) |

### 4.7 Policy rule ids

Dotted `namespace.name`, all `lower_snake` (R54). The namespaces: `layer`, `net`, `time`, `rp3`,
`stream`, `db`, `stat`, `a11y`, `gesture`, `token`, `theme`, `type`, `ui`, `main`, `dep`, `launch`,
`copy`.

04's `snake_case` ids are renamed:

| 04's id | Canonical |
|---|---|
| `no_destructive_ddl` | `db.destructive_ddl` |
| `banned_build_options` | `db.banned_build_option` |
| `no_drift_datetime` | `db.drift_datetime` |
| `migration_uses_historical_schema` | `db.migration_today_schema` |
| `no_sql_side_time` | `time.sql_now_*` (already exists — do not add a duplicate) |
| `no_async_in_assert` | `db.async_in_assert` |
| `no_blob_columns` | `db.blob_column` |
| `path_provider_confined` | `layer.path_provider` |
| `single_clock` | `time.dart_clock` (already exists) |
| `banned_identifiers` | one row per identifier, e.g. `media.opus` |
| `no_base64_in_backup` | `copy.base64_backup` |
| `disclaimer_referenced_not_retyped` | `copy.disclaimer_retyped` |

Rows this file adds that no document had as a row: `ui.spinner`
(`CircularProgressIndicator` under `lib/features/`), `ui.show_dialog` (`showDialog(` outside the two
allowlisted destructive files), `copy.currency_literal` (a currency symbol followed by a digit under
`lib/` or `assets/`), `db.save_verb` (`save\w*\(` under `lib/data/`),
`layer.data_no_validation`.

`tool/policy_allowlist.txt`'s `[exempt]` section has exactly **four** lines on day one (R56):

```
lib/core/time/app_clock.dart       :: time.dart_clock
lib/core/ui/night_error_panel.dart :: token.raw_color
lib/core/ui/primitives.dart        :: token.raw_color
lib/core/ui/palettes.dart          :: token.primitives_import
```

---

## §5 Vocabulary

One word per concept, everywhere: prose, class names, ARB keys, column names, commit messages.

### 5.1 Product and domain nouns

| Use | Never | Why |
|---|---|---|
| **record** (the stored fact a shepherd thinks of) | entry (as a noun), item, object, document | "entry" is reserved for the *act* of typing |
| **entry** (the act, and the screens for it) | input, capture (for typing) | Quick Entry, Lambing Entry, `EntryContext` |
| **event** (a row in an append-only/history table; also the verb form of a write) | action, transaction (for a domain fact) | `FosterEvent`, `CareEvent`, "event verb" |
| **warning** (`List<Warning>`, spec §12.4) | **flag**, issue, problem, validation error | R71. `flags` is banned in prose *and* in code; the field is `warnings` because its type is `List<Warning>` |
| **withdrawal period** (first use), **withdrawal** (thereafter) | withholding, WHP, "the days" | spec §12.1 |
| **clear date** | safe date, withdrawal end date, "clears on" (as a noun) | it is what the app *told* the user |
| **tag** | ear tag, number, ID | `ewes.tag`; `tag_digits` is a projection and is never shown |
| **birth dam** / **rearing dam** | mother, dam (unqualified), foster mum | two distinct traits; never merged |
| **birth type** / **rearing type** | litter size (for the declared value) | `declared_birth_type` is what was tapped |
| **turn out** (verb, two words) / **turn-out** (adjective) | turnout (one word) | the stored key is `turn_out` everywhere, including the Android channel id (R49) |
| **penned** / **pen occupancy** | housed, in the pen (as a state name) | |
| **barren** | empty, not in lamb | stored as `ewe_seasons.status = 'barren'` (R42) |
| **stillborn** | died at birth, dead-born, "died at age 0" | its own bucket, never folded into day-0 deaths |
| **unattributed** (a blank cause) | unknown | "unknown" is a cause the user can pick (`dc_unknown`); "unattributed" is our word for a blank field. Never merge the columns. |
| **season** | year, campaign | |
| **provenance** / **provenance label** | audit, source (unqualified), metadata | `RecordedTime.provenanceLabel` |
| **the free tier** / **the cap** | trial, freemium, paywall | there is no trial period |
| **unlock** | purchase, buy, subscribe | one non-consumable IAP, forever |
| **shed screen** | 3am screen (in code/keys) | the five screens that render nothing monetization-related |

### 5.2 Engineering nouns

| Use | Never |
|---|---|
| **gateway** (the collective noun for the seven seams — six platform, one store) | platform service, adapter, wrapper, client (R71, R74) |
| **repository** (the only writer) | DAO, store (except `MediaStore`), service (for data) |
| **controller** (presentation shaping) | view model, presenter, bloc |
| **write controller** | command, mutation, action |
| **the gate** (`tool/check_policy.dart`) | linter, plugin, checker |
| **the diagnostics log** (`LocalLog`) | crash log, telemetry, analytics — *there is none* |
| **the backup** (JSON) | dump, snapshot, sync | 
| **the snapshot** (`VACUUM INTO`, and the drift schema JSON) | backup |
| **reconcile** (the OS notification projection) | schedule, sync, refresh (R51) |
| **projection** (the windowed OS notification list) | queue, cache (in copy) |
| **the deck** (Quick Entry's two selection strips) | picker, chooser |
| **restore** (replace everything) | import, merge — **there is no merge** |
| **export** (records off the phone) | backup (when it means the JSON file, use "backup"; when it means the action, "export") |

### 5.3 Banned words, absolutely

`draft`, `isDirty`, `save()`, `commit()`, `submit()`, `pending` (as a model state), `sync`,
`synchronized`, `offline-first` (in our own prose — Shed Book is **offline-only**), `flags` (use
`warnings`), `Error` as a failure-type name, "your data never leaves your phone", "a lost phone is
lost data" unqualified, "verified"/"secure" about the backup checksum, "compliance record",
"official record", "recommended dose", "should".

### 5.4 Copy conventions

- **Dates a human reads are never all-numeric.** `d MMM y` (`11 Mar 2026`). Numeric dates appear only
  inside CSV, beside an ISO-8601 column. `07-screens.md` §10.3's `clear on 11/03/2026` is a defect
  (R60).
- **Times are 24-hour `HH:mm`**, `en_GB`. There is no 12-hour path.
- **Every displayed event time carries its provenance label.** A bare `03:21` is a review failure.
- **Every statistic carries its `definition` string, verbatim from
  `LambingPercentageChoice.definition`** (R61). Paraphrasing it in a screen brief is a defect,
  because the same string is printed into CSVs and PDFs that outlive the app.
- **The price is never a literal.** `ProductDetails.price` from the store, always.
- **The three palette labels are 06's, verbatim** (R35): `Night`, `Amber (recommended)`,
  `Deep red (best for night vision, hardest to read)`, plus a separate `High contrast` switch.

---

## §6 The ruling log

R1–R11 are the owner's, already settled. R12 onward are this review's, ruled under the authority
order at the top of this file. Cite the number.

### The owner's eleven — apply, do not re-open

| # | Ruling | Files that must change |
|---|---|---|
| **R1** | The schema package is **`lib/core/db/`**. | 03 (`views.drift` × 2, the `build.yaml` `databases:` path, every `lib/data/db/` path, the §1.4 note), 04 (`git add`, `drift_dev schema dump`, `build.yaml`, every path, the §0 divergence note), 05 (§1.1 file map, the converters header) |
| **R2** | The class is **`AppDatabase`**; the opener is **`openAppDatabase()`**. | 03 (`class ShedBookDatabase extends _$ShedBookDatabase`, `seedFirstRun(ShedBookDatabase)`, `_$` references, DoD), 04 (every `ShedBookDatabase`), 01 + 02 (`openShedBookDatabase()`) |
| **R3** | `WriteCommitted` is **non-generic** with fields **`insertedId`** and **`warnings`**. | 02 (`:final flags`), 04 (the generic `WriteOutcome<LambingId>` signature), 07 (`:final id`) |
| **R4** | There is no `ShedFailure.from(e, s)`. The mapping is **`shedFailureFrom(Object)`** in `lib/data/failure_mapping.dart`. | 02 |
| **R5** | ID extension types live in **`lib/domain/ids.dart`**. | 03 |
| **R6** | **`Lambings.declaredBirthType` is nullable.** Must land before the first schema snapshot. | 03 |
| **R7** | Add **`@DataClassName('PenOccupancy')`** and **`@DataClassName('EweTouch')`**. | 03 |
| **R8** | **`UnexpectedFailure(Object error, StackTrace stack)`**. | 01 |
| **R9** | **`CameraService` / `VoiceRecorder` / `WakelockController`** keep these exact names and get a home in the tree. | 08 (new) |
| **R10** | **`confirmSaved` / `showFailure` / `showCapRow`** are the three confirmation channels, under those exact names. | 06 |
| **R11** | **`markCleanPause()` / `session.lock`** under those exact names. | 13 (new) |

### R12 — The connection file, the opener and the setup function

Three spellings existed: `lib/core/db/open.dart` + `openShedBookDatabase()` (01, 02),
`lib/data/db/connection.dart` + `openConnection()` + `_configureConnection` (03),
`lib/data/db/connection.dart` + `configureConnection` (04).

**Ruling.** `lib/core/db/connection.dart` holds all three:
`Future<AppDatabase> openAppDatabase()` (the app entry point, asserts it is not under `flutter_test`),
`QueryExecutor openConnection()` (the only `driftDatabase(` call site), and
`void configureConnection(CommonDatabase db)` (top-level, **public**, captures nothing — it crosses an
isolate boundary, and a private name cannot be referenced from a test).
File name follows 03 and 04 (majority, and both carry the real code); `open.dart` does not exist.
**Files:** 01 (tree line + §4.1 + §6.3), 02 (§5.1, §5.4), 03 (§1.3), 04 (§2.8).

### R13 — The connection pragma set is the union, in one place

03 sets `journal_mode`, `synchronous`, `foreign_keys`, `busy_timeout`, `recursive_triggers` + the FTS5
assertion. 04 sets `journal_mode`, `synchronous`, `foreign_keys`, `busy_timeout`,
`journal_size_limit`, `temp_store` + the pre-migration snapshot. Neither is a superset.

**Ruling.** One `configureConnection` running, in order: `journal_mode = WAL`, `synchronous = FULL`,
`foreign_keys = ON`, `busy_timeout = 5000`, `journal_size_limit = 4194304`, `temp_store = MEMORY`,
`recursive_triggers = ON`, `_assertEngineCapabilities(db)`, `_snapshotBeforeMigration(db)`.
Every one of those is load-bearing in one of the two documents; dropping any is a regression.
**Files:** 03 (§1.3), 04 (§2.8).

### R14 — `AppDatabase`'s constructor

03 declares `(super.e, {this.seedOnCreate = true})`; 04 adds `schemaVersionOverride`.

**Ruling.** 04 owns migrations, so the class carries both:
`AppDatabase(super.e, {this.seedOnCreate = true, this.schemaVersionOverride = kSchemaVersion})`, with
`@visibleForTesting final int schemaVersionOverride` and
`@override int get schemaVersion => schemaVersionOverride;`.
**Files:** 03 (§1.4).

### R15 — `newUid()` splits from the id types

R5 puts the id extension types in `lib/domain/ids.dart`. `newUid()` needs `package:uuid`, which layer
rule 1 forbids in `lib/domain/`. `lib/core/db/seed/first_run.dart` needs it, and `lib/core/db/` may not
import `lib/data/`.

**Ruling.** `String newUid()` lives in **`lib/core/db/uid.dart`**, the one `package:uuid` call site in
the app. `lib/core/db/`'s allowed packages gain `package:uuid`. `lib/data/ids.dart` does not exist.
**Files:** 03 (§3), 04 (`import 'ids.dart'` in `media_store.dart`, §4.6), 01 (layer rule 2 table and
`_bannedPackages`).

### R16 — Layer rule 2 is amended: `lib/core/db/` may import `lib/core/`

As written, `_mayImport['lib/core/db/'] = {'lib/core/db/', 'lib/domain/'}` makes
`first_run.dart` unable to call `appNow()` and `connection.dart` unable to reach `LocalLog`.

**Ruling.** `_mayImport['lib/core/db/'] = {'lib/core/db/', 'lib/core/', 'lib/domain/'}`. Because
`_layers` matches most-specific-first, `lib/core/ui/` still resolves to its own layer and remains
banned, so rule 2's stated prohibition is unchanged.
**Files:** 01 (§3.1 table, §3.2 `_mayImport`).

### R17 — `lib/domain/`'s internal structure is 05's, not 01's

01 lists flat files; 05 lists subfolders. Both are the "canonical" tree in their own document.

**Ruling.** 05's map wins (it owns the domain and is finer-grained). The mapping a fixer applies to
01 §2.2:

| 01's file | Becomes |
|---|---|
| `withdrawal.dart` | `withdrawal/{withdrawal_period,withdrawal_status,clear_date}.dart` |
| `season_stats.dart` | `stats/{definitions,season_counts,lambing_percentage,litter_size,barren_rate,assisted_rate,losses,lambing_spread}.dart` |
| `consistency.dart` | `validation/{warning,lambing_checks,foster_checks,treatment_checks}.dart` |
| `animal_class.dart` | `terminology/animal_class.dart` |
| `units/mass.dart` | `units/grams.dart` |
| `units/temperature.dart` | `units/milli_celsius.dart` |
| `death_cause.dart` | **deleted** — death causes are `vocab_terms(list='death_cause')`, a user-editable vocabulary (03 convention 6), not a domain enum |

`lib/domain/consistency.dart` is a banned import path (02 §7 cites it).
**Files:** 01 (§2.2, mkdir), 02 (§7).

### R18 — `lib/data/` is flat; there is no `SeasonStatsRepository`

05 §6.3 writes `lib/data/repositories/season_stats_repository.dart`; 01's tree is flat.

**Ruling.** 01 owns the tree: `lib/data/` has no subfolders. And the season-summary reads belong to
**`SeasonRepository`** — a repository that only reads is a query object wearing a repository's name,
and 03 §5.14 already assigns the season tables to `SeasonRepository`.
`watchSeasonCounts` and `watchSpread` are `SeasonRepository` methods.
**Files:** 05 (§6.3 header comment and §6.9).

### R19 — The repository set is twelve, and it is closed

01 lists eight; 03 §5.14 lists ten plus `RestoreService` and omits `ExportRepository`.

**Ruling.** The union, twelve entries, as tabulated in §2.13. Adding a thirteenth is a schema-review
conversation, not an edit.
**Files:** 01 (§2.2 tree), 03 (§5.14 — add `ExportRepository`).

### R20 — `lib/data/models.dart` must export every row class

01's export list has 12 names; the schema has 23 tables. `Note`, `MediaAsset`,
`TreatmentWithdrawal`, `AppSetting`, `VocabTerm`, `EweSeason` and `EweSummary` are all rendered by
screens, and `lib/features/` cannot import `lib/core/db/` to get them.

**Ruling.** The export list is all 23 row classes, as printed in §2.8. `AppSettings` also carries
`@DataClassName('AppSetting')` and `EweSummaries` carries `@DataClassName('EweSummary')` — 03 already
declares both; 01's DoD line already names all four, so only the export list is wrong.
**Files:** 01 (§2.3).

### R21 — Converters are one file, not a directory

01's tree has `core/db/converters/`; 03 and 05 both write a single `converters.dart`.

**Ruling.** `lib/core/db/converters.dart`. A directory holding one file is ceremony.
**Files:** 01 (§2.2, mkdir).

### R22 — The `.drift` files sit directly in `lib/core/db/`

01's tree has a `views/` subdirectory of `*.drift` files. 03 puts `views.drift`, `search.drift` and
`queries.drift` at the package root and registers exactly those three. 04's `include:` omits
`queries.drift`.

**Ruling.** Three files, no subdirectory:
`@DriftDatabase(tables: [...], include: {'search.drift', 'views.drift', 'queries.drift'})`.
`views.drift` holds `CREATE VIEW` **and** the non-search table triggers (the birth-dam immutability
trigger lives there, as 03 already writes it); `search.drift` holds `search_docs`, `search_fts` and
the FTS5 sync triggers; `queries.drift` holds named queries.
**Files:** 01 (§2.2), 04 (§2.3 `include:`).

### R23 — `appNow()` is the only wall-clock reader

05 defines `appNow()`; 01, 02 and 03 call `clock.now()` directly in `lib/data/` and `lib/core/db/`.

**Ruling.** 05 owns time. `Instant appNow()` in `lib/core/time/app_clock.dart` is the single reader;
every repository, controller, seed and sweep calls `appNow()`, never `clock.now()`.
`app_clock.dart` keeps the `time.dart_clock` allowlist entry so the rule has exactly one reviewable
exception point. Tests still install time with `withClock(...)`.
**Files:** 01 (§4.2 `Instant.fromDateTime(clock.now())`, §4.3 rule 1, §7.2 ticker), 02 (§9.1
`_hiddenAt = clock.now()`, `ResumePolicy` call sites), 03 (§8 `sincePenned`, §10 `seedFirstRun`).

### R24 — `package:clock` is banned in `lib/domain/`, and `sincePenned` must take `now`

05 D3 bans it; 01 layer rule 1 explicitly permits it. 03 §8 defines
`Duration sincePenned(Instant enteredAt) => clock.now().difference(enteredAt.utc);` — which would sit
in the domain and read a clock.

**Ruling.** 05 wins: `'package:clock/'` joins `_bannedPackages['lib/domain/']` and drops out of rule
1's "may import" column. The pen function is
**`Duration timeSincePenned(Instant enteredAt, Instant now)`** in `lib/domain/penning.dart`
(01's spelling, 05's purity). `sincePenned` is a banned name.
**Files:** 01 (§3.1 rule 1, §3.2 `_bannedPackages`), 03 (§8).

### R25 — The ticker: one name, one element type, one dispose policy

Three spellings existed: `minuteTickerProvider` / `StreamProvider<Instant>` / keepAlive (01),
`minuteTickProvider` / `StreamProvider.autoDispose<DateTime>` (02),
`penTickProvider` / `StreamProvider.autoDispose<DateTime>` (07).

**Ruling.** **`minuteTickProvider`**, **`StreamProvider.autoDispose<Instant>`**, in
`lib/core/time/ticker.dart`. Name and dispose policy from 02 (which owns providers and the
auto-dispose policy) and 07 (whose battery argument is the reason `autoDispose` is load-bearing);
element type `Instant` from 05 (a provider yielding a raw `DateTime` puts an unwrapped instant in the
UI layer, which is exactly what `Instant` exists to prevent). `minuteTickerProvider` and
`penTickProvider` are banned.
**Files:** 01 (§7.2), 07 (§1.2, §9.2, §11.1).

### R26 — The tag index provider

02 calls it `tagIndexProvider`; 07 calls it `flockTagCacheProvider`.

**Ruling.** **`tagIndexProvider`**, `StreamProvider<List<TagIndexEntry>>`, keepAlive, active animals
only. 02 owns providers, and the element type is already `TagIndexEntry`, so "cache" names the
implementation while "index" names the value.
**Files:** 07 (§1.2, §5.2).

### R27 — `rankTagMatches` lives in `lib/domain/tag_match.dart`

03 §9.1 prints its body under `lib/features/quick_entry/tag_matcher.dart`; 01, 02 and 07 all put it in
`lib/domain/tag_match.dart`.

**Ruling.** `lib/domain/tag_match.dart`, holding both `rankTagMatches` and `TagIndexEntry`. The Flock
search box and the Foster screen both call it, and layer rule 6 forbids one feature importing another,
so the feature-folder placement is not merely inconsistent — it is unbuildable.
**Files:** 03 (§9.1).

### R28 — Quick Entry's two strips are one provider

02 declares `recentEwesProvider` and `inPensProvider` as separate hub providers; 07 §5.2 feeds both
strips from a single `quickEntryDeckQuery`.

**Ruling.** One statement, one provider: **`quickEntryDeckProvider`**,
`StreamProvider<QuickEntryDeck>`, keepAlive, where `QuickEntryDeck` is
`({List<DeckEntry> penned, List<DeckEntry> recents})`. `_InPensStrip` and `_RecentsStrip` read it
with `.select((d) => d.penned)` / `.select((d) => d.recents)`. This satisfies 02's rebuild rules and
07's one-statement rule at once. `recentEwesProvider` and `inPensProvider` are banned.
**Files:** 02 (§4.1, §4.2, §10.1), 07 (§5.2 — name the provider).

### R29 — `settingsProvider` carries the row class, and `themeProvider` is synchronous

02 declares `settingsProvider : StreamProvider<AppSettings>` — that is the **table** class. 03
annotates the table `@DataClassName('AppSetting')`, so the row class is `AppSetting`. Separately, 06
§2.1 refers to `appSettingsProvider`.

**Ruling.** `settingsProvider : StreamProvider<AppSetting>`. `appSettingsProvider` is banned.
`themeProvider : Provider<ShedThemeSet>` is **synchronous** (06's requirement — the first frame paints
before the database opens) and derives from `settingsProvider` through an exhaustive `switch` whose
non-`AsyncData` arm returns the `const night` pair. No `AsyncValue` accessor is used to do it.
**Files:** 02 (§5.1 graph), 06 (§2.1 comment).

### R30 — The three feedback functions, their file and their signatures

R10 fixes the names. Three further spellings were live: `showShedReceipt(context, {required SaveReceipt r})`
(06), `showShedFailure(context, failure)` (07), and `confirmSaved(context, ref, warnings)` (02).

**Ruling.** All three live in **`lib/core/ui/feedback.dart`**, which becomes the one file permitted to
call `showSnackBar(` (the `gesture.raw_snackbar` rule now points there):

```dart
void confirmSaved(BuildContext context, SaveReceipt receipt, List<Warning> warnings);
void showFailure(BuildContext context, ShedFailure failure);
void showCapRow(BuildContext context, RefusalReason reason);
```

`confirmSaved` takes no `WidgetRef` — a feedback function holds a `BuildContext` and nothing else.
`components/shed_receipt.dart` keeps only the `ShedReceiptBar` widget. `showShedReceipt` and
`showShedFailure` are banned.
**Files:** 02 (§7 call site), 06 (§3.5 rule, §10.3), 07 (§6.1).

### R31 — `SaveReceipt`

06 uses it without declaring its fields.

**Ruling.** `lib/core/ui/feedback.dart`:
`final class SaveReceipt { final String term, tag, summary, at; final VoidCallback? undo; final String undoLabel; }`
`at` is pre-formatted `HH:mm` by `lib/core/ui/formatters.dart`. `undoLabel` exists because the label is
not always "UNDO": it is "Correct this" on a foster and "Void this" on a treatment (07 §15.3).
**Files:** 06 (§10.3).

### R32 — `beginLambing` and `addLamb` return an id and throw

01 §4.2 is explicit: the two verbs that mint a row the caller must navigate to return the new id and
throw. 07 §6.1 shows `beginLambing` returning a `WriteOutcome` and switching on
`WriteCommitted(:final id)` — which also contradicts R3.

**Ruling.** 01 owns the write path. `Future<LambingId> beginLambing(EweId ewe)` and
`Future<LambId> addLamb(LambingId, {required Sex sex})` throw; the global error net handles the
failure, because there is no id to hand back and the screen cannot open. Every other write returns
`WriteOutcome`. 07 §6.1's snippet becomes a `try`/`catch` (or simply awaits and pushes).
**Files:** 07 (§6.1).

### R33 — Ids cross boundaries; `int` does not

07 §6.1 passes `int eweId` and declares
`AutoDisposeFamilyAsyncNotifier<LambingEntryState, int>`; 02 §4.2 requires the extension-type ids as
family arguments.

**Ruling.** Every repository parameter, controller family argument, route-helper argument and
provider-family key is an extension type from `lib/domain/ids.dart`. A bare `int` appears only inside
`lib/core/db/` (companions and raw rows) and as `WriteCommitted.insertedId`, which the single reading
call site wraps.
**Files:** 07 (§6.1, §6.2).

### R34 — `ShedBookApp` is a `ConsumerStatefulWidget`

06 §2.1 declares `class ShedBookApp extends ConsumerWidget`. 01 §6.3 needs `initState` for the
post-frame boot kick and 02 §9.1 needs `WidgetsBindingObserver` on its `State`.

**Ruling.** `ConsumerStatefulWidget` with `_ShedBookAppState extends ConsumerState<ShedBookApp> with
WidgetsBindingObserver`. It is the only stateful widget above the router. 06 owns the theme half of
`build()`, not the widget's kind.
**Files:** 06 (§2.1).

### R35 — Palette ids, stored keys and Settings labels

Three mismatches: `app_settings.palette` stores `('dark','amber','red')` (03) while
`ShedPaletteId` is `{night, amber, deepRed}` (06); 06's Settings labels are
`Night / Amber (recommended) / Deep red (…)`, 07 §14.3's are
`Dark (default) / Night — amber (recommended in a shed) / Deep red (…)`.

**Ruling.**
1. `ShedPaletteId { night, amber, deepRed }` with a `key`: `'night'`, `'amber'`, `'red'`.
2. `app_settings.palette`'s CHECK becomes `IN ('night','amber','red')` — 03 changes `dark`→`night`, so
   the stored key and the enum key are the same string (the §5.2/§8.3 stable-key rule).
3. The Settings labels are **06's four, verbatim**: `Night`, `Amber (recommended)`,
   `Deep red (best for night vision, hardest to read)`, and a separate `High contrast` switch. 06 owns
   the design system.
**Files:** 03 (§5.13), 07 (§14.3 §6).

### R36 — The pen-tile status set is 06's

06 §11 has five statuses (settling, ready, attention, loss, **empty pen**) with fixed label text;
07 §9.3 has four and different text (`12h · TREATING` vs `12h · CLEAR 14 JUL`).

**Ruling.** 06's five-row table, including its label text, is canonical. 07 keeps the *behaviour*
(sorting, the READY legend naming the user's own threshold) and adopts 06's labels and the empty-pen
row.
**Files:** 07 (§9.3).

### R37 — The §12.5 provenance quad, and the event-time column names

05 §4.2 requires the quad on `Lambings`, `Treatments`, `CareEvents`, `FosterEvents`,
`EweObservations`, `Notes` and deaths. 07 additionally requires it on `PenOccupancies` because the pen
tile renders an entry time. 03 ships it on three tables only. `Notes` has no `occurred_at` at all.

**Ruling.** 03 adds `captured_at INTEGER NOT NULL`, `original_effective INTEGER`,
`time_source TEXT NOT NULL DEFAULT 'auto'` plus both paired CHECKs to **`PenOccupancies`,
`FosterEvents`, `Notes` and `EweObservations`**, and adds `notes.occurred_at INTEGER NOT NULL`
(distinct from the mixin's `created_at`). This must land **before the first schema snapshot**: adding
a `NOT NULL` column afterwards is a full table rebuild on tables that point at the user's records.
Until it lands, the standing rule is absolute: **a table without the quad has no edit verb.**

Event-time column names, canonical with three documented exceptions:
`occurred_at` everywhere, except `treatments.administered_at`, `pen_occupancies.entered_at` and
`foster_events.effective_at`. All three are domain-meaningful and already agreed by two documents each.
**Files:** 03 (§5.7, §5.9, §5.11, §7), 05 (§2.2 table — add the four rows), 07 (§22 items 3 closes).

### R38 — `original_effective` — no live conflict; delete the stale claims

07 §1.5 and §22 item 8 assert that 05 §4.2 spells the column `original_effective_at`. It does not;
05 writes `original_effective` in both its SQL block and its Dart. The conflict is phantom.

**Ruling.** The column is `original_effective` (Dart `originalEffective`) everywhere. 07 must delete
the claim rather than "resolve" it, because a doc set that records fictional conflicts trains readers
to stop trusting the conflict list.
**Files:** 07 (§1.5 last paragraph, §22 item 8).

### R39 — `Instant.fromDateTime` and `RecordedTime.capture` — no live conflict; delete the stale claims

05 §1.1's "wrong spellings currently in the set" table lists `Instant.fromUtc(...)` and
`RecordedTime.captured(...)` as appearing in 01 §4. Neither string appears anywhere in the set; 01
already writes `Instant.fromDateTime(clock.now())` and `RecordedTime.capture(now)`.

**Ruling.** Both canonical spellings stand. 05 deletes rows 2 and 3 of its §1.1 table and keeps row 1
(`appNow()` vs `Instant.now()`), which is real — 04 referenced `appNow()` before 05 defined it, and
R23 settles it.
**Files:** 05 (§1.1).

### R40 — Two `app_settings` columns must exist

07 renders `AppSettings.lastReconcileScheduled` (the honest reminder line has no data source without
it) and a left-handed layout toggle; 03 declares neither.

**Ruling.** 03 adds `last_reconcile_scheduled INTEGER` (nullable; written by `reconcile()` in the same
transaction that records the projection) and `left_handed INTEGER NOT NULL DEFAULT 0`.
**Files:** 03 (§5.13).

### R41 — `ewes.status` stays a mutable column; there is no status-history table

07 §4.3 and §15.1 render "a history row" per status change and cite decision #31; 03 has a mutable
`ewes.status` and no sibling table.

**Ruling.** 03 owns the schema, and decision #31's history-table rule is instantiated by decisions #33
(fostering) and #34 (pen occupancy) only — no decision creates `ewe_status_events`. `ewes.status`
remains a mutable column with `updated_at` moving. **07 strikes "a history row" and "correction-forward
with a history row"** from §4.3 and §15.1; `setStatus` has no undo verb because the previous value is
recoverable from the record's own context, not because a history row exists.
*Escalate to the owner if the retention story turns out to need "she was culled in March 2025 and
un-culled in April" — that is a schema addition, and it must land before the first snapshot.*
**Files:** 07 (§4.3, §15.1, §22 item 4).

### R42 — Barren is `ewe_seasons.status = 'barren'`

07 §4.3 states that "barren" is an `EweObservations` row and that the §7.7 filter reads it from there.
03's `ewe_seasons.status` CHECK includes `'barren'`, 05 §6.6 computes the barren rate from
`ewesRecordedBarren`, and the `ewe_observation` vocabulary has no barren key (it is
`obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`,
`obs_other`).

**Ruling.** Barren is a **season participation outcome**: `ewe_seasons.status = 'barren'`. The §7.7
flock filter joins `ewe_seasons` for the current season. `EweObservations` never carries it.
**Files:** 07 (§4.3, §22 item 4).

### R43 — `EweSeasonOutcome` is a bucketing, not a replacement

05 §6.6 declares `enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }`;
03's column holds seven keys (`to_ram`, `scanned`, `lambed`, `barren`, `aborted`, `died`, `sold`).

**Ruling.** The seven stored keys are canonical. `EweSeasonOutcome` is a derived four-way bucketing
used only by the statistics functions, with the mapping stated at its declaration:
`lambed`←`lambed`; `recordedBarren`←`barren`; `diedOrSoldBeforeLambing`←`died`|`sold`|`aborted`;
`notRecorded`←`to_ram`|`scanned`|absent. It never round-trips to the database.
**Files:** 05 (§6.6).

### R44 — `LambingEase` carries an ordinal, not descriptions

01's tree comments `lambing_ease.dart # LambingEase 1..5 + the five authored descriptions`;
03 §10.1 makes the five descriptions `vocab_terms` rows `ease_1`…`ease_5` whose labels are ARB
messages. A domain file cannot hold ARB text (layer rule 1 bans `intl`/`AppLocalizations`).

**Ruling.** `extension type const LambingEase(int code)` with validation to 1..5 and nothing else.
The labels come from `vocab_terms` + ARB, resolved at the presentation edge.
**Files:** 01 (§2.2 tree comment).

### R45 — `Sex` member names carry the stored key

01's tree says `male/female/unknown`; 03 stores `('f','m','unknown')`.

**Ruling.** `enum Sex { female('f'), male('m'), unknown('unknown') }` with `fromKey`. `NULL` means
not recorded and is never the `unknown` member — that distinction is the whole point of the column.
**Files:** 01 (§2.2 tree comment), 03 (`lambs.sex` doc comment cross-reference).

### R46 — `BirthType` and `expectedLambCount`

01 puts `code` + `expectedLambCount` on `lib/domain/birth_type.dart`; 05 §1.1 says the file is owned by
03; 05 §7.5 declares `int? expectedLambCount(BirthType)` in its validation section.

**Ruling.** `lib/domain/birth_type.dart` holds `enum BirthType` (with `final int code` 1..5) **and**
the top-level `int? expectedLambCount(BirthType)` — returning `null` for `quintPlus`, which is
load-bearing: a contradiction is *undefined*, not false, for an open-ended type. Ownership: 05 for
the semantics, 03 for the stored codes.
**Files:** 05 (§1.1 ownership note, §7.5 file header).

### R47 — Camera and voice capture belong to their gateways, not to `MediaStore`

04 §4.4 puts `ImagePicker().pickImage(...)` and `AudioRecorder()` in
`lib/data/media_store.dart` as "a method ON MediaStore". 02 §5.1 assigns `image_picker` to
`CameraService` and `record` to `VoiceRecorder`, each wrapping exactly one plugin so the fake in
`test/` tests the real path.

**Ruling.** 02 owns the DI graph and R9 blesses the three names.
`CameraService` owns `image_picker` (`pickImage`, `retrieveLostData`); `VoiceRecorder` owns `record`;
`MediaStore` owns the media root, `newRelativePath`, `resolve`, `writeAtomically` and the
`flutter_image_compress` downscale. The capture flow is: `CameraService.pick()` → `MediaStore`
compresses and writes → `NoteRepository` inserts the `media_assets` row.
**Files:** 04 (§4.4).

### R48 — `package:timezone` lives in `lib/data/notification_scheduler.dart`

05 §2.7 names `lib/features/reminders/notification_gateway.dart` as "the ONLY place tz appears".

**Ruling.** That file does not exist. The tz seam is inside `NotificationScheduler`, the gateway that
wraps `flutter_local_notifications` — putting plugin-adjacent code in a feature folder makes it
untestable through the container and unswappable by a fake. `scheduleTimeFor(Instant)` is a private
method on `NotificationScheduler`.
**Files:** 05 (§2.7), 08 (adopt).

### R49 — Reminder kinds and Android notification channel ids are the same strings

Decision #65 names channels `colostrum, navel, turnout, tag_by, dose, withdrawal`. 03's
`reminders.kind` CHECK is `colostrum, navel, turn_out, tag_by, ring_dock_castrate, second_dose,
withdrawal_end, custom`. Three of the six channel names do not match any kind.

**Ruling.** 03 owns stored keys. There is **one** set of strings, 03's eight, and the Android channel
id is byte-identical to the kind. `turnout`, `dose` and `withdrawal` are banned channel ids. Channel
ids are frozen at release, so this must be right before the first release, not before the first
snapshot.
**Files:** 08 (adopt), and note the deviation from decision #65's wording in 08's decision list.

### R50 — `ReminderBudget`

07 §11.2 calls `ReminderBudget.forPlatform()` and requires that the same constant slices the
projection and feeds the copy. Nothing declares it.

**Ruling.** `abstract final class ReminderBudget { static int forPlatform(); }` in
`lib/domain/reminder_budget.dart` — 56 on iOS, 200 on Android, using `dart:io`'s `Platform`, which
layer rule 1 permits. Both `ReminderReconciler` and the Reminders screen read it; the number `56`
never appears in copy.
**Files:** 07 (§11.2 — cite the file), 08 (adopt).

### R51 — `reconcile()`, and `schedule` is banned on a reminder object

02, 07 and decision #63 agree on the method; nothing names its host.

**Ruling.** `final class ReminderReconciler { Future<void> reconcile(); }` in
`lib/data/reminder_reconciler.dart`, reached through `reminderReconcilerProvider`
(`FutureProvider<ReminderReconciler>`, keepAlive). Idempotent, debounced to once per 500 ms, off the
paint frame, called from exactly four sites. The token `schedule(` on a reminder object is a policy
rule row (`db.reminder_schedule`), because that spelling *is* the architecture decision #63 rejects.
**Files:** 08 (adopt).

### R52 — One diagnostics sink: `LocalLog.instance`

04 §7.5 calls `_diagnostics.record('restore.…')`; 01 and 02 have `LocalLog.instance`. 02 requires that
`\.instance\b` matches exactly one symbol in `lib/`.

**Ruling.** There is one sink. Its surface:
`write(String message, Object error, StackTrace stack)`, `flutterError(FlutterErrorDetails)`,
`record(String event)` (structured, no row contents), `attachTo(Directory)`, `markCleanPause()` (R11).
`_diagnostics` is a banned identifier.
**Files:** 04 (§7.5).

### R53 — `WriteCommitted.warnings` is populated by the controller, never by a repository

05 §7.5 rule 4 bans `lib/data/**` from importing `lib/domain/validation/**` — which means a repository
structurally cannot produce a `Warning`. 01 §5.2 nonetheless describes `warnings` as something the
write returns, and 01 §5.3's `_write` helper returns `const WriteCommitted()`.

**Ruling.** The ban stands (it is a §12.4 structural mechanism and 05 owns it). Therefore:
repositories always return `WriteCommitted(insertedId: …)` with the default empty `warnings`; the
**controller** runs the domain validators against the freshly-watched row and passes the resulting
`List<Warning>` to `confirmSaved`. The field stays on `WriteCommitted` so the two travel together
through `WriteDone` and `ref.listen` — the controller constructs the `WriteCommitted` it emits, or
passes the warnings alongside it. `lib/core/write_outcome.dart` importing
`lib/domain/validation/warning.dart` is legal (core → domain).
**Files:** 01 (§5.2 doc comment, §5.3 `_write`), 02 (§7 call site), 05 (§7.5 — state the consequence).

### R54 — Policy rule ids are dotted `namespace.name`

01, 02, 05 and 06 use `layer.domain`, `time.dart_clock`, `token.raw_color`. 04 uses
`no_destructive_ddl`, `banned_build_options`, `single_clock`, and eight more in that style.

**Ruling.** Dotted, `lower_snake` segments. The mapping table is in §4.7. Two of 04's ids duplicate
existing rows (`no_sql_side_time`, `single_clock`) and must be deleted rather than renamed — a
duplicate rule is a rule that gets weakened twice.
**Files:** 04 (§2.10, §4.9, §6.9).

### R55 — `token.raw_color` and `token.material_color` are scoped to `lib/`

01 scopes both to `lib/features/`, which leaves a raw hex in `lib/core/ui/components/` uncaught — the
one place a shared widget would hide one. 06 widens them.

**Ruling.** Both apply under `lib/`, with the two `[exempt]` lines in R56 as the only escape.
**Files:** 01 (§3.2 `_bannedText`).

### R56 — The `[exempt]` allowlist has four lines on day one

01's Definition of Done says "exactly two entries"; 06 §3.5 adds two more and says so.

**Ruling.** Four, exactly as printed in §4.7. A fifth is a review conversation.
**Files:** 01 (Definition of Done).

### R57 — The test tree

07 writes `test/screens/*` and `test/integration/first_run_journey_test.dart`; 01's tree has
`test/features/` and a top-level `integration_test/`; 06 adds `test/design/`; 02 adds
`test/support/harness.dart`.

**Ruling.** `test/{domain,data,drift,design,features,policy,support,fixtures}/` and a top-level
`integration_test/`. `test/screens/` and `test/integration/` are banned: the widget tier mirrors
`lib/features/`, and `integration_test` is the directory name the SDK package requires.
07's three files become `test/features/{overflow_matrix,tap_budget,no_monetization}_test.dart`;
its first-run journey becomes `integration_test/first_run_journey_test.dart`.
**Files:** 01 (§2.2 mkdir — add `design`, `support`), 07 (§1.3, §21.2, §2.1).

### R58 — The overflow matrix is 252 cells over 14 variants

Decision #114 says 216 (12 screens × 18); 07 adds note search and the export-banner variant.

**Ruling.** **252 cells, 14 pumpable variants** × 3 sizes × 3 text scales × 2 bold-text states. The
arithmetic must follow the variant list, not a remembered number. 12 must carry the same figure, and
the decision record's 216 is superseded with the reason stated.
**Files:** 12 (new), and a one-line note in 01/06 wherever 216 is quoted.

### R59 — Widget key format

01 writes `Key('birthType.twin')`; 02, 05 and 07 write `pen_board.turn_out.3`, `treatment.save`,
`quick_entry.keypad.digit_4`.

**Ruling.** `<screen>.<element>[.<qualifier>]`, every segment `lower_snake`. `birthType.twin` becomes
`lambing_entry.birth_type.twin`.
**Files:** 01 (§4.5 test snippet).

### R60 — No human-facing date is all-numeric

Decision #108 and 05 §5.1 ban it; 04 §7.3 honours it (`14 Jul 2026`); 07 §10.3 renders
`clear on 11/03/2026` on the countdown row.

**Ruling.** `d MMM y`. `11 Mar 2026`. Numeric dates exist only inside CSV, beside an ISO-8601 column.
The withdrawal countdown is the single worst place to break this rule, because the number it renders
is the safety-critical one.
**Files:** 07 (§10.3).

### R61 — Statistic `definition` strings are 05's, verbatim

05 §6.2 pins four strings literally, because they are printed into CSVs and PDFs that outlive the app
and a test freezes them. 07 §12.2 renders a paraphrase
(`"lambs born alive ÷ ewes put to the ram (AHDB)"`).

**Ruling.** The four strings are exactly:
`lambs born alive per ewe put to the ram`,
`lambs born incl. stillborn per ewe put to the ram`,
`lambs born alive per ewe lambed`,
`lambs reared per ewe put to the ram`.
A screen may render a formula *alongside* the definition; it may not render a different definition.
**Files:** 07 (§12.2).

### R62 — `media_assets.relative_path` carries all three CHECKs

04 §4.3 requires three; 03 §5.11 ships one. 04 already flags it.

**Ruling.** All three, in 03, before the v1 snapshot: `NOT LIKE '/%'`,
`GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*'`, `NOT GLOB '*/*/*/*'`. A `CHECK` cannot be added by
`ALTER TABLE` afterwards without the full table rebuild — on the one table that points at the user's
photographs.
**Files:** 03 (§5.11).

### R63 — Pen verbs: `enterPen` / `exitPen` on the repository, `turnOut` on the controller

02 §7 writes `repo.turnOut(pen)`; 07 §15.1 writes `enterPen` / `exitPen`.

**Ruling.** The repository verbs are `enterPen(PenId, {EweId?, List<LambId>})` and
`exitPen(PenOccupancyId, {required PenExitReason reason})`, because the occupancy row — not the pen —
is what closes, and the reason is not optional (03's `CHECK ((exited_at IS NULL) = (exit_reason IS
NULL))` makes it unstorable otherwise). `turnOut` is the **write-controller** method that calls
`exitPen(reason: PenExitReason.turnedOut)`.
`enum PenExitReason { turnedOut('turned_out'), moved('moved'), died('died'), other('other') }` lives
in `lib/domain/penning.dart`.
**Files:** 02 (§7).

### R64 — `FosterOutcome`

07 §8.4 sketches `sealed class FosterOutcome { ToEwe(EweId) | ToBottle() | RemovedUnknown() }` inline.

**Ruling.** `lib/domain/foster_outcome.dart`, sealed, three variants, each carrying its stored key
(`to_ewe`, `to_bottle`, `removed_unknown`). `setRearingDam(lambId, eweId?)` is a banned signature: a
nullable ewe id merges "bottle" (null by intent) with "not recorded" (null by omission), and the
rearing-credit numbers differ.
**Files:** 07 (§8.4 — cite the file), 03 (§7 doc comment cross-reference).

### R65 — Two different things were called an envelope

05 §7.4 defines `ExportEnvelope` — the disclaimer-bearing value every writer must take. 04 §6.2 calls
the JSON backup's header block "the envelope" and versions it as `formatVersion`.

**Ruling.** `ExportEnvelope` (05) keeps the name and moves to its own file,
`lib/domain/policy/export_envelope.dart`. The JSON backup's header type is **`BackupHeader`**, and 04's
prose says "the backup header", never "the envelope". 09 adopts both.
**Files:** 04 (§6.2, §6.5), 09 (adopt).

### R66 — `assets/content/` versus the ARB

01's tree says `assets/content/` holds "the ~40 authored husbandry terms"; 03 §10.1 puts the keys in
`first_run.dart` and the labels in ARB; the decision record's CI check targets `assets/content/`.

**Ruling.** Three homes, no overlap:
- **Keys** → `lib/core/db/seed/first_run.dart` (`vocab_terms`, `origin='seeded'`, `label=NULL`).
- **Labels** → `lib/l10n/app_en.arb`, one message per key; a test asserts the two sets are equal.
- **`assets/content/`** → only authored prose too long to be a UI string (the lambing-ease
  descriptions if they outgrow a label), plus one provenance line per vocabulary list.
The "no verbatim third-party copy" CI check scans **both** `assets/content/` and `lib/l10n/`.
**Files:** 01 (§2.2 tree comment), 03 (§10.1 — name the check's scope).

### R67 — `lib/l10n/` is in the tree

03, 05 and 06 all reference `lib/l10n/*.arb`; `l10n.yaml` sits at the repo root; 01's tree has no
`lib/l10n/`.

**Ruling.** `lib/l10n/app_en.arb` is in the tree and in the `mkdir` line.
**Files:** 01 (§2.2).

### R68 — `unitsProvider` and `terminologyProvider` get types

02's DI graph names both and types neither.

**Ruling.** `unitsProvider : Provider<WeightUnit>` (new enum
`lib/domain/units/weight_unit.dart`, keys `kg`/`lb`, matching `app_settings.weight_unit`'s CHECK) and
`terminologyProvider : Provider<Terminology>` (05's type). Both derive from `settingsProvider`.
There is **no** `temperatureUnitProvider`. No temperature column ships — ruled 2026-08-01, R76.
**Files:** 02 (§5.1).

### R69 — The free-tier types

01 names `EntryContext`, `Allow(overFreeCap: true)` and `RefusalReason`; 07 adds `BlockedByCap` and
requires `FreeTierPolicy` to take the current instant for the 22:00–06:00 window.

**Ruling.** `lib/domain/free_tier.dart` holds `enum EntryContext { liveEntry, calm }`,
`sealed class CapDecision` with `Allow({required bool overFreeCap})` and `BlockedByCap(RefusalReason)`,
`enum RefusalReason { secondSeason, eweCap }`, and `FreeTierPolicy.decide({context, now, unlocked,
ewesInCurrentSeason, seasonCount})`. The repository maps `BlockedByCap(reason)` →
`WriteRefused(reason)`. 11 adopts these names; 01 §5.2's "if 11 chooses a different name, 11 wins" is
superseded — 11 adopts.
**Files:** 01 (§5.2 note), 11 (adopt).

### R70 — `ShedKeypad` is a shared component

01's tree has `features/quick_entry/widgets/big_keypad.dart`; 06 §3.1 moves it, because Lambing Entry,
Treatments and Settings all need the same pad and layer rule 6 forbids a sibling import.

**Ruling.** `lib/core/ui/components/shed_keypad.dart`. `big_keypad.dart` does not exist. The same
applies to every component in 06 §12's inventory.
**Files:** 01 (§2.2).

### R71 — `flags` and "platform service"

Decision #13 wrote `WriteCommitted{flags}`; 01 §5.2 already renamed the field to `warnings`, but
06 §10.1 and 07 §6.1 still use the word "flags" in prose. Separately, 01 §1.3 calls the six seams
"platform services" while 02 §5.1 calls them "gateways".

**Ruling.** The word is **warnings**, in prose and in code, everywhere. The collective noun for the
six platform seams is **gateway** (02 owns the DI graph and decision #112 uses it); "platform service"
is a banned synonym. The individual class suffixes are fixed by §2.12 and are deliberately
non-uniform.
**Files:** 06 (§10.1), 07 (§6.1), 01 (§1.3).

### R72 — `lib/core/write_action.dart` is in the tree

02 §4.6 says it is "the one file this document adds to the `lib/core/` tree printed in
`01-architecture.md` §2.2" — meaning 01's tree is incomplete.

**Ruling.** It is in the canonical tree (§1). The file name stays `write_action.dart` even though the
class is `WriteController`, because 02 owns controllers and two documents already reference the path.
**Files:** 01 (§2.2).

### R73 — `partial_date.dart` and `wall_time.dart` are in the tree

05 §1.1 declares both; 01's `domain/time/` lists three files.

**Ruling.** `lib/domain/time/` holds five files: `instant.dart`, `local_date.dart`,
`partial_date.dart`, `recorded_time.dart`, `wall_time.dart`.
**Files:** 01 (§2.2).

### R74 — `PurchaseService` is the seventh seam, and it is the store seam

§2.12 tabulated six platform seams. `11-monetization-and-store.md` §2 and §5 derive a seventh class of
the same shape — one hand-written class in `lib/data/` wrapping exactly one plugin
(`in_app_purchase`), replaced by a hand-written fake — and `12-testing.md` §4.2 already fakes it.
`CODE-REVIEW-CHECKLIST.md` §1.13's `layer.in_app_purchase` and `launch.store_call` rows are keyed to
the name. Three documents used it; the catalogue did not carry it.

**Ruling.** `final class PurchaseService` in `lib/data/purchase_service.dart`, reached through
`purchaseServiceProvider` (`Provider<PurchaseService>`, keepAlive). §4.2 permits no other spelling —
`Gateway` is not a class suffix and `Store` is reserved to `MediaStore` — so `BillingService`,
`IapGateway`, `StoreClient`, `StoreGateway` and `PurchaseRepository` are banned. It is the **store**
seam, not a platform one: `08-platform-integration.md` documents six and does not document this one;
11 owns it; `test/support/` holds seven fakes. `kUnlockProductId`, `PurchaseSignal` and
`StoreUnreachable` live in the same file and are 11's (11 §2).
**Files:** none outstanding — §1, §2.12 and §3.1 carry it.

---

### R75 — `WithdrawalTarget` keeps `milk` in the v1 schema

Decision-record §7.1 question 10 asked whether the target market is ever a dairy flock. §2.7 and
`03 §5.8` were written for two targets while the question was open, so the *name* was never in doubt —
only whether the member survived to the freeze.

**Ruling** (decision-record §7.0 row 10, 2026-08-01). `enum WithdrawalTarget { meat('meat'),
milk('milk') }` keeps both members. `treatment_withdrawals.target` keeps
`CHECK (target IN ('meat','milk'))` and the `{treatment, target}` unique key, so 0..n rows per
treatment express a second target at no cost. **`WithdrawalMilkings` does not exist in v1** and
nothing converts milkings to days. Ruling the schema does not add a screen: `09 §10` row 12 already
had the four `milk_*` columns shipping in `treatments.csv` regardless, and the v1 UI may never write
one — do not let the ruling grow a Treatments field.
**Files:** none outstanding — §2.7 and §2.9 already spell both members.

---

### R76 — there is no `temperature_unit` column and no `temperatureUnitProvider`

§3 made `temperatureUnitProvider` conditional on a temperature column shipping. It does not ship.

**Ruling** (decision-record §7.0 row 11, 2026-08-01). **No v1 table stores a temperature.**
`app_settings.temperature_unit`, its `CHECK (temperature_unit IN ('c','f'))`, the Settings °C/°F row
and `temperatureUnitProvider` do not exist. `MilliCelsius` **still ships** and is not deleted —
`05 §5.2`'s measured reason for it (0.1 °C silently rewrites 89 of 201 °F entries) is independent of
whether a v1 column uses it. This was the only window in which dropping the column was free:
migrations are forward-only and never destructive (#37), so before the first snapshot it can simply
never exist, and after it, it ships forever unread.
**Files:** `CONVENTIONS.md` §3 (the provider line), `03 §5.12` (`AppSettings` and its
`customConstraints`), `05 §5.2`, `07-screens.md`'s Settings brief.

---

### R77 — `lambs.became_ewe` is in the v1 schema

Decision-record §7.1 question 13 asked whether a lamb kept as a breeding ewe becomes a `Ewe` row.
`03 §6` point 5 was written against the answer *no* and said so in as many words.

**Ruling** (decision-record §7.0 row 13, 2026-08-01). **Yes.** `lambs.became_ewe` is
`integer().nullable().references(Ewes, #id, onDelete: KeyAction.setNull)()`, hand-indexed as
`idx_lamb_became_ewe` because SQLite creates no child-key index automatically (#31). `setNull` and
not `cascade`: deleting the ewe row must not delete the lamb she was, because the lamb is a record of
a birth that happened. The Dart spelling is `becameEwe`; the column is `became_ewe` per §4.6.

The cross-table tag rule at `03 §6` point 5 is amended rather than deleted. Its old reason — *"v1 has
no lamb→ewe promotion"* — is now false; the surviving reason is that promotion writes a `ewes` row
through the same create-on-the-fly path every other ewe uses, so its tag meets the partial unique
index on active ewes exactly like any other. **No cross-table trigger is added**, which is `03 §6`'s
own standing instruction and is now permanent rather than provisional.
**Files:** `03 §5.5` (the `Lambs` table and its index block), `03 §6` point 5, `07-screens.md`'s ewe
card and lamb card briefs.

---

### R78 — the lambing-ease scale is 1..5, stated once

Decision-record §7.1 question 15 offered the spec's five points against SRUC's six. R44 had already
frozen the *type*; this ruling freezes the *bound*.

**Ruling** (decision-record §7.0 row 15, 2026-08-01). **Five**, with point 5 documented as covering
elective caesarean. `extension type const LambingEase(int code)` validates 1..5 (R44);
`lambings.ease` keeps `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)`; the labels stay `vocab_terms`
rows `ease_1`…`ease_5` with ARB defaults; the CSV column stays `lambing_ease_1_5`;
`ShedChoiceRow`'s *ease 1–5 only* contract stands.

`lambings.ease` is deliberately **not** a vocabulary foreign key, so widening the scale is a
migration somebody has to think about, and that friction is the feature. **A blank ease is not
"unassisted"** — it means not scored, and `05 §6.7` excludes unscored lambings from both sides of the
assisted rate and reports coverage; no ruling may make the column non-nullable or give it a default,
which would convert a §12.4 violation into schema. `test/policy/schema_shaped_rulings_test.dart`
asserts the bound is spelled `5` everywhere it appears, because five spellings of one number is how
a scale widens by accident.
**Files:** none outstanding — §2.9, `03 §5.4`, `05 §6.7` and `09 §3.1` already spell it 1..5.

---

### R79 — `struck` / `struck_at`: a second mixin, over the record-bearing tables only

This is P1, the last of the schema-irreversible conflicts (`docs/skills/02-build-manifest.md` §4.5).
`docs/design/indelible.md` Rule 1 — *"nothing is ever removed, only struck"* — is the design system
of record and is therefore binding, not advisory, so the only question P1 ever left open was the
**shape**, never the **whether**. `03` has no such columns today.

The cheap answer was to put the pair on `mixin Identified` and give sixteen tables a strike in one
edit. It is rejected: `TreatmentWithdrawals` and `VocabTerms` would acquire a verb no shepherd would
recognise, and every read in the app would still have to answer for it.

**Ruling** (2026-08-01).

#### a · Which tables

A **second mixin**, `mixin Struckable`, over the twelve tables where a strike is a thing a shepherd
would say out loud. It is applied beside `Identified`, never instead of it.

**Tables (12):**

1. `Seasons`
2. `Ewes`
3. `EweSeasons`
4. `Lambings`
5. `Lambs`
6. `FosterEvents`
7. `CareEvents`
8. `EweObservations`
9. `Pens`
10. `PenOccupancies`
11. `Reminders`
12. `Notes`

Four of the sixteen `Identified` tables are deliberately **not** struckable, each for a stated
reason, and each reason is that the act already has a home:

| Table | Why not |
|---|---|
| `Treatments` | It already has `voided_at` (#69). See §e — a treatment is *voided*, not struck |
| `TreatmentWithdrawals` | A child of `Treatments` with no independent existence. It is voided by voiding its treatment; a withdrawal that could be struck out from under a treatment that still stands is a §12.1 hole |
| `VocabTerms` | A label the user edits. Editing wording is not striking a record, and `TerminologyOverrides` already carries the user's words |
| `MediaAssets` | `04 §4.8` already owns removal: media moves to `.trash/<yyyy-MM-dd>/` and purges after 30 days. A second mechanism for one act is what §5 exists to prevent. The **record** the photo hangs off is what gets struck; the file follows the existing path |

The seven tables that carry no `Identified` at all — `PenOccupancyLambs`, `ReminderRules`,
`TerminologyOverrides`, `AppSettings`, `Entitlements`, `EweTouches`, `EweSummaries` — are unchanged.
Five are settings, projections or link rows; none is a record of something that happened.

#### b · The column shape

```dart
// lib/core/db/tables/common.dart — written in N07-T02, from this ruling
mixin Struckable on Table {
  late final struck   = boolean().withDefault(const Constant(false))();
  late final struckAt = integer().map(const InstantConverter()).nullable()();
}

// and, on every table that carries it:
//   CHECK (struck IN (0,1))
//   CHECK ((struck = 1) = (struck_at IS NOT NULL))
```

Under `STRICT` there is no `BOOLEAN`, hence the first CHECK. The paired CHECK is the same idiom
`treatment_withdrawals` already uses for `(kind = 'days') = (days IS NOT NULL)`. `struck_at` is UTC
epoch millis behind `InstantConverter` and never drift's `dateTime()` (#29), because a strike
happened at a **moment** — and specifically so that a strike recorded at 01:30 on the clocks-back
night is unambiguous. Its round trip belongs in the `uk-zone` tier against **01:00–01:59**; write it
there, so nobody later invents the case thinking a strike is a civil date.

`withDefault(const Constant(false))` on `struck` is correct and is **not** a violation of `03 §2`
point 5: that rule bans defaults on columns that could encode **veterinary advice** — `days`, `ease`,
`status`. `struck` is `NOT NULL` and every existing row needs a value.

#### c · Which side struck rows fall on

**The default: struck rows are excluded from every count and included in every history and every
export.** State it once, here, so N06 does not have to guess eight times.

The dangerous readers are N06's eight statistics. A struck lambing must leave **both** the numerator
and the denominator of lambing percentage, litter size and assisted rate — otherwise striking one
mistyped record silently changes a number the shepherd will compare against last year, which is
§12.4 wearing a different hat.

The named exceptions, all of them in the *included* direction:

| Reader | Struck rows |
|---|---|
| The ewe card's history, the season timeline, any per-animal list | **Included**, drawn with the 3 px madder strike |
| `search_docs` / FTS5 note search | **Included.** The trigger set in `03 §9` is unchanged and a struck note stays findable; the *screen* decides how a struck hit renders. Making it unfindable would be Rule 1 violated at the storage layer |
| Every CSV, the PDF and the JSON backup | **Included and marked** — see §d |
| The Pen Board's open-occupancy projection, the "in the pens" list, the recents strip, `ewe_summaries` | **Excluded.** All four answer "what is true now", and a struck row is a record of something that was not |

#### d · Export and restore

Indelible screen 11 is unambiguous: *"every CSV carries a `struck` and a `struck_at` column and every
struck row is included and marked, because an export that quietly drops the strikes would undo the
one thing this app is for."* The printed footer already promises it —
`STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS BEEN REMOVED.`

**A `WHERE struck = 0` in an export query is therefore a defect**, and a test asserts its absence.

All three CSV shapes carry the pair. `treatments.csv` is the one that needs saying out loud: the
`Treatments` table has no `struck` column, so its two export columns are **derived at write time** —
`struck = (voided_at IS NOT NULL)` and `struck_at = voided_at` — and sit **beside** `is_voided` and
`voided_at_utc`, which keep their names. One export contract, two storage words, and the derivation
written down once so nobody re-derives it differently.

Restore round-trips the pair: **a struck row restores struck**, or the one thing the app promises is
untrue the moment somebody uses the only recovery path there is.

#### e · The word

`CONVENTIONS §5.2` fixes one word per concept, and this ruling deliberately keeps **two** — so the
reason is written here rather than discovered later.

**A treatment is *voided*; everything else is *struck*.** A strike is a private correction to the
shepherd's own notebook. A void is a public one: a treatment may already have been printed into a
medicine book and handed to a vet (#69), so the medicine record must show that the entry was
withdrawn rather than simply carry a line through it. The two acts are not the same act, and
collapsing them would lose the distinction the medicine book depends on.

#### f · The active-tag index predicate

The partial unique index on active tags is written in N07-T03 and its predicate is decided **here**,
because a predicate that says nothing about `struck` means a shepherd who strikes a mistyped `412`
cannot immediately re-enter `412`:

```sql
CREATE UNIQUE INDEX idx_ewe_tag_active
  ON ewes (tag) WHERE tag IS NOT NULL AND status = 'active' AND struck = 0;
```

`ewes.status` stays a mutable column (R41), and culling still releases a tag in one `UPDATE`
(`03 §6` point 4). Striking now releases it too, immediately, which is the whole point of striking a
typo at 03:20.

**Files:** `03 §2` (`mixin Struckable` beside `mixin Identified`), the twelve table definitions,
`03 §6` (the index predicate), `03 §9` (FTS5 unchanged, stated), `04 §7` (restore round-trips the
pair), `09 §3.1`–`§3.3` and `§7` (the CSV and backup shapes),
`.claude/skills/shed-drift-schema/SKILL.md`, `.claude/skills/shed-export-and-restore/SKILL.md`,
`docs/skills/02-build-manifest.md` §4.5.

---

## §7 What this file deliberately does not settle

Four things surfaced during this review that are **not** naming questions and must not be closed by a
naming authority. They are listed so nobody mistakes silence for agreement.

1. **R41's escalation** — whether the retention story needs a ewe status-history table. That is a
   schema addition, it is irreversible after the first snapshot, and it needs the owner.
2. **R37's cost** — adding the provenance quad to four tables enlarges the v1 schema materially. The
   ruling is that it must land before the first snapshot; whether all four tables get an *edit verb*
   in v1 is a screens decision, and 07's "no quad, no edit verb" rule already covers the interim.
3. **The open questions carried by every document** — the field night, the ziplock-bag capacitance
   test, the exact price. None is a name; none is settled here, and all three are bookings rather
   than decisions (`docs/calendar.md`). Five items that were on this list are not any more, and none
   of them was closed by this file acting as a naming authority — each was an owner ruling recorded
   in decision-record §7.0 and then given a number here: the voice-note cap and in-app printing on
   2026-08-01 before `pubspec.yaml` closed (§7.0 rows 16 and 18, no ruling number — neither is a
   name), and the temperature field, the milk withdrawal target and lambing ease 5 vs 6 the same day,
   before the schema freeze (**R75**, **R76**, **R78**).
4. **Whether `HapticFeedback.successNotification()` exists on Flutter 3.44.8** (07 §22 item 7). That
   is an SDK fact, not a naming ruling. 06 owns it; if the member does not exist, the *name* in this
   file changes with it and every other ruling stands.
