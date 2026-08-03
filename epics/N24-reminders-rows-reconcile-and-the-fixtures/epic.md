# N24 — Reminders: rows, reconcile and the fixtures

| | |
|---|---|
| **`00-README` §9 step** | 9 (1 of 2) |
| **Ships in** | `v1.1.0` |
| **Depends on** | N23 |
| **Size** | L |
| **Was** | E20, plus the fixture regeneration the old plan never scheduled |
| **Branch** | `epic/n24-reminders-rows-and-reconcile` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The reminder row is a durable fact written in the **same transaction** as the event; the OS
list is a rebuildable projection of the soonest 56 or 200.

Everything in this epic follows from one sentence in `08 §2.1`: **SQLite is the only truth, the OS
holds a windowed disposable cache, and one idempotent function projects the soonest N.** Apple's
ceiling is 64 pending requests per app and the behaviour above it is *permanently undefined* — three
published descriptions that disagree, and an issue closed `not planned`. A 400-ewe flock in one peak
week produces roughly **500** pending reminders. Fire-and-forget scheduling is not "mostly fine,
occasionally lossy"; it is structurally broken, and it breaks by silently dropping reminders nobody can
see were dropped. In a shed that means a lamb does not get tubed, and there is no screen anywhere that
could have told the shepherd why.

**Nothing in this epic renders.** The Reminders screen is N25. This is the durable half: the budget,
the gateway and its fake, the eight channels, the rows inside the write transactions, the reconciler,
the permissions and receivers, the tap path — and the two fixtures, regenerated now that reminder rows
finally have a writer.

## Release scope — P15

**This epic ships in `v1.1.0`, built February–May 2027 and released on 1 June 2027.**

It is the largest single deferral in the split — fourteen tasks with N25 — and it is deferred for its
risk profile rather than its size. It is the only feature in the backlog whose correctness depends on
undocumented OS behaviour: Apple's ceiling is 64 pending requests and the behaviour above it is
*permanently undefined*, while a 400-ewe flock in one peak week produces roughly 500. Its failure mode
is **silent** — a dropped reminder looks exactly like one that was never due. Shipping that for the
first time, into the first season, three weeks before a freeze during which `13 §11` forbids fixing
it, is the worst-timed thing in the plan.

Three consequences, and each is a reason deferring is *safer* than shipping, not merely cheaper:

- **`v1.0.0` creates no channel**, so #63/#65's *ids are frozen at release* freezes nothing and T03 is
  the first and only place the eight ids are fixed. Getting them wrong later orphans every scheduled
  reminder on every installed device; there is now exactly one chance to get them right, not two.
- **`v1.0.0`'s permission set is strictly smaller.** `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`
  and `SCHEDULE_EXACT_ALARM` arrive with this epic. N31-T01 names them in
  `android/expected_permissions.txt` as the `v1.1.0` delta, so the day G1 goes red the answer is in a
  file. **This epic edits that file and G1 in the same branch.**
- **A lambing recorded in `v1.0.0` gets no reminders.** No rows are written, so there is nothing to
  project. Deliberate: by June 2027 every reminder a February lambing would have raised is months
  past, and writing rows nothing reads is a shape this project uses nowhere else.

Decision-record §7.1 item **17** — *does the free tier cap reminders too?* — expires with this epic
rather than before the first release.

## Why the epic sits here — `00-README` §9's reasoning, not re-derived

§9 step 9 reads:

> *"Reminders: the rows, `ReminderReconciler.reconcile()`, the channels, the honest windowed line.
> Depends on writes from steps 5–7 existing to reconcile **from**, and on the permission being
> requested at the first reminder rather than at launch."*

Both halves of that sentence are structural:

- **It cannot be earlier.** Reminder rows are created *only* inside `LambingRepository`'s and
  `TreatmentRepository`'s transactions (decision #63). Quick Entry's write path (step 5, N14), the rest
  of the 3am path (step 6, N16–N19) and Treatments (step 7, N20) must all be committing before there is
  anything to reconcile. Four of those tasks — N14-T02, N16-T03, N16-T05, N20-T01 — left a comment on
  their transaction boundary naming **N24-T04**, and T04 is where those comments become code.
- **It cannot be earlier for a second reason:** the fixtures. `00-README` §9 step 8 puts restore and the
  seed before this, because `tool/seed.dart` writes through the restore path and the fixtures are what
  make the matrix, the goldens and the at-cap tests possible at all. N23-T05 generated them one epic
  before reminders had a writer, and recorded the consequence rather than papering over it. **T08 is
  the repair**, and it is the only regeneration the plan sanctions.
- **It cannot be later.** Everything downstream that reads a reminder — N25's screen, N33's sweeps and
  goldens — needs both the rows and a populated fixture.

## What is observably true when this epic merges

```bash
fvm flutter test test/domain/reminder_budget_test.dart
fvm flutter test test/data/notification_scheduler_test.dart test/data/notification_channels_test.dart
fvm flutter test test/data/reminder_repository_test.dart test/data/reconcile_test.dart
fvm flutter test test/data/reminder_permissions_test.dart test/features/reminders_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **A 312-reminder flock projects exactly `ReminderBudget.forPlatform()` and drops none of the rest**,
  asserted against `FakeNotificationScheduler`'s recorded calls. The projected ids are the *soonest* by
  `due_at`; the other 312 − N rows are still in SQLite, still listed, still counted. The number 56 is
  never typed — on the test host `forPlatform()` returns 200, and every assertion goes through the call.
- **A lambing and its colostrum reminder commit or roll back together.** Force a failure after the
  reminder insert and both tables are empty. This is decision #63 as a test, and it is the epic's most
  important single assertion.
- **The projection is a rebuild, never a diff.** `fake.calls.first` is `cancelAll` on every run, and
  running `reconcile()` twice past the debounce produces a byte-identical projected set.
- **Two reconciles inside 500 ms produce one projection**, and two concurrent ones await the same
  future. A cold launch that arrives *through a notification tap* fires call sites #1 and #4
  milliseconds apart and still projects once.
- **The eight Android channel ids equal the `reminders.kind` CHECK in the committed
  `drift_schemas/drift_schema_v<N>.json`, byte for byte** — a set comparison against the schema file,
  not against a Dart literal. `turnout`, `dose` and `withdrawal` appear nowhere.
- **A shepherd who only records lambings never sees a system dialog.** Launch, commit a lambing, let
  the reconcile run: `fake.calls` contains no `requestAlerts` and no `requestExactAlarms`.
  `requestAlerts()` ships with **no caller at all** — its two taps are N25's and N29's.
- **Alerts off is a stated condition, not a failure.** `cancelAll()`, `scheduled: 0` recorded, every
  row untouched.
- **A treatment with no withdrawal row produces no `withdrawal_end` reminder.** §12.1, held at the one
  place in the epic where a default could have been invented.
- **`test/fixtures/flock_400_3seasons.json` contains reminders** — all eight kinds, in all three
  buckets, more open unmuted future rows than the budget — and `flock_15_at_cap.json` still holds
  exactly 15 ewes in one season.
- **The ambiguous hour is covered four ways**: DST-6 (a 7-day interval is 168 h, not the civil-day
  form's 167), DST-7 (01:30 on 29 March warns once and projects once), DST-8 (the projected
  `TZDateTime` is the same absolute instant as `due_at`), DST-9 (01:30 on 25 October warns zero times
  and projects once).

What is deliberately **not** true yet: nothing renders, no route helper exists for the Reminders
screen, and the notification tap resolves and reconciles but does not yet push — the push is one
`TODO(N25-T01)` with its reason beside it, the same shape N23 used for its `TODO(N24)`.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§1.1–§1.2** (the gateway rule and `_confinedPackages`) · **§2.1–§2.14** in full — the architecture, the budget, the surface, `reconcile()`, ids and payloads, the copy seam, the eight channels, deferred `POST_NOTIFICATIONS`, the exact-alarm trap, reboot, timezone and DST, the tap, the honest disclosure, the anti-patterns · **§8.2–§8.3** (who asks and when; the final permission set and the manifest block) · §9 (what CI proves) · **§11** (fifteen open items, four of them this epic's) | the whole epic, and every plugin fact that is *not* settled |
| `docs/engineering/03-data-model-and-schema.md` | **§5.10** (`Reminders`, `ReminderRules`, the three `CHECK`s, the six indexes, and *"there is no `os_notification_id` column"*) · §5.13 (`app_settings.last_reconcile_scheduled`) · §5.6 (care events as `EXISTS`) | every column this epic writes |
| `docs/engineering/07-screens.md` | §11.1 (`schedulable_total`'s predicate) · §11.2 (the three lines) · §11.5 (the permission narrowing) · **§17** (the reconciliation rule, the four call sites, and the failure the design removes) | the predicates that must stay byte-identical, and what N25 will read |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree: `lib/domain/reminder_budget.dart`, `lib/data/notification_scheduler.dart`, `lib/data/reminder_reconciler.dart`, `lib/data/reminder_repository.dart`, `lib/features/reminders/`) · §1.1 layer rules 1, 3, 4, 8 and `layer.data_no_validation` · §2.1, §2.12, §2.13, §2.14 · §3.1 · §4.6, §4.7 · §5 · **R29, R40, R48, R49, R50, R51, R56** | **BINDING** on every path, type, provider, column and word |
| `docs/engineering/02-state-di-navigation.md` | §5.4 (override rules) · **§8.1, §8.4** (`Routes.navigatorKey`; navigation from a notification tap) · **§9.1** (the lifecycle observer, printed, including reconcile call site #2) | the two context-free call sites |
| `docs/engineering/12-testing.md` | **§4.1–§4.3** (fakes over mocks; the seven fakes; `FakeNotificationScheduler` printed with its three tripwires) · §5.1–§5.3 (`shedContainer`, seeding, the closed `test/support/` list) · §2.2–§2.4 (time in tests, the ambiguous hour, the two tiers above the domain) · §6.2 (the matrix) · §11.5 (the two fixtures) | every test file in this epic, and the fake every assertion runs through |
| `docs/engineering/01-architecture.md` | §3.2 (the gate's rule tables) · §4.2–§4.3 (event verbs; **never call a gateway inside a transaction**) · §6.3 (the post-frame boot kick) | where the new gate rows go, and the one rule T04 must bend precisely |
| `docs/engineering/13-build-ci-release.md` | §1.2 (`pubspec.lock` is evidence) · §2.2 (**G0**, and why no `tools:node="remove"` line may land here) · §3.1 (`targetSdk 36`, desugaring) · §4.2–§4.3 (the job matrix; the `android` job is **N31's**) | which pipelines run, and which gate does *not* exist yet |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions — `flutter_local_notifications` **22.2.0**, `timezone` **0.11.1**, desugaring **2.1.4** · §5.1 (`flutter_timezone` is required and **unaudited**) · **#63**, #65 (narrowed by §2.8 and R49), #48, #43, #46, #47, #74, #106, #112, #113, #121 | the decisions this epic applies |
| `epics/00-PLAN-CRITIQUE.md` | **S10** (reminders write inside the transactions, and the fixtures predate them) · the E20 restatement of the demo claim · §11.3 (the two anchors) · §11.4 (the skills) | why T08 exists, and why the demo claim names a fake |
| `CLAUDE.md` | offline purity · the 3am floor · the five safety rules · **P2** (there is no SnackBar) · the vocabulary table — *reconcile* never *schedule*/*sync*/*refresh*, *projection* never *queue*/*cache* | the floor, and the two words this epic is most likely to get wrong |
| `shed-book-spec.md` | §5 (zero interruptions; assume the phone dies) · **§7.6** (the reminder kinds, all user-configurable, nothing nags twice) · §4.5 (treatment records are commercially sensitive) · §12.1, §12.2, §12.5 | the product claim reminders exist to hold |

## Tasks

Strictly sequential, and the chain is not an accident: the budget must exist before the fake's tripwire
can read it; the gateway must exist before channels can be installed on it; the channels must exist
before a row can store the title one produced; the rows must exist before there is anything to project;
the projection must exist before a permission state or a DST transition can change it; the reconcile
must exist before a tap can trigger one; and the fixtures cannot contain reminders until reminders have
a writer.

| Task | Depends on | One line |
|---|---|---|
| [N24-T01](N24-T01-reminderbudgetforplatform-56-on-ios-200-on-android.md) | N23-T07 | `ReminderBudget.forPlatform()` — 56 on iOS, 200 on Android |
| [N24-T02](N24-T02-notificationscheduler-the-seam-and-its-fake.md) | N24-T01 | `NotificationScheduler` — the seam and its fake |
| [N24-T03](N24-T03-the-six-android-channels-ids-frozen-at-release.md) | N24-T02 | The Android channels and the copy seam — ids frozen at release. **Eight, not six**: see Risks |
| [N24-T04](N24-T04-reminderrepository-and-rows-written-inside-the-event-transac.md) | N24-T03 · N14-T02 · N20-T01 | `ReminderRepository`, and rows written inside the event transactions |
| [N24-T05](N24-T05-reminderreconcilerreconcile-idempotent-debounced-four-call-s.md) | N24-T04 | `ReminderReconciler.reconcile()` — idempotent, debounced, four call sites |
| [N24-T06](N24-T06-permissions-reboot-and-dst.md) | N24-T05 | Permissions, reboot and DST |
| [N24-T07](N24-T07-handling-a-tap-route-to-the-record-then-re-reconcile.md) | N24-T06 | Handling a tap — route to the record, then re-reconcile |
| [N24-T08](N24-T08-regenerate-and-re-commit-both-fixtures.md) | N24-T07 | Regenerate and re-commit both fixtures |

Three ordering wrinkles, all deliberate:

- **T02 ships the fake in the same commit as the gateway.** N12-T05 landed `shedContainer` with one
  override and named N24 as `FakeNotificationScheduler`'s home. A gateway without its fake is a seam
  nothing can test, and *"an optional parameter that overrides nothing is worse than no parameter"*.
- **T03 lands the copy seam but leaves the boot chain one call long.** `_bootNotifications()` installs
  the copy; T05 appends the first `reconcile()` to the same chain. Each commit compiles and each does
  one thing.
- **T08 is two commits.** The generator must emit reminder rows before a fixture can contain any, and
  `00-README` §7.4 keeps a generated artefact in a commit by itself. The task header says so.

## The pull-request workflow, concretely

```bash
# 1. Cut the branch from the merged main N23 left behind.
git switch main && git pull --ff-only
fvm flutter --version                 # must print 3.44.8 — .fvmrc is the pin
git switch -c epic/n24-reminders-rows-and-reconcile

# 2. Nine commits: one per task, T01 → T08, with T08 as two.
#    Each task file §9 names its own commit message verbatim — use it.
#    Before EVERY commit, in this order: /simplify, then /code-review,
#    then /shed-code-review. Every finding resolved before the commit, not after.
make check && make test               # cheapest failure first, before each one

# 3. /shed-code-review once more over the WHOLE branch, in irreversibility order.
git diff --stat main...HEAD

# 4. Push and open the PR; answer the five §12 questions in the body.
git push -u origin epic/n24-reminders-rows-and-reconcile
gh pr create --base main --title 'N24 — Reminders: rows, reconcile and the fixtures' \
             --body-file .github/pull_request_template.md

# 5. WAIT for the pipelines. Do not merge on a yellow dot.
gh pr checks --watch

# 6. Merge, delete the branch.
gh pr merge --rebase --delete-branch

# 7. Confirm main is green BEFORE N25's branch is cut from it.
git switch main && git pull --ff-only
gh run list --branch main --limit 1
git switch -c epic/n25-reminders-screen
```

**Step 3's order, for this branch specifically** — `00-README` §10 reads a diff by irreversibility, not
by print order:

```
pubspec.yaml + pubspec.lock            (T02: two new dependencies)
tool/policy_allowlist.txt              (T02: the fifth [exempt] line — it deletes a rule forever)
tool/check_policy.dart                 (T02: two confinement rows, four banned-text rows)
android/app/src/main/AndroidManifest.xml + build.gradle.kts + ios/…/AppDelegate.swift  (T06)
test/fixtures/*.json                   (T08: the input to four later epics)
lib/core/db/queries.drift + database.g.dart   (T05)
lib/data/notification_scheduler.dart · reminder_repository.dart · reminder_reconciler.dart
lib/data/lambing_repository.dart · treatment_repository.dart · providers.dart
lib/l10n/app_en.arb                    (T03: eight channel names, and copy that reaches a lock screen)
lib/app.dart · lib/features/reminders/reminder_copy.dart
test/**
```

`android/app/src/main/AndroidManifest.xml` is **never waved through, however small the diff** — see
Irreversible, below.

**Step 4, the five §12 questions, for this epic:**

- **§12.1 — never default a withdrawal period.** A treatment with no `treatment_withdrawals` row
  produces **no** `withdrawal_end` reminder. `WithdrawalNotRecorded` means silence, not a zero-day
  reminder, and T04's test set carries the case.
- **§12.2 — never give veterinary advice.** Eight channel names and every notification title and body
  pass `ContentPolicy`. *"Colostrum — your 2 h interval"* is a fact about a setting the shepherd chose;
  *"Colostrum is needed within 2 hours"* is advice and is banned. This is the copy least likely to be
  reviewed, because nobody re-reads a string that only appears on a lock screen.
- **§12.3 — never a regulatory record.** Nothing in this epic produces an artefact anyone would show an
  inspector; the regenerated fixtures still carry `_disclaimer` as their first key.
- **§12.4 — never silently correct an entry.** A `tag_by` time inside the missing hour raises
  `WarningCode.timeDoesNotExistLocally` and is **shown**, then stored as resolved — never silently moved
  and never refused. The repeated hour raises nothing, deliberately: the displayed time still matches
  what the shepherd typed.
- **§12.5 — timestamps carry provenance.** `reminders` has **no** provenance quad and therefore no edit
  verb, which is the correct shape for a generated row. The provenance a shepherd needs belongs to the
  **event** the reminder came from, and that is what N25 renders.

### Which jobs run for this epic, and what each one proves

| Job | Runs | What it proves **for N24 specifically** |
|---|---|---|
| `gate` | every push | `.fvmrc` still pins 3.44.8; `flutter pub get` resolves **with two new dependencies** — the one job that proves decision-record §5's table still resolves after `flutter_local_notifications` and `timezone` enter it. Then `tool/check_policy.dart` fires **G2 + G3**, and for this diff that means the two new `layer.plugin_*` rows (each plugin imported in exactly one file, which is what makes the fake test the real path), `layer.data_no_material` (the gateway hands up no widget, which is why the copy seam exists), `layer.data_no_validation` (a reminder comes from a rule, never from a warning), `layer.single_writer`, `db.reminder_schedule` (R51 — the token `schedule(` on a reminder object), and the four new `notify.*` rows. Then `dart format --set-exit-if-changed` and `flutter analyze --fatal-infos --fatal-warnings` |
| `codegen` | after `gate` | `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/`. **Two assertions, one positive and one negative.** Positive: T05 adds `soonestPendingReminders` to `lib/core/db/queries.drift`, so `database.g.dart` regenerates and the regeneration must be in the same commit — a stale generated file is invisible locally and lethal on a fresh clone. Negative, and more important: **`drift_schemas/` must not move.** N24 stores nothing new. A snapshot diff on this branch means somebody changed a column to make the reconciler easier — after the N07-T08 freeze, on a table pointing at a shepherd's records. Stop and find out why. T05 §5.3 is the one place this is legitimately at risk |
| `test` | after `gate` | `-P ci-fast` with `--test-randomize-ordering-seed random` — randomisation matters here more than anywhere: `ReminderReconciler` holds `_lastRunAt` and `_inFlight` as instance state, and a test that only passes because a previous test left the debounce window open is exactly the flake that surfaces at 11pm on release day. Then **`TZ=Europe/London flutter test --tags uk-zone`, unscoped over the whole suite** — this is the leg that picks up DST-6, DST-7, DST-8 and DST-9; a path-scoped variant runs them under the runner's UTC, where 29 March has no missing hour and 25 October has no repeated one, and all four pass vacuously. Then `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone`, the hostile whole-hour-offset zone, which T01's pure test rides through unaffected. Coverage is an artefact, **never** a gate |

**The `android` job does not exist yet.** `13 §4.2` lists it as blocking, but the critique's fix #4
places it at **N31-T03**, and N02's epic says so in as many words: *"no job in this epic builds an
`.aab`: the `android` job arrives at N31-T03."* So **G1 does not run on this branch** — and T06 edits
`AndroidManifest.xml`. Read that diff by hand. Goldens do not run either: `v*` or `workflow_dispatch`
only, and none of the eight images is a reminders screen.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- 🚩 **The eight Android channel ids (T03).** A channel id cannot be changed after the first release
  without orphaning every user's per-channel settings, and Android **restores a deleted channel's
  settings if you recreate it with the same id** — so delete-and-recreate is not a repair, it is a
  permanent loss of the shepherd's choices. R49 fixes the list to `03 §5.10`'s eight strings, byte for
  byte. **This task's title, its anchor test name and one DoD line still say "six"** — inherited from
  decision #65, whose list contained three ids (`turnout`, `dose`, `withdrawal`) matching no
  `reminders.kind` value. Build eight. T03 §5.3 carries the ruling and the amendment.
- 🚩 **`android/app/src/main/AndroidManifest.xml` (T06)**, on a branch with **no G1**. Two permissions
  and two receivers, unguarded by any gate in this pipeline. `USE_EXACT_ALARM` in that file is a Play
  **removal**, not a lint warning; `notify.use_exact_alarm` scans `.dart` files only and cannot see
  `android/`. And do **not** add the `tools:node="remove"` line or touch `ACCESS_NETWORK_STATE` — both
  are N31-T01's, gated on G0's recorded evidence.
- 🚩 **`tool/policy_allowlist.txt`'s fifth `[exempt]` line (T02).** `00-README` §7.4: an `[exempt]` line
  *"deletes a rule for one file, forever, silently"*. R56 fixes the section at four on day one; this is
  the only fifth the doc set sanctions, and the reason goes in the commit message that adds it.
- 🚩 **`test/fixtures/*.json` (T08).** From here they are the input to the 252-cell matrix, the
  accessibility gates, the eight goldens, the at-cap monetization tests and the spec §7.7 recall
  assertions. They are also the repo's only standing evidence that an older backup still restores, so
  the `schema` key must not move — T08 §5.3 draws the boundary.
- 🚩 **`lib/l10n/app_en.arb` (T03).** Every string it adds reaches a **lock screen**, read at 03:00 with
  no chance to ask a question. There is no later sweep — N33 only verifies. Copy is cheap to change in
  a build and expensive to change in a shepherd's memory.

**Must not appear in this diff at all:** `drift_schemas/`, `lib/core/db/tables/`,
`lib/core/db/migrations.dart`, `android/expected_permissions.txt`, `ios/*.storekit`, a third file under
`test/fixtures/`.

| Risk | Why it bites here | What holds it |
|---|---|---|
| **Six channels instead of eight** | Decision #65's superseded list survives in this epic's own titles. Ship six and `ring_dock_castrate`, `second_dose` and `custom` reminders land on a channel that cannot be muted separately — or nowhere. Unfixable after release | R49; T03 §5.3's ruling; and the anchor's set comparison against the **committed schema JSON**, which cannot agree with itself |
| **The reminder row written after the event commits** | It is one line simpler, it reads fine, and it is decision #63's exact failure: the phone dies between the two writes and the reminder silently does not exist | T04's anchor forces a failure *after* the reminder insert and asserts both tables empty. The four boundary comments N14/N16/N20 left are the map |
| **A gateway call inside a transaction** | The obvious way to title a reminder is to `await` the scheduler. That holds a write transaction open across a platform-channel hop on the 3am path | `01 §4.3` rule 4, plus the fact that `titleFor`/`bodyFor` are the gateway's only **synchronous** members — T04 §5.3 says why that is not an accident |
| **`reconcile()` called from a repository or inside a write** | It is where the data is, so it is where it looks like it belongs. A 400-ewe treatment batch then takes eleven seconds | T05: call site #3 fires from the **write controller**, after `guard()` returns; a source scan asserts `reconcile(` appears in no `lib/data/*_repository.dart` |
| **Projecting overdue reminders** | On Android `AlarmManager` fires a past trigger **immediately** — twelve overdue rows are twelve pings in one second, on every resume. On iOS a past trigger never fires, so **the bug is Android-only and will not reproduce on an iPhone** | `due_at > :after` in the named query, plus T05's three-overdue-rows case |
| **Caching `canBeExact()`** | It reads as an obvious optimisation: two channel calls per reconcile. The user can revoke *Alarms & reminders* in system Settings while backgrounded, and the stale flag throws `ExactAlarmPermissionException` at 03:00 on the one path with no user in front of it | Asked once per run, cached nowhere; the fake toggles `exactAllowed` mid-test |
| **A literal `56` anywhere** | It renders correctly on iOS and lies on Android, and it is invisible for a year. `forPlatform()` returns **200** on every host this suite runs on, so a test that hard-codes 56 is red on CI and one that hard-codes 200 asserts nothing | R50; T01's single-source rule; every assertion goes through `ReminderBudget.forPlatform()`; N25-T02 adds the tree-wide policy scan |
| **A permission prompt on a write path** | Decision #65 read literally *requires* it, because reminder rows are created automatically. That is a system dialog at 03:24 during the first lambing | The narrowing in `08 §2.8` and `07 §11.5`; T06 ships `requestAlerts()` with **no caller**; the anchor asserts zero permission calls after a committed lambing |
| **`flutter_timezone` added to make `tz.local` work** | `refreshLocalZone()` has no zone source and the fix looks like one line of pubspec. The package is **unaudited** (decision-record §5.1) and release-blocking | G2 goes red on it — *that is the gate working*. The risk is bounded by DST-8: the tz conversion is a rendering, never a shift |
| **A test that fakes time with `Clock.fixed`** | `reconcile()`'s debounce compares `appNow()` against `_lastRunAt`. Under `Clock.fixed` time never moves, so every call after the first returns early and the test measures nothing | Decision #113; drive elapsed time through the binding's advancing clock with `tester.pump`, never `Future.delayed` (banned in tests) |
| **The fixture regenerated for the wrong reason** | N23-T05's rule is *do not regenerate*, and this epic is the exception. Regenerating after a schema bump silently deletes the repo's only proof that an older backup restores | T08 §5.3: check `kSchemaVersion` first, diff the `schema` key, and expect only the reminders, the `counts` block and the checksum to move |
| **The matrix green on an empty Reminders state** | Critique **S10**'s failure mode: an empty list cannot overflow, so 18 cells pass while proving nothing | T08 asserts row counts, all eight kinds and all three buckets **before** N25-T06 asserts any layout |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `flutter_local_notifications` and `package:timezone` are each imported in exactly one file, and `zonedSchedule(` appears in exactly one file
- [ ] the channel-id set equals the `reminders.kind` CHECK in `drift_schemas/`, and it has **eight** members
- [ ] no reminder row is written outside an event's transaction, and a rolled-back event leaves none
- [ ] `reconcile(` appears in exactly four call sites, none under `lib/data/*_repository.dart` and none inside `db.transaction(`
- [ ] no literal `56` or `200` appears in `lib/`, `test/` or `assets/` outside `lib/domain/reminder_budget.dart`
- [ ] a launch plus a committed lambing produces zero permission calls, and `requestAlerts()` has no caller in this epic
- [ ] `USE_EXACT_ALARM` appears nowhere — manifest, Dart, comment or commit message — and both plugin receivers are declared
- [ ] DST-6, DST-7, DST-8 and DST-9 all pass under `TZ=Europe/London`, and each file asserts its own zone in `setUpAll`
- [ ] `drift_schemas/`, `lib/core/db/tables/`, `lib/core/db/migrations.dart` and `android/expected_permissions.txt` are absent from the diff
- [ ] both fixtures are regenerated, committed alone, and `test/fixtures/` still holds exactly two files
- [ ] `CONVENTIONS.md` carries this epic's three amendments — R48's public `scheduleTimeFor`, §4.7's `notify` namespace, and §2.13's `recordProjection`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

A 312-reminder flock projects exactly 56 and drops none of the rest, asserted against
`FakeNotificationScheduler`'s recorded calls — and both fixtures are regenerated now that reminder rows
have a writer.

## Notes

**The branch name.** This epic's header says `epic/n24-reminders-rows-and-reconcile`; N23's epic file
ends by cutting `epic/n24-reminders-rows-reconcile-and-the-fixtures`. **The header above wins** — an
epic owns its own branch name — and N23's closing snippet is corrected in T01's commit. Two spellings
of a branch name produce two branches and one of them is merged.

**Three `CONVENTIONS.md` amendments land inside this epic**, each in the commit that makes the old
wording false (`00-README` §10): R48 (`scheduleTimeFor` is a top-level public function, so DST-8 can
call it — T02); §4.7 gains the `notify` rule-id namespace (T02); §2.13 gains
`SettingsRepository.recordProjection({required int scheduled, required Instant at})` (T05).
`03 §5.13`'s `last_reconcile_scheduled` is amended in T05 too — the column holds a **count**, which is
what R40's name, `07 §11.2` and N25-T02 all require, and its published `InstantConverter` is the defect.

**Four of `08 §11`'s open items are this epic's**, and none may be closed by guessing:
1 (`flutter_timezone` unaudited — **release-blocking**), 2 (whether a wrong `tz.local` can move the
*fired* instant on iOS), 3 (the Darwin resolver's type name after v19), 4
(`getNotificationAppLaunchDetails()`'s shape on 22.2.0). Items 3 and 4 are resolved against the
installed package on the day the code is written; items 1 and 2 go in the PR body and stay open.

**The count in T03's title.** The file is `N24-T03-the-six-android-channels-ids-frozen-at-release.md`
and its anchor is `'the six channel ids match the frozen list exactly'`. Both are kept — the anchor is
cited by `00-PLAN-CRITIQUE` §11.3 and renaming it mid-epic costs more than the inconsistency — and the
correction lives where a red build shows it: in the failure message, in T03 §5.3, and in the row above.
N25's epic already writes *"N24-T03 created the eight channels"*, so the downstream count is right.
