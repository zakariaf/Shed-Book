# N24-T04 — `ReminderRepository`, and rows written inside the event transactions

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 4 of 8 |
| **Depends on** | N24-T03 · N14-T02 · N20-T01 |
| **Commit** | one commit · `feat(data): reminder rows written inside the event transactions` |

## 1. Why this task exists

Decision **#63**: the reminder row is written **inside** the lambing and treatment transactions, not
after them. A colostrum reminder that exists only because a *second* write succeeded is a reminder
that silently does not exist when the phone dies between the two — and spec §5's *"assume the phone
dies"* is not a metaphor in a shed at 03:20 in March.

This is the task the whole epic was ordered around. `00-README` §9 step 9 puts reminders after steps
5–7 precisely because there must be writes to reconcile *from*, and four earlier tasks left a comment
on their transaction boundary naming this one: N14-T02 (`beginLambing`), N16-T03 (`addLamb`), N16-T05
(`addCare`) and N20-T01 (`recordTreatment`). Find those four comments and replace them with code. Do
not open a second boundary beside one of them.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.10** (`Reminders` and `ReminderRules` printed in full — the six indexes, the three `customConstraints`, `title TEXT NOT NULL`, `muted` default false, and *"there is no `os_notification_id` column, and adding one is a defect"*) · §5.6 (care events as `EXISTS`, which is what a colostrum reminder is completed *from*) · §11 (`seedFirstRun` writes the §7.6 intervals, all enabled) | every column, every CHECK, and the two tables this task writes |
| `docs/engineering/08-platform-integration.md` | **§2.1** (SQLite is the only truth; the row is written in the same transaction) · **§2.6** last paragraph (`reminders.title` is written by the repository through `titleFor`, and is a record of what the app said) · §2.11's table (the two classes of reminder and which one can go wrong) · §2.5 (what may reach a lock screen) | the transaction rule and the stored title |
| `docs/engineering/01-architecture.md` | §4.2 (event verbs; `LambingRepository` takes a `NotificationScheduler`) · **§4.3 rule 4** (never call a gateway inside a transaction) · §4.4 (`WriteOutcome`) | the one rule this task must bend precisely and not break |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/reminder_repository.dart`) · §1.1 layer rules 3, 4, **8** (`layer.single_writer`) and `layer.data_no_validation` · §2.1 (`ReminderId`, `LambingId`, `TreatmentId`) · **§2.13** (`ReminderRepository` owns writes to `reminders` and `reminder_rules`) · §3.1 (`reminderRepositoryProvider`) · §4.6 (FK columns carry the parent's singular noun, no `_id`) · **R51** (`schedule(` on a reminder object is a policy row) | **BINDING** on the file, the verbs and the column names |
| `docs/engineering/05-domain-correctness.md` | §2 (`Instant`, `.plus(Duration)`) · §3 (the clear date is stored once, at write time) · §7.1 (§12.1 — no default withdrawal period) · §7.5 (`checkLocalWallTimeExists`, `WarningCode.timeDoesNotExistLocally`) | the arithmetic, and the safety rule this task can break |
| `docs/engineering/12-testing.md` | §3.3 (repository tests against `NativeDatabase.memory()`, never a mock) · §3.5 (*"every write commits immediately" is a testable property*) · §2.4 (the data-tier ambiguous-hour tests) · §4.3 (the fake) | the tier and the harness |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#63** (the row is written in the same transaction as the lambing) · #43 (completing a colostrum reminder writes the `CareEvent` — it is the same tap) · #46 (one clock) · #3/§1 (the withdrawal clear date is absolute, stored once) | the decision this task *is* |
| `epics/00-PLAN-CRITIQUE.md` | **S10** (reminders write inside the lambing and treatment transactions, and the fixtures predate them) | why this task and T08 are in the same epic |
| `shed-book-spec.md` | §7.6 (the reminder kinds, **all user-configurable**, nothing nags twice) · §12.1 · §12.5 | which rows exist at all |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the transaction boundary is the whole point of this task |
| `shed-safety-rules` | a `withdrawal_end` row is one careless default away from breaking §12.1 |

Two auto-firing skills is the cap, and `shed-safety-rules` holds the second slot because this is the
first place a reminder row and a withdrawal period meet. What the row becomes when it is projected is
`shed-platform-gateways`' and is not reloaded — the projection happens in N24-T05, and this task
writes the row and nothing else; §5.2 prints the signature and §6 forbids the schedule call.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/reminder_repository_test.dart`
- **Test** — `'a lambing and its colostrum reminder are written in one transaction and roll back together'`
- **Why it is red today** — reminders have no writer, and the obvious implementation writes them after the event commits.

```bash
fvm flutter test test/data/reminder_repository_test.dart   # expect: failing, for the reason above
```

Sharpen it so it cannot pass on a two-transaction implementation: force the failure **after** the
reminder insert and **before** the event's own transaction returns — a `CHECK` violation on the lambing
row is the cheapest trigger — then assert **both** `countLambings(db) == 0` **and**
`SELECT COUNT(*) FROM reminders == 0`. A test that only asserts the reminder is absent passes against
an implementation that never wrote it at all.

**Green.** The minimum code that passes, and nothing beyond it — the repository, and the calls placed inside N14-T02's and N20-T01's transactions — the
comment placed there in those tasks names this one.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 1 — schema | **skipped** | `reminders` and `reminder_rules` exist from N07-T06 and are frozen. `drift_schemas/` must not move |
| 3 — data | `lib/data/reminder_repository.dart` | **New.** The class, plus the two transaction-scoped insert functions the other repositories call. This file is the only writer of `reminders` and `reminder_rules` (`CONVENTIONS §2.13`) |
| 3 — data | `lib/data/lambing_repository.dart` | **Edit.** The constructor gains `NotificationScheduler` (N14-T02's DoD says it arrives in N24). Reminder rows are inserted inside `beginLambing`, `addLamb` and `addCare`'s existing transactions, at the comment those tasks left |
| 3 — data | `lib/data/treatment_repository.dart` | **Edit.** Same, at N20-T01's comment inside `recordTreatment`: the `second_dose` row and — **only if a withdrawal row exists** — the `withdrawal_end` row |
| 4 — wiring | `lib/data/providers.dart` | **Edit.** `reminderRepositoryProvider` (`FutureProvider<ReminderRepository>`, keepAlive); `lambingRepositoryProvider` and `treatmentRepositoryProvider` now resolve `notificationSchedulerProvider` first |
| 7 — tests | `test/data/reminder_repository_test.dart` | **New.** The anchor plus §5.4's cases |
| 7 — tests | `test/data/reminder_dst_test.dart` | **Edit.** DST-6 joins T02's DST-8 in the existing `uk-zone` file |
| 7 — tests | `test/support/seeds.dart` | **Edit, if needed.** `seedReminder(db, {kind, dueAt})` for the rows T05 and N25 will need. Twelve files, and the list is closed — this goes in `seeds.dart`, not in a thirteenth |

### 5.2 The signatures

```dart
// lib/data/reminder_repository.dart — CONVENTIONS §2.13: the ONLY writer of
// `reminders` and `reminder_rules`.
final class ReminderRepository {
  ReminderRepository(this._db);
  final AppDatabase _db;

  /// Reads the §7.6 intervals seeded by seedFirstRun. Every kind is
  /// user-configurable and a disabled rule writes NO row (spec §7.6).
  Future<List<ReminderRule>> rules();
}

/// Called from INSIDE another repository's open transaction (decision #63).
/// A top-level function rather than a method, so the caller keeps ownership of
/// the transaction and `CONVENTIONS §2.13`'s "owns writes to `reminders`" stays
/// true by FILE, which is the only way it can stay true at all here.
///
/// `now` is the caller's single appNow() value — never a second read.
/// `copy` is the gateway, and the ONLY two members called on it are titleFor
/// and bodyFor, which are synchronous and touch no platform channel (§5.3).
Future<void> writeLambingReminders(
  AppDatabase db, {
  required LambingId lambing,
  required String? tag,
  required Instant occurredAt,
  required Instant now,
  required List<ReminderRule> rules,
  required NotificationScheduler copy,
});

Future<void> writeTreatmentReminders(
  AppDatabase db, {
  required TreatmentId treatment,
  required String? tag,
  required Instant administeredAt,
  required Instant now,
  required Instant? clearDate,        // null => NO withdrawal_end row. §12.1
  required List<ReminderRule> rules,
  required NotificationScheduler copy,
});
```

The row, from `03 §5.10` — the column names are the authority and `customConstraints` use the SQL
spellings:

```
reminders(id, season, ewe, lamb, lambing, treatment, kind, title, due_at, completed_at, muted)

CHECK (kind IN ('colostrum','navel','turn_out','tag_by',
                'ring_dock_castrate','second_dose','withdrawal_end','custom'))
CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)
     + (treatment IS NOT NULL) <= 1)
CHECK (due_at BETWEEN 946684800000 AND 4102444800000)
```

The two classes of reminder, from `08 §2.11` — only one of them can go wrong:

| Class | Kinds | `due_at` | DST exposure |
|---|---|---|---|
| Offset from an event | `colostrum`, `navel`, `turn_out`, `second_dose`, `withdrawal_end` | `eventInstant.plus(Duration(minutes: rule.offsetMinutes))` | **None.** A duration is a duration |
| Wall-clock | `tag_by`, and `custom` when the user sets a time | `Instant.fromDateTime(DateTime(y, m, d, h, mi))` | Real — `tag_by` defaults to **08:00 local**, deliberately outside `01:00–01:59` |

**The verbs a shepherd triggers — `complete`, `mute`, and the interval editor — are N25's and must not
be anticipated here.** N25-T03, N25-T04 and N25-T05 own them. A verb written now has no caller, no
screen and no test that means anything.

### 5.3 The details that are easy to get wrong

- **Never call a gateway inside a transaction** (`01 §4.3` rule 4) — with exactly two exceptions, and
  they are the reason `08 §2.3` declares them as it does. `String titleFor(String kind, {String? tag})`
  and `String bodyFor(...)` are **synchronous**, return `String`, and touch no platform channel. Every
  other member of `NotificationScheduler` is a `Future` over a channel round-trip, and awaiting one
  inside `db.transaction()` holds a write transaction open across a channel hop on the 3am path. If
  you find yourself awaiting the scheduler inside the boundary, you have written the architecture
  decision #63 rejects.
- **drift transactions are zone-scoped, so the helper takes `AppDatabase` and not a transaction
  object.** Any query issued on the same `AppDatabase` inside `db.transaction(() async { … })` runs in
  that transaction. The corollary is the trap: if the helper `await`s anything that escapes the zone —
  a channel call, an isolate hop, a `Future` created outside — the writes leave the transaction
  silently. That is a second reason `titleFor` is synchronous.
- **`appNow()` is called once per mutation, by the caller**, and the reminder's `dueAt` is derived from
  the *event* instant that the same call produced. A second `appNow()` inside the reminder writer puts
  a few milliseconds between a lambing and its colostrum reminder, which is invisible until an export
  round-trip compares them.
- **At most one of `ewe`, `lamb`, `lambing`, `treatment` may be non-null.** The third `CHECK` enforces
  `<= 1`, and the obvious implementation — set `lambing` *and* `ewe`, "so the query is easier" — fails
  at insert. A colostrum reminder points at the **lambing**; a `tag_by` reminder points at the
  **lamb**; a `withdrawal_end` reminder points at the **treatment**. The ewe's tag reaches the
  projection through the `LEFT JOIN` in T05's query, not through a second FK.
- **A disabled rule writes no row at all.** Spec §7.6: the seven kinds are *all user-configurable*.
  `reminder_rules.enabled` is checked before the insert, not after — a row written and then muted is a
  row the shepherd never asked for and will find on the Reminders screen.
- **§12.1 lives in this task.** A `withdrawal_end` reminder is written **only when a
  `treatment_withdrawals` row exists**, and its `due_at` is the **stored `clear_date`** from N20-T01 —
  never recomputed, never defaulted, never `0`. No withdrawal row means `WithdrawalNotRecorded`, which
  means **no reminder**. Writing one with a zero-day default is the exact failure §12.1 exists to make
  unconstructible, and it would arrive on a lock screen as a clinical claim the app invented.
- **§12.5 travels with the reminder's source, not with the reminder.** The reminder's `due_at` is
  arithmetic on a user-configurable interval and is not itself an observation, so it carries no
  provenance quad and `reminders` has none. The **event it came from** does, and that is what the
  Reminders screen renders (`07 §11.6`). Do not add provenance columns here: a table without the quad
  has no edit verb, and that is the correct shape for a generated row.
- **`reminders.title` is stored and is a record of what the app said.** Write it through
  `copy.titleFor(kind, tag: tag)`. A later terminology edit — *ewe* to *gimmer* (N29) — must not
  rewrite a reminder a shepherd has already read, which is the same rule that makes the withdrawal
  clear date stored rather than derived.
- **Civil-day arithmetic is banned for anything time-shaped here.** `dueAt = eventInstant.plus(...)`
  in absolute time. Pre-commit decision #3 measured the civil-day form at **167 h across UK
  spring-forward** — one hour short, in late March, which is peak lambing.
- **`tag_by` defaults to 08:00 local and must never default inside `01:00–01:59`.** On 29 March 2026
  that hour does not exist and `DateTime(2026, 3, 29, 1, 30)` silently returns `02:30` — Dart breaking
  §12.4 on our behalf. If a user picks a time in that hour, `checkLocalWallTimeExists` returns
  `WarningCode.timeDoesNotExistLocally`, the app **shows** the warning and stores the resolved instant.
  It is never silently moved and never refused.
- **`due_at BETWEEN 946684800000 AND 4102444800000`** is 2000-01-01 to 2100-01-01. A sign error on an
  offset produces a constraint failure at insert rather than a silent row twenty years out — which is
  a feature, and a test should prove it fires.
- **`lib/data/` may not import `lib/domain/validation/`** (`layer.data_no_validation`, R53). A reminder
  is generated from a rule, never from a warning, and this repository holds no writer for one.
- **`schedule(` on a reminder object is a policy rule row** (`db.reminder_schedule`, R51, scoped to
  `lib/data/reminder_repository.dart`). The verb here is *write the row*; projecting is T05's, and the
  spelling `schedule` **is** the rejected architecture.
- **Rows are written; nothing is projected.** `reconcile()` runs **after** the transaction returns —
  it is call site #3 and it belongs to T05. A reconcile inside a write is how a 400-ewe treatment batch
  takes eleven seconds.
- **A treatment batch writes many rows in one transaction.** `recordTreatment` over 40 animals writes
  up to 80 reminders. Insert them in one batched statement, not 80 round trips, and keep the whole
  thing inside the one boundary.

### 5.4 The full test set

`test/data/reminder_repository_test.dart` — against `NativeDatabase.memory()`, never a mock

| Case | What it asserts |
|---|---|
| `'a lambing and its colostrum reminder are written in one transaction and roll back together'` | **The anchor.** Force a failure after the reminder insert; both tables are empty afterwards |
| `'beginLambing writes exactly the enabled lambing kinds and no others'` | `colostrum`, `navel`, `turn_out` with all three rules enabled; the row count and the kind set are both asserted |
| `'a disabled rule writes no row'` | Disable `navel` in `reminder_rules`; two rows, not three, and no muted third |
| `'each reminder points at exactly one parent'` | The `<= 1` CHECK, per kind: colostrum → `lambing`, `tag_by` → `lamb`, `withdrawal_end` → `treatment`, and every other FK null |
| `'due_at is the event instant plus the rule offset, from one appNow()'` | `dueAt - occurredAt == Duration(minutes: rule.offsetMinutes)` exactly — no drift, no second clock read |
| `'the stored title is the gateway's titleFor and survives a terminology change'` | Write, change the terminology override, re-read: the stored string is unchanged |
| `'a treatment with a withdrawal row writes a withdrawal_end reminder due on the stored clear date'` | The `due_at` equals `treatment_withdrawals.clear_date` byte for byte; nothing is recomputed |
| `'a treatment with NO withdrawal row writes no withdrawal_end reminder'` | **§12.1.** The single most important case in this task. `WithdrawalNotRecorded` means no row, not a zero-day row |
| `'no reminder body or title contains a day count or a product name'` | Spec §4.5 and §12.2, over the stored `title` and the rendered body |
| `'a rolled-back treatment batch leaves no reminder rows for 40 animals'` | The batch path, and the transaction boundary at volume |
| `'an out-of-range due_at is refused by the CHECK'` | Feed an offset of 100 years; expect the constraint failure, mapped through `shedFailureFrom` |
| `'reminders has no os_notification_id column'` | Over the committed schema JSON. `03 §5.10` calls adding one a defect; this is where it would be added |
| `'lib/data/reminder_repository.dart imports no validation and contains no schedule('` | Source text: `layer.data_no_validation` and R51's `db.reminder_schedule` |
| `'no gateway member other than titleFor and bodyFor is called inside a transaction'` | Source text over `lambing_repository.dart` and `treatment_repository.dart`; `01 §4.3` rule 4 |
| `'the four transaction comments left by N14-T02, N16-T03, N16-T05 and N20-T01 are now code'` | Source text: none of the four `N24` TODO comments survives, and no second `db.transaction(` appeared beside them |

`test/data/reminder_dst_test.dart` — `@Tags(['uk-zone'])`, `TZ=Europe/London`

| Case | What it asserts |
|---|---|
| `'DST-6: a 7-day interval from 20:00 on 26 March is due 168 h later, at 21:00 local on 2 April'` | `08 §2.11`. The civil-day form yields 167 h; this is the case that catches it |
| `'a lambing recorded at 01:30 on 25 October 2026 gives a colostrum reminder exactly the offset later'` | The repeated hour. `dueAt - occurredAt` is the interval in absolute time, whichever of the two 01:30s Dart chose |
| `'a tag_by reminder defaults to 08:00 local and never lands inside 01:00–01:59'` | The default, on both transition dates |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The five safety rules bite twice here.** §12.1: no `withdrawal_end` row without a stored withdrawal.
  §12.2: the stored `title` reaches a lock screen, so it states an interval the user set and never a
  clinical window.
- **No schema change.** `drift_schemas/`, `lib/core/db/tables/` and `lib/core/db/migrations.dart` must
  not appear in this diff. If a column looks missing, it is a migration and it is N08's harness — stop
  and escalate.
- **This task authors no user-facing widget string.** The notification title and body come from T03's
  ARB messages through the copy seam.

## 7. Definition of Done

- [ ] `'a lambing and its colostrum reminder are written in one transaction and roll back together'` passes, and was seen to fail first for the stated reason
- [ ] one transaction per event, containing its reminders
- [ ] a rolled-back event leaves no reminder row
- [ ] the reminder row is a durable fact independent of the OS list
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the four transaction comments left by N14-T02, N16-T03, N16-T05 and N20-T01 are replaced by code, and no second transaction boundary was opened
- [ ] a treatment with no withdrawal row writes **no** `withdrawal_end` reminder (§12.1)
- [ ] a `withdrawal_end` reminder's `due_at` is the stored `clear_date`, never recomputed
- [ ] a disabled `reminder_rules` row writes no reminder
- [ ] every reminder has exactly one non-null parent FK
- [ ] no gateway member other than `titleFor` / `bodyFor` is called inside a transaction
- [ ] DST-6 passes under `TZ=Europe/London`
- [ ] `drift_schemas/` and `lib/core/db/` do not appear in this diff

## 8. Verification

```bash
fvm flutter test test/data/reminder_repository_test.dart
make check
make test
```

```bash
# The transaction rule, read off the source.
grep -n 'db.transaction' lib/data/lambing_repository.dart lib/data/treatment_repository.dart
grep -rn 'TODO(N24\|N24-T04' lib/data/          # expect nothing: the comments became code
grep -rn 'schedule(' lib/data/reminder_repository.dart                 # expect nothing (R51)
grep -rn 'domain/validation' lib/data/                                 # expect nothing (R53)
grep -rn 'appNow()' lib/data/reminder_repository.dart                  # expect nothing: `now` is a parameter

# Nothing schema-shaped moved.
git diff --stat -- drift_schemas/ lib/core/db/                         # expect nothing

TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/data/ --test-randomize-ordering-seed random
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): reminder rows written inside the event transactions`
