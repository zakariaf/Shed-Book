# N11-T09 — `LocalLog`, redaction and dirty-resume detection

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 9 of 9 |
| **Depends on** | N11-T08 |
| **Commit** | one commit · `feat(core): LocalLog with redaction and dirty-resume detection` |

## 1. Why this task exists

The diagnostics log — never *crash log*, never *telemetry*, because there is none and the
words matter. Redaction of tag numbers and free text, `attachTo` for the error net, `markCleanPause()`
and `session.lock`, so the app can tell the difference between *the shepherd closed it* and *the phone
died mid-write*.

The two handlers `main()` installs see **Dart** errors. They do not see an engine or native crash, an
Android low-memory kill, an iOS jetsam kill, `0xdead10cc`, or the battery dying at 04:10 — and
`13 §7.1` is blunt about it: *"those are precisely the failures that matter for a 3am shed app, and
there is no reporter to catch them because there is no network."* So they are detected by inference:
a marker file that exists while a session is live and is rewritten when the app pauses cleanly.
Present-and-not-clean at the next launch means the previous session died without reaching one.

T03 landed this file's minimum surface so `main()` could compile. This task is the rest of it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §7.1 (what the marker is *for*) · §7.2 (**`session.lock`, its directory layout and its exact JSON**) · §7.3 (`markCleanPause()`, printed) · §7.4 (re-arming, and the blind spot stated plainly) · §7.5 (`attachTo`, printed, with the detection inside it) · §8.1 (why there is no crash reporter at all) · §8.3 (**the rolling log's five properties**) · §8.4 (**the redaction table — allowed and forbidden, column by column**) · §8.5 (Settings ▸ Diagnostics) · §8.6 (nothing is ever transmitted) · §9.1.1 (`kAppVersion` / `kAppBuild`) | every method, every field, every rule |
| `docs/engineering/01-architecture.md` | §5.5 (the log's **whole surface**, the memory-only-then-`attachTo` subtlety, and *"crash-path writes bypass the stream sink entirely"*) · §6.3 (`LocalLog.attachTo(dir)` happens post-frame, right after the directory resolves) | the five methods, and when `attachTo` runs |
| `docs/engineering/02-state-di-navigation.md` | §4.6 (**the one deliberate static**, and why a provider cannot satisfy it) · §9.1 (the `hidden` arm is `markCleanPause()`'s only call site) | why it is a singleton, and who calls it |
| `docs/engineering/08-platform-integration.md` | §1.2 (`_confinedPackages` — **`package:path_provider` is permitted in exactly two files, and `local_log.dart` is not one of them**) | why `attachTo` takes a `Directory` parameter |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/core/log/local_log.dart` + `redaction.dart` in the tree) · §5.2 (**the diagnostics log** — never *crash log*, *telemetry*, *analytics*) · §5.4 (dates a human reads are `d MMM y`; times are 24-hour) · R11, R52 | **BINDING** on the names and the words |
| `docs/research/00-tech-decisions.md` | #123 (no reporter; the cap, the rotation, the sync crash write, `session.lock`) · #124 (**the redaction rules**) · §5 (`logging` 1.3.0, `device_info_plus` 13.2.0) | the decisions this file is |
| `docs/engineering/05-domain-correctness.md` | §7.3 (`ContentPolicy` — the two-way self-test pattern this file's redaction test copies) | how to test a redactor in both directions |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | the log, its attachment to the error net and the resume detection |
| `shed-safety-rules` | redaction is what keeps commercially sensitive records out of a shared log |

Two auto-firing skills is the cap. `shed-testing` is not reloaded: §5.4 writes out the two-way
redaction test (a tag that must never appear, and a tag-shaped string that must survive), the
01:00–01:59 ambiguous-hour case, and the reason a real temp directory beats a fake filesystem for a
file the crash path writes with `writeAsStringSync(flush: true)`.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/local_log_test.dart`
- **Test** — `'a tag number and a free-text note are redacted before they reach the log file'`
- **Why it is red today** — nothing records what happened before a crash, and the first log written would carry a shepherd's records into a shared file.

```bash
fvm flutter test test/data/local_log_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. `attachTo` a temp directory; `write` a record
whose error is a `StateError` carrying the string `ewe 412 — prolapse, called the vet`; read
`shedbook.log` back off disk and assert it contains **`StateError`** and contains **neither** `412`
**nor** `prolapse` **nor** `vet`. Then assert the positive half in the same test: the record does
contain a UTC ISO-8601 timestamp, `kAppVersion`, `kAppBuild` and the last `nav.*` event. A redaction
test that only proves absence passes trivially on an empty file — `05 §7.3`'s two-way pattern is the
one to copy.

**Green.** The minimum code that passes, and nothing beyond it — the log, the redaction, the lock file, and the dirty-resume flag.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

This task reaches `lib/core/` and the test tier. There is **no schema step** — the diagnostics log is
a file, deliberately not a table, because a log that lives in the database cannot record the database
failing to open. Say that in the commit message rather than the bare *"stores nothing"*. No domain,
no repository, no provider (§5.3), no controller, no widget, no ARB.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/data/local_log_test.dart` | **New. The anchor, written first.** `test/data/` because it touches a real filesystem, which is that tier's business |
| 2 | `lib/core/log/redaction.dart` | **New.** `Redact` — the allowed / forbidden field lists as code, plus the message-truncation allowlist and the sandbox-UUID stripper. Its own file so the lists can be read without reading the writer |
| 3 | `lib/core/log/local_log.dart` | **Grown** from T03's minimum. `record`, `attachTo`, `markCleanPause`, the 256 KB cap and one rotation, the crash-path sync write, `kAppVersion` / `kAppBuild`, and `_armSession()` |
| 4 | `lib/core/db/connection.dart` | **Edited, one line.** `openAppDatabase()` calls `LocalLog.instance.attachTo(dir)` immediately after `path_provider` resolves the application-support directory and **before** the drift open — see §5.3 |
| 5 | `test/policy/diagnostics_log_is_redacted_test.dart` | **New.** `13 §8.5`'s promise made mechanical: *"a test in `test/policy/` asserts the log never contains a value drawn from the forbidden column."* Named for the property (`12 §11.1`) |
| 6 | `pubspec.yaml` | **Confirmed, not edited.** `logging` 1.3.0 and `device_info_plus` 13.2.0 are already in decision-record §5's table and on the G2 allowlist. Read the lines; do not bump them |

### 5.2 The signatures

`01 §5.5` fixes the whole surface at five methods (R52) — no more, and no second sink:

```dart
// lib/core/log/local_log.dart
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');
const kAppBuild   = int.fromEnvironment('APP_BUILD', defaultValue: 0);

final class LocalLog {
  LocalLog._();
  static final LocalLog instance = LocalLog._();      // the one static in lib/ (R52)

  void write(String event, Object error, StackTrace stack);
  void flutterError(FlutterErrorDetails details);
  void record(String event);            // structured, no row contents
  Future<void> attachTo(Directory dir); // 13 §7.5 — detection lives inside
  void markCleanPause();                // 13 §7.3 — one call site, 02 §9.1's `hidden` arm
}
```

`13 §7.2`'s on-disk layout and the lock's exact JSON:

```
<appSupport>/diagnostics/
  session.lock      ← one JSON object, every field on #124's allowed list
  shedbook.log      ← current, capped at 256 KB
  shedbook.1.log    ← one rotation
```

```json
{
  "startedAt": "2026-03-11T02:41:07.412Z",
  "appVersion": "1.2.0",
  "build": 187,
  "lastEvent": "nav.lambing_entry",
  "freeBytes": 4831838208,
  "clean": false
}
```

And `13 §8.4`'s two columns, which are the specification for `redaction.dart`:

| Allowed | Forbidden |
|---|---|
| Timestamp (UTC ISO-8601) | Ewe tags |
| App version + build (`kAppVersion` / `kAppBuild`) | Note text, of any kind |
| OS version, device model (`device_info_plus`) | Treatment product names, batch numbers |
| Free bytes, DB size, media size, WAL size | **Withdrawal periods** — a safety-critical number that is nobody else's business |
| Route/operation name (`nav.pen_board`, `restore.begin`) | Media paths, file names, anything containing a sandbox UUID |
| Exception **type** | Exception **message** |
| Stack trace, with sandbox UUIDs rewritten out | Row contents, query parameters, bound values |
| SQLite `resultCode` / `extendedResultCode` + a statement id you control | `SqliteException.toString()` |

### 5.3 The details that are easy to get wrong

- **`local_log.dart` may not import `package:path_provider`, and that is why `attachTo` takes a
  `Directory`.** `08 §1.2`'s `_confinedPackages` permits that package in **exactly two files**:
  `lib/data/media_store.dart` and `lib/core/db/connection.dart` (rule `layer.path_provider`). So the
  log cannot resolve its own home. The call site is `openAppDatabase()`, which has already resolved
  the application-support directory — and R16 explicitly lets `lib/core/db/` import `lib/core/`.
- **Call `attachTo` *before* the drift open, not after.** If the open throws — corruption, a failed
  migration, `SQLITE_CANTOPEN` — that is precisely the event most worth having on disk, and a log
  attached afterwards records nothing about it. One line, and its position in the function is the
  whole value.
- **Application support, never the cache directory.** `13 §7.5`'s anti-pattern list is explicit:
  Android deletes cache under storage pressure, **which would silently convert every crash into a
  clean pause.** Same rule as the database (decision #27).
- **Crash-path writes are `writeAsStringSync(mode: FileMode.append, flush: true)` and bypass
  `package:logging`'s stream entirely.** An `IOSink` write is buffered and may never reach disk
  before the process dies. Synchronous plus flush costs a few milliseconds on a path that is already
  failing. `package:logging` provides the named loggers and the `LogRecord` stream for the *ordinary*
  path only; if the crash path goes through the sink, the log is empty exactly when you need it.
- **Every failure inside the log is swallowed, and that is a rule, not laziness.** `13 §7.3`:
  *"diagnostics must never be the cause of a crash."* Every method is wrapped in `try { … } catch (_)
  {}`. This is also the one place in the codebase where a bare `catch (_) {}` is correct — `01 §5.5`
  lists it as an anti-pattern everywhere else, so put the reason in a comment or a reviewer will
  flag it and be right to.
- **`DateTime.now()` is banned here too, and three research notes wrote it in this exact snippet.**
  `startedAt` is `appNow().utc.toIso8601String()`. `time.dart_clock` allowlists one file and it is
  `lib/core/time/app_clock.dart`. The gate catches it; knowing why saves the round trip.
- **The re-arm blind spot is documented, not fixed.** After a clean pause the app may resume and then
  be killed, so the lock must go back to `clean: false`. The re-arm point is **the first
  `write`/`record`/`flutterError` call after a pause**, guarded by an in-memory boolean so it costs
  one synchronous write per resume rather than one per line. Consequence, stated plainly: *a process
  killed after resume but before any event is recorded is reported as a clean pause.* The window is
  milliseconds in practice. Do not add a second lifecycle call site to close it — `02 §9.1` fixes the
  clean-pause marker to one switch, and adding one there is not this task's to do.
- **A dirty resume is reported and never acted on.** §12.4. `13 §7.5`'s anti-patterns: prompting the
  user about it, counting them, or **making the app behave differently because the last session
  died**. A self-repairing app is an app that hides the bug. One line in the log, surfaced in
  Settings ▸ Diagnostics (N29), and nothing else.
- **Redaction is a list, and the list is `13 §8.4`'s — not a regex you invent.** The rule that bites
  is SQLite: exception **messages** echo SQL and sometimes bound values. Log `resultCode`,
  `extendedResultCode` and a statement identifier you control; never `e.toString()`.
  `DatabaseUnreadable(resultCode, extendedResultCode)` exists precisely so those two integers travel
  without the message.
- **`Redact` truncates to an allowlist of known-safe prefixes and otherwise emits only
  `error.runtimeType`.** That is the direction to get right: the default is *drop*, and safety is
  opt-in per prefix. A denylist of "things that look like a tag" fails the day a note contains one.
- **Stack traces need sandbox UUIDs rewritten out**, and on iOS the container UUID changes on every
  install anyway — so a path with one in it is both identifying and useless. Rewrite, do not drop:
  the frames are the point.
- **`kAppVersion` and `kAppBuild` come from `--dart-define`, and their defaults are deliberately
  wrong-looking.** `0.0.0+0` in a log tells you instantly that somebody built without the defines,
  which is better than a plausible lie. There is **no package that supplies the version**:
  `package_info_plus` is in the graph only transitively (via `wakelock_plus`) and reading a
  transitive package from `lib/` is exactly the unreviewed edge G2 exists to prevent.
- **`LocalLog` is a singleton and stays one.** `02 §4.6` names it as *"the one deliberate static, so
  nobody 'fixes' it"*: the handlers are installed synchronously in `main()`, before any
  `ProviderScope` exists, and they must still work when the container has been torn down by the very
  failure being logged. There is no `localLogProvider`. `_diagnostics` is a banned identifier.
- **The words matter and they are gate-enforced vocabulary.** `CONVENTIONS §5.2`: it is **the
  diagnostics log**. Never *crash log*, never *telemetry*, never *analytics* — *there is none*. In
  code, in comments, in test names, in the commit message.
- **A `session.lock` in a widget test will follow you.** The singleton outlives a test's tear-down,
  so a test that calls `attachTo` must point it at a fresh temp directory and reset the instance's
  state afterwards. `12 §11.3`'s randomised ordering is what will find this: a leaked `_dir` makes an
  unrelated test write into another test's directory, and the failure appears in a file nobody
  touched.

### 5.4 The full test set

`test/data/local_log_test.dart` — a real temp directory per test, torn down with the test. No fake
filesystem: the properties under test are *sync write*, *flush*, *rotation* and *file survives a
process boundary*, and a fake proves none of them.

| Case | What it asserts |
|---|---|
| `'a tag number and a free-text note are redacted before they reach the log file'` | **The anchor**, both directions: the file contains `StateError`, a UTC ISO-8601 timestamp, `kAppVersion`, `kAppBuild` and the last `nav.*` event; and contains none of `412`, `prolapse`, `vet` |
| `'a SqliteException reaches the log as two integers and never as a message'` | `resultCode` and `extendedResultCode` present; no substring of `e.toString()` longer than four characters present. The rule `13 §8.4` says bites |
| `'a withdrawal period never reaches the log'` | `28` in a treatment context is redacted. Called out separately because it is the one forbidden field that is a bare number and looks harmless |
| `'a media path with a sandbox UUID is rewritten, and the stack frames survive'` | The UUID is gone, the frame's function names and line numbers are not. Dropping the frame is the wrong fix |
| `'records written before attachTo are flushed on attach, in order'` | The ring buffer. `main()` installs the handlers; the directory is unknown until post-frame — so anything logged in between must survive and must not reorder |
| `'the ring buffer is bounded and drops oldest first'` | Write more than the buffer holds before attaching; assert the newest survive |
| `'the log rotates at 256 KB and keeps exactly one rotation'` | Write past the cap; `shedbook.log` and `shedbook.1.log` exist, `shedbook.2.log` does not, and the total on disk stays under twice the cap. **The log must never contribute to the disk-full failure it is recording** |
| `'a crash-path write reaches disk without a flush of the stream'` | Written synchronously with `flush: true`; the file has the content immediately after the call returns, with no `await` |
| `'a failure inside the log is swallowed and never propagates'` | `attachTo` a read-only directory, then `write`: no throw, and the app is unaffected. Diagnostics must never be the cause of a crash |
| `'attachTo creates the diagnostics directory on first run'` | It does not exist on a fresh install and `_armSession()` writes into it |
| `'a session.lock left with clean:false is reported on the next attachTo'` | Write a lock with `clean:false`, `attachTo` again, assert one `session.abnormal_termination` record with the prior object in it |
| `'a clean pause is not reported as abnormal'` | The negative. Without it, the previous case passes on an implementation that always reports |
| `'markCleanPause rewrites the lock rather than deleting it'` | `13 §7.3`: the *contents* — free bytes and the last event at the moment of the pause — are what make a report useful |
| `'the lock re-arms on the first record after a pause, and only once'` | Two records after a resume produce **one** synchronous lock write, not two |
| `'a session.lock carries only fields on the allowed list'` | Decode the JSON and assert the key set is exactly the six in `13 §7.2`. A seventh key is how a tag gets into a shared file |
| `'nothing this file writes is ever transmitted'` | Source-text over `lib/core/log/`: no `HttpClient`, no `Socket`, no `Uri.http`, no `dart:io` network import. G3 covers `lib/` broadly; this is the file where it matters most |
| `'the words crash log, telemetry and analytics appear nowhere in lib/core/log/'` | `CONVENTIONS §5.2`, over source **and** comments |

`test/data/uk_zone/local_log_dst_test.dart` — `@Tags(['uk-zone'])`, `TZ=Europe/London`. **This is the
time-shaped half and it is not optional**: every record and the lock carry a timestamp.

| Case | What it asserts |
|---|---|
| `'a session started in the ambiguous hour records an unambiguous UTC instant'` | Start a session at **01:30 on 25 October 2026** — the hour that happens twice — and assert `startedAt` is one of the two candidate UTC instants (`00:30Z` or `01:30Z`) and is `Z`-suffixed. A local-time `startedAt` is ambiguous by exactly one hour on the one night of the year when it is hardest to reason about |
| `'two records an hour apart across the fall-back are an hour apart in the log'` | Write at 01:30 BST and 01:30 GMT; the two `startedAt` values differ by exactly 3,600,000 ms even though the wall clock reads the same. The failure mode is a diagnostics timeline that appears to go backwards |
| `'a dirty-resume line renders its date as d MMM y and its time as 24-hour'` | `CONVENTIONS §5.4` and R60: `11 Mar 2026 02:41`, never `11/03/2026`, never 12-hour. The string N29's Diagnostics screen will print |

`test/policy/diagnostics_log_is_redacted_test.dart`:

| Case | What it asserts |
|---|---|
| `'the log never contains a value drawn from the forbidden column'` | Drive a seeded record — a tag, a note, a product name, a batch number, a withdrawal period, a media path — through `write`, `record` and `flutterError`, and assert none survives. `13 §8.5`'s promise, and what makes the share-button copy *"this file contains no animal records"* true |
| `'Redact is self-tested in both directions'` | `05 §7.3`'s pattern: every forbidden sample is caught, and every allowed sample survives unchanged. A redactor that eats everything passes half a test suite |

## 6. Constraints that bind this task

- **The five safety rules** — two land here, at two different levels. **§12.4**: a dirty resume is
  *reported and never acted on*; the app does not repair itself, does not count them, and does not
  prompt. Held by absence of a writer, not by prose. **§12.5**: every timestamp here is
  machine-captured by `appNow()` and can be nothing else — there is no entry path, no edit path and
  no `RecordedTime` in the diagnostics log, so the Diagnostics screen states that once at the top
  (*"Times below are recorded by the app, not entered by you"*) rather than labelling each line. **A
  diagnostics line must never render a `RecordedTime` from a real record** (`13 §7.5`).
- **Offline** — `13 §8.6`, stated once: **the app never sends anything anywhere.** The only egress is
  the system share sheet, on an explicit user tap, with the user choosing the destination. No
  automatic prompt, no deferred queue, no "anonymous usage statistics" toggle — an off-by-default
  toggle is still a transmission path, and G1 would fail the moment one was wired up.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **And in this file specifically: the diagnostics log, never *crash log*, *telemetry* or *analytics*.**

## 7. Definition of Done

- [ ] `'a tag number and a free-text note are redacted before they reach the log file'` passes, and was seen to fail first for the stated reason
- [ ] tags and free text are redacted
- [ ] the log is bounded and rotates
- [ ] a dirty resume is detectable and is a fact, not a guess
- [ ] the words *crash log*, *telemetry* and *analytics* appear nowhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the surface is exactly the five methods of `01 §5.5` (R52); there is no `localLogProvider` and no second sink
- [ ] `local_log.dart` imports no `package:path_provider`; `attachTo(Directory)` is called from `openAppDatabase()` **before** the drift open
- [ ] the log and `session.lock` live in **application support**, never the cache directory
- [ ] crash-path writes are `writeAsStringSync(mode: FileMode.append, flush: true)` and bypass the stream sink
- [ ] every method swallows its own failures, with the reason in a comment
- [ ] `startedAt` comes from `appNow().utc`, and `DateTime.now(` appears nowhere in this file
- [ ] the re-arm blind spot is stated in a comment where the boolean lives
- [ ] the `uk-zone` file exists and its ambiguous-hour cases pass under `TZ=Europe/London`
- [ ] `test/policy/diagnostics_log_is_redacted_test.dart` exists and tests `Redact` in **both** directions

## 8. Verification

```bash
fvm flutter test test/data/local_log_test.dart
fvm flutter test test/policy/diagnostics_log_is_redacted_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Then confirm the properties a test cannot see, on a device:

```bash
fvm flutter run --debug
# 1. Navigate two screens, then force-stop the app from the OS (not from the IDE).
#    Relaunch. The log must carry one session.abnormal_termination line naming
#    the route, and nothing about it may change how the app behaves.
# 2. Background the app normally, relaunch: no abnormal line.
# 3. Read shedbook.log yourself, end to end. `13 §8.5`'s copy promises a user
#    can do exactly that — "you can open it and read it before you send it" —
#    and that sentence is only true because §8.4's list is enforced. If you
#    would not be comfortable sending your own file to a stranger, the
#    redaction list is wrong, not the copy.
```

And the greps the vocabulary rule turns into build failures:

```bash
grep -rni "crash log\|telemetry\|analytics" lib/ test/ --include='*.dart'
# expect zero hits, including in comments

grep -rn "DateTime.now(\|clock.now()" lib/core/log/
# expect zero hits — appNow() only
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(core): LocalLog with redaction and dirty-resume detection`
