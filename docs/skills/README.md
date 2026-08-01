# The Shed Book skill set

**24 skills — 19 engineering, 5 design. 20 auto-triggering, 4 manual-only runbooks.**

They live in [`.claude/skills/<name>/SKILL.md`](../../.claude/skills), project scope, committed to the
repo. They are the distilled, loadable form of the doc set: `docs/engineering/` (14 documents,
~22,700 lines), `docs/design/indelible.md` and `docs/research/00-tech-decisions.md`. **The documents
are BINDING and outrank every skill.** A skill states a rule, cites the owning document and ruling
number, and names the file where the value lives — it never transcribes one, because a transcription's
only two possible states are "identical" and "wrong".

| Artefact | What it is |
|---|---|
| [`02-build-manifest.md`](02-build-manifest.md) | The build spec: why 24, the budget arithmetic, the per-skill brief, the owner rulings. **Amending a skill amends this.** |
| [`00-catalogue.md`](00-catalogue.md) · [`01-catalogue-critique.md`](01-catalogue-critique.md) | Superseded by the manifest. Kept for the reasoning, not the counts (30 and 31 skills). |
| [`audit/`](audit) | Four post-build audits: `a1` triggers and budget · `a2` duplication and staleness · `a3` technical correctness · `a4` mechanical validation. |
| [`research/`](research) | How skills are authored on this platform. Governs these 24; says nothing about the app. |
| [`../../tool/validate_skills.py`](../../tool/validate_skills.py) | The checker. Stdlib only, exit-code driven. |
| [`../../CLAUDE.md`](../../CLAUDE.md) | What must be *present* rather than consulted — the four non-negotiables, the vocabulary, the pinned stack, the routing line. |

## How a skill loads

Claude Code reads every skill's **name and description** into context at session start — that is the
*listing*, and it is the only thing the model sees until a skill is chosen. Two paths in:

1. **Auto-trigger.** The model matches the request against the descriptions in the listing. This is why
   a description is trigger vocabulary rather than a summary: a skill whose description does not contain
   the words a developer types cannot fire, however good the body is.
2. **`/<name>`.** The developer invokes it explicitly. Always available, listing or no listing.

A skill with **`disable-model-invocation: true`** is kept out of the listing entirely — its description
costs no budget, it can never auto-fire, and `/<name>` is the only way in.

Once a skill is selected its `SKILL.md` body loads and stays for the session. Bundled
`references/`, `examples/` and `scripts/` files load **only** when the body's stated load condition is
met ("read X *when* Y"), which is what keeps a 200-line skill from costing 600.

## The full set

Size by body length: **S** ≤ 100 · **M** 101–200 · **L** 201+ lines. Ships: `ref` = `references/` ·
`ex` = `examples/` · `scr` = `scripts/`.

### Engineering — 19

| Skill | Kind | Size | Owns | Ships |
|---|---|---|---|---|
| `shed-conventions` | engineering | M 142 | The `lib/` tree · the eight layer rules and two path-pair bans as one table · naming shapes for file, class, repository, gateway, screen, controller, provider, widget key, column · policy rule id format · banned suffixes | — |
| `shed-dependencies-and-toolchain` | engineering | M 161 | Whether a package may enter at all and at what pin · `pubspec.yaml`, `analysis_options.yaml`, the `Makefile` · gates G2 and G3 · **the gate-integrity rule** | `ref` gate-failures.md |
| `shed-bootstrap-and-errors` | engineering | M 101 | `main()` awaits nothing and the install order · `app.dart` · the first painted frame · the global error net and `shedFailureFrom` · `LocalLog` · lifecycle, resume, the clean pause and a dirty resume | `ex` main.dart |
| `shed-riverpod-providers` | engineering | L 217 | The 2.6.1 pin and every banned 3.x API · provider shapes and disposal · the DI graph · **one drift statement per screen** · `.select` and rebuild scope · the one ticker · `WriteController.guard()` · R53 | `ref` riverpod3-symptoms.md |
| `shed-write-path` | engineering | M 150 | Event verbs, `beginLambing` and `addLamb` first · the row commits on **screen entry, not exit** · `appNow()` once per mutation · one transaction · `WriteOutcome` · the `lib/data/` → `lib/domain/validation/` import ban | `ex` foster_verb.dart |
| `shed-drift-schema` | engineering | L 217 | `STRICT`, FKs with explicit `ON DELETE` and hand-written indexes, `CHECK`s · dual-key ids · time and unit encoding · the provenance quad · the active-only partial index on `tag` · FTS5 · `seedFirstRun` · **and `make gen`** | `ref` storage-decisions.md |
| `shed-domain` | engineering | M 120 | Pure Dart and the import ban · `now` is always a parameter · `Instant`, `LocalDate`, `Grams`, `MilliCelsius`, `RecordedTime` · every statistic's edge cases and `notComputableReason` · the UK ambiguous hour | `ref` statistics.md |
| `shed-withdrawal` | engineering | M 129 | Never defaulted, suggested, pre-filled or copied · the sealed type and its one entry point · **absent row means not recorded, never zero** · ceil-to-next-local-midnight and the DST cases · `REPEAT LAST TREATMENT` leaves the days blank | `ex` clear_date.dart · `ex` clear_date_dst_test.dart |
| `shed-safety-rules` | engineering | M 172 | The five rules **as mechanisms and their level** in the hierarchy · the §12.2 origination line · *a rule that has dropped to merely documented has been deleted* · a table without the provenance quad has no edit verb | — |
| `shed-screens-and-routing` | engineering | L 260 | The one query that feeds a screen · every state · the tap budget · **undo and delete per verb — sole owner**, window in seconds · the export prompt · `RouteNames` / `Routes`, Navigator 1.0 · **the ordered add-a-screen pipeline** | — |
| `shed-accessibility-and-copy` | engineering | L 241 | Semantic labels, headings, live regions · 200% text scaling · motor accessibility · the ship gate · every string through ARB with a `description` · en_GB date, number and unit formats · provenance on every displayed time | `ref` semantics-recipes.md |
| `shed-platform-gateways` | engineering | M 191 | The gateway pattern and its seven hand-written fakes · `reconcile()`, channels, exact alarms, reboot and DST · capture, share, import, wakelock · the per-plugin permission policy holding the manifest at **exactly eight entries** | `ref` notifications.md |
| `shed-export-and-restore` | engineering | M 199 | The three CSV shapes, the PDF, the JSON envelope · **every export carries `struck` / `struck_at` and every struck row is included and marked** · the safety footers · media layout and relative paths · orphan sweeps · atomic restore · `tool/seed.dart` | `ref` restore-and-sweeps.md · `ex` lambs.csv |
| `shed-monetization` | engineering | M 176 | The one non-consumable unlock · the entitlement row and its three rules · `PurchaseService`, `FreeTierPolicy.decide` · the four upgrade-affordance constraints · store declarations · **the price is never a literal** | — |
| `shed-testing` | engineering | L 216 | The five tiers · fixed time and the `uk-zone` tag · the in-memory drift harness · the seven fakes · `pumpApp` · the overflow matrix, count **derived not typed** · **every executable gate** · golden *policy* · **the `--update-goldens` prohibition** | `ref` harness.md |
| `shed-migrations` | **runbook** | M 131 | The hand-written forward-only additive `from<N>To<N+1>` step · `drift_dev schema steps` · the committed snapshot and test helpers · extending the from→to `SchemaVerifier` matrix | `ex` migration_step.dart |
| `shed-release` | **runbook** | M 185 | Gates G0–G5 against a real release bundle · the eight-entry permission set · signing and the off-machine symbols archive · size and startup budgets on two real devices · versioning · the closed track · the 1 Feb – 30 Apr freeze | `ref` pre-release-checklist.md |
| `shed-goldens-rebaseline` | **runbook** | S 97 | Loading the real bundled fonts so nothing renders in Ahem · the tolerant comparator · `make goldens-update` · inspecting every changed image by eye · landing the PNGs as their own commit | — |
| `shed-code-review` | **workflow, manual** | M 124 | The read order by irreversibility · saying nothing about what CI already proves · the five §12 rules as questions · the one Quick Entry question · the never-waved-through list | — |

### Design — 5, all from `indelible.md`

| Skill | Kind | Size | Owns | Ships |
|---|---|---|---|---|
| `indelible-design-system` | design | L 242 | **The front door.** The four rules · serif is the record, sans is the control · the whole palette and the measured floors (4.5:1 text, 3:1 rules and marks) and the two placement rules · red-shift · the type scale, weights, tabular figures, 200% · **the complete gesture ban** · motion and haptics · what the system does not have · the ten acceptance tests | `scr` contrast.py |
| `indelible-page-and-screens` | design | L 201 | The spine, the 68 × 64 margin cell that is itself a target, the record column · the ten-step spacing scale · row heights · **the 64 × 64 target floor and the minimum-target audit** · the three reach bands and the 560px binding rule · the left-handed mirror · growth at 200% without the grid moving · the twelve screens as filters of one document, plus note search | — |
| `indelible-controls` | design | L 204 | All six pressable forms plus the sheet · the corner slab, word button and `INDEX` · the keypad key, ease group, stepper, ruled field and check control · **there is never placeholder text inside a field** · the stepper that replaces every slider · the photo and voice-note capture surfaces | — |
| `indelible-marks-and-strikes` | design | L 249 | Rule 1 — nothing is removed, only struck · the six marks and their geometry · the 2px rule, 3px strike, doubled and dotted rules · boxed vs unboxed stamps · the two-non-colour-channel table · **struck rows stay where they were, at full legibility, in every list and export, forever** · the query mark and the rule that the app never picks · the tallies and the chart | — |
| `indelible-states-and-feedback` | design | L 213 | Frame 1 before data lands · empty and filtered-empty · the error panel · **the save receipt** · the once-a-day export prompt line · the two static upgrade rows · the unset-cell gap · no spinner, no skeleton, no toast, no modal | — |

## Intent → skill

**At most two auto-firing skills per intent.** Where a task genuinely spans more, the owning skill
carries the ordered pipeline and names the next skill to load, one at a time. A skill that expects three
others to be loaded alongside it is mis-scoped. The same table, compressed, is in `CLAUDE.md`.

| Developer intent | Resolves to |
|---|---|
| Any pixel, colour, hex, contrast ratio, token, font, size, weight, spacing, gesture, motion or haptic | `indelible-design-system` — the design front door |
| Any file, class, provider, key or column name; whether one folder may import another | `shed-conventions` — the code front door |
| "add a screen" | `shed-screens-and-routing` **→ then** `indelible-page-and-screens` |
| "add a button" / "the ease buttons" / "a segmented control" | `indelible-controls` (+ `indelible-design-system` for the voice and the token) |
| Compose a page; any padding, gap, width, height or target size | `indelible-page-and-screens` |
| "record a lambing" / "log a treatment" / any Save button, draft or dirty flag | `shed-write-path` (+ `shed-withdrawal` when it is a treatment) |
| "the tally" / "the birth type" / a strike, delete, hide, mute or edit | `indelible-marks-and-strikes` — *derived, never chosen* |
| "add undo" | `shed-screens-and-routing` — sole owner of the per-verb window |
| "show a confirmation" / "add a snackbar" / "the empty state" / "a spinner" | `indelible-states-and-feedback` |
| "add a column" (store) vs "name this column" (spelling) | `shed-drift-schema` vs `shed-conventions` |
| "run codegen" / "make gen" / a regenerated `.g.dart` | `shed-drift-schema` |
| "the clocks changed and the time is wrong" / any statistic or date arithmetic | `shed-domain` |
| Medicines, doses, batch numbers, withdrawal days, clear dates | `shed-withdrawal` |
| "never silently correct that" (mechanism) vs what the shepherd sees | `shed-safety-rules` vs `indelible-marks-and-strikes` |
| "janky at 400 ewes" / any provider, `ref.watch`, `AsyncValue`, rebuild scope | `shed-riverpod-providers` |
| `main.dart`, `app.dart`, exception mapping, lifecycle, resume, white flash, slow start | `shed-bootstrap-and-errors` |
| "add a label" / "rename this string" / a date or number format | `shed-accessibility-and-copy` |
| "fix the contrast" (the value) vs "the contrast test fails" (the assertion) | `indelible-design-system` vs `shed-testing` |
| Any test, flaky test, or failing tap-target / semantics gate; "the golden is red" | `shed-testing` — which refuses `--update-goldens` |
| "add a package" / "pub add" / "let's use fl_chart" / a red gate | `shed-dependencies-and-toolchain` |
| Wrapping an approved plugin, `AndroidManifest.xml`, `Info.plist`, a reminder, a permission | `shed-platform-gateways` |
| CSV, PDF, JSON backup, import, restoring a **backup file** | `shed-export-and-restore` |
| Price, purchase, restoring a **purchase**, entitlement, unlock, the cap | `shed-monetization` |

## The four runbooks

They carry `disable-model-invocation: true`, so **they never auto-fire and their descriptions cost no
listing budget**. Each names an irreversible side effect, which is why it waits to be asked for by name.

| Invoke | Because it |
|---|---|
| `/shed-migrations` | creates a schema snapshot that is irreversible once committed |
| `/shed-release` | builds, signs and tags |
| `/shed-goldens-rebaseline` | overwrites committed reference images |
| `/shed-code-review` | is the project's review, and would otherwise lose a name-space contest with Claude Code's bundled `/code-review` |

Two consequences that are load-bearing:

- **A runbook cannot protect you.** The `--update-goldens` prohibition therefore lives in
  `shed-testing`, which *can* auto-fire, not in `shed-goldens-rebaseline`. Likewise `make gen` lives in
  `shed-drift-schema`, not in `shed-migrations` — otherwise an agent adding a column is told by the
  skill it correctly loaded not to run the one command that makes the change valid.
- `CLAUDE.md` carries the standing line *"before claiming work is complete, run `/shed-code-review`"*,
  so the instruction is present even though the body is not.

## Validating the set

```bash
python3 tool/validate_skills.py            # exit 0 clean or warnings, 1 on a failure, 2 no skills root
python3 tool/validate_skills.py <dir>      # point it elsewhere, e.g. at a broken fixture
```

Current state: **24 skills, 0 failures, 11 warnings, listing 6,234 / 8,000 chars.**

| Threshold | Value | What it means |
|---|---|---|
| `DESCRIPTION_MAX_CHARS` | 1024 | Platform limit. Failing it is fatal. |
| `NAME_MAX_CHARS` | 64 | Platform limit; `name` must equal the directory name, be kebab-case, and contain neither `anthropic` nor `claude`. |
| `BODY_WARN_LINES` / `BODY_FAIL_LINES` | 200 / 500 | 500 is Anthropic's documented ceiling. **200 is this project's own target**, set just above the ~132-line median of Anthropic's shipped skills so growth is visible. Ten skills sit at 201–260 — a signal to watch, not a queue of work. |
| `LISTING_WARN_CHARS` / `LISTING_FAIL_CHARS` | 6000 / 8000 | 8,000 ≈ 2,000 tokens ≈ `skillListingBudgetFraction` **0.01** of a 200k context. On overflow Claude Code **silently drops descriptions**, starting with the least-invoked skills, and the symptom is "my skill stopped triggering" with nothing changed in the file. |
| `REFERENCE_TOC_LINES` | 100 | A reference over 100 lines needs a table of contents. |

It also fails on: an unquoted inline value containing `": "` (real YAML rejects it, and Claude Code
answers by loading the skill with **empty metadata** — `/name` still works and auto-trigger is silently
dead forever), a duplicate frontmatter key, a first- or second-person description opener, a supporting
file on disk that no `SKILL.md` names, a named file that does not exist, a backslash acting as a path
separator, a `Do NOT` pointer at a skill that does not exist, an empty directory, and a stray file at
the skills root. Unknown frontmatter keys **warn** rather than fail, because the field set is versioned
by the Claude Code release and a typo is indistinguishable from a new field.

The checker is not vacuous: it was run against two deliberately broken fixtures and all 22 failure modes
fired (`audit/a4-validation.md` §7). It is also not the whole story — `claude plugin validate` is the
authority on YAML parseability, and `/doctor` plus the **Skills** row of `/context` is the authority on
what the listing actually costs at runtime.

## Adding a skill

### 1. Write the description to the rule

> **A description is identity + triggers + one negative. If a clause describes contents, delete it —
> the body is where contents live, and the body is free.**

That rule is what took the first catalogue from 20,750 characters to 5,750: the originals were ~70%
"here is what I contain". Also required, each with a failure behind it:

- **No colon anywhere in the value.** Invalid YAML → empty metadata → auto-trigger silently dead. Use
  em-dashes and parentheses.
- **Third person.** The description is injected into the system prompt; "You can use this to…" is a
  documented discovery problem. (The bodies may say "you".)
- **Literal trigger vocabulary — the words a developer actually types.** Six skills in this set could
  not fire before `a1` fixed them: the owner of the contrast floors never said *contrast*; the owner of
  the ambiguous-hour model never said *DST*; the write path never said *lambing*.
- **End with `Do NOT use for … (real-sibling-skill-name)`, and make it reciprocal.** The sibling names
  you back. A boundary stated from one side only is not a boundary — that is what `a1` intent 2 found.
- **Only `name`, `description`, and `disable-model-invocation` on the four runbooks.** No `version`, no
  `tools`, no `when_to_use`, and **no `paths:`** — `paths` limits activation to files already in play,
  and every skill here must fire *before* the file exists.
- **Front-load the body.** Only the first ~5,000 tokens survive auto-compaction. Non-negotiables at the
  top.
- **Every `references/` link carries a load condition** — *"read X **if/before** Y"*. `"see
  references/…"` is the documented anti-pattern.

### 2. Do the budget arithmetic before you write the body

```
Budget  B  = 8,000 chars      (skillListingBudgetFraction 0.01 × 200k ctx ≈ 2,000 tokens)
Listing    = every skill's NAME + every AUTO-TRIGGERING skill's DESCRIPTION

  24 names                             484
  20 listed descriptions             5,750   (mean 288, min 172, max 391)
  ─────────────────────────────────────────
  current                            6,234   ✅ 1,766 under the ceiling, 22% headroom
  4 manual descriptions excluded     1,561   (kept out of context by the platform)
```

A new **listed** skill costs `len(name) + len(description)` ≈ **300 chars**, so about five more fit
before the real ceiling — but the project's own 6,000-char warn line is *already crossed*, so plan to
pay for a new skill rather than assume the space exists. A new **runbook** costs only its name (~20
chars): if the work is a procedure a developer asks for by name, that is the cheap door.

Where to take space back, in order: the longest listed descriptions —
`shed-platform-gateways` (391), `indelible-design-system` (371), `shed-dependencies-and-toolchain` (367),
`shed-drift-schema` (344), `shed-write-path` (320). **Do not trim the four runbook descriptions** — the
checker now excludes them, so they cost nothing and shortening them only makes a manual invocation
harder to choose. (`audit/a4` §5 recommended exactly that trim; it was written against an earlier
checker that charged for them. It no longer recovers anything.)

Raising `skillListingBudgetFraction` to `0.02` in `.claude/settings.json` is a *second margin*, never the
thing that makes the arithmetic work — a set that only fits at `0.02` breaks silently in a fresh clone or
a cloud session.

### 3. Run the collision check

1. **Grep your trigger nouns across the set** and read every hit as the model reads it — description
   only, no knowledge of this file:
   ```bash
   grep -rn --include=SKILL.md -iE 'your|trigger|nouns' .claude/skills/
   ```
   If another description matches the same intent, either the two are complementary layers (fine — say
   so in both `Do NOT`s) or one of you is wrong about what you own.
2. **Write the reciprocal negative in both files.** One-sided negatives are how `a1` intents 2 and 4
   failed.
3. **Add a row to the manifest's §7.3 acceptance test** — the intent, the skill that must own it — and
   run it as three near-miss prompts in a *fresh* session. Near-misses, not obvious irrelevancies, are
   the whole game; leftover context in the authoring session masks exactly the gaps you are looking for.
4. **`python3 tool/validate_skills.py`**, then `/doctor` and the **Skills** row of `/context`. If the
   measured listing exceeds the ceiling, the fix is to shorten a description, not to raise the fraction.
5. **Update [`02-build-manifest.md`](02-build-manifest.md) §1 (arithmetic), §3 (the table) and §7.3 in
   the same commit.** A skill whose description no longer matches its row there is worse than a missing
   skill.

## What is deliberately not a skill

| Content | Where it lives instead | Why |
|---|---|---|
| The four non-negotiables, the one-word-per-concept vocabulary and banned words, the pinned stack, the intent routing table, the standing `/shed-code-review` line, the P2 and P8 rulings | [`../../CLAUDE.md`](../../CLAUDE.md) | They must be **present**, not consulted. A one-step request may trigger no skill at all; it can still break all four. The routing table in particular cannot live in a skill — a router loses every listing contest with a specific skill. |
| `dart format` and `check_policy` after every edit · blocking `--update-goldens` · blocking edits to `android/expected_permissions.txt` · the `pubspec.yaml` / `pubspec.lock` pairing check · `validate_skills.py` pre-commit | `.claude/settings.json` hooks — **specified in manifest §6.2 and not yet written** | A rule that must fire on every edit must not depend on a model loading a skill. |
| The decision record's reasoning and its ~40 rejected packages with alternatives | `docs/research/00-tech-decisions.md` | Distilling it creates a second authority that drifts. §5 is the only source of a version number. |
| The thirteen open questions and the owner rulings | `docs/research/` and manifest §4 | They change, and a document is read by a human who can see the date. |
| The twelve screen briefs verbatim and every §-numbered rationale in `01`–`13` | `docs/engineering/` | Skills cite them per screen and per ruling number; copying them is the staleness failure `a2` found in 21 places. |
| `docs/design/the-register.md` and `strip-bay.md` | Nowhere reachable | **No skill may cite, mention or borrow from them.** The point of one design system is that the alternatives are unreachable. The single graft — the *persistent loaded subject* — is Indelible's now and is **never attributed**. |
| The four skill-authoring research notes | [`research/`](research) | They govern how these 24 are written, not how the app is built. |

## Known state

- **`a4`'s headline figure is superseded.** It reported 7,795 chars against the listing budget; the
  checker has since been corrected to exclude manual-only descriptions, and the true cost is **6,234**.
  Everything else in the four audits stands.
- **Ten body-length warnings (201–260 lines)** are left standing deliberately. The ceiling is 500 and
  every skill is under half of it.
- **P1 is unruled** — `struck` / `struck_at` on every table is schema-irreversible. `shed-drift-schema`,
  `shed-export-and-restore` and `indelible-marks-and-strikes` all carry it as blocking.
- **P3, P7, P9, P10 and P14 are carried as open**, each named in exactly one owning skill with both
  sides cited and neither picked. That is correct, not a defect.
- **`.claude/settings.json` does not exist yet**, so none of manifest §6.2's six hooks is wired.
