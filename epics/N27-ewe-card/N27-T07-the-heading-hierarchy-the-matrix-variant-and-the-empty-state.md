# N27-T07 — The heading hierarchy, the matrix variant and the empty state

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 7 of 7 |
| **Depends on** | N27-T06 |
| **Commit** | one commit · `feat(ewe_card): the heading hierarchy and the matrix variant` |

## 1. Why this task exists

A real heading hierarchy, so a screen reader jumps **straight to the summary line** — which
is the whole point of the screen and is otherwise buried under six timeline groups. Plus `ewe_card`
joining `kPumpableVariants`.

10 §3.4 states the stake in one sentence: *"For a sighted user that is a glance. For a VoiceOver user
the only equivalent is the rotor set to Headings and one flick. Without `headingLevel`, that user
swipes through every field on the card and the retention feature is gone."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.4 (`headingLevel` only; `Semantics(header: true)` is a no-op on 3.44 and is *"the single most likely accessibility regression in this codebase"*; the per-screen heading table; the paragraph on why this screen is the reason the rule exists)** · §7.3 (the gate: at least one `headingLevel > 0` node on **all fourteen** variants) · §11 (`sortKey` is banned — `a11y.sort_key`) · §3.2 (labels), §5 (wrap, never truncate) · §8.5 (the terminology placeholder in the title) | the hierarchy, and the one API that works |
| `docs/design/indelible.md` | **§8 screen 2 (the card: `EWE 412 · ALL SEASONS`, the summary printed first on its own 64 px row, the current-status row, then *"the seasons, most recent first, each under a printed sub-head and a double rule: `SEASON 2026` → … `SEASON 2025` → … `SEASON 2024`"*)** · §7.3 (the ruled record row) · §4.4 (row heights) | the visual structure the headings describe |
| `docs/engineering/07-screens.md` | §4.2 (the states table — Frame 1, Loaded, **Empty**, Reused tag, Error, Over-cap) · §2.2 (the empty copy: *"Nothing recorded for 412 yet."* + *"Record a lambing"*) · §1.7 (every section heading uses `headingLevel: 1..6`; `header:` is banned in review) · §4.1 (`season` is projected on all seven arms) | the states, the copy, and the column that decides the grouping |
| `docs/engineering/12-testing.md` | **§6.1 (the fourteen variants — `ewe_card` is number 2)** · §6.2 (`kPumpableVariants` is declared **once**, in `test/support/harness.dart`, and iterated by four files; the self-check is the only place the count is derived) · §5.1 (`pumpApp`, `Device`, `textScale`, `boldText`) · §5.3 (`kSeedEwe` and the fixture id constants) · §7.4 (the semantics and geometric gates, which are N33's) · §8.2 + §8's note (`ewe_card_summary_line` is **not** a golden) | the variant row and how it is pumped |
| `docs/engineering/06-design-system.md` | §12 (`ShedSectionHeading` emits `headingLevel: 2`, screen titles emit `1`; **`ShedEmptyState` — occupies the same box the populated content will, one line of copy, one action at the same `tapHero` control the populated screen uses, no illustration, no spinner, no tour**) | the two components this task composes |
| `docs/engineering/CONVENTIONS.md` | §4.5 (widget keys), §3.4 (`eweCardControllerProvider` — screen state, never data), §4.4 rules 1 and 4 (a screen controller holds screen state; anything the user typed lives in a private field), §5.1 (*season*), R58 (252 cells over 14 variants — the arithmetic follows the variant list), R59 | **BINDING** on the controller, the keys and the count |
| `docs/engineering/03-data-model-and-schema.md` | §5.1 (`Seasons.year`, `.label` — *"2026 lambing"*), §5.12 (`notes.season` is **nullable**; every other arm's is `NOT NULL`) | what a season group is, and the one row that has no season |
| `docs/engineering/02-state-di-navigation.md` | §3.1 (`AutoDisposeFamilyNotifier<S, EweId>` with `S build(EweId arg)` — the 2.6.1 shape), §4.2 (auto-dispose), §8.3 (`PopScope`, `flushPending`) | the screen controller this task finally adds |
| `epics/00-PLAN-CRITIQUE.md` | S1 / S3 (`kPumpableVariants` grows one row per screen epic; the fixtures arrive in N23), §11.3 (N33-T01's matrix self-check) | why the row is added here and not in N33 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | heading levels and the reader's jump order |
| `shed-testing` | the variant row and the semantics assertion |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'the summary line is the first heading a screen reader reaches'`
- **Why it is red today** — the screen has no heading structure, so a reader traverses it linearly.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it measures the **jump**, not the presence. Seed a card with three seasons of
history — ~40 rows — and collect every semantics node with `headingLevel > 0` in **tree order**.
Assert: the first is the title (`headingLevel: 1`), the second is the summary (`2`), and that the
number of *non-heading* nodes before the summary heading is **zero**. A test that only asserts
`headingLevel: 2` exists on the summary passes on a card where forty timeline rows come first, which
is the exact failure 10 §3.4 describes.

**Green.** The minimum code that passes, and nothing beyond it — heading levels 1 and 2, the variant row, and the empty state for a ewe with no
history.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 5 (the screen controller), step 6 (the headings, the grouping and the empty state), step 6
item 22 (the ARB) and step 7 (the matrix row and the tests).** No schema, no domain, no data. Say the
skipped layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/flock/ewe_card_controller.dart` | **Edit.** `EweCardState`, `EweCardController extends AutoDisposeFamilyNotifier<EweCardState, EweId>` and `eweCardControllerProvider` — **screen state only** (§4.4 rule 1): the season-group expansion, the pending note text in a private field, and `flushPending()` for 02 §8.3's `PopScope`. The grouping helper `groupBySeason(List<TimelineRow>)` lives here too |
| 2 | `lib/features/flock/ewe_card_screen.dart` | **Edit.** `Semantics(headingLevel: 1)` on the title, `ShedSectionHeading` (level 2) on the summary and on each season sub-head, the grouped list, and `ShedEmptyState` |
| 3 | `lib/features/flock/widgets/season_heading.dart` | **New.** The printed sub-head and its double rule (Indelible §8 screen 2), emitting `headingLevel: 2` |
| 4 | `lib/l10n/app_en.arb` | **Edit.** The season sub-head, the no-season group label, and the empty-state copy and action — each with a `description` |
| 5 | `test/support/harness.dart` | **Edit.** One row: `RouteNames.eweCard: () => const EweCardScreen(eweId: kSeedEwe)`. The table is declared **once** here and iterated by four files (12 §6.2) |
| 6 | `docs/engineering/10-accessibility-and-i18n.md` | **Amend, §3.4.** The Ewe Card row's *"one flat timeline… no further stops to invent"* is struck with its reason and replaced by the season sub-heads. See §5.3 item 3 |
| 7 | `test/features/ewe_card_test.dart` | **Edit.** The anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/features/flock/ewe_card_controller.dart
//
// 02 §3.1's 2.6.1 family shape. Screen state, never data (CONVENTIONS §4.4
// rule 1): the timeline is eweTimelineProvider's and the summary is
// eweSummaryProvider's. What lives here is what the SCREEN knows.

@immutable
final class EweCardState {
  const EweCardState({this.collapsedSeasons = const <SeasonId>{}});
  final Set<SeasonId> collapsedSeasons;
}

final class EweCardController extends AutoDisposeFamilyNotifier<EweCardState, EweId> {
  /// §4.4 rule 4: anything the user typed lives in a PRIVATE FIELD, not only in
  /// state — build() re-running (because the flock changed) would otherwise
  /// wipe a half-typed note mid-sentence. 02 §3.1 calls this a real 3am bug.
  String _pendingNote = '';

  @override
  EweCardState build(EweId arg) => const EweCardState();

  void noteChanged(String text) => _pendingNote = text;

  /// Called from PopScope's onPopInvokedWithResult (02 §8.3). canPop stays
  /// true — back is never blocked and there is no "discard changes?" dialog.
  Future<void> flushPending() async { /* … */ }
}

final eweCardControllerProvider = NotifierProvider.autoDispose
    .family<EweCardController, EweCardState, EweId>(EweCardController.new);

/// The grouping. Pure, synchronous, testable without a widget tree — and it
/// groups on the STORED season FK, never on the year of `at` (§5.3 item 4).
List<({SeasonId? season, List<TimelineRow> rows})> groupBySeason(List<TimelineRow> rows);
```

```dart
// lib/features/flock/ewe_card_screen.dart — the hierarchy, in tree order.
Semantics(headingLevel: 1, child: Text(l10n.eweCardTitle(singularTerm: term, tag: tag)))
ShedSectionHeading(l10n.eweCardSummaryHeading)      // headingLevel: 2 (06 §12)
EweSummaryLine(...)                                  // key: ewe_card.summary
EarlierAnimalNote(...)                               // T05, when it applies
ShedSectionHeading(l10n.eweCardSeason(label: '2026 lambing'))   // headingLevel: 2
…rows…
ShedSectionHeading(l10n.eweCardSeason(label: '2025 lambing'))
…rows…

// WRONG on 3.44 — compiles, passes review, does nothing on either platform:
//   Semantics(header: true, child: Text(...))
```

```dart
// test/support/harness.dart — ONE row added to the table declared once here.
final kPumpableVariants = <String, Widget Function()>{
  RouteNames.flock:   () => const FlockScreen(),
  RouteNames.eweCard: () => const EweCardScreen(eweId: kSeedEwe),   // ← this task
  // …one row per screen epic (critique S1)
};
```

### 5.3 The details that are easy to get wrong

1. **`Semantics(header: true)` compiles, reads correctly in review, and does nothing.** It is a no-op
   on both platforms as of 3.44 (10 §3.4) and is the single most likely accessibility regression in
   this codebase. `headingLevel` greater than 0 maps to `View.setHeading(true)` on Android and
   `UIAccessibilityTraitHeader` / `accessibilityHeadingLevel` on iOS. The gate row `a11y.header_bool`
   catches it under `lib/`; the review habit is what catches it in a snippet somebody pastes.
2. **The summary heading must come before every timeline row in *tree* order**, not merely exist.
   `sortKey` is banned (`a11y.sort_key`, 10 §11): `OrdinalSortKey` reorders only siblings inside one
   semantics group and misbehaves silently when mixed with unsorted siblings. Build the tree in the
   order you want it read — title, summary heading, summary, disclosure, then the seasons — which is
   also the order Indelible §8 screen 2 draws it.
3. **Two documents disagree about whether the timeline has sub-heads, and the query settles it.**
   10 §3.4's table says the card has *"one flat timeline (`ORDER BY at DESC`), not per-season or
   per-kind sections, so there are no further stops to invent"*; Indelible §8 screen 2 draws
   `SEASON 2026` / `SEASON 2025` / `SEASON 2024` sub-heads with a double rule. The tell is in
   07 §4.1: the statement projects `season` on **all seven arms**, and a flat timeline makes that
   seventh column dead weight. `CLAUDE.md`'s authority order puts `indelible.md` above the thirteen
   engineering documents on what a screen looks like, so:
   - build the sub-heads as Indelible draws them, each emitting `headingLevel: 2`;
   - **amend 10 §3.4's Ewe Card row in this commit**, struck with its reason — N33's semantics gate
     reads that table, and a gate reading a stale table is worse than no gate;
   - name the conflict in the PR body so the owner sees it rather than inheriting it.
   The rows within a group keep `ORDER BY at DESC`; the grouping does not re-sort anything.
4. **Group on the stored `season` FK, never on the year of `at`.** They are not equivalent: a lambing
   on 31 December 2025 recorded inside the *2026 lambing* season belongs to 2026, because the season is
   a column on the row (03 §5.1: *"A season is not a foreign key on `Ewe`… Season scopes the events"*).
   Deriving the group from `LocalDate.of(row.at).year` puts her lambing in the wrong year on the one
   screen built to answer *"what did she do last year?"* — and it does it only for the animals that
   lambed either side of New Year, which is the hardest kind of bug to notice.
5. **`notes.season` is nullable and there is no honest place to put an unseasoned note except its own
   group.** Every other arm's `season` is `NOT NULL` (03 §5.7, §5.9, §7, §5.5, §5.6, §5.8). Folding a
   null into the adjacent season is the app deciding something the shepherd did not — §12.4. Give it
   its own labelled group; place it by its rows' own `at` values so it is not exiled to the bottom of
   a five-season card.
6. **The season sub-head prints `Seasons.label`, not a computed year.** `label` is
   `TEXT NOT NULL CHECK (length(trim(label)) > 0)` and its first-run value is `"<year> lambing"`
   (07 §2.1 step 2) — but the user can rename a season, and printing `year` ignores that. Use the
   label; the ARB message takes it as a placeholder.
7. **The empty state occupies the same box the content will** (06 §12, decision #71). 07 §2.2's copy is
   *"Nothing recorded for 412 yet."* with one action, *"Record a lambing"* — and that action is the
   **same control the populated screen uses**, which on this card is the `RECORD EVENT` word button
   from T06, not a second button that exists only when empty. No illustration, no spinner, no tour.
   The tag in the copy comes through a placeholder alongside the user's term, never concatenated.
8. **Empty and Frame 1 are different states and must not share a widget.** Frame 1 is painted before
   the database is open (decision #21): a fixed-height dark placeholder *at the summary line's exact
   height* (07 §4.2), so nothing shifts when data lands. Empty is a query that returned zero rows.
   Rendering the empty copy during Frame 1 tells a shepherd their records are gone, for one frame,
   every time they open a card.
9. **A ewe with a summary row but no timeline rows is not empty.** She can have a lambing that was
   struck, or a note with no season. Decide *empty* on the timeline being zero-length **and** the
   summary being absent or all-zero — and test the mixed case, because it is the one a
   `rows.isEmpty` check gets wrong.
10. **`kPumpableVariants` is declared once, in `harness.dart`, and this task adds one row.** 12 §6.2:
    four files iterate it — the overflow matrix, the semantics gate, the tap-target gate and
    `contrast_test` — and a table copied four times is four tables that stop agreeing the first time a
    screen is added. Do **not** add a fifteenth variant for the reused-tag or the empty state; those
    are *states* of variant 2, seeded per case. R58 fixes the arithmetic against the variant list, and
    N33-T01's self-check asserts `kPumpableVariants.length == 14`.
11. **The fixtures do not exist for this row's seed.** 12 §6.2's matrix body calls
    `restoreFixture(db, 'flock_400_3seasons.json')`, and the fixtures landed in N23-T05 — so this row
    can use them. What it must **not** do is invent a second seeding path: `kSeedEwe` is the fixture id
    constant `harness.dart` already declares (12 §5.3).
12. **The card wraps at AX5; it does not truncate.** 10 §5: never ellipsise a user's own words — notes
    on the Ewe Card wrap. The matrix pumps this variant at 3 devices × 3 text scales × 2 bold states =
    18 cells, and a fixed-height row anywhere in the card is what makes one of them a `RenderFlex`
    overflow.
13. **`eweCardControllerProvider` holds screen state, never data** (§4.4 rule 1). The timeline is
    `eweTimelineProvider`'s, the summary is `eweSummaryProvider`'s, and the earlier animals are
    `earlierAnimalsProvider`'s. A controller that caches any of them is a fourth copy of the truth,
    and 02 §3.1's `EweCardData` snippet is the demonstration people copy — see T01 §5.3 item 12.
14. **This screen is not a golden.** 12 §8's note names `ewe_card_summary_line` as deliberately not one
    of the eight images: *"covered by the matrix plus the a11y gates."* Adding
    `matchesGoldenFile` here also drags in a macOS runner billed at a 10× multiplier on a job that is
    not supposed to run per-PR (13 §4.2).

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'the summary line is the first heading a screen reader reaches'` | **The anchor.** Heading nodes collected in tree order over a 40-row card; zero non-heading nodes before the summary |
| | `'the card title is headingLevel 1 and every section is headingLevel 2'` | 06 §12's contract for `ShedSectionHeading`, asserted rather than assumed |
| | `'header: true appears nowhere under lib/features/flock/'` | Source-text; duplicates `a11y.header_bool` in the tier a developer runs first |
| | `'sortKey and OrdinalSortKey appear nowhere'` | 10 §11 |
| | `'the timeline is grouped by the stored season, not by the year of the event'` | Seed a lambing on 31 Dec 2025 inside the 2026 season and assert its group |
| | `'a note with no season renders in its own labelled group'` | `notes.season` nullable; §12.4 |
| | `'the season sub-head prints the season label, not a computed year'` | Rename a season and re-pump |
| | `'rows within a season stay in descending event order'` | The grouping does not re-sort |
| | `'a ewe with no records renders the empty state and one action'` | 07 §2.2's copy, and the action being the populated screen's own control |
| | `'a ewe with only a struck lambing is not empty'` | Item 9 — the case `rows.isEmpty` gets wrong |
| | `'Frame 1 renders a fixed-height placeholder, not the empty copy'` | Item 8; decision #21 and #71 |
| | `'the empty state occupies the same height as the loaded summary block'` | 06 §12; a layout shift on every card open |
| | `'no CircularProgressIndicator appears anywhere in the subtree'` | Decision #71, the gate row duplicated locally |
| | `'the card renders at textScale 2.0 with boldText on the smallest device without overflow'` | The matrix covers it; this fails with a readable message |
| | `'popping the card disposes eweCardControllerProvider and eweTimelineProvider'` | `.autoDispose.family` on both |
| | `'typed note text survives a rebuild of the controller'` | §4.4 rule 4 — the private field, not `state` |
| `test/features/overflow_matrix_test.dart` | `'the matrix covers every route, and the count is 14'` | Already exists (N33-T01 owns it). Confirm it still passes with `ewe_card` present, and that the count did **not** change |
| `test/support/harness.dart` | — | One row added. No new file, no second copy of the table |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **`kPumpableVariants` stays at fourteen** — states are seeded, not added as variants (R58).
- **The design system of record is Indelible** — where 10 §3.4 and Indelible §8 disagree about what the
  screen looks like, Indelible wins and the engineering document is amended in the same commit.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the summary line is the first heading a screen reader reaches'` passes, and was seen to fail first for the stated reason
- [ ] the summary line is heading level 1
- [ ] timeline groups are heading level 2
- [ ] `header:` appears nowhere
- [ ] the count stays derived
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the card title is `headingLevel: 1` and the summary is the first `headingLevel: 2`, with zero non-heading nodes before it in tree order
- [ ] the grouping is on the stored `season` FK; a lambing on 31 Dec inside the following season groups correctly
- [ ] a note with no season has its own labelled group and is not folded into a neighbour
- [ ] `sortKey` and `OrdinalSortKey` appear nowhere
- [ ] `kPumpableVariants` has exactly 14 entries and the table is still declared once, in `harness.dart`
- [ ] 10 §3.4's Ewe Card row is amended in this commit, struck with its reason, and the conflict is named in the PR body
- [ ] Frame 1 and Empty are different widgets, and neither is a spinner
- [ ] no `matchesGoldenFile` call was added

> **Reading the first two lines together.** *"The summary line is heading level 1"* is the outcome
> stated from the reader's seat: with the rotor on Headings, the summary is the first thing after the
> screen title. The **levels** are 10 §3.4's — level 1 is the title (*"gimmer 412"*), level 2 is the
> summary and each season sub-head — and 06 §12 fixes them at the component (`ShedSectionHeading`
> emits 2; screen titles emit 1). Both lines describe the same tree; the anchor asserts the tree.

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the matrix — this task is what makes ewe_card one of its rows.
fvm flutter test test/features/ewe_card_test.dart test/features/overflow_matrix_test.dart

# 3. The zone leg, for the season-boundary case.
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. Both gates.
make check
make test
```

```bash
grep -rn "header:" lib/features/flock/                     # expect: nothing
grep -rn "sortKey\|OrdinalSortKey" lib/                    # expect: nothing (a11y.sort_key)
grep -c "() =>" test/support/harness.dart                  # expect: the 14-row table, once
grep -rn "CircularProgressIndicator" lib/features/         # expect: nothing
grep -rn "matchesGoldenFile" test/features/ewe_card_test.dart   # expect: nothing
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): the heading hierarchy and the matrix variant`
