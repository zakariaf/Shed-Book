# N20-T05 — `voidTreatment` — a soft void the medicine book still shows

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 5 of 7 |
| **Depends on** | N20-T04 |
| **Commit** | one commit · `feat(treatments): voidTreatment as a soft, visible strike` |

## 1. Why this task exists

A treatment may already have been printed and handed to a vet, so a void is **soft**: the
row is struck (P1's columns), the medicine book still shows it, and the strike is visible. Deleting it
would make the paper and the phone disagree, which is worse than either being wrong alone.

The second half is harder than the first and is where this task earns its keep: a voided treatment
must leave every *is she clear?* surface **without** the app claiming the animal is clear. Voiding is
evidence that the **record** was wrong, not evidence that the animal was never treated (05 §3.10
path 3), and the app makes no claim either way.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§3.10 path 3** (the whole rule: every countdown and clear-date query filters `voided_at IS NULL`; the withdrawal row, its inputs and its stored `clear_date` are **never** deleted, blanked or recalculated; the book shows the treatment struck with its void date, still carrying the figure it was saved with; and *"the app makes no claim either way and shows both facts"*), §3.8 (nothing but a user action writes a new `clear_date`) | the verb, and the four things it must not touch |
| `docs/engineering/07-screens.md` | **§15.1** (undo for `recordTreatment` **is** the soft void — *"sets `voided_at`"*, visible afterwards as *"the row, struck through, in the medicine book"*), §15.3 (the label is **"Void this"**, not *Undo*, because the record does not disappear — that is what `SaveReceipt.undoLabel` exists for), §15.4 (no undo affordance is ever reconstructed from storage), §10.3 (the book row: *"including voided ones shown struck through with `voided 5 Mar 2026`"*) | the verb's place in the undo table and the word on the control |
| `docs/design/indelible.md` | **§2.7** (the *Struck entry* row: a word in the margin, a **3 px line through the row**, text dropping to `--ink-low`, the line and stamp in `--madder-ink` — three channels, one of them colour), §5.1 (`--motion-strike`, the only animation with a direction — 180 ms left to right), §6.2 mark 5 (the strike line), §1.2 Rule 1 (*"nothing is ever removed, only struck"*), §7.4 (the struck row stays in the list at full legibility), §8 screen 12 (**the only two honest deletes in the product, and this is not one of them**) | what a strike looks like and what it may never become |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 (`voidedAt` as a nullable `Instant`; and `mixin Identified` carrying P1's `struck` / `struck_at`), §2 convention 2 (a ewe with treatments is a record someone may show a vet) | the column, and the ruling this task must read first |
| `docs/engineering/09-export-formats.md` | **§3.3** (rows: *"every `treatments` row in the season, **including voided ones**"*; columns 27–28 `is_voided` / `voided_at_utc`), §5 (the medicine record PDF: *"a voided treatment renders with a strike-through and a `VOID <d MMM y>` marker in the Note column. **The row is never removed.**"*) | what N21 will read out of this column, and the word it prints |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`Future<WriteOutcome> voidTreatment(TreatmentId id)` — the published signature), §2.11 + **R31** (`SaveReceipt.undoLabel` — *"Void this" on a treatment*), §4.5 + R59 (keys), §5.1–§5.3 (the vocabulary), R23 | the signature, the label and the words |
| `docs/skills/02-build-manifest.md` | **§4.1 (P2)** (undo is a **time-boxed strike affordance in the row's own margin**, its window **stated in seconds**, never in terms of a widget's lifetime; there is no SnackBar to dismiss) | what the undo affordance actually is, now that the SnackBar is gone |
| `epics/N00-decisions-rulings-and-the-calendar/N00-T05-rule-p1-struck-struck-at-on-every-table.md` | question **e** | whether a treatment is *voided* or *struck*, and which columns carry it |
| `docs/engineering/12-testing.md` | §2.4 (the ambiguous hour), §3.1 (`testDatabase()`), §5 (`pumpApp`) | the tests |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the strike, its rendering and its permanence |
| `shed-withdrawal` | what a void means for a live withdrawal countdown |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/treatments_test.dart`
- **Test** — `'a voided treatment is struck, still present, and still exported'`
- **Assertion, spelled out** — seed a treatment with a 28-day meat withdrawal; capture its
  `clear_date` and its `days` **before** the void; call `voidTreatment`; then assert five things in
  order: the `treatments` row still exists and its `voidedAt` is not null; the
  `treatment_withdrawals` row still exists with **the same `days` and the same `clear_date`** as
  before; the book mode still finds the row and it renders `VOIDED` with a date in `d MMM y`; the
  countdown mode does **not** find it; and no copy anywhere on the screen says the animal is clear.
  The last two are one property with two halves — leaving the countdown is not the same as claiming
  a negative.
- **Why it is red today** — nothing voids a treatment, and the obvious implementation deletes the row.

```bash
fvm flutter test test/features/treatments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the soft void over `struck` / `struck_at`, the strike rendering, and the medicine-book
read-back.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3, 5, 6 and 7. **Steps 1, 2 and 4 are skipped and the commit message says so**:
the column shipped in N07-T05, the domain has no opinion about a void, and no new provider is needed.

**Read `CONVENTIONS` §6's P1 ruling before you write a line.** N00-T05 question **e** had to decide
whether a treatment's void *is* the strike or sits beside it: `treatments` already carries
`voided_at` (decision #69) and `mixin Identified` now carries `struck` / `struck_at`, and two columns
meaning *this record was wrong* on one table is exactly the duplication `CONVENTIONS` §5 exists to
prevent. Everything below is written for the second shape — `voided_at` stays, because `03` §5.8 and
`09` §3.3's columns 27–28 both ship it and the CSV names are frozen by the export contract. **If the
ruling went the other way, the column names change and nothing else in this task does.**

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/data/treatment_repository.dart` | edit | `voidTreatment(TreatmentId)` — one `UPDATE`, one `appNow()`, one transaction. It is the only write in the project that changes an existing treatment row |
| 2 | `lib/features/treatments/treatment_write_controller.dart` | edit | `voidTreatment(TreatmentId)` through `guard()`, and the `SaveReceipt` whose `undoLabel` is **"Void this"** (R31) |
| 3 | `lib/features/treatments/widgets/treatment_row.dart` | edit | The struck rendering: the margin word, the 3 px line, the drop to `--ink-low`, and the 180 ms left-to-right `--motion-strike` draw honouring `prefersReducedMotion` |
| 4 | `lib/features/treatments/treatments_screen.dart` | edit | The strike affordance in the row's own margin, keyed `treatment.void.<id>`, live for the window in §5.3 item 5 |
| 5 | `lib/l10n/app_en.arb` | edit | `treatmentVoidThis`, `treatmentVoided`, `treatmentVoidedNoClaim` — each with a `description`. The third is the honest line in §5.3 item 3 |
| 6 | `docs/engineering/07-screens.md` §15.2 | edit | The undo window, **stated in seconds**. §15.2 currently reads *"until the SnackBar is dismissed"*, which P2 deleted |
| 7 | `test/features/treatments_test.dart` | edit | the anchor plus the cases in §5.4 |
| 8 | `test/data/treatment_repository_test.dart` | edit | the four data-tier cases in §5.4 |

### 5.2 The signatures

```dart
// lib/data/treatment_repository.dart — CONVENTIONS §2.13.
/// Soft void (decision #69). Sets `voided_at` and moves `updated_at`.
/// It touches NOTHING else: not `treatment_withdrawals`, not `clear_date`,
/// not `days`, not `administered_at`. There is no un-void verb.
Future<WriteOutcome> voidTreatment(TreatmentId id) async {
  final now = appNow();                                  // ONCE (R23)
  try {
    final changed = await _db.transaction(() async {
      // The `voided_at IS NULL` predicate is the idempotence guard: a second
      // void must not move the instant at which the record was struck.
      return (_db.update(_db.treatments)
            ..where((t) => t.id.equals(id.value) & t.voidedAt.isNull()))
          .write(TreatmentsCompanion(
            voidedAt: Value(now),
            updatedAt: Value(now),
          ));
    });
    return changed == 1
        ? WriteCommitted(insertedId: id.value)
        : WriteFailed(shedFailureFrom(StateError('treatment already voided')));
  } catch (e) {
    return WriteFailed(shedFailureFrom(e));
  }
}
```

The countdown predicate, which is the other half of the verb and lives in T06's statement:

```sql
-- 07 §10.1's countdown arm. `t.voided_at IS NULL` is not a tidiness filter:
-- it is the difference between "she is under withdrawal" and "a record that
-- was wrong said she was".
WHERE (:mode = 'book')
   OR (t.voided_at IS NULL AND w.kind = 'days' AND w.clear_date >= :today)
```

### 5.3 The details that are easy to get wrong

1. **Nothing is deleted, and the row does not move.** Indelible Rule 1: *"If a proposal makes
   information disappear from the page, it is wrong."* A struck row stays exactly where it was, at
   full legibility, in every list and every export, forever (§7.4). Sorting voided treatments to the
   bottom, collapsing them behind a *"show voided"* toggle, or dropping them from the book after a
   season are all the same defect wearing different clothes.
2. **The withdrawal rows are untouched — and that is counter-intuitive.** The instinct is that a
   voided treatment should not carry a live clear date. It carries it forever: the date is *what the
   app told the user on the day*, it may already be in a PDF in a vet's hands (#50), and rewriting it
   would make the paper and the phone disagree. `voidTreatment` issues one `UPDATE` against
   `treatments` and touches `treatment_withdrawals` not at all.
3. **Leaving the countdown is not the same as claiming she is clear.** This is the half the anchor's
   fifth assertion exists for. When the only treatment on an animal is voided she vanishes from every
   *is she clear?* surface, and the app must not fill that silence: no *"no withdrawal"*, no *"clear"*,
   no green anything. The book row prints both facts — the treatment, struck, with its figure — and
   one line of copy saying the app makes no claim. Originating the negative would be the app making a
   clinical statement about an animal it has never seen (§12.2).
4. **Every *is she clear?* surface, not just this screen.** 05 §3.10 path 3 says *every*. Today there
   are two: this screen's countdown mode (T06) and the pen board's *under withdrawal* status
   (07 §9.1's projection, N19-T02). **Check the second in this commit** — before this task nothing
   could set `voided_at`, so a missing predicate there has never been reachable and is invisible in
   review. Two more arrive later and are named in their own epics: `latest_meat_clear_date` on
   `ewes.csv` (N21) and the Ewe Card timeline (N27).
5. **Undo is a time-boxed strike affordance in the row's own margin, and its window is a number of
   seconds** (P2). Not *"until the SnackBar is dismissed"* — there is no SnackBar, and
   `07` §15.2's sentence is superseded. Declare the window as one named constant in seconds, put it
   in `07-screens.md` §15.2 in this commit, and never express it as a widget's lifetime: a window
   defined by a widget's life is a window that changes when somebody reparents the widget. It does not
   survive process death and no affordance is ever reconstructed from storage (§15.4).
6. **The label is "Void this", never "Undo".** 07 §15.3: the word *Undo* is used only where the record
   disappears. `SaveReceipt.undoLabel` is a field precisely so this row can carry a different word
   (R31), and calling a soft void *Undo* would be the app claiming to have erased something it did
   not.
7. **A second void is refused, not silently repeated.** The `voided_at IS NULL` predicate makes the
   `UPDATE` affect zero rows the second time, and zero rows becomes `WriteFailed`. Moving the void
   instant would rewrite *when* the record was struck, which is itself a record.
8. **There is no un-void verb, and there will not be one.** Correction forward: if the treatment
   really happened, record it again. `07` §15.1 gives `recordTreatment` exactly one undo — the void —
   and gives the void none.
9. **The strike is three channels, one of them colour, and it must read with the colour deleted.** A
   word in the margin (`VOIDED 5 Mar 2026`), a 3 px line through the row, and the text dropping to
   `--ink-low`; `--madder-ink` reinforces and never carries. Read the book under the OS grayscale
   filter (06 §11's ship gate) and the void must still be obvious.
10. **The strike animates once, 180 ms, left to right, and obeys reduce-motion.** `--motion-strike` is
    the only animation in the system with a direction, because a strike is a thing you *draw*
    (Indelible §5.1). Route it through `prefersReducedMotion` in `lib/core/ui/motion.dart` — an
    animation that ignores the flag is an accessibility defect on a screen somebody reads at 03:20.
11. **`VOIDED <d MMM y>`, never `05/03/2026`** (R60). The same rule that governs the clear date
    governs the void date, and the export spells the word `VOID` in the PDF's Note column (09 §5) —
    keep the two readable off each other.
12. **The export keeps it.** `is_voided = 1` and `voided_at_utc` are columns 27 and 28 of
    `treatments.csv`, and a `WHERE voided_at IS NULL` in an export query is a defect (09 §3.3, and
    Indelible's printed footer promises *"STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK"*). N21 writes
    the file; this task is where the property becomes provable, so assert it against the database now.
13. **`voidTreatment` is the only write in the project that mutates an existing treatment row.**
    Everything else about a treatment is append-only. That makes it the one place a future *"while
    we're here"* edit would land — a corrected product name, a moved administration time — and every
    one of those needs the provenance quad's `original_effective` handling, which this verb does not
    do. Keep it to one column pair.

### 5.4 The full test set

**`test/features/treatments_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'a voided treatment is struck, still present, and still exported'` | **the anchor**, all five assertions |
| `'a voided treatment leaves the countdown mode and no copy claims the animal is clear'` | §5.3 item 3, asserted as a negative over the rendered text |
| `'the struck row keeps its position in the medicine book and its full legibility'` | index before and after; text style is `--ink-low`, not hidden |
| `'the strike reads under a grayscale filter'` | three channels, colour deleted |
| `'the strike draw is skipped when reduce motion is on'` | `prefersReducedMotion` |
| `'the strike affordance is gone after the window and the record stays voided'` | the window as a named constant in seconds; the record is unchanged afterwards |
| `'the affordance is labelled Void this and never Undo'` | 07 §15.3, R31 |
| `'the void date renders as d MMM y'` | R60 |

**`test/data/treatment_repository_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'voidTreatment sets voided_at and moves updated_at, and changes nothing else'` | column-by-column comparison of the row before and after |
| `'voiding leaves every treatment_withdrawals row byte-identical, including clear_date'` | the counter-intuitive half |
| `'a second voidTreatment is refused and does not move voided_at'` | the `IS NULL` predicate |
| `'there is no verb that clears voided_at'` | a source assertion over `lib/data/treatment_repository.dart` |

**`test/data/treatment_ambiguous_hour_test.dart`** `@Tags(['uk-zone'])` — extended.

| Case | What it pins |
|---|---|
| `'a void recorded at 01:30 in the repeated hour reads back as 01:30 after a reopen'` | `voided_at` is an `Instant`, so a strike recorded in the ambiguous hour is unambiguous — the case N00-T05's ruling asked for by name |

## 6. Constraints that bind this task

- **§12.2, and the rule here is what the app refuses to conclude.** A void is evidence that the *record* was wrong, not evidence that the animal was never treated (05 §3.10 path 3). So the struck row stays in the medicine book, the strike is visible, and every *is she clear?* surface must come back **without** the app saying the animal is clear. Substituting *clear* for *unknown* would be a clinical judgement the app is not entitled to make, and it is the tidy-looking outcome a reviewer has to refuse.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. **Swipe-to-void is the obvious wrong answer** and `Dismissible` is a gate row.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Indelible Rule 1** — nothing is removed, only struck. The only two honest deletes in the product are in Settings, and this is not one of them.

## 7. Definition of Done

- [ ] `'a voided treatment is struck, still present, and still exported'` passes, and was seen to fail first for the stated reason
- [ ] nothing is deleted
- [ ] the struck row still appears in the medicine book and in the export, marked
- [ ] an active withdrawal countdown for a voided treatment says what it is
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `clear_date`, `days` and `administered_at` are byte-identical before and after a void
- [ ] the pen board's *under withdrawal* projection filters `voided_at IS NULL`, checked in this commit
- [ ] the undo window is one named constant in seconds and is recorded in `07-screens.md` §15.2
- [ ] no verb anywhere clears `voided_at`

## 8. Verification

```bash
fvm flutter test test/data/treatment_repository_test.dart
fvm flutter test test/features/treatments_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "voided_at\|voidedAt" lib/ --include=*.dart
grep -rn "delete(\|DELETE FROM treatments" lib/data/treatment_repository.dart
grep -rn "Dismissible\|Draggable" lib/features/treatments/
make check
make test
```

The first grep is the audit this task exists to make possible: read every hit and confirm each one is
either the void write, the countdown predicate, the pen board's projection or the export. The second
must print nothing — there is no delete on this table. The third must print nothing; swipe-to-void is
the obvious wrong answer and `gesture.dismissible` is a gate row.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): voidTreatment as a soft, visible strike`
