# 04 — Testing strategy for Shed Book

Research notes. Target toolchain: **Flutter 3.44.6 stable / Dart 3.12.2 / Xcode 26.6 / macOS arm64**, single developer, greenfield.
Researched 2026-07-27. Every package version below was read off its live pub.dev page on that date — see [Sources](#sources).

> Read [`shed-book-spec.md`](../../../shed-book-spec.md) first. This document is judged entirely against §5 (the 3am test), §12 (safety and correctness rules) and §4 (offline is the product).

---

## Bottom line

| Decision | Call | Confidence |
|---|---|---|
| **Test shape** | Not a pyramid. A **thick pure-domain unit layer** (date math, stats, units, tag matching, export serialisation), a **real in-memory Drift layer** (DAOs + every migration path, with data-integrity), a **wide-but-shallow widget layer** driven by an overflow/a11y matrix, ~8 goldens, 4 integration journeys, and a `test/policy/` directory that turns spec §12 into executable assertions. | High |
| **Time injection** | `package:clock` **1.1.2** (`withClock` + `Clock.fixed`) everywhere. Ban `DateTime.now()` in `lib/` with a source-scanning test. `package:fake_async` **1.3.3** for timer-driven code. Widget tests already have a fake clock via `AutomatedTestWidgetsFlutterBinding.clock`. | High |
| **Timezone** | Make the `tz.Location` an **injected value**, not ambient. Calendar math via the `DateTime(y, m, d + n)` constructor, never `add(Duration(days: n))`. One test runs under `TZ=Europe/London` to catch ambient leakage. Mandatory DST cases at the **last Sunday in March** — the UK lambing season straddles it. | High |
| **Database** | `NativeDatabase.memory()` real SQLite, never a mock. **drift 2.34.2 / drift_dev 2.34.5**, `dart run drift_dev make-migrations`, `SchemaVerifier.migrateAndValidate` for **every** `from → to` pair, `testWithDataIntegrity` for data survival, `validateDatabaseSchema()` in `beforeOpen` behind `kDebugMode`. | High |
| **Test doubles** | **Hand-written fakes** for all six gateways (notifications, share/export, speech, OCR/camera, file system, clock). `mocktail` **1.0.5** kept as a dev dependency for the handful of *interaction-ordering* assertions. **Reject `mockito`** as the primary. | High |
| **Goldens** | Built-in `matchesGoldenFile` + a project `flutter_test_config.dart` that loads the real fonts and installs a tolerant comparator. **Reject `golden_toolkit` (discontinued, 0.15.0, 3 years old).** **Reject `alchemist` 0.14.0 for v1** (good package, wrong cost/benefit here) — with an honest counter-argument below. ~8 goldens, dark theme, pinned to one runner and one exact Flutter version. | Medium |
| **Accessibility gate** | `MinimumTapTargetGuideline(size: Size(60, 60), link: …)` — the class is public and const-constructible, so the app's *own* stricter rule needs no subclass. **Plus** a second, geometric gate, because the built-in guideline silently skips nodes flush with the screen edge and nodes with no semantics at all. | High |
| **Integration** | `integration_test` (SDK). **Reject `patrol` 4.8.0 for v1** despite it being healthy — honest counter below. Four journeys, no more. | Medium |
| **Property tests** | `glados` **1.1.7** for the pure value round-trips (its shrinking earns its keep). Hand-rolled seeded generator for the whole-flock export round trip. | Medium |
| **Coverage** | **Report, never a gate.** Track `lib/domain/**` specifically; exclude `*.g.dart`. Argument below. | High |
| **CI split** | PR CI on Linux: analyze + unit + widget + policy + migration. Pinned macOS runner: goldens only. Nightly on a device: integration + startup trace. | High |

---

## 1. What test shape actually fits *this* code

The generic pyramid is a bad guide here because it is drawn for an app whose risk is concentrated in network/serialisation boundaries. Shed Book has no network boundary at all. Its risk is concentrated in three unusual places:

1. **Arithmetic that is invisible when wrong.** A withdrawal clear-date that is one day early puts meat in the food chain. A "hours since penned" that is one hour out during the March DST change moves a ewe out of a pen too early. Nobody notices either bug from the screen. These are pure functions and they deserve *exhaustive* unit tests, including boundary and DST cases — far more than a normal app would justify.
2. **A database that is the only copy of the data.** There is no server, no sync, no cloud backup (§4, §7.9). A bad migration in v1.4 destroys five seasons of a stranger's flock history with no recovery path. Migration testing here is not hygiene, it is the single highest-value test category in the project.
3. **Five safety rules (§12) that are product promises, not code properties.** "Never default a withdrawal period" is not something a type system enforces by accident. These belong in a dedicated `test/policy/` directory that reads like the spec.

Against that, the *screens* are comparatively low-risk: 12 screens, one theme, one layout language, no responsive breakpoints beyond phone sizes, no A/B variants. Heavy screen-level testing would be the wrong investment.

### What to unit test (thick)

| Area | Why | Notes |
|---|---|---|
| Withdrawal clear-date, "days remaining", "clear on" | Safety-critical arithmetic | Calendar arithmetic, not duration arithmetic. See §2. |
| Hours-since-penned, "ready to turn out" threshold | §7.4, DST-sensitive | Absolute elapsed time; must be UTC-instant based. |
| Season boundaries, season assignment of an event | §7.10 season start date | Local calendar day, injected `Location`. |
| Deferred/edited timestamp provenance | §12.5 | See policy test 5. |
| Reminder due-time computation (8 reminder types, §7.6) | Feeds `zonedSchedule` | Compute a `tz.TZDateTime` from an injected `Location`. |
| Lambing %, avg litter, barren rate, assisted rate, losses by cause/age, spread histogram | §7.8; the *definition is user-configurable* (per ewe to ram vs per ewe lambed; born vs reared) → 4 legal definitions × edge cases | Highest combinatorial density in the app. Table-driven. |
| Units kg↔lb, °C↔°F | §7.10 | Round-trip property test + fixed-value table (0 °C = 32 °F etc.). |
| Partial tag matching / ranking (`12` → 412, 128, 12) | §7.1, the hardest UX problem | Pure `List<Ewe> rank(String query, List<Ewe>)`. Test ordering explicitly, including ties. |
| Terminology map substitution (ewe/gimmer/shearling/theave/hogget) | §7.10 | Cheap; catches missing keys. |
| CSV row builders, JSON envelope/payload | §7.9, the only backup | Approved-fixture tests + round trip. |
| Consistency checks (twin + 3 lambs) | §12.4 | Must return warnings and touch nothing. |

### What to widget test (wide, shallow, matrix-driven)

Not "does the button work" — that's covered by the domain layer plus a couple of journeys. What widget tests buy *here* is the 3am test made mechanical:

- **Overflow matrix**: every screen × {375×667, 390×844, 430×932} × textScaler {1.0, 1.3, 2.0} × boldText {false, true} → assert no `RenderFlex` overflow and no exception. That's 12 × 3 × 3 × 2 = 216 cheap assertions from ~30 lines of table-driven code. This is the single best value-per-line in the whole suite for a "must be legible at 18 pt in a head torch" product.
- **Tap-target gate**: same matrix, `meetsGuideline(shedBookTapTargetGuideline)`.
- **Reachability**: the primary action of the 3am screens (Quick Entry, Lambing Entry, Foster) must be *on screen without scrolling* at the smallest device × textScaler 1.3.
- **Interaction budget**: the tap-count assertions that stand behind the 15-second promise (§10.1).
- **Warning-not-correction** behaviour (§12.4) and **edited-timestamp labelling** (§12.5) — these are visible-text assertions.
- **Free-tier cap does not degrade the 3am experience** (§14): at the 15-ewe cap, Quick Entry must still complete a save; the upsell must not be modal on the entry path.

### What to golden test (thin, ~8 images)

See §7. Only where a *pixel* regression is a usability or safety regression.

### What to integration test (4 journeys)

See §9.

### What is a waste of time in this app

- **Golden-testing all 12 screens across the matrix.** 216 PNGs, one developer. It would collapse within a month and be deleted, which is worse than never having it.
- **Mocking Drift or hiding it behind a repository interface *for testability*.** In-memory SQLite is fast (single-digit ms per test) and tests the real SQL. A repository interface may be worth it for architecture reasons — it is not worth it for testing.
- **Unit-testing PDF byte output.** Assert it produces a non-empty document with the expected page count and that the required disclaimer string (§12.3) is present in the text layer. Nothing more.
- **Testing generated code** (`*.g.dart` from drift/riverpod). Test the hand-written code that calls it.
- **Wall-clock timing assertions in `flutter test`.** `flutter test` runs under `FakeAsync`; wall time there is meaningless, and on CI it is noise. See §10.1.
- **Testing every Settings toggle individually.** One parameterised test that each setting persists and re-reads.
- **Any test that needs a network, an account, or a device farm.** Firebase Test Lab is rejected outright: it requires an account and an upload, which is the exact posture the product rejects.

---

## 2. Time: making it injectable and deterministic

This is the highest-leverage single decision in the test strategy, because *every one of the five safety rules touches time*.

### 2.1 `package:clock` — verified

- **clock 1.1.2**, publisher `tools.dart.dev` (verified), last published ~21 months before 2026-07-27, all platforms, not discontinued. [pub.dev/packages/clock](https://pub.dev/packages/clock)
- Public surface (read off the API docs, [clock library](https://pub.dev/documentation/clock/latest/clock/clock-library.html)):
  - `Clock()` and `Clock.fixed(DateTime)` constructors; instance methods `now()` and `stopwatch()`.
  - Top-level `clock` getter → `Clock`; top-level `now` getter → `DateTime`.
  - `T withClock<T>(Clock clock, T Function() callback, {bool isFinal = false})`.
  - `typedef TimeFunction = DateTime Function()`.
  - *(The `agoBy`/`fromNow`/`hoursAgo` convenience helpers are not listed on the current library page — do not rely on them; use `clock.now()` plus explicit arithmetic.)*

**Rule for `lib/`: `DateTime.now()` is banned. Use `clock.now()`.** `withClock` is zone-based; it cannot intercept `DateTime.now()`. That ban is enforced by a policy test (§10, gate A).

```dart
// lib/domain/time/app_clock.dart
import 'package:clock/clock.dart';

/// The single legal way to read wall time in lib/.
DateTime nowUtc() => clock.now().toUtc();
```

```dart
// test/domain/withdrawal_test.dart
import 'package:clock/clock.dart';
import 'package:test/test.dart';

void main() {
  test('clear date is exclusive of the treatment day and calendar-based', () {
    withClock(Clock.fixed(DateTime.utc(2026, 3, 25, 3, 12)), () {
      final t = Treatment.record(withdrawalDays: 28); // no default anywhere
      expect(t.clearDate, DateTime.utc(2026, 4, 22));
    });
  });
}
```

### 2.2 `package:fake_async` — verified

- **fake_async 1.3.3**, publisher `dart.dev` (verified), ~18 months old, not discontinued. Depends on `clock ^1.1.0`. [pub.dev/packages/fake_async](https://pub.dev/packages/fake_async)
- Verified API ([FakeAsync class docs](https://pub.dev/documentation/fake_async/latest/fake_async/FakeAsync-class.html)):
  - `FakeAsync({DateTime? initialTime, bool includeTimerStackTrace = true})`
  - `void elapse(Duration)`, `void elapseBlocking(Duration)`, `void flushMicrotasks()`, `void flushTimers({Duration timeout = const Duration(hours: 1), bool flushPeriodicTimers = true})`
  - `T run<T>(T Function(FakeAsync self) callback)`
  - `Clock getClock(...)` — "a fake `Clock` whose time is elapsed by calls to `elapse` and `elapseBlocking`".
- The README states plainly: `FakeAsync` cannot control `DateTime.now()` or `Stopwatch`; it *can* control `clock.now()` and `clock.stopwatch()`. Which is the whole argument for the ban above.

Use it for anything with a `Timer` — the pen-board "hours since penned" ticker, the once-per-day export prompt (§7.9), reminder re-evaluation:

```dart
test('pen board tile flips to "ready to turn out" exactly at the threshold', () {
  FakeAsync(initialTime: DateTime.utc(2026, 3, 27, 23, 0)).run((async) {
    final board = PenBoard(readyAfter: const Duration(hours: 24));
    board.pen(penId: 3, ewe: ewe412);          // uses clock.now() internally

    async.elapse(const Duration(hours: 23, minutes: 59));
    expect(board.tile(3).readyToTurnOut, isFalse);

    async.elapse(const Duration(minutes: 1));
    expect(board.tile(3).readyToTurnOut, isTrue);
  });
});
```

### 2.3 In widget tests, the clock is already fake

`AutomatedTestWidgetsFlutterBinding` **overrides `clock`** (from `package:clock`) and runs the test body inside a `FakeAsync` zone; `tester.pump(Duration)` advances it, and `elapseBlocking` simulates synchronous time. ([AutomatedTestWidgetsFlutterBinding](https://api.flutter.dev/flutter/flutter_test/AutomatedTestWidgetsFlutterBinding-class.html)) So widget code that reads `clock.now()` is deterministic for free, and `tester.pump(const Duration(hours: 25))` is a legitimate way to test the pen-board badge in a widget test. Code that reads `DateTime.now()` is *not* — a second reason for the ban.

To pin an absolute start time in a widget test, wrap the body:

```dart
testWidgets('pen tile shows 25h at 3am', (tester) async {
  await withClock(Clock.fixed(DateTime.utc(2026, 3, 28, 3, 0)), () async {
    await tester.pumpApp(const PenBoardScreen());
    expect(find.text('25 h'), findsOneWidget);
  });
});
```

### 2.4 The DST and timezone traps you must have a test for

Dart's own docs are explicit about the trap. `DateTime.add`: *"If the resulting `DateTime` has a different daylight saving offset than `this`, then the result won't have the same time-of-day as `this`, and may not even hit the calendar date 50 days later."* And on `DateTime` generally: *"the difference between two midnights in local time may be less than 24 hours times the number of days between them, if there is a daylight saving change in between."* ([DateTime.add](https://api.dart.dev/stable/dart-core/DateTime/add.html), [DateTime](https://api.dart.dev/stable/dart-core/DateTime-class.html))

**The app-specific detail that makes this urgent:** UK/Ireland lambing runs roughly February–April (§3, §17.3 names UK/Ireland as the first region). The BST transition is the **last Sunday in March**, at 01:00 UTC — i.e. *in the middle of the night, in the middle of the season, one hour before the canonical 3am entry*. This is not a theoretical edge case for this product; it will happen to real users in their first season.

Two kinds of arithmetic, two different correct answers:

| Question | Correct arithmetic | Wrong arithmetic |
|---|---|---|
| "Withdrawal is 28 days — what date does it clear?" | **Calendar**: `DateTime(y, m, d + 28)` (the constructor normalises overflow) applied to the *local calendar date*. | `treatedAt.add(Duration(days: 28))` — off by an hour across a DST boundary, and can land on the wrong calendar day. |
| "How many hours has ewe 412 been penned?" | **Absolute**: `nowUtc().difference(pennedAtUtc)`. | `DateTime.now().difference(pennedAtLocal)` where either side was reconstructed from wall-clock components. |
| "Which season does this event belong to?" | **Calendar day** in the flock's location, compared against the user's season start date. | UTC-day comparison — wrong for anything before 01:00 local in winter. |
| "When should the reminder fire?" | `tz.TZDateTime` in the flock's `Location`, passed to `zonedSchedule`. | A UTC `DateTime` — fires an hour off after the transition. |

**Make the timezone injectable, not ambient.** Do not rely on the process TZ. `timezone` **0.11.1** (publisher `labs.dart.dev`, ~28 days old, IANA tzdata **2025c**) gives you `initializeTimeZones()`, `setLocalLocation()` and `TZDateTime`. Take a `tz.Location` as a constructor argument to the domain services; tests then pass `tz.getLocation('Europe/London')` explicitly and never touch process state. [pub.dev/packages/timezone](https://pub.dev/packages/timezone)

Mandatory test cases (write these before writing the feature):

```dart
group('DST — Europe/London, last Sunday in March 2027 (28 March, 01:00 UTC)', () {
  late tz.Location london;
  setUpAll(() { tz.initializeTimeZones(); london = tz.getLocation('Europe/London'); });

  test('hours since penned is absolute elapsed time across the spring-forward', () {
    // Penned at 00:30 GMT. "Now" is 02:30 BST — which is 01:30 UTC. One hour, not two.
    final penned  = DateTime.utc(2027, 3, 28, 0, 30);
    final nowUtc  = DateTime.utc(2027, 3, 28, 1, 30);
    expect(hoursSincePenned(penned, nowUtc), 1);
  });

  test('a 7-day withdrawal from 25 March clears on 1 April at the same wall-clock time', () {
    final clear = clearDate(treatedOn: Date(2027, 3, 25), withdrawalDays: 7, at: london);
    expect(clear, Date(2027, 4, 1));                 // calendar arithmetic
    expect(tz.TZDateTime(london, 2027, 4, 1).hour, 0); // and midnight is still midnight
  });

  test('an event at 01:30 local on transition day does not silently move seasons', () {
    // 01:30 BST does not exist as 01:30 GMT; assert the documented normalisation.
    final t = tz.TZDateTime(london, 2027, 3, 28, 1, 30);
    expect(t.timeZoneName, 'BST');
    expect(seasonOf(t, startDate: Date(2026, 9, 1)), Season(2026));
  });

  test('a reminder scheduled for 06:00 local the morning after fires at 05:00 UTC', () {
    final due = reminderDue(local: tz.TZDateTime(london, 2027, 3, 28, 6), at: london);
    expect(due.toUtc(), DateTime.utc(2027, 3, 28, 5));
  });
});
```

Add the **autumn** case too (last Sunday in October — the *repeated* hour, 01:00–02:00 local occurs twice): `hoursSincePenned` must not go negative or reset.

**One ambient-leakage detector.** Everything above is timezone-injected and therefore passes under any process TZ — which is exactly what you want, but it means a leaked `DateTime.now().hour` in production code goes undetected. Fix that with a single CI job that reruns the domain suite under a hostile TZ:

```bash
TZ=Pacific/Chatham flutter test test/domain      # UTC+12:45, 1h DST — maximally hostile
TZ=UTC             flutter test test/domain
```

If any test's result depends on `TZ`, something is reading ambient local time.

### 2.5 SQLite's own clock — forbid it, then prove it

If any SQL uses `CURRENT_TIMESTAMP`, it bypasses `package:clock` entirely. Drift's answer is `sqlite3_test` **0.2.0** (publisher `simonbinder.eu`, ~8 months old), whose `TestSqliteFileSystem` VFS makes `CURRENT_TIME`/`CURRENT_DATE`/`CURRENT_TIMESTAMP` reflect `package:clock`. It explicitly **cannot support WAL databases** (no mmap IO) and is slow. ([pub.dev/packages/sqlite3_test](https://pub.dev/packages/sqlite3_test), [drift testing docs](https://drift.simonbinder.eu/testing/))

Simpler and better here: **never let SQL produce a timestamp.** All instants come from Dart (`clock.now()`) and are passed in as bound parameters. Then enforce it:

```dart
// test/policy/no_sql_time_test.dart
test('no SQL statement produces a timestamp', () {
  final offenders = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.drift'))
      .where((f) => RegExp(r'CURRENT_(TIMESTAMP|DATE|TIME)|strftime\(|datetime\(')
          .hasMatch(f.readAsStringSync()))
      .map((f) => f.path);
  expect(offenders, isEmpty, reason: 'time must come from package:clock, not sqlite');
});
```

This also removes any need for `sqlite3_test`, and it keeps WAL available (which you want for the "every write commits immediately" promise, §5).

---

## 3. Drift / database testing

### 3.1 Verified package state

| Package | Version | Publisher | Last published | Notes |
|---|---|---|---|---|
| `drift` | **2.34.2** | simonbinder.eu (verified) | 12 days | Not discontinued |
| `drift_dev` | **2.34.5** | simonbinder.eu (verified) | 4 days | Dev dependency only |
| `drift_flutter` | **0.3.1** | simonbinder.eu (verified) | 16 days | `driftDatabase()` helper; docs recommend keeping a separate constructor for tests |
| `sqlite3_test` | **0.2.0** | simonbinder.eu (verified) | 8 months | Only if you use SQL-side time — see §2.5 |

### 3.2 Make the executor an argument

Drift's own testing page is explicit: the only production-code change needed is making the `QueryExecutor` explicit. ([drift testing](https://drift.simonbinder.eu/testing/))

```dart
@DriftDatabase(tables: [Seasons, Ewes, Lambings, Lambs, Pens, Treatments, Reminders, Notes])
class ShedDb extends _$ShedDb {
  ShedDb(super.e);
  ShedDb.forTesting()
      : super(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

  @override
  int get schemaVersion => 1;
}
```

`closeStreamsSynchronously: true` matters: by default, unsubscribing from a drift query stream keeps it open for one event-loop iteration, which the widget-test binding reports as a leaked timer. Drift documents this exact flag for Flutter widget tests.

```dart
late ShedDb db;
setUp(() => db = ShedDb.forTesting());
tearDown(() => db.close());
```

### 3.3 The host-sqlite3 requirement (a real setup trap)

`flutter test` runs on the **host**, not the device, so `sqlite3_flutter_libs` (a plugin) is not applied — you need sqlite3 present on the host:

- macOS arm64 (your dev machine): present by default. ✅
- Linux CI: `sudo apt-get install -y libsqlite3-dev`. **This one line is the difference between a working and a red CI on day one.**
- Windows: `sqlite3.dll` on `PATH`.

([Drift supported platforms / community threads](https://drift.simonbinder.eu/platforms/))

Consequence for CI: the *version* of sqlite3 differs between your Mac and the Linux runner. If any behaviour depends on a sqlite feature version (`STRICT` tables, `RETURNING`, generated columns), the Mac may pass and CI fail. Mitigation: pin a minimum sqlite version assertion in a test —

```dart
test('host sqlite is new enough for the features we use', () {
  expect(sqlite3.version.versionNumber, greaterThanOrEqualTo(3041000)); // 3.41.0
});
```

### 3.4 DAO tests: use the real database

No mocks. A DAO test that mocks the query layer tests nothing. In-memory SQLite is fast enough that the whole DAO suite runs in a second or two.

```dart
test('turning a ewe out clears the pen and preserves entered_at for history', () async {
  final ewe = await db.ewes.create(tag: '412');
  await withClock(Clock.fixed(DateTime.utc(2026, 3, 27, 22)), () => db.pens.penEwe(3, ewe.id));
  await withClock(Clock.fixed(DateTime.utc(2026, 3, 29, 6)),  () => db.pens.turnOut(3));

  final pen = await db.pens.byId(3);
  expect(pen.occupantEweId, isNull);
  final stay = await db.pens.historyFor(ewe.id).then((r) => r.single);
  expect(stay.enteredAt, DateTime.utc(2026, 3, 27, 22));
  expect(stay.turnedOutAt, DateTime.utc(2026, 3, 29, 6));
});
```

Stream tests use `expectLater(..., emitsInOrder([...]))`, which is drift's documented pattern.

### 3.5 Migration testing — the highest-value tests in the project

**Setup (drift's current guided workflow, `drift_dev` ≥ 2.21):**

`build.yaml`:
```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          databases:
            shed_db: lib/data/shed_db.dart
          # defaults, shown for clarity:
          schema_dir: drift_schemas/
          test_dir:   test/drift/
```

```bash
dart run drift_dev make-migrations
```

This combines the older individual commands, which still exist and are worth knowing:

```bash
# snapshot the current schema (run after every schemaVersion bump)
dart run drift_dev schema dump lib/data/shed_db.dart drift_schemas/

# generate the versioned helper databases used by the tests
dart run drift_dev schema generate --data-classes --companions \
  drift_schemas/ test/generated_migrations/

# generate the step-by-step migration scaffold
dart run drift_dev schema steps drift_schemas/ lib/data/schema_versions.dart
```

`drift_schemas/drift_schema_v1.json`, `…_v2.json`, … **are committed to git.** They are the contract.

**Step-by-step migrations** (so that a user on v1 who skips three releases lands correctly):

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.treatments, schema.treatments.batchNo);
        },
        from2To3: (m, schema) async {
          await m.createTable(schema.reminders);
        },
      ),
      beforeOpen: (details) async {
        if (kDebugMode) {
          await validateDatabaseSchema();
        }
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
```

**Verified migration-test API** ([drift migration tests](https://drift.simonbinder.eu/migrations/tests/), [`SchemaVerifier`](https://pub.dev/documentation/drift_dev/latest/api_migrations_native/SchemaVerifier-class.html)):

```dart
SchemaVerifier(SchemaInstantiationHelper helper, {void Function(Database raw)? setup})

Future<DatabaseConnection>            startAt(int version)
Future<InitializedSchema<Database>>   schemaAt(int version)
Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
    {ValidationOptions options = const ValidationOptions(), bool? validateDropped})
Future<void> testWithDataIntegrity<Old extends GeneratedDatabase, New extends GeneratedDatabase>({
  required Old  Function(QueryExecutor) createOld,
  required New  Function(QueryExecutor) createNew,
  required GeneratedDatabase Function(QueryExecutor) openTestedDatabase,
  required void Function(Batch, Old) createItems,
  required Future<void> Function(New) validateItems,
  required int oldVersion,
  required int newVersion,
  ValidationOptions options = const ValidationOptions(),
})
```

`validateDatabaseSchema` is an extension member (`VerifySelf` on `GeneratedDatabase`) in `package:drift_dev/api/migrations_native.dart`:

```dart
Future<void> validateDatabaseSchema({
  ValidationOptions options = const ValidationOptions(),
  void Function(Database raw)? setup,
  bool? validateDropped,
})
```

Note: `package:drift_dev/api/migrations.dart` was **deprecated in drift_dev 2.22.0** in favour of `api/migrations_native.dart`. Use the latter.

**Test every from → to path, not just N-1 → N.** Users skip releases; step-by-step composition is exactly where the bugs are.

```dart
// test/drift/migration_test.dart
import 'package:drift_dev/api/migrations_native.dart';
import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const current = 3; // keep in sync with ShedDb.schemaVersion

  for (var from = 1; from < current; from++) {
    for (var to = from + 1; to <= current; to++) {
      test('schema migrates $from -> $to', () async {
        final connection = await verifier.startAt(from);
        final db = ShedDb(connection);
        await verifier.migrateAndValidate(db, to);
        await db.close();
      });
    }
  }

  test('schemaVersion matches the number of dumped schema files', () {
    final dumps = Directory('drift_schemas').listSync()
        .where((f) => f.path.endsWith('.json')).length;
    expect(dumps, current,
        reason: 'run `dart run drift_dev make-migrations` after bumping schemaVersion');
  });
}
```

**Data integrity is the part that actually protects the user.** Schema shape can be right while five seasons quietly vanish:

```dart
test('a lambing recorded in v1 survives to v3 with its provenance intact', () async {
  await verifier.testWithDataIntegrity(
    oldVersion: 1, newVersion: 3,
    createOld: v1.DatabaseAtV1.new,
    createNew: v3.DatabaseAtV3.new,
    openTestedDatabase: ShedDb.new,
    createItems: (batch, old) {
      batch.insert(old.ewes, v1.EwesCompanion.insert(tag: '412'));
      batch.insert(old.lambings, v1.LambingsCompanion.insert(
        eweId: 1, datetime: DateTime.utc(2026, 3, 28, 3, 12),
        birthType: 3, timeProvenance: 'autoCaptured',
      ));
    },
    validateItems: (fresh) async {
      final l = await fresh.select(fresh.lambings).getSingle();
      expect(l.birthType, 3);
      expect(l.datetime, DateTime.utc(2026, 3, 28, 3, 12));
      expect(l.timeProvenance, 'autoCaptured'); // §12.5 survives migration
    },
  );
});
```

**Also add a "destructive migration is impossible" test.** For a notebook app with no backup, a `deleteTable`/`drop column` in a migration should be a deliberate, reviewed act:

```dart
test('no migration step drops a table or a user-data column', () {
  final src = File('lib/data/schema_versions.dart').readAsStringSync();
  expect(RegExp(r'\bdeleteTable\(|\bdropColumn\(').hasMatch(src), isFalse,
      reason: 'destructive migration — requires an export prompt and an ADR');
});
```

**CI check that schemas are up to date.** After `dart run drift_dev make-migrations`, `git diff --exit-code drift_schemas/ lib/data/schema_versions.dart` must be clean. Someone will bump `schemaVersion` and forget the dump; this catches it in the PR.

### 3.6 "Every write commits immediately" (§5) is a testable property

```dart
test('a lambing row is durable before the save call returns', () async {
  final file = File('${Directory.systemTemp.createTempSync().path}/shed.sqlite');
  final db = ShedDb(NativeDatabase(file));
  final id = await db.lambings.save(draft);      // no explicit flush afterwards
  await db.close();                              // simulate: nothing else runs

  final reopened = ShedDb(NativeDatabase(file)); // simulate a cold start after battery death
  expect(await reopened.lambings.byId(id), isNotNull);
});
```

Pair it with a policy test that no DAO method exposes a "draft"/"pending"/"unsaved" concept, since §5 says there is no draft state.

---

## 4. Fakes vs mocks

### 4.1 Verified state of the two libraries

| | `mocktail` | `mockito` |
|---|---|---|
| Version | **1.0.5** | **5.7.0** |
| Publisher | felangel.dev (verified) | dart.dev (verified) |
| Last published | ~3 months | ~2 months |
| Likes / downloads | 1.24k / 2.73M | 1.54k / 2.13M |
| Codegen | **None** | **Required** (`build_runner` + `@GenerateNiceMocks`) |
| Breaking changes since 1.0.0 | None (1.0.1–1.0.5 are dependency/doc/lint changes only) | 5.0.0 introduced null safety via codegen |

Sources: [mocktail](https://pub.dev/packages/mocktail), [mocktail changelog](https://pub.dev/packages/mocktail/changelog), [mockito](https://pub.dev/packages/mockito).

Both are alive and healthy. This is not a "which is abandoned" question in 2026.

### 4.2 The call: hand-written fakes are the default here

Flutter's own documentation makes the architectural argument for us. On testing plugin-backed code, the docs rank the options and put **"wrap the plugin in your own API and mock that"** first, because *"tests won't break if the plugin API changes… you only test your code, not the plugin's behavior"*; mocking the platform channel with `setMockMethodCallHandler` is ranked **last resort**. ([Plugins in Flutter tests](https://docs.flutter.dev/testing/plugins-in-tests))

Once you have wrapped each plugin in a narrow interface, that interface is 3–6 methods wide and takes 20 lines to fake by hand. At that width a hand-written fake beats both mocking libraries because:

1. **It records intent in a domain shape you can assert on with plain `expect`.** `expect(notifications.scheduled, [ScheduledReminder(type: colostrum, dueAt: t)])` reads like the spec. `verify(() => mock.zonedSchedule(any(), any(), any(), any(), any()))` reads like nothing.
2. **No `registerFallbackValue` ceremony.** mocktail requires registering a fallback for every non-primitive argument type used with `any()`. With six gateways taking rich value types, that's a pile of boilerplate that exists only to serve the mocking library.
3. **The fake doubles as a real implementation.** A `NoOpNotificationGateway` and an `InMemoryShareGateway` are useful in the app itself (simulator builds, the free-tier path, a `--dart-define=SHED_FAKE_GATEWAYS=true` integration build). A mock is useful only in tests.
4. **Fakes fail loudly on unexpected calls.** A hand-written fake can `throw StateError('withdrawal reminder scheduled with no user-entered value')` — turning §12.1 into a runtime tripwire that also fires in integration tests. Nice mocks return null and hide the bug.
5. **They survive refactors.** A mock breaks on any signature change; a fake breaks only if the *contract* changed, which is when you want to be told.

**Where mocktail still earns its keep:** assertions about *ordering* and *non-invocation*, where a fake would need bespoke bookkeeping.

```dart
test('the withdrawal reminder is scheduled once, after the row commits, never with a default', () async {
  final notifier = MockNotificationGateway();
  final service = TreatmentService(db, notifier);

  await service.record(Treatment(product: 'Alamycin', withdrawalDays: 28));

  verify(() => notifier.schedule(any(that: isA<Reminder>()
      .having((r) => r.type, 'type', ReminderType.withdrawalEnds)
      .having((r) => r.source, 'source', WithdrawalSource.asEnteredByUser)))).called(1);
  verifyNoMoreInteractions(notifier);
});
```

**Never mock:** Drift (use in-memory SQLite), the clock (use `withClock`/`FakeAsync`), value objects, or your own pure functions.

### 4.3 The six gateways and their fakes

| Gateway | Real impl | Fake shape | Why a fake wins |
|---|---|---|---|
| **Notifications** | `flutter_local_notifications` **22.2.0** (dexterx.dev, 2 days old) | `List<ScheduledReminder> scheduled`, `List<int> cancelled` | The plugin's API is 20+ methods and takes `TZDateTime`, `NotificationDetails`, Android/iOS detail objects. The fake collapses it to the eight reminder types in §7.6. Also lets you assert "nothing nags twice" as a set-uniqueness invariant. |
| **Share / export** | `share_plus` **13.3.0** (fluttercommunity.dev, 3 days old) | `List<SharedPayload> shared` capturing bytes + mime + filename | You can then run the exported bytes back through the importer *in the same test* — the round-trip gate (§10.6) needs the bytes, not a `verify`. |
| **Speech (voice tag entry, §7.1)** | OS on-device speech | `Stream<String> Function()` you drive from the test | Speech is inherently non-deterministic; a fake makes "typing `12` by voice filters to 412/128/12" a normal unit test. |
| **OCR (tag camera, §7.1)** | OS text recogniser | returns a scripted `List<RecognisedText>` | Same reason. Also lets you test the *"always a shortcut, never the only route"* rule: with the OCR fake throwing, every screen must still be operable. |
| **File system / media folder** | `dart:io` + `path_provider` | `package:file`'s `MemoryFileSystem` | Photo attachment tests without touching disk. |
| **Clock** | `package:clock` | `Clock.fixed` / `FakeAsync` | Covered in §2. |

`flutter_local_notifications` README explicitly notes the plugin class is **not static**, so it is mockable and verifiable — but you still want your own gateway in front of it so the domain never sees `TZDateTime`/`NotificationDetails`. ([pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications))

```dart
// test/fakes/fake_notification_gateway.dart
class FakeNotificationGateway implements NotificationGateway {
  final scheduled = <ScheduledReminder>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(ScheduledReminder r) async {
    if (r.type == ReminderType.withdrawalEnds &&
        r.source != WithdrawalSource.asEnteredByUser) {
      throw StateError('spec §12.1: withdrawal reminder from a non-user source');
    }
    if (scheduled.any((s) => s.id == r.id)) {
      throw StateError('spec §7.6: "nothing nags twice" — duplicate reminder ${r.id}');
    }
    scheduled.add(r);
  }

  @override
  Future<void> cancel(String id) async => cancelled.add(id);
}
```

---

## 5. Widget testing: the `pumpApp` harness

### 5.1 Verified building blocks

- `WidgetTester.view` → `TestFlutterView` with settable `physicalSize`, `devicePixelRatio`, `padding`, `viewInsets`, and `reset()` / `resetPhysicalSize()` / … ([TestFlutterView](https://api.flutter.dev/flutter/flutter_test/TestFlutterView-class.html))
- `WidgetTester.platformDispatcher` → `TestPlatformDispatcher`.
- `pumpWidget(widget, {duration, phase = EnginePhase.sendSemanticsUpdate, wrapWithView = true})`.
- `MediaQueryData.textScaler` is the current API; `TextScaler.linear(n)` is how you set it. ([MediaQueryData.textScaler](https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html))
- Riverpod: **flutter_riverpod 3.4.1** (dash-overflow.net, published 16 hours before this research). Riverpod 3 ships `ProviderContainer.test()` (auto-disposes at test end) and a `WidgetTester.container` extension, replacing the hand-rolled `createContainer` pattern of Riverpod 2. ([Riverpod — what's new](https://riverpod.dev/docs/whats_new))

### 5.2 The harness

```dart
// test/support/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/ui/theme/shed_theme.dart';

/// The devices we promise to work on. Smallest first — most bugs live there.
class Device {
  const Device(this.name, this.size, this.dpr);
  final String name;
  final Size size;      // logical
  final double dpr;

  static const smallPhone  = Device('small',  Size(375, 667), 2.0); // iPhone SE
  static const typicalPhone= Device('typical',Size(390, 844), 3.0); // iPhone 15/16
  static const largePhone  = Device('large',  Size(430, 932), 3.0); // Pro Max
  static const all = [smallPhone, typicalPhone, largePhone];
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    Device device = Device.typicalPhone,
    double textScale = 1.0,
    bool boldText = false,
    ShedTheme theme = ShedTheme.dark,          // dark is the default, not an option (§5)
    List<Override> overrides = const [],
    EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34), // notch + home bar
  }) async {
    view.devicePixelRatio = device.dpr;
    view.physicalSize = device.size * device.dpr;
    addTearDown(view.reset);

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MediaQuery(
          data: MediaQueryData(
            size: device.size,
            devicePixelRatio: device.dpr,
            textScaler: TextScaler.linear(textScale),
            boldText: boldText,
            padding: padding,
            platformBrightness: Brightness.dark,
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.data,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }
}
```

Notes on choices:

- **Padding is not zero.** Real phones have a notch and a home indicator. Bottom-anchored 60 pt targets are exactly where the home indicator steals space; a zero-padding harness hides that class of bug entirely.
- **`ShedTheme.dark` is the default parameter**, mirroring the product. A `light` variant is not offered because the product does not offer one; `redShift` is a third value.
- **`MediaQuery` wraps `MaterialApp`**, not the other way around, so `MaterialApp` inherits the overridden data rather than rebuilding it from the view.

### 5.3 The overflow matrix

```dart
// test/ui/overflow_matrix_test.dart
final screens = <String, Widget Function()>{
  'Flock':        () => const FlockScreen(),
  'EweCard':      () => EweCardScreen(eweId: seedEweId),
  'QuickEntry':   () => const QuickEntryScreen(),
  'LambingEntry': () => LambingEntryScreen(eweId: seedEweId),
  'LambCard':     () => LambCardScreen(lambId: seedLambId),
  'Foster':       () => FosterScreen(lambId: seedLambId),
  'PenBoard':     () => const PenBoardScreen(),
  'Treatments':   () => const TreatmentsScreen(),
  'Reminders':    () => const RemindersScreen(),
  'SeasonSummary':() => const SeasonSummaryScreen(),
  'Export':       () => const ExportScreen(),
  'Settings':     () => const SettingsScreen(),
};

void main() {
  for (final entry in screens.entries) {
    for (final device in Device.all) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final bold in const [false, true]) {
          testWidgets(
            '${entry.key} · ${device.name} · scale $scale · bold $bold — no overflow',
            (tester) async {
              await tester.pumpApp(entry.value(),
                  device: device, textScale: scale, boldText: bold,
                  overrides: seededOverrides());
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
```

`RenderFlex` overflow is reported through `FlutterError.onError` during paint, which the test binding captures; `tester.takeException()` returns it. This is the whole mechanism — no package needed.

**Extend to reachability** for the three 3am screens:

```dart
testWidgets('QuickEntry primary action is on screen without scrolling at scale 1.3', (tester) async {
  await tester.pumpApp(const QuickEntryScreen(), device: Device.smallPhone, textScale: 1.3);
  final save = find.byKey(const Key('quick_entry.save'));
  expect(save, findsOneWidget);
  final rect = tester.getRect(save);
  expect(rect.bottom, lessThanOrEqualTo(667 - 34), reason: 'hidden behind the home indicator');
  expect(find.byType(Scrollable).evaluate().where((e) =>
      (e.widget as Scrollable).controller?.position.maxScrollExtent != 0), isEmpty,
      reason: 'the 3am screen must not require scrolling');
});
```

---

## 6. Accessibility as an executable gate

### 6.1 The real API, verified from source

`flutter_test` exposes four top-level guidelines, and — critically — the *class* behind the tap-target ones is public and const-constructible:

```dart
// packages/flutter_test/lib/src/accessibility.dart  (flutter/flutter master)
@visibleForTesting
class MinimumTapTargetGuideline extends AccessibilityGuideline {
  const MinimumTapTargetGuideline({required this.size, required this.link});
  final Size size;
  final String link;
  …
}

const AccessibilityGuideline androidTapTargetGuideline =
    MinimumTapTargetGuideline(size: Size(48.0, 48.0), link: '…');
const AccessibilityGuideline iOSTapTargetGuideline =
    MinimumTapTargetGuideline(size: Size(44.0, 44.0), link: '…');
const AccessibilityGuideline textContrastGuideline = MinimumTextContrastGuideline();
const AccessibilityGuideline labeledTapTargetGuideline = LabeledTapTargetGuideline._();
```

`AccessibilityGuideline` is `abstract class` with `FutureOr<Evaluation> evaluate(WidgetTester)` and `String get description`. `Evaluation` has `Evaluation.pass()`, `Evaluation.fail([String? reason])`, `bool passed`, `String? reason`, and `operator +` (logical AND, reasons joined by newline).

Matcher: `AsyncMatcher meetsGuideline(AccessibilityGuideline guideline)`, matched **against the `WidgetTester`**, and it requires semantics to be on:

```dart
final handle = tester.ensureSemantics();       // SemanticsHandle ensureSemantics()
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
handle.dispose();
```

Semantics are **not** on by default in widget tests — the semantics tree is only built while a `SemanticsHandle` is alive. Forgetting `ensureSemantics()` makes the guideline evaluate an empty tree and **pass vacuously**. That is the number-one way this gate silently does nothing.

Sources: [accessibility.dart](https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_test/lib/src/accessibility.dart), [AccessibilityGuideline](https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html), [MinimumTapTargetGuideline](https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html), [meetsGuideline](https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html), [ensureSemantics](https://api.flutter.dev/flutter/flutter_test/WidgetController/ensureSemantics.html).

### 6.2 The app's own, stricter rule

The spec demands **60×60 pt** — 25 % bigger than Android's 48 and 36 % bigger than iOS's 44. Because `MinimumTapTargetGuideline` takes `size` as a constructor parameter, no subclass is needed:

```dart
// test/support/shed_guidelines.dart
import 'package:flutter_test/flutter_test.dart';

/// spec §5: "Minimum tap target 60×60 pt." Stricter than either platform.
const shedBookTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/spec.md#5-design-spine-the-3am-test',
);
```

```dart
// test/ui/tap_targets_test.dart
void main() {
  for (final entry in screens.entries) {
    for (final device in Device.all) {
      testWidgets('${entry.key} · ${device.name} — 60pt tap targets', (tester) async {
        final handle = tester.ensureSemantics();
        addTearDown(handle.dispose);
        await tester.pumpApp(entry.value(), device: device, overrides: seededOverrides());
        await expectLater(tester, meetsGuideline(shedBookTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    }
  }
}
```

### 6.3 Why the built-in guideline is **not sufficient** — read the source

`MinimumTapTargetGuideline._traverse` skips a node when **any** of these hold:

1. `node.isMergedIntoParent` — merged nodes are checked via the parent's rect.
2. `shouldSkipNode(node)` is true: **no `tap` and no `longPress` action**, or `isHidden`, or `isLink`.
3. The node's painted rect touches the boundary of an ancestor with `hasImplicitScrolling`, within `_kMinimumGapToBoundary = 0.001` — "avoids cases where a tap target is partially scrolled off-screen".
4. **The node's painted rect touches the view boundary** (`Offset.zero & view.physicalSize`), by the same `_isAtBoundary` test.

Consequences for a one-thumb, bottom-heavy layout like this one:

- **A full-bleed bottom action bar is never checked.** If your Save button is anchored flush to the bottom edge of the screen, rule 4 skips it. This is exactly the button you most care about. Mitigation: keep a ≥ 1 px inset (you want the home-indicator inset anyway) **and** add the geometric gate below.
- **A raw `GestureDetector` with no `Semantics` produces no tappable node at all** → rule 2 skips it. Every tappable in this app must be built from a widget that emits semantics (`InkWell`, `*Button`, or an explicit `Semantics(button: true, …)`).
- The first item in a scrolled list, sitting flush against the viewport top, is skipped by rule 3.

### 6.4 The second, geometric gate

Belt and braces: require every tappable to be constructed through one app widget, then measure it directly.

```dart
// lib/ui/foundation/shed_tap.dart — the ONLY tappable primitive in the app.
class ShedTap extends StatelessWidget {
  const ShedTap({super.key, required this.onTap, required this.semanticLabel, required this.child});
  static const minSize = Size(60, 60);   // spec §5
  …
}
```

```dart
// test/ui/tap_target_geometry_test.dart
testWidgets('${name}: every ShedTap renders at least 60x60 (including at the screen edge)',
    (tester) async {
  await tester.pumpApp(build(), device: device, textScale: 1.0);
  final taps = find.byType(ShedTap);
  expect(taps, findsWidgets, reason: 'screen has no tappables — is the harness seeded?');
  for (var i = 0; i < taps.evaluate().length; i++) {
    final size = tester.getSize(taps.at(i));
    expect(size.width,  greaterThanOrEqualTo(60), reason: 'ShedTap #$i on $name');
    expect(size.height, greaterThanOrEqualTo(60), reason: 'ShedTap #$i on $name');
  }
});
```

…backed by a source gate so nobody bypasses `ShedTap`:

```dart
// test/policy/no_raw_gesture_detectors_test.dart
test('only lib/ui/foundation may use raw tap primitives', () {
  final banned = RegExp(r'\b(GestureDetector|InkWell|InkResponse|RawGestureDetector)\b');
  final offenders = dartFilesUnder('lib')
      .where((f) => !f.path.startsWith('lib/ui/foundation/'))
      .where((f) => banned.hasMatch(f.readAsStringSync()))
      .map((f) => f.path);
  expect(offenders, isEmpty,
      reason: 'spec §5: tappables must go through ShedTap so the 60pt gate can see them');
});
```

Also add a **no-banned-gesture** gate for §5's "no swipe-to-delete, no drag, no long-press-only, no pinch, no force touch":

```dart
test('no dismissible / draggable / long-press-only interactions', () {
  final banned = RegExp(r'\bDismissible\b|\bDraggable\b|\bScaleGestureRecognizer\b|onLongPress:');
  // onLongPress is allowed ONLY where an onTap exists on the same widget — checked separately.
  …
});
```

### 6.5 Contrast, and the red-shift mode

`MinimumTextContrastGuideline` enforces WCAG ratios (4.5:1 normal, 3.0:1 large; "large" determined by `kLargeTextMinimumSize` and `kBoldTextMinimumSize` via `targetContrastRatio(fontSize, bold: …)`), skips off-screen nodes via `isNodeOffScreen`, and samples **rendered pixels**. ([MinimumTextContrastGuideline](https://api.flutter.dev/flutter/flutter_test/MinimumTextContrastGuideline-class.html))

Practical consequences here:

- **Run it — a dark theme is exactly where contrast regressions hide.** Grey-on-black at 18 pt in a head torch is the failure mode the product exists to avoid.
- **Expect false positives on photo-bearing screens** (Ewe Card, Lamb Card, Lambing Entry with an attachment). It samples pixels, so text over a photo will fail non-deterministically depending on the seeded image. Mitigation: seed those screens with a *solid-colour* placeholder image in the harness, so the contrast result is deterministic and meaningful.
- **Red-shift mode is the risky theme.** A red-on-black palette can easily land under 4.5:1. Run the contrast guideline for `ShedTheme.redShift` on all 12 screens. This is arguably the highest-value accessibility test in the project, because red-shift is an optional mode nobody will look at closely after week one.

```dart
for (final theme in [ShedTheme.dark, ShedTheme.redShift]) {
  testWidgets('${entry.key} · ${theme.name} — text contrast', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpApp(entry.value(), theme: theme, overrides: solidColourImageOverrides());
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
```

Add a non-guideline assertion for the 18 pt floor, since no built-in guideline covers it:

```dart
test('no text style in the theme is below 18pt body / 40pt keypad digits', () {
  final t = ShedTheme.dark.data.textTheme;
  expect(t.bodyMedium!.fontSize, greaterThanOrEqualTo(18));   // §5
  expect(ShedTheme.dark.keypadDigitStyle.fontSize, greaterThanOrEqualTo(40)); // §7.1
});
```

---

## 7. Golden tests in 2026

### 7.1 State of the ecosystem — verified

| Package | Version | Publisher | Last published | Status |
|---|---|---|---|---|
| `golden_toolkit` | 0.15.0 | eBay (verified) | **~3 years** | **DISCONTINUED on pub.dev.** 488 likes, 374k downloads. No replacement named. |
| `alchemist` | **0.14.0** | Betterment (verified) | ~4 months | Active. 219 likes, 325k downloads. |
| `spot` | 0.18.0 | pascalwelsch.com | ~14 months | Alive but quiet. 110 likes. Not primarily a golden tool. |
| `golden_screenshot` | **11.0.1** | adil.hanney.org (verified) | ~4 months | Active. Aimed at **app-store screenshots**, with device frames + fuzzy comparison. |

The widely-repeated claim that golden_toolkit is dead is **confirmed** on its pub.dev page. Alchemist is the community's de-facto successor, and its changelog shows real, current maintenance: 0.12.0 raised the minimum Flutter to **3.32.0**; 0.13.0 disabled anti-aliasing on `BlockedTextPaintingContext` for cross-platform stability (a breaking golden change); **0.14.0 added `diffThreshold`** to absorb environment-dependent pixel noise. ([alchemist](https://pub.dev/packages/alchemist), [alchemist changelog](https://pub.dev/packages/alchemist/changelog))

Has Flutter's own tooling absorbed the gap? **Partly.** `matchesGoldenFile(Object key, {int? version})` works against a `Finder`, a `ui.Image` or a `Future<ui.Image>`; `flutter test --update-goldens` regenerates; `flutter_test_config.dart` gives you a per-project hook to load fonts and swap the comparator. What Flutter still does *not* give you: a scenario-grid builder, text blocking for CI, or a tolerance. `LocalFileComparator` is documented as **pixel-for-pixel exact, no tolerance**. ([matchesGoldenFile](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html), [LocalFileComparator](https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html))

### 7.2 The call for this app: built-in, not alchemist

**Adopt `matchesGoldenFile` + a 40-line project harness. Do not adopt alchemist for v1.**

Reasoning specific to Shed Book:
- Alchemist's headline feature — **CI goldens with blocked text** — is deliberately unsuitable here. Blocking text into coloured squares removes the exact property this app's goldens exist to protect: *is the 18 pt type legible, does the tag number fit in the button at textScaler 2.0*. If you block the text, the golden proves nothing you couldn't get from the overflow matrix for free.
- Alchemist's other headline feature — **scenario grids across themes** — is worth a lot in a design-system package with light/dark/brand variants. This app has one theme plus a red-shift variant and eight images total.
- Alchemist couples you to a Flutter-version floor (0.12.0 raised it to 3.32.0) and to golden-affecting behavioural changes (0.13.0's anti-aliasing change re-baselined everyone's goldens). For a solo developer, a golden re-baseline forced by a dependency upgrade is pure cost.
- **Honest counter-argument**: `diffThreshold` (0.14.0) genuinely solves the cross-machine flake that will bite you the first time you run goldens on a different macOS version. But you can get the same thing in ~25 lines by wrapping `LocalFileComparator` (below), without the dependency. If the harness ever grows past ~150 lines, switch to alchemist and don't be precious about it.

**`golden_screenshot` 11.0.1 is worth a separate look, later, for a different job**: generating App Store / Play Store screenshots from golden tests. For a solo dev shipping a €10–15 paid app, that's real value — but it is a release-asset pipeline, not a regression gate. Keep it out of `test/`.

### 7.3 The harness: `flutter_test_config.dart`

The Flutter test framework scans up the directory tree for `flutter_test_config.dart` and calls `Future<void> testExecutable(FutureOr<void> Function() testMain)`, stopping at the first one found or at a `pubspec.yaml`. ([flutter_test library](https://api.flutter.dev/flutter/flutter_test/))

```dart
// test/flutter_test_config.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();
  goldenFileComparator = TolerantFileComparator(
    Uri.parse('${Directory.current.path}/test/'),
    tolerance: 0.005, // 0.5% of pixels may differ
  );
  return testMain();
}

/// Golden files render 'Ahem' (solid squares) unless real fonts are loaded.
/// This app's goldens exist to prove legibility, so real fonts are mandatory.
Future<void> _loadAppFonts() async {
  for (final family in const {'ShedSans': ['assets/fonts/ShedSans-Regular.ttf',
                                           'assets/fonts/ShedSans-Bold.ttf']}.entries) {
    final loader = FontLoader(family.key);           // FontLoader(String family)
    for (final asset in family.value) {
      loader.addFont(rootBundle.load(asset));        // void addFont(Future<ByteData>)
    }
    await loader.load();                             // Future<void> load()
  }
}
```

`FontLoader` is exported from `package:flutter/services.dart`; the builder pattern above is the documented usage. ([FontLoader](https://api.flutter.dev/flutter/services/FontLoader-class.html))

```dart
// test/support/tolerant_comparator.dart
class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, {required this.tolerance});
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
```

### 7.4 Why goldens are OS- and version-sensitive, and how to pin

The `matchesGoldenFile` docs state it directly: *"A golden file generated on Windows with fonts will likely differ from the one produced by another operating system."* Flutter's own team solves this by generating **separate images per platform** through Flutter Gold/Skia Gold, and their contributor docs say plainly: *"It is common for there to be slight differences between them."* ([golden file test docs](https://github.com/flutter/flutter/blob/master/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md))

Flutter Gold is not available to app developers. So for Shed Book:

1. **One runner, one OS, one exact Flutter version.** Goldens are generated and verified on `macos-latest` with `flutter-version: 3.44.6` pinned exactly (not `stable`). A Flutter upgrade is a deliberate, separate PR whose diff is the re-baselined PNGs. Goldens are known to differ across Flutter versions ([flutter#36667](https://github.com/flutter/flutter/issues/36667)).
2. **Tag them and exclude them from the fast PR job**: `flutter test --exclude-tags golden` on Linux; `flutter test --tags golden` on the pinned macOS job.
3. **Never run `--update-goldens` on CI.** Regeneration is a local, reviewed act.
4. **Commit the `failures/` directory to the CI artifacts**, not to git — `LocalFileComparator` writes four images per failure (master, test, isolated diff, masked diff), which makes review trivial.

### 7.5 What a dark-theme-only app should actually golden

Eight images. Each one protects a property that no other test can see:

| Golden | Protects |
|---|---|
| `quick_entry_default` | The 3am screen. The whole product. |
| `quick_entry_scale2.0` | 60 pt targets + 40 pt digits + 18 pt body survive the largest accessibility scale. |
| `quick_entry_redshift` | The red-shift palette is legible, not just "different". |
| `pen_board_12_pens` | Glanceability: badge colour, hours-since-penned typography, arm's-length legibility. |
| `withdrawal_row_three_states` | Active / clears-today / cleared colour semantics. Getting this wrong is a food-safety UI bug. |
| `lambing_spread_chart` | The one chart in the app (§7.8), against a fixed dataset. Charts are where silent rendering regressions hide. |
| `ewe_card_summary_line` | The one-line summary (§7.7) — the retention feature. Truncation regressions here are invisible in a widget test. |
| `export_pdf_footer` | §12.3: the "this is not a regulatory record" disclaimer is present and legible. |

Deliberately **not** goldened: Flock, Lamb Card, Foster, Treatments list, Reminders, Season Summary, Settings. Those are covered by the overflow matrix and the a11y gate, which are cheaper and never need re-baselining.

Every golden is pumped through `pumpApp` with a **frozen clock** (`Clock.fixed`) and a **seeded database**, or the timestamps in the image change every run.

---

## 8. Integration testing: `integration_test` vs patrol

### 8.1 Verified state

- **`integration_test`** ships with the Flutter SDK. Add with `flutter pub add "dev:integration_test:{sdk: flutter}"`, put files in `integration_test/`, call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, run with `flutter test integration_test/app_test.dart` on a connected device. ([docs.flutter.dev/testing/integration-tests](https://docs.flutter.dev/testing/integration-tests))
- **`patrol` 4.8.0**, LeanCode (verified), published **2 days** before this research, 710 likes, 412k downloads, Android/iOS/macOS/Web. It requires `patrol_cli`, a Gradle configuration on Android and an Xcode test target on iOS, and its own runner — the docs state flatly that **"`flutter test` won't work!"** for Patrol tests. 4.7.0 added Swift Package Manager support. ([pub.dev/packages/patrol](https://pub.dev/packages/patrol), [patrol.leancode.co](https://patrol.leancode.co/documentation))

Flutter's own testing overview lists both, describing patrol as extending testing "with native platform UI support (permissions, notifications, platform views)".

### 8.2 The call: `integration_test` for v1

Patrol is a good, healthy package and its value proposition — native dialogs — is genuinely relevant here: this app touches **notification permission**, **microphone** (voice tag entry, §7.1), **camera** (OCR + photo, §7.1/§7.2), and the **system share sheet** (§7.9). Those are four native surfaces `integration_test` cannot drive.

But for v1, integration_test wins on the cost side:

- Those four dialogs appear **once each, on first use**. A solo developer can verify them by hand in five minutes per release. Automating them costs a Gradle test target, an Xcode test target, `patrol_cli` in CI, and the loss of `flutter test` for those files — permanently.
- The share sheet is a black box even for patrol: the meaningful assertion is *"we produced these bytes with this filename and mime type"*, which is a fake-gateway assertion in a widget test, not an e2e one.
- The spec's own posture is anti-nag (§5: "no notification permission nags mid-season"), so the permission surface is deliberately tiny.

**Honest counter-argument:** §5 says *"assume the phone dies"*. Proving that properly means killing the process mid-entry and relaunching — which patrol can do (`pressHome`, native app control) and `integration_test` cannot. That is a real gap. The mitigation is to move the durability proof *down* a layer, to §3.6's reopen-the-file test, which is more deterministic than a process-kill test would be anyway. Revisit patrol if permission flows ever regress in the field, or for v2 when EID/Bluetooth appears (§13) and native automation becomes unavoidable.

### 8.3 The four journeys worth an e2e test

An app with no network and no login has very little integration-shaped risk — which is precisely why the set should be small. Each of these exercises a **wiring** concern that unit and widget tests structurally cannot.

1. **Cold start → saved lambing event.** Launch the real app against a real on-device SQLite file, tap through Recents → event → birth type → save. Assert (a) the row is in the real database, (b) the app returned to the board, (c) the tap count. This is the product's headline promise end to end, including the real database, the real theme and the real navigation stack.
2. **Create-on-the-fly.** Type an unknown tag `731` on the keypad → one tap creates the ewe → continue straight into Lambing Entry. §7.1: *"Never block an entry to make the user go and set something up first."* This journey is entirely about routing + DB creation ordering, which is exactly the wiring layer.
3. **Foster in two taps.** §7.3 names this as *"the flow most likely to be abandoned if it takes five taps"*. Assert `birthDam` and `rearingDam` are both persisted and distinct after the second tap.
4. **Backup round trip on the device.** Export a full JSON backup to a temp file (bypassing the share sheet), wipe the database, restore, and assert the flock reads identically — including timestamp provenance. This is the only mechanism standing between a user and total data loss (§4, §7.9); it deserves to be proven on a real filesystem with real file permissions, not in memory.

Everything else — reminders, treatments, stats, settings — stays in widget/unit tests where it is faster and more precise.

---

## 9. Test organisation, CI and discipline

### 9.1 Layout

```
test/
  domain/          # mirrors lib/domain — pure functions, the thick layer
  data/            # DAOs against NativeDatabase.memory()
  drift/           # generated migration tests (drift's default test_dir)
  ui/              # widget tests: overflow matrix, a11y gates, per-screen behaviour
  golden/          # ~8 goldens + goldens/*.png
  policy/          # ⭐ spec §12 + offline-only, as executable assertions
  support/         # pump_app.dart, shed_guidelines.dart, seeds, tolerant_comparator.dart
  fakes/           # the six gateway fakes
  flutter_test_config.dart
integration_test/  # 4 journeys
drift_schemas/     # committed schema snapshots — the migration contract
```

`test/` mirrors `lib/` one-for-one except for `policy/`, `support/` and `fakes/`. Files are `<subject>_test.dart`. **`test/policy/` is the directory that makes this project unusual, and it should be the first thing a new reader opens.**

### 9.2 `dart_test.yaml`

Verified fields from [package:test configuration docs](https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md):

```yaml
# dart_test.yaml
tags:
  golden:
    # generated and verified only on the pinned macOS runner
  migration:
    timeout: 2x
    allow_test_randomization: false   # migration tests are order-sensitive by design
  policy:
  slow:
    timeout: 3x

presets:
  ci-fast:
    exclude_tags: golden
  ci-golden:
    include_tags: golden
```

`flutter test` registers `--tags`/`-t` and `--exclude-tags`/`-x` as pass-throughs (verified in `flutter_tools/lib/src/commands/test.dart`), along with `--update-goldens`, `--coverage`, `--coverage-path` (default `coverage/lcov.info`), `--reporter`/`-r`, `--file-reporter`, `--concurrency`/`-j`, `--test-randomize-ordering-seed`, `--name`, `--plain-name`, `--total-shards`, `--shard-index`, `--timeout`, `--fail-fast`, and `--dart-define` via `usesDartDefineOption()`.

> ⚠️ **Verify locally**: `flutter test` historically has gaps in how much of `dart_test.yaml` it honours compared to `dart test`. Confirm on day one that `allow_test_randomization: false` actually takes effect; if not, fall back to `--exclude-tags migration` in the randomized job and run migrations in a separate, non-randomized invocation.

### 9.3 Randomized ordering

`--test-randomize-ordering-seed` takes a 32-bit unsigned int or `random`; `0` disables. Run CI with `random`, and the seed is printed on every run so a failure is reproducible with `--test-randomize-ordering-seed=<seed>`.

This matters more than usual here because the DAO and migration suites share a `setUp`-created database; ordering randomisation is what catches accidental cross-test state (a stale `withClock`, a leaked `sqlite3` VFS registration, a static seed counter).

### 9.4 CI vs local

| Job | Runner | Command | Blocks merge? |
|---|---|---|---|
| Analyze | `ubuntu-latest` | `flutter analyze --fatal-infos` | Yes |
| Format | `ubuntu-latest` | `dart format --set-exit-if-changed .` | Yes |
| Codegen freshness | `ubuntu-latest` | `dart run build_runner build -d && dart run drift_dev make-migrations && git diff --exit-code` | Yes |
| Fast tests | `ubuntu-latest` + `libsqlite3-dev` | `flutter test -P ci-fast --test-randomize-ordering-seed random --coverage` | Yes |
| Hostile timezone | `ubuntu-latest` | `TZ=Pacific/Chatham flutter test test/domain` | Yes |
| Release manifest gate | `ubuntu-latest` | build release APK + `apkanalyzer manifest permissions` (§10.2) | Yes |
| Goldens | `macos-latest`, Flutter pinned to **3.44.6** | `flutter test -P ci-golden` | Yes |
| Integration | nightly, real device / simulator | `flutter test integration_test` | No — reported |
| Startup trace | nightly, real device | `flutter run --trace-startup --profile` (§10.1) | No — reported |

### 9.5 Coverage as a report, not a gate

The argument, specific to this codebase:

- The **highest-value tests in this project contribute almost zero line coverage**: the manifest permission gate, the schema-JSON-has-no-default gate, the source-scanning policy tests, the a11y guideline runs. A coverage number that ignores them is measuring the wrong thing.
- **Generated code dominates the denominator.** Drift's `*.g.dart` and Riverpod's generated providers can be thousands of lines. Standard practice is to strip them post-hoc: `lcov --remove coverage/lcov.info '*.g.dart' '*.freezed.dart' '*/generated/*' -o coverage/lcov.info`. After stripping, the number moves a lot for reasons unrelated to test quality.
- A percentage gate creates pressure to write tests for `copyWith` and `toString` — the cheapest lines to cover and the least valuable to test — while the DST cases stay unwritten.

Instead: publish `genhtml` output as a CI artifact, and **track one number that means something — coverage of `lib/domain/**`**, where every line is a pure function and where "not covered" genuinely means "not tested". Aim high there (95 %+) as a *review prompt*, not a build failure. Everywhere else, look at the uncovered-file list in review, not the number.

### 9.6 Flakiness discipline

Zero tolerance, enforced by rules rather than willpower:

- **Banned in tests**: `Future.delayed` (use `FakeAsync`), wall-clock assertions, `DateTime.now()`, reliance on ambient `TZ`/locale, `pumpAndSettle()` with no timeout on any screen with a repeating animation (it hangs for 10 minutes then fails opaquely — pass `EnginePhase`/timeout or use explicit `pump(duration)`).
- A `flaky` tag exists, is **excluded from CI**, and every test carrying it must have an expiry date in its name: `testWidgets('flaky-until-2026-09-01: …', tags: ['flaky'])`. A policy test fails the build when an expiry date passes. Quarantine without an expiry is how suites rot.
- Any test that fails once on CI and passes on rerun is fixed or deleted **that day**. There is one developer; there is no one else to absorb the noise.
- `experimentalLeakTesting` (Flutter's `leak_tracker` integration in `testWidgets`) is available and Flutter 3.44 upgraded leak_tracker for flakiness fixes — but the parameter is documented as experimental and not recommended outside the framework. **Leave it off.** Revisit only if you see real leaks in DevTools.

---

## 10. The product's own promises, as tests

This is `test/policy/`. Each file names its spec clause in the first line.

### 10.1 "Under 15 seconds from unlock to a saved lambing event" (§5, §15)

The dishonest version is a widget test that measures elapsed wall time. `flutter test` runs under `FakeAsync` with a fake clock, so wall time there is meaningless; on CI it is pure noise. **Do not write it.**

The honest version decomposes the 15 s into three budgets, each measured by the right tool:

**(a) Interaction budget — deterministic, per-PR, blocking.** This is the one that actually keeps the promise true, because taps are what the user spends time on.

```dart
// test/policy/interaction_budget_test.dart — §5, §15
class TapCounter {
  int taps = 0;
  int textEntries = 0;
  int scrolls = 0;
}

extension CountedActions on WidgetTester {
  Future<void> countedTap(Finder f, TapCounter c) async { c.taps++;  await tap(f); await pumpAndSettle(); }
  Future<void> countedEnter(Finder f, String s, TapCounter c) async { c.textEntries++; await enterText(f, s); await pumpAndSettle(); }
}

testWidgets('recents path: a saved lambing event costs at most 4 taps and no typing', (tester) async {
  final c = TapCounter();
  await tester.pumpApp(const QuickEntryScreen(), overrides: seededOverrides(recents: [ewe412]));

  await tester.countedTap(find.byKey(const Key('recents.412')), c);        // 1 pick the ewe
  await tester.countedTap(find.byKey(const Key('event.lambed')), c);       // 2 what happened
  await tester.countedTap(find.byKey(const Key('birth_type.twin')), c);    // 3 the only required field
  await tester.countedTap(find.byKey(const Key('lambing.save')), c);       // 4 done

  expect(c.taps, lessThanOrEqualTo(4));
  expect(c.textEntries, 0);
  expect(c.scrolls, 0);
  expect(await db.lambings.count(), 1);
});

testWidgets('keypad path: at most 1 typed tag + 4 taps', (tester) async { … });
testWidgets('create-on-the-fly adds at most 1 tap over the keypad path', (tester) async { … });
```

Budget rationale: 4 taps at a generous 1.5 s each (gloved, wet, cold, dark) is 6 s, leaving ~9 s for unlock + cold start. That is the arithmetic behind the numbers; put it in the test file as a comment so the next person knows why 4 and not 6.

**(b) Cold-start budget — measured on a real device, nightly, reported not gated.**

`flutter run --trace-startup --profile` writes `build/start_up_info.json` containing `engineEnterTimestampMicros`, `timeToFrameworkInitMicros`, `timeToFirstFrameMicros`, `timeAfterFrameworkInitMicros`. ([Flutter debugging docs](https://github.com/flutter/website/blob/main/src/testing/debugging.md))

```bash
flutter run --trace-startup --profile -d <device-id>
python3 tool/check_startup.py build/start_up_info.json --max-first-frame-ms 1200
```

This is device- and thermal-dependent. **Report it, plot the trend, do not block a merge on it.** A hard gate on device timing is the single most reliable way to manufacture a flaky CI.

This budget also happens to protect §5's *"no white flash on launch"* — assert it statically instead of visually:

```dart
// test/policy/no_white_launch_test.dart — §5
test('the native launch screen is dark on both platforms', () {
  final styles = File('android/app/src/main/res/values/styles.xml').readAsStringSync();
  expect(styles, contains('@drawable/launch_background'));
  expect(File('android/app/src/main/res/drawable/launch_background.xml').readAsStringSync(),
      matches(RegExp(r'#(00|0[0-9A-F])[0-9A-F]{4}', caseSensitive: false)),
      reason: 'launch background must be near-black, not @android:color/white');

  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  expect(plist, isNot(contains('UIUserInterfaceStyle</key>\n\t<string>Light')));
});
```

**(c) Frame budget — nightly, integration_test, reported.**

```dart
// integration_test/quick_entry_perf_test.dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('the quick-entry path does not jank', (tester) async {
  await tester.pumpWidget(const ShedBookApp());
  await binding.traceAction(() async {
    await tester.tap(find.byKey(const Key('recents.412'))); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event.lambed'))); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lambing.save'))); await tester.pumpAndSettle();
  }, reportKey: 'quick_entry_timeline');
});
```

Verified signature: `Future<void> traceAction(Future<dynamic> Function() action, {List<String> streams = const ['all'], bool retainPriorEvents = false, String reportKey = 'timeline'})`. Results land in `binding.reportData` and reach the host through `integrationDriver(responseDataCallback: …)`, where `TimelineSummary.summarize(timeline).writeTimelineToFile(...)` produces `build/*.timeline_summary.json` with `missed_frame_build_budget_count`, `worst_frame_build_time_millis`, etc. ([profiling cookbook](https://docs.flutter.dev/cookbook/testing/integration/profiling))

Run with `flutter drive --driver=test_driver/perf_driver.dart --target=integration_test/quick_entry_perf_test.dart --profile`. Track `missed_frame_build_budget_count` as a trend; alert on a step change, don't gate.

### 10.2 "The app has no network path" (§4)

Four layers, because no single check is sufficient — and one honest complication that a naive plan gets wrong.

**⚠️ The complication:** `flutter_local_notifications` → `timezone` **0.11.1**, and `timezone` declares `http: ^1.6.0` as a **regular dependency**, not a dev dependency (verified in its pubspec). So **`package:http` will be in your dependency graph no matter what you do.** A gate of the form "`pubspec.lock` must not contain `http`" is unsatisfiable. The gate must operate on **imports in `lib/`**, plus an explicit, documented allowlist explaining why `http` is present and unused.

**Layer A — source gate (Dart test, per-PR, blocking).**

```dart
// test/policy/no_network_imports_test.dart — §4
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

const _bannedUris = {
  'package:http/http.dart', 'package:http/retry.dart',
  'package:dio/dio.dart', 'package:web_socket_channel/web_socket_channel.dart',
  'package:grpc/grpc.dart', 'dart:html', 'package:web/web.dart',
  'package:firebase_core/firebase_core.dart',
};
// dart:io is allowed (files, share sheet), but not its network surface:
final _bannedIdentifiers = RegExp(
  r'\b(HttpClient|HttpServer|Socket|RawSocket|SecureSocket|ServerSocket|Datagram|RawDatagramSocket|InternetAddress)\b');

void main() {
  test('no file under lib/ can reach the network — spec §4', () {
    final violations = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))) {
      final unit = parseFile(path: file.absolute.path,
          featureSet: FeatureSet.latestLanguageVersion()).unit;
      for (final d in unit.directives.whereType<UriBasedDirective>()) {
        final uri = d.uri.stringValue;
        if (uri != null && _bannedUris.contains(uri)) {
          violations.add('${file.path}: imports $uri');
        }
      }
      for (final m in _bannedIdentifiers.allMatches(file.readAsStringSync())) {
        violations.add('${file.path}: references ${m.group(0)}');
      }
    }
    expect(violations, isEmpty,
        reason: 'Shed Book is permanently offline (spec §4). '
                'No lib/ code may open a socket or an HTTP client.');
  });
}
```

Optionally back this with `import_lint` **2.0.0** (kawa.dev, ~3 months old, requires **Dart 3.10+** / analyzer plugin support added in Dart 3.10 / Flutter 3.38 — satisfied by Dart 3.12.2), which surfaces the same rule live in the IDE. But the test above is the gate; the lint is convenience.

**Layer B — dependency allowlist (Dart test, per-PR, blocking).**

```dart
test('the direct dependency set is on the offline allowlist — spec §4', () {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final direct = (pubspec['dependencies'] as YamlMap).keys.cast<String>().toSet();
  expect(direct.difference(kOfflineAllowlist), isEmpty,
      reason: 'a new direct dependency must be reviewed against spec §4 before it lands');
});

test('http is present only transitively, via timezone, and is not imported', () {
  final lock = loadYaml(File('pubspec.lock').readAsStringSync()) as YamlMap;
  final http = (lock['packages'] as YamlMap)['http'] as YamlMap?;
  if (http != null) {
    expect(http['dependency'], 'transitive',
        reason: 'timezone 0.11.x declares http as a regular dependency (it is only used by '
                'its tzdata tooling). It must never become a direct dependency, and '
                'no_network_imports_test proves nothing in lib/ imports it.');
  }
});
```

**Layer C — Android manifest gate (shell, per-PR, blocking).**

Two facts that make this subtle:

1. Flutter **deliberately puts `INTERNET` in the debug and profile manifests** (`android/app/src/debug/AndroidManifest.xml`, `.../profile/…`) so the tooling can reach the VM service for hot reload. Build-type manifests have **higher** merge priority than `main`. So a naive test that inspects a debug build **will always find INTERNET and always fail**. The gate must target the **release** variant. ([flutter#20789](https://github.com/flutter/flutter/issues/20789), [flutter#22139](https://github.com/flutter/flutter/pull/22139))
2. A library (plugin) manifest can *add* `INTERNET` at any time via an innocuous dependency upgrade. Library manifests are the **lowest** priority, so `main` can strip them with `tools:node="remove"`. ([Manifest merging](https://developer.android.com/build/manage-manifests))

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
    <!-- spec §4: the strongest form of "offline" is an app that cannot reach the network. -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
    …
</manifest>
```

```bash
# tool/assert_no_internet_permission.sh   (CI, blocking)
set -euo pipefail
flutter build apk --release
APK=build/app/outputs/flutter-apk/app-release.apk
PERMS=$("$ANDROID_HOME"/cmdline-tools/latest/bin/apkanalyzer manifest permissions "$APK")
echo "$PERMS"
if grep -q 'android.permission.INTERNET' <<<"$PERMS"; then
  echo "FAIL: spec §4 — the release APK declares INTERNET." >&2
  echo "Blame (which manifest added it):" >&2
  cat android/app/build/outputs/logs/manifest-merger-release-report.txt >&2
  exit 1
fi
echo "OK: release APK declares no INTERNET permission."
```

`apkanalyzer manifest permissions <apk>` and `apkanalyzer manifest print <apk>` are the documented commands; note **apkanalyzer takes an APK, not an AAB**, so build an APK for the check even if you ship an AAB. ([apkanalyzer](https://developer.android.com/tools/apkanalyzer))

Also assert the `tools:node="remove"` line still exists (someone will "clean up" the manifest):

```dart
test('the release manifest still strips INTERNET — spec §4', () {
  final m = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  expect(m, contains('android:name="android.permission.INTERNET"'));
  expect(m, contains('tools:node="remove"'));
});
```

**Layer D — runtime guard + its test (both platforms; the only real iOS answer).**

iOS has no manifest permission for network access, so there is nothing to assert at build time. Be honest about that. What you *can* do is make an accidental network call impossible at runtime and prove it in a test:

```dart
// lib/main.dart
class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw UnsupportedError('Shed Book is permanently offline (spec §4).');
}

void main() {
  HttpOverrides.global = _NoNetwork();   // static setter: HttpOverrides? global
  runApp(const ProviderScope(child: ShedBookApp()));
}
```

```dart
// test/policy/runtime_network_guard_test.dart — §4
test('creating an HttpClient throws once the guard is installed', () {
  HttpOverrides.runWithHttpOverrides(() {
    expect(() => HttpClient(), throwsUnsupportedError);
  }, _NoNetwork());
});
```

`HttpOverrides.global` is a static setter; `createHttpClient(SecurityContext?) → HttpClient` and `static R runWithHttpOverrides<R>(R Function() body, HttpOverrides overrides)` are the verified signatures, and overriding `createHttpClient` to throw does propagate to all `HttpClient()` construction. ([HttpOverrides](https://api.dart.dev/stable/dart-io/HttpOverrides-class.html))

Add an iOS static check for good measure:

```dart
test('iOS Info.plist grants no arbitrary-loads exception', () {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  expect(plist, isNot(contains('NSAllowsArbitraryLoads')));
  expect(plist, isNot(contains('NSAppTransportSecurity')));
});
```

**What none of this proves:** a native plugin could open a socket from Swift/Kotlin without `dart:io`. On Android the missing INTERNET permission stops it dead. On iOS it does not. The residual iOS assurance is: a small, reviewed direct-dependency allowlist (Layer B) + a manual airplane-mode run before each release. Say that out loud in the docs rather than pretending the gate is airtight.

### 10.3 "Never default a medicine withdrawal period" (§12.1)

Four independent tests, because this is the rule where a regression is a food-safety incident.

```dart
// test/policy/withdrawal_no_default_test.dart — §12.1
group('§12.1 — the app ships no default withdrawal period', () {
  test('the database column has no default, in code and in the committed schema', () async {
    final db = ShedDb.forTesting();
    addTearDown(db.close);
    final col = db.treatments.withdrawalDaysUserEntered;
    expect(col.defaultValue, isNull,        reason: 'no withDefault()');
    expect(col.clientDefault, isNull,       reason: 'no clientDefault()');
    expect(col.$nullable, isFalse,          reason: 'a nullable column invites a ?? fallback');

    // and in the committed contract, so a future schema can't sneak one in:
    final schema = jsonDecode(File('drift_schemas/drift_schema_v${db.schemaVersion}.json')
        .readAsStringSync());
    final entry = findColumn(schema, table: 'treatments', column: 'withdrawal_days_user_entered');
    expect(entry['default_dart'], isNull);
    expect(entry['default_client_dart'], isNull);
  });

  test('no code path supplies a withdrawal value the user did not type', () {
    // Heuristic backstop to the type-level design.
    final bad = RegExp(
      r'withdrawal\w*\s*[:=]\s*(\d+|.*\?\?)|'      // withdrawalDays: 28  /  withdrawalDays ?? 0
      r'withdrawal\w*\s*\?\?',
      caseSensitive: false);
    final offenders = dartFilesUnder('lib')
        .where((f) => bad.hasMatch(f.readAsStringSync())).map((f) => f.path);
    expect(offenders, isEmpty,
        reason: '§12.1: the user reads the number off the bottle. The app never supplies one.');
  });

  test('no bundled asset contains medicine or withdrawal data', () {
    // §11: "No breed database, no medicine database."
    final assets = Directory('assets').listSync(recursive: true).whereType<File>();
    for (final a in assets) {
      final text = a.path.endsWith('.json') || a.path.endsWith('.yaml')
          ? a.readAsStringSync() : '';
      expect(RegExp(r'withdrawal|meat_days|milk_days', caseSensitive: false).hasMatch(text),
          isFalse, reason: '${a.path} looks like a medicine database');
    }
    expect(bundledTerms.every((t) => !RegExp(r'\d+\s*day').hasMatch(t)), isTrue,
        reason: '§11: the 40 authored terms are vocabulary, not numbers');
  });

  testWidgets('Save is disabled until the user types a withdrawal period', (tester) async {
    await tester.pumpApp(const TreatmentEntryScreen());
    await tester.tap(find.byKey(const Key('treatment.product')));
    await tester.enterText(find.byKey(const Key('treatment.product')), 'Alamycin LA');
    await tester.pumpAndSettle();
    expect(tester.widget<ShedTap>(find.byKey(const Key('treatment.save'))).onTap, isNull);

    await tester.enterText(find.byKey(const Key('treatment.withdrawal')), '28');
    await tester.pumpAndSettle();
    expect(tester.widget<ShedTap>(find.byKey(const Key('treatment.save'))).onTap, isNotNull);
    expect(find.text('as entered by you'), findsOneWidget);  // §12.1's required label
  });
});
```

Design note that makes the tests easy: model it as a value type with no zero value.

```dart
/// There is deliberately no const WithdrawalPeriod.none / .zero / .defaultValue.
extension type const WithdrawalPeriod._(int days) {
  factory WithdrawalPeriod.asEnteredByUser(int days) {
    if (days < 0) throw ArgumentError.value(days);
    return WithdrawalPeriod._(days);
  }
}
```

Add a policy test that this type has exactly one public factory, so nobody adds `.zero` later:

```dart
test('WithdrawalPeriod exposes exactly one constructor, named for its provenance', () {
  final src = File('lib/domain/treatment/withdrawal_period.dart').readAsStringSync();
  final ctors = RegExp(r'factory\s+WithdrawalPeriod\.(\w+)').allMatches(src)
      .map((m) => m.group(1)).toList();
  expect(ctors, ['asEnteredByUser']);
});
```

### 10.4 "Never silently correct a user's entry" (§12.4)

The half everyone writes is "a warning appears". The half everyone forgets is **"and the record is unchanged"**. Assert both, and assert the second one against the database, not against an in-memory object.

```dart
// test/policy/no_silent_correction_test.dart — §12.4
test('birth type "twin" with three lambs warns and mutates nothing', () async {
  final db = ShedDb.forTesting();
  addTearDown(db.close);

  final id = await db.lambings.save(LambingDraft(
    eweTag: '412', birthType: BirthType.twin,
    lambs: [lamb(), lamb(), lamb()],           // three, deliberately
  ));
  final stored = await db.lambings.byId(id);
  final storedLambs = await db.lambs.forLambing(id);

  final warnings = LambingConsistency.check(stored, storedLambs);
  expect(warnings, [const Warning.birthTypeLambCountMismatch(declared: 2, counted: 3)]);

  // The critical assertion: check() is a query, not a command.
  expect(await db.lambings.byId(id), stored);
  expect(await db.lambs.forLambing(id), storedLambs);
  expect((await db.lambings.byId(id)).birthType, BirthType.twin,
      reason: '§12.4: flag it; do not fix it');
});

testWidgets('the warning is visible, dismissible, and dismissing writes nothing', (tester) async {
  await tester.pumpApp(LambingEntryScreen(lambingId: id), overrides: [dbOverride(db)]);
  expect(find.textContaining('twin', findRichText: true), findsWidgets);
  expect(find.byKey(const Key('warning.birth_type_mismatch')), findsOneWidget);

  final before = await db.lambings.byId(id);
  await tester.tap(find.byKey(const Key('warning.dismiss')));
  await tester.pumpAndSettle();
  expect(await db.lambings.byId(id), before);
});

test('no domain function named fix*/correct*/normalize* performs a write', () {
  final offenders = dartFilesUnder('lib/domain')
      .where((f) => RegExp(r'\b(fix|correct|normalise|normalize|autoFix)\w*\s*\(')
          .hasMatch(f.readAsStringSync()))
      .map((f) => f.path);
  expect(offenders, isEmpty, reason: '§12.4');
});
```

Property test (glados) for the general rule:

```dart
Glados2(any.birthType, any.intInRange(0, 6)).test(
  'check() warns iff declared != counted, and is always pure',
  (declared, counted) {
    final before = snapshot(db);
    final warnings = LambingConsistency.check(lambingWith(declared, counted), …);
    expect(snapshot(db), before);
    expect(warnings.isNotEmpty, declared.expectedLambs != counted);
  },
);
```

### 10.5 "Timestamps are honest" (§12.5)

Model provenance as **stored data**, never as something derived at read time (derived provenance is the bug: it silently becomes "auto" after any refactor of the edit path).

```dart
enum TimeProvenance { autoCaptured, editedByUser }

class EventTime {
  final DateTime instantUtc;
  final TimeProvenance provenance;
  final DateTime? originalInstantUtc;   // set only when edited
  final DateTime? editedAtUtc;          // set only when edited
}
```

```dart
// test/policy/timestamp_provenance_test.dart — §12.5
test('an auto-captured time is labelled auto and keeps no original', () {
  withClock(Clock.fixed(DateTime.utc(2026, 3, 28, 3, 12)), () {
    final t = EventTime.autoCapture();
    expect(t.instantUtc, DateTime.utc(2026, 3, 28, 3, 12));
    expect(t.provenance, TimeProvenance.autoCaptured);
    expect(t.originalInstantUtc, isNull);
    expect(t.editedAtUtc, isNull);
  });
});

test('editing preserves the original and records when the edit happened', () {
  final auto = withClock(Clock.fixed(DateTime.utc(2026, 3, 28, 7, 0)), EventTime.autoCapture);
  final edited = withClock(Clock.fixed(DateTime.utc(2026, 3, 28, 7, 5)),
      () => auto.editTo(DateTime.utc(2026, 3, 28, 3, 20)));  // "it actually happened at 3:20"

  expect(edited.instantUtc, DateTime.utc(2026, 3, 28, 3, 20));
  expect(edited.provenance, TimeProvenance.editedByUser);
  expect(edited.originalInstantUtc, DateTime.utc(2026, 3, 28, 7, 0));
  expect(edited.editedAtUtc, DateTime.utc(2026, 3, 28, 7, 5));
});

test('provenance survives a database round trip and a reopen', () async {
  final file = File('${Directory.systemTemp.createTempSync().path}/shed.sqlite');
  var db = ShedDb(NativeDatabase(file));
  final id = await db.lambings.save(draft.copyWith(time: edited));
  await db.close();

  db = ShedDb(NativeDatabase(file));
  final back = await db.lambings.byId(id);
  expect(back.time, edited);   // all four fields
  await db.close();
});

test('the persisted enum names are frozen — changing them breaks every backup', () {
  expect(TimeProvenance.values.map((e) => e.name).toList(),
         ['autoCaptured', 'editedByUser']);
});

test('an edited time exported and re-imported does not come back as auto-captured', () async {
  final json = await ExportService(db).jsonBackup();
  final fresh = ShedDb.forTesting();
  addTearDown(fresh.close);
  await ImportService(fresh).restore(json);
  expect((await fresh.lambings.byId(id)).time.provenance, TimeProvenance.editedByUser);
});

testWidgets('the UI labels edited times and does not label auto ones', (tester) async {
  await tester.pumpApp(LambingEntryScreen(lambingId: autoId));
  expect(find.text('edited'), findsNothing);
  await tester.pumpApp(LambingEntryScreen(lambingId: editedId));
  expect(find.text('edited'), findsOneWidget);
});
```

Also golden the CSV header + one row so a silent column reorder is caught (a reordered column is a silent data corruption in a spreadsheet):

```dart
test('CSV lamb-shape header is frozen', () {
  expect(CsvExporter.lambHeader.join(','),
      'lamb_id,tag,sex,birth_weight_kg,status,birth_dam_tag,rearing_dam_tag,'
      'lambing_datetime_utc,lambing_time_provenance,…');
});
```

### 10.6 Export → import → export round-trip equality

**What to round-trip, and what not to.** JSON is the backup (§7.9: *"Full JSON backup for restore onto a new device"*). CSV and PDF are **reports** — CSV is deliberately lossy (three different row shapes) and must never be asserted for round-trip equality. Being explicit about which artifact is lossless is itself a design decision worth documenting.

**The envelope trap:** if the JSON payload contains `exportedAt`, byte equality is impossible. Separate `{envelope: {appVersion, schemaVersion, exportedAt}, payload: {...}}` and compare only `payload`.

**Property testing options, verified:**

| Package | Version | Publisher | Last published | Verdict |
|---|---|---|---|---|
| `glados` | **1.1.7** | *unverified uploader* | ~2 years | **adopt-with-care.** 50 likes but **30.5k weekly downloads** — widely used, just finished. Dev-only, no runtime footprint. Shrinking is the reason to keep it. |
| `flutter_glados` | 1.1.18 | leest.dev | ~13 months | **avoid.** 1 like, 56 total downloads. |

`glados` gives `Glados<T>().test(...)`, `Glados2<T,U>`, the `any` generator namespace, an `ExploreConfig` for run count/size growth, and — the part that matters — **shrinking to the smallest failing input**. ([pub.dev/packages/glados](https://pub.dev/packages/glados))

**Recommendation, honestly split:**
- Use `glados` for the **pure value** round-trips (a `Lambing`, a `Treatment`, an `EventTime`), where its built-in shrinking turns "fails on some 40-field record" into "fails when `birthWeightKg == 0.0`" for free.
- **Hand-roll the whole-flock generator.** You would have to write `Any` extensions for the eight entities anyway; a ~80-line seeded `FlockGenerator(seed)` gives you exact control over domain invariants (a lamb's `birthDam` must exist; a `rearingDam` must be a different ewe; treatment dates must fall inside the season) that a generic combinator library makes awkward. Print the seed on failure so any case reproduces exactly.

```dart
// test/policy/backup_round_trip_test.dart — §7.9
// Layer 1: pure values, with shrinking.
Glados(any.lambing).test('a lambing survives JSON round trip', (l) {
  expect(Lambing.fromJson(l.toJson()), l);
});

// Layer 2: the whole flock, seeded, deterministic, byte-exact.
void main() {
  for (var seed = 0; seed < 200; seed++) {
    test('flock backup round-trips byte-for-byte (seed $seed)', () async {
      final source = ShedDb.forTesting();
      final target = ShedDb.forTesting();
      addTearDown(source.close);
      addTearDown(target.close);

      await FlockGenerator(seed).populate(source);   // 8 entities, referentially valid

      final first  = await ExportService(source).jsonBackup();
      await ImportService(target).restore(first);
      final second = await ExportService(target).jsonBackup();

      expect(second.payload, first.payload,
          reason: 'reproduce with FlockGenerator($seed)');
      expect(jsonEncode(second.payload), jsonEncode(first.payload),
          reason: 'byte equality also pins key ordering');

      // Belt and braces: a semantic diff of the entity graph.
      expect(await snapshotGraph(target), await snapshotGraph(source));
    });
  }
}
```

Invariants the generator must respect (each of these, when violated, is a real importer bug you want to find):
- A lamb's `birthDam` exists and is an ewe in the export; `rearingDam` may differ (fostering, §7.3).
- Dead lambs have a `deathDate` ≥ their lambing datetime.
- Treatments reference an animal that exists, and carry a user-entered withdrawal period.
- Notes and photos reference existing animals; photo paths point at files in the media folder.
- At least one record with `TimeProvenance.editedByUser`, at least one with `autoCaptured`.
- Unicode in free-text notes (a shepherd will type `°`, `½`, an em-dash, and an emoji).
- An empty flock, and a flock at the free-tier cap of 15 ewes (§14).

Also test the **media folder**: JSON alone is not the backup if photos live outside it. Assert the backup bundle enumerates every referenced photo, and that restoring onto an empty device with the media folder present rehydrates every attachment.

---

## 11. Pitfalls

| # | Pitfall | Why it happens here | Mitigation |
|---|---|---|---|
| 1 | **The a11y gate passes vacuously.** | `meetsGuideline` evaluates an empty semantics tree unless `tester.ensureSemantics()` was called. Nothing warns you. | Add a canary: one test that asserts a deliberately 40×40 widget **fails** `shedBookTapTargetGuideline`. If the canary stops failing, the gate is dead. |
| 2 | **The 60 pt gate silently skips your most important button.** | `MinimumTapTargetGuideline` skips nodes touching the view boundary or a scrollable boundary (`_isAtBoundary`), and nodes with no tap/longPress semantics. A full-bleed bottom Save button is invisible to it. | Keep a ≥1 px (in practice, home-indicator) inset; add the geometric `ShedTap` size test (§6.4); ban raw `GestureDetector` outside `lib/ui/foundation`. |
| 3 | **Goldens render solid squares.** | Without `FontLoader`, Flutter uses 'Ahem'. The goldens then "pass" while proving nothing about legibility — the exact property this app needs. | `flutter_test_config.dart` loads real fonts (§7.3) + one golden whose review checklist item is "can you read the tag number". |
| 4 | **Goldens flake between your Mac and CI.** | Text rendering, anti-aliasing and font hinting differ across OS and across Flutter versions ([flutter#36667](https://github.com/flutter/flutter/issues/36667)). | One runner, one pinned Flutter version (`3.44.6`, not `stable`), goldens tagged and excluded elsewhere, plus a 0.5 % tolerant comparator. |
| 5 | **`INTERNET` "reappears" and the manifest test fails on every local run.** | Flutter intentionally adds `INTERNET` to the **debug and profile** manifests for hot reload; those have higher merge priority than `main`. | Gate the **release** APK only. Document why debug differs, in the test's `reason:`. |
| 6 | **The "no `package:http`" gate is unsatisfiable.** | `timezone` 0.11.1 declares `http: ^1.6.0` as a regular dependency; `flutter_local_notifications` pulls it in. | Gate at the **import** level in `lib/`, with an explicit lock-file assertion that `http` is `transitive` and a comment explaining why (§10.2 Layer B). |
| 7 | **Migration tests pass, user data vanishes.** | `migrateAndValidate` checks schema *shape*, not data. | Always pair with `testWithDataIntegrity`; add a destructive-operation ban (§3.5). |
| 8 | **Schema snapshot drifts out of sync with `schemaVersion`.** | Someone bumps the version and forgets `make-migrations`. | Count the files in `drift_schemas/` in a test; run `make-migrations` + `git diff --exit-code` in CI. |
| 9 | **CI fails on day one with "failed to load libsqlite3".** | `flutter test` runs on the host; `sqlite3_flutter_libs` is a plugin and is not applied. macOS ships sqlite3; Ubuntu runners do not have the dev package. | `apt-get install -y libsqlite3-dev` in the Linux job; assert a minimum sqlite version in a test. |
| 10 | **Drift stream tests leak timers in widget tests.** | Unsubscribing keeps the stream alive for one event-loop turn by default. | `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`. |
| 11 | **DST bugs pass every test because CI runs in UTC.** | UTC has no DST. Every date test passes. Users in Europe/London lose an hour in the middle of lambing. | Timezone is an injected `Location`, tests name it explicitly, plus one hostile-`TZ` job (§2.4). |
| 12 | **`add(Duration(days: n))` for calendar arithmetic.** | It's the obvious API and it's wrong across DST, per Dart's own docs. | A policy test banning `Duration(days:` in `lib/domain/time/`; use `DateTime(y, m, d + n)`. |
| 13 | **Wall-clock "15 second" test.** | It looks like it tests the promise. It tests CI load. | Interaction-budget widget tests (blocking) + device startup trace (reported). Never a timing assertion in `flutter test`. |
| 14 | **`pumpAndSettle()` hangs for 10 minutes.** | Any indefinitely repeating animation (a pulsing "recording" indicator on the voice-note button) never settles. | Use `pump(duration)` on those screens; give `pumpAndSettle` an explicit timeout; ban indefinite animations on the 3am screens anyway (they cost battery at 3am). |
| 15 | **Coverage gate drives the wrong tests.** | Policy/manifest/a11y tests contribute ~0 lines; `*.g.dart` inflates the denominator. | Report only; track `lib/domain/**` specifically (§9.5). |
| 16 | **Provenance derived instead of stored.** | `isEdited => updatedAt != createdAt` is tempting and breaks the moment anything else touches the row. | Store the enum; freeze its `name` values in a test (§10.5). |
| 17 | **Byte-equality round trips fail on `exportedAt`.** | The envelope timestamp changes every run. | Separate envelope from payload; compare payload only. |
| 18 | **The free-tier cap degrades the 3am path.** | §14 says it must not. A modal upsell on the entry screen is the easy accident. | A widget test at the 15-ewe cap: Quick Entry still saves; no modal barrier on the entry path. |
| 19 | **Contrast guideline false-positives on photo screens.** | It samples rendered pixels; a seeded photo makes results non-deterministic. | Seed solid-colour placeholder images in the harness for those screens. |
| 20 | **Alchemist/patrol adopted for the wrong reason.** | Both are good; both are the community default; neither fits a 12-screen single-theme offline app with one developer. | Re-read §7.2 / §8.2 before adopting. Revisit deliberately, not by drift. |

---

## 12. Rejected alternatives

| Rejected | Why it lost |
|---|---|
| **`golden_toolkit` 0.15.0** | **Discontinued** on pub.dev, last published ~3 years ago. Not a judgement call. |
| **`alchemist` 0.14.0 as the golden framework** | Healthy and well made, but its two headline features are wrong for this app: CI text-blocking destroys the legibility property the goldens exist to prove, and scenario grids across themes buy little in a single-theme app. It also adds a Flutter-version floor and has twice re-baselined everyone's goldens (0.10.0 padding, 0.13.0 anti-aliasing). Its genuinely useful `diffThreshold` is ~25 lines of `LocalFileComparator` subclass. *Adopt it the moment the local harness exceeds ~150 lines.* |
| **`patrol` 4.8.0** | Excellent, actively maintained (published 2 days ago), and the right answer for apps with heavy native-dialog flows. Here it costs a Gradle test target, an Xcode test target, `patrol_cli` in CI, and the loss of `flutter test` for those files — to automate four permission dialogs that appear once each. *Reconsider for v2 (Bluetooth EID, §13) or if permission flows regress.* |
| **`mockito` 5.7.0 as the primary double** | Requires `build_runner` codegen and generated mock files in review, for gateways that are 3–6 methods wide. Hand-written fakes read like the spec and double as real no-op implementations. mockito is not unhealthy — it just loses on ergonomics at this scale. |
| **`mocktail` as the primary double** | Kept as a dev dependency for ordering/non-invocation assertions, but rejected as the default: `registerFallbackValue` ceremony for every rich argument type, and `verify(() => …)` assertions that read nothing like §12. |
| **`package:checks` 0.3.1** | Its own pub.dev page says: *"Experimental — For production use cases, please use `package:test` and `package:matcher`."* Publisher `labs.dart.dev`, last published ~13 months ago. Not for a codebase whose test suite is the spec. |
| **`spot` 0.18.0** | Nice failure-timeline HTML, but ~14 months since publish, 110 likes, and it solves debuggability rather than correctness. Not worth the dependency for a suite this size. |
| **`flutter_glados` 1.1.18** | 1 like, 56 total downloads, ~13 months old. Abandonment risk with no upside over `glados` + a hand-rolled generator. |
| **`sqlite3_test` 0.2.0** | Solves a problem we design away: no SQL in this app produces a timestamp. It also cannot support WAL, which we want. Adopt only if that design rule is ever broken. |
| **`golden_screenshot` 11.0.1 in `test/`** | Genuinely useful — but for generating App Store / Play Store assets, not for regression gating. Keep it in `tool/`, out of the test suite. |
| **Mocking Drift / a repository interface introduced for testability** | In-memory SQLite is fast and tests the real SQL, including the constraints and triggers that a mock cannot express. A repository interface may earn its place architecturally; it does not earn it as a testing device. |
| **Firebase Test Lab** | Requires an account and an upload of the app. The product's entire positioning is "no account, nothing leaves the device" (§4). Using it would be ironic and pointless — there is no backend to integrate with. |
| **Golden tests for all 12 screens across the matrix** | 216 PNGs maintained by one person. It would be abandoned within a month, which is worse than never having it. The overflow + a11y matrices give most of the value at a fraction of the maintenance. |
| **A coverage percentage gate** | Optimises for the cheapest lines and starves the expensive, high-value tests. See §9.5. |
| **Wall-clock timing assertions in `flutter test`** | `flutter test` runs under `FakeAsync`; the number is meaningless and, on CI, noisy. Replaced by interaction budgets + device traces. |
| **Ambient `TZ=` as the primary DST strategy** | Makes tests depend on process environment and CI configuration. Demoted to a single leak-detector job; the primary strategy is an injected `tz.Location`. |
| **BDD frameworks (`bdd_widget_test`, `gherkin`)** | Their value is shared vocabulary across a team of non-engineers. There is one engineer and no product owner. `test/policy/` with spec-clause names achieves the readability without the indirection. |
| **`experimentalLeakTesting` on by default** | Flutter's own docs describe the parameter as experimental and not recommended outside the framework. Adds flake for a class of bug this app is unlikely to hit. |

---

## 13. How this serves the 3am test and the offline-only constraint

- **The 3am test becomes mechanical rather than aspirational.** The 60 pt rule, the 18 pt floor, the dark default, the no-scroll requirement and the tap budget are all asserted on every PR across 12 screens × 3 devices × 3 text scales × 2 bold settings. A regression is caught by CI, not by a shepherd at 3am on night eleven.
- **"Every write commits immediately" is proven, not asserted in a doc.** §3.6's reopen-the-file test is the closest a test suite can get to simulating a dead battery, and it is more deterministic than a process-kill integration test would be.
- **Offline-only is enforced in four independent places** (imports, dependencies, release manifest, runtime guard) — with an honest statement of where the enforcement is weakest (iOS native code). A single check would give false confidence.
- **The safety rules (§12) live in `test/policy/`, named after their clauses.** Someone reading the codebase in 2029 can open that directory and see the product's promises as executable statements, not as a paragraph in a markdown file that drifted.
- **No test in the suite requires a network, an account, a device farm or a cloud service.** The entire suite runs on a laptop on a plane, which is the same property the product sells. `apkanalyzer` is local; the goldens are local; the database is local; `glados` is a dev dependency with no runtime footprint.
- **The suite is sized for one person.** ~8 goldens, 4 integration journeys, a handful of matrices generated from tables, and a policy directory. The thing that kills solo-dev test suites is per-change maintenance cost, and every choice above (built-in goldens over a framework, integration_test over patrol, fakes over mocks, coverage as a report) was made to lower that number.

---

## Sources

Fetched 2026-07-27.

**Flutter / Dart official**
- https://docs.flutter.dev/testing/overview
- https://docs.flutter.dev/testing/integration-tests
- https://docs.flutter.dev/testing/plugins-in-tests
- https://docs.flutter.dev/cookbook/testing/widget/introduction
- https://docs.flutter.dev/cookbook/testing/integration/profiling
- https://docs.flutter.dev/reference/flutter-cli
- https://api.flutter.dev/flutter/flutter_test/
- https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html
- https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html
- https://api.flutter.dev/flutter/flutter_test/MinimumTextContrastGuideline-class.html
- https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html
- https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html
- https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html
- https://api.flutter.dev/flutter/flutter_test/AutomatedTestWidgetsFlutterBinding-class.html
- https://api.flutter.dev/flutter/flutter_test/TestFlutterView-class.html
- https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html
- https://api.flutter.dev/flutter/flutter_test/WidgetController/ensureSemantics.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html
- https://api.flutter.dev/flutter/services/FontLoader-class.html
- https://api.dart.dev/stable/dart-core/DateTime-class.html
- https://api.dart.dev/stable/dart-core/DateTime/add.html
- https://api.dart.dev/stable/dart-io/HttpOverrides-class.html
- https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_test/lib/src/accessibility.dart
- https://raw.githubusercontent.com/flutter/flutter/stable/packages/flutter_tools/lib/src/commands/test.dart
- https://github.com/flutter/flutter/blob/master/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md
- https://github.com/flutter/website/blob/main/src/testing/debugging.md
- https://github.com/flutter/flutter/issues/20789
- https://github.com/flutter/flutter/pull/22139
- https://github.com/flutter/flutter/issues/36667
- https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md

**Drift**
- https://drift.simonbinder.eu/testing/
- https://drift.simonbinder.eu/migrations/
- https://drift.simonbinder.eu/migrations/tests/
- https://drift.simonbinder.eu/migrations/step_by_step/
- https://drift.simonbinder.eu/migrations/exports/
- https://drift.simonbinder.eu/platforms/
- https://pub.dev/documentation/drift_dev/latest/api_migrations_native/SchemaVerifier-class.html
- https://pub.dev/documentation/drift_dev/latest/api_migrations_native/api_migrations_native-library.html
- https://pub.dev/documentation/drift_dev/latest/api_migrations_native/VerifySelf.html

**Android / Apple**
- https://developer.android.com/build/manage-manifests
- https://developer.android.com/tools/apkanalyzer

**Riverpod**
- https://riverpod.dev/docs/whats_new

**pub.dev package pages (versions read live on 2026-07-27)**
- https://pub.dev/packages/clock — 1.1.2
- https://pub.dev/documentation/clock/latest/clock/clock-library.html
- https://pub.dev/packages/fake_async — 1.3.3
- https://pub.dev/documentation/fake_async/latest/fake_async/FakeAsync-class.html
- https://pub.dev/packages/mocktail — 1.0.5 · https://pub.dev/packages/mocktail/changelog
- https://pub.dev/packages/mockito — 5.7.0
- https://pub.dev/packages/golden_toolkit — 0.15.0, DISCONTINUED
- https://pub.dev/packages/alchemist — 0.14.0 · https://pub.dev/packages/alchemist/changelog · https://pub.dev/packages/alchemist/versions/0.14.0 · https://github.com/Betterment/alchemist
- https://pub.dev/packages/spot — 0.18.0
- https://pub.dev/packages/golden_screenshot — 11.0.1
- https://pub.dev/packages/patrol — 4.8.0 · https://patrol.leancode.co/documentation
- https://pub.dev/packages/drift — 2.34.2
- https://pub.dev/packages/drift_dev — 2.34.5 · https://pub.dev/packages/drift_dev/changelog
- https://pub.dev/packages/drift_flutter — 0.3.1
- https://pub.dev/packages/sqlite3_test — 0.2.0
- https://pub.dev/packages/glados — 1.1.7
- https://pub.dev/packages/flutter_glados — 1.1.18
- https://pub.dev/packages/checks — 0.3.1 (experimental)
- https://pub.dev/packages/timezone — 0.11.1 · https://pub.dev/packages/timezone/versions/0.11.1 · https://raw.githubusercontent.com/srawlins/timezone/master/pubspec.yaml
- https://pub.dev/packages/flutter_local_notifications — 22.2.0
- https://pub.dev/packages/share_plus — 13.3.0
- https://pub.dev/packages/flutter_riverpod — 3.4.1
- https://pub.dev/packages/import_lint — 2.0.0
- https://pub.dev/packages/flutter_lints — 6.0.0
- https://pub.dev/packages/very_good_analysis — 10.3.0
- https://pub.dev/packages/test — 1.31.2

**Leads verified against primary sources (not used as evidence on their own)**
- https://verygood.ventures/blog/alchemist-golden-tests-tutorial/
- https://leancode.co/glossary/golden-tests-in-flutter
- https://github.com/kawa1214/import-lint
- https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/DETECT.md
