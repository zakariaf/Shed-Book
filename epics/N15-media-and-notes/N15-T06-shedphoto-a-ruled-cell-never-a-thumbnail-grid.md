# N15-T06 — `ShedPhoto` — a ruled cell, never a thumbnail grid

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 6 of 6 |
| **Depends on** | N15-T05 |
| **Commit** | one commit · `feat(ui): ShedPhoto as a ruled cell` |

## 1. Why this task exists

A captured photo renders as a **ruled cell under a `ColorFiltered`** — never a card, never
a thumbnail grid, never a gallery. The design system has one photo treatment and this is it; a grid of
thumbnails at 3am is a target-size failure and a legibility failure at once.

It is also the **only sanctioned `ColorFiltered` in the app**. A global one over the whole tree is
banned (decision #96) for three reasons in order of severity: it collapses `statusReady`,
`statusAttention` and `statusLoss` into three near-identical hues — a WCAG 1.4.1 failure introduced
*by* the accessibility feature; it destroys per-token contrast control; and it triggers a full-screen
`saveLayer` every frame. Inside this widget the cost is bounded to the image's own bounds, which is
the whole reason the filter is allowed to exist at all.

`indelible.md` §7's component inventory has **no image element and no audio element** — critique
**G5**, conflict **P12**. That gap is why `indelible-controls` was given the capture surfaces, and it
is why this task is where the ruled-cell rule gets written down in code rather than argued about on
twelve screens.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §4.7 | `ShedPhoto` printed in full; why a global `ColorFiltered` is banned; the permanent *"Show in full colour"* control and its §12.2 reason |
| `docs/engineering/06-design-system.md` | §3.4, §12 | `photoTint` is a `ShedTokens` field, non-null only in the night-shift palettes; `ShedPhoto`'s row — *"fills its box · tinted, full colour"* |
| `docs/design/indelible.md` | §4.2 | `--radius-record: 0`, **rules are 2px never 1px**, `--rule-dot` for an unset cell, **shadows: none** |
| `docs/design/indelible.md` | §4.3, §4.4, §7.3 | the record column and the continuous spine; the 64 px record row; the ruled row's six states including *Unset cell* |
| `docs/engineering/04-migrations-media-backup-restore.md` | §5.2 | *"Photo taken 14 March 03:22 — file no longer on this phone"* — the missing state, and why the row is never deleted |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §8.4, §9.1, §9.2 | `headingLevel` never `header:`; every ARB message carries a `description`; dates and times arrive **pre-formatted**; never an all-numeric date |
| `docs/engineering/02-state-di-navigation.md` | §8.1 | thirteen `RouteNames`, twelve push helpers, and the arithmetic that is asserted — which is why there is no photo-viewer route |
| `docs/engineering/12-testing.md` | §6.1, §7.4 | the matrix is **14 routes**, not components; `test/design/` holds the guideline sweeps |
| `docs/engineering/CONVENTIONS.md` | §1, §2.11, §4.1, §4.5, §5.4 | `lib/core/ui/components/shed_<thing>.dart`; layer rule 7; `<screen>.<element>` keys; every displayed event time carries its provenance label |
| `epics/00-PLAN-CRITIQUE.md` | §8 G1, §11.3 N10 | why the component inventory is its own epic, and the exact wording of the per-component gate |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | it owns the photo surface `indelible.md` §7 has no component for (critique G5, conflict P12), and the rule *"a ruled cell with a `ColorFiltered` `ShedPhoto`, never a card and never a thumbnail grid"* is its sentence |
| `indelible-states-and-feedback` | the **missing** state is the DoD's fourth line and a first-class state, not an error — an empty-shaped state with real copy, which is this skill's subject rather than `indelible-page-and-screens`', since this task touches no page grid |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedPhoto renders as a ruled cell with no card, no shadow and no grid'`
- **Assertion, spelled out** — pump `ShedPhoto` through `pumpApp` and assert, on the widget tree:
  `find.byType(Card)` is empty; no `BoxDecoration` in the tree carries a non-null `boxShadow` or a
  non-zero `borderRadius`; `find.byType(GridView)` and `find.byType(Wrap)` are empty; there is exactly
  one `Border`/`Divider`-shaped rule and its thickness equals `context.tokens.outlineWidth`, which is
  **2** and not 1; and `find.byType(ColorFiltered)` is present in the `amber` palette and **absent** in
  `night`. Every one of those is something the framework's obvious answer gets wrong.
- **Why it is red today** — nothing renders a photo, and every framework example is a card in a grid.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the component, the filter, and the component-table test row.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema, no domain, no data, no wiring, no controller. This is step 6 (UI) and step 22 (the ARB),
plus one policy test — and it is the only task in the epic that adds an ARB string.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_photo.dart` | **New.** `ShedPhoto` — the ruled cell, the one `ColorFiltered`, the full-colour toggle and the missing state. `CONVENTIONS` §4.1: shared components are `lib/core/ui/components/shed_<thing>.dart`. |
| 2 | `lib/core/ui/tokens.dart` | Read, **not edited.** `photoTint` already exists as a `ShedTokens` field from N09-T02, non-null only in the two night-shift palettes. |
| 3 | `lib/l10n/app_en.arb` | Edit: three messages, each with a `description` — the missing line, the full-colour control, and the cell's `semanticLabel`. |
| 4 | `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart` | Regenerated by `fvm flutter gen-l10n` and **committed in this commit** (`00-README` §7.1). A stale generation is what the `codegen` job's `git diff --exit-code -- lib/` catches. |
| 5 | `test/design/components_test.dart` | Edit: `ShedPhoto`'s row — the anchor plus the cases in §5.4. This is the file N10-T01…T08 already fill one row each. |
| 6 | `test/policy/one_colorfiltered_test.dart` | **New.** Decision #96 as an executable assertion, on the same shape as N10-T07's `one_overlay_test.dart`. `test/policy/` files are named for the **property**, not the file under test. |
| 7 | `test/features/photo_cell_dst_test.dart` | **New.** `@Tags(['uk-zone'])`. The `TZ=Europe/London --tags uk-zone` run is deliberately **unscoped** (13 §4.3), so a uk-zone file outside `test/domain/` is expected — `12 §2.4` already has two. |

### 5.2 The signatures

`06 §4.7` prints the core. The states, the rule and the control are this task's additions and are
flagged in the PR body rather than invented silently:

```dart
// lib/core/ui/components/shed_photo.dart
/// The ONLY sanctioned ColorFiltered in the app (decision #96). Cost is bounded
/// to the image's own bounds. In night and in every high-contrast palette
/// photoTint is null and this widget is a plain Image.
///
/// It renders as a RULED CELL: no card, no shadow, no radius, no grid.
/// Indelible §4.2 — "nothing in the record has a corner radius, because a
/// document has no corners" — and §4.4, where the record row is 64 px and rows
/// share edges.
class ShedPhoto extends StatefulWidget {
  const ShedPhoto({
    super.key,                       // supplied by the SCREEN — see gotcha 12
    required this.image,             // an ImageProvider. lib/core/ui/ may not
                                     // import lib/data/, so the caller resolves
    required this.capturedAtLabel,   // pre-formatted 'd MMM y' + 'HH:mm'
    required this.provenanceLabel,   // RecordedTime.provenanceLabel, never empty
    this.missing = false,            // media_assets.missing_since is not null
  });

  final ImageProvider image;
  final String capturedAtLabel;
  final String provenanceLabel;
  final bool missing;
}
```

The build, in the shape the assertions read:

```dart
final ColorFilter? tint = context.tokens.photoTint;
final Widget img = Image(image: widget.image, fit: BoxFit.cover);
// Never an identity filter when tint is null: an identity ColorFiltered still
// pays for a saveLayer.
final Widget body = (tint == null || _fullColour) ? img : ColorFiltered(colorFilter: tint, child: img);
```

The three ARB messages, in `10 §8.4`'s shape:

```json
"photoMissingOnThisPhone": "Photo taken {date} {time} — file no longer on this phone",
"@photoMissingOnThisPhone": {
  "description": "04 §5.2. The media_assets row survives when its file does not; deleting the row would make the app lie by omission (spec §12.4). {date} and {time} arrive PRE-FORMATTED from formatShedDate and formatShedTime — never format a date inside a message (10 §8.4 rule 4).",
  "placeholders": { "date": { "type": "String" }, "time": { "type": "String" } }
},
"photoShowInFullColour": "Show in full colour",
"@photoShowInFullColour": {
  "description": "06 §4.7. Permanent, not conditional. A shepherd looking at a photo of a prolapse needs the colour information, and a tinted view of tissue is useless. It is also what keeps the app on the right side of spec §12.2: the app shows what was photographed and never interprets it."
},
"photoSemanticLabel": "Photo taken {date} {time}, {provenance}",
"@photoSemanticLabel": {
  "description": "The cell's semanticLabel. CONVENTIONS §5.4: every displayed event time carries its provenance label — a bare 03:21 is a review failure, and that applies to the spoken form too.",
  "placeholders": { "date": { "type": "String" }, "time": { "type": "String" }, "provenance": { "type": "String" } }
}
```

### 5.3 The details that are easy to get wrong

1. **No `Card`, no `elevation`, no `BoxShadow`, no `BorderRadius`.** Indelible §4.2: `--radius-record`
   is **0** — *"nothing in the record has a corner radius, because a document has no corners"* — and
   **shadows: none, elevation: none**, anywhere in the system; even the bottom sheet is separated by a
   2px rule instead of a blur. Every framework example of an image in a list is a `Card`, so this is
   the defect that arrives by autocomplete.
2. **Rules are 2px, never 1px, and the 2 is a token.** *"A hairline shimmers, aliases, or vanishes
   entirely on a mid-range Android at low brightness — and in this design the ruling is load-bearing
   structure, not decoration."* Use `context.tokens.outlineWidth`; a literal `1` or `2` is a magic
   size and a build-breaking defect.
3. **No `GridView`, no `Wrap` of thumbnails, no gallery, no carousel.** Two photos on a record are two
   ruled cells, stacked, sharing edges. A grid also breaks the spine: `--margin-rule-x: 68px` is a 2px
   madder rule running **continuously down the entire scroll**, and Indelible §4.3 is categorical —
   *"if a component would interrupt it, that component is wrong."*
4. **`photoTint` is `null` in `night` and in every high-contrast palette, and then the widget is a
   plain `Image`.** Do not paper over the null with an identity `ColorFilter.mode(Colors.transparent,
   BlendMode.dst)`: it renders identically and still costs a `saveLayer`, which is one of the three
   reasons the global filter was banned in the first place.
5. **"Show in full colour" is an in-place toggle and must not push a route.** `RouteNames` has
   **thirteen** entries — spec §9's twelve screens plus `noteSearch` — `Routes` has **twelve** push
   helpers, and `02 §8.1` asserts *"`RouteNames` constants minus one equals `Routes` push methods"*. A
   photo-viewer route would break that assertion and add a screen the product does not have. The
   control lives on the cell, at `tapHero`, permanently visible whenever a tint is active.
6. **The tap surface is `ShedTapTarget`, never a bare `GestureDetector`.** `ShedTapTarget` takes a
   **required** `semanticLabel` and sets `Semantics(onTap:)`; `10 §3.2` lists `GestureDetector`
   without semantic callbacks among the widgets that announce nothing, and a button node with no tap
   *action* announces correctly and then refuses to activate under Switch Control. The floor is 60 × 60
   pt by spec §5 and Indelible builds to **64 × 64** — 4 pt of headroom and no more.
7. **The missing state is a state, not an error, and never a broken-image glyph.** `04 §5.2`:
   *"Photo taken 14 March 03:22 — file no longer on this phone"* is a true statement and a useful one;
   deleting the row would make the app lie by omission. Render it with Indelible §7.3's **Unset cell**
   treatment — a 2px **dotted** `--rule-dot` line with a caps label above it, *"a visible gap, never a
   hidden field"*. `Icons.broken_image` is the wrong answer twice: it is an icon in a system that has
   no icon set, and it reports a failure where there is a fact.
8. **The date in that line is never all-numeric.** `d MMM y` → `14 Mar 2026`, `HH:mm` → `03:22`.
   `13/07` and `07/13` are indistinguishable to a reader who does not know which locale resolved, and
   `copy.numeric_date` is a gate row. Both strings arrive **pre-formatted** as placeholders from
   `formatShedDate` and `formatShedTime`; ARB `DateTime` placeholders are not used anywhere in this
   app, because `Instant` and `LocalDate` are extension types and `lib/core/ui/formatters.dart` is the
   one formatting authority.
9. **The time carries its provenance label.** `CONVENTIONS` §5.4: *"Every displayed event time carries
   its provenance label. A bare `03:21` is a review failure."* That applies to `semanticLabel` too,
   which is why `photoSemanticLabel` takes three placeholders and not two.
10. **`lib/core/ui/` may not import `lib/data/`** (layer rule 7). The component therefore cannot call
    `MediaStore.resolve()` and must not construct a `File`; it takes an `ImageProvider` and the caller
    hands it a `FileImage`. That rule is also what makes this task testable with no filesystem at all —
    a `MemoryImage` is enough.
11. **Colours and metrics come from `context.tokens`; `colorScheme` appears nowhere under
    `lib/core/ui/components/`.** A raw `Color(0x…)` is `token.raw_color` and a build-breaking defect.
    `06`'s definition of done states both, and the gate proves both.
12. **A shared component never hard-codes its widget key.** Keys are `<screen>.<element>[.<qualifier>]`,
    all `lower_snake` (§4.5) — `ewe_card.photo`, `lambing_entry.photo.2` — so the *screen* supplies
    them through `super.key`. A key baked into `shed_photo.dart` would name a screen the component does
    not know about, and a key is a test contract: renaming one is a breaking change to
    `test/features/`.
13. **`headingLevel`, never `header: true`.** `Semantics(header: true)` is a **no-op on both iOS and
    Android as of 3.44** and still reads correctly in review, which makes it the single most likely
    accessibility regression in this codebase. `ShedPhoto` is not a heading and emits neither — but
    expect the question, and know the answer.
14. **`ShedPhoto` is not an overflow-matrix variant.** The matrix is 14 **routes** × 3 sizes × 3 text
    scales × 2 bold-text states = 252 (R58), and N33-T01 asserts the count is 14. A component gets a
    row in `test/design/components_test.dart` instead, and that row's wording matters: *every **tap
    surface** in its tree is at least 64 by 64 with a `semanticLabel`* — **not** "no dimension below
    64", which would make `ShedStatusBadge` (≥ 24 tall inside a ≥ `tapMin` parent) and
    `ShedSectionHeading` (no target contract at all) unbuildable.
15. **No golden.** Eight images is the budget (decision #116) and goldens are not a per-PR gate. A
    photo cell's pixels are not a usability or safety regression that nothing else can see; the tint's
    contrast is `test/design/contrast_test.dart`'s, and it operates on tokens, not on photographs.
16. **Run `fvm flutter gen-l10n` and commit `lib/l10n/app_localizations*.dart` in this commit.**
    `flutter run` and `flutter build` re-run gen-l10n, so a stale committed generation is invisible
    locally and red in CI: the `codegen` job diffs `lib/` and this epic's only reason to touch a
    generated file is right here.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/design/components_test.dart` | `'ShedPhoto renders as a ruled cell with no card, no shadow and no grid'` | The anchor, all five clauses. |
| | `'ShedPhoto renders at textScale 2.0 with boldText and every tap surface in its tree is at least 64 by 64 with a semanticLabel'` | The house case every component row carries (`00-PLAN-CRITIQUE` §11.3), in its corrected wording. |
| | `'a ColorFiltered is present in amber and in deep red, and absent in night'` | `photoTint`'s three-way behaviour, asserted by palette rather than by name. |
| | `'no ColorFiltered is present in any high-contrast palette'` | The HC variants set `photoTint` to null on purpose; a tint over an HC palette undoes the thing the palette is for. |
| | `'the full-colour control removes the filter in place and pushes no route'` | Tap it; assert `find.byType(ColorFiltered)` is empty **and** `Routes.navigatorKey.currentState` pushed nothing. Gotcha 5, both halves. |
| | `'the full-colour control is at least 64 by 64 and carries its own semanticLabel'` | It is a second tap surface inside the cell and inherits none of the outer one's labelling. |
| | `'the rule beneath the cell is context.tokens.outlineWidth and not 1'` | Read the value off the painted `Border`; a hairline is a legibility failure nobody sees on a desk monitor. |
| | `'a missing file renders the missing line with its date, time and provenance, and no Icons.broken_image'` | The DoD's fourth line, plus §5.4's provenance rule and the absence of the icon a framework example would reach for. |
| | `'the missing line uses the dotted rule treatment and leaves a visible gap'` | Indelible §7.3's *Unset cell*: the record is honest about its own thinness. |
| | `'two ShedPhotos stack as two ruled cells sharing an edge, with no GridView and no Wrap'` | The anti-gallery assertion, stated positively so it survives a refactor. |
| | `'ShedPhoto reads no colour from ColorScheme and holds no colour literal'` | Belt and braces with `token.raw_color`; the gate scans text, this reads the tree. |
| `test/policy/one_colorfiltered_test.dart` | `'ColorFiltered( appears in exactly one file under lib/, and it is shed_photo.dart'` | Decision #96 as an assertion rather than a comment. Named for the property, not the file (§4.1). |
| | `'tool/policy_allowlist.txt contains no exempt line for a second ColorFiltered'` | A rule with an escape hatch is a rule that will be escaped. |
| `test/features/photo_cell_dst_test.dart` | `'two photos captured at the two 01:30s on 25 October 2026 render two rows, both reading 01:30, ordered by instant'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The ambiguous hour, 01:00–01:59. The label is identical and the order must still be right, because the cell renders the instant and sorts on it. A cell that sorted on its own label would swap them. |
| | `'a photo captured at 00:30 BST on 1 April 2026 renders 1 Apr 2026, not 31 Mar 2026'` | The same local-versus-UTC trap `MediaStore`'s shard has, one layer up: `formatShedDate` takes a `LocalDate`, and a `LocalDate` derived from the UTC instant is a day out for six months of the year. |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. **Pinch-to-zoom on a photo is the specific temptation here and it is banned by name.** The full-colour toggle is a tap; there is no zoom, no pan and no `InteractiveViewer`.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. The three messages in §5.2 are the whole of this epic's ARB surface.
- **§12.2, in image form** — the app shows what was photographed and never interprets it. That is what the permanent full-colour control buys, and it is why the control is not conditional on a setting.
- **§12.4, applied to bytes** — a row whose file is gone renders the fact, not a failure, and the row is never deleted.
- **Dark only** — there is no light theme and none is reachable. The tint is a night-shift affordance over a photograph, never a theme.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. It is a **photo**, never an image or a thumbnail, in every user-facing string.

## 7. Definition of Done

- [ ] `'ShedPhoto renders as a ruled cell with no card, no shadow and no grid'` passes, and was seen to fail first for the stated reason
- [ ] no card, no shadow, no thumbnail grid
- [ ] the tap target is at least 64 × 64
- [ ] a missing file renders the *missing* state, not a broken image
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/design/components_test.dart

# 2. Decision #96, as an assertion.
fvm flutter test test/policy/one_colorfiltered_test.dart

# 3. The ambiguous hour, in the zone it is about.
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. Regenerate the ARB output and commit it WITH this change, or `codegen`
#    fails on a stale generation.
fvm flutter gen-l10n
git status --short lib/l10n/

# 5. The whole design tier, at every palette and text scale.
fvm flutter test test/design/

# 6. Nothing else generated moved.
make gen && git status --short

# 7. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedPhoto as a ruled cell`
