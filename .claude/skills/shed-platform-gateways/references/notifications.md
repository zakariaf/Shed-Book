# Reminders and notifications

Load condition: you are touching a reminder, `NotificationScheduler`, `ReminderReconciler`, a
notification channel, an exact alarm or the Reminders screen's disclosure.

The full specification with its reasoning is `docs/engineering/08-platform-integration.md` §2. The
class surfaces are printed there (§2.3 `NotificationScheduler`, §2.4 `ReminderReconciler`) — copy the
signatures from that file, not from memory. This reference carries the rules and the failure modes.

## Contents

- [The architecture in one line](#the-architecture-in-one-line)
- [The budget and the windowed projection](#the-budget-and-the-windowed-projection)
- [reconcile()](#reconcile)
- [The soonest-N query](#the-soonest-n-query)
- [Ids, payloads and the copy seam](#ids-payloads-and-the-copy-seam)
- [The eight channels](#the-eight-channels)
- [Permission, deferred](#permission-deferred)
- [Exact alarms](#exact-alarms)
- [Reboot](#reboot)
- [Timezone and DST](#timezone-and-dst)
- [Handling a tap](#handling-a-tap)
- [The honest disclosure](#the-honest-disclosure)

## The architecture in one line

SQLite is the only truth. The OS holds a windowed, disposable cache. One idempotent function projects
the soonest N. The `reminders` row is written in the same transaction as the lambing or treatment
that caused it (03 §5.10); nothing about the notification centre is durable.

## The budget and the windowed projection

iOS caps an app at **64 pending notification requests** and the behaviour above the cap is
permanently undefined — three published descriptions disagree and the plugin issue was closed
`not planned`. A 400-ewe flock in one peak week generates roughly **500** pending reminders, an order
of magnitude over the ceiling, so fire-and-forget scheduling is structurally broken and fails
silently: a lamb does not get tubed.

`ReminderBudget.forPlatform()` (R50, `lib/domain/reminder_budget.dart`) returns **56** on iOS (eight
slots of headroom) and **200** on Android (self-imposed; Android documents no cap, and a longer list
is one nobody could act on). The same call slices the projection and feeds the Reminders screen's
copy, so `56` never appears as a literal in an ARB message or a widget.

## reconcile()

`ReminderReconciler.reconcile()` is the only public method on the class (R51,
`lib/data/reminder_reconciler.dart`). It is **debounced to once per 500 ms**, idempotent under
concurrent calls (a second caller awaits the in-flight future), runs off the paint frame, and is
**never** called inside `db.transaction()`.

Its body, in order: `refreshLocalZone()` → `alertsGranted()` (if false: `cancelAll()`, record a
projection of 0, return) → `canBeExact()` **once** → the soonest-N query → `cancelAll()` → one
`project(…, exact: exact)` per row → `SettingsRepository.recordProjection(...)`.

**Teardown-and-rebuild, never a diff.** `pendingNotificationRequests()` returns only id, title, body
and payload, so a diff would need a content hash smuggled into the payload and still could not see
that the Android schedule mode changed. Pending requests are invisible to the user, so churn is free.

**Four call sites, and no others** (decision #63):

1. App start, after the DB opens — recovers from a kill, a reboot, an OS purge or a restore.
2. `AppLifecycleState.resumed` — timezone change, permission change, exact-alarm grant.
3. After any write touching `Reminder`, `Lambing`, `Treatment` or the interval settings.
4. After a notification tap — completing one frees a slot for the 57th.

## The soonest-N query

A named `.drift` query in `lib/core/db/queries.drift`, over `idx_reminder_due_open`, with both
variables typed explicitly (08 §2.4 prints it). Two predicates are load-bearing:

- **`due_at > :after`.** Android's `AlarmManager` fires an already-past alarm **immediately**, so
  projecting twelve overdue reminders gives the shepherd twelve pings in one second on every resume.
  iOS simply never fires a past trigger, so the bug is Android-only and will not reproduce on an
  iPhone. Overdue reminders belong in the Reminders screen's "Overdue" bucket.
- **`completed_at IS NULL AND muted = 0`** must stay byte-identical to the Reminders screen's
  `schedulable_total`, or the screen's honest line becomes a lie by arithmetic. The two deliberately
  differ on `due_at > :after` only: "stored in the app" and "on your lock screen" are different
  claims, which is the point of the line.

drift generates **positional** parameters for a named query's variables, in declaration order — a
named-argument call would not compile.

## Ids, payloads and the copy seam

The notification id **is** `reminders.id`. Never derive one from `uid.hashCode`: it overflows int32
and collides silently, and the collision looks like a reminder that "didn't fire".

The payload is `reminder:<id>` and carries nothing else. A notification body is readable on a locked
phone, so: the tag, the kind's label, the interval the user set and (for `withdrawal_end`) the clear
date may appear; a product name, a batch number, a withdrawal period in days or any note text may
not. Safety rule §12.2 binds hardest here because nobody reviews a string that only ever appears on a
lock screen — *"Colostrum — your 2 h interval"* is a fact about a setting; *"Colostrum is needed
within 2 hours"* is veterinary advice and is banned.

`lib/data/` cannot import `AppLocalizations` (layer rule 4), so every user-visible string arrives
from above as a `NotificationCopy`, built by `lib/features/reminders/reminder_copy.dart` and
installed by `installCopy()` in `lib/app.dart`'s post-frame boot kick **before** the first
`reconcile()`. `project()` throws `StateError` if no copy is installed — the alternative is a blank
notification at 3am. `reminders.title` is written by the repository through
`NotificationScheduler.titleFor()` and stored as a record of what the app said.

## The eight channels

**R49: there is one set of strings.** The Android channel id is byte-identical to `reminders.kind`,
whose CHECK in `03-data-model-and-schema.md` §5.10 is the authority for all eight. Decision #65's
`turnout`, `dose` and `withdrawal` match no kind and are **banned channel ids**. A test asserts the
channel-id set against the committed `drift_schemas/drift_schema_v<N>.json`, and channel ids are
frozen at release.

- Eight channels, not one — muting tag-by spam must not silence colostrum.
- Names are nouns, never clinical claims: "Colostrum", not "Colostrum window".
- `ChannelImportance` is ours (`high` / `normal`), mapped at the plugin call. Importance is an
  **initial value only**: after creation the user owns it, `createNotificationChannel` can lower but
  never raise it, and Android restores a deleted channel's old settings if you recreate the same id.
  Never rely on importance for correctness and never delete-and-recreate to "fix" one.
- No custom sound (an unfamiliar sound at 3am is worse than the familiar one), no badge count, no
  full-screen intent.

## Permission, deferred

`POST_NOTIFICATIONS` is requested from **exactly two explicit taps** — "Turn on alerts" on the
Reminders screen, and Settings ▸ Reminders — and from no write path. Reminder rows are created
automatically inside lambing and treatment transactions, so "ask when the user creates a reminder"
read literally puts a system dialog on screen at 03:24 during a lambing.

Because nothing is ever prompted automatically there is **no state to remember**: no "we already
asked" flag, no cooldown, no new `app_settings` column. If you are adding one, the prompt has escaped
to an automatic path. Until alerts are granted, rows are written and listed normally, `reconcile()`
projects nothing, and the screen says so.

## Exact alarms

Declare `SCHEDULE_EXACT_ALARM` (user-granted). **`USE_EXACT_ALARM` is a Play removal** — it is
restricted to alarm/timer and calendar apps. Note that the `notify.use_exact_alarm` policy rule scans
`.dart` files only and cannot see `android/`; **G1 on the merged manifest of the shipped `.aab` is
the gate that actually keeps it out of a release.**

`canBeExact()` is asked **once per reconcile and never cached** — not in a field, not in an
`app_settings` column. The user can revoke Alarms & reminders while the app is backgrounded, and a
flag read at launch and trusted at 03:00 throws `ExactAlarmPermissionException` on the one path with
no user in front of it. The answer is passed down as `project(…, exact:)` so 200 projections cost one
capability check.

`true` → `AndroidScheduleMode.exactAllowWhileIdle`; `false` → `inexactAllowWhileIdle`. Plain `exact`
is never used (it does not survive Doze, which is what a phone in a coat pocket at 04:00 is in) and
`alarmClock` is never used (it plants a system alarm icon and reads as "your alarm clock is set").
That ternary is the only place `AndroidScheduleMode` is named in the app.

While exact alarms are denied, every reminder row carries an **"approximate" chip — icon *and* text,
never colour alone** (#106) — and the disclosure box gains a fourth line offering a 72 pt action that
calls `requestExactAlarms()`. Granting it sends the user to system Settings; returning produces
`resumed`, which is call site 2, which re-projects everything as exact. No broadcast receiver is
needed for that.

## Reboot

Android destroys `AlarmManager` alarms on reboot. The plugin's `ScheduledNotificationBootReceiver`
replays them, but **the plugin has declared neither receiver itself since v16** — both receiver
blocks and `RECEIVE_BOOT_COMPLETED` are ours to declare (08 §8.3 prints them; copy from there, not
from a blog post). iOS keeps pending requests across a reboot with no work from us.

The boot replay re-uses the **persisted** schedule mode, which may be stale if the exact-alarm
permission changed while the phone was off — which is why it is a backstop and `reconcile()` at next
launch is the mechanism.

## Timezone and DST

`package:timezone` exists in this app for exactly one reason: `zonedSchedule` takes a `tz.TZDateTime`.
It is confined to `NotificationScheduler` (R48). Import `package:timezone/data/latest_10y.dart`,
never `latest` — every instant this app converts is weeks away at most.

`tz.setLocalLocation` is called from exactly two places, both in that file: `initialize()` and
`refreshLocalZone()`, the latter at the head of every `reconcile()`. That is what makes call site 2's
"timezone change" a behaviour rather than a claim.

`scheduleTimeFor(Instant)` is a **top-level public function** in `notification_scheduler.dart`
(08 §2.3), so the DST-8 invariant can call it from `test/` without a `@visibleForTesting` hole. It is
a *rendering* of an instant in a zone, never a shift of the instant. R48's original line calling it a
private method is superseded by 08 §2.3.

Offset-from-event kinds (`colostrum`, `navel`, `turn_out`, `second_dose`, `withdrawal_end`) are
computed as `event.plus(Duration(...))` and have **no DST exposure**. Only wall-clock kinds
(`tag_by`, and `custom` with a time) do. For UK/Ireland the ambiguous hour is **01:00–01:59**:

- No wall-clock default is ever inside it. `tag_by` defaults to **08:00 local**.
- Spring forward: `DateTime(2026, 3, 29, 1, 30)` silently returns `02:30`. `checkLocalWallTimeExists`
  raises `WarningCode.timeDoesNotExistLocally`, the app **shows** it — *"The clock skipped 01:30 that
  night (clocks went forward). Saved as 02:30."* — and stores the resolved instant. Never silently
  moved, never refused (safety rule §12.4).
- Autumn back: the hour happens twice, Dart picks one, and **no warning is raised** — the displayed
  time still matches what the shepherd typed. It fires once, because `cancelAll()` + one row is
  exactly one request.
- **`matchDateTimeComponents` is banned outright.** Recurrence state would live in the OS rather than
  in SQLite, and it drifts across DST. Every reminder is a one-shot row the projection re-creates.

`test/data/reminder_dst_test.dart` carries `@Tags(['uk-zone'])` and DST-6 through DST-9. CI runs the
suite twice: `TZ=Europe/London`, and `TZ=Pacific/Chatham --exclude-tags uk-zone` as the hostile zone
that catches any assumption of whole-hour offsets.

## Handling a tap

**One destination: the Reminders screen.** Resolve the payload to a `ReminderId`, push
`RouteNames.reminders` through `Routes.navigatorKey`, then reconcile. Do **not** read the database on
the tap path to decide which animal to open — that is an async hop before the first paint, on the one
path where the phone has been asleep, to save a tap the shepherd is about to make anyway.

Cold launch by tap uses `getNotificationAppLaunchDetails()`, read **once** inside the post-frame boot
kick and never before `runApp()`. **There are no notification action buttons in v1**, therefore no
background isolate handler, no `@pragma('vm:entry-point')` callback and no second copy of the routing
logic.

## The honest disclosure

The OS list and the app list deliberately disagree, and `07-screens.md` §11.2 owns the copy. Two
facts make it true: `reconcile()` itself writes `app_settings.last_reconcile_scheduled`, so the
number is what was **projected**, not what was intended; and `ReminderBudget.forPlatform()` is the
same constant on both sides. Never write "some reminders may not fire" — they will fire; they are
simply not on the lock screen yet, and they enter the window as nearer ones complete.
