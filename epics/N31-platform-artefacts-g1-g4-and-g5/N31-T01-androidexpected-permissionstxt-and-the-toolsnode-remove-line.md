# N31-T01 — `android/expected_permissions.txt` and the `tools:node="remove"` line G0 proved

| | |
|---|---|
| **Epic** | [N31 — Platform artefacts, G1, G4 and G5](epic.md) · `00-README` §9 step 12 (1 of 3) |
| **Task** | 1 of 4 |
| **Depends on** | N30-T08 · N02-T01 · N02-T02 |
| **Commit** | one commit · `feat(android): expected_permissions.txt from the G0 record` |

## 1. Why this task exists

The permission list, exactly as G0 recorded it at N02, and the one removal directive the
evidence supports. Not the list anybody hoped for: `INTERNET` is removed because G0 proved it can be;
`ACCESS_NETWORK_STATE` follows N02-T02's ruling.

Until this commit, the offline claim is a paragraph in three documents. After it there is a file in
the repository that a shell script can compare against a built artefact — and a manifest line that
makes the comparison come out right. `13 §2.2` is blunt about the order: *"Until this table is filled
in, `android/expected_permissions.txt` does not exist and G1 cannot be written."* The table was filled
at N02. This is the file.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §3.3 | **the authority.** The eight-entry set, spelling for spelling, each line naming its contributing library — as N02-T01 left it after reading a real `.aab` |
| `docs/research/00-tech-decisions.md` | §3.1, §3.2 | the three tiers and which two are claimable; G0 as prerequisite and G1 as the gate that executes it |
| `docs/engineering/13-build-ci-release.md` | §2.2 | G0's filled table, the seven-versus-eight counting rule, and the two permitted `ACCESS_NETWORK_STATE` outcomes |
| `docs/engineering/13-build-ci-release.md` | §2.3 | this file's exact shape, printed — and *"Editing this file to silence G1 is the single worst thing you can do to this project."* |
| `docs/engineering/13-build-ci-release.md` | §3.1 | the manifest fragment: the removal directive with its comment, the two permissions we add, and why the `<application>` block is deliberately elided there |
| `docs/engineering/08-platform-integration.md` | §8.3 | the same set from the platform side, with the manifest additions printed in full |
| `docs/engineering/08-platform-integration.md` | §2.9 | `USE_EXACT_ALARM` is a Play-policy rejection, not a preference |
| `docs/engineering/00-README.md` | §7.1, §7.4 | what is committed, and the commit-message vocabulary |
| `CLAUDE.md` | offline purity | the permitted wording verbatim, and the two files that may never be edited to silence a gate |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the manifest, the removal directives and the permission set |
| `shed-conventions` | this file is one of the two `CLAUDE.md` forbids editing to silence a gate |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/permission_set_test.dart`
- **Test** — `'expected_permissions.txt matches the G0 record exactly'`
- **Why it is red today** — the file does not exist and N02-T03's guard is still the only thing holding the line.

```bash
fvm flutter test test/policy/permission_set_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the file from G0's table, the removal directive, and the cross-read assertion. The
assertion is a **set comparison** between the uncommented entries of
`android/expected_permissions.txt` and the permission names in decision-record §3.3's fenced block,
with `android.permission.INTERNET` required to be marked `ABSENT` in §3.3 and required to be absent
from the file.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. There
is one candidate and it should be refused: `test/policy/g0_recorded_test.dart` also parses a document,
and hoisting either parser into `test/support/` invites a second caller who does not know which column
is the sentinel. `12 §10` keeps a format only one file reads inside that file. Two files, two parsers,
two different documents — and §5.4 explains why the two documents are not interchangeable.

## 5. What you build

### 5.1 The files this task touches, in order

`00-README` §8's layer order does not apply: this task reaches no layer — no schema, no domain, no
data, no wiring, no controller, no widget, no ARB. **Say so in the commit message**, with the reason:
the permission set is a property of the merged manifest, which is a Gradle-time artefact of the
*dependency set*, and no line of Dart participates in it.

The order below is **irreversibility order** instead — the file whose edit can make a public claim
false first.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/permission_set_test.dart` | **New, written first** (§4). One `test()` and three small private parsers. `@Tags(['policy'])` on the first line, above every import, followed by a bare `library;` — placed after an import it is silently ignored. N31-T03 adds the second `test()` to this same file |
| 2 | `android/expected_permissions.txt` | **New.** Seven uncommented lines — eight if N02-T02 ruled that `ACCESS_NETWORK_STATE` stays — sorted, each with an inline `#` comment naming the library that contributes it, plus the comment-only lines that record what is *absent* and why |
| 3 | `android/app/src/main/AndroidManifest.xml` | **Edited.** The `tools` XML namespace on the `<manifest>` element, the `INTERNET` removal directive with `13 §3.1`'s comment kept, and the two `<uses-permission>` lines we add ourselves. **The `<application>` block is not touched here** — the two receivers are N31-T02's, and splitting them keeps each commit readable |
| 4 | `docs/engineering/13-build-ci-release.md` | **Edited, one sentence.** §2.2 ends *"Until this table is filled in, `android/expected_permissions.txt` does not exist and G1 cannot be written."* That is now history. Record where the file is and which test holds it against §3.3, so a reader arriving at §2.3 knows what is real and what is a specimen |

Nothing under `lib/`. Nothing under `ios/`. No `pubspec.yaml` edit and no lockfile churn — a diff
touching any of those in this commit is a different task wearing this one's message.

### 5.2 `android/expected_permissions.txt`, as it must read

`13 §2.3` prints this file. Copy its shape; take the **entries** from decision-record §3.3 as N02-T01
left it, because §3.3 is the authority and §2.3's block is a specimen written before G0 ran.

```
# android/expected_permissions.txt
# Sorted, one per line. Every line names the library that contributes it.
# Editing this file to silence G1 is the single worst thing you can do to this project.
android.permission.POST_NOTIFICATIONS      # flutter_local_notifications (merged)
android.permission.RECEIVE_BOOT_COMPLETED  # we add — reschedule after reboot
android.permission.RECORD_AUDIO            # record (merged) — the voice NOTE, not voice tag entry
android.permission.SCHEDULE_EXACT_ALARM    # we add — user-granted. NEVER USE_EXACT_ALARM
android.permission.VIBRATE                 # flutter_local_notifications (merged)
android.permission.WAKE_LOCK               # wakelock_plus (merged)
com.android.vending.BILLING                # Play Billing 8.0.0 AAR via in_app_purchase (merged)
# android.permission.INTERNET              — ABSENT. Removed at merge time. If this line
#                                             ever becomes real, the product's central claim is void.
```

The last line of §2.3's specimen reads *"`ACCESS_NETWORK_STATE` — PENDING G0."* It is no longer
pending. **Write whichever of the two lines N02-T02's ruling produced**, and never both:

- **ruled absent** → it stays a comment, now recording that G0 read the merged manifest and did not
  find it, with the date. Seven entries.
- **ruled present** → it becomes a real, uncommented entry naming Play Billing as its source, and the
  count is eight. `13 §2.2` also requires the store-listing consequence to be recorded — N02-T02
  already drafted that paragraph in `docs/store/offline-honesty.md`; check it is there, quote it, and
  do not re-draft it.

### 5.3 The manifest fragment

`13 §3.1`'s, with its comments, which are load-bearing:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">

    <!-- Proven safe by G0. Play Billing is binder IPC to the Play Store app,
         which owns the socket. The Play Store's process is not ours. -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />

    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <!-- NOT USE_EXACT_ALARM. Play policy restricts it to alarm/timer and
         calendar apps; Shed Book is neither. 08 §2.9. -->
```

Four things about that fragment, all of which somebody gets wrong:

- **`xmlns:tools` must be declared on the `<manifest>` element.** `flutter create` does not write it,
  because the template needs no tools directive. Without the declaration the build fails on an unbound
  prefix — which is the good outcome. The bad outcome is pasting only the `<uses-permission>` line
  into a file that picked up the namespace in some earlier edit and assuming the job is done.
- **The removal goes in `src/main` and nowhere else.** `src/debug` and `src/profile` keep `INTERNET`
  or hot reload stops working. Build-type manifests outrank `src/main` in the merger, which is what
  makes this safe — `REFERENCES` §22 B19 said *"confirm, do not assume"*, and N02-T01 confirmed it
  against a real debug merger report.
- **The two lines we add are plain `<uses-permission>` elements.** They are ours; there is nothing to
  reconcile and no `tools:` attribute belongs on them.
- **The `<application>` block stays untouched in this commit.** `13 §3.1` elides it deliberately and
  says why — *"a truncated manifest is a manifest somebody pastes."* The receivers are `08 §8.3`'s and
  they land in N31-T02.

### 5.4 The anchor test, in outline

Real names, because N31-T03 extends this file.

```dart
// test/policy/permission_set_test.dart — decision-record §3.3; 13 §2.2, §2.3.
// `flutter test` runs with the package root as the working directory, so these
// paths are relative and no asset bundle is involved.
@Tags(['policy'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _expectedFile = 'android/expected_permissions.txt';
const _decisions = 'docs/research/00-tech-decisions.md';

/// The uncommented entries, inline comments stripped. A line is an entry only
/// if its first non-space character is not `#`.
Set<String> _expectedEntries() => File(_expectedFile)
    .readAsLinesSync()
    .map((l) => l.split('#').first.trim())
    .where((l) => l.isNotEmpty)
    .toSet();

/// The permission names in decision-record §3.3's fenced block, minus the ones
/// the block itself marks ABSENT. Sliced from the `### 3.3` heading to the next
/// `### ` — never whole-file: §3.2 and §3.4 name permissions in prose.
Set<String> _recordedEntries() { /* ... */ }

/// Entry lines whose inline comment does not name a contributing library.
Iterable<String> _entriesWithNoSource() { /* ... */ }

void main() {
  test('expected_permissions.txt matches the G0 record exactly', () {
    expect(File(_expectedFile).existsSync(), isTrue,
        reason: '$_expectedFile is missing — G0 is recorded, so it must exist');
    expect(_expectedEntries(), equals(_recordedEntries()));
    expect(_expectedEntries(), isNot(contains('android.permission.INTERNET')),
        reason: 'INTERNET is asserted by its ABSENCE; a real line here voids the claim');
    expect(_entriesWithNoSource(), isEmpty,
        reason: '13 §2.2: every line names the library that contributes it');
  });
}
```

**Why it reads decision-record §3.3 and not `13 §2.2`'s table.** Both carry the same set, and picking
the wrong one costs you a shared parser. §3.3 is a fenced block of bare names — trivially parseable,
and `08 §8.3` calls it *"the authority"* in those words. `13 §2.2`'s row 1 is a markdown table cell,
and `test/policy/g0_recorded_test.dart` already holds it equal to §3.3 (N02-T01's case: *"row 1's set
is decision-record §3.3's set, spelling for spelling"*). Chaining through §3.3 gives the same
guarantee with one parser instead of two, and the failure message names a document a human can read.

### 5.5 The details that are easy to get wrong

- **Eight entries, seven lines.** `13 §2.2` states it and then states why it matters: *"confusing them
  is how somebody adds a ninth line to make a red build green."* Eight is decision-record §3.3's
  table, which counts `INTERNET`. Seven is uncommented lines in this file, because `INTERNET` is
  asserted by its absence. If N02-T02 ruled that `ACCESS_NETWORK_STATE` stays, the two numbers become
  nine and eight. Write both numbers into the commit message.
- **A missing `#` turns a comment into an entry, silently.** The `INTERNET` note is a two-line comment
  whose continuation is indented under its own `#`. Drop that second `#` and the parser reads a bare
  prose fragment as a permission name, the test goes red on something that looks like nonsense, and
  the instinct is to blame the test. Both lines start with `#`.
- **`com.android.vending.BILLING` does not contain the substring `permission`.** Any filter written as
  `grep permission` drops the single entry the monetization decision contributed — the one whose
  transitive Gradle graph must be re-reviewed on every Billing Library bump. `13 §2.2` calls this out
  twice, in two separate code blocks, because two separate people wrote it.
- **Compare as sets, never as sorted text.** `sort` is locale-sensitive; a developer with a UTF-8
  collation and a runner in the `C` locale can disagree about ordering without disagreeing about
  content, and a test that fails on ordering is a test somebody weakens. The **file** is sorted so a
  human can read a diff; the **assertion** is set equality. It is also why G1's shell script sorts both
  sides before comparing.
- **Inline comments are why the shipped G1 script does not work as printed** — worth knowing now,
  while you are choosing this file's shape. `13 §2.3`'s script strips whole-line comments with
  `grep -v '^\s*#'` and then diffs the survivors against bare permission names, so every line's
  ` # flutter_local_notifications (merged)` tail lands in the diff. The fix belongs in the **script**
  (N31-T03 §5.4). Do **not** pre-empt it by dropping the comments here: `13 §2.2` requires every line
  to name its contributing library, and that provenance is the only reason the file is readable in
  month six.
- **N02-T03's guard must still be green after this commit.** `test/policy/g0_recorded_test.dart` bans
  `tools:node="remove"` *while `13 §2.2`'s table reads UNVERIFIED*. The table is filled, so the
  precondition is false and the guard passes without ever looking at your manifest. That is correct
  behaviour and it is also indistinguishable from a broken guard — run it explicitly in §8, and if it
  goes red, the table was reverted, not the manifest.
- **The removal-directive family is wider than the one spelling you are writing.** N02-T03's regular
  expression already matches `tools:node="removeAll"` and `tools:remove="…"`. Write the narrow,
  correct one; never reach for `removeAll`, which deletes every element of that type including ones a
  future plugin adds for a reason.
- **`tool/check_policy.dart` cannot see this file or this manifest.** Its roots are `lib/` and `test/`
  and it reads `.dart` files. `08 §9` is explicit that widening the roots to `android/` is the wrong
  fix, because the source manifest is not what ships. Everything mechanical about `android/` in this
  project is either a `test/policy/` assertion over text, or G1 over the built artefact.
- **This file is one of exactly two `CLAUDE.md` names as un-editable to silence a gate.** The other is
  `tool/check_policy.dart`. When G1 goes red in month six the correct sequence is: read
  `manifest-merger-release-report.txt` (G4) to find the contributing library, decide whether that
  library stays, then change the **dependency** — or accept the permission with a recorded reason and
  a store-listing consequence. The file changes last, never first.
- **Do not add `ACCESS_NETWORK_STATE` "just in case".** Either G0 saw it or it did not, and N02-T02
  ruled. An entry added on faith is exactly the ninth line §2.2 warns about, and it silently adds
  *"view network connections"* to the Play listing of an app whose entire pitch is that it cannot.

### 5.6 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/permission_set_test.dart` | `'expected_permissions.txt matches the G0 record exactly'` | **the anchor.** An entry in one document and not the other; a line with no contributing library; `INTERNET` present as a real line |
| `test/policy/permission_set_test.dart` | *edge* — the file is absent | fails, never skips. `13 §2.3` gives exit 2 to *"the gate could not run"* and calls it *"still a failure, never a skip"*; the Dart tier keeps the same posture |
| `test/policy/permission_set_test.dart` | *edge* — §3.3 is sliced from its own heading only | §3.2's gate table and §3.4's exceptions table both name permissions in prose; a whole-file scan reads those as entries and is red forever |
| `test/policy/permission_set_test.dart` | *edge* — comparison is by **set**, not by sorted string | locale-dependent ordering must not turn a real regression into noise, or noise into a green |
| `test/policy/permission_set_test.dart` | *edge* — a commented line is never an entry, and an entry always carries an inline comment | the two failure shapes a hand-edited text file actually produces |
| `test/policy/g0_recorded_test.dart` | `'no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED'` (N02-T03, unchanged) | re-run here: this is the commit where the directive legitimately lands, and the guard must pass because the precondition is false, not because somebody deleted it |
| *drill, not a case* | add `android.permission.CAMERA` to the expected file and run the anchor | the set comparison fires in the *added* direction as well as the *missing* one |
| *drill, not a case* | delete one line's inline comment | the provenance requirement is real and not decorative |

The drills are run by hand, watched to fail, and reverted; they are not committed. Planting a
violation, confirming the failure and deleting the file is `00-README` §9 step 1's own method.

**Nothing in this task is time-shaped.** No instant is computed, stored or formatted; the only date
anywhere near it is the *Recorded on* cell N02-T01 wrote, which is read as a sentinel and never as a
time. There is therefore no `test/domain/uk_zone/` case to add, and adding one to hit a quota would be
noise. The ambiguous **01:00–01:59** hour belongs to the domain tier and to
`test/data/reminder_dst_test.dart`.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Never edit `android/expected_permissions.txt` to make a build pass** (`CLAUDE.md`; `13 §2.3`). It is one of two files with that status. The correct response to a red G1 is the merger report, then the dependency, then — with a recorded reason — the file.
- **The permitted public wording is fixed and verbatim** (decision-record §3.1). This commit is what makes its second sentence true. Never write *"your data never leaves your phone"*, never write *"offline-first"* — in code, in comments or in the commit message.
- **`USE_EXACT_ALARM` is a Play-policy rejection** (`08 §2.9`), not a trade-off. `SCHEDULE_EXACT_ALARM` is the user-granted one, and it is the one this manifest declares.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'expected_permissions.txt matches the G0 record exactly'` passes, and was seen to fail first for the stated reason
- [ ] the file matches G0's recorded set, entry for entry
- [ ] `INTERNET` is absent
- [ ] no entry was added to make anything pass
- [ ] every uncommented line carries an inline comment naming its contributing library
- [ ] the `tools` namespace is declared on the `<manifest>` element, and the removal directive exists in `src/main` only
- [ ] `test/policy/g0_recorded_test.dart` is still green after the commit
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/permission_set_test.dart
fvm flutter test test/policy/g0_recorded_test.dart
grep -c '^[^#]' android/expected_permissions.txt
git diff --stat -- lib/ ios/ pubspec.yaml pubspec.lock
make check
make test
```

The third command must print **7** — or **8** if N02-T02 ruled that `ACCESS_NETWORK_STATE` stays. The
fourth must print nothing: this task reaches no layer and touches no dependency.

Then the drill, watched and reverted:

```bash
printf '%s\n' 'android.permission.CAMERA  # planted' >> android/expected_permissions.txt
fvm flutter test test/policy/permission_set_test.dart
git checkout -- android/expected_permissions.txt
fvm flutter test test/policy/permission_set_test.dart
```

The second command must **fail**, naming `CAMERA`; the fourth must pass. `git status` is clean before
the commit.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(android): expected_permissions.txt from the G0 record`
