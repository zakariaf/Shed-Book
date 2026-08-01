# N29-T03 — Terminology editing through `terminology_overrides`

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 3 of 8 |
| **Depends on** | N29-T02 |
| **Commit** | one commit · `feat(settings): terminology editing through overrides` |

## 1. Why this task exists

Rename *ewe* to *gimmer* and the whole app says gimmer — including the ARB messages, which
carry the term as a **placeholder** fed by `terminologyProvider` and never as a literal.

The reason the overlay exists at all is `05 §8`: these words *"are not synonyms and not a clean
taxonomy."* The National Sheep Association's own glossary defines *gimmer* by age plus parity,
*shearling* by **dentition**, and *hogget* by age — three different measuring sticks for overlapping
classes, disagreeing inside one national body's glossary, and disagreeing again by county. There is no
canonical taxonomy to normalise to, which kills both naive designs and leaves exactly one shape: a
closed `AnimalClass` enum in the data, and a user-editable label overlay at the presentation edge.

`AnimalClass`, `TermLabel`, `Terminology` and `validateOverride` all shipped in **N06-T08**.
`terminologyProvider` has been in the DI graph since **N12-T02**, resolving overrides over an injected
default map. `terminology_overrides` was frozen at **N07-T08**. What has never existed is a way for a
shepherd to write a row into it — and `SettingsRepository` currently only *reads* the table.

This task is therefore the one place in N29 that adds a repository verb.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§8.1** (`AnimalClass`'s seven keys; `TermLabel`; `Terminology.labelFor`; *"seeding happens in `lib/features/settings/terminology_bootstrap.dart`, which already has a `BuildContext`"*) · **§8.2** (the ARB frame / terminology noun split; `singularTerm` / `pluralTerm`, never `singular` / `plural`) · **§8.3** (export headers — a user-editable label **never** becomes a machine value) · **§8.4** (`validateOverride`: reject, do not sanitise; the 24-character 3am cap; trimming is the one exception) | the shape, the rules and the validator |
| `docs/engineering/10-accessibility-and-i18n.md` | **§8.5** (the terminology-placeholder rule in full; the wrong and right ARB messages side by side; *"the failure mode that survives code review"*; the seven default pairs; **semantics labels use the user's noun too**) · §8.4 (ARB house rules; `description` carries the safety rationale) · §3.2 rule 8 · §3.3 (`spellOutTag` applies to the **tag range only**) | the ARB half and the announcement |
| `docs/engineering/03-data-model-and-schema.md` | **§5.12** (`TerminologyOverrides`: `key`, `singular`, `plural`, `PRIMARY KEY {key}`, `STRICT`; and `VocabTerms` beside it, which this task does **not** touch) · §5.14 (`SettingsRepository` owns `terminology_overrides`) | the table and its shape |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`SettingsRepository` owns `app_settings`, `vocab_terms`, `terminology_overrides`) · §2.14 (`Terminology`, `TermLabel`) · §3.1 (`terminologyProvider : Provider<Terminology>`) · §4.5 + R59 · **R66** (the ~40 vocabulary labels have three homes — this task touches none of them) · §5.1 (the vocabulary table) | **BINDING** on the verbs, the table and the words |
| `docs/engineering/07-screens.md` | **§14.3 row 2** (Terminology: the editable `TermLabel` overlay; *"seeded here, in a `BuildContext`-bearing feature, never in `domain/` or `data/`. **A locale change or an app update never overwrites a user's term**"*) · §14.4 (≤ 2 taps) | where the seeding lives |
| `docs/design/indelible.md` | **§8 screen 12** (*"Terminology as five text fields with the label above … freely editable, because these vary by county let alone by country, and whatever the shepherd types is what the app then prints everywhere including the exports"*) · **§7.12** (text field: 64 px line, label above, rule below, **never a placeholder inside a field**) | the control |
| `docs/engineering/09-export-formats.md` | §5 (the JSON backup's top-level `terminology` block) · the CSV header rule | why the rename must reach the backup and not the headers |
| `docs/engineering/01-architecture.md` | §4.1–§4.3 (event verbs, one transaction each) · §3.1 layer rules (why `lib/data/` may not import `AppLocalizations`) | the two new verbs' shape |
| `docs/research/00-tech-decisions.md` | #108 (gen-l10n, `use-named-parameters: true`, `nullable-getter: false`) · §7.0 ruling 3 (en_GB, one locale in v1) | the generated signature |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the placeholder rule and the ARB's descriptions |
| `shed-write-path` | the override write, committed immediately |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'renaming ewe to gimmer changes every user-facing rendering and no ARB message carries a domain noun as a literal'`
- **Why it is red today** — terminology is resolvable but not editable, and spec §7.10 requires editing.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen it into **two assertions that fail for two different reasons**, because they defend two
different things and one of them cannot be caught by rendering:

1. **The behaviour.** Enter `gimmer` / `gimmers` into `settings.terminology.ewe.singular` and
   `.plural`; pump the Flock screen and the Ewe Card; assert both render the new noun **and** that
   `terminology_overrides` holds one row keyed `ewe`. Then pump the same screens after clearing the
   override and assert they render `ewe` again from the shipped default.
2. **The source text.** Read `lib/l10n/app_en.arb`, take every message value, and assert that none of
   the fourteen default nouns — `ewe`, `ewes`, `gimmer`, `gimmers`, `ewe lamb`, `ewe lambs`, `ram`,
   `rams`, `ram lamb`, `ram lambs`, `wether`, `wethers`, `lamb`, `lambs` — appears as a word in any of
   them, **except** in the seven `term*Singular` / `term*Plural` messages, which are the defaults
   themselves. Build the exception list from the `AnimalClass` values, not from a literal list, so an
   eighth class cannot slip past.

Assertion 2 is the one that matters. Assertion 1 passes against an implementation whose Flock screen
happens to use the placeholder while the Reminders notification body says "ewe" — and a lock-screen
string is the copy nobody reads (`N25` epic, risk 2).

**Green.** The minimum code that passes, and nothing beyond it — the editor, the override write, and an ARB scan for literal domain nouns.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 3 (write path), 6 (UI), 7 (ARB) and 8 (tests).** No schema — `terminology_overrides` was
frozen at N07-T08 and this task adds no column. No domain — `AnimalClass`, `TermLabel`, `Terminology`
and `validateOverride` all shipped in N06-T08. **Say both out loud in the commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/settings_repository.dart` | **Edit.** Two new verbs — `setTerminologyOverride` and `clearTerminologyOverride`. `CONVENTIONS` §2.13 already assigns `terminology_overrides` to this repository; N12-T02 only added the read (`watchTerminologyOverrides`). **This is the only repository edit in N29** |
| 2 | `lib/features/settings/terminology_bootstrap.dart` | **New.** The one place the shipped en-GB defaults are read out of `AppLocalizations` and handed to `terminologyDefaultsProvider`'s consumer. `05 §8.1` and `10 §8.5` both put it here **by name**, because `lib/domain/` and `lib/data/` are forbidden by layer rules 1 and 3 from importing `AppLocalizations` |
| 3 | `lib/features/settings/widgets/terminology_section.dart` | **New.** Section 2: seven label/value pairs, each two `ShedFieldRow`s (singular, plural), each committing on its own |
| 4 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `setTerm(AnimalClass, String singular, String plural)` and `clearTerm(AnimalClass)`, both `guard()`ed, both running `validateOverride` **before** the repository call |
| 5 | `lib/features/settings/settings_screen.dart` | **Edit.** Slot the section into `SettingsSection.terminology` |
| 6 | `lib/l10n/app_en.arb` | **Edit.** The section strings, the seven class labels, the two rejection messages — and an **audit** of every existing message for a literal domain noun. If the audit finds one, fixing it is part of this commit |
| 7 | `test/features/settings_test.dart` | **Edit.** The behaviour half of the anchor and the cases in §5.4 |
| 8 | `test/policy/no_domain_noun_is_a_literal_test.dart` | **New.** The source-text half. `CONVENTIONS` §4.1: a policy test *"states the property, not the file"* |

### 5.2 The signatures

```dart
// lib/data/settings_repository.dart — the two verbs this task adds.
//
// terminology_overrides is a PREFERENCE OVERLAY, not a record (03 §5.12: "a
// closed AnimalClass enum lives in the domain; this table is the overlay").
// The §12.5 corollary — "a table without the provenance quad has no edit verb"
// — governs tables holding the shepherd's records. This one holds fourteen
// strings the shepherd typed about vocabulary, exactly like app_settings.

/// Upsert on the primary key. Unlike `app_settings` — which is an UPDATE over
/// `where(id.equals(1))` because its row is seeded — a terminology row does not
/// exist until the shepherd renames something.
Future<WriteOutcome> setTerminologyOverride(AnimalClass c, TermLabel label);

/// A DELETE, returning the class to its shipped ARB default. NOT a write of
/// two empty strings: `singular` and `plural` are NOT NULL, so blanks would
/// store, and `Terminology.labelFor` would fall through to the default anyway
/// — leaving a row that says nothing and exports as noise (09 §5).
Future<WriteOutcome> clearTerminologyOverride(AnimalClass c);
```

```dart
// lib/features/settings/terminology_bootstrap.dart
//
// THE ONLY place AppLocalizations is read for a terminology default.
// 05 §8.1 and 10 §8.5 both name this file. Layer rule 1 forbids lib/domain/
// from importing package:flutter at all; layer rule 3 forbids lib/data/ from
// importing package:flutter/material.dart. Neither can reach a generated
// localisation class, which is exactly why the seed lives at the presentation
// edge and `terminology_overrides` is seeded ABSENT rather than populated.
//
// A locale change or an app update therefore never overwrites a user's term
// (07 §14.3 row 2). That is safety rule 4 at the vocabulary layer.
Map<AnimalClass, TermLabel> shippedDefaults(AppLocalizations l) => {
      AnimalClass.ewe:          TermLabel(l.termEweSingular,          l.termEwePlural),
      AnimalClass.maidenFemale: TermLabel(l.termMaidenFemaleSingular, l.termMaidenFemalePlural),
      AnimalClass.eweLamb:      TermLabel(l.termEweLambSingular,      l.termEweLambPlural),
      AnimalClass.ram:          TermLabel(l.termRamSingular,          l.termRamPlural),
      AnimalClass.ramLamb:      TermLabel(l.termRamLambSingular,      l.termRamLambPlural),
      AnimalClass.wether:       TermLabel(l.termWetherSingular,       l.termWetherPlural),
      AnimalClass.lamb:         TermLabel(l.termLambSingular,         l.termLambPlural),
    };
```

```dart
// lib/features/settings/settings_write_controller.dart
//
// validateOverride is 05 §8.4's, in lib/domain/terminology/. It REJECTS with a
// reason; it never strips a character. The controller is where it runs, because
// a repository may not import lib/domain/validation/ (R53) and because a
// rejection is screen state, not a WriteOutcome.
Future<void> setTerm(AnimalClass c, String singular, String plural) async {
  final result = validateOverride(singular, plural);
  switch (result) {
    case TermOverrideRejected(:final message):
      ref.read(settingsControllerProvider.notifier).showTermRejection(c, message);
    case TermOverrideAccepted(:final label):
      await guard(() async {
        final repo = await ref.read(settingsRepositoryProvider.future);
        return repo.setTerminologyOverride(c, label);
      });
  }
}
```

Widget keys, R59 spelling — one pair per `AnimalClass`, the enum member in `lower_snake`:

```
settings.terminology.ewe.singular            settings.terminology.ewe.plural
settings.terminology.maiden_female.singular  settings.terminology.maiden_female.plural
settings.terminology.ewe_lamb.singular       settings.terminology.ewe_lamb.plural
settings.terminology.ram.singular            settings.terminology.ram.plural
settings.terminology.ram_lamb.singular       settings.terminology.ram_lamb.plural
settings.terminology.wether.singular         settings.terminology.wether.plural
settings.terminology.lamb.singular           settings.terminology.lamb.plural
settings.terminology.ewe.reset               … one reset per class
```

### 5.3 The details that are easy to get wrong

- **The domain noun is a placeholder, never a literal — and the failure survives code review**
  (`10 §8.5`). Wrong: `"turnOutPrompt": "Turn out ewe {tag}?"`. Right:
  `"turnOutPrompt": "Turn out {term} {tag}?"` with a `description` saying *"`{term}` is a USER-EDITABLE
  noun from the terminology overlay (ewe/gimmer/theave/…). Never translate it, never hard-code it."*
  The rename feature is worth nothing if one message is wrong, and the wrong one will be the one that
  only ever renders on a lock screen.
- **The placeholders are `singularTerm` / `pluralTerm`, never `singular` / `plural`** (`05 §8.2`,
  `10 §8.5`). `plural` is an **ICU keyword**; a placeholder shadowing it inside a plural expression
  *"parses today and stops parsing on the next `gen-l10n` release."* The database columns are still
  called `singular` and `plural` — the two namespaces are different and both spellings are right in
  their own place. That is the single most confusing pair of names in this task.
- **ICU cannot pluralise a runtime string.** `"{count, plural, other{{count} {term}s}}"` yields
  "3 gimmers" (fine) and "3 sheeps" (not fine). ICU picks the **category**; the map supplies both
  forms. **Never derive a plural by appending "s"** — not in the UI, not in an export, not in a
  semantics label. The user typed one word; guessing the other is safety rule 4 (`05 §8.2`).
- **`"type": "num"` on `count`, and named arguments.** Decision #108 sets `use-named-parameters: true`,
  so `l10n.nAnimals(count: n, singularTerm: …, pluralTerm: …)` compiles and the positional spelling
  does not. `nullable-getter: false` is why there is no `!` after `.of(context)`.
- **Reject; do not sanitise** (`05 §8.4`). A comma, quote, tab or line break is a **rejection with a
  reason**, because stripping it silently would be a correction. *"Trimming surrounding whitespace is
  the one accepted exception — invisible, universally expected, and it cannot change meaning."* The
  24-character cap is a **3am constraint, not a database one**: a label that overflows a 60 pt button
  under a head torch is a defect. Use `validateOverride`'s own messages verbatim; do not paraphrase
  them into the ARB.
- **The seeding lives in `lib/features/settings/terminology_bootstrap.dart` and nowhere else**
  (`05 §8.1`, `07 §14.3` row 2, `10 §8.5`). The layer rules make every other home unbuildable, not
  merely inconsistent. **`vocab_terms.label` is seeded `NULL` and `terminology_overrides` is seeded
  with no rows at all**, and both are resolved at the presentation edge — which is exactly what makes "a locale change never overwrites a
  user's term" structural rather than procedural.
- **`terminologyProvider`'s default source was ruled in N12-T02** — an injected
  `Map<AnimalClass, TermLabel>` from `terminologyDefaultsProvider`, with the file recording which of
  the two documents it followed. **Read that file before writing this one.** If N12-T02 carried the
  seam into the PR body as open instead of ruling it, this task is where it closes, under
  `00-README` §10's amendment rule — and the losing document is edited in the same commit.
- **The rename must not reach a machine value** (`05 §8.3`). CSV **headers** and the CSV
  `animal_class` column are stable English keys (`maidenFemale`). The **PDF flock book** uses the
  user's labels. The **JSON backup** carries enum keys **plus a top-level `terminology` block**, so a
  restore reproduces the shepherd's vocabulary — *"without the block, a restore silently reverts their
  labels, safety rule 4 at the backup layer."* N22 already wrote that block; this task must not break
  it, and the test that proves it is a round trip, not a reading.
- **`maidenFemale` is deliberately an unlovely key that belongs to no county.** Naming it `gimmer`
  would privilege one dialect in the data format forever. The **label** on the screen is
  `gimmer` — the shipped default — and the **key** stays `maidenFemale`. Do not "tidy" either.
- **Many UK users will rename `ram` to *tup*.** `10 §8.5`: *"that is not a defect in the default, it is
  the entire reason the overlay exists."* All seven classes are editable, not just the five the spec
  lists — spec §7.10 names five words, `AnimalClass` has seven members, and shipping five editable
  fields leaves a shepherd who says *tup* with no way to say it.
- **Semantics labels use the user's noun too** (`10 §8.5`, §3.2 rule 8). TalkBack says "theave 412".
  `spellOutTag` applies to the **tag range only** — "gimmer, four one two", never "g-i-m-m-e-r".
- **Never a placeholder inside the text field** (`indelible.md` §7.12). *"In the dark, a grey
  placeholder is indistinguishable from an entered value."* The hint lives in the label, above the
  line, in the control voice. The unset state is a **2 px dotted rule**, not grey text.
- **Every field commits on its own** (`CLAUDE.md` non-negotiable 4). Fourteen fields, fourteen writes,
  no Save button, no "Apply terminology". The commit affordance on a text field is its own — a focus
  loss or an explicit done control — and whichever it is, it is one write per field, not one per
  screen.
- **`clearTerminologyOverride` is a DELETE, and it must be reachable.** A shepherd who renames *ewe*
  to *gimmer* and changes their mind needs a way back to the default that is not "type `ewe` again" —
  because typing `ewe` writes an override that happens to equal the default, and a future default
  change would then not reach them.
- **This section is the longest on the screen at 200 % text scale.** Seven classes × two fields ×
  (label above value) is fourteen 64 px rows plus fourteen labels. It scrolls; the scroll view must not
  be on a primary-action path, and `FittedBox` is banned around user-facing text (`10 §4.4`).
- **`vocab_terms` is not this task's table.** R66 gives the ~40 husbandry terms three homes and
  N07-T07 already seeded the keys and the ARB labels. Editing a death cause is a different feature and
  it is not in `07 §14.3`'s twelve sections.

### 5.4 The full test set

`test/features/settings_test.dart` (appended) and one new policy file.

| Case | What it asserts |
|---|---|
| `'renaming ewe to gimmer changes every user-facing rendering and no ARB message carries a domain noun as a literal'` | **The anchor.** Both halves — the behaviour and the source-text scan |
| `'no ARB message contains a domain noun as a literal'` · in `test/policy/no_domain_noun_is_a_literal_test.dart` | Word-boundary scan over every message value; the exception set is derived from `AnimalClass.values`, never typed |
| `'every AnimalClass has an editable pair and a reset'` | Seven classes; twenty-one keys found. Derived from `AnimalClass.values`, so an eighth member fails here |
| `'an override wins over the shipped default and clearing it restores the default'` | Write, read, clear, read. The clear is a DELETE and the row count returns to zero |
| `'clearing an override deletes the row rather than storing two blanks'` | `SELECT COUNT(*) FROM terminology_overrides` is 0, not 1 |
| `'a label containing a comma is rejected with a reason and nothing is stored'` | `05 §8.4`'s message verbatim; the row is absent. Safety rule 4 |
| `'a label of 25 characters is rejected and one of 24 is accepted'` | The 3am cap, both sides of the boundary |
| `'surrounding whitespace is trimmed and nothing else is'` | `'  gimmer  '` stores `gimmer`; `'gim mer'` stores `gim mer` |
| `'an empty singular or an empty plural is rejected'` | Both arms of `05 §8.4`'s first branch |
| `'the plural is never derived by appending s'` | Rename `ram` to `tup` with plural `tups`, then to `tup`/`tup`; assert the rendered plural is what was typed both times |
| `'the rename reaches the Flock screen, the Ewe Card, the Pen Board and the PDF flock book'` | Four pumps plus one PDF build; all four read the override |
| `'the rename does not reach the CSV header row or the animal_class column'` | Build `ewes.csv` after the rename; the header is `ewe_tag` and the class column is `maidenFemale` (`05 §8.3`) |
| `'a JSON backup round trip reproduces the shepherd's vocabulary'` | Rename, export, restore into a fresh database, read `terminologyProvider`. The `terminology` block is N22's; this proves it survived |
| `'a semantics label uses the user's noun and spells out only the tag'` | `'gimmer, four one two'`; the `SpellOutStringAttribute` range covers `412` and nothing else (`10 §3.3`) |
| `'the closed enum is unchanged — only the labels move'` | `AnimalClass.values` is the same seven after every rename; nothing writes to `ewes.animal_class` |
| `'the terminology section renders without overflow at the smallest device and textScaler 2.0, bold'` | Fourteen fields plus labels — the longest section on the screen |
| `'no SnackBar is shown when a term is renamed or rejected'` | `find.byType(SnackBar)` is `findsNothing`; the rejection renders **in the row**, beside the field (P2) |
| `'every string in this section is an ARB message with a description'` | Source text over `app_en.arb` and over the widget file |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Never silently correct an entry** (safety rule 4), twice over: `validateOverride` rejects rather
  than strips, and a locale change or an app update never rewrites a user's term.
- **A user-editable label never becomes a machine value** (`05 §8.3`). The stable keys — `AnimalClass`,
  `time_source`, `WithdrawalTarget`, `LambCount`, the vocabulary keys, the CSV headers — are contracts,
  not copy.
- **The honest limitation, stated rather than discovered:** two noun forms work cleanly for languages
  with two plural categories. Irish, Polish and Russian need `few`/`many`. For an English-only v1 this
  is correct; adding `TermLabel.few`/`.many` later is additive. Put it in the file, not in a memory.

## 7. Definition of Done

- [ ] `'renaming ewe to gimmer changes every user-facing rendering and no ARB message carries a domain noun as a literal'` passes, and was seen to fail first for the stated reason
- [ ] no domain noun is a literal in any ARB message
- [ ] the rename reaches every screen, including exports
- [ ] the closed enum is unchanged — only the labels move
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records that the schema and domain steps are skipped, and that this is the only repository edit in N29
- [ ] `setTerminologyOverride` upserts on the primary key and `clearTerminologyOverride` deletes; neither stores a blank
- [ ] `terminology_bootstrap.dart` is the only file in `lib/` outside the generated l10n output that reads a terminology default from `AppLocalizations`
- [ ] all **seven** `AnimalClass` members are editable, not the five the spec lists by name
- [ ] the ARB placeholders are `singularTerm` / `pluralTerm`; `{singular}` and `{plural}` appear in no message
- [ ] CSV headers and the `animal_class` column are unchanged by a rename, and a backup round trip reproduces the overlay
- [ ] `test/policy/no_domain_noun_is_a_literal_test.dart` derives its exception set from `AnimalClass.values`
- [ ] the honest `few`/`many` limitation is recorded in `terminology_bootstrap.dart`'s doc comment

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/policy/no_domain_noun_is_a_literal_test.dart
fvm flutter test test/domain/terminology_test.dart    # N06-T08's tier, unchanged, still green
make check
make test
```

```bash
grep -rn "AppLocalizations" lib/data/ lib/domain/                    # expect zero (layer rules 1, 3)
grep -c "AppLocalizations" lib/features/settings/terminology_bootstrap.dart   # the one seed site
grep -n '"{singular}"\|{plural}' lib/l10n/app_en.arb                 # expect zero — Term suffix only
grep -rn "+ 's'\|\\\\'s'" lib/features/ lib/core/ui/                 # no plural by appending
grep -rn "save\|apply\|commit(" lib/features/settings/widgets/terminology_section.dart  # expect zero
grep -rn "hintText\|placeholder" lib/features/settings/              # expect zero (indelible §7.12)
git diff --stat -- drift_schemas/ lib/domain/                        # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): terminology editing through overrides`
