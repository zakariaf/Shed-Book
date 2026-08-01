# N11-T07 — No white flash — the iOS layers

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 7 of 9 |
| **Depends on** | N11-T06 |
| **Commit** | one commit · `fix(ios): no white flash — all four launch layers` |

## 1. Why this task exists

The iOS half: the launch storyboard's background, `Info.plist`'s appearance key, the
window's background colour and the root view controller's. Same rule, different four files.

One missed layer shows as a white flash between the springboard and the first frame — the exact
failure this requirement exists to prevent, and the one a simulator screenshot most often misses.

There is **no `colors.xml` equivalent on iOS**, so the same three components are typed in three
places and the parity gate is the only thing keeping them equal (`06 §9.2`). That is the structural
difference from T06, and it is why T08 exists at all.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §9 (the four-layer diagram) · §9.2 (**every iOS file, printed**: the three `Info.plist` keys with the 3.44 `UIApplicationSceneManifest` verbatim, the `LaunchScreen.storyboard` colour element, the `Main.storyboard` one people forget) · §9.4 (`launch.colour_parity`'s iOS half, **and the note that it has never been run**) | every key, every float |
| `docs/engineering/13-build-ci-release.md` | §3.2 (the iOS key table: three usage strings, one appearance key, and **the four things that must not be present**) · §2.7 (G5, honestly) · §4.3 (the `NSAppTransportSecurity` grep in the `gate` job) | what `Info.plist` may and may not contain |
| `docs/engineering/08-platform-integration.md` | §8.4 (the final iOS key set, the three usage strings verbatim, and why `UIFileSharingEnabled` is **not** set) | the keys already in the file that must survive your edit |
| `docs/engineering/REFERENCES.md` | §22 D10 (**the iOS half of `launch.colour_parity` has not been run**; compare to within 1/255; if brittle, downgrade *that one assertion* to the release checklist rather than weakening the rest) | the escape hatch, and its exact shape |
| `docs/design/indelible.md` | §2.2 (`--page`) · §5.2 (*"no white flash, ever, on either platform"*) · §11 test 9 | the colour and the acceptance test |
| `epics/N11-bootstrap-errors-and-the-first-frame/N11-T04-nighterrorpanel-and-the-p14-ruling.md` | §5.3 | the ruled hex, and the recomputed storyboard floats |
| `docs/engineering/CONVENTIONS.md` | §4.7 · §5.3 | **BINDING** on the rule id and the banned words |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | `Info.plist`, the storyboard and the appearance key |
| `indelible-design-system` | the same page token, on the other platform |
| `shed-release` (manual, `/shed-release`) | invoke it when deciding whether the fragile storyboard assertion is downgraded to the release checklist — that list is its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/first_frame_parity_test.dart`
- **Test** — `'the iOS launch colour equals the page token and the appearance key forbids light'`
- **Why it is red today** — the generated storyboard is white and the appearance key is unset.

```bash
fvm flutter test test/design/first_frame_parity_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Parse both storyboards' root-view `<color
key="backgroundColor" …>` elements, read `red` / `green` / `blue` as doubles, and compare each to the
corresponding channel of `launchSurface` **to within 1/255** — the storyboard stores components as
floats and an exact string comparison is the brittleness `06 §9.4` warns about. Then assert
`Info.plist` contains `UIUserInterfaceStyle` = `Dark`, `UILaunchStoryboardName` = `LaunchScreen`, and
a `UIApplicationSceneManifest` whose `UISceneStoryboardFile` is `Main`. Two storyboards, three keys,
one tolerance.

**Green.** The minimum code that passes, and nothing beyond it — the four iOS layers and the parse-based assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

Entirely outside `lib/`, exactly as T06 was. No schema, no domain, no data, no wiring, no controller,
no widget, no ARB — say so in the commit message, with the same reason: the first two layers of the
launch sequence run before Dart exists.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/design/first_frame_parity_test.dart` | **Extended** with the iOS group. T06 created the file; T08 adds the cross-platform assertion. One file, three groups |
| 2 | `ios/Runner/Info.plist` | **Edited.** `UIUserInterfaceStyle` = `Dark`. Confirm `UILaunchStoryboardName` and `UIApplicationSceneManifest` are both present and untouched — **they are different keys naming different storyboards** |
| 3 | `ios/Runner/Base.lproj/LaunchScreen.storyboard` | **Edited.** The root view's `backgroundColor` as a literal sRGB triplet. Delete the template's `LaunchImage` image view or replace it with a small monochrome mark |
| 4 | `ios/Runner/Base.lproj/Main.storyboard` | **Edited.** The `FlutterViewController`'s view, same three floats. **This defaults to white in the Flutter template** and it is the layer people forget |
| 5 | `tool/check_policy.dart` | **Edited.** `launch.colour_parity`'s iOS half, added to the row T06 created |
| 6 | `test/policy/gate_rules_test.dart` | **Edited.** A `firesOn` case for the iOS half, in this commit |
| 7 | `docs/perf/measurements.md` **or** the release checklist | **Edited only if** the storyboard-float assertion proves brittle and is downgraded. `REFERENCES` §22 D10 says downgrade *that one assertion*, in writing, and keep the rest — never weaken silently |

### 5.2 The three components, in three places

`#0A0A0B` — the hex T04 ruled — is R=10, G=10, B=11 in decimal. As storyboard floats:

| Channel | Decimal | Float |
|---|---|---|
| `red` | 10 / 255 | `0.039216` |
| `green` | 10 / 255 | `0.039216` |
| `blue` | 11 / 255 | `0.043137` |
| `alpha` | — | `1` |

**`06 §9.2` prints `0.043137` / `0.050980` / `0.054902`. Those are `#0B0D0E`'s and they are the
pre-ruling values.** T04's amendment replaces them; if the document you are reading still shows them,
T04 did not finish and this task is blocked on it.

```xml
<!-- ios/Runner/Info.plist — three keys, none of them optional -->
<key>UIUserInterfaceStyle</key>
<string>Dark</string>                     <!-- also darkens share sheets, alerts, any IME -->
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>             <!-- the launch screen -->
<key>UIApplicationSceneManifest</key>          <!-- verbatim from the 3.44 template -->
<dict>
  <key>UIApplicationSupportsMultipleScenes</key><false/>
  <key>UISceneConfigurations</key>
  <dict>
    <key>UIWindowSceneSessionRoleApplication</key>
    <array><dict>
      <key>UISceneClassName</key><string>UIWindowScene</string>
      <key>UISceneConfigurationName</key><string>flutter</string>
      <key>UISceneDelegateClassName</key>
      <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
      <key>UISceneStoryboardFile</key><string>Main</string>   <!-- the app window -->
    </dict></array>
  </dict>
</dict>
```

```xml
<!-- ios/Runner/Base.lproj/LaunchScreen.storyboard AND Main.storyboard.
     Same element, same three floats, two files. Never a named UIColor. -->
<view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
  <color key="backgroundColor" red="0.039216" green="0.039216" blue="0.043137"
         alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
</view>
```

### 5.3 The details that are easy to get wrong

- **`Main.storyboard` is the layer people forget, and it is the one that produces the flash.** It
  defaults to **white** in the Flutter template, and it is the surface shown in the gap between the
  launch screen tearing down and Flutter's first frame. On a fast device the gap is invisible; on a
  cold three-year-old phone in a shed it is a white blink. `06 §9.2` calls it out for exactly this
  reason. Two storyboards, both edited, or the work is not done.
- **`UILaunchStoryboardName` and `UISceneStoryboardFile` are different keys naming different
  storyboards.** The UIScene migration *adds* the second; it does not replace the first. The 3.44
  template ships both, alongside a `Runner/SceneDelegate.swift` that is an empty subclass of
  `FlutterSceneDelegate`. **Deleting the wrong key produces a white launch screen *and* an App Store
  rejection**, and you find out weeks later. After the first `flutter build ios` on this toolchain,
  diff `Info.plist` and assert both survived — the tooling rewrites it.
- **Never a named `UIColor`.** `systemBackgroundColor` and its friends resolve *per appearance* and
  will hand you white on a phone in light mode. `UIUserInterfaceStyle = Dark` makes that unlikely,
  not impossible — and "unlikely" is not the standard for the first painted frame. Literal sRGB
  components, in both storyboards.
- **`UIUserInterfaceStyle = Dark` does more than the app window.** It also darkens share sheets,
  alerts and any IME. That is a feature here — the share sheet is on the export path and a white
  sheet at 3am is the same flashbang the whole theme exists to avoid — and it is also why the key
  cannot be scoped narrower.
- **The float comparison is the fragile part of this gate and `06 §9.4` says so in advance.**
  Compare to within **1/255**. If parsing storyboard XML proves brittle in practice, `REFERENCES`
  §22 D10 gives the exact escape: **downgrade that one assertion to the release checklist, in
  writing, rather than weakening the rest.** The `Info.plist` half is trivial string matching and
  stays in the gate either way. Downgrading silently, or loosening the tolerance until it passes, is
  the anti-pattern.
- **`Info.plist` is the file the `gate` job greps for `NSAppTransportSecurity`, and you are editing
  it.** G5's text half is one `grep -q` in CI. It must not be present; neither must `UIBackgroundModes`,
  `UIFileSharingEnabled` or `LSSupportsOpeningDocumentsInPlace`. The last two look helpful — note 06
  recommended them so a shepherd could pull media off over a cable — and they are **superseded**:
  the database and the media folder both live in Application Support (decision #27) precisely so a
  user tidying up in Files cannot delete `shed_book.sqlite`. With nothing of ours in `Documents/`,
  both keys expose an empty folder.
- **Read the whole `Info.plist` before you edit it.** Three usage strings are already there and their
  copy is `08 §8.4`'s, verbatim — one plain sentence each, no *"we may"*, no *should*. If your diff
  touches any of them, you have edited the wrong thing.
- **There is no `flutter create` regeneration step that will do this for you, and there is no
  `colors.xml`.** The hex is typed three times on iOS — twice as floats, once implicitly through the
  appearance key — and `launch.colour_parity` is the only thing keeping them equal to each other and
  to `nSurface04`. That asymmetry with Android is the whole justification for T08.
- **The iOS storyboard is XML that Xcode rewrites.** Opening the storyboard in Interface Builder and
  saving reformats it and can re-add the `LaunchImage` view. Edit it as text, and if you do open
  Xcode, re-run the parity test before committing.
- **`ios/Runner/PrivacyInfo.xcprivacy` is not this task's.** It is `11 §9.2`'s and lands with the
  store artefacts (N31). Do not create it here to be helpful — over-declaring within your own valid
  codes is safe, but a manifest written by the wrong epic is one nobody re-reads after a plugin bump.
- **You need a Mac.** `flutter build ios` and a real iPhone are the only way to see the layer this
  task exists to fix. The `android` CI job builds an AAB; **nothing in CI builds an iOS artefact**
  (`13 §4.1`'s macOS budget), so the gate row and your own eyes are the entire proof.

### 5.4 The full test set

`test/design/first_frame_parity_test.dart` — the iOS group, added to the file T06 created.

| Case | What it asserts |
|---|---|
| `'the iOS launch colour equals the page token and the appearance key forbids light'` | **The anchor.** `LaunchScreen.storyboard`'s root-view colour matches `launchSurface` to within 1/255 on all three channels, **and** `Info.plist`'s `UIUserInterfaceStyle` is `Dark` |
| `'Main.storyboard carries the same colour as LaunchScreen.storyboard'` | The forgotten layer, asserted against the other storyboard rather than against the token — so the failure message says *which two disagree* |
| `'neither storyboard uses a named UIColor'` | No `systemBackgroundColor`, no `<color … cocoaTouchSystemColor=…>`. The per-appearance resolution that hands you white |
| `'both storyboards declare colorSpace custom / sRGB'` | A `calibratedRGB` or `deviceRGB` triplet with the same numbers is a *different colour*, and it will not match Android |
| `'UILaunchStoryboardName is LaunchScreen and UISceneStoryboardFile is Main'` | The two keys, separately, so a failure names the one that was deleted |
| `'Info.plist contains no NSAppTransportSecurity and no UIBackgroundModes'` | G5's text half, plus the background-mode absence. A test as well as a CI grep, because this is the file being edited |
| `'Info.plist sets neither UIFileSharingEnabled nor LSSupportsOpeningDocumentsInPlace'` | The superseded recommendation, held so it is not re-added by someone reading note 06 |
| `'the three usage strings are unchanged and each is one plain sentence'` | Compare against `08 §8.4`'s copy; assert none contains *should*, *may* or a second sentence |
| `'the storyboard colour tolerance is 1/255 and is stated in the test'` | The tolerance is a named constant in the file with `06 §9.4` cited beside it — so a future weakening is a visible diff on a documented number, not a quiet edit to a magic value |

`test/policy/gate_rules_test.dart` gains:

| Case | What it asserts |
|---|---|
| `'launch.colour_parity fires when a storyboard colour is off by more than 1/255'` | The planted-violation case for the iOS half |
| `'launch.colour_parity fires when UIUserInterfaceStyle is Light or absent'` | The `Info.plist` half, proved separately |

**Nothing in this task is time-shaped**, so no `test/domain/uk_zone/` case and no `@Tags(['uk-zone'])`.

## 6. Constraints that bind this task

- **3am** — the first thing a shepherd sees, on the other platform. No interactive element is added,
  so the 64 × 64 floor and the gesture ban do not bite here; dark-only does, and `UIUserInterfaceStyle
  = Dark` is what makes it unconditional rather than likely.
- **Offline** — no network path may be added. G2 and G3 stay green, **and `NSAppTransportSecurity`
  must stay absent** — its absence is the half of G5 a text check can do, and this is the file it
  greps.
- **Irreversible in claim** — a deleted `Info.plist` key can cost an App Store rejection weeks after
  the commit. Diff this file line by line.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the iOS launch colour equals the page token and the appearance key forbids light'` passes, and was seen to fail first for the stated reason
- [ ] all four iOS layers carry the page colour
- [ ] `UIUserInterfaceStyle` is `Dark` and cannot follow the system
- [ ] watched on a real device
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **`Main.storyboard` is edited, not only `LaunchScreen.storyboard`**, and both carry `colorSpace="custom" customColorSpace="sRGB"`
- [ ] `UILaunchStoryboardName` **and** `UIApplicationSceneManifest`→`UISceneStoryboardFile` both survive the edit
- [ ] `Info.plist` contains no `NSAppTransportSecurity`, no `UIBackgroundModes`, no `UIFileSharingEnabled`, no `LSSupportsOpeningDocumentsInPlace`, and the three usage strings are byte-identical to `08 §8.4`'s
- [ ] the storyboard floats are the ones recomputed by T04's ruling, not `06 §9.2`'s pre-ruling triplet
- [ ] `launch.colour_parity`'s iOS half is in `tool/check_policy.dart` **and** has its `firesOn` entries — or is downgraded to the release checklist **in writing**, with the Android half and the plist half still in the gate
- [ ] a cold launch on a real iPhone, in a dark room, shows no white frame between the springboard and the first Flutter frame

## 8. Verification

```bash
fvm flutter test test/design/first_frame_parity_test.dart
fvm flutter test test/policy/gate_rules_test.dart
dart run tool/check_policy.dart
make check
make test
```

Then on the Mac, because CI builds no iOS artefact at all:

```bash
fvm flutter build ios --release --no-codesign
git diff --stat -- ios/Runner/Info.plist
# The tooling rewrites this file. Expect no diff. If there is one, read every line:
# UILaunchStoryboardName and UIApplicationSceneManifest must both still be there.

fvm flutter install --release -d <your-iphone>
# Cold-launch from the springboard five times, in a dark room, on a REAL device.
# The simulator composites differently and is the single most common way this
# defect ships. indelible.md §11 test 9 records it at 240 fps if there is an
# argument; a second phone's slow-motion camera settles it in two minutes.
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `fix(ios): no white flash — all four launch layers`
