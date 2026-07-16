---
description: "Phase 4: Install stack-specific skills and MCP servers for every detected technology."
---

# Phase 4: Stack-Aware Tooling

> Self-contained phase. Requires Phase 2 (.ai/ folder). Can run after Phase 2 or Phase 3.

## Prerequisites

- Phase 2 completed (`.ai/` folder with `project-context.md` and tech stack identified)
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
- Technology names already in `.ai/project-context.md`

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
gh skill install <owner>/<repo> <skill-name> --dir .github/skills --force
```

**Rules:**
- Only accept results from vendor orgs (e.g. `vercel/`, `shopify/`, `prisma/`) — not individual accounts
- Skip if a skill with that name already exists in `.github/skills/`
- If no suitable match is found on GitHub, generate a minimal skill from `.ai/` evidence (see Fallback section below)
- There must be a resulting `.github/skills/<technology-name>/SKILL.md` for every detected core technology unless you explicitly record why the technology was skipped
- Record each result (installed / skipped / generated fallback)

**Fallback — generate skill from project evidence:**

If `gh skill search` returns no suitable result, generate a minimal project-specific skill directly from what was found in the `.ai/` files:

```markdown
---
name: <technology-name>
description: "Use when working with <technology> in [PROJECT_NAME]: [specific scenarios based on .ai/ files]."
---

# <Technology Display Name>

## Project Context
Read `.ai/project-context.md` for how <technology> is used in this project.

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
- **Don't restate global constraints.** Rules already in `.ai/` or `copilot-instructions.md` (commits, `process.env`, deploy target) are referenced with a one-line pointer, not re-documented per skill.
- **State scope precisely.** A skill's frontmatter scope and body must match — don't add off-topic sections (e.g. Docker build steps inside a framework skill) unless the skill's stated scope covers them.

**Important expectation:** for common stacks such as React, Next.js, Contentful, Prisma, Shopify, and Vercel, the phase should usually end with installed skill files in `.github/skills/` — either vendor-fetched or evidence-generated fallback.

## Step 9.4: Mirror Skills to Other Clients

`.github/skills/` is read by GitHub Copilot. It is not auto-discovered by Claude Code (`.claude/skills/`) or Continue/Kilocode-style clients (`.continue/skills/`, `.kilocode/skills/`). SKILL.md's `name`/`description` frontmatter is the same format across all of these — no translation needed, just a copy.

For every skill installed or generated in Step 9 (vendor-fetched or fallback), copy the whole skill directory verbatim to:
- `.claude/skills/<technology-name>/`

**Rule:** `.github/skills/` stays the single source of truth for content. Mirrors are exact copies, re-copied whenever the source changes — never hand-edited independently. If a skill directory already exists at the mirror path with identical content, skip.

## Step 9.5: Update agent-registry.md with Installed Skills

After installing all skills, append a "Phase 4 Skills" section to `.ai/agent-registry.md`. Read the file first, merge, never overwrite existing content.

```markdown
### Phase 4 Skills (stack-specific, installed YYYY-MM-DD)

| Skill | Source | Purpose |
|---|---|---|
| `<technology>/SKILL.md` | Vendor skill / Generated from project evidence | [one-line description from skill frontmatter] |
```

- Use the `description` field from each skill's YAML frontmatter as the Purpose
- Source: "Vendor skill" if fetched via `gh skill install`, "Generated from project evidence" if fallback-generated
- Include every skill installed or generated in this phase — no silent omissions
- If a technology was skipped, add a row with "Skipped — [reason]" in Purpose column

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

After writing MCP configs, update the `## MCP Servers` section in `.ai/agent-registry.md`:

```markdown
## MCP Servers

Installed by Phase 4 (YYYY-MM-DD). Config in `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`.

| Server key | Package | Transport | Purpose |
|---|---|---|---|
| `<key>` | `<npm-package>` | stdio / http | [what it provides] |
```

If the section already exists, merge new entries — never remove existing rows.

## Step 11: Generate Support Agent

Create `.github/agents/support-agent.agent.md` if not already present.

**Tools to include (use template/agents/support-agent.template.md):**

1. **Core tools** (always present):
   - `read` — file system access
   - `edit` — file creation/modification
   - `search` — code search
   - `run_in_terminal` — command execution
   - `github/*` — GitHub API (issues, PRs, code search)

2. **Installed skills** (from Phase 4 Step 9):
   - Parse `.github/skills/` directory
   - For each skill, list its available tools in agent definition
   - Example: skill `superpowers:systematic-debugging` provides `debug/*` tools

3. **MCP server tools** (for each server in .vscode/mcp.json, .cursor/mcp.json, .mcp.json):
   - Parse all MCP configs to extract server keys
   - For each server, add `<server-key>/*` to tools list
   - Example: if `.vscode/mcp.json` has `@atlassian/mcp-jira`, add `jira/*`

**Agent content from template:**
- Use `templates/agents/support-agent.template.md`
- Substitute all `[PLACEHOLDER]` values in the body:
  - `[PROJECT_NAME]` → from `.ai/project-context.md`
  - `[TECH_STACK_SUMMARY]` → e.g., "Node.js + Next.js + PostgreSQL + Vercel"
  - `[SKILL_LIST]` → bulleted list of installed skills with brief descriptions
  - `[MCP_SERVERS_TABLE]` → table of MCP servers (name, tools, purpose)
  - `[TECH_STACK_DETAILS]` → detailed tech stack from `.ai/project-context.md`
  - `[CONSTRAINTS]` → notable items from `.ai/` files (monorepo layout, deploy constraints, gotchas)
- **Rewrite the `tools:` frontmatter line** to include all MCP server keys:
  ```
  tools: [read, edit, search, run_in_terminal, "github/*", "contentful/*", "vercel/*", "nextjs/*"]
  ```
  Replace the comment line and base `tools:` entry with this expanded version.

**Quality checks:**
- All MCP servers in config files are listed in agent
- No MCP server tool name conflicts (if 2 servers have same tool name, disambiguate)
- Agent references `.ai/` context files explicitly
- Behaviour rules emphasize evidence-first and MCP tool usage

### Mirror to Claude Code

Claude Code auto-loads subagents from `.claude/agents/`. Create `.claude/agents/support-agent.md` with the same body (Project Context, Installed Skills, MCP Servers, Behaviour Rules, Tech Stack, Constraints, Escalation) but Claude Code frontmatter instead of Copilot's:

```markdown
---
name: "Support Agent"
description: "Support & development agent for [PROJECT_NAME]. Use for feature development, debugging, support tasks, and code changes in this [TECH_STACK_SUMMARY] project."
---
```

Keep `name:` **identical to the `.github/agents/support-agent.agent.md` source** (`"Support Agent"`) — VS Code Copilot default-scans both folders and shows the agent twice, so matching names makes the two picker rows read as one agent rather than two. Omit a `tools:` restriction — Claude Code subagents inherit all available tools (file, search, bash, and every configured MCP server) by default, which already covers everything the Copilot `tools:` list enumerates explicitly. Don't translate the Copilot tool-name list into Claude Code tool names — unnecessary and drifts out of sync.

## Verification

- [ ] A skill file exists for every detected core technology (or an explicit skip reason is documented)
- [ ] Every code sample in a generated skill uses only symbols/imports verified to exist (grep/exports), and every path was confirmed with `ls`/glob — no invented APIs or route segments
- [ ] No generated skill has empty/stub sections, and none restates global constraints already in `.ai/`/`copilot-instructions.md` (pointer only)
- [ ] Testing skill installed only if test files exist AND framework is detected — not otherwise
- [ ] No generic `test-driven-development` skill installed (it's methodology-prescriptive, not evidence-based)
- [ ] `.ai/agent-registry.md` has a "Phase 4 Skills" section listing every skill installed or skipped
- [ ] MCP servers installed (or documented why not)
- [ ] MCP config written to all 3 IDE files
- [ ] `.ai/agent-registry.md` `## MCP Servers` section updated with installed servers
- [ ] Project support agent created
- [ ] Every skill from Step 9 mirrored into `.claude/skills/`
- [ ] `.claude/agents/support-agent.md` created, mirroring `.github/agents/support-agent.agent.md`'s body

## Completion Signal

```
✓ Phase 4 complete: Stack-specific tools installed.
  Migration workflow complete. Run scripts/validate.sh to verify compliance.
```
