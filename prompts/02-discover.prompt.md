---
description: "Phase 2: Analyze the repository and generate complete .ai/ context files."
agent: "AI Project Discovery Agent"
---

# Phase 2: Discovery & Analysis

> Self-contained phase. Requires Phase 1 (agents installed). Idempotent.

**Execution mode:** run this prompt with the installed **AI Project Discovery Agent** from `.github/agents/ai-project-discovery.agent.md`. If your tool ignores the prompt frontmatter, explicitly select or invoke that agent before continuing. The agent must receive the local repository, any `graphify-out/` artifacts, and the installed `.github/skills/` context.

## Prerequisites

- Phase 1 completed (agents and skills installed)
- Repository has source code to analyze

## Critical Disciplines

**Follow superpowers:writing-skills discipline:**
- Evidence first: only cite what you find in code, config, and infrastructure
- No hallucination: mark unknowns explicitly with `Assumption:` tags
- All claims traceable to source files
- Rate `Confidence: <0-100>%` per major section

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. Map all packages before per-package analysis.

**Documentation-first rule:** If the repository contains a `doc/` or `docs/` folder, read it early and treat it as primary context for onboarding, architecture explanations, package/campaign descriptions, and Confluence handover content — while still verifying important claims against code/config.

## Graphify Input (Expected When Available)

If the repository contains a `graphify-out/` directory, use it as the **first structural input** before broad raw-source scanning.

**Read in this order:**
1. `graphify-out/GRAPH_REPORT.md`
2. `graphify-out/graph.json` (for detailed structural verification only)

**Use Graphify specifically for:**
- probable service boundaries
- cross-file call paths
- import/dependency clusters
- hotspots / highly connected nodes
- prioritizing which raw files to inspect next
- package/app/campaign boundaries in monorepos or multi-brand repositories

**Verification rule:**
- Treat Graphify output as **supplemental evidence**, not the source of truth
- Any important claim written into `.ai/` must still be verified against actual repository files, config, CI/CD, infra, or other primary evidence
- Do **not** replace operational discovery with Graphify — environments, escalation paths, runbooks, SLAs, ownership, and support constraints still come from project docs, CI/CD, infra, and human-provided evidence

**If `graphify-out/` is absent:** continue normally with raw-repository discovery. Do not fail the phase.

## Step 3: Scan Existing Agentic Configuration

Before generating new files, identify what already exists:

**Scan these locations:**
- **Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- **Instructions**: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `CLAUDE.md`, `.cursor/rules/`
- **Prompts / Skills**: `.github/prompts/*.prompt.md`, `.github/skills/`, `.claude/skills/`
- **MCP**: `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`, VS Code `mcpServers` settings

**Record findings** (file path, name, tool, scope, purpose). This informs `agent-registry.md` and prevents overwriting.

## Step 4: Collect Required Onboarding Links

Gather these 5 links from repository evidence (config files, CI/CD, README, GitHub):
- **GitHub URL** (repository location)
- **Test environment URL** (where features are tested)
- **Acceptance environment URL** (where client validates)
- **Production environment URL** (live service)
- **Keeper URL** (or equivalent secret-management reference)

**Action:** Verify each link from codebase evidence. If any cannot be verified, prompt the user for the missing values.

**Note:** Do NOT ask for Confluence URL. All pages are created under: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

## Step 5: Generate `.ai/` Context Files

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
9. `onboarding.md` — GitHub, environment, and Keeper references collected in Step 4

**For each file:**
- Extract evidence from code, config, CI/CD, and infrastructure files
- Include `Assumption:` tags on inferred content
- Rate `Confidence: <0-100>%` per major section
- Add `Validation Questions` for unresolved gaps
- Cite source evidence (file paths, config names)
- Redact secrets and privileged credentials

**Quality check:** No empty sections, no placeholders. Every section has content or an explicit unknown statement.

## Step 5b: Generate `.ai/.meta.yml`

After generating all 9 files, create `.ai/.meta.yml` from the meta template:
- `standard_version`: read from `config/standard-version.yml`
- `generated_by`: `ai-project-discovery@2.0`
- `generated_at`: current ISO 8601 timestamp
- `project_name`: repository name

## Verification

Before proceeding to Phase 3, confirm:
- [ ] `.ai/` directory contains all 9 required files
- [ ] Each file has content (not just template stubs)
- [ ] `.ai/.meta.yml` exists with correct metadata
- [ ] Confidence scores are present in each file
- [ ] No secrets or credentials in any file

## Completion Signal

```
✓ Phase 2 complete: .ai/ folder generated with 9 context files.
  Next: Run Phase 3 (03-integrate.prompt.md) to wire AI tools and create Confluence docs.
```
