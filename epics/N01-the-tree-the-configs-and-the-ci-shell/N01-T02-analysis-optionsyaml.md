# N01-T02 — `analysis_options.yaml`

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 2 of 7 |
| **Depends on** | N01-T01 |
| **Commit** | one commit · `chore: analysis_options.yaml with the explicit strict block` |

## 1. Why this task exists

`flutter_lints 6.0.0` as the include, plus the explicit `analyzer.language` block —
`strict-casts`, `strict-inference`, `strict-raw-types`, all three `true` — and `errors:` promoting the
project's own rules. `--fatal-infos --fatal-warnings` in CI means an info is a build break, which is
the point.

`flutter_lints` alone is not acceptable and 13 §5.1 says why: it contributes ten Flutter rules and
**no analyzer language modes at all**. The load-bearing one is `strict-casts`, and the argument is
specific to this app — every row out of SQLite and every field out of a JSON backup is a
`dynamic`-adjacent boundary, so without it `final w = row['birth_weight'];` silently becomes whatever
you assign it to and fails at runtime, in a barn, at 3am, on a record that is now lost. For an app
whose §12.4 rule is *never silently correct a user's entry*, the type system doing its job at every
data boundary is not a style preference. With `strict-casts` on, **the analyzer is this project's
only code reviewer** — there is one developer.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §5.1, §5.2, §5.3 | the file verbatim, the enable-then-promote rule, and why `--fatal-infos` is passed explicitly |
| `docs/research/00-tech-decisions.md` | §5 #109, #2 | `flutter_lints` **6.0.0** — the only source of that number — and the analyzer ceiling that forbids a plugin |
| `docs/engineering/CONVENTIONS.md` | §1.1, §4.1 | the layer rules `always_use_package_imports` keeps machine-readable; generated files are never analysed |
| `docs/engineering/12-testing.md` | §1.4 | why a root config file is a `test/policy/` artefact test and not a gate rule |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | `analysis_options.yaml` and a red gate are its front door |
| `shed-conventions` | the lint set encodes naming rules this project already settled |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/analysis_options_test.dart`
- **Test** — `'strict-casts, strict-inference and strict-raw-types are all true and the include is flutter_lints 6.0.0'`
- **Why it is red today** — the generated file includes `flutter_lints` with no strict block and no promoted errors.

```bash
fvm flutter test test/policy/analysis_options_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — author the file and let the test read it as text rather than trusting `analyze` to
notice a missing key. `flutter analyze` is silent about configuration that is absent, and equally
silent about a promotion whose rule was never enabled.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No layer of §8's order is reached. This task writes one root config file and one test.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `analysis_options.yaml` | replaced wholesale with 13 §5.2's file. `flutter create` wrote a three-line version whose only content is the include |
| 2 | `pubspec.yaml` | read, not written. Confirm `flutter_lints: 6.0.0` is the version N00-T03 committed from decision-record §5. If it is a caret range, that is N00's defect and it is fixed there, not here |
| 3 | `test/policy/analysis_options_test.dart` | the anchor, written first |

### 5.2 The file, verbatim from 13 §5.2

```yaml
# analysis_options.yaml
#
# Base: flutter_lints 6.0.0 (decision #109). It sets NO analyzer language modes,
# which is why the block below is not optional and is restated here rather than
# inherited — it must survive a base-package bump and be visible in this repo.
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true        # the one that matters: every SQLite row, every JSON field
    strict-inference: true    # no silent dynamic when inference cannot decide
    strict-raw-types: true    # no bare List / Map / Future

  errors:
    todo: ignore
    # Promotions. A rule must be ENABLED — by flutter_lints' own closure or by the
    # `linter:` block below — before a promotion here does anything at all.
    # Enabled by flutter_lints:
    unrelated_type_equality_checks: error     # extension-type ids compared to raw ints
    collection_methods_unrelated_type: error
    use_build_context_synchronously: error    # every write path awaits, then shows a receipt
    # Enabled by the `linter:` block below, because flutter_lints does NOT set them:
    avoid_dynamic_calls: error
    close_sinks: error                        # the purchase stream subscription

  exclude:
    # Generated. Never hand-edited, never analysed, always regenerated by `make gen`.
    - '**/*.g.dart'
    - '**/*.drift.dart'
    - 'lib/core/db/schema_versions.dart'      # drift_dev schema steps
    - 'test/drift/generated/**'
    - 'build/**'
    # NOT '**/*.freezed.dart'. freezed is rejected on this stack (its analyzer
    # constraint conflicts with both drift_dev and build_runner). A line for a
    # package that cannot be installed is config that implies it might be.

  # NO `plugins:` section. custom_lint is archived upstream and unresolvable against
  # drift_dev's analyzer ^13.0.0; riverpod_lint is internally unresolvable. The
  # equivalent rules live in tool/check_policy.dart, which has zero dependencies.

linter:
  rules:
    # Every rule here is one flutter_lints does NOT enable. Nothing is repeated
    # from the base set — a repeated rule reads as a decision and is noise.
    - avoid_dynamic_calls      # promoted to error above
    - close_sinks              # promoted to error above; NOT in flutter_lints
    - unawaited_futures        # a dropped await is a lost write (spec §5)
    - only_throw_errors
    - always_use_package_imports
    - prefer_final_locals
    - use_super_parameters

formatter:
  page_width: 100
  trailing_commas: automate
```

Why each promotion is here rather than somewhere else, because a promotion with no reason gets
deleted the first time it is inconvenient:

| Rule | The failure it catches in *this* app |
|---|---|
| `unrelated_type_equality_checks` | `CONVENTIONS §2.1`'s ids are extension types over `int`. `eweId == 412` compiles and is always false; this makes it an error |
| `collection_methods_unrelated_type` | the same mistake wearing `list.contains(412)` |
| `use_build_context_synchronously` | every write awaits a transaction and then touches the widget tree to show the receipt. This is the rule that catches the disposed-context crash on a double tap |
| `avoid_dynamic_calls` | the JSON backup boundary. Not in any default set |
| `close_sinks` | the purchase stream subscription in `PurchaseService`. Not in any default set |
| `unawaited_futures` | *"a dropped await is a lost write"* — spec §5's every-write-commits-immediately promise has no other mechanical hold at the call site |
| `always_use_package_imports` | `tool/check_policy.dart`'s layer rules match on the import URI. One import shape to match instead of two is the difference between a 60-line gate and a path resolver |
| `only_throw_errors` | `beginLambing` and `addLamb` are the only two verbs that throw (R32); everything else returns `WriteOutcome`. This keeps the throw set narrow |

### 5.3 What is easy to get wrong here

- **Enable, then promote — and the analyzer will not tell you.** `errors:` can raise a lint's
  severity only if the rule is enabled somewhere. Three promotions ride on `flutter_lints`' own
  closure; **`avoid_dynamic_calls` and `close_sinks` do not**, which is why each appears twice, once
  under `linter: rules:` and once under `errors:`. Delete either half and the promotion becomes
  silently dead configuration. This is the single most valuable case in the anchor test.
- **`todo: ignore` is not laziness.** A `TODO` is an analyzer *info*, and `--fatal-infos` turns
  every one into a build break. Without this line the first `// TODO` in the codebase is red CI.
- **The analyzer's `exclude` does not exclude anything from `dart format`.** If
  `dart format --output=none --set-exit-if-changed .` fails on a generated file, that is a
  **toolchain-pin mismatch** — your formatter and the version `build_runner` formatted with
  disagree — not a source defect. Fix the pin or regenerate. Never hand-format a generated file.
- **Do not add `'**/*.freezed.dart'` to `exclude`.** `freezed` is rejected on this stack (its
  analyzer constraint conflicts with both `drift_dev` and `build_runner`), and a line for a package
  that cannot be installed is configuration that implies it might be.
- **Do not add a `plugins:` section, now or later.** `custom_lint` is archived upstream and
  `riverpod_lint` is internally unresolvable against `drift_dev`'s `analyzer ^13.0.0`. Every
  analyzer plugin that could express this project's rules is discontinued, archived or
  unresolvable — which is exactly why `tool/check_policy.dart` exists (N03).
- **Set the line length with `formatter.page_width`, never by disabling
  `lines_longer_than_80_chars`.** Disabling the lint leaves the formatter still wrapping at 80 and
  the two argue in every diff.
- **Do not parse this file with `package:yaml`.** `yaml` is not in decision-record §5 and §5 is the
  only source of a version number in this project. Declaring it would also need a line in
  `tool/policy_allowlist.txt`'s `[dev_dependencies]` section, and that file does not exist until
  N03. Importing it *without* declaring it trips `depend_on_referenced_packages`, which
  `flutter_lints`' closure enables and `--fatal-infos` turns into a build break. Read the file with
  `dart:io` as a `String` and assert on its lines. This applies to every anchor test in this epic.
- **`flutter analyze` already defaults `--fatal-infos` and `--fatal-warnings` to `true`.** Pass both
  explicitly anyway in the `Makefile` and in `ci.yml`, so the intent survives a tool change and so
  the two cannot drift apart.
- **`// ignore:` without a reason on the same line, and any repo-wide `// ignore_for_file:`, are
  anti-patterns.** So is disabling a rule because one call site is awkward — the awkward call site
  is the finding.

### 5.4 The test set

`test/policy/analysis_options_test.dart` — one file, six cases, all reading the file as text.
Nothing here is time-shaped, so there is no `uk-zone` case.

| Test | What it holds |
|---|---|
| `'strict-casts, strict-inference and strict-raw-types are all true and the include is flutter_lints 6.0.0'` | the anchor. Both halves: the three modes, and that `pubspec.yaml` pins `flutter_lints: 6.0.0` exactly and not a caret range |
| `'every rule promoted under errors is also enabled by flutter_lints or by the linter block'` | the dead-configuration case. Asserts `avoid_dynamic_calls` and `close_sinks` each appear twice |
| `'the exclude list names every generated shape and no freezed output'` | five entries present, `freezed` absent |
| `'there is no plugins section'` | the archived-plugin trap, refused in the file rather than remembered |
| `'formatter page_width is 100 and no line-length lint is disabled'` | the formatter-versus-linter argument, refused |
| `'todo is downgraded to ignore'` | the first `// TODO` does not break the build under `--fatal-infos` |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Versions** — `flutter_lints 6.0.0` comes from decision-record §5 and from nowhere else. Not from
  `pub add`, not from the `flutter create` template, not from memory.

## 7. Definition of Done

- [ ] `'strict-casts, strict-inference and strict-raw-types are all true and the include is flutter_lints 6.0.0'` passes, and was seen to fail first for the stated reason
- [ ] all three strict flags are `true`
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean on the tree
- [ ] the test reads the YAML, not the analyzer's output
- [ ] each of `avoid_dynamic_calls` and `close_sinks` appears in both `linter: rules:` and `errors:`
- [ ] a planted `strict-raw-types` violation was **seen** to fail `analyze`, and then deleted
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter test test/policy/analysis_options_test.dart
```

Then prove the block is live rather than merely present — `00-README` §9 step 1: *"a rule nobody has
seen fire is indistinguishable from a broken rule."* Plant one violation of each mode, watch
`analyze` exit 1 naming it, then delete the file. It is never committed.

```bash
printf 'void probe() {\n  final List raw = <int>[];\n  final dynamic d = raw;\n  d.whatever();\n}\n' > lib/strictness_probe.dart
fvm flutter analyze --fatal-infos --fatal-warnings ; echo "exit=$? (1 is the pass)"
rm lib/strictness_probe.dart
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: analysis_options.yaml with the explicit strict block`
