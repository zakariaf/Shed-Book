# N32-T01 — Signing — the upload keystore, Play App Signing and the iOS half

| | |
|---|---|
| **Epic** | [N32 — Signing and the closed track opens](epic.md) · `00-README` §9 step 12 (2 of 3) |
| **Task** | 1 of 3 |
| **Depends on** | N31-T04 |
| **Commit** | one commit · `feat(release): signing configuration for both platforms` |

## 1. Why this task exists

The upload keystore, `key.properties` **gitignored** and regenerable from the keystore and
its passwords, Play App Signing enrolled, and the iOS certificates and profiles. The keystore itself
never enters git; losing it without Play App Signing means never updating the app again.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §9.2 | the Gradle signing block, verbatim — the shape this task starts from and the two places §5.3 corrects it |
| `docs/engineering/13-build-ci-release.md` | §9.3, §9.4 | Xcode automatic signing for v1, and the four artefacts whose loss has no recovery — keystore, passwords, secrets, symbols |
| `docs/engineering/13-build-ci-release.md` | §4.4 | the CI keystore heredoc and the four `SHEDBOOK_*` secret names — **N34-T01's file**, quoted here only because the Gradle shape must make it work |
| `docs/engineering/13-build-ci-release.md` | §3.1, §4.3 | AAB never a fat APK; and what the per-push `android` job builds, which is the job this task can break |
| `docs/engineering/00-README.md` | §7.2 | what is gitignored: `android/key.properties`, `build/`, the obfuscation symbols, **and the upload keystore itself** |
| `docs/research/00-tech-decisions.md` | §7.1 item 14 | the account question, because Play App Signing is configured on an app record that does not exist until T02 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — signing is its first chapter |
| `shed-platform-gateways` | the Gradle signing configuration and the iOS side |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/signing_config_test.dart`
- **Test** — `'key.properties is gitignored and no keystore or password appears in the repository'`
- **Why it is red today** — nothing is signed, and the closed track cannot open.

```bash
fvm flutter test test/policy/signing_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the signing configuration, the gitignore entries, and a repository scan for secrets.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

Sharpen the anchor before you write it. *"Appears in the repository"* has two readings and only one of
them is worth asserting: **what git tracks**, not what is on this laptop. A filesystem walk is red on a
machine where `key.properties` legitimately exists and green on a machine where a tracked secret has
not been checked out yet — it answers the wrong question in both directions. Read `git ls-files -z`
and assert over that list. The history half of the DoD (*"no password or key material anywhere in git
history"*) is a `git log -S` sweep and belongs in §8, not in a test that runs on every push.

## 5. What you build

Six files, of which one is Kotlin, one is a test, one is a document correction, and one — the
keystore — is deliberately **not** in the repository at all.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `.gitignore` | `00-README` §7.2 already names `android/key.properties` and *"the upload keystore itself"*. Make the second one mechanical rather than prose: `*.jks`, `*.keystore`, `android/upload-keystore.jks` and `key.properties` (unanchored, so a copy in any directory is caught). N01-T01 wrote this file; this is the one edit it could not make, because there was nothing to ignore yet |
| 2 | *(outside the repository)* the keystore | Generated with `keytool` into a directory the repository cannot see. Two backups, neither of them this laptop, one offline (`13 §9.4`) |
| 3 | `android/key.properties` | Local only, git-ignored, four keys and no others: `storePassword`, `keyPassword`, `keyAlias`, `storeFile`. It is the indirection that lets a laptop point at an absolute path outside the tree while CI points at `android/upload-keystore.jks` |
| 4 | `android/app/build.gradle.kts` | The `keystoreProperties` load, the `signingConfigs` block and the `release` build type's assignment. §5.3 is this file in full, because two lines of `13 §9.2`'s snippet do not survive contact with the per-push `android` job |
| 5 | `docs/engineering/13-build-ci-release.md` §9.2 | The snippet gains the conditional and the `rootProject.file` correction, with the reason on the line. A snippet somebody pastes is a snippet that has to work; leaving it wrong means N34 pastes it and the release job fails on the day of a release |
| 6 | `test/policy/signing_config_test.dart` | **Written first** (§4). New file. Nothing else in the suite reads `build.gradle.kts`, and `make check` cannot — `dart format` and `flutter analyze` do not see Kotlin |

GitHub repository secrets are created in the same sitting and are not a file:
`SHEDBOOK_KEYSTORE_BASE64`, `SHEDBOOK_KEYSTORE_PASSWORD`, `SHEDBOOK_KEY_ALIAS`,
`SHEDBOOK_KEY_PASSWORD` (`13 §9.4`). They are consumed by `release.yml`, which is **N34-T01's file**.
Create them now, while the passwords are in front of you; do not write the workflow.

### 5.1 The keystore

```bash
keytool -genkeypair -v \
  -keystore "$HOME/keys/shed-book-upload.jks" \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Four things about that command, each of which is a defect if you get it wrong:

- **`-validity 10000`** is roughly 27 years. Play requires an upload key valid well past 2033; a
  one-year key expires in the middle of season three and the app can never be updated again without a
  support ticket.
- **RSA 2048** — not EC, not 1024. Play's own requirement, and the one place "modern" is the wrong
  instinct.
- **`-storetype JKS`** is stated rather than defaulted. `keytool` will otherwise nudge you to PKCS12
  and print a migration warning on every read, which people then "fix" by regenerating the key.
- **The path is outside the repository.** Generating into `android/` is one `git add -A` away from
  permanent. The `.gitignore` entries in file 1 are the belt; this is the braces.

### 5.2 `android/key.properties`

```properties
storePassword=<the store password>
keyPassword=<the key password>
keyAlias=upload
storeFile=/Users/<you>/keys/shed-book-upload.jks
```

Exactly four keys, spelled as `13 §9.2`'s Kotlin reads them. `storeFile` is absolute on a laptop and
**relative on the runner** — `13 §4.4`'s heredoc writes `storeFile=upload-keystore.jks` beside the
keystore it decodes into `android/`. Both work only if the Gradle side resolves relative paths against
`android/`, which is §5.3's second correction.

### 5.3 `android/app/build.gradle.kts` — the shape that survives CI

`13 §9.2`'s snippet is right about *what* to do and wrong about two mechanics. Written as printed, it
turns the per-push `android` job red on every push from this commit onward, because CI has no
`key.properties` and no keystore until `release.yml` exists at N34.

```kotlin
// android/app/build.gradle.kts — 13 §9.2 with the two corrections below.
import java.io.FileInputStream
import java.util.Properties

// rootProject here is `android/`, not `android/app/`. That is the point:
// 13 §4.4's CI heredoc writes android/key.properties and android/upload-keystore.jks.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasUploadKey) load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"] as String
                keyPassword   = keystoreProperties["keyPassword"] as String
                // `file(...)` would resolve against android/app/ and never find it.
                storeFile     = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasUploadKey) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Loud, once, on the runner that has no key. Never silent, and
                // never the debug config by default — that is how a debug-signed
                // artefact reaches an upload dialog.
                logger.lifecycle(
                    "key.properties absent — release build is UNSIGNED. " +
                    "It may run G1; it may never be uploaded."
                )
            }
        }
    }
}
```

**Correction 1 — the conditional.** `13 §9.2` loads the properties only `if (…exists())` but then
casts unconditionally: `keystoreProperties["keyAlias"] as String` on an empty `Properties` is a null
cast and throws at configuration time. The `android` job would fail with a Kotlin cast exception
naming a Gradle file, ten minutes into a build, on a branch about signing — and the temptation is to
add `continue-on-error`, which `13 §4.6` bans by name.

**Correction 2 — `rootProject.file`.** In `android/app/build.gradle.kts`, `file("upload-keystore.jks")`
resolves against the **app module** directory. `13 §4.4`'s heredoc puts the keystore one level up. The
correction makes the document's own CI step work as written.

> **Unverified, and it is one command to close.** Whether `bundleRelease` completes with **no** signing
> config on AGP 8.12.1 has not been checked. Check it in this sitting: rename `key.properties`, run the
> `android` job's exact build command, and read the result. If an unsigned bundle is refused, the
> fallback is `signingConfigs.getByName("debug")` **with the same `logger.lifecycle` line**, and §5.5's
> second test case changes from *"release is never debug-signed"* to *"the debug config is reachable
> only when `key.properties` is absent, and the build says so out loud"*. Record which of the two
> shipped, in the commit message.

### 5.4 The iOS half

`13 §9.3` for v1: **Xcode-managed signing, automatic provisioning, releases built on the Mac you
already own.** No `fastlane match`, no App Store Connect API key in CI, no signing secrets in GitHub —
that plumbing buys five minutes a month and costs the whole macOS budget (`13 §4.1`: 200 macOS minutes
a month on Free/private, at a 10× multiplier).

What is actually done here:

1. In App Store Connect, the Apple Distribution certificate is created (or the existing one is
   confirmed) and the private key is in the login keychain.
2. Xcode ▸ Signing & Capabilities: **Automatically manage signing** on, team selected, bundle
   identifier equal to the one `RELEASES.md`'s header records — character for character, including
   case.
3. The certificate and its private key are exported once to a `.p12` and stored beside the Android
   keystore backups. `13 §9.4` rates this recoverable — *"Regenerate; existing TestFlight builds are
   unaffected"* — which makes it the one signing artefact here whose loss is an afternoon rather than a
   support ticket.
4. `fvm flutter build ipa --release` once, to prove the archive signs. Not uploaded — uploading is
   T03, and every upload burns a build number forever.

### 5.5 The details that are easy to get wrong

- **The Flutter template signs release builds with the debug key.** The generated
  `android/app/build.gradle.kts` contains, verbatim,
  `signingConfig = signingConfigs.getByName("debug")` under a `// TODO` about adding your own. Leave it
  and every "release" build on the laptop is debug-signed; Play answers with *"You uploaded an APK or
  Android App Bundle that was signed in debug mode"* at the worst possible moment. Deleting that line
  is the actual work of this task, and the second test case exists to keep it deleted.
- **Play App Signing cannot be enrolled before an app record exists.** For a new app it is mandatory
  and it is configured under Play Console ▸ Release ▸ Setup ▸ **App integrity**, on the record
  **N32-T02** creates. So the honest sequence is: generate the upload key here, and tick the DoD line
  when T02's record shows two certificates — the app signing certificate Google holds and the upload
  certificate you hold. Ticking it before T02 is ticking a page you have not looked at.
- **`key.properties` is regenerable; the keystore is not.** `00-README` §7.2 says exactly that — *"local
  only; regenerate from the keystore and its passwords"*. The asymmetry is the whole reason the file is
  ignored and the key is backed up twice.
- **`make check` cannot see this task's main artefact.** `tool/check_policy.dart` scans `lib/` and
  `assets/`; `dart format` and `flutter analyze` read Dart. A Gradle mistake here is caught by the
  anchor test or by a red `android` job ten minutes later, and by nothing else.
- **Never commit a fingerprint you would not publish, and never a password you would.** The SHA-256 of
  the *upload certificate* is public information — it is printed in Play Console and pasted into third
  party consoles routinely. The store password, the key password and the base64 keystore are not, and
  they belong in a password manager and in GitHub secrets, nowhere else. The PR body records the
  fingerprint and the alias; it records no password.
- **If key material ever lands in a commit, a revert is not the fix.** Rewrite the history, rotate the
  key, and — if the key had already signed an upload — open a Play support ticket for an upload-key
  reset. Assume a pushed branch is public.
- **`--split-per-abi` is not for this project.** `13 §3.1`: ship an AAB, never a fat APK. A signed APK
  proves nothing about what Play will accept.
- **Nothing here is time-shaped, with one exception, and the exception must not read a clock.** The
  keystore's validity end date is a date, and it is tempting to assert *"the key has not expired"*.
  That test changes verdict at midnight and is ambiguous for a whole hour once a year, because the
  owner's region ruling puts the UK/Ireland ambiguous hour at **01:00–01:59**. Assert the validity end
  against a **fixed literal date** instead — it must be after `2033-10-22`, which is the far side of
  Play's requirement. If a genuine recency assertion is ever wanted, it takes `withClock` and a case at
  01:30 on the clocks-back night in the `uk-zone` tier, never `DateTime.now()`, which under decision
  #46 may appear in exactly one file under `lib/`.
- **Do not add a row to `docs/calendar.md`.** N00-T06's test asserts the ledger holds **exactly** the
  seven commitments the critique names; an eighth row for the keystore turns
  `'the ledger carries exactly the seven commitments the critique names'` red. Where the key is backed
  up is deliberately written down nowhere in this repository — a map to the key is a copy of the key.

### 5.6 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/signing_config_test.dart` | `'key.properties is gitignored and no keystore or password appears in the repository'` | the anchor; a tracked `key.properties`, a tracked `.jks`, a password literal in any tracked file |
| `test/policy/signing_config_test.dart` | `'the release build type is signed by the release config and never by the debug config'` | the Flutter template's `getByName("debug")` line surviving into a release build |
| `test/policy/signing_config_test.dart` | `'the signing config is created only when key.properties exists, so a runner with no key still builds'` | correction 1 — the null cast that reddens the `android` job on every push |
| `test/policy/signing_config_test.dart` | `'the keystore path is resolved against rootProject, so 13 §4.4's CI heredoc finds it'` | correction 2 — `file()` versus `rootProject.file()`, which fails only at N34 and only on a release day |
| `test/policy/signing_config_test.dart` | `'key.properties names exactly the four properties build.gradle.kts reads'` | a fifth key nobody reads, or a renamed one that resolves to null and throws |
| `test/policy/signing_config_test.dart` | *edge* — the scan reads `git ls-files`, not the filesystem | a laptop-only pass, and a green run on a checkout where nothing is checked out |
| `test/policy/signing_config_test.dart` | *edge* — planting `android/keystore.jks` and adding it to the index turns the anchor red | the anchor asserting a property nobody has watched fail |
| `test/policy/signing_config_test.dart` | *edge* — the keystore validity assertion compares against the literal `2033-10-22` and reads no clock | a test whose verdict changes at midnight, and which is ambiguous for an hour on the clocks-back night |

No `test/domain/uk_zone/` case is added: this task computes, stores and formats no instant. The one
date it asserts is a literal, for the reason in §5.5.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Gate integrity.** Never edit `android/expected_permissions.txt`, `tool/policy_allowlist.txt` or an exit code to make a build green. If the `android` job goes red after this commit, the cause is the Gradle shape in §5.3 and the fix is in §5.3 — not `continue-on-error`, which `13 §4.6` bans by name.
- **No workflow file is written here.** `release.yml` is N34-T01's, and it is the only place the four `SHEDBOOK_*` secrets are ever read.

## 7. Definition of Done

- [ ] `'key.properties is gitignored and no keystore or password appears in the repository'` passes, and was seen to fail first for the stated reason
- [ ] `key.properties` and the keystore are gitignored
- [ ] no password or key material anywhere in git history
- [ ] Play App Signing is enrolled
- [ ] a release build is produced and signed locally
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/signing_config_test.dart
fvm flutter build appbundle --release
make check
```

Then read the artefact rather than trusting the build, because "release" and "signed with the upload
key" are two different facts:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The owner line must be yours. `CN=Android Debug, O=Android, C=US` means the template's debug
`signingConfig` is still in `build.gradle.kts` and the whole task is undone.

Prove the ignore rules and the history are clean:

```bash
git check-ignore -v android/key.properties
git ls-files | grep -Ei '\.(jks|keystore)$|key\.properties'
git log --all -p -S 'storePassword=' -- . | head -40
```

The first names the rule; the second and third must print nothing. Then prove the runner case, which
is the one this task most easily breaks:

```bash
mv android/key.properties android/key.properties.local
fvm flutter build appbundle --release --build-number=1 \
  --dart-define=APP_VERSION=ci --dart-define=APP_BUILD=1
mv android/key.properties.local android/key.properties
```

That is the `android` job's build with no key on the machine. It must complete and print the
`key.properties absent` line — if it fails, take §5.3's blockquote fallback and record which shape
shipped.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(release): signing configuration for both platforms`
