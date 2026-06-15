---
description: "Migrate any project into DEPT Managed Services standards. Generates complete AI-ready documentation (.ai/ folder), installs agents and superpowers skills, wires all AI tools, and creates Confluence handover pages in one workflow."
---

# Migrate Project to DEPT Managed Services Standards

You are running the **DEPT Managed Services Migration** workflow. This automated process transforms any repository into an AI-ready Managed Services project.

## What You'll Get

After this workflow completes:
- ✓ Complete `.ai/` documentation (9 files covering architecture, operations, standards, and onboarding)
- ✓ AI agents installed and ready to use (discovery and maintainer agents)
- ✓ Superpowers skills available (evidence-first discipline, systematic debugging, verification, TDD)
- ✓ All AI tools wired (Copilot, Claude, Cursor auto-load `.ai/` context)
- ✓ Confluence handover pages created in fixed location (no user prompts)
- ✓ Project developer agent configured with all tools and skills

**Time estimate:** 15-30 minutes depending on repository complexity.

## Critical Disciplines

**Write all output as actual files to the repository on disk.** Do not write to session files or summarize in chat only.

**Follow superpowers:writing-skills discipline:**
- Evidence first: only cite what you find in code, config, and infrastructure
- No hallucination: mark unknowns explicitly
- All claims traceable to source files

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. Map all packages before per-package analysis.

---

## PHASE 1: Installation (Steps 1-2)

Install required agents and superpowers skills into this repository.

### Step 1: Fetch and Install DEPT Agents

Fetch these files from the DEPT Agentic Standards repository:

| Agent | Source | Write to |
|---|---|---|
| Discovery Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-discovery.agent.md` | `.github/agents/ai-project-discovery.agent.md` |
| Maintainer Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-maintainer.agent.md` | `.github/agents/ai-project-maintainer.agent.md` |
| Bootstrap Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate-ms.prompt.md` | `.github/prompts/migrate-ms.prompt.md` |

**Action:** Create `.github/agents/` and `.github/prompts/` directories. Write each file. Skip if already exists.

### Step 2: Install Superpowers Skills

Superpowers skills provide reusable discipline patterns that agents reference. Install these 4 required skills:

| Skill | Purpose | Source | Write to |
|---|---|---|---|
| writing-skills | Evidence-first documentation and skill creation | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/writing-skills/SKILL.md` | `.github/skills/writing-skills/SKILL.md` |
| systematic-debugging | Root-cause analysis and debugging patterns | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/systematic-debugging/SKILL.md` | `.github/skills/systematic-debugging/SKILL.md` |
| verification-before-completion | Quality gates and testing before declaring work done | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/verification-before-completion/SKILL.md` | `.github/skills/verification-before-completion/SKILL.md` |
| test-driven-development | TDD patterns and RED-GREEN-REFACTOR cycle | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/test-driven-development/SKILL.md` | `.github/skills/test-driven-development/SKILL.md` |

**Action:** Create `.github/skills/` directory. Write each skill file. Skip if already exists.

**Why these skills:** Agents reference these with `/superpowers:skill-name` notation. They must be available locally.

---

## PHASE 2: Discovery and Analysis (Steps 3-5)

Analyze the repository and generate complete `.ai/` context.

### Step 3: Scan Existing Agentic Configuration

Before generating new files, identify what already exists in the repository:

**Scan these locations:**
- **Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- **Instructions**: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `CLAUDE.md`, `.cursor/rules/`
- **Prompts / Skills**: `.github/prompts/*.prompt.md`, `.github/skills/`, `.claude/skills/`
- **MCP**: `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`, VS Code `mcpServers` settings

**Record findings** (file path, name, tool, scope, purpose). This informs `agent-registry.md` and prevents overwriting.

### Step 4: Collect Required Onboarding Links

Gather these 5 links from repository evidence (config files, CI/CD, README, GitHub):
- **GitHub URL** (repository location)
- **Test environment URL** (where features are tested)
- **Acceptance environment URL** (where client validates)
- **Production environment URL** (live service)
- **Keeper URL** (or equivalent secret-management reference for `.env` values)

**Action:** Verify each link from codebase evidence. If any cannot be verified, prompt the user for the missing values.

**Note:** Do NOT ask for Confluence URL. All Confluence pages are created under a fixed DEPT location: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

### Step 5: Generate `.ai/` Context Files

Generate all 9 context files and write to `.ai/` directory in repository root.

**Files to create:**
1. `project-context.md` — what the system is, key services, monorepo structure, tech stack
2. `architecture.md` — service boundaries, runtime topology, data flows, external systems
3. `runbooks.md` — operational procedures, incident response, common issues and fixes
4. `dependencies.md` — critical vendors, lock-in risks, upgrade paths
5. `cms.md` — CMS SDKs, content models, webhooks, caching, publishing flow
6. `operational-context.md` — deployment pipeline, environments, promotion flow, rollback strategy, monitoring
7. `coding-standards.md` — conventions, quality gates, testing, branching, PR requirements
8. `agent-registry.md` — existing agents, instructions, skills, MCP servers found in Step 3
9. `onboarding.md` — GitHub, environment, and Keeper references collected in Step 4; handover checklist

**For each file:**
- Extract evidence from code, config, CI/CD, and infrastructure files
- Include `Assumption:` tags on inferred content
- Rate `Confidence: <0-100>%` per major section
- Add `Validation Questions` for unresolved gaps
- Cite source evidence (file paths, config names, commit references)
- Redact secrets and privileged credentials

**Quality check:** No empty sections, no placeholders. Every section has content or an explicit unknown statement.

---

## PHASE 3: Integration (Steps 6-7)

Wire AI tools to automatically load `.ai/` context and create Confluence documentation.

### Step 6: Wire AI Tools

Create or update wiring files so every AI tool (Copilot, Claude, Cursor) automatically reads `.ai/` context at session start.

**Rule:** Check each file first. If it exists, append only. Never overwrite existing content.

**File 1: `.github/copilot-instructions.md`**
- Not present: create with full `.ai/` reading instructions and behaviour rules
- Already present: append a `## AI Project Context (.ai/)` section

**File 2: `CLAUDE.md`** (repository root)
- Not present: create with same instructions in Claude format
- Already present: append a `## AI Project Context (.ai/)` section

**File 3: `.github/instructions/ai-context.instructions.md`**
- Not present: create with `applyTo: "**"` frontmatter and concise loading instructions
- Already present: leave unchanged (report as already present)

**All wiring files must instruct AI to:**
1. Read `.ai/` files at session start
2. Cross-reference `.ai/` with agents/instructions/skills found in Step 3
3. Respect constraints in existing agentic files
4. Flag contradictions between `.ai/` and codebase (don't silently accept stale context)

### Step 7: Create Confluence Project Documentation

After `.ai/` files are generated and wiring is complete, create handover documentation in Confluence.

**Target location:**
- Space: `MS`
- Path: `Projects`
- Base URL: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

**Action steps:**
1. Ensure `Projects` directory exists. Create if missing.
2. Create a project page under `Projects` if not present.
3. Make content readable for mixed roles (developer + client manager). Focus on practical onboarding/handover.
4. Use subpages for readability:
   - Overview (what the system is, key contacts)
   - Environments and Access (GitHub, test/acc/prod URLs, Keeper reference)
   - Onboarding and Handover (setup steps, troubleshooting, escalation)
5. Include all 5 links collected in Step 4.
6. Do NOT create a separate coding standards page unless explicitly requested.

---

## PHASE 4: Stack-Aware Tooling (Step 8)

Install skills and MCP servers for every technology detected in the project.

### Step 8: Install Stack-Specific Tools

**Goal:** For every technology found in this project, install matching skills and MCP servers from live public registries.

#### Detect the Tech Stack

Read `package.json` (all workspaces if monorepo) and root config files. Extract:
- All `dependencies`, `devDependencies`, and `peerDependencies` package names
- Config file presence (e.g. `next.config.*`, `turbo.json`, `wrangler.toml`, `Dockerfile`)
- Technology names already in `.ai/project-context.md`

**Mapping hint:** Use `config/stack-detection.yml` from DEPT standards repo to translate package names to human-readable tech names.

#### Install Skills from Public Registry

For each detected technology, search [agentskills.io](https://agentskills.io):

```bash
gh skill search <technology-name>
gh skill install <owner>/<repo> <skill-name>
```

Skills install to `.github/skills/<name>/` automatically.

**Rules:**
- Search for every detected technology, not a predefined list
- Skip if a skill with that name already exists
- If search returns no result, skip (do not fabricate)
- Record each result (installed / skipped / not found)

#### Find and Install MCP Servers

**Priority order (stop at first match):**

**1. DEPT MCP Registry (highest trust):**
```bash
curl -s "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/config/mcp-registry.yml"
```
Use this if technology has an entry and `skip` is not true. Do not query public registry if DEPT registry has entry.

**2. Public MCP Registry (only when DEPT registry has no entry):**
```bash
curl -s "https://registry.modelcontextprotocol.io/v0/servers?search=<technology-name>"
```

**Quality checks on public registry results:**
- Repository URL contains vendor org (e.g. `github.com/Shopify/`, `github.com/prisma/`)
- npm package uses vendor scope (e.g. `@shopify/`, `@prisma/`) — NOT individual scopes
- GitHub org has multiple contributors
- Skip all individual-account packages (`io.github.<username>/`)

#### Write MCP Config (All Three IDEs)

Write to all three IDE config files so project works everywhere:

| IDE | File | Root Key | Stdio Format | HTTP Format |
|---|---|---|---|---|
| VS Code / Copilot | `.vscode/mcp.json` | `servers` | `"type": "stdio"` + `command` + `args` | `"type": "http"` + `url` |
| Cursor | `.cursor/mcp.json` | `mcpServers` | `command` + `args` | `"type": "http"` + `url` |
| Claude Code | `.mcp.json` | `mcpServers` | `command` + `args` | `"type": "http"` + `url` |

**Read first, merge, write back.** Never remove or overwrite existing entries.

#### Generate Project Developer Agent

Create `.github/agents/project-dev-agent.agent.md` if not already present.

**Tools to include:**
- Always: `read`, `edit`, `search`, `execute`, `web`, `agent`
- For every MCP server installed: `<server-key>/*` (e.g. `contentful/*`, `vercel/*`)
- Always: `github/*`

**Template:**
```markdown
---
description: "Developer agent for [PROJECT_NAME]. Use for feature work, debugging, and code changes. Skills: [list]. MCP: [list]."
name: "Project Developer"
tools: [read, edit, search, execute, web, agent, github/*, ...]
---

You are the developer agent for [PROJECT_NAME].

## Before Each Task
Read `.ai/project-context.md`, `.ai/architecture.md`, `.ai/coding-standards.md`.

## Available Skills
[list installed skills with brief descriptions]

## Available MCP Tools
[list MCP servers wired with brief descriptions]

## Behaviour Rules
- Evidence first: read code before changing it
- Follow `.ai/coding-standards.md` conventions
- Respect service boundaries in `.ai/architecture.md`
- Use MCP tools directly — do not hardcode API calls
- Flag stale or missing `.ai/` context
- Never write secrets to files
```

---

## Completion Summary

After all steps are complete, output:

```
## Migration Complete

### Agents Installed
- Discovery Agent (`.github/agents/ai-project-discovery.agent.md`)
- Maintainer Agent (`.github/agents/ai-project-maintainer.agent.md`)
[Or report if already present]

### Superpowers Skills Installed
- writing-skills
- systematic-debugging
- verification-before-completion
- test-driven-development
[Or report if already present]

### .ai/ Files Generated
- project-context.md
- architecture.md
- runbooks.md
- dependencies.md
- cms.md
- operational-context.md
- coding-standards.md
- agent-registry.md
- onboarding.md

### AI Wiring Files
- .github/copilot-instructions.md [created / appended / already present]
- CLAUDE.md [created / appended / already present]
- .github/instructions/ai-context.instructions.md [created / appended / already present]

### Stack-Aware Tools Installed
- Skills installed: [list, or "None matched"]
- MCP servers added: [list, or "None"]
- Project developer agent: [created / already present]

### Existing Agentic Setup Found
[list files found in Step 3, or "None"]

### Confluence Pages Created
[list pages under MS/Projects, or "None"]

### Onboarding Links Collected
- GitHub: [URL or "Missing"]
- Test environment: [URL or "Missing"]
- Acceptance environment: [URL or "Missing"]
- Production environment: [URL or "Missing"]
- Keeper: [URL or "Missing"]

### Validation Questions to Resolve
[consolidated list from all .ai/ files with confidence < 100%]

### Next Steps
1. Review .ai/ files and resolve Validation Questions
2. Commit changes to a feature branch
3. Open a pull request for team review
4. After merging, run AI Project Maintainer Agent after each sprint

**Questions?** See docs/vision.md and standards/agentic-project-standard.md for context.
```
