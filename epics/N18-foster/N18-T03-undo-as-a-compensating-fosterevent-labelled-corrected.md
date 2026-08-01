# N18-T03 — Undo as a compensating `FosterEvent` labelled *corrected*

| | |
|---|---|
| **Epic** | [N18 — Foster](epic.md) · `00-README` §9 step 6 (4 of 5) |
| **Task** | 3 of 5 |
| **Depends on** | N18-T02 |
| **Commit** | one commit · `feat(foster): undo as a compensating corrected event` |

## 1. Why this task exists

There is no delete here: the undo is a **new event** labelled *corrected*, because the
history is the record. `birth_dam` is immutable by trigger, so even a mistaken foster cannot damage
it.

This is the one place in the app where the framework word and the honest word differ. 07 §15.3: *"the
word 'Undo' is only used where the record disappears"* — on a foster it reads **"Correct this"**,
because a compensating event leaves visible history and calling that Undo would be the app claiming to
have erased something it did not.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 | Foster |
| `shed-book-spec.md` | §7.3 | birth dam and rearing dam as separate fields, reassignment in two taps or fewer |
| `docs/engineering/03-data-model-and-schema.md` | §5 | `foster_events`, the trigger and the `lamb_rearing` view |
| `docs/engineering/07-screens.md` | §15.1–§15.4, §8.4 rule 5, §8.5 | undo per verb; the window; why this is §12.4-compliant; the label; and that it does not survive process death |
| `docs/engineering/03-data-model-and-schema.md` | §7 | `corrects` as a self-FK with `ON DELETE RESTRICT`; the view's `ORDER BY effective_at DESC, id DESC` |
| `docs/design/indelible.md` | §1.2 rule 1, §7.3 (the struck row), §6.2 mark 5 (the 3 px strike), §8 screen 6 | *"Nothing is ever removed, only struck"*, and what a corrected foster prints |
| `docs/engineering/CONVENTIONS.md` | §2.1 (`FosterEventId`), §2.13, §4.6, §5.1–§5.2, §6, R31, R37 | the id type, where a new verb name is ruled, and *correct* as the project's word |
| `docs/engineering/06-design-system.md` | §10.3, §12 | `SaveReceipt.undoLabel` is a field; `ShedReceiptBar` is the widget |
| `docs/research/00-tech-decisions.md` | #69 | there is **no** generic `repo.undo(id)`; undo is defined per verb |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | a correction is a mark on the timeline, never an erasure |
| `shed-write-path` | the compensating event and its provenance |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/foster_repository_test.dart`
- **Test** — `'undoing a foster appends a corrected event and deletes nothing'`
- **Assertion, spelled out** — record a foster from the birth dam to ewe B; call the correction verb
  on the returned event; then assert `db.select(db.fosterEvents)` returns **two** rows, that the
  second's `corrects` equals the first's `id`, that the second's `effectiveAt` is greater than or
  equal to the first's, and that `lamb_rearing.rearing_dam` for that lamb is the **birth dam** again —
  restored by a new event naming her, not by a deletion and not by an `UPDATE`.
- **Why it is red today** — nothing undoes a foster, and the obvious implementation deletes the row.

```bash
fvm flutter test test/data/foster_repository_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the compensating write and a read-back showing both events present.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3, 5, 6, 7 — plus a **name**, which under §10's amendment rule item 3 is
`CONVENTIONS`'s and needs a numbered ruling in §6 and a row in §2.13. The schema is untouched:
`corrects` already exists, indexed, with `ON DELETE RESTRICT` (N07-T04).

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/engineering/CONVENTIONS.md` §2.13 + §6 | The verb's name, ruled and numbered. `correctFoster(FosterEventId event)` is the spelling this task proposes: *correct* is the project's word (§5.1), `LambingRepository.correctOccurredAt` is the existing precedent, and decision #69 bans a generic `undo(id)` |
| 2 | `lib/data/foster_repository.dart` | Add the verb beside `recordFoster`. One transaction: read the corrected event, derive the previous state, insert the compensating event |
| 3 | `lib/features/lambing/foster_write_controller.dart` | Add the correction path, through `guard()`. It builds the `SaveReceipt` whose `undoLabel` is `'CORRECT THIS'` |
| 4 | `lib/features/lambing/widgets/foster_event_row.dart` | **New.** The corrected event's row: the old value struck, the new one beside it, both legible forever |
| 5 | `lib/l10n/app_en.arb` | `fosterCorrectAction` (the label), `fosterCorrectedMark` (the row's mark), each with a `description` naming 07 §15.3 as the reason the word is not "Undo" |
| 6 | `test/data/foster_repository_test.dart` | **Extend.** The anchor plus §5.4's data cases |
| 7 | `test/features/foster_test.dart` | **Extend.** The label, the strike, the window and the restart |
| 8 | `test/features/foster_dst_test.dart` | **Extend.** A correction inside the ambiguous hour |

### 5.2 The signatures

```dart
// lib/data/foster_repository.dart — the second and last verb on this repository.
/// Appends a COMPENSATING event that reverses [event] and points at it.
/// There is no delete: `FosterEvents` is append-only and `corrects` is
/// ON DELETE RESTRICT, so neither row can be removed afterwards (07 §15.3).
Future<WriteOutcome> correctFoster(FosterEventId event);
```

What the compensating event carries, and where each value comes from:

| Column | Value | Why |
|---|---|---|
| `corrects` | the corrected event's `id` | The self-FK. This is what makes it a correction rather than a second foster |
| `lamb` · `season` | copied from the corrected event | The season is already the lamb's (T01 §5.3.1); copying keeps the pair cascade-consistent |
| `outcome` · `rearing_dam` | **the state immediately before the corrected event** | The latest event for that lamb with an earlier `(effective_at, id)`; if there is none, `lambs.birth_dam` — arm 1 of the view's `COALESCE`, expressed as an explicit `ToEwe(birthDam)` |
| `effective_at` · `captured_at` | `appNow()`, once | A graft is dated by **when it took effect** (R37), and a correction took effect now |
| `time_source` | `'auto'` | Nothing was typed. **Never `'edited'`** — see gotcha 4 |
| `original_effective` | `NULL` | Forced by the paired CHECK, and correct: this is a new event, not an edit of an old one |

### 5.3 The details that are easy to get wrong

1. **Reversing the very first foster means writing `ToEwe(birthDam)`.** Once any `FosterEvent` exists
   for a lamb, the view's *"no event at all"* arm is unreachable — `EXISTS(…)` is true forever. So
   "put her back with her mother" is an explicit event naming the birth dam as the **rearing** dam.
   That is not a birth-dam mutation and the trigger never fires: `lambs.birth_dam` is not in the
   statement.
2. **`was_fostered` stays 1 forever, and that is correct.** The view reports it from
   `EXISTS(SELECT 1 FROM foster_events …)`, `09 §3.2` exports it as a CSV column, and the lamb *was*
   fostered — a correction is a second fact, not an eraser. Do not add a `WHERE corrects IS NULL` to
   make the column look tidier; that is Rule 1 violated at the storage layer.
3. **Never copy the corrected event's `effective_at`.** With equal timestamps the view resolves on
   `id DESC` alone, which happens to work — and lies about when the correction happened, on a table
   whose entire §12.5 claim is that its timestamps are honest.
4. **Never set `time_source = 'edited'` on the compensating event.** The paired
   `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))` would demand an original, and
   there is not one: the corrected event's time is *still true*, and still on the page. 07 §15.1 gives
   fostering no timestamp-edit verb at all.
5. **Nothing is deleted, and nothing can be.** `corrects` is `ON DELETE RESTRICT`: the compensating
   event cannot be deleted out from under the one it corrects, and the corrected event cannot be
   deleted while something points at it. A `delete(` anywhere in `foster_repository.dart` is a review
   stop.
6. **The affordance is offered on the row just written, and only there.** Correcting an event that is
   no longer the latest one for that lamb changes nothing the shepherd can see — the later event still
   wins the view's `ORDER BY` — so an affordance on an old row would look broken. Do not express that
   as a refusal: `WriteRefused` carries a `RefusalReason`, and its two members are `secondSeason` and
   `eweCap`. Keep the affordance scoped to the receipt, and let the repository record faithfully
   whatever it is asked to.
7. **The label is a field, not a constant.** `SaveReceipt.undoLabel` defaults to `'UNDO'` (06 §10.3);
   this screen passes `'CORRECT THIS'`. That field exists *because of this screen* (R31) — a test that
   asserts the rendered word is the cheapest defence against the default creeping back.
8. **The window is stated in seconds, ends when the route pops, and never survives process death**
   (07 §15.2, §15.4; P2). No undo affordance is ever reconstructed from storage, and there is no "you
   can undo this later" copy anywhere in the app.
9. **Decide where the receipt renders after the commit pops the route, and write it down.** The
   journey is *Lamb Card → Foster → target*, and the shepherd should end up looking at the lamb whose
   dam just changed. The reading that satisfies both 07 §15.2 and P2: the route pops, and the receipt
   — with `CORRECT THIS` — renders in the margin of the re-printed rearing-dam row on the Lamb Card,
   which is where `indelible.md` §8 screen 6 already says the change prints. Record the choice in
   `07-screens.md` §8.5 in this commit; it is a screen behaviour and 07 owns it.
10. **The struck row does not move.** `indelible.md` §7.3: a struck row keeps its position, takes a
    3 px `--madder-ink` line across the record column at 50% height, and its text drops to the struck
    ink — *"5.75:1, still fully legible, permanently"*. It does not collapse, fade, or animate out.
    Both the old dam and the new one stay on the page: `REARING DAM 412 → 305`, with 412 struck.
11. **Colour is never the only channel** (rule 3, 10 §5). The strike is a *line*; the word
    `CORRECTED` prints beside it. A red row alone is not a correction.
12. **The correction is not a second foster in the counts.** `05` §6.10: a lamb has exactly one birth
    dam and appears once in every born count. The reared counts follow the view, so after a correction
    the receiving ewe's *reared* number goes back down — and her *born* number never moved.
13. **`ewe_summaries` is not updated here.** It is `LambingRepository`'s table today, and N27-T03 is
    the task that maintains it from the writes that invalidate it — including this one (critique S9).

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/data/foster_repository_test.dart` | **anchor:** `'undoing a foster appends a corrected event and deletes nothing'` · `'the compensating event restores the previous rearing dam, not the birth dam column'` — after a chain birth dam → B → C, correcting the second event resolves the view to **B** · `'correcting the first foster writes ToEwe(birth dam) and was_fostered stays 1'` · `'correcting a to_bottle event restores the ewe who was rearing before it'` · `'the compensating event carries time_source auto and original_effective NULL'` · `'neither event can be deleted afterwards'` — the `ON DELETE RESTRICT` on `corrects`, asserted by an attempted delete that throws · `'correcting an event that is not the latest leaves the view unchanged'` — documented behaviour, not a refusal |
| `test/features/foster_test.dart` | `'the receipt action reads CORRECT THIS and never UNDO'` · `'the corrected row keeps its position, is struck, and both dams stay legible'` · `'the window is stated in seconds and the affordance is gone after the route pops'` · `'no correction affordance is reconstructed after a restart'` — rebuild the app over the same database and assert the row is present and the action is not |
| `test/features/foster_dst_test.dart` `@Tags(['uk-zone'])` | `'a correction made in the repeated hour sorts after the event it corrects'` — foster at 01:30 BST, correct at 01:30 GMT; the two instants differ by 3 600 000 ms, `lamb_rearing` returns the corrected state, and a civil-time comparison would tie |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Rule 1 of Indelible** — *"If a proposal makes information disappear from the page, it is wrong."* A correction that hides the corrected event contradicts the design system of record, whatever the prose says.

## 7. Definition of Done

- [ ] `'undoing a foster appends a corrected event and deletes nothing'` passes, and was seen to fail first for the stated reason
- [ ] nothing is deleted
- [ ] the corrected event is labelled and renders as a correction on the timeline
- [ ] the rearing dam resolves through the view, so the correction is what the screen shows
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the verb's name is ruled in `CONVENTIONS` §6 and listed in §2.13 in this commit
- [ ] `delete(` appears nowhere in `lib/data/foster_repository.dart`

## 8. Verification

```bash
fvm flutter test test/data/foster_repository_test.dart
fvm flutter test test/features/foster_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "delete(" lib/data/foster_repository.dart
grep -rn "UNDO" lib/features/lambing/
make check
make test
```

The first grep must print nothing. The second must show no literal `UNDO` on this screen — the label
is `'CORRECT THIS'`, and the default lives on `SaveReceipt`, where other screens use it honestly.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(foster): undo as a compensating corrected event`
