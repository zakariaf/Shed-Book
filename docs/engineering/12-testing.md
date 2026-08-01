# 12 — Testing

This document governs what gets tested, at which tier, with what harness, and what a failure looks like. It exists because three properties of this product are invisible when broken: arithmetic that is wrong by one hour, a migration that loses five seasons on a stranger's phone, and five safety promises that no type system enforces by accident. It owns `test/support/harness.dart`, `test/flutter_test_config.dart`, `dart_test.yaml`, the 252-cell overflow matrix, the eight goldens and the four integration journeys. It does **not** own the source-scanning gate — that is `tool/check_policy.dart` in [`01-architecture.md`](01-architecture.md) — and it does not own the CI job matrix, which is [`13-build-ci-release.md`](13-build-ci-release.md). Read it before you write your first test, and re-read §1.4 the next time you are tempted to express a rule as a `RegExp` inside a `test()`.

> **Decisions applied:** #4 `package:test` is never a direct dependency · #10 one source-scanning gate, not five · #15 no repository interfaces for testability · #17/#18/#19 `flutter_riverpod` 2.6.1 spellings and the Riverpod-3 ban list · #22 the double-tap `WriteController` and its one test per destructive action · #37/#38 migrations and migration-test scope · #39 the debug schema self-check · #46 one clock · #47 SQL-side time is banned, which is why `sqlite3_test` is not here · #52 two gates prove "never default a withdrawal", not four · #54 contradiction detection warns and cannot mutate · #70 the chart is golden-tested at three data shapes · #74 seed data written through the restore path · #90 no shed screen branches on `unlocked` · #100 the 60×60 tap floor and its second geometric gate · #103 commit-then-confirm, never optimistic UI · #110 the test shape is not a pyramid · #111 `NativeDatabase.memory()`, never a mock · #112 hand-written fakes for every gateway, `mocktail` for what it is good at · #113 the widget-test binding already has an *advancing* fake clock · #114 the overflow matrix · #115 every `meetsGuideline` run begins with `ensureSemantics()` · #116 ~8 goldens, one runner, one pinned Flutter version, not a per-PR gate · #117 `integration_test`, four journeys, reported not blocking · #118 property tests scoped to value round-trips and one seeded flock generator · #119 coverage is a report, never a gate · #120 tap budgets extended to foster and repeat-treatment · #121 CI shape and randomised ordering · #122 the offline gates, and the "no `http` in the lockfile" gate that must never be written · #126 CI gates size, not speed.
>
> **Owner rulings honoured (decision-record §7.0, settled 2026-07-27):** tag OCR and voice tag entry are cut from v1, so there is no speech fake and no OCR fake — the seven gateways in §4.2 are the whole seam list, and the voice *note* is tested through `VoiceRecorder`. Tags are unique among **active** animals only, so every fixture contains at least one culled ewe whose tag a live ewe reuses. UK/Ireland is first, so the ambiguous DST hour every time test targets is **01:00–01:59** and every date rendered to a human in a golden is `d MMM y`. The free tier is season-primary with the ewe cap secondary, never surfacing mid-entry and never between 22:00 and 06:00 — which is three assertions in §10.7, not a paragraph.

**Sibling documents:** [`01-architecture.md`](01-architecture.md) (the test tree, `tool/check_policy.dart`, `WriteOutcome`, `ShedFailure`), [`02-state-di-navigation.md`](02-state-di-navigation.md) (`shedContainer`, override rules, the Riverpod-3 ban list), [`03-data-model-and-schema.md`](03-data-model-and-schema.md) (the tables the DAO tier writes to), [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) (**the owner of the migration matrix, reproduced here only as a tier**), [`05-domain-correctness.md`](05-domain-correctness.md) (**the owner of DST-1…DST-5** and of every value type these tests assert on), [`06-design-system.md`](06-design-system.md) (**the owner of `test/design/`** — the guideline constant, the geometric gate, the contrast arithmetic), [`07-screens.md`](07-screens.md) (the 14 pumpable variants, the three tap budgets, the widget keys), [`08-platform-integration.md`](08-platform-integration.md) (**the owner of `NotificationScheduler`'s surface**, which §4.3's fake implements verbatim), [`09-export-formats.md`](09-export-formats.md) (**the owner of `writeBackup`, `BackupHeader` and the `tables` value the round trip compares**), [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) (semantics, headings, the platform flag truth table these gates assert against), [`11-monetization-and-store.md`](11-monetization-and-store.md) (`FreeTierPolicy`, and the **seventh** gateway `PurchaseService`), [`13-build-ci-release.md`](13-build-ci-release.md) (**the owner of the `Makefile` and the CI job matrix**, and of the offline gates G0–G5), [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md) (its §"CI already proves this" is this document's output, restated for a reviewer).

> **Naming: settled, not open.** [`CONVENTIONS.md`](CONVENTIONS.md) outranks this document on any name, path, type shape, signature or word. The test tree is R57's: `test/{domain,data,drift,design,features,policy,support,fixtures}/` plus a top-level `integration_test/`. `test/screens/`, `test/integration/`, `test/ui/`, `test/fakes/` and `test/golden/` are banned directories — the widget tier mirrors `lib/features/`, the fakes live in `test/support/`, and the goldens live beside the widget tests that produce them. The overflow matrix is **252 cells over 14 pumpable variants** (R58); decision #114's "216" predates two variants and is superseded.

---

## 1. The shape of the suite

### 1.1 Where the risk actually is

The generic pyramid is drawn for an app whose risk sits on a network or serialisation boundary. This app has no network boundary, no login, no server-shaped failure and no third-party API. Its risk is concentrated in three places that a pyramid does not describe:

1. **Arithmetic that is invisible when wrong.** A clear date one day early puts meat in the food chain. "Hours since penned" one hour out across the last Sunday in March moves a ewe out of a pen too early, in the middle of the only three weeks of the year the app matters. Neither bug is visible on a screen. These are pure functions with no I/O, and they earn *exhaustive* table-driven coverage that a normal app could not justify.
2. **A database that is the only copy of the data.** No sync, no cloud, no support channel (spec §4, §13). A bad migration in v1.4 destroys five seasons with no recovery path. Migration testing here is not hygiene; it is the highest-value category in the project, and [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §3 owns it in full.
3. **Five product promises that are not code properties.** "Never default a withdrawal period" is not something a compiler enforces by accident. They live in `test/policy/`, named after the property rather than the file, and that directory should be the first thing a new reader opens.

Against that, the screens are comparatively low-risk: twelve of them plus note search, one theme family, one layout language, no responsive breakpoints beyond three phone sizes, no A/B variants, no localisation beyond `en`. Heavy per-screen behavioural testing would be the wrong investment; a wide, shallow, table-driven layer that mechanises the 3am test is the right one.

### 1.2 The tiers

| Tier | Directory | What belongs in it | Rough size | Runs |
|---|---|---|---|---|
| **Domain** | `test/domain/` | Every pure function in `lib/domain/`: withdrawal arithmetic, `Instant`/`LocalDate`/`PartialDate`, `RecordedTime`, grams and milli-°C, `rankTagMatches`, `timeSincePenned`, the eight statistics and their `notComputableReason` arms, `expectedLambCount`, `FreeTierPolicy.decide`, every `checkX` validator. **The thickest tier.** | Hundreds of cases, mostly table-driven | Every push, twice (§2.5) |
| **Zone-pinned domain** | `test/domain/uk_zone/` | DST-1 … DST-5, `@Tags(['uk-zone'])`. Fails loudly rather than skipping when the zone is wrong. Owned by [`05-domain-correctness.md`](05-domain-correctness.md) §2.9 | 5 files' worth | Every push, under `TZ=Europe/London` |
| **Data** | `test/data/` | Repositories and named queries against `NativeDatabase.memory()`. Constraints, triggers, partial unique indexes, `watch()` streams, `WriteOutcome` mapping | ~2–3 per repository verb | Every push |
| **Migration** | `test/drift/` | The from→to matrix, the N-1→N data-integrity test, the downgrade test, the snapshot-count test. Generated helpers in `test/drift/generated/`, never hand-edited | N²/2 sub-second tests | Every push |
| **Design** | `test/design/` | `wcag.dart` (the formula), `semantics_gate_test.dart` (the tree-walking guidelines + headings), `tap_target_test.dart` (the geometric gate + the canary), `contrast_test.dart` (the six palettes + the pixel-sampling run), `reduce_motion_test.dart`. Assertions owned by [`06-design-system.md`](06-design-system.md) and [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md); the tables they iterate, and the split between the files, are owned here (§7.4) | 84 + 84 + 42 pumped runs, 6 palettes | Every push |
| **Widget** | `test/features/` | The 252-cell overflow matrix, the reachability assertions, the three tap budgets, the no-monetization test, the double-tap tests, the eight goldens (tagged, excluded by default) | ~300 cells + ~20 named tests | Every push except goldens |
| **Policy** | `test/policy/` | Spec §12 and §7.9 as executable assertions about *behaviour and artefacts* | ~10 files | Every push |
| **Integration** | `integration_test/` | Four journeys on a real device against a real file | 4 files | Nightly, reported |

Every one of these imports `package:flutter_test/flutter_test.dart` — **including the pure-domain tests**. `package:test` is never a direct dependency (decision #4): it caps `analyzer <13.0.0`, which breaks `drift_dev ≥ 2.34.1`, and `flutter_test` does not depend on it. Any file in `test/` that says `import 'package:test/test.dart';` is a defect, and it is the first thing to check when `flutter pub get` reddens.

### 1.3 What is deliberately not tested

Say these out loud, because an untested area that nobody decided not to test is just an oversight wearing a plan's clothes.

| Not tested | Why | What covers it instead |
|---|---|---|
| Generated code — `*.g.dart`, `*.drift.dart`, `schema_versions.dart`, `test/drift/generated/` | It tracks the pinned `drift_dev`; testing it tests the generator | The codegen-freshness diff (§3.4) proves it matches the source |
| PDF byte output | A byte assertion on a 60-page document is a re-baselining chore that proves nothing | Page count > 0, and `Disclaimers.exportFooter` present in the text layer ([`09-export-formats.md`](09-export-formats.md)) |
| Every Settings toggle individually | Twelve near-identical tests | One parameterised test: each setting persists and re-reads |
| Wall-clock timing | `flutter test` runs under `FakeAsync`; the number is meaningless, and on CI it is load noise | Tap budgets (§10.1) + a device startup trace (decision #126, doc 13) |
| Nine of the thirteen screens as goldens | Eight images maintained by one person is the ceiling; 13 × the matrix is 234 PNGs that would be deleted within a month | The overflow matrix and the a11y gates, which never need re-baselining |
| `MediaStore`'s real disk writes in the widget tier | The widget tier has no filesystem story worth the setup | The fake in `test/support/`, plus journey 4 on a real device |
| Anything needing a network, an account or a device farm | It would contradict the product | — |
| App *speed* in CI | Profile mode is disabled on emulators; any hosted-runner number is noise (decision #126) | Two real devices per release, recorded in `docs/perf/measurements.md` |

### 1.4 What is a gate, and what is a test

This is the distinction most likely to be got wrong, and getting it wrong is how a solo developer ends up with five source-scanning suites and a false-positive habit.

- **Source scans are the gate.** `tool/check_policy.dart` — one script, one rule table, one allowlist, one exit code (decision #10). Layer rules, banned imports, `DateTime.now(`, raw colour literals, banned Riverpod-3 spellings, `save\w*\(`, the re-typed disclaimer, currency literals, and `ContentPolicy.bannedInUserFacingText` — which is where spec §12.2 and §12.3 are proved (§10's map). It has zero dependencies, runs in under a second, and needs no Flutter.
- **Behaviour and artefacts are tests.** Does the schema JSON carry a default? Does the record change when a warning fires? Does provenance survive a reopen? Does the payload round-trip?

The rule: **if the assertion can be made by reading source text, it belongs in `tool/check_policy.dart`, not in `test/policy/`.** A `RegExp` inside a `test()` is a policy rule that escaped its home; it will acquire its own allowlist, drift out of sync with the real one, and eventually be weakened by whoever is unlucky enough to hit its false positive. Decision #52 is the worked example: note 04 proposed four independent proofs that no withdrawal period is defaulted, one of which was a numeric-literal heuristic near the word "withdrawal". It fires on `CHECK` constraints and on test fixtures. Two gates ship (§10.3); the heuristic does not.

---

## 2. Time in tests

Every one of the five safety rules touches time, so this section is the highest-leverage part of the strategy.

### 2.1 One clock, and the three ways of installing it

There is exactly one wall-clock reader in the app: `Instant appNow()` in `lib/core/time/app_clock.dart`, which wraps `package:clock`'s ambient `clock` (decision #46, R23). There is no `Clock` interface, no `SystemClock`, no `clockProvider` — two clock seams are worse than none, because a test that fakes one does not fake the other.

| Where | How you install time | Notes |
|---|---|---|
| Pure domain test | **You do not.** Pass `Instant now` as a parameter | `timeSincePenned(enteredAt, now)`, `computeWithdrawalStatus(administeredAt:, period:)` — most domain functions never touch a clock at all, by design (R24) |
| Domain/data test that must pin an instant | `withClock(Clock.fixed(...), body)` | Single-instant assertions only. See §2.2 |
| Widget test | **You do not.** The binding already installs an advancing fake clock | See §2.2 |
| Any test at all | Never `DateTime.now()` | The gate fails the build on it outside `app_clock.dart` |

The one helper, in the harness, exists so that the constraint travels with the call site:

```dart
// test/support/harness.dart
/// Pin `appNow()` to a single instant. SINGLE-INSTANT ASSERTIONS ONLY —
/// `Clock.fixed` freezes time, so nothing that measures elapsed duration
/// may run inside this callback. See 12-testing.md §2.2.
T atFixed<T>(DateTime instant, T Function() body) =>
    withClock(Clock.fixed(instant), body);
```

### 2.2 `fakeAsync`, and the trap decision #113 exists to close

`AutomatedTestWidgetsFlutterBinding` runs every `testWidgets` body inside a `FakeAsync` zone and installs that zone's clock as `package:clock`'s ambient clock — verified in `packages/flutter_test/lib/src/binding.dart`, which does `_clock = fakeAsync.getClock(DateTime.utc(2015))`, and in `FakeAsync.run`, which installs the zone clock. Two consequences, and they point in opposite directions:

1. **`tester.pump(const Duration(hours: 25))` really does move `appNow()`.** Widget code that reads the clock is deterministic for free. This is the recipe for anything that measures elapsed time.
2. **`withClock(Clock.fixed(...))` around a widget test freezes it.** `Clock.fixed` returns a clock whose `now()` never moves. Inside that wrapper `pump(Duration)` still fires timers, but every "hours since penned" and every withdrawal countdown stays at its initial value forever, and the test silently measures 0 h and passes.

So:

> **In a widget test, either pin `now` or measure elapsed time. Never both.**
>
> - *"Does the tile read `9h`?"* — a single-instant assertion. Pin `now` with `atFixed` and offset the **seed data** to the instant you want to be 9 h earlier.
> - *"Does the tile flip from `23h` to `24h`?"* — an elapsed-time assertion. Pin nothing. Seed `entered_at` at `appNow().plus(const Duration(hours: -23, minutes: -59))` and call `tester.pump(const Duration(minutes: 1))`.

**`fakeAsync` in this project means the binding's.** You drive it with `tester.pump`, never by constructing a `FakeAsync` yourself. `package:fake_async` is **not** a declared dependency and §5 of the decision record does not carry it; importing it directly trips `depend_on_referenced_packages` and is an allowlist change, not a convenience. This is not a hardship: the only timer-driven code in the app is `minuteTickProvider` (`Future.delayed`, boundary-aligned, R25), the 500 ms `reconcile()` debounce and the 200 ms note-search debounce, and all three are reachable from a widget test.

### 2.3 The ambiguous hour — 01:00–01:59

The owner has settled the region as UK/Ireland, so the ambiguous hour and the nonexistent hour are both **01:00–01:59** (decision-record §7.0). UK clocks go forward at 01:00 GMT (01:00–01:59 never happens) and back at 02:00 BST (01:00–01:59 happens twice). In 2026 those dates are **29 March** and **25 October**. Late March is peak lambing.

[`05-domain-correctness.md`](05-domain-correctness.md) §2.9 owns the five domain tests, DST-1 to DST-5, and they are ship-blocking. The two this document's scope turns on are reproduced here because they are the pair a reader of *this* file needs in front of them, and because §2.4 extends each of them up a tier.

```dart
// test/domain/uk_zone/dst_test.dart — owned by 05-domain-correctness.md §2.9
@Tags(['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
// ... domain imports

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead.
    expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1),
        reason: 'Run this file with TZ=Europe/London');
  });

  test('DST-1: hours since penned is ABSOLUTE across the spring-forward', () {
    final penned = Instant.fromDateTime(DateTime(2026, 3, 28, 22, 0)); // Sat 22:00 GMT
    final now    = Instant.fromDateTime(DateTime(2026, 3, 29, 8, 0));  // Sun 08:00 BST
    expect(timeSincePenned(penned, now), const Duration(hours: 9));
    // The wall clock advanced 10 h. Nine is correct: it is a welfare question
    // about physical hours in a 4x4 pen, and it errs toward turning out later.
  });

  test('DST-2: a lambing recorded in the ambiguous hour round-trips its wall time', () {
    // 01:30 on 25 Oct 2026 happens twice. Dart picks one instant.
    final typed = DateTime(2026, 10, 25, 1, 30);
    final i = Instant.fromDateTime(typed);

    expect(i.local.hour, 1);
    expect(i.local.minute, 30);
    expect(LocalDate.of(i), LocalDate(2026, 10, 25));

    // Exactly one of the two candidate instants, and the export says which.
    final bstCandidate = DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch;
    final gmtCandidate = DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch;
    expect(i.epochMillis, anyOf(bstCandidate, gmtCandidate));

    // No warning: the displayed time still matches what the user typed, so
    // nothing was silently corrected from the shepherd's point of view.
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });
}
```

### 2.4 The two tiers above the domain tests

DST-1 and DST-2 prove the arithmetic. They cannot prove that the *stored* value survives SQLite, or that the *rendered* value on a pen tile is the one the arithmetic produced. Those are this document's, and both are also `@Tags(['uk-zone'])` because they depend on the process zone.

**Data tier — the ambiguous hour survives a store, a reopen and a provenance round trip.**

```dart
// test/data/lambing_ambiguous_hour_test.dart
@Tags(['uk-zone'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ... shed_book imports

void main() {
  test('a lambing recorded AT 01:30 in the repeated hour reads back as 01:30 after a reopen',
      () async {
    final dir = Directory.systemTemp.createTempSync('shed_ambiguous');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/shed.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    final repo = LambingRepository(db, FakeNotificationScheduler(), FakeMediaStore());
    final ewe = await seedEwe(db, tag: '412');

    // The shepherd is in the shed at 01:30 on 25 Oct 2026 — an hour that
    // happens twice. `appNow()` is what the write captures; nothing is typed.
    final lambing = await atFixed(
        DateTime(2026, 10, 25, 1, 30), () => repo.beginLambing(ewe));
    await db.close();

    // Cold start, as after a battery death.
    db = AppDatabase(NativeDatabase(file), seedOnCreate: false);
    addTearDown(db.close);
    final row = await readLambing(db, lambing);

    expect(row.occurredAt.local.hour, 1);
    expect(row.occurredAt.local.minute, 30);
    expect(row.localDate, LocalDate(2026, 10, 25));
    expect(row.timeSource, TimeSource.autoCaptured);
  });

  test('correcting a time INTO the repeated hour keeps the original and says so',
      () async {
    final db = await testDatabase();
    final repo = LambingRepository(db, FakeNotificationScheduler(), FakeMediaStore());
    final ewe = await seedEwe(db, tag: '412');

    final lambing = await atFixed(
        DateTime(2026, 10, 25, 3, 0), () => repo.beginLambing(ewe));
    await atFixed(
        DateTime(2026, 10, 25, 3, 5),
        () => repo.correctOccurredAt(
            lambing, Instant.fromDateTime(DateTime(2026, 10, 25, 1, 30))));

    final row = await readLambing(db, lambing);
    expect(row.occurredAt.local.hour, 1);
    expect(row.timeSource, TimeSource.userEdited);
    expect(row.originalEffective!.local, DateTime(2026, 10, 25, 3, 0));
    expect(row.localDate, LocalDate(2026, 10, 25),
        reason: 'the denormalised civil date moves with the corrected instant');
  });
}
```

Three things these prove that nothing else does: that `InstantConverter` round-trips an epoch-millis value whose *local* rendering is ambiguous; that the provenance quad survives the file and a reopen; and that `lambings.local_date` — the denormalised civil date the lambing-spread histogram groups by (decision #59) — lands on 25 October and not 24. A one-day error there is a bar in the wrong column of the one chart in the app.

**Widget tier — the pen tile across the spring-forward.** This is the single-instant form, because a transition cannot be crossed by `pump` from a start the binding chose.

```dart
// test/features/pen_board_dst_test.dart
@Tags(['uk-zone'])
library;

void main() {
  testWidgets('a ewe penned at 22:00 GMT reads 9 h at 08:00 BST, not 10', (tester) async {
    final db = await testDatabase();
    await seedOpenOccupancy(db,
        pen: const PenId(3), ewe: const EweId(1),
        enteredAt: Instant.fromDateTime(DateTime(2026, 3, 28, 22, 0)));

    await atFixed(DateTime(2026, 3, 29, 8, 0), () async {
      await tester.pumpApp(const PenBoardScreen(), db: db);
      // 07 §9.3 renders the tile as ONE string — `9h`, `26h · READY` — not as
      // separate Texts, and with no space before the `h`. Match its format.
      expect(find.textContaining('9h'), findsOneWidget);
      expect(find.textContaining('10h'), findsNothing);
    });
  });

  testWidgets('the tile crosses the turn-out threshold on a tick, not on a rebuild',
      (tester) async {
    final db = await testDatabase();
    // ELAPSED-TIME assertion: pin nothing, offset the seed instead (§2.2).
    await seedOpenOccupancy(db,
        pen: const PenId(3), ewe: const EweId(1),
        enteredAt: appNow().plus(const Duration(hours: -23, minutes: -59)));

    await tester.pumpApp(const PenBoardScreen(), db: db);
    expect(find.textContaining('READY'), findsNothing);

    await tester.pump(const Duration(minutes: 1));   // one minuteTickProvider boundary
    // The default turn_out_threshold_hours is 24 (07 §9.3); the seed is one
    // minute short of it, so exactly one tick flips the tile.
    expect(find.textContaining('READY'), findsOneWidget);
  });
}
```

The second test is the one that would silently pass at 0 h forever if it were wrapped in `atFixed`. Put a comment saying so above every `atFixed` call in the widget tier; it is the cheapest possible defence against the next person copying the wrong recipe.

### 2.5 Running them: three commands, not two

```bash
# 1. The target zone, for every file that pins one — wherever it lives.
TZ=Europe/London   flutter test --tags uk-zone

# 2. The whole domain suite in the target zone (05-domain-correctness.md §2.9).
TZ=Europe/London   flutter test test/domain

# 3. The hostile zone, with the zone-pinned files excluded.
TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone
```

`Pacific/Chatham` is UTC+12:45 with its own DST; it catches any code that assumes a whole-hour offset or a same-day UTC/local mapping. **If a test's result depends on `TZ`, something is reading ambient local time that should not be.**

> **Two properties this document requires of [`13-build-ci-release.md`](13-build-ci-release.md) §4.3, both already satisfied as 13 is published.** They are stated rather than assumed, because both are one word wide and both are load-bearing.
>
> 1. The target-zone step must be **unscoped**: `TZ=Europe/London flutter test --tags uk-zone`, with no `test/domain` path. The tag selects the files; a path only removes some of them, and §2.4 puts two zone-pinned files in `test/data/` and `test/features/`. Scoped, those two run in whatever zone the runner has — UTC on `ubuntu-latest`, where a spring-forward test passes because there is no spring forward. 13 §4.3 carries the unscoped form and says why in a comment.
> 2. The hostile-zone step must carry **`--exclude-tags uk-zone`**. `test/domain/uk_zone/` asserts its own offset in `setUpAll` and fails loudly rather than skipping, which is correct (a skipped safety test is a broken safety test) — and under `Pacific/Chatham` that assertion is false, so the step without the exclusion is red on the first run. 13 §4.3 carries it; so does `05-domain-correctness.md` §2.9.
>
> If either ever regresses, it regresses silently into a green run. §14 keeps them as standing properties, not as pending edits.

Also run all three locally before you push a change to anything in `lib/domain/time/` or `lib/domain/withdrawal/`. They take seconds, and the failure they catch takes a season to notice.

### 2.6 Anti-patterns

| Anti-pattern | What happens | Caught by |
|---|---|---|
| `DateTime.now()` in a test | The test depends on the day it runs | `tool/check_policy.dart` (`time.dart_clock`) scans `test/` too |
| `withClock(Clock.fixed(...))` around an elapsed-time widget test | Silently measures 0 h and passes | Review; the comment convention above; the §2.4 pair as the worked example |
| `Future.delayed` in a test body | Real wall time inside `FakeAsync`; hangs or flakes | Banned outright (§11.6) |
| Skipping a zone-pinned test when `TZ` is wrong | A safety test that never runs | `setUpAll` asserts the offset and fails |
| Asserting an absolute wall-clock value in a zone-agnostic file | Fails under `Pacific/Chatham` | Command 3 |
| `sqlite3_test` and its VFS | Solves SQL-side time, which is banned (#47), and cannot support WAL, which we need | Not a dependency |

---

## 3. The drift harness

### 3.1 One way to build a test database

```dart
// test/support/harness.dart
/// The only way a test gets a database. Real SQLite, in memory, migrated
/// to kSchemaVersion by the real MigrationStrategy.
Future<AppDatabase> testDatabase({bool seedOnCreate = true}) async {
  final db = AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    seedOnCreate: seedOnCreate,
  );
  addTearDown(db.close);
  return db;
}
```

Three details, each of which has its own failure mode:

- **`closeStreamsSynchronously: true` is mandatory** (decision #111). By default, unsubscribing from a drift query stream keeps it alive for one event-loop iteration, and the widget-test binding reports that as a leaked timer. Forget it and every stream-touching widget test fails with a pending-timer error that names nothing useful.
- **`NativeDatabase.memory()`, never a mock** (decision #111, #15). Real SQLite runs the real `STRICT` typing, the real foreign keys, the real partial unique index on `pen_occupancies`, the real `BEFORE UPDATE` trigger that makes `birth_dam` immutable, and the real FTS5 triggers. A mock expresses none of those, so a DAO test against a mock tests the mock. This is also why there are no repository interfaces: a real in-memory database is a better fake than any you could write, and it cannot diverge from production.
- **`addTearDown(db.close)` inside the helper**, not at each call site. A leaked database is a leaked isolate.

### 3.2 The host sqlite3 requirement

`flutter test` runs on the **host**, not on a device, so `sqlite3_flutter_libs` — a plugin, and an EOL no-op shim in any case — is not applied. sqlite3 must be present on the host:

| Host | What is needed |
|---|---|
| macOS arm64 (the dev machine) | Present by default |
| `ubuntu-latest` (CI) | `sudo apt-get install -y libsqlite3-dev` — **the one line between a working and a red CI on day one** |
| Windows | `sqlite3.dll` on `PATH`. Not a supported dev platform for this project |

The host's sqlite3 version differs from the bundled one the app ships (decision #25). Pin a floor so a Mac-passes/CI-fails split surfaces as a named assertion rather than a mystery:

```dart
// test/data/host_sqlite_version_test.dart
test('the host sqlite is new enough for STRICT and FTS5', () {
  expect(sqlite3.version.versionNumber, greaterThanOrEqualTo(3041000)); // 3.41.0
});
```

`STRICT` needs ≥ 3.37.0; 3.41.0 is the floor this project asserts, because it clears that with headroom and because a floor stated as a number is a floor CI can prove. **Which sqlite3 a given runner image actually ships is unverified here and must be checked once, on the image in use** — an older LTS image can ship a build below this floor, and the symptom is a red `test/data/host_sqlite_version_test.dart` on day one rather than a mystery. If the assertion fails, the fix is the runner image, never the assertion: lowering it to whatever the runner happens to have is how `STRICT` stops being tested.

### 3.3 Repository tests

No mocks, no interfaces, real SQL. Assert the things a mock cannot see: the constraint, the trigger, the index, the `WriteOutcome` variant.

```dart
// test/data/pen_repository_test.dart
test('the database physically refuses two ewes in one pen', () async {
  final db = await testDatabase();
  final repo = PenRepository(db);

  final first = await repo.enterPen(const PenId(3), ewe: const EweId(1));
  expect(first, isA<WriteCommitted>());

  final second = await repo.enterPen(const PenId(3), ewe: const EweId(2));
  expect(second, isA<WriteFailed>(),
      reason: 'the partial unique index WHERE exited_at IS NULL is the guard, '
              'not a Dart check the next code path can forget');
});

test('exitPen closes the occupancy and preserves entered_at forever', () async {
  final db = await testDatabase();
  final repo = PenRepository(db);
  await atFixed(DateTime(2026, 3, 27, 22, 0),
      () => repo.enterPen(const PenId(3), ewe: const EweId(1)));

  final occupancy = await repo.openOccupancyFor(const PenId(3));
  await atFixed(DateTime(2026, 3, 29, 6, 0),
      () => repo.exitPen(occupancy.id, reason: PenExitReason.turnedOut));

  final row = await (db.select(db.penOccupancies)
        ..where((t) => t.id.equals(occupancy.id.value)))
      .getSingle();
  expect(row.enteredAt.local, DateTime(2026, 3, 27, 22, 0));
  expect(row.exitedAt, isNotNull);
  expect(row.exitReason, 'turned_out');
});
```

Stream tests use drift's documented pattern, `expectLater(stream, emitsInOrder([...]))`. Do **not** assert on two drift streams combined: `combineLatest` over drift streams is banned in `lib/` (decision #12) and asserting it in a test would legitimise it.

### 3.4 Migration testing

[`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §3 owns this in full, including the FTS5-shadow-table question that is still unverified. What this document owns is that it is a **tier that runs on every push**, and the three facts a test author needs.

**The commands, verbatim.** They come from `build.yaml` (`databases: shed_book: lib/core/db/database.dart`, `schema_dir: drift_schemas/`, `test_dir: test/drift/`), so the paths below and `build.yaml` must agree or the artefacts land in the wrong directory:

```bash
# The wrapper you actually run after bumping kSchemaVersion.
dart run drift_dev make-migrations

# The three underlying commands, when you need to understand what it did.
dart run drift_dev schema dump lib/core/db/database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/db/schema_versions.dart
dart run drift_dev schema generate --data-classes --companions \
    drift_schemas/ test/drift/generated/
```

Nothing under `drift_schemas/` or `test/drift/generated/` is ever hand-edited.

**The full from→to matrix, not only the latest hop** (decision #37, #38). A shepherd who bought the app in February 2026 and reopens it in February 2029 runs 1→2→3→…→N in one unattended launch with no backup. `stepByStep` composes edges, but `migrateAndValidate` validates the *terminus*, not the path — only running the real composition proves the real composition lands where you think. The matrix costs one nested loop and N²/2 sub-second tests; at N = 8 that is 28 tests.

```dart
// test/drift/migration_matrix_test.dart — 04-migrations-media-backup-restore.md §3.2
@Tags(['migration'])
library;

import 'package:drift_dev/api/migrations_native.dart';   // NOT api/migrations.dart
import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (var from = 1; from < kSchemaVersion; from++) {
    for (var to = from + 1; to <= kSchemaVersion; to++) {
      test('migrates v$from -> v$to', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase(connection, seedOnCreate: false);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, to);

        final violations = await db.customSelect('PRAGMA foreign_key_check;').get();
        expect(violations, isEmpty, reason: 'FK violations after v$from -> v$to');
        final quick = await db.customSelect('PRAGMA quick_check;').getSingle();
        expect(quick.data.values.first, 'ok');
      });
    }
  }

  test('drift_schemas/ holds exactly kSchemaVersion snapshots', () {
    final dumps = Directory('drift_schemas')
        .listSync()
        .where((f) => f.path.endsWith('.json'))
        .length;
    expect(dumps, kSchemaVersion,
        reason: 'run `dart run drift_dev make-migrations` after bumping kSchemaVersion');
  });
}
```

Data-integrity coverage is **scoped, not universal** (decision #38): the N-1→N pair, plus any step containing `alterTable`. Quadratic data-integrity tests at v1 are busywork; the from→to *schema* matrix is the high-value half. When you do write one, read `testWithDataIntegrity`'s signature out of `test/drift/generated/schema.dart` first — it is generated code that tracks the pinned `drift_dev`, and a signature copied from a document or a blog post will not compile.

**The CI no-diff freshness check.** This is the single most valuable line of CI in the project, because it proves the committed snapshot describes the committed schema — the assumption every other migration test rests on:

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations
git diff --exit-code -- \
    lib/core/db/ drift_schemas/ test/drift/generated/ \
  || { echo "::error::Generated schema artefacts are stale. Run make-migrations and commit."; exit 1; }
```

Someone will bump `kSchemaVersion` and forget the dump. This catches it in the pull request rather than in a user's February.

### 3.5 "Every write commits immediately" is a testable property

Spec §5 says *assume the phone dies*. The closest a test suite can get is to reopen the file:

```dart
// test/data/durability_test.dart
test('a lambing row is durable before the write returns', () async {
  final dir = Directory.systemTemp.createTempSync('shed_durability');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/shed.sqlite');

  var db = AppDatabase(NativeDatabase(file));
  final repo = LambingRepository(db, FakeNotificationScheduler(), FakeMediaStore());
  // Seed a real ewe: foreign_keys = ON (decision #28), so a bare EweId(1)
  // is an FK violation, not a durability test.
  final ewe = await seedEwe(db, tag: '412');
  final id = await repo.beginLambing(ewe);              // no explicit flush after
  await db.close();                                     // nothing else runs

  db = AppDatabase(NativeDatabase(file), seedOnCreate: false);  // cold start
  addTearDown(db.close);
  final rows = await (db.select(db.lambings)..where((t) => t.id.equals(id.value))).get();
  expect(rows, hasLength(1), reason: 'synchronous = FULL, WAL, decision #28');
});
```

This is deliberately a *unit* test and not a process-kill integration test: it is more deterministic, it runs on every push, and `integration_test` cannot kill a process anyway (§9).

### 3.6 Anti-patterns

| Anti-pattern | Why it is wrong |
|---|---|
| Mocking drift, or introducing a repository interface "for testability" | Decision #15. The mock cannot express a `CHECK`, a trigger or a partial index — which is where the bugs are |
| A `DatabaseConnection` without `closeStreamsSynchronously: true` in a widget test | Pending-timer failure in every stream-touching test |
| Copying a `testWithDataIntegrity` signature from a document | It is generated and version-bound |
| Testing only N-1→N | The composed path is exactly where step bugs live |
| Editing a committed snapshot to make a test pass | A released migration step is on someone's phone forever. Repair forward with a new step |

---

## 4. Fakes over mocks

### 4.1 The rule

**Hand-written fakes for everything we own; `mocktail` only for what it is genuinely good at.** Flutter's own guidance ranks "wrap the plugin in your own API and fake that" first and platform-channel mocking last, and this project has already done the wrapping: seven gateways, each wrapping exactly one plugin, most of them 3–6 methods wide (CONVENTIONS §2.12 plus 11 §5). At that width a hand-written fake wins on five counts:

1. **It records intent in a shape you can assert on with plain `expect`.** `expect(notifications.scheduled.map((s) => s.kind), ['colostrum'])` reads like the spec; `verify(() => mock.zonedSchedule(any(), any(), any(), any(), any()))` reads like nothing.
2. **No `registerFallbackValue` ceremony.** With seven gateways taking `Instant`, `ReminderId`, `ProjectedReminder` and other rich types, mocktail's fallback registration is boilerplate that exists to serve the mocking library.
3. **A fake can fail loudly on a call that should be impossible**, turning a product rule into a runtime tripwire that also fires from the widget and integration tiers.
4. **A fake survives a refactor.** A mock breaks on any signature change; a fake breaks only when the *contract* changed, which is when you want to be told.
5. **A fake is a real implementation.** `FakeShareService` capturing bytes is what makes the export→import→export round trip (§10.6) possible at all — you need the bytes, not a `verify`.

`mockito` is rejected outright: it needs `build_runner` codegen and generated mock files in review for interfaces this small, and one generator is the codegen budget (decision #16).

### 4.2 The seven fakes

One file per gateway in `test/support/`, class named `Fake<Gateway>`, always `implements` and never `extends` — so that when an owning document changes a signature, the fake is a **compile error** rather than a silent divergence.

CONVENTIONS §2.12 now tabulates six platform seams **and one store seam**: [`11-monetization-and-store.md`](11-monetization-and-store.md) §5's `PurchaseService`, folded into the catalogue as **R74** on the same shape as the other six. **`test/support/` therefore holds seven fakes, not six**, and `purchaseServiceProvider` joins the override list in §5.1.

| Gateway | Fake | What it records | The tripwire it carries |
|---|---|---|---|
| `NotificationScheduler` | `FakeNotificationScheduler` | `List<ProjectedReminder> projected`, `List<String> calls` | Duplicate id (spec §7.6 "nothing nags twice"); more than `ReminderBudget.forPlatform()` projected (decision #63); a `project()` that was not preceded by a `cancelAll()` |
| `ShareService` | `FakeShareService` | `List<FakeShared> shared` — path, mime, filename | A share of a path that does not exist, and any call passing bytes rather than a path (decision #80) |
| `MediaStore` | `FakeMediaStore` | An in-memory `Map<String, Uint8List>` keyed by relative path | An absolute path, or one with more than two separators — R62's three `CHECK`s, in Dart |
| `CameraService` | `FakeCameraService` | Scripted `pickImage` results, including `null` for "user cancelled" | — |
| `VoiceRecorder` | `FakeVoiceRecorder` | Scripted recordings, elapsed seconds | A recording longer than `kVoiceNoteMaxSeconds` |
| `WakelockController` | `FakeWakelockController` | `int acquired`, `int released` | `release()` without a matching `acquire()` |
| `PurchaseService` | `FakePurchaseService` | A scripted `updates` stream you drive from the test; `List<String> calls` | Any store call during a `pumpApp` of a **shed screen** — decision #90's failure mode is a store call on the 3am path, and this is the only place it can be caught mechanically |

**The clock is not on that list and never will be.** Decision #112's own wording counts "clock" among six doubles and omits the wakelock; that wording is superseded by CONVENTIONS §2.12. The clock is not a gateway, is not a provider, and has no fake — tests install time with `withClock` (§2.1). Writing a `FakeClock` re-introduces the second clock seam decision #46 exists to prevent.

### 4.3 The notification fake, in full

This is the seam with the most surface and the most product rules attached, so it is the one worth printing. It is written against [`08-platform-integration.md`](08-platform-integration.md) §2's declaration: the verb that reaches the OS is **`project(ProjectedReminder, {required bool exact})`**, not `schedule(...)` — `schedule(` on a reminder object is a banned spelling and its own policy rule (R51), because that spelling *is* the architecture decision #63 rejects.

```dart
// test/support/fake_notification_scheduler.dart
import 'package:shed_book/data/notification_scheduler.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/reminder_budget.dart';

/// `implements`, never `extends`. Every member of 08 §2's class is present or
/// this file does not compile — which is exactly the alarm you want when the
/// seam changes. Members with no assertion attached are one-liners.
final class FakeNotificationScheduler implements NotificationScheduler {
  /// What the app asked the OS for, in domain terms. 08 §2 owns the record
  /// type; nothing above this seam ever sees a TZDateTime (R48).
  final List<ProjectedReminder> projected = <ProjectedReminder>[];
  final List<String> calls = <String>[];

  /// Scripted capability answers. Both default to the permissive case so a
  /// test that does not care about permissions does not have to say so.
  bool granted = true;
  bool exactAllowed = true;

  @override
  Future<void> initialize({required void Function(int reminderId) onTap}) async =>
      calls.add('initialize');

  @override
  Future<void> refreshLocalZone() async => calls.add('refreshLocalZone');

  @override
  Future<void> installCopy(NotificationCopy copy) async => calls.add('installCopy');

  @override
  Future<bool> requestAlerts() async {
    calls.add('requestAlerts');
    return granted;
  }

  @override
  Future<bool> alertsGranted() async => granted;

  @override
  Future<bool> canBeExact() async => exactAllowed;

  @override
  Future<void> requestExactAlarms() async => calls.add('requestExactAlarms');

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
    projected.clear();
  }

  @override
  Future<void> project(ProjectedReminder r, {required bool exact}) async {
    calls.add('project:${r.kind}');

    if (!calls.contains('cancelAll')) {
      throw StateError(
          'decision #63: reconcile() is teardown-and-rebuild. A project() with '
          'no preceding cancelAll() is a diff, which cannot see that the '
          'schedule mode changed when the user granted exact alarms.');
    }
    if (projected.any((p) => p.id == r.id)) {
      throw StateError(
          'spec §7.6 "nothing nags twice": reminder ${r.id.value} projected twice');
    }
    if (projected.length >= ReminderBudget.forPlatform()) {
      throw StateError(
          'decision #63: the OS projection is windowed at '
          '${ReminderBudget.forPlatform()}. reconcile() must slice BEFORE it '
          'projects; the 65th request on iOS fails in a way no platform '
          'documents, and it fails by silently dropping a reminder.');
    }
    projected.add(r);
  }

  @override
  Future<List<int>> pendingIds() async => [for (final p in projected) p.id.value];

  @override
  Future<ReminderId?> launchTapTarget() async => null;

  @override
  String titleFor(String kind, {String? tag}) => 'title:$kind';
  @override
  String bodyFor(String kind, {String? tag}) => 'body:$kind';
}
```

Three things that fake buys which a mock does not.

`calls` makes an **ordering** assertion a plain list comparison: `expect(fake.calls.first, 'cancelAll')` proves teardown-and-rebuild without `verifyInOrder` and without a mocking library.

The budget tripwire fires from **every** tier. A widget test that reconciles a 400-ewe flock's reminders throws with a message naming the decision — and that is a bug which is otherwise invisible until a real shepherd's ninth night, on iOS, as a reminder that silently never arrives.

`granted` and `exactAllowed` are plain fields, so the four permission states (alerts on/off × exact alarms on/off) are four lines in a test rather than four mock setups. Spec §5 forbids permission nags, and the assertion that matters — *no permission is requested from a write path* — is `expect(fake.calls, isNot(contains('requestAlerts')))` after a lambing commits.

### 4.4 Where `mocktail` earns its keep

`mocktail: 1.0.5`, dev dependency, expected in perhaps two files. Use it for **non-invocation** and for **ordering across two seams**, where a hand-written fake would need bespoke bookkeeping:

```dart
// test/features/wakelock_scope_test.dart
class _MockWakelock extends Mock implements WakelockController {}

testWidgets('the Flock screen never acquires the wakelock', (tester) async {
  final db = await testDatabase();          // `db` is REQUIRED on pumpApp (§5.1)
  final wakelock = _MockWakelock();
  await tester.pumpApp(const FlockScreen(),
      db: db,
      overrides: [wakelockProvider.overrideWithValue(wakelock)]);
  verifyNever(() => wakelock.acquire());   // decision #79: per-screen, default off
});
```

That is what `verifyNever` is for. It is not what a fake is for: proving a call *did not* happen with a fake means asserting on the absence of an entry in a list, which is true for the wrong reasons whenever the fake was not wired in at all.

### 4.5 Anti-patterns

| Anti-pattern | Why it is wrong |
|---|---|
| A `FakeClock` or a `clockProvider` override | Decision #46. Two clock seams; a test that fakes one does not fake the other |
| `extends NotificationScheduler` in a fake | A signature change becomes a silent divergence instead of a compile error |
| Overriding a repository provider or a screen controller | 02 §5.4: override leaves, never controllers. A fake controller tests the fake |
| A `ProviderScope` with no `databaseProvider` override in a test that touches data | It opens a real database on the test machine. `openAppDatabase()` asserts it is not under `flutter_test` and throws with the name of the override to add |
| `mocktail` as the default double | `registerFallbackValue` ceremony, and assertions that read nothing like the spec |

---

## 5. The `pumpApp` harness

### 5.1 `test/support/harness.dart`

One file. It holds `Device`, `kPumpableVariants`, `testDatabase()`, `shedContainer()`, `atFixed()` and the `pumpApp` extension. [`02-state-di-navigation.md`](02-state-di-navigation.md) §5.4 owns the override *rules*; this document owns the harness that applies them.

```dart
// test/support/harness.dart
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

ProviderContainer shedContainer(
  AppDatabase db, {
  List<Override> overrides = const [],
  FakeNotificationScheduler? notifications,
  FakeShareService? share,
  FakeMediaStore? media,
  FakeCameraService? camera,
  FakeVoiceRecorder? recorder,
  FakeWakelockController? wakelock,
  FakePurchaseService? purchases,
}) {
  final container = ProviderContainer(
    overrides: [
      // 2.6.1 spelling. There is no ProviderContainer.test() and no
      // WidgetTester.container — both are Riverpod 3 (decision #18).
      databaseProvider.overrideWith((ref) async => db),
      notificationSchedulerProvider
          .overrideWith((ref) async => notifications ?? FakeNotificationScheduler()),
      shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
      mediaStoreProvider.overrideWithValue(media ?? FakeMediaStore()),
      cameraServiceProvider.overrideWithValue(camera ?? FakeCameraService()),
      voiceRecorderProvider.overrideWithValue(recorder ?? FakeVoiceRecorder()),
      wakelockProvider.overrideWithValue(wakelock ?? FakeWakelockController()),
      purchaseServiceProvider.overrideWithValue(purchases ?? FakePurchaseService()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);   // 2.6.1: you register this yourself
  return container;
}

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
  }) async {
    view.devicePixelRatio = device.dpr;
    view.physicalSize = device.size * device.dpr;
    addTearDown(view.reset);

    final theme = buildShedTheme(resolvePalette(palette, highContrast: highContrast));

    await pumpWidget(
      UncontrolledProviderScope(
        container: shedContainer(db, overrides: overrides),
        // MediaQuery wraps MaterialApp, not the other way around, so
        // MaterialApp inherits this data instead of rebuilding it from the view.
        child: MediaQuery(
          data: MediaQueryData(
            size: device.size,
            devicePixelRatio: device.dpr,
            textScaler: TextScaler.linear(textScale),   // never textScaleFactor
            boldText: boldText,
            padding: padding,
            platformBrightness: Brightness.dark,
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en', 'GB'),
            home: screen,
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }
}
```

Notes on the choices, each of which is a bug class the default would hide:

- **`textScaler`, never `textScaleFactor`.** The latter is deprecated and banned everywhere including the theme layer (decision #99); the gate greps for it.
- **Dark is not an option.** There is no light theme, so the harness offers none. `palette` and `highContrast` exist because the red-shift palette is the one nobody looks at closely after week one, and it is where a contrast regression will hide.
- **`locale: const Locale('en', 'GB')`.** `d MMM y`, 24-hour times, kg. A harness that inherits the runner's locale produces `3/28/2026` on a US CI runner and passes.
- **No `overrideWithValue(db)`.** `databaseProvider` is a `FutureProvider<AppDatabase>` and `Provider<AppDatabase>` is banned in `lib/` (CONVENTIONS §3.1); `overrideWith((ref) async => db)` is the 2.6.1 spelling that matches it.
- **`...overrides` is spread last, so a caller's override wins over the harness default** for the same provider — that is what lets §4.4 swap one gateway for a `mocktail` double without rebuilding the container. Rely on that ordering and do not reorder the list.
- **`pumpAndSettle()` with no timeout is safe here only because indefinite animations are banned on every screen** (§11.6). If one ever ships, this call hangs for ten minutes and then fails opaquely.

### 5.2 Seeding

Two seeding routes, and the choice is not stylistic:

| Route | Use it for | How |
|---|---|---|
| **Targeted helpers** | Anything asserting one behaviour | `seedEwe(db, tag: '412')`, `seedOpenOccupancy(db, …)` — small, explicit, in `test/support/seeds.dart`. The test reads as the scenario |
| **Committed fixtures** | Anything asserting shape at volume — the overflow matrix, the goldens, the at-cap monetization tests | `await restoreFixture(db, 'flock_400_3seasons.json')` — through `RestoreService`, the same path a user's backup takes |

Fixtures go through `RestoreService` and not through a bespoke loader, for the reason decision #74 gives: it makes the fixture loader a continuous test of the one code path where a bug loses five seasons. See §11.5.

### 5.3 What is in `test/support/`

Twelve files, and the list is closed. Anything else is either a test or a fake. **Every helper any snippet in this document calls is in this table** — a helper used in an example and declared nowhere is how a suite acquires a thirteenth support file by accident.

| File | Holds |
|---|---|
| `harness.dart` | `Device`, `kPumpableVariants` (§6.2's fourteen — declared once, iterated by four files), `testDatabase()`, `shedContainer()`, `atFixed()`, the `pumpApp` extension, `freshSupportDir()` (a temp directory torn down with the test, which is what `restoreInto` restores into — [`09-export-formats.md`](09-export-formats.md) §7.3 calls it and 12 declares it), and the fixture id constants the matrix and the tap budgets index into: `kSeedEwe`, `kSeedLambing`, `kSeedLamb`, `kSeedSeason` |
| `seeds.dart` | Writers. `seedEwe`, `seedOpenOccupancy`, `seedTreatment`, `seedContradictoryLambing`, `seedAutoLambing`, `seedEditedLambing`, `armExportBanner`, `setEntitlement`, `setEwesInCurrentSeason` (tops the current season up to *n* ewes — the fixtures ship at or under the cap, and decision #90's assertion is written at 99), `restoreFixture` |
| `reads.dart` | Readers. `readLambing`, `readLambingByUid`, `readLambs`, `readLamb`, `countLambings`, `countTreatments`, and `findColumn(schema, table:, column:)` over the committed drift schema JSON (§10.3) — so an assertion never has a `select` or a `jsonDecode` walk inline |
| `flock_generator.dart` | `FlockGenerator(seed)` — ~80 lines, §10.6 |
| `tolerant_comparator.dart` | `TolerantFileComparator`, §8.3 |
| `fake_notification_scheduler.dart` … `fake_purchase_service.dart` | The seven gateway fakes (§4.2) |

**Screen-driving helpers are not in `test/support/`.** `selectEwe(tester, '412')` (`test/features/tap_budget_test.dart`), `openNewTreatment(tester)` and `enterWithdrawal(tester, '28')` (`test/policy/withdrawal_has_no_default_test.dart`) are private top-level functions in the single file that uses each. They encode a screen's tap sequence, which is [`07-screens.md`](07-screens.md)'s to change; hoisting them into the shared harness would make every screen change a harness change, and a shared tap sequence quietly stops being the thing the tap-budget test is counting.

> **Landed.** The tree comments in `CONVENTIONS.md` §1 and `01-architecture.md` §2.2 now describe `test/support/` as the harness plus **seven** hand-written fakes ([`11-monetization-and-store.md`](11-monetization-and-store.md) §5's `FakePurchaseService` is the seventh, catalogued as CONVENTIONS R74) and the four helpers — `seeds.dart`, `reads.dart`, `flock_generator.dart`, `tolerant_comparator.dart` — none of which is a new *concept*. The same edit gave `test/design/` its five files rather than three (§7.4 and 10 §7.3). Comment edits, not rulings; the directories and their purposes are unchanged. §14 edit 4, closed.

---

## 6. The overflow matrix — 252 cells

### 6.1 The fourteen variants

The 3am test is a set of prose claims: legible at 18 pt, 60 pt targets, one thumb, no scrolling to reach the primary action. The matrix is what makes them mechanical. It is the best value-per-line in the suite: ~30 lines of table-driven code buys 252 assertions across every screen the product has.

| # | Variant | Route name | Why it is its own variant |
|---|---|---|---|
| 1 | Flock | `flock` | |
| 2 | Ewe Card | `ewe_card` | |
| 3 | Quick Entry | `quick_entry` | |
| 4 | Lambing Entry | `lambing_entry` | |
| 5 | Lamb Card | `lamb_card` | |
| 6 | Foster | `foster` | |
| 7 | Pen Board | `pen_board` | |
| 8 | Treatments | `treatments` | |
| 9 | Reminders | `reminders` | |
| 10 | Season Summary | `season_summary` | |
| 11 | Export | `export` | |
| 12 | Settings | `settings` | |
| 13 | Note search | `note_search` | A real route, not a spec §9 screen (07 §18). It is pumped like any other |
| 14 | Quick Entry **with the export banner shown** | `quick_entry` | The banner is a real layout state (07 §16.4), and it is the state in which the reachability assertion is most likely to fail |

**14 × 3 devices × 3 text scales × 2 bold-text states = 252.** The arithmetic follows the variant list; it is not a remembered number (R58). Decision #114's 216 was 12 × 18 and predates variants 13 and 14.

### 6.2 The test

**The table lives in `test/support/harness.dart`, not in this file.** Four files iterate it — the overflow matrix here, `semantics_gate_test.dart` and `tap_target_test.dart` (§7.4), `contrast_test.dart` (§7.6) — and a table copied four times is four tables that stop agreeing the first time a screen is added. `kPumpableVariants` is declared once, beside `Device`, and its self-check below is the only place the count is derived rather than remembered.

```dart
// test/support/harness.dart — iterated by four test files (§6.2, §7.4, §7.6)
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.flock:         () => const FlockScreen(),
  RouteNames.eweCard:       () => const EweCardScreen(eweId: kSeedEwe),
  RouteNames.quickEntry:    () => const QuickEntryScreen(),
  RouteNames.lambingEntry:  () => const LambingEntryScreen(lambingId: kSeedLambing),
  RouteNames.lambCard:      () => const LambCardScreen(lambId: kSeedLamb),
  RouteNames.foster:        () => const FosterScreen(lambId: kSeedLamb),
  RouteNames.penBoard:      () => const PenBoardScreen(),
  RouteNames.treatments:    () => const TreatmentsScreen(),
  RouteNames.reminders:     () => const RemindersScreen(),
  RouteNames.seasonSummary: () => const SeasonSummaryScreen(seasonId: kSeedSeason),
  RouteNames.export:        () => const ExportScreen(),
  RouteNames.settings:      () => const SettingsScreen(),
  RouteNames.noteSearch:    () => const NoteSearchScreen(),
  'quick_entry.export_banner': () => const QuickEntryScreen(),   // seeded to show it
};
```

```dart
// test/features/overflow_matrix_test.dart
import '../support/harness.dart';

void main() {
  // The matrix cannot silently stop covering a screen someone added. This is
  // the only place the count 252 is derived rather than remembered.
  test('the matrix covers every route, and the count is 14', () {
    const routes = <String>[
      RouteNames.flock, RouteNames.eweCard, RouteNames.quickEntry,
      RouteNames.lambingEntry, RouteNames.lambCard, RouteNames.foster,
      RouteNames.penBoard, RouteNames.treatments, RouteNames.reminders,
      RouteNames.seasonSummary, RouteNames.export, RouteNames.settings,
      RouteNames.noteSearch,
    ];
    expect(routes, hasLength(13), reason: 'RouteNames declares 13 (02 §8.1)');
    for (final r in routes) {
      expect(kPumpableVariants.keys, contains(r),
          reason: 'route "$r" is not in the matrix');
    }
    expect(kPumpableVariants.length, 14,
        reason: '13 routes + the export-banner variant (R58)');
  });

  for (final entry in kPumpableVariants.entries) {
    for (final device in Device.all) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final bold in const [false, true]) {
          testWidgets(
            '${entry.key} · ${device.name} · scale $scale · bold $bold — no overflow',
            (tester) async {
              final db = await testDatabase();
              await restoreFixture(db, 'flock_400_3seasons.json');
              if (entry.key == 'quick_entry.export_banner') {
                await armExportBanner(db);
              }
              await tester.pumpApp(entry.value(),
                  db: db, device: device, textScale: scale, boldText: bold);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
```

`RenderFlex` overflow is reported through `FlutterError.onError` during layout, which the test binding captures. No package is needed and none is used.

### 6.3 What a failure looks like

The binding fails the test on any unhandled `FlutterError` whether or not you call `takeException()`. The explicit assertion exists so the failure message names the **cell**:

```
Lambing Entry · small · scale 2.0 · bold true — no overflow

Expected: null
  Actual: FlutterError:
    The following assertion was thrown during layout:
    A RenderFlex overflowed by 23 pixels on the bottom.
```

There is no yellow-and-black striped bar in a headless test — the exception *is* the signal. When a cell fails:

1. Read the cell name. It tells you the device, the scale and the bold state, which between them locate the constraint that broke.
2. Reproduce the one cell: `flutter test test/features/overflow_matrix_test.dart --plain-name 'small · scale 2.0 · bold true'`.
3. **Fix the layout, never the matrix.** Deleting a cell is deleting the 3am test. Clamping `textScaler` to make it pass is banned outright (decision #99) and defeats Android 14+'s own non-linear curve. Wrapping user-facing text in a `FittedBox` is banned in review — shrinking a tag number to fit is the opposite of legible.
4. The two legitimate fixes are: give the widget a scroll view that is not on the primary-action path, or move something off the screen.

### 6.4 Reachability

Overflow is necessary and not sufficient: a layout can avoid overflowing by pushing the Save button below the fold. Three variants carry an extra assertion (decision #114, 07 §21.2) — Quick Entry, Lambing Entry and Foster, at the smallest device × textScaler 1.3, and for Quick Entry **with the banner shown**:

```dart
testWidgets('Quick Entry: the confirm key is on screen without scrolling, banner shown',
    (tester) async {
  final db = await testDatabase();
  await restoreFixture(db, 'flock_400_3seasons.json');
  await armExportBanner(db);
  await tester.pumpApp(const QuickEntryScreen(),
      db: db, device: Device.small, textScale: 1.3);

  final confirm = find.byKey(const Key('quick_entry.confirm'));
  expect(confirm, findsOneWidget);

  final rect = tester.getRect(confirm);
  expect(rect.bottom, lessThanOrEqualTo(667 - 34),
      reason: 'hidden behind the home indicator');

  // Read the POSITION off ScrollableState, never `Scrollable.controller`.
  // A Scrollable built without an explicit controller has `controller == null`,
  // so a `.where((s) => s.controller?.position…)` filter is empty on every
  // screen in this app and the assertion passes without asserting anything.
  // ScrollableState.position is always live once the widget has laid out.
  final scrollable = tester.stateList<ScrollableState>(find.byType(Scrollable));
  expect(
    scrollable.where((s) => s.position.maxScrollExtent > 0),
    isEmpty,
    reason: '07 §5.3: the keypad, the confirm bar and the recents strip never '
            'give up anything — the filtered-match list gives up rows first',
  );
});
```

That vacuous-filter trap is worth more than the one line it costs. A reachability assertion that cannot fail is worse than no reachability assertion, because it occupies the slot where a real one would go — and this is the screen the whole 15-second claim rests on.

---

## 7. Accessibility as an executable gate

### 7.1 The real API, by its correct names

`flutter_test` exposes four top-level guideline constants and the classes behind them:

```dart
const AccessibilityGuideline androidTapTargetGuideline =
    MinimumTapTargetGuideline(size: Size(48.0, 48.0), link: '…');
const AccessibilityGuideline iOSTapTargetGuideline =
    MinimumTapTargetGuideline(size: Size(44.0, 44.0), link: '…');
const AccessibilityGuideline textContrastGuideline = MinimumTextContrastGuideline();
const AccessibilityGuideline labeledTapTargetGuideline = LabeledTapTargetGuideline._();
```

`AccessibilityGuideline` is abstract with `FutureOr<Evaluation> evaluate(WidgetTester)` and `String get description`; `Evaluation` has `Evaluation.pass()`, `Evaluation.fail([String? reason])`, `bool passed`, `String? reason` and `operator +` (logical AND, reasons joined by newline). The matcher is `AsyncMatcher meetsGuideline(AccessibilityGuideline)` and it is matched **against the `WidgetTester`**, not against a finder.

Two of those four are used and two are not: `androidTapTargetGuideline` (48×48) and `iOSTapTargetGuideline` (44×44) are both **below** this app's floor, so running either would be a gate that passes while the product fails. They appear in this document only so nobody copies a tutorial that uses them.

### 7.2 `ensureSemantics` is not optional

```dart
final handle = tester.ensureSemantics();
addTearDown(handle.dispose);
await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
```

The semantics tree is only built while a `SemanticsHandle` is alive. The guideline's traversal reads `view.owner!.semanticsOwner!.rootSemanticsNode!`; with no live handle `semanticsOwner` is null and that is a **null-check throw**, not a vacuous pass. (Note 04 §6.1 describes it as passing vacuously; c2 §6 checked the source and it does not. The practical verdict is the same and slightly worse: the gate cannot run at all.) Decision #115: **every `meetsGuideline` run begins with those two lines.**

### 7.3 Why the built-in matcher is not enough

`MinimumTapTargetGuideline._traverse` skips a node when any of these hold, verified against `packages/flutter_test/lib/src/accessibility.dart`:

1. `node.isMergedIntoParent` — merged nodes are checked through the parent's rect.
2. `shouldSkipNode(node)`: **no `tap` and no `longPress` action**, or `isHidden`, or `isLink`.
3. The painted rect touches the boundary of an ancestor with `hasImplicitScrolling`, within `_kMinimumGapToBoundary = 0.001`.
4. **The painted rect touches the view boundary** (`Offset.zero & view.physicalSize`), by the same test.

Every one of those is a live risk in a bottom-heavy, one-thumb layout:

- Rule 4 means a **full-bleed bottom action bar is never checked** — and 07 §20.1 puts the primary action of Quick Entry, Lambing Entry, Foster and Pen Board in exactly that position. The mitigation is structural: the harness always supplies a home-indicator inset (§5.1), so the bar is never flush, *and* the geometric gate measures it regardless.
- Rule 2 means a raw `GestureDetector` with no `Semantics` produces no tappable node and is skipped entirely. This is why `ShedTapTarget` requires a `semanticLabel` and sets `Semantics(onTap:)`, and why nothing else in the app is tappable.
- Rule 3 means the first row of a scrolled list, flush against the viewport top, is skipped.

Hence decision #100's "plus a second geometric gate". It is not belt and braces; it is the only gate that sees the app's most important button.

### 7.4 The house rule, across every screen

**First, a collision to settle.** [`06-design-system.md`](06-design-system.md) §6.3 puts the semantic and geometric gates in `test/design/tap_target_test.dart`; [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §7.3 puts the same three guideline calls in `test/design/semantics_gate_test.dart` and adds a headings assertion. Both are right about the assertions and they would run the guidelines twice over the same fourteen variants. As the owner of the tiers, this document splits them by **cost**, which is the only axis that matters once they are both correct:

| File | Holds | Cost |
|---|---|---|
| `test/design/semantics_gate_test.dart` | The **tree-walking** guidelines — `shedTapTargetGuideline`, `labeledTapTargetGuideline` — plus 10's `headingLevel` assertion. 84 runs | Milliseconds per run |
| `test/design/tap_target_test.dart` | The **geometric** gate, the 16 pt gap check, the tap-action check and the canary (06 §6.3's second block). 84 runs | Milliseconds per run |
| `test/design/contrast_test.dart` | 06 §3.5's palette arithmetic, plus the **pixel-sampling** `textContrastGuideline` run. 42 runs, tagged `slow` | Seconds |

`textContrastGuideline` moves out of the semantic gate because it renders and samples every node's pixels, and running it 84 times on every push buys nothing over 42: contrast does not vary with device width, and it is the *palette* that varies (§7.6).

What this document owns beyond that split is **the table all three iterate**: the same fourteen variants as the overflow matrix, across all three devices, at textScaler 1.0 and 2.0 — **84 runs**. Bold text is excluded because it changes glyph weight and text width, not the minimum-size constraints the gates assert, and the matrix already catches the layout consequence.

```dart
// test/design/semantics_gate_test.dart — 06 §6.3 and 10 §7.3 own the assertions;
// this file owns only the table and the ensureSemantics discipline.
const shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/engineering/06-design-system.md#6-tap-targets-hit-slop-and-separation',
);

for (final entry in kPumpableVariants.entries) {     // §6.2's table, from the harness
  for (final device in Device.all) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('${entry.key} · ${device.name} · scale $scale — 60 pt floor',
          (tester) async {
        final handle = tester.ensureSemantics();     // decision #115
        addTearDown(handle.dispose);

        final db = await testDatabase();
        await restoreFixture(db, 'flock_400_3seasons.json');
        await tester.pumpApp(entry.value(), db: db, device: device, textScale: scale);

        // Gate 1 — the tree-walking guidelines. They skip edge-flush and
        // semantics-free nodes, which is why gate 2 exists (§7.3).
        await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // 10-accessibility-and-i18n.md §7.3, decision #104: at least one real
        // heading per screen — on all FOURTEEN variants, not on twelve (10 §3.4).
        expect(
          tester.semantics.simulatedAccessibilityTraversal()
              .any((n) => n.headingLevel > 0),
          isTrue,
          reason: 'header: true is a no-op on 3.44 — use headingLevel',
        );
      });
    }
  }
}
```

**Gate 2, the geometric one, is `test/design/tap_target_test.dart` and is printed in full in [`06-design-system.md`](06-design-system.md) §6.3** — it measures every `ShedTapTarget`'s rect, asserts the 16 pt gap rule, and asserts that an enabled target exposes `SemanticsAction.tap` (a button node that announces correctly and then refuses to activate is invisible to every built-in guideline). It iterates the same 84-run table and it also opens a `SemanticsHandle`, because `getSemantics` needs one just as the guidelines do.

One trap worth repeating from 06: **`find.byWidget` is unusable in the geometric gate.** Two keypad keys can be equal `Widget`s and `getRect` throws on a finder matching more than one element. Match on `Element` identity.

### 7.5 The canary

The number-one failure mode of an accessibility gate is that it silently stops asserting. Prove it is alive:

```dart
// test/design/tap_target_test.dart
testWidgets('CANARY: a deliberately 40x40 target FAILS the 60 pt guideline',
    (tester) async {
  final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 40, height: 40,
          child: Semantics(
            button: true, label: 'too small',
            child: GestureDetector(onTap: () {}, child: const ColoredBox(color: Color(0xFF000000))),
          ),
        ),
      ),
    ),
  ));
  final evaluation = await shedTapTargetGuideline.evaluate(tester);
  expect(evaluation.passed, isFalse,
      reason: 'if this canary ever passes, the 60 pt gate above is dead');
});
```

Note that it calls `evaluate` directly rather than negating `meetsGuideline`. `meetsGuideline` is an `AsyncMatcher`; asserting that something *fails* an async matcher is awkward and easy to get subtly wrong, and a canary you cannot read is not a canary.

### 7.6 Contrast

`MinimumTextContrastGuideline` enforces WCAG ratios (4.5:1 normal, 3.0:1 large, with "large" determined by `kLargeTextMinimumSize` / `kBoldTextMinimumSize`), skips off-screen nodes, and samples **rendered pixels**. Two consequences:

- **It is slow**, so it does not ride the 252-cell table. It runs at 14 variants × the three palettes at standard contrast, on `Device.small` at textScaler 1.0 — **42 runs**, tagged `slow`.
- **It is non-deterministic on photo-bearing screens** (Ewe Card, Lamb Card, Lambing Entry with an attachment) because a seeded photograph's pixels decide the answer. The harness seeds those screens with a **solid-colour placeholder** so the result is deterministic and means something.

The arithmetic half — recomputing every published ratio from the six authored palettes — is `test/design/contrast_test.dart`, owned by 06 §3.5. The rendered half belongs in the same file as a second group, and the deep-red palette is the one that matters: it is an optional mode nobody will look at closely after week one, and it is the palette most likely to land under 4.5:1.

---

## 8. Goldens

### 8.1 Eight images, and why the number is small

A golden earns its place only where a **pixel** regression is a usability or safety regression that no other test can see. Everything else — does it overflow, is the target 60 pt, is the ratio 12:1 — is already asserted more cheaply and without a binary artefact.

The cost side is what fixes the number at eight. Goldens are OS-, font- and Flutter-version-sensitive, so every one of them is re-baselined by hand on a deliberate PR whenever the toolchain moves. At eight that is a five-minute chore. At seventy-two (13 screens × 6 text-scale variants, which note 10 proposed) it is a job nobody does, and an unmaintained golden suite is worse than no golden suite because it trains you to `--update-goldens` without looking.

### 8.2 The eight

| Golden | What it pins that nothing else can |
|---|---|
| `quick_entry_default` | The 3am screen at rest. The whole product in one image |
| `quick_entry_scale_2_0` | 60 pt targets, 40 pt digits and 18 pt body all survive the largest accessibility scale *legibly* — the matrix proves nothing overflowed, not that you can read it |
| `quick_entry_deep_red` | The deep-red palette is legible, not merely different. Standard contrast, where the AA exception lives |
| `pen_board_12_pens` | Glanceability: badge colour, hours-since-penned typography, arm's-length legibility at tile density |
| `withdrawal_countdown_three_states` | Active / clears today / cleared. Getting the colour semantics wrong here is a food-safety UI bug |
| `lambing_spread_one_day` | The chart's degenerate case — one bar, and the axis still reads (decision #70) |
| `lambing_spread_tight_18_days` | The normal case, and the "first 17 days" marker (decision #70) |
| `lambing_spread_60_day_straggle` | The case where bars get thin: the chart must scroll horizontally inside its card rather than shrink (decision #70) |

Every golden is pumped through `pumpApp` with `atFixed` and a committed fixture, or the timestamps in the image change every run.

> **Edit this document requires in [`07-screens.md`](07-screens.md) §21.2.** 07's golden row reads "Quick Entry, Pen Board at three data shapes, the spread chart at three data shapes, the withdrawal control" — the same count, a different composition. The list above keeps 07's Quick Entry, Pen Board and withdrawal control and decision #70's three chart shapes, and spends the remaining two images on **text scale 2.0 and the deep-red palette** rather than on two more pen-board data shapes. The reason: pen-board tile count is a layout property the 252-cell matrix already asserts without a PNG, whereas legibility at 200% and under a red-shift palette is exactly the property that has no other gate. 12 owns the golden policy per the doc-set table; 07 should adopt the list.
>
> Note 04's `export_pdf_footer` and `ewe_card_summary_line` are deliberately not goldens. A PDF footer is a **string** assertion (`Disclaimers.exportFooter` present in the text layer, [`09-export-formats.md`](09-export-formats.md)); goldening a rendered PDF page tests the `pdf` package. The ewe-card summary line is covered by the matrix plus the a11y gates.

### 8.3 The harness

`flutter_test_config.dart` is the SDK's per-project hook: the framework scans up the directory tree from the test file, stops at the first one it finds or at `pubspec.yaml`, and calls `Future<void> testExecutable(FutureOr<void> Function() testMain)`.

```dart
// test/flutter_test_config.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/tolerant_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  // basedir resolves off the file URI, so golden keys are written relative to
  // test/features/ — which is where golden_test.dart and goldens/ both live.
  goldenFileComparator = TolerantFileComparator(
    Uri.parse('${Directory.current.path}/test/features/golden_test.dart'),
    tolerance: 0.005,   // 0.5% of pixels may differ
  );

  return testMain();
}

/// Golden files render 'Ahem' — solid black boxes — unless real fonts are
/// loaded. This app's goldens exist to prove legibility, so a golden rendered
/// in Ahem is not merely wrong, it asserts the opposite of what it claims.
Future<void> _loadAppFonts() async {
  final loader = FontLoader('AtkinsonHyperlegibleNext')
    ..addFont(rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext[wght].ttf'));
  await loader.load();
}
```

```dart
// test/support/tolerant_comparator.dart
// LocalFileComparator is documented as pixel-for-pixel exact with no tolerance.
// This is ~15 lines of the one alchemist feature worth having (diffThreshold).
final class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, {required this.tolerance});
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result =
        await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}
```

> **Verify the comparator is installed before you trust a green golden run.** Corrupt one committed PNG by a single pixel and confirm the run still passes; corrupt 5% of it and confirm the run fails with four images written to `failures/`. A comparator that silently failed to install produces a suite that passes for the wrong reason, which is indistinguishable from a suite that works.

Images live in `test/features/goldens/*.png` and the keys are written relative: `matchesGoldenFile('goldens/quick_entry_default.png')`. There is no `test/golden/` directory (R57).

### 8.4 OS and font sensitivity, and how it is pinned

The `matchesGoldenFile` documentation states it plainly: *"A golden file generated on Windows with fonts will likely differ from the one produced by another operating system."* Flutter's own team solves this with Flutter Gold / Skia Gold, which is not available to app developers, and their contributor docs say *"it is common for there to be slight differences between them."* Goldens also differ across Flutter versions (flutter#36667). So:

1. **One runner, one OS, one exact Flutter version.** Goldens are generated and verified on `macos-latest` with Flutter **3.44.8** pinned exactly via FVM — never `channel: stable`, never a floating version.
2. **Tagged `golden` and excluded from the fast job.** `flutter test --exclude-tags "golden || uk-zone || calendar"` on `ubuntu-latest` — see §11.2 for why the exclusion set is three tags and not one every push; `flutter test --tags golden` on the macOS job.
3. **Not a per-PR gate** (decision #116). GitHub bills macOS at a 10× multiplier and the Free plan's 2,000 minutes is 200 macOS minutes a month; a per-push macOS build burns the quota in a week. The macOS golden job runs on a `v*` tag or manual dispatch, and `make goldens` runs locally before tagging.
4. **`--update-goldens` never runs on CI.** Regeneration is a local, reviewed act.
5. **`failures/` is a CI artifact, never committed.** `LocalFileComparator` writes four images per failure — master, test, isolated diff, masked diff — which makes review trivial.

The two targets are in §11.4, and the split between them matters: `make goldens` **verifies**, `make goldens-update` **re-baselines**. A single target named `goldens` that passes `--update-goldens` is a target you type to check and which always agrees with you.

### 8.5 The re-baselining ritual

1. Confirm the change is intended. A golden diff you did not expect is a bug report, not a chore.
2. `make goldens-update` locally, on the pinned Flutter version.
3. **Open all four failure images for every changed golden.** The review question is not "did it change" but the one this suite exists for: *can you still read the tag number?*
4. Commit the PNGs in **their own pull request**, whose body is one line saying what changed and why. A re-baseline mixed into a feature PR is a re-baseline nobody reviewed.
5. A Flutter version bump is its own PR whose entire diff is re-baselined PNGs and the FVM pin.

### 8.6 What is not used, and why

`golden_toolkit` 0.15.0 is **discontinued** on pub.dev and last published around three years ago. That is a fact off its package page, not a judgement call, and it is why the widely-copied `loadAppFonts()` recipe must be re-implemented as the fifteen lines in §8.3 rather than imported.

`alchemist` 0.14.0 is healthy and well made and is still rejected for v1, for reasons specific to this app. Its headline feature — CI goldens with **blocked text**, where text is replaced by coloured squares — destroys the exact property these goldens exist to prove. Its other headline feature, scenario grids across themes, buys little in an app with one theme family and eight images. It also imposes a Flutter-version floor and has twice re-baselined everyone's goldens (0.10.0 padding, 0.13.0 anti-aliasing). Its genuinely useful `diffThreshold` is the fifteen-line comparator above. **Adopt it the moment the local harness exceeds ~150 lines, and do not be precious about it.**

`golden_screenshot` 11.0.1 is a real tool for a different job — generating App Store and Play Store assets from golden tests. It belongs in `tool/`, never in `test/`: it is a release-asset pipeline, not a regression gate.

---

## 9. The four integration journeys

An app with no network and no login has very little integration-shaped risk, which is precisely why the set is small and fixed at four (decision #117). Each one exercises **wiring** that unit and widget tests structurally cannot, and the justification for each is that specific gap — not "end-to-end coverage", which is not a thing this app needs.

| # | File | Journey | The wiring only it exercises |
|---|---|---|---|
| 1 | `first_run_journey_test.dart` | Fresh install → the first frame → a saved lambing for a **new** ewe, without opening Settings | The real `openAppDatabase()` — which the widget harness deliberately never runs, because it asserts it is not under `flutter_test`. Also the real `onCreate` seed (decision #42): without it, `current_season` is null and the first keypad tap cannot insert a lambing. That is a first-launch-only defect that no in-memory test can reproduce |
| 2 | `create_on_the_fly_journey_test.dart` | Type an unknown tag → one confirm creates the ewe → straight into Lambing Entry | Routing *and* insert ordering across two repositories in one flow. Spec §7.1: "never block an entry to make the user go and set something up first." The failure mode is an ordering bug that only appears when the tag index has not resolved yet (07 §5.3) |
| 3 | `foster_journey_test.dart` | One tap on the Foster screen reassigns a lamb | The `BEFORE UPDATE` trigger that makes `birth_dam` immutable, running against a real file, plus the compensating-event undo. Assert that `birth_dam` is unchanged, that a `FosterEvent` row exists, and that the rearing-dam **view** now returns the new ewe. Spec §7.3 names this the flow most likely to be abandoned |
| 4 | `backup_restore_journey_test.dart` | Export a full JSON backup to a temp file (bypassing the share sheet) → wipe → restore → the flock reads identically, provenance included | The only recovery path the product has, on a real filesystem with real permissions and the real atomic path swap. `RestoreService` writes a **new** file beside the live one and swaps; a sentinel that survives a crash mid-swap is not testable in memory |

They run **nightly on a real device, reported and not blocking** (decision #121). A device-attached job on a merge gate is how you manufacture a flaky CI.

```bash
flutter test integration_test
```

`patrol` is rejected for v1 (decision #117). It is a good package and its value proposition — driving native dialogs — is real here: notification permission, camera, microphone and the share sheet are four native surfaces `integration_test` cannot touch. But each appears **once, on first use**, a solo developer verifies them by hand in five minutes per release, and adopting patrol costs a Gradle test target, an Xcode test target, `patrol_cli` in CI and the permanent loss of `flutter test` for those files.

**The honest gap.** Spec §5 says *assume the phone dies*, and proving that properly means killing the process mid-entry and relaunching, which patrol can do and `integration_test` cannot. The mitigation is to move the durability proof *down* a tier to §3.5's reopen-the-file test, which is more deterministic than a process kill would be. Revisit patrol if permission flows ever regress in the field, or for v2 when Bluetooth EID arrives.

---

## 10. The product's own promises, as tests

`test/policy/` is the directory a new reader should open first. Every file names its spec clause in the first line, and the filename states the **property**, not the file under test (CONVENTIONS §4.1).

**All five of spec §12, and where each one is actually proved.** §1.1 counts five promises; this section writes three of them as tests, and that is not an omission — §1.4's rule decides which is which, and a reader is owed the whole map rather than the part that happens to be a `test()`.

| Spec §12 rule | Proved by | Where |
|---|---|---|
| §12.1 never default a withdrawal period | The sealed type, the committed-schema assertion, the widget test | §10.3 — two gates (decision #52) |
| §12.2 never give veterinary advice | **The gate, not a test.** `ContentPolicy.bannedInUserFacingText` under `lib/` and `assets/` — "should", "recommended dose", diagnosis phrasing — with `ContentPolicy.allowlist` keyed by `Disclaimers.*` rather than by a literal | `tool/check_policy.dart` (`copy.*`). It is a source-text assertion, so §1.4 puts it there and it is a defect anywhere else |
| §12.3 never a compliance or regulatory record | **The gate plus one artefact assertion.** `copy.disclaimer_retyped` proves `Disclaimers.exportFooter` is referenced and never re-typed; §1.3's PDF row proves it is present in the text layer of the produced document | `tool/check_policy.dart` + [`09-export-formats.md`](09-export-formats.md) §6.2 |
| §12.4 never silently correct an entry | A warning fires **and the row is unchanged**, asserted against the database | §10.4 |
| §12.5 timestamps are honest | Provenance stored, not derived; survives a file, a reopen and an export/import | §10.5 |

Two of the five are gate rules and not tests, and that is the point of §1.4: neither "no vet advice" nor "not a compliance record" is a behaviour a widget can exhibit, so a `test()` asserting either would have to read source text, which is the gate's job. What is **not** acceptable is leaving them off the map — a safety rule nobody can point at is a safety rule nobody maintains.

> **Signatures this section borrows, and their status.** The **properties** asserted below are this document's and do not move; the **verbs** belong to the owning documents, and where an owner is published this document has adopted its spelling rather than invented one.
>
> - **Adopted, because the owner is published.** `ExportRepository.writeBackup(envelope:)`, the round trip stated over the backup's **`tables`** value (never over the whole file — the header carries `exportedAtUtc`), and the `tablesBytesOf` / `headerOf` accessors are [`09-export-formats.md`](09-export-formats.md) §7's, verbatim. `restoreInto(...)` — the harness wrapper around the staging-file / validate / swap / reopen flow, returning the reopened `AppDatabase` — is [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §7.2's entry point, named by 09 §7.3. `ExportEnvelope.standard({now, appVersion})` is CONVENTIONS R65's only factory.
> - **Adopted, now that 05 names it.** `checkLambing(Lambing lambing, List<Lamb> lambs)` is the entry point into [`05-domain-correctness.md`](05-domain-correctness.md)'s `lib/domain/validation/lambing_checks.dart`, named in 05 §7.5 guarantee 1 alongside `checkFoster`, `checkTreatment`, `checkClearDate` and `checkLocalWallTimeExists`. It is no longer this document's placeholder. The property — a query with no writer — is what is being asserted and never depended on the name.
>
> Every borrowed name is a real call, so a divergence is a compile error rather than a silent drift. That is the whole reason none of them is stringly-typed.

### 10.1 The three tap budgets

The dishonest version of "under fifteen seconds" is a widget test that measures elapsed wall time. `flutter test` runs under `FakeAsync`; the number is meaningless and on CI it is load noise. **Do not write it.** The honest version decomposes the budget: taps are what the shepherd spends time on, and taps are deterministic.

```dart
// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3
final class TapCounter {
  int taps = 0;
  int textEntries = 0;
}

extension CountedActions on WidgetTester {
  Future<void> countedTap(Finder f, TapCounter c) async {
    c.taps++;
    await tap(f);
    await pumpAndSettle();
  }
}

void main() {
  // Budget rationale, kept here so the next person knows why 6 and not 9:
  // 6 taps at a generous 1.5 s each — gloved, wet, cold, dark — is 9 s,
  // leaving ~6 s for unlock and cold start against the 15 s claim.
  testWidgets('unlock -> committed lambing costs at most 6 taps and no typing',
      (tester) async {
    final db = await testDatabase();
    await seedEwe(db, tag: '412');
    final c = TapCounter();
    await tester.pumpApp(const QuickEntryScreen(), db: db);

    await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_4')), c);
    await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_1')), c);
    await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_2')), c);
    await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);
    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);
    await tester.countedTap(find.byKey(const Key('lambing_entry.birth_type.twin')), c);

    expect(c.taps, lessThanOrEqualTo(6));
    expect(c.textEntries, 0);
    expect(await countLambings(db), 1);
  });

  testWidgets('foster: reassignment from the Foster screen costs 1 tap', (tester) async {
    // 07 §8.5. Spec §7.3: "the flow most likely to be abandoned if it takes five taps."
    final db = await testDatabase();
    await restoreFixture(db, 'flock_400_3seasons.json');
    final c = TapCounter();
    final birthDamBefore = (await readLamb(db, kSeedLamb)).birthDam;
    await tester.pumpApp(const FosterScreen(lambId: kSeedLamb), db: db);

    await tester.countedTap(find.byKey(const Key('foster.target.412')), c);

    expect(c.taps, 1);
    final event = await db.select(db.fosterEvents).getSingle();
    expect(event.outcome, 'to_ewe');       // FosterOutcome.ToEwe's stored key (R64)
    final lamb = await readLamb(db, kSeedLamb);
    // Compare against the value read BEFORE the tap. `EweId(412)` would be
    // wrong: 412 is a TAG, and an EweId is a row id — the two are unrelated,
    // and under the owner's active-only uniqueness ruling a tag is not even
    // unique across time. Capture, then compare.
    expect(lamb.birthDam, birthDamBefore,
        reason: 'decision #33: fostering never touches birth_dam');
  });

  testWidgets('repeat last treatment onto another animal costs 2 taps', (tester) async {
    // 07 §10.4. Spec §7.5 requires the batch shortcut.
    final db = await testDatabase();
    await seedTreatment(db, product: 'Alamycin LA', withdrawalDays: 28);
    final c = TapCounter();
    await tester.pumpApp(const TreatmentsScreen(), db: db);

    await tester.countedTap(find.byKey(const Key('treatments.repeat_last')), c);
    // §12.1: the carried-forward withdrawal figure must be RENDERED before the
    // committing tap. That is what makes "repeat" not a default.
    expect(find.textContaining('28'), findsWidgets);
    // Disclaimers.withdrawalProvenance, REFERENCED and never re-typed
    // (decision #62, CONVENTIONS §2.14). A test that hard-codes the string
    // still passes after somebody edits the constant, which is the one
    // failure this assertion exists to catch.
    expect(find.textContaining(Disclaimers.withdrawalProvenance), findsWidgets);
    await tester.countedTap(find.byKey(const Key('treatment.repeat.animal.128')), c);

    expect(c.taps, 2);
    expect(await countTreatments(db), 2);
  });
}
```

> **New widget keys.** `foster.target.<tag>`, `treatments.repeat_last` and `treatment.repeat.animal.<tag>` are not yet declared in [`07-screens.md`](07-screens.md). They follow CONVENTIONS §4.5 (`<screen>.<element>[.<qualifier>]`, every segment `lower_snake`, on the model of `pen_board.turn_out.3`). 07 owns screen keys; if it spells them differently, 07 wins and this file changes — a key is a test contract and renaming one is a breaking change (R59).

**Double taps.** Every committing action gets a `tester.tap(); tester.tap();` test (decision #22). Cold, wet fingers on capacitive glass double-fire, and without `WriteController.guard()` the second fire is a second lambing record — a data-integrity bug produced by hardware:

```dart
testWidgets('a double-fired confirm commits exactly one lambing', (tester) async {
  final db = await testDatabase();
  await seedEwe(db, tag: '412');
  await tester.pumpApp(const QuickEntryScreen(), db: db);
  await selectEwe(tester, '412');

  final lambing = find.byKey(const Key('quick_entry.event.lambing'));
  await tester.tap(lambing);
  await tester.tap(lambing);          // no pump between them — that is the point
  await tester.pumpAndSettle();

  expect(await countLambings(db), 1);
});
```

### 10.2 The offline gates — what belongs in `test/` and what does not

Almost none of it. This is worth stating explicitly, because "prove the app is offline" reads like a test-suite job and is not one.

| Gate | Where it lives | Owner |
|---|---|---|
| G1 — `bundletool dump manifest` on the shipped release `.aab` asserts the exact permission set | CI shell step | 13 |
| G2 — direct-dependency allowlist over `pubspec.lock`, `dependencies` and `dev_dependencies` scanned separately | `tool/check_policy.dart` + `tool/policy_allowlist.txt` | 01 / 13 |
| G3 — import-level scan of `lib/` for network packages and network identifiers | `tool/check_policy.dart` (`net.*` rules) | 01 |
| G4 — the manifest-merger report, archived | CI artifact, **diagnostic only** | 13 |
| G5 — iOS: no `NSAppTransportSecurity`, App Privacy Report / `nettop` once per release | Manual, per release | 13 |

Two tests must **never** be written:

1. **"`pubspec.lock` contains no `http`."** It is unsatisfiable. `flutter_local_notifications → timezone → http`, `wakelock_plus → package_info_plus → http`, `file_selector → file_selector_platform_interface → http` and `image_picker → image_picker_platform_interface → http` are four regular edges (decision-record §3.4, measured 2026-08-01). A gate that cannot pass gets deleted, and the real gates get deleted alongside it.
2. **A duplicate of any `check_policy` rule.** §1.4. If it can be asserted by reading source text, it is the gate's job.

The one thing this document adds is a negative rule with teeth: **no test may install `HttpOverrides.global`.** Decision #122 rejected the runtime guard as a belt over a manifest brace that already makes sockets impossible on Android; a test that installs it implies the app does, and the next reader will add it to `main()`.

### 10.3 No code path defaults a withdrawal period

Spec §12.1. **Two gates, not four** (decision #52) — the sealed type does most of the work, because `WithdrawalDays` has a private generative constructor and exactly one factory, `asEnteredByUser`, so a value that did not come from the user is unconstructible.

```dart
// test/policy/withdrawal_has_no_default_test.dart — spec §12.1
void main() {
  test('the committed schema has no default of any kind on days', () {
    final schema = jsonDecode(
        File('drift_schemas/drift_schema_v$kSchemaVersion.json').readAsStringSync());
    final column = findColumn(schema, table: 'treatment_withdrawals', column: 'days');

    expect(column['default_dart'], isNull, reason: 'no withDefault()');
    expect(column['default_client_dart'], isNull, reason: 'no clientDefault()');
    expect(column['nullable'], isFalse,
        reason: 'a nullable column invites a ?? fallback; "not recorded" is the '
                'ABSENCE of a row, not a null (decision #51)');
  });

  test('no row implies NotRecorded, and NotApplicable is an explicit marker', () async {
    final db = await testDatabase();
    final repo = TreatmentRepository(db);
    final outcome = await repo.recordTreatment(/* … no withdrawal argument at all … */);
    expect(outcome, isA<WriteCommitted>());

    final rows = await db.select(db.treatmentWithdrawals).get();
    expect(rows, isEmpty);
    expect(await repo.withdrawalFor(TreatmentId(1)), isA<WithdrawalNotRecorded>());
  });

  testWidgets('the entry control is empty, and Save carries no number until one is typed',
      (tester) async {
    final db = await testDatabase();
    await tester.pumpApp(const TreatmentsScreen(), db: db);
    await openNewTreatment(tester);

    // Assert on rendered text, not on a widget's private state: the control is
    // a ShedKeypad and its API is 06's, not this document's.
    final field = find.byKey(const Key('treatment.withdrawal.enter_days'));
    expect(field, findsOneWidget);
    final rendered = find
        .descendant(of: field, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>();
    expect(rendered.any((s) => RegExp(r'\d').hasMatch(s)), isFalse,
        reason: '§12.1: no pre-filled number and no pre-selected option. '
                '0 is a real label value, not a placeholder');

    await enterWithdrawal(tester, '28');
    // Referenced, never re-typed (decision #62). Hard-coding the literal here
    // would keep passing after somebody softened the constant.
    expect(find.textContaining(Disclaimers.withdrawalProvenance), findsOneWidget);
  });
}
```

**The heuristic that is deliberately not written:** a source scan banning a numeric literal near the token `withdrawal`. It fires on the `CHECK` constraints in `03-data-model-and-schema.md`, on every fixture, and on this document's own examples. A gate with a standing false positive gets an allowlist, then gets weakened, then gets deleted — and it is guarding the one rule whose regression is a food-safety incident.

### 10.4 A contradiction warns and does not mutate

Spec §12.4. Everyone writes the half that says "a warning appears". The half that matters is **"and the record is unchanged"** — asserted against the database, not against an in-memory object.

```dart
// test/policy/warnings_never_mutate_test.dart — spec §12.4
test('birth type "twin" with three lambs warns, and mutates nothing', () async {
  final db = await testDatabase();
  final repo = LambingRepository(db, FakeNotificationScheduler(), FakeMediaStore());

  final lambing = await repo.beginLambing(await seedEwe(db, tag: '412'));
  await repo.setBirthType(lambing, BirthType.twin);
  for (var i = 0; i < 3; i++) {
    await repo.addLamb(lambing, sex: Sex.female);        // three, deliberately
  }

  final before = await readLambing(db, lambing);
  final lambsBefore = await readLambs(db, lambing);

  final warnings = checkLambing(before, lambsBefore);
  expect(warnings.single.code, WarningCode.birthTypeLambCountMismatch);

  // The critical assertion: the validator is a query, not a command. It holds
  // no writer — lib/data/ may not import lib/domain/validation/ (R53), so a
  // repository structurally cannot produce or apply one.
  expect(await readLambing(db, lambing), before);
  expect(await readLambs(db, lambing), lambsBefore);
  expect((await readLambing(db, lambing)).declaredBirthType, BirthType.twin.code,
      reason: '§12.4: flag it; do not fix it');
});

test('quintPlus with any lamb count is UNDEFINED, not a contradiction', () {
  // expectedLambCount(quintPlus) returns null (R46) — an open-ended type
  // cannot contradict a count. A warning here would be the app inventing a fact.
  // `lambingWith` and `lambsOfCount` are file-local builders over the row
  // classes, not shared helpers: they belong to this one property (§5.3).
  expect(expectedLambCount(BirthType.quintPlus), isNull);
  expect(checkLambing(lambingWith(BirthType.quintPlus), lambsOfCount(7)), isEmpty);
});

testWidgets('the warning strip is visible, and dismissing it writes nothing',
    (tester) async {
  final db = await testDatabase();
  final lambing = await seedContradictoryLambing(db);
  await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);

  expect(find.byKey(const Key('lambing_entry.warning.birth_type_lamb_count')),
      findsOneWidget);

  final before = await readLambing(db, lambing);
  await tester.tap(find.byKey(const Key('lambing_entry.warning.dismiss')));
  await tester.pumpAndSettle();
  expect(await readLambing(db, lambing), before);
});
```

There is no `fix()`, no `corrected` field and no `warnings` column — the mechanism is *absence*, and these tests assert the absence is real rather than merely intended.

### 10.5 Timestamp provenance survives a round trip

Spec §12.5. Provenance is **stored**, never derived: `isEdited => updatedAt != createdAt` is tempting and breaks the moment anything else touches the row.

```dart
// test/policy/provenance_survives_a_round_trip_test.dart — spec §12.5
test('the stored keys are frozen — changing one breaks every backup ever written', () {
  expect(TimeSource.values.map((s) => s.key).toList(), ['auto', 'entered', 'edited']);
});

test('editing keeps the original and records when the edit happened', () {
  final auto = atFixed(DateTime(2026, 3, 28, 7, 0),
      () => RecordedTime.capture(appNow()));
  final edited = atFixed(DateTime(2026, 3, 28, 7, 5),
      () => auto.editedTo(Instant.fromDateTime(DateTime(2026, 3, 28, 3, 20))));

  expect(edited.effective.local, DateTime(2026, 3, 28, 3, 20));
  expect(edited.source, TimeSource.userEdited);
  expect(edited.originalEffective!.local, DateTime(2026, 3, 28, 7, 0));
  expect(edited.isEdited, isTrue);
  expect(edited.provenanceLabel, isNotEmpty);   // exhaustive switch; can never be empty
});

test('provenance survives a file round trip, a reopen, and an export/import',
    () async {
  final dir = Directory.systemTemp.createTempSync('shed_provenance');
  addTearDown(() => dir.deleteSync(recursive: true));

  var db = AppDatabase(NativeDatabase(File('${dir.path}/shed.sqlite')));
  final id = await seedEditedLambing(db);
  await db.close();

  db = AppDatabase(NativeDatabase(File('${dir.path}/shed.sqlite')), seedOnCreate: false);
  final row = await readLambing(db, id);
  expect(row.timeSource, TimeSource.userEdited);
  expect(row.originalEffective, isNotNull);
  expect(row.capturedAt, isNotNull);

  // And through the only path off the phone. 09 §1.1's verb writes a FILE and
  // returns its path; 04 §7.2's restoreInto swaps it in and reopens.
  final backup = await ExportRepository(db).writeBackup(
      envelope: ExportEnvelope.standard(now: appNow(), appVersion: '1.0.0'));
  await db.close();

  final restoredDb = await restoreInto(freshSupportDir(), File(backup.path));
  addTearDown(restoredDb.close);
  // Identity is `uid`, and integer ids are re-issued on import (09 §7.2 rule
  // 12) — so the restored row is found by uid, never by the old LambingId.
  final restored = await readLambingByUid(restoredDb, row.uid);
  expect(restored.timeSource, TimeSource.userEdited,
      reason: 'an edited time must never come back as auto-captured');
  expect(restored.originalEffective, row.originalEffective);
  expect(restored.capturedAt, row.capturedAt);
});

testWidgets('the UI labels edited times and does not label auto ones', (tester) async {
  final db = await testDatabase();
  final auto = await seedAutoLambing(db);
  await tester.pumpApp(LambingEntryScreen(lambingId: auto), db: db);
  // `recorded automatically` is RecordedTime.provenanceLabel's autoCaptured
  // arm (05 §7.4). textContaining, because 07 §6 renders it inside a composed
  // line — `412 · triplets · 03:24 · recorded automatically`.
  expect(find.textContaining('recorded automatically'), findsOneWidget);
  expect(find.textContaining('edited'), findsNothing);
});
```

`readLambingByUid` joins `reads.dart` for exactly this reason: the moment an assertion crosses a restore, a row id is the wrong handle. Reaching for the pre-export `LambingId` on the far side of an import is the single most common way this test passes by accident on an empty database.

### 10.6 Export → import → export equality

Spec §7.9. **JSON is the backup; CSV and PDF are reports.** CSV is deliberately lossy — three different row shapes — and must never be asserted for round-trip equality. Being explicit about which artefact is lossless is itself a design decision worth writing down.

**The header trap:** the backup's `BackupHeader` carries `exportedAtUtc`, so byte equality over the whole file is impossible by construction. The property is stated over the **`tables`** value and nothing else — [`09-export-formats.md`](09-export-formats.md) §7.1 owns that wording, and this document does not restate it in different words, because a round-trip claim that drifts between two documents is a claim nobody can check.

Two layers (decision #118):

```dart
// test/policy/backup_round_trips_test.dart — spec §7.9
// Layer 1 — pure values, as an explicit table. `glados` was struck from
// decision-record §5.2 on 2026-08-01: it does not resolve against drift_dev
// 2.34.5 at ANY version, because it depends on package:test. The shrinking is
// what it was bought for; a written table of the cases shrinking would have
// found is one screen of code and cannot fail to install.
for (final t in <RecordedTime>[...kRecordedTimeRoundTripCases]) {
  test('a RecordedTime survives its JSON round trip: \$t', () {
    expect(RecordedTime.fromJson(t.toJson()), t);
  });
}

// Layer 2 — the whole flock, hand-rolled, seeded, deterministic.
// The verbs are 09 §7.3's: writeBackup / restoreInto / tablesBytesOf / headerOf.
void main() {
  final env = ExportEnvelope.standard(now: appNow(), appVersion: '1.0.0');

  for (var seed = 0; seed < 200; seed++) {
    test('flock backup round-trips (seed $seed)', () async {
      final source = await testDatabase(seedOnCreate: false);
      await FlockGenerator(seed).populate(source);   // referentially valid

      final first    = await ExportRepository(source).writeBackup(envelope: env);
      final restored = await restoreInto(freshSupportDir(), File(first.path));
      addTearDown(restored.close);
      final second   = await ExportRepository(restored).writeBackup(envelope: env);

      expect(tablesBytesOf(second), tablesBytesOf(first),
          reason: 'reproduce with FlockGenerator($seed)');
      expect(headerOf(second).checksum.value, headerOf(first).checksum.value,
          reason: 'the checksum covers `tables` and must follow it');

      // 09 §7.2 rules 3 and 12, and the reason this file is in test/policy/
      // rather than test/data/: identity is `uid`, integer ids are re-issued,
      // and a recreated ewe must never inherit a culled one's history.
      expect(idsOf(restored), isNot(idsOf(source)));
      expect(uidsOf(restored), uidsOf(source));
    });
  }
}
```

**One file, two owners, no second copy.** 09 §7.3 sketches this same test and this document does not fork it: `test/policy/backup_round_trips_test.dart` is one file, 09 owns what it asserts, and 12 owns where it lives, what it is tagged, how it is seeded and that it runs on every push. `tablesBytesOf`, `headerOf`, `idsOf` and `uidsOf` are private top-level accessors in it, not shared helpers — they read a format only this file reads, and putting them in `test/support/` would invite a second caller who does not know the header is outside the checksum.

The generator is **hand-rolled and roughly 80 lines**, not a `glados` `Any` extension, because the invariants are domain invariants a generic combinator library makes awkward. Every one of these, when violated, is a real importer bug:

- A lamb's `birth_dam` exists in the export; its rearing dam may differ (fostering).
- Dead lambs have a death date at or after their lambing's `occurred_at`.
- Treatments reference an animal that exists; at least one carries `WithdrawalDays`, at least one `WithdrawalNotApplicable`, at least one no row at all.
- At least one record with `TimeSource.userEdited` and at least one with `TimeSource.autoCaptured`.
- Unicode in free text — a shepherd types `°`, `½`, an em-dash and an emoji.
- **A culled ewe whose tag a live ewe reuses** (the owner's ruling: tags are unique among *active* animals only). Import is an upsert on `uid`, never on `tag`, and this is the case that proves it.
- An empty flock, and a flock at the free-tier ewe cap.

Print the seed on failure, and **do not extend the property layer** (decision #118): a seeded generator nobody understands in season three is worse than a fixture.

**`export-carries-no-row-ids` is the same property from the other side, and it is its own file because it fails differently.** `test/policy/export_carries_no_row_ids_test.dart` walks every row object in one produced backup and asserts that no key is `id` and no key ends `_id`, against the `<parent>_uid` convention 09 §5.3 fixes. The round trip above catches an id leak only when the leak *also* breaks equality; a leaked id that happens to survive re-issue passes the round trip and fails this one. The five vocabulary FKs are the documented exception — `route`, `presentation`, `death_cause`, `kind`, `method` carry a `vocab_terms.key` rather than a uid — and the assertion allows them **by name**, never by pattern: a pattern-shaped exemption is one refactor away from exempting the thing it was written to catch.

> **The resolution was run, and it reddened. `glados` is not a dependency of this project.** N00-T03 ran decision #5's `flutter pub get` — the first time anybody had — and `glados` was the one row of §5.2 that did not resolve. It depends on `package:test`, which is exactly what decision #4 bans as a direct dependency and for exactly the same reason: `test` caps `analyzer <13.0.0` and pins a `test_api` other than the `0.7.11` `flutter_test` pins exactly. `glados: any` reports *"glados is incompatible with drift_dev 2.34.5"*, so this is the package and not one version of it. **The rule this paragraph used to state has been applied: the property layer was deleted, not the pin.** §5.2's row is struck with the evidence and decision #118 is amended. Layer 2 — the hand-rolled, seeded `FlockGenerator` — was never a package and is unaffected; it is now the whole of the property tier.

### 10.7 Nothing monetization-related reaches a shed screen

Spec §5's "zero interruptions" is written as a shipping gate, so it is a test (decisions #90, #92, and the owner's ruling on the free tier).

```dart
// test/features/no_monetization_test.dart
const shedScreens = <String, Widget Function()>{
  RouteNames.quickEntry:   () => const QuickEntryScreen(),
  RouteNames.lambingEntry: () => const LambingEntryScreen(lambingId: kSeedLambing),
  RouteNames.lambCard:     () => const LambCardScreen(lambId: kSeedLamb),
  RouteNames.foster:       () => const FosterScreen(lambId: kSeedLamb),
  RouteNames.penBoard:     () => const PenBoardScreen(),
};

for (final entry in shedScreens.entries) {
  testWidgets('${entry.key}: nothing monetization-related at 99 ewes, locked',
      (tester) async {
    final db = await testDatabase();
    await restoreFixture(db, 'flock_15_at_cap.json');
    await setEntitlement(db, unlocked: false);
    // Decision #90 writes the assertion at 99 ewes — far past any cap shape
    // the free tier could take. The fixture ships at the cap; the helper tops
    // the current season up. Both numbers matter: at-cap is the boundary,
    // 99 is the state where a paywall would be most tempting to render.
    await setEwesInCurrentSeason(db, 99);

    await tester.pumpApp(entry.value(), db: db);

    // Keyed, not typed: 11-monetization-and-store.md owns the widget's name,
    // and a key is a contract this test can hold before that document lands.
    expect(find.byKey(const Key('flock.upgrade_row')), findsNothing);
    expect(find.byKey(const Key('settings.upgrade_row')), findsNothing);
    expect(find.textContaining('Unlock'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
  });
}
```

Two more, in `test/domain/free_tier_test.dart`, because they are properties of `FreeTierPolicy` and not of a screen:

```dart
test('liveEntry can never be blocked, at any flock size or season count', () {
  for (final ewes in const [0, 15, 16, 400]) {
    for (final seasons in const [1, 2, 5]) {
      final decision = FreeTierPolicy().decide(
        context: EntryContext.liveEntry,
        now: Instant.fromDateTime(DateTime(2026, 3, 28, 3, 20)),
        unlocked: false, ewesInCurrentSeason: ewes, seasonCount: seasons,
      );
      expect(decision, isA<Allow>(), reason: 'spec §7.1 at 03:20 with $ewes ewes');
    }
  }
});

test('a calm-UI cap decision never blocks between 22:00 and 06:00', () {
  for (final hour in const [22, 23, 0, 1, 3, 5]) {
    final decision = FreeTierPolicy().decide(
      context: EntryContext.calm,
      now: Instant.fromDateTime(DateTime(2026, 3, 28, hour, 30)),
      unlocked: false, ewesInCurrentSeason: 99, seasonCount: 2,
    );
    expect(decision, isA<Allow>(), reason: 'the owner\'s quiet-window ruling, at $hour:30');
  }
});
```

---

## 11. Organisation, tags, ordering and fixtures

### 11.1 Naming

| Kind | Rule | Example |
|---|---|---|
| Unit / data / widget test | Mirrors the file under test, `_test.dart` | `test/domain/withdrawal/clear_date_test.dart` |
| Policy test | States the **property**, not the file | `test/policy/withdrawal_has_no_default_test.dart` |
| Test name | The behaviour, in the present tense, in the domain's words | `'exitPen closes the occupancy and preserves entered_at forever'` |
| Matrix cell | `'<variant> · <device> · scale <n> · bold <b> — <property>'` | the failure message *is* the reproduction command |

A test name that says `'test 3'` or `'works'` costs ten minutes at 23:00 six months from now, when it is the only line CI shows you.

### 11.2 `dart_test.yaml`

```yaml
# dart_test.yaml
tags:
  golden:      # generated and verified only on the pinned macOS runner
  migration:
    timeout: 2x
    allow_test_randomization: false   # order-sensitive by design
  uk-zone:     # requires TZ=Europe/London; the file asserts the offset itself
  policy:
  slow:
    timeout: 3x
  flaky:       # excluded from CI; every one carries an expiry date in its name
```

The tags must be **declared here** or a `--tags` filter silently matches nothing and the run is green because it ran nothing. That much every document agrees on.

**No `presets:` block — and this contradicts [`13-build-ci-release.md`](13-build-ci-release.md) as published, so it is stated as a ruling and carried to §14 rather than left to collide.** 13 §1.3 and §4.3 invoke `flutter test -P ci-fast` and `-P ci-golden`, and 13's preamble attributes both presets to this file. This document owns `dart_test.yaml` and declines to add them, for one hard reason and one soft one:

1. **`flutter test` has no preset flag.** `-P`/`--preset` is **not** in the pass-through list below, which is read off `flutter_tools`' `test.dart`. `dart test` accepts it; `flutter test` is a different command with its own argument parser, and this project never runs `dart test` — decision #4 keeps `package:test` out of the pubspec entirely. A preset name CI cannot pass is not a source of truth, it is an error message on the first push. **Confirm this on day one against the installed SDK** — it is the one line that decides which of the two documents changes — and if `flutter test` does accept `-P`, reason 1 evaporates and only reason 2 stands.
2. 13's stated rationale for the preset — that a bare `--exclude-tags golden` "would silently drop" the `migration` tag's `allow_test_randomization: false` — does not hold. Tag configuration in `dart_test.yaml` applies to every run that selects those tests, preset or not; it is not something a command-line filter switches off.

**RULED 2026-08-01, in N01-T04, by running the check on the installed SDK.** Both halves were run
together as this section asks, on Flutter 3.44.8:

| Check | Command | Answer |
|---|---|---|
| Does `flutter test` accept a preset flag? | `fvm flutter test --help \| grep -E '^\s*-P\|--preset'` | **No.** Empty output. Reason 1 above stands, so **this document is right and 13 §1.3 and §4.3 are wrong as published**; both take §14 edit 1 |
| Does `allow_test_randomization: false` take effect under `flutter test`? | three tests declared `a`, `b`, `c` under `@Tags(['migration'])`, run twice with the same explicit seed | **Yes.** With the key: `a b c`. Without it: `b c a`. The fallback this section names — `--exclude-tags migration` plus a separate non-randomised invocation — is **not needed** |

A third fact fell out of the same twenty minutes and it corrects the sentence at the top of this
section. **An empty tag selection does not exit 0.** `flutter test --tags policy` against a tree with
no file carrying that tag prints *"No tests match the requested tag selectors"* and exits **79**. So
a `--tags` filter that matches nothing fails a CI step rather than passing vacuously — a stronger
position than this document assumed, and it changes nothing about the rule. Declare the tag anyway
and land a carrier anyway: an exit code is a weaker guarantee than a name, and a step that passes
because a tagged file exists is worth more than one that fails because none does. N01-T04 lands the
`uk-zone` canary for exactly that reason.

**The Definition-of-Done line "both presets exist" is therefore unsatisfiable as written**, and it is
recorded here as a ruling rather than quietly dropped: there are no presets, in this file or
anywhere, and every filter in the `Makefile` and in `ci.yml` is spelled out, identically in both.

**And the filter is wider than `--exclude-tags golden`, which is a second correction the same
twenty minutes produced.** `ci-fast` was only ever `exclude_tags: golden`, and a run filtered that
way is red on day one for two reasons that have nothing to do with goldens:

| Also excluded from the broad run | Why, and where it runs instead |
|---|---|
| `uk-zone` | Those files assert their own process offset and **fail loudly under any other zone** — which is the behaviour §2.5 wants, and which makes them a guaranteed failure in the broad run on a UTC CI runner. They run in the dedicated `TZ=Europe/London` step, which is the only place they can pass |
| `calendar` | N00's ledger test is **red by design** until N32 closes the last commitment. §11.2's own rule is that it is kept out of the blocking set by this tag; leaving it in the broad run makes `main` permanently red for the one reason that is not a defect |

So the broad command is

```bash
flutter test --exclude-tags "golden || uk-zone || calendar" \
  --test-randomize-ordering-seed random --coverage
```

and `--exclude-tags` does accept that boolean expression — measured on 3.44.8 on 2026-08-01, along
with everything else in this section. Verified end to end: under `TZ=UTC` it selects 52 tests and all
52 pass, and `zone_canary_test.dart` is not among them.

> **VERIFIED 2026-08-01 (N01-T04), and the answer is in the table above.** `flutter test` historically honours less of `dart_test.yaml` than `dart test` does, so this was a real risk — but `allow_test_randomization: false` **does** take effect on the `migration` tag under `flutter test`, measured against three tests declared `a`, `b`, `c` run twice under the same explicit seed. The fallback named here — `--exclude-tags migration` in the randomised job plus a separate non-randomised invocation — is **not needed** and must not be added: it would be complexity paid for a problem that does not exist.

`flutter test` does pass through `--tags`/`-t`, `--exclude-tags`/`-x`, `--update-goldens`, `--coverage`, `--reporter`, `--concurrency`, `--test-randomize-ordering-seed`, `--name`, `--plain-name`, `--total-shards`, `--shard-index`, `--timeout` and `--fail-fast`. There is no `-P`, no `--preset` and no `--configuration`.

### 11.3 Randomised ordering

```bash
flutter test --exclude-tags "golden || uk-zone || calendar" --test-randomize-ordering-seed random
```

The seed is printed on every run, so any failure reproduces with `--test-randomize-ordering-seed=<seed>`. This matters more here than in a typical app: the data and migration tiers share `setUp`-created databases, and randomisation is what catches accidental cross-test state — a leaked `withClock`, a static seed counter, a fixture mutated in place by a previous test. Migration tests are excluded (they are order-sensitive by design).

### 11.4 The two Makefile targets, and the one word still in dispute

[`13-build-ci-release.md`](13-build-ci-release.md) §1.3 owns the `Makefile` and ships `gen`, `check`, `test`, `goldens`, `goldens-update`, `perf` and `integration`. Two of its targets carry test-suite properties this document is the owner of, and **both are already satisfied in 13 as published** — the zone-pinned second command on `test`, and the split between a `goldens` that verifies and a `goldens-update` that re-baselines. Only the filter spelling is still in dispute (§11.2).

```make
# The shape this document requires. Two commands on `test`, because TZ is
# per-process and the tag alone cannot change the zone the runner starts in.
test:
	$(FLUTTER) test --exclude-tags "golden || uk-zone || calendar" --test-randomize-ordering-seed random --coverage
	TZ=Europe/London $(FLUTTER) test --tags uk-zone

# A target called `goldens` that silently rewrites the baseline is the single
# easiest way to green a broken golden — you type it to check, and it agrees.
goldens:                  ## verify against the committed PNGs
	$(FLUTTER) test --tags golden

goldens-update:           ## re-baseline. A deliberate act, its own commit (§8.5)
	$(FLUTTER) test --tags golden --update-goldens
```

13's copies **used to** read `-P ci-fast` and `-P ci-golden` where these read `--exclude-tags golden` and `--tags golden`. That was the §11.2 disagreement and nothing else; it was settled on 2026-08-01 by running the check, and 13 §1.3 and §4.3 now spell the filters the same way this document does: the target names, the split and the zone run all match. Resolve it once, in whichever direction the day-one check decides, and make both files say the same thing.

Everything else in 13's `Makefile` stands as written. `make check` runs the cheapest failure first — the gate is sub-second, `analyze` is tens of seconds — and that ordering is worth preserving.

### 11.5 Seeds and fixtures

There is one seed generator and it is not in `test/`:

```bash
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42
```

`tool/seed.dart` writes a deterministic database **through the same `RestoreService` path a user's JSON backup takes** (decision #74). That is not a convenience: it makes the seed script a continuous test of the one code path where a bug loses five seasons. It runs with a fixed seed and a fixed clock, and it is guarded by `assert()` plus a `--dart-define` so it cannot run in a release build.

Two committed fixtures, both real backup files:

| Fixture | Shape | Used by |
|---|---|---|
| `test/fixtures/flock_400_3seasons.json` | 400 ewes, three seasons, at least one culled ewe whose tag a live ewe reuses, at least one edited timestamp, at least one contradictory lambing, unicode notes | The overflow matrix, the a11y gates, the goldens, and the **spec §7.7** recall assertions — the multi-season history the retention feature needs and that no in-test seed produces |
| `test/fixtures/flock_15_at_cap.json` | Exactly at the free-tier ewe cap, one season | The monetization tests, the cap decisions |

Both are loaded with `restoreFixture(db, name)`, which calls `RestoreService`. **Do not add a third fixture without deleting one.** Four topics depend on populated state and none of them needs a bespoke shape; a fixture per test is how a suite becomes unmaintainable, and a generator nobody understands in season three is worse than either.

### 11.6 Flakiness discipline

Zero tolerance, enforced by rules rather than willpower — there is one developer and nobody else to absorb the noise.

**Banned in tests:** `Future.delayed`; wall-clock assertions; `DateTime.now()`; reliance on ambient `TZ` or locale outside the two zone-pinned tags; `pumpAndSettle()` on any screen with a repeating animation (it hangs for ten minutes and then fails opaquely — and indefinite animations are banned on the shed screens anyway, because they cost battery at 3am).

**The `flaky` tag is excluded from CI and every test carrying it has an expiry date in its name**: `testWidgets('flaky-until-2026-09-01: …', tags: ['flaky'])`. A test in `test/policy/` fails the build once an expiry passes. Quarantine without an expiry is how a suite rots.

**Any test that fails once on CI and passes on rerun is fixed or deleted that day.**

`experimentalLeakTesting` stays **off**. Flutter's own docs describe the parameter as experimental and not recommended outside the framework; it adds flake for a class of bug this app is unlikely to hit. Revisit only if DevTools shows a real leak.

---

## 12. Coverage — a report, never a gate

```bash
flutter test --coverage
lcov --remove coverage/lcov.info '*.g.dart' '*.drift.dart' '*/generated/*' \
     -o coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
```

Note what is **not** in that strip list: `*.freezed.dart`. `freezed` is rejected on this stack (it is unresolvable against both `drift_dev` and `build_runner`), so a strip pattern for it is dead configuration that implies the package might be used.

Three reasons the number is a report and not a gate, all specific to this codebase:

1. **The highest-value tests contribute almost zero line coverage.** The `.aab` permission assertion, the schema-JSON default assertion, the codegen-freshness diff, the a11y guideline runs, the overflow matrix — none of them executes much of `lib/`. A percentage that ignores them is measuring the wrong thing.
2. **Generated code dominates the denominator.** After stripping, the number moves substantially for reasons unrelated to test quality, which makes any threshold arbitrary.
3. **A percentage gate creates pressure to test the cheapest lines.** `copyWith` and `toString` are trivially coverable and worthless to test; the DST cases are expensive and are the reason this suite exists. A gate that rewards the first while the second stays unwritten is worse than no gate.

Track **one number that means something: coverage of `lib/domain/**`**, aimed at 95%+ as a *review prompt*. Every line there is a pure function, and "not covered" genuinely means "not tested". Everywhere else, read the uncovered-file list in review, not the percentage. Publish `genhtml` output as a CI artifact.

---

## 13. What CI proves, and what it cannot

Owned by [`13-build-ci-release.md`](13-build-ci-release.md); listed here so a test author knows which job their test lands in.

| What runs | Runner | Blocking |
|---|---|---|
| `tool/check_policy.dart`, format, analyze | `ubuntu-latest` | Yes |
| Codegen + `make-migrations` freshness diff | `ubuntu-latest` | Yes |
| `flutter test --exclude-tags "golden \|\| uk-zone \|\| calendar" --test-randomize-ordering-seed random --coverage` (13 §4.3 spelled the filter `-P ci-fast` until 2026-08-01; edit 1 has been applied, and the exclusion set was widened at the same time — see §11.2) | `ubuntu-latest` + `libsqlite3-dev` | Yes |
| `TZ=Europe/London flutter test --tags uk-zone` (no path — §2.5) | `ubuntu-latest` | Yes |
| `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` | `ubuntu-latest` | Yes |
| Release AAB build + permission assertion (G1) | `ubuntu-latest` | Yes |
| `flutter test --tags golden` | `macos-latest`, Flutter 3.44.8 pinned exactly | On `v*` tag or manual dispatch |
| `flutter test integration_test` | Nightly, real device | No — reported |
| Startup trace, `--analyze-size` | Per release, two real devices, by hand | No — recorded in `docs/perf/measurements.md` |

**What no test in this repository can prove.** Legibility under a head torch. Whether six taps *feels* like fifteen seconds with a lamb under one arm. Whether the pen board reads from three metres. Whether a gloved thumb finds the confirm key, or whether a freezer bag passes enough capacitance for any of this to matter. Those close on the field night and the ziplock-bag test (decision-record §7.1, items 1 and 2), and nothing here substitutes for either. Every tap-count budget in §10.1 is a desk estimate held in place by CI until the field night happens.

---

## 14. Edits this document requires in siblings

Four still open, three already landed. None is a naming change and none reopens a decision. Where a sibling is published and spells something differently, **the owner wins and this document has already changed** — §10's preamble records those adoptions, and they are not listed here as edits to anyone else.

**Still open.**

| # | Document | Edit | Why |
|---|---|---|---|
| 1 ✅ **APPLIED 2026-08-01 (N01-T04)** | [`13-build-ci-release.md`](13-build-ci-release.md) §1.3 and §4.3 | Replaced `-P ci-fast` / `-P ci-golden` with `--exclude-tags golden` / `--tags golden`, and dropped the claim that `dart_test.yaml` declares those presets | §11.2. `-P`/`--preset` is not in `flutter test`'s flag set, and this project never runs `dart test` (decision #4). **Run the day-one check first**: if `flutter test` does accept `-P`, this document adds the presets instead and the edit reverses. One of the two files changes; both saying different things is the only unacceptable outcome |
| 2 | [`07-screens.md`](07-screens.md) §21.2 | Adopt §8.2's eight goldens — same count, two images moved from pen-board data shapes to text scale 2.0 and the deep-red palette | Tile count is a layout property the 252-cell matrix asserts without a PNG; legibility at 200% and under red-shift has no other gate |
| 3 | [`06-design-system.md`](06-design-system.md) §6.3 and [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §7.3 | Split by cost, per §7.4: the tree-walking guidelines + headings in `semantics_gate_test.dart`, the geometric gate + canary in `tap_target_test.dart`, the pixel-sampling `textContrastGuideline` in `contrast_test.dart` | Both documents currently run all three guidelines over the same 14 variants, so the contrast run happens twice at 84 runs each when 42 proves the same thing |
| 4 | [`CONVENTIONS.md`](CONVENTIONS.md) §1 and [`01-architecture.md`](01-architecture.md) §2.2 | Tree comments. `test/support/` holds the harness, **seven** fakes, `seeds.dart`, `reads.dart`, `flock_generator.dart` and `tolerant_comparator.dart`. `test/design/` holds `semantics_gate_test.dart` and `reduce_motion_test.dart` as well as the three files the comment lists | Comment edits, not rulings. The seventh fake is [`11-monetization-and-store.md`](11-monetization-and-store.md)'s `FakePurchaseService`; the four helpers are this document's; the two design files are §7.4's and 10 §7.3's |

**Already landed in the sibling — kept here as standing properties, because each regresses into a green run rather than a red one.**

| # | Document | Property | If it regresses |
|---|---|---|---|
| A | [`13-build-ci-release.md`](13-build-ci-release.md) §4.3 | The `TZ=Europe/London … --tags uk-zone` step is **unscoped** | §2.4's two zone-pinned files run under UTC, where a spring-forward test passes because there is no spring forward |
| B | [`13-build-ci-release.md`](13-build-ci-release.md) §4.3 | The `TZ=Pacific/Chatham` step carries `--exclude-tags uk-zone` | The step is red on every run, for the right reason, which is how a correct gate gets deleted |
| C | [`13-build-ci-release.md`](13-build-ci-release.md) §1.3 | `goldens` verifies, `goldens-update` re-baselines, and `test` carries the second zone-pinned command | A target you type to check silently agrees with you |

---

## Definition of done

Tick every line before calling the test layer finished.

- [ ] `test/{domain,domain/uk_zone,data,drift,drift/generated,design,features,policy,support,fixtures}/` and `integration_test/` all exist. No `test/ui/`, `test/screens/`, `test/integration/`, `test/fakes/` or `test/golden/`.
- [ ] No file under `test/` imports `package:test/test.dart`. Every test imports `package:flutter_test/flutter_test.dart`.
- [ ] `test/support/harness.dart` holds `Device`, `testDatabase()`, `shedContainer()`, `atFixed()` and `pumpApp`, and every widget test goes through it. No test constructs a `ProviderScope` by hand.
- [ ] All **seven** gateway fakes exist in `test/support/`, each `implements` (never `extends`) its gateway, and each carries at least one loud tripwire. `FakeNotificationScheduler` implements every member of 08 §2's class and its projection verb is `project(...)`, never `schedule(...)`.
- [ ] There is no `FakeClock`, no `clockProvider` and no second `Clock` abstraction anywhere in `test/`.
- [ ] DST-1 … DST-5 pass under `TZ=Europe/London` and fail loudly under any other zone; the two extensions in §2.4 exist and are tagged `uk-zone`; CI runs `--tags uk-zone` as its own step.
- [ ] Every `atFixed` call in the widget tier carries the comment saying why it is a single-instant assertion.
- [ ] The migration matrix covers **every** from→to pair, `PRAGMA foreign_key_check` returns zero rows on every path, `PRAGMA quick_check` returns `ok`, and `drift_schemas/` holds exactly `kSchemaVersion` files.
- [ ] `dart run drift_dev make-migrations` produces no git diff in CI.
- [ ] The overflow matrix is **252 cells over 14 variants**, its self-check asserts `kPumpableVariants.length == 14`, every `RouteNames` constant appears in the table, and the table is declared **once** in `harness.dart` rather than copied into each of the four files that iterate it.
- [ ] The reachability assertion passes for Quick Entry (with the banner shown), Lambing Entry and Foster at 375×667 × textScaler 1.3.
- [ ] Every `meetsGuideline` run begins with `ensureSemantics()`; the 40×40 canary **fails** the 60 pt guideline; the semantic and geometric gates each run over 14 variants × 3 devices × textScaler {1.0, 2.0}; `textContrastGuideline` runs once per variant per palette and nowhere else.
- [ ] Eight goldens exist, tagged `golden`, excluded from the per-push job, generated on one macOS runner with Flutter 3.44.8 pinned exactly. Corrupting one PNG by 5% fails the run; corrupting it by one pixel does not.
- [ ] `flutter_test_config.dart` loads the real font, and one golden has been eyeballed for "can you read the tag number".
- [ ] Four integration journeys exist, run nightly on a real device, and are reported rather than blocking.
- [ ] The three tap budgets pass with keyed finders: 6 taps unlock→lambing, 1 tap foster reassignment, 2 taps repeat treatment. Every committing action has a double-tap test.
- [ ] `test/policy/` contains, at minimum: withdrawal-has-no-default, warnings-never-mutate, provenance-survives-a-round-trip, backup-round-trips, export-carries-no-row-ids.
- [ ] All five of spec §12 have a named home in §10's map, and the two that are gate rules rather than tests (§12.2, §12.3) are live rows in `tool/check_policy.dart` rather than assumed.
- [ ] Every helper any test calls is declared in §5.3's twelve-file table, or is a private top-level function in the single file that uses it. No thirteenth support file.
- [ ] No test contains a source-scanning `RegExp` that duplicates a `tool/check_policy.dart` rule; no test asserts `http` is absent from `pubspec.lock`; no test installs `HttpOverrides.global`.
- [ ] Every assertion on a disclaimer references `Disclaimers.*` rather than re-typing its text, and every assertion on a time label references `RecordedTime.provenanceLabel`'s wording rather than a literal that outlives it.
- [ ] Coverage is published as an artifact and gates nothing. `lib/domain/**` is at 95%+ or the gap is named in review.
- [ ] `make goldens` **verifies** and `make goldens-update` **re-baselines**; no single target does both.
- [ ] The four open edits in §14 have been made in their owning documents, or each is open with an owner; the three landed properties (A–C) still hold.
- [x] The `dart_test.yaml` day-one check **has been run** (2026-08-01, N01-T04) and both answers are written into §11.2: `flutter test` has no preset flag, and `allow_test_randomization: false` does take effect. A third measurement is recorded there too — an empty tag selection exits 79, not 0 — both the preset question and the `allow_test_randomization` question being the same check.
- [ ] `flutter test` runs green on a laptop in aeroplane mode.

---

## Open items

Carried, not hidden.

1. ~~**`dart_test.yaml` fidelity under `flutter test`** (§11.2). Two unverified halves of one check.~~ **CLOSED 2026-08-01 (N01-T04).** Both halves were run together on Flutter 3.44.8: `flutter test` has no `-P` / `--preset` flag, and `allow_test_randomization: false` does take effect on the `migration` tag. A third fact was measured with them — an empty `--tags` selection exits **79**, not 0. All three are recorded in §11.2 and 13 §1.3 and §4.3 have taken §14 edit 1.
2. **Closed — `checkLambing`'s real name** (§10, §10.4). 05 §7.5 guarantee 1 now names the validation entry points (`check<Thing>` → `List<Warning>`, one per file), so `checkLambing(Lambing, List<Lamb>)` is 05's spelling and not this document's placeholder. Nothing in §10.4 changes.
3. **The host sqlite3 floor on the actual runner image** (§3.2). 3.41.0 is the asserted floor; which build a given image ships has not been checked. Run `test/data/host_sqlite_version_test.dart` on the image before the first green CI.
4. **The tolerant comparator's installation** (§8.3). `LocalFileComparator`'s basedir resolution and the interaction with `flutter_test_config.dart` must be confirmed by deliberately breaking a golden. Until that is done, a green golden run proves nothing.
5. ~~**`glados` resolution** (§10.6).~~ **Closed 2026-08-01 — it does not resolve at any version and is struck from decision-record §5.2.** Nothing left to check; the property tier is the hand-rolled seeded generator alone.
6. **Whether `SchemaVerifier` tolerates FTS5 shadow tables** ([`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §3.4). If it does not, the migration matrix is the test that tells you, in week one, with FTS5 in schema v1 and no real rows at risk. Do not paper over it by disabling the assertion.
7. **`HapticFeedback.successNotification()`** (07 §22 item 7). If the member does not exist on Flutter 3.44.8, the commit-confirmation test asserts `heavyImpact()` instead. Owned by 06.
8. **Every tap-count budget is a desk estimate** until the field night happens (decision-record §7.1 item 1). CI holds the three numbers; it cannot tell you they are the right three.

---

## References

Fetched 2026-07-27 unless stated.

**Flutter test framework**
- `flutter_test` library, including `flutter_test_config.dart` — https://api.flutter.dev/flutter/flutter_test/
- `AutomatedTestWidgetsFlutterBinding` (the advancing fake clock) — https://api.flutter.dev/flutter/flutter_test/AutomatedTestWidgetsFlutterBinding-class.html
- `TestFlutterView` (`physicalSize`, `devicePixelRatio`, `reset`) — https://api.flutter.dev/flutter/flutter_test/TestFlutterView-class.html
- `WidgetController.ensureSemantics` — https://api.flutter.dev/flutter/flutter_test/WidgetController/ensureSemantics.html
- `meetsGuideline` — https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html
- `AccessibilityGuideline` — https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html
- `MinimumTapTargetGuideline` — https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html
- `MinimumTextContrastGuideline` — https://api.flutter.dev/flutter/flutter_test/MinimumTextContrastGuideline-class.html
- `accessibility.dart` source (the four skip rules) — https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_test/lib/src/accessibility.dart
- `matchesGoldenFile` — https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html
- `LocalFileComparator` (pixel-exact, no tolerance) — https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html
- `FontLoader` — https://api.flutter.dev/flutter/services/FontLoader-class.html
- `MediaQueryData.textScaler` — https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html
- Writing a golden-file test (per-platform images, "slight differences") — https://github.com/flutter/flutter/blob/master/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md
- Goldens differ across Flutter versions — https://github.com/flutter/flutter/issues/36667
- `flutter_tools` test command flags — https://raw.githubusercontent.com/flutter/flutter/stable/packages/flutter_tools/lib/src/commands/test.dart

**Flutter docs**
- Testing plugins ("wrap the plugin in your own API" ranked first) — https://docs.flutter.dev/testing/plugins-in-tests
- Integration testing — https://docs.flutter.dev/testing/integration-tests

**Dart**
- `DateTime` (midnights less than 24 h apart across a DST change) — https://api.dart.dev/stable/dart-core/DateTime-class.html
- `DateTime.add` (may not hit the calendar date you expect) — https://api.dart.dev/stable/dart-core/DateTime/add.html
- `package:test` configuration (`tags`, `presets`, `allow_test_randomization`) — https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md

**drift**
- Testing (`NativeDatabase.memory()`, `closeStreamsSynchronously`) — https://drift.simonbinder.eu/testing/
- Migration tests — https://drift.simonbinder.eu/migrations/tests/
- Step-by-step migrations — https://drift.simonbinder.eu/migrations/step_by_step/
- Schema exports — https://drift.simonbinder.eu/migrations/exports/
- Supported platforms (host sqlite3 for `flutter test`) — https://drift.simonbinder.eu/platforms/
- `SchemaVerifier` — https://pub.dev/documentation/drift_dev/latest/api_migrations_native/SchemaVerifier-class.html
- `VerifySelf.validateDatabaseSchema` (an extension member) — https://pub.dev/documentation/drift_dev/latest/api_migrations_native/VerifySelf.html

**Packages (versions from decision-record §5 only)**
- `clock` 1.1.2 — https://pub.dev/packages/clock
- `mocktail` 1.0.5 — https://pub.dev/packages/mocktail
- ~~`glados` 1.1.7~~ — struck 2026-08-01, does not resolve against `drift_dev` 2.34.5 at any version
- `golden_toolkit` 0.15.0, **discontinued** — https://pub.dev/packages/golden_toolkit
- `alchemist` 0.14.0 (rejected; `diffThreshold` in 0.14.0) — https://pub.dev/packages/alchemist · https://pub.dev/packages/alchemist/changelog
- `golden_screenshot` 11.0.1 (belongs in `tool/`) — https://pub.dev/packages/golden_screenshot
- `patrol` 4.8.0 (rejected for v1; `flutter test` will not run its tests) — https://pub.dev/packages/patrol · https://patrol.leancode.co/documentation
- `accessibility_tools` 2.8.0 (debug-only, 48×48 default is below this app's floor) — https://pub.dev/packages/accessibility_tools
- `sqlite3_test` 0.2.0 (not used; SQL-side time is banned and it cannot support WAL) — https://pub.dev/packages/sqlite3_test

**Internal**
- `CONVENTIONS.md` §1 (the test tree), §2.12 (the gateways), §4.1 (test file naming), §4.5 (widget keys), §4.6 (stored keys), R47, R48, R51, R53, R57, R58, R59, R62
- `04-migrations-media-backup-restore.md` §3 (the migration matrix, the data-integrity scope, the no-diff check, the FTS5 question)
- `05-domain-correctness.md` §2.8–§2.9 (time in tests, DST-1 … DST-5 and the measured DST facts)
- `06-design-system.md` §3.5, §6.3 (the contrast arithmetic, `shedTapTargetGuideline`, the geometric gate)
- `07-screens.md` §1.3 (the three tap budgets), §5.4, §8.5, §10.4 (the tap tables and their keys), §21.2 (what CI proves about screens)
- `08-platform-integration.md` §2 (`NotificationScheduler`'s surface and `ProjectedReminder`)
- `10-accessibility-and-i18n.md` §7.3 (the semantic gate and the headings assertion)
- `11-monetization-and-store.md` §5 (`PurchaseService`, the seventh gateway)
- `13-build-ci-release.md` §2 (the `Makefile`), §4.3 (the CI job steps this document amends)
- `docs/research/00-tech-decisions.md` §2K (decisions #110–#122), §5 (the only source of version numbers), §7.0 (the owner's four rulings)
