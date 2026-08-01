# N03-T01 — The gate skeleton — the rule table, the walk, the allowlist

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 1 of 7 |
| **Depends on** | N02-T03 |
| **Commit** | one commit · `feat: the gate skeleton — rule table, file walk, allowlist parser` |

## 1. Why this task exists

`tool/check_policy.dart`: the rule-table shape (id, description, matcher, scope), the file
walk, the generated-file skip (`*.g.dart`, `*.drift.dart`, `app_localizations*.dart`), the
`tool/policy_allowlist.txt` parser, and the four `[exempt]` lines that exist on day one — each with
its reason in the commit message, because an exempt line deletes a rule for one file forever and
silently.

Nothing in this commit forbids anything. That is deliberate: six tasks follow that each add rows, and
every one of them needs the walk, the skip predicate, the allowlist lookup key and the temp-tree test
harness to already be correct. Get the skeleton wrong and six tasks inherit the bug — the most
expensive version of which is an `[exempt]` lookup key that never matches, so every exemption written
for the next three years is silently inert.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §3.2 | the printed driver, the tuple shapes, `_readAllowlist`, the allowlist file format |
| `docs/engineering/01-architecture.md` | §3.3 | the scanned roots, why `tool/` is not scanned, and the three places it runs |
| `docs/engineering/CONVENTIONS.md` | §1 | `tool/check_policy.dart` and `tool/policy_allowlist.txt` are in the canonical tree, with their one-line contracts |
| `docs/engineering/CONVENTIONS.md` | §4.7 | the rule-id grammar and the four `[exempt]` lines, verbatim (R56) |
| `docs/engineering/00-README.md` | §7.3 | the full list of generated files the gate always skips |
| `docs/research/00-tech-decisions.md` | §2 #9, #10 | one script, one allowlist, one exit code — and no second scanning script, ever |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | the rule ids, the file names and the allowlist format are names it owns |
| `shed-dependencies-and-toolchain` | the gate is the enforcement half of the dependency and layering contract |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'check_policy exits 0 on a clean tree and skips every generated file'`
- **Why it is red today** — `tool/check_policy.dart` does not exist and `make check` calls a script that is not there.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The assertion, spelled out, so "green" is unambiguous: build a temp tree containing one ordinary
`lib/` file and one of **each** generated shape — `lib/core/db/database.g.dart`,
`lib/core/db/search.drift.dart`, `lib/l10n/app_localizations_en.dart`,
`test/drift/generated/schema_v1.dart` — with a rule-tripping literal inside every generated one, and
assert `runPolicy(root: temp)` returns an empty list. With no rules in the table yet the first half
passes trivially; the four generated shapes are what the test is really for, and three of the four
are not skipped by the driver as `01-architecture.md` §3.2 prints it.

**Green.** The minimum code that passes, and nothing beyond it — the skeleton with an empty rule table, the walk, the skip list and the allowlist parser —
no rules yet.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

`00-README` §8's order is schema → domain → data → wiring → controller → UI → ARB → tests. **This
task reaches none of those layers**: it is a `tool/` and `test/policy/` change and stores nothing.
§8 requires you to say that out loud in the commit message, so the message body carries one line —
*"no schema, no domain, no data, no UI, no ARB: this is the gate and its proving test."*

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | **New.** The header comment, the empty rule tables, the roots, the skip predicate, the allowlist parser and the driver. Zero dependencies beyond `dart:io` — the moment it needs `pub get` it can fail for reasons that are not violations (01 §3.3) |
| 2 | `tool/policy_allowlist.txt` | **New.** Four sections — `[dependencies]`, `[dev_dependencies]`, `[transitive]`, `[exempt]` — with the four R56 exempt lines and nothing else. The three dependency sections stay empty until N03-T04 fills them |
| 3 | `test/policy/gate_rules_test.dart` | **New.** The temp-tree harness every later task reuses, plus the clean-tree and generated-file cases |
| 4 | `Makefile` | **No change.** N01-T05 already made `dart run tool/check_policy.dart` the first line of `check`. This commit is what makes that line exit 0 |
| 5 | `.github/workflows/ci.yml` | **No change here.** N01-T06 authored the `Policy gate (G2 + G3)` step from `13 §4.3`; N03-T07 asserts its position and adds the inventory assertion |

### 5.2 The signatures

`01-architecture.md` §3.2 prints a `main()` that walks, prints and calls `exit(1)`. That shape cannot
be tested and cannot answer N03-T07's inventory question, so the skeleton splits it in two: a pure
function that takes a root and returns violations, and a `main()` that is the only code that prints
or sets an exit code. Everything else in §3.2 — the tuple shapes, the const table names, the
`_layers` list, the allowlist format — is kept exactly as printed, because six later tasks and four
other documents add rows against those exact shapes.

```dart
// tool/check_policy.dart
//
// The single source-and-dependency gate for Shed Book.
//   dart run tool/check_policy.dart
// Exit codes: 0 clean · 1 violations · 2 the gate could not run (still a failure).
//
// Dependency-free by decision (00-tech-decisions #9, #10): every analyzer plugin
// that could express these rules is discontinued, archived, or unresolvable
// against drift_dev's analyzer ^13.0.0. Do not add a second scanning script;
// the answer to a new rule is a new row in the tables below.
//
// THE RULE TABLE IS NOT CLOSED. copy.vet_advice and copy.disclaimer_retyped
// need ContentPolicy and Disclaimers and arrive with them (N06-T09). The
// db.destructive_ddl family arrives with the migration harness (N08), and
// layer.in_app_purchase / launch.store_call with monetization (N30). A row and
// the case that proves it fires land in the same commit — always.

import 'dart:io';

const _package = 'shed_book';

/// Walked roots. `tool/` is deliberately absent: this file's own tables contain
/// every banned literal, so scanning it would fail the build on itself.
const _roots = <String>['lib', 'test'];

/// (id, literal text, path prefix it applies under, why). An empty `under`
/// means every scanned root — the driver never walks anything else.
const _bannedText = <(String, String, String, String)>[];

/// Same tuple, a pattern instead of a literal. `final`, not `const`: RegExp has
/// no const constructor.
final _bannedPattern = <(String, RegExp, String, String)>[];

/// Every rule id this script can emit, in declaration order. N03-T07's
/// inventory assertion iterates this; a rule that is not here cannot be proved.
Iterable<String> get policyRuleIds sync* { /* … */ }

/// Pure. Walks [root], applies every rule, returns one message per violation.
/// Never prints and never exits — main() owns the process.
List<String> runPolicy({String root = '.'});

/// Parses `<root>/tool/policy_allowlist.txt`. Throws [PolicyConfigError] on a
/// malformed line; main() turns that into exit 2.
Map<String, Set<String>> readAllowlist(String root);

final class PolicyConfigError implements Exception {
  const PolicyConfigError(this.message);
  final String message;
}

void main(List<String> args) {
  final List<String> violations;
  try {
    violations = runPolicy();
  } on PolicyConfigError catch (e) {
    stderr.writeln('POLICY  ${e.message}');
    exit(2);
  }
  if (violations.isEmpty) {
    stdout.writeln('policy ok');
    return;
  }
  for (final line in violations..sort()) {
    stderr.writeln('POLICY  $line');
  }
  exit(1);
}
```

The skip predicate is its own named function, because `00-README` §7.3 lists **four** generated
shapes and §3.2's printed driver skips two of them:

```dart
/// 00-README §7.3: everything generated is named so you can see it, and the
/// gate always skips it. Never hand-edit one; `make gen` is the only writer.
bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.drift.dart') ||
    path.contains('/app_localizations') ||
    path.contains('test/drift/generated/');
```

### 5.3 The details that are easy to get wrong

- **The `[exempt]` lookup key is whitespace-sensitive, and the file is column-aligned.**
  `01-architecture.md` §3.2 prints the allowlist padded for readability —
  `lib/core/time/app_clock.dart       :: time.dart_clock` — while the driver looks up
  `'$from :: $id'`, with exactly one space either side. Store the raw line and **every exemption
  silently fails to match**: the gate goes red on `app_clock.dart` the day N04 lands, somebody
  "fixes" it by deleting the rule, and nobody sees it happen. Normalise on read: split on `::`, trim
  both halves, rejoin as `'$path :: $id'`. Assert it with a case that uses the padded spelling.
- **§3.2's parser silently swallows a line that is outside any section.** `out[section]?.add(line)`
  with `section == ''` is a null-aware call on a map entry that was never created, so the line
  vanishes. That is exactly the malformed line this task's Definition of Done says must be refused.
  Exit 2 with the file and the 1-based line number for: a line before the first `[…]` header, a
  section header that is not one of the four known names, and an `[exempt]` line with no `::`.
  **Exit 2 is a failure, not a warning** — a gate that cannot read its own configuration has not
  passed, it has failed to run.
- **Three of the four generated shapes are not `*.g.dart`.** `lib/l10n/app_localizations.dart` and
  `app_localizations_en.dart` come from gen-l10n, and `test/drift/generated/**` from
  `drift_dev schema steps`. All are committed (`00-README` §7.1) and all are walked by a driver that
  only checks two suffixes. `app_localizations_en.dart` will contain user-facing strings the
  vocabulary rules would fire on, and the drift helpers contain generated SQL. Skip all four now,
  while there is a test that can see the difference; retro-fitting the skip after N08 means a red
  `gate` job on a file nobody is allowed to edit.
- **The walk must be deterministic.** `Directory.listSync(recursive: true)` returns filesystem order,
  which differs between macOS and the `ubuntu-latest` runner. The driver sorts violations before
  printing, so output is stable — but if you ever short-circuit on the first violation, the message
  becomes machine-dependent. Collect all, sort, print.
- **`Directory('lib')` and `File('pubspec.lock')` are relative** (01 §3.3), and it runs from the
  repository root. Threading `root` through every path join is the whole reason `runPolicy` takes it;
  do not reach for `Directory.current =`, which is process-global and breaks under the randomised
  test ordering `make test` uses.
- **Only `.dart` files are walked in this commit.** `00-README` §7.3's list is Dart-shaped and the
  layer rules are import-shaped. N03-T06 widens the filter to `.arb`, because the vocabulary rules
  have to read `lib/l10n/app_en.arb`. Write the filter as one named predicate now so widening it is a
  one-line change in that task and not a rewrite of the walk.
- **The four `[exempt]` lines point at files that do not exist yet.** `app_clock.dart` arrives in
  N04, `night_error_panel.dart` in N11, `primitives.dart` and `palettes.dart` in N09. That is fine —
  an exemption for a missing file is inert — but do **not** add a "stale exemption" check that fails
  on it, or this commit fails on itself. R56's four lines are the day-one set and their reasons go in
  this commit's message: `app_clock.dart` is the single allowlisted home of `DateTime.now(`
  (decision #46); `night_error_panel.dart` hard-codes `#0B0D0E` because it renders outside any
  `Theme`; `primitives.dart` is by definition the file that holds the raw hexes; `palettes.dart` is
  the one file allowed to import it.
- **The test file is scanned.** `test/policy/gate_rules_test.dart` lives under a walked root. It is
  harmless today because the table is empty, and it stays harmless for most later rows because they
  are scoped `lib/` — but the harness must plant its violations **into the temp tree**, never as a
  literal in its own source. Build the harness that way now and the later tasks inherit it.

### 5.4 The full test set

`test/policy/gate_rules_test.dart` — the one file every rule in this epic is proved in
(`00-README` §8 step 7 item 27: a §12-adjacent assertion lives in `test/policy/` and is named for the
property, not the file). The shared harness, written once here:

```dart
// test/policy/gate_rules_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/check_policy.dart';

/// Writes [files] into a throwaway tree, runs the gate over it, returns the
/// violations. The planted text lives in the temp tree, never in this file.
List<String> gateOn(Map<String, String> files, {String allowlist = _emptyAllowlist}) { … }
```

| Case | What it asserts |
|---|---|
| `'check_policy exits 0 on a clean tree and skips every generated file'` | The anchor. One ordinary file plus the four generated shapes, each carrying a literal a later rule will ban; zero violations |
| `'a missing allowlist file is exit 2, not exit 0'` | `readAllowlist` on a tree with no `tool/policy_allowlist.txt` throws `PolicyConfigError`; `main` maps it to 2. A gate that cannot read its configuration has failed to run |
| `'an allowlist line outside any section is refused with its line number'` | The §3.2 parser's silent swallow, closed |
| `'an unknown section header is refused'` | `[deps]` instead of `[dependencies]` is a typo that would empty an entire allowlist section |
| `'an exempt line with no :: separator is refused'` | Malformed waiver, refused rather than ignored |
| `'a column-aligned exempt line matches the driver lookup key'` | The padded spelling from `01 §3.2` is normalised to `'<path> :: <id>'` |
| `'comments and blank lines are ignored, and # ends a line'` | `#` starts a comment; the `[transitive]` section depends on this in N03-T04 |
| `'the walk is not affected by filesystem order'` | Two plantings in different creation order produce the same sorted output |
| `'policyRuleIds is empty in this commit'` | The inventory hook exists and is honest — N03-T07 turns it into an assertion with teeth |

Nothing here is time-shaped, so there is no `test/domain/uk_zone/` case: the gate reads text and never
reads a clock. The first `uk-zone` case in the project is N04's.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. Concretely here: the script imports `dart:io` and nothing else, so the gate itself can never be the thing that opens a socket, and it needs no `pub get` to run.
- **One script** — decision #10. Not a second scanner, not an analyzer plugin, not a `RegExp` inside a `test()` (12 §1.4). Every rule any of the fourteen documents adds is a row in one of the two tables in this file.
- **The two files that may never be edited to green a build** (`CLAUDE.md`) are `tool/policy_allowlist.txt` and `android/expected_permissions.txt`. This commit authors the first of them. If a gate is genuinely wrong, say so and stop.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. The failure type here is `PolicyConfigError`… which is exactly the banned spelling — so it is not a *failure* type, it is a configuration exception, and if that reads as a dodge, name it `PolicyConfigProblem` and move on. Do not name it `PolicyError` and call the rule satisfied.

## 7. Definition of Done

- [ ] `'check_policy exits 0 on a clean tree and skips every generated file'` passes, and was seen to fail first for the stated reason
- [ ] exit 0 on a clean tree, exit 1 with a rule id on a planted violation once rules exist
- [ ] generated files are never scanned
- [ ] the allowlist parser refuses a malformed line rather than ignoring it
- [ ] the header comment says the rule table is **not closed at N03** — `copy.vet_advice` and `copy.disclaimer_retyped` arrive in N06-T09
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart run tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

In full, in the order that finds a problem soonest:

```bash
dart run tool/check_policy.dart ; echo "exit=$?"        # policy ok, exit=0
mv tool/policy_allowlist.txt tool/_parked.txt
dart run tool/check_policy.dart ; echo "exit=$?"        # POLICY … is missing, exit=2
mv tool/_parked.txt tool/policy_allowlist.txt
fvm flutter test test/policy/gate_rules_test.dart
make check
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: the gate skeleton — rule table, file walk, allowlist parser`
