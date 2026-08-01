# N13-T04 — `ShedKeypad` — the only number-entry route in the app

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 4 of 7 |
| **Depends on** | N13-T03 |
| **Commit** | one commit · `feat(quick_entry): ShedKeypad, the only number entry in the app` |

## 1. Why this task exists

Digits at 40 pt minimum on 64 × 64 targets, and **no key is ever disabled** — including
over the free cap, because a dead key at 3am is indistinguishable from a broken phone. The keypad is
the only number-entry route in the product: there is no system keyboard anywhere.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | **§8.1** (five reasons the system keyboard is refused) · **§8.2** (the geometry contract: 3 × 4, cells ≥ `tapPrimary`, gutters `gapMin`, the glyph role, `side = max(tapPrimary, scaler.scale(glyph) * 1.6)`, haptic on down, no key repeat, the `Expanded` trap, never `FittedBox`) · §6.1–§6.2 (`tapMin` 60 / `tapPrimary` 72 / `tapHero` 88 / `gapMin` 16, and `ShedTapTarget`) · §7 (the gesture ban) · §12 (`ShedKeypad`'s inventory row) | the Flutter-side geometry, the glyph role and the hit-slop rules |
| `docs/design/indelible.md` | **§7.2** (the keypad key: `117 × 84`, `--t-tag` 32 px in the **record** face, the bottom row `⌫ · 0 · NEW TAG`, and *"Disabled: Never"*) · §3.5 rule 5 (the documented record-face exception, and why) · §4.1 (`--s-2` 8 px key gaps) · §4.5 (the thumb band, and the 64 × 64 floor) · §6.2 mark 6 (the `⌫` glyph, the only drawn glyph in the app) · §7.14 (the sheet the pad sits in) | every value, the bottom row, and the never-disabled rule |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.6** (the keypad's semantics, element by element — the digit label rule, the pad container, the two live regions, the confirm bar) · §3.8 (the Android `didChangeLabel` re-announce rule) · §4.4 (`FittedBox` is banned) · §8.4 (ARB conventions) | what each node says, and why a label alone is not enough |
| `docs/engineering/07-screens.md` | §5.1 (where the pad sits relative to the strips; what gives up space first) · §5.3 (the `412 →` frame-1 label; over-cap renders **nothing**) · §5.4 (backspace is bottom-left, bottom-right when `leftHanded`; no key repeat) · **§5.6** (what is banned on this screen — no system keyboard, no OCR key, no microphone key) | the pad's place in the screen and the two cut features |
| `docs/engineering/CONVENTIONS.md` | **R70** (`ShedKeypad` is `lib/core/ui/components/shed_keypad.dart`; `big_keypad.dart` does not exist) · §2.11 · §4.2 (`Shed*`) · §4.5 (widget keys) · §1.1 layer rules 6 and 7 · R40 (`app_settings.left_handed`) | **BINDING** on the path, the class and every key |
| `docs/research/00-tech-decisions.md` | #57 (the keypad is the only numeric entry route; the decimal key) · #90 (no shed screen branches on `unlocked`) · #91 (`EntryContext.liveEntry` cannot be blocked) · #99 (never clamp text scale) · #100 (the 60 × 60 floor and its second geometric gate) · #101 (the gesture ban) · §7.0 rulings 5 and 6 (OCR and voice tag entry, **cut from v1**) | the four decisions and the two cuts |
| `shed-book-spec.md` | §7.1 (*"digits at least 40 pt"*) · §5 (the 3am test) | the number in the Definition of Done |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | the keypad is its largest control and its rules are explicit |
| `shed-accessibility-and-copy` | the semantics tree a keypad needs to be operable by a screen reader |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/keypad_test.dart`
- **Test** — `'no keypad key is ever disabled, including over the free cap'`
- **Why it is red today** — there is no keypad, and the system keyboard fails every clause of the 3am test.

```bash
fvm flutter test test/features/keypad_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so "disabled" is mechanical rather than visual. `ShedTapTarget` emits
`Semantics(button: true, enabled: onTap != null, onTap: onTap)` (`06 §6.2`), so for **every** key node
in the pad assert all three:

1. `SemanticsFlag.isEnabled` is set;
2. `SemanticsAction.tap` is present — *"nothing in `flutter_test` catches a missing action"*, and a node
   that announces as a button and then refuses to activate is the exact failure `06 §6.2` warns about;
3. tapping it actually calls the callback.

Then run the whole assertion across the **entitlement matrix**: `unlocked: false` with
`ewesInCurrentSeason` of `0`, `14`, `15`, `16` and `99`, and `unlocked: true`; and additionally with
the clock set inside the 22:00–06:00 window and outside it (`FreeTierPolicy.decide` takes `now`, R69).
Twelve pumps, one assertion. Finish with the strongest form available: the rendered pixels are
**identical** across all of them — capture `tester.getRect` for every key and compare, so "nothing
renders differently over the cap" (decision #90) is held by geometry and not by a reviewer's eye.

**Green.** The minimum code that passes, and nothing beyond it — the widget over `ShedTapTarget`, the semantics tree, and a test that pumps every
entitlement state.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no wiring, no controller.** This task is UI (step 6), ARB (step 6
item 22) and tests (step 7). Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_keypad.dart` | **New.** `ShedKeypad`, its key enum and the `⌫` glyph painter. **`lib/core/ui/components/`, not `features/quick_entry/widgets/`** (R70): Lambing Entry, Treatments and Settings all need the same pad and layer rule 6 forbids a sibling-feature import, so the feature-folder placement is not merely inconsistent — it is unbuildable |
| 2 | `lib/l10n/app_en.arb` | **Edit.** `keypadTagEntry`, `keypadBackspace`, `hintDeleteLastDigit`, `keypadNewTag`, `keypadEnteredTag`, `matchCountClosest` — every one with a `description` carrying its rationale (`10 §8.4` rule 2). `matchCountClosest` is an ICU plural: *"3 matches, closest 412"* / *"1 match, closest 412"* |
| 3 | `lib/features/quick_entry/quick_entry_screen.dart` | **Not yet.** The screen is T05. This task builds and tests the component in isolation, which is why its test file is `keypad_test.dart` and not `quick_entry_test.dart` |
| 4 | `docs/engineering/06-design-system.md` §8.2 **or** `docs/design/indelible.md` §7.2 | **Edit — whichever loses the bottom-row ruling in §5.3.** `00-README` §10's amendment rule: the losing document changes in the **same commit** |
| 5 | `test/features/keypad_test.dart` | **New.** The anchor plus the cases in §5.4 |

### 5.2 The signatures

`CONVENTIONS` §2.11 and §4.2 fix the name and the path; `06 §8.2` fixes the behaviour. The pad is a
`StatelessWidget` that watches nothing — `02 §10.1` is explicit: *"A `StatelessWidget`, **NOT** a
`ConsumerWidget`. It watches nothing, so it cannot be rebuilt by anything — which is the strongest
available proof that a digit cannot reach the keypad."*

```dart
// lib/core/ui/components/shed_keypad.dart
//
// The ONE numeric entry route in the app (decision #57). Tags, litter counts,
// ease scores, days and weights all come through here. There is no TextField on
// any numeric path and no system keyboard anywhere (06 §8.1).
//
// It watches nothing and is const-constructible, so a keystroke cannot rebuild
// it (02 §10.1). The moment someone makes it a ConsumerWidget to "just watch one
// thing here", every child below loses its const-ness.

/// The third key on the bottom row. See the ruling in the task file: the pad is
/// constructed with one of these and NEVER re-legends while it is on screen.
enum ShedKeypadThirdKey { newTag, decimal }

class ShedKeypad extends StatelessWidget {
  const ShedKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.thirdKey,
    required this.onThirdKey,
    this.leftHanded = false,
  });

  final ValueChanged<String> onDigit;   // '0'…'9' — a String, not an int:
                                        // the glyph and the buffer are text
  final VoidCallback onBackspace;
  final ShedKeypadThirdKey thirdKey;
  final VoidCallback onThirdKey;
  final bool leftHanded;                // mirrors the BOTTOM ROW only (R40)
}
```

The key box, from `06 §8.2`, computed rather than written down:

```dart
    final t = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    // Digit glyph is the `displaySmall` role = t.numeralSize: 40 pt in `night`,
    // 44 pt in either night-shift palette. The ROLE is the binding statement,
    // not the number (06 §8.2).
    final glyph = t.numeralSize;
    final side = math.max(t.tapPrimary, scaler.scale(glyph) * 1.6);
    // scale 1.0 -> max(72, 64) = 72. The floor governs until ~112% text scale,
    // after which the pad grows and the match list above it gives up rows.
```

Each key is a `ShedTapTarget`, which is what supplies both the label and the tap **action**
(`06 §6.2`), with the glyph inside so it is not announced twice:

```dart
    ShedTapTarget(
      key: const Key('quick_entry.keypad.digit_4'),   // R59: <screen>.<element>[.<qualifier>]
      semanticLabel: '4',                             // 10 §3.6: the label IS the digit —
      minSize: side,                                  // not "Four key", not "Digit four"
      onTap: () => onDigit('4'),
      child: ExcludeSemantics(child: Text('4', style: …)),
    )
```

Widget keys, spelled once and never renamed (`CONVENTIONS` §4.5 — *"a key is a test contract"*).
`12 §10.1` and `07 §5.4` already name two of them, before this file existed:

```
quick_entry.keypad                 the pad container
quick_entry.keypad.digit_0 … _9    the ten digits
quick_entry.keypad.backspace
quick_entry.keypad.new_tag         (thirdKey == newTag)
quick_entry.keypad.decimal         (thirdKey == decimal)
quick_entry.entered_tag            the live region carrying the buffer
quick_entry.match_count            the second live region
quick_entry.confirm                the ShedConfirmBar (N10-T03), placed by T05
```

The semantics tree, from `10 §3.6`, element for element:

| Element | Semantics |
|---|---|
| A digit key | `ShedTapTarget(semanticLabel: '<digit>')`. The label **is** the digit, because Voice Control matches the visible glyph. The glyph `Text` sits inside `ExcludeSemantics` |
| Backspace | `semanticLabel: l10n.keypadBackspace` ("Backspace"), `onTapHint: l10n.hintDeleteLastDigit`. No key repeat |
| The pad container | `Semantics(container: true, explicitChildNodes: true, label: l10n.keypadTagEntry)` so a VoiceOver user hears what they have landed in |
| The entered tag | A **live region**: `Semantics(liveRegion: true, role: SemanticsRole.status, attributedLabel: <spelled-out digits>)` |
| The match count | A **second** live region whose label carries the closest match — `l10n.matchCountClosest(count: n, tag: top)` → *"3 matches, closest 412"*. Counting alone re-announces nothing when 3 matches become a different 3 matches |

### 5.3 The details that are easy to get wrong

- **Two documents disagree about the bottom-right key, and the anchor test is exactly about that
  disagreement. Rule it here.**

  | Side | What it says | Where |
  |---|---|---|
  | `06` | *"Bottom-right is ALWAYS the decimal key; it renders **inert** (`surfaceRaised`, `textChrome`, `onTap` null) when the field is integer-only. The grid never re-legends."* | `06 §8.2` |
  | Indelible | Bottom row is `⌫ · 0 · NEW TAG`; `NEW TAG` is the create-on-the-fly action in the control face at `--t-ctl-sm` 19 px caps. Key state **Disabled: *"Never. No key is ever disabled — a dead key under a cold thumb is indistinguishable from a missed tap."*** | `indelible.md §7.2` |

  An **inert** key is a disabled key: `onTap: null` makes `ShedTapTarget` emit `enabled: false` and drop
  `SemanticsAction.tap` (`10 §3.6` says so in as many words). So `06 §8.2`'s decimal rule and the
  anchor test cannot both be satisfied. `CLAUDE.md`'s authority order puts `indelible.md` above the
  thirteen engineering documents, and this epic's constraint is *Indelible only*.

  **The resolution to implement, and to amend `06 §8.2` for in this commit:** the third key is a
  **constructor parameter** (`ShedKeypadThirdKey`), not a runtime state. A tag pad is built with
  `newTag`; a weight pad (N20, decision #57) is built with `decimal`. No key is ever disabled in either
  configuration, and `06`'s real requirement — *"the grid never re-legends"* — is preserved, because the
  pad's legend is fixed for as long as it is on screen. If the ruling goes the other way, the anchor
  test's name has to change, which is the strongest sign it should not.
- **Three keypad geometries are in the doc set and only one is binding.** `07 §5.1` sketches *"72 pt
  keys, 44 pt glyphs, 16 pt gaps"*; Indelible §7.2 draws `117 × 84` with 8 px gaps at a 393 px viewport;
  `06 §8.2` gives the contract. `06 §8.2` settles it in its own text: *"the binding statement is the
  role, not the number"* — the glyph is the `displaySmall` role (`t.numeralSize`, 40 pt in `night`,
  44 pt in a night-shift palette) and the box is `max(tapPrimary, scaler.scale(glyph) * 1.6)`. Indelible's
  `117 × 84` is the CSS artefact's rendering at one viewport and is **larger** than the 72 floor, so
  both hold. **Write no literal.** Every number comes from `context.tokens`; a magic size is a
  build-breaking defect.
- **P9 is not ruled yet, so do not freeze a gap number.** `06 §6.1` says `gapMin` 16; Indelible §4.1
  says `--s-2` 8 px key gaps. The conflict is ruled at **N33-T03**. Read `context.tokens.gapMin` and
  assert the **target floor**, never the gap — an assertion on 16 (or on 8) written here reads as
  settled a whole epic before the ruling exists.
- **`Expanded` inside the keypad `Row` overrides `minWidth`** and will silently shrink a key below the
  floor on a 320 pt device once page padding is added (`06 §8.2`). Use explicit sizing. The geometric
  gate at 320 × 568 is what catches it, and it is N33's — so the cheap version lives here, as a case at
  `Device.small`.
- **`FittedBox` is banned** (`06 §8.2`, `10 §4.4`). Shrinking a tag number to fit is the opposite of
  legible. So is clamping `textScaler`: decision #99 bans it outright and it defeats Android 14+'s own
  non-linear curve. **The pad is allowed to consume more screen as text grows** — the filtered match
  list gives up rows first, then the "in the pens" strip; the keypad, the confirm bar and the recents
  strip never give up anything (`07 §5.1`).
- **The digits are set in the RECORD face, and that is the one documented exception in the type
  system.** Indelible §3.5 rule 5: they are *"the only sans-shaped thing that would become serif-shaped
  the instant you press it, and the shepherd is matching a digit on a key against a digit already
  printed in the recents list and in the row above. Same shape, same width, no translation step."*
  Everything else on the pad — `NEW TAG`, `Backspace` — is a **control** and wears the machine face.
  Getting this backwards inverts the system's one learnable rule (*serif = record, sans = control*).
- **Every figure is tabular.** `font-variant-numeric: tabular-nums lining-nums` — in Flutter,
  `FontFeature.tabularFigures()` on the style. Indelible §3.5 rule 2: *"a digit must never change width
  or shape between the button you press and the row it prints into."*
- **The haptic fires on *down*, before the state change.** `HapticFeedback.selectionClick()` — the
  lightest tick on both platforms — so the finger feels the *key*, not the result (`06 §8.2`). Use the
  vocabulary `motion.dart` exposes (N09-T09), not a raw call, and note that P10 (four haptics or five)
  was ruled in that task: read the ruling before you pick a name.
- **No key repeat on backspace, and no long-press anywhere.** Key repeat requires a *held contact*,
  which is a banned gesture (`CLAUDE.md`: no long-press bindings, no hold-to-repeat). A separate visible
  **Clear** control exists for clear-all; clear-all is never a long press. `onLongPress` must not appear
  in this file.
- **There is no OCR key and no microphone key.** Owner rulings §7.0 items 5 and 6: tag OCR and voice
  tag entry are **cut from v1**, and *not open*. The voice **note** ships (via `record` 7.1.1, N15).
  `06 §8.1`: *"the pad is the only tag-entry route and must be designed as such, not as a fallback for
  something else."* `08-platform-integration.md` records both as v2 candidates with the reason, so a
  future contributor does not reopen them.
- **`leftHanded` mirrors the bottom row and nothing else.** R40 and `07 §14.3` row 8: the setting
  mirrors the keypad's bottom row **and** the bottom action bar order, and nothing else. The spine does
  not move (Indelible §4.5); the digit grid does not move. `10 §7.2` row 10 requires the sweep to run
  **both ways**, because *"a mirrored layout that clips at AX5 is a defect the default layout hides"*.
- **Nothing in this file may watch `entitlementProvider`, `purchaseServiceProvider` or
  `freeTierPolicyProvider`.** Decision #90's failure mode is a paywall flash at 3am. The pad is a
  `StatelessWidget` with no `WidgetRef` at all, which makes that structurally impossible — keep it that
  way. `FakePurchaseService.calls` must stay empty through every pump in this file (`12 §4.2`).
- **"No `TextField` and no system keyboard anywhere in the app" means anywhere *numeric*.** The one
  text input in the product is the free-text note (Indelible §7.12; `01 §4.5` gives it a 400 ms
  debounce), and it is N15's. Write the assertion as the exact thing that must never exist:
  **zero `keyboardType:`, zero `TextInputType.` and zero `TextInputFormatter` under `lib/`**, plus zero
  `TextField` under `lib/features/quick_entry/`. That holds the real rule without colliding with the
  note field.
- **The `⌫` glyph is drawn, not typed.** Indelible §6.2 mark 6: it is the only drawn glyph in the app,
  inline SVG at 2 px stroke, butt caps, miter joins, 28 × 28, `currentColor`. Render it as a
  `CustomPainter` (there is no icon set and no icon font — §6.1). The word `DELETE` is refused because
  *"the word takes longer to find on a key than a shape does"*.

### 5.4 The full test set

`test/features/keypad_test.dart`, all through `pumpApp` (N12-T05). Every `meetsGuideline` run begins
with `tester.ensureSemantics()` (decision #115).

| Case | What it asserts |
|---|---|
| `'no keypad key is ever disabled, including over the free cap'` | **The anchor.** Twelve pumps across the entitlement matrix and both sides of the 22:00–06:00 window; every key node has `isEnabled` **and** `SemanticsAction.tap`; every key `Rect` is identical across all twelve |
| `'every key is at least tapPrimary square at every device and text scale'` | `Device.all` × `{1.0, 1.3, 2.0}`. Reads `context.tokens.tapPrimary`, never a literal |
| `'the digit glyph is at least 40 pt at scale 1.0, and 44 in a night-shift palette'` | `numeralSize` per palette. Spec §7.1's number, met at the smallest configuration the app can be in |
| `'the pad is three columns by four rows at every text scale'` | It grows, it never re-lays out. The one component permitted to wrap is the ease group (Indelible §3.6), and this is not it |
| `'no key shrinks below the floor at Device.small once page padding is applied'` | The `Expanded` trap from `06 §8.2`, at 375 × 667 |
| `'FittedBox, TextScaler clamping and TextInputType appear nowhere'` | Source text over `lib/`. Three bans in one case, each with its own `reason:` |
| `'lib/features/quick_entry/ contains no TextField'` | The numeric-path half of the DoD's claim, stated exactly |
| `'the third key is fixed at construction and the grid never re-legends'` | Pump with `newTag`, then with `decimal`; assert the legend matches the parameter and never changes while mounted |
| `'the label of a digit key is the digit, not a phrase'` | `10 §3.6`: `'4'`, never `'Four key'`. Voice Control matches the visible glyph |
| `'the glyph Text is not announced twice'` | Exactly one semantics node per key |
| `'the pad container announces what you have landed in'` | `container: true`, `explicitChildNodes: true`, label from `l10n.keypadTagEntry` |
| `'the entered-tag live region changes label between two presses of the same digit'` | Press `4`, then `4`. Labels `'4'` then `'44'` — different strings, so Android's `didChangeLabel()` fires. Two identical labels are silent on Android (`10 §3.8`) |
| `'the match-count live region names the closest match'` | *"3 matches, closest 412"*; and the singular arm, *"1 match, closest 412"*, because ICU plural |
| `'backspace does not repeat under a held pointer'` | `startGesture`, hold past any plausible repeat delay, release: exactly one call. Also: `onLongPress` appears nowhere in the file |
| `'leftHanded mirrors the bottom row and nothing else'` | Digit `1`'s `Rect` is unchanged; backspace and the third key swap. Run the whole geometry group both ways |
| `'no banned gesture widget appears in the pad'` | `Dismissible`, `Draggable`, `Tooltip`, `Slider`, `InkWell` with `onLongPress` — all zero |
| `'nothing in the pad watches an entitlement or store provider'` | Source text plus `FakePurchaseService.calls` empty after every pump (decision #90) |
| `'the digits are tabular and set in the record face; the word keys are in the control face'` | Reads the resolved `TextStyle`. Indelible §3.5 rules 2 and 5 |
| `'the pad renders identically at 03:20 and at 14:00, at any entitlement'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30** inside the ambiguous repeated hour, then at 14:00. `FreeTierPolicy.decide` takes `now` for the 22:00–06:00 quiet window (R69), so the clock is an input the cap can read — this case asserts the **negative**: no pixel, no label and no enabled flag on this pad may vary with it. The repeated hour is the one where a naive window check can evaluate twice and flip |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Nothing monetization-related renders here, at any entitlement state, ever** (decision #90, #92).
  Quick Entry is one of the five shed screens.
- **The pad emits no `headingLevel`.** `10 §3.4`: Quick Entry carries a level-1 title and **no** level-2
  headings, deliberately — *"each is one task, and heading stops would add navigation to screens whose
  entire purpose is not having any."* `Semantics(header: true)` is a no-op since 3.44 and is banned in
  review (decision #104).

## 7. Definition of Done

- [ ] `'no keypad key is ever disabled, including over the free cap'` passes, and was seen to fail first for the stated reason
- [ ] no key is ever disabled in any state
- [ ] digits are at least 40 pt on 64 × 64 targets
- [ ] no `TextField` and no system keyboard anywhere in the app
- [ ] the semantics tree announces each key and the current entry
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the file is `lib/core/ui/components/shed_keypad.dart`; `features/quick_entry/widgets/big_keypad.dart` does not exist (R70)
- [ ] `ShedKeypad` is a `StatelessWidget` and holds no `WidgetRef`
- [ ] every size comes from `context.tokens`; the file contains no numeric literal for a target, a gap or a glyph
- [ ] **the bottom-row conflict is ruled and the losing document amended in this same commit**, or carried into the PR body with both sides cited
- [ ] the two live regions exist and consecutive labels differ
- [ ] `FittedBox`, `keyboardType:`, `TextInputType.`, `onLongPress` and every banned gesture widget appear nowhere in this file
- [ ] `leftHanded` mirrors the bottom row only, and the geometry group runs both ways
- [ ] `FakePurchaseService.calls` is empty after every pump in this file
- [ ] the `uk-zone` clock-invariance case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/keypad_test.dart
fvm flutter test test/design/                 # nothing in the design tier regressed
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
ls lib/core/ui/components/shed_keypad.dart                        # exists
ls lib/features/quick_entry/widgets/big_keypad.dart               # must NOT exist
grep -rn "FittedBox\|keyboardType\|TextInputType\|TextInputFormatter" lib/   # expect zero
grep -rn "onLongPress\|Dismissible\|Draggable\|Tooltip\|Slider(" lib/        # expect zero
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/core/ui/         # expect zero
grep -nE "[^a-zA-Z](6[0-9]|7[0-9]|8[0-9]|11[0-9])(\.0)?[^0-9]" lib/core/ui/components/shed_keypad.dart   # expect zero magic sizes
grep -n "GoogleFonts" lib/                                         # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): ShedKeypad, the only number entry in the app`
