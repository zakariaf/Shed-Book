# 08 — Platform integration

This document governs every place Shed Book touches the operating system: local notifications, photo capture, audio recording, the share sheet, backup file selection, the wakelock, and the permission each of those costs. It fixes the **gateway pattern** — one hand-written class per plugin, in `lib/data/`, faked in tests — and it homes and specifies the three gateways `CONVENTIONS.md` R9 named but left unwritten: `CameraService`, `VoiceRecorder`, `WakelockController`. Read it before you add a plugin, before you write a line inside `lib/data/notification_scheduler.dart`, and before you touch `AndroidManifest.xml` or `Info.plist`. It is also the document that records why tag OCR and voice tag entry are not in v1 (§10), so that decision does not get quietly reversed by someone reading spec §7.1 in isolation.

**Toolchain.** Flutter **3.44.8** stable, Dart **3.12.2**, pinned via FVM (decision #1). Every version number below comes from decision-record §5 and from nowhere else — not from a README, not from memory, not from `pub add`.

> **Decisions applied:** #63 reminder scheduling (`reconcile()`, never `zonedSchedule()` on write) · #64 the Reminders screen's honest line · #65 notification channels and deferred permission · #48 `package:timezone` confined to the notification seam · #7 Flutter's `offline-first` design pattern is deliberately not followed (Shed Book is offline-**only**) · #40 media on the filesystem, relative paths, 2048 px JPEG q80, AAC-LC `.m4a` · #75 tag OCR cut, both platforms · #76 voice tag entry cut from v1; the voice *note* ships · #77 `image_picker` + `flutter_image_compress`, never `camera` · #78 no permission package · #79 wakelock: default-off, session-scoped, 30-minute expiry, released on any non-resumed state · #80 share sheet: `SharePlus.instance.share(ShareParams(...))` · #81 file import: `file_selector`, magic bytes validated by us · #85 media is not in the v1 backup · #101 gesture ban (no press-and-hold) · #106 colour is never the only channel · #112 hand-written fakes for all six gateways · #122 the two mechanical offline gates · #123/#124 no telemetry, redaction rules · #125 off-isolate work is PDF and image downscaling only · **§1 #5** the manifest-merger prerequisite, with the permission set itself in §3.3, including `com.android.vending.BILLING`.
>
> **One citation needs disambiguating, because the decision record numbers two things "5".** Where this document writes **§1 #5** it means the fifth *pre-commit* decision — "run the manifest-merger check against a real release AAB before writing any `tools:node="remove"` line, and add `com.android.vending.BILLING` to the permission list" — and never §2's decision #5, which is about committing a resolved `pubspec.lock`. Every other `#n` in this document is a §2 row.
>
> **CONVENTIONS rulings adopted, not re-opened:** R9 (`CameraService` · `VoiceRecorder` · `WakelockController`, those exact names) · R47 (capture belongs to the gateways, not to `MediaStore`) · R48 (the tz seam is inside `NotificationScheduler`; `lib/features/reminders/notification_gateway.dart` does not exist) · R49 (reminder kinds **are** the Android channel ids — 03's eight strings, byte-identical) · R50 (`ReminderBudget.forPlatform()`) · R51 (`ReminderReconciler.reconcile()`; `schedule(` on a reminder object is a policy-rule row) · R71 (the collective noun is **gateway**).
>
> **Owner rulings applied (decision-record §7.0):** tag OCR and voice tag entry are **cut from v1** (§10); tags are unique among **active** animals only; region one is **UK / Ireland** — `en_GB`, 24-hour, `d MMM y` in front of a human, ambiguous DST hour **01:00–01:59** (§2.11); the free tier is season-primary with the ewe cap secondary and **never surfaces between 22:00 and 06:00**, which is why nothing in this document renders a monetization surface.

---

## 1. The service boundary

### 1.1 The rule

Every native capability sits behind a **hand-written class in `lib/data/` that wraps exactly one plugin**, exposes only the verbs this app needs, and is replaced by a hand-written fake in tests (decision #112). There are six. They are called **gateways**; "platform service", "adapter", "wrapper" and "client" are banned synonyms (R71).

| Gateway | File | Wraps | Specified in |
|---|---|---|---|
| `NotificationScheduler` | `lib/data/notification_scheduler.dart` | `flutter_local_notifications` **and `package:timezone`** | §2 |
| `CameraService` | `lib/data/camera_service.dart` | `image_picker` | §3 |
| `VoiceRecorder` | `lib/data/voice_recorder.dart` | `record` | §4 |
| `ShareService` | `lib/data/share_service.dart` | `share_plus` | §5 |
| `WakelockController` | `lib/data/wakelock_controller.dart` | `wakelock_plus` | §7 |
| `MediaStore` | `lib/data/media_store.dart` | `path_provider` + `flutter_image_compress` | [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §4 |

Their providers are `CONVENTIONS.md` §3.1's, unchanged: `notificationSchedulerProvider` (`FutureProvider<NotificationScheduler>`, because `initialize()` is async), `cameraServiceProvider`, `voiceRecorderProvider`, `shareServiceProvider`, `mediaStoreProvider` and `wakelockProvider` (plain `Provider`s, keepAlive). Non-plugin services in the same layer: `ReminderReconciler`, `RestoreService`, `MediaSweeper`.

**Why this and not "just call the plugin".** Three reasons, in order of how much they cost you when ignored:

1. **A fake that wraps the plugin tests nothing.** If `image_picker` is imported in two places, the fake covers one of them and the other is untested forever. One import site is the whole property.
2. **Plugin APIs churn.** `flutter_local_notifications` made every parameter named in v20 and renamed the iOS classes in v19; `record` renamed its class from `Record` to `AudioRecorder`; `share_plus` deprecated its entire static API. A gateway turns each of those into a one-file edit.
3. **Layer rule 4 bans `package:flutter/material.dart` in `lib/data/`.** Anything a gateway hands upward is a plain value — a path, an `Instant`, a `bool` — never a widget, never a `BuildContext`.

**No plugin type crosses a gateway's boundary in either direction.** Not `ImageSource`, not `Amplitude`, not `Importance`, not `AndroidScheduleMode`, not `ShareResultStatus`. Each of those would drag its `package:` import into `lib/features/` and make `layer.plugin_*` unsatisfiable — the confinement rule and the plugin-free public surface are the same rule seen from two ends. Every gateway below therefore declares its own small enum or record for anything it accepts or returns, and translates at the plugin call.

### 1.2 The gate

Confinement is mechanical, not a review habit. [`01-architecture.md`](01-architecture.md) §3.2 owns `tool/check_policy.dart`'s rule tables; this document requires one new table there, keyed **package → the file(s) permitted to import it**:

```dart
/// Package → the file(s) permitted to import it. A plugin import outside its
/// gateway means the hand-written fake is no longer testing the real path
/// (decision #112). Same shape as 01 §3.2's `_bannedPackages`.
const _confinedPackages = <String, Set<String>>{
  'package:flutter_local_notifications/': {'lib/data/notification_scheduler.dart'},
  'package:timezone/':                    {'lib/data/notification_scheduler.dart'},  // R48
  'package:image_picker/':                {'lib/data/camera_service.dart'},
  'package:record/':                      {'lib/data/voice_recorder.dart'},
  'package:share_plus/':                  {'lib/data/share_service.dart'},
  'package:wakelock_plus/':               {'lib/data/wakelock_controller.dart'},
  'package:flutter_image_compress/':      {'lib/data/media_store.dart'},
  'package:path_provider/':               {'lib/data/media_store.dart',
                                           'lib/core/db/connection.dart'},          // layer.path_provider
  'package:file_selector/':               {'lib/features/settings/restore_flow.dart'}, // §6
};
```

**One entry needs a second permitted file, which is why the value is a `Set<String>` and not a `String`.** `package:path_provider/` is imported by `lib/core/db/connection.dart` as well as by `MediaStore` (04 §4.3 already states `MediaStore` is otherwise the only caller of `getApplicationSupportDirectory()`).

**The rule ids, spelled out so nobody derives a second spelling.** `path_provider`'s row is not new and its id is already catalogued: `CONVENTIONS.md` §4.7 renames 04's `path_provider_confined` to **`layer.path_provider`**, and that is the id this table uses. The other eight rows are new and are `layer.plugin_<package>`, where `<package>` is the pub package name exactly: `layer.plugin_flutter_local_notifications`, `layer.plugin_timezone`, `layer.plugin_image_picker`, `layer.plugin_record`, `layer.plugin_share_plus`, `layer.plugin_wakelock_plus`, `layer.plugin_flutter_image_compress`, `layer.plugin_file_selector`. Nine rows, nine ids, no abbreviations.

### 1.3 The one plugin with no gateway, and why

`file_selector` is called from exactly one file — `lib/features/settings/restore_flow.dart` — and has no gateway class. This is deliberate, and it is the only exception:

- A system document picker is **out-of-process UI**. A fake would assert that we called a function; it would prove nothing about the picker. The meaningful seam is *"an absolute path arrives"*, and `RestoreService.restoreFrom(File)` is that seam — fakeable with a temp file, exercised by every restore test. That verb is **new**: 04 §7.2 describes the step ("copy the picked file to `<temp>/restore/incoming.json`") without naming a method, and `CONVENTIONS.md` §2.8 lists only `RestoreOutcome` and `completeInterruptedRestore(Directory)` beside the class. `Future<RestoreOutcome> restoreFrom(File backup)` is a new verb on an existing service, flagged in §11 rather than added silently.
- Adding a seventh gateway means adding a seventh name to `CONVENTIONS.md` §2.12, which this document is not entitled to do.
- The single-call-site guarantee that a gateway buys is bought here by the `layer.plugin_file_selector` rule instead, which is the same guarantee by the same mechanism.

`restore_flow.dart` is one function (§6). It is a file addition to `CONVENTIONS.md` §1's `lib/features/settings/` folder, follows §4.1's `lower_snake_case.dart` rule, and is flagged here rather than added silently.

---

## 2. Notifications

### 2.1 The architecture, stated once

**SQLite is the only truth. The OS holds a windowed, disposable cache. One idempotent function projects the soonest N.**

The `reminders` row is written in the same transaction as the lambing or the treatment that caused it ([`03-data-model-and-schema.md`](03-data-model-and-schema.md) §5.10). Nothing about the notification centre is durable: `ReminderReconciler.reconcile()` tears the OS list down with `cancelAll()` and rebuilds it from the database. There is no `os_notification_id` column and adding one is a defect — a stored OS id is a second source of truth that goes stale on the next reconcile.

**`zonedSchedule()` is never called on a write path.** A platform-channel round-trip inside a drift transaction is banned outright: it holds a write transaction open across an `await` on the 3am path, and it schedules against a budget it cannot see. R51 makes `schedule(`-on-a-reminder-object a policy-rule row (`db.reminder_schedule`, scoped to `lib/data/reminder_repository.dart`) because that spelling *is* the architecture decision #63 rejects.

### 2.2 The budget, and the flock that breaks the naive design

Apple's limit is **64 pending notification requests per app**, stated by an Apple engineer on Developer Forums thread 811171: *"there is a limit of 64 … This is a system limit and there is no way around it."* Three descriptions of what happens above it exist and they disagree — the `flutter_local_notifications` README says the last 64 set are kept, the forum implies the soonest, and issue #2312 reports that at 65+ **nothing fired at all**; that issue was closed `not planned`. **Treat the failure mode as undefined and never approach the ceiling.**

Now the arithmetic. Spec §7.6 lists reminder types; 03's `reminders.kind` CHECK carries eight. A 400-ewe flock in one peak week produces, on note 06's shape:

| Source | Count |
|---|---|
| ~60 lambings × {colostrum, navel, turn out} | 180 |
| tag-by on ~120 lambs | 120 |
| ring / dock / castrate on ~120 lambs | 120 |
| second doses + withdrawal ends on ~40 treatments | 80 |
| **Total pending** | **~500** |

Five hundred rows against a sixty-four-slot budget. Fire-and-forget scheduling is not "mostly fine, occasionally lossy" — it is **structurally broken**, and it breaks silently, by dropping reminders nobody can see were dropped. In a shed that means a lamb does not get tubed. The exact figure depends on which types the shepherd enabled and is not worth quoting to two significant figures; what matters is that it is an order of magnitude above the ceiling.

```dart
// lib/domain/reminder_budget.dart — pure Dart. dart:io is permitted by layer rule 1.
import 'dart:io' show Platform;

/// R50. Both `ReminderReconciler` and the Reminders screen read this; the
/// number 56 never appears in copy, only through this call.
abstract final class ReminderBudget {
  /// 64 is the hard iOS limit and the behaviour above it is undefined.
  /// Eight slots of headroom.
  static const int ios = 56;

  /// Android documents no cap. 200 is a self-imposed sanity bound: it keeps
  /// the reconcile loop to ~200 platform-channel calls, and a projection
  /// bigger than that is a list nobody could act on anyway.
  static const int android = 200;

  static int forPlatform() => Platform.isIOS ? ios : android;
}
```

### 2.3 `NotificationScheduler` — the surface

```dart
// lib/data/notification_scheduler.dart
// The ONLY file in the app that imports flutter_local_notifications or
// package:timezone (R48; layer.plugin_flutter_local_notifications and
// layer.plugin_timezone, §1.2).
// Bodies are elided except where the body IS the specification.
final class NotificationScheduler {
  NotificationScheduler(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;
  NotificationCopy? _copy;

  /// Called once, by notificationSchedulerProvider, after the first frame.
  /// Does three things and no more: loads the IANA rules, sets tz.local, and
  /// initialises the plugin with every request* flag FALSE — initialize()
  /// must never raise a prompt.
  Future<void> initialize({required void Function(int reminderId) onTap});

  /// Re-reads the device zone and re-points tz.local at it. Called by
  /// reconcile() before it projects anything, which is what makes call site
  /// #2's "timezone change" claim true rather than aspirational (§2.11).
  Future<void> refreshLocalZone();

  /// Installs the localised strings and creates/updates the eight Android
  /// channels. Must run before the first project(). See §2.6.
  Future<void> installCopy(NotificationCopy copy);

  /// The ONLY permission call in this class. Never called from a write path.
  /// Wraps AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()
  /// and the Darwin resolver's requestPermissions(alert:badge:sound:) (§8.2).
  Future<bool> requestAlerts();
  Future<bool> alertsGranted();

  /// Wraps the Android resolver's canScheduleExactNotifications(), i.e.
  /// AlarmManager.canScheduleExactAlarms(). Returns true on iOS, which has no
  /// equivalent restriction. Asked once per reconcile; never cached (§2.9).
  Future<bool> canBeExact();

  /// Wraps the Android resolver's requestExactAlarmsPermission(), which sends
  /// the user to Settings ▸ Alarms & reminders. Two explicit taps only (§8.2).
  Future<void> requestExactAlarms();

  Future<void> cancelAll();

  /// `exact` is decided ONCE per reconcile by ReminderReconciler and passed
  /// down, so 200 projections cost one capability check, not 200 (§2.9).
  Future<void> project(ProjectedReminder r, {required bool exact});

  /// Diagnostics and tests only. Never a source of truth (§2.1).
  Future<List<int>> pendingIds();

  /// Cold launch from a tap. Read once, during the boot kick (§2.12).
  Future<ReminderId?> launchTapTarget();

  String titleFor(String kind, {String? tag});
  String bodyFor(String kind, {String? tag});
}

/// R48: the one tz conversion in the app, and deliberately a TOP-LEVEL public
/// function in this file rather than a private method — the DST-8 invariant
/// (§2.11) has to be able to call it from test/. It is a RENDERING of an
/// instant in a zone, never a shift of the instant.
tz.TZDateTime scheduleTimeFor(Instant when) =>
    tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, when.epochMillis);

/// What crosses from the reconciler to the OS. Nothing else does.
typedef ProjectedReminder = ({
  ReminderId id,
  String kind,     // one of 03 §5.10's eight; also the channel id (R49)
  Instant dueAt,
  String? tag,     // the animal's tag, or null
});
```

`initialize()` sets `requestAlertPermission: false`, `requestBadgePermission: false`, `requestSoundPermission: false` in `DarwinInitializationSettings`. Letting `initialize()` fire the prompt is spec §5's "notification permission nag" arriving at first launch, and it is the single easiest way to lose this property — the plugin's defaults are `true`.

**Timezone setup lives here and only here.** `initialize()` calls `tz.initializeTimeZones()` — from `package:timezone/data/latest_10y.dart`, never `latest` (§2.11) — and then `tz.setLocalLocation(tz.getLocation(<the device's IANA name>))`. This is the work [`01-architecture.md`](01-architecture.md) §6.3's post-frame table assigns to "the notification seam only", and it is the only place `tz.setLocalLocation` is ever called. **What supplies the IANA name is not yet decided:** `flutter_timezone` is the obvious candidate and has not been audited, which is §11 item 1 and is release-blocking. Until that audit lands, this line is unwritten, not "written with a TODO".

**API shape, verified against v22 (note 06 §1.2).** Everything went **named** in v20; the positional form does not compile. `zonedSchedule` requires `androidScheduleMode` since v18, and `uiLocalNotificationDateInterpretation` was removed in v19. Inside `project()`:

```dart
await _plugin.zonedSchedule(
  id: r.id.value,
  title: titleFor(r.kind, tag: r.tag),
  body: bodyFor(r.kind, tag: r.tag),
  scheduledDate: scheduleTimeFor(r.dueAt),
  notificationDetails: _detailsFor(r.kind),
  androidScheduleMode: exact                      // the caller's flag, §2.9
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle,
  payload: 'reminder:${r.id.value}',
);
```

That ternary is the **only** place `AndroidScheduleMode` is named in the app, which is what keeps the plugin enum on this side of the boundary (§1.1).

> **Verify before writing the permission calls.** v19 renamed the iOS/macOS **settings and details** classes with a `Darwin` prefix. Note 06 §9 still spells the resolver `IOSFlutterLocalNotificationsPlugin`. Resolve the type against the installed 22.2.0 API surface, in one place, on the day you write `requestAlerts()`. Getting this wrong is a compile error, not a silent bug — but do not copy either spelling from a doc.

### 2.4 `ReminderReconciler.reconcile()`

```dart
// lib/data/reminder_reconciler.dart — R51. One public method.
final class ReminderReconciler {
  ReminderReconciler({
    required AppDatabase db,
    required NotificationScheduler scheduler,
    required SettingsRepository settings,   // app_settings is SettingsRepository's
  })  : _db = db,
        _scheduler = scheduler,
        _settings = settings;

  final AppDatabase _db;
  final NotificationScheduler _scheduler;
  final SettingsRepository _settings;

  static const _debounce = Duration(milliseconds: 500);
  Instant? _lastRunAt;
  Future<void>? _inFlight;

  Future<void> reconcile() async {
    final now = appNow();                                 // the one clock, #46
    final last = _lastRunAt;
    if (last != null && now.difference(last) < _debounce) return;
    final running = _inFlight;
    if (running != null) return running;                  // idempotent under races
    final run = _run(now);
    _inFlight = run;
    try {
      await run;
    } finally {
      _inFlight = null;
      _lastRunAt = appNow();
    }
  }

  Future<void> _run(Instant now) async {
    // The device may have crossed a zone since the last run. Cheap, and it is
    // what makes call site #2 honest (§2.11).
    await _scheduler.refreshLocalZone();

    // Alerts off? The database is unchanged and the OS list is empty. The
    // Reminders screen says so; it does not pretend the reminders are gone.
    if (!await _scheduler.alertsGranted()) {
      await _scheduler.cancelAll();
      await _settings.recordProjection(scheduled: 0, at: now);
      return;
    }

    // Asked ONCE per reconcile and never cached (§2.9). The user can revoke
    // it in system Settings between two runs, so a stored flag goes stale and
    // the next exact call throws.
    final exact = await _scheduler.canBeExact();

    // drift generates POSITIONAL parameters for a named .drift query's
    // variables, in declaration order. `after:` / `limit:` would not compile.
    final due = await _db
        .soonestPendingReminders(now.epochMillis, ReminderBudget.forPlatform())
        .get();

    await _scheduler.cancelAll();          // teardown, then rebuild — see below
    var projected = 0;
    for (final r in due) {
      await _scheduler.project(
        (
          id: ReminderId(r.id),
          kind: r.kind,
          dueAt: Instant(r.dueAt),
          tag: r.eweTag ?? r.lambTag,
        ),
        exact: exact,
      );
      projected++;
    }
    await _settings.recordProjection(scheduled: projected, at: now);
  }
}
```

The query is a named `.drift` query in `lib/core/db/queries.drift`, using `idx_reminder_due_open`. Both variables are typed explicitly, in 03's house style (§7's `earlierAnimalsWithTag`), so drift never has to infer an `int` from a `LIMIT`:

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

**`due_at > :after` is load-bearing, not tidiness.** On Android, `AlarmManager` fires an alarm whose trigger time is already past **immediately**. Project twelve overdue reminders and the shepherd gets twelve pings in one second, every time the app resumes. On iOS a past `UNCalendarNotificationTrigger` simply never fires, so the bug is Android-only and will not reproduce on an iPhone. Overdue reminders live on the Reminders screen, in the "Overdue" bucket, where they belong.

**`muted = 0` matches the Reminders screen's `schedulable_total`.** The screen's honest line compares two numbers; if the projection and the count applied different *eligibility* predicates the line would be a lie by arithmetic ([`07-screens.md`](07-screens.md) §11.1). The two do differ on `due_at > :after`, and that difference is deliberate and not a bug: `schedulable_total` counts every open unmuted reminder including overdue ones, because they *are* stored in the app, while the projection excludes overdue ones because the OS cannot usefully hold them. "Stored in the app" and "on your lock screen" are different claims, which is the whole point of the line. `completed_at IS NULL` and `muted = 0` must stay byte-identical in both.

**Teardown-and-rebuild, never a diff.** `pendingNotificationRequests()` returns only id, title, body and payload. A diff would need a content hash smuggled into the payload and *still* could not see that the Android schedule mode changed when the user granted exact alarms. `cancelAll()` + rebuild is ten lines instead of eighty and cannot drift. Pending requests are invisible to the user, so churn costs nothing.

**Four call sites, and no others** (decision #63, mirrored in [`02-state-di-navigation.md`](02-state-di-navigation.md) §9.1 and [`07-screens.md`](07-screens.md) §17.2):

| Trigger | Why |
|---|---|
| App start, after the DB opens | recover from a kill, a reboot, an OS purge, a restore |
| `AppLifecycleState.resumed` | timezone change, permission change, exact-alarm grant, notifications delivered while away |
| After any write touching `Reminder`, `Lambing`, `Treatment` or the interval settings | every write commits immediately; so must the projection |
| After a notification tap | the 57th reminder can now enter the window |

Debounced to once per 500 ms, run off the paint frame, never inside `db.transaction()`. On a 400-ewe device a full run is four fixed platform-channel calls (`refreshLocalZone`, `alertsGranted`, `canBeExact`, `cancelAll`) plus one per projection — so up to 60 on iOS and 204 on Android. Measure it, expect low tens of milliseconds, and do not let it block a frame.

`last_reconcile_scheduled` is written by `SettingsRepository.recordProjection()` in the same transaction that records the projection — it stores **what was projected**, not what was intended, which is what makes 07's honest line honest. That column is R40's; it must exist in `03-data-model-and-schema.md` §5.13.

### 2.5 Ids and payloads

**The notification id is `reminders.id`.** It is `INTEGER PRIMARY KEY AUTOINCREMENT`, stable, and comfortably inside int32 for any real flock; assert it. Deriving an id from `uid.hashCode` collides and overflows int32 — that is note 06's pitfall #2 and it is a silent one, because the collision looks like a reminder that "didn't fire".

**The payload is `reminder:<id>` and carries nothing else.** A notification body sits on a lock screen and is readable without unlocking the phone. Spec §4.5 calls treatment records and losses commercially sensitive, so:

| On the lock screen | Never on the lock screen |
|---|---|
| The animal's tag | The medicine's product name or batch number |
| The reminder kind's label | The withdrawal period in days |
| For `withdrawal_end`, the clear date as `d MMM y` with its "as you entered it" framing (§12.1) | Any note text, any free-text field |
| The interval the user set | Anything phrased as a clinical window (§12.2) |

**§12.2 binds hardest here**, because a notification body is the copy least likely to be reviewed — nobody reads a string that only ever appears on a lock screen. *"Colostrum — your 2 h interval"* is a fact about a setting the shepherd chose. *"Colostrum is needed within 2 hours"* is veterinary advice and is banned.

### 2.6 The copy seam

`lib/data/` may not import `package:flutter/material.dart` (layer rule 4), and the generated `AppLocalizations` does. So the gateway cannot localise anything, and every user-visible string it hands to the OS must arrive from above:

```dart
// lib/data/notification_scheduler.dart
final class NotificationCopy {
  const NotificationCopy({
    required this.channels,
    required this.title,
    required this.body,
  });
  final List<NotificationChannelSpec> channels;   // eight, §2.7
  final String Function(String kind, String? tag) title;
  final String Function(String kind, String? tag) body;
}

typedef NotificationChannelSpec = ({
  String id,               // === reminders.kind (R49)
  String name,
  String description,
  ChannelImportance importance,
});

/// OURS, not the plugin's. `Importance` lives in flutter_local_notifications
/// and `lib/features/` may not import it (§1.1). The gateway maps
/// high -> Importance.high, normal -> Importance.defaultImportance.
enum ChannelImportance { high, normal }
```

It is built at the presentation edge and installed once per run:

```dart
// lib/features/reminders/reminder_copy.dart — may see AppLocalizations and Terminology
NotificationCopy buildNotificationCopy(AppLocalizations l10n, Terminology terms);
```

`_ShedBookAppState`'s post-frame boot kick installs it **before** the first `reconcile()`, in one chain, so the ordering is structural rather than hopeful:

```dart
// lib/app.dart — one async method, started from the existing post-frame
// callback (01 §6.3) and deliberately NOT awaited on the frame. The chain
// inside it IS awaited, which is where the ordering guarantee comes from.
Future<void> _bootNotifications() async {
  final scheduler = await ref.read(notificationSchedulerProvider.future);
  await scheduler.installCopy(
    buildNotificationCopy(AppLocalizations.of(context)!, ref.read(terminologyProvider)),
  );
  await (await ref.read(reminderReconcilerProvider.future)).reconcile();
}

// …inside addPostFrameCallback, beside `ref.read(databaseProvider.future).ignore()`:
_bootNotifications().ignore();          // dart:async — 01 §6.3's spelling
```

`main()` still awaits nothing and the post-frame callback still returns synchronously (decision #21, §1 pre-commit decision #4). A failure inside the chain surfaces through `notificationSchedulerProvider`'s `AsyncError`, exactly as a failed DB open surfaces through `databaseProvider`'s.

`project()` throws `StateError` if no copy is installed. That is deliberate: the alternative — projecting a reminder with an empty title — is a blank notification at 3am.

The same seam solves `reminders.title`. The column is `TEXT NOT NULL` and is written by the repository inside the lambing/treatment transaction; the repository already holds a `NotificationScheduler` ([`01-architecture.md`](01-architecture.md) §4.2 shows `LambingRepository` taking one), so it calls `_reminders.titleFor(kind, tag: tag)`. The stored title is a **record of what the app said**, in the same spirit as the stored `clear_date`: a later terminology edit does not rewrite the reminder a shepherd already read.

### 2.7 Android notification channels

**R49: there is one set of strings.** `03-data-model-and-schema.md`'s `reminders.kind` CHECK is the channel-id list, byte for byte. Decision #65's wording (`turnout`, `dose`, `withdrawal`) is superseded — those three match no kind and are **banned channel ids**. Channel ids are frozen at release, so this must be right before the first release.

| Channel id = `reminders.kind` | Name (ARB) | Initial importance |
|---|---|---|
| `colostrum` | Colostrum | `high` |
| `navel` | Navel dip | `normal` |
| `turn_out` | Turn out | `high` |
| `tag_by` | Tag-by date | `normal` |
| `ring_dock_castrate` | Ring, dock, castrate | `normal` |
| `second_dose` | Second dose | `high` |
| `withdrawal_end` | Withdrawal period ends | `high` |
| `custom` | Other reminders | `normal` |

Rules:

- **Eight channels, not one.** One channel for everything means the shepherd who mutes tag-by spam loses colostrum alerts with it. That is the whole point of channels.
- **The names are nouns, never clinical claims.** "Colostrum", not "Colostrum window" — a channel name is user-facing copy and §12.2 applies to it.
- **Importance is an initial value only.** After creation the user owns it; `createNotificationChannel` can lower it but never raise it, and Android restores a deleted channel's settings if you recreate it with the same id. Never rely on importance for correctness, and never delete-and-recreate a channel to "fix" it.
- **No custom sound.** An unfamiliar sound at 3am is worse than the familiar one.
- **No badge count.** A badge implies unread state the app does not model.
- **No full-screen intents.** `USE_FULL_SCREEN_INTENT` was restricted on Android 14+ by the same policy pattern as `USE_EXACT_ALARM` — Play auto-grants it to calling and alarm apps only. Do not declare it. A heads-up notification on a high-importance channel is what the 3am user expects anyway.
- Channels are created (idempotently) by `installCopy()`, because their names are localised.

**Gate.** A test reads the committed `drift_schemas/drift_schema_v<N>.json`, extracts the `reminders.kind` CHECK's string set, and asserts it equals the channel-id list in `NotificationCopy`. The two cannot drift, and the failure message names both sides.

### 2.8 `POST_NOTIFICATIONS` — deferred, and never from a write path

Decision #65 defers the request to "the first time the user creates a reminder". Read literally, that is wrong here: reminder **rows** are created automatically inside the lambing and treatment transactions (decision #63), so the literal reading puts a system dialog on screen at 03:24 during the first lambing — exactly the mid-season nag spec §5 forbids.

> **The rule that ships (a narrowing of #65, never a widening; agreed with [`07-screens.md`](07-screens.md) §11.5): the notification permission is never requested from a write path.** It is requested from exactly two explicit user taps — "Turn on alerts" on the Reminders screen, and Settings ▸ Reminders. Until then, reminder rows are written and listed normally, `reconcile()` projects nothing, and the Reminders screen states that plainly.

Consequences worth spelling out:

- A shepherd who only ever taps "lambing → twin → save" never sees a system dialog from this app. Ever.
- There is **no state to remember**. Because nothing is ever prompted automatically, there is no "we already asked once" flag, no cooldown, and no new `app_settings` column. If you find yourself adding one, the prompt has escaped to an automatic path.
- The end-of-day export nudge is an **in-app banner**, not a notification (decision #72), precisely so that a shepherd who never creates a reminder still gets the one prompt the spec calls a safety feature.

### 2.9 Exact alarms — the store-rejection trap

Two Android permissions, and picking the wrong one gets the app removed from Google Play.

| | `SCHEDULE_EXACT_ALARM` | `USE_EXACT_ALARM` |
|---|---|---|
| Introduced | Android 12 (API 31) | Android 13 (API 33) |
| Granted how | **By the user**, in Settings ▸ Alarms & reminders | **Automatically** at install; cannot be revoked |
| Android 14+, new installs targeting API 33+ | **Denied by default** | n/a |
| Google Play policy | No restriction | **Restricted to alarm/timer and calendar apps** |

Play Console Help 9888170 permits `USE_EXACT_ALARM` only where "core, user facing functionality requires precisely-timed actions" — specifically "the app is an alarm or timer app" or "a calendar app that shows event notifications" — and states that apps outside those cases "will be disallowed from publishing on Google Play."

> **Does Shed Book qualify? No.** It is a record-keeping notebook that also sets reminders. It is not an alarm clock and it is not a calendar. Declaring `USE_EXACT_ALARM` is a policy violation and a rejected release. Do not let anyone argue the point on the grounds that the colostrum window is time-critical — that argument is exactly the one the policy anticipates and refuses.

We must ship `targetSdk 36` (Play requires Android 16 / API 36 for new apps and updates from 31 August 2026), so we are squarely inside the denied-by-default regime.

**The fallback, and how it stays honest.**

1. Declare `SCHEDULE_EXACT_ALARM`. It is user-granted, not policy-restricted.
2. **Call `NotificationScheduler.canBeExact()` once per reconcile** — it wraps the Android resolver's `canScheduleExactNotifications()` — and pick the mode from the answer, never from a cached flag. `ReminderReconciler._run()` reads it before the projection loop and passes it down as `project(…, exact: …)` (§2.4), so one capability check covers up to 200 projections and the answer cannot go stale mid-run. Calling an exact mode without the permission throws `ExactAlarmPermissionException` from the plugin's `checkCanScheduleExactAlarms`, which is called on the `exact`, `exactAllowWhileIdle` and `alarmClock` paths.

   | `canBeExact()` | Mode | AlarmManager | Fires in Doze |
   |---|---|---|---|
   | `true` | `AndroidScheduleMode.exactAllowWhileIdle` | `setExactAndAllowWhileIdle` | Yes |
   | `false` | `AndroidScheduleMode.inexactAllowWhileIdle` | `setAndAllowWhileIdle` | Yes |

   `AndroidScheduleMode.exact` is never used — it does not survive Doze, which is the state a phone in a coat pocket at 04:00 is in. `AndroidScheduleMode.alarmClock` is never used either: `setAlarmClock` is the most reliable Doze-buster, but it plants a system alarm icon in the status bar and reads to the user as *"your alarm clock is set"*, which is wrong for a withdrawal-period reminder.

   **Why the answer is not cached, stated so nobody "optimises" it.** The user can revoke Alarms & reminders in system Settings at any moment, including while the app is backgrounded. A flag read at launch and trusted at 03:00 produces an `ExactAlarmPermissionException` on the one path that has no user in front of it. Two extra platform-channel calls per reconcile is the price and it is not worth arguing about.

3. **Say so on screen.** On Android 12+ an inexact alarm never fires early and is delivered "within one hour of the trigger time" absent Doze or battery-saver. While exact alarms are denied, every reminder row carries an **"approximate" chip** — icon plus the word, never colour alone (#106) — and the Reminders screen's disclosure box gains a fourth line: *"Reminders may arrive up to an hour late. Turn on 'Alarms & reminders' for on-the-minute."* with a 72 pt action that calls `NotificationScheduler.requestExactAlarms()`. A shepherd who believes a colostrum reminder is exact when it is ±1 h is being misled by the app, which is §12.5's principle applied to delivery instead of to timestamps.
4. **The upgrade path needs no receiver.** Granting the permission sends the user to system Settings; returning to the app produces `AppLifecycleState.resumed`, which is already reconcile call site #2, which re-asks `canBeExact()` and re-projects everything as exact. Registering `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` buys nothing over that and costs a receiver.

**This requires one addition to [`07-screens.md`](07-screens.md) §11.2** — the fourth disclosure line and the per-row "approximate" chip — flagged here rather than assumed.

### 2.10 Reboot persistence

| Platform | Behaviour |
|---|---|
| **Android** | `AlarmManager` alarms are **destroyed on reboot**. The plugin persists the notification details and its `ScheduledNotificationBootReceiver` calls `rescheduleNotifications(context)` on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` / `QUICKBOOT_POWERON`. This requires `RECEIVE_BOOT_COMPLETED` **and** the two receiver declarations in our manifest (§8.3) — the plugin's own manifest declares neither. |
| **iOS** | Pending `UNNotificationRequest`s are held by the system and survive reboot with no work from us. |

Both are then re-validated by `reconcile()` at next launch, so a hostile OEM skin that never delivers `BOOT_COMPLETED` degrades to "reminders resume when the shepherd next opens the app" rather than "reminders are gone". That is also why the boot path is a backstop and not the mechanism: **Android's reboot replay re-uses the schedule mode that was persisted**, which may be stale if the exact-alarm permission changed while the phone was off.

### 2.11 Timezone and DST

`package:timezone` **0.11.1** exists in this app for one reason: `zonedSchedule` takes a `tz.TZDateTime`. It is confined to `NotificationScheduler` (R48, decision #48). Everything else uses `Instant` and its `.local` getter, which reads the **OS** zone rules — deliberately, because this app is bought once and may not be updated for three seasons, and the phone's own rules age better than a snapshot frozen at build time. Decision-record §4 records "bundled IANA snapshot goes stale" as an accepted consequence, bounded by exactly that confinement.

Import `package:timezone/data/latest_10y.dart`, not `latest`. Every instant this app converts is a *future* one, weeks away at most; ten years of rules is more than the app will ever consult, and note 06 measured the difference at roughly 85 KB against 361 KB (**not independently verified** — read the built artifact's size before quoting either figure anywhere user-facing).

**`tz.local` is set in exactly two places, both inside the gateway:** `initialize()` on the boot kick, and `refreshLocalZone()` at the head of every `reconcile()` (§2.3, §2.4). Nothing else in `lib/` calls `tz.setLocalLocation`, and the `layer.plugin_timezone` row makes that mechanical rather than a habit. Refreshing on every reconcile is what turns call site #2's "timezone change" from a claim into a behaviour: a shepherd who drives from Ireland to France gets re-projected reminders on resume, not on next launch.

**Two classes of reminder, and only one of them can go wrong.**

| Class | Kinds | How `due_at` is computed | DST exposure |
|---|---|---|---|
| **Offset from an event** | `colostrum`, `navel`, `turn_out`, `second_dose`, `withdrawal_end` | `dueAt = eventInstant.plus(Duration(minutes: rule.offsetMinutes))` | **None.** A duration is a duration. Correct by construction, and it survives the shepherd flying to another zone. |
| **Wall-clock** | `tag_by`, and `custom` when the user sets a time | `Instant.fromDateTime(DateTime(y, m, d, h, mi))` | Real. See below. |

**The rule for the ambiguous hour, which for UK/Ireland is `01:00–01:59` (owner ruling §7.0 #3).**

- **No wall-clock default is ever inside it.** `tag_by` defaults to **08:00 local**. Any future wall-clock kind picks a time outside `01:00–01:59` and outside `02:00–02:59`, so the same default is right if the app ever ships to continental Europe.
- **Spring forward (29 March 2026): 01:00–01:59 does not exist.** `DateTime(2026, 3, 29, 1, 30)` silently returns `02:30` — Dart violating safety rule 4 on our behalf. If the shepherd types a time in that hour, `checkLocalWallTimeExists` returns `WarningCode.timeDoesNotExistLocally` ([`05-domain-correctness.md`](05-domain-correctness.md) §7.5), the app **shows** the warning — *"The clock skipped 01:30 that night (clocks went forward). Saved as 02:30."* — and stores the resolved instant. It is never silently moved and never refused.
- **Autumn back (25 October 2026): 01:00–01:59 happens twice.** Dart picks one of the two candidate instants. **No warning is raised** (05's rule: the displayed time still matches what the shepherd typed, so nothing was silently corrected from their point of view). The notification therefore fires **once**, at whichever of the two 01:30s Dart chose. It can never fire twice, because `cancelAll()` + one row = exactly one request.
- **`matchDateTimeComponents` is banned outright.** A recurring notification's state lives in the OS rather than in SQLite, which contradicts "assume the phone dies", and it drifts across DST. Every reminder in Shed Book is a one-shot row; the projection re-creates it.

**The invariant that bounds every remaining timezone risk:**

```dart
// test/data/reminder_dst_test.dart — @Tags(['uk-zone']), run under TZ=Europe/London
// scheduleTimeFor is the top-level public function in notification_scheduler.dart
// (§2.3). It is public precisely so this line exists.
test('DST-8: the projected TZDateTime is the SAME absolute instant as due_at', () {
  final i = Instant.fromDateTime(DateTime.utc(2026, 3, 29, 1, 30));
  expect(scheduleTimeFor(i).millisecondsSinceEpoch, i.epochMillis);
});
```

That test is why the un-audited `flutter_timezone` dependency (§11) is a bounded risk rather than a correctness hole: the tz conversion is a *rendering* of an instant in a zone, never a shift of the instant, so a wrong `tz.local` cannot move when a reminder fires — **on Android, where the plugin hands an epoch to `AlarmManager`.** Whether iOS's `UNCalendarNotificationTrigger` construction inside `flutter_local_notifications` 22.2.0 preserves that property is **unverified** and is §11 item 2.

Three more tests belong beside it:

- **DST-6** — an offset reminder created at 20:00 on 26 March with a 7-day interval is due 168 h later, at 21:00 local on 2 April, not 20:00. (The civil-day form yields 167 h; see 05 §2.9's DST-4.)
- **DST-7** — a `tag_by` reminder set to 01:30 on 29 March 2026 produces exactly one `Warning` with `WarningCode.timeDoesNotExistLocally`, and projects exactly one request.
- **DST-9** — a `tag_by` reminder set to 01:30 on 25 October 2026 produces zero warnings and projects exactly one request.

CI runs the suite twice (decision #121): `TZ=Europe/London` for everything, and `TZ=Pacific/Chatham --exclude-tags uk-zone` as the hostile zone that catches any assumption of whole-hour offsets.

### 2.12 Handling a tap

**One destination: the Reminders screen.** A tap resolves the payload to a `ReminderId`, pushes `RouteNames.reminders` through `Routes.navigatorKey`, and then reconciles (call site #4 — completing a reminder frees a slot for the 57th). It does **not** read the database on the tap path to work out which animal to open: that is an async hop before the first paint, on the one path where the phone has been asleep, to save a tap the shepherd is about to make anyway.

| Case | Mechanism |
|---|---|
| App in the foreground or backgrounded but alive | `onDidReceiveNotificationResponse`, wired in `initialize()` |
| App launched *by* the tap (cold) | `getNotificationAppLaunchDetails()`, read **once** inside the post-frame boot kick and never before `runApp()` (decision #21). Push after the first frame. |
| Notification actions | **None in v1.** There are no action buttons, so there is no background isolate handler, no `@pragma('vm:entry-point')` top-level callback, and no second copy of the routing logic. If actions ship in v2, that handler runs in a fresh isolate with no `ProviderScope` and must write through its own database connection — which is a design conversation, not an edit. |

### 2.13 The honest disclosure

The OS list and the app list **deliberately disagree**. [`07-screens.md`](07-screens.md) §11.2 and §17.3 own the copy; this document owns the two facts that make it true:

1. `AppSetting.lastReconcileScheduled` is written by `reconcile()` itself, so `scheduled` is what was projected, not what was hoped for. (The row class is `AppSetting`; `AppSettings` is the drift **table** class and R29 bans it in this position. 07 §11.2 spells the column `app_settings.last_reconcile_scheduled`, which is the same thing seen from SQL.)
2. `ReminderBudget.forPlatform()` is the *same* constant that slices the projection and feeds the copy, so **the number 56 never appears in a string**. A literal in copy is a number that will one day disagree with the behaviour.

Never write "some reminders may not fire." They will fire; they are simply not on the lock screen yet, and they enter the window as nearer ones complete.

### 2.14 Anti-patterns

| Anti-pattern | What it costs | Gate |
|---|---|---|
| `zonedSchedule()` on a write path | A channel round-trip inside a drift transaction; a budget nobody checked | `notify.zoned_schedule` (`lib/`, exempt `notification_scheduler.dart`) |
| `schedule(` on a reminder object | That spelling *is* the rejected architecture | `db.reminder_schedule` (R51) |
| `USE_EXACT_ALARM` in the manifest | Play removal | G1's exact-permission assertion + `notify.use_exact_alarm` |
| `AndroidScheduleMode.alarmClock` | A system alarm icon for a withdrawal reminder | `notify.alarm_clock` |
| `matchDateTimeComponents` | Recurrence state in the OS; DST drift | `notify.recurring` |
| An `os_notification_id` column | A second source of truth that goes stale every reconcile | Schema review (03 §5.10 says so) |
| An id from `uid.hashCode` | int32 overflow and silent collisions | Review; `reminders.id` is the only sanctioned source |
| A prompt from `initialize()` | Spec §5's permission nag at first launch | Widget test: launch, assert zero permission calls |
| Projecting `due_at <= now` | A burst of pings on every Android resume | The query's `> :after`, plus a test with three overdue rows |
| Caching `canBeExact()` in a field or an `app_settings` column | An `ExactAlarmPermissionException` after the user revokes it in system Settings | Re-asked once per reconcile; the fake toggles it mid-test |
| `project()` resolving the schedule mode itself | One capability check per reminder — up to 200 round-trips for one answer | `project()` takes `exact` as a required parameter (§2.3) |

---

## 3. Photo capture

### 3.1 `CameraService`

R47 splits capture from storage: **`CameraService` owns `image_picker`; `MediaStore` owns the media root, `newRelativePath`, `resolve`, `writeAtomically` and the `flutter_image_compress` downscale.** 04 §4.4 currently prints `ImagePicker()` as "a method ON MediaStore"; that is superseded — the code moves, the compression stays.

**Two other things 04 §4.4 says are narrowed here, not contradicted.** It calls `retrieveLostData()` "called on resume"; this document calls it at the top of `pick()` instead, because a resume handler that recovers a photo has nowhere to put it — the attach slot that asked for it may no longer be on screen. Calling it inside `pick()` means the recovered file arrives at the one place that knows which record it belongs to. And `BackgroundIsolateBinaryMessenger.ensureInitialized` stays 04's business, because the compressor is `MediaStore`'s and `CameraService` never leaves the root isolate.

```dart
// lib/data/camera_service.dart

/// OURS, not the plugin's `ImageSource` — no plugin type crosses the
/// boundary (§1.1).
enum CaptureSource { camera, library }

final class CameraService {
  CameraService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  /// Returns an absolute path in the OS's own temp area, plus whether it was
  /// recovered from a killed capture. The caller compresses and rehomes it
  /// through MediaStore; nothing else in lib/ constructs a media File.
  Future<({String path, bool recovered})?> pick(CaptureSource source) async {
    // Android can kill us while the system camera activity is foreground.
    // Ask for the lost picture FIRST: the shepherd already took it, and
    // making them take it twice at 3am is the failure this call exists for.
    final lost = await _picker.retrieveLostData();
    if (!lost.isEmpty && lost.file != null) {
      return (path: lost.file!.path, recovered: true);
    }
    // requestFullMetadata: false — the plugin documents that the microphone
    // permission is never requested when this is ALWAYS false. It does not
    // remove the Info.plist keys, which App Store policy still requires (§8.4).
    final picked = await _picker.pickImage(
      source: switch (source) {
        CaptureSource.camera => ImageSource.camera,
        CaptureSource.library => ImageSource.gallery,
      },
      requestFullMetadata: false,
    );
    return picked == null ? null : (path: picked.path, recovered: false);
  }
}
```

`retrieveLostData()` is documented as a no-op on iOS. When `recovered` is true the attach slot renders the image with an 18 pt line — *"Recovered from your last photo"* — and the normal 60 pt Remove control. Not a dialog, not a modal, not a question: the shepherd can see what they are attaching and can undo it in one tap. Attaching a recovered photo without saying so would attribute one record's photo to another, which is a §12.4 failure in image form.

### 3.2 Zero merged permissions — the reason `image_picker` beat `camera`

`image_picker_android`'s manifest declares **no `uses-permission` at all**: one `FileProvider` (`${applicationId}.flutter.image_provider`) and one *disabled* `com.google.android.gms.metadata.ModuleDependencies` service that signals Play Services to install the photo-picker backport. On Android 13+ the plugin uses the **system photo picker**, which grants per-URI access and needs neither `READ_MEDIA_IMAGES` nor `READ_MEDIA_VISUAL_USER_SELECTED`. The app never asks for gallery access.

> The `ModuleDependencies` service means Play Services may fetch the photo-picker backport on older devices. That is a Play Services action in a Play Services process. It belongs under the decision record's tier-3 honesty (§3.1) and it does not put `INTERNET` in our manifest.

On iOS, `PHPickerViewController` needs no library authorisation at all since iOS 14 — "Limited Photos Access" never applies to us and there is no "manage selection" flow to build. The **camera** path does produce one real `NSCameraUsageDescription` prompt, at the moment of first use, which the 3am rules tolerate.

`camera` 0.12.0+2 was rejected: it merges `CAMERA` + `RECORD_AUDIO`, hands us a preview surface we would have to build a shutter around, and makes us own lifecycle, orientation and torch. The system camera already has a torch button and a shepherd already knows how to work it one-handed with a glove on.

### 3.3 Compression, EXIF and the storage budget

Decision #40: **longest edge 2048 px, JPEG quality 80, `keepExif: false`.** The compression call is `MediaStore`'s and is printed in 04 §4.4; two rules belong here.

**EXIF.** `flutter_image_compress`'s `keepExif` defaults to `false`, which strips metadata and normalises the `Orientation` tag so the image does not double-rotate. Keep the default, and set it explicitly anyway so the intent is visible at the call site. An untouched iPhone photo carries GPS coordinates; spec §4.5 calls losses and treatment records commercially sensitive, and a CSV export carrying a photo with the farm's exact coordinates is a leak the shepherd never consented to.

```dart
('media.keep_exif', 'keepExif: true', 'lib/', 're-attaches GPS — #77, spec §4.5'),
```

**Budget.** The per-file ceiling is the assertion 04 already specifies: a test opens the output and fails if `max(width, height) > 2048` or `bytes > 900 KB`.

| | Per photo | 400 photos (ewes) | 1200 photos (ewes + lambs) |
|---|---|---|---|
| Untouched 12 MP HEIC/JPEG | 2.0–3.5 MB | ~1.0 GB | ~3.0 GB |
| **2048 px / q80 — the ceiling we assert** | ≤ 900 KB | ≤ 360 MB | ≤ 1.08 GB |
| 1600 px / q80 — note 06's *measured* figures | 250–400 KB | ~130 MB | ~390 MB |

The middle row is a ceiling, not a measurement: **nobody has measured typical bytes at 2048 / q80**, and note 06's measured numbers are at a different resolution. Measure it on one portrait and one landscape frame from a real phone and record the figure in `docs/perf/measurements.md`. Settings ▸ Diagnostics shows the media folder size from the stored `byte_size` column, and offers "Delete photos from season 2025" — no filesystem walk.

04 §4.4 carries a live verification item this document does not close: `minWidth`/`minHeight` are documented as **minimums**, so passing `2048/2048` may cap the *shorter* edge and leave the longer one above 2048. Measure before shipping; derive the pair from the source aspect ratio if the parameters behave as floors.

**Never put photos in SQLite.** `VACUUM INTO` copies the whole database, and Android Auto Backup caps at 25 MB per app — inline photos would silently kill the backup of the *records* too (04 §4.1).

---

## 4. Audio recording — the voice note

Voice **tag entry** is cut (§10). The voice **note** ships, and it is pure local recording: no recognizer, no other process, nothing to constrain.

```dart
// lib/data/voice_recorder.dart
// The class is `AudioRecorder`. `Record` was renamed in 5.0.0.
final class VoiceRecorder {
  VoiceRecorder([AudioRecorder? recorder]) : _recorder = recorder ?? AudioRecorder();
  final AudioRecorder _recorder;
  Timer? _cap;

  /// Prompts for RECORD_AUDIO / NSMicrophoneUsageDescription natively.
  /// Called on the FIRST tap of the record button and never earlier.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// `onCapReached` fires if the cap stops the recording before the shepherd
  /// does; the write controller uses it to update the row exactly as it would
  /// on a manual stop, so there is no second code path for a capped note.
  Future<void> start(
    String absolutePath, {
    required void Function(String? path) onCapReached,
  }) async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,   // NEVER opus — see below
        bitRate: 32000,                // mono speech
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: absolutePath,
    );
    // The cap is enforced HERE, not by the countdown ring, because a UI
    // timer can be starved and a gateway cannot. One-shot Timer: the policy
    // rule bans `Timer.periodic(`, not `Timer(`.
    _cap = Timer(const Duration(seconds: kVoiceNoteMaxSeconds),
        () async => onCapReached(await stop()));
  }

  Future<String?> stop() async {
    _cap?.cancel();
    _cap = null;
    return _recorder.stop();
  }

  Future<void> cancel() async { _cap?.cancel(); _cap = null; await _recorder.cancel(); }
  Future<bool> isRecording() => _recorder.isRecording();

  /// dBFS, not the plugin's `Amplitude` — no plugin type crosses the
  /// boundary (§1.1). The level meter is the only consumer.
  Stream<double> levelDbfs(Duration interval) =>
      _recorder.onAmplitudeChanged(interval).map((a) => a.current);
}
```

**Codec and container: AAC-LC in `.m4a`, mono. Never Opus.** `record` containers Opus as **OGG on Android** and **CAF on iOS**. Those files are not interchangeable, which breaks a backup made on an Android phone and restored onto an iPhone — and cross-device restore is the entire point of spec §7.9. AAC-LC produces MPEG-4 `.m4a` on both platforms, playable by both, and is what the OS voice-memo apps use.

```dart
('media.opus', 'AudioEncoder.opus', 'lib/', 'container differs per platform — #40, #76'),
```

**The cap.** `kVoiceNoteMaxSeconds` is a single constant in `lib/data/media_limits.dart`. **Ship 60** until the owner answers §7.1 #18 (60 s or 120 s): it is the lower storage figure and the recoverable mistake — raising a cap orphans nothing, lowering one makes existing recordings unreproducible. At 32 kbps mono the arithmetic is 4 KB/s ⇒ **~240 KB/minute**; 400 notes averaging 30 s is ~48 MB, which sits comfortably under the photo budget.

**File naming.** `MediaStore.newRelativePath('m4a')` ⇒ `YYYY/MM/<uuidv7>.m4a`, and only ever that. Never the tag number (tags get corrected and a rename orphans the row), never a sequence number (collisions after a restore). The row stores the relative path; the absolute path exists only for the duration of the call.

**Write ordering — the audio refinement of 04 §4.5.** The event row still commits first and the media attaches second. Within the audio path, the `media_assets` row is inserted **when recording starts**, not when it stops, because the file exists from that moment: a phone death mid-note must leave a linked, truncated file rather than an orphan the sweeper deletes. `byte_size` is written on `stop()`.

Be honest about what a truncated `.m4a` is: MPEG-4 finalisation writes the `moov` atom at the end, so a note interrupted by a process kill **may not be playable at all**. The app must never claim otherwise — a media row with `byte_size` still `0` renders as *"Recording interrupted"* and offers Delete, not Play.

**3am rules.** Press-and-hold is banned (#101, spec §5): a 60×60 pt tap-to-start / tap-to-stop toggle with an unmissable state change, plus a level meter fed from `VoiceRecorder.levelDbfs` — the shepherd needs to see at a glance that it is actually recording, because they cannot read a small icon through a freezer bag.

**Permission.** `AudioRecorder.hasPermission()` prompts natively. `record_android`'s manifest merges exactly one permission, `RECORD_AUDIO` — no foreground service, no `MODIFY_AUDIO_SETTINGS`, no provider, no receiver. iOS needs `NSMicrophoneUsageDescription` and nothing else.

---

## 5. The share sheet

**The share sheet is the export mechanism** (spec §7.9), which makes it the highest-stakes non-database code path in the app.

```dart
// lib/data/share_service.dart
import 'dart:ui' show Rect;   // NOT package:flutter/material.dart — layer rule 4

final class ShareService {
  /// `origin` is REQUIRED and named — not optional with a default. The
  /// share_plus README states that omitting sharePositionOrigin on iPad
  /// "may cause crashes or unresponsive UI". A required parameter is a
  /// better gate than a lint, because it fails at compile time.
  Future<ShareOutcome> shareFiles({
    required List<String> paths,
    required List<String> fileNames,
    required Rect origin,          // dart:ui — no material import needed
    String? subject,
  }) async {
    assert(paths.length == fileNames.length);
    final result = await SharePlus.instance.share(ShareParams(
      files: [for (final path in paths) XFile(path)],
      fileNameOverrides: fileNames,
      subject: subject,
      sharePositionOrigin: origin,
    ));
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.completed,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}

enum ShareOutcome { completed, dismissed, unknown }
```

Rules:

- **The current API is `SharePlus.instance.share(ShareParams(...))`.** The static `Share.share*` methods are deprecated. `('share.static_api', 'Share.share', 'lib/', …)`.
- **Always pass a file path; never `XFile.fromData`.** `fromData` writes a temp copy that you then have to find and delete yourself. `('share.from_data', 'XFile.fromData', 'lib/', …)`.
- **The caller computes `origin`** from the button that was tapped: `final box = context.findRenderObject()! as RenderBox; box.localToGlobal(Offset.zero) & box.size;`. Passing `Rect.zero` is not a workaround, it is the bug.
- **`share_plus` merges no permissions**: a `ShareFileProvider` and a `SharePlusPendingIntent` receiver, no `uses-permission`, no `queries`.
- Exports are written to `getTemporaryDirectory()` and handed straight to the sheet (04 §4.2) — that directory is excluded from iCloud and from Android Auto Backup, so stale exports never inflate anyone's backup.

**What the result means, and what we do with it.** `ShareResultStatus.dismissed` is not failure — the user may have changed their mind, or the platform may simply not report. So:

> `app_settings.last_exported_at` is written on `ShareOutcome.completed` **and** on `ShareOutcome.unknown`, and **not** on `dismissed`. Recording an export we cannot confirm is the safer error: the cost is one un-nagged evening, whereas refusing to record a real export nags a shepherd who did exactly what the app asked. Never write it before the sheet opens.

This is the rule [`07-screens.md`](07-screens.md) §16.2's banner condition depends on and `09-export-formats.md` implements; flagged here because no document currently states who writes that column.

`open_filex` was rejected: the share sheet already offers "Open in…".

---

## 6. File import — choosing a backup file for a restore

`file_selector` **1.1.0** (flutter.dev), reached from exactly one file:

```dart
// lib/features/settings/restore_flow.dart — the one file_selector call site.
const _backupType = XTypeGroup(
  label: 'Shed Book backup',
  extensions: ['json'],
  // Android MIME filtering is unreliable; some providers report a file as
  // octet-stream. Accept too much and reject clearly (§7.2 step 2 of doc 04)
  // rather than greying out the user's own backup.
  mimeTypes: ['application/json', 'application/octet-stream'],
  uniformTypeIdentifiers: ['public.json'],
);

Future<XFile?> pickBackupFile() => openFile(acceptedTypeGroups: [_backupType]);
```

- **No storage permission on either platform.** Android's `ACTION_OPEN_DOCUMENT` returns a `content://` URI with a per-file grant; iOS uses `UIDocumentPickerViewController`. Neither needs a runtime permission and neither appears in the manifest.
- **The picked URI can be a one-shot grant on Android**, so `RestoreService` copies it to `<temp>/restore/incoming.json` immediately (04 §7.2 step 1) before doing anything else.
- **We validate the magic bytes ourselves** (04 §7.2 step 2): `{` ⇒ JSON, `PK\x03\x04` ⇒ a ZIP and refused by name, `SQLite format 3\0` ⇒ a diagnostics copy and refused by name, anything else refused. That check is what makes accepting `application/octet-stream` safe.
- **`file_picker` was rejected**, and not only on weight (`dbus`, `win32`, `ffi`, a history of merging storage permissions, and a place on Apple's third-party-SDK privacy-manifest list). Its headline feature is cloud picking, and a restore picker that invites the shepherd into Google Drive actively undercuts the thing the product is sold on.
- `.zip` is not accepted in v1, because media is not in the v1 backup (decision #85). Adding it later is one line here and a magic-byte branch there.

---

## 7. Wakelock

Screen sleep mid-lambing is not a nuisance: the phone is in a freezer bag on a gate, the shepherd has both hands inside a ewe, and coming back means a wet-glove Face ID failure, then a passcode with cold fingers, then finding the app again. That single interaction blows the entire 15-second budget, and it is exactly the moment the entry gets deferred to 7am. The cost on the other side is battery, and a dead phone at 05:00 on night eleven is worse than a screen timeout. Decision #79 splits the difference: **default off, session-scoped, 30-minute expiry, released on any non-resumed state.**

```dart
// lib/data/wakelock_controller.dart — R9 fixes the class name and both verbs.
import 'dart:async' show Timer, unawaited;

final class WakelockController {
  static const sessionExpiry = Duration(minutes: 30);

  bool _held = false;
  Timer? _expiry;
  bool get isHeld => _held;

  /// Called ONLY by the route observer (§7.2), and only when
  /// app_settings.wakelock_enabled is true. Idempotent; re-arms the expiry.
  Future<void> acquire() async {
    _expiry?.cancel();
    _expiry = Timer(sessionExpiry, () { unawaited(release()); });
    if (_held) return;
    _held = true;
    await WakelockPlus.enable();
  }

  /// Unconditional and idempotent: it ends the whole session. Called from the
  /// route observer, from EVERY non-resumed lifecycle state (02 §9.1), from
  /// the expiry timer, and on app dispose.
  Future<void> release() async {
    _expiry?.cancel();
    _expiry = null;
    if (!_held) return;
    _held = false;
    await WakelockPlus.disable();
  }
}
```

### 7.1 When it may be held at all

Three conditions, all of them necessary:

1. `app_settings.wakelock_enabled` is **true**. It ships **false** and the Settings row (07 §14.3 §7) says what it costs.
2. The **top route** is `RouteNames.quickEntry`, `RouteNames.lambingEntry` or `RouteNames.penBoard`. Never Season Summary, Export, Settings, Treatments, Flock or note search — those are daylight screens read with two hands.
3. The app is `resumed`.

It is never held app-wide, never held across a background, and never held for more than 30 minutes without the shepherd doing something. When the expiry fires the screen simply behaves normally again; walking to another permitted route and back re-arms it. Say that in the Settings copy rather than letting the shepherd discover it.

### 7.2 Where `acquire()` is called from

Not from a screen's `initState`/`dispose`. Two permitted routes can be stacked (Quick Entry → Lambing Entry), and per-screen calls make popping the top one release a lock the screen underneath still wants — or make the reverse leak it. **One decider:** a small `NavigatorObserver` inside `lib/app.dart` (which already hosts the `WidgetsBindingObserver` and passes `navigatorObservers:` to `MaterialApp`) reads `RouteSettings.name` on every push, pop and replace, and calls `acquire()` or `release()` accordingly. `RouteSettings(name:)` already exists for the diagnostics log and `ModalRoute.withName` (02 §8.1); this is its third and last use.

The lifecycle release stays exactly where 02 §9.1 puts it — `if (state != AppLifecycleState.resumed) ref.read(wakelockProvider).release();` — because a phone that goes `inactive` behind a banner and never reaches `hidden` must not hold the screen on for the rest of the night.

### 7.3 Gates

- `layer.plugin_wakelock_plus` — `package:wakelock_plus/` outside `lib/data/wakelock_controller.dart` fails the build.
- A widget test drives `resumed → inactive` and asserts the fake's `disable()` was called and `isHeld` is false.
- A widget test pumps `Duration(minutes: 31)` (the widget-test binding's clock advances, decision #113) on a permitted route and asserts the lock expired.
- A widget test navigates Quick Entry → Season Summary and asserts release; and Quick Entry → Lambing Entry and asserts the lock is still held.
- A crash-restart with the lock leaked drains the phone silently overnight — which is why `release()` is unconditional rather than reference-counted.

---

## 8. The permission policy

### 8.1 No permission package

`permission_handler` is the reflex answer and it is not used (decision #78). Its Android manifest merges nothing, which is fine, but on iOS with CocoaPods it needs a `post_install` macro dance (`PERMISSION_CAMERA=1`, `PERMISSION_MICROPHONE=0`, …) to strip the permission code you do not use — and getting that wrong is an App Store rejection for undeclared API usage. Every permission this app needs has a first-party request API on the plugin that needs it.

### 8.2 Who asks, and exactly when

**Every row names the gateway verb first, because that is the only spelling `lib/features/` is allowed to see.** The plugin method in brackets is what the gateway calls on the other side of the boundary (§1.1).

| Permission | The call | When | Never |
|---|---|---|---|
| Notifications (`POST_NOTIFICATIONS` / `UNUserNotificationCenter`) | `NotificationScheduler.requestAlerts()` (→ `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()` · the Darwin resolver's `requestPermissions(alert:badge:sound:)`) | An explicit tap on "Turn on alerts" (Reminders) or Settings ▸ Reminders | From `initialize()`, from a write path, at first launch, mid-lambing |
| `SCHEDULE_EXACT_ALARM` | `NotificationScheduler.canBeExact()` → `requestExactAlarms()` (→ `canScheduleExactNotifications()` → `requestExactAlarmsPermission()`) | The same flow, immediately after alerts are granted | On its own, automatically, or from a reconcile — `reconcile()` **reads** `canBeExact()` and never requests |
| Camera | `CameraService.pick(CaptureSource.camera)` — `image_picker` prompts natively | The first tap of "Add a photo" → camera | Before a photo is asked for |
| Microphone | `VoiceRecorder.hasPermission()` (→ `AudioRecorder.hasPermission()`) | The first tap of the record button | At launch |
| Photo library | **none, ever** | — | — |
| Billing | none — Play/StoreKit IPC | Explicit Unlock / Restore taps ([`11-monetization-and-store.md`](11-monetization-and-store.md)) | The launch path |

There is no location, no contacts, no calendar, no Bluetooth, no `FOREGROUND_SERVICE`, no `USE_FULL_SCREEN_INTENT`. **A shepherd who only records lambings never sees a system dialog from this app** — that is spec §5's "zero interruptions" implemented at the plugin layer instead of promised in a design doc.

### 8.3 Android — the final permission set

Reproduced from decision-record §3.3, which is the authority. Gate **G1** (`bundletool dump manifest` on the shipped release `.aab`) asserts this exact set on every push; it is not a review item.

```
android.permission.POST_NOTIFICATIONS      <- flutter_local_notifications (merged)
android.permission.VIBRATE                 <- flutter_local_notifications (merged)
android.permission.RECEIVE_BOOT_COMPLETED  <- we add (reschedule after reboot, §2.10)
android.permission.SCHEDULE_EXACT_ALARM    <- we add (user-granted; NEVER USE_EXACT_ALARM, §2.9)
android.permission.RECORD_AUDIO            <- record (merged)
android.permission.WAKE_LOCK               <- wakelock_plus (merged)
com.android.vending.BILLING                <- Play Billing 8.0.0 AAR (merged, via in_app_purchase)
android.permission.INTERNET                <- ABSENT. Explicitly removed at merge time.
android.permission.ACCESS_NETWORK_STATE    <- removal PENDING G0. Do not commit the removal on faith.
```

`com.android.vending.BILLING` is on this list because the offline gate and the monetization decision were originally designed in ignorance of each other: a grep of the platform, architecture, migration and performance notes for `in_app_purchase` / `BILLING` returned **zero hits**. The Play Billing AAR is a Play-Services-adjacent artifact and its transitive Gradle graph must be re-reviewed on **every** Billing Library bump.

> **G0 is a prerequisite, not a formality.** Before any `tools:node="remove"` line is committed: run `flutter build appbundle --release`, read `build/app/outputs/logs/manifest-merger-release-report.txt`, and record the actual permission set Play Billing 8.0.0 contributes. Removing `INTERNET` is safe and proven. **Removing `ACCESS_NETWORK_STATE` is not yet proven** — three research notes hard-code the removal, and the only billing AAR manifest anyone could fetch was version 2.0.3, six majors behind. If billing 8.0.0 declares it and the merger strips it, the failure surfaces as a purchase flow that misbehaves on a flaky connection, in production, on someone else's phone. Until G0 has been run, the offline gate in CI is **unwritten**, not merely unimplemented (decision-record §1 #5 — the pre-commit decision, not §2's row 5).

**What we add to `android/app/src/main/AndroidManifest.xml`** — the plugin declares neither receiver, deliberately, since v16:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<!-- NOT USE_EXACT_ALARM. Play policy restricts it to alarm/timer and calendar
     apps; Shed Book is neither. See §2.9. -->

<uses-permission android:name="android.permission.INTERNET" tools:node="remove" />

<application ...>
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
      <action android:name="android.intent.action.BOOT_COMPLETED"/>
      <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
      <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
      <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
  </receiver>
</application>
```

**Gradle floors.** [`13-build-ci-release.md`](13-build-ci-release.md) §3.1 owns the build configuration; these are the values this document's plugin set forces, and 13 is where they are set:

| Setting | Value | Source | Status |
|---|---|---|---|
| `targetSdk` | **36** | Play's requirement for new apps and updates from 31 August 2026 (extensions to 1 November 2026) | Settled |
| `compileSdk` | **36** | Follows `targetSdk` | Settled |
| `coreLibraryDesugaringEnabled` + `com.android.tools:desugar_jdk_libs` | **2.1.4** | `flutter_local_notifications` **22.2.0**'s README minimum | Settled |
| AGP | **≥ 8.12.1** | `share_plus`'s README floor, above `flutter_local_notifications`' 8.11.1 | **Unverified** — both are README numbers, and a README changes a floor without a changelog entry. Read them off the installed 13.3.0 / 22.2.0 before the first release build |
| `minSdk` | **not asserted here** | — | 13 §3.1 leaves it at `flutter.minSdkVersion` unless a merged manifest raises it, and requires the effective value to be **read out of the merged manifest at G0 and recorded**. Do not set it from memory or from a plugin changelog |

Java 17 is the toolchain AGP 8.x requires; it is a consequence of the AGP row, not an independent decision.

### 8.4 iOS — the final key set

| Key | Value / purpose | Required by |
|---|---|---|
| `NSCameraUsageDescription` | "Shed Book uses the camera so you can attach a photo to a lambing record." | `image_picker`, camera path |
| `NSPhotoLibraryUsageDescription` | "Shed Book lets you attach a photo you have already taken to a lambing record." | `image_picker`, App Store policy (the picker itself needs no authorisation) |
| `NSMicrophoneUsageDescription` | "Shed Book records voice notes you attach to a lambing record." | `record` |
| `UIUserInterfaceStyle` = `Dark` | No light appearance ([`06-design-system.md`](06-design-system.md) §9.2) | — |
| `PrivacyInfo.xcprivacy` | `C617.1` (file timestamp) + `CA92.1` (user defaults); `E174.1` only if free disk space is actually queried | Decision #93 · owned by 11 |
| **No `NSAppTransportSecurity` key** | Its absence is part of gate **G5** | — |

There is no notification entitlement, no background mode, no `UIBackgroundModes`, and no push capability. `AppDelegate` sets `UNUserNotificationCenter.current().delegate = self` and nothing more.

> **`UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` are NOT set in v1.** Note 06 §4.2 recommends both so a shepherd can pull the media folder off over a cable. That recommendation assumed media lived in `Documents/`. Decision #27 and 04 §4.2 put the database **and** the media folder in **Application Support**, precisely so that a user tidying up in Files cannot delete `shed_book.sqlite`. With nothing of ours in `Documents/`, the two keys expose an empty folder and buy nothing. Superseded, recorded, not re-opened.

Every plugin below is on Apple's third-party-SDK list and must ship a current privacy manifest and signature — which is a reason never to pin an old version: `flutter_local_notifications`, `share_plus`, `path_provider`, `image_picker_ios`. The discontinued `wakelock` (not `wakelock_plus`) is also on that list, which is a second reason it is banned.

---

## 9. What CI proves, in this document's area

| Gate | Proves | Blocking |
|---|---|---|
| **G1** `bundletool dump manifest` on the release `.aab` asserts §8.3's exact set | No plugin silently merged a permission; `USE_EXACT_ALARM` cannot reach a release | Yes, every push |
| **G2** direct-dependency allowlist over `pubspec.lock`, `dependencies` and `dev_dependencies` scanned separately | `google_mlkit_*`, `speech_to_text`, `camera`, `file_picker`, `permission_handler`, `printing` cannot enter the graph unreviewed | Yes, every push |
| **G3** import scan of `lib/` | Our own source cannot reach a network API | Yes, every push |
| **G4** `manifest-merger-release-report.txt` archived | Diagnostic only — names which library contributed which permission | No |
| **G5** iOS: no `NSAppTransportSecurity`, App Privacy "Data Not Collected", one manual App Privacy Report / `nettop` check per release | There is no iOS permission to remove, so enforcement is construction plus observation. **Say so honestly; do not imply parity with Android.** | Manual, per release |
| `layer.plugin_*` (this document, §1.2) | Each plugin has exactly one import site, so its fake tests the real path | Yes, every push |
| Channel-id set vs the committed schema JSON (§2.7) | R49's "one set of strings" cannot drift | Yes, every push |

**A gate that must not be written:** any "`http` must not appear in `pubspec.lock`" rule. `http 1.6.0` sits on four regular edges — `flutter_local_notifications → timezone → http`, `wakelock_plus → package_info_plus → http`, `file_selector → file_selector_platform_interface → http` and `image_picker → image_picker_platform_interface → http` — all of which are load-bearing here. Runtime exposure on Android and iOS is plausibly nil (`timezone`'s use is in `browser.dart`; `package_info_plus`'s is on web) and a built APK shows no `INTERNET` permission and no surviving network symbols after AOT, but the *dependency graph* claim is false and a gate built on it is unsatisfiable on day one. Notes 06 and 09 both assert "no network dependency" for these packages; that phrasing is deleted, not softened. The gates are G1 + G2 + G3.

New `_bannedText` rows this document contributes, in [`01-architecture.md`](01-architecture.md) §3.2's tuple shape:

```dart
('media.opus',           'AudioEncoder.opus',              'lib/', 'container differs per platform — #40, #76'),
('media.keep_exif',      'keepExif: true',                 'lib/', 're-attaches GPS — #77, spec §4.5'),
('notify.use_exact_alarm','USE_EXACT_ALARM',               'lib/', 'Play policy: alarm/calendar apps only — #65'),
('notify.alarm_clock',   'AndroidScheduleMode.alarmClock', 'lib/', 'plants a system alarm icon — #65'),
('notify.recurring',     'matchDateTimeComponents',        'lib/', 'recurrence state in the OS; DST drift — #63'),
('notify.zoned_schedule','zonedSchedule(',                 'lib/', 'only NotificationScheduler projects — #63'),
('share.static_api',     'Share.share',                    'lib/', 'deprecated static API — #80'),
('share.from_data',      'XFile.fromData',                 'lib/', 'writes a temp copy nobody cleans up — #80'),
```

Two things about that table, both of which a reader would otherwise get wrong.

**`notify.use_exact_alarm` cannot see `AndroidManifest.xml`, and is not pretending to.** 01 §3.2's driver walks `lib/` and `test/` and reads `.dart` files only; `android/` is not a scanned root. This row catches the string in Dart — a copied snippet, a diagnostics line, a comment that turns into an edit — and nothing more. **G1 on the merged manifest of the shipped `.aab` is the gate that actually keeps `USE_EXACT_ALARM` out of a release**, and §2.14 lists it first for that reason. Do not widen `check_policy.dart`'s roots to `android/` to close the gap: G1 reads the *merged* manifest, which is the only artefact that tells the truth about what a plugin contributed.

**`notify` and `share` are new rule-id namespaces.** `CONVENTIONS.md` §4.7 lists seventeen and neither is among them (`media` is not listed either, yet §4.7's own rename table produces `media.opus`, so the list is already the stale half of that section). Adding two namespaces is a `CONVENTIONS.md` edit, flagged in §11 — not something this document may do quietly by using them.

`notify.zoned_schedule` needs one `[exempt]` line — `lib/data/notification_scheduler.dart :: notify.zoned_schedule` — which takes `tool/policy_allowlist.txt`'s `[exempt]` section from R56's four lines to five. That is a deliberate, reviewable fifth, and it is the only one this document adds.

---

## 10. Tag OCR and voice tag entry are v2 — the record, not an apology

Spec §7.1 names both. The owner cut both from v1 (decision-record §7.0 #5+6, decisions #75 and #76). This section exists so that a future contributor who reads §7.1 and reaches for a package understands what it costs before they do, and so the decision is not re-litigated by accident.

### 10.1 Tag OCR — cut, both platforms

| Route | Why it lost |
|---|---|
| `google_mlkit_text_recognition` | The "bundled" artifact still transitively depends on `play-services-base` and `play-services-basement`, which contribute `INTERNET` and `ACCESS_NETWORK_STATE`. It would **fail our own G1** on the first release build. It adds ~38 MB per script on iOS against an AAB download target under 20 MB. And ML Kit sends usage metrics to Google by Google's own terms — telemetry the shepherd did not consent to, in an app whose entire pitch is that there is none. |
| Apple Vision via a platform channel, iOS only | Technically excellent: free, on-device, no download, no metrics. It loses because it ships a **platform-asymmetric feature** — present on iPhone, absent on Android — into a spec that describes one product, maintained by one developer, sold once. |
| `flutter_tesseract_ocr` | ~12 MB of traineddata and poor accuracy on curved, dirty, retro-reflective ear tags. **A wrong tag is worse than no tag**: it silently attributes a lambing to the wrong ewe, which is a §12.4 failure the app cannot detect. |

Spec §7.1 marks OCR *"Optional… always a shortcut, never the only route"*, so cutting it costs nothing contractual.

### 10.2 Voice tag entry — cut from v1; the voice *note* ships

The defence that makes every other offline claim airtight is useless here. **Recognition runs in another process** — Google's or Apple's — whose network access our manifest cannot constrain. Removing `INTERNET` from *our* manifest does not remove it from theirs.

Worse, `speech_to_text` 7.4.0's `SpeechListenOptions.onDevice` **defaults to false and silently falls back to network recognition**, and no API reports whether on-device recognition is actually available. So the app could not even tell the user which mode it was in. Its README's manifest block also adds `INTERNET`, which is a second, cruder way to fail G1.

iOS 26's `SpeechAnalyzer` / `SpeechTranscriber` is genuinely the right API — fully on-device, no Siri or dictation prerequisite, explicit model management through `AssetInventory` — but it is iOS-26-only, bespoke Swift, and has no Android peer. Same asymmetry problem as Vision.

**What ships instead:** the 60×60 pt `ShedKeypad` plus `rankTagMatches` (`lib/domain/tag_match.dart`) as the one tag-entry route, and the voice **note** (§4), which is pure local recording with no recognizer anywhere near it.

### 10.3 The bar for v2

All three, or neither ships:

1. An API on **both** platforms that reports on-device availability *before* listening, so the app can refuse rather than guess.
2. No Play Services in the transitive Gradle graph, verified by reading the POM rather than trusting a "bundled" artifact name.
3. A size cost that fits the budget in decision #127 with the numbers measured, not estimated.

Until then, `google_mlkit_*` and `speech_to_text` fail **G2** on the day they are added, which is the point: the gate is the memory, not this paragraph.

---

## 11. Open items and unverified facts

Carried forward honestly; none is papered over.

| # | Item | Status |
|---|---|---|
| 1 | **`flutter_timezone` (or an equivalent) is required and has not been audited.** Something must supply the device's IANA name to `tz.setLocalLocation`. Decision-record §5 states this explicitly and forbids copying note 06's version number into a pubspec. **Audit it by c1's method — pub.dev API, publisher, transitive graph, merged manifest — and record the verified version in §5 before adding it.** | Blocking the first release build |
| 2 | Whether an incorrect `tz.local` can move the *fired* instant on iOS, given `flutter_local_notifications` 22.2.0's trigger construction. The DST-8 invariant proves the Dart-side conversion is a rendering, not a shift; the plugin's iOS side is unread. | Unverified — measure on a device |
| 3 | The iOS permission resolver's exact type name after v19's `Darwin` rename. Note 06 contradicts itself between §1.2 and §9. | Verify against the installed 22.2.0 |
| 4 | `getNotificationAppLaunchDetails()`'s shape on 22.2.0, after v20 made every parameter named. | Verify against the installed 22.2.0 |
| 5 | `flutter_image_compress`'s `minWidth`/`minHeight` — floors or caps (04 §4.4). Decision #40 specifies *longest edge* 2048. | Measure on one portrait and one landscape frame |
| 6 | Typical bytes for a 2048 px / q80 photo. Only the 1600 px figures were ever measured. | Measure; record in `docs/perf/measurements.md` |
| ~~7~~ | ~~`flutter_image_compress`'s Android manifest contribution was never verified.~~ **Closed 2026-08-01 by G0:** `flutter_image_compress_common` merges `<application>` attributes and contributes **no** permission. | Closed — evidence in `docs/gates/manifest-merger-release-report.txt` |
| 8 | `ShareResultStatus`'s member set on `share_plus` 13.3.0. | Verify before writing the `switch` |
| 9 | `timezone`'s `latest_10y` vs `latest` byte cost (85 KB vs 361 KB, from note 06). | Read from `--analyze-size` output |
| 10 | The iOS 64-request over-limit behaviour. Three conflicting descriptions; the issue was closed `not planned`. | **Permanently undefined.** The 56 budget exists because of it |
| 11 | §7.1 #17 — does the free tier cap reminders? 15 ewes fits inside 56 comfortably; 400 does not. | Owner. Changes the budget, not the architecture |
| 12 | §7.1 #18 — voice-note cap 60 s or 120 s. | Owner. One-line change to `kVoiceNoteMaxSeconds` |
| ~~13~~ | ~~**G0 has not been run.**~~ **Run 2026-08-01** (N02-T01). `ACCESS_NETWORK_STATE` is **not** removed: billing 8.0.0's own manifest declares no network permission, and `com.google.android.datatransport:transport-backend-cct:3.1.8` — a compile-scope dependency of it — declares both that and `INTERNET`. Two corrections came with it: `WAKE_LOCK` is contributed by nothing, and `androidx.core:core:1.18.0` contributes `${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. | Closed — the offline gate is writable; N31-T03 writes it |
| ~~14~~ | ~~The effective `minSdk` after plugin manifest merging (§8.3).~~ **Read 2026-08-01: `minSdkVersion="24"`, `targetSdkVersion="36"`,** off the merged manifest and not off a changelog line. It agrees with 13 §3.1's expectation — which is the outcome that needed proving, not the one that could be assumed. | Closed — recorded in 13 §2.2's table. N31-T02 still sets it **explicitly**, because an inherited value moves silently |
| 15 | ~~AGP's real floor for `share_plus` 13.3.0 and `flutter_local_notifications` 22.2.0 (§8.3 quotes 8.12.1 and 8.11.1 from their READMEs).~~ **VERIFIED 2026-08-04, N31-T02 — read off the installed packages rather than their READMEs.** `share_plus-13.3.0/android/build.gradle.kts` pins `com.android.tools.build:gradle:8.12.1`; `flutter_local_notifications-22.2.0/android/build.gradle` pins `8.11.1`. The READMEs were right, which is worth recording because it was not knowable without looking: a README changes a floor without a changelog entry. The project is on AGP **9.0.1**, above both, and `flutter_local_notifications` 22.2.0 compiles against `compileSdk 36` with `minSdkVersion 24` — which is where this task's three explicit numbers come from. | Verified; no action |

Six edits this document requires elsewhere, flagged rather than made silently:

- [`07-screens.md`](07-screens.md) §11.2 gains a fourth disclosure line and a per-row "approximate" chip for the inexact-alarm state (§2.9).
- [`01-architecture.md`](01-architecture.md) §3.2 gains the `_confinedPackages` table (§1.2), the eight `_bannedText` rows (§9), and a fifth `[exempt]` line.
- `CONVENTIONS.md` §4.7 gains two rule-id namespaces, `notify` and `share` (§9). `media` is already produced by that section's own rename table and needs no ruling.
- `CONVENTIONS.md` §2.8 gains one verb on an existing service: `RestoreService.restoreFrom(File) → Future<RestoreOutcome>`, which is the seam 04 §7.2 step 1 describes without naming (§1.3).
- `CONVENTIONS.md` §3.1's note on `reminderReconcilerProvider` reads "needs the DB **and** the notification seam"; it also needs `settingsRepositoryProvider`, because `app_settings` is `SettingsRepository`'s to write (§2.13 of that file) and `reconcile()` must record its own projection. `SettingsRepository.recordProjection({required int scheduled, required Instant at})` is a new verb on an existing repository, not a new type.
- `CONVENTIONS.md` §1's `lib/features/settings/` gains `restore_flow.dart`, and `lib/features/reminders/` gains `reminder_copy.dart` (§1.3, §2.6). Neither is a new class name; both follow §4.1.

None of these is a rename. Nothing in `CONVENTIONS.md` §2 or §3 is re-spelled by this document, and R9's three names — `CameraService`, `VoiceRecorder`, `WakelockController` — are adopted exactly as given.

---

## Definition of done

**Gateways**
- [ ] The six **platform** gateway classes this document owns exist under `lib/data/` with `CONVENTIONS.md` §2.12's exact names and file names, and no second spelling of any of them. There is no seventh *platform* seam: the only other class of this shape in the app is `PurchaseService` (`lib/data/purchase_service.dart`), which is the store seam, is owned by [`11-monetization-and-store.md`](11-monetization-and-store.md) §5, and is not documented here.
- [ ] Every plugin in `_confinedPackages` has exactly one import site — two for `path_provider` — and `dart tool/check_policy.dart` fails on a seeded violation of each of the nine rows. The `path_provider` row uses `CONVENTIONS.md` §4.7's existing id `layer.path_provider`; the other eight are `layer.plugin_<package>` with the pub package name spelled out.
- [ ] `lib/features/reminders/notification_gateway.dart` does not exist (R48).
- [ ] Hand-written fakes exist in `test/support/` for all six — seven counting `FakePurchaseService`, which [`12-testing.md`](12-testing.md) §4.2 owns; no gateway is mocked with `mocktail`.
- [ ] `file_selector` is imported in exactly one file, `lib/features/settings/restore_flow.dart`, and `RestoreService` takes a `File`.

**Notifications**
- [ ] `reconcile()` is called from exactly four sites, debounced to 500 ms, idempotent under concurrent calls, never inside `db.transaction()`, and off the paint frame.
- [ ] `zonedSchedule(` appears in exactly one file and is the one `[exempt]` line this document adds.
- [ ] `ReminderBudget.forPlatform()` returns 56 on iOS and 200 on Android, and the literal `56` appears in no ARB message and no widget.
- [ ] `reconcile()` writes `app_settings.last_reconcile_scheduled` in the same transaction that records the projection, and that column exists in 03 §5.13.
- [ ] The soonest-N query filters `completed_at IS NULL AND muted = 0 AND due_at > :after`, and a test with three overdue rows asserts zero are projected.
- [ ] The eight Android channel ids are byte-identical to `reminders.kind`'s CHECK, asserted against the committed schema JSON.
- [ ] No channel name, notification title or body states a clinical window, a dose, a product name, a batch number or a withdrawal period in days.
- [ ] `initialize()` sets all three Darwin `request*` parameters to `false`; a widget test launches the app and asserts zero permission calls.
- [ ] The notification permission is requested from exactly two explicit taps and from no write path; no `app_settings` column exists to remember a prompt.
- [ ] `USE_EXACT_ALARM` appears nowhere in the merged manifest of the shipped `.aab` (asserted by G1, which is the real gate) and nowhere in `lib/` (asserted by `notify.use_exact_alarm`, which cannot see `android/`); `SCHEDULE_EXACT_ALARM` is declared.
- [ ] `NotificationScheduler.canBeExact()` is called exactly once per `reconcile()` and its answer is passed to `project(…, exact:)`; no field and no `app_settings` column caches it; the mode is `exactAllowWhileIdle` or `inexactAllowWhileIdle` and never `exact` or `alarmClock`. A test revokes it on the fake between two reconciles and asserts the second run projects inexact.
- [ ] `AndroidScheduleMode` is named in exactly one expression, inside `project()`.
- [ ] `tz.setLocalLocation` is called from exactly two places, both in `notification_scheduler.dart`: `initialize()` and `refreshLocalZone()`. `reconcile()` calls `refreshLocalZone()` before it projects, and a test that changes the fake's zone between two reconciles asserts the second projection used the new one.
- [ ] `scheduleTimeFor` is a top-level public function in `notification_scheduler.dart`, and DST-8 calls it directly rather than through a `@visibleForTesting` hole.
- [ ] While exact alarms are denied, every reminder row shows an "approximate" chip (icon **and** text) and the disclosure box shows the fourth line.
- [ ] `RECEIVE_BOOT_COMPLETED` and both `flutter_local_notifications` receivers are declared in our manifest.
- [ ] `matchDateTimeComponents` appears nowhere.
- [ ] The notification id is `reminders.id`; no id is derived from a hash.
- [ ] `test/data/reminder_dst_test.dart` carries `@Tags(['uk-zone'])` and DST-6 through DST-9 all pass under `TZ=Europe/London`.

**Media**
- [ ] `CameraService` owns `image_picker`; `VoiceRecorder` owns `record`; `MediaStore` owns the root, the paths and the compression (R47). 04 §4.4's "a method ON MediaStore" comments are corrected.
- [ ] `pick()` calls `retrieveLostData()` first and marks the result `recovered`; the UI says so on screen.
- [ ] `keepExif: true` appears nowhere; a test asserts the written JPEG carries no GPS tag.
- [ ] A test asserts `max(width, height) ≤ 2048` and `bytes ≤ 900 KB` on a real captured frame, on both a portrait and a landscape source.
- [ ] Voice notes are AAC-LC `.m4a`, mono; `AudioEncoder.opus` appears nowhere.
- [ ] `kVoiceNoteMaxSeconds` is one constant in `lib/data/media_limits.dart`, enforced inside `VoiceRecorder.start()` and not only by the UI countdown.
- [ ] The `media_assets` row is inserted when recording starts; `byte_size` is written on stop; a row with `byte_size = 0` renders as interrupted and offers Delete, not Play.
- [ ] Recording is tap-to-start / tap-to-stop at ≥60×60 pt with a level meter; there is no press-and-hold anywhere.

**Share, import, wakelock**
- [ ] `ShareService.shareFiles` takes `origin` as a **required** parameter; `Rect.zero` appears at no call site.
- [ ] `Share.share` and `XFile.fromData` appear nowhere.
- [ ] `last_exported_at` is written on `completed` and `unknown`, not on `dismissed`, and never before the sheet opens.
- [ ] The backup picker accepts `application/octet-stream` and the magic-byte check refuses ZIP and SQLite files by name.
- [ ] `WakelockController.acquire()` is called only by the route observer, only on the three permitted routes, and only when `wakelock_enabled` is true.
- [ ] `release()` is unconditional, and the lifecycle handler calls it on every non-resumed state.
- [ ] The 30-minute expiry has a passing widget test, as do the two navigation cases.

**Permissions and gates**
- [ ] `permission_handler` is absent from `pubspec.yaml` and from `lib/`.
- [ ] G1 asserts §8.3's exact set on the shipped `.aab`, and it is a required check.
- [ ] **G0 has been run**, the Play Billing 8.0.0 contribution is recorded in the decision record, and `ACCESS_NETWORK_STATE`'s removal is either committed with evidence or not committed at all.
- [ ] `com.android.vending.BILLING` is on the asserted list.
- [ ] The three iOS usage-description strings are present, `NSAppTransportSecurity` is absent, and `UIFileSharingEnabled` is not set.
- [ ] `minSdk` is whatever the merged manifest says it is, recorded in 13 §2.2's G0 table, and appears as a literal in no document including this one.
- [ ] No "`http` must not be in `pubspec.lock`" gate exists anywhere in CI.
- [ ] `flutter_timezone` (or its equivalent) has been audited by c1's method and its verified version recorded in decision-record §5 **before** it appears in `pubspec.yaml`.

---

## References

Fetched 2026-07-27 unless noted.

**Packages (versions from decision-record §5 only)**
- `flutter_local_notifications` 22.2.0 — https://pub.dev/packages/flutter_local_notifications · changelog https://pub.dev/packages/flutter_local_notifications/changelog
- `AndroidScheduleMode` — https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/AndroidScheduleMode.html
- Plugin Android manifest (`VIBRATE` + `POST_NOTIFICATIONS`, nothing else) — https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/AndroidManifest.xml
- Plugin Dart API (v22 named parameters) — https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/lib/src/flutter_local_notifications_plugin.dart
- `checkCanScheduleExactAlarms` in the plugin's Java — https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java
- `timezone` 0.11.1 — https://pub.dev/packages/timezone
- `image_picker` 1.2.3 — https://pub.dev/packages/image_picker · Android manifest (zero permissions) https://raw.githubusercontent.com/flutter/packages/main/packages/image_picker/image_picker_android/android/src/main/AndroidManifest.xml
- `flutter_image_compress` 2.5.1 — https://pub.dev/packages/flutter_image_compress
- `record` 7.1.1 — https://pub.dev/packages/record · `AudioEncoder` (Opus containers differ per platform) https://pub.dev/documentation/record/latest/record/AudioEncoder.html · Android manifest (`RECORD_AUDIO` only) https://raw.githubusercontent.com/llfbandit/record/master/record_android/android/src/main/AndroidManifest.xml
- `share_plus` 13.3.0 — https://pub.dev/packages/share_plus · Android manifest (no permissions) https://raw.githubusercontent.com/fluttercommunity/plus_plugins/main/packages/share_plus/share_plus/android/src/main/AndroidManifest.xml
- `file_selector` 1.1.0 — https://pub.dev/packages/file_selector
- `wakelock_plus` 1.7.0 — https://pub.dev/packages/wakelock_plus
- Rejected: `camera` 0.12.0+2 https://pub.dev/packages/camera · `file_picker` 11.0.2 https://pub.dev/packages/file_picker · `permission_handler` 12.0.3 https://pub.dev/packages/permission_handler · `speech_to_text` 7.4.0 https://pub.dev/packages/speech_to_text · `google_mlkit_text_recognition` 0.16.0 https://pub.dev/packages/google_mlkit_text_recognition · `open_filex` 4.7.0 https://pub.dev/packages/open_filex

**Apple**
- Developer Forums thread 811171 — the 64 pending-request limit per app — https://developer.apple.com/forums/thread/811171
- Third-party SDK privacy-manifest requirements — https://developer.apple.com/support/third-party-SDK-requirements/

**Android / Google Play**
- Play Console Help 9888170 — `USE_EXACT_ALARM` is restricted to alarm/timer and calendar apps — https://support.google.com/googleplay/android-developer/answer/9888170
- Android 14 changes to `SCHEDULE_EXACT_ALARM` (denied by default) — https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- Scheduling alarms; inexact delivery windows — https://developer.android.com/develop/background-work/services/alarms/schedule
- Android 14 behaviour changes (`USE_FULL_SCREEN_INTENT`) — https://developer.android.com/about/versions/14/behavior-changes-14
- Play target-API requirement (API 36 from 31 Aug 2026) — https://developer.android.com/google/play/requirements/target-sdk
- The system photo picker — https://developer.android.com/training/data-storage/shared/photopicker
- Notification channels — https://developer.android.com/develop/ui/views/notifications/channels
- Manifest merging and `tools:node="remove"` — https://developer.android.com/build/manage-manifests

**Flutter**
- flutter/flutter#23957 — the iOS container UUID is not stable across launches — https://github.com/flutter/flutter/issues/23957
- MaikuB/flutter_local_notifications#2312 — a third, conflicting description of the over-64 behaviour; closed `not planned` — https://github.com/MaikuB/flutter_local_notifications/issues/2312

**Project sources**
- `docs/research/00-tech-decisions.md` — §1 (the five pre-commit decisions), §2 G (platform integration), §3 (the offline-purity contract and the permission set), §4 (dropped and degraded), §5 (the only source of version numbers), §7.0 (the owner's rulings).
- `docs/research/raw/06-platform-integration.md` — §1 notifications end to end, §4 camera, §5 audio, §6.4 share, §7 file import, §8 wakelock, §9 permissions, §13 pitfalls.
- `docs/research/critique/c1-packages.md` — the verified package audit; the `http`-on-two-edges correction that makes a lockfile gate unsatisfiable.
- `docs/research/critique/c3-consistency.md` — C7 (OCR), C8 (scheduling inside a transaction), C9 (the timezone boundary), B1/B2 (the manifest-merger prerequisite and the billing permission).

**Sibling documents**
[`CONVENTIONS.md`](CONVENTIONS.md) (the naming authority; R9, R47–R51) · [`01-architecture.md`](01-architecture.md) (the gate, the layer rules, `main()`) · [`02-state-di-navigation.md`](02-state-di-navigation.md) (the gateway providers, the lifecycle handler, `Routes`) · [`03-data-model-and-schema.md`](03-data-model-and-schema.md) (`reminders`, `media_assets`, `app_settings`) · [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) (`MediaStore`, the media layout, the restore flow) · [`05-domain-correctness.md`](05-domain-correctness.md) (`Instant`, `appNow()`, `checkLocalWallTimeExists`, the DST tests) · [`06-design-system.md`](06-design-system.md) (tap targets, the gesture ban, dark launch) · [`07-screens.md`](07-screens.md) (the Reminders screen, the export banner, the reconciliation rule) · `09-export-formats.md` (what the share sheet carries) · `11-monetization-and-store.md` (billing, privacy declarations) · `12-testing.md` (the fakes, the harness) · `13-build-ci-release.md` (G0–G5, the manifest assertion, the size budget).
