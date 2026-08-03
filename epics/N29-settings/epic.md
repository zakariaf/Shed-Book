# N29 — Settings

| | |
|---|---|
| **`00-README` §9 step** | 10 (4 of 4) |
| **Ships in** | **split** — `v1.0.0` T01 T02 T04 T05 T07 T08 · `v1.1.0` T03 T06 (terminology, the two deletes) |
| **Depends on** | N27 — the old N28 edge was linear order alone (P15 §6) |
| **Size** | L |
| **Was** | E26, plus the `WakelockController` gateway the old plan never gave a task |
| **Branch** | `epic/n29-settings` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The settings that actually matter, and the only two honest deletes in the app.

Twelve sections over a repository that already exists. `SettingsRepository` was pulled forward to
**N12-T02** nine epics ago — every `app_settings` column already round-trips through a parameterised
test, and `settingsProvider` / `themeProvider` / `unitsProvider` / `terminologyProvider` have been in
the DI graph since then. What N29 builds is the **screen**, the two `SettingsRepository` verbs that
edit `terminology_overrides`, the `WakelockController` gateway that nine documents assume and no task
ever created, `SeasonRepository.startSeason`, and the two deletes.

Two sentences frame the whole epic. **Nothing here is on the 3am path** — 08 §7.1 rule 2 forbids the
wakelock on this screen by name, `07 §14.4` prices every non-destructive setting at ≤ 2 taps and every
destructive one at 4, and the deliberate friction is the feature rather than a cost. And **this is the
one screen in the product where the word *delete* is honest**: `indelible.md` §9 says of the rest of
the app *"there is no delete. Not banned — absent."* Two verbs on this screen are the exception, and
`ON DELETE CASCADE` has already run by the time the shepherd sees the result.

## Release scope — P15

**Six tasks ship in `v1.0.0`; two wait for `v1.1.0`.**

| | |
|---|---|
| `v1.0.0` | **T01** the screen · **T02** units · **T04** appearance, high contrast, the left-handed mirror and `WakelockController` · **T05** season start date, switching and `startSeason` · **T07** Diagnostics and About · **T08** the matrix variant and the deliberate friction |
| `v1.1.0` | **T03** terminology editing · **T06** the two honest deletes |

**T05 is not deferrable and the reason is a dependency, not a preference.** N30-T04 wires the
entitlement source into the two gated verbs and one of them is `startSeason`. The free tier is
season-primary (§7.0 question 8), so without T05 there is no second season to gate and no cap to sell
against.

**T07 is not deferrable either, and it is the one people will argue about.** There is no crash
reporting in this product and there never will be — the diagnostics log is the **only** way a shepherd
can tell you what went wrong. A first release with no telemetry by design needs it more than a fifth
one does.

**Why terminology waits.** The authored defaults ship in `v1.0.0` and every screen already reads
`terminologyProvider`, in the DI graph since N12-T02, so the labels are correct for the region the
owner ruled first (§7.0 question 3) — they simply cannot be edited yet. `reminder_rules` interval
editing, the other half of spec §7.10, is N25-T05 and also `v1.1.0`.

**Why the two deletes wait.** `v1.0.0`'s honest answer to *delete everything* is **uninstall** — with
no account and no server that genuinely is all of it, which About can print without qualification. And
deleting a season is destructive, irreversible, priced at four taps by `07 §14.4`, and there is no
season worth deleting in a first season.

**Depends on N27, not N28.** The old edge was linear order alone: this screen composes over
`SettingsRepository`, built at N12-T02.

## Why the epic sits here

`00-README` §9 puts this at **step 10**, the last of the four calm screens that share it (N26 Flock and
note search, N27 Ewe Card, N28 Season Summary, N29 Settings). §9's stated reason for step 10, not
re-derived here:

> *"The calm screens: Flock, Ewe Card, Season Summary, Note Search, Settings. **Off the 3am path, so
> they may be daylight work** — but the Ewe Card summary line is the retention feature, the reason the
> product exists in year two. Do not treat it as filler."*

Settings is the one screen in that group with no retention argument attached, and that is precisely
why it is last inside the step. Three consequences bind the scope:

- It comes **after** N25 because `reminder_rules` must be editable before Settings ▸ Reminders can
  point at them, and the interval editor is a **section on the Reminders screen, not a route**
  (N25 epic, risk 5: `RouteNames` declares thirteen and the matrix self-check asserts exactly that).
- It comes **after** N19 because `07 §9.5` sends pen rename and the turn-out threshold here — *"change
  the turn-out threshold → Settings; not on this screen; it is a season-level preference, not a 3am
  decision"* — and N19's epic notes say the same in reverse: *"renaming and deactivating a pen from
  Settings ▸ Pens is N29's."*
- It comes **before** N30 because `07 §19.2` puts one of the two upgrade rows in **Settings ▸ Unlock**,
  and a section cannot render an offer whose `PurchaseService` does not exist. N29 leaves that one
  section unbuilt and says so in a ledger comment; **N30-T05** fills it.

One thing here is not from §9's step 10 at all. **The `WakelockController` gateway is critique gap
G4** — *"the seventh of `12 §4.2`'s seven fakes. E26-T04 describes the setting, never the seam."* It
lands in T04 because `app_settings.wakelock_enabled` is the row that turns it on, and because the
route observer that decides when to hold it lives in `lib/app.dart`, which has been waiting since N11.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/data/wakelock_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/policy/                       # the diagnostics-redaction and disclaimer cases
TZ=Europe/London fvm flutter test --tags uk-zone    # T05 and T07 each add a file
make check && make test
```

- **Rename *ewe* to *gimmer* and the whole app says gimmer.** Type `gimmer` / `gimmers` into the
  Terminology section, then pump the Flock screen, the Ewe Card, the Pen Board and the PDF flock book:
  every one of them reads the user's noun, because no ARB message ever carried a domain noun as a
  literal. The CSV headers and the `animal_class` column do **not** change — they are stable English
  keys, and that asymmetry is what makes the backup survive a rename (`05 §8.3`).
- **Switching to lb changes every rendered weight and rewrites no stored row.** Read the `lambs.birth_weight_g`
  column before and after: identical integers. The setting reaches rendering and parsing only.
- **Delete everything says exactly what it will destroy, counted from the database, before the
  destructive step, and takes two.** *"1 season, 38 ewes, 41 lambs, 6 treatments, 452 photos and voice
  notes."* Then a typed confirmation. Then, and only then, the swap. `tester.tap(); tester.tap();`
  destroys one database, not two.
- **The screen stays on for thirty minutes on Quick Entry and never on this one.** Navigate
  Quick Entry → Lambing Entry and the lock is still held; Quick Entry → Settings and it is released;
  pump `Duration(minutes: 31)` on a permitted route and it has expired. `FakeWakelockController` trips
  on a `release()` with no matching `acquire()`, so a leak is a red test rather than a flat phone.
- **`kPumpableVariants` covers every one of `RouteNames`' thirteen entries.** N13-T07 opened the table
  with one row and a ledger; N29-T08 writes the last route row. 13 × 3 × 3 × 2 = **234 cells** green.
  The fourteenth variant — Quick Entry with the export banner — and the 252 are **N33-T01**'s.
- **Diagnostics contains no animal record and says so truthfully.** The redacted log has no tag, no
  note text, no product name, no batch number, no withdrawal period and no media path — and the
  `VACUUM INTO` snapshot beside it carries the opposite warning, because it contains all of them.
- **`grep -rn "showSnackBar(" lib/` returns nothing**, on the screen where a settings app would have
  eleven of them. The receipt is the row, re-printed with its new value.

What is deliberately **not** demonstrable yet: the Unlock row (N30-T05), the four `kPumpableVariants`
sweeps for semantics, tap targets, contrast and reachability (N33-T02…T04), and the fourteenth matrix
variant (N33-T01). See Notes.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | **§14** (Settings: the query, six states, the **twelve sections in order**, the tap costs, the two `showDialog` files, §12 on this screen) · §15.1 (`deleteSeason` has **no undo**) · §19.2 (Settings ▸ Unlock is one of the two cap surfaces) · §20 (bottom-third primaries, sheet defaults, the left-handed mirror) · §21.1 (the gate rows that fire on a screen) | the screen, section by section |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree; `lib/features/settings/`) · §1.1 layer rules 3, 4, 5, 6, 7 · §2.2–§2.3 (`Instant`, `LocalDate`, `Grams`, `MilliCelsius`, `WeightUnit`) · §2.11 (`ShedTokens`, `ShedPaletteId`, the components) · §2.12 (**`WakelockController`**, R9) · §2.13 (`SettingsRepository` owns `app_settings`, `vocab_terms`, `terminology_overrides`; `SeasonRepository` owns `seasons` and `app_settings.current_season`) · §2.14 (`Terminology`, `TermLabel`, `Disclaimers`, `LocalLog`) · §3.1 (`settingsProvider`, `themeProvider`, `unitsProvider`, `terminologyProvider`, `wakelockProvider`) · §3.4 (`settingsControllerProvider`, `settingsWriteControllerProvider`) · §4.5 + **R59** (widget keys) · §5 (vocabulary) · **R29, R35, R40, R60, R66, R68, R74** | **BINDING** on every path, type, provider, key and word |
| `shed-book-spec.md` | **§7.10** (units, terminology, reminder intervals, season start and switching, theme, the two deletes) · §5 (the 3am test) · §12 (the five safety rules) | the section list itself |
| `docs/engineering/08-platform-integration.md` | **§7** (the wakelock: the class printed in full, the 30-minute expiry, the three conditions, the `NavigatorObserver`, the four gates) · §6 (`restore_flow.dart`, the one `file_selector` call site — N23's, not this epic's) · §8.2 (who asks for a permission and exactly when) · §8.3 (`WAKE_LOCK` is already merged by `wakelock_plus`) | the seam, its fake and its expiry |
| `docs/engineering/05-domain-correctness.md` | **§5** (canonical grams and milli-°C, the display-unit round-trip bug, `parseUserNumber`) · **§8** (`AnimalClass`, `TermLabel`, `Terminology`, the placeholder rule, `validateOverride`, export headers) · §2 (`LocalDate` for a season start) · §7 (the five safety rules as mechanisms) | units at the display edge, and terminology |
| `docs/engineering/03-data-model-and-schema.md` | **§5.13** (`AppSettings`: every column, every `CHECK`, `CHECK (id = 1)`, and why there is **no** locale column) · **§5.12** (`VocabTerms`, `TerminologyOverrides`) · §5.1 (`Seasons`: `label`, `start_date`, `over_free_cap`) · §5.14 (who writes what) · §9.2 (`sweepSearchDocs` + `rebuildSearchIndex` inside the season-delete transaction) | the columns the screen edits and the delete's blast radius |
| `docs/engineering/06-design-system.md` | §4.1 (the six palettes, `resolvePalette`, and the **four Settings labels verbatim**) · §8.2 (`ShedKeypad`, and `leftHanded` mirrors the bottom row only) · §12 (the component inventory; `ShedDestructiveButton` is *"never within `gapDestructive` of a frequent action; two-step"*) · §9 (dark only) | the controls and the labels |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules; **rule 8: the label uses the user's noun**) · §3.4 (**`headingLevel` only** — `header: true` is a no-op on 3.44; Settings is *"one per settings group"*) · §4 (text scaling; never clamp; `FittedBox` banned) · §8.4 (ARB house rules) · **§8.5** (the terminology-placeholder rule and the seven default pairs) · §8.6 (the 40 vocabulary labels) · §8.7 (what is deliberately not in the ARB) | every string, label and heading |
| `docs/engineering/13-build-ci-release.md` | **§8.3–§8.6** (the rolling redacted log, the redaction list, **Settings ▸ Diagnostics** row by row, and *"nothing is ever transmitted"*) · §9.1.1 (`kAppVersion` / `kAppBuild` — there is no package that supplies them) | Diagnostics and About |
| `docs/engineering/04-migrations-media-backup-restore.md` | **§8** (`VACUUM INTO` is a **snapshot**, not a backup, and *"it contains the user's records"*) · §7.2–§7.6 (the atomic replace-everything path the delete-everything verb reuses) · §5 (the media root and the sweep) | the snapshot, and how a destructive swap is done safely |
| `docs/engineering/11-monetization-and-store.md` | §7.2 (`startSeason`'s signature and the one-transaction rule) · §7.3 (the two `RefusalReason` messages) · §7.4 (**a calm gate inside the quiet window is forgiven permanently**) · §8 (the four constraints on the upgrade affordance) | the second gated verb |
| `docs/engineering/12-testing.md` | §4.2 (the seven fakes — `FakeWakelockController` and its release tripwire) · §4.4 (where `mocktail` earns its keep: `verifyNever` on the wakelock) · §5.1 (`pumpApp`) · §6.1–§6.4 (the variant table, the derived count, *"fix the layout, never the matrix"*) · §7.4 + §7.6 (the other three iterators of `kPumpableVariants`) | the fake, the variant and the failure protocol |
| `docs/design/indelible.md` | §7.8–§7.13 (stepper, segmented choice, check control, text field — **never a placeholder** — and the word button; *"never a filled red button"*) · §7.14 (the bottom sheet is the only overlay) · **§8 screen 12** (Settings, laid out) · §9 (the 3am compliance table; *"there is no delete"*) | the composition and the friction |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #56 (canonical grams / milli-°C) · #57 (the keypad is the only number-entry route) · #62 (the single disclaimer constant) · #69 (no generic `undo(id)`) · #73 (a destructive confirmation is typed or two-step) · #79 (**wakelock: default off, session-scoped, 30-minute expiry**) · #86 (export is never gated) · #90 (nothing on the shed path branches on `unlocked`) · #95/#96 (the palettes and their labels) · #99 (never clamp text scale) · #104 (`headingLevel`) · #106 (colour is never the only channel) · #108 (never an all-numeric date) · #123/#124 (diagnostics and redaction) | `wakelock_plus` **1.7.0** · `flutter_riverpod` **2.6.1** · Flutter **3.44.8** / Dart **3.12.2** |
| `epics/00-PLAN-CRITIQUE.md` | **G4** (the `WakelockController` gateway and its fake are unowned) · §5 rule 5 (the harness grows per epic) · §9 change 9 (`SettingsRepository` moved to N12) · §11.4 (≤ 3 skills per task) | why the gateway is here and the repository is not |
| `CLAUDE.md` | the four non-negotiables · **P2 — there is no SnackBar** · the banned words | 60 × 60 pt floor (Indelible builds 64), 18 px floor, dark only, no `draft`/`save()`/`sync` |

> **Two source citations in the pre-deepening files were wrong and are corrected above.** Settings is
> `07-screens.md` **§14**, not §13 (§13 is Export). The wakelock is `08-platform-integration.md`
> **§7**, not §6 (§6 is file import, which is N22/N23's). Every task file in this folder carried both
> errors; a developer who opened §13 expecting Settings would have written the Export screen twice.

## Tasks

Strictly sequential. T01 composes the screen the next six write sections into; T08 pumps what they
built.

| Task | Depends on | One line |
|---|---|---|
| [N29-T01](N29-T01-settings-screen-composition-over-the-repository-built-in-n12.md) | N28, its last task | Settings screen composition over the repository built in N12 |
| [N29-T02](N29-T02-units-kg-lb-and-c-f-converted-only-at-the-display-edge.md) | N29-T01 | Units — kg / lb and °C / °F, converted only at the display edge |
| [N29-T03](N29-T03-terminology-editing-through-terminology-overrides.md) | N29-T02 | Terminology editing through `terminology_overrides` |
| [N29-T04](N29-T04-palette-high-contrast-the-left-handed-mirror-and-wakelockcon.md) | N29-T03 | Palette, high contrast, the left-handed mirror, and `WakelockController` |
| [N29-T05](N29-T05-season-start-date-season-switching-and-startseason.md) | N29-T04 | Season start date, season switching and `startSeason` |
| [N29-T06](N29-T06-the-only-two-honest-deletes-in-the-app.md) | N29-T05 | The only two honest deletes in the app |
| [N29-T07](N29-T07-diagnostics-and-about.md) | N29-T06 | Diagnostics and About |
| [N29-T08](N29-T08-the-matrix-variant-and-the-deliberate-friction.md) | N29-T07 | The matrix variant and the deliberate friction |

T04 is the only task whose anchor is not `test/features/settings_test.dart`: the gateway is a
data-tier object with a data-tier test, and its *setting* is one row on a screen. Do not fold it into
the screen test — a wakelock that leaks is a battery bug, not a layout bug, and it must fail in the
tier that runs first.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N28 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n29-settings
```

**2 — One commit per task, eight commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation:

- **T06 adds the second `ui.show_dialog` allowlisted file** (or does not — see the ruling T06 must make
  first). `07 §14.4`: *"Restore and delete are the only two flows in the app permitted to use
  `showDialog`; `tool/check_policy.dart` allowlists exactly those two files."* N23-T02 landed the
  first and ruled the `indelible.md` §7.14 conflict; T06 inherits that ruling and **must not re-open
  it**. If T06 needs a path the rule does not already name, move the **file**, never the rule
  (`CLAUDE.md`: *"Never edit `tool/check_policy.dart`, its rule table or its exit code to make a build
  pass."*).
- **T04 may need a `layer.plugin_wakelock_plus` row**, if N01's gate table did not ship one.
  `08 §7.3` requires it by name: `package:wakelock_plus/` outside
  `lib/data/wakelock_controller.dart` fails the build. Adding a **rule** is not an `[exempt]` line and
  does not touch R56's four; check before you write either.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # the suite, randomised, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:

`tool/policy_allowlist.txt` and `tool/check_policy.dart` (if T04 or T06 touched either) →
`lib/data/settings_repository.dart`, `lib/data/season_repository.dart`, `lib/data/wakelock_controller.dart` →
`lib/l10n/app_en.arb` → `lib/app.dart` → `lib/features/settings/**` → `test/`.

`lib/data/**` is high in that order for a reason specific to this epic: **T06's two verbs are the only
two in the product that destroy a shepherd's records**, and `deleteSeason` is the one write in the app
with no undo, no compensating event and no soft-void.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Four of the five land in this epic and must not be answered "n/a":

- **§12.1 — never default a withdrawal period.** Nothing on this screen is a withdrawal figure, and
  `07 §14.5` says why the distinction matters here: **reminder intervals are not withdrawal periods
  and may carry defaults.** State that, and state that `app_settings` has no withdrawal column and
  must never gain one.
- **§12.2 — never give veterinary advice.** Three rows on this screen would be advice if worded
  wrongly: the turn-out threshold (*"Ready to turn out"* is the **user's** threshold, `10 §8.4`'s
  `penReadyThreshold` message names it as theirs), the palette labels (they describe **legibility**,
  never eyesight), and Diagnostics (it offers no interpretation). Name all three.
- **§12.3 — never present as a regulatory record.** About renders `Disclaimers.exportFooter`
  **referenced**, never re-typed (decision #62). `copy.disclaimer_retyped` proves it; say which of the
  four call sites this is.
- **§12.4 — never silently correct an entry.** Two places: a `CHECK` violation is a `WriteFailed`,
  never a clamp (N12-T02's rule, inherited); and `validateOverride` **rejects** a terminology label
  containing a comma rather than stripping it (`05 §8.4`). Trimming surrounding whitespace is the one
  accepted exception and the reason is on record.

§12.5 (timestamps carry provenance) does **not** reach this epic — `07 §14.5`: *"§12.5 does not appear:
Settings displays no event time."* Say that, and say that T07's diagnostics log timestamps are UTC
ISO-8601 **log** lines, not event times, so they carry no provenance label and must not grow one.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The epic's whole friction argument, mechanically. `gesture.*` proves no `Dismissible`, `Draggable`, `Tooltip`, `onLongPress:` or slider reached the one screen a settings app would put all five on. `ui.show_dialog` proves T06 used the allowlisted path and nothing else did. `token.raw_color` and the magic-size rows prove the palette section reads `context.tokens` rather than the hexes it is *about*. `copy.disclaimer_retyped` proves T07 referenced `Disclaimers.exportFooter`. `layer.plugin_wakelock_plus` proves T04's plugin has exactly one import site, which is what makes its fake test the real path. **G2 must stay green while `wakelock_plus` 1.7.0 first enters `lib/`** — it is already in the allowlist and in the lockfile; if this job goes red on a dependency, read `pubspec.lock`, not the gateway |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and it is load-bearing here. N29 adds no table and no column: every setting this epic edits was frozen at N07 and every column it writes already exists. `drift_schemas/` must not move and `database.g.dart` must not change. A red `codegen` on this branch means a section reached for a column that does not exist — most likely a temperature field (open question 11) or a `settings` table somebody invented rather than editing the one row `app_settings` already has |
| `test` | `flutter test` randomised · `TZ=Europe/London --tags uk-zone` over the **whole** suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The eight anchors plus the two zone-pinned files T05 and T07 add, plus the **234** matrix cells T08 completes. The `uk-zone` leg matters twice in this epic: a season started at 01:30 in the repeated hour must derive the civil date **2026-10-25** from either candidate instant (T05), and a diagnostics log line written in that hour must be an unambiguous UTC ISO-8601 stamp (T07). Untagged, both pass under UTC for the wrong reason. **`libsqlite3-dev` is installed by this job** — T06's delete tests destroy real SQLite files |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N29 adds no
permission: `WAKE_LOCK` has been merged by `wakelock_plus` since the dependency table was resolved in
N01, so it is already in `android/expected_permissions.txt` and G1's eight-entry set is unchanged.
**If `android` goes red on this branch, a plugin was added — stop, and do not edit
`android/expected_permissions.txt` to make it green** (`CLAUDE.md`).

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. The eight
images are N33-T07's and none of them is Settings.

**6 — Merge, delete the branch, and only then cut N30.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n30-monetization
```

N30-T05 fills the one section this epic leaves empty and it edits `settings_screen.dart` to do it.
Cutting it from anything other than a green merged `main` means the Unlock row is written against a
section list that has moved underneath it.

## Risks, and what is irreversible

**Nothing in this epic is irreversible in the schema sense**, and that is worth saying out loud rather
than leaving as an absence:

- **No schema snapshot.** `drift_schemas/` must not appear in this diff. Every column these twelve
  sections edit was frozen at N07-T08. If a section wants a column, stop: an unused setting is a 3am
  tax and an unused column is a migration you did not need (`05 §5.2`).
- **No native file.** `android/` and `ios/` must not appear in this diff. `WAKE_LOCK` is already
  merged; T04 adds no manifest line and no `Info.plist` key.
- **No published artefact.** No tag, no store listing, no signing key.

**But two things in this epic are irreversible in the only way that matters to a shepherd, and they
are the reason `/shed-code-review` runs twice on T06:**

- 🚩 **`deleteSeason` runs `ON DELETE CASCADE` across `ewe_seasons`, `lambings`, `lambs`,
  `care_events`, `ewe_observations`, `foster_events`, `pen_occupancies`, `treatments` and `reminders`,
  and there is no undo** (`07 §15.1`, last two rows: *"none — nothing. `ON DELETE CASCADE` has already
  run"*). No compensating event, no soft-void, no `original_effective`. The only recovery is a backup
  the shepherd remembered to export. **A count that under-describes what is about to be destroyed is
  the worst defect this epic can ship**, and it is not caught by any gate — it is caught by T06's test
  seeding live and header counts to *different* numbers and asserting neither appears twice.
- 🚩 **Delete everything destroys the database file and the media root.** It is the same one-way door
  as a restore, minus the file that would have replaced the records. If it is implemented as a
  `DELETE FROM` loop it will leave the media root, the FTS shadow tables and the pre-migration
  snapshot behind — and *"delete everything"* that leaves 452 photos on disk is a lie the app told.

**What is expensive to change rather than irreversible:**

- **The section order and the widget-key namespace.** `07 §14.3`'s twelve sections are a fixed order
  and every key is `settings.<section>.<element>` (R59). Keys are test contracts: N30-T05, N33-T02,
  N33-T03 and N33-T04 all read them. Renaming one later is a breaking change to four test files in
  three epics.
- **`WakelockController`'s two verbs.** `08 §7` prints the class in full and R9 fixes the name and both
  verbs. `acquire()` re-arms; `release()` is unconditional and idempotent. Making `release()`
  reference-counted — the obvious "improvement" — is exactly what turns a crash-restart into a phone
  that drains silently overnight.

**Risks specific to N29:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **`settings_screen.dart` has two "Edit" tasks and no "New" task** | N23-T02 (*"Edit. The Settings ▸ Data row"*) and N23-T03 (*"Edit. The Diagnostics line that shows the counts"*) both edit a file that no earlier task creates. N23 is step 8; N29 is step 10 | T01 opens by checking whether the file exists on the branch. If N23 created a skeleton, T01 **composes over it** and does not re-create it; if it did not, T01 creates it and the commit message records that N23's two rows were retroactively wrong. Either way, one sentence in one commit message, not a rediscovery per section |
| **A unit change that rewrites stored values** | `05 §5.1` names the exact bug: 9.5 lb → stored → switch to kg → edit form pre-fills 4.3 at 1 dp → committed → 9.48 lb. *"The value drifted because nobody edited it — a silent correction with no line of code to blame"* | T02's anchor reads the stored column before and after and asserts identical integers. There is **no `unit` column on any measurement** and a schema test already asserts it (N07). The form controller is seeded from the canonical value each time it opens and never re-derives from the old canonical |
| **A domain noun baked into an ARB message** | The rename feature is worthless if one message says "ewe" literally, and the failure is invisible until a user renames. `10 §8.5` calls it *"the failure mode that survives code review"* | T03's anchor scans every message in `app_en.arb` for the seven default singulars and plurals as literals and fails on any. It is a **source-text test over the ARB**, not a widget test — a widget test only catches the messages that screen renders |
| **`ShedPaletteId.values.byName('red')` throws** | `deepRed`'s stored key is `'red'` (R35) — the one member whose key does not match its name. `byName` is the obvious spelling, it is wrong, and it is wrong at the moment a shepherd who chose deep red opens the app | Ruled and implemented in **N12-T02**: `paletteFromKey(String)` is a `.key` lookup and an unrecognised key resolves to `night`. T04 must **call it**, not re-implement it. A second palette-from-string function in `lib/features/` is a second answer |
| **The °C / °F control shipping with nothing to convert** | `07 §14.3` row 1: *"°C / °F ships only if a temperature field ships"* (open question 11), and `05 §5.2` says *"do not add a temperature column until that question is answered"*. The column `temperature_unit` exists with a default of `'c'`, so the control looks one line away | T02 ships the kg / lb control and **not** the °C / °F control, records the condition in a comment beside the section, and answers open question 11 in the PR body as still open. `MilliCelsius` ships either way and costs nothing |
| **The wakelock held on the wrong screen** | Two permitted routes stack (Quick Entry → Lambing Entry). Per-screen `initState`/`dispose` calls make popping the top one release a lock the screen underneath still wants — or leak it (`08 §7.2`) | **One decider**: a `NavigatorObserver` in `lib/app.dart`, reading `RouteSettings.name` on every push, pop and replace. `08 §7.1` names the three permitted routes and names Settings among the six that are not. T04's test navigates Quick Entry → Settings and asserts release |
| **`atFixed` used on the wakelock expiry test** | `Clock.fixed` freezes `appNow()`, so a 31-minute expiry test wrapped in it measures 0 minutes **and passes** (decision #113, N12-T05's warning). The expiry is a `Timer`, not a clock read | T04 pumps `Duration(minutes: 31)` on the widget-test binding's own clock (`08 §7.3`) and pins nothing. The doc comment says which and why |
| **The diagnostics honesty line above the wrong button** | `13 §8.5`'s sentence — *"This file contains no animal records"* — is true of `shedbook.log` and **false** of the `VACUUM INTO` snapshot, which `04 §8` says *"contains the user's records, so it is never shared automatically"*. The two buttons sit in the same section | T07 writes two distinct ARB messages with two distinct `description`s naming the two documents, keys them `settings.diagnostics.export_log` and `settings.diagnostics.save_copy`, and asserts in a test that the "no animal records" string is not reachable from the snapshot button |
| **A calm cap refusal inside the quiet window** | `11 §7.4`: a `startSeason` at 22:30 in the free tier commits with `over_free_cap = 1` and is **forgiven permanently**. That is not a bug and *"do not fix it"* by deferring the refusal to the morning | T05 asserts it as a named test case with the citation in the test name, so the next reader meets it as a decision rather than as a surprise |
| **A fourteenth route** | The obvious way to build Diagnostics, About, the terminology editor or the pen list is a new screen with a new `RouteNames` entry. `RouteNames` declares **thirteen** and the matrix self-check asserts exactly that | Every one of them is a **section or a bottom sheet on Settings**. `13 §8.5` says it explicitly for Diagnostics: *"a sub-screen of Settings, not a thirteenth route — `RouteNames` has thirteen entries and none of them is `diagnostics`."* T08's self-check is what catches a fourteenth |
| **Monetization leaking onto the screen early** | `07 §14.3` row 9 is Unlock and it is tempting to stub it. `purchaseServiceProvider` does not exist until N30-T01 and `entitlementProvider` until N30-T02 | T01 renders eleven sections and a ledger comment naming N30-T05 as the twelfth's home. Nothing in this epic watches `entitlementProvider`, and T08 asserts `FakePurchaseService` is not even wired |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/` or `ios/`
- [ ] `lib/features/settings/` renders **eleven** of `07 §14.3`'s twelve sections, and a ledger comment names N30-T05 as the twelfth's home
- [ ] no ARB message contains any of the seven default singulars or plurals as a literal
- [ ] no stored measurement changes when a display unit changes, proved by a column read on both sides
- [ ] `WakelockController` is the seventh gateway, has exactly one `package:wakelock_plus/` import site, and `FakeWakelockController` trips on an unmatched `release()`
- [ ] `test/support/harness.dart` overrides `wakelockProvider` with the fake, and its fake ledger is complete except for `FakePurchaseService`
- [ ] both deletes read their counts from the database, name them before the destructive step, and take two steps
- [ ] `kPumpableVariants` contains every one of `RouteNames`' thirteen values; the count is derived, and the fourteenth variant is left to N33-T01
- [ ] `grep -rn "showSnackBar(" lib/` returns nothing (P2)
- [ ] `grep -rni "telemetry\|analytics\|crash log" lib/ assets/ docs/store/` returns nothing
- [ ] two `@Tags(['uk-zone'])` files are added (T05, T07), each with the `setUpAll` offset guard, and `TZ=Europe/London fvm flutter test --tags uk-zone` reports the expected count rather than 0

## Demoable on merge

Rename *ewe* to *gimmer* and the whole app says gimmer; delete-everything says exactly what it
will destroy, first, and needs two steps to do it.

## Notes

**What this epic deliberately does not build.**

| Not here | Where it is | Why not here |
|---|---|---|
| The Unlock row and `showCapRow` | **N30-T05** | `PurchaseService`, the entitlement row and `FreeTierPolicy`'s entitlement source all arrive in N30. A section that renders an offer over a provider that does not exist is the `UnimplementedError` stub N12 refused |
| The restore flow and `restore_flow.dart` | **N23-T01/T02**, already merged | `07 §14.3` row 11 puts Restore in the Data section; the flow, the confirmation and the one `file_selector` call site are all N23's. T06 adds the two **deletes** to the same section and reuses N23's confirmation shape |
| The reminder-interval editor | **N25-T05**, already merged | It is a section on the Reminders screen. Settings ▸ Reminders is a row that reaches it, plus *"Turn on lock-screen alerts"*, which is one of the two places `08 §8.2` permits `NotificationScheduler.requestAlerts()` to be called from |
| The semantics, tap-target, contrast and reachability sweeps | **N33-T02 … T05** | All four iterate `kPumpableVariants` (`12 §7.4`, §7.6). Writing one here would repeat critique defect **S7** — a sweep over a not-yet-complete list that passes silently forever |
| The fourteenth matrix variant and the 252 | **N33-T01** | `quick_entry.export_banner` is a Quick Entry layout state, not a screen. T08 completes the thirteen **routes**; N33-T01 adds the banner variant and flips the self-check |
| A Settings golden | nowhere | Eight images is the budget (`12 §8`) and none of them is Settings. `06 §12`'s rule applies: a golden only where a **pixel** regression would be a usability or safety regression nothing else can see |

**The seventh fake completes the ledger.** `test/support/harness.dart`'s header comment has carried a
five-row table since N12-T05 naming which epic lands which fake. T04 writes the sixth row's file
(`FakeWakelockController`, N29) and the ledger then has exactly one row outstanding —
`FakePurchaseService`, N30. Cross the row off in the same commit; a ledger that is not maintained is a
comment nobody reads by N32.

**`app_settings` gains no column in this epic, and that is the test.** Fourteen columns exist
(`03 §5.13`); N12-T02's parameterised setting list asserts its own length against the column count read
out of the committed `drift_schemas/drift_schema_v<N>.json`. Every section in N29 writes through a verb
that already exists on `SettingsRepository`. **The one exception is T03**, which adds
`setTerminologyOverride` and `clearTerminologyOverride` — two verbs over `terminology_overrides`, a
table `CONVENTIONS` §2.13 already assigns to this repository and which N12-T02 only read from.
