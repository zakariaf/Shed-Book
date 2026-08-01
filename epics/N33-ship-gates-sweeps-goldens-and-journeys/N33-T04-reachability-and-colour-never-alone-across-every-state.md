# N33-T04 — Reachability and colour-never-alone across every state

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 4 of 9 |
| **Depends on** | N33-T03 |
| **Commit** | one commit · `test(features): reachability and colour-never-alone` |

## 1. Why this task exists

The primary action stays reachable without scrolling on the smallest device at
textScaler 1.3 — for Quick Entry **with the banner shown**, Lambing Entry and Foster — and no state
anywhere in the app is distinguishable by colour alone.

The two halves are the same argument twice. `12 §6.4`: *"Overflow is necessary and not sufficient: a
layout can avoid overflowing by pushing the Save button below the fold."* And `10 §5.1`: three of
colour, shape, word and position, with colour never one of the three on its own — because *"the
night-shift palettes deliberately destroy the hue channel"*, so a colour-only encoding is unreadable
in the mode the spec names twice. Both are properties the 252 cells and the 168 guideline runs before
this task cannot see.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.4** (the reachability assertion, printed in full, including the vacuous-filter trap and why `ScrollableState.position` is the only correct read) · §6.2 (the table and the cell body) · §5.1 (`pumpApp`'s `palette` and `highContrast` parameters, and the home-indicator inset) · §11.1 (naming a test for the property) | the three assertions and the trap that makes them real |
| `docs/engineering/10-accessibility-and-i18n.md` | **§5.1** (the rule, and the three reasons it binds harder here) · **§5.2** (the redundancy table — every state the app shows, with its token, shape, word and position) · **§5.3** (the gate: grayscale is manual; non-text contrast is 3:1 and **UNVERIFIED** pending an SDK grep) · §3.8 (the save receipt as a live region) · §11 rows 4, 14, 16, 19 | every row this sweep iterates, and what it may not claim to automate |
| `docs/engineering/07-screens.md` | **§5.3** (*"the keypad, the confirm bar and the recents strip never give up anything — the filtered-match list gives up rows first"*) · **§16.4** (the banner's layout consequence, and the same give-way order) · §20 rule 1 (primary actions in the bottom third; a top-right Done is banned) · §21.2 (the reachability row) | which screens carry the assertion, and what gives way when it fails |
| `docs/engineering/06-design-system.md` | §4.1–§4.6 (the palette registry; `night`, `amber`, `deepRed` and the three high-contrast variants) · §4.7 (photos are the only permitted `ColorFiltered`) · §11 (pen-board glanceability) | the three palettes each row is asserted under |
| `docs/design/indelible.md` | §2.7 (how status is encoded without relying on colour) · §2.6 (the red-shift variant, and the doubled strike where the hue channel disappears) · §6.2 (the six marks) · §7.5–§7.7 (the pen tile, the countdown, the stamp) | the shapes and words that carry the second and third channels |
| `docs/engineering/CONVENTIONS.md` | §2.7 (`WithdrawalPeriod` / `WithdrawalStatus` / `ClearsOn`) · §2.11 (`ShedPaletteId`, `context.tokens`) · R36 (the pen-tile status set) · R57 · §1 · §5 | **BINDING** on the type split the withdrawal rows turn on |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#114** (the reachability assertion, named) · #106 (colour is never the only channel) · #92 (the free-tier row is identical at 3 ewes and at 15) · #96 (both night-shift palettes ship, labelled honestly) | the decisions behind both halves |
| `docs/engineering/05-domain-correctness.md` | §9 anti-pattern 9 (`ShedCountdown` takes a `ClearsOn`, never a `WithdrawalStatus`) | why one of the four withdrawal rows is unconstructible rather than merely forbidden |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the reachability assertions and their variants |
| `indelible-marks-and-strikes` | the colour-never-alone rule and every shape that carries its second channel — bar, triangle, dashed outline, hatch, dash |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'the primary action is reachable without scrolling on the smallest device at textScaler 1.3, including with the banner shown'`
- **Why it is red today** — overflow is necessary and not sufficient: a layout can avoid overflowing by pushing the primary action below the fold, and nothing checks that today.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen it in the one way that decides whether it asserts anything at all. Read the scroll position off
**`ScrollableState.position`**, never off `Scrollable.controller`. A `Scrollable` built without an
explicit controller has `controller == null`, so a `.where((s) => s.controller?.position.maxScrollExtent > 0)`
filter is empty on **every screen in this app** and the assertion passes without asserting anything.
`ScrollableState.position` is always live once the widget has laid out. Then assert the confirm key's
`rect.bottom` is above the home indicator using `Device.small.size.height` and `pumpApp`'s bottom inset
as values, not as the literals `667` and `34`.

**Green.** The minimum code that passes, and nothing beyond it — the three reachability assertions and the colour-channel sweep.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) only.** Nothing under `lib/` changes unless a row of §5.2's table turns out to have no
second channel — in which case the widget gains a word or a shape, and the sweep is not relaxed.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/features/overflow_matrix_test.dart` | **Edit.** Three reachability assertions — Quick Entry **with the banner armed**, Lambing Entry, Foster — plus the negative that proves they can fail. N13-T07 landed the Quick Entry one in its without-the-banner form; this replaces it with the form `12 §6.4` prints |
| 2 | `test/features/redundancy_table_test.dart` | **New.** One case per row of `10 §5.2`, each pumped under all three palettes. **No authority names this path**; the task creates it on `test/features/no_monetization_test.dart`'s precedent — a widget test named for the property it holds rather than for the file under test (`12 §11.1`). It is not in `test/design/`, whose five files R57 closes |
| 3 | `test/support/seeds.dart` | **Edit, if needed.** Some §5.2 rows need a state the 400-ewe fixture does not contain — a stillborn lamb, a barren ewe season, an empty pen. Add the smallest targeted seeder for each; `12 §5.2` puts targeted helpers here and reserves fixtures for shape-at-volume |
| 4 | `docs/engineering/10-accessibility-and-i18n.md` §5.3 | **Edit — one paragraph.** §5.3 carries an **UNVERIFIED** note: grep the installed 3.44.8 SDK for `kMinimumRatioNonText` and for exported `AccessibilityGuideline` constants. Record the answer here. If public, wire the non-text contrast evaluation into `test/design/` and delete the manual step; if private, say so with the date and re-check on the next SDK bump. Either way the note stops being open |

### 5.2 The signatures

Reachability, in the form `12 §6.4` prints, with the trap called out where it lives:

```dart
// test/features/overflow_matrix_test.dart
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
  const homeIndicator = 34.0;                       // pumpApp's bottom inset
  expect(rect.bottom, lessThanOrEqualTo(Device.small.size.height - homeIndicator),
      reason: 'hidden behind the home indicator');

  // Read the POSITION off ScrollableState, never `Scrollable.controller`.
  // A Scrollable built without an explicit controller has `controller == null`,
  // so a `.where((s) => s.controller?.position…)` filter is empty on every
  // screen in this app and the assertion passes without asserting anything.
  final scrollable = tester.stateList<ScrollableState>(find.byType(Scrollable));
  expect(
    scrollable.where((s) => s.position.maxScrollExtent > 0),
    isEmpty,
    reason: '07 §5.3: the keypad, the confirm bar and the recents strip never '
            'give up anything — the filtered-match list gives up rows first',
  );
});
```

The redundancy sweep. The table is data, so the test is a loop over it and each row names its own
failure:

```dart
// test/features/redundancy_table_test.dart
/// 10 §5.2, one record per row. `word` is the ARB-resolved visible string that
/// must appear; `shapeKey` is the widget key of the non-colour mark. Colour is
/// deliberately NOT a field: a test that asserts two states have different
/// Colors asserts the OPPOSITE of this rule.
typedef RedundancyRow = ({
  String where,          // 'pen_tile', 'countdown', 'lamb_row', …
  String state,          // 'ready', 'loss', 'withdrawal_unknown', …
  Future<void> Function(AppDatabase db) seed,
  String word,           // 'READY', 'DEAD', 'NOT RECORDED', …
  Key shapeKey,          // the bar, triangle, dashed outline, hatch or dash
});

for (final row in kRedundancyRows) {
  for (final palette in ShedPaletteId.values) {     // night, amber, deepRed
    testWidgets('${row.where} · ${row.state} · ${palette.name} — word and shape',
        (tester) async { … });
  }
}
```

### 5.3 The details that are easy to get wrong

- **The vacuous filter is the whole task.** `12 §6.4` spends a paragraph on it and it is worth more
  than the line it costs: *"A reachability assertion that cannot fail is worse than no reachability
  assertion, because it occupies the slot where a real one would go — and this is the screen the whole
  15-second claim rests on."* `ScrollableState.position`, always. If you find yourself writing `?.` on
  a `controller`, stop.
- **Prove the assertion can fail before you trust it.** Add 200 pt of padding above the confirm bar,
  watch the assertion go red, revert. Every reachability assertion in this file gets that treatment
  once, and the negative case stays in the file as a permanent canary.
- **The banner must be armed, and the arming must be asserted.** Unarmed, the Quick Entry-with-banner
  assertion is the Quick Entry assertion run twice. `armExportBanner(db)` sets the four `app_settings`
  columns; `07 §16.2` also gates the banner on the hour, so a test pinned with `atFixed` into the
  22:00–06:00 window will never see it — the free tier and the banner are both silent at night.
- **1.3, not 2.0, and the difference is deliberate.** Decision #114 fixes reachability at textScaler
  1.3 on the smallest device. At 2.0 the screen is *allowed* to scroll; what is never allowed is an
  action reachable **only** behind a scroll (`06 §7`'s mitigation (c)), and that is the manual sweep's
  row 2, not an assertion. Do not "strengthen" this to 2.0 — you will either break a correct layout or
  weaken the rule to make it pass.
- **A test that compares two `Color`s asserts the opposite of colour-never-alone.** The rule is that
  colour is *not* the carrier. Assert the **word** (from the ARB, resolved through
  `AppLocalizations`) and the **shape** (by widget key). If you cannot name the shape's key, the shape
  does not exist and the row fails — correctly.
- **Shapes must be distinguishable in silhouette** (`10 §5.2`): bar, triangle, dashed outline, hatch,
  dash. Four differently-coloured circles is **one** shape, and it is Apple's own counter-example. A
  row whose `shapeKey` points at a generic badge is a row that has not been done.
- **`ShedCountdown` takes a `ClearsOn`, never a `WithdrawalStatus`.** Two of the four withdrawal rows —
  `NOT APPLICABLE` and `NOT RECORDED` — are painted by the treatment row itself, in the pixels the
  countdown would have occupied, **with no countdown widget in the tree**. `ShedCountdown(status)` does
  not compile, and that is the one place in §5.2's table where the compiler is the gate. A test that
  tries to construct all four through one widget is trying to build the defect the type split
  prevents.
- **`NOT RECORDED` is never `0` and never blank.** It is the presentation half of safety rule §12.1 and
  it belongs in this sweep because the redundancy table is where it is visible.
- **The `~` edited-time prefix has no spoken form and no grayscale form**, so the word `edited` travels
  with it in both channels (`07 §9.6`). Assert the word, not the glyph.
- **The free-tier row is identical at 3 ewes and at 15** (decision #92): `textSecondary` on
  `surfaceRaised`, no colour signal at all. Its §5.2 row has **none** in the colour column, which is
  correct and must not be "fixed" by giving it a status colour.
- **Three palettes, and `deepRed` is the one that matters.** It drops luminance as well as hue
  (decision #96), so it is where a second channel that was quietly a colour will fail. Iterate
  `ShedPaletteId.values`; do not hand-list two of the three.
- **Grayscale is not automatable and the sweep must not pretend otherwise.** `10 §5.3` makes it a
  per-release manual pass (`§7.2` row 6), and T06 records it. The automated half is word-and-shape
  presence; say so in the file's header comment so nobody later reads a green run as a grayscale pass.
- **Non-text contrast (WCAG 1.4.11, 3:1) is carried as UNVERIFIED and this task closes it.** The 3.44
  release notes list `kMinimumRatioNonText` and `UnlabeledLeafNodeEvaluation` in
  `packages/flutter/lib/src/widgets/_accessibility_evaluations.dart`, but the leading underscore means
  they may still be private. **Grep the installed SDK before writing any hand-rolled non-text check.**
  Record the answer in `10 §5.3`.
- **Foster's primary action is a one-tap reassignment** (N18-T02) and Lambing Entry's is the corner
  slab (N16-T02). Use the keys those tasks published; a reachability assertion that finds nothing
  passes `findsOneWidget` never — but a `findsNothing` typo passes silently, so assert
  `findsOneWidget` first, always.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/overflow_matrix_test.dart` · `'the primary action is reachable without scrolling on the smallest device at textScaler 1.3, including with the banner shown'` | **The anchor.** `quick_entry.confirm` found; `rect.bottom` above the home indicator; no `ScrollableState` with `maxScrollExtent > 0` |
| `…` · `'Lambing Entry: the slab is on screen without scrolling at 375x667 x 1.3'` | The second of decision #114's three |
| `…` · `'Foster: the reassign action is on screen without scrolling at 375x667 x 1.3'` | The third |
| `…` · `'CANARY: 200 pt of padding above the confirm bar fails the reachability assertion'` | *canary.* The assertion can fail. Without this, the vacuous-filter bug is undetectable |
| `…` · `'the reachability assertion reads ScrollableState.position and never Scrollable.controller'` | *edge.* Source text over the file. The trap, held by a machine rather than by memory |
| `…` · `'the banner variant's reachability run finds the banner first'` | *edge.* Otherwise it is the no-banner run, twice |
| `test/features/redundancy_table_test.dart` · one case per §5.2 row × 3 palettes | The row's word is present and its shape key is found, under `night`, `amber` and `deepRed` |
| `…` · `'the pen tile ready state reads its threshold as the user's rule, not as a claim'` | *edge.* `Ready — your 24 hour threshold`, never `Ready` alone (`10 §8.4`, spec §12.2) |
| `…` · `'a treatment with no recorded withdrawal prints NOT RECORDED, never 0 and never blank'` | *edge.* The §12.1 presentation half |
| `…` · `'a treatment with no applicable withdrawal prints NOT APPLICABLE and mounts no ShedCountdown'` | *edge.* `find.byType(ShedCountdown)` is `findsNothing`; the words differ from the row above |
| `…` · `'stillborn is its own word and is never folded into died'` | *edge.* `10 §5.2`'s lamb rows |
| `…` · `'the free-tier row is identical at 3 ewes and at 15'` | *edge.* Decision #92: same token, same shape, same copy — the one row with **no** colour channel by design |
| `…` · `'an edited time carries the word edited as well as the marker'` | *edge.* The `~` prefix has no spoken and no grayscale form |
| `…` · `'a lambing edited into the ambiguous hour prints both times and the word edited, in every palette'` | *edge, `uk-zone`.* `atFixed(DateTime(2026, 10, 25, 1, 30), …)`: the provenance row shows the effective time, the original, and `time edited by you` — three channels, none of them colour, in the repeated hour where the two times are one minute apart on the wall clock and an hour apart in absolute time |
| `…` · `'a withdrawal clearing on the clocks-back day prints one clear date in every palette'` | *edge, `uk-zone`.* The clear date is stored once at write time; a row that renders two candidates has recomputed it |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the primary action is reachable without scrolling on the smallest device at textScaler 1.3, including with the banner shown'` passes, and was seen to fail first for the stated reason
- [ ] all three reachability assertions pass
- [ ] every state has a second, non-colour channel
- [ ] the red-shift palette is covered by the same assertions
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the assertions read `ScrollableState.position`; `Scrollable.controller` appears nowhere in the file, proved by a source-text case
- [ ] the padding canary exists and was watched failing
- [ ] every row of `10 §5.2` has a case, and each runs under all three `ShedPaletteId` values
- [ ] no case in `redundancy_table_test.dart` compares two `Color`s
- [ ] `find.byType(ShedCountdown)` is `findsNothing` for both the `NOT APPLICABLE` and the `NOT RECORDED` rows
- [ ] `10 §5.3`'s **UNVERIFIED** non-text-contrast note is closed with the SDK grep's answer and today's date
- [ ] the two ambiguous-hour cases exist and are tagged `uk-zone`
- [ ] the file's header comment says plainly that grayscale is a manual pass and that a green run is not one

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/redundancy_table_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Close the SDK question before you write a line of non-text contrast checking:

```bash
FLUTTER_ROOT=$(fvm flutter --version --machine \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["flutterRoot"])')
grep -rn "kMinimumRatioNonText" "$FLUTTER_ROOT/packages/flutter/lib/src/widgets/"
```

Prove the reachability assertions can fail, reverting each:

```bash
# 1. Add 200 pt of padding above the confirm bar.
fvm flutter test test/features/overflow_matrix_test.dart   # expect: 'hidden behind the home indicator'
# 2. Wrap the keypad in a SingleChildScrollView.
fvm flutter test test/features/overflow_matrix_test.dart   # expect: the maxScrollExtent assertion
# 3. Remove the word from one §5.2 row and leave its colour.
fvm flutter test test/features/redundancy_table_test.dart  # expect: three failures, one per palette
git checkout -- lib/
```

```bash
grep -rn "Scrollable.controller\|\.controller?\." test/features/overflow_matrix_test.dart   # expect zero
grep -rn "expect(.*Color" test/features/redundancy_table_test.dart                          # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): reachability and colour-never-alone`
