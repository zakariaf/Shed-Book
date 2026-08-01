# N11-T01 — `ShedFailure` and `WriteOutcome`

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 1 of 9 |
| **Depends on** | N10-T08 |
| **Commit** | one commit · `feat(core): ShedFailure and WriteOutcome` |

## 1. Why this task exists

Six failure variants and three write outcomes, all non-generic — **no `Ok`, no `Error`**,
because `Error` is a banned name and a generic result type invites `.fold()` chains nobody reads at
3am.

These two files are the vocabulary of every write in the next twenty epics. `01 §5.1` starts from a
fact most apps do not have: **an app with no network has a small, knowable failure set.** Seven rows,
all of them local storage. Designing to *that* set instead of to a generic one is what makes six
honest sentences possible where a `Result<T>` would have produced one apologetic one.

The split — **reads throw, writes return** — is decision #13 and it is not stylistic. Roughly 100% of
reads succeed, and when one does not there is exactly one sensible response at every call site, so a
`Result<T>` on ~60 read methods would force ~200 `switch` blocks handling a case that never fires.
Writes are different, and not because of errors: a write can be **committed but inconsistent**
(spec §12.4 — "twin" with three lambs attached) or **refused by the free-tier policy** (decision
#91). Neither an exception nor a `bool` can carry those, which is the whole reason `WriteOutcome`
has three variants rather than two.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §5.1 (the seven-row failure table and what each earns) · §5.2 (`WriteOutcome`, printed in full) · §5.3 (`ShedFailure`, printed in full, with four `userMessage` bodies) · §5.4 (returned versus thrown) | every field, every variant, four of the six strings verbatim |
| `docs/engineering/CONVENTIONS.md` | §2.4 (the write path — the canonical shape) · §2.5 (the errors — the canonical shape) · §1.1 layer rules 1, 2, 3, 8 · §5.3 (banned words) · R3, R8, R32, R53 | **BINDING**. `WriteCommitted{flags}`, `WriteCommitted{id}`, `WriteOutcome<T>`, `Ok` and `Error` are named as banned spellings |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.7 (the closed list of user-facing strings that are **not** ARB messages) | why these six sentences are `const` Dart and not `app_en.arb` keys |
| `docs/engineering/13-build-ci-release.md` | §8.4 (the redaction list) | why `DatabaseUnreadable` carries two integers and not a message |
| `docs/research/00-tech-decisions.md` | #13 (`WriteOutcome`) · #54 (warnings are flagged, never fixed) · #91 (the cap refusal is not a failure) · §5 for versions | the three variants, and why the third is not an error |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | the failure taxonomy and the mapping boundary are its subject |
| `shed-conventions` | §2 already names both types and forbids `Error` as a failure name |

`CLAUDE.md` caps auto-firing skills at two per intent. The six user-facing sentences authored here do
**not** go through the ARB — they are `ShedFailure`'s own const strings — so `shed-accessibility-and-copy`
is not reloaded; the six sentences are printed in full in §5.2 and the reason they bypass the ARB is
stated there and held as a constraint in §6.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/failure_test.dart`
- **Test** — `'ShedFailure has six variants, WriteOutcome three, and neither is generic'`
- **Why it is red today** — nothing represents a failure, so the first repository would throw a raw `SqliteException`.

```bash
fvm flutter test test/domain/failure_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Sealed-class exhaustiveness is a *compile-time*
property, so the test proves it the only way a test can: an exhaustive `switch` over each type **with
no `default:` arm**, one arm per variant, returning a distinct sentinel. The day a seventh
`ShedFailure` is added the test file stops compiling, which is the failure mode you want — a runtime
`expect(variants.length, 6)` would pass forever while a new variant fell through a `default:`
somewhere else in the app. Assert non-genericity the same way: declare `final ShedFailure f = const
DiskFull();` and `final WriteOutcome o = const WriteCommitted();` with the types written out, so
`WriteOutcome<T>` cannot be reintroduced without breaking this file.

**Green.** The minimum code that passes, and nothing beyond it — both sealed types, exhaustively switched, with display text on each variant.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8's order is schema → domain → data → wiring → controller → UI → ARB → tests. This task reaches
**exactly one of those layers and the test tier**: two value types in `lib/core/` and their test.
There is **no schema step** (it stores nothing — say so in the commit message, per §8), no domain
file, no repository, no provider, no controller, no widget and **no ARB entry** — the six sentences
are one of `10 §8.7`'s closed exceptions and are deliberately not translatable.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/failure.dart` | **New.** `sealed class ShedFailure` with its one member `String get userMessage`, and the six `final class` variants. Owner is 01; the shape is `CONVENTIONS §2.5`'s |
| 2 | `lib/core/write_outcome.dart` | **New.** `sealed class WriteOutcome` and its three `final class` variants. Imports `failure.dart`, `../domain/validation/warning.dart` (R17 — `lib/domain/consistency.dart` does not exist and is a banned import path) and `../domain/free_tier.dart` |
| 3 | `test/domain/failure_test.dart` | **New. The anchor, written before either file above.** `test/` has no `core/` directory (R57's eight are fixed), so pure-Dart tests for `lib/core/` value types live here |

Nothing else. In particular this task does **not** create `lib/core/write_action.dart` (`WriteState`
and `WriteController` are R72's and land at N12-T04) and does **not** create
`lib/data/failure_mapping.dart` (T02). Splitting them is not tidiness: the mapping names SQLite
types, and layer rule 8 keeps `package:sqlite3` out of `lib/core/` entirely.

### 5.2 The signatures

`lib/core/failure.dart` — `CONVENTIONS §2.5` and `01 §5.3`, which is the authority for the message
bodies it prints:

```dart
// lib/core/failure.dart
sealed class ShedFailure {
  const ShedFailure();

  /// Plain, non-technical, actionable. No stack traces, no SQLite codes, no
  /// blame. This is read at 3am by someone holding a lamb.
  String get userMessage;
}

final class DiskFull extends ShedFailure {
  const DiskFull();
  @override
  String get userMessage =>
      'Your phone is out of space. Nothing was saved. Free some space and try again.';
}

final class DatabaseUnreadable extends ShedFailure {
  const DatabaseUnreadable(this.resultCode, this.extendedResultCode);
  final int resultCode;          // logged, never shown
  final int extendedResultCode;  // logged, never shown
  @override
  String get userMessage =>
      'Shed Book cannot read its records file. Do not delete the app. '
      'Open Settings › Diagnostics to save a copy of what is there.';
}

/// SQLITE_IOERR. The app knows the write did not land and does NOT know why.
final class StorageWriteFailed extends ShedFailure {
  const StorageWriteFailed();
  @override
  String get userMessage =>
      'Shed Book could not write to your phone. Nothing was saved. '
      'Check you have free space, then try again.';
}

final class StorageReadOnly  extends ShedFailure { const StorageReadOnly();  /* … */ }
final class MediaWriteFailed extends ShedFailure { const MediaWriteFailed(); /* … */ }

/// Bugs. R8 fixes the constructor at exactly two positional arguments.
final class UnexpectedFailure extends ShedFailure {
  const UnexpectedFailure(this.error, this.stack);
  final Object error;
  final StackTrace stack;
  @override
  String get userMessage =>
      'Something went wrong and nothing was saved. Try again. '
      'If it keeps happening, open Settings › Diagnostics and save a copy.';
}
```

`lib/core/write_outcome.dart` — `CONVENTIONS §2.4` and `01 §5.2`:

```dart
// lib/core/write_outcome.dart
import '../domain/free_tier.dart';            // RefusalReason
import '../domain/validation/warning.dart';   // Warning  (R17)
import 'failure.dart';

/// Deliberately NOT named Ok/Error: `Error` shadows dart:core's `Error`, which
/// produces confusing analyzer messages the first time you write
/// `catch (e) { if (e is Error) … }`.  NOT generic: there is no WriteOutcome<T>.
sealed class WriteOutcome {
  const WriteOutcome();
}

final class WriteCommitted extends WriteOutcome {
  const WriteCommitted({this.insertedId, this.warnings = const []});
  final int? insertedId;          // raw int, wrapped by the one call site that reads it
  final List<Warning> warnings;   // populated by the CONTROLLER, never a repository (R53)
}

final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.failure);
  final ShedFailure failure;
}

/// Nothing was written, and nothing went wrong. Unreachable from
/// EntryContext.liveEntry, by construction.
final class WriteRefused extends WriteOutcome {
  const WriteRefused(this.reason);
  final RefusalReason reason;
}
```

Two members you will be tempted to add, both banned: a `fold` / `when` / `map` helper on either type
— that is the `.fold()` chain §1 exists to prevent, and every read site in the app is an exhaustive
`switch` — and `==` / `hashCode` on any variant. Nothing compares two outcomes; `WriteState` further
down the chain deliberately has **no** `==` so that two identical outcomes in a row each fire
`ref.listen` and each earn their own haptic and their own receipt (`02 §7`).

### 5.3 The details that are easy to get wrong

- **`warnings`, not `flags`, and the name is load-bearing.** Decision #13 writes the success payload
  as `WriteCommitted{flags}`; R3 overrides it, because the field's type is `List<Warning>` from
  decision #54 and *a field whose name disagrees with its type is a bug waiting to be written*.
  `flags` is on `CONVENTIONS §5.3`'s absolutely-banned list — in prose **and** in code, and in the
  commit message.
- **`insertedId` is a raw `int?` while R33 says a bare `int` never crosses a repository boundary.
  Both are true and the tension is deliberate.** `01 §5.2` states the reason: a second create verb
  would otherwise turn this field into a union of id types, so the field stays untyped and **the one
  call site that reads it wraps it** (`EweId(outcome.insertedId!)`). Do not "fix" it by making it
  `Object?` or by adding a type parameter — `WriteOutcome<T>` is a banned spelling. Note also that
  only the cap-refusable create verbs use it at all: `beginLambing` and `addLamb` return an id and
  **throw** (R32), so they never construct a `WriteCommitted`.
- **`WriteRefused` is not a failure, and rendering it as one is a safety bug rather than a style
  bug.** Sending it through `showFailure` would tell a shepherd their record did not save when
  nothing was ever attempted, and would poison the Diagnostics log with a non-error. It renders as
  the calm static upgrade row (`showCapRow`), never a modal, and never between 22:00 and 06:00.
- **`WriteCommitted.warnings` cannot be populated by a repository, and the type must not make it
  look possible.** `lib/data/**` may not import `lib/domain/validation/**` (rule
  `layer.data_no_validation`, a path-pair ban), so a repository is *structurally* incapable of
  producing a `Warning`. The field lives on the outcome anyway so that the outcome and its warnings
  travel together through `WriteDone` and `ref.listen` to `confirmSaved`. Repositories return
  `const WriteCommitted()` and let the default empty list stand.
- **The transitive-import question, answered once so nobody re-opens it.** `lib/data/` imports
  `lib/core/write_outcome.dart`, which imports `lib/domain/validation/warning.dart` — so the
  `Warning` *type* is visible inside a repository. That is not a violation: the rule is an
  import-path rule over source text, and R53's mechanism is that a repository cannot reach the
  *validators* that construct one. Visibility of the type is what lets a repository name the field;
  inability to import `lambing_checks.dart` is what stops it filling the field in.
- **`const UnexpectedFailure(...)` is a const constructor you will never invoke as const.** A
  `StackTrace` is not a compile-time constant, so every construction is a runtime one. Keep the
  `const` anyway: it costs nothing, and it keeps all six variants uniform, which is what makes the
  exhaustive switch in the test read cleanly.
- **`StorageWriteFailed` must not say "you are out of space."** `SQLITE_IOERR` (10) means the app
  knows the write did not land and does **not** know why. Naming a cause the result code does not
  prove is the same class of error safety rule §12.4 exists to prevent, aimed at the user instead of
  at the record. `01 §5.3` carries that comment; keep it in the file.
- **`DatabaseUnreadable` carries two integers because it must never carry a message.**
  `SqliteException`'s message echoes the failing SQL and sometimes bound values — ewe tags, note
  text, batch numbers (`13 §8.4`). The two ints exist precisely so the diagnostics log has something
  to write that is on the allowed list. Neither is ever shown to a user, and the getter must not
  interpolate them.
- **These six strings are scanned by the gate, and by one rule you may not expect.**
  `copy.vet_advice` is scoped to `lib/` and `assets/`, so `lib/core/failure.dart` **is** in scope: a
  message containing a dose, a clinical recommendation or the word *should* fails the build.
  `copy.literal_text`, by contrast, stops at `lib/features/`, so nothing mechanical stops you adding
  a seventh literal here — `10 §8.7`'s exception list is closed and adding to it is a review
  conversation.
- **British English, and the app's own vocabulary.** *records*, never *data* or *entries*;
  *Settings › Diagnostics* with that separator, matching the one place a user can act on the advice.
  Never *crash log*. Never *sync*. Never *try again later* — there is no later, the shepherd is
  holding a lamb now.
- **`ShedFailure` gets no `from` constructor, ever.** R4: there is no `ShedFailure.from(e, s)`. Any
  factory that touches SQLite drags `package:sqlite3` into `lib/core/`, which layer rule 8 forbids
  outright. The mapping is a top-level function in `lib/data/` and it is T02.

### 5.4 The full test set

`test/domain/failure_test.dart` — pure Dart. No `TestWidgetsFlutterBinding`, no database, no
`ProviderScope`, no `pumpWidget`.

| Case | What it asserts |
|---|---|
| `'ShedFailure has six variants, WriteOutcome three, and neither is generic'` | **The anchor.** Two exhaustive `switch` expressions with **no `default:`**, one arm per variant, over locals declared with the supertype written out. Compiles today, stops compiling the day a variant is added |
| `'no variant is named Ok or Error and no type is generic'` | Reads both files as text and asserts no declaration matches `class (Ok\|Error)\b`, and that neither `WriteOutcome` nor `ShedFailure` is followed by `<` in a declaration. Cheap, and it catches the rename a refactor tool would happily perform |
| `'every userMessage is a non-empty sentence a shepherd could act on'` | Six variants, each: non-empty, ends in `.`, contains no `Exception`, no `null`, no stack-frame marker `#0`, no bare integer that could be a SQLite code, and none of `CONVENTIONS §5.3`'s banned words — including **`should`** |
| `'StorageWriteFailed does not claim the phone is out of space'` | The `SQLITE_IOERR` message must not contain *out of space*; only `DiskFull` may say it. The one assertion in this file that is about safety rather than shape |
| `'DatabaseUnreadable never renders its result codes'` | `DatabaseUnreadable(11, 26).userMessage` contains neither `11` nor `26`. The codes exist for the log |
| `'four variants are const-constructible from nothing'` | `DiskFull`, `StorageWriteFailed`, `StorageReadOnly` and `MediaWriteFailed` in a `const` context. `DatabaseUnreadable` and `UnexpectedFailure` are excluded, and the reason is in the neighbouring case names |
| `'WriteCommitted defaults to no inserted id and no warnings'` | `const WriteCommitted().insertedId` is null, `.warnings` is empty, and two default instances share the same canonicalised `const []` |
| `'WriteCommitted carries warnings without acting on them'` | Construct with two `Warning`s; assert both survive, in order, and that the class exposes no method that could remove, fix or reorder one. §12.4 as a type-level property: `Warning` holds no writer and `WriteCommitted` holds no `fix()` |
| `'WriteRefused carries a RefusalReason and is not a WriteFailed'` | `WriteRefused(RefusalReason.eweCap) is! WriteFailed`, and `RefusalReason.values` is exactly `[secondSeason, eweCap]` |
| `'neither file imports drift, sqlite3, flutter or riverpod'` | Source-text: both files import nothing beyond `dart:`, a sibling in `lib/core/`, and `lib/domain/`. Layer rule 8, proved here as well as by the gate — because this is the file somebody will "just add a `SqliteException` case" to |

**Nothing in this task is time-shaped**, so there is no `test/domain/uk_zone/` case and no
`@Tags(['uk-zone'])` here. The first time-shaped file in this epic is T05's `ResumePolicy`, and its
ambiguous-hour case is written there.

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 lands here structurally: `WriteCommitted` can carry warnings and
  has no way to act on them, and `Warning` holds no writer and no `fix()`. A rule that drops to
  merely *documented* has been deleted, whatever the prose says.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan)
  stay green; these two files add no dependency at all.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedFailure has six variants, WriteOutcome three, and neither is generic'` passes, and was seen to fail first for the stated reason
- [ ] neither type is generic
- [ ] no variant is named `Error` or `Ok`
- [ ] every variant has text a shepherd could act on
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the field is `warnings`, not `flags`; `insertedId` is `int?`; there is no `WriteOutcome<T>`, no `fold`, no `when`, no `map` and no `==` on any variant
- [ ] `UnexpectedFailure`'s constructor is exactly `(Object error, StackTrace stack)` (R8)
- [ ] neither file imports `package:drift`, `package:sqlite3`, `package:flutter` or any riverpod
- [ ] `StorageWriteFailed` names no cause the result code does not prove
- [ ] the commit message names the `00-README` §8 layers this task skipped and why

## 8. Verification

```bash
fvm flutter test test/domain/failure_test.dart
make check
make test
```

Then confirm by hand what the types are supposed to make impossible:

```bash
grep -rn "class Ok\b\|class Error\b\|WriteOutcome<\|ShedFailure<" lib/
# expect zero hits

grep -rn "flags" lib/core/ test/domain/failure_test.dart
# expect zero hits — the field is `warnings`

grep -n "^import " lib/core/failure.dart lib/core/write_outcome.dart
# expect three lines in total, all of them lib/domain/ or a sibling in lib/core/
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(core): ShedFailure and WriteOutcome`
