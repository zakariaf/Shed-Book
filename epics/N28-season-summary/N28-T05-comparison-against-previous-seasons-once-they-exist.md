# N28-T05 — Comparison against previous seasons, once they exist

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 5 of 6 |
| **Depends on** | N28-T04 |
| **Commit** | one commit · `feat(season): comparison against previous seasons, with an honest season one` |

## 1. Why this task exists

Spec §7.8's comparison — and the honest empty case: in season one there is nothing to
compare to, and the screen says that rather than rendering a flat zero line that reads like a
collapse.

There is a second, quieter failure this task closes. If the shepherd changed the lambing-percentage
definition between seasons, a delta between the two is a lie — 165% against 179% is fourteen points
of *convention*, not fourteen points of flock performance. **Two `StatResult`s may only be compared
when their `definition` strings are identical**, and when they are not, the screen says so and shows
no delta.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §6.11, §6.2 | the identical-definition rule, and the four choices whose strings differ |
| `docs/engineering/07-screens.md` | §12.4, §12.5 | the "comparison unavailable" state and the season chip |
| `shed-book-spec.md` | §7.8 | comparison against previous seasons once they exist |
| `docs/design/indelible.md` | §7.11, §8 screen 10 | the comparison is a **second set of rows** under a double rule, headed `2025 · 172%` — never overlaid, never a second colour |
| `docs/engineering/06-design-system.md` | §12 | `ShedEmptyState` occupies the same box the populated content will |
| `docs/engineering/CONVENTIONS.md` | §2.6, §3.2, §4.2, §6 | `StatResult`, the provider catalogue, sealed-result naming, and the amendment route for a new name |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the comparison arithmetic and its `notComputableReason` |
| `indelible-states-and-feedback` | the season-one state and its wording |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/season_summary_test.dart`
- **Test** — `'season one renders the no-comparison state, never a zero baseline'`
- **Why it is red today** — nothing compares seasons, and a naive implementation renders zero for the missing one.

```bash
fvm flutter test test/features/season_summary_test.dart   # expect: failing, for the reason above
```

Make the assertion refuse both wrong answers: on a one-season database, assert the named state text
is present **and** that no widget with a `season_summary.comparison.*` key exists at all. 07 §12.4 is
explicit that the previous-season strip is **absent**, not shown locked, greyed or teased — so a test
that only checks for the absence of `0%` passes against a greyed-out strip, and a greyed strip is a
monetization surface outside the two permitted places.

**Green.** The minimum code that passes, and nothing beyond it — the comparison, and the explicit no-comparison state.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1 | — **no schema step** | `seasons` and `seasons.start_date` with `idx_season_start` were frozen in N07. Say so in the commit message |
| 2 | `lib/domain/stats/definitions.dart` | The comparison rule as a pure function beside `StatResult`. It is a domain rule (05 §6.11), not a widget rule, and it has **no name in CONVENTIONS yet** — see §5.3 gotcha 1 |
| 3 | `lib/data/season_repository.dart` | A read that answers *"which season precedes this one"*. `SeasonRepository` owns `seasons` (CONVENTIONS §2.13); the same §6 ruling names it |
| 4 | `lib/features/season/season_controller.dart` | `SeasonSummaryState` gains the previous season's id and the comparison result. **Two family instances of `seasonFactsProvider`, watched independently** — not `combineLatest` |
| 5 | `lib/features/season/season_summary_screen.dart` | The second set of rows under a double rule, headed with the previous season's label and its headline figure; and the three named absent-comparison states |
| 6 | `lib/l10n/app_en.arb` | The season-one line, the measured-differently line (which prints **both** definitions), and the comparison heading — each with a `description` |
| 7 | `test/domain/stats/comparison_test.dart` | The pure rule: identical definitions compare, different ones do not |
| 8 | `test/features/season_summary_test.dart` | The anchor, extended. Written before all of the above |

### 5.2 The signatures

**These names do not exist in `CONVENTIONS.md` §2.6 or §3.2 yet.** The first half of this commit is
the numbered ruling in §6 that adds them; the shapes below are what 05 §6.11's rule forces.

```dart
// lib/domain/stats/definitions.dart — pure Dart, no Flutter, no drift, no clock.
/// Sealed result; variants are nouns (CONVENTIONS §4.2). There is no `Error`
/// variant — `Error` as a failure-type name is banned outright.
sealed class StatComparison {}

/// Both sides computable and measured the same way.
final class Delta extends StatComparison {
  final double points;              // current.value - previous.value
  const Delta(this.points);
}

/// The definitions differ. NO delta is produced, and both strings render.
final class MeasuredDifferently extends StatComparison {
  final String currentDefinition;
  final String previousDefinition;
  const MeasuredDifferently(this.currentDefinition, this.previousDefinition);
}

/// One side is not computable, or there is no previous season at all.
final class NoComparison extends StatComparison {
  final String reason;
  const NoComparison(this.reason);
}

StatComparison compareStatResults(StatResult current, StatResult? previous);
```

```dart
// lib/data/season_repository.dart — the season that precedes `of`, by start_date.
// Returns null in season one. A SeasonId, never a bare int (R33).
Future<SeasonId?> previousSeason(SeasonId of);
```

Widget keys (R59) — and the season-one case renders **none** of them:

```
season_summary.comparison.heading
season_summary.comparison.stat.lambing_percentage
season_summary.comparison.measured_differently
season_summary.no_comparison
```

### 5.3 The details that are easy to get wrong

1. **Four names in this task are not in the naming authority, and shipping them unruled is the
   defect.** `StatComparison` and its three variants are absent from CONVENTIONS §2.6;
   `previousSeason` is absent from §2.13's repository surface. §2 is *"every type that appears in
   more than one document"* and this task creates the second document. Per the amendment rule
   (`CLAUDE.md`, rule 3): a numbered ruling in CONVENTIONS §6, §2 updated, the files listed — **in
   this commit**. A type that arrives without a ruling is how two spellings of the same idea end up
   in the codebase.

2. **A delta between two different definitions is the exact lie this whole area exists to prevent.**
   Compare the `definition` **strings**, not the `LambingPercentageChoice` enum values, and not the
   `definitionParts` record. The string is what was rendered, what was exported, and what a shepherd
   read; the enum is an implementation detail that a future migration could re-map.

3. **Season one renders an *absent* strip, not a disabled one.** 07 §12.4: *"the previous-season
   strip is **absent**, not shown locked or teased. A free-tier user has exactly one season, and a
   greyed 'unlock to compare' row would be a monetization surface outside the two permitted
   places."* Those two places are the Flock screen and Settings (06 §12), and neither is here.

4. **Never a zero baseline.** A missing previous season is `null`, and `?? 0` under
   `lib/features/season/` is caught by gate row `stat.zero_default`. A flat zero line on a spread
   chart reads as a season in which nothing was born — the most alarming possible rendering of "we
   have no data".

5. **The comparison is a second set of rows, never an overlay.** Indelible §7.11: printed below a
   double rule, headed `2025 · 172%`, *"never overlaid, never a second colour — the whole point of
   small multiples is that two colours are unnecessary."* A second painted series inside one chart
   would also need a legend, and there are no legends.

6. **`dayIndex`, not the calendar date, lines the two spreads up.** T03 anchored each season on its
   own first lambing precisely so two seasons that started on different weekdays still compare row
   for row from day 0. Aligning on `local_date` looks more honest and compares 14 March to 14 March
   in a season that started on 2 April.

7. **Two family instances of `seasonFactsProvider` is legal; combining them is not.**
   `ref.watch(seasonFactsProvider(current))` and `ref.watch(seasonFactsProvider(previous))` are two
   independent statements, each with its own `readsFrom:`. Reaching for `combineLatest` to zip them
   is a build-breaking defect (`stream.combine`, decision #12). A one-frame skew between two
   *seasons* is not a torn read — last season's counts do not change while this season's do.

8. **`previousSeason` is a read, and reads throw** (decision #13). It does not return a
   `WriteOutcome`; that type is for writes only. Ordering is by `seasons.start_date`, which
   `idx_season_start` covers, and comparing the `TEXT` civil dates as strings is correct *because*
   the format is `GLOB`-checked and fixed.

9. **The previous season is the previous *season*, not the previous year.** `seasons.year` is an
   `int` with `CHECK (year BETWEEN 2000 AND 2100)` and two seasons can share one — a flock that
   lambs in January and again in September. Order by `start_date`.

10. **The measured-differently state prints both definitions in full.** Not "definitions differ",
    not an icon: the two sentences, verbatim, so the shepherd can see which is which. That is the
    §12.4 posture — surface the disagreement, never resolve it on the user's behalf.

11. **Do not cache a comparison.** A stored delta is the same anti-pattern as a stored
    `lambing_percentage`: it freezes a definition the user can still change in Settings.

12. **No SnackBar and no dialog when the comparison is unavailable** (owner ruling P2; gate row
    `ui.show_dialog`). It is a state on the page, in the same box, at the same 18 px floor.

### 5.4 The full test set

**`test/domain/stats/comparison_test.dart`** — pure, no Flutter, the thickest tier:

| Case | Asserts |
|---|---|
| `'two results with identical definitions produce a Delta in percentage points'` | the arithmetic |
| `'two results with different definition strings produce MeasuredDifferently and no delta'` | 05 §6.11 |
| `'a null previous result produces NoComparison with a reason'` | season one |
| `'a previous result that is not computable produces NoComparison, never a delta from zero'` | the `notComputable` side |
| `'a current result that is not computable produces NoComparison'` | symmetry |
| `'MeasuredDifferently carries both definition strings verbatim'` | both are renderable |
| `'a delta of zero is a Delta, not a NoComparison'` | "identical seasons" is a real answer and is not absence |

**`test/data/season_repository_test.dart`** — extended:

| Case | Asserts |
|---|---|
| `'previousSeason returns null for the earliest season'` | season one |
| `'previousSeason orders by start_date and not by year'` | two seasons in one calendar year |
| `'previousSeason ignores a later season'` | ordering direction |
| `'the lookup is served by idx_season_start'` | `EXPLAIN QUERY PLAN` names the index |

**`test/features/season_summary_test.dart`** — extended:

| Case | Asserts |
|---|---|
| the anchor | the named no-comparison state, and **no** `season_summary.comparison.*` widget at all |
| `'a two-season database renders the comparison as a second set of rows under a double rule'` | Indelible §7.11's shape |
| `'a changed percentage definition renders both definitions and no delta'` | the measured-differently state, end to end |
| `'the comparison strip never renders a locked, greyed or teased row'` | 07 §12.4 |
| `'no monetization widget renders on this screen at any entitlement state'` | including at `unlocked: false` with two seasons |
| `'the comparison occupies the same box whether present or absent'` | no layout shift between season one and season two |

**Time-shaped case — tag it `uk-zone`.** Two seasons whose spreads both contain 25 October 2026
align on `dayIndex`, not on the civil date, and the comparison rows pair up identically under
`TZ=Europe/London` and under the default zone. A DST-driven one-day slip in either season would
misalign every row after it, and this is the only test that would notice.

## 6. Constraints that bind this task

- **Two `StatResult`s may only be compared when their `definition` strings are identical** (05 §6.11). Otherwise: the named state, both definitions, no delta.
- **The comparison strip is absent in season one, never locked, greyed or teased** (07 §12.4).
- **`?? 0` is banned outright under `lib/features/season/**`** — a missing season is `null`, never zero.
- **A new type or repository method requires a numbered ruling in `CONVENTIONS.md` §6, in this commit.**
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'season one renders the no-comparison state, never a zero baseline'` passes, and was seen to fail first for the stated reason
- [ ] season one renders the explanatory state
- [ ] comparisons use the same definition on both sides
- [ ] a changed percentage definition is disclosed in the comparison
- [ ] the comparison compares `definition` **strings**, not enum values
- [ ] in season one **no** `season_summary.comparison.*` widget exists in the tree
- [ ] the comparison renders as a second set of rows under a double rule, never as an overlay and never in a second colour
- [ ] the two seasons are aligned on `dayIndex`, not on the civil date
- [ ] `combineLatest` appears nowhere; the two seasons are two family instances
- [ ] `StatComparison`, its three variants and `previousSeason` are added to `CONVENTIONS.md` §2 by a numbered ruling in the same commit
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/stats/comparison_test.dart
fvm flutter test test/data/season_repository_test.dart
fvm flutter test test/features/season_summary_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "combineLatest" lib/ || echo 'clean'
fvm dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(season): comparison against previous seasons, with an honest season one`
