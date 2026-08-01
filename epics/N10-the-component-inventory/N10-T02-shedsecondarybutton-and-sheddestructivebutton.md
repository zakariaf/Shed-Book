# N10-T02 — `ShedSecondaryButton` and `ShedDestructiveButton`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 2 of 8 |
| **Depends on** | N10-T01 |
| **Commit** | one commit · `feat(ui): the word button's secondary and destructive forms` |

## 1. Why this task exists

The word button's two forms. The destructive form carries **two-step destruction** and
`gapDestructive` separation, so the tap that deletes a season is never adjacent to the tap that does
not.

There is a second reason, and it is Indelible's signature: **there is no delete in this product.** A
destructive action draws a line and prints a time — the row stays on the page, legible, forever
(§1.1 rule 1, §11 test 1). So this component's verb is `STRIKE`, its colour is the madder ink, and it
is never a filled red rectangle: *"a filled red button is a thing you press by accident."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedSecondaryButton`: ≥ `tapPrimary` tall, outlined at `outlineWidth`; `ShedDestructiveButton`: the same plus a **confirming** state, never within `gapDestructive` of a frequent action, two-step) · §6.1 (`gapMin` 16 / `gapDestructive` 32 and why they are double Material's) · §6.3 (the geometric gate's gap assertion) · §7 (swipe-to-delete is banned, so destruction has nowhere left to hide) | the size contract, the separation, the two-step rule |
| `docs/design/indelible.md` | §7.13 (**the word button in full** — six states, the in-stream underline form, and *"never a filled red button"*) · §1.1 rule 1 and §11 test 1 (**there is no delete; striking is a word button that draws a line**) · §6.2 mark 5 (the strike line: 3 px `--madder-ink`, `transform-origin: left`, doubled in red-shift) · §5.1 (`--motion-strike` 180 ms linear — the only animation in the app with a direction) | every value, and what the destructive form actually does |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rule 7 · §4.1–§4.2 · §5.1 (**strike**, not delete; the banned nouns) · §5.3 (banned words) | the paths, the names and the verb |
| `docs/engineering/00-README.md` | §8 step 28 (**a destructive action gets a `tester.tap(); tester.tap();` double-tap test**) · §2.4 (every write commits immediately) | the test this task must end with |
| `docs/engineering/07-screens.md` | §15.1 (undo per verb — what a strike leaves visible) · §15.6 (swipe-to-delete stays banned) · §14.4 (the only two four-tap destructive flows, and they are Settings') | why two steps and not a dialog |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | the button forms and the two-step destruction pattern |
| `indelible-marks-and-strikes` | a delete is a mark before it is an action |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedDestructiveButton requires two taps and is separated by gapDestructive from any other target'`
- **Why it is red today** — only the primary slab exists; the first destructive action would be a single tap.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen it into the two halves it names, and make the second one geometric rather than a promise:

```dart
// half 1 — two taps, and the first one commits nothing
int fired = 0;
await tester.tap(find.byType(ShedDestructiveButton));
await tester.pump();
expect(fired, 0, reason: 'the first tap arms, it does not strike');
await tester.tap(find.byType(ShedDestructiveButton));
await tester.pump();
expect(fired, 1);

// half 2 — the separation is in the widget's own laid-out box, not in the screen
final Rect me    = tester.getRect(find.byType(ShedDestructiveButton));
final Rect other = tester.getRect(find.byKey(const Key('probe.neighbour')));
expect(gapBetween(me, other), greaterThanOrEqualTo(32.0));   // gapDestructive
```

`gapBetween` is `06 §6.3`'s helper; the probe neighbour is a plain `ShedTapTarget` laid out flush
against the destructive button by the test, so the assertion fails unless the component reserves the
gap itself.

**Green.** The minimum code that passes, and nothing beyond it — both widgets, the two-step interaction, and the geometric separation assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB entry — both
components take their copy as parameters, for the reason N10-T01 §5.3 gives. Say so in the commit
message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_secondary_button.dart` | **New.** Indelible's word button: the outlined form `06 §12` contracts for, plus the in-stream underline form §7.13 needs for a filter row (`ALL`, `THIS SEASON`) |
| 2 | `lib/core/ui/components/shed_destructive_button.dart` | **New.** A separate file, not a `destructive: true` flag on the secondary button. The two-step state machine, the reserved `gapDestructive` inset and the madder ink are all specific to it, and a boolean flag is how a screen ends up with a one-tap strike |
| 3 | `test/design/components_test.dart` | **Extend.** Reuses T01's `_pumpComponent`. Adds the two-step cases, the double-tap case `00-README` §8 step 28 requires, and the geometric separation case |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_secondary_button.dart

/// indelible.md §7.13's two forms. `outlined` is `06 §12`'s contract — 2 px
/// at `outlineWidth`, fill `surfaceFill`. `inStream` is the filter row: no
/// fill, no border, a 2 px underline the width of the word.
enum ShedSecondaryButtonForm { outlined, inStream }

final class ShedSecondaryButton extends StatelessWidget {
  const ShedSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.form = ShedSecondaryButtonForm.outlined,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;      // non-nullable, for N10-T01 §5.3's reason
  final String semanticLabel;
  final ShedSecondaryButtonForm form;
  /// Only meaningful for `inStream`: the underline lifts to `textPrimary`
  /// while its siblings sit at `textSecondary`.
  final bool selected;
}
```

```dart
// lib/core/ui/components/shed_destructive_button.dart

/// Two steps, and the first one is not a dialog. `06 §12` lists `confirming`
/// as a real state of this component precisely so that a screen does not need
/// `showDialog(` to get a confirmation — which is banned outside the two
/// allowlisted Settings files (CONVENTIONS §4.7, `ui.show_dialog`).
enum ShedDestructiveButtonState { armed, confirming }

final class ShedDestructiveButton extends StatefulWidget {
  const ShedDestructiveButton({
    super.key,
    required this.label,           // 'STRIKE'
    required this.confirmLabel,    // 'STRIKE — TAP AGAIN'
    required this.onConfirmed,     // fires on the SECOND tap only
    required this.semanticLabel,
    required this.confirmSemanticLabel,
  });

  final String label, confirmLabel, semanticLabel, confirmSemanticLabel;
  final VoidCallback onConfirmed;
}
```

The two facts the state class owns:

```dart
  // 1. The reserved separation. The widget cannot see its neighbours, so it
  //    reserves the gap inside its OWN laid-out box. That is what makes the
  //    rule structural rather than something twelve screens must remember.
  Padding(padding: EdgeInsets.all(t.gapDestructive), child: /* the target */)

  // 2. The disarm. `confirming` decays back to `armed` when the route pops or
  //    the widget is disposed. There is NO timer: a state that unwinds itself
  //    after n seconds is a state that changes under a thumb already moving,
  //    and `--motion-press` is the only duration this component holds.
```

### 5.3 The details that are easy to get wrong

- **The madder ink has no field in `06 §3.3`'s `ShedTokens` list.** Indelible's `--madder-ink`
  (`#D4685C`, 5.59:1 on the page) carries the strike line, `STRUCK`, the query mark and the dagger —
  and `06 §3.3` ships `statusReady` / `statusAttention` / `statusLoss` / `onStatus` with, in
  N09-T02's own words, *"no Indelible equivalent"*. **Read the mapping doc comment at the top of
  `tokens.dart`** — N09-T02 was required to write it — and use the field it names. If no field
  carries the madder, adding one is `06 §1`'s sanctioned route (*"if a direction needs a token this
  system does not have, add the token"*), and it is not a free edit: every `ShedTokens` field is
  `required`, so a new field means editing **all six palette literals** in `palettes.dart` and
  re-running `contrast_test.dart`. Do that in this commit or not at all; do not hard-code the hex.
- **Never a filled red button.** Indelible §7.13's destructive row is label and underline in the
  madder, on the page fill. A filled red rectangle is both the thing §7.13 refuses and a contrast
  problem: the madder is a 5.59:1 *ink*, measured against `--page`, not a surface anything sits on.
- **`gapDestructive` is 32, and `06 §6.3`'s sweep only asserts 16.** The geometric gate's rule is
  `gapBetween(a, b) == 0 || >= 16` — it cannot know which target is destructive. So the 32 pt rule is
  held here, by the component reserving its own inset, and asserted here, in this file's own case.
  Deleting the inset makes the sweep still pass, which is exactly why the local case matters.
- **The double-tap test is not the two-step test.** `00-README` §8 step 28 asks for
  `tester.tap(); tester.tap();` on a destructive action; that case here asserts **one** strike from
  two taps. The *other* double-tap defence — a fast double tap racing a write — is
  `WriteController.guard()` (N12-T04), which refuses to run concurrently. This component is not a
  substitute for it and the doc comment should say so, or a screen epic will assume the guard is
  already handled.
- **No `showDialog(` and no `AlertDialog`.** `ui.show_dialog` (`CONVENTIONS §4.7`) allowlists exactly
  two files, both in Settings, both landing at N29. A confirmation built out of a dialog here would
  be a rule violation *and* would put the confirm target behind a scrim tap, which is not a labelled
  target (`06 §7`).
- **`confirming` must change the words, not only the colour.** Decision #106 and WCAG 1.4.1: colour is
  never the only channel. The armed and confirming states differ by **label text** first — that is
  why `confirmLabel` and `confirmSemanticLabel` are separate required parameters and not derived by
  appending a string in the component.
- **The strike animation is not this component's.** `--motion-strike` (180 ms, `linear`,
  `scaleX(0) → scaleX(1)`, origin left) draws across the **record row**, not across the button.
  Indelible §5.1 calls it the one animation in the app with a direction; it belongs to the row that
  gets struck, which is N16's. This button fires a callback and stops.
- **The word is `strike`, everywhere.** `CONVENTIONS §5.1`–§5.3 and Indelible §11 test 1: search the
  codebase for `DELETE`, `remove`, `splice`, `hidden` — the only legal hits are Settings' two
  season-level actions. A parameter named `onDelete`, an ARB key `deleteLamb` or a commit message
  saying *delete* is a defect in this task.
- **Both files repeat T01's traps.** Token before literal (`t.gapMin * 2`, never `2 * t.gapMin`); no
  `colorScheme`; no constructed `TextStyle`; `ShedTapTarget` underneath or the N33 sweeps cannot see
  it; `onTap` non-nullable — Indelible §7.13's disabled row is *"avoided; where genuinely impossible,
  `--ink-low` with a dotted underline and a printed reason beside it."*

### 5.4 The full test set

`test/design/components_test.dart`, extended.

| Case | What it asserts |
|---|---|
| `'ShedDestructiveButton requires two taps and is separated by gapDestructive from any other target'` | **The anchor.** One tap arms and fires nothing; the second fires exactly once; the laid-out gap to a flush neighbour is ≥ 32 |
| `'tapping ShedDestructiveButton twice in the same frame strikes once'` | `00-README` §8 step 28's literal `tester.tap(); tester.tap();` with no `pump` between — the fast-thumb case, not the deliberate one |
| `'the confirming state changes the label, not only the colour'` | The rendered text after tap 1 differs from the text before it. Decision #106 in one assertion |
| `'confirming reverts on dispose and never on a timer'` | Pump the widget away and back: state is `armed`. Then `tester.pump(const Duration(seconds: 30))` while mounted: state is still `confirming`. Source text: no `Timer`, no `Future.delayed` in the file |
| `'ShedDestructiveButton renders no filled surface behind the madder ink'` | The target's background resolves to the page surface, not to a status colour. Indelible §7.13 |
| `'ShedSecondaryButton is at least tapPrimary tall in both forms'` | 72 in `outlined` and in `inStream`, at textScaler 1.0, 1.3 and 2.0 |
| `'ShedSecondaryButton renders at textScale 2.0 with boldText and every tap surface carries a semanticLabel'` | The epic-wide case, this component's row |
| `'the inStream form draws an underline and no border, and outlined draws a border and no underline'` | The two forms are visually distinguishable with the colour channel removed |
| `'selected lifts the underline ink and leaves the siblings alone'` | Three buttons in a row, one selected: exactly one at `textPrimary` |
| `'neither file names delete, remove, splice or hidden'` | Source text over both files. Indelible §11 test 1, made mechanical |
| `'neither file calls showDialog( or constructs an AlertDialog'` | Source text. `ui.show_dialog` allowlists two Settings files and neither is here |

**Nothing here is time-shaped.** The only duration in either file is `--motion-press`, 40 ms, and it
survives reduce-motion unchanged (Indelible §5.3) — assert that in `reduce_motion_test.dart`'s
existing file rather than adding a clock to this one.

## 6. Constraints that bind this task

- **3am** — ≥ `tapPrimary` (72) tall, `gapMin` (16) from any target, **`gapDestructive` (32) from any
  target for the destructive form**, 18 px floor, dark only. No swipe, no drag, no long-press: with
  swipe-to-delete banned there is nowhere left to hide destruction, and `06 §7` says that is the
  point — deletion becomes explicit and two-step.
- **There is no delete** — Indelible §1.1 rule 1. Held in the vocabulary (`strike`), in the API
  (`onConfirmed`, never `onDelete`) and in a source-text test. A rule held only in prose has been
  deleted.
- **Two-step destruction is held by the widget, not by the screen.** So is the 32 pt separation. Every
  screen that forgets is a screen that ships a one-tap strike next to a frequent action.
- **No ARB entry** — `label`, `confirmLabel` and both semantic labels are required parameters. The
  screen epic authors the messages with their `description`s.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedDestructiveButton requires two taps and is separated by gapDestructive from any other target'` passes, and was seen to fail first for the stated reason
- [ ] the destructive form cannot fire on one tap
- [ ] separation is enforced by the widget, not by each screen remembering
- [ ] a double-tap test exists, per `00-README` §8 step 28
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the destructive form is never a filled red rectangle, and its ink comes from a `ShedTokens` field, not a literal
- [ ] `confirming` differs from `armed` by its **words** as well as its ink
- [ ] `confirming` unwinds on dispose and on no timer
- [ ] neither file contains `delete`, `remove`, `splice`, `hidden`, `showDialog(` or `AlertDialog`
- [ ] if a token was added to `ShedTokens` for the madder ink, all six palettes and `contrast_test.dart` moved in this commit

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -niE "delete|remove|splice|hidden" lib/core/ui/components/shed_destructive_button.dart  # expect zero
grep -n "showDialog(\|AlertDialog" lib/core/ui/components/                                   # expect zero
grep -n "Timer\|Future.delayed" lib/core/ui/components/shed_destructive_button.dart          # expect zero
grep -n "gapDestructive" lib/core/ui/components/shed_destructive_button.dart                 # expect one
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): the word button's secondary and destructive forms`
