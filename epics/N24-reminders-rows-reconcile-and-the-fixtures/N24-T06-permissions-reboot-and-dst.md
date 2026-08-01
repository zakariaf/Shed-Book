# N24-T06 — Permissions, reboot and DST

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 6 of 8 |
| **Depends on** | N24-T05 |
| **Commit** | one commit · `feat(platform): reminder permissions, reboot and DST re-projection` |

## 1. Why this task exists

Three failures, one commit, and each of them is invisible until the night it matters.

**The permission.** Decision #65 defers `POST_NOTIFICATIONS` to *"the first time the user creates a
reminder"*. Read literally that is wrong here: reminder **rows** are created automatically inside the
lambing and treatment transactions (decision #63, T04), so the literal reading puts a system dialog on
screen at 03:24 during the first lambing — exactly the mid-season nag spec §5 forbids. The rule that
ships is a narrowing, agreed by `07 §11.5` and `08 §2.8`: **the notification permission is never
requested from a write path.**

**The store.** `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM` differ by one word and one of them gets the
app removed from Google Play. Play Console Help 9888170 restricts `USE_EXACT_ALARM` to alarm/timer and
calendar apps and states that apps outside those cases *"will be disallowed from publishing"*. Shed
Book is a record-keeping notebook that also sets reminders. **It does not qualify**, and the argument
that the colostrum window is time-critical is precisely the argument the policy anticipates and
refuses.

**The clocks.** Android destroys `AlarmManager` alarms on reboot, and the plugin's boot receiver is
**not** declared by the plugin — it must be in our manifest. And on 29 March 2026, `01:00–01:59` does
not exist; on 25 October it happens twice.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§2.8** (the narrowing of #65, and the three consequences) · **§2.9** (the exact-alarm trap, the two-row mode table, and why the answer is never cached) · **§2.10** (reboot on both platforms, and why the boot path is a backstop) · **§2.11** (the ambiguous hour, the three rules, and `matchDateTimeComponents` banned outright) · **§8.2** (who asks, and exactly when) · **§8.3** (the final Android permission set and the manifest block, verbatim) · §8.4 (the iOS key set) · §9 (`notify.use_exact_alarm` cannot see `AndroidManifest.xml`, and is not pretending to) | every line of the manifest, and every rule about asking |
| `docs/engineering/07-screens.md` | **§11.5** (the same narrowing, from the screen's side) · §11.2 (the fourth disclosure line and the "approximate" chip — **N25's**, not this task's) | which taps may request, and which task authors the copy |
| `docs/engineering/13-build-ci-release.md` | §2.2 (**G0**, and that a `tools:node="remove"` line may not be committed before it) · §3.1 (`targetSdk 36`, `coreLibraryDesugaring`) · §4.2 (the `android` job — **it does not exist until N31**) | what does and does not guard this diff |
| `docs/engineering/CONVENTIONS.md` | §4.7 (rule-id namespaces; `notify` was added in T02) · §5.3 (banned words) · R56 (the `[exempt]` allowlist) | naming, and the words the manifest comment may not use |
| `docs/engineering/05-domain-correctness.md` | §7.5 (`checkLocalWallTimeExists`, `WarningCode.timeDoesNotExistLocally`, and its exact message) · §2.9 (DST-1…DST-5) | the warning a wall-clock reminder raises, and where it already lives |
| `docs/engineering/12-testing.md` | §2.3 (the ambiguous hour; the `setUpAll` zone assertion) · §4.3 (`granted` and `exactAllowed` are plain fields — four permission states in four lines) · §11.2 (the `uk-zone` tag) | how the four permission states and the two DST dates are tested |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions — `flutter_local_notifications` **22.2.0**, desugaring **2.1.4** · **#65** (narrowed, never widened) · #48 · #121 (the two zone-pinned CI runs) | the decision this task narrows, and the two version numbers in the Gradle change |
| `epics/N02-g0-the-merged-manifest-record/epic.md` | the recorded permission set and the archived merger report | the set this manifest must match, exactly |
| `epics/N31-platform-artefacts-g1-g4-and-g5/epic.md` | T01 (`android/expected_permissions.txt` and the `tools:node="remove"` line) · T03 (`tool/assert_permissions.sh`, **G1**, the `android` job) | what is *not* yours to write, and what will assert this manifest later |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | permissions, receivers and the manifest are its subject |
| `shed-accessibility-and-copy` | when the app may ask for anything, and in what words |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/reminder_permissions_test.dart`
- **Test** — `'POST_NOTIFICATIONS is requested at the first reminder and never during launch'`
- **Why it is red today** — nothing requests the permission, and the framework's examples all request at launch.

```bash
fvm flutter test test/data/reminder_permissions_test.dart   # expect: failing, for the reason above
```

Sharpen it to assert the **narrowing**, which is what actually ships. The test name preserves decision
#65's wording; the property is `07 §11.5`'s and `08 §2.8`'s: *the permission is never requested from a
write path.* Concretely — `pumpApp`, commit a lambing through `beginLambing`, let `reconcile()` run,
then `expect(fake.calls, isNot(contains('requestAlerts')))` and
`expect(fake.calls, isNot(contains('requestExactAlarms')))`. Then call `requestAlerts()` directly and
assert it *does* reach the gateway — otherwise the test passes against a gateway that cannot request
at all.

**Green.** The minimum code that passes, and nothing beyond it — the request at first use, the two receivers, and the DST re-projection.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 0 — native | `android/app/src/main/AndroidManifest.xml` | **Edit.** Two `uses-permission` lines and **two receiver declarations** — the plugin declares neither, deliberately, since v16. `08 §8.3` prints the block; copy it |
| 0 — native | `android/app/build.gradle.kts` | **Already done at N02-T01 (2026-08-01).** `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` — `flutter_local_notifications` **22.2.0**'s documented minimum. It landed there because without it `flutter build appbundle --release` fails at `:app:checkReleaseAarMetadata` and G0 has no artefact to read. **Verify it is still present; do not add a second copy.** |
| 0 — native | `ios/Runner/AppDelegate.swift` | **Edit.** `UNUserNotificationCenter.current().delegate = self`, **and nothing more**. No notification entitlement, no `UIBackgroundModes`, no push capability (`08 §8.4`) |
| 3 — data | `lib/data/notification_scheduler.dart` | **Edit.** Bodies for `requestAlerts()`, `alertsGranted()`, `canBeExact()`, `requestExactAlarms()`. The resolver types are resolved against the **installed** 22.2.0 surface, in this one file |
| 7 — tests | `test/data/reminder_permissions_test.dart` | **New.** The anchor plus §5.4's cases |
| 7 — tests | `test/data/reminder_dst_test.dart` | **Edit.** DST-7 and DST-9 join T02's DST-8 and T04's DST-6 in the one `uk-zone` file |
| 7 — tests | `test/policy/permission_is_never_requested_from_a_write_path_test.dart` | **New.** Named for the **property**, not the file (`CONVENTIONS §4.1`). A source scan plus a widget-tier assertion |

**Not in this diff, and each for a different reason:**

| Not here | Where it belongs |
|---|---|
| `android/expected_permissions.txt` | N31-T01. It is G1's input and does not exist yet |
| The `INTERNET` `tools:node="remove"` line | N31-T01, gated on N02's recorded G0 evidence. `13 §2.2`: it may not be committed before G0 has run |
| Any `ACCESS_NETWORK_STATE` removal | Still unproven. **Do not commit it on faith** (`00-README` §4) |
| "Turn on alerts", the fourth disclosure line, the "approximate" chip | N25-T02. This task authors **no** ARB string |
| Settings ▸ Reminders' request tap | N29 |

### 5.2 The manifest, verbatim

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<!-- NOT USE_EXACT_ALARM. Play policy restricts it to alarm/timer and calendar
     apps; Shed Book is neither. See 08 §2.9. -->

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

The permission set this leaves, which N31's **G1** will assert against a real `.aab` (`08 §8.3`):

```
android.permission.POST_NOTIFICATIONS      <- flutter_local_notifications (merged)
android.permission.VIBRATE                 <- flutter_local_notifications (merged)
android.permission.RECEIVE_BOOT_COMPLETED  <- we add, HERE
android.permission.SCHEDULE_EXACT_ALARM    <- we add, HERE (NEVER USE_EXACT_ALARM)
android.permission.RECORD_AUDIO            <- record (merged, N15)
android.permission.WAKE_LOCK               <- wakelock_plus (merged, N29)
com.android.vending.BILLING                <- Play Billing (merged, N30)
```

The mode table, decided once per reconcile in T05 and passed down (`08 §2.9`):

| `canBeExact()` | Mode | AlarmManager | Fires in Doze |
|---|---|---|---|
| `true` | `AndroidScheduleMode.exactAllowWhileIdle` | `setExactAndAllowWhileIdle` | Yes |
| `false` | `AndroidScheduleMode.inexactAllowWhileIdle` | `setAndAllowWhileIdle` | Yes |

### 5.3 The details that are easy to get wrong

- **This manifest edit is unguarded on this branch.** `notify.use_exact_alarm` is a `check_policy` row
  over `.dart` files under `lib/` and `test/`; **`android/` is not a scanned root** (`08 §9`), and the
  `android` CI job that runs **G1** on a real `.aab` does not exist until **N31-T03**. So nothing in
  this pull request will catch a wrong permission line. Read the manifest diff by hand, twice, and say
  in the PR body that you did. Do **not** widen `check_policy.dart`'s roots to close the gap — G1 reads
  the *merged* manifest, which is the only artefact that tells the truth about what a plugin
  contributed.
- **`USE_EXACT_ALARM` is a removed app, not a lint warning.** It is granted automatically at install
  and cannot be revoked, which is exactly why Play restricts it. `SCHEDULE_EXACT_ALARM` is
  user-granted, denied by default for new installs targeting API 33+ on Android 14+, and we ship
  `targetSdk 36` — so we are squarely inside the denied-by-default regime and the inexact fallback is
  the normal case, not the edge case.
- **The plugin declares neither receiver.** Since v16 the receivers are the app's to declare. Miss them
  and reboot persistence silently stops working on Android — with no error, no log, and no test that
  can see it, because a `flutter test` process never reboots.
- **Android's reboot replay re-uses the schedule mode it persisted**, which may be stale if the
  exact-alarm permission changed while the phone was off. That is why the boot receiver is a
  **backstop** and `reconcile()` at next launch is the mechanism: a hostile OEM skin that never
  delivers `BOOT_COMPLETED` degrades to *"reminders resume when the shepherd next opens the app"*
  rather than *"reminders are gone"*.
- **`requestAlerts()` ships with no caller, and that is correct.** Its two call sites are N25-T02's
  *"Turn on alerts"* button and N29's Settings ▸ Reminders. A shepherd who only ever taps *lambing →
  twin → save* never sees a system dialog from this app. Ever.
- **There is no "we already asked" flag, no cooldown and no new `app_settings` column.** Because
  nothing is ever prompted automatically, there is no state to remember. `08 §2.8`: *"if you find
  yourself adding one, the prompt has escaped to an automatic path."* That sentence is the test.
- **`reconcile()` reads `canBeExact()` and never requests.** Requesting from a reconcile means a system
  Settings screen opening while the app is in the background, on a path with no user in front of it.
- **The exact-alarm upgrade path needs no receiver.** Granting sends the user to system Settings;
  returning produces `AppLifecycleState.resumed`, which is already reconcile call site #2, which
  re-asks `canBeExact()` and re-projects everything as exact. Registering
  `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` buys nothing over that and costs a receiver.
- **`matchDateTimeComponents` is banned outright.** A recurring notification's state lives in the OS
  rather than in SQLite, which contradicts *"assume the phone dies"*, and it drifts across DST. Every
  reminder in Shed Book is a one-shot row and the projection re-creates it.
- **Spring forward: `01:00–01:59` does not exist, and Dart hides it.** `DateTime(2026, 3, 29, 1, 30)`
  silently returns `02:30` — Dart breaking §12.4 on our behalf. The app **shows**
  `WarningCode.timeDoesNotExistLocally` — *"The clock skipped 01:30 that night (clocks went forward).
  Saved as 02:30."* — and stores the resolved instant. Never silently moved, never refused.
- **Autumn back: `01:00–01:59` happens twice, and there is deliberately no warning.** The displayed
  time still matches what the shepherd typed, so nothing was silently corrected from their point of
  view. The notification fires **once**, at whichever of the two 01:30s Dart chose, because
  `cancelAll()` + one row = exactly one request.
- **The Darwin resolver's type name is `08 §11` item 3 and is unresolved in the documents.** Note 06
  contradicts itself between its own §1.2 and §9. Resolve it against the installed 22.2.0 API surface
  on the day you write `requestAlerts()`. It is a compile error, not a silent bug — but do not copy
  either spelling from a document.
- **AGP's real floor is unverified** (`08 §11` item 15): §8.3 quotes 8.12.1 and 8.11.1 from two
  READMEs, and a README changes a floor without a changelog entry. The desugaring version **2.1.4** is
  from the installed plugin's README and is settled; read the AGP floors off the installed packages
  before the first release build and record what you find.
- **`minSdk` is not set from memory.** `13 §3.1` leaves it at `flutter.minSdkVersion` and requires the
  effective value to be **read out of the merged manifest at G0 and recorded** (`08 §11` item 14). Do
  not raise it here because a plugin changelog says to.
- **No `USE_FULL_SCREEN_INTENT`, no `FOREGROUND_SERVICE`, no location, no contacts, no calendar, no
  Bluetooth.** The permission set is closed and G1 will assert it exactly.
- **The DST cases must be tagged, or they pass for the wrong reason.** Under the runner's UTC, 29 March
  has no missing hour and 25 October has no repeated one, so an untagged case is green and empty. The
  file asserts its own zone in `setUpAll` — *a skipped safety test is a broken safety test.*

### 5.4 The full test set

`test/data/reminder_permissions_test.dart`

| Case | What it asserts |
|---|---|
| `'POST_NOTIFICATIONS is requested at the first reminder and never during launch'` | **The anchor**, as narrowed: launch + a committed lambing + a reconcile produce **zero** `requestAlerts` / `requestExactAlarms` entries, and a direct `requestAlerts()` does reach the gateway |
| `'a full lambing flow through pumpApp makes zero permission calls'` | The write path, end to end. `12 §4.3`: *"the assertion that matters is `expect(fake.calls, isNot(contains('requestAlerts')))` after a lambing commits"* |
| `'reconcile reads alertsGranted and canBeExact and requests neither'` | The reconcile path specifically — the one with no user in front of it |
| `'alerts denied leaves every reminder row intact and the OS list empty'` | `fake.granted = false`; the database is unchanged, `cancelAll` was called, `scheduled: 0` recorded |
| `'the four permission states each produce a defined projection'` | granted × exact, granted × inexact, denied × exact, denied × inexact — four lines, because `granted` and `exactAllowed` are plain fields on the fake |
| `'exact alarms revoked between two reconciles changes the mode on the second'` | The reason `canBeExact()` is not cached; the fake flips mid-test |
| `'no app_settings column records whether we have asked'` | Over the committed schema JSON. The column that must never exist |

`test/policy/permission_is_never_requested_from_a_write_path_test.dart`

| Case | What it asserts |
|---|---|
| `'requestAlerts is called from no file under lib/data/ and no repository'` | Source scan. Today it has **no** caller at all, and the test says so with the two future call sites named |
| `'USE_EXACT_ALARM appears nowhere in lib/, and SCHEDULE_EXACT_ALARM appears once in the manifest'` | Both halves — the Dart row `notify.use_exact_alarm` cannot see `android/`, so this test reads the manifest itself |
| `'the manifest declares both plugin receivers with all four boot actions'` | Text over `AndroidManifest.xml`. The silent-failure case, made loud |
| `'matchDateTimeComponents and AndroidScheduleMode.alarmClock appear nowhere'` | The two banned spellings, in one place |

`test/data/reminder_dst_test.dart` — `@Tags(['uk-zone'])`, `TZ=Europe/London`

| Case | What it asserts |
|---|---|
| `'DST-7: a tag_by reminder set to 01:30 on 29 March 2026 warns once and projects exactly one request'` | `checkLocalWallTimeExists` returns a single `WarningCode.timeDoesNotExistLocally`; the stored instant is the resolved `02:30`; the projection contains one entry for that row |
| `'DST-9: a tag_by reminder set to 01:30 on 25 October 2026 warns zero times and projects exactly one request'` | The repeated hour. Zero warnings — nothing was corrected from the shepherd's point of view — and one request, because `cancelAll()` + one row cannot produce two |
| `'a reconcile run at each of the two 01:30s on 25 October projects the row once each time, never twice'` | The double-fire fear, disproved at the reconcile tier |
| `'crossing the spring-forward re-projects every offset reminder at the same absolute instant'` | Reconcile before and after; `dueAt` is unchanged in epoch millis. Offset reminders are correct by construction and this is the case that says so |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The ARB rule binds this task negatively: it authors no string.** The permission copy is N25-T02's
  and N29's. A new ARB key in this diff means a prompt grew a screen it should not have.
- **The permission set changes here, and G0's record is the authority for what it may become.** N02
  recorded it; N31 will assert it. Anything not on `08 §8.3`'s list is a review stop.
- **`android/` and `ios/` appear in this diff — the only task in the epic where they do.** Read both
  by hand; no gate covers them on this branch.

## 7. Definition of Done

- [ ] `'POST_NOTIFICATIONS is requested at the first reminder and never during launch'` passes, and was seen to fail first for the stated reason
- [ ] never requested at launch
- [ ] the reboot receiver re-projects
- [ ] a DST transition re-projects and the test covers the ambiguous hour
- [ ] the permission set matches G0's record
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `USE_EXACT_ALARM` appears nowhere — in the manifest, in Dart, in a comment or in the commit message
- [ ] both plugin receivers are declared, with all four boot actions
- [ ] `requestAlerts()` has **no** caller in this commit, and the two future call sites are named in a comment
- [ ] no `app_settings` column, flag or cooldown records that we have asked
- [ ] DST-7 and DST-9 pass under `TZ=Europe/London`, and the file asserts its own zone
- [ ] `android/expected_permissions.txt`, the `tools:node="remove"` line and any `ACCESS_NETWORK_STATE` change are **absent** from this diff
- [ ] this task authors no ARB string

## 8. Verification

```bash
fvm flutter test test/data/reminder_permissions_test.dart
make check
make test
```

```bash
# The manifest, read by hand — nothing on this branch checks it for you.
grep -n 'uses-permission\|receiver\|action android:name' android/app/src/main/AndroidManifest.xml
grep -rn 'USE_EXACT_ALARM' android/ ios/ lib/ test/          # expect nothing, anywhere
grep -rn 'tools:node="remove"\|ACCESS_NETWORK_STATE' android/  # expect nothing (N31-T01, after G0)
grep -rn 'desugar_jdk_libs' android/app/build.gradle.kts       # expect 2.1.4

# The two spellings that undo the architecture.
grep -rn 'matchDateTimeComponents\|AndroidScheduleMode.alarmClock' lib/   # expect nothing

# The permission property, at both tiers.
fvm flutter test test/policy/permission_is_never_requested_from_a_write_path_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
git diff --stat -- lib/l10n/                                   # expect nothing
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(platform): reminder permissions, reboot and DST re-projection`
