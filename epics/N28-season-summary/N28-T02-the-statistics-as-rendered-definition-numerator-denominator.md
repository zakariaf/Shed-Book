# N28-T02 — The statistics as rendered — definition, numerator, denominator, caveats

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 2 of 6 |
| **Depends on** | N28-T01 |
| **Commit** | one commit · `feat(season): the statistics as rendered, with their definitions` |

## 1. Why this task exists

Each statistic renders **with its verbatim definition**, its numerator and denominator, and
its caveats. A lambing percentage without its definition is a number two shepherds will read two
different ways, and §12.2 forbids the app from implying which one is correct practice.

On one flock — 100 to the ram, 92 lambed, 165 born — the OMAFRA convention reads **179%** and the
AHDB convention reads **165%**. Fourteen points apart, both correct, both called "lambing
percentage" in ordinary speech. That is why the definition string is a *required* field on
`StatResult` and why it renders under the number rather than behind an info icon.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §12.1, §12.2, §12.4, §12.6 | the rendering contract, the six cards, the states, and which §12 rules appear |
| `docs/engineering/05-domain-correctness.md` | §6.1, §6.2, §6.4–§6.8 | `StatResult`, the four `LambingPercentageChoice` values, and every statistic's edge cases |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/design/indelible.md` | §8 screen 10, §7.3 | the totals footer: `--t-figure` 56 px figure, 19 px definition beneath, ruled rows, right-aligned tabular column |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §8.4 | `headingLevel: 1` season label + one `2` per stat card; no domain noun literal in an ARB message |
| `docs/engineering/CONVENTIONS.md` | §3.2, §3.4, §4.1–§4.5, R61 | the three spellings, widget keys, and definitions verbatim |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the definitions, the caveats and the not-computable reasons come from the domain, not the screen |
| `indelible-page-and-screens` | the totals-footer composition, the fixed-height cards and the frame-1 geometry |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/season_summary_test.dart`
- **Test** — `'every rendered statistic shows its definition, its numerator and its denominator'`
- **Why it is red today** — nothing renders a statistic, and a bare number with no definition is exactly what §12.2 forbids the app from implying is correct practice.

```bash
fvm flutter test test/features/season_summary_test.dart   # expect: failing, for the reason above
```

Make the assertion carry the contract: for **each** of the six cards, find the card by its widget
key and assert three descendant `Text`s — the value, `stat.definition` **character for character**,
and `'${stat.numerator} / ${stat.denominator}'`. Asserting only that "some definition text is
present" passes against a paraphrase, and a paraphrase is the defect (R61).

**Green.** The minimum code that passes, and nothing beyond it — render from `StatResult`, definition included, with `notComputableReason` rendered as its
own words.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1 | — **no schema step** | Nothing is stored. A cached `lambing_percentage` column would freeze a definition the user can still change and is a named anti-pattern (`01-architecture.md`). Say so in the commit message |
| 2 | — **no domain step** | `StatResult`, `LambingPercentageChoice`, `lambingPercentage`, `averageLitterSize`, `barrenRate`, `assistedRate` and `lossesBreakdown` all shipped in N06. If you are editing `lib/domain/stats/**`, you are re-planning, not building |
| 3 | — no data step | T01 shipped `watchSeasonCounts` |
| 4 | `lib/features/season/season_controller.dart` | Add `SeasonSummaryController`, `SeasonSummaryState` and `seasonControllerProvider`. This file already holds `seasonFactsProvider` from T01 |
| 5 | `lib/features/season/season_summary_screen.dart` | New. `SeasonSummaryScreen` — the season label at `headingLevel: 1`, six cards, each at `headingLevel: 2` |
| 6 | `lib/features/season/widgets/stat_card.dart` | New, feature-private. Value, definition, `numerator / denominator`, caveats. **Not** in `lib/core/ui/components/`: it is used by exactly one screen, and the 21-component inventory does not contain it |
| 7 | `lib/routing/routes.dart` | Add the `RouteNames.seasonSummary` case to `onGenerateRoute` and the typed push helper. `RouteNames.seasonSummary` (`'season_summary'`) already exists from N12; each screen epic adds its own case and helper (`00-PLAN-CRITIQUE.md` S2) |
| 8 | `lib/l10n/app_en.arb` | Every string on the screen, each with a `description`. See §5.3 gotcha 5 for what may **not** go in here |
| 9 | `test/features/season_summary_test.dart` | The anchor, extended. Written before all of the above |

### 5.2 The signatures

```dart
// lib/features/season/season_controller.dart
// flutter_riverpod 2.6.1: family arg arrives via `build` and the inherited `arg`,
// the create argument is a ZERO-argument tear-off, and the base class carries the
// AutoDisposeFamily prefix. Constructor delivery and a bare `Ref` are Riverpod 3.
final seasonControllerProvider = NotifierProvider.autoDispose
    .family<SeasonSummaryController, SeasonSummaryState, SeasonId>(
        SeasonSummaryController.new);

class SeasonSummaryController
    extends AutoDisposeFamilyNotifier<SeasonSummaryState, SeasonId> {
  @override
  SeasonSummaryState build(SeasonId arg) { /* … */ }
}
```

```dart
// lib/features/season/season_controller.dart — screen state, never data.
@immutable
final class SeasonSummaryState {
  final SeasonId season;
  final LambingPercentageChoice choice;   // from settingsProvider.percentageDefinition
  /// Derived, computed in the factory — never a getter (CONVENTIONS §4.4 rule 5).
  final List<StatResult> stats;
  const SeasonSummaryState._({required this.season, required this.choice, required this.stats});

  factory SeasonSummaryState.from(SeasonId season, SeasonCounts c, LambingPercentageChoice choice) =>
      SeasonSummaryState._(season: season, choice: choice, stats: [
        lambingPercentage(c, choice),
        averageLitterSize(c),
        barrenRate(c),
        assistedRate(c),
        // losses render as their own block from lossesBreakdown(…)
      ]);
}
```

```dart
// lib/domain/stats/definitions.dart — already built in N06. Reproduced because
// the four rendered parts are this task's whole contract.
final class StatResult {
  final double? value;            // null means NOT COMPUTABLE. Never 0 as a stand-in.
  final String definition;        // rendered under the number and exported verbatim
  final int numerator;
  final int denominator;
  final String? notComputableReason;
  final List<String> caveats;
}
```

The four definition strings, pinned literally by a test in N06 and **never re-typed here**:

| Stored key | `definition`, verbatim |
|---|---|
| `born_alive_per_ewe_to_ram` | `lambs born alive per ewe put to the ram` |
| `born_incl_stillborn_per_ewe_to_ram` | `lambs born incl. stillborn per ewe put to the ram` |
| `born_alive_per_ewe_lambed` | `lambs born alive per ewe lambed` |
| `reared_per_ewe_to_ram` | `lambs reared per ewe put to the ram` |

Widget keys, `<screen>.<element>[.<qualifier>]`, all `lower_snake` (R59) — these are test contracts
and renaming one later is a breaking change:

```
season_summary.season_chip
season_summary.stat.lambing_percentage
season_summary.stat.lambing_percentage.definition
season_summary.stat.lambing_percentage.fraction
season_summary.stat.lambing_percentage.caveat.0
season_summary.stat.average_litter_size
season_summary.stat.barren_rate
season_summary.stat.assisted_rate
season_summary.stat.losses
season_summary.change_definition
```

### 5.3 The details that are easy to get wrong

1. **Three spellings that do not rhyme, and all three are binding.** The screen widget is
   `SeasonSummaryScreen` in `season_summary_screen.dart` (§4.1, §4.2, and 12 §6.2's harness line);
   the controller **file** is `season_controller.dart` (§3.2's declared file for
   `seasonFactsProvider`); the controller **provider** is `seasonControllerProvider` (§3.4's declared
   list), not `seasonSummaryControllerProvider`. None of these is a typo to tidy, and CONVENTIONS
   outranks every other document on all three.

2. **`?? 0` is a build-breaking defect in this file tree.** Gate rows `stat.zero_default` and
   `stat.zero_default2` scan the literal `?? 0` under `lib/features/season/` and
   `lib/features/flock/`. The rule is the literal text and nothing else — `stat.value ?? 0.0` and
   `?.births ?? 0` in another folder both slip past it, and both are the same lie. Model absence as
   absence all the way to the widget.

3. **`notComputableReason` replaces the value; it does not sit beside it.** No blank cell, no `NaN`,
   no em dash that might mean zero. The lambing-percentage card with no `ewes_to_ram` reads *"The
   number of ewes put to the ram has not been entered for this season."* — and **never** falls back
   to ewes lambed, which is the §12.4 failure in numeric form.

4. **Over 100% is computed, caveated and never clamped.** *"3 ewes have lambed but only 2 were
   recorded as put to the ram."* Warn, never fix. A `clamp(0, 100)` anywhere near this screen is the
   same defect as `?? 0` wearing a different hat.

5. **The definition strings do not go in the ARB.** ARB messages may contain no domain noun as a
   literal (decision #61) and every user-facing string is otherwise an ARB key — but
   `StatResult.definition` arrives **from the domain** as data, is printed verbatim into CSVs and
   PDFs, and is pinned by a test. Putting it in `app_en.arb` creates a second spelling that will
   drift from the first. Card titles, caveat framing and the "Change definition" button label are
   ARB; the definition sentence is a value.

6. **Frame 1 paints the definitions before the counts exist.** 07 §12.4: one fixed-height card per
   stat, in the final geometry, with the definition line already painted — the definitions are
   static text and do not wait for the data. **Never a spinner**: gate row `ui.spinner` bans
   `CircularProgressIndicator` under `lib/features/`, and there is no layout shift when the counts
   land.

7. **No wording may originate an opinion.** The mechanical test: remove the shepherd's own numbers
   and see whether an opinion is left. *"32 of 48 ewes lambed in the first 17 days"* is a fact.
   *"your tupping was tight"*, *"your barren rate is high"* and *"consider scanning earlier"* are
   banned, and so is the word **"should"** (CLAUDE.md's absolute ban list). `ContentPolicy`'s scan
   over string literals and ARB messages is the mechanism; it is not a substitute for reading the
   copy.

8. **The controller never formats.** No `intl`, no `en_GB`, no `%` sign assembled in the notifier
   (CONVENTIONS §4.4 rule 3). `lib/core/ui/formatters.dart` is the only `package:intl` call site in
   `lib/` outside `lib/data/`, and `formatShedCount` / `formatShedDate` live there.

9. **Numerals are tabular or the column reflows on every rebuild.** The right-aligned figure column
   uses a `TextTheme` role carrying `FontFeature.tabularFigures()` (06 §…), which is also what keeps
   `boldText: true` from shifting the column in the matrix.

10. **The heading hierarchy is fixed and may not invent a section.** `headingLevel: 1` on the season
    label ("2026 lambing"); `headingLevel: 2` on each of the six cards — Lambing percentage,
    Average litter size, Barren rate, Assisted rate, Losses, Lambing spread (10 §3.4). `header: true`
    is a no-op on 3.44 and is a gate row (`a11y.header_bool`).

11. **Every colour and metric comes from `context.tokens`.** A raw `Color(0x…)` or a magic size is a
    build-breaking defect (`token.raw_color`); `colorScheme` appears nowhere under
    `lib/features/`.

12. **There is no SnackBar on this screen or anywhere** (owner ruling P2). Nothing on this screen
    writes, so there is nothing to confirm — but the reflex to add a toast when the definition
    changes is exactly the reflex the ruling exists to stop.

### 5.4 The full test set

**`test/features/season_summary_test.dart`** — through `pumpApp`, against `testDatabase()`:

| Case | Asserts |
|---|---|
| the anchor | each of the six cards renders value, `definition` verbatim, and `numerator / denominator` |
| `'the definition string is the domain value, not a paraphrase'` | the rendered text equals `LambingPercentageChoice.bornAlivePerEweToRam.definition` exactly |
| `'changing percentage_definition changes both the number and the sentence'` | write `born_alive_per_ewe_lambed`, pump, assert both moved together |
| `'an unset ewes_to_ram renders the not-computable sentence and no digit'` | the reason text is present; no `%` character in the card |
| `'a not-computable statistic never renders 0'` | scan the card's `Text` descendants for `'0'` as a whole value |
| `'more ewes lambed than put to the ram computes and caveats'` | value above 100 **and** the caveat text present |
| `'a partially scored season shows the assisted-rate coverage caveat'` | *"1 of 3 lambings has no ease score and is excluded from both sides."* |
| `'a season with no ease scores renders assisted rate as not computable, not 0%'` | 05 §6.7 |
| `'a lambing with zero lambs is excluded from both sides of litter size and reported'` | 05 §6.5 |
| `'stillborn is its own losses bucket and is never folded into a day-0 death'` | 05 §6.8 |
| `'a blank death cause is tallied as unattributed and never merged with unknown'` | the vocabulary rule — `dc_unknown` is user-pickable, `unattributed` is ours |
| `'frame 1 paints six cards with their definitions and no progress indicator'` | pump one frame before the database resolves; `CircularProgressIndicator` finds nothing |
| `'the screen carries one headingLevel 1 and six headingLevel 2 nodes'` | 10 §3.4 |
| `'no rendered string implies a target, a recommendation or the word should'` | a copy assertion over the screen text |

**`test/policy/`** — one property-named assertion, because a §12 rule is involved
(`00-README` §8 step 7 point 27):

| File | Asserts |
|---|---|
| `test/policy/every_statistic_carries_its_definition_test.dart` | every `StatResult` the screen builds has a non-empty `definition`, and every one with `value == null` has a non-empty `notComputableReason` |

**Time-shaped case.** Nothing on this screen reads a clock, and that is the assertion worth writing:
tag one case `uk-zone` that pumps the screen under `TZ=Europe/London` with a lambing at 01:30 on
25 October 2026 and asserts the six figures are byte-identical to the same fixture pumped under the
default zone. If they differ, something is deriving a date from an instant at render time.

## 6. Constraints that bind this task

- **The four-part rendering contract is mandatory** (05 §6.1): the `definition` under every headline number *always*, `numerator / denominator` rendered too, the same string exported verbatim, and `notComputableReason` as the value's replacement.
- **`?? 0` is banned outright under `lib/features/season/**`** and is a `tool/check_policy.dart` row.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every rendered statistic shows its definition, its numerator and its denominator'` passes, and was seen to fail first for the stated reason
- [ ] every number carries its definition
- [ ] `notComputableReason` renders as words, never as `0`
- [ ] no wording implies a target or a recommendation
- [ ] the definition text rendered equals `LambingPercentageChoice.definition` character for character; no paraphrase and no ARB copy of it exists
- [ ] `grep -rn '?? 0' lib/features/season/` returns nothing, and `check_policy` agrees
- [ ] frame 1 paints six fixed-height cards with their definitions and no spinner
- [ ] one `headingLevel: 1` and six `headingLevel: 2` nodes, and `header:` appears nowhere
- [ ] every widget key is `season_summary.<element>[.<qualifier>]`, `lower_snake`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/season_summary_test.dart
fvm flutter test test/policy/every_statistic_carries_its_definition_test.dart
grep -rn '?? 0' lib/features/season/ || echo 'clean'
fvm dart tool/check_policy.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(season): the statistics as rendered, with their definitions`
