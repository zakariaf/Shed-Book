# 13 — Build, CI and release

This document governs everything between a commit and a shepherd's phone: the pinned toolchain, the gates that make the offline claim mechanically provable instead of merely asserted, the CI job matrix a single developer can actually afford, the lint configuration that is this project's only code reviewer, the size and startup budgets and where their numbers live, the clean-pause marker that detects the crashes Dart never sees, the diagnostics log that replaces a crash reporter, versioning and signing, the store test tracks, and the calendar window in which you must not ship at all. If you are editing `pubspec.yaml`, `analysis_options.yaml`, anything under `.github/`, anything under `android/` or `ios/`, or you are about to cut a tag, this is your document.

> **Decisions applied:** #1 toolchain pin (Flutter 3.44.8 / Dart 3.12.2 via FVM) · #2 the analyzer ceiling · #3 `build_runner` capped below 2.15.2 · #4 `package:test` is never a direct dependency · #5 `pubspec.lock` is committed as the resolution evidence · #7 the `offline-first` pattern is not followed · #10 one source-scanning gate · #14 the global error net · #16 drift is the only generator · #18 CI greps every banned Riverpod-3 API · #26 `sqlite3_flutter_libs` is expected in the lockfile and is not flagged discontinued · #38 the `make-migrations` no-diff check · #48 the `TZ=Pacific/Chatham` hostile run · #63/#65 notification channel ids frozen at release — **eight ids, R49's spellings, not #65's three superseded ones** (§11.2) · #74 the seed script cannot run in release · #75/#76 OCR and voice tag entry are cut, so no ML Kit and no `speech_to_text` in the graph · #83 no `printing` · #87 one binary, no flavors · #93 store privacy declarations · #109 lints (`flutter_lints` + an explicit strict block) · #116 goldens are not a per-PR gate · #117 four integration journeys, reported not blocking · #119 coverage is reported, never gated · #121 the CI shape · #122 the offline gates · #123 crash diagnostics with no network · #124 redaction rules · #126 CI gates size, not speed — **narrowed once, in §6.1.1: CI measures and archives size and gates nothing until a baseline exists** · #127 the app-size budget and its restated spec deviation · #128 release hygiene, build numbers and the seasonal freeze.
>
> **Owner rulings honoured (decision-record §7.0, settled 2026-07-27):** tag OCR and voice tag entry are **cut from v1** — the voice *note* ships — which is what keeps gates G1–G3 satisfiable at all. Tags are unique among **active** animals only. **UK/Ireland first**, which fixes the seasonal freeze window (§11) and the `Europe/London` DST test run (§4.3). The free tier is season-primary with the ewe cap secondary, which is why no release-note or store-listing copy in this document mentions a limit mid-entry. None of these four is open; nothing below reopens them.

**Sibling documents:** [`01-architecture.md`](01-architecture.md) (`tool/check_policy.dart`, the rule tables, `main()`, `LocalLog`'s surface, the global error net), [`02-state-di-navigation.md`](02-state-di-navigation.md) (the lifecycle switch that calls `markCleanPause()`, the Riverpod-3 ban list CI greps for), [`03-data-model-and-schema.md`](03-data-model-and-schema.md) (`build.yaml`, the schema the codegen gate freezes), [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) (the migration matrix and the `make-migrations` no-diff check this document runs), [`06-design-system.md`](06-design-system.md) (the no-white-flash launch configuration), [`08-platform-integration.md`](08-platform-integration.md) (which plugin needs which permission and how it is requested), [`11-monetization-and-store.md`](11-monetization-and-store.md) (billing, the privacy declarations, the store listing), [`12-testing.md`](12-testing.md) (`dart_test.yaml`, the tags, the harness, the golden policy).

> **Naming: settled, not open.** [`CONVENTIONS.md`](CONVENTIONS.md) is binding and outranks this document on any name, path, type shape, signature or word. Two names are this document's to define, under R11, and it defines them in §7: **`markCleanPause()`** and **`session.lock`**. `LocalLog`'s five-method surface is R52's and is not re-opened here.
>
> **Other rulings this document is bound by, adopted without counter-proposal:** **R49** — the eight Android notification channel ids are `reminders.kind`'s eight strings byte-for-byte, so decision #65's `turnout` / `dose` / `withdrawal` are banned spellings and §11.2 uses 03's (`08-platform-integration.md` §2.7 owns the gate). **R54/R56** — policy rule ids are dotted `namespace.name`, and `tool/policy_allowlist.txt`'s `[exempt]` section has exactly four lines on day one. **R60** — no human-facing date is all-numeric, which binds §7.5's Diagnostics line. **R57** — the test tree, which is why §4.3 diffs `test/drift/generated/` and nothing under `test/screens/`.
>
> **Names this document adds** that CONVENTIONS §1 does not list, because they are outside `lib/`, `test/` and `tool/`'s Dart tree. Each follows §4.1's `lower_snake` rule: `.fvmrc` · `.github/workflows/{ci,release,goldens}.yml` · `.github/dependabot.yml` · `tool/assert_permissions.sh` · `android/expected_permissions.txt` · `android/key.properties` (git-ignored) · `ios/Runner/PrivacyInfo.xcprivacy` · `docs/perf/measurements.md` (named by decision #126) · `RELEASES.md`. The `Makefile` is in CONVENTIONS §1 with four targets in its comment; §1.3 below adds three (`goldens-update`, `perf`, `integration`) and says so. **`dart_test.yaml` and its `ci-fast` / `ci-golden` presets are [`12-testing.md`](12-testing.md)'s**, not this document's; CI passes preset names and never re-spells the filters.

---

## 1. What is pinned, and how

### 1.1 The toolchain

**Flutter 3.44.8 stable (2026-07-23), Dart 3.12.2.** Never `channel: stable` unpinned, in any of the four places the version appears. A bump re-runs the whole resolution matrix, because the SDK pins `meta: 1.18.0`, `test_api: 0.7.11` and `intl: 0.20.2` *exactly*, and those three pins are what make `drift_dev` 2.34.5, `build_runner < 2.15.2` and `flutter_riverpod 2.6.1` the only resolvable combination (decision #2).

The version is stated in **`.fvmrc` plus one `env:` block per workflow file** — `ci.yml`, `release.yml` and `goldens.yml` — which is four places. Four is one more than anybody wants, and the assert below is the whole reason it is safe: **every workflow runs it, in the first job that installs Flutter.** Within `ci.yml` that is `gate`, and every other job in the file `needs:` it, so one assert covers the workflow. `release.yml` and `goldens.yml` have one job each and carry their own. A workflow that installs Flutter without it is the defect, and `goldens.yml` is the one people forget, because it is the only macOS job and the only one that never runs on a PR.

```json
// .fvmrc
{ "flutter": "3.44.8" }
```

```yaml
# .github/workflows/ci.yml (excerpt)
env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc. Asserted below. Never 'stable'.
```

```bash
# CI step, three lines, no script file needed. Copied into all three workflows
# verbatim. It is not factored into a composite action, because a composite
# action would be a fifth place the version could hide.
PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
[ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc says $PINNED, workflow says $FLUTTER_VERSION"; exit 1; }
flutter --version | grep -q "Flutter $FLUTTER_VERSION" || { echo "::error::runner is not on $FLUTTER_VERSION"; exit 1; }
```

Locally: `fvm use 3.44.8`, then `fvm flutter …` or a shell alias. The `.fvm/` directory is git-ignored; `.fvmrc` is committed.

**Anti-patterns.** `channel: stable` with no `flutter-version`. A different version in the workflow than in `.fvmrc` — that is how a green CI ships a binary nobody built locally. Upgrading Flutter in the same commit as anything else: a toolchain bump is its own commit, its own `flutter pub get`, its own `pubspec.lock` diff, and its own read of that diff.

### 1.2 `pubspec.lock` is committed, and it is evidence

Decision #5: before any other work, run `flutter pub get` against the dependency table in decision-record §5 on Flutter 3.44.8 and **commit the resulting `pubspec.lock`**. It is the doc set's proof that the table resolves at all — four of the ten research notes recommended a `build_runner` constraint that does not.

CI re-asserts it two ways: `flutter pub get` must succeed, and gate **G2** (§2.4) reads the lockfile and fails on any package not on the allowlist. A lockfile diff in a PR that does not also change `pubspec.yaml` is a review stop: something upstream moved and you are about to ship it.

### 1.3 The `Makefile`

CONVENTIONS §1 lists four targets in its comment. **Three more are added here.** `perf` and `integration` come from decisions #126 and #117, because both are things a solo developer runs on a desk with a phone plugged in and neither belongs in CI. `goldens-update` comes from [`12-testing.md`](12-testing.md) §11.4, which owns the golden policy and asked for the split in writing: **a target called `goldens` that silently passes `--update-goldens` is the easiest way there is to green a broken golden**, because you type it to check and it always agrees with you. So `goldens` verifies and `goldens-update` re-baselines, and nothing does both.

`test` and `goldens` are 12's targets, reproduced and not redefined. `-P ci-fast` and `-P ci-golden` are `dart_test.yaml` presets and `dart_test.yaml` is 12's file: `ci-fast` is `--exclude-tags golden` **plus** the `migration` tag's `allow_test_randomization: false`, which a bare `--exclude-tags golden` on the command line would silently drop. Pass the preset name; never re-spell the filter.

```make
# Makefile
FLUTTER ?= fvm flutter
DART    ?= fvm dart

gen:                      ## codegen + migration artefacts
	$(DART) run build_runner build --delete-conflicting-outputs
	$(DART) run drift_dev make-migrations

check:                    ## cheapest failure first: <1s, then seconds, then tens of seconds
	$(DART) run tool/check_policy.dart
	$(DART) format --output=none --set-exit-if-changed .
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

test:                     ## 12-testing.md §11.4. Two commands, because TZ is per-process.
	$(FLUTTER) test -P ci-fast --test-randomize-ordering-seed random --coverage
	TZ=Europe/London $(FLUTTER) test --tags uk-zone

goldens:                  ## VERIFY against the committed PNGs. Never a per-PR gate (#116)
	$(FLUTTER) test -P ci-golden

goldens-update:           ## RE-BASELINE. A deliberate act, its own commit (12 §8.5)
	$(FLUTTER) test -P ci-golden --update-goldens

perf:                     ## decision #126 — needs a real device, profile mode
	$(FLUTTER) run --profile --trace-startup -d $(DEVICE)

integration:              ## decision #117 — four journeys, real device, reported not blocking
	$(FLUTTER) test integration_test -d $(DEVICE)
```

**Where the network is genuinely needed, stated precisely, because "offline build" is a claim this project will be held to.** `package:sqlite3`'s build hooks download a sha256-verified prebuilt binary from GitHub (decision-record §3.4 #3). That fetch happens on a **cold** cache — a fresh clone, a new pub cache, or after `flutter clean` — and the artefact is cached afterwards, so a warm laptop builds in plane mode. `flutter pub get` needs a network for the same reason and always has. **Which target trips the fetch first — `pub get`, `gen`, `test` or `build` — is unverified**; find out once, in plane mode, and write the answer in the README. Without that paragraph the first offline build failure gets mistaken for a regression, and somebody spends an evening on it.

---

## 2. The offline contract and the gates that prove it

### 2.1 What is actually claimed

Three tiers exist; two are claimable (decision-record §3.1). The **only** public wording permitted, verbatim:

> "Shed Book has no account, no server and no sync. The Android build ships without the internet permission, so the app itself cannot connect to anything. Your records only leave the phone when you deliberately export and share them."

**Never write "your data never leaves your phone."** It does, the moment they AirDrop a CSV — which is the backup story the product depends on. `tool/check_policy.dart` bans that phrase as literal text under `lib/` and `assets/`; the store listing and the release notes are outside its reach and are a human checklist item (§12).

### 2.2 G0 — the prerequisite, and it is unwritten until it has been run

**G0 is not a CI job. It is a one-afternoon empirical procedure that must complete before a single `tools:node="remove"` line is committed, and until it does, the offline gate in CI is unwritten, not merely unimplemented** (decision-record §1 item 5, §3.2). Three research notes independently hard-coded the removal of `ACCESS_NETWORK_STATE`; the only Play Billing AAR manifest anyone could fetch was version **2.0.3**, six majors behind the **8.0.0** that `in_app_purchase_android` actually pulls in. If billing 8.0.0 declares that permission and the merger strips it, the failure surfaces as a purchase flow that misbehaves on a flaky connection, in production, on someone else's phone.

Run it exactly once, on a machine with the Android toolchain, with `in_app_purchase` already in `pubspec.yaml`:

```bash
flutter build appbundle --release

# 1. The merger's decision tree — it names the source of every permission.
cat build/app/outputs/logs/manifest-merger-release-report.txt | grep -i -A3 'permission'

# 2. The permissions that actually shipped, read off the artefact, not the source.
#    Split on '<' first: matching on the substring "permission" would MISS
#    com.android.vending.BILLING, which is the one this project cares most about.
java -jar bundletool.jar dump manifest \
  --bundle build/app/outputs/bundle/release/app-release.aab > merged-manifest.xml
tr '<' '\n' < merged-manifest.xml | grep '^uses-permission' \
  | grep -o 'android:name="[^"]*"' | sed 's/.*"\(.*\)"/\1/' | sort -u

# 3. Confirm the debug build still HAS internet, or hot reload is gone.
flutter build apk --debug
# then read the debug merged manifest and confirm android.permission.INTERNET is present.
```

**What you record, in this file, in the commit that closes G0** (replace this block; do not delete it):

| Question | Answer | Recorded on |
|---|---|---|
| Exact `uses-permission` set in the release AAB | *not yet run* | — |
| Does Play Billing 8.0.0 contribute `ACCESS_NETWORK_STATE`? | **UNVERIFIED — G0 has not been run** | — |
| Does `tools:node="remove"` in `src/main` leave the `src/debug` `INTERNET` intact? | **UNVERIFIED** — merge priority says build type outranks main, so it should; confirm, do not assume | — |
| Effective `minSdk` after plugin merging | **UNVERIFIED** — read it from the merged manifest; never set it from memory | — |

**The ruling G0 produces.** Removing `INTERNET` is safe and proven — commit that line. For `ACCESS_NETWORK_STATE` there are exactly two permitted outcomes and *neither is a removal on faith*:

- **Absent from the merged manifest** → nothing to do. The canonical set stays at §3.1's **eight entries**, of which seven are `uses-permission` lines G1 asserts and the eighth is `INTERNET`, asserted by its *absence*. `android/expected_permissions.txt` therefore holds **seven** uncommented lines. Whenever this document says "eight", it means §3.1's table; whenever it says "seven", it means lines in the expected file. They are the same fact counted two ways, and confusing them is how somebody adds a ninth line to make a red build green.
- **Present, contributed by billing** → **leave it.** Add it to `android/expected_permissions.txt` with its source in a comment, and record the copy consequence: the Play listing will show "view network connections". That does not contradict the §2.1 wording, because `ACCESS_NETWORK_STATE` cannot open a socket — but a shepherd reading the permission list will see it, so it belongs in the store listing's own honesty paragraph.

Until this table is filled in, `android/expected_permissions.txt` does not exist and G1 cannot be written.

### 2.3 G1 — the permission assertion on the shipped AAB

**Blocking, every push.** It reads the built artefact, never the source manifest, because the source manifest is not what ships — the merger blends in every library's manifest with no warning.

It asserts **exact set equality**, not the absence of `INTERNET`. The failure mode this gate exists for is a plugin bump in month six quietly merging a *new* permission; a grep for one string cannot see that.

```bash
#!/usr/bin/env bash
# tool/assert_permissions.sh — gate G1.
# Not a violation of decision #10 (one *source-scanning* gate): this reads a built
# artefact and needs the Android toolchain, so it can never live in check_policy.dart.
set -euo pipefail

AAB="${1:-build/app/outputs/bundle/release/app-release.aab}"
EXPECTED="android/expected_permissions.txt"
BUNDLETOOL="${BUNDLETOOL:-bundletool.jar}"

[ -f "$EXPECTED" ] || { echo "::error::$EXPECTED is missing — gate G0 has not been closed."; exit 2; }

java -jar "$BUNDLETOOL" dump manifest --bundle "$AAB" > merged-manifest.xml

# Split on '<' and select the uses-permission elements, then read their android:name.
# Do NOT filter on the substring "permission": com.android.vending.BILLING does not
# contain it, and that is the one entry a careless filter would silently drop.
# The '^uses-permission' prefix also catches <uses-permission-sdk-23>, deliberately.
tr '<' '\n' < merged-manifest.xml \
  | grep '^uses-permission' \
  | grep -o 'android:name="[^"]*"' \
  | sed 's/.*"\(.*\)"/\1/' | sort -u > actual-permissions.txt

grep -v '^\s*#' "$EXPECTED" | grep -v '^\s*$' | sort -u > expected-sorted.txt

if ! diff -u expected-sorted.txt actual-permissions.txt; then
  echo "::error::The shipped bundle's permission set does not match $EXPECTED."
  echo "Lines starting '-' are missing; lines starting '+' were added by a dependency."
  echo "Find the contributor in build/app/outputs/logs/manifest-merger-release-report.txt (gate G4)."
  echo "Do NOT edit $EXPECTED to make this pass without understanding what changed."
  exit 1
fi
echo "G1 ok — permission set matches exactly."
```

```
# android/expected_permissions.txt
# Sorted, one per line. Every line names the library that contributes it.
# Editing this file to silence G1 is the single worst thing you can do to this project.
android.permission.POST_NOTIFICATIONS      # flutter_local_notifications (merged)
android.permission.RECEIVE_BOOT_COMPLETED  # we add — reschedule after reboot
android.permission.RECORD_AUDIO            # record (merged) — the voice NOTE, not voice tag entry
android.permission.SCHEDULE_EXACT_ALARM    # we add — user-granted. NEVER USE_EXACT_ALARM
android.permission.VIBRATE                 # flutter_local_notifications (merged)
android.permission.WAKE_LOCK               # wakelock_plus (merged)
com.android.vending.BILLING                # Play Billing 8.0.0 AAR via in_app_purchase (merged)
# android.permission.INTERNET              — ABSENT. Removed at merge time. If this line
#                                             ever becomes real, the product's central claim is void.
# android.permission.ACCESS_NETWORK_STATE  — PENDING G0. Do not add or remove on faith.
```

Exit codes: `0` match · `1` set mismatch · `2` the gate could not run (missing expected file, missing bundletool, missing AAB) — which is still a failure, never a skip.

**`bundletool` is fetched in CI**, not committed:

```yaml
- name: Fetch bundletool
  run: curl -sSL -o bundletool.jar \
       https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
```

> **Unverified:** using `latest` here means the gate's tool floats. It has been stable for years and `dump manifest` is its oldest command, but if a bundletool release ever changes the dump format this gate fails closed (exit 1 on a diff), which is the correct direction. Pin a version if that ever happens once.

### 2.4 G2 — the direct-dependency allowlist

**Blocking, every push.** It is `_checkLockfile` inside `tool/check_policy.dart` ([`01-architecture.md`](01-architecture.md) §3.2) — no second script (decision #10). It reads `pubspec.lock` and checks **three kinds separately** against three sections of `tool/policy_allowlist.txt`:

| Lockfile kind | Allowlist section | Why it is separate |
|---|---|---|
| `direct main` | `[dependencies]` | Ships. Every line was read against decision-record §5.1. |
| `direct dev` | `[dev_dependencies]` | Never ships. `build_runner` legitimately drags `shelf` and `web_socket_channel` into the graph. |
| `transitive` | `[transitive]` | Documented, with the reason on the line. |

Two entries in `[transitive]` exist specifically so nobody "fixes" them:

```
http                  # via timezone AND via package_info_plus. Two regular edges. Unavoidable.
sqlite3_flutter_libs  # no-op EOL shim dragged in by drift_flutter. NOT flagged discontinued on
                      # pub.dev, so a check keyed on that flag will not fire. Expected. Never a direct dep.
```

**Anti-pattern, and it is the one four notes wrote:** a gate that asserts "no `http` in `pubspec.lock`". It is **unsatisfiable** — `flutter_local_notifications → timezone → http ^1.6.0` and `wakelock_plus → package_info_plus → http ^1.6.0` are both regular dependency edges. Writing that gate means either deleting reminders and the wakelock, or disabling the gate. The claim G2 makes is narrower and true: *no package enters the graph unreviewed.*

Also banned outright by this gate's `[dependencies]` section, because they are the ones that will be proposed: `connectivity_plus`, `workmanager`, `battery_plus`, `firebase_*`, `printing`, `google_fonts`, `google_mlkit_text_recognition`, `speech_to_text`, `permission_handler`, `purchases_flutter`. Every one has a rejection row in decision-record §5.3.

### 2.5 G3 — the import-level source scan

**Blocking, every push.** Also `tool/check_policy.dart`: `_bannedEverywhere` (package URIs) plus the `net.*` rows of `_bannedText` (APIs that do not arrive on a `package:` URI). The two halves are not redundant — `HttpClient` and `Socket` come from `dart:io`, which any file may legitimately import, and `Image.network` is in the SDK.

What it proves: **our own source cannot reach a network API.** What it does not prove: that a dependency does not. That is G1's job, and the split is the point.

The same script carries the decision #18 requirement that **CI greps for every banned Riverpod-3 API**. The table is [`02-state-di-navigation.md`](02-state-di-navigation.md) §2.4's and is not restated here, because a second copy is a copy that goes stale: 02 owns providers, and its rows are the `rp3.*` entries of `_bannedText`. What this document owes the reader is the count and the reason. **Thirteen rows**, scoped `lib/**` and `test/**` unless 02 says otherwise:

`retry:` · `ProviderContainer.test` · `tester.container` · `isAutoDispose` · `Mutation` / `ref.mutate(` · `valueOrNull` / `.requireValue` / `.hasValue` / `.asData` · `ref.mounted` and `Ref` written as a type name · `ProviderObserverContext` / `didUnmountProvider` / `didCreateProviderContainer` · `StateProvider` / `StateNotifier` / `ChangeNotifierProvider` · `@riverpod` / `riverpod_annotation` / `riverpod_generator` / `riverpod_lint` · `hooks_riverpod` / `flutter_hooks` / `useProvider` · `package:riverpod/` · `overrideWith` / `overrideWithValue` (**`lib/` only** — overrides are a test mechanism).

The reason it is a grep and not a review item: every tutorial published after 2025 shows the 3.x form, and the analyzer will not save you — several of them **compile** against 2.6.1 and mean something else. If 02 §2.4 gains a row, this count changes and so does the DoD line that names it.

### 2.6 G4 — the merger report, archived

**Non-blocking. Diagnostic only.** `build/app/outputs/logs/manifest-merger-release-report.txt` is uploaded as a CI artefact on every Android build. It is the only thing that answers "*which* library added that?" when G1 goes red. It is not a gate because its format is not a contract.

### 2.7 G5 — iOS, honestly

**There is no iOS permission to remove.** iOS has no manifest analogue of `INTERNET`, so iOS enforcement is *construction plus observation*, and the doc set says so rather than implying parity:

| Check | How | When |
|---|---|---|
| No `NSAppTransportSecurity` key in `Info.plist` | `plutil -p ios/Runner/Info.plist \| grep -c NSAppTransportSecurity` must be `0` | Every push (it is a text check, so it can live in CI) |
| `PrivacyInfo.xcprivacy` present **and in the Runner target's Copy Bundle Resources** | Xcode → Archive → Organizer → **Generate Privacy Report**; read the PDF | Once before first submission, and after every plugin bump |
| App Privacy answers are "Data Not Collected" | App Store Connect | Every submission |
| No socket opens at runtime | One pass with **App Privacy Report** enabled (Settings ▸ Privacy ▸ App Privacy Report), or `nettop -p <pid>` on a tethered device, while doing a full airplane-mode-off session | Once per release, by hand |

> **Flutter 3.44 made Swift Package Manager the default iOS dependency manager.** Plugin resource bundles — which is how a plugin's `PrivacyInfo.xcprivacy` reaches the app — are packaged differently by SwiftPM than by CocoaPods, and a dropped manifest surfaces as `ITMS-91061: Missing privacy manifest` at upload time. Re-generate the privacy report after the SwiftPM migration; do not carry a CocoaPods-era assumption forward.

### 2.8 The gate table

| Gate | Proves | Implementation | Fails on | Blocking |
|---|---|---|---|---|
| **G0** | The merged release manifest is what we think it is | Manual, once, §2.2 | — (it is a prerequisite, not a job) | **Blocks writing G1 at all** |
| **G1** | No plugin silently merged a permission | `tool/assert_permissions.sh` on the release `.aab` | Any difference from `android/expected_permissions.txt` | **Yes**, every push |
| **G2** | No package entered the graph unreviewed | `tool/check_policy.dart` → `_checkLockfile` | A lockfile entry not in its section's allowlist | **Yes**, every push |
| **G3** | Our source cannot reach a network API | `tool/check_policy.dart` → `_bannedEverywhere` + `net.*` | Any banned import or literal under `lib/`/`test/` | **Yes**, every push |
| **G4** | *Which* library contributed a permission | Archive `manifest-merger-release-report.txt` | — | No, diagnostic |
| **G5** | iOS opens no socket | Construction + observation, §2.7 | The ATS check fails; the rest is manual | ATS check yes; the rest manual, per release |

**Anti-patterns, all four previously written down by somebody.** Grepping `build/app/intermediates/` — that directory accumulates debug and profile artifacts and Flutter's debug/profile manifests *do* declare `INTERNET`, so the grep fires on a stale directory and then gets deleted for being flaky. `apkanalyzer` on an APK — the APK is not what ships. `HttpOverrides.global` as a fourth proof — a runtime belt over a manifest brace that already makes sockets impossible on Android, and it proves nothing on iOS. Editing `android/expected_permissions.txt` to make a red build green.

---

## 3. The complete permission set

`08-platform-integration.md` owns *how* each permission is requested and when. This section owns *what the shipped artefacts declare*, because that is what G1 and G5 assert against.

### 3.1 Android — eight entries, not seven

| Permission | Source | Why |
|---|---|---|
| `android.permission.POST_NOTIFICATIONS` | `flutter_local_notifications` (merged) | Reminders (spec §7.6). Requested the first time the user creates a reminder, never at first launch. |
| `android.permission.VIBRATE` | `flutter_local_notifications` (merged) | Notification vibration. No custom sound, no badge count. |
| `android.permission.RECEIVE_BOOT_COMPLETED` | **we add** | Reminders survive a reboot; `ReminderReconciler` rebuilds the OS projection. |
| `android.permission.SCHEDULE_EXACT_ALARM` | **we add** | A colostrum reminder that fires 40 minutes late is useless. **Never `USE_EXACT_ALARM`** — Play rejects it for this app category. |
| `android.permission.RECORD_AUDIO` | `record` (merged) | The voice **note** (spec §7.2). Not voice tag entry — that is cut (§7.0 ruling). |
| `android.permission.WAKE_LOCK` | `wakelock_plus` (merged) | The default-off "Keep screen on" toggle. |
| `com.android.vending.BILLING` | Play Billing 8.0.0 AAR via `in_app_purchase` (merged) | The one-time unlock. The billing AAR is a **Play-Services-adjacent artifact** whose transitive Gradle graph is reviewed on every Billing Library bump. |
| `android.permission.INTERNET` | — | **ABSENT.** Explicitly removed at merge time. |

Zero permissions come from `image_picker` (it uses the system camera UI and the system photo picker) and zero from `path_provider`, `share_plus`, `file_selector`, `drift`/`sqlite3`, `pdf` or `device_info_plus`. That is not luck — it is why each of them was chosen over its more popular alternative (decision-record §5.3).

```xml
<!-- android/app/src/main/AndroidManifest.xml — the removal, and only the proven one -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">

    <!-- Proven safe by G0. Play Billing is binder IPC to the Play Store app,
         which owns the socket. The Play Store's process is not ours. -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />

    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <!-- ACCESS_NETWORK_STATE: no line here until G0 says which line to write. -->
    <!-- NOT USE_EXACT_ALARM. Play policy restricts it to alarm/timer and
         calendar apps; Shed Book is neither. 08 §2.9. -->

    <!-- The <application> block's two flutter_local_notifications receivers are
         08 §8.3's and are not reprinted here: the plugin has declared neither
         itself since v16, so omitting them silently loses every reminder
         across a reboot. Copy them from 08, not from a blog post. -->
</manifest>
```

The elision above is deliberate and it is the one place in this document where "…" would have been dangerous: a truncated manifest is a manifest somebody pastes.

Build configuration that belongs here rather than in a plugin's README. The floors are [`08-platform-integration.md`](08-platform-integration.md) §8.3's, taken as the maximum across the plugin set; this document only says where they are asserted:

- `targetSdk = 36`, `compileSdk = 36` from day one. Play requires API 36 for new apps and updates from **31 August 2026** (extensions to 1 November 2026). A greenfield project has no reason to be behind.
- `minSdk = 24`, which is `flutter_local_notifications`' floor and the highest in the set (08 §8.3). It is not left at `flutter.minSdkVersion` and hoped for: **read the effective value out of the merged manifest during G0, record it in §2.2's table, and set it explicitly.** A `minSdk` that moves because a plugin bumped its own is a silent change to who can install the app.
- **Java 17** (`actions/setup-java` in §4.3 and §4.4 sets exactly this) and **AGP ≥ 8.12.1**, which is `share_plus`'s floor and above `flutter_local_notifications`' 8.11.1.
- `coreLibraryDesugaringEnabled = true` with `desugar_jdk_libs 2.1.4` — required by `flutter_local_notifications` 22.2.0.
- **Ship an AAB, never a fat APK** (decision #127). `--split-per-abi` is for direct download, which we do not do. Play App Signing is mandatory for new apps: you hold the *upload* key, Google holds the *app signing* key.
- **The application id / bundle id is chosen once, before the first upload, and can never change on either store.** No document in this set has fixed the string yet; the shell snippets below write it as `$APP_ID`. Fix it in `android/app/build.gradle.kts` and the Xcode target in the same commit, and record it in `RELEASES.md`'s header so nobody has to go and read a Gradle file to find out what the app is called.

### 3.2 iOS

There is no permission to remove, so the iOS surface is three usage strings, one appearance key, one privacy manifest, and the absence of four things. [`08-platform-integration.md`](08-platform-integration.md) §8.4 owns the key set and the usage-string copy; this section owns what the shipped artefact is asserted to contain.

| `Info.plist` key | Needed by | Rule |
|---|---|---|
| `NSCameraUsageDescription` | `image_picker` system camera | The copy is 08 §8.4's, verbatim. One plain sentence. No "we may", no "should". |
| `NSMicrophoneUsageDescription` | `record` (voice notes) | Names the voice note explicitly, so the prompt is not a surprise. |
| `NSPhotoLibraryUsageDescription` | `image_picker`, **App Store policy** | **Declared.** `PHPickerViewController` needs no authorisation on iOS 14+, so the string exists for review, not for a prompt (08 §8.4). Settled there; not an open question here. |
| `UIUserInterfaceStyle` = `Dark` | Every theme is dark | There is no light appearance ([`06-design-system.md`](06-design-system.md) §9.2). |
| `NSAppTransportSecurity` | — | **Must not be present.** Its absence is the half of G5 a text check can do. |
| `UIBackgroundModes` | — | **Must not be present.** No background work, no push capability, no notification entitlement. |
| `UIFileSharingEnabled` · `LSSupportsOpeningDocumentsInPlace` | — | **Neither is set in v1.** Both expose `Documents/`, and nothing of ours is there — the database *and* the media folder live in Application Support precisely so a shepherd tidying up in Files cannot delete `shed_book.sqlite` (decision #27; 08 §8.4). Superseded, recorded, not re-opened. |

`ios/Runner/PrivacyInfo.xcprivacy`'s contents are **[`11-monetization-and-store.md`](11-monetization-and-store.md) §9.2's**. 11 owns store compliance and it has already turned decision #93's conditional wording into a ruling; this table reproduces that ruling because G5 and the §12 checklist assert against it, and it does **not** re-decide it:

| Category | Reason code | In our manifest |
|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | **Yes.** The database and its WAL, the media folder, `MediaSweeper`'s orphan `stat` calls and the export temp files are all inside the app container. |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `E174.1` | **Yes.** Free space is genuinely queried before a photo or a PDF is written — `DiskFull` is one of the six `ShedFailure` variants. |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | **No, in v1.** `shared_preferences` is not a dependency and the entitlement is a SQLite row (decision #88). Re-read the generated privacy report after any plugin bump; if app-level `NSUserDefaults` use ever appears, add the code and do not agonise. |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | **No.** The Flutter engine's own manifest declares it, and this app writes no native code that reads `systemUptime`. |

> **One item is open, and it is 11's to close.** `85F4.1` is "display disk-space info to the user", and Settings ▸ Diagnostics does display storage figures (§8.5). Note 07's own two tables disagree about whether `85F4.1` is a valid app-level code, and no critic resolved it. **Re-read Apple's `NSPrivacyAccessedAPITypeReasons` page before the first submission and record the answer in 11 §9.2, not here.** `E174.1` is unambiguously correct and ships either way, so nothing before first submission is blocked.

`NSPrivacyTracking` is `false`, `NSPrivacyTrackingDomains` and `NSPrivacyCollectedDataTypes` are genuinely empty arrays. **Never put `0A2A.1` or `C56D.1` in an app's manifest** — they are third-party-SDK codes and their appearance is the shape of `ITMS-91055: Invalid API reason declaration`. Over-declaring within your own valid codes is not a rejection cause; under-declaring is (`ITMS-91053`).

---

## 4. The CI job matrix

### 4.1 The budget, stated first because it determines the design

GitHub Actions bills minutes with an OS multiplier: **Linux 1×, Windows 2×, macOS 10×**. GitHub Free includes 2,000 minutes/month on a **private** repository, which is **200 macOS minutes/month**. A Flutter iOS build with a cold pub/SwiftPM cache is 10–20 minutes.

| Plan / repo | Linux minutes | macOS minutes | iOS builds/month |
|---|---|---|---|
| Free, private | 2,000 | 200 | 10–20, **total** |
| Pro, private | 3,000 | 300 | 15–30 |
| Public repo | unlimited on standard runners | unlimited on standard runners | budget is not the constraint |

Running an iOS build on every push is not a budgeting mistake; it is a same-week outage. **For v1, iOS is built by hand on the developer's Mac.** `flutter build ipa` plus Transporter is a five-minute manual step performed maybe once a month; automating it costs signing-secret plumbing, `fastlane match`, and the entire macOS budget, to save five minutes. This is the opposite of the usual Flutter-CI advice and for a solo developer with a Mac it is correct.

If the repository is public, the budget question disappears and the *only* remaining argument against per-push macOS is wall-clock time. The job shapes below do not change.

### 4.2 Jobs and triggers

| Job | Trigger | Runner | Contents | Blocking |
|---|---|---|---|---|
| `gate` | every push to `main`, every PR | `ubuntu-latest` | toolchain pin check · `pub get` · `check_policy` (**G2+G3**) · `dart format --set-exit-if-changed` · `analyze --fatal-infos --fatal-warnings` · ATS check (**G5** text half) | Yes |
| `codegen` | every push, every PR | `ubuntu-latest` | `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` | Yes |
| `test` | every push, every PR | `ubuntu-latest` **+ `libsqlite3-dev`** | `-P ci-fast`, randomised order · `TZ=Europe/London --tags uk-zone` over the **whole** suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · coverage artefact | Yes |
| `android` | every push, every PR | `ubuntu-latest` | release AAB · **G1** · **G4** artefact | Yes |
| `release` | tag `v*` | `ubuntu-latest` | signed AAB with the release build number · **G1** · `--analyze-size` JSON · symbols · all artefacts | Yes |
| `goldens` | tag `v*` **or** `workflow_dispatch` | `macos-latest` | `flutter test -P ci-golden` — eight images | Yes when it runs |
| iOS archive | — | the developer's Mac | `flutter build ipa --obfuscate --split-debug-info=…` | Manual |
| integration journeys | weekly + before every tag | the developer's desk, phone plugged in | `make integration DEVICE=…` | **Reported, never blocking** |

The four integration journeys are "nightly" in decision #117's words. Read that as *a scheduled job on your own machine* — a `launchd`/cron entry running `make integration` against a plugged-in phone. GitHub's `schedule:` trigger cannot drive a real device, hosted emulators run debug mode only, and Firebase Test Lab requires an account and an upload, which is the exact posture the product rejects (#117). Saying "nightly CI" here would be a promise the infrastructure cannot keep.

### 4.3 `ci.yml`

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc — asserted in the first step. Never 'stable'.

jobs:
  gate:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get

      # Cheapest failure first. The gate is sub-second; analyze is tens of seconds.
      # Gates G2 (dependency allowlist) and G3 (import scan) both live here.
      - name: Policy gate (G2 + G3)
        run: dart run tool/check_policy.dart

      - name: Format
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      # G5, the half a text check can do.
      - name: iOS has no ATS exception
        run: |
          if grep -q NSAppTransportSecurity ios/Runner/Info.plist; then
            echo "::error::NSAppTransportSecurity must not appear in Info.plist"; exit 1
          fi

  codegen:
    runs-on: ubuntu-latest
    needs: gate
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }
      - run: flutter pub get

      # Generated files ARE committed, so a clean checkout builds. CI proves they
      # match their sources. This is the single most valuable step in the pipeline
      # after G1: the failure is invisible locally and lethal on a fresh clone.
      - name: Regenerate
        run: |
          dart run build_runner build --delete-conflicting-outputs
          dart run drift_dev make-migrations

      - name: Generated code and schema artefacts are fresh
        run: |
          git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/ || {
            echo "::error::Generated artefacts are stale. Run 'make gen' and commit."
            exit 1; }

  test:
    runs-on: ubuntu-latest
    needs: gate
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # `flutter test` runs on the HOST, so sqlite3_flutter_libs (a plugin, and an
      # EOL no-op shim anyway) is never applied and the host must supply sqlite3.
      # This is the one line between a working and a red CI on day one.
      # 12-testing.md §3.2.
      - name: Host sqlite3
        run: sudo apt-get install -y libsqlite3-dev

      - run: flutter pub get

      # Randomised ordering catches order-dependent state, which otherwise shows up
      # as a flake at 11pm on release day. `-P ci-fast` is dart_test.yaml's preset:
      # it excludes goldens (pinned to one runner and one exact Flutter version,
      # #116) and the `migration` tag carries allow_test_randomization: false,
      # because migration tests are order-sensitive by design. 12-testing.md owns
      # dart_test.yaml; CI passes the preset name and nothing else.
      # UNVERIFIED (12-testing.md §11.2): `flutter test` historically honours
      # less of dart_test.yaml than `dart test` does, and whether
      # allow_test_randomization: false actually takes effect on the migration
      # tag has not been confirmed on 3.44.8. If migration tests flake under
      # randomisation, the fallback is fixed and named: add
      # `--exclude-tags migration` here and a second, non-randomised
      # `flutter test --tags migration` step below. Do not respond by removing
      # the randomisation — it is the point of the job.
      - name: Test
        run: |
          flutter test -P ci-fast \
            --reporter github \
            --test-randomize-ordering-seed random \
            --coverage

      # The owner's region ruling: UK/Ireland. The ambiguous DST hour is 01:00–01:59
      # and that is the hour the withdrawal and hours-penned cases target.
      # NOT scoped to test/domain: 12-testing.md §2.4 puts two uk-zone files in
      # test/data/ and test/features/, and a `test/domain` scope would run them in
      # the runner's own zone (UTC), where they pass vacuously.
      - name: Zone-pinned tests in the target zone
        run: TZ=Europe/London flutter test --tags uk-zone --reporter github

      # The hostile zone: +12:45/+13:45, a non-hour offset, DST in the southern summer.
      # Decision #48. It asserts against the DEVICE zone, never an injected tz.Location.
      # uk-zone files are EXCLUDED here: they assert the process offset and fail
      # loudly under any other zone, which is the behaviour 12 wants and would be
      # a false red in this step.
      - name: Domain tests in a hostile zone
        run: TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone --reporter github

      # Coverage is REPORTED, never gated (#119). One number that means something:
      # coverage of lib/domain/**. *.g.dart and *.drift.dart are stripped;
      # *.freezed.dart is NOT in the strip list, because freezed is rejected.
      - uses: actions/upload-artifact@v7
        if: always()
        with: { name: coverage, path: coverage/lcov.info }

  android:
    runs-on: ubuntu-latest
    needs: [gate, codegen, test]
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }
      - run: flutter pub get

      - name: Build release bundle
        run: |
          flutter build appbundle --release \
            --build-number=${{ github.run_number }} \
            --dart-define=APP_VERSION=ci --dart-define=APP_BUILD=${{ github.run_number }} \
            --obfuscate --split-debug-info=build/symbols/android

      - name: Fetch bundletool
        run: curl -sSL -o bundletool.jar \
             https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar

      - name: G1 — the shipped permission set is exactly the expected set
        run: bash tool/assert_permissions.sh

      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: android-${{ github.run_number }}
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/app/outputs/logs/manifest-merger-release-report.txt   # G4
            build/symbols/android
            merged-manifest.xml
```

**Action versions.** `actions/checkout` v7.0.1, `actions/cache` v6.1.0, `actions/upload-artifact` v7.0.1, `actions/setup-java` v5, `subosito/flutter-action` **v2.23.0 on the v2 major tag — there is no v3**. These were read off the GitHub API on 2026-07-20 / 2026-06-26 / 2026-04-10 / 2026-03-25 by note 07 and are **not** covered by decision-record §5, which is a pub.dev table. Re-verify before the first run; anyone who tells you `flutter-action@v3` exists is remembering, not checking.

**Dependabot is enabled for GitHub Actions versions only.** `.github/dependabot.yml` declares exactly one ecosystem, `github-actions`, monthly. It is **not** pointed at pub: a plugin bump can change the merged manifest or a privacy manifest, so pub updates go through `flutter pub outdated` read by a human (§4.6), never through a bot that opens a green PR.

### 4.4 `release.yml` — tag `v*`

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags: ['v*']

env:
  FLUTTER_VERSION: '3.44.8'

jobs:
  aab:
    runs-on: ubuntu-latest
    timeout-minutes: 35
    steps:
      # Warns, never blocks — §11. The one release that must be able to run
      # during the freeze is the hotfix the freeze exists to make rare.
      - name: Seasonal freeze check
        run: |
          M=$(date -u +%m)
          case "$M" in 02|03|04)
            echo "::warning::LAMBING FREEZE (1 Feb – 30 Apr). Only a data-loss-class hotfix ships now — §11.1." ;;
          esac

      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # §1.1: every workflow that installs Flutter re-asserts the pin. Verbatim.
      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get

      - name: Write the upload keystore
        env:
          KEYSTORE_B64: ${{ secrets.SHEDBOOK_KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_B64" | base64 --decode > android/upload-keystore.jks
          cat > android/key.properties <<EOF
          storeFile=upload-keystore.jks
          storePassword=${{ secrets.SHEDBOOK_KEYSTORE_PASSWORD }}
          keyAlias=${{ secrets.SHEDBOOK_KEY_ALIAS }}
          keyPassword=${{ secrets.SHEDBOOK_KEY_PASSWORD }}
          EOF

      - name: Build name comes from the tag; build number from this workflow's run
        run: |
          NAME="${GITHUB_REF_NAME#v}"
          echo "BUILD_NAME=$NAME"     >> "$GITHUB_ENV"
          echo "BUILD_NUMBER=${{ github.run_number }}" >> "$GITHUB_ENV"

      - run: |
          flutter build appbundle --release \
            --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
            --dart-define=APP_VERSION="$BUILD_NAME" --dart-define=APP_BUILD="$BUILD_NUMBER" \
            --obfuscate --split-debug-info=build/symbols/android

      - name: Fetch bundletool
        run: curl -sSL -o bundletool.jar \
             https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
      - name: G1
        run: bash tool/assert_permissions.sh

      # Size analysis is a SEPARATE, single-ABI build, so it only runs on a tag.
      # The command prints the path of the JSON it wrote — collect it from the
      # output rather than assuming a location, because that path has moved before.
      - name: Size analysis
        run: |
          flutter build appbundle --release --analyze-size \
            --target-platform android-arm64 \
            --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
            --obfuscate --split-debug-info=build/symbols/android-size \
            | tee size.log
          SIZE_JSON=$(grep -o '[^ ]*code-size-analysis[^ ]*\.json' size.log | tail -1)
          [ -n "$SIZE_JSON" ] || { echo "::error::no size-analysis JSON was written"; exit 1; }
          mkdir -p build/size && cp "$SIZE_JSON" build/size/

      - uses: actions/upload-artifact@v7
        with:
          name: release-${{ github.ref_name }}-build-${{ github.run_number }}
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/app/outputs/logs/manifest-merger-release-report.txt
            build/symbols/android
            merged-manifest.xml
            build/size/
```

Upload to Play by hand. Manual upload of an AAB is ninety seconds and you *want* to look at the release notes and the staged-rollout percentage anyway.

### 4.5 `goldens.yml` — tag or manual, macOS only

```yaml
# .github/workflows/goldens.yml
name: Goldens
on:
  push:
    tags: ['v*']
  workflow_dispatch:

env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc — asserted below. Never 'stable'.

jobs:
  goldens:
    runs-on: macos-latest        # 10x multiplier. This is why it is not per-PR.
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # §1.1. This is the workflow where the pin matters MOST — a golden diff
      # caused by a Flutter version bump reads as a design regression, and the
      # developer spends an hour looking at the wrong thing.
      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get
      - run: flutter test -P ci-golden --reporter github
      - uses: actions/upload-artifact@v7
        if: failure()
        with: { name: golden-failures, path: test/**/failures/** }
```

Eight images, dark theme, pinned to one runner and one exact Flutter version (#116); [`12-testing.md`](12-testing.md) §8.2 owns the list and `ci-golden` is its `dart_test.yaml` preset. They change only on deliberate re-baseline commits, so per-PR macOS is pure cost. Re-baseline locally with `make goldens-update`, look at every changed pixel, commit.

### 4.6 What is deliberately not automated

| Not automated | Because |
|---|---|
| iOS build on push | §4.1. Ten to twenty builds a month, total. |
| iOS release upload | Signing-secret plumbing and `fastlane match` to save five minutes, once a month. |
| Store uploads, both platforms | Ninety seconds by hand, and you should read the rollout percentage. |
| Screenshot generation | `golden_screenshot` belongs in `tool/`, run when the store listing changes. |
| Coverage thresholds | Decision #119. A percentage gate creates pressure to test `copyWith` while the DST cases stay unwritten. |
| Frame times, startup latency, export duration | Decision #126. Profile mode is disabled on emulators, so any number a hosted runner produces is noise. §6.2. |
| Integration journeys on a device farm | Firebase Test Lab requires an account and an upload — the exact posture the product rejects (#117). |
| Dependabot on pub packages | A plugin bump can change the merged manifest or a privacy manifest. Monthly `flutter pub outdated`, read by a human. |

**Anti-patterns.** A CI step that *fixes* rather than *reports* — no auto-format commit, no auto-`dart fix`, no bot that regenerates code and pushes. That is spec §12.4's "never silently correct" applied to the pipeline: a stale artefact is a fact about the commit, and the commit is what has to change. A step that continues on error. A gate that is skipped on `main` "because it already passed on the PR". Making any gate `continue-on-error: true` — if it is not worth failing on, delete it.

---

## 5. Lints and the analyzer

### 5.1 The choice

**`flutter_lints` 6.0.0 plus an explicit `analyzer: language:` strict block** (decision #109). `flutter_lints` alone is not acceptable: it contributes exactly ten Flutter rules and **no analyzer language modes at all**. `very_good_analysis` 10.3.0 is the documented alternative — it turns on the same three modes plus ~215 rules — and it is rejected as the headline because for a solo developer the day-one diagnostic wall gets rules disabled one at a time until you have built a custom set anyway.

The load-bearing argument is **`strict-casts`**, and it is specific to this app: every row out of SQLite and every field out of a JSON backup is a `dynamic`-adjacent boundary. Without it, `final w = row['birth_weight'];` silently becomes whatever you assign it to and fails at runtime — in a barn, at 3am, on a record that is now lost. For an app whose safety rules include "never silently correct a user's entry", the type system doing its job at every data boundary is not a style preference.

### 5.2 `analysis_options.yaml`

```yaml
# analysis_options.yaml
#
# Base: flutter_lints 6.0.0 (decision #109). It sets NO analyzer language modes,
# which is why the block below is not optional and is restated here rather than
# inherited — it must survive a base-package bump and be visible in this repo.
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true        # the one that matters: every SQLite row, every JSON field
    strict-inference: true    # no silent dynamic when inference cannot decide
    strict-raw-types: true    # no bare List / Map / Future

  errors:
    todo: ignore
    # Promotions. A rule must be ENABLED — by flutter_lints' own closure or by the
    # `linter:` block below — before a promotion here does anything at all.
    # Enabled by flutter_lints:
    unrelated_type_equality_checks: error     # extension-type ids compared to raw ints
    collection_methods_unrelated_type: error
    use_build_context_synchronously: error    # every write path awaits, then shows a receipt
    # Enabled by the `linter:` block below, because flutter_lints does NOT set them:
    avoid_dynamic_calls: error
    close_sinks: error                        # the purchase stream subscription

  exclude:
    # Generated. Never hand-edited, never analysed, always regenerated by `make gen`.
    - '**/*.g.dart'
    - '**/*.drift.dart'
    - 'lib/core/db/schema_versions.dart'      # drift_dev schema steps
    - 'test/drift/generated/**'
    - 'build/**'
    # NOT '**/*.freezed.dart'. freezed is rejected on this stack (its analyzer
    # constraint conflicts with both drift_dev and build_runner). A line for a
    # package that cannot be installed is config that implies it might be.

  # NO `plugins:` section. custom_lint is archived upstream and unresolvable against
  # drift_dev's analyzer ^13.0.0; riverpod_lint is internally unresolvable. The
  # equivalent rules live in tool/check_policy.dart, which has zero dependencies.

linter:
  rules:
    # Every rule here is one flutter_lints does NOT enable. Nothing is repeated
    # from the base set — a repeated rule reads as a decision and is noise.
    - avoid_dynamic_calls      # promoted to error above
    - close_sinks              # promoted to error above; NOT in flutter_lints
    - unawaited_futures        # a dropped await is a lost write (spec §5)
    - only_throw_errors
    - always_use_package_imports
    - prefer_final_locals
    - use_super_parameters

formatter:
  page_width: 100
  trailing_commas: automate
```

Three notes on that file:

- **Enable, then promote.** `errors:` can raise a lint's severity only if the rule is enabled somewhere. Three of the five promotions ride on `flutter_lints`' own closure (`package:lints/recommended.yaml` plus its ten Flutter rules). **Two do not:** `avoid_dynamic_calls` and `close_sinks` are in no default set, so each appears twice — once in `linter: rules:` to turn it on, once in `errors:` to raise it. A promotion with no matching enable is silently dead configuration, and the analyzer does not warn about it.
- **`formatter.page_width`** is the documented way to set line length (default 80). Setting it here, rather than disabling `lines_longer_than_80_chars`, keeps the formatter and the linter from arguing.
- **The analyzer's `exclude` does not exclude anything from `dart format`.** If `dart format --set-exit-if-changed` fails on a generated file, that is a **toolchain-pin mismatch** — your Dart formatter and the version `build_runner` formatted with disagree — not a source defect. Fix the pin or regenerate. Never hand-format a generated file.

### 5.3 `--fatal-infos`

`flutter analyze` defaults `--fatal-infos` and `--fatal-warnings` to `true`. **Pass both explicitly anyway**, so the intent survives a tool change and so `make check` and CI cannot drift apart. With `strict-casts` on, the analyzer is this project's only reviewer.

**Anti-patterns.** `// ignore:` without a reason on the same line. A repo-wide `// ignore_for_file:`. Disabling a rule in `analysis_options.yaml` because one call site is awkward — the awkward call site is the finding. Adding an analyzer plugin: every one that could express this project's rules is discontinued, archived, or unresolvable against `drift_dev`'s `analyzer ^13.0.0`, which is exactly why `tool/check_policy.dart` exists.

---

## 6. Budgets

### 6.1 App size — the spec deviation, stated once

**Spec §11 says "Total app payload well under 20 MB, dominated by fonts and icons." That sentence is about bundled content and cannot be read as a promise about install size.** Decision #127 reframes it, and this is the one place the deviation is recorded:

| Promised | Figure | Enforced by |
|---|---|---|
| Bundled assets — fonts, `assets/content/`, icons | **< 5 MB** | Reviewed at each release; the variable font is 114 KB and there is no licensed data of any kind |
| No breed database, no medicine database, no regulatory forms | zero bytes | Spec §11; it is also why there is nothing to license |
| Android AAB **download** size, arm64 | **target < 20 MB** | Tracked, per release, §6.1.1 |
| iOS **install** size | **plausibly 25–45 MB. Not promised anywhere user-facing.** | Recorded, never advertised |

The binary is what Flutter costs. Saying otherwise in a store listing, a README or a forum post is a claim the project cannot keep.

#### 6.1.1 The one tracked number

**The arm64-v8a download size of the release AAB, in MB, as reported by the Play Console's App Bundle Explorer.** One number, one row per release, in `docs/perf/measurements.md`.

It can only be read *after* upload, which is why recording it is a step in the release checklist (§12) and not a CI step. The CI-side number — the total from `--analyze-size`'s JSON — is **not** the download size; it is a diffable proxy that tells you *what changed* between two releases. Archive the JSON as a release artefact and open two of them side by side in `dart devtools` → "Open app size tool" when a release grows.

> **A narrowing of decision #126, recorded once, here.** #126's headline is "CI gates app *size*, not app *speed*". This document keeps the second half exactly (§6.2, §4.6) and narrows the first: **CI measures and archives size on every tag and gates nothing on it.** Two reasons, both specific to this project. The number worth gating — arm64 download size — does not exist until after upload, so no CI job can read it. And the number CI *can* read, the `--analyze-size` total, has no baseline: no release has been built, so any threshold committed today is a guess that will be edited the first time it fires, which is the definition of a gate nobody trusts. **The rule that replaces it:** the first release writes row one of `docs/perf/measurements.md`; the release **after** that one adds a hard check to `release.yml` comparing the `--analyze-size` total against the previous tag's archived JSON and failing on a growth of more than 5% without a matching line in `RELEASES.md`. Until then the gate is §12 checklist item 7, and it has a name against it.

```bash
# Locally, before a tag, if you want the number early:
flutter build appbundle --release --analyze-size --target-platform android-arm64 \
  --obfuscate --split-debug-info=build/symbols/android
# iOS: build the archive, then Xcode Organizer → the App Thinning Size Report.
```

Levers, in the order they matter: ship an AAB not a fat APK; `--obfuscate --split-debug-info`; one variable font rather than a nine-weight family; no `printing`, no `google_fonts`, no ML Kit (which alone would have been ~38 MB per script on iOS and would have tripped G1 besides). R8 is always on in release builds — the `--[no-]shrink` flag has no effect. Flutter 3.44 changed a default here: symbols are no longer stripped from `libapp.so` on Android by default, so **measure both ways once** and record which you ship.

> **No baseline exists yet.** No release has been built, so every figure above is a target, not a measurement. The first row of `docs/perf/measurements.md` is written by the first release, not by this document.

### 6.2 Startup

**The budget:** an interactive keypad **at the first frame**, and the first Flutter frame **≤ 400 ms after `main()`** on the oldest target device. The 400 ms figure is Apple's published launch-time goal; Android vitals treats a cold start as *excessive* at ≥ 5 s, which is the "your app is bad" line and not a target.

The second half of the budget is the one that matters. The spec's 15-second median (§15) is dominated by the human, not the machine: even a 1.6 s launch spends 11% of it. What kills you is a spinner between the tap and the first digit. That is why `main()` awaits nothing and the first frame is a static dark Quick Entry shell with a fully interactive keypad and no data ([`01-architecture.md`](01-architecture.md) §6).

Working targets, to be replaced by measurements:

| Device class | Tap → first Flutter frame | Tap → keypad accepts a digit |
|---|---|---|
| iPhone SE (2020) / iPhone 11, iOS 26 | ≤ 700 ms | same frame |
| Mid-range Android, API 33–36, 4 GB (Pixel 6a class) | ≤ 900 ms | same frame |
| Low-end Android, API 29–30, 3 GB, no Vulkan | ≤ 1600 ms | same frame |

**How it is measured.** Two physical devices — the oldest supported iPhone and the low-end Android — in **profile mode**, once per release. Debug mode is not representative and profile mode is *disabled on emulators and simulators*, so a number from a hosted runner, a simulator or a debug build is not evidence. This single fact is why CI gates size and not speed.

```bash
flutter run --profile --trace-startup -d <device>
# → build/start_up_info.json:
#   engineEnterTimestampMicros · timeToFrameworkInitMicros · timeToFirstFrameMicros
#   timeToFirstFrameRasterizedMicros · timeAfterFrameworkInitMicros

# Android cross-check — includes the OS-side cost --trace-startup cannot see.
# APP_ID is the application id fixed in §3.1; no document in this set has chosen
# the string yet, so it is not written literally anywhere.
APP_ID=$(grep -o 'applicationId *= *"[^"]*"' android/app/build.gradle.kts | sed 's/.*"\(.*\)"/\1/')
adb shell am force-stop "$APP_ID"
adb shell am start -S -W -c android.intent.category.LAUNCHER \
  -a android.intent.action.MAIN "$APP_ID/.MainActivity"
adb logcat -d | grep "Displayed"
```

Also measured, because they are the two things that can quietly regress: **DB open + migration duration** (wrap it in a `dev.TimelineTask()` and read it in DevTools ▸ Performance ▸ Timeline Events) and **export duration** for a 400-ewe flock book, on the slow Android, with the battery under 20% so thermal throttling is in play.

### 6.3 `docs/perf/measurements.md`

The file is a table, appended to, never rewritten. It is the only performance record the project has, because there is no telemetry.

```markdown
# Measurements

Every row is from a physical device in profile or release mode.
A number from a simulator, an emulator or a debug build does not go in this file.

| Release | Build | Device | OS | Tap→first frame | DB open+migrate | Flock book PDF | AAB arm64 download | iOS install |
|---|---|---|---|---|---|---|---|---|
| (first release) | | | | | | | | |

## Method
- Startup: `flutter run --profile --trace-startup`, median of 5 cold starts, force-stopped between.
- DB open: `dev.TimelineTask('db.open')`, 400-ewe seeded database (`tool/seed.dart`).
- PDF: wall clock, 400 ewes, 3 seasons, battery < 20%.
- AAB: Play Console → App Bundle Explorer → arm64-v8a download size.
- iOS: Xcode Organizer → App Thinning Size Report.
```

---

## 7. The clean-pause mechanism

R11 assigns these two names to this document, and here they are.

### 7.1 What they are for

`FlutterError.onError` and `PlatformDispatcher.instance.onError` see **Dart** errors. They do not see an engine or native crash, an Android low-memory kill, an iOS jetsam kill, `0xdead10cc`, or the battery dying at 04:10. **Those are precisely the failures that matter for a 3am shed app**, and there is no reporter to catch them because there is no network.

So they are detected by inference: a marker file that exists while a session is live and is cleared when the app pauses cleanly. Present at the next launch ⇒ the previous session died without reaching a clean pause.

### 7.2 `session.lock`

```
<appSupport>/diagnostics/
  session.lock      ← this file
  shedbook.log      ← current, capped at 256 KB
  shedbook.1.log    ← one rotation
```

Contents — JSON, one object, every field on decision #124's **allowed** list and nothing else:

```json
{
  "startedAt": "2026-03-11T02:41:07.412Z",
  "appVersion": "1.2.0",
  "build": 187,
  "lastEvent": "nav.lambing_entry",
  "freeBytes": 4831838208,
  "clean": false
}
```

`lastEvent` is the last structured event string passed to `LocalLog.record()` — `nav.<route_name>`, `restore.begin`, `migration.v1_to_v2`, `reminders.reconciled`. It is a route or an operation name, never a row, a tag, a note or a path. `startedAt` is `appNow().utc.toIso8601String()`; **`DateTime.now(` is banned outside `lib/core/time/app_clock.dart` and that ban applies to the log too** — three research notes wrote `DateTime.now()` in this exact snippet and all three are wrong. `appVersion` and `build` are `kAppVersion` and `kAppBuild`, compiled in at build time (§9.1.1); there is no package in the graph that can supply them.

### 7.3 `markCleanPause()`

```dart
// lib/core/log/local_log.dart — LocalLog's fifth method (R52). No other file
// touches session.lock.
//
// Called from exactly one place: the AppLifecycleState.hidden arm of
// _ShedBookAppState.didChangeAppLifecycleState (02-state-di-navigation.md §9.1).
// `hidden` is synthesised on both platforms and is the last state you are
// guaranteed to observe, which is what makes it the only safe call site.
void markCleanPause() {
  if (_dir == null) return;               // attachTo() has not run yet; nothing to mark
  try {
    _session = _session.copyWith(clean: true, freeBytes: _freeBytesOrNull());
    _lockFile.writeAsStringSync(jsonEncode(_session), flush: true);
    _clean = true;                        // the in-memory latch §7.4 re-arms from
    record('session.pause');
  } catch (_) {
    // Diagnostics must never be the cause of a crash. Swallow, always.
  }
}
```

It rewrites the file rather than deleting it, because the *contents* are what makes an abnormal termination report useful — free bytes and the last event at the moment of the pause are exactly the two numbers that explain most reports.

### 7.4 Re-arming, and the blind spot

After a clean pause the app may be resumed and then killed. The lock must therefore go back to `clean: false`.

**The re-arm point is the first `write` / `record` / `flutterError` call after a pause**, guarded by an in-memory boolean so it costs one synchronous write per resume and not one per log line. There is no second lifecycle call site, because `02-state-di-navigation.md` fixes the clean-pause marker to that one switch and adding a call there is not this document's to do.

**State the consequence plainly: a process killed after resume but before any event is recorded is reported as a clean pause.** In practice the window is milliseconds — the resume arm invalidates the ticker and kicks `reconcile()`, and any navigation records an event — but it is a real blind spot and it is documented rather than papered over.

### 7.5 Detecting and reporting a dirty resume

Detection happens inside `LocalLog.attachTo(directory)`, on the post-frame boot path, because that is the first moment the diagnostics directory is known:

```dart
Future<void> attachTo(Directory dir) async {
  _dir = dir;
  // First run: the folder does not exist yet, and _armSession() below writes
  // into it. Creating it here rather than lazily keeps every other method's
  // failure mode "the write threw and was swallowed" rather than "the write
  // threw because of us".
  Directory('${dir.path}/diagnostics').createSync(recursive: true);
  final lock = File('${dir.path}/diagnostics/session.lock');
  if (lock.existsSync()) {
    try {
      final prior = jsonDecode(lock.readAsStringSync()) as Map<String, dynamic>;
      if (prior['clean'] != true) {
        // Reported, never acted on. Nothing is repaired, nothing is deleted,
        // nothing is transmitted. It is a line in a log the user can read.
        record('session.abnormal_termination ${jsonEncode(prior)}');
      }
    } catch (_) {/* an unreadable lock is not worth a crash */}
  }
  _armSession();          // writes a fresh session.lock with clean:false
  _flushBufferedRecords(); // everything logged before the directory resolved
}
```

Where it surfaces: **Settings ▸ Diagnostics**, in the last-20-events list, as one line — *"11 Mar 2026 02:41 — previous session ended unexpectedly on Lambing Entry"*. Dates a human reads are `d MMM y`; times are 24-hour `HH:mm` (CONVENTIONS §5.4, R60).

> **Provenance, and why the Diagnostics screen is not an exception to it.** CONVENTIONS §5.4 requires every displayed *event* time to carry a provenance label, and a bare `03:21` on a shed screen is a review failure. Every timestamp in the diagnostics log and on this screen is machine-captured by `appNow()` at the moment of the event and can be nothing else: there is no entry path, no edit path and no `RecordedTime` here, because none of these rows is a record of something a shepherd did. **State that once, at the top of the Diagnostics screen** — *"Times below are recorded by the app, not entered by you"* — and the rule is honoured rather than quietly sidestepped. A diagnostics line must never render a `RecordedTime` from a real record, which would put an unlabelled effective time on screen.

**Anti-patterns.** Prompting the user about it. Counting them. Making the app behave differently because the last session died — spec §12.4 is "flag it, do not fix it", and a self-repairing app is an app that hides the bug. Putting `session.lock` in the cache directory: Android deletes cache under storage pressure, which would silently convert every crash into a clean pause.

---

## 8. Crash diagnostics without a network

### 8.1 Why there is no crash reporter at all

Sentry and Crashlytics both require `android.permission.INTERNET`, transmit device and error data to a third party, add SDK weight and startup work, and — for Crashlytics — drag in Firebase and a Google services plugin. Spec §4.3 ("no server means no outage"), §4.5 ("the data is nobody else's business") and §13 ("no sync, no cloud backup of any kind") each rule them out independently.

**There is no "just crash reports, no PII" configuration that satisfies §4.5, because the transmission itself is the violation.** The fact that a specific device crashed at 03:41 is telemetry the user did not consent to. And mechanically: adding either one fails gate G1 on the next push, which is the correct outcome — the product's central claim is enforced by the pipeline, not by discipline.

The accepted consequence, stated so nobody is surprised in season two: **you will never know why a shepherd stopped using the app.** The compensating mechanisms are the diagnostics export below, the twelve-tester beta cohort, and direct contact with the forums in spec §3.

### 8.2 The two handlers, installed before anything else

Both live in `main()`, synchronously, before `runApp()` — the full file is in [`01-architecture.md`](01-architecture.md) §6.1 and is not reprinted here. What matters for this document:

1. **`FlutterError.onError`** — framework errors (build, layout, paint). `presentError` is kept so debug console behaviour is unchanged. Exceptions thrown by the handler itself are **not** caught, so the body is wrapped in a bare `catch (_)`.
2. **`PlatformDispatcher.instance.onError`** — errors outside the Flutter call stack: async gaps, platform channels. Returns `true`, meaning handled; returning `false` forwards to a platform fallback that on some platforms terminates the process, and at 3am the committed data matters more than the process.

Plus `ErrorWidget.builder`, because the default is a red-on-yellow block, which under a head torch is both blinding and terrifying.

**No `runZonedGuarded`.** `PlatformDispatcher.instance.onError` covers the same root-isolate ground, Flutter's own error-handling page demonstrates the complete setup without it, and a zone/binding mismatch is a documented footgun (flutter#94123). The genuine gap is child isolates, which `onError` never sees — but `Isolate.run` and `compute` rethrow into the caller, so an `await` inside a `try`/`catch` surfaces them normally, and this app never uses raw `Isolate.spawn`.

**No `exit(1)` in release.** Log it, show the panel.

### 8.3 The local rolling redacted log

A **rolling, redacted, plain-text** file in application support — **never** the cache directory.

| Property | Value | Why |
|---|---|---|
| Location | `<appSupport>/diagnostics/shedbook.log` | Cache is deleted under storage pressure |
| Cap | **256 KB**, one rotation to `shedbook.1.log` | The log must never contribute to a disk-full failure |
| Crash-path writes | `writeAsStringSync(mode: FileMode.append, flush: true)` | An `IOSink` write is buffered and may never reach disk before the process dies. Synchronous + flush costs a few ms on a path that is already failing. |
| Before `attachTo` | Bounded in-memory ring buffer, drained on attach | The handlers are installed in `main()`; the directory is not known until `path_provider` resolves after the first frame |
| On any failure inside the log | Swallowed | Diagnostics must never be the cause of a crash |

`package:logging` provides named loggers and a `LogRecord` stream for the ordinary path; **the crash path bypasses the stream entirely.**

One record looks like this — and every field is on the allowed list:

```
--- 2026-03-11T02:41:09.118Z [flutter]
build: 1.2.0+187
device: iPhone12,1 / iOS 26.2
free: 4831838208
event: nav.lambing_entry
error: StateError
#0      LambingEntryController.build (package:shed_book/features/lambing/…:88)
…
```

### 8.4 Redaction is mandatory, and it is a list

Decision #124. This is spec §4.5 made mechanical.

| Allowed | Forbidden |
|---|---|
| Timestamp (UTC ISO-8601) | Ewe tags |
| App version + build number (`kAppVersion` / `kAppBuild`, §9.1.1) | Note text, of any kind |
| OS version, device model (`device_info_plus`) | Treatment product names, batch numbers |
| Free bytes, DB size, media size, WAL size | **Withdrawal periods** — a safety-critical number that is nobody else's business |
| Route/operation name (`nav.pen_board`, `restore.begin`) | Media paths, file names, anything containing a sandbox UUID |
| Exception **type** | Exception **message** |
| Stack trace, with sandbox UUIDs rewritten out | Row contents, query parameters, bound values |
| SQLite `resultCode` / `extendedResultCode` + a statement identifier you control | `SqliteException.toString()` |

The SQLite rule is the one that bites: **`SqliteException` messages echo SQL and sometimes bound values.** Log `e.resultCode`, `e.extendedResultCode` and an identifier you assigned to the statement. Never `e.toString()`. `ShedFailure`'s `DatabaseUnreadable(resultCode, extendedResultCode)` variant exists precisely so the two integers travel without the message.

Do **not** request the iOS 16+ device-name entitlement — a device name is user-identifying.

`Redact` truncates any exception message to a small allowlist of known-safe prefixes and otherwise emits only `error.runtimeType`; and it rewrites file paths in stack traces to strip the container UUID, which on iOS changes on every install anyway.

**Obfuscation and symbols.** Release builds ship `--obfuscate`, so a stack trace in a user's log is unreadable until you symbolize it against the symbols for **that exact build number**:

```bash
# `build/symbols/` is where the build wrote them; the archive path below is where
# you kept them, one directory per <name>+<build>. §9.4 is the archive; this is
# the read. The two must agree or the archive is a folder of useless files.
flutter symbolize -i crash.txt -d symbols-archive/1.2.0+187/ios/app.ios-arm64.symbols
```

That is why §9.4 makes the symbol directory a per-build artefact you must keep. Without it, the one diagnostic channel this app has produces noise.

### 8.5 Settings ▸ Diagnostics

A sub-screen of Settings (screen 12), **not** a thirteenth route — `RouteNames` has thirteen entries and none of them is `diagnostics`.

| Row | Contents |
|---|---|
| Records | ewes / lambings / lambs / treatments counts — reassures the user their data is there |
| Storage | database size, media size, free space on device |
| Last 20 events | timestamped, redacted, scrollable; the abnormal-termination line from §7.5 appears here |
| Check database | `PRAGMA quick_check`, behind a button. Never `integrity_check`, never on the launch path |
| Save a copy of the file | `VACUUM INTO` a snapshot, then the share sheet ([`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §8) |
| Export diagnostics | Share sheet, sending `shedbook.log` + `shedbook.1.log` |
| Typical time to record an event | Optional, local, opt-in: the rolling median of a locally computed `entry_latency_ms`. It is spec §15's own success metric made visible without transmitting anything. Success criteria 1 and 4 are cross-user retention facts and are **not instrumentable** — decision-record §4 declares them qualitative and binds them to the beta cohort instead. |

The copy above the share button, in this tone, because it is what makes voluntary reporting actually happen:

> *"This file contains no animal records — only app version, device model and error messages. You can open it and read it before you send it."*

That sentence is only true because §8.4's list is enforced. A test in `test/policy/` asserts the log never contains a value drawn from the forbidden column.

### 8.6 Nothing is ever transmitted

The rule, stated once: **the app never sends anything anywhere. The only egress is the system share sheet, on an explicit user tap, with the user choosing the destination.**

- No automatic prompt to send. Spec §5: "zero interruptions."
- No "would you like to report this?" dialog after a crash.
- No upload on Wi-Fi, no deferred queue, no "anonymous usage statistics" toggle — an off-by-default toggle is still a transmission path, and G1 would fail the moment one was wired up.
- The share sheet is a *different process* with its own network access. That is tier 3 of the offline contract and it is explicitly **not** claimed (§2.1).

---

## 9. Versioning and signing

### 9.1 Version and build number

`pubspec.yaml`'s `version: <build-name>+<build-number>` maps to:

| | Android | iOS |
|---|---|---|
| build-name (`1.2.0`) | `versionName` | `CFBundleShortVersionString` |
| build-number (`+187`) | `versionCode` | `CFBundleVersion` |

The strategy, and it removes an entire category of release-day friction:

1. **`pubspec.yaml`'s `version:` is a local default, not the shipped value.** It is what a `flutter run` on your desk reports and nothing more. It carries no authority over a store artefact, because every shipped build overrides both halves on the command line.
2. **The build number is always the release workflow's run number**, passed at build time: `--build-number=${{ github.run_number }}`. Both stores reject a re-used build number, and a monotonically increasing integer you never have to think about is worth more than a meaningful one.
3. **The build name comes from the tag, always.** `git tag v1.2.0` triggers `release.yml`, which derives `--build-name=1.2.0`. Bump `pubspec.yaml`'s `version:` to `1.2.0+1` **in the commit you tag**, so a `flutter run` on the desk does not report a stale version — but understand that this is hygiene, not the mechanism. If the tag and `pubspec.yaml` ever disagree, **the tag wins and the artefact is correct**; fix the pubspec, do not re-tag.
4. **Only the `release` workflow's artefact is ever uploaded to a store.** This matters: each workflow has its own `run_number` counter, so a per-push AAB and a release AAB can carry the same or a descending number. The per-push AAB exists to run G1 and is never shipped.
5. The manual iOS build uses **the same number** the release workflow produced for that tag. `RELEASES.md` records it:

```markdown
# Releases — Shed Book
Application id / bundle id: <fixed once, before the first upload; §3.1>

| Tag | Build number | Android uploaded | iOS uploaded | AAB arm64 download | Notes |
|---|---|---|---|---|---|
| v1.0.0 | 187 | 2026-06-04 | 2026-06-05 | | first release |
```

```bash
# The manual iOS release, on your Mac.
flutter build ipa --release \
  --build-name=1.2.0 --build-number=187 \
  --dart-define=APP_VERSION=1.2.0 --dart-define=APP_BUILD=187 \
  --obfuscate --split-debug-info=build/symbols/ios
# Then Transporter, or:
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

**Anti-patterns.** Hand-editing a build number. Reusing one after a failed upload — both stores reject it, and the two minutes you spend understanding why are two minutes at the worst moment. Treating `pubspec.yaml`'s `version:` as the shipped name. Re-tagging to fix a pubspec typo.

#### 9.1.1 How the running app knows its own version

`session.lock` (§7.2), every diagnostics log record (§8.3) and the symbolization path (§8.4) all need the exact `<name>+<build>` of the running binary. **There is no package that supplies it.** `package_info_plus` is in the graph only transitively, via `wakelock_plus`, and reading a transitive package from `lib/` would be exactly the unreviewed edge gate G2 exists to prevent — adding it as a direct dependency to solve this would be trading a real offline-graph review for a convenience.

**The rule: the version is compiled in at build time, from the same two shell variables the release workflow already computes.**

```dart
// lib/core/log/local_log.dart — const, so it is tree-shaken into a literal.
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');
const kAppBuild   = int.fromEnvironment('APP_BUILD', defaultValue: 0);
```

```bash
flutter build appbundle --release \
  --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
  --dart-define=APP_VERSION="$BUILD_NAME" --dart-define=APP_BUILD="$BUILD_NUMBER" \
  --obfuscate --split-debug-info=build/symbols/android
```

Both `--dart-define`s go on **every** build command in §4.3, §4.4 and the manual iOS build, next to the `--build-name` / `--build-number` they mirror. The defaults are deliberately wrong-looking: a diagnostics log that says `0.0.0+0` tells you instantly that somebody built without the defines, which is better than a log that quietly reports a plausible lie. A `test/policy/` test asserts the two defines and the two build flags are set from the same variables in every workflow file.

### 9.2 Android signing

Generate an upload keystore, keep `android/key.properties` out of git, load it in `build.gradle.kts`:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
android {
    signingConfigs {
        create("release") {
            keyAlias      = keystoreProperties["keyAlias"] as String
            keyPassword   = keystoreProperties["keyPassword"] as String
            storeFile     = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
}
```

In CI the keystore arrives base64-encoded from a repository secret and is written out at build time (§4.4). Play App Signing means Google holds the *app signing* key, so a lost **upload** key is recoverable through support — but that is a support ticket you do not want during lambing.

### 9.3 iOS signing

For v1: let Xcode manage signing with automatic provisioning and build releases locally on the Mac you already own. `fastlane match` and App Store Connect API keys in CI buy nothing until the release cadence justifies them, and they cost the macOS budget (§4.1).

### 9.4 The artefacts a solo developer must keep

There is no team, no shared drive and no build server with history. If you lose one of these, the corresponding recovery does not exist.

| Artefact | Where | If you lose it |
|---|---|---|
| **Upload keystore** + its three passwords | Two places, neither of them the laptop; one offline | Recoverable via Play support. Slow, and never at a good time. |
| `android/key.properties` | Local only, git-ignored | Regenerate from the keystore + passwords |
| GitHub secrets: `SHEDBOOK_KEYSTORE_BASE64`, `_PASSWORD`, `_KEY_ALIAS`, `_KEY_PASSWORD` | Repository settings | Re-derive from the keystore |
| **Obfuscation symbols, per build number** — the build writes `build/symbols/{android,ios}`; you keep `symbols-archive/<name>+<build>/{android,ios}/` | Kept forever, off the laptop. Not in git — they are binary and they never change | Every stack trace in every user-sent diagnostics log for that build is permanently unreadable (§8.4). This is the only artefact whose loss cannot be recovered by rebuilding |
| The release `.aab` | Release artefact | Rebuild from the tag — but only if the toolchain still resolves |
| `--analyze-size` JSON | Release artefact | Lose the ability to diff what a release cost |
| `merged-manifest.xml` + `manifest-merger-release-report.txt` | Release artefact (G1, G4) | Lose the evidence for the permission claim on a shipped build |
| `pubspec.lock` | **Committed** | Lose decision #5's evidence and the reproducibility of the build |
| `drift_schemas/*.json` | **Committed** | Every migration test loses its baseline; this is unrecoverable |
| Apple distribution certificate + provisioning profiles | Keychain + an export | Regenerate; existing TestFlight builds are unaffected |
| The `.storekit` configuration file | Committed under `ios/` | Re-author it |

---

## 10. Test tracks

### 10.1 TestFlight

Internal testing — up to 100 members of your own team, **no App Review** — is instant and is the right loop for a solo developer. External testing — up to 10,000 testers, requires a TestFlight review — is how real shepherds get on it. Upload with Transporter or `xcrun altool` (§9.1).

### 10.2 Play's 12-tester / 14-day closed test — put it on the critical path now

**A personal Google Play developer account created after 13 November 2023 must run a closed test with at least 12 opted-in testers for 14 continuous days before it can apply for production access.** (Reduced from 20 testers on 11 December 2024. Organisation accounts and older personal accounts are exempt.)

> **Open, and it blocks a launch date.** Decision-record §7.1 item 14: *does the developer account already exist, and is it a personal account created after 13 Nov 2023?* Nobody has answered this. **If the answer is yes, this is on the critical path and must be scheduled now, not at the end.** Twelve real testers for fourteen continuous days is 2–3 weeks of calendar time *after* you have recruited twelve people — and recruiting a dozen shepherds from The Farming Forum or Accidental Smallholder (spec §3) is itself weeks of work.

The recruitment doubles as the answer to the highest-value open question in the whole project (§7.1 item 1: *does a night in a real lambing shed happen before the Quick Entry screen is written?*). Start the closed test **during** the build, not after it. A launch delayed by fourteen days because nobody read this paragraph is the most avoidable schedule failure available to this project.

Second constraint on the same calendar: those fourteen days must not land inside the seasonal freeze (§11) if the plan is to ship immediately afterwards.

### 10.3 Testing purchases — where it lives

**[`11-monetization-and-store.md`](11-monetization-and-store.md) §11 owns this and is the copy to work from.** It is named here, not restated, because a second list of purchase-test cases is a second list that goes stale. What belongs to *this* document is only the scheduling consequence:

- The **iOS `.storekit` configuration file** loop works fully offline and needs no Apple account, so it is the only purchase test that can be run before the developer account question (§7.1 item 14) is answered. Run it first; it is not blocked on anything.
- **Sandbox, TestFlight and Play License testing all require the store accounts to exist.** They sit behind the same dependency as §10.2's closed test, which is why §10.2 is on the critical path and this paragraph is a pointer rather than a plan.
- The four offline paths in 11 §11 — Unlock in airplane mode, Restore in airplane mode, buy-on-A-install-on-B, and pay-then-lose-the-network inside Google's three-day acknowledgement window — are **release-checklist items** (§12 item 3), not CI. Nothing in this pipeline can test a purchase.

---

## 11. The seasonal release freeze

**You do not ship an update during your customers' lambing season.** A regression shipped on 3 March costs someone a night of records that cannot be reconstructed, in an app whose only backup is one the user remembered to make. There is no server-side rollback, no feature flag, no remote kill switch — by design. An update is irreversible on someone else's phone the moment they take it.

**The window, for UK/Ireland (the owner's region ruling):**

| Dates | Status | What may ship |
|---|---|---|
| 1 Feb – 30 Apr | **FROZEN** | Only a data-loss-class hotfix (§11.1) |
| 1 – 31 May | Elevated scrutiny | Hill flocks are still lambing. Staged rollout only, 10% for 72 h |
| 1 Jun – 31 Jan | Open | Normal releases; this is where feature work lands |

The freeze is a line in this checklist **and the first step of `release.yml`'s `aab` job** (§4.4), not in someone's head. Add it to the calendar in September, when it is easy.

That step **warns and never blocks**, because the one release that must be able to run during the freeze is the hotfix the freeze exists to make rare. A warning annotation stays on the run's summary page for the rest of the release's life, which is the point: the person who cannot remember why they shipped on 3 March can go and read it.

### 11.1 What clears the freeze

Exactly one class of change: **a defect that destroys or corrupts records, or prevents the app opening at all.** Not a crash on a secondary screen, not a wrong statistic, not a layout bug, not a missing translation. If the answer to *"does this bug lose data or lock someone out?"* is no, it waits for the freeze to lift on **1 May** — and then ships under May's rule, which is staged rollout at 10% for 72 hours, not a normal release. Hill flocks are still lambing in May; the freeze lifting is not the season ending.

A freeze-clearing release still gets the full checklist in §12, plus: staged rollout at 10% for 24 hours before going wider on Play, and phased release on iOS.

### 11.2 Release-checklist items the calendar owns

- **Refresh the bundled IANA timezone data** once a year, outside the freeze, by bumping `timezone` and re-running the DST suites. The bundled snapshot ages; that is accepted (decision-record §4) precisely because `package:timezone` is confined to the notification seam and everything else uses the OS zone.
- **Notification channel ids are frozen at release**, and there are **eight**, byte-identical to `reminders.kind`'s CHECK (CONVENTIONS **R49**, [`08-platform-integration.md`](08-platform-integration.md) §2.7): `colostrum`, `navel`, `turn_out`, `tag_by`, `ring_dock_castrate`, `second_dose`, `withdrawal_end`, `custom`. Decision #65's wording (`turnout`, `dose`, `withdrawal`) is **superseded** — those three match no kind and are banned channel ids. Changing one after release silently orphans every scheduled reminder on every installed device, so this has to be right *before* the first release, not before the first snapshot. 08 §2.7's gate asserts the two lists against the committed schema JSON.
- **Play Billing 9 is mandatory by 31 August 2027.** Put a reminder in Q1 2027. `in_app_purchase_android` currently ships Billing 8.0.0, which satisfies the 31 August 2026 deadline.
- **Target API 36 by 31 August 2026** (extensions to 1 November 2026).
- **Xcode 26+ / iOS 26 SDK** has been required for uploads since 28 April 2026.

---

## 12. The manual pre-release checklist

CI proves the mechanical things. These are the ones a pipeline structurally cannot see, and every one of them has bitten somebody.

1. **Read the permission list yourself.** `bundletool dump manifest` on the artefact you are about to upload. Do not just trust that G1 was green — read the seven `uses-permission` lines, and confirm `INTERNET` is not the eighth.
2. **Xcode → Archive → Generate Privacy Report.** Read the aggregate, not just your own manifest. Re-do this after any plugin bump and after the SwiftPM migration.
3. **Airplane-mode pass on a real device.** Cold launch → save a lambing event → export a CSV → open Unlock → tap Restore. All five must behave, and the four purchase paths in [`11-monetization-and-store.md`](11-monetization-and-store.md) §11 are run here, not in CI.
4. **Dark-launch check.** No white flash: the iOS `LaunchScreen` background and the Android `windowBackground` are the app's base surface `#0B0D0E`, and the Android 12+ splash exit fade is disabled. This is a *release configuration* bug, not a Dart bug, so no test in the suite will ever catch it.
5. **The four integration journeys**, on a plugged-in phone (`make integration`). Reported, not blocking — but read the report.
6. **Goldens re-baselined (`make goldens-update`) and every changed pixel looked at**, if any changed. A golden that changed and nobody can say why is a red build, not a re-baseline.
7. **`docs/perf/measurements.md`** has a row for this release: startup on two devices, DB open, PDF duration. Fill the AAB download column in *after* upload.
8. **Season freeze:** is it between 1 February and 30 April? If so, does this release clear §11.1's bar? If you have to argue for it, the answer is no.
9. **Release notes and store listing read for §12.2 compliance.** No dose, no diagnosis, no "you should". No "your data never leaves your phone". `tool/check_policy.dart` cannot see store metadata — you are the gate.
10. **"Did anything gain a network path this release?"** If a dependency was added or bumped, re-read its transitive graph and its merged manifest. If yes, the Apple privacy label and the Play Data safety form are versioned artefacts that must be updated **before** this build ships.
11. **`RELEASES.md` updated** with tag, build number and upload dates; **symbols archived** under that build number.

---

## Definition of done

**Toolchain and pinning**
- [ ] `.fvmrc` and **all three** workflow `FLUTTER_VERSION` blocks say `3.44.8`, and **every** workflow that installs Flutter runs §1.1's three-line assert — `goldens.yml` included. Proven by editing one `env:` to `3.44.7` and watching that workflow, and only that one, go red.
- [ ] `pubspec.lock` is committed and `flutter pub get` was actually run against decision-record §5's table on 3.44.8.
- [ ] `build_runner` is constrained `">=2.15.0 <2.15.2"`; `package:test` appears in no `dev_dependencies`; `flutter_riverpod` is `2.6.1` exactly, not `^2.6.1`.
- [ ] `Makefile` has `gen`, `check`, `test`, `goldens`, `goldens-update`, `perf`, `integration`; `test` and `goldens` are byte-compatible with `12-testing.md` §11.4 and use the `ci-fast` / `ci-golden` presets.
- [ ] The README records **which** command first trips `package:sqlite3`'s build-hook download on a cold cache, established by one plane-mode run, not guessed.
- [ ] The application id / bundle id is fixed in `android/app/build.gradle.kts` and the Xcode target, recorded in `RELEASES.md`'s header, and appears as a literal in no document.

**Offline gates**
- [ ] **G0 has been run against a real release AAB** and §2.2's table is filled in, including the `ACCESS_NETWORK_STATE` answer and confirmation that debug builds keep `INTERNET`.
- [ ] `android/expected_permissions.txt` exists, is sorted, holds **seven** uncommented lines, and every line names its contributing library.
- [ ] G1 asserts **set equality** and fails on an added permission, not just on `INTERNET`. Proven by temporarily adding a permission and watching it go red.
- [ ] G2 checks `direct main`, `direct dev` and `transitive` against three separate allowlist sections; `http` and `sqlite3_flutter_libs` are in `[transitive]` with their reasons.
- [ ] No gate anywhere asserts "no `http` in `pubspec.lock`" — that gate is unsatisfiable and must not exist.
- [ ] G3 carries **all thirteen** `rp3.*` rows from `02-state-di-navigation.md` §2.4 (decision #18). Counted against 02's table, not against §2.5's prose.
- [ ] G4's merger report is uploaded on every Android build.
- [ ] G5's ATS check runs in CI; the manual iOS checks are on the §12 checklist.
- [ ] Nothing greps `build/app/intermediates/`.
- [ ] `PrivacyInfo.xcprivacy` declares `C617.1` and `E174.1` and **not** `CA92.1`, per `11-monetization-and-store.md` §9.2. If the file declares `CA92.1`, it was copied from decision #93's superseded wording.

**CI**
- [ ] `gate` runs `check_policy` before `format` before `analyze` — cheapest failure first.
- [ ] Codegen freshness runs `build_runner` **and** `make-migrations` and diffs `lib/`, `drift_schemas/` and `test/drift/generated/`.
- [ ] The `test` job installs `libsqlite3-dev` before `flutter pub get`. Without it the job is red on day one and the message names no cause.
- [ ] Tests run `-P ci-fast` with `--test-randomize-ordering-seed random`. No `--exclude-tags golden` on the command line — the preset owns that, and two places to change it is one too many.
- [ ] The `TZ=Europe/London --tags uk-zone` run is **unscoped** (not `test/domain`), so §2.4 of 12's two uk-zone files outside `test/domain/` actually run in the target zone.
- [ ] The `TZ=Pacific/Chatham` run carries `--exclude-tags uk-zone`. Without it the zone-pinned files fail loudly, correctly, and pointlessly.
- [ ] Coverage is uploaded and gates nothing. `*.freezed.dart` appears in no strip list and no analyzer exclude.
- [ ] macOS appears in exactly one workflow, triggered by tag or manual dispatch.
- [ ] No job is `continue-on-error`. No job rewrites source.
- [ ] `.github/dependabot.yml` declares `github-actions` and nothing else.

**Lints**
- [ ] `analysis_options.yaml` includes `flutter_lints` **and** carries the explicit `strict-casts` / `strict-inference` / `strict-raw-types` block.
- [ ] Every rule promoted under `errors:` is enabled — by `flutter_lints`' closure or by the `linter:` block. `avoid_dynamic_calls` and `close_sinks` appear in both places; a promotion with no enable is dead config the analyzer will not warn about.
- [ ] There is no `plugins:` section.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` passes with zero `// ignore_for_file:` lines in `lib/`.

**Budgets**
- [ ] `docs/perf/measurements.md` exists with the method section, and the first release fills a row.
- [ ] The size deviation from spec §11 is stated in exactly one place (§6.1) and nothing user-facing promises an install size.
- [ ] The tracked number is the arm64 **download** size from Play Console, and the `--analyze-size` JSON is archived per release as the diff tool.
- [ ] The narrowing of decision #126 is stated in §6.1.1, and the release **after** the first adds the 5%-growth check against the previous tag's archived JSON.
- [ ] No CI job asserts a frame time or a startup latency.

**Diagnostics**
- [ ] `markCleanPause()` and `session.lock` exist under exactly those names, in `lib/core/log/local_log.dart` and `<appSupport>/diagnostics/` respectively.
- [ ] `markCleanPause()` is called from exactly one place: the `hidden` arm of the lifecycle switch.
- [ ] The re-arm point and its blind spot are documented in the code, not just here.
- [ ] The log uses `appNow()`; `DateTime.now(` appears only in `app_clock.dart`.
- [ ] Crash-path writes are `writeAsStringSync(..., flush: true)`; the whole handler body is inside a bare `catch (_)`.
- [ ] The log rotates at 256 KB with one backup, and lives in application support, never cache.
- [ ] A `test/policy/` test asserts no value from §8.4's forbidden column can reach the log — in particular no tag, no note text and **no withdrawal period**.
- [ ] Settings ▸ Diagnostics has all seven rows and the honesty sentence above the share button.
- [ ] Every date on the Diagnostics screen is `d MMM y` and every time `HH:mm` (R60), and the screen states once that its times are machine-recorded, not entered — so §5.4's provenance rule is honoured rather than sidestepped. No diagnostics row renders a `RecordedTime` from a real record.
- [ ] Nothing in the codebase transmits. No prompt to send. No opt-in upload toggle.

**Release**
- [ ] Build number is the release workflow's run number, always; only that workflow's artefact reaches a store.
- [ ] Every build command carries `--dart-define=APP_VERSION` / `APP_BUILD` alongside `--build-name` / `--build-number` (§9.1.1). `package_info_plus` is not a direct dependency, and a diagnostics log reading `0.0.0+0` means somebody built without them.
- [ ] The keystore is backed up somewhere that is not the laptop, and the symbols directory is archived per build number.
- [ ] `RELEASES.md` exists and has a row per tag, and its header records the application id / bundle id.
- [ ] The eight notification channel ids are `reminders.kind`'s eight strings, byte for byte (R49), asserted against the committed schema JSON before the first release — never `turnout`, `dose` or `withdrawal`.
- [ ] The §12 manual checklist is in the repository, not in this document only.
- [ ] The Play 12-tester question (decision-record §7.1 item 14) has been **answered**, and if the answer is yes, the closed test is scheduled with a date.
- [ ] The 1 Feb – 30 Apr freeze is in a calendar, `release.yml` carries §11's warning step, and §11.1's bar is written down before anyone is tempted to argue with it.

---

## References

Every URL below is cited by a rule above.

**Flutter / Dart**
- Build and release an Android app — https://docs.flutter.dev/deployment/android
- Build and release an iOS app — https://docs.flutter.dev/deployment/ios
- Flavors — https://docs.flutter.dev/deployment/flavors
- Measuring your app's size — https://docs.flutter.dev/perf/app-size
- Build modes (profile mode is disabled on emulators) — https://docs.flutter.dev/testing/build-modes
- Handling errors in Flutter — https://docs.flutter.dev/testing/errors
- Flutter 3.44.0 release notes (Android `libapp.so` symbol-stripping default) — https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- UIScene adoption — https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- Customizing static analysis (`language:`, `errors:`, `formatter.page_width`) — https://dart.dev/tools/analysis
- `flutter analyze` flags, read from source — https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/analyze.dart
- `flutter test` flags, read from source — https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/test.dart
- Startup trace keys, read from source — https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/tracing.dart
- `FlutterError.onError` — https://api.flutter.dev/flutter/foundation/FlutterError/onError.html
- `PlatformDispatcher.onError` — https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html
- Dart build hooks — https://dart.dev/tools/hooks
- `flutter_lints` 6.0.0's ten rules, verbatim — https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml
- INTERNET lives in the debug/profile manifests — https://github.com/flutter/flutter/issues/20789
- Zone/binding mismatch — https://github.com/flutter/flutter/issues/94123

**pub.dev**
- `flutter_lints` — https://pub.dev/packages/flutter_lints
- `very_good_analysis` (the documented alternative) — https://pub.dev/packages/very_good_analysis

**Android / Google Play**
- Merge multiple manifest files (`tools:node="remove"`, merge priority) — https://developer.android.com/build/manage-manifests
- App startup time / Android vitals thresholds — https://developer.android.com/topic/performance/vitals/launch-time
- Integrate Google Play's billing system (3-day acknowledgement window) — https://developer.android.com/google/play/billing/integrate
- Billing Library deprecation FAQ (PBL 8 by 31 Aug 2026, PBL 9 by 31 Aug 2027) — https://developer.android.com/google/play/billing/deprecation-faq
- Test your Google Play Billing Library integration (license testers) — https://developer.android.com/google/play/billing/test
- Target API level requirements — https://developer.android.com/google/play/requirements/target-sdk
- App testing requirements for new personal developer accounts (12 testers / 14 days) — https://support.google.com/googleplay/android-developer/answer/14151465
- Use Play App Signing — https://support.google.com/googleplay/android-developer/answer/9842756
- Data safety section — https://support.google.com/googleplay/android-developer/answer/10787469
- Target API level (Play Console Help) — https://support.google.com/googleplay/android-developer/answer/11926878
- bundletool releases — https://github.com/google/bundletool/releases

**Apple**
- App Review Guidelines (3.1.1 restore, 4.3(a), 5.1.1(i)) — https://developer.apple.com/app-store/review/guidelines/
- App privacy details ("collect" = transmitting off device) — https://developer.apple.com/app-store/app-privacy-details/
- Privacy-manifest reason codes — https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- Adding a privacy manifest — https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Upcoming third-party SDK requirements — https://developer.apple.com/support/third-party-SDK-requirements/
- Testing at all stages of development with Xcode and the sandbox — https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox
- Xcode 26 / iOS 26 SDK upload requirement (28 April 2026) — https://developer.apple.com/news/upcoming-requirements/?id=02032026a
- Reducing your app's launch time (the 400 ms goal) — https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time — **the direct fetch of this page returned no body during research; treat the exact wording as second-hand and the 400 ms figure as Apple's published goal**

**CI**
- About billing for GitHub Actions (the 10× macOS multiplier) — https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions
- `subosito/flutter-action` (v2 is the current major; there is no v3) — https://github.com/subosito/flutter-action

**Internal**
- `docs/research/00-tech-decisions.md` §1, §2K, §3 (the offline-purity contract and gates), §4 (dropped and degraded), §5 (the only source of version numbers), §6 (corrections already applied), §7.0 (the owner's rulings), §7.1 (what is still open)
- `docs/research/raw/07-monetization-and-release.md` · `docs/research/raw/08-performance-and-reliability.md` · `docs/research/critique/c1-packages.md` · `docs/research/critique/c3-consistency.md`
