# N18-T05 — The matrix variant and the empty-state row

| | |
|---|---|
| **Epic** | [N18 — Foster](epic.md) · `00-README` §9 step 6 (4 of 5) |
| **Task** | 5 of 5 |
| **Depends on** | N18-T04 |
| **Commit** | one commit · `test(features): the foster matrix variant and reachability assertion` |

## 1. Why this task exists

`foster` joins `kPumpableVariants`, with the extra reachability assertion `12 §6.2`
requires for this screen at the smallest device and textScaler 1.3.

The variant table is what keeps the 3am claims mechanical rather than aspirational: a screen missing
from it is a screen nothing checks for overflow, for an unreachable primary action, or for a broken
semantics tree.

Foster is one of only **three** variants that carry the reachability assertion (`12` §6.4, decision
#114) — with Quick Entry and Lambing Entry — because overflow is necessary and not sufficient: a
layout can avoid overflowing by pushing the target below the fold, and a one-tap flow whose one tap is
off-screen is a five-tap flow.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 | Foster |
| `shed-book-spec.md` | §7.3 | birth dam and rearing dam as separate fields, reassignment in two taps or fewer |
| `docs/engineering/03-data-model-and-schema.md` | §5 | `foster_events`, the trigger and the `lamb_rearing` view |
| `docs/engineering/12-testing.md` | §6.1–§6.4 | the variant list, the derived count, the failure ritual, and the reachability assertion with its vacuous-filter trap |
| `docs/engineering/12-testing.md` | §5.1–§5.3 | `Device`, `pumpApp`, the seed helpers, and the twelve-file closed list in `test/support/` |
| `docs/engineering/07-screens.md` | §1.4, §8.3 | the state vocabulary, and Foster's five states — two of which are impossible and say why |
| `docs/engineering/06-design-system.md` | §12 (`ShedEmptyState`), §12 note 2 | the empty state occupies the content's box; nothing monetization renders on a shed screen |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §4.2, §4.4 | one level-1 heading and no level-2; why clamping `textScaler` is a bug; `FittedBox` is banned around user-facing text |
| `epics/00-PLAN-CRITIQUE.md` | S3, S7 | seeds now, fixtures at N23-T05; the sweeps that iterate this table are N33's |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the variant table and the reachability assertion |
| `indelible-states-and-feedback` | the empty state |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'foster pumps at every device, text scale and bold state and its primary action stays reachable'`
- **Assertion, spelled out** — every cell asserts `tester.takeException()` is `null`; the reachability
  cell additionally pumps at `Device.small` × textScale 1.3 and asserts that
  `find.byKey(const Key('foster.target.bottle'))` and `foster.target.not_recorded` are found, that
  each `rect.bottom` is `lessThanOrEqualTo(667 - 34)` — the small viewport minus the home indicator —
  and that **neither has a `Scrollable` ancestor**. The bottom band does not scroll; the two strips
  give up rows first.
- **Why it is red today** — the screen exists and the variant table does not know about it.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the row, the empty state and the reachability assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 6 and 7 only — the empty state is UI, everything else is tests. No schema, no
domain, no data, no new provider. Say so in the commit message.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/features/lambing/foster_screen.dart` | Edit: the **Empty** state — `ShedEmptyState` in the same box the two strips occupy, one line of 18 px copy, and the keypad still live beneath it |
| 2 | `lib/l10n/app_en.arb` | `fosterEmpty` — 07 §8.3's words with the noun as a `{pluralTerm}` placeholder, plus its `description` |
| 3 | `test/support/harness.dart` | Edit: one row in `kPumpableVariants` — `RouteNames.foster: () => const FosterScreen(lambId: kSeedLamb)`, exactly as `12 §6.2` spells it |
| 4 | `test/features/overflow_matrix_test.dart` | **Extend.** The derived count moves by one; the reachability group gains its second member |
| 5 | `test/features/foster_test.dart` | **Extend.** The empty state, and the two states that are impossible on this screen |

### 5.2 The signatures

```dart
// test/support/harness.dart — the table four files iterate (12 §6.2).
// Declared ONCE. A copy is four tables that stop agreeing the first time a
// screen is added.
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.quickEntry:   () => const QuickEntryScreen(),      // N13-T07
  RouteNames.lambingEntry: () => const LambingEntryScreen(lambingId: kSeedLambing),
  RouteNames.lambCard:     () => const LambCardScreen(lambId: kSeedLamb),
  RouteNames.foster:       () => const FosterScreen(lambId: kSeedLamb),   // this task
};
```

```dart
// test/features/overflow_matrix_test.dart — the count is DERIVED, never typed.
test('the matrix covers every screen built so far, and the count is derived', () {
  const builtSoFar = <String>[
    RouteNames.quickEntry, RouteNames.lambingEntry, RouteNames.lambCard, RouteNames.foster,
  ];
  for (final r in builtSoFar) {
    expect(kPumpableVariants.keys, contains(r), reason: 'route "$r" is not in the matrix');
  }
  expect(kPumpableVariants.length, builtSoFar.length,
      reason: 'four screens exist at N18; the other nine and the export-banner '
              'variant arrive with their own epics and reach fourteen at N33 (R58)');
});

// The cells iterate the same three lists 12 §6.2 iterates, and the cell count is
// whatever those lists produce. No literal anywhere.
for (final entry in kPumpableVariants.entries) {
  for (final device in Device.all) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final bold in const [false, true]) { /* … pump, takeException, assert null */ }
    }
  }
}
```

### 5.3 The details that are easy to get wrong

1. **Do not type the cell count.** After this task the table holds four screens — `quick_entry`,
   `lambing_entry`, `lamb_card`, `foster` — and 4 × 3 devices × 3 text scales × 2 bold states is 72
   cells. **Read the map before you trust that sentence**: N13-T07 fixed the rule that the number is
   derived from the list, and 252 is what the same arithmetic yields at N33 with fourteen entries
   (R58). A remembered number is how a screen silently stops being covered.
2. **`kSeedLamb` is not a fixture yet.** `restoreFixture(db, 'flock_400_3seasons.json')` and the four
   `kSeed*` constants become fixture ids at N23-T05 (critique S3). Until then they are the ids the
   `test/support/seeds.dart` helpers deterministically produce in a fresh in-memory database, where
   `AUTOINCREMENT` starts at 1. The per-cell setup calls the seed helpers; the harness comment N13-T07
   wrote says this once, and it stays until N23 flips it.
3. **A `FosterScreen` cell must be seeded with a lamb that has somewhere to go.** With no other ewe in
   the database the deck is empty and every cell pumps the *empty* state — which then passes the
   overflow assertion without ever laying out a target. Seed at least two ewes and one penned
   occupancy, and let the empty state have its **own** cell instead.
4. **Fix the layout, never the matrix.** Deleting a cell is deleting the 3am test. Clamping
   `textScaler` is banned outright (decision #99) and defeats Android 14+'s own non-linear curve.
   Wrapping user-facing text in a `FittedBox` is banned in review — shrinking a tag number to fit is
   the opposite of legible. The two legitimate fixes are a scroll view that is **not** on the
   primary-action path, or moving something off the screen.
5. **Read the scroll position off `ScrollableState.position`, never `Scrollable.controller`.** A
   `Scrollable` built without an explicit controller has `controller == null`, so a
   `.where((s) => s.controller?.position…)` filter is empty on every screen in this app and the
   assertion passes without asserting anything. `12 §6.4` calls this trap out because *"a reachability
   assertion that cannot fail is worse than no reachability assertion."*
6. **Assert on the two no-ewe targets, not on the first deck tile.** `foster.target.bottle` and
   `foster.target.not_recorded` are present in every data state, so the assertion cannot pass
   vacuously on an empty deck — which is exactly how the Quick Entry version could have gone wrong.
7. **Three of Foster's five states are not "not implemented yet"** (07 §8.3), and the test says which
   and why: **Frame 1** is impossible — the screen is reached only from a loaded card;
   **Filtered-empty** is impossible — there is no filter, the keypad narrows rather than filters, and
   an unmatched tag becomes "Create"; **Over-cap** renders **nothing**, because this is one of the
   five shed screens. Write each as a one-line test with the reason in its `reason:`, not as a comment.
8. **The empty state uses the same control the populated screen uses** (decision #71, 06 §12): one
   line of copy and the keypad, which still creates a ewe. Not an illustration, not a spinner, not a
   tour — there is no onboarding after first run and the empty states are the teaching surface.
9. **The empty copy carries the user's plural noun.** 07 §8.3's words are *"No other animals yet."*;
   the ARB message takes `{pluralTerm}` so a shepherd who renamed her animals sees her own word, and
   the plural comes from `TermLabel`, never from appending an "s" (10 §8.5).
10. **This row also grows three sweeps that do not exist yet.** `semantics_gate_test.dart`,
    `tap_target_test.dart` and the pixel-sampling group in `contrast_test.dart` all iterate this same
    table (12 §6.2, §7.4) and land in N33 (critique S7). Adding the row here is what makes Foster
    covered by all of them the day they arrive — including the assertion that every variant has at
    least one `headingLevel > 0` node, which is why T02 gave this screen its level-1 title.
11. **Bold text is in the overflow matrix and not in the guideline sweeps.** It changes glyph weight
    and text width, not minimum-size constraints, and the matrix already catches the layout
    consequence. Do not "fix" that asymmetry here.
12. **Reproducing one failing cell is one command** — the failure message names the device, the scale
    and the bold state:
    `fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'foster · small · scale 2.0 · bold true'`.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/features/overflow_matrix_test.dart` | **anchor:** `'foster pumps at every device, text scale and bold state and its primary action stays reachable'` — the cells plus the reachability group · `'the matrix covers every screen built so far, and the count is derived'` — extended by one, with the arithmetic and never the number |
| `test/features/foster_test.dart` | `'the empty state occupies the strips box, states it in the user plural term, and the keypad still creates'` · `'frame 1 is unreachable: the screen requires a loaded lamb'` · `'there is no filtered-empty state: an unmatched tag becomes Create'` · `'nothing renders over the cap, at any hour'` · `'the screen carries exactly one heading and it is level 1'` |

Both files run through `pumpApp`, which pins the locale to `en_GB`, the brightness to dark, and a real
device padding — a zero-padding harness hides the entire class of bug where a bottom-anchored target
sits under the home indicator, which is every primary action in this app.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`test/support/` is a closed list of twelve files** (12 §5.3). This task edits `harness.dart`; it does not add a thirteenth support file, and a screen-driving helper stays private to the file that uses it.

## 7. Definition of Done

- [ ] `'foster pumps at every device, text scale and bold state and its primary action stays reachable'` passes, and was seen to fail first for the stated reason
- [ ] the reachability assertion is present
- [ ] the count stays derived
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the reachability assertion reads `ScrollableState.position` and is proved able to fail, by moving a target below the fold once and watching it go red
- [ ] the empty state renders the user's plural term and keeps the keypad live

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/foster_test.dart
fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'foster'
make check
make test
```

Then prove the new assertion can fail before you trust it: temporarily push the no-ewe targets below
the fold, watch the reachability cell go red, and revert. An assertion that has never been seen to
fail is indistinguishable from one that cannot.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the foster matrix variant and reachability assertion`
