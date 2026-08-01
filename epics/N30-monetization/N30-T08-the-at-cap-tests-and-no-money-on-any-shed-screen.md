# N30-T08 — The at-cap tests, and no money on **any** shed screen

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 8 of 8 |
| **Depends on** | N30-T07 |
| **Commit** | one commit · `test(policy): no money on any shed screen, at any state or hour` |

## 1. Why this task exists

The at-cap behaviour against `flock_15_at_cap.json`, and N14-T07's assertion extended from
Quick Entry to **all five shed screens**, at every entitlement state and both sides of the quiet-hours
boundary. Decision #90, complete.

This is the task that closes the loop the epic opened. **N14-T07 wrote the sweep at step 5**, when
Quick Entry was the only screen that existed and monetization was sixteen epics away — deliberately, so
that every screen built afterwards was built against it. Four of those screens now exist, three
monetization surfaces now exist, and the entitlement is now real. The sweep grows to match, and it gains
the axis N14-T07 could not have: the **hour**.

The hour axis is not a nicety. `06 §12` constraint 3 is **wider** than the rule about shed screens: no
`ShedBanner` renders between 22:00 and 06:00 *"on any screen, at any ewe count"* — Flock and Settings
included. So this sweep has two halves that fail differently, and only one of them is about shed
screens.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§10.7** (the test printed in full, the five-screen map keyed by `RouteNames`, the **99-ewe** rationale, the keyed-not-typed assertions, and the two `FreeTierPolicy` properties that stay in `test/domain/`) · **§4.2** (`FakePurchaseService`'s tripwire: *"any store call during a `pumpApp` of a shed screen — decision #90's failure mode is a store call on the 3am path, and this is the only place it can be caught mechanically"*) · §5.1 (`pumpApp`, `shedContainer`) · §5.3 (`setEntitlement`, `setEwesInCurrentSeason`, `restoreFixture`) · §6 (the matrix) · §2.1 (installing time with `withClock`) · §10.1 (the tap budgets) | the sweep, its helpers and its numbers |
| `docs/engineering/11-monetization-and-store.md` | **§4.4** (nothing on the 3am path reads the entitlement; the failure mode is *"a paywall flash at 3am"*) · **§8** constraint 1 (the five shed screens, plus the seven other screens that also render nothing) · §8 constraint 2 (the quiet window, on any screen) · §8.1 (`over_free_cap` is bookkeeping; on not paying nothing is deleted, hidden, greyed, blurred, teased or made read-only) · §7.1 (what is capped and what never is) · §12.2 (the eight test files) · §11 (the fixtures) | what must be absent, and where |
| `docs/engineering/06-design-system.md` | **§12** constraints 1–3 (`ShedBanner` is the only monetization component; never on the five shed screens; **never 22:00–06:00 on any screen, at any ewe count**; *"the widget test that proves it sets the clock, not the entitlement"*) | the wider rule, which is the one that ships |
| `docs/research/00-tech-decisions.md` | §2 **#90** (the widget test, written at `unlocked: false, ewesInCurrentSeason: 99`) · **#92** (the affordance exists in exactly two places) · #86 (export never gated) · #91 · #120 (tap budgets extended to foster and repeat-treatment) · #74 (seed data through the restore path) · §7.0 ruling 8 | the assertion's own parameters |
| `docs/engineering/CONVENTIONS.md` | §1 (the `test/` tree) · §4.1 (a policy test states the **property**, not the file) · §4.5 + **R59** (widget keys are test contracts) · §5.1 (**shed screen**, never *"3am screen"* in code) · **R57** (the test tree; `test/features/` is the widget tier) · **R58** (252 cells over 14 variants; *"the arithmetic follows the variant list, never a remembered number"*) | the names and the tree |
| `epics/N14-quick-entry-the-write-path/N14-T07-nothing-about-money-renders-on-a-shed-screen.md` | the whole task — the file this one extends, its one-screen loop, and the keys it asserted absent | what already exists on `main` |
| `epics/00-PLAN-CRITIQUE.md` | **§11.3** — this task's `[audit]` row (*"the same file N14-T07 created, extended; R57"*) and N14-T07's · §11.5 · §9 change 12 (**N24 regenerates the fixtures**) | one file, not two |
| `docs/engineering/07-screens.md` | §19.2 (the two surfaces, and the seven screens that have none) · §19.4 (what the cap never does) · §5.4 (Quick Entry's write path and its budget) | the screens on both lists |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7 (restore is the path `restoreFixture` uses — decision #74 makes the seed a continuous test of the one code path that can lose five seasons) | why the fixture loads the way it does |
| `shed-book-spec.md` | **§5** (*"zero interruptions"* as a shipping gate: *"if a feature cannot be operated under these conditions, it does not ship"*) · §7.1 · §14 | the gate this test is |
| `CLAUDE.md` | the 3am floor · *"does the shepherd have to do anything new before the record exists?"* | the question this task answers with a test |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the cap's behaviour at the boundary |
| `shed-testing` | the five screens, the entitlement axis and the hour axis |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/no_money_on_a_shed_screen_test.dart`
- **Test** — `'no monetization widget renders on any of the five shed screens at any entitlement state or hour'`
- **Why it is red today** — the assertion covers one screen; four more now exist.

```bash
fvm flutter test test/policy/no_money_on_a_shed_screen_test.dart   # expect: failing, for the reason above
```

Sharpen it so a screen cannot be added later and silently escape. Build the loop from a **map keyed by
`RouteNames`** (`12 §10.7`'s shape) and assert in the same file that the map's key set is exactly the
five constants — `quickEntry`, `lambingEntry`, `lambCard`, `foster`, `penBoard`. A hand-typed list of
five widgets passes forever after a sixth shed screen exists; a key-set assertion fails the moment
`RouteNames` grows and makes somebody decide.

**Green.** The minimum code that passes, and nothing beyond it — extend the sweep to all five, and the at-cap behaviour against the fixture.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Tests only.** No schema, no domain, no data, no controller, no UI, no ARB — say so in the commit
message, and note that the commit type is `test(policy)` for that reason. If this task finds itself
editing something under `lib/`, it has found a defect in T01–T07 and the fix belongs in *that* task's
shape, not here.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/no_money_on_a_shed_screen_test.dart` | **Edit.** The file **N14-T07 created**. Its loop goes from one screen to five, and it gains the hour axis and the two-screen quiet-window half. **Do not create a second file** — see §5.3 |
| 2 | `test/features/free_tier_test.dart` | **Edit.** The at-cap behaviour against `flock_15_at_cap.json`: the boundary, both contexts, and the unchanged 3am path |
| 3 | `test/features/tap_budget_test.dart` | **Edit.** The budgets re-run **at the cap, locked** — five taps plus the first tally stroke, unchanged |
| 4 | `test/support/seeds.dart` | **Check, probably no edit.** `setEntitlement`, `setEwesInCurrentSeason` and `restoreFixture` are `12 §5.3`'s and have existed since N12/N23. `setEwesInCurrentSeason` *"tops the current season up to n ewes"*, which is how the sweep reaches 99 from a fixture that ships at 15 |
| 5 | `test/fixtures/flock_15_at_cap.json` | **Check.** N24 regenerated the fixtures after reminders and entitlements existed (critique **S10**, change 12). Confirm it still loads through the restore path and that its ewe count is `kFreeEweCap`, read rather than assumed. If it is stale, regenerate it with `tool/seed.dart` — **that is N24's shape and its own commit**, not this one's |
| 6 | `test/features/overflow_matrix_test.dart` | **Check.** T05 and T06 added the at-cap and over-cap rows (R58). This task confirms the count is still derived from the variant list and not a remembered number |

### 5.2 The two halves of the sweep

They fail differently and must read differently. `12 §10.7` prints the first:

```dart
// test/policy/no_money_on_a_shed_screen_test.dart
const shedScreens = <String, Widget Function()>{
  RouteNames.quickEntry:   () => const QuickEntryScreen(),
  RouteNames.lambingEntry: () => const LambingEntryScreen(lambingId: kSeedLambing),
  RouteNames.lambCard:     () => const LambCardScreen(lambId: kSeedLamb),
  RouteNames.foster:       () => const FosterScreen(lambId: kSeedLamb),
  RouteNames.penBoard:     () => const PenBoardScreen(),
};

for (final entry in shedScreens.entries) {
  testWidgets('${entry.key}: nothing monetization-related at 99 ewes, locked', (tester) async {
    final db = await testDatabase();
    await restoreFixture(db, 'flock_15_at_cap.json');
    await setEntitlement(db, unlocked: false);
    // Decision #90 writes the assertion at 99 ewes — far past any cap shape the
    // free tier could take. The fixture ships at the cap; the helper tops the
    // current season up. Both numbers matter: at-cap is the boundary, 99 is the
    // state where a paywall would be most tempting to render.
    await setEwesInCurrentSeason(db, 99);

    await tester.pumpApp(entry.value(), db: db);

    // Keyed, not typed: a key is a contract this test could hold before
    // 11-monetization-and-store.md's widget existed.
    expect(find.byKey(const Key('flock.upgrade_row')), findsNothing);
    expect(find.byKey(const Key('settings.upgrade_row')), findsNothing);
    expect(find.textContaining('Unlock'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
  });
}
```

The second half is 06's wider rule, and it is about the **two screens that legitimately carry a row**:

| Half | Screens | Axis | What a failure means |
|---|---|---|---|
| **Shed screens** | Quick Entry, Lambing Entry, Lamb Card, Foster, Pen Board | entitlement × ewe count × hour | A paywall flash at 3am. Decision #90 is broken and spec §5's shipping gate is not met |
| **The quiet window** | **Flock and Settings** | **hour only — the entitlement is held fixed** | The app solicited a shepherd at 23:00. `06 §12` constraint 3 is broken |

### 5.3 The details that are easy to get wrong

- **One file, not two.** `12 §12.2` and R57 name `test/features/no_monetization_test.dart` (the widget
  tier mirrors `lib/features/`); this backlog's anchors name
  `test/policy/no_money_on_a_shed_screen_test.dart`, in **both** N14-T07 and here, consistently. The
  critique's `[audit]` row for this task settles the thing that matters: *"the same file N14-T07
  created, extended."* **Extend it. Do not create a second sweep** — two sweeps means one of them stops
  being maintained, and it will be the one that would have caught the bug. If the file is renamed to
  R57's spelling, that is a rename in this commit, not a new file, and every reference moves with it.
- **The quiet-window half sets the clock, not the entitlement.** `06 §12` constraint 3 says so
  explicitly and `11 §12.2` repeats it. A test that reaches *"no row rendered"* by flipping `unlocked`
  proves the entitlement gate, which is a different property and is already covered. Install time with
  `withClock` (`12 §2.1`); the entitlement is identical in both halves.
- **99 ewes, not 16.** Decision #90 writes the assertion far past any cap shape the free tier could
  take, so that a change to `kFreeEweCap` cannot quietly move the test out from under the property.
  The fixture ships **at** the cap and `setEwesInCurrentSeason` tops it up — both numbers matter, and
  the comment in `12 §10.7` explaining why should survive into the code.
- **Keyed, not typed.** `find.byKey(const Key('flock.upgrade_row'))`, not
  `find.byType(ShedBanner)`. Keys are contracts (R59) and the reason this test could exist at step 5:
  `12 §10.7` says *"11 owns the widget's name, and a key is a contract this test can hold before that
  document lands."* A `byType` assertion also fails to notice a row built from a `Container`.
- **The text assertions catch what the keys cannot.** `find.textContaining('Unlock')`, `'€'` and `'£'`
  catch a price or an offer that reached the screen without the keyed widget — a hand-rolled row, a
  string in a header, a debug label. Keep all of them; they are cheap and they are the only thing that
  catches a leak through a route the keys do not name.
- **`FakePurchaseService`'s tripwire is the mechanical half, and pumping is what fires it.** `12 §4.2`:
  *"any store call during a `pumpApp` of a shed screen"* throws — and this is *"the only place it can be
  caught mechanically."* It matters more after **T04** than it did before, because T04 put
  `entitlementRepositoryProvider` on `flockRepositoryProvider`'s chain and therefore
  `purchaseServiceProvider` transitively on the Quick Entry path. `pumpApp` wires the fake by default
  (`12 §5.1`); **do not pass a permissive double to make a test pass.**
- **Seven more screens render nothing, and they are worth a case each.** `11 §8` constraint 1 and
  `07 §19.2`: Ewe Card, Treatments, Reminders, Season Summary, Export and note search also carry no
  monetization surface — the affordance exists in exactly **two** places. Those seven are not shed
  screens, so their failure is not a 3am failure, but a row that appeared on the Export screen would
  contradict decision #86 in the loudest possible way: *"export is never gated."*
- **The at-cap boundary is read, never typed.** `kFreeEweCap` is 15 today. A test that writes `15` is a
  test that silently stops testing the boundary the day the number moves.
- **`restoreFixture` goes through the restore path** (decision #74), so every run of this file is also
  a run of the one code path that can lose five seasons. If it starts failing on the fixture rather
  than the assertion, read `04 §7` before you touch the JSON.
- **The restored fixture carries stale `over_free_cap` markers and that is correct.** `11 §8.1`:
  *"nothing reads `over_free_cap` when `unlocked = 1`"*, which is what makes a backup restored onto an
  unlocked phone harmless — the app does not rewrite the user's rows to tidy up its own bookkeeping.
  Assert that the markers survive an unlock-then-restore untouched rather than asserting they are
  cleaned.
- **The 3am path must be unchanged at the cap, and that is a tap-budget assertion, not a rendering
  one.** `CLAUDE.md`'s question — *"does the shepherd have to do anything new before the record
  exists? A tap, a wait, a decision, or a thing on screen that was not there before"* — is answered by
  re-running `tap_budget_test.dart` against the at-cap fixture at `unlocked: false` and getting the same
  numbers: **five taps plus the first tally stroke** to a committed lambing (critique **S4**'s 5 + 1
  split), one for a foster reassignment, two for a repeat treatment.
- **Nothing is greyed, blurred or disabled at the cap.** `11 §8.1`: on not paying, *"nothing is
  deleted, hidden, greyed out, blurred, teased or made read-only. Ever."* Assert it positively on at
  least one screen — a `Opacity`/`IgnorePointer`/`enabled: false` that appears only when locked is the
  shape of data ransom and no other test would see it.
- **The matrix count is derived, never remembered.** R58: 252 cells over 14 pumpable variants. If this
  task's fixture work changes a variant, the arithmetic follows the variant list. **Fix the layout,
  never the matrix** (`12 §6`).
- **Do not regenerate the fixtures here.** Critique change 12 gives that to **N24**, after reminders and
  entitlements existed. If `flock_15_at_cap.json` is stale, say so in the commit message and route it;
  a fixture regenerated inside a test commit is a data change hiding in a test diff.

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/policy/no_money_on_a_shed_screen_test.dart` | **anchor** — `'no monetization widget renders on any of the five shed screens at any entitlement state or hour'` | Five screens × {locked, unlocked} × {14:00, 23:30}, at 99 ewes |
| | `'the shed-screen map's key set is exactly the five RouteNames constants'` | A sixth shed screen must make somebody decide |
| | `'no ShedBanner renders on Flock or Settings between 22:00 and 05:59'` | 06's wider rule. **The clock moves; the entitlement does not** |
| | `'both rows render at 21:59 and neither renders at 22:00'` | The boundary, inclusive side |
| | `'neither row renders at 05:59 and both render at 06:00'` | The boundary, exclusive side |
| | `'the seven non-shed, non-surface screens render nothing monetization-related at any state'` | Ewe Card, Treatments, Reminders, Season Summary, Export, note search — and Export loudest, because decision #86 |
| | `'no store call reaches FakePurchaseService during any shed-screen pump'` | The tripwire, asserted rather than relied on — `expect(fake.calls, isEmpty)` after each pump |
| | **`@Tags(['uk-zone'])`** — `'both instants of the repeated 01:00–01:59 hour suppress both rows'` | The hour axis includes the one hour that occurs twice. Build both candidate `Instant`s for `2026-10-25T01:30`, pump Flock and Settings under each, and assert `findsNothing` for both. Carry the `setUpAll` offset guard so the file fails loudly under the wrong `TZ` |
| `test/features/free_tier_test.dart` | `'at the cap, ewe #16 from the Flock screen is refused and ewe #16 from Quick Entry commits'` | The two contexts against the fixture, in one case so the contrast is visible |
| | `'the refused write inserts nothing and the committed one carries over_free_cap = 1'` | Read both back |
| | `'nothing on any screen is greyed, blurred, disabled or hidden at the cap'` | `11 §8.1`, positively |
| | `'stale over_free_cap markers from a restored backup survive an unlock untouched'` | The app does not rewrite the user's rows |
| `test/features/tap_budget_test.dart` | `'five taps plus the first tally stroke to a committed lambing, at the cap, locked'` | The 3am path unchanged — no extra tap, no extra wait, no extra decision |
| | `'one tap for a foster reassignment and two for a repeat treatment, at the cap, locked'` | Decision #120's other two budgets, at the boundary |

**Two assertions that stay where they are.** `test/domain/free_tier_test.dart` (N06-T10) holds
`FreeTierPolicy`'s pure arithmetic and `test/policy/cap_never_blocks_live_entry_test.dart` (T04) holds
the grid. Neither is duplicated here: this task is about what a **screen** renders, and a second copy
of a policy property at the widget tier is a second answer waiting to disagree.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **One word matters more than usual in this file.** `CONVENTIONS §5.1`: it is a **shed screen**, never
> a *"3am screen"*, in code, in test names and in the commit message. The five are named as a set in
> five documents and the set is closed; a test that invents a sixth name for it is a test the next
> reader will not find.

## 7. Definition of Done

- [ ] `'no monetization widget renders on any of the five shed screens at any entitlement state or hour'` passes, and was seen to fail first for the stated reason
- [ ] all five shed screens covered
- [ ] every entitlement state and both quiet-hour boundaries covered
- [ ] the at-cap fixture drives the cap tests
- [ ] the 3am path is unchanged at the cap — no extra tap, no extra wait, no extra decision
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/no_money_on_a_shed_screen_test.dart
fvm flutter test test/features/free_tier_test.dart
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
ls test/policy/no_money* test/features/no_monetization* 2>/dev/null    # exactly one of the two
git diff --stat -- lib/ test/fixtures/                                 # nothing
grep -rn "3am screen" test/ lib/                                       # nothing — it is a shed screen
grep -rn "15\b" test/features/free_tier_test.dart                      # the cap is read, never typed
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): no money on any shed screen, at any state or hour`

> **This is the last commit on the branch.** After it, run `/shed-code-review` once more over the
> **whole** branch in `00-README §10`'s irreversibility order before the PR opens — the epic file lists
> that order for N30 — and answer the five §12 questions in the PR body.
