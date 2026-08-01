# N10-T04 — `ShedAnimalRow` and `ShedSectionHeading`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 4 of 8 |
| **Depends on** | N10-T03 |
| **Commit** | one commit · `feat(ui): ShedAnimalRow and ShedSectionHeading with real heading levels` |

## 1. Why this task exists

The 64 and 88 px ruled rows, the sub-grid they align to, and `headingLevel` 1 and 2 —
with `header:` **banned**, because a screen reader that hears twelve headers and no hierarchy cannot
jump to the summary line the whole retention feature depends on.

`10 §3.4` states the stake plainly: `Semantics(header: true)` **is a no-op on both iOS and Android as
of 3.44**, *"it still compiles and it still reads correctly in review, so it is the single most likely
accessibility regression in this codebase."* Spec §7.7 makes the Ewe Card summary line the retention
feature; for a sighted user that is a glance, and for a VoiceOver user it is the rotor set to Headings
and one flick — or, without `headingLevel`, a swipe through every field on the card.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedAnimalRow`: ≥ `tapPrimary` tall, full width, states default/pressed/selected, tag `displaySmall` tabular + one summary line; `ShedSectionHeading`: `titleMedium`, emits `headingLevel: 2`, screen titles emit `1`, **`header:` is banned**) · §5.1 (the role table: `displaySmall` 40 tabular, `titleLarge` 24, `titleMedium` 20) · §5.4 (**never construct a bare `TextStyle` for a numeral** — it drops `fontFeatures` and the column starts jittering) | the size contract, the roles, the heading levels |
| `docs/design/indelible.md` | §4.3 (**the row sub-grid** — margin cell 0–68, spine at 68, record column 76–377, tag right-aligned in a fixed column, tally 132, trailing status min 64) · §4.4 (row heights: record 64, ewe 88, header 44) · §7.3 (the ruled record row and its six states) · §7.4 (**the ewe row** — tag right-aligned so `412` `128` `77` align on their units digit) · §7.16 (the page header) | the geometry, and what the row's cells are |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (**`headingLevel` only**, the `a11y.header_bool` row, the per-screen `headingLevel > 0` assertion, and the **screen-by-screen level table**) · §3.5 (the `textScalerOf(context).scale(t.numeralSize)` pattern for a width that must hold a tag) · §4.2 (never clamp) | the heading API, the level table and how a fixed cell survives 200% |
| `docs/engineering/07-screens.md` | §1.7 · §3.1 (the Flock query behind the row) · §4.2 (the Ewe Card summary line — *"3 seasons · avg 2.0 · assisted twice"*, the retention feature) | what one row actually says |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rule 7 · §4.1–§4.2 · §4.5 (widget keys) | the paths and the names |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-page-and-screens` | the ruled row, the sub-grid and the page rhythm |
| `shed-accessibility-and-copy` | heading levels, the banned `header:` flag and the reader's jump order |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedSectionHeading exposes headingLevel and no widget in the tree sets header: true'`
- **Why it is red today** — no row and no heading exist; every screen would invent both.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen both halves. The positive half reads the **semantics node**, not the widget:

```dart
final handle = tester.ensureSemantics();
addTearDown(handle.dispose);
await _pumpComponent(tester, const ShedSectionHeading(label: 'Summary'));
expect(tester.getSemantics(find.text('Summary')).headingLevel, 2);
```

The negative half is a source-text sweep, because a `header: true` written into any component would
still render and still read correctly in review:

```dart
expect(
  Directory('lib/core/ui/components').listSync(recursive: true)
      .whereType<File>().where((f) => f.path.endsWith('.dart'))
      .where((f) => f.readAsStringSync().contains('header:')).toList(),
  isEmpty,
  reason: 'header: true is a no-op since 3.44 — use headingLevel (a11y.header_bool)',
);
```

**Green.** The minimum code that passes, and nothing beyond it — both widgets, the two row heights, and the heading-level semantics.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB entry — the
tag, the summary line and the heading label all arrive as strings, and the summary line in particular
is composed by the screen from `07 §4.2`'s query. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_animal_row.dart` | **New.** The row plus its `ShedAnimalRowHeight` enum. Every list in the product — Flock, the foster target picker, the deck, the medicine book — is this row under a different filter, which is why it is one component and not four |
| 2 | `lib/core/ui/components/shed_section_heading.dart` | **New.** Twelve lines of widget carrying the single most likely accessibility regression in the codebase |
| 3 | `test/design/components_test.dart` | **Extend.** The heading-level case, the `header:` sweep over the whole components folder, the two heights, and the tag-column alignment case |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_animal_row.dart

/// indelible.md §4.4's two ruled heights, expressed as tokens rather than as
/// 64 and 88 — see the gotcha about the 64/72 floor.
enum ShedAnimalRowHeight { standard, tall }

final class ShedAnimalRow extends StatelessWidget {
  const ShedAnimalRow({
    super.key,
    required this.tag,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
    this.trailing,
    this.height = ShedAnimalRowHeight.tall,
    this.selected = false,
  });

  /// `displaySmall`, tabular, right-aligned in its own column so that 412,
  /// 128, 77 and 9 all align on their units digit (indelible.md §7.4).
  final String tag;

  /// ONE line. `07 §4.2`: "3 seasons · avg 2.0 · assisted twice". Composed by
  /// the screen from its own query, never assembled here.
  final String summary;

  /// The right-hand cell: a status word, a figure, or nothing. Widget rather
  /// than String because it is usually a ShedStatusBadge (N10-T05).
  final Widget? trailing;

  final String semanticLabel;
  final VoidCallback onTap;
  final ShedAnimalRowHeight height;
  final bool selected;
}
```

```dart
// lib/core/ui/components/shed_section_heading.dart

final class ShedSectionHeading extends StatelessWidget {
  /// `06 §12`: emits `headingLevel: 2`; screen titles emit `1`. Only those two
  /// values exist in this app — `10 §3.4`'s table has no level 3 anywhere —
  /// so the parameter is asserted, not merely typed.
  const ShedSectionHeading({super.key, required this.label, this.level = 2})
      : assert(level == 1 || level == 2, 'only levels 1 and 2 exist — 10 §3.4');

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      headingLevel: level,                       // NEVER `header: true`
      child: Text(label,
          style: level == 1 ? text.titleLarge : text.titleMedium),
    );
  }
}
```

The row's cell widths come from the scaled numeral, exactly as `10 §3.5` does it for the pen board:

```dart
    final ShedTokens t = context.tokens;
    // indelible.md §4.3 prints "76px fixed (3 tabular digits at 32px)". 76 is a
    // value at scale 1.0, not a constant: at 200% a 76 px cell clips a 3-digit
    // tag, and `type.fitted_box` forbids shrinking it back.
    final double tagColumn =
        MediaQuery.textScalerOf(context).scale(t.numeralSize) * 1.9;
```

### 5.3 The details that are easy to get wrong

- **`header:` compiles, reads correctly in review, and does nothing.** `10 §3.4` and decision #104:
  it has been a no-op on both platforms since 3.44. `headingLevel > 0` maps to
  `View.setHeading(true)` on Android and `UIAccessibilityTraitHeader` on iOS. The gate row
  `a11y.header_bool` catches the literal `header: true` under `lib/`, but it does **not** catch
  `header: someBool` — which is why the source sweep in the anchor greps for `header:` and not for
  `header: true`.
- **The two heights are `tapPrimary` and `tapHero`, and one of them is a documented widening.**
  Indelible §4.4 prints 64 and 88; `06 §12` contracts `ShedAnimalRow` at **≥ `tapPrimary`** = 72.
  Both are *minimums*, so the larger wins and the standard row is 72. The cost is one row of page
  density — `852 − 44 − 152 = 656`, eight rows at 64 becomes seven at 72 — and that is a screen
  decision N13-T05 owns, not a component decision. Record the widening in the PR body; do not
  quietly ship 64 (it is below `06 §12`'s floor) and do not quietly ship 72 without saying that
  Indelible's page rhythm moved.
- **Neither `64` nor `88` may appear in either file.** They are `t.tapPrimary` and `t.tapHero`, and
  `token.magic_size` fails the build on `height: 88`. Token first when you multiply:
  `t.tapPrimary * 2`, never `2 * t.tapPrimary`.
- **The spine is not the row's.** Indelible §4.3: the 2 px madder rule at x = 68 is *"continuous down
  the entire scroll. It does not break for headers, sheets, sections or the live row. It is what makes
  this a book and not a list; if a component would interrupt it, that component is wrong."* A row that
  paints its own 68 px spine segment produces a dashed spine at every row boundary from sub-pixel
  rounding. The spine is one widget behind the whole scrollable and belongs to the page — N13-T05.
  The row leaves the margin cell empty and starts its content at the record column.
- **The row's rule is a bottom border only.** §7.3: *"rows share edges; there is no top border and no
  gap — the ruling is continuous, like a ledger."* A row with both borders doubles every rule in the
  list, and a doubled rule already means something else: §7.4's warning state.
- **The tag goes through `displaySmall` and nothing else.** `06 §5.4`: constructing a fresh
  `TextStyle` instead of copying a role drops `FontFeature.tabularFigures()`, and the failure is
  silent — the flock list starts jittering as `412` and `108` take different widths. Never
  `TextStyle(fontSize: …)`; `token.literal_font_size` fails the build on it anyway.
- **A fixed 76 px tag cell fails the overflow matrix.** `10 §3.5`'s pattern is the one that survives:
  derive the width from `MediaQuery.textScalerOf(context).scale(t.numeralSize)`. There is deliberately
  no floor and no ceiling on text scale (`10 §4.2`, decision #99), `TextScaler.clamp` and
  `withClampedTextScaling` are gated, and `FittedBox` is gated — so the cell grows or the row wraps,
  and there is no third option.
- **`selected` is a state of the row, not a colour.** `06 §12` lists default / pressed / selected;
  decision #106 says colour is never the only channel. Indelible §7.13's selected form gives it a
  2 px solid underline the width of the target and lifts the ink while siblings stay at
  `textSecondary`. Two channels minimum, and the monochrome test (Indelible §11 test 4) is how you
  check it: desaturate the screenshot and read it.
- **`ShedSectionHeading` is not the page header.** Indelible §7.16's sticky 44 px header sets
  `--t-head` at **16 px**, which is below the 18 px floor and is a **known artefact defect** —
  `00-PLAN-CRITIQUE.md` §8 records it, and N09-T05 owns the corrected exemption test. Do not
  reproduce 16 px here. This component's roles are `titleMedium` (20) and `titleLarge` (24), both
  above the floor, both already in `buildShedTextTheme`.
- **Levels 1 and 2 must nest, and the nesting is the screen's.** `10 §3.4`'s table is binding and
  short: Ewe Card gets *Summary · Timeline*; Reminders gets *Overdue · Due today · Upcoming*; Quick
  Entry, Lambing Entry, Lamb Card and Foster get **no level 2 at all**, because *"each is one task,
  and heading stops would add navigation to screens whose entire purpose is not having any."* This
  component must not emit a heading it was not asked for, and it must not default to 1.

### 5.4 The full test set

`test/design/components_test.dart`, extended.

| Case | What it asserts |
|---|---|
| `'ShedSectionHeading exposes headingLevel and no widget in the tree sets header: true'` | **The anchor.** `getSemantics(...).headingLevel == 2` for the default, `== 1` for `level: 1`; plus the `header:` sweep over every file in `lib/core/ui/components/` |
| `'ShedSectionHeading refuses a level outside 1 and 2'` | The assert fires for 0 and for 3. `10 §3.4`'s table has no level 3 |
| `'level 1 renders titleLarge and level 2 renders titleMedium'` | Effective style equality against the theme role — 24 and 20 at scale 1.0, never 16 |
| `'ShedAnimalRow is tapPrimary tall standard and tapHero tall tall'` | 72 and 88, measured on the laid-out rect, at textScaler 1.0 |
| `'neither row height shrinks at textScaler 1.3 or 2.0'` | Monotonic in height across three scales; no `RenderFlex` overflow at any of them with a 3-digit tag and a full summary line |
| `'tags right-align on their units digit'` | Pump `412`, `128`, `77`, `9` in four rows and assert the four tag `Text` rects share a **right** edge. This is Indelible §7.4's whole claim, and it is the one that breaks the day someone left-aligns the cell |
| `'the tag renders through displaySmall with tabularFigures'` | `fontFeatures` contains `FontFeature.tabularFigures()`. Catches the constructed-`TextStyle` regression `06 §5.4` warns about |
| `'the summary is exactly one line'` | `maxLines` is 1 at every scale; the row grows, the summary does not become two lines and push the tally off the grid |
| `'the row draws a bottom rule and no top rule'` | Border inspection. Two rules per row is §7.4's warning state and must not be the default |
| `'a selected row differs from an unselected one with colour removed'` | Compare the two subtrees for a non-colour difference — an underline, a weight, a mark. Decision #106 |
| `'the row is one ShedTapTarget with a semanticLabel'` | `find.byType(ShedTapTarget)` once; label non-empty; `SemanticsAction.tap` present |
| `'neither file paints at x = 68 and neither contains the literal 64, 76 or 88'` | Source text. The spine is the page's (Indelible §4.3) and the numbers are tokens |

**Nothing here is time-shaped.** The trailing cell renders a **string** — `31h`, `9d`, `12 Mar` —
formatted by `formatters.dart` (N09-T06) from a `Duration` the caller computed with
`timeSincePenned(enteredAt, now)`, which takes `now` as a parameter and never reads a clock (R24). If
this component ever imports `lib/core/time/`, layer rule 7 has been broken.

## 6. Constraints that bind this task

- **3am** — standard row `tapPrimary` (72), tall row `tapHero` (88), full width, `gapMin` (16)
  between adjacent targets, 18 px floor, dark only. `06 §7`'s one permitted tracked gesture is
  vertical scrolling; the row itself takes a single tap and nothing else.
- **`headingLevel`, never `header:`** — held by the semantics node, by the `a11y.header_bool` gate row
  and by a source sweep over this folder. Three mechanisms, because the failure is invisible in review
  and invisible on screen.
- **Colour is never the only channel** (decision #106, WCAG 1.4.1 Level A) — applies to `selected` and
  to whatever the trailing cell carries.
- **No ARB entry** — `tag`, `summary`, `label` and `semanticLabel` are parameters. `10 §3.2` rule 3
  (the Voice Control criterion) means the visible words and the spoken label must match, and only the
  screen knows both.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedSectionHeading exposes headingLevel and no widget in the tree sets header: true'` passes, and was seen to fail first for the stated reason
- [ ] `header:` appears nowhere
- [ ] heading levels are 1 and 2 and nest correctly
- [ ] the two row heights are tokens, not literals
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] a level outside 1 and 2 is refused by an assert, not merely undocumented
- [ ] tags right-align on their units digit, proved by a four-row rect comparison
- [ ] the tag's style carries `FontFeature.tabularFigures()` and comes from `displaySmall`
- [ ] neither file paints the spine, and neither contains the literals 64, 76 or 88
- [ ] the 64 → 72 widening is recorded in the PR body with its page-density consequence

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -rn "header:" lib/core/ui/components/                                  # expect zero
grep -rnE "(width|height|minWidth|minHeight):\s*(64|76|88)" lib/core/ui/    # expect zero
grep -n "TextStyle(" lib/core/ui/components/shed_animal_row.dart            # expect zero
grep -n "headingLevel" lib/core/ui/components/shed_section_heading.dart     # expect one
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedAnimalRow and ShedSectionHeading with real heading levels`
