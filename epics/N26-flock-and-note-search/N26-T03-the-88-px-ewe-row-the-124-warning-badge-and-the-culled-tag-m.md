# N26-T03 — The 88 px ewe row, the §12.4 warning badge and the culled-tag marker

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 3 of 7 |
| **Depends on** | N26-T02 |
| **Commit** | one commit · `feat(flock): the ewe row with the warning badge and culled marker` |

## 1. Why this task exists

The row over `ShedAnimalRow`, with the §12.4 warning badge — a ewe whose records contradict
themselves says so in the list — and the culled-tag marker, which is what makes the active-only
uniqueness ruling legible: 412 is here twice, and one of them is gone.

It also carries **ruling N2**. `07 §3.1` ends its statement with `WHERE e.status = 'active'`;
Indelible §7.4's **Struck** state says *"She stays in the list, at the bottom, under a printed line
reading `STRUCK — 1`."* Both cannot ship, and this task's own Definition of Done — *a culled tag is
visibly distinct from an active one with the same number* — is **unsatisfiable** if the culled row is
never rendered. That is the strongest argument on the table and it belongs in the ruling.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | **§7.4 (the ewe row: 88 px, 2 px `--rule` bottom border, the fixed 76 px tag column ending at x=152, the 18 px summary line, the trailing state word + figure — and all four states: Default, Pressed, Warning, Struck)** · §7.7 (the stamp: **boxed** = a state of the animal, **unboxed** = a note about the record) · **§2.7 (how status is encoded without colour — the Contradiction, Struck, Under-withdrawal and Last-day rows)** · **§6.2 (the six marks: the dagger `†`, the query mark `?`, the strike line; *"no new mark may be added without deleting one"*)** · §3.4–§3.5 (`--t-tag` 32 px tabular; the fixed three-character right-aligned column) · §4.3–§4.4 (the spine at x=68, the 68 px margin cell, row heights) · §8 Screen 1 (the eight sample rows and their trailing words) | every pixel, mark, ink and state of the row |
| `docs/engineering/07-screens.md` | **§3.1** (*"There is no `warning_count` column and there never will be"*; `has_warning` reads the `lambing_consistency` **view**; the `WHERE e.status = 'active'` half of ruling N2) · **§3.2** (the Loaded state: *"tag (32 pt tabular) · summary line (18 pt, assembled in Dart from the counts) · status chips (icon + text, never colour alone)"*) · **§3.4** (*"Only §12.4: a small persistent badge on any row whose records carry warnings, so a contradiction found at 3am is still findable at 9am. The badge is icon + count, never colour alone"*) · §1.5 (the §12 disclosure matrix — Flock gets §12.4 and nothing else) | what the row shows, and the other half of ruling N2 |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`lambing_consistency` — the view body, and why `declared = 5` is not a mismatch) · §5.13 (`ewe_summaries` stores **counts only**; the sentence is assembled in Dart) · **§6 (tag uniqueness: culling is what releases a tag; the two animals are two animals; *"It is a link, never a merge offer"*)** · §5.2 (`ewes.status` CHECK: `active`, `sold`, `dead`, `culled`) | what the marks mean and what the summary line is made of |
| `docs/engineering/CONVENTIONS.md` | §2.6 (`Warning`, `WarningCode`'s eleven members, `Reviewed<T>` — **no `fix()`, no `corrected`, no callback**) · §2.11 (`ShedTokens`, `context.tokens`) · §4.5 (widget keys, `<screen>.<element>[.<qualifier>]`) · §5.1 (*warning*, never *flag*; *tag*, never *number*) · **R41** (`ewes.status` stays a mutable column; there is no status-history table; *"07 strikes 'a history row'"*) · R53 (warnings are populated by the controller, never by a repository) · R60 (no human-facing date is all-numeric) | the words, the keys and where a warning may come from |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60 / `tapPrimary` 72 / `gapMin` 16) · §6.2 (`ShedTapTarget`; *"a 32 pt glyph can sit inside an 88 pt hit region"*) · **§12** (`ShedAnimalRow` ≥ `tapPrimary` tall, *"Tag `displaySmall` tabular + one summary line"*; `ShedStatusBadge` *"Icon **and** word, always. Never colour alone"*) · §5.4 (tabular figures) | the shared components this row composes |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.3 (`spellOutTag` — the tag range only; *"an off-by-one here spells out half the sentence and nobody notices without a device"*)** · §3.2 (the eight label rules) · §5.1–§5.2 (colour is never the only channel; the redundancy table) · §4.4 (**`FittedBox` is banned around user-facing text**) · §8.5 (the terminology-placeholder rule) · §9.2 (never render an all-numeric date to a human) | what the row says rather than shows |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`'s `palette` and `highContrast` arguments) · §7.4 (the house semantics rule) · §11.5 (the fixture carries *"at least one culled ewe whose tag a live ewe reuses"* and *"at least one contradictory lambing"*) | the two fixture shapes this task depends on |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #54 (a warning cannot be persisted) · #96/#106 (colour is never the only channel) · #99 (never clamp text scale) · #108 (no all-numeric human date) · §7.0 ruling 7 (tags unique among **active** animals only) | the decisions the row applies |
| `shed-book-spec.md` | §7.7 · **§12.4** (never silently correct a user's entry) | the rule the mark exists to satisfy |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the badge, the marker and the colour-never-alone rule |
| `indelible-page-and-screens` | the 88 px row and its sub-grid |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/flock_test.dart`
- **Test** — `'a ewe with a contradiction renders the warning badge with a word as well as a mark'`
- **Why it is red today** — the list renders no state at all.

```bash
fvm flutter test test/features/flock_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on a coloured pixel. Restore
`flock_400_3seasons.json` — `12 §11.5` guarantees it carries *"at least one contradictory lambing"* —
find that ewe's row, and assert three things:

1. The row contains a **word**, from the ARB, in the semantics tree — not only a glyph. `07 §3.4` and
   Indelible §2.7's Contradiction row both require a word; `06 §12`'s `ShedStatusBadge` is *"Icon
   **and** word, always."*
2. The row contains the `?` query mark in the **margin cell**, and the mark's box is inside the
   68 × 64 margin target (Indelible §4.5, §6.2 mark 3).
3. **Rendering the same row at `ShedPaletteId.deepRed` produces the same word and the same mark.**
   Red-shift removes the hue channel; if the assertion passes only in `night`, the row is encoding
   state in colour. `12 §5.1` gives `pumpApp` the `palette` argument for exactly this.

**Green.** The minimum code that passes, and nothing beyond it — the row, the badge, the marker, each with two non-colour channels.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1–5 are skipped and the commit message says so.** This is a UI + ARB + tests task: the facts
are already on `FlockRow` from T01 and T02, and this task renders them. The one non-UI file is the
document ruling N2 amends.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/flock/widgets/flock_row.dart` | **New.** `FlockRowTile` over `ShedAnimalRow` — the 88 px ruled row, the 76 px right-aligned tag column, the assembled summary line, the trailing state word and figure, and the four Indelible §7.4 states |
| 2 | `lib/features/flock/widgets/flock_summary_line.dart` | **New.** `flockSummaryLine(FlockRow, Terminology, WeightUnit)` — the pure assembly of *"3 seasons · avg 2.0 · assisted twice"* from `ewe_summaries` **counts**, with the terminology overlay and `en_GB` applied. A top-level function, not a widget, because T07's matrix and N27's card both call it |
| 3 | `lib/features/flock/flock_screen.dart` | **Edit.** Render `FlockRowTile`; if ruling N2 keeps struck ewes, insert the printed `STRUCK — n` separator line between the active block and the struck block |
| 4 | `lib/features/flock/flock_controller.dart` | **Edit.** Compute the row's `List<Warning>` **here** — R53: *"`WriteCommitted.warnings` is populated by the controller, never by a repository."* `hasWarning` is a boolean from a view; the `Warning` value with its message is Dart's |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The warning word, the struck stamp, the struck separator line, and the six trailing state words (`PENNED`, `TO LAMB`, `BARREN`, `WITHDRAWAL`, `LAMBED`, `STRUCK`), each with a `description`. The summary line's fragments are placeholder-bearing messages (`10 §8.5`) |
| 6 | `docs/engineering/07-screens.md` §3.1 **or** `docs/design/indelible.md` §7.4 | **Edit — ruling N2.** Whichever loses. `00-README` §10: the losing document is amended **in the same commit**, with the reason stated. Do not amend both and do not amend neither |
| 7 | `test/features/flock_test.dart` | **Edit.** The anchor and the row cases in §5.4 |
| 8 | `test/design/contrast_test.dart` | **Edit, only if N2 keeps struck rows.** `--ink-low` on a struck row measures 5.75:1 (Indelible §7.3) and must stay above 4.5:1 in all three palettes |

### 5.2 The signatures

The row, built from Indelible §7.4's geometry, with every number coming from `context.tokens`:

```dart
// lib/features/flock/widgets/flock_row.dart
/// Indelible §7.4. Full width, 88 px, 2 px `--rule` bottom border only — rows
/// share edges; there is no top border and no gap, because the ruling is
/// continuous, like a ledger.
///
/// Layout: margin cell 0–68 · spine at x=68 · tag right-aligned in a 76 px
/// column ending at x=152 · summary line beneath at 18 px · trailing column
/// right-aligned: the state as a WORD at 19 px caps, plus a figure at 32 px
/// tabular where there is one (`31h`, `9d`).
///
/// Every number here is `context.tokens.<name>`. A raw `Color(0x…)` or a magic
/// size is a build-breaking defect (00-README §8 step 18); `token.raw_color`
/// and the magic-size rows are gate rows, not review items.
class FlockRowTile extends StatelessWidget {
  const FlockRowTile({
    super.key,
    required this.row,
    required this.warnings,     // computed by the controller (R53), never by the repository
    required this.today,        // LocalDate, from the widget's ticker watch (T02)
    required this.onTap,
  });

  final FlockRow row;
  final List<Warning> warnings;
  final LocalDate today;
  final VoidCallback onTap;
}
```

The four states, one per Indelible §7.4 row, each with **two** non-colour channels:

| State | Channel 1 — a word | Channel 2 — a mark | Channel 3 — geometry | Colour |
|---|---|---|---|---|
| **Default** | the trailing state word | — | — | none |
| **Pressed** | — | — | fill `--row-pressed`, 40 ms | none |
| **Warning** (over threshold / last withdrawal day) | the trailing word plus its figure | `†` in the margin cell | the trailing figure lifts `--ink-mid` → `--ink-full`; a **doubled** 2 px rule replaces the single rule beneath the row | `--madder-ink` dagger only |
| **Contradiction** (§12.4) | the warning word, from the ARB | `?` at 28 px in the margin cell | a 2 px underline under the offending cell | `--madder-ink` |
| **Struck** (culled / sold / dead) | `STRUCK 12 MAR` in the margin, unboxed | a 3 px line through the record column at 50 % height | all row text drops to `--ink-low`; the row **stays in position** | `--madder-ink` line |

The summary line, assembled from counts and never stored:

```dart
// lib/features/flock/widgets/flock_summary_line.dart
/// 03 §5.13 and 07 §3.1: ewe_summaries stores COUNTS ONLY. "3 seasons · avg 2.0
/// · assisted twice" is assembled HERE, in Dart, with the terminology overlay
/// and the locale applied — "a formatted string in the database would freeze
/// both".
///
/// Returns the ARB-composed sentence, or the "not recorded" line when the
/// summary row is absent. NEVER `?? 0`: decision #58 makes an unknown
/// statistic a reason, not a zero.
String flockSummaryLine(FlockRow row, AppLocalizations l10n);
```

The tag's semantics, which is the one place an off-by-one is invisible without a device:

```dart
/// 10 §3.3: spell out the TAG range only, wherever it sits in the sentence.
/// "gimmer, four one two", never "g-i-m-m-e-r", and never
/// "four hundred and twelve" — 412 is what is printed on the tag and what the
/// shepherd says.
///
/// Through `attributedLabel:`, NEVER `label:`. A `label:` beside an
/// `attributedLabel:` silently wins on some platforms and the spelling is lost.
Semantics(
  attributedLabel: spellOutTag(sentence, row.tag),
  button: true,
  onTap: onTap,
  child: …,
)
```

### 5.3 The details that are easy to get wrong

- **Ruling N2 is a whole-list question, not a row question, and it must be ruled here.** `07 §3.1`
  filters to active; Indelible §7.4 keeps the struck ewe at the bottom under a printed `STRUCK — 1`
  rule; Indelible §1.2's own tie-breaker is that this system *does not erase* — §11's strike test says
  *"the only legal hits are Settings' two season-level actions."* Against that, `07 §3.2`'s empty copy
  is *"No animals yet."* and its filter set has no *struck* filter. **State both sides, rule it, amend
  the loser in this commit.** If you cannot rule it, carry it into the PR body with both citations.
  Whatever the outcome, `03 §6`'s partial unique index is untouched.
- **`ewes.status` has four values, and only one of them is `culled`.** The CHECK is
  `('active','sold','dead','culled')`. Indelible calls the state *struck*, `03` stores four keys, and
  the trailing word must say which — *SOLD* and *DEAD* are different facts from *CULLED*, and merging
  them into one word is the kind of quiet lossiness `CONVENTIONS §5.1` exists to stop (see the
  `unattributed` row).
- **There is no status-history table, and the row must not imply one.** R41: *"07 strikes 'a history
  row' and 'correction-forward with a history row' from §4.3 and §15.1"*; `ewes.status` is a mutable
  column with `updated_at` moving. So `STRUCK 12 MAR` renders `updated_at`, and its accuracy is
  exactly as good as *"the last time anything about this ewe changed"* — which is **not** the same as
  *"the date she was culled"*. Either label it honestly or omit the date; do not invent a provenance
  the schema cannot support. R41's own escalation note says the retention story may one day need
  `ewe_status_events`, *"and it must land before the first snapshot"* — that snapshot is taken.
- **The `?` and the `†` are different marks and mean different things.** Indelible §6.2: `?` is *"the
  record contradicts itself and I am not going to fix it for you"*; `†` is *"look at this"* — an edited
  timestamp, a pen over threshold, a withdrawal on its last day. A contradiction is not a threshold.
  Using one for both loses the distinction that makes the margin column readable, and **§6.2's budget
  is six marks: *"no new mark may be added without deleting one."***
- **`has_warning` is a boolean from a view; the `Warning` value is Dart's.** R53 and decision #54: a
  warning *cannot* be persisted because there is nowhere to persist it, and `lib/data/` may not import
  `lib/domain/validation/` at all. The controller constructs `Warning(WarningCode.birthTypeLambCountMismatch, …)`
  from the boolean plus the counts; the repository never does. There is no `warning_count` column *"and
  there never will be"*.
- **Tapping the `?` offers exactly two options and never a third.** Indelible §6.2 mark 3. §12.4 is
  *never silently correct a user's entry*: the two options are *keep both numbers* and *open the
  lambing to change one yourself*. A third — *"fix it for me"* — is the rule's negation, and `Warning`
  has **no `fix()`, no `corrected` and no callback** so it is unconstructible. Do not add one.
- **The tag column is right-aligned in a **fixed** 76 px column, and this is not a preference.**
  Indelible §3.5 item 4: *"Right-alignment of the tag column is not a preference, it is the reason the
  left column works"* — `12`, `77` and `91` sit under the units of `412`, `128` and `305`, so the eye
  runs straight down the numerals with no zig-zag. Left-aligning it, or letting the column size to
  content, breaks the page at exactly the scanning task the screen exists for.
- **Tabular figures, and `FittedBox` is banned.** `06 §5.4` and `10 §4.4`: *"shrinking a tag number to
  fit is the opposite of legible."* At 200 % text scale the row grows to 156 px (Indelible §3.6's
  table) — that is what T07's matrix cells prove, and the fix for an overflow is the layout, never a
  `FittedBox` and never a clamp (decision #99).
- **The 88 px row is one tap target, and the margin cell is a second one inside it.** `06 §6.2`: *"a
  32 pt glyph can sit inside an 88 pt hit region."* Indelible §4.5 makes the 68 × 64 margin cell *"itself
  a target"*, and §7.7 says stamps are not targets *"except the margin stamp, whose target is the whole
  68 × 64 margin cell."* Two nested `ShedTapTarget`s need `HitTestBehavior.opaque` on both and an
  explicit ordering, or the inner one is unreachable.
- **`gapDestructive` does not apply here and `gapMin` does.** There is no destructive action on a flock
  row — `setStatus` is T04's, from the ewe's own surface, and `06 §6.2` puts destructive targets *"on a
  different screen edge, behind a confirm, at `gapDestructive` minimum."*
- **`spellOutTag` is applied through `attributedLabel:` and covers the tag only.** `10 §3.3` gives the
  four cases to test, including *"a tag that is also a substring of the term"* — a shepherd whose term
  is *"ewe 1"* and whose tag is `1` is the case that finds the off-by-one.
- **The label uses the user's noun.** `10 §3.2` rule 8 and §8.5: *"If the shepherd calls her a theave,
  TalkBack says 'theave 412'."* The noun arrives from `terminologyProvider` as a **placeholder**; a
  hard-coded *ewe* in an ARB message is a `copy.*` gate failure.
- **`STRUCK 12 MAR` is `d MMM y`, never `12/03/2026`.** R60 and decision #108. Numeric dates exist only
  inside CSV, beside an ISO-8601 column.
- **The row renders no event time, and that is the whole of §12.5 on this screen.** `07 §3.4`: *"No
  §12.1 and no §12.5 label appears here: the Flock row shows no withdrawal figure and no event time.
  The summary line is a count, not a time."* The `31h` figure is an elapsed **duration**, which is not
  an event time and carries no provenance label. If any part of this row renders an `HH:mm`, it is a
  review stop.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| features | `'a ewe with a contradiction renders the warning badge with a word as well as a mark'` | **The anchor.** The fixture's contradictory lambing; a word from the ARB in the semantics tree, a `?` inside the 68 × 64 margin target, and the same assertion passing at `ShedPaletteId.deepRed` |
| features | `'a ewe with a contradiction renders no fix affordance'` | §12.4 as geometry. Tapping the `?` offers exactly two options, and neither of them mutates a record |
| features | `'the warning mark and the dagger are different marks'` | One ewe over the pen threshold, one ewe with a contradiction; the two rows carry `†` and `?` respectively and never the same glyph |
| features | `'a culled tag is visibly distinct from an active one with the same number'` | The fixture's reused tag. Two rows, two `EweId`s, two renderings — the struck one struck. **This is ruling N2's executable form** |
| features | `'a struck row stays in position and does not move, collapse or fade'` | Indelible §7.4. Assert the `Rect` before and after a rebuild |
| features | `'the tag column is right-aligned at a fixed width across 12, 77, 412 and 1284'` | Indelible §3.5. The four tags' right edges are equal; a 4-digit tag does not widen the column for the others |
| features | `'the summary line is assembled from ewe_summaries counts and is not a stored string'` | `03 §5.13`. Change a count in the database and expect the sentence to change without a code path that reads a text column |
| features | `'a ewe with no ewe_summaries row renders the not-recorded line, not 0 seasons'` | Decision #58, again at the render edge |
| features | `'the tag is spelled out and the term is not'` | `10 §3.3`. `attributedLabel` carries a `SpellOutStringAttribute` whose range is exactly `tag.length`; assert the four cases, including a tag that is a substring of the term |
| features | `'the semantic label uses the terminology term, not a hard-coded ewe'` | Override `terminologyProvider` to *gimmer*; the label reads *gimmer 412* |
| features | `'no row renders an HH:mm'` | `07 §3.4`. Source-and-render assertion: the rendered text of every row matches no `\d{2}:\d{2}` |
| features | `'the row is 88 high at scale 1.0 and grows rather than clipping at 2.0'` | Indelible §4.4 and §3.6. No `FittedBox`, no overflow, no clamp |
| features | `'every row and every margin cell meets the 60 pt floor'` | `06 §6.1`, on the laid-out `Rect`s, at `Device.small` |
| features | `'the row renders identically at every entitlement state'` | Decision #90. `setEntitlement` both ways; the frames are identical and `FakePurchaseService.calls` is empty |
| features · **`@Tags(['uk-zone'])`** | `'a withdrawal on its last day carries the dagger at 01:30 and at 01:30 again'` | `TZ=Europe/London`, `withClock` at **01:30** on the clocks-back night, evaluated twice. Indelible §2.7's *Last day of withdrawal* row is `†` + one tally mark; the mark must not appear, disappear and reappear across the repeated hour |
| features · **`@Tags(['uk-zone'])`** | `'STRUCK renders d MMM y on the clocks-back night and never an all-numeric date'` | R60. `TZ=Europe/London`, 01:30; the rendered margin text matches `\d{1,2} [A-Z][a-z]{2} \d{4}` and matches no `\d{2}/\d{2}/\d{4}` |
| design | `'--ink-low on a struck row measures at least 4.5:1 in all three palettes'` | Only if N2 keeps struck rows. Indelible §7.3 claims 5.75:1; the contrast sweep is where a claim becomes a fact |

### 5.5 What this task deliberately does not build

- **Navigation from the row.** N27-T01. `onTap` calls `touchEwe` (T01) and returns.
- **`setStatus` and the `EweStatus` enum.** T04. This task renders a `status` string that the fixture
  already carries; T04 gives it a type and a verb.
- **The *"An earlier animal also used tag 412"* disclosure row.** `03 §6` item 3 puts it on the **ewe
  card**, fed by `earlierAnimalsWithTag`, and it is **N27-T05**. This row shows that two 412s exist; the
  card explains it. *"It is a link, never a merge offer."*

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 60 × 60 pt with ≥ 16 pt separation (`06 §6.1`; Indelible's smallest target is 64 × 64), 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Here specifically: **warning**, never *flag*, *issue* or *validation error* (R71).
- **Safety rule §12.4, as a mechanism** — *never silently correct a user's entry*. `CLAUDE.md` places it
  at *unrepresentable + unpersistable*: `Warning`/`Reviewed<T>` have no writer and no `fix()`, there is
  **no `warnings` column**, and `lib/data/` may not import `lib/domain/validation/` at all. A row that
  offers to reconcile the two numbers drops the rule to *documented*, which is deletion.
- **Colour is never the only channel** — decision #106, `10 §5.1`, Indelible §2.7. Every state on this
  row carries a word **and** a mark or a geometry change, and the anchor proves it in `deepRed`.

## 7. Definition of Done

- [ ] `'a ewe with a contradiction renders the warning badge with a word as well as a mark'` passes, and was seen to fail first for the stated reason
- [ ] 88 px rows
- [ ] the badge carries a word
- [ ] a culled tag is visibly distinct from an active one with the same number
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **ruling N2 is closed by an amendment to `07 §3.1` or to `indelible.md` §7.4 in this commit — exactly one of them — or carried into the PR body as open with both sides cited**
- [ ] the anchor passes at `ShedPaletteId.deepRed` as well as at `night`
- [ ] `?` and `†` are used for different states and no seventh mark is introduced (Indelible §6.2)
- [ ] tapping the `?` offers exactly two options and neither mutates a record
- [ ] the `Warning` values are constructed in the controller (R53); no `warnings` column, no `fix()`, no `corrected`
- [ ] the tag column is right-aligned at a fixed width and does not resize for a four-digit tag
- [ ] `spellOutTag` is used through `attributedLabel:` and its range covers the tag only
- [ ] no row renders an `HH:mm`; no human-facing date is all-numeric (R60)
- [ ] no `FittedBox` and no `textScaler` clamp anywhere in the diff
- [ ] the row renders identically at every entitlement state, and `FakePurchaseService.calls` stays empty

## 8. Verification

```bash
fvm flutter test test/features/flock_test.dart
make check
make test
```

```bash
fvm flutter test test/design/contrast_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/flock_test.dart --plain-name 'culled tag'
```

```bash
grep -rn "Color(0x\|Colors\." lib/features/flock/            # expect zero (token.raw_color)
grep -rn "FittedBox\|textScaleFactor\|TextScaler(" lib/       # expect zero
grep -rn "warning_count\|warningCount" lib/ test/             # expect zero (decision #54)
grep -rn "\.fix()\|corrected" lib/domain/validation/          # expect zero
grep -rn "label:" lib/features/flock/widgets/flock_row.dart   # expect attributedLabel only on the tag
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/features/flock/   # expect zero
git diff main -- docs/engineering/07-screens.md docs/design/indelible.md      # exactly one amended
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): the ewe row with the warning badge and culled marker`
