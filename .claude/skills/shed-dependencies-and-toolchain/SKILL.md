---
name: shed-dependencies-and-toolchain
description: >-
  Decides whether a package may enter this app at all and at what pin. Use before pub add, before
  proposing any package, plugin, library or dependency, when editing pubspec.yaml,
  analysis_options.yaml or the Makefile, and whenever a gate is red. Do NOT use for wrapping an
  approved plugin or its permissions (shed-platform-gateways), or to cut a release (shed-release).
---

# Dependencies and toolchain

Every version number in this project comes from `docs/research/00-tech-decisions.md` §5 and from
nowhere else — not a README, not `pub add`, not pub.dev's latest, not memory. `docs/engineering/CONVENTIONS.md`
is the naming authority and outranks this skill on any name or path.

**Owns:** `pubspec.yaml`, `analysis_options.yaml`, `Makefile` targets, gates **G2** and **G3**.
**Do NOT use for:** cutting a release, signing, size/startup budgets, or G0/G1/G4/G5 against a real
AAB → `shed-release`. Schema, migrations or `build_runner` output → `shed-drift-schema`. Which
plugin requests which permission → `shed-platform-gateways`.

## The gate-integrity rule — read this before touching any gate

Never edit `tool/check_policy.dart`, its rule table or its exit code to make a build pass. Never add
a line to `tool/policy_allowlist.txt` or `android/expected_permissions.txt` to silence a gate. If a
gate is genuinely wrong, say so and stop. **User instructions outrank this skill; your own
convenience does not.**

A red gate is a finding, not an obstacle. Editing the allowlist to green a build is named as an
anti-pattern in `13-build-ci-release.md` §2.8, and for `android/expected_permissions.txt` it is
called the single worst thing you can do to this project.

## Before anything else

Decision #5 (`00-tech-decisions.md` §1, `00-README.md` §4): run `flutter pub get` against §5's table
on Flutter 3.44.8 and **commit `pubspec.lock` before any other work**. It is the doc set's only
evidence that the table resolves at all — four of the ten research notes recommended a `build_runner`
constraint that does not. `pubspec.lock` is committed (`00-README.md` §7.1); a lockfile diff in a PR
that does not also change `pubspec.yaml` is a review stop.

## The pins

Read the tables; do not re-derive them. Runtime deps → decision-record §5.1. Dev deps → §5.2.
Rejected, with reason and alternative → §5.3 (~40 rows). Stack at a glance → `00-README.md` §3.1–§3.4.

Non-negotiable, and each is a thing an agent gets wrong:

- **Flutter 3.44.8 stable / Dart 3.12.2**, pinned via FVM. Never `channel: stable` unpinned. The
  version lives in `.fvmrc` **plus one `env:` block per workflow** — four places, made safe only by
  the three-line assert every workflow runs (`13` §1.1). A toolchain bump is its own commit.
- **`flutter_riverpod: 2.6.1` — exact, no caret.** 3.x declares `test: ^1.0.0` at runtime, so
  `flutter pub get` fails outright alongside `drift_dev`.
- **`build_runner: ">=2.15.0 <2.15.2"`.** `^2.15.2` needs `analyzer >=13.3.0` → `meta ^1.18.3` →
  unresolvable.
- **`intl: any`.** `flutter_localizations` pins `intl 0.20.2` exactly; `^0.20.3` will not resolve.
- **`package:test` is never a direct dependency.** Use `flutter_test`.
- **`flutter_timezone` is unaudited and banned from any pubspec** until it is audited by c1's method
  (pub.dev API, publisher, transitive graph, merged manifest) and its verified version is recorded
  in decision-record §5.1. Do not copy note 06's version number.
- **Never run `flutter pub add`.** It writes a caret range and resolves to latest — both wrong here.
  Type the pin by hand, from §5.

## Adding or changing a dependency — the workflow

1. Read decision-record **§5.3** first. If it has a rejection row, the answer is the alternative
   named in that row. Do not re-litigate it; say it is rejected and why.
2. If it is not rejected, it must be **added to §5.1/§5.2 with a verified version before it is added
   to `pubspec.yaml`** — the decision record is the source, the pubspec is the copy.
3. Audit it: verified publisher, transitive graph (does it drag `http`, Play Services, or a second
   DI/codegen system?), and which Android permissions it merges.
4. Add the exact pin to `pubspec.yaml` **and** a line to the matching section of
   `tool/policy_allowlist.txt` (`[dependencies]` or `[dev_dependencies]`), reviewed, not assumed.
5. `flutter pub get`, then read the whole `pubspec.lock` diff. New `transitive` entries need a
   `[transitive]` line **with the reason on the line**.
6. `make check`. G1 needs a real release AAB and belongs to `shed-release`.

## Gotchas

- **The analyzer ceiling governs everything.** The SDK pins `meta: 1.18.0` exactly, so no Flutter app
  can resolve `analyzer ≥ 13.1.0`. That single fact is why `freezed`, `riverpod_generator`,
  `riverpod_lint`, `import_lint` and `custom_lint` are **unresolvable**, not merely unwanted — adding
  one produces a solver failure, not a lint.
- **`http 1.6.0` is in `pubspec.lock`, legitimately**, on four regular edges:
  `flutter_local_notifications → timezone → http`, `wakelock_plus → package_info_plus → http`, `file_selector → file_selector_platform_interface → http` and `image_picker → image_picker_platform_interface → http`.
  A *"no `http` in `pubspec.lock`"* gate is **unsatisfiable** and must never be written — satisfying
  it means deleting reminders and the wakelock. G2's claim is narrower and true: no package enters
  the graph unreviewed. Do not "fix" the two documented `[transitive]` lines.
- **`sqlite3_flutter_libs` is not flagged discontinued on pub.dev** (`isDiscontinued` is false; it
  carries an `+eol` build tag). A check keyed on that flag will never fire. It arrives transitively
  via `drift_flutter` and is expected; it is never a direct dependency.
- **`accessibility_tools` is a dev dependency that `lib/` imports** — it is a widget wrapping the app
  tree. Wire it behind `kDebugMode` and keep it on the allowlist; it is not a layering violation.
- **`package:sqlite3`'s build hooks download a sha256-verified binary from GitHub at build time.** A
  cold-cache plane-mode build failure is expected behaviour, not a regression. The shipped app has no
  network code.
- **An `errors:` promotion is dead config unless the rule is enabled somewhere.** `avoid_dynamic_calls`
  and `close_sinks` are in no default set, so each appears twice — once in `linter: rules:`, once in
  `errors:`. The analyzer does not warn about a promotion with no enable.
- **The analyzer's `exclude:` does not exclude anything from `dart format`.** If
  `dart format --set-exit-if-changed` fails on generated code, that is a toolchain-pin mismatch. Fix
  the pin or regenerate; never hand-format a generated file.
- **Never add `'**/*.freezed.dart'` to `exclude:` or to the lcov strip.** freezed cannot be installed
  on this stack, and config for an impossible package implies it might arrive.
- **No `plugins:` section in `analysis_options.yaml`.** Every analyzer plugin that could express this
  project's rules is archived, discontinued or unresolvable — which is exactly why
  `tool/check_policy.dart` exists.
- **`make goldens` verifies; `make goldens-update` re-baselines.** One target that silently passes
  `--update-goldens` is the easiest way there is to green a broken golden.
- **`flutter test` has no `-P` / `--preset` flag.** `13-build-ci-release.md` §1.3, §4.3 and its
  `Makefile` spell the test targets `-P ci-fast` / `-P ci-golden`; `12-testing.md` §11.2 owns
  `dart_test.yaml`, declines to declare those presets, and rules that **the flags are canonical and
  the presets unwritten** — `-P`/`--preset` is not in `flutter test`'s pass-through set, and this
  project never runs `dart test` (decision #4 keeps `package:test` out of the pubspec). 12 also
  rebuts 13's rationale: tag configuration in `dart_test.yaml` applies to any run that selects those
  tests, so a bare `--exclude-tags golden` does **not** drop the `migration` tag's
  `allow_test_randomization: false`. Write `--exclude-tags golden` / `--tags golden`. 12 §14 edit 1
  carries the correction into 13; if the day-one check finds `flutter test` does accept `-P`, that
  edit reverses and 12 adds the presets — until then, do not put a preset name in a Makefile or a
  workflow.

## `analysis_options.yaml`

`flutter_lints` 6.0.0 **plus an explicit `analyzer: language:` strict block** — `flutter_lints` sets
no language modes at all, so the block is not optional and is written out in this repo rather than
inherited. `strict-casts` is the load-bearing one: every row out of SQLite and every field out of a
JSON backup is a `dynamic`-adjacent boundary. The exact file is `13-build-ci-release.md` §5.2.

Pass `--fatal-infos --fatal-warnings` explicitly even though they default true, so `make check` and
CI cannot drift apart.

Anti-patterns: `// ignore:` with no reason on the same line; a repo-wide `// ignore_for_file:`;
disabling a rule because one call site is awkward — the awkward call site is the finding.

## The two gates this skill owns

Both live in `tool/check_policy.dart`, one script with one allowlist and one exit code (decision #10).
No document adds a second script; every document adds **rows**. Exit codes: `0` clean · `1`
violations · `2` the gate could not run (still a failure, never a skip).

- **G2 — the direct-dependency allowlist.** Blocking, every push. `_checkLockfile` reads
  `pubspec.lock` and checks `direct main` / `direct dev` / `transitive` against three **separate**
  sections of `tool/policy_allowlist.txt`. Separate because `build_runner` legitimately drags `shelf`
  and `web_socket_channel` in as dev-only.
- **G3 — the import-level source scan.** Blocking, every push. `_bannedEverywhere` (package URIs)
  plus the `net.*` rows of `_bannedText`. Not redundant: `HttpClient` and `Socket` come from
  `dart:io` and `Image.network` is in the SDK, so neither arrives on a `package:` URI. G3 proves our
  *own source* cannot reach a network API; it proves nothing about a dependency — that is G1's job.

Rule ids are dotted `namespace.name`, `lower_snake` (`CONVENTIONS.md` §4.7, R54); a duplicate id is a
rule that gets weakened twice. `token.raw_color` and `token.material_color` are scoped to `lib/`, not
`lib/features/` (R55). `tool/policy_allowlist.txt`'s `[exempt]` section has **exactly four lines on
day one** (R56) — `app_clock.dart :: time.dart_clock`, `night_error_panel.dart :: token.raw_color`,
`primitives.dart :: token.raw_color`, `palettes.dart :: token.primitives_import`. A fifth is a review
conversation, never an edit you make to pass a build.

**When any gate is red — or you need to know what a rule id means or what the forbidden fix is —
read `references/gate-failures.md`.**

## Done when

- [ ] Every version in `pubspec.yaml` matches decision-record §5.1/§5.2 character for character, and
      nothing is in the pubspec that is not in that table.
- [ ] `flutter_riverpod` is `2.6.1` with no caret; `build_runner` is `">=2.15.0 <2.15.2"`; `intl` is
      `any`; `test` is absent.
- [ ] Every new lockfile entry has an allowlist line in the correct section, transitive ones with the
      reason on the line.
- [ ] `pubspec.lock` is committed and its diff has been read.
- [ ] `make check` passes — `dart tool/check_policy.dart`, `dart format --set-exit-if-changed`,
      `flutter analyze --fatal-infos --fatal-warnings`.
- [ ] No gate file, rule table, exit code or allowlist was edited to make any of the above pass.
