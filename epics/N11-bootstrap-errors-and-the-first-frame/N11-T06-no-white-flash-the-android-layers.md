# N11-T06 — No white flash — the Android layers

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 6 of 9 |
| **Depends on** | N11-T05 |
| **Commit** | one commit · `fix(android): no white flash — all four launch layers` |

## 1. Why this task exists

The Android half of the four-layer configuration: the launch theme, the window
background, the `styles.xml` night variant and the activity's theme swap — every one of them the page
token's colour. Miss one and there is a white frame between the launcher and the app, which is the
first thing a shepherd sees at 3am.

`06 §9` draws the sequence: **OS window background → native launch screen → Flutter first frame →
first route.** The first two are before Dart runs, so there is no Dart-side fix — by the time
`main()` executes, the flash has already happened. That is why this task is native config and why
`00-README` §9 put the whole epic at step 4: *"the no-white-flash work touches native files you do
not want to revisit."*

It is also the first change to `android/` since N02, which makes it the first PR since then where the
`android` job's **G1** step is proving something new.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §9 (the four-layer diagram and the single constant) · §9.1 (**every Android file, printed**: `colors.xml`, `values/styles.xml`, `values-v31/styles.xml`, `MainActivity.kt`; the `values-night/` ban; the `SplashScreenDrawable` ban) · §9.3 (the Flutter layer) · §9.4 (`launch.colour_parity`, and what it asserts on the Android side) | every line of XML and Kotlin in this task |
| `docs/engineering/13-build-ci-release.md` | §3.1 (**the eight-entry permission set, and the manifest printed with its removal**) · §2.3 (G1 on the shipped AAB) · §4.3 (the `android` job) | what `AndroidManifest.xml` may and may not contain |
| `docs/engineering/08-platform-integration.md` | §8.3 (the final Android key set, including the two `flutter_local_notifications` receivers) · §2.9 (`SCHEDULE_EXACT_ALARM`, never `USE_EXACT_ALARM`) | what is already in the manifest and must survive your edit |
| `docs/engineering/02-state-di-navigation.md` | §8.3 (`android:enableOnBackInvokedCallback="true"`, and predictive back) | the one non-colour manifest attribute this task adds |
| `docs/design/indelible.md` | §2.2 (`--page`) · §5.2 (*"the first painted frame is `--page` with tonight's page already on it. This is a hard requirement, not a target"*) · §11 test 9 (cold launch recorded at 240 fps) | the colour, and the acceptance test |
| `epics/N02-g0-the-merged-manifest-record/` | the recorded G0 evidence | **the only authority for what may be in the permission list.** Read it before you touch the manifest |
| `docs/engineering/CONVENTIONS.md` | §4.7 (rule-id grammar — `launch.colour_parity`) · §5.3 (banned words) | **BINDING** on the rule id |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | `AndroidManifest.xml`, `styles.xml` and the launch theme are its subject |
| `indelible-design-system` | the page colour is a token and this is where it reaches the native layer |

Two auto-firing skills is the cap. `shed-dependencies-and-toolchain` is not reloaded; what it would
have supplied is stated as a hard floor instead: this edit may not disturb the AGP or `minSdk` values,
and G1 (the Android job) plus the merged-permission check stay green — both are commands in §8, not
assumptions.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/first_frame_parity_test.dart`
- **Test** — `'the Android launch colour equals the page token'`
- **Why it is red today** — `flutter create`'s launch theme is white and nothing checks it.

```bash
fvm flutter test test/design/first_frame_parity_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Read `test/design/wcag.dart`'s `launchSurface`
(which T04's ruling made equal to `nSurface04`), format it as the eight-character ARGB string Android
wants — `#FF` + the six hex digits, upper-case — and assert that
`android/app/src/main/res/values/colors.xml` declares `shed_surface_base` with **exactly** that
string. Then assert both `values/styles.xml` and `values-v31/styles.xml` reference
`@color/shed_surface_base` and contain **no** `#` literal at all, and that
`android/app/src/main/res/values-night/` does not exist. Parse the XML; do not `contains` the whole
file, or a commented-out line passes.

**Green.** The minimum code that passes, and nothing beyond it — all four Android layers set to the page colour, and a test that parses the XML rather
than trusting a screenshot.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

`00-README` §8's layer order does not reach native config at all — this task is entirely outside
`lib/`. There is no schema, no domain, no data, no wiring, no controller, no widget and no ARB entry.
Say so in the commit message, and say that the reason is that the first two layers of the launch
sequence run before Dart exists.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/design/first_frame_parity_test.dart` | **New. The anchor, written first.** T07 adds the iOS group and T08 adds the cross-platform assertion to this same file — it is one file, extended twice, not three files |
| 2 | `android/app/src/main/res/values/colors.xml` | **New or edited.** One entry: `shed_surface_base`, the eight-digit ARGB of the ruled page colour. The **only** place the hex is typed on Android |
| 3 | `android/app/src/main/res/values/styles.xml` | **Edited.** `LaunchTheme` and `NormalTheme`, both parented to `@android:style/Theme.Black.NoTitleBar`, both `windowBackground` → `@color/shed_surface_base`, plus `forceDarkAllowed=false` and the two `enforce*Contrast=false` rows. **This is the non-night folder and it must be dark anyway** |
| 4 | `android/app/src/main/res/values-v31/styles.xml` | **New or edited.** Android 12+ replaces `windowBackground` with the SplashScreen API, which cannot be opted out of: `windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon`, `windowSplashScreenAnimationDuration = 0` |
| 5 | `android/app/src/main/kotlin/**/MainActivity.kt` | **Edited.** Kill the Android 12+ splash exit fade — our splash and our first frame are the same solid field, so the fade is a crossfade between two identical images that costs a visible beat |
| 6 | `android/app/src/main/AndroidManifest.xml` | **Edited, minimally.** `android:enableOnBackInvokedCallback="true"` on `<application>` (`02 §8.3`). Read the whole file first: the removal line, the seven permissions and the two `flutter_local_notifications` receivers must all survive |
| 7 | `tool/check_policy.dart` | **Edited.** The `launch.colour_parity` row — `06 §9.4`'s, and **the one rule in the script that reads outside `lib/`**. The Android half lands here; T07 adds the iOS half |
| 8 | `test/policy/gate_rules_test.dart` | **Edited.** A `firesOn` entry for `launch.colour_parity`, or N03-T07's inventory assertion fails the build. Non-negotiable and in the same commit |
| 9 | `android/app/src/main/res/drawable/ic_splash_mono.xml` | **New if it does not exist.** `windowSplashScreenAnimatedIcon` needs a drawable; a monochrome mark on the page colour, or the Android 12 launcher supplies its own default and it will not be yours |

### 5.2 The files, in full

`06 §9.1` prints all four. Substitute the ruled colour from T04 — the values below carry the
pre-ruling hex and **must not be pasted unchanged**:

```xml
<!-- android/app/src/main/res/values/colors.xml -->
<resources>
    <color name="shed_surface_base">#FF0A0A0B</color>   <!-- = nSurface04, ruled at N11-T04 -->
</resources>
```

```xml
<!-- android/app/src/main/res/values/styles.xml — the NON-night folder.
     The launch background must be dark even when the phone is in light mode. -->
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:statusBarColor">@color/shed_surface_base</item>
        <item name="android:navigationBarColor">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:enforceStatusBarContrast">false</item>
        <item name="android:enforceNavigationBarContrast">false</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
```

```xml
<!-- android/app/src/main/res/values-v31/styles.xml — Android 12+ SplashScreen API -->
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/shed_surface_base</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/ic_splash_mono</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
```

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
```

The gate row, `06 §9.4`'s Android half:

```dart
// tool/check_policy.dart — `launch.colour_parity`.
// The ONE rule in this script that reads outside lib/. It parses nSurface04 out
// of lib/core/ui/primitives.dart and asserts every native declaration matches.
//  · values/colors.xml declares shed_surface_base with that exact ARGB string
//  · values/styles.xml and values-v31/styles.xml reference @color/shed_surface_base
//    and contain no `#` literal
//  · android/app/src/main/res/values-night/ does not exist
//  · AndroidManifest.xml contains no
//    io.flutter.embedding.android.SplashScreenDrawable meta-data
```

### 5.3 The details that are easy to get wrong

- **`values-night/` is the trap, and every Android guide walks you into it.** The standard dark-theme
  advice is to use `?android:attr/colorBackground` so the splash follows the system theme. For a
  dark-only app that is exactly backwards: a phone in **light** mode then launches **white**. `06
  §9.1` bans the folder outright and `launch.colour_parity` asserts it does not exist. If you find
  yourself creating one, you have re-derived the bug.
- **`values/styles.xml` is the non-night folder and it must still be dark.** Same reason. There is no
  variant; there is one theme and it is dark.
- **The Android 12+ SplashScreen API cannot be opted out of.** `windowBackground` stops being the
  launch surface at API 31, so `values-v31/styles.xml` is not an optimisation — without it, a phone
  on Android 12 or later shows the system default splash, which is your launcher icon on the system
  background colour. Two files, both required, and the v31 one is the one people forget because their
  test device is old.
- **`windowSplashScreenAnimationDuration = 0` is not the same as killing the exit fade.** The
  duration governs the *entry* animation; the exit transition is a separate handoff that Android runs
  when the app takes over, and it is the one that produces a visible beat between two identical solid
  fields. `MainActivity.kt`'s `setOnExitAnimationListener { view -> view.remove() }` is what removes
  it. Do both.
- **`io.flutter.embedding.android.SplashScreenDrawable` meta-data must not be present.** It has been
  deprecated since Flutter 2.5 and the migration doc says leaving it can cause a **crash**. Flutter
  already holds the Android launch screen until it draws the first frame, so there is no gap to fill
  — only gaps to avoid reintroducing. The gate asserts its absence.
- **Do not adopt `flutter_native_splash`.** It is on decision-record §5.3's not-used list, it would
  own these files as a second source of truth, and `06 §9.3` notes its maintainer has been publicly
  seeking a new owner since March 2026. And do not add a minimum splash duration: the whole point is
  that there is nothing to look at.
- **`AndroidManifest.xml` is the file G1 exists to police, and you are editing it.** Read `13 §3.1`
  and N02's recorded G0 evidence **before** you open it. The `<uses-permission
  android:name="android.permission.INTERNET" tools:node="remove" />` line, the two `we add`
  permissions, and the two `flutter_local_notifications` receivers in `<application>` must all
  survive your one-attribute edit. The plugin has declared neither receiver itself since v16, so
  deleting them silently loses every reminder across a reboot — and no test in the suite catches it.
  If your diff on this file is more than one line, stop.
- **`enableOnBackInvokedCallback` is a manifest attribute, not a permission, and it belongs here
  rather than in a routing epic.** `02 §8.3`: predictive back decides `canPop` *ahead of time*
  because the animation starts before the gesture commits. Adding it in a screen epic means every
  back gesture until then uses the legacy path and the transition changes under you later.
- **Read the colour from the token; never type the hex twice.** The value lives in
  `lib/core/ui/primitives.dart` and reaches Android through exactly one string in `colors.xml`. Both
  `styles.xml` files reference `@color/shed_surface_base` — a literal `#…` in either is what
  `launch.colour_parity` fails on, and it is how the two platforms drift.
- **Android wants `#AARRGGBB`, eight digits, alpha first.** `#FF0A0A0B`, not `#0A0A0BFF` and not
  `#0A0A0B`. A six-digit value is legal XML and means fully opaque, so it *works* — and then the
  parity gate's string comparison fails and you spend twenty minutes on a passing app.
- **The gate row and its proving case land together.** N03-T07's inventory assertion fails any rule
  id with no `firesOn` entry **and** any `firesOn` entry with no rule. Both halves, one commit.
- **A screenshot test cannot catch this.** `06 §9.4` says it outright: the flash is on the native
  side, before Flutter runs, so the framework never sees the frame. The gate proves the *config*; a
  human in a dark room proves the *result*. Both are in the Definition of Done and neither replaces
  the other.
- **`minSdk`, `targetSdk`, AGP and Java are not yours to move here.** `13 §3.1` fixes them —
  `minSdk = 24`, `targetSdk = compileSdk = 36`, Java 17, AGP ≥ 8.12.1,
  `coreLibraryDesugaringEnabled = true` with `desugar_jdk_libs 2.1.4`. If the build complains, the
  answer is in that section, not in a version bump in this commit.

### 5.4 The full test set

`test/design/first_frame_parity_test.dart` — the Android group. This file is created here, extended
by T07 with an iOS group, and completed by T08 with the cross-platform assertion. It reads files off
disk as text; it pumps nothing.

| Case | What it asserts |
|---|---|
| `'the Android launch colour equals the page token'` | **The anchor.** `colors.xml`'s `shed_surface_base` equals `#FF` + `launchSurface`'s six hex digits, upper-case, parsed out of the XML rather than string-matched over the file |
| `'both styles.xml files reference the colour resource and contain no hex literal'` | `values/styles.xml` and `values-v31/styles.xml` each contain `@color/shed_surface_base` and match no `#[0-9A-Fa-f]{6,8}` anywhere. Catches the "just this once" literal |
| `'LaunchTheme sets windowBackground on v-default and windowSplashScreenBackground on v31'` | The two APIs are different keys in different folders. Asserting one and not the other is how a phone on Android 13 shows the system splash while the test is green |
| `'windowSplashScreenAnimationDuration is 0 and an animated icon is declared'` | Both, because a declared duration with no icon falls back to the launcher icon on the system background |
| `'no values-night directory exists'` | `Directory('android/app/src/main/res/values-night').existsSync()` is false. The single most likely regression in this file set |
| `'AndroidManifest.xml declares no SplashScreenDrawable meta-data'` | The deprecated key that can crash |
| `'AndroidManifest.xml still removes INTERNET and still declares the two reminder receivers'` | A regression guard on the file this task edits, keyed to `13 §3.1` and `08 §8.3`. **The test that catches a careless manifest edit before G1 does, in seconds instead of in a twelve-minute AAB build** |
| `'enableOnBackInvokedCallback is true on the application element'` | `02 §8.3` |
| `'MainActivity removes the splash exit animation above API 31'` | Source-text over the Kotlin: `setOnExitAnimationListener` present, inside an SDK-version guard |

`test/policy/gate_rules_test.dart` gains:

| Case | What it asserts |
|---|---|
| `'launch.colour_parity fires when colors.xml disagrees with nSurface04'` | The planted-violation case N03-T07's inventory assertion requires |
| `'launch.colour_parity fires when a values-night directory is planted'` | The second half of the rule, proved separately because it is a different check |

**Nothing in this task is time-shaped**, so no `test/domain/uk_zone/` case and no `@Tags(['uk-zone'])`.

## 6. Constraints that bind this task

- **3am** — this is the fifteen-second clause at its most literal: the first thing a shepherd sees.
  `indelible.md` §5.2 calls it *"a hard requirement, not a target."* No interactive element is added
  here, so the 64 × 64 floor and the gesture ban do not bite — but the 18 px floor and dark-only do,
  through the colour.
- **Offline** — no network path may be added. G2 and G3 stay green, and **the permission set never
  changes without G0's recorded evidence.** This is the task where that sentence is not decorative:
  you are editing the file G1 reads.
- **Irreversible in claim** — a permission that reaches a shipped artefact changes what the product
  may say about itself, and three screens' copy with it. Diff `AndroidManifest.xml` line by line
  before committing.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the Android launch colour equals the page token'` passes, and was seen to fail first for the stated reason
- [ ] all four Android layers carry the same colour
- [ ] the value is read from the token, and the test compares the parsed XML against it
- [ ] watched on a real device, not only in a test
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `android/app/src/main/res/values-night/` does not exist, and no `SplashScreenDrawable` meta-data is declared
- [ ] the hex appears exactly once in `android/` — in `colors.xml` — and both `styles.xml` files reference the resource
- [ ] the `AndroidManifest.xml` diff is **one attribute**, and the `INTERNET` removal, the seven permissions and the two `flutter_local_notifications` receivers are all still present
- [ ] `launch.colour_parity` exists in `tool/check_policy.dart` **and** has its `firesOn` entry in `test/policy/gate_rules_test.dart`, in this commit
- [ ] the `android` CI job is green and its G1 step reports the permission set unchanged
- [ ] a cold launch on a real Android phone, in a dark room, shows no white frame between the launcher and the first Flutter frame

## 8. Verification

```bash
fvm flutter test test/design/first_frame_parity_test.dart
fvm flutter test test/policy/gate_rules_test.dart
dart tool/check_policy.dart          # launch.colour_parity now has something to read
make check
make test
```

Then the two things a test cannot do:

```bash
# 1. Build the artefact CI will build, and read the permissions off it yourself.
fvm flutter build appbundle --release --build-number=0
bash tool/assert_permissions.sh          # G1, locally, before the pipeline says it

# 2. Watch it. In a dark room. On a real phone, not an emulator — the emulator's
#    window compositor does not reproduce the handoff.
fvm flutter install --release
#    Cold-launch from the launcher five times. If you see a pale frame once,
#    it is there every time and you were lucky the other four.
#    indelible.md §11 test 9 records this at 240 fps; a phone slow-motion
#    camera pointed at a second phone is enough to settle an argument.
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `fix(android): no white flash — all four launch layers`
