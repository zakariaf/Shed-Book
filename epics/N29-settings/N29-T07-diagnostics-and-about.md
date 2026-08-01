# N29-T07 — Diagnostics and About

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 7 of 8 |
| **Depends on** | N29-T06 |
| **Commit** | one commit · `feat(settings): diagnostics and About, referenced not re-typed` |

## 1. Why this task exists

The redacted diagnostics log, the `VACUUM INTO` snapshot for support, and About carrying
§12.3's wording and the offline paragraph from N02-T02 — **referenced**, never re-typed. Never *crash
log*, never *telemetry*: there is none.

Two artefacts sit in this section and they carry **opposite** honesty lines. `shedbook.log` is
redacted by a list (decision #124) and `13 §8.5` prints the sentence that is only true because the list
is enforced: *"This file contains no animal records — only app version, device model and error
messages. You can open it and read it before you send it."* The `VACUUM INTO` snapshot beside it is a
copy of the whole database, and `04 §8` says the opposite: *"it contains the user's records, so it is
never shared automatically and never without the user choosing to."* Putting the first sentence above
the second button is the single most damaging defect this task can ship, and no gate catches it.

About is the other half. `Disclaimers.exportFooter` is an `abstract final class` `const` in exactly one
file and Settings is one of its four call sites (`07 §14.5`). The offline paragraph is
`docs/store/offline-honesty.md`'s, authored at **N02-T02**, which said so at the time: *"the About
screen's message is authored at **N29-T07**."* This is that task.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | **§8.3** (the rolling redacted log: `<appSupport>/diagnostics/shedbook.log`, 256 KB cap, one rotation, the crash-path write, the ring buffer before `attachTo`, failures swallowed) · **§8.4** (the redaction list, both columns; *"`SqliteException` messages echo SQL and sometimes bound values"*; `Redact`) · **§8.5** (Settings ▸ Diagnostics, **row by row**, and the honesty sentence) · **§8.6** (*"nothing is ever transmitted"*) · §9.1.1 (`kAppVersion` / `kAppBuild` — **there is no package that supplies them**) | the log, its redaction and the surface |
| `docs/engineering/04-migrations-media-backup-restore.md` | **§8** (`VACUUM INTO`: the SQL, the three reasons it beats the C backup API, *"the file named by the INTO clause must not previously exist"*, and the table row that says the snapshot **contains the user's records**) · §8's vocabulary note (*"the backup"* is JSON; *"the snapshot"* is `VACUUM INTO` — never swap them) | the snapshot |
| `docs/engineering/07-screens.md` | **§14.3 row 10** (Diagnostics: last 20 events, record counts, storage figures, `PRAGMA quick_check`, a **user-initiated** share, *"no automatic prompt to send"*) · **row 12** (About: version, the permitted offline wording, the privacy policy as **static text — no `url_launcher`**, `Disclaimers.exportFooter`) · **§14.5** (§12.3 in About, referenced never re-typed; §12.2 — Diagnostics offers no interpretation; and the Diagnostics honesty line) · §14.2 (Error state: *"Diagnostics stays reachable, because a database read failure is exactly when someone needs it"*) | the two sections |
| `docs/engineering/CONVENTIONS.md` | §2.14 (`Disclaimers`: `exportFooter`, `withdrawalProvenance`, `withdrawalCaveat` — *"referenced, never re-typed"*; `LocalLog.instance` and its five methods) · §2.8 (`diagnostics_snapshot.dart` under `lib/core/db/`) · §4.7 (`copy.disclaimer_retyped`) · **§5.2** (*"the diagnostics log (`LocalLog`)"*, never crash log, telemetry, analytics — *"there is none"*; *"the snapshot"* vs *"the backup"*) · §4.5 + R59 | **BINDING** on the names and the words |
| `docs/engineering/01-architecture.md` | §7 (`LocalLog`, the global error net, *"no Crashlytics, no Sentry, no Bugsnag, no analytics"*) · the `RecoveryScreen`'s three buttons — the same `VACUUM INTO` + share pair, at the other end of the app | the log's shape |
| `docs/engineering/10-accessibility-and-i18n.md` | **§8.7** (what is deliberately **not** in the ARB: `Disclaimers.*`, the six `ShedFailure.userMessage` strings, `RecordedTime.provenanceLabel`, `NightErrorPanel`'s copy; *"adding a seventh exception is a review conversation, not an edit"*) · §8.4 rule 5 · §3.4 (`headingLevel`) | which strings are ARB and which are not |
| `docs/engineering/12-testing.md` | §4.2 (`FakeShareService` — *"a share of a path that does not exist, and any call passing bytes rather than a path"*) · §10 (the product's own promises as tests) | how the share is asserted |
| `docs/research/00-tech-decisions.md` | **#123** (diagnostics with no network) · **#124** (the redaction rules) · #62 (the single disclaimer constant) · #80 (`share_plus`, always a file path) · §3.1 (**the only permitted public offline wording, verbatim**) | the decisions applied |
| `epics/N02-g0-the-merged-manifest-record/N02-T02-…md` | §5.3 (`docs/store/offline-honesty.md`'s outline and the consumer list, which names **N29-T07**) · §5's test (`test/policy/offline_wording_test.dart`) | the paragraph this screen quotes |
| `docs/design/indelible.md` | §8 screen 11 (the printed footer, verbatim) · §7.13 (word button) · §7.16 (page header) | the About block's shape |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | `LocalLog`, its redaction and the snapshot |
| `shed-accessibility-and-copy` | the About wording, §12.3 and the offline paragraph |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'About renders the §12.3 wording and the offline paragraph by reference, and the diagnostics log is redacted'`
- **Why it is red today** — there is no diagnostics surface and no About screen.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen it into three assertions that fail for three different reasons:

1. **By reference, not by copy.** The rendered About text `contains(Disclaimers.exportFooter)` — read
   from the constant at run time, never inlined into the test — and the widget source contains **no**
   string literal matching any sentence of it. `copy.disclaimer_retyped` proves the second half in CI;
   this proves both in the tier that runs first.
2. **The offline paragraph is read, not paraphrased.** Take the quoted block out of
   `docs/store/offline-honesty.md` at run time and assert the rendered text contains it **character for
   character**, the same way `test/policy/offline_wording_test.dart` compares it to decision-record
   §3.1. A copy in the test drifts from the copy in the document and then defends the wrong sentence.
3. **The log is redacted, proved against a forbidden value.** Seed a ewe tagged `412`, a note whose
   body is a distinctive nonsense token, a treatment with a product name and a batch number, and a
   withdrawal of 7 days. Drive an operation that logs. Then assert the log file contains **none** of
   those five values, and that it does contain the timestamp, `kAppVersion`, the device model and the
   route name. Assert the **forbidden column of `13 §8.4`**, not the allowed one — a test that only
   checks what is present passes against a log that also contains everything else.

**Green.** The minimum code that passes, and nothing beyond it — the two surfaces, both referencing `Disclaimers` and the recorded wording.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 3 (a read on the data layer), 6 (UI), 7 (ARB) and 8 (tests).** No schema — nothing is stored.
No domain — `Disclaimers` shipped in N06. **Say both out loud in the commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/log/local_log.dart` | **Edit, only if needed.** `LocalLog` and `Redact` shipped at **N11-T09**. This task **reads** the last 20 records and exposes the two file paths for the share; it does not re-implement the redaction. If `LocalLog` has no read API, adding one is the minimum: `List<String> recentRecords({int limit = 20})` |
| 2 | `lib/core/db/diagnostics_snapshot.dart` | **Edit, only if needed.** `04 §8` prints the function. It lives under `lib/core/db/` because it is the one place a `customStatement(` may run (R1, layer rule 8) |
| 3 | `lib/data/settings_repository.dart` **or** a read on `ExportRepository` | **Edit.** The Diagnostics record counts and storage figures. **Reuse the whole-database count N23-T02 put on `ExportRepository`** — a second count implementation is a second answer to *"how many ewes are on this phone?"* |
| 4 | `lib/features/settings/widgets/diagnostics_section.dart` | **New.** Section 10: records, storage, last 20 events, Check database, Save a copy of the file, Export diagnostics — `13 §8.5`'s rows, in its order |
| 5 | `lib/features/settings/widgets/about_section.dart` | **New.** Section 12: version, the offline paragraph, the privacy policy as **static text**, `Disclaimers.exportFooter` |
| 6 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `runQuickCheck()`, `shareDiagnosticsLog()`, `shareDatabaseSnapshot()`. All three are `guard()`ed; the two shares go through `ShareService` with a **file path**, never bytes |
| 7 | `lib/features/settings/settings_screen.dart` | **Edit.** Slot the two sections in at 10 and 12, and keep Diagnostics **outside** the error panel (`07 §14.2`, the layout decision T01 made) |
| 8 | `lib/l10n/app_en.arb` | **Edit.** Every string except the two that are deliberately not ARB (§5.3). The two honesty lines get `description`s naming the two documents they come from |
| 9 | `test/features/settings_test.dart` | **Edit.** The anchor and the widget cases |
| 10 | `test/policy/diagnostics_log_is_redacted_test.dart` | **New.** The forbidden-value scan. `CONVENTIONS` §4.1: a policy test *"states the property, not the file"* |
| 11 | `test/policy/offline_wording_test.dart` | **Edit.** N02-T02 created it and said N29-T07 would add the About case |
| 12 | `test/data/diagnostics_snapshot_ambiguous_hour_test.dart` | **New.** `@Tags(['uk-zone'])` — the log line's UTC stamp inside the repeated hour |

### 5.2 The signatures and the two honesty lines

```dart
// lib/features/settings/widgets/diagnostics_section.dart
//
// 13 §8.5's six rows, in its order. This is a SUB-SCREEN of Settings, NOT a
// thirteenth route: "RouteNames has thirteen entries and none of them is
// diagnostics".
//
// TWO ARTEFACTS, TWO OPPOSITE HONESTY LINES. Read this before wiring a button:
//
//   settings.diagnostics.export_log   -> shedbook.log + shedbook.1.log
//       13 §8.5: "This file contains no animal records — only app version,
//       device model and error messages. You can open it and read it before
//       you send it."      TRUE, and only because 13 §8.4's list is enforced.
//
//   settings.diagnostics.save_copy    -> VACUUM INTO snapshot of the database
//       04 §8: it "contains the user's records, so it is never shared
//       automatically and never without the user choosing to."
//       The sentence above is FALSE of this file. Its own line says the
//       opposite, and the test asserts the two are not interchangeable.
```

```dart
// lib/features/settings/widgets/about_section.dart
//
// REFERENCED, NEVER RE-TYPED (decision #62, 07 §14.5). Disclaimers is an
// abstract final class of const strings in exactly one file, and Settings is
// one of its four call sites. `copy.disclaimer_retyped` fails the build on a
// second copy of any sentence in it.
Text(Disclaimers.exportFooter)          // NOT an ARB message (10 §8.7)

// The offline paragraph is decision-record §3.1's, verbatim, through
// docs/store/offline-honesty.md (N02-T02). It is the ONLY permitted public
// wording:
//   "Shed Book has no account, no server and no sync. The Android build ships
//    without the internet permission, so the app itself cannot connect to
//    anything. Your records only leave the phone when you deliberately export
//    and share them."
// It IS an ARB message — it is user-facing copy, not a safety constant — and
// its `description` names the document and forbids paraphrase.

// Version: kAppVersion / kAppBuild, compiled in (13 §9.1.1). There is NO
// package in the graph that can supply them: package_info_plus is transitive
// via wakelock_plus, and reading a transitive package from lib/ is exactly the
// unreviewed edge G2 exists to prevent.
Text('$kAppVersion+$kAppBuild')
```

Widget keys, R59 spelling:

```
settings.diagnostics.records          settings.diagnostics.storage
settings.diagnostics.events           settings.diagnostics.check_database
settings.diagnostics.save_copy        settings.diagnostics.export_log
settings.about.version                settings.about.offline
settings.about.privacy                settings.about.disclaimer
```

### 5.3 The details that are easy to get wrong

- **The two honesty lines are not interchangeable, and swapping them is the worst defect in this
  task.** `13 §8.5`'s *"contains no animal records"* is true of `shedbook.log` and **false** of the
  `VACUUM INTO` snapshot. Two ARB messages, two `description`s, two keys, and a test that asserts the
  first string is not reachable from `settings.diagnostics.save_copy`.
- **`VACUUM INTO` is *the snapshot*; JSON is *the backup*. Never swap the words** (`CONVENTIONS` §5.2,
  `04 §8`). *"`VACUUM INTO` is not a backup"* — it is not cross-device, it does not survive a schema
  change, and calling it one in a button label teaches a shepherd to rely on it.
- **`VACUUM INTO` refuses to overwrite an existing non-empty file** (sqlite.org, quoted in `04 §8`).
  Clear any stale output first. It also must **never run inside a transaction**, and its temp output is
  swept at launch (`04`'s DoD).
- **The log is redacted by a list, and the list is the forbidden column** (`13 §8.4`). No tags, no note
  text of any kind, no product names, no batch numbers, **no withdrawal periods** — *"a safety-critical
  number that is nobody else's business"* — no media paths, no file names, nothing containing a sandbox
  UUID, no exception **message**, no row contents, no bound values.
- **The `SQLite` rule is the one that bites.** *"`SqliteException` messages echo SQL and sometimes bound
  values. Log `e.resultCode`, `e.extendedResultCode` and an identifier you assigned to the statement.
  **Never `e.toString()`.**"* `ShedFailure.DatabaseUnreadable(resultCode, extendedResultCode)` exists
  precisely so the two integers travel without the message.
- **Never request the iOS 16+ device-name entitlement** (`13 §8.4`) — a device name is user-identifying.
  Device **model** is on the allowed list; device **name** is not.
- **Nothing is ever transmitted** (`13 §8.6`). No automatic prompt to send, no *"would you like to
  report this?"* after a crash, no upload on Wi-Fi, no deferred queue, no "anonymous usage statistics"
  toggle — *"an off-by-default toggle is still a transmission path, and G1 would fail the moment one
  was wired up."* The only egress is the share sheet, on an explicit tap, with the user choosing the
  destination.
- **The words *telemetry*, *analytics* and *crash log* appear nowhere** (`CONVENTIONS` §5.2: *"the
  diagnostics log (`LocalLog`) — never crash log, telemetry, analytics — **there is none**"*). Not in
  the UI, not in a `description`, not in a variable name, not in the commit message.
- **`PRAGMA quick_check`, behind a button. Never `integrity_check`, never on the launch path**
  (`13 §8.5`, `04 §8`). `integrity_check` is a full-database scan.
- **`kAppVersion` and `kAppBuild` are `String.fromEnvironment` / `int.fromEnvironment` constants**
  (`13 §9.1.1`), defaulting to `'0.0.0'` and `0`. A build without
  `--dart-define=APP_VERSION` / `APP_BUILD` renders `0.0.0+0` in About, and `13`'s DoD says so: *"a
  diagnostics log reading `0.0.0+0` means somebody built without them."* Do not add `package_info_plus`
  as a direct dependency to "fix" it — that is trading a real offline-graph review for a convenience.
- **`Disclaimers.*` is not an ARB message and must not become one** (`10 §8.7`): *"a translator can
  soften or drop an ARB string and the app has no mechanism to notice."* The closed list of non-ARB
  strings is `Disclaimers.*`, the six `ShedFailure.userMessage` strings, `RecordedTime.provenanceLabel`
  and `NightErrorPanel`'s copy. *"Adding a seventh exception is a review conversation, not an edit."*
- **The privacy policy is static text. No `url_launcher`** (`07 §14.3` row 12). `url_launcher` is not
  in the dependency allowlist and a link out of an offline app is a network path the user did not ask
  for. The text lives in `assets/content/` if it is too long to be a UI string (`CONVENTIONS` §1's
  `assets/content/` note), and in the ARB if it is not.
- **Diagnostics stays reachable when the section list is replaced by the error panel** (`07 §14.2`).
  T01 made the layout decision; this task must not undo it by nesting the section inside the panel's
  subtree. *"A database read failure is exactly when someone needs it."*
- **Every share goes through `ShareService` with a file path, never bytes** (decision #80, `12 §4.2`).
  `FakeShareService` trips on both a path that does not exist and a call passing bytes.
- **The diagnostics log's timestamps are UTC ISO-8601 log lines, not event times.** They carry **no**
  provenance label and must not grow one — `07 §14.5`: *"§12.5 does not appear: Settings displays no
  event time."* `13 §8.3`'s record shape is `--- 2026-03-11T02:41:09.118Z [flutter]`, and
  `13 §8`'s own warning applies: **`DateTime.now(` is banned outside `app_clock.dart` and that ban
  applies to the log too** — *"three research notes wrote `DateTime.now()` in this exact snippet and
  all three are wrong."*
- **§12.2 in Diagnostics: it offers no interpretation** (`07 §14.5`). A `quick_check` result is `ok` or
  it is not. No "your database looks healthy", no advice about what to do, no severity colour.
- **The record counts reassure; they do not diagnose** (`13 §8.5`, row 1: *"reassures the user their
  data is there"*). That is the whole reason the row exists, and it is why it comes first.
- **There is no SnackBar** (P2). A `quick_check` result is a line **in the row**; a completed share is
  the system sheet closing.
- **`ContentPolicy` scans ARB messages**, so *"should"*, *"compliance record"*, *"official record"* and
  *"your data never leaves your phone"* are red builds, not review notes. The About section is the most
  likely place in the app for all four.

### 5.4 The full test set

Four files.

`test/features/settings_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'About renders the §12.3 wording and the offline paragraph by reference, and the diagnostics log is redacted'` | **The anchor**, in its three parts |
| `'the disclaimer is referenced and appears as a literal in exactly one file'` | `Disclaimers.exportFooter` read at run time; a source scan finds its sentences only in `lib/domain/policy/disclaimers.dart` |
| `'the offline paragraph matches docs/store/offline-honesty.md character for character'` | Read the document at run time; no inlined copy in the test |
| `'the two diagnostics honesty lines are not interchangeable'` | The *"no animal records"* string is not in the subtree of `settings.diagnostics.save_copy`; the snapshot's own warning is |
| `'the version row renders kAppVersion and kAppBuild'` | `0.0.0+0` under a test build, with the `reason:` naming `13 §9.1.1` |
| `'the privacy policy is static text and no url_launcher import exists'` | Source text over `lib/` and `pubspec.yaml` |
| `'Check database runs quick_check and never integrity_check'` | Source text plus a behaviour case; the result renders as `ok` with no interpretation |
| `'the diagnostics section stays reachable when the section list is in the error state'` | Force `AsyncError`; `settings.section.diagnostics` is still hit-testable (`07 §14.2`) |
| `'a share passes a file path and never bytes'` | `FakeShareService.shared` carries a path that exists; the fake's byte tripwire never fires |
| `'nothing is shared without an explicit tap'` | `FakeShareService.shared` is empty after the screen builds and after a `quick_check` |
| `'the record counts come from the same query the restore confirmation uses'` | Source text: one count implementation, on `ExportRepository` |
| `'no SnackBar is shown for a quick_check or a share'` | P2 |
| `'both sections render without overflow at the smallest device and textScaler 2.0, bold'` | About carries the most prose on the screen after the delete confirmation |

`test/policy/diagnostics_log_is_redacted_test.dart`:

| Case | What it asserts |
|---|---|
| `'the diagnostics log never contains a value from the forbidden column'` | Seeded tag, note token, product name, batch number and withdrawal days — none present. `13 §8.4`'s forbidden column, enumerated |
| `'a SqliteException is logged as two integers and never as its message'` | Force a constraint failure; the log holds `resultCode` and `extendedResultCode`; `e.toString()`'s text is absent |
| `'a stack trace has its sandbox UUID rewritten out'` | `Redact`'s path rewrite, asserted against a container-style path |
| `'the words telemetry, analytics and crash log appear nowhere in lib, assets or the store docs'` | Source text, case-insensitive |
| `'the log is capped at 256 KB with one rotation'` | Write past the cap; `shedbook.log` is under it and `shedbook.1.log` exists; nothing else does |
| `'a failure inside the log is swallowed'` | Point `attachTo` at an unwritable directory; the operation that logs still completes |

`test/policy/offline_wording_test.dart` (appended by this task, per N02-T02):

| Case | What it asserts |
|---|---|
| `'the About screen quotes decision-record §3.1 verbatim and paraphrases nothing'` | The rendered About text against the document, character for character |
| `'no banned phrase reaches About'` | *"your data never leaves your phone"*, *"offline-first"*, unqualified *"a lost phone is lost data"*, *"verified"/"secure"* — case-insensitive, straight and curly apostrophes normalised |

`test/data/diagnostics_snapshot_ambiguous_hour_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)`:

| Case | What it asserts |
|---|---|
| `'a log record written at 01:30 in the repeated hour carries an unambiguous UTC stamp'` | `atFixed` at both candidate instants; the two lines differ, both parse, and both end in `Z` |
| `'the snapshot filename does not collide across the repeated hour'` | Two snapshots taken an hour apart on the clocks-back night produce two files, and `VACUUM INTO`'s must-not-exist rule is honoured for both |
| `'DateTime.now( appears nowhere in the log path'` | Source text over `lib/core/log/`. `13 §8`'s warning, made mechanical |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Offline purity** — the only permitted public wording is decision-record §3.1, verbatim, and this
  screen is where a user reads it. `13 §8.6`: *"the app never sends anything anywhere."* No
  `url_launcher`, no reporting prompt, no toggle.
- **§12.3, at the level *unconstructible*** — `Disclaimers` is a `const` in one file and
  `copy.disclaimer_retyped` fails the build on a second copy. Referencing it is not a style choice.
- **§12.2 — Diagnostics offers no interpretation** (`07 §14.5`). A `quick_check` result is a fact.
- **The two exceptions to the ARB are closed** (`10 §8.7`). Do not add a seventh.

## 7. Definition of Done

- [ ] `'About renders the §12.3 wording and the offline paragraph by reference, and the diagnostics log is redacted'` passes, and was seen to fail first for the stated reason
- [ ] no disclaimer or offline literal in the feature
- [ ] the exported log is redacted
- [ ] the words *telemetry*, *analytics* and *crash log* appear nowhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records that the schema and domain steps are skipped
- [ ] the log's honesty line and the snapshot's honesty line are two distinct ARB messages with two `description`s naming `13 §8.5` and `04 §8`, and a test asserts they are not interchangeable
- [ ] the redaction test asserts the **forbidden** column of `13 §8.4`, seeded with five distinct values
- [ ] a `SqliteException` is logged as `resultCode` + `extendedResultCode`, never as `toString()`
- [ ] `PRAGMA quick_check` is used and `PRAGMA integrity_check` appears nowhere
- [ ] `kAppVersion` / `kAppBuild` are the version source; `package_info_plus` is not a direct dependency
- [ ] the privacy policy is static text and `url_launcher` appears in neither `pubspec.yaml` nor `lib/`
- [ ] every share passes a file path through `ShareService`, and nothing is shared without an explicit tap
- [ ] `DateTime.now(` appears nowhere under `lib/core/log/`
- [ ] `test/data/diagnostics_snapshot_ambiguous_hour_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is reported by `TZ=Europe/London fvm flutter test --tags uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/policy/diagnostics_log_is_redacted_test.dart
fvm flutter test test/policy/offline_wording_test.dart
TZ=Europe/London fvm flutter test test/data/diagnostics_snapshot_ambiguous_hour_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm the new file is counted
make check
make test
```

```bash
grep -rni "telemetry\|analytics\|crash log" lib/ assets/ docs/store/    # expect zero
grep -rn "url_launcher" pubspec.yaml lib/                              # expect zero
grep -rn "integrity_check" lib/                                        # expect zero — quick_check only
grep -rn "package_info_plus" pubspec.yaml                              # expect zero as a DIRECT dep
grep -rn "DateTime.now(" lib/core/log/ lib/features/settings/          # expect zero
grep -rn "toString()" lib/core/log/redaction.dart                      # read every hit by hand
grep -rn "Shed Book has no account" lib/ | wc -l                       # the ARB message, once
grep -rn "SHED BOOK IS A NOTEBOOK" lib/ | wc -l                        # Disclaimers only, once
grep -rn "SnackBar(\|showSnackBar(" lib/features/settings/             # expect zero (P2)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): diagnostics and About, referenced not re-typed`
