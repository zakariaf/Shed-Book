# N25 — Reminders screen

| | |
|---|---|
| **`00-README` §9 step** | 9 (2 of 2) |
| **Ships in** | `v1.1.0` |
| **Depends on** | N24 |
| **Size** | M |
| **Was** | E21, closer task deleted |
| **Branch** | `epic/n25-reminders-screen` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Due today, overdue, upcoming — and the screen that tells the truth about the gap between the
app's list and the phone's.

N24 built the durable half: `reminders` rows written inside the lambing and treatment transactions,
`ReminderBudget.forPlatform()`, `NotificationScheduler`, the eight channels, `ReminderReconciler.reconcile()`
and the two regenerated fixtures. **Nothing in N24 renders.** This epic is the only place a shepherd can
see what the app knows, and the only place the app admits what the OS will not hold.

## Release scope — P15

**`v1.1.0`, with N24.** Nothing in N24 renders and nothing here exists without it, so the pair moves
together; the reasoning is in [N24's release-scope section](../N24-reminders-rows-reconcile-and-the-fixtures/epic.md).

Two things this epic owes the split:

- **`kPumpableVariants` gains its Reminders entry here, not in N33.** `v1.0.0`'s overflow matrix is
  **eleven** variants, not fourteen (N33-T01), and the membership test is derived from the built
  screens precisely so a half-landed screen fails loudly rather than quietly.
- **T05's `reminder_rules` is user-configurable interval editing**, which is the half of spec §7.10
  that N29-T03 does not cover. Both land in `v1.1.0`; neither is cut.

## Why it sits here — `00-README` §9's reasoning, not re-derived

§9 step 9 reads: *"Reminders: the rows, `ReminderReconciler.reconcile()`, the channels, the honest windowed
line — depends on writes from steps 5–7 existing to reconcile from, and on the permission being requested at
the first reminder rather than at launch."*

Three consequences, all of them structural rather than stylistic:

1. **It cannot be earlier.** A Reminders screen before steps 5–7 has nothing to list: reminder rows are
   created only inside `LambingRepository`'s and `TreatmentRepository`'s transactions (decision #63), so
   Quick Entry (step 5), the 3am path (step 6) and Treatments (step 7) must all be writing before this
   screen has a populated state to pump. `00-PLAN-CRITIQUE` **S10** is exactly this failure caught late:
   `flock_400_3seasons.json` was generated one epic before reminder rows had a writer, so the matrix would
   have pumped the *empty* state of a populated screen forever. N24-T08 regenerated both fixtures; N25-T06
   is where that regeneration finally pays.
2. **It cannot be later.** §11.5 narrows decision #65: the notification permission is **never** requested
   from a write path — only from an explicit tap on *"Turn on alerts"* on this screen or in Settings.
   Until this screen exists there is no sanctioned way for a shepherd to grant alerts at all, and every
   reminder written in steps 5–7 is stored and never projected.
3. **It is presentation over settled machinery**, in the same sense step 7 is. `ReminderBudget`,
   `reconcile()`, the projection query and the honest column `app_settings.last_reconcile_scheduled` all
   exist. This epic writes one `customSelect`, one screen, two write verbs and the copy — and the copy is
   the risky part, because §12.2 binds hardest on a string nobody reviews.

## What is observably true when this epic merges

Run it, see it, demo it:

```bash
fvm flutter test test/features/reminders_test.dart test/features/reminders_dst_test.dart
fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'reminders'
make check && make test
```

- **The screen exists and is routable.** `RemindersScreen` renders three `headingLevel: 2` groups —
  Overdue, Due today, Upcoming (10 §3.4's table) — from **one** drift statement, with the day boundaries
  bound from `minuteTickProvider`. Leave it open across local midnight and a row moves group without a
  second ticker and without a rebuild storm.
- **The honest line reads both numbers from data.** Pumped against the regenerated
  `flock_400_3seasons.json`, it reads *"Showing the next 200 reminders on your lock screen. All 312 are
  stored in the app."* on a host test run — 200 because `ReminderBudget.forPlatform()` returns the Android
  bound off-device, which is the point: **the number is a call, never a literal.**
  `test/policy/reminder_budget_is_never_a_literal_test.dart` proves no `56` and no `200` appears in
  `lib/features/reminders/` or in `lib/l10n/app_en.arb`.
- **Completing a colostrum reminder writes the domain fact.** One transaction stamps
  `reminders.completed_at` and inserts the `care_events` row; the Ewe Card timeline shows it on the next
  frame, because drift re-runs every statement that reads `care_events`.
- **Mute is a strike.** The row stays on screen, struck, at the foot of its bucket, carrying `MUTED 03:44`
  — and it drops out of `schedulable_total` and out of the next projection. Nothing is deleted.
- **Intervals are rows.** Changing the colostrum interval rewrites one `reminder_rules` row and
  re-reconciles exactly once; `grep -rn 'Duration(hours:' lib/features/reminders/` returns nothing.
- **`reminders` is the matrix's ninth variant**, pumping clean at 3 devices × 3 text scales × 2 bold
  states, and its empty state names both sources it comes from.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §11 | the screen: the query, the three-state honest line, the states, the tap costs, §11.5's permission rule |
| `docs/engineering/07-screens.md` | §17 | the reconciliation rule the line states, and the five rules it must obey |
| `docs/engineering/07-screens.md` | §1.2, §2.2, §15 | the one-query rule, the empty-state copy verbatim, undo-per-verb |
| `docs/engineering/08-platform-integration.md` | §2.4, §2.11, §2.13 | `reconcile()`'s eligibility predicates, the DST classes, the two facts that make the line honest |
| `docs/engineering/03-data-model-and-schema.md` | §5.6, §5.10, §5.13 | `care_events`, `reminders`, `reminder_rules`, `last_reconcile_scheduled` |
| `docs/engineering/CONVENTIONS.md` | §2.14, §3.1–§3.4, §4.5, R40, R49, R50, R51 | every name this epic writes |
| `docs/engineering/12-testing.md` | §5, §6, §7.4 | `pumpApp`, `kPumpableVariants`, the four files that iterate it |
| `docs/design/indelible.md` | Screen 9, §"Rule 1", the strike spec | the strike, the stamp, the double rule marked `NOT YET WRITTEN` |
| `shed-book-spec.md` | §7.6 | due today, overdue, upcoming; all intervals user-configurable; nothing nags twice |

## Tasks

| Task | One line | Depends on |
|---|---|---|
| [N25-T01](N25-T01-remindersprovider-and-remindersview-three-groups-off-the-tic.md) | `remindersProvider` and `RemindersView` — three groups off the ticker | N24-T08 |
| [N25-T02](N25-T02-the-honest-windowed-line.md) | The honest windowed line | N25-T01 · N24-T01 |
| [N25-T03](N25-T03-completing-a-reminder-writes-the-domain-fact.md) | Completing a reminder writes the domain fact | N25-T02 |
| [N25-T04](N25-T04-mute-as-a-strike-and-nothing-that-nags-twice.md) | Mute as a strike, and nothing that nags twice | N25-T03 |
| [N25-T05](N25-T05-reminder-intervals-as-reminder-rules-user-configurable.md) | Reminder intervals as `reminder_rules`, user-configurable | N25-T04 |
| [N25-T06](N25-T06-the-matrix-variant-and-the-empty-state-that-explains-itself.md) | The matrix variant and the empty state that explains itself | N25-T05 |

The chain is strictly linear and each link is load-bearing: T02's line needs T01's `schedulable_total`;
T03's completion needs a row to tap; T04's strike needs the completion path to differ from it; T05's
re-reconcile needs both write verbs to exist so "once per change" is a real assertion; T06 pumps all of it.

## The pull-request workflow, concretely

```bash
# 1. Cut the branch from the merged main N24 left behind.
git switch main && git pull --ff-only
git switch -c epic/n25-reminders-screen

# 2. One commit per task, T01 → T06, each preceded by /simplify then /code-review
#    then /shed-code-review (each task file §9 spells its own commit message).
#    Before every commit:
make check && make test

# 3. /shed-code-review once more over the WHOLE branch, in irreversibility order:
#    lib/l10n/app_en.arb → lib/data/** → lib/features/** → test/**.
#    (No dependency file, no lib/core/db/tables/**, no drift_schemas/ change in this
#    epic — if the diff touches any of them, stop: see "Irreversible" below.)
git diff --stat main...HEAD

# 4. Open the PR and answer the five §12 questions in the body.
git push -u origin epic/n25-reminders-screen
gh pr create --base main --title 'N25 — Reminders screen' --body-file .github/pull_request_template.md

# 5. WAIT for the pipelines. Do not merge on a yellow dot.
gh pr checks --watch

# 6. Merge preserving the six commits, delete the branch.
gh pr merge --rebase --delete-branch

# 7. Confirm main is green before N26's branch is cut from it.
git switch main && git pull --ff-only
gh run list --branch main --limit 1
```

### Which jobs run for this epic, and what each one proves

| Job | Runs | What it proves **for N25 specifically** |
|---|---|---|
| `gate` | every push | `.fvmrc` still pins `3.44.8`; `pub get` resolves with no new dependency (this epic adds none); `tool/check_policy.dart` fires **G2** and **G3** — for this diff that means `layer.features` (no `package:drift` import anywhere under `lib/features/reminders/`), `layer.sibling` (the reminders screen never imports `lib/features/flock/`), `db.reminder_schedule` (the token `schedule(` on a reminder object), `ui.spinner` (a `CircularProgressIndicator` in the frame-1 or empty state), `token.raw_color` and `token.material_color` (the strike line and the `MUTED` stamp must come from `context.tokens`), the gesture rows (`Dismissible` on a reminder row is the obvious wrong way to build mute), `copy.*` on the ARB; then `dart format --set-exit-if-changed` and `flutter analyze --fatal-infos --fatal-warnings` |
| `codegen` | after `gate` | `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/`. **The valuable assertion here is a negative one:** N25 stores nothing new, so `drift_schemas/` must not move. A diff in `drift_schemas/drift_schema_v<N>.json` on this branch means someone added a column after the freeze, and it is a PR-blocking review conversation, not a `make gen` and a commit. It also proves the regenerated `lib/l10n/app_localizations*.dart` is committed and fresh — every string this epic writes goes through `app_en.arb` |
| `test` | after `gate` | `-P ci-fast` with `--test-randomize-ordering-seed random` — randomised order is what catches a reminders test that only passes because an earlier test left `app_settings.last_reconcile_scheduled` set. Then **`TZ=Europe/London flutter test --tags uk-zone`, unscoped** — this is the step that picks up `test/features/reminders_dst_test.dart`; a path-scoped variant would run it under the runner's UTC, where 25 October has no repeated hour and the test passes vacuously (12 §2.5 note 1). Then `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone`, unaffected by this epic. Coverage is an artefact, **never** a gate |

`android` does not run on this branch — it is a `v*`/dispatch job, and this epic touches no manifest.
**Goldens are not a per-PR gate** (decision #116, the 10× macOS multiplier); the Reminders screen is not
one of the eight golden images and this epic adds none.

## Risks specific to this epic

1. **The number 56 leaking into a string.** It is the single most likely defect in the epic and it is
   invisible for a year: a hard-coded 56 renders correctly on iOS and lies on Android. Held by
   `ReminderBudget.forPlatform()` being the only source (R50, 08 §2.13 fact 2) and by a source-scanning
   policy test in T02.
2. **§12.2 in a notification body.** *"Colostrum — your 2 h interval"* is a fact about a setting.
   *"Colostrum is needed within 2 hours"* is veterinary advice. 08 §2.5 says it plainly: this is the copy
   least likely to be reviewed, because nobody reads a string that only ever appears on a lock screen.
   Every ARB message this epic adds gets read against §12.2 in `/shed-code-review`.
3. **The two numbers on the honest line applying different eligibility predicates.** `schedulable_total`
   counts `completed_at IS NULL AND muted = 0`; the projection adds `due_at > :after`. That difference is
   deliberate (08 §2.4) and the two conditions must stay **byte-identical** where they overlap. If they
   drift, the line becomes a lie by arithmetic and the shepherd concludes the app lost rows.
4. **A keepAlive provider pinning the autoDispose ticker.** `remindersProvider` is keepAlive (§3.2) and
   `minuteTickProvider` is `.autoDispose` because "a plain `StreamProvider` stays subscribed for the life
   of the `ProviderScope`, so the loop would keep waking the process every 60 s all night with no pen board
   on screen" (07 §9.2). Measure the subscription lifetime in T01 rather than assuming it.
5. **A fourteenth route.** The obvious way to build T05's interval editor is a new screen with a new
   `RouteNames` entry. `RouteNames` declares **13** and the matrix self-check asserts exactly that
   (`test/features/overflow_matrix_test.dart`, N33-T01). The correct answer is a section on the Reminders
   screen, not a route.
6. **Pumping the empty state and calling it populated.** S10's failure mode. T06 asserts the fixture
   yields a non-zero reminder count *before* it asserts anything about layout.

## Irreversible — say it loudly

**Nothing in this epic writes DDL, and that is the point. Three things here are one-way doors anyway:**

- 🚩 **`reminders.kind` is a closed CHECK and every value is an Android channel id frozen at release**
  (R49, 08 §2.7, 03 §5.10). N24-T03 created the eight channels. **This epic may not add a ninth kind.**
  Adding one is simultaneously a `CHECK` change on a table pointing at the shepherd's records — after the
  N07-T08 freeze, therefore a migration on somebody else's phone in April — and a channel-id change, which
  Android does not let you take back once shipped. If a new kind looks necessary, stop and escalate.
- 🚩 **`reminder_rules` has exactly one numeric column, `offset_minutes`** (03 §5.10). There is no column
  for a time of day. `tag_by`'s 08:00 default (08 §2.11) is therefore **not** user-configurable in v1, and
  building an editor that pretends otherwise means adding a column after the freeze. T05 says no out loud.
- 🚩 **Every ARB message this epic adds is user-facing copy that reaches a lock screen** through
  `buildNotificationCopy` (08 §2.6). It is also what a shepherd reads at 03:00 with no chance to ask a
  question. Copy is cheap to change in a build and expensive to change in a shepherd's memory.

Additionally, `app_settings.last_reconcile_scheduled` is written by `reconcile()` and read by this screen.
It is not a cache and must never be written from `lib/features/` — the moment the screen writes it, the
line stops recording what was projected and starts recording what was hoped for.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `git diff main...HEAD -- drift_schemas/ lib/core/db/tables/ pubspec.yaml pubspec.lock` is **empty**
- [ ] `remindersProvider` is one statement; nothing on this screen combines two drift streams
- [ ] no literal budget number in `lib/features/` or `lib/l10n/app_en.arb`
- [ ] `RouteNames` still declares 13 names; no route was added
- [ ] `reminders` is in `kPumpableVariants` and every matrix cell for it is green
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

## Demoable on merge

The screen states the discrepancy in one honest line with **both numbers read from data**,
never a hard-coded 56.
