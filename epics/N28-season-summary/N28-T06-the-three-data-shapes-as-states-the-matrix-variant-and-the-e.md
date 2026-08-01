# N28-T06 — The three data shapes as states, the matrix variant and the empty season

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 6 of 6 |
| **Depends on** | N28-T05 |
| **Commit** | one commit · `test(features): the season_summary matrix variant and its three states` |

## 1. Why this task exists

No data, some data, a full season — three states, each with its own box, and
`season_summary` joining `kPumpableVariants`.

Three different layouts, and the one nobody tests is the one a shepherd meets first: February, night
one, a single lambing recorded and eleven statistics that cannot yet be computed.

That partially-computable state is the whole task. A screen that renders beautifully on the seeded
400-ewe fixture and goes blank on night one has failed at exactly the moment the shepherd decided
whether this app is worth opening again.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §12.4, §1.4 | the state table for this screen, and the house rules for each state name |
| `docs/engineering/12-testing.md` | §6.1, §6.2, §6.3, §7.4, §11.5 | the fourteen variants, the matrix code, what a failure looks like, the 84-run gates, the two-fixture rule |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/design/indelible.md` | §7.11 | `NO LAMBINGS RECORDED IN THIS SEASON` — fourteen dotted rows, not a blank page |
| `docs/engineering/06-design-system.md` | §12 | `ShedEmptyState` occupies the same box the populated content will |
| `docs/engineering/CONVENTIONS.md` | R57, R58, R59 | the test tree, 252 cells over 14 variants, the widget-key format |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the three states and the boxes they occupy |
| `shed-testing` | the variant row and its derived count |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'season_summary pumps at every device, text scale and bold state in all three data states'`
- **Why it is red today** — the screen exists and the variant table does not know about it.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Make the assertion name the cell, because a cell is what you will have to fix:
`'${entry.key} · ${device.name} · scale $scale · bold $bold — no overflow'`, and
`expect(tester.takeException(), isNull)`. The binding fails on any unhandled `FlutterError` anyway;
the explicit assertion exists so the failure message tells you the device, the scale and the bold
state, which between them locate the constraint that broke.

**Green.** The minimum code that passes, and nothing beyond it — the three states, the variant row.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1–4 | — no schema, domain, data or wiring step | Everything is built. Say so in the commit message |
| 5 | `lib/features/season/season_controller.dart` | `SeasonSummaryState` gains nothing new; the three data shapes are already expressible as `SeasonCounts` values plus `StatResult.notComputableReason`. If you are adding an `enum SeasonSummaryStatus`, stop — that is a fourth source of truth |
| 6 | `lib/features/season/season_summary_screen.dart` | The empty branch and the partially-computable branch, both occupying the same box as the loaded one |
| 7 | `lib/l10n/app_en.arb` | The empty-season line, with the season label as a placeholder |
| 8 | `test/support/harness.dart` | **One row** added to `kPumpableVariants`: `RouteNames.seasonSummary: () => const SeasonSummaryScreen(seasonId: kSeedSeason)` |
| 9 | `test/features/overflow_matrix_test.dart` | The anchor, written before all of the above |
| 10 | `test/features/season_summary_test.dart` | The three states asserted individually — the matrix proves no overflow, not that the state is right |

`test/support/seeds.dart` is **read, not extended** unless the empty and partial states genuinely
have no writer yet. See §5.3 gotcha 4.

### 5.2 The signatures

```dart
// test/support/harness.dart — the table is declared ONCE here and iterated by
// four files (12 §6.2): the overflow matrix, semantics_gate_test.dart,
// tap_target_test.dart and contrast_test.dart. A copy is four tables that stop
// agreeing the first time a screen is added.
final kPumpableVariants = <String, Widget Function()>{
  // …rows added by earlier screen epics…
  RouteNames.seasonSummary: () => const SeasonSummaryScreen(seasonId: kSeedSeason),
};
```

`kSeedSeason` is one of the fixture id constants `harness.dart` already declares alongside
`kSeedEwe`, `kSeedLambing` and `kSeedLamb`. It is a `SeasonId`, not a bare `int` (R33) — the
constructor parameter's type is what forces that, so if it compiles as an `int` the screen's
signature is wrong.

The three data shapes, and the states 07 §12.4 gives them:

| Shape | State | Rendering |
|---|---|---|
| No lambings in this season | **Empty** | *"Nothing recorded in 2026 lambing yet."* plus one action — "Quick Entry". **No empty chart is drawn**; Indelible §7.11 prints fourteen dotted rows and `NO LAMBINGS RECORDED IN THIS SEASON` |
| One lambing, most inputs missing | **Partially computable** | Every card renders; each renders **its own** `notComputableReason` in its own box. The screen is never blank because one input is missing |
| A full season | **Loaded** | `headingLevel: 1` season label, then one card per stat, then the spread, then the comparison |

Two more states, and both must be stated rather than omitted (07 §1.4: *"if a brief omits one, the
state is impossible and the brief says why"*):

| State | On this screen |
|---|---|
| **Frame 1** | One fixed-height card per stat, in the final geometry, with the definition line already painted. Never a spinner |
| **Filtered-empty** | **Impossible.** The season chip switches the season; it does not filter within one |
| **Over-cap** | **Nothing renders.** The free tier is season-primary and covers one full season, so a free-tier user reaches this screen for their own season and sees it whole. Starting a *second* season is the gated action and it is gated in Settings ▸ Season. Last year's summary is never hidden, blurred or made read-only |
| **Error** | The standard panel — one 18 px line naming what could not be read, plus "Try again" and "Diagnostics". Never the exception message |

### 5.3 The details that are easy to get wrong

1. **Do not write the count assertion here.** `12-testing.md` §6.2's self-check —
   `expect(kPumpableVariants.length, 14)` and the loop over every `RouteNames` constant — belongs to
   **N33-T01**, whose anchor is *"the matrix covers every route, and the count is 14"*. The table
   grows one row per screen epic (`00-PLAN-CRITIQUE.md` S1), so a hard `14` written now fails every
   epic between here and N33. Add the row; leave the arithmetic to the task that owns it.

2. **The matrix is not the state test.** Each of the 18 cells this row adds pumps the **fixture**
   and asserts no `RenderFlex` overflow and no exception. That proves layout, not behaviour. The
   empty and partially-computable states are asserted once each in
   `test/features/season_summary_test.dart`, not eighteen times in the matrix.

3. **Fix the layout, never the matrix.** Deleting a cell is deleting the 3am test. Clamping
   `textScaler` to make a cell pass is banned outright (decision #99) and defeats Android 14+'s own
   non-linear curve; wrapping user-facing text in a `FittedBox` is banned in review — shrinking a
   number to fit is the opposite of legible. The two legitimate fixes are a scroll view that is not
   on the primary-action path, or moving something off the screen.

4. **Do not add a third fixture.** `12-testing.md` §11.5: *"Do not add a third fixture without
   deleting one."* `flock_400_3seasons.json` is the loaded state and `flock_15_at_cap.json` is the
   monetization one; the empty and partially-computable states are built with
   `test/support/seeds.dart` writers on a fresh `testDatabase()`. A fixture per test is how a suite
   becomes unmaintainable.

5. **The matrix loads through `restoreFixture`, which goes through `RestoreService`.** That is
   deliberate (decision #74): it makes the fixture loader a continuous test of the one code path
   where a bug loses five seasons. N23-T06 made the switch; do not route around it with a bespoke
   loader because it is faster.

6. **The empty state occupies the same box the populated content will** (decision #71, 06 §12). One
   line of 18 px copy and exactly one 64 pt action, and that action is the **same control** the
   populated screen uses. No illustration, no spinner, no tour.

7. **A blank page and a zero page are different facts, and so are a blank row and a zero row.**
   Indelible §7.11: a blank line reads as missing data; a dotted line with `0` reads as *nothing
   happened*. The empty season gets the dotted rows and the sentence — not a hidden chart.

8. **`headingLevel` is asserted on all fourteen variants, including the empty one.** The 84-run
   `test/design/semantics_gate_test.dart` requires at least one node with `headingLevel > 0` on
   every variant; a season with no data still has a season label at level 1. `header: true` is a
   no-op on 3.44 and is a gate row.

9. **`boldText: true` is half the matrix and it changes glyph width, not constraints.** The
   right-aligned figure column survives it because the numerals are tabular; if a bold cell
   overflows and the plain one does not, the column is not tabular yet and that is the fix.

10. **Nothing monetization-related renders here at any entitlement state.** `ShedBanner` renders in
    exactly two places, the Flock screen and Settings, and never between 22:00 and 06:00. Season
    Summary is not one of the five shed screens, so it is not covered by
    `test/features/no_monetization_test.dart` — assert it in this screen's own test file instead of
    assuming.

11. **Widget keys added here are contracts.** `season_summary.empty` and
    `season_summary.stat.<name>.not_computable` will be found by N33's gates; renaming one later is
    a breaking change to `test/features/`.

### 5.4 The full test set

**`test/features/overflow_matrix_test.dart`** — the anchor. One row in `kPumpableVariants` buys
**18 cells**: 3 devices × 3 text scales (1.0, 1.3, 2.0) × 2 bold states, each asserting
`tester.takeException()` is null after `pumpApp`.

**`test/features/season_summary_test.dart`** — the states, one assertion each:

| Case | Asserts |
|---|---|
| `'an empty season renders one line, one action and no chart'` | `ShedEmptyState` present; the spread chart absent; no `CircularProgressIndicator` |
| `'the empty state occupies the same box the loaded state will'` | measure the content column in both; the width does not move |
| `'one lambing renders every card, each with its own not-computable reason'` | the partially-computable state; the screen is not blank |
| `'a not-computable card renders words and never a zero'` | no `0` as a rendered value |
| `'frame 1 paints the cards in their final geometry with the definitions already visible'` | pump one frame before the database resolves |
| `'switching the season chip switches the season and never filters within one'` | filtered-empty is impossible |
| `'nothing monetization-related renders at unlocked false with 99 ewes in the season'` | decision #90's posture, on a calm screen |
| `'last season stays whole for a free-tier user'` | not hidden, blurred or read-only |
| `'a read failure renders the standard error panel and never the exception message'` | decision #13, decision #124 |
| `'the screen carries one headingLevel 1 node in every one of the three states'` | including the empty one |

**`test/design/`** — no new file. Adding the `kPumpableVariants` row automatically extends
`semantics_gate_test.dart` and `tap_target_test.dart` by **6 runs each** (3 devices × textScaler 1.0
and 2.0), and `contrast_test.dart` by **3 runs** (three palettes at `Device.small`). Run all three
and read the failures; they are the ones that catch a 44 px chart row that acquired a tap action.

**Time-shaped case — tag it `uk-zone`.** Pump the season variant under `TZ=Europe/London` against a
seed containing a lambing at 01:30 on 25 October 2026, and assert the spread renders the same number
of day rows as it does under the default zone. The matrix itself is not tagged, so without this case
the whole variant never runs in the DST job.

## 6. Constraints that bind this task

- **The matrix cannot silently stop covering a screen.** One row, in `harness.dart`, declared once and iterated by four files.
- **252 cells over 14 variants** (R58) — the arithmetic follows the variant list and is derived, once, in **N33-T01**. Do not remember a number here.
- **Every state occupies the same box**, and there is no spinner anywhere under `lib/features/` (`ui.spinner`).
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'season_summary pumps at every device, text scale and bold state in all three data states'` passes, and was seen to fail first for the stated reason
- [ ] all three states occupy the same box
- [ ] the empty season explains itself
- [ ] the count stays derived
- [ ] exactly one row is added to `kPumpableVariants`, in `harness.dart`, and no count literal is written here
- [ ] no third fixture was added; the empty and partial states use `test/support/seeds.dart`
- [ ] the empty state renders one line, one 64 pt action and no chart — and no spinner
- [ ] every one of the three states carries at least one `headingLevel > 0` node
- [ ] nothing monetization-related renders on this screen at any entitlement state or hour
- [ ] `test/design/semantics_gate_test.dart`, `test/design/tap_target_test.dart` and `test/design/contrast_test.dart` are green with the new variant
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/season_summary_test.dart
fvm flutter test test/design/semantics_gate_test.dart
fvm flutter test test/design/tap_target_test.dart
fvm flutter test test/design/contrast_test.dart --tags slow
TZ=Europe/London fvm flutter test --tags uk-zone
git diff --stat -- test/fixtures/
fvm dart run tool/check_policy.dart
python3 tool/validate_epics.py
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the season_summary matrix variant and its three states`
