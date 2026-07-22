---
description: "Phase 2: Analyze the repository and generate complete .ai/ context files."
agent: "Discovery Agent"
---

# Phase 2: Discovery & Analysis

> Self-contained phase. Requires Phase 1 (agents installed). Idempotent.

**Execution mode:** run this prompt with the installed **Discovery Agent** from `.github/agents/discovery.agent.md`. If your tool ignores the prompt frontmatter, explicitly select or invoke that agent before continuing. The agent must receive the local repository, any `graphify-out/` artifacts, and the installed `.github/skills/` context.

**Claude Code — real subagent vs. main-thread fallback (timing matters):** Claude Code registers subagents from `.claude/agents/*.md` **at session start**, not mid-session.
- **Bootstrap path (recommended):** if the migration was set up with `scripts/install.sh` in a terminal *before* launching Claude Code, `.claude/agents/discovery.md` already exists at session start → dispatch a **real Discovery subagent** for this phase (`Agent` / `subagent_type`), sandboxed with its own context.
- **In-session path:** if `.claude/agents/discovery.md` was only written during Phase 1 of *this same session*, it is **not** yet a registered subagent (no reload happened). Do not fail — run Phase 2 in the **main thread** by reading `.claude/agents/discovery.md` and following it as the Discovery Agent persona. Real subagent dispatch becomes available on the next session. This is the same reload gap as the Datadog MCP (see `migrate.prompt.md` Preflight).

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

**How to use it in practice:**
- Treat `GRAPH_REPORT.md` as short-term structural working context for this discovery run
- Use it to decide which packages, features, apps, campaigns, and docs to inspect first
- Convert the useful findings into durable `.ai/` memory/context files (`project-context.md`, `architecture.md`, `dependencies.md`, `agent-registry.md`) after verifying them against primary repository evidence
- When Graphify highlights packages or feature areas, make sure the generated `.ai/` files explain what each one is for in plain language — not just its path or name

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

## Step 4b: Fetch Client Key Features (Datadog Synthetics)

The project's **key features** are the Datadog Synthetic tests that monitor its critical user flows (browser tests) and availability (API/uptime tests). Fetch them so they land in `.ai/` and, from there, on the Confluence **Overview** page.

**Fetch via the Datadog MCP** (`datadog` server, browser OAuth — **no API keys**). The connector URL must enable the synthetics toolset: `?toolsets=core,synthetics` (default is `core` only — without it there are no Synthetics tools).

1. **Determine the client tag.** Tests are tagged `client:<name>` (e.g. `client:unicef`). Infer `<name>` from the repository/project name; if the exact tag is unknown, fetch the live configs and infer the project tag from the returned test tags. If ambiguous, ask the user.
2. **Is the Datadog MCP callable in this session?** It is configured in Phase 4, but a freshly-added MCP is not callable until the tool/IDE reloads — and OAuth must be completed. So:
   - **If the `datadog` MCP is present and authed** (a re-run in an already-reloaded session, or a repo set up earlier): call **`get_synthetics_tests`** with `mode: "configs"`, `test_state: "live"`, `summary: false` (full config, active tests only — not event aggregation). Filter to the project by its `client:<name>` tag; add `type:browser` / `type:api` or a domain/path filter only when needed to disambiguate. Keep both Browser and API tests; drop inactive tests and unrelated domains/projects even if they share the org. Verify the final list by its public IDs and names.
   - **If it is not yet callable** (first migration run, not reloaded, or not authed): do **not** block. Write the Key Features section with a single `[To fill in — fetch via the Datadog MCP after IDE reload + OAuth]` line so the structure exists; the developer (or the Maintainer on its next run) backfills it. This matches the non-blocking Confluence/Graphify pattern (see Preflight in `migrate.prompt.md`).
3. **If the MCP is callable but no tests are found**: record `No Synthetic tests tagged client:<name>` — the tag convention may differ; note it as a Validation Question rather than inventing tests (evidence-first).

**Table schema** (used in `project-context.md` and on the Confluence Overview page), sorted **Browser tests first, API tests second**:

| Column | Value |
|---|---|
| Public ID | markdown link → `https://app.datadoghq.<region>/synthetics/details/<public_id>` (use the org's region, e.g. `eu`) |
| Type | `Browser` or `API` |
| Name | exact Datadog test name |
| Description | short, factual summary of what the test verifies — derived from the visible config (steps, URL, assertions). **Do not invent details.** |

Feed any fetched tests into `project-context.md` in Step 5 (see file 1 below).

## Step 5: Generate `.ai/` Context Files

Generate all 9 context files and write to `.ai/` directory in repository root.

**Files to create:**
1. `project-context.md` — what the system is, key services, monorepo structure, tech stack, and a `## Key Features (Monitored)` section built from the Step 4b Datadog fetch. Use the Step 4b table schema — **Public ID** (link) · **Type** (Browser/API) · **Name** · **Description** — sorted Browser first, API second, with a one-line note on the split (e.g. "5 browser + 2 API uptime"). This is the single home for key features — it syncs to the Confluence Overview page via `sync_map`. Monitoring *tooling* (that Datadog is the monitor) still belongs in `operational-context.md`; cross-reference, don't duplicate.
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

**Single source of truth (avoid cross-file duplication):**
Each fact/constraint has exactly ONE home file; other files cross-reference it instead of restating it. This prevents drift and the duplication reviewers flag.
- Commit conventions, linting, testing, TypeScript/import rules → **only** `coding-standards.md`
- Tech stack + monorepo layout, and Key Features (monitored Synthetic flows) → **only** `project-context.md`
- Deploy pipeline, environments, env-var handling → **only** `operational-context.md`
- CMS/content model/webhooks/ISR → **only** `cms.md`

If another file needs to mention one of these, write a one-line pointer (e.g. "See `coding-standards.md` → Commit Conventions"), not a copy. `project-context.md` must NOT contain a standalone "Commit Convention" section — point to `coding-standards.md`.

**Quality check:** No empty sections, no placeholders. Every section has content or an explicit unknown statement.

## Step 5b: Generate `.ai/.meta.yml`

After generating all 9 files, create `.ai/.meta.yml` from the meta template:
- `standard_version`: read the `standard.version` value from `config/standard-version.yml` (Phase 1 installs this file into the target repo). If the file is missing for any reason, default to `"1.0.0"` — do not block.
- `generated_by`: `discovery@2.0`
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
