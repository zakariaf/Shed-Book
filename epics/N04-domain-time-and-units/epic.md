# N04 — Domain: time and units

| | |
|---|---|
| **`00-README` §9 step** | 2 (1 of 3) |
| **Depends on** | N03 |
| **Size** | M |
| **Was** | E03 |
| **Branch** | `epic/n04-domain-time-and-units` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |

## Goal

Pure Dart, zero dependencies, the thickest test tier, and the code most likely to be wrong
invisibly. It compiles before Flutter is involved, which makes it the cheapest place in the project to
be correct.

## Why the epic sits here

`00-README` §9 puts this at **step 2**, immediately after the gate (N01–N03) and immediately
**before** the schema (N07). §9's own reason, quoted rather than re-derived:

> *"Pure Dart, zero dependencies, the thickest test tier, and the code most likely to be wrong
> invisibly. It compiles before Flutter is involved, so it is the cheapest place in the project to be
> correct."*

Two consequences follow that no other ordering gives you:

- **The storage shapes are settled before the freeze.** Decision #29 — instants are `INTEGER` UTC
  epoch millis, civil dates are `TEXT 'YYYY-MM-DD'` — is *"irreversible after the first migration
  snapshot"* (`05` §2.1). N07 takes that snapshot. Every column type in `03-data-model-and-schema.md`
  is downstream of the eight files this epic writes, so the types exist first and the columns are
  authored to match, never the other way round.
- **The gate acquires a legitimate call site to point at.** N03-T06 shipped the `time.dart_clock`
  rule — `DateTime.now(` in exactly one non-generated file under `lib/` — with nothing yet to exempt.
  N04-T05 creates that one file and its one `[exempt]` line, which is what turns the rule from
  theoretical into enforced.

Nothing in this epic imports Flutter, drift or Riverpod. `lib/core/time/app_clock.dart` (N04-T05) is
the single file that imports `package:clock`; `lib/domain/**` may not (D3, R24).

## Observably true when this epic merges

Run these on a tree that still has no `lib/data/`, no `lib/features/` and no database:

```bash
fvm flutter test test/domain                                            # the whole domain tier, green
TZ=Europe/London   fvm flutter test --tags uk-zone                      # DST-1 … DST-4, green
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone  # the same tier, hostile zone, green
dart run tool/check_policy.dart                                         # layer.domain + time.dart_clock enforced
```

What you can demonstrate to somebody standing behind you:

- `1.2 lb` through `Grams.fromPounds` comes back out of `inPounds` as `1.2` at 1 dp — and the same
  loop at the *rejected* 0.1 kg resolution corrupts **132 of 241** entries, printed by a test that
  ships (`05` §5.3).
- `LocalDate.parse('2026-02-30')` throws. `LocalDate.parse('2026-2-3')` throws. Neither clamps.
- A ewe born *"2022"* stays `PartialDate('2022')`. No method on it returns a `LocalDate`, so the
  1-January bug has no call site to occur at.
- `RecordedTime.capture(t).editedTo(a).editedTo(b).editedTo(c)` still reports
  `originalEffective == t` — the *first* value, not the previous one — and `provenanceLabel` is
  non-empty for all three `TimeSource` members with no `default:` arm anywhere.
- A ewe penned 22:00 Sat 28 Mar 2026 and checked 08:00 Sun 29 Mar reads **9 hours**, not 10.
- `grep -rn 'DateTime\.now(' lib/` returns exactly one line, in `lib/core/time/app_clock.dart`.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §1.1–§1.3, §2.1–§2.9, §4, §5, §7.5 | the file map, the four import bans, the time model, `RecordedTime`, the units, `checkLocalWallTimeExists` |
| `docs/engineering/CONVENTIONS.md` | §1, §1.1, §2.2, §2.3, §4.1, §4.7, §5 | the tree, layer rule 1, every type shape and signature, the test-file naming rule, the `[exempt]` block, the vocabulary |
| `docs/research/00-tech-decisions.md` | §2.E (#29, #30, #46, #47, #48, #53, #55, #56, #57), §5.1, §5.2, §7.0 | the storage shapes, one clock, canonical units, `clock 1.1.2`, `glados` struck from §5.2 on 2026-08-01, UK/Ireland first |
| `docs/engineering/12-testing.md` | §1.2, §2.1–§2.5, §11.2, §11.3 | the tiers, `atFixed`, the `uk-zone` tag, the three zone commands, randomised ordering |
| `docs/engineering/00-README.md` | §8 steps 2 and 7, §9 step 2 | the file-touch order, and why this epic is here |
| `epics/00-PLAN-CRITIQUE.md` | the first-failing-test table, the skills-per-epic table | the anchors, and `shed-domain` + `shed-testing` |

## Tasks

| # | Task | Depends on | One line |
|---|---|---|---|
| 1 | [N04-T01](N04-T01-instant-the-extension-type-over-utc-epoch-millis.md) | N03-T07 | `Instant` — the extension type over UTC epoch millis |
| 2 | [N04-T02](N04-T02-localdate-strict-parse-never-widened.md) | N04-T01 | `LocalDate` — strict parse, never widened |
| 3 | [N04-T03](N04-T03-partialdate-a-year-maybe-a-month-never-silently-widened.md) | N04-T02 | `PartialDate` — a year, maybe a month, never silently widened |
| 4 | [N04-T04](N04-T04-recordedtime-and-timesource-provenance-as-part-of-the-value.md) | N04-T03 | `RecordedTime` and `TimeSource` — provenance as part of the value |
| 5 | [N04-T05](N04-T05-appnow-the-one-wall-clock-reader.md) | N04-T04 | `appNow()` — the one wall-clock reader |
| 6 | [N04-T06](N04-T06-grams-weightunit-and-parseusernumber.md) | N04-T05 | `Grams`, `WeightUnit` and `parseUserNumber` |
| 7 | [N04-T07](N04-T07-millicelsius-canonical-integer-temperature.md) | N04-T06 | `MilliCelsius` — canonical integer temperature |
| 8 | [N04-T08](N04-T08-the-uk-zone-test-tier-and-the-ambiguous-hour.md) | N04-T07 | The `uk-zone` test tier and the ambiguous hour |

The chain is strictly linear and it is not arbitrary. `LocalDate.of(Instant)` needs T01; `PartialDate`
is defined by what it refuses to become, so `LocalDate` must exist to be refused; `RecordedTime` holds
three `Instant`s; `appNow()` returns an `Instant`; and T08 is the tier that re-runs everything before
it under a pinned zone, so it is last by construction.

## The pull request, concretely

```bash
git checkout main && git pull            # cut from the merged main, never from N03's branch
git checkout -b epic/n04-domain-time-and-units
```

1. **One commit per task**, message exactly as the task file's header line spells it. Eight tasks,
   eight commits. `00-README` §7.4's split rules apply: the `[exempt]` line N04-T05 adds to
   `tool/policy_allowlist.txt` **carries its reason in that commit message**, because an exemption
   deletes a rule for one file, forever, silently.
2. Before each commit: `/simplify`, then `/code-review`, then `/shed-code-review`. In that order.
3. Before the PR opens, run `/shed-code-review` once more over the **whole branch**, reading in
   `00-README` §10's irreversibility order. For this branch that order is
   `tool/policy_allowlist.txt` → `lib/domain/time/` → `lib/domain/units/` → `lib/core/time/` →
   `test/`.
4. `gh pr create --base main --title 'N04 — Domain: time and units'`, and answer the five §12
   questions from `.github/pull_request_template.md` **in the PR body**, not in a comment.
5. **Wait for the pipelines.** Two jobs run on this PR — `codegen` and `android` do not exist yet
   (N08 and N31 create them):

   | Job | What it runs on this branch | What it proves |
   |---|---|---|
   | `gate` | toolchain pin agrees with `.fvmrc` (Flutter 3.44.8) · `flutter pub get` · `dart run tool/check_policy.dart` · `dart format --set-exit-if-changed` · `flutter analyze --fatal-infos --fatal-warnings` · no `NSAppTransportSecurity` | `layer.domain`: nothing under `lib/domain/` imports `package:flutter`, `package:drift`, `package:*riverpod`, `package:intl` or **`package:clock`**. `time.dart_clock`: `DateTime.now(` in exactly one non-generated file. `time.sql_now_*`: no SQL-side time token. `copy.banned_word`: no `draft`, `save()`, `sync`, `flags` or `Error`-as-a-failure-name in the diff |
   | `test` | `libsqlite3-dev` on the runner · `flutter test --exclude-tags golden --test-randomize-ordering-seed random --coverage` · `TZ=Europe/London flutter test --tags uk-zone` (**unscoped** — no path) · `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` · coverage uploaded as an artefact, never gated | The arithmetic under the target zone, and the same arithmetic under a hostile UTC+12:45 zone with its own DST. Green in only one of the two means something is reading ambient local time that should not be (`12` §2.5) |

   `gh pr checks --watch`. Do not merge on a yellow.
6. **Merge.** Squash is wrong here: the eight commits are the record of what was decided in what
   order, and three of them are one-way doors. Merge commit, or rebase-merge preserving all eight.
7. `git push origin --delete epic/n04-domain-time-and-units && git branch -d epic/n04-domain-time-and-units`.
8. Confirm `main` is green after the merge, **then** cut `epic/n05-domain-withdrawal` from the merged
   `main`. N05-T02's first failing test consumes `Instant`, `LocalDate` and the `uk-zone` tier from
   this branch; cutting early buys a conflict in `test/domain/uk_zone/`.

## Irreversible — say it out loud

Nothing in this epic writes a schema snapshot, a native file or a store artefact. Three things are
still one-way doors, and two of them are one-way *because of what happens three epics later*.

- **`TimeSource`'s three keys — `'auto'`, `'entered'`, `'edited'` — are frozen forever.** They are
  written into SQLite, into every CSV `time_source` column and into every JSON backup, and a backup
  written by v1.0 is restored by v1.9 (`04`). Changing one key breaks every export ever written by
  every install. `05` §4.4 pins them with a literal-list test for exactly that reason; that test is
  not decoration.
- **`WeightUnit`'s keys `'kg'` and `'lb'` must be byte-identical to `app_settings.weight_unit`'s
  `CHECK`** (R68). That column does not exist yet — N07 writes it — so this epic *sets* the
  constraint N07 must match. Get it wrong here and the mismatch surfaces as a `CHECK` failure on a
  real phone, not as a compile error.
- **The canonical units and the storage shapes become a migration the moment N07 freezes.** Integer
  grams, integer milli-°C, `INTEGER` epoch millis, `TEXT 'YYYY-MM-DD'`, `TEXT` partial dates.
  `05` §2.1 states the deadline plainly: decision #29 is *"irreversible after the first migration
  snapshot"*. There is no `unit` column on any measurement and there must never be one (`05` §5.1).

One further item is reversible but expensive: the `[exempt]` line in `tool/policy_allowlist.txt`.
R56 fixes the day-one count at **exactly four**; N04-T05 adds the first
(`lib/core/time/app_clock.dart :: time.dart_clock`). A fifth line is a review conversation, not a
convenience.

## Risks specific to this epic

| Risk | Why it bites here | What to do |
|---|---|---|
| **`extension type const LocalDate._(String iso)` may not compile** | The private-representation-constructor spelling is the mechanism that forces construction through the validating factories. `05` §2.4 flags it as **not compiled by the research corpus** and asks for a first-commit check | Run `dart analyze lib/domain/time/local_date.dart` inside N04-T02. If the SDK rejects it, fall back to a public representation constructor and keep **both factories exactly as written** — never weaken `LocalDate.parse` to recover the guard |
| **`Warning` and `WarningCode` do not exist yet** | `checkLocalWallTimeExists` returns `List<Warning>` (CONVENTIONS §2.2), but `lib/domain/validation/warning.dart` is **N06-T02**, two epics later | N04-T05 creates `warning.dart` carrying `Warning` and the single member `WarningCode.timeDoesNotExistLocally`; N06-T02 extends the enum to its eleven. Adding an enum member is additive. Inventing a second warning type is not — see N04-T05 §5.3 |
| **DST-5 cannot be written in this epic** | It asserts on `computeWithdrawalStatus`, which is **N05-T03** | N04-T08 ships DST-1 … DST-4; DST-5 lands with N05-T02 in `test/domain/uk_zone/clear_date_dst_test.dart`. Do not hand-inline a ceil-to-midnight to make five appear — a test that reimplements the function under test proves nothing |
| **A green suite in the wrong timezone** | `test/domain/uk_zone/` is the only tier whose correctness depends on the *process* environment. Under UTC on `ubuntu-latest`, a spring-forward test passes because there is no spring forward | The `setUpAll` offset assertion in every `uk-zone` file, plus the two CI properties `12` §2.5 states: the target-zone step is **unscoped**, and the hostile-zone step carries **`--exclude-tags uk-zone`**. Both are one word wide and both regress silently into green |
| **Extension types erase at runtime** | `Instant`, `Grams`, `MilliCelsius` and every id in `ids.dart` are all `int` at runtime. `is`, a `switch` on runtime type and `identical` cannot tell a moment from a mass | Never build an extension type for a display value (`Pounds` and `Fahrenheit` are banned type names), and never write a runtime type test over one. `05` §2.3, §5.2 |
| ~~**`glados` sits next to the constraint that governs the whole toolchain**~~ **Closed 2026-08-01: it reddened and is struck** | N00-T03 ran decision #5's resolution — the first time anybody had — and `glados` was the one row of §5.2 that did not resolve. It depends on `package:test`, the very edge decision #4 already bans; `glados: any` reports *"glados is incompatible with drift_dev 2.34.5"* | The stated rule was applied: **the property layer was deleted, not the pin** (`12` §10.6). The table-driven loops in `05` §5.3 are now the whole of the pure-value tier, not the floor beneath an additive one |
| **Three tests here are the executable form of an argument, not of a behaviour** | The 132-of-241 corruption loop, the frozen-key list, DST-4's literal 167 — all three read as deletable to a reviewer who does not know why they exist | Each carries a one-line `reason:` naming the decision it holds. Deleting one is deleting decision #56, #53 or #49 |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `lib/domain/` imports nothing beyond `dart:*`, `package:meta` and `package:collection` — `layer.domain` proves it, not review
- [ ] `DateTime.now(` appears in exactly one non-generated file under `lib/`, and `tool/policy_allowlist.txt`'s `[exempt]` section holds exactly that one line (the first of R56's four)
- [ ] all three zone commands in `12` §2.5 pass locally before the PR opens

## Demoable on merge

A pure-Dart suite runs green — including DST-1…DST-5 against the 01:00–01:59 ambiguous hour —
with no Flutter, no drift and no Riverpod anywhere in the import graph.
