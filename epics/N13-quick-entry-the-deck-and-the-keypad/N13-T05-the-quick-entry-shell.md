# N13-T05 — The Quick Entry shell

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 5 of 7 |
| **Depends on** | N13-T04 |
| **Commit** | one commit · `feat(quick_entry): the shell — ruled page, spine, margin, bottom band` |

## 1. Why this task exists

The ruled page, the madder spine, the margin cell, the bottom band — and **frame 1 with no
data**, which is the state the shepherd actually opens to when the phone has been cold in a pocket. The
shell reserves every box before data arrives so nothing moves under a thumb.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | **§4.3** (the layout grid: gutter 16, `--margin-rule-x` **68**, the 2 px spine, `--record-x` **76**, the record column 301) · **§4.4** (row heights: record row **64**, page header **44**, bottom band **152**, and the eight-rows density arithmetic) · **§4.5** (the three reach bands, the two thumb anchors, the left-handed mirror, the minimum-target audit) · §4.2 (radii 0/0/2; every rule is **2 px, never 1 px**; shadows: none) · §2.2–§2.3 (five surfaces, three inks, one hue) · §7.1 (the corner slab and its five states) · §7.16 (the page header) · **§8 Screen 3** (the whole page, in prose) | every box, every position, every value |
| `docs/engineering/07-screens.md` | **§5.1** (layout top to bottom, and what gives up space first) · **§5.3** (the seven states, including Frame 1 and the deliberate absence of filtered-empty) · §5.6 (what is banned on this screen) · §1.4 (the state vocabulary) · §1.6 (resume) · §2.2 (Quick Entry is **never empty**) | the state table and the ordering rule |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.4** (Quick Entry gets a `headingLevel: 1` title and **no** level-2 headings, deliberately) · §3.8 (live regions — and the closed list of which nodes are one) · §4 (text scaling; never clamp) · §8.4 (ARB conventions: `description` mandatory, dates arrive pre-formatted) · §9.1–§9.2 (`formatShed*`, `d MMM y`, 24-hour) | the semantics tree and every string's shape |
| `docs/engineering/06-design-system.md` | §12 (`ShedEmptyState` *"occupies the same box the populated content will"*; `ShedPrimaryButton`; `ShedBottomSheet` — `enableDrag: false`, `isDismissible: false`) · §2.1 (dark only) · §6.1 (the tap scale) · §9 (no white flash — the first painted frame is the page colour) | the shared components this screen composes |
| `docs/engineering/02-state-di-navigation.md` | **§10.1** (the rebuild table — `QuickEntryScreen` is a `StatelessWidget`, `_Keypad` is `const` and never rebuilds) · §4.5 (loading is never a spinner) · §9 (no restoration; `MaterialApp` sets no `restorationScopeId`) | the widget tree's shape, printed |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/features/quick_entry/`) · §4.1 (`<screen>_screen.dart`) · §4.5 (widget keys) · §5.4 (no human-facing date is all-numeric; 24-hour) · R59, R60 | **BINDING** on the file, the class and every key |
| `epics/00-PLAN-CRITIQUE.md` | the `[audit]` block — **Indelible artefact defect 1**, owned by this task | the live row is a fixed layer, not a scrolling child |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-page-and-screens` | the page composition, the spine and the margin are its subject |
| `shed-screens-and-routing` | the screen's structure, keys and route |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'frame 1 with no data occupies the same boxes as frame 2 with data'`
- **Why it is red today** — there is no screen; the app opens to `app.dart`'s placeholder.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion to `Rect` equality on **named** boxes, so a failure says *which* box moved:

1. Pump `const QuickEntryScreen()` with a database whose deck stream has not yet emitted (frame 1).
   Record `tester.getRect(find.byKey(...))` for `quick_entry.page_header`, `quick_entry.spine`,
   `quick_entry.margin_cell`, `quick_entry.penned_strip`, `quick_entry.recents_strip`,
   `quick_entry.keypad`, `quick_entry.confirm`, `quick_entry.bottom_band` and `quick_entry.slab`.
2. Let the deck emit six penned and six recent entries; `await tester.pump()`.
3. Assert every recorded `Rect` is **exactly** equal. Not "approximately", not "within a pixel" — the
   claim is that nothing moves under a thumb, and a 3 pt shift is enough to mis-target a 64 pt key.
4. Run the whole thing at all three `Device`s and at text scales 1.0, 1.3 and 2.0, because a box that is
   stable at 390 × 844 and shifts at 375 × 667 is the bug this test exists for.

**Green.** The minimum code that passes, and nothing beyond it — the shell with reserved boxes, ARB strings authored **in this commit**, and widget keys
spelled `quick_entry.<element>`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller** — T02 and T03 built the providers this screen watches.
This task is UI (step 6), ARB (step 6 item 22) and tests (step 7). Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/quick_entry/quick_entry_screen.dart` | **New.** `class QuickEntryScreen extends StatelessWidget` with a `const` constructor. The page: header, the continuous spine, the margin column, the scrolling record column, the fixed live-row layer, the bottom band with the corner slab and `INDEX` |
| 2 | `lib/features/quick_entry/widgets/quick_entry_page_header.dart` | **New.** The sticky 44 pt header naming what the page is filtered to (Indelible §7.16) |
| 3 | `lib/features/quick_entry/widgets/quick_entry_spine.dart` | **New.** The 2 px `madderRule` vertical rule at `x = 68`, continuous from below the header to the top of the bottom band. It does not break for anything |
| 4 | `lib/features/quick_entry/widgets/quick_entry_bottom_band.dart` | **New.** The 152 pt band: `INDEX` bottom-left (96 × 64), the corner slab bottom-right (160 × 140), both above `MediaQuery.paddingOf(context).bottom` |
| 5 | `lib/features/quick_entry/widgets/quick_entry_margin_cell.dart` | **New.** The 68 × 64 margin cell — the auto-captured time, the `AUTO` stamp, and space for the dagger and query marks. **It is a legal tap target** (Indelible §4.3) |
| 6 | `lib/app.dart` | **Edit.** `home:` becomes `const QuickEntryScreen()`, replacing N11's placeholder. `navigatorKey` is already `Routes.navigatorKey` (T01); `restorationScopeId` is still absent |
| 7 | `lib/l10n/app_en.arb` | **Edit.** The screen's own strings — `quickEntryTitle`, `quickEntryPageHeader`, `quickEntryStampAuto`, `quickEntryIndex`, `quickEntrySlabTagFirst` — each with a `description`. The two strips' empty and error copy is **T06**'s |
| 8 | `test/features/quick_entry_test.dart` | **Edit.** The anchor plus the cases in §5.4 |

The two strips' widgets are **T06**. This task renders their reserved boxes as fixed-height
placeholders in `surfaceBase` and nothing else — which is exactly what makes the anchor test provable
before the strips exist.

### 5.2 The signatures

The screen is a `StatelessWidget`, and `02 §10.1` explains why in a comment worth copying verbatim:

```dart
// lib/features/quick_entry/quick_entry_screen.dart
//
// A StatelessWidget, NOT a ConsumerWidget. It watches nothing, so it cannot be
// rebuilt by anything — which is the strongest available proof that a digit
// cannot reach the keypad. The moment someone makes it a ConsumerWidget to
// "just watch one thing here", every child below loses its const-ness.
class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});
```

The layout, from Indelible §4.3 and §4.4, with every number read off `context.tokens` rather than
typed. The grid, for orientation:

```
 0                68  76                                     377   393
 ├────────────────┼───┼────────────────────────────────────────┼────┤
 │  MARGIN CELL   │ ▌ │            RECORD COLUMN               │gut │
 │  68px          │2px│            301px                       │16px│
```

Vertically, at the 393 × 852 reference viewport:

| Band | Height | Contains |
|---|---|---|
| Page header | **44** | sticky, read-only, double rule beneath. Never collapses, never parallaxes, never changes height |
| Record column | the remainder | one scrolling ruled document; 64 pt rows sharing edges, no gaps |
| **Live-row layer** | 128 (two lines) | **fixed**, welded above the bottom band. See §5.3 |
| Bottom band | **152** + `MediaQuery.paddingOf(context).bottom` | `INDEX` 96 × 64 bottom-left; the corner slab 160 × 140 bottom-right, 12 above the safe-area inset, 16 from the edge |

Widget keys, spelled once and never renamed (`CONVENTIONS` §4.5, R59):

```
quick_entry.page_header      quick_entry.spine          quick_entry.margin_cell
quick_entry.record_column    quick_entry.live_row       quick_entry.bottom_band
quick_entry.index            quick_entry.slab           quick_entry.penned_strip
quick_entry.recents_strip    quick_entry.keypad         quick_entry.confirm
```

The ARB messages this commit authors, with their descriptions (`10 §8.4` rule 2 — the description
carries the rationale, because it is what stops a future contributor "improving" the string):

```json
"quickEntryTitle": "Tonight",
"@quickEntryTitle": {
  "description": "The screen's headingLevel: 1 title. Quick Entry has NO level-2 headings (10 §3.4): it is one task, and heading stops would add navigation to a screen whose purpose is not having any."
},
"quickEntryPageHeader": "Night of {night} · page {page}",
"@quickEntryPageHeader": {
  "description": "Indelible §7.16 page header. {night} arrives PRE-FORMATTED as `d MMM y` from formatShedDate (10 §8.4 rule 4) — never format a date inside a message, and never render an all-numeric date (CONVENTIONS R60). The widget applies toUpperCase(); do not store shouty caps here, because the caps are a typographic decision owned by the design system.",
  "placeholders": { "night": { "type": "String" }, "page": { "type": "int" } }
},
"quickEntryStampAuto": "AUTO",
"@quickEntryStampAuto": {
  "description": "Indelible §3.4's stamp: <= 12 characters, all-caps, and NEVER the sole carrier of its meaning — it sits beside a time that is obviously the current time. Safety rule 5 (spec §12.5): auto-captured time is labelled as such."
},
"quickEntrySlabTagFirst": "Tag first",
"@quickEntrySlabTagFirst": {
  "description": "The corner slab's disabled-state label (Indelible §7.1). It is still a 160x140 target: pressing it opens the tag sheet rather than doing nothing. Never 'Select an animal' — the word is tag (CONVENTIONS §5.1)."
}
```

### 5.3 The details that are easy to get wrong

- **The live row is a fixed layer, not a scrolling child. This task owns that correction.** The
  critique's `[audit]` block records **Indelible artefact defect 1**: `indelible.html:1138` puts the
  live row inside the scrolling `.stream`, so the open row scrolls away. The corrected rule is *the
  live row is a fixed layer above the bottom band*, and its owner is **N13-T05**. Build it as a
  `Stack` layer (or a `Column` sibling of the scroll view), never as the last child of the scrollable.
  The reason is the whole mechanism Indelible §8 describes: *"you can see it, in ink, one line above"* —
  a row you have to scroll to find is not a receipt. Assert it: scroll the record column to its extent
  and the live row's `Rect` must be unchanged.
- **The spine is continuous and does not mirror.** Indelible §4.3: *"2 px wide, `--madder-rule`,
  **continuous down the entire scroll**. It does not break for headers, sheets, sections or the live
  row. It is what makes this a book and not a list; if a component would interrupt it, that component
  is wrong."* And: *"A book's margin is on the left. Left-handed mode moves the slab, not the spine."*
  So the spine is painted **behind** everything, including behind the bottom sheet down to the sheet's
  own top edge — not as a child of any row.
- **The bottom band is 152 *above* the safe-area inset, and hard-coding 152 is the bug.** Indelible
  §4.4 measures from `env(safe-area-inset-bottom)`; in Flutter that is
  `MediaQuery.paddingOf(context).bottom`. `pumpApp` injects
  `padding: EdgeInsets.only(top: 47, bottom: 34)` precisely because *"a zero-padding harness hides the
  entire class of bug where a bottom-anchored 60 pt target is under the home bar — which is every
  primary action in this app"* (`12 §5.1`). A band of exactly 152 puts the slab under the home
  indicator on every shipping iPhone.
- **The page header is not a stamp, so the 14 px exemption does not cover it — and 16 px is under the
  floor.** Indelible §3.4 permits sub-18 px type only for stamps, and only when three conditions hold:
  ≤ 12 characters, all-caps at 0.14em, and never the sole carrier of meaning. `--t-head` is 16 px and
  the header reads `NIGHT OF 27 JUL 2026 · PAGE 3` — far longer than twelve characters, and it is the
  one line naming what the page is. This is the `[audit]` block's **Indelible defect 2**, whose
  corrected exemption test is **N09-T05**'s. Render the header at whatever size that ruling allows;
  **do not re-introduce 16 px here** and do not claim the stamp exemption for it.
- **`AUTO` *is* a legal stamp** — four characters, all-caps, and it sits beside a time that is obviously
  the current time, so it is never the sole carrier of its meaning. Keep it that way: the moment the
  stamp is the only thing distinguishing an auto time from an edited one, the exemption is void and
  §12.5 is at risk.
- **The date is `d MMM y` and never all-numeric.** R60 and decision #108. `11 Mar 2026`, never
  `11/03/2026`. Numeric dates exist only inside CSV, beside an ISO-8601 column. The formatting happens
  in `lib/core/ui/formatters.dart` (N09-T06 — the one `package:intl` call site outside `lib/data/`) and
  the **pre-formatted string** is passed into the ARB message (`10 §8.4` rule 4: *"one formatting
  authority, not two"*).
- **`toUpperCase()` belongs in the widget, not in the ARB.** Indelible's header is caps because
  `--t-head` is a caps role with 0.10em tracking — a typographic decision. Flutter has no
  `text-transform`, so the widget calls `.toUpperCase()`. Storing `NIGHT OF …` in the ARB moves a design
  decision into the copy catalogue and loses it the first time the string is edited.
- **Frame 1 is interactive, and this is decision #21's whole promise.** `07 §5.3`: *"The keypad is fully
  interactive with zero data. Both strips are fixed-height dark placeholders. Digits accumulate in
  widget state. The confirm key reads `412 →` — it makes **no existence claim** while the tag index is
  unresolved."* The `412 →` label is not a fallback; it is the honest label for *"I do not yet know
  whether this ewe exists"*, and it is why creating a new ewe costs one extra tap in that window. Do
  not "improve" it to `Create 412`.
- **Loading is never a spinner and there is no `Filtered-empty` state.** `CircularProgressIndicator` is
  banned outright under `lib/features/**` by `tool/check_policy.dart`'s `ui.spinner` row (decision #71).
  And `07 §5.3` is emphatic that filtered-empty *"does not exist on this screen, and that is the
  design"* — digits that match nothing are not an empty result; the confirm key becomes `Create 412`.
  A "no matches" message here *"would be the app stopping to tell the shepherd something it should
  instead be offering to fix."*
- **The layout gives up rows in a fixed order.** `07 §5.1`: if it does not fit, the filtered-match list
  drops to 2 rows, then the "in the pens" strip yields; *"the keypad, the confirm bar and the recents
  strip never give up anything."* Encode the order in the layout, not in a comment.
- **Nothing required to complete an event may sit above 560 pt from the bottom.** Indelible §4.5's
  binding rule, *"checkable in review with a ruler"*: thumb band 0–320 (slab, `INDEX`, live row, the
  sheet, the event buttons), reach band 320–560 (nothing required), read band 560–852 (read-only). The
  page header is read-only and lives in the read band — correct. A confirm control up there is a
  defect.
- **The screen emits exactly one `headingLevel: 1` and zero `headingLevel: 2`.** `10 §3.4` lists Quick
  Entry among the five screens that deliberately get no level-2 stops. `Semantics(header: true)` is a
  no-op since 3.44 and is banned in review (decision #104). N33-T02's sweep asserts at least one
  `headingLevel > 0` node on all fourteen variants, so the level-1 title is not optional.
- **The record column scrolls; nothing else does, and nothing drags.** Vertical page scroll is
  Indelible's own model (§4.5: *"one scrolling ruled page"*). Every other gesture is banned:
  no `Dismissible`, no `Draggable`, no `Tooltip`, no pinch, no slider, no long-press. If the shell needs
  a bottom sheet, it is `ShedBottomSheet` (N10-T07) with `enableDrag: false`, `isDismissible: false`,
  `showDragHandle: false` and an explicit `CLOSE` word-button — Indelible §7.14: *"No drag handle — drag
  is banned, and a handle that cannot be dragged is a lie."*
- **The slab has no verb yet, and that is correct.** Indelible §7.1's **disabled** state — *"Fill
  `--page`, 2 px dashed `--rule` border, label `--ink-low` reading `TAG FIRST`. Still a 160 × 140
  target: pressing it opens the tag sheet rather than doing nothing."* This task places the box and
  gives it that state; **N14** gives it `+ EVENT` / `+ LAMB` and the armed state. Do not stub a write.
- **Every colour and metric comes from `context.tokens`.** A raw `Color(0x…)` or a magic size is a
  build-breaking defect, and `token.raw_color` is scoped to all of `lib/` (R55) with only four
  `[exempt]` lines in the whole project (R56) — none of them this file.
- **Shared controls come from `lib/core/ui/components/`.** `ShedPrimaryButton` (the slab, N10-T01),
  `ShedConfirmBar` (N10-T03), `ShedEmptyState` (N10-T08), `ShedKeypad` (T04). A sibling-feature import
  is a layer violation and inventing a local copy of a component is worse — it is invisible until the
  second screen needs it.

### 5.4 The full test set

`test/features/quick_entry_test.dart`, all through `pumpApp`.

| Case | What it asserts |
|---|---|
| `'frame 1 with no data occupies the same boxes as frame 2 with data'` | **The anchor.** Nine named `Rect`s, exactly equal before and after the deck emits, at three devices × three text scales |
| `'the live row does not move when the record column is scrolled to its extent'` | The `[audit]` Indelible defect 1, owned here. `drag` is banned in the app but is the legitimate way a *test* scrolls; use `tester.scrollUntilVisible` / `fling` on the scroll view only |
| `'the spine is one 2 px rule from below the header to the bottom band and no widget interrupts it'` | One painted rule at `x = margin-rule-x`, continuous height, painted behind its siblings |
| `'the spine does not move when leftHanded is set; the slab and INDEX swap'` | Indelible §4.5's mirror rule, both halves in one case |
| `'the margin cell is 68 × 64 and is a legal tap target'` | It carries the dagger and the query mark later; a 68 × 64 box that is not tappable makes those marks unexplainable |
| `'the bottom band clears the home indicator at every Device'` | Band bottom ≥ `152 + padding.bottom`; the slab's `Rect.bottom` ≤ `size.height - padding.bottom` |
| `'no required control sits above 560 pt from the bottom'` | Indelible §4.5's binding rule, mechanised |
| `'there is no CircularProgressIndicator anywhere in the tree at frame 1'` | Decision #71 and the `ui.spinner` gate row |
| `'the confirm key reads 412 → while the tag index is unresolved'` | `07 §5.3`'s window. It makes no existence claim |
| `'no filtered-empty message renders for a query that matches nothing'` | The state that deliberately does not exist |
| `'the screen emits exactly one headingLevel: 1 and zero headingLevel: 2'` | `10 §3.4`; and zero `Semantics(header:` anywhere |
| `'every interactive element has a semanticLabel and a quick_entry. key'` | Walks the semantics tree; every button node has a non-empty label, and every `ShedTapTarget` has a key matching `^quick_entry\.[a-z0-9_.]+$` |
| `'every string on screen resolves through AppLocalizations'` | No bare `Text('…')` literal under `lib/features/quick_entry/`, source text |
| `'the page header renders d MMM y and never an all-numeric date'` | R60. `11 Mar 2026`; assert no `/` and no four-digit-slash pattern in the header's text |
| `'the match list gives up rows before the keypad does'` | Shrink to `Device.small` at scale 2.0: the keypad's `Rect` is unchanged and the match list is shorter (`07 §5.1`) |
| `'nothing monetization-related renders at any entitlement state'` | Six pumps; identical tree. Decision #90 |
| `'the page header names one night across the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 BST** and again at **01:30 GMT** on the clocks-back night. Both are the *same* night's page, so the header must render the same date and the same page number both times. A header computed by formatting a local wall time and slicing the day boundary flips to the next day at the wrong instant here, once a year, on the one screen that must never look like it lost the night |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **There is no Save button and there is nothing to save.** Indelible §11's acceptance test greps for
  the string `Save` and expects zero hits. This screen has no `Done`, no `Submit` and no `Cancel`
  either.
- **Indelible only.** No element of `the-register.md` or `strip-bay.md` appears in the diff, in a
  comment, or in a review remark.
- **§12.5 does not bind this screen yet**: nothing here renders an event time. If an `HH:mm` appears in
  this diff, it needs a provenance label and it is in the wrong task.

## 7. Definition of Done

- [ ] `'frame 1 with no data occupies the same boxes as frame 2 with data'` passes, and was seen to fail first for the stated reason
- [ ] every box is reserved at frame 1
- [ ] every string is in `app_en.arb` with a `description`, authored here and not swept later
- [ ] every interactive element has a `semanticLabel` and a `quick_entry.` key
- [ ] no scrolling is required to reach the primary action on the smallest device
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `MaterialApp.home` is `const QuickEntryScreen()` and the N11 placeholder is deleted
- [ ] `QuickEntryScreen` is a `StatelessWidget` with a `const` constructor
- [ ] **the live row is a fixed layer above the bottom band and its `Rect` survives a full scroll** (`[audit]` Indelible defect 1)
- [ ] the spine is continuous, 2 px, and does not move under `leftHanded`
- [ ] the bottom band is measured from `MediaQuery.paddingOf(context).bottom`, not from zero
- [ ] the page header is **not** rendered at 16 px and does not claim the 14 px stamp exemption
- [ ] exactly one `headingLevel: 1`, zero `headingLevel: 2`, zero `Semantics(header:`
- [ ] no `CircularProgressIndicator`, no filtered-empty message, no `Save` / `Done` / `Submit` string
- [ ] the `uk-zone` page-header case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/features/                 # keypad and routing did not regress
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "CircularProgressIndicator" lib/features/                    # expect zero
grep -rniE "\bSave\b|\bDone\b|\bSubmit\b|\bCancel\b" lib/features/quick_entry/ lib/l10n/app_en.arb   # expect zero
grep -rn "Color(0x" lib/features/                                     # expect zero
grep -rn "Semantics(header:" lib/                                     # expect zero
grep -rn "Dismissible\|Draggable\|Tooltip\|Slider(" lib/              # expect zero
grep -n "home:" lib/app.dart                                          # expect const QuickEntryScreen()
grep -rn "the-register\|strip-bay\|Strip Bay\|The Register" lib/ test/ # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): the shell — ruled page, spine, margin, bottom band`
