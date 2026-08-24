---
description: "Phase 4: Install stack-specific skills and MCP servers for every detected technology."
---

# Phase 4: Stack-Aware Tooling

> Self-contained phase. Requires Phase 2 (.ai/ folder). Can run after Phase 2 or Phase 3.

## Prerequisites

- Phase 2 completed (`.ai/` folder generated, with the technology stack table in `architecture.md`)
- Network access for registry queries

## Step 7.5: Detect Existing Test Patterns (Before Stack Detection)

Before detecting the tech stack, check whether the project already has tests:

```bash
# Look for test files
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.tsx" -o -name "*.spec.tsx" \
       -o -name "*.test.js" -o -name "*.test.py" -o -name "test_*.py" \
       | grep -v node_modules | head -20
```

Also check `package.json` for test framework packages:
- `vitest` → Vitest (TypeScript/JavaScript)
- `jest` → Jest (TypeScript/JavaScript)
- `@testing-library/*` → component testing
- `pytest` in `pyproject.toml`/`requirements.txt` → pytest (Python)
- `xunit`, `NUnit`, `MSTest` in `*.csproj` → .NET test frameworks

**Decision rule:**
- If test files exist AND a test framework is detected → generate a **testing skill** (see below) during Step 9
- If no test files exist → skip testing skill entirely. Do not install `test-driven-development` or any generic testing skill.
- Never install a generic or methodology-first TDD skill. Testing skills must reflect the framework and patterns already in use.

**Generating a testing skill when tests exist:**

```markdown
---
name: testing
description: "Use when adding or modifying tests in [PROJECT_NAME]. Framework: [FRAMEWORK]."
---

# Testing in [PROJECT_NAME]

## Test Framework
[FRAMEWORK] — [version from package.json/pyproject.toml]

## Existing Test Patterns
[Describe what the existing tests actually test, e.g. "unit tests for donation/form mapping in src/lib/__tests__/"]

## Key Test Files
[List 3-5 representative test files found during detection]

## Writing Tests Here
- Follow existing file naming: `[pattern from existing files]`
- Use existing test utilities if any (e.g. `src/test-utils.ts`)
- Focus coverage on [most tested area from discovery], not on achieving arbitrary percentages

## Running Tests
[Command from package.json scripts or pyproject.toml]
```

---

## Step 8: Detect the Tech Stack

Read project manifest files and config to identify all technologies:

**Detection sources** (check all that exist):
- `package.json` (all workspaces if monorepo) — `dependencies`, `devDependencies`, `peerDependencies`
- `*.csproj`, `global.json` (.NET)
- `pyproject.toml`, `requirements.txt` (Python)
- `go.mod` (Go)
- `pom.xml`, `build.gradle` (Java/Kotlin)
- `composer.json` (PHP)
- `Gemfile` (Ruby)
- Config file presence (`next.config.*`, `turbo.json`, `wrangler.toml`, `Dockerfile`, `*.tf`)
- CI/CD configs (`.github/workflows/`, `azure-pipelines.yml`)
- Technology names already in `.ai/architecture.md` (technology stack table)

**Mapping:** Use `config/stack-detection.yml` from DEPT standards repo to translate detected signals to technology names.

## Step 9: Install Skills from Public Registry

For each detected technology, use the GitHub CLI skill workflow:

```bash
# Search for matching skills on GitHub
gh skill search "<technology-name>" --owner <vendor-org> --limit 5 --json repo,skillName,path,stars
```

If a result looks authoritative (vendor org, relevant skill name/path), install it into the project:

```bash
# Install the skill into the project skills folder
gh skill install <owner>/<repo> <skill-name> --dir .agents/skills --force
```

**Rules:**
- Only accept results from vendor orgs (e.g. `vercel/`, `shopify/`, `prisma/`), not individual accounts
- Skip if a skill with that name already exists in `.agents/skills/`
- If no suitable match is found on GitHub, generate a minimal skill from `.ai/` evidence (see Fallback section below)
- There must be a resulting `.agents/skills/<technology-name>/SKILL.md` for every detected core technology unless the technology was skipped
- Record each result (installed / skipped / generated fallback) in the completion summary for this run, not in `.ai/`

**Fallback — generate skill from project evidence:**

If `gh skill search` returns no suitable result, generate a minimal project-specific skill directly from what was found in the `.ai/` files:

```markdown
---
name: <technology-name>
description: "Use when working with <technology> in [PROJECT_NAME]: [specific scenarios based on .ai/ files]."
---

# <Technology Display Name>

## Project Context
Read `.ai/architecture.md` for how <technology> fits this project.

## Key Files
- [actual paths found during discovery]

## Common Operations
[most relevant operations for how this tech is actually used here — from .ai/ evidence only]
```

**Accuracy rules for generated skills (non-negotiable — this is where hallucinated skills come from):**
- **No invented APIs.** Every import, function, symbol, or hook name in a code sample must be verified to exist. Before writing it, `grep` the symbol in the repo (or confirm it in the package's `exports`). If you can't find it, don't write it — describe the real helper the project actually uses. (e.g. do not invent `getOptimizelyClient()` when the repo fetches via a `graphqlFetch` wrapper.)
- **Real paths only.** Every path must be confirmed with `ls`/glob. Do not invent route segments like `app/[locale]/` unless that directory exists.
- **Copy, don't imagine.** Base each code sample on a real call site found in the repo; cite the file you took it from.
- **No empty sections.** Every heading has real content or is omitted. Do not emit stub headings.
- **Don't restate global constraints.** Rules already in `.ai/` or `AGENTS.md` (commits, `process.env`, deploy target) are referenced with a one-line pointer, not re-documented per skill. `standards/writing-rules.md` §2 is the test.
- **State scope precisely.** A skill's frontmatter scope and body must match — don't add off-topic sections (e.g. Docker build steps inside a framework skill) unless the skill's stated scope covers them.

**Important expectation:** for common stacks such as React, Next.js, Contentful, Prisma, Shopify, and Vercel, the phase should usually end with installed skill files in `.agents/skills/`, either vendor-fetched or evidence-generated fallback.

## Step 9.3: The `codebase-overview` Skill

Alongside the technology skills, emit `.agents/skills/codebase-overview/SKILL.md` from
`templates/skills/codebase-overview/SKILL.md`, substituting `[PROJECT_NAME]`. Like every other
skill it needs no mirroring, see Step 9.4.

The `description` frontmatter is what makes an agent discover the skill before it starts exploring
the tree. The body is generated from `.ai/architecture.md`: copy the repository tree, the technology
stack table, the placement conventions and the high-fan-in symbols verbatim into the block between
the `BEGIN GENERATED FROM .ai/architecture.md` and `END GENERATED FROM .ai/architecture.md` markers.
Copy nothing else from `.ai/`; every other topic gets at most a one-line pointer to the file that
owns it.

`.ai/architecture.md` remains the single source of truth and the only file edited by hand. The
generated block is a derived copy that is rewritten whenever those sections change (Maintainer Agent
Phase 4d), so an agent whose harness loads skills but not `.ai/` still gets the structure. Editing
the generated block instead of `.ai/architecture.md` is the failure mode.

## Step 9.4: Mirror Skills to Other Clients

`.agents/skills/` is read by GitHub Copilot, VS Code, Codex and Cursor. It is not auto-discovered by Claude Code, which reads `.claude/skills/` only. SKILL.md's `name`/`description` frontmatter is the same format across all of these, so no translation is needed.

**Do not copy any skill.** `.claude/skills` is one relative symlink to `.agents/skills`, so every skill installed or generated in Steps 9 and 9.3 is already mirrored. Run

```bash
bash scripts/mirror-claude.sh
```

if `.claude/skills` is missing, or if this project still carries a copied `.claude/skills/` directory from an older standard: the script converts it, moving into `.agents/skills/` (and reporting) anything that existed only in the copy. The rule and the fallback for a checkout without symlink support are stated once in `standards/agentic-project-standard.md` -> Claude Code mirrors.

## Step 9.5: Update agent-registry.md with Installed Skills

After installing all skills, merge a "Skills" section into `.ai/agent-registry.md`. Read the file first, merge, never overwrite existing content.

```markdown
### Skills

| Skill | Source | Purpose |
|---|---|---|
| `<technology>/SKILL.md` | Vendor skill / Generated from project evidence | [one-line description from skill frontmatter] |
```

- Use the `description` field from each skill's YAML frontmatter as the Purpose
- Source: "Vendor skill" if fetched via `gh skill install`, "Generated from project evidence" if fallback-generated
- List every skill the project has, whether it was installed in this run or already present
- A technology that was skipped has no row. The skip and its reason go in this run's completion summary. `standards/writing-rules.md` §1 is why: `agent-registry.md` records what is wired up, not what an agent chose not to do

## Step 10: Find and Install MCP Servers

**Priority order (stop at first match per technology):**

### 1. DEPT MCP Registry (highest trust)
```bash
curl -s "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/config/mcp-registry.yml"
```
Use if technology has an entry and `skip` is not true.

### 2. Public MCP Registry (fallback)
```bash
curl -s "https://registry.modelcontextprotocol.io/v0/servers?search=<technology-name>"
```

**Quality checks on public registry results:**
- Repository URL contains vendor org (e.g. `github.com/Shopify/`, `github.com/prisma/`)
- npm package uses vendor scope (e.g. `@shopify/`, `@prisma/`) — NOT individual scopes
- GitHub org has multiple contributors
- Skip all individual-account packages

### Write MCP Config (All Three IDEs)

| IDE | File | Root Key |
|---|---|---|
| VS Code / Copilot | `.vscode/mcp.json` | `servers` |
| Cursor | `.cursor/mcp.json` | `mcpServers` |
| Claude Code | `.mcp.json` | `mcpServers` |

**Read first, merge, write back.** Never remove or overwrite existing entries.

> **Reload note:** MCP servers written here become callable only after the
> tool/IDE reloads its MCP connections — they are **not** available later in the
> same migration run. In particular, do not expect to use an `atlassian` MCP for
> Confluence: that publishing already happened in Phase 3 via the `confluence-axi`
> skill. The config written here is for the developer's next session.

After writing MCP configs, update the `## MCP Servers` section in `.ai/agent-registry.md`:

```markdown
## MCP Servers

Config in `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`.

| Server key | Package | Transport | Purpose |
|---|---|---|---|
| `<key>` | `<npm-package>` | stdio / http | [what it provides] |
```

If the section already exists, merge new entries — never remove existing rows.

## Step 11: Generate Support Agent

Create `.github/agents/support.agent.md` if not already present.

**No `tools:` line.** Both Copilot and Claude Code read an agent without one as having every
available tool, MCP servers included, so the enumerated list added nothing and went stale as soon as
a server was added. Leaving it out is also what makes the source valid for both harnesses, which is
what lets the Claude Code mirror be a symlink rather than a second file.

Do list what the project has in the body, where it is documentation rather than a restriction:
- installed skills, from `.agents/skills/`
- MCP servers, from `.vscode/mcp.json`, `.cursor/mcp.json` and `.mcp.json`

**Agent content from template:**
- Use `templates/agents/support.template.md`
- Substitute all `[PLACEHOLDER]` values in the body:
  - `[PROJECT_NAME]` → from `.ai/project-context.md`
  - `[TECH_STACK_SUMMARY]` → e.g., "Node.js + Next.js + PostgreSQL + Vercel"
  - `[SKILL_LIST]` → bulleted list of installed skills with brief descriptions
  - `[MCP_SERVERS_TABLE]` → table of MCP servers (name, tools, purpose)
  - `[TECH_STACK_DETAILS]` → detailed tech stack from `.ai/architecture.md`
  - `[CONSTRAINTS]` → notable items from `.ai/` files (monorepo layout, deploy constraints, gotchas)
- Leave the frontmatter at `description` and `name: support`. Add no `tools:` line.

**Quality checks:**
- All MCP servers in config files are listed in agent
- No MCP server tool name conflicts (if 2 servers have same tool name, disambiguate)
- Agent references `.ai/` context files explicitly
- Behaviour rules emphasize evidence-first and MCP tool usage

### Mirror to Claude Code

Claude Code auto-loads subagents from `.claude/agents/`. Do not write that file: link it to the source you just wrote by running

```bash
bash scripts/mirror-claude.sh
```

It creates `.claude/agents/support.md` as a relative symlink to `../../.github/agents/support.agent.md`. There is no second copy of the support agent, so there is nothing to keep in step and nothing that can drift: two hand-maintained copies of the same agent have already diverged by 85 lines in a client repository.

`name: support` is the role in lowercase, which satisfies Claude Code's naming rule and reads the same in both pickers. VS Code Copilot default-scans both folders and lists the agent twice; it is one file, so the two rows carry the same name.

## Verification

- [ ] A skill file exists for every detected core technology, and any skipped technology is named with its reason in this run's completion summary
- [ ] Every code sample in a generated skill uses only symbols/imports verified to exist (grep/exports), and every path was confirmed with `ls`/glob: no invented APIs or route segments
- [ ] No generated skill has empty/stub sections, and none restates global constraints already in `.ai/` or `AGENTS.md` (pointer only)
- [ ] Testing skill installed only if test files exist AND framework is detected, not otherwise
- [ ] No generic `test-driven-development` skill installed (it's methodology-prescriptive, not evidence-based)
- [ ] `codebase-overview` skill emitted, `[PROJECT_NAME]` substituted, and its generated block carries the repository tree, stack table, placement conventions and high-fan-in symbols verbatim from `.ai/architecture.md`
- [ ] `.ai/agent-registry.md` has a "Skills" section listing every skill the project has
- [ ] MCP servers installed where the registry has an entry; anything not installed is named in this run's completion summary
- [ ] MCP config written to all 3 IDE files
- [ ] `.ai/agent-registry.md` `## MCP Servers` section updated with installed servers
- [ ] Project support agent created
- [ ] `scripts/mirror-claude.sh` run: `.claude/skills` symlinks to `.agents/skills`, and `.claude/agents/support.md` symlinks to `.github/agents/support.agent.md`
- [ ] Nothing under `.claude/` was written or edited by hand

## Completion Signal

```
✓ Phase 4 complete: Stack-specific tools installed.
  Migration workflow complete. Run scripts/validate.sh to verify compliance.
```
