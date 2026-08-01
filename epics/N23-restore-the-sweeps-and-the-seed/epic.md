# N23 — Restore, the sweeps and the seed

| | |
|---|---|
| **`00-README` §9 step** | 8 (3 of 3) |
| **Depends on** | N22 |
| **Size** | L |
| **Was** | E19b |
| **Branch** | `epic/n23-restore-and-seed` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Build the most destructive code in the app — and the seed that routes **through** it.

`RestoreService` builds a new SQLite file beside the live one, validates it completely, and only then
performs two adjacent `rename` calls with a sentinel between them. `completeInterruptedRestore` runs on
every launch before the database opens and resolves **four** reachable states, not two. The
confirmation names what will be destroyed, in numbers read from the live database. `MediaSweeper`
reconciles the media folder with the database in both directions and deletes nothing. `tool/seed.dart`
then writes its demo database *through that same path*, which is what makes 400-ewe profiling, the
overflow matrix, the goldens and the at-cap monetization tests possible at all — and what turns the
seed into a continuous test of the one code path where a bug loses five seasons.

## Why the epic sits here

`00-README` §9 puts export, backup and restore at **step 8**, and gives the ordering reason for this
half of it directly:

> *"Export, backup and restore — then `tool/seed.dart`, which writes its demo database **through the
> restore path**. Restore must exist before the seed script can route through it, and the seed script
> is what makes 400-ewe profiling, the overflow matrix, the goldens and the at-cap monetization tests
> possible at all. It also turns the seed into a continuous test of the one code path where a bug loses
> five seasons."*

Four consequences bind this epic's scope:

- It comes **after N22**, not beside it. N22 owns the format: `BackupHeader`, the canonical encoder,
  `writeBackup`, `unknown_json`, the checksum and the file import with its magic-byte check. N23
  consumes a file that has already been sniffed and whose header has already been validated. The split
  is the critique's ruling on E19: *"two different risk profiles in one PR: a format (reviewable) and
  the app's most destructive code path (not)."*
- It comes **after the schema freeze** (step 3, N07 + N08). Restore writes into *today's* schema and
  refuses a backup whose `schema` is higher than `kSchemaVersion` (`04 §6.5`). Nothing in this epic is
  schema-shaped; if a column turns out to be missing, that is a migration and it is N08's harness.
- It comes **after N21** because `ExportRepository` and `writeBackup` must exist before a round trip can
  be asserted, and because the confirmation screen's live-side counts reuse N21's per-table count query
  rather than writing a second one.
- It comes **before N24 onwards** because everything downstream that needs populated state — the
  reminder fixtures, the goldens, the ship gates, the at-cap monetization tests — loads
  `test/fixtures/flock_400_3seasons.json`, and that file does not exist until T05 generates it.

This epic also closes critique defect **S3**: the overflow matrix was created at N13-T07 seeded from
`test/support/seeds.dart` helpers, with a comment naming **N23-T05** as the switch to
`restoreFixture`. T05 is that switch, and it is the task that proves the fixture is loadable at all.

## What is observably true when this epic merges

```bash
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42
fvm flutter test test/features/restore_test.dart
fvm flutter test test/data/media_sweeper_test.dart
fvm flutter test test/features/seed_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/support/harness_test.dart
fvm flutter test test/policy/export_round_trip_test.dart
make check
make test
```

- **A phone can be filled from a backup file, and it is the only way it can be filled.** There is one
  restore code path. `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` writes its 400-ewe,
  three-season database by generating a backup and handing it to `RestoreService` — not by calling
  repositories. Run it twice with the same seed and the two files are byte-identical.
- **Export → restore → export is equal.** The `tables` value of the two files is byte-identical and the
  two `checksum.value`s match, over 200 generated flocks and over both committed fixtures. Integer ids
  differ between source and restored; every `uid` survives.
- **The live database is never written during a restore.** Kill the process at any of the three windows
  — after the sentinel and before the first rename, between the two renames, after the second rename and
  before the sentinel is deleted — and the next launch reports `notStarted`, `rolledBack` or `completed`
  respectively, with the correct file in place each time. `lostBothFiles` cannot be reached without
  deleting a file by hand.
- **The confirmation names the numbers.** *"3 seasons, 412 ewes, 861 lambs, 145 treatments. Made on
  14 Jul 2026 by Shed Book 1.1.0"* against *"1 season, 38 ewes, 41 lambs, 6 treatments"* — the second
  set counted from the live database with `COUNT(*)`, not read from any header. Two taps, in different
  places, no typed word, no gesture, both controls ≥ 60 × 60 pt. A widget test greps the rendered text
  for `/` and finds none.
- **A missing photo is a rendered state, not a crash.** After a records-only restore every
  `media_assets` row is flagged `missing_since` and the completion screen says so in words. A file with
  no row is moved to `.trash/<yyyy-MM-dd>/`, never deleted. A file that reappears is un-flagged.
- **The overflow matrix runs against 400 ewes of real data**, loaded through `restoreFixture`, which is
  a restore-path call. Its cell count is still derived from the variant list, never typed.
- **No test writes into the developer's real application support directory.** `freshSupportDir()` is a
  temp directory torn down with the test, and `restoreInto` is the only restore entry point tests use.
- **The word *merge* appears nowhere in `lib/`.** There is no merge code, so there is no merge to
  accidentally expose.

What is deliberately **not** true yet: media is not importable, and it will not be in v1
(decision #85). A restore brings back `media_assets` rows whose files are gone, and the app says so
rather than pretending. Reminders are not reconciled by anything in this epic beyond the `cancelAll()`
at step 9 — `ReminderReconciler.reconcile()` is N24's, and until it lands the post-restore step 15 call
site is a `TODO(N24)` with the reason written beside it.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | **§1 row 4** (restore is one of the four irreversible things) · **§5.1–§5.4** (both sweeps, printed in full, their schedule and their gates) · **§6.1–§6.9** (the format this epic consumes) · **§7.1–§7.8** (the rule, the sixteen-step flow, the confirmation, the failure modes, the four resume states, the nine post-restore invariants, media after restore, the gate table) · §8.1 (why `File.copy` is a bug) · §10 (the backup-and-restore Definition of Done) | the flow, step by step, and every state it may not leave behind |
| `docs/engineering/09-export-formats.md` | **§7.1–§7.3** (the round-trip property, the thirteen things that must be true for it to hold, and the printed test) · §5.2–§5.7 (the envelope, the five uid-less tables, the checksum, the compact single-encode writer) · §8.1 (the share sheet) | `restoreInto`, `freshSupportDir()`, and what equality means |
| `docs/engineering/12-testing.md` | **§5.2** (the two seeding routes) · **§5.3** (`test/support/` is twelve files and the list is closed) · §3.1 (`testDatabase()`) · §3.2 (the host sqlite3 floor) · §6.2 (the matrix and its fixture call) · **§10.6** (export → import → export, both layers) · **§11.5** (the seed command and the two fixtures, by shape) · §11.2 (`dart_test.yaml`, and why there is no preset) | where every test in this epic lives and what it is tagged |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree — `lib/data/restore_service.dart`, `lib/data/media_sweeper.dart`, `tool/seed.dart`, `test/fixtures/`) · §1.1 layer rules 3, 4, 5, 8 · **§2.8** (`RestoreService`, `RestoreOutcome`, `completeInterruptedRestore`, `MediaSweeper`, `SweepReport`, `BackupHeader`) · §2.4 (`WriteOutcome`) · §2.5 (the six `ShedFailure` variants) · §3.1 (`restoreServiceProvider`, `mediaSweeperProvider`) · §4.1, §4.5, §4.6 · §5 · **R12, R15, R18, R19, R23, R47, R52, R57, R58, R59, R60, R62, R65** | **BINDING** on every path, type, provider, key and word |
| `docs/engineering/07-screens.md` | §14.3 row 11 (Settings ▸ Data) · **§14.4** (restore is 4 taps; restore and delete are the only `showDialog` flows) · §14.5 (§12 on Settings) · §15.1 (restore has no undo) | where the flow is entered and what it costs |
| `docs/design/indelible.md` | §7.13 (the word button; **destructive is a struck label, never a filled red button**) · **§7.14** (the bottom sheet is *"the only overlay in the app"* — one side of the dialog conflict) · §7.16 (the page header) · §8 Settings (the two destructive actions and their typed confirmation) · §9 (the 3am compliance table) | how the confirmation is drawn, and the conflict T02 must rule |
| `docs/engineering/13-build-ci-release.md` | §4.2 (the four blocking jobs) · §4.3 (`ci.yml` verbatim, including `libsqlite3-dev`) · §1.3 (the `Makefile`) | which pipelines run and what each installs |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #13, #20, #21, #22, #27, #28, #29, #32, #40, #42, #46, #53, #63, **#73**, **#74**, #81, #84, #85, #86, #88, #108, #111, #118, #119, #121, #123, #124, #125 | the decisions this epic applies |
| `CLAUDE.md` | the offline-purity wording · the 3am floor · **P2** (there is no SnackBar) · the vocabulary table (*restore* never *merge*; *the backup* is JSON, *the snapshot* is `VACUUM INTO`) · the banned words | the floor, and the two words this epic is most likely to get wrong |
| `epics/00-PLAN-CRITIQUE.md` | **S3** (the matrix's fixture arrives nine epics late) · §11.3 (the anchors) · the E19 split ruling | why T05 exists and why this epic is separate from N22 |
| `shed-book-spec.md` | §5 (the 3am test) · §7.9 (export and backup) · §12.4 (never silently correct) · §17 | the product claim restore exists to hold |

## Tasks

Strictly sequential. Each task depends on the one before it, and the chain is not an accident:
the service must exist before a screen can call it, the sweeps must exist before step 15 can run them,
the seed cannot route through a path that does not exist, the fixtures cannot be generated before the
seed generates them, the harness cannot wrap a flow that is not finished, and the round-trip property
cannot be asserted before there is something to restore into.

| Task | Depends on | One line |
|---|---|---|
| [N23-T01](N23-T01-restoreservice-a-new-file-beside-the-live-one.md) | N22-T05 | `RestoreService` — a new file beside the live one |
| [N23-T02](N23-T02-the-restore-confirmation-that-names-what-it-will-destroy.md) | N23-T01 | The restore confirmation that names what it will destroy |
| [N23-T03](N23-T03-mediasweeper-both-directions.md) | N23-T02 | `MediaSweeper` — both directions |
| [N23-T04](N23-T04-toolseeddart-writing-its-demo-database-through-the-restore-p.md) | N23-T03 | `tool/seed.dart` — writing its demo database through the restore path |
| [N23-T05](N23-T05-the-two-committed-fixtures-and-the-matrix-switch.md) | N23-T04 · N13-T07 | The two committed fixtures, and the matrix switch |
| [N23-T06](N23-T06-restoreinto-and-freshsupportdir-in-the-harness.md) | N23-T05 | `restoreInto` and `freshSupportDir()` in the harness |
| [N23-T07](N23-T07-the-export-import-export-equality-property.md) | N23-T06 | The export → import → export equality property |

Three ordering wrinkles, all deliberate:

- **T01 splits the import from the swap in its first commit**, and everything after it depends on that
  split. `restoreFixture` (T05) writes into an already-open in-memory database and never renames a
  file; `restoreInto` (T06) runs the whole flow into a temp support directory. If T01 writes the
  import and the swap as one method, neither of the two later tasks is buildable and the matrix cannot
  use the fixtures at all.
- **T05 is the only two-commit task in the epic.** The generated fixtures land alone, then the switch.
  `00-README` §7.4 treats a generated artefact the way it treats a golden re-baseline: committed by
  itself so the diff that reviews it is readable.
- **T06 lands after T05, not before it.** `restoreInto` is only worth writing once there is a committed
  file to restore, and its anchor test asserts a property (*nothing touches the real support
  directory*) that is easiest to make true when both callers already exist.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N22 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n23-restore-and-seed
```

**2 — One commit per task, eight commits, in task order.** Seven tasks; T05 is two commits and its
header says why. Each task file names its commit line verbatim; use it. Before every commit, in this
order: **`/simplify`**, then **`/code-review`**, then **`/shed-code-review`**, then commit. Every
finding is resolved before the commit, not after.

Three commits in this epic carry an extra obligation:

- **T01** adds the `restore` verb's signature and its result type to `CONVENTIONS.md` §2.8. §2.8 today
  carries `RestoreService`, `RestoreOutcome` and `completeInterruptedRestore(Directory)` and stops
  there. A verb two files call and the naming authority does not carry is how a second spelling is born.
- **T02** amends `07-screens.md` §14.4, which currently says the season delete is *"the only
  `canPop: false` flow in the app"*. Restore is the second, and the amendment lands in the same commit
  as the code that makes it false (`00-README` §10's amendment rule).
- **T05** commits two generated files under `test/fixtures/`, alone, in their own commit, with the
  generating command and its seed in the commit message.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:
`tool/policy_allowlist.txt` → `test/fixtures/*.json` (generated, committed, and the input to four later
epics) → `lib/data/restore_service.dart` → `lib/data/media_sweeper.dart` → `lib/data/providers.dart` →
`tool/seed.dart` → `docs/` amendments → `lib/l10n/app_en.arb` → `lib/features/settings/` → `test/`.

`lib/data/restore_service.dart` is **never waved through, however small the diff**. It is the only file
in the product that renames the live database.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. For this epic:

- **§12.4 — never silently correct.** Two answers. Restore never repairs a contradiction on the way in:
  three lambs against a birth type of `twin` restore as three lambs against a birth type of `twin`.
  And a `media_assets` row whose file is gone is **flagged**, never deleted — deleting it would make the
  app lie by omission.
- **§12.5 — timestamps carry provenance.** `effective`, `capturedAt`, `originalEffective` and
  `TimeSource` cross the file as a unit or not at all, and nothing is re-stamped on the way in or out.
  A restore that freshened `updated_at` would break byte equality on every row at once **and** destroy
  the only evidence of when a record was made.
- **§12.1 — never default a withdrawal period.** A treatment restored from a schema that predates
  `treatment_withdrawals` produces **no** withdrawal row, which the sealed type reads as
  `WithdrawalNotRecorded`. `importDefaults` may never carry a withdrawal value, and T07's fixture
  contains a treatment with no withdrawal row precisely so the round trip proves it.
- **§12.3 — never a regulatory record.** `_disclaimer` is the first key of every backup this epic
  reads or writes, and the seed's generated fixtures carry it too.
- **§12.2 — no veterinary advice.** No copy in this epic recommends anything. The confirmation states
  consequences, not advice.

**5 — Wait for the pipelines.** Three jobs block this PR and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The rules that hold this epic's shape. `layer.single_writer` proves no `customStatement(` escaped `lib/core/db/` — restore issues `PRAGMA defer_foreign_keys`, `foreign_key_check`, `quick_check` and `wal_checkpoint`, and every one of them must be a named query or a method inside `lib/core/db/`. `layer.path_provider` proves `getApplicationSupportDirectory()` is still called in exactly two files, which is what makes `RestoreService` constructible with an injected `Directory` and therefore testable at all. `db.destructive_ddl` proves no `DROP` entered the importer. `copy.base64_backup` and the `.copy(` ban under `lib/core/db/` prove nobody reached for the obvious wrong backup. G2 + G3 prove the offline claim survived a file-handling epic: no new dependency, no new import |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | Mostly a **negative**. N23 adds no table and no column, so `drift_schemas/` must not move. A snapshot in this diff means somebody added a column to make the importer easier, and that is irreversible after N07's freeze — stop and find out why. The one legitimate positive is `lib/core/db/queries.drift`: T03's `allMediaRelativePaths`, `mediaAssetsNotYetMissing` and `flagMediaMissing` are named queries, so `database.g.dart` regenerates and that regeneration must be **in the same commit** |
| `test` | `flutter test` with `--exclude-tags golden --test-randomize-ordering-seed random` · `TZ=Europe/London --tags uk-zone` over the **whole** suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The seven anchors, plus the first fixture-backed run of the whole widget tier. The `uk-zone` leg is load-bearing three times: the trash-folder date in T03, the seed's fixed clock in T04 and the round trip's instant encoding in T07 all have a case pinned to **01:00–01:59** on the clocks-back night, and an untagged DST case passes for the wrong reason under the runner's UTC. Randomised ordering matters more here than anywhere so far: T06 hands every restore test its own temp directory, and a test that leaks one into the next shows up as a `FileSystemException` on somebody else's machine |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. Nothing in this
epic touches `AndroidManifest.xml`, `ios/` or `android/expected_permissions.txt` — **if any of the
three appears in this diff, stop.**

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. The eight
images are N33-T07 — and they are one of the four things that could not be produced before this epic
committed its fixtures.

**6 — Merge, delete the branch, and only then cut N24.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n24-reminders-rows-reconcile-and-the-fixtures
```

N24 reconciles reminders and needs `test/fixtures/flock_400_3seasons.json` to exist — and the critique
records that this fixture is generated one epic *before* reminders exist, so **it contains no reminder
rows**. N24 handles that; do not "fix" it here by regenerating the fixture later.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **`test/fixtures/flock_400_3seasons.json` and `test/fixtures/flock_15_at_cap.json`.** Generated
  artefacts, committed, and from this point the input to the overflow matrix, the accessibility gates,
  the eight goldens, the at-cap monetization tests and the spec §7.7 recall assertions. They are
  written **at today's `kSchemaVersion`** and they must **not** be regenerated when the schema bumps:
  a committed fixture carrying an older `schema` is the only standing evidence in the repo that an
  older backup still restores. Regenerating them silently deletes that evidence and changes the input
  of four later epics in one commit.
- **`lib/data/restore_service.dart`.** Not irreversible as a file, but its *behaviour* is: steps 11 and
  12 of `04 §7.2` are the only destructive operations in the product, and a bug in the ordering of
  those two `rename` calls destroys a shepherd's records with no recovery path. There is no server, no
  cloud copy and no support channel. Review it line by line, twice.
- **`lib/l10n/app_en.arb`.** Every string T02 authors is `description`-bearing and there is no later
  sweep — N33 only verifies. The destruction sentence in particular is the safety mechanism, not
  decoration, and its wording is `04 §7.3`'s, in that order.
- **`tool/policy_allowlist.txt`**, if T02 needs a line at all. `00-README` §7.4: an `[exempt]` line
  *"deletes a rule for one file, forever, silently"*. `ui.show_dialog` already carries a two-file
  exception by design — confirm the path in `tool/check_policy.dart` before writing the file, and move
  the **file**, not the rule, if they disagree.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`,
`lib/core/db/tables/`, `lib/core/db/migrations.dart`, `android/`, `ios/`, `pubspec.yaml`.

**Risks specific to N23:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **The import and the swap are written as one method** | Then `restoreFixture` cannot exist — it needs the import half against an in-memory database with no files to rename — and T05 cannot switch the matrix, which re-opens critique **S3** in the epic that was supposed to close it | T01 §5.2 fixes the split in the signature, and T05's anchor test is the executable proof that the import half is callable on its own |
| **Two restore code paths** | The fastest way to get `restoreFixture` working is a bespoke JSON loader in `test/support/`. Decision #73's whole point is that there is **one** path; a second one is a second migration surface that nobody exercises until the night it matters | T05's anchor calls `restoreFixture`, and its DoD requires the call to reach `RestoreService`. A grep for `jsonDecode` under `test/support/` is in T05's verification |
| **`RestoreOutcome` is used as the restore verb's return type** | It is the **resume** enum — `nothingToDo`, `notStarted`, `rolledBack`, `completed`, `lostBothFiles` — and `09 §7.3` says so in a code comment: *"`RestoreOutcome` is 04's enum, not a value with a database on it."* Reusing it for the live flow makes `notStarted` a legal answer to *"did the restore work?"* | T01 keeps the two apart and adds the second signature to `CONVENTIONS` §2.8 |
| **The resume routine reports `completed` for a swap that never started** | `(live exists, rollback missing)` is the crash-after-sentinel case: nothing was destroyed and the live file is the **original**. An implementation that checks only *"does the sentinel exist?"* calls it a success and tells the shepherd their records were replaced when they were not | T01's anchor test simulates all three windows and asserts the three outcomes by name; `lostBothFiles` must be unreachable without deleting a file by hand |
| **A stale `-wal` beside a swapped-in main file** | `04 §8.1`: *"if a database file is separated from its WAL file, then transactions that were previously committed to the database might be lost, or the database file might become corrupted."* Step 8's `wal_checkpoint(TRUNCATE)` and step 11 moving all **three** files are what prevent it, and both are easy to leave out because the tests pass without them | T01 asserts no `-wal`/`-shm` remains beside staging after step 8, and `_moveInto` moves the two sidecars with the main file |
| **`getApplicationSupportDirectory()` inside `RestoreService`** | It reads as the obvious thing to do and it makes the service untestable, un-seedable and un-fixture-able in one stroke: `tool/seed.dart` is a plain Dart script with no Flutter bindings, and `path_provider` in a `flutter_test` process has no platform channel | The `layer.path_provider` rule already bans it outside `connection.dart` and `media_store.dart`. The support directory is a constructor argument |
| **The seed is not deterministic because `newUid()` is not** | UUID v7 carries a time prefix and a random tail. Seed twice and the two backups differ in every `uid`, so the committed fixture churns on every regeneration and the round-trip fixture assertions become noise | T04 derives its uids from its own seeded PRNG, imports no `package:uuid` (R15), and its anchor asserts byte equality across two runs |
| **`seedFirstRun` runs on the restored database** | `04 §7.2` step 5 opens staging with `seedOnCreate: false` and step 6 runs `seedFirstRun` only *if the backup carries no season*. Get the condition backwards and every restored database gains a phantom `"2026 lambing"` nobody created — and it fails the round trip on the first table | T01's test set includes both arms: a backup with seasons and an empty backup |
| **The confirmation is a dialog, and Indelible says there are no dialogs** | `indelible.md` §7.14 calls the bottom sheet *"the only overlay in the app"*; `07 §14.4` permits `showDialog` for exactly two flows and names restore as one. Both documents are authoritative and one of them is wrong | T02 rules it in writing and amends the losing document in the same commit — the same trade N09 made for tokens |
| **The sweep deletes** | It is one line shorter, it frees the storage the diagnostics screen is complaining about, and it is banned. `04 §4.8`: media is moved to `.trash/<yyyy-MM-dd>/` and purged after 30 days or 100 MB, oldest first | T03's anchor asserts the file is **in `.trash`**, not gone, and that the row survives when its file does not |
| **The matrix goes green on an empty fixture** | If `restoreFixture` silently restores nothing — a wrong table name, a swallowed exception — every matrix cell renders the empty layout, which cannot overflow, and 144 cells pass while proving nothing | T05's anchor asserts row counts after the load, not just that the call returned |
| **The round-trip test is written three times under three names** | `12 §10.6` says `test/policy/backup_round_trips_test.dart`, `09 §7.3` says `backup_round_trip_test.dart`, and this epic's anchor says `export_round_trip_test.dart`. Three files that each assert two thirds of the property is worse than one that asserts all of it | T07 keeps this epic's anchor, folds `12 §10.6`'s two layers into the same file, and rules the spelling once — amending the two documents in the same commit |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] there is exactly **one** restore code path; `grep -rn "jsonDecode" test/support/` returns nothing
- [ ] the word `merge` appears nowhere in `lib/`, in a commit message, or in an ARB message
- [ ] `getApplicationSupportDirectory(` is still called in exactly two files (`connection.dart`, `media_store.dart`)
- [ ] the three crash windows (10/11, 11/12, 12/13) are each tested by name, and `lostBothFiles` is unreachable without deleting a file by hand
- [ ] the nine post-restore invariants of `04 §7.5` are asserted directly
- [ ] no media file is ever deleted by a sweep; a `.part` file is the one exception and it is asserted
- [ ] `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` twice produces two byte-identical files
- [ ] both fixtures are committed under `test/fixtures/`, in their own commit, with the generating command in the message
- [ ] no test writes into the real application support directory
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/`, `ios/` or `pubspec.yaml`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

`dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` fills a phone **through the restore
path**, and export → import → export is equal.

## Notes

The critique's §11.3 anchor ids for this epic (`N23-T06`, `N23-T10`) were carried over from
E19's ten-task numbering and do not fit the split. The anchors themselves are kept — the fixture load and
the round-trip property — at T05 and T07.

**The fixture-switch cross-reference is N23-T05, not N23-T06.** Critique **S3** and N13-T07's §1 both
say *"N23-T06"*; the task that lands the two committed fixtures and switches the matrix is **T05**, and
T06 is the harness pair. N13-T07 already carries the correction and writes `N23-T05` into
`test/support/harness.dart`. T05 verifies that the harness comment says T05 and updates it if it does
not. A cross-reference that names the wrong task is worse than none, because it is followed.

**One file, three spellings.** The round-trip test is named `backup_round_trips_test.dart` by
`12 §10.6`, `backup_round_trip_test.dart` by `09 §7.3` and `export_round_trip_test.dart` by this
epic's anchor. T07 keeps the anchor, writes the file once, and amends the two documents in the same
commit. There is no second copy.
