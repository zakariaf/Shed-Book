# N30 — Monetization

| | |
|---|---|
| **`00-README` §9 step** | 11 |
| **Depends on** | N29 |
| **Size** | L |
| **Was** | E27, minus the `FreeTierPolicy` wiring which moved to N06 and N14 |
| **Branch** | `epic/n30-monetization` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

One non-consumable unlock, `shed_book_unlock`, bought once, forever.

Eight tasks build the whole of it: the seventh gateway (`PurchaseService`), the entitlement as a row,
the four-variant unlock flow, the **entitlement source** the two gated verbs have been missing since
N14, the two static upgrade rows, the price that is never a literal, the two stores' privacy artefacts,
and the sweep that proves none of it reaches a shed screen.

Three sentences frame the epic, and everything in it is a consequence of one of them.

**The store is the source of a one-time fact, not a runtime dependency** (`11 §1.2`). Ask it exactly
twice — when the user taps Unlock, and when the user taps Restore. Write the answer to SQLite. Never
ask again. Every rule in `11 §4`, `§5` and `§6` falls out of that one sentence.

**Nothing on the shed path branches on `unlocked`** — decision #90 — which is why this epic can be
eleventh instead of second, and why the widget test that holds it has existed since **N14-T07**, six
epics back, before four of the five screens it constrains were built.

**`StoreUnreachable` is the normal case, not a fault.** The shepherd is in a shed with no signal. It
is deliberately not a `ShedFailure` variant (`11 §6.2`): no dialog, no spinner, no haptic, no red, and
nothing in the diagnostics log. A store failure logged as an error would poison the log with a hundred
non-events.

## Why the epic sits here

`00-README` §9 puts monetization at **step 11**, second to last, and states the reason rather than
leaving it to be re-derived:

> *"**Monetization**: `PurchaseService`, the entitlement row, `FreeTierPolicy`, the two static upgrade
> rows, the store artefacts. **It can be last precisely because nothing on the shed path branches on
> `unlocked`** — that is decision #90, and the widget test that holds it should exist from step 5."*

Three consequences bind the scope, and each is why a task in this folder is thinner than it first
looks:

- **`FreeTierPolicy` is not built here.** It is **N06-T10**, in step 2, twenty-four tasks earlier,
  because `EntryContext` changes `createEwe`'s *reachable return set* and a parameter of that kind
  cannot be retrofitted. `createEwe` has consulted the policy since **N14-T01** and `startSeason`
  since **N29-T05**. What was missing is the **entitlement source**, and that is all **N30-T04**
  supplies. Critique defect **S5**, second half.
- **The no-money assertion is not written here either.** **N14-T07** wrote it at step 5 against Quick
  Entry, when Quick Entry was the only screen that existed. **N30-T08** extends the same file to all
  five shed screens and adds the hour axis. A test written after the screens it constrains documents
  what happened; written first, it decides what may happen.
- **G0 already ran, in N02.** `com.android.vending.BILLING` is in `android/expected_permissions.txt`
  and `in_app_purchase: 3.3.0` has been in `pubspec.yaml` since **N00-T03** — N02 needed it there to
  build a release AAB with the billing AAR merged. **This epic adds no dependency**, and if
  `pubspec.lock` moves in this diff it is a review stop (`00-README §7.1`).

What is genuinely new and could not have been earlier: the plugin has no call site until
`purchase_service.dart` exists, the entitlement row has no writer until `EntitlementRepository`
exists, and the two upgrade rows need the Flock screen (N26) and the Settings section list (N29) to
sit in. `07 §14.3` row 9 is Settings ▸ Unlock, and **N29-T01 rendered eleven of twelve sections and
left a ledger comment naming N30-T05 as the twelfth's home.** T05 fills it.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/data/purchase_service_test.dart
fvm flutter test test/data/entitlement_test.dart
fvm flutter test test/features/unlock_test.dart
fvm flutter test test/features/free_tier_test.dart
fvm flutter test test/policy/                        # cap grid, quiet window, never-revoked, price, artefacts
TZ=Europe/London fvm flutter test --tags uk-zone     # T02's 14-day bound, T05's ambiguous hour
make check && make test
```

- **One unlock buys it forever, and the app never asks the store again.** `FakePurchaseService` emits
  `PurchaseSignal.purchased` once; `entitlements.unlocked` becomes `1`; take the fake away, run every
  other test in the file, and nothing re-consults the store. The mechanism is one row of the app's own
  SQLite file (`11 §4.3`) and there is no second one.
- **A store that never answers costs nothing.** Put the fake in its unreachable state and open
  Settings ▸ Unlock: `UnlockUnavailable(storeUnreachable)` inside ten seconds, one honest sentence, the
  buttons still exactly where they were, and every other pixel in Settings working. No dialog
  (`ui.show_dialog`), no spinner (`ui.spinner`), no haptic, no snackbar (P2), no retry timer.
- **The cap refuses in daylight and is structurally incapable of refusing at 03:20.**
  `test/policy/cap_never_blocks_live_entry_test.dart` walks the whole grid — `unlocked` × ewe counts
  0…30 × season counts 1…5 × all 24 local hours, 7,440 decisions — and no `EntryContext.liveEntry`
  input returns `BlockedByCap`. Not by convention: the function cannot reach that arm on that path.
- **Creating ewe #16 at 03:20 succeeds silently, and the row is real.** No refusal, no receipt
  mentioning money, nothing on screen that was not there before. `ewes.over_free_cap = 1` rides on the
  row and is monetization bookkeeping — no `WarningCode`, no badge, no colour, absent from every CSV
  and every PDF, present in the JSON backup (`09 §5`).
- **Paying clears every marker in one transaction and migrates nothing.** `markUnlocked` writes
  `unlocked`, writes `unlocked_at`, clears `purchase_in_flight_at`, and clears `ewes.over_free_cap` and
  `seasons.over_free_cap` with **no `where`** — every marker in the file — inside one
  `db.transaction`. Read the tables on both sides: same rows, same ids, same uids.
- **The app goes quiet between 22:00 and 06:00, and the test proves it by moving the clock.** At every
  local hour in 22:00–05:59 neither `ShedBanner` renders — on Flock or on Settings — and both calm
  gates degrade to `Allow`. The entitlement is untouched in that test; only the hour changes.
- **`grep -rn "package:in_app_purchase" lib/` returns exactly one file**, and
  `grep -rnE "PurchaseDetails|ProductDetails|PurchaseStatus|PurchaseParam|InAppPurchase" lib/` returns
  the same one. Two things cross the seam: a `PurchaseSignal` and a `String` price.
- **`grep -rnE '[€£$¥][0-9]' lib/ assets/` returns nothing.** The price is `ProductDetails.price`,
  already localised by the store, never reformatted, never persisted, and absent from the rows until
  the store has answered in this process.
- **Nothing about money renders on any of the five shed screens, at any entitlement state or hour** —
  and `FakePurchaseService` throws if one of them so much as touches the seam.
- **`ios/Runner/PrivacyInfo.xcprivacy` says *Data Not Collected* and it is true**, provable by G3's
  import scan and by an `.aab` with no `INTERNET` permission.

What is deliberately **not** demonstrable yet: G1 against a signed release AAB (**N31-T03**), the
`.storekit` loop on a real simulator and the four manual purchase paths (by hand, and **N33**'s
journeys), the closed-track purchase with a licence tester (**N32**), and the price itself, which is
the owner's answer to decision-record §7.1 open question 4 (**N00-T09** holds the ledger).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **all, and it is the owner of this epic** — §1 (the model, the version floors, the rejected models) · §2 (**the ten names this document adds, and where each lands**) · §3 (what `in_app_purchase` does to the manifest; the four allowlist lines; which offline claims survive) · §4 (the entitlement row, the three rules, `markUnlocked` printed in full, the §2.13 ownership exception, the new-device case) · §5 (`PurchaseService` printed in full, the two moments, the 14-day drain, the acknowledgement window) · §6 (the surface, `UnlockState`'s four variants printed in full, the eight-row state machine, restore, the unreachable case, double taps, the price) · §7 (`FreeTierPolicy` printed in full, the two gated verbs, the two consequences) · §8 (the four hard constraints, `over_free_cap`'s data rules, what the cap never does) · §9 (both stores' declarations, the reason-code table, the App Review notes) · §11 (testing purchases) · §12 (**the four gate rows and the eight test files**) | every line in this epic |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree: `lib/data/purchase_service.dart`, `lib/data/entitlement_repository.dart`, `lib/features/settings/`, `test/support/`) · §1.1 layer rules 3, 4, 5, 6, 7 · §2.4 (`WriteOutcome`, `WriteRefused`) · §2.10 (**the free-tier types**) · §2.11 (`ShedBanner`, `showCapRow`) · **§2.12 (`PurchaseService` is the seventh seam, and it is the store seam)** · §2.13 (`EntitlementRepository` owns `entitlements`; `createEwe`'s and `startSeason`'s exact signatures) · §3.1 (`purchaseServiceProvider`, `entitlementRepositoryProvider`, `entitlementProvider`, `freeTierPolicyProvider`) · §3.4 (`unlockControllerProvider`) · §4.2–§4.3 (class and provider naming) · §4.5 + R59 (widget keys) · §4.7 (**the rule ids**) · §5.1 (*unlock*, never *purchase* — and the one exception) · §5.3 (`pending` is banned as a model state) · §5.4 (the price is never a literal) · **R30, R37, R40, R54, R56, R57, R58, R69, R74** | **BINDING** on every path, type, provider, column, key and word |
| `docs/research/00-tech-decisions.md` | **§5.1 only** for versions · §2 rows **#86** (export never gated) **#87** (free + one non-consumable) **#88** (the entitlement row) **#89** (`purchase_in_flight_at` and the three-day window) **#90** (the first frame is entitlement-agnostic) **#91** (one policy object, `EntryContext` explicit) **#92** (no modal, ever; two static rows) **#93** (the privacy declarations — **amended by T07**) · §1 #5 (the manifest-merger prerequisite) · §3.2 G0–G5 · §3.3 the eight-entry permission set · §7.0 ruling 8 (season-primary, ewe cap secondary) · §7.1 open questions **4** (price) and **17** (whether reminders are ever capped) | `in_app_purchase` **3.3.0** · `in_app_purchase_storekit` **≥ 0.4.8** · Play Billing **8.0.0** · `flutter_riverpod` **2.6.1** · Flutter **3.44.8** / Dart **3.12.2** |
| `docs/engineering/03-data-model-and-schema.md` | **§5.13** (`Entitlements` — four columns, `CHECK (id = 1)`, `InstantConverter`; and `AppSettings`' **fourteen** columns, which do **not** include `last_unlock_prompted_at`) · §5.1 (`Seasons.over_free_cap`) · §5.2 (`Ewes.over_free_cap`) · §5.14 (who writes what) · §11 (`seedFirstRun` inserts `const EntitlementsCompanion()` in `onCreate`) | the row, and the column that is missing |
| `docs/engineering/06-design-system.md` | **§12** (the component inventory; `ShedBanner` ≥ `tapHero` with two `tapMin` actions; and **the three free-tier constraints, which are 06's to enforce, not 11's**) · §10.1 (`showCapRow` is the one channel with **no haptic**) · §10.3 (the three feedback functions, and what P2 removed from them) · §9 (dark only) | the component, and the wider of the two quiet-window rules |
| `docs/engineering/07-screens.md` | **§19** (the two cap surfaces, their copy, the seven screens that have none, the two hard rules, what the cap never does) · **§14.2–§14.3** (Settings' over-cap state and section **9 of 12**, *"Restore purchases sits above Unlock"*) · §14.5 (§12 on that screen) · §20 (bottom-third primaries, list-row geometry) | where the rows sit and what they say |
| `docs/engineering/12-testing.md` | **§4.2** (the **seven** fakes; `FakePurchaseService`'s tripwire is *"any store call during a `pumpApp` of a shed screen"*) · §4.1 (`implements`, never `extends`) · §4.4 (where `mocktail` earns its keep) · §5.1 (`shedContainer` already names `purchaseServiceProvider` in its override list) · §5.3 (`setEntitlement`, `setEwesInCurrentSeason`, `restoreFixture`) · §6 (the matrix) · **§10.7** (the no-monetization test printed, including the 99-ewe rationale) · §2.1 (installing time with `withClock`) | the fake, the harness and the sweeps |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7.2 step 6 (*"Entitlement rows are skipped and logged"*) · §7.5 item **9** (*"An entitlement that came out of a backup file"* may not exist after any restore) · §7.7 (*"Never unlocks"*) · §7.8 (the refusal fixture) · §2–§3 (the migration ritual, if T05 lands a column) | the restore boundary |
| `docs/engineering/10-accessibility-and-i18n.md` | **§1.1** (unlock / restore purchase is one of the **seven common tasks** — Apple's Accessibility Nutrition Labels require every one of them to complete under each declared feature) · §3.2 (label rules) · §3.4 (`headingLevel:` only) · §4 (200% text; never clamp) · §8.4 (ARB house rules) | why this surface is a ship gate, not just a screen |
| `docs/engineering/13-build-ci-release.md` | §4.2 (**the four PR jobs and what each runs**) · §1.3 (`make check` / `make test`) · §7.1 (`ios/*.storekit` is the only purchase loop that needs no account) · §2 (G0–G5) | the pipelines |
| `docs/engineering/01-architecture.md` | §6.3 (**"Reading the entitlement" is a named banned line in `main()`**) · §4.1–§4.4 (repositories, event verbs, one `appNow()`, one transaction, `.distinct()` in the repository) · §3.2 (the allowlist) · §5.1 (the six `ShedFailure` variants — and why none of them is a store failure) | the boot path and the write path |
| `docs/design/indelible.md` | §7 (the controls; the word button; *"never a filled red button"*) · §8 (the screens, laid out) · §9 (the 3am compliance table) | how the two rows are drawn |
| `epics/00-PLAN-CRITIQUE.md` | **S5** (`FreeTierPolicy` was wired sixteen epics after the verb it gates) · **G4** (`ios/*.storekit` was owned by nobody; *"E27-T07 covers privacy artefacts only"*) · §9 change 8 · §11.3 (the anchors, and the two `[audit]` file rulings for T04 and T08) · §11.4 (the skills for N30) · §2 row N30 | why this folder is eight tasks and not twelve |
| `shed-book-spec.md` | **§14** (one-time unlock €10–15; no subscription **ever**; a free tier capped at a small flock or one season; *"the cap must not degrade the 3am experience"*) · §5 (the 3am test, and zero interruptions as a **shipping gate**) · §7.1 (never block an entry) · §7.7 (the retention thesis the season wall is aimed at) · §7.9 (export is a safety feature) · §12 (the five safety rules) · §15 (night eleven) | the model and the wedge |
| `CLAUDE.md` | the four non-negotiables · **P2 — there is no SnackBar, and `showMaterialBanner(` went with it** · the banned words · the authority order | 64 × 64 targets, 18 px floor, dark only, no `draft`/`save()`/`sync`/`pending` |

## Tasks

Strictly sequential. T01–T03 build the machinery bottom-up; T04 wires it to the two verbs that have
been waiting for it; T05–T06 draw the surface; T07 files the artefacts; T08 proves none of it leaked.

| Task | Depends on | One line |
|---|---|---|
| [N30-T01](N30-T01-purchaseservice-the-store-seam-and-its-fake.md) | N29-T08 | `PurchaseService` — the store seam and its fake |
| [N30-T02](N30-T02-entitlementrepository-and-the-entitlement-row.md) | N30-T01 | `EntitlementRepository` and the entitlement row |
| [N30-T03](N30-T03-unlockcontroller-and-unlockstates-four-variants.md) | N30-T02 | `UnlockController` and `UnlockState`'s four variants |
| [N30-T04](N30-T04-wire-the-entitlement-source-into-the-two-gated-verbs.md) | N30-T03 · N06-T10 · N14-T01 · N29-T05 | Wire the entitlement source into the two gated verbs |
| [N30-T05](N30-T05-the-two-static-upgrade-rows-and-showcaprow.md) | N30-T04 | The two static upgrade rows and `showCapRow` |
| [N30-T06](N30-T06-the-price-read-from-productdetailsprice-never-a-literal.md) | N30-T05 | The price read from `ProductDetails.price`, never a literal |
| [N30-T07](N30-T07-store-artefacts-privacyinfoxcprivacy-the-data-safety-form-st.md) | N30-T06 | Store artefacts — `PrivacyInfo.xcprivacy`, the data-safety form, `*.storekit` |
| [N30-T08](N30-T08-the-at-cap-tests-and-no-money-on-any-shed-screen.md) | N30-T07 | The at-cap tests, and no money on **any** shed screen |

**T04's dependency list is the epic's whole shape.** It names three tasks from three earlier epics
because the thing it wires already exists in three places: the policy (N06-T10), the first gated verb
(N14-T01) and the second (N29-T05). If any of those three is not on merged `main`, T04 has nothing to
supply an entitlement to.

**Four `check_policy` rows land in this epic, and each needs a proving case in the same commit.**
`11 §12.1` names all four; `N03-T01`'s comment names only two of them, so a developer following N03
will add half the table and be surprised by N03-T07's inventory assertion, which **fails the build on
any rule id with no case in `test/policy/gate_rules_test.dart`**:

| Rule id | Task | What it fails on |
|---|---|---|
| `layer.in_app_purchase` | T01 | `package:in_app_purchase` outside `lib/data/purchase_service.dart`, **or** any of `PurchaseDetails`, `ProductDetails`, `PurchaseStatus`, `PurchaseParam`, `InAppPurchase` outside that file |
| `launch.store_call` | T01 | `PurchaseService` or `purchase_service.dart` referenced in `lib/main.dart` or `lib/app.dart` |
| `db.entitlement_revoke` | T02 | `markLocked`, `revokeEntitlement`, or `unlocked:` assigned `false` / `Constant(false)` outside `lib/core/db/tables/` |
| `ui.monetization_surface` | T05 | `showCapRow(` outside `lib/features/flock/` and `lib/features/settings/`; **and** `ShedBanner` constructed outside those two plus `lib/features/quick_entry/` |

A fifth is a genuine gap. **`copy.currency_literal` is asserted by `11 §12.1` to already exist** — it
is listed under *"rules that already exist and do this document's work, so no duplicate is added"* —
and no task in N01–N29 lands it. `CONVENTIONS §4.7` lists it among *"rows this file adds that no
document had as a row"*. **T06 lands it, and it is not a duplicate.** Check the table before you write
the row; if N03-T05 did ship it, T06 adds only the proving case.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N29 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n30-monetization
```

**2 — One commit per task, eight commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Three commits in this epic carry an extra obligation:

- **T05, if it lands `app_settings.last_unlock_prompted_at`**, is a **schema commit** and
  `00-README §7.4` forbids splitting it: `kSchemaVersion` → 2, the hand-written `from1To2` body, the
  regenerated `drift_schemas/drift_schema_v2.json`, `schema_versions.dart` and
  `test/drift/generated/**`, and the extended from→to matrix — **together or not at all**. Run
  **`/shed-migrations`** by name before you touch `lib/core/db/`. See *Risks*: this is the loudest item
  in the epic, and the alternative is to route the once-a-day rule to the owner.
- **T07 amends two authorities in its own commit.** `11 §9.2` overrules decision-record §2 row 93 and
  `08-platform-integration.md` §11 on the reason codes, and `00-README §10`'s amendment rule requires
  the decision record and every document that applies it to change **in the same change**. A decision
  record that disagrees with the doc that owns the answer is worse than either being wrong.
- **T01 must read `pubspec.lock` before it writes a line.** If `in_app_purchase_storekit` resolves
  below **0.4.8**, promote it to a direct dependency at `^0.4.8`, move its allowlist line from
  `[transitive]` to `[dependencies]`, and put the reason in the commit message (`11 §3.3`). A silent
  0.4.3-era resolution reports a purchase as a restore and costs an unlock. That is a **dependency
  change and its own commit** (`00-README §7.4`) — not part of T01's.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # the suite, randomised, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README §10`'s irreversibility order. For this branch that order is:

`pubspec.lock` and `tool/policy_allowlist.txt` (if either moved — a lockfile diff with no `pubspec.yaml`
diff is a **review stop**) → `tool/check_policy.dart` → `lib/core/db/tables/settings.dart`,
`lib/core/db/migrations.dart` and `drift_schemas/` (T05, if the column ships) → `ios/` and
`docs/store/` (T07) → `lib/data/purchase_service.dart`, `lib/data/entitlement_repository.dart`,
`lib/data/flock_repository.dart`, `lib/data/season_repository.dart` → `lib/l10n/app_en.arb` →
`lib/features/settings/**` and `lib/features/flock/**` → `test/`.

`drift_schemas/**` and the `[exempt]` allowlist are **never** waved through, however small
(`00-README §10`). Neither is `ios/Runner/PrivacyInfo.xcprivacy`: it is the one file on this branch
whose being wrong is a legal exposure rather than a bug.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land squarely in this epic and must not be answered
"n/a":

- **§12.1 — never default a withdrawal period.** Nothing here is a withdrawal figure, and the reason
  matters: `11 §7.1` puts withdrawal periods, clear dates and the medicine book in the *"never capped,
  ever"* row. State that gating anything safety-related would turn a commercial decision into a
  food-safety one, and that no column this epic writes is a withdrawal column.
- **§12.3 — never present the app as a compliance record.** Two places. The unlock copy sells a
  notebook, not a compliance product (`07 §14.5`). And `docs/store/`'s listing copy and the privacy
  policy text on Settings ▸ About are where a store-facing sentence could imply an official record;
  `Disclaimers.exportFooter` is **referenced**, never re-typed (decision #62).
- **§12.4 — never silently correct an entry.** `over_free_cap` is the one to name. It is **not a
  warning**: no `WarningCode`, no badge, no colour, never in the §12.4 contradiction machinery
  (`11 §8.1`). It is monetization bookkeeping that happens to live on two record tables. And *"nothing
  reads `over_free_cap` when `unlocked = 1`"* is what makes it safe for a restored backup to carry
  stale markers the app will never rewrite.

**§12.2** (never give veterinary advice) does not reach this epic — no string in it names a dose, a
period or a clinical decision — but say so rather than skipping the line. **§12.5** (timestamps carry
provenance) reaches it as an **absence with a rule attached**: `unlocked_at` and
`purchase_in_flight_at` are machine facts about our own process, carry no provenance quad, and are
**rendered nowhere in v1** (`11 §4.1`). R37's standing rule is what makes that safe — a table without
the quad has no edit verb, and nothing displays an unprovenanced time. If v1 ever renders an unlock
date, the quad lands on the table first, which is a migration.

**5 — Wait for the pipelines.** Three jobs gate this epic and a fourth runs on every PR. Each proves a
different thing here.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The offline claim, mechanically, on the one branch that adds a store. **G3** proves no network path was added — which is the same fact `PrivacyInfo.xcprivacy` declares, so a red G3 and a *Data Not Collected* label in the same diff is the shape of a false declaration. **G2** proves the four `in_app_purchase*` lines still resolve exactly as N03-T04 allowlisted them: one in `[dependencies]`, three in `[transitive]`. `layer.in_app_purchase` proves the seam is one file *and* that no plugin type leaked into a public signature — the second half is what makes the first half hold. `launch.store_call` proves `main.dart` and `app.dart` never learned the seam's name. `db.entitlement_revoke` proves nothing in `lib/` can write `unlocked = false`. `ui.monetization_surface` proves `showCapRow(` is reachable from exactly two folders. `copy.currency_literal` proves no price literal. `copy.banned_word` proves no `pending` state name survived T03. **If this job reddens on `analyze`, read the Riverpod spelling first** — `AutoDisposeNotifier`, never bare `Notifier` with `.autoDispose` |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | Either a **negative** or the single most important assertion on the branch, depending on T05. If the once-a-day rule does not ship: N30 adds no table and no column, `drift_schemas/` must not move, and a red `codegen` means somebody reached for a column that does not exist. If it does ship: this job is what proves `kSchemaVersion`, the snapshot, `schema_versions.dart` and `test/drift/generated/**` were all regenerated **and committed** — a stale generated file is invisible locally and lethal on a fresh clone (`00-README §7.3`) |
| `test` | `flutter test` randomised · `TZ=Europe/London --tags uk-zone` over the **whole** suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The eight anchors, the four `test/policy/` files `11 §12.2` names, the extended matrix rows, and the two `uk-zone` cases this epic adds. The zone leg matters twice: the **14-day drain bound** must be absolute (336 h), never civil-day arithmetic (T02), and the **quiet window** must give the same answer for both instants of the repeated 01:00–01:59 hour (T05) — which it does, because that hour sits inside 22:00–06:00 under both readings, and `11 §7.2` says so in a comment for exactly this reason. Untagged, both pass under UTC for the wrong reason. **`libsqlite3-dev` is installed by this job** — T02 and T04 write real SQLite files |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. **This epic
adds no permission.** `com.android.vending.BILLING` has been merged by the Play Billing 8.0.0 AAR
since `in_app_purchase` entered `pubspec.yaml` in N00-T03, and N02's G0 recorded it — so it is already
in `android/expected_permissions.txt` and G1's eight-entry set is unchanged. **If `android` reddens on
this branch, a dependency moved — stop, and do not edit `android/expected_permissions.txt` to make it
green** (`CLAUDE.md`).

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. Eight images
is the budget (`12 §8`) and none of them is an upgrade row — a pixel regression there is not a
usability or safety regression, and the overflow matrix already covers the case that matters.

**6 — Merge, delete the branch, and only then cut N31.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n31-platform-artefacts
```

N31 asserts `android/expected_permissions.txt` against G0's record and ships the platform artefacts.
Cutting it from anything other than a green merged `main` means the permission assertion is written
against a manifest that has moved.

## Risks, and what is irreversible

**Four things in this epic cannot be taken back, and three of them are outside the codebase.**

- 🚩 **`kUnlockProductId = 'shed_book_unlock'` is frozen at the first sale.** Byte-identical in App
  Store Connect and in Play Console. **Changing it strands every purchase ever made**, on every phone,
  with no server-side remedy and no support channel (`11 §1.1`, §5). It is a `const` in
  `purchase_service.dart` and T07's test asserts the `.storekit` file spells it the same way. Get it
  right in T01 and never touch it again.
- 🚩 **`ios/Runner/PrivacyInfo.xcprivacy` is a native file and a legal declaration.** A false *Data Not
  Collected* is a store-removal risk and a legal one, which is why T07 is the one task in the folder
  whose close-out says `/shed-code-review` is *doubly* required. Two mechanical traps: **`0A2A.1` and
  `C56D.1` must appear nowhere** in an app manifest (that is the shape of `ITMS-91055`), and **the file
  must be in the Runner target's Copy Bundle Resources** — one that sits in the project but not in the
  target ships nothing *and the build succeeds*.
- 🚩 **The Play data-safety form and the App Store Connect privacy answers are published artefacts.**
  Once submitted they are what the stores hold you to. `11 §9.1` records the two judgement calls to
  re-check rather than remember: in-app purchase data (not "collected" under Apple's definition, and we
  do not even store the `purchaseID`) and crash reports (there are none — **if Sentry or Crashlytics
  ever lands, the label is no longer *Data Not Collected*** and `NSPrivacyTrackingDomains` becomes
  relevant).
- 🚩 **If T05 lands `app_settings.last_unlock_prompted_at`, this epic writes the project's first
  migration and its second schema snapshot.** `04 §1` item 1: the first committed snapshot froze the
  storage representation of every column in it, and every later version is diffed against these files
  by `SchemaVerifier`, forever, including in 2029 on a phone that has never been online. Losing
  `drift_schemas/` is **unrecoverable** (`00-README §7.1`).

**The column that should already exist and does not.** `11 §2` flags
`app_settings.last_unlock_prompted_at` as a nullable `INTEGER` instant on R40's precedent and says, in
bold, that it *"must land before the first schema snapshot"*. `11`'s own Definition of Done repeats it.
**It did not.** `03 §5.13` declares fourteen `AppSettings` columns and this is not one of them, and no
task in N00–N29 adds it. `kSchemaVersion` is `1` and `from1To2` is still the commented-out stub
N08-T01 shipped. So T05 has exactly two honest options and **must pick one in writing, in its commit
message**:

1. **Land it as v2.** Forward-only, additive, nullable — the safest possible migration and a good first
   one. One commit, `/shed-migrations` first, and the from→to matrix goes from zero pairs to one.
2. **Ship without the once-a-day self-navigation.** `showCapRow` renders the refusal in place and the
   app never navigates on its own. Everything else in `11 §8` constraint 4 still holds, because a
   **user-initiated** tap on an upgrade row was never rate-limited. Record it as an open item against
   `11`'s Definition of Done and route the column to the owner.

Do not fake it with a third store. `shared_preferences` is forbidden by entitlement rule 3, is not in
decision-record §5.1, and adding it re-introduces the `NSPrivacyAccessedAPICategoryUserDefaults`
obligation T07 just declared away.

**What is expensive to change rather than irreversible:**

- **The widget keys `flock.upgrade_row` and `settings.upgrade_row`.** N14-T07 has been asserting their
  *absence* since step 5, and `12 §10.7` chose keys over types precisely so that test could exist
  before this document landed. Renaming one now is a breaking change to a test written six epics ago.
- **`PurchaseSignal`'s five members.** They are the seam. Adding a sixth means every reader of
  `updates` gains a case, and `PurchaseStatus`'s exhaustive `switch` in `_onBatch` is deliberately
  written with **no default arm** so that a sixth member in a future plugin major is a compile error
  rather than a silently-ignored purchase.
- **`UnlockState`'s four variants.** `11 §6.2` prints them; a fifth is a screens conversation, and the
  obvious fifth — `pending` — is a banned model state.

**Risks specific to N30:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **A paywall flash at 3am** | The failure mode decision #90 exists to prevent, and the one this whole epic is arranged around. It is not hypothetical: T04 puts `entitlementRepositoryProvider` on `flockRepositoryProvider`'s dependency chain, which puts `purchaseServiceProvider` transitively on the Quick Entry path for the first time | Three layers. `entitlementProvider` is watched by no shed screen. `FakePurchaseService` **throws** on any store call during a `pumpApp` of a shed screen (`12 §4.2`) — the only place this is catchable mechanically. And T08's sweep runs all five screens at `unlocked: false, ewesInCurrentSeason: 99`. Note what protects it in production: constructing `PurchaseService` is safe; **`attach()` is what initialises the Android billing client**, and nothing on the shed path calls it |
| **A plugin type leaking through the seam in a public signature** | `layer.in_app_purchase`'s import ban is *trivially* satisfied by a method returning `List<PurchaseDetails>` — and then `entitlement_repository.dart` has to import the plugin to name its own callback, and the rule becomes a comment CI cannot enforce (`11 §5`) | The rule's **second clause**: the five token names are banned outside the one file, not just the import. T01 plants a violation of each half and watches it fail |
| **Acknowledging a purchase in the wrong order** | Google auto-refunds and revokes if a purchase is not acknowledged within **three days**, and the dangerous case is the one Google names: the user pays, Play confirms, the phone drops off the network. Complete-then-signal leaves a one-process-death window where the purchase is acknowledged and the row unwritten — repaired by the Restore button Apple already requires. Signal-then-complete produces an auto-refund three days later, **which nothing repairs** | `_onBatch` completes **before** it emits, with the reason in a comment, and T01 asserts the ordering directly rather than asserting that both happened |
| **`purchased` and `restored` handled differently** | `in_app_purchase_storekit` 0.4.3 reported StoreKit 2 purchases as `restored` and left them unfinished (flutter#172434). Handling the two arms differently makes that regression capable of costing an unlock even though 0.4.8 fixed it | The two signals are handled by the **same code**, in both readers. It is not tidiness; it is what makes a future resolution slipping below the floor harmless |
| **A calm cap refusal firing inside the quiet window, or being deferred to the morning** | `11 §7.4`: `isQuietHours` returns `Allow`, `startSeason` commits with `over_free_cap = 1`, and rule 1 means the app never revokes. A user who taps "start a new season" at 22:30 gets it for nothing and **keeps it**. That is the accepted cost of the owner's ruling, and *"do not fix it"* — a refusal detached from the tap that caused it is worse than no refusal, and it would fire while the user is somewhere else in the app | N29-T05 already asserts it as a named case with the citation in the test name. T04 asserts the other half: a restored three-season backup closes **both** calm gates with `secondSeason`, and touches no row |
| **A `ShedBanner` fed a stale `now`** | `ShedBanner` takes `now` and self-suppresses in the quiet window (N10-T08). A single `appNow()` read at build time means a Flock screen left open at 21:58 is still soliciting at 22:05 — and the widget test **would not catch it**, because it sets the clock before it pumps | T05 must decide and record which clock the row reads. `minuteTickProvider` is the only ticker in the app (R25) and exists for exactly this class of problem; the pen board, the withdrawal countdown and the Reminders day boundaries all read it |
| **`showCapRow` implemented as a framework banner** | `11 §8` constraint 3 says it is a `ShedBanner` *"through `ScaffoldMessenger.showMaterialBanner`"*. **P2 removed that**: N14-T04 banned `showMaterialBanner(` in the same commit as `showSnackBar(`, and `06 §10.3`'s `OverlayEntry` fallback with it | T05 renders a ruled row in the document, not a floating surface. If you are reaching for `Overlay.of(context)` or `ScaffoldMessenger.of(context)`, you have re-invented the toast with a different class name |
| **A hard-coded price** | Wrong in every territory but one, and a store-review rejection in several. It is also the *tempting* shortcut, because the two rows are always on screen and knowing a price means calling the store | `copy.currency_literal` over `lib/` **and `assets/`**. The rows render **without** a price until `queryUnlockPrice()` returns in this process — in a shed that is the expected rendering, not a failure. The string is never persisted: `PurchaseService._product` holds it and dies with the process |
| **The entitlement lost by a restore of the user's own backup** | `#88` excludes the row from the backup and `04 §7.2` step 6 skips it on import — so restore stages a **fresh file** whose `entitlements` row is `seedFirstRun`'s default. On the same phone, that is a paid unlock wiped by a legitimate restore, and `db.entitlement_revoke` does not see it because no code wrote `false` | **T02 must rule this and record it.** The reading that satisfies both halves: the row is never *imported from the file* (a neighbour's backup must not unlock your app) and the **device's own row is carried across the swap** (your own restore must not lock you out). That is an amendment to `04 §7` and `11 §4.2` and lands in T02's commit, or it is routed to the owner. The anchor test is what forces the answer |
| **A rule row with no proving case** | Four land here and N03-T01's comment names two. N03-T07's inventory assertion fails the build on any rule id absent from `gate_rules_test.dart` — *"a rule added without a proving test is itself a failure"* | The table in *Tasks* above. A row and the case that proves it fires land in the same commit — always |
| **`test/policy/` vs `test/features/` for the two sweeps** | `12 §12.2` and R57 name `test/features/no_monetization_test.dart` (the widget tier mirrors `lib/features/`) and `test/policy/cap_never_blocks_live_entry_test.dart`. The anchors in this folder name `test/policy/no_money_on_a_shed_screen_test.dart` and `test/features/free_tier_test.dart` | **They are one file each, not two.** T08 extends the file N14-T07 created and does not create a second; T04 writes the doc-named grid file alongside its anchor. Each task's *test set* names every file it must end with, and the naming discrepancy is an open item for the audit, not a licence to duplicate a sweep |
| **Reminders capped by accident** | `11 §8.2`: whether the cap ever reaches reminders is decision-record §7.1 open question **17**, still open, and it changes the reconcile budget rather than any screen | Nothing in this epic touches `reminders` or `reminder_rules`. If a task finds itself wanting to, it has answered an open question by implementation |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `pubspec.yaml` and `pubspec.lock` are **unchanged** by this branch, unless the `in_app_purchase_storekit` floor forced a promotion — in which case that is its own commit with the reason in its message
- [ ] `grep -rn "package:in_app_purchase" lib/` returns exactly `lib/data/purchase_service.dart`, and so does `grep -rnE "PurchaseDetails|ProductDetails|PurchaseStatus|PurchaseParam|InAppPurchase" lib/`
- [ ] `grep -rn "PurchaseService\|purchase_service" lib/main.dart lib/app.dart` returns nothing
- [ ] `unlocked` is written in exactly one method, `EntitlementRepository.markUnlocked`, and never written `false` anywhere outside `lib/core/db/tables/`
- [ ] `markUnlocked` clears `ewes.over_free_cap` and `seasons.over_free_cap` in the **same** transaction, with no `where`, and its doc comment states the `CONVENTIONS §2.13` ownership exception and why it exists
- [ ] the word `pending` appears nowhere in `lib/` as a state name; `PurchaseSignal.awaitingPayment` and `UnlockAwaitingPayment` are the spellings
- [ ] `decide` is called from exactly two places — `FlockRepository.createEwe` and `SeasonRepository.startSeason` — inside the same transaction as the insert, with **post-write** counts
- [ ] `EntryContext.liveEntry` cannot return `BlockedByCap`, proved across the whole grid, at all 24 local hours
- [ ] `isQuietHours` is the only definition of 22:00–06:00 in the codebase, and both the policy and both rows read it
- [ ] the two upgrade rows exist in exactly two places, have no dismiss action, put **Restore purchases** above **Unlock**, and render nothing between 22:00 and 06:00 on **any** screen at **any** ewe count
- [ ] `grep -rnE '[€£$¥][0-9]' lib/ assets/` returns nothing, and no price string is written to any table or file
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` ships `C617.1` and `E174.1`, declares `NSPrivacyTracking = false` with empty `NSPrivacyTrackingDomains` and empty `NSPrivacyCollectedDataTypes`, contains neither `0A2A.1` nor `C56D.1` nor `CA92.1`, and is in the Runner target's **Copy Bundle Resources**
- [ ] `ios/Configuration.storekit` is committed and its product identifier is byte-identical to `kUnlockProductId`
- [ ] decision-record §2 row 93 and `08-platform-integration.md` §11 both read `C617.1` + `E174.1` with no `CA92.1`, amended in T07's own commit
- [ ] the four rule ids `layer.in_app_purchase`, `launch.store_call`, `db.entitlement_revoke`, `ui.monetization_surface` are in `tool/check_policy.dart` and each has a planted-violation case in `test/policy/gate_rules_test.dart`; `copy.currency_literal` likewise
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section still has exactly **four** lines (R56)
- [ ] `test/support/` holds **seven** fakes and the harness's fake ledger has no outstanding row
- [ ] two `@Tags(['uk-zone'])` cases are added (T02's 14-day bound, T05's ambiguous hour), each with the `setUpAll` offset guard, and `TZ=Europe/London fvm flutter test --tags uk-zone` reports the expected count rather than 0
- [ ] `drift_schemas/` is absent from this diff **or** T05's schema commit is complete and unsplit, with `/shed-migrations` run and the from→to matrix extended
- [ ] the once-a-day self-navigation either ships over a real `app_settings.last_unlock_prompted_at` column, or is recorded as not shipping with the reason and the routed question
- [ ] the 3am path is unchanged at the cap: `tap_budget_test.dart` against `flock_15_at_cap.json` at `unlocked: false` is still five taps plus the first tally stroke

## Demoable on merge

One unlock buys it forever, and the widget test proves nothing about money renders on any of
the five shed screens at any entitlement state **or hour**.

## Notes

**What this epic deliberately does not build.**

| Not here | Where it is | Why not here |
|---|---|---|
| `FreeTierPolicy`, `EntryContext`, `CapDecision`, `RefusalReason`, `isQuietHours` | **N06-T10**, merged | The policy is pure Dart with no entitlement in it. `EntryContext` is structural on `createEwe` and had to exist before N14-T01's first commit — critique **S5** |
| `createEwe`'s and `startSeason`'s gate call sites | **N14-T01** and **N29-T05**, merged | Both verbs have consulted the policy since their first commit. T04 supplies the entitlement, changes no signature, and adds no third gated verb |
| `ShedBanner`, `ShedTapTarget`, `ShedPrimaryButton` | **N10**, merged | 06 owns the component inventory. This epic *uses* `ShedBanner`; if it needs a variant, that is a 06 conversation and an N10 amendment, not a widget in `lib/features/` |
| `showCapRow`'s signature and its two guards | **N14-T04**, merged | R30 fixes all three feedback signatures, and P2 removed the mechanism `06 §10.3` gave them. N14-T04 landed the signature and the never-on-a-shed-screen / never-22:00–06:00 guards; **T05 lands the pixels** |
| `Routes.settings(context, {bool focusUnlock = false})` | **N29-T01**, merged | An argument on an existing push helper, never a fourteenth `RouteNames` entry (`11 §2`). T05 calls it |
| G1 against a signed release AAB, and `android/expected_permissions.txt` | **N31-T01/T03** | G0's record is N02's; the assertion against a signed bundle is N31's. This epic changes no permission |
| Licence testers, the closed track, sandbox and TestFlight purchases | **N32** | All three need a store account and a signed upload. `11 §11`'s **`.storekit` loop is the exception** — fully offline, no Apple account, and `13 §7.1` says to run it first because it is blocked on nothing |
| The three airplane-mode paths and buy-then-kill | by hand, and **N33**'s journeys | `11 §11` names four manual paths nobody tests and this app takes all four. They need a real device and a real store; the automatable half is T08's fixture work. Put the four in the pre-release checklist, not in someone's memory |
| The price, the territory list, and the Small Business Program enrolment | **N00-T09**, and decision-record §7.1 open question **4** | The price is the owner's. `11 §10` is explicit that nothing in it is settled, that the Play one-time-product rate must be read **in Play Console** rather than from secondary reporting, and that enrolling in the Small Business Program **after** the first sale means paying 30% on everything sold in the gap, for nothing |
| Any monetization surface on tag OCR or voice tag entry | nowhere | Both are cut from v1 (§7.0 rulings 5 and 6), and `11`'s preamble says it directly: *"no monetization surface may ever be attached to them"* |

**The seventh fake closes the ledger.** `test/support/harness.dart` has carried a per-epic fake table
since N12-T05; N29-T04 wrote the sixth row and left exactly one outstanding. T01 writes
`FakePurchaseService`, crosses the row off, and the ledger is complete. `12 §5.1`'s printed
`shedContainer` already names `purchaseServiceProvider` in its override list — T01 makes that line
compile rather than adding it.

**Two documents disagree about the quiet window, and 06 wins.** `07 §19.3` rule 2 suppresses only the
**Flock** row between 22:00 and 06:00; `06 §12` constraint 3 suppresses `ShedBanner` *"on any screen, at
any ewe count"*. `11 §8` constraint 2 rules for 06 — *"the Settings row goes quiet as well as the Flock
one… 07 §19.3 adopts the wider wording"* — and the wider rule is the one that ships. The distinction
that must survive the review: what the window suppresses is **soliciting**, not **selling**. Settings ▸
Unlock is a settings section like any other; it exists at 23:00, its buttons work at 23:00, and a
shepherd who deliberately walks there at midnight to pay is not interrupted by being allowed to. What
does not happen at 23:00 is a row appearing, a refusal firing, or the app navigating anywhere on its
own.

**One number in `11` is not a version and must not be quoted at a reviewer.** `11 §9.3` says Apple's
"commonly used SDKs" list stood at 89 entries when the research was fetched, and says in the same
breath that it grows. Re-read it. The list is full of this app's stack — Flutter itself,
`path_provider`, `share_plus`, `device_info_plus`, `image_picker_ios`, `flutter_local_notifications` —
and the point of the section is that plugin manifests **aggregate**, they do not substitute: SDK
manifests cover SDK code, ours covers ours, and the only way to know the aggregate is Product → Archive
→ **Generate Privacy Report**, read once before the first submission and again after every plugin bump
and after the SwiftPM migration.
