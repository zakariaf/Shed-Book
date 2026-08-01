# N06-T08 — Terminology — a closed enum under a user-editable overlay

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 8 of 11 |
| **Depends on** | N06-T07 |
| **Commit** | one commit · `feat(domain): terminology as a closed enum under an editable overlay` |

## 1. Why this task exists

`AnimalClass`, `TermLabel` and `Terminology`: the concepts are a **closed enum** the code
switches on; the words are an overlay the user edits. Rename *ewe* to *gimmer* and every screen says
gimmer, without a single `if (term == 'gimmer')` anywhere.

The words genuinely are not synonyms and not a clean taxonomy. The National Sheep Association's own
glossary defines *gimmer* by age plus parity, *shearling* by **dentition**, *hogget* by age (and
overloads it with a meat term), and *teg* as two years old — while other regions use *teg* for a
sheep in its second year. Three measuring sticks for overlapping classes, with regional disagreement
inside one national body's glossary. There is no canonical taxonomy to normalise to, which kills both
naive designs ("one enum, translate it" and "free text, no enum") and leaves exactly one shape.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §8.1, §8.2, §8.3, §8.4 | the three types, the resolution order, the ICU placeholder rule, the export-header rule, and reject-do-not-sanitise |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.5, §8.7 | the fourteen ARB keys with their en-GB defaults, the `nAnimals` message, and why `Disclaimers` and `provenanceLabel` are *not* in the ARB |
| `docs/engineering/CONVENTIONS.md` | §2.9, §2.14, §4.6, R66, R68 | `AnimalClass`'s seven members, `Terminology`/`TermLabel`'s home, `terminologyProvider`'s type |
| `docs/engineering/03-data-model-and-schema.md` | `TerminologyOverrides` | the storage shape: `key` TEXT primary key, `singular`, `plural` |
| `docs/research/00-tech-decisions.md` | §2 #61, #108 | the terminology overlay; `use-named-parameters: true`, `nullable-getter: false`, `en` only |
| `shed-book-spec.md` | §7.10 | *"editable labels, because these vary by county, let alone by country"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | no domain noun may appear as a literal in any message |
| `shed-domain` | the enum, the overlay and the resolution order |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/terminology_test.dart`
- **Test** — `'a term override replaces the label everywhere while the enum stays closed'`
- **Why it is red today** — nothing resolves a term, so the first ARB string would hard-code *ewe*.

```dart
const defaults = {AnimalClass.ewe: TermLabel('ewe', 'ewes')};
final t = Terminology(defaults, const {AnimalClass.ewe: TermLabel('yow', 'yows')});
expect(t.labelFor(AnimalClass.ewe).singular, 'yow');
expect(t.labelFor(AnimalClass.ewe).plural, 'yows');
// and the key is unchanged: the enum is what the code switches on
expect(AnimalClass.ewe.name, 'ewe');
```

```bash
fvm flutter test test/domain/terminology_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the closed enum, the overlay lookup,
and the fourteen default labels, which live in **`lib/l10n/app_en.arb`** as `term*Singular` /
`term*Plural` messages (R66; `10` §8.5 lists all fourteen with their en-GB defaults). The *domain*
holds no default text: `Terminology` receives the map, because `lib/domain/` may not import
`AppLocalizations`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

This is the first task in the epic that reaches `00-README` §8 **step 7 (the ARB)** as well as step 2.
Step 1 is skipped — `TerminologyOverrides` is N07-T06's table — and steps 3–6 are not reached.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/terminology/animal_class.dart` | **New.** `enum AnimalClass` with the seven members, no `key` field — the stored value is `.name` (see §5.4) |
| 2 | `lib/domain/terminology/term_label.dart` | **New.** `final class TermLabel { final String singular, plural; }` |
| 3 | `lib/domain/terminology/terminology.dart` | **New.** `Terminology` with the two maps and `labelFor`, plus `validateOverride` and its result type |
| 4 | `lib/l10n/app_en.arb` | **Extended.** Fourteen `term*Singular` / `term*Plural` messages with their `description`s, plus the `nAnimals` plural message with its three placeholders |
| 5 | `lib/l10n/app_localizations*.dart` | **Regenerated and committed.** `00-README` §7.1 requires the generated output in git so a stale generation shows in a diff instead of hiding in a build directory. The `codegen` CI job that would catch a missed regeneration does not exist until N08 — regenerate by hand and read the diff |
| 6 | `test/domain/terminology_test.dart` | **New.** The anchor, the resolution order and `validateOverride` |
| 7 | `test/policy/terminology_survives_a_rename_test.dart` | **New.** The property `05`'s definition of done names: pluralisation survives an arbitrary override, and the seven members and fourteen messages are the same set. **Not** the "no domain noun is a literal" scan — that is `test/policy/arb_has_no_domain_noun_test.dart` and it belongs to N33-T05 (`00-PLAN-CRITIQUE` §11.3). Do not create a second copy |

### 5.2 The signatures

```dart
// lib/domain/terminology/animal_class.dart
/// The DOMAIN concept. These keys go into the database, the CSV and the JSON
/// backup, and they never change — not on a rename, not on a translation.
enum AnimalClass {
  ewe,           // adult female that has lambed
  maidenFemale,  // gimmer / theave / shearling ewe / hogg — regional
  eweLamb,
  ram,
  ramLamb,
  wether,
  lamb,          // sex unknown / not yet sexed
}
```

```dart
// lib/domain/terminology/terminology.dart
final class TermLabel {
  final String singular, plural;
  const TermLabel(this.singular, this.plural);
}

/// Resolution order: user override -> localised default. Never empty.
final class Terminology {
  final Map<AnimalClass, TermLabel> _defaults;   // supplied by the settings bootstrap
  final Map<AnimalClass, TermLabel> _overrides;  // from TerminologyOverrides
  const Terminology(this._defaults, this._overrides);

  TermLabel labelFor(AnimalClass c) {
    final o = _overrides[c];
    if (o != null && o.singular.trim().isNotEmpty && o.plural.trim().isNotEmpty) return o;
    return _defaults[c]!;   // a missing default is a programming error, not a runtime state
  }
}

/// Reject, do not sanitise. Stripping the comma silently would be a silent
/// correction; rejecting with a reason is not.
TermOverrideResult validateOverride(String singular, String plural);
```

`validateOverride`'s three refusals, verbatim from `05` §8.4 — *"Both the singular and the plural are
needed."*, *"24 characters maximum, so it still fits the buttons at arm's length."*, *"No commas,
quotes or line breaks."* — with `RegExp(r'[\n\r\t,"]')` as the character test. `TermOverrideResult`
and its two variants (`TermOverrideAccepted`, `TermOverrideRejected`) are printed in 05 §8.4 but are
not catalogued in `CONVENTIONS` §2; keep 05's spelling exactly and note in the commit message that
§2.14 should gain the row.

### 5.3 The ARB half

```jsonc
// lib/l10n/app_en.arb — the SENTENCE lives here; the NOUN does not.
"nAnimals": "{count, plural, =0{No {pluralTerm}} =1{1 {singularTerm}} other{{count} {pluralTerm}}}",
"@nAnimals": {
  "description": "…",
  "placeholders": {
    "count":        { "type": "num" },
    "singularTerm": { "type": "String", "example": "ewe" },
    "pluralTerm":   { "type": "String", "example": "ewes" }
  }
},
"termEweSingular": "ewe",
"termEwePlural": "ewes",
"termMaidenFemaleSingular": "gimmer",
"termMaidenFemalePlural": "gimmers"
// … one pair per AnimalClass: eweLamb, ram, ramLamb, wether, lamb
```

`10` §8.5's table is the source for all seven pairs and their defaults; every message carries a
`description`, and the `term*` ones carry 10's warning that the value is a **user-editable noun** —
never translate it, never hard-code it.

### 5.4 The details that are easy to get wrong

- **`AnimalClass`'s stored key is `.name`, in camelCase, and that is a documented deviation from
  `CONVENTIONS` §4.6.** §4.6 says stored enum keys are `snake_case`; `05` §8.3 pins `maidenFemale` as
  the value that appears in the CSV's `animal_class` column and in the JSON backup. Do not "fix" it to
  `maiden_female`, and do not add a `key` field that disagrees with `.name`. Write the reason beside
  the enum.
- **Do not rename `maidenFemale` to `gimmer`.** The key is deliberately unlovely and belongs to no
  county, so the default English label (*gimmer*), a Yorkshire user's override (*theave*) and a future
  translator's word are all equal citizens over one stable key. Naming the key `gimmer` privileges
  one dialect in the data format forever.
- **The placeholders are `singularTerm` / `pluralTerm`, never `singular` / `plural`.** `plural` is an
  ICU **keyword**; a placeholder that shadows a keyword inside a plural expression parses today and
  stops parsing on the next `gen-l10n` release. `"type": "num"` on `count` is what Flutter's own
  plural example uses, and `"type": "int"` produces a different generated signature.
- **Named arguments at every call site.** Decision #108 sets `use-named-parameters: true`, so
  `l.nAnimals(count, singular, plural)` does not compile — it is
  `l.nAnimals(count: n, singularTerm: …, pluralTerm: …)`. `nullable-getter: false` is why there is no
  `!` after `AppLocalizations.of(context)`.
- **Never derive a plural by appending "s".** The user is already typing one word; guessing the other
  is safety rule 4. `TermLabel` requires both, and `validateOverride` rejects a blank one rather than
  inventing it.
- **`Terminology` holds no default text and cannot fetch any.** Layer rule 1 bans `intl` and
  `AppLocalizations` from `lib/domain/`; the defaults arrive through the constructor. Seeding happens
  **once**, in `lib/features/settings/terminology_bootstrap.dart` (N29), which already has a
  `BuildContext` — never in `domain/` or `data/`, and a locale change or an app update never
  overwrites a user's override.
- **An override with a blank singular or plural is ignored, not stored-and-rendered.** `labelFor`
  trims and checks both before preferring the override, so a half-filled row falls back to the default
  rather than rendering an empty button at 3am.
- **`_defaults[c]!` is deliberate.** A missing default is a programming error, not a runtime state;
  the parity between the seven members and the fourteen ARB messages is what the rename test holds.
- **Trimming is the one accepted sanitisation.** Invisible, universally expected, and it cannot change
  meaning. Everything else — the comma, the quote, the newline — is **rejected with a reason**.
- **The 24-character cap is a 3am constraint, not a database one.** A label that overflows a 60 pt
  button under a head torch is a defect; `TerminologyOverrides.singular` has no length CHECK.
- **Renaming is never a setup step.** Defaults ship, Settings is optional, and spec §5's *"no
  onboarding after first run"* holds. Nothing in this task belongs on a first-run path.
- **Export headers are stable English keys, always.** CSV headers and CSV `animal_class` values use
  the enum key; the PDF flock book uses the **user's** labels; the JSON backup carries the enum keys
  **plus** a top-level `terminology` block so a restore reproduces the shepherd's vocabulary. Without
  that block a restore silently reverts their labels — safety rule 4 at the backup layer. Those are
  N21's and N22's call sites; the rule is fixed here.
- **The honest limitation, stated rather than discovered:** two noun forms work cleanly for languages
  with two plural categories. Irish, Polish and Russian need `few`/`many`. For an English-only v1 this
  is correct, and adding `TermLabel.few`/`.many` later is an additive change to both the record and
  the ARB.

### 5.5 The full test set

| File | Cases |
|---|---|
| `test/domain/terminology_test.dart` | **anchor:** `'a term override replaces the label everywhere while the enum stays closed'` · `'with no override, labelFor returns the default'` · `'an override with a blank plural is ignored and the default wins'` · `'an override that is only whitespace is ignored'` · `'labelFor is never empty for any of the seven members'` — a loop, so a missing default fails here · `'AnimalClass has exactly seven members and their names are frozen'` · `validateOverride`: `'empty singular is rejected with the both-are-needed reason'` · `'25 characters is rejected, 24 is accepted'` · `'a comma, a quote, a tab and a newline are each rejected'` · `'surrounding whitespace is trimmed and the value is otherwise byte-identical'` |
| `test/policy/terminology_survives_a_rename_test.dart` | `'pluralisation survives an arbitrary override'` — load the catalogue directly with `await AppLocalizations.delegate.load(const Locale('en'))`, then assert `nAnimals(count: 0/1/5, singularTerm: 'yow', pluralTerm: 'yows')` renders *No yows* / *1 yow* / *5 yows*; no widget pump is needed · `'every AnimalClass member has both ARB messages'` — seven members, fourteen keys, asserted as set equality so a member added without a label fails the build rather than rendering blank at 3am · `'no ARB placeholder is named plural or singular'` |

**No `uk-zone` case.** Nothing in this task carries a time.

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Generated output is committed** — `lib/l10n/app_localizations*.dart` moves in this diff and is read before it is committed.

## 7. Definition of Done

- [ ] `'a term override replaces the label everywhere while the enum stays closed'` passes, and was seen to fail first for the stated reason
- [ ] the enum is closed and exhaustively switched
- [ ] an override changes every rendering site
- [ ] no domain noun is a literal in any message
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/terminology_test.dart
fvm flutter test test/policy/terminology_survives_a_rename_test.dart
fvm flutter gen-l10n && git diff --stat -- lib/l10n/   # regenerate, read the diff, commit it
grep -rn "AppLocalizations\|package:intl" lib/domain/  # expect: nothing — layer rule 1
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): terminology as a closed enum under an editable overlay`
