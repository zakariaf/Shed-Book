# 00 — Shed Book engineering doc set

**Start here.** If you read only this file you will know what you are building, what you must never do, and which document to open next. Nothing below is new: every rule traces to [`../../shed-book-spec.md`](../../shed-book-spec.md) (the product), [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) (the canonical decision table and the owner's rulings), or [`CONVENTIONS.md`](CONVENTIONS.md) (the naming authority). Where this file summarises, those files decide.

---

## 1. What this doc set is

Shed Book is a lambing notebook for a phone: an offline-only Flutter app for a shepherd with 20–400 ewes, built around a single fifteen-second interaction — pick the animal, tap what happened — performed at 03:20, one-handed, in a cold shed with a head torch and no signal. It has no account, no server, no sync and no subscription; it is bought once with a single non-consumable unlock; and its lasting value is not the entry but the recall — in year two, *"what did 412 do last year?"* takes one second instead of an evening with a shoebox. These fourteen documents govern the implementation of that product: the layer rules and the one script that enforces them, the SQLite schema that is irreversible after the first migration snapshot, the arithmetic that is invisible when it is wrong (withdrawal periods, lambing percentages, hours since penned), the design system that must be legible at 18 pt under a head torch, the twelve screen briefs, the six platform seams, the export formats that are the only backup this product has, the test tiers, and the CI gates that make the offline claim mechanically provable rather than merely asserted. They are written for one developer, and they assume that developer is about to type `mkdir lib/`.

The doc set is deliberately opinionated because the failure modes are unrecoverable. There is no server-side backfill, no feature flag, no remote kill switch and no support channel that can fix a bad migration on someone else's phone in April. A rule that looks like ceremony in a normal app is usually load-bearing here; the document that states it also states the failure it prevents.

---

## 2. The non-negotiables, in priority order

Four things outrank everything else. Each is held by **one structural mechanism**, not by discipline — the hierarchy applied throughout the set is *unrepresentable → unconstructible → unpersistable → caught by a test on the source text → documented*, strongest first.

### 2.1 The offline-purity contract

**This is the only public wording permitted, verbatim** (decision-record §3.1):

> "Shed Book has no account, no server and no sync. The Android build ships without the internet permission, so the app itself cannot connect to anything. Your records only leave the phone when you deliberately export and share them."

**Never write "your data never leaves your phone."** It does, the moment they AirDrop a CSV — which is the backup story the product depends on. Three tiers exist and only the first two are claimable: *no network code and no `INTERNET` permission* (yes), *no dependency attempts a network call from our process* (yes), *no data ever leaves the device by any route* (**no** — the share sheet and the system photo picker are other processes with their own network access).

| Mechanism | What it is |
|---|---|
| **Gate G1** | `bundletool dump manifest` on the **shipped release `.aab`** asserts the permission set is *exactly* the eight entries in the contract. A plugin cannot silently merge a permission. Blocking, every push. |

Supporting gates: **G2** (direct-dependency allowlist over `pubspec.lock`, `dependencies` and `dev_dependencies` scanned separately), **G3** (import scan of `lib/`), **G4** (merger report, diagnostic only), **G5** (iOS: construction plus observation, honestly labelled as not mechanically enforced). **G0** — the manifest-merger check against a real release AAB — has not been run; until it is, G1 is *unwritten*, not merely unimplemented.

→ [`13-build-ci-release.md`](13-build-ci-release.md) §2 (the gates), §3 (the permission set). Anti-patterns worth knowing before you propose one: a *"no `http` in `pubspec.lock`"* rule is **unsatisfiable** and must never be written — `http 1.6.0` sits on two load-bearing regular edges.

### 2.2 The 3am test (spec §5)

*"Every screen must pass this. If a feature cannot be operated under these conditions, it does not ship."*

| Clause | The mechanism that holds it | Document |
|---|---|---|
| One thumb, one hand; gloves, wet hands; 60×60 pt minimum | `ShedTapTarget` with a required `semanticLabel`, plus `MinimumTapTargetGuideline(size: Size(60, 60))` **and** a second geometric gate in `test/design/` | [`06-design-system.md`](06-design-system.md) §6 |
| No swipe, drag, long-press-only, pinch, force touch | The gesture ban as `check_policy` rows: no `Dismissible`, `Draggable`, `Tooltip` anywhere in `lib/` | [`06-design-system.md`](06-design-system.md) §7 |
| Head torch or darkness; no white flash; 18 pt body | Four dark theme slots, no light theme reachable; raw hexes and magic sizes are build-breaking defects; the no-white-flash recipe at four layers | [`06-design-system.md`](06-design-system.md) §2, §5, §9 |
| **Under fifteen seconds from unlock to a saved lambing** | `main()` awaits nothing and the first frame is a static dark Quick Entry shell with a **fully interactive keypad and no data**; the 6-tap budget is asserted in `test/features/tap_budget_test.dart` | [`01-architecture.md`](01-architecture.md) §6, [`07-screens.md`](07-screens.md) §1.3 |
| Zero interruptions | Nothing monetization-related renders on the five **shed screens** at any entitlement state — a widget test, not a convention | [`11-monetization-and-store.md`](11-monetization-and-store.md) §8 |
| Assume the phone dies | See §2.4 below | [`01-architecture.md`](01-architecture.md) §4.2 |

The one question to ask of any change to Quick Entry: **does the shepherd have to do anything new before the record exists?** A tap, a wait, a decision, or a thing on screen that was not there before. If the answer is yes, the change lands somewhere calmer, in daylight. → [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md) §3.4.

### 2.3 The five safety rules (spec §12)

Spec §12 says these "should be visible in the code review checklist". A checklist is the weakest available mechanism, so each rule is pushed as far up the hierarchy as it will go:

| Rule | Mechanism | Level |
|---|---|---|
| **§12.1** never default a medicine withdrawal period | `sealed class WithdrawalPeriod` with a private generative constructor and one entry point `WithdrawalDays.asEnteredByUser`; persisted as a child table where **no row implies `NotRecorded`** | unconstructible + unpersistable |
| **§12.2** never give veterinary advice | The origination line — *the app may arithmetic-transform a number the user supplied; it may never originate a number that is a clinical decision* — plus `ContentPolicy`'s regex scan over string literals and ARB messages, self-tested in both directions | test on source text |
| **§12.3** never present the app as a compliance record | `Disclaimers` is an `abstract final class` of `const` strings in exactly one file, **referenced and never re-typed**; `ExportEnvelope` has no disclaimer parameter | unconstructible |
| **§12.4** never silently correct a user's entry | `Warning` / `Reviewed<T>` hold no writer and no `fix()`; there is **no `warnings` column**; `lib/data/` may not import `lib/domain/validation/` at all | unrepresentable + unpersistable |
| **§12.5** timestamps are honest | `RecordedTime` (`effective` + `capturedAt` + `originalEffective?` + `TimeSource`) with paired SQL `CHECK`s; `provenanceLabel` is an exhaustive switch and can never be empty | unrepresentable |

→ [`05-domain-correctness.md`](05-domain-correctness.md) §7 owns all five. The corollary you will meet first: **a table without the provenance quad has no edit verb.**

### 2.4 Every write commits immediately

Spec §5: *"Assume the phone dies. Every write is committed immediately. There is no draft state to lose."*

| Mechanism | What it is |
|---|---|
| **Repository methods are event verbs** | There is no `save(aggregate)` method anywhere, so there is no aggregate parameter in which a draft could be deferred. The row is created **on screen entry, not on exit**: the Quick Entry "Lambing" tap calls `beginLambing(ewe)` *before* Lambing Entry is pushed, and every field afterwards is its own committed write. |

Consequences that are not negotiable: no `Save` button, no `isDirty`, no `commit()`, no `submit()`, no `LambingDraft`, no optimistic UI (the SnackBar appears *after* the transaction returns), and `synchronous = FULL` on every connection so a commit survives a power loss. Undo is defined **per verb** in the repository, lives only until the SnackBar is dismissed or the route pops, and does not survive process death.

→ [`01-architecture.md`](01-architecture.md) §4.2 (event verbs), [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §1.3 (pragmas), [`07-screens.md`](07-screens.md) §15 (undo per verb).

---

## 3. Stack at a glance

Every version is from decision-record **§5**, verbatim, and from nowhere else — not a README, not `pub add`, not memory. Concern → choice from **§2**; the bracketed number is the decision row.

### 3.1 Toolchain and shape

| Concern | Choice |
|---|---|
| Flutter / Dart | **Flutter 3.44.8 stable (2026-07-23), Dart 3.12.2**, pinned via FVM. Never unpinned `stable` [#1] |
| Analyzer ceiling | No Flutter app can resolve `analyzer ≥ 13.1.0` — the SDK pins `meta: 1.18.0` exactly. This governs the whole dev-dependency set [#2] |
| Architecture | Flutter MVVM **two-layer** (UI + Data); the domain is plain top-level functions, not use-case classes [#6] |
| Folder layout | Feature-first UI, shared `data/` + `domain/`, single package. 9 feature folders, 12 screens [#8] |
| Enforcement | **One** `tool/check_policy.dart` with a rule table, one allowlist file, one exit code — 8 layer rules, banned text, design tokens and the dependency allowlist [#9, #10] |
| Codegen | **drift only.** One generator is the budget. No `freezed`, no `riverpod_generator`, no `json_serializable` [#16] |

### 3.2 Runtime dependencies

| Concern | Choice | Version |
|---|---|---|
| State + DI [#17] | `flutter_riverpod`, **exact pin, no caret**. Riverpod 3.x cannot resolve alongside `drift_dev` | **2.6.1** |
| Persistence [#25] | `drift` over SQLite | **2.34.2** |
| Connection [#25] | `drift_flutter` (`driftDatabase()`, background connection) | **0.3.1** |
| SQLite engine [#25] | `sqlite3`, bundled via Dart build hooks — guarantees `STRICT` + FTS5 on every device | **3.5.0** |
| Paths [#27] | `path_provider` — database in **application support**, never Documents | **2.1.6** |
| Ids [#32] | `uuid` — RFC 9562 **v7** as the export identity | **4.6.0** |
| Clock [#46] | `clock` — `appNow()` is the only wall-clock reader in the app | **1.1.2** |
| Notifications [#63] | `flutter_local_notifications` — one idempotent `reconcile()`, never `zonedSchedule()` on write | **22.2.0** |
| Timezone [#48] | `timezone` — confined to the notification-scheduling seam | **0.11.1** |
| Screen wake [#79] | `wakelock_plus` — default-off, session-scoped, 30-minute expiry | **1.7.0** |
| Photo capture [#77] | `image_picker` (system camera + system photo picker; merges **zero** Android permissions) | **1.2.3** |
| Downscale [#40] | `flutter_image_compress` — 2048 px longest edge, JPEG q80, `keepExif` false | **2.5.1** |
| Voice note [#76] | `record` (class is `AudioRecorder`) — AAC-LC `.m4a`, **never opus** | **7.1.1** |
| Share [#80] | `share_plus` — `SharePlus.instance.share(ShareParams(...))`, always a file path | **13.3.0** |
| File import [#81] | `file_selector` — no storage permission on either platform; validate magic bytes ourselves | **1.1.0** |
| PDF [#83] | `pdf` — always embed a TTF; never `printing` | **3.13.0** |
| ZIP [#85] | `archive` | **4.0.9** |
| Purchase [#87] | `in_app_purchase` — one non-consumable unlock. `in_app_purchase_storekit` must be ≥ 0.4.8 | **3.3.0** |
| Diagnostics [#123] | `device_info_plus` / `logging` — a local redacted rolling file, never a crash reporter | **13.2.0** / **1.3.0** |
| i18n [#108] | `flutter_localizations` (SDK) + gen-l10n/ARB from day one, shipping `en` only; `intl` declared **`any`** | `intl` **0.20.2** (SDK-pinned) |

### 3.3 Dev dependencies

| Concern | Choice | Version |
|---|---|---|
| Migrations + schema snapshots [#37] | `drift_dev` — `make-migrations`, `schema steps`, `SchemaVerifier` | **2.34.5** |
| Build [#3] | `build_runner` — `^2.15.2` **does not resolve** | **`">=2.15.0 <2.15.2"`** |
| Lints [#109] | `flutter_lints` + an explicit `analyzer: language: {strict-casts, strict-inference, strict-raw-types}` block | **6.0.0** |
| Test doubles [#112] | `mocktail`, for interaction-ordering and non-invocation only; hand-written fakes for the six gateways | **1.0.5** |
| Debug a11y [#100] | `accessibility_tools` — complements, never replaces, the 60×60 house assertion | **2.8.0** |
| Property tests [#118] | a hand-rolled seeded generator — `glados` was struck on 2026-08-01, it does not resolve at any version | — |
| Store screenshots | `golden_screenshot` — belongs in `tool/`, not `test/` | **11.0.1** |

**`package:test` is never a direct dependency** [#4]: a Flutter app uses `flutter_test`, which does not depend on it, and declaring it caps `analyzer < 13.0.0` and breaks `drift_dev`.

### 3.4 Things chosen by *not* being used

`go_router` · `freezed` · `riverpod_generator` / `riverpod_lint` / `hooks_riverpod` · `get_it` · `melos` · `custom_lint` / `import_lint` / `dart_code_metrics` · `sqflite` / `objectbox` / `isar` / `hive` / `realm` · `flutter_secure_storage` · `permission_handler` · `camera` · `file_picker` · `csv` · `printing` / `google_fonts` · `fl_chart` · `connectivity_plus` / `workmanager` / `battery_plus` · `mockito` / `patrol` / `golden_toolkit` / `alchemist` · `flutter_native_splash` · `flutter_screenutil` · `slang` / `easy_localization` · Crashlytics / Sentry / any analytics. Each has a reason and an alternative in decision-record §5.3 — read it before re-proposing one.

---

## 4. The five decisions that must be taken before commit #1

These are irreversible or structural. Everything else can be revisited in week two without rework. Restated from decision-record **§1**.

| # | Decision | Where it is applied |
|---|---|---|
| **1** | **`flutter_riverpod: 2.6.1`, pinned exactly.** Riverpod 3.x cannot resolve alongside `drift_dev`. Every Riverpod-3-only API is banned from the codebase *and* from the docs | [`02-state-di-navigation.md`](02-state-di-navigation.md) §1–§3 |
| **2** | **Instants are `INTEGER` UTC epoch millis; civil dates are `TEXT 'YYYY-MM-DD'`.** `store_date_time_values_as_text` is never set and drift `dateTime()` columns are never used. **Irreversible after the first migration snapshot** | [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §4, [`05-domain-correctness.md`](05-domain-correctness.md) §2 |
| **3** | **Withdrawal clear date = ceil-to-next-local-midnight of (administration instant + N × 24 h)**, in absolute time, stored exactly once at write time. Civil-day arithmetic is banned for withdrawal — measured, it yields **167 h across UK spring-forward**, one hour short, in late March | [`05-domain-correctness.md`](05-domain-correctness.md) §3 |
| **4** | **`main()` awaits nothing**: `ensureInitialized()` → install error handlers → `runApp()`. The database lives in application support and is opened after the first frame | [`01-architecture.md`](01-architecture.md) §6 |
| **5** | **Run the manifest-merger check (G0) against a real release AAB before writing any `tools:node="remove"` line**, and add the four `in_app_purchase*` packages to the offline allowlist and `com.android.vending.BILLING` to the permission list | [`13-build-ci-release.md`](13-build-ci-release.md) §2.2 |

**Until #5 is done, the offline gate in CI is unwritten, not merely unimplemented.** Removing `INTERNET` is proven; removing `ACCESS_NETWORK_STATE` is **not** — do not commit it on faith.

Add one procedural precondition from decision **#5** in §2: **run `flutter pub get` against decision-record §5's table on Flutter 3.44.8 and commit the resulting `pubspec.lock` before any other work.** It is the doc set's only evidence that the table resolves at all — four of the ten research notes recommended a `build_runner` constraint that does not.

---

## 5. Where the ground is firm, and where it is not

### 5.1 Settled by the owner, 2026-07-27 (decision-record §7.0)

These four are **closed**. Anything in the research notes that contradicts them is superseded; do not re-litigate.

| Question | Ruling | What it binds |
|---|---|---|
| Do tag OCR and voice tag entry ship in v1? | **Both cut from v1.** The voice *note* still ships as pure local recording | The offline gate stays mechanically provable: no ML Kit, no `speech_to_text`, no Play Services in the graph. Recorded as v2 candidates *with the reason* in [`08-platform-integration.md`](08-platform-integration.md) §10 so a future contributor cannot quietly reverse it |
| Tag uniqueness | **Unique among ACTIVE animals only** — a partial unique index, not a global one | The schema freeze. A culled 412 releases the tag; a new 412 is a new row with its own history. Create-on-the-fly matches active animals only, and the ewe card must be able to show "there was an earlier 412" |
| Region first | **UK / Ireland** | Ambiguous DST hour is **01:00–01:59** — the hour every withdrawal and hours-penned test targets. `en_GB`, kg, °C, 24-hour clock, `dd/MM/yyyy`, week starts Monday. AHDB lambing-percentage convention (lambs born **alive**) as the default, still user-configurable |
| Free-tier shape | **Season-primary, ewe cap secondary** | The free tier covers one full season; the gate lands where §7.7 says the value is — opening last year's history in season two. Neither surfaces mid-entry, and neither surfaces at all between **22:00 and 06:00** |

### 5.2 Still open (decision-record §7.1), ranked by what they block

1. **Does a night in a real lambing shed happen before the Quick Entry screen is written?** The entry flow *is* the product and cannot be designed correctly from forum posts. **The highest-value unresolved item in the project.** It also closes items 2, 12 and 18.
2. **Ziplock-bag capacitance.** Does the target hardware register taps through a freezer bag? A hardware test, not a desk decision. If it fails, decisions #100, #101 and #102 all change and the interaction model is rethought around volume-button shortcuts.
4. **Exact price and territories.** Enrol in the Apple Small Business Program **before the first sale**; confirm Google's post-30-June-2026 one-time-product rate inside Play Console.
9. Does the app replace the paper record entirely, or sit alongside it for season one?
10. ~~**Is the target market ever a dairy flock?**~~ **Ruled 2026-08-01: ship `WithdrawalTarget.milk` in the v1 schema.** The v1 UI may never write one. `treatment_withdrawals` already carries `CHECK (target IN ('meat','milk'))`, so it costs nothing today and a migration later.
11. ~~**Where does temperature appear at all?**~~ **Ruled 2026-08-01: nowhere — drop the setting.** No v1 table stores a temperature; `app_settings.temperature_unit`, the Settings °C/°F row and `temperatureUnitProvider` do not exist. `MilliCelsius` still ships.
12. Lamb-scale resolution and the plausible weight band (0.1 kg? 0.05 kg? 50 g?).
13. ~~**Does a lamb kept as a breeding ewe become a `Ewe` row?**~~ **Ruled 2026-08-01: yes.** `lambs.became_ewe`, a nullable FK to `ewes(id)` with `onDelete: setNull` and a hand-written index. It is what makes *"her dam was 412"* answerable in season three.
14. **Does the developer account exist, and is it a personal account created after 13 Nov 2023?** If yes, Play's **12-tester / 14-day closed test** is on the critical path and must be scheduled *now*. Recruiting twelve shepherds doubles as the answer to item 1.
15. ~~Lambing ease: the spec's 5 points or SRUC's 6?~~ **Ruled 2026-08-01: five**, with point 5 documented as covering elective caesarean. `lambings.ease` keeps `BETWEEN 1 AND 5` and is deliberately not a vocabulary foreign key, so widening it stays a migration.
16. ~~Must the PDF print from *inside* the app?~~ **Ruled 2026-08-01: no.** `printing` stays rejected, delivery stays share sheet → the OS Print action, and G3's `PdfGoogleFonts` / `networkImage` greps stay blocking (decision-record §7.0 row 16).
17. Does the free tier cap reminders too? 15 ewes fits inside the 56-slot iOS budget; 400 does not.
18. ~~Voice note cap: 60 s or 120 s?~~ **Ruled 2026-08-01: 60 s**, the recoverable direction — raising a cap orphans nothing, lowering one makes existing recordings unreproducible (decision-record §7.0 row 18).

Items **3, 5, 6, 7 and 8** are settled in §5.1 and are struck from the open list. Items **16 and 18** were the two that expired when `pubspec.yaml` closed and were ruled on 2026-08-01, before it did. Items **10, 11, 13 and 15** were the four that expire at the schema freeze and were ruled the same day, five epics before it. **Seven remain: 1, 2, 4, 9, 12, 14 and 17 — four of them bookings rather than decisions.**

Four more, surfaced by `CONVENTIONS.md` §7 and deliberately not closed by a naming authority: whether the retention story needs a **ewe status-history table** (R41 — a schema addition, irreversible after the first snapshot, needs the owner); the cost of adding the provenance quad to four tables (R37); the field-night list above; and whether `HapticFeedback.successNotification()` exists on 3.44.8 (an SDK fact, not a ruling).

**Items 10, 11, 13 and 15 were schema-shaped and would have expired at the first snapshot.** They did not expire — they were answered on 2026-08-01, in N00-T04, five epics before the freeze at N07-T08. Nothing left in this list is schema-shaped.

---

## 6. The file index

Read in this order the first time. After that, open the one that owns your change.

| File | What it covers | When you need it |
|---|---|---|
| [`CONVENTIONS.md`](CONVENTIONS.md) | **BINDING naming authority.** The canonical folder tree, the eight layer rules as amended, the type catalogue, the complete provider catalogue, file/class/provider/key/database naming, the vocabulary (one word per concept), and the 73-entry ruling log | Before you name anything. It outranks every other document on any name, path, type shape, signature or word — and only on those |
| [`01-architecture.md`](01-architecture.md) | Layers and what is dead in a no-network app; the folder tree; the eight dependency rules and `tool/check_policy.dart`; the single write path and event verbs; `WriteOutcome` / `ShedFailure`; the global error net; the ~20-line `main()` | Before you create `lib/`. Every other document links here instead of re-printing bootstrap or write-path code |
| [`02-state-di-navigation.md`](02-state-di-navigation.md) | Why `flutter_riverpod` 2.6.1 exactly; the Riverpod-3 ban list and the 2.6.1 spelling card; provider shapes and the DI graph; controller conventions; the double-tap-safe `WriteController`; `Navigator` + typed route helpers; why there is no state restoration | Before the second screen — and before you copy any Riverpod published after 2025, all of which shows the API that does not compile here |
| [`03-data-model-and-schema.md`](03-data-model-and-schema.md) | The drift setup and `build.yaml`; the connection and its pragmas; every table with its `STRICT`/FK/`CHECK` conventions; the dual-key id strategy; time and unit storage; fostering; pen occupancy; the two search problems; the first-run seed | Before `make-migrations` runs for the first time. **This is the freeze point** |
| [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) | Forward-only additive migrations and the ritual; the full from→to `SchemaVerifier` matrix and the no-diff CI check; the media filesystem layout and the relative-path rule; orphan sweeps; `VACUUM INTO` as a diagnostics snapshot; the atomic replace-everything restore | Adding a column, attaching a photo, or touching import. Everything that can destroy five seasons |
| [`05-domain-correctness.md`](05-domain-correctness.md) | `Instant` / `LocalDate` / `PartialDate`; the one clock and the SQL-time ban; the withdrawal sealed type and the clear-date algorithm; `RecordedTime`; canonical grams and milli-°C; `StatResult` and every statistic's edge cases; terminology; **the five safety rules as structural mechanisms** | Before you write a line of `lib/domain/`, and again before you change one |
| [`06-design-system.md`](06-design-system.md) | Four dark theme slots and the real high-contrast palette; the three hand-authored palettes including deep red; two-tier tokens via one `ThemeExtension`; typography and the w700 cap; tap targets and the gesture ban; the custom keypad; the no-white-flash recipe at four layers; feedback channels; pen-board glanceability | Before your first widget, and every time you are tempted to type a hex |
| [`07-screens.md`](07-screens.md) | All twelve screens: purpose, the one query that feeds each, every state including empty and over-cap, actions and tap costs, which §12 disclosure appears where — plus undo-per-verb, the end-of-day export banner, and the reminder/OS reconciliation rule | Building or changing a screen. It decides *what is on the screen and what it costs the shepherd* |
| [`08-platform-integration.md`](08-platform-integration.md) | The gateway pattern and all six seams; the notification `reconcile()` architecture, channels, exact alarms, reboot and DST; photo capture; audio recording; the share sheet; file import; wakelock; the per-plugin permission policy; and the record of why OCR and voice tag entry are v2 | Adding a plugin, or touching `AndroidManifest.xml` / `Info.plist` |
| [`09-export-formats.md`](09-export-formats.md) | The hand-rolled RFC 4180 CSV writer and its three shapes; the PDF build (embedded TTF, isolate, splitting, memory); the JSON backup envelope and its forward-compatibility rules; the §12.1 and §12.3 disclaimer footers; the export→import→export round trip | Building `lib/features/export/`, or touching `RestoreService` — the backup format is a two-sided contract |
| [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md) | The platform flag truth table; semantics for the pen board, keypad and chart; headings; text scaling; colour-never-alone; motor accessibility; **Apple's Accessibility Nutrition Labels as the ship gate**; the gen-l10n/ARB setup and the terminology-placeholder rule | Writing widgets. 06 owns the pixel; this document owns the label |
| [`11-monetization-and-store.md`](11-monetization-and-store.md) | The one-IAP model; what billing does to the manifest and which offline claims survive; the entitlement row and its three rules; the `PurchaseService` seam; purchase and restore flows; the `FreeTierPolicy` object and `EntryContext`; the four hard constraints on the upgrade affordance; both stores' privacy declarations | Any line that touches money, and every store artefact |
| [`12-testing.md`](12-testing.md) | The five tiers (it is not a pyramid); time in tests; the in-memory drift harness; hand-written fakes; `pumpApp`; the **252-cell** overflow matrix; accessibility as an executable gate; the eight goldens and how to re-baseline; the four integration journeys; the product's own promises as tests; coverage policy; fixtures | Before your first test, and again whenever you are tempted to express a rule as a `RegExp` inside a `test()` |
| [`13-build-ci-release.md`](13-build-ci-release.md) | The pinned toolchain and the `Makefile`; offline gates G0–G5 and the permission set; the CI job matrix and its macOS budget; lints and the strict analyzer block; size and startup budgets; the clean-pause mechanism; diagnostics without a network; versioning and signing; test tracks and the 12-tester requirement; the **seasonal release freeze** | Editing `pubspec.yaml`, `analysis_options.yaml`, anything under `.github/`, `android/` or `ios/`, or cutting a tag |
| [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md) | §1 everything a machine already proves (so you never spend a comment on it); §2 what no gate can catch, starting with the five §12 rules as questions; §3 the review ritual, read order by irreversibility, and the one question about Quick Entry | Every review, on both sides of it |
| [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) | The canonical decision record: the five pre-commit decisions, the numbered decision table (rows #1–#128), the offline contract and its gates, the dropped/degraded list, the verified dependency table, corrections applied, and the owner's rulings | Whenever a document surprises you. It is the authority; the ten research notes in `../research/raw/` are only evidence |

Adjacent, not part of the engineering set: [`../../shed-book-spec.md`](../../shed-book-spec.md) (the product spec), `../design/` (three candidate visual directions — the design *system* is built so any of them drops in by replacing constants), `../research/critique/` (the four critiques that produced the corrections), `../research/raw/` (the ten research notes; **superseded** by the decision record wherever they disagree).

**Not yet written:** `REFERENCES.md`, the consolidated bibliography named in decision-record §8. Until it exists, each document carries its own `## References` section with fetch dates.

---

## 7. Repo conventions

`CONVENTIONS.md` is the naming authority — file names, class names, provider names, widget keys, column names and the project vocabulary all live there and are not restated here. Read its §1 (the tree you `mkdir` from), §4 (naming) and §5 (one word per concept) once, then cite ruling numbers (`per CONVENTIONS R27`) rather than arguing.

### 7.1 What is committed

| Committed | Why |
|---|---|
| `pubspec.lock` | Decision #5's evidence that the dependency table resolves at all. A lockfile diff in a PR that does not also change `pubspec.yaml` is a **review stop** |
| `drift_schemas/drift_schema_v<N>.json` | The migration tests' baseline. Losing these is unrecoverable |
| `lib/core/db/database.g.dart`, `*.drift.dart` | Generated code is committed so a clean checkout builds. CI regenerates and diffs |
| `lib/core/db/schema_versions.dart` | Generated by `drift_dev schema steps` |
| `test/drift/generated/**` | Generated migration-test helpers |
| `lib/l10n/app_localizations*.dart` | Generated by gen-l10n. Committed so a stale generation is visible in a diff instead of invisible in a build directory |
| `test/features/goldens/*.png` | The eight golden images, beside the widget tests that produce them. There is no `test/golden/` directory |
| `test/fixtures/*.json` | `flock_400_3seasons.json`, `flock_15_at_cap.json` |
| `.fvmrc`, `Makefile`, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, `dart_test.yaml` | The toolchain pin and the four generator/lint/test configs |
| `tool/policy_allowlist.txt`, `android/expected_permissions.txt` | The gate's inputs. Editing either to make a red build green is a named anti-pattern |
| `ios/*.storekit` | The offline purchase-test configuration |

### 7.2 What is gitignored

`.fvm/` · `android/key.properties` (local only; regenerate from the keystore and its passwords) · `build/` and every artefact under it · `.dart_tool/` · coverage output · obfuscation symbols (binary, kept forever **off** the laptop under `symbols-archive/<name>+<build>/`, never in git — losing them makes every stack trace in every user-sent diagnostics log for that build permanently unreadable) · the upload keystore itself.

### 7.3 Where generated code lives

Everything generated is named so you can see it: `*.g.dart` and `*.drift.dart`, plus `drift_schemas/*.json`, `test/drift/generated/**` and `lib/l10n/app_localizations*.dart`. **Never hand-edit one.** They are always skipped by `tool/check_policy.dart` and always waved through in review — read them only to confirm nobody edited one. `make gen` is the only way they change:

```bash
make gen     # build_runner build --delete-conflicting-outputs && drift_dev make-migrations
```

The `codegen` CI job re-runs both and fails on `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/`. It is the most valuable step in the pipeline after G1, because a stale generated file is invisible locally and lethal on a fresh clone.

### 7.4 Branches, commits and tags

- **Trunk is `main`.** CI runs on every push to `main` and on every pull request; the release workflow runs on tags matching `v*`; the golden job runs on `v*` or manual dispatch.
- **Work on a short-lived branch and open a PR**, even alone. The PR is where `.github/pull_request_template.md` puts the five §12 questions in front of you verbatim, and where the review order of `CODE-REVIEW-CHECKLIST.md` §3.1 applies.
- **Commits that must stand alone**, because each one changes what the whole product may claim or must be readable as a single diff:
  - a **toolchain bump** — its own commit, its own `flutter pub get`, its own `pubspec.lock` diff, and its own *read* of that diff;
  - a **golden re-baseline** — `make goldens-update` is a deliberate act, never bundled with the change it re-baselines;
  - a **`[exempt]` line** in `tool/policy_allowlist.txt` — it deletes a rule for one file, forever, silently, and the reason goes in the commit message that adds it.
- **Commits that must *not* be split:** a schema change lands as one commit — `kSchemaVersion`, the new `from<N>To<N+1>` step, the regenerated snapshot and the regenerated test helpers, together or not at all. CI enforces this by regenerating and failing on any diff.
- **Commit messages use the project vocabulary** (`CONVENTIONS.md` §5): *record* not entry, *warning* not flag, *withdrawal period*, *clear date*, *turn out*, *reconcile*, *restore* never merge. The banned words are banned in commit messages too — there is no `draft`, no `save()`, no `sync`.
- **Tags:** `git tag v<version>` triggers the release workflow. Build **name** is bumped by hand in the tag; build **number** is always the CI run number — both stores reject a re-used one. Never tag between **1 February and 30 April** except for a data-loss-class hotfix (§9 below and 13 §11).

---

## 8. How a feature gets added, end to end

The single most useful section in this file. From *"I want to add X"* to *"it is merged"*, naming files in the order you touch them. Skip a step only when the feature genuinely does not reach that layer — and if you are skipping the schema step, say so out loud, because it means you are storing nothing.

### Step 0 — Find out whether it is already decided

Read, in this order: `CONVENTIONS.md` §2 (does the type already exist and is it already named?), §3 (does the provider already exist?), then the owning document from the table in §6, then decision-record §2 for the row that governs it. **Most "new" work is an application of an existing decision.** If the feature contradicts a decision, stop and go to §10's amendment rule — do not implement around it.

### Step 1 — Schema, if it stores anything

1. `lib/core/db/tables/<cluster>.dart` — the table or column. `STRICT`, a real FK with an explicit `ON DELETE`, a hand-written index for every FK, the §12.5 provenance quad if the row will ever be edited, and **no `DEFAULT` on any column that could encode veterinary advice**.
2. `lib/core/db/database.dart` — register the table; bump `kSchemaVersion`.
3. `make gen` — writes `database.g.dart`, `drift_schemas/drift_schema_v<N>.json`, `schema_versions.dart` and `test/drift/generated/**`.
4. `lib/core/db/migrations.dart` — the hand-written `from<N>To<N+1>` body. **Forward-only, additive, never destructive.** No `DROP COLUMN`, no `DROP TABLE`, no changing a column's meaning in place.
5. `test/drift/` — extend the from→to matrix so **every** pair runs `SchemaVerifier.migrateAndValidate` and `PRAGMA foreign_key_check` returns zero rows. A red migration test is ship-blocking.
6. If the change needs a view, a trigger or a named query: `lib/core/db/views.drift`, `search.drift` or `queries.drift` — never a `customStatement(` outside `lib/core/db/`.

*Steps 2–5 land in one commit.* → [`03-data-model-and-schema.md`](03-data-model-and-schema.md), [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §2–§3.

### Step 2 — Domain, if it computes anything

7. `lib/domain/<area>/…` — pure Dart. No Flutter, no drift, no Riverpod, no `intl`, **no `package:clock`**. Top-level functions and value types; `now` is a *parameter*, never a read.
8. Ids are extension types from `lib/domain/ids.dart`; mass is `Grams`; temperature is `MilliCelsius`; a contradiction returns `List<Warning>` and has no `fix()`.
9. `test/domain/…` — the thickest tier. Anything time-shaped also gets a case under `test/domain/uk_zone/` tagged `uk-zone`, targeting the **01:00–01:59** ambiguous hour.

→ [`05-domain-correctness.md`](05-domain-correctness.md).

### Step 3 — The write path

10. `lib/data/<area>_repository.dart` — an **event verb**, never `save(aggregate)`. Inside: `appNow()` called **once** per mutation, `RecordedTime.capture(now)` for provenance, `newUid()` for the export identity, everything in one `_db.transaction()`. Returns `WriteOutcome` — except `beginLambing` and `addLamb`, the only two verbs that return an id and throw.
11. `lib/data/failure_mapping.dart` — if a new `SqliteException` shape needs mapping to a `ShedFailure`.
12. `test/data/…` — against `NativeDatabase.memory()`, never a mock.

**A repository may not import `lib/domain/validation/`.** That is a §12.4 structural mechanism, not an oversight: it makes a repository incapable of producing or persisting a warning. → [`01-architecture.md`](01-architecture.md) §4.

### Step 4 — Wiring

13. `lib/data/providers.dart` — the repository or gateway provider, if it is new. `FutureProvider`, keepAlive, derived from `databaseProvider`. Never `Provider<AppDatabase>`, never `overrideWithValue` in `lib/`.
14. The read provider goes in the **feature's** controller file, one drift statement per screen. Aggregates use `customSelect` with an explicit `readsFrom:`. **`combineLatest` over drift streams is a build-breaking defect** — fan-in happens in SQL.

→ [`02-state-di-navigation.md`](02-state-di-navigation.md) §4–§5, `CONVENTIONS.md` §3.

### Step 5 — Controllers

15. `lib/features/<f>/<screen>_controller.dart` — screen state, never data. No `BuildContext`, no navigation, no SnackBar, no formatting, no drift import, **no draft**.
16. `lib/features/<f>/<feature>_write_controller.dart` — every mutation goes through `WriteController.guard()`, which refuses to run concurrently. This is the double-tap defence, and it is a UX safety feature wearing architecture's clothes.
17. The controller — not the repository — runs `lib/domain/validation/` against the freshly-watched row and passes the resulting `List<Warning>` to `confirmSaved`.

### Step 6 — UI

18. `lib/features/<f>/<screen>_screen.dart` and `widgets/`. Colours and metrics come from `context.tokens`; a raw `Color(0x…)` or a magic size is a build-breaking defect. Shared controls come from `lib/core/ui/components/` — a sibling feature import is a layer violation.
19. Every interactive element is ≥ 60×60 pt with ≥ 16 pt separation, has a `semanticLabel`, and carries a widget key spelled `<screen>.<element>[.<qualifier>]`, all `lower_snake`.
20. Feedback is `confirmSaved` / `showFailure` / `showCapRow` from `lib/core/ui/feedback.dart` — the one file permitted to call `showSnackBar(`.
21. `lib/routing/routes.dart` — a `RouteNames` entry and a typed push helper, if the feature adds a screen.
22. `lib/l10n/app_en.arb` — **every** user-facing string, each with a `description`. No domain noun appears literally in a message; the term is a placeholder fed by `terminologyProvider`.

→ [`06-design-system.md`](06-design-system.md), [`07-screens.md`](07-screens.md), [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md).

### Step 7 — Tests

23. Domain unit tests (step 2) and repository tests (step 3) already exist. Now add:
24. `test/features/<f>_test.dart` — widget tests through `pumpApp`.
25. **A new screen or a new pumpable variant means a new row in the 252-cell overflow matrix** (`test/features/overflow_matrix_test.dart`) — 14 variants × 3 sizes × 3 text scales × 2 bold-text states, asserting no `RenderFlex` overflow and no exception. The arithmetic follows the variant list, never a remembered number.
26. Anything on the 3am path is checked against `test/features/tap_budget_test.dart` (6 taps to a committed lambing, 1 for a foster reassignment, 2 for a repeat treatment).
27. Anything touching a §12 rule gets an assertion in `test/policy/`, named for the **property** it holds, not the file it tests.
28. A destructive action gets a `tester.tap(); tester.tap();` double-tap test.
29. Goldens only if a **pixel** regression would be a usability or safety regression nothing else can see. Eight images is the budget.

→ [`12-testing.md`](12-testing.md).

### Step 8 — Run the gates locally

```bash
make gen      # regenerate; commit anything that moves
make check    # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test     # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

`make check` orders itself cheapest-failure-first: the gate is sub-second, `analyze` is tens of seconds.

### Step 9 — Open the PR and let CI prove it

| Job | Must pass |
|---|---|
| `gate` | toolchain pin agrees with `.fvmrc` · `pub get` · `check_policy` (**G2 + G3**) · `format --set-exit-if-changed` · `analyze --fatal-infos --fatal-warnings` · no `NSAppTransportSecurity` |
| `codegen` | `build_runner build` + `make-migrations` + `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/` |
| `test` | `-P ci-fast` with randomised ordering · `TZ=Europe/London --tags uk-zone` · `TZ=Pacific/Chatham test/domain` · coverage artefact (reported, **never** gated) |
| `android` | release AAB built · **G1** permission assertion · **G4** merger report archived |

Goldens are **not** a per-PR gate — the macOS runner bills at a 10× multiplier and a per-push macOS job burns the free monthly quota in a week. They run on `v*` or on manual dispatch.

### Step 10 — Review

The reviewer reads the diff in order of **irreversibility**, not in the order it prints: dependency and allowlist files → `lib/core/db/tables/**` and `drift_schemas/` → `lib/data/**` → `lib/domain/withdrawal|stats|time/` → `lib/l10n/app_en.arb` → `lib/features/**`. Generated files, formatting and coverage are waved through. `lib/domain/withdrawal/**`, `drift_schemas/**`, the `[exempt]` allowlist, `disclaimers.dart`, `main.dart`, any new export format and any table gaining an edit verb are **never** waved through, however small. → [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md).

---

## 9. The recommended build order

Two facts set the order. **Quick Entry is the product** — every other screen exists to serve or read back the loop it drives — and **the schema cannot be changed later**, because the only backup is one the user remembered to make. So the sequence front-loads the irreversible and the invisible-when-wrong, and reaches pixels late.

| # | Build | Why here |
|---|---|---|
| **0** | The five pre-commit decisions (§4). Resolve the dependency table, commit `pubspec.lock`. **Schedule the field night and the 12-tester recruitment now** | Both are calendar-blocking and neither is code. Item 1 of §5.2 closes three other open questions; Play's closed test is 2–3 weeks *after* you have found twelve shepherds |
| **1** | The skeleton and the gate: `mkdir` `CONVENTIONS.md` §1's tree, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, `Makefile`, `tool/check_policy.dart` + its allowlist, and the `gate` CI job. Prove **each rule fires once** — plant a violation, confirm the failure, delete the file | A gate is cheap on an empty tree and impossible to retrofit across twelve screens. A rule nobody has seen fire is indistinguishable from a broken rule |
| **2** | `lib/domain/**` — time, units, withdrawal, warnings, statistics — with `test/domain/` including DST-1…DST-5 | Pure Dart, zero dependencies, the thickest test tier, and the code most likely to be wrong invisibly. It compiles before Flutter is involved, so it is the cheapest place in the project to be correct |
| **3** | The schema and the migration harness: every table, the first snapshot, the from→to matrix **with FTS5 present in v1 and zero real rows**, and the `codegen` no-diff job | The freeze point. Everything the open questions in §5.2 marked schema-shaped must land here or be accepted as a future migration. Discovering that `SchemaVerifier` chokes on FTS5 shadow tables at v4 with real data is a different problem than discovering it in week one with none |
| **4** | `main()`, `app.dart`, the theme set and the first frame: nothing awaited, a dark interactive Quick Entry shell, the four-layer no-white-flash configuration, the global error net and `LocalLog` | The first frame is the product's promise, and the no-white-flash work touches native files you do not want to revisit. Everything after this runs inside a real app |
| **5** | **Quick Entry, end to end**: `tagIndexProvider` + `rankTagMatches`, `quickEntryDeckProvider`, `ShedKeypad`, `beginLambing`, `confirmSaved`, and the 6-tap budget test | It is the product. It also forces you to build every piece of machinery the other eleven screens reuse — the deck query, the keypad, the write controller, the receipt — so the second screen is cheap |
| **6** | The rest of the 3am path: Lambing Entry, Lamb Card, Foster, Pen Board — plus the one 60 s ticker | These are variations on machinery step 5 already built. Foster and the pen board carry their own tap budgets |
| **7** | Treatments and the withdrawal UI | The highest-stakes screen in the app, and the domain behind it was finished in step 2 — so this is presentation over settled arithmetic, which is the right way round |
| **8** | Export, backup and restore — then `tool/seed.dart`, which writes its demo database **through the restore path** | Restore must exist before the seed script can route through it, and the seed script is what makes 400-ewe profiling, the overflow matrix, the goldens and the at-cap monetization tests possible at all. It also turns the seed into a continuous test of the one code path where a bug loses five seasons |
| **9** | Reminders: the rows, `ReminderReconciler.reconcile()`, the channels, the honest windowed line | Depends on writes from steps 5–7 existing to reconcile *from*, and on the permission being requested at the first reminder rather than at launch |
| **10** | The calm screens: Flock, Ewe Card, Season Summary, Note Search, Settings | Off the 3am path, so they may be daylight work — but the Ewe Card summary line is the **retention feature**, the reason the product exists in year two. Do not treat it as filler |
| **11** | Monetization: `PurchaseService`, the entitlement row, `FreeTierPolicy`, the two static upgrade rows, the store artefacts | It can be last precisely because nothing on the shed path branches on `unlocked` — that is decision #90, and the widget test that holds it should exist from step 5 |
| **12** | Release engineering: run **G0**, the size and startup measurements on two real devices, signing, symbols archive, the pre-release checklist | G0 gates the `tools:node="remove"` line, not the app; the measurements need a real device and a real release build, which do not exist until now |

**Two things run in parallel from day one, not at the end:** the accessibility rules (they are widget-authoring rules, and retrofitting semantics across twelve screens is a rewrite) and the ARB (every string goes through `app_en.arb` from the first one — the cost is ten seconds per string now and a full-app sweep later).

---

## 10. Status

| | |
|---|---|
| **Doc set version** | 1.0 — first complete set, 2026-07-27 |
| **Written against** | Flutter **3.44.8** stable (2026-07-23), Dart **3.12.2**, pinned via FVM · `flutter_riverpod` **2.6.1** exactly · `drift` **2.34.2** / `drift_dev` **2.34.5** / `sqlite3` **3.5.0** · `build_runner` `">=2.15.0 <2.15.2"` · `flutter_lints` **6.0.0**. Every other version is in decision-record §5 |
| **Governing decision record** | [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md), dated 2026-07-27, marked FINAL. It supersedes the ten notes in `../research/raw/` wherever they disagree |
| **Owner rulings folded in** | Four rulings, closing five of the eighteen questions, settled 2026-07-27 (§5.1). Thirteen remain open (§5.2) |
| **Complete** | `CONVENTIONS.md`, `01`–`13`, `CODE-REVIEW-CHECKLIST.md`, `REFERENCES.md`, and this file. Nothing in the set is unwritten |
| **Outstanding** | **G0 has not been run.** `flutter_timezone` has not been audited and must not enter any pubspec until it is |
| **Known open contradictions** | `07-screens.md` §3.3 says the `duplicateActiveTag` warning "never blocks the create" while `03-data-model-and-schema.md` §6's partial unique index makes a second *active* animal on the same tag unstorable — one of the two is wrong and it is a domain question, not a naming one. `HapticFeedback.successNotification()` is asserted real by `06-design-system.md` §10 and carried as unverified by `07` §22, `10` §11 and `12`; `REFERENCES.md` §22.E E1 states the five-minute check that closes it |

### The amendment rule

> **A change to a decision requires updating the decision record and every document that applies it, in the same change.**

Concretely:

1. Edit the row in [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) §2 (or §1, §3, §5, §7 as appropriate). State what it now says and why the previous answer was wrong. A superseded decision is **struck with its reason**, never quietly rewritten — decision-record §6 exists so that corrections are not re-litigated by someone re-reading a raw note.
2. Grep the doc set for the decision number. Every document opens with a `> **Decisions applied:**` line; the ones that name your number are the ones that must change **in the same commit**. A doc set where document 07 applies decision #29 and document 03 no longer does is worse than no doc set, because both look authoritative.
3. If the change is a **name**, it is `CONVENTIONS.md`'s: add a numbered ruling in its §6, update §1–§5, and list the files that must change. Fixers then cite the number and apply it mechanically.
4. If the change touches the **schema**, it is irreversible after the first snapshot — say so in the ruling, and route it to the owner rather than deciding it.
5. If the change touches a **§12 safety rule**, the mechanism changes, not just the prose. State which level of the hierarchy it now sits at (unrepresentable → unconstructible → unpersistable → source test → documented) and which test holds it. A rule that drops to "documented" has been deleted, whatever the prose says.
6. Update the version row and the date above.

The one thing you may never do is implement around a decision you disagree with. Every rule in this set has a failure behind it, and most of those failures happen at 03:20 on somebody else's phone in March.
