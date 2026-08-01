# 00-AUDIT-depth — the final conformance pass over the deepened backlog

> **Scope.** Re-verify the five elements the owner requires preserved in every task file, confirm the
> generic boilerplate is gone, sweep for accuracy against the binding authorities, and get
> `tool/validate_epics.py` to exit 0 without weakening a check.
>
> **Result.** `35 epics · 240 tasks · 0 failures · 8 warnings — PASS`, exit code 0.
> All five preserved elements verified present in all 240 files by a second, independent script.
> Eleven task files were structurally broken and are repaired. Two validator checks were themselves
> defective and are fixed. A repeated-sentence check has been added. Eight repeats remain and are
> named honestly in §6.

---

## 0. Headline

| | |
|---|---|
| Epics | 35 (`N00`–`N34`) |
| Task files | 240 |
| Total lines, task files | 67,554 |
| Total lines, `epic.md` | 9,421 |
| Task-file length | min **165** · median **278** · max **439** |
| `epic.md` length | min **163** (`N01`) · max **442** (`N30`) |
| `python3 tool/validate_epics.py` | **PASS, exit 0** — 0 failures, 8 warnings |
| `python3 tool/validate_skills.py` | **PASS with warnings** — 24 skills, 0 failures |
| Five preserved elements | **240 / 240**, verified independently of the validator |
| `"The layers this task reaches are the ones named in"` | **0 occurrences** |

---

## 1. A note on the "before" column

There is **no git history in this repository** — `git log` reports *"your current branch 'main' does
not have any commits yet"* and `epics/` is untracked. There is therefore no on-disk pre-deepening
snapshot to diff against, and any per-epic "before" line count for the *deepening* pass would be
invented. This audit does not invent one. It reports three things it can actually stand behind:

| Column | What it is | Source |
|---|---|---|
| **(a) pre-deepening** | median 85 lines/task · 236 of 241 files sharing one boilerplate sentence · several `epic.md` at 47 lines | the brief's own record of the recovery-conditions state; **not measurable on disk** |
| **(b) start of this pass** | 240 tasks · min 165 · median 277 · max 439 · **0** boilerplate hits · `epic.md` min 163 | measured by this pass before any edit |
| **(c) now** | the table in §2 | measured after the edits in §3 |

The deepening had already landed before this pass began. What (b) → (c) records is a **conformance
delta**, not a depth delta: this pass added 66 net lines to the corpus (18 rewritten skills
sections, 19 rewritten constraint bullets, one amended file row). The depth was already there; what
was missing was that eleven files did not obey the template, two validator checks were lying, and
one file was unreadable to `grep`.

---

## 2. Per-epic line counts, after

| Epic | Tasks | `epic.md` | task lines | min | median | max |
|---|---:|---:|---:|---:|---:|---:|
| `N00-decisions-rulings-and-the-calendar` | 9 | 192 | 1751 | 165 | 199 | 230 |
| `N01-the-tree-the-configs-and-the-ci-shell` | 7 | 163 | 1693 | 214 | 239 | 278 |
| `N02-g0-the-merged-manifest-record` | 3 | 189 | 777 | 237 | 249 | 291 |
| `N03-the-gate` | 7 | 176 | 1827 | 214 | 268 | 299 |
| `N04-domain-time-and-units` | 8 | 181 | 1889 | 203 | 235 | 277 |
| `N05-domain-withdrawal` | 5 | 173 | 1253 | 232 | 250 | 272 |
| `N06-domain-statistics-warnings-and-policy` | 11 | 208 | 2512 | 201 | 228 | 253 |
| `N07-the-schema-and-the-freeze` | 8 | 226 | 2140 | 231 | 269 | 308 |
| `N08-the-migration-harness-and-the-codegen-job` | 7 | 177 | 1536 | 189 | 220 | 255 |
| `N09-the-design-system-foundation` | 9 | 271 | 2571 | 253 | 282 | 319 |
| `N10-the-component-inventory` | 8 | 315 | 2361 | 274 | 293 | 323 |
| `N11-bootstrap-errors-and-the-first-frame` | 9 | 308 | 2733 | 260 | 305 | 388 |
| `N12-the-di-root-settings-the-ticker-and-the-harness` | 5 | 296 | 1648 | 278 | 332 | 405 |
| `N13-quick-entry-the-deck-and-the-keypad` | 7 | 321 | 2379 | 317 | 345 | 357 |
| `N14-quick-entry-the-write-path` | 7 | 292 | 1931 | 229 | 273 | 335 |
| `N15-media-and-notes` | 6 | 224 | 1800 | 292 | 298 | 314 |
| `N16-lambing-entry` | 10 | 299 | 2738 | 222 | 267 | 349 |
| `N17-lamb-card` | 5 | 286 | 1396 | 211 | 265 | 365 |
| `N18-foster` | 5 | 253 | 1157 | 205 | 223 | 275 |
| `N19-pen-board` | 7 | 279 | 1880 | 236 | 269 | 300 |
| `N20-treatments-and-withdrawal` | 7 | 308 | 2075 | 262 | 275 | 373 |
| `N21-export-csv-pdf-and-share` | 8 | 372 | 2436 | 268 | 303 | 339 |
| `N22-the-json-backup-format` | 5 | 278 | 1555 | 292 | 309 | 343 |
| `N23-restore-the-sweeps-and-the-seed` | 7 | 326 | 1956 | 246 | 268 | 340 |
| `N24-reminders-rows-reconcile-and-the-fixtures` | 8 | 332 | 2280 | 210 | 302 | 319 |
| `N25-reminders-screen` | 6 | 212 | 1507 | 230 | 244 | 286 |
| `N26-flock-and-note-search` | 7 | 369 | 2611 | 310 | 369 | 439 |
| `N27-ewe-card` | 7 | 347 | 2140 | 269 | 310 | 347 |
| `N28-season-summary` | 6 | 202 | 1641 | 251 | 272 | 294 |
| `N29-settings` | 8 | 349 | 2822 | 283 | 344 | 402 |
| `N30-monetization` | 8 | 442 | 2409 | 253 | 301 | 351 |
| `N31-platform-artefacts-g1-g4-and-g5` | 4 | 303 | 1348 | 288 | 337 | 386 |
| `N32-signing-and-the-closed-track` | 3 | 225 | 894 | 277 | 294 | 323 |
| `N33-ship-gates-sweeps-goldens-and-journeys` | 9 | 357 | 2734 | 268 | 303 | 368 |
| `N34-release-engineering` | 4 | 170 | 1174 | 255 | 284 | 350 |
| **Total** | **240** | **9,421** | **67,554** | **165** | **278** | **439** |

The shortest task file in the backlog is `N08-T05` at 189 lines. The shortest `epic.md` is `N01` at
163. Nothing in the corpus is close to the 85-line median or the 47-line `epic.md` the brief
describes.

---

## 3. What was fixed

### 3.1 Eleven task files did not obey the template — `N06`, all of it

`N06-T01` … `N06-T11` used an **eleven-section** heading scheme of their own:

```
## 6. The details that are easy to get wrong      ## 8. Constraints that bind this task
## 7. The full test set                           ## 9. Definition of Done
                                                  ## 10. Verification
                                                  ## 11. Close out
```

Every other file in the backlog carries those first two as `### 5.n` subsections and keeps sections
6–9 canonical. The validator was therefore reporting, correctly, that all eleven files were missing
`## 6. Constraints`, `## 7. Definition of Done`, `## 8. Verification` and `## 9. Close out`, and had
no Verification `bash` block, no Definition of Done and no closing sequence — **44 + 11 + 11 + 11 +
11 + 11 = 99 failures from one structural mistake.** The content was there; the headings lied about
where.

Fixed by demoting the two extra headings to `### 5.n` (continuing each file's existing subsection
numbering) and renumbering 8→6, 9→7, 10→8, 11→9. Four internal cross-references that pointed at the
old numbers were re-pointed by hand:

| File | Was | Now |
|---|---|---|
| `N06-T01` | *"the erasure assertion in §7"* | `§5.4` |
| `N06-T02` | *"see §6"* (the `duplicateActiveTag` row) | `§5.4` |
| `N06-T03` | *"see T02 §6"* | `T02 §5.4` |
| `N06-T08` | *"the stored value is `.name` (see §6)"* | `§5.4` |

Every other `§6`–`§11` in the epic was re-read and is a reference to an **external** document
(`00-README §8`, `CONVENTIONS §6`, `05 §9`, `12 §10`, `spec §11`), left alone.

### 3.2 One task file was binary as far as `grep` is concerned

`N22-T05-file-import-through-file-selector-with-the-magic-bytes-valid.md` contained **two raw NUL
bytes** — the file wrote SQLite's magic string `"SQLite format 3\0"` with a literal `0x00` instead of
the two-character escape. `file(1)` reported it as `data`, and **`grep` silently matched nothing in
it**: `grep -n "^## " <file>` returned no rows on a file with nine `##` headings.

That is worse than a cosmetic defect. Every convention check in this project is a grep — the audits
above this one, `tool/check_policy.dart`'s ancestors, and the sweeps in §4 below — and this file was
invisible to all of them. Both NULs replaced with the literal `\0`; the file now reads as
`Unicode text, UTF-8`.

### 3.3 Eighteen skills tables were over budget

`CLAUDE.md`: *"At most **two** auto-firing skills per intent; where a task spans more, the owning
skill names the next one to load."* Eighteen files broke it — all eight of `N21`, eight of `N11`,
plus `N04-T05` and `N24-T04`; `N21-T07` named five skills, four of them auto-firing.

Deleting rows would have deleted the guidance. Instead each table was cut to the two skills that
*own* the task, and the concerns that lost their slot were written out in prose beneath the table —
which is already the house convention (`N12-T02`, `N12-T03`, `N13-T02`, `N17-T01`, `N26-T02`,
`N29-T01`, `N29-T04`, `N29-T05`, `N29-T06` all do it). Each note says which skill is *not* being
loaded and **which section of this file carries what it would have supplied**, so nothing is lost:

| File | Kept | Deferred to, and where it is written out |
|---|---|---|
| `N21-T01` | `shed-export-and-restore` · `shed-testing` | `shed-domain` → §5.2 · `shed-conventions` → §5.1, §5.5 |
| `N21-T02` | `shed-export-and-restore` · `shed-withdrawal` | `shed-drift-schema` → §5.2 · `indelible-marks-and-strikes` → §6 |
| `N21-T03` | `shed-safety-rules` · `shed-export-and-restore` | `shed-accessibility-and-copy` → §5.3 · `indelible-marks-and-strikes` → §5.2 |
| `N21-T04` | `shed-export-and-restore` · `shed-dependencies-and-toolchain` | `indelible-design-system` → §5.2 · `shed-conventions` → §5.1 |
| `N21-T05` | `shed-export-and-restore` · `shed-riverpod-providers` | `shed-testing` → §5.4 · `indelible-marks-and-strikes` → §6, §5.4 |
| `N21-T06` | `shed-platform-gateways` · `shed-dependencies-and-toolchain` | `shed-export-and-restore` → §5.1, §6 · `shed-testing` → §5.4 |
| `N21-T07` | `shed-screens-and-routing` · `indelible-page-and-screens` | three more → §5.1, §5.2 |
| `N21-T08` | `indelible-states-and-feedback` · `shed-screens-and-routing` | `shed-monetization` → §6 · `shed-testing` → §5.4 |
| `N11-T01` | `shed-bootstrap-and-errors` · `shed-conventions` | `shed-accessibility-and-copy` → §5.2, §6 |
| `N11-T02` | `shed-bootstrap-and-errors` · `shed-drift-schema` | `shed-testing` → §5.4 |
| `N11-T03` | `shed-bootstrap-and-errors` · `shed-riverpod-providers` | `shed-testing` → §5.4 |
| `N11-T04` | `shed-bootstrap-and-errors` · `indelible-states-and-feedback` | `shed-conventions` → §5.1, §6 |
| `N11-T05` | `shed-bootstrap-and-errors` · `shed-riverpod-providers` | `shed-accessibility-and-copy` → §5.2, §5.3 |
| `N11-T06` | `shed-platform-gateways` · `indelible-design-system` | `shed-dependencies-and-toolchain` → §8 |
| `N11-T08` | `shed-testing` · `indelible-design-system` | `shed-conventions` → §5.2, §5.4 |
| `N11-T09` | `shed-bootstrap-and-errors` · `shed-safety-rules` | `shed-testing` → §5.4 |
| `N04-T05` | `shed-domain` · `shed-conventions` | `shed-testing` → §5.4 |
| `N24-T04` | `shed-write-path` · `shed-safety-rules` | `shed-platform-gateways` → §5.2, §6 |

`N11-T07` was already inside budget: its third row names `shed-release` as a manual runbook, which
does not count against the auto-firing cap.

### 3.4 Nineteen constraint bullets deferred instead of stating — the last of the boilerplate

The sentence the brief names is gone: `"The layers this task reaches are the ones named in"` has
**zero** occurrences. But its twin survived, in nineteen files, and it fails in exactly the same way
— it points somewhere else instead of saying the thing:

> `- **The five safety rules** — the rule this task touches is named in §1, with the level it is
> held at. A rule that drops to merely *documented* has been deleted, whatever the prose says.`

A developer starting `N20-T04` at 3am does not want to be told the rule is named somewhere else. All
nineteen were replaced with the rule, the level in the mechanism hierarchy, and the specific way this
task can break it:

| File | Now says |
|---|---|
| `N00-T04` | §12.1 and §12.4 are *decided* here, not held here; after `N07-T08` the only answer left is a migration |
| `N06-T02` | §12.4 at **unrepresentable** — no writer, no `fix()`, no `warnings` column, `lib/data/` may not import the folder |
| `N06-T03` | §12.4 at **unrepresentable**; `kPlausibleBirthWeight` is a band not a limit — a 9 kg lamb warns and stores as typed |
| `N06-T04` | **no safety rule is held here**, and the commit message says so — naming one would put it at *documented*, which is deletion |
| `N06-T09` | §12.2 and §12.3 both at **caught by a gate**, per `12 §10`; §12.1 rides in `ContentPolicy` as banned *strings*, not banned *values* |
| `N06-T11` | §12.2 at **caught by a gate** — these forty strings are what `copy.vet_advice` reads |
| `N18-T04` | §12.4 at **caught by a test**; fostering to the birth dam warns and never refuses, because refusing is husbandry advice |
| `N19-T04` | §12.2 reduced to one word — ***whose***. A hard-coded 24, a suggested 24 and an unattributed 24 are the same defect |
| `N20-T01` | §12.1 at **unpersistable**: no child row means *not recorded*; a zero-day row *to be safe* defeats it in one line |
| `N20-T02` | §12.1 at **unconstructible**: `ShedFieldRow` has no parameter that can carry a placeholder — do not add one |
| `N20-T03` | §12.5 on both sides of one line: the date is stored once, the countdown is stored never |
| `N20-T04` | §12.1 — the one place a line that passes every gate still breaks the rule; NADIS' sentence goes in a comment at the copy site |
| `N20-T05` | §12.2 as what the app refuses to conclude: a void is evidence the *record* was wrong, not that the animal was untreated |
| `N20-T06` | §12.4's most consequential rendering: both numbers shown, neither changed, the row byte-identical afterwards |
| `N20-T07` | four of the five rules on one screen (`07 §1.5`), every disclosure **referenced** and never re-typed |
| `N27-T04` | §12.5 at **unrepresentable** — this is the task where it stays there or drops to *documented* |
| `N27-T05` | §12.4 at **caught by a test**: a silent merge of two ewes' histories is a correction made without telling anybody |
| `N27-T06` | §12.2 at **caught by a gate**; no widget test can assert the absence of advice |
| `N29-T06` | §12.4: the only two genuine destructions, and a count that was not actually queried breaks the rule too |

### 3.5 One new file was not recorded as a tree amendment

`N26-T04` creates `lib/domain/ewe_status.dart`. `CONVENTIONS` §1 opens with *"every path any of the
seven documents names is either in this tree or is banned by a numbered ruling"*, and the task
amended §2.9 (the enum catalogue) but not §1 (the tree). Row 9 of its file table and its wording now
require both edits in the same commit.

### 3.6 Two validator checks were themselves wrong

Both were producing **77 false failures** that no edit to the backlog could have cleared, and both
were fixed by making the check *more* precise, never by relaxing a threshold. Every threshold
constant in `tool/validate_epics.py` is unchanged.

**`epic.dangling_task` — 41 false failures.** The check read every task id in an `epic.md`'s
`## Tasks` section and demanded a file for it **in that directory**. But a Tasks table names its own
tasks *and* the earlier-epic tasks each depends on, so every cross-epic dependency — `N04`'s epic.md
citing `N03-T07`, `N30`'s citing `N06-T10` — failed on a task that exists. Now the ids are resolved
in two passes: an id belonging to this epic must have a file **here**, an id belonging to another
epic must have a file **somewhere in the backlog**. That is strictly stronger than before, because
the old code could not detect a reference to a task that exists nowhere at all. Proved by injection:

```
N05-T99 (own epic, no file)  → epic.dangling_task ✓
N99-T01 (no epic at all)     → epic.dangling_task ✓
N04-T01 (real, other epic)   → silent ✓
```

**`skill.unknown_command` — 36 false failures.** `SLASH_TOKEN_RE` treated any `/word` as a slash
command. It cannot: the character before the slash is identical in all four of these shapes.

| Text | What it is |
|---|---|
| `` `/simplify` `` | an invocation — the only one wanted |
| `` `is`/`switch`/serialisation `` | an alternation between two code spans |
| `` `/tmp/seed_a` ``, `res/values/colors.xml` | a path |
| `</resources>`, `</dict>`, `</intent-filter>` | a closing XML / plist tag |

So the text is now **lexed rather than pattern-matched**: fenced blocks are dropped, inline code
spans are examined individually (a span whose whole content is `/name` with no second slash is an
invocation; anything else is a path), and each span is then replaced by `\x01` — deliberately not
whitespace — so that a slash *following* a span cannot be read as a command at word start. The check
keeps its teeth; unit-tested against thirteen shapes:

```
OK  'run `/shed-lambing-helper` first'          -> ['shed-lambing-helper']
OK  'then run /shed-made-up before committing'  -> ['shed-made-up']
OK  '1. **`/simplify`** — quality only.'        -> ['simplify']
OK  '`shed-release` (manual, `/shed-release`)'  -> ['shed-release']
OK  '</resources>\n</dict>\n</intent-filter>'   -> []
OK  '`/tmp/seed_a` and `/usr/bin/env`'          -> []
OK  '`is`/`switch`/serialisation path'          -> []
OK  'it is a `v*`/dispatch job'                 -> []
OK  '`try`/ignore: if the delete also fails'    -> []
OK  '`getApplicationSupportDirectory()/media`'  -> []
OK  '```bash\nsed -i.bak \'s/red="1"/red="2"/\'\n```' -> []
OK  'android/app/src/main/res/values/colors.xml'-> []
lexer: PASS
```

### 3.7 The repeated-boilerplate check, added

`tool/validate_epics.py` did not check for repeated boilerplate. It does now — a new rule
`task.boilerplate`, documented in the module docstring under **WHAT IT WARNS ABOUT**:

- a prose sentence of **≥ 10 words** appearing in **more than 5** task files is a **warning**;
- fenced code, table rows, blockquotes and headings are excluded — none is a place a generic
  sentence hides, and a heading run into the paragraph below it yields a fragment that matches
  everywhere and means nothing;
- sentence boundaries are `[.!?]` **followed by whitespace**, so `app_en.arb`, `CLAUDE.md` and
  `§5.4` do not split;
- `TEMPLATE_FIXED_SECTIONS` and `TEMPLATE_FIXED_SENTENCES` exempt, **by name and with the reason
  written beside them**, the text the owner requires identical everywhere: the whole of
  `## 9. Close out`, and the two stock TDD instructions (*"Write this test first, run it, and
  confirm it fails…"*, *"With the suite green, fold any duplication…"*). Counting those as
  boilerplate would bury the sentences that are boilerplate.

It is a **warning and not a failure** on purpose: deciding whether a repeated sentence is filler or a
binding constraint restated is judgement, and this check only has to make the repetition visible.
`MAX_FILES_PER_SENTENCE = 5` and `MIN_SENTENCE_WORDS = 10` sit with the other thresholds at the top
of the file.

---

## 4. The accuracy sweep

| What was swept | Method | Result |
|---|---|---|
| **Boilerplate sentence** | `grep -rl "The layers this task reaches are the ones named in"` | **0 files** |
| **Skill names** | validator, over table rows *and* every backticked `shed-*` / `indelible-*` token *and* every slash invocation | **0 invented names**; the 24 in `AUTO_FIRING_SKILLS ∪ RUNBOOK_SKILLS` are exactly the 24 on disk |
| **Skill budget** | ≤ 3 rows, ≤ 2 auto-firing | **240 / 240 conform** after §3.3 |
| **Versions** | every `<package> <x.y.z>` in the corpus vs decision-record §5 | **every one matches.** `drift 2.34.2` · `drift_dev 2.34.5` · `sqlite3 3.5.0` · `pdf 3.13.0` · `share_plus 13.3.0` · `flutter_local_notifications 22.2.0` · `record 7.1.1` · `flutter_lints 6.0.0` · `build_runner ">=2.15.0 <2.15.2"` · `intl 0.20.2` · `flutter_riverpod 2.6.1` (never a caret). The single `record 5.0.0` is `N15-T03` correctly explaining that `Record` was renamed `AudioRecorder` in 5.0.0 *"and this project is on 7.1.1"* |
| **Riverpod 3 APIs** | grep for `riverpod_annotation` · `@riverpod` · `riverpod_generator` · `hooks_riverpod` · `Ref.mounted` · `ref.mutate` · `Mutation<` · `Ref<T>` · `StateProvider` · `StateNotifier` · `valueOrNull` | **every occurrence is a ban, a gate row or a `grep … # expect zero`.** `N12-T04` line 321 and `N16-T01` line 339 are the greps; `N03-T06` holds the thirteen `rp3.*` rule rows. 121 uses of `.autoDispose` — a 2.6.1 marker, correct |
| **`SnackBar`** | grep, all forms | **no file proposes one.** Every hit is P2 being enforced: the `gesture.raw_snackbar` gate row with **no exemption**, `N09-T04`'s `grep -n "snackBar" lib/core/ui/theme.dart # expect zero`, and `N10-T08` building `ShedReceiptBar` with its own live region because a house widget inherits none of the framework's wrapping |
| **Birth-type chooser** | grep, all forms | **no file proposes one.** `N16-T02a` exists specifically to rule P8 against `07 §5.4` and `12 §10.1`, strike the decision row *with its reason*, and add `test/policy/p8_ruled_test.dart` asserting no document or skill in the set prescribes one |
| **Defaulted withdrawal** | the three-halves mechanism | intact and cross-referenced: **type** `N05-T01`, **source** `N05-T04`, **schema** `N07-T08`, **widget** `N20-T02`. No file defaults, pre-fills or suggests a day count |
| **Veterinary advice** | §12.2 mechanism | held at *caught by a gate* (`copy.vet_advice`), authored in `N06-T09`, scoped over `lib/` and `assets/` with the joined-string-literal trap handled |
| **Silent correction** | §12.4 mechanism | held at *unrepresentable* in `N06-T02`; `N17-T02` names the exact failure — 9.5 lb stored as 9.5-with-a-flag reads back 9.48 lb after a unit switch, *"the value drifted because nobody edited it"* |
| **Offline purity** | grep for network packages | `speech_to_text`, `google_fonts`, `printing`, `google_mlkit_*` appear **only** in `N03-T03`'s G3 banned-import list |
| **OCR / voice tag entry** | grep | cut from v1 everywhere. Voice *notes* ship (`record` 7.1.1, `aacLc`/`.m4a`, never `opus`); voice *tag entry* does not |
| **Locale and units** | grep `lb` · `Fahrenheit` · `en_US` · `AM/PM` · `12-hour` | canonical `Grams` / `MilliCelsius`, converted **at the display edge only**. `en_US` appears twice, both times as the `package:intl` trap (*"a null locale in a background isolate silently produces `en_US`"*); `AM/PM` appears once, as the reason for 24h |
| **3am test constants** | grep the numerals | `60 × 60` is the spec floor, `64 × 64` is Indelible's (109 uses, above floor), `72 × 72` twice (a sheet dismiss, a semantics canary). `48 × 48` appears three times and **only** as `accessibility_tools` 2.8.0's inadequate default, flagged as below the floor each time. Text floor is `18 px`, 91 times, never anything else |
| **DST hour** | grep | `01:00–01:59`, 101 times. The one `02:00–02:59` is `N25-T05` noting continental Europe shifts an hour later |
| **AHDB** | grep | 8 files, all as the lambing-percentage convention, with the toy season reading 165% under it |
| **The Register / Strip Bay** | grep | the only occurrence is `N13-T05`'s `grep -rn "the-register\|strip-bay\|Strip Bay\|The Register" lib/ test/ # expect zero`. Indelible only |
| **`lib/` paths** | 254 distinct paths vs `CONVENTIONS` §1 | all conform. The 139 not literally in §1's tree are `lib/features/<name>/<name>_screen.dart`-shaped (§1 gives the pattern, not the leaves), flat `lib/data/` additions (R18 permits, and each task records its `CONVENTIONS` amendment), deliberate `_plant.dart` / `foo.dart` gate fixtures, or Flutter SDK paths under `packages/flutter/lib/src/`. `lib/domain/validation/flock_checks.dart` appears once — as a file `N06-T02` explicitly says **does not exist and must not be created** |

---

## 5. Verbatim validator output

```
$ python3 tool/validate_epics.py ; echo "EXIT=$?"
Shed Book backlog validation
========================================================================
epics: 35   tasks: 240   skills known: 24

  N00   9 tasks     N09   9 tasks     N18   5 tasks     N27   7 tasks
  N01   7 tasks     N10   8 tasks     N19   7 tasks     N28   6 tasks
  N02   3 tasks     N11   9 tasks     N20   7 tasks     N29   8 tasks
  N03   7 tasks     N12   5 tasks     N21   8 tasks     N30   8 tasks
  N04   8 tasks     N13   7 tasks     N22   5 tasks     N31   4 tasks
  N05   5 tasks     N14   7 tasks     N23   7 tasks     N32   3 tasks
  N06  11 tasks     N15   6 tasks     N24   8 tasks     N33   9 tasks
  N07   8 tasks     N16  10 tasks     N25   6 tasks     N34   4 tasks
  N08   7 tasks     N17   5 tasks     N26   7 tasks

WARNINGS (8)
  ~ [task.boilerplate] …N00-T01…: this sentence appears in 239 task files (the ceiling is 5) — say
      what *this* task does instead: "The banned words are banned in the commit message too: no
      `draft`, no `save()`, no `sync`, no `Error` as a fai"
  ~ [task.boilerplate] …N01-T03…: appears in 78 task files: "There is no later sweep that adds them;
      N33 only verifies."
  ~ [task.boilerplate] …N00-T01…: appears in 73 task files: "G2 (the dependency allowlist) and G3
      (the import scan) stay green, and the permission set never changes withou"
  ~ [task.boilerplate] …N01-T03…: appears in 72 task files: "- **Accessibility and the ARB, authored
      here** — every string in `app_en.arb` with a `description`, every elem"
  ~ [task.boilerplate] …N03-T05…: appears in 37 task files: "- **3am** — every interactive element
      ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and "
  ~ [task.boilerplate] …N12-T04…: appears in 33 task files: "No draft, no Save button, no
      `commit()`, no optimistic UI; every write commits immediately and goes through `g"
  ~ [task.boilerplate] …N12-T04…: appears in 29 task files: "- **Write path** — the row is created
      on screen entry, not on exit."
  ~ [task.boilerplate] …N03-T02…: appears in 14 task files: "A rule that drops to merely
      *documented* has been deleted, whatever the prose says."

------------------------------------------------------------------------
SUMMARY: 35 epics, 240 tasks, 0 failures, 8 warnings — PASS
EXIT=0
```

`python3 tool/validate_skills.py` → `PASS with warnings — 24 skills, 0 failures, 11 warnings,
listing 6234/8000 chars`. Its warnings are pre-existing and about skill-body length, not about this
backlog.

### The five preserved elements, re-verified independently

The validator's section check is a substring test and could in principle be satisfied by a heading
inside a code fence. A second script was written that does not share a line of code with it, and
checks the five elements structurally — anchored regexes at line start, a real `test/` or
`integration_test/` `.dart` path, a runnable command **inside** the TDD section, and the ordering
`/simplify` < `/code-review` < `**Commit**`:

```
task files checked: 240
ALL FIVE PRESERVED ELEMENTS PRESENT IN EVERY FILE
```

Specifically, in all 240 files:

1. `**Epic**`, `**Task**`, `**Depends on**` and `**Commit**` header rows, the commit row carrying a
   conventional-commit message in backticks;
2. `- **File** — \`test/…\`` matching a real `.dart` path · `- **Test** — '…'` · `- **Why it is red
   today** — …` · the words *"confirm it fails"* · a runnable `bash` block in the TDD section ·
   `**Green.**` · `**Refactor.**`;
3. a Skills-to-load table, ≤ 3 rows, ≤ 2 auto-firing, **zero** names outside the 24;
4. a Definition of Done with ≥ 3 `- [ ]` items (the corpus median is 8);
5. `/simplify` then `/code-review` then `/shed-code-review` then `**Commit**`, in that order.

**Nothing had to be restored.** No file had lost one of the five during the deepening; the eleven
`N06` files had *misnumbered* four of them, which is §3.1, not a loss.

---

## 6. The eight warnings, and why they are still there

These are the sentences that repeat across more than five task files. They are not the failure mode
the brief describes — none of them defers, all of them state a rule the reader can act on — but they
are also not task-specific, and it would be dishonest to suppress the check that finds them. Every
one lives in **`## 6. Constraints that bind this task`**, which is by design the project's binding
constraint list restated per task.

| Files | Sentence | Judgement |
|---:|---|---|
| 239 | *"The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name."* | **Keep.** The vocabulary rule applies to every commit in the project. Varying the phrasing 239 ways would make it harder to check, not easier to read |
| 78 | *"There is no later sweep that adds them; N33 only verifies."* | **Keep.** Load-bearing and frequently disbelieved: developers assume an accessibility sweep will tidy up after them. It will not |
| 73 | *"G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence."* | **Keep.** The offline-purity contract, checkable in one command |
| 72 | *"— every string in `app_en.arb` with a `description`, every element a `semanticLabel`…"* | **Keep.** The ARB rule, and the one most often skipped |
| 37 | *"— every interactive element ≥ 64 × 64 …, 18 px text floor, dark only, and none of the banned gestures…"* | **Keep.** The 3am test, quoted with its numbers so no one has to go and look them up at 3am |
| 33 | *"No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`."* | **Keep.** Restated verbatim in every write-path task on purpose |
| 29 | *"— the row is created on screen entry, not on exit."* | **Keep.** Same |
| 14 | *"A rule that drops to merely *documented* has been deleted, whatever the prose says."* | **Keep.** The mechanism-hierarchy principle. It now follows a **specific** §12.x statement in every file that carries it — that was §3.4's work |

If the owner wants these varied per task too, the check already names every file and the change is
mechanical. This audit's position is that a **constraint checklist should be identical** — a checklist
you have to read differently each time is not a checklist — and that the boilerplate worth killing
was the kind that *pointed elsewhere*, which is now at zero.

---

## 7. Can a developer start any task in this backlog cold?

**For 236 of the 240, yes.** Read the file, run the one command in §4, watch it go red for the stated
reason, and start. The evidence, not the assertion:

- **The test is named, not described.** Every anchor is a property with a real path — e.g.
  `test/policy/withdrawal_has_no_default_test.dart` · `'no literal withdrawal day count appears
  anywhere under lib/'` — with why it is red today and a `fvm flutter test <path>` you can paste.
  Several go further and tell you how to make it red *honestly*: `N05-T04` has you plant
  `const kDefaultWithdrawalDays = 7;`, watch the scan name that file and line, and delete it before
  writing a fix, on the grounds that *"a scan that has never been seen to fire is indistinguishable
  from a scan that asserts nothing."*
- **The files are enumerated in `00-README` §8 order, with what changes in each and why** — and the
  ones that are *not* touched are enumerated too, with the reason. `N05-T04` spends three bullets on
  why there is no `check_policy.dart` row, no allowlist line and no `test/support/` helper.
- **The traps are named as found, not theorised.** The joined-string-literal trap that breaks a naive
  `text.contains`; `AudioRecorder` vs `Record`; `AudioEncoder.opus` producing OGG on Android and CAF
  on iOS so a cross-platform restore fails; `intl` with a null locale silently producing `en_US` in a
  background isolate; `AutoDisposeNotifier` vs `Notifier` and the analyzer message that points at the
  bound instead of the fix.
- **Disagreements between authorities are resolved in writing, with the losing document named.** P2
  supersedes `06 §10.3`'s printed `showSnackBar` body. P8 abolishes `07 §5.4`'s and `12 §10.1`'s
  five-button chooser, and `N16-T02a` exists solely to strike the decision row *with its reason* and
  add the policy test. A developer who reads a document and finds it contradicted knows which one
  wins and where the ruling is.
- **The Definition of Done is checkable from the diff or a command.** Median 8 items; `N26-T04` has
  20, including *"`EntryContext.deliberate` appears nowhere in `lib/`, `test/` or `docs/`"* and
  *"`drift_schemas/` is untouched"*.

**The four qualifications, stated plainly:**

1. **`N00-T02`, `N00-T04`, `N00-T05` and `N00-T09` cannot be started cold by anyone but the owner.**
   They are ruling tasks — they close open questions about dependencies, schema shape, `struck` /
   `struck_at`, and store accounts. That is correct sequencing, not a defect, but a contractor
   handed `N00-T04` will get as far as needing a decision only the owner can make.
2. **Three test anchors point at files the Flutter SDK owns, not this repo** — `N33-T02` and
   `N33-T04` read `packages/flutter_test/lib/src/accessibility.dart` and
   `packages/flutter/lib/src/widgets/_accessibility_evaluations.dart` to justify a constant. They are
   cited correctly and one is verified by a `grep` over `$FLUTTER_ROOT` in the Verification block, but
   they will drift on a Flutter upgrade and nothing in the backlog watches them.
3. **Ruling R1 is still open** and every file therefore runs *both* `/code-review` and
   `/shed-code-review`. That is one redundant review pass per task, 240 times. The blockquote in
   every §9 says exactly what to delete when the owner rules, and
   `REQUIRE_BUNDLED_CODE_REVIEW` / `REQUIRE_PROJECT_CODE_REVIEW` in `tool/validate_epics.py` are the
   two constants to flip.
4. **The eight repeated constraint sentences in §6 are real repetition** even though this audit
   judges them correct. A reader who reads §6 of ten consecutive files will start skipping it, and
   the day one of those files needs a *different* constraint is the day that habit costs something.
   `N06-T04` is now the counter-example worth copying: it says *"none of the five safety rules is
   held in this task, and the commit message says so."*

**What would still improve it most**, in order: close R1 and delete 240 redundant review steps; get
the owner through `N00`'s four ruling tasks before anyone else starts; and make §6 of each file name
which constraints are *not* engaged, the way `N06-T04` now does — that is the last place where a
reader can be told something true and unhelpful at the same time.
