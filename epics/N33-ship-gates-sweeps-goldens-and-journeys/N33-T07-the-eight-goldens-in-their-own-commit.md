# N33-T07 — The eight goldens, in their own commit

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 7 of 9 |
| **Depends on** | N33-T06 |
| **Commit** | `test(features): the eight goldens` |
| **Not one commit because** | two commits — the tests, then the eight PNGs alone. `00-README` §7.4 makes a golden re-baseline its own commit, always |

## 1. Why this task exists

Eight images — the budget — with real fonts loaded and a tolerant comparator, and **the
PNGs in their own commit**, per `00-README` §7.4's rule that a golden re-baseline is a deliberate act
never bundled with the change it re-baselines.

`12 §8.1` fixes the number at eight from the cost side, not the value side: goldens are OS-, font- and
Flutter-version-sensitive, so every one is re-baselined by hand whenever the toolchain moves. *"At
eight that is a five-minute chore. At seventy-two … it is a job nobody does, and an unmaintained golden
suite is worse than no golden suite because it trains you to `--update-goldens` without looking."*

A golden earns its place only where a **pixel** regression is a usability or safety regression no other
test can see. Everything else — does it overflow, is the target 60 pt, is the ratio 12:1 — is already
asserted more cheaply by T01, T03 and `contrast_test.dart`, and without a binary artefact.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§8.1** (eight, and why the number is small) · **§8.2** (the eight, one row each, with the edit it requires in `07 §21.2` and the two images note 04 proposed that are deliberately not goldens) · **§8.3** (`flutter_test_config.dart` and `TolerantFileComparator`, both printed, plus the *verify-the-comparator* instruction) · **§8.4** (OS and font sensitivity, and the five rules that pin it) · **§8.5** (the five-step re-baselining ritual) · **§8.6** (`golden_toolkit` discontinued, `alchemist` rejected with its reason, `golden_screenshot` belongs in `tool/`) · §5.1 (`pumpApp`, `palette`, `atFixed`) · §11.2 (`dart_test.yaml`'s `golden` tag) · §11.4 (the two Makefile targets and why they are two) | every image, the harness, the ritual and the budget |
| `docs/engineering/00-README.md` | **§7.1** (`test/features/goldens/*.png` is committed; there is no `test/golden/`) · **§7.2** (what is git-ignored) · **§7.4** (commits that must stand alone — a golden re-baseline is one of the three) | why this task is two commits |
| `docs/engineering/06-design-system.md` | §4.4 (`deepRed` — shipped and honestly labelled) · §4.5 (the high-contrast variants, and why the deep-red golden is at **standard** contrast) · §5.1–§5.4 (the type scale, the variable font, the w700 cap, tabular figures) · §11 (pen-board glanceability) | what three of the eight images are pinning |
| `docs/engineering/07-screens.md` | §21.2 (the golden row this task's list amends) · §10.3 (the withdrawal countdown's three states) · §12 (Season Summary and the spread chart) | the screens each image comes from |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#116** (≈8 images, dark theme, tagged `golden`, one runner, one exact Flutter version; **not** a per-PR gate) · **#70** (the chart is golden-tested at three data shapes) · #96 (both night-shift palettes ship) | the decisions that fix the list and the number |
| `docs/engineering/13-build-ci-release.md` | §1.3 (`goldens` verifies, `goldens-update` re-baselines) · §4.5 (`goldens.yml`, which T09 creates) | the two targets, and the job that will run them |
| `docs/engineering/CONVENTIONS.md` | **R57** (the test tree; there is no `test/golden/`) · §1 · §4.1 · §5 | **BINDING** on where the images live |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-goldens-rebaseline` | runbook, invoked by name — this is the ritual it describes |
| `shed-testing` | the comparator, the font loading and the eight-image budget |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/goldens_test.dart`
- **Test** — `'the eight goldens render with real fonts and match within the comparator tolerance'`
- **Why it is red today** — there are no goldens, and the images cannot exist before every screen does.

```bash
fvm flutter test test/features/goldens_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so a green run means what it says. Before the first `matchesGoldenFile`, assert
the **font actually loaded**: lay out a known string and check its width is not the Ahem width (Ahem
renders every glyph as a full-em box, so a five-character string at 20 px is exactly 100 px wide). And
assert the **comparator installed**: `goldenFileComparator` is a `TolerantFileComparator`. A suite that
renders tofu or compares pixel-exact passes for the wrong reason, and both failures look identical to a
correct run in the log.

**Green.** The minimum code that passes, and nothing beyond it — the eight tests, then `make goldens-update` **alone**, committed by itself.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The two commits, in order

**Commit 1 — `test(features): the eight goldens`.** The harness, the comparator, the eight tests, the
seeds and the two amendments. **No PNGs.** At the end of this commit the suite is red in the honest
way: eight tests with no baselines.

**Commit 2 — `test(features): the eight golden images, re-baselined`.** Eight binary files and nothing
else:

```
test/features/goldens/quick_entry_default.png
test/features/goldens/quick_entry_scale_2_0.png
test/features/goldens/quick_entry_deep_red.png
test/features/goldens/pen_board_12_pens.png
test/features/goldens/withdrawal_countdown_three_states.png
test/features/goldens/lambing_spread_one_day.png
test/features/goldens/lambing_spread_tight_18_days.png
test/features/goldens/lambing_spread_60_day_straggle.png
```

Its body is **one line** saying what changed and why, plus the exact command and the toolchain it was
run on:

```
TZ=Europe/London make goldens-update      # Flutter 3.44.8, macOS 26.2, first baseline
```

`00-README` §7.4 and `12 §8.5` both require the split. A re-baseline mixed into a feature diff is a
re-baseline nobody reviewed, and the review question for these eight is not *"did it change"* but the
one the suite exists for: **can you still read the tag number?**

### 5.2 The files, in `00-README` §8 order

**No schema, no domain, no data, no wiring, no controller, no UI.** Tests and one config hook — say so
in the commit message.

| # | File | Commit | What changes in it, and why |
|---|---|---|---|
| 1 | `test/support/tolerant_comparator.dart` | 1 | **New.** `TolerantFileComparator extends LocalFileComparator`, ~15 lines, `tolerance: 0.005`. `12 §5.3` already lists this file in the closed twelve-file `test/support/` set, so it is expected rather than new furniture |
| 2 | `test/flutter_test_config.dart` | 1 | **New or extended.** The SDK's per-project hook: `TestWidgetsFlutterBinding.ensureInitialized()`, `_loadAppFonts()`, then install the comparator. The framework scans **up** from each test file to the first one it finds or to `pubspec.yaml`, so one at `test/` covers everything under `test/` — and covers **nothing** under `integration_test/` |
| 3 | `test/support/seeds.dart` | 1 | **Edit.** Three targeted seeders the eight images need and the 400-ewe fixture does not guarantee: a twelve-pen board at three statuses, a treatment set producing all three countdown states, and three season shapes for the chart. `12 §5.2` puts targeted helpers here |
| 4 | `test/features/goldens_test.dart` | 1 | **New.** Eight `testWidgets`, each `tags: 'golden'`, each pumped with `atFixed` and a committed fixture, each ending in `matchesGoldenFile('goldens/<name>.png')` |
| 5 | `test/features/goldens/*.png` | **2** | **New, generated, alone.** Eight files, nothing else in the commit |
| 6 | `.gitignore` | 1 | **Edit, if needed.** `failures/` under `test/` is a CI artefact and is never committed (`12 §8.4` rule 5). Verify the rule exists rather than assuming |
| 7 | `docs/engineering/12-testing.md` §8.3 | 1 | **Amended, in this commit.** The printed comparator builds its `basedir` from a URI ending `test/features/golden_test.dart` — singular, and no such file exists. The directory is what matters, so the behaviour is right and the literal is a lie about a file. Make it name `goldens_test.dart` |
| 8 | `docs/engineering/07-screens.md` §21.2 | 1 | **Amended, in this commit.** `12 §8.2` states the edit it requires: 07's golden row keeps Quick Entry, Pen Board and the withdrawal control, takes decision #70's three chart shapes, and spends the remaining two images on **text scale 2.0** and the **deep-red palette** rather than on two more pen-board data shapes. 12 owns the golden policy; 07 adopts the list |

### 5.3 The signatures

The comparator. Fifteen lines is the whole argument against `alchemist`:

```dart
// test/support/tolerant_comparator.dart
// LocalFileComparator is documented as pixel-for-pixel exact with no tolerance.
// This is the one alchemist feature worth having (diffThreshold), hand-rolled.
final class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, {required this.tolerance});

  /// 0.5% of pixels. Small enough that a moved baseline or a changed weight
  /// fails; large enough to absorb the sub-pixel antialiasing difference two
  /// machines on the SAME Flutter version still produce.
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

The hook. `basedir` resolves off the file URI, so the **directory** is what decides where golden keys
resolve:

```dart
// test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  final cwd = Directory.current.path;
  goldenFileComparator = TolerantFileComparator(
    // The FILE name is arbitrary; the DIRECTORY is not. Keys are written
    // relative to test/features/, which is where goldens_test.dart and
    // goldens/ both live. (12 §8.3, amended in this commit.)
    Uri.parse('$cwd/test/features/goldens_test.dart'),
    tolerance: 0.005,
  );

  return testMain();
}

/// Golden files render 'Ahem' — solid black boxes — unless real fonts are
/// loaded. This app's goldens exist to prove LEGIBILITY, so a golden rendered
/// in Ahem is not merely wrong, it asserts the opposite of what it claims.
Future<void> _loadAppFonts() async {
  final loader = FontLoader('AtkinsonHyperlegibleNext')   // must equal the family the theme asks for
    ..addFont(rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext[wght].ttf'));
  await loader.load();
}
```

One golden, in the shape all eight share:

```dart
// test/features/goldens_test.dart
testWidgets('quick_entry_default', (tester) async {
  final db = await testDatabase();
  await restoreFixture(db, 'flock_400_3seasons.json');
  await atFixed(DateTime(2026, 3, 28, 3, 20), () async {
    await tester.pumpApp(const QuickEntryScreen(), db: db, device: Device.typical);
  });
  await expectLater(find.byType(QuickEntryScreen),
      matchesGoldenFile('goldens/quick_entry_default.png'));
}, tags: 'golden');
```

### 5.4 The eight, and what each pins

`12 §8.2`, with the pump each one needs:

| Image | What it pins that nothing else can | Pumped as |
|---|---|---|
| `quick_entry_default` | The 3am screen at rest. The whole product in one image | `Device.typical`, `night`, scale 1.0, `atFixed` 03:20 |
| `quick_entry_scale_2_0` | 60 pt targets, 40 pt digits and 18 pt body all survive the largest accessibility scale **legibly** — the matrix proves nothing overflowed, not that you can read it | `Device.small`, scale **2.0** |
| `quick_entry_deep_red` | The deep-red palette is legible, not merely different. **Standard** contrast, where the AA exception lives | `ShedPaletteId.deepRed`, `highContrast: false` |
| `pen_board_12_pens` | Glanceability: badge colour, hours-since-penned typography, arm's-length legibility at tile density | twelve pens across three statuses, `atFixed` so the hours are fixed |
| `withdrawal_countdown_three_states` | Active / clears today / cleared. Getting the colour semantics wrong here is a food-safety UI bug | three treatments seeded relative to the fixed instant |
| `lambing_spread_one_day` | The chart's degenerate case — one bar, and the axis still reads (#70) | one season, one day of births |
| `lambing_spread_tight_18_days` | The normal case, and the *"first 17 days"* marker (#70) | eighteen days |
| `lambing_spread_60_day_straggle` | Where bars get thin: the chart must **scroll horizontally inside its card** rather than shrink (#70) | sixty days |

**Three states, not five, on the countdown.** `NOT APPLICABLE` and `NOT RECORDED` are painted by the
treatment row with **no `ShedCountdown` in the tree** — `ShedCountdown` takes a `ClearsOn`, never a
`WithdrawalStatus`. Those two are T04's redundancy sweep, not a fourth panel in a PNG.

### 5.5 The details that are easy to get wrong

- **Ahem is the failure mode that looks like success.** Without `_loadAppFonts()` every glyph is a
  solid black box, the images are stable, the diffs are clean, and the suite asserts the opposite of
  legibility. The font family string passed to `FontLoader` must match the family the theme asks for
  exactly — a mismatch renders in the fallback and produces a golden that is stable and wrong.
- **Verify the comparator before you trust a green run** (`12 §8.3`). Corrupt one committed PNG by a
  single pixel and confirm the run still passes; corrupt 5 % of it and confirm the run fails with four
  images written to `failures/`. A comparator that silently failed to install produces a suite that
  passes for the wrong reason, which is indistinguishable from one that works.
- **Every golden is pumped with `atFixed` and a committed fixture, or the image changes every run.**
  Every screen in this app prints a time. This is the commonest cause of an unstable golden here and
  it presents as flake rather than as a bug.
- **`atFixed` freezes `appNow()`, so anything measuring *elapsed* time reads zero** (decision #113).
  The pen board's *hours since penned* is elapsed. Pin `now` and **offset the seed data** to the instant
  you want to be 26 h earlier; do not pin `now` and expect the tile to advance.
- **The process time zone is not pinned by anything in the harness, and it changes the images.**
  `pumpApp` pins the *locale* (`en_GB`) and `atFixed` pins the *instant*, but `Instant.local` reads the
  process zone. A developer in London re-baselines at 03:20 and a UTC runner renders 02:20 — eight
  diffs, no code change. **Run goldens under `TZ=Europe/London`, locally and in CI**, and make the two
  `Makefile` targets carry it. T09 lands the CI half; this task lands the `Makefile` half and the
  finding.
- **`make goldens` verifies; `make goldens-update` re-baselines.** A single target named `goldens` that
  passes `--update-goldens` is *"the single easiest way to green a broken golden — you type it to
  check, and it agrees with you."* Never run `--update-goldens` on CI (`12 §8.4` rule 4).
- **Keys are relative and there is no `test/golden/`.** `matchesGoldenFile('goldens/x.png')`, resolved
  against `basedir`, which comes from the `testFile` URI's directory. R57 fixes the tree.
- **`failures/` is a CI artefact and is never committed.** `LocalFileComparator` writes four images per
  failure — master, test, isolated diff, masked diff — which makes review trivial and makes an
  accidental commit large.
- **`golden_toolkit` 0.15.0 is discontinued on pub.dev** — a fact off its package page, not a judgement
  — which is why the widely-copied `loadAppFonts()` recipe is re-implemented as the fifteen lines
  above rather than imported. **`alchemist` 0.14.0 is rejected for this app specifically**: its
  headline CI feature replaces text with coloured blocks, destroying the exact property these eight
  images exist to prove. Adopt it the moment the local harness exceeds ~150 lines, and do not be
  precious about it. **`golden_screenshot` belongs in `tool/`**, never in `test/` — it is a
  release-asset pipeline, not a regression gate.
- **`expectLater(finder, matchesGoldenFile(...))`, and the finder is the screen, not `find.byType(MaterialApp)`.**
  Capturing the whole app includes the harness's `MediaQuery` padding as painted background and makes
  every image sensitive to a harness change.
- **Do not golden the PDF footer or the ewe-card summary line.** Note 04 proposed both and `12 §8.2`
  refuses both: a PDF footer is a **string** assertion (`Disclaimers.exportFooter` present in the text
  layer); goldening a rendered PDF page tests the `pdf` package. The summary line is covered by the
  matrix plus the a11y gates.
- **Eight is a budget, not a starting point.** A ninth image requires deleting one, and the deletion
  goes in the PR body with its reason.
- **The images are reviewed as images.** Open all four failure outputs for anything that moved, and ask
  the question the suite exists for, not *"did it change"*.

### 5.6 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/goldens_test.dart` · `'the eight goldens render with real fonts and match within the comparator tolerance'` | **The anchor.** The font-loaded check, the comparator-installed check, and the eight matches |
| `…` · the eight named cases, each `tags: 'golden'` | One `matchesGoldenFile` each, against `goldens/<name>.png` |
| `…` · `'the app font loaded — a five-character string at 20 px is not exactly 100 px wide'` | *edge.* The Ahem check, expressed as arithmetic rather than as a hope |
| `…` · `'goldenFileComparator is a TolerantFileComparator'` | *edge.* If `flutter_test_config.dart` did not run, this is the only thing that says so |
| `…` · `'exactly eight PNGs exist under test/features/goldens/'` | *edge.* The budget, as an assertion. A ninth image fails here |
| `…` · `'every golden test carries the golden tag'` | *edge.* An untagged golden runs in `ci-fast` on ubuntu and fails on font rendering — the confusing failure this prevents |
| `…` · `'no golden test reads the wall clock'` | *edge.* Source text: no `appNow(`, no `DateTime.now(`; every pump is inside `atFixed` |
| `…` · `'no golden captures MaterialApp'` | *edge.* Source text: the finder is the screen |
| `test/support/tolerant_comparator_test.dart` · `'a 0.4 percent difference passes and a 5 percent difference fails'` | *edge.* The tolerance, tested directly on synthetic byte arrays rather than by corrupting a committed file. This is what makes the manual corrupt-a-PNG step a confirmation rather than the only evidence |
| `test/features/goldens_test.dart` · `'the eight goldens are byte-identical under TZ=Europe/London and TZ=Europe/Dublin, and differ under TZ=Pacific/Chatham'` | *edge, `uk-zone`.* The zone finding, made executable: UK and Ireland are the same offset (the ruled region), and a hostile zone must move the pixels — which proves the images genuinely carry a local time and that pinning `TZ` is load-bearing rather than superstition |

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the eight goldens render with real fonts and match within the comparator tolerance'` passes, and was seen to fail first for the stated reason
- [ ] exactly eight images
- [ ] real fonts loaded — no tofu
- [ ] the PNGs are their own commit
- [ ] the comparator's tolerance is a constant with a reason
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] the stated commit exception in the header applies, and the commit message says why
- [ ] the comparator was verified by hand: one pixel corrupted still passes, 5 % corrupted fails with four images in `failures/`
- [ ] every golden is pumped with `atFixed` and a committed fixture, and a source-text case proves no golden reads the wall clock
- [ ] `make goldens` and `make goldens-update` both pin `TZ=Europe/London`, and the zone case proves why
- [ ] `failures/` is git-ignored and no image under it is committed
- [ ] the eight are `12 §8.2`'s eight, and `07 §21.2`'s golden row is amended in this commit to adopt the list
- [ ] `12 §8.3`'s `golden_test.dart` literal is corrected to the file that exists
- [ ] `alchemist`, `golden_toolkit` and `golden_screenshot` appear nowhere in `pubspec.yaml`'s `dev_dependencies` for this purpose
- [ ] the withdrawal golden shows **three** states, and no `ShedCountdown` is constructed for the two that have none

## 8. Verification

```bash
fvm flutter test test/features/goldens_test.dart
make goldens
make goldens-update
git status --short
```

Verify the comparator before you trust the green run — this is `12 §8.3`'s instruction, not optional:

```bash
# 1. One pixel. Expect: still green.
python3 - <<'PY'
p='test/features/goldens/quick_entry_default.png'
b=bytearray(open(p,'rb').read()); b[-40]^=0x01; open(p,'wb').write(b)
PY
TZ=Europe/London make goldens          # expect: PASS — the tolerance is doing its job
git checkout -- test/features/goldens/

# 2. Five percent. Expect: red, with four images per failure.
#    (Re-baseline one image against a deliberately wrong palette, then revert.)
TZ=Europe/London make goldens          # expect: FAIL
ls test/features/failures/             # expect: master / test / isolatedDiff / maskedDiff
git checkout -- test/features/goldens/
```

```bash
ls test/features/goldens/*.png | wc -l                 # expect 8
git check-ignore -v test/features/failures             # expect the ignore rule
grep -rn "appNow(\|DateTime.now(" test/features/goldens_test.dart   # expect zero
grep -rn "golden_toolkit\|alchemist" pubspec.yaml      # expect zero
TZ=Pacific/Chatham make goldens                        # expect FAIL — the images carry a local time
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the eight goldens`, then, separately and alone, the eight PNGs.
