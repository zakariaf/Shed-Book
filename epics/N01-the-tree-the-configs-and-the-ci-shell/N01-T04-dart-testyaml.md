# N01-T04 — `dart_test.yaml`

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 4 of 7 |
| **Depends on** | N01-T01 |
| **Commit** | one commit · `chore: dart_test.yaml with the two presets and the four tags` |

## 1. Why this task exists

The `ci-fast` and `ci-golden` presets, the `uk-zone`, `golden`, `slow` and `calendar` tags,
and randomisation switched **off** for the `migration` tier — where ordering is part of what is being
tested.

Two things make this more than a config file. First, 12 §11.2: *"the tags must be declared here or a
`--tags` filter silently matches nothing and the run is green because it ran nothing."* The `test`
job N01-T06 writes has a step that is exactly `TZ=Europe/London flutter test --tags uk-zone`, and
until some test carries that tag the step is a green line proving nothing — for the eleven epics
between here and the first DST test. So this task also lands **one tagged canary**, and the epic's
zone step starts meaning something on the day it is written. Second, 12 §11.2 and 13 §1.3 currently
**contradict each other in writing** about whether the two presets can exist at all; 12 §14 makes
resolving that a day-one check, and this is day one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | §11.2, §11.3, §11.6 | the file, the tag list, the randomisation rule, the flaky-expiry rule — 12 owns `dart_test.yaml` |
| `docs/engineering/12-testing.md` | §2.3, §2.5 | the ambiguous hour 01:00–01:59, and the three commands the tags select for |
| `docs/engineering/12-testing.md` | §14 edit 1, §11.2 note | the day-one check that decides whether the presets exist, and which document changes |
| `docs/engineering/13-build-ci-release.md` | §1.3, §4.3 | the two places that spell the filters as `-P ci-fast` and `-P ci-golden` today |
| `docs/research/00-tech-decisions.md` | §5 #4, §7.0 | `package:test` is never a direct dependency · UK/Ireland first, which fixes the ambiguous hour |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the tiers, the tags and the presets are its subject |
| `shed-dependencies-and-toolchain` | the file is one of the four committed configs |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/test_config_test.dart`
- **Test** — `'ci-fast and ci-golden exist, the four tags are declared, and migration runs unrandomised'`
- **Why it is red today** — no `dart_test.yaml` exists and `flutter test` runs everything in one undifferentiated pass.

```bash
fvm flutter test test/policy/test_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — run the day-one check in §5.2 **first**, then author the tag block and whichever filter
form it decided; assert both by reading the file as text.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8 reaches tests at step 23. This task is entirely in that step, plus one root config file.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `dart_test.yaml` | new. The tag block from 12 §11.2, extended by `calendar` (N00-T07 and N00-T08 both run `--tags calendar`), plus the preset block if and only if §5.2's check permits it |
| 2 | `test/domain/uk_zone/zone_canary_test.dart` | new. One `@Tags(['uk-zone'])` file so `--tags uk-zone` selects something. It also fails loudly under any other zone, which is what makes N01-T06's `--exclude-tags uk-zone` on the hostile step necessary rather than decorative |
| 3 | `test/policy/tree_shape_test.dart`, `test/policy/analysis_options_test.dart`, `test/policy/l10n_bootstrap_test.dart` | each gains `@Tags(['policy'])` at the top. Until now the tag did not exist and `package:test` warns on every undeclared tag it sees; this is the one pass that adds them |
| 4 | `test/policy/test_config_test.dart` | the anchor, written first — and it carries `@Tags(['policy'])` too |

### 5.2 The day-one check, which runs before anything is authored

12 §11.2 and 13 §1.3 disagree in writing, and 12 §14 edit 1 says which way the disagreement is
resolved depends on one fact about the installed SDK. 12 states flatly that **`flutter test` has no
preset flag** — that `-P` / `--preset` is not in its pass-through list, which is
`--tags`, `--exclude-tags`, `--update-goldens`, `--coverage`, `--reporter`, `--concurrency`,
`--test-randomize-ordering-seed`, `--name`, `--plain-name`, `--total-shards`, `--shard-index`,
`--timeout` and `--fail-fast` — and that this project never runs `dart test` because decision #4
keeps `package:test` out of the pubspec entirely.

Run this before writing a line:

```bash
fvm flutter test --help | grep -E '^\s*-P|--preset'   # empty output means 12 §11.2 is right
```

| Outcome | What this task writes | What else changes, in the same commit |
|---|---|---|
| `-P` **is** accepted | the `presets:` block below, and N01-T05 and N01-T06 spell the filters `-P ci-fast` / `-P ci-golden` | 12 §11.2's ruling reverses — record the answer in that section, as it asks |
| `-P` is **not** accepted | no `presets:` block; N01-T05 and N01-T06 spell the filters `--exclude-tags golden` and `--tags golden` | 13 §1.3 and §4.3 take 12 §14 edit 1. The Definition of Done line *"both presets exist"* becomes unsatisfiable as written and is recorded as a ruling in 12 §11.2 — **not** quietly dropped |

The only unacceptable outcome is the two documents continuing to say different things. Run the
second half of the same check while you are here: whether `allow_test_randomization: false` actually
takes effect on the `migration` tag under `flutter test`. 12 §11.2 names both as one check and names
the fallback if it does not — `--exclude-tags migration` in the randomised job plus a separate
non-randomised invocation. **Never respond by removing the randomisation**; it is the point of the
job.

### 5.3 The file

The tag block is 12 §11.2 verbatim, plus `calendar`:

```yaml
# dart_test.yaml
tags:
  golden:      # generated and verified only on the pinned macOS runner
  migration:
    timeout: 2x
    allow_test_randomization: false   # order-sensitive by design
  uk-zone:     # requires TZ=Europe/London; the file asserts the offset itself
  policy:
  slow:
    timeout: 3x
  calendar:    # N00's ledger test; red until every commitment has a date and an outcome
  flaky:       # excluded from CI; every one carries an expiry date in its name

# Only if the §5.2 check said `-P` is accepted:
presets:
  ci-fast:
    exclude_tags: golden
  ci-golden:
    include_tags: golden
```

The canary, `test/domain/uk_zone/zone_canary_test.dart`. Every assertion is a fact about
`Europe/London` in 2026 and none depends on how a platform normalises a nonexistent local time:

```dart
@Tags(['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test (12 §2.5). Fail loudly.
    expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1),
        reason: 'Run this file with TZ=Europe/London');
    expect(DateTime(2026, 1, 1).timeZoneOffset, Duration.zero,
        reason: 'Run this file with TZ=Europe/London');
  });

  test('29 March 2026 is 23 hours long and 01:00-01:59 has no local representation', () {
    expect(DateTime(2026, 3, 30).difference(DateTime(2026, 3, 29)),
        const Duration(hours: 23));
    // The local hour steps 00 -> 02. Nothing maps onto 01:xx.
    expect(DateTime.utc(2026, 3, 29, 0, 30).toLocal().hour, 0);
    expect(DateTime.utc(2026, 3, 29, 1, 30).toLocal().hour, 2);
  });

  test('25 October 2026 is 25 hours long and 01:00-01:59 happens twice', () {
    expect(DateTime(2026, 10, 26).difference(DateTime(2026, 10, 25)),
        const Duration(hours: 25));
    // Two distinct instants, one wall-clock reading. This is the hour every
    // withdrawal and hours-penned case targets from N04 onward.
    expect(DateTime.utc(2026, 10, 25, 0, 30).toLocal().hour, 1);
    expect(DateTime.utc(2026, 10, 25, 1, 30).toLocal().hour, 1);
  });
}
```

### 5.4 What is easy to get wrong here

- **The four tags the Definition of Done names are not the whole set.** Declare seven. 12 §11.2
  declares `golden`, `migration`, `uk-zone`, `policy`, `slow` and `flaky`; N00's ledger tests run
  `--tags calendar`. A tag that is *used* but not declared warns; a tag that is *selected* but not
  declared matches nothing and the run is green because it ran nothing.
- **`allow_test_randomization: false` is the per-tag key; `test_randomize_ordering_seed` is not.**
  Under a `tags:` entry only test-level metadata is valid — `timeout`, `skip`, `retry`, `tags`,
  `on_platform`, `allow_test_randomization`. `test_randomize_ordering_seed` is a **runner**-level
  key, and setting it at the top of this file would switch randomisation off for the *whole* suite,
  which is the exact opposite of what 13 §4.3's randomised job exists for. The effect the Definition
  of Done names — the migration tier runs unrandomised — is `allow_test_randomization: false`.
- **A declared tag with no test carrying it is the failure this task is really about.** `--tags
  uk-zone` over a tree with no tagged file prints "No tests ran" and exits **0**. That is why the
  canary lands here and not in N04, and why N01-T06's job step must refuse an empty selection.
- **The canary must fail loudly, never skip.** 12 §2.5: *"a skipped safety test is a broken safety
  test."* `test/domain/uk_zone/` asserts its own offset in `setUpAll`, so under any other zone the
  file is red — which is correct, and is precisely why the hostile-zone step carries
  `--exclude-tags uk-zone`. Do not "fix" the canary by making it skip.
- **The zone step in CI must be unscoped.** `TZ=Europe/London flutter test --tags uk-zone`, with no
  path. 12 §2.4 puts two zone-pinned files in `test/data/` and `test/features/` later; a
  `test/domain` scope would run them in the runner's own zone — UTC on `ubuntu-latest`, where a
  spring-forward test passes because there is no spring forward.
- **Do not add `package:test` to fix any of this.** Decision #4: declaring it caps
  `analyzer < 13.0.0` and breaks `drift_dev`. The `flutter_test` package does not depend on it. If a
  configuration key seems to need `dart test`, that is the §5.2 check's answer, not a pubspec edit.
- **Do not parse this file with `package:yaml`** — same reason as N01-T02 §5.3. Read it as text.
- **The `flaky` tag comes with an obligation.** 12 §11.6: every flaky test carries an expiry date in
  its name (`'flaky-until-2026-09-01: …'`) and **a test in `test/policy/` fails the build once an
  expiry passes**. That test is written here, while there are zero flaky tests and it is free.
- **`timeout: 2x` and `3x` are multipliers of the default, not seconds.** A literal `2` would be two
  seconds and would turn the migration tier red at N08.

### 5.5 The test set

| File | Test | What it holds |
|---|---|---|
| `test/policy/test_config_test.dart` | `'ci-fast and ci-golden exist, the four tags are declared, and migration runs unrandomised'` | the anchor. If §5.2 ruled the presets out, the preset half asserts the recorded ruling instead of a `presets:` block, and the test names the ruling |
| | `'every tag the Makefile, ci.yml or a task file selects is declared in dart_test.yaml'` | the silently-matches-nothing failure, closed over the whole repository rather than over a remembered list |
| | `'at least one test file carries each declared tag that any command selects'` | the vacuous-green failure. `uk-zone`, `policy` and `calendar` all have carriers; `golden`, `migration`, `slow` and `flaky` are allowed to be empty until N33, N08, and never |
| | `'the migration tag sets allow_test_randomization false and no runner-level seed is set'` | the two halves of the ordering rule, in the two places they legally live |
| | `'no flaky-tagged test has an expiry date in its name that has passed'` | 12 §11.6's rule, written while it is free |
| `test/domain/uk_zone/zone_canary_test.dart` | `'29 March 2026 is 23 hours long and 01:00-01:59 has no local representation'` | the nonexistent hour, and that the process zone is `Europe/London` |
| | `'25 October 2026 is 25 hours long and 01:00-01:59 happens twice'` | the ambiguous hour — the one the owner's region ruling fixes and every withdrawal and hours-penned case targets from N04 on |

## 6. Constraints that bind this task

- **The ambiguous hour is 01:00–01:59** (decision-record §7.0, UK/Ireland first). Every time-shaped
  case in this backlog targets it, and this task is where the machinery that selects those cases
  starts existing.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ci-fast and ci-golden exist, the four tags are declared, and migration runs unrandomised'` passes, and was seen to fail first for the stated reason
- [ ] both presets exist and are used by the `Makefile` in T05
- [ ] `uk-zone`, `golden`, `slow` and `calendar` are declared
- [ ] the `migration` tier has `test_randomize_ordering_seed: 0`
- [ ] the day-one check in §5.2 has been run and both its answers written into 12 §11.2
- [ ] `TZ=Europe/London fvm flutter test --tags uk-zone` reports at least one test, not "No tests ran"
- [ ] every existing `test/policy/` file carries `@Tags(['policy'])`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test --help | grep -E '^\s*-P|--preset'
fvm flutter test -P ci-fast
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
fvm flutter test test/policy/test_config_test.dart
```

The first line **is** the day-one check: empty output means the second line will not run and the
`--exclude-tags golden` form is the one that ships. The third must report a test count, never "No
tests ran". The fourth must be green *because* the canary was excluded — drop the exclusion once, by
hand, and watch it go red naming the offset, so you have seen the mechanism work.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: dart_test.yaml with the two presets and the four tags`
