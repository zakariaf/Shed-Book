# 04 — Real-world survey of high-quality Agent Skills

**Researched:** 2026-07-27
**Method:** primary sources only. Official docs fetched live (`code.claude.com/docs`, `platform.claude.com/docs`, `agentskills.io`); skills read from cloned repositories at pinned commits; local clone of Anthropic's official plugin marketplace.

**Corpus actually read (not summarised from memory):**

| Source | Commit / date | What |
| --- | --- | --- |
| [`anthropics/skills`](https://github.com/anthropics/skills) | `b29e7cf6` — 2026-07-24 | 17 skills + spec + template — **all 17 SKILL.md read end to end** |
| [`obra/superpowers`](https://github.com/obra/superpowers) | `3dcbd5c4` — 2026-07-23 | 14 skills, 262k stars — largest community collection |
| `anthropics/claude-plugins-official` (local clone at `~/.claude/plugins/marketplaces/`) | local | `skill-creator`, `frontend-design`, `plugin-dev/skill-development`, `hookify`, `example-plugin` |
| [`HiroHyun/grounded-copy`](https://github.com/HiroHyun/grounded-copy) | 2026-07-24 | SKILL.md + 267-line deterministic linter — the best "exactly one way" example found |
| [`arvindrk/extract-design-system`](https://github.com/arvindrk/extract-design-system) | 2026-07-18 | design-token extraction skill (147★) |
| [`catyiqian/claude-design-style`](https://github.com/catyiqian/claude-design-style) | 2026-04-04 | design-token / brand skill |
| [`acdgbrasil/dart-modern-claude-kit`](https://github.com/acdgbrasil/dart-modern-claude-kit) | 2026-04-30 | the only Flutter/Dart skill catalogue found on GitHub — mostly a cautionary tale |

---

## Bottom line — the rules we must follow

| # | Rule | Why |
| --- | --- | --- |
| 1 | Frontmatter: `name` + `description` only, unless you have a specific reason. Both are the only fields the open standard *requires*. | [spec](https://agentskills.io/specification) |
| 2 | `name`: 1–64 chars, `[a-z0-9-]` only, no leading/trailing/consecutive hyphens, **must match the parent directory name**. | [spec](https://agentskills.io/specification) |
| 3 | `description`: ≤1024 chars hard limit — but Claude Code truncates `description`+`when_to_use` at **1,536 chars** in the listing, and the whole listing is budgeted at ~1% of the context window. Put the key use case first. | [spec](https://agentskills.io/specification), [CC skills](https://code.claude.com/docs/en/skills) |
| 4 | Description states **what it does AND when to use it**, third person, "pushy" about triggers. Do **not** summarise the workflow inside the description. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [superpowers/writing-skills](https://github.com/obra/superpowers/blob/main/skills/writing-skills/SKILL.md) |
| 5 | SKILL.md body **under 500 lines / ~5,000 tokens**. Anthropic's own median is ~130 lines. | [spec](https://agentskills.io/specification), [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 6 | Bundled dirs: `scripts/` (executed), `references/` (read on demand), `assets/` (used in output). `examples/` is common in practice but is not one of the three named in the spec. | [spec](https://agentskills.io/specification) |
| 7 | References **one level deep from SKILL.md**. Never `SKILL.md → a.md → b.md`. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 8 | Every reference file gets a **when-to-load trigger** in SKILL.md, not a bare "see references/". | [agentskills best practices](https://agentskills.io/skill-creation/best-practices) |
| 9 | Reference files >100 lines get a table of contents at the top. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 10 | Add only what the agent lacks. Cut anything Claude already knows. | [agentskills best practices](https://agentskills.io/skill-creation/best-practices) |
| 11 | Give **one default with an escape hatch**, never a menu of options. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 12 | Match specificity to fragility: high freedom for judgement calls, exact commands for fragile sequences. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 13 | Where a rule is mechanically checkable, ship a **script** that checks it, and tell the agent it may not edit the script. | `grounded-copy`, `xlsx`, `docx` |
| 14 | Pair every prescriptive rule with a **verification loop**: do work → run validator → fix → repeat until clean. | [best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| 15 | Prohibitions work for *discipline* failures. For *wrong-shaped output*, prohibitions backfire — state the positive recipe instead. | [superpowers/writing-skills](https://github.com/obra/superpowers/blob/main/skills/writing-skills/SKILL.md#L459-L474) |
| 16 | Skill content **stays in context for the rest of the session** once loaded. Write standing instructions, not one-time steps; every line is a recurring token cost. | [CC skills](https://code.claude.com/docs/en/skills) |
| 17 | Don't put `version:` in frontmatter. It is in neither schema, and Anthropic's own validator **rejects** it. Use `metadata: {version: "1.0"}`. | `skill-creator/scripts/quick_validate.py` |
| 18 | Test with a baseline: same prompt, fresh session, skill available vs. disabled. | [CC skills](https://code.claude.com/docs/en/skills) |

---

## 1. The verified schema (quote everything)

### 1.1 Agent Skills open standard — frontmatter

Verbatim from [agentskills.io/specification](https://agentskills.io/specification):

> | Field           | Required | Constraints                                                                                                       |
> | --------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
> | `name`          | Yes      | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen.             |
> | `description`   | Yes      | Max 1024 characters. Non-empty. Describes what the skill does and when to use it.                                 |
> | `license`       | No       | License name or reference to a bundled license file.                                                              |
> | `compatibility` | No       | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
> | `metadata`      | No       | Arbitrary key-value mapping for additional metadata.                                                              |
> | `allowed-tools` | No       | Space-separated string of pre-approved tools the skill may use. (Experimental)                                    |

And on `name`, verbatim:

> * Must be 1-64 characters
> * May only contain unicode lowercase alphanumeric characters (`a-z`, `0-9`) and hyphens (`-`)
> * Must not start or end with a hyphen (`-`)
> * Must not contain consecutive hyphens (`--`)
> * **Must match the parent directory name**

`platform.claude.com` adds two constraints the spec page does not state:

> `name`: … Cannot contain XML tags. Cannot contain reserved words: "anthropic", "claude"
> `description`: … Cannot contain XML tags

(Anthropic's own `quick_validate.py` enforces the XML-tag rule as "Description cannot contain angle brackets (< or >)".)

### 1.2 Claude Code's extended frontmatter

Claude Code implements the standard and adds fields. Verbatim from [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills):

> All fields are optional. Only `description` is recommended so Claude knows when to use the skill.

Fields (abridged from the doc's table, quoting the load-bearing ones):

| Field | Notes (verbatim where quoted) |
| --- | --- |
| `name` | "Display name shown in skill listings. Defaults to the directory name." For personal/project skills the **command name comes from the directory**, not this field. |
| `description` | "Put the key use case first: the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing to reduce context usage." |
| `when_to_use` | "Additional context for when Claude should invoke the skill … Appended to `description` in the skill listing and counts toward the 1,536-character cap." |
| `disable-model-invocation` | "Set to `true` to prevent Claude from automatically loading this skill." |
| `user-invocable` | "Set to `false` to hide from the `/` menu. Use for background knowledge users shouldn't invoke directly." |
| `allowed-tools` | "Tools Claude can use without asking permission during the turn that invokes this skill. The grant clears when you send your next message." |
| `disallowed-tools` | "Tools removed from Claude's available pool while this skill is active." |
| `paths` | "Glob patterns that limit when this skill is activated. … When set, Claude loads the skill automatically only when working with files matching the patterns." |
| `context: fork` / `agent` / `background` | run the skill as a subagent |
| `model`, `effort`, `hooks`, `argument-hint`, `arguments`, `shell` | see doc |

**`paths` is the sleeper field for a Flutter repo.** A `flutter-widgets` skill with `paths: lib/**/*.dart` only auto-loads when Dart files are in play — it costs listing budget but not false triggers.

Two Claude-Code-only levers worth knowing:

- **Invocation control matrix**, verbatim:
  > | Frontmatter                      | You can invoke | Claude can invoke | When loaded into context                                     |
  > | (default)                        | Yes            | Yes               | Description always in context, full skill loads when invoked |
  > | `disable-model-invocation: true` | Yes            | No                | Description not in context, full skill loads when you invoke |
  > | `user-invocable: false`          | No             | Yes               | Description always in context, full skill loads when invoked |

- **Lifecycle** — this changes how you write:
  > "When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session. … Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps."

  And on compaction:
  > "Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens."

  → **Put the non-negotiable rules in the first 5,000 tokens of the file.** Anything after that is dropped on compaction.

### 1.3 Directory layout

Verbatim from the spec:

> ```
> skill-name/
> ├── SKILL.md          # Required: metadata + instructions
> ├── scripts/          # Optional: executable code
> ├── references/       # Optional: documentation
> ├── assets/           # Optional: templates, resources
> └── ...               # Any additional files or directories
> ```

Verbatim from Claude Code docs (note it shows `examples/`, not `assets/`):

> ```
> my-skill/
> ├── SKILL.md           # Main instructions (required)
> ├── template.md        # Template for Claude to fill in
> ├── examples/
> │   └── sample.md      # Example output showing expected format
> └── scripts/
>     └── validate.sh    # Script Claude can execute
> ```

Both are fine — the spec's "any additional files or directories" covers `examples/`. Anthropic's `webapp-testing` and `internal-comms` both ship `examples/`.

### 1.4 Progressive disclosure, quoted

> 1. **Metadata** (~100 tokens): The `name` and `description` fields are loaded at startup for all skills
> 2. **Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
> 3. **Resources** (as needed): Files (e.g. those in `scripts/`, `references/`, or `assets/`) are loaded only when required
>
> Keep your main `SKILL.md` under 500 lines. Move detailed reference material to separate files.
> — [spec](https://agentskills.io/specification)

### 1.5 Discovery in Claude Code

> | Location   | Path                                     | Applies to                     |
> | Enterprise | See managed settings                     | All users in your organization |
> | Personal   | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects              |
> | Project    | `.claude/skills/<skill-name>/SKILL.md`   | This project only              |
> | Plugin     | `<plugin>/skills/<skill-name>/SKILL.md`  | Where plugin is enabled        |

> "When skills share the same name across levels, enterprise overrides personal, and personal overrides project."

> "Project skills load from `.claude/skills/` in your starting directory and in every parent directory up to the repository root… Claude Code also discovers skills from nested `.claude/skills/` directories on demand."

Live reload works for SKILL.md text; a **newly created top-level skills directory needs a restart**.

---

## 2. Anthropic's own published skills — the survey

All 17 read end to end. Frontmatter fields used, length, and bundled dirs:

| Skill | Lines | Words | Frontmatter fields | Bundled |
| --- | ---: | ---: | --- | --- |
| `internal-comms` | 32 | 211 | name, description, license | `examples/` (4 md) |
| `frontend-design` | 55 | 1336 | name, description, license | — |
| `theme-factory` | 59 | 486 | name, description, license | `themes/` (10 md), `theme-showcase.pdf` |
| `brand-guidelines` | 73 | 329 | name, description, license | — |
| `web-artifacts-builder` | 73 | 446 | name, description, license | `scripts/` (2 sh + tarball) |
| `docx` | 91 | 975 | name, description, license | `scripts/` (+ full OOXML XSD schemas) |
| `webapp-testing` | 95 | 501 | name, description, license | `scripts/`, `examples/` |
| `xlsx` | 99 | 1312 | name, description, license | `scripts/` |
| `canvas-design` | 129 | 1749 | name, description, license | `canvas-fonts/` |
| `mcp-builder` | 236 | 1143 | name, description, license | `reference/` (4 md), `scripts/` |
| `pptx` | 238 | 3129 | name, description, license | `scripts/` |
| `slack-gif-creator` | 254 | 1103 | name, description, license | `core/`, `requirements.txt` |
| `pdf` | 314 | 1007 | name, description, license | `forms.md`, `reference.md` (611 lines), `scripts/` (8 py) |
| `doc-coauthoring` | 375 | 2466 | name, description | — |
| `algorithmic-art` | 404 | 2763 | name, description, license | `templates/` |
| `skill-creator` | 485 | 5205 | name, description | `agents/`, `assets/`, `eval-viewer/`, `references/`, `scripts/` |
| `claude-api` | 546 | 9556 | name, description, license | 8 per-language dirs |

**Observations that matter:**

- **Nobody uses `version:`.** Every skill uses `name` + `description`, and open-source ones add `license`. That is the whole vocabulary.
- **Median 129 lines.** Two skills (`skill-creator` 485, `claude-api` 546) push the limit; `claude-api` exceeds it and is the only one that does.
- **The newest, densest skills are the shortest.** `docx` (91 lines) and `xlsx` (99 lines) carry more operational knowledge per line than `pdf` (314 lines), which spends most of its length on `pypdf`/`pdfplumber` snippets Claude already knows.
- The official **template** is six lines:

```markdown
---
name: template-skill
description: Replace with description of the skill and when Claude should use it.
---

# Insert instructions below
```

### 2.1 `docx` — the model to copy (91 lines)

Frontmatter, verbatim:

```yaml
---
name: docx
description: "Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation."
license: Proprietary. LICENSE.txt has complete terms
---
```

Note the **negative trigger** at the end (`Do NOT use for PDFs…`). Four of the five document skills do this.

Section structure:

```
# DOCX creation, editing, and analysis
  <one-sentence framing + 3-row decision table: Create / Edit / Read>
  <note: script paths are relative to this skill's directory>
## Creating with docx-js — gotchas     ← 12 bullets, each a single footgun
## Verify the output                   ← render to image and LOOK at it
## Editing existing documents          ← exact bash pipeline
## Comments                            ← exact script invocations
## Dependencies                        ← one line
```

The opening is a **routing table**, not prose:

```markdown
| Task | Approach |
|---|---|
| **Create** a new document | Write a `docx` (npm) script — see gotchas below |
| **Edit** an existing document | `unzip` → edit `word/document.xml` → `zip` (docx-js cannot open existing files) |
| **Read** content | `pandoc -t markdown file.docx` |
```

Its "gotchas" are pure delta-knowledge — each line is something Claude would get wrong:

> - **Page size defaults to A4.** For US Letter set `page: { size: { width: 12240, height: 15840 } }` (DXA; 1440 = 1″).
> - **Table shading:** use `ShadingType.CLEAR`, never `SOLID` (renders black).
> - **Lists:** never insert `•` literally; use a `numbering` config with `LevelFormat.BULLET`.
> - **Never use `\n`** — use separate `Paragraph` elements.

It ends on a bare dependency line — no summary, no sign-off.

### 2.2 `xlsx` — how to state hard requirements (99 lines)

Its `## Requirements for every output` is the cleanest "non-negotiables" block in the corpus. Verbatim excerpts:

> - **Zero formula errors.** Never ship while `recalc.py` reports `errors_found`. If you think an error predates you, prove it: load the *original* with `data_only=True` and look at that cell. An error you introduced looks exactly like one you inherited.
> - **Use formulas, never hardcoded results.** Write `sheet['B10'] = '=SUM(B2:B9)'`, not the Python-computed total. The sheet must recalculate when its inputs change.
> - **Follow the user's spec literally.** Exact tab names, exact column headers, and the formula they spelled out. A redesign that computes something else fails, however elegant.
> - **Editing an existing file: match its conventions exactly.** They override every guideline here.

And the hardest prohibition in the whole corpus, which is worth studying because it explains *why*:

> - **Never use `XLOOKUP`, `XMATCH`, `SORT`, `FILTER`, `UNIQUE`, or `SEQUENCE`.** The runtime's LibreOffice cannot evaluate them under *any* prefix. Newer builds do evaluate them, but they are spilling array functions and an openpyxl-written file has no spill metadata, so only the top-left cell of the range gets a value — and `recalc.py` reports `total_errors: 0` on the truncated result. Use `INDEX`/`MATCH` for lookups, and sort, filter, and de-duplicate in Python before writing the cells.

Structure: **prohibition + mechanism + the approved substitute, in one bullet.** No bare "never do X".

It also anticipates the false-confidence failure:

> **A green recalc proves your formulas *evaluate*, not that they are *right*.**

### 2.3 `internal-comms` — the minimum viable dispatcher (32 lines)

The entire body is: when-to-use bullets, a numbered "load the right file from `examples/`" dispatcher, and a `## Keywords` line. That's it. This is the pattern for a skill whose value is *routing to the right reference*, and it is 211 words.

```markdown
## How to use this skill

To write any internal communication:

1. **Identify the communication type** from the request
2. **Load the appropriate guideline file** from the `examples/` directory:
    - `examples/3p-updates.md` - For Progress/Plans/Problems team updates
    - `examples/company-newsletter.md` - For company-wide newsletters
    ...
3. **Follow the specific instructions** in that file

## Keywords
3P updates, company newsletter, company comms, weekly update, faqs, ...
```

The `## Keywords` section is a triggering hedge — extra search surface in the body for when the description gets truncated.

### 2.4 `webapp-testing` — the black-box-scripts doctrine (95 lines)

Two things here are directly reusable:

**A rule about the agent's own context hygiene**, verbatim:

> **Always run scripts with `--help` first** to see usage. DO NOT read the source until you try running the script first and find that a customized solution is abslutely necessary. These scripts can be very large and thus pollute your context window. They exist to be called directly as black-box scripts rather than ingested into your context window.

**An ASCII decision tree** — the only one in Anthropic's corpus:

```
User task → Is it static HTML?
    ├─ Yes → Read HTML file directly to identify selectors
    │         ├─ Success → Write Playwright script using selectors
    │         └─ Fails/Incomplete → Treat as dynamic (below)
    └─ No (dynamic webapp) → Is the server already running?
        ├─ No → Run: python scripts/with_server.py --help
        └─ Yes → Reconnaissance-then-action: ...
```

Plus a two-line `## Common Pitfall` using ❌/✅ — a compressed prohibition form:

> ❌ **Don't** inspect the DOM before waiting for `networkidle` on dynamic apps
> ✅ **Do** wait for `page.wait_for_load_state('networkidle')` before inspection

### 2.5 `skill-creator` — Anthropic's own authoring guidance

The single most opinionated statement about how to write skills, verbatim from `anthropics/skills/skills/skill-creator/SKILL.md`:

> Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs. Use theory of mind and try to make the skill general and not super-narrow to specific examples. Start by writing a draft and then look at it with fresh eyes and improve it.

And on the trigger problem:

> Note: currently Claude has a tendency to "undertrigger" skills -- to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit "pushy". So for instance, instead of "How to build a simple fast dashboard to display internal Anthropic data.", you might write "How to build a simple fast dashboard to display internal Anthropic data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"

And a direct warning against the ALL-CAPS style:

> If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag — if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important.

And the strongest signal for when to bundle a script:

> **Look for repeated work across test cases.** … If all 3 test cases resulted in the subagent writing a `create_docx.py` or a `build_chart.py`, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it.

---

## 3. Community collections

### 3.1 `obra/superpowers` (262k★) — the discipline-skill school

14 skills, 62–679 lines. Frontmatter is minimal everywhere: `name` + `description`, nothing else. Descriptions **always start with "Use when…"**:

```yaml
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
```

Its recurring section skeleton (from `writing-skills/SKILL.md`, verbatim):

```markdown
# Skill Name
## Overview          — What is this? Core principle in 1-2 sentences.
## When to Use       — bullet list with SYMPTOMS; when NOT to use
## Core Pattern      — before/after comparison
## Quick Reference   — table for scanning
## Implementation    — inline code, or link out
## Common Mistakes   — what goes wrong + fixes
## Real-World Impact — optional
```

**Four devices this collection invented that are worth stealing:**

1. **The Iron Law** — one boxed sentence that is the whole skill:
   ```
   NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
   ```
2. **The spirit-vs-letter cutoff**, one line placed early: *"Violating the letter of this rule is violating the spirit of this rule."* This kills a whole class of rationalisation.
3. **The rationalization table** — a two-column table of every excuse the agent made in baseline testing:

   | Excuse | Reality |
   |--------|---------|
   | "Should work now" | RUN the verification |
   | "I'm confident" | Confidence ≠ evidence |
   | "Linter passed" | Linter ≠ compiler |
   | "I'm tired" | Exhaustion ≠ excuse |

4. **Red Flags — STOP** — a self-check list of the *symptoms of about to violate*:
   > - Using "should", "probably", "seems to"
   > - Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
   > - Thinking "just this once"

**Its most important finding — when NOT to use prohibitions.** Verbatim from `writing-skills/SKILL.md`:

> | Baseline failure | Right form | Wrong form |
> |---|---|---|
> | Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags | Soft guidance ("prefer...", "consider...") |
> | Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
> | Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
> | Behavior should depend on a condition | Conditional keyed to an observable predicate | Unconditional rule + exemption clauses |

> **Why prohibitions backfire on shaping problems:** under a competing incentive … the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control …
> - **No nuance clauses.** "Don't X unless it matters" reopens the negotiation …
> - **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks.

**This is the key insight for our design-system skills.** "Never invent a second button style" is a *shaping* problem, not a discipline problem — so the right form is *"there is one Button; here is its full API; here is the file it lives in"*, not a list of don'ts.

**Where superpowers contradicts Anthropic** — flagged, not resolved:

> `description`: Third-person, describes ONLY when to use (NOT what it does)
> **NEVER summarize the skill's process or workflow**

Anthropic says the description must contain *both* what it does and when to use it. The reconciliation: state **what** at capability level ("Applies the design system's Button/Card/Field components") and **when** ("whenever building any Flutter UI") — but never the *steps*. Superpowers' evidence is specifically that a description summarising the *workflow* ("dispatches subagent per task with code review between tasks") caused agents to follow the description and skip the body. Follow Anthropic's rule; heed superpowers' caveat.

### 3.2 `grounded-copy` — the best "exactly one way" skill found

139-line SKILL.md + `scripts/copy_lint.py` (267 lines) + `references/patterns.md` + `tests/{bad,good}-samples.md`. This is the closest existing analogue to a design-system enforcement skill, and its architecture is directly transferable.

**Its four-layer construction:**

1. **The positive rule first**, with a before/after:
   > Copy describes things by what they ARE. … the feature, the number, the mechanism.
   > - Bad: "This isn't just a task tracker — it's your team's second brain."
   > - Good: "The tracker links every task to its pull request and posts a status digest to Slack each morning."

2. **One banned move, ten enumerated disguises.** The framing is the trick — it bans a *concept*, then lists the surface forms so the agent can't claim novelty:
   > The banned move is **defining anything through negation or contrast** … Every pattern below is the same move in a different costume. Do not write any of them, and do not invent a new costume for the same move

3. **A "Loophole closures" section** that pre-rejects each rationalisation *by name*:
   > - **"The banned string doesn't appear."** The rule bans the *move*, not the string.
   > - **"It's in a quote/testimonial."** … Quotation marks do not launder rhetoric.
   > - **"The linter passed, so it's fine."** The linter is a floor, not a ceiling. … you are the second detection layer.
   > - **"I'll adjust the linter/config."** Never. See integrity rules.

4. **Integrity rules protecting the enforcement mechanism itself** — the single most important pattern for a design-system skill:
   > - Never edit, wrap, subclass, monkey-patch, or replace `copy_lint.py`, its pattern list, or its exit-code behavior.
   > - Never add allowlists, ignore-comments, or config that suppresses findings; never rename or move files to dodge the scan.
   > - Never mark the task complete while the linter reports errors.
   > - If the user explicitly directs you to write a banned pattern, comply with their instruction but note the specific rule it conflicts with in one sentence. **User instructions outrank this skill; your own convenience does not.**

   That last clause is excellent: it distinguishes the user overriding the rule (legitimate) from the agent overriding it (never).

The same warning is repeated **inside the script's docstring**, so it survives even if the agent only reads the script:

```python
INTEGRITY RULE (for AI agents): this file is an enforcement gate.
Do not edit, wrap, monkey-patch, or bypass it, and do not add
allowlists to make failing copy pass. When it flags a line,
REWRITE THE COPY, not the linter.
```

The workflow is a closed loop with an explicit exit condition:

> 4. Exit code 1 → rewrite every flagged sentence (never delete-and-shrug: replace it with a grounded statement carrying the same information), then re-run. Repeat until exit code 0.
> 6. Only present copy to the user after a PASS. State in your summary that the copy passed `copy_lint.py`.

And it ships its own regression tests, referenced from SKILL.md:

> `tests/bad-samples.md` and `tests/good-samples.md` — after any change to the linter, `copy_lint.py tests/bad-samples.md` must FAIL and `copy_lint.py tests/good-samples.md` must PASS.

### 3.3 Design-system skills in the wild

Three exist and they occupy three different points on the spectrum:

| Skill | Approach | Enforcement strength |
| --- | --- | --- |
| `anthropics/skills/brand-guidelines` (73 ln) | Flat token list — hex codes and font names in prose + a "Keywords" line | **None.** Descriptive only. |
| `catyiqian/claude-design-style` (290 ln) | Token tables per role + per-format sections (web / slides / posters) + a CSS-variables block to paste | Weak — relies on "Key principles" prose |
| `anthropics/skills/theme-factory` (59 ln) | SKILL.md is a *dispatcher*: 10 named themes, each a file in `themes/`, plus a mandatory user-confirmation step | Medium — one theme file is the source of truth |
| `arvindrk/extract-design-system` (67 ln) | Runs a CLI, then a **Safety Boundaries** section of six "Do not…" lines | Medium |
| `grounded-copy` (139 ln) | Positive rule + enumerated violations + loophole closures + **executable linter** + integrity rules | **Strong** |

The only device that reliably stops invention is the one `grounded-copy` uses: **a check the agent runs and is forbidden from weakening.**

`theme-factory` contributes a second useful device — a **mandatory human gate** before any styling happens:

> 1. **Show the theme showcase**: Display the `theme-showcase.pdf` … 2. **Ask for their choice** … 3. **Wait for selection**: Get explicit confirmation … 4. **Apply the theme**

`catyiqian/claude-design-style` contributes the *table-per-role* token format, which is the right shape for Flutter theme tokens:

```markdown
| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary (Brand) | Warm Terracotta / Clay | `#D97757` | CTAs, accent elements, brand marks |
| Neutral 900 | Charcoal | `#1A1A1A` | Primary text |
```

…paired with an absolute, mechanism-explaining prohibition:

> The background is NEVER pure white (`#FFFFFF` for backgrounds) — use the warm off-white `#FAF8F5`… Cards and elevated surfaces may use `#FFFFFF`.

Note the **scoped exception baked into the rule itself**, rather than as a trailing "unless" clause — exactly what superpowers recommends.

### 3.4 Flutter / mobile skill catalogues

There is essentially **one** published Flutter skill catalogue: `acdgbrasil/dart-modern-claude-kit` (0★, Apr 2026). It is a useful *anti-*example.

`skills/flutter-modern/SKILL.md` is **984 lines** — nearly double the documented limit — with a 12-line YAML block-scalar description that is a keyword dump:

```yaml
description: >
  Modern Flutter & Dart specialist skill — opinionated MVVM + Logic Layer with Command,
  Result, Selectors/Connectors, Atomic Design, and a 5-policy contract (encapsulation,
  pattern matching, concurrency, MVVM+Logic, agent testing). Activates when the user
  mentions: Flutter, Dart, widget, ViewModel, UseCase, Repository, Service, MVVM,
  Command pattern, ChangeNotifier, ListenableBuilder, GoRouter, Riverpod, Provider,
  ...
```

That description is ~700 characters of mostly keywords — under the 1024 cap but it will be one of the first things truncated when the listing budget is tight, and the keyword soup gives Claude little signal about *when*.

What it does get right, and we should copy:

- **The reference-per-policy split.** 14 files in `references/`, each named for one policy (`encapsulation_policy.md`, `pattern_matching_policy.md`, `ui_layer.md`, `tests.md`) — and SKILL.md numbers them 1–14 with a one-line description of each.
- **A "these references prevail" clause**: *"When in doubt, **these references prevail** over generic web guidance."* Useful when the model's priors about Flutter conflict with the project's.
- **The layer table** — one row per architectural layer, with a "Key Rules" column. Compact and scannable:
  > | Layer | Responsibility | Key Rules |
  > | **View** | Display data, capture events. Decides NOTHING. | Max 1 widget per file. No ViewModel refs in Atoms/Molecules. |
- **A fixed implementation order**: `Model -> Service -> Repository -> UseCase -> ViewModel -> View` with *"Inside-out. NEVER start from the View."*
- **A tool gate**: *"Before considering ANY task complete, you MUST use the Dart MCP Server: `analyze_files`… `run_tests`… `dart_format`…"*

Its `vibe-designer` skill (390 lines) is a genuinely novel pattern: a **read-only-scope skill** for UI work. Its description contains an explicit negative scope (translated): *"Does NOT activate for ViewModel, UseCase, Repository, Service, business logic, state, data, or anything beyond the visual layer."* Its body opens with **"RULE ZERO: Understand Before Touching"** — a four-step read-only context protocol, then a **fill-in-the-blank response template** the agent must emit and get confirmed before editing anything. That template-as-contract device is worth stealing for any skill where the agent must not act unilaterally.

---

## 4. What skill scripts actually do

Catalogued from every script in the corpus. Five categories, all Python or Bash:

### 4.1 Validators / gates (the most valuable category)

| Script | Lang | Lines | What it does | Invocation |
| --- | --- | ---: | --- | --- |
| `grounded-copy/scripts/copy_lint.py` | py | 267 | ~80 compiled regexes over 9 languages; ERROR/WARN levels; **exit 1 = rewrite** | `python3 scripts/copy_lint.py FILE…` or `--stdin` |
| `xlsx/scripts/recalc.py` | py | 308 | Recalculates via LibreOffice, rewrites in place, emits JSON `{status, total_formulas, total_errors, error_summary}` | `python scripts/recalc.py output.xlsx [timeout]` |
| `docx/scripts/office/validate.py` | py | 173 | XSD-validates OOXML parts; `--auto-repair`; `--author` checks every edit is tracked | `python scripts/office/validate.py out.docx --original doc.docx` |
| `docx/scripts/office/validators/redlining.py` | py | 299 | Undoes new tracked changes, diffs against original → finds **untracked** edits | imported by `validate.py` |
| `skill-creator/scripts/quick_validate.py` | py | 102 | Validates a SKILL.md: frontmatter parses, allowed keys only, name kebab-case ≤64, description ≤1024, no angle brackets | `python quick_validate.py <skill_dir>` |
| `slack-gif-creator/core/validators.py` | py | 136 | Checks GIF against Slack's size/dimension limits | imported |
| `pdf/scripts/check_bounding_boxes.py` | py | 65 | Detects overlapping form-field rectangles before filling | `python … fields.json` |

The **`quick_validate.py` allow-list is a schema oracle** and is worth quoting in full, because it tells us exactly which frontmatter keys Anthropic considers legal:

```python
ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility'}
```

`version:` is **not** in that set — it returns `"Unexpected key(s) in SKILL.md frontmatter"`. Yet `plugin-dev/skill-development`, `hookify/writing-rules`, and `example-plugin/example-skill` in `claude-plugins-official` all ship `version: 0.1.0`. Claude Code tolerates it; the standard's validator does not.

### 4.2 Scaffolding generators

- `web-artifacts-builder/scripts/init-artifact.sh` (322 lines) — detects Node version, scaffolds Vite + TS + Tailwind + 40 shadcn components from a bundled tarball, configures path aliases. Invoked `bash scripts/init-artifact.sh <project-name>`.
- `web-artifacts-builder/scripts/bundle-artifact.sh` (53 lines) — `set -e`, checks `package.json` and `index.html` exist with a clear error, then Parcel + html-inline into one file.

Both fail loudly with actionable messages:
```bash
if [ ! -f "package.json" ]; then
  echo "❌ Error: No package.json found. Run this script from your project root."
  exit 1
fi
```

### 4.3 Harness / lifecycle wrappers

- `webapp-testing/scripts/with_server.py` (105 lines) — starts N servers, waits for their ports, runs a command, tears down. This exists purely so the agent's script contains *only* Playwright logic. Documented as a black box (see §2.4).

### 4.4 Deterministic transformers

- `docx/scripts/merge_runs.py` (310) — coalesces fragmented `<w:r>` runs so find-and-replace works. Its docstring explains *why* the naive approach fails, which is the model of a good script header.
- `docx/scripts/comment.py` (368) — writes the six cross-linked XML parts a Word comment needs, then **prints the snippet the agent must paste into `document.xml`**. Script does the mechanical part; agent does the placement.
- `pptx/scripts/thumbnail.py` (311) — renders slides into a labelled grid so the agent can *look* at its output.

### 4.5 Meta / eval tooling

`skill-creator/scripts/` — `run_eval.py`, `run_loop.py`, `improve_description.py`, `aggregate_benchmark.py`, `package_skill.py`, plus `eval-viewer/generate_review.py` (471 lines, stdlib-only HTTP server serving a review UI). These shell out to `claude -p` and are how Anthropic tunes descriptions.

### 4.6 The design rules for agent-facing scripts

Verbatim from [agentskills.io/skill-creation/using-scripts](https://agentskills.io/skill-creation/using-scripts):

> **Avoid interactive prompts.** This is a hard requirement of the agent execution environment. Agents operate in non-interactive shells — they cannot respond to TTY prompts… A script that blocks on interactive input will hang indefinitely.

> **Document usage with `--help`.** `--help` output is the primary way an agent learns your script's interface.

> **Write helpful error messages.** … say what went wrong, what was expected, and what to try:
> ```
> Error: --format must be one of: json, csv, table.
>        Received: "xml"
> ```

> **Use structured output.** Prefer structured formats — JSON, CSV, TSV — over free-form text.
> **Separate data from diagnostics:** send structured data to stdout and progress messages, warnings, and other diagnostics to stderr.

> * **Idempotency.** Agents may retry commands. "Create if not exists" is safer…
> * **Meaningful exit codes.** Use distinct exit codes for different failure types … and document them in your `--help`
> * **Predictable output size.** Many agent harnesses automatically truncate tool output beyond a threshold (e.g., 10-30K characters)…

And from `platform.claude.com` best practices — **solve, don't defer**:

> When writing scripts for Skills, handle error conditions rather than deferring to Claude. … Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it?

**Path resolution.** Reference bundled scripts with `${CLAUDE_SKILL_DIR}` when the skill is Claude-Code-specific, and pre-approve the exact command:

```yaml
---
name: render-chart
description: Render a chart from a CSV file
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
---

Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render the chart.
```

> "The `allowed-tools` rule then matches the exact command the skill body tells Claude to run, so the script runs without prompting." (Requires CC ≥ v2.1.129.)

For portability across agents, use plain relative paths instead (`scripts/foo.py`), which the spec mandates: *"Use relative paths from the skill root."*

---

## 5. How to encode "there is exactly one way to do this"

Synthesised from `grounded-copy`, `xlsx`, `theme-factory`, `claude-design-style`, and superpowers' form-matching table. Five layers, weakest to strongest — **use at least layers 1, 2, and 5.**

**Layer 1 — Name the single source of truth, with a path.**
Not "use the design tokens" but "every colour comes from `lib/theme/app_colors.dart`; a raw `Color(0x…)` anywhere else is a defect." The agent needs a file to open, not a principle.

**Layer 2 — Enumerate the complete API as a table.** One row per component, so "there is no Button variant for this" is checkable rather than a judgement call:

```markdown
| Component | File | Variants | Never |
|---|---|---|---|
| `AppButton` | `lib/ui/atoms/app_button.dart` | `primary`, `secondary`, `destructive`, `ghost` | Never `ElevatedButton`, `TextButton`, `FilledButton` directly |
| `AppCard`   | `lib/ui/atoms/app_card.dart`   | `flat`, `elevated`                             | Never a bare `Container` with `BoxDecoration` |
```

The "Never" column is doing the work: the prohibition sits *next to* the approved alternative, in the same row. This is the xlsx pattern (prohibition + mechanism + substitute in one unit).

**Layer 3 — Ban the *move*, then enumerate its disguises.** From `grounded-copy`: the rule bans "defining through negation", then lists ten costumes and says *"do not invent a new costume for the same move."* For a design system: ban "introducing a visual primitive outside the token system", then enumerate — hardcoded hex, hardcoded `EdgeInsets` numbers, a local `TextStyle`, a one-off `BorderRadius`, a `Theme.of(context).copyWith(...)` at a call site.

**Layer 4 — Pre-reject the rationalisations by name.** Baseline testing tells you which ones. Predictable ones for a design system:
- *"It's a one-off screen."* Scope is every widget in `lib/`, including demo and debug screens.
- *"The design calls for a colour that isn't a token."* Then a token is missing. Add it to the token file in a separate step and say so; do not inline it.
- *"I used `Theme.of(context)` so it's themed."* Only tokens named in the table are the design system. A themed value derived at a call site is still a second source of truth.
- *"The lint passed."* The lint is a floor. You are the second detection layer.

**Layer 5 — Ship a check and forbid weakening it.**
A `scripts/check_design_system.sh` doing exactly what `copy_lint.py` does — grep for `Color(0x`, `ElevatedButton(`, `TextStyle(`, raw `EdgeInsets.all(<number>)` outside the token/atoms directories; exit 1 with file:line. Then the integrity clause, adapted verbatim in shape from `grounded-copy`:

> - Never edit, wrap, or bypass `scripts/check_design_system.sh`, its pattern list, or its exit-code behavior.
> - Never add ignore-comments, allowlist entries, or `// ignore:` directives to make a failing file pass.
> - Never mark the task complete while the check reports errors.
> - If the user explicitly asks for a value outside the token system, comply and note in one sentence which rule it conflicts with. User instructions outrank this skill; your own convenience does not.

Plus the human gate from `theme-factory` for anything that *changes* the system: show the current tokens, ask, wait for explicit confirmation, then apply.

---

## 6. Template SKILL.md — distilled

Each block is annotated with the source of the pattern and why it's there. Delete any block that doesn't earn its tokens — Anthropic's own median skill is 129 lines.

````markdown
---
# name must equal the directory name; [a-z0-9-], ≤64 chars, no leading/trailing/double hyphen.
# Gerund or noun-phrase. Never "helper"/"utils"/"tools". Never contains "claude" or "anthropic".
name: flutter-design-system

# ≤1024 chars (hard cap); the listing truncates description+when_to_use at 1,536.
# Front-load the key use case — the tail is what gets cut.
# Third person. Says WHAT (capability level) + WHEN (concrete triggers) + WHEN NOT.
# Be "pushy": name situations where it applies even if the user doesn't use the domain word.
# Do NOT summarise the workflow — agents will follow the summary instead of reading the body.
description: >
  Applies this project's single design system to every Flutter widget — the token file,
  the atom components, and the spacing/typography scales. Use this skill whenever building,
  restyling, or reviewing ANY Flutter UI: new screens, new widgets, layout changes, colour or
  spacing changes, dark-mode work, or a review that touches lib/ui/. Use it even when the
  request never says "design system", "theme", or "tokens" — for example "make this screen
  look better", "add a save button", or "fix the padding". Do NOT use for ViewModel, repository,
  routing, or data-layer changes that touch no widget code.

# Optional. Limits auto-activation to matching files — cheap precision for a repo-scoped skill.
paths: lib/**/*.dart

# Optional. Pre-approves the exact commands the body tells the agent to run (Claude Code only).
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/check_design_system.sh *)
---

# Flutter Design System
<!-- WHY: H1 restates the skill in three words. Costs one line, orients the reader. -->

<!-- OPENING: one or two sentences of framing, then immediately a routing table or the
     single core principle. Anthropic's newest skills (docx, xlsx) open with a decision
     table in the first ten lines. Never open with "This skill provides guidance on…". -->

Every visual value in this app comes from one place. There is exactly one Button, one Card,
one text scale, and one spacing scale. Inventing a second is the defect this skill exists to
prevent.

| Task | Do this |
|---|---|
| **Need a colour / size / radius** | Read `lib/theme/app_tokens.dart`. Never write a literal. |
| **Need a UI element** | Use the atom from the table below. Never a raw Material widget. |
| **The token or variant you need doesn't exist** | Stop. Add it to the token file as a separate, announced change. |

## The component contract
<!-- WHY: layer 2 above. The complete enumerated API makes "there is no variant for this"
     a checkable fact rather than a judgement call. The "Never" column puts the prohibition
     in the same row as its replacement — the xlsx pattern. -->

| Component | File | Variants | Never use instead |
|---|---|---|---|
| `AppButton` | `lib/ui/atoms/app_button.dart` | `primary` `secondary` `destructive` `ghost` | `ElevatedButton`, `TextButton`, `FilledButton`, `OutlinedButton` |
| `AppCard` | `lib/ui/atoms/app_card.dart` | `flat` `elevated` | `Container` + `BoxDecoration`, `Card` |
| `AppTextField` | `lib/ui/atoms/app_text_field.dart` | `text` `password` `search` | `TextField`, `TextFormField` |

## Gotchas
<!-- WHY: agentskills.io calls this "the highest-value content in many skills" — concrete
     corrections to mistakes the agent WILL make, not general advice. Keep in SKILL.md,
     not a reference file: the agent must read these before it hits the situation. -->

- Spacing is `AppSpacing.md`, not `16`. The scale is 4/8/12/16/24/32; there is no 20 and no 14.
- `AppButton` already includes its own padding and min-height. Wrapping it in `Padding` breaks
  the 44pt touch target the accessibility tests assert on.
- Dark mode is not `Theme.of(context).brightness`. Read `AppTokens.of(context)`, which resolves
  both modes; a raw brightness check bypasses the high-contrast override.

## Workflow
<!-- WHY: checklists are the documented pattern for multi-step tasks with validation gates.
     Numbered steps + an explicit "only proceed when" gate stops the agent skipping step 4. -->

1. Read `lib/theme/app_tokens.dart` before writing any widget code.
2. Build the widget from the atoms above.
3. Run the check:
   ```bash
   bash scripts/check_design_system.sh lib/
   ```
4. Exit code 1 → replace every flagged literal with its token and re-run. Repeat until 0.
5. Only report the work complete after a clean run, and say so in your summary.

## Loophole closures — read before claiming compliance
<!-- WHY: layer 4. Each of these is a rationalisation observed in baseline testing.
     Naming them individually is what makes them stop working. Only include the ones you
     have actually seen; a table of imagined excuses is dead weight. -->

- **"It's a one-off / debug screen."** Scope is every widget under `lib/`, no exceptions.
- **"The design needs a colour that isn't a token."** Then a token is missing. Add it to the
  token file as its own announced change; never inline the value.
- **"I used `Theme.of(context)`, so it's themed."** Only the names in `AppTokens` are the
  design system. A value derived at a call site is a second source of truth.
- **"The check passed."** The check is a floor, not a ceiling. You are the second detection layer.

## Integrity rules
<!-- WHY: grounded-copy's decisive move. Without this the agent "fixes" a failing check by
     editing the check. The last clause is important: it lets the USER override while
     denying the AGENT the same latitude. -->

- Never edit, wrap, or bypass `scripts/check_design_system.sh`, its pattern list, or its
  exit codes; never add `// ignore:` directives or allowlist entries to make a file pass.
- Never mark work complete while the check reports errors.
- If the user explicitly asks for a value outside the system, comply and note in one sentence
  which rule it conflicts with. User instructions outrank this skill; your own convenience
  does not.

## References
<!-- WHY: one level deep, each with a WHEN-to-load trigger. "See references/ for details"
     is the documented anti-pattern; "read X if Y" is the documented pattern. -->

- `references/tokens.md` — the full token table with every hex value and scale step. Read when
  you need a value that isn't in the gotchas above.
- `references/motion.md` — durations, curves, and the reduced-motion rule. Read only when the
  change involves animation or transitions.
- `scripts/check_design_system.sh` — run it; do not read it unless it reports a bug in itself.
````

**What was deliberately left out and why:**

- No `## Overview` that restates the description. Pure duplication; Anthropic's `docx` and `xlsx` have none.
- No `version:`. Not in either schema; `quick_validate.py` rejects it.
- No ALL-CAPS `MUST`/`ALWAYS` sprinkled through prose — `skill-creator` explicitly calls that a yellow flag. The two places where absolute language *is* used (component table "Never", integrity rules) each carry the mechanism or the substitute alongside.
- No closing summary. Every high-quality skill read here ends on its last substantive section.

---

## 7. Pitfalls — how skill authoring goes wrong in practice

**P1 — The skill loads but the agent ignores it.** The docs name this directly:
> "If a skill seems to stop influencing behavior after the first response, the content is usually still present and the model is choosing other tools or approaches."
Fix: strengthen the description *and* the instructions, or move to hooks for deterministic enforcement. Re-invoke after compaction if the skill is large.

**P2 — Description truncation silently kills triggering.** The listing budget is 1% of the context window; when it overflows *"Claude Code drops descriptions starting with the skills you invoke least."* A repo with 25 skills can silently lose the descriptions of half of them. Mitigations: front-load the key use case; run `/doctor` for the listing cost; set low-priority skills to `"name-only"` in `skillOverrides`; raise `skillListingBudgetFraction`.

**P3 — Undertriggering by default.** `skill-creator` states Claude *"has a tendency to 'undertrigger' skills"*. Both agentskills.io and skill-creator prescribe the same fix: be pushy, list contexts explicitly, include "even if they don't explicitly mention X".

**P4 — Simple prompts never trigger any skill.**
> "Claude only consults skills for tasks it can't easily handle on its own — simple, one-step queries like 'read this PDF' may not trigger a skill even if the description matches perfectly."
So "read this file" style eval queries are worthless as tests, and a skill whose whole job is a one-liner may never fire.

**P5 — Descriptions that summarise the workflow become the skill.** superpowers documented an agent doing one code review instead of the flowchart's two, because the description said "code review between tasks". Removing the workflow summary fixed it.

**P6 — Prohibitions on shaping problems make the problem worse.** superpowers' head-to-head test: the prohibition arm produced *more* unwanted content than the no-guidance control. Classify the failure first (see §3.1 table).

**P7 — Nuance and exemption clauses.** *"Don't X unless it matters"* reopens the negotiation. *"This limit doesn't apply to code blocks"* still suppresses code blocks. Restructure so the rule cannot reach the exempt part.

**P8 — Bloat.** `flutter-modern` at 984 lines is nearly 2× the limit; `claude-api` at 546 is Anthropic's only overrun. agentskills.io: *"Overly comprehensive skills can hurt more than they help — the agent … may pursue unproductive paths triggered by instructions that don't apply to the current task."*

**P9 — Teaching Claude what it already knows.** The `pdf` skill spends ~200 lines on pypdf/pdfplumber/reportlab snippets. Compare `docx` (91 lines), which contains only footguns. Test: *"Would the agent get this wrong without this instruction?"* If no, cut it.

**P10 — Nested references.**
> "Claude may partially read files when they're referenced from other referenced files. … Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information."
One level deep. Always.

**P11 — Reference files without a load trigger.** *"Read `references/api-errors.md` if the API returns a non-200 status code"* beats *"see references/ for details."* A file the agent never opens is dead weight; a file the agent opens every time should have been in SKILL.md.

**P12 — Menus instead of defaults.** *"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or…"* One default, one escape hatch.

**P13 — Invalid frontmatter fails silently-ish.**
> "If the frontmatter YAML is malformed, Claude Code loads the skill body with empty metadata, so `/skill-name` still works but Claude has no `description` to match against. Run with `--debug` to see the parse error."
So a broken skill looks fine when you test it manually and never auto-triggers. Run `quick_validate.py` in CI.

**P14 — `name` ≠ directory name.** The spec requires they match; Claude Code takes the *command* from the directory for personal/project skills and from `name` for plugin skills. Divergence means the skill is invoked under a name that doesn't appear in its own file.

**P15 — `version:` / `tools:` in frontmatter.** Both appear in `claude-plugins-official` skills. Neither is in the Agent Skills spec or the Claude Code table, and `quick_validate.py` errors on unknown keys. Use `metadata:` for versioning.

**P16 — Untested skills.** Both official sources and superpowers converge: run the same prompts with and without the skill, in a fresh session. *"A fresh session matters because leftover context from authoring the skill will mask gaps in the written instructions."*

**P17 — Rules that could be mechanical are left as prose.** superpowers: *"Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)."* A design-system rule you can grep for should be a script, not a paragraph.

**P18 — Time-sensitive content.** Put deprecated material in a collapsed `<details>` "Old patterns" section instead of "if you're doing this before August 2025…".

**P19 — Skills scoped too narrowly.** *"Skills scoped too narrowly force multiple skills to load for a single task, risking overhead and conflicting instructions."* A 20-skill catalogue where five load per task is worse than eight coherent ones.

**P20 — Loading skill content stays for the whole session.** Every line is a recurring cost across every subsequent turn, not a one-time cost.

---

## 8. Contradictions between primary sources (unresolved — flagged)

| Point | `platform.claude.com` / spec | `superpowers/writing-skills` | `plugin-dev/skill-development` |
| --- | --- | --- | --- |
| Description content | "both what the Skill does and when to use it" | "describes ONLY when to use (NOT what it does)" | "This skill should be used when the user asks to '<phrase>'…" |
| Description opener | "Use when…" / capability-first both shown | must start with "Use when…" | must start with "This skill should be used when…" |
| Absolute language | "using stronger language such as 'MUST filter'" is suggested as a fix | prohibitions only for discipline failures | — |
| `skill-creator` (Anthropic) | — | — | contradicts both: ALL-CAPS MUST/ALWAYS is *"a yellow flag"* |
| Body length | <500 lines / <5k tokens | <500 words for most skills | 1,500–2,000 words, <3,000 |
| `version:` field | not in schema; validator rejects | not used | prescribes `version: 0.1.0` |

**Recommended resolution for our skills:** follow `platform.claude.com` + the spec (they are the normative pair), take superpowers' form-matching table and loophole devices as tactics, and treat `plugin-dev/skill-development` as the weakest source — it is older, prescribes a rejected frontmatter field, and its house style ("This skill should be used when…") burns ~30 characters of a budgeted field on boilerplate.

---

## 9. Sources — every URL actually fetched

Official documentation:
- https://code.claude.com/docs/en/skills — Claude Code skills reference (frontmatter table, discovery, lifecycle, budgets, troubleshooting)
- https://code.claude.com/docs/en/plugins-reference — plugin skill layout, skills-directory plugins
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices — Anthropic skill authoring best practices
- https://agentskills.io/specification — Agent Skills open standard (frontmatter schema, layout, progressive disclosure)
- https://agentskills.io/skill-creation/best-practices — scoping, gotchas, templates, checklists, validation loops
- https://agentskills.io/skill-creation/using-scripts — agent-facing script design
- https://agentskills.io/skill-creation/optimizing-descriptions — trigger evals, train/validation split
- https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md — skills-related release entries

Repositories cloned and read:
- https://github.com/anthropics/skills (`b29e7cf6`, 2026-07-24) — 17 skills, spec, template
- https://github.com/obra/superpowers (`3dcbd5c4`, 2026-07-23) — 14 skills
- https://github.com/anthropics/claude-plugins-official — via local marketplace clone (`skill-creator`, `frontend-design`, `plugin-dev`, `hookify`, `example-plugin`)
- https://github.com/HiroHyun/grounded-copy
- https://github.com/arvindrk/extract-design-system
- https://github.com/catyiqian/claude-design-style
- https://github.com/acdgbrasil/dart-modern-claude-kit

Individual files quoted:
- `anthropics/skills/skills/{docx,xlsx,pdf,internal-comms,webapp-testing,web-artifacts-builder,mcp-builder,brand-guidelines,theme-factory,skill-creator}/SKILL.md`
- `anthropics/skills/skills/skill-creator/scripts/quick_validate.py`
- `anthropics/skills/template/SKILL.md`
- `obra/superpowers/skills/{writing-skills,verification-before-completion,test-driven-development}/SKILL.md`
- `HiroHyun/grounded-copy/SKILL.md`, `scripts/copy_lint.py`
- `acdgbrasil/dart-modern-claude-kit/skills/{flutter-modern,vibe-designer}/SKILL.md`

Working copies (this machine): `/private/tmp/claude-501/-Users-zakariafatahi-50-apps-challenge-E01/9d30eaa5-a0ff-43e9-9f39-652c25d9ad59/scratchpad/`

---

## 10. Unverified / could not confirm

- **`display-name`, `default-enabled`, `fallback` frontmatter.** CC changelog v2.1.186 says *"Improved skill frontmatter: 'display-name', 'default-enabled', 'fallback', and 'metadata.*' keys now accept multiple case formats."* None of these appear in the `code.claude.com/docs/en/skills` frontmatter table. `defaultEnabled` **is** documented as a `plugin.json` field. Treat these as plugin-manifest fields, not SKILL.md fields, until documented otherwise. Do not use them.
- **`when_to_use`** is documented in Claude Code but is not in the Agent Skills spec — it is a Claude-Code-only extension. Portable skills should fold that content into `description`.
- **Exact token budget for the skill listing** — documented as "1% of the model's context window" and tunable via `skillListingBudgetFraction` / `SLASH_COMMAND_TOOL_CHAR_BUDGET`; the absolute character number for the model in use was not measured.
- **Whether Claude Code errors or ignores unknown frontmatter keys** (e.g. `version:`). Anthropic's spec validator rejects them; Claude Code appears to tolerate them (shipped skills use `version:` and work), but no doc states the behaviour. Avoid the question by not using them.
- **`paths` interaction with `disable-model-invocation`** — not documented; untested.
- **No mature published Flutter/mobile skill catalogue exists.** The only candidate (`dart-modern-claude-kit`, 0★) violates the length limit and has no scripts. There is no prior art to imitate here; we will be setting it.
