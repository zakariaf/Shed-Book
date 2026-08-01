# N26-T07 — Two matrix variants — `flock` and `note_search`

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 7 of 7 |
| **Depends on** | N26-T06 |
| **Commit** | one commit · `test(features): the flock and note_search matrix variants` |

## 1. Why this task exists

Both routes join `kPumpableVariants`, taking the table to a count the arithmetic derives.
Note search is a real route and is pumped like any other, per `12 §6.1`'s variant 13.

This is the surviving half of the *"closer task"* the critique deleted (§4: *"What survives as its own
one-line task per screen: **add the matrix variant and the empty-state row** — two files, one commit,
and it is the row that keeps `kPumpableVariants` honest"*). Semantic labels, heading levels, widget
keys and ARB entries already landed **inside** T01–T06, which is what the plan claims and what N33 only
verifies.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1 (the fourteen variants; variant 13 is note search — *"A real route, not a spec §9 screen (07 §18). It is pumped like any other"*; the 14 × 3 × 3 × 2 = 252 arithmetic)** · **§6.2 (`kPumpableVariants` lives in `harness.dart` because **four** files iterate it; the printed table and the self-check)** · **§6.3 (what a failure looks like; *"fix the layout, never the matrix"*)** · **§6.4 (reachability — and the three variants that carry it, which do not include these two)** · §5.1 (`Device`, `pumpApp`, the notch/home-indicator padding) · §5.2 (the two seeding routes) · §5.3 (`test/support/`'s closed twelve) · §3.2 (the host `sqlite3` floor) · §11.3 (randomised ordering) | the table, the arithmetic and the failure protocol |
| `docs/engineering/CONVENTIONS.md` | **R58** (252 cells over 14 pumpable variants; *"the arithmetic must follow the variant list, not a remembered number"*) · **R57** (the test tree; `test/screens/` and `test/integration/` are banned) · §2.14 (`RouteNames`, `Routes` — 13 names, 12 push helpers) · §4.1 (test file naming) | **BINDING** on the count, the file and the folder |
| `docs/engineering/02-state-di-navigation.md` | **§8.1** (*"`RouteNames` has **thirteen** entries… `Routes` has **twelve** push helpers… the arithmetic is checkable"*) · §5.4 (overriding in tests — leaves, never controllers) · §2.1–§2.3 (the Riverpod-3 ban list: no `ProviderContainer.test`, no `WidgetTester.container`) | the two push helpers this epic contributed, and the 2.6.1 spellings |
| `docs/engineering/07-screens.md` | §21.2 (the matrix and the reachability assertions) · §18 (note search's states, which every cell must render one of) · §3.2 (Flock's six states) | which assertion belongs to which variant |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (*"Note search still carries a level-1 title, because §7.3's gate asserts at least one `headingLevel > 0` node on **all fourteen** variants, not on twelve"*) · §7.2 (the per-screen sweep runs over the **14 pumpable variants**) · §4.2 (why clamping is a bug) | why note search is in the table at all |
| `docs/engineering/13-build-ci-release.md` | §4.2–§4.3 (`test` runs `-P ci-fast` with `--test-randomize-ordering-seed random`, and installs `libsqlite3-dev` on the host) | why every cell must be independent |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#114** (the overflow matrix — superseded by R58 on the count) · #99 (never clamp text scale) · #111 (`NativeDatabase.memory()`, never a mock) · #121 (randomised ordering) | the decisions the matrix applies |
| `epics/00-PLAN-CRITIQUE.md` | **§4** (*"delete the closer task"* — what survives is this) · **S3** (the matrix is created in E10, its fixture arrives in E19) · **S7** (the sweeps iterate a variant table and must not be written per screen) · §10 (the rules of the corrected plan) | why this task is one line and not five |
| `epics/N13-quick-entry-the-deck-and-the-keypad/N13-T07-…md` | the harness ledger comment it planted, naming which epic adds which variant | the ledger this task updates — and the line it must correct |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the variant table and its derived count |
| `shed-screens-and-routing` | both routes and their push helpers |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'flock and note_search both pump at every device, text scale and bold state'`
- **Why it is red today** — two screens exist and the variant table knows about neither.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on a remembered number. N13-T07 planted a **membership**
self-check, and this task extends it, not replaces it:

1. `kPumpableVariants.keys` still equals the set of `RouteNames` values **whose screen exists today**,
   which after this commit is eleven — the nine that were there plus `RouteNames.flock` and
   `RouteNames.noteSearch` — plus the one documented suffix key `quick_entry.export_banner`.
2. The generated cell count equals
   `kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length`,
   computed from the same lists the loops iterate. Today that is **11 × 3 × 3 × 2 = 198**, and this
   commit adds **36**.
3. The `reason:` string names **N33-T01** as the task where the assertion becomes
   `expect(kPumpableVariants.length, 14)`. **Do not write that line here** — it is `12 §6.2`'s
   eventual assertion and it belongs to the epic that makes it true.
4. Both variants pump against `restoreFixture(db, 'flock_400_3seasons.json')`. `12 §5.2`: fixtures for
   *shape at volume*, and a flock matrix seeded with six rows proves nothing about the screen that
   exists to render four hundred.

**Green.** The minimum code that passes, and nothing beyond it — two rows, two push helpers, two empty states.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

> **Correction to carry into the harness ledger.** N13-T07 planted the comment
> `flock, ewe_card, note_search        N26`. **`ewe_card` is not N26's.** The Ewe Card is its own epic
> and its variant lands in **N27-T07 — "The heading hierarchy, the matrix variant and the empty
> state"**. This epic adds **two** rows, not three. Fix the ledger line to
> `flock, note_search   N26` and `ewe_card   N27`, and note the correction in the commit message. A
> cross-reference that names the wrong epic is worse than none, because it is followed.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 7 (tests) only.** Nothing under `lib/` changes. This is a test-tier diff and the commit message
says so.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/support/harness.dart` | **Edit.** Add two rows to `kPumpableVariants` — `RouteNames.flock` and `RouteNames.noteSearch` — and correct the per-epic ledger comment's `ewe_card` line. The table lives here, not in the matrix file, because **four** files iterate it (`12 §6.2`) and *"a table copied four times is four tables that stop agreeing the first time a screen is added"* |
| 2 | `test/features/overflow_matrix_test.dart` | **Edit.** The self-check's expected membership and count move from nine to eleven; the two new variants' cells are generated by the existing loops with no new code |
| 3 | `test/support/seeds.dart` | **Edit, only if needed.** Both screens seed from the fixture, so probably nothing. If a note-search cell needs at least one hit to render the populated layout rather than an empty one, add it to the fixture-backed setup here, not inline in the matrix file |

`lib/` is untouched. **If a file under `lib/` appears in this diff, a cell was made to pass by editing
the screen** — which is `12 §6.3`'s *"fix the layout, never the matrix"* read backwards. That is a
legitimate thing to do, but it is a **separate commit** and it belongs to T02/T03/T06, not here.

### 5.2 The signatures

Two rows, and nothing else:

```dart
// test/support/harness.dart — iterated by four test files (12 §6.2, §7.4, §7.6)
//
// ELEVEN entries after this commit. It reaches FOURTEEN at N33-T01 — the
// thirteen RouteNames screens plus the export-banner variant (CONVENTIONS R58;
// decision #114's "216" was 12 x 18 and is superseded).
//
//   flock, note_search                   N26   <- this commit
//   ewe_card                             N27   <- CORRECTED: was written N26
//   season_summary                       N28
//   settings                             N29
//
final kPumpableVariants = <String, Widget Function()>{
  …                                                        // the nine already here
  RouteNames.flock:      () => const FlockScreen(),
  RouteNames.noteSearch: () => const NoteSearchScreen(),
};
```

Both are **const, zero-argument** constructors, and that is not an accident:

```dart
// 12 §6.2's printed table takes a `Widget Function()`. Every per-animal variant
// passes a fixture id constant — EweCardScreen(eweId: kSeedEwe),
// LambingEntryScreen(lambingId: kSeedLambing). Flock and note search take
// NONE: both are hub screens with no family argument, so their rows are
// `() => const XScreen()` and they need no fixture id constant added to
// harness.dart's `kSeed*` set.
```

The self-check, extended rather than replaced:

```dart
// test/features/overflow_matrix_test.dart
test('the matrix covers every route whose screen exists, and the count is derived', () {
  // Membership, DERIVED — not `length == 11`. This is the assertion that makes
  // it impossible for the table to silently stop covering a screen someone
  // added (12 §6.2, R58).
  …
  expect(
    kPumpableVariants.length *
        Device.all.length * kTextScales.length * kBoldStates.length,
    198,
    reason: '11 variants x 3 devices x 3 scales x 2 bold states. '
        'Becomes 14 x 3 x 3 x 2 = 252 at N33-T01, which is also where '
        '`expect(kPumpableVariants.length, 14)` belongs (R58).',
  );
});
```

### 5.3 The details that are easy to get wrong

- **Do not write `expect(kPumpableVariants.length, 14)`.** `12 §6.2` prints that line because it is
  describing the *finished* matrix. Writing it here makes the suite red for three epics, and the
  natural "fix" is to delete the self-check — which is exactly how a matrix silently stops covering a
  screen. N33-T01 replaces the membership assertion with the 14 and the
  `reason: '13 routes + the export-banner variant (R58)'`.
- **The count is arithmetic over the same lists the loops use.** `kTextScales` and `kBoldStates` are
  declared beside the table for this reason (N13-T07). If the self-check hard-codes `3` and `2` while
  the loops iterate literals, adding a fourth text scale passes the self-check and silently changes the
  matrix — the failure mode R58 exists to prevent.
- **The N13-T07 ledger assigns `ewe_card` to N26 and it is wrong.** Correct it here, in the same commit
  that touches the line. N27-T07's title is literally *"The heading hierarchy, the matrix variant and
  the empty state"*.
- **Both variants pump the *populated* layout, not the empty one.** An empty flock is one line of copy
  and one button: it cannot overflow, so thirty-six green cells would prove nothing. `restoreFixture(db,
  'flock_400_3seasons.json')` is already what the matrix uses (N23-T05 switched it), and note search
  additionally needs a **query** typed into it — an unqueried note-search screen renders the
  `NoQuery` empty box and is the smallest layout the screen has. Type a query that hits before
  asserting, or the cell is testing the wrong state.
- **Do not add a reachability assertion to either variant.** `12 §6.4` names exactly three — Quick
  Entry, Lambing Entry and Foster — *"at the smallest device × textScaler 1.3, and for Quick Entry with
  the banner shown"*. Flock and note search are scrolling lists whose primary action is a bottom-anchored
  slab; `06 §7`'s mitigation (c) — *"no action is ever reachable only behind a scroll"* — is held by
  T02 and T04's own target tests, not by the matrix. Adding a fourth reachability assertion here would
  fail on a long flock list for a reason that is correct behaviour.
- **Do not write a tap-target, semantics or contrast sweep here.** Those three also iterate
  `kPumpableVariants` (`12 §7.4`, §7.6) and they are **N33-T02 / T03 / T04**. Writing one here repeats
  critique defect **S7**. What this task *should* do is leave the one-line comment N13-T07 planted
  intact — the one naming the other three iterators — so the next person adding a variant knows what
  else they are feeding.
- **Every cell builds its own database.** The `test` job runs `--test-randomize-ordering-seed random`
  (decision #121, `13 §4.3`) *because* order-dependent state otherwise shows up as a flake at 11pm on
  release day. This matters more for these two variants than for any before them: `noteSearchProvider`
  is `.autoDispose.family` with a `Timer` behind it (T05), and a cell that leaks a listener makes the
  next cell's statement count wrong.
- **`pumpAndSettle()` and the note-search debounce.** `12 §5.1`: *"`pumpAndSettle()` with no timeout is
  safe here only because indefinite animations are banned."* A pending 200 ms `Timer` is **not** an
  animation and `pumpAndSettle` does not wait for it — so a cell that types a query and asserts
  immediately renders the pre-debounce state. Advance time explicitly, or seed the settled query
  through the controller.
- **`pumpApp`'s default padding is not zero and must not be overridden.**
  `EdgeInsets.only(top: 47, bottom: 34)` — *"real phones have a notch and a home indicator. A
  zero-padding harness hides the entire class of bug where a bottom-anchored 60 pt target is under the
  home bar"* (`12 §5.1`). The flock's `+ EWE` slab is exactly such a target.
- **Fix the layout, never the matrix.** `12 §6.3`, in order: read the cell name; reproduce the one cell
  with `--plain-name`; fix the layout. **Deleting a cell is deleting the 3am test.** Clamping
  `textScaler` is banned outright (decision #99) and defeats Android 14+'s own non-linear curve.
  Wrapping user-facing text in a `FittedBox` is banned in review — *"shrinking a tag number to fit is
  the opposite of legible."* The two legitimate fixes are a scroll view **not** on the primary-action
  path, or moving something off the screen.
- **The 88 px row at scale 2.0 is where these cells will bite.** Indelible §3.6's table grows the ewe
  row from 88 px to 156 px at 200 %, and the trailing state word plus its 32 px figure sit on the same
  line as a 32 px tag. `Device.small` × 2.0 × bold is the cell to read first when this goes red.
- **`test/screens/` and `test/integration/` are banned directories** (R57). The widget tier mirrors
  `lib/features/`, so the file is `test/features/overflow_matrix_test.dart` and nothing else.
- **2.6.1 spellings only.** `ProviderContainer.test()` and `WidgetTester.container` are Riverpod 3
  (decision #18) and do not exist here; `shedContainer(db, overrides: …)` is the shape and the harness
  already registers `addTearDown(container.dispose)`. Override **leaves, never controllers**
  (`02 §5.4`).
- **`flutter test` runs on the host, so the host must supply sqlite3.** `12 §3.2` and `13 §4.3`. A
  developer whose thirty-six new cells all fail to open a database should install `libsqlite3-dev`
  rather than mock the database (decision #111).

### 5.4 The full test set

`test/features/overflow_matrix_test.dart`, plus the harness edit.

| Case | What it asserts |
|---|---|
| `'flock and note_search both pump at every device, text scale and bold state'` | **The anchor.** Thirty-six generated cells — 2 × `Device.all` × `kTextScales` × `kBoldStates` — each with `tester.takeException()` null |
| `'the matrix covers every route whose screen exists, and the count is derived'` | Membership derived from the built screens; the product computed from the same lists the loops iterate; today **198**; the `reason:` names N33-T01 |
| `'kPumpableVariants contains flock and note_search'` | Both keys present, both values `() => const …Screen()` with no family argument |
| `'the harness ledger names N27 for ewe_card'` | A source-text case over `harness.dart`. The corrected line **is** the artefact; a comment nothing reads is a comment someone deletes |
| `'expect(kPumpableVariants.length, 14) does not appear'` | Source text. That assertion is N33-T01's |
| `'no reachability assertion was added for flock or note_search'` | Source text over the matrix file. `12 §6.4` names three variants and only three |
| `'no tap-target, semantics or contrast sweep was written here'` | Critique **S7**. Those are N33-T02 / T03 / T04 |
| `'each note_search cell renders the populated layout, not the NoQuery box'` | The state trap. Assert at least one `SearchHitRow` per note-search cell |
| `'each flock cell renders more than one row'` | The same trap on the other screen — a matrix over an empty list proves nothing |
| `'no cell shares a database with another'` | Each cell builds its own `testDatabase()`; run the file twice with different `--test-randomize-ordering-seed` values |
| `'no lib/ file changed in this commit'` | A source-tier assertion in the commit, not in the suite: `git diff --name-only --cached -- lib/` is empty |
| **`@Tags(['uk-zone'])`** `'flock · typical · scale 1.3 · bold false — no overflow, inside the ambiguous DST hour'` | `TZ=Europe/London` with the clock pinned to **01:30** on the clocks-back night. Both screens render formatted dates — the flock's `STRUCK 12 MAR` margin (T03) and the note-search hit's `d MMM y` (T06) — so a cell's **width** depends on the clock. Pinning it stops a cell that runs at 23:59:59.9 flaking on a longer date string, and the repeated hour is where a naive implementation renders two dates and overflows the 68 px margin cell |
| **`@Tags(['uk-zone'])`** `'note_search · small · scale 2.0 · bold true — no overflow, inside the ambiguous DST hour'` | The worst cell of the two, at the worst clock. 156 px rows at 200 % plus a two-line provenance stamp is where the 64 px ruled row runs out |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **This task authors no string and no widget**, so the ARB rule binds it *negatively*: a string in
  this diff means a screen was edited to make a cell pass, which is `12 §6.3` read backwards. If a
  layout genuinely has to change, that is a separate commit against T02, T03 or T06.
- **The 3am test is what the matrix mechanises.** *"The 3am test is a set of prose claims: legible at
  18 pt, 60 pt targets, one thumb, no scrolling to reach the primary action. The matrix is what makes
  them mechanical"* (`12 §6.1`). Every deleted cell is a deleted claim.
- **Coverage is reported, never gated** (decision #119). Thirty-six widget cells will move the number;
  that is not the point of them.

## 7. Definition of Done

- [ ] `'flock and note_search both pump at every device, text scale and bold state'` passes, and was seen to fail first for the stated reason
- [ ] both variants present
- [ ] both push helpers added to `routes.dart`
- [ ] the count stays derived
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the two push helpers are `Routes.flock` (landed in T01) and `Routes.noteSearch` (landed in T05); this task **asserts** both exist and that `RouteNames` still has thirteen entries
- [ ] `kPumpableVariants` has eleven entries and the derived cell count is **198**
- [ ] `expect(kPumpableVariants.length, 14)` does **not** appear; the membership assertion stays derived
- [ ] the harness ledger's `ewe_card` line reads **N27**, and the commit message notes the correction
- [ ] no reachability assertion was added for either variant (`12 §6.4` names three, and only three)
- [ ] no tap-target, semantics or contrast sweep was written here (critique **S7**)
- [ ] every cell renders the **populated** layout — note search with a query that hits, flock with more than one row
- [ ] the `uk-zone` cells exist and fail when the `TZ=Europe/London` leg is removed
- [ ] no file under `lib/` appears in this diff
- [ ] the file is `test/features/overflow_matrix_test.dart`; `test/screens/` and `test/integration/` do not exist (R57)

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
make check
make test
```

```bash
fvm flutter test test/features/                 # the whole widget tier, after this epic
TZ=Europe/London fvm flutter test --tags uk-zone

# Reproduce one cell the way 12 §6.3 says to.
fvm flutter test test/features/overflow_matrix_test.dart \
  --plain-name 'note_search · small · scale 2.0 · bold true'

# Randomised ordering, twice, with different seeds — cell independence.
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 1
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed 2
```

```bash
grep -n "kPumpableVariants" test/support/harness.dart          # declared once, here
grep -n "N27" test/support/harness.dart                        # the corrected ledger line
grep -rn "expect(kPumpableVariants.length, 14)" test/          # expect zero
grep -rn "getRect\|maxScrollExtent" test/features/overflow_matrix_test.dart
                                                               # expect only the three 12 §6.4 variants
grep -c "static const" lib/routing/routes.dart                 # RouteNames still 13 (02 §8.1)
grep -n "Routes.flock\|Routes.noteSearch" lib/routing/routes.dart   # both helpers present
git diff --name-only main -- lib/                              # expect empty
ls test/screens test/integration 2>/dev/null                   # must not exist (R57)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the flock and note_search matrix variants`
