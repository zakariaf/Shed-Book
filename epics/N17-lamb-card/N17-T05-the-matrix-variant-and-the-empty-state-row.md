# N17-T05 — The matrix variant and the empty-state row

| | |
|---|---|
| **Epic** | [N17 — Lamb Card](epic.md) · `00-README` §9 step 6 (3 of 5) |
| **Task** | 5 of 5 |
| **Depends on** | N17-T04 |
| **Commit** | one commit · `test(features): the lamb_card matrix variant and empty state` |

## 1. Why this task exists

`lamb_card` joins `kPumpableVariants`, with its empty state — a lamb with nothing recorded
but its existence, which is the common case in the first hour.

This is what survives of E14's deleted closer task. `00-PLAN-CRITIQUE.md` §4 removed *"screen
composition, ARB, semantics, the matrix variant and the tap costs"* because it bundled five commits
and turned the accessibility track into a batch; semantics, headings, keys and ARB entries land
inside T01–T04. What is left is two files and one commit — the row that keeps `kPumpableVariants`
honest, and the state the screen spends most of its life in.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1–§6.2** | the fourteen variants, the table's home in `test/support/harness.dart`, and the self-check that **derives** the count |
| `docs/engineering/12-testing.md` | §5.1, §2.2–§2.4 | `pumpApp`, `Device`, `atFixed`, and why `Clock.fixed` must not wrap an elapsed-time widget test |
| `docs/engineering/12-testing.md` | §7.4 | the four files that iterate the variant table, and the semantics and tap-target sweeps that will iterate this row from N33 |
| `docs/engineering/07-screens.md` | **§7.2** | the six states, and the three that are impossible on this screen with the reason each is impossible |
| `docs/engineering/07-screens.md` | §1.4, §2.2 | the state vocabulary, and the empty-state table — *"the empty states are the teaching surface"* |
| `docs/engineering/06-design-system.md` | §12 | `ShedEmptyState` — *"occupies the same box the populated content will"*, one line of copy, one action, **no spinner** |
| `docs/design/indelible.md` | §7.3 | the **Unset cell**: a 2 px dotted rule with a caps label above it. *"A visible gap, never a hidden field"* |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §7.3 | the Lamb Card carries one `headingLevel: 1` and no level 2, and the gate asserts a heading node on **all fourteen** variants |
| `docs/engineering/CONVENTIONS.md` | §4.1, §4.5, R58 | test-file naming, widget keys, and 252 = 14 × 3 × 3 × 2 following the variant list |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the variant table and its derived count |
| `indelible-states-and-feedback` | the empty state's box and wording |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'lamb_card pumps at every device, text scale and bold state without overflow'`
- **Why it is red today** — the screen exists and the variant table does not know about it.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the row and the empty state.

Sharpen the assertion: the matrix asserts **no `RenderFlex` overflow and no exception**. Add the
reachability assertion `12 §6.2` requires for a screen with a bottom-anchored action — at the
smallest `Device` and `textScaler` 1.3, every target the card offers is inside the thumb band and
reachable without scrolling past the fold.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 7 only. **Every other step is skipped and the commit message says so** — this
task adds no column, no domain function, no verb, no provider and no new widget. It is a `test:`
commit and its scope is two files.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/features/overflow_matrix_test.dart` | edit | The anchor, written first. It fails because `kPumpableVariants` has two entries and the assertion asks for a third |
| 2 | `test/support/harness.dart` | edit | One line: `RouteNames.lambCard: () => const LambCardScreen(lambId: kSeedLamb),`. `kSeedLamb` already exists — `12 §5.1`'s table lists it beside `kSeedEwe`, `kSeedLambing` and `kSeedSeason` |
| 3 | `test/support/seeds.dart` | edit | `seedBareLamb` — a lamb with a `lambing` and a `birth_dam` and **nothing else**: no tag, no sex, no weight, no status change, no pet-lamb flag, no foster event |
| 4 | `lib/features/lambing/lamb_card_screen.dart` | edit | The empty-history state — `ShedEmptyState` in the same box the history occupies, with `07 §7.2`'s copy |
| 5 | `lib/l10n/app_en.arb` | edit | `lambCardNothingElseRecorded` with its `description`, if T01 has not already landed it |

### 5.2 The signatures

```dart
// test/support/harness.dart — the table lives here, iterated by four test files (12 §6.2).
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.quickEntry:   () => const QuickEntryScreen(),      // N13-T07
  RouteNames.lambingEntry: () => const LambingEntryScreen(lambingId: kSeedLambing), // N16-T09
  RouteNames.lambCard:     () => const LambCardScreen(lambId: kSeedLamb),           // here
};
```

```dart
// test/features/overflow_matrix_test.dart — the count follows the map, never a literal.
test('the matrix covers every route built so far, and the count is derived', () {
  expect(kPumpableVariants.length, _routesBuiltSoFar.length,
      reason: 'a screen was added without a matrix row — R58');
});
```

### 5.3 The details that are easy to get wrong

1. **`lamb_card` is already in `12 §6.2`'s printed table, and the table in the repository has two
   entries.** The doc prints the finished fourteen-entry map; the code grows one row per screen as
   the screens land. Reading `12 §6.2` and concluding the row already exists is the fastest way to
   watch the anchor pass on its first run — and `epics/README.md` §1 is blunt about what that means:
   *"a task whose anchor test passed the first time you ran it has not been done; it has been
   described."*
2. **The count is derived, never typed.** R58: 14 × 3 devices × 3 text scales × 2 bold states = 252,
   and *"the arithmetic follows the variant list; it is not a remembered number."* Decision #114's
   216 was 12 × 18 and predates variants 13 and 14. Until N33 the assertion follows the map's own
   length; writing `expect(kPumpableVariants.length, 3)` re-introduces exactly the remembered number
   R58 exists to delete.
3. **The empty state on this screen is not a zero-row state.** T01's statement always yields the
   `'born'` arm, because `lambs.lambing` is `NOT NULL`. `07 §7.2`'s copy is *"Nothing **else**
   recorded."* — the word *else* is load-bearing, and it is the difference between a lamb that does
   not exist and a lamb nothing has happened to yet. If your empty state fires when the whole
   statement returns nothing, you have written the state for a bug.
4. **Empty and unset are two different renderings and both appear at once.** The **history** below
   the fold gets `ShedEmptyState`; each **cell** above it gets Indelible §7.3's Unset cell — a 2 px
   dotted rule 40 px long with a 14 px caps label above it, *"a visible gap, never a hidden
   field."* A bare lamb therefore shows one empty state and five visible gaps, which is the honest
   picture of a record that is thin on purpose.
5. **`ShedEmptyState` occupies the same box the content will.** `06 §12` and decision #71. A shorter
   empty state means the page reflows when the first care event lands, and reflow at 3am is a missed
   tap. It carries one line of copy and **one** action at the same `tapHero` control the populated
   screen uses — no illustration, no tour, and **never a spinner** (`ui.spinner` is a gate row).
6. **Three of the six states are impossible here and the brief says why for each.** `07 §7.2`:
   **Frame 1** — reached only from a loaded Lambing Entry, Ewe Card or pen tile, and the row is
   committed before any of those can offer the tap; **Filtered-empty** — this screen has no filter;
   **Over-cap** — nothing renders, it is a shed screen. Writing a placeholder for Frame 1 is dead
   code that will one day be reached by a route helper someone adds.
7. **Do not wrap the matrix in `withClock(Clock.fixed(...))`.** `12 §2.2`: `Clock.fixed` freezes
   `now()`, `pump(Duration)` still fires timers, and every elapsed-time readout stays at its initial
   value forever — the test silently measures 0 h and passes. Widget tests fake nothing; the
   binding already installs an advancing fake clock. Where a fixed instant is genuinely needed, offset
   the **seed data**, never pin `now`.
8. **`seedBareLamb` writes through `seeds.dart`, not `restoreFixture`.** The two committed
   fixtures — `flock_400_3seasons.json`, `flock_15_at_cap.json` — are produced by `tool/seed.dart`
   through the restore path at **N23**, five epics away. Until then the matrix seeds through
   `test/support/seeds.dart` (critique defect S3). A test that needs a fixture that does not exist
   yet is a test that will be skipped and forgotten.
9. **The heading gate iterates this row from N33.** `10 §7.3` asserts at least one `headingLevel > 0`
   node on **all fourteen** variants; `12 §7.4`'s `semantics_gate_test.dart` and
   `tap_target_test.dart` iterate the same table. So this one line quietly enrols the Lamb Card in
   three more sweeps, and `10 §3.4` is what it must satisfy: one level 1, no level 2.
   `Semantics(header: true)` is a no-op on 3.44 and is the gate row `a11y.header_bool`.
10. **The row goes in `harness.dart`, not in the test file.** `12 §6.2`: four files iterate the
    table, *"and a table copied four times is four tables that stop agreeing the first time a screen
    is added."* A local `const variants = {...}` inside `overflow_matrix_test.dart` passes today and
    silently stops covering the screen at N33.
11. **This commit is `test:` and touches `lib/` in exactly one place.** The empty state is UI, so
    `lamb_card_screen.dart` is legitimately in the diff; anything else under `lib/` means the task
    has grown. `00-README` §7.4's rule about commits that must stand alone does not apply here — this
    is one commit, and it is small on purpose.

### 5.4 The full test set

**`test/features/overflow_matrix_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'lamb_card pumps at every device, text scale and bold state without overflow'` | **the anchor.** 3 devices × 3 text scales × 2 bold states = 18 cells, asserting no `RenderFlex` overflow and no exception |
| `'the matrix covers every route built so far, and the count is derived'` | the map's own length, with a `reason:` naming R58 |
| `'every target on lamb_card is reachable at the smallest device and textScaler 1.3'` | `12 §6.2`'s reachability assertion for this screen |

**`test/features/lamb_card_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'a lamb with nothing recorded renders its header, one history row and the empty state'` | the bare lamb from `seedBareLamb`; the copy is *"Nothing else recorded."* |
| `'the empty state occupies the same box the history occupies'` | measure the history box with `seedBareLamb`, seed a care event, pump, and assert the box height is unchanged |
| `'every unrecorded cell renders a visible gap, not a hidden field'` | sex, weight, death date, cause and feed count each expose their dotted rule and caps label |
| `'the empty state carries exactly one action and no spinner'` | one `tapHero` control; no `CircularProgressIndicator` anywhere in the tree |
| `'lamb_card carries exactly one headingLevel 1 node and no headingLevel 2'` | `10 §3.4`, re-asserted here because this is the task that enrols the screen in the sweep |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`00-README` §8 steps 1–6 skipped** — the commit message says so. The only `lib/` file in this diff is `lamb_card_screen.dart`'s empty state and its one ARB string.

## 7. Definition of Done

- [ ] `'lamb_card pumps at every device, text scale and bold state without overflow'` passes, and was seen to fail first for the stated reason
- [ ] the count stays derived
- [ ] the empty state occupies the content's box
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/lamb_card_test.dart
fvm flutter test test/design
grep -rn "kPumpableVariants" test/ | grep -v "support/harness.dart"   # iterations only, no second table
grep -rn "expect(kPumpableVariants.length, [0-9]" test/               # expect: nothing
grep -rn "CircularProgressIndicator" lib/features/                    # expect: nothing
dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the lamb_card matrix variant and empty state`
