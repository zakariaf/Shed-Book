# CR — Code review checklist

Spec §12 opens with *"These are non-negotiable and should be visible in the code review checklist."* This is that checklist, and it governs one thing: **where a reviewer's attention goes.** §1 lists everything a machine already proves, so you never spend a review comment on it. §2 lists what no gate can catch, starting with the five safety rules of spec §12 phrased as questions you ask of the diff. §3 is the ritual — read order, what you may wave through, and the one question about Quick Entry. Every item cross-links to the document that argues it, so the checklist stays short and the reasoning stays one click away. Read [`CONVENTIONS.md`](CONVENTIONS.md) before you use this file: it outranks every document here on any name, path, type or word, and a review comment that contradicts it is wrong.

**Toolchain this file is written against: Flutter 3.44.8 stable, Dart 3.12.2, `flutter_riverpod` 2.6.1 pinned exactly** (decision-record §2 row 1 and §5.1). Every version number below traces to decision-record §5 and to nothing else — not to a research note, not to memory, not to a tutorial. The Riverpod pin is load-bearing: 3.x cannot resolve alongside `drift_dev`, so every Riverpod-3-only API is a compile error here and every tutorial published after 2025 shows the wrong one.

**Doc-set state:** the set is complete — `CONVENTIONS.md`, `00`–`13`, this file and `REFERENCES.md` are all written. §1.13 carries the rows 08–13 brought with them and the gaps §1 still does not cover.

> **Decisions applied:** #10 (one source-scanning gate, not five) · #12 (one watched statement per screen, no `combineLatest`) · #13 (writes return `WriteOutcome`) · #18 (the banned Riverpod-3 API list) · #29/#30 (integer instants, text civil dates, no `dateTime()`) · #31 (no advice-bearing defaults) · #35 (in-memory tag match, no keypad debounce) · #37/#38 (forward-only additive migrations, the full from→to matrix) · #46 (one clock) · #47 (SQL-side time banned) · #51/#52 (the withdrawal sealed type and its **two** gates, no third) · #53 (timestamp provenance) · #54 (warnings are flagged, never fixed) · #55 (the `normalize*` scope) · #58/#59 (`StatResult`, never a bare nullable) · #62 (`Disclaimers` referenced, never re-typed) · #66 (one ticker) · #69 (undo per verb) · #91 (`EntryContext.liveEntry` cannot be blocked) · #97 (tokens, never a raw literal) · #99 (never clamp text scale) · #100/#101 (60 pt floor, the gesture ban) · #103 (commit then confirm) · #109 (`flutter_lints` + the strict analyzer block) · #110 (the test shape) · #114 (the overflow matrix) · #115 (`ensureSemantics()` before every guideline run) · #119 (coverage is reported, never gated) · #120 (tap budgets) · #121 (the CI job shape) · #122 (the offline gates G1–G3) · #124 (redaction). Offline contract §3.2 (G0–G5). §4: *"§12 'visible in the code review checklist' — PRESERVED, as a deliverable."* Owner rulings §7.0: tag OCR and voice tag entry cut from v1; tags unique among **active** animals only; UK/Ireland defaults; free tier season-primary, ewe cap secondary, never mid-entry, never 22:00–06:00.

---

## 1. CI already proves this

### 1.1 The contract this section makes with you

**If a property is listed in this section, do not review it.** A machine ran it, on this diff, before you opened the page. Reading the diff for a raw hex or a `DateTime.now(` is not diligence, it is duplicated work at the cost of the attention §2 needs.

Three corollaries, and they are the whole reason the section exists:

1. **A green build is a licence to ignore §1, not a licence to merge.** Everything in §2 is still unexamined.
2. **If a §1 property was violated and CI passed, the fix is a rule row, not a review comment.** Adding a row to `_bannedText` or `_bannedPattern` in `tool/check_policy.dart` is one line and it holds forever; a review comment holds until the next tired Tuesday. See [`01-architecture.md`](01-architecture.md) §3.2 — every document in this set adds rows to that table, and no document adds a second script.
3. **A weakened rule is worse than a deleted one, because it is invisible.** The only escape from a rule is a line in `tool/policy_allowlist.txt`'s `[exempt]` section, keyed `'<path> :: <id>'`, which shows up in the diff. `CONVENTIONS.md` R56 fixes the day-one count at **four**, and a fifth is a review conversation — it is the one review conversation this document tells you to have.

> **The fifth is already proposed, and it is unresolved.** [`08-platform-integration.md`](08-platform-integration.md) §9 requires `lib/data/notification_scheduler.dart :: notify.zoned_schedule` and states plainly that this takes the section "from R56's four lines to five". [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §10 asserts the opposite — "the day-one allowlist stays at CONVENTIONS R56's **four** entries". **Two written documents disagree and `CONVENTIONS.md` has not been amended.** Flag it in any diff that touches `tool/policy_allowlist.txt`; do not silently pick a side, and do not treat the count as settled until R56 says five. This is the doc set's own §12.4 rule applied to itself: a contradiction is reported, not repaired by whoever noticed it.

Run the same gates locally before you push:

```bash
dart run tool/check_policy.dart     # < 1 s, no Flutter needed. "policy ok" or exit 1.
make check                          # check_policy → dart format --output=none --set-exit-if-changed . → flutter analyze --fatal-infos --fatal-warnings
make test                           # flutter test --exclude-tags golden --test-randomize-ordering-seed random --coverage
```

Both targets are [`13-build-ci-release.md`](13-build-ci-release.md) §1.3's `Makefile`, verbatim. If your local `make check` and CI disagree, the toolchain pin is the first suspect — 13 §1.1 asserts `.fvmrc` and the workflow agree on **Flutter 3.44.8 / Dart 3.12.2** (decision-record §2 row 1), and a version from memory is a defect.

### 1.2 Layers, imports and the single writer

Proven by `tool/check_policy.dart`'s layer driver over `lib/` and `test/`, defined in [`01-architecture.md`](01-architecture.md) §3.1–§3.2 and tabulated in [`CONVENTIONS.md`](CONVENTIONS.md) §1.1.

| Proven | Rule id |
|---|---|
| `lib/domain/` imports no Flutter, no drift, no riverpod, no sqlite3, no intl, **no `package:clock`** | `layer.domain` |
| `lib/core/db/` imports no `lib/data/`, no `lib/features/`, no `lib/core/ui/`, no `material.dart` | `layer.core_db` |
| `lib/data/` imports no `lib/features/` | `layer.data` |
| `lib/data/` imports no `material.dart` / `cupertino.dart` | `layer.data_no_material` |
| `lib/features/` imports no `lib/core/db/`, no `package:drift/`, no `package:sqlite3` | `layer.features` |
| No feature imports a sibling feature | `layer.sibling` |
| `lib/core/ui/` imports no `lib/data/`, no `lib/core/db/`, no drift | `layer.core_ui` |
| `customStatement(` appears nowhere under `lib/data/`; `lib/features/` cannot reach drift at all | `layer.single_writer`, `db.raw_statement` |
| `lib/main.dart` and `lib/app.dart` import no drift, no sqlite3, no `lib/core/db/` | `layer.root` |
| **`lib/data/**` cannot import `lib/domain/validation/**`** — the structural mechanism behind spec §12.4 | `layer.data_no_validation` (R53) |
| `lib/main.dart` contains no `await ` | `main.no_await` |
| Any import direction not in `_mayImport` | `layer.direction`, `layer.import` |

### 1.3 Time

Defined in [`05-domain-correctness.md`](05-domain-correctness.md) §2.8 and §1.3.

| Proven | Rule id |
|---|---|
| No `DateTime.now(` under `lib/` outside the one exempt file, `lib/core/time/app_clock.dart` | `time.dart_clock` |
| No `date('now')`, `datetime('now')`, `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME` under `lib/` — including in migrations | `time.sql_now_1` … `time.sql_now_5` |
| No `Timer.periodic(` under `lib/` — the one ticker uses `Future.delayed`, so the rule needs no exemption | `net.sync_timer` |

> **Gap, and it is a human check until it closes.** [`07-screens.md`](07-screens.md) §21.1 and [`CONVENTIONS.md`](CONVENTIONS.md) §2.2 both say `clock.now(` outside `app_clock.dart` is banned, but [`01-architecture.md`](01-architecture.md) §3.2's `_bannedText` has a row for `DateTime.now(` only. Until a `time.ambient_clock` row lands next to it, **a repository calling `clock.now()` directly compiles, passes the gate, and violates R23.** 01's own Definition of Done already asserts the property it does not enforce — *"`clock.now(` appears in the same one file"* — which is the clearest possible sign the row is missing rather than deliberately absent. See **§2.8**.

### 1.4 Riverpod 2.6.1

Defined in [`02-state-di-navigation.md`](02-state-di-navigation.md) §2.2–§2.4. `flutter_riverpod` is pinned to **2.6.1 exactly**; every Riverpod-3-only API is banned, and this matters because every tutorial published after 2025 shows the 3.x form.

| Proven | Rule id |
|---|---|
| No `retry:` (a compile error on 2.6.1 — decision-record §6 overturned "mandatory, non-negotiable") | `rp3.retry` |
| No `ProviderContainer.test(` | `rp3.container_test` |
| No `tester.container` in `test/` | `rp3.tester_container` |
| No `Mutation<` / `ref.mutate(` | `rp3.mutation` |
| No `.valueOrNull`, `.requireValue`, `.hasValue`, `.asData` | `rp3.value_or_null` and its siblings |
| No `StateProvider`, `StateNotifierProvider` | `rp3.state_provider`, `rp3.state_notifier` |
| No `ChangeNotifierProvider` — [`02-state-di-navigation.md`](02-state-di-navigation.md) §2.4 lists it, but **it matches neither 01 §3.2 literal**, so today this is a human check (§2.14) | *no row yet* |
| No `isAutoDispose`, `ref.mounted`, `Ref` written as a type name | 02 §2.4 rows |
| No `overrideWith` / `overrideWithValue` under `lib/` — production has zero overrides | 02 §2.4 |
| No `go_router`, `GoRoute`, `context.go(`, `pushNamed(`, `onGenerateRoute` | 02 §2.4 |
| No `RestorationMixin` / `restorationScopeId` / `Restorable*` | 02 §2.4 |
| No `WillPopScope` | 02 §2.4 |

### 1.5 Streams and the read path

| Proven | Rule id | Defined in |
|---|---|---|
| No `combineLatest` anywhere in `lib/` | `stream.combine` | [`01-architecture.md`](01-architecture.md) §4.4 |
| No `ref.invalidate(` anywhere under `lib/` — drift tracks tables; manual invalidation is a stale read | `stream.invalidate` | [`02-state-di-navigation.md`](02-state-di-navigation.md) §3 |
| No `CircularProgressIndicator` under `lib/features/` — loading is a fixed-height placeholder or it is nothing | `ui.spinner` | [`07-screens.md`](07-screens.md) §1.4 |

> **`stream.invalidate` has no exemption and the codebase needs exactly one.** `CONVENTIONS.md` §3.3 and 02 §9.1 both require `ref.invalidate(minuteTickProvider)` on `AppLifecycleState.resumed` — one call, in `lib/app.dart`, restarting a wall-clock ticker with no database behind it. The rule is scoped to `lib/` with no `[exempt]` line in R56's four, so **as specified the gate fails the build on the one call the architecture mandates.** Either the row narrows to drift-backed providers (02 §3's own wording) or `lib/app.dart :: stream.invalidate` joins the allowlist. Until one of those lands, treat a red `stream.invalidate` on `app.dart` as expected and a red one anywhere else as a defect. This is the second of the three open gate questions (§1.3, here, §1.10).

### 1.6 Database, schema and migrations

Defined in [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §2.10 and §3.7, with the ids canonicalised by `CONVENTIONS.md` §4.7.

| Proven | Gate |
|---|---|
| No `DROP TABLE` / `DROP COLUMN` in `lib/core/db/` | `db.destructive_ddl` |
| No `store_date_time_values_as_text` in `build.yaml` | `db.banned_build_option` |
| No `dateTime()` in any table definition | `db.drift_datetime` |
| No `db.` or a today-schema table class inside a `from<N>To<N+1>` callback | `db.migration_today_schema` |
| No `validateDatabaseSchema()` inside a synchronous `assert` | `db.async_in_assert` |
| No BLOB columns | `db.blob_column` |
| No `save\w*\(` under `lib/data/` — event verbs, never `save()` | `db.save_verb` (`CONVENTIONS.md` §4.7) |
| No `schedule(` on a reminder object — the method is `ReminderReconciler.reconcile()` | `db.reminder_schedule` (R51) |
| `path_provider` is confined to its gateway | `layer.path_provider` |
| **Every from→to migration pair validates**, `foreign_key_check` is empty and `quick_check` is `ok` on every path — N²/2 tests generated by a loop, so bumping `kSchemaVersion` extends the matrix automatically | `test/drift/migration_matrix_test.dart` |
| Rows written at N-1 are readable and correct at N | the N-1→N data-integrity test (**hand-written — see §2.16**) |
| Opening a v(N) file with v(N-1) code throws instead of migrating | `test/drift/downgrade_test.dart` |
| `drift_schemas/` holds exactly `kSchemaVersion` snapshot files | snapshot-count test |
| `make-migrations` produces no diff — the committed snapshot describes the committed schema | the codegen-freshness step; 04 calls it *"the single most valuable line of CI in the project"* |
| Every `NOT NULL` column with no `defaultValue` and no `clientDefault` is a primary key, a `uid`, or present in `importDefaults` | the schema-JSON completeness test, 04 §6.7 |
| Every foreign key is hand-indexed (`app_settings` is the one allowlisted exemption) | the index test, [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §2 convention 3 |
| Every stored vocabulary key belongs to that column's own `list` | `test/data/vocab_list_scope_test.dart` |
| Every seeded vocabulary key has a matching ARB message, and the two sets are equal — 40 keys, 40 messages, mapped `vocab_terms.key` → `'vocab' + upperCamel(key)` | `test/policy/vocab_labels_are_complete_test.dart`, 03 §10.1 + [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §8.6 |

### 1.7 Design tokens, theme and typography

Defined in [`06-design-system.md`](06-design-system.md) §3.5. Scope is `lib/**` for all of these (R55), skipping `*.g.dart` and `*.drift.dart`.

| Proven | Rule id |
|---|---|
| No `Color(0x`, no `Colors.`, no `Color.fromARGB(` / `Color.fromRGBO(` | `token.raw_color`, `token.material_color`, `token.raw_color_ctor` |
| No `ColorScheme.fromSeed` | `token.seeded_scheme` |
| No literal `fontSize:` | `token.literal_font_size` |
| No `colorScheme` read under `lib/features/` or `lib/core/ui/components/` — widgets read `context.tokens` | `token.color_scheme_read`, `token.color_scheme_read_ui` |
| `lib/core/ui/primitives.dart` is imported by exactly one file | `token.primitives_import` |
| No magic size in an `EdgeInsets`, `SizedBox`, `BoxConstraints`, `Size`, `Radius.circular`, or a `width`/`height`/`spacing`/`elevation`/`letterSpacing` argument (0 and 1 excepted) | `token.magic_size` |
| No `ThemeMode.system` / `.light`, no `Brightness.light`, no `platformBrightnessOf`, no `ColorScheme.light` / `ThemeData.light` — there is no light theme | `theme.*` |
| No deprecated `ColorScheme` roles (`background`, `onBackground`, `surfaceVariant`) | `theme.deprecated_scheme_role` |
| No `GoogleFonts` / `google_fonts` — a runtime font fetch is a network path | `type.google_fonts` |
| No `withClampedTextScaling` / `TextScaler.clamp` / `textScaleFactor` | `type.clamp`, `a11y.scale_factor` |
| No `FontWeight.w800` / `w900` / `black` / `extraBold` — they render *lighter* under Bold Text | `type.weight_cap` |
| **No `FittedBox` anywhere in `lib/`** | `type.fitted_box` |
| The launch-screen colour matches `nSurface04` in `primitives.dart` (the one rule that reads outside `lib/`) | `launch.colour_parity` — **its iOS storyboard half has not been run; 06 §9.4 flags it** |

### 1.8 Gestures and banned widgets

The gesture ban is decision #101 and [`06-design-system.md`](06-design-system.md) §7. **Eighteen rule ids**, each a literal or a pattern row, all scoped to `lib/` except where noted:

`gesture.dismissible` (`Dismissible(`) · `gesture.draggable` (`Draggable(`) · `gesture.tooltip` (`Tooltip(`) · `gesture.long_press_draggable` · `gesture.interactive_viewer` (`InteractiveViewer`, `ReorderableListView`) · `gesture.refresh` (`RefreshIndicator`) · `gesture.long_press` (`onLongPress*:`) · `gesture.scale` (`onScale*:`, `onForcePress`) · `gesture.drag` (`on{Horizontal,Vertical,Pan}Drag*:`) · `gesture.drag_handle` (`showDragHandle: true`) · `gesture.sheet_drag` (`enableDrag: true`) · `gesture.slider` (`Slider`, `RangeSlider`, `CupertinoPicker`) · `gesture.horizontal_swipe` (`PageView`, `TabBarView`) · `gesture.raw_snackbar` (`showSnackBar(` under `lib/features/` — call `confirmSaved` instead) · `ui.show_dialog` (`showDialog(` outside the two allowlisted destructive files) · `a11y.announce` (`SemanticsService.announce`, a no-op on Android) · `a11y.header_bool` (`header: true`, a no-op since 3.44 — use `headingLevel`) · **`a11y.material_picker`** (`showDatePicker(`, `showTimePicker(` — the dial is a drag, the keyboard mode is the system IME, and the cells are under 60 pt; [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §6.2).

Fourteen of those are `gesture.*`. [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §10 says "the eleven `gesture.*` rows"; 06 §3.5 plus 01 §3.2 print fourteen. **Count the table, never the sentence.**

### 1.9 Statistics

| Proven | Rule id | Defined in |
|---|---|---|
| No `?? 0` under `lib/features/season/` | `stat.zero_default` | [`05-domain-correctness.md`](05-domain-correctness.md) §6.1 |
| No `?? 0` under `lib/features/flock/` | `stat.zero_default2` | same |

**Those are the only two paths CI covers**, and the rule is the literal `?? 0` — nothing else. Everything in **§2.9** is about the rest, and [`09-export-formats.md`](09-export-formats.md) §9 names this checklist as the only gate on the export side.

### 1.10 Copy and content policy

| Proven | Gate | Defined in |
|---|---|---|
| No banned clinical phrasing in any string literal under `lib/**.dart` or any message value in `lib/l10n/*.arb` — and the guard is self-tested **in both directions**, because a guard that never fires is indistinguishable from a broken one | the `ContentPolicy` scan, `test/policy/` | [`05-domain-correctness.md`](05-domain-correctness.md) §7.3 |
| `Disclaimers.exportFooter` is defined in exactly one place and never re-typed | `copy.disclaimer_retyped` + the single-definition test | 05 §7.4 |
| No currency symbol followed by a digit under `lib/` or `assets/` — the price is `ProductDetails.price` | `copy.currency_literal` | `CONVENTIONS.md` §4.7 |
| No base64 in the backup | `copy.base64_backup` | 04 |
| Every export artefact carries the footer | one golden per format, `test/policy/` | 05 §7.4 |
| No numeric default reaches a withdrawal field | `test/policy/withdrawal_has_no_default_test.dart` (schema JSON) + the untouched-field widget test | 05 §3.9 |

> **Not proven, and it is now named in four documents.** The banned phrase *"your data never leaves your phone"* is described by [`07-screens.md`](07-screens.md) §21.1 as banned *"as literal text anywhere in `lib/` and `assets/`"*, by [`13-build-ci-release.md`](13-build-ci-release.md) §2.1 as banned by `tool/check_policy.dart` under `lib/` and `assets/`, and by `CONVENTIONS.md` §5.3 — but **no document prints a rule id for it, and `_bannedText` in 01 §3.2 has no row.** Per `CONVENTIONS.md` §4.7's namespace list this document names it **`copy.tier3_claim`** and flags the coinage as unverified until a document adopts it. Until the row exists, the phrase is a human check (§2.3). Note also that 13 §2.1 and §12 item 9 are explicit that **store listings and release notes are outside every scanner's reach** and are a manual pre-release item whatever happens to this row.

### 1.11 Offline purity and dependencies

The offline contract is decision-record §3; the gates are G0–G5 there and, with implementations, in [`13-build-ci-release.md`](13-build-ci-release.md) §2.2–§2.8. [`08-platform-integration.md`](08-platform-integration.md) §9 restates the same table for the plugin surface.

| Proven | Gate |
|---|---|
| Every `direct main`, `direct dev` and `transitive` lockfile entry is on the matching section of `tool/policy_allowlist.txt` — the three kinds checked separately, because `build_runner` legitimately drags `shelf` and `web_socket_channel` in as dev-only | **G2** — `dep.direct_main`, `dep.direct_dev`, `dep.transitive`; `tool/check_policy.dart` → `_checkLockfile`, blocking, every push |
| No `package:http`, `dio`, `connectivity_plus`, `workmanager`, `battery_plus`, `web_socket_channel`, `firebase_*`, `google_fonts`, `printing`, `speech_to_text`, `google_mlkit_*`, `permission_handler` imported anywhere scanned | **G3** — `_bannedEverywhere`, blocking, every push |
| No `HttpClient(`, `Socket.connect(`, `Image.network(`, `PdfGoogleFonts` — the three highest-risk socket APIs arrive on no `package:` URI at all, which is why they need their own rows | **G3** — `net.*`, blocking, every push |
| No `NSAppTransportSecurity` key in `Info.plist` | **G5**, text half only — the rest of G5 is manual, per release |
| The merged-manifest report is archived per build | **G4**, diagnostic only |
| Each plugin has exactly one import site, so its hand-written fake tests the real path | `layer.plugin_*` — [`08-platform-integration.md`](08-platform-integration.md) §1.2 |
| The Android notification channel-id set matches the committed schema JSON byte for byte (R49) | 08 §2.7 |

> **G1 is specified but not yet writable, and it is the row a reviewer most wants to trust.** 13 §2.3 implements it as `tool/assert_permissions.sh` diffing `bundletool dump manifest` on the release `.aab` against `android/expected_permissions.txt`. 13 §2.2 is equally explicit: *"Until this table is filled in, `android/expected_permissions.txt` does not exist and G1 cannot be written."* **Do not review a diff as though the eight-permission set were being asserted on every push.** It is not, yet.
>
> **Two more things are not proven and must not be reviewed as if they were.** **G0 has not been run**: removing `INTERNET` is proven, removing `ACCESS_NETWORK_STATE` is **not** — the only Play Billing AAR manifest anyone could fetch was 2.0.3, six majors behind 8.0.0. Until G0 runs against a real release AAB, *the offline gate in CI is unwritten, not merely unimplemented* (decision-record §1 item 5; 13 §2.2 carries the four-row table G0 fills in, every cell of which currently reads UNVERIFIED). And **iOS has no permission to remove**: G5 is construction plus one manual App Privacy Report / `nettop` check per release. Say so honestly; never imply parity with Android.
>
> **A gate that must never be written:** any *"no `http` in `pubspec.lock`"* rule. `http 1.6.0` sits on two regular edges (§2.17) and such a gate is unsatisfiable on day one. 08 §9 and decision-record §3.4 both say so; refuse it in review.

### 1.12 Tests that gate

Defined by decisions #110–#122; the per-screen shape is [`07-screens.md`](07-screens.md) §21.2 and the job matrix is [`13-build-ci-release.md`](13-build-ci-release.md) §4.2. **`12-testing.md` is the one document in the set still unwritten** (§1.13), so treat the table below as the live list and 12 as its eventual home.

| Proven | Test |
|---|---|
| **252 cells** — 14 pumpable variants × {375×667, 390×844, 430×932} × textScaler {1.0, 1.3, 2.0} × boldText {false, true}: no `RenderFlex` overflow, no exception (R58 — the decision record's 216 is superseded, and the arithmetic follows the variant list, never a remembered number) | `test/features/overflow_matrix_test.dart` |
| The primary action of Quick Entry, Lambing Entry and Foster is on screen without scrolling at the smallest device × textScaler 1.3 | the reachability assertion |
| **6 taps** unlock → committed lambing; **1 tap** foster reassignment from the Foster screen; **2 taps** repeat-last-treatment | `test/features/tap_budget_test.dart`, keyed finders |
| No monetization widget renders on any of the five shed screens at `unlocked: false, ewesInCurrentSeason: 99` | `test/features/no_monetization_test.dart` |
| 60×60 pt minimum tap targets plus a geometric gate for edge-flush and semantics-free nodes — every run begins `final handle = tester.ensureSemantics(); addTearDown(handle.dispose);`, without which the guideline throws instead of checking | `test/design/tap_target_test.dart` |
| Every published contrast ratio recomputes, including the documented AA exception for standard-contrast deep red | `test/design/contrast_test.dart` |
| One `tester.tap(); tester.tap();` per committing action — the double-tap guard | widget tests |
| No `ShedBanner` on the five shed screens; the cap never blocks `EntryContext.liveEntry` at any hour; entitlement is never revoked | `test/policy/{cap_never_blocks_live_entry,quiet_window_never_solicits,entitlement_is_never_revoked}_test.dart`, [`11-monetization-and-store.md`](11-monetization-and-store.md) §12.2 |
| A backup round-trips byte-for-byte, and no integer primary key is exported as identity | the round-trip test, [`09-export-formats.md`](09-export-formats.md) §7.3 |
| `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, `strict-casts` / `strict-inference` / `strict-raw-types` | `make check`, decision #109, 13 §1.3 |
| Tests run with randomized ordering; the `uk-zone`-tagged suite runs under `TZ=Europe/London` and the domain suite runs a second time under `TZ=Pacific/Chatham` | decision #121, 13 §4.2 |
| `.fvmrc` and the workflow both say **3.44.8**, and the runner is on it | 13 §1.1, three lines in `ci.yml` |

Two things deliberately do **not** gate: **coverage** (reported only — a percentage gate creates pressure to test `copyWith` while the DST cases stay unwritten) and **goldens** (~8 images, macOS, tag-triggered or manual, because GitHub bills macOS at a 10× multiplier and a per-push macOS build burns the Free plan's whole quota in a week). Do not ask for either in review.

### 1.13 The rows 08–13 add, and what §1 still does not cover

**Doc-set state, as of this revision.** Every document is written: `CONVENTIONS.md`, `00`–`13`, this file and `REFERENCES.md`. No gate in this checklist belongs to an unwritten document. If you are told a gate "belongs to an unwritten document", check the directory before you believe it.

These rows are specified by a written document and belong in the same single `tool/check_policy.dart` table (decision #10 — no document adds a second script). They are listed here so nobody adds a duplicate — a duplicate rule is a rule that gets weakened twice (R54) — and so no reviewer spends a comment on them:

| Rule id | Fails on | Scope | Owner |
|---|---|---|---|
| `layer.plugin_*` | a plugin imported outside its one gateway | `lib/` | 08 §1.2 |
| `media.opus` | `AudioEncoder.opus` — the container differs per platform, so a cross-platform restore breaks | `lib/` | 08 §9 |
| `media.keep_exif` | `keepExif: true` — re-attaches GPS (spec §4.5) | `lib/` | 08 §9 |
| `notify.use_exact_alarm` | `USE_EXACT_ALARM` — Play policy: alarm/calendar apps only | `lib/` | 08 §9 |
| `notify.alarm_clock` | `AndroidScheduleMode.alarmClock` — plants a system alarm icon | `lib/` | 08 §9 |
| `notify.recurring` | `matchDateTimeComponents` — recurrence state in the OS, DST drift | `lib/` | 08 §9 |
| `notify.zoned_schedule` | `zonedSchedule(` outside `NotificationScheduler` | `lib/` | 08 §9 — **needs the disputed fifth `[exempt]` line (§1.1)** |
| `share.static_api` | `Share.share` — deprecated static API | `lib/` | 08 §9 |
| `share.from_data` | `XFile.fromData` — writes a temp copy nobody cleans up | `lib/` | 08 §9 |
| `export.csv_bytes` | a `\r\n` literal or the BOM triple outside `lib/data/csv_writer.dart` | `lib/` | 09 §9 |
| `export.pdf_document` | `pw.Document(` / `pw.MultiPage(` outside `lib/data/pdf_writer.dart` | `lib/` | 09 §9 |
| `export.base_14_font` | `Font.helvetica` / `.times` / `.courier` / `.symbol` / `.zapfDingbats` — Latin-1 only, and they **throw** on a curly quote mid-export | `lib/` | 09 §9 |
| `export.share_static` | the deprecated static `Share.share*` API | `lib/` | 09 §9 |
| `export.intl_in_writer` | `package:intl` inside `csv_writer.dart` / `pdf_writer.dart` / `backup_format.dart` — a locale decimal comma shifts every column after the weight | those three files | 09 §9 |
| `a11y.sort_key` | `OrdinalSortKey` / `sortKey:` — tree order is traversal order | `lib/` | 10 §10 |
| `a11y.merge_semantics` | `MergeSemantics` — joins child labels with newlines and takes the first handler | `lib/` | 10 §10 |
| `a11y.material_picker` | `showDatePicker(` / `showTimePicker(` | `lib/` | 10 §10 |
| `copy.numeric_date` | `DateFormat.yMd` or any `DateFormat('…/…')` / `('….…')` — no all-numeric date a human reads (R60) | `lib/` | 10 §10 |
| `copy.literal_text` | `Text(` or `TextSpan(` opened with a string literal | `lib/features/` **only** | 10 §10 |
| `copy.arb_domain_noun` | a domain noun (`ewe`, `gimmer`, `theave`, `shearling`, `hogget`, `tup`, `wether`) literal in an ARB message, skipping the `term*Singular` / `term*Plural` messages | `lib/l10n/` | 10 §10 |
| `layer.in_app_purchase` | `package:in_app_purchase` imported outside `lib/data/purchase_service.dart` | `lib/` | 11 §12.1 |
| `launch.store_call` | `PurchaseService` / `InAppPurchase` / `purchase_service.dart` referenced from `lib/main.dart` or `lib/app.dart` | those two files | 11 §12.1 |
| `ui.monetization_surface` | `ShedBanner` outside `lib/features/flock/` and `lib/features/settings/` | `lib/features/` | 11 §12.1 |
| `db.entitlement_revoke` | `markLocked`, `revokeEntitlement`, or `unlocked:` assigned `false` / `Constant(false)` outside `lib/core/db/tables/` | `lib/` | 11 §12.1 |

> **The name these rules depend on is now in the catalogue.** `layer.in_app_purchase` and `launch.store_call` are keyed to **`PurchaseService`** (`lib/data/purchase_service.dart`), which [`CONVENTIONS.md`](CONVENTIONS.md) §2.12 carries as **R74** — six platform seams plus one store seam — with `purchaseServiceProvider` in §3.1 and the file in §1's tree. [`11-monetization-and-store.md`](11-monetization-and-store.md) §2 derived the spelling from §4.2, under which `PurchaseService` is the only permitted form (`Gateway` is not a class suffix and `Store` is reserved to `MediaStore`). Cite CONVENTIONS R74 when you enforce the name, and refuse any other spelling (`BillingService`, `IapGateway`, `StoreClient`) on §4.2 alone.

**Two driver amendments 10 §10 requires, and `01-architecture.md` must accept them:** the walker already reads `lib/l10n/*.arb` for the `ContentPolicy` scan and the two ARB rules reuse that reader (including its join-adjacent-literals behaviour, §2.3); and generated `lib/l10n/app_localizations*.dart` joins `*.g.dart` and `*.drift.dart` on the skip list, because every rule that fires on it is firing on the ARB twice. **If those amendments are not in 01 §3.2 when you review, the ARB rows are not live.**

**What §1 still does not cover, and these are §2 items even though they read like §1 items:**

- **`12-testing.md` is written**, and it carries R58's 252-cell figure (12 §7). Where this file, 07 §21.2 and 13 §4 also state a testing rule, 12 is the owner and the other three restate it.
- **A general "no user-facing string literal outside `lib/features/`" gate does not exist.** `copy.literal_text` deliberately stops at `lib/features/`, because `lib/core/ui/` takes its strings as parameters and `night_error_panel.dart` must contain literal English (10 §10). Those files are reviewed by hand — see §2.15.
- **The three coinage/conflict gaps:** `time.ambient_clock` (§1.3), the `stream.invalidate` exemption (§1.5), and `copy.tier3_claim` (§1.10). None is closed.
- **`flutter_timezone` is required and was never audited.** Decision-record §5.1 and 08 §11 item 1 both say so, and 08 calls it *blocking the first release build*. Audit it by c1's method and record the verified version in decision-record §5 *before* it enters a pubspec. Do not copy a version number out of a research note. See §2.17.

---

## 2. A human must check this

### 2.1 How to use this section

Ask each question **of the diff**, not of the codebase. If the diff does not touch the area, skip the question — this list is long because the app is small and the failure modes are specific, not because every review needs all of it.

Every item below has the same shape: **the question**, **the failure it prevents**, and **an example that passes every gate in §1 and is still wrong**. The examples are not hypothetical shapes; each one is a mistake the doc set predicts, and several were found while it was being written.

---

### The five safety rules of spec §12

These five are the reason this file exists. They are already mechanised as far as they can be — [`05-domain-correctness.md`](05-domain-correctness.md) §7.1 grades each one *unrepresentable* → *unconstructible* → *unpersistable* → *tested on source text* → *documented* — and the residue is yours.

#### 2.2 §12.1 — *Does anything in this diff put a number in a withdrawal field that the user did not read off the bottle?*

**Failure it prevents.** A shepherd sends milk or meat inside a withdrawal period on the app's authority. This is the highest-stakes code in the app and the only place where a wrong number hurts somebody who is not the user.

**Why CI stops here.** The sealed `WithdrawalPeriod` makes the wrong *state* unconstructible, and two gates prove it (05 §3.9): the schema JSON shows no `defaultValue`, no `clientDefault` and no `DEFAULT` in `customConstraints` on `treatment_withdrawals.days`; and a widget test asserts an untouched field saves **no row**, because absence *is* the state `WithdrawalNotRecorded`. Decision #52 allows exactly two gates. A third — a source heuristic hunting for numeric literals near the word "withdrawal" — only fires on `CHECK` constraints and fixtures, gets weakened, and a weakened gate is worse than none.

**Passes CI, still wrong:**

```dart
// lib/features/treatments/treatment_write_controller.dart
Future<void> repeatLast(TreatmentId source) async {
  final (treatment, withdrawal) = await _repo.readTreatment(source);
  await guard(() => _repo.recordTreatment(
        product: treatment.product,
        dose: treatment.dose,
        route: treatment.route,
        withdrawal: WithdrawalDays.asEnteredByUser(          // legal factory
          days: withdrawal.days,                             // NOT read off THIS bottle
          target: WithdrawalTarget.meat,
        ),
      ));
}
```

Every gate passes. The factory is the public one, there is no `?? 0`, the column still has no default. It is still a §12.1 violation, because NADIS is explicit that withdrawal periods *"can change for the same medicine and differ between products with the same active ingredient"* — the same trade name, bought twice, can carry two different numbers. **Repeat-last-treatment copies product, dose, route and batch and starts the withdrawal empty** (05 §3.10 path 1). Pre-filling every field except one reads as an oversight to whoever implements it next, so the reason belongs in a comment at the copy site.

Three more shapes that pass:

- `hintText: '28'` on the withdrawal field. A hint at 3am is a value.
- A "you usually enter 28 for this product" suggestion. That is a medicines lookup table the user built by accident, and it fails silently on the one bottle that changed (05 §3.10 path 2).
- A migration that populates a new withdrawal column from an older one. [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §2.7: *"no 'the old column said 7 so put 7 in the meat row'."* If a migration cannot populate a withdrawal without guessing, the correct migration leaves no row.

**Also check:** a soft-voided treatment (`voided_at IS NOT NULL`) is excluded from every "is she clear?" surface and its stored `clear_date` is **never** recomputed or blanked — it may already have been printed into a medicine book handed to a vet (05 §3.10 path 3). And the countdown widget takes a `ClearsOn`, never a `WithdrawalStatus`.

#### 2.3 §12.2 — *Does this diff originate a number or a judgement, rather than transform one the user supplied?*

**Failure it prevents.** The app makes a clinical decision for an animal it has never seen, and a shepherd acts on it.

**The line, from 05 §7.3:** *the app may arithmetic-transform a number the user supplied; the app may never originate a number that is a clinical decision.* Counting down from the N the user typed is fine. Suggesting N is not.

**Why CI stops here.** `ContentPolicy.bannedInUserFacingText` (`lib/domain/policy/content_policy.dart`) scans string literals under `lib/**.dart` and message values in `lib/l10n/*.arb` against **ten** patterns, and is self-tested in both directions. It matches *phrasings*. It cannot see arithmetic, and it cannot see a template whose dangerous part is the runtime substitution.

**Passes CI, still wrong:**

```dart
// lib/features/lambing/lamb_card_screen.dart
final l10n = AppLocalizations.of(context);
final target = (lamb.birthWeight.inKilograms * 50).round();
Text(l10n.colostrumTarget(ml: target));         // ARB: "Give {ml} ml"
```

No banned pattern matches. The dose regex is `\b\d+\s?(ml|mg|cc|iu)\s?/\s?kg\b` — it needs the literal `ml/kg` and there is none — and the ARB message is four innocuous words. It is nonetheless the exact case 05 §7.3 names: AHDB publishes *"50 ml/kg of colostrum within the first four to six hours"*, the app holds the birthweight, multiplying is one line and would be *helpful*. It is a dose suggestion and it is banned.

Three more that pass:

- A pen tile labelled **"Ready to turn out"**. The threshold is the user's, so the badge is legal — but only if the label says so: *"past your 24 h threshold"*, never *"ready"*. The word "ready" is the app making the clinical call.
- Pre-selecting a death cause from age-at-death or birthweight. A vocabulary the user picks from is fine; it becomes advice the moment the app infers one.
- A `DEFAULT` on any column that could encode a clinical value — lambing ease, `ewe_seasons.status`, withdrawal days (03 §2 convention 5).

**And a scanner gotcha worth knowing so you do not trust the guard further than it goes:** a naive `contains()` source scan **misses long strings**, because Dart wraps them across adjacent string literals and the phrase is never contiguous in the source text. The scanner extracts and joins literals before matching. If a diff adds a new scanning path, check it does the same.

#### 2.4 §12.3 — *Does this diff produce an artefact a shepherd could hand to an inspector, without the footer that says it is not one?*

**Failure it prevents.** The app is presented — by us or by a user acting on our framing — as a statutory medicine book, holding register or movement record. Spec §13 puts all three out of scope.

**Why CI stops here.** `Disclaimers` is an `abstract final class` (cannot be instantiated *or* extended, so nobody can subclass it and shadow a string), a single-definition test proves each string exists once, `copy.disclaimer_retyped` fires on a re-typing, and there is **one golden per export format** asserting the footer. [`09-export-formats.md`](09-export-formats.md) §9 hardened this considerably: `export.csv_bytes` confines CSV production to `lib/data/csv_writer.dart`, whose constructor **takes an `ExportEnvelope`**, and `export.pdf_document` confines `pw.Document(` / `pw.MultiPage(` to `lib/data/pdf_writer.dart`, which always sets `footer:`. Inside those two formats the footer is now structural.

**The hole that remains is a *third* format.** A writer that is neither CSV nor PDF goes through neither file, so neither row fires, and it has no golden until someone writes one.

**Passes CI, still wrong:**

```dart
// lib/data/export_repository.dart — a new plain-text "summary" a shepherd shares
Future<String> buildMedicineSummary(SeasonId season) async {
  final rows = await _treatmentsFor(season);
  return rows.map((r) => '${r.administeredAt} · ${r.product} · ${r.dose}').join('\n');
  // neither CSV nor PDF, so export.csv_bytes and export.pdf_document both look
  // elsewhere; no ExportEnvelope parameter; no footer; no golden yet
}
```

Nothing re-types a disclaimer, so nothing fires. The artefact ships without the sentence that makes it honest — and it is the medicine data, which is the artefact most likely to be handed to a vet. **Every writer takes an `ExportEnvelope`** (`lib/domain/policy/export_envelope.dart`, `ExportEnvelope.standard({now, appVersion})` is its only constructor, R65) and **every new format gets its golden and its `export.*` confinement row in the same commit.** A new format is on §3.3's never-wave-through list for exactly this reason.

**Also check:** the words *compliance record* and *official record* are banned in prose and in code (`CONVENTIONS.md` §5.3). A PDF whose page-2 header says "Medicine Record" while the footer sits on page 1 is the same failure with better typography.

#### 2.5 §12.4 — *Does this diff change a value the user entered, on the way in or on the way out?*

**Failure it prevents.** The shepherd's record stops being the shepherd's record. Spec §12.4: *"If a birth type of 'twin' has three lambs attached, flag it; do not fix it."*

**Why CI stops here.** The mechanism is structural and it is strong: `Warning` has no `fix()`, no `corrected`, no callback; `Reviewed<T>` has no `cleaned` getter; validators are pure top-level functions holding no writer; there is no `warnings` column, so nothing persists; and `lib/data/**` cannot import `lib/domain/validation/**`, so a repository *structurally cannot produce a `Warning`* (R53). What none of that stops is a **controller** — which is allowed to see validation — deciding to be helpful.

**Passes CI, still wrong:**

```dart
// lib/features/lambing/lambing_write_controller.dart
final lambs = await _repo.lambsFor(id);
final expected = expectedLambCount(type);
if (expected != null && lambs.length != expected) {
  // "obviously the birth type was mistyped"
  await guard(() => _repo.setBirthType(
        id, BirthType.values.firstWhere((t) => t.code == lambs.length)));
}
```

Every layer rule holds — this is a controller, and controllers may import `lib/domain/validation/`. No banned token appears. It is a textbook §12.4 violation: the contradiction was the record, and now it is gone. The correct behaviour is `WarningCode.birthTypeLambCountMismatch`, rendered as a persistent 60 pt amber strip under the field that reappears every time the record is opened, never blocks the save, and shows as a badge on the ewe card and the flock list so a contradiction found at 3am is still findable at 9am.

Four more that pass:

- **A migration that infers.** 04 §2.7: never infer a lambing ease, a birth type, a cause of death or a `barren` outcome from the absence of data; never "repair" a contradiction. *CI catches the SQL-side time ban and the `DROP` ban; it cannot catch "invented a domain value" — that is why migrations get reviewed at all.*
- **Garbage-collecting an abandoned entry.** A lambing with only a timestamp is a true statement — *something happened to this ewe at 03:20*. Silent deletion is §12.4 in the other direction (01 §4.5). Provide an explicit delete on the ewe card.
- **`int.tryParse(raw) ?? 0` or a `.trim()` that silently rewrites a tag.** The `normalize*` ban is on functions that **return a corrected domain value**; a projection like `tag_digits` stored *alongside* the verbatim `tag` is fine, and is never shown to a user (decision #55).
- **A warning that gates the save.** The save button is always live. A blocked save produces a lost record, which is worse than a flagged one.

**And check the export tells the truth:** the CSV carries `has_warnings` plus a `warnings` column of joined **codes** — codes, not localised messages — so the file states the data's condition without claiming to have fixed anything.

#### 2.6 §12.5 — *Does every event time this diff writes or renders carry its provenance?*

**Failure it prevents.** A time the app captured and a time the user typed become indistinguishable, so the record can no longer be defended.

**Why CI stops here.** `RecordedTime` makes the bare instant hard to get hold of, and the paired `CHECK`s make an inconsistent quad unstorable. But `Instant` is an extension type over an `int`, and formatting one is a legal, ordinary thing to do.

**Passes CI, still wrong:**

```dart
// lib/features/pens/widgets/pen_tile.dart
Text(formatHm(occupancy.enteredAt)),        // "03:21"
```

`CONVENTIONS.md` §5.4 is unambiguous: **every displayed event time carries its provenance label; a bare `03:21` is a review failure.** `RecordedTime.provenanceLabel` exists for exactly this and `formatters.dart` is the only place allowed to format.

Three more that pass:

- **An edit verb on a table without the quad.** R37 adds `captured_at` / `original_effective` / `time_source` to `PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations` before the first snapshot, and the standing rule until it lands is absolute: **a table without the quad has no edit verb.** An auto label must be unfalsifiable, not merely unchallenged.
- **A migration that moves an instant between columns** and does not carry `effective`, `capturedAt`, `originalEffective` and `TimeSource` as a unit (04 §2.7).
- **An all-numeric date in front of a human.** `d MMM y` — `11 Mar 2026`. Numeric dates exist only inside CSV, beside an ISO-8601 column (R60). The withdrawal countdown is the single worst place to break this, because the number it renders is the safety-critical one.

---

### The specific traps

#### 2.7 *Does every colour and every metric in this widget come from `context.tokens`?*

**Reason.** Three palettes plus a high-contrast slot only work if nothing bypasses them; a hard-coded grey is invisible in Deep red and illegible under a head torch. Argued in [`06-design-system.md`](06-design-system.md) §3.

**What §1.7 already catches:** every hex literal, `Colors.*`, `ColorScheme.fromSeed`, literal `fontSize:`, a `colorScheme` read inside a feature or a shared component, and magic numbers in the common size arguments.

**What it misses, and you must read for:**

```dart
const _gap = 12.0;                                   // named, so token.magic_size never fires
SizedBox(height: _gap * 2.5)                         // and now it is a metric nobody named
Opacity(opacity: 0.6, child: Text(...))              // a colour literal wearing a costume
DecoratedBox(decoration: BoxDecoration(color: t.surface.withValues(alpha: 0.4)))
```

A private const in a feature file is a token you failed to put in `ShedTokens`. An `Opacity` over a token colour produces a colour that was never contrast-tested — and `test/design/contrast_test.dart` only recomputes the palettes, not what a widget does to them.

#### 2.8 *Does anything read the wall clock outside `lib/core/time/app_clock.dart`?*

**Reason.** One clock, read through `Instant appNow()`, is what makes spec §12.5 testable and DST arithmetic reproducible. Two clock seams is worse than none, because a test that fakes one does not fake the other. Argued in [`05-domain-correctness.md`](05-domain-correctness.md) §1.3 and §2.8; R23.

**What §1.3 catches:** `DateTime.now(` under `lib/`, with `app_clock.dart` as the single allowlisted exemption.

**What it misses:**

```dart
final now = clock.now();                     // no row for this — see the gap note in §1.3
final t   = DateTime.timestamp();            // not `DateTime.now(`
final f   = DateTime.now;                    // torn off; the rule matches the open paren
```

Also: `lib/domain/` may not import `package:clock` at all (R24), so a domain function that needs the current instant **takes it as a parameter** — `timeSincePenned(enteredAt, now)`. A new pure function with a hidden time dependency compiles fine if it reaches the clock through a caller. And in `test/`, the rule is scoped to `lib/`: a test may write `DateTime.now()` and thereby become non-reproducible. Tests install time with `withClock(...)`, and `Clock.fixed` **freezes** `now()` — using it for an elapsed-time widget test makes the test silently measure 0 h (decision #113).

#### 2.9 *Does any nullable number in this diff acquire a zero it did not earn?*

**Reason.** `StatResult.value == null` means **not computable**. `?? 0` turns "we have not recorded that" into "you scored zero", and a shepherd quotes it over a gate. The same season yields 120% / 100% / 80% / 200% under four legitimate published definitions, so a bare number that is also a *lie* has no defence at all. Argued in [`05-domain-correctness.md`](05-domain-correctness.md) §6.1.

**What §1.9 catches:** the literal `?? 0`, under `lib/features/season/` and `lib/features/flock/`. That is all.

**What it misses:**

```dart
'${stat.value ?? 0.0}%'                                  // not `?? 0`
counts.firstWhereOrNull((c) => c.day == d)?.births ?? 0  // in lib/features/export/
final pct = numerator / (denominator == 0 ? 1 : denominator);   // worse: it invents a denominator
Text(result.value!.toStringAsFixed(1))                   // and this one just throws at 3am
```

The four-part UI and export contract is mandatory and is a review item in its own right: the `definition` string renders **under every headline number, always** — not behind an info icon; `numerator / denominator` renders too ("6 / 5"); the CSV and PDF carry the definition **verbatim**; and `notComputableReason` is displayed *as the value's replacement* — no blank cell, no `NaN`, no em-dash that might mean zero. The four definition strings are pinned literally (R61) and are exactly `lambs born alive per ewe put to the ram`, `lambs born incl. stillborn per ewe put to the ram`, `lambs born alive per ewe lambed`, `lambs reared per ewe put to the ram`; a paraphrase in a screen brief is a defect, because the same string is printed into files that outlive the app. [`09-export-formats.md`](09-export-formats.md) §9 lists `?? 0` on a nullable aggregate in its own anti-pattern table and names **this checklist** as the gate — so a statistics change in an export diff has no mechanical backstop at all.

#### 2.10 *Does anything in this diff make user text smaller than the user's own setting?*

**Reason.** The product requirement is "legible at 18 pt in a head torch". `FittedBox` visually undoes the OS text-size setting — the single accessibility control this user actually needs. Argued in [`06-design-system.md`](06-design-system.md) §5.5 and §8.

**What §1.7 catches:** the `FittedBox` identifier anywhere in `lib/`, plus `withClampedTextScaling`, `TextScaler.clamp` and `textScaleFactor`.

**What it misses:**

```dart
MediaQuery(data: mq.copyWith(textScaler: TextScaler.linear(1.0)), child: ...)
Transform.scale(scale: 0.8, child: Text(ewe.tag))
Text(ewe.tag, maxLines: 1, overflow: TextOverflow.ellipsis)   // a truncated tag is a wrong tag
```

**Reflow, never clip.** The pen grid is `LayoutBuilder`-driven on a minimum tile width that scales with `MediaQuery.textScalerOf(context).scale(40)`; at 200% text it goes to one or two columns and scrolls. A shepherd who needs 200% text needs a bigger `26h`, not four columns of clipped numbers.

#### 2.11 *Is every action in this diff reachable by one discrete tap on a ≥60 pt target?*

**Reason.** Every banned gesture fails the same way: a cold, gloved, possibly wet thumb through a freezer bag cannot hold a tracked contact. A marginal contact mid-swipe reads as a tap; a long press cancels on a tremor. Argued in [`06-design-system.md`](06-design-system.md) §7; decision #101.

**What §1.8 catches:** eighteen rule ids, including `Tooltip`, `Dismissible`, `Draggable` and the Material date/time pickers.

**What it misses:**

```dart
Listener(onPointerMove: _drag, child: ...)                    // no row matches
RawGestureDetector(gestures: {ScaleGestureRecognizer: ...})   // no row matches
// inside lib/core/ui/feedback.dart — the ONE file allowed to call showSnackBar(,
// and gesture.raw_snackbar is scoped to lib/features/, so this fires nothing:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: ..., dismissDirection: DismissDirection.horizontal));
```

That last one throws away the one on-screen proof that a record committed. **Three bottom-sheet settings are not defaults and must be typed every time**, because Flutter's defaults are all permissive: `showDragHandle: false`, `enableDrag: false`, `isDismissible: false`, with an explicit ≥72 pt Cancel. The one permitted tracked gesture is vertical scrolling, and **no action is ever reachable only behind a scroll**.

#### 2.12 *Is any value on screen computed from more than one drift stream?*

**Reason.** drift#3338 is open and the maintainer's position is that torn emission *"generally is working as intended"*: two streams updated inside one transaction can emit at different times, so a combination of them shows a state that never existed in the database. A Pen Board built that way renders a pen whose ewe has already moved. Argued in [`01-architecture.md`](01-architecture.md) §4.4 and [`07-screens.md`](07-screens.md) §1.2.

**What §1.5 catches:** the literal `combineLatest`.

**What it misses** — and this is the common one, because no grep can see it:

```dart
// two independent watches, combined in one build() — no banned token anywhere
final pens = ref.watch(penBoardProvider);
final ewes = ref.watch(flockListProvider);
return Text('${pens.value!.length} pens · ${ewes.value!.length} ewes');
```

Also `StreamZip`, `Stream.multi`, and an `await for` over two streams. The enforceable rule is 07 §1.2's: **every screen has exactly one *content* statement, and no displayed value may be computed from two drift streams.** Anything else the screen watches must be a single-row lookup or an app-level singleton (`settingsProvider`, `entitlementProvider`, `tagIndexProvider`, `minuteTickProvider`). Two independent widgets watching two independent streams is fine — torn emission only hurts when you combine. **Fan-in happens in SQL** (`WITH … UNION ALL`), not in Dart.

Two adjacent questions while you are here: does the new stream `.distinct()` **in the repository** (never in the widget — `List` equality is identity, so list results need a comparator)? And does every aggregate go through `customSelect` with an explicit `readsFrom:` — without it drift cannot track the statement and the stream silently stops updating.

#### 2.13 *Did this diff add a debounce, or grow one?*

**Reason.** The keypad path has **no debounce at all** and must not acquire one: `rankTagMatches` is pure and synchronous, so the list updates in the same frame as the keystroke, and there is no `await` between a digit and a redraw. Debouncing a sub-millisecond operation is cargo cult and it puts visible lag between the thumb and the digit. Argued in [`02-state-di-navigation.md`](02-state-di-navigation.md) §7.1 and §10, [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §9.1, decision #35.

**Exactly two debounces exist in `lib/`, and a third is a defect:**

| Where | Value | Rule |
|---|---|---|
| Free-text fields (notes, tag entry) | **400 ms** | The ceiling. Also commit on focus loss, on route pop (`PopScope`, `canPop` stays `true`), and on `AppLifecycleState.inactive`. Worst-case loss is 400 ms of typing. |
| Full-text note search, on its own screen | **200 ms** | Never on the keypad path. |

**This is the number's home.** 01 §4.5 and 02 §7.1 both say the 400 ms figure is written down here *"so it cannot silently grow"* — so a diff that changes it changes this file, in the same commit, and the reviewer asks why. `ReminderReconciler.reconcile()` is separately debounced to once per 500 ms; it is not a filter and it is not one of the two.

**The grep, from 02's Definition of Done:** `Duration(milliseconds:` near a `Timer`.

#### 2.14 *Does every write go through a repository, in exactly one transaction, in the right order?*

**Reason.** `lib/data/` is the only layer that writes. Draft state is unrepresentable because there is no aggregate to defer — *"a team convention 'always commit immediately' survives until 11pm on a Tuesday; a write API with no aggregate parameter survives forever."* Argued in [`01-architecture.md`](01-architecture.md) §4.

**What CI catches:** `lib/features/` cannot import drift at all, so a widget cannot open a transaction; `db.save_verb` fires on `save\w*(` under `lib/data/`; `stream.invalidate` fires on `ref.invalidate(` after a write. **CI cannot catch a badly-shaped repository method** — 01 §4.5 names the review question explicitly.

Ask, in this order:

1. **Does any repository method take a whole aggregate?** `saveLambing(Lambing whole)` is the failure. Verbs are events: `setBirthType`, `setEase`, `addCare`, `correctOccurredAt`.
2. **Is the clock read exactly once, at the top, via `appNow()`?** Two rows written in one mutation must not disagree by a millisecond.
3. **Is media written *before* the transaction, outside it?** A failed file write must leave no row. An orphaned file is garbage the sweep collects; an orphaned row is a broken record.
4. **Is every statement inside exactly one `_db.transaction`, and every one `await`ed?** drift is explicit that un-awaited work escapes the transaction and can silently lose data. Treat any drift runtime warning about this as a P0. Single-statement mutations get a transaction too — uniformity is the point, because the next edit that adds a second statement is already inside the boundary.
5. **Is every gateway call *after* the transaction returns?** Never call a platform channel inside a drift transaction: it round-trips through another isolate while holding the write lock.
6. **Does the verb return `WriteOutcome`?** The only two exceptions are `beginLambing` and `addLamb`, which return an id and **throw** (R32). `createEwe` is *not* in that set — it is the one create verb the cap can refuse.
7. **Are bulk writes one transaction?** Restore, seeding, and repeat-treatment-for-a-batch. 5,000 individual inserts notify every watching stream 5,000 times.
8. **Did anything show success before the transaction returned?** There is no optimistic UI; the three channels — haptic, persistent receipt with Undo, list mutation — all fire on `WriteCommitted`.

**And the five Riverpod questions only a human can ask** ([`02-state-di-navigation.md`](02-state-di-navigation.md) §2.4–§2.5, none of them a soft preference): `ref.watch` inside a callback; `ref.read` inside `build()`; a derived collection exposed as a getter rather than a stored field computed in a factory; **`AsyncValue.value`** — the other four accessors are distinctive enough to grep, but bare `.value` collides with `MapEntry.value`, `ValueNotifier.value` and every drift companion field, so only a reviewer can see it; and **`ChangeNotifierProvider`**, which 02 §2.4 bans and 01 §3.2's `_bannedText` does not match (§1.4). Anything the user typed lives in a **private field** on the notifier, not only in `state`.

#### 2.15 *Is every string a human reads in this diff an ARB message?*

**Reason.** Two failures, and the second is the expensive one. A hard-coded string is invisible to the terminology system, so a farm that calls a ewe a *theave* gets "ewe" anyway — and terminology is spec §7.10, not a nicety. It is also invisible to whichever half of the §12.2 content-policy scan it dodged.

**What CI now catches**, since [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) §10 landed: `copy.literal_text` fires on `Text(` / `TextSpan(` opened with a string literal under **`lib/features/` only**; `copy.arb_domain_noun` fires on a domain noun typed literally into an ARB message; `copy.numeric_date` fires on `DateFormat.yMd` and on any `DateFormat` pattern containing `/` or `.`; and `test/policy/vocab_labels_are_complete_test.dart` proves the 40 seeded `vocab_terms` keys and the 40 ARB messages are the same set, mapped `key` → `'vocab' + upperCamel(key)`.

**What it still misses, and this is yours:**

- **`lib/core/ui/` is out of scope on purpose.** Components take their strings as parameters, `feedback.dart` builds its label from a `SaveReceipt`, and `night_error_panel.dart` must hold literal English because it renders outside `Localizations` by construction. A literal that creeps into a shared component is caught by nothing.
- **A string that reaches a human without passing through `Text(`** — a `semanticLabel:`, an `onTapHint:`, a `SnackBar` content built from a `String` variable, an export column header. `copy.literal_text` matches a constructor opening, not a destination.
- **Whether the message is *right*.** 10 §8.4 house rule 2 makes `description` non-optional — held by `test/policy/l10n_bootstrap_test.dart`, **not** by `required-resource-attributes: true`, which was measured on 3.44.8 and only fails on a missing `@key` block (10 §8.4 rule 2) — and requires the description to carry the safety rationale — because that description is what stops a future contributor "improving" `withdrawalSource` away from *"as entered by you"*, which is a spec §12.1 requirement and not a style choice. A new message with a hollow description is a defect.

**The three homes, no overlap** (R66): keys → `lib/core/db/seed/first_run.dart`; labels → `lib/l10n/app_en.arb`; `assets/content/` → only authored prose too long to be a UI string, plus one provenance line per vocabulary list. The "no verbatim third-party copy" check scans **both** `assets/content/` and `lib/l10n/`, because the provenance lines live in the first and the labels in the second, and a check pointed at one of them misses whichever half the copy was pasted into. The lambing-ease descriptions are **paraphrased, never adopted verbatim** — the cited SRUC technical note is image-based and its text and licence terms **could not be verified** (decision-record §6; 10 §8.6).

**Exactly three exceptions exist**, and adding a fourth is a review conversation (10 §8.7): the six `ShedFailure.userMessage` strings, which must render when the database is unreadable; `Disclaimers.*`, because a translator can drop or soften an ARB string and the app has no mechanism to notice; and `NightErrorPanel`'s copy, because a `Localizations` lookup inside the crash handler is a crash inside the crash handler. Stable machine keys — `time_source`, `WithdrawalTarget`, `LambCount`, `AnimalClass`, vocabulary keys, CSV headers — are contracts, not copy, and are never ARB messages either.

#### 2.16 *Is the new column nullable or structurally defaulted — and was the matrix extended where it is hand-written?*

**Reason.** A user can sit on v1.0 for two seasons and update straight to v2.4. There is no server to run a backfill, no way to push a hotfix to a phone that has never been online, and no cloud copy if a migration eats a table. A red migration test is ship-blocking. Argued in [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §2 and §3.

**What §1.6 catches:** destructive DDL, `dateTime()`, today-schema references inside a step, the from→to matrix (generated by a loop, so it extends itself when `kSchemaVersion` bumps), `foreign_key_check` and `quick_check` on every path, the snapshot count, the codegen no-diff, the `importDefaults` completeness test, and FK indexing.

**What it misses:**

1. **Whether the column should be nullable at all.** A `NOT NULL` column with no default cannot be added to a table that already has rows, so a "default" gets invented — and *no column that could encode veterinary advice carries a `DEFAULT` or a `clientDefault`* (03 §2 convention 5). If both are true, the column is nullable. `NULL` and an explicit "unknown" value are **different facts** and both are modelled where both exist (`lambs.sex IS NULL` = not recorded; `= 'unknown'` = the shepherd looked and could not tell). Never collapse them.
2. **Whether the `importDefaults` entry is *correct*, not merely present.** The completeness test proves a key exists. It cannot know the value is right, and that map is what stops a v4 app refusing to restore a v2 backup on the night it matters.
3. **The N-1→N data-integrity test is hand-written** (04 §3.3), as is the downgrade test. The from→to *schema* matrix extends itself; these do not.
4. **`@DataClassName` on any table that does not singularise by dropping one `s`** (03 §2 convention 9). drift generates `PenOccupancie`. Renaming a row class after the first snapshot is a whole-codebase edit for zero behaviour change.
5. **`CHECK` constraints cannot be added by `ALTER TABLE` afterwards** without a full table rebuild. R62's three `media_assets.relative_path` checks and R37's provenance quad must land **before the first schema snapshot**.
6. **Whether the migration writes a domain value** — see §2.5. A migration may write `0`, `NULL`, an empty string, a copied column value, a `newUid()` or an `appNow()` instant. It may never write a withdrawal, an ease, a birth type, a death cause or a `barren` outcome.
7. **Whether a column's *meaning* changed in place.** New meaning ⇒ new column ⇒ new name. A column that meant "kg × 10" and now means "grams" is a silent corruption no test catches and no user notices until the season summary is wrong.
8. **Whether it all landed in one commit.** `schemaVersion`, the step, the regenerated snapshot and the regenerated helpers, together or not at all.

> **Unverified and relevant to any schema review:** whether drift's `SchemaVerifier` tolerates FTS5 shadow tables has not been established on a real run (04 §3.4). Do not assume a green matrix has proved the search tables.

#### 2.17 *Does this diff add a dependency — and if so, where is the audit?*

**Reason.** Tier 1 + tier 2 of the offline contract is the only thing the product may claim in public, and it is *"only true if the drops in §4 actually happen."* One plugin with a Play-Services-adjacent transitive graph contributes `INTERNET`, trips the app's own G1 gate, and ends the claim.

**What CI catches:** G2 fails the build on any lockfile entry not on the matching allowlist section. **That failure is the review.** The diff will contain a line added to `tool/policy_allowlist.txt`, and your job is to refuse it until the audit exists.

**The audit, by c1's method, and all five parts are required:**

1. **Version and publisher from the pub.dev API** (`https://pub.dev/api/packages/<name>`), not from memory and not from a research note. Every version in this project comes from decision-record §5 and nowhere else.
2. **The transitive graph**, read for network edges. `http 1.6.0` is already in the graph on two regular edges (`flutter_local_notifications → timezone` and `wakelock_plus → package_info_plus`); that is unavoidable and documented, and **any "no http in pubspec.lock" gate is unsatisfiable and must not be written.** A *new* http edge is a different conversation.
3. **The merged manifest** — which Android permissions it contributes. The permission set is eight entries and G1 asserts it exactly.
4. **Resolution against Flutter stable's pins.** `meta: 1.18.0` governs the entire dev-dependency set: no Flutter app can resolve `analyzer ≥ 13.1.0`, `build_runner` is `">=2.15.0 <2.15.2"`, and `package:test` is never a direct dependency because `flutter_test` does not depend on it.
5. **Whether it is even needed.** Decision-record §5.3 is a long rejected list, each row carrying the reason and the alternative. Read it before adding anything — `fl_chart`, `printing`, `google_fonts`, `freezed`, `go_router`, `custom_lint`, `permission_handler`, `file_picker`, `csv` and every charting package are all already answered.

**Two live items:** `flutter_timezone` is **required and unaudited** — decision-record §5.1 and [`08-platform-integration.md`](08-platform-integration.md) §11 item 1, which calls it *blocking the first release build*. Audit and record it before it enters a pubspec; do not copy note 06's version number. And `accessibility_tools` **2.8.0** is a debug-only widget that wraps the app tree, so **`lib/` imports it**: it is wired behind `kDebugMode`, it is on the allowlist, and its 48×48 default is *below* the spec's 60×60, so it complements the house assertion and never replaces it.

**Two audits that are already done and must not be re-opened.** Decision-record §7.0 rulings #5 and #6 cut tag OCR and voice tag entry from v1; 08 §10 records the reasoning so a future contributor does not reach for `google_mlkit_*` or `speech_to_text` again. Both fail **G2** the day they are added, which is the point — the gate is the memory, not the paragraph. A diff that reintroduces either is refused, not debated, and 08 §10.3 states the three conditions that would have to hold before v2 could revisit it.

---

## 3. The review ritual

### 3.1 Read the diff in order of irreversibility, not in the order it prints

| Order | What | Why it is here |
|---|---|---|
| 1 | `pubspec.yaml`, `pubspec.lock`, `tool/policy_allowlist.txt`, `android/expected_permissions.txt`, `.fvmrc` | A dependency changes what the whole product may claim. An `[exempt]` line deletes a rule for one file, forever, silently. A toolchain bump re-runs the whole resolution matrix and belongs in its own commit (13 §1.1). |
| 2 | `lib/core/db/tables/**`, `drift_schemas/`, `lib/core/db/migrations.dart` | Irreversible after the first snapshot. There is no server-side backfill and most users have no backup. |
| 3 | `lib/data/**` | The only layer that writes. Everything above it is recoverable; a bad write is not. |
| 4 | `lib/domain/withdrawal/`, `lib/domain/stats/`, `lib/domain/time/` | Arithmetic that is invisible when wrong. A wrong clear date hurts somebody who is not the user. |
| 5 | `lib/l10n/app_en.arb` | Every string a human reads, and the surface the §12.2 scan and the terminology system both act on. |
| 6 | `lib/features/**` | Last, and largely §1's problem. |

### 3.2 What you may wave through

- **Generated files.** `*.g.dart`, `*.drift.dart`, `drift_schemas/*.json`, `test/drift/generated/**` — never hand-edited, and CI proves they are fresh by regenerating and diffing. Read them only to confirm nobody hand-edited one.
- **Anything in a §1 table.** That is the whole point of §1. **The boxed notes in §1.3, §1.5, §1.10, §1.11 and §1.13 are the exceptions** — they name properties §1 does *not* prove, and they are the only part of §1 you still have to hold in your head.
- **Formatting.** `dart format --output=none --set-exit-if-changed .` runs in `make check`.
- **A widget-only diff that adds no string, no colour, no metric, no write and no gesture.** Rare, but real.
- **New cases added to an existing table-driven test.**
- **Coverage numbers and golden diffs.** Neither gates; asking for either in review is asking for the wrong work.

### 3.3 What you never wave through, however small

`lib/domain/withdrawal/**` · `drift_schemas/**` · the `[exempt]` section of `tool/policy_allowlist.txt` · `lib/domain/policy/disclaimers.dart` · `lib/main.dart` · any new export format · any table gaining an edit verb · `android/expected_permissions.txt` (editing it to make a red build green is 13 §2.8's named anti-pattern) · a `pubspec.lock` diff in a PR that does not also change `pubspec.yaml` (13 §1.2: something upstream moved and you are about to ship it).

### 3.4 The one question to ask about any change to Quick Entry

> **Does the shepherd have to do anything new before the record exists?**

Quick Entry is the product. It is the root route, never pushed; it is interactive at the first frame with the database still closed; and its budget — **6 taps from unlock to a committed lambing**, held by `test/features/tap_budget_test.dart` — is the only mechanical hold on spec §15's fifteen seconds. Four ways the answer is yes, in descending order of how easy they are to miss:

1. **A tap.** One more confirmation, one more disambiguation prompt, one more "which season?". The tag-disambiguation case is the canonical example: a re-used tag number moves off the 3am path onto the ewe card, deliberately.
2. **A wait.** An `await`, a `Timer`, a debounce, or a spinner between a digit and a redraw. `CircularProgressIndicator` is banned in `lib/features/**`; loading is a fixed-height placeholder that occupies the same box the content will occupy, so nothing shifts.
3. **A decision.** Anything that makes the shepherd choose before recording. The free tier is **season-primary with the ewe cap secondary**, and `EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap` — but a *prompt* is not a block, and neither may surface mid-entry, and neither may surface at all between **22:00 and 06:00**.
4. **A thing on screen that was not there before.** Quick Entry is a **shed screen**: nothing monetization-related renders on it, at any entitlement state, ever. The export banner is the one permitted addition, and all six of 07 §16.2's conditions hold before it renders — first launch of a local civil day, writes since the last export, not already prompted today, not dismissed for the season, **no ewe loaded and no lambing opened in this session**, and local time between 06:00 and 22:00.

If the answer is yes, the change does not land on Quick Entry. It lands somewhere calmer, in daylight.

---

## Definition of done

- [ ] A PR template exists at `.github/pull_request_template.md`, it links to this file, and it carries the five §12 questions from §2.2–§2.6 **verbatim**.
- [ ] Every rule id named in §1 exists as a row in `tool/check_policy.dart`, and each has been proven to fire once: plant a violation, confirm the failure, delete the file.
- [ ] `dart run tool/check_policy.dart` exits 0 on a clean tree and prints `policy ok`.
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section matches R56's count, each line has a reason in the commit message that added it, and **the 08-versus-10 disagreement over the fifth line (`notify.zoned_schedule`) is resolved in `CONVENTIONS.md` R56 itself** — not settled locally by whichever document was edited last (§1.1).
- [ ] The three gaps §1 names are closed or recorded as open with an owner: a `time.ambient_clock` row for `clock.now(` (§1.3); the `stream.invalidate` exemption or narrowing that lets `ref.invalidate(minuteTickProvider)` compile (§1.5); and a `copy.tier3_claim` row for *"your data never leaves your phone"* (§1.10).
- [ ] The two driver amendments 10 §10 requires are in `01-architecture.md` §3.2 — the `lib/l10n/*.arb` reader is shared, and `lib/l10n/app_localizations*.dart` is on the skip list — or the ARB rows in §1.13 are struck from §1 until they are.
- [ ] Every cross-link in §2 and §1.13 resolves to a live section in a written document, and no document is marked unwritten — the set is complete.
- [ ] `layer.in_app_purchase` and `launch.store_call` key to `PurchaseService` exactly as `CONVENTIONS.md` R74 spells it, and no second spelling (`BillingService`, `IapGateway`, `StoreClient`, `StoreGateway`, `PurchaseRepository`) has appeared anywhere in `lib/` or `test/`.
- [ ] The 400 ms free-text ceiling and the 200 ms note-search debounce appear in §2.13 and nowhere else as a mutable number; a diff that changes either changes this file in the same commit.
- [ ] G0 has been run against a real release AAB and its result — specifically, whether Play Billing 8.0.0 contributes `ACCESS_NETWORK_STATE` — is recorded in decision-record §3.3 **and** in 13 §2.2's four-row table, before any `tools:node="remove"` line is committed. Until then §1.11 lists G1 as *not writable*, and no reviewer treats the eight-permission set as asserted.
- [ ] `flutter_timezone` has been audited by the five-part method in §2.17 and its verified version recorded in decision-record §5.1, before it enters any pubspec.
- [ ] The toolchain pin is asserted: `.fvmrc` and `ci.yml` both say **3.44.8**, and no version number in this file was written from memory — every one traces to decision-record §5 or §2 row 1.
- [ ] A reviewer who has never seen the codebase can read §1, believe it, and start at §2 — confirmed by asking one.

---

## References

Only the sources this document cites. Fetched 2026-07-27 unless noted; every version number comes from decision-record §5 and never from memory.

**Project documents**
- [`../../shed-book-spec.md`](../../shed-book-spec.md) — §5 the 3am test, §7.1–§7.10 features, §9 screens, §12 the five safety rules, §13 not in v1, §15 success criteria.
- [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) — §1 the five pre-commit decisions, §2 the decision table, §3 the offline-purity contract and gates G0–G5, §4 dropped/degraded (including *"§12 … PRESERVED, as a deliverable"*), §5 the verified dependency table, §6 corrections applied, §7.0 the owner's rulings, §7.1 still open.
- [`../research/critique/c4-completeness.md`](../research/critique/c4-completeness.md) — finding 9, which asked for this file and named its two sections.
- [`CONVENTIONS.md`](CONVENTIONS.md) — the naming authority; §4.7 policy rule ids, §5 vocabulary, §6 rulings R22–R73.
- [`01-architecture.md`](01-architecture.md) · [`02-state-di-navigation.md`](02-state-di-navigation.md) · [`03-data-model-and-schema.md`](03-data-model-and-schema.md) · [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) · [`05-domain-correctness.md`](05-domain-correctness.md) · [`06-design-system.md`](06-design-system.md) · [`07-screens.md`](07-screens.md) · [`08-platform-integration.md`](08-platform-integration.md) — §1.2 the plugin confinement gate, §9 the new `media.*` / `notify.*` / `share.*` rows and the disputed fifth `[exempt]` line, §10 why OCR and voice tag entry are cut, §11 the open and unverified list · [`09-export-formats.md`](09-export-formats.md) — §4.3 the one PDF builder, §7.3 the round-trip test, §9 the five `export.*` rows · [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) — §8.4 the ARB house rules, §8.6 the 40 vocabulary labels, §8.7 what is deliberately not in the ARB, §10 the gate rows and the two driver amendments · [`11-monetization-and-store.md`](11-monetization-and-store.md) — §12.1 the four monetization rows, §12.2 the policy tests · [`13-build-ci-release.md`](13-build-ci-release.md) — §1.1 the toolchain pin, §1.3 the `Makefile`, §2.2 G0, §2.3 G1, §2.8 the gate table, §4.2 the job matrix, §12 the manual pre-release checklist.
- `12-testing.md` — **not yet written.** R58 requires it to carry the 252-cell figure; until it lands, §1.12 is the live list.

**Drift and Flutter issues cited as reasons**
- https://github.com/simolus3/drift/issues/3338 — torn state across two streams updated in one transaction (open). The reason `combineLatest` is banned (§2.12).
- https://github.com/simolus3/drift/issues/3295 — streams re-run on any write to a tracked table (open). The reason for `.distinct()` in the repository (§2.12).
- https://github.com/flutter/flutter/issues/139712 — `w800` renders *lighter* with Bold Text on. The reason for the w700 cap (`type.weight_cap`, §1.7).
- https://drift.simonbinder.eu/dart_api/transactions/ — all statements inside a transaction must be awaited; streams see updates only after commit (§2.14).
- https://drift.simonbinder.eu/dart_api/streams/ — table tracking and `readsFrom:` (§2.12).

**Clinical and agricultural sources, cited only as things the app must not repeat**
- NADIS, *Sheep — Medicine Usage* — withdrawal periods *"can change for the same medicine and differ between products with the same active ingredient"*. The basis for §2.2's repeat-treatment rule. https://www.nadis.org.uk/disease-a-z/sheep/medicine-usage/
- AHDB, *Reducing Lamb Losses for Better Returns* — the 50 ml/kg colostrum guidance the app holds every input for and must never compute (§2.3). https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf

**Dependency audit**
- https://pub.dev/api/packages/ — the API endpoint the §2.17 audit reads for version, publisher and dependency graph. The only permitted source for a version number outside decision-record §5.
