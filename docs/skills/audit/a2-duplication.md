# A2 — Duplication and staleness audit of the 24 built skills

**Lens:** the doc set (`docs/engineering/`, 22,694 lines) and `docs/research/00-tech-decisions.md` are
BINDING and outrank every skill. A skill that *transcribes* them creates a second authority that goes
stale silently — its only two possible states are "identical" and "wrong", and it can never win.

**Audited:** all 24 `SKILL.md` files, all 9 `references/`, all 6 `examples/`, 1 `scripts/`, against
`docs/engineering/CONVENTIONS.md`, `docs/research/00-tech-decisions.md`,
`docs/skills/01-catalogue-critique.md` §7 and `docs/skills/02-build-manifest.md` §3 (the house rule)
and §4 (the owner rulings).

**The house rule being enforced** (manifest §3, from critique §7):

> No skill restates a name, a signature, a column spelling, a stored key, a version number or a
> verbatim user-facing string. It states the rule, cites the owning document and ruling number, and
> names the file where the value lives. A skill that would go stale when a doc changes is written wrong.

**Verdict in one line:** the set was already citation-heavy and largely obeys its own house rule — but
it broke it in **21 places**, one of which (the statistics `definition` string) is a correctness
defect rather than a maintenance one. All 21 are fixed. Four residual risks are accepted and named.

---

## Contents

- [1. Transcriptions found and replaced with citations](#1-transcriptions-found-and-replaced-with-citations)
- [2. One rule, two skills, different words](#2-one-rule-two-skills-different-words)
- [3. Contradictions](#3-contradictions)
- [4. Supporting files, load conditions, depth, TOCs](#4-supporting-files-load-conditions-depth-tocs)
- [5. `examples/` that shadow a file destined for `lib/`](#5-examples-that-shadow-a-file-destined-for-lib)
- [6. Accepted risks — found, not fixed, and why](#6-accepted-risks--found-not-fixed-and-why)
- [7. Full list of files changed](#7-full-list-of-files-changed)

---

## 1. Transcriptions found and replaced with citations

### 1.1 The statistics `definition` string — the one correctness defect

**This is the finding the critique predicted and it had already happened, twice.** R61 pins four
`definition` strings literally because they are printed into CSVs and PDFs that outlive the app, and
two `StatResult`s may only be compared when their strings are **identical**. A second spelling makes
two identical seasons refuse to compare.

| File | Was | Now |
|---|---|---|
| `shed-domain/SKILL.md` §7 | *"the default percentage convention is AHDB — lambs born **alive**, per ewe put to the ram"* | names the choice, cites R61, names `lib/domain/stats/definitions.dart` as the only source |
| `shed-domain/references/statistics.md` § Lambing percentage | *"Default is AHDB — lambs born alive per ewe put to the ram"* | same |

Both were verbatim or near-verbatim reproductions of R61's string #1
(`lambs born alive per ewe put to the ram`). `statistics.md`'s **own standing rule at the top of the
file** forbids exactly this — *"never quoted, retyped, paraphrased or reworded anywhere else … not in
a screen, a test expectation, a comment, a doc, **or this file**"* — so the file contradicted itself
75 lines later. The manifest's E7 brief is equally explicit: the skill *"copies none of them."*

Neither copy would have failed a gate. `check_policy` cannot see a doc, and a screen built from the
skill's wording rather than the constant would have produced a PDF whose definition line differs from
the CSV's by one word.

### 1.2 The provider catalogue (CONVENTIONS §3)

`shed-riverpod-providers` §3 said *"the closed catalogue … is `CONVENTIONS.md` §3.1–§3.4. Look yours
up there first"* and then printed **eight banned spellings** and an enumeration of which providers are
`keepAlive`. That is a second catalogue sitting directly under the sentence telling you to read the
first one.

Fixed: the skill now states the *policy by kind* (what class of provider is kept alive and why) and
sends every name — including the banned spellings — to §3.2–§3.4, with an explicit "never copy a row
of §3 into a skill, a comment or a PR description."

`shed-screens-and-routing` §2 carried a third fragment (`lambingControllerProvider` is banned, and its
two legal spellings). Replaced with a citation. `shed-conventions` was already correct — it points at
§3.2–§3.4 and prints no rows.

### 1.3 Version numbers outside `shed-dependencies-and-toolchain`

Decision-record §5 is *"the only source of a version number in this project"*, and five skills said so
while printing one anyway:

| Skill | Transcribed | Now |
|---|---|---|
| `shed-export-and-restore` | `pdf` 3.13.0, `share_plus` 13.3.0, `archive` 4.0.9 (header **and** body) | cites §5.1, names the owning skill |
| `shed-migrations` | `drift` 2.34.2 / `drift_dev` 2.34.5 | cites §5 |
| `shed-testing` | Flutter 3.44.8, `mocktail: 1.0.5` | cites `.fvmrc` / §5.2 |
| `shed-release` | Flutter 3.44.8 / Dart 3.12.2 | cites `.fvmrc`, whose value is §5's |
| `shed-goldens-rebaseline` | Flutter 3.44.8 (×2, one a precondition) | "reports exactly the string in `.fvmrc`" |
| `shed-monetization` | `in_app_purchase_storekit ≥ 0.4.8`, plugin 0.4.3 | cites 11 §1.1 + §5.1 |
| `shed-accessibility-and-copy` | `intl: any`, `flutter_localizations` pins `0.20.2` | cites the pin's owner |

The `shed-goldens-rebaseline` one mattered most: a runbook precondition that says "confirm the tool
reports 3.44.8" keeps passing after the pin moves and re-baselines eight PNGs against a version the
macOS runner then rejects.

`shed-riverpod-providers`' `2.6.1` is **kept** — the manifest's E4 brief assigns that skill "the 2.6.1
pin" and it is the skill's subject, not a borrowed fact. `shed-dependencies-and-toolchain` keeps every
pin it prints; it is the owner.

### 1.4 The column-naming table (R37 / R38)

`shed-drift-schema` § The provenance quad printed all four column spellings and both CHECK
expressions, then said *"never retype a spelling from memory."* R37/R38 exist specifically to close a
stale-claim sweep in which `original_effective_at` had to be deleted from three documents; a skill
carrying the spelling is one edit from reintroducing it.

Fixed in three places: `shed-drift-schema` (spellings → R37/R38, table list and CHECK text → 03 §4.2),
`shed-write-path` step 2 (four field names → R37/R38), `shed-safety-rules` §12.5 (quad shape → 05 §4 +
R37/R38). `shed-domain` §4 **keeps** the field names — the manifest assigns it `RecordedTime` and the
semantics are unstatable without them; it already cites §2.2 for the shape.

`shed-drift-schema` also printed the four `@DataClassName` row-class names; now cites R20 +
`lib/data/models.dart`.

### 1.5 The plugin-confinement catalogue

`shed-platform-gateways` reproduced 08 §1.2's nine-row `_confinedPackages` table plus the tenth row
from `CODE-REVIEW-CHECKLIST §1.13` — a ten-row package→path map that already exists in a document
*and* in `tool/check_policy.dart`. Three copies of a map means a seam can move in two of them.

Replaced with a citation naming both real locations, plus the four rows an agent gets wrong from
memory (`path_provider`'s two sites, `file_selector`'s non-gateway location, `timezone`'s confinement,
`in_app_purchase` under R74). The gotchas survive; the catalogue does not.

Same skill: the seven declared Android permissions were listed inline while `shed-release` — which
owns the gate — says *"Read the table in §3.1; do not retype it."* Now both cite. The count trap
(eight entries, seven lines, `INTERNET` asserted by absence) is kept in both, because it is the thing
that causes somebody to add a ninth line.

### 1.6 Screen-brief content

The twelve briefs themselves were **already cited correctly** by `shed-screens-and-routing` §2
(`07 §3` Flock · `§4` Ewe Card · …) — the critique's §10 correction had been applied. Two brief-level
transcriptions remained:

- **The export prompt's six conditions** (07 §16.2) were enumerated in full. `indelible-states-and-feedback`
  §6 had already found the right shape — *"All six conditions must hold. The two most often dropped
  are …"* — so `shed-screens-and-routing` now matches it.
- **The overflow-matrix arithmetic** (`14 → 252`, `15 → 270`) appeared in both `shed-screens-and-routing`
  step 7 and `shed-testing`, in a skill whose own sentence says *"Derive it from the variant list;
  never carry a remembered number."* `shed-testing` owns R58 and the single place the count is
  written down; screens now points there.

---

## 2. One rule, two skills, different words

Ownership was decided by the manifest where it is explicit, and otherwise by scope. In every row the
owner keeps the full statement with its mechanism; the other side keeps **one line naming the
consequence it owns** and a pointer. No rule was deleted from both sides.

| # | Rule | Owner (and why) | Was also fully stated by | Fix |
|---|---|---|---|---|
| 1 | `WriteCommitted.warnings` is the controller's, never a repository's (**R53**) | `shed-riverpod-providers` — manifest E4: *"stated here only; `shed-write-path` points at it"* | `shed-write-path`, `shed-safety-rules`, `shed-domain` | all three now point; write-path keeps the *import ban* (its own), safety-rules keeps the *ladder level* (its own) |
| 2 | `combineLatest` over drift streams is a build-breaking defect (drift#3338) | `shed-riverpod-providers` — manifest E4 owns it verbatim | `shed-write-path`, `shed-screens-and-routing`, `statistics.md` | three pointers; each keeps its own consequence (fan-in in SQL / one content statement / a torn Season Summary) |
| 3 | Ruling **P2** — there is no SnackBar; the receipt is the committed row | `indelible-states-and-feedback` (what is seen) + `shed-screens-and-routing` (the window) + `indelible-marks-and-strikes` (the strike) — manifest §4.1 | `shed-riverpod-providers`, `shed-write-path`, `shed-accessibility-and-copy` each restated *what the receipt is* | the **ban** stays everywhere (it overrides a BINDING doc and cannot be progressive-disclosed); the **description of the receipt** now exists only in the design skills |
| 4 | Ruling **P8** — no birth-type chooser | `indelible-marks-and-strikes` §4 + `indelible-controls` — manifest §4.2 | `shed-screens-and-routing`, `shed-safety-rules`, `shed-accessibility-and-copy` restated the `ShedChoiceRow` carve-out | carve-out removed from all three; each keeps only its own consequence (the 6th tap is a stroke / §12.4 becomes structural / there is no control to label) |
| 5 | The three strings that fail the stamp-size exemption | `indelible-design-system` (the test and the sizes) — manifest §4.4 defect 2 | `shed-accessibility-and-copy`, `shed-testing` | both point; accessibility keeps "must also be spoken", testing keeps "assert the outcome" |
| 6 | Never store a time-relative value | `shed-drift-schema` — manifest E7 owns it | `shed-riverpod-providers` §8 | riverpod keeps the **render** half (ticker, `now` as a parameter) and points for the **storage** half |
| 7 | Target sizes and separation | `indelible-page-and-screens` (the 64 floor, the audit, P9) | `shed-accessibility-and-copy` §6 printed `60 / 72 / 88 / 16` | accessibility now points; see contradiction C2 |
| 8 | Rule weights (2 px, never 1 px) | `indelible-marks-and-strikes` §5 — manifest D5 owns "the 2px rule, the 3px strike weight" | `indelible-page-and-screens` §3 | page-and-screens points |
| 9 | Behaviour at 200% text scale | `indelible-page-and-screens` §7 (it is a layout fact) | `indelible-design-system` | design-system keeps the **type** half (never clamp) and points for per-element behaviour |
| 10 | The bottom sheet's three permissive Flutter defaults + its close control | `indelible-controls` | `shed-screens-and-routing` §8 | screens points; see contradiction C1 |

---

## 3. Contradictions

Three, all now stated rather than silently resolved.

**C1 — the bottom sheet's close control.** `shed-screens-and-routing` §8 specified *"an explicit 72 pt
Cancel"* (07 §20); `indelible-controls` specifies an **88 × 64 `CLOSE` word button, top-right**
(indelible §7.14). These are different controls at different sizes. Per manifest §4.3 the design
system of record wins on design. Fixed: `shed-screens-and-routing` now names both, says the design
system wins, and hands the control to `indelible-controls`.

**C2 — the target floor and the gap.** Three numbers were in circulation: the executable gate asserts
**60 × 60** (`shed-testing`), `shed-accessibility-and-copy` printed *"60 floor / 72 primary / 88 hero
/ 16 gap"* from 06 §6, and Indelible builds to **64 × 64** with the separation figure **open as P9**
(8–12 px vs the asserted 16). Only `indelible-page-and-screens` reconciled them (*"the spec floor is
60, so 4 pt of headroom is all you have"*) and only it records P9. Fixed: `shed-accessibility-and-copy`
and `shed-screens-and-routing` now point there, and `shed-screens-and-routing`'s bare *"16 pt gap"* —
which quoted one side of an open conflict as settled — now names P9 as open.

**C3 — `statistics.md` versus its own standing rule.** Recorded at §1.1 above. Fixed.

Checked and **not** contradictions, though they read like one: `shed-domain` overruling
`01-architecture.md` layer rule 1 on `package:clock` (it cites R24, and CONVENTIONS outranks 01);
`shed-bootstrap-and-errors` overruling a `CONVENTIONS §2.14` table cell (it cites R23, a later ruling
in the same file, and instructs the reader to flag the cell rather than follow it); every "supersedes"
sentence attached to P2 or P8 (both are owner rulings recorded in manifest §4).

---

## 4. Supporting files, load conditions, depth, TOCs

All four checks **pass**; nothing needed fixing.

- **Every supporting file is named in its `SKILL.md` with a load condition.** 16/16 — nine
  `references/`, six `examples/`, one `scripts/`. Every one is phrased *"read X **when/before** Y"*,
  not "see also". `contrast.py` additionally carries the required execute-or-read instruction
  (*"execute it, do not read it"*), which research 02 §4.3 names as a documented ambiguity failure.
- **Reference links are one level deep.** No `references/` or `examples/` file links to another
  bundled file; the only in-file links are anchors into their own TOC. Zero nesting traps.
- **Every reference over 100 lines has a table of contents.** All six qualifying files carry one:
  `gate-failures.md` (222), `notifications.md` (218), `storage-decisions.md` (155),
  `restore-and-sweeps.md` (153), `statistics.md` (134), `harness.md` (131), `semantics-recipes.md`
  (118). The two under 100 (`pre-release-checklist.md` 87, `riverpod3-symptoms.md` 52) correctly do not.
- **Every reference opens by naming the document it defers to**, which is the load-bearing habit: e.g.
  `notifications.md` — *"the class surfaces are printed there (§2.3, §2.4) — copy the signatures from
  that file, not from memory."*

---

## 5. `examples/` that shadow a file destined for `lib/`

Six example files. **Five shadow a real file; one does not.**

| File | Destination | Verdict |
|---|---|---|
| `shed-bootstrap-and-errors/examples/main.dart` | `lib/main.dart` | **Shadows.** Header already says *"Reference copy of `lib/main.dart`"* |
| `shed-withdrawal/examples/clear_date.dart` | `lib/domain/withdrawal/clear_date.dart` | **Shadows.** Was the only one with a precedence clause |
| `shed-withdrawal/examples/clear_date_dst_test.dart` | `test/domain/uk_zone/dst_test.dart` | **Shadows** a test file |
| `shed-write-path/examples/foster_verb.dart` | `lib/data/foster_repository.dart` | **Shadows.** Header says *"Copy the SHAPE, not the file"* |
| `shed-migrations/examples/migration_step.dart` | `lib/core/db/migrations.dart` | **Shadows.** Header says *"EXCERPT … Do not copy this file into the tree"* |
| `shed-export-and-restore/examples/lambs.csv` | — | **Clean.** An expected-output artefact, which is what Claude Code's own docs describe `examples/` as being for |

The critique's ruling was *"replace each with a named path, not a copy."* I did **not** delete the
four Dart examples, and that is a judgement call to review:

- Each already names its destination path in its first three lines, so none is anonymous.
- Two carry information the real file **structurally cannot**: `main.dart`'s per-line annotations
  cannot live in `lib/main.dart` because the `main.no_await` gate is a substring match and the word in
  a comment fails the build; `clear_date_dst_test.dart` is a test that does not exist yet.
- The critique's own target was the *seven design-system component copies* (`text_theme.dart`,
  `ruled_row.dart`, `shed_keypad.dart`, …), and **none of those was built** — the design skills ship
  zero `examples/`. That instruction was already honoured where it bit hardest.

**Fix applied instead:** every one of the four now carries an explicit precedence clause in the
`SKILL.md` load condition — *"`lib/<path>` is authoritative the moment it exists"* — matching the
clause `shed-withdrawal` already had. The example can no longer become the second authority; it can
only be a teaching copy that loses.

**Residual risk, stated plainly:** four Dart files in `.claude/skills/` will drift from `lib/` once
`lib/` exists, and a precedence sentence is a weaker mechanism than deletion. The right closing move
is a `tool/lint_skills.py` rule — the critique already proposes one for path existence — extended to
fail when an `examples/*.dart` names a destination path that now exists. That is a tool change, not a
skill edit, so it is out of this audit's scope and is recorded here as the follow-up.

---

## 6. Accepted risks — found, not fixed, and why

**R1 — the Indelible palette table (11 hex values + measured contrast ratios).**
`indelible-design-system` reproduces `indelible.md` §2.2–§2.5. This is a transcription by the letter of
the house rule. Not cut, because: the design skills carry no `paths:` and must fire *before*
`lib/core/ui/primitives.dart` exists (manifest §3), the manifest's D1/D2 briefs assign the surfaces and
inks to this skill, and the measured ratios are the entire argument for Rule 4 (*"the floor is
measurement, not taste"*). **Mitigation applied:** a precedence paragraph now states that
`indelible.md` is the source, `primitives.dart` is authoritative once it exists, and *"if the table
disagrees with either, the table is the thing that is wrong."*

**R2 — the twelve-token type scale** in the same skill. Same reasoning; manifest D3 explicitly assigns
"the full scale" to a design skill. Left as-is, covered by the same precedence paragraph.

**R3 — `pt` versus `px` used interchangeably across skills.** `shed-accessibility-and-copy` writes
"18 pt floor" and "60 pt target"; the Indelible skills write "18 px floor" and "64 × 64". Research 02
§6.5 names inconsistent terminology as a real adherence cost. Not fixed: picking one unit is an owner
decision (the design source is CSS px, the Flutter/WCAG surface is logical pt) and a blind rewrite
would create a fourth number. **Recommend an owner ruling**, then one pass across all 24 skills.

**R4 — the layer-rule table** in `shed-conventions` (8 rules + 2 path-pair bans). A transcription of
CONVENTIONS §1.1 — but the critique's corrected catalogue §10.1 **explicitly assigns it**: *"The tree;
the eight layer rules + two path-pair bans as one table; naming shapes; banned words."* Kept by
instruction, not by oversight.

---

## 7. Full list of files changed

**Skills (14 `SKILL.md`, 1 reference):**

```
.claude/skills/shed-domain/SKILL.md                            §7 definition string → R61 citation; §6 R53 → pointer
.claude/skills/shed-domain/references/statistics.md            definition string → citation; combineLatest → pointer
.claude/skills/shed-riverpod-providers/SKILL.md                §3 provider catalogue → citation; §8 storage half → pointer;
                                                               §9 receipt → pointer; DoD reworded
.claude/skills/shed-write-path/SKILL.md                        R53 → pointer; combineLatest → pointer; P2 → pointer;
                                                               quad spellings → R37/R38; example precedence clause
.claude/skills/shed-drift-schema/SKILL.md                      quad spellings → R37/R38 + 03 §4.2; @DataClassName → R20
.claude/skills/shed-safety-rules/SKILL.md                      R53 → pointer; P8 carve-out → pointer; 18px → pointer;
                                                               quad shape → 05 §4
.claude/skills/shed-screens-and-routing/SKILL.md               P2 + P8 → pointers; combineLatest → pointer; banned
                                                               provider spelling → citation; export-prompt six
                                                               conditions → citation; matrix count → shed-testing;
                                                               sheet close control → indelible-controls (C1);
                                                               "16 pt gap" → P9 open (C2)
.claude/skills/shed-accessibility-and-copy/SKILL.md            intl pin → citation; P2 preamble → pointer; 18px →
                                                               pointer; target numbers → pointer; P8 carve-out →
                                                               pointer; §10 definition string → file path; DoD
.claude/skills/shed-platform-gateways/SKILL.md                 _confinedPackages 10-row table → citation + 4 gotchas;
                                                               permission list → 13 §3.1; DoD
.claude/skills/shed-export-and-restore/SKILL.md                pdf/share_plus/archive versions → §5.1
.claude/skills/shed-migrations/SKILL.md                        drift pins → §5; example precedence clause
.claude/skills/shed-testing/SKILL.md                           Flutter + mocktail versions → citations; 18px → pointer
.claude/skills/shed-release/SKILL.md                           Flutter/Dart version → .fvmrc
.claude/skills/shed-goldens-rebaseline/SKILL.md                Flutter version → .fvmrc (precondition + DoD)
.claude/skills/shed-monetization/SKILL.md                      storekit floor + 0.4.3 → 11 §1.1 / §5.1
.claude/skills/shed-bootstrap-and-errors/SKILL.md              example precedence clause
.claude/skills/indelible-design-system/SKILL.md                palette precedence paragraph; 200% → page-and-screens
.claude/skills/indelible-page-and-screens/SKILL.md             rule weight → marks-and-strikes
```

Nothing was deleted from all owners. Every removed sentence was replaced by a citation naming the
document, the section and — where one exists — the ruling number.

**Not changed and deliberately so:** `shed-conventions` (already the cleanest skill in the set — it
carries the tree, the layer rules and the naming table, and cites §2/§3 by ruling number without
printing a row), `shed-code-review` (a routing skill; every line already names the checklist section it
routes to), `shed-withdrawal` (already carried the only precedence clause in the set),
`indelible-controls`, `indelible-marks-and-strikes`, `indelible-states-and-feedback` (all three are
owners of what they state and were already pointing outward correctly).

---

## Verdict

**The set was built to the house rule and broke it in 21 places, one of which mattered.**

The one that mattered is the statistics `definition` string: R61 pins four strings because they are
printed into artefacts that outlive the app, `shed-domain` and its reference both carried a copy of
the first one, and `statistics.md` did it 75 lines below its own standing rule forbidding it. No gate
could have caught it, and the failure mode — two seasons refusing to compare, or a PDF and a CSV
disagreeing by one word — is silent and permanent.

The rest were maintenance hazards of the ordinary kind: a provider catalogue printed directly beneath
the sentence telling you to read the real one, seven version numbers in six skills that all cite
"§5 is the only source of a version number", a ten-row plugin map existing in three places, and the
provenance quad's column spellings retyped in the three skills most likely to write them — against
rulings that exist *because* those spellings were wrong once already.

The cross-skill duplication was smaller than the critique feared and mostly well-managed: P2 and P8
appear in nine skills each, which is correct, because you cannot progressive-disclose a surprise — the
defect was that seven of them restated the *whole* ruling rather than the consequence they own.

What is **not** fixed and should not be read as fixed: the palette and type scale in
`indelible-design-system` are still transcriptions, protected only by a precedence paragraph; four
`examples/*.dart` still shadow files destined for `lib/`, protected only by a precedence clause, and
closing that properly needs a `lint_skills.py` rule rather than an edit; and `pt`/`px` is still used
inconsistently across the set pending an owner ruling.
