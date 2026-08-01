# N00-T03 — `pubspec.yaml` from decision-record §5, and the committed lockfile

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 3 of 9 |
| **Depends on** | N00-T02 |
| **Commit** | one commit · `chore: author pubspec.yaml from decision-record §5 and commit the resolved lockfile` |

## 1. Why this task exists

Every dependency authored from decision-record §5.1 and §5.2 **verbatim** —
`flutter_riverpod: 2.6.1` with no caret, `drift 2.34.2` / `drift_dev 2.34.5` / `sqlite3 3.5.0`,
`build_runner: ">=2.15.0 <2.15.2"`, `flutter_lints 6.0.0` — plus the `assets/content/` and
`assets/fonts/` declarations the seed and the typography will need. `flutter pub get` then produces
`pubspec.lock`, which is committed as decision #5's evidence that the table resolves at all.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §5.1, §5.2, §5.3 | every version, verbatim; the rejected list with its reasons; *"No version in this project may come from any other source, including memory"* |
| `docs/research/00-tech-decisions.md` | §1 item 5, §2 A #3, #4, #5 | commit the lockfile as evidence; `build_runner` cannot be `^2.15.2`; `package:test` is never a direct dependency |
| `docs/engineering/13-build-ci-release.md` | §1.2, §1.3, §2.4 | the lockfile-is-evidence rule and the review stop, the cold-cache build-hook fetch, and G2's three allowlist sections |
| `docs/engineering/CONVENTIONS.md` | §1 | `assets/fonts/`, `assets/content/` and the package name the pubspec declares |
| `docs/engineering/00-README.md` | §3.2, §3.3, §7.1 | the stack at a glance and the rule that `pubspec.lock` is committed |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | decision-record §5 is the only source of a version number and this skill is its guard |
| `shed-conventions` | the asset paths and the package name are names, and names are its authority |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/lockfile_is_evidence_test.dart`
- **Test** — `'pubspec.lock pins flutter_riverpod to exactly 2.6.1 and declares no package:test'`
- **Why it is red today** — `flutter create`'s generated pubspec carries `cupertino_icons` and caret ranges, and no lockfile is in git.

```bash
fvm flutter test test/policy/lockfile_is_evidence_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — rewrite the dependency block from §5, delete what §5.3 rejected, run `flutter pub get`, and
commit the lockfile in the same commit as the pubspec that produced it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

| # | File | What changes, and why |
|---|---|---|
| 1 | `pubspec.yaml` | The dependency block replaced wholesale from decision-record §5.1 and §5.2. `cupertino_icons` deleted (nothing in the design system uses it and it is not in §5). The `flutter:` section gains `assets:` for `assets/content/` and `assets/fonts/` |
| 2 | `assets/content/.gitkeep`, `assets/fonts/.gitkeep` | Git does not track empty directories, and `flutter build` fails on a declared asset directory that does not exist. Two empty files, deleted the moment real content lands |
| 3 | `pubspec.lock` | Produced by `fvm flutter pub get` and **committed in this same commit**. It is decision #5's evidence, and a lockfile diff in a PR that does not also change `pubspec.yaml` is a review stop (`13 §1.2`) |
| 4 | `README.md` | The one paragraph `13 §1.3` requires by name: which command first trips `package:sqlite3`'s build-hook download on a cold cache, established by one plane-mode run. This task is the first moment `sqlite3` is in the graph, so it is the first moment the answer exists |
| 5 | `test/policy/lockfile_is_evidence_test.dart` | The anchor. It reads the **lockfile**, not the pubspec — the pubspec is what you asked for, the lockfile is what you got |

### The dependency block, as decision-record §5 gives it

```yaml
name: shed_book
description: A lambing notebook for a phone. Offline only.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.12.2
  flutter: 3.44.8

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  flutter_riverpod: 2.6.1          # EXACT. Not ^2.6.1. Decision #17
  drift: 2.34.2
  drift_flutter: 0.3.1
  sqlite3: 3.5.0
  path_provider: 2.1.6
  uuid: 4.6.0
  clock: 1.1.2
  intl: any                        # flutter_localizations pins 0.20.2 exactly. Decision #108
  flutter_local_notifications: 22.2.0
  timezone: 0.11.1
  wakelock_plus: 1.7.0
  image_picker: 1.2.3
  flutter_image_compress: 2.5.1
  file_selector: 1.1.0
  record: 7.1.1
  pdf: 3.13.0
  archive: 4.0.9
  share_plus: 13.3.0
  in_app_purchase: 3.3.0
  device_info_plus: 13.2.0
  logging: 1.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: 2.34.5
  build_runner: ">=2.15.0 <2.15.2"
  flutter_lints: 6.0.0
  mocktail: 1.0.5
  accessibility_tools: 2.8.0
  glados: 1.1.7
  golden_screenshot: 11.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/content/
```

**Why bare versions and not carets.** Decision-record §5 is *"the only source of version numbers"* and
§2 A #1 says any bump *"re-runs the full resolution matrix"*. A caret admits a version §5 has not
verified, which is the one thing §5 exists to prevent. So every runtime and dev package is written at
exactly the §5 version, `intl` is `any` (because `flutter_localizations` pins `0.20.2` exactly and
`^0.20.3` will not resolve), and `build_runner` carries the range verbatim. If you want carets, that is
an amendment to §5, not a formatting preference.

**There is no `fonts:` block yet.** `assets/fonts/` holds nothing until N09-T05 bundles
`AtkinsonHyperlegibleNext[wght].ttf` and `OFL.txt`. A `fonts:` family block names a *file*, and
`flutter build` fails on a missing one — an `assets:` directory entry only needs the directory. Add the
family in the task that adds the font.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Every version from §5, none from memory** — decision-record §5's header states it as a rule, and four of the ten research notes recommended a `build_runner` constraint that does not resolve.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **`package:test` is not "missing"; it is banned.** `flutter_test` does **not** depend on it (decision
  #4). Declaring it caps `analyzer < 13.0.0`, which breaks `drift_dev` 2.34.5, and `test 1.31.2` pins
  `test_api 0.7.13` and cannot coexist with `flutter_test` at all. It will still appear in
  `pubspec.lock` **transitively**; the assertion is about the `dependency:` kind, never about presence.
- **There is no YAML parser available to the test.** `yaml` is not in decision-record §5, and importing
  a transitive package from `test/` is the kind of thing G2's `[transitive]` section exists to police.
  Write a ~15-line line scanner over `pubspec.lock` — it is a generated file with a flat, stable shape
  (`  <name>:` / `    dependency: "direct main"` / `    version: "2.6.1"`). Same posture as decision
  #82's hand-rolled CSV writer: fifty lines you control beat a package you have to justify.
- **Never assert "no `http` in `pubspec.lock`".** It is unsatisfiable — `http 1.6.0` sits on two regular
  edges via `timezone` and `package_info_plus` — and `13`'s Definition of done bans the gate by name.
  The offline proof is G1 + G2 + G3, not the lockfile's package list.
- **`sqlite3_flutter_libs` will be in the lockfile and that is expected.** It arrives transitively via
  `drift_flutter` 0.3.1 as a no-op `+eol` shim. pub.dev's `isDiscontinued` flag is **false** for it, so a
  CI check keyed on that flag will never fire (decision #26). It goes in G2's `[transitive]` section
  with its reason in N03-T04 — it never goes in `dependencies`.
- **`accessibility_tools` is a dev dependency that `lib/` imports.** It is a widget that wraps the app
  tree, so `lib/app.dart` will import it behind `kDebugMode` at N11. That trips the
  `depend_on_referenced_packages` lint and looks like a mistake to a reviewer. Decision-record §5.2 says
  to note it explicitly and allowlist it; the note belongs here, in the commit that admits the package.
- **`golden_screenshot` belongs to `tool/`, not `test/`** (§5.2). It is declared here and used nowhere
  until store screenshots are produced.
- **`flutter pub get` needs a network, and so does `package:sqlite3`'s first build.** The build hooks
  download a sha256-verified prebuilt binary from GitHub on a **cold** cache — a fresh clone, a new pub
  cache, or after `flutter clean` — and cache it afterwards, so a warm laptop builds in plane mode
  (decision-record §3.4 #3). **Which** command trips it first is unverified in the doc set and `13 §1.3`
  asks for the answer in the README. Find it once, here, in plane mode; without that paragraph the first
  offline build failure gets mistaken for a regression and somebody spends an evening on it.
- **The lockfile and the pubspec are one commit or neither.** `13 §1.2`: a lockfile diff in a pull
  request that does not also change `pubspec.yaml` is a review stop, because something upstream moved
  and you are about to ship it.
- **Do not run `flutter pub upgrade`.** It will happily move a package off a §5 version and produce a
  lockfile that is evidence of something nobody decided.
- **Nothing in this task is time-shaped.** No instant, no civil date, no ambiguous-hour case.

## 7. Definition of Done

- [ ] `'pubspec.lock pins flutter_riverpod to exactly 2.6.1 and declares no package:test'` passes, and was seen to fail first for the stated reason
- [ ] every version matches decision-record §5 exactly, including the `build_runner` range
- [ ] `flutter_riverpod` is `2.6.1` with no caret and no range
- [ ] `pubspec.lock` is committed and the test reads it, not the pubspec
- [ ] `package:test` appears nowhere; the test tier is `flutter_test`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter pub get
fvm flutter test test/policy/lockfile_is_evidence_test.dart
```

Then read the evidence yourself, because the whole point of decision #5 is that somebody has:

```bash
grep -A2 '^  flutter_riverpod:' pubspec.lock     # version: "2.6.1", dependency: "direct main"
grep -A2 '^  build_runner:'     pubspec.lock     # version: "2.15.0" or "2.15.1", never 2.15.2
grep -B1 -A2 '^  test:'         pubspec.lock     # if present at all, dependency: "transitive"
grep -A2 '^  sqlite3_flutter_libs:' pubspec.lock # dependency: "transitive" — expected, harmless
git status --short pubspec.yaml pubspec.lock     # both staged, in the same commit
```

The test set this task ends with, one file and six cases:

| Case | Asserts |
|---|---|
| `'pubspec.lock pins flutter_riverpod to exactly 2.6.1 and declares no package:test'` | the anchor: `flutter_riverpod` is `direct main` at `2.6.1`, and no package named `test` is `direct main` or `direct dev` |
| `'build_runner resolves inside the range decision #3 fixes'` | the resolved version is `>= 2.15.0` and `< 2.15.2` |
| `'every package in decision-record §5.1 is a direct main dependency at its §5 version'` | the table is read from a fixture list in the test, so a version drifting anywhere goes red |
| `'every package in decision-record §5.2 is a direct dev dependency at its §5 version'` | the same, for the seven dev packages |
| `'no package from §5.3 is a direct dependency'` | `printing`, `google_fonts`, `csv`, `permission_handler`, `file_picker`, `go_router`, `freezed`, `mockito`, `sqlite3_flutter_libs` are absent from both direct sections |
| `'the test makes no claim about http'` | a deliberate documentation case: `http` is asserted only to be **transitive**, never absent |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: author pubspec.yaml from decision-record §5 and commit the resolved lockfile`
