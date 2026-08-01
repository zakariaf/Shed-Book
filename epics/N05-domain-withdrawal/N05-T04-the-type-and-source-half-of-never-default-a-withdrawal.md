# N05-T04 — The type-and-source half of *never default a withdrawal*

| | |
|---|---|
| **Epic** | [N05 — Domain: withdrawal](epic.md) · `00-README` §9 step 2 (2 of 3) |
| **Task** | 4 of 5 |
| **Depends on** | N05-T03 |
| **Commit** | one commit · `test(policy): no literal withdrawal day count under lib/` |

## 1. Why this task exists

`test/policy/withdrawal_has_no_default_test.dart` grows its second assertion: **no literal
withdrawal day count appears anywhere under `lib/`** — not in a constant, not in an example, not in a
placeholder, not in a comment that a future contributor will copy. The schema half of this test lands
at the freeze, in N07-T08.

The type from N05-T01 stops a *value*. It cannot stop a developer writing
`const kDefaultWithdrawalDays = 7` and feeding it to the factory, because the factory cannot tell a
typed 7 from a hard-coded one. That is the gap this assertion closes, and it is the last one that is
cheap to close before twelve screens exist.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §2 #52 | **two gates and no more**, and the heuristic that is deliberately not written |
| `docs/engineering/12-testing.md` | §1.4, §10.3 | what is a gate and what is a test, and the published shape of this file |
| `docs/engineering/05-domain-correctness.md` | §3.9, §7.3 | the two gates, and the joined-string-literal trap that breaks naive source scans |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 | *"Do not add a source heuristic banning numeric literals near withdrawal"* — the sentence this task must not violate |
| `shed-book-spec.md` | §7.5, §12.1 | the app ships no default values and makes no suggestion |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | the test is the mechanism and the rule is its reason |
| `shed-testing` | a policy test named for the property it holds |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/withdrawal_has_no_default_test.dart`
- **Test** — `'no literal withdrawal day count appears anywhere under lib/'`
- **Why it is red today** — nothing stops a `const kDefaultWithdrawalDays = 7` being written today.

```bash
fvm flutter test test/policy/withdrawal_has_no_default_test.dart   # expect: failing, for the reason above
```

Make it red honestly: plant `const kDefaultWithdrawalDays = 7;` in a scratch file under `lib/`, watch
the assertion fail **naming that file and line**, then delete the file before you write the fix. A
scan that has never been seen to fire is indistinguishable from a scan that asserts nothing.

**Green.** The minimum code that passes, and nothing beyond it — scan the source for the shapes that would encode a default, and fail naming the file and
line.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

**This task touches no layer except tests, and the commit message says so** — the commit type is
`test(policy)` precisely because nothing under `lib/` changes. If your diff contains a `lib/` file,
either you planted a default and forgot to delete it, or the scan found something real and the fix
belongs in its own commit ahead of this one.

| # | File | New or re-opened | What changes in it, and why |
|---|---|---|---|
| 1 | `test/policy/withdrawal_has_no_default_test.dart` | **re-opened** (N05-T01 created it) | The second assertion, plus the file-local scanner it needs and the self-tests that prove the scanner fires and stays quiet. Update the file docstring so it names all three halves and their tasks. |

Nothing else. In particular:

- **No `tool/check_policy.dart` row.** See §5.3 — this is not a third gate.
- **No line in `tool/policy_allowlist.txt`.** An `[exempt]` line deletes a rule for one file,
  forever, silently; `CONVENTIONS` R56 fixes the allowlist at four lines on day one and none of them
  is this. If the scan cannot be written without an exemption, it is the wrong scan.
- **No helper in `test/support/`.** That directory does not exist until N12-T05, and when it does it
  holds `harness.dart`, the fakes and `seeds.dart` — not source scanners. The scanner is a
  file-local function belonging to this one property (12 §5.3).

### 5.2 The shape of the assertion

The scanner is a pure function over `(path, text)` so the same code can be pointed at the real tree
**and** at a planted string. That is what makes both halves of the Definition of Done checkable
without a test ever writing into the source tree:

```dart
// test/policy/withdrawal_has_no_default_test.dart
//
// Spec §12.1 — never default a medicine withdrawal period. THREE HALVES, and
// this file is all of them:
//   * the type half     — N05-T01: WithdrawalDays has no public generative ctor
//   * the source half   — N05-T04: no literal day count under lib/  (this one)
//   * the schema half   — N07-T08: drift_schema_v1.json has null defaultValue
//                         and null clientDefault for treatment_withdrawals.days
// The fourth proof is a widget test on the entry control, in N20-T02.

/// A hit is (path, line, why). Empty means clean.
List<({String path, int line, String why})> literalWithdrawalDays(
    String path, String text) { … }
```

Three shapes, and only three. Each is a *construction or declaration site*, never a proximity match:

| # | Shape | Why it is a default |
|---|---|---|
| 1 | a call to `asEnteredByUser(` whose `days:` argument is an integer literal | the only entry point, handed a number nobody typed |
| 2 | a `const` / `final` / `static const` declaration whose identifier contains a withdrawal token **and** a day token, initialised to an integer literal | `const kDefaultWithdrawalDays = 7`, in every spelling of it |
| 3 | `WithdrawalDays._(` outside `lib/domain/withdrawal/withdrawal_period.dart` | the private constructor reached through a `part`, which is the one hole `sealed` does not close |

Scope: files under `lib/` only, ending `.dart`, **excluding** `*.g.dart` and `*.drift.dart`
(generated code is never hand-edited and is always skipped by the gate). Comments are **in scope on
purpose** — the Definition of Done says *"not in a comment that a future contributor will copy"*,
and a commented-out default is the most copied line in any codebase.

### 5.3 The details that are easy to get wrong

- **This is not the heuristic decision #52 rejects, and the difference has to be visible in the
  code.** What #52 rejects — in three documents, by name — is *"a source heuristic banning a
  numeric literal near the word withdrawal"*: it fires on `CHECK (days IS NULL OR days >= 0)`, on
  `CHECK (target IN ('meat','milk'))`, on every fixture and on the doc set's own examples. *"A gate
  with a standing false positive gets an allowlist, then gets weakened, then gets deleted — and it
  is guarding the one rule whose regression is a food-safety incident."* The three shapes above have
  **zero standing false positives on the real tree**, and the test that proves it is not optional:
  it is the negative self-test in §5.4. If you cannot keep that test green without an exemption,
  **stop and raise it** rather than widening the allowlist — `CLAUDE.md` is explicit that a gate you
  have to silence is a gate you should be arguing about.
- **Why it stays in `test/policy/` and does not become a `check_policy` row.** 12 §1.4's rule is
  *"if the assertion can be made by reading source text, it belongs in `tool/check_policy.dart`"* —
  and the rule immediately above it is decision #52's *two gates and no more*, where the two are the
  schema-JSON assertion and the widget test. Both live in `test/`, because one parses JSON and the
  other pumps a widget, and `check_policy.dart` has zero dependencies and no test harness by design.
  Splitting §12.1's proof across two files would leave a reader of `withdrawal_has_no_default_test.dart`
  believing they had seen the whole rule. Keep the three halves in the one file `03` §5.8, `05`
  §3.9 and `12` §10.3 all name by path.
- **The long-string trap, found while the research was being written, not theorised.** A naive
  `text.contains('some long phrase')` **misses**, because Dart wraps long strings across adjacent
  string literals and the phrase is never contiguous in the source. It does not bite shapes 1 and 3,
  and it bites shape 2 the moment somebody writes the identifier across a line break. Normalise
  whitespace before matching, and never build the scan on a single `contains`.
- **Skip generated files or the scan will fail on something nobody wrote.** `*.g.dart` and
  `*.drift.dart` are regenerated by `make gen` and are always waved through in review; a scan that
  reads them is a scan that will one day be red on a `drift_dev` bump.
- **Never scan `test/`.** This file would match itself — it contains all three shapes as fixtures —
  and so would every future seed and fixture. Scoping to `lib/` is the second reason the false
  positive set is empty.
- **Plant into a string, not into a file.** A test that writes a scratch file under `lib/` leaves
  the tree dirty when it fails, and `make check`'s formatter and analyzer will then fail for a
  reason that has nothing to do with the assertion. The planted-default test feeds a literal string
  to the scanner. (The one-off manual plant in §4 is a deliberate act you undo by hand before you
  write any code.)
- **The failure message is the deliverable.** *"names it"* in the Definition of Done means path and
  line number, and the why: `lib/features/treatments/foo.dart:41 — const declaration initialised to
  an integer literal (kDefaultWithdrawalDays)`. A bare `expect(hits, isEmpty)` at 3am tells a
  developer nothing.
- **`test/policy/` is in the blocking set already.** `dart_test.yaml` declares a `policy` tag, and
  the `test` job runs `-P ci-fast` — everything except `golden`. Nothing extra is needed to satisfy
  the Definition of Done's *"the test is in the blocking set"*; do not add a tag that would let it
  be filtered out.
- **The scan is not a substitute for reading the diff.** `00-README` §8 step 10 and
  `CODE-REVIEW-CHECKLIST` §3.3 both put `lib/domain/withdrawal/**` on the never-waved-through list,
  however small the diff. A green scan is evidence, not absolution.

### 5.4 The full test set

All of it in `test/policy/withdrawal_has_no_default_test.dart`, beside N05-T01's assertions:

| Test | Case |
|---|---|
| `'no literal withdrawal day count appears anywhere under lib/'` | **the anchor.** The scanner over every non-generated `.dart` file under `lib/`; expects no hits |
| `'the scan names the file and the line of a planted default'` | a planted `const kDefaultWithdrawalDays = 7;` string produces one hit carrying path, line and reason |
| `'the scan fires on a literal handed to asEnteredByUser'` | `WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat)` as a planted string |
| `'the scan fires on the private constructor called outside its own file'` | shape 3, planted |
| `'the scan is silent on the schema CHECK constraints and on the implausibility guard'` | the negative self-test: `CHECK (days IS NULL OR days >= 0)`, `CHECK (kind IN ('days','not_applicable'))` and the factory's own `days > 1000` guard all produce **no** hits. This is the test that keeps the assertion honest against decision #52 |
| `'the scan is silent on a day count read from a row or a parameter'` | `asEnteredByUser(days: typed, …)` and `asEnteredByUser(days: row.days!, …)` produce no hits |
| `'the scan reads comments, because a commented-out default is one a contributor will copy'` | the planted default inside a `//` line still fires |
| `'the scan skips generated files'` | the same planted string in a path ending `.g.dart` produces no hits |

**No `uk-zone` case.** Nothing here is time-shaped: the assertion is about source text, and it holds
identically in every zone. The zone-pinned tier belongs to N05-T02 and N05-T03.

## 6. Constraints that bind this task

- **Safety rule §12.1, held at *caught by a test on the source text*.** That is the fourth level of
  the hierarchy, below *unconstructible* and *unpersistable* — which is why this task is a
  supplement to N05-T01 and N07-T08 and never a replacement for either. A rule that drops to merely
  *documented* has been deleted, whatever the prose says.
- **Decision #52: two gates and no more.** This assertion earns its place by having no false
  positives; the moment it acquires one it must be deleted, not exempted.
- **No medicines lookup table, no learned default, no *"you usually enter 28 for this product"*.**
  Those are the features shape 2 exists to catch early: they are a medicines database the user built
  by accident, and they fail silently on the one bottle that changed.
- **`ContentPolicy`'s regexes are not this task's.** *"default withdrawal"*, *"typical withdrawal"*
  and the rest are string-literal patterns and they land with `ContentPolicy` in N06-T09. Writing
  them here would define the same rule in two places, which is exactly what the disclaimer test
  caught during the research.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'no literal withdrawal day count appears anywhere under lib/'` passes, and was seen to fail first for the stated reason
- [ ] the test fails on a planted default and names it
- [ ] the test's docstring says the schema half arrives in N07-T08
- [ ] the test is in the blocking set
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
fvm flutter test test/policy
fvm dart run tool/check_policy.dart
git diff --stat -- tool/policy_allowlist.txt
make check
make test
```

The fourth command must print nothing: a green build bought with an allowlist line is not a green
build.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): no literal withdrawal day count under lib/`
