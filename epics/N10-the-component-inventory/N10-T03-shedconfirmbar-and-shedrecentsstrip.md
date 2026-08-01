# N10-T03 — `ShedConfirmBar` and `ShedRecentsStrip`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 3 of 8 |
| **Depends on** | N10-T02 |
| **Commit** | one commit · `feat(ui): ShedConfirmBar and ShedRecentsStrip, fixed height from frame 1` |

## 1. Why this task exists

Both outcome-labelled and both at **fixed height from frame 1**, so nothing shifts under a
thumb that is already moving. A strip that grows when data arrives is a mis-tap at 3am.

The fixed height is not a nicety, it is the whole no-spinner design. `06 §9.3`: the first painted
frame is *"a static dark Quick Entry shell with a fully interactive keypad and no data"*, and the
recents strip is one of the two frame-1 placeholders that must reserve their box before the database
has opened. Decision #71 is the other half: **never a spinner, anywhere.**

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedConfirmBar`: full width × `tapHero`, labelled with the outcome; `ShedRecentsStrip`: 6 chips × `tapPrimary`, states include **placeholder**, fixed height at frame 1) · §8.2 (**the keypad geometry contract and the Quick Entry stack order** — the confirm bar is a separate full-width `tapHero` bar labelled with the outcome, *"never a bare tick"*) · §9.3 (frame-1 placeholders are fixed-height `surfaceRaised` blocks; there is never a spinner) | both size contracts and the label rule |
| `docs/design/indelible.md` | §7.15 (the recents line — six of them, `412 · penned 2h · twin last year`) · §7.14 (the sheet the strip sits in) · §4.4 (row heights) · §5.2 (**rows never reorder, never slide, never crossfade; the page re-prints instantly**) | the content of one entry, and what may not animate |
| `docs/engineering/07-screens.md` | §5.1 (the Quick Entry stack, and that the keypad, confirm bar and recents strip **never give up anything**) · §5.2 (`quickEntryDeckProvider` — one statement, two strips; `recentEwesProvider` is a banned spelling) · §2.2 (the empty copy: *"No recent animals."*) · §5.3 (the error state: the strips fail, **the keypad keeps working**) | what the strip is fed and what it says when empty |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rule 7 · §4.1–§4.2 · §4.7 (**`ui.spinner` is scoped to `lib/features/`**) · R28 (the deck is one provider) | the paths, and the gate hole this task has to cover itself |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | confirmation and receipt shapes are its subject |
| `indelible-controls` | the strip is a row of targets and obeys the control rules |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedRecentsStrip occupies the same height empty and full'`
- **Why it is red today** — neither exists, and the recents strip is the second-most-used control in the product.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen it to **four** states, not two, and compare the laid-out height rather than a constraint:

```dart
final heights = <String, double>{};
for (final entry in <String, List<ShedRecentsEntry>?>{
  'placeholder': null,          // frame 1: the database has not opened
  'empty':       const [],      // opened, nothing to show
  'partial':     three,
  'full':        six,
}.entries) {
  await _pumpComponent(tester, ShedRecentsStrip(entries: entry.value, /* … */));
  heights[entry.key] = tester.getSize(find.byType(ShedRecentsStrip)).height;
}
expect(heights.values.toSet(), hasLength(1), reason: 'the strip shifted: $heights');
```

Then run the same four states at textScaler 1.0, 1.3 and 2.0. The height may differ **between**
scales — text grows — but never between states **at** a scale.

**Green.** The minimum code that passes, and nothing beyond it — both widgets with a reserved box, and a test that pumps empty and full and compares the
laid-out height.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB entry — the
empty copy (*"No recent animals."*) and the confirm verb both arrive as parameters, because they are
`07 §2.2`'s and the screen's respectively. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_confirm_bar.dart` | **New.** The full-width `tapHero` bar. It is not a `ShedPrimaryButton` with different padding: the slab is one-per-page and corner-anchored, the confirm bar is full-width and lives in the sheet's bottom edge (`06 §8.2`'s stack order) |
| 2 | `lib/core/ui/components/shed_recents_strip.dart` | **New.** The strip plus the immutable `ShedRecentsEntry` it renders. Six maximum, one fixed height, four states |
| 3 | `test/design/components_test.dart` | **Extend.** The four-state height case, the outcome-label case, the six-maximum case and the no-spinner source case |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_recents_strip.dart

/// One entry, already formatted. indelible.md §7.15: `412 · penned 2h ·
/// twin last year` — a tag in the record voice and a summary in the control
/// voice. Both arrive as strings: `hours since penned` is a Duration the
/// CALLER turned into `2h` through `formatters.dart`, because a component in
/// lib/core/ui/ reads no clock and imports no provider (layer rule 7).
@immutable
final class ShedRecentsEntry {
  const ShedRecentsEntry({
    required this.tag,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
  });

  final String tag, summary, semanticLabel;
  final VoidCallback onTap;
}

final class ShedRecentsStrip extends StatelessWidget {
  const ShedRecentsStrip({
    super.key,
    required this.entries,          // null == frame 1, before the database opened
    required this.emptyLabel,       // '07 §2.2': 'No recent animals.'
    this.selectedTag,
  });

  /// `null` is the placeholder state and `const []` is the empty state. They
  /// are different facts and they render differently; collapsing them is how
  /// a shepherd on day one is told the app lost their flock.
  final List<ShedRecentsEntry>? entries;
  final String emptyLabel;
  final String? selectedTag;

  /// Spec §7.1. Asserted in the constructor AND in the layout, because an
  /// assert is stripped in release.
  static const int maxEntries = 6;
}
```

```dart
// lib/core/ui/components/shed_confirm_bar.dart

final class ShedConfirmBar extends StatelessWidget {
  const ShedConfirmBar({
    super.key,
    required this.outcomeLabel,     // 'Create 412' / 'Use 412' / '7 days — as entered by you'
    required this.onTap,            // non-nullable — N10-T01 §5.3
    required this.semanticLabel,
  });

  final String outcomeLabel, semanticLabel;
  final VoidCallback onTap;
}
```

Height comes from tokens and from nothing else:

```dart
  SizedBox(height: t.tapHero,     child: /* confirm bar   */)   // 88
  SizedBox(height: t.tapPrimary,  child: /* recents strip */)   // 72
```

### 5.3 The details that are easy to get wrong

- **`null` entries and `const []` entries are different states.** Frame 1 has not read the database;
  empty has. `06 §9.3` wants a fixed-height `surfaceRaised` block for the first and `07 §2.2` wants
  *"No recent animals."* for the second. A nullable list is the cheapest way to keep them apart, and
  `entries.isEmpty` on a non-nullable list is the bug: on day one the shepherd sees the frame-1 grey
  block forever and concludes the strip is broken.
- **`ui.spinner` is scoped to `lib/features/`, and this is the one folder it does not cover.**
  `CONVENTIONS §4.7` adds the row as *"`CircularProgressIndicator` under `lib/features/`"*. A spinner
  written into `lib/core/ui/components/shed_recents_strip.dart` passes the gate and then renders on
  every screen that mounts the strip. Hold it here with a source-text case over the whole components
  folder, and say in the commit message that you did.
- **Six is the maximum and it is not a scroll.** `06 §12` says six chips; `07 §5.1` says the strip
  *"never gives up anything"* when the layout is tight — the filtered-match list loses rows first,
  then the pens strip. So the strip neither scrolls nor shrinks: it renders `min(entries.length, 6)`
  and drops the tail. Assert with nine entries in, six rendered.
- **The arrangement is horizontal, and here is the arithmetic that settles it.** `06 §12` says *6
  chips × `tapPrimary`*; `indelible.md` §7.15 says *six full-width 64 px ruled lines inside the
  sheet*. Both cannot hold in Quick Entry's viewport: `06 §8.2` fixes the keypad at
  `84 × 4 + 8 × 3 = 360`, the confirm bar at `tapHero` 88, and `06 §8.2`'s stack order puts the
  entered tag and up to three match rows above both — six ruled lines at 64 would need another 384 px
  on a 667 px-tall `Device.small`. Take **`06 §12`'s horizontal band**, and record in the PR body
  that Indelible §7.15's ruled-line form survives as the **index sheet's** row rendering, which is
  `ShedBottomSheet` content and N13's to place. Do not freeze a screen decision in a shared control.
- **The confirm bar is labelled with the outcome, and the banned labels are a test, not a habit.**
  `06 §8.2`: *"labelled with the OUTCOME — 'Use 412' / 'Create 412' — never a bare tick."* `OK`,
  `Done`, `Confirm`, `Submit`, `✓` and — Indelible §11 test 7 — the string `Save` are all wrong. The
  component cannot compose the label, so it asserts against the set instead.
- **`06 §12` lists a `disabled` state on the confirm bar and this task does not build one.**
  N10-T01 already ruled the same conflict for the slab: a target that announces as a button and then
  refuses is worse than one that explains itself. The confirm bar with nothing to confirm carries the
  outcome that is **missing** (*"Type a tag"*) and still fires, opening the thing that is missing.
  `onTap` stays non-nullable. If the owner rules the other way it is one enum member — say so in the
  PR body rather than quietly shipping either reading.
- **Nothing animates between states.** Indelible §5.2: *"rows never reorder, never slide, never
  crossfade. The page re-prints instantly with no transition — a crossfade at 3am reads as a lag, and
  a lag reads as 'it didn't save'."* No `AnimatedSwitcher`, no `AnimatedContainer`, no
  `AnimatedOpacity` on state change. `--motion-ink` (120 ms, opacity only) is for a **newly printed
  glyph**, not for a strip swapping its contents.
- **The strip is fed by one provider and this component does not know that.** `07 §5.2` and R28:
  `quickEntryDeckProvider` is a single `StreamProvider<QuickEntryDeck>` and both strips read it with
  `.select`; `recentEwesProvider` and `inPensProvider` are **banned spellings**. None of that reaches
  this file — a component reads no provider — but the doc comment should name the provider so the
  screen epic does not wire a second query.
- **Every entry is its own `ShedTapTarget`, `gapMin` apart.** `06 §6.3`'s geometric gate asserts
  `gapBetween(a, b) == 0 || >= 16`. A `Row` with `spacing: t.gapMin` gets it right; a `Wrap` with
  default spacing gets it wrong and the sweep only notices at N33, twelve screens later.

### 5.4 The full test set

`test/design/components_test.dart`, extended.

| Case | What it asserts |
|---|---|
| `'ShedRecentsStrip occupies the same height empty and full'` | **The anchor**, across all four states — placeholder, empty, partial, full — at textScaler 1.0, 1.3 and 2.0 |
| `'a null entry list renders the frame-1 placeholder and an empty list renders the empty copy'` | The two states are distinguishable by their rendered text. The day-one bug, caught |
| `'nine entries render six'` | `ShedRecentsStrip.maxEntries`, held in the layout and not only in an `assert` |
| `'every recents entry is a ShedTapTarget at least tapPrimary tall with a semanticLabel'` | Six targets, each ≥ 72, each labelled — the N33 sweeps find them by type |
| `'adjacent recents entries are gapMin apart or touching'` | `gapBetween` over the six rects: `0` or `>= 16`, never 4 |
| `'ShedConfirmBar is full width and tapHero tall'` | Width equals the parent's; height ≥ 88 at every text scale |
| `'ShedConfirmBar refuses OK, Done, Confirm, Submit and Save as its label'` | The banned set, asserted through the constructor. Indelible §11 test 7 plus `06 §8.2` |
| `'ShedConfirmBar renders the outcome text verbatim'` | `Create 412` in, `Create 412` on screen — no truncation, no `FittedBox` (`type.fitted_box` bans it anyway), no ellipsis at scale 2.0 |
| `'neither component constructs a CircularProgressIndicator'` | Source text over `lib/core/ui/components/`. Covers the hole `ui.spinner`'s `lib/features/` scope leaves |
| `'neither component uses AnimatedSwitcher, AnimatedContainer or AnimatedOpacity'` | Source text. Indelible §5.2 |
| `'both components render at textScale 2.0 with boldText with no overflow'` | The epic-wide case, these two components' rows |

**Nothing here is time-shaped.** The strip renders `2h` as a **string the caller already formatted** —
`timeSincePenned` is `lib/domain/penning.dart`'s and takes `now` as a parameter (R24), and
`formatShed*` is `formatters.dart`'s (N09-T06). If this file ever needs a `Duration`, the design is
wrong.

## 6. Constraints that bind this task

- **3am** — confirm bar `tapHero` (88) full width; every recents entry ≥ `tapPrimary` (72) with
  `gapMin` (16) separation; 18 px floor; dark only. The one permitted tracked gesture is vertical
  scrolling and neither of these scrolls.
- **Fixed height from frame 1** — held by the widget's own layout, asserted across four states. This
  is the mechanism behind *"never a spinner"* (decision #71): a reserved box is what makes a loading
  indicator unnecessary rather than merely banned.
- **Every write commits immediately** — the confirm bar fires a callback and shows nothing. `07 §5.5`
  and `06 §10.3`: `tap → write → await the transaction → THEN change the UI`. A confirm bar that
  renders a success state of its own is optimistic UI and is banned outright.
- **No ARB entry** — `outcomeLabel`, `emptyLabel` and both semantic labels are parameters.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedRecentsStrip occupies the same height empty and full'` passes, and was seen to fail first for the stated reason
- [ ] identical height in every state
- [ ] the confirm bar labels the outcome, never *OK*
- [ ] six recents maximum, per spec §7.1
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the placeholder state and the empty state are distinct, and both are asserted
- [ ] no `CircularProgressIndicator` anywhere under `lib/core/ui/components/` — held by a test, since `ui.spinner` does not reach this folder
- [ ] no `Animated*` widget switches between states in either file
- [ ] the horizontal-versus-ruled arrangement conflict is recorded in the PR body, with the arithmetic

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -rn "CircularProgressIndicator\|LinearProgressIndicator" lib/core/ui/components/   # expect zero
grep -rn "Animated" lib/core/ui/components/shed_recents_strip.dart                      # expect zero
grep -n "maxEntries" lib/core/ui/components/shed_recents_strip.dart                     # expect two: the const and its use
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedConfirmBar and ShedRecentsStrip, fixed height from frame 1`
