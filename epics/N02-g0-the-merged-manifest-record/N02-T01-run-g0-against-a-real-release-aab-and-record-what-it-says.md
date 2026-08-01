# N02-T01 — Run G0 against a real release AAB and record what it says

| | |
|---|---|
| **Epic** | [N02 — G0 — the merged-manifest record](epic.md) · `00-README` §9 step 12, run at 2 |
| **Task** | 1 of 3 |
| **Depends on** | N01-T07 · N00-T03 |
| **Commit** | one commit · `docs: record G0 — the merged manifest from a real release AAB` |

## 1. Why this task exists

`flutter build appbundle --release` with `in_app_purchase` present, then read the merged
manifest and the merger report. Record into `13 §2.2`'s table: the exact `uses-permission` set, which
library contributed each one, whether Play Billing 8.0.0 contributes `ACCESS_NETWORK_STATE`, whether
`src/debug`'s `INTERNET` survives into the release variant, and the effective `minSdk`. Archive the
merger report. **Also record, in `README.md`, which build target trips the `sqlite3` build-hook network
fetch** — decision-record §3.4 #3 and `13 §1.3` both require it by name, and both call the omission a
wasted evening.

One build closes four things `REFERENCES` §22 carries as unverified: **A2** (the Play Billing 8.0.0
AAR manifest, which *"is not published as text and could not be fetched from any primary source"*),
**B19** (whether `tools:node="remove"` in `src/main` leaves `src/debug`'s `INTERNET` intact), **B20**
(which target trips the build-hook fetch) and most of **D8** (the whole four-row table, the effective
`minSdk`, and `flutter_image_compress`'s Android contribution, *"which was never verified at all"*).
`REFERENCES` §22.H ranks it first of the five things to run if only one afternoon is available.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.2 | the three-command procedure verbatim, and the four-row table this task replaces in place |
| `docs/engineering/13-build-ci-release.md` | §2.6, §2.8, §3.1 | the merger report is G4's artefact · the four named anti-patterns · `minSdk` is read, never remembered |
| `docs/engineering/13-build-ci-release.md` | §1.3 | the `sqlite3` build-hook fetch, the cold-cache condition, and the README paragraph it owes |
| `docs/research/00-tech-decisions.md` | §1 #5, §3.2, §3.3, §3.4 #3 | decision #5, G0 as prerequisite, the eight-entry set, the build-machine network exception |
| `docs/engineering/11-monetization-and-store.md` | §3.1, §3.2 | what each layer contributes, and the ruling that the answer is *also* recorded in decision-record §3.3 |
| `docs/engineering/REFERENCES.md` | §22 A2, B19, B20, D8 | the exact claims this build converts into evidence |
| `docs/engineering/00-README.md` | §7.1, §7.2, §7.4 | what is committed, what the `build/` ignore rule swallows, and the commit-message vocabulary |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | `AndroidManifest.xml`, the merger and the permission set are its subject |
| `shed-dependencies-and-toolchain` | which dependency contributes which permission is a dependency-table fact |
| `shed-release` | typed by name, never auto-firing; its description is the only one naming the offline gates G0 to G5 against a real release bundle |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/g0_recorded_test.dart`
- **Test** — `'the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares'`
- **Why it is red today** — every cell in `13 §2.2`'s table reads UNVERIFIED, and the test refuses that word.

```bash
fvm flutter test test/policy/g0_recorded_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — run the build, `bundletool dump manifest` the `.aab`, fill in the table from the output,
and commit the merger report. The test parses `13 §2.2`'s table out of the document on disk, asserts
every *Recorded on* cell is an ISO date, asserts no *Answer* cell contains `UNVERIFIED` or the words
*not yet run*, and asserts the permission set in the first row is the same set — spelling for
spelling — as decision-record §3.3's block, with a contributing library named on every line. It does
**not** re-implement `bundletool`: it holds two documents to the artefact a human read.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. The
two document parsers stay **private top-level functions in this one file** — `12 §10`'s rule for a
format only one file reads — because hoisting them into `test/support/` invites a second caller who
does not know the *Recorded on* column is the sentinel.

## 5. What you build

### 5.1 The procedure, in `13 §2.2`'s order

Run it on a machine with the Android SDK and **JDK 17** (`13 §3.1`). Do not substitute a shorter
pipeline: `11 §3.2` prints a three-line version that pipes `bundletool` straight into
`grep -i "uses-permission"`, and `13 §2.2` is the section that owns the procedure and explains why
that form is not enough.

```bash
# 0. COLD CACHE FIRST — see §5.5. Do this before the build below, or the answer is wrong.
#    Cold means a fresh clone with an empty pub cache; `flutter clean` alone is not cold.
#    Network off, then run these in order and stop at the first that fails:
fvm flutter pub get
fvm flutter test
fvm flutter build appbundle --release
#    `make gen` is NOT in the sweep: at N02 there is no drift database, so `drift_dev
#    make-migrations` has nothing to do. Record that, and let N08 re-check it.

# 1. Network back on. The build that produces the evidence.
fvm flutter build appbundle --release

# 2. The merger's decision tree — it names the source of every permission.
grep -i -A3 'permission' build/app/outputs/logs/manifest-merger-release-report.txt

# 3. The permissions that actually shipped, read off the artefact, not the source.
java -jar bundletool.jar dump manifest \
  --bundle build/app/outputs/bundle/release/app-release.aab > merged-manifest.xml
tr '<' '\n' < merged-manifest.xml | grep '^uses-permission' \
  | grep -o 'android:name="[^"]*"' | sed 's/.*"\(.*\)"/\1/' | sort -u

# 4. The effective minSdk, read — never set from memory (13 §3.1).
tr '<' '\n' < merged-manifest.xml | grep '^uses-sdk'

# 5. B19: does the debug variant keep INTERNET? Uncommitted experiment — see §5.5.
fvm flutter build apk --debug
grep -i -B2 -A6 'INTERNET' build/app/outputs/logs/manifest-merger-debug-report.txt
```

### 5.2 The files this task touches, in order

`00-README` §8's layer order does not apply — this branch reaches no layer. The order below is
**irreversibility order** instead: the document that outranks everything first, the throwaway last.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/research/00-tech-decisions.md` §3.3 | `11 §3.2` rules that the permission set Play Billing 8.0.0 contributes is recorded **here**, not only in 13. The `ACCESS_NETWORK_STATE` line stops reading *"removal PENDING G0"* and states what the artefact declared. The `INTERNET` line stays `ABSENT`, now with evidence behind it. The file is dated and marked FINAL: strike the superseded line **with its reason**, never rewrite it quietly |
| 2 | `docs/engineering/13-build-ci-release.md` §2.2 | the four-row table is **replaced in place** — §2.2 says *"replace this block; do not delete it."* Each row gains an answer and an ISO date. The prose around it about why G0 exists stays: it is what stops the next contributor treating the table as a formality |
| 3 | `docs/gates/manifest-merger-release-report.txt` | the merger report, copied byte-for-byte out of `build/app/outputs/logs/`. It is the only artefact that answers *"which library added that?"* (`13 §2.6`, G4). **Not under a directory named `build`** — see §5.5 |
| 4 | `README.md` | one paragraph naming the target that first needs the network on a cold cache, stating plainly that this is a **build-machine** fact and not a runtime one. `13 §1.3`: without it *"the first offline build failure gets mistaken for a regression, and somebody spends an evening on it"* |
| 5 | `docs/engineering/REFERENCES.md` §22 | A2, B19, B20 and the manifest half of D8 are struck with the answer and the date. An unverified row that has been verified and left standing is how the same afternoon gets spent twice |
| 6 | `test/policy/g0_recorded_test.dart` | **written first** (§4). Created here with one `test()`; N02-T03 adds the second to the same file |

Nothing under `lib/`, no `pubspec.yaml` edit, no lockfile churn. A diff touching any of those in this
commit is a different task wearing this one's message.

~~Nothing under `android/`~~ — **amended 2026-08-01, and it is the one exception.**
`flutter build appbundle --release` fails at `:app:checkReleaseAarMetadata` with *"Dependency
':flutter_local_notifications' requires core library desugaring to be enabled for :app"*, so there is
no `.aab` to read and G0 cannot run at all. Two lines go into `android/app/build.gradle.kts` —
`isCoreLibraryDesugaringEnabled = true` and
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`, both of them `13 §3.1`'s and
already owned by N31-T02 and N24-T06 — and they are **committed, not reverted**, because an archived
merger report describing a tree nobody can rebuild is evidence of nothing. They contribute no manifest
node: `desugar_jdk_libs` appears zero times in the report. Both task files are amended to verify
rather than add.

### 5.3 The table, as it must read afterwards

Replace `13 §2.2`'s block with this shape. The angle-bracketed cells are **fields you fill from the
artefact**, not answers — nobody may pre-fill them from a document, including this one.

| Question | Answer | Recorded on |
|---|---|---|
| Exact `uses-permission` set in the release AAB | `<one line per entry, sorted, each naming its contributing library>` | `<YYYY-MM-DD>` |
| Does Play Billing 8.0.0 contribute `ACCESS_NETWORK_STATE`? | `<yes / no>`, read from `<the merger report line that says so>` | `<YYYY-MM-DD>` |
| Does `tools:node="remove"` in `src/main` leave the `src/debug` `INTERNET` intact? | `<yes / no>`, from the **debug** merger report | `<YYYY-MM-DD>` |
| Effective `minSdk` after plugin merging | `<the number in the merged manifest's uses-sdk element>` | `<YYYY-MM-DD>` |

Two rows have an expected answer, and neither is permission to skip the reading. `13 §3.1` says
`minSdk` is 24, *"`flutter_local_notifications`' floor and the highest in the set"* — if the merged
manifest says anything else, 13 is wrong and the amendment rule fires. `REFERENCES` §22 B19 says
merge priority *should* leave the debug `INTERNET` intact: *"confirm; do not assume."*

### 5.4 The anchor test, in outline

Real names, because the file is created here and N02-T03 extends it.

```dart
// test/policy/g0_recorded_test.dart — decision-record §1 item 5; 13 §2.2.
// `flutter test` runs with the package root as the working directory, so these
// paths are relative and no asset bundle is involved.
const _thirteen = 'docs/engineering/13-build-ci-release.md';
const _decisions = 'docs/research/00-tech-decisions.md';

/// The four rows of §2.2's table, as (question, answer, recordedOn).
/// Sliced from the `### 2.2` heading to the next `### ` — never whole-file.
List<(String, String, String)> _g0Table() { /* ... */ }

/// The permission names in decision-record §3.3's fenced block.
Set<String> _canonicalPermissions() { /* ... */ }

/// The permission names inside one table cell.
Set<String> _permissionsIn(String cell) { /* ... */ }

void main() {
  test('the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares', () {
    final rows = _g0Table();
    expect(rows, hasLength(4), reason: '13 §2.2 fixes four questions');
    for (final (question, answer, recordedOn) in rows) {
      expect(answer, isNot(contains('UNVERIFIED')), reason: question);
      expect(answer.toLowerCase(), isNot(contains('not yet run')), reason: question);
      expect(recordedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')), reason: question);
    }
    // Row 1's set is decision-record §3.3's set, spelling for spelling.
    expect(_permissionsIn(rows.first.$2), equals(_canonicalPermissions()));
  });
}
```

### 5.5 The details that are easy to get wrong

- **A directory named `build` under `docs/` is silently swallowed.** `00-README` §7.2 ignores
  `build/` *"and every artefact under it"*, and an ignore entry written without a leading solidus
  matches a directory of that name **at any depth** — so a report placed in `docs/build/` is ignored,
  `git add` says nothing, and the archive that is this task's whole point is absent from the merge.
  Use `docs/gates/`, and prove it:
  `git check-ignore -v docs/gates/manifest-merger-release-report.txt` must find nothing (exit 1). The
  basename is kept from the generated file so a reader can see it was copied and not retyped.
- **Answering B19 means writing the one line decision #5 forbids.** You cannot observe what
  `tools:node="remove"` does to the debug variant without writing it. Decision #5 bans **committing**
  it, not trying it: write it into `android/app/src/main/AndroidManifest.xml`, build the debug APK,
  read the debug merger report, revert the file. `git diff --cached` before the commit must show no
  manifest change at all. The real line is N31-T01's, and N02-T03's guard is what stops it landing
  early.
- **Do not filter the dump on the substring `permission`.** `13 §2.2` spells out why: it would miss
  `com.android.vending.BILLING`, the one entry this project cares most about. Split on `<` first and
  select the `uses-permission` **element** — which also catches `<uses-permission-sdk-23>`,
  deliberately.
- **`bundletool dump manifest` emits XML on very few lines.** A line-oriented `grep` over its raw
  output can appear to find nothing at all. That is what `tr '<' '\n'` is for; it is not a stylistic
  preference.
- **Read the artefact, never `build/app/intermediates/`.** `13 §2.8` names four anti-patterns and
  this is the first: that directory accumulates debug and profile artefacts, and Flutter's debug and
  profile manifests *do* declare `INTERNET`, so a grep there fires on a stale directory and is then
  deleted for being flaky. `apkanalyzer` on an APK is the second — the APK is not what ships.
- **The cold-cache observation is destroyed by doing it second.** `package:sqlite3`'s build hooks
  download a sha256-verified binary from GitHub and cache it, *"so a warm laptop builds in plane
  mode."* Build online first and every plane-mode target passes, and you record that nothing needs
  the network. Do the sweep first, on a fresh clone with an empty pub cache — `13 §1.3` gives the
  cold condition as *"a fresh clone, a new pub cache, or after `flutter clean`"*, and only the first
  two are genuinely cold, because `flutter clean` does not empty `~/.pub-cache`.
- **`make gen` cannot be swept at N02, and the README paragraph must say so.** There is no
  `lib/core/db/database.dart` yet, so `drift_dev make-migrations` has nothing to generate. Record the
  answer for `pub get`, `test` and `build`; if `pub get` is the first to need the network then B20 is
  closed outright, and if it is not, say in the README that `gen` was untestable here and that N08
  re-checks it. A half-answered paragraph that does not admit which half is missing is worse than
  none.
- **The release AAB is debug-signed at this epic, and that is correct.** The generated
  `android/app/build.gradle.kts` points the release build type at the debug signing config. Signing
  is N32's. It changes not one byte of the merged manifest, and adding a signing config here is scope
  this task does not have.
- **Eight entries, seven lines.** `13 §2.2`: eight is decision-record §3.3's table; seven is the
  uncommented lines `android/expected_permissions.txt` will hold, because `INTERNET` is asserted by
  its *absence*. Same fact counted two ways, and *"confusing them is how somebody adds a ninth line
  to make a red build green."* If billing contributes `ACCESS_NETWORK_STATE` it becomes nine and
  eight. Write both numbers down.
- **`flutter_image_compress` has never been checked.** `REFERENCES` §22 D8 says so in those words. Do
  not assume the merger report will show only the six libraries the doc set lists.
- **The record is true of one dependency set.** It describes the `pubspec.lock` in the tree on the day
  you built. That is not a weakness to hedge in prose — it is exactly what G1 (N31-T03) exists to
  catch on every push afterwards.

### 5.6 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/g0_recorded_test.dart` | `'the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares'` | a half-filled table, a permission recorded in one document and not the other, a line with no contributing library |
| `test/policy/g0_recorded_test.dart` | *edge* — the table is sliced from §2.2 only | `13` carries the word UNVERIFIED in two other places: §2.3's `bundletool` note and a comment inside §4.3's YAML. A whole-file scan is red forever, and then gets weakened by whoever hits it |
| `test/policy/g0_recorded_test.dart` | *edge* — an absent or unparseable `13 §2.2` fails, never skips | `13 §2.3` on G1: a gate that could not run *"is still a failure, never a skip"* |
| `test/policy/g0_recorded_test.dart` | *edge* — row 1 is compared as a **set**, not as a string | whitespace and ordering churn in a markdown table must not turn a real regression into noise, or noise into a green |

Nothing in this task is time-shaped: no instant is computed, stored or formatted, so there is no
`test/domain/uk_zone/` case to add, and adding one to hit a quota would be noise. The first cases in
the ambiguous **01:00–01:59** hour arrive with the domain in N04.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **The build machine is not the app.** `flutter pub get` and the `sqlite3` build hooks need a network; the shipped binary has none. The README paragraph must say which is which — conflating them is how the central claim gets softened by somebody being careful.
- **No `tools:node="remove"` is committed** (decision-record §1 item 5). The experiment in §5.5 is reverted before the commit, and `git diff --cached` proves it.
- **The amendment rule** — decision-record §3.3 and `13 §2.2` change in the *same* commit, and every document naming decision #5 is grepped: `11 §3.1` and §3.2, `08 §11` items 7, 13 and 14, `REFERENCES` §22, `CODE-REVIEW-CHECKLIST`. A superseded line is struck with its reason, never quietly rewritten.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares'` passes, and was seen to fail first for the stated reason
- [ ] every cell in the table is filled from a real `.aab`, not from documentation
- [ ] each permission names the library that contributed it
- [ ] the effective `minSdk` is recorded
- [ ] `README.md` names the target that trips the `sqlite3` build-hook fetch
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

In order. Steps 1 to 3 produce the evidence; 4 to 8 prove it was recorded honestly.

```bash
fvm flutter build appbundle --release
java -jar bundletool.jar dump manifest --bundle build/app/outputs/bundle/release/app-release.aab > merged-manifest.xml
tr '<' '\n' < merged-manifest.xml | grep '^uses-permission' | grep -o 'android:name="[^"]*"' | sed 's/.*"\(.*\)"/\1/' | sort -u
git check-ignore -v docs/gates/manifest-merger-release-report.txt
git diff --cached -- android/
fvm flutter test test/policy/g0_recorded_test.dart
make check
make test
```

`git check-ignore` must print nothing and exit 1; `git diff --cached -- android/` must be empty. Then
read the archived report yourself, top to bottom, once — `13 §12` item 1 makes that a permanent
release-checklist item for exactly this reason: *"Do not just trust that G1 was green."*

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: record G0 — the merged manifest from a real release AAB`
