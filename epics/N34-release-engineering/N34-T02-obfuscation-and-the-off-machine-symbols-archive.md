# N34-T02 — Obfuscation and the off-machine symbols archive

| | |
|---|---|
| **Epic** | [N34 — Release engineering](epic.md) · `00-README` §9 step 12 (3 of 3) |
| **Task** | 2 of 4 |
| **Depends on** | N34-T01 |
| **Commit** | one commit · `ci: obfuscation and the off-machine symbols archive` |

## 1. Why this task exists

`--obfuscate --split-debug-info`, and the symbols archived under
`symbols-archive/<name>+<build>/` — **kept forever, off the laptop, never in git**. Losing them makes
every stack trace in every diagnostics log a user sends for that build permanently unreadable.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §8.4 | redaction, why a release trace is unreadable without symbols, and the `flutter symbolize` command with its per-build path |
| `docs/engineering/13-build-ci-release.md` | §9.4 | the artefact table — the symbols row is the only one whose loss cannot be recovered by rebuilding |
| `docs/engineering/13-build-ci-release.md` | §4.4, §6.1 | where the flags go in the workflow; Flutter 3.44's changed `libapp.so` stripping default and its interaction with the size number |
| `docs/engineering/13-build-ci-release.md` | §8.1, §8.6 | why there is no crash reporter to "solve" this with, and why nothing is ever transmitted |
| `docs/engineering/00-README.md` | §7.2 | `.gitignore` — obfuscation symbols are binary, kept forever **off** the laptop, never in git |
| `docs/research/00-tech-decisions.md` | §5, #127 | `--obfuscate --split-debug-info` as a size lever, and the pinned toolchain the mappings belong to |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — the archive and its retention rule |
| `shed-bootstrap-and-errors` | the diagnostics logs the symbols are needed to read |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/release_config_test.dart`
- **Test** — `'the release workflow obfuscates and archives symbols, and symbols-archive is gitignored'`
- **Why it is red today** — a release would ship unobfuscated or lose its symbols.

```bash
fvm flutter test test/policy/release_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the flags, the archive step, the gitignore entry, and the assertion. The assertion holds four
things: `--obfuscate` and `--split-debug-info` appear **together** on every release build command in
every workflow; the AAB build and the size build write to **different** directories; `build/symbols/android`
is in the release artefact upload list; and `symbols-archive/` is git-ignored with no tracked file
beneath it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached. Say so in the commit body. Four files, none of them new — this task
finishes three things N34-T01 deliberately left open and extends its test.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `.github/workflows/release.yml` | edit. `--obfuscate --split-debug-info=build/symbols/android` on the AAB build; `--obfuscate --split-debug-info=build/symbols/android-size` on the size build; `build/symbols/android` added to the artefact upload list. These are the three holes N34-T01 left with named comments |
| 2 | `.gitignore` | N01-T01 wrote it from `00-README` §7.2, which already names the symbols. **Confirm `symbols-archive/` is there and add it if the prune dropped it.** The anchor test holds it either way, so it can never silently disappear |
| 3 | `RELEASES.md` | edit. A `## Symbols` section: the archive layout, the retention rule, and the `flutter symbolize` command with a real path. This is the file somebody opens at release time, which is what *"written where the next person will read it"* means |
| 4 | `test/policy/release_config_test.dart` | extended — the same file N34-T01 created. Do not create a second one |

### 5.2 The commands and the archive layout

The shippable build, with both flags. `--obfuscate` is **not accepted alone**; it requires
`--split-debug-info`.

```bash
flutter build appbundle --release \
  --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
  --dart-define=APP_VERSION="$BUILD_NAME" --dart-define=APP_BUILD="$BUILD_NUMBER" \
  --obfuscate --split-debug-info=build/symbols/android
```

The size build gets its own directory, because it is a throwaway single-ABI build and its mappings are
not the ones that shipped:

```bash
flutter build appbundle --release --analyze-size \
  --target-platform android-arm64 \
  --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
  --obfuscate --split-debug-info=build/symbols/android-size
```

The manual iOS build on your Mac (13 §9.1) uses **the same build number the release workflow produced
for that tag**:

```bash
flutter build ipa --release \
  --build-name=1.0.0 --build-number=187 \
  --dart-define=APP_VERSION=1.0.0 --dart-define=APP_BUILD=187 \
  --obfuscate --split-debug-info=build/symbols/ios
```

Two paths, and they must agree or the archive is a folder of useless files. `build/symbols/` is where
the build wrote them; `symbols-archive/<name>+<build>/` is where you kept them:

```
symbols-archive/
└── 1.0.0+187/
    ├── android/        ← the whole of build/symbols/android from the release run's artefact.
    │                     One .symbols file PER ABI — arm64, arm, x64.
    └── ios/            ← build/symbols/ios, copied by hand from the Mac that built the IPA.
```

Reading a trace back, months later, off a log a shepherd emailed you:

```bash
flutter symbolize -i crash.txt -d symbols-archive/1.0.0+187/ios/app.ios-arm64.symbols
flutter symbolize -i crash.txt -d symbols-archive/1.0.0+187/android/app.android-arm64.symbols
```

The `RELEASES.md` section, in the words that make the rule stick:

```markdown
## Symbols

Every release build is `--obfuscate`d, so a stack trace in a user's diagnostics log is unreadable
until it is symbolized against the symbols for **that exact build number**.

- Download `build/symbols/android` from the release run's artefact.
- File it as `symbols-archive/<build-name>+<build-number>/android/`, every ABI, not just arm64.
- Copy `build/symbols/ios` from the Mac that built the IPA into the `ios/` sibling, under the
  **same** build number.
- Keep the whole directory **forever**, in two places, neither of them this laptop, never in git.

A rebuild from the same tag produces different mappings. This is the only artefact in the project
whose loss cannot be recovered by rebuilding (13 §9.4).
```

### 5.3 What is easy to get wrong here

- **The two paths must agree, and this is 13 §8.4's own warning.** `build/symbols/` is the write; the
  archive path is the read. If the archive is filed under a version instead of a `<name>+<build>`, or
  under the tag instead of the run number, the symbolize command in `RELEASES.md` points at nothing.
- **The archive is keyed on the build *number*, not the version.** Two builds of `1.0.0` have different
  `run_number`s and different mappings. Symbolizing build 188's trace against build 187's symbols does
  not fail cleanly — it can produce plausible-looking, wrong frames, and you will chase them.
- **Every ABI, not just arm64.** A multi-ABI AAB writes one `.symbols` file per architecture into
  `build/symbols/android`. Archiving only `app.android-arm64.symbols` loses every trace from every
  32-bit device, which is exactly the old low-end hardware this app is for.
- **The size build's symbols directory is a decoy.** `build/symbols/android-size` comes from the
  single-ABI throwaway build in the same job. It must **not** go into the archive, and copying it over
  the real one is a silent, total loss — the files look right and symbolize nothing. That is the whole
  reason the two builds get different `--split-debug-info` directories.
- **iOS symbols never come from CI.** The iOS release is a manual build on your own Mac (13 §9.3), so
  `symbols-archive/<name>+<build>/ios/` is filled by hand, with the build number the *release workflow*
  produced for that tag — not a number Xcode chose. This is the most likely way the archive ends up
  half-empty, and the failure is invisible until the first iOS crash report arrives.
- **`symbols-archive/` is git-ignored and that is the design, not an oversight.** They are binary, they
  never change, and they must outlive the repository. The consequence is that **nothing in CI can file
  them for you**: downloading the artefact and putting it in the right place is checklist item 11
  (N34-T04) and a human step, forever.
- **Do not add a crash reporter to solve this.** 13 §8.1: there is no reporter because there is no
  network, and G1 fails the moment one is wired up. The one diagnostic channel this app has is the
  local rolling log the user chooses to share, and the archive is what makes it readable.
- **Obfuscation interacts with what the log is even allowed to contain.** `Redact` emits
  `error.runtimeType` and never the exception message (13 §8.4), and stack traces have their sandbox
  UUIDs rewritten out. So a release trace is doubly opaque: obfuscated *and* redacted. Both are
  correct, and both are why the archive is not optional.
- **Flutter 3.44 changed a default and it is not the same thing as `--split-debug-info`.** Symbols are
  no longer stripped from `libapp.so` on Android by default (13 §6.1). **Measure the AAB both ways
  once and record which you ship** — it moves N34-T01's size number, and conflating the two settings
  is how a size regression gets attributed to the wrong change.
- **`--obfuscate` is a size lever as well as a privacy one** (13 §6.1's lever list, second after
  shipping an AAB rather than a fat APK). R8 is always on in release builds; the `--[no-]shrink` flag
  has no effect. Do not go looking for it.
- **The debug and profile builds are not obfuscated, so a trace from `make perf` or a debug run reads
  fine.** That is the trap: everything looks readable during development and nothing is readable in
  production. Prove the round trip once, in §8, on a real release build.
- **Nothing in this task reads a clock,** so it has no ambiguous-hour case. The only date in the
  archive is the one embedded in the build number's run, and it is not arithmetic.

### 5.4 The test set

`test/policy/release_config_test.dart` — extended, `@Tags(['policy'])`. N34-T01's ten cases stay; these
six are added.

| Test | What it holds |
|---|---|
| `'the release workflow obfuscates and archives symbols, and symbols-archive is gitignored'` | the anchor. Both flags present, the archive path named in `RELEASES.md`, and `symbols-archive/` git-ignored |
| `'every release build command carries obfuscate and split-debug-info together'` | across all workflow files **and** the iOS command recorded in `RELEASES.md`. `--obfuscate` alone is not a legal command and must not appear anywhere |
| `'the AAB build and the size build write to different split-debug-info directories'` | `build/symbols/android` versus `build/symbols/android-size`, asserted as two distinct strings — the case that fires when somebody tidies them into one |
| `'build/symbols/android is in the release artefact upload list'` | without it the symbols exist for 35 minutes and then the runner is destroyed |
| `'no file under symbols-archive is tracked'` | `git ls-files symbols-archive/` is empty, and `.gitignore` names the directory. Both directions, because one without the other is a half-rule |
| `'RELEASES.md states the retention rule and a symbolize command whose path carries a build number'` | the path in the documented command matches the `<name>+<build>` layout, so the write and the read cannot drift apart in prose |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. In particular: no crash reporter, no symbol-upload service, no "would you like to report this?" dialog. 13 §8.6 — the only egress is the system share sheet on an explicit tap.
- **Redaction is a list, not a judgement** (#124). The symbols make a trace readable to *you*, after the user has chosen to send a log they were invited to open and read first. Nothing about this task widens what the log contains.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the release workflow obfuscates and archives symbols, and symbols-archive is gitignored'` passes, and was seen to fail first for the stated reason
- [ ] obfuscation is on for release builds
- [ ] symbols are archived per build name and number
- [ ] `symbols-archive/` is gitignored
- [ ] the retention rule is written where the next person will read it
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/release_config_test.dart
make check
make test

git ls-files symbols-archive/ | wc -l      # expect: 0
git check-ignore -v symbols-archive/       # expect: the .gitignore line that covers it
```

Then prove the round trip on your own desk, because a release build is the only build where this can
fail and CI never runs one for you on this branch:

```bash
# 1. Build the shipped shape, obfuscated.
fvm flutter build appbundle --release \
  --build-name=1.0.0 --build-number=0 \
  --dart-define=APP_VERSION=1.0.0 --dart-define=APP_BUILD=0 \
  --obfuscate --split-debug-info=build/symbols/android

# 2. One .symbols file per ABI, not one file.
ls -l build/symbols/android

# 3. File it exactly as RELEASES.md says, then read a trace back through it.
mkdir -p symbols-archive/1.0.0+0/android
cp build/symbols/android/* symbols-archive/1.0.0+0/android/
fvm flutter symbolize -i crash.txt -d symbols-archive/1.0.0+0/android/app.android-arm64.symbols
```

For `crash.txt`: install that release build on a real device, trip a deliberate throw, and take the
stack trace out of `<appSupport>/diagnostics/shedbook.log` through Settings ▸ Diagnostics ▸ Export
diagnostics. **Confirm the raw trace is unreadable and the symbolized one is not.** That is the only
proof that counts; an archive nobody has ever symbolized against is a folder you are hoping about.

Then delete `symbols-archive/` from the working tree — it is git-ignored, and the real one does not
live on this laptop.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: obfuscation and the off-machine symbols archive`
