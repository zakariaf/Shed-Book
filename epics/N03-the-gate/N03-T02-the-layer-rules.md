# N03-T02 — The layer rules

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 2 of 7 |
| **Depends on** | N03-T01 |
| **Commit** | one commit · `feat: the ten layer rules, each proved by a planted violation` |

## 1. Why this task exists

The eight layer rules plus `layer.sibling` and `layer.data_no_validation`. The last one is
a §12.4 **structural** mechanism, not a style rule: a repository that cannot import
`lib/domain/validation/` is a repository incapable of producing or persisting a warning. Each rule is
planted, watched to fire, and the planted file deleted — in this commit, not in a thirty-cycle task at
the end of the epic.

They land now, on an empty tree, because `00-README` §9 step 1 says a gate is *"impossible to
retrofit across twelve screens"* and rule 6 is the one it names as rotting first: *"Foster needs Ewe
and Lambing; the easy move is `import '../flock/…'`, and that is how a feature-first tree becomes a
ball of mud in one season."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §3.1 | the eight rules with the failure each prevents, and the rule id for each |
| `docs/engineering/01-architecture.md` | §3.2 | `_layers`, `_mayImport`, `_bannedPackages`, `_bannedPathPairs`, `_resolveRelative`, and the driver's import loop |
| `docs/engineering/CONVENTIONS.md` | §1.1 | the amended layer table — R16 and R53 are already folded in; this is the version that binds |
| `docs/engineering/CONVENTIONS.md` | §6 R16, R24, R53 | why `lib/core/db/` may import `lib/core/`, why `package:clock` is banned in the domain, why `lib/data/` may not see a `Warning` |
| `docs/engineering/00-README.md` | §2.3 §12.4 | the safety rule `layer.data_no_validation` holds, and the level it is held at |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | §1's tree and its import rules are exactly what these rules encode |
| `shed-safety-rules` | `layer.data_no_validation` is how §12.4 stops being procedural |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'layer.features_no_db exits 1 on a planted drift import under lib/features/'`
- **Why it is red today** — the rule table is empty, so a drift import in a feature file passes.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The assertion, spelled out: plant `lib/features/flock/flock_screen.dart` containing
`import 'package:drift/drift.dart';` into the temp tree, and assert the returned violations contain
exactly one message, that it names the file, and that its bracketed id is **`layer.features`** —
§3.1's id for rule 5. The test title is the backlog's anchor and stays as written; the id the
assertion matches on is `CONVENTIONS` §1.1's, because `CONVENTIONS` outranks a task title on any name.

**Green.** The minimum code that passes, and nothing beyond it — ten rules, each with an id, a message naming the id, and a test that plants and removes
its violation in a temp directory.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

This task reaches no schema, domain, data, controller, UI or ARB layer — say so in the commit
message, per `00-README` §8. Two files change.

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | `_layers`, `_mayImport`, `_bannedPackages` and `_bannedPathPairs` are filled in from `CONVENTIONS` §1.1; the import loop is added to the walk from N03-T01; `_resolveRelative` and `_layerOf` arrive with it; `policyRuleIds` starts yielding |
| 2 | `test/policy/gate_rules_test.dart` | Ten planting cases plus the six edge cases in §5.4, all through `gateOn` from N03-T01 |

No allowlist line is added. **No layer rule has an exemption**, on day one or ever — R56's four
lines are all text rules, and a layer violation with a waiver is a layer that has been deleted.

### 5.2 The signatures

The ten ids, spelled exactly as `CONVENTIONS` §1.1 and §3.1 spell them:

`layer.domain` · `layer.core_db` · `layer.data` · `layer.data_no_material` · `layer.features` ·
`layer.sibling` · `layer.core_ui` · `layer.single_writer` · `layer.root` · `layer.data_no_validation`

The tables, from `CONVENTIONS` §1.1 — copy them, do not re-derive them:

```dart
/// Most specific prefix first — _layerOf returns the first match. lib/core/ui/
/// must precede lib/core/, or rule 2's ban on lib/core/ui/ never fires.
const _layers = <String>[
  'lib/core/db/', 'lib/core/ui/', 'lib/core/', 'lib/domain/',
  'lib/data/', 'lib/features/', 'lib/routing/', 'lib/',
];

const _mayImport = <String, Set<String>>{
  'lib/domain/':   {'lib/domain/'},
  'lib/core/db/':  {'lib/core/db/', 'lib/core/', 'lib/domain/'},   // R16
  'lib/core/ui/':  {'lib/core/ui/', 'lib/domain/'},
  'lib/core/':     {'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
  'lib/data/':     {'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
  'lib/features/': {'lib/features/', 'lib/data/', 'lib/domain/', 'lib/core/',
                    'lib/core/ui/', 'lib/routing/'},
  'lib/routing/':  {'lib/routing/', 'lib/features/', 'lib/data/', 'lib/core/', 'lib/domain/'},
  'lib/':          {'lib/', 'lib/core/', 'lib/core/ui/', 'lib/data/', 'lib/domain/',
                    'lib/features/', 'lib/routing/'},
};

const _bannedPackages = <String, Set<String>>{
  // R24: package:clock is banned in the domain. A pure function that needs the
  // current instant takes it as a parameter: timeSincePenned(enteredAt, now).
  'lib/domain/':   {'package:flutter/', 'package:drift/', 'package:sqlite3',
                    'package:flutter_riverpod/', 'package:riverpod/', 'package:intl/',
                    'package:clock/'},
  'lib/data/':     {'package:flutter/material.dart', 'package:flutter/cupertino.dart'},
  'lib/core/ui/':  {'package:drift/', 'package:sqlite3'},
  'lib/features/': {'package:drift/', 'package:sqlite3'},
  'lib/routing/':  {'package:drift/', 'package:sqlite3'},
  'lib/':          {'package:drift/', 'package:sqlite3'},
};

/// Path-pair bans. Not expressible in _mayImport, because lib/data/ may import
/// the rest of lib/domain/ freely. R53 — spec §12.4's structural half.
const _bannedPathPairs = <(String, String, String)>[
  ('layer.data_no_validation', 'lib/data/', 'lib/domain/validation/'),
];
```

And the one addition this task makes to `01-architecture.md` §3.2's printed driver — a map from the
importing layer to the id the violation is reported under:

```dart
/// §3.1 gives every layer its own rule id; §3.2's driver emits the generic
/// `layer.direction` / `layer.import` instead, which N03-T07's inventory
/// assertion cannot match against the table. Report the specific id.
const _directionRuleId = <String, String>{
  'lib/domain/': 'layer.domain',   'lib/core/db/': 'layer.core_db',
  'lib/core/ui/': 'layer.core_ui', 'lib/core/':   'layer.core_ui',
  'lib/data/':   'layer.data',     'lib/features/': 'layer.features',
  'lib/routing/': 'layer.features', 'lib/': 'layer.root',
};
```

### 5.3 The details that are easy to get wrong

- **`_layers` order is the rule.** `_layerOf` returns the first prefix that matches, so
  `'lib/core/ui/'` and `'lib/core/db/'` must both precede `'lib/core/'`, and `'lib/'` must be last.
  Sort that list alphabetically — a plausible tidy-up — and `lib/core/db/database.dart` resolves to
  layer `lib/core/`, which *is* allowed to import `lib/core/ui/`, and R16's carefully drawn line
  disappears with no test failing.
- **The printed driver emits two ids that are not in the table.** `[layer.direction]` and
  `[layer.import]` appear in `01-architecture.md` §3.2's `main()`; neither is one of §3.1's ten.
  Leave it as printed and N03-T07's inventory assertion has ten ids with no proving case and two
  proving cases with no id. Map the importing layer to its id, as above. `lib/routing/` shares
  `layer.features` because §3.1 gives routing no id of its own and the two-way routing↔features edge
  is deliberate.
- **`lib/routing/` and `lib/features/` import each other on purpose** (01 §3.1). Rule 6 only fires
  when the *importing* file is under `lib/features/`, so routing may name all nine features and a
  feature still may not name a sibling. Do not "fix" the asymmetry.
- **`layer.sibling` reads the third path segment**: `from.split('/')[2]`. For
  `lib/features/flock/flock_screen.dart` that is `flock`. For a file placed directly at
  `lib/features/something.dart` it is `something.dart`, which compares unequal to every folder name —
  harmless, but it means a stray file at the top of `lib/features/` is treated as its own feature.
  Nine feature folders are fixed by `CONVENTIONS` §1; a tenth is a review conversation, not a gate
  failure.
- **`layer.root` is not a separate mechanism.** It is `_mayImport['lib/']` omitting `'lib/core/db/'`
  plus `_bannedPackages['lib/']` banning drift and sqlite3. `lib/main.dart` and `lib/app.dart` are
  the only two files that resolve to layer `'lib/'`. Adding a third file at the root of `lib/` puts
  it under the same rule, which is correct and worth knowing before you try it.
- **`layer.data_no_validation` is checked before the direction check and independently of it.**
  `lib/data/` *may* import `lib/domain/`, so `_mayImport` cannot express this; it is a path pair. It
  is also the only rule in this task that a reviewer must never wave through: it is spec §12.4's
  structural half, and if it drops to merely documented the rule has been deleted whatever the prose
  says (`00-README` §10, amendment rule item 5).
- **Package bans and path bans travel different code paths.** `layer.data_no_material` is a
  *package* ban (`package:flutter/material.dart` under `lib/data/`), not a direction rule. A
  `package:` URI that is not banned is skipped before `_resolveRelative` ever runs — so
  `import 'package:collection/collection.dart'` in the domain is legal and must stay legal.
- **`package:shed_book/...` and a relative import are the same import.** The driver rewrites
  `package:$_package/foo.dart` to `lib/foo.dart` and resolves `../../data/models.dart` with
  `_resolveRelative`. Both spellings must be planted in the tests, because a developer who learns the
  gate only catches one will use the other. `_resolveRelative` normalises `..` by popping segments and
  does not clamp at the root — a path with more `..` than depth silently escapes `lib/`, resolves to
  no layer, and is skipped. That is acceptable (the analyzer rejects it anyway) but plant it once so
  the behaviour is recorded rather than discovered.
- **Conditional imports and `export`.** The `_directive` regex matches `import` *and* `export`, so a
  re-export is a layer violation exactly as an import is — which is what makes
  `lib/data/models.dart` (R20, the one file that re-exports every drift row type) a legal
  concentration point rather than a hole. `import ... if (dart.library.io)` configurable imports are
  not matched by the regex; there are none in this project and none is permitted.
- **`layer.single_writer` is half here and half in N03-T06.** The import half — `package:drift/` and
  `package:sqlite3` banned outside `lib/data/` and `lib/core/db/` — is `_bannedPackages` above. The
  text half — `customStatement(` outside `lib/core/db/` — is the `db.raw_statement` row, and it lands
  with the other `db.*` rows in N03-T06. Say which half is which in the commit message so the next
  reader does not add a duplicate row; a duplicated rule is a rule that gets weakened twice (R54).

### 5.4 The full test set

Ten planting cases — one per rule, each planting into the temp tree and asserting the id — plus the
edge cases that would otherwise be found by a screen epic in four months:

| Case | Plant | Expect |
|---|---|---|
| `layer.domain` | `lib/domain/withdrawal/clear_date.dart` imports `package:clock/clock.dart` | one violation, id `layer.domain` (R24 — the domain takes `now` as a parameter) |
| `layer.core_db` | `lib/core/db/database.dart` imports `package:shed_book/core/ui/tokens.dart` | one violation, id `layer.core_db` — R16 lets it reach `lib/core/`, not `lib/core/ui/` |
| `layer.data` | `lib/data/flock_repository.dart` imports `../features/flock/flock_screen.dart` | one violation, id `layer.data` |
| `layer.data_no_material` | `lib/data/lambing_repository.dart` imports `package:flutter/material.dart` | one violation, id `layer.data_no_material` |
| `layer.features` (the anchor) | `lib/features/flock/flock_screen.dart` imports `package:drift/drift.dart` | one violation, id `layer.features` |
| `layer.sibling` | `lib/features/lambing/foster_screen.dart` imports `../flock/ewe_card_screen.dart` | one violation, id `layer.sibling`, message naming both features and the move-it-to-`lib/data/` remedy |
| `layer.core_ui` | `lib/core/ui/components/shed_pen_tile.dart` imports `package:shed_book/data/models.dart` | one violation, id `layer.core_ui` |
| `layer.single_writer` | `lib/features/pens/pen_board_screen.dart` imports `package:sqlite3/sqlite3.dart` | one violation, id `layer.features` for the layer and `layer.single_writer` for the writer ban — assert whichever the table emits, and assert only one message |
| `layer.root` | `lib/main.dart` imports `package:shed_book/core/db/database.dart` | one violation, id `layer.root` |
| `layer.data_no_validation` | `lib/data/lambing_repository.dart` imports `package:shed_book/domain/validation/warning.dart` | one violation, id `layer.data_no_validation` |
| **edge** — legal domain import | `lib/domain/stats/losses.dart` imports `package:collection/collection.dart` and `dart:math` | zero violations |
| **edge** — legal data→domain import | `lib/data/treatment_repository.dart` imports `package:shed_book/domain/withdrawal/clear_date.dart` | zero violations; only `lib/domain/validation/` is closed to it |
| **edge** — routing may name a feature | `lib/routing/routes.dart` imports `../features/flock/flock_screen.dart` | zero violations |
| **edge** — a feature may name itself | `lib/features/flock/flock_screen.dart` imports `widgets/ewe_row.dart` | zero violations |
| **edge** — `export` counts | `lib/data/models.dart` exports `../features/flock/flock_screen.dart` | one violation, same id as the import form |
| **edge** — the two spellings agree | the same violation planted as `package:shed_book/…` and as `../../…` | identical id, identical count |
| **edge** — no direction rule outside `lib/` | `test/support/harness.dart` imports `package:shed_book/core/db/database.dart` | zero violations — the test tier is allowed to reach the database, and `_layerOf` returns null under `test/` |

Every planting case deletes its temp tree in `addTearDown`. Nothing here is time-shaped, so there is
no `uk-zone` case.

## 6. Constraints that bind this task

- **The five safety rules** — §12.4, *never silently correct a user's entry*, is held here at the **unrepresentable** level: `lib/data/` cannot import `lib/domain/validation/`, so a repository cannot construct a `Warning`, so `WriteCommitted.warnings` can only ever be populated by a controller (R53). A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **One script** — decision #10. These are rows and table entries in `tool/check_policy.dart`; no analyzer plugin, no second scanner. Every candidate — `import_lint`, `custom_lint`, `dart_code_metrics` — is unresolvable, archived or discontinued on this stack (01 §3.1).
- **No layer rule takes an `[exempt]` line.** R56's four are text rules. If a layer rule fires on legitimate code, the code is in the wrong folder.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'layer.features_no_db exits 1 on a planted drift import under lib/features/'` passes, and was seen to fail first for the stated reason
- [ ] all ten rules exist and each has been watched to fire
- [ ] `lib/data/**` importing `lib/domain/validation/` exits 1
- [ ] a sibling feature import exits 1
- [ ] no rule scans a generated file
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart run tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

Then watch two of the ten fire against the real tree, which is what *"watched to fire"* means:

```bash
mkdir -p lib/features/lambing lib/data
printf "import '../flock/ewe_card_screen.dart';\n" > lib/features/lambing/_plant.dart
printf "import 'package:shed_book/domain/validation/warning.dart';\n" > lib/data/_plant.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # two POLICY lines, exit=1
rm lib/features/lambing/_plant.dart lib/data/_plant.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # policy ok, exit=0
make check
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: the ten layer rules, each proved by a planted violation`
