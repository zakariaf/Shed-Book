# Gate failures — what fired, what it means, and the forbidden fix

Load this when a gate is red. Every row names the **forbidden fix** as well as the real one, because
almost every rule here has an obvious one-line way to silence it that destroys the property it
proves.

**The rule that outranks every row below.** Never edit `tool/check_policy.dart`, its rule table or
its exit code to make a build pass. Never add a line to `tool/policy_allowlist.txt` or
`android/expected_permissions.txt` to silence a gate. If a gate is genuinely wrong, say so and stop.
User instructions outrank this skill; your own convenience does not.

## Contents

1. [Reading the output](#1-reading-the-output)
2. [`dep.*` — the G2 lockfile allowlist](#2-dep--the-g2-lockfile-allowlist)
3. [The packages an agent actually proposes](#3-the-packages-an-agent-actually-proposes)
4. [`net.*` and `layer.import` — G3](#4-net-and-layerimport--g3)
5. [`layer.*` — the eight dependency rules](#5-layer--the-eight-dependency-rules)
6. [`time.*`, `rp3.*`, `stream.*`, `db.*`, `stat.*`](#6-time-rp3-stream-db-stat)
7. [`a11y.*`, `gesture.*`, `token.*`, `main.*`, `ui.*`, `copy.*`](#7-a11y-gesture-token-main-ui-copy)
8. [G1–G5 when they fire](#8-g1g5-when-they-fire)
9. [Failures that are not policy violations](#9-failures-that-are-not-policy-violations)

---

## 1. Reading the output

`dart tool/check_policy.dart` prints one line per violation, sorted, to stderr:

```
POLICY  [rule.id] path/to/file.dart contains "text" — why
```

Exit codes: **0** clean · **1** violations · **2** the gate could not run. Exit 2 is a failure, never
a skip — it means `tool/policy_allowlist.txt` or `pubspec.lock` is missing. The fix for exit 2 is
`flutter pub get` or restoring the allowlist file, never deleting the check.

The rule tables are the first hundred lines of `tool/check_policy.dart` and are its documentation;
the layer rules they enforce are `01-architecture.md` §3.1. Read the row, not the regex.

---

## 2. `dep.*` — the G2 lockfile allowlist

```
[dep.direct_main] <name> is not on the allowlist — read its pubspec, confirm it opens no socket
and merges no permission, then add it to tool/policy_allowlist.txt
```

| Id | Lockfile kind | Allowlist section |
|---|---|---|
| `dep.direct_main` | `direct main` | `[dependencies]` |
| `dep.direct_dev` | `direct dev` | `[dev_dependencies]` |
| `dep.transitive` | `transitive` | `[transitive]` |

**What it means.** A package entered the graph that nobody reviewed. Either you added it, or a
dependency bump pulled it in — the second case is the one the gate exists for.

**The real fix.** Find out which edge introduced it (`flutter pub deps`). Then: does
`docs/research/00-tech-decisions.md` §5.3 already reject it? If yes, remove the thing that pulled it
in. If no, audit it (verified publisher, transitive graph, merged Android permissions), record the
verified version in decision-record §5.1 or §5.2, and only then add the allowlist line — for a
`[transitive]` entry, with the reason on the line.

**The forbidden fix.** Adding the name to the allowlist to make the build green. Moving an entry
into `[transitive]` because `[dependencies]` felt like a bigger commitment. Widening the parser.

**Two `[transitive]` entries exist so nobody "fixes" them:** `http` (via `timezone` **and** via
`package_info_plus`, `file_selector_platform_interface` and `image_picker_platform_interface` — four regular edges) and `sqlite3_flutter_libs` (a no-op EOL shim dragged in by
`drift_flutter`, **not** flagged discontinued on pub.dev, so a check keyed on that flag never fires).
Deleting either line does not make the graph cleaner; it makes the build red for a fact that is
documented and unavoidable.

**Never write a "no `http` in `pubspec.lock`" rule.** It is unsatisfiable: satisfying it means
deleting reminders and the wakelock. Four research notes proposed it. The claim G2 makes is narrower
and true — *no package enters the graph unreviewed*.

---

## 3. The packages an agent actually proposes

These eight come up repeatedly. Each has a rejection row in decision-record **§5.3** carrying the
full reason and alternative — read the row before answering; this table is a pointer, not a copy.

| Proposed for | Package | Answer |
|---|---|---|
| The season summary chart | `fl_chart` | Rejected. Hand-rolled `CustomPainter` (~120 lines, `semanticsBuilder`, golden-tested at three data shapes) — decision #70. |
| Writing the CSV export | `csv` | Rejected. Hand-rolled RFC 4180 writer, ~50 lines — you need byte control over BOM, CRLF, quoting and the formula-injection guard — decision #82. |
| Navigation | `go_router` | Rejected. `Navigator` 1.0 plus a static typed route-helper file — decision #23. |
| Immutable models / unions | `freezed` | **Unresolvable**, not merely unwanted: `analyzer >=9.0.0 <11.0.0` conflicts with both `drift_dev` and `build_runner`. drift rows plus hand-written `@immutable` / `sealed` classes — decision #16. |
| Dependency injection | `get_it` | Rejected. Riverpod 2.6.1 is the whole DI root; a second DI system is a second mental model. |
| Any runtime permission | `permission_handler` | Rejected. Every permission has a first-party request API on the plugin that needs it; its CocoaPods `PERMISSION_*` macro block is an App Store rejection risk — decision #78. `shed-platform-gateways` owns the per-plugin policy. |
| Printing / PDF fonts | `printing` | Rejected. Depends on `http`, and `PdfGoogleFonts` / `networkImage` are one-line footguns that turn this into a networked app. `pdf` plus `share_plus` → the OS Print action — decision #83. |
| Anything at all | `http` | Never a direct dependency. It is in the lockfile transitively and that is documented; adding it directly voids the product's central claim. |

If the need is real, the answer is the alternative in the §5.3 row — not the package.

---

## 4. `net.*` and `layer.import` — G3

| Id | Fires on | Under |
|---|---|---|
| `net.http_client` | `HttpClient(` | `lib/` |
| `net.socket` | `Socket.connect(` | `lib/` |
| `net.image_network` | `Image.network(` | `lib/` |
| `net.pdf_fonts` | `PdfGoogleFonts` | `lib/` |
| `net.sync_timer` | `Timer.periodic(` | `lib/` |
| `layer.import` | a banned `package:` URI (`http`, `dio`, `connectivity_plus`, `workmanager`, `battery_plus`, `web_socket_channel`, `firebase_*`, `google_fonts`, `printing`, `speech_to_text`, `google_mlkit_*`, `permission_handler`) | any scanned file |

**What it means.** Our own source reached — or could reach — a network API. The `net.*` text rows and
the banned-package set are deliberately not redundant: `HttpClient` and `Socket` come from `dart:io`,
which any file may legitimately import, and `Image.network` is in the Flutter SDK, so none of them
arrives on a `package:` URI.

`net.sync_timer` is a different failure with the same shape: per-row timers **and** sync loops are
both banned. The one app-level ticker uses `Future.delayed`, so this rule needs no exemption
(decisions #66, #7).

**The real fix.** Delete the call. There is no offline-safe use of any of these in this app. For a
remote image there is no requirement; for a font, bundle the TTF.

**The forbidden fix.** An `[exempt]` line. `HttpOverrides.global` as a "runtime belt" — it is a belt
over a manifest brace that already makes sockets impossible on Android, and it proves nothing on iOS.

---

## 5. `layer.*` — the eight dependency rules

`layer.domain` · `layer.core_db` · `layer.data` · `layer.data_no_material` · `layer.features` ·
`layer.sibling` · `layer.core_ui` · `layer.single_writer` · `layer.root` · `layer.data_no_validation`
· `layer.direction` · `layer.path_provider`.

The table of what each layer may and may not import is `01-architecture.md` §3.1. Three that fire
most often:

- **`layer.sibling`** — `lib/features/<a>/` imported `lib/features/<b>/`. The message names the fix:
  move the shared piece into `lib/data/` or `lib/domain/`. This is the rule that rots first.
- **`layer.domain`** — something in `lib/domain/` imported Flutter, drift, Riverpod, `intl` or
  **`package:clock`**. A pure function that needs the current instant takes it as a parameter
  (`timeSincePenned(enteredAt, now)`), so that safety-critical arithmetic stays testable.
- **`layer.single_writer`** — a mutating drift API or `customStatement(` outside `lib/data/` /
  `lib/core/db/`. A raw statement also bypasses drift's stream tracking, so the UI silently stops
  updating.

**The forbidden fix.** Widening `_mayImport`. Adding a layer prefix. Re-exporting the banned symbol
through an allowed file — that defeats the rule while passing the gate, which is worse than a red
build.

---

## 6. `time.*`, `rp3.*`, `stream.*`, `db.*`, `stat.*`

| Id | Means | Real fix |
|---|---|---|
| `time.dart_clock` | `DateTime.now(` outside its one allowlisted file | `appNow()`. `lib/core/time/app_clock.dart` is the only home (decision #46). |
| `time.sql_now_1..5` | `date('now')`, `datetime('now')`, `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME` | All time arithmetic happens in Dart; SQL compares and orders opaque integers and sortable date strings (#47). |
| `rp3.*` (13 rows) | A Riverpod-3 API. Several **compile** on 2.6.1 and mean something else — the analyzer will not save you, and every tutorial published after 2025 shows the 3.x form | The 2.6.1 spelling is `02-state-di-navigation.md` §2.4's table, which owns these rows. |
| `stream.combine` | `combineLatest` over drift streams — two streams updated in one transaction can emit at different times (torn state, drift#3338) | One SQL statement per screen (#12). |
| `stream.invalidate` | `ref.invalidate(` — drift already tracks tables; manual invalidation is a stale read — **except the two architected arguments**, which the pattern excludes by lookahead since 2026-08-02 | Delete it (#12). If the gate fired, your argument is **not** one of the two architected call sites — `minuteTickProvider` on resume (02 §9.1) and `databaseProvider` at restore step 14 (04 §7) — and those two are already green. Neither is a drift-backed read. Do **not** reach for an `[exempt]` line: it would delete the rule for that whole file, and the allowlist is fixed at four (R56). |
| `db.raw_statement` | `customStatement(` under `lib/data/` | Move it to `lib/core/db/` or express it in drift. |
| `stat.zero_default` | `?? 0` under `lib/features/season/` or `lib/features/flock/` | Unknown is not zero. `StatResult` carries `notComputableReason` (#58). |

`db.*` rows about schema and migrations belong to `shed-drift-schema`; this file only tells you which
id fired.

---

## 7. `a11y.*`, `gesture.*`, `token.*`, `main.*`, `ui.*`, `copy.*`

| Id | Means | Real fix |
|---|---|---|
| `a11y.scale_factor` | `textScaleFactor` — deprecated, and clamping defeats the OS curve | `MediaQuery.textScalerOf`; never clamp globally (#99). |
| `a11y.header_bool` | `header: true` — a no-op on both platforms since 3.44, and it still compiles | `headingLevel: 1..6` (#104). |
| `gesture.dismissible` / `gesture.draggable` / `gesture.tooltip` | The gesture ban: no swipe-to-delete, drag, or hover/long-press affordance | One simple pointer action per action (#101). |
| `token.raw_color` / `token.material_color` | `Color(0x` or `Colors.` under `lib/` — scoped to `lib/`, not `lib/features/`, because `lib/core/ui/components/` is exactly where a shared widget hides a hex (R55) | Read `ShedTokens` (#97). |
| `main.no_await` | `await ` in `lib/main.dart` — `main()` awaits nothing (#21) | Move the work after the first frame; `shed-bootstrap-and-errors` owns the order. |
| `ui.spinner` | `CircularProgressIndicator` under `lib/features/` | The empty state occupies the box the content will occupy; never a spinner (#71). |
| `copy.*` | A banned phrase, a re-typed disclaimer, or a currency literal | Reference `Disclaimers.exportFooter`; never re-type it (#62). **Never write "your data never leaves your phone"** — the permitted wording is decision-record §3.1, verbatim. |

**`[exempt]` has exactly four lines on day one** (`CONVENTIONS.md` R56): `app_clock.dart ::
time.dart_clock`, `night_error_panel.dart :: token.raw_color`, `primitives.dart :: token.raw_color`,
`palettes.dart :: token.primitives_import`. A fifth is a review conversation with the owner — it is
never something you add to clear a red build.

---

## 8. G1–G5 when they fire

| Gate | Owner | Fires when | Real fix | Forbidden fix |
|---|---|---|---|---|
| **G0** | `shed-release` | Not a job — a one-afternoon empirical procedure that must complete before any `tools:node="remove"` line is committed. **Closed 2026-08-01**; `13-build-ci-release.md` §2.2's table carries four answers and four dates | Nothing, unless the dependency set moved. Re-run on any Billing Library bump | Committing the `ACCESS_NETWORK_STATE` removal on faith. Three research notes hard-coded it; the measured answer is that it stays, and that a **transitive** telemetry library, not the billing AAR, is what declares it |
| **G1** | `shed-release` | The shipped AAB's `uses-permission` set differs from `android/expected_permissions.txt`. It asserts **exact set equality**, not the absence of `INTERNET`, because the failure it exists for is a plugin bump quietly merging a *new* permission | Read `manifest-merger-release-report.txt` (G4) to find the contributing library, then decide whether that library stays | Editing `android/expected_permissions.txt`. If `android.permission.INTERNET` ever appears there, the product's central claim is void |
| **G2** | this skill | §2 above | §2 above | §2 above |
| **G3** | this skill | §4 above | §4 above | §4 above |
| **G4** | `shed-release` | Never fails — diagnostic only, archived as a CI artefact | It is the only thing that answers "*which* library added that?" | Treating it as a gate; its format is not a contract |
| **G5** | `shed-release` | The `NSAppTransportSecurity` text check fails, or a manual per-release check does | Remove the key. iOS has no `INTERNET` analogue, so enforcement is construction plus observation — say so rather than implying parity with Android | Claiming iOS parity. Skipping the per-release App Privacy Report / `nettop` pass |

Three more anti-patterns, all previously written down by somebody: grepping
`build/app/intermediates/` (it accumulates debug and profile artifacts whose manifests *do* declare
`INTERNET`, so the grep fires on a stale directory and then gets deleted for being flaky);
`apkanalyzer` on an APK (the APK is not what ships); `HttpOverrides.global` as a fourth proof.

---

## 9. Failures that are not policy violations

- **`dart format --set-exit-if-changed` fails on a generated file.** That is a toolchain-pin
  mismatch — your Dart formatter and the version `build_runner` formatted with disagree. Fix the pin
  or regenerate. Never hand-format generated code, and note the analyzer's `exclude:` does not
  exclude anything from the formatter.
- **A promotion in `analysis_options.yaml` seems to do nothing.** `errors:` can raise a lint's
  severity only if the rule is enabled somewhere. `avoid_dynamic_calls` and `close_sinks` are in no
  default set and therefore appear twice, deliberately.
- **`flutter pub get` fails after a Flutter bump.** The SDK re-pins `meta`, `test_api` and `intl`
  exactly. Re-run the resolution matrix; a toolchain bump is its own commit with its own read of the
  `pubspec.lock` diff.
- **A build fails in plane mode on a cold cache.** `package:sqlite3`'s build hooks download a
  sha256-verified binary from GitHub at build time. Expected; documented in decision-record §3.4.
- **The gate exits 2.** `tool/policy_allowlist.txt` or `pubspec.lock` is missing. Restore the file or
  run `flutter pub get`. A gate that cannot read its own configuration has not passed — it has failed
  to run.
