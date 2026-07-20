---
description: "Phase 3: Wire AI tools to load .ai/ context and create Confluence documentation."
---

# Phase 3: Integration

> Self-contained phase. Requires Phase 2 (.ai/ folder generated). Idempotent.

## Prerequisites

- Phase 2 completed (`.ai/` folder with 9 context files exists)
- Confluence access (for documentation creation)

## Step 6: Wire AI Tools

Create or update wiring files so every AI tool automatically reads `.ai/` context at session start. **`.ai/` is the single shared source of truth**; each file below is a thin *pointer* into it, one per client that only auto-loads its own dotfile.

Coverage target — the four supported IDEs:

| IDE | Wiring file it auto-loads |
|---|---|
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` |
| Claude Code | `CLAUDE.md` |
| OpenAI Codex | `AGENTS.md` |
| Cursor | `.cursor/rules/*.mdc` (also honors `AGENTS.md`) |

`AGENTS.md` is the nearest-to-universal pointer (Codex, Cursor, and Copilot's coding agent all read it) — but each client's own dotfile is the reliable always-on path, so write all of them.

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
- For OpenAI Codex, Cursor, and any agent framework that reads `AGENTS.md` by convention (the nearest to a cross-tool standard)
- **Not present**: create from `templates/AGENTS.template.md` — same `.ai/` loading instructions as `CLAUDE.md`, adapted for Codex format
- **Already present**: append a `## AI Project Context (.ai/)` section
- Fill `[SETUP_COMMANDS]` with the relevant install/run commands from `.ai/onboarding.md`
- Fill `[KEY_CONSTRAINTS_ONE_LINERS]` with terse one-liners from `.ai/coding-standards.md` (commit format, env var rules, type safety, etc.)

### File 5: `.cursor/rules/ai-context.mdc` (Cursor native rules)
- Cursor's always-on rule format. `AGENTS.md` also works, but a `.mdc` with `alwaysApply: true` is the reliable native path.
- **Not present**: create with this frontmatter + a short pointer body (do NOT restate `.ai/` content — point to it):
  ```
  ---
  description: Load .ai/ project context before any task
  alwaysApply: true
  ---
  This project keeps machine-readable context in `.ai/`. Read `.ai/project-context.md`,
  `.ai/architecture.md`, and `.ai/coding-standards.md` at the start of every task; consult the
  other `.ai/` files as the task requires. Flag contradictions between `.ai/` and the codebase.
  ```
- **Already present**: leave unchanged (report as already present)

### All wiring files must instruct AI to:
1. Read `.ai/` files at session start
2. Cross-reference `.ai/` with agents/instructions/skills found in Phase 2
3. Respect constraints in existing agentic files
4. Flag contradictions between `.ai/` and codebase (don't silently accept stale context)

## Step 7: Create Confluence Project Documentation

After wiring is complete, create handover documentation in Confluence.

**Publish path — use the `atlassian-axi` skill (primary).** It is installed in Phase 1 at `.github/skills/atlassian-axi/` and drives the `atlassian-axi` npm CLI (`npx -y atlassian-axi confluence ...`), which wraps the Confluence Cloud REST API. Do NOT rely on the Atlassian MCP here: the MCP is only configured in Phase 4, and an MCP added to `.mcp.json` mid-session is not callable until the tool/IDE reloads — so during a single migration run the MCP is not a usable publish path for this step. Verify access first (`npx -y atlassian-axi confluence space list` → lists spaces), then create the landing page, capture its id, and create the four subpages under it with `--parent <landingId>`. When updating existing pages, resolve subpages by walking the landing page's children (`npx -y atlassian-axi confluence page children <landingId>`) — never a bare title search, because the shared `MS` space collides across projects. `page update` bumps the version automatically (no 409 handling).

> **If Confluence access is unavailable** (the `atlassian-axi confluence space list` preflight
> failed — not authed, or the site is unreachable): do NOT skip the
> work silently. Instead **stage the pages as local drafts** — write one Markdown
> file per page (landing + the four subpages, following the structure below) into
> `.ai/confluence/`, and write the `confluence:` block into `.ai/.meta.yml` with
> `published: false` and empty `id`s. The Maintainer Agent (or a later run with
> access) then publishes them and backfills the IDs. Report clearly in the
> completion summary that Confluence was staged, not published.
>
> **Drafts are transient.** Once the pages are published and their real ids are
> written into `.ai/.meta.yml`, the `.ai/confluence/` drafts are no longer needed
> — the Maintainer syncs from the `.ai/` files via `sync_map`, never from the
> drafts. Phase 5 (cleanup) removes them.

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
   landing page uses the human project name with **no affix**; every subpage is **prefixed with the
   landing title** — `<landing title> - <subpage name>`. The `MS` space is shared, so bare titles
   like `Overview` collide across projects.
   - Main page: `[Project Name]`  (e.g. `DEPT Client Portal`)  ← this is the landing title
   - Subpage: `[Project Name] - Overview`
   - Subpage: `[Project Name] - Architecture & Package Map`
   - Subpage: `[Project Name] - Environments & Access`
   - Subpage: `[Project Name] - Onboarding & Handover`
5. On the **main `[Project Name]` page** (the landing page), include in order:
   - A short intro paragraph (project type, client, agency)
   - `## Key facts` table: repo, framework, package manager, CMS, hosting, database, monitoring — use `[To fill in]` for unknowns
   - `## Quick links` table: GitHub, test, acceptance, production, Keeper/secrets
   - `## Documentation structure` bullet list linking to the four subpages
   - `## AI tooling status` — list context files, agents, skills, code graph, MCP servers, instructions; add a warning panel if not yet confirmed
   - `## Key contacts` table (last section) — columns `Role`, `Name`, `Contact (email)`; add a warning panel asking the team to verify before sharing
6. Make content readable for mixed roles (developer + client manager).
7. In `Overview`, include what the system does and the main business capabilities. When the project has multiple packages, features, brands, or campaigns, add a short plain-language summary for each major area so a new developer can quickly understand what each one is for. Also include a `## Key Features (Monitored)` section copied from `.ai/project-context.md` → *Key Features* (the Datadog Synthetic tests fetched in Phase 2 Step 4b). Use the canonical schema — **Public ID** (link → `https://app.datadoghq.<region>/synthetics/details/<public_id>`) · **Type** (Browser/API) · **Name** (exact test name) · **Description** (factual, from the config) — sorted Browser first, API second, with a one-line note on the split (e.g. "5 browser tests + 2 API uptime tests"). Keep it in sync with `.ai/project-context.md`; do not invent columns or details. If Datadog access was unavailable at migration time, keep the section with a `[To fill in]` note — do not omit it.
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
15. **Record the page mapping.** After creating/finding the pages, write a `confluence:` block into `.ai/.meta.yml` using the schema in `docs/confluence-page-standard.md` — space, base URL, each page's **full prefixed** `title`, its real `id`, and the `sync_map`. This is what lets the Maintainer Agent sync the right pages without duplicating. If a page's ID cannot be captured, leave it empty; the Maintainer resolves it by the full title and backfills it on first run.

## Verification

Before proceeding to Phase 4, confirm:
- [ ] `.github/copilot-instructions.md` references `.ai/` folder (Copilot)
- [ ] `CLAUDE.md` references `.ai/` folder (Claude Code)
- [ ] `AGENTS.md` references `.ai/` folder (Codex + Cursor + universal)
- [ ] `.github/instructions/ai-context.instructions.md` exists (Copilot path-scoped)
- [ ] `.cursor/rules/ai-context.mdc` exists (Cursor native, `alwaysApply: true`)
- [ ] Confluence pages created (or report why not)
- [ ] `.ai/.meta.yml` has a `confluence:` block with page IDs + `sync_map`

## Completion Signal

```
✓ Phase 3 complete: AI tools wired and Confluence documentation created.
  Next: Run Phase 4 (04-stack-tooling.prompt.md) to install stack-specific tools.
```
