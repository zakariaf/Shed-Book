# N18 — Foster

| | |
|---|---|
| **`00-README` §9 step** | 6 (4 of 5) |
| **Depends on** | N17 |
| **Size** | M |
| **Was** | E15, closer task deleted |
| **Branch** | `epic/n18-foster` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Move a lamb to a different rearing dam **in one tap from the Foster screen**, append-only, with the
birth dam untouched and both dams printed side by side forever. Spec §7.3 calls this *"the flow most
likely to be abandoned if it takes five taps"*, and 03 §7 states the reason the shape is what it is in
five words: **birth is a fact, rearing is a history.**

Five tasks: the write verb (`FosterRepository.recordFoster`), the screen over the deck the shepherd
already knows, the correction as a compensating event, the `fosterToSelf` warning with the four rules
this screen may not break, and the matrix variant with its reachability assertion.

The epic writes **no schema**. `foster_events`, the `lamb_birth_dam_is_immutable` trigger and the
`lamb_rearing` view were frozen in N07-T04 and snapshotted in N07-T08. If a file under
`lib/core/db/` or `drift_schemas/` appears in this branch, stop and find out why.

## Why the epic sits here

`00-README` §9 puts Foster in **step 6**, *"the rest of the 3am path: Lambing Entry, Lamb Card,
Foster, Pen Board"*, with its stated reason — not re-derived here:

> *"These are variations on machinery step 5 already built. Foster and the pen board carry their own
> tap budgets."*

Three consequences bind the scope:

- It is **after N13/N14** because every piece of machinery this epic reuses was built there: the deck
  statement (`quickEntryDeckProvider`, R28), `ShedKeypad`, `WriteController.guard()`, and the receipt
  (`confirmSaved` / `SaveReceipt`, P2 — there is no SnackBar). N18 invents no new machinery; where it
  looks like it needs some, read the gotcha in the task file first.
- It is **after N17** — T01 opens against N17-T05's merged state — because the Foster screen is opened from the Lamb Card's rearing-dam cell
  (`indelible.md` §8 screen 6), and `lambCardProvider` already reads the current rearing dam from
  `lamb_rearing` (N17-T01) — so the screen this epic writes has somewhere to return to and something
  to re-print.
- It is **before N19** because the pen board is the other tap-budgeted screen and reuses the same
  commit-then-receipt shape settled here.

The two tracks `00-README` §9 says run from day one run here too: **accessibility** (every element on
this screen gets its `semanticLabel` and its `<screen>.<element>` key in the commit that creates it)
and **the ARB** (every string lands in `lib/l10n/app_en.arb` with a `description`, and no domain noun
is a literal — 10 §8.5). N33 only verifies; there is no later sweep.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/data/foster_repository_test.dart test/data/fostering_conservation_test.dart
fvm flutter test test/features/foster_test.dart test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
```

- **One tap reassigns a lamb.** `'foster reassignment from the Foster screen costs 1 tap'` counts the
  taps on keyed finders, from the Foster screen's first painted frame — the tap that opened it is not
  counted (07 §1.3). There is no confirmation step and no dialog: the commit *is* the tap.
- **The birth dam did not move**, proved by a value captured **before** the tap and compared after —
  not by `EweId(412)`, because 412 is a tag and an `EweId` is a row id, and under the active-only
  uniqueness ruling a tag is not even unique across time.
- **Three outcomes are distinguishable in the database.** `to_ewe`, `to_bottle` and
  `removed_unknown` read back as themselves; bottle (null by intent) and unknown (null by omission)
  are different facts and the rearing-credit numbers differ.
- **Nothing was deleted, ever.** Correcting a foster appends a second `FosterEvent` whose `corrects`
  FK names the first; both rows are present afterwards, both print on both animals' timelines, and
  `lamb_rearing` resolves to the corrected dam.
- **Fostering a lamb onto its own current rearing dam warns and still commits.** `fosterToSelf`
  renders as an amber strip; nothing is blocked, nothing is defaulted, nothing is corrected.
- **The conservation property holds under 200 random moves**: total lambs invariant, `born` counts by
  `birth_dam` summing to the same total, `reared` counts excluding bottle lambs.
- **`foster` is the sixth row of `kPumpableVariants`** and pumps clean at 3 devices × 3 text scales ×
  2 bold states, with the primary action reachable at `Device.small` × textScaler 1.3 without
  scrolling.
- **Nothing about money renders**, at any entitlement state or hour: Foster is one of the five shed
  screens (06 §12).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 (all of it), §1.3 (counting taps), §15.1–§15.3 (undo per verb, and why the label is not "Undo"), §20 (bottom third, back as a bottom-bar button) | the screen: its query, states, five rules, tap costs and §12 disclosures |
| `docs/engineering/03-data-model-and-schema.md` | §7 (fostering, the trigger, `lamb_rearing`, the born-vs-reared invariant, the conservation test), §5.5 (`Lambs`), §5.14 (who writes what) | the storage shape this epic writes into and may not change |
| `shed-book-spec.md` | §7.3, §5, §12 | birth dam and rearing dam as separate fields; two taps or fewer; the five safety rules |
| `docs/engineering/CONVENTIONS.md` | §1 (tree + the eight layer rules, **rule 6**), §2.9 (`FosterOutcome`), §2.13 (`FosterRepository.recordFoster`), §3.1–§3.4 (`fosterRepositoryProvider`, `fosterControllerProvider`, `fosterWriteControllerProvider`), §4.5 (widget keys), §5 (vocabulary), R18, R19, R27, R28, R30, R31, R32, R37, R53, R59, R64 | **BINDING** on every path, type, provider, key and word |
| `docs/engineering/05-domain-correctness.md` | §6.8–§6.10 (born vs reared, the fostering invariant), §7.5 (`checkFoster`, the `fosterToSelf` row) | what a foster may and may not change about a number |
| `docs/engineering/12-testing.md` | §2.3–§2.5 (the ambiguous hour and the three commands), §3.1/§3.3 (the drift harness), §5 (`pumpApp`), §6.2/§6.4 (the matrix and reachability), §10.1 (the published 1-tap test) | every test file this epic writes or extends |
| `docs/design/indelible.md` | §1.2 rule 1, §7.3 (the ruled record row and its struck state), §7.13–§7.16, §8 screen 6, §4.4–§4.5 | what the screen looks like and what a correction prints |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules), §3.3 (`spellOutTag`), §3.4 (Foster gets a level-1 heading and no level-2), §3.8 (the receipt is a live region), §8.4–§8.5 (ARB and the terminology placeholder) | every string and every label |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12, #22, #33, #67, #69, #90, #101 | `flutter_riverpod` **2.6.1**, `drift` **2.34.2**, Flutter **3.44.8** / Dart **3.12.2** |
| `epics/00-PLAN-CRITIQUE.md` | S2 (each screen epic adds its own route helper), S3 (fixtures do not exist until N23), S9 (N27 re-opens this repository), §11.3, §11.4 | why the tests seed instead of restoring, and which skills this epic loads |
| `CLAUDE.md` | the four non-negotiables · **P2** (there is no SnackBar) · the vocabulary table | the receipt is the committed row; *event*, *record*, *birth dam* / *rearing dam* |

## Tasks

Strictly sequential. Each task depends on the one before it: the screen cannot commit without the
verb, the correction cannot be offered without the screen, the warning cannot be asserted without the
correction, and the matrix cannot pump a screen that does not exist.

| Task | Depends on | One line |
|---|---|---|
| [N18-T01](N18-T01-fosterrepositoryrecordfoster-append-only-birth-dam-untouched.md) | N17, merged | `FosterRepository.recordFoster` — append-only, birth dam untouched |
| [N18-T02](N18-T02-the-one-tap-reassignment.md) | N18-T01 | The one-tap reassignment |
| [N18-T03](N18-T03-undo-as-a-compensating-fosterevent-labelled-corrected.md) | N18-T02 | Undo as a compensating `FosterEvent` labelled *corrected* |
| [N18-T04](N18-T04-the-fostertoself-warning-and-the-four-rules-this-screen-may.md) | N18-T03 | The `fosterToSelf` warning and the four rules this screen may not break |
| [N18-T05](N18-T05-the-matrix-variant-and-the-empty-state-row.md) | N18-T04 | The matrix variant and the empty-state row |

**T02 carries a naming ruling.** `quickEntryDeckProvider` is declared in
`lib/features/quick_entry/quick_entry_controller.dart` (`CONVENTIONS` §3.2) and **layer rule 6 forbids
`lib/features/lambing/` from importing it**. That is exactly the situation R27 already ruled once, in
these words: *"The Flock search box and the Foster screen both call it, and layer rule 6 forbids one
feature importing another, so the feature-folder placement is not merely inconsistent — it is
unbuildable."* T02 rules it the same way and amends the losing sections in the same commit. Read T02
§5.3 before writing a line of the screen.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N17 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n18-foster
```

**2 — One commit per task, five commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

One commit in this epic carries an extra obligation: **T02 amends `CONVENTIONS` §1/§3.2 and
`02-state-di-navigation.md` §4 in the same commit as the provider move**, per `00-README` §10's
amendment rule. A ruling that lands in code and not in the naming authority is a ruling that will be
reversed by the next person who reads §3.2.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`lib/data/foster_repository.dart` → `lib/data/providers.dart` → `lib/l10n/app_en.arb` →
`lib/routing/routes.dart` → `lib/features/lambing/foster_*` → `test/`. `lib/data/**` is never waved
through, however small: this is the file that writes the only row saying who reared a lamb.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land here and must be answered with a file and a test,
not with a sentence:

- **§12.4 (never silently correct an entry)** — `fosterToSelf` warns and never blocks; the correction
  is a new event and never a rewrite; `lib/data/` still cannot import `lib/domain/validation/`.
- **§12.5 (honest timestamps)** — every `foster_events` row carries the provenance quad, and the
  screen renders `RecordedTime.provenanceLabel` beside the event on both animals' timelines.
- **§12.2 (never give veterinary advice)** — 07 §8.6: *"no screen in the app is more tempting to make
  helpful."* No "this ewe has capacity", no "she has milk", no teat count, and no ordering of targets
  by anything except the two neutral facts the deck already has.

§12.1 and §12.3 do not appear on this screen — say that, and say which task would have carried them.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` | The layer rules, which are the whole architecture of this epic: `layer.sibling` (rule 6) proves `lib/features/lambing/` imports no other feature — the rule that forces T02's ruling; `layer.data` proves the repository cannot see `lib/domain/validation/` (R53); `layer.single_writer` proves no `customStatement(` escaped `lib/core/db/`. It also proves the banned gestures and the banned words are absent from a screen whose obvious implementation is a drag between two ewes |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N18 stores into a frozen table and must move no snapshot. A red `codegen` on this branch means somebody edited `lib/core/db/tables/lambing.dart` or `views.drift` — which after N07-T08 is a migration on somebody else's phone, not an edit |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` (**unscoped** — the tag selects the files) · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · coverage artefact (reported, **never** gated) | The five anchors, the conservation property and the 252-cell matrix. The `uk-zone` leg is what proves `test/data/foster_ambiguous_hour_test.dart` and `test/features/foster_dst_test.dart` ran in `Europe/London`; scoped to `test/domain`, both would run under the runner's UTC and pass because there is no spring forward there |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N18 changes no
native file and no permission, so it proves nothing this epic authored — but it must stay green.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. No golden in
the eight-image budget is a Foster screen (`12 §8.2`).

**6 — Merge, delete the branch, and only then cut N19.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n19-pen-board
```

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **Every widget key this epic introduces is a test contract** (R59): `foster.target.<tag>`,
  `foster.target.bottle`, `foster.target.not_recorded`, `foster.correct`. Renaming one later breaks
  the tap-budget test, the matrix and the semantics gate together. They are recorded in `07-screens.md`
  §8.5 in the same commit that creates them, because 07 owns screen keys.
- **The `quickEntryDeckProvider` placement ruling (T02)** is a change to `CONVENTIONS`, and
  `CONVENTIONS` outranks every other document on a path. It must land as a numbered ruling in §6 with
  its "files that must change" line, not as a quiet move.
- **Nothing else here is irreversible**, and that is worth stating: no schema, no snapshot, no native
  file, no published artefact, no allowlist line. If this branch touches `drift_schemas/`,
  `lib/core/db/`, `tool/policy_allowlist.txt`, `android/` or `ios/`, the change is in the wrong epic.

**Risks specific to N18:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **The obvious implementation updates `lambs.birth_dam`** | "Move a lamb to another ewe" reads like an `UPDATE`. It is the one write this schema physically refuses, and a code path that tried it would destroy a season of breeding history if the trigger were ever dropped | The `BEFORE UPDATE OF birth_dam` trigger (N07-T04), T01's read-back assertion, and the fact that no parameter of `recordFoster` can name a birth dam |
| **A denormalised `rearing_dam` column gets proposed to make a query simpler** | Decision #33 rejected it explicitly: a dual write a future code path gets wrong, producing a lamb whose history says *fostered to 128* while the list screen says *412* | There is no such column and adding one is a schema change after the freeze. The rearing dam is the `lamb_rearing` view, everywhere, always |
| **The event is filed under `app_settings.current_season`** | `foster_events.season` is `ON DELETE CASCADE`. A lamb from season 2026 whose foster is filed under 2027 loses its foster silently when 2027 is deleted — and `lamb_rearing` then reverts the rearing dam with no row to explain it | T01 §5.3: the season is read from the lamb's own lambing inside the same transaction, with a test that seeds a lamb in an earlier season while `current_season` is a later one |
| **Layer rule 6 makes the stated goal unbuildable as written** | *"reusing Quick Entry's deck query"* is the whole point of the epic and `lib/features/lambing/` may not import `lib/features/quick_entry/` | T02's ruling, on R27's precedent, before any screen code is written |
| **The fixtures do not exist yet** | `12 §10.1`'s published 1-tap test calls `restoreFixture(db, 'flock_400_3seasons.json')` and indexes `kSeedLamb`. Both arrive in N23 (critique S3). Copying the snippet verbatim gives a red test that looks like a product bug | T02 seeds through `test/support/seeds.dart` and captures the real ids it created; N23-T05 is the one task that switches the matrix and the budgets to the fixture |
| **"Correct this" gets implemented as "Undo"** | The framework word is Undo and the label is a field, not a constant (`SaveReceipt.undoLabel`, R31). Calling a compensating event "Undo" claims an erasure that never happens | 07 §15.3 and T03's assertion on the rendered label |
| **The correction window closes when the route pops** | 07 §15.2 fixes the window at *"until the receipt is dismissed or the route pops, whichever is first"*, and this screen commits and returns | T03 §5.3 decides where the receipt renders after the pop and asserts the affordance is present there — and gone after a restart |
| **N27-T03 re-opens `lib/data/foster_repository.dart`** | Critique S9: `ewe_summaries` is maintained inside the writes that invalidate it, and one of those writes is `recordFoster`. It is additive, but it is a second visit to the product's most-reviewed file | Named here so the N27 reviewer reads this epic's diff first, in irreversibility order |
| **A method chooser gets added because the column exists** | `foster_events.method` is a nullable FK onto the five `fm_*` vocabulary keys. Offering it on this screen costs a tap on the one flow the spec says dies at five | v1 writes `NULL`. The column stays; the chooser does not exist. T01 §5.3 |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `android/`, `ios/` or `tool/policy_allowlist.txt`
- [ ] `grep -rn "rearing_dam" lib/core/db/` still returns only `views.drift` — there is no column, only the view
- [ ] `setRearingDam` appears nowhere in the repository, and no method of `FosterRepository` takes a nullable ewe id
- [ ] `lib/features/lambing/` imports no other feature folder, proved by `layer.sibling` and not by inspection
- [ ] every new widget key and every new ARB message is recorded in `07-screens.md` §8.5 in the commit that creates it
- [ ] the three tap budgets in `test/features/tap_budget_test.dart` are all still green, not only the one this epic added

## Demoable on merge

**A reassignment in one tap** from the Foster screen, with both dams still on the page
forever — and a correction that appends a second event rather than deleting the first, both of them
printing on both animals' timelines.

## Notes

**What this epic deliberately does not build.** The rearing-dam cell on the Lamb Card is N17's; the
`ewe_summaries` reared counts are N27-T03's; the CSV columns `rearing_dam_uid` and `was_fostered` are
N21's (`09 §3.2`); the fixture switch is N23-T05's; the semantics and tap-target sweeps over
`kPumpableVariants` are N33's. This epic ends at five files under `lib/` and six under `test/`.

**`was_fostered` never returns to 0.** Once any `FosterEvent` exists for a lamb, `lamb_rearing`
reports `was_fostered = 1` forever, including after a correction. That is the design and it is what
the CSV exports: the lamb *was* fostered, and a correction is a second fact, not an eraser. Do not
"fix" it in N21 when the column reads 1 for a lamb back with her birth dam.
