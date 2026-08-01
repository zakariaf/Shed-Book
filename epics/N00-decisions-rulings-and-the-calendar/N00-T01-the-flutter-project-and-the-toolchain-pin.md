# N00-T01 — The Flutter project and the toolchain pin

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 1 of 9 |
| **Depends on** | — (nothing in this backlog precedes it) |
| **Commit** | one commit · `chore: create the flutter project and pin the toolchain to 3.44.8 / 3.12.2` |

## 1. Why this task exists

`flutter create` at the pinned SDK, producing `android/`, `ios/` and a `pubspec.yaml` that
T03 will rewrite. The application id and the bundle id are chosen **once** here and recorded as a
numbered row in the decision record §2 G, because both stores key on them forever. `.fvmrc` pins
Flutter 3.44.8 / Dart 3.12.2 — never the string `stable`, never a caret, never a channel.

This is the first commit in the repository, and it is what makes every later "the first failing test"
line in this backlog literally true: until a test runner exists, no task can watch a test fail.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §1 item 1, §2 A #1, #2 | Flutter 3.44.8 stable (2026-07-23) / Dart 3.12.2, pinned via FVM; and why a bump re-runs the whole resolution matrix |
| `docs/engineering/13-build-ci-release.md` | §1.1, §3.1, §9.1 | the exact `.fvmrc` contents, the three-line CI assert that reads it, and the rule that the application id is fixed once and recorded in `RELEASES.md` |
| `docs/engineering/CONVENTIONS.md` | §1, §4.1 | the package name `shed_book`, the tree this project is later pruned to, and `snake_case.dart` file naming |
| `docs/engineering/00-README.md` | §3.1, §7.1, §9 step 0 | the toolchain row, what is committed, and why step 0 is decisions rather than code |
| `epics/00-PLAN-CRITIQUE.md` | §1 S11, §9 change 2 | no task in the old plan ever created `android/` or `ios/`, which also made G0 impossible before E29 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | owns `.fvmrc`, the pinned stack, and every `pub add` decision |
| `shed-conventions` | fixes the tree, the package name and the identifier spellings before anything is generated into the wrong place |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/toolchain_pin_test.dart`
- **Test** — `'.fvmrc pins 3.44.8 and never the string stable'`
- **Why it is red today** — there is no `.fvmrc`, no `pubspec.yaml` and no test runner. The test is red because the file it reads does not exist.

```bash
fvm flutter test test/policy/toolchain_pin_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — run `flutter create` on the pinned SDK, hand-write `.fvmrc` as `{"flutter": "3.44.8"}`, and
let the test read the file and assert the exact version string and the absence of `stable`, `any`,
`^` and `beta`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

There is one ordering wrinkle and it is worth stating, because it is the only task in the backlog
where it exists. A Dart test cannot run before a test runner does, so the honest sequence is: install
the pinned SDK, `flutter create` (which is toolchain, not feature), **then** write
`toolchain_pin_test.dart` and watch it fail because `.fvmrc` does not exist, **then** hand-write
`.fvmrc`. The red you must actually see is *"Cannot open file `.fvmrc`"*, not *"No pubspec.yaml found"* —
the second is the project missing, which is a different failure and proves nothing.

## 5. What you build

Files in `00-README` §8 order. This task reaches no schema, no domain, no data and no UI layer — it
creates the ground those layers stand on — so the order below is the order the files come into
existence.

| # | File | What changes, and why |
|---|---|---|
| 1 | `.fvmrc` | The whole file is `{ "flutter": "3.44.8" }`, hand-written, exactly as `13 §1.1` prints it. It is committed; `.fvm/` is not (`00-README` §7.2) |
| 2 | `android/` (generated) | `flutter create`'s Android project. `android/app/build.gradle.kts` carries `applicationId` — the string that can never change |
| 3 | `ios/` (generated) | `flutter create`'s iOS project. `ios/Runner.xcodeproj/project.pbxproj` carries `PRODUCT_BUNDLE_IDENTIFIER` in all three build configurations |
| 4 | `pubspec.yaml` (generated) | `name: shed_book`, the SDK constraint, and `flutter create`'s starter dependencies. **T03 rewrites the dependency block from decision-record §5** — do not curate it here |
| 5 | `lib/main.dart`, `test/widget_test.dart`, `analysis_options.yaml`, `.gitignore`, `.metadata` (generated) | Left exactly as generated. N01-T01 prunes to `CONVENTIONS §1`'s tree, N01-T02 rewrites the analyzer block, and N01-T01 writes `.gitignore` from `00-README` §7.2 |
| 6 | `RELEASES.md` | Created with the header block `13 §9.1` specifies. Its first line records the application id / bundle id so nobody has to open a Gradle file to find out what the app is called |
| 7 | `docs/research/00-tech-decisions.md` §2 G | A new numbered row recording the identifier decision, its date, and the two build files that hold the literal — per the amendment rule (`00-README` §10), a decision is not taken until it is in the record |
| 8 | `test/policy/toolchain_pin_test.dart` | The anchor. Written before `.fvmrc` exists |

### The command, spelled out

```bash
fvm install 3.44.8
fvm use 3.44.8                     # then hand-correct .fvmrc to 13 §1.1's exact shape — see below
fvm flutter create \
  --project-name shed_book \
  --org <the org reverse-domain, chosen once, here> \
  --platforms=android,ios \
  --empty \
  .
```

`--project-name shed_book` fixes the Dart package name, and therefore every `package:shed_book/…`
import in the codebase, `build.yaml`'s `databases: shed_book:` key and the database file name
`shed_book.sqlite`. `--org` is what produces the application id and the bundle id: `--org com.example`
gives `com.example.shed_book` on both platforms. `--platforms=android,ios` and nothing else — there is
no web target (decision #23 rejects `go_router` partly on that basis) and no desktop target, and the
offline gates G1–G5 are written for exactly two platforms.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Irreversible** — the application id and the bundle id can never change on either store (`13 §3.1`). Everything else in this task is editable; these two are not.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **`fvm use` may not write `13 §1.1`'s file.** Recent FVM releases write `{"flutterSdkVersion": "3.44.8"}`,
  not `{"flutter": "3.44.8"}`. The key matters: `13 §1.1`'s CI assert is
  `grep -o '"flutter": *"[^"]*"' .fvmrc`, copied verbatim into three workflow files from N01-T06 onward.
  If the installed FVM writes a different key, hand-correct the file to `13 §1.1`'s shape and keep the
  test asserting that shape. A `.fvmrc` the CI assert cannot read is a green pipeline that has proved
  nothing.
- **`flutter create .` in a non-empty directory is fine, and that is the point.** The repository already
  holds `docs/`, `epics/`, `tool/`, `.claude/` and `CLAUDE.md`. `flutter create` adds what is missing and
  leaves what is there. It will still overwrite `analysis_options.yaml` and `.gitignore` if they exist —
  read the diff before you commit, do not assume.
- **`--org` is not a display name and it is not editable later.** It becomes the Kotlin source directory
  `android/app/src/main/kotlin/<org path>/`, the Gradle `applicationId`, the Xcode
  `PRODUCT_BUNDLE_IDENTIFIER` in Debug, Release **and** Profile, and the App Store / Play record's
  identity. Renaming it after the first upload is a new app with no users and no purchase history.
- **Two documents disagree about where the identifier literal lives, and both are right about
  something.** This task's Definition of Done says it appears once in the decision record; `13`'s says it
  *"appears as a literal in no document"* and is recorded in `RELEASES.md`'s header. The resolution that
  satisfies both: the literal lives in `android/app/build.gradle.kts`, the Xcode target and
  `RELEASES.md`'s header; the decision-record row records the **decision**, its date and where the
  literal lives, and does not re-type it in a second spelling. One string, one spelling, three files
  that must agree, and a document that says which three.
- **Debug builds declare `INTERNET` and that is not a regression.** `flutter build apk --debug` produces
  a manifest with `INTERNET` and `ACCESS_NETWORK_STATE` merged from Flutter's own debug manifest; the
  offline claim is about the **shipped release AAB** (G1), and `00-README` §2.1 says so. Do not "fix" it,
  do not grep `build/app/intermediates/` for it — decision #122 names that grep as unsound because the
  directory accumulates debug and profile artifacts. N02-T01 records the debug behaviour deliberately.
- **`flutter create` writes a `test/widget_test.dart` that references the generated app widget.** With
  `--empty` it is still generated and it still compiles today. It is deleted in N01-T01. Until then, do
  not run the whole suite and conclude the tree is broken — run the anchor by path.
- **`flutter pub get` needs a network and always has.** So does `package:sqlite3`'s build hook, once T03
  puts it in the graph — but not yet. A plane-mode failure here is `pub get`, not a regression in the
  offline claim (decision-record §3.4 #3).
- **Nothing in this task is time-shaped.** There is no instant, no civil date and no ambiguous-hour case
  to write; the first DST cases in the backlog are N04-T08's, against 01:00–01:59.

## 7. Definition of Done

- [ ] `'.fvmrc pins 3.44.8 and never the string stable'` passes, and was seen to fail first for the stated reason
- [ ] `fvm flutter --version` prints Flutter 3.44.8 and Dart 3.12.2
- [ ] `android/` and `ios/` exist and `flutter build apk --debug` completes
- [ ] the application id and bundle id appear exactly once, in the decision record, and nowhere else in a different form
- [ ] the test fails if `.fvmrc` is changed to a floating channel
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

`make check` and `make test` do not exist until N01-T05 writes the `Makefile`. In this epic they are
satisfied by §8's commands; from N01 onward they are the two commands that matter.

## 8. Verification

```bash
fvm install
fvm flutter --version
fvm flutter test test/policy/toolchain_pin_test.dart
```

Then prove the negative half — the test must be able to fail:

```bash
cp .fvmrc .fvmrc.bak
printf '{ "flutter": "stable" }\n' > .fvmrc
fvm flutter test test/policy/toolchain_pin_test.dart   # expect: red, naming the floating channel
mv .fvmrc.bak .fvmrc
fvm flutter test test/policy/toolchain_pin_test.dart   # expect: green again
fvm flutter build apk --debug                          # android/ and ios/ are real projects
```

The test set this task ends with is one file and four cases:

| Case | Asserts |
|---|---|
| `'.fvmrc pins 3.44.8 and never the string stable'` | `.fvmrc` parses as JSON, `json['flutter'] == '3.44.8'` |
| `'.fvmrc names no channel and no range'` | the raw text contains none of `stable`, `beta`, `dev`, `master`, `any`, `^`, `>=` |
| `'the .fvmrc key is the one 13 §1.1's CI assert greps for'` | the raw text matches `"flutter": *"3.44.8"`, so the three-line workflow assert can read it |
| `'pubspec.yaml declares the package name CONVENTIONS §1 fixes'` | `name: shed_book`, so no `package:` import has to move later |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: create the flutter project and pin the toolchain to 3.44.8 / 3.12.2`
