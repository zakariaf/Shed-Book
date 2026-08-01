# N27-T04 — Timeline rows with provenance, and every withdrawal *as entered by you*

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 4 of 7 |
| **Depends on** | N27-T03 |
| **Commit** | one commit · `feat(ewe_card): provenance on every timeline row` |

## 1. Why this task exists

Every event carries its provenance label; every withdrawal carries *as entered by you*.
§12.5 and §12.1 rendered on the one screen where a shepherd reads a whole animal's history back.

This is the task where §12.5 either stays **unrepresentable** or drops to *documented*. R37 put the
quad on all seven of these tables specifically so this screen could be honest, and 07 §1.5 makes the
label mandatory on **every** timeline row — not on the interesting ones. A row that renders `03:21`
with nothing beside it is a review failure (05 §4.3).

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§4.4 (the three §12 disclosures on this screen, stated exactly)** · §1.5 (the disclosure matrix; the §12.5 precondition and R37; the `original_effective` spelling) · §4.1 (the quad is projected on all seven arms) · §4.3 (*Edit a timestamp* — available only where the quad exists) · §15.1 (undo per verb: a voided treatment stays in the medicine book; a foster undo is a compensating event, both visible forever) | which label belongs on which row |
| `docs/engineering/05-domain-correctness.md` | **§4.1 (`RecordedTime`, its three factories, `editedTo`, and `provenanceLabel` as an exhaustive switch that can never be empty)** · §4.2 (the four columns and the two paired CHECKs) · **§4.3 (how it renders: "the provenance label appears in the same visual block as the time. Never a bare `03:21`", and edited times read "03:20 · time edited by you · was 07:00")** · §4.4 (the never-empty test) · §7.4 (`Disclaimers` referenced, never re-typed) | the value type, the three labels, and the rendering rule |
| `docs/design/indelible.md` | **§7.3 (the ruled record row and its six states — Default, Live, Pressed, **Struck**, **Queried**, Unset cell — with the margin cell at 0–68 px carrying the time and the stamp beneath it)** · §6.2 (the six marks: `†` for an edited timestamp, `?` for a self-contradicting record, the strike line) · §6.3 (2 px stroke, butt caps, `currentColor`, 24 or 28 px boxes only) · §8 screen 2 (`07:02 †edited` over `event 03:20 as entered`; struck entries stay at 5.75:1) · §9 safety rule 5 (the margin carries the time **and** its provenance stamp) | what a row looks like, in every state |
| `docs/skills/02-build-manifest.md` | **§4.4 defect 2 (`--t-stamp: 14px` sits under the 18 px floor, and `AUTO-CAPTURED` — "the sole §12.5 provenance label" — is one of exactly three stamps that lose the exemption)** · §4.1 (P2 — no SnackBar; the receipt is the committed row) | the corrected type rule for this screen's most important stamp |
| `docs/engineering/CONVENTIONS.md` | §2.14 (`Disclaimers` — `exportFooter`, `withdrawalProvenance`, `withdrawalCaveat`; referenced, never re-typed), §2.2 (`RecordedTime`, `TimeSource`, and the banned spellings `RecordedTime.captured()` / `Instant.now()`), §2.7 (`WithdrawalPeriod` — `WithdrawalNotRecorded` means **no row**), §4.5 (widget keys), §4.6 (`original_effective`, never `original_effective_at`), §5.4 (dates a human reads are never all-numeric; times are 24-hour `HH:mm`, `en_GB`), R37, R38, R59, R60 | **BINDING** on the strings, the columns and the keys |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules — the spoken label and the visible words agree), §3.3 (`spellOutTag` on the tag range only), §5 (never ellipsise a user's own words), §8.4 rule 4 (a time is passed pre-formatted; `lib/core/ui/formatters.dart` is the one authority), §8.5 (the terminology placeholder) | every label on every row |
| `docs/engineering/06-design-system.md` | §12 (`ShedStatusBadge` — icon **and** word, never colour alone; `ShedAnimalRow`), §6.1 (`tapMin` 60 / `gapMin` 16 — and P9), §5.4–§5.5 (the type scale, tabular figures) | the components the row composes |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 (`Treatments`, `voided_at`; `TreatmentWithdrawals` — **no row implies not recorded**, and `days` has no default), §5.7 / §5.9 / §5.12 / §7 (the quad on the four R37 tables) | where the withdrawal figure comes from, and what its absence means |
| `docs/engineering/12-testing.md` | §2.2 (pin `now` **or** measure elapsed time, never both), §2.3–§2.4 (the ambiguous hour and the tier above the domain tests), §7.4 (the semantics gate) | how the rows are asserted |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | which label belongs on which row |
| `indelible-marks-and-strikes` | the provenance mark and the corrected-entry mark |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'every timeline row renders a provenance label and every withdrawal renders as entered by you'`
- **Why it is red today** — rows render without provenance, which is §12.5 dropped to documented.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on the easy rows. Seed **one of every `TimelineKind`** — all
seven — and iterate `TimelineKind.values` rather than listing three by hand, so an arm added later
inherits the assertion. For each rendered row assert the label is one of
`RecordedTime.provenanceLabel`'s three exact strings and that it is **non-empty**; then seed a
treatment with a `treatment_withdrawals` row and assert `Disclaimers.withdrawalProvenance` appears
beside the figure, by **identity with the constant**, not by matching the text. Matching the text
passes on a re-typed copy, which is the defect `copy.disclaimer_retyped` exists to catch.

**Green.** The minimum code that passes, and nothing beyond it — the labels from `provenanceLabel` and `Disclaimers`, on every row kind.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 6 (the widgets), step 6 item 22 (the ARB) and step 7 (tests).** No schema, no domain, no data
step — the columns arrived in N07 and the statement arrived in T01. One repository edit is needed for
the withdrawal figure, and it is a projection on the statement that already exists. Say the skipped
layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** The `treatment` arm gains three projected columns — `withdrawal_kind`, `withdrawal_days`, `clear_date` — from a `LEFT JOIN treatment_withdrawals`. `readsFrom:` gains `treatmentWithdrawals`, making it **nine** tables. A `LEFT JOIN` is the whole mechanism: **no row means not recorded** (03 §5.8) |
| 2 | `lib/features/flock/ewe_card_controller.dart` | **Edit.** `TimelineRow` gains `withdrawal` — a `WithdrawalPeriod` from `lib/domain/withdrawal/`, so *not recorded* is a **variant**, not a null int |
| 3 | `lib/features/flock/widgets/timeline_record_row.dart` | **New.** Indelible §7.3's ruled record row: the 68 px margin cell (time at 18 px tabular, provenance stamp beneath at the 18 px floor), the spine, the record column, and the four states this screen can be in — Default, Struck, Queried, Unset cell. Key `ewe_card.row.<kind>.<ref>` |
| 4 | `lib/features/flock/widgets/withdrawal_note.dart` | **New.** The figure plus `Disclaimers.withdrawalProvenance`, and the *not recorded* state that is never `0` |
| 5 | `lib/features/flock/ewe_card_screen.dart` | **Edit.** The `ListView` builds real rows |
| 6 | `lib/l10n/app_en.arb` | **Edit.** The per-kind row sentences, the `was <time>` fragment for an edited row, and the struck stamp — each with a `description`, each time pre-formatted |
| 7 | `test/support/seeds.dart` | **Edit.** `seedStruckLambing`, `seedTreatmentWithWithdrawal`, `seedTreatmentWithoutWithdrawal`. `seedEditedLambing` and `seedAutoLambing` already exist |
| 8 | `test/features/ewe_card_test.dart` | **Edit.** The anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/features/flock/ewe_card_controller.dart — TimelineRow gains one field.

  /// Three states, not a nullable int. `WithdrawalNotRecorded` is what a
  /// missing treatment_withdrawals row means (03 §5.8, CONVENTIONS §2.7), and
  /// 0 is a REAL label value — so a nullable int cannot carry the distinction.
  /// Non-treatment rows carry `WithdrawalNotApplicable`… no: they carry
  /// null, because the field is absent, not unrecorded. See §5.3 item 4.
  final WithdrawalPeriod? withdrawal;
```

```dart
// lib/features/flock/widgets/timeline_record_row.dart
//
// Indelible §7.3. The margin cell is 0–68px: the time at --t-margin, and the
// provenance stamp BENEATH it. build-manifest §4.4 defect 2 removes the 14px
// exemption from this stamp specifically, because it is the sole carrier of the
// §12.5 claim — it renders at the 18px floor.

final class TimelineRecordRow extends ConsumerWidget {
  const TimelineRecordRow({required this.row, super.key});
  final TimelineRow row;
}
```

```dart
// The label, and the two things it must never be.
final RecordedTime rt = row.recorded;          // T01 reconstructs it
final String label = rt.provenanceLabel;       // exhaustive switch, never empty

// WRONG — a second implementation of a §12.5 mechanism:
//   final label = row.timeSource == TimeSource.autoCaptured ? 'auto' : 'edited';
// WRONG — a re-typed disclaimer, which copy.disclaimer_retyped catches:
//   const Text('as entered by you')
// RIGHT:
Text(Disclaimers.withdrawalProvenance)
```

### 5.3 The details that are easy to get wrong

1. **`AUTO-CAPTURED` is not an exempt stamp.** Indelible sets `--t-stamp: 14px` and uses it 49 times;
   build-manifest §4.4 defect 2 names exactly three stamps that lose the exemption because each is the
   **sole** carrier of its meaning, and the §12.5 provenance label is one of them. It renders at the
   18 px floor on this screen. Every *other* stamp on the row keeps the exemption. Do not "fix" this
   by shortening the label — the three strings are 05 §4.1's and they are what the export legend and
   the CSV `time_source` column are read against.
2. **The label comes from `RecordedTime.provenanceLabel` and from nowhere else.** It is an exhaustive
   `switch` that can never be empty (05 §4.1) and 05 §4.4 has a test asserting exactly that. A second
   `switch` over `time_source` in a widget is a §12.5 mechanism reimplemented in the layer least likely
   to be reviewed, and it will disagree with the CSV within one release.
3. **An edited row shows *both* times, not a marker.** 05 §4.3: `"03:20 · time edited by you · was
   07:00"`. Indelible §8 screen 2 prints it as `07:02 †edited` over `event 03:20 as entered`. Either
   layout is fine; **omitting the original is not**, because the paired SQL `CHECK`
   (`(time_source = 'edited') = (original_effective IS NOT NULL)`) exists precisely so the pre-edit
   value is always there to show. And per Indelible §6.2 the dagger is *"always accompanied by a
   word"* — never the mark alone.
4. **`WithdrawalPeriod?` on a non-treatment row is `null` because the field does not apply; on a
   treatment row it is never `null`.** A lambing has no withdrawal — that is absence of a concept. A
   treatment with no `treatment_withdrawals` row has `WithdrawalNotRecorded` — that is a recorded
   fact about a live animal and it must render as *not recorded*, never as `0` and never as blank.
   `CONVENTIONS §2.7`: `WithdrawalDays` has a private generative constructor and one entry point,
   `WithdrawalDays.asEnteredByUser`. If you find yourself writing `days ?? 0`, stop.
5. **The `LEFT JOIN` is the mechanism, not a convenience.** 03 §5.8 makes *no row* the storage
   representation of *not recorded*; an `INNER JOIN` silently drops every treatment whose withdrawal
   was not recorded, which is the exact set of rows §12.1 exists to make visible. And
   `readsFrom:` gains `treatmentWithdrawals` — nine tables now — or the card goes stale the moment a
   withdrawal is entered.
6. **`Disclaimers.withdrawalProvenance` is referenced, never re-typed** (decision #62, §12.3's
   mechanism). `test/policy/disclaimer_is_defined_once_test.dart` (N06-T09) asserts the literal appears
   in exactly one file, and the gate row `copy.disclaimer_retyped` scans for it. The test in §4 asserts
   **identity with the constant**, because a text match passes on a copy.
7. **A struck row stays exactly where it is.** Indelible §7.3's **Struck** state: a 3 px `--madder-ink`
   line across the record column at 50 % height, all text dropping from `--ink-full` / `--ink-mid` to
   `--ink-low` (5.75:1 — *"still fully legible, permanently"*), and `STRUCK 03:41` printed in the
   margin. *"The row **stays in position** — it does not move, collapse, or fade."* Sorting struck rows
   to the bottom, collapsing them behind a "show struck" toggle, or fading them below 4.5:1 all
   delete the feature §1.1 rule 1 exists to protect.
8. **The `?` query mark is a real state on this screen and it is not a warning badge.** Indelible §6.2:
   *"the record contradicts itself and I am not going to fix it for you"* — and *"tapping it offers
   exactly two options and never a third"*. On this card the contradiction that can appear is a
   declared birth type disagreeing with the tally (N16-T06's `lambing_consistency` view). Render the
   mark and the underline beneath the offending cell only; do **not** offer a "fix" affordance, and do
   not let the app pick.
9. **Colour is never the only channel** (decision #106, Indelible §2.7). Struck carries a line **and**
   dimmed ink **and** a margin stamp; edited carries a dagger **and** the word; queried carries a mark
   **and** an underline. Read the card under the OS grayscale filter once, by hand, and say so in the
   PR body.
10. **Times are 24-hour `HH:mm`, `en_GB`, and dates a human reads are never all-numeric** (R60,
    §5.4). `11 Mar 2026`, never `11/03/2026`. Formatting happens in
    `lib/core/ui/formatters.dart` — the one `package:intl` site outside `lib/data/` — and the string
    arrives at the ARB message pre-formatted (10 §8.4 rule 4).
11. **The spoken row and the visible row agree on the visible words** (10 §3.2 rule 3, the Voice
    Control criterion). Build each row as **one** semantics node whose label is a complete sentence in
    the order a shepherd would say it, with the tag carrying `SpellOutStringAttribute` on the tag range
    only (10 §3.3). Seven `Text` widgets is seven rotor stops per row and ~80 rows on a five-season
    card.
12. **P9 is open and this row is where it fires.** 06 §6.1 wants `gapMin` 16 between adjacent targets;
    Indelible stacks 64 px ruled rows with a 2 px rule and nothing else. Build the rows as Indelible
    draws them, name P9 in the PR body, and route the ruling to the owner rather than inventing a gap.
13. **P2: there is no SnackBar on this screen or any other.** If a row gains a tap that writes
    anything (T06 adds them), the confirmation is the row re-printing in ink, not an overlay
    (build-manifest §4.1). `showSnackBar(` is banned everywhere including `feedback.dart`.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'every timeline row renders a provenance label and every withdrawal renders as entered by you'` | **The anchor.** Iterates `TimelineKind.values` — all seven — and asserts identity with `Disclaimers.withdrawalProvenance` |
| | `'an auto-captured row reads recorded automatically'` | The first of the three exact strings |
| | `'a deferred entry reads time entered by you'` | The `userEntered` / `userEdited` split — a 07:00 entry for a 03:20 lambing was never wrong |
| | `'an edited row shows both the current time and what it was edited from'` | 05 §4.3. The paired CHECK guarantees the original is there; this asserts it is shown |
| | `'the provenance label renders at 18 px or above'` | build-manifest §4.4 defect 2, as a geometric assertion, not a comment |
| | `'a treatment with no withdrawal row reads not recorded and never 0'` | §12.1's unpersistable mechanism, on the read side |
| | `'a treatment whose withdrawal is not_applicable does not render a day count'` | `WithdrawalNotApplicable` is a third state, not zero days |
| | `'a lambing row renders no withdrawal element at all'` | Absence of the concept vs *not recorded* — the distinction item 4 turns on |
| | `'a struck row stays in position, stays legible and prints STRUCK with its time'` | Indelible §7.3. Assert the index in the list, not just the presence |
| | `'a voided treatment renders struck and keeps its withdrawal figure'` | Soft-void (decision #69): the medicine book keeps it, and the clear date it told the user is still the fact |
| | `'a contradicting lambing renders the query mark and offers exactly two options'` | Indelible §6.2, both halves — including "never a third" |
| | `'no row renders a bare time'` | The negative, over every row: assert no rendered `HH:mm` string exists without a label in the same node |
| | `'each row is one semantics node whose label contains the visible words'` | 10 §3.2 rule 3. The Voice Control criterion, asserted character-for-character |
| | `'the card renders identically with every colour token collapsed to grey'` | Decision #106. A programmatic stand-in for the by-hand grayscale read |
| | `'the disclaimer string appears as a literal in exactly one file'` | Duplicates N06-T09 deliberately, in the tier a developer runs first |
| `test/features/ewe_card_dst_test.dart` | `@Tags(['uk-zone'])` · `'a lambing edited from 07:00 to 01:30 on 25 October 2026 shows both times and the label'` | The ambiguous hour on the edit path — the one place the pre-edit and post-edit values can be the same wall time and different instants |
| | `'a lambing entered at 01:30 on 25 October 2026 renders 01:30 and time entered by you'` | 12 §2.3's DST-2, one tier up: the wall time round-trips through SQLite and reaches the widget |

## 6. Constraints that bind this task

- **§12.5, held at *unrepresentable* — and this is the task where it either stays there or drops to *documented*.** R37 put the provenance quad on all seven of these tables precisely so this screen could be honest, and 07 §1.5 makes the label mandatory on **every** timeline row, not on the interesting ones. A row that renders `03:21` with nothing beside it is a review failure (05 §4.3). §12.1 rides on every withdrawal row — *as entered by you*, referenced from `Disclaimers` and never re-typed here.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every timeline row renders a provenance label and every withdrawal renders as entered by you'` passes, and was seen to fail first for the stated reason
- [ ] no row renders without a provenance label
- [ ] corrected rows show both times
- [ ] struck rows are visible and marked
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the label comes from `RecordedTime.provenanceLabel`; `grep -rn "time_source\|timeSource" lib/features/` shows no second switch
- [ ] the provenance stamp meets the 18 px floor (build-manifest §4.4 defect 2), and every other stamp keeps its exemption
- [ ] `Disclaimers.withdrawalProvenance` is referenced, not re-typed, and the test asserts identity with the constant
- [ ] a treatment with no withdrawal row reads *not recorded* — never `0`, never blank
- [ ] `readsFrom:` now names **nine** tables
- [ ] struck rows keep their position and stay at or above 5.75:1; no "show struck" toggle exists
- [ ] the card has been read once under the OS grayscale filter, by hand, and it is stated in the PR body
- [ ] P9 is named in the PR body and no gap was invented

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the zone leg.
fvm flutter test test/features/ewe_card_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. The disclaimer is still defined once.
fvm flutter test test/policy/disclaimer_is_defined_once_test.dart

# 4. Both gates.
make check
make test
```

```bash
grep -rn "as entered by you" lib/ --include=*.dart --include=*.arb   # expect: disclaimers.dart only
grep -rn "recorded automatically\|time entered by you\|time edited by you" lib/features/  # expect: nothing
grep -n "readsFrom" lib/data/flock_repository.dart                   # expect: nine tables
grep -rn "days ?? 0\|withdrawalDays ?? 0" lib/                       # expect: nothing
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): provenance on every timeline row`
