# 06 — Plugins & Platform Integration

**Shed Book** · offline-only lambing notebook · Flutter 3.44.6 / Dart 3.12.2 / Xcode 26.6
Research date: **2026-07-27**. Every version below was read off pub.dev on that date. Relative dates
("28 days ago") are what pub.dev displayed; absolute dates are my arithmetic from 2026-07-27.

> **Read this first.** This app makes a marketing claim — "permanently offline, no server, no account,
> nothing leaves the device" — that most Flutter plugin advice silently violates. Three of the most
> popular answers in the Flutter community (`speech_to_text` as documented, `google_mlkit_text_recognition`,
> and `printing`) each introduce a network path. Two of them do it in ways that are invisible until you
> read a Gradle POM or a transitive `pubspec`. This document exists mostly to catch that.

---

## Bottom line

| Capability | Decision | Package / API | Version verified 2026-07-27 | Offline verdict |
|---|---|---|---|---|
| Local notifications | **Adopt** | `flutter_local_notifications` | 22.2.0 (dexterx.dev, ~2026-07-25) | Clean. Merges `POST_NOTIFICATIONS` + `VIBRATE` only |
| Timezone data | **Adopt** | `timezone` | 0.11.1 (labs.dart.dev, ~2026-06-29) | Clean. IANA 2025c bundled as Dart source, no fetch |
| Device timezone name | **Adopt** | `flutter_timezone` | 5.1.0 (wolverinebeach.net, ~2026-05-28) | Clean. No permissions |
| Exact alarms | **Adopt-with-care** | `SCHEDULE_EXACT_ALARM` only, never `USE_EXACT_ALARM` | — | Play policy: `USE_EXACT_ALARM` = store rejection for this app |
| Voice **tag entry** (STT) | **Defer to v1.1, gated** | `speech_to_text` w/ `onDevice: true` | 7.4.0 (csdcorp.com, ~2026-05-27) | Conditionally offline. Cannot be *guaranteed* without a runtime capability check the plugin does not expose |
| Voice **note** (recording) | **Adopt — ship this instead** | `record` | 7.1.1 (cow-level.ovh, ~2026-06-29) | Clean. Merges `RECORD_AUDIO` only. No recognition, no network, no second process |
| Tag OCR | **Cut from v1** | ~~`google_mlkit_text_recognition`~~ | 0.16.0 (flutter-ml.dev, ~2026-07-08) | **Rejected.** Pulls `play-services-base`/`basement`; +38 MB on iOS; ML Kit sends metrics to Google by Google's own terms |
| Photo attachment | **Adopt** | `image_picker` | 1.2.3 (flutter.dev, ~2026-07-01) | Clean. Merges **zero** permissions |
| Photo downscale / EXIF strip | **Adopt** | `flutter_image_compress` | 2.5.1 (fluttercandies.com, ~2026-07-25) | Clean. `keepExif` defaults to **false** |
| Full camera control | **Reject for v1** | ~~`camera`~~ | 0.12.0+2 (flutter.dev, ~2026-07-14) | Not needed; `image_picker` uses the system camera UI and avoids a preview surface |
| CSV | **Hand-roll (~50 lines)** | RFC 4180 writer in `lib/export/csv_writer.dart` | — | Zero deps. `csv` 8.0.0 is an unverified-uploader rewrite |
| PDF | **Adopt** | `pdf` | 3.13.0 (nfet.net, ~2026-06-17) | Clean **if** you never add `printing` |
| PDF print dialog | **Reject** | ~~`printing`~~ | 5.15.0 (nfet.net, ~2026-06-17) | **Rejected.** Depends on `http`. Share sheet delivers the PDF instead |
| Share sheet | **Adopt** | `share_plus` | 13.3.0 (fluttercommunity.dev, ~2026-07-24) | Clean. Merges a FileProvider + one receiver, no permissions |
| Backup ZIP | **Adopt** | `archive` | 4.0.9 (loki3d.com, ~2026-02) | Clean. Deps: `path`, `posix` only |
| File import (restore) | **Adopt** | `file_selector` | 1.1.0 (flutter.dev, ~2025-11) | Clean. `file_picker` loses on deps + permissions history |
| Paths | **Adopt** | `path_provider` | 2.1.6 (flutter.dev, ~2026-06-16) | Clean |
| Keep screen awake | **Adopt, scoped + opt-in** | `wakelock_plus` | 1.7.0 (fluttercommunity.dev, ~2026-07-22) | Clean. `WAKE_LOCK` is a normal (install-time) permission |
| Runtime permissions | **No package** | Each plugin's own request API | — | `permission_handler` 12.0.3 is unnecessary here |

**Target manifest permission set (the whole list):**

```
android.permission.POST_NOTIFICATIONS      <- flutter_local_notifications (merged)
android.permission.VIBRATE                 <- flutter_local_notifications (merged)
android.permission.RECEIVE_BOOT_COMPLETED  <- we add (reschedule after reboot)
android.permission.SCHEDULE_EXACT_ALARM    <- we add (user-granted, optional)
android.permission.RECORD_AUDIO            <- record (merged)
android.permission.WAKE_LOCK               <- wakelock_plus (merged)
android.permission.INTERNET                <- ABSENT. Explicitly removed at merge time.
```

Seven permissions, none of them dangerous except `RECORD_AUDIO`, and no `INTERNET`.
That is the whole point of this document.

---

## 0. What "offline" is actually being claimed, in three tiers

Be precise about this in the docs and in the App Store / Play listing, because tier 3 is not
achievable and claiming it would be a lie.

| Tier | Claim | Achievable? |
|---|---|---|
| 1 | **The app has no network code and no INTERNET permission.** Nothing in our process can open a socket. | **Yes on Android**, mechanically provable (§11). Yes on iOS by construction + observable via App Privacy Report. |
| 2 | **No dependency attempts a network call.** | **Yes**, if we drop ML Kit and `printing`. Provable by `dart pub deps` + merged-manifest inspection. |
| 3 | **No data ever leaves the device by any route.** | **No.** The user can share an export anywhere. The OS share sheet, the Android photo picker, and (if we shipped it) the platform speech recognizer are *other processes* with their own network access. Removing `INTERNET` from **our** manifest does not constrain them. |

The honest public wording is tier 1 + 2:

> "Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when
> you deliberately export and share them."

**Do not write "your data never leaves your phone."** It does, the moment they AirDrop a CSV — which is
the backup story the spec depends on.

---

## 1. Local notifications (spec 7.6)

### 1.1 The package

[`flutter_local_notifications` **22.2.0**](https://pub.dev/packages/flutter_local_notifications) —
publisher `dexterx.dev` (verified), Flutter Favorite, 7.3k likes, 150 pub points, published ~2 days
before 2026-07-27. Requires **Flutter ≥ 3.38.1 / Dart ≥ 3.10** — we're on 3.44.6/3.12.2, fine.
Dependencies: `clock`, `timezone ^0.11.0`, and the platform-interface / linux / web / windows federated
packages. **No HTTP client anywhere in the graph.**

It is on
[Apple's third-party-SDK list](https://developer.apple.com/support/third-party-SDK-requirements/)
that requires a privacy manifest and a signature — the current pod ships one; do not pin an ancient
version.

**Manifest merged by the plugin itself** — verified against
[the plugin's own `AndroidManifest.xml` on `master`](https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/AndroidManifest.xml):

```xml
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

That's it. Since v16 the plugin deliberately declares only "the bare minimum" and pushes everything
else onto the app.

**What we must add ourselves** (from the
[plugin README](https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/README.md)):

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<!-- NOT USE_EXACT_ALARM. See §1.3. -->

<application ...>
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
      <action android:name="android.intent.action.BOOT_COMPLETED"/>
      <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
      <action android:name="android.intent.action.QUICKBOOT_POWERON" />
      <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
  </receiver>
</application>
```

Gradle: core-library desugaring is required —
`coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'` (README-stated minimum for 22.x)
and AGP ≥ 8.11.1.

**iOS setup:** no Info.plist key, no entitlement, no background mode. Just
`UNUserNotificationCenter.current().delegate = self` in `AppDelegate` and
`DarwinInitializationSettings`. **Do not** let `initialize()` fire the permission prompt at first
launch — the 3am spec says "no notification permission nags." Set
`requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false` and
call `IOSFlutterLocalNotificationsPlugin.requestPermissions()` the first time the user actually
creates a reminder.

### 1.2 Current API (v22 — verify against this, not memory)

Everything went **named** in v20.0.0. If you write the old positional form it will not compile.
Verified against
[`flutter_local_notifications_plugin.dart` on `master`](https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/lib/src/flutter_local_notifications_plugin.dart):

```dart
Future<bool?> initialize({
  required InitializationSettings settings,
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
});

Future<void> show({
  required int id,
  String? title,
  String? body,
  NotificationDetails? notificationDetails,
  String? payload,
});

Future<void> zonedSchedule({
  required int id,
  required TZDateTime scheduledDate,
  required NotificationDetails notificationDetails,
  required AndroidScheduleMode androidScheduleMode,   // required since v18
  String? title,
  String? body,
  String? payload,
  DateTimeComponents? matchDateTimeComponents,
});
```

Breaking changes in the last ~18 months that will bite anyone porting old sample code
([changelog](https://pub.dev/packages/flutter_local_notifications/changelog)):

- **22.0.0** — web + Windows support; error codes lowercased (`INVALID_ICON` → `invalid_icon`).
- **21.0.0** — Flutter ≥ 3.38.1, Dart ≥ 3.10, **Android minSdk 24**, iOS 13+, compileSdk 36.
- **20.0.0** — all positional params → named on `initialize`, `show`, `zonedSchedule`, `cancel`,
  `periodicallyShow`.
- **19.0.0** — removed `uiLocalNotificationDateInterpretation` from `zonedSchedule`; iOS/macOS
  classes renamed with the `Darwin` prefix.
- **18.0.0** — removed `androidAllowWhileIdle`; **`androidScheduleMode` is now required**.
- **16.0.0** — `requestPermission()` → `requestNotificationsPermission()`; plugin manifest reduced to
  the bare minimum; `requestExactAlarmsPermission()` added.

### 1.3 Android exact alarms — the store-rejection trap

Two permissions, and picking the wrong one gets the app removed from Google Play.

| | `SCHEDULE_EXACT_ALARM` | `USE_EXACT_ALARM` |
|---|---|---|
| Introduced | Android 12 (API 31) | Android 13 (API 33) |
| Granted how | **User**, via *Settings → Alarms & reminders* | **Automatically** at install, cannot be revoked |
| Android 14+ default for new installs targeting API 33+ | **Denied** | n/a (auto-granted) |
| Google Play policy | No restriction | **Restricted to alarm/timer and calendar apps** |

The Play policy text, quoted from
[Play Console Help 9888170 (Permissions and APIs that Access Sensitive Information)](https://support.google.com/googleplay/android-developer/answer/9888170):
`USE_EXACT_ALARM` is permitted only where "core, user facing functionality requires precisely-timed
actions" — specifically "The app is an alarm or timer app" or "The app is a calendar app that shows
event notifications" — and apps "that do not meet the acceptable use case criteria will be disallowed
from publishing on Google Play." Google's own guidance is to use `SCHEDULE_EXACT_ALARM` instead, which
"provides the same functionality but access must be granted by the user."

**Does Shed Book qualify for `USE_EXACT_ALARM`? No.** It is a record-keeping notebook that also sets
reminders. It is not an alarm clock and not a calendar. Declaring `USE_EXACT_ALARM` would be a policy
violation and a rejected release. This is unambiguous — do not let anyone talk you into it because
"the colostrum window is time-critical."

Also confirmed on
[developer.android.com — Android 14 changes to SCHEDULE_EXACT_ALARM](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms):
on Android 14+, `SCHEDULE_EXACT_ALARM` is **denied by default** for newly-installed apps targeting
API 33+. Only calendar/alarm apps (via `USE_EXACT_ALARM`), platform-signed apps, privileged apps,
power-allowlisted apps and `SYSTEM_WELLBEING` role holders are pre-granted.

We must ship targetSdk **36** anyway:
[Play's target API requirement](https://developer.android.com/google/play/requirements/target-sdk)
is Android 16 / API 36 for new apps and updates from **31 August 2026** (extension available to
1 November 2026). So we are squarely inside the denied-by-default regime.

#### AndroidScheduleMode → AlarmManager, and where it throws

Verified against
[`FlutterLocalNotificationsPlugin.java` on `master`](https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java):

```java
private static void checkCanScheduleExactAlarms(AlarmManager alarmManager) {
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
    throw new ExactAlarmPermissionException();
  }
}
```

`checkCanScheduleExactAlarms` is called on the `exact`, `exactAllowWhileIdle` and `alarmClock` paths
before `AlarmManagerCompat.setExact` / `setExactAndAllowWhileIdle` / `setAlarmClock`. The
`inexact*` paths go straight to `set` / `setAndAllowWhileIdle` with no check.

| Mode | AlarmManager call | Needs exact-alarm permission on API 31+ | Fires in Doze |
|---|---|---|---|
| `alarmClock` | `setAlarmClock` | **Yes** | Yes (highest priority, shows a system alarm icon) |
| `exactAllowWhileIdle` | `setExactAndAllowWhileIdle` | **Yes** | Yes |
| `exact` | `setExact` | **Yes** | No |
| `inexactAllowWhileIdle` | `setAndAllowWhileIdle` | No | Yes |
| `inexact` | `set` | No | No |

Inexact accuracy, from
[developer.android.com — schedule alarms](https://developer.android.com/develop/background-work/services/alarms/schedule):
on Android 12+ an inexact alarm never fires *early* and is delivered "within one hour of the trigger
time" absent Doze/battery-saver. `setWindow()` clips `windowLengthMillis` up to a **10-minute minimum**.

#### What this means for a colostrum-window reminder

A lamb needs colostrum inside the first hours of life. A ±60-minute slip on a "give colostrum now"
ping is not a rounding error — it can be the whole clinical window. So exactness genuinely matters
here, and we are not allowed the permission that makes it free.

**The design that survives this:**

1. Ship `SCHEDULE_EXACT_ALARM` in the manifest. It is not policy-restricted; it is just user-granted.
2. On first reminder creation only (never at launch), if
   `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` is `false`, show one
   60×60pt sheet: *"Reminders can be on-the-minute, or up to an hour late. Turn on 'Alarms &
   reminders' for on-the-minute."* → `requestExactAlarmsPermission()`. One prompt, ever. Remember the
   dismissal.
3. Pick the mode per reminder from the *actual* current capability, re-checked at every reconcile:
   - exact granted → `AndroidScheduleMode.exactAllowWhileIdle`
   - exact denied → `AndroidScheduleMode.inexactAllowWhileIdle`
4. **Be honest in the UI** (spec §12.5 extends naturally here). On the Reminders screen, show a small
   "approximate" chip on every reminder that is scheduled inexactly. A shepherd who believes a
   colostrum reminder is exact when it is ±1h is being misled by the app.
5. Register a receiver for `AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` (or
   simply reconcile on every `AppLifecycleState.resumed`) so that granting the permission later
   upgrades all pending reminders to exact.

`alarmClock` is tempting — it is the most reliable Doze-buster — but it plants a system alarm icon in
the status bar and reads to the user as "your alarm clock is set." That is wrong for a withdrawal-period
reminder. Use it nowhere.

#### One more Android 14 trap in the same family

`USE_FULL_SCREEN_INTENT` was restricted by the *same* policy pattern:
[Android 14 behavior changes](https://developer.android.com/about/versions/14/behavior-changes-14) —
for apps targeting API 34+, Play auto-grants it only to calling and alarm apps; everyone else must
check `NotificationManager.canUseFullScreenIntent()` and send the user to
`Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`.
**Do not use full-screen intents.** Do not declare the permission. A standard heads-up notification on
a high-importance channel is enough, and it is what the 3am user expects.

### 1.4 iOS: the 64-request ceiling, and why fire-and-forget scheduling is fatal here

Apple's limit is **64 pending notification requests per app**. This is stated by an Apple engineer on the
[Developer Forums thread 811171](https://developer.apple.com/forums/thread/811171): *"there is a limit
of 64 for how many simultaneous notification requests can be active/pending at one time per app. This
is a system limit and there is no way around it."* The `flutter_local_notifications` README puts it as
"iOS will only keep the 64 notifications that were last set on any iOS versions newer than 9."

The two descriptions disagree (soonest-64 vs last-64), and
[flutter_local_notifications issue #2312](https://github.com/MaikuB/flutter_local_notifications/issues/2312)
reports a third behaviour: at 65+, *none* fired. It was closed as `not planned`.

**Treat the failure mode as undefined and never approach the ceiling.** Design for a hard budget of
**56**, leaving 8 slots of headroom.

#### The budget maths for this app

Spec 7.6 lists six reminder types. A 400-ewe flock at peak lambing could have, in one week:

- ~60 lambings, each producing colostrum + navel-dip + turn-out reminders = 180
- tag-by dates on ~120 lambs = 120
- ring/dock/castrate on ~120 lambs = 120
- second doses + withdrawal ends on ~40 treatments = 80

That is **~500 pending reminders against a 64-slot OS budget**. Naive `zonedSchedule()`-on-write is
not "mostly fine, occasionally lossy" — it is *structurally broken*, and the way it breaks is that the
oldest or newest reminders silently vanish. In a shed, silently-vanishing means a lamb doesn't get
tubed.

#### The correct architecture: SQLite is the source of truth; the OS holds a cache

The `Reminder` table (spec §10) is the record. The notification centre holds a **windowed projection**
of it. One idempotent function reconciles them.

```dart
/// The OS holds at most [_iosBudget] pending requests. SQLite holds all of them.
/// This function is the ONLY place that talks to the notification centre.
/// It is idempotent: calling it twice in a row is a no-op.
class ReminderScheduler {
  static const _iosBudget = 56;   // 64 hard limit, 8 slots of headroom
  static const _androidBudget = 200; // Android has no documented cap; stay sane anyway

  final FlutterLocalNotificationsPlugin _fln;
  final ReminderDao _dao;
  final SettingsDao _settings;

  Future<void> reconcile() async {
    final budget = Platform.isIOS ? _iosBudget : _androidBudget;

    // 1. Ask the DB, not memory, for the truth.
    final due = await _dao.soonestPending(
      limit: budget,
      after: DateTime.now().toUtc(),        // never schedule the past
    ); // WHERE completed_at IS NULL AND muted = 0 AND due_at > ? ORDER BY due_at LIMIT ?

    // 2. Decide the Android delivery mode from the CURRENT permission state.
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canBeExact = Platform.isAndroid
        ? (await android?.canScheduleExactNotifications() ?? false)
        : true;
    final mode = canBeExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // 3. Full teardown + rebuild. Pending requests are invisible to the user,
    //    so there is no flicker cost, and this removes an entire class of drift bug.
    await _fln.cancelAll();

    for (final r in due) {
      await _fln.zonedSchedule(
        id: r.id,                                   // INTEGER PRIMARY KEY, stable, < 2^31
        title: _title(r),
        body: _body(r),
        scheduledDate: tz.TZDateTime.from(r.dueAtUtc, tz.local), // <- see §1.5
        notificationDetails: _details(r.type),
        androidScheduleMode: mode,
        payload: 'reminder:${r.id}',
      );
    }

    await _settings.setLastReconcile(DateTime.now().toUtc(), scheduled: due.length);
  }
}
```

**Call `reconcile()` from exactly these places, and nowhere else:**

| Trigger | Why |
|---|---|
| App start, after DB open | Recover from a kill, a reboot, an OS purge |
| `AppLifecycleState.resumed` | Timezone change, permission change, notifications delivered while away |
| After any write that touches `Reminder`, `Lambing`, `Treatment`, or reminder-interval settings | Every write commits immediately (spec §5) — so must the projection |
| After the user taps a notification (marks a reminder complete) | The 57th reminder can now enter the window |

Debounce it to at most once per 500 ms and run it off the paint frame. On a 400-ewe device it is
56 platform-channel calls; measure it, but expect low tens of milliseconds.

**Why full teardown rather than a diff:** `pendingNotificationRequests()` returns only
`id/title/body/payload`, so a diff needs a content hash smuggled into the payload, and it still can't
see whether the *schedule mode* changed. `cancelAll()` + rebuild is ~10 lines instead of ~80 and
cannot drift. The only cost is churn, which is invisible.

**Don't forget the horizon.** With a 56-slot window, a reminder due in 6 weeks may not be scheduled at
all today. That's correct and safe — it'll enter the window as nearer ones are completed — *provided*
`reconcile()` runs regularly. It does, because the shepherd opens the app several times a night. But
add a belt: an inexact daily "housekeeping" notification is **not** needed; instead show, on the
Reminders screen, "Showing the next 56 reminders on your lock screen. All 312 are stored in the app."
Honest, and it tells the user why a distant reminder didn't ping.

### 1.5 Timezones, DST, and the 02:30 problem

[`timezone` **0.11.1**](https://pub.dev/packages/timezone), publisher `labs.dart.dev` (verified), IANA
database **2025c** bundled. `latest` ≈ 361 KB, `latest_all` ≈ 443 KB, `latest_10y` ≈ 85 KB. **Nothing is
fetched at runtime** — the database is Dart source compiled into the app. Use `latest_10y` unless you
need historical zones; a lambing app never looks further back than a few seasons, and 85 KB vs 361 KB
matters against the spec's "well under 20 MB" payload budget.

[`flutter_timezone` **5.1.0**](https://pub.dev/packages/flutter_timezone) (publisher
`wolverinebeach.net`, verified, a maintained fork of the abandoned `flutter_native_timezone`) supplies
the device's IANA name. No permissions. Deps: `equatable`, `meta`.

```dart
Future<void> initTimezones() async {
  tzdata.initializeTimeZones();                       // package:timezone/data/latest_10y.dart
  final info = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(info.identifier));
}
```

#### The rule that makes DST a non-issue

**Store every `due_at` as a UTC instant.** Almost all Shed Book reminders are *offsets from an event*:
"colostrum + 2 h", "navel dip + 30 min", "turn out + 24 h", "withdrawal ends + N days". A duration is a
duration; it does not care about DST. Compute `dueAtUtc = eventUtc.add(interval)`, store epoch millis,
and only convert at schedule time via `tz.TZDateTime.from(dueAtUtc, tz.local)`. This is DST-correct by
construction and survives the shepherd flying to a different timezone.

The only wall-clock reminders are (a) the user-set "tag-by" date and (b) the end-of-day export nudge
(spec 7.9). For those:

- **Never default a wall-clock reminder to a time between 01:00 and 03:00 local.** In CET/CEST the
  clocks go 02:00 → 03:00 on the last Sunday of March, so **02:30 does not exist on that day**, and on
  the last Sunday of October 02:30 happens **twice**. In UK/IE the ambiguous hour is 01:00–01:59
  instead. `TZDateTime` will normalise a non-existent local time to *something*, and that something is
  not what the user typed.
- Default the end-of-day export nudge to **20:00 local**. Unambiguous everywhere, and it is when the
  shepherd is actually inside with a cup of tea.
- If the user picks a wall-clock time inside the DST gap, don't silently move it (spec §12.4 — never
  silently correct). Show it as entered and add a one-line note on the two affected days.
- Never use `matchDateTimeComponents` for anything in this app. Recurring notifications drift across
  DST and their state lives in the OS rather than in SQLite, which contradicts §5 ("assume the phone
  dies"). Every reminder in Shed Book is a one-shot row in SQLite; the projection re-creates it.

#### Reboot persistence

| | Behaviour |
|---|---|
| **Android** | `AlarmManager` alarms are **destroyed on reboot**. The plugin persists `NotificationDetails` to shared prefs and `ScheduledNotificationBootReceiver` calls `rescheduleNotifications(context)` on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`. Requires `RECEIVE_BOOT_COMPLETED` + the receiver declaration. Verified in the plugin's Java source. |
| **iOS** | Pending `UNNotificationRequest`s are held by the system and **survive reboot** with no work from us. |

Both are then re-validated by `reconcile()` on next launch, so a failed boot receiver (some OEM
skins are hostile) is recoverable rather than fatal. Note the Android boot path re-uses the schedule
mode that was persisted — another reason to re-reconcile at launch.

### 1.6 Notification channels (Android)

Create one channel per reminder type at first run so the shepherd can silence "tag-by" without
silencing "colostrum". Channel IDs must never change after release.

| Channel ID | Name | Importance |
|---|---|---|
| `colostrum` | Colostrum window | `Importance.high` |
| `navel` | Navel dip | `Importance.defaultImportance` |
| `turnout` | Turn out from pen | `Importance.high` |
| `tag_by` | Tag-by date | `Importance.defaultImportance` |
| `dose` | Second dose due | `Importance.high` |
| `withdrawal` | Withdrawal period ends | `Importance.high` |

No custom sound (an unfamiliar sound at 3am is worse than the familiar one). No badge count — a badge
implies unread state the app doesn't model. Android 15 added a *notification cooldown* that quiets
rapid bursts; irrelevant here because reminders are minutes-to-days apart, but do not batch-fire six
reminders in one second on the reconcile path.

---

## 2. On-device speech recognition (spec 7.1 voice tag, 7.2 voice note)

### 2.1 The critical question, answered plainly

**Can speech recognition be *guaranteed* to run fully on-device with no network? Conditionally, on both
platforms — and the condition is a runtime capability check that `speech_to_text` does not expose to
Dart.**

The reason this is subtle: **recognition does not happen in our process.** On both platforms the audio
is handed to a system service which has its own network access. Removing `INTERNET` from our manifest
does *nothing* to stop that service from uploading audio. So the "no INTERNET permission" defence,
which is airtight for everything else in this app, is **useless here**. This is the single most
important finding in this section.

**Android.** The official
[`SpeechRecognizer` reference](https://developer.android.com/reference/android/speech/SpeechRecognizer)
states that "the implementation of this API is likely to stream audio to remote servers to perform
speech recognition." The offline path is:
- `SpeechRecognizer.isOnDeviceRecognitionAvailable(context)` — **API 31+**
- `SpeechRecognizer.createOnDeviceSpeechRecognizer(context)` — **API 31+**
- `RecognizerIntent.EXTRA_PREFER_OFFLINE` — a *preference*, not a guarantee

On-device recognition is provided by Speech Services by Google / Android System Intelligence, and the
per-language model **must already have been downloaded** (usually via Settings → System → Languages →
Voice input → offline speech recognition, or automatically on Pixel/Samsung flagships). On a phone
where it hasn't been, `isOnDeviceRecognitionAvailable` returns false.

**iOS.** `SFSpeechRecognitionRequest.requiresOnDeviceRecognition` is documented (headers mirrored at
[docs.rs/objc2-speech](https://docs.rs/objc2-speech/latest/objc2_speech/struct.SFSpeechRecognitionRequest.html))
as *"A Boolean value that determines whether a request must keep its audio data on the device"*, with
the decisive caveat: **"The request only honors this setting if the `SFSpeechRecognizer.supportsOnDeviceRecognition`
property is also `true`."**
[`supportsOnDeviceRecognition`](https://docs.rs/objc2-speech/latest/objc2_speech/struct.SFSpeechRecognizer.html)
is *"A Boolean value that indicates whether the speech recognizer can operate without network access."*
When it is false, SFSpeechRecognizer sends audio to Apple's servers. It is false unless the dictation
language model for that locale is installed on the device.

So: **check the capability, and if it's absent, do not offer the feature.** Never "try on-device and
fall back."

### 2.2 What `speech_to_text` actually does

[`speech_to_text` **7.4.0**](https://pub.dev/packages/speech_to_text), publisher `csdcorp.com`
(verified), BSD-3, active. `SpeechListenOptions` (added in 6.6.0) carries `onDevice` (default
**`false`**), `partialResults`, `listenMode`, `localeId`, `pauseFor`, `listenFor`, `autoPunctuation`,
`enableHapticFeedback`, `sampleRate`, `cancelOnError`.

The Android implementation, verified in
[`SpeechToTextPlugin.kt` on `main`](https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/android/src/main/kotlin/com/csdcorp/speech_to_text/SpeechToTextPlugin.kt):

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && onDevice) { ... }
supportsLocal = SpeechRecognizer.isOnDeviceRecognitionAvailable(pluginContext!!)
// createOnDeviceSpeechRecognizer(pluginContext!!) when supported
putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, onDevice)
```

**Three problems for this app:**

1. **It falls back silently.** When `onDevice: true` but on-device is unavailable, it constructs the
   ordinary `SpeechRecognizer` — i.e. the network one. There is no error, no flag, nothing surfaced
   to Dart. The
   [`SpeechToText` class API](https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechToText-class.html)
   exposes `isAvailable`, `hasPermission`, `locales()`, `systemLocale()` — and **no member reporting
   whether on-device recognition is available**. We cannot gate the button on what we need to gate it on.
2. **The README tells you to add `INTERNET`.** Verified in
   [the README on `main`](https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/README.md):
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.BLUETOOTH"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   ```
   with the note that `INTERNET` is required "because speech recognition may use remote services."
   **Good news:** the plugin's own
   [`AndroidManifest.xml`](https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/android/src/main/AndroidManifest.xml)
   is **empty** — it merges nothing. Those lines are README instructions we can simply not follow. But
   note again (§2.1) that omitting `INTERNET` does not stop the recognizer's own process.
3. **API 30+ needs a `<queries>` element** to see the recognition service at all:
   ```xml
   <queries>
     <intent><action android:name="android.speech.RecognitionService" /></intent>
   </queries>
   ```

iOS/macOS Info.plist keys: `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription`.

### 2.3 iOS 26 has a better answer, and we're building on Xcode 26.6

`SpeechAnalyzer` / `SpeechTranscriber` shipped in **iOS 26**
([WWDC25 session 277](https://developer.apple.com/videos/play/wwdc2025/277/)). It is fully on-device,
the model *"is retained in system storage and does not increase the download or storage size of your
application... It operates outside of your application's memory space,"* models are installed via
`AssetInventory.assetInstallationRequest(supporting:)`, and — unlike `SFSpeechRecognizer` — it does
**not** require the user to have enabled Siri or keyboard dictation for the locale.

`speech_to_text` does not use it (7.4.0's iOS changes are `SFSpeechRecognizer`-based). Adopting it
would mean a bespoke Swift platform channel, iOS 26 minimum, and no Android counterpart.

### 2.4 Verdict

**Voice tag entry (7.1): do not ship in v1.**

The honest reasons, in order:

1. We cannot mechanically prove it stays offline on a given handset, and the plugin's silent
   network fallback is exactly the failure mode our positioning cannot survive. One shepherd running
   a packet capture and finding audio going to Google is a 1-star review that reads
   *"they lied about offline."*
2. It is not even a UX win. The tag is 2–4 digits. A 40 pt keypad with a recents strip resolves it in
   under two seconds. A lambing shed at 3am is ~70 dB of ewes and a running fan; ASR word error rates
   on digit strings in that environment are poor, and a misheard `412` → `4:12` produces a *wrong
   record*, which is the exact failure the app exists to eliminate (spec §2).
3. Spec 7.1 already says OCR/voice are "always a shortcut, never the only route." Cutting a shortcut
   costs nothing structural.

**If it ships in v1.1**, the gate is non-negotiable:

```dart
// Requires a ~30-line platform channel; speech_to_text does not expose this.
// iOS:     SFSpeechRecognizer(locale:)?.supportsOnDeviceRecognition == true
// Android: Build.VERSION.SDK_INT >= 31 && SpeechRecognizer.isOnDeviceRecognitionAvailable(ctx)
final offlineCapable = await OnDeviceSpeech.isGuaranteedOffline(localeId);
if (!offlineCapable) return null;   // hide the mic button entirely. No fallback. No toast.

await speech.listen(
  onResult: _onResult,
  listenOptions: SpeechListenOptions(
    onDevice: true,            // defaults to false — you MUST set it
    partialResults: true,
    listenMode: ListenMode.search,
    localeId: localeId,
  ),
);
```

Plus a settings row: *"Voice entry — unavailable on this phone. Requires offline speech recognition,
which your phone hasn't downloaded."* Never a "download it now" button; that's a network path.

**Voice notes (7.2): ship this instead, in v1.** See §4. Recording audio is a strictly safer, strictly
more offline, and — for a shepherd with iodine on both hands describing a malpresentation — strictly
more useful feature than dictating a 3-digit tag. It is the right half of the spec's voice ambition.

---

## 3. Tag OCR from the camera (spec 7.1)

### 3.1 ML Kit: bundled vs unbundled, and why "bundled" is not what it sounds like

From [Google's ML Kit text-recognition v2 Android docs](https://developers.google.com/ml-kit/vision/text-recognition/v2/android):

| | Unbundled (`com.google.android.gms:play-services-mlkit-text-recognition`) | Bundled (`com.google.mlkit:text-recognition`) |
|---|---|---|
| Size | **~260 KB** per script per architecture | **~4 MB** per script per architecture |
| Model | "dynamically downloaded via Google Play Services"; "might have to wait for model to download before first use" | "statically linked to your app at build time"; "available immediately" |

[`google_mlkit_text_recognition` **0.16.0**](https://pub.dev/packages/google_mlkit_text_recognition)
(publisher `flutter-ml.dev`, verified, MIT, ~19 days before 2026-07-27) uses the **bundled** artifact —
verified in
[its `android/build.gradle`](https://raw.githubusercontent.com/flutter-ml/google_ml_kit_flutter/master/packages/google_mlkit_text_recognition/android/build.gradle):

```gradle
dependencies {
    implementation("com.google.mlkit:text-recognition:16.0.1")
    compileOnly("com.google.mlkit:text-recognition-chinese:16.0.1")
    compileOnly("com.google.mlkit:text-recognition-devanagari:16.0.1")
    compileOnly("com.google.mlkit:text-recognition-japanese:16.0.1")
    compileOnly("com.google.mlkit:text-recognition-korean:16.0.1")
}
```

That looks fine. It isn't. Reading the **actual POM** at
`https://dl.google.com/dl/android/maven2/com/google/mlkit/text-recognition/16.0.1/text-recognition-16.0.1.pom`:

```
com.google.android.gms:play-services-base:18.5.0                     (compile)
com.google.android.gms:play-services-basement:18.4.0                 (compile)
com.google.android.gms:play-services-mlkit-text-recognition:19.0.1   (compile)
com.google.mlkit:common:18.11.0                                      (compile)
com.google.mlkit:text-recognition-bundled-common:17.0.0              (compile)
```

The "bundled" artifact **transitively depends on the Play Services artifact and on
`play-services-base` / `play-services-basement`**, which are the libraries that contribute
`android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` to a merged manifest. Add
this plugin and our seven-permission manifest silently becomes a nine-permission manifest with
`INTERNET` in it. The whole positioning collapses at that line.

### 3.2 ML Kit phones home, by Google's own terms

From [Google's ML Kit Terms of Service](https://developers.google.com/ml-kit/terms):

> "processing of the input data (e.g. images, video, text) fully happens on-device, and ML Kit does not
> send that data"
>
> "**The ML Kit APIs also send metrics about the performance and utilization of the APIs in your app to
> Google.**"
>
> "You are responsible for informing users of your app about Google's processing of ML Kit metrics data
> as required by applicable law."

Corroborated in the wild:
[mobile_scanner #553](https://github.com/juliansteenbakker/mobile_scanner/issues/553) and
[google_ml_kit_flutter #198](https://github.com/flutter-ml/google_ml_kit_flutter/issues/198) both
report periodic POSTs to `firebaselogging.googleapis.com/v0cc/log/batch?format=json_proto3`, roughly
every 15 minutes. Neither issue has a maintainer-endorsed way to disable it; the community workaround is
Firebase manifest meta-data flags (`firebase_analytics_collection_deactivated`,
`firebase_performance_collection_deactivated`), which are not documented as covering ML Kit's own
logger.

The images stay on-device — I believe Google on that. But an app whose entire pitch is "no network path"
cannot ship a dependency that beacons to Google every 15 minutes, and cannot ship an App Store privacy
label of "Data Not Collected" while it does.

### 3.3 iOS side: 38 MB

From [Google's ML Kit iOS docs](https://developers.google.com/ml-kit/vision/text-recognition/v2/ios):
"**About 38 MB per script SDK**", assets "statically linked to your app at build time." Pods:
`GoogleMLKit/TextRecognition` (+ per-script variants). Minimum iOS 15.5.

Spec §11: *"Total app payload well under 20 MB, dominated by fonts and icons."* One OCR shortcut would
make the iOS binary roughly **three times the entire budgeted app**. For a feature the spec itself
labels optional.

### 3.4 Apple Vision, the honest comparison

`VNRecognizeTextRequest` (iOS 13+) / `RecognizeTextRequest` (iOS 18+) is part of the OS. Zero binary
cost, zero download, `.accurate` and `.fast` recognition levels, `recognitionLanguages` in priority
order, and it is documented and universally understood to run entirely on-device with no network
([supportedRecognitionLanguages(for:revision:)](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/supportedrecognitionlanguages(for:revision:)),
[VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest?language=objc)).
A platform channel over it is maybe 60 lines of Swift.

**But Android has no equivalent in the platform.** There is no AOSP text recogniser. The options are
ML Kit (rejected above) or Tesseract via `flutter_tesseract_ocr` (a ~10 MB trained-data blob, poor
accuracy on the low-contrast, curved, mud-caked, sometimes handwritten plastic tags that this feature
actually has to read).

### 3.5 Verdict: cut OCR from v1

| Option | Size | Network | Ships on |
|---|---|---|---|
| ML Kit both platforms | +4 MB Android, **+38 MB iOS** | **INTERNET merged + 15-min telemetry** | both |
| Vision on iOS only | ~0 | none | iOS only |
| Tesseract on Android | ~+12 MB | none | Android, badly |
| **Cut it** | 0 | none | — |

**Cut it.** Reasons, ranked:

1. ML Kit is disqualified on offline purity alone (§3.1, §3.2). That is not a close call.
2. iOS-only Vision means the two builds are different products. For a €10–15 one-time purchase with a
   single developer, a divergent feature set is a support burden and a review-score liability
   ("the Android version is missing features").
3. The feature has a bad hit rate on the real input. Sheep ear tags at 3am under a head torch are
   curved, retro-reflective, often over-printed with a flock number in a different size, and frequently
   smeared. OCR that returns the flock prefix instead of the animal number, or `8` for `B`, produces a
   *wrong record silently attached to the wrong ewe*. That is worse than no feature — it is the exact
   failure mode spec §2 is written against.
4. Spec 7.1 already ranks it last: "Always a shortcut, never the only route." The budget it frees goes
   into the giant keypad, the recents strip, and partial matching — which the spec calls "the hardest
   UX problem in the app."

**Revisit in v1.1 as iOS-only Vision** *only if* forum feedback asks for it, and ship it behind a
clearly-labelled "iPhone only (uses Apple's built-in text reader)" note. Do not add ML Kit to reach
parity; add nothing.

---

## 4. Camera and photo attachment (spec 7.2)

### 4.1 `image_picker`, not `camera`

[`image_picker` **1.2.3**](https://pub.dev/packages/image_picker), publisher `flutter.dev` (verified),
Android SDK 24+, iOS 13+.

**It merges zero permissions.** Verified in
[`image_picker_android/android/src/main/AndroidManifest.xml`](https://raw.githubusercontent.com/flutter/packages/main/packages/image_picker/image_picker_android/android/src/main/AndroidManifest.xml):
one `FileProvider` (`${applicationId}.flutter.image_provider`), one disabled
`com.google.android.gms.metadata.ModuleDependencies` service that signals Play Services to install the
photo-picker module, and no `uses-permission` at all. On Android 13+ it uses the
[system photo picker](https://developer.android.com/training/data-storage/shared/photopicker), which
grants per-URI access and **requires no runtime storage permission** — not `READ_MEDIA_IMAGES`, not
`READ_MEDIA_VISUAL_USER_SELECTED`. That is a meaningful win: the app never asks for gallery access.

> Note the ModuleDependencies service: on older devices Play Services may fetch the photo-picker
> backport. That is a Play Services action in a Play Services process, not ours. Document it under
> tier-3 honesty (§0); it does not put `INTERNET` in our manifest.

iOS Info.plist keys required by the plugin:

```xml
<key>NSCameraUsageDescription</key>
<string>Shed Book uses the camera so you can attach a photo to a lambing record.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Shed Book lets you attach a photo you have already taken to a lambing record.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Shed Book records voice notes you attach to a lambing record.</string>
```

`NSMicrophoneUsageDescription` is needed anyway for `record` (§5). `image_picker` documents that the
mic permission "will not be requested if you always pass `false` for `requestFullMetadata`" but the
plist entry is still required by App Store policy.

**Why not [`camera` 0.12.0+2](https://pub.dev/packages/camera)** (also flutter.dev, also fine): it gives
a live preview surface we would then have to build a shutter UI around, it merges `CAMERA` +
`RECORD_AUDIO`, and it makes us own lifecycle/orientation/torch handling. Spec 7.2 asks for a photo
attachment, not a camera product. `ImagePicker().pickImage(source: ImageSource.camera)` hands off to
the system camera, which the user already knows how to operate one-handed with a glove on, and which
has a torch button we don't have to build. **Ship `image_picker`.** (If we later want in-app tag OCR
we'd need `camera` — but we cut OCR, §3.5.)

**iOS limited photo library:** since iOS 14, `PHPickerViewController` (which `image_picker` uses) needs
no library authorisation at all — the user picks in an out-of-process UI and we receive only that
asset. So "Limited Photos Access" never applies to us and there is no "manage selection" flow to build.
On the *camera* path we do get a real `NSCameraUsageDescription` prompt; that is one prompt, at the
moment of first use, which the 3am rules tolerate.

### 4.2 Downscale, strip EXIF, and the 400-ewe storage question

[`flutter_image_compress` **2.5.1**](https://pub.dev/packages/flutter_image_compress), publisher
`fluttercandies.com` (verified), MIT, native Kotlin/ObjC encoders (the README is explicit that pure-Dart
image libraries "are too slow for typical compression workloads" — true; `package:image` JPEG encode of
a 12 MP frame is seconds on a mid-range Android). **`keepExif` defaults to `false`**, i.e. metadata is
stripped by default, with the `Orientation` tag normalised so the image doesn't double-rotate.

That default is exactly what we want, and it matters: an untouched iPhone photo carries GPS
coordinates. Spec §4.5 says losses and treatment records are commercially sensitive; a CSV export
carrying a photo with the farm's exact coordinates is a leak the shepherd didn't consent to.

```dart
Future<File> storeLambingPhoto(XFile picked, String lambingId) async {
  final dir = await getApplicationDocumentsDirectory();       // iOS: visible in Files app
  final media = Directory(p.join(dir.path, 'media'))..createSync(recursive: true);
  final out = p.join(media.path, '$lambingId-${const Uuid().v4()}.jpg');

  final result = await FlutterImageCompress.compressAndGetFile(
    picked.path,
    out,
    format: CompressFormat.jpeg,
    quality: 80,
    minWidth: 1600,      // aspect-preserving UPPER bounds; never upscales
    minHeight: 1600,
    keepExif: false,     // explicit even though it is the default
  );
  if (result == null) throw StorageException('compress failed');
  return File(result.path);
}
```

**Storage growth over a 400-ewe season:**

| Strategy | Per photo | 400 photos | 1200 photos (lambs too) |
|---|---|---|---|
| Untouched 12 MP HEIC/JPEG | 2.0–3.5 MB | **~1.0 GB** | ~3.0 GB |
| 1600 px long edge, JPEG q=80 | 250–400 KB | **~130 MB** | ~390 MB |
| 1280 px long edge, JPEG q=75 | 150–250 KB | ~80 MB | ~240 MB |

1600 px / q=80 is the right pick: a lamb's ear tag and a prolapse are both still legible, and a season
fits inside what a phone with 20 GB free will never notice. Show the media-folder size on the Settings
screen with a "Delete photos from season 2025" action — the spec already has "delete a season."

**Do not put photos in SQLite.** Media folder + relative path in the row (spec §10 says exactly this).
BLOBs bloat the DB file, break incremental vacuum, and make the JSON backup unusable.

**iOS storage location:** `getApplicationDocumentsDirectory()` is user-visible in the Files app on iOS.
For a "your data is yours" app that is a *feature* — set `UIFileSharingEnabled` and
`LSSupportsOpeningDocumentsInPlace` to `true` in Info.plist so a shepherd can pull the media folder off
via a cable with no export step. It also means the media folder is included in an iTunes/Finder
encrypted backup, which is a genuine second safety net the spec doesn't currently claim.

---

## 5. Audio recording — voice notes (spec 7.2)

[`record` **7.1.1**](https://pub.dev/packages/record), publisher `cow-level.ovh` (verified), BSD-3,
Android/iOS/macOS/Windows/Linux/Web. **7.0.0 raised the floor to Flutter 3.44 / Dart 3.12** — exactly
our toolchain, which is a good sign the package is being maintained against current Flutter rather than
lagging it. 7.0.0 also removed the Android background-recording service (we don't want it) and moved to
AGP 9.x.

**Android manifest merged**, verified in
[`record_android/android/src/main/AndroidManifest.xml`](https://raw.githubusercontent.com/llfbandit/record/master/record_android/android/src/main/AndroidManifest.xml):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

One permission. No `FOREGROUND_SERVICE`, no `MODIFY_AUDIO_SETTINGS`, no provider, no receiver. iOS:
`NSMicrophoneUsageDescription` only. **No network dependency anywhere.**

**Codec choice — pick `aacLc` / `.m4a`, and here is why it isn't Opus.** From
[`AudioEncoder`](https://pub.dev/documentation/record/latest/record/AudioEncoder.html), `opus` is
containered as **OGG on Android** and **CAF on iOS**. Those files are not interchangeable, which would
break a JSON/ZIP backup restored from an Android phone onto an iPhone — and cross-device restore is the
entire point of spec 7.9. `aacLc` produces MPEG-4 `.m4a` on both platforms, playable by both, and is
what the OS voice-memo apps use.

```dart
final rec = AudioRecorder();                       // NOT `Record` — renamed in 5.0.0
if (!await rec.hasPermission()) return;            // record asks for RECORD_AUDIO itself
await rec.start(
  const RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 48000,          // mono speech; 32k is intelligible, 64k is wasteful
    sampleRate: 22050,
    numChannels: 1,
  ),
  path: p.join(mediaDir.path, '$lambingId-note.m4a'),
);
```

**File size:** 48 kbps mono ≈ **6 KB/s** ≈ 360 KB/minute. Cap notes at **60 seconds** with a visible
countdown ring — a 3am note is "big single, ewe wouldn't take her, tubed 200 ml." A season of 400 notes
at 30 s each is **~72 MB**. Acceptable next to the photo budget.

**3am design notes:** press-and-hold-to-record fails the spec ("no long-press-only actions"). Use a
60×60 pt tap-to-start / tap-to-stop toggle with an unmissable red state and a waveform level meter fed
from `rec.onAmplitudeChanged()` — the shepherd needs to know at a glance that it is actually recording,
because they cannot see a tiny icon through a freezer bag. **Commit the file path to SQLite the moment
recording starts**, not when it stops, so a mid-note phone death leaves a truncated but *linked* file
rather than an orphan.

---

## 6. Export and share (spec 7.9)

### 6.1 CSV — hand-roll it

[`csv` **8.0.0**](https://pub.dev/packages/csv) is a **rewrite by an unverified uploader**: `CsvCodec`
renamed to `Csv`, no longer extends `dart:convert`'s `Codec`, `CsvDecoder`/`CsvEncoder` changed from
`Converter` to `StreamTransformerBase`, and the classic `ListToCsvConverter` replaced. It is a decent
package, but for an app whose pitch is "it cannot break," taking an unverified-publisher dependency
with a fresh breaking rewrite — to do something that is 50 lines of extremely well-specified
behaviour — is the wrong trade.

**Write the RFC 4180 encoder.** The rules are short and the test cases are obvious:

```dart
/// RFC 4180 writer. https://www.rfc-editor.org/rfc/rfc4180
class CsvWriter {
  CsvWriter({this.delimiter = ',', this.bom = true});
  final String delimiter;
  final bool bom;

  static final _needsQuote = RegExp(r'[",\r\n;\t]');
  /// Excel/Sheets evaluate a leading = + - @ as a formula. See §6.1 note.
  static final _formulaLead = RegExp(r'^[=+\-@\t\r]');

  String _field(Object? v) {
    if (v == null) return '';
    var s = v is DateTime
        ? v.toUtc().toIso8601String()
        : v is double ? v.toStringAsFixed(2)   // ALWAYS '.' decimal, never locale
        : v.toString();
    if (_formulaLead.hasMatch(s)) s = "'$s";           // documented, export-only
    if (!_needsQuote.hasMatch(s) && s.trim() == s) return s;
    return '"${s.replaceAll('"', '""')}"';             // RFC 4180 §2.7
  }

  /// Returns bytes, not a String, because the BOM is a byte-level concern.
  Uint8List encode(List<String> header, Iterable<List<Object?>> rows) {
    final b = BytesBuilder();
    if (bom) b.add([0xEF, 0xBB, 0xBF]);                 // UTF-8 BOM for Excel
    void line(List<Object?> r) =>
        b.add(utf8.encode('${r.map(_field).join(delimiter)}\r\n'));  // CRLF per RFC 4180 §2.1
    line(header);
    for (final r in rows) line(r);
    return b.takeBytes();
  }
}
```

Decisions baked in above, each with a reason:

- **UTF-8 BOM on.** Excel on Windows mis-decodes BOM-less UTF-8 as the ANSI code page, which mangles
  every `°`, `£`, `é` and every Welsh/Irish name in the flock. Numbers and Sheets both cope with the BOM.
- **CRLF line endings.** RFC 4180 §2.1. Every parser accepts them; some Excel versions still prefer them.
- **Quote on `,`, `"`, CR, LF** — and also on `;` and TAB so the same bytes survive a semicolon-delimited
  reopen — plus any field with leading/trailing whitespace.
- **Escape `"` as `""`.** Not backslash. This is the single most common hand-rolled CSV bug.
- **Comma delimiter by default, semicolon behind a Settings toggle** labelled *"Semicolon separator
  (some European versions of Excel)"*. Do **not** emit Excel's `sep=;` sniffing line — it is
  Microsoft-proprietary and breaks strict RFC 4180 parsers, including the one we need for round-tripping.
- **Numbers always with a `.` decimal separator**, regardless of device locale, because CSV is a data
  interchange format, not a display format. A `2,5` birthweight in a comma-delimited file is a
  column-shift bug.
- **Formula-injection guard.** A note that begins `-2 lambs` or `=needs vet` becomes an executable
  formula when opened in Excel or Google Sheets. Prefixing with `'` neutralises it (Excel consumes the
  apostrophe as a text marker; a plain-text viewer shows it). **This is a deliberate, documented
  transformation of the *export*, not of the record** — spec §12.4 forbids silently correcting a user's
  entry, and we don't: SQLite and the JSON backup keep the exact bytes the shepherd typed. Say so in the
  export footer.

Three shapes, per spec 7.9: `lambs.csv` (one row per lamb), `ewes.csv` (one row per ewe), and
`treatments.csv` (one row per treatment). Every file gets a trailing comment row:

```
"Shed Book export. Not a statutory medicine book or holding register.",,,
"Withdrawal periods are as entered by the user from the product label.",,,
```

That is spec §12.1 and §12.3 discharged in the artifact that leaves the device.

### 6.2 PDF — `pdf` yes, `printing` no

[`pdf` **3.13.0**](https://pub.dev/packages/pdf), publisher `nfet.net` (verified), Apache-2.0, 3.03k
likes, 160 pub points, Dart SDK ≥ 3.12 as of 3.13.0. Dependencies: `archive`, `barcode`, `bidi`,
`crypto`, `image`, `meta`, `path_parsing`, `vector_math`, `xml`. **No HTTP client.**

[`printing` **5.15.0**](https://pub.dev/packages/printing), same publisher — its dependency list
includes **`http (>=0.13.0 <2.0.0)`**. It is there for `PdfGoogleFonts` (downloads font binaries from
Google's servers) and `networkImage()`. Its Android manifest is clean (verified: only a
`PrintFileProvider`, no permissions), so it wouldn't *merge* `INTERNET` — but it puts a live HTTP client
in the app's Dart graph and gives every future contributor a one-liner (`PdfGoogleFonts.robotoRegular()`)
that quietly turns the app into a networked app on iOS, where there is no permission gate to stop it.

**Reject `printing`.** Spec 7.9 says delivery is "via the system share sheet." `pdf` builds the bytes;
`share_plus` hands them to the OS; the iOS share sheet has a Print action, and on Android every PDF
viewer has one. We lose an in-app print button and gain a provably network-free dependency graph. For
this app that is the right side of the trade.

If someone later insists on the in-app print dialog, the price of admission is a CI gate that fails on
any occurrence of `PdfGoogleFonts` or `networkImage` in `lib/` (§11.4).

#### Fonts: you must embed a TTF

The PDF base-14 fonts (`Font.helvetica()` etc.) are Latin-1/WinAnsi only. The `dart_pdf`
[Fonts Management wiki](https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management) says they are fine
"if you plan to only use US or West-European characters, but as soon as you need specific accents or
Asian characters, you have to switch to a Unicode font," and the tracker is full of the resulting
crash — e.g. [#810](https://github.com/DavBfr/dart_pdf/issues/810),
[#252](https://github.com/DavBfr/dart_pdf/issues/252),
[#405](https://github.com/DavBfr/dart_pdf/issues/405) — *"Helvetica has no Unicode support"* /
*"Can not decode the string to Latin1."*

`°` (U+00B0) and `£` (U+00A3) happen to be inside Latin-1, so those two specifically survive. What does
**not**: the curly quotes and en-dashes an iOS keyboard inserts automatically (`'`, `"`, `–`), the
ellipsis `…`, `℃` (U+2103) if anyone types it, Welsh `ŵ`/`ŷ`, and any emoji — and a shepherd typing a
free-text note at 3am on a phone keyboard will produce all of those. A crash while exporting the
medicine book for a vet visit is a catastrophic failure of the one safety feature the app has.

**Always embed a TTF. Never use a base-14 font anywhere in this app.**

```dart
final theme = pw.ThemeData.withFont(
  base: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
  bold: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
);
final doc = pw.Document(theme: theme, title: 'Shed Book — Season 2026');
```

Two weights of an OFL family (Noto Sans / Source Sans 3 / Inter) is roughly 300–700 KB of assets, which
the spec already anticipates ("payload dominated by fonts and icons"). **Verify by measurement whether
`pdf` subsets the embedded font** — if it embeds the whole face, each generated PDF carries the full
font and a medicine-book PDF jumps by ~400 KB. Acceptable either way, but know the number before you
promise a printable flock book by email.

#### Memory: a season-long flock book

`pw.Document.save()` returns a `Uint8List` — the whole document is materialised in memory, and
`pw.MultiPage` builds its widget tree before paginating. A 400-ewe / ~900-lamb season book is roughly
60–120 pages of text-only tables: the output PDF is a few MB, but peak Dart heap during layout is
plausibly 100–200 MB. On a €150 Android phone in a cold shed with the camera app also resident, that is
an OOM kill — and an OOM kill during "export my season" is precisely the moment the user is trying to
protect their data.

Mitigations, all cheap:

1. **Never embed photos in the season PDF.** Text and tables only. Offer photos as a separate
   media export.
2. **Build the PDF on a background isolate** with `compute()`. `pdf` is pure Dart so it isolates
   cleanly. Load the font bytes and query the DB on the main isolate, pass plain data + `Uint8List`
   font bytes in.
3. **Write straight to a temp file** with `File.writeAsBytes(await doc.save())` and hand the *path* to
   `share_plus`. Never hold both the byte list and an `XFile.fromData` copy.
4. **Split by section** if it still struggles: `flock-book-ewes.pdf`, `flock-book-lambs.pdf`,
   `medicine-book.pdf`. The medicine record for a vet or an inspection is a separate document anyway
   (spec 7.9) and is usually only tens of rows.
5. Put a hard row cap with an honest message rather than a crash: *"This season is too large for a
   single PDF. Exporting as three files."*

### 6.3 JSON backup format

Design goals: human-inspectable, restorable onto a different platform, all-or-nothing, and it must not
OOM.

```jsonc
{
  "format": "shed-book-backup",
  "schema": 1,                       // integer; refuse to import schema > known
  "appVersion": "1.0.0+12",
  "exportedAtUtc": "2026-07-27T21:04:11.482Z",
  "deviceTimeZone": "Europe/Dublin",  // context only; all instants below are UTC
  "counts": { "ewe": 412, "lambing": 398, "lamb": 861, "treatment": 145 },
  "tables": {
    "season":    [ /* rows as flat objects, column names == SQLite column names */ ],
    "ewe":       [],
    "lambing":   [],
    "lamb":      [],
    "pen":       [],
    "treatment": [],
    "reminder":  [],
    "note":      [],
    "settings":  {}
  },
  "media": [
    { "path": "media/9f3c-....jpg", "bytes": 284113, "sha256": "…" }
  ]
}
```

Rules:

- **All timestamps are UTC ISO-8601 with `Z`.** Store the tz name separately for context only.
  This is what makes the backup portable and DST-proof (§1.5).
- **Preserve the timestamp provenance flags** (spec §12.5 — auto-captured vs edited). If the backup
  drops that column, a restore launders an edited timestamp into an auto one.
- **Do not base64 media inline.** 130 MB of photos becomes ~175 MB of base64 inside a JSON string, and
  `jsonEncode` will build the whole thing in memory. Instead, produce a **ZIP** containing
  `backup.json` + `media/`.
  [`archive` **4.0.9**](https://pub.dev/packages/archive) (publisher `loki3d.com`, verified; deps
  `path` + `posix`, no network) does this; use its file-stream API (`InputFileStream`/`OutputFileStream`)
  rather than building an in-memory `Archive`, and verify against the current API before writing code —
  the README documents streaming clearly on the *decode* side and I did not verify a streaming encoder.
  If streaming encode turns out to be awkward, ship **JSON-only** as the primary restore path (it is
  small — 400 ewes of text is low single-digit MB) and offer media as a separate share.
- **Integrity:** include `sha256` per media file and a `sha256` of the canonicalised `tables` object.
  Verify on import; refuse a corrupt archive rather than half-importing.
- **Restore is atomic.** Import into a *new* SQLite file next to the live one, validate row counts and
  foreign keys, then swap file paths and reopen. Never merge into the live DB. Offer "Replace
  everything" only — a merge UI at 3am is a data-loss generator.
- **Forward compatibility:** unknown columns in a newer backup are preserved into a `_unknown` JSON
  column rather than dropped, so a downgrade doesn't silently destroy data.

### 6.4 Share sheet

[`share_plus` **13.3.0**](https://pub.dev/packages/share_plus), publisher `fluttercommunity.dev`
(verified), Flutter Favorite, 4.0k likes. Requires Flutter ≥ 3.38.1 / Dart ≥ 3.10, iOS ≥ 13, Java 17,
AGP ≥ 8.12.1.

**Manifest merged**, verified in
[`share_plus/android/src/main/AndroidManifest.xml`](https://raw.githubusercontent.com/fluttercommunity/plus_plugins/main/packages/share_plus/share_plus/android/src/main/AndroidManifest.xml):
a `ShareFileProvider` (`${applicationId}.flutter.share_provider`) and a `SharePlusPendingIntent`
receiver. **No `uses-permission`, no `queries`.** Clean.

Current API — the static `Share.share*` methods are **deprecated**:

```dart
await SharePlus.instance.share(
  ShareParams(
    files: [XFile(pdfPath), XFile(lambsCsvPath)],
    fileNameOverrides: ['ShedBook-2026-FlockBook.pdf', 'ShedBook-2026-lambs.csv'],
    subject: 'Shed Book export — season 2026',
    // REQUIRED on iPad or the popover has no anchor and the sheet misbehaves:
    sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
  ),
);
```

Two operational notes: pass a **file path**, not `XFile.fromData` (the latter writes a temp copy you
then have to clean up yourself with `path_provider`), and always set `sharePositionOrigin` — the README
is explicit that omitting it on iPad "may cause crashes or unresponsive UI."

`share_plus` is on
[Apple's third-party-SDK privacy-manifest list](https://developer.apple.com/support/third-party-SDK-requirements/),
as are `flutter_local_notifications`, `path_provider`, `image_picker_ios`, `file_picker`, `sqflite`,
`package_info_plus` and `wakelock` (the old, discontinued one). Current versions all ship the manifest;
this is a reason not to pin anything old.

`open_filex` 4.7.0 was considered for "open the PDF I just made" — **not needed**, last published ~16
months ago, and the share sheet already offers "Open in…". Skip it.

---

## 7. File import for restore: `file_selector`, not `file_picker`

| | [`file_selector` 1.1.0](https://pub.dev/packages/file_selector) | [`file_picker` 11.0.2](https://pub.dev/packages/file_picker) |
|---|---|---|
| Publisher | **flutter.dev** (verified) | miguelruivo.com (verified) |
| Last publish | ~8 months before 2026-07-27 | ~3 months before (12.0.0-beta.7 in prerelease) |
| Pub points / likes | 160 / 435 | 140 / 4.93k |
| Deps | federated platform impls only | `cross_file, dbus, ffi, flutter_plugin_android_lifecycle, path, plugin_platform_interface, web, win32` |
| Extra Android permissions | none | historically merged storage permissions; README documents none, wiki-only setup |
| Apple privacy-manifest list | not listed | **listed** (extra maintenance surface) |
| Features we don't need | — | cloud files, directory picking, save dialogs |

`file_selector`'s older publish date is not staleness — it is a `flutter.dev` federated plugin that is
feature-complete for `openFile`/`getSaveLocation`. `file_picker`'s 4.93k likes reflect its extra
features (cloud/iCloud/Drive picking) which, for an offline app, are actively *undesirable*: we do not
want the restore picker inviting the user into Google Drive.

```dart
const backupType = XTypeGroup(
  label: 'Shed Book backup',
  extensions: ['json', 'zip'],
  mimeTypes: ['application/json', 'application/zip'],          // Android
  uniformTypeIdentifiers: ['public.json', 'public.zip-archive'] // iOS
);
final file = await openFile(acceptedTypeGroups: [backupType]);
```

Android's `ACTION_OPEN_DOCUMENT` needs **no storage permission** and returns a `content://` URI the
plugin copies into our cache. iOS uses `UIDocumentPickerViewController`, also permission-free. macOS
would need `com.apple.security.files.user-selected.read-only` — irrelevant, we ship mobile only.

**One caveat to test on device:** Android extension filtering is by MIME type, and a `.zip` produced by
`archive` may be reported as `application/octet-stream` by some file providers. Include
`application/octet-stream` in the accepted types, or add a `*/*` "Show all files" escape hatch, and
validate the magic bytes ourselves after opening. Better to accept too much and reject clearly than to
grey out the user's own backup.

---

## 8. Keep-screen-awake

[`wakelock_plus` **1.7.0**](https://pub.dev/packages/wakelock_plus), publisher `fluttercommunity.dev`
(verified), BSD-3, 1.96M weekly downloads, published ~5 days before 2026-07-27. API:
`WakelockPlus.enable() / disable() / toggle(enable:) / enabled`. Android uses the `WAKE_LOCK` permission
internally (a **normal**, install-time permission — no runtime prompt, no privacy prompt in the store
listing); iOS sets `UIApplication.idleTimerDisabled`, which the system resets when the app backgrounds.
Deps include `package_info_plus`, `win32`, `dbus`, `web` — all noise on mobile, none of them network.

**Use the `_plus` fork, not `wakelock`.** The original is discontinued and is on Apple's
privacy-manifest list, i.e. it would fail App Store validation.

**Is it warranted? Yes — but scoped and opt-in.** The 3am case: the phone is in a freezer bag on a gate,
the shepherd has both hands inside a ewe, and the screen sleeps after 30 seconds. Coming back means
wet-glove Face ID failure → passcode with cold fingers → find the app again. That single interaction
blows the entire 15-second budget, and it is exactly the moment the entry gets deferred to 7am — the
failure the whole product exists to prevent.

The cost is battery, and a dead phone at 05:00 on night eleven is worse than a screen timeout.

```dart
// Settings: "Keep screen on during a lambing session" — default OFF.
// When ON, only these routes hold the lock: QuickEntry, LambingEntry, PenBoard.
class KeepAwake extends StatefulWidget { ... }

@override void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
}
@override void didChangeAppLifecycleState(AppLifecycleState s) {
  if (s != AppLifecycleState.resumed) WakelockPlus.disable();   // belt and braces
}
@override void dispose() {
  WakelockPlus.disable();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

Never app-wide. Never on the Season Summary or Settings screens. Always release on
`dispose()` **and** on any non-resumed lifecycle state, because a crash-and-restart that leaks a wakelock
drains the phone silently. Pair it with the app's dark theme and a reduced brightness on those screens —
a dark screen held awake costs far less on OLED than a white one.

---

## 9. Runtime permissions: ship no permission package

[`permission_handler` **12.0.3**](https://pub.dev/packages/permission_handler) (Baseflow, verified) is
the reflex answer and it is unnecessary here. Its
[`permission_handler_android` manifest](https://raw.githubusercontent.com/Baseflow/flutter-permission-handler/main/permission_handler_android/android/src/main/AndroidManifest.xml)
is empty — it merges nothing, which is good — but on iOS with CocoaPods it requires a `post_install`
macro dance (`PERMISSION_CAMERA=1`, `PERMISSION_MICROPHONE=0`, …) to strip the permission code you don't
use, and getting that wrong is an App Store rejection for undeclared API usage.

We need exactly four permission interactions, and every one has a first-party API:

| Permission | Who asks | When |
|---|---|---|
| `POST_NOTIFICATIONS` (Android 13+) / iOS notifications | `requestNotificationsPermission()` / `IOSFlutterLocalNotificationsPlugin.requestPermissions()` | First time the user creates a reminder — never at launch |
| `SCHEDULE_EXACT_ALARM` | `canScheduleExactNotifications()` → `requestExactAlarmsPermission()` | Once, on the same sheet |
| Camera | `image_picker` prompts natively | First photo attach |
| Microphone | `AudioRecorder.hasPermission()` prompts natively | First voice note |

Photo *library* access needs no permission at all on either platform (system pickers, §4.1). No location,
contacts, calendar, or Bluetooth. **Drop `permission_handler`.**

This is also the right 3am answer: spec §5 bans "notification permission nags mid-season." Deferring
every prompt to first genuine use means a shepherd who only ever taps "lambing → twin → save" is never
interrupted by a single system dialog.

---

## 10. The full dependency set

```yaml
# pubspec.yaml — platform integration only. Versions read off pub.dev 2026-07-27.
dependencies:
  flutter_local_notifications: ^22.2.0   # dexterx.dev
  timezone: ^0.11.1                      # labs.dart.dev  (import data/latest_10y.dart)
  flutter_timezone: ^5.1.0               # wolverinebeach.net
  image_picker: ^1.2.3                   # flutter.dev
  flutter_image_compress: ^2.5.1         # fluttercandies.com
  record: ^7.1.1                         # cow-level.ovh
  pdf: ^3.13.0                           # nfet.net
  share_plus: ^13.3.0                    # fluttercommunity.dev
  file_selector: ^1.1.0                  # flutter.dev
  path_provider: ^2.1.6                  # flutter.dev
  wakelock_plus: ^1.7.0                  # fluttercommunity.dev
  archive: ^4.0.9                        # loki3d.com  (backup ZIP; verify streaming encode)

# DELIBERATELY ABSENT — see §11.3 for the CI gate that enforces this:
#   printing            -> depends on http
#   google_mlkit_*      -> pulls play-services-base/basement; ML Kit sends metrics to Google
#   speech_to_text      -> v1.1 at the earliest, behind a hard on-device capability gate
#   camera              -> not needed; image_picker uses the system camera UI
#   file_picker         -> heavier deps; file_selector is first-party and permission-free
#   permission_handler  -> every prompt we need has a first-party API
#   csv                 -> ~50 lines of RFC 4180 instead
#   http, dio, connectivity_plus, any firebase_*, any *_web_socket
```

---

## 11. Proving it: the mechanical offline audit

Assertions are worthless. These are the checks, and they belong in CI.

### 11.1 Android — strip `INTERNET` at merge time

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">

  <!-- Shed Book is offline-only. If any dependency contributes these, remove them at merge time.
       The build then fails at runtime for that dependency instead of shipping a lie.
       Documented at https://developer.android.com/build/manage-manifests -->
  <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />

  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
  ...
```

This is a safety net, **not** the gate. Removal is silent, so on its own it would hide the fact that a
new dependency wanted the network. Which brings us to:

### 11.2 Android — read the merged manifest and the blame report

```bash
flutter build apk --release

# WHO contributed what (this is the file that names the offending library):
REPORT=android/app/build/outputs/logs/manifest-merger-release-report.txt
grep -n -i -E 'INTERNET|ACCESS_NETWORK_STATE' "$REPORT" || echo "clean: nothing requested network"

# WHAT actually shipped:
apkanalyzer manifest permissions build/app/outputs/flutter-apk/app-release.apk
# or, without Android Studio tooling:
aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

For the Play upload artifact (`.aab`, which `apkanalyzer` will not read):

```bash
bundletool dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab \
  | grep -i -E 'INTERNET|ACCESS_NETWORK_STATE' && exit 1
```

If a *new* dependency ever adds `INTERNET`, the merger report shows an ADDED-then-REMOVED entry naming
the library, and the reviewer gets a real decision rather than a silent regression.

### 11.3 Dart graph — no network client, transitively

```bash
dart pub deps --style=compact --json > /tmp/deps.json
python3 - <<'PY'
import json, sys
BANNED = {"http","http2","dio","web_socket_channel","grpc","googleapis","googleapis_auth",
          "socket_io_client","cronet_http","cupertino_http"}
BANNED_PREFIX = ("firebase_","cloud_firestore","google_mlkit_","google_sign_in","connectivity_plus")
d = json.load(open("/tmp/deps.json"))
names = {p["name"] for p in d["packages"] if p.get("kind") in ("direct","dev","transitive")}
bad = sorted(n for n in names if n in BANNED or n.startswith(BANNED_PREFIX))
if bad:
    sys.exit("OFFLINE GATE FAILED — network-capable packages in the graph: " + ", ".join(bad))
print("offline gate: dart graph clean (%d packages)" % len(names))
PY
```

This is the check that catches `printing` → `http`. Run it on every PR.

### 11.4 Our own source

```bash
grep -rnE '\b(HttpClient|Socket\.connect|RawDatagramSocket|WebSocket|SecureSocket|InternetAddress\.lookup)\b' lib/ && exit 1
grep -rnE '\b(PdfGoogleFonts|networkImage)\b' lib/ && exit 1
```

### 11.5 iOS — there is no permission to remove, so prove it behaviourally

1. **App Privacy Report** (Settings → Privacy & Security → App Privacy Report) records every domain each
   app contacts. Run a full one-week internal season with it on; the expected result is that Shed Book
   never appears. This is cheap, decisive, and you can screenshot it for the store listing.
2. **Proxy the test plan.** Point a device at `mitmproxy`, run the whole 12-screen script including a
   full export, and assert zero flows from the app.
3. **Airplane mode is the acceptance test, not a bug report.** Every test session — manual and
   integration — runs in airplane mode. If a feature needs a network, it fails the suite by construction.
4. **Static smell check** on the built app, for embedded third-party frameworks only (the Flutter engine
   itself legitimately links CFNetwork, so this is a triage aid rather than a gate):
   ```bash
   for f in build/ios/Release-iphoneos/Runner.app/Frameworks/*.framework; do
     otool -L "$f/$(basename "$f" .framework)" | grep -q -E 'CFNetwork|/Network\.framework' \
       && echo "links networking: $f"
   done
   ```
5. **`PrivacyInfo.xcprivacy`** in `ios/Runner/`: `NSPrivacyTracking=false`, empty
   `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, plus required-reason declarations
   for File Timestamp (`C617.1`), User Defaults (`CA92.1`) and Disk Space (`E174.1`) as our plugins use
   them. Then the App Store privacy label is honestly **"Data Not Collected"** — which is a marketing
   asset, not just compliance.

### 11.6 One CI job

```yaml
# .github/workflows/offline-gate.yml (sketch)
- run: dart pub deps --style=compact --json > deps.json && python3 tool/check_no_network_deps.py
- run: bash tool/check_no_network_source.sh
- run: flutter build apk --release
- run: bash tool/check_apk_permissions.sh   # fails if INTERNET/ACCESS_NETWORK_STATE present
```

Green build = "no plugin merged INTERNET and no socket-capable package is in the graph." That is a
provable claim, and it is the one the product is sold on.

---

## 12. Rejected alternatives

| Rejected | In favour of | Why it lost |
|---|---|---|
| `google_mlkit_text_recognition` | **cutting OCR** | POM pulls `play-services-base` + `play-services-basement` (INTERNET/ACCESS_NETWORK_STATE contributors); +38 MB iOS vs a <20 MB payload budget; Google's own terms say ML Kit sends usage metrics; observed 15-minute POSTs to `firebaselogging.googleapis.com` |
| Apple Vision via platform channel, iOS-only | cutting OCR | Technically perfect (free, on-device, no download) but creates a divergent product for a solo developer on a one-time-purchase app. Revisit in v1.1 if users ask |
| `flutter_tesseract_ocr` | cutting OCR | ~12 MB traineddata; poor accuracy on curved, dirty, retro-reflective ear tags; a wrong tag is worse than no tag |
| `speech_to_text` shipping in v1 | shipping voice **notes** in v1 | Silently falls back to the network recognizer when on-device is unavailable, and exposes no Dart-visible way to detect that. Recognition runs in another process, so our missing INTERNET permission does not protect us |
| iOS `SpeechAnalyzer` / `SpeechTranscriber` (iOS 26) | — | Genuinely the right API (fully on-device, no Siri/dictation prerequisite, `AssetInventory` model management) but iOS-26-only, bespoke Swift, and no Android peer |
| `printing` | `pdf` + `share_plus` | Depends on `http`. Its `PdfGoogleFonts`/`networkImage` are a one-line footgun future-you will step on. Spec 7.9 delivers via the share sheet anyway |
| `pw.Font.helvetica()` (base-14) | embedded Noto Sans TTF | Latin-1 only; throws "Can not decode the string to Latin1" on curly quotes, en-dashes, `…`, Welsh `ŵ`, emoji — all of which a phone keyboard produces unprompted |
| `csv` 8.0.0 | ~50-line RFC 4180 writer | Unverified uploader + a fresh breaking rewrite, to replace well-specified behaviour we need precise control over (BOM, CRLF, formula-injection guard, locale-independent decimals) |
| `camera` | `image_picker` | Merges `CAMERA` + `RECORD_AUDIO`, forces us to own preview/lifecycle/orientation, and gives a worse one-gloved-thumb UX than the system camera |
| `file_picker` | `file_selector` | Heavier transitive deps (`dbus`, `win32`, `ffi`), on Apple's privacy-manifest list, history of merging storage permissions, and its cloud-picker features actively invite the user off-device |
| `permission_handler` | first-party per-plugin APIs | Every prompt we need is available directly; avoids the iOS CocoaPods `PERMISSION_*` macro dance and an entire class of "undeclared API" rejections |
| `USE_EXACT_ALARM` | `SCHEDULE_EXACT_ALARM` + inexact fallback | Play policy restricts it to alarm/timer/calendar apps; declaring it is a publishing block |
| `AndroidScheduleMode.alarmClock` | `exactAllowWhileIdle` / `inexactAllowWhileIdle` | Plants a system alarm-clock icon in the status bar; wrong signal for a withdrawal-period reminder |
| `matchDateTimeComponents` recurring notifications | one-shot rows in SQLite + `reconcile()` | Recurrence state lives in the OS, not in our DB, which contradicts "assume the phone dies"; also drifts across DST |
| Full-screen intents | high-importance channel | `USE_FULL_SCREEN_INTENT` restricted on Android 14+ to calling/alarm apps — the same trap as `USE_EXACT_ALARM` |
| `wakelock` | `wakelock_plus` | Discontinued; on Apple's privacy-manifest list, so it would fail App Store validation |
| `open_filex` | `share_plus` | Last published ~16 months ago; the share sheet already offers "Open in…" |
| Base64 media inside the JSON backup | ZIP with `backup.json` + `media/` | 130 MB of photos → ~175 MB of base64 built entirely in memory → OOM at exactly the wrong moment |
| Photos as SQLite BLOBs | media folder + relative path | Bloats the DB, breaks the backup design, and the spec (§10) already specifies a media folder |

---

## 13. Pitfalls

**Notifications**

1. *Scheduling on write and forgetting.* On iOS the 65th reminder produces undefined behaviour — reported
   as "nothing fires at all." → One idempotent `reconcile()` reading the DB, budget 56 (§1.4).
2. *Non-deterministic notification IDs.* `uuid.hashCode` collides and overflows int32.
   → Use the SQLite `INTEGER PRIMARY KEY` of the `Reminder` row.
3. *Assuming exact alarms are granted.* On Android 14+ they are denied by default for new installs.
   Calling an exact mode without the permission throws `ExactAlarmPermissionException` from
   `checkCanScheduleExactAlarms`. → Query `canScheduleExactNotifications()` on **every** reconcile and
   pick the mode from the answer.
4. *Shipping `USE_EXACT_ALARM` because a colostrum reminder feels urgent.* → Store rejection. Use
   `SCHEDULE_EXACT_ALARM`, and label inexact reminders as approximate in the UI.
5. *Forgetting `RECEIVE_BOOT_COMPLETED` + the boot receiver.* Android destroys alarms on reboot; a
   shepherd who reboots at 22:00 loses every overnight reminder silently. → Declare both, and let
   `reconcile()` at launch be the backstop.
6. *Storing `due_at` as local wall-clock.* DST moves it. → UTC instants in SQLite,
   `TZDateTime.from(utc, tz.local)` at schedule time.
7. *Defaulting a daily reminder to 02:30.* That time does not exist in CET on the spring-forward Sunday
   and occurs twice on the autumn one. → Default to 20:00 local.
8. *Firing the notification permission prompt during `initialize()` at launch.* Violates "zero
   interruptions." → `requestAlertPermission: false` etc., prompt on first reminder creation.
9. *One notification channel for everything.* The shepherd mutes "tag-by" spam and loses colostrum
   alerts with it. → Six channels (§1.6).

**Speech / OCR**

10. *Believing "no INTERNET permission" protects speech recognition.* It does not — recognition happens in
    Google's / Apple's process. → Gate on the on-device capability check, or don't ship the feature.
11. *Copying the `speech_to_text` README manifest block.* It adds `INTERNET`. → The plugin's own manifest
    is empty; add only `RECORD_AUDIO` and the `<queries>` element.
12. *Trusting "bundled" in an ML Kit artifact name.* `com.google.mlkit:text-recognition:16.0.1` depends
    on `play-services-mlkit-text-recognition` and `play-services-basement`. → Always read the POM.

**Media**

13. *Storing camera output untouched.* ~1 GB per 400-ewe season, plus GPS EXIF in every file.
    → 1600 px / q=80 / `keepExif: false`.
14. *Recording voice notes as Opus.* OGG on Android, CAF on iOS — a cross-platform restore breaks.
    → `aacLc` / `.m4a`.
15. *Committing the media path only when recording stops.* A phone death mid-note orphans the file.
    → Insert the row when recording starts.
16. *Press-and-hold to record.* Banned by spec §5. → Tap-to-start / tap-to-stop, 60×60 pt, loud red state.

**Export**

17. *Base-14 PDF fonts.* Throws on an iOS smart quote. → Always embed a TTF.
18. *Building a 400-ewe PDF on the UI isolate with photos embedded.* OOM at the exact moment the user is
    trying to protect their data. → `compute()`, text only, write straight to a file, split by section.
19. *CSV without a BOM.* Excel on Windows mangles `°`, `£` and every accented name. → Emit `EF BB BF`.
20. *Escaping `"` with a backslash.* RFC 4180 says `""`. → Test with a note containing `she "walked" off`.
21. *Locale-formatted numbers in CSV.* `2,5` in a comma-delimited file shifts every subsequent column.
    → `toStringAsFixed` with a `.` always.
22. *Unguarded leading `=`/`-` in a note.* Executes as a formula in Excel/Sheets. → Prefix `'` in the CSV
    only, document it, never touch the stored value.
23. *Partial restore.* → Import to a temp DB, validate, swap. All-or-nothing.
24. *Dropping the timestamp-provenance flag from the backup.* Restore launders an edited time into an
    auto-captured one, breaking spec §12.5. → Round-trip that column and test it.

**General**

25. *Adding a package without re-running the offline gate.* → §11.6 in CI, required check on `main`.
26. *Claiming "your data never leaves your phone."* It does, via the share sheet — which is the backup
    story. → Use the tier-1+2 wording in §0.
27. *Leaking a wakelock.* A crash-restart with the lock held drains the phone overnight.
    → Release on `dispose()` **and** on any non-resumed lifecycle state.

---

## 14. How this serves the 3am test and the offline-only constraint

- **Zero permission dialogs on the happy path.** A shepherd who only records lambings never sees a system
  prompt: the photo picker needs none, notifications are only requested when a reminder is first created,
  and there is no location/contacts/analytics anything (§9). That is "zero interruptions" (spec §5)
  implemented at the plugin layer rather than promised in a design doc.
- **The reconcile architecture means reminders survive the phone dying.** Every reminder is a committed
  SQLite row; the notification centre is a disposable cache rebuilt from it. Spec §5: "assume the phone
  dies. Every write is committed immediately." The notification layer now obeys the same rule.
- **Honest reminders.** Labelling inexact reminders as approximate is the same principle as spec §12.5
  (honest timestamps) and §12.1 (withdrawal periods "as entered by you"). The app never implies more
  precision than it has.
- **Cutting OCR and voice-tag entry buys the keypad.** Spec 7.1 calls animal selection "the hardest UX
  problem in the app" and gives it the most attention. Two shortcuts that don't work reliably in a
  70 dB shed under a head torch were competing for that attention, and one of them would have cost the
  offline claim outright.
- **No `INTERNET` permission is a user-visible fact.** On Android the Play listing shows the permission
  set; a shepherd who has been burned by farm SaaS can look and see there is no network permission. That
  is the wedge in spec §14 made checkable rather than claimed.
- **The export path is the backup path, so it must not crash.** Isolate-built, text-only, TTF-embedded
  PDFs and a hand-rolled CSV writer with a BOM exist because "a lost phone is lost data unless the user
  exports" (spec 7.9) makes the export the single highest-stakes code path in the app.
- **60×60 pt everywhere touches this layer too.** The record button, the share button and the photo
  button are all in this document's surface area, and all three must be tap-only, big, and reversible.

---

## 15. Open questions for the app owner

1. **Ziplock-bag operation** (spec §17.4) also determines whether `wakelock_plus` is a nice-to-have or
   mandatory. Needs one night with a real phone in a real bag.
2. **Is a printable PDF required to print *from inside the app*,** or is share-sheet → Print acceptable?
   Only the first justifies re-admitting `printing` (and its `http` dependency) behind a CI gate.
3. **Does the free tier cap reminders too?** 15 ewes fits inside the 56-slot iOS budget comfortably;
   400 does not. The cap interacts with the notification architecture.
4. **Voice notes: is a 60-second cap acceptable,** or do shepherds want to narrate a whole difficult
   lambing? The cap drives the storage budget.
5. **Region/locale for v1** (spec §17.3) decides the DST edge case that actually bites: UK/IE's
   ambiguous hour is 01:00–01:59; continental Europe's is 02:00–02:59.
6. **Should the JSON backup be a plain `.json` (small, inspectable, no photos)** or a `.zip` including
   media? The first is simpler and safer; the second is what "restore onto a new device" implies.

---

## 16. Sources

Every URL below was actually fetched on 2026-07-27.

**pub.dev package pages**
- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/flutter_local_notifications/changelog
- https://pub.dev/packages/flutter_local_notifications/versions
- https://pub.dev/packages/flutter_local_notifications/versions/22.2.0
- https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/AndroidScheduleMode.html
- https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/FlutterLocalNotificationsPlugin/zonedSchedule.html
- https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/AndroidFlutterLocalNotificationsPlugin-class.html
- https://pub.dev/packages/timezone
- https://pub.dev/packages/flutter_timezone
- https://pub.dev/packages/speech_to_text
- https://pub.dev/packages/speech_to_text/changelog
- https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechListenOptions-class.html
- https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechToText-class.html
- https://pub.dev/packages/google_mlkit_text_recognition
- https://pub.dev/packages/google_mlkit_commons
- https://pub.dev/packages/image_picker
- https://pub.dev/packages/camera
- https://pub.dev/packages/flutter_image_compress
- https://pub.dev/packages/record
- https://pub.dev/packages/record/changelog
- https://pub.dev/documentation/record/latest/record/AudioEncoder.html
- https://pub.dev/packages/pdf
- https://pub.dev/packages/pdf/changelog
- https://pub.dev/documentation/pdf/latest/widgets/Font-class.html
- https://pub.dev/packages/printing
- https://pub.dev/documentation/printing/latest/printing/PdfGoogleFonts-class.html
- https://pub.dev/packages/share_plus
- https://pub.dev/packages/csv
- https://pub.dev/packages/csv/changelog
- https://pub.dev/packages/file_picker
- https://pub.dev/packages/file_selector
- https://pub.dev/packages/wakelock_plus
- https://pub.dev/packages/path_provider
- https://pub.dev/packages/permission_handler
- https://pub.dev/packages/archive
- https://pub.dev/packages/open_filex

**Plugin source (GitHub raw)**
- https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/README.md
- https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/lib/src/flutter_local_notifications_plugin.dart
- https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java
- https://github.com/MaikuB/flutter_local_notifications/issues/2312
- https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/README.md
- https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/csdcorp/speech_to_text/main/speech_to_text/android/src/main/kotlin/com/csdcorp/speech_to_text/SpeechToTextPlugin.kt
- https://raw.githubusercontent.com/flutter-ml/google_ml_kit_flutter/master/packages/google_mlkit_text_recognition/android/build.gradle
- https://raw.githubusercontent.com/flutter-ml/google_ml_kit_flutter/master/packages/google_mlkit_text_recognition/android/src/main/AndroidManifest.xml
- https://github.com/flutter-ml/google_ml_kit_flutter/issues/198
- https://github.com/juliansteenbakker/mobile_scanner/issues/553
- https://raw.githubusercontent.com/flutter/packages/main/packages/image_picker/image_picker_android/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/llfbandit/record/master/record_android/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/fluttercommunity/plus_plugins/main/packages/share_plus/share_plus/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/DavBfr/dart_pdf/master/printing/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/Baseflow/flutter-permission-handler/main/permission_handler_android/android/src/main/AndroidManifest.xml
- https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
- https://github.com/DavBfr/dart_pdf/issues/810
- https://github.com/DavBfr/dart_pdf/issues/252
- https://github.com/DavBfr/dart_pdf/issues/405

**Google Maven**
- https://dl.google.com/dl/android/maven2/com/google/mlkit/text-recognition/16.0.1/text-recognition-16.0.1.pom

**Android / Google Play**
- https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- https://developer.android.com/develop/background-work/services/alarms/schedule
- https://developer.android.com/about/versions/14/behavior-changes-14
- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/build/manage-manifests
- https://developer.android.com/training/data-storage/shared/photopicker
- https://developer.android.com/reference/android/speech/SpeechRecognizer
- https://support.google.com/googleplay/android-developer/answer/9888170

**Google ML Kit**
- https://developers.google.com/ml-kit/vision/text-recognition/v2
- https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- https://developers.google.com/ml-kit/vision/text-recognition/v2/ios
- https://developers.google.com/ml-kit/terms

**Apple**
- https://developer.apple.com/forums/thread/811171
- https://developer.apple.com/support/third-party-SDK-requirements/
- https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- https://developer.apple.com/videos/play/wwdc2025/277/
- https://developer.apple.com/documentation/vision/vnrecognizetextrequest?language=objc
- https://developer.apple.com/documentation/vision/vnrecognizetextrequest/supportedrecognitionlanguages(for:revision:)
- https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition
- https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition

**Apple header docs (mirrored — used because developer.apple.com pages render client-side and returned no body to the fetcher)**
- https://docs.rs/objc2-speech/latest/objc2_speech/struct.SFSpeechRecognizer.html
- https://docs.rs/objc2-speech/latest/objc2_speech/struct.SFSpeechRecognitionRequest.html

### Fetches that failed or returned no usable body

- `developer.apple.com/documentation/…` pages for `supportsOnDeviceRecognition`,
  `requiresOnDeviceRecognition`, `RecognizeTextRequest`, `recognizing-text-in-images`, and
  `UNUserNotificationCenter.add(_:withCompletionHandler:)` all returned only the page title (JS-rendered
  docs). The API semantics above are therefore sourced from the mirrored Objective-C headers on docs.rs
  and from the Apple Developer Forums thread with an Apple engineer's reply. **Re-verify
  `supportsOnDeviceRecognition` and `requiresOnDeviceRecognition` in Xcode's Quick Help before writing
  the platform channel**, if voice entry is ever revived.
- `developer.android.com/develop/background-work/services/alarms/schedule-exact-alarms` → 404
  (the live page is `/develop/background-work/services/alarms/schedule`, which was fetched).
- `support.google.com/googleplay/android-developer/answer/12253906` returned a deadlines page with no
  exact-alarm policy text; the policy language was obtained from answer 9888170 instead.
- The iOS Swift source of `speech_to_text` could not be located at the guessed paths
  (`ios/Classes/SwiftSpeechToTextPlugin.swift`, `ios/speech_to_text/Sources/…`) — both 404'd. The
  Android on-device implementation **was** verified directly. The iOS `onDevice → requiresOnDeviceRecognition`
  mapping is therefore *inferred*, not verified, which is a further reason for the hard capability gate
  in §2.4.
- `archive`'s streaming ZIP **encoder** API was not confirmed from primary docs; only the streaming
  decode path is documented on the pub.dev page. Verify before committing to the ZIP backup design (§6.3).
