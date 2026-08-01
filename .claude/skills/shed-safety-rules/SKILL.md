---
name: shed-safety-rules
description: The five safety rules as structural mechanisms, not reminders. Use before adding any default, pre-fill, suggestion, autofill, placeholder, validation, disclaimer or automatic correction, and before changing a stored value. Do NOT use for clear dates (shed-withdrawal).
---

# The five safety rules as mechanisms

Spec §12's five rules are the ones where a defect hurts somebody who is not the user. Spec §12 asks
for them "in the code review checklist"; a checklist is the weakest available mechanism, because it
depends on a tired human at 11pm noticing an absence. So each rule is pushed as far up this ladder
as it will go:

**unrepresentable → unconstructible → unpersistable → a test over the source text → documented.**

**The standing rule: a rule that has dropped to merely *documented* has been deleted, whatever the
prose says.** If your change removes a type, a `CHECK`, a policy rule or a layer ban and replaces it
with a comment, a doc line or a review note, you have deleted a safety rule. Restore the mechanism
or do not make the change.

## The map — the level is binding, and it may only move up

| Rule | Mechanism | Level |
|---|---|---|
| §12.1 never default a withdrawal | `sealed WithdrawalPeriod`, private generative ctor, one entry point; no row = `WithdrawalNotRecorded` | unconstructible + unpersistable |
| §12.2 never give veterinary advice | the origination line + `ContentPolicy`, self-tested both ways | test on source text |
| §12.3 never a compliance record | `Disclaimers` referenced never re-typed; `ExportEnvelope` has no disclaimer parameter | unconstructible |
| §12.4 never silently correct | `Warning` / `Reviewed<T>` with no writer; no `warnings` column; `layer.data_no_validation` | unrepresentable + unpersistable |
| §12.5 timestamps are honest | `RecordedTime` quad + the paired SQL `CHECK`s | unrepresentable |

Proofs, code and the reasoning: `docs/engineering/05-domain-correctness.md` §7 (owner of all five),
`docs/engineering/00-README.md` §2.3, `docs/engineering/CODE-REVIEW-CHECKLIST.md` §2.2–§2.6.
Type shapes and file paths are `docs/engineering/CONVENTIONS.md` §2.6, §2.7, §2.14 — read there, do
not re-spell them here.

## §12.1 — never default a withdrawal

`shed-withdrawal` owns the type and the clear-date algorithm. This skill owns the level: absence of
a row **is** the state `WithdrawalNotRecorded`, so anything that can produce a row without a human
reading a bottle drops the rule off the ladder. Banned: SQL `DEFAULT`, drift `clientDefault`,
`?? 0`, `hintText: '28'` (a hint at 3am is a value), a "you usually enter 28" suggestion, a
migration that fills a withdrawal column from an older one, and carrying the withdrawal across
repeat-last-treatment. Two gates prove it; decision #52 allows no third (05 §3.9, §3.10).

## §12.2 — never give veterinary advice

The line that resolves every argument:

> **The app may arithmetic-transform a number the user supplied. It may never originate a number
> that is a clinical decision.**

Counting down from the N the user typed is arithmetic. Suggesting N is origination. "She has been
penned 26 hours" is arithmetic. "That is light for a twin" is origination. The full allowed/
forbidden table is 05 §7.3.

`ContentPolicy` (`lib/domain/policy/content_policy.dart`, CONVENTIONS §2.14) holds
`bannedInUserFacingText` — ten regexes over string literals in `lib/**.dart` and message values in
`lib/l10n/*.arb` — and `allowlist`, keyed by `Disclaimers.*` constants. A new pattern ships with a
planted offender **and** a legitimate-copy case in the two-way self-test, because a guard that never
fires is indistinguishable from a broken one.

Also §12.2, and invisible to every regex: never pre-select a death cause from age-at-death or
birthweight (a vocabulary the user picks from is fine; inference is advice), never put a `DEFAULT`
on a column that could encode a clinical value (lambing ease, `ewe_seasons.status`, withdrawal days
— decision #31), and label a user-set threshold as the user's: *"past your 24 h threshold"*, never
*"ready"*.

## §12.3 — never a compliance record

`Disclaimers` is an `abstract final class` in `lib/domain/policy/disclaimers.dart` — it cannot be
instantiated *or* extended, so nobody can subclass it and shadow a string. Its three constants are
**referenced, never re-typed**, including inside `ContentPolicy.allowlist`; `copy.disclaimer_retyped`
plus a single-definition test enforce that. They are deliberately not in the ARB: a translator can
soften an ARB string and the app has no mechanism to notice.

`ExportEnvelope` (`lib/domain/policy/export_envelope.dart`, R65) **has no disclaimer parameter** —
`ExportEnvelope.standard({now, appVersion})` is its only constructor, and every writer signature
takes one. That is what makes the footer unconstructible-around rather than remembered.
`export.csv_bytes` and `export.pdf_document` confine CSV and PDF production to one file each.

**The remaining hole is a third format.** A plain-text or Markdown "summary" goes through neither
confined file, so neither policy rule fires and no golden exists. A new export format takes an
`ExportEnvelope`, gets its golden and gets its `export.*` confinement row **in the same commit**.

## §12.4 — never silently correct a user's entry

`Warning`, `WarningCode` (11 members) and `Reviewed<T>` live in
`lib/domain/validation/warning.dart` (CONVENTIONS §2.6). Read the negative space: `Warning` has no
`fix()`, no `corrected`, no callback, no repository reference; `Reviewed<T>` carries the
byte-identical value and has no `cleaned` getter. The mutation API does not exist, so no amount of
call-site carelessness produces one.

Four structural guarantees your change must preserve:

1. Validators are **pure top-level functions**, `check<Thing>(...) → List<Warning>`, one per file,
   no class, no `Validator` suffix. They hold no writer, so they cannot write.
2. **No `warnings` column** in any entity table. Warnings are recomputed on read, so they can never
   diverge from their source or be mistaken for user data on export.
3. **Warnings never gate the save.** A blocked save produces a lost record, which is worse than a
   contradictory one, and every write commits immediately.
4. `lib/data/**` has no import path to `lib/domain/validation/**` (`layer.data_no_validation`), so a
   repository *structurally cannot* produce a `Warning`. R53 moves the job to the controller;
   **shed-riverpod-providers** states that rule and this skill does not restate it — what belongs
   here is only the level it sits at, which is *unrepresentable*, not *reviewed*.

The `normalize*` ban is on functions that **return a corrected domain value**. A projection stored
*alongside* the verbatim value is fine — `tag_digits` beside `tag` drives the keypad filter and is
never shown to a user (decision #55).

Say **warning**, never **flag**: `flags` is banned in prose and in code (CONVENTIONS §5.1, R71).

## §12.5 — timestamps are honest

The `RecordedTime` quad's four parts, and the paired SQL `CHECK`s that make an inconsistent quad
unstorable, are `05 §4` with the column spellings in R37/R38 — read them there (`shed-domain` owns
the value, `shed-drift-schema` the columns). Two consequences you own:

- **A table without the provenance quad has no edit verb** (R37). Until the quad lands on
  `PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations`, those tables get no edit path.
  An "auto" label must be unfalsifiable, not merely unchallenged.
- **Every displayed event time carries its provenance label.** A bare `03:21` is a review failure
  (CONVENTIONS §5.4). `RecordedTime.provenanceLabel` is an exhaustive switch and can never be empty.

## Gotchas

- **A naive `contains()` source scan misses long strings.** Dart wraps them across adjacent string
  literals, so the phrase is never contiguous in the source text and the guard silently passes. Any
  scanner extracts and joins string literals before matching. This was a real defect, not a theory.
- **`ContentPolicy` cannot see arithmetic, and cannot see a runtime substitution.**
  `(birthWeight.inKilograms * 50).round()` fed into an ARB message reading `"Give {ml} ml"` matches
  no pattern and is the exact banned case: AHDB publishes 50 ml/kg of colostrum, the app holds the
  birthweight, multiplying is one line and would be *helpful*. It is a dose suggestion.
- **The §12.4 hole is the controller.** Controllers may import `lib/domain/validation/`, so a
  helpful "obviously the birth type was mistyped, fix it" passes every layer rule and every gate.
  The contradiction *was* the record. Emit `WarningCode.birthTypeLambCountMismatch` instead.
- **Silent deletion is §12.4 in the other direction.** A lambing carrying only a timestamp is a true
  statement — something happened to this ewe at 03:20. Never garbage-collect it; provide an explicit
  delete on the ewe card.
- **There is no birth-type chooser anywhere in the product** (ruling P8), and that is precisely what
  moves §12.4 up the ladder from *procedural* to *structural*: a value nobody can pick is a value
  nobody can be silently corrected about. A segmented control for birth type is a defect. What
  replaces it — the strokes, the stamp, the one surviving choice control — belongs to
  **indelible-marks-and-strikes**.
- **`AUTO-CAPTURED` and `DERIVED FROM 3 STROKES` are the sole statement of the §12.5 and §12.4 claims
  on their line**, which is exactly the fact that disqualifies them from the design system's
  stamp-size exemption. The corrected exemption test and both sizes are **indelible-design-system**'s;
  what this skill asserts is that a safety claim is never the smallest thing on its row.
- **Repeat-last-treatment is the highest-risk feature for §12.1** precisely because pre-filling
  every field *except one* reads as an oversight to whoever implements it next. NADIS: withdrawal
  periods "can change for the same medicine and differ between products with the same active
  ingredient". Put that sentence in a comment at the copy site or it will be "fixed".
- **A soft-voided treatment's stored `clear_date` is never recomputed or blanked.** It may already
  have been printed into a medicine book handed to a vet.

## Not this skill

- The clear-date algorithm, `WithdrawalPeriod`'s shape, civil-day arithmetic → **shed-withdrawal**.
- What the shepherd sees when a record is struck, warned or queried — the strike, the margin, the
  time-boxed undo affordance → **indelible-marks-and-strikes**. Its body defers §12.4's *mechanism*
  to this skill; do not restate its rendering here.
- Copy, ARB, tone and the absolutely-banned word list → **shed-accessibility-and-copy** (the list
  itself is in `CLAUDE.md`, mirroring CONVENTIONS §5.3).

## Definition of done

- [ ] Every rule this change touches sits at the same level in the ladder as before, or higher.
- [ ] Nothing new can put a number in a withdrawal field that the user did not read off a bottle —
      no default, `clientDefault`, `?? 0`, hint, suggestion, copy-across or migration fill.
- [ ] Every new number and every new sentence transforms user data; none originates a clinical
      judgement. New `ContentPolicy` patterns ship with both halves of the self-test.
- [ ] Every export writer takes an `ExportEnvelope`; a new format also ships its golden and its
      `export.*` confinement row in the same commit; no `Disclaimers` string is re-typed.
- [ ] No `fix()`, no `corrected`, no `cleaned`, no `warnings` column, no
      `lib/data/**` → `lib/domain/validation/**` import, no save blocked by a warning.
- [ ] Every event time written carries the quad; every event time rendered carries its provenance
      label; no table gained an edit verb without the quad.
- [ ] `dart tool/check_policy.dart` is clean and the safety-rule tests in `test/policy/` pass.
