# N06 — Domain: statistics, warnings and policy

| | |
|---|---|
| **`00-README` §9 step** | 2 (3 of 3) |
| **Depends on** | N05 |
| **Size** | L |
| **Was** | E05, plus the two `copy.*` gate rows and the authored term content |
| **Branch** | `epic/n06-domain-statistics-warnings-policy` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |

## Goal

Ids, the enums that mirror stored keys, the validators that cannot fix anything, the eight
statistics with their verbatim definitions, terminology, the disclaimers, the free-tier decision, and
the ~40 authored terms the schema will seed from.

## Why the epic sits here

`00-README` §9 step 2 is *"`lib/domain/**` — time, units, withdrawal, warnings, statistics — with
`test/domain/`"*, and its reason is quoted rather than re-derived:

> Pure Dart, zero dependencies, the thickest test tier, and the code most likely to be wrong
> invisibly. It compiles before Flutter is involved, so it is the cheapest place in the project to be
> correct.

Step 2 is cut into three epics because it is three separable bodies of arithmetic: N04 (time and
units), N05 (withdrawal), and this one. N06 is last of the three because every type it writes stands
on N04's `Instant`/`LocalDate`/`Grams` and on N05's `Warning`-shaped precedent — `treatment_checks.dart`
already exists, holding `checkClearDate` from N05-T05.

It comes **before** N07 (the schema and the freeze) for one reason that is not stylistic: this epic
fixes the strings that N07 freezes. `LambingPercentageChoice`'s four `key`s are byte-identical to
`app_settings.percentage_definition`'s `CHECK` list; `Sex`'s three keys, `BirthType`'s codes 1..5,
`FosterOutcome`'s three keys and `AnimalClass`'s seven names are all stored values. Writing them
after `drift_schema_v1.json` exists turns a rename into a migration.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §5.4, §6, §7, §8 | the plausibility band, the eight statistics, the five safety rules as mechanisms, terminology |
| `docs/engineering/CONVENTIONS.md` | §1, §2.1, §2.6, §2.9, §2.10, §2.14, R5 R17 R24 R27 R43 R44 R45 R46 R53 R61 R64 R65 R66 R69 | every file path, type name and stored key in this epic |
| `docs/engineering/11-monetization-and-store.md` | §2, §7.1–§7.4 | `FreeTierPolicy`, `EntryContext`, `isQuietHours`, decision #91 |
| `docs/engineering/03-data-model-and-schema.md` | §5.13, §9.1, §10.1 | the `percentage_definition` CHECK, `rankTagMatches`'s ranking, the six vocabulary lists |
| `docs/engineering/12-testing.md` | §10, §10.4 | which safety rules are gate rows rather than tests, and `checkLambing`'s call shape |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.5, §8.6, §8.7 | the terminology-placeholder rule and the three homes of the forty terms |
| `shed-book-spec.md` | §7.1, §7.8, §11, §12 | partial tag matching, the season summary, the bundled content, the five safety rules |
| `epics/00-PLAN-CRITIQUE.md` | S5, S8, G4 | why `FreeTierPolicy` is here and not in N30, why the two `copy.*` rows are here and not in N03 |

## Tasks

| # | Task | Depends on | One line |
|---|---|---|---|
| 1 | [N06-T01](N06-T01-idsdart-and-the-enums-that-mirror-stored-keys.md) | N05-T05 | `ids.dart` and the enums that mirror stored keys |
| 2 | [N06-T02](N06-T02-warning-the-eleven-warningcode-members-and-reviewed-t.md) | N06-T01 | `Warning`, the eleven `WarningCode` members and `Reviewed<T>` |
| 3 | [N06-T03](N06-T03-the-three-validators-and-kplausiblebirthweight.md) | N06-T02 | The three validators and `kPlausibleBirthWeight` |
| 4 | [N06-T04](N06-T04-statresult-lambcount-flockdenominator-and-seasoncounts.md) | N06-T03 | `StatResult`, `LambCount`, `FlockDenominator` and `SeasonCounts` |
| 5 | [N06-T05](N06-T05-lambing-percentage-average-litter-size-and-barren-rate.md) | N06-T04 | Lambing percentage, average litter size and barren rate |
| 6 | [N06-T06](N06-T06-assisted-rate-losses-by-cause-and-by-age-and-the-lambing-spr.md) | N06-T05 | Assisted rate, losses by cause and by age, and the lambing spread |
| 7 | [N06-T07](N06-T07-ranktagmatches-and-the-pen-timing-functions.md) | N06-T06 | `rankTagMatches` and the pen-timing functions |
| 8 | [N06-T08](N06-T08-terminology-a-closed-enum-under-a-user-editable-overlay.md) | N06-T07 | Terminology — a closed enum under a user-editable overlay |
| 9 | [N06-T09](N06-T09-disclaimers-contentpolicy-exportenvelope-and-the-two-copy-ga.md) | N06-T08 | `Disclaimers`, `ContentPolicy`, `ExportEnvelope` — and the two `copy.*` gate rows |
| 10 | [N06-T10](N06-T10-free-tierdart-the-cap-decision-eleven-epics-before-it-is-wir.md) | N06-T09 | `free_tier.dart` — the cap decision, eleven epics before it is wired |
| 11 | [N06-T11](N06-T11-assetscontent-the-40-authored-terms.md) | N06-T10 | `assets/content/` — the ~40 authored terms |

The chain is linear because each task's red test imports the previous task's type: T02's `Warning`
needs T01's enums to build a message about; T03's validators return T02's `Warning`; T04's
`SeasonCounts` feeds T05 and T06; T09's `ContentPolicy` allowlist is keyed by its own `Disclaimers`
and is what T11's content is then scanned against. Only T07 is genuinely independent of T04–T06 and
may be pulled forward if the branch stalls.

## Demoable on merge

Every statistic computes with its verbatim definition, its caveats and its
`notComputableReason`; `rankTagMatches('12')` ranks 12 → 128 → 412; and the gate now refuses a re-typed
disclaimer.

### Observably true when this merges

Nothing here paints a pixel — the app still has no first frame until N11 — so the demo is a terminal
and a diff. Concretely, on the merged branch:

```bash
fvm flutter test test/domain test/policy        # green, several hundred cases, no Flutter binding
dart tool/check_policy.dart                 # exits 0; the rule table now has copy.vet_advice
                                                # and copy.disclaimer_retyped in it
```

- `lambingPercentage(counts, LambingPercentageChoice.ahdbDefault)` on the toy season in
  `05-domain-correctness.md` §6 returns a `StatResult` whose `definition` reads
  *"lambs born alive per ewe put to the ram"* and whose `numerator`/`denominator` print as `4 / 5` —
  and the same counts under `bornAlivePerEweLambed` return a different number with a different
  definition string, which is the whole point of §6.
- Blank `seasons.ewes_to_ram` returns `notComputableReason`, never `0`, never `—`.
- `rankTagMatches` over a list holding `12`, `128` and `412` and a query of `'12'` returns them in
  that order, in memory, synchronously.
- Plant `'You should give 2 ml/kg of colostrum.'` in any string literal under `lib/` and
  `make check` exits 1 naming `copy.vet_advice`. Re-type the export disclaimer into a second file and
  it exits 1 naming `copy.disclaimer_retyped`. Both were watched to fire in T09's commit.
- `FreeTierPolicy.decide(context: EntryContext.liveEntry, …)` returns `Allow` for all 24 local hours ×
  every ewe count × every season count. The cap cannot speak at 03:20, and it is a property, not a
  promise.
- `grep -rn "package:flutter" lib/domain/` returns nothing, and so does
  `grep -rn "package:clock" lib/domain/`.

## PR workflow, concretely

1. **Cut the branch from the merged `main`.** N05 is merged and green first — `00-PLAN-CRITIQUE` §10:
   *branch from merged `main`, wait for the pipelines, merge, then cut the next branch.*
   ```bash
   git checkout main && git pull --ff-only
   git checkout -b epic/n06-domain-statistics-warnings-policy
   ```
2. **One commit per task**, in the order above, each with the commit line its task file names. No
   task in this epic is one of `00-README` §7.4's four stand-alone exceptions and none of them is a
   schema change, so there is nothing here that may not be split and nothing that must be.
3. **Run the gates locally before every commit** — `make check` then `make test` (`00-README` §8 step
   8). `make check` is cheapest-failure-first: `check_policy` is sub-second, `analyze` is tens of
   seconds.
4. **Push and open the PR.** `.github/pull_request_template.md` (N01-T07) puts the five §12 questions
   in the body verbatim. Three of them have real answers on this branch and must not be waved:
   §12.2 (T09 and T11), §12.3 (T09), §12.4 (T02 and T03).
5. **Wait for the pipelines. Do not merge on a local green.** Two jobs run on this epic, because
   `codegen` lands in N08 and `android` in N31 (`00-PLAN-CRITIQUE` §9 item 4):

   | Job | What it proves for *this* epic |
   |---|---|
   | `gate` | The toolchain pin still matches `.fvmrc`; `pub get` resolves; **`check_policy` exits 0 with the two new `copy.*` rows in the table** — G2 (no new dependency crept in with the content assets) and G3 (no network API); `dart format --set-exit-if-changed`; `analyze --fatal-infos --fatal-warnings`, which with `strict-casts` on is this project's only reviewer of the arithmetic |
   | `test` | `-P ci-fast` with `--test-randomize-ordering-seed random` — randomised order is what catches a statistic that passes only because a previous test left a value behind; `TZ=Europe/London --tags uk-zone` over the **whole** suite, which is where T06's spread cases in the 01:00–01:59 hour run; and `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`, the hostile-zone run at UTC+12:45 that catches any statistic that assumed a whole-hour offset or a same-day UTC/local mapping |

   The hostile-zone run is the one that will surprise you on this branch: it is why every
   zone-agnostic assertion in `test/domain/stats/` must be **relational** ("this list is dense",
   "this elapsed duration is exactly 168 h") and never an absolute wall-clock value.
6. **Review in irreversibility order**, not in diff order (`00-README` §8 step 10):
   `lib/domain/policy/disclaimers.dart` first — it is on the never-waved-through list, however small
   the diff — then `tool/check_policy.dart`, then `lib/domain/stats/`, then everything else.
7. **Merge, then delete the branch.**
   ```bash
   gh pr merge --squash --delete-branch     # or merge in the UI and delete there
   git checkout main && git pull --ff-only
   ```
8. **Confirm `main` is green after the merge**, then cut `epic/n07-the-schema-and-the-freeze` from
   it. Not before: N07 opens with `kSchemaVersion` and the first snapshot, and a snapshot taken on
   top of an unmerged key rename is the one mistake in this build order that cannot be undone.

## Risks, and what is irreversible

**Nothing in this epic writes a schema snapshot, a native file or a published artefact.** There is no
`drift_schemas/*.json` here, no `AndroidManifest.xml`, no store upload. Say that out loud, because it
is the last epic of which it is true — N07 is the freeze.

What is irreversible *in practice*, one epic later:

- 🔒 **Every stored key written here is frozen by N07's `drift_schema_v1.json`.** That is
  `BirthType.code` 1..5, `Sex`'s `('f','m','unknown')`, `FosterOutcome`'s
  `('to_ewe','to_bottle','removed_unknown')`, `AnimalClass`'s seven member names, `LambStatus`'s four
  keys, `LambCount`'s and `FlockDenominator`'s keys, and above all
  **`LambingPercentageChoice`'s four `key` strings, which must be byte-identical to
  `app_settings.percentage_definition`'s `CHECK`** (`03-data-model-and-schema.md` §5.13). Renaming one
  after N07 is a data migration on a column that already holds it.
- 🔒 **The four `LambingPercentageChoice.definition` strings and `Disclaimers.*` are printed into
  CSVs and PDFs that outlive the app** (R61, decision #62). A shepherd's 2027 season file quotes the
  2026 wording. Change one and two seasons no longer compare (§6.11 refuses the delta), which is
  correct behaviour and still a support conversation you cannot have, because there is no support
  channel.
- ⚠️ **The two `copy.*` gate rows change what the build refuses**, for every file, forever. A rule
  that is added and never watched to fire is indistinguishable from a broken rule — N03's discipline
  applies here too, and T09 must plant an offender, watch the failure, and delete it.

Risks specific to this epic:

| Risk | Where it bites | What to do |
|---|---|---|
| `checkLambing(Lambing, List<Lamb>)` as spelled in `05` §7.5 takes **drift row classes**, which `lib/domain/` may not import (layer rule 1, D2) | T03 will not compile as literally specified | Settle it in T03's commit: the domain takes plain records, exactly as `LambOutcome` already does in `05` §6.8. Record the deviation in the commit message |
| `duplicateActiveTag` is one of the eleven `WarningCode` members and **no file in `CONVENTIONS` §1's tree produces it** | T02 declares a code nothing raises | Declare it anyway (the enum is frozen). Do **not** invent `lib/domain/validation/flock_checks.dart`. `07-screens.md` §3.3 computes it in Dart from the tag index on the Flock create path (N26), and `00-README` §10 records the open contradiction with the partial unique index |
| The gate's driver walks `lib/` and `test/` and **only `.dart` files** (`01-architecture.md` §3.2) | T09's `copy.vet_advice` is specified to scan `lib/l10n/*.arb` and `assets/content/`, which it will never open | T09 changes the **driver**, not just the rule table. Two table rows alone are a rule that silently passes |
| `stat.zero_default` (`?? 0`) is scoped to `lib/features/season/` and `lib/features/flock/` only | A `?? 0` inside `lib/domain/stats/` passes the gate | Only T04–T06's tests hold this. Every zero-denominator arm needs a named case |
| Statistic arithmetic is invisible when wrong | Everywhere in T05 and T06 | Every edge case in `05` §6.4–§6.9 gets a **named** test, per that document's own definition of done. The list is thirteen cases long and it is reproduced in T05 and T06 |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

### And, specific to N06

- [ ] `lib/domain/` still imports no `package:flutter`, no `package:drift`, no `package:riverpod`, no `package:intl` and **no `package:clock`** — `layer.domain` proves it
- [ ] every statistic is a pure top-level function returning `StatResult`; none returns a bare `double`
- [ ] `LambingPercentageChoice` has exactly four members and their `definition` strings are pinned literally
- [ ] no validator returns a corrected value; `Warning` has no `fix()`; `Reviewed<T>` has no `cleaned`
- [ ] `Disclaimers.exportFooter` appears as a literal in exactly one file, and the gate now says so
- [ ] `EntryContext.liveEntry` cannot reach `BlockedByCap`, across the whole input grid
- [ ] the six vocabulary lists' forty labels exist, every one of them authored, and `ContentPolicy` passes over all of them

## Notes

**One cross-epic correction to carry forward.** `N07-T07`'s §1 says `seedFirstRun` seeds *"the ~40
authored terms from `assets/content/`"*. Per R66, `10-accessibility-and-i18n.md` §8.6 and
`00-PLAN-CRITIQUE` G4's `[audit]` row, that is backwards: the **keys** are seeded in
`lib/core/db/seed/first_run.dart` with `label = NULL`, the **labels** are ARB messages, and
`assets/content/` holds only prose too long to be a UI string plus one provenance line per list.
N06-T11 lands the labels and the provenance lines; N07-T07 lands the keys and
`test/policy/vocab_labels_are_complete_test.dart`. Fix N07-T07's wording when that branch is cut.
