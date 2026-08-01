# N33-T03 — The tap-target sweep, the geometric gate and the P9 ruling

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 3 of 9 |
| **Depends on** | N33-T02 |
| **Commit** | one commit · `test(design): the tap-target sweep and the P9 ruling` |

## 1. Why this task exists

The geometric gate over fourteen variants × three devices × two text scales, with the
40 × 40 canary failing the 60 pt guideline. **This task rules P9**: `00-README` step 19's ≥ 16 pt
separation against Indelible §4.5's 8–12 px. One of them becomes the executable number and the other
document is amended in this commit.

It is also the first time in the project that a gate measures every `ShedTapTarget` on a real screen.
`12 §7.3` is explicit that `MinimumTapTargetGuideline` **silently skips** a node whose painted rect
touches the view boundary — and `07 §20.1` puts the primary action of Quick Entry, Lambing Entry,
Foster and Pen Board in a full-bleed bottom action bar. Decision #100's *"plus a second geometric
gate"* is not belt and braces; it is the only gate that sees the app's most important button.

**Expect this task to go red on real screens, and treat the red list as a work queue.** T01 and T02
prove layout and labels; nothing before this measures a rect.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | **§6.3** (the geometric gate, printed in full, with `gapBetween`, the `Element`-identity finder and the tap-action check) · **§6.1** (the tap scale — `tapMin` 60, `tapPrimary` 72, `tapHero` 88, `gapMin` **16**, `gapDestructive` **32** — and the mm conversion behind it) · §6.2 (`ShedTapTarget`, and why a missing `Semantics(onTap:)` announces and then refuses) · §3.3 (`ShedTokens`' flat field list, including `gapMin`) · §3.4 (the `tap*` / `gap*` naming scheme) · §7 (the gesture ban) | the gate, the numbers and one side of P9 |
| `docs/design/indelible.md` | **§9** (the 3am compliance table — *"8–12px minimum gaps between adjacent targets"*, the sentence P9 is actually about) · **§4.5** (reach zones and the minimum target audit — every component's size, and *"the smallest target in the app is 64 × 64"*) · §4.1 (the spacing scale: `--s-2` 8, `--s-4` 16) · **§7.2** (the keypad grid: `117 × 3 + 8 × 2 = 367`) · **§7.9** (the ease group: `64 × 5 + 8 × 4 = 352` inside 361 available) · §7.8 (the stepper) · §7.3 (rows share edges; *"there is no top border and no gap"*) · §4.2 (2 px rules) | the other side of P9, and the arithmetic that decides it |
| `docs/engineering/12-testing.md` | **§7.3** (the four `_traverse` skip rules and why gate 2 exists) · **§7.4** (the cost split, the 84-run table, and *"`find.byWidget` is unusable"*) · **§7.5** (the canary, and why it calls `evaluate` directly) · §7.2 (`ensureSemantics`, also required by `getSemantics`) · §6.2 (the table this file iterates) · §11.1 (test naming) | the sweep's table, its cost and its canary |
| `docs/engineering/10-accessibility-and-i18n.md` | §6.1 (why the numbers are accessibility numbers, not generosity) · §6.2 (the gesture ban as a motor-accessibility requirement) · §6.3 (Switch Control and Voice Control — every interactive node reachable and named) · §11 rows 12, 13, 32 | why a 9 mm contact patch centred on a gap must resolve to exactly one row |
| `docs/engineering/CONVENTIONS.md` | §6 (the ruling log — this task adds one) · §2.11 (`ShedTokens`, `context.tokens`) · R57 · §1 · §5 | **BINDING**; and the mechanism a ruling takes |
| `docs/engineering/00-README.md` | **§8 step 19** (*"Every interactive element is ≥ 60×60 pt with ≥ 16 pt separation"*) · §2.2 (the 3am table) · §10 (the amendment rule) | the winning side of P9, and how to amend the losing one |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#100** (60 × 60 floor, 72–88 for the five primaries, **16 pt minimum gap**, enforced by the guideline **plus** a second geometric gate) · #101 (the gesture ban) · #115 | the decision that outranks a visual direction |
| `epics/00-PLAN.md` | §2 **P9** (the conflict, stated) | the row this task closes |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the geometric gate, its cost and its canary |
| `indelible-design-system` | §4.5 and §9 are one side of P9, and §7.2/§7.8/§7.9's three components are what the ruling re-spaces |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/tap_target_test.dart`
- **Test** — `'every interactive element is at least 60 pt and separated by the ruled distance, and the 40x40 canary fails'`
- **Why it is red today** — P9 is open, so the separation assertion cannot be written at all — there are two numbers and no ruling.

```bash
fvm flutter test test/design/tap_target_test.dart   # expect: failing, for the reason above
```

Sharpen it so the ruling is what makes it green rather than a literal. The separation assertion reads
`context.tokens.gapMin`, never `16.0` — a test with the number typed in cannot carry the amendment, and
the whole point of a ruling is that changing it changes one place. Write the assertion as
`anyOf(equals(0.0), greaterThanOrEqualTo(t.gapMin))` from the first line, and make the failure message
print both rects and the measured gap: *"targets closer than gapMin without touching"* is useless
without the number that was measured.

**Green.** The minimum code that passes, and nothing beyond it — rule P9, amend the losing document, and write the sweep with the ruled number.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 P9, ruled

**The conflict, stated precisely.** `00-README` §8 step 19 and decision #100 both say **≥ 16 pt**
between any two targets, and `06 §6.1` publishes it as the `gapMin` token. `indelible.md` §9's 3am
compliance table says *"8–12px minimum gaps between adjacent targets"*, and three of its components
build on 8: the keypad (`117 × 3 + 8 × 2 = 367`, §7.2), the ease group (`64 × 5 + 8 × 4 = 352`, §7.9)
and the stepper (§7.8). `00-PLAN.md` §2 cites the sentence as §4.5; it is in **§9**, and §4.5 is the
reach-zone and minimum-target-audit section the ruling also touches. Fix the citation while you are in
there.

**The ruling: 16 pt wins, and the gate's two legal values are 0 or ≥ `gapMin`.** Three reasons, in
descending order of authority:

1. **Decision #100 outranks a visual direction.** `06 §1` fixes what a direction may and may not
   change; the interaction floor is not on the list, and the decision record is BINDING. `06 §6.1`
   gives the measured argument — Parhi, Karlson & Bederson's 9.2/9.6 mm is the *ideal-conditions
   optimum for a bare, warm, dry thumb*, not a margin over it — and 8 px ≈ 1.3 mm of separation on a
   wet screen through a glove is not separation.
2. **The published assertion already forbids 8.** `06 §6.3`'s gate reads
   `anyOf(equals(0.0), greaterThanOrEqualTo(16.0))`: *touching* is legal, ≥ 16 is legal, and the band
   between them is not. Indelible's 8 px sits squarely inside the forbidden band. This is not a new
   constraint invented by the ruling; it is the constraint the design system already published.
3. **The arithmetic decides it.** Widen the ease group to 16 px gaps and it is `64 × 5 + 16 × 4 = 384`
   in the 361 px available — it does not fit, and shrinking a button below 64 breaks the 60 pt floor.
   Widen the keypad and it is `117 × 3 + 16 × 2 = 383` plus 24 px of sheet padding = 407 in a 393 px
   viewport. **The only arithmetic that works is gap 0**, which is Indelible's own ledger idiom:
   §7.3, *"rows share edges; there is no top border and no gap — the ruling is continuous, like a
   ledger."* Applying it to the keypad makes the keys **larger**, not smaller: `(393 − 24) / 3 = 123`
   px wide against today's 117.

**What is amended, in this commit**, per `CLAUDE.md`'s amendment rule:

- `indelible.md` §9's *"8–12px minimum gaps"* row → *"adjacent targets inside one grouped control share
  a 2 px rule and no gap; independent targets are ≥ 16 px apart"*, with the reason.
- `indelible.md` §7.2 → the keypad grid recomputed at gap 0: `123 × 3 = 369` inside the sheet, row
  height unchanged at 84 with shared 2 px rules.
- `indelible.md` §7.9 → the ease group at gap 0: `72 × 5 = 360` inside 361 available, which raises
  every ease button from 64 to 72 (`tapPrimary`) for free.
- `indelible.md` §7.8 → the stepper's `±` pair share their edge.
- `indelible.md` §4.5's minimum target audit → the two numbers that moved.
- `00-PLAN.md` §2's P9 row → struck, with the ruling and the §4.5 → §9 citation correction.
- `CONVENTIONS.md` §6 → **one numbered ruling** recording all of the above. Read §6's tail before you
  type a number: N00-T05, N16-T02, N16-T04 and N16-T05 have each claimed one past R74, and two of them
  claim **R75**. Take the next genuinely free number and list the files it touches.

**If the owner overturns this and 8–12 px wins**, the consequence is not one number: `06 §6.1`'s token
table, `06 §6.3`'s published assertion, `00-README` §8 step 19, §2.2's 3am table and decision #100 all
change together, and the gate's `anyOf` becomes a three-way. Say that in the PR body. Do not implement
around it and do not leave both numbers live.

### 5.2 The files, in `00-README` §8 order

**No schema, no domain, no data, no wiring, no controller. UI where a screen goes red, then tests, plus
the amendments.** Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/design/indelible.md` | **Amended.** §9, §7.2, §7.8, §7.9 and §4.5 — the five places the 8 px gap is arithmetic rather than prose |
| 2 | `docs/engineering/CONVENTIONS.md` §6 | **Amended.** One numbered ruling recording P9 and every file it touches |
| 3 | `epics/00-PLAN.md` §2 | **Amended.** The P9 row is struck with its ruling and the citation correction |
| 4 | `lib/core/ui/components/shed_keypad.dart` | **Edited only if red.** N13-T04 built it from `indelible.md` §7.2's 8 px grid. Under the ruling the keys share edges and widen to 123 px. This is the largest layout consequence in the task and it is on the 3am path |
| 5 | `lib/features/lambing/widgets/…` (the ease group) | **Edited only if red.** N16-T04's five buttons go from 64 × 64 with 8 px gaps to 72 × 72 touching |
| 6 | `lib/core/ui/components/…` (the stepper, and any `Row`/`Wrap` carrying `spacing: 8`) | **Edited only if red.** The gate names each one; work the list, do not guess it |
| 7 | `test/design/wcag.dart` | **Edit.** `double gapBetween(Rect a, Rect b)` is added here — `06 §6.3` calls it and no document declares it, and N10-T02 and N10-T03 already call it from the component tests |
| 8 | `test/design/tap_target_test.dart` | **Edit → the 84-run sweep.** N09-T08's single-widget version becomes the geometric gate: every `ShedTapTarget`'s rect, the separation rule, the tap-action check and the 40 × 40 canary |
| 9 | `test/design/gate_inventory_test.dart` | **Edit.** `tap_target_test.dart` now references `kPumpableVariants` too — T02 flipped the assertion, this task completes it |

### 5.3 The signatures

The helper `06 §6.3` calls and no document declares. Its subtlety is the diagonal case:

```dart
// test/design/wcag.dart
/// Edge-to-edge distance between two rects; 0 if they touch or overlap.
///
/// For a diagonal neighbour the gap is the LARGER of the two axis gaps, not the
/// Euclidean distance: two keypad keys offset by one row and one column are
/// separated by a full key on each axis and a thumb cannot land between them.
/// Using hypot() here makes every diagonal pair look further apart than it is
/// and quietly switches the rule off for a grid — which is the one control it
/// matters most for.
double gapBetween(Rect a, Rect b) {
  final dx = math.max(0.0, math.max(a.left - b.right, b.left - a.right));
  final dy = math.max(0.0, math.max(a.top - b.bottom, b.top - a.bottom));
  return math.max(dx, dy);
}
```

The sweep, from `06 §6.3`, iterating `12 §7.4`'s 84-run table and reading the ruled number off the
tokens:

```dart
// test/design/tap_target_test.dart — GATE 2, the geometric one. It exists
// because MinimumTapTargetGuideline skips edge-flush and semantics-free nodes
// (12 §7.3), and 07 §20.1 puts every primary action in a full-bleed bottom bar.
for (final entry in kPumpableVariants.entries) {
  for (final device in Device.all) {
    for (final scale in const [1.0, 2.0]) {          // 84 runs; bold is not an axis
      testWidgets('${entry.key} · ${device.name} · scale $scale — geometry',
          (tester) async {
        final handle = tester.ensureSemantics();     // getSemantics needs it too
        addTearDown(handle.dispose);

        final db = await testDatabase();
        await restoreFixture(db, 'flock_400_3seasons.json');
        if (entry.key == 'quick_entry.export_banner') await armExportBanner(db);
        await tester.pumpApp(entry.value(), db: db, device: device, textScale: scale);

        final t = tester.element(find.byType(Scaffold).first).tokens;

        // find.byWidget is UNUSABLE here: two keypad keys can be equal Widgets
        // and getRect throws on a finder matching more than one element.
        final elements = find.byType(ShedTapTarget).evaluate().toList();
        final rects = <Rect>[
          for (final e in elements) tester.getRect(find.byElementPredicate((x) => x == e)),
        ];

        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].width, greaterThanOrEqualTo(t.tapMin),
              reason: 'target "${_labelOf(elements[i])}" is ${rects[i].width} wide');
          expect(rects[i].height, greaterThanOrEqualTo(t.tapMin));
        }

        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            if (!_couldBeAdjacent(rects[i], rects[j], t.gapMin)) continue;   // see §5.4
            final g = gapBetween(rects[i], rects[j]);
            expect(g, anyOf(equals(0.0), greaterThanOrEqualTo(t.gapMin)),
                reason: 'gap $g between ${rects[i]} and ${rects[j]} — P9: 0 or >= gapMin');
          }
        }

        // No built-in guideline checks this: an enabled button node with no tap
        // ACTION announces correctly and then refuses to activate (06 §6.2).
        for (final e in elements) {
          if ((e.widget as ShedTapTarget).onTap == null) continue;
          final node = tester.getSemantics(find.byElementPredicate((x) => x == e));
          expect(node.hasAction(SemanticsAction.tap), isTrue,
              reason: 'ShedTapTarget "${node.label}" is a button with no tap action');
        }
      });
    }
  }
}
```

The canary, from `12 §7.5`, verbatim in shape and deliberately not a `ShedTapTarget`:

```dart
testWidgets('CANARY: a deliberately 40x40 target FAILS the 60 pt guideline', (tester) async {
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

### 5.4 The details that are easy to get wrong

- **`find.byWidget` is unusable, and the tempting repair makes it worse.** Two keypad keys can be equal
  `Widget`s and `getRect` throws on a finder matching more than one element. The obvious fix — narrow
  the finder by key — quietly stops measuring the twelve keys that most need measuring. Match on
  `Element` identity. `06 §6.3` and `12 §7.4` both say this; it is repeated here because it is the one
  that gets "simplified" in review.
- **`getSemantics` needs the same live `SemanticsHandle` the guidelines need.** Both tests in this file
  open one. Without it the tap-action check throws rather than asserting.
- **The separation number is a token, not a literal.** `t.gapMin`, reached through `context.tokens`
  from an element inside the pumped tree. A `16.0` typed into the test cannot carry the amendment, and
  the ruling's whole value is that changing it changes one place.
- **`gapBetween` on a diagonal pair is the larger axis gap, not `hypot`.** See the doc comment above.
- **The pair loop is O(n²) and the flock list is 400 rows.** Only built rows exist, so a scrolled list
  yields tens rather than hundreds — but `Wrap`-heavy screens still make the naive loop the slowest
  thing in the suite. Skip pairs whose rects are more than `gapMin` apart on **both** axes; that is not
  an approximation, it is the definition of "adjacent" the rule uses.
- **Rule 4 of `_traverse` is why this file exists, and the mitigation must not be removed.** Gate 1
  skips any node whose painted rect touches `Offset.zero & view.physicalSize`, so a full-bleed bottom
  action bar is **never** checked by it. `pumpApp`'s `EdgeInsets.only(top: 47, bottom: 34)` keeps the
  bar off the boundary *and* this gate measures it regardless. A run that overrides the padding to zero
  disables both halves at once.
- **A disabled `ShedTapTarget` is still size-checked and deliberately not action-checked.** It becomes
  enabled without moving, so it must already be 60 pt; and it must **not** expose
  `SemanticsAction.tap`.
- **`gapDestructive` is 32 and no automatic rule can find it.** The gate cannot know which target is
  destructive, so the 32 pt rule lives in the destructive component's own test (N10-T02), not here. Do
  not "improve" this sweep by inferring destructiveness from a label.
- **Two scales, not three; no bold.** 84 runs, the same reasoning and the same tempting consistency
  edit as T02. Bold changes glyph weight and text width, not the minimum-size constraints this gate
  asserts, and the matrix already catches the layout consequence.
- **The gate is expected to be red on real screens the first time it runs, and the red list is the
  work.** `06 §6.2` rule 2 names the class of bug it surfaces: *"if a target overflows its parent, the
  taps are silently dropped even with `Clip.none` — restructure the layout instead."* That is a
  real-device bug and this is the first mechanism that catches it on a laptop.
- **Spacing comes from `spacing:` on `Column`/`Row`/`Flex`, not from `SizedBox` soup** (`06 §6.2`).
  When a screen goes red, `spacing: t.gapMin` is usually the whole fix.
- **Do not run the tree-walking guidelines or `textContrastGuideline` here.** T02 owns the first;
  `contrast_test.dart` owns the second at 42 runs tagged `slow`. This file measures rects and reads one
  semantics action. The 84 runs here and the 84 in T02 are two different costs against one table, split
  on purpose.
- **The canary is a bare `Semantics` + `GestureDetector`, which `06 §6.2` bans in `lib/`.** It is under
  `test/`, where the ban does not reach, and it is deliberately the banned shape — comment it, or a
  future reader deletes it as a policy violation.
- **A target that is 60 pt at scale 1.0 and clipped at scale 2.0 fails here, not in the matrix.** The
  matrix asserts no overflow; a clipped-but-not-overflowing target is exactly the bug this gate is for.

### 5.5 The full test set

| File · case | What it asserts |
|---|---|
| `test/design/tap_target_test.dart` · `'every interactive element is at least 60 pt and separated by the ruled distance, and the 40x40 canary fails'` | **The anchor.** The size rule, the separation rule read from `t.gapMin`, and the canary — on one variant first, then across the table |
| `…` · **84 generated runs** `'<variant> · <device> · scale <n> — geometry'` | Every `ShedTapTarget` rect ≥ `tapMin` on both axes; every adjacent pair 0 or ≥ `gapMin`; every enabled target exposes `SemanticsAction.tap` |
| `…` · `'CANARY: a deliberately 40x40 target FAILS the 60 pt guideline'` | `shedTapTargetGuideline.evaluate(tester)` returns `passed: false` |
| `…` · `'CANARY: two targets 8 pt apart fail the separation rule'` | *canary.* The P9 band asserted to be forbidden. This is what stops the ruling being quietly reverted by a `spacing: 8` |
| `…` · `'a disabled ShedTapTarget is size-checked and not action-checked'` | *edge.* `onTap == null`: 60 pt still required, `SemanticsAction.tap` not required |
| `…` · `'the keypad's twelve keys share edges and each measures at least tapPrimary'` | *edge.* The ruling's largest consequence, asserted where it lands: gap 0 between neighbours, 72 pt minimum per key |
| `…` · `'the five ease buttons share edges and each measures at least tapPrimary'` | *edge.* The second consequence: `72 × 5 = 360` in 361 available |
| `…` · `'the bottom action bar is measured even though the tree-walking guideline skips it'` | *edge.* Pump Quick Entry and assert gate 2 measures **more** rects than gate 1 visited nodes — the proof that `_traverse` rule 4 is real and that this file is not redundant |
| `…` · `'the separation number is read from context.tokens and appears as no literal in this file'` | *edge.* Source text: no bare `16` or `16.0` inside an `expect` |
| `…` · `'a treatment row under withdrawal keeps 60 pt targets when the countdown wraps at 01:30 on 25 October'` | *edge, `uk-zone`.* `atFixed(DateTime(2026, 10, 25, 1, 30), …)` on the treatments variant, `Device.small`, scale 2.0. The countdown row grows a line in the repeated hour because the provenance label prints beside the clear date; the targets beneath it must still measure and must still be `gapMin` apart |
| `…` · `'a pen tile whose hours-penned spans the clocks-back night keeps its target geometry'` | *edge, `uk-zone`.* The tile reads **absolute** hours (DST-1), so the string is a character longer and the tile must not shrink its target to fit |
| `test/design/gate_inventory_test.dart` · `'tap_target_test.dart iterates kPumpableVariants'` | **Edited.** The post-sweep state for the second gate file |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every interactive element is at least 60 pt and separated by the ruled distance, and the 40x40 canary fails'` passes, and was seen to fail first for the stated reason
- [ ] P9 is ruled and the losing document amended in this commit
- [ ] the canary fails
- [ ] 84 runs, per `12 §7.4`'s cost split
- [ ] the ruled separation is a token, not a literal in the test
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the ruling is a numbered `CONVENTIONS §6` entry listing every file it touches, and `00-PLAN.md`'s P9 row is struck with the §4.5 → §9 citation correction
- [ ] `indelible.md` §9, §7.2, §7.8, §7.9 and §4.5 all carry the ruled geometry with their arithmetic recomputed
- [ ] the second canary — two targets 8 pt apart — fails, so the forbidden band is asserted and not merely described
- [ ] `find.byWidget` appears nowhere in the file; every rect is fetched by `Element` identity
- [ ] `gapBetween` is declared once, in `test/design/wcag.dart`, and returns the larger axis gap for a diagonal pair
- [ ] every enabled `ShedTapTarget` exposes `SemanticsAction.tap`; disabled ones are size-checked only
- [ ] the two ambiguous-hour cases exist and are tagged `uk-zone`
- [ ] every layout edit this gate forced is in this diff, and none of them shrank a target or a font

## 8. Verification

```bash
fvm flutter test test/design/tap_target_test.dart
fvm flutter test test/design/gate_inventory_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove both canaries and the ruling, reverting each:

```bash
# 1. Set one ShedTapTarget's minSize to 48.
fvm flutter test test/design/tap_target_test.dart   # expect: the size assertion, with the label
# 2. Put spacing: 8 back on the keypad row.
fvm flutter test test/design/tap_target_test.dart   # expect: 'gap 8.0 ... P9: 0 or >= gapMin'
# 3. Drop Semantics(onTap:) from ShedTapTarget.
fvm flutter test test/design/tap_target_test.dart   # expect: 'is a button with no tap action'
git checkout -- lib/
```

```bash
grep -rn "find.byWidget" test/design/                        # expect zero
grep -rn "8–12\|8-12" docs/design/indelible.md               # expect zero after the amendment
grep -rn "117 × 3 + 8\|64 × 5 + 8" docs/design/indelible.md  # expect zero after the amendment
grep -rn "spacing: 8\|SizedBox(width: 8" lib/core/ui lib/features   # expect zero between targets
fvm flutter test test/design/tap_target_test.dart --reporter expanded | tail -3   # expect 84 runs + 2 canaries
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(design): the tap-target sweep and the P9 ruling`
