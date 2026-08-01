---
name: shed-code-review
description: >-
  Reviews a Shed Book change the way this project's checklist prescribes rather than the way a general
  review does — read the diff in order of irreversibility, say nothing about anything CI already
  proves, and spend the whole review on the five safety rules asked as questions and the one Quick
  Entry question. Invoked by the developer by name, so it never competes with the bundled review.
disable-model-invocation: true
---

# The Shed Book review

**This is the project's review, not Claude Code's bundled `/code-review`.** It deliberately ignores
most of the diff. `docs/engineering/CODE-REVIEW-CHECKLIST.md` owns this procedure and outranks this
skill on every rule; `docs/engineering/00-README.md` §8 step 10 is the same order in one sentence.
This skill routes attention — open the checklist section it names, do not re-derive the rule here.

**Do NOT use for** being the authority on any individual rule — the five safety rules as structural
mechanisms are **shed-safety-rules**. For depth on a finding, load the owning skill: **shed-withdrawal**,
**shed-write-path**, **shed-drift-schema** / **shed-migrations**, **shed-riverpod-providers**,
**shed-dependencies-and-toolchain**, **shed-export-and-restore**, **shed-accessibility-and-copy**,
**indelible-design-system**.

## 1. Run the gates before you read a line

```bash
dart tool/check_policy.dart     # ~2.5 s, no Flutter, no network. "policy ok" or exit 1.
                                # NEVER `dart run` — that adds an implicit pub get.
make check                          # check_policy → dart format --set-exit-if-changed → analyze --fatal-infos --fatal-warnings
```

**A green gate is a licence to ignore checklist §1, not a licence to merge** — everything in §2 is
still unexamined. Never spend a comment on a §1 property (layers, raw hex, `DateTime.now(`, banned
Riverpod-3 APIs, gestures, destructive DDL, `?? 0` in the two stat paths…). If one was violated **and
the gate passed, the fix is a rule row in `tool/check_policy.dart`, not a review comment** — a comment
holds until the next tired Tuesday. Never propose a second scanning script (decision #10: one gate,
one allowlist, one exit code), and never weaken a rule, an allowlist or an exit code to green a build.

**The boxed notes are the only part of §1 you carry in your head:** §1.3 (`clock.now(` has no row),
§1.5 (`stream.invalidate` has no exemption and `lib/app.dart` legitimately needs one), §1.10
(*"your data never leaves your phone"* is a human check), §1.11 (**G0 ran 2026-08-01, but G1 is still
unwritten until N31-T03 — do not review as if the permission set were asserted on every push**), §1.13. Count the rule
table, never a sentence about it: §1.8 is **fourteen** `gesture.*` rows, not eleven.

## 2. Read in this order — irreversibility, not print order

| # | Files | Why here |
|---|---|---|
| 1 | `pubspec.yaml`, `pubspec.lock`, `tool/policy_allowlist.txt`, `android/expected_permissions.txt`, `.fvmrc` | A dependency changes what the product may claim; an `[exempt]` line deletes a rule for one file, forever, silently |
| 2 | `lib/core/db/tables/**`, `drift_schemas/`, `lib/core/db/migrations.dart` | Irreversible after the first snapshot — no server backfill, and most users have no backup |
| 3 | `lib/data/**` | The only layer that writes |
| 4 | `lib/domain/withdrawal/`, `lib/domain/stats/`, `lib/domain/time/` | Arithmetic that is invisible when wrong |
| 5 | `lib/l10n/app_en.arb` | Every string a human reads, and the surface the §12.2 scan acts on |
| 6 | `lib/features/**` | Last, and largely §1's problem |

## 3. The five safety-rule questions (checklist §2.2–§2.6) — ask each *of the diff*

1. **§12.1 — Does anything put a number in a withdrawal field that the user did not read off the
   bottle?** Repeat-last-treatment copies product, dose, route and batch and starts the withdrawal
   **empty**; `hintText: '28'` is a value at 3am; a migration never populates a withdrawal.
2. **§12.2 — Does this originate a number or a judgement, rather than transform one the user
   supplied?** Counting down from the N they typed is fine. `birthWeight * 50` for colostrum is a dose
   suggestion. A pen tile saying "Ready to turn out" makes the clinical call; *"past your 24 h
   threshold"* does not.
3. **§12.3 — Does this produce an artefact a shepherd could hand to an inspector, without the footer
   that says it is not one?** Any writer that is neither CSV nor PDF passes every `export.*` row and
   ships unfootered. Every writer takes an `ExportEnvelope`; every new format gets its confinement row
   and its golden in the same commit.
4. **§12.4 — Does this change a value the user entered, on the way in or on the way out?** A
   controller "fixing" a birth type to match the lamb count is the textbook violation: flag with a
   `WarningCode`, never fix, and a warning never gates the save. Migrations never infer.
5. **§12.5 — Does every event time this writes or renders carry its provenance?** A bare `03:21` is a
   review failure — `RecordedTime.provenanceLabel`, formatted only in `formatters.dart`. **A table
   without the provenance quad has no edit verb** (R37).

## 4. The one Quick Entry question (checklist §3.4, README §2.2)

> **Does the shepherd have to do anything new before the record exists?**

Four ways the answer is yes: **a tap** (a confirmation, a disambiguation, a "which season?"); **a
wait** (an `await`, a `Timer`, a debounce, a spinner between a digit and a redraw); **a decision** (a
monetization *prompt* is not a block, and neither may surface mid-entry or 22:00–06:00); **a thing on
screen that was not there before** (Quick Entry is a shed screen — nothing monetization-related, at any
entitlement state, ever). If yes, the change lands somewhere calmer, in daylight. The 6-tap budget in
`test/features/tap_budget_test.dart` is the only mechanical hold on spec §15's fifteen seconds.

## 5. Wave through / never wave through

**Wave through:** generated files (`*.g.dart`, `*.drift.dart`, `drift_schemas/*.json`), read only to
confirm nobody hand-edited one · anything in a §1 table · formatting · coverage and golden diffs
(neither gates) · new cases in an existing table-driven test.

**Never, however small:** `lib/domain/withdrawal/**` · `drift_schemas/**` · the `[exempt]` section of
`tool/policy_allowlist.txt` · `lib/domain/policy/disclaimers.dart` · `lib/main.dart` · any new export
format · any table gaining an edit verb · `android/expected_permissions.txt` · a `pubspec.lock` diff
in a PR that does not also change `pubspec.yaml`.

## 6. Gotchas — passes every gate, still wrong

- **Two `ref.watch`es combined in one `build()`.** No banned token appears; drift#3338 makes the pair
  render a state that never existed. One content statement per screen; fan-in happens in SQL.
- **Bare `AsyncValue.value`.** The other four accessors are grep-able; `.value` collides with
  `MapEntry` and every drift companion, so only a reviewer sees it. Same for `ChangeNotifierProvider`.
- **A named private const is a token you failed to put in `ShedTokens`**, and `Opacity` over a token
  colour is a colour that was never contrast-tested.
- **The 400 ms free-text debounce and the 200 ms note-search debounce are the only two**, and the
  keypad path has none. A diff changing either changes checklist §2.13 in the same commit.
- **`showSnackBar(` is banned everywhere, including `lib/core/ui/feedback.dart`** — Indelible §9 wins
  over `CONVENTIONS §2.11` and `07 §15`. The receipt is the **committed row itself**, one line above
  the one being written; `confirmSaved` / `SaveReceipt` are that printed-receipt channel. **Undo is a
  time-boxed strike in the row's own margin and its window is stated in seconds**, never "until the
  SnackBar is dismissed". Nothing is erased: a strike prints `STRUCK hh:mm`, the row stays in the
  ewe's history, and the CSV carries `struck` / `struck_at` with every struck row included and marked.
- **There is no birth-type chooser anywhere** — Indelible wins over `06 §12`. Birth type is **derived
  from the tally strokes and labelled as derived**, which is what makes §12.4 structural. A diff
  adding `ShedChoiceRow` for birth type is refused; that control survives only for lambing ease 1–5.
- **The live row is a fixed layer above the thumb band and cannot scroll away** (`indelible.html:1138`
  has it inside `.stream` — the mockup is the defect, not the rule). And `DEAD`, `AUTO-CAPTURED` and
  `DERIVED FROM 3 STROKES` are **not exempt stamps**: each carries meaning nothing else on its line
  carries, so each meets the 18px floor rather than `--t-stamp:14px`.
- **Refuse, do not debate:** tag OCR or voice tag entry returning (the voice *note* ships), any "no
  `http` in `pubspec.lock`" gate (unsatisfiable — `http 1.6.0` sits on four regular edges), a Save
  button, a draft, an `isDirty`, or any wording resembling *"your data never leaves your phone"*.

## Done when

- [ ] `dart tool/check_policy.dart` and `make check` were run, and no finding restates what they prove.
- [ ] The diff was read in the §2 order; every never-wave-through file was read line by line, including
      the reason for each new `[exempt]` line and the five-part audit behind each new dependency (§2.17).
- [ ] All five §12 questions and — for anything reaching `lib/features/quick_entry/` — the Quick Entry
      question were asked of the diff, and each answer is recorded, including "does not touch this area".
- [ ] Findings are ranked by irreversibility, each names its checklist section or `CONVENTIONS` rule id,
      and each is a defect or a rule row to add — never a style preference.
- [ ] Any §1 property violated on a green gate left as a proposed row in `tool/check_policy.dart`.
