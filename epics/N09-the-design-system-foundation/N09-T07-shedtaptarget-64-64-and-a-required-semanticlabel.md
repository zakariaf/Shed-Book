# N09-T07 — `ShedTapTarget` — 64 × 64 and a required `semanticLabel`

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 7 of 9 |
| **Depends on** | N09-T06 |
| **Commit** | one commit · `feat(ui): ShedTapTarget with a required semanticLabel` |

## 1. Why this task exists

The tap primitive every control is built on: a **required** `semanticLabel`, a 64 × 64
minimum build box against the 60 pt floor's four points of headroom, generous hit slop for cold
fingers through a bag, and `Semantics(onTap:)` so a screen reader has something to announce.

It is also the only sanctioned tap surface in the app (`06 §6.2`, `§12`), which is what makes the two
gates in N33 possible at all: they find targets by `find.byType(ShedTapTarget)`, so a control built
on a bare `InkWell` is invisible to every one of them. Fifteen components in N10 and twelve screens
after that inherit whatever this file gets right or wrong.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §6.1 (the tap scale, and why 60 is the floor rather than a margin) · §6.2 (**the full `ShedTapTarget` body and the two hit-slop rules**) · §6.3 (the two gates and the `find.byWidget` trap) · §7 (the gesture ban) · §12 (the component contract) | the class, its parameters, its semantics |
| `docs/design/indelible.md` | §4.5 (**the minimum-target audit — the smallest target in the app is 64 × 64**) · §5.1 (a press is a fill change only: no scale, no lift, no ripple) · §7.1–§7.2 (a disabled slab is still a target; no keypad key is ever disabled) | the build box, and what a press may and may not do |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.1 (what you get free and what you do not) · §3.2 (**the eight label rules**) · §3.3 (`spellOutTag`, which sits beside this component and is not part of it) | what the label must and must not say |
| `docs/engineering/12-testing.md` | §7.4 (the split between the two gate files and the 84-run table they share) · §7.5 (**the canary**) | why this test is single-widget today and a sweep at N33 |
| `docs/research/00-tech-decisions.md` | §5 · #100 (60 × 60 floor + a second geometric gate) · #101 (the gesture ban) · #104 (`headingLevel`, never `header:`) · #115 (`ensureSemantics` before every `meetsGuideline`) | the floor, the gates and the handle discipline |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | every button, field and control is built on this primitive, and it owns their states |
| `shed-accessibility-and-copy` | the eight label rules and why an unlabelled node is an unnamed stop in a Switch Control scan |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/tap_target_test.dart`
- **Test** — `'ShedTapTarget lays out at least 64 by 64 and requires a semanticLabel'`
- **Why it is red today** — no tap primitive exists, so the first button would be a bare `InkWell`.

```bash
fvm flutter test test/design/tap_target_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion in three ways. Measure the **laid-out rect**, not the constraint:
`tester.getRect(find.byType(ShedTapTarget))` with a deliberately tiny child — a 20 px `Text` — and
assert both axes at ≥ 64.0. Run it at textScaler 1.0, 1.3 and 2.0, because the box must never shrink
as text grows. And open the test with `final handle = tester.ensureSemantics();
addTearDown(handle.dispose);` — without it `semanticsOwner` is null, and the guideline **throws
instead of asserting**, which is a gate that silently cannot do its job (decision #115).

**Green.** The minimum code that passes, and nothing beyond it — the widget with a required label parameter, the minimum box, the slop, and the semantics
node.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller. **No ARB entry
either** — `ShedTapTarget` takes its label as a parameter and never composes copy; the strings belong
to the callers, one ARB message each with a `description`, from N10 onward. Say so in the commit
message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_tap_target.dart` | **New.** `CONVENTIONS §4.1` reserves `lib/core/ui/components/` for `shed_<thing>.dart` files, and R70 puts every `06 §12` component here rather than under a feature — a sibling-feature import is a layer violation, so no screen may invent its own |
| 2 | `test/design/tap_target_test.dart` | **New.** The single-widget form, plus the canary. **This is the same file N33-T03 extends** with the geometric sweep — not a different one. Leave the comment that says so |

### 5.2 The signatures

`06 §6.2`, typed as printed. Every line of it is load-bearing:

```dart
// lib/core/ui/components/shed_tap_target.dart
/// Guarantees a >= [minSize] hit region regardless of the child's painted size,
/// and makes the whole region opaque to hit testing so a tap in the transparent
/// margin still counts. That margin IS the hit slop.
class ShedTapTarget extends StatelessWidget {
  const ShedTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.minSize,
    this.onTapHint,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String semanticLabel;   // required: an unlabelled node is an unnamed
  final double? minSize;        // stop in a Switch Control scan
  final String? onTapHint;

  @override
  Widget build(BuildContext context) {
    final double size = minSize ?? context.tokens.tapMin;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      // MANDATORY, and easy to leave out. ExcludeSemantics below drops the
      // GestureDetector's own SemanticsAction.tap, so without this line the
      // node announces as a button and then does nothing when VoiceOver or
      // Switch Control activates it — and `onTapHint` is inert, because a hint
      // overrides the verb of an action that has to exist first.
      onTap: onTap,
      onTapHint: onTapHint,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
```

The guideline constant the tests use lives in `test/design/`, not in `lib/`:

```dart
const shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/engineering/06-design-system.md#6-tap-targets-hit-slop-and-separation',
);
```

### 5.3 The details that are easy to get wrong

- **`Semantics(onTap:)` is the line everybody deletes.** `ExcludeSemantics` strips the
  `GestureDetector`'s own `SemanticsAction.tap`, so without that line the node announces correctly as
  a button and then **refuses to activate** under VoiceOver or Switch Control. Nothing in
  `flutter_test` catches it — not `MinimumTapTargetGuideline`, not `labeledTapTargetGuideline` — which
  is exactly why `06 §6.3`'s geometric gate asserts `node.hasAction(SemanticsAction.tap)` by hand.
  `onTapHint` is inert without it too: a hint overrides the verb of an action that must exist first.
- **60 is the gate's number and 64 is the widget's, and the anchor asserts 64.** `06 §6.1` sets
  `tapMin` at 60 as the absolute floor and `MinimumTapTargetGuideline(size: Size(60, 60))` is the
  contract; `indelible.md` §4.5's audit puts the smallest thing in the whole app at **64 × 64** — *"the
  spec floor is 60"*, with four points of headroom and no more. Two honest ways to get there: author
  `ShedTokens.tapMin` at 64 (still ≥ 60, so `contrast_test`'s `tapMin >= 60.0` assertion is unchanged
  and `primitives.dart` keeps `tapMin = 60.0` as the documented spec floor), or leave the token at 60
  and make **this widget's** default 64. Pick one, say which in the commit message, and do not leave
  both numbers implicit — the next reader will assume the wrong one.
- **Say nothing about separation.** `gapMin` 16 pt (`06 §6.1`) versus Indelible's 8–12 px is **P9**,
  and it is ruled in **N33-T03**, where the geometric gate actually asserts it. A single-widget test
  that quietly freezes one of the two numbers into a passing assertion is how an open conflict becomes
  settled without anyone deciding it.
- **Flutter clips hit testing to a parent's bounds.** If a target overflows its parent, the taps are
  silently dropped **even with `Clip.none`**. `HitTestBehavior.opaque` and the `ConstrainedBox` handle
  slop *inside* the layout; outside it, the fix is to **restructure the layout**, never to add a clip
  behaviour. This is a class of bug that only appears on a real device, and it is why the geometric
  gate measures rects rather than trusting constraints.
- **No `InkWell`, and no ripple.** `indelible.md` §5.1: a press is a **fill change only** — *"no
  scale, no lift, no ripple, because a target that shrinks under a cold thumb is a target you miss."*
  `ShedTapTarget` is a `GestureDetector`, so there is no ripple by construction; the 40 ms fill flash
  belongs to the calling component and its `--slab` → `--slab-pressed` transition, which is N10's.
- **`GestureDetector` gets `onTap` and nothing else.** `onLongPress*`, `onPan*`, `onScale*`,
  `onForcePress` and `onHorizontal/VerticalDrag*` are all gate rows under `lib/` (`06 §3.5`). The
  replacement for every one of them is two taps on a list.
- **The label is required at the **type** level, not asserted at runtime.** `required String
  semanticLabel`, non-nullable. An `assert(label != null)` is stripped in release, which means the
  guarantee evaporates in exactly the build a shepherd runs.
- **The eight label rules (`10 §3.2`) bind every caller, and this file's doc comment is where they get
  read.** Never put the control type in the label (`'Turn out'`, never `'Turn out button'` — Flutter
  emits the role). Never put state in the label — use `enabled:` and `selected:`. The label **matches
  the visible text**, because that is Voice Control's criterion: if the control reads *Turn out* and
  the label is *Release from pen*, "Show names" displays the wrong words and "tap turn out" does
  nothing. Labels survive out of order — no "Tap here", no "More", no "This". Concise: `'New
  lambing'`, not `'Press to record a new lambing event'`. `onTapHint` is for a non-obvious outcome
  only.
- **The label uses the user's noun, and this widget cannot fetch it.** `terminologyProvider` is a
  Riverpod provider in `lib/data/providers.dart`, and layer rule 7 forbids `lib/core/ui/` from
  importing riverpod at all. So the **caller** resolves the term and passes the finished string. Put
  that in the doc comment, because the alternative — hard-coding "ewe" — is `10 §8.5`'s named defect.
- **`enabled: onTap != null` is the whole disabled story, and disabled is rare here.**
  `indelible.md` §7.1: a disabled corner slab is *"still a 160 × 140 target — pressing it opens the
  tag sheet rather than doing nothing."* §7.2: no keypad key is **ever** disabled, because *"a dead key
  under a cold thumb is indistinguishable from a missed tap."* A disabled `ShedTapTarget` still
  measures 64 × 64 and still announces; it just has no action.
- **`find.byWidget` is unusable in any test over this type.** Two keypad keys can be equal `Widget`s
  and `getRect` throws on a finder matching more than one element — match on `Element` identity
  instead. It bites in the single-widget test the moment you pump two targets to check slop.
- **`accessibility_tools` 2.8.0 runs in debug alongside these tests and its default is 48 × 48** —
  *below* our floor. It complements the house assertion and never replaces it. Do not read a green
  overlay as a passing gate.
- **This file is not a sweep, and the comment saying so is part of the deliverable.** The 84-run
  geometric gate over `kPumpableVariants` is **N33-T03**; the tree-walking guidelines and the
  `headingLevel` assertion are **N33-T02**'s `semantics_gate_test.dart`. Both need a variant table
  that does not exist until N13. Critique defect S7 is exactly this mistake made once.

### 5.4 The full test set

`test/design/tap_target_test.dart`. Every case that touches semantics opens a `SemanticsHandle`.

| Case | What it asserts |
|---|---|
| `'ShedTapTarget lays out at least 64 by 64 and requires a semanticLabel'` | **The anchor.** A 20 px child inside a target whose measured rect is ≥ 64 × 64 |
| `'the box is never below 64 at textScaler 1.0, 1.3 and 2.0'` | The box grows with text and never shrinks. Three pumps, one assertion each |
| `'a tap in the transparent margin fires onTap'` | `tester.tapAt` at a point inside the rect but outside the child. `HitTestBehavior.opaque` is what makes the margin a target rather than a hole |
| `'an enabled target exposes SemanticsAction.tap'` | `tester.getSemantics(...).hasAction(SemanticsAction.tap)`. The failure no built-in guideline catches |
| `'a disabled target announces enabled false and still measures 64 by 64'` | `onTap: null`. It is still a target, it is just not an action |
| `'the semantics label is exactly the string passed and carries no role word'` | The label does not end in `button`, `link` or `tab` (`10 §3.2` rule 1) |
| `'onTapHint reaches the node only alongside a tap action'` | A hint on an action-less node is inert and misleading |
| `'the target passes shedTapTargetGuideline and labeledTapTargetGuideline'` | Both `meetsGuideline` runs, inside one `ensureSemantics` handle |
| `'CANARY: a deliberately 40x40 target FAILS the 60 pt guideline'` | `12 §7.5`. Calls `shedTapTargetGuideline.evaluate(tester)` **directly** and expects `passed` to be false — `meetsGuideline` is an `AsyncMatcher` and asserting that something fails one is easy to get subtly wrong, and *"a canary you cannot read is not a canary"* |
| `'ShedTapTarget uses no InkWell and binds no banned gesture'` | Source text over the component: no `InkWell`, no `onLongPress`, no `onPan`, no `onScale`, no `onForcePress` |
| `'semanticLabel is a required non-nullable String'` | Source text. A runtime assert would be stripped in release |
| `'this file iterates no variant table'` | `kPumpableVariants` appears nowhere in it, and the comment naming N33-T02 / N33-T03 is present |

**Nothing here is time-shaped.** No `uk-zone` case; T06 has the epic's only one.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark
  only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. This
  file is where the first two of those become mechanical rather than aspirational.
- **Accessibility, authored here** — the required `semanticLabel` and `Semantics(onTap:)` are
  widget-authoring rules, not a later sweep. N33 only verifies; there is no epic that retrofits
  semantics across twelve screens, because that would be a rewrite.
- **Layer rule 7** — `lib/core/ui/` imports `lib/core/ui/`, `lib/domain/` and `package:flutter/*`. No
  riverpod, so no `terminologyProvider`; the caller passes the resolved noun.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedTapTarget lays out at least 64 by 64 and requires a semanticLabel'` passes, and was seen to fail first for the stated reason
- [ ] the label is required at the type level, not asserted at runtime
- [ ] the laid-out box is never below 64 × 64 at any text scale
- [ ] hit slop extends beyond the visual bounds
- [ ] this is a **single-widget** test — the sweep over every screen is N33-T03
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `Semantics(onTap:)` is set, and a test asserts an enabled target exposes `SemanticsAction.tap`
- [ ] the canary is present and calls `evaluate` directly rather than negating `meetsGuideline`
- [ ] every semantics case opens `tester.ensureSemantics()` with `addTearDown(handle.dispose)`
- [ ] the widget uses no `InkWell` and binds no banned gesture
- [ ] the 60-versus-64 choice is made explicitly and its reason is in the commit message
- [ ] **the file asserts nothing about target separation** — P9 is N33-T03's
- [ ] the file lives at `lib/core/ui/components/shed_tap_target.dart`, not under a feature

## 8. Verification

```bash
fvm flutter test test/design/tap_target_test.dart
fvm flutter test test/design/
make check
make test
```

Prove the canary is doing its job — comment out the `ConstrainedBox`, watch the anchor fail, revert:

```bash
# temporarily drop the ConstrainedBox from shed_tap_target.dart
fvm flutter test test/design/tap_target_test.dart   # expect the anchor to fail on the measured rect
git checkout -- lib/core/ui/components/shed_tap_target.dart
```

```bash
grep -rn "InkWell\|onLongPress\|onPanUpdate\|onScaleUpdate\|onForcePress" lib/core/ui/components/   # expect zero
grep -rn "kPumpableVariants" test/design/tap_target_test.dart                                       # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedTapTarget with a required semanticLabel`
