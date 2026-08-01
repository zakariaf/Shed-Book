# N20-T04 — Repeat last treatment — two taps, and the days are not copied

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 4 of 7 |
| **Depends on** | N20-T03 |
| **Commit** | one commit · `feat(treatments): repeat last treatment without copying the days` |

## 1. Why this task exists

Product, dose, route and batch are copied; **the withdrawal days are not**, and the row
says so: `DAYS NOT COPIED — READ THE BOTTLE`. Copying a withdrawal period from a previous bottle is the
single most plausible route to a §12.1 violation in real use, because it is the helpful thing to do.

`CODE-REVIEW-CHECKLIST` §2.2 prints the exact code that does it, and notes that it passes every gate
in the project: the factory is the public one, there is no `?? 0`, and the column still has no
default. The reason it is still wrong is a fact about medicines rather than about code — NADIS:
withdrawal periods *"can change for the same medicine and differ between products with the same active
ingredient."* The same trade name, bought twice, can carry two different numbers. That sentence goes
in a comment at the copy site, or the next person will "fix" the omission.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§3.10 path 1** (repeat copies everything **except** the withdrawal; `WithdrawalPeriod` starts as `WithdrawalNotRecorded` and the field starts empty; the NADIS citation and the instruction to put it in a comment), **§3.10 path 2** (no learned default, ever), §3.2 (a milkings-only label lives in the **note**) | the four fields, the one refusal, and why the note is not a fifth field |
| `docs/engineering/07-screens.md` | **§10.4** (repeat is **2 taps**: tap 1 opens a sheet showing the entire copied treatment, tap 2 picks the animal and commits — and the paragraph *"Why 'repeat last' does not violate §12.1"*), §1.3 (**counting taps**: the tap that navigated here is not counted), §10.3 (the row that results renders *Withdrawal not recorded*) | the flow, the budget and the sentence §5.3 item 1 resolves |
| `docs/engineering/12-testing.md` | **§10.1** (the published two-tap test in full, including `find.textContaining('28')`, the `Disclaimers.withdrawalProvenance` assertion and its comment, and the three new widget keys), §5 (screen-driving helpers stay private to the file that uses them) | the anchor, verbatim, and the keys it names |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | **§2.2** (the passing-and-wrong `repeatLast` implementation, and the three further shapes that also pass) | the code this task must not write |
| `docs/design/indelible.md` | **§8 screen 8** (`REPEAT LAST TREATMENT` as a prominent word button that copies product, dose, route and batch and **explicitly leaves the withdrawal days blank**, printing `DAYS NOT COPIED — READ THE BOTTLE` where the value would be), §9 safety rule 1 (the same, as the safety table's answer), §7.13 (the word button), §7.14–§7.15 (the sheet and its recents lines) | the words, verbatim, and where they print |
| `docs/engineering/CONVENTIONS.md` | §1.1 **layer rule 6** (a feature may never import a sibling feature), §2.7, §2.13, §3.2 (`tagIndexProvider` — active animals only, R26), §4.4 (`WriteController.guard()`), §4.5 + R59 (keys), R33 (a bare `int` never crosses a boundary; a tag is not an id) | where the animal list comes from, and what the key is allowed to spell |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 (`UNIQUE (treatment, target)`; and `TreatmentWithdrawals` carries **no provenance quad**) | why a withdrawal can be added later and never changed |
| `docs/engineering/05-domain-correctness.md` | §4.2 and its corollary — **a table without the quad has no edit verb** | the one-line answer to *"can they correct the days afterwards?"* |
| `docs/research/00-tech-decisions.md` | §7.0 ruling 7 (tags are unique among **active** animals only) | why the animal key spells a tag and the write takes an id |
| `shed-book-spec.md` | §7.5 (*"Repeat-last-treatment shortcut for treating a batch"*), §12.1 | the feature, and the rule it is most likely to break |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | what may be copied and what may never be |
| `shed-safety-rules` | the stamp is the mechanism and the wording is fixed |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/tap_budget_test.dart`
- **Test** — `'repeat last treatment costs 2 taps, leaves days blank, and renders Disclaimers.withdrawalProvenance'`
- **Assertion, spelled out** — `12 §10.1` prints it; write it as published and add the half it omits.
  Seed with `seedTreatment(db, product: 'Alamycin LA', withdrawalDays: 28)`; pump `TreatmentsScreen`;
  `countedTap(find.byKey(const Key('treatments.repeat_last')))`; assert
  `find.textContaining('28')` **findsWidgets** and
  `find.textContaining(Disclaimers.withdrawalProvenance)` **findsWidgets** — the previous entry, shown
  with its provenance, before the committing tap. Then
  `countedTap(find.byKey(const Key('treatment.repeat.animal.128')))`; assert `c.taps == 2`,
  `countTreatments(db) == 2`, **and** — this is the assertion the published snippet does not make —
  `(await db.select(db.treatmentWithdrawals).get()).length == 1`: still only the original's row. The
  new treatment has none.
- **Why it is red today** — nothing repeats a treatment, and every implementation that copies *the last one* copies the days.

```bash
fvm flutter test test/features/tap_budget_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the two-tap path, the four copied fields, the blank days, and the stamp referenced from
`Disclaimers`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3, 5, 6 and 7. **Steps 1, 2 and 4 are skipped and the commit message says so**:
no schema, no domain, no new provider in `lib/data/providers.dart` — the animal list comes from
`tagIndexProvider`, which N13 already declared.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/data/treatment_repository.dart` | edit | `lastTreatment()` — the most recent **non-voided** treatment with its withdrawal rows, for the sheet to render. And `recordWithdrawal(TreatmentId, WithdrawalPeriod)`, the INSERT that makes T03's *"Add it"* action reachable; see §5.3 item 6 for why it is an insert and never an update |
| 2 | `lib/features/treatments/treatment_write_controller.dart` | edit | `repeatLast(TreatmentId source, {EweId? ewe, LambId? lamb})` — four fields copied, the withdrawal list **empty**, one `guard()`ed call |
| 3 | `lib/features/treatments/widgets/repeat_sheet.dart` | **new** | The sheet: the whole previous treatment rendered, the `DAYS NOT COPIED — READ THE BOTTLE` stamp where the new value would be, and the animal lines off `tagIndexProvider` |
| 4 | `lib/features/treatments/treatments_screen.dart` | edit | The `REPEAT LAST TREATMENT` word button, keyed `treatments.repeat_last` |
| 5 | `lib/l10n/app_en.arb` | edit | `treatmentRepeatLast`, `treatmentDaysNotCopied`, `treatmentRepeatPickAnimal`, `treatmentPreviousEntry` — each with a `description` |
| 6 | `docs/engineering/07-screens.md` §10.4 | edit | record the three widget keys `12 §10.1` names but 07 does not declare, and resolve §10.4's carried-forward sentence per §5.3 item 1 |
| 7 | `test/features/tap_budget_test.dart` | edit | the anchor, as published plus the missing assertion |
| 8 | `test/features/treatments_test.dart` | edit | the eight cases in §5.4 |

### 5.2 The signatures

```dart
// lib/features/treatments/treatment_write_controller.dart
//
// NADIS, Sheep — Medicine Usage: withdrawal periods "can change for the same
// medicine and differ between products with the same active ingredient". The
// same trade name, bought twice, can carry two different numbers. THIS IS WHY
// THE DAYS ARE NOT COPIED. Pre-filling every field except one reads as an
// oversight to whoever implements it next — 05 §3.10 path 1 says to put this
// sentence here, so it is here.
Future<void> repeatLast(TreatmentId source, {EweId? ewe, LambId? lamb}) async {
  final previous = await _repo.lastTreatment();          // rendered, never copied from
  await guard(() => _repo.recordTreatment(
        ewe: ewe,
        lamb: lamb,
        productName: previous!.productName,              // 1
        doseText: previous.doseText,                     // 2
        route: previous.route,                           // 3
        batchNo: previous.batchNo,                       // 4
        // note: NOT copied — §5.3 item 3.
        withdrawals: const [],                           // and that is the whole feature
      ));
}
```

```dart
// lib/data/treatment_repository.dart
/// The most recent treatment that has not been voided, with its withdrawal
/// rows, ordered by `administered_at DESC, id DESC`. Null on an empty book.
Future<TreatmentRow?> lastTreatment();

/// Adds a withdrawal to a treatment that has none for that target — the verb
/// behind T03's "Add it". An INSERT, never an UPDATE (§5.3 item 6). The
/// clear date is computed here, once, exactly as in `recordTreatment`.
Future<WriteOutcome> recordWithdrawal(TreatmentId id, WithdrawalPeriod period);
```

Widget keys, recorded in `07-screens.md` §10.4 in this commit (R59):

| Key | What it is |
|---|---|
| `treatments.repeat_last` | tap 1 — opens the sheet. **Named by `12 §10.1`**, declared nowhere else |
| `treatment.repeat.animal.<tag>` | tap 2 — picks the animal **and commits**. Named by `12 §10.1` |
| `treatment.withdrawal.add.<treatmentId>` | T03's *"Add it"*, wired here |

### 5.3 The details that are easy to get wrong

1. **07 §10.4 reads as though the figure is carried forward. It is not, and one reading satisfies
   every source.** The paragraph says *"the number being carried forward is the user's own previous
   entry, visible on screen at the moment of the commit tap"*, and requires the figure be **rendered
   before the committing tap**. `05` §3.10 path 1, `CODE-REVIEW-CHECKLIST` §2.2, Indelible §8 screen 8
   and this epic's own demo line all say the days are **not copied**. Both are true of exactly one
   design: **the sheet renders the previous treatment in full — including its withdrawal figure with
   `Disclaimers.withdrawalProvenance` beside it — and the new row is committed with no
   `treatment_withdrawals` row at all.** The rendered figure is a *receipt of a record the shepherd
   already made*; it is not a value in the new record. That is also the only reading under which
   `12 §10.1`'s two assertions — `find.textContaining('28')` **and** a blank days field — can both
   pass. Write it that way, and say so in the PR body.
2. **The stamp prints where the value would be, not in a footnote.** Indelible: `DAYS NOT COPIED —
   READ THE BOTTLE`, in the cell the new withdrawal would occupy. A stamp at the bottom of the sheet
   is a stamp nobody reads at 03:20 with a head torch.
3. **Exactly four fields are copied, and the note is not one of them.** Product name, dose text,
   route, batch number. The **note** is where a milkings-only label is recorded verbatim (05 §3.2), so
   copying it would carry a withdrawal figure forward in prose — a §12.1 violation through a door the
   sealed type does not guard. The DoD counts the copied fields.
4. **A voided treatment is never the one repeated.** `lastTreatment()` filters `voided_at IS NULL`.
   Repeating a record the shepherd struck is repeating a mistake, and the void exists precisely
   because the record was wrong (05 §3.10 path 3).
5. **The animal list comes from `tagIndexProvider`, not from Quick Entry's deck.** Layer rule 6
   forbids `lib/features/treatments/` importing `lib/features/quick_entry/`, which is where
   `quickEntryDeckProvider` lives — and the gate row `layer.sibling` fails the build on it. The
   sanctioned cross-feature read is `tagIndexProvider` in `lib/data/providers.dart`: keepAlive,
   **active animals only** (R26). The Foster screen already reaches for the same one.
6. **`recordWithdrawal` is an INSERT and there is no update verb, because
   `treatment_withdrawals` carries no provenance quad.** 05 §4.2's corollary is absolute: *a table
   without the quad has no edit verb.* So: a treatment whose target has no row can gain one; a
   treatment whose target **has** a row cannot have it changed in v1, and the second call is refused
   by `UNIQUE (treatment, target)` and mapped to `WriteFailed`. 05 §3.8's sentence about *"editing the
   treatment"* describes a path that does not exist yet; adding one means adding four columns to the
   child table, which after N07-T08 is a migration and therefore the owner's call. Do not paper over
   it with an upsert — an upsert would silently rewrite a `clear_date` that has already been printed.
7. **`recordWithdrawal` computes the clear date the same way `recordTreatment` does** —
   `clearDateFor(administeredAt: <the treatment's stored instant>, days:)`, inside one transaction.
   Not from `appNow()`: the period runs from the moment of **administration**, which may have been
   yesterday. Getting this wrong shortens a withdrawal by exactly the delay between treating the
   animal and reading the bottle, which is the interval this feature exists to make short.
8. **The key spells a tag; the write takes an id.** `treatment.repeat.animal.128` is a display
   affordance — under the owner's ruling a tag is unique only among **active** animals and is not
   unique across time, so `EweId(128)` is a different thing entirely and is wrong twice over (R33).
   Resolve tag → `EweId` through the index entry the row was built from, never by parsing the key.
9. **Two taps means two taps from the screen already painted** (07 §1.3). The tap that pushed
   Treatments is not counted, digits count individually, and there are no gestures to count. Tap 2
   **commits** — it does not open a confirmation, because a confirmation step would make it three.
10. **The commit goes through `guard()`.** Tap 2 is a committing action on a cold, wet capacitive
    screen; without the concurrency refusal the double fire is two treatments, which in a medicine
    book is two doses (decision #22). The double-tap test is in §5.4 and is not optional.
11. **The repeated row is honestly incomplete, and the screen says so.** It renders *Withdrawal not
    recorded* with the 60 pt *"Add it"* from T03 — never blank, never `0`, never an em-dash. That is
    what makes the two-tap shortcut safe: the shortcut cannot produce a record that *looks* complete
    while carrying a number nobody read.
12. **No learned default, at this call site above all others** (05 §3.10 path 2). No *"you usually
    enter 28 for this product"*, no allowlist, no confidence threshold. The widget test that the
    second treatment of an identical product still commits no withdrawal row is named in the source
    document and belongs here as well as on the control.

### 5.4 The full test set

**`test/features/tap_budget_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'repeat last treatment costs 2 taps, leaves days blank, and renders Disclaimers.withdrawalProvenance'` | **the anchor.** Two taps, two treatments, **one** withdrawal row in the database |

**`test/features/treatments_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'repeat copies exactly four fields and copies neither the withdrawal nor the note'` | compare the two rows column by column; `note` is null on the new one |
| `'the sheet prints DAYS NOT COPIED — READ THE BOTTLE in the cell the value would occupy'` | Indelible's wording, from the ARB, in the right place |
| `'the previous figure renders with its provenance and never lands in the new row'` | the §12.1 reading in §5.3 item 1, asserted from both ends |
| `'a voided treatment is never the one repeated'` | seed two treatments, void the newer, assert the older is offered |
| `'a second repeat of an identical product still commits no withdrawal row'` | 05 §3.10 path 2, at the call site most likely to grow a memory |
| `'the repeat sheet lists only active animals and never imports the Quick Entry deck'` | `tagIndexProvider`, plus a source assertion that `lib/features/treatments/` imports no sibling |
| `'a double-fired second tap commits exactly one treatment'` | decision #22 through `guard()` |
| `'the repeated row renders Withdrawal not recorded with an Add it action'` | the honest incompleteness |
| `'adding a withdrawal afterwards inserts the missing row and computes its clear date from administered_at'` | `recordWithdrawal`, and the instant it must use |
| `'a second add for the same target is refused and changes nothing'` | `UNIQUE (treatment, target)`; the child table has no edit verb |

**`test/data/treatment_ambiguous_hour_test.dart`** `@Tags(['uk-zone'])` — extended.

| Case | What it pins |
|---|---|
| `'a treatment repeated an hour later inside the repeated hour is a second row ordered by the instant'` | 01:30 BST then 01:30 GMT differ by 3 600 000 ms; `lastTreatment()` must return the **second** one. A civil-time ordering ties here and repeats the wrong bottle |
| `'a withdrawal added at 01:30 to a treatment administered the previous evening clears from the administration instant'` | §5.3 item 7, in the hour where the two instants are easiest to confuse |

## 6. Constraints that bind this task

- **§12.1, held at *caught by a test* — and this is the one place in the product where a line that passes every gate still breaks the rule.** Product, dose, route and batch copy; the withdrawal days do not, and the row says `DAYS NOT COPIED — READ THE BOTTLE`. `CODE-REVIEW-CHECKLIST` §2.2 prints the passing-but-wrong version so you can recognise it. NADIS' sentence — withdrawal periods *"can change for the same medicine and differ between products with the same active ingredient"* — goes in a comment at the copy site, or the next contributor will helpfully "fix" the omission.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures. The sheet has **no drag handle** and closes with an 88 × 64 word button (Indelible §7.14); `enableDrag: false` and `showDragHandle: false` are not preferences.
- **Layer rule 6** — `lib/features/treatments/` may not import `lib/features/quick_entry/`, however convenient the deck is.
- **The child table has no edit verb** — it has no provenance quad, and that corollary is absolute.

## 7. Definition of Done

- [ ] `'repeat last treatment costs 2 taps, leaves days blank, and renders Disclaimers.withdrawalProvenance'` passes, and was seen to fail first for the stated reason
- [ ] two taps, asserted on keyed finders
- [ ] the days field is blank and unfilled
- [ ] the stamp is referenced from `Disclaimers`, never re-typed
- [ ] the copied fields are exactly four
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the repeated treatment has **no** row in `treatment_withdrawals`, asserted against the database and not against the screen
- [ ] the NADIS sentence is in a comment at the copy site
- [ ] `recordWithdrawal` inserts and never updates, and a second call for the same target is refused
- [ ] the three widget keys are recorded in `07-screens.md` §10.4 in this commit

## 8. Verification

```bash
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/features/treatments_test.dart
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "features/quick_entry" lib/features/treatments/
grep -rn "withdrawal" lib/features/treatments/treatment_write_controller.dart
grep -rn "update(\|UPDATE treatment_withdrawals" lib/data/treatment_repository.dart
make check
make test
```

The first grep is `layer.sibling` and must print nothing. The second must show the empty list and the
NADIS comment and nothing else — any other mention of a withdrawal in the repeat path is the defect.
The third must print nothing: there is no update verb on a table with no provenance quad.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): repeat last treatment without copying the days`
