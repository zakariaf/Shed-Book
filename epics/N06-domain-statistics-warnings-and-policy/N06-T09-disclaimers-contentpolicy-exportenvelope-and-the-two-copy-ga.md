# N06-T09 — `Disclaimers`, `ContentPolicy`, `ExportEnvelope` — and the two `copy.*` gate rows

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 9 of 11 |
| **Depends on** | N06-T08 |
| **Commit** | one commit · `feat(domain): Disclaimers, ContentPolicy, ExportEnvelope and the two copy gate rows` |

## 1. Why this task exists

`Disclaimers` as an `abstract final class` of `const` strings in **one** file, referenced
and never re-typed; `ExportEnvelope` with **no** disclaimer parameter, so an export cannot be
constructed without the real one; and `ContentPolicy.bannedInUserFacingText` with its allowlist keyed
by `Disclaimers.*` rather than by a literal. This task also adds the two `copy.*` rows N03 deliberately
left out — `copy.vet_advice` and `copy.disclaimer_retyped` — closing critique defect S8.

`12-testing.md` §10 is explicit that safety rules §12.2 and §12.3 are **gate rows, not tests**:
neither "no vet advice" nor "not a compliance record" is a behaviour a widget can exhibit, so a
`test()` asserting either would have to read source text, which is the gate's job. That is why this
task is half domain code and half `tool/check_policy.dart`.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §7.1, §7.3, §7.4 | the origination line, the ten patterns with their `why` strings, the allowlist keyed by `Disclaimers.*`, the three disclaimer strings verbatim, `ExportEnvelope`'s single factory, and the joined-string-literal gotcha |
| `docs/engineering/01-architecture.md` | §3.2 | the gate's rule-row tuple `(id, literal, under, why)`, the driver's file walk, and why `tool/` is not scanned |
| `docs/engineering/09-export-formats.md` | §7, §8.1, §8.2 | the three things called an envelope (R65), where each disclaimer lands per format, and `disclaimer_is_defined_once_test.dart` by name |
| `docs/engineering/12-testing.md` | §10, §1.4 | §12.2 and §12.3 are proved by the gate, not by a test |
| `docs/engineering/CONVENTIONS.md` | §2.8, §2.14, §4.7, R54, R56, R65 | the rule-id namespaces, the four `[exempt]` lines that exist on day one, and `ExportEnvelope`'s file |
| `epics/00-PLAN-CRITIQUE.md` | S8; `epics/00-AUDIT-accuracy.md` B1 | why the two rows land here and not in N03; and the anchor's correct file name |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | §12.2 and §12.3 are its rules and this is where they become mechanical |
| `shed-conventions` | the gate's rule table and the one-file rule are naming decisions |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/disclaimer_is_defined_once_test.dart`
- **Test** — `'Disclaimers.exportFooter appears as a literal in exactly one file'`
- **Why it is red today** — there are no disclaimers, so the first export footer would be typed into a PDF builder.

```dart
final hits = dartFilesUnder('lib/')
    .where((f) => joinedStringLiterals(f)
        .contains(RegExp(r'statutory\s+medicine|holding\s+register')))
    .toList();
expect(hits, ['lib/domain/policy/disclaimers.dart']);
```

```bash
fvm flutter test test/policy/disclaimer_is_defined_once_test.dart   # expect: failing, for the reason above
```

> **Anchor path corrected.** The plan previously named `test/policy/disclaimer_is_referenced_test.dart`.
> `09-export-formats.md` §7 and its definition of done both name
> **`disclaimer_is_defined_once_test.dart`**, and `00-AUDIT-accuracy.md` B1 rules that the eleven
> mis-named anchors take the doc-named file rather than inventing a second one. The test name and the
> property are unchanged.

**Green.** The minimum code that passes, and nothing beyond it — the three types, then the two gate rows added to `tool/check_policy.dart`'s table with
their proving tests, in this commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2, plus `tool/`. Step 1 is skipped — none of these strings is stored — and steps
3–7 are not reached. `ExportEnvelope`'s call sites are N21's and N22's; the disclaimers' *placement*
per format is fixed here and implemented there.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/policy/disclaimers.dart` | **New.** `abstract final class Disclaimers` with three `const String`s. On `00-README` §8 step 10's never-waved-through list, however small the diff |
| 2 | `lib/domain/policy/content_policy.dart` | **New.** `bannedInUserFacingText` — ten `(pattern, why)` records — and `allowlist`, keyed by `Disclaimers.exportFooter` and never by a literal |
| 3 | `lib/domain/policy/export_envelope.dart` | **New.** `ExportEnvelope` with a private generative constructor and one factory (R65) |
| 4 | `tool/check_policy.dart` | **Extended.** Two rows, **and the driver change that makes them reachable** (§5.3). Its header comment loses N03's "the table is not closed" note, because this is the commit that closes it |
| 5 | `test/policy/disclaimer_is_defined_once_test.dart` | **New.** The anchor |
| 6 | `test/policy/content_policy_test.dart` | **New.** The guard's two-way self-tests |
| 7 | `test/policy/gate_rules_test.dart` | **Extended** (N03-T01 created it). Both new rows watched to fire on a planted offender |
| 8 | `test/domain/policy/export_envelope_test.dart` | **New.** The disclaimer cannot be omitted, overridden or shortened |

### 5.2 The signatures

```dart
// lib/domain/policy/disclaimers.dart
/// The ONLY place these strings exist. Not in the ARB — a translator can drop
/// or soften an ARB string and the app has no mechanism to notice.
/// `abstract final` cannot be instantiated OR extended, so nobody can subclass
/// it and shadow a string.
abstract final class Disclaimers {
  static const String exportFooter =
      'Shed Book is a personal notebook. It is not a statutory medicine '
      'record, holding register, or movement record, and must not be '
      'presented as one. All entries are as recorded by the user.';

  static const String withdrawalProvenance = 'as entered by you';

  static const String withdrawalCaveat =
      'Withdrawal period as entered by you from the product label. '
      'Shed Book does not know any product and suggests no value. '
      'Check the label.';
}
```

```dart
// lib/domain/policy/export_envelope.dart (R65)
final class ExportEnvelope {
  final String disclaimer;
  final Instant generatedAt;
  final String appVersion;
  const ExportEnvelope._(this.disclaimer, this.generatedAt, this.appVersion);

  /// The only constructor. `disclaimer` is not a parameter.
  factory ExportEnvelope.standard({required Instant now, required String appVersion}) =>
      ExportEnvelope._(Disclaimers.exportFooter, now, appVersion);
}
```

`ContentPolicy`'s ten patterns are printed in full in `05` §7.3 and are copied verbatim, `why`
strings included. Two of them are worth reading twice before you edit them: `call the vet` is banned
**deliberately** — it sounds like the safe thing to say and is still the app making a clinical call
about a specific animal at a specific moment — and `\b\d+\s?(ml|mg|cc|iu)\s?/\s?kg\b` exists because
AHDB publishes *"50 ml/kg of colostrum within the first four to six hours"*, the app holds the
birthweight, and multiplying is one line and would be *helpful*.

### 5.3 The gate work, which is more than two rows

`01-architecture.md` §3.2's driver walks `_roots = ['lib', 'test']` and skips anything not ending
`.dart`. Both new rules are specified to scan places it never opens, and both need a matcher the
`(id, literal, under, why)` tuple cannot express. **Two table rows alone are a rule that silently
passes.** What has to change, and the decision each change forces:

| Change | Why | The decision |
|---|---|---|
| Walk `lib/l10n/*.arb` and `assets/content/**` | `12` §10 scopes `copy.vet_advice` to *"`lib/` and `assets/`"*; `03` §10.1 and R66 require the "no verbatim third-party copy" check to scan **both** `assets/content/` and `lib/l10n/`. Neither is a `.dart` file and `assets/` is not a root | Add a second walk with its own extension filter. Keep the `.dart` walk exactly as it is — it is proved by N03's tests |
| Match **regexes**, not literals | Every one of the ten patterns is a `RegExp`. `_bannedText` matches with `String.contains` | A second rule family beside `_bannedText`, not an overload of it. A rule that is weakened to fit an existing table is a rule that gets deleted later |
| Join adjacent string literals before matching | **The gotcha that will bite you**, and `05` §7.3 records it as found rather than theorised: a naive `file.contains('some long phrase')` **misses long strings**, because Dart wraps them across adjacent literals and the phrase is never contiguous in the source. `Disclaimers.exportFooter` is exactly such a string | Extract string literals and join them. `09` §7's definition of done names the helper: `joinedStringLiterals` — the same one the anchor test uses |
| Keep `content_policy.dart` out of its own scan | The file holds every banned pattern as a regex source, so it matches itself. This is the same problem that made `tool/` unscanned — *"this file's own rule tables contain every banned literal"* | Skip it **inside the rule**, not with a fifth `[exempt]` line: R56 fixes the allowlist at four lines on day one and says a fifth is a review conversation |
| `copy.disclaimer_retyped` asserts *exactly one* file | A literal `contains` rule fires on `disclaimers.dart` itself, which is the one legitimate site | Write it as a count-and-name rule: the phrase may appear in exactly one file and that file is `lib/domain/policy/disclaimers.dart`. Same property as the anchor test, enforced at build time |
| Decide where the patterns live | `ContentPolicy` is the single definition (`05` §7.3); a copy inside the gate is a second home that drifts | `tool/check_policy.dart` has zero *package* dependencies, and `content_policy.dart` + `disclaimers.dart` are pure Dart with no package imports, so the gate can import them directly. Take that, and record the choice in the file header — if you instead copy the patterns, you own a duplication the doc set forbids |

Both rows go in the `copy` namespace (`CONVENTIONS` §4.7), and **each is watched to fire in this
commit**: plant an offender, confirm the failure names the rule id, delete the file. N03's discipline
— *"a rule nobody has seen fire is indistinguishable from a broken rule"* — applies to the two rows
it deliberately deferred.

### 5.4 Where each disclaimer lands, per format

Fixed here, implemented in N21 and N22. One golden test per format asserts the produced bytes
contain it:

| Artefact | §12.3 `exportFooter` | §12.1 `withdrawalCaveat` / `withdrawalProvenance` |
|---|---|---|
| CSV | a final row, `# <disclaimer>` in the first field | beside every withdrawal figure |
| PDF flock book | a running footer on **every** page | — |
| Medicine-record PDF | footer **plus** a boxed statement under the title — it is the one somebody hands to an inspector | the box carries `withdrawalCaveat` too |
| JSON backup | a top-level `"_disclaimer"` key, **first** | `"_withdrawalNotice"`, second |
| Export screen | a one-liner above the buttons | — |

### 5.5 The details that are easy to get wrong

- **Three different things are called an envelope, and R65 exists to stop two of them merging.** The
  **envelope** is the whole `.json` file; **`BackupHeader`** is the type behind its header block
  (`format`/`formatVersion`/`schema`/`counts`/`checksum`), and it lives in `lib/data/`;
  **`ExportEnvelope`** is this task's disclaimer-bearing value in `lib/domain/policy/`, which *every*
  writer takes, CSV and PDF included. If a sentence would read the same with two of the three
  swapped, it is wrong.
- **`ExportEnvelope`'s mechanism is that `disclaimer` is not a parameter.** No caller can pass an
  empty string, a placeholder, or "a short version for this one file". Adding an optional named
  parameter to `standard()` deletes safety rule 3 in one line and looks like a convenience.
- **The allowlist key is `Disclaimers.exportFooter`, not the sentence.** This caught a real
  duplication while the research was being written — the banned-phrase allowlist had re-typed the
  string it exists to permit. Keying by the constant is both the fix and the correct design.
- **The guard is self-tested in both directions.** A guard that never fires is indistinguishable from
  a broken guard, and a guard that fires on legitimate copy gets weakened until it does nothing. `05`
  §7.3 supplies both fixture lists; use them verbatim, including
  `'412 · 3 seasons · avg 2.0 · assisted twice'` and `'Clear on 11 Mar. Period ends 10 Mar 20:00.'`,
  which are the two most likely false positives.
- **`should` is a banned word outright** (`CONVENTIONS` §5.3), so the pattern `\byou should\b` is
  narrower than the vocabulary rule N03 already ships. Do not merge them and do not delete either —
  a duplicate rule is a rule that gets weakened twice (R54), but these two are not duplicates: one is
  a word ban in our own prose, the other is a phrase ban in user-facing text.
- **`Disclaimers` is `abstract final`.** Not `abstract`, not `final`, not a `class` with a private
  constructor. `abstract final` cannot be instantiated **or** extended, so nobody can subclass it and
  shadow a string.
- **These strings never go in the ARB** (`10` §8.7). A translator can soften or drop an ARB string and
  the app has no mechanism to notice. That is also why `05` §4.1's `provenanceLabel` stays out of the
  ARB while v1 ships `en` alone.
- **Do not write a `test()` for §12.2 or §12.3 beyond the two here.** `12` §1.4 puts source-text
  assertions in the gate, and a duplicated assertion in `test/policy/` is a second thing to weaken.
  The map in `12` §10 is the authority on which rule is proved where.
- **`disclaimers.dart` is never waved through in review** (`00-README` §8 step 10), and this commit is
  where the file first exists. Read it in full, out loud if necessary.

### 5.6 The full test set

| File | Cases |
|---|---|
| `test/policy/disclaimer_is_defined_once_test.dart` | **anchor:** `'Disclaimers.exportFooter appears as a literal in exactly one file'`, using `joinedStringLiterals` · `'a phrase split across adjacent string literals is still found'` — the regression for the gotcha itself: plant a wrapped copy in a temp fixture and assert it is caught · `'withdrawalCaveat and withdrawalProvenance are also single-site'` |
| `test/policy/content_policy_test.dart` | `'rule 2 guard catches planted offenders'` — all four of `05` §7.3's offenders · `'rule 2 guard does not reject legitimate app copy'` — all five of its permitted strings · `'the allowlist is keyed by Disclaimers.exportFooter, not by a literal'` — assert `ContentPolicy.allowlist.keys.single` is identical to the constant · `'every pattern carries a non-empty why'` |
| `test/policy/gate_rules_test.dart` (extended) | `'copy.vet_advice fires on a planted dose in a Dart string literal'` · `'copy.vet_advice fires on a planted dose in an ARB message value'` · `'copy.vet_advice fires on a planted dose in assets/content/'` — the three scopes, because the driver change is the risky half · `'copy.vet_advice does not fire on content_policy.dart itself'` · `'copy.disclaimer_retyped fires when the footer is typed into a second file'` · `'copy.disclaimer_retyped does not fire on disclaimers.dart'` · `'the [exempt] allowlist still has exactly four lines'` (R56) |
| `test/domain/policy/export_envelope_test.dart` | `'standard() carries Disclaimers.exportFooter'` — compared by reference to the constant, never to a re-typed string · `'there is no constructor that takes a disclaimer'` — the compile is the assertion; state it in the test's comment · `'generatedAt is the Instant passed in'` |

**No `uk-zone` case.** `ExportEnvelope.generatedAt` carries an `Instant` but computes nothing with
it; the export's own timestamp formatting is `09`'s and lands in N21.

## 6. Constraints that bind this task

- **§12.2 and §12.3, both held at *caught by a gate*, and `12 §10` says so in as many words.** Neither *no veterinary advice* nor *not a regulatory record* is a behaviour a widget can exhibit, so `copy.vet_advice` and `copy.disclaimer_retyped` are the mechanism and this task writes both rows. §12.1 rides along inside `ContentPolicy.bannedInUserFacingText`: *"default withdrawal"* and *"typical withdrawal"* are banned **strings** here, which is a different mechanism from N05-T01's banned **value** and does not replace it.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`tool/policy_allowlist.txt` still has exactly four `[exempt]` lines** (R56). A fifth is a review conversation, not an edit — and it is not the way to solve either of this task's self-scan problems.

## 7. Definition of Done

- [ ] `'Disclaimers.exportFooter appears as a literal in exactly one file'` passes, and was seen to fail first for the stated reason
- [ ] `Disclaimers` is `abstract final` and its strings are `const`
- [ ] `ExportEnvelope` has no disclaimer parameter
- [ ] `ContentPolicy` scans in both directions and is self-tested both ways
- [ ] the gate's rule table now includes `copy.vet_advice` and `copy.disclaimer_retyped`, each watched to fire
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/disclaimer_is_defined_once_test.dart
fvm flutter test test/policy/content_policy_test.dart test/policy/gate_rules_test.dart
fvm flutter test test/domain/policy/export_envelope_test.dart
dart run tool/check_policy.dart                     # exits 0 on the clean tree
# then, by hand, for each of the two new rows: plant an offender, watch it exit 1
# naming the rule id, and delete the file before committing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): Disclaimers, ContentPolicy, ExportEnvelope and the two copy gate rows`
