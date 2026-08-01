# N02-T03 — `g0_recorded_test.dart` — the guard on `tools:node="remove"`

| | |
|---|---|
| **Epic** | [N02 — G0 — the merged-manifest record](epic.md) · `00-README` §9 step 12, run at 2 |
| **Task** | 3 of 3 |
| **Depends on** | N02-T02 |
| **Commit** | one commit · `test: guard tools:node=remove behind the recorded G0 evidence` |

## 1. Why this task exists

Decision #5 in one executable line: **no `tools:node="remove"` may exist in any manifest
while `13 §2.2`'s table still reads UNVERIFIED**. The test outlives this epic — it is what stops a
future contributor removing a permission on faith because a blog post said it was safe.

It is deliberately **conditional**, not absolute. At N31-T01 the removal directive lands for real, and
this guard must still pass — because by then the table is filled and the precondition is false. A
guard that banned the line outright would be deleted the first time somebody legitimately needed it,
and a deleted guard protects nothing in month six when a plugin bump re-opens the question.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §1 #5, §3.2 | *"before any `tools:node="remove"` line is committed"* — the exact condition this test executes |
| `docs/engineering/13-build-ci-release.md` | §2.2 | the four-row table the guard reads, and the sentence about G1 being unwritten until it is filled |
| `docs/engineering/13-build-ci-release.md` | §2.3, §2.8 | a gate that could not run *"is still a failure, never a skip"* · the four named anti-patterns, one of which is scanning `build/` |
| `docs/engineering/12-testing.md` | §1.4, §10 | gate-versus-test, and why a policy test is named for the **property** it holds |
| `docs/engineering/00-README.md` | §9 step 1 | *"a rule nobody has seen fire is indistinguishable from a broken rule"* |
| `docs/engineering/CONVENTIONS.md` | §1, §4.1, R57 | `test/policy/` is in the tree; the filename states the property |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the manifest and its removal directives are its subject |
| `shed-testing` | a policy test named for the property it holds, not the file it reads |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/g0_recorded_test.dart`
- **Test** — `'no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED'`
- **Why it is red today** — nothing stops a `tools:node="remove"` line being written today.

```bash
fvm flutter test test/policy/g0_recorded_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — scan every `AndroidManifest.xml` for the directive and cross-read the table; fail with a
message that names the row that is still unverified. The scan is over
`android/app/src/*/AndroidManifest.xml` — the three source-set manifests a `flutter create` project
has — and over nothing else. The table parser is T01's `_g0Table()`, already in this file; reuse it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. There
is exactly one duplication to fold: both tests slice `13 §2.2`. One parser, two `test()` bodies, no
`test/support/` helper — `12 §10` keeps a format only one file reads inside that file.

## 5. What you build

### 5.1 What the guard actually asserts

Two facts, and the relation between them. Neither alone is the rule.

| `13 §2.2` table | A removal directive under `android/` | Verdict |
|---|---|---|
| any row unfilled | none | **pass** — the state of the world before T01 |
| any row unfilled | present | **fail**, naming the unfilled row | 
| all four rows filled | none | **pass** — the state at the end of this epic |
| all four rows filled | present | **pass** — the state after N31-T01, and the reason the guard survives |
| unreadable or absent | either | **fail.** `13 §2.3`: a gate that could not run *"is still a failure, never a skip"* |

The failure message names the row, not the file. *"`13 §2.2` row 2 (`ACCESS_NETWORK_STATE`) still
reads UNVERIFIED, and `android/app/src/main/AndroidManifest.xml` line 14 removes a permission"* tells
the reader what to do; *"assertion failed"* tells them to delete the test.

### 5.2 The files this task touches, in order

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/g0_recorded_test.dart` | a second `test()` in the file T01 created, plus the manifest scanner. One file, two properties, one shared table parser |
| 2 | `docs/engineering/13-build-ci-release.md` §2.2 | one sentence recording that the condition is now executable and where it lives. The document said *"until this table is filled in, `android/expected_permissions.txt` does not exist and G1 cannot be written"* — a reader arriving at N31 needs to know what now holds that line |

Nothing else. No `lib/`, no `android/`, no workflow file: `test/policy/` is already inside the `test`
job's `-P ci-fast` selection from N01-T06, so no CI change is needed to make this blocking.

### 5.3 The guard, in outline

```dart
// test/policy/g0_recorded_test.dart — decision-record §1 item 5; 13 §2.2.
// Only the three source-set manifests. NEVER a recursive walk from the repo
// root: build/ holds a merged manifest and is gitignored, so a walk is green
// in CI and red on the machine that just ran T01's experiment.
const _manifests = <String>[
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/debug/AndroidManifest.xml',
  'android/app/src/profile/AndroidManifest.xml',
];

/// Any directive that deletes something at merge time — not just the one
/// spelling. `tools:node="removeAll"` is not caught by a match on
/// `tools:node="remove"`, and `tools:remove="…"` deletes an attribute.
final _removalDirective = RegExp(
  r'''tools:(node\s*=\s*['"]remove(All)?['"]|remove\s*=)''',
);

/// Rows of 13 §2.2 whose Answer or Recorded-on cell is still unfilled.
Iterable<String> _unverifiedRows() => _g0Table()   // T01's parser, reused
    .where((r) => r.$2.contains('UNVERIFIED')
        || r.$2.toLowerCase().contains('not yet run')
        || r.$3.trim() == '—')
    .map((r) => r.$1);

void main() {
  test('no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED', () {
    final unverified = _unverifiedRows().toList();
    if (unverified.isEmpty) return;   // G0 is recorded; N31-T01 may write the line
    expect(File(_manifests.first).existsSync(), isTrue,
        reason: 'src/main must exist; an absent manifest is a failure, never a skip');
    for (final path in _manifests) {
      final file = File(path);
      if (!file.existsSync()) continue;   // src/debug and src/profile only
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        expect(_removalDirective.hasMatch(lines[i]), isFalse,
            reason: '$path line ${i + 1} removes something at merge time while '
                '13 §2.2 still reads UNVERIFIED for: ${unverified.join(", ")}');
      }
    }
  });
}
```

### 5.4 The details that are easy to get wrong

- **Do not scan the doc set.** `grep -rn 'tools:node="remove"' --include="*.md" docs/` returns **39**
  lines today — `13 §3.1`'s example manifest, `08 §8`'s, `11 §2`, `00-README` §4, `REFERENCES` §22
  B19, `CODE-REVIEW-CHECKLIST`. Every one is documentation doing its job. A guard that reads markdown
  is red forever on day one and gets weakened by whoever hits it.
- **Do not walk the tree from the repository root.** `build/` is gitignored, so it is absent in CI and
  present on the machine that just ran T01 — and after T01's B19 experiment it contains a **merged**
  manifest carrying exactly the directive this test bans. A recursive walk is therefore green in CI
  and red locally, which is the worst kind of flake and the shape `13 §2.8` warns about when it bans
  grepping `build/app/intermediates/`. Name the three files.
- **There are three source-set manifests, not one.** `flutter create` writes `src/main`, `src/debug`
  and `src/profile`; the last two exist precisely to hold `INTERNET` for hot reload, which is what
  makes them the interesting place for a removal directive. `src/profile` is the one people forget.
- **`tools:node="remove"` is not the only spelling that deletes.** `tools:node="removeAll"` is not
  matched by a search for `tools:node="remove"` — the closing quote is in the way — and
  `tools:remove="android:name"` deletes an attribute rather than an element. Match the family, allow
  whitespace around the `=`, and allow single quotes.
- **The test goes green at the end of this epic for a reason that is not the guard working.** T01
  filled the table, so the precondition is false and the body never runs. That is correct behaviour
  and it is *also* indistinguishable from a broken test. `00-README` §9 step 1: *"a rule nobody has
  seen fire is indistinguishable from a broken rule."* Run the drill in §8 before you commit.
- **Why this is a test and not a `check_policy.dart` rule.** `12 §1.4` is emphatic that source scans
  belong in the gate. Three reasons it does not apply here, and all three should be in the commit
  message: `tool/check_policy.dart` does not exist until **N03**, and the temptation this guards
  against exists **now**; the gate walks Dart source under `lib/` and `test/`, and an XML file under
  `android/` is outside that walk; and the assertion is a **relation between two artefacts** — a
  manifest and a document's table — which `12 §1.4` puts in `test/policy/` alongside the other
  artefact assertions.
- **"In the `gate` job's blocking set" means the blocking set, not the `gate` job.** `13 §4.2` gives
  the `gate` job no test step; `test/policy/` runs in the **`test`** job, under `-P ci-fast`, on every
  push and every pull request, and it is blocking. Both jobs are required. Moving this file so the
  `gate` job could see it would mean turning it into a source scan, which is the thing §5.4 above
  explains it is not.
- **Read `13 §2.2` from disk on every run.** A copy of the table's state inside the test is a copy
  that goes stale, and it would go stale in the one direction that matters: green while the document
  says UNVERIFIED.
- **Slice §2.2, not the whole document.** `13` carries the word UNVERIFIED in §2.3's `bundletool`
  note and inside §4.3's YAML comment. This is the same trap T01's parser already avoids, which is
  why the parser is shared rather than re-written.

### 5.5 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/g0_recorded_test.dart` | `'no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED'` | a removal directive committed before the evidence exists |
| `test/policy/g0_recorded_test.dart` | `'the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares'` (N02-T01) | the table being half-filled or disagreeing with decision-record §3.3 |
| *drill, not a case* | plant `tools:node="removeAll"` in `src/profile` with the table reverted | the family match; the third source set |
| *drill, not a case* | plant `tools:remove="android:name"` in `src/main` with the table reverted | attribute-level deletion slipping past an element-level match |
| *drill, not a case* | revert one *Recorded on* cell to `—` with a directive present | the precondition keyed on the sentinel column and not only on the word UNVERIFIED |
| `test/policy/g0_recorded_test.dart` | *edge* — `13` absent or §2.2 unparseable fails, never skips | `13 §2.3`: a gate that could not run is a failure, never a skip |

The drills are run by hand, watched to fail, and reverted; they are not committed. Planting a
violation, confirming the failure and deleting the file is `00-README` §9 step 1's own method.

Nothing in this task is time-shaped — the guard computes no instant and formats no date — so there is
no `test/domain/uk_zone/` case to add. The only date it touches is the *Recorded on* cell, and it
reads that as a sentinel, never as a time. The ambiguous **01:00–01:59** hour first appears in N04.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **The guard is conditional, and it stays conditional.** N31-T01 legitimately writes the directive this test bans today. Hardening it into an absolute ban would guarantee its deletion, and a deleted guard protects nothing.
- **Never weaken a red gate to make a build green** (`CLAUDE.md`). If this test goes red, the answer is the manifest or the missing evidence — never the regular expression, never an allowlist entry, never a skip.
- **`test/policy/` names the property, not the file** (`12 §10`, `CONVENTIONS` §4.1, R57). The file is named for G0 being recorded, which is the property; it is not named for the manifest it reads.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED'` passes, and was seen to fail first for the stated reason
- [ ] the test fails if a `remove` directive is planted while the table is unverified
- [ ] the test passes now that T01 filled the table
- [ ] the test is in the `gate` job's blocking set
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

The drill first, because the pass at the end proves nothing on its own.

```bash
git stash list
sed -i '' 's/^| Effective `minSdk`.*$/| Effective `minSdk` after plugin merging | **UNVERIFIED** | — |/' docs/engineering/13-build-ci-release.md
printf '%s\n' '  <uses-permission android:name="android.permission.INTERNET" tools:node="removeAll" />' >> android/app/src/profile/AndroidManifest.xml
fvm flutter test test/policy/g0_recorded_test.dart
git checkout -- docs/engineering/13-build-ci-release.md android/app/src/profile/AndroidManifest.xml
fvm flutter test test/policy/g0_recorded_test.dart
make check
make test
```

The fourth command must **fail**, naming the `minSdk` row and the profile manifest. The sixth must
pass. `git status` must be clean before the commit, and `git diff --cached -- android/` empty.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test: guard tools:node=remove behind the recorded G0 evidence`
