---
description: "Phase 4: Install stack-specific skills and MCP servers for every detected technology."
---

# Phase 4: Stack-Aware Tooling

> Self-contained phase. Requires Phase 2 (.ai/ folder). Can run after Phase 2 or Phase 3.

## Prerequisites

- Phase 2 completed (`.ai/` folder with `project-context.md` and tech stack identified)
- Network access for registry queries

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

For each detected technology, search GitHub for community skills using the `gh` CLI:

```bash
# Search GitHub for SKILL.md files matching the technology
gh search repos "SKILL.md <technology-name>" --sort stars --limit 5 --json fullName,url,stargazersCount
```

If a result looks authoritative (vendor org, high stars), fetch the SKILL.md directly:

```bash
# Download the SKILL.md into the project skills folder
curl -sL "https://raw.githubusercontent.com/<owner>/<repo>/main/SKILL.md" \
  -o ".github/skills/<technology-name>/SKILL.md"
```

**Rules:**
- Only accept results from vendor orgs (e.g. `vercel/`, `shopify/`, `prisma/`) — not individual accounts
- Skip if a skill with that name already exists in `.github/skills/`
- If no suitable match is found on GitHub, generate a minimal skill from `.ai/` evidence (see Fallback section below)
- Record each result (downloaded / skipped / generated fallback)

**Fallback — generate skill from project evidence:**

If `gh search` returns no suitable result, generate a minimal project-specific skill directly from what was found in the `.ai/` files:

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

## Verification

- [ ] Skills searched for all detected technologies
- [ ] MCP servers installed (or documented why not)
- [ ] MCP config written to all 3 IDE files
- [ ] Project support agent created

## Completion Signal

```
✓ Phase 4 complete: Stack-specific tools installed.
  Migration workflow complete. Run scripts/validate.sh to verify compliance.
```
