# N13-T07 — `kPumpableVariants` is born, with one entry

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 7 of 7 |
| **Depends on** | N13-T06 |
| **Commit** | one commit · `test(features): the overflow matrix, born with one variant` |

## 1. Why this task exists

The overflow matrix's table is created here with **one** row — `quick_entry` — and its
count is **derived from the variant list, never typed**. It grows one row per screen epic and reaches
fourteen in N33. Matrix cells use `test/support/seeds.dart` until the fixtures exist in N23; that switch
is **N23-T05** and is stated once, here, in the harness comment. Critique defect S3.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1** (the fourteen variants and the 14 × 3 × 3 × 2 arithmetic) · **§6.2** (`kPumpableVariants` and the matrix, both printed; the table lives in `harness.dart` because **four** files iterate it) · **§6.3** (what a failure looks like; *"fix the layout, never the matrix"*) · **§6.4** (reachability, and the `ScrollableState.position` trap) · §5.1 (`Device`, `pumpApp`) · §5.2 (the two seeding routes) · §3.2 (the host `sqlite3` floor) | the table, the arithmetic and the failure protocol |
| `docs/engineering/CONVENTIONS.md` | **R58** (252 cells over 14 pumpable variants; *"the arithmetic must follow the variant list, not a remembered number"*) · **R57** (the test tree; `test/screens/` is banned) · §4.1 (test file naming) | **BINDING** on the count, the file and the folder |
| `docs/engineering/07-screens.md` | §21.2 (the matrix and the reachability assertions) · §16 (the export banner — variant 14, and **not** this task's) · §5.1 (*"Reachability at 375 × 667 × textScaler 1.3, with the banner shown"*) | which assertion belongs to which variant |
| `docs/engineering/02-state-di-navigation.md` | §5.4 (overriding in tests — leaves, never controllers) · §2.1–§2.3 (the Riverpod-3 ban list: no `ProviderContainer.test`, no `WidgetTester.container`) | the 2.6.1 spellings the harness must keep |
| `docs/engineering/13-build-ci-release.md` | §4.2 + §4.3 (`test` runs `-P ci-fast` with `--test-randomize-ordering-seed random`, and installs `libsqlite3-dev` on the host) | why every cell must be independent |
| `docs/research/00-tech-decisions.md` | #114 (the overflow matrix, superseded by R58 on the count) · #99 (never clamp text scale) · #111 (`NativeDatabase.memory()`, never a mock) · #121 (randomised ordering) | the decisions the matrix applies |
| `epics/00-PLAN-CRITIQUE.md` | **S3** (the matrix is created in E10, its fixture arrives in E19) · **S1** (the harness grows per epic) · §5 rule 5 | why the table is born with one row and seeded from `seeds.dart` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the matrix, the variant table and the derived-count rule are its subject |
| `shed-screens-and-routing` | a route and a pumpable variant are the same list seen twice |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'the matrix count equals kPumpableVariants.length times the device, scale and bold axes'`
- **Why it is red today** — `kPumpableVariants` does not exist, and the old plan seeded the matrix from a fixture written nine epics later.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by remembering a number. Assert three things:

1. `kPumpableVariants.keys` is exactly the set of `RouteNames` values **whose screen exists today** —
   today, `{RouteNames.quickEntry}`. Deriving the membership from the built screens rather than from a
   literal is what makes the table impossible to silently stop covering a screen someone added.
2. The number of generated `testWidgets` cells equals
   `kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length` —
   computed from the same lists the loops iterate, so the two can never disagree.
3. Today that product is **1 × 3 × 3 × 2 = 18**, and the `reason:` string says so *and* names N33-T01
   as the task where it becomes 252 over fourteen variants. Do **not** write
   `expect(kPumpableVariants.length, 14)` — that is `12 §6.2`'s eventual assertion and it belongs in
   the epic that makes it true.

**Green.** The minimum code that passes, and nothing beyond it — the table with one entry, the derived arithmetic, and the harness comment naming N23-T06 as
the fixture switch.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

> **Correction to carry into the code comment.** The line above says *N23-T06*. The task that lands the
> two committed fixtures and switches the matrix to `restoreFixture` is **N23-T05 — "the two committed
> fixtures and the matrix switch"**; N23-T06 is `restoreInto` and `freshSupportDir` in the harness.
> Write **N23-T05** in the harness comment, and note the correction in the commit message.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) only.** Nothing under `lib/` changes. This is the second task in the project whose
whole diff is test-tier — say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Edit.** Add `kPumpableVariants` with **one** entry, `kTextScales`, `kBoldStates`, and the ledger comment naming (a) which epic adds which variant and (b) the seeds-now / fixtures-at-**N23-T05** rule. The table lives here, not in the matrix file, because **four** files iterate it (`12 §6.2`) and *"a table copied four times is four tables that stop agreeing the first time a screen is added"* |
| 2 | `test/features/overflow_matrix_test.dart` | **New.** The self-check, the generated cells, and the Quick Entry reachability assertion in its without-the-banner form |
| 3 | `test/support/seeds.dart` | **Edit, if needed.** A `seedQuickEntryDeck(db)` convenience that fills both buckets to six, so every cell renders the *populated* layout rather than the empty one — the empty layout is smaller and cannot overflow, so a matrix seeded with nothing is a matrix that proves nothing |

`restoreFixture` and `armExportBanner` are **not** referenced. The first arrives with the fixtures at
N23-T05; the second needs `app_settings`' four export columns and is N21-T08's.

### 5.2 The signatures

`12 §6.2` prints the eventual table. What lands today is the same shape with one row and a ledger:

```dart
// test/support/harness.dart — iterated by four test files (12 §6.2, §7.4, §7.6)
//
// ONE entry today. It grows one row per screen epic and reaches FOURTEEN at
// N33-T01 — the thirteen RouteNames screens plus the export-banner variant
// (CONVENTIONS R58; decision #114's "216" was 12 x 18 and is superseded).
//
//   flock, ewe_card, note_search        N26
//   lambing_entry                       N16
//   lamb_card                           N17
//   foster                              N18
//   pen_board                           N19
//   treatments                          N20
//   reminders                           N25
//   season_summary                      N28
//   export                              N21
//   settings                            N29
//   quick_entry.export_banner           N21-T08
//
// SEEDS NOW, FIXTURES AT N23. Cells seed through test/support/seeds.dart. The
// switch to `restoreFixture(db, 'flock_400_3seasons.json')` is N23-T05 — the
// task that writes the two committed fixtures through the restore path and is
// therefore the task that proves the fixture is loadable. Stated once, here,
// so it is not rediscovered per screen. Critique defect S3.
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.quickEntry: () => const QuickEntryScreen(),
};

/// The three axes, declared beside the table so the matrix's arithmetic and its
/// loops read the SAME lists. R58: the count follows the variant list.
const kTextScales = <double>[1.0, 1.3, 2.0];
const kBoldStates = <bool>[false, true];
```

The matrix itself, following `12 §6.2`'s printed shape:

```dart
// test/features/overflow_matrix_test.dart
import '../support/harness.dart';

void main() {
  // The only place the cell count is derived rather than remembered.
  test('the matrix count equals kPumpableVariants.length times the device, '
      'scale and bold axes', () { … });

  for (final entry in kPumpableVariants.entries) {
    for (final device in Device.all) {
      for (final scale in kTextScales) {
        for (final bold in kBoldStates) {
          testWidgets(
            '${entry.key} · ${device.name} · scale $scale · bold $bold — no overflow',
            (tester) async {
              final db = await testDatabase();
              await seedQuickEntryDeck(db);
              await tester.pumpApp(entry.value(),
                  db: db, device: device, textScale: scale, boldText: bold);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
```

The reachability assertion, in the form that is honest today (`12 §6.4`, `07 §5.1`):

```dart
  testWidgets('Quick Entry: the confirm key is on screen without scrolling', (tester) async {
    final db = await testDatabase();
    await seedQuickEntryDeck(db);
    await tester.pumpApp(const QuickEntryScreen(),
        db: db, device: Device.small, textScale: 1.3);

    final confirm = find.byKey(const Key('quick_entry.confirm'));
    expect(confirm, findsOneWidget);

    final rect = tester.getRect(confirm);
    expect(rect.bottom, lessThanOrEqualTo(667 - 34),
        reason: 'hidden behind the home indicator');

    // Read the POSITION off ScrollableState, never `Scrollable.controller`.
    // A Scrollable built without an explicit controller has `controller == null`,
    // so a `.where((s) => s.controller?.position…)` filter is empty on every
    // screen in this app and the assertion passes without asserting anything.
    // ScrollableState.position is always live once the widget has laid out.
    …
  });
```

### 5.3 The details that are easy to get wrong

- **Do not write `expect(kPumpableVariants.length, 14)`.** `12 §6.2` prints that line because it is
  describing the finished matrix. Writing it today makes the suite red for twenty epics, and the
  natural "fix" is to delete the self-check — which is exactly how a matrix silently stops covering a
  screen. The assertion that belongs here is the **membership** one: the keys are the routes whose
  screens exist. N33-T01 replaces it with the 14 and the `reason: '13 routes + the export-banner
  variant (R58)'`.
- **The count is arithmetic over the same lists the loops use.** `kTextScales` and `kBoldStates` are
  declared beside the table for exactly this reason. If the self-check hard-codes `3` and `2` while the
  loops iterate literals, adding a fourth text scale passes the self-check and silently changes the
  matrix — the failure mode R58 was written to prevent.
- **The fixture switch is N23-T05, not N23-T06.** The critique's S3 text and this task's §1 both say
  N23-T06; the N23 folder's actual tasks are `N23-T05 — the two committed fixtures and the matrix
  switch` and `N23-T06 — restoreInto and freshSupportDir in the harness`. Write **N23-T05** in the
  comment. A cross-reference that names the wrong task is worse than none, because it is followed.
- **Seed the *populated* layout, not the empty one.** An empty Quick Entry has two placeholder boxes and
  no rows: it cannot overflow, so eighteen green cells would prove nothing. Fill both deck buckets to
  six and seed enough active ewes that the match list has content. `12 §5.2`'s two seeding routes exist
  precisely so a test can choose: helpers for "a shape", fixtures for "shape at volume".
- **Every cell builds its own database.** The `test` job runs
  `--test-randomize-ordering-seed random` (decision #121, `13 §4.3`) *because* order-dependent state
  otherwise shows up as a flake at 11pm on release day. `testDatabase()` registers its own teardown
  (N12-T05); do not hoist one database into a `setUpAll`.
- **`flutter test` runs on the host, so the host must supply sqlite3.** `12 §3.2` and `13 §4.3`:
  `sqlite3_flutter_libs` is a plugin — and an EOL no-op shim anyway — so it is never applied in a host
  test. CI installs `libsqlite3-dev`; a developer whose eighteen cells all fail to open a database
  should install it locally rather than mock the database (decision #111: `NativeDatabase.memory()`,
  never a mock).
- **`tester.takeException()` is the assertion, and the binding already fails on the error.**
  `RenderFlex` overflow is reported through `FlutterError.onError` during layout, which the test
  binding captures. No package is needed and none is used. The explicit assertion exists so the failure
  message names the **cell** — which is what tells you the device, the scale and the bold state, and
  between them the constraint that broke.
- **Fix the layout, never the matrix.** `12 §6.3`, in order: read the cell name; reproduce the one cell
  with `--plain-name`; fix the layout. **Deleting a cell is deleting the 3am test.** Clamping
  `textScaler` to make it pass is banned outright (decision #99) and defeats Android 14+'s own
  non-linear curve. Wrapping user-facing text in a `FittedBox` is banned in review — *"shrinking a tag
  number to fit is the opposite of legible."* The two legitimate fixes are: give the widget a scroll
  view that is **not** on the primary-action path, or move something off the screen.
- **Overflow is necessary and not sufficient.** A layout can avoid overflowing by pushing the primary
  action below the fold, which is why `12 §6.4` adds a reachability assertion. Quick Entry is one of
  the three variants that carry it — and today it runs **without** the export banner, because the
  banner does not exist. The banner-shown form is `07 §5.1`'s harder case and belongs to **N21-T08**,
  which adds variant 14. Say so in a comment beside the assertion.
- **Read the scroll position off `ScrollableState.position`, never `Scrollable.controller`.** `12 §6.4`
  spells the trap out: a `Scrollable` built without an explicit controller has `controller == null`, so
  a `.where((s) => s.controller?.position …)` filter is empty on **every screen in this app** and the
  assertion passes without asserting anything. This is a test that lies rather than fails, which is the
  worst kind.
- **`pumpApp`'s default padding is not zero and must not be overridden here.**
  `EdgeInsets.only(top: 47, bottom: 34)` — *"real phones have a notch and a home indicator. A
  zero-padding harness hides the entire class of bug where a bottom-anchored 60 pt target is under the
  home bar — which is every primary action in this app"* (`12 §5.1`). The reachability assertion's
  `667 - 34` comes from that default.
- **2.6.1 spellings only.** `ProviderContainer.test()` and `WidgetTester.container` are Riverpod 3
  (decision #18) and do not exist here; `shedContainer(db, overrides: …)` plus
  `addTearDown(container.dispose)` is the shape, and the harness already registers the teardown.
  Override **leaves, never controllers** (`02 §5.4`).
- **The matrix is not the tap-target, semantics or contrast sweep.** Those three also iterate
  `kPumpableVariants` (`12 §7.4`, §7.6) and they are **N33-T02 / T03 / T04**. Writing one here would
  repeat critique defect **S7** — a gate that iterates an empty-ish list and passes, silently, forever.
  Put a one-line comment in the matrix file naming the other three iterators, so the next person adding
  a variant knows what else they are feeding.
- **`test/screens/` and `test/integration/` are banned directories** (R57). The widget tier mirrors
  `lib/features/`, so the file is `test/features/overflow_matrix_test.dart` and nothing else.

### 5.4 The full test set

`test/features/overflow_matrix_test.dart`, plus one harness case.

| Case | What it asserts |
|---|---|
| `'the matrix count equals kPumpableVariants.length times the device, scale and bold axes'` | **The anchor.** The product is computed from the same lists the loops iterate; today it is 18, and the `reason:` names N33-T01 as where it becomes 252 |
| `'kPumpableVariants covers every route whose screen exists today'` | Membership, derived — not `length == 1` |
| `'every kPumpableVariants key is a RouteNames value or a documented variant suffix'` | Guards the shape `quick_entry.export_banner` will need at N21-T08 without adding it now |
| `'quick_entry · small · scale 1.0 · bold false — no overflow'` … (18 generated cells) | `Device.all` × `kTextScales` × `kBoldStates`. `takeException()` is null in every one |
| `'Quick Entry: the confirm key is on screen without scrolling'` | `Device.small` × 1.3. `Rect.bottom ≤ 667 - 34`; position read off `ScrollableState.position` |
| `'no cell shares state with another'` | Run the file twice with two different `--test-randomize-ordering-seed` values in CI; locally, assert each cell's database is a distinct instance |
| `'the harness comment names N23-T05 and the per-epic variant ledger'` | A source-text case over `harness.dart`. The comment **is** the artefact for critique S3, and a comment nothing reads is a comment someone deletes |
| `'restoreFixture and armExportBanner are not referenced yet'` | Source text. Referencing either today is exactly the forward reference S3 is about |
| `'the matrix file names the other three iterators of kPumpableVariants'` | The S7 guard: whoever adds variant two must know they are also feeding the semantics, tap-target and contrast sweeps |
| `'quick_entry · typical · scale 1.3 · bold false — no overflow, inside the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London` with `atFixed` pinned to **01:30** on the clocks-back night. The page header renders a formatted date (T05), so a cell's content — and therefore its width — depends on the clock; pinning it stops a cell that runs at 23:59:59.9 flaking on a longer date string, and the repeated hour is where a naive header implementation renders two dates and overflows the 44 pt band |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **This task authors no string and no widget**, so the ARB row binds it negatively: a string in this
  diff means a screen was edited to make a cell pass, which is `12 §6.3`'s *"fix the layout, never the
  matrix"* read backwards.
- **The 3am test is what the matrix mechanises.** *"The 3am test is a set of prose claims: legible at
  18 pt, 60 pt targets, one thumb, no scrolling to reach the primary action. The matrix is what makes
  them mechanical"* (`12 §6.1`). Every deleted cell is a deleted claim.
- **Coverage is reported, never gated** (decision #119). Eighteen widget cells will move the number;
  that is not the point of them.

## 7. Definition of Done

- [ ] `'the matrix count equals kPumpableVariants.length times the device, scale and bold axes'` passes, and was seen to fail first for the stated reason
- [ ] the count is derived, never a remembered number
- [ ] the one cell passes at all three devices, three text scales and both bold states
- [ ] the comment states the seeds-now / fixtures-at-N23 rule once, where it will be read
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `kPumpableVariants` lives in `test/support/harness.dart`, has exactly one entry, and its ledger names the epic that adds each of the other thirteen
- [ ] the harness comment names **N23-T05** (not N23-T06) as the fixture switch, and the commit message notes the correction
- [ ] `expect(kPumpableVariants.length, 14)` does **not** appear; the membership assertion is derived
- [ ] `restoreFixture` and `armExportBanner` are referenced nowhere
- [ ] the reachability assertion reads `ScrollableState.position`, never `Scrollable.controller`, and is documented as the without-the-banner form
- [ ] no tap-target, semantics or contrast sweep is written here (critique S7)
- [ ] the file is `test/features/overflow_matrix_test.dart`; `test/screens/` does not exist (R57)
- [ ] the `uk-zone` cell exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/                 # the whole widget tier, after this epic
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

# Reproduce one cell the way 12 §6.3 says to.
fvm flutter test test/features/overflow_matrix_test.dart \
  --plain-name 'small · scale 2.0 · bold true'

# Randomised ordering, twice, with different seeds — cell independence.
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 1
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 2
```

```bash
grep -n "kPumpableVariants" test/support/harness.dart          # declared once, here
grep -rn "kPumpableVariants" test/ | wc -l                     # one declaration + one iterator today
grep -n "N23-T05" test/support/harness.dart                    # the fixture-switch comment
grep -rn "restoreFixture\|armExportBanner" test/               # expect zero
grep -rn "expect(kPumpableVariants.length, 14)" test/          # expect zero
grep -rn "Scrollable.controller" test/                         # expect zero
ls test/screens test/integration 2>/dev/null                   # must not exist (R57)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the overflow matrix, born with one variant`
