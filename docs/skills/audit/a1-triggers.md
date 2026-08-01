# A1 — Triggers, budget and frontmatter validity

Audited **2026-07-28** against `../research/01-skill-mechanics.md`, `../research/02-authoring-quality.md`
and `../02-build-manifest.md` §3.3. Scope: the 24 `SKILL.md` frontmatter blocks in
`.claude/skills/`. **Every fix in this document is already applied to the files.** Bodies were not
edited under this lens.

---

## 1. Frontmatter validity — 24/24 pass after one fix

Checked mechanically (`name` vs directory, kebab-case, ≤64 chars, reserved words `anthropic`/`claude`,
`description` non-empty and ≤1024, XML tags, colons, unknown keys, `when_to_use`, first/second person,
runbook flag).

| Rule | Result |
|---|---|
| `name` equals directory name | 24/24 |
| `name` kebab-case, no `--`, no leading/trailing hyphen, ≤64 (longest 31) | 24/24 |
| `name` contains no reserved word | 24/24 |
| `description` non-empty, ≤1024 (longest 431 → now 391) | 24/24 |
| No XML tags, no colon (a colon in a plain scalar loads the skill with **empty metadata**) | 24/24 |
| No `when_to_use`, no unknown keys — only `name`, `description`, `disable-model-invocation` | 24/24 |
| `disable-model-invocation: true` on exactly the four runbooks, and on nothing else | 4/4 correct |
| `description` free of first/second person | **1 violation, fixed** |

**The one violation.** `indelible-design-system` read *"serif means it happened and sans means **you
press it**"*. The platform validator's rule is *"Always write in third person… Avoid: 'You can use
this to…'"* — the description is injected into the system prompt, and point-of-view drift there is a
documented discovery problem. Rewritten to *"sans means **it is pressed**"*. The body still says
"a thing you can press"; that is fine, only the description is injected.

**Runbooks are correct.** `shed-migrations`, `shed-release`, `shed-goldens-rebaseline` and
`shed-code-review` carry the flag; each names its irreversible side effect (*"creates a schema
snapshot"*, *"builds, signs and tags"*, *"overwrites committed reference images"*) and says it runs
only when asked for by name. No listed skill carries the flag.

**Observation, not a defect.** 20 of 24 descriptions open with a noun phrase (*"The page every screen
is —"*) rather than the platform's model third-person verb phrase (*"Processes Excel files"*). The
four runbooks do open with verbs (*Writes*, *Cuts*, *Re-baselines*, *Reviews*). Noun-phrase openings
violate no stated rule and are not first- or second-person, so they were left alone rather than
churned across 20 files at real budget cost.

---

## 2. The listing budget

`skillListingBudgetFraction` defaults to `0.01` — 1% of the context window. At 200k that is
~2,000 tokens ≈ **8,000 characters**. `disable-model-invocation: true` *"removes the skill from
Claude's context entirely"*, so the four runbooks cost **zero**.

| | Before | After | Δ |
|---|---:|---:|---:|
| Listed descriptions (20 skills) | 5,557 | **5,750** | +193 |
| Manual-only descriptions (4, cost zero) | 1,561 | 1,561 | 0 |
| All 24 descriptions | 7,118 | 7,311 | +193 |
| Listed names | 418 | 418 | 0 |
| **Exact model** (desc + names + 10/row scaffold) | 6,175 | **6,368** | +193 |
| **Conservative model** (desc + 40/row, critique §1.1) | 6,357 | **6,550** | +193 |
| Headroom against 8,000, exact | 22.8% | **20.4%** | −2.4pt |
| Headroom against 8,000, conservative | 20.5% | **18.1%** | −2.4pt |

**The total never exceeded the budget, so nothing was shortened for budget reasons.** Shortening was
still done — to *pay for* the trigger fixes below. Contents inventory was cut from nine descriptions
(the manifest §1.4 rule: *"if a clause describes contents, delete it"*), funding new trigger
vocabulary and four new reciprocal negatives at a net cost of 193 characters.

Cuts: `shed-monetization` −102 (dropped the entitlement-row / seam / cap inventory that the trigger
list already carries), `indelible-controls` −75, `indelible-design-system` −33 net of additions,
`indelible-page-and-screens` −44 net, `indelible-marks-and-strikes` −24, `shed-testing` −8,
`shed-export-and-restore` −14, `shed-drift-schema` and `shed-platform-gateways` partially self-funded.

**Honest note on the ceiling.** The manifest set itself a 20%-headroom ceiling of **6,400**. The
exact model lands at 6,368 (**under**); the conservative model lands at 6,550 (**150 over**, 18.1%
headroom). The conservative model's flat 40 chars/row for name + scaffold is an assumption, not a
measurement — the measured names average 20.9 chars. I judged 150 characters of a self-imposed margin
a fair price for closing six intents that fired on nothing or fired on the wrong skill; the real
cliff is 8,000 and we are 1,450 clear of it on the pessimistic model. If a later skill is added, take
the space back from `shed-release`-style prose in the four runbooks first — they cost zero, so trim
them last, not first — and then from `shed-riverpod-providers` (301) and `shed-conventions` (262).

---

## 3. Trigger simulation — 14 intents

"Fires" = the description contains vocabulary the intent would match. This is analytic, not an
executed eval; §6 says what that does and does not prove.

| # | Intent | Fires **before** | Fires **after** | Verdict |
|---|---|---|---|---|
| 1 | *"add a button"* | `indelible-controls`, `indelible-design-system` | same | **Agreed.** Two skills, complementary layers: design-system fixes the voice and the token before a size exists; controls owns the anatomy. No contradiction. |
| 2 | *"add a screen"* | `shed-screens-and-routing`, `indelible-page-and-screens` | same | **Was a defect — fixed.** The boundary was stated from one side only: routing said *"not how it is drawn (indelible-page-and-screens)"*, and page-and-screens answered by pointing at `indelible-marks-and-strikes`. Page-and-screens now says *"Do NOT use for what a screen shows or how it is reached (shed-screens-and-routing)"*. `indelible-design-system` is held to two by its own *"or the data on a screen"* negative. |
| 3 | *"add a column"* | `shed-drift-schema`, `shed-conventions` | same | **Agreed.** Already a clean reciprocal pair — *"not what a column stores"* ↔ *"not a column's spelling"*. `shed-migrations` cannot fire (manual), which is deliberate; drift-schema's negative names it so the agent knows a migration exists. |
| 4 | *"add a package"* | `shed-dependencies-and-toolchain`, `shed-platform-gateways` | same | **Was a defect — fixed.** Both fired on *plugin* and neither named the other; deps pointed at `shed-release`, gateways at `shed-export-and-restore`. Boundary now stated from both sides: deps *"decides whether a package may enter this app at all and at what pin… Do NOT use for wrapping an approved plugin or its permissions"*; gateways *"wraps an already-approved plugin… Do NOT use to decide whether a package may be added at all"*. |
| 5 | *"write a test"* | `shed-testing` | same | **Clean.** One skill. `shed-goldens-rebaseline` is manual so it cannot contest, and testing's own text carries the `--update-goldens` prohibition. |
| 6 | *"record a lambing"* | **nothing reliable** | `shed-write-path` | **Was a defect — fixed.** No description contained *lambing*, *lamb*, *ewe* or *record*; write-path said only *"storing any fact"*, which is the documented "too abstract to fire" failure. It now says *"Use when recording a lambing, lamb, weight, treatment or note"* — the two verbs that are the product (`beginLambing`, `addLamb`) are what the body is mostly about. |
| 7 | *"fix a contrast problem"* | `shed-testing`, `shed-accessibility-and-copy` (in its *negative*) | `indelible-design-system`, `shed-testing` | **Was a defect — fixed.** The owner of the contrast floors did not contain the word *contrast*; the only skills that did were the two that disclaim it. Design-system now carries *"contrast ratio… and when fixing a contrast failure"*. The value/assertion split (critique C7) is now stated from both sides: design-system *"Do NOT use for the gate that asserts a value (shed-testing)"* ↔ testing *"Do NOT use to choose a value (indelible-design-system)"*. |
| 8 | *"the pen board is janky at 400 ewes"* | `shed-riverpod-providers` | same | **Clean, on one word.** Fires on *jank* / *rebuild scope*, which is the right owner (one drift statement per screen, `.select`). *"pen board"* and *"400 ewes"* appear in no description — acceptable, since the generic word carries it. |
| 9 | *"change a label"* | `shed-accessibility-and-copy` | same | **Clean.** One skill; it owns both senses (visible string and semantic label). |
| 10 | *"undo a mistake"* | `shed-screens-and-routing` | same, strengthened | **Clean.** Write-path's negative routes here; marks-and-strikes owns the strike's *shape*, not its clock, and does not match this wording. Routing now adds *"and when undoing or deleting a record"* so the intent matches a use-clause, not just an identity clause. |
| 11 | *"log a treatment"* | `shed-withdrawal` | `shed-withdrawal`, `shed-write-path` | **Agreed, deliberately two.** Withdrawal owns the rule that days are never defaulted; write-path owns the verb and the transaction. The second skill is a gain: previously a treatment could be written with no write-path guidance in context. See §5 for the residual. |
| 12 | *"generate the CSV export"* | `shed-export-and-restore` | same | **Clean.** One skill; *CSV* is retained as a literal keyword. |
| 13 | *"run codegen"* | **nothing** | `shed-drift-schema` | **Was a defect — fixed.** No description contained *codegen*, *build_runner* or *.g.dart*; per critique R1 `make gen` is owned by drift-schema precisely so an agent adding a column is not told by a manual-only runbook to run it. Drift-schema now says *"the only skill that runs codegen… whenever make gen, build_runner or a regenerated .g.dart or .drift.dart file is involved"*. `shed-riverpod-providers` correctly stays silent — its body bans Riverpod codegen outright. |
| 14 | *"the app is showing the wrong time after the clocks change"* | **nothing** (weak match on *date arithmetic*) | `shed-domain` | **Was a defect — fixed.** *DST*, *daylight saving*, *timezone* and *clocks change* appeared in no description, though the DST rules are the highest-stakes arithmetic in the app. Domain now carries *"for a daylight-saving, DST, timezone, clocks-change or ambiguous-hour bug"*. The existing reciprocal pair holds the boundary: domain *"not clear dates (shed-withdrawal)"* ↔ withdrawal *"not general date arithmetic (shed-domain)"*. |

**Bonus collision found outside the 14, and fixed.** The bare word **restore** fired
`shed-export-and-restore` and `shed-monetization` equally, and the two would give opposite advice
(atomic replace-everything vs. asking the store a second time). Disambiguated in both directions:
monetization now says *"restoring purchases"*, export says *"restoring a backup file"* and adds
*"Do NOT use for restoring a purchase (shed-monetization)"*.

---

## 4. Skills that would never have fired

| Skill | Why it would not fire | Fix applied |
|---|---|---|
| `shed-write-path` | *"Use when storing any fact"* — abstract, and the app's own nouns were absent. | Domain verbs added (lambing, lamb, weight, treatment, note). |
| `shed-drift-schema` (for codegen) | Identity said *"Ends by running make gen"*, which is a contents claim, not a trigger; the words a developer types were missing. | *codegen*, *build_runner*, *.g.dart*, *.drift.dart* added; claim promoted to *"the only skill that runs codegen"*. |
| `indelible-design-system` (for contrast) | Owned the 4.5:1 and 3:1 floors, never said *contrast*. | *contrast ratio*, *font*, *gesture*, *motion*, *haptic* added as literal triggers. |
| `shed-domain` (for DST) | Owned the ambiguous-hour model, never said *DST*. | DST vocabulary added. |
| `shed-monetization` | Fired fine, but 62% of the description was inventory. | Cut to identity + triggers + negative (274 → 172). |
| `indelible-controls` | Fired fine; the inventory duplicated the trigger list, and *slider* was missing even though the stepper exists to replace sliders. | Inventory cut, *slider* and *stepper* added to the trigger list. |

---

## 5. What remains — not fixed, and why

1. **`shed-write-path` and `shed-withdrawal` have no reciprocal negative.** Both fire on *"log a
   treatment"*. They are complementary rather than contradictory (rule vs. mechanism), and adding two
   more negatives costs ~90 characters of a budget that is already 150 over the manifest's ceiling.
   Revisit if a trace shows one skill answering the other's question.
2. **`shed-bootstrap-and-errors` and `indelible-states-and-feedback` both fire on "handle this
   error"** and neither names the other — both point at `shed-write-path`. The boundary (failure
   mapping vs. the panel's words and pixels) is stated in both bodies but not in either description.
   Same reasoning as above; lower risk because the bodies route correctly on load.
3. **`indelible-marks-and-strikes` ↔ `shed-safety-rules` reciprocity is one-sided.** Marks names
   safety-rules; safety-rules names withdrawal. Critique C6 required the pair; only half of it is in
   the descriptions.
4. **`shed-drift-schema` may become a third skill on intent 14** via *"how time and units are
   encoded"*. Encoding vs. arithmetic separates them in practice, but no negative enforces it.
5. **Conservative listing model is 150 over the manifest's 6,400 ceiling** (§2). Under the real
   8,000 budget by 1,450.
6. **Domain-object vocabulary is still thin.** *pen board*, *quick entry*, *flock*, *ewe*, *tag* and
   *foster* appear in no description; those intents ride on generic verbs (*jank*, *screen*, *store*).
   Adding them is the next-cheapest triggering win if budget is freed.
7. **Bodies were not audited here.** Another lens owns them; body edits landed in these same files
   while this audit ran (see §6).

---

## 6. Method, and what this audit does not prove

Frontmatter validity and the budget arithmetic are **measured** — parsed with `yaml.safe_load`,
counted with `len()`, re-verified after every write.

The firing table is **analytic**: it reasons over the vocabulary each description contains against
the intent's likely wording. It is not the documented eval — ~20 labelled prompts, 8–10
should-trigger and 8–10 should-not-trigger, three runs each in **fresh sessions**, thresholded at 0.5
(research 02 §1.7). That method cannot be run from inside the authoring session, and leftover context
here would mask exactly the gaps it is meant to find. Treat "fires" as *"contains the words needed to
fire"*, which is necessary but not sufficient. The six fixed intents were verifiable in the strong
direction only: before the fix, the words were absent, so the skill provably could not match.

**Concurrency.** Another agent edited the bodies of at least `shed-riverpod-providers`,
`shed-drift-schema` and `shed-write-path` while this audit was running. Every frontmatter change here
was re-verified present after those writes. If a later session reports a missing description change,
it was clobbered by a concurrent whole-file write, not by this audit — re-apply from this document's
§3 table.
