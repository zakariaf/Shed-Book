# N11-T08 — The first-frame parity gate

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 8 of 9 |
| **Depends on** | N11-T07 |
| **Commit** | one commit · `test(design): the first-frame parity gate` |

## 1. Why this task exists

One test that reads **both** platforms' native files and asserts they equal each other
and the token. Two platforms drifting apart is the failure mode here, and it is invisible unless
something compares them.

T06 proved Android against `nSurface04`. T07 proved iOS against `nSurface04`. Neither proved the two
against **each other**, and that is not the same assertion the day somebody edits the token and
updates one platform — which is the realistic version of this bug, because the two edits are in
different directories and one of them needs a Mac.

There is a second, larger reason. **The hex is typed in six places** across this repo: `nSurface04`,
`launchSurface`, `night_error_panel.dart`, `colors.xml`, and two storyboards. Five of those six are
downstream of one value and nothing in the language relates them. This task is what turns
"six places, one intention" into a single failing line with a filename in it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §9.4 (**`launch.colour_parity` — the rule, its five assertions, and the note that its storyboard half has not been run**) · §3.5 (`test/design/wcag.dart`'s `launchSurface`, *"duplicated here deliberately: if someone edits `nSurface04` without editing the native config, this test must fail"*) · §12 (the Definition of Done line) | the rule, and the reason the duplicate constant exists |
| `docs/engineering/12-testing.md` | §1.4 (**what is a gate and what is a test** — *"if the assertion can be made by reading source text, it belongs in `tool/check_policy.dart`"*) · §11.2 (`dart_test.yaml`'s tags, and the `-P ci-fast` dispute) · §11.1 (a policy test is named for the property) | where each half of this assertion lives, and why |
| `docs/engineering/13-build-ci-release.md` | §4.3 (the `gate` job runs `check_policy` first, sub-second, before `pub get`) · §1.3 (`make check` orders itself cheapest-failure-first) | why the parity rule is in the gate rather than only in the suite |
| `docs/engineering/REFERENCES.md` | §22 D10 (the escape hatch for the storyboard half, and the manual check that survives it either way) | what "downgrade in writing" means, exactly |
| `epics/N03-the-gate/N03-T07-wire-the-gate-into-ci-and-assert-the-rule-inventory-is-compl.md` | the inventory assertion and the id grammar | `launch.colour_parity` must have a `firesOn` entry, in both directions |
| `docs/engineering/CONVENTIONS.md` | §4.7 (rule-id grammar, `launch` namespace) · R54 (dotted ids, and *"a duplicate rule is a rule that gets weakened twice"*) · R57 (the test tree) | **BINDING** on the id and the file's home |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | a gate that reads native files is still a gate and belongs in the blocking set |
| `indelible-design-system` | the token is the source of truth both native sides must match |

The cap is two auto-firing skills. `shed-conventions` is not reloaded and its one bearing is carried
here: R54's rule-id grammar, and the inventory assertion that every id in the table is exercised by a
planted case. §5.2 names the new id and §5.4 plants it, so the assertion is proved rather than
declared.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/first_frame_parity_test.dart`
- **Test** — `'the Android and iOS launch colours equal the page token and each other'`
- **Why it is red today** — the two platforms are configured by two tasks and nothing compares them.

```bash
fvm flutter test test/design/first_frame_parity_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Build a `Map<String, Color>` keyed by
**filename** — `primitives.dart`, `wcag.dart`, `night_error_panel.dart`, `colors.xml`,
`LaunchScreen.storyboard`, `Main.storyboard` — read each value out of its own file, and assert the
set of distinct values has **length 1**. When it does not, the failure message prints the map, so the
first line of CI output names the file that drifted and what it drifted to. That is the whole design:
six sources, one assertion, a message you can act on without opening anything.

To see it fail for the right reason, plant one channel of one storyboard off by two and watch the
message name that storyboard — then revert. A parity assertion that has never been seen to fail is
indistinguishable from a parity assertion that reads the same file twice.

**Green.** The minimum code that passes, and nothing beyond it — the parity assertion, in the blocking set, with a message naming which side drifted.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

Test tier and gate only. No schema, no domain, no data, no wiring, no controller, no widget, no ARB —
say so in the commit message.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/design/first_frame_parity_test.dart` | **Completed.** T06 created it with the Android group, T07 added the iOS group; this task adds the cross-platform group and the six-source map. One file, three groups, one shared reader |
| 2 | `tool/check_policy.dart` | **Completed.** `launch.colour_parity` gains its fifth assertion — the two platforms against each other — and its failure message gains the filename |
| 3 | `test/policy/gate_rules_test.dart` | **Extended.** A `firesOn` case for the cross-platform half, and a reverse-direction check that no `firesOn` entry names a rule the table no longer has |
| 4 | `dart_test.yaml` | **Read, and almost certainly not edited.** The gate must run in the blocking set; it is untagged, so it already does. Add a tag **only** if you have a reason, and know that `12 §11.2` is unresolved on whether `flutter test` honours `-P` at all |

### 5.2 The shape

One reader per source, one comparison, one message. The six sources and how each is read:

| Source | How it is read | Owner |
|---|---|---|
| `lib/core/ui/primitives.dart` | Regex for `nSurface04` and parse the `0x…` literal | N09-T01 |
| `test/design/wcag.dart` | `launchSurface`, imported directly — it is Dart in the test tree | N09-T08 |
| `lib/core/ui/night_error_panel.dart` | Regex for its one `Color(0x…)` literal. `06 §2.4` requires it to be the base surface, and nothing else compares them | N11-T04 |
| `android/…/res/values/colors.xml` | Parse the `shed_surface_base` element; `#AARRGGBB`, alpha first | N11-T06 |
| `ios/…/LaunchScreen.storyboard` | Parse the root view's `<color key="backgroundColor">`; three floats, tolerance 1/255 | N11-T07 |
| `ios/…/Main.storyboard` | Same element, same tolerance | N11-T07 |

```dart
// test/design/first_frame_parity_test.dart — the cross-platform group.
// The failure message is the feature. `expect(distinct, hasLength(1))` with a
// reason that prints the whole map means the first line of CI output names the
// file that drifted and the value it drifted to — no bisect, no local repro.
test('the Android and iOS launch colours equal the page token and each other', () {
  final sources = <String, Color>{
    'lib/core/ui/primitives.dart':                nSurfaceFromPrimitives(),
    'test/design/wcag.dart':                      launchSurface,
    'lib/core/ui/night_error_panel.dart':         panelSurfaceFromSource(),
    'android/app/src/main/res/values/colors.xml': androidLaunchColour(),
    'ios/Runner/Base.lproj/LaunchScreen.storyboard': storyboardColour('LaunchScreen'),
    'ios/Runner/Base.lproj/Main.storyboard':         storyboardColour('Main'),
  };
  expect(sources.values.toSet(), hasLength(1), reason: _describe(sources));
});
```

The storyboard readers return a quantised `Color` — round each float to the nearest 1/255 — so the
map's values compare with `==` and the tolerance lives in exactly one function rather than in five
assertions.

### 5.3 The details that are easy to get wrong

- **The gate and the test are not redundant, and `12 §1.4` says which is which.** *"If the assertion
  can be made by reading source text, it belongs in `tool/check_policy.dart`, not in
  `test/policy/`."* So the **rule** is `launch.colour_parity` in the gate — sub-second, runs before
  `pub get`, fails the `gate` job cheaply. The **test** exists because the gate's own correctness
  needs proving (N03-T07's inventory assertion demands a `firesOn` case) and because the
  storyboard-float parsing is the fragile half and deserves its own named cases. Writing the parity
  logic twice is the mistake; **share the readers** and let the gate call them.
- **Six sources, not two.** The task title says *both platforms*, and the parity that actually
  matters is wider: `night_error_panel.dart`'s hard-coded hex is on the same first frame and is
  exempt from `token.raw_color`, so **no other rule in the project looks at it**. If it drifts, the
  error panel renders a seam against the launch colour on the one frame anybody would notice. Include
  it.
- **The Android value has alpha and the others do not.** `colors.xml` is `#AARRGGBB`; the storyboards
  have a separate `alpha` attribute; `Color(0x…)` in Dart is `0xAARRGGBB`. Normalise to a `Color`
  with alpha `0xFF` in every reader, and assert the Android alpha is exactly `FF` separately — a
  translucent launch background is a different bug with the same symptom.
- **Do not compare hex *strings*.** `#FF0A0A0B` and `#ff0a0a0b` are the same colour and different
  strings; `0.039216` and `0.0392157` are the same colour and different strings. Parse to a value,
  compare values, and let one function own the tolerance.
- **The failure message is the deliverable.** A red `expect(a, b)` with two integers in it costs
  twenty minutes at 23:00. `12 §11.1`: *"a test name that says 'works' costs ten minutes six months
  from now, when it is the only line CI shows you."* The same is true of the reason string — print
  the map, sorted by path.
- **The new rule id must satisfy the grammar and the inventory, both directions.** N03-T07 asserts
  `policyRuleIds.difference(firesOn.keys)` is empty **and** `firesOn.keys.difference(policyRuleIds)`
  is empty, and that every id matches the dotted-namespace regex. `launch.colour_parity` is one id
  with several assertions — do **not** split it into `launch.colour_parity_android` and
  `launch.colour_parity_ios`. R54: a duplicate rule is a rule that gets weakened twice.
- **`launch.colour_parity` is the one rule in `tool/check_policy.dart` that reads outside `lib/`, and
  that is a deliberate exception with a cost.** The script is otherwise a `lib/`-and-`test/` walker
  with zero dependencies. Keep the file reads guarded: if `ios/` does not exist (a Linux checkout
  building only Android), the rule must **skip that half and say so on stdout**, not crash and not
  silently pass. A gate that dies on a missing directory gets deleted by whoever hits it first.
- **`-P ci-fast` is disputed and you do not have to resolve it here.** `12 §11.2` declines to add
  presets to `dart_test.yaml` and records that **`flutter test` has no `-P` flag**, while `13 §1.3`
  and §4.3 both pass one. The Definition of Done says *"the gate is in `-P ci-fast`"* and the way to
  satisfy that today is to leave this test **untagged**: `ci-fast` excludes `golden`, so an untagged
  test is in the blocking set under either spelling. Do not tag it `slow` to make a local run
  quicker.
- **The manual check survives whatever this gate does.** `06 §9.4` and `REFERENCES` §22 D10 both say
  it: *"the manual check stays — a cold launch on both platforms in a genuinely dark room, every
  release. A screenshot test cannot catch this."* If the storyboard half is downgraded, the release
  checklist is where it lands, and `13 §12` item 4 is the line it lands on.
- **This test reads files by relative path, so it depends on the working directory.** `flutter test`
  runs from the package root, which is what makes `File('android/…')` work — and what makes the same
  test fail confusingly if anyone ever adds a second package. `01 §8.2`'s answer is that this app has
  one package and does not yet earn a second; if that changes, this test is on the list of things
  that move.

### 5.4 The full test set

`test/design/first_frame_parity_test.dart` — completed. Three groups: Android (T06), iOS (T07), and
the cross-platform group below.

| Case | What it asserts |
|---|---|
| `'the Android and iOS launch colours equal the page token and each other'` | **The anchor.** Six sources, one distinct value, and a `reason:` that prints the whole map keyed by path |
| `'the failure message names the drifting file'` | Feed the comparison a deliberately mismatched map built in the test and assert the produced message contains the offending path. **The test that makes the previous test useful** |
| `'night_error_panel.dart's hard-coded hex is the launch colour'` | Its own case, because it is exempt from `token.raw_color` and nothing else in the project reads it |
| `'the Android colour is fully opaque'` | Alpha is exactly `FF`. A translucent launch background looks like the flash it is meant to prevent |
| `'every reader normalises to the same representation'` | Parse a known value through all three reader shapes (Dart `0x…`, Android `#AARRGGBB`, storyboard floats) and assert one `Color`. The unit test for the tolerance function |
| `'the parity check skips a platform whose directory is absent, and says so'` | Point the readers at a temp directory with no `ios/`; assert no throw and a stated skip. The behaviour that keeps the gate alive on a Linux checkout |

`test/policy/gate_rules_test.dart` — completed for this rule:

| Case | What it asserts |
|---|---|
| `'launch.colour_parity fires when Android and iOS disagree with each other'` | The cross-platform half, planted |
| `'launch.colour_parity does not fire on a correctly configured tree'` | The negative. A rule that always fires is a rule that gets exempted |
| `'every rule id is proved and every proving case names a real rule'` | N03-T07's inventory assertion, re-run with the new id present in both directions |

**Nothing in this task is time-shaped**, so no `test/domain/uk_zone/` case and no `@Tags(['uk-zone'])`.

## 6. Constraints that bind this task

- **3am** — the property under test is the first thing a shepherd sees. No interactive element is
  added here, so the 64 × 64 floor and the gesture ban do not bite; the dark-only rule does, and this
  gate is its mechanism.
- **Gate integrity** — `13`'s rule is absolute: **never add an allowlist line to make a red build
  green.** If this gate goes red, the native config is wrong. The only sanctioned relaxation in this
  area is `REFERENCES` §22 D10's, it applies to **one** assertion, and it is written down when taken.
- **Offline** — no network path may be added. G2 and G3 stay green; this task adds no dependency, and
  `tool/check_policy.dart` still has zero.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the Android and iOS launch colours equal the page token and each other'` passes, and was seen to fail first for the stated reason
- [ ] the gate compares both platforms and the token
- [ ] the failure message names the drifting file
- [ ] the gate is in `-P ci-fast`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **all six sources** are compared, including `night_error_panel.dart`'s exempt hex
- [ ] the parity logic exists once — the gate and the test share their readers — and the tolerance lives in one function
- [ ] `launch.colour_parity` is **one** rule id, matches `CONVENTIONS §4.7`'s grammar, and satisfies N03-T07's inventory assertion in both directions
- [ ] the rule skips a missing platform directory with a message and does not crash
- [ ] the drift was **seen** — a planted one-channel change produced a message naming the file, and was reverted

## 8. Verification

```bash
fvm flutter test test/design/first_frame_parity_test.dart
fvm flutter test test/policy/gate_rules_test.dart
dart tool/check_policy.dart          # prints `policy ok`
make check
make test
```

Then see it fire, once, because a parity gate nobody has watched fail is indistinguishable from a
broken one:

```bash
# Plant a drift in the layer that is hardest to notice, and confirm the message.
sed -i.bak 's/red="0.039216"/red="0.041216"/' ios/Runner/Base.lproj/Main.storyboard
fvm flutter test test/design/first_frame_parity_test.dart
# expect: FAILED, and the message names ios/Runner/Base.lproj/Main.storyboard
mv ios/Runner/Base.lproj/Main.storyboard.bak ios/Runner/Base.lproj/Main.storyboard

# And the cheap one, on the other platform.
sed -i.bak 's/#FF0A0A0B/#FF0B0D0E/' android/app/src/main/res/values/colors.xml
dart tool/check_policy.dart
# expect: exit 1, launch.colour_parity, naming colors.xml
mv android/app/src/main/res/values/colors.xml.bak android/app/src/main/res/values/colors.xml
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(design): the first-frame parity gate`
