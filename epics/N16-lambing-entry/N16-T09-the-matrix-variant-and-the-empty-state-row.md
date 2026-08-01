# N16-T09 — The matrix variant and the empty-state row

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 10 of 10 |
| **Depends on** | N16-T08 |
| **Commit** | one commit · `test(features): the lambing_entry matrix variant and empty state` |

## 1. Why this task exists

`lambing_entry` joins `kPumpableVariants` and the screen's empty state gets its own row —
the two files that keep the variant table honest. This is what survives of the old plan's *"screen
composition, ARB, semantics, the matrix variant and the tap costs"* closer task; everything else in it
was authored inside the widget tasks, which is what the plan always claimed.

The matrix is the best value-per-line in the suite: *"~30 lines of table-driven code buys 252
assertions across every screen the product has"* (`12 §6.1`). This screen contributes eighteen of
them, and it is one of only three variants that also carry the reachability assertion — because the
primary action is a 160 × 140 corner slab and pushing it below the fold is the failure the overflow
check alone cannot see.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1 (the fourteen variants and the 252 arithmetic)** · **§6.2 (`kPumpableVariants` lives in `test/support/harness.dart`, iterated by four files; the count is derived, never remembered)** · §6.3 (what a failure looks like, and the two legitimate fixes) · **§6.4 (reachability, and the vacuous-`Scrollable.controller` trap)** · §7.3–§7.4 (the semantics gates that iterate the same table) | the table, the cells and the reachability assertion |
| `docs/engineering/07-screens.md` | **§2.2 (*"4 Lambing Entry — never empty… Lambs list: 'No lambs recorded yet.' · 'Add a lamb'"*)** · §6.3 (Frame 1 and Filtered-empty are both impossible here) · §1.4 (the state vocabulary and the never-a-spinner rule) | the empty copy and which states exist |
| `docs/engineering/06-design-system.md` | §12 (`ShedEmptyState`: *"occupies the same box the populated content will"*, one line of copy, one action at the same `tapHero` control, no illustration, no spinner, no tour) | the component contract |
| `docs/design/indelible.md` | §9 screen 4 (*"every unset cell prints its gap and its `NOT RECORDED · SKIPPABLE` label"*) · §3.6 (the ease group's 3 + 2 wrap at ≥ 150%) · §4.4 (row heights) | what has to survive the matrix |
| `docs/engineering/CONVENTIONS.md` | §1 (`test/support/`, `test/features/`) · §3.2 · **R57** (the test tree) · **R58** (252 cells over 14 variants; the arithmetic follows the list) | where the table lives and how it is counted |
| `epics/00-PLAN-CRITIQUE.md` | **S3 (the matrix cannot call `restoreFixture` until N23 writes the fixtures)** · S7 (a gate written before the thing it gates) | how the cells are seeded today |
| `docs/research/00-tech-decisions.md` | §5 · #99 (**never clamp the text scale**) · #114 as amended by R58 · #71 (never a spinner) · #21 (frame 1) | the decisions applied |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the variant table, its derived count and the reachability assertion |
| `indelible-states-and-feedback` | the empty state and the box it must occupy |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'lambing_entry pumps at every device, text scale and bold state without overflow'`
- **Why it is red today** — the variant table has one entry and the new screen is not in it.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen it by pumping the **hard** state, not the easy one. A lambing with **five** lambs exercises
the five-bar gate, the five lamb sub-rows, the ease description printed to the right of a selected
button, a query mark in the margin and a two-line provenance header — all at once. An empty lambing
passes eighteen cells while proving almost nothing.

**Green.** The minimum code that passes, and nothing beyond it — the row, the empty state, and the extra reachability assertion `12 §6.2` requires for this
screen at the smallest device and textScaler 1.3.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller.** This is a UI-and-tests commit — one empty region and
one table row — which is why the commit type is `test(features):`.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Extended.** One row in `kPumpableVariants` and the `kSeedLambing` constant beside `kSeedEwe`. The table is declared **once**, here, because four files iterate it (`12 §6.2`) and a table copied four times is four tables that stop agreeing the first time a screen is added |
| 2 | `test/support/seeds.dart` | **Extended.** `seedLambingWithFiveLambs(db)` — the hard state. Seeds, **not** `restoreFixture`: the fixtures are written by `tool/seed.dart` through the restore path at N23 (critique defect S3), and `12 §6.2`'s published cells call a fixture that does not exist yet |
| 3 | `lib/features/lambing/widgets/lambs_empty.dart` | **New.** `ShedEmptyState` for the lambs region: *"No lambs recorded yet."* It occupies the same box the populated list will, so nothing shifts when the first stroke lands |
| 4 | `lib/l10n/app_en.arb` | **Extended.** One message with a `description`, taking the animal noun as a placeholder |
| 5 | `test/features/overflow_matrix_test.dart` | **The anchor**, plus the derived-count assertion and the reachability case |
| 6 | `test/features/lambing_entry_test.dart` | **Extended.** The empty region's own cases |

### 5.2 The signatures

The table row, in `12 §6.2`'s own shape:

```dart
// test/support/harness.dart — iterated by four test files (12 §6.2, §7.4, §7.6)
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.quickEntry:   () => const QuickEntryScreen(),          // N13-T07
  RouteNames.lambingEntry: () => const LambingEntryScreen(lambingId: kSeedLambing),
};
```

The coverage assertion, and the comment that keeps it honest until N33:

```dart
// test/features/overflow_matrix_test.dart
// The matrix cannot silently stop covering a screen someone added. This is the
// only place the count is DERIVED rather than remembered (R58).
//
// It is TWO today and it will be FOURTEEN at N33 — thirteen RouteNames screens
// plus the export-banner variant. Do not write 14 here: a hard-coded target
// makes this file red for eleven epics and it will be "fixed" by deleting it.
test('the matrix covers every screen that exists today', () {
  for (final route in kRoutesBuiltSoFar) {
    expect(kPumpableVariants.keys, contains(route),
        reason: 'route "$route" is not in the matrix');
  }
  expect(kPumpableVariants.length, kRoutesBuiltSoFar.length);
});
```

The reachability case, with the trap `12 §6.4` spends a paragraph on:

```dart
testWidgets('Lambing Entry: the slab is on screen without scrolling', (tester) async {
  final db = await testDatabase();
  await seedLambingWithFiveLambs(db);
  await tester.pumpApp(const LambingEntryScreen(lambingId: kSeedLambing),
      db: db, device: Device.small, textScale: 1.3);

  final slab = find.byKey(const Key('lambing_entry.tally.stroke'));
  expect(slab, findsOneWidget);
  expect(tester.getRect(slab).bottom, lessThanOrEqualTo(667 - 34),
      reason: 'hidden behind the home indicator');

  // Read the POSITION off ScrollableState, never `Scrollable.controller`. A
  // Scrollable built without an explicit controller has `controller == null`,
  // so a `.where((s) => s.controller?.position…)` filter is EMPTY on every
  // screen in this app and the assertion passes without asserting anything.
  final scrollable = tester.stateList<ScrollableState>(find.byType(Scrollable));
  expect(scrollable.where((s) => s.position.maxScrollExtent > 0), isNotEmpty,
      reason: 'the detail section scrolls; the slab and the tally never do');
});
```

### 5.3 The details that are easy to get wrong

- **Lambing Entry has no screen-level empty state, and adding one is the mistake.** `07 §2.2` and
  `07 §6.3` both say it: *"never empty — the row exists before the screen does."* Frame 1 is
  impossible (the row was committed before the push) and Filtered-empty is impossible (there is no
  filter). What is empty is the **lambs region**, and only until the first stroke.
- **The empty region must not duplicate the slab.** `06 §12` says `ShedEmptyState` carries *"one line
  of copy + one action, at the same `tapHero` control the populated screen uses"* — and on this screen
  that control is the corner slab, which is already on the page. Print the line; let the slab be the
  action. Two `+ LAMB` targets on a 3am screen is worse than none.
- **It occupies the same box the populated content will.** That is the whole contract: nothing shifts
  when the first lamb lands, so a thumb already travelling to a target does not miss it.
- **Never a spinner and never an illustration** (decision #71). `CircularProgressIndicator` under
  `lib/features/` is a gate row (`ui.spinner`), not a review remark; loading is a fixed-height
  placeholder or it is nothing.
- **The reachability assertion is not the overflow assertion.** `12 §6.4`: *"overflow is necessary and
  not sufficient — a layout can avoid overflowing by pushing the Save button below the fold."* Three
  variants carry it: Quick Entry, **Lambing Entry** and Foster, at the smallest device × textScaler
  1.3. On this screen the reachable thing is the slab.
- **The vacuous-filter trap is the one to copy carefully.** `Scrollable.controller` is `null` on every
  screen in this app, so a filter written against it is empty and the assertion passes without
  asserting anything. `ScrollableState.position` is always live once the widget has laid out. *"A
  reachability assertion that cannot fail is worse than no reachability assertion, because it occupies
  the slot where a real one would go."*
- **Note the direction of this screen's assertion.** Quick Entry asserts `maxScrollExtent == 0` —
  nothing on it scrolls. Lambing Entry is longer than a phone by design (`indelible.md` §9 screen 4
  lists a header, a tally row, n lamb rows, an ease group, four care lines, three detail fields and
  two attachment controls), so the **detail section scrolls and the slab does not**. Copying Quick
  Entry's assertion here fails for a correct layout, and "fixing" it by deleting the scroll is how the
  detail fields get cut.
- **Fix the layout, never the matrix** (`12 §6.3`). Deleting a cell is deleting the 3am test.
  `TextScaler.clamp`, `textScaleFactor` and `withClampedTextScaling` are banned outright (decision
  #99) and defeat Android 14+'s own non-linear curve. Wrapping user-facing text in a `FittedBox` is
  banned in review — shrinking a tag number to fit is the opposite of legible. The two legitimate
  fixes are a scroll view that is not on the primary-action path, or moving something off the screen.
- **The ease group's 3 + 2 wrap is exercised here for the first time across three devices.**
  `indelible.md` §3.6 calls it *"the one documented component wrap in the system"*, triggered at
  ≥ 150%. The matrix runs 1.0, 1.3 and 2.0, so the 2.0 cells are where it fires. If a cell fails
  there, re-lay the component — do not clamp the scale and do not drop a button.
- **Seed through `test/support/seeds.dart`, not `restoreFixture`.** Critique defect S3:
  `flock_400_3seasons.json` is written by `tool/seed.dart` **through the restore path** at N23, and
  `12 §6.2`'s published cells call it nine epics early. State the reason in the harness file once, or
  it gets rediscovered per screen.
- **The count is derived and it is two today.** `kPumpableVariants` was born with one entry at
  N13-T07; this makes two. R58's fourteen and the 252 arithmetic arrive at N33, and the arithmetic
  follows the variant list, never a remembered number. Writing `expect(kPumpableVariants.length, 14)`
  now makes the file red for eleven epics, and a permanently red test is a deleted test.
- **This task adds a row; it does not write a sweep.** The 84-run geometric tap-target gate
  (N33-T03), the semantics gate (N33-T02) and the pixel-sampling contrast group all iterate this same
  table and all arrive at N33. Critique defect S7 is a gate written before the thing it gates, made
  once; leave the comment in the harness saying which files will iterate this row.
- **Every variant must emit at least one `headingLevel > 0` node** (`12 §7.3`). This screen has the
  title from T01 and deliberately no level-2 headings (`10 §3.4`) — *"each is one task, and heading
  stops would add navigation to screens whose entire purpose is not having any."* The gate asserts at
  least one, so the title is load-bearing.
- **Nothing in this task is time-shaped**, so there is no `uk-zone` case. Say so; a DST case that
  cannot fail occupies the slot where a real one would go.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/overflow_matrix_test.dart` · `'lambing_entry pumps at every device, text scale and bold state without overflow'` | **The anchor.** Eighteen cells — 3 devices × 3 text scales × 2 bold states — on a lambing seeded with **five** lambs, an ease, a care event, a declared type that contradicts, and an edited time. `tester.takeException()` is null in each |
| `test/features/overflow_matrix_test.dart` · `'the matrix covers every screen that exists today'` | The count is derived from `kPumpableVariants.length`, never typed. Two today |
| `test/features/overflow_matrix_test.dart` · `'Lambing Entry: the slab is on screen without scrolling at the smallest device and textScaler 1.3'` | `12 §6.4`'s third variant. Position read off `ScrollableState.position`, never `Scrollable.controller` |
| `test/features/overflow_matrix_test.dart` · `'the ease group re-lays to 3 + 2 at textScaler 2.0 on the smallest device'` | `indelible.md` §3.6's one documented wrap, under matrix conditions |
| `test/features/lambing_entry_test.dart` · `'a lambing with no lambs prints No lambs recorded yet and offers no second add control'` | The empty region, and the slab is the only action |
| `test/features/lambing_entry_test.dart` · `'the lambs region occupies the same box empty as populated'` | Measure the region's rect before and after the first stroke; nothing shifts |
| `test/features/lambing_entry_test.dart` · `'the screen renders no CircularProgressIndicator and no illustration in any state'` | Decision #71, at every pumped frame |
| `test/features/lambing_entry_test.dart` · `'the screen emits at least one headingLevel greater than zero and no headingLevel 2'` | `12 §7.3` and `10 §3.4`'s table. Opens `tester.ensureSemantics()` with `addTearDown(handle.dispose)` |
| `test/support/harness.dart` (as exercised) · `'no matrix cell calls restoreFixture'` | Source text. Critique defect S3 — the fixtures do not exist until N23 |

**Nothing here is time-shaped.** No `uk-zone` case; T01, T02, T03, T04, T05, T06, T07 and T08 carry
the epic's zone-pinned cases between them.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. The matrix is what turns those prose claims into 18 mechanical assertions for this screen.
- **Never clamp the text scale** — `textScaleFactor`, `TextScaler.clamp` and `withClampedTextScaling` appear nowhere, and `FittedBox` never wraps user-facing text.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Fix the layout, never the matrix** — deleting a cell is deleting the 3am test.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'lambing_entry pumps at every device, text scale and bold state without overflow'` passes, and was seen to fail first for the stated reason
- [ ] the variant count is still derived, never typed
- [ ] the reachability assertion is present for this screen
- [ ] the empty state occupies the same box as the content
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the cells pump the **hard** state — five lambs, an ease, a care event, a contradiction and an edited time
- [ ] the reachability case reads `ScrollableState.position`, never `Scrollable.controller`
- [ ] the empty region prints one line and offers **no second add control**; the slab is the action
- [ ] no cell calls `restoreFixture`, and the harness says why in a comment
- [ ] `kPumpableVariants` is declared once, in `test/support/harness.dart`, and this task writes no sweep
- [ ] the screen emits at least one `headingLevel > 0` node and no `headingLevel: 2`
- [ ] nothing clamps the text scale and no `FittedBox` wraps user-facing text
- [ ] the ease group re-lays rather than overflowing at textScaler 2.0 on the smallest device

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/lambing_entry_test.dart
make check
make test
```

Reproduce one cell by name, the way `12 §6.3` says to when the matrix goes red:

```bash
fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'small · scale 2.0 · bold true'
```

```bash
grep -rn "restoreFixture" test/features/overflow_matrix_test.dart   # expect zero until N23
grep -rn "TextScaler.clamp\|textScaleFactor\|FittedBox" lib/        # expect zero
grep -rn "CircularProgressIndicator" lib/features/                  # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the lambing_entry matrix variant and empty state`
