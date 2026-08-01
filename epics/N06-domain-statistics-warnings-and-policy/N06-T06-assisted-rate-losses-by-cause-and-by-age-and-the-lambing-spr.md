# N06-T06 — Assisted rate, losses by cause and by age, and the lambing spread

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 6 of 11 |
| **Depends on** | N06-T05 |
| **Commit** | one commit · `feat(domain): assisted rate, losses and the dense lambing spread` |

## 1. Why this task exists

The remaining statistics, plus the **dense, zero-filled** lambing spread: every day of
the season present, including the days nothing was born, because a spread with the empty days omitted
reads as a tight tupping when it was a loose one.

This is the first time-shaped code in the epic. Everything before it took counts; the spread takes
civil dates and generates a day range, which is where DST arithmetic gets a chance to be wrong once
per season, silently, in the direction nobody checks.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §6.7, §6.8, §6.9, §2.9 | the assisted-rate denominator, the loss buckets and their Teagasc boundaries, the four spread rules, and the DST facts the `uk-zone` cases assert |
| `docs/engineering/CONVENTIONS.md` | §2.6, §5.1 | `DayBirths`/`LambOutcome`/`AgeBucket`'s home, and *unattributed* versus *unknown* |
| `docs/engineering/03-data-model-and-schema.md` | §5.4, §5.5, §5.13 | `lambings.local_date` is denormalised and written in the same transaction as `occurred_at`; `lambs.death_date` is day resolution; `app_settings.cycle_days` defaults to 17 |
| `docs/engineering/06-design-system.md` | §86 | *"32 of 48 ewes lambed in the first 17 days" is a fact; "your tupping was tight" is a judgement and is banned* |
| `docs/research/00-tech-decisions.md` | §2 #59, #70 | the statistic inputs; the chart is a hand-rolled `CustomPainter` — this task ships none of it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the arithmetic, the grouping and the density rule |
| `shed-testing` | the zero-filled property is the assertion that matters |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/stats/spread_test.dart`
- **Test** — `'the lambing spread is dense and zero-filled across every day of the season'`
- **Why it is red today** — nothing computes the spread, and a sparse implementation is the obvious wrong one.

```dart
// Two births, eleven days apart, in a season that runs 1–20 March.
final s = lambingSpread(rows, cycleDays: 17);
expect(s.bars.length, 20);                        // every civil day, not two
expect(s.bars.where((b) => b.births == 0).length, 18);
expect(s.bars.map((b) => b.dayIndex).toList(), List.generate(20, (i) => i));
```

```bash
fvm flutter test test/domain/stats/spread_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the three statistics plus a spread that generates the day range from the season bounds
rather than from the data.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only; the commit message says step 1 is skipped. The two `customSelect`
statements that feed these functions are `SeasonRepository`'s and land in N28 (R18 — there is no
`SeasonStatsRepository`); the chart is `06`/`07`'s and lands in N28 too. This task is the arithmetic.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/stats/assisted_rate.dart` | **New.** `StatResult assistedRate(SeasonCounts)`. Both sides exclude unscored lambings; coverage is always reported |
| 2 | `lib/domain/stats/losses.dart` | **New.** `lossesBreakdown(List<LambOutcome>)` returning total, `byCause`, `byAge` and caveats |
| 3 | `lib/domain/stats/lambing_spread.dart` | **New.** `lambingSpread(List<DayBirths>, {int cycleDays})` returning dense bars, the first-cycle ewe count and the cycle length |
| 4 | `test/domain/stats/spread_test.dart` | **New.** The anchor plus the density, anchoring and boundary cases |
| 5 | `test/domain/stats/assisted_rate_test.dart` · `losses_test.dart` | **New.** §6.7's and §6.8's edge cases |
| 6 | `test/domain/uk_zone/lambing_spread_dst_test.dart` | **New**, `@Tags(['uk-zone'])`. The two UK transitions, and the 23:55 / 00:05 pair |

### 5.2 The signatures

```dart
// lib/domain/stats/assisted_rate.dart
/// Numerator: lambings with ease >= 2 (1 = no assistance).
/// Denominator: lambings WITH an ease score. Both sides exclude unscored
/// lambings, and coverage is always reported.
/// Sheep Genetics: "a blank score indicates the lambing ease was not scored."
/// Reading blank as "1 — unassisted" deflates the rate and is the silent
/// inference safety rule 4 forbids.
StatResult assistedRate(SeasonCounts c);
```

```dart
// lib/domain/stats/losses.dart
({int total, Map<String, int> byCause, Map<AgeBucket, int> byAge, List<String> caveats})
    lossesBreakdown(List<LambOutcome> lambs);
```

```dart
// lib/domain/stats/lambing_spread.dart
/// Dense and zero-filled. The day range is generated from the SEASON BOUNDS,
/// never from the rows: the gaps are the information, because "was my tupping
/// tight?" is a statement about gaps.
({List<({LocalDate date, int dayIndex, int births, int ewes})> bars,
  int? ewesInFirstCycleDays,
  int cycleDays}) lambingSpread(List<DayBirths> rows, {int cycleDays = 17});
```

### 5.3 The buckets, and where their boundaries come from

`AgeBucket` is `{stillborn, sameDay, day1to3, day4to7, day8to30, over30, unknownAge}` and the splits
are **matched to published figures, not invented**. Teagasc's lamb-mortality breakdown — the numbers
an Irish or UK shepherd has actually seen — splits at day 1–3 and day 4–7, with *"the first three
days after birth account for 74% of lamb mortality."* A `day1to2` / `day3to7` split straddles that
boundary and makes the comparison impossible without arithmetic nobody does at the kitchen table.
`day8to30` and `over30` subdivide Teagasc's single ">day 7" band; summing them recovers it exactly.

Age is computed from **civil dates**: `lambingDate.daysUntil(deathDate)` → 0 `sameDay`, 1–3
`day1to3`, 4–7 `day4to7`, 8–30 `day8to30`, >30 `over30`, negative `unknownAge` **plus**
`WarningCode.deathBeforeBirth` on the record.

### 5.4 The details that are easy to get wrong

- **A sparse spread is the obvious implementation and it is the defect.** Generate the day range
  from the season's `start_date`/`end_date`, then fill from the rows. Generating it from
  `rows.first.date` to `rows.last.date` looks dense and silently deletes the empty days at both ends,
  which is where a loose tupping shows.
- **Generate the range with `LocalDate.plusDays`, never by adding `Duration(days: 1)` to a local
  `DateTime`.** `plusDays` routes through `DateTime.utc` deliberately (`05` §2.4), so `+1` is exactly
  one calendar day. The local version yields 23 h across the UK spring-forward and 25 h across the
  autumn one — a season spanning 29 March 2026 then produces a duplicated or a skipped civil day,
  once a year, in the middle of lambing.
- **Group by the denormalised `local_date`, never by UTC and never by a SQL date function** (§6.9
  rule 1, §2.6's ban). A 00:05 lambing belongs to that day; a 23:55 one to the day before. Getting
  this wrong is a once-per-night off-by-one for a whole season.
- **Do not recompute `local_date` for historical rows.** If the device zone changed between insert
  and read, the stored value is the record of the shepherd's day as it was lived. The disagreement is
  surfaced by `localDateDisagrees` (T03) and applied by nothing.
- **`cycleDays` has a default in the signature and the app must never use it.** The value comes from
  `app_settings.cycle_days`, whose column default is 17; the parameter default exists *only* so a
  unit test can omit it. Two defaults that can drift apart is one too many — if that makes you
  uneasy, make the parameter `required` and delete the default, which `05` §6.9 explicitly permits.
- **Bar height is *lambs*; the first-cycle figure counts *ewes*.** Two different units in one chart.
  Label both, and never sum across them.
- **`unattributed` is not `unknown`.** `dc_unknown` is a cause the user can pick; *unattributed* is
  our word for a blank field. Never merge the two columns (`CONVENTIONS` §5.1). Give `unattributed`
  a prominent row rather than hiding it: in a *studied* population Teagasc still records 19% of
  deaths as "diagnosis not reached", so a large unattributed share is something real, not a personal
  failing.
- **`stillborn` is its own bucket, never "died at age 0".** A stillborn lamb has no age at death, and
  folding it in double-counts against any "first 24 h losses" figure.
- **The first bucket is labelled "born and died the same day", never "under 24 hours".** `death_date`
  has day resolution. Teagasc can split 0 h from <24 h because a research post-mortem has a death
  *time*; a civil date does not, and claiming it is the precision inflation safety rule 4 forbids.
- **A blank ease score is not a 1.** No lambing scored → `notComputable`, **not** `0%`. Partial
  coverage → the caveat *"1 of 3 lambings has no ease score and is excluded from both sides."*
- **Ease is recorded per lambing, not per lamb.** SRUC and Sheep Genetics score per lamb; the spec
  puts it on the `Lambing` and for a notebook that is right. Make the definition string say *"per
  lambing"* and label the CSV column `lambing_ease_1_5`, so a future consumer is not misled.
- **A season with no lambings is a named state, not an error.** `bars` empty,
  `ewesInFirstCycleDays` null, and the chart renders its named empty state — never a spinner, never a
  zero-height chart.
- **The hostile-zone CI run will find an absolute assertion.** `TZ=Pacific/Chatham` is UTC+12:45 with
  its own DST. Every assertion in `test/domain/stats/` must be **relational** — "this list is dense",
  "these two dates are 11 apart" — and never a wall-clock literal. The wall-clock literals belong in
  the `uk_zone` file, which the hostile run excludes.

### 5.5 The full test set

| File | Cases |
|---|---|
| `test/domain/stats/spread_test.dart` | **anchor:** `'the lambing spread is dense and zero-filled across every day of the season'` · `'dayIndex is anchored at 0 on the season's first day so two seasons overlay'` · `'a season with no lambings returns empty bars and a null first-cycle count'` · `'ewesInFirstCycleDays counts ewes, not lambs'` · `'the cycle length used is the one passed in, not the signature default'` — pass 21 and assert the window is 21 · `'a day with births but no distinct ewe change still renders its own bar'` |
| `test/domain/stats/assisted_rate_test.dart` | `'no lambing has an ease score → notComputable, not 0%'` · `'ease >= 2 is assisted; ease 1 is not'` · `'unscored lambings are excluded from BOTH sides'` · `'partial coverage attaches the "1 of 3 lambings has no ease score" caveat'` · `'the definition string says per lambing'` |
| `test/domain/stats/losses_test.dart` | `'stillborn is its own bucket and is never sameDay'` · `'a death with no death_date is unknownAge and still counted in the total'` · `'a death with no cause is tallied under unattributed, never under unknown'` · `'unattributed and dc_unknown are separate rows'` · `'a death_date before the lambing gives unknownAge plus deathBeforeBirth'` · `'a tagless dead lamb is counted'` · `'day boundaries: 0→sameDay, 1 and 3→day1to3, 4 and 7→day4to7, 8 and 30→day8to30, 31→over30'` — both ends of every bucket · `'a fostered lamb that died is counted once at season level'` · `'byAge totals equal total'` |
| `test/domain/uk_zone/lambing_spread_dst_test.dart` `@Tags(['uk-zone'])` | `'a season spanning 29 March 2026 has exactly one bar per civil day, with no duplicate and no gap'` — the spring-forward · `'a season spanning 25 October 2026 does the same'` — the fall-back · `'a lambing at 01:30 on 25 Oct 2026, the ambiguous hour, lands on the 25 Oct bar exactly once'` · `'a 23:55 lambing and a 00:05 lambing five minutes apart land on different bars'` — §6.9's own fixture case |

The `uk_zone` file carries `05` §2.9's `setUpAll` offset assertion and **fails loudly** rather than
skipping when the zone is wrong.

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **§12.2** — every figure here is a count of what the user recorded. *"32 of 48 ewes lambed in the first 17 days"* ships; *"your tupping was tight"* does not.

## 7. Definition of Done

- [ ] `'the lambing spread is dense and zero-filled across every day of the season'` passes, and was seen to fail first for the stated reason
- [ ] the spread has one entry per civil day of the season
- [ ] losses are bucketed by cause **and** by age, with `stillborn` its own bucket
- [ ] `unattributed` and `unknown` are never merged
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/stats/spread_test.dart
fvm flutter test test/domain/stats/
TZ=Europe/London  fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): assisted rate, losses and the dense lambing spread`
