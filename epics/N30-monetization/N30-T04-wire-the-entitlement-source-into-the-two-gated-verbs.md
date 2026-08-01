# N30-T04 — Wire the entitlement source into the two gated verbs

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 4 of 8 |
| **Depends on** | N30-T03 · N06-T10 · N14-T01 · N29-T05 |
| **Commit** | one commit · `feat(monetization): supply the entitlement source to the two gated verbs` |

## 1. Why this task exists

`FreeTierPolicy` has been consulted by `createEwe` since N14-T01 and by `startSeason` since
N29-T05; what has been missing is the **entitlement source**. This task supplies it — and that is all,
because the policy shape was settled in N06-T10. Critique defect S5's other half.

That is the whole scope, and it is worth being blunt about how small it is: **no signature changes, no
new verb, no new type, no new policy arm.** `createEwe({required String tag, required EntryContext
context})` and `startSeason({required String label, required LocalDate startDate, required EntryContext
context})` are fixed by `CONVENTIONS §2.13` and stay fixed. What changes is that
`FreeTierPolicy.decide` finally receives a real `unlocked` instead of the placeholder N14-T01 had to
pass, and that two repository constructors gain one collaborator each.

The original plan wired the whole policy in E27, sixteen epics after the verb it gates. The critique's
ruling (**S5**) split it: the policy landed in step 2 because `EntryContext` changes `createEwe`'s
*reachable return set* and could not be retrofitted; the entitlement landed here because it genuinely
needs the store seam.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§7.2** (`FreeTierPolicy` printed in full — `kFreeEweCap = 15`, `kFreeSeasonCount = 1`, `isQuietHours`, `decide`'s five parameters and the exact order of its `return`s) · **§7.3** (`createEwe` printed with its transaction, and `startSeason`'s signature; the five rules that fall out; the two ARB messages) · **§7.4** (the two consequences stated rather than discovered) · §7.1 (what is capped and what never is) · §8.1 (`over_free_cap` is bookkeeping, never a warning) · §4.3 (`EntitlementRepository.read()`) · §12.2 (`cap_never_blocks_live_entry_test.dart` and `free_tier_test.dart`) | the call sites, the counts and the two consequences |
| `docs/engineering/CONVENTIONS.md` | **§2.10** (`EntryContext`, `CapDecision`, `Allow`, `BlockedByCap`, `RefusalReason`, `FreeTierPolicy.decide`'s parameter list) · **§2.13** (`createEwe`'s and `startSeason`'s exact signatures; `FlockRepository` owns `ewes`, `SeasonRepository` owns `seasons`) · §2.4 (`WriteOutcome`, `WriteRefused(reason)`) · §3.1 (`entitlementRepositoryProvider`, `freeTierPolicyProvider`, `flockRepositoryProvider`, `seasonRepositoryProvider`) · §1.1 layer rules 3, 4, 8 · **R23/R24** (`appNow()` in `lib/data/`, never in `lib/domain/`) · **R69** (the repository maps `BlockedByCap(reason)` → `WriteRefused(reason)`) · R33 | **BINDING**: the signatures that must not move |
| `docs/research/00-tech-decisions.md` | §2 **#91** (one policy object consulted by the repository, `EntryContext` explicit; the cap is **not** a schema `CHECK` and **not** a UI check) · **#90** (nothing on the shed path branches on `unlocked`) · #13 (writes return `WriteOutcome`) · #86 (export never gated) · §7.0 ruling 8 (season-primary, ewe cap secondary) · §7.1 open question 17 | the placement of the check |
| `docs/engineering/03-data-model-and-schema.md` | §5.1 (`Seasons.over_free_cap`) · §5.2 (`Ewes.over_free_cap`, and the active-only partial unique index on `tag`) · §5.13 (`Entitlements`) · §5.14 (who writes what) | the two flag columns |
| `docs/engineering/01-architecture.md` | §4.1–§4.4 (repositories take `AppDatabase` and collaborators, never a `Clock`; one `appNow()` and one `db.transaction` per mutation) · §4.3 (`WriteRefused` reaches the screen through `WriteDone`) · §6.3 (the banned `main()` lines) | the transaction shape |
| `docs/engineering/07-screens.md` | §19.1 (season-primary) · §19.3 (the two hard rules) · §19.4 (what the cap never does) · §5.4 (Quick Entry's write path) · §14.3 row 4 (Settings ▸ Season, calm-gated) | the two calling contexts |
| `docs/engineering/12-testing.md` | §3.1, §3.3 (`NativeDatabase.memory()`, never a mock) · **§4.2** (`FakePurchaseService`'s tripwire — *"any store call during a `pumpApp` of a shed screen"*) · §5.3 (`setEntitlement`, `setEwesInCurrentSeason`, `restoreFixture`) · §10.7 (the two `FreeTierPolicy` properties that live in `test/domain/`) | the tier and the tripwire |
| `epics/00-PLAN-CRITIQUE.md` | **S5** (the defect this closes) · §9 change 8 · **§11.3** (this task's `[audit]` row: *"`test/policy/cap_never_blocks_live_entry_test.dart` — the doc-named file; `FreeTierPolicy.decide`'s pure arithmetic stays in `test/domain/free_tier_test.dart`"*) | which file holds which assertion |
| `docs/engineering/05-domain-correctness.md` | §1.2 D3 (`package:clock` is banned in `lib/domain/`, which is *why* `decide` takes `now`) · §2 (`Instant`, `LocalDate`) | the parameter that looks redundant and is not |
| `shed-book-spec.md` | **§7.1** (*"never block an entry to make the user go and set something up first"*) · §7.7 (the retention thesis) · §7.9 (export is a safety feature) · §14 · §5 | the arm that is the reason the object exists |
| `CLAUDE.md` | rule 4 (every write commits immediately) · the banned words | the write shape |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the cap, the entitlement and the two gated verbs |
| `shed-write-path` | the refusal maps to `WriteRefused`, not to an exception |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/free_tier_test.dart`
- **Test** — `'startSeason returns WriteRefused at the cap and createEwe on the live-entry path does not'`
- **Why it is red today** — the policy always sees an unentitled state because nothing supplies the real one.

```bash
fvm flutter test test/features/free_tier_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it fails for the *supply* rather than for the *cap*. Set the entitlement to
**unlocked** and assert both verbs return `WriteCommitted` at 400 ewes and three seasons — that is the
half that is red today, because a hard-coded `unlocked: false` refuses a paying user and no existing
test catches it. Then set it back to locked and assert the pair in the test's name. Both halves in one
test, because the property is *"the policy sees the truth"* and either half alone can pass for the
wrong reason.

**Green.** The minimum code that passes, and nothing beyond it — the entitlement provider feeding the policy, and the two verbs' behaviour asserted at the
cap.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, no domain step, no UI step, no ARB step.** The columns were frozen at N07-T08, the
policy is N06-T10's, the refusal copy is `11 §7.3`'s two ARB messages and the *rendering* of a refusal
is **T05**'s. This task is §8 step 3 (the write path), step 4 (wiring) and step 7 (tests). Say so in
the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** The constructor gains `EntitlementRepository`; `createEwe`'s body replaces N14-T01's placeholder with `final unlocked = (await _entitlements.read()).unlocked;` **inside** the existing transaction. The signature does not move |
| 2 | `lib/data/season_repository.dart` | **Edit.** The same, in `startSeason`. The season count is the one that is post-write here |
| 3 | `lib/data/providers.dart` | **Edit.** `flockRepositoryProvider` and `seasonRepositoryProvider` now `await ref.watch(entitlementRepositoryProvider.future)` and pass it in. Both stay `FutureProvider`, both stay keepAlive |
| 4 | `test/features/free_tier_test.dart` | **New.** The anchor and the widget-tier cases in §5.4 |
| 5 | `test/policy/cap_never_blocks_live_entry_test.dart` | **New.** `11 §12.2`'s file and the critique's `[audit]` row for this task: the whole input grid, named for the property |
| 6 | `test/data/flock_repository_test.dart` | **Edit.** The boundary cases at ewe #15 and #16, both contexts |
| 7 | `test/data/season_repository_test.dart` | **Edit.** Season #2 refused calm, allowed at 22:30, and the restored-multi-season case |

**Not touched, and each absence is a check:** `lib/domain/free_tier.dart` (N06-T10 settled it; if this
task wants to change `decide`, it has found a defect in the policy and that is a `11` conversation),
`lib/features/**` (the refusal's pixels are T05's), `lib/core/db/**` and `drift_schemas/` (no column
moves), `lib/l10n/app_en.arb` (T05 authors the two `RefusalReason` messages, beside the row that
renders them).

### 5.2 The signatures

Nothing here is new. The point of printing them is that **none of them changes**, and the diff should
show that:

```dart
// lib/data/flock_repository.dart — CONVENTIONS §2.13, unchanged since N14-T01.
Future<WriteOutcome> createEwe({required String tag, required EntryContext context});

// lib/data/season_repository.dart — CONVENTIONS §2.13, unchanged since N29-T05.
Future<WriteOutcome> startSeason({
  required String label,
  required LocalDate startDate,
  required EntryContext context,
});
```

What changes is the body, and `11 §7.3` prints it. Note where each count comes from:

```dart
Future<WriteOutcome> createEwe({required String tag, required EntryContext context}) =>
    _db.transaction(() async {
      final unlocked = (await _entitlements.read()).unlocked;    // <- THIS TASK
      final decision = _policy.decide(
        context: context,
        now: appNow(),                                           // R24: read here, never in domain/
        unlocked: unlocked,
        ewesInCurrentSeason: await _countEwesInCurrentSeason() + 1,   // post-write
        seasonCount: await _countSeasons(),                          // unchanged by this verb
      );
      return switch (decision) {
        BlockedByCap(:final reason) => WriteRefused(reason),
        Allow(:final overFreeCap) => WriteCommitted(
            insertedId: await _insertEwe(tag: tag, overFreeCap: overFreeCap),
          ),
      };
    });
```

`startSeason` is the mirror image, and the asymmetry is the thing to get right: **`seasonCount` is the
post-write count there (`+ 1`) and `ewesInCurrentSeason` is whatever the new season starts with (zero,
or the count as it will be after the write).** Getting the `+ 1` on the wrong parameter is an off-by-one
that either refuses the first season or lets the second through.

And the policy's own `return` order, which is what makes the whole thing a property rather than a
promise (`11 §7.2`):

```dart
if (unlocked) return const Allow(overFreeCap: false);
if (context == EntryContext.liveEntry) return Allow(overFreeCap: over);   // spec §7.1
if (isQuietHours(now)) return Allow(overFreeCap: over);                   // owner's ruling
if (overSeason) return const BlockedByCap(RefusalReason.secondSeason);    // season-primary
if (overEwes) return const BlockedByCap(RefusalReason.eweCap);
return const Allow(overFreeCap: false);
```

The provider wiring:

```dart
// lib/data/providers.dart
final flockRepositoryProvider = FutureProvider<FlockRepository>((ref) async => FlockRepository(
      await ref.watch(databaseProvider.future),
      await ref.watch(entitlementRepositoryProvider.future),   // <- THIS TASK
      ref.watch(freeTierPolicyProvider),
    ));                                                        // keepAlive
```

### 5.3 The details that are easy to get wrong

- 🚩 **This is the commit that puts `purchaseServiceProvider` on the Quick Entry path for the first
  time.** `flockRepositoryProvider` → `entitlementRepositoryProvider` → `purchaseServiceProvider`, and
  Quick Entry's create-on-the-fly reaches `createEwe`. Decision #90 survives it for exactly one reason:
  **constructing `PurchaseService` is inert; `attach()` is what initialises the Android billing
  client** (`11 §5`). Nothing in this chain calls `attach()`, `isAvailable()`, `queryUnlockPrice()`,
  `buyUnlock()` or `restore()`. `read()` is a SQLite read of one row and nothing more.
  `FakePurchaseService`'s tripwire — *"any store call during a `pumpApp` of a shed screen"* — is the
  only place this is catchable mechanically, and T08 is where it gets pumped. If you find yourself
  wanting `EntitlementRepository.attach()` in a repository constructor, stop: that is a billing client
  initialising from a lambing at 03:20.
- **The counts are the counts as they would be *after* the write.** `11 §7.2`'s doc comment says so and
  calls the alternative *"an off-by-one that either refuses ewe #15 or lets #16 through."* `kFreeEweCap`
  is **15**, and `decide` tests `ewesInCurrentSeason > kFreeEweCap` — so ewe #15 must arrive as `15`
  (allowed) and ewe #16 as `16` (refused). Write the `+ 1` where the count is *changed by this verb*,
  and nowhere else.
- **The decision and the insert are in one transaction.** If they are not, the count can move between
  them, and the two writers who can move it are the same user in two screens and the restore path.
  There is no lock, there is a transaction.
- **`appNow()` is read in `lib/data/`, never in `lib/domain/`.** `package:clock` is banned in the domain
  (R24), which is exactly *why* `decide` takes `now` as a parameter. A reviewer meeting the parameter
  and thinking *"the policy could just read the clock"* has found the reason it cannot.
- **The cap is not a schema `CHECK`.** A `CHECK` would fire on a paying user mid-lambing and there would
  be no way to tell it apart from corruption (#91).
- **The cap is not a UI check.** A UI check is one refactor from being bypassed and cannot be tested
  without pumping a widget (#91, critique **D7**).
- **There are exactly two gated verbs and there is no third.** `beginLambing` and `addLamb` throw and
  return ids; they are **never** gated, at any entitlement state (R32). Nor are treatments, withdrawal
  periods, clear dates, the medicine book, fostering, pen occupancy, reminders, note search or
  **export** — decision #86 makes export ungated in every state, because paywalling the only backup
  mechanism in an app with no cloud is a data-hostage pattern that contradicts the product's own selling
  point.
- **`BlockedByCap` becomes `WriteRefused(reason)`, never a thrown exception.** Decision #13: writes
  return a sealed `WriteOutcome`. `WriteRefused` reaches the screen through `WriteDone`, and the screen
  — not the repository — calls `showCapRow(context, reason)`. A `throw CapExceeded()` here reddens
  nothing at compile time and produces a `WriteFailed` on screen with the wrong copy and an error
  haptic.
- **Season-primary: if both are over, the reason is `secondSeason`.** The `return` order encodes the
  owner's ruling and a reordering is a product change.
- **A calm gate that lands inside the quiet window is forgiven permanently, and it is not a bug.**
  `isQuietHours` returns `Allow`, the row commits with `over_free_cap = 1`, and rule 1 means the app
  never revokes and never re-refuses. A user who taps *"start a new season"* at 22:30 gets it for
  nothing and keeps it. `11 §7.4`: **do not "fix" it** by deferring the refusal to the morning — a
  refusal detached from the tap that caused it is worse than no refusal, and it would fire while the
  user is somewhere else in the app. N29-T05 already asserts this; do not delete or invert that case.
- **A restored multi-season backup closes both calm gates at once.** `_countSeasons()` on a restored
  three-season file is `3 > kFreeSeasonCount`, so in the free tier `createEwe(context: calm)` returns
  `BlockedByCap(secondSeason)` — the season is the reason — and so does `startSeason`. Everything else
  still works: every restored ewe is readable, editable, searchable and **exportable**, every live-entry
  write commits, and **no row is touched**. That is the honest shape of *"the cap is never applied
  retroactively"*: it constrains the *next* write, never the existing records.
- **`over_free_cap` is not a warning.** No `WarningCode`, no badge, no colour, never in the §12.4
  contradiction machinery. It is bookkeeping. And `lib/data/` may not import `lib/domain/validation/` at
  all (layer rule, R53), so the repository is structurally incapable of producing one anyway.
- **The two `RefusalReason` messages carry the cap as a placeholder**, so the number is never typed
  twice: *"The free version covers {count} ewes in a season. Unlock to add more."* T05 authors them;
  this task must not hard-code **15** into a test expectation string either — read `kFreeEweCap`.

### 5.4 The full test set

The split matters, and the critique's `[audit]` row for this task fixes it: **the pure arithmetic stays
in `test/domain/free_tier_test.dart`** (N06-T10's file, already green), **the grid property lives in
`test/policy/cap_never_blocks_live_entry_test.dart`** (the doc-named file), and the repository behaviour
lives in the two `test/data/` files. This task's anchor sits at the widget tier because it asserts what
a *screen* gets back from a *verb* with a real entitlement behind it.

| File | Case | What it holds |
|---|---|---|
| `test/features/free_tier_test.dart` | **anchor** — `'startSeason returns WriteRefused at the cap and createEwe on the live-entry path does not'` | Both halves of §4, including the unlocked half that is red today |
| | `'an unlocked entitlement short-circuits both gates at 400 ewes and three seasons'` | The supply, from the permissive side |
| | `'the refusal arrives as WriteDone(WriteRefused) and never as a thrown exception'` | Decision #13, at the boundary the screen sees |
| `test/policy/cap_never_blocks_live_entry_test.dart` | `'decide never returns BlockedByCap for EntryContext.liveEntry'` | The whole grid: `unlocked` ∈ {true, false} × ewe counts 0…30 × season counts 1…5 × all 24 local hours = **7,440** decisions. The `reason:` string names the ewe count and the hour so a failure reads as a coordinate |
| | `'createEwe with EntryContext.liveEntry commits at 400 ewes and three seasons, locked'` | The same property one layer up, through the repository, so a future refactor that adds a guard *around* `decide` is caught |
| `test/data/flock_repository_test.dart` | `'ewe #15 is allowed in the calm context and ewe #16 is refused'` | The boundary, from `kFreeEweCap`, never from a literal 15 |
| | `'ewe #16 commits on the live-entry path with over_free_cap = 1'` | The flagged row is a real row: read it back and assert its `tag`, `uid` and `status` |
| | `'a refusal inserts nothing'` | The transaction rolled back, and `ewe_touches` gained no row either |
| | `'createEwe(calm) on a restored three-season file refuses with secondSeason, not eweCap'` | Season-primary, and the restored-backup consequence |
| `test/data/season_repository_test.dart` | `'season #1 is allowed and season #2 is refused in the calm context'` | `kFreeSeasonCount` |
| | `'season #2 at 22:30 commits with over_free_cap = 1 and is never re-refused afterwards'` | `11 §7.4`'s first consequence, permanent forgiveness |
| | `'the post-write season count is seasonCount + 1 and the ewe count is not'` | The asymmetry §5.2 names — assert the arguments `decide` actually received |
| **`@Tags(['uk-zone'])`**, in `test/data/season_repository_test.dart` | `'a calm startSeason at 01:30 on the clocks-back night is forgiven under both candidate instants'` | The repeated hour produces two `Instant`s one hour apart; both are inside 22:00–06:00 under either reading, so `decide` must return `Allow` for both. `11 §7.2`'s comment says this is the one place a local hour is genuinely ambiguous *and* the ambiguity cannot change the answer — assert it rather than trusting it. Carry the `setUpAll` offset guard so the file fails loudly under the wrong `TZ` |

**Do not duplicate `test/domain/free_tier_test.dart`.** N06-T10 already asserts the boundaries, the
quiet-hours predicate at 21:59 / 22:00 / 05:59 / 06:00, both-over → `secondSeason`, and the
`unlocked` short-circuit, as pure arithmetic with no database. A second copy at the data tier is a
second answer waiting to disagree.

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **The 3am non-negotiable is the one that binds hardest here**, even though this task ships no pixels.
> The question `00-README §2.2` says to ask of any change to Quick Entry — *does the shepherd have to do
> anything new before the record exists?* — has to be answered **no** by this commit, at every ewe count
> and every entitlement state. A tap, a wait, a decision, or a thing on screen that was not there
> before: none of them. That is what `EntryContext.liveEntry` structurally guarantees, and what T08
> pumps.

## 7. Definition of Done

- [ ] `'startSeason returns WriteRefused at the cap and createEwe on the live-entry path does not'` passes, and was seen to fail first for the stated reason
- [ ] exactly two gated verbs, unchanged in signature
- [ ] `liveEntry` still cannot be refused
- [ ] a refusal is a `WriteRefused` outcome, never a thrown exception
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/free_tier_test.dart
fvm flutter test test/policy/cap_never_blocks_live_entry_test.dart
fvm flutter test test/data/flock_repository_test.dart test/data/season_repository_test.dart
fvm flutter test test/domain/free_tier_test.dart          # N06-T10's, must stay green and unmodified
TZ=Europe/London fvm flutter test --tags uk-zone
git diff -- lib/data/flock_repository.dart | grep -n "createEwe"     # the signature line must be unchanged
git diff -- lib/data/season_repository.dart | grep -n "startSeason"  # ditto
git diff --stat -- lib/domain/free_tier.dart lib/features/ drift_schemas/   # nothing
grep -rn "decide(" lib/                                    # exactly two call sites
grep -rn "attach()" lib/data/flock_repository.dart lib/data/season_repository.dart   # nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(monetization): supply the entitlement source to the two gated verbs`
