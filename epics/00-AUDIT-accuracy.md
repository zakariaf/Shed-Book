# Audit — technical accuracy and skill validity

**Scope.** Every file under `epics/`, verified line by line against `docs/engineering/CONVENTIONS.md`,
`docs/research/00-tech-decisions.md`, `docs/design/indelible.md`, `CLAUDE.md`, and — where those four
delegate — `docs/engineering/{06,07,08,09,12,13}` and `docs/skills/02-build-manifest.md`.

**Method.** Not a read-through. Every backticked token in both files (698 distinct) was extracted and
matched against the full doc corpus; the 146 that did not match verbatim were run down individually.
The 24 skill names were checked against `.claude/skills/` on disk, and every `SKILL.md` frontmatter was
read to confirm which four carry `disable-model-invocation: true`. Every command was checked against
the `Makefile` in `13` §1.3 and the CI job table in `13` §4.2.

---

## 1. The finding that outranks the rest

**There are no epic files and no task files.** `epics/` contains `00-PLAN.md`,
`00-PLAN-CRITIQUE.md`, `00-AUDIT-template.md` and this file. The brief describes "the completed
epic/task backlog" and asks for every `epic.md` and task file to be read; **227 of them were specified
and none was written.**

This is not a technicality. Six of the seven checks in this lens — skill names, runbook usage,
Riverpod APIs, safety-rule instructions, Indelible purity, Verification-block commands — are
properties of *task files*. What exists is a **plan and its critique**: a 227-row index and a
corrected 35-epic re-cut. Both were audited in full and are the subject of everything below. The
verdict in §5 is scoped accordingly: **what exists is accurate after these fixes; most of the backlog
does not exist to be inaccurate.**

---

## 2. What passed

These were checked adversarially and are correct. They are listed so they are not re-litigated.

| Check | Result |
|---|---|
| **Skill names** | **Clean.** No invented skill name appears anywhere in either file. `.claude/skills/` holds exactly 24 directories and every name referenced matches one of them: `shed-drift-schema`, `shed-export-and-restore`, `shed-testing` in `00-PLAN`'s prose; §11.4's full per-epic mapping in the critique |
| **Runbook usage** | **Clean.** Exactly four skills carry `disable-model-invocation: true` on disk — `shed-migrations`, `shed-release`, `shed-goldens-rebaseline`, `shed-code-review` — and all four are referenced with "by name" / "invoked by name". No task relies on one auto-firing. `shed-release` on the G0 epic is *right*: its description is the only one that names "the offline gates G0 to G5 against a real release bundle" |
| **`/shed-code-review`** | Already corrected in `00-PLAN` §1 by the parallel structural pass; the critique §5 and §10 mandate it. No `/code-review` instruction survives outside the two places that name it to ban it |
| **Riverpod** | **Clean.** No Riverpod-3 API anywhere. Only `.select`, `autoDispose`, `family`, `ConsumerStatefulWidget`, `ref.watch`, `AsyncValue` appear — all 2.6.1. `StateProvider` and `AsyncValue.valueOrNull`, banned by decision-record §5.1, appear nowhere. The pin is written `flutter_riverpod: 2.6.1` with "pinned exactly" |
| **Version numbers** | Every one traced to decision-record §5: Flutter 3.44.8 / Dart 3.12.2, `flutter_riverpod` 2.6.1, `flutter_lints` 6.0.0, Play Billing 8.0.0, `accessibility_tools` 2.8.0. No number invented, none copied from a README |
| **Safety rules and owner rulings** | No defaulted withdrawal, no veterinary advice, no auto-correction, no provenance-free timestamp, no tag OCR, no voice *tag* entry (the voice *note* is correctly kept), no global tag uniqueness (E06-T03 is explicitly "the **active-only** partial unique index"), no mid-entry or 22:00–06:00 upgrade prompt. `showSnackBar(` appears only in the three places that ban it. Birth type is derived and labelled `(COUNTED)`; `ShedChoiceRow` survives for lambing ease 1–5 only |
| **Indelible purity** | No element of The Register or Strip Bay. The grafted *persistent loaded subject* is honoured and the 6 px hours bar — the one thing `02-build-manifest.md` §4.3 says must **not** come with it — is absent |
| **Commands** | All thirteen exist: `make gen` · `make check` · `make integration` · `dart tool/check_policy.dart` · `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` (verbatim from `03` §checklist) · `dart run build_runner build` · `flutter create` · `flutter build appbundle --release` · `git diff --exit-code` · `git tag v1.0.0` · `bundletool dump manifest` · `fvm flutter --version` · `python3 tool/validate_skills.py`. No invented command |
| **Arithmetic** | 252 = 14 × 3 × 3 × 2 ✓ (R58). 11 `WarningCode` members ✓. 23 tables, 21 restorable ✓. 13 `RouteNames`, 12 push helpers ✓. Six palettes ✓. Five pen-tile statuses ✓ (R36). Seven pragmas ✓ (R13). Four `[exempt]` lines ✓ (R56). Seven fakes ✓ (§2.12). 56 iOS / 200 Android ✓ (R50). **Seven** Makefile targets ✓ (`13` §1.3) |
| **The six open conflicts** | P1, P3, P7, P9, P10, P14 are real, correctly numbered against `02-build-manifest.md` §4.5, and correctly described. P7's four weights (390/420/520/600) and the 500–700 axis, P9's 16 pt vs 8–12 px, P10's four haptics vs five, P14's `#0B0D0E` vs `#0A0A0B` all check out against the source artefacts |

---

## 3. Defects found and fixed

Seventeen — eight in `00-PLAN.md`, nine in `00-PLAN-CRITIQUE.md`. Each was fixed in the file it
lives in and marked **`[audit]`** there.

### In `00-PLAN.md`

| # | Defect | Fix |
|---|---|---|
| **A1** | **E20 and E20-T03 say "six Android channels".** There are **eight**. R49 rules that decision #65's six names are superseded, that `reminders.kind`'s eight strings are the channel ids byte-identical, and that `turnout` / `dose` / `withdrawal` are **banned** channel ids. `08` §7 says it in a heading — *"Eight channels, not one"* — and its checklist asserts the eight against the committed schema JSON. Six channels means two reminder kinds with nowhere to fire, and channel ids are **frozen at release** | Both lines corrected to eight, with R49 and the banned-id list named |
| **A2** | **E12-T02 gives the image downscale to `CameraService`.** R47 rules the opposite: `CameraService` owns `image_picker` (`pickImage`, `retrieveLostData`) and **`MediaStore` owns the `flutter_image_compress` downscale**. Written as planned, the gateway wraps two plugins and its fake stops testing the real path | E12-T01 gains the 2048 px / q80 / `keepExif: false` downscale; E12-T02 is reduced to the capture seam, with R47's three-step flow spelled out |
| **A3** | **E29's demo asserts "exactly eight permissions".** Decision-record §3.3 marks `ACCESS_NETWORK_STATE`'s removal **PENDING G0** — *"do not commit the removal on faith"* — so the count is not known until G0 runs. The demo sentence pre-decides the exact question the epic exists to answer | Restated as "exactly the permission set G0 recorded", with `INTERNET` absent and `ACCESS_NETWORK_STATE` on evidence |
| **A4** | **E29-T02 writes "the eight entries" into `expected_permissions.txt`** — same defect, in the artefact that G1 asserts against. A remembered eight in that file is a gate asserting a number nobody measured | Restated as "the entries G0 recorded" |
| **A5** | **E29-T04 types `minSdk` 24 from memory.** `13` §3.1 requires the effective value be *"read out of the merged manifest during G0"* and set explicitly; `08` §8.3's checklist goes further — it must *"appear as a literal in no document including this one"* | Restated to set `minSdk` from G0's merged manifest, with the 24 expectation cited rather than asserted. AGP ≥ 8.12.1 and `desugar_jdk_libs` 2.1.4 added, since `13` §3.1 names both alongside Java 17 |
| **A6** | **E11-T06 states a six-tap budget** on a key P8 abolished (`lambing_entry.birth_type.twin`). The critique catches this as S4; the plan row itself still read the old way, and a task file written from that row would reintroduce the chooser | Restated as the five-tap `beginLambing` assertion, pointing at S4 / N14-T06 / N16-T02a |
| **A7** | **`02-build-manifest.md` §4.4 defect 2 has no owner.** `--t-stamp` 14 px and `--t-head` 16 px sit under the 18 px floor, and the exemption test fails on **`DEAD`**, **`AUTO-CAPTURED`** (the sole §12.5 provenance label) and **`DERIVED FROM N STROKES`** (the sole statement of the §12.4 claim). An unowned correction to the design artefacts is a correction that does not happen | Given to E08-T05, which already owns the scale |
| **A8** | **`02-build-manifest.md` §4.4 defect 1 has no owner.** `indelible.html:1138` puts the live row inside the scrolling `.stream`, so the row being written scrolls off screen — the exact 3am failure the design exists to prevent | Given to E10-T05, which owns the Quick Entry shell |

### In `00-PLAN-CRITIQUE.md`

| # | Defect | Fix |
|---|---|---|
| **B1** | **Eleven of §11.3's 64 test anchors name the wrong file.** An anchor's whole value is that it is a path a developer opens; a wrong path invents a second file for a test the doc set already homes. `test/features/semantics_gate_test.dart` → `test/design/` (`12` §7.4 splits the sweeps by cost). `test/policy/no_money_on_a_shed_screen_test.dart` ×2 → `test/features/no_monetization_test.dart` (**R57 names this file explicitly**). `test/policy/disclaimer_is_referenced_test.dart` → `disclaimer_is_defined_once_test.dart`. `test/policy/arb_completeness_test.dart` → `arb_has_no_domain_noun_test.dart`. `test/policy/export_round_trip_test.dart` → `backup_round_trips_test.dart` (`12` §9: *"one file, two owners, no second copy"*). `test/features/free_tier_test.dart` → `test/policy/cap_never_blocks_live_entry_test.dart`. The two DST anchors → the one `test/domain/uk_zone/dst_test.dart` that holds DST-1…DST-5 | All eleven rewritten to the doc-named file, each citing the ruling |
| **B2** | **The N10 component anchor asserts "no dimension below 64".** `06` §12 sizes `ShedStatusBadge` at *"≥ 24 tall inside a ≥ `tapMin` parent"* and gives `ShedSectionHeading` no target contract at all — it is a heading. As written, the gate makes two of the fifteen components unbuildable | Rewritten to assert every **tap surface** is ≥ 64 × 64 with a `semanticLabel` |
| **B3** | **The N10-T07 overlay anchor bans `showDialog(` outright.** `CONVENTIONS §4.7`'s `ui.show_dialog` rule bans it *"outside the two allowlisted destructive files"*, and `07` §12 names them: restore and delete-everything are **the only two flows permitted to use `showDialog`**. The anchor as written outlaws the only two honest deletes in the app | Split: `showModalBottomSheet(` confined to `shed_bottom_sheet.dart`; `showDialog(` outside the two allowlisted files |
| **B4** | **S6 cites R40 for the export-banner columns.** R40 is a different ruling — it adds `last_reconcile_scheduled` and `left_handed`. The banner's four columns are decision #72's and already exist in `03` §5.13 (`07` §16 lists all four by name) | Citation corrected; the four real column names substituted; `09` §8.3's stamping rule (`completed` **and** `unknown`, never `dismissed`, never before the sheet opens) added, because it is the part that makes the banner honest |
| **B5** | **§8's `assets/content/` gap row has R66 backwards.** R66 gives the ~40 husbandry terms **three** homes — keys in `first_run.dart`, labels in `app_en.arb`, and `assets/content/` for *only* long prose plus one provenance line per list. So E06-T11's key source **is** created. The genuine gap is the ARB half and `test/policy/vocab_labels_are_complete_test.dart`, which asserts the two sets are equal — and stating it wrongly would have sent the ~40 labels to the wrong file | Row rewritten around the real gap |
| **B6** | **N01-T05 says "eight-target `Makefile`".** `13` §1.3 defines **seven** — `gen`, `check`, `test`, `goldens`, `goldens-update`, `perf`, `integration` — and `13`'s checklist lists exactly those. Adding `validate_skills.py` to `check` adds a *command*, not a target | Corrected to seven, targets enumerated verbatim, with the distinction stated |
| **B7** | **N16-T02a amends two artefacts and needs four.** `CONVENTIONS §4.5` publishes **`lambing_entry.birth_type.twin`** as a worked example of the widget-key format and **R59** rules that the old spelling *becomes* it — so the naming authority still blesses a key for the control P8 abolished, while T02a's own canary forbids that key. The amendment rule requires both to move in the same commit | §4.5's example and R59 added to T02a's scope, plus `06` §12's `ShedChoiceRow` row |
| **B8** | **P14 is ruled in one place and applied in three.** `#0B0D0E` is `CONVENTIONS §2.11`'s stated hex for `NightErrorPanel` **and** `13` §5.4's dark-launch check for the iOS `LaunchScreen` and the Android `windowBackground`. N11-T06's anchor already assumes the Indelible page token won. Without a same-commit amendment, the first painted frame and the error panel can end up one hex apart and no test catches it | Added as an explicit coverage row naming N11-T04 as the commit that rules **and** amends |
| **B9** | **§11.4's N02 row routes G0 through `shed-conventions`.** G0 is a manifest and permission question, which `CLAUDE.md`'s routing table sends to `shed-platform-gateways` | N02 given its own row: `shed-platform-gateways` auto-firing, `/shed-release` typed by name, with the `disable-model-invocation` reason stated |

Plus one non-defect recorded in §5 of the critique: the 24 skills and the four runbook flags were
**re-verified against the filesystem**, not against a list, and the result is written down so the next
reader does not have to repeat it.

---

## 4. What remains — and is not mine to fix

| # | Item | Why it is still open |
|---|---|---|
| **R1** | **227 task files do not exist.** Neither does one `epic.md` | Writing 227 task files is authoring, not auditing. `00-AUDIT-template.md` fixes the shape; `00-PLAN-CRITIQUE.md` §11.1/§11.3/§11.4 fixes the content spine. The remaining ~163 tasks still need their own first-failing test named when their file is written |
| **R2** | **`HapticFeedback.successNotification()` is still unverified** | `REFERENCES.md` §22.E E1 calls it *"a five-minute check that closes four documents at once"* — grep the installed 3.44.8 SDK. It cannot be closed from inside `epics/`. P10's task (E08-T09 / N09-T09) is the right owner and already carries it |
| **R3** | **`CONVENTIONS §4.5` and R59 still publish `lambing_entry.birth_type.twin`** | The *plan* now schedules the amendment (B7). The doc edit itself belongs to N16-T02a's commit, under the amendment rule, and must not be made ahead of it |
| **R4** | **`06 §12`'s `ShedChoiceRow` row still reads "Birth type, ease 1–5, death cause"** | Same — scheduled into N16-T02a, not made here |
| **R5** | **`00-PLAN` §3's 227 rows still name no skill and no test** | Structural, not factual: a one-line row cannot carry either. The banner at the top of the file now says so, and §11.3/§11.4 carry the mapping. Fixing it *properly* is R1 |
| **R6** | **The `duplicateActiveTag` contradiction** | `00-README` §"Known open contradictions": `07` §3.3 says the warning *"never blocks the create"* while `03` §6's partial unique index makes a second active animal on the same tag unstorable. One of the two is wrong, it is a **domain** question, and no task in either plan owns it. It lands on E05-T02 / E11-T01 and needs the owner |
| **R7** | **`make integration` is written without `DEVICE=`** | `13` §1.3's target is `make integration DEVICE=…`. Cosmetic in a plan; it must not be cosmetic in E28-T08's Verification block |

---

## 5. Verdict

**The plan and its critique are technically sound on the things that are expensive to get wrong, and
were wrong on seventeen things that are cheap to get wrong and expensive to discover late.**

Skill validity — the half of this lens with the sharpest failure mode, because a wrong skill name is a
developer typing a slash command that returns nothing — is **clean, and was clean before I touched
it**. All 24 names are real, all four runbooks are invoked explicitly, and the routing is defensible
in every row but one, which I fixed. That is a genuinely good result for a 1,300-line planning
artefact and it should be said plainly.

The technical defects clustered exactly where you would predict: **numbers remembered instead of
looked up** (six channels for eight, eight permissions for whatever G0 says, `minSdk` 24, an
eight-target Makefile) and **file paths invented instead of cited** (eleven of 64 anchors). None was
a misunderstanding of the product. Two were worse than cosmetic: the six-channel error would ship
frozen channel ids with two reminder kinds unroutable, and the two "eight permissions" lines pre-decide
G0 — the one decision the decision record says in bold must not be taken on faith.

The honest caveat is §1. **This audit covered a plan, not a backlog.** Seven checks in the brief are
properties of task files, and task files do not exist. What I can attest is that the spine those 227
files will be written from is now accurate. What I cannot attest is that the files themselves will be
— and on the evidence of these seventeen defects, **the first ten task files written should be
re-audited against this same list before the other 217 are started**, because every one of these
errors is the kind that propagates by copy-paste.
