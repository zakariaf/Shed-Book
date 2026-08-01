---
name: shed-conventions
description: >-
  The naming and layering authority — the tree, the eight layer rules, the banned words. Use before
  naming any file, class, provider, key or column, and before deciding whether one folder may import
  another. Do NOT use for what a column stores (shed-drift-schema).
---

# Shed Book — naming and layering

`docs/engineering/CONVENTIONS.md` is BINDING and outranks this skill on any name, path, type shape or
signature. This skill carries the operative rule; that file carries the catalogue and the reasoning.
Cite rulings by number (`per CONVENTIONS R27`), and never re-type a signature from `§2` or a provider
row from `§3` — read them.

## The tree

One package, no `lib/src/`. Create it exactly as `CONVENTIONS §1` prints it:

```bash
mkdir -p lib/l10n \
         lib/domain/{time,units,withdrawal,stats,validation,terminology,policy} \
         lib/core/{db/{tables,seed},time,log,ui/components} \
         lib/data lib/routing \
         lib/features/{quick_entry,flock,lambing,pens,treatments,reminders,season,export,settings}/widgets \
         tool drift_schemas assets/{fonts,content} \
         test/{domain/uk_zone,data,drift/generated,design,features,policy,support,fixtures} \
         integration_test
```

Nine feature folders for twelve screens — a feature is a functional requirement, not a screen (Lamb
Card and Foster live in `lambing/`). `lib/data/` is **flat** (R18); its repository set is twelve and
closed (R19), its gateway set seven (§2.12, R74). Read `CONVENTIONS §1` for what each file holds
before creating any file not in that `mkdir`.

## The eight layer rules and the two path-pair bans

`tool/check_policy.dart` enforces every row. Scanned roots are `lib/` and `test/`; layer *direction*
applies only under `lib/`.

| # | From | May import | Never | Rule id |
|---|---|---|---|---|
| 1 | `lib/domain/` | `lib/domain/`, `dart:*`, `meta`, `collection` | flutter, drift, riverpod, sqlite3, intl, **clock** (R24), every other layer | `layer.domain` |
| 2 | `lib/core/db/` | `lib/core/db/`, `lib/core/` (R16), `lib/domain/`, drift, sqlite3, uuid (R15), clock, `flutter/foundation.dart` | `lib/data/`, `lib/features/`, `lib/core/ui/`, `flutter/material.dart` | `layer.core_db` |
| 3 | `lib/data/` | `lib/data/`, `lib/core/*`, `lib/domain/` **except** `validation/`, drift, sqlite3, clock, collection, intl, timezone | `lib/features/`, `lib/domain/validation/` | `layer.data` |
| 4 | `lib/data/` | — | `flutter/material.dart`, `flutter/cupertino.dart` | `layer.data_no_material` |
| 5 | `lib/features/` | own feature, `lib/data/`, `lib/domain/`, `lib/core/`, `lib/core/ui/`, `lib/routing/` | `lib/core/db/`, drift, sqlite3 | `layer.features` |
| 6 | `lib/features/<a>/` | — | `lib/features/<b>/` — **path-pair** | `layer.sibling` |
| 7 | `lib/core/ui/` | `lib/core/ui/`, `lib/domain/`, `flutter/*`, intl (in `formatters.dart` only) | `lib/data/`, `lib/core/db/`, drift | `layer.core_ui` |
| 8 | anything outside `lib/data/` | — | any mutating drift API; `customStatement(` outside `lib/core/db/`; sqlite3 outside `lib/data/` + `lib/core/db/` | `layer.single_writer` |
| + | `lib/main.dart`, `lib/app.dart` | — | `lib/core/db/`, drift, sqlite3 | `layer.root` |
| + | `lib/data/**` | — | `lib/domain/validation/**` (R53) — **path-pair** | `layer.data_no_validation` |

Gotchas that decide real edits:

- `lib/core/ui/` is **not** inside `lib/core/` for this gate — `_layerOf` matches the most specific
  prefix first, so rule 2's allowance of `lib/core/` never reaches it. A `lib/core/db/` file
  importing a token is still a violation.
- The two path-pair bans are **not** in `_mayImport`; each has its own row in the driver, because
  `lib/data/` may import the rest of `lib/domain/` freely. R53's consequence — a repository cannot
  see a `Warning`, so it returns `WriteCommitted(insertedId: …)` and the **controller** runs the
  validators. That is spec §12.4's structural mechanism, not a style preference.
- `lib/routing/` and `lib/features/` import each other **deliberately**. Rule 6 fires only when the
  *importing* file is under `lib/features/`, so `routes.dart` is the one file allowed to name all
  nine features — keep it to `Navigator` calls and screen constructors.
- `lib/features/` reaches a drift row class through `lib/data/models.dart` (rows only), never
  `lib/core/db/database.dart` — that import is what rule 5 exists to catch.
- Fix a sibling import by moving the shared piece into `lib/data/` or `lib/domain/`. Moving it into
  `lib/core/ui/` is not a fix; rule 7 forbids a repository there.
- `tool/` is deliberately **not** scanned — its own rule tables contain every banned literal.

## Naming shapes

| Thing | File | Class / identifier |
|---|---|---|
| Any Dart file | `lower_snake_case.dart` | — |
| Screen | `<screen>_screen.dart` | `<Screen>Screen`, state `<Screen>State` |
| Screen controller | `<screen>_controller.dart` | `<Screen>Controller` — screen state, never data |
| Write controller | `<feature>_write_controller.dart`, or the screen controller's file if it is one small class | `<Feature>WriteController extends WriteController` |
| Repository | `<area>_repository.dart` | `<Area>Repository` — the only code that may write |
| Gateway / service | `<name>.dart` matching the class in `lower_snake` | `<Name>Service` · `Store` · `Scheduler` · `Recorder` · `Controller` |
| drift table / row | `lib/core/db/tables/<cluster>.dart` | plural `PascalCase` / singular `PascalCase` |
| Shared component | `lib/core/ui/components/shed_<thing>.dart` | `Shed*` |
| Value type, sealed result | — | no suffix; variants are nouns (`Instant`, `WriteCommitted`) |
| Test | mirrors the file under test, `_test.dart` | policy tests are named for the **property** |

**Banned suffixes:** `Manager`, `Helper`, `Util`, `Handler`, `Impl`, `Abstract*`. `DatabaseService` is
banned outright — `AppDatabase` is already the data-source wrapper. **Banned paths:** `lib/src/`,
`utils.dart`, `constants.dart`, a `models/` folder, and `shared/`, `common/` or `data/` under
`lib/features/`. The gate cannot see a badly named folder; that one is on you.

**Providers** (§4.3) — `<typeNameLowerCamel>Provider`, a top-level `final` global in the file `§3`
assigns it. Read providers are named for **what they read** (`penBoardProvider`), never the screen;
controller providers for **the screen** (`penBoardControllerProvider`); a family provider's name is
singular. Exactly five documented exceptions and no sixth — `databaseProvider`, `settingsProvider`,
`wakelockProvider`, `minuteTickProvider`, `tagIndexProvider`. Several plausible names are **banned
spellings**; check `CONVENTIONS §3.2–§3.4` before declaring one.

**Controllers** (§4.4) — one screen controller per screen, one write controller per feature, every
mutation through `WriteController.guard()`. Controllers hold no `BuildContext`, never navigate, never
format for display, never import drift, and never hold a draft — every write commits immediately, so
there is no Save button. What the user typed lives in a private field on the notifier, not only in
`state`.

**Widget keys** (§4.5, R59) — `<screen>.<element>[.<qualifier>]`, every segment `lower_snake`, joined
by `.`, e.g. `quick_entry.keypad.digit_4`, `pen_board.turn_out.3`. `Key('birthType.twin')` is a defect
twice over — camelCase segments, and there is no birth-type control to key: birth type is **derived
from the tally strokes** and labelled as derived (owner ruling P8). A key is a test contract, so
renaming one breaks `test/features/`.

**Database names** (§4.6) — Dart `lowerCamel` / SQL `snake_case`; tables plural both sides; index
`idx_<table-abbrev>_<columns>`; named `.drift` query `lowerCamel`; view a `snake_case` noun; stored
enum keys `snake_case` ASCII, **frozen forever**. Two spellings that defy the obvious guess: a
foreign-key column is the parent's **singular noun with no `_id` suffix** (`ewe`, `lambing`,
`season`), and the provenance quad is `captured_at`, `original_effective`, `time_source` — never
`original_effective_at` (R38). Event time is `occurred_at`, three documented exceptions (R37). A
drift table not ending in a plain `s` generates a broken row class — check the generated name and
annotate with `@DataClassName` (R7, R20).

## Policy rule ids

Dotted `namespace.name`, every segment `lower_snake` (R54). The namespace must be one of the seventeen
in `CONVENTIONS §4.7` — do not invent an eighteenth, and do not add a rule duplicating an existing row
(a duplicated rule is a rule weakened twice). A new rule is **one row added to
`tool/check_policy.dart`**, never a second script; decisions #9/#10 mandate one gate, one allowlist,
one exit code. `tool/policy_allowlist.txt`'s `[exempt]` has exactly four lines (R56) — a fifth is a
review conversation, not an edit.

## Do NOT use for

- What a column **stores** — type, `CHECK`, index, FK action, migration → `shed-drift-schema`. This
  skill owns the spelling only.
- Copy, user-facing wording, semantics labels, the one-word-per-concept vocabulary and its banned
  words → `shed-accessibility-and-copy` and `CLAUDE.md`.
- A provider's **type**, scope or auto-dispose policy → `shed-riverpod-providers` (`CONVENTIONS §3`).

## Done when

- [ ] `dart tool/check_policy.dart` prints `policy ok` and exits 0.
- [ ] Every new path is in `CONVENTIONS §1`'s tree, or a numbered ruling adding it exists.
- [ ] No new file sits under `lib/src/`, `utils.dart`, `constants.dart`, a `models/` folder, or
      `shared/` · `common/` · `data/` inside `lib/features/`.
- [ ] Every new class ends in a suffix from the table above, none in a banned one.
- [ ] Every new provider matches `<typeNameLowerCamel>Provider` or is one of the five §4.3
      exceptions, and is not a banned spelling from `§3.2–§3.4`.
- [ ] Every new widget key is `<screen>.<element>[.<qualifier>]`, all `lower_snake`.
- [ ] Every new rule id uses a §4.7 namespace and is one row in `tool/check_policy.dart`; `[exempt]`
      still has four lines.
- [ ] Any sibling import was resolved into `lib/data/` or `lib/domain/`, not `lib/core/ui/`.
