# N21-T08 — The end-of-day export banner

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 8 of 8 |
| **Depends on** | N21-T07 · N12-T02 |
| **Commit** | one commit · `feat(export): the end-of-day banner and matrix variant 14` |

## 1. Why this task exists

Once per **local civil day**, never mid-entry, never between 22:00 and 06:00, dismissible
for the season — and it is matrix variant 14, *Quick Entry with the banner shown*, which is the state
in which the reachability assertion is most likely to fail. It writes `app_settings` through
`SettingsRepository`, which is why that repository is in N12.

It is an **in-app banner and not a notification**, and the reason is structural: a notification needs
`POST_NOTIFICATIONS`, which is deliberately deferred to the moment the user asks for lock-screen
alerts — so a shepherd who never creates a reminder would never receive the one prompt the spec calls
a **safety** feature (#72, 07 §16.1). A banner needs no permission, cannot fire while their hands are
full in the shed, and honours spec §5's *zero interruptions*.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§16.1** (why a banner and not a notification) · **§16.2** (where and when — the **six** conditions, all of which must hold; the four `app_settings` columns; why the civil day is evaluated in Dart; and why `last_export_prompted_at` is written when the banner *renders*) · **§16.3** (the wording, both actions, and the four banned words) · **§16.4** (the layout consequence: its own matrix variant, the reachability assertion, and the shrink order) · §5.1 (Quick Entry's layout, top to bottom) · §5.6 (what is banned on that screen) | the banner, condition by condition and string by string |
| `docs/engineering/12-testing.md` | **§6.1** (variant 14 and why it exists) · **§6.2** (`kPumpableVariants` printed, including the `'quick_entry.export_banner'` key and `armExportBanner(db)`) · **§6.3** (what a failure looks like, and the three banned "fixes") · **§6.4** (the reachability assertion, printed) · §5.3 (`armExportBanner` belongs in `seeds.dart`, not `harness.dart`) · §11.1 | the variant, the harness helper and the assertion |
| `docs/engineering/03-data-model-and-schema.md` | **§5.13** (`app_settings.last_exported_at`, `last_export_prompted_at`, `export_prompt_dismissed_for_season`, `current_season` — all four already exist, with their types and their FK actions) | the columns, spelled exactly |
| `docs/engineering/09-export-formats.md` | **§8.3** (`lastExportedAt` and the banner that depends on it; the three-way stamp rule; and *"never inside the artefact build, and never inside any transaction that also does something side-effecting"*) | who writes the stamp, and when |
| `docs/engineering/08-platform-integration.md` | §11 (the same three-way rule, stated from the gateway's side) | the other half of the same sentence |
| `docs/engineering/11-monetization-and-store.md` | **§12.1** (`ui.monetization_surface` — and the paragraph explaining why `lib/features/quick_entry/` is exempt **on purpose**) · §12.2 (`test/features/no_monetization_test.dart`, which asserts the five shed screens contain no `ShedBanner`) | the gate collision in §5.3 |
| `docs/engineering/06-design-system.md` | §12 (`ShedBanner`: ≥ `tapHero` tall, two `tapMin` actions, visible/dismissed states, *"never modal, never on the 3am path, never 22:00–06:00"*) · §12's three free-tier constraints | the component and its two contradictory-looking rules |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`SettingsRepository` owns `app_settings`) · §3.2 + R28 (`quickEntryDeckProvider` is **one** statement; `recentEwesProvider` and `inPensProvider` are banned) · §3.4 (`quickEntryControllerProvider`, `settingsWriteControllerProvider`) · §4.5 (widget keys) · **R58** (the matrix is 252 cells over 14 variants) · R29 (`settingsProvider` carries `AppSetting`) | **BINDING** on the provider, the repository and the key |
| `docs/design/indelible.md` | screen 11's last sentence (*"a printed line at the foot of tonight's page, once a day, dismissible for the season — never a modal, never a notification"*) · §12 | the voice, and the one place Indelible and `06 §12` describe the same thing differently |
| `docs/research/00-tech-decisions.md` | **#72** (the banner, its three original conditions and its two actions) · #90 (the first frame is entitlement-agnostic) · #103 (no optimistic UI) | the decision, and the one `07 §16.2` narrows |
| `epics/00-PLAN-CRITIQUE.md` | **§S6** (all four columns already exist in `03 §5.13`; the R40 citation was wrong and is corrected; `SettingsRepository` moved to N12-T02 for this task) | why this task writes nothing itself |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the banner, its timing rules and its dismissal are its subject |
| `shed-screens-and-routing` | where a banner may render, and Quick Entry's layout above the tag readout |

The cap is two. `shed-monetization`'s bearing is one line and it is stated here rather than loaded:
`ui.monetization_surface` exempts `quick_entry/` on purpose, and this banner is the reason the
exemption exists — it is not an upsell and it must never become one, which §6 holds as a constraint.
`shed-testing`'s variant 14 and the reachability assertion are written out in §5.4 with the pump
sequence they need.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'variant 14 — Quick Entry with the banner — keeps the primary action reachable at the smallest device and textScaler 1.3'`
- **Why it is red today** — nothing prompts an export, and spec §7.9 requires it because a lost phone is lost data unless the shepherd exported.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. `12 §6.4` prints the shape: pump
`QuickEntryScreen` on `Device.small` (375 × 667) at `textScale: 1.3` after `armExportBanner(db)`, and
assert the **confirm key's** rect is inside the viewport **without scrolling** — not merely that it
exists in the tree. Also assert `tester.takeException()` is null, because a `RenderFlex` overflow is
reported through `FlutterError.onError` during layout and is the other half of the same failure. The
test fails today because `armExportBanner` does not exist and `'quick_entry.export_banner'` is not a
key in `kPumpableVariants`.

**Green.** The minimum code that passes, and nothing beyond it — the banner, its three timing rules, the settings writes, and variant 14.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and this is the point of critique defect S6:** all four `app_settings` columns
already exist in `03 §5.13` and were written at N07. Say so in the commit message — this task adds no
column and `drift_schemas/` must not move.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/settings_repository.dart` | **Edit.** Three verbs, each one statement in its own transaction: `markExported(Instant)`, `markExportPrompted(Instant)`, `dismissExportPromptForSeason(SeasonId)`. `CONVENTIONS §2.13` gives `app_settings` to this repository and gives `ExportRepository` nothing; N12-T02 built the class for exactly this |
| 2 | `lib/features/quick_entry/quick_entry_controller.dart` | **Edit.** The six conditions, evaluated in Dart against `appNow()` and the `AppSetting` row, exposed as one boolean on the screen state. **No new provider** — R28 keeps Quick Entry on one statement and the strips read it with `.select` |
| 3 | `lib/features/quick_entry/widgets/export_banner.dart` | **New.** A `ShedBanner` with two 60 pt actions and a `quick_entry.export_banner` widget key. It renders in the slot **above the tag readout** (07 §16.2) and nowhere else |
| 4 | `lib/features/quick_entry/quick_entry_screen.dart` | **Edit.** The slot, and the shrink order when it does not fit: the filtered-match list loses a row, then the "in the pens" strip. **The keypad, the confirm bar and the recents strip never shrink** |
| 5 | `lib/features/export/export_write_controller.dart` | **Edit.** `markExported` is called **after** the share result, on `ShareOutcome.completed` and `ShareOutcome.unknown` only. T06 returned the outcome so that this line could exist |
| 6 | `lib/l10n/app_en.arb` | **Edit.** The banner's headline, its count line, and both action labels, each with a `description`. Authored here |
| 7 | `test/support/seeds.dart` | **Edit.** `armExportBanner(db)` — `12 §5.3` places it in `seeds.dart` with the other writers, **not** in `harness.dart`. It sets the four columns so all six conditions hold |
| 8 | `test/support/harness.dart` | **Edit.** `kPumpableVariants` gains `'quick_entry.export_banner': () => const QuickEntryScreen()` — the fourteenth entry, and the one the self-check's `length == 14` has been waiting for |
| 9 | `test/features/overflow_matrix_test.dart` | **Edit. The anchor.** Variant 14's cells plus the reachability assertion |
| 10 | `test/features/no_monetization_test.dart` | **Edit.** The assertion is re-pointed at a **widget key**, not `find.byType(ShedBanner)` — see §5.3 |
| 11 | `test/features/export_banner_test.dart` | **New.** The six conditions, the dismissal and the three-way stamp |
| 12 | `test/domain/uk_zone/export_banner_civil_day_test.dart` | **New.** `@Tags(['uk-zone'])`. Conditions 1 and 3 across the ambiguous hour — see §5.4 |

### 5.2 The six conditions and the wording

`07 §16.2` — **every** condition must hold. This is an `&&` chain and there is no "mostly":

1. It is the first launch of a **local civil day** (the denormalised local-date rule, not UTC).
2. Writes have occurred since `app_settings.last_exported_at`.
3. `app_settings.last_export_prompted_at` is not today.
4. `app_settings.export_prompt_dismissed_for_season != app_settings.current_season`.
5. No ewe is loaded and no lambing has been opened in this session.
6. **Local time is between 06:00 and 22:00.**

Condition 6 **narrows** decision #72 and does not widen it: without it, *"first launch of a local
civil day"* during lambing means 03:00 on night eleven, which is exactly the interruption the banner
is supposed to be gentler than. It uses the same quiet window the owner set for the free-tier
surfaces (§7.0 ruling 8).

The wording (`07 §16.3`), authored in the ARB:

> **You have not exported since 2 Mar 2026.** 41 records since then. A lost phone is lost records.
> `[ Export now ]` `[ Not this season ]`

*"Export now"* pushes the Export screen and **starts no work**. *"Not this season"* writes
`export_prompt_dismissed_for_season` and the banner never appears again this season. **There is no
third "later" action and no close X**: not answering is already free.

### 5.3 The details that are easy to get wrong

- **`no_monetization_test.dart` will fail on this banner unless you re-point its assertion, and the
  fix is not to exempt Quick Entry.** `11 §12.2` asserts *"the five shed screens at `unlocked: false,
  ewesInCurrentSeason: 99` contain no `ShedBanner`"*, and Quick Entry is one of the five. The gate
  already handles this correctly — `ui.monetization_surface` allows `ShedBanner` in
  `lib/features/quick_entry/` **on purpose**, and `11 §12.1` explains why in a sentence worth quoting
  into the test's `reason:`: *"the same component carries the end-of-day export prompt, which is not
  a monetization surface and predates this document. Scoping the component ban to two folders would
  have failed the build on a banner the spec calls a safety feature."* So the widget assertion moves
  from `find.byType(ShedBanner)` to the **upgrade row's own widget key**, and the export banner keeps
  `quick_entry.export_banner`. Two banners, two keys, one component.
- **The civil day is evaluated in Dart against `appNow()`, using the same derivation as
  `lambings.local_date` — never a UTC day.** Comparing UTC days fires the banner an hour early or
  late depending on the season, *"which is the kind of small wrongness that makes a shepherd stop
  trusting the thing"* (07 §16.2). This is the whole reason for the `uk-zone` case in §5.4.
- **`last_export_prompted_at` is written when the banner *renders*, not when it is answered.** An
  unanswered banner does not come back the same day. Write it from the controller as a side effect of
  the render decision, in its own transaction, and never as part of the tap handler.
- **`last_exported_at` is stamped after the share result, on `completed` **and** `unknown`, never on
  `dismissed`, and never before the sheet opens.** `08 §11` and `09 §8.3` agree word for word.
  Recording an export we cannot confirm is the safer error — the cost is one un-nagged evening,
  whereas refusing to record a real export nags a shepherd who did exactly what the app asked, which
  is the fastest way to teach them to ignore the one banner that matters. It goes in **its own
  single-statement transaction**, never inside the artefact build and never inside a transaction that
  also does something side-effecting (01 §4.3).
- **`ExportRepository` writes none of this.** All three verbs are `SettingsRepository`'s. If this
  task feels like it needs a write from the export layer, that is critique defect S6 re-appearing.
- **Condition 5 is about the session, not about the database.** *"No ewe is loaded and no lambing has
  been opened in this session"* is screen state, held in the Quick Entry controller — which is
  exactly what `CONVENTIONS §4.4` rule 1 means by *screen state, never data*. Reading it from a table
  would make "mid-entry" survive a restart, which is wrong in both directions.
- **The banner is a real layout state and its variant already exists in the arithmetic.** R58 fixes
  the matrix at **252 cells over 14 variants**; the fourteenth slot has been reserved since `12 §6.1`
  was written and T07 filled the thirteenth. This commit fills the last one, so the self-check's
  `expect(kPumpableVariants.length, 14)` starts passing rather than changing. **Do not touch the 252.**
- **When it does not fit, fix the layout — never the matrix.** `12 §6.3` names the three banned
  "fixes": deleting a cell (that is deleting the 3am test), clamping `textScaler` (banned outright by
  #99, and it defeats Android 14+'s own non-linear curve), and wrapping user-facing text in a
  `FittedBox` (shrinking a tag number to fit is the opposite of legible). The two legitimate fixes
  are a scroll view that is **not** on the primary-action path, or moving something off the screen —
  and `07 §16.4` fixes the order: the filtered-match list loses a row, then the "in the pens" strip.
  **The keypad, the confirm bar and the recents strip never shrink.**
- **Both actions are ≥ 60 × 60 pt and there is no gesture on this banner.** No swipe to dismiss, no
  `Dismissible`, no drag. #101 bans all of them, and a banner is exactly where a `Dismissible` looks
  reasonable.
- **The banned words are banned in the copy, not only in the code** (07 §16.3): *"backup"* used to
  mean anything automatic, *"sync"* in any form, *"your data is safe"*, and any implication that the
  app protects the records by itself. The one permitted sentence is the one that is true —
  *"A lost phone is lost records."*
- **`06 §12` and Indelible describe the same thing differently, and `06` wins on the component.**
  Indelible screen 11 calls the prompt *"a printed line at the foot of tonight's page"*; `06 §12`
  makes it a `ShedBanner` at the top of Quick Entry, and `07 §16.2` places it *"in a slot above the
  tag readout"*. Two documents against one, and the two are the ones that own the component and the
  screen. Use `ShedBanner`; render it in Indelible's voice.
- **No optimistic UI and no SnackBar here** (#103). *"Export now"* navigates; it does not start a
  build, does not show a receipt and does not confirm anything. There is nothing committed to
  confirm.
- **`settingsProvider` carries the row class `AppSetting`, not the table class `AppSettings`** (R29),
  and `appSettingsProvider` is a banned spelling. The banner reads three columns off that row.

### 5.4 The full test set

`test/features/overflow_matrix_test.dart` — the anchor lives here because variant 14 is a matrix
variant:

| Case | What it asserts |
|---|---|
| `'variant 14 — Quick Entry with the banner — keeps the primary action reachable at the smallest device and textScaler 1.3'` | **The anchor.** `Device.small` × 1.3 with `armExportBanner(db)`: the confirm key's rect is inside the viewport without scrolling, and `takeException()` is null |
| `'the matrix covers every route, and the count is 14'` | The existing self-check, now passing with the fourteenth entry present. 13 routes + the banner variant (R58) |
| the 18 generated cells for `'quick_entry.export_banner'` | 3 devices × 3 text scales × 2 bold states, asserting no `RenderFlex` overflow. They come for free from the map entry, which is the reason the table is declared once |

`test/features/export_banner_test.dart`:

| Case | What it asserts |
|---|---|
| `'all six conditions must hold for the banner to render'` | Six cases, each flipping exactly one condition false and asserting the banner is absent. The `&&` chain, enumerated — this is the test that catches a refactor turning one clause into an `||` |
| `'the banner does not render at 23:30 or at 05:30, at any record count'` | Condition 6, at both edges of the quiet window. **The test sets the clock, not the data** |
| `'the banner renders at 06:00 and at 21:59 and not at 22:00'` | The three boundary minutes. Off-by-one at a window edge is the defect this catches |
| `'last_export_prompted_at is written when the banner renders, not when it is answered'` | Pump, do not tap, rebuild in the same civil day: the banner is gone and the column is set |
| `'Not this season writes export_prompt_dismissed_for_season and the banner never returns that season'` | Tap, then re-arm every other condition; still absent. Then advance `current_season` and assert it returns — the dismissal is per season, not forever |
| `'Export now pushes the Export screen and starts no work'` | The route is pushed; `FakeShareService.shared` is empty; no artefact file exists on disk |
| `'there is no third action and no close affordance'` | Exactly two tappable descendants |
| `'both actions are at least 60 × 60 and carry semantic labels'` | The 3am floor, on the one component that is not on the 3am path but sits on the 3am screen |
| `'no gesture dismisses the banner'` | No `Dismissible`, no `GestureDetector` with a drag callback, in the widget's subtree |
| `'last_exported_at is stamped on completed and on unknown, and never on dismissed'` | Three cases through `FakeShareService`, reading the column after each. The one that matters is `dismissed`: the column must be **unchanged**, not set to null |
| `'the stamp happens after the share call, never before'` | Order-sensitive: assert the column is unset at the moment the fake's `shareFiles` is entered |
| `'the stamp is a single-statement transaction and does nothing else'` | Source text over `settings_repository.dart`: `markExported`'s transaction body has one statement |
| `'the banner copy contains no banned word'` | *backup*, *sync*, *your data is safe*, over the ARB messages for this component |
| `'the export banner and the upgrade row are distinguishable by key'` | Both are `ShedBanner`; `quick_entry.export_banner` and the upgrade row's key are different, and `no_monetization_test` asserts by key |

`test/features/no_monetization_test.dart` (edited):

| Case | What it asserts |
|---|---|
| `'the five shed screens render no upgrade row at unlocked false and 99 ewes'` | Re-pointed from `find.byType(ShedBanner)` to the upgrade row's key, with `11 §12.1`'s sentence in the `reason:` so the next reader does not "fix" it back |
| `'the export banner may render on Quick Entry and is not a monetization surface'` | The positive statement of the same rule, so the exemption is documented by a test rather than by a comment |

`test/domain/uk_zone/export_banner_civil_day_test.dart` — `@Tags(['uk-zone'])` under
`TZ=Europe/London`:

| Case | What it asserts |
|---|---|
| `'the two 01:30s of the clocks-back night are the same local civil day'` | Two instants an hour apart both deriving the same `LocalDate`. Condition 1 and condition 3 both compare civil days, so a UTC-day comparison makes the banner eligible twice in one night — which is the one night it must not be |
| `'a prompt recorded at 00:30 GMT is "today" for a launch at 01:30 BST on the same civil date'` | The comparison is civil-date equality and never a 24-hour elapsed check. A `Duration`-based test passes in July and fails in October |
| `'the clocks-forward night has no 01:30, and the banner is unaffected'` | Condition 6 excludes the hour entirely; the case exists so nobody adds a wall-time existence check the banner does not need. `checkLocalWallTimeExists` is for entry, not for this |
| `'the quiet window is evaluated in local wall time and not in UTC'` | 22:30 BST is quiet even though it is 21:30 UTC. This is the failure that only appears for half the year |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 60 × 60 pt with ≥ 16 pt separation, an 18 pt text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. **This banner sits on the 3am screen even though it may not render at 3am**, so it obeys every rule that screen obeys.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Zero interruptions** (spec §5) — never modal, never blocking, never mid-entry, never in the quiet window, and never more than once a local civil day. The banner is the only thing in the product that asks for attention unprompted, which is why six conditions guard it rather than three.
- **Every write commits immediately** — the three settings verbs are one statement each, in their own transaction, with no draft and no Save button. The dismissal is committed the instant it is tapped.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. **In particular this task adds no notification permission**, which is the whole reason it is a banner.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'variant 14 — Quick Entry with the banner — keeps the primary action reachable at the smallest device and textScaler 1.3'` passes, and was seen to fail first for the stated reason
- [ ] at most once per local civil day
- [ ] never mid-entry and never in quiet hours
- [ ] dismissible for the season, and the dismissal persists
- [ ] variant 14 exists and its reachability assertion passes
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] all six conditions are enumerated by six tests, one per clause
- [ ] the civil day is derived in Dart from `appNow()` and never from a UTC day, proved by a `uk-zone` case at 01:00–01:59
- [ ] `last_export_prompted_at` is written on **render**, not on answer
- [ ] `last_exported_at` is stamped on `completed` **and** `unknown`, never on `dismissed`, never before the sheet opens, in its own single-statement transaction
- [ ] every one of the three settings writes goes through `SettingsRepository`; `ExportRepository` is unchanged by this commit
- [ ] `no_monetization_test.dart` asserts by widget key and carries `11 §12.1`'s reason
- [ ] `kPumpableVariants.length == 14` and the matrix still derives **252** — the arithmetic did not move
- [ ] `drift_schemas/` is untouched: all four `app_settings` columns already existed (critique S6)
- [ ] the words *backup*, *sync* and *your data is safe* appear nowhere in the banner's copy

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/export_banner_test.dart
fvm flutter test test/features/no_monetization_test.dart
make check
make test
```

Then the DST tier and the one cell that matters most, reproduced alone:

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

fvm flutter test test/features/overflow_matrix_test.dart \
  --plain-name 'quick_entry.export_banner · small · scale 1.3'
```

Then run the app: arm the four columns in a debug build, relaunch at 20:00 and confirm the banner
renders above the tag readout with the confirm key still on screen; tap *"Not this season"* and
confirm it never returns; relaunch at 23:30 and confirm it does not render at all.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the end-of-day banner and matrix variant 14`
