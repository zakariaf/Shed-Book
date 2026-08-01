# A3 — Technical correctness audit of the Shed Book skill set

**Scope.** All 24 skills in `.claude/skills/`, plus their 9 `references/` files, 5 `examples/` files
and 1 `scripts/` file — 39 artefacts, ~4,900 lines.
**Verified against.** `docs/research/00-tech-decisions.md` (decisions #1–#128, §5 the only source of
version numbers, §7.0 the owner rulings), `docs/engineering/CONVENTIONS.md` (BINDING on every name,
path, type shape and signature; R1–R74), `docs/design/indelible.md`, and — where a skill cites one —
the thirteen engineering documents, `CODE-REVIEW-CHECKLIST.md`, `REFERENCES.md` and
`docs/skills/02-build-manifest.md` §4 (the owner rulings P1–P14).
**Date.** 2026-07-28. **Lens.** Technical correctness only. Triggers, overlap and prose quality are
`a1`/`a2`'s.

---

## 0. Verdict in one line

The set is **technically sound on every axis the brief names** — no Riverpod-3 API is offered as
guidance, every version traces to §5, every name I checked matches CONVENTIONS, all five safety rules
sit at or above their stated rung, all seven owner rulings hold, the Indelible defects are corrected
everywhere they are stated, and every Dart snippet compiles conceptually bar one. **Fourteen defects
were found and all fourteen are fixed.** Ten are cross-skill contradictions — two skills giving
incompatible instructions with neither naming the conflict — which is the failure mode a set this
size actually has, rather than a wrong fact in a single file.

---

## 1. What was checked and found clean

Recording these so the next audit does not re-derive them.

### 1.1 Riverpod (lens item 1)

Grepped every Riverpod-3 symbol across all 39 artefacts: `ProviderScope.retry`,
`ProviderContainer.test`, `WidgetTester.container`, `ref.mounted`, `Mutation`/`ref.mutate`,
`@riverpod`, `riverpod_generator`, `riverpod_annotation`, `hooks_riverpod`, `StateProvider`,
`StateNotifier(Provider)`, `ChangeNotifierProvider`, `isAutoDispose`, `ProviderObserverContext`,
every `AsyncValue` accessor. **Every hit is inside a ban list, a symptom→fix table, or a
"this is 3.x" diagnosis.** None is offered as guidance.

The 2.6.1 spellings that *are* offered are correct:
`AutoDisposeFamilyAsyncNotifier<T, Arg>` with `build(Arg arg)` and a zero-argument `C.new` tear-off;
`AsyncNotifierProvider.autoDispose.family<C, T, Arg>(C.new)`;
`NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new)` over an
`AutoDisposeNotifier`; `ProviderContainer(overrides: […])` + a hand-registered
`addTearDown(container.dispose)`; `FutureProvider.overrideWith((ref) async => …)` vs
`Provider.overrideWithValue(…)` used correctly per provider kind in `harness.md`'s eight-override
block; `UncontrolledProviderScope`. The ban on ever writing the type name `Ref` is right — 2.6.1
deprecates `Ref<State>`'s type parameter.

### 1.2 Versions (lens item 2)

Extracted every `x.y.z` token in the set (43 distinct) and traced each. All resolve to
decision-record §5, to a decision-record §2 row, to an engineering document, or to a **section
reference** (`§9.1.1`, `§6.1.1`, `§8.5.5`) or a **standards citation** (WCAG 1.4.12, App Review
3.1.1, EMA CVMP §4.1.2) rather than a package version. Spot-confirmed against §5:
`flutter_riverpod 2.6.1` exact · `build_runner ">=2.15.0 <2.15.2"` · `intl: any` · Flutter 3.44.8 /
Dart 3.12.2 · `drift 2.34.2` / `drift_dev 2.34.5` · `pdf 3.13.0` · `share_plus 13.3.0` ·
`archive 4.0.9` · `flutter_lints 6.0.0` · `mocktail 1.0.5` · `in_app_purchase_storekit ≥ 0.4.8` ·
`http 1.6.0` on two regular edges. **No version from memory.** `record`'s "renamed in 5.0.0" and
`kVoiceNoteMaxSeconds = 60` are both quoted from `08 §4` (60 is 08's explicit "ship 60 until the
owner answers §7.1 #18"), not invented; `TolerantFileComparator` tolerance `0.005` is `12 §8.3`'s.

### 1.3 Names (lens item 3)

Spot-checked ~90 names against CONVENTIONS §§1–5 and the ruling log. All correct, including the ones
most likely to drift: the twelve-repository closed set and the seven gateways (§2.13, §2.12, R74) ·
`shedFailureFrom(Object)` not `ShedFailure.from` (R4) · `WriteCommitted{insertedId, warnings}`
non-generic (R3) · `beginLambing`/`addLamb` return an id and **throw** (R32) · `enterPen`/`exitPen`
on the repository, `turnOut` on the controller (R63) · `recordFoster(LambId, FosterOutcome)` with
`setRearingDam` banned (R64) · `settingsProvider : StreamProvider<AppSetting>` (row class, R29) ·
`minuteTickProvider : StreamProvider.autoDispose<Instant>` (R25) · `quickEntryDeckProvider` with
`recentEwesProvider`/`inPensProvider` banned (R28) · `tagIndexProvider` not `flockTagCacheProvider`
(R26) · the provenance quad `captured_at` / `original_effective` / `time_source`, never
`original_effective_at` (R37, R38) · `occurred_at` with exactly three exceptions · FK columns as the
parent's singular noun with no `_id` · the four `@DataClassName` tables and the 23-name
`models.dart` export list (R7, R20) · `unlockControllerProvider`, `UnlockState`'s four variants and
`kUnlockProductId = 'shed_book_unlock'` (11 §2, §6.2) · `ShedTokens`' `tapMin` 60 / `tapPrimary` 72 /
`tapHero` 88 / `gapMin` 16 and `surfaceRaised` / `textSecondary` (06 §3.3) · `13 RouteNames,
12 Routes` · `[exempt]` at exactly four lines (R56) · the seventeen policy namespaces (§4.7).
The backup's "21 tables" is arithmetically right: 23 row classes minus `Entitlement` and
`EweSummary`.

Two exceptions found and fixed — **D9** (an index name) and **D11** (an example CSV). Both below.

### 1.4 The five safety rules (lens item 4)

Grepped all five failure shapes across the set — a defaulted withdrawal value, a suggested dose,
veterinary advice, an auto-correction of a user entry, a timestamp without provenance. **Every hit is
a prohibition, a counter-example or a gate row.** Nothing anywhere shows one as acceptable. The
ladder in `shed-safety-rules` (unrepresentable → unconstructible → unpersistable → source test →
documented) is consistent with the mechanisms the other skills describe, and the standing rule ("a
rule that has dropped to merely *documented* has been deleted") is stated where it will be read.

Three sharp points are correct and worth keeping: `0` is a real withdrawal-label value, so a nullable
`int` cannot carry the state and absence-of-row is the mechanism; the ceil-to-next-local-midnight is
a *second* rounding in the regulator's own direction and must not be "simplified"; and a
`(birthWeight.inKilograms * 50).round()` fed into an ARB message matches no `ContentPolicy` pattern
and is exactly the banned case.

### 1.5 The owner rulings (lens item 5)

| Ruling | Held? | Where it is stated |
|---|---|---|
| Tag OCR cut | ✅ | `shed-platform-gateways` §"v2 — the record", `indelible-controls`, `shed-monetization`, `shed-code-review`, `gate-failures.md` |
| Voice tag entry cut (voice **note** ships) | ✅ | same five |
| Tags unique among **active** animals only | ✅ | `shed-drift-schema`; two partial unique indexes, uniqueness on `tag` never `tag_digits` |
| UK/Ireland default | ✅ | `shed-domain` §8, `shed-accessibility-and-copy` §9 — `en_GB`, kg, °C, 24-hour, week starts Monday, ambiguous hour **01:00–01:59**, AHDB lambs-born-**alive** |
| No mid-entry upgrade prompt | ✅ | `shed-monetization` (4 hard constraints), `shed-screens-and-routing` §3, `indelible-states-and-feedback` §7 — plus the 22:00–06:00 quiet window and `EntryContext.liveEntry` being *structurally* unblockable |
| **P2 — no SnackBar** | ✅ | Stated in **nine** skills, each superseding `CONVENTIONS §2.11` explicitly; `showSnackBar(` banned including in `feedback.dart`; undo restated as a time-boxed margin strike **in seconds** |
| **P8 — no birth-type segmented control** | ✅ | Stated in **eight** skills; `07 §5.4`'s `lambing_entry.birth_type.twin` finder and `06 §12`'s `ShedChoiceRow` are both named as superseded, and the 6-tap budget's last tap is re-pointed at the tally stroke |

### 1.6 The Indelible defects (lens item 6)

- **Live row scrollable** — corrected in `indelible-page-and-screens` §1.1 (a fixed layer above the
  band, `indelible.html:1138` named as the defect) and echoed in `shed-code-review` and
  `indelible-states-and-feedback`.
- **14px/16px for `DEAD`, `AUTO-CAPTURED`, `DERIVED FROM 3 STROKES`** — corrected in all four design
  skills plus `shed-safety-rules`, `shed-testing`, `shed-accessibility-and-copy` and
  `shed-code-review`. `indelible-design-system` additionally raises `--t-head` 16→18 with the reason
  ("the only statement of which night you are on"), which is within the manifest's correction, and
  `indelible-page-and-screens` owns the layout consequence nobody else would have caught: an 18px
  caps-tracked word does not fit the 68px margin cell, so those three print in the record column.

### 1.7 Design purity (lens item 7)

No element of The Register or Strip Bay appears: no phosphor palette, no welded instrument zones, no
"a digit always means a number", no flight strips, no bays, no dark-board discipline, no commit
green. `re-legend` appears twice but is `06 §8`'s own wording for the keypad grid, not an import.
One attribution defect found and fixed (**D3**).

### 1.8 Dart snippets (lens item 8)

Read all five example files and every inline snippet.

- `shed-withdrawal/examples/clear_date.dart` — matches `05 §3.5` line for line; the IIFE inside a
  switch-expression arm is valid Dart 3; `Instant.epochMillis`, `.plus`, `LocalDate.of`,
  `.startOfDayLocal()`, `.plusDays` and `ClearsOn`'s positional constructor all match §2.2/§2.7.
- `clear_date_dst_test.dart` — I recomputed all five DST assertions against real UK 2026 offsets.
  DST-1's 9 h, DST-4's **167** and DST-5's `2026-04-02 21:00` local → `LocalDate(2026, 4, 3)` are all
  correct. `@Tags(['uk-zone']) library;` is the current directive form.
- `shed-write-path/examples/foster_verb.dart` — imports are layer-legal, `Value(x)` vs
  `Value.absent()` vs `const Value<int?>(null)` are used correctly, companion `insert` puts required
  columns raw and defaulted columns in a `Value`, and `const WriteCommitted()` is the R53-correct
  return.
- `shed-bootstrap-and-errors/examples/main.dart` — the three handlers install in the right order,
  nothing suspends, and (I checked) the file contains no `await ` token, which matters because its
  own last note warns that `main.no_await` is a substring match that fires on prose.
- `indelible-design-system/scripts/contrast.py` — **executed**. Every ratio the skill quotes
  reproduces exactly: 16.19 / 11.69 / 7.80 / 5.63 / 5.75 / 4.94 / 5.59 / 4.80 / 3.52 / 3.02 / 3.88 /
  3.33, and the two placement rules' 4.16 and 2.54. Red-shift reproduces too (9.96 / 6.32 / 5.13 /
  12.79 / 3.73 / 4.73).

One compile defect found and fixed (**D2**).

---

## 2. Defects found — all fixed

Ranked by what a wrong instruction would cost.

### D1 — `flutter test` has no `-P`/`--preset`; the toolchain skill told you to use it

`shed-dependencies-and-toolchain/SKILL.md`, gotchas.

> *"Pass the `dart_test.yaml` preset name (`-P ci-fast`, `-P ci-golden`); never re-spell the filter. A
> bare `--exclude-tags golden` silently drops the `migration` tag's `allow_test_randomization: false`."*

Both sentences are wrong, and `shed-testing` says the opposite in its own body ("`flutter test` has
no `-P`/`--preset`"). `12-testing.md` §11.2 owns `dart_test.yaml`, declines to declare those presets,
and rules that **the flags are canonical and the presets unwritten**: `-P` is not in `flutter test`'s
pass-through set (read off `flutter_tools`' `test.dart`), and this project never runs `dart test`
because decision #4 keeps `package:test` out of the pubspec. 12 also rebuts 13's rationale directly —
tag configuration in `dart_test.yaml` applies to any run that selects those tests, so a command-line
filter cannot switch `allow_test_randomization: false` off. Following the skill produces a Makefile
and three workflows that fail on the first push.

**Fixed.** Replaced with 12's ruling, both sides cited, 12 §14 edit 1 named as the carrier, and the
day-one check named as the thing that could reverse it.

### D2 — `MinimumTapTargetGuideline(size: Size(60, 60))` does not compile

`shed-testing/SKILL.md`. `link` is a **required** named parameter on 3.44 (`06 §5`'s SDK-resolution
line records the signature as `MinimumTapTargetGuideline({size, link})`, and `06 §6.3` ships the
`const` with it). The skill's spelling omits it.

**Fixed.** `MinimumTapTargetGuideline(size: Size(60, 60), link: …)`, pointing at `06 §6.3` for the
`const`, with the reason stated so it is not "tidied" back.

### D3 — the one permitted graft was attributed

`indelible-page-and-screens/SKILL.md` §2 opened *"From The Register, and it is Indelible's now"*.
Manifest §4.3 is explicit: the persistent loaded subject **"is Indelible's now. Do not attribute
it."** `indelible-design-system` gets this right ("the one graft is already Indelible's and is never
attributed"); this skill named the origin in the first four words of the section.

**Fixed.** Attribution removed; the unattributed rule now stated as an instruction that covers code,
comments, commit messages and review.

### D4 / D5 — the pen board described as a reflowing grid of tiles

`shed-accessibility-and-copy/SKILL.md` §4 and its definition of done:

> *"the pen board reflows 4 → 3 → 2 → 1 and is a list at AX5"* · *"The pen board reflows to ≤ 2
> columns at AX5"*

and `references/semantics-recipes.md` §1: `SemanticsRole.listItem` on each **tile**,
`ExcludeSemantics(child: <the painted tile>)`, and *"build a `Column` of `Row`s, or a `GridView`"*.

That is `10 §3.5`/`§4.2`'s model, and it is superseded. Indelible's pen board is **twelve ruled 88 pt
rows, one per pen, in one column** — `indelible-marks-and-strikes` §7 says so in terms ("There are no
tiles; the pen board is ruled rows") and `indelible-page-and-screens` §5 and §8 carry the 88 px row
height and the hours-descending sort. A board that is already one column cannot reflow to fewer, so
the DoD line was unsatisfiable and the recipe's `GridView` option was unbuildable.

**Fixed.** Both restated: rows grow taller, the board is one column at every scale, `06 §11` and
`10 §5.2`'s tile model named as superseded, `GridView` explicitly excluded, "tile" → "row" in the
tree sketch and the one-node rule, and the DoD line rewritten to assert growth and no ellipsis
instead of a column count.

### D6 — `ref.invalidate`: "exactly one" vs a mandated second

`shed-riverpod-providers` (body and DoD) and `riverpod3-symptoms.md` both said the only legitimate
`ref.invalidate` in the app is `minuteTickProvider` on resume and **"a second is a defect"**.
`shed-export-and-restore/references/restore-and-sweeps.md` step 14 requires
`ref.invalidate(databaseProvider)` — which is `04 §7`'s own step 14, and structurally necessary,
because the live database *file* has just been replaced by a rename. `gate-failures.md`'s
`stream.invalidate` row said only *"Delete it (#12)"*, so an agent hitting a red gate on either call
site would delete a mandated call.

02 §3's own wording scopes the ban to drift-backed **read** providers; neither call site is one.

**Fixed** in three places. Both call sites named, the drift-backed-*read* scoping made explicit, and
the open gate question (`CODE-REVIEW-CHECKLIST §1.5` — the rule scans `lib/` with no `[exempt]` line,
so both are expected red) recorded with "raise it; never delete the call to green the gate".

### D7 — the typeface half of P7 was silently resolved

`indelible-design-system` stated the bundled faces as settled fact: *"Two faces, bundled, never
fetched. Record: **Source Serif 4**. Control: **Source Sans 3**."* — and its P7 block asked the
reader to *"read the real `wght` range off the committed Source Serif 4 and Source Sans 3 files"*, as
though they were already in the tree.

They are not. Decision **#98** bundles **one** face, Atkinson Hyperlegible Next; `CONVENTIONS §1`
(BINDING on paths) puts `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf + OFL.txt` in the tree;
`06 §5.2` declares family `AtkinsonNext`; `09 §4.2` embeds that same file in every PDF; `12 §8.3`
loads it in `test/flutter_test_config.dart`; and `shed-goldens-rebaseline` named the Atkinson path.
The manifest defines **P7 as "typeface *and* the `FontVariation` weight axis"** and requires the
owning skill to carry it "open, with the conflict named and both sides cited" — the skill carried
only the weight half. The consequence is not cosmetic: Indelible's Rule 2 (serif = record, sans =
control) *is* the design and collapses to one voice on one family, and "two faces" moves four
artefacts together plus ~700 kB against `13 §6`'s asset budget.

**Fixed.** The typeface conflict is now stated as P7's first half with both sides cited, the two
`REFERENCES §22` checks that gate it (C1 — Atkinson's real file size, `wght` range and figure
features, never downloaded; B8 — whether `pdf` accepts a variable font at all) named, the four
co-moving artefacts listed, and the DoD line widened to "both halves … no `fonts:` block,
`assets/fonts/` path or golden font loader changed on this skill's authority". `shed-goldens-rebaseline`
now loads *every family in the pubspec's `fonts:` block* and names P7, because a family that ships
and is not loaded silently re-baselines eight images in Ahem.

### D8 — `indelible-marks-and-strikes` required `struck`/`struck_at` that P1 forbids adding

Its §0 and DoD asserted the two columns as existing facts. `shed-drift-schema` correctly says P1 is
unruled and the columns are **"not yours to add"**, and `shed-export-and-restore` correctly heads its
section *"blocked on P1"*. The design skill was the one place a reader could land and conclude the
schema was settled.

**Fixed.** The same P1 block added: the design rule stands as the *page and export* shape, the
storage half is blocked, and "if a task needs a strike, an undo or a mute to persist, stop and say P1
blocks it". DoD line qualified to match.

### D9 — index name violated `CONVENTIONS §4.6`

`shed-migrations/examples/migration_step.dart` created `ewes_eid_idx`. §4.6 fixes
`idx_<table-abbrev>_<columns>`, and `03 §5.9`/`§6` ship `idx_ewe_tag_active`, `idx_ewe_tagdigits`. An
index name lands in the committed schema snapshot, so fixing it later costs a migration.

**Fixed** to `idx_ewe_eid`, with the convention cited and the cost noted inline.

### D10 — a counter-example wrote the wrong type into `declared_birth_type`

Same file: the "never do this" block read `UPDATE lambings SET declared_birth_type = 'single'`. That
column stores `BirthType.code`, an **INTEGER 1..5** (§2.9, R6), under `STRICT`. A counter-example that
would fail at the storage layer for a different reason teaches the wrong lesson about the right rule.

**Fixed** to an integer code, with a note that the column is nullable precisely so "no strokes
tallied yet" is storable and that there is no birth-type chooser to backfill from.

### D11 — `examples/lambs.csv` rendered two different time zones in one file

`09 §3` cols 13–15: `born_at_local` is **derived from `born_at_utc` in the export-time zone**, and
`local_date_disagrees` is `born_local_date ≠` that same render. One zone per file, by construction.

The committed example rendered four rows at **UTC+00:00** and one (the row that exists to demonstrate
`local_date_disagrees = 1`) at **UTC+01:00**, while its trailer declared *"rendered in IST
(UTC+01:00)"*. It is also the wrong zone on the facts: the file's dates are 13–15 March 2026 and UK/
Ireland DST starts 29 March, so mid-March is GMT. This is the one artefact a writer is told to read
*before writing any CSV shape*, and it taught that the offset is per-row.

**Fixed** at byte level and re-verified programmatically: every row now renders at UTC+00:00, the
trailer declares GMT (UTC+00:00), and the `local_date_disagrees = 1` demonstration is preserved by
leaving the *stored* `born_local_date` one day ahead of the fresh GMT render — which is what the flag
actually means (the shepherd's lived day, recorded when the device was in a different zone, versus
today's render). Re-asserted after the edit: BOM present, CRLF throughout including the final record,
37 columns on all 13 records, the embedded-newline note intact, and quoting correct on every field
that needs it — including the two the repair initially dropped, `" watched her all night "`
(leading/trailing whitespace) and `"Dai; vet"` (semicolon), both restored. A validator over the house
quoting rule (`,` `"` CR LF `;` TAB, leading/trailing whitespace) now reports zero problems.

### D12 — see D6 (`gate-failures.md`'s `stream.invalidate` row).

### D13 — `NOT RECORDED · SKIPPABLE` cited as a legal 14px stamp in the same sentence that bans it

`indelible-controls` gotchas listed it among stamps that are *"legal only while all three §3.4
exemption conditions hold: **≤12 characters**, …"*. It is 23 characters. `indelible-states-and-feedback`
§4 defends it on the third condition only and never mentions the first. The discrepancy is
`indelible.md`'s own (§7.8/§7.9 print it at `--t-stamp`), but as written the skill contradicted
itself in one sentence and handed a reader precedent for any long stamp.

**Fixed.** Split out: the two genuinely-exempt control stamps keep the rule; `NOT RECORDED ·
SKIPPABLE` is named as failing the *first* condition, its survival attributed to the dotted rule
carrying the same fact, and explicitly barred as precedent — a stamp over 12 characters is a label
and takes an ≥18px role.

### D14 — pre-release checklist miscounted its own after-upload items

`shed-release/references/pre-release-checklist.md` opened *"three items can only be done after
upload"*; section F has four (19–22), and `shed-release/SKILL.md` says four. A checklist whose
preamble disagrees with its own sections is one somebody stops reading.

**Fixed** to four, with the section named.

---

## 3. What remains open — and is correctly open

None of these is a defect. Each is a conflict the skill set is *supposed* to carry unresolved, and
after the fixes each is named in exactly one owning skill with both sides cited.

| # | Open question | Carried by | Blocks |
|---|---|---|---|
| **P1** | `struck` / `struck_at` on every table — schema-irreversible | `shed-drift-schema` (blocked), `shed-export-and-restore` (build against the names), `indelible-marks-and-strikes` (**added this pass**) | the schema freeze; every strike/undo/mute that must persist |
| **P3** | Navigator stack vs Indelible's `INDEX`-only model | `shed-screens-and-routing` §10 | adding an index sheet, removing a back affordance, changing the 13/12 count |
| **P7** | **(a) the typeface** — one Atkinson vs two Source families (**added this pass**); (b) the 390/420 weights vs a 500–700 axis | `indelible-design-system` | the `fonts:` block, `assets/fonts/`, the embedded PDF TTF, the golden font loader |
| **P9** | ≥16 pt separation vs Indelible's 8–12 px keypad/ease geometry | `indelible-page-and-screens` §9 | re-spacing the keypad, relaxing `tap_target_test.dart` |
| **P10** | four haptics (06) vs five (Indelible §5.4); `HapticFeedback.successNotification()` unverified | `indelible-design-system` | writing the haptic call |
| **P14** | `NightErrorPanel`'s `#0B0D0E` vs `--page` `#0A0A0B`, and `launch.colour_parity` asserting equality | `indelible-states-and-feedback` §2 | either literal, or that assertion |
| — | `stream.invalidate` has no `[exempt]` line and the architecture needs two call sites | `shed-riverpod-providers`, `gate-failures.md` (**both updated this pass**) | a green gate on `app.dart` and the restore flow |
| — | G0 unrun ⇒ G1 unwritten ⇒ `android/expected_permissions.txt` does not exist | `shed-release` stop condition 1 | any `tools:node="remove"` line |
| — | FTS5 shadow tables vs `SchemaVerifier` — unverified | `shed-migrations` | the migration matrix in week one |

Two further items I judged **not** defects after checking, recorded so they are not re-raised:

- **`shed-release`'s 10%/72 h vs the checklist's 10%/24 h** — different cases, both correct. `13 §11`:
  a *post-1 May* release is 10% for 72 h; a *freeze-clearing* release is 10% for 24 h.
- **`indelible-design-system` raising `--t-head` 16→18** — beyond the manifest's literal three
  strings, but inside its stated rule ("a fourth string that turns out to be the sole carrier of its
  meaning is not a stamp either") and correct on the facts.

---

## 4. Honest verdict

**Technically correct, after fourteen fixes.** The set gets the hard things right — the exact
Riverpod pin and every 2.6.1 spelling, absolute-time withdrawal arithmetic with the measured 167-hour
case, the five safety rules as types and layer bans rather than reminders, all seven owner rulings
restated in every skill where the mistake would be made, and the two Indelible artefact defects
corrected consistently in eight files. The contrast script reproduces every published ratio exactly.

The failure mode this audit actually found is not wrong facts — it is **eleven-file coherence**. Ten
of the fourteen defects are two skills disagreeing where an agent loads only one: presets vs flags,
one `ref.invalidate` vs two, one font vs two, a tile grid vs ruled rows, `struck` columns asserted vs
blocked, a stamp banned and permitted in one sentence. None was catchable inside a single file, and
none would have been caught by a per-skill review. **A cross-skill consistency pass belongs in the
authoring standard**, and the cheapest form of it is mechanical: a script that extracts every
"X is banned / there is exactly one X / X is superseded" claim and diffs the claims against each
other.

Two things I could not verify and am not claiming: whether `flutter test` on the *installed* SDK
accepts `-P` (12 §11.2's day-one check — I applied 12's ruling because 12 owns the file, and named
the reversal condition), and whether Atkinson Hyperlegible Next's `wght` axis or `pdf`'s variable-font
support behave as `06 §5.2` and `09 §4.2` assume (`REFERENCES §22` C1 and B8, both recorded as
unverified upstream). Both are now stated as open inside the owning skill rather than silently
resolved.
