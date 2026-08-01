# N25-T03 — Completing a reminder writes the domain fact

| | |
|---|---|
| **Epic** | [N25 — Reminders screen](epic.md) · `00-README` §9 step 9 (2 of 2) |
| **Task** | 3 of 6 |
| **Depends on** | N25-T02 |
| **Commit** | one commit · `feat(reminders): completing a reminder writes the domain fact` |

## 1. Why this task exists

The tap that ticks *colostrum given* writes the `CareEvent` — the reminder is not a
to-do list, it is a prompt to record a fact, and completing it without writing the fact would leave the
Ewe Card silent about something that happened.

03 §5.6 says it from the schema side: *"Checkbox state on the Lambing Entry screen is `EXISTS(…)`, never
a boolean column — that keeps 'colostrum given at 03:22' recoverable, and it gives the colostrum reminder
something to be completed **from**. Completing the reminder writes the `CareEvent`; it is the same tap."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §11.4 | 1 tap; for `colostrum` and `navel` it writes the `CareEvent`; then `reconcile()` runs |
| `docs/engineering/07-screens.md` | §15.1, §15.2, §15.4 | undo per verb: `addCare` → hard delete, window = until the route pops, never reconstructed after process death |
| `docs/engineering/03-data-model-and-schema.md` | §5.6 | `care_events`: the four kinds, the exactly-one-parent CHECK, the provenance quad |
| `docs/engineering/03-data-model-and-schema.md` | §5.10 | `reminders.completed_at`, and the at-most-one-parent CHECK |
| `docs/engineering/08-platform-integration.md` | §2.4 | call site #3, debounced 500 ms, **never inside `db.transaction()`** |
| `docs/engineering/CONVENTIONS.md` | §2.4, §2.13, §4.4, §4.6, R53 | `WriteOutcome`, repository ownership, provenance column spellings |
| `docs/engineering/01-architecture.md` | §4.2, §4.5 | one `appNow()` per mutation; there is no Save button |
| `docs/design/indelible.md` | Screen 9 | `DONE` prints a timestamp and moves the row into tonight's page as a real event |
| `shed-book-spec.md` | §7.6 | due today, overdue, upcoming |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the completion is a domain write, immediately committed |
| `shed-screens-and-routing` | the completion's route and its undo |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'completing the colostrum reminder writes a CareEvent and marks the reminder complete in one transaction'`
- **Why it is red today** — completing a reminder would only mark the reminder.

The assertion, sharpened: seed a lambing with a lamb and its `colostrum` reminder, tap `reminders.row.<id>.done`,
then assert **three** things — `reminders.completed_at` is non-null, exactly one `care_events` row exists
with `kind = 'colostrum'` and `lamb` set, and `countCareEvents(db)` is unchanged when the same write is
made to throw partway (inject a failure on the second statement and assert **zero** rows, not one).
Atomicity is the claim; a test that only counts the happy path does not hold it.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the write, one transaction, and a read-back on the Ewe Card's timeline.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Files touched, in `00-README` §8's order

| §8 step | File | What changes, and why |
|---|---|---|
| 1 — schema | **skipped** | `reminders.completed_at` and every `care_events` column exist and are frozen. Nothing new is stored |
| 3 — write path | `lib/data/reminder_repository.dart` | **new verb** `complete(...)` — one `_db.transaction()`, one `appNow()`, stamps `reminders.completed_at` and, for `colostrum` / `navel`, inserts the `care_events` row |
| 3 — write path | `lib/data/reminder_repository.dart` | **new verb** `undoComplete(CareEventId?, ReminderId)` — the hard delete 07 §15.1 defines for `addCare`, plus clearing `completed_at`, in the same transaction |
| 5 — controllers | `lib/features/reminders/reminder_write_controller.dart` | **new.** `ReminderWriteController extends WriteController`; every mutation through `guard()`; calls `reconcile()` **after** the transaction returns |
| 5 — controllers | `lib/features/reminders/reminders_controller.dart` | no data change; the controller runs `lib/domain/validation/` against the freshly-watched row and passes the `List<Warning>` to `confirmSaved` (R53) |
| 6 — UI | `lib/features/reminders/widgets/reminder_row.dart` | the `DONE` word button in the thumb band, 60 pt, and the completed row's re-print with its timestamp |
| 6 — ARB | `lib/l10n/app_en.arb` | the `DONE` label, its `semanticLabel`, the receipt summary, the undo label |
| 7 — tests | `test/data/reminder_repository_test.dart` | the repository half, against `NativeDatabase.memory()` |
| 7 — tests | `test/features/reminders_test.dart` | the anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/data/reminder_repository.dart
//
// Every write returns WriteOutcome except beginLambing/addLamb (R32).
// insertedId is the care_events row's raw int, wrapped by the ONE call site
// that reads it — the write controller, so it can offer the undo (R33).
Future<WriteOutcome> complete(ReminderId id);
Future<WriteOutcome> undoComplete(ReminderId id, {CareEventId? careEvent});
```

The body, in the order that matters:

```dart
Future<WriteOutcome> complete(ReminderId id) => _db.transaction(() async {
      final now = appNow();                       // ONCE per mutation (§8 step 10)
      final r = await _readReminder(id);
      final careKind = _careKindFor(r.kind);      // null for the six non-care kinds
      int? insertedId;
      if (careKind != null && (r.lamb != null || r.lambing != null)) {
        insertedId = await into(careEvents).insert(CareEventsCompanion.insert(
          uid: newUid(),
          season: r.season,                       // NOT NULL on care_events
          lamb: Value(r.lamb), lambing: Value(r.lambing),
          kind: careKind,
          occurredAt: now, capturedAt: now,       // RecordedTime.capture(now)
          // originalEffective stays NULL and timeSource stays 'auto' —
          // the paired CHECK ties them together.
          createdAt: now, updatedAt: now,
        ));
      }
      await (update(reminders)..where((t) => t.id.equals(id.value)))
          .write(RemindersCompanion(completedAt: Value(now), updatedAt: Value(now)));
      return WriteCommitted(insertedId: insertedId);
    });
```

The kind mapping — **this is the line the task turns on**:

```dart
/// reminders.kind and care_events.kind are DIFFERENT closed vocabularies.
/// 03 §5.10: colostrum, navel, turn_out, tag_by, ring_dock_castrate,
///           second_dose, withdrawal_end, custom
/// 03 §5.6 : colostrum, navel_dip, stomach_tube, warmed
String? _careKindFor(String reminderKind) => switch (reminderKind) {
      'colostrum' => 'colostrum',
      'navel'     => 'navel_dip',     // NOT 'navel'
      _           => null,            // the other six complete without a fact
    };
```

### 5.3 The details that are easy to get wrong

- **`navel` is not `navel_dip`.** `reminders.kind` allows `navel`; `care_events.kind`'s CHECK allows
  `navel_dip`. Passing the reminder's kind straight through fails the CHECK at runtime with a
  `SqliteException` — on the one path that matters, at 03:00, on a device. It is a two-line mapping and
  it is the single most likely defect in this task.
- **`care_events` requires exactly one parent; `reminders` allows zero.** `care_events`'
  `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)`; `reminders`'
  `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) + (treatment IS NOT NULL) <= 1)`.
  So a `colostrum` reminder attached to a **ewe**, or to nothing, has no legal `care_events` parent. The
  completion must still succeed — it stamps `completed_at` and writes no fact — and the receipt must not
  claim a fact was recorded. Do **not** invent a parent, and do **not** refuse the completion.
- **`care_events.season` is `NOT NULL`.** `reminders.season` is nullable. Read the season from the parent
  lambing or lamb, not from the reminder, and if it is genuinely absent take
  `app_settings.current_season` — which is what every other write on this path does.
- **`reconcile()` runs after the transaction, never inside it.** 08 §2.4: never inside `db.transaction()`,
  off the paint frame, debounced to once per 500 ms. It is call site #3 ("after any write touching
  `Reminder`, `Lambing`, `Treatment` or the interval settings") and its purpose here is that completing the
  56th frees a slot so the 57th can enter the window. A `zonedSchedule()` round-trip inside a drift
  transaction is banned outright and is a gate row (`notify.zoned_schedule`).
- **`schedule(` on a reminder object fails the gate** (`db.reminder_schedule`, R51) — that spelling *is*
  the architecture decision #63 rejects. The verb is `reconcile()`.
- **The provenance quad is a set of four columns, and two of them are paired by a CHECK.**
  `(time_source = 'edited') = (original_effective IS NOT NULL)`. A completion is auto-captured:
  `occurred_at = captured_at = now`, `original_effective` NULL, `time_source` `'auto'`. The column is
  `original_effective`, never `original_effective_at` (§4.6, R38).
- **`appNow()` exactly once per mutation.** Two calls put two different instants on `occurred_at` and
  `completed_at` for what the shepherd experienced as one tap. `clock.now()` and `DateTime.now(` outside
  `lib/core/time/app_clock.dart` are gate failures (R23).
- **The repository may not produce a `Warning`.** `lib/data/` may not import `lib/domain/validation/`
  (layer rule 3, R53) — structurally, not by convention. The repository returns
  `WriteCommitted(insertedId: …)` with empty `warnings`; the **controller** runs the validators against
  the freshly-watched row and hands the list to `confirmSaved`.
- **There is no SnackBar.** The receipt is the committed row: the completed reminder re-prints in place
  with its timestamp and moves into tonight's page as a real event (Indelible, Screen 9). `confirmSaved`
  is still the named call (R10, R30) and it lives in `lib/core/ui/feedback.dart` — the one file permitted
  to call `showSnackBar(`. `lib/features/reminders/` never calls it, never builds a `SnackBar`, and never
  shows a dialog (`ui.show_dialog`).
- **The undo window is until the route pops** (07 §15.2), and it is **never reconstructed after process
  death** (§15.4). No "you can undo this later" copy anywhere. The label is `Undo` here, not "Correct
  this" or "Void this" — the record genuinely disappears, which is the only case where the word `Undo` is
  honest (§15.3).
- **Undo is two deletes in one transaction.** Hard-delete the `care_events` row *and* clear
  `completed_at`. Clearing only one leaves a reminder that is complete with no fact behind it, or a fact
  with a reminder still nagging.
- **`guard()` is the double-tap defence.** `WriteController.guard()` refuses to run concurrently
  (§8 step 16). A destructive or duplicating action gets a `tester.tap(); tester.tap();` test (§8 step 28);
  completing twice must produce one `care_events` row.
- **The Ewe Card is where the read-back is proved.** `care_events` is on the timeline, and drift re-runs
  every statement whose `readsFrom:` includes it, so no invalidate is needed. Assert it there, not only in
  `reminders`.

### 5.4 The full test set

`test/data/reminder_repository_test.dart` — against `NativeDatabase.memory()`, no mocks

| Case | What it holds |
|---|---|
| `'complete on a colostrum reminder writes one care_events row and stamps completed_at'` | the happy path |
| `'complete on a navel reminder writes care_events.kind = navel_dip'` | **the mapping** |
| `'a failure partway leaves zero care_events rows and a null completed_at'` | atomicity |
| `'complete on a turn_out reminder stamps completed_at and writes no care_events row'` | the six non-care kinds |
| `'complete on a colostrum reminder attached to a ewe stamps completed_at and writes no fact'` | the parent CHECK |
| `'the care_events row carries occurred_at = captured_at, original_effective null, time_source auto'` | the quad |
| `'complete calls appNow() once'` | one instant on both columns |
| `'undoComplete deletes the care_events row and clears completed_at in one transaction'` | 07 §15.1 |

`test/features/reminders_test.dart`

| Case | What it holds |
|---|---|
| `'completing the colostrum reminder writes a CareEvent and marks the reminder complete in one transaction'` | **the anchor** |
| `'the completed reminder re-prints in place with its timestamp and no SnackBar is shown'` | Indelible; `find.byType(SnackBar)` is `findsNothing` |
| `'completing costs one tap on a 60 pt target'` | 07 §11.4 |
| `'a double tap on DONE produces exactly one care_events row'` | `guard()` |
| `'the care event appears on the Ewe Card timeline without an invalidate'` | drift table tracking |
| `'reconcile runs once after the completion and not inside the transaction'` | `FakeNotificationScheduler.calls` order: the write returns, then `cancelAll`, then `project` |
| `'the receipt names the fact only when a fact was written'` | the ewe-attached case renders no "colostrum recorded" claim |
| `'undo is offered until the route pops and never after a rebuild from storage'` | §15.4 |

`test/features/reminders_dst_test.dart` — `@Tags(['uk-zone'])`

| Case | What it holds |
|---|---|
| `'a reminder completed at 01:30 on 25 October 2026 reads back as 01:30 after a reopen'` | the repeated hour survives `InstantConverter` and a cold start |
| `'a reminder completed during the skipped hour on 29 March 2026 stores the resolved instant and says so'` | `WarningCode.timeDoesNotExistLocally` is **not** raised on an auto-captured time — nothing was typed |

### 5.5 Verification

```bash
fvm flutter test test/data/reminder_repository_test.dart
fvm flutter test test/features/reminders_test.dart
TZ=Europe/London fvm flutter test test/features/reminders_dst_test.dart
rg -n 'SnackBar|showDialog' lib/features/reminders/    # expect: no matches
rg -n 'schedule\(' lib/data/reminder_repository.dart   # expect: no matches
rg -n "'navel'" lib/data/reminder_repository.dart      # expect: only the mapping switch
make check
make test
```

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **§12.5** — every event time this diff writes carries its provenance quad, and every event time it
  renders carries its provenance label. A bare `03:21` is a review failure (§5.4).
- **§12.4** — the completion never rewrites a value the shepherd entered. Undo removes a record made
  seconds ago on their own tap; it never corrects one.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. `save\w*\(` under `lib/data/` is its own gate row (`db.save_verb`).

## 7. Definition of Done

- [ ] `'completing the colostrum reminder writes a CareEvent and marks the reminder complete in one transaction'` passes, and was seen to fail first for the stated reason
- [ ] the domain fact is written
- [ ] both writes are in one transaction
- [ ] the reminder's completion carries the provenance quad
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/reminders_test.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(reminders): completing a reminder writes the domain fact`
