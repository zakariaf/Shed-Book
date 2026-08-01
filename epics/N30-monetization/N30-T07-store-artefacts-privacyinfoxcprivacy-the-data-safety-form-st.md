# N30-T07 — Store artefacts — `PrivacyInfo.xcprivacy`, the data-safety form, `*.storekit`

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 7 of 8 |
| **Depends on** | N30-T06 |
| **Commit** | one commit · `feat(store): the privacy artefacts and the offline purchase configuration` |

## 1. Why this task exists

Apple's **genuine** *Data Not Collected* declaration, Play's data-safety form filled in to
match, and `ios/Configuration.storekit` — the offline purchase-test configuration `00-README` §7.1 lists
as committed and which the old plan's privacy task did not cover. Critique gap G4.

Three of the four artefacts here are **outside the Dart codebase**, and two of them are irreversible in
a way no test can undo. `11 §9` opens with the reason to take it seriously: *"this is a real,
mechanical rejection cause. Precision here is cheaper than a rejected submission at the start of
lambing."* And a *Data Not Collected* label that is not true is not a bug — it is a store-removal risk
and a legal exposure.

This task also carries an **amendment**. `11 §9.2` overrules decision-record §2 row 93 and
`08-platform-integration.md` §11 on which reason codes ship, and `00-README §10`'s amendment rule
requires all three documents to change in the same change.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§9.1** (Apple's definition of *collect*, the fourteen categories answered No, the two judgement calls to re-check, the mandatory hosted policy URL and the in-app half) · **§9.2** (the reason-code table, the plist printed in full, the ruling that supersedes #93 and 08 §11, the two banned SDK codes, the unresolved `85F4.1` question, and the Copy Bundle Resources requirement) · **§9.3** (plugin manifests aggregate, they do not substitute; Generate Privacy Report; the SwiftPM packaging change) · **§9.4** (Play: no data collected or shared, the payment-service exemption, `targetSdk = 36`, AAB + Play App Signing) · **§9.5** (what is **not** needed because there is no account, and the App Review notes verbatim) · §3.1–§3.4 (the eight-entry permission set and which offline claims survive) · §11 (the `.storekit` loop) · §1.1 (`kUnlockProductId`) | every artefact and every declaration |
| `docs/research/00-tech-decisions.md` | §2 **#93** (*"`C617.1` + `CA92.1`, with `E174.1` only if free disk space is actually queried"* — **this task amends it**) · #87 (one bundle id, no flavors) · #88 · #123/#124 (no telemetry; redacted local diagnostics only) · §3.1 (the only permitted public wording) · **§3.3** (the eight-entry permission set G0 recorded) · §3.4 (the honest exceptions) · §5.1 for versions · §7.1 item 14 (the developer-account question) | the row this commit rewrites |
| `docs/engineering/08-platform-integration.md` | **§11** (restates #93 while marking the row *"owned by 11"* — **this task amends it too**) · §8.3 (which permissions each plugin merges) | the sibling that must move in the same commit |
| `docs/engineering/00-README.md` | **§7.1** (*"`ios/*.storekit` — the offline purchase-test configuration"* is a **committed** artefact) · §7.2 (what is gitignored) · **§10, the amendment rule** (edit the decision row, grep the doc set for the number, change every document that applies it, in the same commit) | why the `.storekit` file is in git, and how the amendment is done |
| `docs/engineering/13-build-ci-release.md` | **§7.1** (*"the `.storekit` configuration file — committed under `ios/`"*, and *"the iOS `.storekit` loop works fully offline and needs no Apple account, so it is the only purchase test that can be run before the developer account question is answered. Run it first; it is not blocked on anything"*) · §2 (G0–G5, and G5's honest label) · §4.2 (the `android` job) · §9 (the release workflow) | where the file lives and when to run it |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree; `ios/` is outside it and that is the point) · §4.1 (a policy test states the **property**) · §5.3 (banned strings — *"your data never leaves your phone"*, *"compliance record"*, *"official record"*) | the test's name, and the copy ban |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.3 (`media_assets.relative_path` — the app-container file access `C617.1` covers) · §8 (`VACUUM INTO`) | why `C617.1` is true |
| `docs/engineering/01-architecture.md` | §5.1 (`ShedFailure`'s six variants — **`DiskFull` is one of them**, which is why `E174.1` is true) | why `E174.1` ships |
| `epics/N02-g0-the-merged-manifest-record/` | **N02-T01** (G0 run against a real release AAB) · **N02-T02** (`docs/store/offline-honesty.md` — *"the single authored source of every public sentence about the offline claim"*, and the character-for-character comparison against decision-record §3.1) | the permission set and the public wording this task must not contradict |
| `epics/00-PLAN-CRITIQUE.md` | **G4** (*"`ios/*.storekit` — `00-README` §7.1 lists it as committed. E27-T07 covers privacy artefacts only"*) · §11.4 | the gap this task closes |
| `shed-book-spec.md` | §4.3, §4.5 (positioning and privacy) · §7.10 (delete everything) · §12 (the five safety rules) · §14 | what the declarations are about |
| `CLAUDE.md` | offline purity, verbatim · the banned strings · the authority order | the wording that may not change |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the store artefacts and the declarations |
| `shed-platform-gateways` | the plist artefacts and where they live |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/store_artefacts_test.dart`
- **Test** — `'PrivacyInfo.xcprivacy declares no collected data and Configuration.storekit is committed'`
- **Why it is red today** — none of the three artefacts exists.

```bash
fvm flutter test test/policy/store_artefacts_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it holds the two things a human eye slides over. Parse the plist and assert
`NSPrivacyCollectedDataTypes` is an **empty array present**, not an absent key — an absent key is a
different declaration from an empty one and reads as an omission. And assert the `.storekit` file's
product identifier is **byte-identical to `kUnlockProductId`**: `expect(storekitProductId,
kUnlockProductId)`, reading both off disk, because a `.storekit` file that says
`shed_book_unlock_v2` makes every local purchase test pass against a product that does not exist in
either store.

**Green.** The minimum code that passes, and nothing beyond it — all three, with the declarations matching what the app actually does — which is nothing,
because there is no network path.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller, no UI step, and no Dart under `lib/` at all.** Every
artefact is a platform or documentation file, and the anchor is a policy test that reads files off
disk. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `ios/Runner/PrivacyInfo.xcprivacy` | 🚩 **New, and a legal declaration.** `11 §9.2` prints it in full. `NSPrivacyTracking = false`, empty `NSPrivacyTrackingDomains`, **empty-but-present** `NSPrivacyCollectedDataTypes`, and exactly two `NSPrivacyAccessedAPITypes` dicts: `FileTimestamp` → `C617.1` and `DiskSpace` → `E174.1` |
| 2 | `ios/Runner.xcodeproj/project.pbxproj` | 🚩 **Edit.** Add the plist to the **Runner target's Copy Bundle Resources**. `11 §9.2`: *"a `PrivacyInfo.xcprivacy` that sits in the project but not in the target ships nothing, and the build succeeds"* — the worst possible failure shape |
| 3 | `ios/Configuration.storekit` | **New.** One non-consumable, `productID` = `kUnlockProductId`, a display name and a locale price for the local loop only. `00-README §7.1` lists `ios/*.storekit` as committed; critique **G4** is that nobody owned it |
| 4 | `docs/store/data-safety.md` | **New.** Play's form answers, recorded so they can be re-checked rather than remembered: *no data collected*, *no data shared*, the payment-service exemption quoted, the privacy-policy URL, *"users can't create accounts"*, and `targetSdk = 36`. It lands beside `offline-honesty.md`, which N02-T02 created as *"the single authored source of every public sentence about the offline claim"* |
| 5 | `docs/store/app-review-notes.md` | **New.** `11 §9.5`'s paragraph **verbatim**, attached to every submission. Reviewers test on a networked device and may not read it, so nothing in the app may *depend* on it being read |
| 6 | `docs/research/00-tech-decisions.md` | 🚩 **Amend, in this commit.** §2 row 93 becomes `C617.1` + `E174.1`, with **no `CA92.1`**, and the superseded wording is **struck with its reason** rather than quietly rewritten (decision-record §6 exists for this) |
| 7 | `docs/engineering/08-platform-integration.md` §11 | 🚩 **Amend, in this commit.** It restates #93 and must now match. `00-README §10`: *"a doc set where document 07 applies decision #29 and document 03 no longer does is worse than no doc set, because both look authoritative"* |
| 8 | `test/policy/store_artefacts_test.dart` | **New.** The anchor and the cases in §5.4 |

**Not touched:** anything under `lib/`, `android/expected_permissions.txt` (N02's G0 recorded it and
this task changes no permission), `pubspec.yaml`, `pubspec.lock`, `drift_schemas/`.

### 5.2 The artefacts

`11 §9.2` prints the plist and this is it. Two dicts, two codes, nothing else:

```xml
<!-- ios/Runner/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>

  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <!-- Genuinely empty. Shed Book transmits nothing off the device. -->
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>

  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- shed_book.sqlite + WAL, the media folder, export temp files:
         all inside the app container. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>

    <!-- Free-space check before writing a photo or a PDF export.
         DiskFull is a ShedFailure variant. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>E174.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

The four codes and why each is in or out (`11 §9.2`):

| Category | Code | In our manifest? | Why |
|---|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | **`C617.1`** | **Yes** | Timestamps, size and metadata of files **inside the app container**. drift writes `shed_book.sqlite` plus its WAL, `MediaStore` writes and resolves media, `MediaSweeper` stats files to find orphans, and the export path writes temp files |
| `NSPrivacyAccessedAPICategoryDiskSpace` | **`E174.1`** | **Yes** | *"Check whether there is sufficient disk space to write files."* `DiskFull` is one of the six `ShedFailure` variants — the app genuinely queries this before writing a photo or a PDF |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | **No, in v1** | `shared_preferences` is not a dependency and entitlement **rule 3** forbids it. No app-level Dart touches `NSUserDefaults`; plugins that do declare it themselves. Re-check in the generated privacy report after any plugin bump |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | **No** | The Flutter engine's own manifest already declares FileTimestamp `[0A2A.1, C617.1]` and SystemBootTime `[35F9.1]`. Declare it yourself only if you write native code reading `systemUptime` / `mach_absolute_time` — this app writes none |

The `.storekit` configuration — the identifier is the load-bearing field:

```jsonc
// ios/Configuration.storekit  (shape; Xcode owns the exact schema)
{
  "products": [
    {
      "productID": "shed_book_unlock",   // === kUnlockProductId. Byte-identical or the loop is a lie.
      "type": "NonConsumable",
      "referenceName": "Shed Book unlock"
    }
  ],
  "subscriptionGroups": []               // there is no subscription, ever (#87, spec §14)
}
```

And the App Review notes, `11 §9.5`, **verbatim**:

> This app has no server, no account and no sync. Android release builds declare no INTERNET
> permission. To test the unlock, use the sandbox account below; a "Restore purchases" button sits
> directly above the Unlock button on the same screen (Settings ▸ Unlock). The free tier covers one
> season and 15 ewes; every other feature, including export, is available without purchase.

### 5.3 The details that are easy to get wrong

- 🚩 **Never `0A2A.1`, never `C56D.1`.** Both are reserved for **third-party SDK wrappers**, and using
  either in an *app* manifest is the shape of `ITMS-91055: Invalid API reason declaration`. `0A2A.1` is
  particularly tempting because the Flutter engine's own manifest declares it — the engine is an SDK and
  we are not.
- 🚩 **Copy Bundle Resources, or it ships nothing and the build succeeds.** The file must be at the root
  of the app bundle. A green build with a missing privacy manifest surfaces as `ITMS-91061` at
  submission, at the start of lambing. Assert the `project.pbxproj` membership in the test — a grep for
  the filename inside the `PBXResourcesBuildPhase` block is enough and is far better than nothing.
- 🚩 **Re-read Apple's own `NSPrivacyAccessedAPITypeReasons` page before the first submission, and do
  not trust a single summary — including `11 §9.2`'s.** The document says so itself: the codes were
  cross-checked against two independent renderings *because the first fetch returned a garbled mapping*.
- **The `85F4.1` question is open and must be closed against Apple's page, not here.** It is *"display
  disk-space info to the user"*, and Settings ▸ Diagnostics **does** display storage figures (decision
  #123). Note 07's reason-code table treats it as a valid app-level code; its own pitfall table lists it
  as a rejection cause. The two halves of the research disagree and no critic resolved it. `E174.1` is
  unambiguously correct and ships either way. **Record the answer** in `docs/store/data-safety.md` when
  you have it; do not leave the question in a comment.
- **Over-declaring inside your own valid codes is not a rejection cause; under-declaring is.** So if a
  plugin bump ever introduces app-level `NSUserDefaults` use, add `CA92.1` and do not agonise.
- **The amendment is not optional and it is not a follow-up.** #93's wording predates entitlement rule
  3, which is what removed the `shared_preferences` dependency that would have made `CA92.1` true. Edit
  the decision row **and** `08 §11` in this commit, striking the superseded text with its reason. A
  decision record that disagrees with the doc that owns the answer is worse than either being wrong.
- **`Data Not Collected` is true because of G3, and the two must be reviewed together.** A red G3 and a
  *Data Not Collected* label in the same diff is the shape of a false declaration. Apple's operative
  verb is narrow: *"**Collect** refers to transmitting data off the device in a way that allows you
  and/or your third-party partners to access it for a period longer than what is necessary to service
  the transmitted request in real time."* Records, photos, voice notes and the SQLite file leave the
  phone only through the system share sheet, where the **user** chooses the destination — that is the
  user transmitting, not the app.
- **In-app purchase data is not "collected" under that definition** — Apple processes and retains it; we
  receive a `purchaseID` and nothing that identifies a person, and `11 §4.1` says we do not even store
  that. Record the judgement call so it is re-checked rather than remembered: **if a backend is ever
  added, this answer changes and the label must be updated before that build ships.**
- **Play's payment-service exemption is why a plain `in_app_purchase` integration keeps a clean form.**
  Quote it in `data-safety.md` rather than paraphrasing. It is also the second, independent reason
  `purchases_flutter` is rejected (#87): with a third party in the path you must declare *"Purchase
  history"* collected, because your app transmits purchase data to them.
- **The hosted privacy-policy URL is the one piece of internet infrastructure this project cannot
  avoid, and it lives outside the app.** Guideline 5.1.1(i) requires the link in App Store Connect
  metadata **and** *"within the app in an easily accessible manner"*. The in-app half is satisfied by
  shipping the full policy text as static Dart strings on Settings ▸ About (N29-T07) — readable in the
  shed with no signal, and it avoids `url_launcher`, which is itself on Apple's privacy-manifest SDK
  list.
- **Do not add Sign in with Apple, an account-deletion screen or a deletion URL "for parity."** All
  three are conditioned on account creation and there is none (`11 §9.5`). Each would create the account
  model the app does not have, and each is a new privacy declaration.
- **The public wording is fixed and this task may not amend a word of it.** N02-T02 made
  `docs/store/offline-honesty.md` the single authored source and asserts it character-for-character
  against decision-record §3.1. `11 §3.4`: *"the only public wording permitted stays exactly as it is,
  verbatim, and monetization does not amend a word of it."* And **never** write *"your data never
  leaves your phone"* — it is a banned string and `copy.tier3_claim` fails the build on it.
- **State the purchase boundary honestly wherever anyone asks.** During a purchase, bytes move on the
  device's behalf, **in someone else's process**. That is a different sentence from *"the app
  connects"*, and the app's own permission line is the verifiable proof of the difference.
- **Guideline 4.2 Minimum Functionality is the one to watch**, and the *free* experience is what the
  reviewer sees. The design clears it comfortably — everything works, one full season, 15 ewes, export
  included. A hard three-ewe demo would not.
- **Run the `.storekit` loop first, because it is blocked on nothing.** It works fully offline, needs no
  Apple account, and is the only purchase test that can be run before decision-record §7.1 item 14 (the
  developer-account question) is answered.
- **The `.storekit` product id is frozen with `kUnlockProductId`.** Byte-identical in the file, in App
  Store Connect and in Play Console. Changing it strands every purchase ever made.

### 5.4 The full test set

Everything below reads a file off disk. There is no widget and no database.

| File | Case | What it holds |
|---|---|---|
| `test/policy/store_artefacts_test.dart` | **anchor** — `'PrivacyInfo.xcprivacy declares no collected data and Configuration.storekit is committed'` | Both halves of §4 |
| | `'NSPrivacyAccessedAPITypes contains exactly FileTimestamp/C617.1 and DiskSpace/E174.1'` | Set equality, not `contains` — a third dict must fail |
| | `'0A2A.1, C56D.1 and CA92.1 appear nowhere in the app manifest'` | The two SDK-only codes and the one v1 ruled out |
| | `'NSPrivacyTracking is false and NSPrivacyTrackingDomains is an empty array'` | Both keys present |
| | `'NSPrivacyCollectedDataTypes is present and empty'` | Present-and-empty ≠ absent |
| | `'PrivacyInfo.xcprivacy is a member of the Runner target Copy Bundle Resources'` | Grep `project.pbxproj`; the failure this catches ships a green build with nothing in it |
| | `'the .storekit product identifier equals kUnlockProductId'` | Read both off disk |
| | `'the .storekit configuration declares one non-consumable and no subscription group'` | Spec §14's *"no subscription, ever"* as an artefact assertion |
| | `'docs/store/data-safety.md declares no collection and no sharing and answers users cannot create accounts'` | The Play half, matching the Apple half |
| | `'decision-record row 93 and 08 §11 both read C617.1 and E174.1 with no CA92.1'` | The amendment, asserted in the commit that makes it — otherwise it is a promise |
| | `'docs/store/ contains no banned public claim'` | *"your data never leaves your phone"*, *"offline-first"*, *"compliance record"*, *"official record"* — and the permitted paragraph present, character-for-character against decision-record §3.1 (N02-T02's assertion, extended to the new files) |
| | `'android/expected_permissions.txt is unchanged and still contains com.android.vending.BILLING and no INTERNET'` | G0's record, as a tripwire on this branch |

**No `uk-zone` case, and say why in the file's header comment.** Nothing here is time-shaped: every
assertion is over file content.

**Four things this task cannot automate, and they go in the pre-release checklist rather than in
someone's memory** (`11 §9.3`, §11, `13 §7.1`):

1. **Product → Archive → Generate Privacy Report**, read as a PDF. Once before the first submission, and
   again after **every** plugin bump and after the SwiftPM migration — Flutter 3.44 made Swift Package
   Manager the default and plugin resource bundles are packaged differently, which is how a plugin's own
   manifest fails to reach the app. Check `file_selector`, `record`, `flutter_image_compress`,
   `wakelock_plus`, `in_app_purchase_storekit` and `sqlite3` in the report: whether each ships a manifest
   is **unverified**, and any that does not and touches a required-reason API is ours to declare.
2. **The `.storekit` loop in the simulator**: buy, restore, and buy-when-already-owned.
3. **The three airplane-mode paths** (`11 §11`): open Settings ▸ Unlock and tap **Unlock**; tap
   **Restore purchases**; and install on a second device with no signal and confirm the app is fully
   usable in the free tier with a complete restored flock.
4. **Buy, then kill the app before the purchase stream delivers.** Relaunch offline — the flag is set,
   `attach()` runs, nothing arrives, the app stays free and usable. Relaunch with signal — the stream
   delivers, `completePurchase` runs inside the three-day window, and the row is written **after** it.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **Two more bind here.** **§12.3 — never present the app as a compliance record**: `docs/store/`'s
> listing copy and the App Review notes are the two places where a store-facing sentence could imply an
> official record, and *"compliance record"* and *"official record"* are banned strings. And the
> **offline wording is frozen**: this commit adds files to `docs/store/`, which is inside
> `copy.tier3_claim`'s public-copy scope (N02-T02), so every sentence in them is gated.

## 7. Definition of Done

- [ ] `'PrivacyInfo.xcprivacy declares no collected data and Configuration.storekit is committed'` passes, and was seen to fail first for the stated reason
- [ ] *Data Not Collected* is true and provable by G3
- [ ] the Play form matches the Apple declaration
- [ ] `ios/Configuration.storekit` is committed
- [ ] the declarations are consistent with G0's recorded permission set
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/store_artefacts_test.dart
dart tool/check_policy.dart                          # copy.tier3_claim over docs/store/
plutil -lint ios/Runner/PrivacyInfo.xcprivacy            # valid plist, on a Mac
plutil -p ios/Runner/PrivacyInfo.xcprivacy               # read it; two dicts, two codes
grep -n "PrivacyInfo.xcprivacy" ios/Runner.xcodeproj/project.pbxproj    # in Copy Bundle Resources
grep -n "productID" ios/Configuration.storekit           # shed_book_unlock
grep -rn "0A2A.1\|C56D.1\|CA92.1" ios/                   # nothing
grep -rn "C617.1\|E174.1" docs/research/00-tech-decisions.md docs/engineering/08-platform-integration.md
grep -rni "your data never leaves\|offline-first\|compliance record\|official record" docs/store/   # nothing
git diff --stat -- lib/ pubspec.yaml pubspec.lock android/expected_permissions.txt   # nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(store): the privacy artefacts and the offline purchase configuration`
