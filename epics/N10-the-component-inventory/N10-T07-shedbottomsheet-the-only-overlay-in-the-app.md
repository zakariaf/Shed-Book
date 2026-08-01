# N10-T07 — `ShedBottomSheet` — the only overlay in the app

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 7 of 8 |
| **Depends on** | N10-T06 |
| **Commit** | one commit · `feat(ui): ShedBottomSheet, the only overlay in the app` |

## 1. Why this task exists

One overlay type, and only one: no drag handle, no drag, not dismissible by tapping
outside, with an explicit Cancel. Every banned gesture is banned here first, because a sheet is where
they usually arrive.

The mechanism matters more than the prose. All three of the settings this component types are
**permissive by default in Flutter** — `enableDrag` defaults to `true` and *is* drag-to-dismiss — and
`tool/check_policy.dart` can only see a literal `true`, never an omission. So the rule is held by
making this file the **one call site** of `showModalBottomSheet(` in the app, and by a policy test
that says so.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedBottomSheet`: content anchored to the bottom, `showDragHandle: false`, **`enableDrag: false`**, `isDismissible: false`, explicit `tapPrimary` Cancel) · §7 (**the gesture-ban table**, and the paragraph that says all three settings must be *typed on every bottom sheet* because the defaults are permissive) · §3.5 (`gesture.drag_handle`, `gesture.sheet_drag`) | the three flags and the dismiss control |
| `docs/design/indelible.md` | §7.14 (**the bottom sheet in full** — `--sheet` `#141416`, 0 radius, a 2 px full-ink **top rule instead of a shadow**, 60 % of the viewport for the keypad and content-height for choosers, an 88 × 64 `CLOSE` word-button top-right, and **exactly three contents, ever**) · §4.2 (shadows: none; elevation: none) · §5.1 (`--motion-sheet` 160 ms, **translate-Y only** — no fade, no backdrop blur, no scrim animation) | every value, and what may not animate |
| `docs/engineering/07-screens.md` | §20.3 (modal sheets over full-screen pages for every short pick-one flow, all three flags typed on every sheet) · **§15.5** (*"there is no draft state, so 'Cancel' is not a verb"*) · §14.4 (**the only `canPop: false` flow in the app**, and it is not this one) | the composition rule, and the word |
| `docs/engineering/CONVENTIONS.md` | **§4.7** (`ui.show_dialog` — `showDialog(` outside **the two allowlisted destructive files**) · §4.1 (a policy test states the property) · §2.11 (the design-system catalogue this commit amends) · §1.1 layer rule 7 | what the policy test may and may not forbid |
| `epics/00-PLAN-CRITIQUE.md` | §11.3, the N10-T07 row **`[audit]`** — *"banning `showDialog(` outright would make the only two honest deletes in the app illegal"* | the corrected assertion |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | the sheet is a control and its interaction rules are its own |
| `indelible-states-and-feedback` | what may interrupt the shepherd, and when |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/one_overlay_test.dart`
- **Test** — `'showDialog( and showModalBottomSheet( appear nowhere outside shed_bottom_sheet.dart'`
- **Why it is red today** — nothing constrains overlays, and `showDialog(` is already a gate rule with no legitimate call site to point at.

```bash
fvm flutter test test/policy/one_overlay_test.dart   # expect: failing, for the reason above
```

**Sharpen the assertion, and do not implement the name literally.** `00-PLAN-CRITIQUE.md` §11.3
corrects this anchor: `ui.show_dialog` allowlists **restore-from-backup and delete-everything by
name** (`07 §14.4`), so a flat *nowhere* would make the only two honest deletes in the app illegal
when N29 lands them. Assert the corrected property, and read the allowlist rather than hard-coding a
path — the set is empty today and grows by two at N29 without this test needing an edit:

```dart
// half 1 — one overlay type, one call site, no exceptions
expect(_callSitesOf('showModalBottomSheet(', under: 'lib/'),
       equals({'lib/core/ui/components/shed_bottom_sheet.dart'}));

// half 2 — showDialog( only where the allowlist says, wherever that is today
expect(_callSitesOf('showDialog(', under: 'lib/'),
       equals(_allowlistedFor('ui.show_dialog')));   // today: the empty set

// half 3 — the flags the gate cannot see, because omitting them is the bug
final String src = File('lib/core/ui/components/shed_bottom_sheet.dart').readAsStringSync();
for (final flag in ['showDragHandle: false', 'enableDrag: false', 'isDismissible: false']) {
  expect(src.contains(flag), isTrue, reason: '$flag is not a default — it must be typed');
}
```

**Green.** The minimum code that passes, and nothing beyond it — the component, its single allowlist line, and the policy test.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI, one document amendment, and tests.** No schema, no domain, no data, no wiring, no controller,
no ARB entry — the dismiss word and the sheet's title arrive as parameters. Say so in the commit
message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_bottom_sheet.dart` | **New.** The `ShedBottomSheet` widget **and** `showShedBottomSheet`, the one function in the app permitted to call `showModalBottomSheet(`. Both live here, because the rule is *one call site*, and a widget alone cannot type the three flags — they are arguments to the show call, not to the sheet |
| 2 | `test/policy/one_overlay_test.dart` | **New.** The three-part property above. `CONVENTIONS §4.1`: a policy test is named for the property, not for the file it tests |
| 3 | `docs/engineering/CONVENTIONS.md` §2.11 | **Amend.** `showShedBottomSheet` is a new public name in `lib/core/ui/` and §2.11 is the design-system catalogue. R30 already rules on the `showShed*` spelling for two *feedback* functions; this one is not covered by any ruling, so add the row in this commit rather than leaving the catalogue incomplete (`00-README` §10) |
| 4 | `test/design/components_test.dart` | **Extend.** The geometry, the dismiss target and the no-scrim-animation cases |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_bottom_sheet.dart

/// The ONLY call site of showModalBottomSheet( in the app.
///
/// All three settings below are typed because Flutter's defaults are all
/// permissive (`06 §7`): `enableDrag` defaults to TRUE and is drag-to-dismiss,
/// a drag handle advertises a gesture this app does not support, and a scrim
/// tap is not a labelled target. `tool/check_policy.dart` can only see a
/// literal `true` — it cannot see an omission — so the rule is held by there
/// being exactly one place to omit them.
Future<T?> showShedBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  required String dismissLabel,        // indelible.md §7.14: 'CLOSE'
  required String dismissSemanticLabel,
  required String barrierLabel,
  bool fillsViewport = false,          // true for the keypad, false for a chooser
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: false,
    enableDrag: false,
    isDismissible: false,
    // 60% of the viewport is above Flutter's 9/16 default cap, so the keypad
    // sheet does not fit without this. A chooser is content-height and does
    // not need it (indelible.md §7.14).
    isScrollControlled: fillsViewport,
    barrierLabel: barrierLabel,
    backgroundColor: context.tokens.surfaceRaised,
    shape: const RoundedRectangleBorder(),   // radius 0 — "a document has no corners"
    builder: (_) => ShedBottomSheet(
      dismissLabel: dismissLabel,
      dismissSemanticLabel: dismissSemanticLabel,
      fillsViewport: fillsViewport,
      child: child,
    ),
  );
}

final class ShedBottomSheet extends StatelessWidget {
  const ShedBottomSheet({
    super.key,
    required this.child,
    required this.dismissLabel,
    required this.dismissSemanticLabel,
    this.fillsViewport = false,
  })  : assert(dismissLabel != 'Cancel', "07 §15.5: 'Cancel' is not a verb here"),
        assert(dismissLabel != 'Save', 'indelible.md §11 test 7');

  final Widget child;
  final String dismissLabel, dismissSemanticLabel;
  final bool fillsViewport;

  /// indelible.md §7.14: 60% of the viewport for the keypad.
  static const double viewportFraction = 0.6;
}
```

The two pieces of chrome, and neither is a Material default:

```dart
  // A 2 px full-ink TOP RULE instead of a shadow, at 15.05:1. indelible.md
  // §4.2: "shadows: none. Elevation: none." More visible in the dark than any
  // blur, and it does not lift the black level.
  Border(top: BorderSide(color: t.textPrimary, width: t.outlineWidth))

  // The dismiss control: a word button, top-right, at least tapPrimary in
  // BOTH axes. See the gotcha about 88 x 64.
  ShedSecondaryButton(label: dismissLabel, /* … */)
```

### 5.3 The details that are easy to get wrong

- **The gate cannot see a default, and every default here is wrong.** `enableDrag` defaults to `true`;
  `isDismissible` defaults to `true`; `showDragHandle` follows the theme. `gesture.sheet_drag` matches
  the literal `enableDrag: true` and `gesture.drag_handle` matches `showDragHandle: true` — **neither
  fires on an omitted argument.** A second `showModalBottomSheet(` anywhere in `lib/` that simply
  forgets all three ships a drag-to-dismiss sheet with a green build. That is why the policy test
  asserts a **call-site set**, not a spelling.
- **Do not implement the anchor's name literally.** `00-PLAN-CRITIQUE.md` §11.3 corrects it: banning
  `showDialog(` outright would make restore-from-backup and delete-everything illegal, and `07 §14.4`
  says those two are *"the only two flows in the app permitted to use `showDialog`"*. Neither file
  exists yet — they are N29's — so read the allowlist and compare sets. Today the expected set is
  empty; at N29 it becomes two, and this test needs no edit. Hard-coding two paths that do not exist
  yet would make the test red for two epics.
- **`Cancel` is not a word this product uses.** `07 §15.5`: *"the row is created on screen entry, not
  on exit … there is no `Save`, no `Cancel`, no `isDirty`, no `commit()`."* `06 §12` and `07 §20.3`
  both say *"explicit Cancel"* meaning *an explicit dismiss control*, and Indelible §7.14 gives it its
  word: **`CLOSE`**. The label is a required parameter and the two asserts are what keep `Cancel` and
  `Save` out of it. Indelible §11 test 7 is the sweep: zero hits on the string `Save` in the UI.
- **Indelible's `CLOSE` is 88 × 64 and `06 §12` asks for a `tapPrimary` Cancel.** 88 clears 72 on the
  long axis; **64 does not clear 72 on the short one.** Both documents state minimums, so take the
  larger and make the dismiss control ≥ `tapPrimary` (72) in both axes. Record the widening in the PR
  body — it costs 8 px of sheet header and it is the second time this epic has taken the larger of two
  floors (N10-T04 was the first).
- **`isScrollControlled` is the difference between a 60 % sheet and a clipped keypad.** Flutter caps a
  modal sheet at 9/16 of the screen (about 56 %) unless it is set. Indelible §7.14 wants 60 % (511 of
  852) for the keypad, and `06 §8.2` fixes the keypad at `84 × 4 + 8 × 3 = 360` plus the confirm bar.
  Set it for the keypad, leave it off for a chooser, and never set a fixed pixel height.
- **`canPop: false` is not this component's.** `07 §14.4`: delete-a-season is *"the only `canPop:
  false` flow in the app"*. The Android system back gesture must still close the sheet — it is the one
  non-tap route out, it belongs to the OS, and `isDismissible: false` only removes the **scrim tap**.
  A `PopScope(canPop: false)` here would trap a shepherd in a chooser at 3am with no labelled way out
  but the one control they cannot see because their thumb is over it.
- **Translate-Y only, 160 ms.** Indelible §5.1: *"no fade, no backdrop blur, no scrim animation."*
  Material's default sheet route fades the barrier; `06 §2.2`'s theme work is where that is pinned, so
  if the barrier still fades, fix the theme rather than adding an animation controller here. And under
  reduce-motion `--motion-sheet` goes to **0 ms** — the sheet is simply there (§5.3).
- **A top rule, never a shadow.** `--shadow: none`, elevation none, radius 0. `Material(elevation:)`,
  `BoxShadow` and `RoundedRectangleBorder(borderRadius: …)` are all wrong; a shadow on `#0A0A0B`
  either is invisible or lifts the black level, and the 2 px rule at 15.05:1 is what separates the
  sheet from the page.
- **The spine runs behind the sheet.** Indelible §4.3 and §7.14: the madder margin rule is continuous
  down the entire scroll and *"the sheet does not cover the margin column above its own top edge."*
  This component therefore must not paint a full-bleed background above its own top rule, and must not
  be given a scrim that hides the page's left 68 px. The spine itself belongs to the page (N13-T05).
- **Exactly three contents, ever.** §7.14: the tag keypad + recents, the index, an inline cell
  chooser. The component takes a `child` and cannot enforce that — but the doc comment names the three
  so a fourth is a conversation rather than a commit.
- **What *"never used on the five shed screens"* can mean, and what it cannot.** The Definition of
  Done carries that line, and Indelible §7.14 puts the **tag keypad** in a sheet on tonight's page,
  which is a shed screen. The reading that survives both is: **the app never raises a sheet; the
  shepherd does.** Nothing may present a sheet in response to a timer, a launch, a save, a cap or a
  reminder — that is `06 §12`'s free-tier rule (*no self-appearing sheet*) and spec §5's *zero
  interruptions*. Whether Quick Entry's keypad is a sheet at all or the inline stack of `06 §8.2` is a
  **composition** question that belongs to N13-T05; record it in the PR body and do not settle it in a
  shared control.

### 5.4 The full test set

`test/policy/one_overlay_test.dart` for the source-text properties, `test/design/components_test.dart`
for the geometry.

| File · Case | What it asserts |
|---|---|
| policy · `'showDialog( and showModalBottomSheet( appear nowhere outside shed_bottom_sheet.dart'` | **The anchor**, implemented as the audit corrects it: the `showModalBottomSheet(` call-site set is exactly `{shed_bottom_sheet.dart}`, and the `showDialog(` call-site set equals the `ui.show_dialog` allowlist read off disk |
| policy · `'the one sheet call site types all three permissive flags'` | `showDragHandle: false`, `enableDrag: false`, `isDismissible: false` all present as literals. The omission the gate cannot see |
| policy · `'no file under lib/ constructs a PopScope with canPop: false'` | Today the expected count is zero; `07 §14.4` gives it exactly one call site at N29, and this test is where that stays deliberate |
| policy · `'no file under lib/ names BoxShadow, elevation: or Material 3 sheet elevation'` | Indelible §4.2. A shadow is the first thing a Material default puts back |
| design · `'ShedBottomSheet draws a 2 px top rule and no shadow'` | Border inspection: a `BorderSide` at `outlineWidth` on the top edge only, colour equal to `textPrimary` |
| design · `'the sheet has radius zero'` | `RoundedRectangleBorder` with `BorderRadius.zero`, in both `fillsViewport` modes |
| design · `'the dismiss control is at least tapPrimary in both axes and sits top-right'` | ≥ 72 × 72; its rect's right edge is within the gutter of the sheet's right edge |
| design · `'the dismiss label cannot be Cancel or Save'` | Both asserts fire. `07 §15.5` and Indelible §11 test 7 |
| design · `'fillsViewport true asks for more than half the viewport'` | The laid-out sheet height exceeds `9/16` of the pumped viewport — the assertion that `isScrollControlled` is actually doing its job |
| design · `'a chooser sheet is content-height'` | With `fillsViewport: false` the sheet is the height of its child plus chrome, not a fixed fraction |
| design · `'the sheet renders at textScale 2.0 with boldText with no overflow'` | The epic-wide case, this component's row |
| design · `'under reduce-motion the sheet is simply there'` | With `MediaQueryData(disableAnimations: true)` the sheet is at its final offset on the first pump. Indelible §5.3 |

**Nothing here is time-shaped.** The only duration is `--motion-sheet`, 160 ms, and it reduces to
zero rather than to shorter — assert that in `reduce_motion_test.dart`'s existing file rather than
adding a clock to this one.

## 6. Constraints that bind this task

- **The gesture ban, first and hardest.** `06 §7` lists eleven banned gestures and a sheet is where
  drag-to-dismiss, a drag handle and a scrim tap all arrive at once. All three are refused here, at
  the one call site, by typed arguments — and the vertical scroll inside the sheet's content is the
  one permitted tracked gesture.
- **Zero interruptions** (spec §5) — the app never raises a sheet. `06 §12`'s free-tier rule says the
  same thing from the monetization side: no modal, no interstitial, **no self-appearing sheet**
  anywhere in `lib/`.
- **3am** — the dismiss control ≥ `tapPrimary` (72) in both axes, `gapMin` (16) from anything else,
  18 px floor, dark only. The sheet's own surface is `surfaceRaised`, which is measured against every
  ink in `contrast_test.dart` already.
- **No ARB entry** — `dismissLabel`, `dismissSemanticLabel` and `barrierLabel` are parameters. The
  barrier label is not optional: it is what a screen reader announces when the modal route takes
  focus.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'showDialog( and showModalBottomSheet( appear nowhere outside shed_bottom_sheet.dart'` passes, and was seen to fail first for the stated reason
- [ ] exactly one file may open an overlay
- [ ] no drag handle and no drag-to-dismiss
- [ ] an explicit Cancel target of at least 64 × 64
- [ ] never used on the five shed screens
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the `showDialog(` half compares against the **allowlist read off disk**, not against a hard-coded path, so N29's two destructive flows stay legal
- [ ] all three permissive flags are typed as literals at the one call site, and a test asserts it
- [ ] the dismiss control clears `tapPrimary` in **both** axes, and the widening from Indelible's 88 × 64 is recorded in the PR body
- [ ] no `PopScope(canPop: false)` anywhere in this diff
- [ ] the sheet has radius 0, a 2 px top rule and no shadow or elevation
- [ ] `showShedBottomSheet` is added to `CONVENTIONS §2.11` in this commit

## 8. Verification

```bash
fvm flutter test test/policy/one_overlay_test.dart
fvm flutter test test/design/components_test.dart
make check
make test
```

```bash
grep -rn "showModalBottomSheet(" lib/            # expect exactly one hit
grep -rn "showDialog(" lib/                      # expect zero until N29
grep -rn "canPop:\|BoxShadow\|elevation:" lib/   # expect zero
grep -n "enableDrag: false\|isDismissible: false\|showDragHandle: false" lib/core/ui/components/shed_bottom_sheet.dart
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedBottomSheet, the only overlay in the app`
