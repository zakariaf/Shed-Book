# C1 — Package & Version Audit (adversarial review)

**Auditor lens:** package and version auditor
**Audited:** 2026-07-27
**Method:** every package below was re-read from the pub.dev API (`/api/packages/<name>` and `/api/packages/<name>/score`), which is the same data the package page renders. Constraint conflicts were computed from published `pubspec.yaml` constraints, not reproduced by running `pub get`. Flutter SDK pins were read from `raw.githubusercontent.com/flutter/flutter/stable/packages/{flutter,flutter_test,flutter_localizations}/pubspec.yaml`. Flutter release history from `storage.googleapis.com/flutter_infra_release/releases/releases_macos.json`.

---

## Verdict in one paragraph

The package research is unusually good on *individual* package facts — dates, likes, points, publishers and README quotes are accurate to within a day or two almost everywhere, and the hard calls (drift over sqflite, avoid ML Kit, avoid RevenueCat, avoid golden_toolkit) are correct and well-evidenced. It fails at the level that matters most for a doc set that must ship one `pubspec.yaml`: **the ten notes were audited in isolation and never reconciled against each other or against a single resolution.** Three notes give three different verdicts for `flutter_riverpod` on the same day. The concrete pubspec in note 03 cannot `pub get`. Two independent `package:http` edges exist in the adopted plugin set and only one note noticed one of them. The chain that breaks all of this — the Flutter SDK's exact `meta: 1.18.0` and `test_api: 0.7.11` pins versus the analyzer 13.1+ line — was found by exactly one researcher (note 02) and ignored by the other nine.

---

## 1. The analyzer/meta/test_api chain — the thing that breaks the build

This is the single most important verified fact in the audit, because four notes recommend a package that cannot resolve.

**Flutter SDK pins (read from `stable`, i.e. Flutter 3.44.8):**

| File | Pin |
|---|---|
| `packages/flutter/pubspec.yaml` | `meta: 1.18.0` (exact) |
| `packages/flutter_test/pubspec.yaml` | `meta: 1.18.0`, `test_api: 0.7.11`, `matcher: 0.12.19` (all exact) |
| `packages/flutter_localizations/pubspec.yaml` | `intl: 0.20.2` (exact) |

**analyzer's `meta` constraint, by version:**

| analyzer | published | `meta` |
|---|---|---|
| 12.1.0 | 2026-04-08 | `^1.18.0` |
| **13.0.0** | 2026-04-22 | `^1.18.0` ← **highest analyzer usable in a Flutter app** |
| 13.1.0 | 2026-06-04 | `^1.18.3` |
| 13.3.0 | 2026-06-11 | `^1.18.3` |
| 14.1.0 | 2026-07-13 | `^1.18.3` |

Because the SDK pins `meta: 1.18.0` exactly, **no Flutter app can resolve analyzer ≥ 13.1.0.** Consequences:

| Package | Declared `analyzer` | Resolvable in a Flutter app? |
|---|---|---|
| `drift_dev` 2.34.5 | `^13.0.0` | Yes — resolves to analyzer 13.0.0 exactly |
| `build_runner` **2.15.2** | `>=13.3.0 <15.0.0` | **NO** |
| `build_runner` 2.15.1 | `>=8.0.0 <14.0.0` | Yes |
| `import_lint` 2.0.0 | `^12.1.0` | Yes alone — **NO** with `drift_dev` ^13 |
| `freezed` 3.2.5 | `>=9.0.0 <11.0.0` | **NO** with `drift_dev` ^13 |
| `custom_lint` 0.8.1 | `^8.0.0` | **NO** with `drift_dev` ^13 |
| `riverpod_lint` 3.1.6 | `^13.0.0` **+** `riverpod_analyzer_utils: 1.0.0-dev.10` (which requires `analyzer ^12.0.0`) | **NO — self-contradictory** |
| `riverpod_generator` 4.0.6 | same self-contradiction | **NO — self-contradictory** |

**And the `test` package:** every `test` release pins `test_api` exactly. The SDK pins `test_api: 0.7.11`. The only `test` release pinning `test_api: 0.7.11` is **`test` 1.31.0** (2026-03-18), whose constraint is `analyzer >=8.0.0 <13.0.0`. `test` 1.31.2 pins `test_api: 0.7.13` and cannot coexist with `flutter_test` at all.

Therefore, in a Flutter app on current stable:
- `test` resolves to **1.31.0**, not 1.31.2;
- `test` 1.31.0 (`analyzer <13.0.0`) is **mutually exclusive with `drift_dev` ≥ 2.34.1** (`analyzer ^13.0.0`);
- anything that drags `test` in — including `riverpod` 3.x's runtime `test: ^1.0.0` — therefore forces `drift_dev` back to **2.34.0** (`analyzer >=10.0.0 <13.0.0`), which is exactly what note 02 observed empirically.

Note 02's core finding is **fully corroborated by published constraints**, and its explanation of *why* pub picked `drift_dev 2.34.0` under `any` constraints is now mechanically explained rather than merely observed.

---

## 2. Findings

### BLOCKER-1 — `build_runner: ^2.15.2` does not resolve; four notes recommend it
Notes 01 (§4.4, sources list), **03 (§2.6 concrete pubspec)**, 07 (dependency table, verdict "adopt"), 08 (implicit via drift_dev) all name `build_runner 2.15.2`. It requires `analyzer >=13.3.0`, which requires `meta ^1.18.3`, which the Flutter SDK forbids (`meta: 1.18.0` exact).
**Correction:** `build_runner: ">=2.15.0 <2.15.2"`. Note 02 already says this ("constrain to `any` (resolves to 2.15.1) or an explicit `<2.15.2`") and is the only note that does.

### BLOCKER-2 — note 03's shipped pubspec is unresolvable twice over
`03-persistence.md` §2.6 publishes a copy-pasteable pubspec containing both `build_runner: ^2.15.2` (BLOCKER-1) **and** `test: any` in `dev_dependencies` next to `drift_dev: ^2.34.5`. `test` caps analyzer below 13.0.0; `drift_dev` 2.34.5 requires `^13.0.0`. Empty intersection.
**Correction:** drop `test:` entirely (a Flutter app uses `flutter_test`, which does **not** depend on `package:test`), and cap build_runner. Add a CI step that actually runs `flutter pub get` on the published pubspec before it ships in the doc set.

### BLOCKER-3 — three notes, three verdicts for the same package on the same day
| Note | Package | Verdict | Mentions the resolution failure? |
|---|---|---|---|
| 01 | `flutter_riverpod` 3.4.1 | adopt-with-care | No |
| 02 | `flutter_riverpod` 3.4.1 | **avoid** — "the only state option tested that breaks `pub get`"; pin 2.6.1 | Yes, reproduced locally |
| 04 | `flutter_riverpod` 3.4.1 | adopt — "pin the version" | No |

Note 02 is right and the mechanism is confirmed above. Notes 01 and 04 both build substantial guidance (retry config, `ProviderContainer.test()`, `WidgetTester.container`, `Ref.mounted`, `ProviderException` error assertions) on a version the app cannot install alongside `drift_dev`. Note 04's entire Riverpod-3 testing section is unusable if 2.6.1 is pinned.
**Correction:** one verdict in the doc set. If Riverpod: `flutter_riverpod: 2.6.1` exact, and delete or clearly quarantine every 3.x-only API in notes 01 and 04.

### HIGH-4 — `import_lint` 2.0.0 cannot coexist with `drift_dev`
`import_lint` 2.0.0 declares `analyzer: ^12.1.0` → `[12.1.0, 13.0.0)`. `drift_dev` 2.34.5 declares `^13.0.0`. Note 04 verdicts it "adopt-with-care"; note 01 praises it in its "why" and rejects it only on adoption grounds. Neither noticed it is unresolvable on the very stack they specify. This is the same class of error note 02 caught for `riverpod_lint` — the doc set applied the check inconsistently.
**Correction:** verdict `avoid` with the reason "analyzer ^12.1.0 conflicts with drift_dev's ^13.0.0", and keep the dependency-free `tool/check_layers.dart` script as the only gate (which both notes already prefer anyway).

### HIGH-5 — `test 1.31.2` is not obtainable, and does not arrive via `flutter_test`
Notes 04 and 07 both ship a `test 1.31.2 · adopt` row. Note 07 states "Comes in transitively via `flutter_test`." `flutter_test`'s dependencies are `test_api 0.7.11`, `matcher 0.12.19`, `path`, `fake_async`, `clock`, `stack_trace`, `vector_math`, `leak_tracker_flutter_testing`, `collection`, `meta`, `stream_channel` — **`test` is not among them.** And `test` 1.31.2 pins `test_api: 0.7.13`, which the SDK pin excludes.
**Correction:** remove the `test` row from the runtime/dev table. Re-anchor the `dart_test.yaml` / `--test-randomize-ordering-seed` guidance in note 04 to `test` 1.31.0 (the only version compatible with the SDK) and verify each flag against `flutter test` rather than `dart test`, which note 04 already flags as a risk but attributes to the wrong version.

### HIGH-6 — the "no network path" claim: `package:http` is in the graph twice, not zero times
The app's headline claim is that there is no network path. Verified regular (non-dev) dependencies:

| Edge | Verified |
|---|---|
| `flutter_local_notifications` 22.2.0 → `timezone` ^0.11.0 → **`http: ^1.6.0`** | Yes (timezone 0.11.1 pubspec) |
| `wakelock_plus` 1.7.0 → `package_info_plus` >=10.1.0 <11.0.0 → **`http: ^1.6.0`** | Yes (package_info_plus 10.2.1 pubspec) |

- Note 04 caught the first and correctly labelled it "CRITICAL FINDING: ... Any 'no http in pubspec.lock' offline gate is unsatisfiable."
- **Note 06 asserts the opposite** for the same package: flutter_local_notifications has "No network dependency in the graph (deps: clock, timezone, and federated linux/web/windows packages)."
- **Note 06 also asserts** for wakelock_plus: "Deps include package_info_plus, win32, dbus, web (desktop noise, **none network**)." That is false.
- Note 09 describes `timezone` as "no network".

Runtime exposure on Android/iOS is plausibly nil (the `http` use in `timezone` is in `browser.dart`, added in 0.10.0 per its changelog; `package_info_plus` uses it on web), and note 02 separately verified on a built APK that no `INTERNET` permission is merged and no network symbols survive AOT. But the *dependency graph* claim is wrong, and the CI gate designed in note 01 §12.2 / note 03 ("allowlist `pubspec.lock`") is unsatisfiable as written.
**Correction:** state once, in the shared dependency table, that `http 1.6.0` is an unavoidable transitive dependency via two edges; make the gate **import-level in `lib/` + merged-manifest permission assertion + a documented transitive allowlist**, exactly as note 04 proposes. Delete the "none network" phrasing from note 06 and the "no network" phrasing from note 09.

### MEDIUM-7 — the stated toolchain baseline is not the current stable
All ten notes target "Flutter 3.44.6 stable" and notes 02/04 present resolution results as verified against it. Flutter release history:

| Version | Released | Dart |
|---|---|---|
| **3.44.8** | **2026-07-23** ← current stable on the research date | 3.12.2 |
| 3.44.7 | 2026-07-20 | 3.12.2 |
| 3.44.6 | 2026-07-09 (note 02 says "2026-07-08") | 3.12.2 |

Dart is unchanged at 3.12.2 and the `meta`/`test_api`/`intl` pins are the same on current stable, so no conclusion above flips — but a doc set whose central artefact is a resolution result must name the version it was resolved against, and 3.44.6 was already two patch releases stale when the research was written.
**Correction:** re-baseline to 3.44.8 and re-run the resolution matrix, or state explicitly "pinned to 3.44.6 via FVM; do not upgrade without re-running the matrix."

### MEDIUM-8 — publisher attributions in note 02's table are wrong in two places
| Package | Note 02 says | pub.dev |
|---|---|---|
| `custom_lint` 0.8.1 | "dash-overflow.net (verified)" | **invertase.io** (notes 01 and 05 have it right) |
| `riverpod_lint` 3.1.6 | "dash-overflow.net (verified)" | **no publisher tag at all** — not published under a verified publisher |

A table that uses "verified publisher" as a trust signal cannot get the publisher wrong.

### MEDIUM-9 — `sqlite3_flutter_libs` is *not* marked discontinued on pub.dev
Notes 03, 07, 08 and 09 call it "DISCONTINUED" / "Discontinued". pub.dev's `isDiscontinued` flag is **false** for both `sqlite3_flutter_libs` 0.6.0+eol and `sqlcipher_flutter_libs` 0.7.0+eol. What exists is an `+eol` build suffix plus a caution box: *"Not used anymore, update to version 3.x of package:sqlite3 instead"* and README text *"Starting from version 0.6.0, this package no longer does anything."* The practical advice ("don't add it yourself") is correct; the metadata claim is not. Two consequences:
1. a CI check keyed on pub.dev's discontinued flag will not fire on it;
2. **`drift_flutter` 0.3.1 declares both as regular dependencies** (`sqlite3_flutter_libs: ^0.6.0+eol`, `sqlcipher_flutter_libs: ^0.7.0+eol`), so both **will** be in `pubspec.lock` regardless. Notes 03 and 08 say this correctly; notes 07 and 09 imply the app can be free of them.

### MEDIUM-10 — `intl` will resolve to 0.20.2, not the 0.20.3 in the table
`flutter_localizations` pins `intl: 0.20.2` **exactly** on stable (verified). Note 10's `intl: any` advice is right and the reason is right, but its table row says `intl 0.20.3 · adopt`, which is the version the app will *not* get.
**Correction:** table row = `intl` **0.20.2 (SDK-pinned via flutter_localizations)**, declared as `intl: any`.

### MEDIUM-11 — `flutter_native_splash`: notes 05 and 08 disagree, and note 08 omits the abandonment signal
Verified: GitHub issue `jonbhanson/flutter_native_splash#821`, **open**, created **2026-03-06** by the maintainer `jonbhanson`, titled *"flutter_native_splash is looking for new project owner."* Note 05 cites it and verdicts `avoid`. Note 08 verdicts `adopt-with-care` for asset generation and does not mention it.
**Correction:** one verdict. If adopted for generation only, the note must carry the ownership-search fact and the "commit generated files, CI-check regeneration produces no diff" mitigation that note 05 already wrote.

### MEDIUM-12 — `drift_dev` scores 90/160 and no note says so
Several notes reject packages on pub-points grounds (`custom_lint` 60, `riverpod_generator` 40, `flutter_glados` 30, `import_lint` low adoption). The doc set's own core code generator scores **90/160**, losing points for: platform support 0/20 (`dart:js_interop`/`dart:ffi` import-chain conflict), up-to-date dependencies 10/40 (*"`analyzer` constraint `^13.0.0` incompatible with latest `14.1.0`"*, *"`package_config` constraint `^2.1.0` incompatible with latest `3.0.0`"*), static analysis 40/50, no example 10/20. The dependency-lag item is the same analyzer-chain lag that already breaks `build_runner` — it is a leading indicator, not cosmetic.
**Correction:** disclose it in the table. It does not change the adopt verdict; it changes the honesty of the selection criteria.

### LOW-13 — `freezed`'s incompatibility is understated
Note 02 says `freezed` 3.2.5's `analyzer: >=9.0.0 <11.0.0` conflicts with `build_runner` 2.15.2's `>=13.3.0`. It also conflicts with `drift_dev` 2.34.5's `^13.0.0`, i.e. freezed is unusable on this stack **whatever** build_runner is pinned to. Strengthens the (correct) "avoid" call; the stated reason is incomplete.

### LOW-14 — `flutter_lints` has two verdicts
Notes 01, 04 and 05 say `adopt`; note 07 says `avoid` (correctly noting it sets no analyzer language modes and quoting its exact ten Flutter rules). These are reconcilable — note 07's own text says it is acceptable paired with an `analyzer.language` block — but the shipped table must carry one row.

### LOW-15 — minor date drift
`speech_to_text` 7.4.0 published **2026-05-19**; note 06 says "~2026-05-27 ('2 months ago')". `drift` 2.34.2 published **2026-07-14**, not "~2026-07-15". `realm` 20.2.0 published **2025-09-24**. Several "N days ago" figures are off by 1–2 days. Immaterial individually; worth one pass because the notes present these as read-off-the-page facts.

### LOW-16 — the ZIP streaming question is still open
Note 06 honestly flags that it could not verify a streaming ZIP *encoder* in `archive` and proposes a JSON-only fallback on that basis. Partial resolution: `ZipFileEncoder` **does** exist and is exported from `package:archive/archive_io.dart` alongside `OutputFileStream`/`InputFileStream`. Its incremental-write behaviour still needs a primary-source or empirical confirmation before a design decision (media-in-ZIP vs media-shared-separately) is made on the assumption that it does not stream.

---

## 3. Everything the researchers got right (so it is not re-litigated)

Verified accurate against pub.dev on 2026-07-27, no correction needed:

- **`dart_code_metrics` 5.7.6 — `isDiscontinued: true`**, last published 2023-07-16. Correctly used as the cautionary precedent (note 01).
- **`golden_toolkit` 0.15.0 — `isDiscontinued: true`**, 2023-02-21, 488 likes / 385k downloads. Note 04's warning that it "looks alive in search results" is exactly right.
- **`wakelock` 0.6.2 — `isDiscontinued: true`, `replacedBy: wakelock_plus`.** Note 06 correct.
- **`riverpod` 3.4.1 declares `test: ^1.0.0` in `dependencies:`** — verified verbatim in the pubspec. `flutter_riverpod` 3.4.1 declares `flutter_test: {sdk: flutter}`. `hooks_riverpod` 3.4.1 carries both. Note 02 correct.
- **`riverpod_generator` 4.0.6 and `riverpod_lint` 3.1.6 are internally unresolvable**: both declare `analyzer: ^13.0.0` while pinning `riverpod_analyzer_utils: 1.0.0-dev.10`, whose own pubspec declares `analyzer: ^12.0.0`. Note 02 correct, and worth adding: `riverpod_analyzer_utils`' latest **stable** is 0.5.10 (2025-02-28, 3 likes) — the whole codegen chain hangs off a prerelease.
- **`timezone` 0.11.1 declares `http: ^1.6.0` as a regular dependency.** Note 04 correct (and see HIGH-6).
- **`timezone` 0.11.0 changed `Location.offset` from `int` to `Duration`.** Note 09 correct (verified in changelog).
- **`google_fonts` 8.2.0 declares `http: ^1.0.0`** and its README documents HTTP fetching at runtime as the default. Note 05 correct.
- **`printing` 5.15.0 declares `http: >=0.13.0 <2.0.0`.** Note 06 correct.
- **`drift_flutter` 0.3.1 declares `sqlite3_flutter_libs: ^0.6.0+eol` and `sqlcipher_flutter_libs: ^0.7.0+eol`.** Notes 03 and 08 correct.
- **drift changelog:** 2.34.0 *"Use `BEGIN IMMEDIATE` to start transactions"*; 2.32.0 *"Potentially breaking change: Migrate to version 3.x of the `sqlite3` package."* Notes 01 and 03 correct.
- **`flutter_local_notifications` Android manifest declares exactly `VIBRATE` and `POST_NOTIFICATIONS`** — no receiver, service, provider or queries. Notes 01, 06, 07 correct.
- **`invertase/dart_custom_lint` GitHub repo is `archived: true`**, last push 2026-03-24, 51 open issues. Note 05 correct.
- **`checks` 0.3.1 README:** *"`package:checks` is still experimental. For production use cases, please use `package:test` and `package:matcher`."* Note 04 correct.
- **`realm` 20.2.0** is not flagged discontinued but carries *"We announced the deprecation of Atlas Device Sync + Realm SDKs in September 2024."* Note 03 correct.
- **Prerelease-only successors** all correct: `isar` 4.0.0-dev.14 (stable frozen at 3.1.0+1, 2023-04-25), `hive` 4.0.0-dev.2 (stable 2.2.3, 2022-06-30), `freezed` 4.0.0-dev.3, `flutter_screenutil` 6.0.0-alpha.1 (stable 5.9.3, 2024-05-31), `easy_localization` 4.0.0-dev.0, `file_picker` 12.0.0-beta.7.
- **Play Billing deadlines**: PBL 8 required by **31 Aug 2026**; PBL 9 required by **31 Aug 2027**. Note 07 is correct on both, and `in_app_purchase_android` 0.5.2 (Billing 8.0.0) therefore satisfies the near deadline. No contradiction.
- **`sqlite_async` 0.14.4 depends on `sqlite3: ^3.5.0`** and does not require PowerSync. Note 03 correct.
- **`fixed` 6.1.1, onepub.dev, 11 likes.** Note 09 correct.
- **Unverified-uploader calls all correct**: `csv`, `glados`, `screen_brightness`, `disk_space_plus`, `easy_localization`, `flutter_screenutil` all return no `publisher:` tag.
- **Download-count figures** in the notes match what pub.dev renders; the "weekly" wording is pub.dev's own sidebar label, not a researcher error. Not a finding.

---

## 4. The dependency table the doc set should ship

Verified 2026-07-27. Everything below was checked to resolve against Flutter stable's `meta: 1.18.0` / `test_api: 0.7.11` / `intl: 0.20.2` pins.

### 4.1 Runtime dependencies — adopt

| Package | Verified version | Publisher | Why it is here | What it costs | Verdict |
|---|---|---|---|---|---|
| `drift` | 2.34.2 (2026-07-14) | simonbinder.eu ✓ | Reactive typed SQLite; `watch()` streams make "DB is the single source of truth" structural; generated migration snapshots + `SchemaVerifier` | build_runner in the loop; single maintainer; open #3338 (torn `combineLatest`), #3295 (no `distinct()`) | **adopt** |
| `drift_flutter` | 0.3.1 (2026-07-11) | simonbinder.eu ✓ | `driftDatabase()`; background connection; sets `sqlite3.tempDirectory` | Pre-1.0. Defaults to Documents dir — override to Application Support. Drags `sqlite3_flutter_libs`/`sqlcipher_flutter_libs` EOL stubs into `pubspec.lock` (harmless, unavoidable) | **adopt-with-care** |
| `sqlite3` | 3.5.0 (2026-07-18) | simonbinder.eu ✓ | Bundles SQLite via Dart build hooks; guarantees FTS5 + STRICT on every device | Build hooks **download** binaries from GitHub at build time (sha256-verified). Build machine needs network; shipped app does not | **adopt** |
| `path_provider` | 2.1.6 (2026-06-15) | flutter.dev ✓ | DB + media + temp paths | iOS container UUID changes across installs — never persist absolute paths. Apple privacy-manifest SDK | **adopt** |
| `uuid` | 4.6.0 (2026-07-15) | yuli.dev ✓ | RFC 9562 v7 ids; monotonic prefix keeps the uid index appending | None material. Pure Dart | **adopt** |
| `share_plus` | 13.3.0 (2026-07-23) | fluttercommunity.dev ✓ | The only export/backup channel (spec §7.9) | Static `Share.*` API deprecated — use `SharePlus.instance.share(ShareParams(...))`. `sharePositionOrigin` required on iPad. Requires Flutter ≥3.38.1 | **adopt** |
| `clock` | 1.1.2 (2024-10-28) | tools.dart.dev ✓ | `clock.now()` / `withClock()`; the one chokepoint making spec §12.5 testable | Must be paired with a CI ban on `DateTime.now(` and SQLite `CURRENT_TIMESTAMP` or it is bypassed | **adopt** |
| `intl` | **0.20.2** (SDK-pinned) | dart.dev ✓ | `DateFormat`/`NumberFormat`; transitive requirement of `flutter_localizations` | **Must be declared `intl: any`** — `flutter_localizations` pins 0.20.2 exactly, so `^0.20.3` will not resolve. Re-check after every Flutter upgrade | **adopt** |
| `flutter_localizations` | SDK | flutter.dev | `GlobalMaterialLocalizations` → en-GB date/time pickers | Pins `intl` exactly (above). Not on pub.dev | **adopt** |
| `flutter_local_notifications` | 22.2.0 (2026-07-25) | dexterx.dev ✓ | The only reminder mechanism (spec §7.6) | Merges `POST_NOTIFICATIONS` + `VIBRATE` only; you add `RECEIVE_BOOT_COMPLETED` + `SCHEDULE_EXACT_ALARM`. **Drags `timezone` → `http 1.6.0` into the graph.** Heavy breaking-change history (v16/v18/v19/v20). Requires Flutter ≥3.38.1, desugar_jdk_libs 2.1.4 | **adopt-with-care** |
| `timezone` | 0.11.1 (2026-06-29) | labs.dart.dev ✓ | Forced by `flutter_local_notifications.zonedSchedule` | **Declares `http: ^1.6.0` as a regular dependency.** Bundled IANA 2025c ages; refresh is a release-checklist item. 0.11.0 changed `Location.offset` `int`→`Duration` | **adopt (forced)** |
| `wakelock_plus` | 1.7.0 (2026-07-21) | fluttercommunity.dev ✓ | Screen sleep mid-lambing forces a wet-gloved unlock — alone blows the 15 s budget | **Drags `package_info_plus` → `http 1.6.0` into the graph.** Must be per-screen, default off, released on dispose and on any non-resumed lifecycle state | **adopt-with-care** |
| `image_picker` | 1.2.3 (2026-06-30) | flutter.dev ✓ | Photo attach via system photo picker / system camera | Merges **zero** Android permissions. Needs `NSCameraUsageDescription` etc. Use `retrieveLostData()` | **adopt** |
| `flutter_image_compress` | 2.5.1 (2026-07-25) | fluttercandies.com ✓ | Native downscale at capture; `keepExif` defaults **false** (strips GPS) | Needs `BackgroundIsolateBinaryMessenger.ensureInitialized` off the root isolate. `quality` ignored for PNG on iOS | **adopt** |
| `file_selector` | 1.1.0 (2025-11-21) | flutter.dev ✓ | Backup import via `ACTION_OPEN_DOCUMENT` / `UIDocumentPickerViewController` — no storage permission | Android MIME filtering unreliable for `.zip`; validate magic bytes yourself. Older publish date = feature-complete | **adopt** |
| `pdf` | 3.13.0 (2026-06-16) | nfet.net ✓ | Flock book + medicine record PDFs. Pure Dart, no http in its deps | Base-14 fonts are Latin-1 and **throw** on curly quotes/ellipses — always embed a TTF. `save()` materialises the whole doc — isolate it | **adopt** |
| `archive` | 4.0.9 (2026-02-17) | loki3d.com ✓ | ZIP backup. Deps are only `path` + `posix`. Already transitive via `pdf` | Streaming *encode* still unverified — `ZipFileEncoder` exists in `archive_io` with `OutputFileStream`; confirm before designing media-in-ZIP | **adopt-with-care** |
| `record` | 7.1.1 (2026-06-29) | cow-level.ovh ✓ | Voice notes (spec §7.2). Merges exactly `RECORD_AUDIO` | Class is `AudioRecorder` (not `Record`). Use `aacLc`/`.m4a`, never opus (container differs per platform → broken cross-platform restore). Requires Flutter ≥3.44 | **adopt** |
| `in_app_purchase` | 3.3.0 (2026-06-03) | flutter.dev ✓ | One-time unlock (spec §14). Binder IPC / XPC, not an app-process network path; adds no manifest permission | `in_app_purchase_storekit` **must be ≥ 0.4.8** (0.4.3-era regression reported StoreKit2 purchases as `restored` and left them unfinished). Play Billing 9 mandatory 31 Aug 2027 | **adopt** |
| `device_info_plus` | 13.2.0 (2026-06-26) | fluttercommunity.dev ✓ | Model + OS version in the diagnostics log header. No `http` in its deps | Do **not** request the iOS 16+ device-name entitlement (user-identifying, spec §4.5) | **adopt** |
| `logging` | 1.3.0 (2024-10-17) | dart.dev ✓ | Named loggers + a `LogRecord` stream wired to a local rolling file | Crash-path writes must bypass the stream (`writeAsStringSync(flush: true)`) | **adopt** |
| **State management** — pick one | | | | | |
| `flutter_riverpod` | **2.6.1 pinned exactly** (2024-10-22) | dash-overflow.net ✓ | Context-free DI, `ProviderScope` test overrides, `.select`, `autoDispose`; 4 pure-Dart transitive deps | Frozen: **no bug fixes**. 3.x is not installable alongside `drift_dev` ≥2.34.1 (see §1). Do not use `StateProvider` or `AsyncValue.valueOrNull` so a future 4.0 migration is near-free | **adopt** |
| `provider` | 6.1.5+1 (2025-08-19) | dash-overflow.net ✓ | Flutter's official DI recommendation; adds only `nested`; resolves cleanly | BuildContext-scoped DI is awkward for export/notification code; `ChangeNotifier` is mutable; ~16 lines of `StreamSubscription` lifecycle per screen | **legitimate fallback** |

### 4.2 Dev dependencies — adopt

| Package | Verified version | Why | Cost | Verdict |
|---|---|---|---|---|
| `drift_dev` | 2.34.5 (2026-07-22) | `make-migrations`, `schema steps`, `SchemaVerifier`, generated migration tests | **90/160 pub points** (analyzer/package_config lag, 0/20 platforms, failing downgrade test). Import `api/migrations_native.dart`, not the deprecated `api/migrations.dart` | **adopt** |
| `build_runner` | **`">=2.15.0 <2.15.2"`** | Required by drift codegen | **`^2.15.2` does not resolve** (see BLOCKER-1). `--workspace` is explicitly experimental | **adopt, capped** |
| `flutter_lints` | 6.0.0 (2025-05-27) | Baseline lint set | Sets **no** analyzer language modes — pair with an explicit `analyzer: language: strict-casts: true` block | **adopt** |
| `very_good_analysis` | 10.3.0 (2026-06-18) | Alternative to the above: turns on `strict-casts` + `strict-inference` + `strict-raw-types` (~215 rules); zero dependencies | Noisy day one; disable the package-publishing/taste rules | **adopt (alternative)** |
| `mocktail` | 1.0.5 (2026-04-10) | Interaction-ordering / non-invocation assertions only. No codegen | Overuse risk — hand-written fakes beat it for the six gateways | **adopt-with-care** |
| `accessibility_tools` | 2.8.0 (2025-11-13) | Debug-only semantic-label / tap-area / large-font checker. Deps: `collection`, `flutter`, `flutter_test` only | Its 48×48 default is below the spec's 60×60 — complements, does not replace, a house assertion | **adopt** |
| `glados` | 1.1.7 (2023-12-04) | Property-based testing with shrinking for pure value round-trips | **Unverified uploader**, 2.5 y stale, 50 likes. Dev-only, deletable. Hand-roll the whole-flock graph generator | **adopt-with-care** |
| `golden_screenshot` | 11.0.1 (2026-03-20) | Store screenshots from golden tests | Belongs in `tool/`, not `test/`. 26 likes | **adopt-with-care** |

### 4.3 Avoid — with the reason and the alternative

| Package | Verified version | Why avoided | Alternative |
|---|---|---|---|
| `flutter_riverpod` / `riverpod` | 3.4.1 | Runtime `test`/`flutter_test` dep forces `test` 1.31.0 → `analyzer <13` → **cannot coexist with `drift_dev` ≥2.34.1** | `flutter_riverpod` 2.6.1 pinned |
| `riverpod_generator` | 4.0.6 | **Unresolvable in any project**: `analyzer ^13.0.0` + `riverpod_analyzer_utils 1.0.0-dev.10` (`analyzer ^12.0.0`) | Hand-written providers (~1 line each) |
| `riverpod_lint` | 3.1.6 | Same self-contradiction | None; revisit after `riverpod_analyzer_utils` gets an analyzer-13 release |
| `riverpod_annotation` | 4.0.5 | Pins `riverpod: 3.4.1` exactly; moot once codegen is rejected | — |
| `hooks_riverpod` | 3.4.1 | Second mental model; same runtime `flutter_test` dep | — |
| `import_lint` | 2.0.0 | **`analyzer ^12.1.0` conflicts with `drift_dev` ^13.0.0** — unresolvable on this stack | `tool/check_layers.dart` (zero deps) |
| `custom_lint` | 0.8.1 | `analyzer ^8.0.0` (six majors behind); **upstream repo archived** 2026-03-24, 51 open issues | `tool/check_tokens.dart` (~40 lines) |
| `dart_code_metrics` | 5.7.6 | **`isDiscontinued: true`**, commercial relicense | Dependency-free scripts |
| `freezed` | 3.2.5 | `analyzer >=9.0.0 <11.0.0` — conflicts with **both** `drift_dev` and `build_runner`; redundant given drift's generated rows | drift rows + hand-written `@immutable` classes |
| `go_router` | 17.3.0 | Core value is URL routing; no web, no deep links. Three majors in ~24 months. Open restoration bugs flutter#117683 (since 2022-12-27) and #174935 | `Navigator` + typed push helpers |
| `get_it` | 9.2.1 | Global service locator; second DI system alongside Riverpod | Riverpod / provider |
| `melos` | 8.2.2 | Now delegates to pub workspaces; nothing to orchestrate at 1 package | 4-target Makefile |
| `test` (direct) | 1.31.0 max | Caps `analyzer <13.0.0` → breaks `drift_dev`. Does **not** arrive via `flutter_test` | `flutter_test` only |
| `google_fonts` | 8.2.0 | `http ^1.0.0`; HTTP fetching at runtime is the default | Bundle the TTF; CI grep for `GoogleFonts` |
| `printing` | 5.15.0 | `http >=0.13.0 <2.0.0`; `PdfGoogleFonts`/`networkImage` are one-line footguns | `share_plus` alone |
| `google_mlkit_text_recognition` | 0.16.0 | Play Services transitive deps contribute INTERNET/ACCESS_NETWORK_STATE; ~38 MB per script on iOS vs a <20 MB budget | Cut OCR from v1 |
| `speech_to_text` | 7.4.0 (2026-05-19) | `SpeechListenOptions.onDevice` defaults false and silently falls back to network recognition; no API reports on-device availability | Defer to v1.1 |
| `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` | 0.6.0+eol / 0.7.0+eol | No-op EOL shims (**not** flagged discontinued on pub.dev). Arrive transitively via `drift_flutter` anyway | `package:sqlite3` 3.x |
| `sqflite` | 2.4.3 | Uses the OS SQLite — STRICT/FTS5 become a per-device lottery. No reactive streams, no migration tooling | drift |
| `sqlite_async` | 0.14.4 | Good, but no generated schema snapshots / `SchemaVerifier` | drift |
| `objectbox` / `isar` / `hive` / `hive_ce` / `realm` / `sembast` | 5.3.2 / 3.1.0+1 / 2.2.3 / 2.19.3 / 20.2.0 / 3.8.9+1 | Proprietary format, prerelease-only successors, deprecated upstream, or wrong data model | drift |
| `flutter_secure_storage` | 10.3.1 | Only needed for a DB encryption key; its own page documents the Android-backup `InvalidKeyException` that makes a restore permanently unreadable | No encryption at rest |
| `purchases_flutter` | 10.4.3 | Mandatory third-party network path + API key; forces a "Purchase history collected" Play declaration | `in_app_purchase` |
| `flutter_inapp_purchase` | 9.6.1 | Technically ahead but single-maintainer bus factor on a decade-lived dependency | `in_app_purchase` |
| `file_picker` | 11.0.2 | Heavier transitive deps; cloud-picking undercuts the positioning; 12.0.0-beta.7 signals another break | `file_selector` |
| `permission_handler` | 12.0.3 | Every permission needed has a first-party request API; CocoaPods `PERMISSION_*` macro block is an App Store rejection risk | Per-plugin APIs |
| `camera` | 0.12.0+2 | Merges `CAMERA` + `RECORD_AUDIO`; manual lifecycle handling | `image_picker` system camera |
| `csv` | 8.0.0 | Unverified uploader + fresh breaking rewrite, for ~50 lines of RFC 4180 you need byte control over | Hand-rolled encoder |
| `golden_toolkit` | 0.15.0 | **`isDiscontinued: true`** | Local `LocalFileComparator` harness |
| `alchemist` | 0.14.0 | CI text-blocking replaces text with coloured squares — destroys the legibility property the goldens exist to prove | Local harness |
| `patrol` | 4.8.0 | Requires `patrol_cli`, Gradle + Xcode test target; `flutter test` won't run its tests | Manual check of 4 native surfaces |
| `checks` | 0.3.1 | *"still experimental. For production use cases, please use `package:test` and `package:matcher`."* | `matcher` |
| `spot` / `flutter_glados` | 0.18.0 / 1.1.18 | Debuggability not correctness; 1 like / 55 downloads respectively | — |
| `mockito` | 5.7.0 | Requires `@GenerateNiceMocks` codegen for 3–6-method interfaces | `mocktail` / hand fakes |
| `sqlite3_test` | 0.2.0 | Only needed if SQL-side time is used, which is banned; cannot support WAL | Ban SQL-side time |
| `flutter_native_splash` | 2.4.8 | Maintainer publicly seeking a new owner (issue #821, open since 2026-03-06); rewrites 3 native files as a second source of truth | ~25 lines of hand-written XML/plist |
| `screen_brightness` | 2.1.11 | Unverified uploader; changing a system property the user did not ask for | Cap luminance in the red palette tokens |
| `slang` / `easy_localization` / `intl_translation` | 4.18.0 / 3.0.8 / 0.22.0 | SDK-bundled `gen-l10n` beats a third-party tool for a solo dev; `easy_localization` has an HTTP loader extension point and an unverified uploader | `gen-l10n` |
| `flutter_screenutil` | 5.9.3 | Fights OS text scale; its own escape hatch (`textScaleFactor: 1.0`) breaks Apple's Larger Text criterion | `MediaQuery.textScalerOf` |
| `disk_space_plus` | 0.2.6 | 14 likes, unverified uploader, 13 months stale | ~20-line `StatFs`/`NSFileManager` channel |
| `open_filex` | 4.7.0 | Share sheet already offers "Open in…"; 16 months stale | `share_plus` |
| `ulid` | 2.0.1 | Community spec, 22 months stale, less legible in a CSV | `uuid` v7 |
| `fixed` / `decimal` | 6.1.1 / 3.2.5 | `BigInt` allocations for a problem integer grams solves exactly | `int` canonical units |
| `signals` / `flutter_bloc` | 7.1.0 / 9.1.1 (2025-05-02) | Elegance / discipline that this app's small state surface does not need. Note: `flutter_bloc` itself is 15 months since last publish (`bloc` core is current at 9.2.1) | Riverpod 2.6.1 |
| `connectivity_plus` / `workmanager` / `battery_plus` | — | The offline-first design pattern's packages. All are banned network/sync machinery here | Nothing |

---

## 5. Actions required before this doc set ships

1. Cap `build_runner` below 2.15.2 everywhere and re-publish note 03's pubspec.
2. Delete `test:` from note 03's dev_dependencies; delete the `test 1.31.2` rows from notes 04 and 07.
3. Pick one `flutter_riverpod` verdict and propagate it through notes 01, 02 and 04.
4. Flip `import_lint` to `avoid` in note 04 with the analyzer-conflict reason.
5. Add one shared "unavoidable transitive `http`" statement covering **both** the `timezone` and `package_info_plus` edges; correct notes 06 and 09.
6. Correct `custom_lint` and `riverpod_lint` publishers in note 02.
7. Change the `intl` table row to 0.20.2.
8. Re-baseline the toolchain to Flutter 3.44.8, or state the pin explicitly.
9. Reconcile the `flutter_native_splash` and `flutter_lints` verdicts.
10. Actually run `flutter pub get` against the final table and commit the resulting `pubspec.lock` as the doc set's evidence.
