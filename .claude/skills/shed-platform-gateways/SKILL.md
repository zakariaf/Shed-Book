---
name: shed-platform-gateways
description: >-
  Wraps an already-approved plugin behind one of the seven platform seams. Use when wrapping a
  plugin, editing AndroidManifest.xml or Info.plist, scheduling a reminder or notification,
  capturing media, sharing a file or asking for a permission. Do NOT use to decide whether a package
  may be added at all (shed-dependencies-and-toolchain), or for an export's contents
  (shed-export-and-restore).
---

# Platform gateways

Every native capability sits behind one **hand-written class in `lib/data/` that wraps exactly one
plugin**, exposes only the verbs this app needs, and is replaced by a **hand-written fake** in
`test/support/` — never `mocktail` (decision #112). The collective noun is **gateway**; "platform
service", "adapter", "wrapper" and "client" are banned synonyms (R71).

`docs/engineering/08-platform-integration.md` is the specification — read the section you are
touching. `CONVENTIONS.md` §2.12 owns the seven class and file names, §3.1 their providers. This
skill carries what applies to every edit and the traps that ship silently.

**Not this skill:** what is inside an exported or restored file → `shed-export-and-restore`. The
release-time gate G1 and the release checklist → `shed-release`. Entitlement, free-tier and
purchase-flow rules → `shed-monetization`.

## One plugin, one import site

Six platform seams (08's) plus `PurchaseService`, the **store** seam (R74, owned by 11). Confinement
is mechanical, and the package → file map exists in exactly two places on purpose: **`08 §1.2`'s
nine-row `_confinedPackages` table plus the tenth row `CODE-REVIEW-CHECKLIST §1.13` adds, and the
same rows inside `tool/check_policy.dart`.** Read the map out of one of those two; a third copy is
how a seam moves in the gate and not in the docs. Class and file names are `CONVENTIONS §2.12`.

Four rows the map does not read the way an agent guesses:

- **`path_provider` has two legal sites**, not one — the media root and the database connection.
- **`file_selector` is confined to the restore flow under `lib/features/`**, not to a gateway (below).
- **`timezone` is confined to the notification seam** (R48) and never enters the domain.
- **`in_app_purchase` is confined by R74 to the store seam**, and `lib/main.dart` / `lib/app.dart` may
  not reference `PurchaseService` at all (`launch.store_call`).

Rule ids are `layer.plugin_<pub package name>`, spelled out, no abbreviations — except
`layer.path_provider` and `layer.in_app_purchase` (CONVENTIONS §4.7).

**No plugin type crosses a gateway boundary in either direction.** Not `ImageSource`, `Amplitude`,
`Importance`, `AndroidScheduleMode`, `ShareResultStatus`, `ProductDetails`. Each gateway declares its
own small enum or record and translates at the plugin call — `CaptureSource`, `ChannelImportance`,
`ShareOutcome`, `ProjectedReminder`, a `double` of dBFS. One leaked type drags a `package:` import
into `lib/features/` and makes `layer.plugin_*` unsatisfiable. `lib/data/` may not import
`package:flutter/material.dart` (layer rule 4); `ShareService` imports `dart:ui show Rect` instead.

**`file_selector` is the one deliberate exception and there is no seventh platform gateway.** A
system document picker is out-of-process UI, so a fake would only assert that we called a function;
the meaningful seam is `RestoreService.restoreFrom(File)`. Adding a gateway means editing
CONVENTIONS §2.12, which no other document may do.

## Reminders and notifications

**SQLite is the only truth. The OS holds a windowed, disposable cache.
`ReminderReconciler.reconcile()` (R51) tears it down with `cancelAll()` and rebuilds it.**

- `zonedSchedule(` appears in exactly one file, `lib/data/notification_scheduler.dart`, and is the
  only `[exempt]` line 08 adds. A platform-channel round-trip inside a drift transaction holds a
  write open across an `await` on the 3am path, against a budget it cannot see.
- `schedule(` on a reminder object is banned (`db.reminder_schedule`, R51) — that spelling *is* the
  architecture decision #63 rejects. Say **reconcile**, never schedule/sync/refresh.
- There is no `os_notification_id` column: a stored OS id is a second source of truth that goes stale
  on the next reconcile.
- `ReminderBudget.forPlatform()` (R50, `lib/domain/reminder_budget.dart`) both slices the projection
  and feeds the Reminders screen's copy, so the literal `56` appears in no ARB message and no widget.

Two traps that bite before you would think to open a reference file:

- **`initialize()` must set `requestAlertPermission`, `requestBadgePermission` and
  `requestSoundPermission` to `false`.** The plugin's defaults are `true`, so the obvious code raises
  an iOS permission prompt at first launch — spec §5's nag, on the launch path.
- **`USE_EXACT_ALARM` in a manifest is a Play removal.** Play restricts it to alarm/timer and
  calendar apps; Shed Book is a notebook. Declare `SCHEDULE_EXACT_ALARM`, which is user-granted. Do
  not re-argue this because colostrum is time-critical — that is the argument the policy anticipates.

**Read `references/notifications.md` before writing or editing anything that touches a reminder or a
notification** — it carries `reconcile()` and its four call sites, the soonest-N query, the eight
channels, exact alarms, reboot, DST and the honest disclosure.

## Capture — `CameraService` and `VoiceRecorder`

R47: `CameraService` owns `image_picker` (`pickImage`, `retrieveLostData`), `VoiceRecorder` owns
`record` (the class is `AudioRecorder`; `Record` was renamed in 5.0.0), and `MediaStore` owns the
media root, `newRelativePath`, `resolve`, `writeAtomically` and the `flutter_image_compress`
downscale. 04 §4.4's "a method ON `MediaStore`" is superseded — the code moves, the compression stays.
The voice **note** ships; voice **tag entry** is cut (below).

- **`pick()` calls `retrieveLostData()` first, inside itself — never from a resume handler.** Android
  can kill the app while the system camera is foreground, and a resume handler that recovers a photo
  has nowhere to put it; only `pick()`'s caller knows which record it belongs to. A recovered photo is
  labelled on screen — *"Recovered from your last photo"* at the 18px floor, with the normal 60×60
  Remove control — because attaching it silently misattributes one record's photo to another (§12.4).
- `requestFullMetadata: false` keeps the microphone permission unasked; it does **not** remove the
  `Info.plist` keys, which App Store review still requires.
- Compression is decision #40: longest edge 2048 px, JPEG q80, `keepExif: false` set explicitly —
  `keepExif: true` re-attaches GPS and is a banned string (`media.keep_exif`). Photos never go into
  SQLite: `VACUUM INTO` copies the whole database and Auto Backup caps at 25 MB.
- **AAC-LC `.m4a`, mono, 32 kbps. Never Opus** (`media.opus`): `record` containers Opus as OGG on
  Android and CAF on iOS, so an Android backup would not play after a restore onto an iPhone — the
  entire point of spec §7.9.
- The voice-note cap is a one-shot `Timer` inside `VoiceRecorder.start()`, not the UI countdown ring:
  a UI timer can be starved, a gateway cannot. `kVoiceNoteMaxSeconds` is one constant in
  `lib/data/media_limits.dart`, shipping **60**.
- **The `media_assets` row is inserted when recording starts**, because the file exists from that
  moment and a phone death mid-note must leave a linked truncated file rather than an orphan the
  sweeper deletes. `byte_size` is written on `stop()`; a truncated `.m4a` may be unplayable at all
  (the `moov` atom is written last), so `byte_size == 0` renders as *"Recording interrupted"* and
  offers Delete, **not** Play.
- Tap-to-start / tap-to-stop at 60×60 with a level meter from `levelDbfs`. **Press-and-hold is banned
  everywhere** (#101).

## Share sheet — `ShareService`

The share sheet **is** the export mechanism (spec §7.9).

- `SharePlus.instance.share(ShareParams(...))`; the static `Share.share*` methods are deprecated and
  banned (`share.static_api`). Always pass a file path — `XFile.fromData` (`share.from_data`) writes
  a temp copy nobody cleans up.
- **`origin` is a required named `Rect`**, computed by the caller from the button that was tapped
  (`box.localToGlobal(Offset.zero) & box.size`). Omitting `sharePositionOrigin` on iPad crashes;
  passing `Rect.zero` is not a workaround, it is the bug.
- `app_settings.last_exported_at` is written on `ShareOutcome.completed` **and** on
  `ShareOutcome.unknown`, never on `dismissed`, and never before the sheet opens.
- Exports go to `getTemporaryDirectory()`, which is excluded from iCloud and Auto Backup.

## Backup import and wakelock

`file_selector` is called from `lib/features/settings/restore_flow.dart` only, and needs no storage
permission on either platform. Accept `application/octet-stream` as well as `application/json` —
Android MIME filtering is unreliable, and greying out the shepherd's own backup is worse than
accepting too much and refusing clearly. **We validate the magic bytes ourselves**, and
`RestoreService` copies the pick to `<temp>/restore/incoming.json` immediately because an Android
`content://` grant can be one-shot. `.zip` is not accepted in v1.

`WakelockController` (decision #79): **default off, session-scoped, 30-minute expiry, released on any
non-resumed state.** `acquire()` is called **only** by the `NavigatorObserver` in `lib/app.dart`,
never from `initState`/`dispose` — Quick Entry → Lambing Entry stack, so per-screen calls either leak
the lock or release one the screen underneath still wants. The permitted routes are
`RouteNames.quickEntry`, `RouteNames.lambingEntry` and `RouteNames.penBoard`. `release()` is
unconditional and idempotent, never reference-counted: a leaked lock drains the phone silently
overnight, and a dead phone at 05:00 is worse than a screen timeout.

## Permissions — the eight entries

`13-build-ci-release.md` §3.1 is the authority for **what ships** and holds the table — read it, never
retype it. The count that confuses everyone: the eight entries are seven *declared* permissions plus
`INTERNET`, which is an entry asserted by its **absence**, so the expected file holds seven lines.
`ACCESS_NETWORK_STATE` is **pending gate G0**: do not add or remove that line on faith. 08 §8.2 owns
**who asks and when**; **shed-release** owns the gate that checks the set.

> **Editing `android/expected_permissions.txt` to silence G1 is named in 13 §2.3 as the single worst
> thing you can do to this project.** G1 asserts exact set equality against the shipped `.aab` to
> catch a plugin bump in month six quietly merging a new permission. If it fails, find the
> contributor in `manifest-merger-release-report.txt` — never edit the expected file to go green.

- **No `permission_handler`** (decision #78). Every permission has a first-party request API on the
  plugin that needs it: `NotificationScheduler.requestAlerts()`, `CameraService.pick()` (prompts
  natively), `VoiceRecorder.hasPermission()`. `lib/features/` sees only the gateway verb, never the
  plugin method, and no permission is ever requested from a write path or at launch.
- **Photo library: none, ever.** No location, contacts, calendar, Bluetooth, `FOREGROUND_SERVICE` or
  `USE_FULL_SCREEN_INTENT`. A shepherd who only records lambings never sees a system dialog.
- **iOS `Info.plist`:** three usage strings (`NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription` — for review, not for a prompt — and
  `NSMicrophoneUsageDescription`) plus `UIUserInterfaceStyle = Dark`. `NSAppTransportSecurity` and
  `UIBackgroundModes` must be **absent**; `UIFileSharingEnabled` and
  `LSSupportsOpeningDocumentsInPlace` are deliberately not set, because the database and media live
  in Application Support and nothing of ours is in `Documents/`.
- Never write a "`http` must not appear in `pubspec.lock`" gate — `http` sits on two load-bearing
  regular edges, so such a gate is unsatisfiable on day one. The gates are G1 + G2 + G3.

## Tag OCR and voice tag entry are v2 — the record

Both are cut from v1 by owner ruling (decisions #75, #76; 08 §10), so do not reach for a package.
`google_mlkit_*` drags in `play-services-base`, which contributes `INTERNET` and fails our own G1 on
the first release build; `speech_to_text`'s on-device flag defaults false and **silently falls back
to network recognition**, in another process whose network access our manifest cannot constrain. Both
fail **G2** the day they are added, which is the point. What ships instead is the 60×60 `ShedKeypad`
with `rankTagMatches`, plus the voice note. 08 §10.3 states the bar for v2.

## Done when

- [ ] Every plugin in `08 §1.2`'s map has exactly one import site (two for `path_provider`), and
      `dart run tool/check_policy.dart` fails on a seeded violation of each row.
- [ ] A hand-written fake exists in `test/support/` for all seven seams; none is mocked, no plugin
      type appears in a gateway signature, and `lib/features/reminders/notification_gateway.dart`
      does not exist (R48).
- [ ] `zonedSchedule(` is in one file; `schedule(` on a reminder object, `matchDateTimeComponents`,
      `AndroidScheduleMode.alarmClock`, `USE_EXACT_ALARM`, `AudioEncoder.opus`, `keepExif: true`,
      `Share.share` and `XFile.fromData` appear nowhere in `lib/`.
- [ ] `ShareService.shareFiles` takes `origin` as required; `Rect.zero` appears at no call site.
- [ ] `release()` is unconditional and the lifecycle handler calls it on every non-resumed state.
- [ ] The merged manifest matches `android/expected_permissions.txt` exactly, and that file was not
      edited to make it match.
- [ ] `permission_handler`, `camera`, `file_picker`, `speech_to_text` and `google_mlkit_*` are absent
      from `pubspec.yaml`; `flutter analyze` is clean.
