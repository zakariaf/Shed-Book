# N06-T07 — `rankTagMatches` and the pen-timing functions

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 7 of 11 |
| **Depends on** | N06-T06 |
| **Commit** | one commit · `feat(domain): rankTagMatches and the pen-timing functions` |

## 1. Why this task exists

The ranking behind spec §7.1's partial tag matching — typing `12` surfaces 12, then 128,
then 412 — and `timeSincePenned` / `isReadyToTurnOut`, both taking `now` as a **parameter** so the pen
board's ticker drives them rather than a hidden clock read.

Both are read at 03:20 by a cold thumb. `rankTagMatches` is called on **every keypad tap** and must
return inside the same frame, which is why it is synchronous, in memory, and holds no `await`. It is
also the reason spec §7.1's *"never block an entry to make the user go and set something up first"*
is achievable at all.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §9.1, §6 | the ranking body, the four score bands and the tie-break; why FTS5 cannot do it; `tag_digits` as a projection, never an identity |
| `docs/engineering/CONVENTIONS.md` | §2.14, R24, R26, R27, R63 | `TagIndexEntry`'s four fields, `rankTagMatches`'s and `timeSincePenned`'s exact signatures, and that `sincePenned` is a banned name |
| `docs/engineering/05-domain-correctness.md` | §1.2 D3, §2.8, §7.3 | `now` is a parameter because `package:clock` is banned in this layer; and the READY badge is the user's own threshold played back, never a clinical claim |
| `docs/engineering/07-screens.md` | §9.3, §9.6, §5.2, §3.3 | the pen-tile statuses, the READY legend naming the user's number, and the strip that consumes the ranking |
| `shed-book-spec.md` | §7.1, §7.4 | the worked ranking example and the glanceable board |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | ranking and elapsed-time arithmetic, both pure |
| `shed-testing` | the ranking order is a table test with the spec's own example in it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/tag_match_test.dart`
- **Test** — `"rankTagMatches('12') returns 12, 128, 412 in that order"`
- **Why it is red today** — nothing ranks tag matches, and the keypad in N13 has nothing to call.

```dart
final all = [entry('412'), entry('128'), entry('12'), entry('99')];
expect(rankTagMatches(all, '12').map((e) => e.tag).toList(), ['12', '128', '412']);
// exact(0) then prefix(1) then suffix(2). '99' scores 99 and is dropped.
```

```bash
fvm flutter test test/domain/tag_match_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the four score bands from `03` §9.1
(exact 0, prefix 1, suffix 2, infix 3, anything else dropped), tie-broken by most-recently-touched
and then by digit length; and `isReadyToTurnOut` whose threshold is a **parameter**, never a
constant, because it is the user's threshold.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only; step 1 is skipped and the commit message says so. `tagIndexProvider`,
the strip and the pen board are N13's and N19's; this task is the two pure functions they call.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/tag_match.dart` | **New.** `TagIndexEntry` **and** `rankTagMatches` in one file (R27). Not a feature folder: the Flock search box and the Foster screen both call it, and layer rule 6 forbids one feature importing another — a feature-folder placement is not merely inconsistent, it is unbuildable |
| 2 | `lib/domain/penning.dart` | **New.** `timeSincePenned`, `isReadyToTurnOut`, and `enum PenExitReason` (R63) |
| 3 | `test/domain/tag_match_test.dart` | **New.** The anchor plus the full band table |
| 4 | `test/domain/penning_test.dart` | **New.** The threshold boundary and the parameter discipline |
| 5 | `test/domain/uk_zone/penning_dst_test.dart` | **New**, `@Tags(['uk-zone'])`. Elapsed time is absolute across both transitions |

### 5.2 The signatures

```dart
// lib/domain/tag_match.dart — R26, R27. Fed by tagIndexProvider, a drift
// watch() over the ewes table filtered to ACTIVE animals.
// ~400 entries x ~40 bytes = 16 KB.
typedef TagIndexEntry = ({EweId eweId, String tag, String digits, Instant? lastTouched});

/// Pure, synchronous. Every keypad tap re-filters inside the same frame.
List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query);
```

The body is printed in `03-data-model-and-schema.md` §9.1 and is copied from there, including the
`score` function and the three-clause comparator. The bands:

| Band | Score | Example against query `12` |
|---|---|---|
| exact | 0 | `12` |
| prefix | 1 | `128` |
| suffix | 2 | `412` |
| infix | 3 | `4125` |
| no match | 99 | dropped before the sort |

Ties inside a band break by **most-recently-touched first** (`lastTouched` descending, nulls last),
then by **shorter digit string first**.

```dart
// lib/domain/penning.dart — R24. `now` is a parameter; package:clock is banned
// in lib/domain/ and the gate proves it.
Duration timeSincePenned(Instant enteredAt, Instant now);

/// The threshold is the USER's, from app_settings.turn_out_threshold_hours
/// (default 24, CHECK 1..336). This function holds no opinion about it and
/// never supplies one — §12.2: the badge is the user's own rule played back.
bool isReadyToTurnOut({
  required Instant enteredAt,
  required Instant now,
  required int thresholdHours,
});

/// Stored keys for pen_occupancies.exit_reason (R63).
enum PenExitReason { turnedOut('turned_out'), moved('moved'), died('died'), other('other') }
```

### 5.3 The details that are easy to get wrong

- **`sincePenned` is a banned name** (R24). `03` §8 once declared
  `Duration sincePenned(Instant enteredAt) => clock.now().difference(enteredAt.utc);` — which would
  sit in the domain and read a clock. The canonical spelling is
  `timeSincePenned(Instant enteredAt, Instant now)`, two parameters, no clock.
- **`isReadyToTurnOut` originates neither the threshold nor `now`.** Both are parameters. A default
  of 24 in this signature is the app suggesting a husbandry decision, which is exactly §12.2's
  origination line. The schema's `CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)` is a range
  guard, not a recommendation.
- **The label is never "ready".** `07` §9.6: the legend says *"Ready = your 24 h threshold"* with the
  user's own number substituted, never the default and never a bare *ready*. That is a copy rule for
  N19, and it is here because this function is where somebody will be tempted to name the concept
  `isFitToTurnOut`.
- **Elapsed time is absolute, and the answer will look wrong by an hour once a year.** Penned Sat
  22:00, checked Sun 08:00 across the spring-forward: `difference` is **9 h** while the wall clock
  says 10. Nine is correct — it is a welfare question about physical hours in a 4×4 pen, and it errs
  toward turning out later. Do not "fix" it, and put that sentence in the code comment.
- **The ranking is over ACTIVE animals only** (R26, and the owner's tag ruling). A culled 412
  releases the tag. The filtering is `tagIndexProvider`'s, not this function's — but a test that
  seeds a culled animal and expects it back is testing the wrong layer, so state the boundary in the
  doc comment.
- **`digits` is `tag_digits`, a projection, and it is never shown to a user.** Uniqueness is on `tag`
  as typed, not on `tag_digits` — making the projection unique would refuse `0412` because `412`
  exists, which is the app deciding two tags are the same animal (`03` §9.1). Rank with it; never
  display it; never compare identity with it.
- **A query with no digits returns `const []`, not everything.** `query.replaceAll(RegExp(r'\D'),
  '')` on `'abc'` is empty, and an empty query must not dump the whole flock into a strip at 03:20.
- **No FTS5, no trigram tokenizer, no `LIKE`, no debounce on this path.** The spec's own example is a
  two-character infix query, which is FTS5's documented counter-example: *"substrings consisting of
  fewer than 3 unicode characters do not match any rows"*. The 200 ms debounce belongs to note search
  and nowhere else — a debounced keypad is a keypad that feels broken.
- **`PenExitReason`'s four keys are stored values**, so they are frozen by N07-T05's
  `pen_occupancies.exit_reason` CHECK one epic later. R63 puts the enum in this file; landing it here
  means the enum and the CHECK are written in the right order. N19-T01 is where it is first *used*,
  and if you defer it there you will be matching an enum to a CHECK that already shipped.
- **`TagIndexEntry` is a record typedef, not a class** (`CONVENTIONS` §2.14 gives its four fields in
  record syntax). Records have structural equality for free, which is what lets `tagIndexProvider`
  use `.distinct()` — a hand-written class here would need `==` and would silently defeat it.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/domain/tag_match_test.dart` | **anchor:** `"rankTagMatches('12') returns 12, 128, 412 in that order"` — spec §7.1's own example · `'an infix match ranks below a suffix match'` (`4125` after `412`) · `'a non-matching tag is dropped, not sorted last'` · `'within a band the most-recently-touched comes first'` · `'a null lastTouched sorts after a non-null one'` · `'within a band with no lastTouched, the shorter digit string comes first'` · `'a query with no digits returns an empty list'` · `'a query of "0412" does not match "412"'` — the projection ranks, it never decides identity · `'ranking is synchronous'` — the call site is not `async` and the test does not `await` |
| `test/domain/penning_test.dart` | `'timeSincePenned is now minus enteredAt, exactly'` · `'a 24 h threshold: 23:59 is not ready, 24:00 is'` — both sides of the boundary · `'the threshold is a parameter: 6 and 48 give different answers on the same instants'` · `'no default threshold exists in the signature'` — a call omitting it must not compile, asserted by a comment on the analyzer rather than by a runtime expect · `'PenExitReason's four stored keys are turned_out, moved, died, other'` |
| `test/domain/uk_zone/penning_dst_test.dart` `@Tags(['uk-zone'])` | `'penned Sat 22:00, checked Sun 08:00 across the spring-forward is 9 h, not 10'` — `05` §2.9's DST-1, at this function's own call site · `'the same pair across the fall-back is 11 h, not 10'` · `'isReadyToTurnOut against a 10 h threshold flips on absolute hours, not wall-clock hours'` |

The `uk_zone` file carries `05` §2.9's `setUpAll` offset assertion and fails loudly rather than
skipping when the zone is wrong.

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. *Turn out* is two words as a verb, `turn_out` as a stored key (R49).
- **§12.2** — the app may play back the user's own threshold; it may never originate one.
- **The 3am test** — this ranking runs on every keypad tap. Synchronous, in memory, no `await`, no debounce.

## 7. Definition of Done

- [ ] `"rankTagMatches('12') returns 12, 128, 412 in that order"` passes, and was seen to fail first for the stated reason
- [ ] the spec's own example is a test case
- [ ] ranking is computed in memory, with no SQL round trip
- [ ] `isReadyToTurnOut` takes the threshold and `now`, and originates neither
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/tag_match_test.dart test/domain/penning_test.dart
TZ=Europe/London  fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
grep -rn "sincePenned\b" lib/ test/       # expect: only timeSincePenned — R24
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): rankTagMatches and the pen-timing functions`
