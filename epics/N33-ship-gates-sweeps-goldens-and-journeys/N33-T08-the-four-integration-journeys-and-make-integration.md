# N33-T08 — The four integration journeys and `make integration`

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 8 of 9 |
| **Depends on** | N33-T07 |
| **Commit** | one commit · `test(integration): the four journeys` |

## 1. Why this task exists

Four journeys through the real app on a real device — reported, **never blocking**, because
an integration suite in the blocking set is a suite that gets deleted the first week it is flaky.

`12 §9` is blunt about the scope: *"An app with no network and no login has very little
integration-shaped risk, which is precisely why the set is small and fixed at four."* Each journey
exercises **wiring** that unit and widget tests structurally cannot, and the justification for each is
that specific gap — not "end-to-end coverage", which is not a thing this app needs. The largest gap of
all is the one the widget harness creates on purpose: `openAppDatabase()` **asserts it is not under
`flutter_test`** and throws. Everything the real opener does — the pragmas, the application-support
path, the `onCreate` seed — is unexercised until this file exists.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | **§9** (the four journeys, one row each, with the wiring only each one exercises; why `patrol` is rejected; **the honest gap**) · §3.5 (durability as a testable property, one tier down) · §5.1 (why the widget harness never runs the real opener) · §11.6 (flakiness discipline — no `Future.delayed`, no wall-clock assertion, no `pumpAndSettle` on a repeating animation) | the four journeys and what each is for |
| `docs/engineering/13-build-ci-release.md` | **§4.2** (the job matrix — the integration row reads *"the developer's desk, phone plugged in"*, **reported, never blocking**, and the paragraph explaining why `schedule:` cannot drive a device) · **§4.6** (what is deliberately not automated, and the CI anti-patterns — including `continue-on-error`) · §1.3 (the `Makefile`'s `integration` target, already shipped) | why this is not a GitHub job, and which target runs it |
| `docs/engineering/01-architecture.md` | §4.2 (event verbs; the row is created on screen entry) · §6 (`main()` awaits nothing; the database opens after the first frame) | what journey 1 is actually watching |
| `docs/engineering/03-data-model-and-schema.md` | §1.3 (the connection pragmas, `synchronous = FULL`) · §11 (the first-run seed and `current_season`) · the `BEFORE UPDATE` trigger on `lambs.birth_dam` | the three things only a real file proves |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7 (the atomic replace-everything restore: a **new** file beside the live one, then a swap) | journey 4's whole point |
| `docs/engineering/09-export-formats.md` | §7.3 (`restoreInto`, `freshSupportDir`) · §5 (the JSON backup envelope) | how journey 4 exports without a share sheet |
| `docs/engineering/07-screens.md` | §1.3 (the three tap budgets and the fifteen-second claim) · §3.1 (create-on-the-fly) · §5.3 (the tag index and the ordering risk) · §8 (Foster) | the four flows the journeys walk |
| `docs/engineering/CONVENTIONS.md` | **R57** (`integration_test/` at the top level — the directory name the SDK package requires; `test/integration/` is banned) · §1 (the tree) · §5 | **BINDING**, and the file-name conflict this task rules |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#117** (`integration_test` from the SDK, four journeys, no more; nightly on a real device; reported, not blocking; `patrol` and Firebase Test Lab both rejected with reasons) · #42 (the first-run seed) · #121 (the CI shape) | the decision that fixes the set at four and keeps it off CI |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 (this task's anchor) · §11.1 N33 | the anchor's file name, and where the journeys sit |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the integration tier, its cost and why it does not gate |
| `shed-write-path` | journeys 1–3 walk the product's four real paths, verb by verb, and journey 4 walks the only recovery path it has |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `integration_test/journeys_test.dart`
- **Test** — `'the 3am journey records a lambing with three lambs from a cold start in under fifteen seconds'`
- **Why it is red today** — nothing exercises the app end to end on a device.

```bash
fvm flutter test integration_test/journeys_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so the number means what the spec means. Measure from **`runApp`** to the
`INSERT` returning, not from the first frame — the fifteen seconds in spec §5 is *unlock to a saved
lambing*, and the app's whole bootstrap argument is that `main()` awaits nothing. And run it in
**profile** mode: `flutter test integration_test` runs in **debug** by default, where a cold start is
several times slower than the release build the claim is about. In debug the case must **skip with a
reason**, never assert a loosened number.

**Green.** The minimum code that passes, and nothing beyond it — four journeys, the `make integration` target, and a reported-not-blocking CI step.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Two rulings this task takes before it writes a line

**Ruling 1 — one file, four groups.** `12 §9` names four files and `CONVENTIONS` R57 names
`integration_test/first_run_journey_test.dart` explicitly. The anchor is
`integration_test/journeys_test.dart`, and that is the file this task lands, because **each additional
file under `integration_test/` is another full install-and-launch cycle on the device**: four files
means four builds, four installs and four cold starts on a suite that runs on a desk with a phone
plugged in. Four `group()`s in one entry file is the shape the SDK's own tooling is fastest with, and
the four journeys keep `12 §9`'s names as their group names. **Amend `12 §9`'s File column and R57's
last sentence in this commit**, per the amendment rule; and read `CONVENTIONS §6`'s tail before typing
a ruling number, because N00-T05, N16-T02, N16-T04 and N16-T05 have each claimed one past R74.

**Ruling 2 — the "reported, never blocking" CI step is not a CI step.** The old green line says *"a
reported-not-blocking CI step"*. `13 §4.2` is explicit that this cannot exist: GitHub's `schedule:`
trigger cannot drive a real device, hosted emulators run debug mode only, and Firebase Test Lab
requires an account and an upload — *"the exact posture the product rejects (#117)"*. And
`continue-on-error: true` is a named CI anti-pattern in `13 §4.6`: *"if it is not worth failing on,
delete it."* So the journeys are **not a GitHub job at all**. "Nightly" in decision #117's words means
*a scheduled job on your own machine* — a `launchd` or `cron` entry running `make integration` against
a plugged-in phone. The recipe is recorded in `README.md`; nothing new lands in `tool/`, whose contents
`CONVENTIONS §1` fixes at four files.

### 5.2 The files, in `00-README` §8 order

**No schema, no domain, no data, no wiring, no controller, no UI.** One new test file, one README
paragraph, two document amendments, one existing test extended — say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `integration_test/journeys_test.dart` | **New. The anchor, written first.** `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, then four `group()`s named for `12 §9`'s four journeys |
| 2 | `Makefile` | **Verify, do not add.** `integration: $(FLUTTER) test integration_test -d $(DEVICE)` shipped at N01-T05. Add only the guard that fails with a readable message when `DEVICE` is unset — an unguarded run picks an arbitrary attached device, including a simulator, and journey 1's *fresh install* then means nothing |
| 3 | `README.md` | **Edit.** The `launchd` or `cron` recipe and the sentence that the journeys never run in GitHub Actions, with `13 §4.2`'s reason. It sits beside the cold-cache network paragraph N01-T05 put there |
| 4 | `test/policy/ci_jobs_test.dart` | **Edit.** Two cases: **no** workflow under `.github/workflows/` runs `integration_test`, and `make integration` exists and requires `DEVICE`. The first is the assertion that keeps ruling 2 true after everybody has forgotten why |
| 5 | `docs/engineering/12-testing.md` §9 | **Amended, in this commit.** The File column becomes four group names in one file, with the install-cycle reason |
| 6 | `docs/engineering/CONVENTIONS.md` R57 + §6 | **Amended, in this commit.** R57's *"its first-run journey becomes `integration_test/first_run_journey_test.dart`"* becomes the one-file form, recorded as a numbered ruling |
| 7 | `.github/workflows/ci.yml` | **Unchanged, deliberately.** Say so in the commit message: the absence is the design |

### 5.3 The signatures

The entry file and its four groups:

```dart
// integration_test/journeys_test.dart
// FOUR journeys, ONE file. Each extra file under integration_test/ is another
// full build-install-launch cycle on the device (12 §9, amended here).
//
// test/flutter_test_config.dart does NOT apply to this directory — the SDK
// scans UP from the test file and stops at the first config or at
// pubspec.yaml. There is no tolerant comparator and no loaded font here, so
// nothing in this file is a golden.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('first run', () { … });            // 12 §9 journey 1
  group('create on the fly', () { … });    // journey 2
  group('foster', () { … });               // journey 3
  group('backup and restore', () { … });   // journey 4
}
```

The fifteen-second claim, measured honestly:

```dart
testWidgets('the 3am journey records a lambing with three lambs from a cold start '
    'in under fifteen seconds', (tester) async {
  // Debug mode is several times slower than the release build the claim is
  // about. Skip loudly rather than assert a number that means nothing.
  const profile = bool.fromEnvironment('dart.vm.product') ||
      const bool.fromEnvironment('dart.vm.profile');

  await deleteApplicationSupportDatabase();   // a genuinely fresh install
  final sw = Stopwatch()..start();
  app.main();                                  // the REAL main(), not pumpApp
  await tester.pumpAndSettle();
  // … three digits, confirm, "Lambing", three slab presses …
  sw.stop();

  expect(await countLambs(), 3);
  if (profile) {
    expect(sw.elapsed, lessThan(const Duration(seconds: 15)),
        reason: 'spec §5: unlock to a saved lambing');
  }
}, skip: !profile ? 'the fifteen-second claim is only measurable in profile mode' : null);
```

### 5.4 The four journeys, and the wiring only each one exercises

`12 §9`, with the assertion each one turns on:

| # | Group | Journey | The wiring only it exercises, and what to assert |
|---|---|---|---|
| 1 | `first run` | Fresh install → the first frame → a saved lambing for a **new** ewe, without opening Settings | The real `openAppDatabase()` — which the widget harness deliberately never runs. Also the real `onCreate` seed (#42): **without it `current_season` is null and the first keypad tap cannot insert a lambing.** Assert the seed ran (`current_season` is not null) *before* asserting the lambing exists, so a first-launch-only defect fails by its own name |
| 2 | `create on the fly` | Type an unknown tag → one confirm creates the ewe → straight into Lambing Entry | Routing **and** insert ordering across two repositories in one flow. Spec §7.1: *"never block an entry to make the user go and set something up first."* The failure mode is an ordering bug that only appears when the tag index has not resolved yet (`07 §5.3`) — so do **not** settle between the digits and the confirm |
| 3 | `foster` | One tap on the Foster screen reassigns a lamb | The `BEFORE UPDATE` trigger that makes `birth_dam` immutable, **running against a real file**, plus the compensating-event undo. Assert `birth_dam` is unchanged, that a `FosterEvent` row exists, and that the rearing-dam **view** returns the new ewe |
| 4 | `backup and restore` | Export a full JSON backup to a temp file (bypassing the share sheet) → wipe → restore → the flock reads identically, provenance included | The only recovery path the product has, on a real filesystem with real permissions and the real atomic path swap. `RestoreService` writes a **new** file beside the live one and swaps; a sentinel that survives a crash mid-swap is not testable in memory |

### 5.5 The details that are easy to get wrong

- **Do not add a GitHub job, and do not add `continue-on-error: true` to make one non-blocking.** Both
  are covered above; the assertion in `ci_jobs_test.dart` is what keeps it true.
- **`test/flutter_test_config.dart` does not apply here.** The SDK scans **up** from the test file to
  the first config or to `pubspec.yaml`; `integration_test/` is a sibling of `test/`, not a child. No
  loaded font, no tolerant comparator — nothing in this directory is a golden, and a `matchesGoldenFile`
  here would compare against an Ahem render.
- **Do not import `test/support/harness.dart`.** `shedContainer` overrides `databaseProvider` with an
  in-memory database, which is the precise opposite of what journey 1 is for. Journeys run `app.main()`
  and touch the real DI graph. Small helpers for the journeys are private top-level functions **in this
  file** — the same rule `12 §5.3` applies to `selectEwe` and `enterWithdrawal`: a shared tap sequence
  quietly stops being the thing the test is measuring.
- **"Fresh install" means deleting the file, and the file is in application support, not Documents**
  (decision #27). Delete it before `app.main()`, in the test, and assert it is gone — otherwise journey
  1 is journey 2 with extra steps on the second run.
- **The real `onCreate` seed is the thing journey 1 exists for.** Decision #42: without it,
  `current_season` is null and the first keypad tap cannot insert a lambing. That is a
  first-launch-only defect that **no in-memory test can reproduce**, because the harness seeds around
  it.
- **`pumpAndSettle()` with no timeout is safe only because indefinite animations are banned**
  (`12 §11.6`). On a real device the 60 s ticker is `Future.delayed`, not `Timer.periodic`, so it does
  not hold the pump — but if any repeating animation ever ships, this call hangs for ten minutes and
  then fails opaquely.
- **No `Future.delayed`, no wall-clock assertion, no `DateTime.now()` in a test body.** The stopwatch
  above measures elapsed real time, which is the one legitimate exception and is why it lives behind
  the profile-mode guard.
- **Journey 3's trigger only exists against a real file.** A `BEFORE UPDATE` trigger in `views.drift`
  is compiled into the database; asserting `birth_dam` immutability in memory tests the same trigger,
  but asserting it *after a reopen* is what proves the trigger survived the file. Read the value back
  after closing and reopening.
- **Journey 4 bypasses the share sheet and must say so.** `SharePlus` opens a native surface
  `integration_test` cannot drive. Export to a temp path directly through `ExportRepository` +
  `MediaStore.writeAtomically`, then restore from it. That is not a shortcut — the share sheet is
  another process and is out of scope by construction (`00-README` §2.1's third tier).
- **Journey 4 asserts provenance, not just row counts.** *"the flock reads identically, provenance
  included"*: `captured_at`, `original_effective` and `time_source` all survive the round trip. A
  restore that loses `time_source` turns every edited row into an auto one, which is safety rule §12.5
  deleted silently.
- **Four native surfaces cannot be driven here and must be hand-verified**: notification permission,
  camera, microphone and the share sheet. Each appears **once, on first use**; a solo developer
  verifies them by hand in five minutes per release. `patrol` could drive them and is rejected for v1
  because it costs a Gradle test target, an Xcode test target, `patrol_cli` in CI and the permanent
  loss of `flutter test` for those files.
- **The honest gap, stated in the file's header comment rather than discovered later.** Spec §5 says
  *assume the phone dies*, and proving that properly means killing the process mid-entry and
  relaunching, which `integration_test` cannot do. The mitigation is to move the durability proof
  **down** a tier to `12 §3.5`'s reopen-the-file test, which is more deterministic than a process kill
  would be. Do not let the journey imply coverage it does not have.
- **`make integration DEVICE=` unset picks an arbitrary attached device.** On a laptop with a simulator
  running, that is a simulator — no real filesystem permissions, no real cold start, and journey 1's
  fifteen seconds are meaningless. Guard it.

### 5.6 The full test set

| File · case | What it asserts |
|---|---|
| `integration_test/journeys_test.dart` · `'the 3am journey records a lambing with three lambs from a cold start in under fifteen seconds'` | **The anchor.** Fresh file, real `main()`, three digits, confirm, "Lambing", three slab presses; three `lambs` rows; the elapsed assertion in profile mode only |
| `…` (group `first run`) · `'the onCreate seed runs and current_season is not null before the first tap'` | *edge.* Decision #42's first-launch-only defect, asserted **before** the lambing so it fails by its own name |
| `…` · `'openAppDatabase opens under application support, not Documents'` | *edge.* Decision #27, on a real filesystem |
| `…` (group `create on the fly`) · `'an unknown tag becomes a ewe and a lambing in one confirm, with no settings visit'` | Spec §7.1. Routing plus insert ordering across two repositories |
| `…` · `'the confirm lands before the tag index has resolved and still creates exactly one ewe'` | *edge.* `07 §5.3`'s ordering bug, reproduced deliberately by not settling between the digits and the confirm |
| `…` (group `foster`) · `'one tap reassigns the lamb and birth_dam is unchanged after a reopen'` | The `BEFORE UPDATE` trigger against a real file, read back after a close and reopen |
| `…` · `'a FosterEvent row exists and the rearing-dam view returns the new ewe'` | The other half of journey 3 |
| `…` · `'undo writes a compensating FosterEvent and never deletes the first'` | *edge.* Append-only, labelled corrected (N18-T03) |
| `…` (group `backup and restore`) · `'export, wipe, restore — the flock reads identically'` | Row counts and content across every table |
| `…` · `'provenance survives the round trip: captured_at, original_effective and time_source all match'` | *edge.* §12.5, on the one path that can lose it |
| `…` · `'a lambing stored at the ambiguous instant round-trips through the backup unchanged'` | *edge.* The fixture's 01:30-on-25-October lambing: assert the **stored** `occurred_at` epoch millis are byte-identical before and after. Epoch millis are zone-independent, so this case is meaningful on a device in any zone — which is why it is the ambiguous-hour case that belongs at this tier. The **rendered** half is `12 §2.4`'s `test/data/lambing_ambiguous_hour_test.dart`, tagged `uk-zone`, and the header comment says so rather than leaving the reader to assume this file covers it |
| `…` · `'the restore swapped a new file in and the old one is gone'` | *edge.* `04 §7`'s atomic path swap, observed on the filesystem |
| `test/policy/ci_jobs_test.dart` · `'no workflow runs integration_test'` | **Edited.** Ruling 2, held by a machine. Reads every file under `.github/workflows/` |
| `…` · `'make integration exists and fails readably when DEVICE is unset'` | **Edited.** The guard, and the reason a simulator run is not a journey run |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the 3am journey records a lambing with three lambs from a cold start in under fifteen seconds'` passes, and was seen to fail first for the stated reason
- [ ] four journeys covering entry, foster, treatment and export
- [ ] the 3am journey asserts the fifteen-second claim
- [ ] reported, never blocking
- [ ] each journey runs against a seeded fixture
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **no** workflow under `.github/workflows/` runs `integration_test`, and `ci_jobs_test.dart` asserts it
- [ ] no step anywhere in the repository carries `continue-on-error: true`
- [ ] the fifteen-second assertion runs in **profile** mode and skips with a reason in debug — it is never loosened
- [ ] journey 1 deletes the application-support database first, and asserts `current_season` is seeded before it asserts the lambing
- [ ] `integration_test/journeys_test.dart` imports nothing from `test/support/`
- [ ] `12 §9`'s File column and `CONVENTIONS` R57's last sentence are amended in this commit, and the ruling is numbered
- [ ] `make integration` fails readably when `DEVICE` is unset
- [ ] the file's header comment states the honest gap (no process kill; durability lives at `12 §3.5`) and the four hand-verified native surfaces
- [ ] the ambiguous-instant round-trip case exists, and the header says where the rendered half lives

## 8. Verification

```bash
fvm flutter test integration_test/journeys_test.dart -d <device>     # debug: the timing case skips
make integration DEVICE=<device>
make integration                                                     # expect: a readable DEVICE error
fvm flutter test test/policy/ci_jobs_test.dart
make check
make test
```

The fifteen-second claim, measured where it means something:

```bash
fvm flutter test integration_test/journeys_test.dart --profile -d <device>
```

Prove the two rulings hold:

```bash
grep -rn "integration_test" .github/workflows/     # expect zero
grep -rn "continue-on-error" .github/workflows/    # expect zero
grep -rn "test/support/" integration_test/         # expect zero
ls integration_test/                               # expect one file
```

The launchd/cron entry, once, on the developer's machine — not in the repository:

```bash
# README.md records this. It is a machine-local schedule, not a project artefact.
crontab -l | grep 'make integration'
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(integration): the four journeys`
