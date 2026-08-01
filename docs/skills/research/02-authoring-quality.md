# 02 — What makes a Claude Code skill actually good

Research date: **2026-07-27**. Every structural claim below is quoted from a primary source fetched
on that date. Where sources disagree, the disagreement is shown rather than resolved silently.

**Important:** the docs moved hosts. `docs.claude.com/en/docs/claude-code/skills` now 301s to
`code.claude.com/docs/en/skills`, and `docs.anthropic.com/.../agent-skills/best-practices` 302s to
`platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`. There are now **three**
authorities with slightly different contracts:

| Authority | URL | Governs |
| --- | --- | --- |
| Agent Skills open standard | [agentskills.io/specification](https://agentskills.io/specification.md) | The portable file format |
| Anthropic platform (API / claude.ai) | [platform.claude.com/…/best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) | Authoring guidance, validation rules |
| Claude Code | [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) | Runtime behaviour, extra frontmatter |

We are writing **Claude Code project skills**, so Claude Code's runtime rules bind us — but write to
the *intersection* of all three so the skills stay portable and never trip a validator.

---

## Bottom line

| # | Rule | Why |
| --- | --- | --- |
| 1 | `description` is the entire trigger mechanism. Write it last, tune it hardest. | Only `name` + `description` are preloaded; the body never loads if the description doesn't match. |
| 2 | Description = *third-person statement of what it does* + *imperative "Use when…" clause naming concrete triggers*. | Platform docs mandate third person; agentskills.io mandates imperative "Use when". Anthropic's own skills do both in one field. |
| 3 | Keep `description` ≤ **1024 characters**. | Hard spec limit. Claude Code truncates the listing at 1,536 chars, but 1024 is the portable ceiling. |
| 4 | Be **pushy**. Claude under-triggers skills by default. | Anthropic's own `skill-creator` says so in as many words. |
| 5 | State **negative triggers** ("Do NOT use for…") when adjacent skills exist. | Every one of Anthropic's document skills does this. It is how you stop overlap. |
| 6 | SKILL.md body **under 500 lines** (spec also says < 5,000 tokens). | Stated in all three sources. Anthropic's own median skill is ~100–250 lines. |
| 7 | Everything over that limit goes in `references/`, and SKILL.md **must explicitly point at it with a load condition**. | The agent only reads a file if SKILL.md tells it the file exists *and when to read it*. |
| 8 | Reference links stay **one level deep** from SKILL.md. | Nested refs cause partial reads (`head -100`) and incomplete information. |
| 9 | Write only what the agent doesn't already know. Cut anything that fails "would removing this cause a mistake?" | Bloat causes the real rules to be ignored. |
| 10 | Prefer a **tested script** over prose whenever the operation is deterministic, repeated, or fragile. | More reliable, saves tokens, output-only context cost. |
| 11 | Say explicitly whether a script is to be **executed** or **read**. | Documented ambiguity failure mode. |
| 12 | Give **one default with an escape hatch**, never a menu of options. | Menus produce wandering and wasted turns. |
| 13 | A **gotchas** section is usually the highest-value content in the skill. | Named as such by agentskills.io; it is what Anthropic's `xlsx`/`docx` skills are almost entirely made of. |
| 14 | Explain **why** a rule matters instead of shouting MUST — but keep hard prohibitions short, absolute, and reason-carrying. | Sources conflict; the synthesis is "reason + imperative", not "ALL CAPS". |
| 15 | Add a **validation loop / definition of done** for anything quality-critical. | The single most repeated pattern across all Anthropic guidance. |
| 16 | One skill = one **coherent unit of work**, sized like a function. | Too narrow → multiple skills load and conflict; too broad → can't trigger precisely. |
| 17 | In Claude Code, an invoked skill's content **stays in context for the whole session** and is never re-read. Write standing instructions, not one-time steps. | Claude Code-specific and easy to get wrong. |
| 18 | Test triggering with should-trigger *and* near-miss should-not-trigger prompts, in **fresh sessions**. | Leftover authoring context masks gaps. |

---

## 1. The `description` field — the whole trigger mechanism

### 1.1 How triggering actually works

> "At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads
> SKILL.md only when the Skill becomes relevant, and reads additional files only as needed."
> — [platform.claude.com best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

> "This means the description carries the entire burden of triggering. If the description doesn't
> convey when the skill is useful, the agent won't know to reach for it."
> — [agentskills.io/skill-creation/optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

A nuance that matters for a Flutter project full of small tasks:

> "agents typically only consult skills for tasks that require knowledge or capabilities beyond what
> they can handle alone. A simple, one-step request like 'read this PDF' may not trigger a PDF skill
> even if the description matches perfectly, because the agent can handle it with basic tools."
> — [optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

**Implication:** a skill whose job is "do the obvious thing correctly" will not fire on trivial
prompts no matter how good the description. If we need a convention enforced on *every* small edit,
that belongs in CLAUDE.md or a `paths:`-scoped skill, not in a description-triggered skill.

### 1.2 Third person or imperative? Both.

The two authorities appear to conflict. They do not — they govern different halves of the sentence.

> **Warning: Always write in third person**. The description is injected into the system prompt, and
> inconsistent point-of-view can cause discovery problems.
> * **Good:** "Processes Excel files and generates reports"
> * **Avoid:** "I can help you process Excel files"
> * **Avoid:** "You can use this to process Excel files"
> — [platform.claude.com best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

> "**Use imperative phrasing.** Frame the description as an instruction to the agent: 'Use this skill
> when…' rather than 'This skill does…' The agent is deciding whether to act, so tell it when to act."
> — [optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

**Synthesis (this is the rule we follow):**

```
<Third-person verb phrase: what it does>. Use when <concrete trigger contexts>. Do NOT use for <near-miss cases>.
```

Never "I", never "you can". The banned point-of-view is about the *assistant and user*; the
imperative "Use when…" is an instruction to the loader and is correct.

### 1.3 Should it enumerate trigger keywords? Yes.

> "**Be specific and include key terms**. Include both what the Skill does and specific
> triggers/contexts for when to use it."
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

> "Should include specific keywords that help agents identify relevant tasks"
> — [agentskills.io/specification](https://agentskills.io/specification.md), `description` field

> "**Err on the side of being pushy.** Explicitly list contexts where the skill applies, including
> cases where the user doesn't name the domain directly: 'even if they don't explicitly mention
> "CSV" or "analysis."'"
> — [optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

And the strongest statement, from Anthropic's own `skill-creator` skill:

> "Note: currently Claude has a tendency to 'undertrigger' skills -- to not use them when they'd be
> useful. To combat this, please make the skill descriptions a little bit 'pushy'. So for instance,
> instead of 'How to build a simple fast dashboard to display internal Anthropic data.', you might
> write 'How to build a simple fast dashboard to display internal Anthropic data. Make sure to use
> this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to
> display any kind of company data, even if they don't explicitly ask for a "dashboard."'"
> — [anthropics/skills `skills/skill-creator/SKILL.md`](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)

Caveat on keyword stuffing: keywords are good, but *copying failed eval queries verbatim* is
overfitting.

> "Avoid adding specific keywords from failed queries — that's overfitting. Instead, find the general
> category or concept those queries represent and address that."
> — [optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

### 1.4 How long?

| Limit | Value | Source |
| --- | --- | --- |
| Spec hard limit | **1024 chars**, non-empty | [agentskills.io/specification](https://agentskills.io/specification.md) |
| Platform validation | **Maximum 1,024 characters. Cannot contain XML tags** | [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| Claude Code listing cap | **1,536 chars** combined `description` + `when_to_use` | [code.claude.com skills](https://code.claude.com/docs/en/skills) |
| Claude Code listing budget | `skillListingBudgetFraction` **default `0.01`** (1% of context window) | [code.claude.com settings](https://code.claude.com/docs/en/settings.md) |
| Per-skill cap setting | `skillListingMaxDescChars` **default `1536`** | [code.claude.com settings](https://code.claude.com/docs/en/settings.md) |

Verbatim from the Claude Code frontmatter table:

> "Put the key use case first: the combined `description` and `when_to_use` text is truncated at
> 1,536 characters in the skill listing to reduce context usage."

And the failure mode:

> "The listing always contains every skill name, but if you have many skills, Claude Code shortens
> descriptions to fit the listing's character budget, which can strip the keywords Claude needs to
> match your request. … When the listing overflows, Claude Code drops descriptions starting with the
> skills you invoke least, so the skills you use most keep their full text."
> — [code.claude.com skills § Skill descriptions are cut short](https://code.claude.com/docs/en/skills)

This is a mechanism that **changed recently** — the Claude Code changelog records
"raised the listing cap from 250 to 1,536 characters and added a startup warning when descriptions
are truncated"
([CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)). Do not trust any
older blog post quoting 250.

**Our rule:** aim for **200–600 characters**; hard-cap at **1024**. Put the key use case in the first
sentence so truncation degrades gracefully.

The agentskills.io guidance is softer and worth balancing against pushiness:

> "**Keep it concise.** A few sentences to a short paragraph is usually right — long enough to cover
> the skill's scope, short enough that it doesn't bloat the agent's context across many skills."

### 1.5 Real descriptions — good, and why

All of these are the **actual shipped values** from
[github.com/anthropics/skills](https://github.com/anthropics/skills), fetched 2026-07-27.

**Gold standard — `xlsx`** (does everything: scope, casual-phrasing catch, deliverable test, explicit negatives):

```yaml
description: "Use this skill any time a spreadsheet file is the primary input or output. This means any task where the user wants to: open, read, edit, or fix an existing .xlsx, .xlsm, .xltx, .csv, or .tsv file (e.g., adding columns, computing formulas, formatting, charting, cleaning messy data); create a new spreadsheet from scratch or from other data sources; or convert between tabular file formats. Trigger especially when the user references a spreadsheet file by name or path — even casually (like \"the xlsx in my downloads\") — and wants something done to it or produced from it. Also trigger for cleaning or restructuring messy tabular data files (malformed rows, misplaced headers, junk data) into proper spreadsheets. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved."
```

Why it works: (a) a one-line scope test — *"the primary input or output"*; (b) enumerated file
extensions as literal keywords; (c) casual-phrasing catch; (d) a **deliverable test** that resolves
ties with adjacent skills; (e) an explicit **Do NOT** list naming the actual competitors (`docx`,
report-writing, scripting).

**`docx`** — same shape, ends with:
`"Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation."`

**`pptx`** — catches the sneaky case where the file is only an *input*:
`"…even if the extracted content will be used elsewhere, like in an email or summary…"`

**`skill-creator`** — short and clean, no negatives needed because nothing competes:

```yaml
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.
```

**`webapp-testing`** — a *what-it-is* description with no explicit "Use when". Note that this is one
of the weaker ones in Anthropic's own repo by their own stated guidance:

```yaml
description: Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs.
```

It states capability but never says *when to reach for it*, and lists no trigger words a user would
actually type ("test my app", "is the button working", "screenshot the page"). Treat as a
counter-example, not a model.

### 1.6 Real descriptions — bad, and why

Straight from the docs:

```yaml
description: Helps with documents
description: Processes data
description: Does stuff with files
```
— [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

```yaml
# Poor example
description: Helps with PDFs.
```
— [agentskills.io/specification](https://agentskills.io/specification.md)

The documented before/after:

```yaml
# Before
description: Process CSV files.

# After
description: >
  Analyze CSV and tabular data files — compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use this
  skill when the user has a CSV, TSV, or Excel file and wants to
  explore, transform, or visualize the data, even if they don't
  explicitly mention "CSV" or "analysis."
```
> "The improved description is more specific about what the skill does (summary stats, derived
> columns, charts, cleaning) and broader about when it applies."
> — [optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md)

**The rule the before/after teaches:** *specific about what, broad about when.* Vague descriptions
fail in both directions at once.

### 1.7 Testing a description (do this, it is cheap)

Documented method: ~20 labelled queries, 8–10 should-trigger and 8–10 should-not-trigger, run each
3× in a fresh session, compute a trigger rate, threshold at 0.5. Split 60/40 train/validation to
avoid overfitting; pick the iteration with the best **validation** score, which "may not be the last
one you produced". Five iterations is usually enough.
([optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md))

The most valuable negatives are **near-misses**, not obvious irrelevancies:

> Weak: `"Write a fibonacci function"` — obviously irrelevant, tests nothing.
> Strong: `"I need to update the formulas in my Excel budget spreadsheet"` — shares "spreadsheet" and
> "data" concepts, but needs Excel editing, not CSV analysis.

For a Flutter project the near-misses are the whole game: a `flutter-widget-tests` skill and a
`flutter-golden-tests` skill will fight over "write a test for this widget" unless both descriptions
draw the boundary explicitly.

---

## 2. Length and structure of SKILL.md

### 2.1 The documented limit

> "Keep SKILL.md body under 500 lines for optimal performance. Split content into separate files when
> approaching this limit."
> — [platform best-practices § Progressive disclosure patterns](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

> "**Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is
> activated … Keep your main `SKILL.md` under 500 lines."
> — [agentskills.io/specification § Progressive disclosure](https://agentskills.io/specification.md)

> "Tip: Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files."
> — [code.claude.com skills § Add supporting files](https://code.claude.com/docs/en/skills)

So: **500 lines and 5,000 tokens**, both stated. `skill-creator` softens it slightly — *"These word
counts are approximate and you can feel free to go longer if needed"* — but immediately re-states the
limit as a key pattern.

### 2.2 What Anthropic actually ships (empirical)

Line counts of every `SKILL.md` in `anthropics/skills` @ main, 2026-07-27:

```
  32  internal-comms          95  webapp-testing        254  slack-gif-creator
  55  frontend-design         99  xlsx                  314  pdf
  59  theme-factory          129  canvas-design         375  doc-coauthoring
  73  brand-guidelines       236  mcp-builder           404  algorithmic-art
  73  web-artifacts-builder  238  pptx                  485  skill-creator
  91  docx                                              546  claude-api
```

Median ≈ **132 lines**. Two-thirds are under 250. Only `claude-api` exceeds 500 — and it is a pure
reference index whose body is mostly tables pointing into ~40 bundled files.

**Read this as:** 500 is a ceiling, not a target. A good project skill is **60–200 lines**.

### 2.3 Does compliance degrade with length? What is actually evidenced

There is **no published Anthropic measurement** of a compliance cliff at a specific SKILL.md length.
What *is* stated, in Anthropic's own voice, about the analogous always-loaded file:

> "Keep it concise. For each line, ask: *'Would removing this cause Claude to make mistakes?'* If not,
> cut it. **Bloated CLAUDE.md files cause Claude to ignore your actual instructions!**"
>
> "If Claude keeps doing something you don't want despite having a rule against it, **the file is
> probably too long and the rule is getting lost.**"
> — [code.claude.com best-practices § Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices.md)

And the Claude Code skills page explicitly transfers that test to skills:

> "Keep the body itself concise. Once a skill loads, its content stays in context across turns, so
> every line is a recurring token cost. State what to do rather than narrating how or why, and apply
> the same conciseness test you would for CLAUDE.md content."

Corroborating, from the standard:

> "Overly comprehensive skills can hurt more than they help — the agent struggles to extract what's
> relevant and may pursue unproductive paths triggered by instructions that don't apply to the current
> task. Concise, stepwise guidance with a working example tends to outperform exhaustive documentation."
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

> "If pass rates plateau despite adding more rules, the skill may be over-constrained — try removing
> instructions and see if results hold or improve."
> — [agentskills.io evaluating-skills](https://agentskills.io/skill-creation/evaluating-skills.md)

**Verdict:** the "dilution" effect is asserted by Anthropic and consistent across three sources, but
**no numeric threshold is evidenced**. Treat 500 lines as a documented recommendation and ~150 lines
as the observed norm. Marked as *medium* confidence in the summary.

### 2.4 Claude Code-only lifecycle facts that change how you write

These are Claude Code-specific and materially affect authoring:

> "When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a
> single message and stays there for the rest of the session. … **Claude Code does not re-read the
> skill file on later turns, so write guidance that should apply throughout a task as standing
> instructions rather than one-time steps.**"

> "Auto-compaction carries invoked skills forward within a token budget. … Claude Code re-attaches the
> most recent invocation of each skill after the summary, **keeping the first 5,000 tokens of each**.
> Re-attached skills share a combined budget of **25,000 tokens**."

> "If a skill seems to stop influencing behavior after the first response, the content is usually
> still present and the model is choosing other tools or approaches."
> — all three: [code.claude.com skills § Skill content lifecycle](https://code.claude.com/docs/en/skills)

**Two authoring consequences:**
1. **Front-load.** The first 5,000 tokens survive compaction; everything after may not. Put the
   non-negotiable rules near the top.
2. **No "step 1 / step 2 / now forget it".** The content is permanent context. Phrase rules as
   invariants ("Every widget file has X") rather than transient steps, except inside an explicitly
   labelled workflow.

---

## 3. Progressive disclosure

### 3.1 The three levels (verbatim)

> 1. **Metadata** (~100 tokens): The `name` and `description` fields are loaded at startup for all skills
> 2. **Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
> 3. **Resources** (as needed): Files (e.g. those in `scripts/`, `references/`, or `assets/`) are loaded only when required
> — [agentskills.io/specification](https://agentskills.io/specification.md)

> "**No context penalty for large files:** Reference files, data, or documentation don't consume
> context tokens until actually read."
> — [platform best-practices § Runtime environment](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 3.2 Directory layout (verbatim, spec)

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

Claude Code's own example uses a slightly different set — `examples/` and `template.md` appear:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```
— [code.claude.com skills](https://code.claude.com/docs/en/skills)

Both are valid; the spec says "Any additional files or directories". Use `references/`, `scripts/`,
`examples/`, `templates/` and be consistent across our skill set.

### 3.3 Must SKILL.md point at the reference? **Yes — and with a condition.**

> "The `SKILL.md` contains the main instructions and is required. Other files are optional … **Reference
> these files from your `SKILL.md` so Claude knows what they contain and when to load them.**"
> — [code.claude.com skills](https://code.claude.com/docs/en/skills)

> "The key is telling the agent *when* to load each file. **'Read `references/api-errors.md` if the API
> returns a non-200 status code' is more useful than a generic 'see references/ for details.'**"
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

And the observable failure signal:

> "**Ignored content:** If Claude never accesses a bundled file, it might be unnecessary or poorly
> signaled in the main instructions."
> — [platform best-practices § Observe how Claude navigates Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 3.4 One level deep — the nesting trap (verbatim)

> "Claude may partially read files when they're referenced from other referenced files. When
> encountering nested references, Claude might use commands like `head -100` to preview content rather
> than reading entire files, **resulting in incomplete information.**
>
> **Keep references one level deep from SKILL.md.** All reference files should link directly from
> SKILL.md to ensure Claude reads complete files when needed."
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 3.5 Table of contents in long reference files

> "For reference files longer than 100 lines, include a table of contents at the top. This ensures
> Claude can see the full scope of available information even when previewing with partial reads."
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

`skill-creator` says `>300 lines` for the same rule. Use **100** — it is the stricter published figure
and costs nothing.

### 3.6 What goes in a reference vs. the body — the decision rule

Push to `references/` when **all** of these hold:
- It is needed only in a *subset* of runs (one framework, one error path, one domain).
- You can write a **one-line load condition** for it ("read this *if* X").
- It is bulky: schemas, API surfaces, long tables, exhaustive enumerations.

Keep in SKILL.md when **any** of these hold:
- It applies on **every** run (the workflow spine, the definition of done).
- It is a **gotcha** — a fact that defies a reasonable assumption. Explicitly called out:

> "Keep gotchas in `SKILL.md` where the agent reads them before encountering the situation. A separate
> reference file works if you tell the agent when to load it, but **for non-obvious issues, the agent
> may not recognize the trigger.**"
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

That last point is the sharpest rule in the whole corpus: **you cannot progressive-disclose a
surprise.** If the agent doesn't know it's about to step on a rake, it will never read
`references/rakes.md`.

### 3.7 Domain-organised references (the pattern to copy)

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```
with SKILL.md body:
```markdown
**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
**Sales**: Opportunities, pipeline, accounts → See [reference/sales.md](reference/sales.md)
```
— [platform best-practices § Pattern 2](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

Anthropic's `mcp-builder` ships exactly this shape (`reference/python_mcp_server.md`,
`reference/node_mcp_server.md`, `reference/evaluation.md`) and uses the phrasing
`"**Load [Evaluation Guide](./reference/evaluation.md) for complete evaluation guidelines.**"` — an
imperative verb, not a passive "see also".

---

## 4. Scripts versus prose

### 4.1 When a script beats instructions

> "Even if Claude could write a script, pre-made scripts offer advantages:
> * More reliable than generated code
> * Save tokens (no need to include code in context)
> * Save time (no code generation required)
> * Ensure consistency across uses"
> — [platform best-practices § Provide utility scripts](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

> "**Prefer scripts for deterministic operations:** Write `validate_form.py` rather than asking Claude
> to generate validation code"

The discovery signal for *when* to write one:

> "If you notice the agent independently reinventing the same logic each run — building charts,
> parsing a specific format, validating output — that's a signal to write a tested script once and
> bundle it in `scripts/`."
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

### 4.2 What good skill scripts do

The four documented jobs, all present in Anthropic's shipped skills:

| Job | Example | Source |
| --- | --- | --- |
| **Analyse / extract** | `analyze_form.py input.pdf > fields.json` | platform best-practices |
| **Validate** | `validate_fields.py fields.json` → "OK" or lists conflicts | platform best-practices |
| **Execute the fragile step** | `recalc.py output.xlsx` (LibreOffice recalculation) | `anthropics/skills` xlsx |
| **Verify the result** | `verify_output.py output.pdf` | platform best-practices |
| **Manage lifecycle** | `with_server.py --server "npm run dev" --port 5173 -- python auto.py` | `anthropics/skills` webapp-testing |

The strongest structural pattern is **plan → validate → execute**:

> "The workflow becomes: analyze → **create plan file** → **validate plan** → execute → verify. …
> **When to use:** Batch operations, destructive changes, complex validation rules, high-stakes
> operations."
> — [platform best-practices § Create verifiable intermediate outputs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 4.3 Execute or read? Say which.

> "**Important distinction:** Make clear in your instructions whether Claude should:
> * **Execute the script** (most common): 'Run `analyze_form.py` to extract fields'
> * **Read it as reference** (for complex logic): 'See `analyze_form.py` for the field extraction algorithm'
>
> For most utility scripts, execution is preferred because it's more reliable and efficient."
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

`webapp-testing` states the black-box rule bluntly, and it is worth copying verbatim into our scripts:

> "**Always run scripts with `--help` first** to see usage. DO NOT read the source until you try
> running the script first and find that a customized solution is absolutely necessary. These scripts
> can be very large and thus pollute your context window. They exist to be called directly as
> black-box scripts rather than ingested into your context window."

### 4.4 What makes a script fragile

Every item below is documented; the first is a **hard requirement**, not a preference.

| Fragility | Rule | Source |
| --- | --- | --- |
| **Interactive prompts** | "This is a hard requirement of the agent execution environment. Agents operate in non-interactive shells… A script that blocks on interactive input will hang indefinitely." | [using-scripts](https://agentskills.io/skill-creation/using-scripts.md) |
| **No `--help`** | "`--help` output is the primary way an agent learns your script's interface." | using-scripts |
| **Opaque errors** | "An opaque 'Error: invalid input' wastes a turn. Instead, say what went wrong, what was expected, and what to try." | using-scripts |
| **Unstructured output** | "Prefer structured formats — JSON, CSV, TSV — over free-form text." Data → stdout, diagnostics → stderr. | using-scripts |
| **Unbounded output** | "Many agent harnesses automatically truncate tool output beyond a threshold (e.g., 10-30K characters), potentially losing critical information." | using-scripts |
| **Non-idempotent** | "Agents may retry commands. 'Create if not exists' is safer than 'create and fail on duplicate.'" | using-scripts |
| **Deferring errors to Claude** | "handle error conditions rather than deferring to Claude" — catch `FileNotFoundError`/`PermissionError` and degrade | [platform § Solve, don't defer](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| **Voodoo constants** | "`TIMEOUT = 47  # Why 47?`" — "If you don't know the right value, how will Claude determine it?" (Ousterhout's law, cited by name) | platform best-practices |
| **Windows paths** | "Always use forward slashes in file paths, even on Windows" | platform best-practices |
| **Assumed installs** | "Don't assume packages are available" — state the install command | platform best-practices |
| **Unpinned one-off commands** | "**Pin versions** (e.g., `npx eslint@9.0.0`) so the command behaves the same over time." | using-scripts |

Also relevant for a *Flutter* repo where scripts must run from anywhere: Claude Code substitutes
`${CLAUDE_SKILL_DIR}` in **both** the body and `allowed-tools`, which lets a bundled script run without
a permission prompt:

```yaml
---
name: render-chart
description: Render a chart from a CSV file
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
---

Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render the chart.
```
> "The `allowed-tools` rule then matches the exact command the skill body tells Claude to run, so the
> script runs without prompting." (Requires Claude Code **v2.1.129+**; `${CLAUDE_PROJECT_DIR}` requires
> **v2.1.196+**.)
> — [code.claude.com skills § Available string substitutions](https://code.claude.com/docs/en/skills)

---

## 5. Examples

### 5.1 What they're for

> "For Skills where output quality depends on seeing examples, provide input/output pairs just like in
> regular prompting. … **Examples convey the desired style and level of detail to Claude more clearly
> than descriptions alone.**"
> — [platform best-practices § Examples pattern](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

The checklist item is: **"Examples are concrete, not abstract"**.

### 5.2 Useful vs decorative

A useful example is an **input/output pair** that resolves a judgement the prose cannot:

````markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

Follow this style: type(scope): brief description, then detailed explanation.
````
— [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

A **decorative** example is one that restates the rule in another font: a snippet with no
counterpart, no delta from the default, and nothing the model would have gotten wrong. The test:
*would the agent produce something different without this example?* If not, delete it.

For a *file-level* example (`examples/sample.dart`), the useful form is the **expected output
artifact** — Claude Code's own docs describe `examples/sample.md` as "Example output showing expected
format". Anthropic's `webapp-testing` lists its examples with a one-line purpose each, which is what
makes them loadable on demand:

```markdown
## Reference Files

- **examples/** - Examples showing common patterns:
  - `element_discovery.py` - Discovering buttons, links, and inputs on a page
  - `static_html_automation.py` - Using file:// URLs for local HTML
  - `console_logging.py` - Capturing console logs during automation
```

Three or fewer examples, each pinned to a distinct decision, beats a gallery.

---

## 6. Writing style for an agent audience

### 6.1 Cut what the model already knows

The canonical good/bad pair (~50 tokens vs ~150 tokens for the same instruction):

> **Good (concise):**
> ````markdown
> ## Extract PDF text
> Use pdfplumber for text extraction:
> ```python
> import pdfplumber
> with pdfplumber.open("file.pdf") as pdf:
>     text = pdf.pages[0].extract_text()
> ```
> ````
> **Bad (too verbose):** "PDF (Portable Document Format) files are a common file format that
> contains text, images, and other content. To extract text from a PDF, you'll need to use a library…"
> — [platform best-practices § Concise is key](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

The test to apply to every paragraph:

> "Ask yourself about each piece of content: **'Would the agent get this wrong without this
> instruction?'** If the answer is no, cut it."
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

### 6.2 Imperative or explanatory? The sources genuinely conflict — here is the resolution

| Source | Position |
| --- | --- |
| `skill-creator` (Anthropic) | "Prefer using the imperative form in instructions." … "Try to explain to the model **why** things are important in lieu of heavy-handed musty MUSTs. **Use theory of mind**…" |
| agentskills.io evaluating-skills | "**Explain the why.** Reasoning-based instructions ('Do X because Y tends to cause Z') work better than rigid directives ('ALWAYS do X, NEVER do Y'). Models follow instructions more reliably when they understand the purpose." |
| agentskills.io best-practices | "For flexible instructions, explaining *why* can be more effective than rigid directives" — but **"Be prescriptive when operations are fragile"**: *"Run exactly this sequence… Do not modify the command or add additional flags."* |
| platform best-practices | Uses `ALWAYS use this exact template structure` for strict formats; suggests "using stronger language such as **'MUST filter'** instead of 'always filter'" when a rule is being ignored |
| code.claude.com best-practices (CLAUDE.md) | "You can tune instructions by adding emphasis (e.g., 'IMPORTANT' or 'YOU MUST') to improve adherence." |

**Resolution — the rule we adopt:**

1. **Default: imperative + reason, one sentence.** `Do X, because Y.` Not `You should consider Xing.`
2. **Reserve ALL-CAPS / MUST / NEVER for genuine prohibitions** where deviation is a defect, and even
   then attach the consequence. Emphasis is a scarce resource; if half the document is bold, none of
   it is.
3. **Escalate only on evidence.** The documented workflow is: observe the model ignoring the rule →
   *then* strengthen the wording. Not preemptively.

The best model of this in production is Anthropic's `xlsx` skill — every prohibition carries its
mechanism:

> "**Never use `XLOOKUP`, `XMATCH`, `SORT`, `FILTER`, `UNIQUE`, or `SEQUENCE`.** The runtime's
> LibreOffice cannot evaluate them under *any* prefix. Newer builds do evaluate them, but they are
> spilling array functions and an openpyxl-written file has no spill metadata, so only the top-left
> cell of the range gets a value — and `recalc.py` reports `total_errors: 0` on the truncated result."

That is a hard prohibition the model will obey, because it also tells the model *why the obvious
workaround also fails* — closing the escape hatch is what makes a prohibition stick.

### 6.3 Anti-patterns stated explicitly: yes, do it

`webapp-testing` uses a two-line ❌/✅ block:

```markdown
## Common Pitfall

❌ **Don't** inspect the DOM before waiting for `networkidle` on dynamic apps
✅ **Do** wait for `page.wait_for_load_state('networkidle')` before inspection
```

And the highest-value section type in the entire corpus:

> "The highest-value content in many skills is a list of gotchas — environment-specific facts that
> defy reasonable assumptions. These aren't general advice ('handle errors appropriately') but
> **concrete corrections to mistakes the agent will make without being told otherwise**"
>
> "**When an agent makes a mistake you have to correct, add the correction to the gotchas section.**
> This is one of the most direct ways to improve a skill iteratively."
> — [agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)

### 6.4 Does a "definition of done" help? Yes — as a validation loop

Not phrased as "definition of done" in the docs, but the pattern is everywhere and is the single most
repeated recommendation:

> "**Common pattern:** Run validator → fix errors → repeat. **This pattern greatly improves output quality.**"
>
> ```markdown
> 1. Make your edits to `word/document.xml`
> 2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
> 3. If validation fails: review the error, fix the issues, run validation again
> 4. **Only proceed when validation passes**
> ```
> — [platform best-practices § Implement feedback loops](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

And a checklist the model copies into its own response:

> "For particularly complex workflows, provide a checklist that Claude can copy into its response and
> check off as it progresses. … **Clear steps prevent Claude from skipping critical validation.**"

`xlsx` shows the prose form — a `## Requirements for every output` section that reads as an
acceptance test ("Zero formula errors. Never ship while `recalc.py` reports `errors_found`"). For our
Flutter skills the equivalent is a closing block: *`flutter analyze` clean, `dart format` applied,
tests pass, no `print()` left behind* — with the exact commands.

### 6.5 Consistent terminology

> "Choose one term and use it throughout the Skill. … **Bad - Inconsistent:** Mix 'API endpoint',
> 'URL', 'API route', 'path'… **Consistency helps Claude parse and follow instructions.**"
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 6.6 One default, not a menu

> "**Bad example: Too many choices** (confusing): 'You can use pypdf, or pdfplumber, or PyMuPDF, or
> pdf2image, or…'
> **Good example: Provide a default** (with escape hatch): 'Use pdfplumber for text extraction…
> For scanned PDFs requiring OCR, use pdf2image with pytesseract instead.'"
> — [platform best-practices § Avoid offering too many options](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

Diagnostic: *"too many options presented without a clear default"* is listed as a cause of the agent
wasting time in execution traces ([agentskills.io best-practices](https://agentskills.io/skill-creation/best-practices.md)).

### 6.7 No time-sensitive content

> **Bad:** "If you're doing this before August 2025, use the old API. After August 2025, use the new API."
> **Good:** a `## Current method` section plus an `## Old patterns` section wrapped in
> `<details><summary>Legacy v1 API (deprecated 2025-08)</summary>`.
> — [platform best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

---

## 7. Scope — how big is one skill?

### 7.1 The stated principle

> "Deciding what a skill should cover is **like deciding what a function should do**: you want it to
> encapsulate a coherent unit of work that composes well with other skills. **Skills scoped too
> narrowly force multiple skills to load for a single task, risking overhead and conflicting
> instructions. Skills scoped too broadly become hard to activate precisely.** A skill for querying a
> database and formatting the results may be one coherent unit, while a skill that also covers
> database administration is probably trying to do too much."
> — [agentskills.io best-practices § Design coherent units](https://agentskills.io/skill-creation/best-practices.md)

That paragraph is the entire published answer on scope. It names both failure directions:

- **Too many small skills** → several load at once → **conflicting instructions** + listing-budget pressure.
- **One big skill** → the description can't be precise → it either over-triggers or under-triggers.

### 7.2 When splitting hurts — the "wrong half" problem

The docs don't use that phrase, but three documented mechanisms produce it:

1. **Description ambiguity.** Two skills whose descriptions overlap are resolved by the model reading
   ~1,536 chars of each. If neither says "not this", it picks by vibes. Fix: explicit `Do NOT` clauses
   in *both*, drawing the same boundary from both sides.
2. **Listing truncation.** With many skills, "Claude Code shortens descriptions to fit the listing's
   character budget, which can strip the keywords Claude needs to match your request" — and it drops
   the *least-used* skills' descriptions first. A rarely-used half of a split pair silently loses its
   description ([code.claude.com skills](https://code.claude.com/docs/en/skills)).
3. **Partial context.** Once a skill is invoked its content persists all session. Loading the wrong
   half means the wrong standing instructions sit in context for the rest of the session, and
   Claude Code will *not* re-read the right one automatically.

### 7.3 Practical sizing heuristic for this project

Split when the two halves have **genuinely different trigger vocabularies** and **different bodies of
knowledge**. Keep together when a task routinely needs both.

- `flutter-state-management` + `flutter-widget-conventions` → **split** (different triggers, different rules).
- `flutter-testing` split into `unit` / `widget` / `golden` → **probably don't**; "write a test" hits all
  three and they share setup. Prefer one `flutter-testing` skill with `references/golden-tests.md`.
- Anything with **side effects** (release, publish, migrate) → its own skill with
  `disable-model-invocation: true`, per the documented reason: *"You don't want Claude deciding to
  deploy because your code looks ready."*

### 7.4 Claude Code gives extra scoping tools — use them instead of splitting

| Field | Effect | Verbatim |
| --- | --- | --- |
| `paths` | Auto-trigger only for matching files | "Glob patterns that limit when this skill is activated. … When set, Claude loads the skill automatically only when working with files matching the patterns." |
| `disable-model-invocation: true` | Manual-only; **removes the description from context entirely** | "This removes the skill from Claude's context entirely." |
| `user-invocable: false` | Model-only background knowledge, hidden from `/` menu | "Use this for background knowledge that isn't actionable as a command." |
| Nested `.claude/skills/` | Per-package skills in a monorepo, auto-namespaced `apps/web:deploy` | "Claude picks the variant that matches the files it is working on." |
— all from [code.claude.com skills](https://code.claude.com/docs/en/skills)

`paths:` is the cleanest answer to "this rule only applies to `lib/features/**`" and costs zero
description budget.

---

## 8. Frontmatter — the exact, current schema

### 8.1 The open standard (portable floor)

> | Field | Required | Constraints |
> | --- | --- | --- |
> | `name` | Yes | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen. |
> | `description` | Yes | Max 1024 characters. Non-empty. Describes what the skill does and when to use it. |
> | `license` | No | License name or reference to a bundled license file. |
> | `compatibility` | No | Max 500 characters. Indicates environment requirements… |
> | `metadata` | No | Arbitrary key-value mapping for additional metadata. |
> | `allowed-tools` | No | Space-separated string of pre-approved tools the skill may use. (Experimental) |
> — [agentskills.io/specification](https://agentskills.io/specification.md)

Plus, for `name`: "Must not contain consecutive hyphens (`--`)" and **"Must match the parent directory
name."**

### 8.2 Platform validation adds two prohibitions

> `name`: "Cannot contain XML tags. Cannot contain reserved words: 'anthropic', 'claude'"
> `description`: "Cannot contain XML tags"
> — [platform best-practices § Skill structure](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

⚠️ **Observed contradiction:** Anthropic's own repo ships `skills/claude-api/SKILL.md` with
`name: claude-api`, and Claude Code bundles a `/claude-api` skill. The reserved-word rule is
evidently not enforced on the Claude Code path. **Follow the documented rule anyway** — don't put
`claude` or `anthropic` in our skill names; there is no upside.

### 8.3 Claude Code's frontmatter (superset — and everything is optional)

> "All fields are optional. Only `description` is recommended so Claude knows when to use the skill."
> — [code.claude.com skills § Frontmatter reference](https://code.claude.com/docs/en/skills)

Claude Code-only fields we may use: `when_to_use`, `argument-hint`, `arguments`,
`disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`,
`context`, `agent`, `background`, `hooks`, `paths`, `shell`.

Key notes, verbatim:
- `name`: "Display name shown in skill listings. **Defaults to the directory name.**" (In a personal or
  project skill, `name` sets only the display label — **the command comes from the directory name**.)
- `description`: "If omitted, uses the first paragraph of markdown content."
- `when_to_use`: "Additional context for when Claude should invoke the skill, such as trigger phrases
  or example requests. Appended to `description` in the skill listing and counts toward the
  1,536-character cap."
- Booleans accept `yes`/`no`/`on`/`off`/`1`/`0` case-insensitively as of **v2.1.218**.
- Malformed YAML: "Claude Code loads the skill body with empty metadata, so `/skill-name` still works
  but Claude has no `description` to match against. Run with `--debug` to see the parse error."

**Our house rule:** always write `name` (matching the directory, per the spec) and `description`.
Skip `when_to_use` — it is Claude Code-only and non-portable; fold its content into `description`
instead, staying under 1024 chars.

---

## 9. Complete file examples

### 9.1 Minimal, single-file skill (the shape most of ours should take)

```markdown
---
name: flutter-riverpod-providers
description: Defines and wires Riverpod providers in this app — file placement, naming, codegen, and disposal rules. Use when adding or changing state, creating a provider, notifier, or repository, refactoring setState into shared state, or when the user mentions Riverpod, providers, notifiers, ref.watch, or ref.read. Do NOT use for pure widget layout or styling work that touches no state.
---

# Riverpod providers

Every provider in this app is code-generated. Hand-written `StateNotifierProvider` is a defect.

## Where things live

- Providers: `lib/features/<feature>/providers/<name>_provider.dart`
- Notifiers: same file, same name, `@riverpod class <Name>Notifier`
- Never declare a provider inside a widget file.

## Workflow

1. Write the provider with `@riverpod` and a `part '<file>.g.dart';` directive.
2. Run codegen: `dart run build_runner build --delete-conflicting-outputs`
3. Consume with `ref.watch` in `build`; `ref.read` only inside callbacks.
4. Run `flutter analyze` and fix every warning before finishing.

## Gotchas

- `ref.read` in `build` compiles fine and silently stops rebuilding. Reviewers miss it; the widget
  just goes stale. Use `ref.watch` in `build`, always.
- Codegen writes `.g.dart` next to the source. If `build_runner` reports a conflict, it is almost
  always a stale `.g.dart` from a renamed file — delete it rather than passing extra flags.
- `autoDispose` is the default under `@riverpod`. A provider that must outlive its screen needs
  `@Riverpod(keepAlive: true)` — omitting it produces a "state resets when you navigate back" bug
  that looks like a routing problem.

## Done when

- [ ] `dart run build_runner build --delete-conflicting-outputs` succeeds
- [ ] `flutter analyze` reports zero issues
- [ ] No `ref.read` appears inside any `build` method
```

Why this shape: ~40 lines, one coherent concern, description carries triggers *and* a negative, the
gotchas are non-obvious and carry their mechanism, and the close is a checkable definition of done.

### 9.2 Multi-file skill with progressive disclosure

```
.claude/skills/flutter-testing/
├── SKILL.md                       # 90 lines: workflow + gotchas + done-when
├── references/
│   ├── golden-tests.md            # loaded only for golden work (has a TOC)
│   └── mocking.md                 # loaded only when mocks/fakes are involved
├── examples/
│   └── widget_test_example.dart   # one canonical passing test
└── scripts/
    └── check_coverage.sh          # executed; prints JSON; exits non-zero under threshold
```

The navigation block inside SKILL.md — note the **load conditions**, not a bare "see also":

```markdown
## Additional resources

- Writing or updating a golden test, or a golden diff failed → read [references/golden-tests.md](references/golden-tests.md)
- The unit under test has a network or platform-channel dependency → read [references/mocking.md](references/mocking.md)
- Unsure of the expected structure of a widget test → read [examples/widget_test_example.dart](examples/widget_test_example.dart)

Run `bash scripts/check_coverage.sh` to verify coverage; do not read its source.
```

Each line has a **trigger condition**, a **link**, and (for the script) an explicit
execute-not-read instruction. All links are one level deep.

---

## 10. Pitfalls — how skill authoring goes wrong in practice

**Documented in the sources:**

1. **Vague description** → never fires. `"Helps with documents"`, `"Processes data"`,
   `"Does stuff with files"` are the docs' own examples. Also: a *capability-only* description with
   no "Use when" (see `webapp-testing`, §1.5).
2. **Over-broad description** → fires constantly. Documented fix: "Make the description more specific"
   or set `disable-model-invocation: true`.
3. **Overlapping triggers between skills** → coin-flip selection. Fix with reciprocal `Do NOT` clauses.
4. **Description truncated away** → in Claude Code, with many skills the listing budget (1% of context
   by default) drops the least-used skills' descriptions first. Symptom: a skill that used to fire
   stops firing after you add ten more. Diagnose with `/doctor`; check the Skills row in `/context`.
5. **Nested references** → partial reads, incomplete information. Keep one level deep.
6. **Reference file never read** → "it might be unnecessary or poorly signaled in the main
   instructions". Usually means SKILL.md gave no load condition.
7. **Gotcha buried in a reference file** → the agent doesn't know it needs to look. Gotchas belong in
   SKILL.md.
8. **Bloat** → "Bloated CLAUDE.md files cause Claude to ignore your actual instructions"; the same
   test applies to skills. "If Claude keeps doing something you don't want despite having a rule
   against it, the file is probably too long and the rule is getting lost."
9. **Time-sensitive content** → "will become wrong". Use an `## Old patterns` `<details>` block.
10. **Inconsistent terminology** → parsing cost, weaker adherence.
11. **A menu instead of a default** → wandering, wasted turns.
12. **Documentation-as-skill** → generic content the model already knows. "Does Claude really need this
    explanation?" / "Would the agent get this wrong without this instruction?" If a skill's advice is
    "handle errors appropriately" or "follow best practices for authentication", it is documentation,
    not a skill. Named directly: *"A common pitfall in skill creation is asking an LLM to generate a
    skill without providing domain-specific context… The result is vague, generic procedures."*
13. **Answer-shaped instead of procedure-shaped** → "A skill should teach the agent *how to approach*
    a class of problems, not *what to produce* for a specific instance."
14. **Fragile scripts** → interactive prompts (hangs forever), no `--help`, opaque errors, unbounded
    output, magic constants, Windows path separators, assumed installs.
15. **Ambiguous execute-vs-read** → the agent burns context reading a 900-line script it should have run.
16. **`context: fork` on a reference skill** → returns nothing. Verbatim warning: *"`context: fork` only
    makes sense for skills with explicit instructions. If your skill contains guidelines like 'use
    these API conventions' without a task, the subagent receives the guidelines but no actionable
    prompt, and returns without meaningful output."*
17. **Malformed YAML** → skill silently loads with **empty metadata**; `/skill-name` still works, so
    you won't notice, but auto-triggering is dead. Check with `--debug`.
18. **Testing in the authoring session** → "leftover context from authoring the skill will mask gaps in
    the written instructions." Always test in a fresh session.

**Observed in Anthropic's own repo (our reading, not doc claims):**

19. A skill whose description states *what it is* but never *when to reach for it* (`webapp-testing`,
    `theme-factory`, `frontend-design`). These rely on the user naming the skill.
20. Over-length bodies happen even at Anthropic (`claude-api`, 546 lines) — but only where the body is
    a pure routing index into bundled files.

**Claude Code-specific traps we must not repeat:**

21. Writing a skill as **one-time steps** when its content persists all session and is never re-read.
22. Burying the critical rules past the **first 5,000 tokens**, which is all that survives compaction.
23. Assuming a skill in `~/.claude/skills/` will exist in cloud/Cowork sessions — it won't; project
    skills must be committed to `.claude/skills/`.
24. Putting `allowed-tools` in a project skill without realising it "can grant itself broad tool
    access" and only takes effect after the workspace trust dialog. Review before committing.

---

## 11. Process — the loop that actually produces a good skill

1. **Do the task manually first**, with Claude, and note every correction you make. *"Notice what
   information you repeatedly provide."*
2. **Build evaluations before extensive documentation.** *"Create evaluations BEFORE writing extensive
   documentation. This ensures your Skill solves real problems rather than documenting imagined ones."*
   Baseline without the skill first.
3. **Write the minimum** that closes the observed gaps.
4. **Test in fresh sessions**, with the skill and without it, and compare.
5. **Read execution traces, not just outputs.** Wasted steps mean vague instructions, inapplicable
   instructions, or too many options without a default.
6. **Tune the description last**, with a train/validation split, ~20 labelled queries, 3 runs each.
7. **Feed corrections back into the gotchas section**, permanently.

Claude Code ships a first-party tool for this loop:
`/plugin install skill-creator@claude-plugins-official` — it stores test cases in
`evals/evals.json` in the skill directory, spawns a subagent per case, grades assertions to
`grading.json`, aggregates with/without-skill into `benchmark.json`, does blind A/B between skill
versions, and has a **description-tuning mode** that "generates should-trigger and should-not-trigger
prompts, measures the hit rate, and proposes description edits when the skill activates on the wrong
requests" ([code.claude.com skills § Run evals with skill-creator](https://code.claude.com/docs/en/skills)).

---

## 12. Explicitly unverified / uncertain

- **No published measurement of a compliance cliff at any specific SKILL.md length.** The 500-line and
  5,000-token figures are recommendations stated without accompanying data. The "long files cause
  ignored rules" claim is asserted by Anthropic (about CLAUDE.md, transferred to skills by the Claude
  Code docs) but not quantified anywhere I could fetch.
- **The `name` reserved-word rule ("anthropic", "claude") is contradicted by Anthropic's own shipped
  `claude-api` skill.** Which validator enforces it, and on which path, is not documented.
- **`compatibility` and `metadata` are spec fields not listed in Claude Code's frontmatter table.**
  Claude Code documents its own field list and says "All fields are optional"; whether unknown fields
  are ignored silently or warned about is not documented. Assume ignored; do not rely on them.
- **The `spec/` directory referenced in `anthropics/skills` README** was not fetched; agentskills.io's
  `/specification` page was used as the authoritative spec instead.
- **Whether `examples/` is a spec-recognised directory.** The spec names `scripts/`, `references/`,
  `assets/` and says "Any additional files or directories". `examples/` appears in Claude Code's docs
  and in `webapp-testing`, so it is conventional but not specified.
- **WebSearch budget for this session was exhausted**, so no third-party/community corroboration was
  gathered. Everything above is from primary sources only — which was the requirement, but it means
  no independent replication of the trigger-rate methodology was checked.
- **Claude Code version-gated behaviours** (`${CLAUDE_SKILL_DIR}` in `allowed-tools` needs v2.1.129+,
  `${CLAUDE_PROJECT_DIR}` v2.1.196+, background forks v2.1.218+, nested-skill fan-out v2.1.203+).
  I did not check which version is installed on this machine. Verify with `claude --version` before
  relying on any of them.

---

## Sources

Fetched 2026-07-27. Every URL below was actually retrieved for this document.

**Claude Code documentation**
- https://code.claude.com/docs/en/skills — Extend Claude with skills (frontmatter reference, discovery, lifecycle, listing budget, troubleshooting)
- https://code.claude.com/docs/en/skills.md
- https://code.claude.com/docs/en/settings.md — `skillListingBudgetFraction`, `skillListingMaxDescChars`, `skillOverrides`, `disableBundledSkills`
- https://code.claude.com/docs/en/best-practices.md — "Write an effective CLAUDE.md" (conciseness / rule-dilution)
- https://code.claude.com/docs/en/plugins-reference.md — skills in plugins, skills-directory plugins
- https://code.claude.com/docs/llms.txt — doc index

**Anthropic platform documentation**
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices — Skill authoring best practices (the primary authoring source)
- (redirect origins verified: https://docs.claude.com/en/docs/claude-code/skills → 301; https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/best-practices → 302)

**Agent Skills open standard**
- https://agentskills.io/specification.md — frontmatter schema, directory layout, progressive disclosure, file references
- https://agentskills.io/skill-creation/best-practices.md — scoping, calibration, gotchas, templates, validation loops
- https://agentskills.io/skill-creation/optimizing-descriptions.md — description writing + trigger-eval methodology
- https://agentskills.io/skill-creation/evaluating-skills.md — eval file format, assertions, grading, iteration loop
- https://agentskills.io/skill-creation/using-scripts.md — script design for agentic use
- https://agentskills.io/llms.txt — doc index

**Anthropic source repositories**
- https://github.com/anthropics/skills — all 18 `SKILL.md` files fetched raw for frontmatter + line counts
- https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md — "undertrigger"/"pushy" guidance, writing style
- https://github.com/anthropics/skills/blob/main/skills/xlsx/SKILL.md — gold-standard description and gotchas style
- https://github.com/anthropics/skills/blob/main/skills/docx/SKILL.md
- https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md — black-box script rule, ❌/✅ pitfall block
- https://github.com/anthropics/skills/blob/main/README.md
- https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md — listing cap 250 → 1,536; version-gated skill features
- https://github.com/anthropics/claude-plugins-official — `skill-creator` plugin location

**Anthropic engineering**
- https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills — three-level progressive disclosure, "effectively unbounded" bundled context
