# N34-T03 — Startup measured on two real devices, in profile mode

| | |
|---|---|
| **Epic** | [N34 — Release engineering](epic.md) · `00-README` §9 step 12 (3 of 3) |
| **Task** | 3 of 4 |
| **Depends on** | N34-T02 |
| **Commit** | one commit · `docs(perf): startup measured on two real devices` |

## 1. Why this task exists

The numbers that decide whether the first-frame work in N11 actually paid off — measured in
**profile** mode on two real devices, one of them the oldest supported, and written into
`docs/perf/measurements.md` with the device, the OS version and the date.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §6.2 | the budget, the three device classes, `--trace-startup`'s five keys, the Android `Displayed` cross-check, and why an emulator number is not evidence |
| `docs/engineering/13-build-ci-release.md` | §6.3 | `docs/perf/measurements.md` verbatim — the columns and the Method section |
| `docs/engineering/13-build-ci-release.md` | §6.1.1, §4.6 | the AAB download column is filled after upload, not by CI; frame times and startup are deliberately not automated |
| `docs/engineering/13-build-ci-release.md` | §1.3 | the `Makefile`'s `perf` target and its `DEVICE` variable |
| `docs/research/00-tech-decisions.md` | §5, #126 | CI gates size, not speed; hand-measured on two real devices per release |
| `docs/engineering/01-architecture.md` | §6 | what the first frame is required to be — a dark Quick Entry shell with an interactive keypad and no data |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — the measurement procedure |
| `shed-bootstrap-and-errors` | slow start and what may not move into `main()` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/perf_recorded_test.dart`
- **Test** — `'docs/perf/measurements.md records a startup measurement for two devices with dates'`
- **Why it is red today** — no measurement exists, and the first-frame claim rests on a design intention.

```bash
fvm flutter test test/policy/perf_recorded_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — measure, record, and assert the file's completeness. The assertion holds that there
are at least two data rows; that each names a device, an OS version and a date; that no device cell
contains `simulator`, `emulator` or `debug`; and that the Method section states profile mode, the
median of five cold starts and the force-stop between them.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached, and no code is written at all except the assertion. Say so in the commit
body. The work in this task is done with two phones on a desk.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `docs/perf/measurements.md` | **new.** 13 §6.3's shape verbatim — the header sentence, the table, the Method section — with the placeholder row replaced by two real rows |
| 2 | `RELEASES.md` | edit. One line under the table pointing at `docs/perf/measurements.md` and saying that the **AAB arm64 download** column is filled in *after* upload, from Play Console ▸ App Bundle Explorer |
| 3 | `test/policy/perf_recorded_test.dart` | the anchor, written first, carrying `@Tags(['policy'])`. One of its cases carries `tags: ['uk-zone']` — see §5.4 |
| 4 | `Makefile` | **check only.** N01-T05 already landed `perf: $(FLUTTER) run --profile --trace-startup -d $(DEVICE)` from 13 §1.3. If it is missing or has lost `--profile`, that is a defect in this task's path and it is fixed here |

### 5.2 The file

```markdown
# Measurements

Every row is from a physical device in profile or release mode.
A number from a simulator, an emulator or a debug build does not go in this file.

| Release | Build | Device | OS | Tap→first frame | DB open+migrate | Flock book PDF | AAB arm64 download | iOS install |
|---|---|---|---|---|---|---|---|---|
| v1.0.0 | 187 | iPhone SE (2020) | iOS 26.0 | | | | | |
| v1.0.0 | 187 | <low-end Android, API 29–30, 3 GB, no Vulkan> | Android 11 | | | | | |

## Method
- Startup: `flutter run --profile --trace-startup`, median of 5 cold starts, force-stopped between.
- DB open: `dev.TimelineTask('db.open')`, 400-ewe seeded database (`tool/seed.dart`).
- PDF: wall clock, 400 ewes, 3 seasons, battery < 20%.
- AAB: Play Console → App Bundle Explorer → arm64-v8a download size.
- iOS: Xcode Organizer → App Thinning Size Report.
```

### 5.3 The measurement, exactly

```bash
fvm flutter devices                       # get the two device ids

make perf DEVICE=<device-id>              # = fvm flutter run --profile --trace-startup -d <id>
cat build/start_up_info.json
```

`build/start_up_info.json` carries five keys (13 §6.2):
`engineEnterTimestampMicros` · `timeToFrameworkInitMicros` · `timeToFirstFrameMicros` ·
`timeToFirstFrameRasterizedMicros` · `timeAfterFrameworkInitMicros`.

The Android cross-check, which includes the OS-side cost `--trace-startup` structurally cannot see:

```bash
# APP_ID is the application id fixed in N01-T01. No document in this set writes it
# as a literal — read it, never type it.
APP_ID=$(grep -o 'applicationId *= *"[^"]*"' android/app/build.gradle.kts | sed 's/.*"\(.*\)"/\1/')
adb shell am force-stop "$APP_ID"
adb shell am start -S -W -c android.intent.category.LAUNCHER \
  -a android.intent.action.MAIN "$APP_ID/.MainActivity"
adb logcat -d | grep "Displayed"
```

The budget you are measuring against (13 §6.2), and both halves matter:

| Device class | Tap → first Flutter frame | Tap → keypad accepts a digit |
|---|---|---|
| iPhone SE (2020) / iPhone 11, iOS 26 | ≤ 700 ms | same frame |
| Mid-range Android, API 33–36, 4 GB (Pixel 6a class) | ≤ 900 ms | same frame |
| Low-end Android, API 29–30, 3 GB, no Vulkan | ≤ 1600 ms | same frame |

The headline budget is an **interactive keypad at the first frame**, and the first Flutter frame
**≤ 400 ms after `main()`** on the oldest target device.

The other two numbers in the row, because they are the two things that can quietly regress:

```bash
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42   # the 400-ewe database (N23)
# DB open + migrate: dev.TimelineTask('db.open'), read in DevTools ▸ Performance ▸ Timeline Events
# Flock book PDF: wall clock, 400 ewes, 3 seasons, on the slow Android, battery under 20%
```

### 5.4 What is easy to get wrong here

- **Profile mode is disabled on emulators and simulators.** A number from a simulator, an emulator, a
  hosted runner or a debug build is not evidence, does not go in the file, and is not a smaller
  version of the truth — it is a different measurement. This one fact is the entire reason CI gates
  size and not speed (#126, 13 §4.6). The anchor test enforces it against the device column, because
  the temptation to fill the file from a simulator on a day when the phone is at home is real.
- **"Two devices" means two *classes*, one of them the oldest supported.** The pair is the oldest
  iPhone (SE 2020 / 11) and the **low-end Android — API 29–30, 3 GB, no Vulkan**. Two current phones
  measure the machine you already knew was fast, and the 3am user is not on one.
- **Median of five cold starts, force-stopped between.** One run is noise. A second launch is a warm
  start and is a different number entirely; on Android that means `adb shell am force-stop` between
  every run, and on iOS it means killing the app from the switcher, not backgrounding it.
- **`--trace-startup` and `Displayed` measure different things and will not agree.** The trace begins
  at engine enter; `am start -S -W` and logcat's `Displayed` include the OS-side cost before Dart ever
  runs. Record both, label which is which, and do not treat the gap as an error — it is the part of a
  cold start Flutter cannot instrument.
- **`timeToFirstFrameMicros` is not "tap → first frame".** The budget table's column is measured from
  the tap; the 400 ms figure is measured from `main()`. Two different origins. Filing one under the
  other's heading makes a passing app look like it failed, or worse, the other way round.
- **The second half of the budget is the one that matters, and it is not in the JSON.** *"What kills
  you is a spinner between the tap and the first digit."* A 900 ms launch with an interactive keypad
  beats a 600 ms launch with a spinner. Measure "tap → keypad accepts a digit" by actually typing on
  it at first paint, and record it. The spec's 15-second median is dominated by the human: even a 1.6 s
  launch spends 11% of it.
- **The file is appended to, never rewritten** (13 §6.3). A row is a fact about a build. Editing an
  old row deletes the only performance history the project has, because there is no telemetry and
  there never will be.
- **The AAB arm64 download column is deliberately blank in this commit.** It can only be read *after*
  upload, from Play Console ▸ App Bundle Explorer (13 §6.1.1), which is why it is release-checklist
  item 7 and not a CI step. A test that requires it to be non-empty makes this task unfinishable —
  §5.5 asserts the opposite on purpose.
- **The DoD line "a regression against the recorded number is a release blocker" is a checklist item
  with a name against it, not a gate — and writing the gate is the specific mistake #126 forbids.**
  No CI job may assert a frame time or a startup latency. The blocker lives in
  `docs/release-checklist.md` item 7 (N34-T04).
- **`APP_ID` appears as a literal in no document in the set** (13 §6.2's own comment). Read it out of
  `android/app/build.gradle.kts` with the `grep`/`sed` line above. Typing it is how the two platforms
  quietly end up with different ids, which can never be fixed on either store.
- **The PDF number wants the battery under 20%**, so thermal throttling is in play. That is the honest
  number for a shepherd whose phone has been in a cold shed all night, not the best one.
- **This is the project's one measurements file and other documents already point at it.** The font's
  byte count and `wght` axis range (06 §14), the typical bytes for a 2048 px / q80 photo (08 §7) and
  the PDF font-subsetting figure (09) all land here. Do not create a second file; do not reformat the
  table so their rows stop fitting.
- **The date column is a civil date, not an instant, and that is where the time-shaped bug is.** Rows
  are dated `d MMM y` (R60). A parser that builds a local `DateTime` from a bare date is fine 363 days
  a year and wrong on two: on the clocks-forward Sunday a wall time in the missing hour does not exist,
  and on the clocks-back Sunday 01:00–01:59 happens twice. The parser reads a `LocalDate` and
  constructs no `DateTime`; §5.5 has the case, tagged `uk-zone`.

### 5.5 The test set

`test/policy/perf_recorded_test.dart` — one file, `@Tags(['policy'])`, reading
`docs/perf/measurements.md` and `RELEASES.md` as text.

| Test | What it holds |
|---|---|
| `'docs/perf/measurements.md records a startup measurement for two devices with dates'` | the anchor. At least two data rows, each with a device, an OS version and a date |
| `'no row is from a simulator, an emulator or a debug build'` | the device and OS columns carry none of those three words. The file's own header sentence, made executable |
| `'at least one row is the oldest supported device class'` | one row is an iPhone SE (2020) / 11 class device **or** an Android at API 29–30, per 13 §6.2's table. Two fast phones is not a measurement set |
| `'the Method section states profile mode, the median of five and the force-stop between runs'` | the four Method lines survive; a Method section that decays into "we ran it a few times" makes every row unreproducible |
| `'a row with a blank AAB download column is still valid'` | the deliberate exception, asserted so nobody "fixes" the file by demanding a number that does not exist until after upload |
| `'a row dated on the clocks-back Sunday parses as a civil date and constructs no DateTime'` | `tags: ['uk-zone']`. 25 October 2026, the ambiguous hour **01:00–01:59** — the wall time that occurs twice. The row parses to exactly one `LocalDate`, the parser never calls `DateTime(` or `DateTime.parse(`, and the same assertion is run for the clocks-forward Sunday whose 01:30 does not exist at all |
| `'docs/perf/measurements.md is the only measurements file in the repository'` | one file, one record. A second copy is how two numbers for the same build end up disagreeing |
| `'no workflow asserts a startup latency or a frame time'` | #126 in the negative, over all three workflow files. The pair to N34-T01's size case |

The `uk-zone` case is a **third** zone-tagged test outside `test/domain/` — which is precisely why
12 §14 amendment A makes `ci.yml`'s `TZ=Europe/London --tags uk-zone` step **unscoped**. A `test/domain`
path scope would run this case in the runner's UTC, where a spring-forward assertion passes vacuously
because there is no spring forward.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. Nothing in this task adds a dependency; `--trace-startup` and `adb` are toolchain, not app code.
- **No CI perf assertion, in either direction** (#126). Profile mode is disabled on emulators, so any number a hosted runner produces is noise — and a gate built on noise gets disabled, which is worse than not having one.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'docs/perf/measurements.md records a startup measurement for two devices with dates'` passes, and was seen to fail first for the stated reason
- [ ] two devices, one of them the oldest supported
- [ ] profile mode, not debug
- [ ] the date and OS version are recorded
- [ ] a regression against the recorded number is a release blocker
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/perf_recorded_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

The measurement itself, in order, with both phones on the desk:

```bash
fvm flutter devices

# Device 1 — the oldest supported iPhone. Five cold starts, killed from the switcher between.
make perf DEVICE=<iphone-id>
cat build/start_up_info.json

# Device 2 — the low-end Android. Five cold starts.
make perf DEVICE=<android-id>
cat build/start_up_info.json

# The OS-side cross-check that --trace-startup cannot see.
APP_ID=$(grep -o 'applicationId *= *"[^"]*"' android/app/build.gradle.kts | sed 's/.*"\(.*\)"/\1/')
adb shell am force-stop "$APP_ID"
adb shell am start -S -W -c android.intent.category.LAUNCHER \
  -a android.intent.action.MAIN "$APP_ID/.MainActivity"
adb logcat -d | grep "Displayed"

# The other two columns, on the slow Android.
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42
# DB open + migrate: DevTools ▸ Performance ▸ Timeline Events, the dev.TimelineTask('db.open') span.
# Flock book PDF: export it from the app by hand and time it by wall clock, battery under 20%.
```

Then do the thing no number can tell you: **launch it and try to type a tag on the first frame.** If
there is a spinner, a splash that outstays the frame, or a keypad that is drawn but not yet listening,
the numbers above are irrelevant and the finding belongs in N11's territory, not in this row.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs(perf): startup measured on two real devices`
