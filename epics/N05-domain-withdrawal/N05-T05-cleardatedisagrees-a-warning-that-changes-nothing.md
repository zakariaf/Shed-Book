# N05-T05 — `clearDateDisagrees` — a warning that changes nothing

| | |
|---|---|
| **Epic** | [N05 — Domain: withdrawal](epic.md) · `00-README` §9 step 2 (2 of 3) |
| **Task** | 5 of 5 |
| **Depends on** | N05-T04 |
| **Commit** | one commit · `feat(domain): clearDateDisagrees — warn, never correct` |

## 1. Why this task exists

When the stored clear date does not equal what today's arithmetic would produce from the
stored inputs — because the device zone changed, or the row predates a fix — the app **says so and
changes nothing**. §12.4 in one function: a warning computed from stored inputs, shown, never
applied.

`clear_date` is the one stored derived value in the app (decision #50), and it is stored precisely
because it is *not really derived*: it is a record of what the app told the user on the day, printed
into a medicine-book PDF that may be handed to a vet or an abattoir. A value like that cannot be
silently refreshed. The disagreement is the honest answer to the staleness objection, and it is the
last piece of arithmetic N20 needs before it can be a screen epic.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §3.8 | `checkClearDate`, printed in full — the signature, the body and the message |
| `docs/engineering/05-domain-correctness.md` | §7.5 | `Warning`, `WarningCode`, the no-writer guarantees, and the warning catalogue |
| `docs/engineering/CONVENTIONS.md` | §2.6, §1.1 | the eleven `WarningCode` members, and the ban that keeps `lib/data/` away from them |
| `docs/engineering/07-screens.md` | §10.4 | how Treatments renders it: both dates, stored first, plus *"Nothing has been changed."* |
| `docs/research/00-tech-decisions.md` | §2 #50, #54 | stored exactly once, and contradictions are `List<Warning>` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the disagreement is about its arithmetic |
| `shed-safety-rules` | showing and not fixing is exactly §12.4 |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/withdrawal/disagreement_test.dart`
- **Test** — `'clearDateDisagrees warns and returns the stored clear date unchanged'`
- **Why it is red today** — nothing detects the disagreement, so a re-computed date would silently replace a stored one.

```bash
fvm flutter test test/domain/withdrawal/disagreement_test.dart   # expect: failing, for the reason above
```

The assertion, sharpened: given stored inputs that recompute to a different day, `checkClearDate`
returns exactly one `Warning` whose `code` is `WarningCode.clearDateDisagrees`, whose `message`
contains **both** `storedClearDate.iso` and the recomputed `.iso`, and whose `fieldPath` is
`'withdrawal'` — and after the call the caller's `storedClearDate` is still the value it passed in.
The function hands back no date at all, so there is nothing a caller could mistake for a correction.

**Green.** The minimum code that passes, and nothing beyond it — the pure comparison, returning a `Warning` and the **stored** date, with no writer
anywhere in the signature.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Read this before you start: the one sequencing ruling in this epic

`checkClearDate` is published in `05-domain-correctness.md` §3.8 as living in
`lib/domain/validation/treatment_checks.dart` and returning `List<Warning>`. Neither
`lib/domain/validation/warning.dart` nor `treatment_checks.dart` exists yet: `Warning`,
`WarningCode` and `Reviewed<T>` are **N06-T02**, and the three validators are **N06-T03** — one epic
later, because epics are strictly sequential and one pull request each.

**The ruling this task applies, and it is the smallest one that leaves both epics buildable:**

1. This task creates `lib/domain/validation/warning.dart` containing `final class Warning` and
   `enum WarningCode` **with all eleven members**, spelled and ordered exactly as `CONVENTIONS`
   §2.6 and 05 §7.5 give them. Writing one member now and ten later would make the enum an export
   vocabulary defined twice; writing all eleven is mechanical and free.
2. This task does **not** create `Reviewed<T>` and does not create `checkLambing`, `checkFoster` or
   `checkTreatment`. `treatment_checks.dart` lands here holding `checkClearDate` and nothing else.
3. **The two files N06 re-opens, named here so its reviewer reads them in the right order:**
   N06-T02 finds `warning.dart` present and its commit adds `Reviewed<T>` and
   `test/policy/warning_has_no_writer_test.dart`, which sweeps this file too; N06-T03 finds
   `treatment_checks.dart` present and adds `checkTreatment` beside `checkClearDate`.

If you disagree with the ruling, raise it — do not build around it. `00-README` §10's amendment
rule applies, and the alternatives both cost more: inventing a withdrawal-local result type would
put a second spelling of a published signature into the naming authority's own subject area, and
deferring this task into N06 would move a `lib/domain/withdrawal/` concern out of the withdrawal
epic.

### 5.2 The files, in `00-README` §8's order

Step 1 (schema) is **skipped and the commit message says so**: warnings are recomputed on read and
**there is no `warnings` column anywhere in the schema** — that absence is one of §12.4's four
structural guarantees, not an omission. Steps 3 to 6 are not reached; step 4's consumer is
`treatmentsProvider` in N20-T06.

| # | File | New or re-opened | What changes in it, and why |
|---|---|---|---|
| 1 | `test/domain/withdrawal/disagreement_test.dart` | **new** | The anchor. It sits under `test/domain/withdrawal/` rather than mirroring `treatment_checks.dart` because the property under test is the withdrawal disagreement; N06-T03 adds the validator-shaped tests in `test/domain/validation/`. |
| 2 | `lib/domain/validation/warning.dart` | **new** (see §5.1) | `Warning` and `WarningCode`. Read the negative space: no repository reference, no `T corrected`, no callback, no `fix()`. The API surface for mutation does not exist, so no amount of call-site carelessness produces one. |
| 3 | `lib/domain/validation/treatment_checks.dart` | **new** | `checkClearDate`, exactly as 05 §3.8 prints it. A top-level function, no class, no `Validator` suffix — the shape is fixed: `check<Thing>` returning `List<Warning>`. |
| 4 | `test/domain/uk_zone/clear_date_dst_test.dart` | **re-opened** (N05-T02, N05-T03) | One case: a row written by civil-day arithmetic across the spring-forward disagrees with today's arithmetic by exactly one day, warns, and is not corrected. This is the disagreement's real-world origin story, in the zone where it happens. |

### 5.3 The signatures

```dart
// lib/domain/validation/warning.dart
/// Advisory only. No fix(), no `corrected` field, no apply(). A Warning cannot
/// mutate anything because it holds nothing mutable and exposes no writer.
final class Warning {
  final WarningCode code;
  final String message;     // what we OBSERVED, never what to do
  final String? fieldPath;  // for scroll-to-field, not for editing
  const Warning(this.code, this.message, {this.fieldPath});
}

enum WarningCode {
  birthTypeLambCountMismatch,
  lambingBeforeSeasonStart,
  lambingInFuture,
  lambingLongBeforeCapture,
  implausibleBirthWeight,
  timeDoesNotExistLocally,
  fosterToSelf,
  deathBeforeBirth,
  duplicateActiveTag,
  clearDateDisagrees,
  localDateDisagrees,
}
```

```dart
// lib/domain/validation/treatment_checks.dart
List<Warning> checkClearDate({
  required Instant administeredAt,
  required int days,
  required LocalDate storedClearDate,
}) {
  final recomputed = clearDateFor(administeredAt: administeredAt, days: days).date;
  if (recomputed.compareTo(storedClearDate) == 0) return const [];
  return [
    Warning(
      WarningCode.clearDateDisagrees,
      'This treatment was saved with a clear date of ${storedClearDate.iso}. '
      'From the details now recorded it would be ${recomputed.iso}.',
      fieldPath: 'withdrawal',
    ),
  ];
}
```

There is no `fix()`. Editing the treatment is a user action that writes a new `clear_date` through
the normal repository path; nothing else may rewrite it.

### 5.4 The details that are easy to get wrong

- **The function returns warnings and no date, and that *is* "returns the stored value, always".**
  There is no return path yielding the recomputed date as a value a caller could persist. The
  stored `clear_date` the caller passed in is the only date that survives the call, and it stays the
  one printed in the medicine book.
- **`return const []` when they agree — not `[]`, and never `null`.** A `const` empty list allocates
  nothing on the read path, and this function runs on every render of every treatment row.
- **It takes `int days`, not a `WithdrawalPeriod`.** Only the `WithdrawalDays` arm has a stored
  clear date; `NotApplicable` has no date to disagree with and `NotRecorded` has no row at all.
  Widening the signature would import a switch that `computeWithdrawalStatus` already owns.
- **Never call it for a soft-voided treatment.** Decision #69: the withdrawal row, its inputs and
  its stored `clear_date` are **never** deleted, blanked or recalculated, and the medicine book
  shows the treatment struck through with its void date, still carrying the figure it was saved
  with. A disagreement badge on a voided row is the app arguing with a record it already published.
- **The structural guarantee, and the layer rule that holds it.** `lib/data/**` may not import
  `lib/domain/validation/**` at all — a path-pair ban with its own gate row,
  `layer.data_no_validation` (R53, `CONVENTIONS` §1.1). So a repository is *incapable* of producing
  or applying a warning; repositories always return `WriteCommitted` with the default empty
  `warnings`, and the **controller** runs the validators against the freshly-watched row. Do not
  "helpfully" call `checkClearDate` from `TreatmentRepository` in N20 — it will not compile, and
  that is the mechanism working.
- **Warnings are never persisted.** There is no `warnings` column; they are recomputed on read. A
  derived value that is never stored can never diverge from its source and can never be mistaken for
  user data on export.
- **A warning never gates a write.** The receipt is always live. This is a 3am requirement — every
  write is committed immediately — *and* a correctness one: a blocked write produces a lost record,
  which is worse than a flagged one.
- **The message carries ISO dates and `CONVENTIONS` R60 bans all-numeric human-facing dates. Both
  are right, and the resolution is not in this file.** The domain cannot import `package:intl`
  (05 §1.2 D4), so it *cannot* produce `11 Mar 2026`; and `Warning` has no structured date fields —
  only `code`, `message` and `fieldPath` — so a screen cannot reformat the message's contents. The
  consequence for N20-T06, stated here because this is where the constraint is created: the
  disagreement row renders **both dates from the values the row already holds**, formatted through
  `lib/core/ui/formatters.dart` as `d MMM y`, stored first, with *"Nothing has been changed."*
  under them (07 §10.4). The warning's `message` is the domain's own record of the observation and
  is not the string a shepherd reads at 3am.
- **The disagreement has three causes and exactly one response.** The device zone changed; an input
  was edited; the row predates a fix. All three produce the same warning and none of them produces a
  correction. Do not branch on the cause — the app cannot know which one it was.
- **Compare with `compareTo(...) == 0`, as 05 §3.8 does.** `LocalDate` is an `extension type` over
  its ISO string, so `==` happens to work today; `compareTo` survives the day the type gains a
  different representation. And remember extension types erase at runtime: a `Map<LocalDate, …>`
  will happily be hit by a bare `String` key.
- **The ambiguous hour is not warned about, here or anywhere.** It is one hour a year with zero
  visible effect, and noise at 3am is a defect. The *nonexistent* hour is warned about, by
  `checkLocalWallTimeExists` (N04), which is a different code and a different task.

### 5.5 The full test set

`test/domain/withdrawal/disagreement_test.dart`:

| Test | Case |
|---|---|
| `'clearDateDisagrees warns and returns the stored clear date unchanged'` | **the anchor.** One warning, the right code, both ISO dates in the message, `fieldPath: 'withdrawal'`, and the caller's stored date untouched |
| `'agreement returns a const empty list, not a warning with an empty message'` | inputs that recompute to the stored value |
| `'the message names the stored date first and the recomputed date second'` | the order 07 §10.4 renders them in, pinned so a reword cannot silently swap them |
| `'a zero-day withdrawal whose stored date was rounded down disagrees by one day'` | the `0` case, which is where a naive implementation stores *today* |
| `'checkClearDate exposes no writer: its only return type is List of Warning'` | the negative-space assertion, kept beside the positive one |
| `'the warning is recomputed identically on every call'` | purity; no memo, no cache, nothing to invalidate |

`test/domain/uk_zone/clear_date_dst_test.dart` — one case added:

| Test | Case |
|---|---|
| `'a clear date saved by civil-day arithmetic across the spring-forward disagrees by exactly one day and is not corrected'` | administered 20:00 on 26 March 2026, 7 days, `storedClearDate` = `LocalDate(2026, 4, 2)` — what the civil-day bug would have written. The recomputed date is 3 April; one warning; the stored 2 April is what the function still leaves the caller holding |

## 6. Constraints that bind this task

- **Safety rule §12.4 — never silently correct a user's entry.** Held at **unrepresentable +
  unpersistable**: `Warning` and `Reviewed<T>` hold no writer and no `fix()`, there is no `warnings`
  column, and `lib/data/` has no import path to `lib/domain/validation/` at all. A rule that drops
  to merely *documented* has been deleted, whatever the prose says.
- **Decision #50.** `clear_date` is computed exactly once, at write time, inside the same
  `db.transaction` that writes the withdrawal row, and its inputs live alongside it forever. Nothing
  in this task may rewrite it and nothing in N20 may either.
- **Decision #54.** A contradiction is a `List<Warning>` — never an exception, never a `bool`,
  never a nullable "corrected" value.
- **The message is an observation, never an instruction.** `ContentPolicy` (N06-T09) scans string
  literals for imperative clinical advice; *"you should"*, *"we recommend"* and *"call the vet"* are
  banned, and this message is the shape to copy: what we observed, and nothing about what to do.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. In particular the word is **warning**, never *flag*, in prose, in code and in the commit message.

## 7. Definition of Done

- [ ] `'clearDateDisagrees warns and returns the stored clear date unchanged'` passes, and was seen to fail first for the stated reason
- [ ] the function returns the stored value, always
- [ ] there is no `fix()`, no repair path and no writer
- [ ] the warning carries both numbers so the screen can print them
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/withdrawal/disagreement_test.dart
fvm flutter test test/domain/withdrawal
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
fvm dart tool/check_policy.dart
make check
make test
```

This is the last task on the branch: after it, run `/shed-code-review` over the **whole branch** in
irreversibility order before the pull request is opened.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): clearDateDisagrees — warn, never correct`
