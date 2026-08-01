# N12-T05 — `test/support/` — `pumpApp`, `Device` and `seeds.dart`, and nothing else

| | |
|---|---|
| **Epic** | [N12 — The DI root, settings, the ticker and the harness](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 5 of 5 |
| **Depends on** | N12-T04 |
| **Commit** | one commit · `test(support): pumpApp, Device and the seed helpers` |

## 1. Why this task exists

`pumpApp` over `NativeDatabase.memory()`, the `Device` table, `freshSupportDir()`, and
`seeds.dart`'s `seedEwe` / `seedLambing` / `seedTreatment`. **No fakes and no `kPumpableVariants`** —
the seven fakes wrap gateways that do not exist yet and the variant map names screen constructors that
do not exist yet. Each grows with the epic that creates its subject. Critique defect S1.

This is the most-copied file in the project. Roughly 250 widget tests enter through `pumpApp`,
including all 252 overflow-matrix cells and all eight goldens, so every comment written here is read
more often than any comment in `lib/`.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4–§5 | the provider graph, the override rules and the harness |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3 | `SettingsRepository`'s ownership of `app_settings`, and every provider name |
| `docs/engineering/12-testing.md` | §4, §6.2 | the seven fakes and the variant table — and what may exist yet |
| `docs/engineering/12-testing.md` | §2.1 (`atFixed`) · §2.2 (the `Clock.fixed` trap and why `package:fake_async` is not a dependency) · §3.1 (`testDatabase()`, `closeStreamsSynchronously`, `addTearDown` inside the helper) · §3.2 (the host sqlite3 floor) · **§5.1** (`shedContainer` and `pumpApp` printed in full, and the six notes on the choices) · §5.2 (the two seeding routes) · **§5.3** (the closed twelve-file list) · §11.5 (seeds and fixtures) · §11.6 (`Future.delayed` in a test body is banned) | the harness, member for member |
| `docs/engineering/02-state-di-navigation.md` | §2.3 (`ProviderContainer.test` and `WidgetTester.container` are 3.x) · §5.2 (production has zero overrides) · §5.4 (**override leaves, never controllers**) | which providers may be overridden and which spelling to use |
| `docs/engineering/CONVENTIONS.md` | §1 (`test/` in the canonical tree) · §2.8 (`AppDatabase`'s constructor, `seedOnCreate`) · §2.11 (`ShedPaletteId`, `buildShedTheme`) · R57 (the test tree; `test/screens/` and `test/integration/` are banned) | where each file goes and what it is called |
| `docs/engineering/09-export-formats.md` | §7.3 | `restoreInto(freshSupportDir(), …)` — the one future caller of `freshSupportDir()` |
| `docs/engineering/06-design-system.md` | §2.1 · §4.1 | `buildShedTheme` / `resolvePalette` and the six palettes the harness selects from |
| `epics/00-PLAN-CRITIQUE.md` | **S1** · S3 | why the fakes and the variant map are not here, and why the fixture is not either |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the harness, the tiers and the override rules are its subject |
| `shed-riverpod-providers` | the override list, `shedContainer()`, and why `ProviderContainer.test` and `tester.container` do not exist here |

`seeds.dart` writes rows directly, so it must satisfy every `STRICT` type, `CHECK` and foreign key by
hand — that is `03 §5`'s, and the specific traps are in §5.3. The skill budget is two auto-firing.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/support/harness_test.dart`
- **Test** — `'pumpApp builds a widget against NativeDatabase.memory() with no production override'`
- **Why it is red today** — nothing pumps a widget; every later widget test would build its own container.

```bash
fvm flutter test test/support/harness_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it holds both halves of the sentence, because they fail differently:

- **"builds a widget against `NativeDatabase.memory()`"** — pump a probe `ConsumerWidget` that
  `ref.watch`es `settingsProvider` and renders the palette key it finds. Pumping succeeds, the tree
  settles, `tester.takeException()` is null, and the probe eventually renders `night` — which it can
  only do if the in-memory database was opened, migrated to `kSchemaVersion` and seeded by
  `seedFirstRun`. A harness that silently failed to override would throw
  `openAppDatabase()`'s under-test assertion instead.
- **"with no production override"** — a source-text sweep asserting `overrideWith` appears in
  `test/support/harness.dart` and nowhere under `lib/`. The asymmetry is the point: it is what
  `rp3.overrides`' `lib/`-only scope buys, and N03-T06 planted the case that proves the scope.

**Green.** The minimum code that passes, and nothing beyond it — the harness file with exactly these members, and a header comment listing which epic adds
which fake.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) only.** No schema, no domain, no data, no wiring, no controller, no UI, no ARB
string — this task adds nothing under `lib/` at all. Say so in the commit message: it is the one task
in the epic where the whole diff is test-tier.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **New.** `Device`, `testDatabase()`, `shedContainer()`, `atFixed()`, `freshSupportDir()`, the `PumpApp` extension — and the header ledger naming which epic adds which fake |
| 2 | `test/support/seeds.dart` | **New.** `seedEwe`, `seedLambing`, `seedTreatment`, and a header comment naming the six other writers `12 §5.3` closes the list with |
| 3 | `test/support/harness_test.dart` | **New.** The anchor plus the container, device, locale, palette, teardown and policy cases in §5.4 |
| 4 | `test/support/harness_dst_test.dart` | **New.** `@Tags(['uk-zone'])` with the `setUpAll` offset guard. `atFixed` pinning `appNow()` inside the repeated hour, and the freezing trap demonstrated deliberately |

`test/support/reads.dart`, `flock_generator.dart`, `tolerant_comparator.dart` and the seven fakes are
**not** in this diff. `12 §5.3` closes the folder at twelve files; this task lands two of them.

### 5.2 The signatures

`12 §5.1` prints `shedContainer` and `pumpApp` in full, with seven gateway overrides and seven optional
gateway parameters. **Six of the seven providers do not exist and the code as printed does not
compile.** What survives, and what must not be anticipated, is the whole content of this task.

```dart
// test/support/harness.dart
//
// The one way a test gets a database, a container and a pumped tree.
// 02 §5.4 owns the override RULES; 12 §5 owns this harness.
//
// WHAT IS DELIBERATELY ABSENT, AND WHERE IT LANDS (critique defect S1):
//
//   the seven gateway fakes (12 §4.2) — each lands in the epic that writes its
//   gateway, and extends shedContainer's override list in the SAME commit:
//     FakeMediaStore · FakeCameraService · FakeVoiceRecorder      N15
//     FakeShareService                                            N21
//     FakeNotificationScheduler                                   N24
//     FakeWakelockController                                      N29
//     FakePurchaseService (the store seam, R74)                   N30
//
//   kPumpableVariants (12 §6.2) — a Map<String, Widget Function()> over
//     RouteNames. N13 creates it with ONE entry (quick_entry) and every screen
//     epic adds one row. Four files iterate it, and none of them exist yet:
//     the 252-cell overflow matrix, semantics_gate_test, the geometric half of
//     tap_target_test, and the pixel-sampling group in contrast_test (N33).
//
//   restoreFixture / flock_400_3seasons.json (12 §5.2, critique defect S3) —
//     fixtures go through RestoreService, which is N23, and tool/seed.dart
//     writes them through the restore path in the same epic. Until then every
//     test seeds with the targeted helpers in seeds.dart. The switch is one
//     task, N23-T06, and it is the task that proves the fixture is loadable.
//
//   kSeedEwe / kSeedLambing / kSeedLamb / kSeedSeason (12 §5.3) — fixture ids.
//     They index into the fixture and are meaningless without it: N23.
//
// An optional `share:` parameter that overrides nothing is WORSE than no
// parameter, because it silently accepts a fake and the test passes for the
// wrong reason. Add each one with its provider, never before.

/// The devices we promise to work on. Smallest first — most bugs live there.
final class Device {
  const Device(this.name, this.size, this.dpr);
  final String name;
  final Size size;        // logical
  final double dpr;

  static const small   = Device('small',   Size(375, 667), 2.0);  // iPhone SE
  static const typical = Device('typical', Size(390, 844), 3.0);  // iPhone 15/16
  static const large   = Device('large',   Size(430, 932), 3.0);  // Pro Max
  static const all = <Device>[small, typical, large];
}

/// The only way a test gets a database. Real SQLite, in memory, migrated to
/// kSchemaVersion by the real MigrationStrategy (12 §3.1, decisions #111, #15).
Future<AppDatabase> testDatabase({bool seedOnCreate = true}) async {
  final db = AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    seedOnCreate: seedOnCreate,
  );
  addTearDown(db.close);
  return db;
}

/// ONE override today: the database. 2.6.1 spelling — there is no
/// ProviderContainer.test() and no WidgetTester.container (decision #18).
/// `...overrides` is spread LAST so a caller's override wins over the harness
/// default for the same provider. Do not reorder that list.
ProviderContainer shedContainer(
  AppDatabase db, {
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWith((ref) async => db),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);   // 2.6.1: you register this yourself
  return container;
}

/// Pin `appNow()` to a single instant. SINGLE-INSTANT ASSERTIONS ONLY —
/// `Clock.fixed` FREEZES now(), so nothing that measures elapsed duration may
/// run inside this callback. Wrap a pen-board test in it and every "hours since
/// penned" readout silently measures 0 h and passes (decision #113, 12 §2.2).
T atFixed<T>(DateTime instant, T Function() body) =>
    withClock(Clock.fixed(instant), body);

/// A temp directory torn down with the test — what `restoreInto` restores into
/// (09 §7.3). Nothing calls it until N23; it lands here because 12 §5.3 closes
/// the file list and this is harness.dart's member.
Directory freshSupportDir();

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget screen, {
    required AppDatabase db,
    Device device = Device.typical,
    double textScale = 1.0,
    bool boldText = false,
    ShedPaletteId palette = ShedPaletteId.night,
    bool highContrast = false,
    List<Override> overrides = const [],
    // Real phones have a notch and a home indicator. A zero-padding harness
    // hides the entire class of bug where a bottom-anchored 60 pt target is
    // under the home bar — which is every primary action in this app.
    EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  }) async { … }
}
```

`test/support/seeds.dart` — three writers, with the signatures `12 §10.1` and `12 §2.4` already call:

```dart
// test/support/seeds.dart
//
// Targeted seed helpers (12 §5.2): small, explicit, and the test reads as the
// scenario. These write rows DIRECTLY through drift, not through a repository —
// deliberately, because at N12 only SettingsRepository exists, and because a
// fixture is not a record. The other route is restoreFixture, which goes
// through RestoreService (N23).
//
// 12 §5.3 closes this file at ten writers. Three land here; each of the others
// lands with the epic that first needs it:
//   seedOpenOccupancy            N19   (pen board)
//   seedAutoLambing              N16   (lambing entry)
//   seedEditedLambing            N16   (the provenance quad)
//   seedContradictoryLambing     N06/N16 (the warning path, 12 §10.4)
//   armExportBanner              N21
//   setEntitlement · setEwesInCurrentSeason · restoreFixture   N23/N30

Future<EweId> seedEwe(AppDatabase db, {required String tag});

Future<LambingId> seedLambing(AppDatabase db, EweId ewe, {Instant? occurredAt});

/// `withdrawalDays` is REQUIRED and has no default value. Safety rule 1: no
/// code path in this project defaults a withdrawal period, and that includes
/// a test helper — a default here is a default that gets copied into a screen.
Future<TreatmentId> seedTreatment(
  AppDatabase db, {
  required String product,
  required int withdrawalDays,
});
```

### 5.3 The details that are easy to get wrong

- **`closeStreamsSynchronously: true` is mandatory** (decision #111). By default, unsubscribing from a
  drift query stream keeps it alive for one event-loop iteration, and the widget-test binding reports
  that as a leaked timer. Forget it and every stream-touching widget test in the project fails with a
  pending-timer error that names nothing useful — and it will be diagnosed as a bug in the screen.
- **`databaseProvider.overrideWith((ref) async => db)`, never `overrideWithValue(db)`.**
  `databaseProvider` is a `FutureProvider<AppDatabase>` and `Provider<AppDatabase>` is banned in `lib/`
  (`CONVENTIONS` §3.1); `overrideWithValue` on a `FutureProvider` takes an `AsyncValue`, not an
  `AppDatabase`, and the error message will not say so clearly.
- **`addTearDown` goes *inside* the helpers, not at each call site** — for both the database and the
  container. A leaked database is a leaked isolate, and 250 call sites will not each remember.
- **`ProviderContainer.test()` and `tester.container` are Riverpod 3.** Both are gate rows
  (`rp3.container_test` under `lib/`, `rp3.tester_container` under `test/`), and the second exists
  purely because this is the file somebody would write it in. Use `ProviderContainer(overrides: [...])`
  and `UncontrolledProviderScope(container: …, child: …)`.
- **Override leaves, never controllers** (`02 §5.4`). `databaseProvider` and — later — the seven
  gateways. **Never** a repository provider and never a screen controller: a fake controller tests the
  fake. A real in-memory SQLite database is a better fake than anything hand-written and cannot
  diverge from production.
- **`...overrides` is spread last, and something depends on it.** `12 §4.4` swaps one gateway for a
  `mocktail` double by passing an override rather than rebuilding the container, and that works only
  because the caller's entry comes after the harness default. Do not sort the list, do not deduplicate
  it, and do not move the spread.
- **`MediaQuery` wraps `MaterialApp`, not the other way round.** Inside-out and `MaterialApp` rebuilds
  the `MediaQueryData` from the view, discarding the `textScaler`, the `boldText` flag and the padding —
  and the overflow matrix then passes 252 cells at scale 1.0 while claiming to have tested 2.0.
- **`textScaler`, never `textScaleFactor`** (decision #99). The latter is deprecated, banned everywhere
  including the theme layer, and grepped by the gate.
- **`locale: const Locale('en', 'GB')`.** A harness that inherits the runner's locale renders
  `3/28/2026` on a US CI runner and passes. `d MMM y`, 24-hour, kg.
- **`view.physicalSize = device.size * device.dpr`, and `addTearDown(view.reset)`.** Forget the reset
  and the next test in the same file inherits a Pro Max viewport — which is exactly the size at which
  the overflow bugs do not reproduce.
- **`pumpAndSettle()` with no timeout is safe *only* because indefinite animations are banned on every
  screen.** If one ever ships, this call hangs for ten minutes and fails opaquely. Say so in a comment
  beside it, because the person debugging that hang will be reading this file.
- **The harness pins the theme; it does not read `themeProvider`.** `pumpApp` builds
  `buildShedTheme(resolvePalette(palette, highContrast: highContrast))` and passes it to `theme:`,
  `darkTheme:` and `themeMode: ThemeMode.dark`. Reading `themeProvider` instead would make every widget
  test depend on whatever `settingsProvider` emitted from the in-memory row, and a palette-specific
  golden could not be written at all.
- **`atFixed` is where the project's worst silent-pass lives.** `Clock.fixed` freezes `now()`, so an
  elapsed-time assertion inside it measures 0 h forever **and passes**. Put `12 §2.2`'s rule in the doc
  comment verbatim — *"in a widget test, either pin `now` or measure elapsed time, never both"* — and
  put the convention in the file too: every `atFixed` call in the widget tier carries a comment saying
  why it is a single-instant assertion.
- **In a widget test you install no clock at all.** The binding already runs the body inside a
  `FakeAsync` zone whose clock is installed as `package:clock`'s ambient clock, so
  `tester.pump(const Duration(hours: 25))` really moves `appNow()`. `package:fake_async` is **not** a
  declared dependency; importing it trips `depend_on_referenced_packages` and is an allowlist change.
- **`seeds.dart` writes rows directly and therefore must satisfy the schema by hand.**
  `foreign_keys = ON` (decision #28) means `seedLambing` needs a real `ewes` row; every table is
  `STRICT`; `uid` comes from `newUid()`; and any lambing row carrying the §12.5 provenance quad needs
  `captured_at`, `original_effective` and `time_source` set coherently. A seed that writes
  `time_source: 'auto'` with a non-null `original_effective` is a row the app could never have produced.
- **`seedTreatment`'s `withdrawalDays` has no default, and neither does anything downstream.** Safety
  rule 1 is *never default a withdrawal period*, and `12 §10.1` calls the helper with the value
  explicit for exactly this reason. A convenience default in a test helper is how a default reaches a
  screen.
- **`test/screens/` and `test/integration/` are banned** (R57). The widget tier mirrors
  `lib/features/`; the SDK requires the top-level `integration_test/` directory name.
- **Do not add a thirteenth file to `test/support/`.** `12 §5.3` closes the list, and it closes it with
  a reason: *"a helper used in an example and declared nowhere is how a suite acquires a thirteenth
  support file by accident."* Screen-driving helpers such as `selectEwe(tester, '412')` are private
  top-level functions in the single file that uses each — they encode a screen's tap sequence, which is
  `07-screens.md`'s to change.
- **The host must have sqlite3** (`12 §3.2`). macOS has it; `ubuntu-latest` needs
  `sudo apt-get install -y libsqlite3-dev`, which the `test` job already carries. If `harness_test.dart`
  is the first red thing on CI, read the job, not the harness.

### 5.4 The full test set

`test/support/harness_test.dart` — the harness testing itself, which is legitimate here precisely
because everything else in the project depends on it being right.

| Case | What it asserts |
|---|---|
| `'pumpApp builds a widget against NativeDatabase.memory() with no production override'` | **The anchor.** Both halves in §4: the probe renders a value that could only come from a migrated, seeded in-memory database; `overrideWith` appears in the harness and nowhere under `lib/` |
| `'testDatabase migrates to kSchemaVersion and seeds the first-run rows'` | One season, one `app_settings` row, one `entitlements` row, 40 `vocab_terms` rows and **zero** pens (`03`'s own `onCreate` contract) |
| `'testDatabase(seedOnCreate: false) leaves the tables empty'` | The other arm, needed by the reopen tests in T02 and by every migration test |
| `'a stream-touching widget test settles with no pending timer'` | The `closeStreamsSynchronously` property, expressed as the failure it prevents: pump a probe that watches `settingsProvider`, settle, and assert no timer complaint |
| `'a caller override wins over the harness default for the same provider'` | Pass a second `databaseProvider` override in `overrides:` and assert the caller's database is the one reached. The spread-last ordering, as behaviour |
| `'the container is disposed after the test'` | Capture the container, register a `ref.onDispose` on a probe provider, and assert it ran in a later test's `setUp`. Proves `addTearDown` is inside the helper |
| `'Device.all is three entries, smallest first'` | And each `size` and `dpr` matches `12 §5.1` exactly — the matrix's arithmetic depends on the count |
| `'pumpApp applies textScale, boldText and the notch padding'` | Read `MediaQuery.of` inside the pumped tree and compare all three. Catches the `MediaQuery`-inside-`MaterialApp` inversion |
| `'pumpApp renders in en_GB'` | `Localizations.localeOf` is `en_GB` inside the tree |
| `'pumpApp cannot produce a light theme'` | `Theme.of(context).brightness` is dark for all six `(palette, highContrast)` combinations |
| `'freshSupportDir returns a directory that is gone after the test'` | Capture the path, assert it exists inside the test and is deleted afterwards |
| `'seedEwe, seedLambing and seedTreatment produce readable rows'` | One case per helper: the row exists, its `uid` is non-empty, and `seedLambing`'s row references the seeded ewe |
| `'seedLambing fails loudly on an unseeded ewe'` | `foreign_keys = ON` is doing its job, and the helper does not paper over it |
| `'seedTreatment has no default withdrawalDays'` | Source text over `seeds.dart`. Safety rule 1 at the test tier |
| `'test/support/ holds exactly the files this task lands'` | Directory listing equals `{harness.dart, seeds.dart, harness_test.dart, harness_dst_test.dart}`. Fails the day somebody adds a fake early, which is the whole of critique defect S1 |
| `'kPumpableVariants is absent and the header comment names N13'` | Source text over `harness.dart` |
| `'no Fake* class is declared under test/support/'` | Source text. The seven fakes have named homes and this is the tripwire |

`test/support/harness_dst_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` and failing with the zone it found
(N04-T08's pattern):

| Case | What it asserts |
|---|---|
| `'atFixed pins appNow() to 01:30 inside the repeated hour'` | 25 October 2026: `appNow().local.hour == 1` and `.minute == 30` inside the callback, and the epoch millis are one of the two candidates |
| `'atFixed freezes appNow(), and this file is where that is proved rather than discovered'` | Two `appNow()` reads separated by a `pumpEventQueue()` inside one `atFixed` return the **same** instant. Deliberately asserting the trap, with a comment saying that this is the only place in the suite where freezing is the property under test |
| `'without atFixed, a pumped duration moves appNow()'` | `tester.pump(const Duration(hours: 25))` and the difference is 25 h. The binding's advancing clock, proved once, so no later epic re-derives it |
| `'a row seeded inside atFixed at 01:30 reads back as 01:30'` | `seedLambing(db, ewe, occurredAt: appNow())` inside the callback, then a plain read. Ties the harness's time helper to the converter T02 exercised |

## 6. Constraints that bind this task

- **The 3am test** — `Device.small` first, and the default `padding` is not zero. Both exist because a
  60 pt primary action under the home indicator is the bug this harness is shaped to expose.
- **Never default a withdrawal period** — `seedTreatment(withdrawalDays:)` is required. The rule
  reaches the test tier because helpers get copied.
- **Timestamps carry provenance** — a seeded row is a row the app could have produced, quad and all.
- **Honest reach** — no fake, no variant map, no fixture, no fixture id constants. Every absence is
  named in a comment with the epic that closes it.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'pumpApp builds a widget against NativeDatabase.memory() with no production override'` passes, and was seen to fail first for the stated reason
- [ ] `pumpApp` works with no gateway fakes, because no gateway exists
- [ ] the header comment names N15, N21, N24, N29 and N30 as the homes of the fakes
- [ ] `kPumpableVariants` is deliberately absent and the comment says N13 creates it
- [ ] seed helpers cover the three shapes `12 §10.1` already uses
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `shedContainer` declares **one** override and **zero** gateway parameters; `...overrides` is spread last and a test proves a caller's override wins
- [ ] `testDatabase()` passes `closeStreamsSynchronously: true` and registers `addTearDown(db.close)` inside the helper
- [ ] `overrideWithValue`, `ProviderContainer.test` and `tester.container` appear nowhere in `test/support/`
- [ ] `MediaQuery` wraps `MaterialApp`, and a test reads back `textScale`, `boldText` and the padding from inside the tree
- [ ] `atFixed`'s doc comment carries `12 §2.2`'s rule verbatim, and the DST file proves the freezing behaviour rather than leaving it to be discovered
- [ ] `seedTreatment` has no default `withdrawalDays`
- [ ] `test/support/` holds exactly four files, and a test asserts the listing
- [ ] the header comment names `restoreFixture`, the 400-ewe fixture and the four `kSeed*` id constants as N23's, so critique defect S3 is not rediscovered per screen
- [ ] `test/support/harness_dst_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is reported by `TZ=Europe/London fvm flutter test --tags uk-zone`

## 8. Verification

```bash
fvm flutter test test/support/harness_test.dart
TZ=Europe/London fvm flutter test test/support/harness_dst_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm the new file is counted
fvm flutter test                     # the whole suite still passes through the new harness
make check
make test
```

```bash
ls test/support/                                        # expect exactly four files
grep -rn "overrideWithValue" test/support/              # expect zero
grep -rn "ProviderContainer.test\|tester.container" test/  # expect zero
grep -rn "textScaleFactor" test/                        # expect zero
grep -rn "kPumpableVariants\|class Fake" test/support/  # expect zero
grep -n "withdrawalDays" test/support/seeds.dart        # expect `required int withdrawalDays`
grep -rn "overrideWith" lib/                            # expect zero — the asymmetry is the point
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(support): pumpApp, Device and the seed helpers`
