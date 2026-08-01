# N33-T05 — The ARB completeness sweep

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 5 of 9 |
| **Depends on** | N33-T04 |
| **Commit** | one commit · `test(policy): the ARB completeness sweep` |

## 1. Why this task exists

Every user-facing string is an ARB key with a `description`, and **no domain noun appears
as a literal** anywhere. The ARB has been authored inside every widget task since N13 — this sweep is
verification, not the authoring pass the old plan deferred.

It also closes a gap that has been silently green since N03. `10 §10` amendment (a) is explicit:
*"The walker does not currently reach the ARB at all"* — `01 §3.2`'s `main()` skips every file that
does not end `.dart`, so `copy.arb_domain_noun` **and** `05 §7.3`'s `ContentPolicy` scan over
`lib/l10n/*.arb` have had nothing to run against. Two of the five safety rules lean on that scan. This
task lands the reader and proves it fires in both directions.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/10-accessibility-and-i18n.md` | **§8.4** (the six ARB house rules, and the four worked messages with their safety descriptions) · **§8.5** (the terminology-placeholder rule, the ICU plural shape, and the four load-bearing details) · **§8.6** (the forty vocabulary labels and their mechanical key mapping) · **§8.7** (what is deliberately **not** in the ARB — the closed list) · **§10** (the gate rows, their scopes, and the **two driver amendments this task depends on**) · §8.2 (`l10n.yaml`, `required-resource-attributes`, `use-named-parameters`) · §8.3 (the `supportedLocales` ordering trap) · §9.1–§9.4 (one formatting authority; no all-numeric human date) · §11 rows 22–31 | every property this sweep asserts, and every one it must not |
| `docs/engineering/12-testing.md` | **§1.4** (what is a gate and what is a test — the split this task turns on) · §11.1 (a policy test is named for the **property**) · §11.2 (`dart_test.yaml`'s `policy` tag) | why half of this task is a self-test of the gate rather than a scan |
| `docs/engineering/05-domain-correctness.md` | §7.2–§7.3 (the origination line, `ContentPolicy`'s regex scan over string literals **and ARB messages**, self-tested in both directions) · §8 (terminology, and its agreement with `10 §8.5`) | the §12.2 half of the scan, and the file this task feeds |
| `docs/engineering/CONVENTIONS.md` | §5.1–§5.4 (the vocabulary, the engineering nouns, the absolute ban list, the copy conventions) · **R66** (three homes for the forty labels, no overlap) · R56 (the four `[exempt]` lines) · R57 · R60 · R67 · §4.7 (rule-id namespaces) | **BINDING** on the words and on the rule ids |
| `docs/engineering/01-architecture.md` | §3.2 (the gate driver, `_bannedText` / `_bannedPattern`, and the skip list this task extends) | where the ARB reader lands |
| `docs/engineering/09-export-formats.md` | §3.x (CSV headers are stable **English keys**, never user labels) | the one place a domain noun is legitimately a literal, and it is not in the ARB |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#61** (terminology is a user-owned overlay; no domain noun in any ARB message) · #108 (gen-l10n/ARB from day one, `en` only, never an all-numeric human date) · #62 (`Disclaimers` referenced, never re-typed) | the two decisions the sweep holds |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 N33-T05, with its `[audit]` note naming `test/policy/arb_has_no_domain_noun_test.dart` and its pairing with `vocab_labels_are_complete_test.dart` | the file-name conflict this task rules |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the ARB, its descriptions and the terminology placeholder rule |
| `shed-testing` | the sweep, and the gate-versus-test split it turns on |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/arb_completeness_test.dart`
- **Test** — `'every user-facing string is an ARB key with a description and no domain noun is a literal'`
- **Why it is red today** — nothing verifies the ARB as a whole, so one missed string would ship untranslatable and un-renameable.

```bash
fvm flutter test test/policy/arb_completeness_test.dart   # expect: failing, for the reason above
```

Sharpen it so it fails for the *interesting* reason rather than the cheap one. `l10n.yaml` already sets
`required-resource-attributes: true`, which was measured on 3.44.8 in N01-T03 and fails only on a missing **`@key` block**, not on a missing `description`; the description itself is held by `test/policy/l10n_bootstrap_test.dart` — an
assertion that only checks presence is duplicated work wearing a safety hat. Assert instead that every
description is non-empty, is longer than a stub, and that the two safety descriptions —
`@withdrawalSource` and `@penReadyThreshold` — are **byte-identical** to `10 §8.4`'s published text.
Those two descriptions are the mechanism that stops a future contributor "improving" a safety string,
and they are the only thing standing between `as entered by you` and a shorter, friendlier lie.

**Green.** The minimum code that passes, and nothing beyond it — the sweep over the widget tree and the ARB, failing with the file and the literal
named.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The file-name conflict, ruled

`00-PLAN-CRITIQUE` §11.3 carries an `[audit]` note preferring `10 §7.3`'s name,
`test/policy/arb_has_no_domain_noun_test.dart`. That name describes **one** of the three properties
this task holds. **Ruling: one file, `test/policy/arb_completeness_test.dart`**, because all three
properties share one ARB reader and splitting them means parsing the same JSON three times and
maintaining three copies of the §8.7 exception list. `10 §7.3`'s third bullet is amended in this commit
to name the file that exists.

`test/policy/vocab_labels_are_complete_test.dart` (`10 §8.6`, R66) is a **separate, existing** file and
stays: it asserts the forty seeded `vocab_terms` keys and the forty ARB messages are the same set. Do
not fold it in — it is a database-versus-ARB parity test, not an ARB-internal one.

### 5.2 The files, in `00-README` §8 order

**No schema, no domain, no data, no wiring, no controller, no UI.** One `tool/` change, one ARB-adjacent
document amendment, one new test file — say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | **Edit — `10 §10`'s two driver amendments.** (a) One reader that walks `lib/l10n/*.arb`, decodes the JSON and yields each non-`@`-prefixed message **value** as a string. It is a **separate** reader from the Dart one: JSON has no adjacent-string-literal problem, so `05 §7.3`'s join-before-matching rule applies to the `.dart` half **only** and copying it onto the ARB half would silently concatenate unrelated messages. (b) `lib/l10n/app_localizations*.dart` joins `*.g.dart` and `*.drift.dart` in the skip list — it is generated, it is committed, its name matches neither existing pattern, and every rule that fires on it fires on the ARB twice |
| 2 | `tool/check_policy.dart` | **Edit — `copy.arb_domain_noun`'s skip.** The rule must skip the `term*Singular` / `term*Plural` messages, which are the **only** place those words legitimately appear. Implement the skip **in the rule**, not in `tool/policy_allowlist.txt`: R56 fixes the day-one `[exempt]` list at four lines and an exemption is invisible where a rule condition is readable |
| 3 | `test/policy/arb_completeness_test.dart` | **New. The anchor, written first.** `@Tags(['policy'])`. Reads `lib/l10n/app_en.arb` as JSON and `lib/features/**` as text; holds the three properties, the §8.7 closed list, and the gate's two-direction self-test |
| 4 | `docs/engineering/10-accessibility-and-i18n.md` §7.3, §10 | **Amended, in this commit.** §7.3's third bullet names this file; §10's amendment (a) and (b) are marked landed with the commit that landed them |
| 5 | `docs/engineering/01-architecture.md` §3.2 | **Amended, in this commit.** The driver now has two readers and a longer skip list. `10 §10` says 01 *"must accept them"*; this is where it does |

### 5.3 The signatures

The reader, and the rule that must not be copied onto it:

```dart
// tool/check_policy.dart
/// Walks lib/l10n/*.arb and yields every message VALUE (skipping @-prefixed
/// metadata). Separate from the Dart reader on purpose: 05 §7.3 joins adjacent
/// string literals before matching, because Dart splits a long string across
/// two literals and a naive scan misses the banned phrase. JSON has no such
/// problem — joining here would concatenate two unrelated messages and match a
/// phrase that exists in neither.
Iterable<({String file, String id, String value})> arbMessages(Directory root) sync* { … }
```

The three properties, as the test expresses them:

```dart
// test/policy/arb_completeness_test.dart
@Tags(['policy'])
library;

/// 10 §8.7's closed list. A sweep that demands EVERY user-facing string be an
/// ARB key fails on these seven, and the obvious "fix" is to move them into the
/// ARB — into the one place a translator can soften a safety string. Adding an
/// eighth entry is a review conversation, not an edit (10 §8.7).
const kNotInTheArb = <String>[
  'lib/domain/policy/disclaimers.dart',        // decision #62
  'lib/core/failure.dart',                     // the six ShedFailure.userMessage strings
  'lib/domain/time/recorded_time.dart',        // provenanceLabel — a §12.5 property, not copy
  'lib/core/ui/night_error_panel.dart',        // renders outside Localizations by construction
  // stable keys (time_source, WithdrawalTarget, LambCount, AnimalClass, vocab
  // keys, CSV headers) live in their enum or their schema — a machine value is
  // a contract, not copy; anything the user typed lives in SQLite; the price
  // comes from ProductDetails.price.
];
```

### 5.4 The details that are easy to get wrong

- **The gate proves the absence; the test proves the gate is alive.** `12 §1.4` draws the line and this
  task is the clearest case of it in the project. Do **not** re-implement `copy.literal_text` or
  `copy.arb_domain_noun` as a `RegExp` inside a `test()` — express the rule as a gate row and let the
  test plant a violation, run `tool/check_policy.dart`, and assert exit code 1 with the rule id in the
  output. Then plant a *legitimate* string and assert exit code 0. A one-direction self-test is how a
  rule that matches everything ships.
- **The ARB reader has been missing and everything looked green.** `10 §10` amendment (a). Until it
  lands, `copy.arb_domain_noun` scans zero files and so does `ContentPolicy`'s ARB half — which is
  §12.2's mechanism. Land the reader **first**, then watch the existing rules fire on the real ARB for
  the first time; expect findings.
- **`required-resource-attributes: true` does NOT fail the build on a missing `description`** — measured on 3.44.8 in N01-T03; it fails only when the whole `@key` block is absent. `test/policy/l10n_bootstrap_test.dart` holds the description half from N01-T03 onward. Asserting
  presence duplicates gen-l10n and gives false confidence. Assert non-emptiness, a minimum length, and
  byte-identity for the two safety descriptions.
- **`copy.literal_text` is scoped to `lib/features/` only, and widening it costs four exemptions.**
  `lib/core/ui/` components take their strings as parameters, `feedback.dart` builds its label from a
  `SaveReceipt`, and `night_error_panel.dart` **must** contain literal English — a `Localizations`
  lookup there is a crash inside the crash handler. Those are reviewed by hand and none of them needs
  an `[exempt]` line; the day-one allowlist stays at R56's four (`10 §10`).
- **The `term*` skip goes in the rule, never in the allowlist.** `termEwePlural` legitimately contains
  the word *ewes*. An `[exempt]` line for `lib/l10n/app_en.arb :: copy.arb_domain_noun` would delete
  the rule for the whole file, forever, silently — which is precisely what R56 and `CR §1.1` say an
  exemption does.
- **Placeholders are `singularTerm` / `pluralTerm`, never `singular` / `plural`.** `plural` is an ICU
  keyword; a placeholder that shadows it inside a plural expression parses today and stops parsing on
  the next `gen-l10n` release. Assert the spelling, because the failure is a build break months later
  with no obvious cause.
- **`count` is `"type": "num"`**, matching Flutter's own plural example; and arguments are **named**
  (`use-named-parameters: true`), so the positional spelling does not compile.
- **Never derive a plural by appending `s`** — not in the UI, not in exports, not in a semantics label.
  The user typed one word; guessing the other is safety rule 4. The map supplies both forms.
- **No date or time is formatted inside a message.** ARB supports `DateTime` placeholders with a
  `format`; this app does not use them, because `Instant` and `LocalDate` are extension types over
  `int` and `String`, and the one formatting site is `lib/core/ui/formatters.dart`. Two authorities is
  one too many, and an ICU-formatted date renders in the **runner's** zone — see the DST case below.
- **No all-numeric human date** (`copy.numeric_date`, R60). `d MMM y`. The withdrawal countdown is the
  single worst place to break it, because the number it renders is the safety-critical one.
- **An orphan ARB key is dead copy and a missing one is a runtime blank.** Assert both directions: every
  message id is referenced somewhere under `lib/`, and every `AppLocalizations.of(context).x` call site
  names an id that exists. The second is what stops a rename shipping as an empty label at 3am.
- **The failure message must name the file *and* the string.** `12 §6.3`'s standard applied here: a
  sweep that says *"a literal was found"* costs an hour; one that says
  `lib/features/pens/pen_board_screen.dart:212 — Text('Ready')` costs a minute.
- **`ContentPolicy` is self-tested in both directions and this task is not a second copy of it.**
  `05 §7.3` owns the banned-phrase scan; this file asserts the reader reaches the ARB, not that the
  regexes are right.
- **`@@locale` is `en` and there is no `synthetic-package` line in `l10n.yaml`** — the flag cannot be
  enabled on 3.44 (`10 §11` row 31).
- **CSV headers and `animal_class` values are stable English keys** (`09`). A sweep that demands every
  occurrence of *ewe* be a placeholder will fire on the export layer, which is correct English and a
  machine contract. Scope the rule to `lib/l10n/` as `10 §10` writes it.

### 5.5 The full test set

| File · case | What it asserts |
|---|---|
| `test/policy/arb_completeness_test.dart` · `'every user-facing string is an ARB key with a description and no domain noun is a literal'` | **The anchor.** The three properties in one case, run over the real ARB and the real `lib/features/` tree |
| `…` · `'every description is non-empty and longer than a stub'` | Presence is gen-l10n's job; substance is this file's |
| `…` · `'the withdrawalSource and penReadyThreshold descriptions are byte-identical to 10 §8.4'` | *edge.* The two descriptions that carry a safety rationale. This is the case that stops *"as entered by you"* being shortened |
| `…` · `'every ARB message id is referenced at least once under lib/'` | *edge.* An orphan key is dead copy nobody deletes |
| `…` · `'every AppLocalizations call site names an id that exists in the ARB'` | *edge.* The other direction — a rename that ships as a blank label |
| `…` · `'no placeholder is named singular or plural'` | *edge.* `plural` is an ICU keyword; this parses today and breaks on the next gen-l10n |
| `…` · `'every plural message declares count as num and uses named parameters'` | *edge.* Flutter's own plural shape |
| `…` · `'no message declares a DateTime placeholder or a format'` | *edge.* One formatting authority (`10 §8.4` rule 4) |
| `…` · `'@@locale is en and l10n.yaml declares no synthetic-package'` | *edge.* `10 §11` row 31 |
| `…` · `'each of 10 §8.7's seven exceptions is present and is NOT an ARB key'` | *edge.* The closed list, asserted in the direction that matters: a `Disclaimers` string that moved into the ARB fails here |
| `…` · `'the gate exits 1 on a planted Text literal under lib/features/'` | *self-test.* Plant, run `tool/check_policy.dart`, assert exit 1 and `copy.literal_text` in the output, revert |
| `…` · `'the gate exits 1 on a planted domain noun in an ARB message'` | *self-test.* Same shape, `copy.arb_domain_noun` |
| `…` · `'the gate exits 0 on the same noun inside termEwePlural'` | *self-test, the direction that fails silently.* The skip is in the rule, and it works |
| `…` · `'the gate reads lib/l10n/*.arb at all'` | *edge.* `10 §10` amendment (a). Plant a banned phrase in a message value and assert the run goes red; without the reader it stays green and nobody notices for a year |
| `…` · `'the gate skips lib/l10n/app_localizations*.dart'` | *edge.* Amendment (b). Otherwise every ARB rule fires twice, once on the source and once on the generated Dart |
| `…` · `'no ARB message renders an all-numeric date'` | *edge.* R60 and `copy.numeric_date`, asserted over the message text as well as over the `DateFormat` call sites |
| `…` · `'no message formats a time, so a message cannot render 00:30 for an instant the app calls 01:30'` | *edge, `uk-zone`.* Run the file under `TZ=Europe/London` and again under the hostile zone: an ICU-formatted time inside a message resolves in the **process** zone, so the ambiguous hour is where the two disagree by exactly one hour. The assertion is structural — no `DateTime` placeholder exists — and the zone-tagged run is what proves the structure is load-bearing rather than stylistic |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every user-facing string is an ARB key with a description and no domain noun is a literal'` passes, and was seen to fail first for the stated reason
- [ ] every key has a `description`
- [ ] no domain noun appears literally in any message
- [ ] no user-facing literal exists outside the ARB
- [ ] the failure message names the file and the string
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `tool/check_policy.dart` reads `lib/l10n/*.arb` through its **own** reader, and skips `lib/l10n/app_localizations*.dart` — both amendments landed and both self-tested
- [ ] `copy.arb_domain_noun`'s `term*Singular` / `term*Plural` skip is **in the rule**, and `[exempt]` is still at R56's four lines
- [ ] the two safety descriptions are byte-identical to `10 §8.4`
- [ ] `10 §8.7`'s seven exceptions each have a case, and none of them is an ARB key
- [ ] the gate is self-tested in **both** directions for both `copy.*` rows
- [ ] `10 §7.3`'s third bullet and `01 §3.2`'s driver description are amended in this commit
- [ ] the zone-pinned case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/policy/arb_completeness_test.dart
fvm flutter test test/policy/vocab_labels_are_complete_test.dart
dart tool/check_policy.dart          # "policy ok" or exit 1
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the reader and the rules, reverting each:

```bash
# 1. Put a banned phrase in an ARB message value.
dart tool/check_policy.dart          # expect: exit 1, naming the message id
# 2. Put Text('Ready') in a features file.
dart tool/check_policy.dart          # expect: exit 1, copy.literal_text, with the line
# 3. Put "ewes" in termEwePlural — the legitimate case.
dart tool/check_policy.dart          # expect: exit 0. If it is 1, the skip is wrong
git checkout -- lib/
```

```bash
grep -c '"description"' lib/l10n/app_en.arb        # equals the message count
grep -rn "synthetic-package" l10n.yaml             # expect zero
grep -rn "DateFormat" lib/ --include=*.dart | grep -v core/ui/formatters.dart   # expect zero
fvm flutter gen-l10n && git diff --exit-code -- lib/l10n/   # generated output is committed and fresh
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): the ARB completeness sweep`
