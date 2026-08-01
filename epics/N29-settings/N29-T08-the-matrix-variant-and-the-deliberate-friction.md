# N29-T08 — The matrix variant and the deliberate friction

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 8 of 8 |
| **Depends on** | N29-T07 |
| **Commit** | one commit · `test(features): the settings matrix variant and its friction assertions` |

## 1. Why this task exists

`settings` joins `kPumpableVariants`, and the friction is asserted: nothing on this screen
is a one-tap destructive action, and nothing on it is reachable from a shed screen in fewer taps than
the shed screen's own primary action.

This is the **thirteenth and last route variant**. N13-T07 opened the table with one entry and a
per-epic ledger; N16, N17, N18, N19, N20, N21, N25, N26, N27 and N28 each wrote a row. With `settings`
added, `kPumpableVariants.keys` is a superset of every `RouteNames` value for the first time — and the
membership assertion N13-T07 wrote (*"the keys are the routes whose screens exist today"*) becomes
*"every `RouteNames` value"*, which is a strictly stronger claim and the one the matrix was designed to
reach.

13 × 3 × 3 × 2 = **234 cells**. Not 252: the fourteenth variant is `quick_entry.export_banner`, a Quick
Entry **layout state** rather than a screen, and it is **N33-T01**'s. Do not write
`expect(kPumpableVariants.length, 14)` here — that is `12 §6.2`'s eventual assertion and it belongs in
the epic that makes it true.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1** (the fourteen variants and the 14 × 3 × 3 × 2 arithmetic) · **§6.2** (`kPumpableVariants` and the matrix, both printed; the table lives in `harness.dart` because **four** files iterate it) · **§6.3** (what a failure looks like; *"fix the layout, never the matrix"*; `FittedBox` banned; clamping banned) · §6.4 (reachability and the `ScrollableState.position` trap) · §5.1 (`Device`, `pumpApp` and its non-zero default padding) · §5.2 (`restoreFixture`) · §7.4 + §7.6 (the other three iterators) | the table, the arithmetic and the failure protocol |
| `docs/engineering/CONVENTIONS.md` | **R58** (252 cells over 14 pumpable variants; *"the arithmetic must follow the variant list, not a remembered number"*) · **R57** (the test tree; `test/screens/` and `test/integration/` are banned) · §4.1 (test file naming; a policy test states the **property**) · §4.5 + R59 (the keys the friction assertions read) | **BINDING** on the count, the file and the folder |
| `docs/engineering/07-screens.md` | **§14.4** (the tap costs: ≤ 2 for every non-destructive setting, **4** for each destructive one) · §21.2 (the matrix and the reachability assertions) · §19.2 (**the five shed screens render nothing monetization-related**) · §20 (the five cross-screen layout rules) · §16.4 (the banner variant — **not** this task's) | which assertion belongs to which variant |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (`headingLevel`; Settings is *"one per settings group"*) · §4.2 (**why clamping is a bug**) · §4.4 (`FittedBox` is banned around user-facing text) · §4.6 (bold text, and the bug that makes heavy text lighter) · §7.3 (the automated half; *"at least one `headingLevel > 0` node on **all fourteen** variants"*) | the axes and the heading assertion |
| `docs/design/indelible.md` | §4.5 (reach zones; *"nothing above 560 px from the bottom is ever required to complete an event"*) · §3.6 (at 200% text scale) · §9 (the 3am compliance table) | what the cells are defending |
| `docs/engineering/06-design-system.md` | §6.3 (the geometric gate at 320 × 568) · §9.3 (`tapMin` 60, `gapDestructive` 32) · §12 (the component inventory) | the geometry the cells exercise |
| `docs/research/00-tech-decisions.md` | **#114** (the overflow matrix — 216, superseded by R58) · **#99** (never clamp text scale) · #111 (`NativeDatabase.memory()`, never a mock) · #121 (randomised ordering) · #22 (the double-tap defence) · #90 (nothing on the shed path branches on `unlocked`) | the decisions the matrix applies |
| `epics/00-PLAN-CRITIQUE.md` | **S3** (the matrix is created early, its fixture arrives in N23) · **S1** (the harness grows per epic) · **S7** (a sweep over a not-yet-complete list passes silently forever) | why the sweeps are not here |
| `epics/N13-quick-entry-the-deck-and-the-keypad/N13-T07-…md` | §5.2 (the ledger comment this task's row completes) · §5.3 (*"do not write `expect(kPumpableVariants.length, 14)`"*) | the table this task closes |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the variant row and the friction assertions |
| `indelible-page-and-screens` | the page's rhythm and its target separation |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'settings pumps at every device, text scale and bold state and no destructive action is one tap'`
- **Why it is red today** — the screen exists and the variant table does not know about it.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen it so it cannot pass by remembering a number, and so it records what became true here:

1. **Membership, derived.** `kPumpableVariants.keys` now contains **every** `RouteNames` value.
   Iterate the constants; do not type a list. This is the assertion that changes shape in this commit —
   from *"the routes whose screens exist today"* to *"every route"* — and the `reason:` says so.
2. **The count, computed from the same lists the loops iterate.**
   `kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length` — today
   `13 × 3 × 3 × 2 = 234`, with the `reason:` naming **N33-T01** as where it becomes 252 over fourteen
   variants (R58). Do **not** write `expect(kPumpableVariants.length, 14)`.
3. **The friction, as two properties rather than a tap count.** *No destructive action is one tap*: walk
   the Settings subtree, find every control whose key is under `settings.data.`, and assert each one
   opens a confirmation rather than performing a write — `FakeShareService`, the season repository and
   `RestoreService` all record zero calls after a single tap on each. And *nothing on this screen is
   reachable from a shed screen in fewer taps than that shed screen's own primary action*: from Quick
   Entry, the primary action is **one** tap (the confirm bar), so Settings must cost **at least two**.

**Green.** The minimum code that passes, and nothing beyond it — the row and the friction assertions.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 8 (tests) only. Nothing under `lib/` changes.** If a file under `lib/` appears in this diff, a
screen was edited to make a cell pass, which is `12 §6.3`'s *"fix the layout, never the matrix"* read
backwards. **Say so in the commit message** — and if a layout genuinely must change, that is a separate
commit on one of T01–T07's files, not a smuggled hunk in a test commit.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Edit.** One row: `RouteNames.settings: () => const SettingsScreen()`. **Cross `settings` off the per-epic ledger** N13-T07 wrote, and update the comment to record that the thirteen routes are now complete and only `quick_entry.export_banner` (N33-T01) remains |
| 2 | `test/features/overflow_matrix_test.dart` | **Edit.** The membership assertion changes shape (every `RouteNames` value); the derived count becomes 234; the `reason:` strings name N33-T01 |
| 3 | `test/features/settings_test.dart` | **Edit.** The friction assertions, the heading assertion and the tap-cost cases — they belong beside the screen's other widget tests, not inside the matrix file |
| 4 | `test/features/tap_budget_test.dart` | **Edit.** One case: Settings is **not** on a shed screen's tap budget and must not shorten one. `00-README` §8 step 7 item 26 |

`restoreFixture(db, 'flock_400_3seasons.json')` **is** available here — N23-T05 landed the two committed
fixtures and switched the matrix to them. Use it: a Settings screen seeded from an empty database
renders shorter section bodies, and a matrix cell that pumps the small layout proves the small layout.

### 5.2 The signatures

```dart
// test/support/harness.dart — the thirteenth and last ROUTE variant.
//
// LEDGER — complete for routes as of N29. RouteNames declares thirteen and all
// thirteen are now here. What remains is ONE non-route variant:
//
//   quick_entry.export_banner            N33-T01   <- the only row outstanding
//
// 12 §6.1 variant 14 is a Quick Entry LAYOUT STATE (07 §16.4), not a screen.
// It is the state in which the reachability assertion is most likely to fail,
// which is why it is its own variant and why it lands with the final sweep.
final kPumpableVariants = <String, Widget Function()>{
  … the twelve rows N13..N28 added …
  RouteNames.settings: () => const SettingsScreen(),
};
```

```dart
// test/features/overflow_matrix_test.dart — the self-check, in the shape this
// commit gives it. R58: the arithmetic follows the variant list.
test('the matrix covers every route, and the count is derived', () {
  for (final r in kRouteNamesValues) {
    expect(kPumpableVariants.keys, contains(r),
        reason: 'route "$r" is not in the matrix');
  }
  expect(kPumpableVariants.length, kRouteNamesValues.length,
      reason: 'N29-T08: all thirteen ROUTES are covered. The fourteenth '
              'variant — quick_entry.export_banner — is N33-T01, and it is a '
              'Quick Entry layout state, not a screen (12 §6.1, 07 §16.4).');

  final cells = kPumpableVariants.length *
      Device.all.length * kTextScales.length * kBoldStates.length;
  expect(cells, 234,
      reason: '13 x 3 x 3 x 2. It becomes 252 at N33-T01 (R58); the number is '
              'computed from the same lists the loops iterate, never typed.');
});
```

### 5.3 The details that are easy to get wrong

- **Do not write `expect(kPumpableVariants.length, 14)`.** `12 §6.2` prints that line because it
  describes the **finished** matrix. Writing it here makes the suite red for four epics, and the
  natural "fix" is to delete the self-check — which is exactly how a matrix silently stops covering a
  screen. N13-T07 says the same thing from the other end.
- **The count is arithmetic over the same lists the loops use.** `kTextScales` and `kBoldStates` were
  declared beside the table in N13-T07 for exactly this reason. A self-check that hard-codes `3` and
  `2` while the loops iterate literals passes while silently changing the matrix — the failure mode
  R58 was written to prevent.
- **The membership assertion changes shape in this commit, and that is the deliverable.** Up to now it
  read *"the keys are the routes whose screens exist today"* — a claim that gets weaker as the project
  grows. From here it reads *"every `RouteNames` value"*, which is what the matrix was for. Say so in
  the `reason:`; a stronger assertion that arrives without explanation is a stronger assertion somebody
  weakens again.
- **Fix the layout, never the matrix** (`12 §6.3`), in order: read the cell name; reproduce the one
  cell with `--plain-name`; fix the layout. **Deleting a cell is deleting the 3am test.** Clamping
  `textScaler` is banned outright (decision #99) and defeats Android 14+'s own non-linear curve
  (`10 §4.2`). Wrapping user-facing text in a `FittedBox` is banned in review — *"shrinking a tag number
  to fit is the opposite of legible."* The two legitimate fixes are: a scroll view that is **not** on
  the primary-action path, or moving something off the screen.
- **Settings is the screen most likely to fail a cell, and the fix is a scroll view.** Eleven sections,
  seven terminology pairs, the diagnostics rows and the About prose is the longest content in the app.
  A scroll view is correct here precisely because **no primary action lives on this screen** — nothing
  on it is on the 3am path, so `12 §6.4`'s reachability constraint does not bind it. Say that in a
  comment beside the cells, or the next reader will add a reachability assertion that cannot fail.
- **Bold text is an axis for a reason, and it is the axis that catches this screen.** `10 §4.6` records
  the bug that makes heavy text **lighter**: a family that already ships a bold weight can render
  thinner under the platform's bold-text flag if the weight is bumped past the face's range. Settings
  is full of `titleMedium` headings and `labelLarge` word buttons, and the `w700` cap (`06 §3`) is what
  holds it. A cell that fails at `bold true` and passes at `bold false` is that bug.
- **Seed the populated layout, not the empty one** (critique S10, N13-T07's own gotcha). Use
  `restoreFixture(db, 'flock_400_3seasons.json')`: the pen list has pens to rename, the season section
  has seasons to switch between, the Diagnostics counts are non-zero, and the delete confirmations have
  real numbers. An empty Settings screen has shorter rows and cannot overflow, so 36 green cells would
  prove nothing.
- **Every cell builds its own database.** The `test` job runs `--test-randomize-ordering-seed random`
  (decision #121) *because* order-dependent state otherwise shows up as a flake at 11 pm on release
  day. `testDatabase()` registers its own teardown (N12-T05); do not hoist one database into a
  `setUpAll`.
- **`flutter test` runs on the host, so the host must supply sqlite3** (`12 §3.2`, `13 §4.3`). CI
  installs `libsqlite3-dev`; a developer whose 36 cells all fail to open a database should install it
  locally rather than mock the database (decision #111).
- **This task is not the semantics, tap-target, contrast or reachability sweep.** All four iterate
  `kPumpableVariants` (`12 §7.4`, §7.6) and they are **N33-T02 / T03 / T04**. Writing one here repeats
  critique defect **S7** — a gate that iterates a list which is *nearly* complete and passes, silently,
  forever. The matrix file already carries a comment naming the other three iterators (N13-T07); check
  it is still accurate now that the route list is closed.
- **The friction assertions are properties, not tap counts, wherever possible.** *"No destructive action
  is one tap"* is better expressed as *"a single tap on any `settings.data.*` control performs no
  write"* than as *"the delete costs four taps"* — the first survives a redesign of the confirmation
  and the second does not. `07 §14.4`'s four is the budget; the property is the guarantee.
- **The five shed screens render nothing monetization-related, and Settings is not one of them**
  (`07 §19.2`, decision #90). The assertion that belongs here is the reverse: nothing on **Settings**
  reaches `entitlementProvider` or `purchaseServiceProvider` **yet**, because neither exists. N30-T08
  writes the at-cap tests; this task asserts the absence.
- **Every section heading is a real heading level** (`10 §3.4`, §7.3). The automated half asserts *"at
  least one `headingLevel > 0` node"* on all fourteen variants; Settings has eleven level-2 nodes and
  one level-1. `header: true` is a no-op on 3.44 and `a11y.header_bool` fails the build on it.
- **`test/screens/` and `test/integration/` are banned directories** (R57). The widget tier mirrors
  `lib/features/`, so the files are `test/features/overflow_matrix_test.dart` and
  `test/features/settings_test.dart`.
- **2.6.1 spellings only.** `ProviderContainer.test()` and `WidgetTester.container` are Riverpod 3
  (decision #18) and do not exist here; `shedContainer(db, overrides: …)` plus
  `addTearDown(container.dispose)` is the shape, and the harness already registers the teardown.
- **`pumpApp`'s default padding is not zero and must not be overridden here.**
  `EdgeInsets.only(top: 47, bottom: 34)` — *"real phones have a notch and a home indicator"*
  (`12 §5.1`). A zero-padding harness hides the class of bug where a bottom-anchored 60 pt target sits
  under the home bar.

### 5.4 The full test set

Three files.

`test/features/overflow_matrix_test.dart` (edited):

| Case | What it asserts |
|---|---|
| `'settings pumps at every device, text scale and bold state and no destructive action is one tap'` | **The anchor.** The 36 Settings cells plus the friction property |
| `'the matrix covers every route, and the count is derived'` | Membership over every `RouteNames` value; `cells == 234`, computed; the `reason:` names N33-T01 |
| `'settings · small · scale 1.0 · bold false — no overflow'` … (36 generated cells) | `Device.all` × `kTextScales` × `kBoldStates`; `takeException()` is null in every one |
| `'the harness ledger records that all thirteen routes are covered'` | Source-text case over `harness.dart`. The comment **is** the artefact for critique S3, and a comment nothing reads is a comment somebody deletes |
| `'the matrix file still names the other three iterators of kPumpableVariants'` | The S7 guard, re-checked now that the route list is closed |
| `'expect(kPumpableVariants.length, 14) does not appear'` | Source text. It is N33-T01's line, not this one's |

`test/features/settings_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'a single tap on any settings.data control performs no write'` | Walk every `settings.data.*` key; tap each once; `FakeShareService.shared` is empty, `seasons` and the database file are untouched, no `RestoreService` call recorded |
| `'no destructive control is within gapDestructive of a frequent action'` | `tester.getRect` over the Data section against `context.tokens.gapDestructive` |
| `'every settings section heading is headingLevel 2 and the title is headingLevel 1'` | Eleven level-2 nodes, one level-1, zero `header: true` |
| `'every interactive element on the screen is at least 60 x 60'` | Against `context.tokens.tapMin`; Indelible builds 64 and 60 is the floor |
| `'Settings costs at least two taps from Quick Entry'` | Quick Entry's own primary action is one tap; the friction rule is that Settings is never cheaper |
| `'Settings is on no shed screen's tap budget'` | `test/features/tap_budget_test.dart`'s companion case: the 6-tap lambing, the 1-tap foster and the 2-tap repeat treatment are unchanged by this epic |
| `'nothing on Settings watches the entitlement or the store seam'` | Source text plus `FakePurchaseService.calls` being empty — and the fake is not even wired, which is the point |
| `'the section count is eleven and the ledger names N30-T05'` | The self-check T01 wrote, re-asserted after seven tasks of edits |
| `'settings renders every section at textScaler 2.0 with bold on, and scrolls rather than shrinking'` | No `FittedBox`, no clamped `textScaler`; the scroll view exists and is not on a primary-action path |
| `'settings renders correctly inside the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 on 25 October 2026**. The Season section renders a start date and the Diagnostics section renders log timestamps, so this screen's *content* — and therefore its width — depends on the clock; the repeated hour is where a naive implementation renders two dates and overflows the row |

`test/features/tap_budget_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'no route added in N29 shortens a shed screen's tap budget'` | The three budgets re-asserted after Settings joins the route table |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **This task authors no string and no widget**, so the ARB row binds it **negatively**: a string in
  this diff means a screen was edited to make a cell pass.
- **The 3am test is what the matrix mechanises** (`12 §6.1`): *"a set of prose claims — legible at
  18 pt, 60 pt targets, one thumb, no scrolling to reach the primary action. The matrix is what makes
  them mechanical."* Every deleted cell is a deleted claim.
- **Coverage is reported, never gated** (decision #119). Thirty-six widget cells will move the number;
  that is not the point of them.

## 7. Definition of Done

- [ ] `'settings pumps at every device, text scale and bold state and no destructive action is one tap'` passes, and was seen to fail first for the stated reason
- [ ] no destructive action is one tap
- [ ] the count stays derived
- [ ] every section heading is a real heading level
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **no file under `lib/` appears in the diff**, and the commit message says so
- [ ] `kPumpableVariants` contains every `RouteNames` value; the membership assertion is derived and its `reason:` records that the route list is now closed
- [ ] the cell count is `kPumpableVariants.length × Device.all.length × kTextScales.length × kBoldStates.length` = **234**, computed, with the `reason:` naming N33-T01 and the 252
- [ ] `expect(kPumpableVariants.length, 14)` appears nowhere
- [ ] the harness ledger's last outstanding row is `quick_entry.export_banner` (N33-T01)
- [ ] the cells seed through `restoreFixture(db, 'flock_400_3seasons.json')`, not through an empty database
- [ ] no semantics, tap-target, contrast or reachability **sweep** is written here (critique S7)
- [ ] the `uk-zone` case exists and fails when the `TZ=Europe/London` leg is removed
- [ ] `test/screens/` and `test/integration/` do not exist (R57)

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/settings_test.dart
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/features/                 # the whole widget tier, after this epic
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

# Reproduce one cell the way 12 §6.3 says to.
fvm flutter test test/features/overflow_matrix_test.dart \
  --plain-name 'settings · small · scale 2.0 · bold true'

# Randomised ordering, twice, with different seeds — cell independence.
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 1
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 2
```

```bash
git diff --stat -- lib/                                    # expect empty
grep -n "RouteNames.settings" test/support/harness.dart    # the thirteenth row
grep -rn "expect(kPumpableVariants.length, 14)" test/      # expect zero
grep -n "quick_entry.export_banner" test/support/harness.dart   # the ledger's last row
grep -n "N33-T01" test/support/harness.dart test/features/overflow_matrix_test.dart
grep -rn "FittedBox\|textScaler.clamp\|TextScaler.linear" lib/features/settings/  # expect zero
grep -rn "Scrollable.controller" test/                     # expect zero (12 §6.4)
ls test/screens test/integration 2>/dev/null               # must not exist (R57)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the settings matrix variant and its friction assertions`
