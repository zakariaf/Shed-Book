# N13 — Quick Entry: the deck and the keypad

| | |
|---|---|
| **`00-README` §9 step** | 5 (1 of 2) |
| **Depends on** | N12 |
| **Size** | M |
| **Was** | E10 |
| **Branch** | `epic/n13-quick-entry-deck-and-keypad` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Build the **read half** of the product's one screen: `routes.dart`, `tagIndexProvider`,
`quickEntryDeckProvider`, `ShedKeypad`, the Quick Entry shell and its two strips — and the first row
of the overflow matrix. Nothing here writes. Every write verb, the receipt and the tap budget are
N14.

Five pieces of shared machinery are born in this epic and every later screen epic reuses them
without re-deciding anything: the route file, the in-memory tag index, the one-statement deck read,
the only numeric-entry control in the product, and `kPumpableVariants`. **P3 is ruled in T01** — `02`'s
Navigator stack against Indelible §7.17's *"there is no tab bar, no rail, no stack, and no back
button"* — and the losing document is amended in the same commit.

## Why the epic sits here

`00-README` §9 puts Quick Entry at **step 5**, immediately after the first frame (step 4, N09 + N10 +
N11) and immediately before the rest of the 3am path (step 6, N16–N19). Its stated reason, not
re-derived here:

> *"It is the product. It also forces you to build every piece of machinery the other eleven screens
> reuse — the deck query, the keypad, the write controller, the receipt — so the second screen is
> cheap."*

And the sentence that sets the whole order, from the same section:

> *"Quick Entry is the product — every other screen exists to serve or read back the loop it drives."*

Three consequences bind this epic's scope:

- It comes **after** N11 because everything in it runs inside a real app: `app.dart` exists, the theme
  set is installed, the global error net is up, and `databaseProvider` opens on the first post-frame
  callback. A screen built before that has nowhere to be pumped.
- It comes **after** the schema freeze (step 3, N07 + N08) because the deck statement reads four
  frozen tables — `pen_occupancies`, `ewe_touches`, `ewes`, `pens` — and `ewe_touches` exists **only**
  to make the recents strip possible (decision #68). Nothing in N13 is schema-shaped; if a column
  turns out to be missing, that is a migration and it is N08's harness, not this epic's.
- It is split from **N14** deliberately. §9's step 5 names the write path in the same breath, but a
  read epic that goes green on its own is the smaller reviewable unit, and the split is what lets
  `test/features/tap_budget_test.dart` be N14-T06 rather than a forward reference (critique **S4**).

`00-README` §9's two parallel tracks start here in earnest rather than in a later sweep:
**accessibility** — `ShedKeypad` is the control `10 §3.6` calls *"the most important control in the
app and the one most likely to be invisible to assistive tech"* — and **the ARB**, because T05 and T06
author the first screen strings in the project. N33 only *verifies*.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/routing_test.dart
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/features/keypad_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
make check
make test
```

- **The app opens to a real Quick Entry screen**, not a placeholder. `MaterialApp.home` is
  `const QuickEntryScreen()`, `navigatorKey` is `Routes.navigatorKey`, and there is **no**
  `restorationScopeId`.
- **Type `12` on a real phone and `12 · 128 · 412` rank in the same frame**, with no SQL round trip,
  no `await` between the digit and the redraw, and no debounce. That is `rankTagMatches` over a
  ~400-entry, ~16 KB in-memory index (`03 §9.1`), and the test proves it by counting the statements
  the database executed during the keystroke: **zero**.
- **The keypad works at frame 1, with the database still closed** — twelve fully interactive keys,
  both strips as fixed-height placeholders in the page colour, and a confirm key reading `412 →` that
  makes no existence claim. Nothing moves when the data lands: the boxes at frame 1 are the boxes at
  frame 2, asserted as `Rect` equality.
- **No keypad key is ever disabled, in any entitlement state**, including `unlocked: false` with
  ninety-nine ewes in the season. Nothing on this screen watches `entitlementProvider` (decision #90).
- **One drift statement feeds both strips.** `combineLatest` appears nowhere; a change to the recents
  bucket rebuilds the recents strip and not the penned one, proved by a rebuild counter rather than by
  inspection.
- **The overflow matrix exists with one row and its count is arithmetic**, not a remembered number:
  `kPumpableVariants.length × Device.all.length × 3 text scales × 2 bold states`. Today that is
  1 × 3 × 3 × 2 = **18 cells**; it reaches 252 over fourteen variants at N33-T01 and every intervening
  screen epic adds exactly one row.
- **`RouteNames` has thirteen constants and `routes.dart` contains no `push(` call at all**, because
  the only screen that exists is `MaterialApp.home` and is never pushed. `onGenerateRoute`, a `routes:`
  map, `pushNamed` and `go_router` appear nowhere in `lib/`, `test/` or `pubspec.yaml`.
- **P3 is closed with a written ruling that amends its losing document in the same commit**, or
  carried into the PR body as open with both sides cited. It is not silently resolved.

What is deliberately **not** demonstrable yet: nothing commits. There is no `beginLambing`, no
`createEwe`, no receipt and no undo — press the slab and it does nothing, because the slab has no verb
until N14. The 6-tap budget claim is not made in this epic (critique **S4**); N14-T06 makes the
5-tap version it can honestly hold.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §1.1–§1.4 (the index, the one-query rule, counting taps, the state vocabulary) · §1.7 (headings) · §2.2 (the empty-state table) · **§5.1–§5.7** (layout, the query, the states, the tap costs, what is banned, §12 on this screen) | the screen brief: what renders, in what order, in which state |
| `docs/design/indelible.md` | §2.2–§2.3 (surfaces and inks) · §3.4–§3.5 (the scale, the record/control split, tabular figures) · §4.1–§4.5 (spacing, geometry, the grid, row heights, the three reach bands) · §7.1 (the corner slab) · **§7.2 (the keypad key)** · §7.3 (the ruled record row) · §7.14 (the bottom sheet) · §7.15 (the recents line) · §7.16 (the page header) · §7.17 (the index — **one side of P3**) · §8 Screen 3 | every value: size, ink, rule weight, target, band |
| `docs/engineering/02-state-di-navigation.md` | §4.4 (`.select` and the collection trap) · §4.5 (reading an `AsyncValue`) · §4.6 (where providers are declared) · **§8 (navigation, the route helper, the stack, Android back, the anti-patterns)** · §9 (why there is no restoration) · **§10 (keeping Quick Entry cheap — the rebuild table, the controller, the nine rules)** | the provider shapes, the rebuild scope, and the routing file verbatim |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 5, 6, 7, 8 · §2.11, §2.13, §2.14 · §3.1–§3.4 · §4.1–§4.6 · §5 · **R19, R26, R27, R28, R30, R33, R57, R58, R59, R70** | **BINDING** on every path, type, provider, key and word |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes`, `tag`, `tag_digits`, the partial unique index) · §6 (tag uniqueness, settled) · §8 (elapsed time from epoch millis) · **§9.1 (`rankTagMatches`, and why FTS5 cannot do this)** · the `EweTouches` table | the four tables the deck reads and the ranking it uses |
| `docs/engineering/06-design-system.md` | §6.1–§6.2 (`tapMin` / `tapPrimary` / `tapHero` / `gapMin`, `ShedTapTarget`) · §7 (the gesture ban) · **§8.1–§8.2 (why the pad exists and its geometry contract)** · §12 (the component inventory) | the keypad's Flutter-side contract and the shared components this epic composes |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (Quick Entry gets a level-1 heading and **no** level-2) · **§3.6 (the keypad's semantics, element by element)** · §3.8 (live regions and the Android re-announce rule) · §8.4 (the ARB conventions) · §9 (en_GB formats) | what the screen says rather than shows, and every string's home |
| `docs/engineering/12-testing.md` | §5.1 (`Device`, `pumpApp`, `shedContainer`) · **§6.1–§6.4 (the fourteen variants, the matrix, what a failure looks like, reachability)** | the harness this epic extends and the matrix it starts |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12, #21, #23, #24, #35, #57, #67, #68, #90, #91, #99, #100, #101, #103, #114 · §7.0 rulings 5, 6, 7 | Flutter **3.44.8** / Dart **3.12.2** · `flutter_riverpod` **2.6.1** exactly · `drift` **2.34.2** |
| `CLAUDE.md` | the 3am test floor · **P2** (there is no SnackBar) · **P8** (no birth-type chooser) · the banned words · the authority order | the floor, and the two owner rulings that supersede a written document |
| `epics/00-PLAN-CRITIQUE.md` | **S2** (the route file) · **S3** (the matrix's fixture) · S4 (the tap budget) · §5 rules 5 and 6 · §11.4 | why T01 lands one helper and T07 one variant |
| `shed-book-spec.md` | §5 (the 3am test) · **§7.1 (fast animal selection)** · §12 (the five safety rules) · §15 (under fifteen seconds) | the product claim this epic exists to hold |

## Tasks

Strictly sequential: each task depends on the one before it. `routes.dart` has to exist before a
screen can be routed to, the index has to exist before the controller can rank, the deck has to exist
before the strips can read it, and the matrix cannot pump a screen that has not been built.

| Task | Depends on | One line |
|---|---|---|
| [N13-T01](N13-T01-routesdart-thirteen-names-one-helper-and-the-p3-ruling.md) | N12-T05 | `routes.dart` — thirteen names, one helper, and the P3 ruling |
| [N13-T02](N13-T02-tagindexprovider-active-animals-only-ranked-in-memory.md) | N13-T01 | `tagIndexProvider` — active animals only, ranked in memory |
| [N13-T03](N13-T03-quickentrydeckprovider-one-statement-two-buckets.md) | N13-T02 | `quickEntryDeckProvider` — one statement, two buckets |
| [N13-T04](N13-T04-shedkeypad-the-only-number-entry-route-in-the-app.md) | N13-T03 | `ShedKeypad` — the only number-entry route in the app |
| [N13-T05](N13-T05-the-quick-entry-shell.md) | N13-T04 | The Quick Entry shell |
| [N13-T06](N13-T06-the-two-strips.md) | N13-T05 | The two strips |
| [N13-T07](N13-T07-kpumpablevariants-is-born-with-one-entry.md) | N13-T06 | `kPumpableVariants` is born, with one entry |

Two ordering wrinkles, both deliberate:

- **T02 creates `quick_entry_controller.dart`; T03 adds one provider to it.** The controller and its
  private `_query` field are what make the same-frame ranking testable, so they land with the index,
  not with the deck. Do not split `QuickEntryState` across two commits.
- **T04 builds `ShedKeypad` in `lib/core/ui/components/`, not in this feature.** N10 built fifteen of
  the twenty-one components and left this one to the epic that first uses it. It is still a **shared**
  component (R70): Lambing Entry, Treatments and Settings all need the same pad and layer rule 6
  forbids a sibling-feature import. `features/quick_entry/widgets/big_keypad.dart` does not exist and
  must not be created.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N12 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n13-quick-entry-deck-and-keypad
```

**2 — One commit per task, seven commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation:

- **T01** amends a published document as part of the P3 ruling, and edits
  `android/app/src/main/AndroidManifest.xml` if N11-T06 has not already added
  `android:enableOnBackInvokedCallback="true"`. `00-README` §10's amendment rule applies: the decision
  record **and every document that applies the decision** change in the same commit.
- **T03** adds `DeckEntry` and `QuickEntryDeck` to `CONVENTIONS.md` §2.14. A name that two files use
  and the naming authority does not carry is how a second spelling gets born.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`android/app/src/main/AndroidManifest.xml` → the `docs/` amendments made by the P3 ruling and by T03's
`CONVENTIONS` row → `lib/data/` → `lib/l10n/app_en.arb` → `lib/routing/` → `lib/core/ui/components/`
→ `lib/features/quick_entry/` → `test/`.

`lib/l10n/app_en.arb` is **never waved through**: this epic authors the first screen copy in the
project, and §12.2 binds it as copy discipline — no event button, no strip header and no confirm key
may contain a "should", a recommendation or a clinical claim.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land here and the honest answers are short:

- **§12.5** — Quick Entry displays **no event time**. The pens strip renders an elapsed *duration*
  (`31h`), which is not an event time and carries no provenance label; the recents strip renders
  nothing but a tag (`07 §5.2`). The one §12.5 disclosure on this screen is in the commit
  confirmation, and that is N14's. If any task in this branch renders an `HH:mm`, it is a review stop.
- **§12.4** — Quick Entry owns no field a warning can attach to. `duplicateActiveTag` fires on the
  Flock create path (`07 §3.3`), not here.
- **§12.2** — copy discipline on every string T05 and T06 author.

The other two (**§12.1** withdrawal, **§12.3** the not-a-regulatory-record footer) do not reach this
epic — say so, and say which epic they land in (N20 and N21).

If P3 could not be closed, **the PR body carries the conflict with both sides cited**
(`02-build-manifest.md` §4.5). Do not resolve it on this epic's own authority.

**5 — Wait for the pipelines.** Three jobs block this PR and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The layer rules, mechanically — and this is the epic where they bite hardest. `layer.features` proves `lib/features/quick_entry/` imports no `package:drift` and no `lib/core/db/`, which is what forces the deck statement onto the repository. `layer.single_writer` proves no `customStatement(` escaped `lib/core/db/`. The gesture rows prove no `Dismissible`, `Draggable`, `Tooltip` or slider entered the first screen. `token.raw_color` and the magic-size rows prove the keypad's 72 came from `context.tokens`, not from a literal. `--fatal-infos` is what turns the deprecated `onPopInvoked` into a CI failure, which is why T01 uses `onPopInvokedWithResult` |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | Two things. First a **negative**: N13 adds no table and no column, so `drift_schemas/` must not move. A schema snapshot in this diff means someone added a column to make a query easier, and that is irreversible after N07's freeze. Second a **positive**: T03 sets `override_hash_and_equals_in_result_sets: true` in `build.yaml` if it is not already set, which regenerates `database.g.dart` — that regeneration must be **in the commit**, or a fresh clone gets a `.distinct()` that silently never de-duplicates |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | Four widget-test files and the first eighteen matrix cells. The `uk-zone` leg is load-bearing in three tasks: T01's resume-across-the-repeated-hour case, T05's page-header date and T06's hours-penned figure all only exercise the ambiguous **01:00–01:59** hour when tagged and run under `TZ=Europe/London`. An untagged DST case passes for the wrong reason. Randomised ordering matters more here than anywhere so far: eighteen matrix cells each open their own `NativeDatabase.memory()`, and a cell that leaks state into the next one shows up as a flake at 11pm on release day |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. If T01 edits
`AndroidManifest.xml`, **read the G4 merger report on this run** — it is the only PR in this epic where
the shipped permission set could change, and `android/expected_permissions.txt` must not be touched to
make it green.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, because the
macOS runner bills at a 10× multiplier. The eight images are N33-T07.

**6 — Merge, delete the branch, and only then cut N14.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n14-quick-entry-write-path
```

N14 hangs `createEwe`, `beginLambing`, the write controller, the receipt and the tap budget off
exactly the widgets and providers this epic ships. Cutting it from anything other than a green merged
`main` means the write path is rebased onto a moving keypad.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **`android/app/src/main/AndroidManifest.xml`** (T01), if the predictive-back attribute lands here.
  A native file, and the one file in this branch that changes what the shipped artefact *is* rather
  than what it renders. It is also the file G1 and G4 watch. Never edit
  `android/expected_permissions.txt` in the same commit.
- **Every widget key spelled in T04, T05 and T06.** `CONVENTIONS` §4.5: *"a key is a test contract, so
  renaming one is a breaking change to `test/features/`."* `quick_entry.keypad.digit_4`,
  `quick_entry.confirm` and `quick_entry.event.lambing` are named in `07 §5.4` and `12 §10.1` **before
  this epic exists** and are read by N14-T06's tap budget, by N33's four sweeps and by the four
  integration journeys. Spell them once, correctly.
- **Every ARB key and message T05 and T06 author.** A message is `description`-bearing and the
  description carries the rationale; `10 §8.4` rule 2 exists because *"when a future contributor
  'improves' it, the description is what tells them why they must not."* There is no later sweep —
  N33-T05 only verifies completeness.
- **The P3 ruling and its document amendment** (T01). A doc set where `02` ships a Navigator stack and
  `indelible.md` says there is no stack is worse than no doc set, because both look authoritative.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`, `lib/core/db/tables/`,
`lib/core/db/migrations.dart`, `ios/`. **If a file under any of those shows up in this branch, stop and
find out why.** The read half of a screen stores nothing.

**Risks specific to N13:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **P3 is not one conflict but a whole-screen disagreement** | Indelible §8's Screen 3 opens *"There is no Quick Entry screen, and that is the design"* — tonight's page with a live row already drawn — while `07 §5.1` specifies entered-tag → matches → two strips → keypad → confirm bar → event buttons, and `CONVENTIONS` §3.2 names `quick_entry_controller.dart`. Ruling only the *back button* half and calling P3 closed is the failure mode | T01 states both halves and rules them together; T05 builds the shell from Indelible's grid under `07`'s names, which is the same trade N09 made for tokens |
| **`quickEntryDeckProvider` is declared in `lib/features/` and cannot touch drift** | `CONVENTIONS` §3.2 puts the provider in `quick_entry_controller.dart`; layer rule 5 bans `package:drift/*` there. A developer reading only §3.2 writes `db.customSelect(...)` in a feature file and the gate fails after the layout already depends on it | T03 puts the statement on `FlockRepository` (one of the closed twelve, R19) and the provider on the feature side, with the reason written in both files |
| **`.select` over a `List` deduplicates nothing** | `02 §4.4` says so explicitly. The DoD *"a change in one bucket rebuilds one strip"* is **false** for a naive implementation: a new `QuickEntryDeck` carries two new `List` instances, `List`'s `==` is identity, and both strips rebuild | T03's gotchas name the exact mechanism — the repository reuses the previous bucket's list instance when that bucket is unchanged — and T06's rebuild counter is what proves it |
| **Two keypad geometries and two bottom rows are live** | `06 §8.2` says the bottom-right key is always the decimal and renders **inert** when the field is integer-only; Indelible §7.2 says the bottom row is `⌫ · 0 · NEW TAG` and *"Disabled: Never"* — and the anchor test's whole subject is that no key is ever disabled | T04 rules it in writing, amends the losing document in the same commit, and its anchor test is the executable form of the ruling |
| **`07 §5.1`'s strips scroll horizontally, and drag is banned** | *"fixed height, horizontally scrolling"* against `CLAUDE.md`'s *"drag and drag handles"* ban and Indelible §7.15's six full-width 64px ruled lines. A horizontal strip is operated by a lateral drag, and the gate has no row that catches a `ListView(scrollDirection: Axis.horizontal)` | T06 rules it and cites both sides. Vertical page scroll is not in question — Indelible §4.5 is *"one scrolling ruled page"* |
| **P9 (16 pt vs 8–12 px separation) is ruled at N33-T03, after the keypad is drawn** | T04 could freeze either number into a passing assertion, which then reads as settled a whole epic before the ruling | T04 reads `context.tokens.gapMin` and asserts the **target floor**, never the gap number |
| **`--t-head` 16 px and `--t-stamp` 14 px are under the 18 px floor** | The `[audit]` Indelible defect 2. T05's page header is not a stamp — it is longer than twelve characters and it is the one line naming what the page is — so the 14 px stamp exemption does not cover it | T05 renders the header at whatever size N09-T05's corrected exemption test allows, and never re-introduces 16 px |
| **The live row scrolls away** | The `[audit]` Indelible defect 1: `indelible.html:1138` puts the live row inside the scrolling `.stream`. The corrected rule is *the live row is a fixed layer above the bottom band*. Owner: **N13-T05** | T05 asserts the live row's `Rect` is unchanged after scrolling the page to its extent |
| **The matrix is created before its fixture exists** | Critique **S3**, once. Rebuilding it here against `restoreFixture('flock_400_3seasons.json')` would repeat the defect nine epics early | T07 uses `test/support/seeds.dart` and states the seeds-now / fixtures-at-**N23-T05** rule once, in the harness comment where it will be read |
| **A paywall flash at 3am** | Decision #90's failure mode is a store call or an entitlement read on the shed path. Nothing in this epic should ever want one — which is exactly when it gets added by accident | T04 pumps every entitlement state and asserts the pixels are identical; `FakePurchaseService.calls` must stay empty through every `pumpApp` in this branch |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `MaterialApp` sets `home: const QuickEntryScreen()` and `navigatorKey: Routes.navigatorKey`, and sets no `restorationScopeId`
- [ ] `RouteNames` has thirteen constants; `routes.dart` contains no `push(`, no `onGenerateRoute`, no `routes:` map and no `pushNamed`
- [ ] `recentEwesProvider`, `inPensProvider` and `flockTagCacheProvider` appear nowhere (R26, R28)
- [ ] `combineLatest` appears nowhere in `lib/`
- [ ] no file under `lib/features/` imports `package:drift`, `package:sqlite3` or `lib/core/db/`
- [ ] `features/quick_entry/widgets/big_keypad.dart` does not exist; the pad is `lib/core/ui/components/shed_keypad.dart` (R70)
- [ ] nothing in `lib/features/quick_entry/` watches `entitlementProvider` or `purchaseServiceProvider` (decision #90)
- [ ] every user-facing string authored in this branch is in `app_en.arb` with a `description`; no domain noun appears literally in a message
- [ ] every interactive element has a `semanticLabel` and a `quick_entry.` or `keypad.` key, all `lower_snake` (R59)
- [ ] `kPumpableVariants` has exactly one entry and the matrix's cell count is derived from it
- [ ] **P3 is either closed by a ruling that amends its losing document in the same commit, or carried into the PR body as open with both sides cited** — never silently resolved
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/` or `ios/`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

Type `12` on a real phone and 412 · 128 · 12 rank **in the same frame**, with no SQL round
trip.

## Notes

`routes.dart` lands `RouteNames` (thirteen `const String`s — free, no compile edge),
`Routes.navigatorKey`, the route factory and **only the Quick Entry helper**. Every screen epic adds
its own `RouteNames` case and its own push helper. The *"thirteen names, twelve helpers"* assertion is
a `test/policy/` row in N33. This closes critique defect **S2**.

**A correction the critique's own wording invites.** S2's fix text says *"the `onGenerateRoute`
switch"*, but `02 §8.1` says *"There is no `routes:` table and no `onGenerateRoute`"* and §8.4 bans
`onGenerateRoute` outright with its reason. `CONVENTIONS` §2.14 carries `RouteNames`, `Routes` and
`Routes.navigatorKey` and nothing else. Build **no** `onGenerateRoute`; the "switch" is the private
`_route(name, builder)` factory that stamps `RouteSettings(name:)`. T01 states this.

**And the other half of S2's wording.** Quick Entry is `MaterialApp.home`, route 0, `isFirst`, and is
**never pushed** (`02 §8.1`, `07 §1.1`). So the one helper `routes.dart` ships today is
`Routes.popToQuickEntry` — a *pop* helper — plus its context-free twin `popToQuickEntryGlobal`, which
the resume policy and a future notification tap need. The push-helper count today is **zero**, and the
arithmetic *thirteen names minus twelve push helpers equals one* is only complete once all twelve
pushed screens exist. T01 writes both facts into the file, beside the deferred assertion.

`kPumpableVariants` is created here with **one** entry and grows one row per screen epic, reaching
fourteen at N33-T01 (`12 §6.1`: thirteen routes plus the export-banner variant, R58). Matrix cells use
`test/support/seeds.dart` until the two committed fixtures exist; the switch to `restoreFixture` is
**N23-T05**, and that task is the one that proves the fixture is loadable. This closes critique defect
**S3**.
