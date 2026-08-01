# N28-T04 — The hand-rolled spread chart

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 4 of 6 |
| **Depends on** | N28-T03 |
| **Commit** | one commit · `feat(season): the hand-rolled spread chart with real semantics` |

## 1. Why this task exists

A `CustomPainter` and a `semanticsBuilder` — **no chart library**, no axis furniture, no
legend, no tooltip, no colour encoding and no animation. Spec §7.8 asks for a simple bar chart of
births per day; a chart package would bring a dependency, a gesture surface and a colour palette this
product has ruled out three times over.

Apple is unambiguous that a chart owes *"a reasonably complete text alternative"*, and Flutter has no
chart API to provide one. So the chart is three layers of readable — a visible summary sentence, a
semantics node per day, and a "View as table" — and every one of the three is required.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/10-accessibility-and-i18n.md` | §3.7 | the three layers, the `semanticsBuilder` shape, the eight-placeholder message, the reflow argument |
| `docs/design/indelible.md` | §7.11, §8 screen 10 | fourteen 44 px ruled rows, one block per birth, dotted zero rows, no axis, no colour, no animation |
| `docs/engineering/07-screens.md` | §12.3 | `SpreadChartPainter`, 18 pt labels, no hover, and the horizontal-scroll rule |
| `docs/engineering/06-design-system.md` | §12 | `ShedSpreadChart`'s row in the 21-component inventory |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/engineering/12-testing.md` | §7.3, §8.2 | why an untappable node is skipped by the tap-target guideline; the three chart goldens N33 takes |
| `docs/engineering/CONVENTIONS.md` | §1.1 rule 7, §4.1, §4.2 | `lib/core/ui/` may not import `lib/features/`; shared components are `shed_<thing>.dart` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the chart is a mark, and its rules are the design system's |
| `shed-accessibility-and-copy` | the `semanticsBuilder` is how the chart is readable at all |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/spread_chart_test.dart`
- **Test** — `'the spread chart exposes a semanticsBuilder node per day and imports no chart package'`
- **Why it is red today** — nothing draws the spread, and the obvious solution is a package.

```bash
fvm flutter test test/features/spread_chart_test.dart   # expect: failing, for the reason above
```

Make the assertion count: pump a twenty-day spread in which day 5 has **no** lambs, then assert the
semantics tree holds exactly twenty nodes under the chart and that the day-5 node's label reads
*"18 Mar, no lambs"*. Asserting only "some nodes exist" passes against a painter that skips the
empty days, and the empty days are the point.

**Green.** The minimum code that passes, and nothing beyond it — the painter, the semantics nodes, and an import assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1–3 | — no schema, domain or data step | Everything the chart draws arrives as `List<DayBirths>` from T03. Say so in the commit message |
| 4 | `lib/core/ui/components/shed_spread_chart.dart` | New. `ShedSpreadChart` (the widget) **and** `SpreadChartPainter` (the painter) in one file. §4.1 puts a shared component at `lib/core/ui/components/shed_<thing>.dart`, and layer rule 7 forbids `lib/core/ui/` importing `lib/features/` — so the painter cannot live under a feature. See §5.3 gotcha 1 |
| 5 | `lib/features/season/season_summary_screen.dart` | Mount the chart, wire the two visible text lines, add the "View as table" button |
| 6 | `lib/features/season/widgets/spread_table.dart` | New, feature-private. Layer 3 — the date/count table with `SemanticsRole.table`, `row`, `cell` and a `columnHeader` per column. This is the **only** place table roles are correct in the app |
| 7 | `lib/l10n/app_en.arb` | Three messages: the eight-placeholder summary sentence, the per-bar label (with an ICU plural and a distinct zero case), and the "View as table" button label — each with a `description` |
| 8 | `test/features/spread_chart_test.dart` | New. The anchor, written before all of the above |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_spread_chart.dart
//
// A painter has NO BuildContext and must never reach for one. Everything it
// needs — the resolved token colours and the pre-localised strings — is passed in.
final class SpreadChartPainter extends CustomPainter {
  const SpreadChartPainter({
    required this.days,          // the dense, zero-filled list from lambingSpread
    required this.strings,       // pre-localised label builders
    required this.block,         // Color, resolved from context.tokens by the widget
    required this.rule,          // Color, the dotted zero-day rule
  });

  final List<({LocalDate date, int dayIndex, int births, int ewes})> days;
  final SpreadChartStrings strings;
  final Color block;
  final Color rule;

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
        final double rowHeight = size.height / days.length;
        return <CustomPainterSemantics>[
          for (int i = 0; i < days.length; i++)
            CustomPainterSemantics(
              key: ValueKey<LocalDate>(days[i].date),
              rect: Rect.fromLTWH(0, i * rowHeight, size.width, rowHeight),
              properties: SemanticsProperties(
                // "21 Mar, 19 lambs" / "18 Mar, no lambs" — never "bar 7 of 20".
                label: strings.barLabel(days[i].date, days[i].births),
                role: SemanticsRole.listItem,
              ),
            ),
        ];
      };

  @override
  bool shouldRebuildSemantics(SpreadChartPainter old) => !listEquals(old.days, days);

  @override
  bool shouldRepaint(SpreadChartPainter old) =>
      !listEquals(old.days, days) || old.block != block || old.rule != rule;
}
```

The visible text — **two lines, both always visible, neither screen-reader-only**:

```
Lambing spread, 14 Mar to 2 Apr. 132 lambs over 20 days. Busiest day 21 Mar, 19 lambs.
First day 14 Mar, 3 lambs. Last day 2 Apr, 1 lamb.        <- 10 §3.7 layer 1, eight placeholders
32 of 48 ewes lambed in the first 17 days.                <- 07 §12.3, off app_settings.cycle_days
```

Widget keys (R59), stable and a test contract from here on:

```
season_summary.spread_chart
season_summary.spread_summary_line
season_summary.cycle_line
season_summary.view_as_table
season_summary.spread_table
```

### 5.3 The details that are easy to get wrong

1. **The painter's published path is stale, and following it fails the gate.**
   `10-accessibility-and-i18n.md` §3.7's code comment says
   `lib/features/season/widgets/spread_chart_painter.dart`, while `06-design-system.md` §12 lists
   `ShedSpreadChart` in the 21-component inventory — *"every one of them in
   `lib/core/ui/components/`"* — and `00-PLAN-CRITIQUE.md` §8 G1 places it in this epic. Those two
   cannot both be built: layer rule 7 (`layer.core_ui`) forbids `lib/core/ui/` importing
   `lib/features/`, so a component in `components/` cannot reach a painter under a feature.
   CONVENTIONS §4.1 is the naming authority and it wins: **both classes live in
   `lib/core/ui/components/shed_spread_chart.dart`.** Under the amendment rule, edit 10 §3.7's path
   **in this commit** — a stale path in the accessibility document is how the next person rebuilds
   the violation.

2. **Indelible outranks `07-screens.md` on what the chart looks like, and they disagree.** The
   authority order in `CLAUDE.md` is decision record → CONVENTIONS → `docs/design/indelible.md` →
   the thirteen engineering documents. Indelible §7.11 renders the spread as **fourteen 44 px ruled
   rows**, one `8 × 24 px` block per birth with 3 px gaps, day number in the margin, count
   right-aligned — *"there is no axis because there is no scaling"*. 07 §12.3 describes vertical
   bars with a 60 pt tap target each. Build Indelible's. Record the resolution in the commit
   message so it is not re-litigated at N33 when the goldens are taken.

3. **Do not make a bar tappable.** It is the instinct that "fixes" accessibility and it breaks two
   gates at once. `MinimumTapTargetGuideline` **skips** a node with no `tap` and no `longPress`
   action (`12-testing.md` §7.3 rule 2) — which is precisely why Indelible's 44 px row, *"the only
   sub-64 px row in the system — it is read-only"*, is legal. Add `Semantics(onTap:)` to a bar and
   you have planted a sub-60 pt tappable node that fails `test/design/tap_target_test.dart` on all
   84 runs. Indelible §7.11's state table says it outright: **Pressed — not a target.** The
   tappable affordance is the 64 × 64 "View as table" word button, and 07 §12.5's "read a bar's
   value, 1 tap" is superseded.

4. **A zero day is a dotted rule with `0` printed, never a blank line.** *"A blank line reads as
   missing data, a dotted line reads as nothing happened, and they are different facts."* It also
   gets its own semantics node, labelled *"18 Mar, no lambs"*.

5. **The painter has no `BuildContext` — and neither `Localizations.of` nor `context.tokens` may be
   reached from `paint`.** `ShedSpreadChart` resolves both and passes them down as constructor
   parameters. A `Color(0x…)` inside the painter is a build-breaking defect (`token.raw_color`), and
   the only two files in the app allowed to hold a colour literal are `primitives.dart` and
   `night_error_panel.dart`.

6. **`listEquals` here, `ListEquality` in the repository.** Layer rule 7 permits `package:flutter/*`
   under `lib/core/ui/`, so `listEquals` from `package:flutter/foundation.dart` is correct in this
   file. Layer rule 3's list for `lib/data/` does not include `package:flutter/*`, which is why T03
   used `package:collection`. Same idea, two layers, two spellings — and `old.days != days` on two
   `List`s compares identity and is always true, so `shouldRebuildSemantics` would rebuild the
   semantics tree on every frame.

7. **Every count that can be 1 is an ICU plural.** *"1 lambs"* on the one-lamb day is the failure,
   and it will happen: the first and last day of most seasons are one-lamb days.

8. **Dates arrive pre-formatted.** `formatShedDayMonth(date, localeName)` → `14 Jul`. ARB messages
   never format a `DateTime` placeholder (10 §8.4 rule 4), and no human-facing date is all-numeric
   (R60) — `14/03` is banned even inside the chart.

9. **Two visible lines, not one.** 10 §3.7's summary sentence and 07 §12.3's cycle line **both**
   ship, both as real text, neither screen-reader-only. *"A developer who reads only one document
   will delete the other"* — that sentence is in the source, and it is about this task.

10. **No animation, no implicit animation, no `AnimatedContainer`.** Indelible §7.11 and the reduce
    motion rules both forbid it, and an animated chart is also a non-deterministic golden.

11. **The horizontal scroll is a scroll, not a gesture.** 07 §12.3 has the chart scroll horizontally
    inside its card rather than shrink; the banned-gesture list is swipe *actions*, drag,
    long-press, pinch and sliders — held as `check_policy` rows against `Dismissible`, `Draggable`
    and `Tooltip`. A `SingleChildScrollView` is none of those. It must not be on the primary-action
    path, and there is no primary action on this screen.

12. **Leave it golden-able and take no golden.** `lambing_spread_one_day`,
    `lambing_spread_tight_18_days` and `lambing_spread_60_day_straggle` are **N33's** three images
    (12 §8.2), and goldens do not run on this pull request. What this task owes N33: determinism —
    a committed fixture, `atFixed()`, no wall-clock read, no animation, no random ordering.

### 5.4 The full test set

**`test/features/spread_chart_test.dart`**:

| Case | Asserts |
|---|---|
| the anchor | one semantics node per day, and no chart package |
| `'a day with no lambs still has a node and it says no lambs'` | zero days are in the list, labelled, never skipped |
| `'a bar label names the date and the count, never a position'` | no node label matches `bar \d+ of \d+` |
| `'no chart node exposes SemanticsAction.tap'` | the node has no tap action — the reason the 44 px row is legal |
| `'one lamb reads 1 lamb, not 1 lambs'` | the ICU plural |
| `'shouldRebuildSemantics is true when a count changes and false for an equal list'` | element-wise `listEquals`, not identity |
| `'the painter holds no colour literal'` | read the file; assert no `Color(0x` — the weaker half of gate row `token.raw_color` |
| `'the widget renders with no chart package import'` | read the file; assert no `fl_chart`, `charts_flutter`, `syncfusion`, `graphic` import |
| `'the chart scrolls horizontally rather than shrinking below the tap floor'` | a 60-day spread produces a scrollable, and the day rows keep their height |
| `'the chart carries no Dismissible, Draggable or Tooltip'` | the gesture ban, in the tree |

**`test/features/season_summary_test.dart`** — extended:

| Case | Asserts |
|---|---|
| `'the summary sentence and the cycle line are both present and both visible'` | 10 §3.7's pairing rule, in one assertion |
| `'the summary sentence states facts and never a judgement'` | copy assertion |
| `'View as table renders one row per day with table, row and cell roles'` | layer 3, including a `columnHeader` per column |
| `'View as table is at least 64 by 64 and carries a semanticLabel'` | it is the screen's only chart affordance |
| `'an empty season renders the named empty state, never a zero-height chart and never a spinner'` | 05 §6.9's edge case |

**Time-shaped case — tag it `uk-zone`.** The chart takes `LocalDate`s and never an `Instant`, so the
assertion is that the DST bug is *unrepresentable* here: under `TZ=Europe/London`, a fixture whose
lambings straddle 01:30 on 25 October 2026 renders **one** row for 25 October, labelled `25 Oct`, and
the row count is identical to the same fixture rendered under the default zone.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **The chart itself is read-only.** Its 44 px day row is the one sub-64 px row Indelible permits, and it is permitted *because* it is not a target.
- **No chart package, ever.** G2's dependency allowlist is the mechanism; `fl_chart` is on `00-README` §3.4's chosen-by-not-being-used list. **Do not add a line to `tool/policy_allowlist.txt`.**
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the spread chart exposes a semanticsBuilder node per day and imports no chart package'` passes, and was seen to fail first for the stated reason
- [ ] no chart package in the import graph
- [ ] one semantics node per day, with its date and count
- [ ] readable at 200% text scale
- [ ] no animation and no gesture surface
- [ ] `ShedSpreadChart` and `SpreadChartPainter` are both in `lib/core/ui/components/shed_spread_chart.dart`, and 10 §3.7's path is corrected in the same commit
- [ ] zero-count days have a node and a dotted rule with `0` printed, never a blank line
- [ ] no chart node exposes `SemanticsAction.tap`; "View as table" is the only affordance and is ≥ 64 × 64
- [ ] both visible lines ship — the eight-placeholder summary sentence **and** the cycle line
- [ ] every count that can be 1 is an ICU plural, and every date is `d MMM` from `formatShedDayMonth`
- [ ] `tool/policy_allowlist.txt` is unchanged and `pubspec.yaml` gained no dependency
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/spread_chart_test.dart
fvm flutter test test/features/season_summary_test.dart
fvm flutter test test/design/tap_target_test.dart
fvm flutter test test/design/semantics_gate_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
git diff --exit-code -- pubspec.yaml pubspec.lock tool/policy_allowlist.txt
fvm dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(season): the hand-rolled spread chart with real semantics`
