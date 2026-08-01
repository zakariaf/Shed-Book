# Claude Code Skills: Mechanics and Authoring Guide

Research date: July 27, 2026 | Verified against: Claude Code v2.1.218+, Anthropic platform 2026-07

## Bottom Line: Rules We Must Follow

| Rule | Source | Confidence |
|------|--------|-----------|
| **SKILL.md is required**; it's the entry point for every skill | [code.claude.com/docs/en/skills.md](https://code.claude.com/docs/en/skills.md) | high |
| **Frontmatter requires `name` and `description`; all other fields optional** | [platform.claude.com Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) | high |
| **`name` max 64 chars, lowercase + hyphens + numbers only, no XML tags, cannot contain "anthropic" or "claude"** | [platform.claude.com](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) | high |
| **`description` max 1024 chars, must be non-empty, no XML tags, drives auto-triggering via keyword matching** | [platform.claude.com](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) | high |
| **Description + `when_to_use` combined cap at 1,536 chars in skill listing** | [code.claude.com/docs/en/skills.md § Frontmatter reference](https://code.claude.com/docs/en/skills.md) | high |
| **Skills live in `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (personal)** | [code.claude.com/docs/en/skills.md § Where skills live](https://code.claude.com/docs/en/skills.md) | high |
| **Only SKILL.md metadata (name + description) loads at startup; full body loads only when invoked** | [platform.claude.com Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) | high |
| **`allowed-tools` grants tools for ONE turn only; grant clears on next user message** | [code.claude.com/docs/en/skills.md § Pre-approve tools](https://code.claude.com/docs/en/skills.md) | high |
| **`allowed-tools` does NOT apply in Agent SDK; use SDK's `allowedTools` config instead** | [code.claude.com/docs/en/agent-sdk/skills.md](https://code.claude.com/docs/en/agent-sdk/skills.md) | high |
| **`disable-model-invocation: true` prevents Claude from auto-invoking; only `/name` works** | [code.claude.com/docs/en/skills.md § Control who invokes](https://code.claude.com/docs/en/skills.md) | high |
| **`user-invocable: false` hides from `/` menu; only Claude can invoke** | [code.claude.com/docs/en/skills.md § Control who invokes](https://code.claude.com/docs/en/skills.md) | high |
| **`context: fork` runs skill in isolated subagent context; defaults to `background: true`** | [code.claude.com/docs/en/skills.md § Run skills in subagent](https://code.claude.com/docs/en/skills.md) | high |
| **SKILL.md body is capped at 500 lines for optimal performance; use supporting files for larger content** | [platform.claude.com best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) | high |
| **`!`command`` (shell injection) runs at skill load time; output replaces placeholder before Claude sees it** | [code.claude.com/docs/en/skills.md § Inject dynamic context](https://code.claude.com/docs/en/skills.md) | high |
| **Skills follow [agentskills.io open standard](https://agentskills.io); Claude Code extends it with `disable-model-invocation`, `context: fork`, etc.** | [code.claude.com intro to skills](https://code.claude.com/docs/en/skills.md) | high |
| **Nested `.claude/skills/` in monorepos are auto-discovered and namespaced as `subdirectory:skill-name`** | [code.claude.com § Automatic discovery from nested directories](https://code.claude.com/docs/en/skills.md) | high |
| **skill-creator plugin automates skill eval/iteration; installs from marketplace** | [code.claude.com § Run evals with skill-creator](https://code.claude.com/docs/en/skills.md) | high |

---

## SKILL.md Format and YAML Frontmatter Schema

### Structure (Required and Recommended)

Every skill file has two parts, separated by `---` markers:

```yaml
---
[YAML frontmatter — metadata about the skill]
---

[Markdown body — instructions Claude follows when the skill is invoked]
```

### Frontmatter Fields (Complete Reference)

From [code.claude.com/docs/en/skills.md § Frontmatter reference](https://code.claude.com/docs/en/skills.md):

| Field | Required | Type | Max length | Constraints | Notes |
|-------|----------|------|-----------|-------------|-------|
| `name` | No | String | 64 chars | Lowercase, numbers, hyphens only. No XML tags. Cannot contain "anthropic" or "claude". | Defaults to directory name. For plugins, overrides directory name in command. In personal/project skills, sets display label only. |
| `description` | Recommended | String | 1024 chars | Non-empty. No XML tags. | **Critical for auto-triggering.** Claude matches keywords here when deciding to invoke. Combined with `when_to_use`, capped at 1,536 chars in skill listing. **Must be in third person.** |
| `when_to_use` | No | String | Part of 1,536-char cap | Non-empty if present. | Appends to `description` in skill listing. Triggers examples or additional context for activation. |
| `argument-hint` | No | String | Unconstrained | Any text. | Shown during autocomplete. Example: `[issue-number]` or `[filename] [format]`. |
| `arguments` | No | List or space-separated string | Unconstrained | Names only (no special characters). | Named positional arguments for `$name` substitution in skill content. Example: `arguments: [issue, branch]` allows `$issue` and `$branch` in markdown. |
| `disable-model-invocation` | No | Boolean | N/A | `true`, `false`, `yes`, `no`, `on`, `off`, `1`, `0` (case-insensitive, v2.1.218+) | Prevents Claude from auto-triggering the skill. Manual invocation with `/name` still works. Also prevents preload into subagents and scheduled task execution. |
| `user-invocable` | No | Boolean | N/A | Same as above. | `false` hides from `/` menu but Claude can still invoke. Default: `true`. |
| `allowed-tools` | No | List or space-separated string | Unconstrained | Tool names and patterns. | Grants tool access **for the turn that invokes this skill only**. Grant clears on next user message. For CLI only; does NOT apply in Agent SDK. Supports `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` substitution (v2.1.129+). |
| `disallowed-tools` | No | List or space-separated string | Unconstrained | Tool names. | Removes tools from Claude's pool while skill is active. Clears on next message. Cannot remove `EndConversation` while other tools remain. |
| `model` | No | String | Unconstrained | Valid model ID or `inherit`. | Overrides session model for this skill's turn only. Excluded models (via `availableModels` allow-list) are ignored. Resumes session model on next prompt. |
| `effort` | No | String | N/A | `low`, `medium`, `high`, `xhigh`, `max` | Overrides session effort level. Availability depends on model. Default: inherits session. |
| `context` | No | String | N/A | `fork` | Runs skill in isolated subagent context. Subagent does not have conversation history. |
| `agent` | No | String | Unconstrained | Subagent name (e.g., `Explore`, `Plan`, `general-purpose`). | Specifies which subagent type executes the forked skill. Only applies with `context: fork`. |
| `background` | No | Boolean | N/A | Same as `disable-model-invocation`. | With `context: fork`: `false` blocks turn until subagent finishes; `true` (default) runs in background. v2.1.218+. |
| `hooks` | No | YAML object | Unconstrained | Hook event config. | Scoped to skill lifecycle. See [hooks documentation](https://code.claude.com/docs/en/hooks). |
| `paths` | No | List or comma-separated string | Unconstrained | Glob patterns (same as [path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)). | Skill activates automatically only when working with matching files. |
| `shell` | No | String | N/A | `bash` (default) or `powershell` | Shell for `` !`command` `` and ` ```! ` blocks. PowerShell requires v2.1+ and `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` or Windows without Git Bash. |

### Example Frontmatter

```yaml
---
name: summarize-changes
description: Summarizes uncommitted changes and flags anything risky. Use when the user asks what changed, wants a commit message, or asks to review their diff.
when_to_use: Common triggers include "what did I change", "review my diff", "create a commit message"
disable-model-invocation: false
allowed-tools: Bash(git diff *) Bash(git status *)
paths: "*.py,*.js,*.ts"
shell: bash
---
```

### String Substitutions Available in Skill Content

From [code.claude.com § Available string substitutions](https://code.claude.com/docs/en/skills.md):

| Variable | Expands to | Example | Notes |
|----------|-----------|---------|-------|
| `$ARGUMENTS` | All arguments passed to skill as a single string | User types `/fix-issue 123`; `$ARGUMENTS` → `123` | If not present, `ARGUMENTS: <value>` is appended to skill. |
| `$ARGUMENTS[N]` | Nth argument (0-indexed) | `$ARGUMENTS[0]` with args `SearchBar React Vue` → `SearchBar` | Multi-word args must be shell-quoted: `/skill "hello world"`. |
| `$N` | Shorthand for `$ARGUMENTS[N]` | `$0`, `$1` → first, second arg | Equivalent to `$ARGUMENTS[N]`. |
| `$name` | Named argument from `arguments` frontmatter | With `arguments: [issue, branch]`, `$issue` → first arg | Names map to positions in order. Missing named args expand to empty string. |
| `${CLAUDE_SESSION_ID}` | Current session UUID | Used for logging, session-specific files | Useful for correlation, temp files. |
| `${CLAUDE_EFFORT}` | Current effort level | `low`, `medium`, `high`, `xhigh`, or `max` (no `ultracode` distinction) | Adapt skill instructions to effort setting. |
| `${CLAUDE_SKILL_DIR}` | Directory containing skill's SKILL.md | Personal skill → `~/.claude/skills/my-skill`; plugin skill → plugin subdir | Use in `` !`command` `` and `allowed-tools`. Resolves independent of cwd. v2.1.129+ for `allowed-tools`. |
| `${CLAUDE_PROJECT_DIR}` | Project root directory | Same as [hooks](https://code.claude.com/docs/en/hooks#reference-scripts-by-path) receive. | Reference project-local scripts/files. v2.1.196+. |

**Escaping:** To include literal `$` (e.g., `$1.00`), use `\$1.00`. Single backslash only; double (`\\$`) leaves both.

---

## Directory Layout and Skill Discovery

### Where Skills Live (Precedence Order)

From [code.claude.com § Where skills live](https://code.claude.com/docs/en/skills.md):

```
Enterprise (managed settings) → Personal (~/.claude/skills/) → Project (.claude/skills/) → Plugin (plugin/skills/)
```

**Highest-to-lowest precedence:**

1. **Enterprise** (managed settings, admins only)
   - Applies to all users in organization
   - Overrides personal, project, and bundled skills

2. **Personal** (`~/.claude/skills/<skill-name>/SKILL.md`)
   - Available across all projects
   - Overrides project and bundled skills
   - Lives in user's home directory

3. **Project** (`.claude/skills/<skill-name>/SKILL.md`)
   - Committed to repo; shared with team
   - Overrides bundled skills
   - Discovered in starting directory and parent directories up to repo root

4. **Plugin** (`<plugin-dir>/skills/<skill-name>/SKILL.md`)
   - Namespaced as `/plugin-name:skill-name`
   - Cannot conflict with other levels
   - Installed via `/plugin install`

5. **Bundled** (ship with Claude Code)
   - Fallback; overridable by any level above
   - Examples: `/debug`, `/code-review`, `/verify`, `/doctor`

### Directory Structure Within Skill

From [code.claude.com § Getting started](https://code.claude.com/docs/en/skills.md):

```
my-skill/
├── SKILL.md                    # Required: main instructions
├── references/
│   ├── api.md                  # Optional: detailed docs
│   └── schema.md               # Optional: database schema
├── examples/
│   └── sample.md               # Optional: expected output format
├── scripts/
│   ├── validate.sh             # Optional: executable script
│   └── helper.py               # Optional: Python utility
├── templates/
│   └── report.md               # Optional: template for Claude to fill in
└── assets/
    └── logo.png                # Optional: images or static files
```

**Key points:**
- Only `SKILL.md` is required
- Supporting files load on demand (no context cost until accessed)
- Files in `scripts/` can be executed with bash
- Use forward slashes in all paths (even on Windows)
- Descriptive filenames help Claude navigate

### Monorepo and Nested Skills

From [code.claude.com § Automatic discovery from nested directories](https://code.claude.com/docs/en/skills.md):

When Claude edits a file in a subdirectory, skills from that subdirectory's `.claude/skills/` become available:

```
repo/
├── .claude/skills/deploy/SKILL.md          → /deploy (project root)
├── .claude/skills/lint/SKILL.md            → /lint
└── packages/web/
    └── .claude/skills/deploy/SKILL.md      → /packages/web:deploy (namespaced)
```

**Behavior:**
- Both `/deploy` (project root) and `/packages/web:deploy` (nested) are available
- Typing `/deploy` invokes project root version
- Claude picks the variant matching the files being worked on
- Nested skill also applies when unqualified name is invoked (v2.1.203+)

---

## Discovery and Loading Mechanics

### What Loads at Startup vs. On Demand

From [platform.claude.com Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview):

#### Level 1: Metadata (Always Loaded)
- **Content:** `name` and `description` from YAML frontmatter
- **Token cost:** ~100 tokens per skill (total for all skills)
- **When:** Startup; included in system prompt
- **Purpose:** Claude sees available skills and uses description to decide whether to trigger

#### Level 2: Instructions (Loaded When Triggered)
- **Content:** Full SKILL.md body (markdown after frontmatter)
- **Token cost:** Under 5,000 tokens per skill
- **When:** Claude invokes skill or user invokes with `/skill-name`
- **Behavior:** Entire body stays in context for rest of session

#### Level 3: Resources (As Needed)
- **Content:** `references/`, `examples/`, `scripts/`, `templates/`, `assets/`
- **Token cost:** Zero until accessed; file loads only when Claude reads it
- **When:** Claude explicitly reads the file (e.g., with bash `cat` command)
- **Behavior:** Scripts run through bash; only output enters context (not script code)

### Skill Content Lifecycle

From [code.claude.com § Skill content lifecycle](https://code.claude.com/docs/en/skills.md):

> "When you or Claude invokes a skill, the rendered `SKILL.md` content enters the conversation as a single message and **stays there for the rest of the session**."

**Key points:**
- Content persists across turns
- Permissions (e.g., `allowed-tools` grants) clear after one message
- On re-invocation with identical rendered content, Claude Code adds a note instead of re-pasting
- If rendered content differs (arguments changed, dynamic context updated), full content appends again
- During auto-compaction, skills re-attach with first 5,000 tokens; shared 25,000-token budget across all re-attached skills

### How Claude Decides to Invoke a Skill

**Matching logic:**
1. Claude scans description + `when_to_use` text combined (1,536-char cap)
2. Looks for keyword overlap between user request and skill's description
3. If match found and skill doesn't have `disable-model-invocation: true`, Claude can invoke automatically
4. User can invoke manually with `/skill-name` even if `disable-model-invocation: true`

From [code.claude.com § Skill descriptions are cut short](https://code.claude.com/docs/en/skills.md):

> "The listing always contains every skill name, but if you have many skills, Claude Code shortens descriptions to fit the listing's character budget, which can strip the keywords Claude needs to match your request."

Budget scales at 1% of model's context window. If budget overflows, Claude Code drops descriptions starting with least-invoked skills.

---

## Size Limits and Token Budget

From [code.claude.com](https://code.claude.com/docs/en/skills.md) and [platform.claude.com best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

| Component | Limit | Notes |
|-----------|-------|-------|
| Skill `name` | 64 characters | Lowercase + numbers + hyphens only |
| Skill `description` | 1,024 characters | Non-empty, no XML tags |
| `description` + `when_to_use` combined | 1,536 characters in skill listing | Truncated if total exceeds 1,536 chars |
| SKILL.md body | 500 lines (recommended max) | Exceeding this should trigger splitting into supporting files |
| Total Skill directory size | No documented limit; practical limit is filesystem size | Supported files don't consume context until accessed |
| Skill listing budget | 1% of model's context window | Scales with context window size; budget set by `skillListingBudgetFraction` (default 0.01) or `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var |
| Compaction re-attachment per skill | 5,000 tokens | After auto-compaction, first 5,000 tokens of most recent invocation reattach |
| Compaction re-attachment total | 25,000 tokens combined | Budget shared across all re-attached skills after compaction |

**No practical limit on bundled content:** Files and scripts don't consume context until accessed. A skill can include dozens of reference files, large datasets, or extensive examples with zero context penalty until needed.

From [code.claude.com § Skill descriptions are cut short](https://code.claude.com/docs/en/skills.md):

To raise skill listing budget: set `skillListingBudgetFraction` in settings (e.g., `0.02` = 2%) or `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var to fixed character count.

---

## Supporting Files: References, Examples, Scripts, Templates

### How Claude Accesses Supporting Files

From [platform.claude.com Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview):

> "Claude accesses these files only when referenced. The filesystem model means each content type has different strengths: instructions for flexible guidance, code for reliability, resources for factual lookup."

**Access patterns:**

1. **Reference files** (`.md` docs, schemas)
   - Claude reads via bash `cat` command
   - Full content loads into context when read
   - Best for: API docs, database schemas, formatting rules, detailed guides

2. **Code scripts** (`.py`, `.sh`, `.js`)
   - Claude executes via bash
   - Script code NEVER enters context; only output does
   - Best for: validation, file analysis, deterministic transformations, data processing

3. **Templates** (`.md`, `.json`)
   - Claude reads and fills in
   - Content loads when accessed
   - Best for: output format examples, structured checklists

4. **Assets** (images, static files)
   - Claude can analyze images if referenced
   - Static files served as-is
   - Best for: logos, diagrams, reference materials

### Progressive Disclosure Patterns

From [platform.claude.com best practices § Progressive disclosure patterns](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

**Pattern 1: High-level guide with references**
```markdown
# PDF Processing

## Quick start
Extract text with pdfplumber:
[code example]

## Advanced features
- **Form filling**: See [FORMS.md](FORMS.md)
- **API reference**: See [REFERENCE.md](REFERENCE.md)
- **Examples**: See [EXAMPLES.md](EXAMPLES.md)
```

**Pattern 2: Domain-specific organization**
```
bigquery-skill/
├── SKILL.md (overview)
└── reference/
    ├── finance.md
    ├── sales.md
    ├── product.md
    └── marketing.md
```

**Pattern 3: Conditional details**
```markdown
## Editing documents

For simple edits, modify XML directly.

For tracked changes: See [REDLINING.md](REDLINING.md)
For OOXML details: See [OOXML.md](OOXML.md)
```

### File Path References

From [code.claude.com § Add supporting files](https://code.claude.com/docs/en/skills.md):

- Paths are **relative to skill directory**
- **Always use forward slashes** (even on Windows)
- Example: `[API docs](reference.md)`, `[Form filling guide](reference/forms.md)`

---

## `allowed-tools` Semantics

### Pre-Approving Tools in Claude Code

From [code.claude.com § Pre-approve tools for a skill](https://code.claude.com/docs/en/skills.md):

> "The `allowed-tools` field grants permission for the listed tools during the turn that invokes the skill, so Claude can use them without prompting you for approval. **The grant clears when you send your next message**, even though the skill content stays in context."

**Key points:**
- `allowed-tools` is a **turn-scoped grant**, not a persistent permission
- Only applies during the turn the skill is invoked
- After user sends next message, grant is revoked
- Does NOT restrict tools: listed tools are allowed; unlisted tools still require permission per session rules
- Session's `permission settings` still govern baseline approval behavior
- Supported formats: space-separated string, comma-separated string, or YAML list
- Tool patterns support regex and wildcards (e.g., `Bash(git add *)`)

**Example:**
```yaml
---
name: commit
description: Stage and commit changes
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---
```

### `disallowed-tools`: Denying Tools in a Skill

From [code.claude.com § Pre-approve tools](https://code.claude.com/docs/en/skills.md):

> "To remove tools from Claude's available pool while a skill is active, list them in `disallowed-tools`."

**Example:**
```yaml
---
name: background-loop
disable-model-invocation: false
disallowed-tools: AskUserQuestion
---
```

**Constraints:**
- Cannot remove `EndConversation` while other tools remain (safety constraint)
- Clears when user sends next message
- Like deny rules, it's a **turn-scoped restriction**

### Agent SDK: `allowed-tools` Does NOT Apply

From [code.claude.com/docs/en/agent-sdk/skills.md](https://code.claude.com/docs/en/agent-sdk/skills.md):

> "The `allowed-tools` frontmatter field in SKILL.md is only supported when using Claude Code CLI directly. **It does not apply when using Skills through the SDK**. When using the SDK, control tool access through the main `allowedTools` option in your query configuration."

**In the SDK**, use `ClaudeAgentOptions.allowed_tools` (Python) or `options.allowedTools` (TypeScript) to control all tool access. Skills' `allowed-tools` fields are ignored.

---

## Invocation Methods and Manual vs. Auto-Triggering

### Explicit Invocation (User Types `/skill-name`)

- Works regardless of `disable-model-invocation` setting
- User can pass arguments: `/fix-issue 123`
- Appears in `/` autocomplete menu if `user-invocable: true` (default)

### Auto-Invocation (Claude Decides)

From [code.claude.com § Control who invokes a skill](https://code.claude.com/docs/en/skills.md):

| Frontmatter | Claude can invoke | You can invoke | Context loaded |
|-----------|------------------|-----------------|-----------------|
| (default) | Yes | Yes (`/skill-name`) | Description always; full content on invoke |
| `disable-model-invocation: true` | **No** | Yes | Description NOT in context; content on invoke |
| `user-invocable: false` | Yes | **No** (hidden from menu) | Description always; content on invoke |

### Stacking Skills (Multiple Skills in One Message)

From [code.claude.com § Pass arguments to skills](https://code.claude.com/docs/en/skills.md):

> "Typing `/write-tests /fix-issue 123` loads both skills and passes the trailing text `123` as `$ARGUMENTS` to each of them."

- Expands first skill + up to 5 stacked after it
- Stops at first token that isn't an inline user-invocable skill (e.g., forked skills like `/code-review`)
- Remaining text becomes argument text for every expanded skill

### Plugin Skills Namespace

From [code.claude.com § How a skill gets its command name](https://code.claude.com/docs/en/skills.md):

```
my-plugin/skills/review/SKILL.md
  → `/my-plugin:review` (frontmatter `name` or directory name)
  → Also invocable as bare `/review` if no conflict
```

---

## Skills vs. Other Mechanisms

From [code.claude.com](https://code.claude.com/docs/en/skills.md) and context:

| Mechanism | Use When | Notes |
|-----------|----------|-------|
| **Skill** | You keep pasting the same instructions, checklist, or multi-step procedure | Skills load on demand; free until invoked. Discoverable via `/` menu. Can be auto-triggered. Distributed via git (.claude/skills/) or plugins. |
| **CLAUDE.md** | You need persistent context that applies to every session in a project | Always loaded; costs every turn. Not discoverable. Best for facts, architecture, conventions. |
| **Hook** | You want to automate behavior before/after a tool (e.g., "always run prettier before commit") | Executes deterministically without Claude deciding. Configured in settings.json, not loaded by Claude. |
| **Subagent** (custom agent in `.claude/agents/`) | You want a specialized multi-turn agent for a complex workflow | Programmatically configured. Can be invoked by user (`/@agent-name`) or by Claude. Maintains state across turns. |
| **Slash command** (built-in like `/help`) | Framework-provided action | Fixed logic, not prompt-based. Cannot be customized. |
| **MCP server** | You need to integrate external tools/APIs that Claude doesn't have built-in access to | Separate process, networked integration. Provides tools Claude can call (e.g., GitHub, Slack). |

**Decision tree:**
- Need persistent session context for every project → **CLAUDE.md**
- Reusable instructions invoked on demand → **Skill**
- Automate tool workflows deterministically → **Hook**
- Orchestrate multi-turn specialized agent → **Subagent**
- Integrate external services → **MCP**

---

## Dynamic Context Injection: `!`command``

From [code.claude.com § Inject dynamic context](https://code.claude.com/docs/en/skills.md):

### Inline Form

```markdown
## Current changes

!`git diff HEAD`
```

**Execution:**
1. Claude Code runs `git diff HEAD` immediately (before Claude sees the skill)
2. Output replaces the placeholder
3. Claude receives skill with actual diff inlined

**Constraints:**
- `!` must be at start of line or after whitespace
- Command runs once; substitution is one-pass (no nested placeholders)
- Plain-text output only

### Fenced Block Form

```markdown
## Environment
```!
node --version
npm --version
git status --short
```
```

**Use for:** Multi-line commands.

### Disable Shell Execution

From [code.claude.com § Inject dynamic context](https://code.claude.com/docs/en/skills.md):

Set `"disableSkillShellExecution": true` in settings to prevent all `` !`cmd` `` execution. Bundled and managed skills are not affected.

### Substitution Variables in Shell Commands

Both `` !`cmd` `` and `allowed-tools` support:
- `${CLAUDE_SKILL_DIR}` — skill directory (v2.1.129+)
- `${CLAUDE_PROJECT_DIR}` — project root (v2.1.196+)

Example:
```yaml
---
name: render-chart
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
---

Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render.
```

---

## Run Skills in Subagents: `context: fork`

From [code.claude.com § Run skills in a subagent](https://code.claude.com/docs/en/skills.md):

### Basic Usage

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files
2. Read and analyze
3. Summarize findings
```

**Behavior:**
- Skill content becomes the subagent's prompt
- Subagent does NOT have access to conversation history
- Subagent inherits system prompt from `agent` type
- Result returned when subagent finishes

### Background vs. Foreground

| Setting | Behavior | Applies to |
|---------|----------|-----------|
| `background: true` (default, v2.1.218+) | Subagent runs in background; you keep working | Interactive sessions |
| `background: false` | Turn blocks until subagent finishes | All cases |

**Claude Code also waits (ignores `background: true`) in:**
- Non-interactive mode (`-p` flag, Agent SDK)
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` env var set
- Forked skill re-invoked while earlier invocation still running
- Scheduled task execution

### Available Subagent Types

From [code.claude.com § Run skills in subagent](https://code.claude.com/docs/en/skills.md):

- `Explore` — Read-only tools optimized for codebase exploration; skips CLAUDE.md and git status
- `Plan` — Reasoning-focused agent; skips CLAUDE.md and git status
- `general-purpose` (default) — Full tool access, loads CLAUDE.md and git status
- Custom subagents from `.claude/agents/`

**Note:** Forked skills don't inherit `CLAUDE.md` by default if using `Explore` or `Plan` agent.

---

## Skill Lifecycle and Overrides

### `skillOverrides` Setting

From [code.claude.com § Override skill visibility](https://code.claude.com/docs/en/skills.md):

Controlled in `.claude/settings.json` or `.claude/settings.local.json`:

```json
{
  "skillOverrides": {
    "deploy": "off",
    "legacy-context": "name-only",
    "helper": "user-invocable-only"
  }
}
```

| Value | Listed to Claude | In `/` menu |
|-------|-----------------|-----------|
| `"on"` (default) | Name + description | Yes |
| `"name-only"` | Name only | Yes |
| `"user-invocable-only"` | Hidden | Yes |
| `"off"` | Hidden | Hidden |

**Use case:** Override bundled or third-party skills without editing their SKILL.md files.

### Live Change Detection

From [code.claude.com § Live change detection](https://code.claude.com/docs/en/skills.md):

> "Claude Code watches skill directories for file changes. Adding, editing, or removing a skill under `~/.claude/skills/`, the project `.claude/skills/`, or a `.claude/skills/` inside an `--add-dir` directory takes effect within the current session without restarting."

**Exception:** For skills that are also plugins (with `hooks/`, `.mcp.json`, `agents/`, `output-styles/`), run `/reload-plugins` for changes to take effect.

---

## Skill Evaluation and Testing: `skill-creator` Plugin

From [code.claude.com § Run evals with skill-creator](https://code.claude.com/docs/en/skills.md):

### Installation

```bash
/plugin install skill-creator@claude-plugins-official
/reload-plugins
```

### Capabilities

From the documentation:

> "The plugin walks you through writing test cases and runs the loop:
> - **Test cases**: stores prompts, input files, and expected behavior in `evals/evals.json`
> - **Isolated runs**: spawns a subagent per test case
> - **Grading**: checks each assertion against output
> - **Benchmark**: aggregates pass rate, time, tokens for with-skill vs. without-skill
> - **Version comparison**: runs blind A/B between two skill versions
> - **Description tuning**: generates should-trigger/should-not-trigger prompts
> - **Review viewer**: opens HTML report for qualitative feedback"

### Usage

Ask Claude (after plugin is loaded):
```
evaluate my summarize-changes skill with skill-creator
```

---

## Pitfalls: How Skill Authoring Goes Wrong

### Common Mistakes

From observations across [code.claude.com](https://code.claude.com/docs/en/skills.md), [platform.claude.com best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), and [agentskills.io](https://agentskills.io):

| Pitfall | Problem | Fix |
|---------|---------|-----|
| **Description too vague** | Claude doesn't know when to trigger the skill. Keywords are lost if description is short. | Include both what the skill does AND when to use it. Put key use case first. Use specific trigger phrases. |
| **Skill body > 500 lines** | Slows performance; token budget eaten. Should split into supporting files. | Move detailed reference to separate `.md` files in `reference/` or `examples/`. SKILL.md stays focused. |
| **No examples** | Claude doesn't understand expected output format. Can generate misaligned results. | Include concrete input/output examples. Show desired style, not abstract guidance. |
| **Nested references too deep** | Claude may partially read files. Information becomes incomplete. | Keep references one level deep from SKILL.md. Avoid SKILL.md → A.md → B.md chains. |
| **Windows-style paths in markdown** | Breaks on Unix. Scripts fail with "file not found". | Always use forward slashes: `reference/api.md` not `reference\api.md`. |
| **`allowed-tools` forgotten in CLI skills** | Claude repeatedly asks for permission. Worse UX. | Add `allowed-tools` for commands skill must run (git, bash, etc.). Remember: only ONE turn scope. |
| **Complex skill marked `disable-model-invocation: true` too conservatively** | User has to manually invoke frequently-needed skill. | Use `disable-model-invocation: true` only for workflows with side effects (deploy, delete) that should never auto-trigger. |
| **Skill without `description` field** | Skill doesn't auto-trigger. Uses first paragraph of markdown instead, which is often just "## Instructions". | Always include explicit `description` frontmatter. Keep it specific and keyword-rich. |
| **Time-sensitive information in skill** | Skill becomes wrong after date passes. Requires manual update. | Avoid hardcoded dates or version info. Use "old patterns" section with `<details>` for deprecated approaches. |
| **Assuming Claude knows domain terms** | Skill is too terse. Claude guesses wrong. | Provide definitions and context. Test with Haiku (smaller model) to verify skill is self-contained. |
| **Skill description written in first-person** | System prompt context injection breaks. Claude doesn't recognize skill application. | Write descriptions in third person: "Extracts text from PDFs" not "I can extract text from PDFs". |
| **Scripts that generate more placeholder content** | Shell injection runs once; nested placeholders don't expand. | One-pass substitution only. Complex logic must happen in script, not via chained `!`cmd`` placeholders. |
| **Frontmatter syntax errors (malformed YAML)** | Skill loads with empty metadata. `/skill-name` still works but auto-triggering fails silently. | Run with `--debug` to see parse errors. Use standard YAML syntax (`:` after key, proper indentation). |
| **`allowed-tools` and `disallowed-tools` both present** | Conflicting directives confuse permission system. | Use one or the other. `allowed-tools` grants; `disallowed-tools` denies. Don't mix unless carefully reasoned. |
| **Too many skills installed** | Skill listing budget exceeded; important descriptions truncated. Claude misses keywords. | Trim descriptions to essential keywords only. Set low-priority skills to `"name-only"` in `skillOverrides`. Run `/doctor` to check listing size. |
| **Reference file not mentioned in SKILL.md** | Claude doesn't know the file exists. Won't read it even if relevant. | Always link reference files from SKILL.md: "For advanced usage, see [ADVANCED.md](ADVANCED.md)." |
| **Skill runs in `context: fork` but references CLAUDE.md** | Subagent doesn't load project's CLAUDE.md (if using Explore/Plan agent). Loses context. | If forked skill needs project context, load it into skill body explicitly, or use `general-purpose` agent, or avoid fork. |
| **Scripts fail silently** | User sees no output; thinks skill broke. Unclear what went wrong. | Scripts should print explicit success/failure messages. Use try/catch, validation steps, verbose logging. |
| **Mixed permission semantics** | Skill author doesn't realize `allowed-tools` clears after one turn. Sets it expecting persistent grant. | Remember: `allowed-tools` is turn-scoped. For persistent grants, add allow rules to `.claude/settings.json`. |

### Testing and Iteration Best Practices

From [platform.claude.com best practices § Evaluation and iteration](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

**Before committing a skill:**

1. Test with at least three representative prompts
2. Test with Haiku, Sonnet, and Opus (to verify guidance works at all model tiers)
3. Compare runs with skill vs. without skill (baseline)
4. Use `skill-creator` for eval automation
5. Iterate based on observation (not assumption)

**Development pattern:**
- Work with Claude A (expert refiner)
- Test with Claude B (fresh instance using skill)
- Observe what Claude B does wrong
- Bring observations back to Claude A for refinement
- Repeat

---

## Sources

All claims in this document are verified against primary sources fetched on July 27, 2026:

- [Claude Code Skills Overview](https://code.claude.com/docs/en/skills.md) — Comprehensive guide covering skill creation, frontmatter, directory layout, discovery, lifecycle, and advanced patterns (code.claude.com)

- [Claude Code Agent SDK Skills Reference](https://code.claude.com/docs/en/agent-sdk/skills.md) — SDK-specific skill mechanics, tool restrictions, skill locations, and configuration (code.claude.com)

- [Agent Skills Overview (Anthropic Platform)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) — Skill structure, frontmatter requirements, progressive disclosure architecture, where skills work (platform.claude.com)

- [Skill Authoring Best Practices (Anthropic Platform)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Naming conventions, writing effective descriptions, patterns, workflows, evaluation, testing, anti-patterns (platform.claude.com)

- [Agent Skills Open Standard](https://agentskills.io) — Open-source standard adopted across multiple AI tools, client showcase, specification reference (agentskills.io)

---

## Appendix: Complete Frontmatter Example (All Fields)

```yaml
---
name: pdf-processing-advanced
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
when_to_use: Common triggers include "analyze this PDF", "extract text", "fill out forms", "merge documents"
argument-hint: "[filename] [operation]"
arguments: [file, operation]
disable-model-invocation: false
user-invocable: true
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/*.py) Read(${CLAUDE_PROJECT_DIR}/docs/*.md)
disallowed-tools: AskUserQuestion
model: claude-opus-4-1
effort: high
context: fork
agent: general-purpose
background: false
paths: "*.pdf,*.PDF"
shell: bash
hooks:
  - trigger: "tool-call"
    condition: "tool == 'Bash'"
    action: "log-to-file"
---

[Skill body in markdown...]
```

---

## Related Reading

- [Subagents in Claude Code](https://code.claude.com/docs/en/sub-agents) — How to create and configure custom agents
- [Hooks in Claude Code](https://code.claude.com/docs/en/hooks) — Automate tool workflows
- [MCP Integration](https://code.claude.com/docs/en/plugins-reference) — Connect external services
- [Permissions and Tool Access](https://code.claude.com/docs/en/permissions) — Control what Claude can do
