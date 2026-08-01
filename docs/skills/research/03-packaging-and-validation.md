# Skills: packaging, distribution, validation, cross-agent portability

Research date: **2026-07-27**. Verified against Claude Code **v2.1.220** (`claude --version`, run locally) and the live docs at `code.claude.com` and `agentskills.io`.

> Note on method: `docs.claude.com/en/docs/claude-code/*` now **301-redirects to `code.claude.com/docs/en/*`**. That redirect is itself a verified fact — every Claude Code doc URL in these notes is the post-redirect canonical one. Every mechanical claim marked "measured" was executed against throwaway fixtures on this machine, not recalled.

---

## Bottom line

| # | Rule | Confidence |
|---|---|---|
| 1 | A skill is a **directory containing `SKILL.md`**. Nothing else is required. | High — [spec](https://agentskills.io/specification) |
| 2 | Spec-required frontmatter is exactly two fields: `name`, `description`. Everything else is optional. | High — [spec](https://agentskills.io/specification) |
| 3 | Spec `name`: 1–64 chars, `a-z0-9-` only, no leading/trailing/consecutive hyphen, **must match the parent directory name**. | High — [spec](https://agentskills.io/specification) |
| 4 | Spec `description`: 1–1024 chars. Claude Code separately truncates `description` + `when_to_use` at **1,536 chars** in the skill listing. | High — [spec](https://agentskills.io/specification), [CC skills](https://code.claude.com/docs/en/skills) |
| 5 | In **Claude Code**, `name` in a personal/project skill is only a display label — the **directory name** is the command. Do not rely on `name` to rename a command. | High — [CC skills](https://code.claude.com/docs/en/skills) |
| 6 | Keep `SKILL.md` **under 500 lines and ~5,000 tokens**. Push detail into `references/`. | High — [spec](https://agentskills.io/specification), [best practices](https://agentskills.io/skill-creation/best-practices) |
| 7 | Project skills live at `.claude/skills/<name>/SKILL.md` and are committed. This is the correct default for a single-repo solo dev. | High — [CC skills](https://code.claude.com/docs/en/skills) |
| 8 | Precedence: **enterprise > personal > project**; any of those overrides a bundled skill. Plugin skills are namespaced so they never conflict. | High — [CC skills](https://code.claude.com/docs/en/skills) |
| 9 | Project `.claude/skills/` is gated on the **workspace trust dialog** for `allowed-tools` and for `@skills-dir` plugins. Measured: an untrusted workspace skips project-scope skills-dir plugins entirely. | High — doc + measured |
| 10 | `claude plugin validate <path>` **requires** `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json` at that path. **It cannot validate a bare `.claude/skills/` tree.** | High — measured |
| 11 | Workaround: drop a lint-only `.claude/.claude-plugin/plugin.json`. Measured: it makes `claude plugin validate ./.claude` walk `.claude/skills/**/SKILL.md`, and it does **not** load as a runtime plugin. | High — measured |
| 12 | The built-in validator only catches **unparseable frontmatter (error)** and **missing/empty description (warning)**. It does **not** check name/dir match, charset, length limits, unknown keys, bad enum values, or missing referenced files. | High — measured |
| 13 | Warnings alone exit **0**; `--strict` turns warnings into errors and exits **1**. Use `--strict` in a pre-commit hook. | High — measured |
| 14 | Because the built-in validator is weak, **write your own SKILL.md linter**. A ~40-line Python script covers every spec rule. Full script below. | High — measured |
| 15 | There is a published JSON Schema for `plugin.json` and `marketplace.json` on SchemaStore. There is **no** published JSON Schema for `SKILL.md` frontmatter. | High — [SchemaStore catalog](https://www.schemastore.org/api/json/catalog.json) |
| 16 | `.claude-plugin/` holds **only** `plugin.json`. `skills/`, `agents/`, `hooks/` etc. go at the **plugin root**. This is the single most common plugin mistake. | High — [plugins ref](https://code.claude.com/docs/en/plugins-reference) |
| 17 | The `skills` npm CLI is real and current: `npx skills add`, from `vercel-labs/skills`, v1.5.20. It installs into `.claude/skills/` (project) or `~/.claude/skills/` (`-g`). It is a **consumer** tool — not needed to author your own repo's skills. | High — `npm view skills` |
| 18 | Claude Code reads **`CLAUDE.md`, not `AGENTS.md`**. If the repo has `AGENTS.md`, add a `CLAUDE.md` containing `@AGENTS.md`. | High — [memory](https://code.claude.com/docs/en/memory) |
| 19 | `claude plugin eval` exists in v2.1.220 but is **gated**: running it prints `` `plugin eval` is currently in early access `` and writes nothing. Do not plan around it yet. | High — measured |
| 20 | The supported testing loop today is the **baseline comparison**: run the same prompts with the skill and with it disabled (`skillOverrides: {"name": "off"}`), in fresh sessions. | High — [CC skills](https://code.claude.com/docs/en/skills) |
| 21 | For ~25 project skills, **do not build a plugin**. Commit `.claude/skills/` + a lint script + a pre-commit hook. Plugins buy namespacing and marketplace distribution you don't need. | High — reasoned from [plugins](https://code.claude.com/docs/en/plugins) |
| 22 | Watch the **skill listing budget**: it is 1% of the model's context window, and when it overflows Claude Code silently drops descriptions starting with least-used skills. 25 skills is enough to hit this. Check with `/doctor` and `/context`. | High — [CC skills](https://code.claude.com/docs/en/skills) |

---

## 1. The Agent Skills open standard

`agentskills.io` is the canonical home of the standard. The overview page states the governance model verbatim:

> The Agent Skills format was originally developed by [Anthropic](https://www.anthropic.com/), released as an open standard, and has been adopted by a growing number of agent products. The standard is open to contributions from the broader ecosystem.

Source repo: <https://github.com/agentskills/agentskills>. Code is Apache 2.0, docs CC-BY-4.0.

### 1.1 What the standard mandates

The [specification](https://agentskills.io/specification) mandates the directory shape:

> A skill is a directory containing, at minimum, a `SKILL.md` file:
>
> ```
> skill-name/
> ├── SKILL.md          # Required: metadata + instructions
> ├── scripts/          # Optional: executable code
> ├── references/       # Optional: documentation
> ├── assets/           # Optional: templates, resources
> └── ...               # Any additional files or directories
> ```

And the frontmatter, verbatim:

| Field           | Required | Constraints                                                                                                       |
| --------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`          | Yes      | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen.             |
| `description`   | Yes      | Max 1024 characters. Non-empty. Describes what the skill does and when to use it.                                 |
| `license`       | No       | License name or reference to a bundled license file.                                                              |
| `compatibility` | No       | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
| `metadata`      | No       | Arbitrary key-value mapping for additional metadata.                                                              |
| `allowed-tools` | No       | Space-separated string of pre-approved tools the skill may use. (Experimental)                                    |

Additional `name` rules stated separately in the spec body:

> * Must be 1-64 characters
> * May only contain unicode lowercase alphanumeric characters (`a-z`, `0-9`) and hyphens (`-`)
> * Must not start or end with a hyphen (`-`)
> * Must not contain consecutive hyphens (`--`)
> * **Must match the parent directory name**

Progressive disclosure budgets, verbatim:

> 1. **Metadata** (~100 tokens): The `name` and `description` fields are loaded at startup for all skills
> 2. **Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
> 3. **Resources** (as needed): Files (e.g. those in `scripts/`, `references/`, or `assets/`) are loaded only when required
>
> Keep your main `SKILL.md` under 500 lines. Move detailed reference material to separate files.

File-reference rule:

> When referencing other files in your skill, use relative paths from the skill root [...] Keep file references one level deep from `SKILL.md`. Avoid deeply nested reference chains.

The spec's own validator:

> Use the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) reference library to validate your skills:
>
> ```bash
> skills-ref validate ./my-skill
> ```

`skills-ref` is a Python package (pip/uv), CLI `skills-ref` with three commands — `validate`, `read-properties`, `to-prompt`. Its own README calls it "**Reference library for Agent Skills**" and says it is "intended for demonstration purposes only, not production use." I could **not** run it here (no `uv`/`uvx`/`pipx` on this machine), so its exact strictness is **unverified**.

### 1.2 What the standard deliberately does *not* mandate

Crucially, from the [client implementation guide](https://agentskills.io/client-implementation/adding-skills-support):

> the Agent Skills specification does not mandate where skill directories live (it only defines what goes inside them)

Instead a convention has emerged:

> | Scope   | Path                               | Purpose                       |
> | ------- | ---------------------------------- | ----------------------------- |
> | Project | `<project>/.<your-client>/skills/` | Your client's native location |
> | Project | `<project>/.agents/skills/`        | Cross-client interoperability |
> | User    | `~/.<your-client>/skills/`         | Your client's native location |
> | User    | `~/.agents/skills/`                | Cross-client interoperability |
>
> The `.agents/skills/` paths have emerged as a widely-adopted convention for cross-client skill sharing.
>
> Some implementations also scan `.claude/skills/` (both project-level and user-level) for pragmatic compatibility, since many existing skills are installed there.

The universal precedence rule the standard recommends:

> The universal convention across existing implementations: **project-level skills override user-level skills.**

Note that **Claude Code inverts this** (see §2.2). That is a real cross-agent divergence.

The guide also tells clients to be lenient where the spec is strict:

> * Name doesn't match the parent directory name → warn, load anyway
> * Name exceeds 64 characters → warn, load anyway
> * Description is missing or empty → skip the skill (a description is essential for disclosure), log the error
> * YAML is completely unparseable → skip the skill, log the error

...and warns about the single most common authoring bug:

> ```yaml
> # Technically invalid YAML — the colon breaks parsing
> description: Use this skill when: the user asks about PDFs
> ```

### 1.3 Which other agents consume the same files

From the `agentskills.io` client showcase data (each with its own skills doc):
Claude Code, Claude (claude.ai), **OpenAI Codex**, **Cursor**, **Gemini CLI**, **GitHub Copilot / VS Code**, **JetBrains Junie**, OpenCode, OpenHands, Amp, Goose, Roo Code, Kiro, Factory, Letta, Firebender, Trae, Tabnine, Qodo, Ona, Mux, Emdash, Superconductor, Databricks Genie Code, Snowflake Cortex Code, Pulumi Neo, Mistral Vibe, Laravel Boost, Spring AI, ZeroClaw, nanobot, fast-agent, pi, VT Code, Command Code, Autohand, Agentman, Vita, Workshop, Piebald, Deep Code, Google AI Edge Gallery, bub.

**Practical portability rule:** if you write spec-clean `SKILL.md` files (two required fields, correct `name`, relative paths one level deep, no Claude-only frontmatter in the body's critical path), the same directory is consumable by all of the above. Claude-only frontmatter fields are ignored by other clients rather than fatal — but any behaviour you encode in `context: fork`, `disable-model-invocation`, `!`command`` injection, or `$ARGUMENTS` **will silently not happen elsewhere**.

---

## 2. Claude Code's implementation

Claude Code states the relationship itself:

> Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, which works across multiple AI tools. Claude Code extends the standard with additional features like invocation control, subagent execution, and dynamic context injection.

### 2.1 Where skills live (verbatim)

> | Location   | Path                                                | Applies to                     |
> | :--------- | :-------------------------------------------------- | :----------------------------- |
> | Enterprise | See managed settings                                | All users in your organization |
> | Personal   | `~/.claude/skills/<skill-name>/SKILL.md`            | All your projects              |
> | Project    | `.claude/skills/<skill-name>/SKILL.md`              | This project only              |
> | Plugin     | `<plugin>/skills/<skill-name>/SKILL.md`             | Where plugin is enabled        |

**`.agents/skills/` is not listed.** Whether Claude Code v2.1.220 also scans `.agents/skills/` is **unverified** — see §10.

### 2.2 Precedence and discovery (verbatim)

> When skills share the same name across levels, enterprise overrides personal, and personal overrides project. A skill at any of these levels also overrides a bundled skill with the same name. [...] Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels. If you have files in `.claude/commands/`, those work the same way, but if a skill and a command share the same name, the skill takes precedence.

> Project skills load from `.claude/skills/` in your starting directory and in every parent directory up to the repository root, so starting Claude in a subdirectory still picks up skills defined at the root.

Nested monorepo behaviour:

> * The nested one appears under a directory-qualified name, `apps/web:deploy`.
> * Its description says which directory it applies to.
> * Claude picks the variant that matches the files it is working on.

Symlinks are supported for the personal/project locations:

> A `<skill-name>` entry in the enterprise, personal, or project locations can be a symlink to a directory elsewhere on disk. Claude Code follows the symlink and reads `SKILL.md` from the target directory, and if the same target is reachable from more than one location, Claude Code loads the skill once.

Live reload:

> Adding, editing, or removing a skill under `~/.claude/skills/`, the project `.claude/skills/`, or a `.claude/skills/` inside an `--add-dir` directory takes effect within the current session without restarting. Creating a top-level skills directory that did not exist when the session started requires restarting Claude Code.

### 2.3 Claude Code's extended frontmatter

Claude Code's own statement on requiredness contradicts the open spec and matters a lot:

> All fields are optional. Only `description` is recommended so Claude knows when to use the skill.

The Claude-only fields (from the [frontmatter reference](https://code.claude.com/docs/en/skills)) are: `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`.

Two that change how you package:

- **`paths`** — "Glob patterns that limit when this skill is activated. [...] When set, Claude loads the skill automatically only when working with files matching the patterns." This is the cheap way to keep 25 skills from polluting the listing.
- **`${CLAUDE_SKILL_DIR}`** — the substitution that makes a bundled script runnable regardless of install location:

> ```yaml
> ---
> name: render-chart
> description: Render a chart from a CSV file
> allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
> ---
>
> Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render the chart.
> ```

Requires v2.1.129+ for the `allowed-tools` substitution; `${CLAUDE_PROJECT_DIR}` requires v2.1.196+.

### 2.4 The listing budget — the real constraint at 25 skills

> Claude Code loads a listing of skill names and descriptions into context so Claude knows what's available. The listing always contains every skill name, but if you have many skills, Claude Code shortens descriptions to fit the listing's character budget, which can strip the keywords Claude needs to match your request. The budget scales at 1% of the model's context window. When the listing overflows, Claude Code drops descriptions starting with the skills you invoke least, so the skills you use most keep their full text.

Mitigations, all documented: `/doctor` to estimate cost, `/context` Skills row to see post-budget size, `skillListingBudgetFraction` setting (`0.02` = 2%), `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var, `skillOverrides: {"x": "name-only"}`, and `skillListingMaxDescChars`.

---

## 3. Distribution paths for a project's own skills

### 3.1 The four options

| Option | Where | Committed? | Namespacing | Trust gate | Reload |
|---|---|---|---|---|---|
| **A. Project skills** | `<repo>/.claude/skills/<n>/` | Yes | `/name` | Trust dialog for `allowed-tools` | Live |
| **B. Symlink personal→repo** | `~/.claude/skills/<n>` → repo path | The target is | `/name` | None (personal scope) | Live |
| **C. Skills-dir plugin** | `.claude/skills/<n>/.claude-plugin/plugin.json` | Yes | `<n>@skills-dir`, `/n:skill` | Trust dialog; monitors disabled, MCP re-approved | `/reload-plugins` for non-SKILL.md |
| **D. Marketplace plugin** | Separate repo + `marketplace.json` | Separate repo | `/plugin:skill` | Install step | `/reload-plugins` |

### 3.2 Trade-offs for a solo dev in one repo

**A (project skills) wins.** Reasons, each doc-backed:

- The skills version with the code they describe — a Flutter refactor and its skill update land in the same commit. Staleness detection (§8) becomes a `git log` problem instead of a "which copy is canonical" problem.
- Skill names stay short: `/gen-riverpod-provider`, not `/my-flutter-plugin:gen-riverpod-provider`. The docs frame this explicitly: standalone gives `/hello`, plugins give `/plugin-name:hello`, and "**Use standalone configuration when** [...] You're customizing Claude Code for a single project."
- Live change detection means edits apply mid-session with no reload.
- Cloud sessions get them free: "Cloud sessions additionally load project skills committed to the cloned repository's `.claude/skills/`." Personal skills in `~/.claude/skills/` do **not** transfer to Cowork/cloud/routines.

**B (symlink)** is for one specific case: a skill you want in *every* repo but want to edit in *this* repo. Costs: `~/.claude/skills/` is machine-local, so nothing about it is reproducible on a second machine or in CI, and cloud sessions never see it. For a single-repo project it is pure downside.

**C (skills-dir plugin)** is the interesting middle. It is how you attach hooks/MCP/agents to a skill folder without a marketplace:

> Any folder under a skills directory that contains a `.claude-plugin/plugin.json` manifest is loaded as a plugin named `<name>@skills-dir` on the next session, with no marketplace and no install step.

But note the sharp edge, verbatim:

> Project-scope `@skills-dir` plugins load only from the `.claude/skills/` of the directory where you start Claude Code. They do not walk up to the repository root the way plain skills and commands do, so launching from a subdirectory misses a plugin that lives at the repo root.

And in project scope, "**Background monitors do not load**" and MCP servers need per-server approval. Use C only if one skill genuinely needs bundled hooks.

**D (marketplace plugin)** is for distribution to other people. Overhead you'd be paying for nothing: a second repo or a `plugins/` tree, version bumping discipline ("If you set `version` in `plugin.json`, you must bump it every time you want users to receive changes"), an install step, and namespaced commands. Skip it.

---

## 4. Plugin packaging (for reference, and because the validator needs it)

### 4.1 Directory layout — the load-bearing warning

> The `.claude-plugin/` directory contains the `plugin.json` file. All other directories (commands/, agents/, skills/, workflows/, output-styles/, themes/, monitors/, hooks/) must be at the plugin root, not inside `.claude-plugin/`.

Default component locations (verbatim table, abridged to what matters here):

> | Component | Default Location | Purpose |
> | **Manifest** | `.claude-plugin/plugin.json` | Plugin metadata and configuration (optional) |
> | **Skills** | `skills/` | Skills with `<name>/SKILL.md` structure |
> | **Commands** | `commands/` | Skills as flat Markdown files. Use `skills/` for new plugins |
> | **Hooks** | `hooks/hooks.json` | Hook configuration |
> | **MCP servers** | `.mcp.json` | MCP server definitions |
> | **Executables** | `bin/` | Executables added to the Bash tool's `PATH` |

### 4.2 `plugin.json` — the current complete schema, verbatim

> ```json
> {
>   "name": "plugin-name",
>   "displayName": "Plugin Name",
>   "version": "1.2.0",
>   "description": "Brief plugin description",
>   "author": {
>     "name": "Author Name",
>     "email": "author@example.com",
>     "url": "https://github.com/author"
>   },
>   "homepage": "https://docs.example.com/plugin",
>   "repository": "https://github.com/author/plugin",
>   "license": "MIT",
>   "keywords": ["keyword1", "keyword2"],
>   "skills": "./custom/skills/",
>   "commands": ["./custom/commands/special.md"],
>   "agents": ["./custom/agents/reviewer.md"],
>   "hooks": "./config/hooks.json",
>   "mcpServers": "./mcp-config.json",
>   "outputStyles": "./styles/",
>   "lspServers": "./.lsp.json",
>   "experimental": {
>     "themes": "./themes/",
>     "monitors": "./monitors.json"
>   },
>   "dependencies": [
>     "helper-lib",
>     { "name": "secrets-vault", "version": "~2.1.0" }
>   ]
> }
> ```
>
> ### Required fields
>
> If you include a manifest, `name` is the only required field.

Three behaviours worth memorising:

> Claude Code ignores top-level fields it does not recognize. [...] `claude plugin validate` reports unrecognized fields as warnings, not errors. [...] Fields with the wrong type still fail. For example, a `keywords` value that is a string instead of an array is a load error.

> * **Replaces the default**: `commands`, `agents`, `workflows`, `outputStyles`, `experimental.themes`, `experimental.monitors`. [...]
> * **Adds to the default**: `skills`. The default `skills/` directory is always scanned, and directories listed in `skills` are loaded alongside it.

> All paths must be relative to the plugin root and start with `./`

### 4.3 `marketplace.json` — required fields, verbatim

> ### Required fields
>
> | Field | Type | Description |
> | `name` | string | Marketplace identifier (kebab-case, no spaces). This is public-facing [...] |
> | `owner` | object | Marketplace maintainer information |
> | `plugins` | array | List of available plugins |

Owner: `name` required; `email`, `url` optional. Plugin entries require `name` + `source`; source types are relative path (must start `./`), `github`, `url`, `git-subdir`, `npm`.

A real, complete example — Anthropic's own, fetched from `anthropics/skills`:

```json
{
  "name": "anthropic-agent-skills",
  "owner": { "name": "Keith Lazuka", "email": "klazuka@anthropic.com" },
  "metadata": { "description": "Anthropic example skills", "version": "1.0.0" },
  "plugins": [
    {
      "name": "example-skills",
      "description": "Collection of example skills demonstrating various capabilities...",
      "source": "./",
      "strict": false,
      "skills": [
        "./skills/skill-creator",
        "./skills/mcp-builder",
        "./skills/webapp-testing"
      ]
    }
  ]
}
```

Note the pattern: `"source": "./"` plus an explicit `skills` array. Per the path-behavior exception, "for a marketplace entry whose `source` resolves to the marketplace root, declaring specific subdirectories replaces the default `skills/` scan" — that is how one repo publishes several disjoint plugin bundles from one `skills/` tree.

### 4.4 How a plugin exposes skills

> **Location**: `skills/` or `commands/` directory in plugin root, or a single `SKILL.md` file at the plugin root

Naming, verbatim, and this differs from project skills:

> | Plugin `skills/` subdirectory | Frontmatter `name` or the directory name, namespaced by plugin | `my-plugin/skills/review/SKILL.md` → `/my-plugin:review`, or `/my-plugin:fancy` with `name: fancy` |
> | Plugin root `SKILL.md` | Frontmatter `name`, with the plugin directory name as a fallback | `my-plugin/SKILL.md` with `name: review` → `/my-plugin:review` |

With a real trap for single-skill plugins:

> Without it, Claude Code falls back to the install directory name, which for marketplace-installed plugins is a version string that changes on every update.

---

## 5. Validation — every mechanical check that actually exists

### 5.1 `claude plugin validate` — measured behaviour

```
$ claude plugin validate --help
Usage: claude plugin validate [options] <path>

Validate a plugin or marketplace manifest

Options:
  -h, --help  Display help for command
  --strict    Treat warnings as errors (exit 1). Use in CI to fail on
              unrecognized fields, missing metadata, and other issues that the
              runtime tolerates.
```

**Finding 1 — it refuses a bare skills tree.** Measured against four directory shapes, all four failed identically:

```
$ claude plugin validate ./shapes/bare          # dir containing skills/ but no manifest
$ claude plugin validate ./shapes/single/beta   # a single skill dir with SKILL.md at root
$ claude plugin validate ./proj/.claude         # a project's .claude/
$ claude plugin validate ./proj                 # a project root

✘ Found 1 error:
  ❯ directory: No manifest found in directory. Expected .claude-plugin/marketplace.json or .claude-plugin/plugin.json
exit=1
```

This is the single most important operational fact in these notes. Any "run `claude plugin validate` before committing your skills" advice is **wrong** for a plain `.claude/skills/` repo unless you add a manifest.

**Finding 2 — the lint-shim works, and is runtime-inert.** Adding `.claude/.claude-plugin/plugin.json` makes the validator treat `.claude/` as a plugin root, so `.claude/skills/` becomes its default `skills/` scan:

```
$ claude plugin validate ./proj/.claude
Validating plugin manifest: .../proj/.claude/.claude-plugin/plugin.json
Validating skill: .../proj/.claude/skills/beta/SKILL.md
✘ Found 1 error:
  ❯ frontmatter: YAML frontmatter failed to parse: YAML Parse error: Unexpected token.
    At runtime this skill loads with empty metadata (all frontmatter fields silently dropped).
```

Is the shim inert? Measured yes. With a genuine skills-dir plugin at `.claude/skills/gamma/.claude-plugin/plugin.json` **and** a shim at `.claude/.claude-plugin/plugin.json`, `claude plugin list` reported exactly one candidate:

```
Skills-directory plugins (.claude/skills/*):
  ⚠ 1 project-scope plugin directory under ./.claude/skills/ was not loaded because this
    workspace was not trusted when plugins were scanned.
```

The shim was not counted, consistent with the doc's wording: only "any folder **under a skills directory**" becomes a `@skills-dir` plugin. `.claude/` is not under a skills directory. (That output also independently confirms the **workspace-trust gate** on project-scope skills-dir plugins.)

**Finding 3 — what it checks about `SKILL.md` is thin.** Measured against a fixture plugin with seven deliberately broken skills:

| Fixture | Result |
|---|---|
| Unparseable YAML (`description: Use when: x` + `allowed-tools: [Read`) | **ERROR** — "YAML frontmatter failed to parse [...] At runtime this skill loads with empty metadata" |
| No frontmatter block at all | **WARNING** |
| `name:` present, `description:` absent | **WARNING** — "No description in frontmatter" |
| `name: totally-different` in dir `name-mismatch/` | **not detected** |
| `name: Uppercase-Name` (spec charset violation) | **not detected** |
| `description` of 1,200 chars (spec max 1024) | **not detected** |
| `totally-made-up-key: yes` in frontmatter | **not detected** |
| `context: forkk`, `model: not-a-real-model` (invalid enums) | **not detected** |
| Body references `scripts/does-not-exist.py` | **not detected** |

Exit-code behaviour, measured: warnings only → `✔ Validation passed with warnings`, **exit 0**. With `--strict` → `✘ Validation failed (--strict treats warnings as errors)`, **exit 1**.

On `plugin.json` the validator is more useful: it flags unknown fields, missing `author`, missing `version`, JSON syntax errors, and wrong types. Per the docs it also covers "skill/agent/command frontmatter, and `hooks/hooks.json` for syntax and schema errors," and when pointed at a marketplace it "checks `marketplace.json` for schema errors, duplicate plugin names, and source path traversal."

### 5.2 JSON-Schema validation of manifests

Real, verified schemas on SchemaStore (catalog fetched):

| File | Schema URL | fileMatch |
|---|---|---|
| `plugin.json` | `https://json.schemastore.org/claude-code-plugin-manifest.json` | `**/.claude-plugin/plugin.json` |
| `marketplace.json` | `https://www.schemastore.org/claude-code-marketplace.json` | `**/.claude-plugin/marketplace.json` |
| `settings.json` | `https://www.schemastore.org/claude-code-settings.json` | `**/.claude/settings.json` |
| `keybindings.json` | `https://www.schemastore.org/claude-code-keybindings.json` | `**/.claude/keybindings.json` |

Plugin-manifest schema, verified: `$id` = `https://json.schemastore.org/claude-code-plugin-manifest.json`, title "Claude Code Plugin Manifest", `required: ["name"]`.

Add `"$schema"` to get editor autocomplete — the docs confirm it is a no-op at load time ("Claude Code ignores this field at load time"). CLI validation:

```bash
npx --yes ajv-cli validate \
  -s <(curl -sL https://json.schemastore.org/claude-code-plugin-manifest.json) \
  -d .claude/.claude-plugin/plugin.json
```

**There is no SKILL.md frontmatter schema published anywhere.** Confirmed by scanning the SchemaStore catalog for `skill` / `agent-skill` — zero hits. This is why §5.4 exists.

### 5.3 Checking that bundled scripts at least parse

Nothing in Claude Code does this. Per-language one-liners, all offline:

```bash
# Bash / sh
find .claude/skills -name '*.sh'  -exec bash -n {} \;
# Python (compile only, no execution)
find .claude/skills -name '*.py'  -exec python3 -m py_compile {} \;
# Dart (Flutter repos)
find .claude/skills -name '*.dart' -exec dart analyze {} \;
# Node
find .claude/skills -name '*.js'  -exec node --check {} \;
# YAML/JSON assets
find .claude/skills \( -name '*.yaml' -o -name '*.yml' \) -exec python3 -c \
  'import sys,yaml; [yaml.safe_load(open(p)) for p in sys.argv[1:]]' {} +
find .claude/skills -name '*.json' -exec python3 -m json.tool --sort-keys {} /dev/null \;
```

Also check the executable bit — the docs list "Hooks not firing → Script not executable → Run `chmod +x script.sh`" as a top-five plugin failure:

```bash
find .claude/skills -path '*/scripts/*' -name '*.sh' ! -perm -u+x -print
```

### 5.4 The linter you actually need

The gap between the spec and `claude plugin validate` is exactly this script. Written and **measured working** against the fixture set — it caught all five rules the built-in validator missed.

```python
#!/usr/bin/env python3
"""tool/lint_skills.py — enforce the Agent Skills spec on .claude/skills/**/SKILL.md.

Covers what `claude plugin validate` does not: name/dir match, name charset,
length limits, description length, unknown frontmatter keys, dangling file refs.
Exit 0 = clean, 1 = at least one error.
"""
import re, sys, pathlib

try:
    import yaml
except ImportError:
    sys.exit("lint_skills: pip install pyyaml")

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".claude/skills")

SPEC_FIELDS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
CC_FIELDS = {
    "when_to_use", "argument-hint", "arguments", "disable-model-invocation",
    "user-invocable", "disallowed-tools", "model", "effort", "context",
    "agent", "background", "hooks", "paths", "shell",
}
KNOWN = SPEC_FIELDS | CC_FIELDS
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
FM_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)#:]+\.[a-z]{1,5})\)")

errors = warnings = 0

def err(p, m):
    global errors; errors += 1; print(f"ERROR {p}: {m}")

def warn(p, m):
    global warnings; warnings += 1; print(f"WARN  {p}: {m}")

for skill_md in sorted(ROOT.rglob("SKILL.md")):
    d = skill_md.parent
    rel = skill_md.relative_to(ROOT.parent.parent) if ROOT.is_absolute() else skill_md
    text = skill_md.read_text(encoding="utf-8")

    m = FM_RE.match(text)
    if not m:
        err(rel, "no YAML frontmatter block at the top of the file")
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        err(rel, f"frontmatter is not valid YAML ({e}). "
                 "Quote any description containing a colon.")
        continue
    if not isinstance(fm, dict):
        err(rel, "frontmatter is not a mapping")
        continue

    name = fm.get("name")
    if name is None:
        warn(rel, "no `name` (Claude Code falls back to the directory name; "
                  "the open spec requires it)")
    else:
        name = str(name)
        if name != d.name:
            err(rel, f"name {name!r} does not match directory {d.name!r}")
        if not NAME_RE.fullmatch(name):
            err(rel, f"name {name!r} violates spec charset "
                     "(lowercase a-z0-9 and single hyphens, no leading/trailing)")
        if len(name) > 64:
            err(rel, f"name is {len(name)} chars (max 64)")

    desc = fm.get("description")
    if not desc:
        err(rel, "missing or empty `description` — Claude cannot match this skill")
    else:
        n = len(str(desc)) + len(str(fm.get("when_to_use", "")))
        if len(str(desc)) > 1024:
            err(rel, f"description is {len(str(desc))} chars (spec max 1024)")
        elif n > 1536:
            warn(rel, f"description + when_to_use is {n} chars; Claude Code "
                      "truncates the listing entry at 1536")

    comp = fm.get("compatibility")
    if comp and len(str(comp)) > 500:
        err(rel, f"compatibility is {len(str(comp))} chars (max 500)")

    for k in set(fm) - KNOWN:
        warn(rel, f"unknown frontmatter key {k!r} (silently ignored at runtime)")

    lines = text.count("\n") + 1
    if lines > 500:
        warn(rel, f"{lines} lines — spec recommends keeping SKILL.md under 500")

    body = text[m.end():]
    for target in LINK_RE.findall(body):
        if target.startswith(("http", "/", "$", "~")):
            continue
        if not (d / target).exists():
            err(rel, f"references missing file {target!r}")

print(f"\n{errors} error(s), {warnings} warning(s)")
sys.exit(1 if errors else 0)
```

Measured output against the fixtures:

```
ERROR .../uppercase-name/SKILL.md: name 'Uppercase-Name' != dir 'uppercase-name'
ERROR .../uppercase-name/SKILL.md: name 'Uppercase-Name' violates spec charset
ERROR .../name-mismatch/SKILL.md: name 'totally-different' != dir 'name-mismatch'
ERROR .../long-desc/SKILL.md: description 1200 chars > 1024
ERROR .../no-frontmatter/SKILL.md: no frontmatter
ERROR .../empty-desc/SKILL.md: missing/empty description
```

### 5.5 The one command to run before committing

```bash
python3 tool/lint_skills.py .claude/skills \
  && claude plugin validate ./.claude --strict \
  && find .claude/skills -name '*.sh' -exec bash -n {} \; \
  && find .claude/skills -name '*.py' -exec python3 -m py_compile {} \;
```

Wire it as `.git/hooks/pre-commit`, or as a `lint-skills` entry in whatever task runner the Flutter repo already uses (`melos`, a `Makefile`, or `dart run` script).

---

## 6. The `skills` CLI

It still exists and is actively maintained. Verified via `npm view skills`:

```
version         = '1.5.20'
repository.url  = 'git+https://github.com/vercel-labs/skills.git'
description     = 'The open agent skills ecosystem'
```

Commands (from the repo README): `npx skills add`, `use`, `list`/`ls`, `find`, `update`, `remove`/`rm`, `init`.

Install locations:
- **Project (default)**: `./<agent>/skills/` — for Claude Code that is `.claude/skills/`; also writes `.agents/skills/` for cross-client targets.
- **Global (`-g`)**: `~/<agent>/skills/` — `~/.claude/skills/`, or platform paths like `~/.config/opencode/skills/`.

It claims support for 70+ agents. **No lockfile or manifest is documented**, which makes `skills update` non-reproducible — treat installs as vendored source you then commit.

**Recommendation:** this is a tool for *consuming* third-party skills into a repo. It plays no role in authoring your own 25. If you do use it, commit what it writes and never let it manage `~/.claude/skills/` for anything the project depends on.

---

## 7. `AGENTS.md` and cross-agent entry files

Unambiguous, verbatim:

> Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If your repository already uses `AGENTS.md` for other coding agents, create a `CLAUDE.md` that imports it so both tools read the same instructions without duplicating them.
>
> ```markdown CLAUDE.md
> @AGENTS.md
>
> ## Claude Code
>
> Use plan mode for changes under `src/billing/`.
> ```
>
> A symlink also works if you don't need to add Claude-specific content:
>
> ```bash
> ln -s AGENTS.md CLAUDE.md
> ```

Verification step, verbatim: "In your next session, run `/context` and confirm `CLAUDE.md` appears under **Memory files**." On Windows use the import, not the symlink.

`/init` also absorbs other agents' rule files: Cursor (`.cursor/rules/`, `.cursorrules`) and Copilot (`.github/copilot-instructions.md`) always; with `CLAUDE_CODE_NEW_INIT=1` also `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/`, `.clinerules`.

**Should this repo have an `AGENTS.md`?** Only if a non-Claude agent will actually be pointed at it. Otherwise it is a second file to keep in sync. The important boundary is elsewhere:

> Rules load into context every session or when matching files are opened. For task-specific instructions that don't need to be in context all the time, use skills instead.

> Keep it to facts Claude should hold in every session: build commands, conventions, project layout, "always do X" rules. If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a skill or a path-scoped rule instead.

So: **`CLAUDE.md` under 200 lines** (documented target) for always-true facts; `.claude/rules/*.md` with `paths:` frontmatter for path-scoped standing rules; `.claude/skills/` for procedures. `AGENTS.md` is a portability shim, not a third tier.

---

## 8. Versioning, maintenance, staleness, testing

### 8.1 Versioning

For project skills committed in the repo, **git is the version**. There is no per-skill version mechanism in the standard — the spec only offers an untyped `metadata` map (`metadata: {version: "1.0"}`), which nothing reads or enforces.

Plugin versioning, if you ever go there, verbatim:

> The version is resolved from the first of these that is set:
> 1. The `version` field in the plugin's `plugin.json`
> 2. The `version` field in the plugin's marketplace entry in `marketplace.json`
> 3. The git commit SHA of the plugin's source [...]
> 4. `unknown`, for `npm` sources or local directories not inside a git repository

With the trap:

> If you set `version` in `plugin.json`, you must bump it every time you want users to receive changes. Pushing new commits alone is not enough [...] If you're iterating quickly, leave `version` unset so the git commit SHA is used instead.

### 8.2 Detecting a stale skill

Nothing automates this. Practical mechanisms, in order of cost:

1. **Dangling-reference lint.** The linter in §5.4 already errors on `[x](references/gone.md)`. Extend the same idea to code paths a skill names — if a skill says `lib/features/auth/`, assert the directory exists.
2. **Path-scoped co-location.** Give each skill a `paths:` frontmatter glob naming the code it describes. That both narrows activation and encodes the dependency, so a reviewer can grep for skills whose `paths` no longer match anything:
   ```bash
   # crude staleness sweep
   for f in .claude/skills/*/SKILL.md; do
     python3 - "$f" <<'PY'
   import sys,re,yaml,glob,pathlib
   t=pathlib.Path(sys.argv[1]).read_text()
   fm=yaml.safe_load(re.match(r"\A---\n(.*?)\n---\n",t,re.S).group(1)) or {}
   for p in (fm.get("paths") or []):
       if not glob.glob(p, recursive=True):
           print(f"STALE {sys.argv[1]}: paths pattern {p!r} matches nothing")
   PY
   done
   ```
3. **Commit-age heuristic.** `git log -1 --format=%cs -- .claude/skills/<n>/` vs the last commit touching the code it describes. A skill older than its subject by many commits is a review candidate.
4. **The documented iteration signal.** From [best practices](https://agentskills.io/skill-creation/best-practices): "When an agent makes a mistake you have to correct, add the correction to the gotchas section. This is one of the most direct ways to improve a skill iteratively."

### 8.3 Testing a skill

**`claude plugin eval` exists but is gated.** Measured on v2.1.220:

```
$ claude plugin eval --help
Usage: claude plugin eval [options] [command] [target]
Run eval cases (evals/**/case.yaml or evals/**/prompt.md + graders/*.md) against
a plugin and report scored results...
Options: --ablation <none|with-without>  --threshold <0..1>  --runs <n>
         --report <path>  --json [path]  --judge-model <model>  ...
Commands: init [options] [name]   Author an eval suite under evals/ ...

$ claude plugin eval init --bare smoke
`plugin eval` is currently in early access
```

It wrote nothing. It is not documented on `code.claude.com` either (grep of the full plugins reference returned no substantive `eval` section). **Do not build a workflow on it yet**, but it is clearly the direction: `evals/**/case.yaml`, `graders/*.md`, `--ablation with-without`, `--threshold`, HTML reports, and a no-plugin baseline arm.

**What works today**, verbatim:

> The check for both is a baseline comparison. Collect a few realistic prompts, run each one in a fresh session with the skill available and again with it disabled, and compare the results. A fresh session matters because leftover context from authoring the skill will mask gaps in the written instructions.

Disable a single skill for the baseline arm via `.claude/settings.local.json`:

```json
{ "skillOverrides": { "gen-riverpod-provider": "off" } }
```

The `skill-creator` plugin automates the loop:

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install skill-creator@claude-plugins-official
/reload-plugins
```

It stores cases in `evals/evals.json` inside the skill directory. The documented shape:

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "I have a CSV of monthly sales data in data/sales_2025.csv. Can you find the top 3 months by revenue and make a bar chart?",
      "expected_output": "A bar chart image showing the top 3 months by revenue, with labeled axes and values.",
      "files": ["evals/files/sales_2025.csv"],
      "assertions": [
        "The output includes a bar chart image file",
        "The chart shows exactly 3 months",
        "Both axes are labeled"
      ]
    }
  ]
}
```

with generated `grading.json`, `timing.json`, `benchmark.json` per iteration. Note the two file formats are **different**: `skill-creator` uses `evals/evals.json`; the gated `claude plugin eval` uses `evals/**/case.yaml`. Expect churn here.

---

## 9. Concrete recommendation — single-dev Flutter repo, ~25 project skills

### 9.1 Layout

```
<repo>/
├── CLAUDE.md                              # committed. <200 lines. Facts only.
├── .gitignore                             # + .claude/settings.local.json, *.py[co]
├── pubspec.yaml
├── lib/ …  test/ …
│
├── .claude/
│   ├── settings.json                      # COMMITTED — shared perms, hooks
│   ├── settings.local.json                # GITIGNORED — machine-local, skillOverrides
│   │
│   ├── .claude-plugin/
│   │   └── plugin.json                    # COMMITTED — lint shim ONLY (see 9.3)
│   │
│   ├── rules/                             # COMMITTED — always-on / path-scoped rules
│   │   ├── dart-style.md
│   │   └── widget-tests.md                # frontmatter: paths: ["test/**/*_test.dart"]
│   │
│   └── skills/                            # COMMITTED — the 25 skills
│       ├── flutter-run-and-verify/
│       │   └── SKILL.md
│       ├── gen-riverpod-provider/
│       │   ├── SKILL.md                   # < 500 lines
│       │   ├── references/
│       │   │   └── provider-patterns.md   # loaded on demand
│       │   ├── templates/
│       │   │   └── provider.dart.tmpl
│       │   └── scripts/
│       │       └── scaffold.sh            # chmod +x
│       ├── add-l10n-string/
│       ├── build-release-android/
│       └── … 21 more
│
└── tool/
    ├── lint_skills.py                     # COMMITTED — the §5.4 linter
    └── lint_skills.sh                     # COMMITTED — the §5.5 one-liner wrapper
```

### 9.2 Committed vs gitignored

| Path | Status | Why |
|---|---|---|
| `.claude/skills/**` | **committed** | The whole point; also what cloud sessions load |
| `.claude/rules/**` | **committed** | Team/self standing rules |
| `.claude/settings.json` | **committed** | Shared permissions and hooks; project plugin scope |
| `.claude/.claude-plugin/plugin.json` | **committed** | Lint shim; runtime-inert (measured) |
| `CLAUDE.md` | **committed** | Session facts |
| `tool/lint_skills.py` | **committed** | The real validator |
| `.claude/settings.local.json` | **gitignored** | Docs: local scope = "Project-specific plugins, gitignored". Holds `skillOverrides` for eval baselines |
| `CLAUDE.local.md` | **gitignored** | Docs recommend this explicitly |
| `.claude/skills/*/evals/results/**` | **gitignored** | Eval run artifacts, regenerable |
| `**/__pycache__/`, `*.pyc` | **gitignored** | Byproduct of `py_compile` in the lint step |

### 9.3 The lint shim — copy this exactly

`.claude/.claude-plugin/plugin.json`:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "e01-project-skills",
  "displayName": "E01 project skills (lint target)",
  "description": "Lint-only manifest so `claude plugin validate ./.claude` can walk .claude/skills/. Not installed, not enabled, not loaded as a plugin at runtime.",
  "version": "0.1.0",
  "author": { "name": "Zakaria Fatahi" }
}
```

Measured properties: (a) `claude plugin validate ./.claude` now descends into `.claude/skills/**/SKILL.md`; (b) `claude plugin list` does **not** report it as a plugin, because a `@skills-dir` plugin must sit *under* a skills directory and `.claude/` is not one. Include `version` and `author` or the validator emits warnings that `--strict` will fail on.

### 9.4 The command to run before committing

```bash
tool/lint_skills.sh
```

where `tool/lint_skills.sh` is:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

echo "==> spec lint (name/dir, charset, lengths, dangling refs)"
python3 tool/lint_skills.py .claude/skills

echo "==> claude plugin validate (YAML parse + manifest schema, strict)"
claude plugin validate ./.claude --strict

echo "==> bundled scripts parse"
find .claude/skills -name '*.sh' -print0 | xargs -0 -r -n1 bash -n
find .claude/skills -name '*.py' -print0 | xargs -0 -r -n1 python3 -m py_compile
find .claude/skills -name '*.dart' -print0 | xargs -0 -r dart analyze --fatal-infos

echo "==> executable bits"
find .claude/skills -path '*/scripts/*' -name '*.sh' ! -perm -u+x -print | \
  { ! grep . ; } || { echo "^ missing chmod +x"; exit 1; }

echo "==> listing budget"
echo "   (run /doctor inside a session to see the skill-listing token cost)"
echo "OK"
```

Install as a hook:

```bash
ln -sf ../../tool/lint_skills.sh .git/hooks/pre-commit
```

### 9.5 Two things to do once the 25 exist

1. Run `/doctor` and check the skill-listing estimate, then `/context` and read the **Skills** row. With 25 skills you are near the 1%-of-context budget. If it overflows, either trim descriptions (key use case first) or set `skillListingBudgetFraction: 0.02` in `.claude/settings.json`.
2. Add `paths:` frontmatter to every skill that is scoped to part of the tree (`lib/features/auth/**`, `test/**`, `android/**`). It reduces false activation and doubles as the staleness signal in §8.2.

---

## 10. Pitfalls — how skill authoring goes wrong in practice

1. **The colon in the description.** `description: Use when: the user asks about X` is invalid YAML. Claude Code's failure mode is silent and nasty, verbatim: "If the frontmatter YAML is malformed, Claude Code loads the skill body with empty metadata, so `/skill-name` still works but Claude has no `description` to match against." Your skill appears to work when you type it and never fires on its own. **Always quote descriptions containing `:`.** `claude plugin validate` does catch this one — one more reason to run it.
2. **Assuming `claude plugin validate` covers your skills.** It refuses any directory without `.claude-plugin/`. Measured. Without the shim you are shipping unvalidated files.
3. **Assuming the validator is strict.** It ignores name/dir mismatch, uppercase names, over-length descriptions, unknown keys, and bad enum values. Measured. Write the linter.
4. **Renaming a skill via frontmatter `name`.** In a project skill that does nothing — the directory name is the command. Verbatim: "In a personal or project skill, `name` sets only the display label shown in skill listings, and the command still comes from the directory or file name." Rename the directory.
5. **Putting `skills/` inside `.claude-plugin/`.** The docs list it as a named failure: "Skills not appearing → Wrong directory structure → Ensure `skills/` or `commands/` is at the plugin root, not inside `.claude-plugin/`."
6. **Forgetting the workspace trust gate.** Verbatim: "For skills checked into a project's `.claude/skills/` directory, `allowed-tools` takes effect after you accept the workspace trust dialog for that folder." Measured: an untrusted workspace also skips project-scope `@skills-dir` plugins entirely. A fresh clone therefore behaves differently from your working copy.
7. **Descriptions that don't state *when*.** The spec's own bad example is `description: Helps with PDFs.` A description is a retrieval key, not a title. It must contain the words a user would type.
8. **Overflowing the listing budget.** At 25 skills, Claude Code starts dropping descriptions from least-used skills. The symptom is "my skill stopped triggering" with nothing in the file changed.
9. **Treating a skill as a fact sheet.** Verbatim from best practices: "A skill should teach the agent *how to approach* a class of problems, not *what to produce* for a specific instance." Facts belong in `CLAUDE.md` or `.claude/rules/`.
10. **Writing prose the model already knows.** "Would the agent get this wrong without this instruction? If the answer is no, cut it." Once loaded, a skill "stays in context across turns, so every line is a recurring token cost."
11. **`context: fork` on a reference skill.** Verbatim warning: "`context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like 'use these API conventions' without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output."
12. **Expecting the skill file to be re-read.** "Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps." Also: a backgrounded `context: fork` skill applies edits outside checkpoints, so `/rewind` won't undo them.
13. **Deep reference chains.** "Keep file references one level deep from `SKILL.md`." `references/a.md` → `references/deep/b.md` → `c.md` reliably loses the model.
14. **Relative script paths that break by install location.** Use `${CLAUDE_SKILL_DIR}/scripts/x.sh` in both the body and `allowed-tools` so the pre-approval rule matches the exact command (v2.1.129+).
15. **Non-executable or interactive scripts.** `chmod +x`; and per the scripts guide, "Agents operate in non-interactive shells — they cannot respond to TTY prompts [...] A script that blocks on interactive input will hang indefinitely."
16. **Testing in the session where you wrote the skill.** "A fresh session matters because leftover context from authoring the skill will mask gaps in the written instructions."
17. **Believing a personal skill will be there tomorrow.** `~/.claude/skills/` does not reach Cowork, cloud sessions, or routines: "If a skill exists only in `~/.claude/skills/` on your machine, Claude Code reports that the skill was not found when a routine invokes it."

---

## 11. Explicitly unverified

- **Does Claude Code v2.1.220 scan `.agents/skills/`?** The docs list only enterprise / `~/.claude/skills/` / `.claude/skills/` / plugin `skills/`. My empirical probe was inconclusive: the test workspace had `hasTrustDialogAccepted: false`, so *neither* marker skill was visible, including the `.claude/skills/` control. **Treat `.agents/skills/` as unsupported by Claude Code until proven otherwise**, and if cross-agent sharing is needed, symlink `.agents/skills → .claude/skills`.
- **`skills-ref` strictness.** No `uv`/`uvx`/`pipx` on this machine, so I could not run `skills-ref validate` against the fixture set. Its README self-describes as "for demonstration purposes only, not production use." Unknown whether it enforces the name/dir rule.
- **`claude plugin eval` semantics.** Flags are read from `--help`; behaviour is gated behind early access and could not be exercised. The `case.yaml` / `graders/*.md` schema is unknown beyond the help text.
- **Whether `--strict` on `claude plugin validate` will ever gain SKILL.md rules.** Currently it only escalates the two existing warnings.
- **`skills` CLI reproducibility.** No lockfile is documented; whether `skills update` pins anything is unverified.
- **Exact `.claude/settings.json` key list** — I did not fetch the settings reference page; the setting names used here (`skillOverrides`, `skillListingBudgetFraction`, `skillListingMaxDescChars`, `disableBundledSkills`, `disableSkillShellExecution`, `claudeMdExcludes`, `autoMemoryEnabled`) are all quoted from the skills/memory pages, but their full value schemas were not independently confirmed.

---

## 12. Sources

Every URL below was actually fetched or executed during this research.

**Agent Skills open standard**
- <https://agentskills.io> — overview, governance, client showcase
- <https://agentskills.io/llms.txt> — page index
- <https://agentskills.io/specification> — the normative spec
- <https://agentskills.io/skill-creation/best-practices> — authoring guidance, progressive disclosure
- <https://agentskills.io/skill-creation/evaluating-skills> — `evals/evals.json`, grading, benchmarks
- <https://agentskills.io/skill-creation/using-scripts> — script bundling, PEP 723, agentic script design
- <https://agentskills.io/client-implementation/adding-skills-support> — discovery paths, `.agents/skills/`, precedence, lenient validation
- <https://github.com/agentskills/agentskills> — repo layout, `skills-ref`
- <https://raw.githubusercontent.com/agentskills/agentskills/main/README.md>
- <https://raw.githubusercontent.com/agentskills/agentskills/main/skills-ref/README.md>

**Claude Code documentation** (note: `docs.claude.com/en/docs/claude-code/*` 301s here)
- <https://code.claude.com/docs/en/skills> — locations, precedence, full frontmatter reference, lifecycle, listing budget, troubleshooting
- <https://code.claude.com/docs/en/plugins> — creating plugins, `--plugin-dir`, migration, submission
- <https://code.claude.com/docs/en/plugins-reference> — `plugin.json` schema, path rules, skills-dir plugins, CLI reference, versioning
- <https://code.claude.com/docs/en/plugin-marketplaces> — `marketplace.json` schema, sources, validation section
- <https://code.claude.com/docs/en/memory> — CLAUDE.md hierarchy, `AGENTS.md`, `.claude/rules/`, auto memory
- <https://code.claude.com/docs/llms.txt> — page index
- <https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md> — skill/plugin entries for v2.1.178–2.1.220

**Anthropic skill repositories**
- <https://github.com/anthropics/skills> — layout, `spec/`, `template/`
- <https://raw.githubusercontent.com/anthropics/skills/main/.claude-plugin/marketplace.json> — real marketplace manifest

**Schemas**
- <https://www.schemastore.org/claude-code-plugin-manifest.json>
- <https://www.schemastore.org/api/json/catalog.json> — confirms no SKILL.md schema exists

**npm**
- `npm view skills version repository.url description` → 1.5.20, `vercel-labs/skills`
- <https://raw.githubusercontent.com/vercel-labs/skills/main/README.md>

**Locally executed (v2.1.220)**
- `claude --version`
- `claude plugin --help`, `plugin validate --help`, `plugin eval --help`, `plugin eval init --help`
- `claude plugin validate` against 6 fixture directory shapes and 9 broken-`SKILL.md` fixtures
- `claude plugin validate --strict` exit-code behaviour
- `claude plugin list` in a workspace containing both a real `@skills-dir` plugin and a `.claude/.claude-plugin/` shim
- `tool/lint_skills.py` prototype against the same fixtures
