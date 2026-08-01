## What changed

One line, in project vocabulary (`CONVENTIONS §5`). Not the branch name.

## The five safety rules (spec §12)

Ask each of the diff, not of the codebase. If the diff does not touch the area, write
"not reached" — do not tick it.

- [ ] **§12.1 — Never default a medicine withdrawal period.** The user reads it off the bottle. The app stores what they typed and shows its source as "as entered by you."
      *Does anything in this diff put a number in a withdrawal field that the user did not read off the bottle?*
- [ ] **§12.2 — Never give veterinary advice.** No suggested doses, no diagnosis from symptoms, no "you should" text anywhere.
      *Does this diff originate a number or a judgement, rather than transform one the user supplied?*
- [ ] **§12.3 — Never present the app as a compliance or regulatory record.** It is a notebook. Holding numbers, movement reporting and statutory medicine books are out of scope, and the export should say so in its footer.
      *Does this diff produce an artefact a shepherd could hand to an inspector, without the footer that says it is not one?*
- [ ] **§12.4 — Never silently correct a user's entry.** If a birth type of "twin" has three lambs attached, flag it; do not fix it.
      *Does this diff change a value the user entered, on the way in or on the way out?*
- [ ] **§12.5 — Timestamps are honest.** Auto-captured time is labelled as such; edited time is labelled as edited.
      *Does every event time this diff writes or renders carry its provenance?*

## If this diff touches Quick Entry

> **Does the shepherd have to do anything new before the record exists?**

A tap, a wait, a decision, or a thing on screen that was not there before. If yes, it lands
somewhere calmer, in daylight.

## Read the diff in this order — irreversibility, not the order it prints

1. `pubspec.yaml`, `pubspec.lock`, `tool/policy_allowlist.txt`, `android/expected_permissions.txt`, `.fvmrc`
2. `lib/core/db/tables/**`, `drift_schemas/`, `lib/core/db/migrations.dart`
3. `lib/data/**`
4. `lib/domain/withdrawal/`, `lib/domain/stats/`, `lib/domain/time/`
5. `lib/l10n/app_en.arb`
6. `lib/features/**`

**Never waved through, however small:** `lib/domain/withdrawal/**` · `drift_schemas/**` · the
`[exempt]` section of `tool/policy_allowlist.txt` · `lib/domain/policy/disclaimers.dart` ·
`lib/main.dart` · any new export format · any table gaining an edit verb ·
`android/expected_permissions.txt` · a `pubspec.lock` diff in a PR that does not also change
`pubspec.yaml`.

## Gates

- [ ] `gate` green
- [ ] `codegen` green — it is a REQUIRED check, so a stale generated file blocks the merge
- [ ] `test` green
- [ ] `/simplify`, then `/code-review`, were run before every commit on this branch
- [ ] `/shed-code-review` run once over the whole branch, in irreversibility order, before this PR was opened
