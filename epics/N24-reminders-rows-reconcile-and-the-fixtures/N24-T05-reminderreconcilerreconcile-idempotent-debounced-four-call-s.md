# N24-T05 — `ReminderReconciler.reconcile()` — idempotent, debounced, four call sites

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 5 of 8 |
| **Depends on** | N24-T04 |
| **Commit** | one commit · `feat(data): ReminderReconciler.reconcile(), idempotent and debounced` |

## 1. Why this task exists

**SQLite is the only truth. The OS holds a windowed, disposable cache. One idempotent function
projects the soonest N.** That sentence is the architecture (`08 §2.1`), and this task is the
function: `refreshLocalZone()`, then `cancelAll()`, then project the soonest `ReminderBudget.forPlatform()`
rows, then record what was actually projected.

Idempotent, debounced to once per 500 ms, called from exactly four places, and **never on a write
path** — because reconciling inside a write is how a 400-ewe treatment batch takes eleven seconds, and
because a platform-channel round-trip inside a drift transaction holds a write open across an `await`
at 03:20.

It is also the task that makes the Reminders screen's honest line possible at all: `reconcile()`
writes `app_settings.last_reconcile_scheduled` itself, so the number is **what was projected**, not
what was hoped for (`07 §17.3` rule 1).

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§2.4** (the class printed in full — the debounce, the in-flight guard, `_run`, the named query, `recordProjection`) · **§2.1** (teardown-and-rebuild; no `os_notification_id`) · **§2.9** (`canBeExact()` once per reconcile, never cached; the two schedule modes) · §2.11 (`refreshLocalZone` at the head of every run) · §2.13 (the two facts that make the honest line honest) · **§2.14** (the anti-pattern table — every row in it is reachable from this file) | the whole method, and the six ways to write it wrongly |
| `docs/engineering/07-screens.md` | **§11.1** (`schedulable_total` and its predicate) · §11.2 (the three lines) · **§17.2** (the four call sites) · §17.3 (both numbers come from data) | the predicate that must stay byte-identical, and who reads the column |
| `docs/engineering/02-state-di-navigation.md` | **§9.1** (the lifecycle observer, printed — `unawaited(ref.read(reminderReconcilerProvider.future).then((r) => r.reconcile()))` on `resumed`) · §5.4 (override rules) | call site #2, verbatim |
| `docs/engineering/03-data-model-and-schema.md` | **§5.10** (the `reminders` columns and `idx_reminder_due_open`) · **§5.13** (`app_settings.last_reconcile_scheduled`, nullable, and its doc comment) | the query's index and the one column this task writes |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/reminder_reconciler.dart`, `lib/core/db/queries.drift`) · §2.12 (`ReminderReconciler` is a non-plugin service in `lib/data/`) · §3.1 (`reminderReconcilerProvider`; **it needs `settingsRepositoryProvider` too** — `08 §11`) · §4.6 (named `.drift` query is `lowerCamel`) · **R40**, **R51**, R29 | **BINDING** on the class, the provider and the query name |
| `docs/engineering/12-testing.md` | §4.3 (the fake's three tripwires, all of which this task must satisfy) · §2.2 (the binding's advancing clock, and why `Clock.fixed` freezes the debounce) · §3.3 (data-tier tests) | how to test a debounce without `Future.delayed` |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#63** (four call sites, 500 ms, off the paint frame) · #46 (`appNow()`) · #47 (SQL-side time is banned) | the decision this method implements |
| `epics/N25-reminders-screen/N25-T02-the-honest-windowed-line.md` | §5.2, §5.3 (the screen reads `AppSetting.lastReconcileScheduled` as a **count**, and never writes it) | what the column must contain when N25 opens it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the projection, the budget and the OS surface |
| `shed-riverpod-providers` | the debounce, the call sites and what may not call it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/reconcile_test.dart`
- **Test** — `'reconcile is idempotent and projects exactly the soonest 56 of 312'`
- **Why it is red today** — nothing projects reminders onto the OS.

```bash
fvm flutter test test/data/reconcile_test.dart   # expect: failing, for the reason above
```

Sharpen it in two ways, both of which decide whether the test means anything:

1. **Never write the literal 56.** `ReminderBudget.forPlatform()` returns **200** on every host this
   suite runs on (`Platform.isIOS` is false on `ubuntu-latest` and on macOS). Seed **312** open,
   unmuted, future reminders and assert `fake.projected.length == ReminderBudget.forPlatform()` — the
   number in the test name is the iOS case the fake's tripwire holds, not a literal to type.
2. **Assert the slice, not just the count.** The projected ids must be the first `forPlatform()` rows
   of the 312 ordered by `due_at` ascending — so a reconciler that projects the *last* N, or projects
   in insertion order, fails. Then run `reconcile()` a second time past the debounce and assert the
   projected set is byte-identical: that is the idempotence half of the name.

**Green.** The minimum code that passes, and nothing beyond it — the reconciler, the debounce, the four call sites named in the source, and the assertion
against the fake's recorded calls.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 1 — schema | **skipped** | `app_settings.last_reconcile_scheduled` was added by **R40** and shipped in N07. **Read §5.3 before you touch it** — its declared Dart type and its documented use disagree, and resolving that must not move `drift_schemas/` |
| — db | `lib/core/db/queries.drift` | **Edit.** The named query `soonestPendingReminders(:after AS INT, :limit AS INT)`, printed in `08 §2.4`. Regenerating `database.g.dart` is part of **this** commit |
| 3 — data | `lib/data/reminder_reconciler.dart` | **New.** `final class ReminderReconciler` with **one** public method, `Future<void> reconcile()` (R51) |
| 3 — data | `lib/data/settings_repository.dart` | **Edit.** `Future<void> recordProjection({required int scheduled, required Instant at})` — a new verb on an existing repository (`08 §11`), added to `CONVENTIONS §2.13` in this commit |
| 4 — wiring | `lib/data/providers.dart` | **Edit.** `reminderReconcilerProvider` (`FutureProvider<ReminderReconciler>`, keepAlive), resolving `databaseProvider`, `notificationSchedulerProvider` **and** `settingsRepositoryProvider` |
| 6 — root | `lib/app.dart` | **Edit.** Call site **#1** — the reconcile at the end of `_bootNotifications()`'s chain (T03 left it one call long). Call site **#2** — `AppLifecycleState.resumed`, beside `ref.invalidate(minuteTickProvider)`, spelled with `unawaited(...)` from `dart:async` |
| 5 — controllers | `lib/features/lambing/lambing_write_controller.dart` · `lib/features/treatments/treatment_write_controller.dart` | **Edit.** Call site **#3** — **after** `guard()` returns, never inside it and never inside the repository |
| 7 — tests | `test/data/reconcile_test.dart` | **New.** The anchor plus §5.5's cases |

Call site **#4** — after a notification tap — is T07's, and this commit leaves it unwritten.

### 5.2 The signatures

`08 §2.4` prints the class body. It is printed because the body **is** the specification: the debounce,
the in-flight guard and the order of the four gateway calls are all load-bearing.

```dart
// lib/data/reminder_reconciler.dart — R51. One public method.
final class ReminderReconciler {
  ReminderReconciler({
    required AppDatabase db,
    required NotificationScheduler scheduler,
    required SettingsRepository settings,   // app_settings is SettingsRepository's
  })  : _db = db, _scheduler = scheduler, _settings = settings;

  static const _debounce = Duration(milliseconds: 500);
  Instant? _lastRunAt;
  Future<void>? _inFlight;

  Future<void> reconcile() async { … }      // debounce, then _run, then bookkeeping
  Future<void> _run(Instant now) async { … }
}
```

`_run`, in order, and the order is the specification:

1. `await _scheduler.refreshLocalZone();`
2. `if (!await _scheduler.alertsGranted()) { cancelAll(); recordProjection(scheduled: 0, at: now); return; }`
3. `final exact = await _scheduler.canBeExact();` — **once**, never cached
4. `final due = await _db.soonestPendingReminders(now.epochMillis, ReminderBudget.forPlatform()).get();`
5. `await _scheduler.cancelAll();`
6. the projection loop, `project((id:, kind:, dueAt:, tag:), exact: exact)`
7. `await _settings.recordProjection(scheduled: projected, at: now);`

The query, in `lib/core/db/queries.drift`, using `idx_reminder_due_open`:

```sql
soonestPendingReminders(:after AS INT, :limit AS INT):
SELECT r.id, r.kind, r.due_at, e.tag AS ewe_tag, l.tag AS lamb_tag
  FROM reminders r
  LEFT JOIN ewes  e ON e.id = r.ewe
  LEFT JOIN lambs l ON l.id = r.lamb
 WHERE r.completed_at IS NULL
   AND r.muted = 0
   AND r.due_at > :after
 ORDER BY r.due_at ASC
 LIMIT :limit;
```

### 5.3 One contradiction this task must resolve, in writing

`app_settings.last_reconcile_scheduled` is described three ways and they do not agree:

| Source | What it says |
|---|---|
| `CONVENTIONS` **R40** | *"03 adds `last_reconcile_scheduled INTEGER` (nullable; written by `reconcile()` in the same transaction that records the projection)"* |
| `07 §11.2`, `§17.3` rule 1, and N25-T02 | It is the **number** the honest line quotes — *"Showing the next 56 reminders on your lock screen"* — read from data, never a literal |
| `03 §5.13` as published | `integer().map(const InstantConverter()).nullable()` — an **`Instant`** |

The name, R40 and both consumers agree: it is a **count**. `03 §5.13`'s `InstantConverter` is the
defect. Resolve it here, because this task is the only writer and N25-T02 is the first reader.

**Do it in this order, and stop if step 2 surprises you.**

1. Change the declaration to a plain nullable `integer()` — the *SQL* column type is `INTEGER` either
   way, so this is a Dart-side mapping change, not a column change.
2. Run `make gen` and read `git diff -- drift_schemas/`. **If the snapshot moves, stop.** A snapshot
   diff after the N07-T08 freeze is a schema change on a table pointing at a shepherd's records, and it
   is N08's harness plus an owner conversation — not a `make gen` and a commit.
3. Amend `03 §5.13` in the same commit (`00-README` §10's amendment rule).

`recordProjection`'s `at:` parameter has **no column in v1**. `08 §2.4` passes it, and it is worth
keeping: it is the single `appNow()` value the whole method shares, and it makes the verb honest about
which instant produced the count. Say so in its doc comment — *"`at` is not stored in v1; adding a
column for it is a migration"* — so nobody later assumes a "last reconciled at" timestamp exists.

### 5.4 The details that are easy to get wrong

- **`due_at > :after` is load-bearing, not tidiness.** On Android, `AlarmManager` fires an alarm whose
  trigger time is already past **immediately**. Project twelve overdue reminders and the shepherd gets
  twelve pings in one second, every time the app resumes. On iOS a past `UNCalendarNotificationTrigger`
  simply never fires — so the bug is **Android-only and will not reproduce on an iPhone**, which is
  the worst possible shape for a bug in a solo-developer project. Overdue reminders live on the
  Reminders screen's "Overdue" bucket, where they belong.
- **`completed_at IS NULL` and `muted = 0` must stay byte-identical with `07 §11.1`'s
  `schedulable_total`.** The honest line compares two numbers; if the projection and the count applied
  different *eligibility* predicates the line would be a lie by arithmetic. The two deliberately differ
  on `due_at > :after` and on nothing else.
- **drift generates POSITIONAL parameters for a named `.drift` query's variables, in declaration
  order.** `soonestPendingReminders(now.epochMillis, ReminderBudget.forPlatform())`. Writing
  `after:` / `limit:` does not compile, and the failure reads like a missing method.
- **Teardown-and-rebuild, never a diff.** `pendingNotificationRequests()` returns only id, title, body
  and payload. A diff would need a content hash smuggled into the payload and *still* could not see
  that the Android schedule mode changed when the user granted exact alarms. `cancelAll()` + rebuild is
  ten lines instead of eighty and cannot drift. Pending requests are invisible to the user, so the
  churn costs nothing.
- **`canBeExact()` is asked once per reconcile and never cached** — not in a field, not in an
  `app_settings` column. The user can revoke *Alarms & reminders* in system Settings at any moment,
  including while the app is backgrounded; a flag read at launch and trusted at 03:00 produces an
  `ExactAlarmPermissionException` on the one path with no user in front of it. Two extra
  platform-channel calls per reconcile is the price and it is not worth arguing about.
- **`project()` takes `exact` as a required parameter** so one capability check covers up to 200
  projections. A `project()` that resolves the mode itself is 200 round trips for one answer, and it is
  a named anti-pattern (`08 §2.14`).
- **Alerts off is not an error state.** `cancelAll()`, record `scheduled: 0`, return. The database is
  unchanged and the reminders are all still there; the Reminders screen says so. Do **not** skip
  `recordProjection` on this path — a stale count is exactly the lie the column exists to prevent.
- **Never inside `db.transaction()`, never from a repository, never on the paint frame.** Call site #3
  fires from the **write controller**, after `guard()` has returned. If `reconcile()` appears anywhere
  under `lib/data/*_repository.dart`, the architecture decision #63 rejects has been rebuilt.
- **The debounce silently swallows the second call, and that is correct.** Two writes 200 ms apart
  produce **one** reconcile. A test that calls `reconcile()` twice in a row and expects two `cancelAll`
  entries is asserting the opposite of the requirement. Drive elapsed time with `tester.pump` /
  `fakeAsync` through the binding — never `Future.delayed`, which is banned in tests (`12 §11.6`), and
  never `withClock(Clock.fixed(...))`, which freezes `appNow()` so `_lastRunAt` never ages and every
  subsequent call returns early (decision #113).
- **`_inFlight` returns the *running* future, it does not start a second run.** That is what makes the
  method idempotent under races — two call sites firing in the same frame (boot + resumed, or tap +
  resumed) collapse into one projection.
- **`appNow()` is read once at the top and threaded through.** `CURRENT_TIMESTAMP`, `date('now')` and
  friends are banned in SQL (decision #47), which is why `:after` is a bound parameter.
- **`refreshLocalZone()` at the head of every run is what makes call site #2's "timezone change" claim
  true rather than aspirational.** A shepherd who drives from Ireland to France gets re-projected
  reminders on resume, not on next launch. Until `flutter_timezone` is audited (T02, `08 §11` item 1)
  the call is a seam with no source behind it — keep the call, keep the item in the PR body.
- **The fake's budget tripwire fires at `>= ReminderBudget.forPlatform()`**, so a reconciler that
  slices *after* projecting throws a `StateError` naming decision #63. That is the intended failure and
  it is why the `LIMIT` is in SQL and not in Dart.
- **Cost, measured not assumed.** A full run is four fixed platform-channel calls plus one per
  projection — up to 60 on iOS and 204 on Android. Expect low tens of milliseconds; do not let it block
  a frame. If it does, the answer is scheduling it off the frame, never shrinking the budget.
- **`schedule`, `sync` and `refresh` are banned words for this operation** (`CONVENTIONS §5.2`, R51).
  The method is `reconcile()`, the noun is *projection*, and both are gate rows.

### 5.5 The full test set

`test/data/reconcile_test.dart` — `NativeDatabase.memory()` plus `FakeNotificationScheduler`

| Case | What it asserts |
|---|---|
| `'reconcile is idempotent and projects exactly the soonest 56 of 312'` | **The anchor.** 312 seeded rows → `projected.length == ReminderBudget.forPlatform()`; the ids are the first N by `due_at` ascending; a second run past the debounce yields a byte-identical set |
| `'the rest are still stored'` | The other 312 − N rows are untouched in SQLite. The OS list is a cache; the database is the truth |
| `'the first recorded call of every run is cancelAll'` | `fake.calls.first`, as a plain list comparison. Teardown-and-rebuild |
| `'overdue reminders are never projected and are still counted as stored'` | Three rows with `due_at < now`: zero projections, and `schedulable_total` still counts them. The Android burst-of-pings bug |
| `'muted and completed reminders are never projected'` | The two predicates the honest line shares |
| `'two reconciles inside 500 ms produce one projection'` | The debounce, driven through the binding's clock — not `Future.delayed` |
| `'two concurrent reconciles await the same future'` | `_inFlight`; `fake.calls.where((c) => c == 'cancelAll').length == 1` |
| `'a reconcile after the debounce window runs again'` | The other half — a debounce that never expires is a projection that never updates |
| `'alerts off cancels everything and records scheduled: 0'` | `fake.granted = false`; `cancelAll` recorded, zero projections, and `last_reconcile_scheduled == 0` — **not null** |
| `'canBeExact is asked exactly once per reconcile'` | `fake.calls.where((c) => c == 'canBeExact')` has length 1 for 312 rows |
| `'toggling exactAllowed between runs changes the mode on every projection'` | The fake flips mid-test; nothing is cached across runs |
| `'last_reconcile_scheduled records what was projected, not what was due'` | Seed 312, project N, assert the column equals N and not 312 |
| `'last_reconcile_scheduled is a count and its column carries no InstantConverter'` | §5.3's resolution, held as a test so it cannot silently revert |
| `'reconcile appears in exactly four call sites and none is under lib/data/*_repository.dart'` | Source scan. Today three exist; the file asserts three **and names T07 as the fourth**, so the count is derived from a ledger rather than remembered |
| `'reconcile is never called inside db.transaction('` | Source text over `lib/` |
| `'the projection query uses positional parameters'` | Source text over the generated call site: `soonestPendingReminders(` followed by two positional arguments |
| `'a 400-ewe fixture reconciles without exceeding the fake budget'` | Load `flock_400_3seasons.json` — **after T08 regenerates it**; until then this case is seeded. It is the epic's demo claim, asserted |
| `'a reconcile inside the ambiguous hour projects each row exactly once'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 on 25 October 2026** — the hour that happens twice. `cancelAll()` + one row = exactly one request; a reconcile that ran at both 01:30s must not double-project, and the `due_at > :after` comparison must stay in absolute time |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Never on a write path.** `reconcile()` runs after a write commits, from the write controller, off
  the paint frame. This is the constraint the epic exists to hold and the one a reviewer checks first.
- **`flutter_riverpod` 2.6.1 spellings only.** `FutureProvider`, `keepAlive`, `overrideWith`,
  `unawaited(ref.read(...).then(...))`. Every Riverpod-3 API is a compile error here and a CI grep.
- **`lib/core/db/queries.drift` changes, so `database.g.dart` regenerates in the same commit.** The
  `codegen` job fails on any stale generated file, and a stale one is invisible locally.

## 7. Definition of Done

- [ ] `'reconcile is idempotent and projects exactly the soonest 56 of 312'` passes, and was seen to fail first for the stated reason
- [ ] idempotent — running it twice changes nothing
- [ ] exactly the soonest N are projected and the rest are still stored
- [ ] four call sites, none of them on a write path
- [ ] the assertion reads `FakeNotificationScheduler`'s recorded calls
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the test contains no literal `56` and no literal `200`; the slice is asserted against `ReminderBudget.forPlatform()`
- [ ] `due_at > :after` is present, and an overdue-rows case proves it
- [ ] `canBeExact()` is asked once per run and cached nowhere
- [ ] `last_reconcile_scheduled` holds the projected **count**, §5.3's contradiction is resolved, and `drift_schemas/` did not move
- [ ] `recordProjection` is added to `CONVENTIONS §2.13`, and `03 §5.13` is amended in this commit
- [ ] `reconcile(` appears nowhere under `lib/data/*_repository.dart` and nowhere inside `db.transaction(`
- [ ] `database.g.dart` is regenerated and committed with the `.drift` change

## 8. Verification

```bash
fvm flutter test test/data/reconcile_test.dart
make check
make test
```

```bash
make gen
git diff --exit-code -- drift_schemas/     # MUST be clean: §5.3 step 2
git status --short lib/core/db/            # database.g.dart regenerated, and committed here

# The four call sites, and the places that must not be one of them.
grep -rn 'reconcile()' lib/ | sort
grep -rn 'reconcile' lib/data/*_repository.dart          # expect nothing
grep -rn 'canBeExact' lib/                               # expect one call, in _run

# The two numbers that must not be typed.
grep -rn '\b56\b\|\b200\b' test/data/reconcile_test.dart # expect nothing

TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/data/ --test-randomize-ordering-seed random
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): ReminderReconciler.reconcile(), idempotent and debounced`
