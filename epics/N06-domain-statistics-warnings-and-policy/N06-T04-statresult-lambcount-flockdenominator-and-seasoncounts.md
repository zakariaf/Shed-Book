# N06-T04 — `StatResult`, `LambCount`, `FlockDenominator` and `SeasonCounts`

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 4 of 11 |
| **Depends on** | N06-T03 |
| **Commit** | one commit · `feat(domain): the statistic result shapes` |

## 1. Why this task exists

The shapes every statistic returns. A statistic with no denominator returns
`notComputableReason` — **not** zero, not a dash, not an empty string. Zero and *cannot be computed*
are different facts and a shepherd reading a barren rate needs to know which one they are looking
at.

It also fixes the four `LambingPercentageChoice.key` strings, which must be byte-identical to
`app_settings.percentage_definition`'s `CHECK` list — written one epic later, in N07. Getting them
right here costs nothing; getting them wrong there costs a migration.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §6.1, §6.2, §6.3, §6.6, §6.8 | `StatResult`'s six fields and its UI/export contract, the four choices and their pinned definition strings, `SeasonCounts`'s thirteen fields and why it writes its own `==`, `EweSeasonOutcome`'s mapping, `LambStatus`/`AgeBucket` |
| `docs/engineering/CONVENTIONS.md` | §2.6, §2.9, §4.6, R43, R61 | which type lives in which of the two files, the stored-key convention, and that the definition strings are 05's verbatim |
| `docs/engineering/03-data-model-and-schema.md` | §5.13, §5.6, §5.14 | `percentage_definition`'s `CHECK` strings, `ewe_seasons.status`'s seven keys, `lambs.status`'s four |
| `docs/research/00-tech-decisions.md` | §2 #58, #59, §7.0 ruling 3 | `StatResult` as the return shape, the statistic inputs, AHDB as the default convention |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the statistics tier and its result shapes |
| `shed-safety-rules` | rendering *cannot be computed* as `0` is a silent correction |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/stats/stat_result_test.dart`
- **Test** — `'a statistic with no denominator returns notComputableReason, never 0'`
- **Why it is red today** — no result shape exists, so a first statistic would return a bare `double`.

```dart
const r = StatResult.notComputable(
    definition: 'lambs born alive per ewe put to the ram',
    reason: 'The number of ewes put to the ram has not been entered for this season.');
expect(r.value, isNull);
expect(r.value, isNot(0));            // both halves: null, and not a zero standing in for it
expect(r.notComputableReason, isNotEmpty);
expect(r.definition, isNotEmpty);     // there is no constructor without one
```

```bash
fvm flutter test test/domain/stats/stat_result_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the sealed result, the count types, and `LambingPercentageChoice` carrying the AHDB
convention ruled by the owner.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only; the commit message states that step 1 is skipped because this task stores
nothing. The counts these types describe are produced by `SeasonRepository.watchSeasonCounts` in
N28 — this task deliberately builds only the shape the repository will fill.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/stats/definitions.dart` | **New.** `StatResult` · `LambCount` · `FlockDenominator` · `LambingPercentageDefinition` (a typedef record) · `LambingPercentageChoice` · `EweSeasonOutcome`. Exactly the list `CONVENTIONS` §2.6 assigns to this file |
| 2 | `lib/domain/stats/season_counts.dart` | **New.** `SeasonCounts` with hand-written `==`/`hashCode` · `DayBirths` (same, plus its own `==`) · `LambOutcome` (a typedef record) · `LambStatus` · `AgeBucket`. Note that `LambStatus` and `AgeBucket` live **here**, not in `definitions.dart` (§2.6, §2.9) |
| 3 | `test/domain/stats/stat_result_test.dart` | **New.** The anchor and `StatResult`'s contract |
| 4 | `test/domain/stats/definitions_test.dart` | **New.** The four choices, their keys and their pinned definition strings; the three enums' keys |
| 5 | `test/domain/stats/season_counts_test.dart` | **New.** Value equality across all thirteen fields, and `DayBirths`'s |

### 5.2 The signatures

`StatResult`, `LambCount`, `FlockDenominator` and `LambingPercentageChoice` are printed in full in
`05-domain-correctness.md` §6.1–§6.2 and are copied verbatim, including the doc comments. The two
things worth restating here are the parts a reader gets wrong from memory:

```dart
// lib/domain/stats/definitions.dart — the four choices. The `key` strings are
// byte-identical to app_settings.percentage_definition's CHECK (03 §5.13); the
// `definition` strings are R61's, verbatim, and are frozen by a test.
enum LambingPercentageChoice {
  bornAlivePerEweToRam('born_alive_per_ewe_to_ram',
      LambCount.bornAlive, FlockDenominator.ewesPutToRam,
      'lambs born alive per ewe put to the ram'),
  bornInclStillbornPerEweToRam('born_incl_stillborn_per_ewe_to_ram',
      LambCount.born, FlockDenominator.ewesPutToRam,
      'lambs born incl. stillborn per ewe put to the ram'),
  bornAlivePerEweLambed('born_alive_per_ewe_lambed',
      LambCount.bornAlive, FlockDenominator.ewesLambed,
      'lambs born alive per ewe lambed'),
  rearedPerEweToRam('reared_per_ewe_to_ram',
      LambCount.reared, FlockDenominator.ewesPutToRam,
      'lambs reared per ewe put to the ram');
  // …
  static const LambingPercentageChoice ahdbDefault = bornAlivePerEweToRam;
}

/// A DERIVED four-way bucketing over `ewe_seasons.status`'s seven stored keys,
/// used only by the statistics functions. It never round-trips to the database
/// and never replaces the stored keys, which stay canonical (R43):
///   lambed                   <- 'lambed'
///   recordedBarren           <- 'barren'
///   diedOrSoldBeforeLambing  <- 'died' | 'sold' | 'aborted'
///   notRecorded              <- 'to_ram' | 'scanned' | no row
enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }
```

```dart
// lib/domain/stats/season_counts.dart — thirteen fields, ONE of them nullable.
final class SeasonCounts {
  final int? ewesPutToRam;               // null = not entered for this season
  final int ewesLambed;
  final int lambingsTotal;
  final int lambingsWithLambs;
  final int lambingsScored;
  final int lambingsScoredAssisted;
  final int lambsBorn;
  final int lambsBornAlive;
  final int lambsReared;
  final int ewesRecordedBarren;
  final int ewesDiedOrSoldBeforeLambing;
  final int ewesWithNoRecordedOutcome;
  const SeasonCounts({ /* all required */ });

  /// Hand-written value equality over EVERY field. Without it the repository's
  /// `.distinct()` is a no-op that looks like a fix.
  @override bool operator ==(Object o) => /* … every field … */;
  @override int get hashCode => Object.hash(/* … every field … */);
}
```

The thirteenth field is `lambingsWithLambs`'s companion in `05` §6.3's list — read that block and
copy the field list from it rather than from this table, because the statistics in T05 and T06
index every one of them by name.

### 5.3 The details that are easy to get wrong

- **`SeasonCounts` without `==` is a performance bug that presents as a correctness bug.**
  `Stream.distinct()` compares with `==`; identity equality never matches; every drift re-emit on any
  tracked table rebuilds the whole Season Summary. `Object.hash` over more than twenty arguments
  needs `Object.hashAll` — count the fields before you write it.
- **`DayBirths` needs `==` too, and a `List<DayBirths>` needs `listEquals` on top.** A bare
  `.distinct()` over a `List` compares list *identity* and filters nothing (`05` §6.9). That is
  N28's call site, but the equality it depends on is written here.
- **`ewesPutToRam` is `int?` and the null is load-bearing.** `null` is "I did not record it" — not
  zero, and not "the same as ewes lambed" (03 §5.6). Every statistic that divides by it must reach
  `notComputable`, and T05 has a named test for exactly that.
- **`notComputableReason` is a `String?`, not an enum** (`05` §6.1, catalogued in `CONVENTIONS`
  §2.6). "A closed set with display text" is satisfied by holding the reasons as named `const`
  strings in this file and referencing them, never by typing the sentence at four call sites — two
  call sites that word it differently produce two statistics that §6.11 then refuses to compare.
- **The four `key` strings cannot be cross-checked against the schema JSON yet.**
  `05`'s definition of done asks for a test "against the committed schema JSON"; there is no
  `drift_schemas/drift_schema_v1.json` until **N07-T08**. Here, pin the four keys and the four
  definition strings *literally* in `definitions_test.dart`; the JSON cross-check is N07's, and
  N07-T08's freeze must add it. Say so in the test's own comment so nobody deletes the literal freeze
  as a duplicate later.
- **`LambStatus` and `AgeBucket` live in `season_counts.dart`.** They feel like definitions and they
  are not; `CONVENTIONS` §2.6 and §2.9 both place them, and a moved type is an import churn across
  T06, N21 and N28.
- **`EweSeasonOutcome` is a bucketing and never a column** (R43). Four members over seven stored
  keys. If you find yourself writing `EweSeasonOutcome.name` into anything that reaches SQLite, stop:
  the seven keys are canonical and this enum never round-trips.
- **There is no `StatResult` constructor without `definition`** (`05` §9 row 21). That is the
  mechanism, not a convention: a bare percentage cannot be constructed, so it cannot be rendered.
- **`StatResult.notComputable` defaults `numerator` and `denominator` to `0`.** They are structural
  placeholders, not counts. Nothing may render them when `value` is null — `notComputableReason` is
  the value's *replacement*, and "0 / 0" beside it reads as a real measurement.
- **`?? 0` is banned in `lib/features/season/` and `lib/features/flock/`, and the gate only scans
  those two prefixes.** A `?? 0` inside `lib/domain/stats/` compiles, passes `make check`, and turns
  "we have not recorded that" into "you scored zero". Only the tests in T05 and T06 hold this. Read
  every nullable arithmetic in this diff twice.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/domain/stats/stat_result_test.dart` | **anchor:** `'a statistic with no denominator returns notComputableReason, never 0'` · `'a computable result carries value, numerator, denominator and definition together'` · `'caveats defaults to const [] and is never null'` · `'notComputable leaves numerator and denominator at 0 and value null'` |
| `test/domain/stats/definitions_test.dart` | `'LambingPercentageChoice has exactly four members'` · `'the four keys are the four strings in app_settings.percentage_definition's CHECK'`, pinned literally with a comment pointing at N07-T08 for the JSON cross-check · `'the four definition strings are frozen'` — all four spelled out, per R61 · `'ahdbDefault is bornAlivePerEweToRam'` (§7.0 ruling 3) · `'definitionParts returns the (count, per) pair for each choice'` · `'LambCount and FlockDenominator keys are born/born_alive/reared and ewes_to_ram/ewes_lambed'` · `'EweSeasonOutcome buckets all seven ewe_seasons.status keys, and an absent row, to exactly one member each'` |
| `test/domain/stats/season_counts_test.dart` | `'two SeasonCounts with identical fields are equal and share a hashCode'` · `'changing any ONE of the thirteen fields breaks equality'` — a loop over the fields, so a forgotten field in `==` fails here rather than as a silent rebuild storm in N28 · `'ewesPutToRam null and ewesPutToRam 0 are not equal'` · `'DayBirths has value equality'` · `'LambStatus keys are alive, dead, stillborn, sold'` |

**No `uk-zone` case.** These are shapes, not arithmetic over time. `DayBirths` carries a `LocalDate`
but computes nothing with it; the first time-shaped assertions in this epic are T06's spread cases
in the 01:00–01:59 hour.

## 6. Constraints that bind this task

- **None of the five safety rules is held in this task, and the commit message says so.** These are result shapes, not decisions. The nearest thing to a rule is `notComputableReason`, which exists so a statistic can refuse rather than return a zero a shepherd would read as a fact — that is honesty about a denominator, not §12.4. Claiming a rule this task does not hold would put it at the *documented* level, and a rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Stored keys are frozen by N07.** Every `key` in this diff is a `CHECK` string one epic later.

## 7. Definition of Done

- [ ] `'a statistic with no denominator returns notComputableReason, never 0'` passes, and was seen to fail first for the stated reason
- [ ] no statistic can return a number without a denominator
- [ ] `notComputableReason` is a closed set with display text
- [ ] the AHDB percentage convention is the default and is named as a choice
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/stats/stat_result_test.dart
fvm flutter test test/domain/stats/
grep -rn "?? 0" lib/domain/stats/      # expect: nothing — the gate does not scan here
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): the statistic result shapes`
