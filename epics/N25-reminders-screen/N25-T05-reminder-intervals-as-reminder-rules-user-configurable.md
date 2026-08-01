# N25-T05 — Reminder intervals as `reminder_rules`, user-configurable

| | |
|---|---|
| **Epic** | [N25 — Reminders screen](epic.md) · `00-README` §9 step 9 (2 of 2) |
| **Task** | 5 of 6 |
| **Depends on** | N25-T04 |
| **Commit** | one commit · `feat(reminders): user-configurable intervals as reminder_rules` |

## 1. Why this task exists

Spec §7.6: *all intervals user-configurable*. The rules are rows, not constants — and the
free-tier question about reminders is **recorded** here, whichever way it is answered, so N30 does not
discover it.

The rows already exist: `reminder_rules` is seeded by `_seedReminderRules(db)` in `onCreate` with "the
§7.6 intervals, all enabled" (03 §10). What does not exist is a writer, a screen surface, and the two
rulings this task must record.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.10 | `ReminderRules`: `kind` PK, `enabled`, `offset_minutes`, `isStrict`, **no `Identified` mixin** |
| `docs/engineering/03-data-model-and-schema.md` | §10 | `_seedReminderRules(db)` — the §7.6 intervals, all enabled, in `onCreate` |
| `docs/engineering/08-platform-integration.md` | §2.11 | the two classes of reminder; `dueAt = eventInstant.plus(Duration(minutes: rule.offsetMinutes))`; `tag_by` defaults to 08:00 local |
| `docs/engineering/08-platform-integration.md` | §2.4 | call site #3 — "after any write touching … the interval settings"; debounced 500 ms |
| `docs/engineering/07-screens.md` | §11.3, §11.4 | over-cap renders **nothing**; "Change intervals" is 1 tap |
| `docs/engineering/09-export-formats.md` | §5.3, §7.2 | `reminder_rules` has no `uid`; the backup emits it keyed by `kind` and orders by `kind` |
| `docs/engineering/CONVENTIONS.md` | §2.13, §4.6, R49 | `ReminderRepository` owns `reminder_rules`; stored keys are frozen forever |
| `docs/research/00-tech-decisions.md` | §7.1 open question 17 | whether the free tier caps reminders |
| `docs/design/indelible.md` | Screen 12 | *"Reminder intervals as number steppers"* |
| `shed-book-spec.md` | §7.6, §7.10 | all intervals user-configurable; "Reminder intervals" is a Setting that matters |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the rule rows and their immediate writes |
| `shed-monetization` | whether reminders are capped is a free-tier decision and it is recorded here |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'changing an interval rewrites the rule row and re-reconciles once'`
- **Why it is red today** — intervals are constants, which spec §7.6 forbids.

The assertion, sharpened: read `reminder_rules` where `kind = 'colostrum'`, tap the stepper twice inside
500 ms, then assert `offset_minutes` holds the new value **once** (an upsert on the `kind` PK, not a
second row — `countReminderRules(db)` is unchanged), and that `FakeNotificationScheduler.calls` contains
exactly one `cancelAll` for the pair of taps, because `reconcile()` is debounced to once per 500 ms.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the rows, the edit path, and one reconcile per change.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Files touched, in `00-README` §8's order

| §8 step | File | What changes, and why |
|---|---|---|
| 1 — schema | **skipped, and it must stay skipped** | `reminder_rules` exists and is frozen. See §5.3's second 🚩 — the temptation to add a column here is real |
| 3 — write path | `lib/data/reminder_repository.dart` | **new verbs** `setInterval(...)` and `setRuleEnabled(...)`; both are upserts on the `kind` primary key |
| 3 — write path | `lib/data/reminder_repository.dart` | **new read** `watchRules()` — one statement over a nine-row table, `ORDER BY kind` |
| 5 — controllers | `lib/features/reminders/reminder_write_controller.dart` | both verbs through `guard()`, then `reconcile()` after the transaction |
| 6 — UI | `lib/features/reminders/widgets/interval_rules_section.dart` | **new.** A section on the Reminders screen — **not a route**. One ruled row per kind: the kind's label, a number stepper, an enable toggle |
| 6 — UI | `lib/features/reminders/reminders_screen.dart` | the "Reminder intervals" control that reveals the section, and the same control the empty state uses (T06) |
| 6 — ARB | `lib/l10n/app_en.arb` | one label per configurable kind, the stepper's `semanticLabel`, the enable toggle, the "not configurable in v1" line for `tag_by`'s time of day |
| 7 — tests | `test/data/reminder_repository_test.dart` | the upsert half |
| 7 — tests | `test/features/reminders_test.dart` | the anchor plus §5.4's cases |
| — | `docs/research/00-tech-decisions.md` | **the two rulings this task records.** See §5.3 |

### 5.2 The signatures

```dart
// lib/data/reminder_repository.dart
//
// reminder_rules' PK is {kind} and the table has NO Identified mixin — no uid,
// no created_at, no updated_at (03 §5.10). Both verbs are upserts on that key.
Future<WriteOutcome> setInterval({required String kind, required int offsetMinutes});
Future<WriteOutcome> setRuleEnabled({required String kind, required bool enabled});
Stream<List<ReminderRule>> watchRules();      // the row class, re-exported by lib/data/models.dart
```

The eight kinds, and which of them has a configurable interval at all — this table is the task:

| `reminders.kind` | Class (08 §2.11) | `offset_minutes` means | Configurable in v1 |
|---|---|---|---|
| `colostrum` | offset from the lambing | minutes after birth | **yes** |
| `navel` | offset from the lambing | minutes after birth | **yes** |
| `turn_out` | offset from the pen entry | minutes after penning | **yes** |
| `second_dose` | offset from the treatment | minutes after the first dose | **yes** |
| `withdrawal_end` | offset from the treatment | derived from the user's withdrawal days — **§12.1 territory** | **no** |
| `ring_dock_castrate` | offset from the lambing | minutes after birth | **yes** |
| `tag_by` | wall-clock | days-as-minutes; the time of day is fixed at 08:00 | **interval yes, time of day no** |
| `custom` | wall-clock | the user set the instant directly; there is no rule row to edit | **n/a** |

### 5.3 The details that are easy to get wrong

- 🚩 **`withdrawal_end`'s offset is not an interval the user may set here, and offering it is a §12.1
  violation.** Its `due_at` comes from the withdrawal days the shepherd read off the bottle, through
  `clearDateFor()`. A stepper on it would let a shepherd shorten a withdrawal period from the Reminders
  screen — the one place in the app where a wrong number hurts somebody who is not the user. It renders
  as a row that states where its timing comes from, with no control.
- 🚩 **`reminder_rules` has exactly one numeric column, and there is no room for a time of day.** 08 §2.11
  fixes `tag_by` at **08:00 local**, chosen so no wall-clock default is inside `01:00–01:59` — and outside
  `02:00–02:59` too, so the same default is right if the app ever ships to continental Europe. Making the
  time of day editable means a new column on a frozen table: a forward-only migration on somebody else's
  phone in April. **Do not.** State the 08:00 fact in the row's copy and move on.
- 🚩 **The interval editor is a section, not a route.** `RouteNames` declares **13** names and
  `test/features/overflow_matrix_test.dart`'s self-check asserts exactly that (N33-T01). A fourteenth route
  breaks it, and the fix is not to bump the number. 07 §11.4 says the control "pushes Settings ▸
  Reminders", but N29 — Settings — has **no** reminder-intervals task: this is where that surface is
  built. A `ShedBottomSheet` or an in-page reveal on the Reminders screen satisfies both, and the same
  control is what the empty state's single action opens (07 §2.2 row 9, T06).
- 🚩 **Changing an interval does not retro-date reminders already written, and this ruling must be
  recorded.** `due_at` was computed at write time from the rule then in force. Rewriting it would silently
  correct a stored fact — safety rule 4 — and the precedent is already in the doc set: `reminders.title`
  stores what the app *said*, "in the same spirit as the stored `clear_date`: a later terminology edit
  does not rewrite the reminder a shepherd already read" (08 §2.6). New rows use the new rule; old rows do
  not move. Write this into `docs/research/00-tech-decisions.md` with the argument, because the export and
  N30 both see the consequence.
- 🚩 **The free-tier reminder question is §7.1 open question 17 and it is answered here, in writing.**
  07 §11.3 already fixes the screen's behaviour whichever way it goes: over-cap renders **nothing**,
  because a cap "changes the reconcile budget, not this screen". Record the ruling in the decision record;
  do not branch on `unlocked` anywhere in `lib/features/reminders/`, and do not watch
  `entitlementProvider` (decision #90).
- **The upsert is on `kind`, and a naive insert throws.** `reminder_rules`' PK is `{kind}` and the table is
  `STRICT`. `into(reminderRules).insert(...)` on an existing kind raises a constraint violation; the shape
  is `insertOnConflictUpdate` or an explicit `update ... where kind = ?`. The nine rows are seeded in
  `onCreate`, so in production the row always exists — but a restore from an older backup may not carry
  it, which is why the write must tolerate both.
- **No interval literal anywhere in `lib/`.** The defaults live in `_seedReminderRules` (`lib/core/db/seed/first_run.dart`);
  every writer and reader goes through the row. `const Duration(hours: 2)` in `lib/features/` or
  `lib/data/` is exactly the constant spec §7.6 forbids. Grep for it in verification.
- **An interval is a duration, and a duration is immune to DST** (08 §2.11, the "offset from an event"
  class): `dueAt = eventInstant.plus(Duration(minutes: rule.offsetMinutes))`. Do **not** be tempted into
  civil-day arithmetic — 05 §2.9's DST-4 shows the civil-day form yielding 167 h where the offset form
  correctly yields 168.
- **The stepper is not a slider.** Sliders are on the banned-gesture list. Two ≥ 60 pt word buttons, or the
  house keypad; Indelible calls them number steppers, and a stepper is two discrete taps.
- **`reminder_rules` is one of the five tables the backup emits without a `uid`** (09 §5.3), keyed by
  `kind` and ordered by `kind` (§7.2). Changing an interval therefore changes the backup's bytes — which is
  correct and expected, and is why `test/policy/backup_round_trips_test.dart` must still pass after this
  task. Run it.
- **`enabled = false` means no new rows of that kind are written; it does **not** delete existing ones.**
  Same rule as mute, one level up. Turning `navel` off tonight leaves last night's navel reminders on the
  screen, and that is right.

### 5.4 The full test set

`test/data/reminder_repository_test.dart`

| Case | What it holds |
|---|---|
| `'setInterval upserts on kind and never creates a second row'` | the PK |
| `'setInterval on a kind whose row is missing creates it'` | the older-backup path |
| `'setRuleEnabled false leaves existing reminders untouched'` | the mute analogue |
| `'no reminder kind other than the seeded eight can be written'` | the closed CHECK, R49 |
| `'setInterval refuses a negative offset'` | `WriteRefused` or a guarded control; a negative offset means a reminder due before the event |

`test/features/reminders_test.dart`

| Case | What it holds |
|---|---|
| `'changing an interval rewrites the rule row and re-reconciles once'` | **the anchor**, §4's assertion |
| `'the intervals section renders no control on withdrawal_end'` | §12.1 |
| `'the tag_by row states its 08:00 time and offers no time control'` | the frozen-column ruling |
| `'the intervals section is not a route and RouteNames still declares 13'` | the matrix self-check |
| `'the empty state action opens the same intervals section'` | 07 §2.2 row 9; T06 asserts the copy |
| `'no monetization widget renders here at any entitlement state'` | 07 §11.3's over-cap row |
| `'every stepper control is at least 60 pt and there is no slider'` | the banned gestures |
| `'changing an interval does not move due_at on reminders already written'` | **the retro-dating ruling**, asserted |

`test/features/reminders_dst_test.dart` — `@Tags(['uk-zone'])`

| Case | What it holds |
|---|---|
| `'a 168-minute interval from 20:00 on 28 March 2026 is due 168 minutes later in physical time'` | the offset class is immune to the transition |
| `'a 7-day tag_by interval set on 26 March 2026 is due at 08:00 local on 2 April, not 07:00'` | DST-6's shape, at the rule layer |
| `'no configurable interval can place a tag_by due time inside 01:00–01:59'` | 08 §2.11's rule, asserted rather than assumed |

### 5.5 Verification

```bash
fvm flutter test test/data/reminder_repository_test.dart
fvm flutter test test/features/reminders_test.dart
TZ=Europe/London fvm flutter test test/features/reminders_dst_test.dart
fvm flutter test test/policy/backup_round_trips_test.dart
rg -n 'Duration\((hours|minutes|days):' lib/features/reminders/ lib/data/reminder_repository.dart
#   expect: only the reconciler's 500 ms debounce, nothing interval-shaped
rg -n 'RouteNames\.' lib/routing/routes.dart | wc -l          # expect: 13
rg -n 'entitlementProvider|unlocked' lib/features/reminders/  # expect: no matches
git diff -- docs/research/00-tech-decisions.md                # expect: the two rulings
make check
make test
```

## 6. Constraints that bind this task

- **§12.1 binds `withdrawal_end`.** Nothing on this screen may put a number into a withdrawal field, or
  change the timing of a withdrawal the shepherd read off a bottle.
- **§12.2 binds every interval label.** *"Colostrum — your 2 h interval"* is a fact about a setting.
  *"Colostrum is needed within 2 hours"* is veterinary advice and is banned, **including in the
  notification body**, which is the copy most likely to be written carelessly because nobody reviews a
  string that only appears on a lock screen (07 §11.6, 08 §2.5).
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'changing an interval rewrites the rule row and re-reconciles once'` passes, and was seen to fail first for the stated reason
- [ ] every interval is a row
- [ ] no interval literal in `lib/`
- [ ] the free-tier reminder decision is recorded in the decision record
- [ ] the retro-dating decision is recorded in the decision record
- [ ] `drift_schemas/` did not move
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
3. **Commit** — `feat(reminders): user-configurable intervals as reminder_rules`
