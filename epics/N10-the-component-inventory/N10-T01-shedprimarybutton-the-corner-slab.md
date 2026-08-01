# N10-T01 — `ShedPrimaryButton` — the corner slab

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 1 of 8 |
| **Depends on** | N09-T09 |
| **Commit** | one commit · `feat(ui): ShedPrimaryButton, the corner slab` |

## 1. Why this task exists

The one-per-page primary verb: a corner slab, five states, and the rule that it **never
refuses a press**. A disabled primary button at 3am is a shepherd tapping a dead rectangle in the dark
with no idea why; if the action cannot be performed, the button says what is missing instead.

It is also the first component in the folder, so it carries three things the other seven tasks
inherit and never rebuild: the **pump helper** in `test/design/components_test.dart`, the
**`ShedTapTarget`-underneath rule** that makes every N33 gate able to find these controls at all, and
the **copy-as-a-parameter rule** that keeps a shared component out of the ARB. Get those wrong here
and they are wrong fifteen times.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedPrimaryButton`: ≥ `tapHero` tall, ≥ 2 × `tapPrimary` wide, `labelLarge`, `surfaceFill` on `surfaceBase`, states default/pressed/disabled) · §6.1–§6.2 (the tap scale and `ShedTapTarget`) · §3.5 (`token.magic_size`, `token.color_scheme_read_ui`) · §5.1 (`labelLarge`) | the size contract, the tap surface, the text role |
| `docs/design/indelible.md` | §7.1 (**the corner slab in full** — 160 × 140, its per-page verb table, and all five states including `TAG FIRST` and the warning state) · §4.5 (the two thumb anchors, and the 64 × 64 audit) · §5.1 (a press is a 40 ms fill change: no scale, no lift, no ripple) · §4.2 (2 px border, 2 px radius, no shadow) | every value and every state |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/core/ui/components/`) · §1.1 layer rule 6 (a sibling-feature import is a layer violation) and rule 7 (what `lib/core/ui/` may import) · §4.1 (`shed_<thing>.dart`) · §4.2 (`Shed*`) · §4.5 (widget keys) | **BINDING** on the path, the class name and what this file may import |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp` — which is N12-T05 and does not exist yet) · §5.3 (`test/support/` is a **closed** twelve-file list) | why this test builds its own pump and where that helper may live |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | every button shape, state and label rule is its subject |
| `indelible-design-system` | the slab's geometry, tokens and corner treatment |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedPrimaryButton renders at textScale 2.0 with boldText, has a semanticLabel, and no dimension below 64'`
- **Why it is red today** — `lib/core/ui/components/` is empty; a screen would build its own button and the layer rule would then forbid sharing it.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion. `64` is Indelible §4.5's system floor — *"the smallest target in the app is
64 × 64. The spec floor is 60"* — and this component's real contract is larger, so assert the
contract and let 64 be the backstop:

```dart
final Rect r = tester.getRect(find.byType(ShedPrimaryButton));
expect(r.height, greaterThanOrEqualTo(88.0));   // tapHero
expect(r.width,  greaterThanOrEqualTo(144.0));  // 2 x tapPrimary
expect(r.shortestSide, greaterThanOrEqualTo(64.0));
```

Type the numbers as literals here, never as `context.tokens.tapHero`: a test that reads its expected
value out of the same token the widget read asserts nothing. Open the test with
`final handle = tester.ensureSemantics(); addTearDown(handle.dispose);` — without it `semanticsOwner`
is null and the semantics assertion throws instead of failing (decision #115).

**Green.** The minimum code that passes, and nothing beyond it — the widget over `ShedTapTarget`, its five states, and the table-driven component test
that every later component joins.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller — and **no ARB entry**
(§5.3 says why). Say so in the commit message: skipping the schema step means you are storing nothing.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_primary_button.dart` | **New.** `CONVENTIONS §4.1` fixes the path shape `lib/core/ui/components/shed_<thing>.dart`; `06 §12` puts every component here rather than under a feature's `widgets/`, because layer rule 6 forbids a sibling import and a button built inside `quick_entry/` could never be reused by Lambing Entry |
| 2 | `test/design/components_test.dart` | **New.** The anchor case, the five-state cases, and the **private `_pumpComponent` helper the other seven tasks in this epic reuse**. It is a private top-level function in this file, not a thirteenth file in `test/support/` — `12 §5.3` closes that list |
| 3 | `docs/engineering/CONVENTIONS.md` §1 · `06-design-system.md` §3.5 | **Amend, only if N09 has not already.** Both still describe `test/design/` by a file list that predates this file. `00-README` §10's amendment rule does not care which epic notices; it cares that the document and the tree agree in the same commit |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_primary_button.dart

/// The five states of indelible.md §7.1. There is no `disabled` member, and
/// that absence is the point: `06 §12` lists one, Indelible rules that the
/// slab still fires and opens the tag sheet, and Indelible wins because a
/// dead rectangle in the dark is indistinguishable from a missed tap.
enum ShedPrimaryButtonState {
  /// Fill `surfaceFill`, outline at `outlineWidth`, label at full ink.
  ready,

  /// A subject has landed; the next press writes. Outline lifts to
  /// `textPrimary` and the corner tick prints.
  armed,

  /// What is missing, said in words. Same box, same target, different verb
  /// and a dotted outline. `onTap` still fires — it opens the thing that is
  /// missing.
  refusing,

  /// Pressing would contradict something already recorded. Fires normally;
  /// the query mark is the record's job, not the button's.
  querying,
}

final class ShedPrimaryButton extends StatelessWidget {
  const ShedPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,          // NOT nullable. See §5.3.
    required this.semanticLabel,
    this.state = ShedPrimaryButtonState.ready,
  });

  /// Already localised and already upper-cased by the caller. `+ LAMB`,
  /// `+ EWE`, `+ DOSE`, `TAG FIRST`. This file composes no copy (§5.3).
  final String label;
  final VoidCallback onTap;
  final String semanticLabel;
  final ShedPrimaryButtonState state;
}
```

The build body, with the two constructions that are not obvious:

```dart
  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return ShedTapTarget(
      key: key,
      onTap: onTap,
      semanticLabel: semanticLabel,
      minSize: t.tapHero,                    // 88 — one scalar, both axes
      child: ConstrainedBox(
        // tapHero is square; 06 §12 also wants >= 2 x tapPrimary of WIDTH.
        // Token first, literal second — see the token.magic_size gotcha.
        constraints: BoxConstraints(minWidth: t.tapPrimary * 2),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
```

Widget key, per `CONVENTIONS §4.5` — `<screen>.<element>[.<qualifier>]`, every segment `lower_snake`.
The component does not invent one; the screen passes it (`quick_entry.slab`, `flock.slab`). A
`Key('primaryButton')` is a defect (R59).

### 5.3 The details that are easy to get wrong

- **`onTap` is non-nullable, and that is the whole task.** `ShedTapTarget` takes
  `VoidCallback? onTap` and sets `Semantics(enabled: onTap != null)`. Pass `null` and three things
  happen at once: the node announces as a disabled button, `06 §6.3`'s geometric gate **skips** it
  (`if (onTap == null) continue;`), and a shepherd taps a live-looking rectangle that does nothing.
  Indelible §7.1's disabled row is explicit — *"Still a 160 × 140 target — pressing it opens the tag
  sheet rather than doing nothing."* Narrow the type and the failure mode stops being expressible.
- **`minWidth: 2 * t.tapPrimary` fails the build.** `token.magic_size` (`06 §3.5`) matches
  `minWidth:\s*[0-9]` with only `0` and `1` excused, so a leading numeric literal is a gate failure
  even when it multiplies a token. Write `t.tapPrimary * 2`. The same trap is waiting on `height:`,
  `width:`, `spacing:`, `strokeWidth:` and `letterSpacing:` — token first, always.
- **`ShedTapTarget.minSize` is one scalar applied to both axes.** `06 §6.2`'s body is
  `BoxConstraints(minWidth: size, minHeight: size)`. Any non-square contract — and the slab is
  144 × 88 at minimum — needs a second `ConstrainedBox` on the child. Passing `minSize: t.tapHero`
  and hoping the label makes it wide enough works at scale 1.0 with `+ LAMB` and fails at scale 1.0
  with `MOVE`.
- **This file composes no user-facing copy, so this epic adds nothing to `app_en.arb`.** The slab's
  verb changes per page (Indelible §7.1's table: `+ LAMB` · `+ EVENT` · `+ EWE` · `+ DOSE` · `+ NOTE`
  · `MOVE`), and several of those words are terminology the user owns and edits — `terminologyProvider`
  is Riverpod, and a component in `lib/core/ui/` is not a `ConsumerWidget` and reads no provider
  (layer rule 7). So `label` and `semanticLabel` are required `String`s, the screen supplies them
  from its own ARB message, and each of those messages carries its own `description` when the screen
  epic lands. Do not add `slabLamb` to the ARB here to "get ahead" — a message with no call site is a
  message nobody reviews.
- **`colorScheme` is a build failure inside this folder.** `token.color_scheme_read_ui` bans the
  identifier under `lib/core/ui/components/` outright. Every colour comes from `context.tokens`;
  every size comes from `context.tokens`; every text style comes from a `TextTheme` **role**, never a
  constructed `TextStyle` (that drops `fontFeatures` and is how a tabular column starts jittering —
  `06 §5.4`).
- **A press is a fill change and nothing else.** Indelible §5.1: `--motion-press` is 40 ms,
  `--ease-out`, *"fill only; no scale, no lift, no ripple — a target that shrinks under a cold thumb
  is a target you miss."* §5.3 keeps that 40 ms **even under reduce-motion**, because it is the only
  visual confirmation available through a glove. `InkWell`, `InkSparkle`, `Material` elevation and
  `AnimatedScale` are all wrong answers here. The pressed fill is Indelible's `--slab-pressed`, which
  is the **fifth surface** N09-T02 added to `ShedTokens`; read the field name out of `tokens.dart`
  rather than guessing it, and do not reuse `surfacePressed`, which is the row press (`--row-pressed`)
  and a different hex.
- **The refusing state is not a disabled state and must not be styled as one.** Indelible §7.1 gives
  it a **dotted** 2 px outline (`--rule-dot`, `2px 6px`), `textChrome` ink and a verb that names what
  is missing. `ElevatedButton(onPressed: null)`'s grey-out is the exact rendering this task exists to
  refuse.
- **160 × 140 is a layout value, not a component value.** Indelible §4.5 pins the slab at 160 × 140
  in the bottom band of a 393 × 852 reference viewport. That placement belongs to the Quick Entry
  shell (N13-T05), which owns the bottom band and the left-handed mirror. This component publishes
  **minimums from tokens** and lets its parent give it the box. Hard-coding 160 × 140 here would put
  a magic size in `lib/` and freeze a screen decision inside a shared control.
- **`pumpApp` does not exist yet.** `test/support/harness.dart` is N12-T05, two epics away. Write
  `_pumpComponent` in this file, take `Device.small`'s 375 × 667 by value with a comment saying the
  table is N12's, and install the theme with
  `buildShedTheme(resolvePalette(ShedPaletteId.night, highContrast: false))` from N09-T03/T04.
  Without the theme the `ShedTokens` extension is absent, `context.tokens`' trailing `!` throws, and
  the failure message will not mention tokens (N09-T02 says so in a doc comment beside the accessor).
- **The gate scans `lib/**` only.** Literals in `test/` are fine and here they are *required*: assert
  `88.0` and `144.0`, not `t.tapHero` and `t.tapPrimary * 2`.

### 5.4 The full test set

`test/design/components_test.dart` — widget tests. Every case runs through `_pumpComponent`, and
every case that touches semantics opens a `SemanticsHandle` first.

| Case | What it asserts |
|---|---|
| `'ShedPrimaryButton renders at textScale 2.0 with boldText, has a semanticLabel, and no dimension below 64'` | **The anchor.** Laid-out rect ≥ 88 tall, ≥ 144 wide, shortest side ≥ 64; exactly one `Semantics` node with a non-empty label; no `RenderFlex` overflow and no exception |
| `'the slab is one ShedTapTarget and the gates can find it'` | `find.byType(ShedTapTarget)` matches exactly once inside the subtree. N33's two sweeps find targets by type; a control built on a bare `InkWell` is invisible to every one of them |
| `'every ShedPrimaryButtonState exposes SemanticsAction.tap'` | Loop the enum. `tester.getSemantics(...).hasAction(SemanticsAction.tap)` is true in **all four** states, including `refusing`. This is the executable form of *never refuses a press* |
| `'the refusing state changes the label and the outline, never the enabled flag'` | `SemanticsFlag.isEnabled` is set in `refusing`; the rendered label differs from `ready`'s; the outline is dotted |
| `'a press changes fill and nothing else'` | `tester.startGesture` on the child, pump 40 ms, and compare the laid-out rect before and after: identical. Catches an `AnimatedScale` or a `Transform` added later |
| `'the label goes through labelLarge and never a constructed TextStyle'` | The rendered `Text`'s effective style equals `Theme.of(context).textTheme.labelLarge` merged with the framework's bold-text merge — no third `fontSize`, no third weight |
| `'no dimension shrinks between textScale 1.0, 1.3 and 2.0'` | Three pumps, three rects, monotonic in both axes. A box that shrinks as text grows is the `FittedBox` bug wearing a different hat |
| `'ShedPrimaryButton constructs with no nullable onTap'` | Source-text assertion over `shed_primary_button.dart`: no `VoidCallback?` and no `onTap: null`. The narrowing is the feature; a widened signature is the regression |
| `'the component file contains no colorScheme, no Color(0x and no literal fontSize'` | Source text, three greps. The gate already proves this repo-wide; the local case is what tells you *which component* broke it |
| `'the file imports no provider, no localisation and nothing under lib/data'` | Source text over the import block. Layer rule 7 lists what `lib/core/ui/` may import, and this is the file where the first violation would be introduced |

**Nothing here is time-shaped**, so there is no `uk-zone` case: the slab reads no clock and holds no
duration but the 40 ms press. `ShedCountdown` (N10-T05) and `ShedBanner` (N10-T08) are the two
components in this epic that get one.

## 6. Constraints that bind this task

- **3am** — `tapHero` (88) tall and `tapPrimary * 2` (144) wide, `gapMin` (16) from any neighbour and
  `gapDestructive` (32) from anything destructive, 18 px text floor, dark only. None of the banned
  gestures reaches this file: it is a single `onTap` on a `HitTestBehavior.opaque` region.
- **The slab never refuses a press** — held at the *type* level (`onTap` is non-nullable), not at the
  documented level. `00-README` §10's hierarchy: a rule that drops to merely *documented* has been
  deleted, whatever the prose says.
- **No ARB entry, and that is deliberate** — every string this component renders arrives as a
  parameter. The screen epic that mounts it authors the message with its `description`; N33 verifies.
  Say so in the commit message so a reviewer does not read the empty ARB diff as an omission.
- **Two tiers** — no hex, no magic size, no `colorScheme`, no constructed `TextStyle`. `context.tokens`
  and a `TextTheme` role, or it does not build.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedPrimaryButton renders at textScale 2.0 with boldText, has a semanticLabel, and no dimension below 64'` passes, and was seen to fail first for the stated reason
- [ ] never disabled — the refusing state explains itself instead
- [ ] one per page, and the test asserts the single-instance rule where a screen uses it
- [ ] renders at text scale 2.0 with bold text without overflow
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `onTap` is `VoidCallback`, not `VoidCallback?`, and every state exposes `SemanticsAction.tap`
- [ ] the widget is built on `ShedTapTarget` and `find.byType(ShedTapTarget)` finds it
- [ ] `label` and `semanticLabel` are required parameters; `app_en.arb` is untouched by this commit
- [ ] `_pumpComponent` is a private top-level function in `components_test.dart`, not a new file under `test/support/`
- [ ] `test/design/`'s file list in `CONVENTIONS §1` and `06 §3.5` names `components_test.dart`

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/design/                 # nothing N09 landed regressed
make check
make test
```

```bash
grep -n "colorScheme\|Color(0x\|fontSize:" lib/core/ui/components/shed_primary_button.dart   # expect zero
grep -n "VoidCallback?" lib/core/ui/components/shed_primary_button.dart                      # expect zero
grep -rn "^import" lib/core/ui/components/shed_primary_button.dart                           # flutter + core/ui only
git diff --stat -- lib/l10n/app_en.arb                                                       # expect no change
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedPrimaryButton, the corner slab`
