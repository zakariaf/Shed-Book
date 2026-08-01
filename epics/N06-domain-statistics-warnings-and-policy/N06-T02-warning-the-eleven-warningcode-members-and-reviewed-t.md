# N06-T02 — `Warning`, the eleven `WarningCode` members and `Reviewed<T>`

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 2 of 11 |
| **Depends on** | N06-T01 |
| **Commit** | one commit · `feat(domain): Warning, WarningCode and Reviewed<T> — no writer, no fix` |

## 1. Why this task exists

The §12.4 mechanism, at the *unrepresentable* level: `Warning` has **no writer**, no
`fix()`, and nothing to persist into — there is no `warnings` column anywhere in the schema and
`lib/data/` may not import this folder at all. `Reviewed<T>` carries a value together with what is
questionable about it, so a screen cannot render the value without seeing the warning.

The file already exists in part: N05-T05 wrote `checkClearDate` and needed `Warning` and
`WarningCode.clearDateDisagrees` to return. This task completes it — the full eleven-member enum,
`Reviewed<T>`, and the policy test that holds the absences down.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §7.1, §7.5 | the hierarchy of mechanisms, the type shapes, the four structural guarantees, the eleven-row catalogue and its message wording |
| `docs/engineering/CONVENTIONS.md` | §2.6, §5.1, R53, R71 | the exact eleven member names, `warnings` not `flags`, and who populates `WriteCommitted.warnings` |
| `docs/engineering/12-testing.md` | §10, §10.4 | that §12.4 is proved by *the row being unchanged*, not by the warning appearing |
| `docs/engineering/01-architecture.md` | §3.1 rule set, §3.2 | `layer.data_no_validation` — the path-pair ban this task's absence depends on |
| `shed-book-spec.md` | §12.4 | *"If a birth type of 'twin' has three lambs attached, flag it; do not fix it."* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | §12.4 is its rule and this is the mechanism |
| `shed-domain` | the value types and the closed code list |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/warning_has_no_writer_test.dart`
- **Test** — `'Warning has no fix(), no writer and no persistence path'`
- **Why it is red today** — nothing represents a contradiction, so the first validator would either fix it or drop it.

```bash
fvm flutter test test/policy/warning_has_no_writer_test.dart   # expect: failing, for the reason above
```

The assertion is a **source scan over this project's own files**, and it has three clauses. Write all
three now; a test that only checks the first passes for a type that is mutable everywhere else:

```dart
final src = File('lib/domain/validation/warning.dart').readAsStringSync();
expect(src, isNot(matches(RegExp(r'\b(fix|repair|correct|apply)\s*\('))));
expect(src, isNot(contains('corrected')));
final dataImports = dartFilesUnder('lib/data/')
    .where((f) => f.readAsStringSync().contains('domain/validation/'));
expect(dataImports, isEmpty, reason: 'R53: the code that writes cannot reach the code that judges');
```

**Green.** The minimum code that passes, and nothing beyond it — the two types, the eleven codes, and a policy test that reads the source for a
`fix`/`repair`/`correct` member and for any import of this folder from `lib/data/`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

Step 1 of `00-README` §8 is skipped and the commit message says so — **deliberately**, and for once
that is the feature rather than an omission. Guarantee 2 of `05` §7.5 is *the schema has no `warnings`
column*; if this task reached the schema step it would have failed. Steps 3–6 are unreachable by the
same ban. This is step 2 and step 7 only.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/validation/warning.dart` | **Extended** (N05-T05 created it). The full `enum WarningCode` — eleven members in `CONVENTIONS` §2.6's order — plus `final class Reviewed<T>`. `Warning` itself already has its shape; confirm it has gained no field since N05 |
| 2 | `test/policy/warning_has_no_writer_test.dart` | **New.** The anchor: three source-scan clauses, above |
| 3 | `test/domain/validation/warning_test.dart` | **New.** The value-type behaviour: `Reviewed.hasWarnings`, message/`fieldPath` round trips, and the eleven-member freeze |

### 5.2 The signatures

```dart
// lib/domain/validation/warning.dart
/// Advisory only. No fix(), no `corrected` field, no apply(). A Warning cannot
/// mutate anything because it holds nothing mutable and exposes no writer.
final class Warning {
  final WarningCode code;
  final String message;     // what we OBSERVED, never what to do
  final String? fieldPath;  // for scroll-to-field, not for editing
  const Warning(this.code, this.message, {this.fieldPath});
}

enum WarningCode {
  birthTypeLambCountMismatch,
  lambingBeforeSeasonStart,
  lambingInFuture,
  lambingLongBeforeCapture,
  implausibleBirthWeight,
  timeDoesNotExistLocally,
  fosterToSelf,
  deathBeforeBirth,
  duplicateActiveTag,
  clearDateDisagrees,
  localDateDisagrees,
}

/// A value that has been looked at by the validator. Carries the UNCHANGED
/// value plus advisories. There is deliberately no way to get a "cleaned"
/// value out of it.
final class Reviewed<T> {
  final T value;                 // byte-identical to what the user supplied
  final List<Warning> warnings;
  const Reviewed(this.value, this.warnings);
  bool get hasWarnings => warnings.isNotEmpty;
}
```

`WarningCode` has **no** `key` field and no `fromKey`, unlike every other enum in T01. That is on
purpose: a stored key exists so a value can be written to SQLite, and a warning is never written
anywhere. The one place a code becomes a string is the CSV's `warnings` column, which joins the
**enum names** — `05` §7.5's "codes, not localised messages" — and that is `09-export-formats.md`'s
call site, not this file's.

### 5.3 Where the eleven codes are actually raised

Eleven codes, four producers, and **three of them are not in this epic**. Write the table into the
enum's doc comment; the next reader's first question is "who raises this?".

| Code | Raised by | Epic |
|---|---|---|
| `birthTypeLambCountMismatch`, `lambingBeforeSeasonStart`, `lambingInFuture`, `lambingLongBeforeCapture`, `implausibleBirthWeight`, `deathBeforeBirth`, `localDateDisagrees` | `checkLambing` in `lib/domain/validation/lambing_checks.dart` | **N06-T03** |
| `fosterToSelf` | `checkFoster` in `lib/domain/validation/foster_checks.dart` | **N06-T03** |
| `clearDateDisagrees` | `checkClearDate` in `lib/domain/validation/treatment_checks.dart` | N05-T05, already merged |
| `timeDoesNotExistLocally` | `checkLocalWallTimeExists` in `lib/domain/time/wall_time.dart` | N04-T08, already merged |
| `duplicateActiveTag` | **nothing in `CONVENTIONS` §1's tree** — see §5.4 | N26 |

### 5.4 The details that are easy to get wrong

- **`duplicateActiveTag` has no producer file, and you must not invent one.** There is no
  `lib/domain/validation/flock_checks.dart` in `CONVENTIONS` §1's tree, and adding one is a tree
  change that needs a numbered ruling. `07-screens.md` §181 and §208 compute this code **in Dart from
  the same active-tag cache the keypad uses** (`tagIndexProvider`), on the Flock create path, in N26 —
  it is not in any drift statement because it is not in the database. Declare the member, document
  the producer, move on.
- **`00-README` §10 records this as a live open contradiction**: 07 §3.3 says the warning "never
  blocks the create", while 03 §6's partial unique index makes a second *active* animal on the same
  tag unstorable. One of the two is wrong and it is a domain question. Do **not** resolve it here by
  deleting the code or by softening it — this task declares the vocabulary; N26 resolves the
  behaviour, and it needs the code to exist to argue about.
- **The mechanism is the *absence*, so the diff must be read for what is not in it.** No
  `fix()`, no `apply()`, no `T get cleaned`, no `Warning.corrected`, no callback field, no reference
  to a repository. `/shed-code-review` is doubly required on this file because a helpful future
  contributor adding `Reviewed.cleaned` is a two-line diff that deletes safety rule 4.
- **`Reviewed<T>` is not `Either`, `Result` or `Validated`.** `Either<Corrected, List<Warning>>` is
  banned by name in `05` §9 row 16. There is no error arm, because a warning is never a failure — the
  save is never blocked (guarantee 3), so there is nothing to branch on.
- **The word is `warnings`, never `flags`** (R71) — in prose, in field names, in the commit message,
  in the ARB. Decision #13 originally wrote `WriteCommitted{flags}`; the field is `warnings` because
  its type is `List<Warning>`.
- **`message` states what was observed, never what to do.** *"Birth type is twin but 3 lambs are
  recorded."* is a message; *"Change the birth type to triplet."* is advice and would trip
  `copy.vet_advice` in T09 the moment it names a number.
- **`lib/core/write_outcome.dart` importing this file is legal and intended** (R53): core may import
  domain, and the ban is `lib/data/` → `lib/domain/validation/` specifically. Do not "tidy" that
  import away.
- **Adding a twelfth code is a `CONVENTIONS` §2.6 edit**, not a local decision — the eleven are
  catalogued there and `12-testing.md` counts them.

### 5.5 The full test set

| File | Cases |
|---|---|
| `test/policy/warning_has_no_writer_test.dart` | **anchor:** `'Warning has no fix(), no writer and no persistence path'`, all three clauses · `'Reviewed<T> exposes no cleaned or corrected accessor'` · `'no file under lib/ declares a warnings column'` — a source scan for `warnings` as a drift column declaration, which is guarantee 2's half that N07 must not break |
| `test/domain/validation/warning_test.dart` | `'WarningCode has exactly eleven members, in CONVENTIONS §2.6's order'` (freeze the `.name` list literally) · `'Reviewed.hasWarnings is false for an empty list and true otherwise'` · `'Reviewed holds the value byte-identically'` — construct with a `String` carrying leading/trailing whitespace and a comma, and assert it comes back unchanged · `'a Warning constructed without fieldPath has a null fieldPath'` |

**No `uk-zone` case.** Nothing here carries a time. `timeDoesNotExistLocally` is *named* in the enum
but is raised by N04-T08's `checkLocalWallTimeExists`, whose DST-3 case already runs in the
01:00–01:59 hour under `TZ=Europe/London`.

## 6. Constraints that bind this task

- **§12.4, held at *unrepresentable* — the highest level this rule ever reaches in the product.** `Warning` has no writer, no `fix()` and nowhere to go: there is no `warnings` column anywhere in the schema and `lib/data/` may not import this folder at all. `Reviewed<T>` binds a value to what is questionable about it, so a screen cannot render the value without the warning. Every one of those absences is held down by the policy test in §5; add a writer and §12.4 has dropped two levels in one commit.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'Warning has no fix(), no writer and no persistence path'` passes, and was seen to fail first for the stated reason
- [ ] no member mutates anything
- [ ] no `warnings` column is proposed anywhere in N07
- [ ] the eleven codes match `05-domain-correctness.md` exactly
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/warning_has_no_writer_test.dart
fvm flutter test test/domain/validation/warning_test.dart
grep -rn "domain/validation" lib/data/     # expect: nothing — R53, layer.data_no_validation
grep -rn "flags" lib/ test/                # expect: nothing — R71
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): Warning, WarningCode and Reviewed<T> — no writer, no fix`
