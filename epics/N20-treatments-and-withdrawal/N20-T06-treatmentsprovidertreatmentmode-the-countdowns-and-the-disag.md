# N20-T06 — `treatmentsProvider(TreatmentMode)`, the countdowns and the disagreement badge

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 6 of 7 |
| **Depends on** | N20-T05 |
| **Commit** | one commit · `feat(treatments): the three modes and the clearDateDisagrees badge` |

## 1. Why this task exists

One statement per mode — log, countdowns, medicine book — plus the `clearDateDisagrees`
badge from N05-T05, which shows both numbers and changes neither.

That badge is §12.4's most consequential rendering in the product: the app has noticed a disagreement
about a clear date, it says so, it prints both numbers, and it corrects nothing.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§10.1** (the statement in full, its `readsFrom`, the fan-out and the Dart fold, and why `w.kind = 'days'` keeps a not-recorded treatment out of the countdown), **§10.3** (all six states, including the **clear date disagrees** row and its *"Nothing has been changed."* line), §1.2 (the one-query rule, stated exactly), §1.4 (Frame 1 is a fixed-height placeholder and **never a spinner**) | the statement, the modes and every state |
| `docs/engineering/05-domain-correctness.md` | **§3.8** (`checkClearDate`, its message with both dates, and *"There is no `fix()`"*), §7.5 (rule 4 as a mechanism: `Warning` holds no writer), §3.4 (the three statuses) | the badge, and what it may never do |
| `docs/engineering/CONVENTIONS.md` | **§3.2** (`treatmentsProvider : StreamProvider.autoDispose.family<List<TreatmentRow>, TreatmentMode>` in `lib/features/treatments/treatments_controller.dart`), §2.6 (`Warning`, `WarningCode.clearDateDisagrees`, `Reviewed<T>`), §3.3 (`minuteTickProvider`), §3.4 (two objects per screen), §4.4 (controller rules, and **rule 6: warnings are populated here, never by a repository**), **R33** (a family key is an extension-type id or a type with verified `==`), R25, R28, R53 | the provider's exact shape, and who computes a warning |
| `docs/engineering/02-state-di-navigation.md` | §4.1–§4.2 (provider shapes and the auto-dispose policy), §4.4 (`customSelect` with an explicit `readsFrom:`), §4.5 (reading an `AsyncValue` exhaustively) | the provider rules |
| `docs/engineering/01-architecture.md` | §4.4 (**one statement per screen**, `.distinct` in the repository, `readsFrom:`; *"`combineLatest` over drift streams is a build-breaking defect — fan-in happens in SQL"*), §7.2 (bucket A) | the rule this task is most likely to break |
| `docs/design/indelible.md` | **§8 screen 8** (the countdown rows above a double rule, the book below, and the page header printing what the book is filtered to), §8 screen 1 (the **filter line** — a 64 px ruled line of words with counts, the active one carrying a 2 px `--ink-full` underline; *there are no chips*), §7.6 (the countdown row), §6.2 mark 3 (**the query mark** — *"the record contradicts itself and I am not going to fix it for you"*), §7.16 (the page header and its double rule) | what the mode control and the two blocks actually look like |
| `docs/engineering/10-accessibility-and-i18n.md` | §5.2 (the **warning badge** row: `statusAttention`, a filled triangle and `!`, and **the `Warning.message` in full, on the row that owns the field**), §4 (the screen title and its two modes, *"in 07 §10's words"*), §3.4 (headings) | how the badge renders and what it says |
| `docs/engineering/12-testing.md` | §2.2 (`Clock.fixed` measures zero), §5 (`pumpApp`), §6.2 (the matrix row T07 adds), §3.3 (repository tests against real SQLite) | the tests |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 (`idx_withdrawal_clear`, and the `(treatment, target)` unique key that makes the fan-out at most two rows) | why the statement is cheap and the fold is bounded |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the family, its modes and its rebuild scope |
| `shed-withdrawal` | the countdown's arithmetic and the disagreement warning |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/treatments_test.dart`
- **Test** — `'a disagreeing clear date renders both numbers and updates neither'`
- **Assertion, spelled out** — seed a treatment whose inputs give `2026-03-12` today but whose stored
  `clear_date` is `2026-03-11`; capture the stored row; pump the book mode; assert
  `find.text('11 Mar 2026')` and `find.text('12 Mar 2026')` are **both** present, that the stored one
  is rendered **first**, that `find.textContaining('Nothing has been changed')` is present, and that
  there is no control anywhere in the subtree whose semantics label offers to correct it. Then
  re-read the row from the database and assert it is byte-identical to the captured one — the
  assertion that a render did not become a write.
- **Why it is red today** — there is one screen and three different reads, and nothing renders the disagreement.

```bash
fvm flutter test test/features/treatments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the family, one statement per mode, and the badge.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 4, 5, 6 and 7. **Steps 1, 2 and 3 are skipped and the commit message says so**:
no schema, no domain function (`checkClearDate` is N05-T05's and is *called* here, not written), and
no new write verb.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/core/db/queries.drift` | edit | `treatmentsQuery` — 07 §10.1's statement, as a named query, because `customStatement(` outside `lib/core/db/` is a layer violation and a named query is the only way a feature gets a hand-written `SELECT` |
| 2 | `lib/data/treatment_repository.dart` | edit | `watchTreatments(TreatmentMode)` — the one stream, `.distinct()`, folded in Dart per §5.3 item 3. It returns rows; it never computes a warning (R53) |
| 3 | `lib/features/treatments/treatments_controller.dart` | edit | `enum TreatmentMode`, `final class TreatmentRow`, and `treatmentsProvider` — `StreamProvider.autoDispose.family`, per `CONVENTIONS` §3.2. This is where `checkClearDate` is called (§4.4 rule 6) |
| 4 | `lib/features/treatments/widgets/disagreement_badge.dart` | **new** | The §12.4 rendering: the query mark, both dates, the `Warning.message` in full, and one line saying nothing has been changed |
| 5 | `lib/features/treatments/treatments_screen.dart` | edit | The mode line, the two blocks, the two empty states and Frame 1's fixed-height placeholders |
| 6 | `lib/l10n/app_en.arb` | edit | `treatmentsModeCountdown`, `treatmentsModeBook`, `treatmentsEmptyBook`, `treatmentsEmptyCountdowns`, `treatmentNothingChanged` — each with a `description`. **The disagreement text itself is not an ARB string**; see §5.3 item 7 |
| 7 | `docs/engineering/07-screens.md` §10.3 | edit | record the mode keys and, per §5.3 item 8, the mode control Indelible actually draws |
| 8 | `test/features/treatments_test.dart` | edit | the anchor plus the cases in §5.4 |
| 9 | `test/data/treatment_repository_test.dart` | edit | the three statement-level cases in §5.4 |

### 5.2 The signatures

```dart
// lib/features/treatments/treatments_controller.dart
//
// The two values 07 §10.1's statement binds into `:mode`. The commit line for
// this task says "three modes" — the plan counted the log and the medicine
// book separately, and both 07 §10 ("two segments") and Indelible §8 screen 8
// ("the medicine book is not a separate view — it is the book filtered to
// treatments") make them one. A third member needs a third arm in the bound
// statement, which §1.2's one-query rule forbids. See §5.3 item 1.
enum TreatmentMode {
  countdown('countdown'),
  book('book');

  const TreatmentMode(this.key);
  /// Bound into the statement. Frozen, never localised.
  final String key;
}
```

```dart
// The element type CONVENTIONS §3.2 names and no document shapes.
final class TreatmentRow {
  const TreatmentRow({
    required this.id,
    required this.productName,
    required this.doseText,
    required this.route,
    required this.batchNo,
    required this.administered,     // RecordedTime — the whole quad, not an Instant
    required this.voidedAt,
    required this.eweTag,
    required this.lambTag,
    required this.withdrawals,      // 0..2 in book mode; exactly 1 in countdown mode
    required this.warnings,         // computed by the CONTROLLER (R53), never stored
  });

  final TreatmentId id;
  final String productName;
  final String? doseText;
  final String? route;              // an 'rt_*' vocab_terms key
  final String? batchNo;
  final RecordedTime administered;
  final Instant? voidedAt;
  final String? eweTag;
  final String? lambTag;
  final List<TreatmentWithdrawalRow> withdrawals;   // T03's type
  final List<Warning> warnings;
}

final treatmentsProvider = StreamProvider.autoDispose
    .family<List<TreatmentRow>, TreatmentMode>((ref, mode) async* { /* … */ });
```

The warning, computed where it is allowed to be computed:

```dart
// lib/features/treatments/treatments_controller.dart — §4.4 rule 6, R53.
// `lib/features/` MAY import lib/domain/validation/; `lib/data/` may not.
List<Warning> _warningsFor(TreatmentRow row) => [
      for (final w in row.withdrawals)
        if (w.period case WithdrawalDays(:final days))
          ...checkClearDate(
            administeredAt: row.administered.effective,
            days: days,
            storedClearDate: w.storedClearDate!,
          ),
    ];
```

Widget keys, recorded in `07-screens.md` §10.3 in this commit (R59):
`treatments.mode.countdown`, `treatments.mode.book`, `treatment.row.<id>`,
`treatment.disagreement.<id>`.

### 5.3 The details that are easy to get wrong

1. **The enum has two members, and the commit line says three.** The header is the task's contract and
   is preserved verbatim; the *count* in it is a plan-level artefact. 07 §10 declares two segments,
   07 §10.1's statement binds exactly two values, and Indelible screen 8 makes the log and the
   medicine book the same page. Ship two, say so in the PR body, and if the owner wants a third the
   ruling belongs in `CONVENTIONS` §6 alongside a third arm in the statement — not in a quietly added
   enum member.
2. **One statement, and `combineLatest` is a build-breaking defect** (`01` §4.4). The temptation is
   real here because the screen wants treatments **and** their withdrawals **and** the animal's tag:
   that is three tables, and the answer is one `LEFT JOIN`, not three streams. `readsFrom:` must list
   all four — `{treatments, treatmentWithdrawals, ewes, lambs}` — or the stream will not re-run when a
   withdrawal is added and the countdown will be stale until an unrelated write happens.
3. **The statement fans out and the fold differs per mode.** A treatment with a meat figure and a milk
   figure returns two rows. In **book** mode they fold to one `TreatmentRow` carrying both
   withdrawals; in **countdown** mode the fan-out is *wanted* and each `(treatment, target)` pair is
   its own row with exactly one withdrawal, because a meat clear date and a milk clear date are two
   different countdowns (07 §10.1). Same type, two folds. Getting this backwards produces a book that
   lists one bottle twice, which is what an inspector would read as two doses.
4. **`w.kind = 'days'` is what keeps a not-recorded treatment out of the countdowns**, and it is not a
   tidiness filter: there is no number to count down. That treatment appears in the **book** with
   *Withdrawal not recorded*, which is where somebody would look for it. Dropping the predicate puts a
   row with a null clear date into a list ordered by clear date.
5. **`:today` is bound once, and the per-row figures come off the ticker.** A bound parameter does not
   change at midnight, and drift re-runs a statement only when a tracked table is **written** — so the
   row set is *what was under withdrawal when the screen opened*, and every figure on it (days left,
   `LAST DAY`, `CLEARED`) is derived at build from `minuteTickProvider`. A row that clears while you
   watch prints `CLEARED` in place rather than vanishing, which is Indelible Rule 1 and also the
   correct behaviour at 03:20. This is the same ruling N19-T02 made for the pen board.
6. **The widget watches the tick; the provider does not.** `treatmentsProvider` is `autoDispose`
   (§3.2) and `minuteTickProvider` is `autoDispose` (R25). Watching the tick inside the provider would
   re-run the SQL every 60 s all night for a value that is pure arithmetic over data already in
   memory. `ref.watch(minuteTickProvider)` belongs in the row widget's `build`.
7. **The disagreement message is the `Warning`'s own text, and it is not an ARB string.**
   `checkClearDate` composes it in `lib/domain/validation/treatment_checks.dart` with both ISO dates
   in it, exactly as `RecordedTime.provenanceLabel` is English in the domain (05 §4.1). The badge
   renders `Warning.message` **in full** (10 §5.2) and adds one ARB line: *"Nothing has been
   changed."* Paraphrasing the message, truncating it or reformatting its dates loses the two numbers
   the badge exists to show.
8. **The mode control is a line of words, not a Material segmented control.** 07 §10 says *"two
   segments on a 60 pt segmented control"*; Indelible has no such component — screen 1's filter line
   is *"a single… 64 px ruled line of words with counts printed after them"*, the active one carrying
   a 2 px `--ink-full` underline, and *"the filters are not chips — chips are containers with a
   radius, and this system has neither"*. The design system is the system of record and outranks the
   engineering documents on what a screen looks like (`CLAUDE.md`, authority order); 07 keeps the
   **behaviour** it owns, which is that this is a **mode and not a filter** — so *filtered-empty* is
   unreachable and each mode has its own empty copy. This is the same shape R36 used for the pen tile.
9. **Two empty states, and they say different things.** *"No treatments recorded."* with a
   `New treatment` action in book mode; *"Nothing under withdrawal."* in countdown mode. Both occupy
   the same box the populated content will (06 §12, decision #71), with one 60 pt action and **no
   spinner** — `ui.spinner` is a gate row.
10. **Frame 1 is six fixed-height dark row placeholders, the same geometry as Flock** (07 §10.3), so
    nothing shifts when the data lands. A layout shift at 03:20 is a missed tap on the row above.
11. **The family key is an enum, which is one of the two shapes R33 permits.** Never a `String` mode,
    never a record, never a hand-written class without a verified `==` — a family keyed on a value
    with identity equality leaks a provider per rebuild.
12. **A disagreement is reachable, and it is worth knowing how, or somebody will delete the badge as
    dead code.** There is no edit verb on `treatment_withdrawals` (it has no provenance quad), so the
    stored date and today's arithmetic can diverge in exactly two ways: the **device moved zone**
    between the write and the read (05 §3.8), and a **restore** of a backup written on a device in
    another zone (N22, N23). Both are real, neither is rare on a phone that travels, and the badge is
    the only thing standing between them and a silently different date.
13. **Nothing on this path writes.** The controller computes warnings and hands them to the widget;
    `Warning` holds no writer and has no `fix()`; there is no `warnings` column; and `lib/data/`
    cannot import `lib/domain/validation/` at all. The anchor's last assertion — re-read the row and
    compare — is the one that proves it, and it is worth keeping even though it looks tautological.
14. **`ORDER BY` matters and is published.** Book mode is reverse chronological on
    `administered_at`; countdown mode is ascending on `clear_date`; both break ties on `t.id, w.target`
    so the fold is deterministic. A non-deterministic order makes the golden-free widget tests flake
    and makes two runs of an export differ.

### 5.4 The full test set

**`test/features/treatments_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'a disagreeing clear date renders both numbers and updates neither'` | **the anchor**, including the re-read |
| `'the badge renders Warning.message in full and adds the nothing-has-been-changed line'` | 10 §5.2 · 07 §10.3 |
| `'the badge offers no control that would apply the recomputed date'` | §12.4 — there is no `fix()` and there is no button for one |
| `'countdown mode lists a meat and a milk withdrawal as two rows, each labelled with its target'` | the wanted fan-out |
| `'book mode folds the same treatment into one row carrying both withdrawals'` | the unwanted fan-out, folded |
| `'countdown mode excludes voided treatments and treatments with no days'` | T05's predicate and `w.kind = 'days'` |
| `'the two empty states differ, and filtered-empty is unreachable'` | 07 §10.3 |
| `'frame 1 renders six fixed-height placeholders and no spinner, and nothing shifts when data lands'` | measure the row box before and after |
| `'switching mode costs one tap and re-uses the open database'` | the mode line, and no second `openConnection` |
| `'the row figures move on a minute tick with no database write'` | bucket A |

**`test/data/treatment_repository_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'watchTreatments emits once per relevant write and never combines two streams'` | one statement; a source assertion for `combineLatest` |
| `'the statement declares readsFrom for all four tables'` | adding a withdrawal re-emits the stream without any other write |
| `'the book order is administered_at descending and the countdown order is clear_date ascending, both tie-broken deterministically'` | seed two treatments in the same millisecond |

**`test/features/treatments_dst_test.dart`** `@Tags(['uk-zone'])` — extended.

| Case | What it pins |
|---|---|
| `'a clear date stored before the clocks change and read after it produces the badge, not a rewrite'` | the disagreement's real-world origin, in the zone where it happens |

## 6. Constraints that bind this task

- **§12.4, held at *caught by a test*, and this badge is its most consequential rendering in the product.** `clearDateDisagrees` shows both numbers — the clear date stored on the day and the one today's rules would produce — and changes neither. No arm of this provider may pick a winner, hide the older value, sort it out of view or write a correction back; the assertion is that the row is byte-identical after the badge has been rendered.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. It is a **warning**, never a *flag* (R71).
- **One statement per screen** — `customSelect` with an explicit `readsFrom:`, fan-in in SQL, and `combineLatest` over drift streams is a build-breaking defect.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **`lib/data/` may not import `lib/domain/validation/`** (R53, `layer.data_no_validation`) — the warning is computed here, in the controller, and nowhere else.

## 7. Definition of Done

- [ ] `'a disagreeing clear date renders both numbers and updates neither'` passes, and was seen to fail first for the stated reason
- [ ] one statement per mode
- [ ] the badge shows the stored and the computed value
- [ ] neither value is written
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `TreatmentMode` has two members whose keys are byte-identical to the values the statement binds, and the PR body says why the commit line says three
- [ ] `combineLatest` appears nowhere under `lib/`, and `readsFrom:` lists all four tables
- [ ] `minuteTickProvider` is watched by a widget and never by `treatmentsProvider`

## 8. Verification

```bash
fvm flutter test test/features/treatments_test.dart
fvm flutter test test/data/treatment_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "combineLatest\|rxdart" lib/
grep -rn "customStatement(" lib/features/ lib/data/
grep -rn "minuteTickProvider" lib/features/treatments/
grep -rn "CircularProgressIndicator" lib/features/treatments/
make check
make test
```

The first two greps must print nothing: fan-in happens in SQL, and `customStatement(` is legal only
inside `lib/core/db/` (`layer.single_writer`). The third must show the tick watched in a widget's
`build` and nowhere else. The fourth is `ui.spinner` — Frame 1 is a placeholder, never a spinner.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): the three modes and the clearDateDisagrees badge`
