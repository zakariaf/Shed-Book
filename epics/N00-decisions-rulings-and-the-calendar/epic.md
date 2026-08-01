# N00 — Decisions, rulings and the calendar

| | |
|---|---|
| **`00-README` §9 step** | 0 |
| **Depends on** | — |
| **Size** | S |
| **Was** | E00, plus the four calendar items the old plan left unowned |
| **Branch** | `epic/n00-decisions-rulings-and-the-calendar` — one pull request, merged before the next epic is cut |
| **Pipelines** | no pipeline yet — `.github/workflows/ci.yml` lands in N01-T06, so this PR is proved by the commands in each task's Verification block |

## Goal

The five pre-commit decisions are closed, the schema-irreversible rulings are made, the
dependency table is proved to resolve, and every calendar commitment is written where a test can see
it. Almost none of this is product code and all of it is unrecoverable later.

`00-README` §9 puts this at **step 0** and gives the reason in one line: *"Both are calendar-blocking
and neither is code. Item 1 of §5.2 closes three other open questions; Play's closed test is 2–3 weeks
**after** you have found twelve shepherds."* The rest of the build order front-loads the irreversible and
the invisible-when-wrong; this epic front-loads the things that are irreversible **and** need somebody
else's calendar. Everything here is either a decision that expires (a `pubspec.yaml` question expires
when the pubspec closes in T03; a schema question expires at the freeze in N07-T08) or a booking whose
lead time is measured in weeks.

## What is observably true when this epic merges

Nine commits on `main`, and every one of these can be run or read:

| Claim | How you see it |
|---|---|
| The repository is a Flutter project at the pinned SDK | `fvm flutter --version` prints Flutter **3.44.8** and Dart **3.12.2**; `android/` and `ios/` exist; `fvm flutter build apk --debug` completes |
| The toolchain pin cannot float | `test/policy/toolchain_pin_test.dart` goes red if `.fvmrc` is edited to `stable`, a caret or a channel |
| Decision-record §5's dependency table actually resolves | `fvm flutter pub get` succeeds and `pubspec.lock` is committed beside the `pubspec.yaml` that produced it — decision #5's evidence, and the first time anyone has run it |
| `flutter_riverpod` is `2.6.1` and `package:test` is not a direct dependency | `test/policy/lockfile_is_evidence_test.dart` reads the **lockfile**, not the pubspec |
| The two dependency-shaped questions are closed | decision-record §7.1's in-app-printing and voice-note-cap rows carry a ruling, a reason and a date; `test/policy/dependency_rulings_test.dart` is green |
| The four schema-shaped questions are closed | each names the table and column it becomes in N07; `test/policy/schema_shaped_rulings_test.dart` is green |
| P1 is ruled in writing | `CONVENTIONS §6` carries a numbered ruling for `struck` / `struck_at` and lists every table it applies to; `test/policy/p1_ruled_test.dart` is green and `python3 tool/validate_skills.py` passes |
| Seven calendar commitments exist where a test can see them | `docs/calendar.md` has seven rows; `test/policy/calendar_commitments_test.dart` **names by row** every one still undated |
| The field night, the ziplock test and the store accounts have owners and dates | three of the seven rows are green; the ledger test is deliberately still red for the rest, and it says which |

The one thing you cannot demo is a screen. There is no `lib/` in this epic — `CONVENTIONS §1`'s tree
is `mkdir`-ed in N01-T01 — and that is the point: the whole epic is decisions, evidence and bookings.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §1 (the five pre-commit decisions), §5 (the only source of a version number), §7.0 / §7.1 (ruled and still open) | every version, every ruling, every row struck in this epic |
| `docs/engineering/00-README.md` | §4, §5.2, §7.4, §9 step 0, §10 (the amendment rule) | why each item is calendar-blocking, what is committed, and how a ruling propagates |
| `docs/engineering/CONVENTIONS.md` | §1, §2.7–§2.9, §4.6, §6 (the ruling log), §7 | the tree, the columns and enums the rulings name, and the next free ruling number |
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.2, §10.2, §11 | the `.fvmrc` shape and its CI assert, the lockfile-as-evidence rule, Play's 12-tester clock, the seasonal freeze |
| `docs/engineering/11-monetization-and-store.md` | §10 | price, territories, Apple SBP and Google's 30 June 2026 fee restructure |
| `docs/skills/02-build-manifest.md` | §4.5 | P1 as the last schema-irreversible open conflict |
| `epics/00-PLAN-CRITIQUE.md` | §2, §9, §11.2, §11.5 | why the calendar ledger is blocking and why this epic is nine tasks, not six |
| `shed-book-spec.md` | §3, §14, §17 | the recruitment channels, the price range, and the four questions to resolve before building |

## Tasks

| Task | One line | Depends on |
|---|---|---|
| [N00-T01](N00-T01-the-flutter-project-and-the-toolchain-pin.md) | The Flutter project and the toolchain pin | — |
| [N00-T02](N00-T02-rule-the-two-dependency-shaped-open-questions.md) | Rule the two dependency-shaped open questions | N00-T01 |
| [N00-T03](N00-T03-pubspecyaml-from-decision-record-5-and-the-committed-lockfil.md) | `pubspec.yaml` from decision-record §5, and the committed lockfile | N00-T02 |
| [N00-T04](N00-T04-rule-the-four-schema-shaped-questions.md) | Rule the four schema-shaped questions | N00-T01 |
| [N00-T05](N00-T05-rule-p1-struck-struck-at-on-every-table.md) | Rule P1 — `struck` / `struck_at` on every table | N00-T04 |
| [N00-T06](N00-T06-docscalendarmd-and-the-ledger-test-that-stays-red-until-it-i.md) | `docs/calendar.md` and the ledger test that stays red until it is filled | N00-T01 |
| [N00-T07](N00-T07-book-the-field-night-and-start-recruiting-twelve-shepherds.md) | Book the field night and start recruiting twelve shepherds | N00-T06 |
| [N00-T08](N00-T08-the-ziplock-bag-capacitance-test.md) | The ziplock-bag capacitance test | N00-T06 |
| [N00-T09](N00-T09-store-accounts-the-small-business-program-price-and-territor.md) | Store accounts, the Small Business Program, price and territories | N00-T06 |

Two chains run through the epic. **The pubspec chain** — T01 creates the project, T02 rules what may
enter the dependency table, T03 closes it and commits the lockfile — must run in that order, because
T03 is the moment the two dependency-shaped questions stop being answerable. **The ledger chain** —
T06 builds the ledger and its test, then T07, T08 and T09 each turn rows green — can run in any order
after T06. T04 and T05 (the schema rulings) touch no code and can be done while a shepherd is not
answering the phone.

## The pull request, concretely

1. **Cut the branch from `main`.** `git switch main && git pull && git switch -c epic/n00-decisions-rulings-and-the-calendar`.
   This is the first substantive branch in the repository, and N00-T01's commit is the first commit that puts a
   Flutter project in it.
2. **One commit per task, in file order T01 → T09.** Each task ends `/simplify` → `/code-review` →
   `/shed-code-review` → commit, in that order, over that task's diff only. No task in this epic states an
   exception, so nine tasks means nine commits.
3. **Run `/shed-code-review` once more over the whole branch** before the PR opens, reading in
   `00-README` §10's irreversibility order: the identifier and dependency files first
   (`android/app/build.gradle.kts`, `pubspec.yaml`, `pubspec.lock`), then the rulings that bind the
   schema (`CONVENTIONS §6`, decision-record §7), then the ledger and the tests. A branch reviewed in
   nine pieces has not been reviewed as a change.
4. **Open the PR** — `gh pr create --base main --head epic/n00-decisions-rulings-and-the-calendar`.
   The five §12 questions are answered **in the PR body**. `.github/pull_request_template.md` does not
   exist yet (it lands in N01-T07), so for this one PR paste them by hand from
   `docs/engineering/CODE-REVIEW-CHECKLIST.md` §2, where the five safety rules are already written as
   questions.
5. **Wait for the pipelines — and there are none.** `.github/workflows/ci.yml` is created in N01-T06, so
   no `gate`, no `codegen`, no `test` and no `android` job runs on this PR. That is a stated fact about
   this epic, not an oversight, and it is why every task in it carries runnable commands in its §8.
   What stands in for CI here, run from the repository root before you ask for the merge:

   ```bash
   fvm flutter --version                                   # 3.44.8 / 3.12.2
   fvm flutter pub get                                     # decision #5's evidence still resolves
   fvm flutter test test/policy/                           # eight files; calendar_commitments_test.dart is expected red
   python3 tool/validate_epics.py                          # the backlog's own shape
   python3 tool/validate_skills.py                         # no skill drifted from 02-build-manifest.md §3
   ```

   The first pipeline anybody sees is on N01's PR, and the first thing it does is assert that
   `.fvmrc` and the workflow's `FLUTTER_VERSION` agree (`13 §1.1`). N00's job is to make that assert
   have something true to say.
6. **Merge with a merge commit, never a squash.** `gh pr merge --merge --delete-branch`. Squashing
   collapses nine commits into one and destroys the property `epics/README.md` §1 relies on — that
   `git log` reads as the task index and a bisect lands on a task file that explains itself.
7. **Confirm `main` is green, then cut N01 from the merged `main`.** There is exactly one branch, one
   open pull request and one green `main` at any moment in this backlog; the next epic starts only
   after this one is merged and its branch is gone.

## Risks, and what is irreversible

**Loud, in the order a reviewer should read them.**

- **The application id and the bundle id (T01) can never change on either store.** They are chosen once,
  in `android/app/build.gradle.kts` and the Xcode target, and every future Play listing, App Store
  record, signing identity and purchase entitlement keys on them. Changing one after the first upload
  is a new app with no users. `13 §3.1`: *"chosen once, before the first upload, and can never change
  on either store."*
- **The four schema-shaped rulings (T04) and P1 (T05) expire at N07-T08.** Once
  `drift_schemas/drift_schema_v1.json` is committed, a change to any of them is a migration running on a
  shepherd's phone in April, in an app whose only backup is one the user remembered to make. This is
  the entire reason the rulings are in epic 0 and not in epic 7.
- **P1 is worse than a migration.** Adding `struck` / `struck_at` after the snapshot is a cheap
  `ALTER TABLE … ADD COLUMN` and an expensive re-reading of every query, every export shape, every
  statistic and every restore mapping written in the meantime — because each of them silently assumed
  no row could be struck. Rule it here or accept that N06's eight statistics, N21's three CSV shapes and
  N23's restore all get revisited.
- **Apple Small Business Program enrolment (T09) is a deadline, not a task.** It takes effect fifteen
  days after the end of the fiscal month of approval. Enrolling after the first sale means paying 30%
  instead of 15% on everything sold in the gap, for nothing.
- **Play's 12-tester / 14-day closed test (T07, T09) is the longest pole in the project.** A personal
  Google Play account created after 13 November 2023 must run a closed test with at least twelve
  opted-in testers for fourteen continuous days. Recruiting twelve shepherds from spec §3's channels is
  itself weeks. The clock cannot start until N32-T03 — but the recruiting has to start now or fourteen
  days of dead calendar sit at the end of the project by construction.
- **The field night must be booked before N13.** UK/Ireland lambing runs roughly February to April
  (`13 §11`), so the window is seasonal and does not reopen on demand. If it cannot be booked before
  Quick Entry is written, that fact is recorded in the ledger's outcome cell — because designing the
  entry flow from forum posts is a decision somebody should have to make in writing.
- **The ledger test is meant to be red when this epic merges,** and the wrong fix is to delete a row.
  It stays red until N32 closes the last commitment. `make test` and the `test` CI job exclude it by the
  `calendar` tag, which is declared in N01-T04 — **not here**, because `dart_test.yaml` does not exist
  yet. Never run `--tags calendar` before that lands: an undeclared tag matches nothing and the run is
  green having run no tests (`12 §11.2`).
- **G0 has not been run.** It is N02's whole epic. Nothing in N00 may commit a `tools:node="remove"`
  line, and no document may claim `ACCESS_NETWORK_STATE` is removed. `00-README` §2.1: until G0 has been
  run, G1 is *unwritten*, not merely unimplemented.
- **`make check` and `make test` do not exist yet.** The `Makefile` lands in N01-T05. Every task's
  Definition of Done names them because the habit is the point; in this epic the runnable equivalent is
  the task's own §8.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: no pipeline yet — `.github/workflows/ci.yml` lands in N01-T06, so this PR is proved by the commands in each task's Verification block
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `python3 tool/validate_epics.py` and `python3 tool/validate_skills.py` both exit 0
- [ ] the seven `docs/calendar.md` rows exist; three are recorded and the ledger test names the rest by row
- [ ] no `tools:node="remove"` line exists anywhere in the branch, and no document claims a permission removal G0 has not proved

## Demoable on merge

`fvm flutter --version` prints 3.44.8 / 3.12.2, `flutter pub get` resolves and the lockfile is
committed, P1 is ruled in writing, and `docs/calendar.md` exists with seven commitments —
`calendar_commitments_test.dart` naming by row every one that is still undated.

## Notes

**Why `flutter create` is here and not in N01.** The corrected plan put it in N01-T01, but every
task in this epic names a failing Dart test and a Dart test cannot run before a test runner exists.
The project skeleton is therefore the first commit in the repository; N01 prunes it to the
`CONVENTIONS §1` tree. This closes critique defect S11 one epic earlier than the critique proposed and
makes N02 (G0) runnable, because `flutter build appbundle --release` now has something to build.

**Why the tasks are renumbered against `00-PLAN-CRITIQUE.md` §11.2.** The critique lists nine tasks in a
different order — its T02 is the pubspec and its T09 is the printing/voice-cap ruling. That ordering is
impossible: the two dependency-shaped questions expire *when the pubspec closes*, so ruling them after
it is ruling them too late. The chain here is create → rule → close, and the dependency rows in each
task's header carry it.
