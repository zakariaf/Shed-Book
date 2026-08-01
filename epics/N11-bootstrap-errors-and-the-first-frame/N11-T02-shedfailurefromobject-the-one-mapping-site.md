# N11-T02 — `shedFailureFrom(Object)` — the one mapping site

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 2 of 9 |
| **Depends on** | N11-T01 |
| **Commit** | one commit · `feat(data): shedFailureFrom — the one exception mapping site` |

## 1. Why this task exists

The **only** place a `SqliteException` becomes a `ShedFailure`. One function means one
place to add a mapping when a new constraint fires, and one place a reviewer reads to know what the app
can say when a write fails.

It lives in `lib/data/` and not on `ShedFailure` because putting it on the type would drag
`package:sqlite3` into `lib/core/`, which layer rule 8 forbids (R4 — there is **no**
`ShedFailure.from(e, s)`). And it takes **one** positional argument, not `(error, stack)`, because
the only variant that needs a stack captures `StackTrace.current` itself.

The half of this task that will actually bite you is not the switch. It is the **unwrap**:
`drift_flutter` runs SQLite on a background isolate, so every exception the app sees in production
arrives wrapped in a `DriftRemoteException` and a bare `on SqliteException catch (e)` clause **never
matches** (`04 §7`). One `remoteCause` unwrap, at one site, is the whole defence.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §5.1 (the seven-row failure table, with the result code beside each row) · §5.3 (`shedFailureFrom` printed in full, plus the *never log the message* rule and the `_write` helper that calls it) · §5.4 (returned versus thrown; what an `assert` is for) | the function body, its imports, and every result code it switches on |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7 (*"it does not write `on SqliteException catch (e)`"* — the `DriftRemoteException` wrapper, in the document that hit it first) | why the unwrap exists and why a bare catch clause is a silent bug |
| `docs/engineering/03-data-model-and-schema.md` | §5.9 (the two partial unique indexes: `idx_ewe_tag_active`, `idx_lamb_tag_alive`) · §6 (`idx_penocc_one_open`) · §1.3 (the connection and its pragmas, incl. `foreign_keys = ON`) | the constraints that can actually fire, by name |
| `docs/engineering/13-build-ci-release.md` | §8.4 (the redaction list, and the SQLite rule that bites) | log `resultCode` / `extendedResultCode`, never `toString()` |
| `docs/engineering/12-testing.md` | §1.4 (what is a gate and what is a test) · §3.1–§3.2 (`NativeDatabase.memory()`, and the host `libsqlite3-dev` requirement) | where the single-call-site assertion belongs, and how to provoke a real `SqliteException` |
| `docs/engineering/CONVENTIONS.md` | §2.5 (the function signature, verbatim) · §1.1 layer rules 3, 4, 8 · R4, R8 | **BINDING** on the name, the arity and the file |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | exception mapping is its subject, and this is the one site it may happen |
| `shed-drift-schema` | the constraint names being mapped come from the schema, and the isolate that wraps them is drift's |

Two auto-firing skills is the cap. `shed-testing` is not reloaded: provoking a real `SqliteException`
from an in-memory database, and hand-faking the wrapper drift will not produce in-process, are both
written out as runnable shapes in §5.4 — that is the whole of what the skill would have supplied.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/failure_mapping_test.dart`
- **Test** — `'a unique-constraint violation on ewes.tag maps to a named ShedFailure, not to a generic one'`
- **Why it is red today** — nothing maps exceptions; a constraint violation would surface as a raw error string.

```bash
fvm flutter test test/data/failure_mapping_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Seed one active ewe with tag `412`, insert a
second active ewe with the same tag, catch what SQLite throws — it will be a `SqliteException` with
`resultCode` **19** (`SQLITE_CONSTRAINT`) and `extendedResultCode` **2067**
(`SQLITE_CONSTRAINT_UNIQUE`) from `idx_ewe_tag_active` — and assert that `shedFailureFrom(e)` returns
an `UnexpectedFailure` whose `error` is the exception it was handed. **That is the correct mapping
and the test name is still honest**: `UnexpectedFailure` is a *named* variant, not a generic one, and
`01 §5.1` classifies a constraint violation as a **programmer error the user cannot act on**. What
the test must refuse is a raw string, a `dynamic`, an `Error`, or a `DiskFull` invented because
"something about storage went wrong."

**Green.** The minimum code that passes, and nothing beyond it — the function, a case per constraint the schema can raise, and a default that is honest
about being unknown.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8 step 11 is *"`lib/data/failure_mapping.dart` — if a new `SqliteException` shape needs mapping to a
`ShedFailure`"*. This task is that step and only that step: one data-layer file and one test. No
schema (it stores nothing), no domain, no provider, no controller, no widget, no ARB — say so in the
commit message.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/failure_mapping.dart` | **New.** The top-level `ShedFailure shedFailureFrom(Object error)` and nothing else. `lib/data/` is flat (R18) — there is no `lib/data/errors/` |
| 2 | `test/data/failure_mapping_test.dart` | **New. The anchor, written first.** Lives in `test/data/` because it runs against `NativeDatabase.memory()`, which is what `test/data/` is for |
| 3 | `test/policy/one_failure_mapping_site_test.dart` | **New.** The single-call-site property. `12 §11.1`: a policy test is named for the **property**, not the file it tests |

`tool/check_policy.dart` is **not** touched. The single-call-site property here is about a `switch`
over result codes, which no existing rule id covers and which does not deserve a new one — see the
gotchas.

### 5.2 The signature

`CONVENTIONS §2.5` fixes it at one positional argument and `01 §5.3` prints the body:

```dart
// lib/data/failure_mapping.dart
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../core/failure.dart';

ShedFailure shedFailureFrom(Object error) {
  // drift_flutter runs SQLite on a background isolate, so the original error
  // arrives wrapped. Unwrap once, then classify.
  final e = error is DriftRemoteException ? error.remoteCause : error;
  final s = StackTrace.current;   // the signature takes no stack — R4 fixes it at one arg
  return switch (e) {
    SqliteException(:final resultCode, :final extendedResultCode) => switch (resultCode) {
        13 => const DiskFull(),                                         // SQLITE_FULL
        10 => const StorageWriteFailed(),                               // SQLITE_IOERR
        11 || 26 => DatabaseUnreadable(resultCode, extendedResultCode), // CORRUPT / NOTADB
        8 || 3 || 14 => const StorageReadOnly(),                        // READONLY / PERM / CANTOPEN
        _ => UnexpectedFailure(e, s),
      },
    _ => UnexpectedFailure(e, s),
  };
}
```

The five result codes and the two arms are the whole function. `MediaWriteFailed` is **not**
reachable from here — it is a `FileSystemException` from `MediaStore`, mapped at that gateway
(`01 §5.1`'s last row), and adding a `FileSystemException` arm to this function would put media IO
behind a SQLite-shaped door. Leave it out.

### 5.3 The details that are easy to get wrong

- **`on SqliteException catch (e)` never matches in production, and always matches in your test.**
  `drift_flutter`'s background isolate wraps the original in a `DriftRemoteException`; an in-process
  `NativeDatabase.memory()` does not. So a test that only provokes a real exception proves the
  *inner* half of this function and leaves the unwrap — the half that actually runs on a phone —
  untested and passing. Write both: one case that provokes a genuine `SqliteException` from an
  in-memory database, and one that constructs a `DriftRemoteException` by hand around it and asserts
  the same `ShedFailure` comes back.
- **`01 §5.3` promises that "`DriftRemoteException`'s exact wrapper shape is asserted by a test in
  `12-testing.md`". Grep `12-testing.md`: there is no such test.** It is this task's, and it belongs
  in `test/data/failure_mapping_test.dart`. Assert `remoteCause` is the property name and that it
  yields the original object identity — if drift 2.34.2 wraps differently, `01 §5.3` says fix *this
  function*, not its call sites.
- **A constraint violation maps to `UnexpectedFailure`, and that is the design, not a gap.**
  `01 §5.1` classifies `SQLITE_CONSTRAINT` (19) as a programmer error: the user cannot act on it,
  and inventing a user-facing sentence for it would be the app explaining its own bug to a shepherd
  at 3am. There is no `ConstraintViolated` variant and adding one is a `CONVENTIONS §2.5` change.
- **"Loud in debug" is *not* held for a constraint violation by the code as printed, and you should
  say so rather than quietly fix it.** `01 §5.4` says a programmer error "throws in debug via
  `assert`", and `01 §5.3`'s repository helper writes `assert(e is! Error, …)`. But
  `SqliteException` implements **`Exception`**, not `Error`, so that assert does not fire on
  resultCode 19. Do **not** move an assert into `shedFailureFrom` — this function must stay total and
  testable with asserts enabled, which is how `flutter test` runs. Record the finding in the PR body
  and name its owner: the first repository's `_write` helper (N14), where widening the assert to
  cover `SqliteException(resultCode: 19)` costs one clause.
- **`StackTrace.current` is captured inside the function, and that is deliberate.** R4 fixes the
  arity at one argument so there is exactly one call shape everywhere. The stack you get is the
  mapping site's, not the throw site's — which is enough, because the *throw* site is inside SQLite
  and the useful frames are the repository's, immediately above.
- **Never put the exception's message anywhere.** Not in `userMessage`, not in the log, not in a
  `reason:` on an `expect`. SQLite messages echo the failing SQL and sometimes bound values — ewe
  tags, note text, batch numbers. `13 §8.4`'s rule is the one that bites: log `resultCode`,
  `extendedResultCode` and an identifier you control, never `e.toString()`. This is also why
  `DatabaseUnreadable` takes two integers.
- **`package:sqlite3/common.dart`, not `package:sqlite3/sqlite3.dart`.** The `common` library is the
  platform-neutral one; importing the other pulls in `dart:ffi` paths a host test does not need.
  Either way this file is inside `lib/data/`, which is one of the two directories layer rule 8 lets
  `package:sqlite3` live in — the other is `lib/core/db/`.
- **The extended result codes are worth logging and worth *not* switching on.** 2067
  (`SQLITE_CONSTRAINT_UNIQUE`), 1555 (`SQLITE_CONSTRAINT_PRIMARYKEY`), 787
  (`SQLITE_CONSTRAINT_FOREIGNKEY`) all arrive as primary code 19; 3082 (`SQLITE_IOERR_*`) family
  members arrive as 10. Switching on the primary code keeps the arms at five; carrying the extended
  code into `DatabaseUnreadable` is what makes a real report diagnosable later.
- **The single-call-site property is a test, not a gate row, and the reason matters.** `12 §1.4`'s
  rule is *"if the assertion can be made by reading source text, it belongs in
  `tool/check_policy.dart`"* — but the thing being asserted here is that no **other** file switches
  on a SQLite result code, and a regex for that fires on every integer literal near the word
  `resultCode`, including in this file and in its own test. Decision #52 is the worked example of
  exactly that heuristic being rejected. So the assertion is written as a **count-and-name** test:
  `SqliteException` may appear in exactly the files named in a literal list, and that list is two
  entries long today (`lib/data/failure_mapping.dart` and its test). Same property, no false
  positives, and the failure message says which file joined.
- **The layer rules bite one direction and not the other.** `lib/data/` may import `lib/core/`
  (rule 3) so `import '../core/failure.dart'` is legal; `lib/core/` may **not** import `lib/data/`,
  which is why the mapping cannot live beside the type it produces. And rule 4 bans
  `package:flutter/material.dart` in `lib/data/` entirely — if you reach for a `Color` or a
  `BuildContext` while writing a message here, you are in the wrong file.

### 5.4 The full test set

`test/data/failure_mapping_test.dart` — against `NativeDatabase.memory()`, never a mock
(`00-README` §8 step 12). The host needs `libsqlite3-dev`; CI installs it in the `test` job.

| Case | What it asserts |
|---|---|
| `'a unique-constraint violation on ewes.tag maps to a named ShedFailure, not to a generic one'` | **The anchor.** Two active ewes on tag `412` against `idx_ewe_tag_active`; the thrown object is a `SqliteException` with `resultCode` 19 / `extendedResultCode` 2067; `shedFailureFrom` returns an `UnexpectedFailure` carrying that exact object, and returns neither a `String`, a `dynamic`, an `Error`, nor a `DiskFull` |
| `'a DriftRemoteException is unwrapped once and classified by its remoteCause'` | Wrap the same exception in a `DriftRemoteException` by hand and assert the identical result. **The half that only runs in production** — the in-process test database never produces the wrapper |
| `'SQLITE_FULL maps to DiskFull'` | `resultCode` 13 → `DiskFull`. Provoked, or constructed — either is honest here because the code is the whole input |
| `'SQLITE_IOERR maps to StorageWriteFailed and the message does not mention space'` | 10 → `StorageWriteFailed`, and its `userMessage` contains no *out of space*. The one case in this file that is about safety rather than shape |
| `'SQLITE_CORRUPT and SQLITE_NOTADB both map to DatabaseUnreadable and carry both codes'` | 11 and 26 → `DatabaseUnreadable`, `.resultCode` and `.extendedResultCode` preserved exactly |
| `'SQLITE_READONLY, SQLITE_PERM and SQLITE_CANTOPEN all map to StorageReadOnly'` | 8, 3, 14 → one variant. Three codes, one thing the user can do about it |
| `'an unknown SQLite result code maps to UnexpectedFailure and says so'` | An invented code (e.g. 99) → `UnexpectedFailure`; the `userMessage` admits it does not know rather than guessing a cause |
| `'a non-SQLite object maps to UnexpectedFailure without inspecting it'` | `shedFailureFrom(StateError('x'))` and `shedFailureFrom('a bare string')` both return `UnexpectedFailure` carrying the original. The function is **total**: there is no input for which it throws |
| `'no ShedFailure produced here ever renders the exception message'` | For every case above, assert the returned `userMessage` does not contain any substring of `e.toString()` longer than four characters. `13 §8.4`, made mechanical at the one place it can leak |
| `'a foreign-key violation and a partial-index violation are both programmer errors'` | Provoke a real FK failure (`foreign_keys = ON` is on the connection, `03 §1.3`) and a second open occupancy against `idx_penocc_one_open`; both → `UnexpectedFailure`. Documents the classification rather than leaving it to the reader |

`test/policy/one_failure_mapping_site_test.dart`:

| Case | What it asserts |
|---|---|
| `'SqliteException is named in exactly two files and shedFailureFrom is declared once'` | Walks `lib/**/*.dart` and `test/**/*.dart` (skipping `*.g.dart`, `*.drift.dart` and `app_localizations*.dart`), collects every file naming `SqliteException` or `DriftRemoteException`, and compares against a literal two-entry list. The failure message names the file that joined |

**Nothing in this task is time-shaped.** There is no `test/domain/uk_zone/` case and no
`@Tags(['uk-zone'])` here: a result code carries no clock.

## 6. Constraints that bind this task

- **The five safety rules** — §12.5's neighbour: nothing this function returns may name a cause the
  result code does not prove. That is the same honesty rule as "never silently correct an entry",
  pointed at the user instead of at the record.
- **Offline** — no network path may be added. G2 and G3 stay green; `package:drift` and
  `package:sqlite3` are both already direct dependencies on the allowlist, so this file adds nothing
  to `pubspec.yaml`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a unique-constraint violation on ewes.tag maps to a named ShedFailure, not to a generic one'` passes, and was seen to fail first for the stated reason
- [ ] one call site for the mapping, enforced by a policy assertion
- [ ] each mapped constraint names the index or check it came from
- [ ] the unknown case says so rather than guessing
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the signature is `ShedFailure shedFailureFrom(Object error)` — one positional argument, no stack parameter, no `ShedFailure.from` anywhere (R4)
- [ ] the `DriftRemoteException` unwrap has its own test case, constructed by hand, because the in-process test database cannot produce one
- [ ] the function is total: no input makes it throw
- [ ] no returned `userMessage` contains any part of the exception's own message
- [ ] the "loud in debug for `SQLITE_CONSTRAINT`" finding is recorded in the PR body with N14 named as its owner

## 8. Verification

```bash
fvm flutter test test/data/failure_mapping_test.dart
fvm flutter test test/policy/one_failure_mapping_site_test.dart
make check
make test
```

Then confirm the confinement by hand — the property the policy test exists to hold:

```bash
grep -rln "SqliteException\|DriftRemoteException" lib/ test/ \
  --include='*.dart' | grep -v '\.g\.dart' | grep -v '\.drift\.dart'
# expect exactly: lib/data/failure_mapping.dart, test/data/failure_mapping_test.dart,
#                 test/policy/one_failure_mapping_site_test.dart

grep -rn "ShedFailure.from\|shedFailureFrom(" lib/
# expect one declaration and zero other call sites until the first repository lands
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): shedFailureFrom — the one exception mapping site`
