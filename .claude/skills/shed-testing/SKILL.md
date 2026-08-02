---
name: shed-testing
description: >-
  How Shed Book is tested and every gate asserted — tiers, fixed time, the harness and the fakes.
  Use for any test, flaky test, or failing tap-target, semantics or contrast gate, and never run
  --update-goldens. Do NOT use to choose a value (indelible-design-system).
---

# Testing Shed Book

**Authority.** `docs/engineering/12-testing.md` owns the strategy; `docs/engineering/CONVENTIONS.md`
R57 (the test tree), R58 (252 cells over 14 variants), §4.1 (test and policy-test naming) and §4.5
(widget keys) own every name and path and outrank this skill. Open the section, do not re-derive it.

**Do NOT use this skill for:** choosing a colour, a size, a ratio or a target dimension —
**indelible-design-system** owns the value, this skill owns the assertion. Semantic labels, heading
text or en_GB formats — **shed-accessibility-and-copy**. Re-baselining golden PNGs —
**shed-goldens-rebaseline**, developer-invoked only. Extending the migration from→to matrix —
**shed-migrations**.

**Read `references/harness.md` when writing a widget or a repository test** — it holds `testDatabase`,
the seven fakes and `pumpApp`'s exact override list.

## Never run `flutter test --update-goldens`

Not to see if it helps, not to unblock a run, and not via `make goldens-update` — that target
re-baselines; `make goldens` is the one that verifies. A red golden is a **failing test** until a
human has looked at the four images `LocalFileComparator` wrote to `failures/` and answered the
question the suite exists for: *can you still read the tag number?* A `PreToolUse` hook blocks the
flag outright, so attempting it fails the tool call rather than silently rewriting the baseline.
Re-baselining is `/shed-goldens-rebaseline`, developer-invoked, its own commit. Report the red golden;
do not resolve it — and never edit a committed PNG.

Golden **policy**: eight images and no more, tagged `golden`, excluded from the per-push job,
generated on one macOS runner with the Flutter version `.fvmrc` and decision-record §5 pin, exactly.
`test/flutter_test_config.dart`
loads the real bundled font (a golden rendered in Ahem is black boxes asserting the opposite of
legibility) and installs `TolerantFileComparator` at 0.005. Add a ninth only where a *pixel*
regression is one nothing cheaper can see — overflow, targets and contrast are already asserted
without a PNG.

## Where a test goes

Not a pyramid — the risk is arithmetic that is invisible when wrong, one database with no second copy
and five promises no compiler enforces (12 §1.1), so the domain tier is thickest and the screens get a
wide table-driven layer instead of per-screen behaviour tests.

`test/domain/` pure functions · `test/domain/uk_zone/` DST-1…DST-5, `@Tags(['uk-zone'])` ·
`test/data/` repositories against real SQLite · `test/drift/` the migration matrix ·
`test/design/` the executable gates · `test/features/` widget tests, the matrix, the goldens ·
`test/policy/` spec §12 as behaviour · `test/support/` harness and fakes · `test/fixtures/` ·
`integration_test/` four journeys, nightly, non-blocking.

`test/screens/`, `test/integration/`, `test/ui/`, `test/fakes/` and `test/golden/` are **banned** (R57).
Unit tests mirror the file under test; a `test/policy/` file is named for the **property** —
`withdrawal_has_no_default_test.dart` (§4.1). **Every test imports `package:flutter_test/flutter_test.dart`, including pure-domain tests.**
`package:test` is never a direct dependency (decision #4): it caps `analyzer <13.0.0` and breaks
`drift_dev`, so an `import 'package:test/test.dart';` under `test/` is the first thing to check when
`flutter pub get` reddens.

**Gate or test?** If the assertion can be made by reading source text it belongs in
`tool/check_policy.dart` — one script, one allowlist, one exit code (decision #10) — and nowhere else.
A `RegExp` inside a `test()` is a policy rule that escaped home; it acquires its own allowlist and
drifts. Never assert `http` is absent from `pubspec.lock` (unsatisfiable — two legitimate transitive
edges); never install `HttpOverrides.global`.

## Time — pin `now` or measure elapsed, never both

One clock: `appNow()` in `lib/core/time/app_clock.dart` over `package:clock`. There is no `FakeClock`,
no `clockProvider` and no second `Clock` abstraction — a test that fakes one of two seams does not
fake the other (decision #46).

- **Widget tests already have an advancing fake clock** — the binding installs the `FakeAsync` zone's
  clock as the ambient one, so `tester.pump(const Duration(hours: 25))` really does move `appNow()`.
  Never construct a `FakeAsync`; `package:fake_async` is not a dependency.
- **The trap:** `atFixed(...)` wraps `withClock(Clock.fixed(...))`, which *freezes* time. Wrap an
  elapsed-time widget test in it and every countdown holds its initial value — the test measures 0 h
  and **passes**. Single-instant ("does the tile read `9h`?") → `atFixed`, with the seed data offset to
  the instant you want. Elapsed ("does it flip to `24h`?") → pin nothing, seed at
  `appNow().plus(const Duration(hours: -23, minutes: -59))`, then `pump`. Every widget-tier `atFixed`
  carries a comment saying which it is.
- `DateTime.now()` in a test is a build failure (the gate scans `test/` too); so is `Future.delayed` in
  a test body — real wall time inside `FakeAsync` hangs or flakes.
- **Anything time-shaped also gets a `test/domain/uk_zone/` case** tagged `uk-zone` in the
  **01:00–01:59** ambiguous hour (UK/Ireland: 29 March and 25 October 2026 — late March is peak
  lambing). `setUpAll` asserts the process offset and **fails loudly** rather than skipping; a skipped
  safety test is a broken safety test. Data- and widget-tier extensions carry the tag too, which is why
  the CI zone step stays **unscoped**.

```bash
TZ=Europe/London   flutter test --tags uk-zone          # no path — the tag selects the files
TZ=Europe/London   flutter test test/domain
TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone
```

Run all three before pushing anything under `lib/domain/time/` or `lib/domain/withdrawal/`; if a
result depends on `TZ`, something is reading ambient local time that should not be.

## Databases and fakes

- `testDatabase()` in `test/support/harness.dart` is the **only** way a test gets a database: real
  SQLite via `NativeDatabase.memory()`, never a mock and never behind a repository interface
  (decisions #111, #15) — a mock has no `CHECK`, no trigger and no partial unique index, and that is
  where the bugs are. `closeStreamsSynchronously: true` is mandatory, or every stream-touching widget
  test fails with a pending-timer error naming nothing useful.
- `flutter test` runs on the **host**: CI needs `libsqlite3-dev`, and
  `test/data/host_sqlite_version_test.dart` asserts a 3.41.0 floor — if it fails, fix the runner image,
  never the assertion. The `test/drift/` matrix runs on every push and `make-migrations` must leave no
  git diff; extending it is **shed-migrations**'s.
- Seven hand-written fakes in `test/support/`, `Fake<Gateway>`, always `implements` and never
  `extends` — a signature change must be a compile error, not a silent divergence — each carrying a
  loud tripwire. `mocktail` (pinned in decision-record §5.2) is for **non-invocation** and cross-seam ordering only
  (`verifyNever`); proving absence with a fake is true for the wrong reasons when the fake was never
  wired in. Never override a repository provider or a screen controller — override leaves only.

## The overflow matrix — the count is derived, never typed

**252 = 14 pumpable variants × 3 devices × 3 text scales × 2 bold-text states** (R58). `kPumpableVariants`
is declared **once** in `test/support/harness.dart` and iterated by four files (the matrix,
`semantics_gate_test.dart`, `tap_target_test.dart`, `contrast_test.dart`). Adding a screen makes it
**270**, not a lint error: add the entry and its `RouteNames` constant, then update the self-check —
the only place a count is written down, and it also asserts every `RouteNames` constant is in the
table (00-README §8 step 25).

When a cell fails, **fix the layout, never the matrix.** Deleting a cell deletes the 3am test; clamping
`textScaler` is banned (decision #99) and a `FittedBox` around user-facing text is banned in review —
shrinking a tag number is the opposite of legible. The two legitimate fixes are a scroll view off the
primary-action path, or less on the screen.

**Reachability** rides on three variants — Quick Entry *with the export banner shown*, Lambing Entry,
Foster — at `Device.small` × textScaler 1.3. Read scroll position off `ScrollableState.position`, never
`Scrollable.controller`: these screens build no explicit controller, so a
`.where((s) => s.controller?.position…)` filter is empty everywhere and the assertion passes without
asserting anything.

## Every executable gate

- **`ensureSemantics()` first, always** — `final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);` before any `meetsGuideline` or `getSemantics` call (decision #115).
  Without a live handle `semanticsOwner` is null and the guideline **throws**: the gate cannot run.
- **`shedTapTargetGuideline` is `MinimumTapTargetGuideline(size: Size(60, 60), link: …)`** — copy the
  `const` from `06 §6.3`; `link` is a **required** named parameter of that class on 3.44, so omitting
  it does not compile. Never
  `androidTapTargetGuideline` (48) or `iOSTapTargetGuideline` (44): both sit below this product's
  floor, so running either is a gate that passes while the product fails.
- **The tree-walking guideline is not sufficient.** It skips nodes with no `tap`/`longPress` action and
  nodes whose painted rect touches the view boundary — which is every full-bleed bottom action bar in
  the app. Hence the geometric gate in `test/design/tap_target_test.dart`: each `ShedTapTarget` rect
  against 60×60, gaps `0` or `≥ 16`, and an enabled target exposing `SemanticsAction.tap`.
  `find.byWidget` is unusable there — two keypad keys can be equal `Widget`s and `getRect` throws on a
  multi-match finder; match on `Element` identity.
- **Split by cost, four files.** `semantics_gate_test.dart` = tree-walking guidelines + the
  `headingLevel > 0` assertion (`header: true` is a no-op on Flutter 3.44); `tap_target_test.dart` =
  the geometric gate + the canary. Both run **14 variants × 3 devices × textScaler {1.0, 2.0} = 84
  runs** — bold is excluded, it changes glyph weight, not a minimum-size constraint.
  `contrast_test.dart` = the palette arithmetic **plus** the pixel-sampling `textContrastGuideline`,
  tagged `slow`, 14 variants × 3 palettes on `Device.small` at 1.0 — never on the 84-run table.
  `reduce_motion_test.dart` = two branches, Android `disableAnimations` alone and iOS `reduceMotion`
  alone, because each platform sets only one and `prefersReducedMotion` ORs both.
- **The canary must fail.** A deliberate 40×40 target is asserted to *fail* the 60 pt guideline by
  calling `guideline.evaluate(tester)` directly and expecting `passed` false, never by negating an
  async matcher. If the canary passes, the gate above it is dead.
- **A failing gate is fixed in the widget** — never by lowering a guideline, deleting a variant or
  adding an exemption. Three strings fail the design system's stamp-size exemption because each is
  the sole carrier of its meaning on its line — **indelible-design-system** owns that test and both
  sizes; this skill only asserts the outcome, so read the sizes there before writing the assertion.

## The product's promises, as tests

- Spec §12.2 (no veterinary advice) and §12.3 (not a regulatory record) are **gate rows in
  `tool/check_policy.dart`**, not tests; §12.1, §12.4 and §12.5 are tests in `test/policy/`.
- A warning test asserts **the row is unchanged**, read back from the database — not merely that a
  message appeared. There is no `fix()`, no `corrected` field and no `warnings` column: the mechanism
  is absence, and the test proves the absence is real.
- Provenance is stored, never derived: assert it survives a file, a reopen and an export/import, and
  find the restored row **by `uid`** — integer ids are re-issued on import. Assert disclaimers via
  `Disclaimers.*` and time labels via `RecordedTime.provenanceLabel`; a hard-coded literal keeps
  passing after somebody softens the constant, which is what the assertion exists to catch.
- **Tap budgets: 6 taps unlock→committed lambing, 1 tap foster reassignment, 2 taps repeat treatment**,
  counted with keyed finders, never with elapsed wall time (`FakeAsync` makes that noise). Every
  committing action also gets a `tap(); tap();` double-tap test — cold wet fingers double-fire, and
  `WriteController.guard()` makes the second fire a no-op.
- **There is no birth-type chooser** (owner ruling P8): birth type is derived from tally strokes and
  labelled as derived, so the sixth tap in the budget is a stroke. 12 §10.1's
  ~~`lambing_entry.birth_type.twin`~~ predates the ruling; no test may select a birth type. The sixth
  tap is `lambing_entry.tally.stroke` (P8 ruled 2026-08-02, decision-record §7.0b).
- **There is no SnackBar** (owner ruling P2). The confirmation is the committed row on the page, so
  assert the row; `showSnackBar(` is banned everywhere, `feedback.dart` included. Undo is a time-boxed
  strike affordance in the row's own margin — assert the window **in seconds**, never as a widget's
  lifetime.
- Nothing monetization-related renders on a shed screen at any entitlement state, asserted at 99 ewes
  locked; `EntryContext.liveEntry` is never blocked, and no cap decision blocks 22:00–06:00.

## Fixtures, tags, flakiness

Two committed fixtures — `flock_400_3seasons.json` and `flock_15_at_cap.json`, real backup files
loaded with `restoreFixture(db, name)` **through `RestoreService`** (decision #74), so every fixture
load re-tests the one path where a bug loses five seasons. **Do not add a third without deleting
one.** Targeted `seedX(db, …)` helpers cover single-behaviour tests; screen-driving helpers
(`selectEwe`, `openNewTreatment`) stay private to the one file that uses them, never in
`test/support/`. `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` seeds through that same
path (00-README §9 step 8).

Every tag must be declared in `dart_test.yaml` (`golden`, `migration`, `uk-zone`, `policy`, `slow`,
`flaky`) — an undeclared tag makes `--tags` match nothing and the run is green **because it ran
nothing**. `flutter test` has no `-P`/`--preset`: use `--tags`/`--exclude-tags` with
`--test-randomize-ordering-seed random`. A test that fails once on CI and passes on rerun is fixed or
deleted that day; a `flaky`-tagged test carries an expiry date in its name and is excluded from CI.

## Definition of done

- [ ] In the R57 tier matching what it asserts, named for the property if in `test/policy/`, importing
      `package:flutter_test/flutter_test.dart`, with no `RegExp` duplicating a `check_policy` rule.
- [ ] Time installed one way only — a parameter, `atFixed` for a single instant, or nothing plus
      `pump` for elapsed — and every widget-tier `atFixed` says in a comment which it is.
- [ ] Anything time-shaped has a `uk-zone` case in the 01:00–01:59 hour, failing loudly in any other
      zone; widget tests go through `pumpApp` with a required `db` — no hand-built `ProviderScope`,
      no `FakeClock`, no overridden repository or controller.
- [ ] A new screen added a `kPumpableVariants` entry and updated the self-check counts; no cell
      deleted, no `textScaler` clamped to make one pass.
- [ ] Every `meetsGuideline` run opens `ensureSemantics()`; the 60 pt guideline is the only tap-target
      guideline used; the canary still fails.
- [ ] `flutter test --exclude-tags golden --test-randomize-ordering-seed random` green, then the three
      `TZ` commands green, and no golden regenerated.
