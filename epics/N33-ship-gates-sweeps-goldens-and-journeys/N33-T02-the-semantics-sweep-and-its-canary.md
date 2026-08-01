# N33-T02 — The semantics sweep and its canary

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 2 of 9 |
| **Depends on** | N33-T01 |
| **Commit** | one commit · `test(features): the semantics sweep and its canary` |

## 1. Why this task exists

The tree-walking guidelines plus the headings assertion across all fourteen variants — and
the **canary that proves the gate can fail**, because a sweep nobody has watched fail is
indistinguishable from a sweep that asserts nothing.

`test/design/semantics_gate_test.dart` is the one file in `CONVENTIONS` R57's five that has never
existed. N09-T08 deliberately refused to create it as a placeholder — *"an empty gate file is worse
than a missing one: it looks like coverage"* — and left a comment naming this task. It is created here,
with its sweep, in one commit.

The file also settles a collision `12 §7.4` names and resolves: `06 §6.3` and `10 §7.3` both print the
same three guideline calls in two different files. `12` owns the tiers and splits them **by cost**,
which is the only axis that matters once both are correct. This task lands the cheap half — the
tree-walking guidelines and `headingLevel` — and amends the two documents that still print
`textContrastGuideline` inside it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§7.1** (the four real guideline constants, by their correct names, and `Evaluation`'s shape) · **§7.2** (`ensureSemantics` is not optional, and why it throws rather than passing vacuously) · **§7.3** (the four `_traverse` skip rules, verified against the SDK source) · **§7.4** (the cost split, the 84-run table, and the file this task creates — printed in full) · **§7.5** (the canary, and why it calls `evaluate` directly) · §7.6 (contrast, and why it is **not** in this file) · §6.2 (the table this file iterates) · §11.1 (test naming) | the sweep, its table, its discipline and its canary |
| `docs/engineering/10-accessibility-and-i18n.md` | **§7.3** (the automated half, printed — the version this task amends) · **§3.4** (`headingLevel` only; `header:` is a no-op on 3.44 and still compiles) · §3.1–§3.3 (what you get free, the eight label rules, tag numbers spelled out) · §3.5–§3.7 (the pen board, the keypad, the chart — the three hard cases the sweep walks) · §3.9 (traversal order) · §11 rows 1, 12, 13, 32, 33, 35 (the anti-patterns this file must not contain) | the guidelines, the heading rule and the house rule across every screen |
| `docs/engineering/06-design-system.md` | **§6.3** (the two gates, printed — the version this task amends) · §6.2 (`ShedTapTarget`, its required `semanticLabel` and its mandatory `Semantics(onTap:)`) · §6.1 (the 60 pt floor and where it comes from) | one half of the collision `12 §7.4` resolves |
| `docs/engineering/CONVENTIONS.md` | **R57** (`test/design/`'s five files, named) · §1 (the tree) · §4.5 (widget keys) · §5 (the words) | **BINDING** on the file name and the directory's contents |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#115** (`ensureSemantics()` before every `meetsGuideline`) · **#104** (`headingLevel: 1..6`; `header:` banned) · #100 (the 60 pt floor and its second gate) | the two decisions this file exists to hold |
| `epics/N09-.../N09-T08` | §5.1 rows 3–6, §5.3 last bullet | what already exists in `test/design/`, and the comment that names this task |
| `epics/00-PLAN-CRITIQUE.md` | **S7** (why the sweeps are here and not in E08) · §11.3 (this task's anchor, with its `[audit]` note putting it in `test/design/`) | why this file could not be written earlier |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the guidelines, the headings and the house rule |
| `shed-testing` | the sweep's cost split and its canary |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/semantics_gate_test.dart`
- **Test** — `'the canary widget with no semanticLabel fails the sweep'`
- **Why it is red today** — no sweep exists — N09 deliberately deferred it because there was nothing to iterate.

```bash
fvm flutter test test/design/semantics_gate_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion the way `12 §7.5` sharpens the other canary: call
`labeledTapTargetGuideline.evaluate(tester)` **directly** and assert `evaluation.passed` is `isFalse`,
with `reason: 'if this canary ever passes, the labelled-target gate above is dead'`. Do not negate
`meetsGuideline` — it is an `AsyncMatcher`, asserting that something fails one is awkward and easy to
get subtly wrong, and a canary you cannot read is not a canary. Then assert
`evaluation.reason`, which is a newline-joined string, **names the widget** — a canary that fails for
an unrelated reason is a canary that passes for the wrong one.

**Green.** The minimum code that passes, and nothing beyond it — the sweep over the fourteen variants at textScaler 1.0 and 2.0, `ensureSemantics()` first,
and the canary.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) plus two document amendments.** Nothing under `lib/` changes unless a variant goes red;
if one does, the missing `semanticLabel` or the missing heading is a one-line edit in the screen that
omitted it — never a lowered bar in this file.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/design/wcag.dart` | **Edit.** `const shedTapTargetGuideline` moves here, declared **once**. `12 §7.4` prints it in `semantics_gate_test.dart` and `06 §6.3` prints it in `tap_target_test.dart`; two files declaring two 60 × 60 guidelines is two constants that silently diverge on the first edit. `wcag.dart` is already the shared, non-`_test` file in `test/design/` (R57) and it is where a shared constant belongs |
| 2 | `test/design/semantics_gate_test.dart` | **New, with its sweep.** The 84-run table, `ensureSemantics()` first, `shedTapTargetGuideline`, `labeledTapTargetGuideline`, the `headingLevel > 0` assertion, and the canary |
| 3 | `test/design/tap_target_test.dart` | **Edit — comment only.** N09-T08's scope comment is updated: the tree-walking half has landed next door; the geometric half arrives at T03. The `const` it declared, if it declared one, now imports from `wcag.dart` |
| 4 | `test/design/gate_inventory_test.dart` | **Edit.** The file list becomes **five**, and N09-T08's *"none of them references `kPumpableVariants` yet"* assertion is **flipped**, not deleted: `semantics_gate_test.dart` must reference it, `tap_target_test.dart` will at T03, and `contrast_test.dart` at its own group. An inventory that still asserts the pre-sweep state is an inventory that fails the moment the sweeps land, and the tempting fix is to delete it |
| 5 | `docs/engineering/10-accessibility-and-i18n.md` §7.3 | **Amended, in this commit.** Its printed snippet runs `textContrastGuideline` inside the semantic gate. `12 §7.4` moved it to `contrast_test.dart` at 42 runs tagged `slow`, for a stated reason — it renders and samples every node's pixels. Remove the line and cite the split |
| 6 | `docs/engineering/06-design-system.md` §6.3 | **Amended, in this commit.** Same edit to its first block, plus the note that the `shedTapTargetGuideline` constant now lives in `test/design/wcag.dart` |

### 5.2 The signatures

The shared constant, and the two names that must never appear:

```dart
// test/design/wcag.dart — declared ONCE; imported by semantics_gate_test.dart
// and tap_target_test.dart. 06 §6.3 and 12 §7.4 each printed it in their own
// file; two constants for one floor is one constant too many.
const shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/engineering/06-design-system.md#6-tap-targets-hit-slop-and-separation',
);

// androidTapTargetGuideline (48x48) and iOSTapTargetGuideline (44x44) are both
// BELOW this app's floor. Running either is a gate that passes while the
// product fails. They are named here so nobody copies a tutorial that uses one,
// and a policy case asserts neither appears anywhere under test/. (12 §7.1)
```

The sweep, from `12 §7.4`, with the discipline that makes it real:

```dart
// test/design/semantics_gate_test.dart
// 06 §6.3 and 10 §7.3 own the ASSERTIONS; this file owns the table and the
// ensureSemantics discipline. The pixel-sampling contrast run is NOT here —
// it is 42 runs in contrast_test.dart, tagged `slow` (12 §7.6).
for (final entry in kPumpableVariants.entries) {     // 12 §6.2's table, from the harness
  for (final device in Device.all) {
    for (final scale in const [1.0, 2.0]) {          // NOT kTextScales — see §5.3
      testWidgets('${entry.key} · ${device.name} · scale $scale — 60 pt floor',
          (tester) async {
        final handle = tester.ensureSemantics();     // decision #115
        addTearDown(handle.dispose);

        final db = await testDatabase();
        await restoreFixture(db, 'flock_400_3seasons.json');
        if (entry.key == 'quick_entry.export_banner') await armExportBanner(db);
        await tester.pumpApp(entry.value(), db: db, device: device, textScale: scale);

        // Gate 1 — the tree-walking guidelines. They skip edge-flush and
        // semantics-free nodes, which is why gate 2 (T03) exists (12 §7.3).
        await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // 10 §7.3, decision #104: at least one real heading per screen — on all
        // FOURTEEN variants, not on twelve (10 §3.4).
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

The canary. It is the anchor, and it is the only test in the file that pumps a widget of its own:

```dart
testWidgets('the canary widget with no semanticLabel fails the sweep', (tester) async {
  final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 72, height: 72,                       // big enough — SIZE is not the point
          child: GestureDetector(
            onTap: () {},
            child: const ColoredBox(color: Color(0xFF000000)),
          ),
        ),
      ),
    ),
  ));

  final evaluation = await labeledTapTargetGuideline.evaluate(tester);
  expect(evaluation.passed, isFalse,
      reason: 'if this canary ever passes, the labelled-target gate above is dead');
});
```

### 5.3 The details that are easy to get wrong

- **`ensureSemantics()` is not a nicety and it does not fail soft.** Without a live `SemanticsHandle`
  the guideline's traversal reads `view.owner!.semanticsOwner!.rootSemanticsNode!` and
  `semanticsOwner` is null — that is a **null-check throw**, not a vacuous pass. `04 §6.1` describes it
  as passing vacuously and is wrong; c2 §6 checked the source. The practical verdict is the same and
  slightly worse: the gate cannot run at all. Decision #115 makes the two lines mandatory, and
  `addTearDown(handle.dispose)` — not an inline `dispose()` — is what stops a failing `expect` leaking
  the handle into the next test in a randomised-order run.
- **`meetsGuideline` is matched against the `WidgetTester`, not against a finder.**
  `expectLater(tester, meetsGuideline(g))`. `expectLater(find.byType(X), meetsGuideline(g))` compiles
  and means nothing.
- **The canary's target is 72 × 72, on purpose.** It is testing the *labelled* guideline, so it must be
  comfortably above the size floor: a 40 × 40 unlabelled box fails for two reasons and proves neither.
  T03's canary is the size one, at 40 × 40, against `shedTapTargetGuideline`. Two canaries, one
  property each.
- **The canary uses a bare `GestureDetector`, which is banned in `lib/`.** `06 §6.2` makes
  `ShedTapTarget` the only sanctioned way to make something tappable. The canary is under `test/`,
  where the ban does not reach, and it is deliberately the shape the ban exists to prevent — that is
  what makes it a canary. Say so in a comment, or a future reader deletes it as a policy violation.
- **Two scales here, three in the matrix.** 14 × 3 devices × 2 scales = **84 runs**. Bold is excluded
  because it changes glyph weight and text width, not the minimum-size constraints these gates assert,
  and the matrix already catches the layout consequence (`12 §7.4`). Writing `kTextScales` here makes
  it 126 runs and buys nothing — and it is the obvious "consistency" edit, so it will be proposed.
- **`textContrastGuideline` does not belong in this file.** It renders and samples every node's
  pixels — seconds, not milliseconds — and contrast does not vary with device width. `12 §7.6` puts it
  in `contrast_test.dart` at 42 runs (14 variants × 3 palettes, `Device.small`, scale 1.0), tagged
  `slow`. Adding it here turns an 84-run file that runs on every push into one that does not.
- **The built-in guideline skips four classes of node and three of them are live risks here**
  (`12 §7.3`, verified against `packages/flutter_test/lib/src/accessibility.dart`): a node merged into
  its parent; a node with no `tap` and no `longPress` action, or hidden, or a link; a node whose
  painted rect touches a `hasImplicitScrolling` ancestor's boundary; and a node whose painted rect
  touches the **view** boundary. Rule 4 means a full-bleed bottom action bar is never checked — and
  `07 §20.1` puts the primary action of Quick Entry, Lambing Entry, Foster and Pen Board in exactly
  that position. Two things mitigate it and both must stay: `pumpApp`'s home-indicator inset keeps the
  bar off the boundary, and T03's geometric gate measures it regardless. **This file is not sufficient
  on its own and must not be described as if it were.**
- **`simulatedAccessibilityTraversal()` needs the handle alive for the whole expression.** It walks the
  semantics tree lazily; evaluating `.any(...)` after the handle is disposed reads a dead tree.
- **`headingLevel`, never `header: true`.** `header:` became a no-op on both platforms in 3.44 and
  still compiles, so it fails silently — decision #104, and there is a gate row (`a11y.header_bool`)
  for the spelling. The assertion here is the behavioural half: *at least one* real heading per screen,
  on all fourteen variants. Note search and the banner variant are variants, not exceptions.
- **The banner variant's heading is Quick Entry's.** Variant 14 is the same screen in a different
  layout state; it does not get a second heading, and a sweep that demands one will send someone off to
  add a heading to a banner.
- **`isSemantics`, never `containsSemantics`** — deprecated in 3.41 and still all over blog snippets
  (`10 §11` row 33).
- **`MergeSemantics` and `OrdinalSortKey` are banned in `lib/`** (`a11y.merge_semantics`,
  `a11y.sort_key`) and both would make this sweep pass while the traversal is wrong: `MergeSemantics`
  joins child labels with newlines and takes the first handler, so an unlabelled sibling disappears
  behind a labelled one. If a variant only goes green after someone adds one, the screen is the defect.
- **`accessibility_tools` 2.8.0 runs in the debug app alongside these and its 48 × 48 default is below
  the floor.** It complements the house assertion and never replaces it. It is a `dev_dependency` that
  `lib/app.dart` imports behind `kDebugMode`, which is why it has a line in
  `tool/policy_allowlist.txt`'s `[dev_dependencies]` section — verify that line still exists rather
  than assuming it.
- **`gate_inventory_test.dart` must be edited in the same commit.** Its N09-T08 assertion is *"none of
  them references `kPumpableVariants` yet"*, which this task falsifies on purpose. Flip it to the
  post-sweep state; deleting the file to make it green removes the only thing that stops a sixth gate
  file appearing silently.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/design/semantics_gate_test.dart` · `'the canary widget with no semanticLabel fails the sweep'` | **The anchor.** `labeledTapTargetGuideline.evaluate(tester)` returns `passed: false` on a 72 × 72 unlabelled `GestureDetector`, and the reason names it |
| `…` · **84 generated runs** `'<variant> · <device> · scale <n> — 60 pt floor'` | `ensureSemantics()` first; `shedTapTargetGuideline` and `labeledTapTargetGuideline` both met; at least one node with `headingLevel > 0` |
| `…` · `'every screen has exactly one level-1 heading, and no screen has two'` | *edge.* `10 §3.4`'s hierarchy rule. Two `headingLevel: 1` nodes on one screen is a rotor with two tops |
| `…` · `'the banner variant shares Quick Entry's heading and does not add one'` | *edge.* Variant 14's traversal has the same level-1 label as variant 3 |
| `…` · `'the pen board announces a summary node before the first pen'` | *edge.* `10 §7.3`'s traversal example: the first label starts with `12 pens`, and pens follow row-major. The pen board is the screen where a grid's traversal order goes wrong invisibly |
| `…` · `'the keypad's twelve keys each expose a distinct label'` | *edge.* `10 §3.6`. Twelve identical labels is a Switch Control scan with twelve stops called "button" |
| `…` · `'the sweep is deterministic in the ambiguous hour'` | *edge, `uk-zone`.* `atFixed(DateTime(2026, 10, 25, 1, 30), …)`, all fourteen variants at `Device.small` scale 1.0. Every label containing a time is built by `formatters.dart` from a stored instant; a label built from the wall clock, or one that formats the repeated hour twice, makes this run flaky rather than red — which is why it is pinned rather than assumed |
| `test/design/gate_inventory_test.dart` · `'test/design/ holds exactly the five files R57 names'` | **Edited.** Five, not four, and no sixth |
| `…` · `'semantics_gate_test.dart iterates kPumpableVariants'` | **Flipped.** The post-sweep state, asserted rather than assumed |
| `…` · `'no file under test/ references androidTapTargetGuideline or iOSTapTargetGuideline'` | *edge.* Source text over `test/`. Both are below the floor; using either is a gate that passes while the product fails (`12 §7.1`) |
| `…` · `'every meetsGuideline call in test/design/ is preceded by ensureSemantics'` | *edge.* Source text: every file containing `meetsGuideline(` also contains `ensureSemantics()` and `addTearDown(handle.dispose)`. Decision #115, held by a machine instead of by review |
| `…` · `'no file under test/ uses containsSemantics'` | *edge.* Deprecated in 3.41 (`10 §11` row 33) |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the canary widget with no semanticLabel fails the sweep'` passes, and was seen to fail first for the stated reason
- [ ] `ensureSemantics()` begins every guideline run
- [ ] one heading per screen, on all fourteen variants
- [ ] the canary fails and is asserted to fail
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the file is **84 runs** — two scales, not three — and bold text is not an axis
- [ ] `shedTapTargetGuideline` is declared once, in `test/design/wcag.dart`, and imported by both gate files
- [ ] `textContrastGuideline` appears nowhere in this file, and `10 §7.3` and `06 §6.3` are amended in this commit to match `12 §7.4`'s split
- [ ] `test/design/` holds exactly five files, and `gate_inventory_test.dart`'s pre-sweep assertion is **flipped**, not deleted
- [ ] `androidTapTargetGuideline` and `iOSTapTargetGuideline` appear nowhere under `test/`
- [ ] a source-text case proves every `meetsGuideline` call in `test/design/` opens and tears down a handle
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/design/semantics_gate_test.dart
fvm flutter test test/design/gate_inventory_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the sweep is alive, three ways, reverting each:

```bash
# 1. Delete a semanticLabel from one ShedTapTarget on the pen board.
fvm flutter test test/design/semantics_gate_test.dart   # expect: 18 pen-board runs red, by name
# 2. Change one screen's heading to Semantics(header: true).
fvm flutter test test/design/semantics_gate_test.dart   # expect: the headingLevel assertion
# 3. Remove the two ensureSemantics lines from one run.
fvm flutter test test/design/semantics_gate_test.dart   # expect: a null-check THROW, not a pass
git checkout -- lib/ test/design/
```

```bash
grep -rn "androidTapTargetGuideline\|iOSTapTargetGuideline" test/   # expect zero
grep -rn "containsSemantics" test/                                  # expect zero
grep -c "textContrastGuideline" test/design/semantics_gate_test.dart # expect zero
ls test/design/                                                     # expect exactly five files
fvm flutter test test/design/semantics_gate_test.dart --reporter expanded | tail -3  # expect 84 runs + the canary
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the semantics sweep and its canary`
