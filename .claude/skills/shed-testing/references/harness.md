# The test harness — databases, fakes, `pumpApp`

Load this when writing a widget or a repository test. `docs/engineering/12-testing.md` §3, §4 and §5
own it in full and outrank this file; `CONVENTIONS.md` §2.12 owns the gateway names, R74 the seventh.

1. [The database](#1-the-database)
2. [The seven fakes](#2-the-seven-fakes)
3. [`shedContainer` — the exact override list](#3-shedcontainer--the-exact-override-list)
4. [`pumpApp`](#4-pumpapp)
5. [What lives in `test/support/`](#5-what-lives-in-testsupport)

## 1. The database

`testDatabase({bool seedOnCreate = true})` in `test/support/harness.dart` is the only constructor a
test uses. It builds `AppDatabase` over
`DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`, lets the real
`MigrationStrategy` migrate to `kSchemaVersion`, and registers `addTearDown(db.close)` **inside the
helper** — a leaked database is a leaked isolate.

- `closeStreamsSynchronously: true` is not optional. Without it an unsubscribed drift stream lives one
  extra event-loop turn and the widget binding reports a leaked timer that names nothing.
- Never mock drift and never add a repository interface "for testability" (decisions #111, #15). Real
  SQLite runs the real `STRICT` typing, foreign keys, the partial unique index on `pen_occupancies`,
  the `BEFORE UPDATE` trigger that freezes `birth_dam`, and the FTS5 triggers.
- **Durability and provenance tests use a real file, not memory**: create a temp dir, open
  `AppDatabase(NativeDatabase(file))`, write, `await db.close()`, then reopen with
  `seedOnCreate: false` and read back. That is the closest a test gets to "assume the phone dies", and
  it is a unit test, not an integration test.
- Seed a real ewe before writing anything that references one — `foreign_keys = ON` (decision #28), so
  a bare `EweId(1)` is an FK violation wearing a durability test's clothes.
- Stream assertions use `expectLater(stream, emitsInOrder([...]))`. Never assert over two combined
  drift streams: `combineLatest` is banned in `lib/`, and testing it would legitimise it.

## 2. The seven fakes

One file per gateway in `test/support/`, class `Fake<Gateway>`, always `implements` and never
`extends`, so an owning document's signature change is a compile error. Each records intent in a shape
plain `expect` can read, and each carries at least one tripwire that throws.

| Gateway | Fake | Records | Tripwire it throws on |
|---|---|---|---|
| `NotificationScheduler` | `FakeNotificationScheduler` | `List<ProjectedReminder> projected`, `List<String> calls` | a duplicate reminder id; more than `ReminderBudget.forPlatform()` projected; a `project()` not preceded by `cancelAll()` |
| `ShareService` | `FakeShareService` | `List<FakeShared> shared` — path, mime, filename | sharing a path that does not exist; any call passing bytes instead of a path |
| `MediaStore` | `FakeMediaStore` | `Map<String, Uint8List>` keyed by relative path | an absolute path, or more than two separators (R62's three `CHECK`s, in Dart) |
| `CameraService` | `FakeCameraService` | scripted `pickImage` results, `null` for cancelled | — |
| `VoiceRecorder` | `FakeVoiceRecorder` | scripted recordings, elapsed seconds | a recording longer than `kVoiceNoteMaxSeconds` |
| `WakelockController` | `FakeWakelockController` | `int acquired`, `int released` | `release()` with no matching `acquire()` |
| `PurchaseService` | `FakePurchaseService` | a scripted `updates` stream, `List<String> calls` | any store call during a `pumpApp` of a shed screen |

- The notification verb that reaches the OS is `project(ProjectedReminder, {required bool exact})`.
  `schedule(` on a reminder object is a banned spelling (R51) — the fake must not offer one.
- `calls` makes ordering a plain list comparison: `expect(fake.calls.first, 'cancelAll')` proves
  teardown-and-rebuild without a mocking library. Permission states are plain fields (`granted`,
  `exactAllowed`), so "no permission is requested from a write path" is
  `expect(fake.calls, isNot(contains('requestAlerts')))`.
- **There is no clock fake and never will be.** The clock is not a gateway; tests install time with
  `withClock`/`atFixed`.
- `mocktail` earns its keep only for `verifyNever` and cross-seam ordering — pass the double in through
  `pumpApp`'s `overrides:`, which is spread last and therefore wins over the harness default.

## 3. `shedContainer` — the exact override list

Eight overrides, in `flutter_riverpod` **2.6.1** spellings. There is no `ProviderContainer.test()` and
no `WidgetTester.container` — both are Riverpod 3 (decision #18).

```dart
final container = ProviderContainer(
  overrides: [
    // databaseProvider is a FutureProvider<AppDatabase> — Provider<AppDatabase>
    // is banned in lib/ (CONVENTIONS §3.1), so this is overrideWith, not
    // overrideWithValue.
    databaseProvider.overrideWith((ref) async => db),
    notificationSchedulerProvider
        .overrideWith((ref) async => notifications ?? FakeNotificationScheduler()),
    shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
    mediaStoreProvider.overrideWithValue(media ?? FakeMediaStore()),
    cameraServiceProvider.overrideWithValue(camera ?? FakeCameraService()),
    voiceRecorderProvider.overrideWithValue(recorder ?? FakeVoiceRecorder()),
    wakelockProvider.overrideWithValue(wakelock ?? FakeWakelockController()),
    purchaseServiceProvider.overrideWithValue(purchases ?? FakePurchaseService()),
    ...overrides,          // caller's overrides last: they win. Do not reorder.
  ],
);
addTearDown(container.dispose);   // 2.6.1: you register this yourself
```

A `ProviderScope` with no `databaseProvider` override in a test that touches data opens a **real**
database on the machine — `openAppDatabase()` asserts it is not running under `flutter_test` and
throws naming the override to add. Override leaves only: never a repository provider, never a screen
controller (02 §5.4), because a fake controller tests the fake.

## 4. `pumpApp`

`tester.pumpApp(screen, db: db, …)` is the only way a widget test builds a tree. Parameters:
`db` (**required**), `device` (`Device.small` 375×667@2, `typical` 390×844@3, `large` 430×932@3),
`textScale`, `boldText`, `palette`, `highContrast`, `overrides`, and `padding`, defaulting to
`EdgeInsets.only(top: 47, bottom: 34)`.

It sets `view.devicePixelRatio`/`physicalSize` with `addTearDown(view.reset)`, wraps a `MediaQuery`
**around** `MaterialApp` (so the app inherits the data instead of rebuilding it from the view), and
ends with `pumpAndSettle()`.

Each default is a bug class the alternative would hide:

- **`textScaler: TextScaler.linear(scale)`, never `textScaleFactor`** — deprecated and banned
  everywhere, including the theme layer (decision #99); the gate greps for it.
- **Dark only.** There is no light theme, so the harness offers none. `palette` and `highContrast`
  exist because the red-shift palette is where a contrast regression hides.
- **`locale: const Locale('en', 'GB')`** — `d MMM y`, 24-hour times, kg. A harness that inherits the
  runner's locale renders `3/28/2026` on a US CI runner and passes.
- **Non-zero `padding`.** Real phones have a notch and a home indicator; a zero-padding harness hides
  every bottom-anchored 60 pt target sitting under the home bar, which is every primary action here.
- `pumpAndSettle()` with no timeout is safe only because indefinite animations are banned on every
  screen. If one ships, this call hangs for ten minutes and then fails opaquely.

## 5. What lives in `test/support/`

Twelve files, and the list is closed — anything else is a test or a fake.

`harness.dart` (`Device`, `kPumpableVariants`, `testDatabase()`, `shedContainer()`, `atFixed()`,
`pumpApp`, `freshSupportDir()`, and the fixture id constants `kSeedEwe`, `kSeedLambing`, `kSeedLamb`,
`kSeedSeason`) · `seeds.dart` (writers: `seedEwe`, `seedOpenOccupancy`, `seedTreatment`,
`seedContradictoryLambing`, `seedAutoLambing`, `seedEditedLambing`, `armExportBanner`,
`setEntitlement`, `setEwesInCurrentSeason`, `restoreFixture`) · `reads.dart` (readers: `readLambing`,
`readLambingByUid`, `readLambs`, `readLamb`, `countLambings`, `countTreatments`, `findColumn`) ·
`flock_generator.dart` · `tolerant_comparator.dart` · the seven `fake_*.dart` files.

Anything that encodes a **screen's tap sequence** — `selectEwe`, `openNewTreatment`,
`enterWithdrawal` — is a private top-level function in the one test file that uses it. Hoisting it
here would make every screen change a harness change, and a shared tap sequence quietly stops being
the thing a tap-budget test counts.
