# N06-T10 — `free_tier.dart` — the cap decision, eleven epics before it is wired

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 10 of 11 |
| **Depends on** | N06-T09 |
| **Commit** | one commit · `feat(domain): free_tier.dart — the cap decision as a pure policy` |

## 1. Why this task exists

`EntryContext`, `CapDecision`, `RefusalReason`, `FreeTierPolicy.decide` and
`isQuietHours`. The policy exists **now** so that `createEwe` can consult it from its first commit in
N14-T01 — decision #91 makes `EntryContext.liveEntry` structurally incapable of returning
`BlockedByCap`, which is a parameter shape, not a later addition. This closes critique defect S5.

The original plan wired `FreeTierPolicy` in E27, sixteen epics after the verb it gates, while
`CONVENTIONS` §2.13 already fixes the signature as
`createEwe({required String tag, required EntryContext context})`. A parameter that changes a
function's *reachable return set* cannot be retrofitted; it is either there in the first commit or
the first commit is wrong.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | §2, §7.1, §7.2, §7.3, §7.4, §12.2 | the two constants, the complete type, the post-write count contract, the two consequences stated rather than discovered, and the test files |
| `docs/engineering/CONVENTIONS.md` | §2.10, §2.13, R69 | the member names, `FreeTierPolicy.decide`'s parameter list, and that the repository maps `BlockedByCap(reason)` → `WriteRefused(reason)` |
| `docs/research/00-tech-decisions.md` | §2 #90, #91, §7.0 ruling 8 | nothing on a shed screen branches on `unlocked`; the check lives in the repository with the context as a parameter; season-primary, ewe cap secondary |
| `docs/engineering/05-domain-correctness.md` | §1.2 D3 | `package:clock` is banned here, which is *why* `decide` takes `now` |
| `epics/00-PLAN-CRITIQUE.md` | S5 | the defect this task closes |
| `shed-book-spec.md` | §5, §7.1, §14 | zero interruptions; never block an entry; one-time unlock with a small free tier |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the free tier, the cap and the refusal vocabulary are its subject |
| `shed-domain` | the policy is a pure function over context and counts |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/free_tier_test.dart`
- **Test** — `'isQuietHours is true at 23:00 and 05:59 local and decide never refuses EntryContext.liveEntry'`
- **Why it is red today** — no policy exists, so `createEwe` in N14 would be written without the `EntryContext` parameter and would have to be re-opened in N30.

```dart
expect(isQuietHours(at(23, 00)), isTrue);
expect(isQuietHours(at(05, 59)), isTrue);
expect(isQuietHours(at(06, 00)), isFalse);   // both boundaries, both directions
expect(isQuietHours(at(21, 59)), isFalse);
expect(
  const FreeTierPolicy().decide(
      context: EntryContext.liveEntry, now: at(14, 00), unlocked: false,
      ewesInCurrentSeason: 99, seasonCount: 5),
  isA<Allow>(),
);
```

```bash
fvm flutter test test/domain/free_tier_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the pure policy, the quiet-hours window (22:00–06:00), and the season-primary rule; no
store, no entitlement source, no UI.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only. Step 1 is skipped: the cap is **not** a schema `CHECK` — a `CHECK` would
fire on a paying user mid-lambing and there would be no way to tell it apart from corruption. Step 3
is N14-T01's (`createEwe`) and N29's (`startSeason`); step 6 is N30's two static rows.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/free_tier.dart` | **New.** `kFreeEweCap` · `kFreeSeasonCount` · `EntryContext` · `CapDecision` + `Allow` + `BlockedByCap` · `RefusalReason` · `isQuietHours` · `FreeTierPolicy`. The file is 01's, the members are 11's (R69) |
| 2 | `test/domain/free_tier_test.dart` | **New.** The anchor and the four boundaries |
| 3 | `test/policy/cap_never_blocks_live_entry_test.dart` | **New.** The whole input grid, per `11` §12.2 |

`test/policy/quiet_window_never_solicits_test.dart` and
`test/policy/entitlement_is_never_revoked_test.dart` are also `11` §12.2's, and both have a widget or
a repository half that cannot exist yet. They belong to N30. Do not create empty shells for them.

### 5.2 The signatures

`11-monetization-and-store.md` §7.2 prints the file complete, with its doc comments, and it is copied
from there. The four things a reader gets wrong from memory:

```dart
/// The free tier's two limits. Constants, not constructor parameters: an
/// injectable cap lets a test lower it to 3 and hide an off-by-one that
/// production would then ship. The at-cap fixture
/// (test/fixtures/flock_15_at_cap.json) is how tests reach the boundary.
const int kFreeEweCap = 15;
const int kFreeSeasonCount = 1;

enum EntryContext { liveEntry, calm }
enum RefusalReason { secondSeason, eweCap }

sealed class CapDecision { const CapDecision(); }
final class Allow extends CapDecision {
  const Allow({required this.overFreeCap});
  final bool overFreeCap;   // the row is real; the flag rides on it and clears on unlock
}
final class BlockedByCap extends CapDecision {
  const BlockedByCap(this.reason);
  final RefusalReason reason;
}

/// 22:00–06:00 local wall time. ONE predicate, so the policy and the upgrade
/// row cannot disagree about when the app goes quiet.
bool isQuietHours(Instant now) {
  final h = now.local.hour;
  return h >= 22 || h < 6;
}

final class FreeTierPolicy {
  const FreeTierPolicy();

  /// `ewesInCurrentSeason` and `seasonCount` are the counts **as they would be
  /// after the write**. That is the contract, and getting it wrong is an
  /// off-by-one that either refuses ewe #15 or lets #16 through.
  CapDecision decide({
    required EntryContext context,
    required Instant now,
    required bool unlocked,
    required int ewesInCurrentSeason,
    required int seasonCount,
  });
}
```

The body's five statements are in a fixed order and the order **is** the policy:

1. compute `overSeason`, `overEwes`, `over`;
2. `if (unlocked) return const Allow(overFreeCap: false);`
3. `if (context == EntryContext.liveEntry) return Allow(overFreeCap: over);` — spec §7.1, and the
   arm the whole object exists for;
4. `if (isQuietHours(now)) return Allow(overFreeCap: over);` — the owner's ruling;
5. season-primary: `overSeason` first, then `overEwes`, then `Allow(overFreeCap: false)`.

Read steps 2–4 before the gates: **`EntryContext.liveEntry` is structurally incapable of returning
`BlockedByCap`.** Not by convention, not by a review rule — the function cannot reach it on that
path. That is what makes *"the cap never fires at 03:20"* a property rather than a promise.

### 5.3 The details that are easy to get wrong

- **The counts are post-write, and nothing in the signature says so.** `createEwe` passes
  `await _countEwesInCurrentSeason() + 1`. Pass the pre-write count and ewe #16 slips through; add
  the `+1` in *both* places and ewe #15 is refused. The doc comment is the only guard rail — do not
  delete it, and put the contract in the test names.
- **`kFreeEweCap` and `kFreeSeasonCount` are `const`, not parameters.** Making the cap injectable so a
  test can set it to 3 is the obvious ergonomic improvement and it hides exactly the off-by-one above:
  the test passes at 3 and production ships at 15. `test/fixtures/flock_15_at_cap.json` (N24) is how
  tests reach the boundary honestly.
- **`isQuietHours` is one predicate with two call sites.** The policy and N30's upgrade row both read
  it. Two implementations of "when the app goes quiet" is one too many, and the second one is always
  the one that says 23:00–05:00.
- **The quiet window and the ambiguous DST hour are deliberately compatible.** UK/Ireland's ambiguous
  hour is 01:00–01:59 (§7.0 ruling 3), which sits inside 22:00–06:00 under **both** readings of that
  hour — so the one place in the app where a local hour is genuinely ambiguous is a place where the
  ambiguity cannot change the answer. Write that in the comment; it is the reason no `uk-zone` case is
  needed for this file.
- **A calm gate inside the quiet window is forgiven, permanently — not deferred.** `isQuietHours`
  returns `Allow`, `startSeason` commits with `over_free_cap = 1`, and the app never revokes and never
  re-refuses. A user who taps "start a new season" at 22:30 gets their second season for nothing and
  keeps it. **Do not "fix" it** by deferring the refusal to the morning: a refusal detached from the
  tap that caused it is worse than no refusal, and it would fire while the user is somewhere else in
  the app.
- **Season-primary means: if both are over, the reason is `secondSeason`.** The order of the last two
  `if`s is the ruling. A restored three-season backup therefore refuses `createEwe(context: calm)`
  with `secondSeason`, which is the honest shape of *"the cap is never applied retroactively"* — it
  constrains the next write, never the existing records.
- **Nothing in this file knows what a purchase is.** `unlocked` is a `bool` parameter. No
  `PurchaseService`, no `EntitlementRepository`, no `ProductDetails`, no price. `layer.in_app_purchase`
  fires on any of those tokens anywhere outside `lib/data/purchase_service.dart`, and `net.*` fires on
  anything that would reach a store.
- **`now` is a parameter because `package:clock` is banned in `lib/domain/`** (D3, R24). The
  repository calls `appNow()` in `lib/data/` and passes the result in, inside the **same transaction**
  as the insert, so the count cannot move between the decision and the write.
- **The cap is not a UI check.** A UI check is one refactor away from being bypassed and cannot be
  tested without pumping a widget. `createEwe` and `startSeason` are the only two gated verbs;
  `beginLambing` and `addLamb` are never gated, at any entitlement state.
- **Export is never gated and nothing safety-related is ever gated** (`11` §7.1). Export is the only
  backup mechanism in an app with no cloud, and a withdrawal period is §12.1 machinery. If you find a
  `decide` call anywhere near either, something has gone badly wrong.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/domain/free_tier_test.dart` | **anchor:** `'isQuietHours is true at 23:00 and 05:59 local and decide never refuses EntryContext.liveEntry'` · the four `isQuietHours` boundaries — 21:59 false, 22:00 true, 05:59 true, 06:00 false · `'ewe #15 is allowed and ewe #16 is refused in calm'` — the post-write counts, spelled as 15 and 16 · `'season #1 is allowed and season #2 is refused in calm'` · `'both over → the reason is secondSeason, not eweCap'` · `'unlocked short-circuits everything and returns Allow(overFreeCap: false)'` · `'a calm gate at 22:30 returns Allow(overFreeCap: true), and the flag is what N30 reads'` |
| `test/policy/cap_never_blocks_live_entry_test.dart` | `'decide(context: liveEntry, …) never returns BlockedByCap across the whole grid'` — `unlocked` × ewe counts 0…30 × season counts 1…5 × **all 24 local hours**, exactly as `11` §12.2 specifies. That is 2 × 31 × 5 × 24 = 7 440 cases and it runs in milliseconds, because the function is pure |

**No `uk-zone` case, and the reason is worth stating in the test file.** The only local-hour read is
`isQuietHours`, and the ambiguous 01:00–01:59 hour falls inside the quiet window under both of its
two possible instants, so no DST reading can change a decision. The 24-hour sweep in the grid test
covers every hour anyway.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. *The free tier* and *the cap*, never trial, freemium or paywall; *unlock*, never purchase or subscribe.
- **The 3am test** — spec §5's *"zero interruptions"* is a shipping gate, and this file is where it is held.

## 7. Definition of Done

- [ ] `'isQuietHours is true at 23:00 and 05:59 local and decide never refuses EntryContext.liveEntry'` passes, and was seen to fail first for the stated reason
- [ ] `liveEntry` cannot return `BlockedByCap` — it is not in the return type's reachable set
- [ ] quiet hours are 22:00–06:00 local and the boundaries are tested
- [ ] the free tier is season-primary, per the owner's ruling
- [ ] nothing in this file knows what a purchase is
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/free_tier_test.dart
fvm flutter test test/policy/cap_never_blocks_live_entry_test.dart
grep -rn "in_app_purchase\|ProductDetails\|entitlement" lib/domain/   # expect: nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): free_tier.dart — the cap decision as a pure policy`
