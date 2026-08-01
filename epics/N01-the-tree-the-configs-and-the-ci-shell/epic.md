# N01 — The tree, the configs and the CI shell

| | |
|---|---|
| **`00-README` §9 step** | 1 |
| **Depends on** | N00 (merged) |
| **Size** | M |
| **Was** | E01, plus the ARB bootstrap, the `test` job and the PR template |
| **Branch** | `epic/n01-tree-configs-ci` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` (both are created *inside* this epic, by N01-T06) |

## Goal

Turn the bare `flutter create` output that N00-T01 committed into the repository a developer works
inside: the `CONVENTIONS §1` folder tree, the `.gitignore` that decides what can never be committed
and — more dangerously — what can never be *lost*, the four committed generator/lint/test configs
(`analysis_options.yaml`, `build.yaml`, `l10n.yaml`, `dart_test.yaml`), the `Makefile` that is the
local mirror of CI, `lib/l10n/app_en.arb` with its first real string, and two blocking CI jobs with
the PR template that puts the five spec §12 questions in front of the reviewer.

**Why it sits at step 1.** `00-README` §9 does not argue this from taste; it gives two reasons and
they are the whole of the case. *"A gate is cheap on an empty tree and impossible to retrofit across
twelve screens"* — every rule this epic installs (the strict analyzer block, the format check, the
ARB discipline, the test tags) costs nothing today and costs a week per screen in month three. And
*"a rule nobody has seen fire is indistinguishable from a broken rule"* — which is why N01-T06 does
not end at "the workflow file is committed" but at "the two job logs have been read".

Two things `00-README` §9 says run in parallel **from day one and not at the end** start here and
nowhere later: the ARB (N01-T03 authors `app_en.arb` so that the first user-facing string in N13 has
somewhere to land) and the accessibility rules (there is no sweep epic that adds them; N33 only
verifies).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/CONVENTIONS.md` | §1, §1.1, §4.1, §5.3 | the folder tree verbatim, the layer rules the tree encodes, file naming, the banned words |
| `docs/engineering/00-README.md` | §7.1, §7.2, §7.4, §8, §9 | what is committed, what is ignored, the branch and commit rules, the file-touch order, the build order |
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.3, §4.2, §4.3, §5.2 | the toolchain pin assert, the `Makefile`, the job matrix, `ci.yml`, `analysis_options.yaml` |
| `docs/engineering/12-testing.md` | §1.4, §2.3, §2.5, §3.2, §11.2 | gate-versus-test, the ambiguous hour, the three test commands, `libsqlite3-dev`, `dart_test.yaml` |
| `docs/engineering/03-data-model-and-schema.md` | §1.2 | `build.yaml`, verbatim, and the key that must stay absent |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.1–§8.5 | `l10n.yaml`, the ARB conventions, the terminology-placeholder rule |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §2, §3.1–§3.4 | the five §12 questions and the irreversibility reading order the PR template carries |
| `epics/00-PLAN-CRITIQUE.md` | §1 S11, §9 items 2 and 4, §11.2 | why N00 runs `flutter create`, why the `test` job is in this epic and not nowhere |

## Tasks

Strictly ordered. T02, T03 and T04 are independent of each other and all three need T01's tree; T05
needs the two configs it invokes; T06 needs the `Makefile` it mirrors; T07 needs the workflow it
sits beside.

| Task | Depends on | One line |
|---|---|---|
| [N01-T01](N01-T01-prune-to-the-conventions-1-tree-and-write-gitignore.md) | the merged N00 branch | Prune to the `CONVENTIONS §1` tree and write `.gitignore` |
| [N01-T02](N01-T02-analysis-optionsyaml.md) | N01-T01 | `analysis_options.yaml` — `flutter_lints` 6.0.0 and the explicit strict block |
| [N01-T03](N01-T03-buildyaml-l10nyaml-and-libl10napp-enarb.md) | N01-T01 | `build.yaml`, `l10n.yaml` and `lib/l10n/app_en.arb` with its first string |
| [N01-T04](N01-T04-dart-testyaml.md) | N01-T01 | `dart_test.yaml` — the tags, the ordering rule, and the canary that proves a tag selects something |
| [N01-T05](N01-T05-the-makefile-cheapest-failure-first.md) | N01-T02 · N01-T04 | The `Makefile`, cheapest failure first |
| [N01-T06](N01-T06-githubworkflowsciyml-the-gate-and-test-jobs.md) | N01-T05 | `.github/workflows/ci.yml` — the `gate` and `test` jobs |
| [N01-T07](N01-T07-githubpull-request-templatemd-the-five-12-questions-verbatim.md) | N01-T06 | `.github/pull_request_template.md` — the five §12 questions, verbatim |

## Demoable on merge

`make check` is green on an empty tree, and a pull request shows a green `gate` **and** a green
`test` job with `libsqlite3-dev` installed on the test runner and the PR template putting the five
§12 questions in front of the reviewer. Concretely, the things you can run, see or show somebody
once this epic is on `main`:

| What | The command or the place to look |
|---|---|
| The tree a developer works inside exists, and the five banned test directory names cannot creep back | `fvm flutter test test/policy/tree_shape_test.dart` |
| An analyzer *info* is a build break | add an unnecessary cast, run `fvm flutter analyze --fatal-infos --fatal-warnings`, watch it exit 1 |
| A string has a home, and it is the safety-carrying one | `lib/l10n/app_en.arb` holds `withdrawalSource` with its description; `lib/l10n/app_localizations.dart` is committed beside it |
| `--tags uk-zone` selects a real test rather than passing on an empty set | `TZ=Europe/London fvm flutter test --tags uk-zone` reports one file, not "No tests ran" |
| The local mirror of CI runs cheapest-failure-first | `make check` — sub-second validators, then `format`, then `analyze` |
| A pull request shows a green `gate` **and** a green `test` job | the PR's Checks tab; `libsqlite3-dev` appears in the `test` job log |
| The reviewer is asked the five §12 questions before they read a line of the diff | open any PR; the template pre-fills the body |

## The pull request, concretely

One branch, one pull request, seven commits, then delete the branch. Nothing about this epic is
allowed to start before N00's PR is merged and `main` is green (`00-PLAN-CRITIQUE` §10, *"One PR per
epic"*).

1. **Cut the branch from the merged `main`.**

   ```bash
   git switch main && git pull --ff-only
   git switch -c epic/n01-tree-configs-ci
   ```

2. **One commit per task, in task order**, each message in the project vocabulary
   (`CONVENTIONS §5`; no `draft`, no `save()`, no `sync`, no `Error` as a failure name). Each task
   file names its own subject line. There is no exception in this epic: none of the four stated
   exceptions in `00-README` §7.4 applies — no toolchain bump, no golden re-baseline, no `[exempt]`
   line, no schema change.

3. **Push and open the pull request** after the first commit, not after the last. Before N01-T06
   merges there is no workflow file, so the first pushes have **no checks at all** — that is
   expected and it is why T06 exists. From T06 onward every push runs the two jobs.

   ```bash
   git push -u origin epic/n01-tree-configs-ci
   gh pr create --web
   ```

   **Never `gh pr create --fill`** — it takes the body from the commit messages and skips the
   template entirely, which defeats the whole of N01-T07.

4. **Wait for the pipelines.** Two jobs run for this epic and no others: `codegen` arrives in N08,
   `android` in N31, `goldens` only on a tag or manual dispatch (13 §4.2).

   | Job | Runner | What it proves for *this* epic |
   |---|---|---|
   | `gate` | `ubuntu-latest` | `.fvmrc` and the workflow's `FLUTTER_VERSION` agree, so a green CI is not building a toolchain nobody has locally (13 §1.1) · `flutter pub get` still resolves, which is decision #5's evidence · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` — this is N01-T02's strict block actually executing · `ios/Runner/Info.plist` carries no `NSAppTransportSecurity`, which is the half of G5 a text check can do |
   | `test` | `ubuntu-latest` **+ `libsqlite3-dev`** | the host has an sqlite3 for `flutter test` to run against — 12 §3.2 calls this *"the one line between a working and a red CI on day one"* · the whole suite under randomised ordering · `TZ=Europe/London --tags uk-zone`, **unscoped**, which is where N01-T04's canary runs · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`, proving the suite is not accidentally London-only · coverage uploaded as an artefact and never gated (#119) |

   `gate` runs `dart tool/check_policy.dart` as its cheapest step — see the risk table below;
   that script arrives in N03 and this epic must decide, once, what the step does until then.

5. **Answer the five §12 questions in the PR body.** After N01-T07 the template pre-fills them. For
   the commits that land before T07, paste them from `CODE-REVIEW-CHECKLIST` §2 by hand — the point
   of the template is that nobody has to remember, not that the questions start being asked later.

6. **Review the diff in irreversibility order** (`CODE-REVIEW-CHECKLIST` §3.1). For this epic that
   is: `.gitignore` and the four configs first, then the workflow, then everything else. `.gitignore`
   is the never-wave-through file of this epic for the reason in the risk table.

7. **Merge, then delete the branch, then confirm `main` is green.** Only then cut
   `epic/n02-g0-merged-manifest`. N02 needs the `android/` folder and `in_app_purchase` in the
   pubspec, both of which already exist, and it needs a `main` whose `gate` job runs.

   ```bash
   gh pr merge --squash --delete-branch
   git switch main && git pull --ff-only
   gh run list --branch main --limit 1
   ```

## Risks, and what is irreversible here

**Nothing in this epic touches the schema, and nothing here is irreversible in the migration sense.**
The freeze point is N07. What *is* unrecoverable here is a loss, not a change:

| Risk | Why it bites | Where it is held |
|---|---|---|
| **`.gitignore` silently un-commits an artefact whose loss is permanent.** `drift_schemas/drift_schema_v<N>.json` is the migration tests' only baseline and `00-README` §7.1 says losing it is unrecoverable. `pubspec.lock`, `lib/l10n/app_localizations*.dart`, `test/drift/generated/**`, `test/features/goldens/*.png` and `test/fixtures/*.json` are all generated-looking files that **must** be committed. A single over-broad ignore line drops them from every future commit and the loss is invisible until somebody clones the repository months later | N01-T01. The anchor test asserts both directions — the ignore list *and* the committed list — and this is the one file in the epic that is never waved through |
| **`build.yaml` freezes a decision that expires at N07.** `store_date_time_values_as_text` must be absent and stay absent; setting it is irreversible after the first snapshot and it forces one representation onto instants and civil dates, which are different kinds (decision #29) | N01-T03 writes the file without it; N03's gate greps for the key; N07 is where the mistake would become permanent |
| **The two CI job names become the required-status-check names.** Once branch protection requires `gate` and `test`, renaming a job in `ci.yml` silently un-requires it and the PR goes green on nothing | N01-T06. Fix the two names now and never rename them |
| **`make check` calls a script that does not exist until N03.** `tool/check_policy.dart` is N03-T01's, and N03-T01's own first failing test is red *because* `make check` calls a script that is not there. Left undecided, `main` is red for a whole epic — which `00-PLAN-CRITIQUE` §10 forbids outright | N01-T05 must choose and state its resolution; the task file names both options and recommends one |
| **A test tag declared with nothing carrying it.** 12 §11.2: *"the tags must be declared here or a `--tags` filter silently matches nothing and the run is green because it ran nothing."* The `test` job's second step is `TZ=Europe/London --tags uk-zone`; with no tagged test in the tree it passes vacuously for the eleven epics before the first DST test is written | N01-T04 lands one tagged canary in `test/domain/uk_zone/`; N01-T06 asserts the step does not report "No tests ran" |
| **`flutter test` may not accept `-P`.** 12 §11.2 states flatly that `-P` / `--preset` is not in `flutter test`'s pass-through list and that 13 §1.3 and §4.3 are wrong as published; 12 §14 edit 1 makes it a day-one check whose answer decides which of the two documents changes | N01-T04 runs the check and records the answer; N01-T05 and N01-T06 spell the filters whichever way it came out, identically |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `git status` on a fresh clone is clean, and `pubspec.lock`, `lib/l10n/app_localizations*.dart` and every path in `00-README` §7.1 are present in it
- [ ] the two day-one checks 12 §11.2 requires are run and their answers written into that section — whether `flutter test` accepts `-P`, and whether `allow_test_randomization: false` takes effect on the `migration` tag
- [ ] the `gate` and `test` job logs have been **read**, not merely observed green
