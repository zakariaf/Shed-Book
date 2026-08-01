# N31-T02 — Android build configuration

| | |
|---|---|
| **Epic** | [N31 — Platform artefacts, G1, G4 and G5](epic.md) · `00-README` §9 step 12 (1 of 3) |
| **Task** | 2 of 4 |
| **Depends on** | N31-T01 |
| **Commit** | one commit · `feat(android): explicit SDK levels, desugaring and the two receivers` |

## 1. Why this task exists

`targetSdk` / `compileSdk` 36, an **explicit** `minSdk` 24, Java 17, core-library
desugaring, and the two receivers reminders need. Explicit rather than inherited, because an inherited
`minSdk` moves under you when a plugin bumps its own.

Two consequences that are not obvious from the diff. `13 §3.1`: *"A `minSdk` that moves because a
plugin bumped its own is a silent change to who can install the app"* — nobody is notified, least of
all the shepherd on the three-year-old phone who stops receiving updates. And `08 §2.10`: the
`flutter_local_notifications` plugin *"has declared neither receiver itself since v16"*, so omitting
them silently loses **every reminder across a reboot**, with no error, no log line and no way to
notice until a colostrum reminder does not arrive.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §3.1 | `targetSdk`/`compileSdk` 36 and the Play dates behind them, Java 17, AGP ≥ 8.12.1, `desugar_jdk_libs` 2.1.4, the AAB-not-APK rule, and the sentence that makes `minSdk` explicit |
| `docs/engineering/13-build-ci-release.md` | §2.2 | the row of G0's table that recorded the **effective** `minSdk` off the merged manifest — the number this task writes down |
| `docs/engineering/13-build-ci-release.md` | §9.2 | the signing block — **N32-T01's**, deliberately not written here |
| `docs/engineering/08-platform-integration.md` | §8.3 | the Gradle floors table with its *Unverified* AGP row, and both receiver declarations printed in full |
| `docs/engineering/08-platform-integration.md` | §2.9 | `SCHEDULE_EXACT_ALARM` versus `USE_EXACT_ALARM`, and why `targetSdk 36` puts this app inside the denied-by-default regime |
| `docs/engineering/08-platform-integration.md` | §2.10 | reboot persistence: which three intent actions the boot receiver needs and what happens without them |
| `docs/research/00-tech-decisions.md` | §5.1 | `flutter_local_notifications` **22.2.0**, `share_plus` **13.3.0** — the two packages whose READMEs set the floors — and the rule that no version comes from anywhere else |
| `docs/research/00-tech-decisions.md` | §2 K #87, #127 | one binary, no flavors; ship an AAB, never a fat APK |
| `docs/engineering/06-design-system.md` | §9.1 | `MainActivity.kt` and the splash-exit listener — **N11-T06's**, already merged; read it, do not re-edit it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the Gradle configuration and the receivers |
| `shed-dependencies-and-toolchain` | the SDK levels are pinned facts like every other version |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/android_config_test.dart`
- **Test** — `'minSdk is declared explicitly as 24 and the two receivers are registered'`
- **Why it is red today** — the generated Gradle files carry Flutter's defaults and no receivers.

```bash
fvm flutter test test/policy/android_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the explicit configuration and the assertion that parses it. The assertion reads
`android/app/build.gradle.kts` as text and refuses the expression `flutter.minSdkVersion`, then reads
`android/app/src/main/AndroidManifest.xml` and requires both receiver class names by their fully
qualified spellings.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. The one
duplication worth folding is the manifest-file list: this file and
`test/policy/g0_recorded_test.dart` both name the three source-set manifests. Leave both copies —
three string constants in two files is cheaper than a `test/support/` helper whose second caller does
not know that `src/profile` is the one people forget.

## 5. What you build

### 5.1 The files this task touches, in order

`00-README` §8's layer order does not apply — no layer is reached. Say so in the commit message. The
order below is the one that makes the diff readable: the file that decides *who can install the app*
first, the file that decides *whether reminders survive a reboot* second.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/android_config_test.dart` | **New, written first** (§4). `@Tags(['policy'])` then a bare `library;`, above every import. Reads three files as text: the two Gradle files and `src/main`'s manifest |
| 2 | `android/app/build.gradle.kts` | **Edited.** `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` as a literal, `compileOptions` at Java 17 with `isCoreLibraryDesugaringEnabled = true`, the Kotlin JVM target at 17, and one `coreLibraryDesugaring(...)` dependency line |
| 3 | `android/settings.gradle.kts` | **Edited.** The Android Gradle Plugin version in the `plugins { }` block, raised to the floor `08 §8.3` records — and re-read off the installed `share_plus` 13.3.0 and `flutter_local_notifications` 22.2.0 first, because both floors are README numbers |
| 4 | `android/app/src/main/AndroidManifest.xml` | **Edited, `<application>` block only.** The two `flutter_local_notifications` receivers. T01 owned the `<uses-permission>` block in the previous commit; this commit must not touch those lines |
| 5 | `android/gradle/wrapper/gradle-wrapper.properties` | **Edited only if** the AGP version raised in step 3 requires a newer Gradle distribution. The build tells you, by name and version, before it tells you anything else |
| 6 | `docs/engineering/08-platform-integration.md` | **Edited, one row.** §8.3's AGP row is marked *Unverified — "both are README numbers, and a README changes a floor without a changelog entry."* You are about to read them off the installed packages. Record the answer and strike the *Unverified* marker; leave the reasoning |

Nothing under `lib/`, nothing under `ios/`, no `pubspec.yaml` and no lockfile churn.

### 5.2 `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "…"                 // fixed at N00-T01. Do not touch.
    compileSdk = 36                 // 13 §3.1 — Play requires API 36 for new apps and
                                    // updates from 31 August 2026 (extensions to 1 November).
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // flutter_local_notifications 22.2.0
    }

    kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }

    defaultConfig {
        applicationId = "…"         // fixed at N00-T01 and frozen by both stores. Do not touch.
        minSdk = 24                 // EXPLICIT. 13 §3.1; the value G0 read off the merged
                                    // manifest and recorded in 13 §2.2. Never flutter.minSdkVersion.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**`kotlin { compilerOptions { … } }` versus `kotlinOptions { jvmTarget = "17" }`.** Both spellings
exist in the wild; the Kotlin Gradle Plugin deprecated the second. **Keep whichever form the 3.44.8
template generated and change only the version** — swapping the block shape is a second, unrelated
change hiding inside a version bump, and if it goes wrong the error message is about a JVM target
mismatch rather than about the block you rewrote.

### 5.3 The two receivers

`08 §8.3`'s, verbatim, inside the existing `<application>` element:

```xml
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

Four actions, not one. `BOOT_COMPLETED` is the standard one; `MY_PACKAGE_REPLACED` is what makes
reminders survive an app **update**, which happens far more often than a reboot; the two
`QUICKBOOT_POWERON` actions are the OEM fast-boot equivalents on HTC-derived skins, where a "restart"
never emits `BOOT_COMPLETED` at all. Copy them from `08`, never from a blog post — `13 §3.1` says so
in the manifest fragment it deliberately truncates.

### 5.4 The details that are easy to get wrong

- **`minSdk = 24` is a *recorded* number, not a remembered one.** `13 §3.1` gives 24 as
  `flutter_local_notifications`' floor and the highest in the plugin set, and then refuses to let you
  set it from that: *"read the effective value out of the merged manifest during G0, record it in
  §2.2's table, and set it explicitly."* N02-T01 did the reading. **Open `13 §2.2` row 4 and use that
  number.** If it is not 24, the doc set is wrong and `00-README` §10's amendment rule fires — a
  disagreement here is not a rounding error, it is a different set of phones.
- **Enabling desugaring without the dependency line fails the build; adding the dependency without
  the flag does nothing.** They are two halves of one setting in two different blocks of the same
  file, and reviewers routinely see one and assume the other. The version is **2.1.4** and it comes
  from `08 §8.3` (which reads it off `flutter_local_notifications` 22.2.0's README) — not from a
  Stack Overflow answer, not from the AGP release notes.
- **Java 17 is asserted in three places and they must agree**: `sourceCompatibility`,
  `targetCompatibility`, and the Kotlin JVM target. CI's `actions/setup-java@v5` with
  `java-version: '17'` is a fourth. A mismatch does not say "you set two different versions" — it
  says *"Inconsistent JVM-target compatibility detected"*, which sends people to the wrong file. The
  test asserts all three in one case so the failure message names which one drifted.
- **AGP ≥ 8.12.1 is `share_plus`'s floor, above `flutter_local_notifications`' 8.11.1** — and `08 §8.3`
  marks the row **Unverified**, because *"both are README numbers, and a README changes a floor
  without a changelog entry."* Read them off the installed 13.3.0 and 22.2.0 before you set it. If the
  real floor is higher, raise it and record the reading; if it is lower, keep 8.12.1 and record that
  too. Do not raise AGP beyond what is needed to satisfy the floor: a newer AGP is a newer Gradle is a
  slower cold CI build, on the job that is already the slowest in the matrix.
- **`USE_EXACT_ALARM` must appear nowhere, and this test is the only mechanical thing that can see
  `android/`.** `08 §9` is explicit: `check_policy.dart`'s `notify.use_exact_alarm` row catches the
  string in **Dart** and cannot read `AndroidManifest.xml`, and the instruction is *not* to widen the
  gate's roots — G1 on the merged manifest is what actually keeps it out of a release. Between the
  two sits this file, which reads the source manifests directly. Assert the absence in all three
  source sets.
- **`targetSdk = 36` is what puts the app inside the denied-by-default exact-alarm regime** (`08 §2.9`).
  That is a settled consequence, not a reason to reconsider the level: `NotificationScheduler.canBeExact()`
  is read once per reconcile and the mode is chosen from the answer. Nothing in this task caches a
  capability flag, and nothing in this task may add a permission to avoid the check.
- **The release build type still points at the debug signing config, and that is correct here.**
  `13 §9.2`'s `signingConfigs` block plus `android/key.properties` is **N32-T01's**. Adding it now
  means either a keystore in the repository or a build that fails in CI on a missing properties file
  — and it changes not one byte of the merged manifest, so it buys this epic nothing.
- **No product flavors, no `--split-per-abi`, no fat APK.** Decision #87 is one binary; decision #127
  ships an AAB. A flavor axis added here multiplies every later Gradle question by two and gives Play
  App Signing a second artefact to be confused by.
- **Do not touch `MainActivity.kt`.** `06 §9.1`'s splash-exit listener landed at N11-T06 and the
  first-frame parity gate holds it. A Gradle commit that also edits an Activity is two commits.
- **Do not re-touch T01's `<uses-permission>` lines.** They are the previous commit's, and this commit
  edits the `<application>` element of the same file. `git diff HEAD~1 -- android/app/src/main/AndroidManifest.xml`
  before committing: the only added lines should be inside `<application>`.
- **Both receivers carry `android:exported="false"`.** They are woken by the system through an
  explicit component name and by the plugin's own alarms; exporting them lets any app on the phone
  fire the reminder receiver. On `targetSdk` 31+ an `exported` attribute is mandatory on any component
  with an intent filter, so omitting it is a build failure — but the value being `false` is the part
  that matters and the part a copied snippet gets wrong.
- **Parsing Gradle Kotlin DSL with a regular expression is fine here and only here.** The test asserts
  the presence of literal assignments in one file, not the semantics of a build. Match
  `minSdk\s*=\s*24` and separately refuse `minSdk\s*=\s*flutter\.minSdkVersion`; asserting only the
  first would pass on a file that carries both, which is exactly what a half-finished edit leaves
  behind. Strip `//` comments before matching, or a commented-out old line satisfies the assertion.

### 5.5 The full test set

`test/policy/android_config_test.dart` — one file, eight cases, reading three files as text.

| Case | What it holds |
|---|---|
| `'minSdk is declared explicitly as 24 and the two receivers are registered'` | **the anchor.** The literal, and both receiver class names by their fully qualified spellings |
| `'minSdk is never the inherited flutter.minSdkVersion expression'` | the half-finished edit that leaves both lines in the file |
| `'compileSdk and targetSdk are both 36'` | Play's requirement for new apps and updates from 31 August 2026, in one case so the failure names which of the two moved |
| `'core library desugaring is enabled and desugar_jdk_libs is 2.1.4'` | both halves of one setting, in two blocks — and the version, which is `flutter_local_notifications` 22.2.0's minimum |
| `'Java 17 is set for source, target and the Kotlin JVM target'` | the three places, in one case, so the message names the one that drifted |
| `'the boot receiver declares BOOT_COMPLETED, MY_PACKAGE_REPLACED and both QUICKBOOT_POWERON actions'` | update survival and the OEM fast-boot skins — the three actions that are not `BOOT_COMPLETED` |
| `'both receivers are exported false'` | a copied snippet that exports them, and the `targetSdk` 31+ requirement to state it at all |
| `'USE_EXACT_ALARM appears in no source-set manifest and no Gradle file'` | the Play-policy rejection `check_policy.dart` structurally cannot see |
| `'no product flavor and no signing config are declared in app/build.gradle.kts'` | decision #87, and the scope boundary with N32-T01 |
| *drill, not a case* | replace `minSdk = 24` with `minSdk = flutter.minSdkVersion`, run the anchor | the inherited-value case fires, not just the literal one |
| *drill, not a case* | delete the boot receiver's `MY_PACKAGE_REPLACED` action, run the anchor | the four-action assertion is real and not a `contains` on the element |

**Nothing in this task is time-shaped.** It asserts text in three files; no instant is computed,
stored or formatted, so there is no `test/domain/uk_zone/` case to add. The **behaviour** this
configuration enables is very much time-shaped, and it is tested where it lives:
`test/data/reminder_dst_test.dart`'s DST-7 and DST-9 cases put a `tag_by` reminder at **01:30** on
both the spring-forward and the clocks-back night (`08 §2.11`), tagged `uk-zone` and run under
`TZ=Europe/London`. Those cases arrived with the reminders in N24; this commit is what lets the
projection they assert survive a reboot.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. `coreLibraryDesugaring` is a compile-time artefact and adds nothing to the merged manifest; if G1 goes red after this commit, something else changed.
- **No version comes from anywhere but decision-record §5** — including `desugar_jdk_libs` 2.1.4, and including AGP, whose floor `08 §8.3` records and marks unverified. Reading a floor off an installed package is verification; reading it off a memory is not.
- **`USE_EXACT_ALARM` is a store rejection** (`08 §2.9`), and `13 §12` item 1 makes reading the shipped permission list by hand a permanent release-checklist item partly because of it.
- **Signing is N32-T01's** (`13 §9.2`). A keystore, a `key.properties` reference or a `signingConfigs` block in this commit is scope this task does not have.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'minSdk is declared explicitly as 24 and the two receivers are registered'` passes, and was seen to fail first for the stated reason
- [ ] `minSdk` is explicit and matches G0's effective value
- [ ] desugaring is enabled
- [ ] both receivers registered
- [ ] no `NSAppTransportSecurity` equivalent leniency anywhere
- [ ] `compileSdk` and `targetSdk` are both 36, and the AGP floor was read off the installed packages rather than remembered
- [ ] `USE_EXACT_ALARM` appears in no manifest and no Gradle file
- [ ] the commit adds no `signingConfigs` block and no product flavor
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/android_config_test.dart
fvm flutter build appbundle --release
grep -rn 'USE_EXACT_ALARM' android/ || echo "clean"
git diff HEAD~1 --stat -- android/app/src/main/AndroidManifest.xml
make check
make test
```

The second command must succeed — a desugaring flag with no dependency line, or a Java-target
mismatch, fails here and nowhere else. The third must print `clean`. The fourth must show only the
`<application>` block growing; T01's permission lines were the previous commit's.

Then read the effective `minSdk` back out of the artefact you just built, which is the only place it
is true:

```bash
java -jar bundletool.jar dump manifest \
  --bundle build/app/outputs/bundle/release/app-release.aab > merged-manifest.xml
tr '<' '\n' < merged-manifest.xml | grep '^uses-sdk'
```

It must print the number in `13 §2.2` row 4 and in `build.gradle.kts`. Three places, one number.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(android): explicit SDK levels, desugaring and the two receivers`
