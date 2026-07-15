---
description: "Phase 3: Wire AI tools to load .ai/ context and create Confluence documentation."
---

# Phase 3: Integration

> Self-contained phase. Requires Phase 2 (.ai/ folder generated). Idempotent.

## Prerequisites

- Phase 2 completed (`.ai/` folder with 9 context files exists)
- Confluence access (for documentation creation)

## Step 6: Wire AI Tools

Create or update wiring files so every AI tool (Copilot, Claude, Cursor) automatically reads `.ai/` context at session start.

**Rule:** Check each file first. If it exists, append only. Never overwrite existing content.

> **Wiring files are pointers, not a second source of truth.** `.ai/` is
> authoritative. A wiring file may carry a SHORT summary of the always-on
> constraints (so they load with the file), but it must be explicitly marked as a
> summary of `.ai/coding-standards.md` — never a full restatement that can drift.
> Keep the summary to terse one-liners (commits, env-var handling); push all
> detail to `.ai/`. Do not copy whole sections out of `.ai/` into these files.

### File 1: `.github/copilot-instructions.md`
- **Not present**: create with `.ai/` reading instructions + a short "Behaviour Rules (summary — full detail in `.ai/coding-standards.md`)" block of one-liners
- **Already present**: append a `## AI Project Context (.ai/)` section

### File 2: `CLAUDE.md` (repository root)
- **Not present**: create with same instructions in Claude format
- **Already present**: append a `## AI Project Context (.ai/)` section

### File 3: `.github/instructions/ai-context.instructions.md`
- **Not present**: create with `applyTo: "**"` frontmatter and concise loading instructions
- **Already present**: leave unchanged (report as already present)

### File 4: `AGENTS.md` (repository root)
- For OpenAI Codex and any agent framework that reads `AGENTS.md` by convention
- **Not present**: create from `templates/AGENTS.template.md` — same `.ai/` loading instructions as `CLAUDE.md`, adapted for Codex format
- **Already present**: append a `## AI Project Context (.ai/)` section
- Fill `[SETUP_COMMANDS]` with the relevant install/run commands from `.ai/onboarding.md`
- Fill `[KEY_CONSTRAINTS_ONE_LINERS]` with terse one-liners from `.ai/coding-standards.md` (commit format, env var rules, type safety, etc.)

### All wiring files must instruct AI to:
1. Read `.ai/` files at session start
2. Cross-reference `.ai/` with agents/instructions/skills found in Phase 2
3. Respect constraints in existing agentic files
4. Flag contradictions between `.ai/` and codebase (don't silently accept stale context)

## Step 7: Create Confluence Project Documentation

After wiring is complete, create handover documentation in Confluence.

> **If Confluence access is unavailable** (no Atlassian MCP/connector, or the
> tool running this prompt cannot reach `dept-nl.atlassian.net`): do NOT skip the
> work silently. Instead **stage the pages as local drafts** — write one Markdown
> file per page (landing + the four subpages, following the structure below) into
> `.ai/confluence/`, and write the `confluence:` block into `.ai/.meta.yml` with
> `published: false` and empty `id`s. The Maintainer Agent (or a later run with
> access) then publishes them and backfills the IDs. Report clearly in the
> completion summary that Confluence was staged, not published.

**Canonical structure source:** `docs/confluence-page-standard.md`
- Use it as the default page-layout and section-order source for every project.
- Keep the base page names and section order the same unless a project-specific need clearly justifies a deviation.
- If you deviate, keep the standard structure as intact as possible and explain the deviation in your final report.

**Target location:**
- Space: `MS`
- Path: `Projects`
- Base URL: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

**Action steps:**
1. Ensure `Projects` directory exists. Create if missing.
2. Create a project page under `Projects` if not present.
3. Sanitize the page title before creating it: decode HTML entities, never leave `&amp;` or `@amp;` in the title, and prefer `and` instead of symbols when needed for readability.
4. Keep the layout consistent with other MS projects by using this fixed structure. **Titles must
   follow the collision-safe rule** (see `docs/confluence-page-standard.md` → *Page titles*): the
   landing page uses the human project name with **no suffix**; every subpage is suffixed
   ` - <project_name>` where `<project_name>` is `meta.project_name` from `.ai/.meta.yml` (the repo
   slug). The `MS` space is shared, so unsuffixed titles like `Overview` collide across projects.
   - Main page: `[Project Name]`  (e.g. `DEPT Client Portal`)
   - Subpage: `Overview - <project_name>`
   - Subpage: `Architecture & Package Map - <project_name>`
   - Subpage: `Environments & Access - <project_name>`
   - Subpage: `Onboarding & Handover - <project_name>`
5. On the **main `[Project Name]` page** (the landing page), include in order:
   - A short intro paragraph (project type, client, agency)
   - `## Key facts` table: repo, framework, package manager, CMS, hosting, database, monitoring — use `[To fill in]` for unknowns
   - `## Quick links` table: GitHub, test, acceptance, production, Keeper/secrets
   - `## Documentation structure` bullet list linking to the four subpages
   - `## AI tooling status` — list context files, agents, skills, code graph, MCP servers, instructions; add a warning panel if not yet confirmed
   - `## Key contacts` table (last section) — columns `Role`, `Name`, `Contact (email)`; add a warning panel asking the team to verify before sharing
6. Make content readable for mixed roles (developer + client manager).
7. In `Overview`, include what the system does and the main business capabilities. When the project has multiple packages, features, brands, or campaigns, add a short plain-language summary for each major area so a new developer can quickly understand what each one is for.
8. In `Architecture & Package Map`, document each major app/package/feature/campaign and what it is responsible for. For monorepos or multi-brand/campaign projects, include all of the following:
   - an inventory table for quick scanning
   - a short summary paragraph or bullet for each major package/feature/campaign explaining purpose, ownership/context, and notable dependencies or integrations when known
   - a **Mermaid diagram** at the top of the page that gives a quick structural overview of how the project works
9. The Mermaid diagram must be a concise architecture overview, not an ASCII tree or screenshot-style code block. Prefer a simple `flowchart LR` or `flowchart TD` showing the main runtime path, major internal components, and key external systems/services.
10. If the repository has a `doc/` or `docs/` folder, use it as a primary input for Confluence wording, package/campaign descriptions, and onboarding context — but still verify against code/config when facts conflict.
11. In `Environments & Access`, include GitHub, test/acc/prod URLs, and Keeper reference.
12. In `Onboarding & Handover`, include setup steps, troubleshooting, escalation, and project-specific gotchas. Do **not** repeat the Key Contacts table here — it lives on the main `[Project Name]` landing page.
13. Include all 5 links collected in Phase 2 Step 4.
14. Do NOT create a separate coding standards page unless explicitly requested.
15. **Record the page mapping.** After creating/finding the pages, write a `confluence:` block into `.ai/.meta.yml` using the schema in `docs/confluence-page-standard.md` — space, base URL, each page's **full suffixed** `title`, its real `id`, and the `sync_map`. This is what lets the Maintainer Agent sync the right pages without duplicating. If a page's ID cannot be captured, leave it empty; the Maintainer resolves it by the full title and backfills it on first run.

## Verification

Before proceeding to Phase 4, confirm:
- [ ] `.github/copilot-instructions.md` references `.ai/` folder
- [ ] `CLAUDE.md` references `.ai/` folder
- [ ] `AGENTS.md` references `.ai/` folder (OpenAI Codex wiring)
- [ ] `.github/instructions/ai-context.instructions.md` exists
- [ ] Confluence pages created (or report why not)
- [ ] `.ai/.meta.yml` has a `confluence:` block with page IDs + `sync_map`

## Completion Signal

```
✓ Phase 3 complete: AI tools wired and Confluence documentation created.
  Next: Run Phase 4 (04-stack-tooling.prompt.md) to install stack-specific tools.
```
