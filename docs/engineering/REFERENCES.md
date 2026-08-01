# REFERENCES — the master bibliography for the Shed Book engineering doc set

Every primary source cited anywhere in the fourteen engineering documents and in `docs/research/00-tech-decisions.md`, deduplicated and grouped. Below the bibliography is the section that matters as much as it: **§22, what could not be verified** — every claim in the set that rests on something nobody fetched, nobody measured, or nobody ran, with what it would take to close each one and which document breaks if it turns out wrong.

**Compiled 2026-07-27**, against the toolchain recorded in §23.

---

## How to read this file

- **Every source below was fetched on 2026-07-27** unless the entry says otherwise. Two entries record a fetch that *failed*; both are marked, and both reappear in §22.
- **No version number appears in this file.** Package versions live in `docs/research/00-tech-decisions.md` §5 and nowhere else — that is decision #5 and it is not negotiable. Where a pub.dev page is cited below, it is cited as *the package's documentation*, not as the source of its version.
- **A URL in this bibliography is not a warrant.** Several documents deliberately read the *source* rather than the docs page — `02-state-di-navigation.md` reads Riverpod out of `~/.pub-cache`, `10-accessibility-and-i18n.md` reads the Flutter engine and framework, `06-design-system.md` resolves every symbol against a local SDK checkout. Those reads are recorded in §5 and §12 and they outrank any doc page that disagrees.
- **Project-internal documents are listed in §19**, separately, because they are provenance and not primary sources.
- Notes are one line each and say what the citation is *load-bearing for* — not what the page is about.

---

## 1. Flutter — official documentation: app architecture

The architecture guide is the spine of `01-architecture.md` and `02-state-di-navigation.md`, including the one page the app is required *not* to follow.

| Source | URL | Load-bearing for |
|---|---|---|
| App architecture concepts | https://docs.flutter.dev/app-architecture/concepts | The two mandatory layers and the optional logic layer — 01 §1's layer model. |
| Architecture guide | https://docs.flutter.dev/app-architecture/guide | View / ViewModel / Repository / Service definitions; the MVVM shape 01 and 02 both build on. |
| Architecture recommendations | https://docs.flutter.dev/app-architecture/recommendations | The strongly-recommend list, including abstract repositories — 01 diverges from it deliberately and cites this to say so. |
| Case study (Compass App) | https://docs.flutter.dev/app-architecture/case-study | The hybrid folder layout behind 01 §2's tree. |
| Case study — dependency injection | https://docs.flutter.dev/app-architecture/case-study/dependency-injection | DI without global objects; 02's provider graph. |
| Design pattern — offline-first | https://docs.flutter.dev/app-architecture/design-patterns/offline-first | **The page this app must not follow** (01 §1.4). Cited as the rejected alternative and as the reason `connectivity_plus` / `workmanager` are banned. |
| Design pattern — result | https://docs.flutter.dev/app-architecture/design-patterns/result | The `Result` pattern; 01 scopes it to writes only and cites this for the shape. |
| Design pattern — command | https://docs.flutter.dev/app-architecture/design-patterns/command | *"can't be launched again until it finishes"* — the guarantee behind 01 §4's write guard and 02 §7's `WriteController`. |

## 2. Flutter — official documentation: guides, testing, deployment, performance

| Source | URL | Load-bearing for |
|---|---|---|
| Handling errors in Flutter | https://docs.flutter.dev/testing/errors | The three error hooks and the `exit(1)` option the app declines — 01 §5, 13 §8. |
| Hot reload | https://docs.flutter.dev/tools/hot-reload | The documented limitation list; 01 §8 notes package boundaries are absent from it. |
| Performance best practices | https://docs.flutter.dev/perf/best-practices | `saveLayer` cost, `const`, lazy builders, do not override `==` on widgets — 02 §9, 06 §7. |
| Measuring your app's size | https://docs.flutter.dev/perf/app-size | `--analyze-size`; 13 §6's size budget and the `drift_dev` tree-shake check 03 §1.4 asks for. |
| Build modes | https://docs.flutter.dev/testing/build-modes | Profile mode is disabled on emulators — 13 §6, decision #126's "two real devices". |
| Testing plugins in tests | https://docs.flutter.dev/testing/plugins-in-tests | *"wrap the plugin in your own API"* ranked first — the justification for 12's six/seven gateway fakes. |
| Integration testing | https://docs.flutter.dev/testing/integration-tests | 12's four integration journeys (decision #117), reported not blocking. |
| Internationalization | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization | gen-l10n, ARB placeholders inside plural variants — 05 §8, 10 §8. |
| Build and release an Android app | https://docs.flutter.dev/deployment/android | `INTERNET` lives in `src/debug` and `src/profile`, not `main` — 11 §2, 13 §2.2, the whole offline-permission argument. |
| Build and release an iOS app | https://docs.flutter.dev/deployment/ios | 13 §9 signing and archive. |
| Flavors | https://docs.flutter.dev/deployment/flavors | Cited as the thing decision #87 rejects — one binary, no flavors (13 §9). |
| What's new in Flutter 3.44 (blog) | https://blog.flutter.dev/whats-new-in-flutter-3-44-b0cc1ad3c527 | Swift Package Manager is the default for iOS/macOS — 11 §9.3 and 13 §5's privacy-manifest packaging warning. |
| Flutter 3.44.0 release notes | https://docs.flutter.dev/release/release-notes/release-notes-3.44.0 | Android `libapp.so` symbol-stripping default (13 §6); the new accessibility evaluations (10 §5.3 — see §22 B2). |

## 3. Flutter — breaking changes

Each of these changed something the doc set would otherwise have got wrong.

| Source | URL | Load-bearing for |
|---|---|---|
| Material color utilities update | https://docs.flutter.dev/release/breaking-changes/material-color-utilities | 06 §3's token layer and why the palettes are hand-authored rather than seeded. |
| `FontWeight` drives the `wght` axis | https://docs.flutter.dev/release/breaking-changes/font-weight-variation | 06 §5's variable-font type scale. |
| SnackBar with action no longer auto-dismisses | https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update | 06 §2's `snackBarTheme` and 07's undo affordances. |
| Splash screen migration | https://docs.flutter.dev/release/breaking-changes/splash-screen-migration | 06 §9's no-white-flash recipe. |
| Android 14 non-linear text scaling | https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration | 06 §5 and 10 §4 — why `TextScaler`, never a factor. |
| `textScaleFactor` deprecation | https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor | Same; 12's 252-cell overflow matrix pumps `TextScaler`. |
| `header` / `headingLevel` behaviour change | https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level | 10 §3 and 07's DoD: `headingLevel:` everywhere, `Semantics(header: true)` nowhere. |
| `containsSemantics` → `isSemantics` | https://docs.flutter.dev/release/breaking-changes/deprecate-contains-semantics | 12's semantic assertions. |
| Semantics order of overlay entries in modal routes | https://docs.flutter.dev/release/breaking-changes/modal-router-semantics-order | 10 §6's traversal order. |
| Localized messages generated into source | https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source | 10 §8 — the `synthetic-package` flag is dead (decision #108). |
| UIScene delegate adoption | https://docs.flutter.dev/release/breaking-changes/uiscenedelegate | 06 §9's iOS `Info.plist` keys and 13 §5. |
| Android predictive back | https://docs.flutter.dev/release/breaking-changes/android-predictive-back | `canPop` decided ahead of time — 02 §8.3's single `canPop: false`. |

## 4. Flutter and Dart API reference

| Symbol | URL | Load-bearing for |
|---|---|---|
| `runApp` | https://api.flutter.dev/flutter/widgets/runApp.html | `runApp` initialises the binding itself — 01 §6's ~20-line `main()`. |
| `AppLifecycleState` | https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html | `hidden` is synthesised on both platforms and is the last guaranteed state — 02's lifecycle handler, 13 §7's clean-pause marker. |
| `RestorationMixin` · `Navigator.restorablePush` | https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html · https://api.flutter.dev/flutter/widgets/Navigator/restorablePush.html | What state restoration would have cost — 02's "why there is no restoration". |
| `RestorationManager` | https://api.flutter.dev/flutter/services/RestorationManager-class.html | The iOS `FlutterViewController` restoration-ID requirement this app does not pay. |
| `FlutterError.onError` | https://api.flutter.dev/flutter/foundation/FlutterError/onError.html | 01 §5 and 13 §8's global error net. |
| `PlatformDispatcher.onError` | https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html | The second hook; why no `runZonedGuarded`. |
| `ThemeExtension` | https://api.flutter.dev/flutter/material/ThemeExtension-class.html | 06 §3's two-tier tokens and `lerp(covariant …)`. |
| `MaterialTapTargetSize` | https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html | 06 §6's 72/88 pt targets above the Material default. |
| `HapticFeedback` | https://api.flutter.dev/flutter/services/HapticFeedback-class.html | 06 §10's haptic vocabulary. **See §22 E1 — the doc page and the SDK disagree, and three documents still carry the stale doubt.** |
| `MediaQueryData` | https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html | 06 §7 and 10 §4 — `disableAnimationsOf`, `withNoTextScaling`, `withClampedTextScaling`. |
| `MediaQueryData.textScaler` · `MediaQuery.textScalerOf` | https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html · https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html | The overflow matrix's pump axis (12 §5). |
| `TextScaler` | https://api.flutter.dev/flutter/painting/TextScaler-class.html | `TextScaler.clamp` — 06 §5's cap. |
| `MediaQueryData.lineHeightScaleFactorOverride` | https://api.flutter.dev/flutter/widgets/MediaQueryData/lineHeightScaleFactorOverride.html | 10 §4. |
| `MediaQueryData.supportsAnnounce` | https://api.flutter.dev/flutter/widgets/MediaQueryData/supportsAnnounce.html | 10 §5's live-region strategy on Android 16. |
| `FontFeature` | https://api.flutter.dev/flutter/dart-ui/FontFeature-class.html | `tabularFigures` and `slashedZero` — 06 §5 and the Inter fallback. |
| `ColorFilter.matrix` | https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html | 06's grayscale check for the differentiate-without-colour criterion. |
| `AccessibilityFeatures` | https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html | 10 §2's feature bitfield. |
| `SemanticsRole` | https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html | 10 §3. |
| `Semantics` | https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html | 10 §3; `onTap`, `onTapHint`, `headingLevel`. |
| `SemanticsProperties.liveRegion` | https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html | 10 §5's live regions, the replacement for deprecated announcements. |
| `SemanticsService.sendAnnouncement` | https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html | The deprecated path, cited to explain why it is not used. |
| `SpellOutStringAttribute` | https://api.flutter.dev/flutter/dart-ui/SpellOutStringAttribute-class.html | 10 §3 — reading a tag number digit by digit. |
| `CustomPainter.semanticsBuilder` · `CustomPainterSemantics` | https://api.flutter.dev/flutter/rendering/CustomPainter/semanticsBuilder.html · https://api.flutter.dev/flutter/rendering/CustomPainterSemantics-class.html | The hand-rolled chart's text alternative (10 §6, Apple's VoiceOver criterion). |
| `OrdinalSortKey` | https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html | 10 §6's traversal order. |
| `basicLocaleListResolution` | https://api.flutter.dev/flutter/widgets/basicLocaleListResolution.html | `languageLocales[code] ??= locale`, first wins — why `Locale('en')` is listed before `en_GB` (decision #108). |
| `MaterialLocalizations.firstDayOfWeekIndex` | https://api.flutter.dev/flutter/material/MaterialLocalizations/firstDayOfWeekIndex.html | Week starts Monday under `en_GB` (10 §8). |
| `flutter_test` library index | https://api.flutter.dev/flutter/flutter_test/ | 12 §2, including `flutter_test_config.dart`. |
| `AutomatedTestWidgetsFlutterBinding` | https://api.flutter.dev/flutter/flutter_test/AutomatedTestWidgetsFlutterBinding-class.html | The advancing fake clock — 12 §4's time-in-tests rules. |
| `TestFlutterView` | https://api.flutter.dev/flutter/flutter_test/TestFlutterView-class.html | `physicalSize`, `devicePixelRatio`, `reset` — 12's overflow matrix harness. |
| `WidgetController.ensureSemantics` | https://api.flutter.dev/flutter/flutter_test/WidgetController/ensureSemantics.html | Required before any tap-target run (07 DoD, 12 §7). |
| `meetsGuideline` | https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html | 12 §7's a11y gate. |
| `AccessibilityGuideline` · `SemanticsController` | https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html · https://api.flutter.dev/flutter/flutter_test/SemanticsController-class.html | 10 §7 and 12 §7. |
| `MinimumTapTargetGuideline` | https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html | `({size, link})` — the base for 06 §6.3's `shedTapTargetGuideline`. |
| `MinimumTextContrastGuideline` | https://api.flutter.dev/flutter/flutter_test/MinimumTextContrastGuideline-class.html | 12 §7; complements 06 §3.5's own contrast test. |
| `matchesGoldenFile` | https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html | 12 §8's golden policy. |
| `LocalFileComparator` | https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html | Pixel-exact, no tolerance — why 12 §8.3 installs a tolerant comparator. **See §22 D4.** |
| `FontLoader` | https://api.flutter.dev/flutter/services/FontLoader-class.html | Loading the real face into golden tests (12 §8). |
| `DateTime` | https://api.dart.dev/stable/dart-core/DateTime-class.html | *"the difference between two midnights in local time may be less than 24 hours…"* — 05 §2 and 12's DST cases. |
| `DateTime.add` | https://api.dart.dev/stable/dart-core/DateTime/add.html | *"If the resulting DateTime has a different daylight saving offset…"* — the strongest single citation behind 05's absolute-time model. |

## 5. Flutter and Dart source read directly

Where a doc page was insufficient or absent, the source was read. These reads outrank the corresponding doc pages.

| Source | URL / path | Load-bearing for |
|---|---|---|
| `flutter_test/lib/src/accessibility.dart` | https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_test/lib/src/accessibility.dart | The four skip rules in the tap-target guideline — 12 §7. |
| `flutter_tools/.../commands/analyze.dart` | https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/analyze.dart | `flutter analyze` flags, read from source — 13 §3. |
| `flutter_tools/.../commands/test.dart` | https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/test.dart · https://raw.githubusercontent.com/flutter/flutter/stable/packages/flutter_tools/lib/src/commands/test.dart | `flutter test` flags — 12 §11 and 13 §4. **The `-P`/`--preset` question in §22 B14 was not closed by this read.** |
| `flutter_tools/lib/src/tracing.dart` | https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/tracing.dart | Startup trace keys — 13 §6's startup budget. |
| `flutter_lints/lib/flutter.yaml` | https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml | The ten rules, verbatim — 13 §3's lint block (decision #109). |
| Writing a golden-file test | https://github.com/flutter/flutter/blob/master/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md | Per-platform images and "slight differences" — 12 §8's tolerance policy. |
| Flutter engine `lib/ui/window.dart` | local 3.44 checkout | The `AccessibilityFeatures` bitfield — 10 §2. |
| `AccessibilityFeatures.swift` (iOS embedder) | local 3.44 checkout | Which iOS features reach Dart — 10 §2. |
| `AccessibilityBridge.java` (Android embedder) | local 3.44 checkout | `NO_ANNOUNCE` :517, `disableAnimations` :444–451, live region :1106 / :2025, `// NOT SUPPORTED` :2472–2483, `boldText` :3270 — 10 §2 and §5. |
| `widgets/text.dart` :716–750 | local 3.44 checkout | The bold-text merge — 10 §4 and the w700 cap. |
| `widgets/app.dart` :146–235, :356 | local 3.44 checkout | `basicLocaleListResolution` and the `en_US` default — 10 §8. |
| `flutter_localizations/pubspec.yaml` | local 3.44 checkout | The exact `intl` pin that forces `intl: any` (decision #108). |
| `flutter_tools/.../generate_localizations.dart` | local 3.44 checkout | `synthetic-package` help text: *"DEPRECATED. This flag cannot be enabled…"* |
| `flutter_tools/templates/app/ios.tmpl/Runner/Info.plist.tmpl` | local 3.44 checkout | The iOS UIScene keys quoted in 06 §9. |
| Riverpod 2.6.1 / 3.4.1 package sources | `~/.pub-cache/hosted/pub.dev/` | 02 §2.1's file-and-line table: `Ref` shape, `Ref.mounted`, `ProviderObserver`, `ProviderContainer.test`, `ProviderScope.retry`, the family bound, `UncontrolledProviderScope`. The authority for every 2.6.1 spelling in the set. |

## 6. Flutter and Dart issue tracker

| Issue | URL | Load-bearing for |
|---|---|---|
| flutter#94123 — zone/binding mismatch | https://github.com/flutter/flutter/issues/94123 | Why there is no `runZonedGuarded` (01 §5, 13 §8). |
| flutter#32736 · flutter#39494 — binding init tears the native splash down early | https://github.com/flutter/flutter/issues/32736 · https://github.com/flutter/flutter/issues/39494 | 06 §9's no-white-flash recipe and the order of operations in `main()`. |
| flutter#23957 — iOS container UUID is not stable across launches | https://github.com/flutter/flutter/issues/23957 | **Never persist absolute paths** — 03 §5, 04 §4 (relative-path rule), 08. |
| flutter#20789 — `INTERNET` lives in the debug/profile manifests | https://github.com/flutter/flutter/issues/20789 | 13 §2.2's G0 and the whole permission argument. |
| flutter#139712 (open) — Bold Text makes w800/w900 render *lighter* | https://github.com/flutter/flutter/issues/139712 | The w700 weight cap (`type.weight_cap`) — 06 §5, 07, 10, CODE-REVIEW-CHECKLIST §1.7. |
| flutter#177801 (open) — `boldText` ignores a custom `TextSpan` weight | tracked in 10 §4 | 10's bold-text handling. |
| flutter#10603 (closed) — iOS Smart Invert / `accessibilityIgnoresInvertColors` unexposed | tracked in 10 §2 | Why Smart Invert is a manual check, not a gate. |
| flutter#67814 · flutter#36307 — GridView traversal under TalkBack | tracked in 10 §6 | The keypad's traversal order. |
| flutter PR #178102 — three iOS motion features added in 3.44 | tracked in 10 §2 | Reduce-motion support. |
| flutter PR #183569 — non-text colour contrast (`kMinimumRatioNonText = 3.0`) | tracked in 10 §5.3 | **See §22 B2 — public or private is unresolved.** |
| flutter PR #182872 — `UnlabeledLeafNodeEvaluation` | tracked in 10 §5.3 | Same. |
| flutter#117683 (open since 2022-12-27) · flutter#174935 | https://github.com/flutter/flutter/issues/117683 · https://github.com/flutter/flutter/issues/174935 | go_router restoration defects — part of why `go_router` is rejected (02, decision-record §5.3). |
| flutter#172434 — StoreKit 2 purchases reported as `restored` and left unfinished | https://github.com/flutter/flutter/issues/172434 | The `in_app_purchase_storekit ≥ 0.4.8` floor and why 11 §6.3 handles `purchased` and `restored` identically. |
| flutter#36667 — goldens differ across Flutter versions | https://github.com/flutter/flutter/issues/36667 | 12 §8 — goldens are not a per-PR gate (decision #116). |
| dart-lang/build#3555 — build_runner's O(N²)-ish incremental model | https://github.com/dart-lang/build/issues/3555 | One generator is the budget (decision #16) — 01 §8, 03 §1. |

## 7. Dart language and tooling

| Source | URL | Load-bearing for |
|---|---|---|
| Extension types | https://dart.dev/language/extension-types | Zero cost, non-transparent, *"at run time there is absolutely no trace"* — 05 §1's `Instant` / `LocalDate` / gram types. |
| Class modifiers | https://dart.dev/language/class-modifiers | `sealed` exhaustiveness — 05's withdrawal target and `WriteOutcome` / `ShedFailure`. |
| Customizing static analysis | https://dart.dev/tools/analysis | `language:`, `errors:`, `formatter.page_width` — 13 §3's explicit strict block (decision #109). |
| Dart build hooks | https://dart.dev/tools/hooks | How `package:sqlite3` ships SQLite — 03 §1, 13 §1.3's honest network paragraph. |
| Pub workspaces | https://dart.dev/tools/pub/workspaces | Stable since 3.6.0 — 01 §8's "when this app earns a second package". **Glob support on this SDK is unverified: §22 B12.** |
| `package:test` configuration | https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md | `tags`, `presets`, `allow_test_randomization` — 12 §11.2's `dart_test.yaml`. **Fidelity under `flutter test` is unverified: §22 B14.** |
| `package:clock` README | https://github.com/dart-lang/clock | `clock.now()`, `Clock.fixed`, `withClock` — 05 §2's chokepoint, the mechanism that makes spec §12.5 testable. |
| pub.dev package API endpoint | https://pub.dev/api/packages/ | The only permitted source for a version number outside decision-record §5 — CODE-REVIEW-CHECKLIST §2.17's dependency audit. |

## 8. Riverpod

The codebase is written against 2.6.1, pinned exactly. Every URL below is cited for a 2.6.1 fact; 3.x pages are cited only to name what is banned.

| Source | URL | Load-bearing for |
|---|---|---|
| riverpod 2.6.1 API index | https://pub.dev/documentation/riverpod/2.6.1/ | The API surface the whole codebase is written against. |
| `FamilyAsyncNotifier` (2.6.1) | https://pub.dev/documentation/riverpod/2.6.1/riverpod/FamilyAsyncNotifier-class.html | The 2.6.1 family bound and `build(Arg)` signature — 02 §2. |
| `AutoDisposeFamilyNotifier` (2.6.1) | https://pub.dev/documentation/riverpod/2.6.1/riverpod/AutoDisposeFamilyNotifier-class.html | `build(Arg arg)` plus the `arg` getter. |
| `Provider` (2.6.1) | https://pub.dev/documentation/riverpod/2.6.1/riverpod/Provider-class.html | `overrideWithValue(State)` — 12's override harness. |
| `FutureProvider` (2.6.1) | https://pub.dev/documentation/riverpod/2.6.1/riverpod/FutureProvider-class.html | `overrideWith` and the `future` property. |
| `UncontrolledProviderScope` (flutter_riverpod 2.6.1) | https://pub.dev/documentation/flutter_riverpod/2.6.1/flutter_riverpod/UncontrolledProviderScope-class.html | `{required container, required child}` — the 2.6.1 replacement for `WidgetTester.container`. |
| `ProviderScope` (flutter_riverpod 2.6.1) | https://pub.dev/documentation/flutter_riverpod/2.6.1/flutter_riverpod/ProviderScope-class.html | The 2.6.1 constructor; **there is no `retry` parameter** — one of the banned Riverpod-3 APIs CI greps for (decision #18). |
| riverpod pub API | https://pub.dev/api/packages/riverpod | `test: ^1.0.0` in 3.4.1's *runtime* dependencies — the single fact that makes 3.x unusable alongside `drift_dev` (decision #2). |
| rrousselGit/riverpod#4791 | https://github.com/rrousselGit/riverpod/issues/4791 | The maintainer's WONTFIX on that runtime dependency. The reason the pin is permanent, not temporary. |
| Riverpod — what's new | https://riverpod.dev/docs/whats_new | Constructor-delivered notifier arguments and provider auto-retry — both 3.x-only, both on 02 §2's ban list. |
| Riverpod 3.0.0 changelog (2025-04-30) | linked from the package changelog | *"It is quite possible that a 4.0.0 will be released relatively soon."* A signal, **not a date** — see §22 A6. |

## 9. drift

| Source | URL | Load-bearing for |
|---|---|---|
| Setup / `driftDatabase` / `DriftNativeOptions` | https://drift.simonbinder.eu/setup/ | 03 §1's connection; the override from Documents to Application Support. |
| Streams | https://drift.simonbinder.eu/dart_api/streams/ | Table tracking and `readsFrom:` — 01, 02, 07's one-query-per-screen rule. |
| Transactions | https://drift.simonbinder.eu/dart_api/transactions/ | All statements must be awaited; streams see updates only after commit — 01 §4's write path. |
| Views | https://drift.simonbinder.eu/docs/dart-api/views/ | View registration; view expression getters are always nullable — 03 §8. |
| Tables / `@DataClassName` | https://drift.simonbinder.eu/docs/dart-api/tables/ | drift strips one trailing `s`, which is why `PenOccupancies` and `EweTouches` must be annotated (03 §2.3). |
| Generation options | https://drift.simonbinder.eu/generation_options/ | `override_hash_and_equals_in_result_sets` — 03's `build.yaml`. |
| DateTime migration guide | https://drift.simonbinder.eu/guides/datetime-migrations/ | The two storage modes and *"drift always returns a non-UTC value"* — 03 §1 and 05 §2's `dateTime()` ban. |
| Migrations / `stepByStep` / `make-migrations` / `TableMigration` | https://drift.simonbinder.eu/migrations/ | 04 §2–§3, the whole forward-only migration policy. |
| Step-by-step migrations | https://drift.simonbinder.eu/migrations/step_by_step/ | 04 §3, 12 §3. |
| Migration tests | https://drift.simonbinder.eu/migrations/tests/ | 12 §3's from→to matrix. |
| Schema exports | https://drift.simonbinder.eu/migrations/exports/ | The committed `drift_schemas/` JSON and the no-diff CI check (decision #38). |
| Runtime schema inspection | https://drift.simonbinder.eu/docs/advanced-features/schema_inspection/ | `validateDatabaseSchema` — 03 §1.4, 04 §3. |
| Testing | https://drift.simonbinder.eu/testing/ | `NativeDatabase.memory()`, `closeStreamsSynchronously` — 12 §3. |
| Supported platforms | https://drift.simonbinder.eu/platforms/ | `flutter test` runs against the *host* sqlite3 — 12 §3.2's version floor. **See §22 D3.** |
| `SchemaVerifier` API | https://pub.dev/documentation/drift_dev/latest/api_migrations_native/SchemaVerifier-class.html | 04 §3, 12 §3. **Tolerance of FTS5 shadow tables is unverified: §22 D1.** |
| `VerifySelf.validateDatabaseSchema` | https://pub.dev/documentation/drift_dev/latest/api_migrations_native/VerifySelf.html | An extension member — cited so nobody looks for it on the class. |
| drift#3338 (open) — two streams in one transaction emit at different times | https://github.com/simolus3/drift/issues/3338 | **The reason `combineLatest` is banned** and every screen has one content statement — 01, 02, 03, 07, CODE-REVIEW-CHECKLIST. Maintainer: *"generally is working as intended"*. |
| drift#3295 (open) — streams re-run on any write to a tracked table | https://github.com/simolus3/drift/issues/3295 | The reason for `.distinct()` in the repository. |
| drift#3531 — wrap bulk inserts in one transaction | https://github.com/simolus3/drift/issues/3531 | 03's seed and 04's restore path. |
| drift#3322 (open) — FTS5 special INSERT commands in the analyser | https://github.com/simolus3/drift/issues/3322 | 03 §9.2's fallbacks A and B. **Unresolved: §22 D2.** |
| drift discussion #2670 — `build.yaml` naming footgun | https://github.com/simolus3/drift/discussions/2670 | `build.yaml`, never `build.yml` — 03 DoD. |
| `package:sqlite3` build hooks doc | https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md | How the binary is fetched and sha256-verified — 13 §1.3's cold-cache paragraph. |
| prisma#8106 · rails#52354 — FTS5 shadow tables break schema diffing elsewhere | https://github.com/prisma/prisma/issues/8106 · https://github.com/rails/rails/pull/52354 | The *precedent* for §22 D1. Other ecosystems have choked on exactly these tables. |

## 10. SQLite

| Source | URL | Load-bearing for |
|---|---|---|
| STRICT tables | https://sqlite.org/stricttables.html | Every table declares `isStrict` — 03's DoD, 12 §3.2's version floor. |
| Foreign key support | https://www.sqlite.org/foreignkeys.html | No automatic child index; enforcement off by default — 03 §5 and `every_fk_is_indexed_test.dart`. |
| FTS5 | https://sqlite.org/fts5.html · https://www.sqlite.org/fts5.html | External content tables, the trigram tokenizer limit, and *"substrings of fewer than 3 unicode characters do not match"* — 03 §9, 07's note search, and the reason `rankTagMatches` is Dart, not SQL. |
| Write-Ahead Logging | https://sqlite.org/wal.html · https://www.sqlite.org/wal.html | 03 §1's pragmas, 04 §8's snapshot rules. |
| `PRAGMA` reference | https://www.sqlite.org/pragma.html · https://sqlite.org/pragma.html#pragma_synchronous | `synchronous`, `foreign_keys`, `defer_foreign_keys`, `journal_size_limit`, `temp_store`, `wal_checkpoint`, `quick_check`, `foreign_key_check`, `recursive_triggers` — 03 §1 and 04 §5. |
| Result codes | https://www.sqlite.org/rescode.html | `SQLITE_FULL`, `SQLITE_CORRUPT`, `SQLITE_NOTADB` — the primary codes `shedFailureFrom` maps in 01 §5. |
| `VACUUM` / `VACUUM INTO` | https://sqlite.org/lang_vacuum.html | Decision #84 — a diagnostics snapshot, explicitly **not** a backup (04 §8). |
| `ALTER TABLE` and the 12-step rebuild | https://sqlite.org/lang_altertable.html | 04 §2's forward-only migration rules. |
| Generated columns | https://www.sqlite.org/gencol.html | Restriction 7 — a `STORED` column cannot be added by `ALTER TABLE` (01, 03). |
| Views are read-only | https://www.sqlite.org/lang_createview.html | 03 §8's derived-state rules. |
| `SELECT` | https://www.sqlite.org/lang_select.html | `ORDER BY`/`LIMIT` apply to the compound SELECT as a whole — why each deck bucket in 07 is a CTE. |
| The LIKE optimisation | https://sqlite.org/optoverview.html#the_like_optimization | Why `LIKE '%12%'` cannot use an index — decision #35's justification for the Dart-side tag matcher. |
| How To Corrupt An SQLite Database File | https://www.sqlite.org/howtocorrupt.html | 03 §1 and 04 §5–§8: what the restore path must never do. |
| 35% Faster Than The Filesystem | https://www.sqlite.org/fasterthanfs.html | The blob-vs-file crossover behind 04 §4's media-on-disk decision. |

## 11. Package documentation — pub.dev

Cited as documentation of behaviour. **Versions come from decision-record §5, never from these pages.**

### 11.1 Adopted

| Package | URL | Load-bearing for |
|---|---|---|
| `drift` | https://pub.dev/packages/drift | The persistence layer (03, 04, 12). |
| `sqlite3` | https://pub.dev/packages/sqlite3 | The bundled engine; guarantees FTS5 + STRICT on every device. **Online-backup API on `CommonDatabase` unverified: §22 B1.** |
| `path_provider` | https://pub.dev/packages/path_provider | DB, media and temp paths (03, 04). Apple privacy-manifest SDK. |
| `uuid` | https://pub.dev/packages/uuid | RFC 9562 v7 ids; the monotonic prefix keeps the uid index appending (03 §2). |
| `share_plus` | https://pub.dev/packages/share_plus | The only export/backup channel (spec §7.9) — 04 §7, 08 §6, 09 §8. **`ShareResultStatus` unverified: §22 B3.** |
| `file_selector` | https://pub.dev/packages/file_selector | Backup import with no storage permission — 04 §7, 08 §7. |
| `clock` | https://pub.dev/packages/clock | 05 §2, 12 §4. |
| `flutter_local_notifications` · changelog | https://pub.dev/packages/flutter_local_notifications · https://pub.dev/packages/flutter_local_notifications/changelog | The only reminder mechanism (08 §2). Heavy breaking-change history is why 08 reads the source, not the docs. |
| `AndroidScheduleMode` | https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/AndroidScheduleMode.html | Exact vs inexact delivery — 08 §2.9's "approximate" chip. |
| `timezone` | https://pub.dev/packages/timezone | Forced by `zonedSchedule`; confined to that seam by R48 (08 §2). |
| `wakelock_plus` | https://pub.dev/packages/wakelock_plus | Per-screen, default off — 08 §8. |
| `image_picker` | https://pub.dev/packages/image_picker | System photo picker / system camera; merges zero Android permissions — 08 §4. |
| `flutter_image_compress` | https://pub.dev/packages/flutter_image_compress | Native downscale at capture; `keepExif` defaults false — 04 §4. **`minWidth`/`minHeight` semantics unverified: §22 B5.** |
| `record` · `AudioEncoder` | https://pub.dev/packages/record · https://pub.dev/documentation/record/latest/record/AudioEncoder.html | Voice notes; Opus containers differ per platform, which is why `aacLc`/`.m4a` is mandatory (08 §5). |
| `pdf` | https://pub.dev/packages/pdf | Flock book and medicine record (09 §4). **Four behaviours unverified: §22 B8–B11.** |
| `archive` | https://pub.dev/packages/archive | ZIP backup (04 §7, 09 §5). **`ZipFileEncoder` streaming unverified: §22 A3.** |
| `in_app_purchase` API reference | https://pub.dev/documentation/in_app_purchase/latest/in_app_purchase/InAppPurchase-class.html | The seven members 11 §6 uses. |
| `device_info_plus` | tracked in decision-record §5.1 | Model + OS version in the diagnostics header (13 §8). |
| `logging` | tracked in decision-record §5.1 | Named loggers wired to a local rolling file (13 §8). |
| `flutter_lints` | https://pub.dev/packages/flutter_lints | The baseline lint set (13 §3). |
| `mocktail` | https://pub.dev/packages/mocktail | Interaction-ordering assertions only (12 §2). |
| ~~`glados`~~ | https://pub.dev/packages/glados | **Struck 2026-08-01.** Does not resolve against `drift_dev` 2.34.5 at any version — it depends on `package:test`, which decision #4 already bans for the same reason. Not a dependency of this project. **§22 D5 is closed.** |
| `golden_screenshot` | https://pub.dev/packages/golden_screenshot | Store screenshots; belongs in `tool/`, not `test/` (12 §8). |
| `accessibility_tools` | https://pub.dev/packages/accessibility_tools | Debug-only checker; its 48×48 default is *below* this app's floor, so it complements and never replaces the house assertion (10 §7, 12 §7). |

### 11.2 Rejected — cited for the reason

| Package | URL | Why it is in the bibliography |
|---|---|---|
| `csv` | https://pub.dev/packages/csv | Rejected (decision #82): unverified uploader + fresh breaking rewrite, for ~50 lines of RFC 4180 you need byte control over (09 §2). |
| `printing` | https://pub.dev/packages/printing | Rejected (decision #83): `http` dependency; `PdfGoogleFonts`/`networkImage` are one-line footguns (09 §4). |
| `camera` | https://pub.dev/packages/camera | Rejected: merges `CAMERA` + `RECORD_AUDIO` (08 §4). |
| `file_picker` | https://pub.dev/packages/file_picker | Rejected: heavier transitive deps; cloud-picking undercuts the positioning (08 §7). |
| `permission_handler` | https://pub.dev/packages/permission_handler | Rejected: the CocoaPods `PERMISSION_*` macro block is an App Store rejection risk (08 §9). |
| `speech_to_text` | https://pub.dev/packages/speech_to_text | Rejected: `onDevice` defaults false and silently falls back to network recognition — the reason voice tag entry is cut (08 §10, owner ruling §7.0). |
| `google_mlkit_text_recognition` | https://pub.dev/packages/google_mlkit_text_recognition | Rejected: Play Services contribute INTERNET/ACCESS_NETWORK_STATE — the reason OCR is cut (08 §10). |
| `open_filex` | https://pub.dev/packages/open_filex | Rejected: the share sheet already offers "Open in…". |
| `very_good_analysis` | https://pub.dev/packages/very_good_analysis | The documented alternative to `flutter_lints` + a strict block (13 §3). |
| `golden_toolkit` | https://pub.dev/packages/golden_toolkit | Rejected: `isDiscontinued: true` (12 §8). |
| `alchemist` · changelog | https://pub.dev/packages/alchemist · https://pub.dev/packages/alchemist/changelog | Rejected: CI text-blocking replaces text with coloured squares, destroying the legibility property the goldens exist to prove (12 §8). |
| `patrol` · docs | https://pub.dev/packages/patrol · https://patrol.leancode.co/documentation | Rejected for v1: `flutter test` will not run its tests (12 §9). |
| `sqlite3_test` | https://pub.dev/packages/sqlite3_test | Not used: SQL-side time is banned and it cannot support WAL (12 §3). |

## 12. Package sources and Android manifests read directly

The permission argument in `08-platform-integration.md` §9 and `11-monetization-and-store.md` §2 is built on these, not on README claims.

| Source | URL | Load-bearing for |
|---|---|---|
| `flutter_local_notifications` Android manifest | https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/AndroidManifest.xml | Merges `VIBRATE` + `POST_NOTIFICATIONS` and nothing else — you add `RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM` yourself. |
| `flutter_local_notifications` Dart API source | https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/lib/src/flutter_local_notifications_plugin.dart | The v22 named-parameter surface. |
| `FlutterLocalNotificationsPlugin.java` | https://raw.githubusercontent.com/MaikuB/flutter_local_notifications/master/flutter_local_notifications/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java | `checkCanScheduleExactAlarms` — 08 §2.9's permission flow. |
| `image_picker_android` manifest | https://raw.githubusercontent.com/flutter/packages/main/packages/image_picker/image_picker_android/android/src/main/AndroidManifest.xml | Zero permissions merged. |
| `record_android` manifest | https://raw.githubusercontent.com/llfbandit/record/master/record_android/android/src/main/AndroidManifest.xml | `RECORD_AUDIO` only. |
| `share_plus` Android manifest | https://raw.githubusercontent.com/fluttercommunity/plus_plugins/main/packages/share_plus/share_plus/android/src/main/AndroidManifest.xml | No permissions merged. |
| `in_app_purchase_android` manifest | https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/src/main/AndroidManifest.xml | Empty — which is why the billing permission question moves to the AAR (§22 A2). |
| `in_app_purchase_android` `build.gradle.kts` | https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/build.gradle.kts | `com.android.billingclient:billing:8.0.0` — the version whose manifest could not be read. |
| MaikuB/flutter_local_notifications#2312 (closed `not planned`) | https://github.com/MaikuB/flutter_local_notifications/issues/2312 | A third, conflicting description of the iOS over-64 behaviour — see §22 F1. |
| dart_pdf Fonts Management wiki | https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management | Base-14 fonts are Latin-1 — always embed a TTF (09 §4.2). |
| dart_pdf #810 · #252 · #405 | https://github.com/DavBfr/dart_pdf/issues/810 · https://github.com/DavBfr/dart_pdf/issues/252 · https://github.com/DavBfr/dart_pdf/issues/405 | The evidence that base-14 fonts *throw* on curly quotes and ellipses — `export.base_14_font` exists because of these. |

## 13. Apple

| Source | URL | Load-bearing for |
|---|---|---|
| About the app launch sequence | https://developer.apple.com/documentation/uikit/about-the-app-launch-sequence | Suspended apps stay in memory; termination under memory pressure — 02's no-restoration argument. |
| File System Programming Guide | https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html | Application Support is backed up; file-reference URLs are not safe to persist — 04 §4. |
| UI design tips | https://developer.apple.com/design/tips/ | 44×44 pt targets, 11 pt minimum text — 06 §6, 10 §4. The app exceeds both. |
| App Store Review Guidelines | https://developer.apple.com/app-store/review/guidelines/ | 2.5.9 (volume switches — 06's gesture ban), 3.1.1 (restore mechanism), 4.2, 4.3(a), 4.8, 5.1.1(i), 5.1.1(v) — 11 §6, §9; 13 §10. |
| App privacy details on the App Store | https://developer.apple.com/app-store/app-privacy-details/ | The definition of "collect" (= transmitting off device) — the basis of the genuine "Data Not Collected" in 11 §9.1. |
| Describing use of required reason API | https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons | The reason-code table — `C617.1`, and the conditional `E174.1` (11 §9.2, 04 §8). |
| Adding a privacy manifest | https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk | `PrivacyInfo.xcprivacy` — 11 §9.2, 13 §5. |
| Upcoming third-party SDK requirements | https://developer.apple.com/support/third-party-SDK-requirements/ | Which plugins must ship their own manifest — 08, 11 §9.3. **Coverage unverified: §22 D8.** |
| `Transaction.currentEntitlements` | https://developer.apple.com/documentation/storekit/transaction/currententitlements | A local cache that the network populates — 11 §5's no-signal case. |
| Developer Forums thread 706450 | https://developer.apple.com/forums/thread/706450 | DTS: *"To get the latest transactions the device will need internet access…"* and the new-device-with-no-signal case — 11 §5. |
| Developer Forums thread 811171 | https://developer.apple.com/forums/thread/811171 | The **64 pending-notification-request limit per app** — the origin of 08's 56-slot budget and 07's reconciliation copy. |
| Testing at all stages with Xcode and the sandbox | https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox | The `.storekit` file, sandbox, TestFlight — 11 §11, 13 §10. |
| App Store Small Business Program | https://developer.apple.com/app-store/small-business-program/ | 15%, under $1M, effective 15 days after the fiscal month of approval — enrol **before the first sale** (11 §10). |
| Xcode 26 / iOS 26 SDK upload requirement (28 Apr 2026) | https://developer.apple.com/news/upcoming-requirements/?id=02032026a | 13 §1's toolchain calendar. |
| Reducing your app's launch time | https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time | The 400 ms goal in 13 §6. **The direct fetch returned no body — this citation is second-hand: §22 A4.** |
| Accessibility Nutrition Labels — overview | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/ | The ship gate 10 is written against. |
| VoiceOver evaluation criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria/ | Charts need a text alternative; no control types in labels — 10 §3, §6. |
| Voice Control evaluation criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria/ | Labels must match visible text — 10 §3. |
| Larger Text evaluation criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/ | 200% or the system maximum; test at AX3 and AX5 — 12's overflow matrix. |
| Differentiate Without Color Alone criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria/ | The grayscale test — every pen status carries colour **and** shape **and** text (07 DoD). |
| Sufficient Contrast criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria/ | 06 §3.5's contrast test. |
| Reduced Motion criteria | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/ | 10 §2's motion handling. |

## 14. Google / Android / Play

| Source | URL | Load-bearing for |
|---|---|---|
| Process lifecycle | https://developer.android.com/guide/components/activities/process-lifecycle | Cached processes are killed freely; `onDestroy()` is not guaranteed — 02's lifecycle handler, 13 §7's clean-pause marker. |
| Merge multiple manifest files | https://developer.android.com/build/manage-manifests | Merge priority and `tools:node="remove"` / `tools:selector` — the mechanism the whole offline permission claim rests on (08, 11 §2, 13 §2.2). |
| Android Auto Backup | https://developer.android.com/identity/data/autobackup | The 25 MB cap, what is included, `data_extraction_rules` — 04 §9. **D2D behaviour unverified: §22 C7.** |
| App-specific storage | https://developer.android.com/training/data-storage/app-specific | Cache volatility — 04 §4's media layout. |
| The system photo picker | https://developer.android.com/training/data-storage/shared/photopicker | Why `image_picker` needs no permission (08 §4). |
| Notification channels | https://developer.android.com/develop/ui/views/notifications/channels | The eight frozen channel ids (R49, 08 §2.7, 13 §11.2). |
| Scheduling alarms | https://developer.android.com/develop/background-work/services/alarms/schedule | Inexact delivery windows — 08 §2.9. |
| Android 14 — `SCHEDULE_EXACT_ALARM` denied by default | https://developer.android.com/about/versions/14/changes/schedule-exact-alarms | 08 §2.9's permission flow and the "approximate" disclosure. |
| Android 14 behaviour changes | https://developer.android.com/about/versions/14/behavior-changes-14 | `USE_FULL_SCREEN_INTENT` — cited as a thing this app does not use. |
| Android 14 features | https://developer.android.com/about/versions/14/features | 200% non-linear font scaling — 10 §4. |
| Android 16 behaviour changes | https://developer.android.com/about/versions/16/behavior-changes-all | Announcements deprecated; `setAccessibilityLiveRegion` recommended — 06, 10 §5. |
| Android 12+ splash screen | https://developer.android.com/develop/ui/views/launch/splash-screen | 06 §9's dark launch. |
| Android dark theme | https://developer.android.com/develop/ui/views/theming/darktheme | 06 §9. |
| App accessibility guide | https://developer.android.com/guide/topics/ui/accessibility/apps | 48 dp targets, 8 dp separation, 4.5:1 below 18 sp — 06 §6, 10 §4. |
| Accessibility help — target size | https://support.google.com/accessibility/android/answer/7101858 | 48×48 dp separated by 8 dp; 48 dp ≈ 9 mm — the mm figure 06 §6 reasons in. |
| App startup time / Android vitals | https://developer.android.com/topic/performance/vitals/launch-time | 13 §6's startup thresholds. |
| Integrate Google Play's billing system | https://developer.android.com/google/play/billing/integrate | The three-day acknowledgement window and the network-loss case — 11 §6, 13 §10. |
| Handle BillingResult response codes | https://developer.android.com/google/play/billing/errors | `SERVICE_UNAVAILABLE`, `BILLING_UNAVAILABLE` — 11 §6.2. |
| Play Billing Library deprecation FAQ | https://developer.android.com/google/play/billing/deprecation-faq | PBL 8 by 31 Aug 2026, PBL 9 by 31 Aug 2027 — the only hard external deadline in the project (11 §10, 13 §11). |
| Test your Play Billing integration | https://developer.android.com/google/play/billing/test | License testers — 11 §11. |
| Target API level requirements (developer.android.com) | https://developer.android.com/google/play/requirements/target-sdk | API 36 from 31 Aug 2026 — 08, 13 §1. |
| Target API level requirements (Play Console Help) | https://support.google.com/googleplay/android-developer/answer/11926878 | Same requirement, the policy-side statement. |
| `USE_EXACT_ALARM` is restricted | https://support.google.com/googleplay/android-developer/answer/9888170 | Restricted to alarm/timer and calendar apps — the reason this app uses `SCHEDULE_EXACT_ALARM` and degrades gracefully (08 §2.9). |
| Data safety section | https://support.google.com/googleplay/android-developer/answer/10787469 | The ephemeral, on-device and payment-service exemptions — 11 §9.4. |
| App account deletion requirements | https://support.google.com/googleplay/android-developer/answer/13327111 | Conditioned on account creation — why 11 §9.5 needs nothing. |
| Use Play App Signing | https://support.google.com/googleplay/android-developer/answer/9842756 | 13 §9. |
| App testing requirements for new personal developer accounts | https://support.google.com/googleplay/android-developer/answer/14151465 | 12 testers / 14 days — on the critical path if the account is post-13-Nov-2023 (13 §10, decision-record §7.1 #14). |
| Expanded billing choice and lower fees on Google Play (30 Jun 2026) | https://android-developers.googleblog.com/2026/06/play-expanded-billing.html | The service-fee / billing-fee split. **The one-time-product rate is not stated here — see §22 A7.** |
| Archived Google IAB v3 integration guide | https://stuff.mit.edu/afs/sipb/project/android/docs/google/play/billing/billing_integrate.html | Architectural evidence that in-app billing is IPC through the Play Store app, which is why `com.android.vending.BILLING` exists — 11 §2. |
| Mirrored Play Billing AAR manifest, **billing 2.0.3** | https://github.com/dandar3/android-google-play-billing/blob/master/AndroidManifest.xml | Architectural evidence only, six majors behind. **The 8.0.0 manifest could not be fetched from a primary source: §22 A2.** |

## 15. Accessibility standards and legislation

| Source | URL | Load-bearing for |
|---|---|---|
| WCAG 2.2 quick reference | https://www.w3.org/WAI/WCAG22/quickref/ | 10's conformance frame. |
| WCAG2ICT (W3C Group Note, 11 Dec 2025) | https://www.w3.org/TR/wcag2ict/ | How WCAG applies to non-web software — 10 §1. |
| Understanding Contrast (Minimum), 1.4.3 | https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html | The 4.5:1 / 3:1 thresholds every palette in 06 §4 is measured against. |
| Understanding Use of Color, 1.4.1 | https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html | Colour is never the only carrier — 06, 07's pen statuses, 10. |
| Understanding Target Size (Minimum), 2.5.8 · (Enhanced) | https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html · https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html | The floors 06 §6 exceeds (72 / 88 pt against a 60 pt floor). |
| APCA in a Nutshell | https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell.html | WCAG 2.x overstates contrast near black — why 06 §4 does not treat a passing ratio on `#0B0D0E` as sufficient on its own. |
| European Accessibility Act — covered products | https://commission.europa.eu/strategy-and-policy/policies/justice-and-fundamental-rights/disability/union-equality-strategy-rights-persons-disabilities-2021-2030/european-accessibility-act_en | Whether this app is in scope — 10 §1. |

## 16. Fonts and licences

| Source | URL | Load-bearing for |
|---|---|---|
| Atkinson Hyperlegible Next (SIL OFL 1.1) | https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext | The bundled face — 06 §5, 09 §4.2's embedded TTF. **File size, `wght` range and figure features unverified: §22 C1.** |
| Braille Institute free font page | https://www.brailleinstitute.org/freefont/ | Provenance and licence statement for the same face. |
| Inter (SIL OFL 1.1) | https://github.com/rsms/inter | The documented fallback — `tnum` + `FontFeature.slashedZero()` if Atkinson's zero fails the head-torch test (06 §5.2). |

## 17. Format specifications

| Source | URL | Load-bearing for |
|---|---|---|
| RFC 4180 — CSV | https://www.rfc-editor.org/rfc/rfc4180 | The hand-rolled writer in 09 §2: CRLF, `""` escaping, the quoting predicate. Decision #82. |
| RFC 9562 — UUIDs (v7) | https://www.rfc-editor.org/rfc/rfc9562 | Every `uid` in the schema (03 §2) and every id in the backup envelope (09 §5). |

## 18. Agricultural, veterinary and husbandry sources

The only group in this bibliography where the sources disagree with each other, and where that disagreement is itself the finding: `05-domain-correctness.md` §6 exists because two published bodies define "lambing percentage" differently.

### 18.1 Medicine withdrawal periods — the highest-stakes citations in the set

| Source | URL | Load-bearing for |
|---|---|---|
| VICH, *Report on calculation of withdrawal periods* (Aug 2020) | https://vichsec.org/wp-content/uploads/2024/10/Report%20on%20calculation%20of%20withdrawal%20periods%20-final%20August%202020.pdf | The definition, and *"rounded up to the next full day or milking"* — 05 §3.5's `clearDateFor`. |
| EMA/CVMP/SWP/735418/2012 Rev. 1, *Guideline on determination of withdrawal periods for milk*, §4.1.1–§4.1.2 | https://www.ema.europa.eu/en/documents/scientific-guideline/adopted-guideline-determination-withdrawal-periods-milk-revision-1_en.pdf | *"milk from the first milking at or after 108 hours is considered safe"*; *"the final unit… should be real time"*. **The strongest citation for the absolute-time model** (05 §3.7) and for requiring a user-supplied milking interval (05 §3.2). |
| NADIS, *Cattle — Medicine Usage* | https://www.nadis.org.uk/disease-a-z/cattle/medicine-usage/ | The period runs from the **last** dose — 05 §3.10's repeat-treatment rule. |
| NADIS, *Sheep — Medicine Usage* | https://www.nadis.org.uk/disease-a-z/sheep/medicine-usage/ | *"can change for the same medicine and differ between products with the same active ingredient"* — **the basis for the no-learned-default rule**: the withdrawal control has no pre-filled number and no pre-selected option (05 §3.10, 07, 09, CODE-REVIEW-CHECKLIST §2.2). |
| Fimea, *What is a withdrawal period?* | https://fimea.fi/en/veterinary/withdrawal_period_and_mrl/what_is_a_withdrawal_period | A second regulator's plain-language definition, used as a cross-check. |

### 18.2 Flock statistics, lambing and fostering

| Source | URL | Load-bearing for |
|---|---|---|
| AHDB, *Reducing Lamb Losses for Better Returns* | https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf | The five KPI formulas (p.5), birthweight ranges (p.16), and the 50 ml/kg colostrum guidance the app holds every input for and **must never compute** (CODE-REVIEW-CHECKLIST §2.3). |
| AHDB, *Key performance indicators for the lamb sector* | https://ahdb.org.uk/key-performance-indicators-kpis-for-lamb-sector | The default percentage convention adopted for UK/Ireland (owner ruling §7.0 #3). |
| Penn State Extension, *Does Your Flock Meet Your Performance Expectations?* | https://extension.psu.edu/does-your-flock-meet-your-performance-expectations | Per-ewe-**exposed** as *"the more accurate method"* — 05 §6.2's alternative definition. |
| Sheep Ireland, *How to Record a Lambing Event* | https://www.sheep.ie/how-to-record-a-lambing-event/ | *"Number of Lambs born should include both alive and dead lambs"* — the convention that **conflicts** with AHDB, which is why the definition is user-configurable and `StatResult.definition` is printed verbatim on every export. |
| OMAFRA (Ontario), *Measuring sheep flock productivity* | https://www.ontario.ca/page/measuring-sheep-flock-productivity | *"lambs born ÷ ewes lambing × 100"*, explicitly including stillborn and mummified — the published counter-convention behind 05 §6.2's worked contrast. |
| Teagasc, *Lamb mortality — the main causes and timing* | https://www.teagasc.ie/news--events/daily/lamb-mortality-the-main-causes-and-timing/ | The day 1–3 / day 4–7 split, *"the first three days… account for 74% of lamb mortality"*, and *"diagnosis not reached"* at 19% — 05 §6.8's bucket boundaries. |
| Sheep Genetics (MLA), *Understanding Lambing Ease ASBVs* | https://www.sheepgenetics.org.au/globalassets/sheep-genetics/resources/lambing-ease-scoring-guideline.pdf | *"a blank score indicates the lambing ease was not scored"* — why blank and `unknown` are distinct everywhere in the schema and the CSV. |
| Huisman & Brown et al., *Effects of birth–rearing type*, Genet Sel Evol 2015 (PMC4489108) | https://pmc.ncbi.nlm.nih.gov/articles/PMC4489108/ | Birth type and rearing type are **distinct traits** — 03 §7's `lamb_rearing` and the foster conservation invariant. |
| NSIP, *Recording Orphan and Foster Lambs* | https://nsip.org/wp-content/uploads/2026/04/Recording-Orphan-and-Foster-Lambs-4-Aug-2020-RLB-Edits.pdf | The grafted lamb **keeps its birth type** — 03 §7, and why `UPDATE lambs SET birth_dam = …` throws. |
| Sheep Ireland, *Recording foster and pet lambs properly is crucial* | https://www.sheep.ie/recording-foster-and-pet-lambs-properly-is-crucial/ | Foster lambs are assigned to the genetic dam — the same invariant from a second body. |
| National Sheep Association, *Terms to know* | https://nationalsheep.org.uk/terms-to-know/ | Conflicting gimmer/shearling/hogget/teg definitions — **why terminology is a user-editable overlay and not a taxonomy** (03 §10, 05 §8, 10 §8.6). |
| SRUC / Farm Advisory Service, *TN747 Recording traits of lambing* | https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf | The 1–5 (SRUC: 1–6) lambing-ease scale. **Unverified — image-based PDF, text and licence unconfirmed: §22 A1. Paraphrase, never copy.** |

## 19. Vision science and HCI

| Source | URL | Load-bearing for |
|---|---|---|
| StatPearls, *Physiology, Night Vision* | https://www.ncbi.nlm.nih.gov/books/NBK545246/ | Rod/cone behaviour behind 06 §4's night palette. |
| Webvision, *Light and Dark Adaptation* | https://www.webvision.pitt.edu/book/part-viii-gabac-receptors/light-and-dark-adaptation/ | ~40 min to absolute threshold — the reason the app never flashes white (06 §4, §9). |
| Parhi, Karlson & Bederson, MobileHCI 2006 | https://www.microsoft.com/en-us/research/publication/target-size-study-for-one-handed-thumb-use-on-small-touchscreen-devices/ | 9.2 / 9.6 mm one-handed thumb targets — the empirical floor 06 §6 sizes above. |
| Touch-screen performance with and without motor control disabilities (PMC3572909) | https://pmc.ncbi.nlm.nih.gov/articles/PMC3572909/ | Target size under impaired motor control — the cold-and-gloved analogue. |
| Hoober, *How Do Users Really Hold Mobile Devices?*, UXmatters 2013 | https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php | 49% one-handed; of those 67% right thumb / 33% left — 06 §6's reachability rules and the `left_handed` setting. |
| Naval/aviation red-vs-white dark-adaptation finding | — | **Secondary summaries only; the primary DTIC report returned HTTP 403 and was never fetched: §22 A5.** Medium confidence in 06 §4.3. |

## 20. CI and build infrastructure

| Source | URL | Load-bearing for |
|---|---|---|
| About billing for GitHub Actions | https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions | The 10× macOS multiplier — the reason goldens run on one macOS job and never on a PR (13 §4). |
| `subosito/flutter-action` | https://github.com/subosito/flutter-action | v2 is the current major; there is no v3 — 13 §4's workflows. |
| bundletool releases | https://github.com/google/bundletool/releases · https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar | `dump manifest` — the tool G0 and G1 are built on (13 §2.2). **`latest` floats: §22 D7.** |

---

## 21. Project-internal documents

Not primary sources. Listed because every engineering document cites them and a reader needs the map.

**Binding, in precedence order:**

1. `docs/research/00-tech-decisions.md` — the canonical decision record. **§5 is the only source of any version number in the project.** §1 the five pre-commit decisions · §2 the decision table (#1–#128) · §3 the offline-purity contract and gates G0–G5 · §4 dropped/degraded · §6 corrections applied (do not re-litigate) · §7.0 the owner's four rulings, settled 2026-07-27 · §7.1 the eighteen-item open list, of which items 3, 5, 6, 7 and 8 are closed by §7.0 and **thirteen remain genuinely open** (`00-README.md` §5.2 carries the live list).
2. `docs/engineering/CONVENTIONS.md` — the naming authority. Outranks every engineering document on any name, path, type shape, signature or word. §4.7 policy rule-id namespaces · §6 rulings R1–R73 (R1–R11 the owner's, R12–R73 the review's) · §7 the items it deliberately does not rule on.
3. `shed-book-spec.md` — the product spec. §4 offline · §5 the 3am test · §7 features · §9 screens · §12 the five safety rules · §14 money · §17 open questions.

**The engineering set:** `00-README.md` · `01-architecture.md` · `02-state-di-navigation.md` · `03-data-model-and-schema.md` · `04-migrations-media-backup-restore.md` · `05-domain-correctness.md` · `06-design-system.md` · `07-screens.md` · `08-platform-integration.md` · `09-export-formats.md` · `10-accessibility-and-i18n.md` · `11-monetization-and-store.md` · `12-testing.md` · `13-build-ci-release.md` · `CODE-REVIEW-CHECKLIST.md` · this file.

> **Closed.** Decision-record §8 specifies an index; it is written, as `docs/engineering/00-README.md` — beside the documents it indexes rather than one level up, which is where `06-design-system.md`'s sibling list, `07-screens.md` and `CODE-REVIEW-CHECKLIST.md` all already point. The set has its front door.

**Research inputs** (superseded by the decision record wherever they conflict): `docs/research/raw/01`–`10` and `docs/research/critique/c1-packages.md`, `c2-api-correctness.md`, `c3-consistency.md`, `c4-completeness.md`. `c4` finding 9 is what asked for this file and named its two sections.

**Design inputs:** `docs/design/00-directions.md`, `00-comparison.md`, and the three candidate directions `indelible.md`, `strip-bay.md`, `the-register.md`.

---

---

# 22. What could NOT be verified

Everything below is a claim the doc set makes, or a number it uses, that no primary source and no measurement currently supports. The decision record names three by name — SRUC TN747's text and licence, the Play Billing 8.0.0 AAR manifest, and `ZipFileEncoder`'s streaming behaviour. Those are A1, A2 and A3. The other fifty-odd are the ones you find by reading all fourteen documents at once.

**How to read the tables:** *What would close it* is the cheapest sufficient check, not the most thorough one. *Depends on it* names the document(s) that break, or have to be edited, if the answer is not the one assumed. Items marked **BLOCKING** cannot be deferred past the milestone named.

---

## 22.A Sources that could not be fetched or read

These are failures of *access*, not of effort. Each one has a paper trail.

| # | Claim and its source | What would close it | Depends on it |
|---|---|---|---|
| **A1** | **SRUC / FAS TN747, *Recording traits of lambing*** — the 1–5 (SRUC: 1–6) lambing-ease scale. **The PDF is image-based; neither its text nor its licence terms could be confirmed.** Raw note 09 §1.2 said *"Adopt them verbatim"*; the decision record §6 **overturned that**, and §4 flags verbatim adoption of a levy-body technical note as both a licensing problem and a contradiction of the spec's "written from scratch" claim. | Obtain a text-layer or OCR'd copy **and** a written licence statement from SRUC / Farm Advisory Service. Until then the standing rule holds: **paraphrase at the same semantic granularity, never copy.** The *concept* of a five-point assistance scale is not ownable; the sentences are. | `05-domain-correctness.md` §8 (the scale) · `03-data-model-and-schema.md` §10 (the `lambing_ease` vocabulary seed — 5 of ~40 terms) · `10-accessibility-and-i18n.md` §8.6 (the ARB labels) · `CODE-REVIEW-CHECKLIST.md` §R66 (the "no verbatim third-party copy" check, which scans **both** `assets/content/` and `lib/l10n/`). Also blocks the honesty of decision-record §4's "~13 of ~40 terms actually authored" status line. |
| **A2** | **The Play Billing 8.0.0 AAR manifest.** The claim is that the AAR merges `com.android.vending.BILLING`, a translucent `ProxyBillingActivity`, and a `com.google.android.play.billingclient.version` meta-data key — **and nothing else**, in particular not `ACCESS_NETWORK_STATE`. **The 8.0.0 manifest is not published as text and could not be fetched from any primary source.** The only readable manifest anyone found is a third-party mirror of **billing 2.0.3**, six majors behind. "Billing 8.0.0 adds nothing else" is *highly likely* and **unverified**. | **Run G0.** Build a real release AAB and `bundletool dump manifest` it; that is primary evidence and it replaces the citation entirely. `13-build-ci-release.md` §2.2 carries the four-row table G0 fills in — **every cell of which currently reads UNVERIFIED.** | **BLOCKING the offline gate.** `11-monetization-and-store.md` §2 · `13-build-ci-release.md` §2.2 (G0, and `android/expected_permissions.txt`'s line count — seven or eight) · `08-platform-integration.md` §11 item 13 · `CODE-REVIEW-CHECKLIST.md` (which states plainly: until G0 runs, *"the offline gate in CI is unwritten, not merely unimplemented"*). Removing `INTERNET` is proven; removing `ACCESS_NETWORK_STATE` is not, and **must not be committed on faith**. |
| **A3** | **`ZipFileEncoder`'s incremental-write behaviour** in `package:archive/archive_io.dart`. The class exists, and `OutputFileStream` exists alongside it; whether it streams or materialises is **unverified**. | Encode ~200 MB of media through `ZipFileEncoder` + `OutputFileStream` and watch peak RSS. Empirical, one afternoon. | Decision #85 (media is records-only for v1) · `04-migrations-media-backup-restore.md` §7.6 and §11 · `09-export-formats.md` §5 and §10 item 7 · decision-record §5.1's `archive` row. **No media-in-ZIP design may be attempted until this is done and recorded.** |
| **A4** | **Apple, *Reducing your app's launch time*** — the 400 ms goal quoted in `13-build-ci-release.md` §6. **The direct fetch of the page returned no body during research.** The wording is second-hand; the figure is reported as Apple's published goal. | Fetch the page in a browser session and quote it, or replace the citation with a WWDC session that states the number on the record. | `13-build-ci-release.md` §6's startup budget. Low blast radius — the budget is a target, not a gate — but the number is currently uncited in a document that gates on numbers. |
| **A5** | **The naval/aviation red-vs-white dark-adaptation finding** ("intensity matters more than colour"). Reported from **secondary summaries only**; the primary DTIC report **returned HTTP 403 and was never fetched.** | Retrieve the report through DTIC's public search or an institutional library, or substitute a peer-reviewed vision-science source that states the same finding. | `06-design-system.md` §4.3 — treated as **medium confidence** and explicitly labelled as such. It informs why the red palette exists but is not the argument for it; the surface-ramp argument is, and that one is measured. |
| **A6** | **Any release date for Riverpod 4.0.0.** The 3.0.0 changelog (2025-04-30) says *"It is quite possible that a 4.0.0 will be released relatively soon in the future."* That is a maintainer's signal. **No date has been published and none should be written down.** | Nothing can close this; it is upstream's to announce. The correct handling is already in place: `02-state-di-navigation.md` §2's ban list is what makes a 2.6.1 → 4.x jump cheap, so no plan depends on the date. | `02-state-di-navigation.md` §2 and its References. Listed because a future reader will be tempted to write a date into a roadmap, and the doc set has deliberately refused to. |
| **A7** | **Google's one-time-product fee rate for IE/UK/EEA** after the 30 June 2026 restructure. The figure most often quoted — **20% service + 5% billing** — comes from **secondary reporting only**; Google's own announcement does not state a one-time-product rate, and the secondary sources disagree in detail. | **Read the rate inside Play Console** for the actual merchant account and the actual territories, before committing to a price. | `11-monetization-and-store.md` §10 · decision-record §7.1 #4. ⚠️ This changed two months before the research was done. A number copied from a blog into a spreadsheet is how a price gets set 5% wrong for three years. |

---

## 22.B Package and SDK behaviour never checked against the installed toolchain

Every one of these is a fact about code sitting on disk. None needs a network; all need somebody to look.

| # | Claim | What would close it | Depends on it |
|---|---|---|---|
| **B1** | Whether **`package:sqlite3` exposes an online-backup API on `CommonDatabase`.** `04-migrations-media-backup-restore.md` §8.2 declines to assert either way. | Read the published API of the pinned version. Ten minutes. | `04` §8.2. Does **not** change the decision — #84 names `VACUUM INTO` and its reasons are independent — but nobody may write *"there is no `backup()` method"* in a code comment on this document's strength. |
| **B2** | Whether **Flutter 3.44's in-framework accessibility evaluations are public API.** The release notes list non-text colour contrast (`kMinimumRatioNonText = 3.0`), `UnlabeledLeafNodeEvaluation` and a title evaluation — but they live in `_accessibility_evaluations.dart` and **the leading underscore means they may still be private.** | `grep` the installed SDK for `kMinimumRatioNonText` and for exported `AccessibilityGuideline` constants. **Do this before writing any hand-rolled non-text contrast check.** | `10-accessibility-and-i18n.md` §5.3 and §11 · `12-testing.md` §7. If public: wire them in and delete the manual step. If private: keep measuring WCAG 1.4.11 by hand and re-check on every SDK bump. |
| **B3** | **`ShareResultStatus`'s member set and per-platform semantics** on the pinned `share_plus`. | Read the package source; then run an airplane-mode pass on both OSes and record what each actually returns. | `09-export-formats.md` §8.3's three-way branch and `last_exported_at` stamping · `08-platform-integration.md` §11 item 8 (`ShareService`'s signature) · `04` §7.6. The requirement 09 places on 08 is that the result **reaches the caller at all** rather than being swallowed into a `Future<void>` — that part does not depend on the answer. |
| **B4** | Whether **`pragma_compile_options` is itself available in the bundled sqlite3 build.** The FTS5 startup assertion is written against it. | Run it once. If compiled out, the documented replacement is `CREATE VIRTUAL TABLE temp.fts5_probe USING fts5(x)` inside a `try`/`rethrow` — still an assertion, still loud, **still not a fallback branch.** Record which one shipped. | `03-data-model-and-schema.md` §1.3 and its DoD. Week one. |
| **B5** | **`flutter_image_compress`'s `minWidth`/`minHeight` — floors or caps.** They are documented as *minimums*; decision #40 specifies **longest edge 2048 px**. Passing `2048/2048` may cap the *shorter* edge and leave the longer one above 2048. | Measure on one portrait and one landscape photo from a real phone. If they behave as floors, derive the pair from the source aspect ratio before compressing. **Ship the assertion either way:** open the output and fail if `max(w, h) > 2048` or `bytes > 900 KB`. | `04-migrations-media-backup-restore.md` §4.4 · `08-platform-integration.md` §11 item 5. |
| **B6** | Whether **drift opens `transaction()` with `BEGIN` or `BEGIN IMMEDIATE`.** A plausible claim was written here from memory and deliberately removed. | Read it off a statement log once and record the answer in the file. | `03-data-model-and-schema.md` §5.14. Matters only for the deferred-to-write upgrade case, which needs two concurrent writers, which this app does not have. If it is a deferred `BEGIN`, `busy_timeout = 5000` covers the `VACUUM INTO` overlap and nothing else changes. |
| **B7** | Whether **cascade deletes fire correctly with `recursive_triggers` on**, in the bundled SQLite. | Five-minute test: insert a note, delete its season, assert `search_docs` is empty and `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw — **once with the pragma on and once with it off.** | `03-data-model-and-schema.md` §9.2. The orphan sweep makes the app correct either way; the answer decides only whether the pragma is load-bearing or belt-and-braces. |
| **B8** | Whether **`pdf` accepts a *variable* font file** (`AtkinsonHyperlegibleNext[wght].ttf`), and if so which instance it embeds. The package has its own TTF parser; `fvar`/`gvar` tables may be ignored, mis-rendered or rejected. | Twenty minutes: build a one-page document with `pw.Font.ttf(ByteData.sublistView(fontBytes))`, write it, open it in Preview **and** Acrobat, confirm glyphs and metrics. | `09-export-formats.md` §4.2 and §10 item 1. **Blocks the flock book.** Fallback is two static instances. |
| **B9** | Whether **`pdf` subsets the embedded face** or writes the whole thing into every document. | Generate a 1-row and a 500-row document; diff the file sizes. | `09` §4 and §10 item 2. Acceptable either way — but measure it **before promising a printable flock book by email**, because the number lands in someone's inbox. |
| **B10** | Whether **`pw.TableHelper.fromTextArray(headerCount: 1)` repeats the header** across `MultiPage` pages. | Generate a 5-page table and look at page 3. | `09` §4.5's page furniture. |
| **B11** | Whether **`pdf` writes the document-information `subject:` as a plain literal PDF string**, findable as UTF-8 in an uncompressed document. This is **asserted from the PDF format, not measured from the package**, and the entire byte-level disclaimer proof rests on it. | Build a two-page document with `compress: false` and `grep` the raw bytes for the first six words of `Disclaimers.exportFooter`. Repeat with `compress: true` and record whether it still hits. | `09` §6.4 and §10 item 13 — `every_export_carries_the_footer_test.dart`'s PDF arm. If the string is not findable, the fallback is a structural assertion only, and §6.3's "footer on every page" loses its byte-level proof. **Say so rather than deleting the row.** |
| **B12** | Whether **glob patterns in a pub `workspace:` list are supported on the pinned SDK.** Not verified by the c1 audit. | Check dart.dev, or try one. | `01-architecture.md` §8. Only bites if a second package is ever extracted. The related fact *is* settled: `build_runner --workspace` is documented as experimental, so codegen stays in the app package. |
| **B13** | Whether **drift_dev can constant-fold a `customConstraints` expression built by a helper function.** | Nobody intends to find out. The rule is: write constraints as literal strings, never factor them. | `03-data-model-and-schema.md` §2 rule 7. Listed because it is an *avoided* unknown, not a resolved one — a future refactor that "tidies up" the constraint strings would walk straight into it. |
| **B14** | **`dart_test.yaml` fidelity under `flutter test`.** Two halves of one check: (a) whether `allow_test_randomization: false` actually takes effect on the `migration` tag; (b) whether `flutter test` accepts `-P` / `--preset` **at all**. `flutter test` historically honours less of the file than `dart test` does. | Run both on day one, together. Fallback for (a): `--exclude-tags migration` in the randomised job plus a separate non-randomised invocation. | `12-testing.md` §11.2 and Open item 1 · `13-build-ci-release.md` §1.3 (the `Makefile`'s `-P ci-fast` / `-P ci-golden`) and §4.3, **whose CI YAML currently carries an `UNVERIFIED` comment in-line.** Answer (b) decides whether 12's §14 edit 1 lands in 13 or reverses back into 12. |
| **B15** | **The iOS permission resolver's exact type name** after the plugin's v19 `Darwin` rename. Note 06 contradicts itself between its §1.2 and §9. | Read it off the installed plugin. | `08-platform-integration.md` §11 item 3. |
| **B16** | **`getNotificationAppLaunchDetails()`'s shape** after v20 made every parameter named. | Read it off the installed plugin. | `08-platform-integration.md` §11 item 4. |
| **B17** | Whether **an incorrect `tz.local` can move the *fired* instant on iOS**, given the plugin's `UNCalendarNotificationTrigger` construction. The DST-8 invariant proves the **Dart-side** conversion is a rendering, not a shift — *on Android, where the plugin hands an epoch to `AlarmManager`*. **The plugin's iOS side is unread.** | Measure on a device: schedule across a DST boundary with a deliberately wrong `tz.local` and observe when it fires. | `08-platform-integration.md` §11 item 2 · `05-domain-correctness.md` §2.9 (the DST cases). This is what makes the un-audited `flutter_timezone` dependency (D6) a *bounded* risk rather than a correctness hole — and the bound is only proven on one of the two platforms. |
| **B18** | **AGP's real floor** for the pinned `share_plus` and `flutter_local_notifications`. Both numbers in `08` §8.3 are **README numbers**, and a README changes a floor without a changelog entry. | Read them off the installed packages before the first release build. | `08-platform-integration.md` §8.3 and §11 item 15 · `13-build-ci-release.md` §3. |
| **B19** | Whether **`tools:node="remove"` in `src/main` leaves the `src/debug` `INTERNET` intact.** Merge priority says build type outranks main, so it *should*. | Read the **debug** merged manifest. Confirm; do not assume. | `13-build-ci-release.md` §2.2's G0 table. If it does not, debug builds lose networking and every developer notices on day one — which is the safe failure direction, but the doc asserts the safe one without evidence. |
| **B20** | **Which `make` target trips the `package:sqlite3` build-hook download first** on a cold cache — `pub get`, `gen`, `test` or `build`. | Find out once, in plane mode, and write the answer in the README. | `13-build-ci-release.md` §1.3. Nothing breaks; but *"offline build"* is a claim this project will be held to, and without that paragraph the first offline build failure gets mistaken for a regression and somebody loses an evening. |
| **B21** | Whether each of the plugins **not on Apple's third-party-SDK list ships a `PrivacyInfo.xcprivacy`** — specifically `file_selector`, `record`, `flutter_image_compress`, `wakelock_plus`, `in_app_purchase_storekit` and `sqlite3`. | Check the generated privacy report at archive time. | `11-monetization-and-store.md` §9.3. If one does not ship a manifest and it touches a required-reason API this app has not declared, **the declaration is ours.** `C617.1` already covers the common case. |
| **B22** | Whether **StoreKit 2 under the pinned `in_app_purchase_storekit` distinguishes Apple's Ask-to-Buy hold** from an ordinary `pending`. **No primary source in the research covers it.** | Test with a sandbox family account configured for Ask to Buy. | `11-monetization-and-store.md` §6.3. Handled safely either way — both arms mean no unlock, no `completePurchase`, flag left set — so a later approval drains through the same path. Listed because the *safety* is by construction, not by knowledge. |

---

## 22.C Numbers that are estimates, not measurements

Every number below is currently a desk figure. Several are already load-bearing in a CI gate.

| # | Number and where it is used | What would close it | Depends on it |
|---|---|---|---|
| **C1** | **Atkinson Hyperlegible Next's file size, `wght` axis range, and figure features.** The font **was never downloaded** while `06-design-system.md` was written. Three separate unknowns: (a) the file size — decision-record §5 does not carry the font, so there is no authoritative number to copy; (b) the `wght` axis range; (c) the claim that it has **no** `zero`/slashed-zero feature and no `ss01`/`cv` variants, separating `0` from `O` by counter shape and width alone. | Download it. Read the `fvar` table, `ls -l` the file, and view `0` against `O` **on a real device under a head torch**. If (c) fails the legibility test, the documented fallback is Inter with `FontFeature.slashedZero()`. | `06-design-system.md` §5.2 and §11 · `09-export-formats.md` §4.2 (the embedded TTF and its ~114 KB estimate) · `13-build-ci-release.md` §6 (the size budget). **Must run before the pubspec entry is written.** |
| **C2** | **The 0.72 em cap-height figure** in `06` §11 — *"a typical value for a humanist sans, not a measurement of this face."* Everything downstream inherits the uncertainty: **4.6 mm**, **26 arc-minutes**, *"~5× threshold"*. | Measure the shipped face when the font is locked in. | `06-design-system.md` §11's legibility argument. The *direction* of the argument survives any plausible value; the specific arc-minute figure does not. |
| **C3** | **`kPdfRowsPerVolume = 2000`** and the **100–200 MB peak-heap** figure behind it. `pw.Document.save()` materialises the whole document; `pw.MultiPage` builds its tree before paginating. The estimate is explicitly *"plausibly 100–200 MB"*. | Measure peak RSS on the **low-end target device** generating a 2,000-row volume. | `09-export-formats.md` §4.9 and §10 item 4. The split threshold. On a €150 Android phone in a cold shed with the camera app still resident, being wrong here is an OOM kill during the one export that mattered. |
| **C4** | **Peak heap for `jsonEncode` at the 20 MB tripwire.** | Measure at the tripwire, not before. | `09-export-formats.md` §5.7 and §10 item 8. Decides whether the streaming writer is ever needed at all. |
| **C5** | **The 50-file batch in one `ShareParams`.** *"A chosen bound, not a documented platform limit"* — `share_plus` publishes none. Picked so one share never carries more than ~35 MB of `XFile` paths through the platform channel. | Find a real limit on either OS. If one exists, it replaces this number and the source goes into `04` §11. | `04-migrations-media-backup-restore.md` §7.6 · `08-platform-integration.md` §6. |
| **C6** | **Photo size at 2048 px / q80 on a real device.** **Only the 1600 px figures were ever measured.** | Measure; record in `docs/perf/measurements.md`. | `04` §4.7 · `08` §11 item 6 · the storage budget generally. |
| **C7** | **Android device-to-device transfer behaviour.** Two halves: (a) Google documents the **25 MB** Auto Backup limit for backup *to Drive*; it is **not documented as applying to local D2D transfer**; (b) Google's own docs note that on Android 12+ `allowBackup="false"` *"may only disable cloud backups but not device-to-device transfers, depending on the device manufacturer."* | Confirm empirically **before any UI text implies media transfers**. | `04-migrations-media-backup-restore.md` §9.2. (b) is another reason to *configure* backup rather than disable it. |
| **C8** | **`timezone`'s `latest_10y` vs `latest` byte cost** — 85 KB vs 361 KB, a figure carried from a raw note. | Read it from `--analyze-size` output. | `08-platform-integration.md` §11 item 9 · `13` §6's size budget. |
| **C9** | **The keypad frame budget and `rankTagMatches`'s speed.** A naive 400-row implementation would *plausibly* still hit 60 fps — **an estimate, not a measurement.** A substring scan over 400 short strings is claimed **sub-millisecond**; sharper figures circulate (~40 µs) and are **desktop estimates, not target-device measurements.** | Decision #126: profile mode, two real devices, the 400-ewe fixture. | `02-state-di-navigation.md` §9 and the tag-matcher section. Nothing in the design *depends* on the sharper numbers, and the doc says so — the structural claim (the filter runs in Dart on the UI isolate, so digits and list update in the **same** frame) holds regardless. |
| **C10** | **Every tap-count budget** in `07-screens.md` — 6 taps unlock→lambing, 1 tap foster reassignment, 2 taps repeat treatment. **Desk estimates until the field night happens.** | The field night (decision-record §7.1 #1). CI holds the three numbers; **it cannot tell you they are the right three.** | `07-screens.md` §1.3 and its DoD · `12-testing.md` Open item 8. |
| **C11** | **Free-space figures on the Diagnostics screen.** They need ~20 lines of platform channel (`StatFs.getAvailableBytes()` / `NSFileManager.attributesOfFileSystem(forPath:)`); `disk_space_plus` is rejected. **Until that channel exists the two rows are not implemented and the screen says so** rather than showing a wrong number. | Write the channel. **In the same commit, `PrivacyInfo.xcprivacy` gains the `E174.1` reason code** (#93) — it is declared *only if* free space is actually queried, so shipping the channel and forgetting the manifest is an App Review finding. | `04-migrations-media-backup-restore.md` §8 · `11-monetization-and-store.md` §9.2. |
| **C12** | **`DateTime.timeZoneName`** returns an abbreviation on some platforms and a full name on others. | Log it on both OSes. | `09-export-formats.md` §3 (the CSV trailer's zone line, `exportedAtZoneAbbreviation`) and §10 item 6. Note the constraint: **never `package:timezone` here** — R48 confines that package to the notification seam. |

---

## 22.D Gates, tests and checks that have never been run

The difference between an unwritten test and an unrun one matters here: several of these are *written down in full* and have simply never executed.

| # | Gate or check | What would close it | Depends on it |
|---|---|---|---|
| **D1** | **Whether drift's `SchemaVerifier` tolerates FTS5 shadow tables** (`search_fts_data`, `_idx`, `_docsize`, `_config`). **Nobody has verified it.** Schema-diffing tools in other ecosystems have choked on exactly these (prisma#8106, rails#52354). | **Write the migration matrix test with FTS5 present in schema v1, before there is a single real row**, so you find out in week one rather than at v4. If the verifier rejects them: move note search behind a plain `search_docs` table with a ranked, `LIKE`-free query, **or** exclude the virtual table from the snapshot — decide then, with the error in front of you, and record the outcome. **Do not paper over it by disabling the assertion.** | `04-migrations-media-backup-restore.md` §3.4 · `03-data-model-and-schema.md` §9.2 and its DoD · `12-testing.md` §3 and Open item 6 · `CODE-REVIEW-CHECKLIST.md` (*"do not assume a green matrix has proved the search tables"*). |
| **D2** | **drift#3322** — whether drift's SQL analyser will generate for FTS5's special INSERT commands (`INSERT INTO t(t) VALUES('delete')`, `VALUES('rebuild')`). Open upstream. | Run codegen in week one. **Two ways out and you take one of them, not a third.** **Fallback A:** keep external content, move the two triggers and the rebuild into `customStatement`s where drift never parses them — costs the typed query API and puts raw SQL in `lib/core/db/`. **Fallback B:** drop `content='search_docs'` and let `search_fts` store its own copy — the corpus is a few hundred KB, so the duplicate costs nothing, and the whole cascade-vs-`recursive_triggers` question (B7) stops mattering. **Take B if A costs more than half a day**, and record which one shipped in both `03` and `04`. | `03-data-model-and-schema.md` §9.2 · `04` §3. **Before the schema is frozen.** |
| **D3** | **The host sqlite3 version on the actual CI runner image.** `flutter test` runs against the host's sqlite3; the project asserts a **3.41.0** floor (STRICT needs ≥ 3.37.0). Which build a given image ships **has not been checked** — an older LTS image can ship below the floor. | Run `test/data/host_sqlite_version_test.dart` on the image in use, **before the first green CI**. | `12-testing.md` §3.2 and Open item 3. If it fails, **the fix is the runner image, never the assertion.** Lowering the floor to whatever the runner happens to have is how `STRICT` stops being tested. |
| **D4** | **The tolerant golden comparator's installation.** `LocalFileComparator`'s basedir resolution and its interaction with `flutter_test_config.dart` are unconfirmed. | **Deliberately break a golden** and confirm the run goes red. | `12-testing.md` §8.3 and Open item 4. Until this is done, **a green golden run proves nothing.** |
| ~~**D5**~~ | ~~**`glados`'s resolution against the pinned stack**~~ **— CLOSED 2026-08-01, it reddened.** | `flutter pub get` was run in N00-T03, the first execution of decision #5. | `glados: any` reports *"glados is incompatible with drift_dev 2.34.5"*: it depends on `package:test`, which caps `analyzer <13.0.0` and pins a `test_api` other than `flutter_test`'s exact `0.7.11`. **The stated rule was applied — the property layer was deleted, not the pin.** §5.2's row is struck, decision #118 is amended, and `12-testing.md` §10.6 carries the outcome. |
| **D6** | **`flutter_timezone` (or an equivalent) has never been audited.** Something must supply the device's IANA name to `tz.setLocalLocation`. It appears only in a raw note; **no critic verified it**, and the decision record explicitly forbids copying that note's version number into a pubspec. | **Audit it by c1's method** — pub.dev API, publisher, transitive graph, merged manifest — and record the verified version in decision-record §5 **before adding it**. | **BLOCKING the first release build.** `08-platform-integration.md` §11 item 1 · `05-domain-correctness.md` §2 (the DST tests assume a correct `tz.local`) · decision-record §5.1. |
| **D7** | **`bundletool latest`** — the G0/G1 gate's tool floats. It has been stable for years and `dump manifest` is its oldest command. | Nothing, until a bundletool release changes the dump format; **then pin a version.** | `13-build-ci-release.md` §2.2. Fails *closed* (exit 1 on a diff), which is the correct direction — listed for completeness, not as a risk. |
| **D8** | **G0 has not been run at all.** See A2. Consequently the four-row table in `13` §2.2 is entirely UNVERIFIED, including the **effective `minSdk` after plugin manifest merging** (13 §3.1 forbids setting it from memory; a raw note reports the notifications plugin raising it, but that is a changelog line, not a merged manifest) and **`flutter_image_compress`'s Android manifest contribution**, which was never verified at all. | Build a release AAB, `bundletool dump manifest`, and fill in every cell in the commit that closes G0. | `13-build-ci-release.md` §2.2 · `08-platform-integration.md` §11 items 7, 13, 14 · `11-monetization-and-store.md` §2 · `CODE-REVIEW-CHECKLIST.md`. |
| **D9** | **G5 is not a gate and must never be described as one.** iOS has **no permission to remove**; G5 is construction plus **one manual App Privacy Report / `nettop` check per release.** | Nothing — this is a permanent asymmetry, recorded so nobody claims parity. | `13-build-ci-release.md` §2 · `CODE-REVIEW-CHECKLIST.md`: *"Say so honestly; never imply parity with Android."* |
| **D10** | **The iOS half of `launch.colour_parity` has not been run.** The Android half is trivial string matching; the iOS half parses **floats out of storyboard XML** and may prove brittle. | Run it. Compare to within 1/255. If it proves brittle, **downgrade that one assertion to the release checklist rather than weakening the rest.** | `06-design-system.md` §9.4 · `13-build-ci-release.md` · `CODE-REVIEW-CHECKLIST.md` §1 (the one rule that reads outside `lib/`). Either way **the manual check stays**: a cold launch on both platforms in a genuinely dark room, every release. A screenshot test cannot catch this — the flash is on the native side, before Flutter runs. |
| **D11** | **Whether the deep-red palette is usable at 4.59:1 for secondary text under a real head torch.** *"Not a desk question."* | `06` §4.8's ten-minute dark-adaptation procedure. **It has not been run.** | `06-design-system.md` §4.8. The palette ships or does not on this result. |
| **D12** | **Whether `stepByStep` throws on a downgrade** on the pinned drift. *"Understood to"* — but that is library behaviour on a pinned dependency, and `04` deliberately refuses to quote a version-sourced claim it cannot get from decision-record §5. | `test/drift/downgrade_test.dart` **owns the guarantee** rather than quoting it — it opens a newer file with older code and asserts a throw. Run it. | `04-migrations-media-backup-restore.md` §2.1 and §3.5. This is the model the rest of §22 should follow: where a library fact cannot be cited, own it with a test. |

---

## 22.E Names and spellings that are placeholders, and one live contradiction

| # | Item | What would close it | Depends on it |
|---|---|---|---|
| **E1** | **`HapticFeedback.successNotification()` — the doc set contradicts itself, and the contradiction is stale in three places.** `06-design-system.md` §10 states the member is real *"checked, because the iOS-only-sounding names invite the assumption that they are not"*, and its References record every symbol as resolved against a local **3.44.6** checkout on 2026-07-27 (the pin is **3.44.8**; §5 records the SDK pins as identical, so the doc argues no symbol is version-sensitive within 3.44). But **`07-screens.md` §22 item 7, `10-accessibility-and-i18n.md` §11 and `12-testing.md` Open item 7 all still carry it as unverified**, sourced to a raw note and *"never checked against the SDK"*. `CONVENTIONS.md` §7 item 4 deliberately declines to rule, on the grounds that it is an SDK fact and not a name. | **`grep` the installed 3.44.8 SDK for the member and the `HapticFeedbackConstants.CONFIRM` mapping.** Then either clear the three stale flags, or correct `06` §10 and §11. This is a five-minute check that closes four documents at once. | `06-design-system.md` §10 and §11 (four use sites) · `07-screens.md` §22 item 7 · `10` §11 · `12` Open item 7. If the member does not exist on 3.44.8, the commit haptic degrades to `heavyImpact()` and **the design intent is unchanged** — the vocabulary is correct, only the spelling is in doubt. |
| **E2** | ~~**`checkLambing(lambing, lambs)` is a placeholder name.**~~ **Closed.** `05-domain-correctness.md` §7.5 guarantee 1 now names the validation entry points — `checkLambing(Lambing, List<Lamb>)`, `checkFoster`, `checkTreatment`, beside the already-printed `checkClearDate` and `checkLocalWallTimeExists` — under the fixed shape `check<Thing>` → `List<Warning>`, one per file. | Nothing. Delete this row at the next revision. | `12-testing.md` §10 and §10.4 call 05's spelling, not a placeholder. |
| **E3** | **`copy.tier3_claim` is a coinage, not an adopted rule id.** The banned phrase *"your data never leaves your phone"* is described as banned by `07-screens.md` §21.1 (as literal text in `lib/` and `assets/`), by `13-build-ci-release.md` §2.1 (by `tool/check_policy.dart`) and by `CONVENTIONS.md` §5.3 — **but no document prints a rule id for it, and `_bannedText` in `01-architecture.md` §3.2 has no row.** `CODE-REVIEW-CHECKLIST.md` named it `copy.tier3_claim` under CONVENTIONS §4.7's namespace list and flagged the coinage as unverified. | A document adopts the id and `01` §3.2 grows the row. **Until then the phrase is a human check.** | `CODE-REVIEW-CHECKLIST.md` §2.3 · `01` §3.2 · `07` §21.1 · `13` §2.1. Note separately that **store listings and release notes are outside every scanner's reach** and are a manual pre-release item whatever happens to this row. |
| **E4** | **A contrast correction, recorded rather than silently applied.** A note printed **7.36:1** for `#FF6B4A` on `#000000`; recomputation with the WCAG formula on 2026-07-27 gives **7.45:1**. The night palette's three surface-ramp steps are **1.07 / 1.18 / 1.36**, not the 1.08 / 1.20 / 1.42 an earlier draft printed. | `test/design/contrast_test.dart` **is the authority** — and it has not been written yet. Write it; every ratio in `06` §4 is the recomputed value pending that test. | `06-design-system.md` §3.5 and §4. Listed here because the *authority* named for these numbers does not yet exist. |
| **E5** | **OLED black smear and halation** — design-literature leads with **no primary clinical citation**. | A clinical or display-engineering source, if one is wanted. | `06-design-system.md` §4. They inform the choice of `#0B0D0E` over `#000000` but are **explicitly not load-bearing** — the surface-ramp argument is, and that one is arithmetic. |

---

## 22.F Permanently undefined — no source exists, and none is coming

| # | Item | Why it cannot be closed | How the doc set survives it |
|---|---|---|---|
| **F1** | **iOS's behaviour when an app exceeds the 64 pending-notification-request limit.** **Three conflicting descriptions exist**: the Apple Developer Forums thread, the plugin's issue #2312 (closed `not planned`), and a third account. No authoritative statement has ever been published. | Apple has not documented it, and the plugin issue was closed without a resolution. | `08-platform-integration.md` §2 designs to a **56-slot budget** — a deliberate margin under 64 — precisely because the over-limit behaviour is undefined. `07-screens.md` §11's reconciliation copy reports what was actually scheduled rather than what was requested. **The architecture does not depend on the answer; only the budget does.** |

---

## 22.G Owner decisions still open

These are **not** verification failures — nothing is missing that research could supply. They are listed because several documents carry a branch that cannot be collapsed until a human answers, and a reader auditing §22 will otherwise mistake them for gaps.

| Decision-record ref | Question | What it blocks |
|---|---|---|
| §7.1 #1 | **Does a night in a real lambing shed happen before Quick Entry is written?** *The highest-value unresolved item in the project.* | Every tap budget in `07` (C10); closes #2, #12 and #18 as a side effect. |
| §7.1 #2 | **Ziplock-bag capacitance.** Does the target hardware register taps through a freezer bag? | If not, the entire interaction model is rethought around volume-button shortcuts, and decisions #100–#102 all change. Hardware test, not a desk decision. |
| §7.1 #4 | **Exact price and territories.** | `11` §10 — and see A7: the Play fee rate must be read in Console first. Enrol in Apple's Small Business Program **before the first sale**. |
| §7.1 #9 | Does the app replace the paper record, or sit alongside it for the first season? | `09` §10 item 9 — how hard the export has to work, and whether records-only JSON backup is acceptable at all. |
| §7.1 #10 | Is the target market ever a **dairy flock**? | `09` §10 item 12. The `milk_*` CSV columns ship regardless, because `WithdrawalTarget.milk` is in the v1 sealed type; the v1 UI may never write one. |
| §7.1 #11 | **Does a temperature field ship at all?** Spec §7.10 has a °C/°F setting; §10's data model has no temperature column. | `03` DoD calls this *"the only thing in this document that cannot be closed by a developer"* — and it is a schema decision, so it **closes before the first `make-migrations` run**, not after. Also `07` §14.3 and `09` §10 item 11. |
| §7.1 #12 | Lamb-scale resolution and the plausible weight band. | Grams stay canonical either way; the *input step* needs twenty minutes with a real shepherd. |
| §7.1 #13 | Does a lamb kept as a breeding ewe become a `Ewe` row? | A v1 schema decision with v3 consequences — a nullable `became_ewe` FK. |
| §7.1 #14 | Does the developer account exist, and is it a personal account created after 13 Nov 2023? | If yes, the **12-tester / 14-day closed test** is on the critical path and must be scheduled now. **And: who are the twelve testers?** That recruitment doubles as the answer to #1. |
| §7.1 #15 | **Lambing ease: 5 points or SRUC's 6?** | Recommendation on record: stay at 5 and document that 5 covers elective caesarean. **Decide before any data exists.** Interacts with A1. |
| §7.1 #16 | Is printing *from inside the app* required? | The only thing that re-admits `printing` and its `http` dependency behind a CI gate. `09` §10 item 10. |
| §7.1 #17 | Does the free tier cap reminders? | 15 ewes fits inside the 56-slot budget comfortably; 400 does not. Changes the budget, **not the architecture** (`08` §11 item 11). |
| §7.1 #18 | Voice-note cap: 60 s or 120 s? | One-line change to `kVoiceNoteMaxSeconds`; drives the storage budget. |
| `07` §22 item 12 | **Export banner quiet hours 06:00–22:00** — narrows decision #72 using the owner's 22:00–06:00 precedent. | Needs owner confirmation. |
| `CONVENTIONS.md` R41 escalation | "Culled in March, un-culled in April" — if the retention story needs it, that is a schema addition. | Owner. |

**Settled and not to be reopened** (decision-record §7.0, 2026-07-27): tag OCR and voice tag entry are **cut from v1** (the voice *note* ships); tag uniqueness is **among active animals only**, a partial unique index; the first region is **UK / Ireland**, which fixes the ambiguous DST hour at 01:00–01:59 and the AHDB lambing-percentage default; the free tier is **season-primary with the ewe cap secondary**. Anything in the research notes that contradicts these is superseded.

---

## 22.H Summary — what to run first

If only one afternoon is available, run these five, in this order. Each closes more than one document.

1. **G0** — build a release AAB and `bundletool dump manifest`. Closes **A2**, **B19**, and most of **D8**; unblocks the offline gate, which is currently *unwritten, not merely unimplemented*.
2. **The FTS5 migration matrix with FTS5 in schema v1** — closes **D1** and **D2** while the schema still has no real rows in it. Both are irreversible-after-the-first-snapshot decisions.
3. **`grep` the installed SDK for `HapticFeedback.successNotification` and `kMinimumRatioNonText`** — closes **E1** across four documents and **B2** across two. Five minutes.
4. **Audit `flutter_timezone` by c1's method** — closes **D6**, which blocks the first release build outright.
5. **Download the font** — closes **C1**, unblocks the pubspec entry, the PDF embed and the size budget.

Everything else in §22 is either measurable at leisure, safe by construction, or an owner's to answer.

---

## 23. Compilation note and toolchain

**Compiled 2026-07-27** by reading the `## References` section of all fourteen engineering documents plus `docs/research/00-tech-decisions.md` §5 and its reference sections, deduplicating by URL, and re-reading each citing passage to write the load-bearing note. Source fetch dates are 2026-07-27 throughout unless an entry says otherwise; §22 A4 and §22 A5 record the two fetches that failed.

**The toolchain this bibliography was written against:**

| | |
|---|---|
| Flutter | **3.44.8 stable** (released 2026-07-23), pinned in `.fvmrc` and in one `env:` block per workflow — four places, asserted equal by a three-line CI step |
| Dart | **3.12.2** |
| SDK-pinned transitives that constrain everything downstream | `meta 1.18.0` · `test_api 0.7.11` · `intl 0.20.2` — pinned *exactly* by the SDK, which is what makes the drift / `build_runner` / Riverpod 2.6.1 combination the only resolvable one (decision #2) |
| Version authority | `docs/research/00-tech-decisions.md` **§5**, and nowhere else — not memory, not a pub.dev page, not this file |
| Verified against | the pub.dev API on **2026-07-27**, and checked to resolve against the SDK pins above |
| SDK checkouts read directly | Flutter **3.44.6** (`06-design-system.md`'s symbol resolution — §5 records the 3.44.x SDK pins as identical, so the doc argues no symbol is version-sensitive within 3.44) and a 3.44 stable checkout (`10-accessibility-and-i18n.md`'s engine and framework reads) |
| Package sources read directly | `~/.pub-cache/hosted/pub.dev/` — Riverpod 2.6.1 and 3.4.1, with file and line recorded in `02-state-di-navigation.md` §2.1 |

**When to re-compile this file.** On any Flutter or Dart bump — the SDK pins move and `intl: any` has to be re-checked; when any §22 item is closed — the entry moves from §22 into the bibliography with its evidence; when a document is added to the set; and before the first release build, because §22 D6 and D8 are both BLOCKING and neither is closed today.

**A note on how this file should age.** A bibliography that only ever grows is a bibliography nobody trusts. §22 is meant to *shrink*. Every time an item there is closed, delete it from §22, write the answer into the document that depended on it, and — if a source was finally fetched — add it to the bibliography above with its fetch date. An entry that still says "unverified" at v1.0 is an entry nobody finished.
