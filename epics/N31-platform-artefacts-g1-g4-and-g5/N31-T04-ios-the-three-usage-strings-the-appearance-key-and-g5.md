# N31-T04 — iOS — the three usage strings, the appearance key, and G5

| | |
|---|---|
| **Epic** | [N31 — Platform artefacts, G1, G4 and G5](epic.md) · `00-README` §9 step 12 (1 of 3) |
| **Task** | 4 of 4 |
| **Depends on** | N31-T03 |
| **Commit** | one commit · `feat(ios): usage strings, the appearance key and the G5 record` |

## 1. Why this task exists

Camera, microphone and photo-library usage strings written as a shepherd would read them,
the dark appearance key, **no ATS exception** — and G5 as *construction plus observation*: there is no
iOS equivalent of a manifest permission dump, so the claim is held by what is built and by what is
observed on a real device.

`13 §2.7`'s heading is *"G5 — iOS, honestly"* and its first sentence is *"There is no iOS permission to
remove."* Decision-record §3.2 says the same thing and then says how to talk about it: *"Say so
honestly rather than implying parity with Android."* This task is the one place in the backlog where
the correct output is a weaker guarantee than the sibling platform's, stated plainly, with the two
halves that *are* mechanical made mechanical and the half that is not given a date and a device.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | §8.4 | **the copy.** All three usage strings verbatim, the appearance key, and the ruling that `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` are superseded, not open |
| `docs/engineering/08-platform-integration.md` | §8.2 | who asks for what and when — and the row that says the photo library is asked for **never** |
| `docs/engineering/13-build-ci-release.md` | §2.7 | G5's four-row table: which check, how, and when · the SwiftPM warning about `ITMS-91061` |
| `docs/engineering/13-build-ci-release.md` | §3.2 | the iOS key table, the four required absences, and the pointer to who owns the privacy manifest |
| `docs/engineering/13-build-ci-release.md` | §4.1, §4.3, §12 | there is no macOS CI job and why · the `gate` job's ATS grep · checklist items 2, 3 and 10, which are this task's forever |
| `docs/research/00-tech-decisions.md` | §3.1, §3.2 | tier 1 is *"yes on iOS by construction and observable via the App Privacy Report"* — the exact scope of what this task can claim |
| `docs/engineering/11-monetization-and-store.md` | §9.2 | `PrivacyInfo.xcprivacy`'s ruling — **N30-T07's file**, already merged. Read it; do not re-author it |
| `docs/engineering/06-design-system.md` | §9.2 | the three launch-related `Info.plist` keys, authored at N11-T07 — the file you are editing, and the parts of it you must not touch |
| `docs/engineering/10-accessibility-and-i18n.md` | §7 | the ARB rules, and the boundary: these three strings are native platform metadata, not `app_en.arb` messages |
| `docs/engineering/CONVENTIONS.md` | §5.4 | copy conventions — en_GB, one plain sentence, no *should* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | `Info.plist`, the usage strings and the ATS position |
| `shed-accessibility-and-copy` | the usage strings are user-facing copy and are read at the worst moment |
| `shed-release` | typed by name, never auto-firing; G5's observation half is a per-release runbook step, not a test |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/ios_config_test.dart`
- **Test** — `'the three usage strings are present, non-empty, and no ATS exception exists'`
- **Why it is red today** — the generated `Info.plist` has no usage strings and nothing forbids an ATS exception.

```bash
fvm flutter test test/policy/ios_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the three strings, the appearance key, the ATS assertion, and the G5 observation
recorded. The three strings are `08 §8.4`'s, character for character; the appearance key already
exists from N11-T07 and this task holds it rather than writing it; the ATS assertion is a text scan of
the plist, never a `plutil` call.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. There
is one real duplication and folding it means **moving cases, not adding them**: N11-T07 put four
plist-policy assertions into `test/design/first_frame_parity_test.dart`. They belong here. See §5.4.

## 5. What you build

### 5.1 The files this task touches, in order

`00-README` §8's layer order does not apply — no layer is reached, and in particular **no ARB entry is
authored**, which is a departure from every widget task and is explained in §6. Say so in the commit
message. The order below is irreversibility order: the file whose contents become App Store review
metadata first.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/ios_config_test.dart` | **New, written first** (§4). `@Tags(['policy'])` then a bare `library;`. Reads `ios/Runner/Info.plist` as text and parses it as XML; never shells out |
| 2 | `ios/Runner/Info.plist` | **Edited.** Three usage-description keys added with `08 §8.4`'s copy. `UIUserInterfaceStyle` = `Dark` is **confirmed present**, not re-written — N11-T07 authored it. The three launch keys are confirmed untouched. Four keys must be absent and stay absent |
| 3 | `test/design/first_frame_parity_test.dart` | **Edited.** The four plist-policy cases N11-T07 left there **move** into file 1. The design test keeps the colour and storyboard assertions, which are what it is for |
| 4 | `docs/calendar.md` | **Edited.** An eighth row, `g5_observation`, filled in the same commit — owner, ISO date, device, outcome. An empty row here turns the ledger test red on purpose and this is not the task to leave it red |
| 5 | `test/policy/calendar_commitments_test.dart` | **Edited, one constant.** N00-T06's case `'the ledger carries exactly the seven commitments the critique names'` becomes eight, with the new key named. See §5.5 — this is an extension with a stated reason, not a weakening |
| 6 | `docs/engineering/13-build-ci-release.md` | **Edited, §2.7.** The G5 table's *When* column says *"once per release, by hand"*. Record where the answer now lives, so the next release does not re-derive where to write it down |

Nothing under `lib/`, nothing under `android/`, no `pubspec.yaml`, no lockfile churn. **Nothing under
`ios/Runner/PrivacyInfo.xcprivacy`** — that is N30-T07's and it is already merged.

### 5.2 The three strings, verbatim

`08 §8.4` owns this copy and it is not paraphrased here or anywhere:

| Key | Value | Why it exists |
|---|---|---|
| `NSCameraUsageDescription` | "Shed Book uses the camera so you can attach a photo to a lambing record." | `image_picker`'s system camera path |
| `NSPhotoLibraryUsageDescription` | "Shed Book lets you attach a photo you have already taken to a lambing record." | `image_picker` and **App Store policy**. `PHPickerViewController` needs no authorisation on iOS 14+, so this string exists **for review, not for a prompt** |
| `NSMicrophoneUsageDescription` | "Shed Book records voice notes you attach to a lambing record." | `record`, for the voice **note**. Not voice tag entry — that is cut from v1 (`08 §10.2`) |

Three sentences, en_GB, each naming the feature the permission serves. No *"we may"*, no *"should"*,
no second sentence, no marketing. A shepherd reads these at the moment a system dialog interrupts
them, one-handed, and the only useful content is *what this is for*.

### 5.3 The keys that must not be there

`13 §3.2` and `08 §8.4`, in one place because the test asserts them together:

| Key | Why its absence is required |
|---|---|
| `NSAppTransportSecurity` | Its absence is the half of G5 a text check can do. An ATS dictionary — even a permissive one added "to test something" — is an admission that something in the process opens a socket |
| `UIBackgroundModes` | No background work, no push capability, no notification entitlement. `AppDelegate` sets `UNUserNotificationCenter.current().delegate = self` and nothing more |
| `UIFileSharingEnabled` | **Superseded, recorded, not re-opened.** Note 06 recommended it so media could be pulled off over a cable; decision #27 then put the database *and* the media folder in Application Support precisely so a shepherd tidying up in Files cannot delete `shed_book.sqlite`. With nothing of ours in `Documents/`, it exposes an empty folder |
| `LSSupportsOpeningDocumentsInPlace` | Same ruling, same reason, same file |

### 5.4 The anchor test, and the four cases that move into it

```dart
// test/policy/ios_config_test.dart — 08 §8.4; 13 §2.7, §3.2.
@Tags(['policy'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _plist = 'ios/Runner/Info.plist';

/// The <string> value that follows a given <key>, or null if the key is absent.
/// Parsed from the XML text: `plutil` is macOS-only and CI is ubuntu (§5.5).
String? _stringFor(String key) { /* ... */ }

/// True if the key appears at all, whatever its value type.
bool _hasKey(String key) { /* ... */ }

void main() {
  test('the three usage strings are present, non-empty, and no ATS exception exists', () {
    for (final key in const [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSMicrophoneUsageDescription',
    ]) {
      final value = _stringFor(key);
      expect(value, isNotNull, reason: '$key is missing from $_plist (08 §8.4)');
      expect(value!.trim(), isNotEmpty,
          reason: '$key is present but empty — App Review rejects an empty usage string');
    }
    expect(_hasKey('NSAppTransportSecurity'), isFalse,
        reason: 'G5, the half a text check can do: 13 §2.7');
  });
}
```

**Four cases move here from `test/design/first_frame_parity_test.dart`.** N11-T07's test set put
them in the design tier because it was the task editing the file at the time:
`'Info.plist contains no NSAppTransportSecurity and no UIBackgroundModes'`,
`'Info.plist sets neither UIFileSharingEnabled nor LSSupportsOpeningDocumentsInPlace'`,
`'the three usage strings are unchanged and each is one plain sentence'`, and the appearance-key half
of `'the iOS launch colour equals the page token and the appearance key forbids light'`.

Move the first three whole. **Split the fourth**: the colour comparison stays in the design test where
the token lives; the `UIUserInterfaceStyle` assertion is duplicated here rather than moved, because
this file is the one a developer opens when asking *"what is this app allowed to declare?"* and the
design test is the one that asks *"does the first frame flash?"* One property with two owners is a
property that goes stale in one of them — so name both in the commit message and say which is the
policy home.

There is a second reason the move is the right shape and not tidying: N11-T07's §5.3 says *"Three
usage strings are already there and their copy is `08 §8.4`'s, verbatim. If your diff touches any of
them, you have edited the wrong thing."* At N11 they were **not** there — this task authors them, and
N11 runs twenty epics earlier. If N11-T07 shipped placeholder strings to make its own case pass,
replace them with `08 §8.4`'s here and say so; if it shipped the case red or deferred, this commit is
where it goes green. Either way the plist is read end to end before it is edited.

### 5.5 The details that are easy to get wrong

- **`plutil` is macOS-only, and the `test` job runs on `ubuntu-latest`.** `13 §2.7` writes the ATS
  check as `plutil -p ios/Runner/Info.plist | grep -c NSAppTransportSecurity`. That form cannot run
  on the runner this project uses, and the temptation — *"do it properly, parse the plist with the
  real tool"* — produces a check that silently stops running the day it moves into CI. N01-T06
  already took the text-scan option for the `gate` job's shell step, for the same reason. Parse the
  XML text.
- **`grep -q` exits 1 when the pattern is absent, and absent is the pass.** N01-T06's §5.3 spells this
  out for the workflow step: written as `plutil … | grep -c … = 0` under `set -e`, the naive form
  fails the step on the *good* outcome. You are not writing that step — it exists — but you are the
  task most likely to be asked to "improve" it. Do not.
- **A present-but-empty usage string is a rejection, not a warning.** `<key>NSCameraUsageDescription</key><string></string>`
  satisfies a `containsKey` check and fails App Review. Assert non-empty after trimming.
- **`NSPhotoLibraryUsageDescription` is not dead weight.** `PHPickerViewController` needs no
  authorisation on iOS 14+, so nothing in this app ever triggers a photo-library prompt (`08 §8.2`
  gives that row the value *"none, ever"*). The string exists for **review**. Somebody will eventually
  notice no prompt uses it and delete it; `13 §3.2` calls this *"settled there; not an open question
  here."*
- **`UIUserInterfaceStyle` = `Dark` was authored at N11-T07 and does more than the app window.** It
  darkens share sheets, alerts and any IME — which matters because the share sheet is the export path
  and a white sheet at 3am is the flashbang the whole theme exists to avoid. This task **holds** the
  key; it does not re-write it, and a diff that changes its value is the wrong diff.
- **Do not touch the three launch keys.** `UILaunchStoryboardName` and `UIApplicationSceneManifest`'s
  `UISceneStoryboardFile` are different keys naming different storyboards; `06 §9.2` says deleting the
  wrong one produces *"a white launch screen **and** an App Store rejection"*, discovered weeks later.
  The first-frame parity gate holds them; leave them alone.
- **`PrivacyInfo.xcprivacy` is N30-T07's and is already merged.** `11 §9.2` ruled the codes: `C617.1`
  and `E174.1` ship, `CA92.1` does not. Do not re-author it, and do not add codes to be helpful —
  `0A2A.1` and `C56D.1` are third-party-SDK codes and their appearance in an app manifest is the
  shape of `ITMS-91055`. What this task *does* owe it is the **membership** check: `13 §2.7` requires
  the file to be present **and in the Runner target's Copy Bundle Resources**, and no text test can
  see target membership. That is what Generate Privacy Report is for.
- **Flutter 3.44 made Swift Package Manager the default iOS dependency manager, and a plugin's
  privacy manifest reaches the app through its resource bundle.** SwiftPM packages those differently
  from CocoaPods, and a dropped manifest surfaces as `ITMS-91061: Missing privacy manifest` at upload
  time — weeks after the commit that caused it. `13 §2.7` says to re-generate the privacy report after
  the SwiftPM migration and not to carry a CocoaPods-era assumption forward. Do it now, while the
  archive is a five-minute step and not a release-day one.
- **Nothing in CI builds an iOS artefact.** `13 §4.1`: macOS runners bill at a 10× multiplier and the
  free private-repo budget is about 200 macOS minutes a month, so *"for v1, iOS is built by hand on
  the developer's Mac."* The `gate` job's ATS grep and this file's assertions are the **entire**
  mechanical proof for iOS. Everything else in G5 is your eyes, once per release, written down.
- **The G5 observation is a per-release fact and the ledger's key set is closed at seven.**
  `test/policy/calendar_commitments_test.dart` carries `'the ledger carries exactly the seven
  commitments the critique names'`, so adding a `g5_observation` row without updating that constant
  turns the ledger test red. Updating it is the correct move and it is not a weakening: the assertion
  exists so a row *cannot be quietly dropped*, and extending a named set with the reason in the commit
  message is the mechanism `00-README` §10 describes. The alternative — a second ledger under
  `docs/gates/` — is a second place to look, and the next person looks in one of them.
- **The ledger row's date is a sentinel, never a time.** N00-T06's sixth case is `'the test reads no
  clock'`, and its reason is this project's own: a test that compares a ledger date to `now` changes
  verdict at midnight and is ambiguous for a whole hour once a year, because the owner's region ruling
  puts the UK/Ireland ambiguous hour at **01:00–01:59**. Record `YYYY-MM-DD`; assert the shape; never
  compare it to anything.
- **The observation must be done on a build that behaves like the shipped one.** `13 §12` item 3 is a
  full airplane-mode pass on a real device — cold launch, save a lambing, export a CSV, open Unlock,
  tap Restore — and the App Privacy Report pass is the same session with the network **on**, because a
  device in airplane mode cannot demonstrate that nothing tried to use the network. Do both, and note
  which is which.
- **Never add an ATS exception "temporarily".** There is no debugging story in this app that needs
  one, because there is no network code to debug. A commented-out ATS block still trips the `gate`
  job's grep, which is the correct behaviour and not a bug in the check.

### 5.6 G5's observation half, concretely

`13 §2.7`'s four rows, and what each produces:

| Check | How | Result recorded |
|---|---|---|
| No `NSAppTransportSecurity` | this file's anchor case, plus the `gate` job's `grep` | mechanical, every push |
| `PrivacyInfo.xcprivacy` present **and in the Runner target's Copy Bundle Resources** | Xcode → Archive → Organizer → **Generate Privacy Report**; read the PDF | once now, and after every plugin bump — `13 §12` item 2 |
| App Privacy answers are *Data Not Collected* | App Store Connect | every submission — N32-T02's, noted here so it is not assumed to be this task's |
| **No socket opens at runtime** | one full session with **Settings ▸ Privacy ▸ App Privacy Report** enabled, or `nettop -p <pid>` on a tethered device | `docs/calendar.md`'s `g5_observation` row: owner, ISO date, device and iOS version, outcome |

The fourth row is the one this task's Definition of Done turns into a record. It is not a test and it
will never be one — decision-record §3.1 marks tier 1 on iOS as *"yes by construction and observable
via the App Privacy Report"*, and *observable* is doing real work in that sentence.

### 5.7 The full test set

`test/policy/ios_config_test.dart` — one file, eight cases, reading one file as XML text.

| Case | What it holds |
|---|---|
| `'the three usage strings are present, non-empty, and no ATS exception exists'` | **the anchor.** Presence, non-emptiness after trimming, and G5's text half |
| `'each usage string matches 08 §8.4 character for character'` | the copy is owned by a document, and a paraphrase in a system dialog is copy nobody reviewed |
| `'no usage string contains should, may or a second sentence'` | `CONVENTIONS` §5.4 and spec §12.2 — an advice verb in a permission prompt is the app telling a shepherd what to do |
| `'UIUserInterfaceStyle is Dark'` | the appearance key forbids light. Duplicated from the design tier deliberately; §5.4 says why |
| `'Info.plist declares no UIBackgroundModes'` | no background work, no push capability, no notification entitlement |
| `'Info.plist sets neither UIFileSharingEnabled nor LSSupportsOpeningDocumentsInPlace'` | the superseded recommendation, held so nobody re-adds it from note 06 |
| `'the three launch keys are present and unchanged'` | `UILaunchStoryboardName`, `UIApplicationSceneManifest` and its `UISceneStoryboardFile` — you are editing this file and the tooling rewrites it |
| `'PrivacyInfo.xcprivacy exists and this test does not re-declare its codes'` | a presence check only. `11 §9.2` owns the codes; this case exists so the file cannot silently vanish in an Xcode reorganisation |
| *edge* — an absent or unparseable `Info.plist` fails, never skips | `13 §2.3`'s posture, applied to the other platform |
| *edge* — the plist is parsed as XML text, never through `plutil` | the macOS-only trap, asserted as a source property of this test file |

`test/policy/calendar_commitments_test.dart` — one existing case, extended:

| Case | What changes |
|---|---|
| `'the ledger carries exactly the seven commitments the critique names'` | becomes eight, naming `g5_observation`, with the reason in the commit message. The property — a row cannot be quietly dropped — is unchanged |

**Nothing in this task is time-shaped.** No instant is computed, stored or formatted; the plist holds
no time and the ledger's date is read as a sentinel. There is therefore no `test/domain/uk_zone/` case
to add. The ambiguous **01:00–01:59** hour appears here only as the reason N00-T06's ledger test is
forbidden from reading a clock — a recency assertion over a ledger date would change verdict at
midnight and be ambiguous for one hour every autumn, which is precisely the failure it was written to
avoid.

## 6. Constraints that bind this task

- **These three strings are native platform metadata, not ARB messages.** `10 §7`'s rule — every user-facing string lives in `lib/l10n/app_en.arb` with a `description` — governs strings Flutter renders. iOS renders these, from the app bundle, before any Dart runs; `gen-l10n` writes no `InfoPlist.strings` and localising them would mean a second, hand-maintained `.lproj` file. The app ships **en only** (`l10n.yaml`), so there is nothing to localise. **No ARB key is authored in this commit**, and that is a stated exception rather than an omission.
- **The copy conventions still apply in full** (`CONVENTIONS` §5.4): en_GB, one plain sentence each, no advice verb. Spec §12.2 does not stop at the app's own screens.
- **G5 is construction plus observation, and the prose must say so** (decision-record §3.2; `13 §2.7`). Never write anything that implies iOS parity with Android's manifest dump. Tier 1 on iOS is claimable *by construction*; tier 3 is not claimable at all, on either platform.
- **Offline** — no network path may be added. G2 and G3 stay green. An `NSAppTransportSecurity` key is the iOS shape of the thing this whole product claims not to do.
- **`PrivacyInfo.xcprivacy` is not re-authored here** (`11 §9.2`, N30-T07). Over-declaring within your own valid codes is safe; a manifest written by the wrong epic is one nobody re-reads after a plugin bump.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the three usage strings are present, non-empty, and no ATS exception exists'` passes, and was seen to fail first for the stated reason
- [ ] all three usage strings present and specific
- [ ] `NSAppTransportSecurity` appears nowhere
- [ ] the appearance key forbids light
- [ ] the G5 observation is recorded in the calendar ledger with a date and a device
- [ ] the four plist-policy cases moved out of `test/design/first_frame_parity_test.dart`, leaving no second copy
- [ ] `UIBackgroundModes`, `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` are absent
- [ ] the privacy report was generated from an Xcode archive and read
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/ios_config_test.dart
fvm flutter test test/design/first_frame_parity_test.dart
fvm flutter test test/policy/calendar_commitments_test.dart
grep -c NSAppTransportSecurity ios/Runner/Info.plist || echo "absent — this is the pass"
make check
make test
```

The second command must still pass with four fewer cases; the third must be **green**, which is the
first time in this project's history it has been — N00-T06 left it deliberately red and N32-T03 is
what turns the twelfth-tester row green, so if it is still red here, read the failure message and
confirm the only remaining rows are N32's.

Then the manual half, on the Mac, in this order:

```bash
fvm flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols/ios
```

1. Open the archive in Xcode → Organizer → **Generate Privacy Report**, and read the PDF. Confirm
   `PrivacyInfo.xcprivacy` is in the aggregate and that no plugin declares a reason code this project
   does not expect.
2. Install on a real iPhone. Enable **Settings ▸ Privacy ▸ App Privacy Report**.
3. One full session with the network **on**: cold launch, save a lambing, attach a photo, record a
   voice note, export a CSV, open Unlock, tap Restore.
4. Read the App Privacy Report. There must be no network activity for this app.
5. Write the row: owner, ISO date, device model, iOS version, outcome.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ios): usage strings, the appearance key and the G5 record`
