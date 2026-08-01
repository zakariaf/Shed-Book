# c3 — Cross-topic consistency critique

**Reviewer lens:** cross-topic consistency and coherence across all ten research notes.
**Date:** 2026-07-27. **Judged against:** `shed-book-spec.md` §4 (offline), §5 (3am test), §7, §11, §12 (safety rules), §13 (not in v1), §14 (money).

> **Headline.** The ten notes are individually strong and collectively unbuildable. There are
> **five decisions that cannot both be taken** and that must be settled before commit #1 because
> they are irreversible or structural: the state-management package, the DateTime storage format,
> the withdrawal clear-date algorithm, whether `main()` awaits, and whether `clear_date` is stored.
> Separately, **the offline-purity contract is not actually closed**: the note that enumerates
> "the whole list" of Android permissions (06) never mentions `in_app_purchase` at all, and the
> note that adopts `in_app_purchase` (07) admits in writing that it could not verify the Play
> Billing 8.0.0 manifest from a primary source. Three notes independently hard-code
> `tools:node="remove"` on `ACCESS_NETWORK_STATE` without anyone checking whether billing needs it.

---

## How to read the rulings

Each conflict states both sides, picks a winner, and gives the one line the decision log should
carry. "Winner" means *the decision that ships*; the loser's reasoning is often still worth keeping
as a rejected-alternative entry.

---

# A. Blockers — cannot ship both, must be decided in week 1

## A1. State management: Riverpod 3.4.1 vs 2.6.1 — and the `retry:` line does not compile on 2.6.1

**Side 1 (01 §7.2, "non-negotiable"):** adopt `flutter_riverpod` 3.4.1 and set
`ProviderScope(retry: (retryCount, error) => null)` in the first commit, because Riverpod 3
auto-retries failing providers with exponential backoff and disk-full never heals. 01 pitfall #4
calls this a **Blocker**. 04 §6 also assumes 3.4.1 (`ProviderContainer.test()`,
`WidgetTester.container`).

**Side 2 (02 §1):** pin `flutter_riverpod` **2.6.1 exactly**, because 3.x declares `test` as a
*runtime* dependency (WONTFIX, rrousselGit in riverpod#4791), and on this app's real stack
(drift + drift_dev + build_runner) `flutter pub get` **fails outright**. 02 reproduced the solver
output locally and tested six alternatives, all of which resolve.

**Verified independently:** the `ProviderScope` constructor in flutter_riverpod **2.6.1** is
`ProviderScope({Key? key, List<Override> overrides, List<ProviderObserver>? observers, ProviderContainer? parent, required Widget child})`
— [there is no `retry` parameter](https://pub.dev/documentation/flutter_riverpod/2.6.1/flutter_riverpod/ProviderScope-class.html).
01's "non-negotiable first commit" line is a compile error on 02's pin. 01's `WriteController`
comment ("Riverpod 3: `Notifier`, no `AutoDispose` prefix") is likewise 3.x-only.

**Winner: 02 — `flutter_riverpod: 2.6.1`, pinned exactly.** 02 is the only note that ran the
resolver; 01 asserted 3.4.1 without testing resolution against drift_dev.

**Consequence that must be written down, not left implicit:** on 2.6.1 there *is no auto-retry*, so
01's Blocker-severity pitfall #4 and the CI grep for `retry:` both **evaporate** — delete them
rather than porting them. 01 §8.5's `WriteController` must be respelled with
`AutoDisposeNotifier`, and 04 §6's `ProviderContainer.test()` / `WidgetTester.container` idioms
must be rewritten as `ProviderContainer(...)` + `addTearDown(container.dispose)`.

> **Decision-log line:** flutter_riverpod pinned to 2.6.1; Riverpod 3.x rejected on
> dependency-resolution grounds only (not on network grounds — 02 proved it adds no network path).
> All Riverpod-3-only APIs (`ProviderScope.retry`, `ProviderContainer.test`, bare `Notifier`
> autoDispose spelling, Mutations) are banned from the codebase and from the docs.

---

## A2. Withdrawal clear-date: civil-day arithmetic vs absolute hours — a spec §12.1 safety bug

**Side 1 (01 §5 `clearDateFor`, 04 §2 "Timezone"):** compute the clear date with calendar
arithmetic, `DateTime(d.year, d.month, d.day + days)`, and 04 turns this into a *testing rule*:
"Use calendar arithmetic `DateTime(y, m, d + n)` for date offsets."

**Side 2 (09 #3):** `clearDate = ceilToNextLocalMidnight(treatmentInstant + N × 24 h)`, computed in
absolute time, never civil days. 09 cites VICH (the withdrawal period is the minimum period between
last administration and production of foodstuffs, whole days rounded **up**) and gives **program
output**: civil-day `+7` across the UK spring-forward yields **167 h elapsed, not 168**.

This is not a style disagreement. It is a one-hour-short withdrawal period on a treatment given in
late March — exactly when UK/Ireland lambing happens — on the single calculation spec §12.1 calls
out as the reason "a wrong withdrawal number puts meat or milk into the food chain".

**Winner: 09.** Absolute `Duration(hours: days * 24)`, then ceil to the next local midnight. 09 is
the only note that measured it, and it is measuring the safety-critical direction (short, not long).

> **Decision-log line:** withdrawal clear date = ceil-to-next-local-midnight of
> (administration instant + N × 24 h). Civil-day `DateTime(y, m, d + n)` arithmetic is banned for
> withdrawal; 04's blanket "use calendar arithmetic for date offsets" rule is narrowed to
> season boundaries and display-only date offsets, and the `elapsedCivil.inHours == 167` DST
> regression test from 09 is mandatory.

---

## A3. Is `clear_date` stored or recomputed?

**Side 1 (01 §10.4, and spec §10's data model, which literally lists `clear_date` on `Treatment`):**
store it. Rationale: it is not derived, it is *a record of what the app told the user* and printed
into the medicine-book PDF; recomputing later could silently produce a different date after a DST
transition or a device timezone change, which is a §12.4/§12.5 violation. 01 attaches four rules:
computed once, never silently recomputed, mismatch raises `ClearDateDisagrees`, inputs stored
forever.

**Side 2 (09 §, table row "`Treatment.clear_date` | derived civil date | *not stored* | Recompute"):**
do not store it, because a stored derived value goes stale when `date` or `withdrawal_days` is
edited and nothing guarantees the recompute fires. Cost of recomputing is zero.

**Winner: 01, with 09's algorithm.** Store it, because spec §10 puts it in the model and because the
PDF handed to a vet or an abattoir must match what the app displayed on the day. 09's staleness
objection is already answered by 01's `ClearDateDisagrees` consistency flag — which is *shown, never
applied*, and is therefore a §12.4-compliant answer rather than a silent correction.

> **Decision-log line:** `clear_date` is the one stored derived value; computed exactly once at
> write time by the single `clearDateFor()` function using 09's absolute-hours algorithm; its
> inputs are stored alongside it forever; a mismatch is surfaced as a warning and never auto-fixed.

---

## A4. DateTime storage format: drift TEXT ISO-8601 vs INTEGER epoch millis

**Side 1 (03, "High", explicitly day-0 and irreversible):** `store_date_time_values_as_text: true`
in `build.yaml`, ISO-8601 TEXT. 03 also warns: "Changing `store_date_time_values_as_text` after
launch … Drift: 'not compatible with existing database schemas'. Set it in the very first commit."

**Side 2 (09 #5, "High"):** instants → `INTEGER` UTC epoch millis via an
`extension type Instant(int epochMillis)`; civil dates → `TEXT 'YYYY-MM-DD'`. 09 explicitly rejects
drift's `DateTime` columns and names the global build flag as the reason: "The mode is a global
build-flag decision that applies to *every* column."

Both are marked High confidence. Both are irreversible after launch. They cannot both be taken and
nobody noticed.

**Winner: 09.** The decisive argument is 09's, and it is a modelling argument rather than a storage
one: an *instant* and a *civil date* are different kinds, a lambing happened at a moment while a
withdrawal clears on a date, and drift's single global flag forces one representation onto both.
09's `Instant` extension type also composes with the absolute-time clear-date rule in A2, whereas a
timezone-aware ISO string invites exactly the civil-day arithmetic A2 bans.

**Cost of this ruling, stated honestly:** 03's `mixin Identified` (`createdAt`/`updatedAt` as
`dateTime()`), its `CHECK (end_date IS NULL OR end_date >= start_date)` constraints, and every
`dateTime()` column in its schema must be rewritten as `integer()` (instants) or
`text()` (civil dates) before the first migration snapshot is generated. That is cheap on day 0 and
impossible on day 400.

> **Decision-log line:** instants are `INTEGER` UTC epoch millis behind
> `extension type Instant`; civil dates are `TEXT 'YYYY-MM-DD'` behind `extension type LocalDate`.
> `store_date_time_values_as_text` is not set and drift `dateTime()` columns are not used anywhere.

---

## A5. What `main()` does: four incompatible bootstraps

| Note | `main()` |
|---|---|
| 01 §13 | awaits nothing; constructs `AppDatabase` eagerly ("drift opens lazily"); `runApp` immediately |
| 02 §4.1 | `await openShedBookDatabase()` **and** `await LocalNotificationGateway.initialize()` before `runApp` |
| 05 §5.4 | `await SettingsStore.open()` before `runApp` to resolve the palette |
| 08 #1 | *nothing* async: `ensureInitialized` → install error handlers → `runApp`; DB, migration, tz DB, notification plugin, locale and `path_provider` all move into a post-first-frame `FutureProvider` |

01's own open question #3 concedes the load-bearing assumption is unverified: "Does `AppDatabase`
construction really do zero IO before the first query, given `drift_flutter`'s `path_provider`
call?" **03 answers it: no.** 03's opener passes `databaseDirectory: getApplicationSupportDirectory`,
which is a `Future` — the open path is inherently async, so 01's "construct eagerly, nothing is
awaited" is a distinction without a difference the moment 03's directory override lands.

**Winner: 08.** It is the only note that reasons about the first *frame* rather than the first
*query*, and it is the only one whose design survives A6 (the DB directory override) unchanged.
05's argument survives intact under 08 and should be quoted in the log: because *every* theme is
dark, a wrong first frame is a dark first frame, so the palette can be read after `runApp` at no
cost. 02's notification-plugin warm-up moves into 06's `reconcile()` on app start.

> **Decision-log line:** `main()` = `ensureInitialized()` → install error handlers → `runApp()`.
> Nothing is awaited. DB open, migration, `path_provider`, timezone DB, settings/palette and
> notification init all happen after the first frame. The first frame is a static dark Quick Entry
> shell with a fully interactive keypad and no data.

---

# B. The offline-purity contract — the most important consistency check, and it is not closed

## B1. `in_app_purchase` is invisible to the offline audit

06 is the offline audit. It publishes a **"Target manifest permission set (the whole list)"** of
seven permissions and says "That is the whole point of this document." A grep of 06, 01, 04 and 08
for `in_app_purchase`, `billing` or `BILLING` returns **zero hits**. 07 then adopts
`in_app_purchase` 3.3.0, which pulls `com.android.billingclient:billing:8.0.0` and adds
`com.android.vending.BILLING` to the merged manifest.

So 06's canonical permission list is wrong the moment monetization ships, and 01's
`tool/check_offline.dart` allowlist — which fails CI on any unlisted package — does not contain
`in_app_purchase`, `in_app_purchase_android`, `in_app_purchase_storekit` or
`in_app_purchase_platform_interface`. The offline gate and the monetization decision were designed
in ignorance of each other.

**Ruling:** 06's permission list becomes eight entries with `com.android.vending.BILLING` added and
sourced to the billing AAR; 01's allowlist gains the four `in_app_purchase*` packages with a
one-line justification each; and the audit must state that the billing AAR is a *Play-Services-
adjacent* artifact whose transitive Gradle graph is reviewed on every Billing Library bump.

## B2. `tools:node="remove"` on `ACCESS_NETWORK_STATE` is unverified against Play Billing

01 §12.1, 04 §10.2 and 06 §11.1 all independently write:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
```

07 §1.1(c) admits, in writing: *"that mirror is billing 2.0.3. I could not fetch the AAR manifest
for billing **8.0.0** … from a primary source … Treat 'no INTERNET in billing 8.0.0' as **highly
likely but requiring one empirical check**."* I could not verify it either — Google's
[Integrate Google Play's billing system](https://developer.android.com/google/play/billing/integrate)
page documents no manifest permissions at all, and the AAR manifest is not published as text.

Three notes therefore hard-code a *removal* of a permission that a library six major versions newer
than the one anyone checked may declare. If billing 8.0.0 declares `ACCESS_NETWORK_STATE` and the
merger strips it, the failure surfaces as a purchase flow that misbehaves on a flaky connection —
in production, on someone else's phone.

**Ruling: 07's §1.6 empirical check is promoted from "day one of the Android work" to a
prerequisite for writing the manifest at all.** Run `flutter build appbundle --release`, read
`build/app/outputs/logs/manifest-merger-release-report.txt`, and record the actual permission set
contributed by billing 8.0.0 in the decision log before any `tools:node="remove"` line is committed.
Removing `INTERNET` is safe and proven; removing `ACCESS_NETWORK_STATE` is not yet proven and must
not be committed on faith.

## B3. Complete inventory of things that would introduce a network path, and the ruling on each

| # | Recommendation | Note | Network exposure | Ruling |
|---|---|---|---|---|
| 1 | Flutter's `offline-first` design pattern (`connectivity_plus`, `workmanager`, `battery_plus`, FCM, `Timer.periodic` sync) | 01 §1.4 rejects it | `ACCESS_NETWORK_STATE` merged; platform channel that exists to ask about a network | **Drop.** Unanimous, correct, and the single most likely reintroduction vector. |
| 2 | Crashlytics / Sentry / Bugsnag in `FlutterError.onError` | 01 §9.3, 08 #10 both reject | Network + exfiltration of data spec §4.5 calls commercially sensitive | **Drop.** Local capped ring-buffer log, exported via the share sheet on user action only. |
| 3 | `google_mlkit_text_recognition` (tag OCR) | 06 **cuts**; 07 says "if it ships, use the bundled model" and "consider iOS-Vision-only OCR for v1" | Bundled artifact still transitively depends on `play-services-base`/`basement`, which contribute `INTERNET` + `ACCESS_NETWORK_STATE`; +38 MB iOS; ML Kit sends usage metrics to Google | **Drop entirely, both platforms.** 06 wins; see C7. |
| 4 | `speech_to_text` (voice tag entry, spec §7.1) | 06 defers to v1.1, gated | The plugin README instructs you to add `INTERNET`; recognition runs in *another process* whose network access our manifest cannot constrain; no Dart-visible on-device guarantee | **Drop from v1** and record it as a deliberate spec §7.1 deviation, not an oversight. Ship 06's voice *note* instead. |
| 5 | `printing` 5.15.0 (PDF print dialog) | 06 rejects | Depends on `http` and instantiates a live HTTP client | **Drop.** `pdf` alone + share sheet. |
| 6 | `in_app_purchase` 3.3.0 | 07 adopts | Binder IPC to the Play Store / XPC to the App Store daemon — *someone else's* socket; adds `com.android.vending.BILLING` | **Keep, gated behind explicit user action only** (Unlock / Restore), never on the launch path. See B1, B2, C6. |
| 7 | `sqlite3` build hooks download prebuilt binaries from GitHub releases at **build** time | 03 §2.5 | Build machine only; the shipped binary has no network code | **Keep.** Must be documented in the README so a plane-mode `flutter clean && flutter build` failure is not mistaken for a regression. Neither 01's nor 07's CI plan mentions it. |
| 8 | `build_runner` pulling `shelf` / `web_socket_channel` into `pubspec.lock` | 02 §10 footnote | dev-only, never shipped | **Keep**, but 01's `check_offline.dart` allowlist is a `pubspec.lock` scan and will flag them — the allowlist must distinguish `dependencies` from `dev_dependencies` or it fails on day one. |
| 9 | A **hosted privacy-policy URL** | 07 #12 | The one piece of internet infrastructure the project cannot avoid | **Keep**, and note it is *outside* the app: no `url_launcher`, full policy text also shipped as static Dart strings. Correctly handled; flagging only because it is the one honest exception to "no network anywhere". |
| 10 | System share sheet, Android photo picker, OS speech recognizer | 06 §0 tier 3 | Other processes with their own network access | **Keep**, and adopt 06's tier-1+tier-2 public wording verbatim. **Do not write "your data never leaves your phone."** |

**The one claim the doc set must stop making:** 03 §1.1 says drift has "Zero network surface … no
manifest permissions merged in" and 02 §1.3 says "the 'no network path' claim survives Riverpod 3.x
intact". Both are true *and both are about the wrong layer*. The binding claim is 06's tier 1 + 2,
and it is only true if items 3, 4 and 5 above are actually dropped.

---

# C. High — silent incompatibilities

## C1. The `DateTime.now()` ban fires on five of the ten notes' own code

01 §11.3 puts the literal string `DateTime.now(` in `check_layers.dart`'s text bans for all of
`lib/`. 04 gate A and 09 #8 independently mandate the same ban with a source-scanning policy test.

Then: 02 §4.1 defines `class SystemClock implements Clock { DateTime now() => DateTime.now(); }`,
03 uses `DateTime.now()` in its export/media code (four sites), 05 §11 drives the pen timer from
`DateTime.now()`, 06's `reconcile()` calls it twice, and 08 calls it in lifecycle handling, the
resume policy, the crash log and the session-lock file (six sites).

**Winner: 01/04/09's ban.** But it needs one carve-out and one rewrite:

- 02's bespoke `abstract class Clock` / `clockProvider` is a **second, competing clock abstraction**
  and must be deleted in favour of `package:clock`'s ambient `clock.now()` + `withClock`. Two clock
  seams is worse than none, because a test that fakes one does not fake the other.
- The ban needs exactly one allowlisted file (`lib/core/time/app_clock.dart`) and the scan must skip
  `*.g.dart`. 01 already notes this; 04 and 09 do not.

> **Decision-log line:** one clock, `package:clock`. `DateTime.now()` appears in exactly one
> allowlisted file. `lib/di.dart`'s `Clock`/`SystemClock`/`clockProvider` from 02 is deleted.

## C2. Three incompatible positions on SQL-side time

- 01 §10.6 and 04 §2.4 ban `CURRENT_TIMESTAMP` / `date('now')` and 04 extends the scan to
  **`strftime` and `datetime`** in all of `lib/`.
- 03 chooses drift's TEXT datetime mode, in which drift emits SQL date functions for comparison and
  extraction, and writes `CHECK (end_date IS NULL OR end_date >= start_date)` constraints.
- 09 denormalises a `local_date TEXT` column at insert precisely *because* "SQLite cannot [group by
  the shepherd's civil day] correctly without a tz database, and Dart can."

Under ruling A4 (integer instants + text civil dates) this mostly resolves itself, and it should be
stated as the resolution rather than left to collide: **all time arithmetic happens in Dart; SQL
only compares and orders opaque integers and lexicographically-sortable date strings.** 04's scan
should ban `CURRENT_TIMESTAMP`/`CURRENT_DATE`/`CURRENT_TIME`/`date('now')`/`datetime('now')` and
drop the bare `strftime`/`datetime` tokens, which will false-positive and get weakened.

## C3. State restoration: `RestorationMixin` vs none

**02 (High):** `restorationScopeId` + `RestorationMixin` for the keypad query string and scroll
offsets, plus an iOS `FlutterViewController` restoration-ID step in `Main.storyboard`.
**08 (High):** no `RestorationMixin`, no `restorationScopeId`; resume to Quick Entry with nothing
selected after ~2 minutes backgrounded, because "restoring a stale selected ewe at 3am is a
data-integrity bug, not a convenience."

**Winner: 08.** It is the only side that argues from *correctness* rather than convenience, it
aligns with 02's own §6.3 decision to deliberately cold-start to Quick Entry, and 02's open
question #2 already concedes the keypad-restore may not be worth it. Dropping restoration also
deletes the easy-to-miss iOS storyboard step.

## C4. Theme: two different dark palettes, and one of them contradicts the spec

**05:** three palettes (`night` **#0B0D0E**, `redShift` **#000000**, `daylight`), all dark;
`theme`, `darkTheme`, `highContrastTheme` and `highContrastDarkTheme` **all set to the same object**.
**10:** `darkTheme` on **#121212** with **#E6E6E6** body text; a *hand-built, genuinely different*
`highContrastDarkTheme`; and — decisively — **"Build it as amber-shift, not red-shift"** because
red-on-black is one of the worst combinations for protanopia (`#FF0000` on `#121212` = 4.69:1 for a
normal observer, far worse for a protanope) while `#FFB000` measures 10.23:1.

Three separate conflicts here:

1. **Surface value.** #0B0D0E vs #121212. **Winner: 05** — it publishes measured ratios for its
   whole palette against #0B0D0E and gives a surface *ramp* argument (elevation without outlines)
   that 10 does not rebut. 10's #121212 rationale (pure black smears on OLED) is an argument against
   #000000, which 05 also rejects for the same reason.
2. **`highContrastDarkTheme`.** 05 sets it to the same object as `darkTheme` while simultaneously
   claiming to "honour `highContrast` … from `MediaQueryData`". That is internally inconsistent:
   the slot becomes dead plumbing. **Winner: 10** — ship a genuinely higher-contrast palette in
   that slot, and expose it as an in-app toggle too, since `highContrast` only fires on iOS.
3. **Red vs amber.** Spec §5 says "Optional **red-shift** mode" and §7.10 says "Dark / **red-shift**
   theme". 10 unilaterally substitutes amber. **Ruling: ship both, labelled honestly** — 10's own
   proposed wording ("Amber (recommended)" / "Deep red (best for night vision, hardest to read)") is
   the right answer and it is already in 10; it just needs to stop being framed as *replacing*
   red-shift, which is a spec deviation.

## C5. Font weight: 10's w700 cap vs 05's `weightBump: 100`

10 #5 / §4.5: **"no text style in Shed Book exceeds `FontWeight.w700`"**, citing
[flutter#139712](https://github.com/flutter/flutter/issues/139712) — with the Bold Text accessibility
setting on, w800/w900 styles render **lighter**, at w700.

05 sets `labelLarge`, `displaySmall`, `displayLarge`, `displayMedium` and `headlineLarge` at w700,
then adds `weightBump: 100` for both `boldText` **and** red-shift mode — pushing them to w800. 05
even documents the outcome: "`labelLarge` w700 → w800. AH Next's axis tops out at 800, so it clamps."

So 05's boldText handling walks straight into the bug 10 cites, on the app's most important text
(button labels and pen-tile numerals) in the exact accessibility mode the bug affects.

**Winner: 10.** Cap at w700. 05's "when you cannot buy contrast, buy stroke" argument for red-shift
survives via its *other* lever, which is already in 05: bump `bodySize` 18→20 and `numeralSize`
40→44. Delete `weightBump`.

## C6. Entitlement: read at launch vs nothing async before the first frame

07 #3 / §5: the entitlement is "a locally-persisted fact in SQLite", with "**Zero store calls on the
launch path. Cold start reads one SQLite row.**" 08 #1: no DB access at all before the first frame.

These are compatible only if the first frame is entitlement-agnostic — which it is, and which nobody
says. Write it down, because the failure mode is a paywall flash at 3am.

> **Decision-log line:** the first frame renders the unlocked-neutral Quick Entry shell. The
> entitlement row is read with the rest of the post-first-frame bootstrap. No screen on the 3am path
> ever branches on `unlocked`, so a late read is unobservable. (07's own widget test — "no upgrade
> widget renders on Quick Entry, Lambing Entry, Lamb Card, Foster or Pen Board with
> `unlocked: false`" — already enforces this; it just needs to be named as the mechanism.)

## C7. OCR: cut entirely (06) vs "consider iOS-Vision-only for v1" (07)

06 rejects `google_mlkit_text_recognition` on four independent grounds (transitive
`play-services-base`/`basement` → `INTERNET` + `ACCESS_NETWORK_STATE`; +38 MB iOS against a
sub-20 MB payload budget; Google's own terms say ML Kit sends usage metrics; observed 15-minute
POSTs to `firebaselogging.googleapis.com`) and explicitly says **"do not ship an iOS-only Apple
Vision channel either."** 07 #16 says "If Android tag OCR ships, use the BUNDLED ML Kit model
(+~4 MB per script) … Consider iOS-Vision-only OCR for v1."

**Winner: 06.** 07's own §1 designs a CI gate that fails the build if `INTERNET` reaches the
manifest; its OCR suggestion would trip that gate on Android and would ship a platform-asymmetric
feature (present on iPhone, absent on Android) into a spec that describes one product. Spec §7.1
marks tag OCR "Optional … Always a shortcut, never the only route," so cutting it costs nothing
contractual — but it must be recorded as a deliberate deviation.

## C8. Reminder scheduling inside a database transaction

01 §2.3: "scheduling a 'colostrum window' reminder must happen in the same repository call that
inserts the lambing, so there is never a lambing without its reminder" — i.e. a
`NotificationScheduler` call inside `_db.transaction(...)`.
06 §1: **never** `zonedSchedule()` on write; write the reminder row to SQLite and let one idempotent
`reconcile()` project the soonest 56 into the OS.
08: "Never hold a SQLite transaction open across an `await`."

01's design puts a platform-channel round-trip inside a drift write transaction, on the 3am path,
against a 64-slot iOS budget that 06 shows a 400-ewe flock blows past by an order of magnitude
(~500 pending reminders).

**Winner: 06.** 01's invariant ("never a lambing without its reminder") is preserved *better* by
06's architecture, because the reminder row is written in the same transaction as the lambing and
the OS projection is a rebuildable cache rather than a durable fact.

## C9. Timezone strategy: three positions

- **09 #7 (contrarian, explicit):** use `DateTime` + `toLocal()` for display and arithmetic; use
  `package:timezone` **only** where `flutter_local_notifications` forces it, because its IANA
  snapshot is frozen at build time and this app never updates.
- **04:** make `tz.Location` an *injected value* used throughout the domain, with mandatory
  Europe/London DST tests and a `TZ=Pacific/Chatham` hostile CI job.
- **06:** adopt `timezone` 0.11.1 with IANA 2025c bundled.

**Winner: 09's boundary, 04's tests.** `package:timezone` is confined to the notification-scheduling
seam (06's `tz.TZDateTime.from(dueAtUtc, tz.local)`), everything else uses `Instant` + `toLocal()`.
04's DST cases and hostile-TZ job survive intact — they just assert against the device zone rather
than an injected `tz.Location`. 09's staleness argument is real and belongs in the log: a
one-time-purchase app that a shepherd does not update for three seasons will have a *more* correct
zone from the OS than from a bundled snapshot.

## C10. CI: two runner budgets, four permission-gate mechanisms

**Runners.** 04 requires a **pinned `macos-latest` runner for goldens, gating every PR**. 07 §9
allocates macOS to **tags only**, because GitHub bills macOS at a **10× multiplier** and the Free
plan's 2,000 minutes = 200 macOS minutes/month — "a per-push macOS build burns the whole quota in a
week." 07 also says iOS is built manually on the developer's own Mac for v1.

**Winner: 07 on the budget, 04 on the necessity.** Goldens move to a tag-triggered / manually
dispatched macOS job and to a `make goldens` target the developer runs locally before tagging. They
are not a per-PR gate. 04's own reasoning supports this: it says goldens are ~8 images pinned to one
exact Flutter version, i.e. they change only on deliberate re-baseline PRs.

**Permission gate.** Four mechanisms across four notes: 01 greps `build/app/intermediates/`; 04 uses
`apkanalyzer manifest permissions` on the release **APK**; 06 greps the manifest-merger report plus
`aapt2`/`bundletool`; 07 uses `bundletool dump manifest` on the release **AAB**. **01's is unsound**
— `build/app/intermediates/` accumulates debug and profile artifacts, and both 02 and 04 confirm
Flutter's debug/profile manifests *do* declare `INTERNET`, so 01's grep will fire on a stale
directory. **Winner: 07's `bundletool dump manifest` on the shipped `.aab`**, because 07 also rules
that the AAB is what ships; 06's merger-report grep is kept as the *diagnostic* that names which
dependency added a permission.

## C11. Lints: `flutter_lints` vs `very_good_analysis`

01's tree comments `analysis_options.yaml # include: package:flutter_lints/flutter.yaml`; 02's
pubspec pins `flutter_lints: ^6.0.0`. 07 #8 says use `very_good_analysis` 10.3.0 and "**What is not
acceptable is `flutter_lints` alone, with no strict modes**."

**Winner: 07**, but take its own stated fallback rather than its headline: `flutter_lints` +
an explicit `analyzer: language: {strict-casts, strict-inference, strict-raw-types}` block gets the
90% (07's own words) without ~215 rules of noise for a solo developer. 07's `strict-casts` argument
is the load-bearing one and it is specific to this app: every row out of SQLite and every field out
of a JSON backup is a `dynamic`-adjacent boundary. 01 and 02's pubspecs must be updated either way.

---

# D. Medium — one thing with more than one owner

## D1. The database directory

01 §6.4 writes `driftDatabase(name: 'shed_book')` with the comment "drift_flutter stores
`$name.sqlite` under `getApplicationDocumentsDirectory()`". 03 §3.1 and 08 both mandate overriding
to `getApplicationSupportDirectory`, and 03 gives a product-ending reason: if
`UIFileSharingEnabled` is ever set so users can grab exports from the Files app, all of `Documents/`
becomes user-visible and **user-deletable**. **Winner: 03/08.** 01's snippet must change.

## D2. Backup and restore have two formats and two restore paths

03 makes `VACUUM INTO` the "DB snapshot for backup/export" and argues settings live in the DB so
"one `VACUUM INTO` snapshot restores a complete, coherent app state". 06/07/08 treat **JSON** as
*the* backup (06: `backup.json` + a sibling media ZIP, restored into a temp DB then swapped; 08:
"The backup format is JSON (spec §7.9)"). Spec §7.9 names JSON only.

**Winner: JSON as the restore format** (spec-mandated, cross-device, inspectable, and the only one
that survives a schema change between the exporting and importing app versions). `VACUUM INTO` is
demoted from "backup" to what it actually is: the correct *mechanism* for producing a `.sqlite`
snapshot for the Diagnostics / "save a copy of the damaged file" path in 01 §13.2 and 08 #15. Two
restore code paths is two migration surfaces and one of them has no spec requirement behind it.

## D3. Timestamp provenance has four shapes for one spec rule (§12.5)

01: `occurredAt` + `occurredAtSource` + `occurredAtEditedAt`. 03: "Timestamps are two columns, not
one." 04: an enum + `originalInstantUtc` + `editedAtUtc`. 09: `RecordedTime {effective, capturedAt,
originalEffective?, TimeSource}`.

**Winner: 09.** It is the only one that keeps the *original* effective value (so "edited" can show
what it was edited *from*), it is a value type rather than three loose columns, and 04's frozen
enum-name assertion and round-trip tests apply to it unchanged. 01's and 03's shapes lose the
pre-edit value, which makes the §12.5 label "edited" true but uninformative.

## D4. The withdrawal type has two incompatible models, and 04's policy tests are written against
the losing one

**09 #1/#2:** a `sealed` class with three states — `WithdrawalDays(n)` / `WithdrawalNotApplicable` /
`WithdrawalNotRecorded` — with a private generative constructor and one entry point
`WithdrawalDays.asEnteredByUser(days:, target:)`; and **0..n entries per treatment**, because one
product routinely prints different meat and milk figures.
**04:** an `extension type` with exactly one factory `WithdrawalPeriod.asEnteredByUser`, and four
policy tests including "the Drift column has null `defaultValue` and null `clientDefault` and is
**non-nullable**" — which presumes exactly one column, matching spec §10's
`withdrawal_days_user_entered`.

**Winner: 09.** A non-nullable single `int` column cannot express "I did not look at the bottle",
which is the exact confusion spec §12.1 exists to prevent, and a dairy flock needs two numbers. 04's
four-gate policy test must be rewritten against a `treatment_withdrawals(treatment_id, target,
days)` child table: no default on `days`, no row implies `NotRecorded`, and an explicit
`NotApplicable` marker row. An `extension type` is also the wrong tool here — 09 is right that a
hand-written sealed class is what gives you a *private* generative constructor.

## D5. Season statistics: SQL views vs `StatResult`

01 §10.3: aggregates are drift `View`s, computed on read, returning nullable doubles.
09 #9: every statistic returns a `StatResult` carrying `value`, `definition`, `numerator`,
`denominator`, `caveats`, `notComputableReason`, because the same season yields **120% / 100% / 80%
/ 200%** under four legitimate definitions.

A SQL view cannot carry `caveats` or `notComputableReason`. **Winner: 09 for the return type, 01 for
the data source** — the view produces the raw counts, a pure Dart function assembles the
`StatResult`. Say so explicitly, because 01's "compute on read, expressed as drift views" reads as a
complete answer and is not.

## D6. Terminology has four homes, and one of them breaks the layer rule

01 puts it in `lib/domain/terminology.dart`; 03 in a `TerminologyOverrides` Drift table; 09 as a
closed `enum AnimalClass` + user-editable `TermLabel(singular, plural)` overlay; 10 as data "seeded
once from ARB defaults".

10's seeding requires the code that seeds to read `AppLocalizations` — a Flutter type — which 01's
`check_layers.dart` forbids in both `lib/domain/` (`package:flutter/` banned) and `lib/data/`
(`package:flutter/material.dart` banned). **Winner: 09's shape, 03's storage, 10's placeholder
rule.** Seeding happens in a `lib/features/settings/` bootstrap that already has a `BuildContext`,
not in domain or data. 10's non-negotiable rule survives and should be the headline: no domain noun
appears literally in any ARB message.

## D7. Free-tier cap: three placements, one of which breaks spec §7.1

01 open question #6: "a `data/`-layer guard on `FlockRepository.createEwe` returning a
`WriteOutcome`". 02 open question #4: "enforced in the write path (the ViewModel command)". 07 #5:
create-on-the-fly during Quick Entry / Lambing Entry is **never** blocked; the row is created and
flagged `over_free_cap`; only the calm-UI Flock screen and "start a second season" are gated.

01's repository guard would block `createEwe` regardless of caller, which is exactly the 03:20
failure 07 names as "Catastrophic; kills the app's one promise" and which spec §7.1 forbids ("Never
block an entry to make the user go and set something up first"). **Winner: 07.** The guard takes an
`EntryContext`, and `EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap`.

## D8. Golden count and matrix

04: ~8 goldens, dark theme, tagged `golden`, one runner. 10: text-scale goldens at
{1.0, 1.3, 2.0} × {bold on/off} — six variants, which across 12 screens is 72 images.
**Winner: 04's count, 10's dimensions applied to the *widget* matrix instead.** 04's own overflow
matrix (12 × 3 × 3 × 2 = 216 assertions) already covers text scale and bold text without pixels;
goldens stay at ~8 and cover the things a `takeException()` assertion cannot see.

## D9. The pen timer ticks at three different rates

01 §10.2: one app-level ticker at **30 s**, boundary-aligned so all cells update together.
05 §11 and 08: `Stream.periodic(Duration(minutes: 1))`.
Pick one. **Winner: 01's boundary-aligned ticker at 60 s** — 01's alignment argument is the good one
("a grid where cells update at different moments reads as noise under a head torch") and the display
granularity is hours, so 30 s buys nothing.

## D10. Smaller inconsistencies worth a line each

- **`sqlite3_flutter_libs`.** 03 and 08 both say never add it (`0.6.0+eol`, no-op). 01's
  `check_offline.dart` allowlist lists it as an expected package (harmless — `drift_flutter` drags
  it in transitively) but **02's resolution experiment added it as a direct dependency**, so 02's
  "117 packages, resolves cleanly" figure was measured against a pubspec the project will not have.
  Re-run A1's resolution check against 03's actual pubspec before the 2.6.1 pin is treated as
  proven.
- **`*.freezed.dart` in 04's lcov strip.** freezed is rejected by 01, 02 and 09. Dead config that
  implies it might be used.
- **`accessibility_tools` (10).** Listed as a `dev_dependency`, but it is a widget that must wrap
  the app tree — so `lib/` imports it, which breaks a release build unless guarded, and it is not in
  01's allowlist. Either wire it behind `kDebugMode` with an explicit note, or drop it.
- **FTS5 availability.** 03 proves `SQLITE_ENABLE_FTS5` is compiled into the bundled binary and
  therefore "guaranteed, on every device"; 09 #17 puts note search "behind a runtime capability
  probe". The probe is unnecessary under 03's evidence; keep it only as a startup assertion.
- **Tag uniqueness on the 3am path.** 03 makes `Ewes.tag` `UNIQUE` and proposes that typing a culled
  ewe's tag surfaces a "412 — culled 2025 — use anyway? / new animal?" prompt. That is a
  disambiguation dialog on the create-on-the-fly path, which spec §7.1 and 05's bottom-sheet rules
  both push against. Resolve before the schema is frozen: either tags are unique forever (and
  reuse is impossible) or they are unique *within a status scope* and the prompt moves off the
  entry path.
- **Wakelock.** 06 scopes it to QuickEntry/LambingEntry/PenBoard, released on `dispose` and any
  non-resumed state; 08 makes it session-scoped with a 30-minute auto-expire, released on `hidden`.
  Merge: default-off Settings toggle, session-scoped, 30-minute expiry, released on any non-resumed
  state. (08's expiry is the safety-relevant half; 06's release condition is the stricter half.)
- **App size.** Spec §11: "Total app payload well under 20 MB." 07 reframes to "bundled assets under
  5 MB" and concedes iOS *install* will be 25–45 MB. That is a spec deviation and needs an owner,
  because 05's variable font, 10's `flutter_localizations` + `intl`, and 06's plugin set all draw on
  the same budget with no single note tracking the total.

---

# E. Scope creep — ceremony that does not earn its keep for one developer shipping v1

| Item | Note | Why it is too much |
|---|---|---|
| `tool/check_layers.dart` **plus** `tool/check_offline.dart` **plus** `tool/check_tokens.dart` **plus** a source-scan policy suite (`DateTime.now()`, `strftime`, `fix*/correct*/normalize*`, numeric literals near "withdrawal", raw `GestureDetector`) | 01, 04, 05 | Five bespoke source-scanning gates, each with its own false-positive surface, before a single screen exists. Merge into **one** `tool/check_policy.dart` with a table of rules, one allowlist file, and one exit code. |
| Migration tests covering **every** from→to pair with `SchemaVerifier.migrateAndValidate` **and** `testWithDataIntegrity` **and** a CI check that `make-migrations` produces no git diff | 04 | The from→to matrix is correct and non-negotiable (no cloud backup). The no-diff CI check is the one to keep. `testWithDataIntegrity` on every pair is quadratic busywork at v1 — apply it to the N-1→N pair and to any migration that rewrites a table. |
| Four independent proofs of "no network path" (analyzer scan + dependency allowlist + APK permission gate + `HttpOverrides.global`) | 04 | Two earn their keep: the `.aab` permission gate (mechanical, catches the real risk — a plugin merging a permission) and the direct-dependency allowlist. The analyzer import scan duplicates the allowlist; `HttpOverrides.global` is a runtime belt over a manifest brace that already makes sockets impossible on Android. |
| Four independent tests for "never default a withdrawal period" | 04 | Under ruling D4 the sealed type makes the wrong state unconstructible. Keep the schema assertion (no default in the committed drift schema JSON) and the widget test. Drop the source heuristic banning numeric literals near "withdrawal" — it will fire on `CHECK` constraints and test fixtures. |
| A `12 × 3 × 3 × 2 = 216` overflow matrix **and** a `12 × 2` contrast/label guideline run **and** ~8 goldens **and** text-scale goldens at 6 variants | 04, 10 | The 216-cell matrix is genuinely the best value-per-line in the suite. Everything after it is duplicated coverage. See D8. |
| Pub workspaces / melos / a separate pure-Dart domain package | 01 §4 | 01 correctly rejects all three. Recording it here so nobody re-litigates. |
| `glados` property tests + a hand-rolled seeded `FlockGenerator` | 04 | Reasonable for the JSON round trip. Do not extend it; a seeded generator that nobody understands in season three is worse than a fixture. |
| Answering spec open question 4 from a desk | 05 | 05 declares "No volume-button shortcuts; spec open question 4 is answered no." Spec §17.4 makes this contingent on whether the target hardware registers taps through a freezer bag — a **hardware test**. 01 open question #4 and 02 open question #2 both correctly leave it open. 05 cannot close it without the shed observation (spec §17.1). **Reopen it.** |

---

# F. Spec conflicts

| Spec clause | Conflicting recommendation | Ruling |
|---|---|---|
| §5 "Optional red-shift mode"; §7.10 "Dark / red-shift theme" | 10: ship **amber-shift instead of** red-shift | Ship both, labelled honestly (10's own wording). Amber is the default recommendation; red remains available because the spec names it. |
| §5 "no long-press-only actions… no swipe" | 05 and 10 both comply. 03's culled-tag disambiguation prompt sits on the create-on-the-fly path | See D10. Move the prompt off the entry path. |
| §7.1 "Optional voice tag entry using OS on-device speech recognition" | 06 cuts it from v1 | Accept (it is optional), but record it as a **deliberate deviation with a reason** — recognition runs in another process whose network access our manifest cannot constrain — not as silence. |
| §7.1 "Optional tag OCR" | 06 cuts it; 07 suggests iOS-only | Cut, both platforms. See C7. |
| §7.1 "Create-on-the-fly… Never block an entry" | 01's repository-level free-tier guard on `createEwe` | 07 wins. See D7. |
| §10 data model lists `clear_date` on `Treatment` | 09 says do not store it | Store it, with 09's algorithm. See A3. |
| §11 "Total app payload well under 20 MB" | 07 reframes to "bundled assets under 5 MB"; concedes iOS install 25–45 MB | Accept the reframe, but state the deviation in one place and give the total-size budget an owner. |
| §12.1 "Never default a medicine withdrawal period" | 04's single non-nullable column cannot express "not recorded" | 09 wins. See D4. |
| §12.4 "Never silently correct" | 03 writes a `tagDigits` normalised projection alongside `tag` | Not a violation (the typed value is preserved verbatim), but 04's source ban on `normalize*` in `lib/domain` will fire on the helper. Scope the ban to functions that *return a corrected domain value*, not to projections. |
| §12.5 "Timestamps are honest" | Four different column shapes | 09 wins. See D3. |
| §13 "no sync, no cloud backup of any kind" | Nothing violates this. 01's rejection of Flutter's offline-first page is the correct reading | Keep 01 §1.4 verbatim in the engineering doc; it is the single best anti-regression artefact in the set. |
| §14 free tier "capped at a small flock (e.g. 15 ewes) **or** one season" | 07 implements both, season-primary | Fine, and 07 flags it as an owner call. Decide it once and stop calling it open. |

---

# G. The short list — what must be decided before commit #1

1. `flutter_riverpod` **2.6.1** (A1) — and delete every Riverpod-3-only API from the notes.
2. Instants as **`INTEGER` epoch millis**, civil dates as **`TEXT`** (A4) — irreversible after the
   first migration snapshot.
3. Withdrawal clear date = **absolute hours, ceil to local midnight** (A2), stored once (A3).
4. `main()` **awaits nothing** (A5); database in **application support** (D1).
5. Run 07 §1.6's **manifest-merger check against a real release AAB** before writing any
   `tools:node="remove"` line (B2), and add `in_app_purchase*` to 06's permission list and 01's
   allowlist (B1).

Everything else in this document can be settled in week two without rework.
