# N14-T07 — Nothing about money renders on a shed screen

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 7 of 7 |
| **Depends on** | N14-T06 |
| **Commit** | one commit · `test(policy): nothing about money renders on Quick Entry` |

## 1. Why this task exists

Decision #90's widget test, sixteen epics before monetization exists: **no
monetization widget renders on Quick Entry at any entitlement state or hour**. It exists now so that
every screen built after it is built against it.

`00-README` §9 step 11 says monetization *"can be last precisely because nothing on the shed path
branches on `unlocked` — that is decision #90, and the widget test that holds it should exist from step
5."* This is step 5. A test written after the screens it constrains is a test that documents what
happened; written now, it is a test that decides what may happen.

The failure mode it prevents is a **paywall flash at 3am** — and spec §5's *"zero interruptions"* is
written as a shipping gate, not a preference: *"if a feature cannot be operated under these conditions,
it does not ship."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/11-monetization-and-store.md` | §4.1 (the entitlement row) · §4.4 (nothing on the 3am path reads it) · §7.2 (`isQuietHours`, and why the ambiguous hour cannot change the answer) · §8 constraints 1–4 · §8.1 (`over_free_cap` is bookkeeping, never a warning) | the five shed screens, the hour axis and the two places the affordance may exist |
| `docs/engineering/12-testing.md` | **§10.7 (the test, printed, including the 99-ewe rationale)** · §5.1–§5.3 (`pumpApp`, `setEntitlement`, `setEwesInCurrentSeason`) · §2.1 (installing time with `withClock`) | the shape of the test and the helpers it needs |
| `docs/engineering/06-design-system.md` | §12 constraints 1–3 (`ShedBanner` is the only monetization component; never on the five shed screens; never 22:00–06:00 **on any screen, at any ewe count**) | the wider of the two rules, which is the one that ships |
| `docs/engineering/CONVENTIONS.md` | §1 (the `test/` tree) · §4.5 (widget keys) · §5.1 (*shed screen*, never "3am screen" in code) · R57 | **BINDING**: the keys the test looks for, and the word for what it is testing |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 (this anchor, and its `[audit]` note on the file path) · §11.5 | where this file lives, and what N30-T08 does with it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the cap, the unlock and where they may never appear |
| `shed-testing` | the entitlement-state matrix and the hour axis |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/no_money_on_a_shed_screen_test.dart`
- **Test** — `'no monetization widget renders on Quick Entry at any entitlement state or hour'`
- **Why it is red today** — nothing holds decision #90, and the first upgrade row would land on the 3am screen.

```bash
fvm flutter test test/policy/no_money_on_a_shed_screen_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion into a grid rather than a single pump. Iterate the entitlement axis
(`unlocked: false` at 0, 15, 16 and **99** ewes; `unlocked: true` at 99) crossed with the hour axis
(21:59, 22:00, 05:59, 06:00, 03:20 and 01:30), and for each cell assert **five** negatives:
`find.byKey(const Key('flock.upgrade_row'))` findsNothing,
`find.byKey(const Key('settings.upgrade_row'))` findsNothing,
`find.textContaining('Unlock')` findsNothing, and no `£` or `€` anywhere in the tree. Keyed, not typed:
`11-monetization-and-store.md` owns the widget's name, and a key is a contract this test can hold
before that document's code lands.

**Green.** The minimum code that passes, and nothing beyond it — the test over every entitlement state and both sides of the quiet-hours boundary, with a
comment naming N30-T08 as where it extends to all five shed screens.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Tests only.** If a cell of the grid goes red, the fix is in T03 or T04, not here — the test is
allowed to be the thing that fails.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/no_money_on_a_shed_screen_test.dart` | **New.** The anchor and the grid. See the file-path note below before you create it |
| 2 | `test/support/seeds.dart` | **Edit.** Add `setEntitlement(db, unlocked: …)` and `setEwesInCurrentSeason(db, n)` — both are on `12 §5.3`'s closed list for `seeds.dart`, and this is the first task that needs either |
| 3 | `test/support/harness.dart` | **Edit, only if needed.** `atFixed()` is `12 §5.3`'s helper for installing a fixed instant; if N12-T05 did not land it, it lands here, because the hour axis is the point of this test |

**The file path carries a live conflict — read this before creating the file.** This task's anchor
names `test/policy/no_money_on_a_shed_screen_test.dart`. `CONVENTIONS` **R57** maps 07's three files to
`test/features/{overflow_matrix,tap_budget,no_monetization}_test.dart`, and
`00-PLAN-CRITIQUE §11.3` carries an `[audit]` row saying the same thing with its reason: *"R57 names
this file; it is a widget test, so it is `test/features/`, not `test/policy/`."* `12 §10.7` prints it
as `test/features/no_monetization_test.dart`, and **N30-T08 extends the same file** to all five shed
screens.

Three documents and the critique agree; only this task file dissents. Resolve it in the first five
minutes of the task, do not discover it in N30:

- **Recommended:** follow R57 — create `test/features/no_monetization_test.dart`, and update this task
  file's §4, §8 and its title line in the same commit so the anchor and the file agree.
- **If the anchor path is kept instead**, then N30-T08's *"the same file N14-T07 created, extended"*
  is false, and R57 must be amended to bless a second location. Do that explicitly, with a reason,
  rather than leaving two files that assert overlapping properties.

Either way, **one file, not two.** Two files asserting the same property is how one of them stops
being maintained.

### 5.2 The shape

`12 §10.7` prints the map this test iterates. Four of its five entries do not exist yet, and that is
the whole point of the comment N30-T08 will read:

```dart
// test/features/no_monetization_test.dart  (see the path note in §5.1)
//
// Decision #90. Today this map has ONE entry, because Quick Entry is the only
// shed screen that exists. N30-T08 grows it to five — Quick Entry, Lambing
// Entry, Lamb Card, Foster, Pen Board — and does not rewrite this file.
const shedScreens = <String, Widget Function()>{
  RouteNames.quickEntry: () => const QuickEntryScreen(),
};
```

The two axes, both of which must be crossed and neither of which is optional:

| Axis | Values | Why each value is there |
|---|---|---|
| Entitlement | locked at 0, 15, 16 and 99 ewes; unlocked at 99 | 15 is the cap boundary, 16 is one past it, and **99** is `12 §10.7`'s deliberate figure: *"the state where a paywall would be most tempting to render"* |
| Hour | 21:59, 22:00, 05:59, 06:00, 03:20, 01:30 | Both sides of both quiet-window boundaries, the 3am case the product is named for, and the ambiguous DST hour |

**The widget test that proves the quiet window sets the clock, not the entitlement** (`06 §12`
constraint 3, `11 §8` constraint 2). That sentence is the test's design: `withClock` moves the hour and
the entitlement stays wherever the cell put it.

### 5.3 The details that are easy to get wrong

- **Set the entitlement in the *database*, not by overriding a provider.** `entitlementProvider` and
  `entitlementRepositoryProvider` do not exist until N30-T02, and a test that overrides a provider that
  does not exist yet is a test written against a future. `setEntitlement(db, unlocked: false)` writes
  the singleton `entitlements` row — the one `seedFirstRun` seeded (`11 §4.1`) — and that is also
  exactly how the app reads it, so the test exercises the real mechanism.
- **`flock_15_at_cap.json` does not exist yet, and reaching for it is critique defect S3.** `12 §10.7`
  loads it through `restoreFixture`, but the fixture is written by `tool/seed.dart` **through the
  restore path** in N23, and it is regenerated again in N24-T08 once reminders and entitlements have
  writers. Until then this test uses `test/support/seeds.dart` helpers. **N23-T06 is the task that
  switches it**, and the comment naming that switch belongs in the harness, said once, or it is
  rediscovered per screen.
- **`setEwesInCurrentSeason(db, 99)` tops the season up; it does not replace the seed.** `12 §5.3`
  declares it precisely because the fixtures ship *at or under* the cap while decision #90's assertion
  is written at 99. Both numbers matter: at-cap is the boundary, 99 is the temptation.
- **The five shed screens are named in the file even though four do not exist.** *Quick Entry, Lambing
  Entry, Lamb Card, Foster, Pen Board.* Naming them now is what makes N30-T08 an extension rather than
  a rewrite, and it is what a reader of this file needs in order to know the rule is about a class of
  screens and not about one.
- **The quiet-window rule is wider than the shed-screen rule, and the wider one ships.** `06 §12`
  constraint 3: never between 22:00 and 06:00 **on any screen, at any ewe count** — the Settings row
  goes quiet as well as the Flock one. `07 §19.3`'s narrower wording adopts it. Assert the wide rule
  where you can, and say in a comment that the other four screens' cells arrive with N30-T08.
- **What the quiet window suppresses is soliciting, not selling** (`11 §8` constraint 2). Settings ▸
  Unlock is a settings section like any other: it exists at 23:00 and its buttons work at 23:00. Do not
  write an assertion that would forbid a user-initiated purchase at midnight — that is not the rule,
  and N30 would have to delete it.
- **`over_free_cap` must not render anywhere on this screen.** It is monetization bookkeeping, not a
  warning (`11 §8.1`): no `WarningCode`, no badge, no colour, no line in the receipt. T01 writes the
  column; this test is what stops it leaking into the 3am screen. Assert a row created over the cap
  looks identical to one created under it.
- **`purchaseServiceProvider` may not be watched here, and `lib/main.dart` / `lib/app.dart` may not
  reference it at all** (`CONVENTIONS §3.1`, the `launch.store_call` rule). Nothing in this epic
  should — assert it in source text so the rule is visible in a failing test and not only in the gate.
- **The currency assertions are two symbols, not one.** `£` and `€` — the territory question is open
  (`00-README` §5.2 item 4) and `copy.currency_literal` already bans a currency symbol followed by a
  digit under `lib/`. The price is never a literal anyway: `ProductDetails.price` from the store,
  always (`CONVENTIONS §5.4`).
- **This is a widget test even though the anchor path says `test/policy/`.** `12 §7.4` splits the tiers
  deliberately: `test/policy/` holds spec §12 assertions over source text and shape, `test/features/`
  holds anything that pumps a tree. It pumps a tree. See the path note in §5.1.
- **Do not assert on `EntryContext` here.** `FreeTierPolicy.decide`'s pure arithmetic — including
  *"liveEntry can never be blocked, at any flock size or season count"* — belongs to
  `test/domain/free_tier_test.dart` (N06-T10) and to
  `test/policy/cap_never_blocks_live_entry_test.dart` (N30-T04). This file asserts what *renders*.

### 5.4 The full test set

| Case | What it asserts |
|---|---|
| `'no monetization widget renders on Quick Entry at any entitlement state or hour'` | **The anchor.** The full grid: 5 entitlement cells × 6 hours, five negatives per cell |
| `'the 22:00 boundary is covered on both sides'` | 21:59 and 22:00, with the entitlement unchanged across the pair — the clock moves, not the state |
| `'the 06:00 boundary is covered on both sides'` | 05:59 and 06:00, same discipline |
| `'nothing renders at 03:20 with 99 ewes, locked'` | The named failure mode, as its own case, so a regression reads as itself in CI output |
| `'an unlocked user at 99 ewes sees no upgrade row either'` | The row is not a nag *or* a receipt; it does not exist on this screen in any state |
| `'a ewe created over the free cap renders identically to one created under it'` | `11 §8.1`. `over_free_cap` earns no badge, no colour and no line in the receipt |
| `'the word Unlock appears nowhere in the tree'` | Text, not keys — a hand-rolled row would not carry the key |
| `'no currency symbol appears in the tree'` | `£` and `€`, for the open-territory reason |
| `'Quick Entry never watches entitlementProvider or purchaseServiceProvider'` | Source text over `lib/features/quick_entry/`. `11 §4.4` is a structural claim, so assert it structurally |
| `'the five shed screens are named in this file and the four unbuilt ones are commented as N30-T08'` | Keeps the extension honest: N30-T08 adds rows, not a file |
| `'no dialog, modal or bottom sheet appears on this screen at any cell'` | `11 §8` constraint 3, and `ui.show_dialog` already fails the build on `showDialog(` outside the two allowlisted destructive files |

**The `uk-zone` group.** The hour axis is the time-shaped part, and 01:00–01:59 is the one hour the
region ruling makes ambiguous. Put it in a `group('DST', …, tags: 'uk-zone')` that asserts the ambient
zone **first and loudly**.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: nothing renders at 01:30 on the clocks-back night, at both instants of the repeated hour'` | `11 §7.2`: the ambiguous hour sits inside 22:00–06:00 under **both** readings, so *"the one place in the app where a local hour is genuinely ambiguous is a place where the ambiguity cannot change the answer."* Assert it rather than trusting the arithmetic |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The word is *shed screen*, never "3am screen" in code or in a key** (`CONVENTIONS §5.1`), and the
  word is *the cap* or *the free tier*, never "paywall", "trial" or "freemium".
- **3am — zero interruptions.** This test is that clause, made executable. Nothing monetization-related
  renders on the five shed screens at any entitlement state.

## 7. Definition of Done

- [ ] `'no monetization widget renders on Quick Entry at any entitlement state or hour'` passes, and was seen to fail first for the stated reason
- [ ] every entitlement state is pumped
- [ ] 22:00–06:00 is covered on both boundaries
- [ ] the test names the five shed screens and asserts the one that exists today
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **the file-path conflict in §5.1 is resolved in this commit** — one file, and R57, this task file and N30-T08 agree on which
- [ ] the entitlement is set in the database through `setEntitlement`, never by overriding a provider that does not exist yet
- [ ] `setEntitlement` and `setEwesInCurrentSeason` land in `test/support/seeds.dart`, not in this test file
- [ ] no `restoreFixture` call and no reference to `flock_15_at_cap.json`; a comment names N23-T06 as the switch
- [ ] the hour axis is driven by `withClock`, with the entitlement held constant across each boundary pair
- [ ] the 99-ewe cell exists and carries `12 §10.7`'s rationale as a comment
- [ ] a row created over the free cap renders identically to one created under it
- [ ] the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers 01:00–01:59
- [ ] this diff adds no file under `lib/`

## 8. Verification

```bash
fvm flutter test test/policy/no_money_on_a_shed_screen_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/features/quick_entry/ --include='*.dart'
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/main.dart lib/app.dart
grep -rn "restoreFixture\|flock_15_at_cap" test/policy/ test/features/ --include='*.dart'
# expect zero hits for all three
git diff --stat -- lib/            # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): nothing about money renders on Quick Entry`
