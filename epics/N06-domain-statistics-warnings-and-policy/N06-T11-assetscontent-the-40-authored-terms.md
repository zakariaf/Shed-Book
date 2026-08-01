# N06-T11 — `assets/content/` — the ~40 authored terms

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 11 of 11 |
| **Depends on** | N06-T10 |
| **Commit** | one commit · `feat(content): the ~40 authored husbandry terms` |

## 1. Why this task exists

Spec §11's only shipped data: the lambing-ease scale descriptions, the common death
causes, the common malpresentations and the common treatment routes — roughly forty generic husbandry
terms written from scratch, under the heading **"None that is licensed."**

> **R66, the right way round.** The plan's earlier wording — *"`R66` keeps them out of the ARB, and
> N07-T07 seeds `vocab_terms` from this file"* — has R66 backwards, and `00-AUDIT-accuracy.md` **B5**
> and `00-PLAN-CRITIQUE` **G4** both record the correction. R66 gives the forty terms **three homes,
> with no overlap**:
>
> | Half | Home | Epic |
> |---|---|---|
> | **Keys** (`dc_starvation`, `ease_1`, …) | `lib/core/db/seed/first_run.dart`, `vocab_terms` rows with `origin = 'seeded'`, `label = NULL` | N07-T07 |
> | **Labels** (the English words) | `lib/l10n/app_en.arb`, one message per key | **this task** |
> | **Long prose + provenance** | `assets/content/` — only authored prose too long to be a UI string, plus one provenance line per list | **this task** |
>
> `test/policy/vocab_labels_are_complete_test.dart`, which asserts the two sets are equal, is
> N07-T07's: it needs the seeded keys to compare against. Do not create it here.

So this is the **authoring** task. Forty husbandry terms, written from scratch, that a shepherd will
read at 03:20 and may rename the next morning.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §10.1 | the six lists and all forty keys, verbatim; the two constraints on the writing itself |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.6, §8.7 | the three homes, the `key` → `'vocab' + upperCamel(key)` mapping, and what is deliberately not in the ARB |
| `docs/engineering/CONVENTIONS.md` | §1, §4.6, R44, R66 | `assets/content/`'s scope, the vocabulary-key format, and that `LambingEase` carries no descriptions |
| `docs/engineering/05-domain-correctness.md` | §7.3, §6.8, §6.7 | the origination line every term is scanned against; *unattributed* is not *unknown*; the ease scale is paraphrased at the same semantic granularity |
| `shed-book-spec.md` | §11 | *"all generic husbandry vocabulary written from scratch"*, and no breed, medicine or regulatory database |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | every authored term is scanned by `ContentPolicy`; a dose or a *should* here is §12.2 |
| `shed-accessibility-and-copy` | the wording, the descriptions and which half of R66 lands where |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/content_scan_test.dart`
- **Test** — `'every authored term passes ContentPolicy and contains no dose, no should and no diagnosis'`
- **Why it is red today** — the forty labels do not exist and `assets/content/` is empty, so N07-T07's seeded keys would render blank at 3am and R66's ARB half would be missing — critique gap G4, as corrected by `00-AUDIT-accuracy.md` B5.

```dart
final terms = arbVocabMessages(File('lib/l10n/app_en.arb'))          // 40 values
  ..addAll(authoredProseUnder('assets/content/'));
for (final t in terms) {
  final hits = ContentPolicy.bannedInUserFacingText.where((r) => r.pattern.hasMatch(t));
  expect(hits, isEmpty, reason: '$t → ${hits.map((h) => h.why)}');
}
expect(terms.length, greaterThanOrEqualTo(40));
```

```bash
fvm flutter test test/policy/content_scan_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — author the forty labels into the ARB,
author the provenance lines and the long-form ease descriptions into `assets/content/` (the asset
directory is already declared in the pubspec, N00-T03), and scan them in both directions.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 **step 7 (the ARB)** plus the asset directory. No Dart under `lib/` changes at all.
Step 1 is N07-T07's and the commit message says so.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/l10n/app_en.arb` | **Extended.** Forty `vocab*` messages, each with a `description`. The mapping is mechanical: `vocab_terms.key` → `'vocab' + upperCamel(key)` — `dc_starvation` → `vocabDcStarvation`, `ease_1` → `vocabEase1`, `mp_breech` → `vocabMpBreech` |
| 2 | `assets/content/vocabulary_provenance.md` | **New.** One provenance line per list, six lines, each stating that the list was authored for this app. This is the artefact the "no verbatim third-party copy" check exists to protect |
| 3 | `assets/content/lambing_ease.md` | **New.** The 1–5 scale in long form, paraphrased at the same semantic granularity as the published scales and copied from none of them. The short label stays `vocabEase1`…`vocabEase5` in the ARB; this file is the expansion a screen can show |
| 4 | `lib/l10n/app_localizations*.dart` | **Regenerated and committed** (`00-README` §7.1). The `codegen` CI job does not exist until N08 — regenerate by hand and read the diff |
| 5 | `test/policy/content_scan_test.dart` | **New.** The anchor, scanning both homes |

### 5.2 The six lists, and all forty keys

Copied from `03` §10.1. The keys are frozen; only the labels are yours to write.

| `list` | n | Keys |
|---|---|---|
| `lambing_ease` | 5 | `ease_1` … `ease_5` |
| `death_cause` | 8 | `dc_starvation`, `dc_hypothermia`, `dc_watery_mouth`, `dc_joint_ill`, `dc_crushed`, `dc_stillborn`, `dc_unknown`, `dc_other` |
| `malpresentation` | 8 | `mp_head_back`, `mp_one_leg_back`, `mp_both_legs_back`, `mp_breech`, `mp_backwards`, `mp_twins_together`, `mp_ringwomb`, `mp_other` |
| `treatment_route` | 8 | `rt_subcutaneous`, `rt_intramuscular`, `rt_oral`, `rt_topical`, `rt_intranasal`, `rt_intravenous`, `rt_intraperitoneal`, `rt_other` |
| `ewe_observation` | 6 | `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`, `obs_other` |
| `foster_method` | 5 | `fm_wet_adopt`, `fm_skin`, `fm_crate`, `fm_bottle`, `fm_other` |

Forty exactly. If your count is 41 you have added the sixth ease point that decision-record §7.1 open
question 15 leaves open — and that is a schema `CHECK` change, not a content edit.

### 5.3 The details that are easy to get wrong

- **The labels go in the ARB, not in `assets/content/`.** This is the correction in §1 and it is the
  single most likely thing to get wrong in this task, because the task's own title names the
  directory. `assets/content/` gets the provenance lines and the long-form ease prose; the forty
  words go in `app_en.arb`.
- **Paraphrase the ease scale; never adopt it.** The SRUC technical note the research cites is
  **image-based**, and neither its text nor its licence terms could be verified. Decision-record §4
  overturns "adopt them verbatim". The *concept* of a five-point assistance scale is not ownable; the
  sentences are. Write them in the app's own words at the same semantic granularity.
- **Every list carries a provenance line**, and the CI check for verbatim third-party copy scans
  **both** `assets/content/` and `lib/l10n/` (R66) — a check pointed at only one of them misses
  whichever half the copy was pasted into. T09's driver change is what makes both reachable.
- **A term is a label, not a sentence.** These render on 60×60 pt buttons at an 18 px floor under a
  head torch. *Watery mouth* fits; *"watery mouth (E. coli septicaemia in the first 24 hours)"* does
  not — and the parenthesis is also a diagnosis, which is §12.2.
- **No product name, no dose, no diagnosis, no *should*.** `ContentPolicy` will catch the obvious
  ones; it will not catch *"give 2 ml"* written as *"2ml"*, and it will not catch a brand name at
  all. The app ships **no medicine database** (decision-record §5.3 and spec §11), so `rt_oral` is a
  route and never a product.
- **`dc_stillborn` and `LambStatus.stillborn` are different things and both exist.** One is a
  user-pickable cause; the other is the lamb's status, with its own age bucket in T06. Do not
  rationalise them into one.
- **`dc_unknown` is not *unattributed*.** `dc_unknown` is a cause the user can pick; *unattributed* is
  our word for a blank field, and T06 tallies them in separate rows. Never merge the columns
  (`CONVENTIONS` §5.1).
- **Every term is user-editable afterwards, and nothing here is a default the app defends.** A user's
  edit writes `vocab_terms.label`, which no locale change and no app update touches; removing a term
  sets `hidden_at` and never `DELETE`s, because a term in use is the target of a foreign key with
  `ON DELETE RESTRICT`.
- **Flutter's asset declaration is not recursive.** A `pubspec.yaml` entry for `assets/content/`
  bundles the files **directly** in that directory and nothing in a subdirectory. Keep the files flat,
  or you will ship an app whose content file is missing only in release.
- **Nothing in `lib/domain/` reads these assets.** `rootBundle` is `package:flutter/services.dart`,
  which layer rule 1 bans. The screen that renders the long-form ease prose (N16) loads it; the domain
  never sees it. That is also why `LambingEase` carries no descriptions (R44).
- **Write for a reader at 03:20 on night eleven.** The terms are picked one-handed in the dark from a
  list. Short, concrete, and in the words a shepherd already uses — *legs back*, not *carpal flexion*.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/policy/content_scan_test.dart` | **anchor:** `'every authored term passes ContentPolicy and contains no dose, no should and no diagnosis'`, over the ARB values **and** the `assets/content/` prose · `'there are forty vocab messages, one per seeded key'` — the ARB half of the count, pinned here so a missing label is caught before N07-T07's parity test exists · `'every vocab message carries a description'` · `'the ARB message ids follow vocab + upperCamel(key)'`, checked against the forty keys spelled out in §5.2 · `'each of the six lists has a provenance line in assets/content/'` · `'no authored term names a product or a brand'` — an assertion by review with an explicit fixture list, because no regex catches a brand name |

**No `uk-zone` case.** This task ships prose. Nothing here computes with time.

`test/policy/vocab_labels_are_complete_test.dart` — the seeded-keys-versus-ARB set equality — is
**N07-T07's**, and this task's count assertion is deliberately the weaker half that can run today.
Say so in the test's comment, so nobody deletes it later as a duplicate.

## 6. Constraints that bind this task

- **§12.2, held at *caught by a gate*.** These forty strings are exactly what `copy.vet_advice` reads, and `12 §10` is explicit that no widget test can exhibit the absence of advice. *Twin lamb disease* is vocabulary a shepherd already uses and is in scope; *treat with*, a dose, a course, a product name or a breed is advice and is not. Write the reason beside any term you are unsure about rather than adding an allowlist line.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Bundled assets stay under 5 MB** (decision #127). Six markdown files are noise against that budget; a photograph would not be.

## 7. Definition of Done

- [ ] `'every authored term passes ContentPolicy and contains no dose, no should and no diagnosis'` passes, and was seen to fail first for the stated reason
- [ ] roughly forty terms, all generic husbandry vocabulary
- [ ] no product name, no dose, no diagnosis, no *should*
- [ ] the file is the single seed source for `vocab_terms`
- [ ] every term is editable by the user afterwards
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> Read the fourth line against §1: R66's three homes make **`first_run.dart` the single source of the
> keys** and **`app_en.arb` the single source of the labels**. "Single seed source" is satisfied by
> there being exactly one place each half is written — which is what this task and N07-T07 together
> establish — not by `assets/content/` being read at seed time. Nothing reads `assets/content/` from
> `lib/data/`.

## 8. Verification

```bash
fvm flutter test test/policy/content_scan_test.dart
fvm flutter gen-l10n && git diff --stat -- lib/l10n/   # regenerate, read the diff, commit it
dart run tool/check_policy.dart                        # copy.vet_advice now walks assets/content/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(content): the ~40 authored husbandry terms`
