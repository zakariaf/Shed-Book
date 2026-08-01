# N01-T01 — Prune to the `CONVENTIONS §1` tree and write `.gitignore`

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 1 of 7 |
| **Depends on** | N00-T03 |
| **Commit** | one commit · `chore: prune to the CONVENTIONS §1 tree and write .gitignore` |

## 1. Why this task exists

`flutter create` produced `lib/main.dart` and `test/widget_test.dart` and none of
`CONVENTIONS §1`'s folders. Create the tree — `lib/{core,data,domain,features,l10n,routing}`,
`test/{domain,data,drift,design,features,policy,support,fixtures}`, `integration_test/`, `tool/` —
delete the samples, and write `.gitignore` from §7.2 so the keystore, `.fvm/`, `build/` and the
obfuscation symbols can never be committed by accident.

The half of this task that will actually hurt if it is wrong is the other direction. `.gitignore`
decides what can never be **lost**, and five of the paths a fresh clone must carry look exactly like
build output: `pubspec.lock`, `drift_schemas/drift_schema_v<N>.json`,
`lib/l10n/app_localizations*.dart`, `test/drift/generated/**` and `test/features/goldens/*.png`. Of
those, `00-README` §7.1 says the schema snapshots are the one whose loss is **unrecoverable** — they
are the migration tests' only baseline and there is no server-side copy of anybody's phone.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/CONVENTIONS.md` | §1 | the folder tree and its `mkdir -p` line, verbatim |
| `docs/engineering/CONVENTIONS.md` | §6 R57, R67 | the test tree, the five banned directory names, and `lib/l10n/` being in the tree |
| `docs/engineering/00-README.md` | §7.1, §7.2 | what is committed and what is ignored — the two halves of this task |
| `docs/engineering/12-testing.md` | §1.4, §11.1 | why this is a `test/policy/` artefact test and not a gate rule; policy tests are named for the property |
| `docs/engineering/01-architecture.md` | §3.2 | the gate walks `lib/` and `test/` only, which is why a root config file is a test's business |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | §1 is the tree and R57 is the test tree; both are its authority |
| `shed-testing` | R57's test tree has five banned directory names and this is where they are refused |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/tree_shape_test.dart`
- **Test** — `'every directory in CONVENTIONS §1 exists and none of the five banned test directories does'`
- **Why it is red today** — the generated tree has none of §1's folders and `test/widget_test.dart` still exists.

```bash
fvm flutter test test/policy/tree_shape_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — run `CONVENTIONS §1`'s `mkdir -p` line verbatim, put a `.gitkeep` in every leaf that
holds no file yet, delete the generated samples, write `.gitignore`, and let the test assert both
directions — the directories that must exist and the five names that must not.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8's order is schema → domain → data → wiring → controller → UI → ARB → tests. This task reaches
**none** of those layers: it creates the directories they will live in and nothing that compiles.
Say so in the commit message; there is no schema step here because there is nothing stored yet.

| # | Path | What changes, and why |
|---|---|---|
| 1 | the tree itself | `CONVENTIONS §1`'s `mkdir -p` block, run verbatim from the repository root. Do not retype it from the ASCII tree above it in that file — the `mkdir` line is the executable form and the two are kept in step deliberately |
| 2 | `<leaf>/.gitkeep` in every directory that holds no file yet | git tracks files, not directories. Without these, a fresh clone reproduces `lib/`, `test/` and four others and none of the twenty-odd leaves, and the anchor test passes on your machine and fails on CI |
| 3 | `lib/main.dart` | the generated counter app is deleted down to an entry point that compiles and paints nothing: `void main() => runApp(const SizedBox.shrink());`. The real ~20-line `main()` is `01-architecture.md` §6's and is written in **N11**. Leaving the sample means `flutter analyze --fatal-infos` in N01-T02 fails on demo code, and deleting the file entirely means `flutter build apk --debug` — which N00-T01's Definition of Done already asserts — has no entry point |
| 4 | `lib/app.dart` | **not created.** `ShedBookApp` is N11's; a placeholder here would be a second file N11 has to delete |
| 5 | `test/widget_test.dart` | deleted. It references `MyApp`, which no longer exists, and its location mirrors nothing in `lib/` |
| 6 | `.gitignore` | rewritten from `00-README` §7.2. `flutter create` left one behind; it is a starting point, not the answer |
| 7 | `test/policy/tree_shape_test.dart` | the anchor, written first |

`CONVENTIONS §1`'s `mkdir -p` block, with its one feature line expanded into a loop so the nine
feature directories are visible as a list:

```bash
mkdir -p lib/l10n \
         lib/domain/{time,units,withdrawal,stats,validation,terminology,policy} \
         lib/core/{db/{tables,seed},time,log,ui/components} \
         lib/data lib/routing \
         tool drift_schemas assets/{fonts,content} \
         test/{domain/uk_zone,data,drift/generated,design,features,policy,support,fixtures} \
         integration_test

for f in quick_entry flock lambing pens treatments reminders season export settings; do
  mkdir -p "lib/features/$f/widgets"
done
```

### 5.2 The two lists the anchor test holds

**Must exist** — every leaf in `CONVENTIONS §1`. **Must not exist** — the five banned names, each
because its content already has a home:

| Banned | Where that content actually goes | Authority |
|---|---|---|
| `test/screens/` | `test/features/` — the widget tier mirrors `lib/features/` | R57 |
| `test/integration/` | `integration_test/` at the top level — the directory name the SDK package requires | R57 |
| `test/ui/` | `test/design/` for tokens and contrast, `test/features/` for widgets | R57 · CONVENTIONS §1 |
| `test/fakes/` | `test/support/` — the seven hand-written fakes live beside `harness.dart` | 12 §4.2 |
| `test/golden/` | `test/features/goldens/*.png`, beside the widget tests that produce them | 00-README §7.1 |

**`.gitignore`**, from `00-README` §7.2. Six entries plus the keystore itself:

```gitignore
.fvm/                      # the FVM SDK cache. .fvmrc is COMMITTED — one character apart
.dart_tool/
build/
coverage/                  # lcov.info is a CI artefact, never a committed file
android/key.properties     # local only; regenerate from the keystore and its passwords
android/*.jks              # the upload keystore itself
symbols-archive/           # obfuscation symbols — kept forever OFF the laptop, never in git
```

**Never ignored, and the test proves it** (`00-README` §7.1): `pubspec.lock` · `.fvmrc` ·
`Makefile` · `analysis_options.yaml` · `build.yaml` · `l10n.yaml` · `dart_test.yaml` ·
`drift_schemas/` · `lib/core/db/database.g.dart` · `lib/core/db/schema_versions.dart` ·
`lib/l10n/app_localizations.dart` · `test/drift/generated/` · `test/features/goldens/` ·
`test/fixtures/` · `tool/policy_allowlist.txt` · `android/expected_permissions.txt` ·
`ios/Runner/PrivacyInfo.xcprivacy`.

### 5.3 What is easy to get wrong here

- **`flutter create` wrote more than one ignore file.** There is an `android/.gitignore` and an
  `ios/.gitignore` as well as the root one, and `android/.gitignore` already contains
  `key.properties` and `**/*.keystore`. A test that reads the text of the root `.gitignore` alone
  is testing one of three files. Assert the **effective** answer with
  `git check-ignore <path>` — it exits 0 when a path is ignored and 1 when it is not, it works on
  paths that do not exist yet, and `-v` prints the file and line that decided.
- **The dangerous direction is the one nobody writes a test for.** An ignore line for any directory
  named `generated` reads as tidy and silently drops `test/drift/generated`; `*localizations*` drops
  the committed gen-l10n output; a bare `*.json` drops `drift_schemas` **and** `test/fixtures`.
  Every one of those is invisible until a fresh clone. The must-never-be-ignored list above is the
  more valuable half of the anchor test, not an afterthought.
- **`symbols-archive/` is not "just build output".** Losing an obfuscation symbols directory makes
  every stack trace in every diagnostics log a user ever sends for that build permanently
  unreadable. It is git-ignored *and* kept off the laptop; the ignore line exists so nobody solves
  the second half by committing it.
- **`.fvm/` is ignored and `.fvmrc` is committed.** They differ by one character and the failure is
  silent in both directions: ignore `.fvmrc` and CI's toolchain-pin assert has nothing to read;
  commit `.fvm/` and you have added a Flutter SDK to the repository.
- **Do not add an `assets:` block to `pubspec.yaml` yet.** `assets/fonts/` and `assets/content/` are
  created here and are empty; declaring an empty asset directory in `pubspec.yaml` fails the build.
  The font lands in N09 and the block lands with it.
- **`.gitkeep` under `lib/` is not scanned by the gate** (`01-architecture.md` §3.2 walks `lib/` and
  `test/` and skips anything that is not `.dart`), so it costs nothing. It is deleted from a
  directory the moment that directory gains a real file — leaving both is harmless but reads as an
  oversight.
- **Do not tag this test `policy` yet.** `dart_test.yaml` does not exist until N01-T04, and
  `package:test` prints a warning for every tag that is used but not declared. Add
  `@Tags(['policy'])` to every `test/policy/` file in T04, in one pass, when the tag is real.
- **This is a test and not a gate rule, and that is deliberate.** 12 §1.4's rule — *"if the
  assertion can be made by reading source text, it belongs in `tool/check_policy.dart`"* — is about
  source under `lib/` and `test/`, which is the only thing the gate walks. `.gitignore` and the
  directory tree are artefacts outside that walk, so they are 12 §1.4's second bullet: *"behaviour
  and artefacts are tests."*

### 5.4 The test set

`test/policy/tree_shape_test.dart` — one file, five cases. Nothing in this task is time-shaped, so
there is no `uk-zone` case; the first one lands in N01-T04.

| Test | What it holds |
|---|---|
| `'every directory in CONVENTIONS §1 exists and none of the five banned test directories does'` | the anchor. Both directions in one case, because a test that only checks presence passes on a tree that also has `test/screens/` |
| `'every leaf directory that holds no Dart file holds a .gitkeep'` | the clone reproduces the tree. This is the case that fails on CI and passes locally if it is missing |
| `'no path 00-README §7.1 requires committed is git-ignored'` | `git check-ignore` over the seventeen paths in §5.2. The unrecoverable-loss case |
| `'.gitignore refuses the keystore, .fvm, build output, coverage and the symbols archive'` | `git check-ignore` over `android/key.properties`, `.fvm/flutter_sdk`, `build/app`, `coverage/lcov.info`, `symbols-archive/x` |
| `'the flutter create samples are gone'` | `test/widget_test.dart` does not exist and `lib/main.dart` contains no `MyApp`, no `MyHomePage` and no `_counter` |

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Layers** — the tree *is* `CONVENTIONS §1.1`'s eight layer rules made visible. Every directory
  created here is one the gate will later police the imports of; a directory invented outside §1 is
  a layer rule with no rule id.
- **Offline** — no dependency is added and none may be. The anchor test reads files with `dart:io`
  and shells out to `git`; it adds nothing to `pubspec.yaml`, which stays exactly as N00-T03 closed
  it.

## 7. Definition of Done

- [ ] `'every directory in CONVENTIONS §1 exists and none of the five banned test directories does'` passes, and was seen to fail first for the stated reason
- [ ] every §1 directory exists
- [ ] `test/screens/`, `test/integration/`, `test/ui/`, `test/fakes/` and `test/golden/` do not exist and the test refuses them
- [ ] `.gitignore` carries `android/key.properties`, `.fvm/`, `build/`, `.dart_tool/`, coverage output and `symbols-archive/`
- [ ] no path in `00-README` §7.1 is ignored by any `.gitignore` in the repository, proved by `git check-ignore`
- [ ] a fresh `git clone` of the branch reproduces every directory in `CONVENTIONS §1`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/tree_shape_test.dart
git check-ignore -v android/key.properties .fvm/flutter_sdk build/app coverage/lcov.info symbols-archive/x
git check-ignore -v pubspec.lock drift_schemas/drift_schema_v1.json lib/l10n/app_localizations.dart; echo "exit=$? (1 means none of them is ignored — that is the pass)"
git clone --no-hardlinks . "$TMPDIR/n01t01-clone" && find "$TMPDIR/n01t01-clone/lib" -type d | sort
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: prune to the CONVENTIONS §1 tree and write .gitignore`
