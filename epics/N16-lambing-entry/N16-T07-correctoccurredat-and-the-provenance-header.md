# N16-T07 — `correctOccurredAt` and the provenance header

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 8 of 10 |
| **Depends on** | N16-T06 |
| **Commit** | one commit · `feat(lambing_entry): correctOccurredAt and the provenance header` |

## 1. Why this task exists

A deferred entry's time is editable, and an edited time **prints both times** — the
captured one and the corrected one — with its provenance label. §12.5 on screen, not only in a
column.

`05 §4.3`'s first rule is the one this task holds: *"the provenance label appears in the same visual
block as the time. Never a bare `03:21`."* Three loose columns make the §12.5 label true but
uninformative; the quad keeps the pre-edit value, and this screen is the only place in v1 that writes
to it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§4.1 (`RecordedTime` in full: `editedTo`, `originalEffective ?? effective`, `provenanceLabel`'s exhaustive switch, `entryLag`)** · **§4.2 (the four columns and the two paired `CHECK`s)** · §4.3 (how it renders and how it exports) · §4.4 (the three published tests) · §7.5 (the codes a correction can fire) | the type, the columns and the rendering rules |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`Lambings`' quad, and **`local_date` — the denormalised civil date the spread histogram groups by**) · §4.1–§4.2 (the two schema-level date guards) | what the write must move, and what it must not |
| `docs/engineering/12-testing.md` | **§2.4 (the published `'correcting a time INTO the repeated hour keeps the original and says so'` case — this task's zone-pinned anchor)** · §10.5 (timestamp provenance survives a round trip) · §2.3 (the ambiguous hour) | the tests, already written down |
| `docs/design/indelible.md` | §2.2 (the edited-timestamp row: `†edited — event 03:20 as entered`, the dagger, the second line) · §6.2 mark 1 (the dagger: 24 px, `--madder-ink`, in the margin, **always accompanied by a word**) · §9 screen 4 (`03:20` over `AUTO`; tapping re-prints as `07:02 †edited` over `event 03:20 as entered`) | how the header prints, edited and not |
| `docs/engineering/07-screens.md` | **§6.5 (*"the event time sits in the header with its provenance label at all times"*)** · §6.4 (edit the event time — 2 taps plus the picker) · §15.1 (**`correctOccurredAt` has no undo verb**) | the behaviour and the absence of an undo |
| `docs/engineering/CONVENTIONS.md` | §2.2 (`Instant`, `LocalDate`, `RecordedTime`, `TimeSource`, `appNow()`) · §2.13 (`correctOccurredAt` returns `WriteOutcome`) · §4.6 (**`captured_at`, `original_effective`, `time_source` — never `original_effective_at`**) · §5.4 (24-hour `HH:mm`, `en_GB`, never an all-numeric human date) · R37 · R38 · R60 | every name and every format |
| `docs/engineering/06-design-system.md` | §12 (`ShedBottomSheet`, `ShedKeypad`) · §7 (the gesture ban) | what the time editor may be |
| `docs/research/00-tech-decisions.md` | §5 · #57 (the keypad is the only numeric entry route) · #101 (the gesture ban) · #108 (never an all-numeric human date) · §7.0 (UK/Ireland: `en_GB`, 24-hour, ambiguous hour 01:00–01:59) | the decisions applied |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | §12.5 is the rule and the header is its rendering |
| `shed-write-path` | the correction is its own committed write with its own provenance |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'a corrected time renders both the captured and the corrected time with the provenance label'`
- **Why it is red today** — nothing corrects a time, and spec §7.2 requires it for deferred entries.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen it to name the strings. Assert the corrected time renders as `HH:mm` (24-hour, `en_GB`), that
the original renders too, and that the label is **exactly** `RecordedTime.provenanceLabel` — compare
against the getter, not against a literal, so the assertion still holds after somebody edits the
wording. `12 §10.1`'s `Disclaimers.withdrawalProvenance` case is the same trick for the same reason.

**Green.** The minimum code that passes, and nothing beyond it — the verb, the header, and the exhaustive provenance label.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `Lambings` carries the quad and both paired
`CHECK`s since N07-T04; this task is the first code in the app that writes an `edited` row.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/time/recorded_time.dart` | **Unchanged, and that is the check.** `editedTo` was written at N04. If this file moves, the provenance type is being reinvented at the screen |
| 2 | `lib/data/lambing_repository.dart` | **Extended.** `Future<WriteOutcome> correctOccurredAt(LambingId id, Instant when)` — one `db.transaction`, `appNow()` once, `RecordedTime.editedTo(when)`, and **`local_date` rewritten in the same statement** |
| 3 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingWriteController.correctOccurredAt` through `guard()`, and the warning recompute after the write |
| 4 | `lib/features/lambing/widgets/provenance_header.dart` | **New.** The margin cell over the record: the time at `--t-margin` 18 px tabular, the stamp beneath it (`AUTO` / `EDITED`), the dagger when edited, and the second line carrying what it was edited from |
| 5 | `lib/features/lambing/widgets/time_editor_sheet.dart` | **New.** `ShedBottomSheet` + `ShedKeypad`. **Not** `showTimePicker` and **not** `showDatePicker` — see §5.3 |
| 6 | `lib/core/ui/formatters.dart` | **Extended only if a format is missing.** It is the one `package:intl` call site outside `lib/data/`; `HH:mm` and `d MMM y` already live there from N09-T06. If it does not move, say so |
| 7 | `lib/l10n/app_en.arb` | **Extended.** The header's `semanticLabel`, the *was* line, the editor's labels. **Not** the three provenance labels — those are `RecordedTime.provenanceLabel`'s, in the domain, and v1 ships `en` only (`05 §4.1`) |
| 8 | `test/features/lambing_entry_test.dart` | **The anchor**, plus the header's always-on cases |
| 9 | `test/data/lambing_repository_test.dart` | **Extended.** The verb, the `local_date` move, and the unstorable-state case |
| 10 | `test/domain/recorded_time_test.dart` | **Extended** (created at N04). The chain-of-edits case, if `05 §4.4`'s three are not already all present |
| 11 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** `12 §2.4`'s published second case, verbatim |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart
/// Writes ONE RecordedTime transition: capture -> edited, or edited -> edited.
///
/// `local_date` is rewritten in the SAME statement. It is the denormalised
/// civil date the lambing-spread histogram groups by (decision #59) — SQLite
/// cannot bucket by the shepherd's civil day without a tz database and Dart
/// can — so a correction that moves the instant across midnight and leaves the
/// date behind puts a bar in the wrong column of the only chart in the app,
/// and fires `WarningCode.localDateDisagrees` forever after.
Future<WriteOutcome> correctOccurredAt(LambingId id, Instant when) async {
  final now = appNow();                                  // ONCE (R23)
  return _db.transaction(() async {
    final row = await _read(id);
    final corrected = row.time.editedTo(when);           // 05 §4.1
    await (_db.update(_db.lambings)..where((t) => t.id.equals(id.value))).write(
      LambingsCompanion(
        occurredAt:        Value(corrected.effective),
        originalEffective: Value(corrected.originalEffective),
        timeSource:        Value(corrected.source.key),
        localDate:         Value(LocalDate.of(corrected.effective)),
        updatedAt:         Value(now),
        // capturedAt is ABSENT, not Value(null). It never moves. 05 §4.1.
      ),
    );
    return const WriteCommitted();
  });
}
```

The header, and the rule it exists to hold:

```dart
// lib/features/lambing/widgets/provenance_header.dart
/// 05 §4.3 row 1: the provenance label appears in the same visual block as the
/// time. NEVER a bare `03:21` — a bare time is a review failure (CONVENTIONS
/// §5.4). The label is `RecordedTime.provenanceLabel`, an exhaustive switch
/// that can never be empty; it is never a hand-typed string and never an ARB
/// message (v1 ships `en` only — 05 §4.1).
///
/// Edited: `03:20 †` in the margin with `EDITED` beneath, and the second line
/// `event 07:00 as entered`. The dagger is ALWAYS accompanied by a word
/// (indelible.md §6.2 mark 1). Not edited: `03:20` with `AUTO` beneath.
```

### 5.3 The details that are easy to get wrong

- **`showTimePicker` and `showDatePicker` are both `showDialog` call sites, and both are banned here.**
  `ui.show_dialog` is a gate row outside two allowlisted destructive files, and this screen is not one
  of them. Material's time picker also **defaults to the dial**, which is a drag gesture — banned
  outright (decision #101) — and its input mode is a `TextField` with a numeric keyboard, which
  decision #57 replaced with `ShedKeypad`. The editor is the app's own keypad inside `ShedBottomSheet`
  (`enableDrag: false`, `isDismissible: false`, explicit Cancel). This is the single most likely
  shortcut on the whole screen.
- **`captured_at` never moves, and the companion must say so with absence.** `Value.absent()` leaves
  the column alone; `Value(null)` writes `NULL` and trips the `CHECK`. `05 §4.1`'s anti-pattern list
  names *"a `copyWith` on `RecordedTime` that accepts `capturedAt`"* for the same reason: the field is
  how `entryLag` is measurable at all, and it is how spec §15's *"within five minutes of the event"*
  can ever be checked.
- **`originalEffective` is the FIRST value, not the previous one.** `editedTo` is
  `originalEffective ?? effective` — an unbounded chain of edits keeps what we first thought.
  `05 §4.4`'s published test edits three times and asserts the 7am original survives. Storing the
  previous value instead is the shape that records *that* a time was edited and loses *what it was
  edited from*, which makes the §12.5 label true but uninformative.
- **`local_date` moves with the instant, in the same statement.** `12 §2.4`'s published case asserts it
  explicitly: *"the denormalised civil date moves with the corrected instant."* A one-day error puts a
  bar in the wrong column of the lambing-spread histogram and fires `localDateDisagrees` on every
  subsequent read.
- **The paired `CHECK` makes the broken state unstorable**, and the test should prove it:
  `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))`. Attempt a raw update setting
  `time_source = 'edited'` with a `NULL` original and expect SQLite to refuse. That is the mechanism;
  a Dart-side invariant is not.
- **`userEntered` and `userEdited` are different facts and this verb only produces the second.** *"A
  deferred entry typed at 7am for a 03:20 lambing was never wrong, whereas an edited one was."*
  `RecordedTime.entered` is for a time typed **at creation**, and v1's Quick Entry does not offer one —
  every lambing starts `auto`. Do not reach for `editedTo` to model a deferred creation, and do not
  add an `entered` path here without a screens decision.
- **The label is the domain's, not the ARB's.** `provenanceLabel` is English in `lib/domain/`, which is
  correct today because v1 ships `en` only (decision #108). If a second locale ever ships, the label
  moves to ARB **and the exhaustive-switch test moves with it**. Meanwhile: no ARB message duplicates
  those three strings, and no widget hand-types them.
- **The header carries its label at all times, not only when edited.** `07 §6.5`: *"the event time sits
  in the header with its provenance label at all times."* An auto-captured time prints `AUTO`. The
  common bug is to render the label only in the edited branch, which passes every edited-case test.
- **Never an all-numeric human date** (R60, decision #108). If the correction crosses a day, the second
  line prints `d MMM y` — `11 Mar 2026` — never `11/03/2026`. Numeric dates exist only inside CSV,
  beside an ISO-8601 column. Times are 24-hour `HH:mm`, `en_GB`; there is no 12-hour path.
- **The correction can fire four warnings and must block none of them.** `lambingInFuture`
  (> now + 2 min), `lambingBeforeSeasonStart`, `lambingLongBeforeCapture` (`capturedAt − effective`
  > 3 days) and `timeDoesNotExistLocally`. They render through T06's query mark. `05 §7.5` guarantee 3:
  warnings never gate the write — a blocked write produces a lost record, which is worse than a
  flagged one.
- **`correctOccurredAt` has no undo verb, and that is deliberate** (`07 §15.1`). `original_effective`
  is the record: the previous value stays visible on screen and in every export, so there is nothing to
  restore and nothing to hide. Adding an undo would create a second way to change the same value, and
  only one of them would be visible.
- **The exported columns are keys, never labels.** `05 §4.3`'s CSV shape carries `time_source` as
  `auto` | `entered` | `edited` — the **stable key** — plus both a local-with-offset and a UTC column.
  N21 writes them; this task must not let a localised label anywhere near the value.
- **`entryLag` is never displayed to the user as a judgement** (`05 §4.3`). It is a diagnostics figure.
  Printing *"recorded 4 hours late"* on the header is the app grading the shepherd's night.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'a corrected time renders both the captured and the corrected time with the provenance label'` | **The anchor.** Both times, `HH:mm`, and the label compared against `provenanceLabel` rather than a literal |
| `test/features/lambing_entry_test.dart` · `'an auto-captured time still prints its provenance label'` | `07 §6.5`'s *at all times*. The bug that passes every edited-case test |
| `test/features/lambing_entry_test.dart` · `'no time on this screen renders without a label'` | Tree walk: every rendered `HH:mm` has a label in the same block |
| `test/features/lambing_entry_test.dart` · `'the time editor is ShedKeypad in a ShedBottomSheet'` | Source text: `showTimePicker`, `showDatePicker`, `showDialog(` and `TextField` appear nowhere in the feature |
| `test/features/lambing_entry_test.dart` · `'a correction that crosses a day prints d MMM y and never an all-numeric date'` | R60 |
| `test/features/lambing_entry_test.dart` · `'a corrected time in the future warns and still commits'` | `lambingInFuture` renders through T06's mark; the write is not blocked |
| `test/features/lambing_entry_test.dart` · `'a corrected time before the season start warns and still commits'` | `lambingBeforeSeasonStart`, same rule |
| `test/data/lambing_repository_test.dart` · `'correctOccurredAt sets time_source to edited and preserves the original'` | The transition, read back from the database |
| `test/data/lambing_repository_test.dart` · `'captured_at is unchanged after a correction'` | `Value.absent()`, not `Value(null)` |
| `test/data/lambing_repository_test.dart` · `'correctOccurredAt rewrites local_date in the same statement'` | A correction across midnight moves the civil date |
| `test/data/lambing_repository_test.dart` · `'time_source edited with a null original is refused by the CHECK'` | The unstorable state, proved against SQLite |
| `test/domain/recorded_time_test.dart` · `'editing preserves the ORIGINAL across many edits'` | `05 §4.4`, verbatim: three edits, the 7am original survives, `capturedAt` never moves |
| `test/domain/recorded_time_test.dart` · `'provenance label is never empty, for any source'` | The exhaustive switch, all three members |
| `test/domain/recorded_time_test.dart` · `'time_source keys are FROZEN'` | `['auto', 'entered', 'edited']` — changing one breaks every export ever written |
| `test/data/lambing_ambiguous_hour_test.dart` · `'correcting a time INTO the repeated hour keeps the original and says so'` | **`uk-zone`.** `12 §2.4`'s published case: `occurredAt.local.hour` is 1, `timeSource` is `userEdited`, `originalEffective` is 03:00, and `localDate` is 25 October |
| `test/data/lambing_ambiguous_hour_test.dart` · `'correcting a time INTO the nonexistent hour warns and stores what it was saved as'` | **`uk-zone`.** 29 March 2026, 01:30: Dart moves it forward silently, `timeDoesNotExistLocally` fires, and the stored instant is the 02:30 one |

## 6. Constraints that bind this task

- **The five safety rules** — §12.5 is held at *unrepresentable*: `RecordedTime` has no setter for `capturedAt`, `provenanceLabel` is an exhaustive switch that cannot be empty, and the paired `CHECK` makes *edited without an original* unstorable. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Write path** — the correction is its own committed write through `guard()`. No draft, no Save button, no confirmation step.
- **3am** — the editor is the app's own keypad in a sheet that does not drag and does not dismiss. No dial, no scroll wheel, no dialog, no `TextField`.
- **`en_GB`, 24-hour, never an all-numeric human date** — the owner's §7.0 ruling and R60.
- **Vocabulary** — one word per concept (`CLAUDE.md`). It is **provenance** and **provenance label**, never *audit*, *source* unqualified or *metadata*. The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a corrected time renders both the captured and the corrected time with the provenance label'` passes, and was seen to fail first for the stated reason
- [ ] both times render whenever they differ
- [ ] the label is `provenanceLabel`, never a hand-typed string
- [ ] the original captured time is never overwritten
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the header carries its label on an **auto-captured** time too, not only on an edited one
- [ ] `local_date` is rewritten in the same statement as `occurred_at`
- [ ] `original_effective` holds the **first** value across a chain of edits
- [ ] `captured_at` is written with `Value.absent()`, and a test proves it did not move
- [ ] the *edited without an original* state is proved unstorable against the `CHECK`
- [ ] `showTimePicker`, `showDatePicker`, `showDialog(` and `TextField` appear nowhere in the feature
- [ ] no ARB message duplicates the three provenance labels, and no widget hand-types them
- [ ] a date that a human reads is `d MMM y`, never all-numeric
- [ ] both `uk-zone` cases exist: the correction **into** the repeated hour and the correction **into** the nonexistent hour

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/data/lambing_repository_test.dart
fvm flutter test test/domain/recorded_time_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "showTimePicker\|showDatePicker\|showDialog(\|TextField" lib/features/lambing/   # expect zero
grep -rn "recorded automatically\|time entered by you\|time edited by you" lib/            # one file only
grep -rn "capturedAt:" lib/data/lambing_repository.dart                                    # expect zero writes
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): correctOccurredAt and the provenance header`
