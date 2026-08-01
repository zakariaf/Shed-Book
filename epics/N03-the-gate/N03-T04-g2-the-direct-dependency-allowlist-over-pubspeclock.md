# N03-T04 — G2 — the direct-dependency allowlist over `pubspec.lock`

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 4 of 7 |
| **Depends on** | N03-T03 |
| **Commit** | one commit · `feat: G2 — the direct-dependency allowlist over pubspec.lock` |

## 1. Why this task exists

Every direct dependency must appear in the allowlist with a reason. `dependencies` and
`dev_dependencies` are scanned **separately**, because a dev dependency that reaches the network is a
different risk from a runtime one, and merging them is how a runtime package sneaks in behind a test
tool.

There is a third section, and it is the one that makes the gate satisfiable at all: `transitive`.
`build_runner` legitimately drags `shelf` and `web_socket_channel` into the graph, and `http 1.6.0`
arrives on two regular edges nothing can remove. An undifferentiated allowlist fails on day one and
gets deleted on day two. The claim G2 makes is narrower and true: **no package enters the graph
unreviewed.**

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.4 | G2's three-kind table, the two `[transitive]` entries that exist so nobody "fixes" them, and the outright bans |
| `docs/engineering/13-build-ci-release.md` | §1.2 | `pubspec.lock` is committed and is evidence; a lockfile diff with no `pubspec.yaml` diff is a review stop |
| `docs/engineering/01-architecture.md` | §3.2 | `_checkLockfile`, `_sectionFor`, the two lockfile regexes and why the `sdks:` block is skipped for free |
| `docs/research/00-tech-decisions.md` | §5.1, §5.2, §5.3 | every allowlisted package with its version, its reason and its cost — and the rejected list with the alternative |
| `docs/research/00-tech-decisions.md` | §1 #5, §3.4 | the four `in_app_purchase*` packages, and the honest exceptions |
| `CLAUDE.md` | the pinned stack | decision-record §5 is the only source of a version number, and this file may never be edited to green a build |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | G2 is the dependency table's enforcement |
| `shed-conventions` | the allowlist file format and its location |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'G2 exits 1 on a package added to pubspec.lock dependencies but not the allowlist'`
- **Why it is red today** — a new direct dependency can be added with no gate noticing.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The assertion, spelled out: write a synthetic `pubspec.lock` into the temp tree containing one
package marked `dependency: "direct main"` that is absent from `[dependencies]`, and assert exactly
one violation, whose id is `dep.direct_main` and whose message names **both** the package and the
section it appeared in. Then repeat with the same package moved to `direct dev` and assert the id is
`dep.direct_dev` — proving the two sections are genuinely separate rather than one list read twice.

**Green.** The minimum code that passes, and nothing beyond it — parse the lockfile, split by dependency kind, compare against the allowlist, and fail
naming the package **and** which section it appeared in.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

No schema, no domain, no data, no UI, no ARB — say so in the commit message (`00-README` §8).

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | `_sectionFor` and `_checkLockfile` are added, and `runPolicy` appends their result to the walk's violations. The lockfile path is resolved against the same `root` the walk uses, so the temp-tree tests can supply their own |
| 2 | `tool/policy_allowlist.txt` | The three dependency sections are filled from decision-record §5.1 / §5.2 and from a real `flutter pub get`. **Every line carries the reason it is there**, and `[transitive]` carries the reason it is *unavoidable* |
| 3 | `test/policy/gate_rules_test.dart` | The synthetic-lockfile cases, the section-separation case, the `sdks:` case and the four `in_app_purchase*` case |

### 5.2 The signatures

```dart
const _sectionFor = <String, String>{
  'direct main': 'dependencies',
  'direct dev':  'dev_dependencies',
  'transitive':  'transitive',
};

/// Parses pubspec.lock by hand — no YAML package, because the gate has no
/// dependencies (#9, #10). The lockfile's shape makes it trivial: a two-space
/// indented package name, then `dependency: "direct main"` / "direct dev" /
/// transitive.
List<String> _checkLockfile(Map<String, Set<String>> allow, {required String root});
```

The two regexes, from `01-architecture.md` §3.2, and the id each violation carries:

```dart
final _lockPackage = RegExp(r'^  ([a-z0-9_]+):$');
final _lockKind    = RegExp(r'^    dependency: "?([a-z ]+)"?$');

// ids: dep.direct_main · dep.direct_dev · dep.transitive
'[dep.${kind.replaceAll(' ', '_')}] $name is not on the allowlist — '
'read its pubspec, confirm it opens no socket and merges no permission, '
'then add it to tool/policy_allowlist.txt'
```

The allowlist's three sections, with the entries that are not obvious. `[dependencies]` is
decision-record §5.1 plus the two SDK packages; `[dev_dependencies]` is §5.2 plus `flutter_test`;
`[transitive]` carries the two entries `13 §2.4` prints so nobody "fixes" them:

```
[dependencies]        # direct main — every line was read against 00-tech-decisions §5.1
flutter               # the SDK package. Absent from §5.1's table because it is not on pub.dev.
flutter_localizations # SDK. Pins intl exactly, which is why intl is declared `any` (#108).
drift · drift_flutter · sqlite3 · path_provider · uuid · clock · intl
flutter_riverpod      # 2.6.1 EXACTLY. A caret here is the resolution failure, not a style choice.
flutter_local_notifications · timezone · wakelock_plus · image_picker
flutter_image_compress · record · share_plus · file_selector · pdf · archive
device_info_plus · logging
in_app_purchase       # decision #5: the ONLY direct one of the four. Adds com.android.vending.BILLING.
accessibility_tools   # decision #100: it wraps the app tree, so lib/ imports it. Debug-only, behind kDebugMode.

[dev_dependencies]    # direct dev — never shipped
flutter_test          # the SDK test package. `test` is NEVER a direct dependency (#4).
drift_dev · build_runner · flutter_lints · mocktail · glados · golden_screenshot

[transitive]          # documented, with the reason on the line
http                  # via timezone AND via package_info_plus. Two REGULAR edges. Unavoidable.
sqlite3_flutter_libs  # no-op EOL shim dragged in by drift_flutter. NOT flagged discontinued on
                      # pub.dev, so a check keyed on that flag will not fire. Expected.
in_app_purchase_android · in_app_purchase_storekit · in_app_purchase_platform_interface
                      # decision #5's other three. storekit must be >= 0.4.8 (§5.1).
sky_engine            # SDK. Appears as transitive with source: sdk.
```

The remaining `[transitive]` lines are whatever `flutter pub get` actually produced. **Do not type
them from memory** — run the gate, read the violations it prints, and add each line only after
reading that package's pubspec.

### 5.3 The details that are easy to get wrong

- **The four SDK packages are the first thing that breaks G2, and none of them is in
  decision-record §5.1's table.** `flutter` and `flutter_localizations` appear in the lockfile as
  `direct main` with `source: sdk`; `flutter_test` as `direct dev`; `sky_engine` as `transitive`.
  §5.1 is a pub.dev table and correctly omits them. The developer who copies §5.1 into
  `[dependencies]` and stops gets a red gate on the first run and concludes the gate is broken.
- **Only `in_app_purchase` is direct.** The Definition of Done says *"the four `in_app_purchase*`
  packages are allowlisted with decision #5's reason"* — and three of them (`_android`, `_storekit`,
  `_platform_interface`) are **transitive**, so they belong in `[transitive]`, not
  `[dependencies]`. Put them in the wrong section and the gate is red with a message that reads like
  the package is unknown when the real fault is the section. Decision #5's reason goes on all four
  lines: billing is a Play-Services-adjacent artefact whose transitive Gradle graph must be reviewed
  on every Billing Library bump, and it is what contributes `com.android.vending.BILLING`.
- **`intl` is declared `any` in `pubspec.yaml` and pins to 0.20.2 in the lockfile.** The allowlist
  matches on the name, not the version, so this is invisible here — but if you are tempted to add a
  version check to G2, `flutter_localizations` pins `intl` exactly and `^0.20.3` will not resolve.
  Version enforcement belongs to `pubspec.yaml` and decision-record §5, not to this gate.
- **The `sdks:` block at the foot of the lockfile is skipped for free**, and it is worth knowing why
  rather than rediscovering it: its entries carry a value on the same line (`dart: ">=3.12.0 …"`),
  so `^  ([a-z0-9_]+):$` — which requires the line to *end* at the colon — never matches. Change that
  anchor and the gate starts reporting `dart` and `flutter` as unknown packages.
- **`^    dependency:` is four spaces, `^  ([a-z0-9_]+):$` is two.** Both are exact. A lockfile
  written by a different pub version with different indentation would silently match nothing and G2
  would pass on everything. Add a case asserting the parser finds a **known** count on the real
  `pubspec.lock`, so "parsed zero packages" fails loudly instead of passing quietly.
- **A missing `pubspec.lock` is exit 2, not exit 0.** It means `flutter pub get` has not run, and a
  gate that reports clean because it could not find its input is worse than no gate. `01-architecture`
  §3.3 makes the same point about the allowlist.
- **This gate reads a committed file, so it is only as good as the commit discipline around it.**
  `13 §1.2`: a lockfile diff in a PR that does not also change `pubspec.yaml` is a **review stop** —
  something upstream moved and you are about to ship it. G2 cannot see that; a reviewer can. Say so
  in the commit message.
- **Never write the lockfile rule.** A *"no `http` in `pubspec.lock`"* gate is unsatisfiable —
  `http` sits on two regular edges — and writing it means either deleting reminders and the wakelock
  or disabling the gate. N03-T03 put the reason in the source; this task is where somebody looking at
  a lockfile full of `http` will be tempted to add it anyway. The `[transitive]` line's comment is
  the answer.
- **This file is one of the two `CLAUDE.md` forbids editing to make a build pass.** The other is
  `android/expected_permissions.txt`. Adding a line to silence a red gate is a named anti-pattern
  (`13 §2.8`). The legitimate act — reading a new package's pubspec, confirming it opens no socket
  and merges no permission, then adding the line **with that reason** — is the same keystrokes and a
  completely different act. The difference lives in the commit message.

### 5.4 The full test set

Every case writes its own synthetic `pubspec.lock` into the temp tree, so none of them depends on the
real dependency graph — except the last two, which deliberately do.

| Case | Lockfile | Expect |
|---|---|---|
| the anchor | one `direct main` package absent from `[dependencies]` | one violation, id `dep.direct_main`, message naming package and section |
| the same package as `direct dev` | absent from `[dev_dependencies]` | one violation, id `dep.direct_dev` |
| the same package as `transitive` | absent from `[transitive]` | one violation, id `dep.transitive` |
| **sections do not leak** | a package listed only in `[dev_dependencies]`, appearing as `direct main` | one violation — this is the "runtime package behind a test tool" failure the split exists to catch |
| quoted and unquoted kinds | `dependency: "direct main"` and `dependency: transitive` | both parsed; the regex's `"?` is not decorative |
| the `sdks:` block | a lockfile with a trailing `sdks:` block | zero violations from it |
| a package name with digits and underscores | `sqlite3_flutter_libs` in `[transitive]` | zero violations |
| a missing lockfile | no `pubspec.lock` in the temp tree | `PolicyConfigError`, mapped to exit 2 |
| an empty lockfile | a file with a `packages:` header and nothing under it | the "parsed zero packages" guard fires |
| the four `in_app_purchase*` | the real allowlist | `in_app_purchase` resolves in `[dependencies]`, the other three in `[transitive]`, zero violations |
| the real tree | the committed `pubspec.lock` and the committed allowlist | **zero violations** — G2 green on the actual graph is the only case that proves the file is complete |

No case is time-shaped.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This commit **is** G2: from here, a package cannot enter the graph unreviewed.
- **Decision-record §5 is the only source of a version number** — not a README, not `pub add`, not memory. This task adds no version to any file; it adds names and reasons. If a name here does not appear in §5, it does not go on the list.
- **`flutter_timezone` is not on the list and must not be added.** It is *"required but NOT in the c1 audit"* (§5.1) and must be audited by c1's method — pub.dev API, publisher, transitive graph, merged manifest — with the verified version recorded in the decision record *before* it enters any pubspec. G2 red on it is the gate working.
- **The outright bans belong in the `[dependencies]` section's comment**, because they are the ones that will be proposed: `connectivity_plus`, `workmanager`, `battery_plus`, `firebase_*`, `printing`, `google_fonts`, `google_mlkit_text_recognition`, `speech_to_text`, `permission_handler`, `purchases_flutter`. Every one has a rejection row in decision-record §5.3.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'G2 exits 1 on a package added to pubspec.lock dependencies but not the allowlist'` passes, and was seen to fail first for the stated reason
- [ ] a planted direct dependency exits 1
- [ ] the two sections are scanned separately and the message says which
- [ ] the four `in_app_purchase*` packages are allowlisted with decision #5's reason
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart run tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

Then prove it on the real graph, which is the only run that proves the allowlist is complete:

```bash
fvm flutter pub get                                  # the lockfile the gate will read
git diff --exit-code -- pubspec.lock                 # 13 §1.2: a lockfile diff is a review stop
dart run tool/check_policy.dart ; echo "exit=$?"     # policy ok, exit=0
grep -c '^[a-z_]' tool/policy_allowlist.txt          # the line count you just justified
make check
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: G2 — the direct-dependency allowlist over pubspec.lock`
