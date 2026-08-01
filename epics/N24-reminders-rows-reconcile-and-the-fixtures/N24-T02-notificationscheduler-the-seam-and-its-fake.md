# N24-T02 — `NotificationScheduler` — the seam and its fake

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 2 of 8 |
| **Depends on** | N24-T01 |
| **Commit** | one commit · `feat(gateway): NotificationScheduler and its fake` |

## 1. Why this task exists

The sixth and last platform gateway, and the only one that wraps **two** packages:
`flutter_local_notifications` **22.2.0** and `package:timezone` **0.11.1**. It is the app's single
`tz.setLocalLocation` call site (R48) and its single `zonedSchedule(` call site — both held
mechanically by `layer.plugin_*` rows rather than by review habit, because *"a fake that wraps the
plugin tests nothing: if `image_picker` is imported in two places, the fake covers one of them and the
other is untested forever"* (`08 §1.1`).

Its projection verb is `project(...)`, never `schedule(...)`. That is not taste: `schedule(` on a
reminder object **is** the architecture decision #63 rejects, and R51 makes the spelling a policy rule
row. *Reconcile* is what we do; *schedule* is what the OS does.

`FakeNotificationScheduler` ships in the same commit, with all three tripwires, because every
assertion in T04, T05, T06, T07, N25 and N33 is made against its recorded calls. A fake with no
tripwires makes those assertions decorative.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§1.1** (the gateway rule; no plugin type crosses the boundary in either direction) · **§1.2** (`_confinedPackages`, and the nine rule ids spelled out) · **§2.3** (the surface, printed in full, plus the `zonedSchedule` call shape verified against v22) · §2.5 (ids and payloads) · **§2.6** (`NotificationCopy`, `NotificationChannelSpec`, `ChannelImportance`, and why the gateway cannot localise) · **§2.11** (tz confinement, `latest_10y`, and the DST-8 invariant printed) · §2.14 (the anti-pattern table and its gates) · §9 (the new `_bannedText` rows and the fifth `[exempt]` line) · **§11 items 1–4** (the four unverified plugin facts) | the class, every member, and every plugin fact that is *not* settled |
| `docs/engineering/12-testing.md` | **§4.1** (hand-written fakes, five reasons) · **§4.2** (the seven fakes; `implements`, never `extends`) · **§4.3** (`FakeNotificationScheduler` printed in full, with its three tripwires and their messages) · **§5.1** (`shedContainer`, and the `FutureProvider` override spelling) · §5.3 (the closed twelve-file `test/support/` list) · §4.5 (the anti-patterns) | the fake, verbatim, and where it plugs in |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/notification_scheduler.dart`) · §1.1 layer rules **3** (`lib/data/` may import `package:timezone`) and **4** (`lib/data/` may not import `material.dart`) · §2.1 (`ReminderId`) · **§2.12** (the gateway table) · §3.1 (`notificationSchedulerProvider` — `FutureProvider`, keepAlive) · §4.2 (`<Name>Scheduler`) · §4.7 (rule-id namespaces) · **R48**, **R51**, R71 | **BINDING** on the path, the class name, the provider and the words |
| `docs/engineering/01-architecture.md` | §3.2 (the rule tables `_confinedPackages` and `_bannedText` extend) · §4.3 rule 4 (never call a gateway inside a transaction) · §6.3 (the post-frame table: tz setup is *"the notification seam only"*) | where the new gate rows live |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions — `flutter_local_notifications` **22.2.0**, `timezone` **0.11.1** · §5.1's note that **`flutter_timezone` is required and NOT audited** · #48, #63, #112 | the two version numbers, and the one package you may not add |
| `docs/engineering/13-build-ci-release.md` | §1.2 (`pubspec.lock` is evidence) · §2.4 (G2's allowlist) · §4.2 (the three blocking jobs) | what CI does with two new dependencies |
| `epics/N03-the-gate/N03-T04-g2-the-direct-dependency-allowlist-over-pubspeclock.md` | §5 (both packages are already on the `[dependencies]` allowlist; **`flutter_timezone` is deliberately not**) | why `pub get` here needs no allowlist edit, and why it would if you reached for the wrong package |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the notification seam, its surface and its fake |
| `shed-testing` | the fake's tripwires are what make the later assertions meaningful |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/notification_scheduler_test.dart`
- **Test** — `'the fake trips on a duplicate id and on a project() not preceded by cancelAll()'`
- **Why it is red today** — nothing schedules a notification, and there is no fake for the harness to override with.

```bash
fvm flutter test test/data/notification_scheduler_test.dart   # expect: failing, for the reason above
```

Sharpen it: assert the **`StateError` message text**, not merely that it throws. Each of the three
tripwires carries the decision or spec clause it holds (`12 §4.3` prints all three), and a tripwire
whose message says only "bad state" tells the developer who hits it at 23:00 nothing. Use
`throwsA(isA<StateError>().having((e) => e.message, 'message', contains('decision #63')))`.

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the fake, and the fake joining `pumpApp`'s override list in this commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 0 — deps | `pubspec.yaml` · `pubspec.lock` | **Edit.** `flutter_local_notifications: 22.2.0` and `timezone: 0.11.1`, exactly those versions, from decision-record §5 and nowhere else. The lockfile moves in the same commit — it is the evidence the table still resolves (`13 §1.2`) |
| 1 — schema | **skipped** | `reminders` and `reminder_rules` were created at N07-T06 and frozen at N07-T08. **No column is added here**, and there is no `os_notification_id` column — adding one is a defect (`03 §5.10`) |
| 3 — data | `lib/data/notification_scheduler.dart` | **New.** The class, the top-level `scheduleTimeFor`, `ProjectedReminder`, `NotificationCopy`, `NotificationChannelSpec`, `ChannelImportance`. The only file in `lib/` that names either package |
| 4 — wiring | `lib/data/providers.dart` | **Edit.** `notificationSchedulerProvider` — `FutureProvider<NotificationScheduler>`, keepAlive, because `initialize()` is async. N12-T01 left the slot with a comment naming N24 |
| — gate | `tool/check_policy.dart` | **Edit.** Two `_confinedPackages` rows (`layer.plugin_flutter_local_notifications`, `layer.plugin_timezone`) and four `_bannedText` rows (`notify.zoned_schedule`, `notify.use_exact_alarm`, `notify.alarm_clock`, `notify.recurring`). `notify` is a **new rule-id namespace** and `CONVENTIONS §4.7` gains it in this commit (`08 §11`) |
| — gate | `tool/policy_allowlist.txt` | **Edit.** One `[exempt]` line: `lib/data/notification_scheduler.dart :: notify.zoned_schedule`. R56's four become **five**, and this is the only fifth the doc set sanctions |
| 7 — tests | `test/support/fake_notification_scheduler.dart` | **New.** `12 §4.3`, verbatim. `implements`, never `extends` |
| 7 — tests | `test/support/harness.dart` | **Edit.** `shedContainer` gains `FakeNotificationScheduler? notifications` and the override; the header comment loses N24's line from the "still to come" list. With this commit the override list holds **five** of `12 §5.1`'s seven |
| 7 — tests | `test/data/notification_scheduler_test.dart` | **New.** The anchor plus §5.5's cases |
| 7 — tests | `test/data/reminder_dst_test.dart` | **New.** DST-8 only, `@Tags(['uk-zone'])`. DST-7 and DST-9 are T06's; do not write them here |

### 5.2 The signatures

`08 §2.3` prints the class. Copy it as printed — every member is called by a later task, and the
elisions in that document are bodies, never signatures.

```dart
// lib/data/notification_scheduler.dart
// The ONLY file in the app that imports flutter_local_notifications or
// package:timezone (R48; layer.plugin_flutter_local_notifications and
// layer.plugin_timezone).
final class NotificationScheduler {
  NotificationScheduler(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;
  NotificationCopy? _copy;

  Future<void> initialize({required void Function(int reminderId) onTap});
  Future<void> refreshLocalZone();
  Future<void> installCopy(NotificationCopy copy);       // T03 fills it
  Future<bool> requestAlerts();                          // T06
  Future<bool> alertsGranted();
  Future<bool> canBeExact();                             // T06
  Future<void> requestExactAlarms();                     // T06
  Future<void> cancelAll();
  Future<void> project(ProjectedReminder r, {required bool exact});
  Future<List<int>> pendingIds();                        // diagnostics and tests only
  Future<ReminderId?> launchTapTarget();                 // T07
  String titleFor(String kind, {String? tag});
  String bodyFor(String kind, {String? tag});
}

/// R48's one tz conversion, and deliberately a TOP-LEVEL PUBLIC function rather
/// than a private method: the DST-8 invariant has to call it from test/.
/// It is a RENDERING of an instant in a zone, never a shift of the instant.
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

Inside `project()`, the v22 call shape — **named parameters throughout**, verified in `08 §2.3`:

```dart
await _plugin.zonedSchedule(
  id: r.id.value,
  title: titleFor(r.kind, tag: r.tag),
  body: bodyFor(r.kind, tag: r.tag),
  scheduledDate: scheduleTimeFor(r.dueAt),
  notificationDetails: _detailsFor(r.kind),
  androidScheduleMode: exact                      // the CALLER's flag, never ours
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle,
  payload: 'reminder:${r.id.value}',
);
```

That ternary is the **only** place `AndroidScheduleMode` is named in the app.

### 5.3 One ruling this task must make, in writing

**`scheduleTimeFor` is a top-level public function; `CONVENTIONS.md` R48 says it is a private method.**
Both documents are authoritative and one of them is wrong. `08 §2.3` wins, and the reason is in
`08 §2.11`: the DST-8 invariant lives in `test/data/reminder_dst_test.dart`, and a private method
cannot be called from `test/`. Without that test, an incorrect `tz.local` is an unbounded correctness
risk instead of a bounded one.

Per `00-README` §10's amendment rule — clause 3, a change to a **name** is `CONVENTIONS.md`'s — R48 is
amended **in this commit**: its last line becomes *"`scheduleTimeFor(Instant)` is a top-level public
function in `notification_scheduler.dart`, so the DST-8 invariant can call it."* Do not leave two
spellings standing.

### 5.4 The details that are easy to get wrong

- **`initialize()` must never raise a prompt.** `DarwinInitializationSettings` defaults
  `requestAlertPermission`, `requestBadgePermission` and `requestSoundPermission` to **`true`**. All
  three are set `false` here. Letting `initialize()` fire the prompt is spec §5's *"notification
  permission nag"* arriving at first launch, and it is the single easiest way to lose that property —
  the plugin's defaults work against you.
- **The device's IANA zone name has no source yet, and you may not add one.** `tz.setLocalLocation`
  needs it; `flutter_timezone` is *"required but NOT in the c1 audit"* (decision-record §5.1) and is
  release-blocking open item 1 in `08 §11`. `08 §2.3` is explicit: *"until that audit lands, this line
  is unwritten, not 'written with a TODO'."* So `initialize()` calls `tz.initializeTimeZones()` and
  stops; `refreshLocalZone()` exists, is called at the head of every reconcile (T05), and has one
  private zone-name lookup with nothing behind it yet. **N03-T04 left `flutter_timezone` off the G2
  allowlist deliberately — G2 going red on it is the gate working, not a gate to edit.**
- **That gap is bounded, and DST-8 is what bounds it.** `scheduleTimeFor` is a *rendering* of an
  absolute instant in a zone, so a wrong `tz.local` cannot move **when** a reminder fires on Android,
  where the plugin hands an epoch to `AlarmManager`. Whether iOS's `UNCalendarNotificationTrigger`
  construction preserves that property inside 22.2.0 is **unverified** (`08 §11` item 2) — write the
  item into the PR body; do not write a workaround for it.
- **`package:timezone/data/latest_10y.dart`, never `latest`.** Every instant this app converts is a
  future one, weeks away at most. Note 06 measured roughly 85 KB against 361 KB — a figure `08 §2.11`
  marks *not independently verified*, so do not quote either number anywhere user-facing.
- **No plugin type crosses the boundary in either direction.** Not `Importance`, not
  `AndroidScheduleMode`, not `NotificationResponse`, not `TZDateTime`. Each would drag its `package:`
  import into `lib/features/` and make `layer.plugin_*` unsatisfiable. `ChannelImportance { high,
  normal }` is **ours**, and the gateway maps it at the plugin call.
- **The Darwin rename is a v19 landmine — a compile error, not a silent bug.** v19 prefixed the
  iOS/macOS settings and details classes with `Darwin`, and note 06 contradicts itself on the
  resolver's name between its own §1.2 and §9. Resolve the type against the **installed** 22.2.0
  surface, in one place, on the day you write it. Do not copy either spelling out of a document.
- **`implements`, never `extends`, in the fake.** `12 §4.2`: if the fake `extends`, a signature change
  in the gateway becomes a silent divergence instead of a compile error. Every member above must
  appear in the fake or the file does not compile — which is exactly the alarm you want.
- **The fake's `cancelAll()` clears `projected`.** That is what makes the budget tripwire *per
  reconcile* rather than per test, and it is why the `calls` list — not `projected` — is what proves
  teardown-and-rebuild ordering (`expect(fake.calls.first, 'cancelAll')`).
- **`notificationSchedulerProvider` is a `FutureProvider`, so the harness override is
  `.overrideWith((ref) async => …)`.** `overrideWithValue` is for the plain `Provider` gateways;
  `Provider<NotificationScheduler>` is not an option because `initialize()` is async. `12 §5.1` prints
  the exact line — copy it, and copy the 2.6.1 spelling with it (there is no `ProviderContainer.test()`
  and no `WidgetTester.container`; both are Riverpod 3).
- **`...overrides` stays spread last in `shedContainer`.** A caller's override must win over the
  harness default for the same provider. Do not reorder the list to group the new gateway "with its
  friends".
- **`pendingIds()` is diagnostics and tests only.** The plugin's `pendingNotificationRequests()`
  returns only id, title, body and payload — not enough to diff against, which is exactly why
  teardown-and-rebuild exists. Anything treating it as a source of truth has re-introduced the second
  source of truth decision #63 removed.
- **`project()` throws `StateError` when no copy is installed.** Deliberate. The alternative —
  projecting with an empty title — is a blank notification at 3am.
- **Do not write a "no `http` in `pubspec.lock`" rule when the lockfile grows.** Adding `timezone`
  adds `http 1.6.0` on a regular edge (`flutter_local_notifications → timezone → http`). That edge is
  load-bearing; a gate built on its absence is **unsatisfiable on day one**, and `08 §9` deletes the
  phrasing rather than softening it. The gates are G1 + G2 + G3.
- **`notify` and `share` are new rule-id namespaces** and `CONVENTIONS §4.7` lists neither. This task
  adds `notify` there in the same commit — a document may not use a namespace it has not been given
  (`08 §11`).
- **The fifth `[exempt]` line is deliberate and reviewable.** R56 fixes the section at four lines on
  day one; `notify.zoned_schedule` needs one, and it is the only fifth the doc set sanctions. The
  reason goes in **this** commit message, because `00-README` §7.4 says an `[exempt]` line *"deletes a
  rule for one file, forever, silently"*.

### 5.5 The full test set

`test/data/notification_scheduler_test.dart`

| Case | What it asserts |
|---|---|
| `'the fake trips on a duplicate id and on a project() not preceded by cancelAll()'` | **The anchor.** Two `StateError`s, each matched on its **message**: `'nothing nags twice'` and `'decision #63'` |
| `'the fake trips when the projection exceeds ReminderBudget.forPlatform()'` | The third tripwire. Feed `forPlatform() + 1` rows after one `cancelAll()`; the message names the budget and the undefined 65th request |
| `'cancelAll clears the fake projection, so the budget is per reconcile'` | Project to the ceiling, `cancelAll()`, project again — no throw |
| `'calls records order, and the first entry after a reconcile is cancelAll'` | Ordering as a plain list comparison; no `verifyInOrder`, no mocking library |
| `'FakeNotificationScheduler implements every member of NotificationScheduler'` | Source text: the fake declares `implements` and not `extends`, and its `@override` count equals the class's public member count |
| `'shedContainer resolves notificationSchedulerProvider to the fake, and lib/ contains no overrideWithValue'` | In `test/support/harness_test.dart`. The override landed **here**, in this commit, per N12-T05's ledger |
| `'flutter_local_notifications is imported in exactly one file under lib/'` | Source scan over `lib/`. `layer.plugin_*` proves it in CI; this proves it in the suite, with a message naming the fake |
| `'package:timezone is imported in exactly one file under lib/'` | Same property, R48 |
| `'zonedSchedule( appears in exactly one file, and it is the exempted one'` | Source scan plus a read of `tool/policy_allowlist.txt`: the `[exempt]` line exists and names this file |
| `'AndroidScheduleMode is named exactly once under lib/'` | The ternary in `project()`. `alarmClock` and bare `exact` appear nowhere |
| `'initialize() sets all three Darwin request flags false'` | Source text over `notification_scheduler.dart` — the assertion cannot be made at runtime without a device, and the failure it guards is a prompt at first launch |
| `'a launch through pumpApp makes zero permission calls'` | Widget tier: `pumpApp` any screen, then `expect(fake.calls, isNot(contains('requestAlerts')))`. `08 §2.14`'s named gate for *"a prompt from `initialize()`"* |
| `'the provider uses no Riverpod 3 API'` | `overrideWith((ref) async => …)`; no `Ref` type argument, no 3.x `Notifier` generics, no `ProviderContainer.test()` |

`test/data/reminder_dst_test.dart` — `@Tags(['uk-zone'])`, run under `TZ=Europe/London`

| Case | What it asserts |
|---|---|
| `'DST-8: the projected TZDateTime is the SAME absolute instant as due_at'` | `08 §2.11`, printed. `Instant.fromDateTime(DateTime.utc(2026, 3, 29, 1, 30))` → `scheduleTimeFor(i).millisecondsSinceEpoch == i.epochMillis`. This one line is what makes the un-audited zone source a bounded risk rather than a correctness hole |
| `'DST-8b: the same holds inside the repeated hour on 25 October 2026'` | The autumn-back twin, at `01:30`. The conversion is a rendering in both directions, and only the fired-instant behaviour differs by platform |
| `setUpAll` zone assertion | `expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1), reason: 'Run this file with TZ=Europe/London')`. **A skipped safety test is a broken safety test** (`12 §2.3`) — without it the file passes vacuously under the runner's UTC |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`reconcile` never `schedule`, `sync` or `refresh`** (R51, `CONVENTIONS §5.2`); **projection** never
  *queue* or *cache* in copy; **gateway** never *adapter*, *wrapper*, *client* or *platform service*
  (R71). All four are gate rows, so they are enforced twice and remembered once.
- **`lib/data/` may not import `package:flutter/material.dart`** (layer rule 4). The gateway hands
  upward a path, an `Instant`, a `bool` or a `ReminderId` — never a widget, never a `BuildContext`,
  never an `AppLocalizations`. That is precisely why T03's copy seam exists.
- **Two dependencies enter the graph in this commit and no others**, at decision-record §5's exact
  versions: `flutter_local_notifications` **22.2.0**, `timezone` **0.11.1**. Not `pub add`, not a
  README, not memory.
- **This task authors no user-facing string.** Every string the OS shows arrives through
  `installCopy()` from `lib/features/reminders/reminder_copy.dart`, which is T03's.

## 7. Definition of Done

- [ ] `'the fake trips on a duplicate id and on a project() not preceded by cancelAll()'` passes, and was seen to fail first for the stated reason
- [ ] the fake implements every member and never extends
- [ ] all three tripwires exist and are proved
- [ ] `package:timezone` is imported in exactly one file
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `flutter_local_notifications` is imported in exactly one file, and `zonedSchedule(` appears in exactly one file
- [ ] the three Darwin request flags are `false` in `initialize()`
- [ ] `flutter_timezone` is **not** in `pubspec.yaml`, and the release-blocking open item is named in the PR body
- [ ] DST-8 passes under `TZ=Europe/London`, and the file asserts its own zone in `setUpAll`
- [ ] `shedContainer` overrides `notificationSchedulerProvider`, spelled `overrideWith((ref) async => …)`
- [ ] `CONVENTIONS.md` R48 is amended in this commit to say `scheduleTimeFor` is top-level and public
- [ ] `CONVENTIONS.md` §4.7 gains the `notify` namespace in this commit
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section has exactly five lines, and the fifth is explained in the commit message
- [ ] `pubspec.lock` moved, and its diff was read rather than skimmed

## 8. Verification

```bash
fvm flutter test test/data/notification_scheduler_test.dart
make check
make test
```

```bash
# Confinement — the whole property this gateway exists for.
grep -rln 'package:flutter_local_notifications' lib/   # expect exactly notification_scheduler.dart
grep -rln 'package:timezone' lib/                      # expect exactly notification_scheduler.dart
grep -rn  'zonedSchedule(' lib/                        # expect one hit, in that file
grep -rn  'AndroidScheduleMode' lib/                   # expect one hit (the ternary)
grep -rn  'alarmClock\|matchDateTimeComponents\|USE_EXACT_ALARM' lib/    # expect nothing
grep -rn  'flutter_timezone' pubspec.yaml pubspec.lock                   # expect nothing

# The fake, the harness and the allowlist.
grep -n 'implements NotificationScheduler' test/support/fake_notification_scheduler.dart
grep -n 'notificationSchedulerProvider' test/support/harness.dart
sed -n '/^\[exempt\]/,$p' tool/policy_allowlist.txt    # expect five entries

# The zone-pinned leg, which the default run does not cover.
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/support/harness_test.dart
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(gateway): NotificationScheduler and its fake`
