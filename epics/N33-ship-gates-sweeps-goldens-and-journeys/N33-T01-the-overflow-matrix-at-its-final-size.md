# N33-T01 — The overflow matrix at its final size

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 1 of 9 |
| **Depends on** | N32-T03 · N13-T07 · N24-T08 |
| **Commit** | one commit · `test(features): the matrix at its final 252 cells` |

## 1. Why this task exists

Fourteen variants × 3 devices × 3 text scales × 2 bold states = **252 cells**, with the
count **derived from the variant list, never typed**. Decision #114's 216 predates variants 13 and 14
and is superseded.

`12 §6.1` calls the matrix *"the best value-per-line in the suite: ~30 lines of table-driven code buys
252 assertions across every screen the product has."* That is only true once every screen exists.
N13-T07 was born with one entry and a ledger comment naming the epic that adds each row; this task
closes the ledger, deletes it, and turns the arithmetic on. It is also the first task in the project
that can honestly load `flock_400_3seasons.json` into every cell — the fixture is written through the
restore path at N23-T05 and regenerated at N24-T08, which is why those two are dependencies and not
footnotes.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1** (the fourteen variants, one row at a time, with the reason each is its own variant) · **§6.2** (`kPumpableVariants` and the matrix, both printed in full) · **§6.3** (what a failure looks like, and the three banned "fixes") · §5.1 (`pumpApp` and every default it sets) · §5.2 (targeted seeds versus committed fixtures) · §5.3 (the closed twelve-file `test/support/` list, and `kSeedEwe`/`kSeedLambing`/`kSeedLamb`/`kSeedSeason`) · §11.1 (a matrix cell's name **is** its reproduction command) · §11.3 (randomised ordering, and what it catches) · §11.5 (the two committed fixtures and their shapes) | the table, its arithmetic, its self-check and what each cell may do |
| `docs/engineering/CONVENTIONS.md` | **R58** (252 cells over 14 pumpable variants; the arithmetic follows the variant list) · R57 (the test tree) · §1 (the tree) · §4.5 (widget keys) · §5 (the words) | **BINDING** on the count, the paths and the file names |
| `docs/engineering/07-screens.md` | §16.4 (the export banner is a real layout state, and what gives way when it does not fit) · §18 (note search is a real route, not a spec §9 screen) · §21.2 (the matrix row, and why 216 is superseded) · §20 rule 1 (primary actions live in the bottom third) | why the fourteenth and thirteenth variants exist |
| `docs/engineering/02-state-di-navigation.md` | §8.1 (`RouteNames` — thirteen constants, twelve push helpers, and the checkable arithmetic) | the thirteen names the self-check iterates |
| `docs/engineering/10-accessibility-and-i18n.md` | §4.1 (`TextScaler`, never `textScaleFactor`) · §4.2 (why clamping is a bug, and what it costs the Larger Text declaration) · §4.4 (`FittedBox` is banned around user-facing text) · §4.6 (Bold Text, and the bug that makes heavy text lighter) | the two axes, and the three fixes that are banned |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #99 · #114 · #121 | Flutter **3.44.8** / Dart **3.12.2**; the matrix and its superseded count |
| `epics/00-PLAN-CRITIQUE.md` | **S1** (why the table could not exist in E09) · **S3** (seeds now, fixtures at N23) · §11.3 (this task's anchor, named) | why this table grew a row per epic instead of arriving whole |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the matrix, its arithmetic and its self-check |
| `shed-accessibility-and-copy` | text scaling and bold text are its axes |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'the matrix covers every route, and the count is 14'`
- **Why it is red today** — the table has thirteen entries and the fourteenth — Quick Entry with the banner — is the one the reachability assertion needs most.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion in three ways before you make it green. Assert `expect(routes, hasLength(13),
reason: 'RouteNames declares 13 (02 §8.1)')` **first**, so a fourteenth route added later fails on the
route list rather than on the map. Then assert every one of the thirteen appears as a key. Then assert
`kPumpableVariants.length == 14` with the reason `'13 routes + the export-banner variant (R58)'`. The
three together are what make a missing screen a named failure instead of a smaller matrix.

**Green.** The minimum code that passes, and nothing beyond it — the final table, the self-check asserting every `RouteNames` constant appears, and the
derived arithmetic.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) only. Nothing under `lib/` changes** — say so in the commit message, and if a cell goes
red, the layout fix belongs in the screen's own epic unless it is a one-line edit you can review as
part of this diff.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Edit.** `kPumpableVariants` grows to its final **fourteen** entries; the N13-T07 ledger comment is **deleted**, because every row it promised has landed and a ledger that still promises a future edit is a ledger someone acts on twice. The `kSeedEwe` / `kSeedLambing` / `kSeedLamb` / `kSeedSeason` constants are confirmed to resolve inside `flock_400_3seasons.json` as regenerated at N24-T08 |
| 2 | `test/features/overflow_matrix_test.dart` | **Edit.** The anchor self-check in its final form, the four nested loops over the four axis lists, and the fixture load per cell. The `seeds.dart` calls N13-T07 used are replaced by `restoreFixture` — N23-T05 already made that switch for the variants that existed then; this task finishes it |
| 3 | `test/support/seeds.dart` | **Edit, if needed.** `armExportBanner(db)` exists from N21-T08; this task only calls it. Add nothing here. If it does not arm the banner against the regenerated fixture, the bug is in the fixture or in the four `app_settings` columns, and it is fixed there |
| 4 | `docs/engineering/12-testing.md` §6.2 | **Verify, do not rewrite.** The printed table already carries fourteen rows; confirm the code you land matches it key for key. If it does not, one of the two is wrong and the amendment rule applies |

`test/design/gate_inventory_test.dart`'s assertion that *"none of the four design files references
`kPumpableVariants` yet"* is still true after this task — the sweeps are T02 and T03. Do not flip it
here.

### 5.2 The signatures

The table, in its final form. `12 §6.2` prints it; this is that, with the two things that are easy to
get wrong marked:

```dart
// test/support/harness.dart — iterated by FOUR test files (12 §6.2, §7.4, §7.6):
// overflow_matrix_test.dart, semantics_gate_test.dart, tap_target_test.dart,
// contrast_test.dart. Declared once, here, beside Device — "a table copied four
// times is four tables that stop agreeing the first time a screen is added."
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.flock:         () => const FlockScreen(),
  RouteNames.eweCard:       () => const EweCardScreen(eweId: kSeedEwe),
  RouteNames.quickEntry:    () => const QuickEntryScreen(),
  RouteNames.lambingEntry:  () => const LambingEntryScreen(lambingId: kSeedLambing),
  RouteNames.lambCard:      () => const LambCardScreen(lambId: kSeedLamb),
  RouteNames.foster:        () => const FosterScreen(lambId: kSeedLamb),
  RouteNames.penBoard:      () => const PenBoardScreen(),
  RouteNames.treatments:    () => const TreatmentsScreen(),
  RouteNames.reminders:     () => const RemindersScreen(),
  RouteNames.seasonSummary: () => const SeasonSummaryScreen(seasonId: kSeedSeason),
  RouteNames.export:        () => const ExportScreen(),
  RouteNames.settings:      () => const SettingsScreen(),
  RouteNames.noteSearch:    () => const NoteSearchScreen(),

  // The fourteenth. Its key is a LITERAL, not RouteNames.quickEntry — the two
  // variants are the same screen in two layout states, and a duplicate map key
  // silently overwrites, leaving 13 entries and 234 cells that still pass.
  'quick_entry.export_banner': () => const QuickEntryScreen(),   // armed by seeds
};

/// The three axes, declared beside the table so the matrix's arithmetic and its
/// loops read the SAME lists. R58: the count follows the variant list.
const kTextScales = <double>[1.0, 1.3, 2.0];
const kBoldStates = <bool>[false, true];
```

The self-check. This is the only place in the suite where the count is derived rather than remembered:

```dart
// test/features/overflow_matrix_test.dart
test('the matrix covers every route, and the count is 14', () {
  const routes = <String>[
    RouteNames.flock, RouteNames.eweCard, RouteNames.quickEntry,
    RouteNames.lambingEntry, RouteNames.lambCard, RouteNames.foster,
    RouteNames.penBoard, RouteNames.treatments, RouteNames.reminders,
    RouteNames.seasonSummary, RouteNames.export, RouteNames.settings,
    RouteNames.noteSearch,
  ];
  // Dart cannot enumerate an abstract final class's statics, so the list is
  // hand-typed and THIS assertion is what fails when a fourteenth route lands.
  expect(routes, hasLength(13), reason: 'RouteNames declares 13 (02 §8.1)');

  for (final r in routes) {
    expect(kPumpableVariants.keys, contains(r), reason: 'route "$r" is not in the matrix');
  }
  expect(kPumpableVariants.length, 14, reason: '13 routes + the export-banner variant (R58)');

  // 252, computed from the same four lists the loops below iterate. If this
  // line reads `expect(cells, 252)` against a literal, delete it: a remembered
  // number is exactly what R58 forbids.
  final cells = kPumpableVariants.length *
      Device.all.length * kTextScales.length * kBoldStates.length;
  expect(cells, kPumpableVariants.length * 18,
      reason: '3 devices x 3 scales x 2 bold states is 18 per variant');
});
```

The cell body, unchanged from `12 §6.2` except for the banner assertion:

```dart
for (final entry in kPumpableVariants.entries) {
  for (final device in Device.all) {
    for (final scale in kTextScales) {
      for (final bold in kBoldStates) {
        testWidgets(
          '${entry.key} · ${device.name} · scale $scale · bold $bold — no overflow',
          (tester) async {
            final db = await testDatabase();
            await restoreFixture(db, 'flock_400_3seasons.json');
            if (entry.key == 'quick_entry.export_banner') {
              await armExportBanner(db);
            }
            await tester.pumpApp(entry.value(),
                db: db, device: device, textScale: scale, boldText: bold);
            if (entry.key == 'quick_entry.export_banner') {
              // Without this, an unarmed banner makes variant 14 a duplicate of
              // variant 3: eighteen cells that pass and prove nothing.
              expect(find.byKey(const Key('quick_entry.export_banner')), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
```

### 5.3 The details that are easy to get wrong

- **The two Quick Entry variants must not share a map key.** This is the single highest-cost mistake
  available in this file. `RouteNames.quickEntry` used twice makes the second entry overwrite the
  first; `kPumpableVariants.length` becomes 13; the matrix runs 234 cells; every one of them passes;
  and the only thing that notices is the anchor's `expect(…, 14)`. That is why the anchor exists and
  why it is written before the table.
- **`RenderFlex` overflow needs no package and none is used.** It is reported through
  `FlutterError.onError` during layout, which the test binding captures. The binding fails the test on
  any unhandled `FlutterError` whether or not you call `takeException()` — the explicit assertion is
  there so the failure message names the **cell**, and the cell name is the reproduction command
  (`12 §11.1`).
- **Reproduce one cell with `--plain-name`, never by commenting out loops.**
  `flutter test test/features/overflow_matrix_test.dart --plain-name 'small · scale 2.0 · bold true'`.
  `flutter test` passes `--plain-name` through; it does **not** accept `-P`/`--preset`
  (`12 §11.2`).
- **Fix the layout, never the matrix.** `12 §6.3` names the three banned fixes and each is a defect
  elsewhere in the doc set: deleting a cell deletes the 3am test; clamping `textScaler` is decision
  #99 and defeats Android 14+'s own non-linear curve; a `FittedBox` around user-facing text shrinks a
  tag number to fit, which is the opposite of legible. The two legitimate fixes are a scroll view that
  is **not** on the primary-action path, or moving something off the screen.
- **`pumpApp`'s defaults are load-bearing and must not be overridden per cell.** The
  `EdgeInsets.only(top: 47, bottom: 34)` inset is what keeps a bottom-anchored 60 pt target off the
  view boundary — and off the boundary is the only way `MinimumTapTargetGuideline` will look at it at
  all (`12 §7.3` rule 4). A cell that passes `padding: EdgeInsets.zero` to "simplify" has removed the
  home indicator from every phone the product runs on.
- **`textScaler`, never `textScaleFactor`** — the latter is deprecated, banned everywhere including
  the theme layer, and `a11y.scale_factor` greps for it.
- **Bold text is an axis here and is deliberately *not* an axis in the two sweeps.** 252 cells here;
  84 runs in T02 and T03. Bold changes glyph weight and text width — a layout property — not the
  minimum-size constraints the guideline gates assert. Adding it to the sweeps costs 42 more runs each
  and buys nothing.
- **Every cell restores the 400-ewe fixture, and that is the cost of the file.** 252 in-memory
  databases, 252 restores. The tempting optimisation is one shared database in `setUpAll`; do not.
  `12 §11.3` runs this suite with `--test-randomize-ordering-seed random` precisely to catch a fixture
  mutated in place by a previous test, and a shared database makes that bug unfindable. If wall clock
  genuinely blocks, shard with `--total-shards` / `--shard-index`, never by deleting cells.
- **`restoreFixture` must be asserted to have loaded something.** A silently-failing restore — a
  mistyped table name, a swallowed exception, a rolled-back transaction — leaves every cell rendering
  the *empty* layout, which is smaller and cannot overflow. All 252 go green and prove nothing.
  N23-T05 already names this; the cheapest guard here is a count assertion in the anchor rather than
  per cell.
- **Variant 14's key is a widget key, not a route.** `07 §16.4` makes the banner a real layout state
  in which *"the filtered-match list loses a row, then the 'in the pens' strip; the keypad, the confirm
  bar and the recents strip never shrink."* If the banner cell overflows, that ordering is the fix.
- **The matrix is not tagged.** It runs in `ci-fast` on every push. Do not tag it `slow` to move it out
  of the fast job — it *is* the fast job's most valuable content.
- **The fixture carries the shapes the matrix needs to be honest** (`12 §11.5`): a culled ewe whose tag
  a live ewe reuses, at least one edited timestamp, at least one contradictory lambing, unicode notes.
  A cell rendered against a tidy fixture is a cell that never sees `~ edited`, a query mark or a
  long-grapheme note — three of the layouts most likely to overflow at scale 2.0 with bold on.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/overflow_matrix_test.dart` · `'the matrix covers every route, and the count is 14'` | **The anchor.** Thirteen `RouteNames` constants present, `hasLength(13)` on the route list, `kPumpableVariants.length == 14`, and the cell count computed from the four axis lists |
| `…` · `'the two Quick Entry variants have different map keys'` | `kPumpableVariants.keys.where((k) => k.startsWith('quick_entry'))` has length 2. The duplicate-key collapse, caught by name |
| `…` · `'every variant builds a widget without throwing'` | Calls each `Widget Function()` outside a pump. A constructor that throws on a missing seed id fails here with the variant's name rather than 18 cells down |
| `…` · **252 generated cells** `'<variant> · <device> · scale <n> · bold <b> — no overflow'` | `takeException()` is null after `pumpAndSettle`. Fourteen variants × `Device.all` × `kTextScales` × `kBoldStates` |
| `…` · `'the export-banner variant renders the banner'` | `find.byKey(const Key('quick_entry.export_banner'))` finds one widget after `armExportBanner`. Without it, variant 14 is variant 3 |
| `…` · `'the fixture loaded — the flock is 400 ewes and three seasons'` | *edge.* A row-count assertion after `restoreFixture`, so a silent restore failure fails once, by name, instead of greening 252 cells |
| `…` · `'a variant that overflows fails with its cell name in the message'` | *canary.* Pump a deliberately over-tall throwaway widget through the same cell body and assert the failure text carries the device, the scale and the bold state. Delete the throwaway before committing; the case stays as a `skip`-free negative using `expectLater(..., throwsA(...))` around the harness call |
| `…` · `'a lambing recorded at 01:30 on 25 October renders both times and does not overflow'` | *edge, `uk-zone`.* `atFixed(DateTime(2026, 10, 25, 1, 30), …)`, the fixture's edited lambing pumped on `Device.small` at scale 2.0 with bold **on**. The provenance row prints the effective time **and** the original with `time edited by you` — two lines where one is budgeted, on the smallest device, in the repeated hour. This is the cell most likely to overflow in the whole matrix and it exists nowhere else |
| `…` · `'a withdrawal countdown clearing on the clocks-back day renders one date, not two'` | *edge, `uk-zone`.* `CLEAR 25 OCT` on the treatments variant at scale 2.0. The clear date is a civil date computed at write time; a cell that renders two candidates has read the instant twice |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the matrix covers every route, and the count is 14'` passes, and was seen to fail first for the stated reason
- [ ] `kPumpableVariants.length == 14`, asserted
- [ ] every `RouteNames` constant appears in the table
- [ ] 252 cells, derived
- [ ] no `RenderFlex` overflow and no exception in any cell
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the two Quick Entry variants have **different** map keys, asserted by its own case
- [ ] the literal `252` appears in no assertion — the count is the product of the four axis lists
- [ ] every cell loads `flock_400_3seasons.json` through `restoreFixture`, and a case proves the load happened
- [ ] the export-banner cell asserts the banner is present before it asserts no overflow
- [ ] N13-T07's ledger comment is **deleted** from `test/support/harness.dart`
- [ ] `12 §6.2`'s printed table and the landed table agree key for key
- [ ] the two ambiguous-hour cases exist and are tagged `uk-zone`
- [ ] no `textScaleFactor`, no `TextScaler.clamp`, no `withClampedTextScaling` and no `FittedBox` appears anywhere in the diff

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'small · scale 2.0 · bold true'
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the self-check is doing its job — break the table three ways, watch three different failures,
revert each:

```bash
# 1. Key the banner variant RouteNames.quickEntry instead of the literal.
fvm flutter test test/features/overflow_matrix_test.dart   # expect: length 13, not 14
# 2. Delete the note-search entry.
fvm flutter test test/features/overflow_matrix_test.dart   # expect: 'route "note_search" is not in the matrix'
# 3. Add a fourteenth RouteNames constant.
fvm flutter test test/features/overflow_matrix_test.dart   # expect: the hasLength(13) assertion
git checkout -- test/support/harness.dart lib/routing/routes.dart
```

```bash
grep -rn "textScaleFactor\|FittedBox\|withClampedTextScaling" test/ lib/   # expect zero
grep -c "252" test/features/overflow_matrix_test.dart                     # expect zero
fvm flutter test test/features/overflow_matrix_test.dart --reporter expanded | tail -3   # expect 252 cells + the self-checks
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the matrix at its final 252 cells`
